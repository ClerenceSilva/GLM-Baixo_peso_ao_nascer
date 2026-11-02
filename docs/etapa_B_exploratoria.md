# Etapa B — Análise exploratória (Tema 8, baixo peso ao nascer em SC, SINASC 2026)

Script: `scripts/03_exploratoria.R` · Status: **script entregue; aguardando execução no R** · Campos `[PREENCHER]` = números reais que vêm das saídas do R (nada aqui foi inventado).

---

## 0. Para que serve esta etapa

As orientações pedem, no item (b): *"descrever a resposta e explorar suas relações com os principais preditores, utilizando tabelas e gráficos pertinentes"*. Na nossa estratégia, a Etapa B responde **quatro perguntas** que preparam a modelagem (Etapa C) **sem ajustar nenhum modelo**:

1. **Como é a resposta?** A taxa de baixo peso varia entre municípios? Quanto disso é só ruído por municípios pequenos?
2. **Como são os preditores?** Distribuição, zeros, assimetria, ruído.
3. **Cada preditor parece se relacionar com o baixo peso?** E essa relação parece **linear no logito** (a forma que a regressão logística assume)?
4. **Os preditores se misturam entre si?** (prévia de multicolinearidade)

> **Regra de ouro da etapa:** explorar para *entender e planejar*, não para *concluir*. Nenhum p-valor, nenhuma seleção de variável aqui. Isso fica para as Etapas C–E.

**Entradas:** `data/processed/base_municipal_sc2026.rds` (295 municípios, validada contra o TABNET).
**Saídas:** `output/figuras/B_*.png`, `output/tabelas/B_*.csv`, `data/processed/base_municipal_sc2026_exploratoria.rds`.

---

## 1. Conceitos que você precisa dominar (leia antes das decisões)

| Conceito | Explicação em uma frase | Por que importa aqui |
|---|---|---|
| **Binomial agrupada** | Em cada município, `Y_i` = nº de nascidos com baixo peso entre `n_i` nascidos; `Y_i ~ Binomial(n_i, π_i)`. | A resposta do modelo é o **par (sucessos, insucessos)**, não a taxa. |
| **Variância binomial** | `Var(Y_i/n_i) = π(1−π)/n_i`: cai com `n_i`. | Município pequeno tem taxa muito instável **só por acaso**. É o coração da Etapa B. |
| **Funil (funnel plot)** | Taxa × `n_i`, com faixas do que o acaso binomial permitiria se todos os municípios tivessem a mesma probabilidade. | Separa "diferença real" de "ruído de município pequeno". |
| **Logito empírico** | `log((y+0,5)/(n−y+0,5))`. O 0,5 evita `log(0)` quando um município tem 0 casos (são 24). | A regressão logística é **linear no logito**; então é nele que olhamos linearidade. |
| **Correlação ponderada** | Correlação em que cada município pesa `n_i`. | Município com 8 nascimentos não deve pesar igual a Florianópolis. |
| **IC de Wilson** | Intervalo para proporção que funciona bem com `n` pequeno ou taxa perto de 0/1. | Usado nas taxas por faixa de preditor. |
| **Dispersão (φ)** | Razão entre a variância observada e a binomial. φ≈1: só acaso; φ>1: há diferença real entre municípios além do acaso (**superdispersão**). | Antecipa se na Etapa C precisaremos de quasi-binomial/beta-binomial. |

---

## 2. Decisões da Etapa B

Formato de cada decisão: **o que · alternativas · por que · risco · frase para a banca**.

### B1 — Descrever a resposta pela taxa, mas **deixar claro que a taxa é só descrição**

