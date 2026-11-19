# Etapa F — Fechamento (Tema 8, baixo peso ao nascer em SC, SINASC 2026)

Arquivos: `slides/slides_tema8_v2.qmd` (slides finais, 26 páginas em PDF) e este documento · Status: **CONCLUÍDA em 18/11/2026**. Slides renderizados e conferidos; faltam apenas enviar o PDF (até 20/11) e ensaiar.

---

## 0. Para que serve esta etapa

As orientações pedem (item f) *"responder ao objetivo, destacar os principais achados e discutir limitações. Evitar conclusões causais. Nas análises municipais, não extrapolar automaticamente as associações para indivíduos"*, e a entrega é **PDF dos slides até 20/11/2026**, para a apresentação de **10 a 15 minutos** (fora do intervalo desconta nota), com 10 a 20 slides principais e o resto em apêndice. A Etapa F entrega: (1) conclusão, (2) slides, (3) roteiro de fala cronometrado, (4) Q&A para o debate, (5) checklist de entrega.

Nenhum número novo foi calculado: todos vêm das Etapas A–E. Os únicos elementos gerados no slide são o gráfico de probabilidades (lido de `E_curvas_prob.csv`) e o forest de robustez (lido de `E_robustez_familias.csv`).

---

## 1. Decisões

Formato: **o que · alternativas · por que · risco · frase para a banca**.

### F1 — Slides em Quarto/Beamer, saída PDF
* **O que:** `slides/slides_tema8.qmd` baseado no template da disciplina, paleta "Saúde/Biostatística", 16:9, Madrid.
* **Alternativas:** PowerPoint; LaTeX puro.
* **Por que:** reprodutibilidade (critério de avaliação), fórmulas nativas, gráficos lidos direto de `output/`.
* **Risco:** falta de figura quebra o layout. O script avisa no console (`FIGURA AUSENTE`) sem derrubar a renderização.
* **Frase:** *"Os slides são gerados por código a partir das tabelas e figuras do próprio trabalho."*

### F2 — Estrutura: título + 17 slides principais + apêndice (A1–A8), 26 páginas
Título · 1 pergunta · 2 dados · 3 resposta e preditores · 4 funil · 5 linearidade · 6 modelo · 7 por que beta-binomial · 8 seleção · 9 resíduos/envelope · 10 influência e espaço · 11 estimativas · 12 probabilidades · 13 pontos percentuais · 14 robustez · 15 limitações · 16 conclusões · 17 perguntas.
* **Por que:** cobre todos os itens da avaliação (problema, dados, modelagem, diagnóstico, resultados, limitações) dentro de 10–20 slides.
* **Risco:** denso para 13–14 minutos. Mitigação: slides 8 e 10 são os mais curtos na fala; cortar o slide 8 (seleção) se o ensaio passar de 15 min.

### F3 — Gráfico de probabilidades com o **mesmo eixo vertical** nos dois painéis (5% a 28%)
* **Por que:** com eixos diferentes o efeito de pré-natal parece tão grande quanto o de gestação múltipla; com o mesmo eixo vê-se que gestação múltipla mexe muito mais (decisão já registrada na E).
* **Risco:** a faixa de `mult10` acima de 10 p.p. fica larga (só 10 municípios); está marcada com linha tracejada.
* **Frase:** *"A faixa é o intervalo de confiança da probabilidade média; não é o espalhamento das taxas municipais."*

### F4 — Pré-natal apresentado como associação **moderada** e gestação múltipla como **forte e estável**
* **Por que:** é o que a Etapa E sustenta: OR do pré-natal oscila com a família (p = 0,004 no beta-binomial; 0,066 no quase-binomial) e com a definição (limiar de 7 consultas: 1,04–1,07).
* **Risco:** a banca perguntar "então é significativo?" (resposta na Seção 5, P5).

### F5 — Resultado em três escalas: OR por +10 p.p., OR por +1 DP e diferença em p.p. de probabilidade
* **Por que:** OR por 10 p.p. é grande para gestação múltipla (DP ≈ 3,3 p.p.); a diferença em p.p. mostra o impacto prático partindo de 8,2%.
* **Risco:** confundir razão de chances com razão de probabilidades (2,24 vs 2,03). Há uma nota no slide 13.

### F6 — Tabelas dos slides com números digitados a partir dos `.md` das etapas
* **Por que:** compatível com PDF/Beamer e conferível linha a linha.
* **Risco:** divergir de um CSV. Mitigação: checklist da Seção 6 (conferir slides 11 e 13 contra `E_coeficientes.csv` e `E_efeitos_probabilidade.csv`).

