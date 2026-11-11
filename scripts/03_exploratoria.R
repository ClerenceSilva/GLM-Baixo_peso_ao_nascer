################################################################################
### CE314 - Modelos Lineares Generalizados | Trabalho final - Tema 8
### Baixo peso ao nascer em Santa Catarina (SINASC, 2026)
###
### ETAPA B - Análise exploratória (SEM ajustar nenhum modelo)
### Entrada : data/processed/base_municipal_sc2026.rds   (1 linha = 1 município)
### Saída   : output/figuras/B_*.png  e  output/tabelas/B_*.csv
###
### COMO RODAR: working directory = raiz do repositório; rodar de cima para baixo.
### Cada bloco imprime resultados: COLE as saídas no chat para eu conferir e
### preencher os campos [PREENCHER] de docs/etapa_B_exploratoria.md.
### Decisões numeradas (B1, B2, ...) explicadas em docs/etapa_B_exploratoria.md
################################################################################

################################################################################
### 0. Pacotes, pastas e parâmetros
################################################################################
suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(tibble)
  library(ggplot2)
})

for (pasta in c("output/figuras", "output/tabelas")) {
  dir.create(pasta, recursive = TRUE, showWarnings = FALSE)
}
options(scipen = 999)

salvar <- function(p, nome, w = 9, h = 5.5) {
  ggsave(file.path("output/figuras", nome), p, width = w, height = h, dpi = 300)
}
tema <- theme_bw(base_size = 13)

preds <- c("prop_adolescente", "prop_esc_baixa", "prop_prenatal_insuf",
           "prop_gestacao_mult", "prop_mae_35mais")
rotulos <- c(prop_adolescente    = "Mães adolescentes (< 20 anos)",
             prop_esc_baixa      = "Mães com < 8 anos de estudo",
             prop_prenatal_insuf = "Pré-natal insuficiente (< 6 consultas)",
             prop_gestacao_mult  = "Gestação múltipla",
             prop_mae_35mais     = "Mães com 35 anos ou mais")

################################################################################
### 1. Leitura e checagens de integridade (devem bater com a Etapa A)
################################################################################
b <- readRDS("data/processed/base_municipal_sc2026.rds")

stopifnot(
  nrow(b) == 295,
  sum(b$n_nascidos) == 64469,
  sum(b$baixo_peso) == 5302,
  all(b$baixo_peso + b$demais == b$n_nascidos),
  !anyDuplicated(b$cod6)
)

b <- b %>%
  mutate(
    taxa   = baixo_peso / n_nascidos,                       # só descrição
    elogit = log((baixo_peso + 0.5) / (demais + 0.5)),      # logito empírico (B5)
    classe_n = cut(n_nascidos, breaks = c(0, 29, 99, 499, Inf),
                   labels = c("< 30", "30-99", "100-499", ">= 500"))
  )

p0 <- sum(b$baixo_peso) / sum(b$n_nascidos)   # taxa global = 8,22%
p0

################################################################################
### 2. A resposta: como a taxa de baixo peso se distribui?  (B1)
################################################################################
## 2.1 Resumo da taxa municipal (CADA município pesa igual - é só descrição)
summary(b$taxa)
sd(b$taxa)

## 2.2 Tamanho dos municípios (denominador n_i)
summary(b$n_nascidos)
quantile(b$n_nascidos, c(.1, .25, .5, .75, .9, .95))

## 2.3 Tabela por classe de tamanho: o ponto central da Etapa B.
## Se a taxa varia MUITO mais nos pequenos, isso é ruído binomial, não "efeito".
tab_classe <- b %>%
  group_by(classe_n) %>%
  summarise(
    n_municipios     = n(),
    nascimentos      = sum(n_nascidos),
    pct_nascimentos  = round(100 * sum(n_nascidos) / sum(b$n_nascidos), 1),
    casos_baixo_peso = sum(baixo_peso),   # nome novo: não sobrescrever a coluna de entrada
    taxa_agregada    = round(100 * sum(baixo_peso) / sum(n_nascidos), 2),
    taxa_min         = round(100 * min(taxa), 1),
    taxa_max         = round(100 * max(taxa), 1),
    dp_taxa          = round(100 * sd(taxa), 2),
    municipios_taxa0 = sum(baixo_peso == 0),
    .groups = "drop"
  )
