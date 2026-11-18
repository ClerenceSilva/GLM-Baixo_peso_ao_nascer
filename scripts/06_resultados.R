################################################################################
### CE314 - Modelos Lineares Generalizados | Trabalho final - Tema 8
### Baixo peso ao nascer em Santa Catarina (SINASC, 2026)
###
### ETAPA E - Resultados
### Entrada : data/processed/base_municipal_sc2026.rds
### Saída   : output/tabelas/E_*.csv, output/figuras/E_*.png,
###           data/processed/E_resultados.rds
###
### Modelo apresentado (decidido na Etapa C, mantido na D):
###   Y_i ~ BetaBinomial(n_i, pi_i, rho),  logit(pi_i) = b0 + b1*pre10 + b2*mult10
###   pre10  = prop_prenatal_insuf * 10   (1 unidade = 10 pontos percentuais)
###   mult10 = prop_gestacao_mult  * 10
###
### COMO RODAR: raiz do repositório como working directory; rodar de cima para
### baixo. Cada bloco imprime o que deve ser colado no chat (ver docs/etapa_E).
### Nada aqui reseleciona variáveis ou exclui municípios.
################################################################################

################################################################################
### 0. Pacotes e pastas
################################################################################
suppressPackageStartupMessages({
  library(dplyr)
  library(tibble)
  library(glmmTMB)
  library(ggplot2)
  library(patchwork)
})

for (pasta in c("output/tabelas", "output/figuras", "data/processed")) {
  dir.create(pasta, recursive = TRUE, showWarnings = FALSE)
}
options(scipen = 999)
set.seed(314)

Z <- qnorm(0.975)  # 1,96


################################################################################
### 1. Dados e reajuste do modelo final (conferência com a Etapa C)
################################################################################
base <- readRDS("data/processed/base_municipal_sc2026.rds")

dat <- base %>%
  filter(n_nascidos > 0) %>%
  transmute(
    cod6, nome,
    n      = n_nascidos,
    y      = baixo_peso,
    demais = demais,
    pre10  = prop_prenatal_insuf * 10,
    mult10 = prop_gestacao_mult  * 10,
    adol10 = prop_adolescente    * 10
  )

## Conferência com a Etapa A
stopifnot(nrow(dat) == 295, sum(dat$n) == 64469, sum(dat$y) == 5302,
          all(dat$y + dat$demais == dat$n))

bb <- glmmTMB(cbind(y, demais) ~ pre10 + mult10,
              family = betabinomial(link = "logit"), data = dat)

c(convergencia = bb$fit$convergence, pdHess = bb$sdr$pdHess)  # esperado: 0 e TRUE

est <- fixef(bb)$cond
V   <- vcov(bb)$cond
ep  <- sqrt(diag(V))

## Dispersão: no glmmTMB, sigma(modelo) = phi e  rho = 1/(1 + phi)
## Var(Y) = n*pi*(1-pi)*[1 + (n-1)*rho]
phi_bb <- sigma(bb)
rho_bb <- 1 / (1 + phi_bb)

conf <- c(beta_mult = est[["mult10"]], beta_pre = est[["pre10"]],
          phi = phi_bb, rho = rho_bb)
conf
## Esperado (Etapa C): beta_mult 0,805 ; beta_pre 0,151 ; phi 968,9 ; rho 0,00103
if (abs(est[["mult10"]] - 0.805) > 0.01 || abs(est[["pre10"]] - 0.151) > 0.01) {
  warning("O reajuste NÃO reproduz a Etapa C. Pare e investigue antes de interpretar.")
}


################################################################################
### 2. Estimativas, ICs e razões de chances (E1)
################################################################################
sd_x <- c(pre10 = sd(dat$pre10), mult10 = sd(dat$mult10))  # DP entre municípios
sd_x   # em unidades de 10 p.p.; esperado ~0,51 e ~0,33

