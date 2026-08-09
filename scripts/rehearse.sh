#!/bin/bash
# Ensaio da demo TwinForge: limpa a rodada anterior, cria uma tarefa nova,
# acorda o agente e cronometra ate o PR sair.
#
#   ./scripts/rehearse.sh          roda um ensaio
#   ./scripts/rehearse.sh --clean  so limpa, sem criar tarefa nova
#
# Cada ensaio parte de demo/base (main + gate, --dim ainda quebrado), entao o
# estado inicial e sempre o mesmo. A main nunca e tocada.

set -euo pipefail

REPO=air-bizapps/twinforge-landing-claude-meetup
COMPANY=7ab9ce90-1f50-4a57-bab7-92fbce701fe0
PROJECT=e27d1a5d-25b6-4f08-bbd9-600a97e4d8a4
AGENT=f4e7bad9-e056-4c55-9206-551972775f24   # ARIAne (POA Claude Meetup)

tf() {
  env -u PAPERCLIP_API_KEY -u PAPERCLIP_API_URL -u PAPERCLIP_COMPANY_ID \
      -u PAPERCLIP_AGENT_ID -u PAPERCLIP_RUN_ID \
    twinforgecli "$@" --profile demo
}

echo "== limpando a rodada anterior =="

# So PRs de ensaio. Um PR de demo (demo/*) nao pode ser fechado por engano:
# ele e o artefato que sustenta a apresentacao se a instancia estiver fora.
for pr in $(gh pr list --repo "$REPO" --state open --json number,headRefName \
              --jq '.[] | select(.headRefName | startswith("ensaio/")) | .number'); do
  echo "  fechando PR #$pr"
  gh pr close "$pr" --repo "$REPO" --delete-branch >/dev/null 2>&1 || true
done

# Branches de ensaio ficam com prefixo ensaio/. main e demo/base nunca somem.
for br in $(git ls-remote --heads origin 'refs/heads/ensaio/*' | awk '{print $2}' | sed 's|refs/heads/||'); do
  echo "  apagando branch $br"
  git push -q origin --delete "$br" 2>/dev/null || true
done

# Tarefas de rodadas anteriores viram ruido no board — e o board aparece na
# gravacao. Cancela so as de correcao; a auditoria tem outro titulo e fica.
OLD_IDS=$(tf issue list -C "$COMPANY" --project-id "$PROJECT" --json 2>/dev/null \
  | python3 -c '
import json, sys
try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)
items = data if isinstance(data, list) else data.get("items", [])
for i in items:
    if i.get("title", "").startswith("Corrigir o contraste apontado na auditoria") \
       and i.get("status") not in ("cancelled", "done"):
        print(i["id"])
')

for id in $OLD_IDS; do
  ref=$(tf issue update "$id" --status cancelled --json 2>/dev/null \
        | python3 -c 'import json,sys; print(json.load(sys.stdin)["identifier"])' 2>/dev/null || echo "$id")
  echo "  cancelando $ref"
done

if [ "${1:-}" = "--clean" ]; then
  echo "limpo."
  exit 0
fi

STAMP="$(date +%H%M%S)"
BRANCH="ensaio/$STAMP-contraste"

echo
echo "== criando tarefa (branch $BRANCH) =="

# O titulo precisa ser unico: issue create deduplica por titulo dentro do
# projeto e devolveria a tarefa da rodada anterior, ja concluida, fazendo o
# ensaio "passar" em segundos sem ter rodado nada.
ISSUE_JSON=$(tf issue create -C "$COMPANY" \
  --title "Corrigir o contraste apontado na auditoria ($STAMP)" \
  --description "A auditoria da POA-2 encontrou 13 combinacoes de texto e fundo abaixo do minimo WCAG AA de 4.5:1 para texto normal, todas originadas do token --dim (#646464).

Contexto do repositorio: pagina estatica, index.html unico com CSS inline, sem build step. As cores vivem como custom properties no :root. O repo tem uma verificacao em scripts/check-contrast.mjs que le os tokens e mede todos os pares que a pagina renderiza, incluindo estados de hover.

Preparacao:

  git fetch origin
  git checkout -B $BRANCH origin/demo/base

Criterio de aceite:
- Nenhuma combinacao de texto normal abaixo de 4.5:1.
- A verificacao do repo sai com codigo 0.
- Identidade grayscale mantida, sem matiz.
- O token --acid permanece intocado.
- CSS continua inline, sem build step e sem recurso externo.

Entrega:
- commit no branch $BRANCH e push
- PR contra a main, com a saida da verificacao no corpo
- comentario aqui com a URL do PR, tarefa em in_review" \
  --status todo --priority high \
  --project-id "$PROJECT" \
  --assignee-agent-id "$AGENT" \
  --json)

ISSUE_ID=$(printf '%s' "$ISSUE_JSON" | python3 -c 'import json,sys; print(json.load(sys.stdin)["id"])')
ISSUE_REF=$(printf '%s' "$ISSUE_JSON" | python3 -c 'import json,sys; print(json.load(sys.stdin)["identifier"])')
echo "  $ISSUE_REF  ($ISSUE_ID)"

echo
echo "== acordando a ARIAne =="
tf agent wake "$AGENT" -C "$COMPANY" --json >/dev/null
START=$(date +%s)

while :; do
  sleep 15
  STATUS=$(tf issue get "$ISSUE_ID" --json 2>/dev/null \
    | python3 -c 'import json,sys; print(json.load(sys.stdin).get("status",""))' 2>/dev/null || echo "")
  ELAPSED=$(( $(date +%s) - START ))
  printf '\r  [%3ds] %-12s' "$ELAPSED" "$STATUS"
  case "$STATUS" in
    in_review|done)  echo; echo "  terminou em ${ELAPSED}s"; break ;;
    blocked)         echo; echo "  BLOQUEOU em ${ELAPSED}s — veja os comentarios de $ISSUE_REF"; exit 1 ;;
  esac
  [ "$ELAPSED" -gt 900 ] && { echo; echo "  passou de 15min, algo travou"; exit 1; }
done

echo
echo "== resultado =="
gh pr list --repo "$REPO" --state open --json number,title,url --jq '.[] | "  PR #\(.number)  \(.url)"'

PR=$(gh pr list --repo "$REPO" --state open --json number --jq '.[0].number // empty')
if [ -n "$PR" ]; then
  echo "  aguardando o deploy de preview..."
  gh pr checks "$PR" --repo "$REPO" --watch >/dev/null 2>&1 || true
  gh pr view "$PR" --repo "$REPO" --json comments \
    --jq '.comments[].body | select(startswith("Preview:"))' | tail -1 | sed 's/^/  /'
fi
