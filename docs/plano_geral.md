# Plano geral do trabalho — CE314 (MLG), Tema 8

**Baixo peso ao nascer: probabilidade de baixo peso entre municípios de Santa Catarina (SINASC, 2026)**
Última atualização: 18/11/2026 · Status: **Etapas A a F concluídas; slides finais (v2, 26 páginas) renderizados e conferidos; faltam enviar o PDF (até 20/11) e ensaiar com os três integrantes**

---

## 0. Leia primeiro

### 0.1 O trabalho em cinco linhas

1. **Pergunta:** a probabilidade de um bebê nascer com menos de 2.500 g (baixo peso) é igual em todos os municípios de Santa Catarina? Que características dos municípios acompanham as diferenças?
2. **Dados:** todos os nascimentos de 2026 de mães residentes em SC (SINASC/DATASUS, janeiro a agosto, versão preliminar): 64.469 bebês em 295 municípios. Para cada município contamos quantos nasceram com baixo peso e quantos não.
3. **Método:** regressão **binomial agrupada**. Como os municípios variam mais do que o acaso explicaria, usamos a versão **beta-binomial**, que deixa o risco variar um pouco de município para município.
4. **Resultado principal:** onde há mais **gestações múltiplas** (gêmeos ou mais), a probabilidade de baixo peso é bem maior; onde há mais **pré-natal insuficiente** (menos de 6 consultas), é um pouco maior.
5. **Cuidado:** tudo isso são **associações entre municípios**. Não dizemos que algo "causa" baixo peso nem que vale para uma gestante individual.

### 0.2 Os números que todos precisam saber de cabeça

| O quê                                         | Valor                                                           |
| --------------------------------------------- | --------------------------------------------------------------- |
| Nascidos vivos analisados · municípios        | 64.469 · 295                                                    |
| Baixo peso (< 2.500 g): casos · taxa estadual | 5.302 · 8,22%                                                   |
| Peso ignorado (fora do denominador)           | 3 nascimentos (0,005%)                                          |
| Período e versão dos dados                    | jan–ago/2026, 2ª prévia, extração em 01/09/2026                 |
| Funil: municípios fora da faixa de 95%        | 24 (o acaso explicaria até ≈ 15); 7 dos 28 maiores              |
| Gestação múltipla (OR)                        | 2,24 por +10 p.p. (IC 1,87–2,68); **1,30 por +1 desvio-padrão** |
| Gestação múltipla em probabilidade            | **+2,2 p.p.** por +1 DP (de 8,2% para ≈ 10,4%)                  |
| Pré-natal insuficiente (OR)                   | 1,16 por +10 p.p. (IC 1,05–1,29); 1,08 por +1 DP                |
| Pré-natal em probabilidade                    | **+0,6 p.p.** por +1 DP                                         |
| Heterogeneidade extra (ρ)                     | 0,00191 sem preditores → 0,00103 com eles (cerca de metade)     |
| Superdispersão por tamanho (φ, binomial)      | 1,07 · 1,13 · 1,23 · **2,51** (municípios pequenos → grandes)   |
| Depois do beta-binomial (φ)                   | 1,06 · 1,05 · 0,96 · 1,15                                       |
| Dependência espacial (Moran)                  | 0,077 (fraca); some com controle de região ou superfície        |

*p.p. = pontos percentuais. 1 DP entre municípios ≈ 3,3 p.p. de gestação múltipla e 5,1 p.p. de pré-natal insuficiente.*

### 0.3 Frases de defesa (decore as cinco)

1. *"A resposta do modelo é o par de contagens (com e sem baixo peso) de cada município, porque o tamanho do município define a precisão da sua taxa."*
2. *"A variabilidade extra entre municípios cresce com o tamanho; por isso usamos o beta-binomial e não o quase-binomial."*
3. *"Gestação múltipla tem associação forte e estável em todos os cenários que testamos."*
4. *"Pré-natal insuficiente tem associação moderada: resiste a municípios influentes e à geografia, mas depende da família do modelo e da definição de insuficiente."*
5. *"São associações entre municípios, sem causalidade e sem extrapolar para indivíduos."*

### 0.4 O que **não** dizer

* "Causa", "efeito" ou "risco" sem a palavra **associação** e **entre municípios**.
* "Significativo" sem dizer em qual modelo (o pré-natal tem p = 0,004 no beta-binomial e 0,066 no quase-binomial).
* "OR = 2,24 significa 2,24 vezes mais probabilidade": OR é razão de **chances**; em probabilidade é cerca de 2,03 (e depende do ponto de partida).
* Que a faixa do gráfico mostra a variação dos municípios: é o **intervalo de confiança da probabilidade média**.
* Que o modelo "prevê" o baixo peso de um município: o objetivo é associação, não predição.

### 0.5 Como estudar (ordem sugerida, cerca de 2 a 3 horas)

1. Ler os **slides** (PDF) inteiros, uma vez, sem pausa (20 min).
2. Ler esta **Seção 0** e o **mini-glossário** (Seção 0.7) (20 min).
3. Ler `etapa_F_fechamento.md`: **Seção 2** (conclusão), **Seção 3** (roteiro) e **Seção 5** (perguntas da banca) (40 min).
4. Ler o **resumo executivo** de cada etapa, na ordem: `etapa_A` (dados), `etapa_B` (funil e exploratória), `etapa_C` (modelo), `etapa_D` (diagnóstico), `etapa_E` (resultados) (1 h).
5. Ensaiar em voz alta a sua parte, com cronômetro, e depois treinar perguntas entre os três.

### 0.6 Divisão da fala (sugestão, ajustar entre vocês)

