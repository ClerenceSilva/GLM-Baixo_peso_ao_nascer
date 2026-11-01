################################################################################
### CE314 - Modelos Lineares Generalizados | Trabalho final - Tema 8
### Baixo peso ao nascer em Santa Catarina (SINASC, 2026)
###
### ETAPA A - Preparação da base
### Entrada : data/raw/DNSC2026.dbc  (microdados das Declarações de Nascidos Vivos)
### Saída   : data/processed/base_municipal_sc2026.rds / .csv  (1 linha = 1 município)
###           output/tabelas/*.csv   (fluxo de perdas, qualidade dos dados, etc.)
###
### COMO RODAR: abra o projeto na RAIZ do repositório (working directory = raiz)
### e execute o script de cima para baixo. Cada bloco imprime verificações:
### LEIA as saídas, elas alimentam o texto do trabalho (seção "Dados").
###
### Todas as decisões estão numeradas (D1, D2, ...) e explicadas em
### docs/etapa_A_preparacao_dados.md
################################################################################


################################################################################
### 0. Pacotes e pastas
################################################################################

suppressPackageStartupMessages({
    library(dplyr)
    library(tibble)
})

## Pacotes usados apenas em pontos específicos (chamados com ::):
##   datasusr (leitura do .dbc), geobr + sf (lista oficial de municípios de SC)

for (pasta in c("data/raw", "data/processed", "output/tabelas")) {
    dir.create(pasta, recursive = TRUE, showWarnings = FALSE)
}

options(scipen = 999)

## Parâmetros do trabalho (alterar aqui, e só aqui, se algo mudar)
UF_PREFIXO     <- "42"      # código IBGE da UF: 42 = Santa Catarina
ANO_ANALISE    <- 2026      # orientações: usar o ano mais recente disponível
CORTE_BAIXOPESO <- 2500     # g; baixo peso = peso < 2500 g (definição do tema)
CORTE_PRENATAL <- 6         # nº de consultas; insuficiente = menos de 6 (D10)
COD_MUN_IGNORADO <- "420000" # código SINASC para "município ignorado" de SC (D6)


################################################################################
### 1. Leitura dos microdados brutos
################################################################################

arq_dbc <- "data/raw/DNSC2026.dbc"
arq_rds <- "data/raw/dnsc2026_bruto.rds"   # cópia em RDS: leitura rápida depois

if (!file.exists(arq_rds)) {
    stopifnot(file.exists(arq_dbc))
    dn_bruto <- datasusr::read_datasus_dbc(arq_dbc)
    saveRDS(dn_bruto, arq_rds)
} else {
    dn_bruto <- readRDS(arq_rds)
}

## Data de extração: orientações exigem informar. O horário de modificação do
## arquivo local costuma ser o dia do download. CONFIRME e, se preciso, digite
## a data manualmente (ex.: as.Date("2026-10-31")).
data_extracao <- as.Date(file.info(arq_dbc)$mtime)
data_extracao

dim(dn_bruto)          # linhas (nascimentos) x colunas (variáveis)
names(dn_bruto)

## Todas as colunas vêm como texto (<chr>): é o padrão do DATASUS. Por isso
## precisamos converter datas e números "na mão" (bloco 3).


################################################################################
### 2. Inspeção inicial e unicidade
################################################################################

## Cada linha deve ser UMA Declaração de Nascido Vivo (um recém-nascido).
## (Gêmeos geram duas linhas: isso é esperado e é a unidade do SINASC - D4.)

n_linhas_duplicadas <- sum(duplicated(dn_bruto))
n_contador_repetido <- sum(duplicated(dn_bruto$contador))

n_linhas_duplicadas   # linhas 100% idênticas  -> esperado: 0
n_contador_repetido   # 'contador' repetido    -> esperado: 0

## Se algum desses números for > 0, NÃO remova automaticamente: investigue
## (View(dn_bruto[duplicated(dn_bruto$contador) | duplicated(dn_bruto$contador, fromLast = TRUE), ]))
## e registre a decisão no documento da Etapa A.


