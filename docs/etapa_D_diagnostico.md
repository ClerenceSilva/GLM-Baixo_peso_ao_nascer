# Etapa D — Diagnóstico (Tema 8, baixo peso ao nascer em SC, SINASC 2026)

Scripts: `scripts/05_diagnostico.R` e `scripts/05b_sensibilidade_espacial.R` · Status: **CONCLUÍDA em 11/11/2026 (D1–D12; saídas e figuras conferidas; nenhuma pendência).**

---

## 0. Para que serve esta etapa

As orientações (item d) pedem: *"avaliar resíduos, observações atípicas e influentes, multicolinearidade e adequação da relação funcional. Explicar os problemas encontrados e as decisões tomadas; **não excluir observações apenas por serem influentes**."*

Modelo diagnosticado: `Y_i ~ BetaBinomial(n_i, π_i, ρ)`, `logit(π_i) = β0 + β1·pre10 + β2·mult10` (295 municípios).

Seis perguntas: (1) a distribuição descreve a variabilidade, inclusive por tamanho `n`? (2) sobrou padrão contra os preditores / a relação é linear? (3) a ligação está ok? (4) algum município "manda" no resultado? (5) há multicolinearidade? (6) municípios vizinhos têm resíduos parecidos (Moran)?

**Não** houve seleção de variáveis, troca de modelo por causa de um teste isolado, nem exclusão de municípios.

---

## 1. Resumo executivo (resultados reais)

| # | Pergunta | Resposta | Evidência |
|---|---|---|---|
| 1 | O reajuste reproduz a Etapa C? | **Sim.** β_mult = 0,805; β_pre = 0,151; ρ = 0,00103; `pdHess` = TRUE | bloco 1 |
| 2 | Resíduos quantílicos ~ N(0,1)? | **Sim.** média 0,003; DP **0,997**; 12 com \|r\|>2 (esperado ≈ 15) e 1 com \|r\|>3 (esperado ≈ 1); Shapiro p = 0,41. Binomial: DP 1,10; 21 e 3 | bloco 3 |
| 3 | Envelope simulado | **0 pontos fora** (de 295), 99/99 simulações válidas | bloco 5, `D_envelope_bb.png` |
| 4 | O padrão por tamanho `n` foi resolvido? | **Sim.** φ de Pearson por classe: beta-binomial 1,06 · 1,05 · 0,96 · 1,15; binomial 1,07 · 1,13 · 1,23 · **2,51** | bloco 3 |
| 5 | DHARMa | bb: KS p = 0,82; dispersão p = 0,13; outliers p = 1; **sem problemas**. Binomial: dispersão p = 0,036 e **desvios de quantis** (curvas vermelhas) | bloco 4 |
| 6 | Forma funcional / ligação | **Sem evidência de curvatura:** splines p = 0,51 (conjunto), 0,19 (`mult10`), 0,95 (`pre10`); η̂² p = 0,137 | bloco 7 |
| 7 | Multicolinearidade | **Ausente:** VIF = 1,003; r(pre10, mult10) = −0,033; nº de condição 1,03 | bloco 8 |
| 8 | Influentes | **Nenhum decisivo.** Maior \|DFBETAS\| = 0,52 (Morro Grande em `mult10`); maior Cook = 0,113 (Florianópolis). Nenhuma exclusão; OR de `mult10` varia só 2,14–2,35 nos cenários | blocos 9 e 10 |
| 9 | Moran | **Autocorrelação espacial fraca, mas detectável:** I = 0,077 (p = 0,015) e 0,082 (p = 0,007); vira **limitação** | bloco 11 |

| 10 | Sensibilidade espacial (D12) | **Conclusões robustas:** com lon/lat e superfície, OR `mult10` 2,14–2,17 e `pre10` 1,16–1,21, significativas; Moran cai a 0,038 (p = 0,13) com a superfície; ρ cai ~80%. Com regiões intermediárias (M1) a OR de `mult10` é 2,15 e a de `pre10` 1,19; o Moran some (p = 0,25). M4 degenerado | D12 |

**Leitura geral:** o beta-binomial descreve bem a variabilidade (inclusive nos 28 municípios grandes), sem padrão residual nos preditores nem em `n`; a relação é linear no logito; os preditores são ortogonais; nenhum município muda as conclusões. A ressalva é a dependência espacial residual leve, que pode deixar os erros-padrão um pouco otimistas.

---

## 2. Conceitos que você precisa dominar