| Bloco                                     | Slides                                                                                       | Tempo  | Responsável                                 |
| ----------------------------------------- | -------------------------------------------------------------------------------------------- | ------ | ------------------------------------------- |
| Abertura, dados e exploratória            | título, pergunta, dados, preditores, funil, linearidade                                      | ≈ 4:30 | `[PREENCHER]`                               |
| Modelo e diagnóstico (parte mais técnica) | modelo, por que beta-binomial, seleção, resíduos/envelope, influência e espaço               | ≈ 4:15 | Clerence (sugestão: foi quem fez a análise) |
| Resultados e conclusão                    | estimativas, probabilidades, pontos percentuais, robustez, limitações, conclusões, perguntas | ≈ 5:00 | `[PREENCHER]`                               |

* O roteiro minuto a minuto está em `etapa_F_fechamento.md`, Seção 3. Total: **13:45** (limite oficial: 10 a 15 min; fora disso desconta nota).
* **Debate (5 min):** qualquer um pode ser perguntado sobre qualquer parte. Perguntas simples (resposta nas Seções 0.2 a 0.4) podem ser respondidas por quem estiver mais perto; as técnicas (superdispersão, beta-binomial, envelope, Moran, TRV) ficam preferencialmente com Clerence, mas os outros dois devem saber a resposta curta.
* **Apêndice:** não se fala nele. Ele existe para ser aberto durante as perguntas (A3 robustez, A4 espaço, A7 superdispersão são os mais prováveis).
* **Combinar antes:** quem troca o slide, quem controla o tempo, quem abre o apêndice, e como passar a palavra ("agora o [nome] apresenta o modelo").

### 0.7 Mini-glossário em linguagem simples

* **Baixo peso:** bebê que nasce com menos de 2.500 g.
* **Binomial agrupada:** cada município tem `n` nascimentos, dos quais `y` com baixo peso; o modelo compara a probabilidade entre municípios usando esses dois números.
* **Superdispersão:** os dados variam **mais** do que o simples acaso permitiria; sobra diferença real entre municípios.
* **Beta-binomial:** igual à binomial, mas a probabilidade de baixo peso pode variar um pouco de município para município. O parâmetro ρ mede o tamanho dessa variação.
* **Funil:** gráfico que mostra o quanto a taxa de um município oscilaria só por acaso; municípios pequenos oscilam muito, grandes pouco, daí o formato de funil.
* **Razão de chances (OR):** quantas vezes a *chance* (probabilidade ÷ (1 − probabilidade)) fica multiplicada. OR = 2 significa chance dobrada; não é o mesmo que probabilidade dobrada.
* **+10 p.p. e +1 DP:** variações de referência do preditor: 10 pontos percentuais, ou um desvio-padrão (o "tamanho típico" da diferença entre municípios).
* **Intervalo de confiança (IC):** faixa de valores plausíveis para a estimativa.
* **Resíduo e envelope simulado:** o resíduo mede o quanto o modelo errou em cada município; o envelope é a faixa de erro que o próprio modelo geraria por acaso. Pontos dentro dele = modelo compatível com os dados.
* **Município influente:** município que, se retirado, muda o resultado. Aqui retiramos para testar, mas **nenhum foi excluído**.
* **Moran:** mede se municípios vizinhos têm erros do modelo parecidos (dependência espacial). Aqui é fraca.
* **Associação ecológica:** conclusão sobre grupos (municípios), que **não** vale automaticamente para indivíduos.

---

## 1. Contexto

* **Disciplina:** CE314 — Modelos Lineares Generalizados (UFPR, Prof. Cesar Augusto Taconeli).
* **Autoria e papéis:** a análise (dados, modelagem, diagnóstico, resultados) foi conduzida por **Clerence (Vinicius de Lima Santana)**. Em 18/11 entraram **João Victor P. Goncalves** e **Leonardo E. Sakai** para ajudar na apresentação; os três constam nos slides finais. As orientações exigem que **todos os integrantes participem da apresentação e estejam preparados para explicar as decisões da análise**. Divisão da fala sugerida na Seção 0.6.
* **Tema 8:** investigar diferenças na **probabilidade de baixo peso ao nascer** entre municípios de residência das
  mães em SC, com **regressão binomial agrupada**:
  `glm(cbind(baixo_peso, demais) ~ x1 + x2 + ..., family = binomial, data = dados)`.
* **Datas:** slides em PDF (resposta binária) até **20/11/2026**, por e-mail para o professor; seminários em
  **30/11 e 01/12/2026**; apresentação de 10–15 min (descontam nota se fugir do intervalo) + 5 min de debate;
  10–20 slides principais, resto em apêndice.
* **Avaliação:** clareza do problema; preparação dos dados; coerência/justificativa da modelagem; diagnóstico;
  interpretação e limitações; reprodutibilidade; qualidade da apresentação; tempo; participação no debate.
* **Exigência de entendimento:** **todos os integrantes** precisam conseguir **explicar cada decisão** na defesa. Por isso toda etapa
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

| Item                                                        | Valor                                 |
| ----------------------------------------------------------- | ------------------------------------- |
| Registros / mães residentes em SC / nascidos em 2026        | 64.472 / 64.472 / 64.472              |
| Peso ignorado (excluído do denominador)                     | 3 (0,005%)                            |
| **Base de análise**                                         | **64.469 nascidos vivos**             |
| Baixo peso (sucessos) · taxa global                         | 5.302 · 8,22%                         |
| Municípios                                                  | 295 (todos com nascimentos; mínimo 8) |
| Nascimentos por município (Q1 · mediana · média · Q3 · máx) | 28 · 67 · 218,5 · 169 · 4.978         |
| Municípios com < 30 nascimentos / com 0 caso de baixo peso  | 80 / 24                               |
| Duplicatas                                                  | 0                                     |
| **Validação externa (TABNET, mesma prévia)**                | **0 diferenças em 295 municípios**    |

