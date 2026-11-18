################################################################################
### CE314 - Modelos Lineares Generalizados | Trabalho final - Tema 8
### ETAPA D (complemento) - D12: SENSIBILIDADE ESPACIAL
###
### Pergunta: a dependência espacial fraca encontrada no Moran (I ~ 0,08)
### muda as conclusões sobre pre10 e mult10 (estimativas, EP, significância)?
###
### Modelos comparados (todos beta-binomial, ligação logito):
###   M0  final:               pre10 + mult10
###   M1  + região:            pre10 + mult10 + região (efeito fixo regional; mesorregião
###                            2010 ou, se indisponível no geobr, região intermediária 2019)
###   M2  + coordenadas:       pre10 + mult10 + lon + lat (tendência linear)
###   M3  + superfície:        pre10 + mult10 + poly(lon, lat, 2) (tendência quadrática)
###   M4  + efeito espacial:   pre10 + mult10 + efeito aleatório espacial exponencial
###                            (modelo mais sofisticado; pode não convergir)
###
### Entrada : data/processed/base_municipal_sc2026.rds
### Saída   : output/tabelas/D12_*.csv ; output/figuras/D12_*.png ;
###           data/processed/D12_espacial.rds
### Requer  : geobr, sf, spdep (e internet para as malhas do geobr)
###
### Cole as saídas no chat. Decisões explicadas em docs/etapa_D_diagnostico.md (D12).
################################################################################

suppressPackageStartupMessages({
  library(dplyr)
  library(tibble)
  library(ggplot2)
  library(glmmTMB)
  library(splines)
})
stopifnot(all(vapply(c("geobr", "sf", "spdep"), requireNamespace, logical(1), quietly = TRUE)))

for (pasta in c("data/processed", "output/tabelas", "output/figuras")) {
  dir.create(pasta, recursive = TRUE, showWarnings = FALSE)
}
options(scipen = 999)
SEMENTE      <- 67
N_SIM_MORAN  <- 9999
tema <- theme_bw(base_size = 13)

################################################################################
### 1. Dados (mesma preparação da Etapa D)
################################################################################
base <- readRDS("data/processed/base_municipal_sc2026.rds")
b <- base %>%
  filter(entra_no_ajuste) %>%
  mutate(n = n_nascidos, y = baixo_peso,
         pre10 = prop_prenatal_insuf * 10,
         mult10 = prop_gestacao_mult * 10)
stopifnot(nrow(b) == 295, all(b$y + b$demais == b$n))

################################################################################
### 2. Geografia: coordenadas (km, UTM 22S) e região de cada município
################################################################################
mm <- geobr::read_municipality(code_muni = "SC", year = 2020, showProgress = FALSE)
mm$cod6 <- substr(as.character(mm$code_muni), 1, 6)
sfb <- dplyr::inner_join(mm, b[, "cod6"], by = "cod6")
stopifnot(nrow(sfb) == 295)

## SIRGAS 2000 / UTM 22S (EPSG:31982): distâncias em metros, adequadas a SC
sfb_utm <- sf::st_transform(sfb, 31982)
cent <- suppressWarnings(sf::st_centroid(sf::st_geometry(sfb_utm)))
xy   <- sf::st_coordinates(cent)
coord <- tibble(cod6 = sfb$cod6, x_km = xy[, 1] / 1000, y_km = xy[, 2] / 1000)

## Divisão regional do M1: tenta mesorregião (IBGE 2010); se não estiver disponível
## na versão do geobr, usa região intermediária (IBGE 2019). Cada município recebe a
## região do polígono mais próximo do seu centroide. `nome_divisao` guarda qual foi usada.
tentativas <- list(
  list(rotulo = "mesorregião", col = "name_meso",
       ler = function() geobr::read_meso_region(code_meso = "SC", year = 2010, showProgress = FALSE)),
  list(rotulo = "região intermediária", col = "name_intermediate",
       ler = function() geobr::read_intermediate_region(code_intermediate = "SC", year = 2019, showProgress = FALSE))
)
meso <- NULL
nome_divisao <- NA_character_
for (tt in tentativas) {
  res <- tryCatch(tt$ler(),
                  error = function(e) { message("Falhou (", tt$rotulo, "): ", conditionMessage(e)); NULL })
  if (!is.null(res) && tt$col %in% names(res)) {
    meso <- res; nome_divisao <- tt$rotulo; col_reg <- tt$col
    break
  }
}
message("Divisão regional usada no M1: ", nome_divisao)

if (!is.null(meso)) {
  meso_utm <- sf::st_transform(meso, 31982)
  id_meso  <- sf::st_nearest_feature(cent, meso_utm)
  coord$regiao <- factor(meso_utm[[col_reg]][id_meso])
  stopifnot(!anyNA(coord$regiao))
  print(table(coord$regiao))
} else {
  warning("Não consegui obter a divisão regional: M1 será pulado (M2-M4 seguem).")
}