| Conceito | Explicação em uma frase | Por que importa aqui |
|---|---|---|
| **Resíduo de Pearson** | `(y − nμ)/√Var(y)`, com a variância **do modelo**. | No beta-binomial a variância inclui `1+(n−1)ρ`. Se o modelo está certo, a média do quadrado é ≈ 1. |
| **Resíduo quantílico aleatorizado** | `r = Φ⁻¹(F(y))`; com `y` discreto sorteia-se `u` em `[F(y−1), F(y)]`. | Normal padrão se o modelo está certo, mesmo com contagens pequenas. |
| **Envelope simulado** | Simula respostas sob o modelo, reajusta, e usa mín–máx dos |resíduos| ordenados. | Diz o que o acaso permite; pontos dentro = compatível. |
| **Alavancagem `h_ii`** | Quanto a posição de `x_i` (ponderada) puxa o ajuste. | Potencial de influência. |
| **Distância de Cook** | Mudança global nos coeficientes ao retirar uma observação. | Combina "mal ajustado" com "alavanca". Referência usual: preocupar-se perto de 1. |
| **DFBETAS** | `(β_j − β_j(−i))/EP(β_j)`. | Responde direto: "este município muda o efeito?". Limiar `2/√n` ≈ 0,116 é **sensível**: ~5% passam por acaso; só valores ≥ 1 são considerados graves. |
| **Leave-one-out (LOO)** | Reajustar o modelo sem cada observação. | Aqui é barato (295 refits), então é exato. |
| **Resíduo parcial** | Resíduo de trabalho + `β_j(x_j − x̄_j)`. | Mostra a relação de `x_j` com o logito já descontados os outros preditores. |
| **VIF** | `1/(1−R²_j)`. | > 5 ou 10 merece atenção. |
| **I de Moran** | Correlação entre o resíduo de um município e a média dos vizinhos (−1 a +1). | Independência é suposição do modelo. |

---

## 3. Decisões e resultados

Formato: **o que · por que · resultado · frase para a banca**.

### D1 — Reajustar o modelo final e conferir com a Etapa C
* **O que:** o script reajusta `glmmTMB(cbind(y, demais) ~ pre10 + mult10, betabinomial)` e compara com a C.
* **Resultado:** idêntico. β_mult 0,80547 (EP 0,091); β_pre 0,15090 (EP 0,053); ρ = 0,00103; φ do glmmTMB = 969; AIC 1387,4.
* **Frase para a banca:** *"O diagnóstico parte do reajuste do modelo final, conferido contra a etapa de modelagem."*

### D2 — Resíduo principal: quantílico aleatorizado (manual e DHARMa)
* **Por que:** com resposta discreta e `nπ < 3` em 31,9% dos municípios, Pearson e deviance não são normais. O quantílico é N(0,1) se o modelo está certo.
* **Resultado:**

| Modelo | média | DP | mín | máx | \|r\|>2 | \|r\|>3 | Shapiro p |
|---|---|---|---|---|---|---|---|
| beta-binomial | 0,003 | **0,997** | −2,41 | 3,02 | 12 | 1 | 0,41 |
| binomial | 0,030 | 1,10 | −3,13 | 3,14 | 21 | 3 | 0,66 |

  Referência sob normalidade: ≈ 15 acima de 2 e ≈ 1 acima de 3 (em 295). O beta-binomial está dentro; o binomial tem excesso de resíduos grandes.
* **Cuidado:** o resíduo é aleatorizado (outro `seed` muda pontos individuais, não o padrão). O Shapiro é só descritivo.
* **Frase para a banca:** *"Como a resposta é discreta e os municípios são pequenos, usei resíduos quantílicos aleatorizados; no beta-binomial eles têm média 0 e desvio-padrão 1, como o esperado."*

### D3 — Envelope simulado manual (algoritmo do `hnp`)
* **O que:** 99 simulações (`π_i ~ Beta`, `y ~ Binomial`), reajuste em cada uma, envelope mín–máx dos |Pearson| ordenados.
* **Resultado:** **0 pontos fora**. Os maiores resíduos (Painel 4,78; Jaborá 3,68) ficam **dentro** da faixa; a cauda observada fica um pouco acima da mediana simulada, sem sair do envelope.
* **Frase para a banca:** *"O envelope diz quanto de afastamento o próprio modelo produziria por acaso: nenhum dos 295 resíduos saiu dele."*

### D4 — Resíduos × ajustados, preditores e tamanho (o teste central)
* **Por que:** a razão para escolher o beta-binomial foi a superdispersão **crescer com `n`**. Se ele está certo, φ de Pearson ≈ 1 em todas as classes.
* **Resultado:**

| Classe de `n` | Municípios | DP rq (bb) | DP rq (bin) | φ Pearson (bb) | φ Pearson (bin) |
|---|---|---|---|---|---|
| < 30 | 80 | 0,975 | 0,981 | 1,06 | 1,07 |
| 30–99 | 105 | 1,02 | 1,05 | 1,05 | 1,13 |
| 100–499 | 82 | 0,951 | 1,06 | 0,96 | 1,23 |
| ≥ 500 | 28 | 1,10 | **1,62** | 1,15 | **2,51** |

  O φ do binomial reproduz exatamente o da Etapa C (1,07 · 1,13 · 1,23 · 2,51), e o beta-binomial o leva a ≈ 1 em todas as classes. O φ global caiu de 1,284 (binomial) para **1,052**. Correlações dos resíduos com `pre10`, `mult10`, `log(n)` e `η̂`: todas \|r\| < 0,014.
