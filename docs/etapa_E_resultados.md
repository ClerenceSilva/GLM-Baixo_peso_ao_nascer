# Etapa E — Resultados (Tema 8, baixo peso ao nascer em SC, SINASC 2026)

Script: `scripts/06_resultados.R` · Status: **executada em 13/11/2026; saídas e figuras conferidas; pendências resolvidas (IC de ρ e D7). Resta só o ajuste cosmético dos rótulos do forest (E6). Etapa E CONCLUÍDA.**

---

## 0. Para que serve esta etapa

Orientações, item (e): estimativas, ICs, testes, interpretação na escala adequada e **pelo menos um gráfico de probabilidades com IC**. Modelo apresentado (M0): `Y_i ~ BetaBinomial(n_i, π_i, ρ)`, `logit(π_i) = β0 + β1·pre10 + β2·mult10`, com 1 unidade = 10 p.p. Nenhuma variável foi reselecionada e nenhum município excluído.

Saídas: `output/tabelas/E_*.csv`, `output/figuras/E_*.png`, `data/processed/E_resultados.rds`.

---

## 1. Resumo executivo (números reais)

| # | Pergunta | Resposta | Evidência |
|---|---|---|---|
| 1 | Reajuste = Etapa C? | **Sim.** β_mult 0,8055; β_pre 0,1509; φ 968,9; ρ 0,00103; convergiu (pdHess = TRUE) | bloco 1 |
| 2 | `mult10`, OR por +10 p.p. | **2,24** (IC Wald 1,87–2,68; perfil 1,87–2,67); TRV χ² = 68,5, p = 1,3×10⁻¹⁶ | `E_coeficientes.csv` |
| 3 | `pre10`, OR por +10 p.p. | **1,16** (Wald 1,05–1,29; perfil 1,05–1,29); TRV χ² = 8,36, p = 0,0038 | idem |
| 4 | OR por +1 DP | `mult10` **1,30** (1,23–1,38); `pre10` **1,08** (1,03–1,14) | idem |
| 5 | Modelo final vs nulo | χ² = 73,8 (2 gl), p ≈ 9×10⁻¹⁷; AIC 1457,3 → 1387,4 | `E_trv.csv` |
| 6 | Em probabilidade | `mult10`: **+2,2 p.p.** por +1 DP (IC 1,7–2,7); `pre10`: **+0,6 p.p.** (0,2–1,0) | `E_efeitos_probabilidade.csv` |
| 7 | Heterogeneidade (ρ) | 0,00191 (nulo) → 0,00103 (final; IC 0,00046–0,00229): **−46%** | `E_rho.csv` |
| 8 | Robustez | `mult10` robusto (OR 2,14–2,35); `pre10` robusto a atípicos e espaço, **sensível à família** (quasi: 1,09, IC 0,99–1,20, p = 0,066) e à definição | seção 3 (E3) |
| 9 | Calibração | Sem desvio sistemático por decil; esperado total 5.390 vs observado 5.302 (+1,7%) | `E_calibracao_*.csv` |

Intercepto: −2,731 (EP 0,057) → com os dois preditores em 0, π = 6,1%; nas médias (7,8% e 2,4%), π ≈ 8,2%.

---

## 2. Conceitos que você precisa dominar

