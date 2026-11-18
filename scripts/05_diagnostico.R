################################################################################
### CE314 - Modelos Lineares Generalizados | Trabalho final - Tema 8
### Baixo peso ao nascer em Santa Catarina (SINASC, 2026)
###
### ETAPA D - Diagnóstico do modelo final
### Modelo: beta-binomial, logit(pi_i) = b0 + b1*pre10 + b2*mult10
###
### Entrada : data/processed/base_municipal_sc2026.rds
###           (opcional, só para conferência) data/processed/C_modelos.rds
### Saída   : output/tabelas/D_*.csv ; output/figuras/D_*.png ;
###           data/processed/D_diagnostico.rds
###
### COMO RODAR: raiz do repositório como working directory; rodar de cima para
### baixo. Cada bloco imprime resultados: COLE AS SAÍDAS no chat para eu
### conferir os números e preencher docs/etapa_D_diagnostico.md.
###
### Decisões numeradas (D1, D2, ...) explicadas em docs/etapa_D_diagnostico.md.
###
### Tempo estimado: 3 a 10 minutos (leave-one-out e envelope simulado refazem
### o ajuste centenas de vezes).
################################################################################

################################################################################
### 0. Pacotes, pastas e parâmetros
################################################################################
suppressPackageStartupMessages({
  library(dplyr)
  library(tibble)
  library(ggplot2)
  library(patchwork)
  library(glmmTMB)
  library(DHARMa)
  library(car)
  library(splines)
})
## Usados só no bloco de Moran (chamados com ::): geobr, sf, spdep

for (pasta in c("data/processed", "output/tabelas", "output/figuras")) {
  dir.create(pasta, recursive = TRUE, showWarnings = FALSE)
}
options(scipen = 999)

SEMENTE       <- 67     # reprodutibilidade
N_SIM_ENV     <- 99     # simulações do envelope (convenção do pacote hnp)
N_SIM_DHARMA  <- 1000   # simulações do DHARMa
N_SIM_MORAN   <- 9999   # permutações do teste de Moran
FAZ_MORAN     <- TRUE   # D10: pode ser desligado se faltar tempo/internet

tema <- theme_bw(base_size = 13)

################################################################################
### 1. Dados e REAJUSTE do modelo final (D1)
################################################################################
base <- readRDS("data/processed/base_municipal_sc2026.rds")

b <- base %>%
  filter(entra_no_ajuste) %>%
  mutate(
    n   = n_nascidos,
    y   = baixo_peso,
    ## mesmas unidades da Etapa C: 10 pontos percentuais
    adol10 = prop_adolescente * 10,
    esc10  = prop_esc_baixa * 10,
    pre10  = prop_prenatal_insuf * 10,
    mult10 = prop_gestacao_mult * 10,
    m35_10 = prop_mae_35mais * 10,
    classe_n = cut(n, breaks = c(-Inf, 29, 99, 499, Inf),
                   labels = c("<30", "30-99", "100-499", ">=500"))
  )

stopifnot(nrow(b) == 295, all(b$y + b$demais == b$n))

fit_bb <- function(d, formula = cbind(y, demais) ~ pre10 + mult10) {
  suppressWarnings(
    glmmTMB(formula, family = betabinomial(link = "logit"), data = d)
  )
}

bb <- fit_bb(b)
summary(bb)

## Conferência com a Etapa C (valores esperados: mult10 = 0,805; pre10 = 0,151;
## rho = 0,00103). Se divergir, PARE e investigue antes de continuar.
cf  <- fixef(bb)$cond
phi <- sigma(bb)          # parâmetro de dispersão do glmmTMB
rho <- 1 / (1 + phi)      # correlação intraclasse
conferencia <- tibble(
  item     = c("pdHess (convergência)", "beta mult10", "beta pre10", "rho"),
  obtido   = c(as.numeric(bb$sdr$pdHess), cf["mult10"], cf["pre10"], rho),
  esperado = c(1, 0.805, 0.151, 0.00103)
)
print(conferencia)
if (!isTRUE(bb$sdr$pdHess) ||
    abs(cf["mult10"] - 0.805) > 0.01 || abs(cf["pre10"] - 0.151) > 0.01) {
  warning("O reajuste NÃO reproduz a Etapa C. Investigue antes de seguir.")
}

## Modelos de comparação (como na C): binomial com os mesmos preditores
m_bin <- glm(cbind(y, demais) ~ pre10 + mult10, family = binomial, data = b)

################################################################################
### 2. Quantidades básicas: ajustados, variância e resíduo de Pearson (D2)
################################################################################
## Sob o beta-binomial (parametrização do glmmTMB):
##   E(Y_i)   = n_i * mu_i
##   Var(Y_i) = n_i mu_i (1 - mu_i) * (n_i + phi)/(1 + phi)
## e (n+phi)/(1+phi) = 1 + (n-1) rho. Este é o "fator de superdispersão".
X   <- model.matrix(~ pre10 + mult10, data = b)
eta <- drop(X %*% cf)
mu  <- plogis(eta)
fator <- (b$n + phi) / (1 + phi)