################################################################################
### 3. Conversão de tipos e criação de variáveis individuais
################################################################################

## Funções auxiliares: texto -> número, sem emitir avisos
para_num <- function(x) suppressWarnings(as.numeric(x))

dn <- dn_bruto %>%
    transmute(
        contador,
        codmunres  = trimws(codmunres),               # município de residência da mãe
        dtnasc     = as.Date(dtnasc, format = "%d%m%Y"),
        dtrecebim  = as.Date(dtrecebim, format = "%d%m%Y"),
        peso_num   = para_num(peso),
        idade_num  = para_num(idademae),
        escmae     = trimws(escmae),
        gravidez   = trimws(gravidez),
        cons_num   = para_num(consprenat)
    )

## --- Conferência: algum valor NÃO vazio virou NA na conversão? ---------------
## (indicaria um código inesperado no arquivo)
conv_falhas <- c(
    peso      = sum(dn_bruto$peso      != "" & is.na(dn$peso_num)),
    idademae  = sum(dn_bruto$idademae  != "" & is.na(dn$idade_num)),
    consprenat = sum(dn_bruto$consprenat != "" & is.na(dn$cons_num)),
    dtnasc    = sum(dn_bruto$dtnasc    != "" & is.na(dn$dtnasc))
)
conv_falhas   # esperado: tudo 0

## --- Distribuição dos códigos de cada variável (olhe os valores "estranhos") --
table(dn$escmae,   useNA = "ifany")   # válidos: 1-5 ; 9 = ignorado
table(dn$gravidez, useNA = "ifany")   # válidos: 1-3 ; 9 = ignorado
summary(dn$idade_num)
summary(dn$cons_num)                  # 99 = ignorado (D9/D10)
summary(dn$peso_num)

## --- Peso: o que conta como "ignorado"? (D5) ---------------------------------
## Consideramos peso IGNORADO: vazio/NA, 0 g ou 9999 g. Veja se há outros
## códigos suspeitos na tabela abaixo antes de aceitar esta regra.
sort(table(dn$peso_num[dn$peso_num %in% c(0, 9999) | is.na(dn$peso_num)],
           useNA = "ifany"), decreasing = TRUE)

dn <- dn %>%
    mutate(
        peso_ignorado = is.na(peso_num) | peso_num %in% c(0, 9999),

        ## Códigos fora do domínio válido viram NA (ignorado) - D9.
        ## NÃO são convertidos em zero nem em "categoria de referência".
        idade_val = ifelse(!is.na(idade_num) & idade_num >= 10 & idade_num <= 59,
                           idade_num, NA_real_),
        esc_val   = ifelse(escmae   %in% as.character(1:5), as.integer(escmae),   NA_integer_),
        grav_val  = ifelse(gravidez %in% as.character(1:3), as.integer(gravidez), NA_integer_),
        cons_val  = ifelse(!is.na(cons_num) & cons_num >= 0 & cons_num <= 98,
                           cons_num, NA_real_),

        ## Resposta (nível do nascido vivo) - D4
        baixo_peso = peso_num < CORTE_BAIXOPESO,

        ## Indicadores que serão agregados por município - D8, D9, D10
        adolescente    = idade_val < 20,               # mãe de 10 a 19 anos
        mae_35mais     = idade_val >= 35,              # (preditor EXTRA, opcional)
        esc_baixa      = esc_val %in% 1:3,             # < 8 anos de estudo
        prenatal_insuf = cons_val < CORTE_PRENATAL,    # < 6 consultas
        gestacao_mult  = grav_val %in% 2:3             # dupla, tripla ou mais
    ) %>%
    ## %in% devolve FALSE (não NA) quando o código é inválido; corrigimos:
    mutate(
        esc_baixa     = ifelse(is.na(esc_val),  NA, esc_baixa),
        gestacao_mult = ifelse(is.na(grav_val), NA, gestacao_mult)
    )