**Base final:** `data/processed/base_municipal_sc2026.rds` (e `_completa.rds`, `.csv`). Colunas:
`cod6, nome, n_nascidos, baixo_peso, demais, n_peso_ignorado, prop_adolescente, prop_esc_baixa,
prop_prenatal_insuf, prop_gestacao_mult, prop_mae_35mais, taxa_baixo_peso (só descrição), entra_no_ajuste`.

**Preditores candidatos (proporções municipais, escala 0–1, calculadas nos nascidos com peso conhecido):**

| Variável              | Definição                                                                               |
| --------------------- | --------------------------------------------------------------------------------------- |
| `prop_adolescente`    | mães de 10–19 anos                                                                      |
| `prop_esc_baixa`      | mães com < 8 anos de estudo (`escmae` 1–3)                                              |
| `prop_prenatal_insuf` | mães com < 6 consultas (`consprenat`; `00` = nenhuma consulta, válido; `99` = ignorado) |
| `prop_gestacao_mult`  | gravidez dupla ou mais                                                                  |
| `prop_mae_35mais`     | mães ≥ 35 anos (**extra, mantido por decisão do autor**)                                |

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
* **Hipótese levantada (e depois confirmada na D):** vários municípios com risco alto ficam no Meio-Oeste/Planalto → possível agrupamento espacial.

### Resumo da Etapa C (concluída em 10/11/2026; detalhes em `docs/etapa_C_modelagem.md`)

* **Modelo final:** `Y_i ~ BetaBinomial(n_i, π_i, ρ)`, `logit(π_i) = β0 + β1·pre10 + β2·mult10`, com preditores em **unidades de 10 p.p.** (`pre10 = prop_prenatal_insuf × 10`; `mult10 = prop_gestacao_mult × 10`).

| Termo    | β (EP)        | OR por +10 p.p. | OR por +1 DP | p (TRV)   |
| -------- | ------------- | --------------- | ------------ | --------- |
| `mult10` | 0,805 (0,091) | **2,24**        | ≈ 1,30       | 1,3×10⁻¹⁶ |
| `pre10`  | 0,151 (0,053) | **1,16**        | ≈ 1,08       | 0,0038    |

* **Convergência:** sem separação (ajustados entre 0,056 e 0,258; maior EP 0,107). φ Pearson: nulo 1,551 · completo 1,229 · final (binomial) 1,284. Preditores explicam 20,4% da deviance (completo, binomial).
* **Ligação:** logito (probito melhor por apenas 1,07 de AIC; cloglog 1,63; cauchit +15,0).
* **Família:** **beta-binomial.** TRV vs binomial χ² = 19,55 (p ≈ 5×10⁻⁶); AIC 1404,99 → 1387,44 (Δ = 17,5); ρ = 0,00103. A superdispersão **cresce com `n`**: φ observado 1,07 · 1,13 · 1,23 · **2,51** (classes `< 30` · 30–99 · 100–499 · `>= 500`) vs fator previsto `1+(n−1)ρ` 1,02 · 1,06 · 1,22 · **2,44**. O quasi-binomial (φ constante = 1,28) não reproduz isso e fica como **robustez**.
* **Seleção:** 32 modelos no binomial (QAIC) e no beta-binomial. No beta-binomial, 8 modelos ficam a menos de 2 de AIC do melhor; só `pre10` e `mult10` estão em 100% deles (`adol10`, `esc10` e `m35_10` em 50%, intercambiáveis). `pre10 + mult10`: ΔAIC = 1,45 e **melhor BIC**. **Procedimento corrigido:** escolher a família **antes** de selecionar (o QAIC do binomial indicava 4 variáveis, abandonado).
* **Descartadas:** `esc10` (p > 0,6 com `n ≥ 30`, sinal negativo), `m35_10` (p = 0,29), `adol10` (limítrofe: p = 0,058 no beta-binomial ao acrescentá-la; fica como robustez).
* **Forma funcional:** sem curvatura (quadráticos p = 0,68 e 0,19; teste de η̂² p = 0,21) → **sem termos quadráticos**.
* **Robustez:** `mult10` estável (OR 2,19–2,35 em todos os cenários e famílias). `pre10` **sensível à família e à definição**: beta-binomial 1,16 (p = 0,004) vs quasi 1,09 (p = 0,067); com pré-natal < 7 consultas cai a 1,07 (bb, p = 0,050) e 1,04 (quasi, p = 0,24). Deve ser reportada como **associação moderada e sensível à família e à definição**.

### Resumo da Etapa D (concluída em 11/11/2026; detalhes em `docs/etapa_D_diagnostico.md`)