b$eta   <- eta
b$mu    <- mu
b$taxa  <- b$y / b$n
b$fator <- fator

pearson_bb <- function(f, d) {
  Xf  <- model.matrix(~ pre10 + mult10, data = d)
  mu_f <- plogis(drop(Xf %*% fixef(f)$cond))
  ph_f <- sigma(f)
  (d$y - d$n * mu_f) / sqrt(d$n * mu_f * (1 - mu_f) * (d$n + ph_f) / (1 + ph_f))
}
b$r_p <- pearson_bb(bb, b)

## Pearson do binomial (para mostrar o que o beta-binomial corrige)
mu_bin <- fitted(m_bin)
b$r_p_bin <- (b$y - b$n * mu_bin) / sqrt(b$n * mu_bin * (1 - mu_bin))

## Alavancagem aproximada (pesos de quasi-verossimilhança do beta-binomial)
w   <- b$n * mu * (1 - mu) / fator
Xw  <- X * sqrt(w)
XtWXi <- solve(crossprod(Xw))
b$h <- rowSums((Xw %*% XtWXi) * Xw)
p_par <- ncol(X)                        # 3 parâmetros de regressão
b$r_p_std <- b$r_p / sqrt(1 - b$h)      # Pearson padronizado
b$cook_aprox <- b$r_p^2 * b$h / (p_par * (1 - b$h)^2)

## Dispersão residual por Pearson: deve ficar perto de 1 se o modelo
## descreve bem a variabilidade (D2/D5)
c(phi_pearson_bb  = sum(b$r_p^2)     / (nrow(b) - p_par - 1),
  phi_pearson_bin = sum(b$r_p_bin^2) / (nrow(b) - p_par))
## (no beta-binomial há 1 parâmetro a mais, o phi; por isso n - p - 1)

################################################################################
### 3. Resíduo quantílico normalizado aleatorizado, calculado "à mão" (D2)
################################################################################
## F(y) = P(Y <= y) do beta-binomial, somando a função de probabilidade.
## Para variável discreta sorteia-se u ~ U[F(y-1), F(y)] e r = qnorm(u).
## Se o modelo estiver certo, r ~ N(0,1) aproximadamente.
pbb <- function(q, n, mu, phi) {
  if (q < 0) return(0)
  a <- mu * phi
  bq <- (1 - mu) * phi
  k <- 0:q
  min(1, sum(exp(lchoose(n, k) + lbeta(k + a, n - k + bq) - lbeta(a, bq))))
}

set.seed(SEMENTE)
lo <- mapply(pbb, q = b$y - 1, n = b$n, mu = mu, MoreArgs = list(phi = phi))
hi <- mapply(pbb, q = b$y,     n = b$n, mu = mu, MoreArgs = list(phi = phi))
u  <- runif(nrow(b), lo, hi)
u  <- pmin(pmax(u, 1e-12), 1 - 1e-12)
b$rq <- qnorm(u)

## O mesmo para o binomial (comparação)
lo_b <- pbinom(b$y - 1, b$n, mu_bin)
hi_b <- pbinom(b$y,     b$n, mu_bin)
set.seed(SEMENTE)
b$rq_bin <- qnorm(pmin(pmax(runif(nrow(b), lo_b, hi_b), 1e-12), 1 - 1e-12))

## Resumo global dos resíduos quantílicos (esperado: média ~0, DP ~1)
resumo_rq <- tibble(
  modelo = c("beta-binomial", "binomial"),
  media  = c(mean(b$rq), mean(b$rq_bin)),
  dp     = c(sd(b$rq),   sd(b$rq_bin)),
  min    = c(min(b$rq),  min(b$rq_bin)),
  max    = c(max(b$rq),  max(b$rq_bin)),
  n_abs_gt2 = c(sum(abs(b$rq) > 2),   sum(abs(b$rq_bin) > 2)),
  n_abs_gt3 = c(sum(abs(b$rq) > 3),   sum(abs(b$rq_bin) > 3)),
  shapiro_p = c(shapiro.test(b$rq)$p.value, shapiro.test(b$rq_bin)$p.value)
)
print(resumo_rq)
## Esperado sob normalidade: ~5% (≈ 15) com |r| > 2 e ~0,3% (≈ 1) com |r| > 3.
## O Shapiro é DESCRITIVO (resíduos aleatorizados mudam a cada sorteio).

## Por classe de tamanho: o ponto central da pendência 5 da Etapa C.
## Se o beta-binomial está certo, DP ~1 e phi de Pearson ~1 em TODAS as classes.
por_classe <- b %>%
  group_by(classe_n) %>%
  summarise(
    n_mun        = n(),
    media_rq     = mean(rq),
    dp_rq        = sd(rq),
    dp_rq_bin    = sd(rq_bin),
    phi_pearson_bb  = mean(r_p^2),
    phi_pearson_bin = mean(r_p_bin^2),
    prop_abs_gt2 = mean(abs(rq) > 2),
    .groups = "drop"
  )