| Conceito | Explicação em uma frase | Por que importa aqui |
|---|---|---|
| **Razão de chances (OR)** | `exp(β)`: multiplica a chance `π/(1−π)` por +1 unidade (10 p.p.). | Escala natural do logito, mas **não** é razão de probabilidades (E5). |
| **OR por +1 DP** | `exp(β·DP)`, DP entre municípios (0,51 e 0,33 unidades = 5,1 e 3,3 p.p.). | +10 p.p. é grande para `mult10`; o DP é a variação "típica". |
| **IC de Wald × perfil** | Wald: `β ± 1,96·EP`; perfil: valores de β não rejeitados pelo TRV. | Aqui coincidem até a 2ª casa: a aproximação normal é adequada. |
| **TRV por termo** | `2[ℓ(completo) − ℓ(sem o termo)] ~ χ²₁`, reestimando ρ. | Teste do efeito ajustado, coerente com a família escolhida. |
| **IC da probabilidade** | IC em `η = Xβ` e depois `plogis`. | Limites sempre em (0,1). É IC da probabilidade **média**, não intervalo de predição. |
| **Diferença/razão de probabilidades** | `π₁ − π₀` e `π₁/π₀`, IC por 10.000 sorteios `β ~ N(β̂, V̂)`. | Traduz a OR em pontos percentuais; depende do ponto de partida. |
| **ρ** | `Var = nπ(1−π)[1+(n−1)ρ]`; ρ = 1/(1+φ). | Mede heterogeneidade entre municípios além do acaso. |
| **Calibração descritiva** | Taxa observada × esperada por grupos. | Checagem de bom senso; não é teste (alerta A4). |

---

## 3. Decisões e resultados

### E1 — Estimativas e ICs (Wald e perfil; +10 p.p. e +1 DP)

* **Resultado:**

| Termo | β (EP) | z | p Wald | p TRV | OR +10 p.p. (Wald) | OR +10 p.p. (perfil) | OR +1 DP (Wald) |
|---|---|---|---|---|---|---|---|
| `pre10` | 0,151 (0,053) | 2,87 | 0,0041 | 0,0038 | 1,163 (1,049–1,289) | 1,050–1,291 | 1,08 (1,025–1,138) |
| `mult10` | 0,805 (0,091) | 8,82 | 1,2×10⁻¹⁸ | 1,3×10⁻¹⁶ | 2,238 (1,871–2,677) | 1,867–2,672 | 1,30 (1,226–1,378) |

* **Leitura:** Wald e perfil praticamente idênticos (regra de leitura 2: Wald nos slides, perfil no apêndice). Wald e TRV de `pre10` também concordam (0,0041 × 0,0038).
* **Frase para a banca:** *"Reporto a razão de chances por 10 pontos percentuais e por um desvio-padrão entre municípios; o primeiro é interpretável, o segundo é a variação típica. Os intervalos de Wald e de verossimilhança perfilada coincidem."*

### E2 — TRV, ρ e ajuste

* **TRV:**

| Comparação | χ² | gl | p | AIC reduzido → final |
|---|---|---|---|---|
| Final vs nulo | 73,83 | 2 | 9,3×10⁻¹⁷ | 1457,3 → 1387,4 |
| Sem `pre10` | 8,36 | 1 | 0,0038 | 1394 → 1387 |
| Sem `mult10` | 68,50 | 1 | 1,3×10⁻¹⁶ | 1454 → 1387 |

  Retirar `pre10` custa ΔAIC ≈ 7; retirar `mult10`, ≈ 67.
* **Ajuste (descritivo):** log-verossimilhança −726,6 (nulo) → −689,7 (final), ganho 36,9; BIC 1402,2; redução da deviance no binomial: 17,6%.
* **ρ:** 0,00191 (nulo) → 0,00103 (final), **−46%**. A D12 mostrou que região/superfície levam ρ a 0,00033/0,00021; ou seja, sobra pouca heterogeneidade depois de preditores + geografia.
* **IC de ρ (resolvido):** com o trecho corrigido (`summary(bb$sdr, "fixed")`), ρ final = 0,00103, **IC 95% (Wald em log φ) 0,00046–0,00229**. O IC exclui 0 com folga (coerente com o TRV de ρ = 0 da C, p ≈ 5×10⁻⁶) e é assimétrico, como esperado para um parâmetro de dispersão. O nulo não tem IC calculado (só a estimativa, 0,00191); os dois intervalos não foram comparados formalmente, então dizer "reduz cerca de metade" e não "reduz significativamente".
  Trecho usado (para o script): 
  ```r
  ss   <- summary(bb$sdr, "fixed")
  lphi <- ss["betadisp", "Estimate"]; se_l <- ss["betadisp", "Std. Error"]
  rho_ic <- sort(1 / (1 + exp(lphi + c(-Z, Z) * se_l)))
  ```