### F7 — O que vai para o apêndice
Taxas por faixa, calibração, forest de robustez por família, forest espacial, influência, resíduos parciais, resíduos × tamanho, correlações e conferência de dados. São material de resposta ao debate, não da fala.

### F8 — Revisão completa (v1 → v2) antes do envio
* **O que:** conferência slide a slide contra as Etapas A–E, as orientações, o texto do Tema 8 e o material da disciplina.
* **Correções de conteúdo:** (1) +3,6% → **+3,8%** nos 28 maiores (3.277 esperado × 3.158 observado; a base é o observado, como no +1,7% do total); (2) tabela de Moran só com região (0,020) e superfície (0,038), pois o Moran do modelo lon/lat não consta nas saídas; (3) forma funcional citada apenas com os testes do modelo final (splines p = 0,51; η̂² p = 0,14); (4) "+10 p.p. sai do suporte" → "região esparsa", com a linha +8,4 p.p. e razão 2,03 na tabela; (5) `pre10` e `mult10` definidos no slide de preditores.
* **Ajustes de apresentação:** data do rodapé, rodapé enxuto, figuras em colunas, eixo y do gráfico de probabilidades com marcas a cada 5%, apêndice ampliado (A6 e A7).
* **Observações do PDF final (26 páginas):** nenhum slide transbordou; os slides 4 e 15 ficam justos na parte de baixo, mas legíveis.
* **Frase:** *"Revisei cada número dos slides contra as saídas das etapas; os que divergiam foram corrigidos."*

### F9 — Equipe e divisão da fala
* **Situação:** a análise foi conduzida por Clerence; em 18/11 entraram **João Victor P. Goncalves** e **Leonardo E. Sakai** para ajudar na apresentação, e os três constam nos slides. Antes o `plano_geral.md` registrava trabalho individual; foi reescrito (Seção 0) para servir também de guia aos colegas.
* **Regra das orientações:** **todos os integrantes** apresentam e devem estar preparados para explicar as decisões da análise; o grupo debatedor pode perguntar a qualquer um.
* **Divisão sugerida (13:45 no total):** bloco 1 (título a linearidade, ≈ 4:30); bloco 2 (modelo a influência e espaço, ≈ 4:15, o mais técnico); bloco 3 (estimativas a perguntas, ≈ 5:00). Responsáveis a preencher no `plano_geral.md`, Seção 0.6.
* **Risco:** transições ruins e estouro de tempo. Mitigação: combinar a frase de passagem, quem controla o tempo e quem abre o apêndice; ensaiar os três juntos.
* **Frase:** *"Cada integrante apresenta uma parte, mas todos respondem pelo trabalho inteiro."*

---

## 2. Conclusão (texto para o trabalho)

**Objetivo.** Investigar diferenças na probabilidade de baixo peso ao nascer entre os 295 municípios de Santa Catarina (SINASC 2026, 2ª prévia, jan–ago; 64.469 nascidos vivos) e quais características municipais se associam a elas, por regressão binomial agrupada.

**Principais achados.**
1. Existe heterogeneidade real entre municípios além do acaso binomial, e ela **cresce com o tamanho** do município (φ de Pearson de 1,07 a 2,51 no binomial). O modelo beta-binomial com ligação logito a descreve (resíduos quantílicos com DP 0,997, envelope simulado sem pontos fora, φ por classe de tamanho entre 0,96 e 1,15).
2. **Gestação múltipla:** associação forte, positiva e estável. A chance de baixo peso é cerca de 2,2 vezes maior onde essa proporção é 10 p.p. maior (OR 2,24; IC 1,87–2,68), ou 1,30 por desvio-padrão, o que equivale a cerca de **+2,2 p.p.** de probabilidade (IC 1,7–2,7), controlado o pré-natal.
3. **Pré-natal insuficiente:** associação positiva **moderada** (OR 1,16 por 10 p.p.; IC 1,05–1,29; ≈ +0,6 p.p. por desvio-padrão), robusta a observações influentes e ao controle geográfico, mas sensível à família do modelo e à definição de pré-natal insuficiente.
4. Os dois preditores reduzem cerca de metade da heterogeneidade extra (ρ de 0,00191 para 0,00103); boa parte do restante é geográfica.