* **Detalhe a mencionar:** nos gráficos (`D_residuos_x.png`, `D_residuos_x_n_bin_vs_bb.png`) a curva suavizada **desce nas pontas** (η̂ alto, `mult10` > 1,2, `n` > 2.000), com bandas largas que incluem zero; são poucos pontos (Florianópolis, Joinville e alguns). Os ≥ 500 têm média de rq = −0,11 (levemente superestimados), sem significância. Não é padrão sistemático.
* **Frase para a banca:** *"A prova de que o beta-binomial corrigiu o problema certo é a dispersão por classe de tamanho: no binomial ela chega a 2,5 nos municípios grandes; no beta-binomial fica entre 0,96 e 1,15."*

### D5 — Forma funcional e ligação
* **Resultado:**

| Teste | p |
|---|---|
| Splines (3 gl) em `pre10` e `mult10` | 0,511 |
| Spline só em `mult10` | 0,194 |
| Spline só em `pre10` | 0,946 |
| η̂² (ligação/forma) | 0,137 (coef. −0,39, EP 0,26) |

  Resíduos parciais (`D_residuos_parciais.png`): `pre10` acompanha a reta. Em `mult10`, a suavização **achata acima de ≈ 1,0 (10 p.p.)**, mas a banda inclui a reta e há só ~8 municípios ali (e a maioria é minúscula, como Morro Grande, com 4 de 23 em gestação múltipla); o teste do spline (p = 0,194) não confirma curvatura.
* **Decisão:** manter ambos **lineares no logito**. **Consequência para a Etapa E:** no gráfico de probabilidades, restringir `mult10` ao suporte observado (≤ 17,4 p.p.) e não extrapolar; comentar que acima de ~10 p.p. há pouca informação.
* **Frase para a banca:** *"Linearidade checada por três caminhos: resíduos parciais, splines e teste de η̂²; nenhum indica curvatura. O trecho final de `mult10` tem pouquíssimos municípios, e por isso restrinjo as previsões ao suporte observado."*

### D6 — Influência: aproximada e LOO exato
* **Resultado:**
  * Alavancagem > 2p/n (0,0203): **38** municípios (13%); a distribuição é assimétrica (média p/n = 0,010), então o limiar é pouco seletivo. Os mais altos: Florianópolis 0,093, Morro Grande 0,081, Arroio Trinta e Capão Alto 0,062, Ponte Serrada 0,048.
  * **DFBETAS** > 0,116: 15 em `pre10` e 14 em `mult10` (≈ 5%, exatamente o que o acaso produz). **Máximos:** Morro Grande −0,52 em `mult10`; Florianópolis −0,49 em `pre10`; Jaborá +0,33 e Caçador −0,25 em `pre10`; Sangão +0,27 e Marema +0,24 em `mult10`. **Nenhum chega a 1.**
  * **Cook (aprox.):** máximo 0,113 (Florianópolis), depois Morro Grande 0,096, Caçador 0,051, Jaborá 0,046, Sangão 0,032.
  * **Comparação com o binomial:** Florianópolis tem Cook = **1,66** no binomial, contra 0,113 no beta-binomial. O beta-binomial reduz o peso dos grandes e elimina o problema de influência que o binomial teria.
  * **Morro Grande** (n = 23; 2 casos; `mult10` = 1,74, o maior valor): puxa a OR de `mult10` **para baixo**; sem ele a OR sobe 0,109 (2,24 → 2,35). **Florianópolis** puxa a OR de `pre10` para baixo (sem ela, +0,03).
  * Os 4 minúsculos do funil (Painel, Marema, Presidente Nereu, Braço do Trombudo): alavancagem baixa, Cook ≤ 0,021 e \|DFBETAS\| ≤ 0,24. **Não são influentes**; seus resíduos são altos (Painel 3,02 quantílico) mas dentro do envelope.
* **Frase para a banca:** *"Medi a influência refazendo o ajuste sem cada município; o maior impacto foi de meio erro-padrão (Morro Grande), longe de 1, e ninguém foi excluído."*

### D7 — Sensibilidade (reportar, não excluir)

| Cenário | n | OR `mult10` (IC 95%) | p | OR `pre10` (IC 95%) | p | ρ |
|---|---|---|---|---|---|---|
| 0. Principal | 295 | 2,24 (1,87–2,68) | 1,2×10⁻¹⁸ | 1,16 (1,05–1,29) | 0,0041 | 0,00103 |
| 1 e 2. Sem Morro Grande, Florianópolis, Jaborá, Sangão, Caçador* | 290 | 2,34 (1,94–2,81) | 3×10⁻¹⁹ | 1,20 (1,08–1,33) | 0,0005 | 0,00066 |
| 3. Sem os 4 minúsculos do funil | 291 | 2,14 (1,78–2,58) | 1×10⁻¹⁵ | 1,17 (1,06–1,30) | 0,0026 | 0,00102 |
| 4. Sem os 28 maiores | 267 | 2,22 (1,86–2,65) | 5×10⁻¹⁹ | 1,24 (1,11–1,38) | 0,00015 | 0,00005 |
| 5. Sem n < 30 | 215 | 2,35 (1,86–2,97) | 7×10⁻¹³ | 1,17 (1,04–1,31) | 0,0066 | 0,00105 |
| 6. Sem \|rq\| > 2 | 283 | 2,29 (1,92–2,74) | 8×10⁻²⁰ | 1,13 (1,03–1,25) | 0,014 | 0,00063 |

