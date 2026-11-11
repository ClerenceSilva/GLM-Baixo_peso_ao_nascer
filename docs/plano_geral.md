# Plano geral do trabalho — CE314 (MLG), Tema 8

**Baixo peso ao nascer: probabilidade de baixo peso entre municípios de Santa Catarina (SINASC, 2026)**
Última atualização: 10/11/2026 · Status: **Etapas A, B e C concluídas; próxima: Etapa D (diagnóstico)**

> **Este arquivo é o contexto-mestre do projeto.** Se estiver começando um novo chat, leia primeiro as Seções 1, 2 e 7.
> Detalhes e justificativas: `docs/etapa_A_preparacao_dados.md`, `docs/etapa_B_exploratoria.md` e `docs/etapa_C_modelagem.md`.

---

## 1. Contexto

* **Disciplina:** CE314 — Modelos Lineares Generalizados (UFPR, Prof. Cesar Augusto Taconeli).
* **Autor:** Clerence, **trabalhando sozinho** (a dupla não está mais participando).
* **Tema 8:** investigar diferenças na **probabilidade de baixo peso ao nascer** entre municípios de residência das
  mães em SC, com **regressão binomial agrupada**:
  `glm(cbind(baixo_peso, demais) ~ x1 + x2 + ..., family = binomial, data = dados)`.
* **Datas:** slides em PDF (resposta binária) até **20/11/2026**, por e-mail para o professor; seminários em
  **30/11 e 01/12/2026**; apresentação de 10–15 min (descontam nota se fugir do intervalo) + 5 min de debate;
  10–20 slides principais, resto em apêndice.
* **Avaliação:** clareza do problema; preparação dos dados; coerência/justificativa da modelagem; diagnóstico;
  interpretação e limitações; reprodutibilidade; qualidade da apresentação; tempo; participação no debate.
* **Exigência de entendimento:** o autor precisa conseguir **explicar cada decisão** na defesa. Por isso toda etapa
  produz um `.md` com decisões, alternativas, justificativa, risco e uma frase para a banca.

### Regras do enunciado que valem para todo o trabalho
* Resposta = `cbind(sucessos, insucessos)`; **não** transformar % em "alto/baixo" por quartis.
* Excluir peso ignorado do denominador e informar sua frequência; avaliar **dispersão extra-binomial**.
* Município com denominador zero não entra no ajuste.
* 4 a 8 preditores candidatos; nem todos precisam estar no modelo final.
* **Não** usar preditores que sejam componentes da resposta ou revelem seu valor.
* Preditores quantitativos contínuos; justificar categorizações/transformações.
* Diagnóstico: resíduos, atípicas/influentes, multicolinearidade, relação funcional; **não excluir observação só por ser
  influente**.
* Resultados: estimativas, ICs, testes, interpretação na escala adequada e **pelo menos um gráfico de probabilidades
  com IC**.
* Interpretar como **associações municipais**; sem causalidade e sem extrapolar para indivíduos.

---

## 2. Estado atual (resumo da Etapa A, concluída e validada)

**Fonte:** microdados SINASC `DNSC2026.dbc` (SC), **2ª prévia, extração 01/09/2026** (download 31/10/2026).
**Período efetivo:** 01/01 a 31/08/2026; agosto incompleto na 2ª quinzena (decisão: **manter jan–ago**, sensibilidade
jan–jul na Etapa C, pois a taxa de agosto = jan–jul = 8,22%).

| Item | Valor |
|---|---|
| Registros / mães residentes em SC / nascidos em 2026 | 64.472 / 64.472 / 64.472 |
| Peso ignorado (excluído do denominador) | 3 (0,005%) |
| **Base de análise** | **64.469 nascidos vivos** |
| Baixo peso (sucessos) · taxa global | 5.302 · 8,22% |
| Municípios | 295 (todos com nascimentos; mínimo 8) |
| Nascimentos por município (Q1 · mediana · média · Q3 · máx) | 28 · 67 · 218,5 · 169 · 4.978 |
| Municípios com < 30 nascimentos / com 0 caso de baixo peso | 80 / 24 |
| Duplicatas | 0 |
| **Validação externa (TABNET, mesma prévia)** | **0 diferenças em 295 municípios** |

