# Etapa D — Diagnóstico (Tema 8, baixo peso ao nascer em SC, SINASC 2026)

Script: `scripts/05_diagnostico.R` · Status: **script entregue; aguardando execução no R e conferência das saídas** (resultados marcados `[PREENCHER]`).

> Nada neste arquivo é resultado ainda. As seções "O que esperar" são **hipóteses**; os números reais vêm das suas saídas.

---

## 0. Para que serve esta etapa

As orientações (item d) pedem: *"avaliar resíduos, observações atípicas e influentes, multicolinearidade e adequação da relação funcional. Explicar os problemas encontrados e as decisões tomadas; **não excluir observações apenas por serem influentes**."*

Modelo diagnosticado: `Y_i ~ BetaBinomial(n_i, π_i, ρ)`, `logit(π_i) = β0 + β1·pre10 + β2·mult10`.

A etapa responde seis perguntas:

1. **Distribuição:** o beta-binomial descreve bem a variabilidade (inclusive **por tamanho de município**)?
2. **Parte sistemática:** sobrou padrão nos resíduos contra os preditores? A relação é linear no logito?
3. **Ligação:** o logito está adequado?
4. **Atípicas e influentes:** algum município "manda" no resultado?
5. **Multicolinearidade:** `pre10` e `mult10` se confundem?
6. **Independência:** municípios vizinhos têm resíduos parecidos (Moran)?

**Não** há seleção de variáveis, nem troca de modelo por causa de um único teste, nem exclusão de municípios.

**Entrada:** `base_municipal_sc2026.rds`. **Saídas:** `output/tabelas/D_*.csv`, `output/figuras/D_*.png`, `data/processed/D_diagnostico.rds`.

---

## 1. Resumo executivo (preencher após rodar)

| # | Pergunta | Resposta | Evidência |
|---|---|---|---|
| 1 | Reajuste reproduz a Etapa C? | `[PREENCHER]` (esperado: β_mult 0,805; β_pre 0,151; ρ 0,00103) | bloco 1 |
| 2 | Resíduos quantílicos ~ N(0,1)? | `[PREENCHER]` (DP, nº com \|r\|>2 e >3, KS do DHARMa) | blocos 3 e 4 |
| 3 | Envelope simulado | `[PREENCHER]` pontos fora do envelope | bloco 5 |
| 4 | Padrão por tamanho `n` resolvido? | `[PREENCHER]` φ de Pearson por classe (bb × binomial) | bloco 3 |
| 5 | Forma funcional | `[PREENCHER]` p dos splines e de η̂² | bloco 7 |
| 6 | VIF | `[PREENCHER]` (esperado ≈ 1) | bloco 8 |
| 7 | Influentes | `[PREENCHER]` quais municípios; efeito na OR | blocos 9 e 10 |
| 8 | Moran | `[PREENCHER]` I, p; modelo nulo × final | bloco 11 |

---

## 2. Conceitos que você precisa dominar

| Conceito | Explicação em uma frase | Por que importa aqui |
|---|---|---|
| **Resíduo de Pearson** | `(y − nμ)/√Var(y)`; diferença padronizada pela variância **do modelo**. | No beta-binomial a variância inclui o fator `1+(n−1)ρ`. Se o modelo está certo, tem variância ≈ 1. |
| **Resíduo quantílico aleatorizado** | Passa cada observação pela função de distribuição do modelo e depois pela inversa da normal: `r = Φ⁻¹(F(y))`. Como `y` é discreto, sorteia-se `u` entre `F(y−1)` e `F(y)`. | Se o modelo está certo, `r ~ N(0,1)` **mesmo com resposta discreta** (slides de resíduos). Pearson e deviance não têm essa propriedade com contagens pequenas. |
| **Envelope simulado** | Simula-se muitas respostas sob o modelo ajustado, reajusta-se, e o envelope é a faixa que o acaso permite para os resíduos. | Responde "este padrão residual é compatível com o modelo?", sem depender de normalidade. |
| **Alavancagem `h_ii`** | O quanto a posição de `x_i` (no espaço dos preditores, ponderada) puxa o ajuste. | Município com `x` extremo e muitos nascimentos tem potencial de influenciar. |
| **Distância de Cook** | Mudança global nos coeficientes ao retirar uma observação (≈ resíduo² × alavancagem). | Combina "mal ajustado" com "alavanca". |
| **DFBETAS** | `(β_j − β_j(−i))/EP(β_j)`: mudança **padronizada** em cada coeficiente ao retirar o município `i`. | Responde direto: "este município muda o efeito de `mult10`?". Limiar usual `2/√n` ≈ 0,116. |
| **Leave-one-out (LOO)** | Reajustar o modelo `n` vezes, retirando uma observação por vez. | Aqui é barato (295 refits), então calculamos o **exato** em vez de aproximar. |
| **Resíduo parcial** | `z_i + β_j(x_ij − x̄_j)`, onde `z` é o resíduo de trabalho `(y/n−μ)/(μ(1−μ))`. | Mostra a relação entre `x_j` e o logito **depois de tirar os outros preditores**; se não é reta, há não linearidade. |
| **VIF** | `1/(1−R²_j)`; quanto a variância de `β_j` incha por `x_j` ser explicado pelos outros preditores. | Referência prática: > 5 ou 10 merece atenção. |
| **I de Moran** | Correlação entre o valor de um município e a média dos vizinhos (−1 a +1; ≈ 0 = sem dependência). | Se os resíduos são espacialmente correlacionados, a suposição de independência falha e os EP podem ficar subestimados. |

