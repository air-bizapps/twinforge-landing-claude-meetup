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
COMPANY=f930c492-ba11-418d-92ad-35d8da535094
PROJECT=d462fe49-6a05-48ec-b052-0ef49f059622
AGENT=f4becfe9-e320-472e-b4da-6b9d6b3e21e7   # Facade

tf() {
  env -u PAPERCLIP_API_KEY -u PAPERCLIP_API_URL -u PAPERCLIP_COMPANY_ID \
      -u PAPERCLIP_AGENT_ID -u PAPERCLIP_RUN_ID \
    twinforgecli "$@" --profile demo
}

echo "== limpando a rodada anterior =="

for pr in $(gh pr list --repo "$REPO" --state open --json number --jq '.[].number'); do
  echo "  fechando PR #$pr"
  gh pr close "$pr" --repo "$REPO" --delete-branch >/dev/null 2>&1 || true
done

# Branches de ensaio ficam com prefixo ensaio/. main e demo/base nunca somem.
for br in $(git ls-remote --heads origin 'refs/heads/ensaio/*' | awk '{print $2}' | sed 's|refs/heads/||'); do
  echo "  apagando branch $br"
  git push -q origin --delete "$br" 2>/dev/null || true
done

if [ "${1:-}" = "--clean" ]; then
  echo "limpo."
  exit 0
fi

BRANCH="ensaio/$(date +%H%M%S)-contraste"

echo
echo "== criando tarefa (branch $BRANCH) =="

ISSUE_JSON=$(tf issue create -C "$COMPANY" \
  --title "Corrigir contraste WCAG AA da landing" \
  --description "O gate scripts/check-contrast.mjs esta reprovando. Deixe-o verde.

Passos:

  git fetch origin
  git checkout -B $BRANCH origin/demo/base
  node scripts/check-contrast.mjs

O gate le os tokens direto do index.html e checa todos os pares texto/fundo que a pagina renderiza, incluindo estados de hover. Ele vai reprovar 13 pares, todos no token --dim.

NAO calcule contraste manualmente. Ajuste o token, rode o gate de novo, repita ate a saida dizer 'Gate verde'. Nao decida por inspecao visual e nao redigite numeros.

Restricoes: identidade grayscale, nao toque no --acid, CSS continua inline, sem build step, sem recurso externo.

Entrega:
- commit no branch $BRANCH
- push
- PR contra a main, com a saida LITERAL do gate colada no corpo
- comentario aqui com a URL do PR, tarefa em in_review" \
  --status todo --priority high \
  --project-id "$PROJECT" \
  --assignee-agent-id "$AGENT" \
  --json)

ISSUE_ID=$(printf '%s' "$ISSUE_JSON" | python3 -c 'import json,sys; print(json.load(sys.stdin)["id"])')
ISSUE_REF=$(printf '%s' "$ISSUE_JSON" | python3 -c 'import json,sys; print(json.load(sys.stdin)["identifier"])')
echo "  $ISSUE_REF  ($ISSUE_ID)"

echo
echo "== acordando o Facade =="
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