print(por_classe, width = Inf)
## phi_pearson_bin deve reproduzir o padrão da Etapa C (≈ 1,07 · 1,13 · 1,23 ·
## 2,51). phi_pearson_bb é o que o beta-binomial deixou sem explicar.

write.csv(resumo_rq,  "output/tabelas/D_residuos_resumo.csv", row.names = FALSE)
write.csv(por_classe, "output/tabelas/D_residuos_por_classe_n.csv", row.names = FALSE)

################################################################################
### 4. DHARMa: simulação de resíduos e testes (D9 - explica o testDispersion)
################################################################################
set.seed(SEMENTE)
sim_bb  <- simulateResiduals(bb,    n = N_SIM_DHARMA, seed = SEMENTE)
sim_bin <- simulateResiduals(m_bin, n = N_SIM_DHARMA, seed = SEMENTE)

png("output/figuras/D_dharma_bb.png", width = 1500, height = 750, res = 140)
plot(sim_bb)
dev.off()
png("output/figuras/D_dharma_bin.png", width = 1500, height = 750, res = 140)
plot(sim_bin)
dev.off()

extrai_dharma <- function(sim, rotulo) {
  tu <- testUniformity(sim, plot = FALSE)
  td <- testDispersion(sim, plot = FALSE)
  to <- testOutliers(sim, plot = FALSE)
  tibble(modelo = rotulo,
         ks_uniformidade_p = tu$p.value,
         dispersao_estat   = unname(td$statistic),
         dispersao_p       = td$p.value,
         outliers_p        = to$p.value)
}
tab_dharma <- bind_rows(extrai_dharma(sim_bb, "beta-binomial"),
                        extrai_dharma(sim_bin, "binomial"))
print(tab_dharma)
write.csv(tab_dharma, "output/tabelas/D_dharma_testes.csv", row.names = FALSE)

## Resíduos DHARMa contra cada preditor e contra n (arquivos separados)
png("output/figuras/D_dharma_x_preditores.png", width = 1800, height = 600, res = 140)
par(mfrow = c(1, 3))
plotResiduals(sim_bb, b$mult10, xlab = "mult10", main = "Resíduos x mult10")
plotResiduals(sim_bb, b$pre10,  xlab = "pre10",  main = "Resíduos x pre10")
plotResiduals(sim_bb, log(b$n), xlab = "log(n)", main = "Resíduos x log(n)")
dev.off()

## LEITURA: na Etapa C o testDispersion deu < 1 (0,86), na contramão do phi de
## Pearson. A estatística é o DP dos resíduos quantílicos; aqui comparamos com
## o DP por classe de tamanho (bloco 3) para ver QUEM puxa o valor para baixo.

################################################################################
### 5. Envelope simulado (estilo hnp) para o beta-binomial (D3)
################################################################################
## O pacote hnp não reconhece glmmTMB diretamente. Fazemos à mão, com o mesmo
## algoritmo: (i) simula respostas SOB o modelo ajustado; (ii) reajusta o modelo
## em cada simulação; (iii) guarda os |resíduos de Pearson| ordenados;
## (iv) envelope = mínimo e máximo das simulações em cada posição.
## Se o modelo é adequado, os pontos observados ficam dentro do envelope.
set.seed(SEMENTE)
sims <- list()
tentativas <- 0
while (length(sims) < N_SIM_ENV && tentativas < 3 * N_SIM_ENV) {
  tentativas <- tentativas + 1
  p_s  <- rbeta(nrow(b), mu * phi, (1 - mu) * phi)   # pi_i variando entre municípios
  y_s  <- rbinom(nrow(b), b$n, p_s)
  d_s  <- b
  d_s$y <- y_s
  d_s$demais <- b$n - y_s
  f_s <- tryCatch(fit_bb(d_s), error = function(e) NULL)
  if (!is.null(f_s) && isTRUE(f_s$sdr$pdHess)) {
    sims[[length(sims) + 1]] <- sort(abs(pearson_bb(f_s, d_s)))
  }
}
c(simulacoes_validas = length(sims), tentativas = tentativas)

M_sim   <- do.call(cbind, sims)
obs_ord <- sort(abs(b$r_p))
ord_idx <- order(abs(b$r_p))
nn <- nrow(b)
escore_hn <- qnorm((seq_len(nn) + nn - 1/8) / (2 * nn + 1/2))  # escores meio-normais

env <- tibble(
  escore = escore_hn,
  obs    = obs_ord,
  lim_inf = apply(M_sim, 1, min),
  mediana = apply(M_sim, 1, median),
  lim_sup = apply(M_sim, 1, max)
) %>%
  mutate(fora = obs > lim_sup | obs < lim_inf)

c(n_fora_envelope = sum(env$fora), pct_fora = round(100 * mean(env$fora), 1))
## Referência: com 99 simulações o envelope (min-max) cobre ~98%; esperam-se
## poucos pontos fora por acaso (a literatura aceita "a maioria dentro").