---

## 3. Decisões e resultados

Formato: **o que · alternativas · por que · risco · frase para a banca · resultado**.

### D1 — Reajustar o modelo final em vez de ler o `C_modelos.rds`

* **O que:** o script reajusta `glmmTMB(cbind(y, demais) ~ pre10 + mult10, family = betabinomial)` e **confere** com a Etapa C (β, ρ, convergência).
* **Alternativas:** carregar `bb_fin` do RDS.
* **Por que:** o script fica independente da estrutura do arquivo e reprodutível; a conferência garante que estamos diagnosticando o mesmo modelo.
* **Risco:** divergência por versão de pacote. O script emite aviso se `β_mult` ou `β_pre` diferirem mais de 0,01.
* **Frase para a banca:** *"O diagnóstico parte do reajuste do modelo final, conferido contra a etapa de modelagem."*
* **Resultado:** `[PREENCHER]`.

### D2 — Resíduo principal: quantílico aleatorizado (calculado à mão **e** pelo DHARMa)

* **O que:** (i) resíduo de Pearson com a variância do beta-binomial; (ii) resíduo quantílico aleatorizado com a função de distribuição beta-binomial (`pbb`, soma da função de probabilidade); (iii) o mesmo via `DHARMa::simulateResiduals`.
* **Alternativas:** só resíduo de deviance/Pearson (aula: não são normais com resposta discreta e médias pequenas — 31,9% dos municípios têm `nπ < 3`).
* **Por que dois cálculos:** o manual é transparente (você consegue explicar a fórmula); o DHARMa é a referência da literatura. Devem concordar nas conclusões.
* **Risco:** o resíduo é **aleatorizado**; outro `seed` muda pontos individuais, não o padrão global. Conclusões devem se basear em padrões persistentes.
* **Frase para a banca:** *"Como a resposta é discreta e os municípios são pequenos, usei resíduos quantílicos aleatorizados, que são normais padrão se o modelo estiver correto."*
* **O que esperar (hipótese):** DP próximo de 1; ~15 pontos com |r| > 2 e ~1 com |r| > 3.
* **Resultado:** `[PREENCHER]` (`D_residuos_resumo.csv`).

### D3 — Envelope simulado **manual** (algoritmo do `hnp`)

* **O que:** 99 simulações de `π_i ~ Beta(μφ, (1−μ)φ)`, `y ~ Binomial(n_i, π_i)`; reajuste do beta-binomial em cada uma; envelope = mínimo e máximo dos |resíduos de Pearson| ordenados.
* **Alternativas:** `hnp::hnp` (não reconhece `glmmTMB` sem funções auxiliares); só DHARMa.
* **Por que:** o `hnp` usa exatamente este algoritmo; refazemos para o beta-binomial. O reajuste dentro de cada simulação é essencial: os resíduos observados vêm de um modelo estimado nos próprios dados.
* **Risco:** com 99 simulações o envelope (mín–máx) cobre ≈ 98%; esperam-se 0–3 pontos fora por acaso.
* **Frase para a banca:** *"O envelope diz quanto de afastamento o próprio modelo produziria só por acaso; pontos dentro dele são compatíveis com o ajuste."*
* **Resultado:** `[PREENCHER]` nº de pontos fora e quais municípios.

### D4 — Resíduos × ajustados, × preditores, × tamanho `n` (pendência 5 da C)