## 2.1 IC de Wald (manual)
ic_wald <- cbind(lo = est - Z * ep, hi = est + Z * ep)

## 2.2 IC por verossimilhança perfilada (pode demorar; se falhar, fica NA)
ic_perf <- tryCatch({
  m <- as.matrix(confint(bb, parm = "beta_", method = "profile"))
  m <- m[, 1:2, drop = FALSE]
  rownames(m) <- names(est)
  colnames(m) <- c("lo", "hi")
  m
}, error = function(e) {
  message("IC por perfil falhou: ", conditionMessage(e), " -> usando só Wald.")
  matrix(NA_real_, nrow = length(est), ncol = 2,
         dimnames = list(names(est), c("lo", "hi")))
})

## 2.3 TRV por termo (cada termo retirado, ρ reestimado em cada modelo)
bb_sem_pre  <- update(bb, . ~ . - pre10)
bb_sem_mult <- update(bb, . ~ . - mult10)
bb_nulo     <- update(bb, . ~ 1)

trv <- function(m_completo, m_reduzido, gl) {
  chi <- 2 * (as.numeric(logLik(m_completo)) - as.numeric(logLik(m_reduzido)))
  c(chi2 = chi, gl = gl, p = pchisq(chi, gl, lower.tail = FALSE))
}
trv_pre  <- trv(bb, bb_sem_pre, 1)
trv_mult <- trv(bb, bb_sem_mult, 1)
trv_glob <- trv(bb, bb_nulo, 2)

tab_coef <- tibble(
  termo      = c("pre10", "mult10"),
  beta       = est[c("pre10", "mult10")],
  ep         = ep[c("pre10", "mult10")],
  z          = beta / ep,
  p_wald     = 2 * pnorm(-abs(z)),
  p_trv      = c(trv_pre[["p"]], trv_mult[["p"]]),
  OR_10pp    = exp(beta),
  OR_lo_wald = exp(ic_wald[termo, "lo"]),
  OR_hi_wald = exp(ic_wald[termo, "hi"]),
  OR_lo_perf = exp(ic_perf[termo, "lo"]),
  OR_hi_perf = exp(ic_perf[termo, "hi"]),
  DP_10pp    = sd_x[termo],
  OR_1DP     = exp(beta * DP_10pp),
  OR_1DP_lo  = exp(ic_wald[termo, "lo"] * DP_10pp),
  OR_1DP_hi  = exp(ic_wald[termo, "hi"] * DP_10pp)
)
print(as.data.frame(tab_coef), digits = 4)
write.csv(tab_coef, "output/tabelas/E_coeficientes.csv", row.names = FALSE)

## Intercepto (para registro)
c(intercepto = est[["(Intercept)"]], ep = ep[["(Intercept)"]])

## TRV global e por termo
tab_trv <- tibble(
  comparacao = c("Final vs nulo (pre10 e mult10)", "Sem pre10", "Sem mult10"),
  chi2 = c(trv_glob[["chi2"]], trv_pre[["chi2"]], trv_mult[["chi2"]]),
  gl   = c(2, 1, 1),
  p    = c(trv_glob[["p"]], trv_pre[["p"]], trv_mult[["p"]]),
  AIC_reduzido = c(AIC(bb_nulo), AIC(bb_sem_pre), AIC(bb_sem_mult)),
  AIC_final    = AIC(bb)
)
print(as.data.frame(tab_trv), digits = 4)
write.csv(tab_trv, "output/tabelas/E_trv.csv", row.names = FALSE)

## 2.4 Dispersão (ρ) com IC e quanto os preditores absorvem (E2)
ss   <- summary(bb$sdr, "fixed")
lphi <- ss["betadisp", "Estimate"]; se_l <- ss["betadisp", "Std. Error"]
rho_ic <- sort(1 / (1 + exp(lphi + c(-Z, Z) * se_l)))

