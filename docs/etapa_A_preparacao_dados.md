# Etapa A — Preparação da base

**Trabalho final CE314 (MLG) · Tema 8 · Baixo peso ao nascer em Santa Catarina (SINASC, 2026)**
Script correspondente: `scripts/01_preparacao_base.R`

> Como usar este documento: ele tem (1) o raciocínio geral, (2) cada decisão numerada (D1…D14) com
> *o que foi feito, alternativas, por que escolhi esta, risco e como explicar em 1 frase*, (3) dicionário
> de variáveis, (4) tabela de resultados para você preencher após rodar o script e (5) perguntas
> prováveis da banca com respostas. Tudo o que está marcado **[PREENCHER]** depende da saída do seu R.

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

**O que o enunciado e as orientações exigem na preparação (e onde cada item foi atendido):**

| Exigência (Temas.pdf / Orientações.pdf) | Onde/como foi atendida |
|---|---|
| Município de residência **da mãe**, não de ocorrência | D2 |
| Período claramente definido; informar fonte, **data de extração** e **período efetivamente coberto** | D1, D3 |
| "Exibir linhas zeradas" e conferir se todos os municípios aparecem | D7 |
| Distinguir zero de informação ausente/ignorada; não converter ignorado em zero | D5, D9 |
| Excluir peso ignorado do denominador e **informar sua frequência** | D5 |
| Remover linhas de total; separar município ignorado e informar quantos registros | D6 |
| Conferir duplicidades, consistência das contagens e perdas | D13 + bloco 7 do script |
| Município sem nascimento elegível (denominador 0) não entra no ajuste | D7 |
| 4 a 8 preditores candidatos, com justificativa | D8 |
| Preditores quantitativos contínuos; **não** transformar % em "alto/baixo" por quartis | D11 |
| Evitar preditores que sejam componentes da resposta ou calculados a partir dela | D8 (exclusões) |
| Compatibilidade temporal (ano de cada variável) | D1 |
| Registrar fonte, definição, unidade e ano de cada variável | Seção 4 deste documento |

---

## 2. Decisões (D1 a D14)

### D1 — Fonte: microdados do SINASC (arquivo `DNSC2026.dbc`) em vez de tabulação do TABNET

* **Decisão:** usar as Declarações de Nascidos Vivos individuais de SC, 2026, baixadas em
  `datasus.saude.gov.br/transferencia-de-arquivos`, lidas com `datasusr::read_datasus_dbc()`.
* **Alternativa:** tabular no TABNET (município de residência × peso ao nascer), como o enunciado descreve.
* **Por que microdados:**
  1. Os preditores municipais pedidos (proporção de mães adolescentes, escolaridade, pré-natal, gestações
     múltiplas) são **calculados a partir dos próprios nascimentos**. Com microdados eu os calculo da *mesma
     fonte, mesmo ano e mesma população* que a resposta → compatibilidade temporal perfeita.
  2. Com o TABNET eu teria de fazer várias tabulações separadas e juntá-las, aumentando o risco de
     inconsistência entre tabelas.
  3. Reprodutibilidade: o script refaz tudo do zero a partir do arquivo bruto.
* **Equivalência:** a tabulação do TABNET é justamente a contagem dos microdados por município; os
  números de sucessos e denominadores são os mesmos que o TABNET produziria (útil como *conferência*:
  se quiser, tabule 1 ou 2 municípios no TABNET e compare com a minha base).
* **Risco:** o enunciado menciona o TABNET; deixe explícito que o resultado é equivalente.
* **Em uma frase:** *"Usei os microdados porque os preditores municipais saem dos mesmos nascimentos da
  resposta, garantindo mesma fonte e mesmo ano."*

### D2 — Unidade geográfica: município de **residência da mãe** (`codmunres`)

* **Decisão:** agrupar por `codmunres` e manter apenas registros com `codmunres` começando por `42` (SC).
* **Por que residência e não ocorrência (`codmunnasc`):** o tema pergunta sobre diferenças entre municípios
  *de residência das mães*; as características (idade, escolaridade…) são das mães residentes; e muitas
  mulheres parem em município-polo diferente do que moram (ocorrência concentraria casos nos polos).
* **Observação do cabeçalho:** nas 6 primeiras linhas aparecem `codmunnasc` de outros estados (ex.: 120040,
  150130) para mães de SC. Isso mostra por que **não** se deve usar ocorrência, e o fluxo de perdas (etapa 2)
  vai mostrar quantos registros do arquivo têm mãe residente fora de SC (se for ~0, o arquivo já está
  organizado por UF de residência).
