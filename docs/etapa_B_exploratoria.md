# Etapa B — Análise exploratória (Tema 8, baixo peso ao nascer em SC, SINASC 2026)

Script: `scripts/03_exploratoria.R` · Status: **CONCLUÍDA em 02/11/2026 (todas as saídas conferidas, incluindo a figura com `n ≥ 30`)**.

---

## 0. Para que serve esta etapa

As orientações pedem, no item (b), *"descrever a resposta e explorar suas relações com os principais preditores, utilizando tabelas e gráficos pertinentes"*. A Etapa B responde **quatro perguntas** que preparam a modelagem (Etapa C) **sem ajustar nenhum modelo**:

1. **Como é a resposta?** A taxa varia entre municípios? Quanto é só ruído por município pequeno?
2. **Como são os preditores?** Distribuição, zeros, assimetria, ruído.
3. **Cada preditor parece se relacionar com o baixo peso?** A relação parece **linear no logito**?
4. **Os preditores se misturam entre si?**

> **Regra de ouro:** explorar para *entender e planejar*, não para *concluir*. Nenhum p-valor, nenhuma seleção de variável aqui.

**Entrada:** `data/processed/base_municipal_sc2026.rds` (295 municípios, validada contra o TABNET).
**Saídas:** `output/figuras/B_*.png`, `output/tabelas/B_*.csv`, `data/processed/base_municipal_sc2026_exploratoria.rds`.

---

## 1. Resumo executivo (o que a Etapa B mostrou)

