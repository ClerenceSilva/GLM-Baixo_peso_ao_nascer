################################################################################
### CE314 - Trabalho final - Tema 8 (baixo peso ao nascer, SC, 2026)
### Conferência EXTERNA da base municipal com a tabulação do TABNET
###
### Entrada : data/raw/tabnet_nv_sc2026_peso.csv   (CSV copiado do TABNET)
###           data/processed/base_municipal_sc2026_completa.rds (Etapa A)
### Saída   : output/tabelas/conferencia_tabnet.csv
###
### Passo a passo da extração no TABNET: docs/etapa_A_preparacao_dados.md, Seção 9.
### Linha = Município (residência da mãe); Coluna = Peso ao nascer (faixas);
### Conteúdo = nascimentos por residência da mãe; marcar "Exibir linhas zeradas".
################################################################################

suppressPackageStartupMessages({
    library(dplyr)
    library(tibble)
})

arq_tabnet <- "data/raw/tabnet_nv_sc2026_peso.csv"
stopifnot(file.exists(arq_tabnet))

base <- readRDS("data/processed/base_municipal_sc2026_completa.rds")


################################################################################
### 1. Leitura do CSV do TABNET
################################################################################

## O CSV do TABNET: separador ";", codificação latin1, algumas linhas de título
## no topo, a tabela, e notas de rodapé no fim.
linhas <- iconv(readLines(arq_tabnet, warn = FALSE), from = "latin1", to = "UTF-8")

## Cabeçalho = primeira linha que começa com "Município" (com ou sem aspas)
i_cab <- grep('^"?Munic', linhas)[1]
stopifnot(!is.na(i_cab))

## Notas de rodapé: o CSV do TABNET pode NÃO trazê-las (nesta extração não trouxe
## nada). Mostramos as últimas linhas do arquivo para conferir. A legenda do
## traço "-" fica na tela do TABNET (rodapé da página), não necessariamente no CSV.
tail(linhas, 8)

tab <- read.csv2(text = linhas[i_cab:length(linhas)],
                 check.names = FALSE, stringsAsFactors = FALSE, colClasses = "character")
names(tab)[1] <- "municipio"

## Mantém só linhas de município (começam com o código de 6 dígitos);
## remove a linha "Total" e as notas (item das orientações: "remover linhas de total")
total_tabnet <- tab[grepl("^Total", tab$municipio), , drop = FALSE]
tab <- tab[grepl("^[0-9]{6}", tab$municipio), , drop = FALSE]
tab$cod6 <- substr(tab$municipio, 1, 6)

nrow(tab)   # esperado: 295 (se "Exibir linhas zeradas" estava marcado)


################################################################################
### 2. Conversão dos números (o traço "-" significa zero NO TABNET)
################################################################################

## Atenção às orientações: não converter traço em zero "no escuro". Confira, nas
## legenda do TABNET (tela da página) que "-" é "dado numérico igual a zero". Se o
## CSV não trouxer notas, a VALIDAÇÃO EMPÍRICA é o próprio teste de totais abaixo:
## se "-" não significasse zero, os totais por município não bateriam com os meus.
## Só então:
cols_num <- setdiff(names(tab), c("municipio", "cod6"))

## Quantas células são "-" ou vazias? (se for 0, não há o que converter)
celulas <- unlist(tab[cols_num])
c(tracos = sum(trimws(celulas) == "-"), vazias = sum(trimws(celulas) == ""))
para_n <- function(x) {
    x <- trimws(x)
    x[x %in% c("-", "")] <- "0"
    as.numeric(gsub("\\.", "", x))       # remove separador de milhar, se houver
}
tab[cols_num] <- lapply(tab[cols_num], para_n)

## Classificação das colunas de peso. CONFIRA o resultado impresso!
cols_peso <- setdiff(cols_num, "Total")
grupo <- case_when(
    grepl("gnorado", cols_peso)                  ~ "ignorado",
    grepl("^Menos|^500|^1000|^1500", cols_peso)  ~ "baixo_peso",   # < 2500 g
    grepl("^2500|^3000|^4000", cols_peso)        ~ "demais",       # >= 2500 g
    TRUE                                         ~ "NAO_CLASSIFICADA"
)
print(tibble(coluna = cols_peso, grupo = grupo))
stopifnot(!any(grupo == "NAO_CLASSIFICADA"))
stopifnot(all(c("baixo_peso", "demais", "ignorado") %in% grupo))

tn <- tab %>%
    transmute(
        cod6,
        tn_total  = if ("Total" %in% names(tab)) Total else rowSums(across(all_of(cols_peso))),
        tn_baixo  = rowSums(across(all_of(cols_peso[grupo == "baixo_peso"]))),
        tn_demais = rowSums(across(all_of(cols_peso[grupo == "demais"]))),
        tn_ign    = rowSums(across(all_of(cols_peso[grupo == "ignorado"])))
    )

## Autoconsistência do próprio TABNET
stopifnot(all(tn$tn_total == tn$tn_baixo + tn$tn_demais + tn$tn_ign))


################################################################################
### 3. Comparação município a município
################################################################################

cmp <- base %>%
    transmute(cod6, nome,
              meu_total = n_nascidos + n_peso_ignorado,   # tudo que o município registrou
              meu_baixo = baixo_peso,
              meu_demais = demais,
              meu_ign = n_peso_ignorado) %>%
    left_join(tn, by = "cod6") %>%
    mutate(
        dif_total = tn_total - meu_total,    # >0: TABNET tem MAIS nascimentos que a minha base
        dif_baixo = tn_baixo - meu_baixo,
        dif_demais = tn_demais - meu_demais,
        dif_ign = tn_ign - meu_ign
    )

## 3.1 Todos os municípios casaram?
sum(is.na(cmp$tn_total))                      # esperado: 0
setdiff(tn$cod6, base$cod6)                   # esperado: character(0)

## 3.2 Totais do estado
cmp %>% summarise(across(c(meu_total, tn_total, meu_baixo, tn_baixo, meu_demais, tn_demais, meu_ign, tn_ign), sum))

## 3.3 Municípios com QUALQUER diferença
dif <- cmp %>% filter(dif_total != 0 | dif_baixo != 0 | dif_demais != 0 | dif_ign != 0)
nrow(dif)                                     # esperado: 0 (mesma prévia)
print(dif, n = 40)

## 3.4 Se houver diferenças, o sentido é sempre "TABNET >= minha base"?
##     (consistente com o TABNET estar em prévia mais nova, com mais agosto)
c(tabnet_menor = sum(cmp$dif_total < 0), tabnet_maior = sum(cmp$dif_total > 0))

## 3.5 Taxa de baixo peso (descritiva): TABNET x minha base
c(taxa_minha = sum(cmp$meu_baixo) / sum(cmp$meu_baixo + cmp$meu_demais),
  taxa_tabnet = sum(cmp$tn_baixo) / sum(cmp$tn_baixo + cmp$tn_demais))

write.csv(cmp, "output/tabelas/conferencia_tabnet.csv", row.names = FALSE, fileEncoding = "UTF-8")

## LEITURA DO RESULTADO
## - nrow(dif) == 0  -> base validada contra o TABNET (mesma prévia).
## - diferenças só com TABNET > base -> prévia mais nova do TABNET; descreva isso e,
##   se possível, compare jan-jul (meses completos).
## - diferenças nos dois sentidos -> investigar (filtros, código de município,
##   critério de peso ignorado) ANTES de seguir para a Etapa B.
