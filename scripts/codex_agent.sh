#!/usr/bin/env bash
# Codex (gpt-6.1-sol, xingchiapi) ko ek agent ki tarah chalao.
#   bash scripts/codex_agent.sh "kaam" [folder]      (CODEX_SANDBOX=workspace-write se file likh sakta hai)
# Key .env ke XINGCHI_API_KEY se aati hai; temp config chalne ke baad shred ho jaati hai.
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
KEY=$(grep '^XINGCHI_API_KEY=' "$ROOT/.env" | cut -d= -f2-)
H=$(mktemp -d); OUT="$H/last.txt"
trap 'shred -u "$H/config.toml" 2>/dev/null || true; rm -rf "$H"' EXIT
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
  -C "${2:-$ROOT}" -o "$OUT" "$1" </dev/null >"$H/log.txt" 2>&1 || { tail -5 "$H/log.txt" >&2; exit 1; }
cat "$OUT"