## Teste de consistência cruzada: 'consprenat' (nº de consultas) deve bater
## com a variável antiga 'consultas' (categorias 1=nenhuma, 2=1-3, 3=4-6, 4=7+).
## Se a tabela mostrar valores fora da "diagonal lógica", repense a D10.
chk <- tibble(
    consultas = dn_bruto$consultas,
    cons      = dn$cons_val
) %>%
    filter(!is.na(cons)) %>%
    mutate(faixa_cons = cut(cons, c(-Inf, 0, 3, 6.5, Inf),
                            labels = c("1: nenhuma", "2: 1-3", "3: 4-6", "4: 7+")))
## Atenção: a faixa "4-6" inclui 4,5,6 e '7+' começa em 7 (6.5 é só o corte).
table(consultas_antiga = chk$consultas, consprenat_faixa = chk$faixa_cons)


################################################################################
### 4. Fluxo de perdas (quantos registros saem em cada filtro e POR QUÊ)
################################################################################

## Cada filtro é aplicado em sequência; guardamos o n depois de cada um.

d0 <- dn
d1 <- d0 %>% filter(substr(codmunres, 1, 2) == UF_PREFIXO)               # D2
d2 <- d1 %>% filter(!is.na(dtnasc), format(dtnasc, "%Y") == ANO_ANALISE) # D3
d3 <- d2 %>% filter(codmunres != COD_MUN_IGNORADO)                       # D6
d4 <- d3 %>% filter(!peso_ignorado)                                      # D5

fluxo_perdas <- tibble(
    etapa = c(
        "Registros no arquivo DNSC2026",
        "Mãe residente em SC (codmunres começa com 42)",
        "Nascimento ocorrido em 2026 (dtnasc)",
        "Município de residência identificado (exclui 420000)",
        "Peso ao nascer conhecido  => BASE DE ANÁLISE"
    ),
    n = c(nrow(d0), nrow(d1), nrow(d2), nrow(d3), nrow(d4))
) %>%
    mutate(perdidos_na_etapa = lag(n) - n,
           pct_perdido_etapa = round(100 * perdidos_na_etapa / lag(n), 3))

fluxo_perdas

## Frequência de peso ignorado (exigência do tema: "informar sua frequência")
n_peso_ign <- nrow(d3) - nrow(d4)
pct_peso_ign <- 100 * n_peso_ign / nrow(d3)
c(n_peso_ignorado = n_peso_ign, pct = round(pct_peso_ign, 3))

## Município ignorado (separado, conforme orientações)
c(n_municipio_ignorado = nrow(d2) - nrow(d3))

## --- Período EFETIVAMENTE coberto pelo arquivo (D3) --------------------------
periodo <- c(primeiro_nasc = as.character(min(d2$dtnasc)),
             ultimo_nasc   = as.character(max(d2$dtnasc)),
             ultimo_recebimento_no_sistema = as.character(max(d2$dtrecebim, na.rm = TRUE)))
periodo

## Nascimentos por mês: os últimos meses costumam estar INCOMPLETOS por atraso
## de notificação. Anote isso nas limitações.
table(format(d2$dtnasc, "%Y-%m"))


################################################################################
### 5. Lista oficial de municípios de SC (para não perder os zeros) - D7
################################################################################

## Equivale ao "Exibir linhas zeradas" do TABNET: sem uma lista de referência,
## município sem nenhum nascimento simplesmente "some" da base.

mun_oficial <- tryCatch({
    mm <- geobr::read_municipality(code_muni = "SC", year = 2020, showProgress = FALSE)
    mm <- sf::st_drop_geometry(mm)
    tibble(cod6 = substr(as.character(mm$code_muni), 1, 6),   # SINASC usa 6 dígitos
           nome = mm$name_muni)
}, error = function(e) NULL)

