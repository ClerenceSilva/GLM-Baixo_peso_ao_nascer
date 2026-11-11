# Etapa C — Modelagem e seleção (Tema 8, baixo peso ao nascer em SC, SINASC 2026)

Script: `scripts/04_modelagem.R` · Status: **CONCLUÍDA em 10/11/2026 (todas as saídas conferidas)**.

---

## 0. Para que serve esta etapa

As orientações (item c) pedem: *"especificar a distribuição, a função de ligação, o preditor linear […] Justificar a escolha do modelo final e os critérios de comparação ou seleção utilizados."* A Etapa C responde cinco perguntas:

1. O binomial-logito com os 5 preditores **converge** e é **estável** (sem separação)?
2. Qual **ligação** usar?
3. Como tratar a **superdispersão** (binomial, quasi-binomial, beta-binomial)?
4. Quais **preditores** ficam?
5. O resultado **aguenta** mudanças razoáveis nos dados?

A forma funcional também é checada por teste formal (B9). O diagnóstico completo (resíduos, influência, VIF, Moran) fica na Etapa D.

**Entrada:** `base_municipal_sc2026.rds` (295 municípios). **Saídas:** `output/tabelas/C_*.csv`, `output/figuras/C_phi_por_classe_n.png`, `data/processed/C_modelos.rds`.

---

## 1. Resumo executivo

| # | Pergunta | Resposta | Evidência |
|---|---|---|---|
| 1 | Convergência/separação | Convergiu em 4 iterações; ajustados entre 0,056 e 0,258; maior EP = 0,107. **Sem separação.** | bloco 2 |
| 2 | Dispersão | φ do nulo = 1,551; do completo = **1,229**. Os preditores explicam 20,4% da deviance, mas a superdispersão **não some**. | bloco 2 |
| 3 | Ligação | **Logito** (probito melhor por apenas 1,07 de AIC; cauchit pior por 15,0) | `C_ligacoes.csv` |
| 4 | Família de dispersão | **Beta-binomial.** TRV vs binomial: χ² = 19,55 (p ≈ 5×10⁻⁶); ΔAIC = **17,5**; ρ = 0,00103 | blocos 7 e 7b |
| 5 | Preditores mantidos | **`prop_gestacao_mult`** e **`prop_prenatal_insuf`** | seleção no beta-binomial |
| 6 | Forma funcional | Sem evidência de curvatura (quadráticos p = 0,68 e 0,19; η̂² p = 0,21) | bloco 8 |
| 7 | Robustez | `mult10` muito estável (OR 2,19–2,35); `pre10` **frágil** (depende da família e da definição de pré-natal) | `C_sensibilidades.csv` |

**Modelo final:** `Y_i ~ BetaBinomial(n_i, π_i, ρ)`, `logit(π_i) = β0 + β1·pre10 + β2·mult10`.

| Termo | β (EP) | OR por +10 p.p. | p (TRV) |
|---|---|---|---|
| `mult10` (gestação múltipla) | 0,805 (0,091) | **2,24** | 1,3×10⁻¹⁶ |
| `pre10` (pré-natal insuficiente) | 0,151 (0,053) | **1,16** | 0,0038 |

---

## 2. Conceitos que você precisa dominar

| Conceito | Explicação em uma frase | Por que importa aqui |
|---|---|---|
| **Modelo binomial agrupado** | `Y_i ~ Binomial(n_i, π_i)`, `logit(π_i) = β0 + β1 x_i1 + …`; resposta = par (baixo peso, demais). | É o que o tema exige; usa o tamanho `n_i`. |
| **Logito e razão de chances** | `exp(β)` multiplica a **chance** `π/(1−π)` por unidade do preditor. | Unidade aqui = **10 p.p.** (C1). |
| **Deviance** | `D = 2[ℓ(saturado) − ℓ(modelo)]`; distância ao ajuste perfeito. | Diferença de deviances = TRV entre modelos encaixados. |
| **TRV (qui-quadrado)** | Com φ = 1, `D0 − D1 ~ χ²(p1 − p0)` sob H0. | Só vale se a binomial descreve a variabilidade. Aqui, só de referência. |
| **Teste F** | Com φ desconhecido: `F = [(D0 − D1)/(p1 − p0)] / φ̂ ~ F(p1 − p0, n − p1)`. | Versão correta com superdispersão (slides de deviance). |
| **Superdispersão (φ)** | Variância observada ÷ variância binomial; φ̂ = X²/(n − p). | φ nulo = 1,55. |
| **Quasi-binomial** | Mesmas estimativas do binomial; EP × √φ. Sem verossimilhança (sem AIC). | Correção simples dos EP. |
| **Beta-binomial** | `π_i` varia entre municípios (Beta). `Var = nπ(1−π)[1 + (n−1)ρ]`. Verossimilhança verdadeira. | A variância extra **cresce com `n`**, como observamos. |
| **ρ** | Correlação intraclasse: o quanto o risco varia entre municípios além do acaso. | ρ = 0 recai na binomial. |
| **AIC / BIC / QAIC** | `−2ℓ + 2p`; `−2ℓ + ln(n)p`; `−2ℓ/φ̂ + 2(p+1)`. | QAIC corrige o AIC para superdispersão do **binomial**. |
| **Separação** | Preditor "prevê perfeitamente" a resposta; β → ±∞. | Checagem exigida; não ocorreu. |

