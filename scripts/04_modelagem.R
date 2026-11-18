################################################################################
### CE314 - Modelos Lineares Generalizados | Trabalho final - Tema 8
### Baixo peso ao nascer em Santa Catarina (SINASC, 2026)
###
### ETAPA C - Modelagem e seleção
### Entrada : data/processed/base_municipal_sc2026.rds   (295 municípios, Etapa A)
###           data/raw/dnsc2026_bruto.rds                (só para as sensibilidades
###                                                       jan-jul e pré-natal < 7)
### Saída   : output/tabelas/C_*.csv, output/figuras/C_*.png,
###           data/processed/C_modelos.rds
###
### COMO RODAR: working directory = raiz do repositório. Rode de cima para baixo
### e LEIA as saídas de cada bloco. Há UM ponto de decisão do autor (bloco 6,
### "DECISÃO"): rode até o bloco 5, decida, edite VARS_FINAL, e rode o resto.
### Todas as decisões (C1, C2, ...) estão em docs/etapa_C_modelagem.md
################################################################################

################################################################################
### 0. Pacotes e pastas
################################################################################
## install.packages(c("dplyr","tibble","car","glmmTMB","DHARMa","ggplot2"))
suppressPackageStartupMessages({
    library(dplyr)
    library(tibble)
    library(car)
    library(glmmTMB)
    library(DHARMa)
    library(ggplot2)
})

for (pasta in c("output/tabelas", "output/figuras", "data/processed")) {
    dir.create(pasta, recursive = TRUE, showWarnings = FALSE)
}
options(scipen = 999)
set.seed(314)


################################################################################
### 1. Dados e escala dos preditores (C1)
################################################################################
base <- readRDS("data/processed/base_municipal_sc2026.rds")

stopifnot(
    nrow(base) == 295,
    all(base$n_nascidos > 0),
    all(base$baixo_peso + base$demais == base$n_nascidos),
    sum(base$baixo_peso) == 5302,
    sum(base$n_nascidos) == 64469
)

## C1: preditores em unidades de 10 pontos percentuais.
## prop (0-1) * 10  =>  1 unidade = 10 p.p.  =>  exp(beta) = razão de chances
## associada a +10 p.p. na proporção municipal. O MODELO É O MESMO (só muda a
## escala do coeficiente); fica mais legível do que "por 1 unidade = 100 p.p.".
escala <- function(d) {
    d %>% mutate(
        adol10 = prop_adolescente * 10,
        esc10  = prop_esc_baixa * 10,
        pre10  = prop_prenatal_insuf * 10,
        mult10 = prop_gestacao_mult * 10,
        m35_10 = prop_mae_35mais * 10
    )
}
dados <- escala(base)

VARS <- c("adol10", "esc10", "pre10", "mult10", "m35_10")

## monta cbind(sucessos, insucessos) ~ preditores
mk_f <- function(vars) {
    as.formula(paste(
        "cbind(baixo_peso, demais) ~",
        if (length(vars) == 0) "1" else paste(vars, collapse = " + ")
    ))
}

## dispersão: Pearson e deviance divididos pelos graus de liberdade residuais
disp <- function(m) {
    c(phi_pearson  = sum(residuals(m, "pearson")^2) / df.residual(m),
      phi_deviance = deviance(m) / df.residual(m),
      gl           = df.residual(m))
}

## extrator de coeficientes (glm e glmmTMB)
coef_tab <- function(m, tipo) {
    s <- if (inherits(m, "glmmTMB")) summary(m)$coefficients$cond else summary(m)$coefficients
    tibble(termo = rownames(s), est = s[, 1], ep = s[, 2], p = s[, 4], modelo = tipo)
}


################################################################################
### 2. Modelo nulo e modelo completo binomial-logito (C2, C3, C4)
################################################################################
m_nulo <- glm(mk_f(character(0)), family = binomial, data = dados)
disp(m_nulo)
## CONFERÊNCIA com a Etapa B: phi_pearson do modelo nulo deve ser ~ 1,551 (gl 294)