* **Risco:** se o arquivo `DNSC` fosse por ocorrência, mães de SC que parem fora de SC estariam ausentes
  (**[PREENCHER]** conferir pelo fluxo de perdas e citar como limitação se for o caso).
* **Código de município:** o SINASC usa 6 dígitos (sem o dígito verificador do IBGE); a lista oficial é
  reduzida a 6 dígitos para casar.

### D3 — Período: nascimentos de 2026 (parcial) e comunicação do período efetivo

* **Decisão:** manter só `dtnasc` em 2026 (as orientações pedem o ano mais recente). Reportar o período
  **efetivo** = `min(dtnasc)` a `max(dtnasc)` (o script imprime).
* **Por que importa:** 2026 não terminou. No cabeçalho vemos cadastros até ~31/08/2026 e recebimentos até
  ~01/09/2026, então o arquivo cobre aproximadamente **jan–ago/2026**. **[PREENCHER com a saída]**.
* **Risco/limitação:** os meses finais podem estar incompletos por atraso de notificação (tabela de
  nascimentos por mês no script). Como o atraso tende a ser parecido entre municípios, o efeito sobre a
  *proporção* é menor do que sobre as contagens; mas deve entrar nas limitações.
* **Registros com `dtnasc` de outro ano** (registro tardio de 2025, por exemplo) saem; a quantidade aparece
  no fluxo de perdas.
* **Data de extração:** o script usa a data de modificação do arquivo baixado; **confirme** (é a data do seu
  download) e escreva no slide de dados.

### D4 — Definição da resposta (sucessos, insucessos, denominador)

* `baixo_peso` = `peso < 2500` (g). `demais` = `peso ≥ 2500`. `n_nascidos` = soma, apenas com peso conhecido.
* **Unidade:** o *nascido vivo* (um gêmeo = duas linhas), como no SINASC. Isso é o que o tema define:
  denominador = "nascidos vivos com peso conhecido". Não é "gestações" nem "partos".
* **Nascidos vivos de peso muito baixo** (< 500 g) **não** são excluídos: são nascidos vivos legítimos e
  baixo peso por definição. O script apenas mostra `summary(peso)` para você inspecionar extremos.
* **Em uma frase:** *"Baixo peso é peso < 2.500 g entre nascidos vivos com peso conhecido; os demais são os insucessos."*

### D5 — Peso ignorado: sai do denominador e sua frequência é reportada

* **Decisão:** peso é ignorado se vazio/NA, `0` ou `9999`. Esses registros **não** entram nem como sucesso
  nem como insucesso; contamos quantos são (número e %) e por município (`n_peso_ignorado`).
* **Por que não classificar como "não baixo peso":** seria tratar "não sei" como "normal", subestimando a
  taxa. O tema pede explicitamente para excluir do denominador.
* **Risco:** se o peso ignorado for mais frequente em certos municípios (e/ou em partos de maior risco),
  há viés de seleção. Reporte a % global e verifique se ela é pequena (**[PREENCHER]**).
* **Verificação feita no script:** a tabela de códigos mostra se há outro código de "ignorado" além de
  vazio/0/9999. Se aparecer, ajuste a regra e registre aqui.

### D6 — Município ignorado

* **Decisão:** registros com `codmunres == "420000"` (código SINASC de "município ignorado" de SC) são
  separados e contados, e **não** entram na base municipal (não há como atribuí-los a um município).
* **Por que:** as orientações mandam separar e informar quantos registros não puderam ser atribuídos.

### D7 — Lista oficial dos 295 municípios e tratamento dos zeros

* **Decisão:** partir da lista oficial de municípios de SC (via `geobr`, IBGE) e fazer `left_join` com os
  agregados. Município sem nascimentos recebe `0` (é um **zero real**: nenhum nascimento ocorreu).
* **Por que:** com microdados, município sem nascimento simplesmente não aparece (não há linha). Isso é o
  equivalente ao "Exibir linhas zeradas" do TABNET, e a própria orientação alerta que a opção sozinha não
  garante a integridade da lista; por isso conferimos contra uma lista externa (o script checa que não há
  código nos dados fora da lista e que `nrow == 295`).
* **Denominador 0 → fora do ajuste:** `cbind(0, 0)` não tem informação para a binomial (taxa indefinida).
  Esses municípios ficam em `base_municipal_sc2026_completa.rds` (com flag `entra_no_ajuste = FALSE`) e
  são listados em `output/tabelas/municipios_sem_nascimento.csv`. Em 2026, com 8 meses de dados, é provável
  que haja alguns municípios muito pequenos nesta situação (**[PREENCHER]**).