---

## 3. Decisões e resultados

Formato: **o que · alternativas · por que · risco · frase para a banca · resultado**.

### C1 — Preditores em unidades de 10 pontos percentuais

* **O que:** `adol10 = prop_adolescente × 10` etc. `exp(β)` = razão de chances por +10 p.p.
* **Alternativas:** escala 0–1 (OR por "100 p.p."); z-score; escala 0–100 (OR por 1 p.p., minúsculo).
* **Por que:** 10 p.p. é legível. É só mudança de escala: o ajuste não muda.
* **Risco:** +10 p.p. é grande para `mult10` (DP ≈ 3,3 p.p.; máx. 17 p.p.). **Por 1 DP:** OR de `mult10` = exp(0,805 × 0,326) ≈ **1,30**; de `pre10` (DP ≈ 5,1 p.p.) = exp(0,151 × 0,51) ≈ **1,08**. Vale mostrar os dois.
* **Frase para a banca:** *"Reescalei os preditores para 10 pontos percentuais para dar interpretação prática à razão de chances; isso não altera o modelo."*

### C2 — Ponto de partida: binomial agrupada, ligação logito

* **O que:** `glm(cbind(baixo_peso, demais) ~ …, family = binomial(link = "logit"))`.
* **Alternativas:** taxa com `weights = n_i` (equivalente); regressão linear na taxa (ignora `n_i` e a variância binomial); Poisson com offset (outra pergunta).
* **Frase para a banca:** *"A resposta é o número de nascidos com baixo peso entre `n_i`; o modelo binomial dá a cada município o peso que sua informação merece."*
* **Resultado (completo):**

| Termo | β | EP | p (Wald) |
|---|---|---|---|
| Intercepto | −2,666 | 0,107 | < 10⁻¹⁶ |
| `adol10` | 0,092 | 0,063 | 0,142 |
| `esc10` | 0,049 | 0,058 | 0,391 |
| `pre10` | 0,098 | 0,045 | 0,030 |
| `mult10` | 0,788 | 0,086 | < 10⁻¹⁶ |
| `m35_10` | −0,063 | 0,037 | 0,088 |

  Deviance residual 368,85 (289 gl) contra 463,37 (294 gl) do nulo.

### C3 — Convergência e separação

* **Resultado:** convergiu (4 iterações de Fisher); probabilidades ajustadas entre 0,056 e 0,258; maior EP 0,107; sem aviso de probabilidades 0/1.
* **Por que não há separação:** exigiria que uma combinação linear dos preditores dividisse perfeitamente os municípios entre "com" e "sem" baixo peso; os 24 municípios sem casos são todos pequenos e não são separáveis dos demais.
* **Frase para a banca:** *"Verifiquei convergência, probabilidades ajustadas longe de 0 e 1 e erros-padrão razoáveis; não há separação."*

### C4 — Dispersão: Pearson e simulação, **não** o χ² da deviance

* **O que:** φ̂ = X²/(n − p) e D/(n − p); sem `pchisq(deviance, gl)`.
* **Por que:** `n_i·p0 < 3` em 31,9% dos municípios (alerta A4).
* **Resultado:**

