# Etapa A — Preparação da base

**Trabalho final CE314 (MLG) · Tema 8 · Baixo peso ao nascer em Santa Catarina (SINASC, 2026)**
Script correspondente: `scripts/01_preparacao_base.R`
Status: **executada**. Os resultados reais estão na Seção 5; os alertas, na Seção 6.

> Como usar este documento: (1) raciocínio geral, (2) cada decisão numerada (D1…D14) com *o que foi feito,
> alternativas, por que esta, risco e como explicar em 1 frase*, (3) dicionário de variáveis, (4) a tabela de
> resultados, (5) os alertas encontrados na execução e (6) perguntas prováveis da banca.

---

## 1. O problema em uma página

**Pergunta do tema:** o que diferencia os municípios catarinenses quanto à *probabilidade* de um nascido
vivo ter baixo peso (< 2.500 g)?

**Por que "binomial agrupada"?** Em cada município *i* há `n_i` nascidos vivos, dos quais `Y_i` têm baixo
peso. Supomos

```
Y_i ~ Binomial(n_i, π_i)          logit(π_i) = β0 + β1·x1_i + β2·x2_i + ...
```

em que `π_i` é a probabilidade de baixo peso no município *i* e os `x` são características *do município*
(ex.: % de mães adolescentes). No R: `glm(cbind(baixo_peso, demais) ~ ..., family = binomial)`.

* **Sucessos** = nascidos com peso < 2.500 g (`baixo_peso`).
* **Insucessos** = nascidos com peso ≥ 2.500 g (`demais`).
* **Denominador** = `n_nascidos` = sucessos + insucessos = nascidos vivos com **peso conhecido**.

("Sucesso" é só o nome do evento de interesse na binomial; não é "bom".)

**Exigências do enunciado/orientações e onde foram atendidas:**

| Exigência (Temas.pdf / Orientações.pdf) | Onde/como foi atendida |
|---|---|
| Município de residência **da mãe**, não de ocorrência | D2 |
| Período definido; informar fonte, **data de extração** e **período efetivamente coberto** | D1, D3 |
| "Exibir linhas zeradas" e conferir se todos os municípios aparecem | D7 |
| Distinguir zero de informação ausente/ignorada; não converter ignorado em zero | D5, D9 |
| Excluir peso ignorado do denominador e **informar sua frequência** | D5 |
| Remover linhas de total; separar município ignorado e informar quantos registros | D6 |
| Conferir duplicidades, consistência das contagens e perdas | D13 + bloco 7 do script |
| Município sem nascimento elegível (denominador 0) não entra no ajuste | D7 |
| 4 a 8 preditores candidatos, com justificativa | D8 |
| Preditores quantitativos contínuos; **não** transformar % em "alto/baixo" por quartis | D11 |
| Evitar preditores que sejam componentes da resposta ou calculados a partir dela | D8 |
| Compatibilidade temporal (ano de cada variável) | D1 |
| Registrar fonte, definição, unidade e ano de cada variável | Seção 4 |

---

## 2. Decisões (D1 a D14)

### D1 — Fonte: microdados do SINASC (`DNSC2026.dbc`), 2ª prévia, em vez de tabulação do TABNET

* **Decisão:** usar as Declarações de Nascidos Vivos individuais de SC, 2026, lidas com
  `datasusr::read_datasus_dbc()`. O site informa: **"Dados de 2026 – 2ª prévia – data de extração 01/09/2026"**.
* **Alternativa:** tabular no TABNET (município de residência × peso ao nascer), como o enunciado descreve.
* **Por que microdados:**
  1. Os preditores municipais pedidos (adolescentes, escolaridade, pré-natal, gestações múltiplas) são
     **calculados a partir dos próprios nascimentos**. Com microdados eles saem da *mesma fonte, mesmo ano e
     mesma população* da resposta, o que dá compatibilidade temporal perfeita.
  2. Com o TABNET seriam várias tabulações separadas a juntar, com mais risco de inconsistência.
  3. Reprodutibilidade: o script refaz tudo a partir do arquivo bruto.
* **Equivalência:** a tabulação do TABNET é a contagem dos microdados por município. Conferência opcional:
  tabule 1–2 municípios no TABNET e compare com a base.
* **Duas datas diferentes (não confundir):** *data de extração* = 01/09/2026 (informada pelo DATASUS; é a
  que vai no relatório) e *data de download* = 31/10/2026 (quando você baixou o arquivo; fica nos metadados).