g_env <- ggplot(env, aes(x = escore)) +
  geom_ribbon(aes(ymin = lim_inf, ymax = lim_sup), alpha = 0.25) +
  geom_line(aes(y = mediana), linetype = 2) +
  geom_point(aes(y = obs, colour = fora), size = 1.8) +
  scale_colour_manual(values = c(`FALSE` = "black", `TRUE` = "red"), guide = "none") +
  labs(x = "Escores meio-normais",
       y = "|Resíduo de Pearson| (ordenado)",
       title = "Envelope simulado - beta-binomial (pre10 + mult10)") +
  tema
ggsave("output/figuras/D_envelope_bb.png", g_env, width = 7, height = 5, dpi = 150)
write.csv(env, "output/tabelas/D_envelope_bb.csv", row.names = FALSE)

## Quais municípios estão fora do envelope?
fora_env <- b[ord_idx[env$fora], c("nome", "n", "y", "taxa", "r_p", "rq")]
print(fora_env)

################################################################################
### 6. Resíduos x ajustados / preditores / tamanho (D4)
################################################################################
graf_res <- function(xvar, xlab, logx = FALSE) {
  ggplot(b, aes(x = .data[[xvar]], y = rq)) +
    geom_hline(yintercept = c(-2, 0, 2), linetype = c(3, 2, 3)) +
    geom_point(aes(size = n), alpha = 0.5) +
    geom_smooth(method = "loess", formula = y ~ x, span = 0.9, se = TRUE,
                colour = "red", linewidth = 0.9) +
    scale_size_continuous(range = c(0.8, 4), guide = "none") +
    { if (logx) scale_x_log10() } +
    labs(x = xlab, y = "Resíduo quantílico") +
    tema
}
b$log_n <- log(b$n)
g1 <- graf_res("eta",    "Preditor linear ajustado")
g2 <- graf_res("pre10",  "pre10 (10 p.p.)")
g3 <- graf_res("mult10", "mult10 (10 p.p.)")
g4 <- graf_res("n",      "n_i (escala log)", logx = TRUE)
ggsave("output/figuras/D_residuos_x.png", (g1 | g2) / (g3 | g4),
       width = 11, height = 8, dpi = 150)

## Binomial para comparação: o padrão por tamanho deve aparecer aqui, não no bb
g4b <- ggplot(b, aes(x = n, y = rq_bin)) +
  geom_hline(yintercept = c(-2, 0, 2), linetype = c(3, 2, 3)) +
  geom_point(alpha = 0.5) +
  geom_smooth(method = "loess", formula = y ~ x, span = 0.9, colour = "red") +
  scale_x_log10() +
  labs(x = "n_i (escala log)", y = "Resíduo quantílico (binomial)",
       title = "Binomial") + tema
g4a <- ggplot(b, aes(x = n, y = rq)) +
  geom_hline(yintercept = c(-2, 0, 2), linetype = c(3, 2, 3)) +
  geom_point(alpha = 0.5) +
  geom_smooth(method = "loess", formula = y ~ x, span = 0.9, colour = "red") +
  scale_x_log10() +
  labs(x = "n_i (escala log)", y = "Resíduo quantílico (beta-binomial)",
       title = "Beta-binomial") + tema
ggsave("output/figuras/D_residuos_x_n_bin_vs_bb.png", g4b | g4a,
       width = 11, height = 4.5, dpi = 150)

## Correlações dos resíduos com preditores e com log(n): esperado ~0
c(cor_rq_pre10   = cor(b$rq, b$pre10),
  cor_rq_mult10  = cor(b$rq, b$mult10),
  cor_rq_logn    = cor(b$rq, b$log_n),
  cor_rq_eta     = cor(b$rq, b$eta))

################################################################################
### 7. Forma funcional: resíduos parciais, splines e teste de eta^2 (D5)
################################################################################
## Resíduo parcial (componente + resíduo) para ligação logito:
##   z_i = (y_i/n_i - mu_i) / (mu_i (1 - mu_i))   [resíduo de trabalho]
##   parcial_j = z_i + beta_j * (x_ij - média_j)
## Se a relação é linear no logito, a curva suavizada acompanha a reta de
## inclinação beta_j. Ponderamos pelo peso do modelo (w).
b$z_trab <- (b$taxa - mu) / (mu * (1 - mu))
b$w_mod  <- w

## Para a reta passar pela nuvem, centramos x (a linha pontilhada usa x - média)
parcial_c <- function(var, beta) {
  df <- b
  df$xc <- df[[var]] - mean(df[[var]])
  df$parcial <- df$z_trab + beta * df$xc
  ggplot(df, aes(x = xc, y = parcial)) +
    geom_point(aes(size = n), alpha = 0.45) +
    geom_abline(intercept = 0, slope = beta, linetype = 2) +
    geom_smooth(aes(weight = w_mod), method = "loess", formula = y ~ x,
                span = 0.9, colour = "red", se = TRUE) +
    scale_size_continuous(range = c(0.8, 4), guide = "none") +
    labs(x = paste0(var, " centrada (10 p.p.)"), y = "Resíduo parcial") +
    tema
}
ggsave("output/figuras/D_residuos_parciais.png",
       parcial_c("mult10", cf["mult10"]) | parcial_c("pre10", cf["pre10"]),
       width = 11, height = 4.8, dpi = 150)