\* Os cenários 1 e 2 coincidem: as 5 de maior DFBETAS e as 5 de maior Cook são o **mesmo conjunto**. Apresentar como um só.

* **Regra pré-definida (mudança > 10% na OR ou mudança de significância):** **nenhum cenário a aciona.** `mult10`: 2,14–2,35 (−4% a +5%). `pre10`: 1,13–1,24 (−3% a +7%), significativo em **todos**.
* **Leituras que a banca pode explorar:**
  * No cenário 4, ρ cai para 0,00005 (praticamente binomial): confirma que a superdispersão extra está nos municípios grandes.
  * A OR de `pre10` sobe sem os grandes (1,24): o efeito é maior nos municípios pequenos/médios (mesmo achado da C sobre o peso do beta-binomial). Em coeficiente, β_pre varia de 0,12 a 0,21: a **OR** é estável, mas a **magnitude** de pre10 oscila; reportar como "associação moderada".
  * Fragilidade de `pre10` na C era com a **família** e a **definição** (limiar 7), não com municípios isolados: aqui nenhum município a derruba.
  * O cenário 6 (cortar por resíduo) é só estresse; não é proposta de exclusão.
* **Frase para a banca:** *"Nenhuma observação foi excluída. Refiz o modelo sem os municípios mais influentes e sem grupos inteiros (os 28 maiores, os minúsculos): a OR de gestação múltipla fica entre 2,1 e 2,35 e a de pré-natal entre 1,13 e 1,24, sempre significativa."*

### D8 — Multicolinearidade
* **Resultado:** VIF(pre10) = VIF(mult10) = **1,003**; r = −0,033; número de condição 1,03. No modelo completo de 5 preditores (referência), VIF máximo = 1,54 (`adol10`), 1,49 (`m35_10`).
* **Frase para a banca:** *"Os preditores finais são praticamente ortogonais; os coeficientes não competem entre si."*

### D9 — O `testDispersion` do DHARMa (correção da minha explicação anterior)
* **Resultado:** no beta-binomial, dispersão = 0,864 (p = **0,132**, não significativo); no binomial, 0,912 (p = 0,036). Na figura, o painel do bb mostra "No significant problems" (KS 0,82; outliers 1) e o do binomial mostra desvios de quantis (curvas vermelhas) e dispersão significativa.
* **Correção:** na Etapa C e na versão anterior desta seção sugeri que o valor < 1 vinha de os municípios minúsculos terem resíduos discretos puxando o DP para baixo. **As saídas não confirmam isso:** o DP dos resíduos quantílicos é 0,975 em `< 30` (≈ 1) e 0,997 no total. Além disso, a estatística do DHARMa não é o DP dos resíduos quantílicos, e sim a razão entre a variância observada e a simulada dos resíduos. O que se pode afirmar é: **no modelo final não há evidência de dispersão inadequada** (p = 0,13), e a evidência principal é o φ por classe, o envelope e o DP dos resíduos. Não explique o 0,864 por um mecanismo específico.
* **Frase para a banca:** *"O teste de dispersão do DHARMa não rejeita o beta-binomial (p = 0,13), ao passo que rejeita o binomial (p = 0,036); isso concorda com o φ de Pearson por classe de tamanho."*

### D10 — Moran nos resíduos

| Resíduo | Vizinhança | I | p (normal) | p (Monte Carlo, 9.999) |
|---|---|---|---|---|
| Pearson, **modelo final** | contiguidade | **0,077** | 0,0145 | 0,0152 |
| Pearson, modelo final | 5 vizinhos | **0,082** | 0,0070 | 0,0102 |
| Pearson, modelo nulo | contiguidade | 0,054 | 0,059 | 0,063 |
| Pearson, modelo nulo | 5 vizinhos | 0,057 | 0,041 | 0,048 |
| Quantílico, modelo final | contiguidade | 0,087 | 0,0072 | 0,0082 |