m_bin_full <- glm(mk_f(VARS), family = binomial(link = "logit"), data = dados)
summary(m_bin_full)

## --- C3: convergência e separação -------------------------------------------
m_bin_full$converged                       # esperado: TRUE
m_bin_full$iter                            # nº de iterações (poucas = bom sinal)
range(fitted(m_bin_full))                  # probabilidades ajustadas: longe de 0 e 1?
max(summary(m_bin_full)$coefficients[, "Std. Error"])   # EP enormes => separação
## Aviso "fitted probabilities numerically 0 or 1" NÃO deve ter aparecido.

## --- C4: dispersão (NÃO usar o p-valor chi2 da deviance: alerta A4) ---------
disp(m_bin_full)
## phi > 1 => superdispersão (variância maior que a binomial).

## Redução de deviance em relação ao nulo (pseudo-R2 da deviance; descritivo)
100 * (deviance(m_nulo) - deviance(m_bin_full)) / deviance(m_nulo)


################################################################################
### 3. Escolha da função de ligação (C5)
################################################################################
ligacoes <- c("logit", "probit", "cloglog", "cauchit")

tab_lig <- bind_rows(lapply(ligacoes, function(l) {
    m <- suppressWarnings(glm(mk_f(VARS), family = binomial(link = l), data = dados,
                              control = glm.control(maxit = 100)))
    tibble(ligacao = l,
           convergiu = m$converged,
           logLik = as.numeric(logLik(m)),
           AIC = AIC(m), BIC = BIC(m),
           phi_pearson = unname(disp(m)["phi_pearson"]))
})) %>% mutate(dAIC = AIC - min(AIC))

tab_lig
write.csv(tab_lig, "output/tabelas/C_ligacoes.csv", row.names = FALSE, fileEncoding = "UTF-8")
## Regra (C5): ficamos com o LOGITO (canônica, razão de chances) salvo se alguma
## outra ligação reduzir o AIC em mais de ~10 unidades.


################################################################################
### 4. Testes por termo: análise de deviance (C6)
################################################################################
## Modelo quasi-binomial: mesmas estimativas do binomial, mas phi é ESTIMADO
## e os erros-padrão são multiplicados por sqrt(phi).
m_q_full <- glm(mk_f(VARS), family = quasibinomial(link = "logit"), data = dados)
phi_full <- summary(m_q_full)$dispersion
phi_full     # deve coincidir com disp(m_bin_full)["phi_pearson"]

## 4.1 TRV (qui-quadrado) com phi = 1: SÓ de referência (ignora superdispersão)
car::Anova(m_bin_full, type = 2, test.statistic = "LR")

## 4.2 Teste F (phi desconhecido, estimado no modelo completo): o que vale.
##     F = [(D0 - D1)/(p1 - p0)] / phi_hat ~ F(p1 - p0, n - p1)  (slides de deviance)
car::Anova(m_q_full, type = 2, test.statistic = "F")
drop1(m_q_full, test = "F")

## 4.3 Sequencial (tipo I): depende da ORDEM; só para ilustrar
anova(m_q_full, test = "F")


################################################################################
### 5. Seleção de variáveis (C7)
################################################################################
## 5.1 Todas as regressões possíveis: 2^5 = 32 modelos (viável, só 5 candidatos)
subconjuntos <- c(list(character(0)),
                  unlist(lapply(1:5, function(k) combn(VARS, k, simplify = FALSE)),
                         recursive = FALSE))