* **Adequação da distribuição:** resíduos quantílicos aleatorizados com média 0,003 e **DP 0,997** (12 com |r|>2 e 1 com |r|>3; binomial: DP 1,10, 21 e 3); **envelope simulado sem nenhum ponto fora** (99 simulações com reajuste); DHARMa sem problemas no beta-binomial (KS p = 0,82; dispersão p = 0,13; outliers p = 1), enquanto o binomial mostra desvio de quantis e dispersão significativa (p = 0,036).
* **Teste central (pendência da C):** φ de Pearson por classe de `n` (`< 30` · 30–99 · 100–499 · `>= 500`): **beta-binomial 1,06 · 1,05 · 0,96 · 1,15**; binomial 1,07 · 1,13 · 1,23 · **2,51**. φ global cai de 1,284 para 1,052. Resíduos sem correlação com `pre10`, `mult10`, `log(n)` e `η̂` (|r| < 0,014).
* **Forma funcional e ligação:** splines de 3 gl p = 0,51 (conjunto), 0,19 (`mult10`), 0,95 (`pre10`); η̂² p = 0,137; resíduos parciais sem curvatura clara (em `mult10` a suavização achata acima de ≈ 10 p.p., com ~8 municípios) → **lineares no logito**; gráfico de probabilidades restrito a `mult10` ≤ 17,4 p.p.
* **Multicolinearidade:** VIF = 1,003; r(`pre10`, `mult10`) = −0,033.
* **Influência (LOO exato, nenhuma exclusão):** maior |DFBETAS| = 0,52 (Morro Grande, em `mult10`) e 0,49 (Florianópolis, em `pre10`); nenhum chega a 1. Cook máx. 0,113 (Florianópolis; **no binomial seria 1,66**: o beta-binomial reduz o peso dos grandes). 15 e 14 municípios acima de 2/√n, ≈ 5%, o esperado por acaso.
* **Sensibilidade a atípicos (6 cenários):** OR de `mult10` 2,14–2,35; de `pre10` 1,13–1,24 (sempre p < 0,05); nenhum cenário muda a OR em mais de 10%. Sem os 28 maiores, ρ ≈ 0,00005 (a superdispersão está nos municípios grandes).
* **Moran:** dependência espacial **fraca**, mas detectável nos resíduos do modelo final: I = 0,077 (p = 0,015, contiguidade) e 0,068 (p = 0,024, 5 vizinhos, coordenadas projetadas).
* **D12, sensibilidade espacial** (M1 região intermediária IBGE 2019, 7 regiões; M2 lon/lat; M3 superfície quadrática; M4 efeito aleatório espacial): OR de `mult10` **2,14–2,17** e de `pre10` **1,16–1,21**, sempre significativas, com EP iguais ou menores. Moran cai para **0,020 (p = 0,25) com região** e **0,038 (p = 0,13) com superfície**. ρ cai de 0,00103 para 0,00033 (região) e 0,00021 (superfície): **68–80% da heterogeneidade extra entre municípios é diferença geográfica**. A OR de `pre10` **sobe** ao controlar região/superfície (a região de Caçador tem a maior taxa e a menor proporção de pré-natal insuficiente). **M4 não convergiu** (variância ≈ 10⁻⁶, `pdHess` = FALSE) e foi descartado. AIC prefere M1/M3 (−13 a −15) e BIC prefere M0.
* **Decisão:** o **modelo final continua M0** (beta-binomial, `pre10 + mult10`, lineares); D12 entra como robustez e limitação ("dependência espacial fraca, absorvida por região ou superfície, sem alterar as conclusões").

### Resumo da Etapa E (concluída em 13/11/2026; detalhes em `docs/etapa_E_resultados.md`)

* **Reajuste** reproduz a C (β_mult 0,8055; β_pre 0,1509; φ 968,9; ρ 0,00103; `pdHess` = TRUE). Intercepto −2,731 (EP 0,057): π = 6,1% com os dois preditores em 0; ≈ 8,2% nas médias (7,8% e 2,4%).

| Termo    | β (EP)        | OR +10 p.p. (IC Wald) | IC perfil | OR +1 DP (IC)        | p TRV     |
| -------- | ------------- | --------------------- | --------- | -------------------- | --------- |
| `mult10` | 0,805 (0,091) | **2,24** (1,87–2,68)  | 1,87–2,67 | **1,30** (1,23–1,38) | 1,3×10⁻¹⁶ |
| `pre10`  | 0,151 (0,053) | **1,16** (1,05–1,29)  | 1,05–1,29 | **1,08** (1,03–1,14) | 0,0038    |

* **TRV:** modelo final × nulo χ² = 73,8 (2 gl), p ≈ 9×10⁻¹⁷; AIC 1457,3 → 1387,4; log-verossimilhança −726,6 → −689,7; BIC 1402,2; redução da deviance no binomial 17,6%. Wald e perfil coincidem; nos slides, Wald.
* **Efeito em probabilidade** (IC por 10.000 sorteios de β; outro preditor na média): `mult10` +1 DP (2,4% → 5,7%) = **+2,2 p.p.** (1,7–2,7), razão de probabilidades 1,27; +10 p.p. = +8,4 p.p. (6,1–11,0; razão 2,03; cuidado: vai a 12,4%, região esparsa); 0% → 5% = +3,1 p.p. `pre10` +1 DP (7,8% → 12,9%) = **+0,6 p.p.** (0,2–1,0), razão 1,07; +10 p.p. = +1,2 p.p. (0,4–2,1).
* **Probabilidades preditas (π, IC 95%):** `mult10` 0% → 6,8% (6,4–7,2); 2,4% → 8,2%; 5% → 9,9%; 10% → 14,1% (12,5–15,8); 15% → 19,7% (16,4–23,5); máx. 17,4% ≈ 23%. `pre10` 0% → 7,3% (6,7–8,0); 7,8% → 8,2%; 12% → 8,7%; 20% → 9,7% (8,6–10,8); 25% → 10,3% (8,8–12,1). Só **10 municípios** com `mult10` > 10 p.p.
* **Heterogeneidade:** ρ 0,00191 (nulo) → 0,00103 (final; IC 95% Wald em log φ: 0,00046–0,00229), **−46%**; com região/superfície (D12) cai a 0,00033/0,00021.
* **Robustez:** `mult10` robusto (OR 2,14–2,35 em todas as famílias e cenários). `pre10`: robusto a atípicos (1,13–1,24, todos p < 0,05), ao espaço (1,16–1,21) e a `adol10`/`n ≥ 30` no bb (1,15–1,17), mas **sensível à família** (quasi-binomial 1,09, IC 0,99–1,20, p = 0,066; binomial sem correção p = 0,037) e à definição de pré-natal (limiar 7: 1,04–1,07). O binomial sem correção dá IC mais estreito que o quasi: ilustra EP subestimado sem a correção. `adol10` no modelo com ela: OR 1,12 (0,996–1,256), p = 0,058.
* **Calibração descritiva:** sem desvio sistemático por decil de π̂; esperado total 5.390 × observado 5.302 (+1,7%); nos 28 maiores, esperado 3.277 × observado 3.158 (+3,8%), contrapartida de o beta-binomial pesar menos os grandes (da ordem de 1 a 1,5 DP; conta aproximada).
* **Conferência da D7:** os cenários 1 (5 maiores DFBETAS) e 2 (5 maiores Cook) são o **mesmo conjunto** (Morro Grande, Florianópolis, Jaborá, Sangão, Caçador): citar como um cenário só. Florianópolis: Cook 0,113 no bb × 1,66 no binomial.
* **Conclusões sustentadas:** (1) gestação múltipla: associação forte, positiva e estável; (2) pré-natal insuficiente: associação positiva **moderada**; (3) os dois preditores reduzem cerca de metade da heterogeneidade (ρ) e boa parte do resto é geográfica; tudo como **associação municipal**.
* **Pendência cosmética (não afeta resultados):** rótulos dos painéis do `E_forest_robustez.png` ainda estão como `mult10`/`pre10`; trocar por "Gestação múltipla (+10 p.p.)" e "Pré-natal insuficiente (+10 p.p.)". O trecho do IC de ρ no `06_resultados.R` precisa usar `summary(bb$sdr, "fixed")` (versão que gerou o IC acima).