* **O que:** histograma da taxa municipal, tabela por classe de tamanho (`< 30`, `30-99`, `100-499`, `>= 500`), histograma de `n_i`.
* **Alternativas:** (a) só mostrar a taxa global; (b) descrever só municípios grandes.
* **Por que:** precisamos mostrar a **heterogeneidade de tamanho** (mediana 67 nascimentos; 80 municípios com < 30; 24 sem nenhum caso). A tabela por classe mostra que o desvio-padrão da taxa é muito maior nos pequenos — evidência direta de que a taxa crua engana.
* **Risco:** alguém interpretar o histograma da taxa como "distribuição do risco". Não é: parte da dispersão é ruído amostral.
* **Frase para a banca:** *"A taxa municipal aparece só para descrever. A resposta do modelo é o par sucessos/insucessos, justamente porque o tamanho de cada município determina a precisão da sua taxa."*
* **Resultados:** taxa municipal — mín/mediana/máx: `[PREENCHER]`; DP da taxa por classe de tamanho: `[PREENCHER]` (tabela `B_tabela_classe_tamanho.csv`); taxa agregada por classe: `[PREENCHER]`.

### B2 — Gráfico de funil com limites binomiais **exatos** (`qbinom`)

* **O que:** pontos (`n_i`, taxa) sobre faixas de 95% e 99,8% construídas com `qbinom(·, n_i, p0)/n_i`, onde `p0 = 5302/64469 = 8,22%` é a taxa global.
* **Alternativas:** limites aproximados pela normal (`p0 ± 1,96·√(p0(1−p0)/n)`). Funcionam mal quando `n·p0` é pequeno, que é o nosso caso.
* **Por que:** a hipótese de referência é *"todos os municípios têm a mesma π = p0"*. Sob ela, a quantidade de pontos fora das faixas é previsível (~5% fora da de 95%; ~0,2% fora da de 99,8%). Se **muito mais** do que isso fica fora, existem diferenças reais entre municípios ⇒ há algo para os preditores explicarem (e/ou superdispersão).
* **Risco:** o funil usa uma taxa **única**, então não é um teste de modelo; é uma referência visual. Como a binomial é discreta, a fração fora de 95% fica ≤ 5%.
* **Frase para a banca:** *"O funil responde: se todo município tivesse o mesmo risco, quanto a taxa oscilaria só por acaso? Os pontos fora das faixas indicam heterogeneidade além do acaso."*
* **Resultados:** fora de 95%: `[PREENCHER]` (esperado ≈ 15 se fosse só acaso); fora de 99,8%: `[PREENCHER]` (esperado ≈ 0,6); distribuição por classe de tamanho: `[PREENCHER]`.

**Prévia de dispersão (φ do modelo nulo):** `X²_nulo / (295 − 1)` = `[PREENCHER]`. Interpretação: ≈1 ⇒ pouco além do acaso; ≫1 ⇒ heterogeneidade. **Cuidado:** é o φ do modelo *sem preditores*; depois de incluí-los tende a cair. **O diagnóstico oficial de dispersão é na Etapa C/D.**

### B3 — Descrever preditores: resumo, zeros e assimetria

* **O que:** tabela com média, mediana, DP, mín, máx, nº e % de zeros e assimetria (coef. de 3º momento padronizado); histogramas; e médias/DP dos preditores **por classe de tamanho** do município.
* **Alternativas:** só `summary()`.
* **Por que:**
  * `prop_gestacao_mult` tem 1º quartil = 0 e é assimétrica (alerta A3): se poucos municípios sustentam o efeito, a estimativa é frágil.
  * A tabela por classe de tamanho mostra que o **DP dos preditores é maior nos municípios pequenos** (ruído amostral da própria proporção). Isso é o alerta de **erro de medida** (A3): o preditor do município pequeno é uma estimativa ruidosa da "verdadeira" proporção, o que tende a **atenuar** coeficientes.