tab_sub <- bind_rows(lapply(subconjuntos, function(v) {
    m  <- glm(mk_f(v), family = binomial, data = dados)
    ll <- as.numeric(logLik(m))
    p  <- length(coef(m))
    tibble(modelo = if (length(v) == 0) "(nulo)" else paste(v, collapse = " + "),
           k = length(v), logLik = ll, deviance = deviance(m),
           AIC = AIC(m), BIC = BIC(m),
           ## QAIC: AIC corrigido para superdispersão, com phi do modelo completo
           ## (conta +1 parâmetro: o próprio phi)
           QAIC = -2 * ll / phi_full + 2 * (p + 1))
})) %>%
    mutate(dAIC = AIC - min(AIC), dBIC = BIC - min(BIC), dQAIC = QAIC - min(QAIC))

cat("\n--- Top 8 por AIC ---\n");  print(tab_sub %>% arrange(AIC)  %>% head(8))
cat("\n--- Top 8 por BIC ---\n");  print(tab_sub %>% arrange(BIC)  %>% head(8))
cat("\n--- Top 8 por QAIC ---\n"); print(tab_sub %>% arrange(QAIC) %>% head(8))
write.csv(tab_sub %>% arrange(QAIC), "output/tabelas/C_todas_regressoes.csv",
          row.names = FALSE, fileEncoding = "UTF-8")

## Em quantos dos modelos "competitivos" (dQAIC < 2) cada variável aparece?
comp <- tab_sub %>% filter(dQAIC < 2)
sapply(VARS, function(v) mean(grepl(v, comp$modelo)))

## 5.2 Backward / forward / stepwise por AIC e por BIC (para comparar com 5.1)
## OBS (C7): o BIC do glm usa n = nº de LINHAS (295 municípios), não 64.469.
n_mun <- nrow(dados)
passo <- function(direcao, k) {
    if (direcao == "backward") {
        step(m_bin_full, direction = "backward", k = k, trace = 0)
    } else {
        step(m_nulo, scope = formula(m_bin_full), direction = direcao, k = k, trace = 0)
    }
}
selecoes <- list(
    back_AIC = passo("backward", 2),        back_BIC = passo("backward", log(n_mun)),
    forw_AIC = passo("forward", 2),         forw_BIC = passo("forward", log(n_mun)),
    both_AIC = passo("both", 2),            both_BIC = passo("both", log(n_mun))
)
tab_step <- tibble(metodo = names(selecoes),
                   modelo = sapply(selecoes, function(m) {
                       v <- attr(terms(m), "term.labels")
                       if (length(v) == 0) "(nulo)" else paste(v, collapse = " + ")
                   }))
tab_step
write.csv(tab_step, "output/tabelas/C_stepwise.csv", row.names = FALSE, fileEncoding = "UTF-8")


################################################################################
### 6. DECISÃO DO AUTOR  >>>>>>  manter somente pre10 e mult10  <<<<<<   (C11)
################################################################################
## Regra escrita ANTES de olhar os resultados (ver docs, C11):
##  (i)  partir do melhor critério e escolher o mais simples com dAIC < 2;
##  (ii) variável sem sustentação nos dados sai ("nem todos precisam estar no modelo final");
##  (iii) em caso de empate, ganha o modelo mais simples (parcimônia).
## AJUSTE DE PROCEDIMENTO (registrado em C11): a seleção deve ser feita NA FAMÍLIA
## PRINCIPAL. Como o beta-binomial foi a família escolhida (C8), a seleção vale o
## ranking do bloco 7b (AIC/BIC do beta-binomial), e não o QAIC do binomial.
## Decisão: 5 variáveis -> 2. esc10 (p > 0,6 com n >= 30), adol10 e m35_10 são
## intercambiáveis (aparecem em 50% dos modelos competitivos); ficam pre10 e mult10.
VARS_FINAL <- c("pre10", "mult10")

cat("\nModelo final adotado neste run:", paste(VARS_FINAL, collapse = " + "), "\n")