### Resumo da Etapa F (concluída em 18/11/2026; detalhes em `docs/etapa_F_fechamento.md`)

* **Entrega:** `slides/slides_tema8_v2.qmd` → PDF de **26 páginas** (título + 17 slides principais + apêndice A1–A8), Quarto/Beamer, paleta Saúde/Biostatística, data 30/11/2026.
* **Revisão v1 → v2 (erros de conteúdo corrigidos):** (1) calibração dos 28 maiores: **+3,8%** sobre o observado (3.277 × 3.158), não +3,6% (que era sobre o esperado); o +1,7% do total já usava o observado; (2) tabela de Moran sem a linha "lon/lat" (só região 0,020 e superfície 0,038 estão nas saídas); (3) forma funcional citada só com os testes do modelo final (splines p = 0,51; η̂² p = 0,14), sem misturar com os do quase-binomial da C; (4) "+10 p.p. sai do suporte" corrigido para "região esparsa" e linha +8,4 p.p. / razão 2,03 incluída na tabela de efeitos; (5) nomes `pre10`/`mult10` definidos no slide de preditores.
* **Roteiro:** 13:45 min; cortar o slide de seleção se o ensaio passar de 14:30. Q&A com 22 perguntas.
* **Pendências:** enviar o PDF a cetaconeli@gmail.com até 20/11; combinar a divisão da fala entre os três (Seção 0.6); ensaiar com cronômetro.

---

## 3. Plano das próximas etapas

Numeração dos scripts: `01_preparacao_base.R`, `02_conferencia_tabnet.R`, `03_exploratoria.R`, `04_modelagem.R`, `05_diagnostico.R`, `05b_sensibilidade_espacial.R` e `06_resultados.R` já existem.

### Etapa B — Exploratória (`03_exploratoria.R` + `docs/etapa_B_exploratoria.md`) — **concluída em 02/11**

* Distribuição da taxa e de `n_i`; funil; preditores × taxa; assimetria; correlações; linearidade no logito (sem ajustar modelo).

### Etapa C — Modelagem (`04_modelagem.R` + `docs/etapa_C_modelagem.md`) — **concluída em 10/11**

* Binomial-logito completo; ligações; testes por termo (TRV e teste F tipo II); 32 modelos por AIC/BIC/QAIC; família (binomial × quasi × **beta-binomial**); seleção refeita no beta-binomial; forma funcional; sensibilidades (jan–jul, pré-natal < 7, com `adol10`, `n ≥ 30`).
* **Resultado:** ver Seção 2. Tudo em `output/tabelas/C_*.csv` e `data/processed/C_modelos.rds`.

### Etapa D — Diagnóstico (`05_diagnostico.R`, `05b_sensibilidade_espacial.R` + `docs/etapa_D_diagnostico.md`) — **concluída em 11/11**

* Resíduos quantílicos (manual + DHARMa), envelope simulado, resíduos × preditores/tamanho, resíduos parciais, splines, η̂², VIF, alavancagem/Cook/DFBETAS (LOO exato), sensibilidade a atípicos, Moran, sensibilidade espacial (D12).
* **Resultado:** ver Seção 2. Tudo em `output/tabelas/D_*.csv`, `D12_*.csv`, `output/figuras/D_*.png`, `D12_*.png` e `data/processed/D_diagnostico.rds`, `D12_espacial.rds`.

### Etapa E — Resultados (`06_resultados.R` + `docs/etapa_E_resultados.md`) — **concluída em 13/11**