## Testes formais complementares (a C só testou quadráticos)
bb_ns <- fit_bb(b, cbind(y, demais) ~ ns(pre10, 3) + ns(mult10, 3))
t_ns  <- anova(bb, bb_ns)            # LRT: spline com 3 gl por variável
print(t_ns)

bb_ns_m <- fit_bb(b, cbind(y, demais) ~ pre10 + ns(mult10, 3))
bb_ns_p <- fit_bb(b, cbind(y, demais) ~ ns(pre10, 3) + mult10)
t_ns_m <- anova(bb, bb_ns_m)
t_ns_p <- anova(bb, bb_ns_p)

b$eta2 <- eta^2
bb_eta <- fit_bb(b, cbind(y, demais) ~ pre10 + mult10 + eta2)
t_eta <- summary(bb_eta)$coefficients$cond["eta2", ]
t_eta

tab_forma <- tibble(
  teste = c("splines (3 gl) em pre10 e mult10", "spline só em mult10",
            "spline só em pre10", "eta^2 (ligação)"),
  p_valor = c(t_ns$`Pr(>Chisq)`[2], t_ns_m$`Pr(>Chisq)`[2],
              t_ns_p$`Pr(>Chisq)`[2], unname(t_eta["Pr(>|z|)"]))
)
print(tab_forma)
write.csv(tab_forma, "output/tabelas/D_forma_funcional.csv", row.names = FALSE)
## Decisão: p > 0,05 em todos => manter lineares no logito (coerente com a C).

################################################################################
### 8. Multicolinearidade (D8)
################################################################################
## O VIF depende só da matriz X (e dos pesos), por isso usamos o glm binomial.
vif_final <- car::vif(m_bin)
m_bin5 <- glm(cbind(y, demais) ~ adol10 + esc10 + pre10 + mult10 + m35_10,
              family = binomial, data = b)
vif_5 <- car::vif(m_bin5)
vif_final
vif_5

cor_pre_mult <- cor(b$pre10, b$mult10)
Xs <- scale(model.matrix(~ pre10 + mult10, b)[, -1])
cond_num <- kappa(Xs, exact = TRUE)     # número de condição das colunas padronizadas
c(cor_pre_mult = cor_pre_mult, numero_condicao = cond_num)

tab_vif <- bind_rows(
  tibble(modelo = "final (2 preditores)", termo = names(vif_final), vif = as.numeric(vif_final)),
  tibble(modelo = "completo (5 preditores)", termo = names(vif_5), vif = as.numeric(vif_5))
)
write.csv(tab_vif, "output/tabelas/D_vif.csv", row.names = FALSE)

################################################################################
### 9. Observações atípicas e influentes (D6)
################################################################################
## 9.1 Medidas aproximadas (alavancagem e Cook) - cálculo rápido
##     alavancagem alta: h > 2p/n ; Cook: comparar entre si (gráfico)
lim_h <- 2 * p_par / nrow(b)
c(limite_alavancagem = lim_h, n_acima = sum(b$h > lim_h))

## 9.2 Leave-one-out EXATO: reajusta o beta-binomial sem cada município.
##     dfbetas_j(i) = (beta_j - beta_j(-i)) / EP(beta_j)  [EP do modelo completo]
##     limiar usual: 2/sqrt(n) (heurística; ~5% de pontos acima é normal)
se_cf <- sqrt(diag(vcov(bb)$cond))
loo <- matrix(NA_real_, nrow = nrow(b), ncol = 4,
              dimnames = list(NULL, c("b0", "b_pre10", "b_mult10", "phi")))
for (i in seq_len(nrow(b))) {
  f_i <- tryCatch(fit_bb(b[-i, ]), error = function(e) NULL)
  if (!is.null(f_i) && isTRUE(f_i$sdr$pdHess)) {
    loo[i, ] <- c(fixef(f_i)$cond, sigma(f_i))
  }
}
sum(is.na(loo[, 1]))   # municípios cujo reajuste falhou (esperado: 0)

b$dfb_pre  <- (cf["pre10"]  - loo[, "b_pre10"])  / se_cf["pre10"]
b$dfb_mult <- (cf["mult10"] - loo[, "b_mult10"]) / se_cf["mult10"]
b$dOR_mult <- exp(loo[, "b_mult10"]) - exp(cf["mult10"])   # variação no OR por +10 p.p.
b$dOR_pre  <- exp(loo[, "b_pre10"])  - exp(cf["pre10"])
b$dfb_max  <- pmax(abs(b$dfb_pre), abs(b$dfb_mult))
lim_dfb <- 2 / sqrt(nrow(b))