| # | Achado | Veredito |
|---|---|---|
| 1 | O desvio-padrão da taxa e o dos preditores **cai fortemente com o tamanho** do município (ex.: DP de `prop_adolescente` vai de 6,9 p.p. em municípios `< 30` para 1,95 p.p. em `>= 500`). A taxa agregada **não** tem tendência com o tamanho (8,40 · 7,89 · 8,64 · 8,08%). | Esperado. Confirma que o ruído binomial domina nos pequenos. **Não é problema.** |
| 2 | Funil: **24** municípios fora dos limites de 95% (esperado ≤ ≈ 14,8) e **2** fora dos de 99,8% (esperado ≈ 0,6). O excesso se concentra nos **grandes**: 25% (7/28) dos municípios com `>= 500` nascimentos estão fora. | **Há diferenças reais entre municípios**, além do acaso. É um achado, não um defeito. |
| 2b | Dos 24 municípios fora de 95%, **18 estão acima** e 6 abaixo de 8,22%; vários acima ficam no Meio-Oeste/Planalto (Concórdia, Caçador, Joaçaba, Campos Novos, São Joaquim, Herval d'Oeste, Itaiópolis). | **Hipótese** (não resultado): agrupamento regional → motiva o teste de Moran na Etapa D. |
| 3 | Dispersão do modelo nulo: **φ = 455,99/294 = 1,55**. | Superdispersão **antes** dos preditores; parte pode ser explicada por eles. Planejar quasi-binomial/beta-binomial. |
| 4 | Reta ponderada e loess divergiam nas caudas. **Removendo os municípios com `n < 30` (figura `B_preditor_x_logito_n30.png`), reta e loess praticamente coincidem** em `prop_adolescente`, `prop_gestacao_mult` e `prop_prenatal_insuf`; sobram resquícios leves na cauda esquerda de `prop_mae_35mais` e de `prop_esc_baixa`. | As curvaturas eram **ruído de município pequeno**. Sem evidência para termos não lineares. |
| 5 | Faixas extremas de vários preditores têm IC que **exclui** os 8,22% globais. `prop_gestacao_mult` é a associação marginal mais nítida e monotônica (6,7% → 11,5%). | Associação marginal, esperada. Não é teste de modelo. |
| 6 | Correlações com a resposta: `prop_gestacao_mult` ≈ 0,4–0,47 em **todas** as versões; as demais são fracas. `prop_esc_baixa` e `prop_adolescente` **mudam** quando se removem municípios `< 30`. Entre preditores: máx. |r| = 0,19. | Sem colinearidade. Duas variáveis sensíveis aos municípios pequenos → reforça a sensibilidade (d). |

---

## 2. Conceitos que você precisa dominar

| Conceito | Explicação em uma frase | Por que importa aqui |
|---|---|---|
| **Binomial agrupada** | Em cada município, `Y_i` = nº com baixo peso entre `n_i`; `Y_i ~ Binomial(n_i, π_i)`. | A resposta do modelo é o **par (sucessos, insucessos)**, não a taxa. |
| **Variância binomial** | `Var(Y_i/n_i) = π(1−π)/n_i`: cai com `n_i`. | Município pequeno tem taxa instável **só por acaso**. É o coração da etapa. |
| **Funil** | Taxa × `n_i` com faixas do que o acaso binomial permitiria se todos tivessem a mesma probabilidade. | Separa "diferença real" de "ruído de município pequeno". |
| **Logito empírico** | `log((y+0,5)/(n−y+0,5))`; o 0,5 evita `log(0)` (24 municípios têm 0 casos). | A regressão logística é **linear no logito**; é nele que olhamos linearidade. |
| **Correlação ponderada** | Cada município pesa `n_i`. | Município com 8 nascimentos não deve pesar como Joinville. |
| **IC de Wilson** | IC para proporção que funciona bem com `n` pequeno. | Usado nas taxas por faixa. |
| **Dispersão φ** | Variância observada ÷ variância binomial. φ≈1: só acaso; φ>1: **superdispersão**. | Antecipa se precisaremos de quasi-binomial/beta-binomial. |

---

## 3. Decisões e resultados

Formato: **o que · alternativas · por que · risco · frase para a banca · resultado real**.

### B1 — Descrever a resposta pela taxa, deixando claro que a taxa é só descrição

* **O que:** histograma da taxa municipal, tabela por classe de tamanho, histograma de `n_i`.
* **Alternativas:** só a taxa global; só municípios grandes.
* **Por que:** mostrar a **heterogeneidade de tamanho** e que a taxa crua engana.
* **Risco:** ler o histograma da taxa como "distribuição do risco" (parte da dispersão é ruído).
* **Frase para a banca:** *"A taxa municipal aparece só para descrever. A resposta do modelo é o par sucessos/insucessos, porque o tamanho de cada município determina a precisão da sua taxa."*
* **Resultados reais:**
  * Taxa global **p0 = 8,224%** (5.302/64.469).
  * Taxa municipal: mín 0 · Q1 5,48% · mediana 7,95% · média 8,32% · Q3 10,35% · máx 44,4%; DP = 5,30 p.p.
  * `n_i`: mín 8 · Q1 28 · mediana 67 · média 218,5 · Q3 169 · máx 4.978; percentis 90% = 467 e 95% = 885.
  * **Concentração:** 28 municípios (≥ 500) concentram **60,6%** dos nascimentos; os 80 menores (`< 30`), só **2,4%**.

| Classe de `n_i` | Municípios | Nascimentos | % nasc. | Baixo peso | Taxa agregada |
|---|---|---|---|---|---|
| `< 30` | 80 | 1.560 | 2,4 | 131 | 8,40% |
| 30–99 | 105 | 6.150 | 9,5 | 485 | 7,89% |
| 100–499 | 82 | 17.691 | 27,4 | 1.528 | 8,64% |
| `>= 500` | 28 | 39.068 | 60,6 | 3.158 | 8,08% |

  * **Dispersão da taxa por classe (DP, em p.p.) e amplitude:**

| Classe | `dp_taxa` | Taxa mín | Taxa máx |
|---|---|---|---|
| `< 30` | **8,36** | 0 | 44,4 |
| 30–99 | **4,51** | 0 | 25,0 |
| 100–499 | **2,57** | 2,9 | 18,1 |
| `>= 500` | **1,44** | 4,9 | 11,5 |

  * O DP cai ≈ **5,8 vezes** (8,36 → 1,44) enquanto a taxa agregada fica estável: variabilidade por ruído binomial, não por "risco" diferente.
  * Municípios sem nenhum caso: **24** no total (Etapa A); só existem nas classes `< 30` e `30–99` (taxa mínima 0 só nelas). A coluna `municipios_taxa0` do script saiu 0 por **erro de código** (Seção 5), já corrigido.
  * Maiores municípios: Joinville (4.978; 7,29%), Florianópolis (4.121; 7,77%), Blumenau (2.917; 9,32%), Itajaí (2.455; 7,94%), Chapecó (2.419; 9,38%).
  * Entre os com `n ≥ 100`, maiores taxas: Sangão (18,1%; 21/116), Lauro Müller (13,9%), Herval d'Oeste (13,4%), Itaiópolis (13,2%), Dionísio Cerqueira (13,1%). Menores: Agrolândia (2,9%; 3/105), Garopaba (3,9%), Rio do Sul (4,85%; 31/639), Santo Amaro da Imperatriz (4,9%), São José do Cedro (5,0%).
* **Leitura:** a taxa agregada por classe **não tem tendência com o tamanho**; o que muda é a **variabilidade** (item 1 do resumo). Isso é o que a teoria binomial prevê.

### B2 — Gráfico de funil com limites binomiais **exatos** (`qbinom`)

* **O que:** pontos (`n_i`, taxa) sobre faixas de 95% e 99,8% de `qbinom(·, n_i, p0)/n_i`.
* **Alternativas:** limites normais aproximados (ruins quando `n·p0` é pequeno, nosso caso).
* **Por que:** a referência é *"todos têm a mesma π = p0"*. Sob ela, ~5% (≤, por discretização) dos pontos ficam fora da faixa de 95% e ~0,2% da de 99,8%. Muito mais que isso ⇒ **diferenças reais**.
* **Risco:** o funil usa taxa **única**; é referência visual, não teste de modelo. O "esperado" de 14,8 é um **teto** (a binomial é discreta, então a taxa real fora é ≤ 5%).
* **Frase para a banca:** *"O funil pergunta: se todo município tivesse o mesmo risco, quanto a taxa oscilaria só por acaso? Pontos fora indicam heterogeneidade além do acaso."*
* **Resultados reais:**

| Faixa | Observado | Esperado sob "todos iguais" |
|---|---|---|
| Fora de 95% | **24** (8,1%) | ≤ ≈ 14,8 (5%) |
| Fora de 99,8% | **2** | ≈ 0,6 |

| Classe | Fora de 95% | % da classe |
|---|---|---|
| `< 30` | 4/80 | 5,0% |
| 30–99 | 4/105 | 3,8% |
| 100–499 | 9/82 | 11,0% |
| `>= 500` | 7/28 | **25,0%** |

* **Leitura (importante):**
  * Os dois pontos vermelhos (fora de 99,8%) são um município ≈ 116 nascimentos **acima** (provavelmente Sangão, 18,1%) e um ≈ 640 **abaixo** (provavelmente Rio do Sul, 4,85%).
  * "Só 2 pontos fora de 99,8%" **não** significa "tudo é acaso": por si só 2 vs 0,6 não é chocante (cerca de 12% de chance sob Poisson), mas o conjunto de evidências é forte: 24 fora de 95% é um excesso de cerca de 2,3 desvios (p ≈ 1%, e essa conta é conservadora), e **7 de 28** grandes fora (probabilidade < 0,1% sob acaso puro).
  * O excesso aparece **onde o teste tem poder** (grandes). Nos pequenos o ruído binomial esconde a heterogeneidade, por isso ali a proporção fora é ≈ 5% ou menos.
  * **Quem está fora de 95% (24 municípios; 18 acima e 6 abaixo de 8,22%):**
    * `>= 500` (7): Joinville (4.978; 7,29%, abaixo), Blumenau (9,32%), Chapecó (9,38%), Balneário Camboriú (977; 6,24%, abaixo), Concórdia (10,7%), Caçador (11,5%), Rio do Sul (639; 4,85%, abaixo).
    * 100–499 (9): Imbituba (12,2%), Campos Novos (11,9%), Garopaba (3,9%, abaixo), Joaçaba (12,2%), São Joaquim (12,5%), Herval d'Oeste (13,4%), Itaiópolis (13,2%), Sangão (18,1%), Agrolândia (2,9%, abaixo).
    * 30–99 (4): Monte Carlo (16,1%), Paulo Lopes (1/69; 1,4%, abaixo), Riqueza (19,5%), Jaborá (25,0%).
    * `< 30` (4): Braço do Trombudo (7/28), Marema (5/14), Presidente Nereu (4/13), Painel (4/9; 44,4%).
  * **Leitura:** o excesso é **assimétrico** (18 acima × 6 abaixo): há municípios com risco sistematicamente **maior**, e vários deles (Concórdia, Caçador, Joaçaba, Campos Novos, São Joaquim, Herval d'Oeste) ficam na mesma região do estado. É uma **hipótese de agrupamento espacial**, não um resultado; verificar com Moran nos resíduos (Etapa D). Os 4 municípios `< 30` fora do funil (Painel, Marema, Presidente Nereu, Braço do Trombudo) serão **candidatos a alta influência** na Etapa D; **não** serão excluídos por serem atípicos.
* **Prévia de dispersão (φ do modelo nulo):** `X²_nulo = 455,99`, `gl = 294`, **φ = 1,551**. Mesmo com a ressalva do alerta A4 (aproximação χ² ruim com contagens pequenas), a distância é grande (≈ 6–7 desvios de um χ²₂₉₄). **Cuidado:** é o φ **sem preditores**; depois deles tende a cair. O diagnóstico oficial é na Etapa C/D.

### B3 — Descrever preditores: resumo, zeros, assimetria e ruído por tamanho

* **O que:** tabela resumo, histogramas, médias/DP por classe de tamanho.
* **Por que:** (i) `prop_gestacao_mult` tem muitos zeros e é assimétrica (alerta A3); (ii) o DP dos preditores é maior nos pequenos, só por ruído amostral (**erro de medida**, tende a atenuar coeficientes).
* **Risco:** confundir "variar mais nos pequenos" com "pequenos são diferentes".
* **Frase para a banca:** *"As proporções dos municípios pequenos são estimativas ruidosas; por isso fazemos sensibilidade sem municípios com menos de 30 nascimentos."*
* **Resultados reais:**

| Preditor | Média | Mediana | DP | Máx | Zeros | % zeros | Assimetria |
|---|---|---|---|---|---|---|---|
| `prop_adolescente` | 0,0814 | 0,0769 | 0,0492 | 0,333 | 27 | 9,2 | 1,01 |
| `prop_esc_baixa` | 0,0596 | 0,0545 | 0,0474 | 0,308 | 46 | 15,6 | 1,33 |
| `prop_prenatal_insuf` | 0,0781 | 0,0761 | 0,0510 | 0,267 | 33 | 11,2 | 0,64 |
| `prop_gestacao_mult` | 0,0241 | 0,0158 | 0,0326 | 0,174 | **124** | **42,0** | **2,00** |
| `prop_mae_35mais` | 0,185 | 0,182 | 0,0702 | 0,471 | 3 | 1,0 | 0,33 |

  * Ruído por tamanho (`prop_adolescente`): DP = 0,0686 (`< 30`) → 0,0486 (30–99) → 0,0312 (100–499) → 0,0195 (`>= 500`). Médias: 0,0775 · 0,0823 · 0,0870 · 0,0725. Demais preditores por classe (`< 30` → `>= 500`):

| Preditor | Médias | DPs |
|---|---|---|
| `prop_esc_baixa` | 0,058 · 0,0622 · 0,0604 · 0,0517 | 0,0710 · 0,0415 · 0,0294 · 0,0193 |
| `prop_prenatal_insuf` | 0,0675 · 0,0796 · 0,0824 · 0,0903 | 0,0687 · 0,0493 · 0,0357 · 0,0279 |
| `prop_gestacao_mult` | 0,0284 · 0,0201 · 0,0249 · 0,0239 | 0,0497 · 0,0294 · 0,0166 · **0,0060** |
| `prop_mae_35mais` | 0,182 · 0,180 · 0,188 · 0,204 | 0,0975 · 0,0692 · 0,0437 · 0,0348 |

  Todos os DPs caem com o tamanho (o de `prop_gestacao_mult` cai ≈ 8 vezes, por ser evento raro). As **médias** de `prop_prenatal_insuf` (6,8% → 9,0%) e `prop_mae_35mais` (18,2% → 20,4%) **sobem** com o tamanho: municípios maiores diferem em perfil, o que reforça manter a sensibilidade sem os pequenos.
* **Leitura:** quase metade dos municípios (42%) não tem gestação múltipla registrada em 2026, o que é efeito de município pequeno + evento raro (2,4%). A variável é contínua, mas com **massa em zero**: relevante para influência (Etapa D).

### B4 — Contagens esperadas (prova do alerta A4)

* **Por que:** os slides exigem `mπ ≥ 3` e `m(1−π) ≥ 3` para usar o χ² da deviance.
* **Frase para a banca:** *"Com taxa de 8% e municípios com poucas dezenas de nascimentos, o esperado de baixo peso é frequentemente menor que 3; então a aproximação χ² da deviance não vale e avaliamos o ajuste por simulação e resíduos quantílicos."*
* **Resultados reais:** `n_i·p0 < 3` em **94 municípios (31,9%)**; `< 5` em **138 (46,8%)**; `n_i(1−p0) < 3` em 0.
* **Conclusão:** **não** usaremos o p-valor χ² da deviance como teste de qualidade do ajuste.

### B5 — Relação preditor × resposta no logito empírico

* **O que:** dispersão (`x`, logito empírico), tamanho do ponto ∝ `n_i`, reta e loess ponderados (`span = 0,9`).
* **Por que:** o modelo é linear no logito; se loess e reta divergem sistematicamente, a forma funcional pode estar errada.
* **Risco:** o logito empírico de município pequeno é ruidoso; o loess **nas caudas** é sustentado por poucos pontos pequenos.
* **Frase para a banca:** *"Olhamos linearidade na escala em que o modelo é linear, o logito, e ponderamos por n_i porque municípios grandes carregam mais informação."*
* **Resultados reais (da figura `B_preditor_x_logito.png`):**

| Preditor | Direção | Reta × loess | Comentário |
|---|---|---|---|
| `prop_adolescente` | levemente positiva | loess plano e cai no fim da escala | cauda (> 25%) com poucos pontos pequenos |
| `prop_esc_baixa` | fraca | loess **sobe forte** acima de ≈ 20% | upturn sustentado por poucos municípios pequenos |
| `prop_prenatal_insuf` | quase nula | **acompanham-se** | sem sinal de curvatura |
| `prop_gestacao_mult` | **positiva nítida** | loess sobe e **estabiliza** acima de ≈ 10% | cauda esparsa (máx. 17%); ainda assim a tendência é clara |
| `prop_mae_35mais` | levemente negativa | loess mais alto nos valores baixos | faixa baixa com poucos pontos |

* **Verificação com `n ≥ 30` (figura `B_preditor_x_logito_n30.png`, 215 municípios):**
  * `prop_adolescente`, `prop_gestacao_mult` e `prop_prenatal_insuf`: reta e loess **praticamente coincidem**. A relação de `prop_gestacao_mult` é nitidamente linear no logito.
  * `prop_esc_baixa`: reta quase plana; o loess só se afasta levemente na cauda esquerda (< 2%). O *upturn* acima de 20% **desapareceu** (era dos pequenos).
  * `prop_mae_35mais`: o loess ainda fica mais alto abaixo de ≈ 10%, onde há só poucos pontos pequenos; no restante coincide com a reta.
  * **Cuidado:** removendo os pequenos também some a cauda do preditor (ex.: `prop_gestacao_mult` vai só até ≈ 12%). A linearidade vale **dentro desse suporte**; a dispersão vertical dos pontos continua grande (é a heterogeneidade do funil, não um problema de forma funcional).
* **Decisão (B9, abaixo):** não incluir termos não lineares; checar apenas por teste/resíduos parciais.

### B6 — Taxa agregada por faixas, com IC de Wilson (só exploratório)

* **O que:** quintis (zeros em grupo próprio se ≥ 10% dos municípios) e taxa agregada `ΣY/ΣN`.
* **Atenção:** o enunciado proíbe quartis **para modelar**; aqui é só visualização. O modelo usa preditores contínuos.
* **Frase para a banca:** *"As faixas são só um recurso gráfico; o modelo usa os preditores contínuos e a resposta binomial agrupada."*
* **Resultados reais (taxa agregada por faixa, do menor para o maior valor do preditor):**

| Preditor | Taxas das faixas | Leitura |
|---|---|---|
| `prop_adolescente` | 7,84 · 7,79 · 8,59 · 8,23 · **9,68%** | plano e **só a última faixa** sobe (IC 8,84–10,6, exclui 8,22) |
| `prop_esc_baixa` | 7,96 (zeros) · 8,04 · 8,23 · 8,18 · **9,47%** | plano e só a última sobe (IC 8,62–10,4) |
| `prop_prenatal_insuf` | 6,94 (zeros) · 8,25 · 7,84 · 8,28 · **8,77%** | quase plano; IC da última exclui 8,22 por pouco |
| `prop_gestacao_mult` | **6,71 (zeros)** · 7,73 · 8,12 · 9,12 · **11,5%** | **monotônica** e ≈ regular no logito; extremos excluem 8,22 |
| `prop_mae_35mais` | 8,65 · 9,04 · 7,73 · 8,41 · 7,98% | **não monotônica**, efeito fraco |

* **Leitura:** `prop_gestacao_mult` é a associação marginal mais clara (de 6,7% nos municípios sem gestação múltipla até 11,5% na faixa mais alta). Em `prop_adolescente` e `prop_esc_baixa`, a associação só aparece na faixa mais extrema (consistente com a divergência reta × loess da B5). Um IC que exclui 8,22% descreve a faixa; **não é teste de associação** (p0 vem dos mesmos dados e as faixas são exploratórias).

### B7 — Correlações

* **Resultados reais (descritivos, não são testes):**

| Preditor | Pearson (taxa, simples) | Spearman | Ponderada (taxa) | Ponderada (taxa), `n ≥ 30` | Ponderada (logito), `n ≥ 30` |
|---|---|---|---|---|---|
| `prop_adolescente` | 0,034 | 0,082 | 0,158 | **0,220** | 0,206 |
| `prop_esc_baixa` | **0,248** | 0,088 | 0,102 | **0,048** | 0,026 |
| `prop_prenatal_insuf` | 0,086 | 0,116 | 0,083 | 0,091 | 0,090 |
| `prop_gestacao_mult` | 0,441 | 0,472 | 0,430 | 0,409 | 0,397 |
| `prop_mae_35mais` | −0,135 | −0,057 | −0,107 | −0,129 | −0,126 |

  Coluna que faltava, ponderada no logito empírico com todos os municípios: adolescente **0,153** · esc_baixa **0,059** · prenatal 0,082 · gestação múltipla **0,412** · mães 35+ −0,110. (Com `n ≥ 30`: 0,206 · 0,026 · 0,090 · 0,397 · −0,126.) Mesma conclusão: `prop_esc_baixa` enfraquece e `prop_adolescente` fortalece quando os pequenos saem.
* **Leitura:**
  * `prop_gestacao_mult`: ≈ 0,4–0,47 em **qualquer** versão ⇒ associação **robusta** aos municípios pequenos.
  * `prop_esc_baixa`: Pearson simples (0,248) muito maior que Spearman (0,088), ponderada (0,102) e `n ≥ 30` (0,048) ⇒ a correlação simples é puxada por **poucos municípios pequenos com valores extremos** (alavancagem). Associação **frágil**.
  * `prop_adolescente`: **aumenta** (0,034 → 0,158 → 0,22) quando se dá mais peso aos grandes/remove os pequenos ⇒ coerente com **atenuação por erro de medida** (alerta A3).
  * `prop_prenatal_insuf` e `prop_mae_35mais`: fracas e estáveis.
* **Entre preditores:** maior |Pearson| = **0,19** (`prop_adolescente` × `prop_mae_35mais`, −0,19); Spearman máx. = 0,23 (mesmo par). Sem sinal de multicolinearidade.
* **Frase para a banca:** *"As correlações são descritivas e marginais; o efeito de cada preditor controlando pelos demais só é avaliado no modelo."*

### B8 — O que **não** fazemos nesta etapa

| Não fazemos | Motivo |
|---|---|
| Ajustar `glm` | Etapa C |
| Testes de hipótese | Nada de "significativo" na exploratória |
| Excluir municípios | Orientações: manter zeros e não excluir por serem atípicos; sensibilidade na C |
| Categorizar preditores para o modelo | Orientação: preferir contínuos |
| Usar a taxa como resposta | Orientação do tema; perderíamos `n_i` |

### B9 — Decisão (nova): manter os 5 preditores contínuos e **não** incluir termos não lineares agora

* **O que:** levar os 5 candidatos para a Etapa C **como estão**; testar não linearidade (termo quadrático) **apenas** onde há indício e justificativa, via TRV.
* **Alternativas:** (a) incluir quadráticos já; (b) transformar (log, raiz) `prop_gestacao_mult`; (c) categorizar.
* **Por que:** as divergências reta × loess estão em caudas esparsas e ruidosas; decidir por olho em exploratória é arriscado (superajuste). As orientações pedem justificar transformações. **Confirmado pela figura com `n ≥ 30`:** as curvaturas vinham dos municípios pequenos. Todos os preditores entram **lineares**; um termo quadrático só será testado (TRV) como checagem de robustez em `prop_esc_baixa` e `prop_mae_35mais`, sem expectativa de mantê-lo.
* **Risco:** perder uma curvatura real. Mitigação: resíduos parciais e gráfico de resíduos × preditor (Etapa D), e sensibilidade com `n ≥ 30`.
* **Frase para a banca:** *"Os desvios da linearidade apareceram nas caudas, onde há poucos municípios pequenos. Preferimos testar formalmente a curvatura na modelagem a introduzir termos por inspeção visual."*

---

## 4. O que a Etapa B alimenta na Etapa C

| Achado da B | Consequência na C |
|---|---|
| φ nulo = 1,55; 24 fora de 95%, 7/28 grandes fora | Esperar superdispersão; **quasi-binomial** e/ou **beta-binomial** são candidatos reais |
| `n_i·p0 < 3` em 31,9% (e `< 5` em 46,8%) | Não usar χ² da deviance; usar Pearson, resíduos quantílicos, envelope simulado/simulação |
| `prop_gestacao_mult` com efeito marginal claro (≈ 0,4 de correlação) | Provável preditor dominante; 42% de zeros → vigiar influência |
| `prop_esc_baixa` sensível a municípios pequenos; `prop_adolescente` cresce com `n ≥ 30` | Sensibilidade (d) é **essencial**; reportar os dois cenários |
| Reta × loess coincidem com `n ≥ 30` | Preditores lineares no logito; quadrático só como checagem de robustez |
| 18 de 24 fora do funil estão acima; agrupamento regional aparente | Moran nos resíduos (Etapa D): prioridade média |
| `n_i·p0 < 3` e municípios minúsculos fora do funil (Painel, Marema, Presidente Nereu, Braço do Trombudo) | Vigiar influência (Cook/alavancagem); reportar sem excluir |
| `prop_prenatal_insuf` e `prop_mae_35mais` fracas | Podem sair na seleção; "nem todos precisam estar no modelo final" |
| Correlações entre preditores ≤ 0,19 | Multicolinearidade improvável (VIF na D só para confirmar) |

**Atenção às hipóteses do plano:** gestação múltipla com efeito positivo tem apoio marginal claro; adolescentes e pré-natal insuficiente têm apoio **fraco** (e o de adolescentes só aparece sem municípios pequenos). O modelo ajustado decide.

---

## 5. Pendências resolvidas e correção de código

* Todas as colunas que o PDF cortou foram preenchidas (Seções 3/B1, B3 e B7).
* **Erro de script encontrado e corrigido:** em `tab_classe`, a linha `baixo_peso = sum(baixo_peso)` **sobrescrevia** a coluna dentro do `summarise`, então `municipios_taxa0 = sum(baixo_peso == 0)` contava sobre o valor já somado e saiu 0 em todas as classes (incompatível com os 24 municípios sem casos da Etapa A e com `taxa_min = 0`). No `03_exploratoria.R` entregue agora a coluna se chama `casos_baixo_peso` e `municipios_taxa0` está certa. Lição: em `summarise`, **não reutilizar o nome de uma coluna de entrada** para um resultado que será usado depois.
* Para obter a contagem correta sem rodar tudo: `b %>% group_by(classe_n) %>% summarise(sem_casos = sum(baixo_peso == 0))` (deve somar 24).
* `B_pares_preditores.png` não foi inspecionada visualmente; as correlações numéricas (máx. |r| = 0,19) já cobrem a pergunta.

---

## 6. Perguntas que a banca pode fazer (e respostas curtas)

1. **"Por que não usar a taxa como resposta?"** Porque a taxa de um município com 8 nascimentos e a de um com 4.978 têm precisões muito diferentes. A binomial agrupada usa `n_i`.
2. **"O que é o funil?"** Referência do que o acaso binomial faria se todos tivessem o mesmo risco. Encontramos 24 municípios fora de 95% (esperado ≤ 15), e 7 dos 28 maiores.
3. **"Isso significa superdispersão?"** Sinaliza heterogeneidade: φ do modelo nulo = 1,55. O diagnóstico oficial é feito no modelo final, com Pearson e resíduos quantílicos.
4. **"Por que logito empírico com 0,5?"** Para evitar `log(0)` nos 24 municípios sem casos; só visualização.
5. **"Você usou quintis? O enunciado proíbe."** Só no gráfico exploratório; o modelo usa preditores contínuos.
6. **"Por que ponderar por `n_i`?"** Grandes têm estimativas mais precisas; sem ponderar, os pequenos dominam.
7. **"Já dá para dizer que X afeta o baixo peso?"** Não. É exploração marginal. Associação ajustada, ICs e testes vêm no modelo, e sempre como associação entre municípios, sem causalidade nem extrapolação para indivíduos.
8. **"Por que o efeito de adolescentes parece maior sem os municípios pequenos?"** Porque as proporções dos pequenos são ruidosas (erro de medida), o que atenua a associação.

---

## 7. Registro de decisões (colar na Seção 8 do `plano_geral.md`)

| Data | Decisão | Quem |
|---|---|---|
| 02/11/2026 | B1–B8 executadas conforme o plano | autor |
| 02/11/2026 | Evidência de heterogeneidade além do acaso (funil: 24 fora de 95%; 7/28 grandes) e φ nulo = 1,55 → quasi-binomial/beta-binomial como candidatos na C | autor |
| 02/11/2026 | B9: manter os 5 preditores contínuos e lineares no logito; quadrático só como checagem de robustez | autor (após figura `n ≥ 30`) |
| 02/11/2026 | Sensibilidade `n ≥ 30` promovida a análise essencial (esc_baixa e adolescente sensíveis) | autor |
| 02/11/2026 | Moran nos resíduos: sugerido fazer (18/24 fora do funil acima; agrupamento regional aparente) | a decidir na Etapa D |
| 02/11/2026 | Etapa B concluída; próxima: Etapa C | autor |