* **Resultado:** ver Seção 2. Tudo em `output/tabelas/E_*.csv`, `output/figuras/E_*.png` e `data/processed/E_resultados.rds`. O plano abaixo foi cumprido.
* **Modelo apresentado:** beta-binomial M0 (`pre10 + mult10`); quasi-binomial e binomial lado a lado como robustez; **OR de M1–M3 (D12) como robustez espacial**.
* Estimativas do modelo final com ICs (Wald e **perfil**, se o `glmmTMB` permitir; senão Wald), razões de chances **por +10 p.p. e por +1 DP** (DP de `mult10` ≈ 3,3 p.p.; de `pre10` ≈ 5,1 p.p.), TRV por termo; ρ com IC.
* **Gráfico exigido:** probabilidade predita de baixo peso × `mult10` e × `pre10`, com IC, mantendo o outro preditor na média; **restringir ao suporte observado** (`mult10` ≤ 17,4 p.p.; `pre10` ≤ ≈ 26,7 p.p.) e sombrear/anotar a região de poucos municípios (`mult10` > 10 p.p.).
* Medida de ajuste: redução de deviance vs nulo (binomial) e/ou diferença de log-verossimilhança no beta-binomial.
* Tabela de robustez: cenários da C (C10), atípicos (D7) e espaciais (D12).
* Interpretação sempre como associação entre municípios; `pre10` como **moderada**, sensível à família e à definição de pré-natal, mas **não** ao espaço nem a municípios isolados.

### Etapa F — Fechamento (`docs/etapa_F_fechamento.md`, `slides/slides_tema8_v2.qmd`) — **concluída em 18/11**

* **Slides finais (PDF, 26 páginas):** título · pergunta · base de dados · resposta e preditores · funil · linearidade no logito · modelo · por que beta-binomial · seleção e forma funcional · resíduos/envelope · influência e espaço · estimativas · probabilidades com IC · efeito em p.p. · robustez · limitações · conclusões · perguntas. **Apêndice A1–A8:** taxas por faixas, calibração, robustez por família, sensibilidade espacial, influência, resíduos parciais, resíduos × tamanho, correlações e conferência de dados.
* **Mensagens-chave:** gestação múltipla = associação forte e estável (OR 2,24 por +10 p.p.; 1,30 por +1 DP; +2,2 p.p.); pré-natal insuficiente = associação **moderada** (OR 1,16; +0,6 p.p.), sensível à família e à definição; heterogeneidade extra concentrada nos municípios grandes e em parte geográfica; tudo como associação municipal.
* **Limitações declaradas:** prévia (agosto parcial); municípios pequenos (erro de medida); desenho ecológico; seleção e inferência nos mesmos dados; `pre10` sensível à família e à definição; dependência espacial residual fraca (Moran ≈ 0,07; EP possivelmente otimistas); beta-binomial pesa menos os grandes (+3,8% esperado vs observado nos 28 maiores; +1,7% no total); cauda de `mult10` esparsa (10 municípios > 10 p.p.); sem covariáveis socioeconômicas; χ² da deviance não usado (A4).
* **Pendências:** enviar o PDF até 20/11; combinar a divisão da fala (Seção 0.6); ensaiar os três juntos (13–14 min).

---

## 4. Cronograma (hoje: 18/11/2026; entrega dos slides: **20/11**)

| Prazo         | Entrega                                                                                                                           |
| ------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| até 04/11     | Etapa B (exploratória) — **feita em 02/11**                                                                                       |
| até 08/11     | Etapa C (modelagem e seleção) — **concluída em 10/11**                                                                            |
| até 12/11     | Etapa D (diagnóstico) — **concluída em 11/11**                                                                                    |
| até 14/11     | Etapa E (resultados e gráficos) — **concluída em 13/11**                                                                          |
| 14–18/11      | Etapa F: conclusão, slides, roteiro, Q&A e revisão completa (v1 → v2) — **concluída em 18/11**                                    |
| **20/11**     | **Envio do PDF dos slides** (`slides_tema8_v2.pdf`) para cetaconeli@gmail.com                                                     |
| 21–29/11      | Os três estudam a Seção 0 e `etapa_F_fechamento.md` (Seções 3 a 5); ensaio conjunto cronometrado (10–15 min); treino de perguntas |
| 30/11 e 01/12 | Seminários (ordem e grupos debatedores definidos em 27/10)                                                                        |

Se sobrar pouco tempo, o que cortar na fala: o slide de seleção. O que nunca cortar: funil, "por que beta-binomial", envelope com φ por classe, tabela de estimativas e gráfico de probabilidades.

---

## 5. Glossário rápido de termos que apareceram

* **Moran (I de Moran):** medida de **autocorrelação espacial**. Pergunta: "municípios vizinhos têm valores parecidos
  mais do que o acaso explicaria?". Varia aproximadamente de −1 a +1; ≈ 0 = sem dependência espacial; positivo =
  vizinhos parecidos. Aplicado aos **resíduos**: se há dependência espacial, os municípios não são independentes
  (suposição do GLM) e os erros-padrão podem ficar **subestimados**. Aqui: I ≈ 0,07–0,08 (p ≈ 0,02), fraco, e absorvido por região ou superfície geográfica.
* **Funil (funnel plot):** gráfico da taxa contra o tamanho `n_i` com bandas esperadas sob o acaso; taxas de municípios
  pequenos variam muito mais, por isso formam um "funil".
