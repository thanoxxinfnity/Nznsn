#!/usr/bin/env bash
# Codex (gpt-6.1-sol, xingchiapi) ko ek agent ki tarah chalao.
#   bash scripts/codex_agent.sh "kaam" [folder]      (CODEX_SANDBOX=workspace-write se file likh sakta hai)
# Key .env ke XINGCHI_API_KEY se aati hai; temp config chalne ke baad shred ho jaati hai.
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
KEYS=${XINGCHI_KEY_VAR:-"XINGCHI_API_KEY XINGCHI_API_KEY2"}  # pehli key ka balance khatam -> agli key apne-aap
H=$(mktemp -d); OUT="$H/last.txt"
trap 'shred -u "$H/config.toml" 2>/dev/null || true; rm -rf "$H"' EXIT
for KV in $KEYS; do
  KEY=$(grep "^$KV=" "$ROOT/.env" | cut -d= -f2-); [ -n "$KEY" ] || continue
cat > "$H/config.toml" <<TOML
model_provider = "OpenAI"
model = "${CODEX_MODEL:-gpt-6.1-sol}"
web_search = "disabled"
disable_response_storage = true

[model_providers.OpenAI]
name = "OpenAI"
base_url = "https://api.xingchiapi.com/v1"
model_catalog_url = "https://api.xingchiapi.com/v1/models"
wire_api = "responses"
requires_openai_auth = false
experimental_bearer_token = "$KEY"
http_headers = { "x-openai-actor-authorization" = "local-image-extension" }

[features]
api_key_model_discovery = true
image_generation = true
TOML
chmod 600 "$H/config.toml"
unset XINGCHI_API_KEY OPENAI_API_KEY
CODEX_HOME="$H" codex exec --skip-git-repo-check --sandbox "${CODEX_SANDBOX:-read-only}" \
  -C "${2:-$ROOT}" -o "$OUT" "$1" </dev/null >"$H/log.txt" 2>&1 && { cat "$OUT"; exit 0; }
  tail -5 "$H/log.txt" >&2
  grep -qiE "insufficient|balance|quota|exceeded|401|402|403|余额" "$H/log.txt" || exit 1
  echo "[codex_agent] $KV khatam/band -> agli key" >&2
done
exit 1