| Modelo | φ Pearson | φ deviance | gl |
|---|---|---|---|
| Nulo | 1,551 | 1,576 | 294 |
| Completo (5 var.) | 1,229 | 1,276 | 289 |
| Final (2 var.) | 1,284 | 1,308 | 292 |

  Conferência: o φ do nulo reproduz exatamente o 1,551 da Etapa B. Redução da deviance vs nulo (descritiva): **20,4%**.
* **Frase para a banca:** *"Não usei o qui-quadrado da deviance porque o esperado de casos é menor que 3 em quase um terço dos municípios; avaliei a dispersão por Pearson e por simulação."*

### C5 — Ligação: logito

* **Resultado:**

| Ligação | AIC | ΔAIC | φ Pearson |
|---|---|---|---|
| probito | 1397 | 0 | 1,23 |
| logito | 1398 | 1,07 | 1,23 |
| cloglog | 1398 | 1,63 | 1,23 |
| cauchit | 1412 | 15,0 | 1,26 |

* **Decisão:** a regra era ficar com o logito salvo ganho de ~10 de AIC; o máximo foi 1,07. **Logito**, pela razão de chances.
* **Frase para a banca:** *"Comparei quatro ligações; logito, probito e cloglog empataram (ΔAIC < 2), e fiquei com o logito pela interpretação em razões de chances."*

### C6 — Testes por termo: análise de deviance com teste F

* **Resultado (modelo completo, tipo II):**

| Termo | TRV χ² (φ=1) | p | F (φ̂ = 1,229) | p |
|---|---|---|---|---|
| `adol10` | 2,14 | 0,144 | 1,74 | 0,188 |
| `esc10` | 0,73 | 0,392 | 0,60 | 0,440 |
| `pre10` | 4,70 | 0,030 | 3,83 | 0,051 |
| `mult10` | 77,73 | < 10⁻¹⁶ | 63,25 | 4×10⁻¹⁴ |
| `m35_10` | 2,91 | 0,088 | 2,37 | 0,125 |

* **Leitura:** só `mult10` é inequívoco; `pre10` fica na fronteira (p = 0,030 ou 0,051 conforme se corrige φ). **Ilustração da dependência da ordem (tipo I):** `adol10` entrando primeiro tem p = 0,003, mas p = 0,19 quando ajustado pelos demais; ele "carrega" a estrutura etária que `m35_10` também mede (r = −0,19).
* **Frase para a banca:** *"Como há superdispersão, usei o teste F da análise de deviance e o tipo II, que não depende da ordem das variáveis."*

### C7 — Seleção: 32 modelos, e a seleção **na família principal**

* **O que:** todas as regressões possíveis (2⁵ = 32) por AIC, BIC e QAIC no binomial; depois repetidas no **beta-binomial**; stepwise para conferir.
* **No binomial (QAIC):** melhor = `adol10 + pre10 + mult10 + m35_10`; o de 3 variáveis (`adol + pre + mult`) está a 0,11 de QAIC. Stepwise por AIC (backward, forward, both) → as mesmas 4 variáveis; por BIC → `adol10 + mult10`.
* **No beta-binomial (a que vale):**

| Modelo | k | ΔAIC | ΔBIC |
|---|---|---|---|
| `adol10 + pre10 + mult10` | 3 | **0** | 2,24 |
| `esc10 + pre10 + mult10 + m35_10` | 4 | 0,17 | 6,09 |
| `pre10 + mult10 + m35_10` | 3 | 0,38 | 2,61 |
| `adol10 + pre10 + mult10 + m35_10` | 4 | 0,90 | 6,83 |
| `pre10 + mult10` | 2 | 1,45 | **0** |

  Há **8 modelos a menos de 2 unidades do melhor** (os dados não os discriminam). Só `pre10` e `mult10` estão em **100%** deles; `adol10`, `esc10` e `m35_10` em 50% cada (são intercambiáveis).
* **Ajuste de procedimento (honestidade):** a regra C11 original mandava selecionar pelo QAIC do binomial e escolher a família depois. Isso era incoerente: a seleção deve ser feita **na família principal**. A ordem correta é **família (C8) → seleção (C7/C11)**. Foi isso que fizemos ao refazer a seleção no beta-binomial. O modelo de 4 variáveis (que o QAIC indicava) foi considerado primeiro e abandonado por esse motivo.
* **Risco:** seleção e inferência nos mesmos dados → p-valores otimistas (limitação). BIC do `glm` usa n = 295 (município), não 64.469.
* **Frase para a banca:** *"Quatro dos cinco preditores são quase intercambiáveis pelo AIC. Só gestação múltipla e pré-natal insuficiente aparecem em todos os modelos competitivos; fiquei com esses dois, que também têm o melhor BIC."*