################################################################################
### 7. Modelo final em três "famílias de dispersão" (C8)
################################################################################
## (a) binomial (phi = 1)  (b) quasi-binomial (phi estimado)
## (c) beta-binomial (pi_i varia entre municípios segundo uma Beta)
m_bin_fin <- glm(mk_f(VARS_FINAL), family = binomial,      data = dados)
m_q_fin   <- glm(mk_f(VARS_FINAL), family = quasibinomial, data = dados)

ajusta_bb <- function(vars, d = dados) {
    glmmTMB(mk_f(vars), family = betabinomial(link = "logit"), data = d)
}
bb_fin  <- ajusta_bb(VARS_FINAL)
bb_full <- ajusta_bb(VARS)

## convergência do beta-binomial (deve ser TRUE / 0)
bb_fin$sdr$pdHess
bb_fin$fit$convergence

## Parâmetro de dispersão do beta-binomial: no glmmTMB
##   Var(Y) = n mu (1-mu) [1 + (n-1)/(phi_bb + 1)],   rho = 1/(1 + phi_bb)
## rho = correlação intra-município (heterogeneidade entre mães do mesmo município)
rho_bb <- function(m) 1 / (1 + sigma(m))
c(phi_bb = sigma(bb_fin), rho = rho_bb(bb_fin))

## --- Comparação por verossimilhança (binomial e beta-binomial são verossimilhanças
##     verdadeiras, então AIC/BIC são comparáveis entre elas; o quasi NÃO tem AIC)
comp_familias <- tibble(
    modelo = c("binomial (final)", "beta-binomial (final)",
               "binomial (completo)", "beta-binomial (completo)"),
    logLik = c(logLik(m_bin_fin), logLik(bb_fin), logLik(m_bin_full), logLik(bb_full)) %>% as.numeric(),
    AIC = c(AIC(m_bin_fin), AIC(bb_fin), AIC(m_bin_full), AIC(bb_full)),
    BIC = c(BIC(m_bin_fin), BIC(bb_fin), BIC(m_bin_full), BIC(bb_full))
)
comp_familias
write.csv(comp_familias, "output/tabelas/C_familias_AIC.csv", row.names = FALSE, fileEncoding = "UTF-8")

## --- Dispersão do modelo final
disp(m_bin_fin)
summary(m_q_fin)$dispersion

## --- Estimativas lado a lado: binomial x quasi x beta-binomial
tab_coef <- bind_rows(coef_tab(m_bin_fin, "binomial"),
                      coef_tab(m_q_fin,   "quasi-binomial"),
                      coef_tab(bb_fin,    "beta-binomial")) %>%
    mutate(OR_10pp = exp(est))
tab_coef %>% arrange(termo, modelo)
write.csv(tab_coef, "output/tabelas/C_coef_3familias.csv", row.names = FALSE, fileEncoding = "UTF-8")
## Leitura: os EP do binomial são menores (ignoram phi); os do quasi são ~ sqrt(phi)
## vezes maiores; o beta-binomial muda também as ESTIMATIVAS (pesos diferentes).

## --- Testes por termo no beta-binomial (TRV, refazendo sem cada variável)
trv_bb <- bind_rows(lapply(VARS_FINAL, function(v) {
    reduzido <- ajusta_bb(setdiff(VARS_FINAL, v))
    a <- anova(reduzido, bb_fin)
    tibble(termo_removido = v, chisq = a$Chisq[2], gl = a$`Chi Df`[2], p = a$`Pr(>Chisq)`[2])
}))
trv_bb

## --- Como a superdispersão se comporta com o TAMANHO do município? (C8)
##     Quasi-binomial supõe Var = phi * n pi (1-pi)      => E[resíduo Pearson^2] ~ phi, PLANO em n
##     Beta-binomial supõe Var = n pi (1-pi)[1+(n-1)rho] => E[resíduo Pearson^2] CRESCE com n
dados$rp   <- residuals(m_bin_fin, "pearson")
dados$classe_n <- cut(dados$n_nascidos, c(0, 29, 99, 499, Inf),
                      labels = c("<30", "30-99", "100-499", ">=500"))