* **Frase para a banca:** *"Os dois preditores reduzem quase metade da heterogeneidade entre municípios; o restante é em boa parte geográfico, como mostrou a sensibilidade espacial."*

### E3 — Robustez

* **Famílias e subconjuntos (OR por +10 p.p., IC de Wald):**

| Cenário | Família | `mult10` | `pre10` | p (`pre10`) |
|---|---|---|---|---|
| Principal (295) | **Beta-binomial** | 2,24 (1,87–2,68) | **1,16 (1,05–1,29)** | 0,004 |
| Principal | Quasi-binomial | 2,22 (1,83–2,69) | 1,09 (0,99–1,20) | 0,066 |
| Principal | Binomial (EP sem correção) | 2,22 (1,87–2,63) | 1,09 (1,01–1,19) | 0,037 |
| Com `adol10` | Beta-binomial | 2,22 (1,85–2,65) | 1,15 (1,04–1,28) | 0,006 |
| `n ≥ 30` (215) | Beta-binomial | 2,35 (1,86–2,97) | 1,17 (1,04–1,31) | 0,007 |
| `n ≥ 30` | Quasi-binomial | 2,30 (1,79–2,95) | 1,09 (0,98–1,21) | 0,111 |

  `adol10` no modelo com ela: OR 1,12 (0,996–1,256), p = 0,058 (limítrofe; permanece fora do modelo final).
* **Consolidação com as Etapas C e D:**

| Cenário (fonte) | `mult10` | `pre10` |
|---|---|---|
| Jan–jul (C10) | 2,30 | bb 1,16 (p 0,007); quasi 1,10 (p 0,069) |
| Pré-natal < 7 consultas (C10) | 2,21 | bb 1,07 (p 0,050); quasi 1,04 (p 0,24) |
| Atípicos, 6 cenários (D7, bb) | 2,14–2,35 | 1,13–1,24 (todos p < 0,05) |
| Sem os 28 maiores (D7) | 2,22 | 1,24 (p = 0,0001) |
| Espacial: região / lon-lat / superfície (D12) | 2,15 / 2,17 / 2,14 | 1,19 / 1,16 / 1,21 (todas p < 0,01) |

  (Os valores de C10 vêm do `etapa_C_modelagem.md`; o `head()` impresso só mostrou parte do CSV.)
* **Classificação pela regra 1:** `mult10` = **robusto** (OR varia ≈ −4% a +5%, sempre p < 10⁻¹¹). `pre10` = **robusto a atípicos e à geografia, sensível à família** (significância muda de p = 0,004 no bb para 0,066 no quasi) **e à definição** (limiar 7 derruba para 1,04–1,07).
* **Observação:** o IC do binomial sem correção é mais estreito que o do quasi (p = 0,037 × 0,066): ilustra a subestimação dos EP pela superdispersão ignorada.
* **Conferido (D7, cenários 1 e 2):** os resultados idênticos **não são bug**. Pelos CSVs de influentes, os 5 de maior |DFBETAS| são Morro Grande (0,52 em `mult10`), Florianópolis (0,49 em `pre10`), Jaborá (0,33), Sangão (0,27) e Caçador (0,25); os 5 de maior Cook aproximado são Florianópolis (0,113), Morro Grande (0,096), Caçador (0,051), Jaborá (0,045) e Sangão (0,032): **o mesmo conjunto, em ordem diferente**. Nos slides, citar como **um cenário só** ("sem os 5 municípios mais influentes"). O CSV de Cook mostra ainda que Florianópolis tem Cook 0,113 no beta-binomial e 1,66 no binomial (o beta-binomial reduz o peso dos grandes), e que a alavancagem máxima (0,093, Florianópolis; 0,081, Morro Grande) fica bem acima do limiar 2p/n ≈ 0,020 sem que isso mude as OR (maior ΔOR = 0,11 em `mult10`, em Morro Grande).
* **Frase para a banca:** *"Gestação múltipla é estável em todos os cenários. Pré-natal insuficiente resiste a atípicos e à geografia, mas depende da família e da definição; por isso o trato como associação moderada."*