d <- b %>% left_join(coord, by = "cod6")
stopifnot(!anyNA(d$x_km))
d$lon100 <- (d$x_km - mean(d$x_km)) / 100   # unidades de 100 km, centradas
d$lat100 <- (d$y_km - mean(d$y_km)) / 100

## Descritivo por região: os preditores e a taxa variam entre regiões?
## (se variam, o efeito regional pode "disputar" variação com pre10/mult10)
if ("regiao" %in% names(d)) {
  por_regiao <- d %>%
    group_by(regiao) %>%
    summarise(n_mun = n(), nascidos = sum(n),
              taxa_agregada = sum(y) / sum(n),
              media_pre10 = mean(pre10), media_mult10 = mean(mult10),
              .groups = "drop")
  print(por_regiao, width = Inf)
  write.csv(por_regiao, "output/tabelas/D12_por_regiao.csv", row.names = FALSE)
}

################################################################################
### 3. Ajuste dos modelos
################################################################################
fit_gen <- function(formula, dados) {
  suppressWarnings(glmmTMB(formula, family = betabinomial(link = "logit"), data = dados))
}

m0 <- fit_gen(cbind(y, demais) ~ pre10 + mult10, d)
m1 <- if ("regiao" %in% names(d)) fit_gen(cbind(y, demais) ~ pre10 + mult10 + regiao, d) else NULL
m2 <- fit_gen(cbind(y, demais) ~ pre10 + mult10 + lon100 + lat100, d)
m3 <- fit_gen(cbind(y, demais) ~ pre10 + mult10 + poly(lon100, lat100, degree = 2), d)

## M4: efeito aleatório espacial (covariância exponencial no espaço, km).
## Um único "grupo" (todo o estado) e uma posição por município.
## ATENÇÃO: pode não convergir; o tryCatch registra e o script segue.
d$pos <- glmmTMB::numFactor(d$x_km, d$y_km)
d$grp <- factor(1)
m4 <- tryCatch(
  suppressWarnings(glmmTMB(cbind(y, demais) ~ pre10 + mult10 + exp(pos + 0 | grp),
                           family = betabinomial(link = "logit"), data = d)),
  error = function(e) { message("M4 falhou: ", conditionMessage(e)); NULL }
)
if (!is.null(m4) && !isTRUE(m4$sdr$pdHess)) {
  warning("M4 não convergiu bem (pdHess = FALSE): trate como NÃO CONFIÁVEL.")
}
if (!is.null(m4)) { print(summary(m4)); print(VarCorr(m4)) }

## O rótulo do M1 reflete a divisão realmente usada (propaga para tabelas e gráfico)
rot_m1 <- if (is.na(nome_divisao)) "M1 + região" else paste("M1 +", nome_divisao)
modelos <- list(m0, m1, m2, m3, m4)
names(modelos) <- c("M0 final", rot_m1, "M2 + lon/lat",
                    "M3 + superfície 2ª ordem", "M4 + efeito espacial")
modelos <- modelos[!vapply(modelos, is.null, logical(1))]
for (nm in names(modelos)) {   # fit_gen() silencia avisos: confira a Hessiana de todos
  if (!isTRUE(modelos[[nm]]$sdr$pdHess)) warning(nm, ": pdHess = FALSE (erros-padrão não confiáveis).")
}

################################################################################
### 4. Estimativas: OR por +10 p.p., EP e significância em cada modelo
################################################################################
z <- qnorm(0.975)
extrai2 <- function(f, rotulo) {
  s <- summary(f)$coefficients$cond
  g <- function(v) {
    e <- s[v, "Estimate"]; se <- s[v, "Std. Error"]
    c(OR = exp(e), lo = exp(e - z * se), hi = exp(e + z * se),
      p = s[v, "Pr(>|z|)"], EP = se)
  }
  gm <- g("mult10"); gp <- g("pre10")
  tibble(modelo = rotulo,
         pdHess = isTRUE(f$sdr$pdHess),
         AIC = AIC(f), logLik = as.numeric(logLik(f)),
         OR_mult = gm["OR"], IC_mult_inf = gm["lo"], IC_mult_sup = gm["hi"],
         p_mult = gm["p"], EP_mult = gm["EP"],
         OR_pre = gp["OR"], IC_pre_inf = gp["lo"], IC_pre_sup = gp["hi"],
         p_pre = gp["p"], EP_pre = gp["EP"],
         rho = 1 / (1 + sigma(f)))
}
tab <- bind_rows(lapply(names(modelos), function(nm) extrai2(modelos[[nm]], nm)))
tab <- tab %>%
  mutate(mud_OR_mult_pct = 100 * (OR_mult / OR_mult[1] - 1),
         mud_OR_pre_pct  = 100 * (OR_pre  / OR_pre[1]  - 1),
         razao_EP_mult   = EP_mult / EP_mult[1],
         razao_EP_pre    = EP_pre  / EP_pre[1],
         dAIC_vs_M0      = AIC - AIC[1])