* **Risco:** confundir "variar mais nos pequenos" com "pequenos são diferentes". Parte é só ruído; por isso mantemos todos e fazemos a sensibilidade sem municípios `< 30` (Etapa C).
* **Frase para a banca:** *"As proporções dos municípios pequenos são estimativas ruidosas; isso pode enfraquecer associações e é por isso que fazemos sensibilidade sem esses municípios."*
* **Resultados:** `[PREENCHER]` (`B_resumo_preditores.csv`, `B_ruido_preditores_por_tamanho.csv`). Zeros em `prop_gestacao_mult`: `[PREENCHER]` municípios (`[PREENCHER]`%); assimetria: `[PREENCHER]`.

### B4 — Contagens esperadas (prova do alerta A4)

* **O que:** quantos municípios têm `n_i·p0 < 3`, `< 5` e `n_i(1−p0) < 3`.
* **Por que:** os slides (análise de deviance) dizem que o teste qui-quadrado da deviance só é confiável se `mπ ≥ 3` e `m(1−π) ≥ 3`. Aqui mostramos **com números** que isso falha em muitos municípios, justificando por que **não usaremos o p-valor χ² da deviance** como teste de qualidade do ajuste, e sim dispersão de Pearson, resíduos quantílicos/envelope simulado ou simulação.
* **Risco:** nenhum relevante; é uma checagem objetiva.
* **Frase para a banca:** *"Com taxa de 8% e municípios com poucas dezenas de nascimentos, o esperado de baixo peso é frequentemente menor que 3; então a aproximação qui-quadrado da deviance não vale, e avaliamos o ajuste por simulação e resíduos quantílicos."*
* **Resultados:** `n_i·p0 < 3` em `[PREENCHER]` municípios (`[PREENCHER]`%); `< 5` em `[PREENCHER]`.

### B5 — Olhar a relação preditor × resposta **na escala do logito empírico**

* **O que:** para cada preditor, dispersão (`x`, logito empírico) com tamanho do ponto ∝ `n_i`, reta ponderada (azul) e loess ponderado (vermelho tracejado).
* **Alternativas:** olhar a taxa crua (escala de probabilidade).
* **Por que:** o modelo logístico assume `logito(π_i) = β0 + β1·x1 + …`, ou seja, **linearidade no logito**. Se o loess acompanha a reta, a forma funcional é razoável; se curva claramente, na Etapa C avaliamos termo quadrático/transformação (**só com justificativa**, como exigem as orientações).
* **Risco:** o logito empírico de município pequeno é ruidoso; por isso o **tamanho do ponto** e as **linhas ponderadas** (município grande pesa mais). Curvaturas nos extremos com poucos pontos grandes não são confiáveis.
* **Frase para a banca:** *"Olhamos linearidade na escala em que o modelo é linear, o logito, e ponderamos por n_i porque municípios grandes carregam mais informação."*
* **Resultados (anotar um por preditor — direção e forma):**

| Preditor | Direção aparente | Forma (linear / curva) | Observações |
|---|---|---|---|
| `prop_adolescente` | `[PREENCHER]` | `[PREENCHER]` | `[PREENCHER]` |
| `prop_esc_baixa` | `[PREENCHER]` | `[PREENCHER]` | `[PREENCHER]` |
| `prop_prenatal_insuf` | `[PREENCHER]` | `[PREENCHER]` | `[PREENCHER]` |
| `prop_gestacao_mult` | `[PREENCHER]` | `[PREENCHER]` | `[PREENCHER]` |
| `prop_mae_35mais` | `[PREENCHER]` | `[PREENCHER]` | `[PREENCHER]` |

> Lembrete: as expectativas do plano (gestação múltipla, adolescentes, pré-natal insuficiente com efeito positivo) são **hipóteses**. Se os dados mostrarem outra coisa, descrevemos o que os dados mostram.

### B6 — Taxa **agregada** por faixas do preditor, com IC de Wilson (só exploratório)