* **Leitura:** a esperança sob independência é −0,003. Todos os I são positivos e pequenos (≈ 0,05–0,09), **significativos nos modelos finais** com as duas definições de vizinho. O sinal é fraco (a escala vai a 1), mas consistente: **há agrupamento espacial residual**. Os preditores **não absorvem** essa estrutura (I final ≥ I nulo; a diferença 0,054 → 0,077 é pequena e não foi testada, então não afirme que "aumentou").
* **Mapas** (`D_mapa_residuos.png`, `D_mapa_residuos_nulo.png`): resíduos positivos concentrados no Planalto Serrano/Meio-Oeste/Oeste e resíduos negativos agrupados no Leste (Vale do Itajaí e litoral central). Os 12 maiores resíduos positivos incluem Painel, São Joaquim, Lauro Müller (Planalto/Sul), Jaborá, Arabutã, Águas de Chapecó, Caçador, Herval d'Oeste e Nova Itaberaba (Meio-Oeste/Oeste), **o que apoia a hipótese levantada na Etapa B**. Descreva as regiões como "padrão visual", não como teste (não testamos regiões).
* **Implicação:** a suposição de independência é levemente violada; os **erros-padrão e p-valores podem ficar um pouco otimistas**. As estimativas pontuais não são afetadas de forma importante com um I desse tamanho; a conclusão sobre `mult10` (z ≈ 8,8) não corre risco; a de `pre10` foi testada no D12 e **não** se mostrou sensível ao controle espacial (OR 1,16–1,21, sempre significativa).
* **Decisão:** **não alterar o modelo final**; registrar como **limitação** (Seção 5 da C e F). Complemento opcional (Seção 5, item 2): sensibilidade com um efeito regional.
* **Frase para a banca:** *"Testei se municípios vizinhos têm resíduos parecidos: há uma dependência espacial fraca (I ≈ 0,08, p ≈ 0,01). Os preditores não a absorvem. Por isso trato os erros-padrão como ligeiramente otimistas, principalmente o de pré-natal, e declaro isso como limitação."*

### D11 — O que **não** fizemos
Excluir municípios; trocar o modelo por um teste isolado; refazer a seleção de variáveis; usar χ² da deviance (alerta A4); interpretar o Shapiro como veredito.

### D12 — Sensibilidade espacial (complemento do Moran)

**Resultado (`05b_sensibilidade_espacial.R`):**

| Modelo | Situação | OR `mult10` (IC 95%) | OR `pre10` (IC 95%) | p `pre10` | ΔAIC vs M0 | ρ | Moran (contig.) |
|---|---|---|---|---|---|---|---|
| M0 final | ok | 2,24 (1,87–2,68) | 1,16 (1,05–1,29) | 0,0041 | 0 | 0,00103 | I = 0,077; p = 0,015 |
| M1 + regiões intermediárias (7) | ok | 2,15 (1,81–2,55) | 1,19 (1,08–1,32) | 0,0005 | −13,3 | 0,00033 | **I = 0,020; p = 0,25** |
| M2 + lon/lat | ok | 2,17 (1,83–2,59) | 1,16 (1,06–1,28) | 0,0023 | −5,5 | 0,00052 | I = 0,071; p = 0,023 |
| M3 + superfície 2ª ordem | ok | 2,14 (1,81–2,55) | **1,21 (1,10–1,33)** | **0,0001** | **−14,7** | **0,00021** | **I = 0,038; p = 0,13** |
| M4 + efeito espacial | **degenerado** (`pdHess` = FALSE, AIC = NA) | idêntico a M0 | idêntico a M0 | — | — | — | idêntico a M0 |

* **TRV contra M0:** regiões intermediárias (6 gl) χ² = 25,3, p = 0,0003; lon/lat (2 gl) χ² = 9,54, p = 0,0085; superfície (5 gl) χ² = 24,7, p = 0,00016. **Existe diferença geográfica real** na probabilidade de baixo peso, além dos dois preditores.
* **Divisão regional usada em M1:** o `read_meso_region(year = 2010)` não existe na sua versão do `geobr` (só há 2000, 2001, 2013–2022). O script caiu na **região intermediária (IBGE 2019)**, com 7 regiões: Blumenau (60 municípios), Caçador (16), Chapecó (109), Criciúma (44), Florianópolis (17), Joinville (25), Lages (24). **Chame de "região intermediária", não de mesorregião**, nos slides.
* **Regras pré-definidas:** (1) OR muda < 10%: **sim** (mult10 −2,8% a −4,2%; pre10 +0,2% a +3,9%) e p < 0,05 se mantém: **sim**, em M1, M2 e M3; (2) `pre10` **não** perdeu significância (ficou mais forte em M1 e M3); (3) razão de EP > 1,2: **não** (0,93–0,98: os EP não aumentaram, ficaram até um pouco menores); (4) M4 não convergiu: **não é usado**.
* **M4 (por que descartar):** a variância do efeito espacial estimada é ≈ 10⁻⁶ (DP 0,001) e as correlações entre posições ≈ 0, os coeficientes são idênticos aos de M0 até a 5ª casa e o Moran idêntico: o otimizador colapsou o efeito espacial para zero e `pdHess` = FALSE. Provável causa: o beta-binomial já tem um parâmetro de variância extra, e os dois efeitos disputam a mesma variação. **Não reporte M4 como resultado**; no texto diga "tentei um efeito espacial aleatório exponencial, mas o modelo não convergiu de forma confiável".
* **Diferenças entre regiões (descritivo, médias entre municípios):**