* **"Prévia" importa:** são dados preliminares, sujeitos a revisão pelo Ministério da Saúde (limitação).
* **Em uma frase:** *"Usei os microdados porque os preditores municipais saem dos mesmos nascimentos da
  resposta, garantindo mesma fonte e mesmo ano."*

### D2 — Unidade geográfica: município de **residência da mãe** (`codmunres`)

* **Decisão:** agrupar por `codmunres`, mantendo registros com `codmunres` começando por `42` (SC).
* **Por que residência e não ocorrência (`codmunnasc`):** o tema pergunta sobre diferenças entre municípios
  *de residência das mães*; as características (idade, escolaridade…) são das mães residentes; e muitas
  mulheres parem em município-polo diferente do que moram (a ocorrência concentraria casos nos polos).
* **Resultado da execução:** o filtro "mãe residente em SC" **não eliminou nenhum registro** (64.472 → 64.472).
  Se o arquivo fosse por ocorrência haveria mães de outras UFs; como não há nenhuma, o arquivo está
  organizado por **UF de residência**. Reforço: no cabeçalho aparecem nascimentos de mães de SC ocorridos
  em município de outro estado (`codmunnasc` 12…, 15…). O script agora tabula isso
  (`nasceu_em_SC`); **Resultado: 653 nascimentos (1,01%) ocorreram fora de SC e 63.819 em SC**. Isso confirma que o arquivo é por residência da mãe.
* **Consequência:** não há perda por este critério e o problema "mães de SC que parem fora de SC ficariam
  ausentes" **não se aplica** a este arquivo.
* **Código de município:** o SINASC usa 6 dígitos (sem dígito verificador); a lista oficial foi reduzida a
  6 dígitos para casar.

### D3 — Período: jan–ago/2026 (parcial); agosto é incompleto

* **Decisão:** manter só `dtnasc` em 2026 (as orientações pedem o ano mais recente). Nenhum registro de
  outro ano apareceu (perda = 0).
* **Período efetivamente coberto (saída do R):** **01/01/2026 a 31/08/2026**; último recebimento no sistema
  em 01/09/2026.
* **Achado (ver D3b e Seção 6):** nascimentos por mês = 8.543 · 7.517 · 8.837 · 8.751 · 8.788 · 8.372 ·
  8.578 · **5.086**. Agosto tem ~60% do volume dos meses completos: **notificação ainda incompleta**.

### D3b — Como tratar agosto (decisão a confirmar com as verificações do script)

* **Opções:**
  1. **Manter jan–ago como base principal** e rodar **análise de sensibilidade jan–jul** na Etapa C.
  2. Restringir tudo a jan–jul (meses completos), perdendo ~5.100 nascimentos (≈ 7,9%).
* **Recomendação:** opção 1, desde que as checagens (novo bloco do script) mostrem que agosto não é
  diferente de jan–jul. As checagens são: nascimentos por dia de agosto; taxa de baixo peso de agosto vs
  jan–jul (`prop.test`); perfil dos preditores; municípios que perderiam todos os nascimentos sem agosto.
* **Por que manter não é absurdo:** cada registro presente é um nascimento válido; a incompleteza afeta o
  tamanho `n_i`, não a validade de `Y_i ~ Binomial(n_i, π_i)`. O risco real é de **seleção**: se os
  nascimentos que demoram a ser notificados forem sistematicamente diferentes (por município ou por risco),
  a taxa de agosto fica enviesada. As checagens testam isso; a sensibilidade quantifica o impacto.
* **Por que restringir também é defensável:** dá uma janela limpa (jan–jul) e elimina o risco de seleção;
  custo: menos dados e municípios pequenos ainda menores.
* **Regra de decisão sugerida:** se a taxa de agosto estiver próxima da de jan–jul (diferença pequena e sem
  evidência forte) **e** nenhum município ficar sem nascimentos sem agosto, mantenha jan–ago como principal.
  Caso contrário, use jan–jul como principal e jan–ago como sensibilidade. **DECISÃO TOMADA: manter jan–ago como base principal** (resultado das checagens abaixo), com sensibilidade jan–jul na Etapa C.