print(tab_classe)
write.csv(tab_classe, "output/tabelas/B_tabela_classe_tamanho.csv",
          row.names = FALSE, fileEncoding = "UTF-8")

## 2.4 Histogramas
g_taxa <- ggplot(b, aes(x = taxa)) +
  geom_histogram(bins = 30, color = "white", fill = "grey60") +
  geom_vline(xintercept = p0, linetype = 2, linewidth = 0.9) +
  scale_x_continuous(labels = scales::percent) +
  labs(x = "Taxa de baixo peso do município", y = "Nº de municípios",
       title = "Distribuição da taxa municipal de baixo peso",
       subtitle = "Linha tracejada: taxa global do estado (8,22%)") + tema
salvar(g_taxa, "B_hist_taxa.png")

g_n <- ggplot(b, aes(x = n_nascidos)) +
  geom_histogram(bins = 30, color = "white", fill = "grey60") +
  scale_x_log10() +
  labs(x = "Nascidos vivos com peso conhecido (escala log)", y = "Nº de municípios",
       title = "Distribuição do tamanho dos municípios (n_i)") + tema
salvar(g_n, "B_hist_n.png")

## 2.5 Sanidade: extremos (municípios GRANDES e taxas extremas)
b %>% arrange(desc(n_nascidos)) %>%
  select(nome, n_nascidos, baixo_peso, taxa) %>% head(8)
b %>% filter(n_nascidos >= 100) %>% arrange(desc(taxa)) %>%
  select(nome, n_nascidos, baixo_peso, taxa) %>% head(5)
b %>% filter(n_nascidos >= 100) %>% arrange(taxa) %>%
  select(nome, n_nascidos, baixo_peso, taxa) %>% head(5)

################################################################################
### 3. Gráfico de funil: o quanto é só acaso binomial?  (B2)
################################################################################
## Hipótese de referência (H0 de "todos iguais"): todo município tem pi = p0.
## Então Y_i ~ Binomial(n_i, p0) e os limites esperados dependem só de n_i.
grade <- tibble(n = min(b$n_nascidos):max(b$n_nascidos)) %>%
  mutate(lo95  = qbinom(0.025, n, p0) / n, hi95  = qbinom(0.975, n, p0) / n,
         lo998 = qbinom(0.001, n, p0) / n, hi998 = qbinom(0.999, n, p0) / n)

b <- b %>%
  mutate(
    fora95  = baixo_peso < qbinom(0.025, n_nascidos, p0) |
              baixo_peso > qbinom(0.975, n_nascidos, p0),
    fora998 = baixo_peso < qbinom(0.001, n_nascidos, p0) |
              baixo_peso > qbinom(0.999, n_nascidos, p0)
  )

## Sob "todos iguais", esperaríamos ~5% (<= 5%, pois a binomial é discreta)
## fora dos limites de 95% e ~0,2% fora dos de 99,8%.
c(fora95 = sum(b$fora95), esperado95_aprox = round(0.05 * nrow(b), 1),
  fora998 = sum(b$fora998), esperado998_aprox = round(0.002 * nrow(b), 1))
table(classe_n = b$classe_n, fora95 = b$fora95)

g_funil <- ggplot() +
  geom_ribbon(data = grade, aes(x = n, ymin = lo998, ymax = hi998),
              fill = "grey90") +
  geom_ribbon(data = grade, aes(x = n, ymin = lo95, ymax = hi95),
              fill = "grey75") +
  geom_hline(yintercept = p0, linetype = 2) +
  geom_point(data = b, aes(x = n_nascidos, y = taxa, color = fora998),
             alpha = 0.7, size = 1.8) +
  scale_color_manual(values = c("FALSE" = "black", "TRUE" = "red"),
                     labels = c("dentro", "fora (99,8%)"), name = NULL) +
  scale_x_log10() +
  scale_y_continuous(labels = scales::percent) +
  labs(x = "Nascidos vivos no município (n_i, escala log)",
       y = "Taxa de baixo peso",
       title = "Gráfico de funil",
       subtitle = "Faixas: limites binomiais de 95% (escura) e 99,8% (clara) sob taxa única = 8,22%") +
  tema + theme(legend.position = "bottom")