**Base final:** `data/processed/base_municipal_sc2026.rds` (e `_completa.rds`, `.csv`). Colunas:
`cod6, nome, n_nascidos, baixo_peso, demais, n_peso_ignorado, prop_adolescente, prop_esc_baixa,
prop_prenatal_insuf, prop_gestacao_mult, prop_mae_35mais, taxa_baixo_peso (só descrição), entra_no_ajuste`.

**Preditores candidatos (proporções municipais, escala 0–1, calculadas nos nascidos com peso conhecido):**

| Variável | Definição |
|---|---|
| `prop_adolescente` | mães de 10–19 anos |
| `prop_esc_baixa` | mães com < 8 anos de estudo (`escmae` 1–3) |
| `prop_prenatal_insuf` | mães com < 6 consultas (`consprenat`; `00` = nenhuma consulta, válido; `99` = ignorado) |
| `prop_gestacao_mult` | gravidez dupla ou mais |
| `prop_mae_35mais` | mães ≥ 35 anos (**extra, mantido por decisão do autor**) |

**Deixados de fora de propósito:** semanas de gestação/prematuridade (mediador, quase a resposta), Apgar, sexo do bebê,
malformação, tipo de parto, qualquer indicador derivado do peso.

**Estatísticas descritivas (média entre municípios):** adolescentes 8,1%; esc. baixa 6,0%; pré-natal insuficiente
7,8%; gestação múltipla 2,4% (1º quartil = 0, assimétrica); mães ≥ 35 anos 18,5%. **Correlações entre preditores
fracas** (máx. |0,19|), logo multicolinearidade não deve ser problema.

### Alertas conhecidos (A2–A5)
* **A2 Prévia:** dados preliminares, sujeitos a revisão (limitação).
* **A3 Municípios pequenos:** taxas e preditores ruidosos; possível atenuação (erro de medida); `prop_gestacao_mult`
  sustentada por poucos municípios.
* **A4 Teste χ² da deviance NÃO confiável:** com `n_i` pequeno e π ≈ 0,08, `n_i·π_i < 3` em muitos municípios (regra dos
  slides: `mπ ≥ 3` e `m(1−π) ≥ 3`). Usar dispersão por Pearson, resíduos quantílicos/envelope simulado e/ou p-valor por simulação.
* **A5 Peso mínimo 122 g:** provável erro de digitação, inócuo (qualquer valor < 2.500 g é baixo peso); não excluído.

### Resumo da Etapa B (concluída em 02/11/2026; detalhes em `docs/etapa_B_exploratoria.md`)
* **Ruído por tamanho:** DP da taxa municipal cai de 8,36 p.p. (`< 30`) para 1,44 p.p. (`>= 500`); a taxa agregada fica estável (7,9–8,6%). 28 municípios concentram 60,6% dos nascimentos.
* **Heterogeneidade real:** funil com 24 municípios fora de 95% (esperado ≤ 14,8) e 2 fora de 99,8% (esperado 0,6); **7 dos 28 maiores** fora. 18 acima × 6 abaixo da taxa global. φ do modelo nulo = **1,55**.
* **Contagens esperadas:** `n_i·p0 < 3` em 94 municípios (31,9%); `< 5` em 138 (46,8%) → χ² da deviance inválido (A4 confirmado).
* **Preditores:** `prop_gestacao_mult` tem 42% de zeros e assimetria 2,0; correlação com a resposta ≈ 0,4 em todas as versões (robusta). `prop_esc_baixa` e `prop_adolescente` **sensíveis** aos municípios pequenos (correlações ponderadas mudam com `n ≥ 30`); `prop_prenatal_insuf` e `prop_mae_35mais` fracas. Correlação máxima entre preditores = 0,19.
* **Forma funcional:** curvaturas aparentes eram dos municípios pequenos; com `n ≥ 30`, reta e loess praticamente coincidem → preditores **lineares no logito**.
* **Hipótese a verificar (D):** vários municípios com risco alto ficam no Meio-Oeste/Planalto → possível agrupamento espacial (Moran).

### Resumo da Etapa C (concluída; detalhes em `docs/etapa_C_modelagem.md`)
* **Modelo final:** `Y_i ~ BetaBinomial(n_i, π_i, ρ)`, `logit(π_i) = β0 + β1·pre10 + β2·mult10`, com preditores em **unidades de 10 p.p.** (`pre10 = prop_prenatal_insuf × 10`; `mult10 = prop_gestacao_mult × 10`).