| Região intermediária | Municípios | Taxa agregada | média `pre10` | média `mult10` |
|---|---|---|---|---|
| Blumenau | 60 | 7,7% | 0,76 | 0,25 |
| Caçador | 16 | **10,1%** | **0,47** | **0,40** |
| Chapecó | 109 | 9,2% | 0,83 | 0,21 |
| Criciúma | 44 | 8,5% | 0,83 | 0,25 |
| Florianópolis | 17 | 7,6% | 0,90 | 0,17 |
| Joinville | 25 | 7,9% | 0,70 | 0,31 |
| Lages | 24 | 9,3% | 0,77 | 0,25 |

  **Leitura (hipótese, não teste):** a região de Caçador tem a **maior taxa** e a **maior** proporção de gestação múltipla, mas a **menor** de pré-natal insuficiente. Isso sugere que, sem controlar a região, parte do sinal de `pre10` é "mascarado" (região com taxa alta e `pre10` baixo), e por isso a OR de `pre10` **sobe** ao controlar região (1,16 → 1,19) ou superfície (→ 1,21). Há também uma diferença Oeste/Planalto (taxas ≈ 9%) × Leste/litoral (≈ 7,6–7,9%), coerente com o mapa de resíduos do D10.
* **O achado mais informativo (ρ):** com as regiões, ρ cai de 0,00103 para 0,00033 (≈ −68%) e com a superfície para **0,00021 (≈ −80%)**. Ou seja, **grande parte da heterogeneidade extra entre municípios que o beta-binomial absorvia é tendência geográfica**. Isso não invalida o modelo final (a superdispersão continua existindo para M0, e foi o que justificou o beta-binomial), mas muda a **interpretação**: boa parte da "variação não explicada" é espacial, e vale uma frase na discussão.
* **Moran:** com as regiões intermediárias (M1) o Moran cai para **0,020 (p = 0,25; 5 vizinhos: 0,013, p = 0,30)** e com a superfície (M3) para 0,038 (p = 0,13): em ambos o agrupamento espacial residual deixa de ser detectável. Lon/lat linear (M2) absorve pouco (0,071). **Ou seja, a dependência espacial que o Moran viu era, em grande parte, diferença entre regiões.** Obs.: a vizinhança de 5 aqui usa coordenadas projetadas (UTM) e difere um pouco da do D10 (final: I = 0,068, p = 0,024, contra 0,082 e 0,010); **a contiguidade é idêntica** (0,077; p = 0,015). Cite os valores do D12 e a contiguidade como principal; a conclusão (I pequeno e significativo) não muda.
* **Critérios de informação:** o AIC prefere M3 (−14,7) e M1 (−13,3), mas o BIC prefere M0 (M3 é 3,7 pior; M1 é 8,8 pior; M2 é 1,8 pior). M1 e M3 empatam em ajuste (AIC 1374,1 × 1372,7). Para **apresentar**, M1 é mais fácil de explicar ("mesmas regiões do estado") e M3 é mais flexível; mostre os dois. Com 295 municípios e 5–6 gl extras, não há base para trocar o modelo.
* **Decisão:** **o modelo final continua M0.** Coordenadas não são um preditor de interesse substantivo do tema e mudariam o estimando; D12 mostra que as conclusões **não dependem** do tratamento do espaço. `mult10` fica em 2,14–2,24 e `pre10` em 1,16–1,21 (M1: 2,15 e 1,19), ambos significativos. **Isto atualiza a leitura anterior**: `pre10` não é frágil ao espaço (só ao tipo de família e à definição de pré-natal, como na C).
* **Figura:** `D12_forest_espacial.png` (M0–M3). **Legenda sugerida:** *"OR por +10 p.p. e IC 95% (Wald). M4 (efeito espacial aleatório) foi ajustado, mas não convergiu e foi omitido."*
* **Frase para a banca:** *"Como o Moran apontou dependência espacial fraca, refiz o modelo com a região intermediária e com a posição geográfica (linear e superfície quadrática). Há diferenças regionais significativas, mas as razões de chances mudam menos de 5% e continuam significativas; o efeito de pré-natal até se fortalece (OR 1,19 a 1,21), e o Moran deixa de ser significativo. Portanto as conclusões não dependem da dependência espacial."*

**Ressalva a manter na discussão:** a diferença geográfica (região ou superfície) explica 68–80% da correlação intraclasse (ρ) do beta-binomial: parte da "heterogeneidade não explicada" entre municípios é espacial.

#### Desenho do D12 (definido antes de ver os resultados)

* **Pergunta:** o Moran mostrou dependência espacial fraca nos resíduos (I ≈ 0,08). Isso muda as conclusões sobre `pre10` e `mult10`? Precisamos separar duas coisas: **(a)** os **erros-padrão** estavam otimistas? **(b)** as **estimativas** mudam quando se controla a região?
* **O que:** cinco versões do beta-binomial, todas com ligação logito:

| Modelo | O que acrescenta | Ideia em uma frase |
|---|---|---|
| M0 | nada (modelo final) | referência |
| M1 | região intermediária IBGE (efeito fixo; 7 regiões de SC; o plano inicial era mesorregião, indisponível no `geobr`) | compara municípios **dentro** da mesma região; checa confusão regional |
| M2 | longitude e latitude (linear) | tendência geográfica simples (ex.: leste–oeste) |
| M3 | superfície quadrática de lon/lat (5 gl) | tendência geográfica suave e curva |
| M4 | efeito aleatório espacial exponencial | correlação que decai com a distância; é a correção "de verdade" da dependência |