### E4 — Gráficos de probabilidade com IC (exigido)

* **Valores de referência (π, IC 95%):**

| `mult10` (%) | π | IC | `pre10` (%) | π | IC |
|---|---|---|---|---|---|
| 0 | 6,8% | 6,4–7,2 | 0 | 7,3% | 6,7–8,0 |
| 1 | 7,4% | 7,0–7,7 | 4 | 7,8% | 7,3–8,2 |
| 2,4 (média) | 8,2% | 7,9–8,5 | 7,8 (média) | 8,2% | 7,9–8,5 |
| 5 | 9,9% | 9,4–10,4 | 12 | 8,7% | 8,3–9,1 |
| 10 | 14,1% | 12,5–15,8 | 20 | 9,7% | 8,6–10,8 |
| 15 | 19,7% | 16,4–23,5 | 25 | 10,3% | 8,8–12,1 |

* **O que as figuras mostram** (`E_prob_painel.png`, `E_prob_painel_com_dados.png`):
  * `mult10`: curva convexa de 6,8% a ≈ 23% em 17,4 p.p.; a faixa abre acima de 10 p.p. (só **10 municípios**, anotado) — interpretar essa cauda com cautela. No eixo x há uma coluna de municípios em 0% (os 124 sem gestação múltipla).
  * `pre10`: subida suave de 7,3% a ≈ 10,6% em 26,7 p.p., com faixa larga e quase tocando a média na região baixa.
  * Com os dados: pontos (taxa observada, ∝ n) espalham-se muito além da faixa, como esperado (a faixa é IC da probabilidade média; os pontos têm ruído binomial e heterogeneidade). 3 municípios com taxa > 30% ficaram fora do eixo (anotar no rodapé do slide).
* **Sugestão de ajuste gráfico (opcional):** os dois painéis têm eixos y diferentes (≈ 6–28% × 7–12,5%), o que faz o efeito de `pre10` parecer maior do que é. Para o slide, usar o **mesmo `coord_cartesian(ylim = c(0.05, 0.28))` nos dois**: fica visível que `mult10` mexe muito mais que `pre10`. Manter a versão atual no apêndice.
* **Frase para a banca:** *"A faixa é o intervalo de confiança da probabilidade média do modelo; os pontos são taxas observadas, que variam bem mais porque municípios pequenos têm ruído binomial."*

### E5 — Efeito em probabilidade (diferença e razão; IC por simulação)

| Contraste (outro preditor na média) | Diferença (p.p.) | IC 95% | Razão de prob. | IC 95% |
|---|---|---|---|---|
| `mult10`: média → +1 DP (2,4% → 5,7%) | **+2,2** | 1,7–2,7 | 1,27 | 1,20–1,34 |
| `mult10`: média → +10 p.p. | +8,4 | 6,1–11,0 | 2,03 | 1,74–2,35 |
| `mult10`: 0% → 5% | +3,1 | 2,4–3,7 | 1,45 | 1,33–1,57 |
| `pre10`: média → +1 DP (7,8% → 12,9%) | **+0,6** | 0,2–1,0 | 1,07 | 1,02–1,13 |
| `pre10`: média → +10 p.p. | +1,2 | 0,4–2,1 | 1,15 | 1,05–1,26 |