| Termo | β (EP) | OR por +10 p.p. | OR por +1 DP | p (TRV) |
|---|---|---|---|---|
| `mult10` | 0,805 (0,091) | **2,24** | ≈ 1,30 | 1,3×10⁻¹⁶ |
| `pre10` | 0,151 (0,053) | **1,16** | ≈ 1,08 | 0,0038 |

* **Convergência:** sem separação (ajustados entre 0,056 e 0,258; maior EP 0,107). φ Pearson: nulo 1,551 · completo 1,229 · final (binomial) 1,284. Preditores explicam 20,4% da deviance (completo, binomial).
* **Ligação:** logito (probito melhor por apenas 1,07 de AIC; cloglog 1,63; cauchit +15,0).
* **Família:** **beta-binomial.** TRV vs binomial χ² = 19,55 (p ≈ 5×10⁻⁶); AIC 1404,99 → 1387,44 (Δ = 17,5); ρ = 0,00103. A superdispersão **cresce com `n`**: φ observado 1,07 · 1,13 · 1,23 · **2,51** (classes `< 30` · 30–99 · 100–499 · `>= 500`) vs fator previsto `1+(n−1)ρ` 1,02 · 1,06 · 1,22 · **2,44**. O quasi-binomial (φ constante = 1,28) não reproduz isso e fica como **robustez**.
* **Seleção:** 32 modelos no binomial (QAIC) e no beta-binomial. No beta-binomial, 8 modelos ficam a menos de 2 de AIC do melhor; só `pre10` e `mult10` estão em 100% deles (`adol10`, `esc10` e `m35_10` em 50%, intercambiáveis). `pre10 + mult10`: ΔAIC = 1,45 e **melhor BIC**. **Procedimento corrigido:** escolher a família **antes** de selecionar (o QAIC do binomial indicava 4 variáveis, abandonado).
* **Descartadas:** `esc10` (p > 0,6 com `n ≥ 30`, sinal negativo), `m35_10` (p = 0,29), `adol10` (limítrofe: p = 0,058 no beta-binomial ao acrescentá-la; fica como robustez).
* **Forma funcional:** sem curvatura (quadráticos p = 0,68 e 0,19; teste de η̂² p = 0,21) → **sem termos quadráticos**.
* **Robustez:** `mult10` estável (OR 2,19–2,35 em todos os cenários e famílias). `pre10` **frágil**: beta-binomial 1,16 (p = 0,004) vs quasi 1,09 (p = 0,067); com pré-natal < 7 consultas cai a 1,07 (bb, p = 0,050) e 1,04 (quasi, p = 0,24). Deve ser reportada como **associação moderada e sensível à família e à definição**.
* **Atenção ao DHARMa:** `testDispersion` deu 0,912 (p = 0,026) no binomial e 0,857 (p = 0,104) no beta-binomial, **na contramão** do φ de Pearson; tratado como pouco informativo (dominado pelos municípios pequenos). Examinar os resíduos quantílicos na Etapa D.

---

## 3. Plano das próximas etapas

Numeração dos scripts: `01_preparacao_base.R` e `02_conferencia_tabnet.R` já existem.

### Etapa B — Exploratória (`03_exploratoria.R` + `docs/etapa_B_exploratoria.md`) — **concluída em 02/11**
* Distribuição da taxa de baixo peso e de `n_i`.
* **Gráfico de funil:** taxa × `n_i`, com limites binomiais em torno de 8,22% (mostra o ruído por tamanho de município
  e justifica a binomial em vez de trabalhar com taxas).
* Cada preditor × taxa (pontos com tamanho ∝ `n_i`, suavização ponderada).
* Assimetria de `prop_gestacao_mult`; correlações entre preditores.
* Objetivo: avaliar se as relações parecem lineares na escala logito (sem ajustar modelo ainda).

### Etapa C — Modelagem (`04_modelagem.R` + `docs/etapa_C_modelagem.md`) — **concluída**
* Binomial-logito completo (5 preditores): convergência, separação, dispersão (Pearson, sem χ² da deviance).
* Ligações (logito, probito, cloglog, cauchit) por AIC → logito.
* Testes por termo: TRV (φ = 1, só referência) e **teste F tipo II** (φ estimado); 32 modelos por AIC/BIC/QAIC; stepwise.
* Família de dispersão: binomial × quasi-binomial × **beta-binomial** (escolhida por TRV, ΔAIC e φ por classe de `n`); seleção refeita no beta-binomial.
* Forma funcional por teste formal; sensibilidades (a) jan–jul, (b) pré-natal < 7, (c) com `adol10`, (d) `n ≥ 30`.
* **Resultado:** ver Seção 2 (Resumo da Etapa C). Tudo em `output/tabelas/C_*.csv` e `data/processed/C_modelos.rds`.