* **Resultado das checagens:**
  1. **Por dia:** de 01 a 14/08 há ~210–290 nascimentos/dia (normal, ~270/dia); a queda começa por volta do dia 15 e é
     forte depois do dia 22; nos dias 27–31 há 14, 4, 2, 1 e 1 registros. Ou seja, **agosto está praticamente completo
     até meados do mês e muito incompleto na 2ª quinzena**.
  2. **Taxa de baixo peso:** agosto **8,22%** (418/5.085) e jan–jul **8,22%** (4.884/59.384); `prop.test`: p = 1,
     IC95% da diferença (−0,79 p.p.; +0,79 p.p.). **Sem diferença.**
  3. **Preditores:** perfis muito parecidos (ex.: adolescentes 7,35% vs 7,46%; pré-natal insuficiente 8,3% vs 9,0%;
     mães ≥35 anos 20,8% vs 20,3%).
  4. **Municípios:** nenhum perderia todos os nascimentos sem agosto; sem agosto cada município mantém de 71% a 100% do
     seu `n` (mediana 92%).
* **Como justificar:** a incompletude de agosto reduz `n_i`, mas não alterou a taxa nem o perfil dos preditores, e a
  sensibilidade jan–jul mostrará se as conclusões mudam. Ressalva honesta: ausência de diferença nas médias não *prova*
  ausência de seleção; por isso a sensibilidade.
* **Como descrever o período no trabalho:** "nascimentos de 01/01 a 31/08/2026 (2ª prévia, extração 01/09/2026),
  com notificação de agosto incompleta na segunda quinzena".
* **Em uma frase:** *"Agosto estava incompleto; verifiquei se diferia dos demais meses e rodei a análise com
  e sem ele para mostrar que a conclusão não depende dessa escolha."*

### D4 — Definição da resposta (sucessos, insucessos, denominador)