c(limite_dfbetas = lim_dfb,
  n_acima_pre  = sum(abs(b$dfb_pre)  > lim_dfb, na.rm = TRUE),
  n_acima_mult = sum(abs(b$dfb_mult) > lim_dfb, na.rm = TRUE))

## 9.3 Comparação com o binomial (Cook "oficial" do glm)
b$cook_bin <- cooks.distance(m_bin)
b$h_bin    <- hatvalues(m_bin)

## 9.4 Tabela das mais influentes
cols_inf <- c("nome", "n", "y", "taxa", "pre10", "mult10", "rq", "h",
              "cook_aprox", "dfb_pre", "dfb_mult", "dOR_pre", "dOR_mult", "cook_bin")
top_dfb  <- b %>% arrange(desc(dfb_max))        %>% select(all_of(cols_inf)) %>% head(12)
top_cook <- b %>% arrange(desc(cook_aprox))     %>% select(all_of(cols_inf)) %>% head(12)
top_h    <- b %>% arrange(desc(h))              %>% select(all_of(cols_inf)) %>% head(12)
print(top_dfb,  width = Inf)
print(top_cook, width = Inf)
print(top_h,    width = Inf)
write.csv(top_dfb,  "output/tabelas/D_influentes_dfbetas.csv", row.names = FALSE)
write.csv(top_cook, "output/tabelas/D_influentes_cook.csv", row.names = FALSE)
write.csv(top_h,    "output/tabelas/D_influentes_alavancagem.csv", row.names = FALSE)

## Os 4 municípios minúsculos fora do funil (Etapa B)
norm <- function(x) tolower(iconv(x, to = "ASCII//TRANSLIT"))
nomes_funil <- c("painel", "marema", "presidente nereu", "braco do trombudo")
idx_funil <- which(norm(b$nome) %in% nomes_funil)
if (length(idx_funil) != 4) warning("Não achei os 4 municípios do funil pelo nome: confira os nomes.")
print(b[idx_funil, c("nome", "n", "y", "taxa", "rq", "h", "cook_aprox", "dfb_pre", "dfb_mult")])

## 9.5 Gráficos de influência
b$id <- seq_len(nrow(b))
rot <- function(cond) ifelse(cond, b$nome, "")
g_h <- ggplot(b, aes(id, h)) +
  geom_point(aes(size = n), alpha = 0.5) +
  geom_hline(yintercept = lim_h, linetype = 2, colour = "red") +
  geom_text(aes(label = rot(h > quantile(h, 0.985))), vjust = -0.6, size = 3) +
  scale_size_continuous(range = c(0.8, 4), guide = "none") +
  labs(x = "Município (índice)", y = "Alavancagem (aprox.)") + tema
g_c <- ggplot(b, aes(id, cook_aprox)) +
  geom_point(aes(size = n), alpha = 0.5) +
  geom_text(aes(label = rot(cook_aprox > quantile(cook_aprox, 0.985))), vjust = -0.6, size = 3) +
  scale_size_continuous(range = c(0.8, 4), guide = "none") +
  labs(x = "Município (índice)", y = "Distância de Cook (aprox.)") + tema
g_d1 <- ggplot(b, aes(id, dfb_mult)) +
  geom_point(aes(size = n), alpha = 0.5) +
  geom_hline(yintercept = c(-lim_dfb, lim_dfb), linetype = 2, colour = "red") +
  geom_text(aes(label = rot(abs(dfb_mult) > quantile(abs(dfb_mult), 0.985, na.rm = TRUE))),
            vjust = -0.6, size = 3) +
  scale_size_continuous(range = c(0.8, 4), guide = "none") +
  labs(x = "Município (índice)", y = "DFBETAS - mult10") + tema
g_d2 <- ggplot(b, aes(id, dfb_pre)) +
  geom_point(aes(size = n), alpha = 0.5) +
  geom_hline(yintercept = c(-lim_dfb, lim_dfb), linetype = 2, colour = "red") +
  geom_text(aes(label = rot(abs(dfb_pre) > quantile(abs(dfb_pre), 0.985, na.rm = TRUE))),
            vjust = -0.6, size = 3) +
  scale_size_continuous(range = c(0.8, 4), guide = "none") +
  labs(x = "Município (índice)", y = "DFBETAS - pre10") + tema
ggsave("output/figuras/D_influencia.png", (g_h | g_c) / (g_d1 | g_d2),
       width = 12, height = 8, dpi = 150)

## Alavancagem x resíduo (bolha = Cook): quem é outlier E alavanca ao mesmo tempo?
g_bolha <- ggplot(b, aes(h, rq)) +
  geom_hline(yintercept = c(-2, 2), linetype = 3) +
  geom_vline(xintercept = lim_h, linetype = 2, colour = "red") +
  geom_point(aes(size = cook_aprox), alpha = 0.5) +
  geom_text(aes(label = rot(cook_aprox > quantile(cook_aprox, 0.985))), vjust = -0.8, size = 3) +
  labs(x = "Alavancagem (aprox.)", y = "Resíduo quantílico", size = "Cook") + tema
