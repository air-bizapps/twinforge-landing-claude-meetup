# TwinForge Landing Page — Design

**Data:** 2026-08-06
**Contexto:** Landing de apresentação do TwinForge no Claude Meetup, sob a identidade AI/R.
**Fonte de conteúdo:** https://docs.twinforge.webjump.ai/ (Plataforma, WatchTower, Agentes Forjados, Crucible CLI, Suite)

---

## 1. Decisões travadas

| Decisão | Escolha |
|---|---|
| Versão de marca | AI/R standalone + tagline "Agentic AI Software Engineering" |
| Idioma | Português, termos técnicos e nomes de produto em inglês |
| Stack | `index.html` único com CSS inline, sem build step |
| Ângulo | Equilibrado — tese técnica, produto, arquitetura, outcomes |
| Menção ao evento | Faixa discreta no topo: "Apresentado no Claude Meetup" (sem data/local) |
| Logo | SVG oficial extraído de aircompany.ai, inline no HTML |

## 2. Entregáveis

```
index.html                       # página completa, CSS inline
assets/
  air-logo.svg                   # logo header oficial (99×32, O₂ + wordmark)
  air-logo-full.svg              # logo footer oficial (164×79)
  favicon.svg                    # símbolo O₂
  fonts/RobotoMono-{Light,Regular,Medium,Bold}.woff2
docs/superpowers/specs/2026-08-06-twinforge-landing-design.md
```

Sem `package.json`, sem bundler. A página abre por duplo clique e funciona offline.

## 3. Sistema visual

### Cor

Dark-first, espelhando aircompany.ai. Paleta primária do guideline AI/R:

| Token | HEX | Uso |
|---|---|---|
| `--ink` | `#0C0C0C` | Fundo base |
| `--ink-2` | `#141414` | Superfícies elevadas (cards) |
| `--line` | `#383838` | Bordas, réguas, hairlines |
| `--mute` | `#A7A7A7` | Texto secundário |
| `--text` | `#E9E9E9` | Texto primário |
| `--white` | `#FFFFFF` | Títulos, wordmark |
| `--accent` | `#D7EF25` | Acento único (lime do Forge AI) |

Um único acento, escolhido por amarração semântica: `#D7EF25` é a cor do Forge AI na paleta de plataformas AI/R, e TwinForge herda o "Forge". Usado em: numeração de seções, `↗`, borda ativa de card, CTA primário, nós ativos do diagrama. Nunca em bloco grande de fundo — o guideline trata cores de plataforma como uso contextual, não como elemento primário de marca.

### Tipografia

- **Corpo:** `Neue Haas Grotesk Display Pro` → fallback `Helvetica Neue, Helvetica, Arial, sans-serif`. A fonte é licenciada; não é redistribuída no repo. O fallback é nativo em macOS e visualmente próximo.
- **Títulos, labels, callouts técnicos:** `Roboto Mono`, servido local via `@font-face` a partir de `assets/fonts/` nos pesos 300/400/500/700.

Escala fluida com `clamp()`. Títulos de seção em Roboto Mono uppercase com `letter-spacing` negativo leve; labels em Roboto Mono 11–12px uppercase com tracking positivo.

### Elementos gráficos (do guideline)

- Blocos repetidos / estrutura isométrica no hero, em CSS e SVG
- Linhas finas (hairlines) ligando a numeração `01…07` ao título da seção
- Caixas modulares retangulares para os cards da suite
- Seta diagonal `↗` como ícone de link e CTA
- Overlay de textura grain via `<svg><feTurbulence>` em `::before` fixo, opacidade baixa

### Acessibilidade e responsividade

- Contraste mínimo AA em todo texto (`--mute` sobre `--ink` = 7.3:1)
- Um só `<h1>`; hierarquia `h2`/`h3` sem salto
- Diagrama SVG com `role="img"` e `<title>`/`<desc>`
- Breakpoints em 1024px, 768px e 520px; grids colapsam para coluna única
- `prefers-reduced-motion` desliga todas as transições e reveals
- Sem scroll horizontal em nenhuma largura ≥ 320px

## 4. Estrutura da página

### Faixa de evento

Linha única no topo, altura mínima, borda inferior hairline: `Apresentado no Claude Meetup`. Marcada com `data-event-banner` e comentário no HTML, para remoção em um passo quando a landing for reaproveitada.

### Header

Logo AI/R inline + tagline "Agentic AI Software Engineering". Nav com âncoras para as seções. Sticky com fundo translúcido e blur.

### 01 — Hero

- Eyebrow em mono: `TwinForge · AI/R`
- `h1`: **A suite para operar empresas movidas a agentes de IA**
- Sub: digital twins, expertise real, desenvolvimento autônomo. Control plane, observabilidade de frota, catálogo de especialistas e workbench de terminal.
- CTAs: primário (slot de inscrição, hoje → docs) e secundário (→ `#suite`)
- Visual à direita: composição de blocos isométricos em CSS/SVG