tab_var_n <- dados %>% group_by(classe_n) %>%
    summarise(n_mun = n(), media_n = mean(n_nascidos),
              phi_classe = mean(rp^2), .groups = "drop")
tab_var_n
write.csv(tab_var_n, "output/tabelas/C_phi_por_classe_n.csv", row.names = FALSE, fileEncoding = "UTF-8")

g_var <- ggplot(tab_var_n, aes(x = classe_n, y = phi_classe, group = 1)) +
    geom_hline(yintercept = 1, linetype = 2) +
    geom_point(size = 3) + geom_line() +
    theme_bw(base_size = 14) +
    labs(x = "Nascimentos no município", y = "Média do resíduo de Pearson ao quadrado",
         title = "Dispersão por tamanho (modelo binomial final)")
ggsave("output/figuras/C_phi_por_classe_n.png", g_var, width = 7, height = 4.5, dpi = 150)

## --- Dispersão testada por SIMULAÇÃO (substitui o chi2 da deviance, A4)
sim_bin <- simulateResiduals(m_bin_fin, n = 1000, plot = FALSE)
testDispersion(sim_bin)                      # H0: dispersão compatível com a binomial
sim_bb <- try(simulateResiduals(bb_fin, n = 1000, plot = FALSE), silent = TRUE)
if (!inherits(sim_bb, "try-error")) testDispersion(sim_bb)


################################################################################
### 7b. Seleção DENTRO do beta-binomial (família principal) e TRV bin x beta-bin
################################################################################
tab_sub_bb <- bind_rows(lapply(subconjuntos, function(v) {
    m <- tryCatch(ajusta_bb(v), error = function(e) NULL)
    if (is.null(m)) return(NULL)
    tibble(modelo = if (length(v) == 0) "(nulo)" else paste(v, collapse = " + "),
           k = length(v), pdHess = isTRUE(m$sdr$pdHess),
           logLik = as.numeric(logLik(m)), AIC = AIC(m), BIC = BIC(m))
})) %>% mutate(dAIC = AIC - min(AIC), dBIC = BIC - min(BIC))

print(tab_sub_bb %>% arrange(AIC) %>% head(8), width = Inf)
print(tab_sub_bb %>% arrange(BIC) %>% head(8), width = Inf)
sapply(VARS, function(v) mean(grepl(v, (tab_sub_bb %>% filter(dAIC < 2))$modelo)))
write.csv(tab_sub_bb %>% arrange(AIC), "output/tabelas/C_todas_regressoes_bb.csv",
          row.names = FALSE, fileEncoding = "UTF-8")

## TRV binomial x beta-binomial (fronteira rho = 0: p = metade do qui-quadrado)
c(AIC_bin = AIC(m_bin_fin), AIC_bb = AIC(bb_fin))
lrt <- 2 * (as.numeric(logLik(bb_fin)) - as.numeric(logLik(m_bin_fin)))
c(lrt = lrt, p = 0.5 * pchisq(lrt, 1, lower.tail = FALSE))

## Fator de variância previsto pelo beta-binomial, 1 + (n-1) rho, nas classes de n:
## deve reproduzir a tabela de phi por classe (bloco 7)
rho_hat <- rho_bb(bb_fin)
tab_var_n %>% mutate(fator_bb = 1 + (media_n - 1) * rho_hat)

## esc10 aguenta ser descartada sem os municípios pequenos?
sens(dados %>% filter(n_nascidos >= 30), VARS, "d-completo (com esc10)") %>%
    filter(termo == "esc10")