phi_nulo <- sigma(bb_nulo); rho_nulo <- 1 / (1 + phi_nulo)
tab_rho <- tibble(
  modelo = c("Nulo", "Final"),
  rho    = c(rho_nulo, rho_bb),
  rho_lo = c(NA, rho_ic[1]),
  rho_hi = c(NA, rho_ic[2])
)
print(as.data.frame(tab_rho), digits = 4)
c(reducao_rho_pct = 100 * (1 - rho_bb / rho_nulo))
write.csv(tab_rho, "output/tabelas/E_rho.csv", row.names = FALSE)

## 2.5 Medidas de ajuste (descritivas, NÃO são teste de qualidade do ajuste)
bin   <- glm(cbind(y, demais) ~ pre10 + mult10, family = binomial, data = dat)
bin0  <- glm(cbind(y, demais) ~ 1,              family = binomial, data = dat)
ajuste <- tibble(
  medida = c("Redução da deviance, binomial (%)",
             "Log-verossim. beta-binomial: nulo", "Log-verossim. beta-binomial: final",
             "Ganho de log-verossimilhança", "AIC bb nulo", "AIC bb final", "BIC bb final"),
  valor = c(100 * (1 - deviance(bin) / deviance(bin0)),
            as.numeric(logLik(bb_nulo)), as.numeric(logLik(bb)),
            as.numeric(logLik(bb)) - as.numeric(logLik(bb_nulo)),
            AIC(bb_nulo), AIC(bb), BIC(bb))
)
print(as.data.frame(ajuste), digits = 5)
write.csv(ajuste, "output/tabelas/E_ajuste.csv", row.names = FALSE)


################################################################################
### 3. Robustez: mesma fórmula em outras famílias e subconjuntos (E3)
################################################################################
## Todos com IC de Wald, OR por +10 p.p., para comparar lado a lado.
extrai <- function(modelo, cenario, familia) {
  if (inherits(modelo, "glmmTMB")) {
    b <- fixef(modelo)$cond; s <- sqrt(diag(vcov(modelo)$cond))
  } else {
    b <- coef(modelo); s <- sqrt(diag(vcov(modelo)))
  }
  termos <- intersect(c("pre10", "mult10", "adol10"), names(b))
  tibble(cenario = cenario, familia = familia, termo = termos,
         OR = exp(b[termos]), lo = exp(b[termos] - Z * s[termos]),
         hi = exp(b[termos] + Z * s[termos]),
         p = 2 * pnorm(-abs(b[termos] / s[termos])))
}

dat30 <- filter(dat, n >= 30)
qbin  <- glm(cbind(y, demais) ~ pre10 + mult10, family = quasibinomial, data = dat)
bb_ad <- update(bb, . ~ . + adol10)
bb30  <- update(bb, data = dat30)
q30   <- glm(cbind(y, demais) ~ pre10 + mult10, family = quasibinomial, data = dat30)

robustez <- bind_rows(
  extrai(bb,   "Principal (jan-ago, 295 mun.)", "Beta-binomial"),
  extrai(qbin, "Principal (jan-ago, 295 mun.)", "Quasi-binomial"),
  extrai(bin,  "Principal (jan-ago, 295 mun.)", "Binomial (EP sem correção)"),
  extrai(bb_ad,"Com adol10",                    "Beta-binomial"),
  extrai(bb30, "Apenas n >= 30 (215 mun.)",     "Beta-binomial"),
  extrai(q30,  "Apenas n >= 30 (215 mun.)",     "Quasi-binomial")
)
print(as.data.frame(robustez), digits = 4)
write.csv(robustez, "output/tabelas/E_robustez_familias.csv", row.names = FALSE)

## Os demais cenários (jan-jul, pré-natal < 7, atípicos D7, espaciais D12) já
## foram calculados nas Etapas C e D. Listamos os arquivos para consolidar:
arqs <- list.files("output/tabelas",
                   pattern = "^(C_sensibilidades|D_sensibilidade_atipicos|D12_)",
                   full.names = TRUE)