* **Leitura importante:** a OR de 2,24 por 10 p.p. vira razão de **probabilidades** de 2,03 (a chance de base já é ~9%, não desprezível), e em pontos percentuais: +8,4 p.p. (a partir da média, mas "+10 p.p." leva `mult10` a 12,4%, região esparsa). A comparação por +1 DP é a mais defensável: **+2,2 p.p.** (gestação múltipla) e **+0,6 p.p.** (pré-natal).
* **Frase para a banca:** *"Em chance, um desvio-padrão a mais de gestação múltipla multiplica por 1,3; em probabilidade, é cerca de 2 pontos percentuais a mais de baixo peso, partindo de uma média de 8%."*

### E6 — Forest plots

* `E_forest_familias.png`: `mult10` idêntico nas três famílias; `pre10`: bb 1,16 vs quasi/binomial 1,09, com o IC do quasi tocando 1.
* `E_forest_robustez.png`: todos os cenários acima de 1 para `mult10`; para `pre10`, só os quasi (principal e `n ≥ 30`) tocam o 1.
* **Ajuste cosmético (único item em aberto):** os rótulos dos painéis do segundo gráfico estão como `mult10`/`pre10`; trocar por "Gestação múltipla (+10 p.p.)" e "Pré-natal insuficiente (+10 p.p.)" (mesmo `recode` do primeiro) antes de usar no slide.

### E7 — Calibração descritiva

| Decil de π̂ | Nascidos | Observado | Esperado | Taxa obs. | Taxa esp. |
|---|---|---|---|---|---|
| 1 | 758 | 54 | 46,7 | 7,1% | 6,2% |
| 2 | 1.784 | 106 | 116,8 | 5,9% | 6,5% |
| 3 | 1.511 | 96 | 103,9 | 6,4% | 6,9% |
| 4 | 2.703 | 181 | 195,3 | 6,7% | 7,2% |
| 5 | 7.438 | 612 | 572,9 | 8,2% | 7,7% |
| 6 | 15.000 | 1.164 | 1.210 | 7,8% | 8,1% |
| 7 | 15.678 | 1.235 | 1.299 | 7,9% | 8,3% |
| 8 | 10.665 | 998 | 932 | 9,4% | 8,7% |
| 9 | 7.891 | 711 | 773 | 9,0% | 9,8% |
| 10 | 1.041 | 145 | 140,6 | 13,9% | 13,5% |

| Classe de `n` | Observado | Esperado | Taxa obs. | Taxa esp. |
|---|---|---|---|---|
| < 30 | 131 | 142 | 8,4% | 9,1% |
| 30–99 | 485 | 498 | 7,9% | 8,1% |
| 100–499 | 1.528 | 1.473 | 8,6% | 8,3% |
| ≥ 500 | 3.158 | 3.277 | 8,1% | 8,4% |

* **Leitura:** pontos em torno da diagonal, sem padrão sistemático (o maior desvio, decil 8 × 9, tem sentidos opostos). O esperado total é 5.390 contra 5.302 observados (+88; +1,7%): o beta-binomial pesa menos os municípios grandes, e nos ≥ 500 o modelo espera ~3,6% mais casos do que o observado (a diferença é da ordem de 1 a 1,5 desvio-padrão sob a variância beta-binomial; conta aproximada, sem teste). Descritivo, sem p-valor.
* **Frase para a banca:** *"Comparei taxas observadas e esperadas por faixa de risco previsto; não há desvio sistemático. A leve superestimação nos maiores municípios é a contrapartida de o beta-binomial pesar menos esses municípios."*

### E8 — O que **não** fazemos

| Não fazemos | Motivo |
|---|---|
| Reselecionar variáveis | C fechada; `adol10` só robustez |
| Excluir municípios | Orientações |
| Chamar OR de risco relativo | Chance ≠ probabilidade (por isso E5) |
| Extrapolar a curva de `mult10` | Cauda esparsa (10 municípios > 10 p.p.) |
| Linguagem causal ou sobre indivíduos | Falácia ecológica |

---

## 4. Conclusões já sustentadas pela Etapa E (insumo para a F)