* **O que:** cada preditor é dividido em quintis (se ≥ 10% dos municípios têm valor 0, o zero vira um grupo próprio e os positivos são divididos em 4); em cada faixa, calcula-se a taxa agregada `ΣY/ΣN` com IC de Wilson.
* **Por que:** a taxa agregada (soma dos casos / soma dos nascimentos) já pondera naturalmente por `n_i` e dá um gráfico fácil de ler e de mostrar nos slides. Complementa o B5.
* **Atenção — não contradiz a regra do enunciado:** o tema proíbe transformar a resposta em "alto/baixo" por quartis **para modelar**. Aqui as faixas são **apenas visualização**; o modelo usa a resposta (`cbind`) e os preditores **contínuos**, como as orientações pedem.
* **Risco:** a escolha das faixas altera o visual; por isso o B5 (sem faixas) é a evidência principal e o B6 é apoio.
* **Frase para a banca:** *"As faixas são só um recurso gráfico; o modelo usa os preditores contínuos e a resposta binomial agrupada."*
* **Resultados:** `[PREENCHER]` (`B_taxa_por_faixas_preditor.csv`, figura `B_preditor_x_taxa_faixas.png`).

### B7 — Correlações: preditores × resposta e preditores entre si

* **Preditores × resposta (descritivo, não é teste):** Pearson simples, Spearman, **ponderada por `n_i`** (taxa e logito empírico) e a ponderada restrita a `n_i ≥ 30`. Comparar as versões mostra se o sinal/magnitude **dependem dos municípios pequenos**.
* **Entre preditores:** Pearson, Spearman e matriz de dispersão. Na Etapa A a maior |correlação| foi 0,19; aqui confirmamos (e vemos se há não linearidade escondida pelo Spearman).
* **Por que:** antecipa multicolinearidade (a checagem formal, VIF, é na Etapa D).
* **Risco:** correlação marginal ≠ efeito ajustado. Um preditor pode parecer fraco sozinho e importante no modelo (ou vice-versa).
* **Frase para a banca:** *"As correlações são descritivas e marginais; o efeito de cada preditor controlando pelos demais só é avaliado no modelo."*
* **Resultados:** correlações com a resposta: `[PREENCHER]`; maior |correlação| entre preditores: `[PREENCHER]` (referência da Etapa A: 0,19).

### B8 — O que **NÃO** fazemos nesta etapa (e por quê)

| Não fazemos | Motivo |
|---|---|
| Ajustar `glm` (nem simples) | A modelagem é a Etapa C; aqui evitamos escolher variáveis olhando p-valores. |
| Testes de hipótese | Nada de "significativo" na exploratória. |
| Excluir municípios (pequenos ou extremos) | As orientações pedem manter zeros e proíbem excluir só por serem atípicos; sensibilidade fica para a Etapa C. |
| Categorizar preditores para o modelo | Orientação: preferir preditores contínuos. |
| Usar a taxa como resposta | Orientação do tema 8 (e perderíamos a informação de `n_i`). |

---

## 3. Como ler as saídas (guia rápido)

1. **Tabela por classe de tamanho:** o DP da taxa deve cair bastante de `< 30` para `>= 500`. Se sim, o ruído binomial é o principal motivo da dispersão visual.
2. **Funil:** pontos pequenos espalhados *dentro* das faixas = esperado. Pontos grandes *fora* das faixas = diferença real entre municípios.
3. **φ do modelo nulo:** ≈ 1 (pouca heterogeneidade) ou ≫ 1 (muita). É prévia, não veredito.
4. **Gráfico do logito:** a reta azul e o loess vermelho andam juntos? Então linearidade OK. Curva forte e sustentada por pontos grandes ⇒ considerar termo não linear na Etapa C.
5. **Faixas com IC:** o IC das faixas extremas exclui a linha de 8,22%? Indica associação marginal.
6. **Correlações com n ≥ 30 vs. todos:** se o sinal muda ou a magnitude muda muito, os municípios pequenos pesam na impressão.

---

## 4. O que a Etapa B alimenta na Etapa C