arqs
for (a in arqs) { cat("\n=====", a, "=====\n"); print(utils::head(read.csv(a), 12)) }


################################################################################
### 4. Probabilidades preditas com IC (gráfico exigido) (E4)
################################################################################
## IC construído na escala do preditor linear (eta +- 1,96*EP) e depois
## transformado por plogis. Isso é IC para a PROBABILIDADE MÉDIA pi do modelo
## (não é intervalo de predição da taxa de um município).
nm <- c("(Intercept)", "pre10", "mult10")
est3 <- est[nm]; V3 <- V[nm, nm]

mu_pre  <- mean(dat$pre10)    # média entre municípios (sem ponderar)
mu_mult <- mean(dat$mult10)

curva <- function(var, grade) {
  X <- cbind(1,
             if (var == "pre10") grade else mu_pre,
             if (var == "mult10") grade else mu_mult)
  eta <- drop(X %*% est3)
  se  <- sqrt(rowSums((X %*% V3) * X))
  tibble(x_pct = grade * 10, prob = plogis(eta),
         lo = plogis(eta - Z * se), hi = plogis(eta + Z * se))
}

g_mult <- seq(0, max(dat$mult10), length.out = 120)   # só o suporte observado
g_pre  <- seq(0, max(dat$pre10),  length.out = 120)
c_mult <- curva("mult10", g_mult)
c_pre  <- curva("pre10",  g_pre)

c(max_mult_pct = 10 * max(dat$mult10), max_pre_pct = 10 * max(dat$pre10),
  mult_acima_10pp = sum(dat$mult10 > 1), pre_acima_p95 = sum(dat$pre10 > quantile(dat$pre10, .95)),
  media_pre_pct = 10 * mu_pre, media_mult_pct = 10 * mu_mult)

## Dados observados (taxa crua; ruído binomial grande nos pequenos)
dat <- dat %>% mutate(taxa = y / n, mult_pct = mult10 * 10, pre_pct = pre10 * 10)

tema <- theme_bw(base_size = 14)

## 4.1 Versão limpa (para os slides)
g1 <- ggplot(c_mult, aes(x_pct, prob)) +
  geom_ribbon(aes(ymin = lo, ymax = hi), alpha = 0.25) +
  geom_line(linewidth = 1.1) +
  geom_rug(data = dat, aes(x = mult_pct, y = NULL), sides = "b", alpha = 0.25) +
  geom_vline(xintercept = 10, linetype = 2) +
  annotate("text", x = 10.3, y = max(c_mult$hi) * 0.98, hjust = 0, size = 3.6,
           label = paste0("> 10 p.p.: só ", sum(dat$mult10 > 1), " municípios")) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
  labs(x = "Gestações múltiplas (% dos nascidos vivos do município)",
       y = "Probabilidade de baixo peso (π)",
       subtitle = paste0("Pré-natal insuficiente fixo na média (",
                         round(10 * mu_pre, 1), "%)")) + tema

g2 <- ggplot(c_pre, aes(x_pct, prob)) +
  geom_ribbon(aes(ymin = lo, ymax = hi), alpha = 0.25) +
  geom_line(linewidth = 1.1) +
  geom_rug(data = dat, aes(x = pre_pct, y = NULL), sides = "b", alpha = 0.25) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
  labs(x = "Pré-natal insuficiente (% dos nascidos vivos do município; < 6 consultas)",
       y = "Probabilidade de baixo peso (π)",
       subtitle = paste0("Gestação múltipla fixa na média (",
                         round(10 * mu_mult, 1), "%)")) + tema

ggsave("output/figuras/E_prob_mult10.png", g1, width = 7, height = 5, dpi = 200)
ggsave("output/figuras/E_prob_pre10.png",  g2, width = 7, height = 5, dpi = 200)
ggsave("output/figuras/E_prob_painel.png", g1 + g2, width = 14, height = 5, dpi = 200)

