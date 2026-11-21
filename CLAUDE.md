# Nznsn — AI Game Studio (yaaddasht; naya session isse seedha shuru kare)
User Hindi/Hinglish bolta hai: usi mein, chhota aur seedha jawab do. Kaam jaldi chahiye.

## Setup (har naye session mein pehle)
- `bash scripts/setup_env.sh` -> Godot 4.7.2 (`godot`) + Blender 5.3.0 (`blender -b`) lagata hai.
- Secrets (git mein NAHI jaate, user se maango): `.env` (template `.env.example`), `config/agents.json` (template `config/agents.example.json`).
- Branch: `ccr-be73983f-pefhcc`. Chat mein aayi keys/links kabhi commit mat karo.

## AI team (multi-provider, auto-failover) — 9 roles, `config/team_models.json`
- Roles: lead, coder, blender_tech, reviewer (chain "strong": Codex gpt-6.1-sol -> NVIDIA kimi -> Gemini -> Coarena -> seek -> Sim)
  aur level_designer, props_artist, animator, art_director, gameplay_designer (chain "cheap": Coarena deepseek -> seek -> Coarena luna -> Gemini -> NVIDIA -> Codex -> Sim).
- Ek provider ka limit/balance/429/down hone par agla chalta hai, fail hue ko cooldown (scripts/llm.py). Health: `python3 scripts/llm.py health` (chhoti calls, Codex ~$0.03).
- Chalana: `python3 scripts/studio.py ask <role> "sawaal"` | `team "bada kaam"` (lead baantta hai) | `list` | `credits` | `remember "fact"` | `memory/forget <role>`.
- Yaaddasht: team/memory/<role>.json (local, har provider ke saath pichli baatein bheji jaati hain) + team/memory/shared.md (git mein). Sim ka server-side memory sirf Sim ke liye (config/agents.json mein chat links, git mein NAHI).
- Sim sirf aakhri backup ($5 free limit, ~$0.7 bacha). Coarena $1/din, 10 req/min.
- Blender agent: `python3 scripts/blender_agent.py "naam" "kya banana" 4 [--anim] [--base script.py]` -> assets/models_3d/*.glb/.png (blender_tech role chain use karta hai).
- Codex agent (file likhta/chalata hai): `bash scripts/codex_agent.sh "kaam" [folder]` (CODEX_SANDBOX=workspace-write).

## API providers (sab ek ek limit ke saath; .env mein keys)
- z14vx94quka0-d.space-z.ai router: sirf demo-chat/demo-3d (demo-3d prompt ignore karta hai, gola deta hai).
- api.xingchiapi.com (key XINGCHI_API_KEY): 21 Nov se CHALTA, sirf Codex CLI ke raaste (client check). `bash scripts/codex_agent.sh "kaam" [folder]` (CODEX_SANDBOX=workspace-write se file likh/chala sakta hai; model gpt-6.1-sol; CODEX_MODEL se badlo). Test: Godot enemy.gd likha, khud check chalaya, PASS. Direct API (/chat/completions, /messages) band; IMAGE band ("not enabled for this group"). Pehle 403 insufficient balance tha, ab theek. Balance dekho: GET /v1/usage (Bearer key) ya `studio.py credits`. 21 Nov: ~$599.7, kharcha ~$0.03/call.

- NVIDIA NIM (integrate.api.nvidia.com/v1, key NVIDIA_API_KEY): CHALTA. 33 models; chat: moonshotai/kimi-k3.1-pro (OK), mistralai/mistral-large-4-1t-a52b, z-ai/glm-5.3-flash (timeout), minimaxai/minimax-m3.1-flash, nvidia/nemotron-3-ultra-550b-a55b, stepfun-ai/step-5-preview. Reasoning models: max_tokens >= 800 rakho warna content khali.
- Google Gemini (generativelanguage.googleapis.com, header x-goog-api-key, key GOOGLE_API_KEY): gemini-3.5-flash CHALTA; pro models free tier mein 429 (quota 0).
- Hugging Face router (HF_TOKEN): token sahi par 402 — prepaid credits/PRO chahiye. Abhi use nahi ho sakta.
- Google "Antigravity" OAuth code (4/0A...): use NAHI kiya (ek-baar ka code, uska API tarika official nahi/ToS ke against).
- Coarena (https://coarena.ai/api/v1, OpenAI-style /chat/completions, key COARENA_API_KEY): FREE par sirf 3 model: gpt-6-luna, gemini-3-8-flash, deepseek-v4-1-flash-1017 (teeno CHALTE, Godot code syntax OK). Limit: $1/din, 10 req/min, 2 saath. Fable/Opus/Sonnet free mein NAHI (402). PRIVACY: Coarena har prompt/reply store karta hai aur datasets mein de sakta hai -> keys/personal data kabhi mat bhejo. Aaj ka kharcha: GET /usage.
- 100milionseek (https://100milionseek.top/v1, key SEEK_API_KEY, OpenAI-style): 2 model. deepseek-v4.1-flash-free CHALTA (/chat/completions; chhote prompt par bhi ~630 prompt tokens ka chhupa overhead). jev-1.13-free = 'judge model', sirf POST /v1/systemone {model, state(object), questions}; chat nahi karta, format abhi samjha nahi. Usage/limit endpoint nahi. Site anjaan -> sensitive data mat bhejo.

## Game
Concept aur status: GAME.md (v0.1 chal raha, autotest PASS). Godot project: godot_project/ (headless test: `godot --headless --path godot_project -- --autotest`).