## Plano B: se o geobr falhar (sem internet), baixe a lista do IBGE e salve em
## data/raw/municipios_sc_ibge.csv com as colunas cod6 (6 dígitos) e nome.
if (is.null(mun_oficial) && file.exists("data/raw/municipios_sc_ibge.csv")) {
    mun_oficial <- read.csv("data/raw/municipios_sc_ibge.csv",
                            colClasses = "character", fileEncoding = "UTF-8") %>% as_tibble()
}
if (is.null(mun_oficial)) {
    stop("Sem lista oficial de municípios. Instale/rode o geobr com internet ",
         "ou crie data/raw/municipios_sc_ibge.csv (cod6, nome).")
}

nrow(mun_oficial)   # esperado: 295 municípios em SC

## Os códigos dos registros existem na lista oficial? (esperado: nenhum fora)
codigos_fora_da_lista <- setdiff(unique(d3$codmunres), mun_oficial$cod6)
codigos_fora_da_lista
if (length(codigos_fora_da_lista) > 0) {
    warning("Há códigos de município nos dados que não estão na lista oficial. ",
            "Investigue (código antigo? erro de digitação?) antes de prosseguir.")
    print(table(d3$codmunres[d3$codmunres %in% codigos_fora_da_lista]))
}


################################################################################
### 6. Agregação: de nascido vivo (microdado) para município
################################################################################

## Proporção ignorando os NA da própria variável (D9); NA se todos forem NA.
prop_valida <- function(x) if (all(is.na(x))) NA_real_ else mean(x, na.rm = TRUE)

agg <- d4 %>%
    group_by(codmunres) %>%
    summarise(
        n_nascidos = n(),                                  # DENOMINADOR (peso conhecido)
        baixo_peso = sum(baixo_peso),                      # SUCESSOS
        demais     = n_nascidos - baixo_peso,              # INSUCESSOS
        across(c(adolescente, esc_baixa, prenatal_insuf, gestacao_mult, mae_35mais),
               prop_valida, .names = "prop_{.col}"),
        .groups = "drop"
    )

## Peso ignorado por município (informativo - NÃO entra no denominador)
ign_mun <- d3 %>%
    group_by(codmunres) %>%
    summarise(n_peso_ignorado = sum(peso_ignorado), .groups = "drop")

base_mun <- mun_oficial %>%
    left_join(agg,     by = c("cod6" = "codmunres")) %>%
    left_join(ign_mun, by = c("cod6" = "codmunres")) %>%
    ## Município sem nascimento: contagem ZERO REAL (não é dado ausente) - D7.
    mutate(across(c(n_nascidos, baixo_peso, demais, n_peso_ignorado),
                  ~ coalesce(.x, 0L))) %>%
    mutate(
        taxa_baixo_peso = ifelse(n_nascidos > 0, baixo_peso / n_nascidos, NA_real_),
        entra_no_ajuste = n_nascidos > 0                   # denominador zero fica fora
    ) %>%
    arrange(cod6)


################################################################################
### 7. Verificações de integridade (o script PARA se algo estiver errado)
################################################################################

stopifnot(
    nrow(base_mun) == nrow(mun_oficial),                    # nenhuma linha perdida/duplicada no join
    !anyDuplicated(base_mun$cod6),                          # 1 linha por município
    sum(base_mun$n_nascidos) == nrow(d4),                   # soma municipal = base de análise
    all(base_mun$baixo_peso + base_mun$demais == base_mun$n_nascidos),
    all(base_mun$baixo_peso >= 0 & base_mun$demais >= 0)
)

prop_cols <- grep("^prop_", names(base_mun), value = TRUE)
stopifnot(all(unlist(base_mun[prop_cols]) >= 0 & unlist(base_mun[prop_cols]) <= 1, na.rm = TRUE))

## Municípios que NÃO entram no ajuste (denominador zero)
sem_nascimento <- base_mun %>% filter(!entra_no_ajuste)
nrow(sem_nascimento)
sem_nascimento$nome

base_modelo <- base_mun %>% filter(entra_no_ajuste)
nrow(base_modelo)    # n de observações do modelo (nº de municípios)