* **Superdispersão:** variância dos dados maior do que a binomial prevê. Corrige-se com quasi-binomial ou beta-binomial.
* **Quasi-binomial:** mantém a média do modelo binomial, mas estima um parâmetro de dispersão φ e multiplica os erros-padrão.
* **Beta-binomial:** binomial em que π varia entre municípios segundo uma Beta; modelo probabilístico completo.
* **Razão de chances (OR):** `exp(β)`; quanto a chance de baixo peso fica multiplicada por unidade do preditor (aqui, por 10 p.p.).
* **TRV (teste da razão de verossimilhanças):** compara dois modelos encaixados pela diferença de `−2·log-verossimilhança`; para testar ρ = 0 a distribuição é uma mistura 50:50 de χ²₀ e χ²₁, logo o p-valor é a **metade** do p do χ²₁.
* **QAIC:** AIC corrigido para superdispersão; vale para binomial/quasi, **não** para o beta-binomial.
* **ρ (correlação intraclasse):** no beta-binomial, `Var = nπ(1−π)[1+(n−1)ρ]`; ρ pequeno (0,001) importa porque o fator cresce com `n`.
* **Teste F (análise de deviance):** versão do TRV quando φ é estimado.
* **OR por +10 p.p. / por +1 DP:** razão de chances para uma variação de 10 pontos percentuais / de um desvio-padrão do preditor entre municípios.
* **Resíduo quantílico aleatorizado:** `Φ⁻¹(F(y))`, com sorteio dentro do salto da função de distribuição quando `y` é discreto; N(0,1) se o modelo está certo.
* **Envelope simulado:** faixa dos resíduos que o próprio modelo geraria por acaso (simula, reajusta, mín–máx).
* **Alavancagem, Cook, DFBETAS:** influência potencial (posição em `x`), influência global e mudança padronizada em cada coeficiente ao retirar um município; aqui calculados por reajuste exato (leave-one-out).
* **VIF:** `1/(1−R²_j)`; incha a variância de `β_j` por colinearidade.
* **Região intermediária (IBGE):** divisão regional (7 em SC) usada como efeito fixo no D12 (a mesorregião 2010 não está disponível no `geobr`).
* **IC por verossimilhança perfilada:** valores de β que o TRV não rejeita; mais fiel que Wald com poucas observações. Aqui coincidiu com Wald.
* **Razão de probabilidades × razão de chances:** a OR (2,24 por +10 p.p. em `mult10`) vira razão de probabilidades de 2,03 e +8,4 p.p., porque a probabilidade de base (≈ 8%) não é desprezível; o contraste depende do ponto de partida.
* **IC da probabilidade média:** IC em `η = Xβ` e depois `plogis`; descreve a incerteza da curva π, **não** o espalhamento das taxas municipais observadas (ruído binomial + ρ).
* **Calibração descritiva:** taxa observada × esperada por grupos (decis de π̂, classes de `n`); checagem de bom senso, não teste.
* **Falácia ecológica:** conclusões sobre indivíduos a partir de dados agregados; proibida pelas orientações.

---

## 6. Estrutura do repositório

```
.
├── README.md
├── .gitignore                       # data/raw/  e  *.Rhistory
├── data/
│   ├── raw/                         # DNSC2026.dbc, tabnet_nv_sc2026_peso.csv  (NÃO versionar)
│   └── processed/                   # base_municipal_sc2026.rds / _completa.rds / .csv, C_modelos.rds, D_diagnostico.rds, D12_espacial.rds, E_resultados.rds
├── scripts/
│   ├── 01_preparacao_base.R         # feito
│   ├── 02_conferencia_tabnet.R      # feito
│   ├── 03_exploratoria.R            # B (feito)
│   ├── 04_modelagem.R               # C (feito)
│   ├── 05_diagnostico.R             # D (feito)
│   ├── 05b_sensibilidade_espacial.R # D12 (feito)
│   └── 06_resultados.R              # E (feito)
├── docs/
│   ├── plano_geral.md               # este arquivo
│   ├── etapa_A_preparacao_dados.md  # feito
│   ├── etapa_B_exploratoria.md      # feito
│   ├── etapa_C_modelagem.md         # feito
│   ├── etapa_D_diagnostico.md       # feito
│   ├── etapa_E_resultados.md        # feito
│   └── etapa_F_fechamento.md        # F (feito)
├── output/
│   ├── tabelas/
│   └── figuras/
└── slides/                          # slides_tema8_v2.qmd e PDF final
```

Pacotes já usados: `dplyr`, `tibble`, `datasusr`, `geobr`, `sf`, `spdep`, `car`, `glmmTMB` (beta-binomial), `DHARMa`, `splines`, `patchwork`, `ggplot2`. Usados na E: `MASS` (`mvrnorm`), `scales`; as predições foram feitas à mão (`η = Xβ`, EP = √diag(XVX′)) em vez de `ggeffects`/`marginaleffects`, por transparência e compatibilidade com `glmmTMB`. Para a F (slides): Quarto/Beamer (`template_slides_R.qmd`). Se o `glmmTMB` falhar, alternativa: `VGAM::vglm(..., betabinomial)`.

---

## 7. Registro de decisões do plano (atualizar a cada mudança)