ggsave("output/figuras/D_alavancagem_x_residuo.png", g_bolha, width = 7.5, height = 5.5, dpi = 150)

################################################################################
### 10. Sensibilidade a atípicos/influentes: REPORTAR, não excluir (D7)
################################################################################
extrai <- function(f, rotulo, nobs) {
  s <- summary(f)$coefficients$cond
  z <- qnorm(0.975)
  ci_m <- s["mult10", "Estimate"] + c(-1, 1) * z * s["mult10", "Std. Error"]
  ci_p <- s["pre10",  "Estimate"] + c(-1, 1) * z * s["pre10",  "Std. Error"]
  tibble(cenario = rotulo, n_mun = nobs,
         OR_mult = exp(s["mult10", "Estimate"]),
         IC_mult_inf = exp(ci_m[1]), IC_mult_sup = exp(ci_m[2]),
         p_mult  = s["mult10", "Pr(>|z|)"],
         OR_pre  = exp(s["pre10", "Estimate"]),
         IC_pre_inf = exp(ci_p[1]), IC_pre_sup = exp(ci_p[2]),
         p_pre   = s["pre10", "Pr(>|z|)"],
         rho     = 1 / (1 + sigma(f)))
}
cenario <- function(rotulo, excluir_idx = integer(0), manter_mask = NULL) {
  d <- if (!is.null(manter_mask)) b[manter_mask, ] else if (length(excluir_idx)) b[-excluir_idx, ] else b
  f <- fit_bb(d)
  extrai(f, rotulo, nrow(d))
}
top5_dfb  <- order(-b$dfb_max)[1:5]
top5_cook <- order(-b$cook_aprox)[1:5]
tab_sens <- bind_rows(
  extrai(bb, "0. Principal (todos os 295)", nrow(b)),
  cenario("1. Sem as 5 de maior DFBETAS",       excluir_idx = top5_dfb),
  cenario("2. Sem as 5 de maior Cook (aprox.)", excluir_idx = top5_cook),
  cenario("3. Sem os 4 minúsculos do funil",    excluir_idx = idx_funil),
  cenario("4. Sem os 28 maiores (n >= 500)",    manter_mask = b$n < 500),
  cenario("5. Sem n < 30 (215 municípios)",     manter_mask = b$n >= 30),
  cenario("6. Sem |resíduo quantílico| > 2",    manter_mask = abs(b$rq) <= 2)
)
print(tab_sens, width = Inf)
write.csv(tab_sens, "output/tabelas/D_sensibilidade_atipicos.csv", row.names = FALSE)
## Regra (escrita ANTES de ver os números): reportar qualquer cenário em que o
## OR de mult10 ou de pre10 mude mais de ~10% ou em que a significância mude.
## Nenhuma observação é excluída do modelo final.
print(b[top5_dfb,  c("nome", "n", "taxa", "dfb_pre", "dfb_mult")])
print(b[top5_cook, c("nome", "n", "taxa", "cook_aprox")])