## 4.2 Versão com as taxas observadas (ponto ∝ n; eixo y cortado em 30%)
g1d <- g1 + geom_point(data = dat, aes(mult_pct, taxa, size = n),
                       alpha = 0.25, inherit.aes = FALSE) +
  coord_cartesian(ylim = c(0, 0.30)) + guides(size = "none")
g2d <- g2 + geom_point(data = dat, aes(pre_pct, taxa, size = n),
                       alpha = 0.25, inherit.aes = FALSE) +
  coord_cartesian(ylim = c(0, 0.30)) + guides(size = "none")
ggsave("output/figuras/E_prob_painel_com_dados.png", g1d + g2d,
       width = 14, height = 5, dpi = 200)
sum(dat$taxa > 0.30)   # municípios fora do eixo (cortados na figura)

## 4.3 Tabela de probabilidades em valores de referência
ref <- function(var, valores_pct) {
  g <- valores_pct / 10
  curva(var, g) %>% mutate(variavel = var, .before = 1)
}
tab_prob <- bind_rows(
  ref("mult10", c(0, 1, 2.4, 5, 10, 15)),
  ref("pre10",  c(0, 4, 7.8, 12, 20, 25))
)
print(as.data.frame(tab_prob), digits = 3)
write.csv(tab_prob, "output/tabelas/E_prob_referencia.csv", row.names = FALSE)
write.csv(bind_rows(mutate(c_mult, variavel = "mult10"),
                    mutate(c_pre,  variavel = "pre10")),
          "output/tabelas/E_curvas_prob.csv", row.names = FALSE)


################################################################################
### 5. Efeitos na escala da probabilidade (diferença e razão) com IC (E5)
################################################################################
## OR é razão de CHANCES; aqui traduzimos para diferença (p.p.) e razão de
## PROBABILIDADES, com IC por simulação (10.000 sorteios de beta ~ N(est, V)).
B <- MASS::mvrnorm(10000, mu = est3, Sigma = V3)

pi_de <- function(pre, mult, beta = B) plogis(beta[, 1] + beta[, 2] * pre + beta[, 3] * mult)

resumo_sim <- function(rotulo, p0, p1) {
  d <- 100 * (p1 - p0)       # diferença em pontos percentuais de probabilidade
  r <- p1 / p0
  tibble(contraste = rotulo,
         dif_pp = median(d), dif_lo = quantile(d, .025), dif_hi = quantile(d, .975),
         razao = median(r), raz_lo = quantile(r, .025), raz_hi = quantile(r, .975))
}

tab_efeitos <- bind_rows(
  resumo_sim("mult10: média -> média + 1 DP",
             pi_de(mu_pre, mu_mult), pi_de(mu_pre, mu_mult + sd_x[["mult10"]])),
  resumo_sim("mult10: média -> média + 10 p.p.",
             pi_de(mu_pre, mu_mult), pi_de(mu_pre, mu_mult + 1)),
  resumo_sim("mult10: 0% -> 5%",
             pi_de(mu_pre, 0), pi_de(mu_pre, 0.5)),
  resumo_sim("pre10: média -> média + 1 DP",
             pi_de(mu_pre, mu_mult), pi_de(mu_pre + sd_x[["pre10"]], mu_mult)),
  resumo_sim("pre10: média -> média + 10 p.p.",
             pi_de(mu_pre, mu_mult), pi_de(mu_pre + 1, mu_mult))
)
print(as.data.frame(tab_efeitos), digits = 3)
write.csv(tab_efeitos, "output/tabelas/E_efeitos_probabilidade.csv", row.names = FALSE)


################################################################################
### 6. Forest plot das razões de chances (E6)
################################################################################
fp <- robustez %>%
  filter(termo %in% c("pre10", "mult10"), cenario %in% c("Principal (jan-ago, 295 mun.)")) %>%
  mutate(termo = recode(termo, pre10 = "Pré-natal insuficiente (+10 p.p.)",
                        mult10 = "Gestação múltipla (+10 p.p.)"))