* **Alternativas descartadas:** modelos espaciais bayesianos (INLA/BYM) — fora do escopo do curso e do prazo; ponderar por vizinhança — não resolve a dependência do modelo; SAR/CAR para binomial agrupada — implementação menos direta no R. M1–M3 são fixos e simples; M4 é o único com estrutura espacial no erro.
* **Por que quatro versões:** nenhuma é "a verdadeira"; se **todas** dão conclusões parecidas, a conclusão não depende da forma de tratar o espaço. Os efeitos fixos (M1–M3) mudam o **estimando** (OR "ajustada pela região/localização"), o M4 mantém o estimando e corrige a **incerteza**.
* **Regra escrita antes de ver os números:**
  1. Conclusão robusta: OR muda menos de ~10% **e** p < 0,05 se mantém.
  2. Se `pre10` perder significância em algum modelo, reportar que a evidência de `pre10` depende do controle regional/espacial.
  3. Razão entre o EP do modelo e o EP de M0 > ~1,2 → o EP do modelo final estava otimista; usar o EP maior como referência no texto.
  4. M4 só vale se `pdHess` = TRUE; se não convergir, registrar "M4 não convergiu" e apoiar-se em M1–M3 (sem inventar resultado).
* **Como interpretar (para a banca):**
  * M1–M3 respondem "a associação com `mult10` e `pre10` **persiste** quando comparamos municípios da mesma região/vizinhança?". Se a OR de `pre10` cair, parte do efeito era **diferença entre regiões** (confusão geográfica), não relação "dentro" da região.
  * M4 responde "os p-valores e ICs continuam parecidos quando se modela a correlação espacial?".
  * O Moran dos resíduos de cada modelo (bloco 5) mostra **quanto da dependência cada versão absorve**. No M4 há dois Moran: o **marginal** (parte fixa, comparável com M0) e o **condicional** (depois do efeito espacial; deve ficar ~0 por construção, então não é evidência independente).
* **Riscos:** (i) a região intermediária tem 7 níveis (a de Caçador só tem 16 municípios); regiões são grandes e heterogêneas; (ii) M3 usa 5 graus de liberdade extras; (iii) M4 pode não convergir ou ter parâmetros mal identificados, pois o beta-binomial já tem um parâmetro de variância extra; (iv) mudança de estimando: OR de M1–M3 **não é diretamente comparável** em interpretação com a de M0 (é "condicional à região/posição"); (v) seleção e inferência nos mesmos dados continua valendo.
* **O que NÃO muda:** o modelo final do trabalho continua sendo **M0**. D12 é uma checagem de robustez; só mudaria algo se `mult10` desaparecesse (improvável) ou se `pre10` mudasse de forma qualitativa, e mesmo assim a decisão seria reportar, não trocar o modelo.
* **Onde entra no trabalho:** um slide de robustez (forest plot `D12_forest_espacial.png`) ou apêndice; uma linha em limitações.

---

## 4. O que a Etapa D alimenta

| Saída da D | Uso adiante |
|---|---|
| Envelope e φ por classe de `n` | **F:** slide "diagnóstico" |
| Linearidade (parciais, splines) | **E:** justifica preditores lineares; restringir o gráfico de probabilidades ao suporte (`mult10` ≤ 17,4 p.p.) |
| Influência e sensibilidade | **E/F:** slide de robustez |
| VIF | **F:** uma linha no slide |
| Moran e mapa | **F:** limitação; mapa para slide ou apêndice |
| D12 (forest plot, regiões, superfície) | **E/F:** slide de robustez (ou apêndice) e uma frase sobre ρ e diferenças regionais |

**Slides candidatos (3 a 4 de 10–20):** (1) envelope simulado + φ por classe (binomial × beta-binomial); (2) resíduos × preditores e parciais; (3) influência (DFBETAS) + tabela de sensibilidade; (4) Moran + mapa. VIF, DHARMa e demais gráficos vão para o apêndice.

---

## 5. Pendências

Nenhuma. Itens resolvidos nesta etapa:
1. **Arroio Trinta × Capão Alto:** coincidência (`cod6` 420160 e 420325 distintos; mesmos valores).
2. **M1 do D12:** rodou com **região intermediária** (a mesorregião 2010 não existe na sua versão do `geobr`); rótulo corrigido no script.
3. **Figura do D12:** regenerada com M0, M1, M2 e M3 (M4 omitido, documentado).

**Para a Etapa E (lembretes vindos da D):** gráfico de probabilidades restrito ao suporte observado de `mult10` (≤ 17,4 p.p.); apresentar o modelo final M0 e, como robustez, as OR de M1–M3; ICs de Wald e de perfil; OR por +10 p.p. e por +1 DP.

---

## 6. Perguntas que a banca pode fazer (e respostas curtas)