**Limitações.** Desenho ecológico (sem causalidade e sem extrapolação a indivíduos); dados preliminares com agosto parcial; proporções ruidosas em municípios pequenos; seleção e inferência nos mesmos dados; sensibilidade do pré-natal; dependência espacial residual fraca (Moran ≈ 0,07), com erros-padrão possivelmente otimistas; beta-binomial pesa menos os municípios grandes (esperado cerca de 3,8% acima do observado nos 28 maiores); cauda de gestação múltipla esparsa (10 municípios acima de 10 p.p.); ausência de covariáveis socioeconômicas de contexto.

---

## 3. Roteiro de fala (alvo: 13 a 14 min)

| # | Slide | Tempo | O que dizer (essencial) |
|---|---|---|---|
| 0 | Título | 0:30 | Tema, dados e a pergunta; aviso de que tudo é associação entre municípios. |
| 1 | Pergunta e contexto | 0:45 | Baixo peso < 2.500 g; unidade = município; resposta = par sucessos/insucessos. |
| 2 | Base de dados | 0:50 | SINASC 2ª prévia, 01/09/2026; jan–ago; 3 pesos ignorados; 64.469; validação TABNET sem diferenças. |
| 3 | Resposta e preditores | 0:50 | Sucessos/insucessos; cinco candidatos em 10 p.p.; definir `pre10` e `mult10`; o que ficou de fora e por quê (mediadores). |
| 4 | Funil | 0:55 | Município pequeno oscila por acaso; 24 fora (esperado ≤ 15), 7 de 28 grandes; φ nulo 1,55. |
| 5 | Linearidade | 0:40 | Curvaturas eram dos pequenos; com n ≥ 30 reta e loess coincidem. |
| 6 | Modelo | 0:50 | Beta-binomial, fórmula da variância, logito; por que não usei χ² da deviance. |
| 7 | Por que beta-binomial | 0:55 | Tabela: superdispersão cresce com n e o fator 1+(n−1)ρ reproduz (2,51 vs 2,44); TRV p ≈ 5×10⁻⁶. |
| 8 | Seleção e forma funcional | 0:40 | 32 modelos no beta-binomial; só dois em todos os competitivos; melhor BIC; splines p = 0,51 e η̂² p = 0,14. |
| 9 | Resíduos e envelope | 0:55 | DP 0,997; nenhum ponto fora; φ por classe deixa de crescer (1,15 nos grandes). |
| 10 | Influência e espaço | 0:55 | VIF 1; nenhum DFBETAS chega a 1; ninguém excluído; Moran fraco e absorvido por região. |
| 11 | Estimativas | 0:55 | OR 2,24 e 1,16 por 10 p.p.; 1,30 e 1,08 por DP; ρ cai pela metade. |
| 12 | Probabilidades | 0:55 | Ler o gráfico: 6,8% a ≈ 23% em gestação múltipla; 7,3% a ≈ 10,6% em pré-natal; faixa é IC da média; cauda acima de 10 p.p. é incerta. |
| 13 | Pontos percentuais | 0:40 | +2,2 p.p. e +0,6 p.p. por DP, partindo de 8,2%; OR não é razão de probabilidades. |
| 14 | Robustez | 0:50 | Gestação múltipla estável; pré-natal depende da família e da definição. |
| 15 | Limitações | 0:45 | Ecológico, prévia, seleção, espaço, grandes, covariáveis. |
| 16 | Conclusões | 0:45 | Três conclusões e a frase única. |
| 17 | Perguntas | 0:10 | Agradecer e abrir. |
| | **Total** | **13:45** | Margem de ~1 min dentro do limite de 15. |

**Dicas de ensaio.** (i) Cronometrar três vezes; se passar de 14:30, cortar o slide 8 para uma frase e encurtar o 5. (ii) Nunca dizer "significativo" sem dizer em qual família. (iii) Nunca dizer "causa", "efeito" ou "risco" sem a palavra "associação" e "entre municípios". (iv) Na fala do slide 12, apontar a linha tracejada antes de comentar a cauda.

### Divisão da fala entre os três (sugestão)

| Bloco | Slides | Tempo | Responsável |
|---|---|---|---|
| 1. Abertura, dados e exploratória | 0 a 5 | 4:30 | `[PREENCHER]` |
| 2. Modelo e diagnóstico | 6 a 10 | 4:15 | Clerence (sugestão) |
| 3. Resultados e conclusão | 11 a 17 | 5:00 | `[PREENCHER]` |

**Para os colegas que não fizeram a análise.** Leiam antes o `plano_geral.md` (Seção 0). Em cada slide, saibam dizer: (i) a mensagem em uma frase; (ii) os números em negrito; (iii) o que *não* dizer (causalidade, "significativo" sem modelo, OR como probabilidade). Se travarem em uma pergunta técnica, a resposta segura é a frase curta da Seção 5 e passar a palavra a Clerence.

