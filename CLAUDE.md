# Nznsn — AI Game Studio (yaaddasht; naya session isse seedha shuru kare)
User Hindi/Hinglish bolta hai: usi mein, chhota aur seedha jawab do. Kaam jaldi chahiye.

## Setup (har naye session mein pehle)
- `bash scripts/setup_env.sh` -> Godot 4.7.2 (`godot`) + Blender 5.3.0 (`blender -b`) lagata hai.
- Secrets (git mein NAHI jaate, user se maango): `.env` (template `.env.example`), `config/agents.json` (template `config/agents.example.json`).
- Branch: `ccr-be73983f-pefhcc`. Chat mein aayi keys/links kabhi commit mat karo.

## AI team (Sim.ai chats, model Fable 5.2 — FINAL)
- Agents `config/agents.json` mein (9: lead, coder, blender_tech, level_designer, props_artist, animator, reviewer, art_director, gameplay_designer).
- Sim-side memory CHALU hai (Agent block: Memory=conversation, ID=<start.conversationId>); 8/8 links test PASS (21 Nov). studio.py har agent ko `conversationId=nznsn-<naam>` bhejta hai.
- Phir bhi studio.py apni local yaaddasht bhi saath bhejta hai (backup): `python3 scripts/studio.py ask|add|list|remember|memory|forget|team`.
  Memory: team/memory/<agent>.json (local), team/memory/shared.md (git mein, poori team ko jaata hai).
- Sim plan FREE: $5 limit. Asli kharcha dekho: `python3 scripts/studio.py credits` (SIM_API_KEY, .env). Kharcha dollar/token ke hisaab se hai (flat per-message nahi). 21 Nov: $4.29/$5. Chhoti call ~ $0.02. Bina poochhe bade kaam mat chalao.
- Sim par ek saath bahut requests = 429. Agents ko ek-ek karke chalao.
- Blender agent: `python3 scripts/blender_agent.py "naam" "kya banana" 4 [--anim] [--base script.py]` -> assets/models_3d/*.glb/.png
  (agent bpy code likhta hai, hum headless Blender mein chalate/validate karte hain). Sirf primitives-wale props achhe; character rigging untested.

## API providers (sab ek ek limit ke saath; .env mein keys)
- z14vx94quka0-d.space-z.ai router: sirf demo-chat/demo-3d (demo-3d prompt ignore karta hai, gola deta hai).
- api.xingchiapi.com (key XINGCHI_API_KEY): 21 Nov se CHALTA, sirf Codex CLI ke raaste (client check). `bash scripts/codex_agent.sh "kaam" [folder]` (CODEX_SANDBOX=workspace-write se file likh/chala sakta hai; model gpt-6.1-sol; CODEX_MODEL se badlo). Test: Godot enemy.gd likha, khud check chalaya, PASS. Direct API (/chat/completions, /messages) band; IMAGE band ("not enabled for this group"). Pehle 403 insufficient balance tha, ab theek. Balance dekho: GET /v1/usage (Bearer key) ya `studio.py credits`. 21 Nov: ~$599.7, kharcha ~$0.03/call.

- NVIDIA NIM (integrate.api.nvidia.com/v1, key NVIDIA_API_KEY): CHALTA. 33 models; chat: moonshotai/kimi-k3.1-pro (OK), mistralai/mistral-large-4-1t-a52b, z-ai/glm-5.3-flash (timeout), minimaxai/minimax-m3.1-flash, nvidia/nemotron-3-ultra-550b-a55b, stepfun-ai/step-5-preview. Reasoning models: max_tokens >= 800 rakho warna content khali.
- Google Gemini (generativelanguage.googleapis.com, header x-goog-api-key, key GOOGLE_API_KEY): gemini-3.5-flash CHALTA; pro models free tier mein 429 (quota 0).
- Hugging Face router (HF_TOKEN): token sahi par 402 — prepaid credits/PRO chahiye. Abhi use nahi ho sakta.
- Google "Antigravity" OAuth code (4/0A...): use NAHI kiya (ek-baar ka code, uska API tarika official nahi/ToS ke against).
- Coarena (https://coarena.ai/api/v1, OpenAI-style /chat/completions, key COARENA_API_KEY): FREE par sirf 3 model: gpt-6-luna, gemini-3-8-flash, deepseek-v4-1-flash-1017 (teeno CHALTE, Godot code syntax OK). Limit: $1/din, 10 req/min, 2 saath. Fable/Opus/Sonnet free mein NAHI (402). PRIVACY: Coarena har prompt/reply store karta hai aur datasets mein de sakta hai -> keys/personal data kabhi mat bhejo. Aaj ka kharcha: GET /usage.

## Game
Concept aur status: GAME.md (v0.1 chal raha, autotest PASS). Godot project: godot_project/ (headless test: `godot --headless --path godot_project -- --autotest`).