### C8 — Família de dispersão: **beta-binomial**

* **Regra (escrita antes):** binomial se φ ≤ ~1,1 e simulação não rejeita; beta-binomial se ΔAIC (bin − bb) > 10 **e** φ por classe sobe com `n`; senão quasi.
* **Resultados no modelo final:**

| Evidência | Valor |
|---|---|
| AIC binomial · beta-binomial | 1404,99 · **1387,44** (ΔAIC = **17,5**) |
| TRV (fronteira ρ = 0) | χ² = 19,55; **p ≈ 0,000005** |
| φ_bb · ρ | 968,9 · **0,00103** |

| Classe de `n` | φ observado (Pearson²) | Fator beta-binomial `1+(n−1)ρ` |
|---|---|---|
| < 30 (n̄ = 19) | 1,07 | 1,02 |
| 30–99 (n̄ = 59) | 1,13 | 1,06 |
| 100–499 (n̄ = 216) | 1,23 | 1,22 |
| ≥ 500 (n̄ = 1.395) | **2,51** | **2,44** |

* **Leitura:** a superdispersão **não é constante**: está nos municípios grandes. O beta-binomial reproduz quase exatamente o padrão observado; o quasi-binomial (φ constante = 1,28) ficaria curto nos grandes e largo nos pequenos. Um ρ de 0,001 parece desprezível, mas com 1.400 nascimentos ele mais que dobra a variância.
* **Consequência nas estimativas (importante):** o beta-binomial **pesa menos os municípios grandes**, então os coeficientes mudam, não só os EP:

| | binomial | quasi | beta-binomial |
|---|---|---|---|
| `mult10` β (EP) | 0,797 (0,086) | 0,797 (0,098) | 0,805 (0,091) |
| `pre10` β (EP) | 0,089 (0,043) | 0,089 (0,048) | **0,151 (0,053)** |
| `pre10` p | 0,037 | **0,067** | **0,004** |

  `mult10` não depende da família. `pre10` sim: seu efeito é maior nos municípios pequenos/médios e menor nos grandes.
* **DHARMa (simulação):** dispersão 0,912 (p = 0,026) no binomial e 0,857 (p = 0,104) no beta-binomial. **Não interprete como subdispersão:** a estatística é o DP dos resíduos quantílicos, dominado pelos 80 municípios pequenos (resíduos muito discretos), e vai no sentido contrário do φ de Pearson. Tratar como **pouco informativo aqui**; a evidência principal é o TRV e o φ por classe. Rever os resíduos quantílicos do modelo final na Etapa D.
* **Risco:** `glmmTMB` pode não convergir (aqui convergiu: `pdHess = TRUE`, convergência 0). A fórmula `ρ = 1/(1 + sigma)` vale para a parametrização do `glmmTMB` (confirmar em `?glmmTMB::betabinomial` antes de citar).
* **Frase para a banca:** *"A variabilidade extra entre municípios é real e concentrada nos grandes. O beta-binomial a modela: o teste da razão de verossimilhanças contra a binomial dá p da ordem de 10⁻⁶ e a variância prevista por tamanho acompanha a observada (2,4 contra 2,5 nos 28 maiores). O preço é que ele pesa menos os municípios grandes, o que muda o coeficiente de pré-natal."*

### C9 — Forma funcional

* **Resultado:** quadráticos (teste F): `pre10` p = 0,68; `mult10` p = 0,19. Teste de η̂²: p = 0,21. **Nenhuma evidência de curvatura.**
* **Frase para a banca:** *"As curvaturas da exploratória eram de municípios pequenos; testes formais não encontram não linearidade."*
* **Pendência para a D:** resíduos parciais de `mult10` (cauda esparsa acima de 10 p.p.).

### C10 — Sensibilidades

OR por +10 p.p. (e p) no modelo final `pre10 + mult10`:

| Cenário | `mult10` quasi | `mult10` bb | `pre10` quasi | `pre10` bb |
|---|---|---|---|---|
| 0. Principal (jan–ago) | 2,22 (< 10⁻¹³) | 2,24 (< 10⁻¹⁷) | 1,09 (0,067) | 1,16 (0,004) |
| a. Jan–jul | 2,30 | 2,30 | 1,10 (0,069) | 1,16 (0,007) |
| b. Pré-natal < 7 | 2,21 | 2,21 | **1,04 (0,24)** | **1,07 (0,050)** |
| c. Com `adol10` | 2,19 | 2,22 | 1,10 (0,053) | 1,15 (0,006) |
| d. Apenas `n ≥ 30` (215) | 2,30 | 2,35 | 1,09 (0,112) | 1,17 (0,007) |

* `adol10` no cenário (c): OR 1,17 (quasi, p = 0,005) e 1,12 (beta-binomial, p = 0,058): positivo e consistente, mas limítrofe na família principal.
* `esc10` com `n ≥ 30` e modelo completo: β = −0,035 (quasi, p = 0,64) e −0,023 (bb, p = 0,75): **descartado com segurança**.
* **Leitura:**
  * **`mult10` é robusto**: OR entre 2,19 e 2,35 em todos os cenários e famílias.
  * **`pre10` é frágil**: depende da família (bb p ≈ 0,005; quasi p ≈ 0,07–0,24) e da definição (limiar 7 derruba o efeito para 1,04–1,07). Deve entrar como **associação moderada e sensível à definição**, nunca como achado forte.
  * Reconstrução da base (jan–jul, pré-natal < 7) validada contra a Etapa A (`stopifnot`).
* **Frase para a banca:** *"Gestação múltipla é estável em todos os cenários. Pré-natal insuficiente depende da família e da definição, e por isso o apresento como associação moderada."*

### C11 — Modelo final

* **Regra:** na família principal, escolher o mais simples com ΔAIC < 2 do melhor; variável sem sustentação sai; empate → parcimônia.
* **Aplicação:** `pre10 + mult10` (k = 2): ΔAIC = 1,45, **melhor BIC** entre os 32, as duas variáveis em 100% dos modelos competitivos, TRV de `pre10` p = 0,004 e de `mult10` p ≈ 10⁻¹⁶.
* **Alternativa de robustez:** `adol10 + pre10 + mult10` (melhor AIC, mas `adol10` p = 0,058 no bb).
* **O que foi descartado e por quê:** `esc10` (p > 0,6 com `n ≥ 30`); `m35_10` (p = 0,29, efeito fraco); `adol10` (limítrofe, intercambiável).
* **Atenção para a apresentação:** o enunciado pede 4 a 8 preditores **candidatos**; os 5 foram considerados, e 2 compõem o modelo final ("nem todos precisam integrar o modelo final").

### C12 — O que **não** fazemos

| Não fazemos | Motivo |
|---|---|
| p-valor χ² da deviance como "qualidade do ajuste" | Alerta A4 |
| Interações | Sem justificativa; 295 observações |
| Categorizar preditores | Orientação do enunciado |
| Excluir municípios | Só sensibilidade; influência é na D |
| Diagnóstico completo | Etapa D |

---

## 4. O que a Etapa C alimenta

| Saída da C | Uso adiante |
|---|---|
| Modelo final (beta-binomial, `pre10 + mult10`) | **D:** diagnóstico (resíduos quantílicos, envelope simulado, Cook, alavancagem, VIF, Moran) |
| ORs por +10 p.p. | **E:** ICs (Wald e perfil), forest plot, gráfico de probabilidades com IC |
| Sensibilidades e fragilidade de `pre10` | **E/F:** slide de robustez e limitações |
| φ por tamanho e municípios grandes | **D:** influência dos 28 maiores; o beta-binomial já reduz o peso deles |

**Pendências para a Etapa D:**
1. Resíduos parciais e resíduos × preditor para `mult10` (suporte curto, 42% de zeros).
2. Resíduos quantílicos do modelo final (explicar o resultado estranho do DHARMa).
3. Cook/alavancagem, com atenção a Painel, Marema, Presidente Nereu e Braço do Trombudo (pequenos, fora do funil) e aos 28 maiores.
4. VIF (esperado ~1: r entre `pre10` e `mult10` = −0,03).
5. Moran nos resíduos (agrupamento regional sugerido na B).

---

## 5. Limitações a levar para o fechamento