**Mapa de perguntas por tema.** Simples (qualquer um responde): 1, 11, 12, 14, 15, 16, 17, 21. Técnicas (preferencialmente Clerence; os outros dois sabem a resposta curta): 2, 3, 4, 7, 9, 10, 18, 19, 20, 22.

---

## 4. Conceitos que você precisa dominar para a defesa

| Conceito | Em uma frase |
|---|---|
| **Beta-binomial** | Binomial em que π varia entre municípios segundo uma Beta; variância `nπ(1−π)[1+(n−1)ρ]`. |
| **ρ** | Quanto o risco varia entre municípios além do acaso; pequeno (0,001), mas o fator cresce com n. |
| **Funil** | Taxa × n com a faixa que o acaso binomial permitiria se todos tivessem o mesmo risco. |
| **Resíduo quantílico aleatorizado** | `Φ⁻¹(F(y))`; N(0,1) se o modelo está certo, mesmo com resposta discreta. |
| **Envelope simulado** | Faixa de resíduos que o próprio modelo geraria por acaso (simula e reajusta). |
| **DFBETAS (leave-one-out)** | Mudança padronizada do coeficiente ao retirar um município. |
| **Moran** | Parecença dos resíduos entre vizinhos; ≈ 0 = sem dependência espacial. |
| **OR × razão de probabilidades** | OR 2,24 por 10 p.p. vira 2,03 em probabilidade; o contraste depende do ponto de partida. |
| **IC da probabilidade média** | Incerteza da curva π, não o espalhamento das taxas observadas. |
| **Falácia ecológica** | Concluir sobre indivíduos a partir de dados agregados. |

---

## 5. Perguntas que a banca pode fazer (respostas curtas)

1. **Por que binomial agrupada e não regressão na taxa?** A taxa de um município com 8 nascimentos e a de um com 4.978 têm precisões diferentes; a binomial usa n e mantém a variância π(1−π)/n.
2. **Por que beta-binomial e não quase-binomial?** A superdispersão cresce com n (1,07 a 2,51); o quase supõe φ constante. O beta-binomial reproduz o padrão (2,44 vs 2,51 nos ≥ 500) e tem verossimilhança (TRV p ≈ 5×10⁻⁶, ΔAIC 17,5).
3. **ρ = 0,001 não é desprezível?** Não: o fator é 1+(n−1)ρ; com n ≈ 1.400 passa de 2,4.
4. **Por que não usou o χ² da deviance?** O esperado de casos é < 3 em 31,9% dos municípios; a aproximação não vale. Avaliei por Pearson por classe, resíduos quantílicos e envelope simulado.
5. **O pré-natal é significativo ou não?** No modelo final p = 0,004; no quase-binomial p = 0,066; com limiar de 7 consultas, 0,050. Por isso o apresento como associação moderada e dependente da família e da definição, que resiste a atípicos e à geografia.
6. **Por que só dois preditores?** Quatro dos cinco são quase intercambiáveis pelo AIC; só esses dois aparecem em todos os modelos competitivos e têm o melhor BIC.
7. **A seleção não invalida os p-valores?** Em parte; é limitação declarada. Por isso usei critérios sem p-valor, testes por termo e várias sensibilidades.
8. **Você excluiu outliers?** Nenhum município foi excluído; refiz o modelo sem os mais influentes só para mostrar que as OR não mudam mais de 10%.
9. **E a linearidade?** Resíduos parciais, splines (p = 0,51) e teste de η̂² (p = 0,137) não indicam curvatura.
10. **E a dependência espacial?** Moran fraco (0,077, p = 0,015); com região ou superfície cai (p = 0,13 a 0,25) e as OR mal mudam (2,14–2,17 e 1,16–1,21). O modelo com efeito aleatório espacial não convergiu e foi descartado.
11. **O que significa OR = 2,24?** Entre municípios, onde a proporção de gestações múltiplas é 10 p.p. maior, a chance de baixo peso é cerca de 2,2 vezes maior, fixo o pré-natal. Por desvio-padrão, 1,30.
12. **Em probabilidade, quanto?** +2,2 p.p. (IC 1,7–2,7) por desvio-padrão, partindo de 8,2%.
13. **Por que os pontos fogem tanto da faixa?** A faixa é o IC da probabilidade média; os pontos têm ruído binomial (municípios pequenos) e heterogeneidade.
14. **Isso vale para uma gestante?** Não: desenho ecológico, sem extrapolação individual.
15. **Gestação múltipla causa baixo peso?** O trabalho não mede causa; é associação municipal. Gestação múltipla é fator de risco clínico conhecido, então o sinal é plausível, mas isso não decorre do modelo.
16. **Por que manter agosto, que está incompleto?** A taxa e o perfil de agosto são iguais aos de jan–jul (8,22%); a sensibilidade sem agosto dá as mesmas conclusões (OR 2,30 e 1,16).
17. **Por que a curva de gestação múltipla abre acima de 10 p.p.?** Só 10 municípios; a incerteza é real e a cauda não deve ser extrapolada.
18. **Por que o modelo espera mais casos nos grandes (+3,8%)?** O beta-binomial pesa menos os municípios grandes; é uma contrapartida descrita, sem desvio sistemático por decil.
19. **Por que não incluiu prematuridade ou semanas de gestação?** São mediadores, quase a própria resposta; as orientações proíbem preditores que revelam a resposta.
20. **Por que logito?** Canônica, dá razão de chances; probito e cloglog empatam (ΔAIC < 2), cauchit é pior (+15).
21. **E o peso mínimo de 122 g?** Provável erro de digitação, inócuo (qualquer valor < 2.500 g é baixo peso); não excluído.
22. **Você usou a beta-binomial como na aula (gamlss)?** O modelo é o mesmo; usei `glmmTMB`. A dispersão da aula (θ) e a minha (ρ = 1/(1+φ)) se relacionam por ρ = θ/(1+θ), com φ = 1/θ. Os coeficientes devem coincidir com os do `gamlss(..., family = BB)` (conferência opcional).