salvar(g_funil, "B_funil.png")

## Prévia da dispersão: estatística de Pearson do modelo NULO (só intercepto).
## ATENÇÃO: NÃO é o diagnóstico final (aqui ainda não há preditores).
X2_nulo  <- sum((b$baixo_peso - b$n_nascidos * p0)^2 /
                (b$n_nascidos * p0 * (1 - p0)))
phi_nulo <- X2_nulo / (nrow(b) - 1)
c(X2_nulo = X2_nulo, gl = nrow(b) - 1, phi_nulo = phi_nulo)

################################################################################
### 4. Contagens esperadas: por que o qui-quadrado da deviance não vale (A4)
################################################################################
b <- b %>% mutate(esp_sucessos = n_nascidos * p0,
                  esp_insucessos = n_nascidos * (1 - p0))
tab_esp <- tibble(
  criterio = c("n_i * p0 < 3", "n_i * p0 < 5", "n_i * (1-p0) < 3"),
  n_municipios = c(sum(b$esp_sucessos < 3), sum(b$esp_sucessos < 5),
                   sum(b$esp_insucessos < 3))
) %>% mutate(pct = round(100 * n_municipios / nrow(b), 1))
print(tab_esp)
write.csv(tab_esp, "output/tabelas/B_contagens_esperadas.csv",
          row.names = FALSE, fileEncoding = "UTF-8")
## Regra dos slides: o teste de deviance exige m*pi >= 3 e m*(1-pi) >= 3.

################################################################################
### 5. Os preditores: distribuição, zeros e assimetria  (B3)
################################################################################
summary(b[preds])

assimetria <- function(x) { z <- (x - mean(x)) / sd(x); mean(z^3) }
tab_pred <- tibble(
  preditor = preds,
  media    = sapply(preds, function(v) mean(b[[v]])),
  mediana  = sapply(preds, function(v) median(b[[v]])),
  dp       = sapply(preds, function(v) sd(b[[v]])),
  minimo   = sapply(preds, function(v) min(b[[v]])),
  maximo   = sapply(preds, function(v) max(b[[v]])),
  n_zeros  = sapply(preds, function(v) sum(b[[v]] == 0)),
  pct_zeros = round(100 * n_zeros / nrow(b), 1),
  assimetria = sapply(preds, function(v) assimetria(b[[v]]))
) %>% mutate(across(c(media, mediana, dp, minimo, maximo, assimetria),
                    ~ round(.x, 4)))
print(tab_pred)
write.csv(tab_pred, "output/tabelas/B_resumo_preditores.csv",
          row.names = FALSE, fileEncoding = "UTF-8")

b_long <- b %>%
  pivot_longer(all_of(preds), names_to = "preditor", values_to = "x") %>%
  mutate(rotulo = factor(rotulos[preditor], levels = rotulos))

g_hist_pred <- ggplot(b_long, aes(x = x)) +
  geom_histogram(bins = 30, color = "white", fill = "grey60") +
  facet_wrap(~ rotulo, scales = "free", ncol = 3) +
  scale_x_continuous(labels = scales::percent) +
  labs(x = "Proporção no município", y = "Nº de municípios",
       title = "Distribuição dos preditores candidatos") + tema
salvar(g_hist_pred, "B_hist_preditores.png", w = 11, h = 6)

## B3b: o RUÍDO dos preditores também depende de n_i (municípios pequenos têm
## proporções mais "dispersas" só por acaso) -> alerta A3 (erro de medida).
tab_ruido <- b %>%
  group_by(classe_n) %>%
  summarise(across(all_of(preds), list(media = mean, dp = sd),
                   .names = "{.col}__{.fn}"), .groups = "drop") %>%
  mutate(across(where(is.numeric), ~ round(.x, 4)))