################################################################################
### 8. Forma funcional (C9)
################################################################################
## 8.1 Termo quadrático, um preditor por vez (teste F no quasi-binomial)
quad <- bind_rows(lapply(VARS_FINAL, function(v) {
    f2 <- as.formula(paste("cbind(baixo_peso, demais) ~",
                           paste(VARS_FINAL, collapse = " + "), "+ I(", v, "^2)"))
    m2 <- glm(f2, family = quasibinomial, data = dados)
    a  <- anova(m_q_fin, m2, test = "F")
    tibble(preditor = v, F = a$F[2], p = a$`Pr(>F)`[2])
}))
quad
write.csv(quad, "output/tabelas/C_quadraticos.csv", row.names = FALSE, fileEncoding = "UTF-8")

## 8.2 Teste da ligação (slides de resíduos): acrescentar eta_hat^2 como covariável
d_eta <- dados
d_eta$eta2 <- predict(m_bin_fin, type = "link")^2
m_eta <- glm(update(formula(m_q_fin), . ~ . + eta2), family = quasibinomial, data = d_eta)
summary(m_eta)$coefficients["eta2", ]
## p grande => sem evidência de má especificação da ligação/preditor.
## (Não identifica a causa se for significativo.)


################################################################################
### 9. Sensibilidades (C10)
################################################################################
sens <- function(d, vars, rotulo) {
    mq  <- glm(mk_f(vars), family = quasibinomial, data = d)
    out <- coef_tab(mq, "quasi-binomial") %>%
        mutate(cenario = rotulo, n_mun = nrow(d), phi = summary(mq)$dispersion)
    bb  <- tryCatch(ajusta_bb(vars, d), error = function(e) NULL)
    if (!is.null(bb)) {
        out <- bind_rows(out, coef_tab(bb, "beta-binomial") %>%
                             mutate(cenario = rotulo, n_mun = nrow(d), phi = NA_real_))
    }
    out
}

lista_sens <- list(
    sens(dados, VARS_FINAL, "0. Principal (jan-ago, todos)"),
    ## (c) acrescentando prop_adolescente (3º candidato mais forte no beta-binomial)
    sens(dados, c("adol10", "pre10", "mult10"), "c. Com adol10"),
    ## (d) sem municípios pequenos (n < 30)  -- ESSENCIAL (Etapa B)
    sens(dados %>% filter(n_nascidos >= 30), VARS_FINAL, "d. Apenas n >= 30")
)

## (a) jan-jul e (b) pré-natal < 7 exigem reconstruir a base a partir dos microdados.
## A função abaixo REPLICA as definições da Etapa A (01_preparacao_base.R) e é
## validada contra a base oficial antes de ser usada.
arq_bruto <- "data/raw/dnsc2026_bruto.rds"

construir_base <- function(bruto, meses = 1:8, corte_prenatal = 6) {
    pn <- function(x) suppressWarnings(as.numeric(x))
    pv <- function(x) if (all(is.na(x))) NA_real_ else mean(x, na.rm = TRUE)
    d <- bruto %>%
        transmute(codmunres = trimws(codmunres),
                  dtnasc = as.Date(dtnasc, format = "%d%m%Y"),
                  peso = pn(peso), idade = pn(idademae),
                  esc = trimws(escmae), grav = trimws(gravidez), cons = pn(consprenat)) %>%
        filter(substr(codmunres, 1, 2) == "42", !is.na(dtnasc),
               format(dtnasc, "%Y") == "2026", codmunres != "420000",
               !(is.na(peso) | peso %in% c(0, 9999)),
               as.integer(format(dtnasc, "%m")) %in% meses) %>%
        mutate(idade_val = ifelse(!is.na(idade) & idade >= 10 & idade <= 59, idade, NA_real_),
               esc_val   = ifelse(esc %in% as.character(1:5), as.integer(esc), NA_integer_),
               grav_val  = ifelse(grav %in% as.character(1:3), as.integer(grav), NA_integer_),
               cons_val  = ifelse(!is.na(cons) & cons >= 0 & cons <= 98, cons, NA_real_),
               bp  = peso < 2500,
               adolescente = idade_val < 20,
               m35 = idade_val >= 35,
               esc_baixa = ifelse(is.na(esc_val), NA, esc_val %in% 1:3),
               pre = cons_val < corte_prenatal,
               mult = ifelse(is.na(grav_val), NA, grav_val %in% 2:3))
    d %>% group_by(cod6 = codmunres) %>%
        summarise(n_nascidos = n(), baixo_peso = sum(bp), demais = n() - sum(bp),
                  prop_adolescente = pv(adolescente), prop_esc_baixa = pv(esc_baixa),
                  prop_prenatal_insuf = pv(pre), prop_gestacao_mult = pv(mult),
                  prop_mae_35mais = pv(m35), .groups = "drop") %>%
        arrange(cod6)
}