print(tab, width = Inf)
write.csv(tab, "output/tabelas/D12_comparacao_modelos.csv", row.names = FALSE)

## Testes de razão de verossimilhanças para os modelos ENCAIXADOS em M0
## (M4 não entra: variância no limite do espaço paramétrico; compare por AIC)
cat("\n--- TRV: M0 x M1 (", rot_m1, ") ---\n"); if (!is.null(m1)) print(anova(m0, m1))
cat("\n--- TRV: M0 x M2 (lon/lat) ---\n");       print(anova(m0, m2))
cat("\n--- TRV: M0 x M3 (superfície) ---\n");    print(anova(m0, m3))

## Regra pré-definida (escrita ANTES de ver os números):
##  - "conclusão robusta": OR muda < ~10% e a significância (p < 0,05) se mantém;
##  - se pre10 perder significância em algum modelo, reportar que a evidência
##    de pre10 depende do controle regional/espacial;
##  - razão de EP > ~1,2 indica que o EP do modelo final estava otimista.

################################################################################
### 5. O Moran dos resíduos melhora? (por modelo)
################################################################################
nb_q <- spdep::poly2nb(sfb_utm, queen = TRUE)
lw_q <- spdep::nb2listw(nb_q, style = "W", zero.policy = TRUE)
nb_k <- spdep::knn2nb(spdep::knearneigh(xy, k = 5))
lw_k <- spdep::nb2listw(nb_k, style = "W")

pearson_de <- function(f, re = FALSE) {
  eta <- if (re) predict(f, type = "link") else predict(f, type = "link", re.form = NA)
  mu_f <- plogis(eta); ph <- sigma(f)
  (d$y - d$n * mu_f) / sqrt(d$n * mu_f * (1 - mu_f) * (d$n + ph) / (1 + ph))
}
moran1 <- function(r, lw) {
  r_sf <- r[match(sfb$cod6, d$cod6)]          # reordena para a ordem da malha
  set.seed(SEMENTE)
  mc <- spdep::moran.mc(r_sf, lw, nsim = N_SIM_MORAN, zero.policy = TRUE)
  c(I = unname(mc$statistic), p_mc = mc$p.value)
}
lin <- list()
for (nm in names(modelos)) {
  f <- modelos[[nm]]
  tipos <- if (startsWith(nm, "M4")) c("marginal (parte fixa)", "condicional (com efeito espacial)") else "marginal (parte fixa)"
  for (tp in tipos) {
    r <- pearson_de(f, re = grepl("condicional", tp))
    q <- moran1(r, lw_q); k <- moran1(r, lw_k)
    lin[[length(lin) + 1]] <- tibble(modelo = nm, residuo = tp,
                                      I_contig = q["I"], p_contig = q["p_mc"],
                                      I_5viz = k["I"], p_5viz = k["p_mc"])
  }
}
tab_moran <- bind_rows(lin)
print(tab_moran, width = Inf)
write.csv(tab_moran, "output/tabelas/D12_moran_por_modelo.csv", row.names = FALSE)

################################################################################
### 6. Gráfico: as OR mudam? (forest plot por modelo)
################################################################################
## M4 fica fora do gráfico (continua na tabela/CSV): citar isso na legenda da figura
tab_graf <- tab %>% filter(!startsWith(modelo, "M4"))

long <- bind_rows(
  tab_graf %>% transmute(modelo, termo = "mult10 (gestação múltipla, +10 p.p.)",
                         OR = OR_mult, inf = IC_mult_inf, sup = IC_mult_sup),
  tab_graf %>% transmute(modelo, termo = "pre10 (pré-natal insuficiente, +10 p.p.)",
                         OR = OR_pre, inf = IC_pre_inf, sup = IC_pre_sup)
) %>% mutate(modelo = factor(modelo, levels = rev(unique(modelo))))

g <- ggplot(long, aes(x = OR, y = modelo)) +
  geom_pointrange(aes(xmin = inf, xmax = sup)) +
  geom_vline(xintercept = 1, linetype = 2, colour = "red") +
  facet_wrap(~ termo, scales = "free_x") +
  labs(x = "Razão de chances (IC 95%, Wald)", y = NULL) + tema
ggsave("output/figuras/D12_forest_espacial.png", g, width = 11, height = 4.5, dpi = 150)

saveRDS(list(tabela = tab, moran = tab_moran, modelos = modelos),
        "data/processed/D12_espacial.rds")

## FIM DO D12. Cole no chat: a tabela de comparação (bloco 4), os TRV, o resumo
## e VarCorr do M4 (se rodou), a tabela do Moran (bloco 5) e, se puder, a
## figura D12_forest_espacial.png.