### 02 — A tese

Seção de destaque, citação em mono grande:

> O modelo nunca é a fonte da verdade sobre "está correto" nem sobre "terminei".

Duas colunas de desdobramento:
- **Correção** vem de ferramentas e gates determinísticos
- **Conclusão** vem de exit code

### 03 — A suite

Quatro cards modulares, cada um com label mono, nome, uma linha de definição, 3 bullets factuais das docs e link `↗` para a subseção correspondente.

1. **Plataforma** — control plane: companies, agents, issues; budgets e approvals; atomic checkout contra trabalho duplicado; auditoria. Princípio: *"O control plane não roda agentes. Ele os orquestra."*
2. **WatchTower** — console central sobre a frota. Pull-based, snapshots read-only. Views: Overview, Fleet, Runs, Problems, Approvals, Drift, Costs, Audit. Roda em três processos separados, independente da plataforma. *"Uma tela só, para você não precisar abrir quinze."*
3. **Agentes Forjados** — repositório Git de agentes e skills em markdown. Cada agente forjado de um especialista real: arquiteto Salesforce, dev, QA, prompt engineer. Três famílias com papéis e reporte definidos. Gate `twinforge-verify` por perfil (Apex, LWC, Flow), offline, com evidência persistente.
4. **Crucible CLI** — harness de coding no terminal, conectado ao proxy LiteLLM interno. Leitura livre; write, exec, web search e MCP sob gate. Regras de permissão persistentes e trust fingerprinting que revalida se as settings do projeto mudam via VCS. *"Autonomia real, mas nada acontece sem sua aprovação."*

Fecho da seção: *"Úteis isoladamente, desenhados para operar juntos."*

### 04 — Arquitetura

Diagrama SVG inline, autoral, mostrando o fluxo real:

```
Control plane (companies · agents · issues · budgets · approvals)
        │ acorda com contexto e orçamento
        ▼
Adapters ──► Claude Code · Cursor · shell · webhook
        │ agentes rodam onde rodam
        ▼
Heartbeat ──► de volta ao control plane (log, custo, decisão pendente)

WatchTower ──► puxa fleet snapshots (read-only) de N instâncias
```

Legenda em mono abaixo. Em telas < 768px o diagrama vira empilhamento vertical.

### 05 — Governança

O que o operador vê e controla, em grid de itens compactos: orçamento por agente, fila de aprovações, atomic checkout, detecção de drift, custo agregado, trilha de auditoria, multi-company.

### 06 — Outcomes

Duas partes:

**Modelo econômico** — modelos menores nos papéis mecânicos (Dev, QA), modelos fortes reservados para julgamento. Consequência direta do gate determinístico: se a correção não depende da opinião do modelo, o papel mecânico não precisa do modelo mais caro.

**Os três outcomes AI/R** — Revenue Growth, Operational Excellence, Customer Experience, cada um conectado a uma capacidade concreta do TwinForge.

**Restrição explícita:** nenhuma métrica numérica é apresentada. O guideline AI/R pede outcomes quantificados, mas as docs do TwinForge não publicam números, e inventar métrica viola o guideline com mais gravidade do que omiti-la. Quando houver dado real de uso, substituir as afirmações qualitativas desta seção.

### 07 — CTA + Footer

Bloco de fecho com o slot de inscrição isolado (ver §5). Footer com logo AI/R, tagline, link para as docs e linha de copyright.

## 5. Slot do botão de inscrição

O botão de inscrição será apontado para a página de inscrição em um passo posterior, via TwinForge. Para tornar essa troca trivial:

- Todo CTA de inscrição usa a classe `.js-signup` e `data-signup`
- Um único comentário-âncora no HTML marca o ponto de troca de URL
- Hoje o `href` aponta para `https://docs.twinforge.webjump.ai/`
- Trocar a URL em dois lugares (hero e fecho) conclui a integração — sem mudança de estilo ou estrutura

## 6. Regras de copy aplicadas

Do guideline AI/R, §8–9:

- Voz ativa em toda a página
- Sem adjetivo abstrato: nenhuma ocorrência de "innovative", "transformational", "revolucionário", "state-of-the-art"
- Sem pergunta retórica
- Uma ideia por frase; frases curtas
- Presente e imperativo
- Todo dado técnico rastreável às docs do TwinForge — nada inventado

## 7. Verificação

Antes de considerar concluída:

1. Página abre em `file://` sem erro de console
2. Fontes locais carregam (Roboto Mono renderiza, não cai para monospace do sistema)
3. Sem scroll horizontal em 1440px, 768px e 375px
4. Screenshot em desktop e mobile conferido visualmente
5. Grep de copy contra a lista de adjetivos proibidos
6. Nenhuma métrica numérica fabricada na página