### Etapa D — Diagnóstico (`05_diagnostico.R` + `docs/etapa_D_diagnostico.md`)
* Resíduos de deviance/Pearson e **quantílicos aleatorizados com envelope simulado** (`hnp`/`DHARMa`).
* Resíduos × ajustados e × cada preditor; resíduos parciais (linearidade).
* Alavancagem e distância de Cook; investigar, refazer sem as observações e **reportar** (não excluir por padrão).
* VIF (multicolinearidade); teste do η̂² para a ligação.
* **Modelo a diagnosticar:** beta-binomial `pre10 + mult10` (`C_modelos.rds`, objeto `bb_fin`); o binomial/quasi final (`m_bin_fin`, `m_q_fin`) entra só como comparação.
* **Pendências vindas da C:** (1) resíduos quantílicos + envelope simulado do modelo final (explicar o `testDispersion` < 1 do DHARMa); (2) resíduos parciais e resíduos × preditor para `mult10` (42% de zeros, cauda esparsa acima de 10 p.p.; quadrático teve p = 0,19); (3) Cook/alavancagem, atenção a Painel, Marema, Presidente Nereu, Braço do Trombudo e aos 28 municípios `>= 500`; (4) VIF (esperado ≈ 1); (5) checar que o beta-binomial não deixa padrão residual por tamanho `n`.
* **Opcional — autocorrelação espacial dos resíduos (Moran):** ver Seção 5; decidir nesta etapa conforme o tempo (a Etapa B sugere agrupamento regional entre os municípios fora do funil: prioridade média).

### Etapa E — Resultados (`06_resultados.R` + `docs/etapa_E_resultados.md`)
* Estimativas do modelo final (beta-binomial), com ICs (Wald e **perfil**), razões de chances **por +10 p.p. e por +1 DP**, TRV por termo; tabela lado a lado com binomial e quasi-binomial (robustez).
* **Gráfico exigido:** probabilidade predita de baixo peso × `mult10` e × `pre10`, com IC, mantendo o outro preditor na média. Atenção: restringir ao suporte observado (`prop_gestacao_mult` ≤ 17 p.p.).
* Medida de ajuste: redução de deviance vs nulo (binomial) e/ou diferença de log-verossimilhança no beta-binomial; ρ com IC.
* Slide de robustez com a tabela de sensibilidades (C10).
* Interpretação sempre como associação entre municípios; `pre10` apresentada como **moderada e sensível**.

### Etapa F — Fechamento
* Conclusão (objetivo, achados, limitações), slides (10–20 principais + apêndice), roteiro de fala (10–15 min), Q&A da banca.
* Limitações previstas: prévia, agosto parcial, municípios pequenos, desenho ecológico, ausência de covariáveis
  socioeconômicas de contexto.

---

## 4. Cronograma (hoje: 10/11/2026; entrega dos slides: **20/11**)

| Prazo | Entrega |
|---|---|
| até 04/11 | Etapa B (exploratória) — **feita em 02/11** |
| até 08/11 | Etapa C (modelagem e seleção) — **concluída (com ~2 dias de atraso)** |
| até 11/11 → **12/11** | Etapa D (diagnóstico) — prazo reajustado para absorver o atraso da C |
| até 14/11 | Etapa E (resultados e gráficos) |
| até 18/11 | Slides prontos e revisados (Etapa F) |
| **20/11** | **Envio do PDF dos slides** para cetaconeli@gmail.com |
| 21–29/11 | Ensaio da apresentação (cronometrar 10–15 min), Q&A |
| 30/11 e 01/12 | Seminários (ordem e grupos debatedores definidos em 27/10) |

Como o autor está sozinho, a margem de segurança é de 2 dias antes de 20/11 (a Etapa C consumiu 2 dias de folga; a E segue em 14/11); se uma etapa atrasar, cortar primeiro
os extras (Moran, sensibilidades secundárias), nunca o diagnóstico nem o gráfico de probabilidades.

---