* `baixo_peso` = `peso < 2500` g. `demais` = `peso ≥ 2500`. `n_nascidos` = soma, apenas com peso conhecido.
* **Unidade:** o *nascido vivo* (gêmeos = duas linhas), como no SINASC e como o tema define.
* **Pesos extremos:** o mínimo é **122 g**, que provavelmente é erro de digitação, mas **não é excluído**:
  qualquer valor < 2.500 g já é baixo peso, então a classificação não muda (e excluir "porque parece
  estranho" seria uma exclusão não justificada). O script lista os 10 menores e conta os < 500 g.
* **Em uma frase:** *"Baixo peso é peso < 2.500 g entre nascidos vivos com peso conhecido; os demais são os
  insucessos."*

### D5 — Peso ignorado: sai do denominador e a frequência é reportada

* **Decisão:** peso é ignorado se vazio/NA, `0` ou `9999`. Esses registros não entram como sucesso nem
  insucesso.
* **Resultado:** apenas **3 registros** (0,005%), todos **vazios/NA**; não há `0` nem `9999`. A regra
  funcionou e **não há outro código suspeito**.
* **Por que não classificar como "não baixo peso":** seria tratar "não sei" como "normal". O tema pede
  excluir do denominador.
* **Risco:** viés de seleção por peso ignorado é desprezível com 0,005%.

### D6 — Município ignorado

* **Decisão:** `codmunres == "420000"` seria separado e contado. **Resultado: 0 registros.** Nenhum código
  dos dados ficou fora da lista oficial (`codigos_fora_da_lista = character(0)`).

### D7 — Lista oficial de 295 municípios e tratamento dos zeros

* **Decisão:** partir da lista oficial de SC (`geobr`, IBGE; **295**, como esperado) e fazer `left_join`
  com os agregados; zero real quando não há nascimento; denominador 0 → fora do ajuste.
* **Resultado:** **todos os 295 municípios têm nascimentos** (mínimo = 8), então **nenhum** sai por
  denominador zero. *(Na versão anterior deste documento eu havia dito que provavelmente haveria alguns
  municípios sem nascimento; isso não se confirmou. A lógica de segurança foi mantida porque ela é parte
  da garantia de integridade.)*
* **Por que conferir contra lista externa:** com microdados, município sem nascimento simplesmente não
  aparece; é o equivalente ao "Exibir linhas zeradas" do TABNET, e a orientação alerta que a opção sozinha
  não garante a lista completa.
* **Em uma frase:** *"Zero é diferente de ausente; conferi os 295 municípios contra a lista do IBGE e todos
  têm denominador positivo."*

### D8 — Preditores candidatos (e o que ficou de fora de propósito)

Todos são **proporções municipais** calculadas sobre a base de análise:

| Variável | Definição | Por que é candidata |
|---|---|---|
| `prop_adolescente` | % de mães de 10 a 19 anos | Gravidez na adolescência associada a prematuridade e baixo peso |
| `prop_esc_baixa` | % de mães com < 8 anos de estudo (`escmae` 1–3) | Proxy socioeconômica e de acesso a cuidado |
| `prop_prenatal_insuf` | % de mães com < 6 consultas (`consprenat`) | Pré-natal inadequado associado a piores desfechos perinatais |
| `prop_gestacao_mult` | % de nascidos de gravidez dupla/tripla+ | Gestações múltiplas têm peso menor por natureza |
| `prop_mae_35mais` *(extra)* | % de mães ≥ 35 anos | Idade materna avançada é fator de risco clássico |

* O enunciado lista os 4 primeiros; as orientações pedem 4–8 e dizem que nem todos precisam entrar no
  modelo final. O 5º é uma sugestão minha; **você pode descartá-lo**.
* **Deixados de fora de propósito:**
  * **`gestacao` / semanas de gestação:** principal determinante do peso; é *mediador* (parte do caminho
    até o baixo peso) e esconderia os demais efeitos; viola o espírito de "evitar preditores que revelem
    diretamente a resposta".
  * **Apgar, sexo do bebê, malformação, tipo de parto:** características do recém-nascido/parto, não do
    contexto materno municipal.
  * **Qualquer indicador calculado a partir do peso.** Nenhum preditor usa `peso`; todos vêm de variáveis
    da mãe/gestação, por isso **não são "componentes da resposta"**.
* **Interpretação:** associações **entre municípios**, não sobre a mãe individual (falácia ecológica).

### D9 — Informação ignorada nos preditores: sai do cálculo, não vira zero

* **Decisão:** códigos "ignorado" ou fora do domínio válido viram `NA`; a proporção municipal usa só os
  registros com informação válida. Domínios: idade 10–59; `escmae` 1–5; `gravidez` 1–3; `consprenat` 0–98.
* **Resultado (base de análise, n = 64.469):** idade **0%** ignorada; escolaridade **0,166%** (107);
  pré-natal **0,271%** (175); tipo de gravidez **0,039%** (25). **Nenhum município ficou com preditor NA.**
* **Conclusão:** a perda por ignorados é desprezível; o `glm` usará os 295 municípios completos.
* **Nota:** idade variou de 12 a 55 anos, faixa plausível; nada foi invalidado.

### D10 — Definição de "pré-natal insuficiente" (confirmada)

* **Decisão:** `consprenat < 6`.
* **Por quê:** o Ministério da Saúde recomenda no mínimo 6 consultas; é o limiar usual.
* **Por que `consprenat` e não `consultas`:** `consultas` vem em faixas (1 nenhuma, 2 de 1–3, 3 de 4–6, 4
  de 7+) e **não separa 6 de 4–5**; `consprenat` traz o número exato.
* **Evidência de que `consprenat` é o número de consultas:**
  1. No `NASCIDO.def` (arquivos auxiliares do TABNET) ela aparece como **"Consultas Detalh"**, ou seja, a
     versão *detalhada* de `CONSULTAS` (mesmo padrão de `SEMAGESTAC` = "Semanas Gest Detalh").
  2. **Tabela cruzada na base inteira:** `consultas` × faixa de `consprenat` tem concordância **perfeita**
     (320 · 1.680 · 7.901 · 54.396 na diagonal, zero fora dela). Isso valida a interpretação.
* **Pendência resolvida (`SEMADUM.CNV`):** o arquivo de conversão tem 44 categorias: `N Inf`, depois as consultas
  **01 a 42** (uma categoria para cada) e **"43 e+" = 43 a 50**. Conclusões:
  1. `consprenat` é de fato o **número de consultas** (categorias numéricas).
  2. Tudo o que está fora de 01–50 cai em **"N Inf"** (não informado), incluindo `99`. Isso é coerente com tratar
     `99` como ignorado (62 registros na base de análise; + 113 vazios = 175 ignorados, igual ao que o script contou).
  3. **Cuidado:** o código `00` **não aparece** em nenhuma categoria numerada; no TABNET ele provavelmente cai em
     "N Inf", misturado com os ignorados. **No nosso tratamento, `00` é um valor VÁLIDO ("nenhuma consulta")**: a
     tabela cruzada mostrou que `consprenat = 0` corresponde exatamente a `consultas = 1` ("nenhuma"; 320 casos),
     que **conta como pré-natal insuficiente**. É uma diferença entre o nosso tratamento e a conversão do TABNET;
     por isso **não** use `consprenat` para validar contra o TABNET (use as outras variáveis, ver Seção 9).
* **Cauda de `consprenat`:** valores entre 32 e 41 (31 registros) e `99` (62). Nenhum código absurdo além do `99`.
  O máximo plausível (41) está dentro das categorias do CNV. Nada a ajustar.
* **Sensibilidade (Etapa C, opcional):** refazer com `< 7` ou com `consultas ≤ 2`.

### D11 — Preditores contínuos, sem categorizar

* **Decisão:** manter as proporções em escala contínua (0 a 1).
* **Por que:** as orientações preferem quantitativos contínuos e pedem justificar categorizações; o tema
  proíbe transformar o percentual em alto/baixo por quartis.
* **Detalhe para a Etapa C:** na escala 0–1 o coeficiente refere-se à mudança de "100 pontos percentuais";
  na interpretação reescalamos (ex.: por 10 p.p.) sem alterar a variável.

### D12 — Municípios pequenos não são excluídos

* **Decisão:** manter todo município com `n_nascidos > 0`.
* **Por que:** a binomial já pondera por `n_i`; excluir seria arbitrário.
* **Resultado:** mínimo 8 nascimentos; **80 municípios (27%) com < 30**; **24 com zero casos** de baixo peso.
* **Riscos (ver Seção 6):** instabilidade das proporções, superdispersão, influência e a limitação do teste
  de qualidade de ajuste pela deviance.

### D13 — Unicidade e duplicidades

* **Resultado:** linhas 100% idênticas = **0**; `contador` repetido = **0**. Nada foi removido.
* O identificador disponível é `contador` (não há `numerodn` nas colunas). Gêmeos são linhas distintas
  (D4), o que é correto.

### D14 — Reprodutibilidade

* Dado bruto em `data/raw/` **fora do Git** (público e grande); o repositório guarda script e data de
  extração. Scripts numerados; parâmetros no topo; `stopifnot()` para integridade; `sessionInfo()` salvo.

---

## 3. Estrutura sugerida do repositório

```
.
├── README.md
├── .gitignore                  # data/raw/  e  *.Rhistory
├── data/
│   ├── raw/                    # DNSC2026.dbc  (NÃO versionar)
│   └── processed/              # base_municipal_sc2026.rds / .csv
├── scripts/
│   └── 01_preparacao_base.R    # (próximos: 02_exploratoria.R, 03_modelagem.R, 04_diagnostico.R)
├── docs/
│   └── etapa_A_preparacao_dados.md
└── output/
    └── tabelas/
```

---

## 4. Dicionário da base final (`base_municipal_sc2026.rds`)

| Coluna | Tipo | Descrição | Origem (campo SINASC) | Ano |
|---|---|---|---|---|
| `cod6` | texto | Código IBGE do município (6 dígitos) | `codmunres` | — |
| `nome` | texto | Nome do município | lista IBGE (`geobr`) | 2020 (malha) |
| `n_nascidos` | inteiro | Nascidos vivos com peso conhecido (denominador) | contagem | 2026 |
| `baixo_peso` | inteiro | Peso < 2.500 g (sucessos) | `peso` | 2026 |
| `demais` | inteiro | Peso ≥ 2.500 g (insucessos) | `peso` | 2026 |
| `n_peso_ignorado` | inteiro | Peso ignorado (fora do denominador) | `peso` | 2026 |
| `prop_adolescente` | 0–1 | Mães de 10–19 anos | `idademae` | 2026 |
| `prop_esc_baixa` | 0–1 | Mães com < 8 anos de estudo | `escmae` | 2026 |
| `prop_prenatal_insuf` | 0–1 | Mães com < 6 consultas | `consprenat` | 2026 |
| `prop_gestacao_mult` | 0–1 | Gravidez dupla ou mais | `gravidez` | 2026 |
| `prop_mae_35mais` | 0–1 | Mães com ≥ 35 anos (extra) | `idademae` | 2026 |
| `taxa_baixo_peso` | 0–1 | `baixo_peso / n_nascidos` (**só descrição/gráficos; NÃO é a resposta**) | derivada | 2026 |
| `entra_no_ajuste` | lógico | `n_nascidos > 0` | derivada | — |

> **Regra de ouro:** a resposta do modelo é `cbind(baixo_peso, demais)`, não a taxa.

---

## 5. Resultados reais da Etapa A

| Item | Valor |
|---|---|
| Arquivo / versão | `DNSC2026.dbc` — SINASC 2026, **2ª prévia** (64.472 linhas × 61 colunas) |
| Data de extração (DATASUS) / data de download | **01/09/2026** / 31/10/2026 |
| Período efetivo | **01/01/2026 a 31/08/2026** |
| Mães residentes fora de SC (excluídas) | 0 |
| Nascimentos fora de 2026 (excluídos) | 0 |
| Município ignorado (420000) | 0 |
| Peso ignorado | **3** (0,005%) — todos vazios |
| **Nascidos vivos na base de análise** | **64.469** |
| Baixo peso (total) e taxa global | **5.302** · **8,22%** |
| Municípios (oficiais / no ajuste / sem nascimento) | **295 / 295 / 0** |
| Nascidos por município (min · Q1 · mediana · média · Q3 · máx) | 8 · 28 · 67 · 218,5 · 169 · 4.978 |
| Municípios com < 30 nascimentos / com 0 caso de baixo peso | **80 / 24** |
| % ignorado: idade · escolaridade · pré-natal · gravidez | 0 · 0,166 · 0,271 · 0,039 |
| Linhas duplicadas / `contador` repetido | 0 / 0 |
| Nascimentos por mês (jan→ago) | 8.543 · 7.517 · 8.837 · 8.751 · 8.788 · 8.372 · 8.578 · **5.086** |

**Funil de perdas:** 64.472 → 64.472 → 64.472 → 64.472 → **64.469** (única perda: peso ignorado, 3).

**Preditores municipais (média ponderada igual por município):**

| Variável | Mín | Q1 | Mediana | Média | Q3 | Máx |
|---|---|---|---|---|---|---|
| `prop_adolescente` | 0,000 | 0,052 | 0,077 | 0,081 | 0,108 | 0,333 |
| `prop_esc_baixa` | 0,000 | 0,028 | 0,055 | 0,060 | 0,080 | 0,308 |
| `prop_prenatal_insuf` | 0,000 | 0,043 | 0,076 | 0,078 | 0,107 | 0,267 |
| `prop_gestacao_mult` | 0,000 | 0,000 | 0,016 | 0,024 | 0,033 | 0,174 |
| `prop_mae_35mais` | 0,000 | 0,143 | 0,182 | 0,185 | 0,225 | 0,471 |

**Correlações entre preditores:** todas fracas (máximo em módulo = 0,19, entre `prop_adolescente` e
`prop_mae_35mais`). **Não há indício de multicolinearidade.**

---

## 6. Alertas e pontos de atenção encontrados na execução

**Nenhum problema impede de avançar. A1 e A6 foram resolvidos; A2–A5 são pontos que você deve saber explicar.**

1. **A1 — Agosto incompleto (RESOLVIDO).** 5.086 nascimentos contra ~8.500 nos demais meses; incompleto sobretudo na
   2ª quinzena. As checagens não mostraram diferença na taxa nem no perfil; decisão: manter jan–ago e fazer
   sensibilidade jan–jul (D3b).
2. **A2 — "Prévia".** Dados preliminares; os números podem mudar nas versões seguintes. Limitação a citar.
3. **A3 — Municípios pequenos e instabilidade.** 27% dos municípios têm < 30 nascimentos e 24 têm zero
   caso. Consequências: (a) a taxa observada desses municípios é muito ruidosa; (b) os **preditores** dos
   municípios pequenos também são ruidosos (proporção calculada com poucos nascimentos), o que pode
   atenuar associações (erro de medida na covariável); (c) **`prop_gestacao_mult` tem 1º quartil = 0**
   (muitos municípios sem nenhuma gestação múltipla), logo é assimétrica e sustentada por poucos
   municípios; observe isso na exploratória.
4. **A4 — Teste de qualidade de ajuste pela deviance (Etapas C/D).** Os slides da disciplina dizem que o
   teste assintótico pela deviance exige, na binomial, `m·π ≥ 3` e `m·(1−π) ≥ 3`. Com `n_i` = 8 e π ≈ 0,08,
   `m·π ≈ 0,6 < 3`. Para muitos municípios a regra **não é satisfeita**, então o p-valor χ² da deviance
   não é confiável. Use a **estimativa de dispersão por Pearson**, resíduos quantílicos/envelope
   simulado e, se quiser, p-valor por simulação (como no script de deviance da disciplina).
5. **A5 — Peso mínimo de 122 g.** Provável erro de digitação, mas inócuo para a classificação (D4).
6. **A6 — Pendências (RESOLVIDAS).** `SEMADUM.CNV` confirmou que `consprenat` é número de consultas e que `99` é
   "não informado"; 653 nascimentos (1,01%) de mães de SC ocorreram fora de SC, confirmando o arquivo por residência.
   Ressalva nova: o TABNET trata `00` provavelmente como "N Inf" (D10).

**O que está bem:** nenhuma duplicata; nenhum registro perdido além de 3 pesos vazios; os 295 municípios
conferem com o IBGE; ignorados < 0,3% em todos os preditores; taxa global de 8,22% é compatível com o
esperado para o Brasil (8–9%); `consprenat` validada contra `consultas`; preditores pouco correlacionados;
volume de eventos (5.302) muito alto em relação ao nº de parâmetros, então não há problema de "poucos
eventos" no ajuste municipal.

---

## 7. Perguntas prováveis da banca (e respostas curtas)

1. **Por que microdados e não TABNET?** Os preditores municipais saem dos mesmos nascimentos; mesma fonte e
   mesmo ano. Equivale à tabulação. (D1)
2. **Por que residência da mãe?** O tema compara municípios de residência; as características são da mãe
   residente; ocorrência concentraria nos polos. O arquivo já é por residência. (D2)
3. **2026 está completo?** Não. Cobre 01/01 a 31/08, é a 2ª prévia e agosto está incompleto; avaliei se agosto
   difere dos demais meses e fiz sensibilidade sem ele. (D3, D3b)
4. **O que fez com peso ignorado?** Saiu do denominador; foram 3 registros (0,005%). (D5)
5. **Por que não usar a taxa como resposta?** A taxa ignora o tamanho `n_i`; a binomial usa
   `cbind(sucessos, insucessos)` e pondera: 1 caso em 3 nascimentos não vale como 1.000 em 3.000. (Seção 1)
6. **Por que não incluir semanas de gestação?** É mediadora/quase a própria resposta. (D8)
7. **Município sem nascimento?** Verifiquei os 295 contra o IBGE; nenhum tem denominador zero. (D7)
8. **Por que o limiar de 6 consultas?** Mínimo recomendado pelo Ministério; `consprenat` permite, `consultas`
   (faixas) não; e validei `consprenat` contra `consultas`. (D10)
9. **Os coeficientes valem para a mãe individual?** Não; são associações entre municípios. (D8)
10. **E municípios minúsculos?** Mantidos; a binomial pondera por `n_i`; avaliamos superdispersão e
    influência. (D12, A3)
11. **Por que proporções contínuas?** Evita perda de informação e cortes arbitrários. (D11)
12. **Por que não excluiu o peso de 122 g?** Qualquer valor < 2.500 g já é baixo peso; excluir seria sem
    justificativa. (D4)
13. **Preditores e resposta vêm das mesmas DNs; isso não é circular?** Não: nenhum preditor usa `peso`;
    vêm de características da mãe/gestação. É o desenho ecológico usual. (D8)

---

## 8. Checklist antes da Etapa B

- [x] Script rodou do início ao fim; `stopifnot` passou.
- [x] Funil de perdas, qualidade e estatísticas descritivas obtidos (Seção 5).
- [x] `consprenat` validada contra `consultas` e identificada no `.def`.
- [x] Data de extração oficial registrada (01/09/2026).
- [x] Bloco de agosto rodado; decisão: manter jan–ago (D3b).
- [x] `SEMADUM.CNV` verificado (D10).
- [x] Nascimentos de mães de SC ocorridos fora de SC conferidos: 653 (D2); cauda de `consprenat` sem problemas.
- [x] Base conferida com o TABNET: 0 diferenças em 295 municípios (Seção 9, `02_conferencia_tabnet.R`).
- [ ] `commit` com script, este documento, `output/tabelas/` e `.gitignore` (sem `data/raw`).

**Próxima etapa (B):** análise exploratória (distribuição de `taxa_baixo_peso`, relação com cada preditor
considerando o tamanho do município, assimetria de `prop_gestacao_mult`, mapa/gráficos), ainda sem ajustar o modelo.


---

## 9. Conferência da base com o TABNET (validação externa)

**Objetivo:** mostrar que o que o script produziu a partir dos microdados é idêntico ao que o sistema oficial
tabula. É a melhor resposta à pergunta "como você sabe que sua base está certa?".

**O que comparar (por município):** total de nascidos vivos, nascidos com baixo peso, nascidos com peso ≥ 2.500 g e
peso ignorado. **Não** compare `consprenat` (D10).

**Passo a passo no TABNET** (os nomes dos menus podem variar um pouco):
1. `datasus.saude.gov.br` → *Informações de Saúde (TABNET)* → *Estatísticas Vitais* → *Nascidos vivos*.
2. Escolha a abrangência **Santa Catarina** (com município) e o ano **2026**.
3. **Linha:** *Município* (residência da mãe, conforme as orientações). **Coluna:** *Peso ao nascer* (faixas).
   **Conteúdo:** *Nascim p/resid.mãe* (nascimentos por residência da mãe).
4. Marque **"Exibir linhas zeradas"**.
5. Clique em *Mostra* e use **"Copia como .CSV"** (ou botão equivalente). Salve em
   `data/raw/tabnet_nv_sc2026_peso.csv`.
6. Anote a **data/versão** que o TABNET exibe para 2026 e rode `scripts/02_conferencia_tabnet.R`.

**Ressalva importante (a mais provável causa de diferenças):** o TABNET pode estar em uma prévia **mais nova**
que a sua (extração de 01/09/2026). Se for o caso, o TABNET terá **mais nascimentos**, concentrados em agosto
(a fase incompleta). Se aparecerem diferenças, elas devem ser **todas ≥ 0 a favor do TABNET**; se houver
diferenças em ambos os sentidos, ou em municípios com poucos nascimentos sem relação com agosto, investigue.
Se o TABNET permitir restringir por mês, compare jan–jul, que já estava completo na sua extração.

**O que é "traço" no TABNET:** o CSV pode usar `-` para célula zero. O CSV desta extração **não trouxe notas de
rodapé** (o script de leitura não encontrou nenhuma), então a legenda do traço fica apenas na tela do TABNET.
Como as orientações pedem não converter traço em zero sem consultar a documentação, a justificativa aqui é dupla:
(1) a legenda do TABNET na página e (2) **a validação empírica**: como os totais por município e por faixa de
peso batem *exatamente* com os microdados (abaixo), a conversão de `-` e células vazias em zero está comprovada.

**Critério de aceitação:** diferença zero em todos os municípios (mesma prévia) ou diferenças explicáveis pela
prévia (TABNET ≥ base).

### Resultado da conferência (executada)

| Item | Base (microdados) | TABNET |
|---|---|---|
| Municípios | 295 | 295 (todos casaram; nenhum código fora da base) |
| Total de nascidos vivos | 64.472 | 64.472 |
| Baixo peso (< 2.500 g) | 5.302 | 5.302 |
| Peso ≥ 2.500 g | 59.167 | 59.167 |
| Peso ignorado | 3 | 3 |
| Taxa de baixo peso (sobre peso conhecido) | 8,2241% | 8,2241% |
| **Municípios com qualquer diferença** | — | **0** |

* Faixas do TABNET classificadas: baixo peso = *Menos de 500 g*, *500–999 g*, *1000–1499 g*, *1500–2499 g*;
  demais = *2500–2999 g*, *3000–3999 g*, *4000 g e mais*; *Ignorado* separado.
* O TABNET estava **na mesma prévia** (2ª prévia, extração 01/09/2026) que o arquivo baixado: não houve nenhuma
  diferença nem a favor do TABNET.
* **Conclusão:** a base municipal construída a partir dos microdados **reproduz exatamente** a tabulação oficial
  (resposta, denominador e peso ignorado). A validação cobre a **resposta e o denominador**; os preditores
  (proporções de adolescentes etc.) não estão nessa tabulação e foram verificados por consistência interna
  (domínios válidos, ignorados < 0,3%, nenhuma proporção fora de [0,1]).
* **Resposta para a banca:** *"Conferi os 295 municípios contra a tabulação oficial do TABNET na mesma prévia: totais,
  baixo peso, demais e ignorados coincidem exatamente."*