* **Em uma frase:** *"Zero é diferente de ausente: município sem nascimento tem contagem zero, mas
  denominador zero não informa taxa, então sai do ajuste e eu informo quais são."*

### D8 — Preditores candidatos (e o que ficou de fora de propósito)

Todos são **proporções municipais** calculadas sobre a base de análise (peso conhecido):

| Variável (nome na base) | Definição | Por que é candidata |
|---|---|---|
| `prop_adolescente` | % de mães de 10 a 19 anos | Gravidez na adolescência associada a prematuridade e baixo peso |
| `prop_esc_baixa` | % de mães com < 8 anos de estudo (`escmae` 1–3) | Proxy de condição socioeconômica e acesso a cuidado |
| `prop_prenatal_insuf` | % de mães com < 6 consultas de pré-natal (`consprenat`) | Pré-natal inadequado associado a desfechos perinatais piores |
| `prop_gestacao_mult` | % de nascidos de gravidez dupla/tripla+ (`gravidez` 2–3) | Gestações múltiplas têm peso menor por natureza |
| `prop_mae_35mais` *(extra, opcional)* | % de mães com ≥ 35 anos | Idade materna avançada é fator de risco clássico; permite testar a "outra ponta" da idade |

* O enunciado lista os 4 primeiros; as orientações pedem 4–8 e dizem que "nem todos precisam integrar o
  modelo final". O 5º é uma sugestão minha para enriquecer a seleção; **você pode descartá-lo** sem custo.
* **Deixados de fora de propósito:**
  * **`gestacao` / semanas de gestação (prematuridade):** é o principal determinante do peso. Tende a ser
    *mediador* (parte do caminho que leva ao baixo peso) e é quase uma "consequência/irmão" da resposta;
    incluí-la esconderia os demais efeitos e viola o espírito de "evitar preditores que revelem diretamente
    a resposta".
  * **Apgar, sexo do bebê, malformação, tipo de parto:** são características do recém-nascido/do parto
    (consequências ou simultâneas ao desfecho), não do município como contexto materno.
  * **Qualquer indicador calculado a partir do peso** (óbvio, mas vale dizer na banca).
* **Interpretação (importante):** são associações **entre municípios**. Não se pode concluir que "uma
  mãe adolescente tem maior risco" (falácia ecológica); só que "municípios com maior % de adolescentes
  tendem a ter maior probabilidade de baixo peso".

### D9 — Informação ignorada nos preditores: sai do cálculo da proporção, não vira zero

* **Decisão:** para cada variável, códigos "ignorado" ou fora do domínio válido viram `NA` e a proporção
  municipal é calculada **entre os registros com informação válida** daquela variável
  (`mean(x, na.rm = TRUE)`).
  * Idade válida: 10–59 anos (fora disso, NA).
  * `escmae` válida: 1–5 (9 e vazio → NA). `gravidez` válida: 1–3. `consprenat` válida: 0–98 (99 → NA).
* **Alternativas:** (a) tratar ignorado como categoria própria (aumenta o nº de preditores e quase não há
  informação), (b) imputar. Para variáveis demográficas com ignorados tipicamente raros, usar os válidos é o
  padrão e simples de explicar.
* **Risco:** se a % de ignorado for alta em algum município, a proporção fica instável. O script mostra a %
  global (tabela `qualidade_variaveis.csv`) e quantos municípios ficaram com preditor `NA`
  (**[PREENCHER]**; se houver, o `glm` descartará essas linhas — nesse caso o n do modelo muda e deve ser dito).

### D10 — Definição de "pré-natal insuficiente"

* **Decisão:** `consprenat < 6`, isto é, menos de 6 consultas.
* **Por quê:** o Ministério da Saúde (Programa de Humanização do Pré-natal/Rede Cegonha) recomenda no
  mínimo 6 consultas; é o limiar usual em indicadores nacionais.
* **Por que `consprenat` e não `consultas`:** `consultas` (documentada no PDF de estrutura) vem agrupada em
  faixas (1 nenhuma, 2 de 1–3, 3 de 4–6, 4 de 7+) e **não permite separar 6 de 4–5**. `consprenat` traz o
  número exato. Nas 6 linhas do cabeçalho, `consprenat` (13, 12, 04, 12, 08, 17) é coerente com `consultas`
  (4, 4, 3, 4, 4, 4); o script faz esta checagem para a base inteira.