* **O que:** resíduos quantílicos contra `η̂`, `pre10`, `mult10` e `log(n)` com loess; tabela de DP e φ de Pearson **por classe de tamanho**, para o beta-binomial **e** o binomial.
* **Por que:** a razão de escolher o beta-binomial foi a superdispersão **crescer com `n`** (φ 1,07 · 1,13 · 1,23 · 2,51). Se o modelo está certo, φ de Pearson ≈ 1 em **todas** as classes. Este é o teste mais importante da etapa.
* **O que esperar (hipótese):** binomial com padrão por tamanho (φ crescente); beta-binomial sem padrão.
* **Risco:** os 80 municípios `< 30` têm resíduos muito discretos (muitos zeros), então o DP pode ficar < 1 nessa classe mesmo com modelo correto (ver D9).
* **Frase para a banca:** *"A prova de que o beta-binomial corrigiu o problema certo é a dispersão por classe de tamanho: no binomial ela cresce com `n`; no beta-binomial fica estável."*
* **Resultado:** `[PREENCHER]` (`D_residuos_por_classe_n.csv`).

### D5 — Forma funcional e ligação: resíduos parciais, splines e η̂²

* **O que:** (i) resíduos parciais de `mult10` e `pre10`; (ii) teste de razão de verossimilhanças com spline natural de 3 gl (conjunto e individual); (iii) teste de η̂² (acrescentar `η̂²` ao modelo; se significativo, sugere ligação/forma funcional inadequada).
* **Alternativas:** só os quadráticos da C (p = 0,68 e 0,19).
* **Por que:** a C testou uma forma específica (quadrática); o spline é mais flexível e pega curvaturas de outro formato. `mult10` tem cauda esparsa (máx. 17 p.p.), por isso merece a checagem visual extra.
* **Decisão pré-definida:** p > 0,05 em tudo → manter lineares no logito.
* **Risco:** TRV com 295 observações e municípios pequenos tem pouco poder; por isso os parciais complementam.
* **Frase para a banca:** *"A linearidade foi checada por três caminhos independentes: resíduos parciais, splines e o teste de η̂²."*
* **Resultado:** `[PREENCHER]` (`D_forma_funcional.csv`).

### D6 — Influência: aproximada **e** leave-one-out exato

* **O que:** alavancagem e Cook aproximados (pesos de quasi-verossimilhança do beta-binomial), e **LOO exato** (295 refits) com DFBETAS para `pre10` e `mult10` e variação na OR; comparação com `cooks.distance` do binomial.
* **Alternativas:** só `influence.measures` do binomial (não representa o modelo final).
* **Por que:** `glmmTMB` não traz medidas de influência prontas; como o refit é rápido, o LOO exato é a medida mais honesta e responde diretamente à pergunta de interesse ("muda o efeito?").
* **Limiares (heurísticos):** alavancagem `> 2p/n` ≈ 0,020; DFBETAS `> 2/√n` ≈ 0,116 (esperam-se ~5% acima por acaso, então ~15 municípios acima **não** é problema por si só); Cook: comparar entre si.
* **Quem vigiar (da B/C):** Painel, Marema, Presidente Nereu, Braço do Trombudo (minúsculos, fora do funil) e os 28 municípios `>= 500`.
* **Risco:** o beta-binomial já reduz o peso dos grandes; a influência dos grandes pode ser **menor** que no binomial.
* **Frase para a banca:** *"Medi a influência refazendo o ajuste sem cada município e olhando quanto o coeficiente muda em unidades de erro-padrão."*
* **Resultado:** `[PREENCHER]` (`D_influentes_*.csv`, figuras `D_influencia.png` e `D_alavancagem_x_residuo.png`).

### D7 — Sensibilidade a atípicos/influentes: **reportar, não excluir**

* **O que:** reajustar sem (1) as 5 de maior DFBETAS; (2) as 5 de maior Cook; (3) os 4 minúsculos do funil; (4) os 28 maiores; (5) `n < 30`; (6) \|r quantílico\| > 2.
* **Regra escrita antes de ver os números:** reportar qualquer cenário em que a OR de `mult10` ou de `pre10` mude mais de ~10% ou em que a significância mude. **O modelo final continua com os 295 municípios.**
* **Por que:** as orientações proíbem excluir só por influência; mas pedem que o impacto seja avaliado e discutido.
* **Risco:** o cenário 6 (cortar por resíduo) é "olhar o resultado e podar"; está lá só como estresse, e deve ser descrito assim.
* **Frase para a banca:** *"Nenhuma observação foi excluída. Refiz o modelo sem os municípios mais influentes só para mostrar que as conclusões não dependem deles."*
* **O que esperar (hipótese):** `mult10` estável (como na C); `pre10` mais sensível, como já sabemos.
* **Resultado:** `[PREENCHER]` (`D_sensibilidade_atipicos.csv`).