print(tab_ruido)
write.csv(tab_ruido, "output/tabelas/B_ruido_preditores_por_tamanho.csv",
          row.names = FALSE, fileEncoding = "UTF-8")

################################################################################
### 6. Cada preditor x taxa de baixo peso  (B4, B5, B6)
################################################################################
## 6.1 Dispersão na escala do logito empírico, tamanho do ponto ~ n_i,
##     reta ponderada (por n_i) e suavização loess ponderada.
##     (a regressão logística é LINEAR NO LOGITO: é isso que queremos checar)
g_elogit <- ggplot(b_long, aes(x = x, y = elogit)) +
  geom_point(aes(size = n_nascidos), alpha = 0.35) +
  geom_smooth(aes(weight = n_nascidos, linetype = "reta ponderada"),
              method = "lm", formula = y ~ x, se = FALSE, color = "blue") +
  geom_smooth(aes(weight = n_nascidos, linetype = "loess ponderado"),
              method = "loess", formula = y ~ x, span = 0.9, se = FALSE,
              color = "red") +
  facet_wrap(~ rotulo, scales = "free_x", ncol = 3) +
  scale_x_continuous(labels = scales::percent) +
  scale_size_continuous(range = c(0.5, 6), name = "n_i") +
  scale_linetype_manual(values = c("reta ponderada" = 1, "loess ponderado" = 2),
                        name = NULL) +
  labs(x = "Proporção no município",
       y = "Logito empírico de baixo peso: log((y+0,5)/(n-y+0,5))",
       title = "Relação de cada preditor com o baixo peso (escala do logito)",
       subtitle = "Tamanho do ponto proporcional a n_i; linhas ponderadas por n_i") +
  tema + theme(legend.position = "bottom")
salvar(g_elogit, "B_preditor_x_logito.png", w = 12, h = 7)

## 6.2 Versão "agrupada": taxa AGREGADA por faixas do preditor, com IC de Wilson.
##     Só exploratório! (o modelo usará o preditor CONTÍNUO, não faixas)
bin_x <- function(x) {
  if (mean(x == 0) >= 0.10) {                   # muitos zeros: zero vira grupo próprio
    g <- rep(0L, length(x)); pos <- x > 0
    br <- unique(quantile(x[pos], seq(0, 1, 0.25)))
    g[pos] <- as.integer(cut(x[pos], br, include.lowest = TRUE))
    g
  } else {
    as.integer(cut(x, unique(quantile(x, seq(0, 1, 0.2))), include.lowest = TRUE))
  }
}
wilson <- function(y, n, z = 1.96) {
  p <- y / n
  centro <- (p + z^2 / (2 * n)) / (1 + z^2 / n)
  meia <- z * sqrt(p * (1 - p) / n + z^2 / (4 * n^2)) / (1 + z^2 / n)
  list(lo = centro - meia, hi = centro + meia)
}

b_bins <- bind_rows(lapply(preds, function(v) {
  tibble(preditor = v, grupo = bin_x(b[[v]]), x = b[[v]],
         y = b$baixo_peso, nn = b$n_nascidos)
})) %>%
  group_by(preditor, grupo) %>%
  summarise(n_mun = n(), N = sum(nn), Y = sum(y),
            x_medio = weighted.mean(x, nn), .groups = "drop") %>%
  mutate(taxa = Y / N,
         lo = wilson(Y, N)$lo, hi = wilson(Y, N)$hi,
         rotulo = factor(rotulos[preditor], levels = rotulos))
print(b_bins %>% mutate(across(c(x_medio, taxa, lo, hi), ~ round(.x, 4))), n = 40)
write.csv(b_bins, "output/tabelas/B_taxa_por_faixas_preditor.csv",
          row.names = FALSE, fileEncoding = "UTF-8")