* **Atenção:** o PDF "Estrutura_SINASC_para_CD" fornecido é de layout antigo e **não descreve** `consprenat`,
  `escmae2010` etc. Confirme no dicionário atual do DATASUS (Estrutura da DN) e cite-o. Se a descrição de
  `consprenat` for diferente de "número de consultas", **esta decisão muda**.
* **Análise de sensibilidade (opcional, Etapa C):** refazer o modelo com `< 7` ou com a definição por
  faixas (`consultas ≤ 2`) e ver se as conclusões mudam.

### D11 — Preditores contínuos, sem categorizar

* **Decisão:** manter as proporções em escala contínua (0 a 1).
* **Por que:** orientações pedem preferir quantitativos contínuos e justificar categorizações; o tema
  proíbe transformar o percentual em alto/baixo por quartis. Categorizar perderia informação e criaria
  pontos de corte arbitrários.
* **Detalhe para a Etapa C:** a escala 0–1 faz o coeficiente representar a mudança associada a
  "100 pontos percentuais"; é melhor reescalar (ex.: por 10 pontos percentuais) *na interpretação*, sem alterar
  a variável. Ficará explicado quando chegarmos lá.

### D12 — Municípios pequenos não são excluídos

* **Decisão:** manter todo município com `n_nascidos > 0`, inclusive os minúsculos.
* **Por que:** a binomial já dá menos peso a municípios com `n` pequeno (variância ∝ π(1−π)/n); excluir
  seria arbitrário e contraria "não excluir por conveniência". O script reporta quantos têm < 30 nascimentos
  e quantos têm 0 casos de baixo peso.
* **Risco:** pode haver **superdispersão** (variabilidade extra-binomial, ex.: municípios diferem por
  fatores não medidos) e possíveis observações influentes; tratamos nas Etapas C e D (quasi-binomial ou
  beta-binomial, diagnóstico), conforme as orientações pedem.

### D13 — Unicidade e duplicidades

* **Decisão:** checar linhas 100% idênticas e `contador` repetido. **Não remover nada automaticamente**;
  se o resultado for ≠ 0, investigar caso a caso e documentar aqui.
* **Nota:** `id` único exigido nas orientações de outros temas; aqui o identificador disponível é
  `contador` (o `numerodn` não está nas colunas do cabeçalho). Gêmeos geram linhas *distintas*, o que é
  correto (D4).
* **[PREENCHER]:** duplicadas = ___ ; contador repetido = ___.

### D14 — Reprodutibilidade

* Dado bruto fica em `data/raw/` **fora do Git** (`.gitignore`): é público, grande e baixável novamente;
  o repositório guarda o *script* e a *data de extração*.
* Scripts numerados (`01_`, `02_`, …) que rodam do início ao fim; parâmetros (cortes, ano, UF) no topo.
* `sessionInfo()` salvo em `output/tabelas/` (versões dos pacotes).
* Verificações com `stopifnot()` no script: se algo estiver inconsistente, ele para.

---

## 3. Estrutura sugerida do repositório

```
.
├── README.md
├── .gitignore                  # inclua: data/raw/  e  *.Rhistory
├── data/
│   ├── raw/                    # DNSC2026.dbc  (NÃO versionar)
│   └── processed/              # base_municipal_sc2026.rds / .csv
├── scripts/
│   └── 01_preparacao_base.R    # (próximos: 02_exploratoria.R, 03_modelagem.R, 04_diagnostico.R)
├── docs/
│   └── etapa_A_preparacao_dados.md
└── output/
    └── tabelas/                # fluxo_perdas.csv, qualidade_variaveis.csv, ...
```

---

## 4. Dicionário da base final (`base_municipal_sc2026.rds`)

| Coluna | Tipo | Descrição | Origem (campo SINASC) | Ano |
|---|---|---|---|---|
| `cod6` | texto | Código IBGE do município (6 dígitos) | `codmunres` | — |
| `nome` | texto | Nome do município | lista IBGE (`geobr`) | 2020 (malha) |
| `n_nascidos` | inteiro | Nascidos vivos com peso conhecido (denominador) | contagem de linhas | 2026 |
| `baixo_peso` | inteiro | Nascidos vivos com peso < 2.500 g (sucessos) | `peso` | 2026 |
| `demais` | inteiro | Nascidos vivos com peso ≥ 2.500 g (insucessos) | `peso` | 2026 |
| `n_peso_ignorado` | inteiro | Peso ignorado (fora do denominador, informativo) | `peso` | 2026 |
| `prop_adolescente` | 0–1 | Mães de 10–19 anos | `idademae` | 2026 |
| `prop_esc_baixa` | 0–1 | Mães com < 8 anos de estudo | `escmae` | 2026 |
| `prop_prenatal_insuf` | 0–1 | Mães com < 6 consultas | `consprenat` | 2026 |
| `prop_gestacao_mult` | 0–1 | Gravidez dupla ou mais | `gravidez` | 2026 |
| `prop_mae_35mais` | 0–1 | Mães com ≥ 35 anos (extra) | `idademae` | 2026 |
| `taxa_baixo_peso` | 0–1 | `baixo_peso / n_nascidos` (**só para descrever/plotar; NÃO é a resposta do modelo**) | derivada | 2026 |
| `entra_no_ajuste` | lógico | `n_nascidos > 0` | derivada | — |