################################################################################
### 11. Autocorrelação espacial dos resíduos: I de Moran (D10)
################################################################################
moran_res <- NULL
if (FAZ_MORAN) {
  ok_pkg <- all(vapply(c("geobr", "sf", "spdep"), requireNamespace,
                       logical(1), quietly = TRUE))
  if (!ok_pkg) {
    warning("Pacotes geobr/sf/spdep ausentes: bloco de Moran pulado. ",
            "Instale-os ou registre como limitação.")
  } else {
    mm <- geobr::read_municipality(code_muni = "SC", year = 2020, showProgress = FALSE)
    mm$cod6 <- substr(as.character(mm$code_muni), 1, 6)
    sfb <- dplyr::inner_join(mm, b[, c("cod6", "nome", "n", "r_p", "rq", "taxa")], by = "cod6")
    stopifnot(nrow(sfb) == 295)

    ## Resíduos do modelo NULO beta-binomial (para ver o que os preditores absorvem)
    bb0 <- fit_bb(b, cbind(y, demais) ~ 1)
    mu0 <- plogis(fixef(bb0)$cond[1]); ph0 <- sigma(bb0)
    r0  <- (b$y - b$n * mu0) / sqrt(b$n * mu0 * (1 - mu0) * (b$n + ph0) / (1 + ph0))
    sfb$r_p_nulo <- r0[match(sfb$cod6, b$cod6)]

    ## Vizinhança 1: contiguidade (rainha). Ilhas ficam sem vizinhos (zero.policy).
    nb_q <- spdep::poly2nb(sfb, queen = TRUE)
    lw_q <- spdep::nb2listw(nb_q, style = "W", zero.policy = TRUE)
    n_sem_viz <- sum(spdep::card(nb_q) == 0)
    ## Vizinhança 2: 5 vizinhos mais próximos (robustez à definição de vizinho)
    cent <- suppressWarnings(sf::st_centroid(sf::st_geometry(sfb)))
    nb_k <- spdep::knn2nb(spdep::knearneigh(sf::st_coordinates(cent), k = 5))
    lw_k <- spdep::nb2listw(nb_k, style = "W")

    faz_moran <- function(x, lw, rotulo_x, rotulo_viz) {
      set.seed(SEMENTE)
      mt <- spdep::moran.test(x, lw, zero.policy = TRUE)
      mc <- spdep::moran.mc(x, lw, nsim = N_SIM_MORAN, zero.policy = TRUE)
      tibble(residuo = rotulo_x, vizinhanca = rotulo_viz,
             I = unname(mt$estimate["Moran I statistic"]),
             esperado = unname(mt$estimate["Expectation"]),
             p_normal = mt$p.value, p_monte_carlo = mc$p.value)
    }
    moran_res <- bind_rows(
      faz_moran(sfb$r_p,      lw_q, "Pearson (modelo final)", "contiguidade"),
      faz_moran(sfb$r_p,      lw_k, "Pearson (modelo final)", "5 vizinhos"),
      faz_moran(sfb$r_p_nulo, lw_q, "Pearson (modelo nulo)",  "contiguidade"),
      faz_moran(sfb$r_p_nulo, lw_k, "Pearson (modelo nulo)",  "5 vizinhos"),
      faz_moran(sfb$rq,       lw_q, "Quantílico (modelo final)", "contiguidade")
    )
    print(moran_res)
    print(c(municipios_sem_vizinho = n_sem_viz))
    write.csv(moran_res, "output/tabelas/D_moran.csv", row.names = FALSE)

    ## Mapa dos resíduos (para o slide)
    g_mapa <- ggplot(sfb) +
      geom_sf(aes(fill = r_p), colour = "grey40", linewidth = 0.1) +
      scale_fill_gradient2(low = "blue", mid = "white", high = "red",
                           midpoint = 0, limits = c(-4, 4), oob = scales::squish,
                           name = "Resíduo\nde Pearson") +
      theme_void(base_size = 13) +
      labs(title = "Resíduos de Pearson do modelo final, por município")
    ggsave("output/figuras/D_mapa_residuos.png", g_mapa, width = 7, height = 6, dpi = 150)

    ## Mapa do modelo nulo, para comparar visualmente
    g_mapa0 <- ggplot(sfb) +
      geom_sf(aes(fill = r_p_nulo), colour = "grey40", linewidth = 0.1) +
      scale_fill_gradient2(low = "blue", mid = "white", high = "red",
                           midpoint = 0, limits = c(-4, 4), oob = scales::squish,
                           name = "Resíduo\nde Pearson") +
      theme_void(base_size = 13) +
      labs(title = "Resíduos do modelo nulo (sem preditores)")
    ggsave("output/figuras/D_mapa_residuos_nulo.png", g_mapa0, width = 7, height = 6, dpi = 150)

    ## Municípios com maiores resíduos positivos (hipótese Meio-Oeste/Planalto)
    print(sfb %>% sf::st_drop_geometry() %>% arrange(desc(r_p)) %>% head(12))
  }
}

################################################################################
### 12. Tabela-síntese e salvamento
################################################################################
sintese <- tibble(
  item = c("phi de Pearson (bb), global",
           "DP dos resíduos quantílicos (bb)",
           "|rq| > 2 (bb)", "|rq| > 3 (bb)",
           "Pontos fora do envelope (de 295)",
           "Alavancagem acima de 2p/n",
           "|DFBETAS| > 2/sqrt(n): pre10 · mult10",
           "VIF máximo (modelo final)",
           "p do teste de eta^2"),
  valor = c(round(sum(b$r_p^2) / (nrow(b) - p_par - 1), 3),
            round(sd(b$rq), 3),
            sum(abs(b$rq) > 2), sum(abs(b$rq) > 3),
            sum(env$fora),
            sum(b$h > lim_h),
            paste(sum(abs(b$dfb_pre) > lim_dfb, na.rm = TRUE),
                  sum(abs(b$dfb_mult) > lim_dfb, na.rm = TRUE), sep = " · "),
            round(max(vif_final), 3),
            round(unname(t_eta["Pr(>|z|)"]), 3))
)
print(sintese)
write.csv(sintese, "output/tabelas/D_sintese.csv", row.names = FALSE)

saveRDS(list(dados = b, bb = bb, m_bin = m_bin, envelope = env,
             sensibilidade = tab_sens, moran = moran_res, loo = loo),
        "data/processed/D_diagnostico.rds")
writeLines(capture.output(sessionInfo()), "output/tabelas/sessionInfo_etapa_D.txt")

## FIM DA ETAPA D. Próxima: Etapa E (resultados e gráficos de probabilidades).
## Cole no chat: blocos 1 (conferência), 2-3 (phi, resíduos, por classe),
## 4 (DHARMa), 5 (envelope), 7 (forma funcional), 8 (VIF), 9 (influência),
## 10 (sensibilidade), 11 (Moran) e 12 (síntese).