---

## 6. Checklist de entrega (até 20/11)

- [x] Scripts de E e figuras/tabelas usados nos slides disponíveis em `output/`.
- [x] Slides renderizados (`slides_tema8_v2.pdf`): 26 páginas, sem figura em branco, sem transbordamento.
- [x] Números dos slides conferidos contra as etapas; correções da revisão aplicadas (F8).
- [x] `plano_geral.md` e este documento atualizados.
- [ ] Conferir o Moran do modelo lon/lat em `D12_moran_por_modelo.csv` (só necessário se quiser citá-lo).
- [ ] Combinar a divisão da fala entre os três e preencher os responsáveis (`plano_geral.md`, Seção 0.6).
- [ ] Os dois colegas leem a Seção 0 do `plano_geral.md` e esta Etapa F (Seções 2 a 5).
- [ ] **Enviar o PDF para cetaconeli@gmail.com antes de 20/11/2026.**
- [ ] Ensaio conjunto dos três, 3 vezes, cronometrando (13–14 min); simular 5 minutos de perguntas com a Seção 5, alternando quem responde.
- [ ] Atualizar o `README.md` (ordem dos scripts `01` a `06` e `05b`).

---

## 7. Pendências após a renderização (resolvidas)

* Nº total de páginas do PDF: **26** (título + 17 slides principais + 8 de apêndice).
* Slides que transbordaram ou precisaram de ajuste: **nenhum**; slides 4 e 15 justos na base.
* Tempo medido nos ensaios (min:s): `[PREENCHER]` (alvo 13–14 min).
* Ordem de apresentação e grupo debatedor (definidos em 27/10): `[PREENCHER]`

---

## 8. Registro de decisões (já colado na Seção 8 do `plano_geral.md`)

| Data | Decisão | Quem |
|---|---|---|
| 14/11/2026 | Slides em QMD (Quarto/Beamer → PDF), paleta Saúde/Biostatística, 17 slides principais + título + apêndice | autor |
| 14/11/2026 | Gráfico de probabilidades com mesmo eixo y; forest de robustez gerado no slide | autor |
| 14/11/2026 | Mensagem: gestação múltipla forte e estável; pré-natal moderada e sensível à família e à definição | autor |
| 14/11/2026 | Roteiro de 13:45 min; cortar o slide de seleção se o ensaio passar de 14:30 | autor |
| 18/11/2026 | Revisão completa v1 → v2 (F8): +3,8% nos 28 maiores; Moran por modelo; forma funcional com testes do modelo final; "região esparsa"; nomes `pre10`/`mult10` definidos | autor |
| 18/11/2026 | Apêndice ampliado para A1–A8; PDF final com 26 páginas | autor |
| 18/11/2026 | Dois integrantes passam a ajudar na apresentação; `plano_geral.md` reescrito com Seção 0 (guia para os colegas); divisão da fala em três blocos (F9) | autor |
| 18/11/2026 | **Etapa F concluída**; próximos passos: enviar PDF até 20/11 e ensaiar | autor |