## 5. Glossário rápido de termos que apareceram

* **Moran (I de Moran):** medida de **autocorrelação espacial**. Pergunta: "municípios vizinhos têm valores parecidos
  mais do que o acaso explicaria?". Varia aproximadamente de −1 a +1; perto de 0 = sem dependência espacial; positivo =
  vizinhos parecidos. Aplicado aos **resíduos** do modelo: se há dependência espacial, os municípios não são
  independentes (suposição do GLM) e os erros-padrão podem ficar **subestimados**. Precisa de uma definição de
  "vizinho" (municípios que compartilham fronteira, via malha do `geobr` + pacote `spdep`). **Status: opcional, decidir na
  Etapa D.** Se não for feito, entra como limitação.
* **Funil (funnel plot):** gráfico da taxa contra o tamanho `n_i` com bandas esperadas sob o acaso; taxas de municípios
  pequenos variam muito mais, por isso formam um "funil".
* **Superdispersão:** variância dos dados maior do que a binomial prevê (diferenças reais entre municípios não explicadas
  pelos preditores). Corrige-se com quasi-binomial ou beta-binomial.
* **Quasi-binomial:** mantém a média do modelo binomial, mas estima um parâmetro de dispersão φ e multiplica os erros-padrão.
* **Beta-binomial:** binomial em que π varia entre municípios segundo uma Beta; modelo probabilístico completo.
* **Razão de chances (OR):** `exp(β)`; quanto a chance de baixo peso fica multiplicada por unidade do preditor
  (aqui, por 10 p.p.).
* **TRV (teste da razão de verossimilhanças):** compara dois modelos encaixados pela diferença de `−2·log-verossimilhança`; para testar ρ = 0 (binomial × beta-binomial) a distribuição é uma mistura 50:50 de χ²₀ e χ²₁, logo o p-valor é a **metade** do p do χ²₁.
* **QAIC:** AIC corrigido para superdispersão (`−2ℓ/φ̂ + 2(p+1)`); vale para famílias do tipo binomial/quasi, **não** para o beta-binomial (que tem AIC próprio).
* **ρ (correlação intraclasse):** no beta-binomial, `Var = nπ(1−π)[1+(n−1)ρ]`; ρ pequeno (0,001) importa porque o fator cresce com `n`.
* **Teste F (análise de deviance):** versão do TRV quando φ é estimado: `F = [(D0−D1)/(p1−p0)] / φ̂`.
* **OR por +10 p.p. / por +1 DP:** razão de chances para uma variação de 10 pontos percentuais / de um desvio-padrão do preditor entre municípios.
* **Falácia ecológica:** conclusões sobre indivíduos a partir de dados agregados; proibida pelas orientações.

---

## 6. Estrutura do repositório

```
.
├── README.md
├── .gitignore                       # data/raw/  e  *.Rhistory
├── data/
│   ├── raw/                         # DNSC2026.dbc, tabnet_nv_sc2026_peso.csv  (NÃO versionar)
│   └── processed/                   # base_municipal_sc2026.rds / _completa.rds / .csv
├── scripts/
│   ├── 01_preparacao_base.R         # feito
│   ├── 02_conferencia_tabnet.R      # feito
│   ├── 03_exploratoria.R            # B (feito)
│   ├── 04_modelagem.R               # C (feito)
│   ├── 05_diagnostico.R             # D
│   └── 06_resultados.R              # E
├── docs/
│   ├── plano_geral.md               # este arquivo
│   ├── etapa_A_preparacao_dados.md  # feito
│   ├── etapa_B_exploratoria.md      # feito
│   ├── etapa_C_modelagem.md         # feito
│   └── etapa_D...F_*.md
├── output/
│   ├── tabelas/
│   └── figuras/
└── slides/
```

Pacotes já usados: `dplyr`, `tibble`, `datasusr`, `geobr`, `sf`, `car`, `glmmTMB` (beta-binomial), `DHARMa`, `ggplot2`. Previstos: `hnp`,
`statmod`, `performance`, `ggeffects`/`marginaleffects`, `spdep` (Moran, opcional). Se o `glmmTMB` falhar, alternativa: `VGAM::vglm(..., betabinomial)`.

---

## 7. Como trabalhamos (convenções para qualquer novo chat)

1. **Idioma:** português. O autor quer **entender tudo**: cada decisão deve vir com *o que, alternativas, por que, risco,
   frase para a banca*.