################################################################################
### 8. Qualidade dos dados: o que falta em cada preditor? (D9)
################################################################################

## Percentual de nascidos da base de análise com informação IGNORADA em cada
## variável usada para construir preditores.
qualidade <- tibble(
    variavel = c("idade da mãe", "escolaridade da mãe", "nº consultas pré-natal", "tipo de gravidez"),
    n_ignorado = c(sum(is.na(d4$idade_val)), sum(is.na(d4$esc_val)),
                   sum(is.na(d4$cons_val)),  sum(is.na(d4$grav_val)))
) %>%
    mutate(pct_ignorado = round(100 * n_ignorado / nrow(d4), 3))
qualidade

## Municípios cujo preditor ficou NA (todos os registros ignorados nessa variável)
colSums(is.na(base_modelo[prop_cols]))


################################################################################
### 9. Resumo descritivo mínimo (checagem de sanidade, não é a EDA ainda)
################################################################################

## Taxa global de baixo peso: no Brasil costuma ficar em torno de 8-9%.
## Valor muito distante disso => provável erro de filtro ou de definição.
taxa_global <- sum(base_modelo$baixo_peso) / sum(base_modelo$n_nascidos)
round(100 * taxa_global, 2)

c(total_nascidos = sum(base_modelo$n_nascidos),
  total_baixo_peso = sum(base_modelo$baixo_peso),
  n_municipios = nrow(base_modelo))

## Tamanho dos denominadores: municípios pequenos terão taxas muito instáveis.
summary(base_modelo$n_nascidos)
quantile(base_modelo$n_nascidos, c(.1, .25, .5, .75, .9))
sum(base_modelo$n_nascidos < 30)    # municípios com menos de 30 nascimentos
sum(base_modelo$baixo_peso == 0)    # municípios sem nenhum caso de baixo peso

summary(base_modelo[prop_cols])

## Correlação entre os preditores (adianta o diagnóstico de multicolinearidade
## da Etapa D): valores acima de ~0,7 merecem atenção.
round(cor(base_modelo[prop_cols], use = "pairwise.complete.obs"), 2)


################################################################################
### 10. Salvando os resultados
################################################################################

saveRDS(base_mun,    "data/processed/base_municipal_sc2026_completa.rds")  # 295 linhas
saveRDS(base_modelo, "data/processed/base_municipal_sc2026.rds")           # só n_nascidos > 0
write.csv(base_modelo, "data/processed/base_municipal_sc2026.csv",
          row.names = FALSE, fileEncoding = "UTF-8")

write.csv(fluxo_perdas, "output/tabelas/fluxo_perdas.csv", row.names = FALSE, fileEncoding = "UTF-8")
write.csv(qualidade,    "output/tabelas/qualidade_variaveis.csv", row.names = FALSE, fileEncoding = "UTF-8")
write.csv(sem_nascimento, "output/tabelas/municipios_sem_nascimento.csv", row.names = FALSE, fileEncoding = "UTF-8")

metadados <- list(
    arquivo_fonte        = arq_dbc,
    data_extracao        = data_extracao,
    periodo_coberto      = periodo,
    n_linhas_duplicadas  = n_linhas_duplicadas,
    n_contador_repetido  = n_contador_repetido,
    n_peso_ignorado      = n_peso_ign,
    pct_peso_ignorado    = pct_peso_ign,
    n_municipio_ignorado = nrow(d2) - nrow(d3),
    n_municipios_oficiais = nrow(mun_oficial),
    n_municipios_no_ajuste = nrow(base_modelo),
    parametros = list(corte_baixo_peso = CORTE_BAIXOPESO, corte_prenatal = CORTE_PRENATAL)
)
saveRDS(metadados, "output/tabelas/metadados_etapa_A.rds")

writeLines(capture.output(sessionInfo()), "output/tabelas/sessionInfo_etapa_A.txt")

## FIM DA ETAPA A. Próxima: Etapa B (análise exploratória) a partir de
## data/processed/base_municipal_sc2026.rds