### D8 — Multicolinearidade

* **O que:** VIF do modelo final (e do completo com 5, só como referência), correlação `pre10 × mult10` e número de condição.
* **Por que:** correlação entre `pre10` e `mult10` ≈ −0,03 → VIF ≈ 1. É confirmação formal, exigida pelas orientações.
* **Frase para a banca:** *"Os preditores finais são praticamente ortogonais (r ≈ −0,03; VIF ≈ 1), então os coeficientes não competem entre si."*
* **Resultado:** `[PREENCHER]` (`D_vif.csv`).

### D9 — O resultado estranho do DHARMa (pendência 1 da C)

* **O problema:** `testDispersion` do DHARMa deu 0,86–0,91 (< 1), na contramão do φ de Pearson (1,28 no binomial).
* **Explicação a verificar:** a estatística do DHARMa é o DP dos resíduos quantílicos. Com 80 municípios minúsculos (muitos com 0 casos), os resíduos quantílicos são muito discretos e o DP desses municípios fica < 1 mesmo num modelo correto; como são 27% dos municípios, puxam o DP global para baixo. Já o φ de Pearson é dominado pelos **grandes**, onde está a superdispersão.
* **Como o script verifica:** o DP dos resíduos quantílicos **por classe** (bloco 3). Se for < 1 só em `< 30` e ≈ 1 nas demais, a explicação se confirma. Se o DP de `>= 500` continuar > 1 no beta-binomial, há superdispersão residual real.
* **Frase para a banca:** *"O teste do DHARMa resume dispersão em um número que mistura municípios muito pequenos e muito grandes; por isso olhei a dispersão por classe de tamanho, onde o padrão fica claro."*
* **Resultado:** `[PREENCHER]`.

### D10 — Moran nos resíduos: **fazer**

* **Decisão sobre a opcional:** recomendo **fazer** (código pronto, poucos minutos). Motivos: (i) a Etapa B achou 18 de 24 municípios fora do funil **acima** da taxa global, vários no Meio-Oeste/Planalto; (ii) é uma suposição do modelo (independência) que a banca pode perguntar; (iii) se falhar o download, vira limitação sem perder nada. Dá para desligar com `FAZ_MORAN <- FALSE`.
* **O que:** I de Moran e teste (normal e Monte Carlo com 9.999 permutações) nos **resíduos de Pearson** do modelo final, com dois critérios de vizinhança (contiguidade "rainha" e 5 vizinhos mais próximos), e os mesmos no **modelo nulo** para ver quanto da estrutura espacial os preditores absorvem; mapas dos resíduos.
* **Por que Pearson e não quantílico:** o Pearson é determinístico; o quantílico muda com o sorteio (incluído só como conferência).
* **Risco:** a definição de vizinho altera o resultado (por isso duas); Florianópolis (ilha) pode ficar sem vizinhos na contiguidade (`zero.policy`); municípios pequenos com resíduos ruidosos diluem o sinal.
* **Como interpretar:** I ≈ 0 e p > 0,05 → sem evidência de dependência espacial. I > 0 com p < 0,05 → vizinhos têm resíduos parecidos: os EP podem estar **subestimados**; **não muda o modelo final**, entra como **limitação** (e, no máximo, sugestão: acrescentar covariável regional/modelo espacial em trabalho futuro).
* **Frase para a banca:** *"Testei se municípios vizinhos têm resíduos parecidos. [resultado]. Se houvesse dependência, os erros-padrão estariam subestimados, e isso entraria como limitação."*
* **Resultado:** `[PREENCHER]` (`D_moran.csv`, mapas `D_mapa_residuos*.png`).

### D11 — O que **não** fazemos

| Não fazemos | Motivo |
|---|---|
| Excluir municípios do modelo final | Orientações |
| Trocar o modelo por causa de um teste isolado (ex.: DHARMa) | Evidência principal é o conjunto: envelope, φ por classe, resíduos × x |
| Refazer a seleção de variáveis | Etapa C já fechada |
| Usar χ² da deviance para "qualidade do ajuste" | Alerta A4 |
| Interpretar p-valor do Shapiro dos resíduos aleatorizados como veredito | Descritivo apenas |
| Resultados finais (ICs, gráfico de probabilidades) | Etapa E |

---

## 4. O que a Etapa D alimenta

