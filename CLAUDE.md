# Nznsn — AI Game Studio (yaaddasht; naya session isse seedha shuru kare)
User Hindi/Hinglish bolta hai: usi mein, chhota aur seedha jawab do. Kaam jaldi chahiye.

## Setup (har naye session mein pehle)
- `bash scripts/setup_env.sh` -> Godot 4.7.2 (`godot`) + Blender 5.3.0 (`blender -b`) lagata hai.
- Secrets (git mein NAHI jaate, user se maango): `.env` (template `.env.example`), `config/agents.json` (template `config/agents.example.json`).
- Branch: `ccr-be73983f-pefhcc`. Chat mein aayi keys/links kabhi commit mat karo.

## AI team (Sim.ai chats, model Fable 5.2 — FINAL)
- Agents `config/agents.json` mein (9: lead, coder, blender_tech, level_designer, props_artist, animator, reviewer, art_director, gameplay_designer).
- Chat stateless hai -> yaaddasht hamari: `python3 scripts/studio.py ask|add|list|remember|memory|forget|team`.
  Memory: team/memory/<agent>.json (local), team/memory/shared.md (git mein, poori team ko jaata hai).
- Sim par ek saath bahut requests = 429. Agents ko ek-ek karke chalao.
- Blender agent: `python3 scripts/blender_agent.py "naam" "kya banana" 4 [--anim] [--base script.py]` -> assets/models_3d/*.glb/.png
  (agent bpy code likhta hai, hum headless Blender mein chalate/validate karte hain). Sirf primitives-wale props achhe; character rigging untested.

## API providers (sab ek ek limit ke saath; .env mein keys)
- z14vx94quka0-d.space-z.ai router: sirf demo-chat/demo-3d (demo-3d prompt ignore karta hai, gola deta hai).
- api.xingchiapi.com: chat/messages/image sab blocked (group, client check, balance). Kaam nahi aaya.

## Game
Concept aur status: GAME.md (v0.1 chal raha, autotest PASS). Godot project: godot_project/ (headless test: `godot --headless --path godot_project -- --autotest`).