if (file.exists(arq_bruto)) {
    bruto <- readRDS(arq_bruto)

    ## VALIDAÇÃO: a reconstrução (jan-ago, corte 6) tem de reproduzir a base oficial
    b0  <- construir_base(bruto, 1:8, 6)
    ref <- base %>% arrange(cod6)
    stopifnot(identical(b0$cod6, ref$cod6),
              all(b0$baixo_peso == ref$baixo_peso),
              all(b0$n_nascidos == ref$n_nascidos),
              isTRUE(all.equal(b0$prop_adolescente, ref$prop_adolescente)),
              isTRUE(all.equal(b0$prop_esc_baixa, ref$prop_esc_baixa)),
              isTRUE(all.equal(b0$prop_prenatal_insuf, ref$prop_prenatal_insuf)),
              isTRUE(all.equal(b0$prop_gestacao_mult, ref$prop_gestacao_mult)),
              isTRUE(all.equal(b0$prop_mae_35mais, ref$prop_mae_35mais)))
    cat("Reconstrução da base validada contra a Etapa A.\n")

    ## (a) jan-jul (meses completos)
    b_jj <- escala(construir_base(bruto, 1:7, 6))
    ## (b) pré-natal insuficiente = menos de 7 consultas
    b_p7 <- escala(construir_base(bruto, 1:8, 7))

    lista_sens <- c(lista_sens, list(
        sens(b_jj, VARS_FINAL, "a. Jan-jul"),
        sens(b_p7, VARS_FINAL, "b. Pré-natal < 7 consultas")
    ))
} else {
    message("data/raw/dnsc2026_bruto.rds não encontrado: sensibilidades (a) e (b) puladas.")
}

tab_sens <- bind_rows(lista_sens) %>% mutate(OR_10pp = exp(est))
tab_sens %>% filter(termo != "(Intercept)", modelo == "quasi-binomial") %>%
    arrange(termo, cenario) %>% select(cenario, termo, est, ep, p, OR_10pp, phi, n_mun)
tab_sens %>% filter(termo != "(Intercept)", modelo == "beta-binomial") %>%
    arrange(termo, cenario) %>% select(cenario, termo, est, ep, p, OR_10pp)
write.csv(tab_sens, "output/tabelas/C_sensibilidades.csv", row.names = FALSE, fileEncoding = "UTF-8")
## Leitura: o sinal e a ordem de grandeza dos coeficientes se mantêm nos cenários?
## Se algum coeficiente muda muito (esperado: esc10 e adol10 em "d"), REPORTAR.


################################################################################
### 10. Salvando
################################################################################
saveRDS(list(VARS = VARS, VARS_FINAL = VARS_FINAL,
             m_nulo = m_nulo, m_bin_full = m_bin_full, m_q_full = m_q_full,
             m_bin_fin = m_bin_fin, m_q_fin = m_q_fin,
             bb_full = bb_full, bb_fin = bb_fin),
        "data/processed/C_modelos.rds")
writeLines(capture.output(sessionInfo()), "output/tabelas/sessionInfo_etapa_C.txt")

## FIM DA ETAPA C. Próxima: Etapa D (diagnóstico) sobre o modelo final.