g_bins <- ggplot(b_bins, aes(x = x_medio, y = taxa)) +
  geom_hline(yintercept = p0, linetype = 2, color = "grey40") +
  geom_errorbar(aes(ymin = lo, ymax = hi), width = 0, color = "grey40") +
  geom_point(aes(size = N)) +
  geom_line() +
  facet_wrap(~ rotulo, scales = "free_x", ncol = 3) +
  scale_x_continuous(labels = scales::percent) +
  scale_y_continuous(labels = scales::percent) +
  scale_size_continuous(range = c(1.5, 5), name = "Nascimentos\nna faixa") +
  labs(x = "Proporção média (ponderada) do preditor na faixa",
       y = "Taxa agregada de baixo peso (IC 95% de Wilson)",
       title = "Taxa de baixo peso por faixas de cada preditor (exploratório)",
       subtitle = "Faixas = quintis dos municípios (zeros como grupo próprio, se >= 10%)") +
  tema + theme(legend.position = "bottom")
salvar(g_bins, "B_preditor_x_taxa_faixas.png", w = 12, h = 7)

## 6.3 Correlações com a resposta (descritivas, NÃO são testes)
wcor <- function(x, y, w) {
  cov.wt(cbind(x, y), wt = w / sum(w), cor = TRUE)$cor[1, 2]
}
tab_cor_resp <- tibble(
  preditor = preds,
  cor_pearson_taxa_simples = sapply(preds, function(v) cor(b[[v]], b$taxa)),
  cor_spearman_taxa        = sapply(preds, function(v)
                                    cor(b[[v]], b$taxa, method = "spearman")),
  cor_pond_taxa            = sapply(preds, function(v)
                                    wcor(b[[v]], b$taxa, b$n_nascidos)),
  cor_pond_elogit          = sapply(preds, function(v)
                                    wcor(b[[v]], b$elogit, b$n_nascidos))
) %>% mutate(across(where(is.numeric), ~ round(.x, 3)))
print(tab_cor_resp)

## 6.4 Mesma coisa só com municípios de n_i >= 30 (prévia da sensibilidade (d))
b30 <- b %>% filter(n_nascidos >= 30)
tab_cor_resp30 <- tibble(
  preditor = preds,
  n_municipios = nrow(b30),
  cor_pond_taxa_n30 = sapply(preds, function(v)
                       wcor(b30[[v]], b30$taxa, b30$n_nascidos)),
  cor_pond_elogit_n30 = sapply(preds, function(v)
                       wcor(b30[[v]], b30$elogit, b30$n_nascidos))
) %>% mutate(across(where(is.numeric), ~ round(.x, 3)))
print(tab_cor_resp30)

write.csv(left_join(tab_cor_resp, tab_cor_resp30, by = "preditor"),
          "output/tabelas/B_correlacoes_com_resposta.csv",
          row.names = FALSE, fileEncoding = "UTF-8")

################################################################################
### 7. Relação ENTRE os preditores (prévia da multicolinearidade)  (B7)
################################################################################
cor_pearson  <- round(cor(b[preds]), 2)
cor_spearman <- round(cor(b[preds], method = "spearman"), 2)
cor_pearson
cor_spearman
write.csv(cor_pearson, "output/tabelas/B_cor_preditores_pearson.csv",
          fileEncoding = "UTF-8")
write.csv(cor_spearman, "output/tabelas/B_cor_preditores_spearman.csv",
          fileEncoding = "UTF-8")
## Maior correlação (em módulo) fora da diagonal
cp <- cor(b[preds]); diag(cp) <- NA
max(abs(cp), na.rm = TRUE)

png("output/figuras/B_pares_preditores.png", width = 2400, height = 2400, res = 250)
pairs(b[preds], labels = unname(rotulos[preds]), pch = 20,
      col = rgb(0, 0, 0, 0.35), cex = 0.8, gap = 0.4)
dev.off()

################################################################################
### 8. Fechamento
################################################################################
saveRDS(b, "data/processed/base_municipal_sc2026_exploratoria.rds")
writeLines(capture.output(sessionInfo()), "output/tabelas/sessionInfo_etapa_B.txt")

## FIM DA ETAPA B. Próxima: Etapa C (modelagem), a partir de
## data/processed/base_municipal_sc2026.rds