g_fp <- ggplot(fp, aes(x = OR, y = familia, xmin = lo, xmax = hi)) +
  geom_pointrange(size = 0.7) +
  geom_vline(xintercept = 1, linetype = 2) +
  scale_x_log10() +
  facet_wrap(~ termo, scales = "free_x") +
  labs(x = "Razão de chances (IC 95% de Wald, escala log)", y = NULL) + tema
ggsave("output/figuras/E_forest_familias.png", g_fp, width = 11, height = 4, dpi = 200)

fp_all <- robustez %>%
  filter(termo %in% c("pre10", "mult10"), familia != "Binomial (EP sem correção)") %>%
  mutate(rot = paste(cenario, familia, sep = " | "))
g_fp2 <- ggplot(fp_all, aes(x = OR, y = rot, xmin = lo, xmax = hi)) +
  geom_pointrange(size = 0.5) + geom_vline(xintercept = 1, linetype = 2) +
  scale_x_log10() + facet_wrap(~ termo, scales = "free_x") +
  labs(x = "Razão de chances por +10 p.p. (IC 95% Wald)", y = NULL) + tema
ggsave("output/figuras/E_forest_robustez.png", g_fp2, width = 12, height = 4.5, dpi = 200)


################################################################################
### 7. Calibração descritiva: observado x esperado (E7)
################################################################################
## Não é teste (alerta A4); só mostra se o modelo reproduz as taxas por grupos.
dat$pi_hat <- plogis(drop(cbind(1, dat$pre10, dat$mult10) %*% est3))
dat$esp    <- dat$n * dat$pi_hat

dat <- dat %>%
  mutate(decil = ntile(pi_hat, 10),
         classe_n = cut(n, c(-Inf, 29, 99, 499, Inf),
                        labels = c("< 30", "30-99", "100-499", ">= 500")))

cal <- function(g) {
  dat %>% group_by({{ g }}) %>%
    summarise(municipios = n(), nascidos = sum(n), obs = sum(y), esp = sum(esp),
              taxa_obs = obs / nascidos, taxa_esp = esp / nascidos, .groups = "drop")
}
cal_decil <- cal(decil)
cal_n     <- cal(classe_n)
print(as.data.frame(cal_decil), digits = 4)
print(as.data.frame(cal_n), digits = 4)
c(total_obs = sum(dat$y), total_esperado_bb = sum(dat$esp))

write.csv(cal_decil, "output/tabelas/E_calibracao_decil.csv", row.names = FALSE)
write.csv(cal_n,     "output/tabelas/E_calibracao_classe_n.csv", row.names = FALSE)

g_cal <- ggplot(cal_decil, aes(taxa_esp, taxa_obs)) +
  geom_abline(slope = 1, intercept = 0, linetype = 2) +
  geom_point(aes(size = nascidos)) +
  scale_x_continuous(labels = scales::percent_format(accuracy = 0.1)) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 0.1)) +
  labs(x = "Taxa esperada pelo modelo (por decil de π ajustado)",
       y = "Taxa observada (agregada)", size = "Nascidos") + tema
ggsave("output/figuras/E_calibracao.png", g_cal, width = 6.5, height = 5, dpi = 200)


################################################################################
### 8. Salvando
################################################################################
saveRDS(list(coef = tab_coef, trv = tab_trv, rho = tab_rho, ajuste = ajuste,
             robustez = robustez, prob_ref = tab_prob, efeitos = tab_efeitos,
             cal_decil = cal_decil, cal_n = cal_n,
             medias = c(pre10 = mu_pre, mult10 = mu_mult), dp = sd_x),
        "data/processed/E_resultados.rds")
writeLines(capture.output(sessionInfo()), "output/tabelas/sessionInfo_etapa_E.txt")

## FIM DA ETAPA E. Próxima: Etapa F (conclusão, slides, roteiro, Q&A).