| Data       | Decisão                                                                                                                                                                                                                                                                 | Quem                  |
| ---------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------- |
| 01/11/2026 | Manter agosto (jan–ago) como base principal; sensibilidade jan–jul                                                                                                                                                                                                      | autor, após checagens |
| 01/11/2026 | Manter `prop_mae_35mais` como 5º preditor candidato                                                                                                                                                                                                                     | autor                 |
| 01/11/2026 | Data de entrega dos slides: 20/11                                                                                                                                                                                                                                       | autor                 |
| 01/11/2026 | Trabalho individual (dupla ausente)                                                                                                                                                                                                                                     | autor                 |
| 01/11/2026 | Seguir plano B→F, ajustável conforme os resultados                                                                                                                                                                                                                      | autor                 |
| 02/11/2026 | Etapa B concluída; heterogeneidade real entre municípios (funil, φ nulo = 1,55) → considerar quasi-binomial/beta-binomial na C                                                                                                                                          | autor                 |
| 02/11/2026 | Preditores contínuos e lineares no logito (curvaturas eram de municípios pequenos); quadrático só como checagem de robustez                                                                                                                                             | autor                 |
| 02/11/2026 | Sensibilidade `n ≥ 30` passa a ser análise essencial                                                                                                                                                                                                                    | autor                 |
| 10/11/2026 | Preditores em unidades de 10 p.p. (OR por +10 p.p. e por +1 DP)                                                                                                                                                                                                         | autor                 |
| 10/11/2026 | Ligação logito (ΔAIC < 2 vs probito/cloglog; cauchit rejeitado, +15)                                                                                                                                                                                                    | autor                 |
| 10/11/2026 | Família principal: **beta-binomial** (TRV p ≈ 5×10⁻⁶; ΔAIC 17,5; φ cresce com `n`); quasi-binomial como robustez                                                                                                                                                        | autor                 |
| 10/11/2026 | Procedimento corrigido: escolher família **antes** de selecionar variáveis; seleção refeita no beta-binomial                                                                                                                                                            | autor                 |
| 10/11/2026 | **Modelo final: `prop_prenatal_insuf` + `prop_gestacao_mult`** (ΔAIC 1,45; melhor BIC; 100% dos modelos competitivos)                                                                                                                                                   | autor                 |
| 10/11/2026 | `esc10` descartada (p > 0,6 com `n ≥ 30`); `m35_10` e `adol10` fora (intercambiáveis); `adol10` fica como robustez                                                                                                                                                      | autor                 |
| 10/11/2026 | Sem termos quadráticos (p = 0,68; 0,19; η̂² p = 0,21)                                                                                                                                                                                                                    | autor                 |
| 10/11/2026 | `pre10` reportada como associação moderada e sensível (família e limiar de pré-natal)                                                                                                                                                                                   | autor                 |
| 10/11/2026 | Etapa C concluída; Etapa D com prazo reajustado para 12/11                                                                                                                                                                                                              | autor                 |
| 11/11/2026 | Diagnóstico por resíduo quantílico (manual + DHARMa), envelope simulado manual e LOO exato; **nenhuma exclusão**                                                                                                                                                        | autor                 |
| 11/11/2026 | Modelo final **mantido** (beta-binomial, `pre10 + mult10`, lineares); sem termos extras após diagnóstico                                                                                                                                                                | autor                 |
| 11/11/2026 | Moran feito (I ≈ 0,07–0,08, p ≈ 0,02) → limitação; D12 mostra que região/superfície o absorvem sem mudar as conclusões                                                                                                                                                  | autor                 |
| 11/11/2026 | D12: M1 com **região intermediária IBGE 2019** (mesorregião 2010 indisponível no `geobr`); M4 (efeito aleatório espacial) descartado por não convergir; modelo final = M0                                                                                               | autor                 |
| 11/11/2026 | Explicação do `testDispersion` do DHARMa da Etapa C **corrigida** (não é o mecanismo dos municípios minúsculos; no bb p = 0,13)                                                                                                                                         | autor                 |
| 11/11/2026 | Gráfico de probabilidades (E) restrito ao suporte observado de `mult10` (≤ 17,4 p.p.)                                                                                                                                                                                   | autor                 |
| 11/11/2026 | Etapa D concluída (D1–D12); próxima: Etapa E                                                                                                                                                                                                                            | autor                 |
| 13/11/2026 | Etapa E executada; reajuste reproduz a C; Wald nos slides (perfil coincide); OR por +10 p.p. e +1 DP; efeitos também em p.p. de probabilidade (IC por simulação)                                                                                                        | autor                 |
| 13/11/2026 | `mult10` classificada como robusta; `pre10` como associação moderada, robusta a atípicos e espaço, sensível à família e à definição                                                                                                                                     | autor                 |
| 13/11/2026 | Gráfico de probabilidades: mesmo eixo y nos dois painéis (slide); versão com dados no apêndice; 3 municípios > 30% fora do eixo                                                                                                                                         | autor                 |
| 13/11/2026 | IC de ρ obtido (0,00046–0,00229); redução de ρ pelos preditores (−46%) descrita como "cerca de metade", sem teste formal                                                                                                                                                | autor                 |
| 13/11/2026 | D7 cenários 1 e 2 são o mesmo conjunto de 5 municípios (Morro Grande, Florianópolis, Jaborá, Sangão, Caçador): citar como um cenário                                                                                                                                    | autor                 |
| 13/11/2026 | Calibração descritiva sem desvio sistemático; leve superestimação nos 28 maiores (+3,8%) declarada como limitação                                                                                                                                                       | autor                 |
| 13/11/2026 | Etapa E concluída; próxima: Etapa F (conclusão, slides PDF, roteiro, Q&A); pendência cosmética: rótulos do forest de robustez                                                                                                                                           | autor                 |
| 14/11/2026 | Slides em Quarto/Beamer (QMD → PDF), 17 slides principais + título + apêndice                                                                                                                                                                                           | autor                 |
| 18/11/2026 | Revisão completa v1 → v2: corrigido +3,6% → **+3,8%** (28 maiores; base = observado); Moran por modelo só com região e superfície; forma funcional citada com os testes do modelo final; "+10 p.p. sai do suporte" → "região esparsa"; nomes `pre10`/`mult10` definidos | autor                 |
| 18/11/2026 | Apêndice ampliado para A1–A8 (resíduos parciais e resíduos × tamanho)                                                                                                                                                                                                   | autor                 |
| 18/11/2026 | Slides finais = `slides_tema8_v2` (26 páginas, data 30/11/2026), renderizados e conferidos                                                                                                                                                                              | autor                 |
| 18/11/2026 | Dois integrantes (J. V. P. Goncalves e L. E. Sakai) passam a ajudar na apresentação; análise conduzida por Clerence; os três constam nos slides. Plano reescrito para servir também de guia aos colegas (nova Seção 0)                                                  | autor                 |
| 18/11/2026 | Divisão da fala sugerida em três blocos (≈ 4:30 · 4:15 · 5:00); responsáveis a preencher (Seção 0.6)                                                                                                                                                                    | autor                 |
| 18/11/2026 | Etapa F concluída; próximos passos: enviar PDF até 20/11 e ensaiar                                                                                                                                                                                                      | autor                 |