1. **Gestação múltipla:** associação forte, positiva e estável. Entre municípios, a chance de baixo peso é ≈ 2,2 vezes maior onde essa proporção é 10 p.p. maior (≈ 1,3 por +1 DP; ≈ +2,2 p.p. de probabilidade), controlando pré-natal.
2. **Pré-natal insuficiente:** associação positiva **moderada** (OR 1,16 por 10 p.p.; ≈ +0,6 p.p. por +1 DP), robusta a atípicos e à geografia, sensível à família (quasi-binomial: p = 0,066) e à definição (limiar de 7 consultas).
3. **Heterogeneidade:** os dois preditores reduzem ρ em 46%; boa parte do resto é geográfica (D12).
4. Todas as afirmações são **associações municipais**; sem causalidade e sem extrapolação a indivíduos.

---

## 5. O que a Etapa E alimenta (Etapa F)

| Saída | Slide |
|---|---|
| `E_coeficientes.csv`, `E_trv.csv` | **Tabela de resultados** (OR por +10 p.p. e +1 DP, IC, TRV) |
| `E_prob_painel.png` (com mesmo eixo y nos dois) | **Gráfico de probabilidades com IC** |
| `E_efeitos_probabilidade.csv` | Frase de impacto prático em p.p. |
| `E_forest_robustez.png` + tabela consolidada | **Robustez** |
| `E_calibracao.png`, `E_rho.csv`, `E_prob_painel_com_dados.png` | Apêndice |

---

## 6. Perguntas que a banca pode fazer (e respostas curtas)

1. **"O que significa OR = 2,2?"** Entre municípios, onde a proporção de gestações múltiplas é 10 p.p. maior, a chance de baixo peso é ≈ 2,2 vezes maior, fixo o pré-natal; por +1 DP (≈ 3,3 p.p.), ≈ 1,3.
2. **"Em probabilidade, quanto?"** +1 DP de gestação múltipla = +2,2 p.p. (IC 1,7–2,7), partindo de 8,2%.
3. **"Por que os pontos fogem tanto da faixa?"** A faixa é o IC da probabilidade média; os pontos têm ruído binomial (municípios pequenos) e heterogeneidade (ρ).
4. **"Pré-natal é significativo ou não?"** No modelo final (beta-binomial) p = 0,004; no quasi-binomial p = 0,066. Por isso é associação moderada e dependente da família e da definição.
5. **"Por que Wald e perfil?"** Para checar a aproximação normal: coincidem.
6. **"Isso vale para uma gestante?"** Não: desenho ecológico.
7. **"E a dependência espacial?"** Moran fraco (0,07); controlando região/superfície as OR mal mudam (2,14–2,17 e 1,16–1,21); EP possivelmente otimistas (limitação).
8. **"O modelo reproduz as taxas?"** Descritivamente sim, sem desvio sistemático; leve superestimação nos maiores (+3,6%).
9. **"Por que a curva de gestação múltipla abre acima de 10 p.p.?"** Só 10 municípios; a incerteza é real.

---

## 7. Registro de decisões (colar na Seção 8 do `plano_geral.md`)

| Data | Decisão | Quem |
|---|---|---|
| 13/11/2026 | Etapa E executada; reajuste reproduz a C (β, ρ, convergência) | autor |
| 13/11/2026 | ICs: Wald nos slides (coincide com perfil); OR por +10 p.p. e por +1 DP; efeitos também em p.p. de probabilidade | autor |
| 13/11/2026 | `mult10` classificada como robusta; `pre10` como associação moderada, robusta a atípicos e espaço, sensível à família e à definição | autor |
| 13/11/2026 | Gráfico de probabilidades com mesmo eixo y nos dois painéis (slide) e versão com dados (apêndice) | autor |
| 13/11/2026 | IC de ρ obtido (0,00046–0,00229); D7 cenários 1 e 2 são o mesmo conjunto de 5 municípios (Morro Grande, Florianópolis, Jaborá, Sangão, Caçador) → citar como um cenário | autor |
| 13/11/2026 | Etapa E concluída; próxima: Etapa F | autor |