2. **Fluxo por etapa:** (i) o assistente entrega `scripts/0X_*.R` (não executado pelo assistente, que não roda R no
   ambiente) + `docs/etapa_X_*.md`; (ii) o autor roda no R e cola as **saídas**; (iii) o assistente confere números,
   aponta problemas e atualiza o `.md` com resultados reais; (iv) só então avança.
3. **Nunca inventar resultados:** números dos `.md` vêm das saídas reais; pendências ficam marcadas `[PREENCHER]`.
4. **Hipóteses não são resultados:** as expectativas (gestação múltipla, adolescentes e pré-natal insuficiente com efeito
   positivo) são só hipóteses; os dados decidem.
5. **Antes de cada etapa**, conferir o que as orientações exigem (Seção 1) e atualizar este plano se algo mudar.
6. **Arquivos úteis para anexar a um novo chat:** este arquivo, `docs/etapa_A_preparacao_dados.md`, `docs/etapa_B_exploratoria.md`, `docs/etapa_C_modelagem.md`, e, se for
   preciso rodar algo novo, as saídas do R (ou `output/tabelas/*.csv`).

### Prompt sugerido para iniciar um novo chat
> "Estou fazendo o trabalho final de CE314 (Tema 8, baixo peso ao nascer em SC, SINASC 2026). Leia `plano_geral.md` e
> `etapa_A_preparacao_dados.md`, `etapa_B_exploratoria.md` e `etapa_C_modelagem.md`. As Etapas A (validada contra o TABNET), B e C estão
> concluídas; o modelo final é beta-binomial com `pre10 + mult10`. Vamos começar a Etapa D (diagnóstico). Quero tudo bem documentado e
> explicado, como nas etapas anteriores."

---

## 8. Registro de decisões do plano (atualizar a cada mudança)

| Data | Decisão | Quem |
|---|---|---|
| 01/11/2026 | Manter agosto (jan–ago) como base principal; sensibilidade jan–jul | autor, após checagens |
| 01/11/2026 | Manter `prop_mae_35mais` como 5º preditor candidato | autor |
| 01/11/2026 | Data de entrega dos slides: 20/11 | autor |
| 01/11/2026 | Trabalho individual (dupla ausente) | autor |
| 01/11/2026 | Moran: opcional, decidir na Etapa D | a decidir |
| 01/11/2026 | Seguir plano B→F, ajustável conforme os resultados | autor |
| 02/11/2026 | Etapa B concluída; heterogeneidade real entre municípios (funil, φ nulo = 1,55) → considerar quasi-binomial/beta-binomial na C | autor |
| 02/11/2026 | Preditores contínuos e lineares no logito (curvaturas eram de municípios pequenos); quadrático só como checagem de robustez | autor |
| 02/11/2026 | Sensibilidade `n ≥ 30` passa a ser análise essencial | autor |
| 02/11/2026 | Moran: sugerido fazer na Etapa D (18/24 fora do funil acima; agrupamento regional aparente) | a decidir |
| 10/11/2026 | Preditores em unidades de 10 p.p. (OR por +10 p.p. e por +1 DP) | autor |
| 10/11/2026 | Ligação logito (ΔAIC < 2 vs probito/cloglog; cauchit rejeitado, +15) | autor |
| 10/11/2026 | Família principal: **beta-binomial** (TRV p ≈ 5×10⁻⁶; ΔAIC 17,5; φ cresce com `n`); quasi-binomial como robustez | autor |
| 10/11/2026 | Procedimento corrigido: escolher família **antes** de selecionar variáveis; seleção refeita no beta-binomial | autor |
| 10/11/2026 | **Modelo final: `prop_prenatal_insuf` + `prop_gestacao_mult`** (ΔAIC 1,45; melhor BIC; 100% dos modelos competitivos) | autor |
| 10/11/2026 | `esc10` descartada (p > 0,6 com `n ≥ 30`); `m35_10` e `adol10` fora (intercambiáveis); `adol10` fica como robustez | autor |
| 10/11/2026 | Sem termos quadráticos (p = 0,68; 0,19; η̂² p = 0,21) | autor |
| 10/11/2026 | `pre10` reportada como associação moderada e sensível (família e limiar de pré-natal) | autor |
| 10/11/2026 | Etapa C concluída; Etapa D com prazo reajustado para 12/11 | autor |