> **Regra de ouro (orientações):** a resposta do modelo é `cbind(baixo_peso, demais)`, não a taxa nem
> categorias dela. A taxa existe só para gráficos.

---

## 5. Resultados da Etapa A — preencher após rodar o script

| Item | Valor |
|---|---|
| Arquivo / data de extração | DNSC2026.dbc / **[__/__/2026]** |
| Período efetivo (primeiro e último nascimento) | **[__ a __]** |
| Registros no arquivo | **[ ]** |
| Mães residentes fora de SC (excluídas) | **[ ]** |
| Nascimentos fora de 2026 (excluídos) | **[ ]** |
| Município ignorado (420000) | **[ ]** |
| Peso ignorado (n e %) | **[ ]** |
| **Nascidos vivos na base de análise** | **[ ]** |
| Total de baixo peso e taxa global (%) | **[ ]** |
| Municípios oficiais / municípios no ajuste / sem nascimento | **295 / [ ] / [ ]** |
| Municípios com < 30 nascimentos | **[ ]** |
| % ignorado: idade / escolaridade / pré-natal / gravidez | **[ ]** |
| Linhas duplicadas / `contador` repetido | **[ ] / [ ]** |

---

## 6. Perguntas prováveis da banca (e respostas curtas)

1. **Por que microdados e não TABNET?** Os preditores municipais saem dos mesmos nascimentos; garante
   mesma fonte e mesmo ano. O resultado é equivalente à tabulação do TABNET. (D1)
2. **Por que residência da mãe?** O tema compara municípios de residência; características e risco são da
   mãe residente; ocorrência concentraria casos nos polos. (D2)
3. **2026 está completo?** Não; cobre até ~agosto. Atrasos de notificação podem afetar os últimos meses;
   entra como limitação. (D3)
4. **O que você fez com peso ignorado?** Saiu do denominador, reportei n e %. Não é "normal", é "não sei". (D5)
5. **Por que não usar a taxa como resposta?** Porque a taxa ignora o tamanho `n_i` de cada município; a
   binomial usa `cbind(sucessos, insucessos)` e pondera corretamente (um município com 3 nascimentos e 1 caso
   não vale o mesmo que outro com 3.000 e 1.000). (Seção 1)
6. **Por que não incluir semanas de gestação, que explica o peso?** É mediadora/quase a própria resposta;
   violaria a regra de não usar preditores que revelem o desfecho. (D8)
7. **Município sem nascimento?** Zero real, denominador zero, sai do ajuste e listo quais. (D7)
8. **Por que o limiar de 6 consultas?** Recomendação mínima do Ministério da Saúde; `consprenat` permite
   isso, `consultas` (faixas) não. (D10)
9. **Os coeficientes valem para a mãe individual?** Não; são associações entre municípios (falácia ecológica). (D8)
10. **E municípios minúsculos?** Mantidos; a binomial já pondera por `n_i`; avaliamos superdispersão e
    influência na modelagem. (D12)
11. **Por que proporções contínuas e não faixas?** Evita perda de informação e cortes arbitrários;
    exigência das orientações. (D11)

---

## 7. Checklist antes de passar à Etapa B

- [ ] Script rodou do início ao fim sem erro (e os `stopifnot` passaram).
- [ ] Seção 5 preenchida com as saídas reais.
- [ ] Conferi a descrição de `consprenat` no dicionário atual do DATASUS (D10).
- [ ] Conferi se há outros códigos de peso ignorado além de vazio/0/9999 (D5).
- [ ] Comparei 1–2 municípios com o TABNET (opcional, mas ótimo argumento na defesa).
- [ ] `commit` com: script, este documento, `output/tabelas/` e `.gitignore` (sem `data/raw`).

**Próxima etapa (B):** análise exploratória (distribuição de `taxa_baixo_peso`, relação com cada preditor
ponderando pelo tamanho do município, correlações entre preditores, mapa/gráficos), ainda sem ajustar o modelo.