1. **"Por que resíduo quantílico e não o de deviance?"** Com resposta discreta e médias pequenas, deviance e Pearson não são normais mesmo com modelo correto; o quantílico é N(0,1) se o modelo está certo. No beta-binomial: média 0,003, DP 0,997.
2. **"O que é o envelope?"** A faixa que o próprio modelo geraria por acaso (99 simulações com reajuste). Nenhum dos 295 resíduos saiu dela.
3. **"Como sabe que o beta-binomial resolveu a superdispersão?"** Pela dispersão por classe de tamanho: no binomial chega a 2,5 nos 28 maiores; no beta-binomial fica entre 0,96 e 1,15. O φ global cai de 1,28 para 1,05.
4. **"Algum município muda o resultado?"** Não decisivamente. Máximo de 0,52 erro-padrão (Morro Grande, em `mult10`); a OR de `mult10` varia de 2,14 a 2,35 e a de `pre10` de 1,13 a 1,24 nos cenários.
5. **"Por que não excluiu os influentes?"** São municípios reais, sem erro de dado, e as orientações pedem avaliar o impacto, não excluir.
6. **"E a linearidade?"** Resíduos parciais, splines (p = 0,51) e teste de η̂² (p = 0,14) não indicam curvatura. Em `mult10`, a cauda acima de 10 p.p. tem muito poucos municípios.
7. **"Há multicolinearidade?"** Não: r = −0,03, VIF = 1,003.
8. **"Municípios vizinhos não são parecidos? Isso viola a independência?"** Sim, levemente: I de Moran ≈ 0,08 (p ≈ 0,01). Os preditores não absorvem esse padrão (Planalto/Meio-Oeste com resíduos positivos; Leste com negativos). É limitação: os erros-padrão podem estar um pouco otimistas, sobretudo o de pré-natal.
9. **"O DHARMa dava dispersão < 1. Está subdisperso?"** Não: no beta-binomial o teste não é significativo (p = 0,13), ao contrário do binomial (p = 0,036).
10. **"Por que Florianópolis não é um problema?"** Porque no beta-binomial os grandes pesam menos: o Cook de Florianópolis cai de 1,66 (binomial) para 0,11.
11. **"Controlou pela região?"** Sim, pela posição geográfica (D12): com região intermediária, lon/lat e superfície quadrática as OR mudam menos de 5% e continuam significativas; o Moran cai para p = 0,13 com a superfície. O Moran deixa de ser significativo com região (p = 0,25) e com superfície (p = 0,13). (O efeito aleatório espacial não convergiu e foi descartado.)
12. **"Isso muda sua conclusão sobre pré-natal?"** Não muda a direção nem a significância, mas confirma que é associação moderada: depende da família, da definição de pré-natal e é a mais afetada pela dependência espacial residual.

---

## 7. Resumo para colar no `plano_geral.md` (Seção 2) e registro de decisões (Seção 8)

**Resumo da Etapa D (concluída em 11/11/2026):** o beta-binomial `pre10 + mult10` descreve bem os dados: resíduos quantílicos com DP 0,997; envelope simulado sem pontos fora; φ de Pearson por classe de `n` entre 0,96 e 1,15 (binomial: até 2,51); DHARMa sem problemas (dispersão p = 0,13); forma funcional linear (splines p = 0,51; η̂² p = 0,14); VIF = 1,003. Nenhum município é decisivo (máx. \|DFBETAS\| = 0,52, Morro Grande; Cook máx. 0,11, Florianópolis, que no binomial teria Cook 1,66); OR de `mult10` 2,14–2,35 e de `pre10` 1,13–1,24 em seis cenários de sensibilidade. **Moran:** I ≈ 0,07–0,08 (p ≈ 0,02, duas vizinhanças): dependência espacial fraca nos resíduos, tratada como limitação. **D12:** com regiões intermediárias, lon/lat e superfície geográfica, OR de `mult10` 2,14–2,17 e de `pre10` 1,16–1,21 (significativas); região e superfície zeram o Moran (p = 0,25 e 0,13) e reduzem ρ em ~70–80%.

| Data | Decisão | Quem |
|---|---|---|
| 11/11/2026 | Diagnóstico por resíduo quantílico (manual + DHARMa), envelope simulado manual e LOO exato; nenhuma exclusão | autor |
| 11/11/2026 | Modelo final **mantido** (beta-binomial, `pre10 + mult10`, lineares, sem termos extras) | autor |
| 11/11/2026 | Moran feito: I ≈ 0,08 significativo → **limitação** (EP possivelmente otimistas, sobretudo `pre10`) | autor |
| 11/11/2026 | Gráfico de probabilidades (E) restrito ao suporte observado de `mult10` (≤ 17,4 p.p.) | autor |
| 11/11/2026 | Sensibilidade espacial (D12) decidida: M1 região, M2 lon/lat, M3 superfície, M4 efeito espacial; modelo final continua M0 | autor |
| 11/11/2026 | D12 concluído: conclusões **robustas** ao controle espacial (M1 regiões intermediárias, M2, M3); M4 descartado (não convergiu); `read_meso_region` indisponível → usadas regiões intermediárias (IBGE 2019); **modelo final = M0** | autor |
| 11/11/2026 | Moran principal citado com contiguidade (I = 0,077; p = 0,015); registrar que ρ cai ~80% com superfície geográfica | autor |
| 11/11/2026 | Etapa D concluída; próxima: Etapa E | autor |