* Seleção e inferência nos mesmos dados (p-valores otimistas).
* `pre10` sensível à família e à definição (limiar 6 vs 7).
* Beta-binomial muda os pesos: interpretação dos coeficientes é "ponderada" de forma diferente da binomial.
* Modelo explica uma parte modesta da variação (deviance −20% no binomial completo; resta heterogeneidade entre municípios grandes).
* Ecológico: associações municipais, sem extrapolação para indivíduos.
* Prévia dos dados; agosto parcial (sensibilidade jan–jul não altera as conclusões).

---

## 6. Perguntas que a banca pode fazer (e respostas curtas)

1. **"Por que binomial e não regressão linear na taxa?"** A taxa tem precisão distinta por município (`n` de 8 a 4.978), variância `π(1−π)/n` e é limitada a [0,1].
2. **"O que é superdispersão e como você viu?"** Variância maior que a binomial prevê: φ do nulo = 1,55; do modelo final = 1,28; e concentrada nos municípios grandes (2,5 nos ≥ 500).
3. **"Por que não usou o χ² da deviance?"** Esperado de casos < 3 em 31,9% dos municípios; a aproximação não vale.
4. **"Quasi-binomial ou beta-binomial?"** Beta-binomial: TRV contra a binomial p ≈ 5×10⁻⁶, ΔAIC = 17,5, e a variância prevista por tamanho reproduz a observada (2,44 vs 2,51 nos ≥ 500). O quasi supõe φ constante, o que não ocorre.
5. **"Por que ρ tão pequeno (0,001) é relevante?"** Porque o fator é `1 + (n − 1)ρ`: com `n` ≈ 1.400 ele chega a 2,4.
6. **"Por que logito?"** Canônica, razão de chances; ΔAIC < 2 em relação ao probito e ao cloglog.
7. **"Por que só 2 preditores?"** Quatro dos cinco são intercambiáveis pelo AIC; só gestação múltipla e pré-natal estão em todos os modelos competitivos; essas duas têm o melhor BIC.
8. **"A seleção não invalida os p-valores?"** Em parte; por isso usei critérios sem p-valor, testes por termo e sensibilidades. É limitação declarada.
9. **"Por que o efeito de pré-natal é maior no beta-binomial?"** Porque ele pesa menos os municípios grandes, onde o efeito é menor. Por isso reporto o resultado como moderado e sensível à família.
10. **"O que significa OR = 2,24 para gestação múltipla?"** Entre municípios, a chance de baixo peso é cerca de 2,2 vezes maior onde a proporção de gestações múltiplas é 10 p.p. maior, fixo o pré-natal (por 1 DP ≈ 3,3 p.p., OR ≈ 1,30). É associação municipal, sem causalidade nem extrapolação a indivíduos; e gestação múltipla é fator de risco clínico conhecido, então o resultado é plausível.
11. **"E o resultado do DHARMa?"** Dá dispersão < 1, na contramão do Pearson e do TRV; é uma estatística sensível a muitos municípios pequenos com resíduos discretos; as evidências principais são o TRV e o φ por classe, e a Etapa D examina os resíduos quantílicos.

---

## 7. Registro de decisões (colar na Seção 8 do `plano_geral.md`)

| Data | Decisão | Quem |
|---|---|---|
| 10/11/2026 | Preditores em unidades de 10 p.p. (OR por +10 p.p.) | autor |
| 10/11/2026 | Ligação logito (ΔAIC < 2 vs probito/cloglog; cauchit rejeitado) | autor |
| 10/11/2026 | Família principal: **beta-binomial** (TRV p ≈ 5×10⁻⁶; ΔAIC 17,5; φ cresce com `n`); quasi como robustez | autor |
| 10/11/2026 | Procedimento corrigido: escolher família **antes** de selecionar variáveis; seleção refeita no beta-binomial | autor |
| 10/11/2026 | **Modelo final: `prop_prenatal_insuf` + `prop_gestacao_mult`** (melhor BIC; ΔAIC 1,45) | autor |
| 10/11/2026 | `esc10` descartada (p > 0,6 com `n ≥ 30`); `m35_10` e `adol10` fora (intercambiáveis, efeito fraco/limítrofe); `adol10` fica como robustez | autor |
| 10/11/2026 | Sem termos quadráticos (p = 0,68; 0,19; η̂² p = 0,21) | autor |
| 10/11/2026 | `pre10` reportada como associação moderada e sensível (família e limiar de pré-natal) | autor |
| 10/11/2026 | Etapa C concluída; próxima: Etapa D | autor |