| Achado da B | Consequência na C |
|---|---|
| Ruído por tamanho / φ nulo | Planejar quasi-binomial e/ou beta-binomial; checar dispersão do modelo final por Pearson |
| `n_i·p0 < 3` em muitos municípios | Não usar χ² da deviance; usar simulação/resíduos quantílicos |
| Curvatura no logito (se houver) | Testar termo quadrático **com justificativa** |
| Assimetria/zeros de `prop_gestacao_mult` | Sensibilidade sem municípios que sustentam o efeito; cuidado com alavancagem (Etapa D) |
| Sinal muda com `n ≥ 30` | Reforça sensibilidade (d) |
| Correlações entre preditores | Confirmar ausência de colinearidade (VIF na D) |

---

## 5. Checklist de entrega e pendências

- [ ] Rodar `03_exploratoria.R` e colar no chat **todas as saídas impressas** (principalmente: `p0`, `tab_classe`, contagem de pontos fora do funil, `phi_nulo`, `tab_esp`, `tab_pred`, `tab_ruido`, `b_bins`, `tab_cor_resp`, `tab_cor_resp30`, matrizes de correlação).
- [ ] Olhar e descrever as figuras (ou enviá-las): `B_funil.png`, `B_preditor_x_logito.png`, `B_preditor_x_taxa_faixas.png`, `B_hist_preditores.png`, `B_pares_preditores.png`.
- [ ] Eu preencho os `[PREENCHER]`, confiro os números e atualizo o `plano_geral.md` (Seção 8: registro de decisões).
- [ ] Só então avançamos para a Etapa C.

**Pacote novo nesta etapa:** `tidyr` e `ggplot2` (além de `dplyr` e `tibble`). Instalar se faltar: `install.packages(c("tidyr","ggplot2"))`.

**Possíveis avisos no R (normais):** o `loess` ponderado pode emitir avisos de pontos próximos/singularidades em preditores com muitos zeros; se aparecer, avise e eu ajusto o `span`.

---

## 6. Perguntas que a banca pode fazer nesta etapa (e respostas curtas)

1. **"Por que não usar a taxa como resposta?"** Porque a taxa de um município com 8 nascimentos e a de um com 4.978 têm precisões muito diferentes. A binomial agrupada usa `n_i` e dá a cada município o peso certo.
2. **"O que é o funil?"** Uma referência do que o acaso binomial faria se todos os municípios tivessem o mesmo risco. Pontos fora das faixas indicam diferenças reais.
3. **"Por que logito empírico com 0,5?"** Para evitar `log(0)` nos 24 municípios sem casos, apenas para visualização.
4. **"Você usou quintis? O enunciado proíbe."** Só no gráfico exploratório; o modelo usa a resposta binomial e preditores contínuos.
5. **"Por que ponderar por `n_i`?"** Municípios grandes têm estimativas mais precisas; ponderar evita que os pequenos dominem a impressão.
6. **"Já dá para dizer que X afeta o baixo peso?"** Não. Isto é exploração marginal; associação ajustada, intervalos e testes vêm no modelo, e sempre como associação entre municípios, sem causalidade nem extrapolação para indivíduos.

---

## 7. Registro de decisões desta etapa (para o `plano_geral.md`)

| Decisão | Resumo |
|---|---|
| B1 | Taxa só como descrição; resposta do modelo é `cbind(baixo_peso, demais)` |
| B2 | Funil com limites binomiais exatos em torno de p0 = 8,22% |
| B3 | Preditores: resumo, zeros, assimetria, e ruído por classe de tamanho |
| B4 | Contagens esperadas para justificar o abandono do χ² da deviance |
| B5 | Linearidade avaliada no logito empírico, pontos e linhas ponderados por `n_i` |
| B6 | Faixas (quintis) só para visualização, com IC de Wilson |
| B7 | Correlações descritivas (ponderadas e com `n ≥ 30`) |
| B8 | Sem modelos, testes ou exclusões na exploratória |