| Saída da D | Uso adiante |
|---|---|
| Envelope, resíduos por classe, DHARMa | **F:** slide "diagnóstico" (envelope + resíduos × tamanho) |
| Forma funcional (parciais, splines) | **E/F:** justificativa de preditores lineares |
| Influência e sensibilidade | **E:** slide de robustez; **F:** limitações |
| VIF | **F:** uma linha no slide de diagnóstico |
| Moran | **F:** limitação (ou ausência dela) |

**Slides candidatos da D (3 a 4 de 10–20):** (1) envelope simulado + φ por classe de tamanho; (2) resíduos × preditores + parciais; (3) influência (DFBETAS) + sensibilidade; (4) Moran + mapa (se feito). O resto vai para o apêndice.

---

## 5. Como rodar e o que me enviar

1. Raiz do repositório como working directory; salvar o script em `scripts/05_diagnostico.R`; instalar se faltar: `glmmTMB`, `DHARMa`, `car`, `patchwork`, `splines` (já vem no R) e, para Moran, `geobr`, `sf`, `spdep`.
2. Rodar de cima para baixo (3 a 10 min; o LOO e o envelope reajustam o modelo centenas de vezes).
3. Colar no chat as saídas dos blocos: **1** (conferência com a C), **3** (resíduos e `por_classe`), **4** (DHARMa), **5** (envelope e municípios fora), **7** (forma funcional), **8** (VIF), **9** (tabelas de influentes), **10** (sensibilidade), **11** (Moran) e **12** (síntese).
4. Se algum `warning` aparecer (principalmente "O reajuste NÃO reproduz a Etapa C"), mande-o primeiro: nesse caso paramos antes de interpretar qualquer coisa.
5. As figuras `D_*.png` eu não vejo sozinho: descreva ou anexe as principais (`D_envelope_bb`, `D_residuos_x`, `D_residuos_parciais`, `D_influencia`, mapa).

---

## 6. Perguntas que a banca pode fazer (e respostas curtas)

1. **"Por que resíduo quantílico e não o de deviance?"** Com resposta discreta e médias pequenas, deviance e Pearson não são normais mesmo com modelo correto; o quantílico aleatorizado é N(0,1) se o modelo está certo.
2. **"O que é o envelope?"** A faixa de resíduos que o próprio modelo geraria por acaso, obtida simulando e reajustando; pontos dentro = compatível.
3. **"Como sabe que o beta-binomial resolveu a superdispersão?"** Pela dispersão por classe de tamanho: no binomial cresce com `n`; no beta-binomial fica ~1. `[confirmar com a saída]`
4. **"Algum município muda o resultado?"** Medi com leave-one-out e DFBETAS; refiz o modelo sem os mais influentes e sem os grupos suspeitos; as OR mudaram `[PREENCHER]`. Ninguém foi excluído.
5. **"Por que não excluiu os outliers?"** Orientação do curso e boa prática: só se for erro de dado; aqui são municípios reais.
6. **"E a linearidade?"** Resíduos parciais, splines (3 gl) e teste de η̂² não indicam curvatura `[confirmar]`.
7. **"Há multicolinearidade?"** Não: r ≈ −0,03 e VIF ≈ 1.
8. **"Municípios vizinhos não são parecidos? Isso não viola a independência?"** Testei com Moran: `[PREENCHER]`. Se houver dependência, é limitação: EP possivelmente subestimados.
9. **"O DHARMa dava dispersão < 1. O modelo está subdisperso?"** Não; a estatística mistura muitos municípios minúsculos com resíduos discretos; a análise por classe de tamanho é mais informativa. `[confirmar]`
10. **"O diagnóstico muda sua conclusão sobre pré-natal?"** `[PREENCHER]` Já sabíamos que `pre10` é moderada e sensível; a D mostra se algum município ou a forma de ponderar a explica.

---

## 7. Registro de decisões (colar na Seção 8 do `plano_geral.md` após preencher)

| Data | Decisão | Quem |
|---|---|---|
| 10/11/2026 | Etapa D: resíduo principal = quantílico aleatorizado (manual + DHARMa); envelope simulado manual com 99 reajustes | autor |
| 10/11/2026 | Influência por LOO exato + DFBETAS; **nenhuma exclusão**; cenários de sensibilidade apenas para reportar | autor |
| 10/11/2026 | Moran: **fazer** (contiguidade e 5 vizinhos; modelo final e nulo); se significativo → limitação | autor |
| `[PREENCHER]` | Conclusões do diagnóstico (adequação, influentes, Moran) | autor |
| `[PREENCHER]` | Etapa D concluída; próxima: Etapa E | autor |
