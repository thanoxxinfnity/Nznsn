# Nznsn — "Jungle ke Khazane"
**Concept:** Veer lakdi ke jungle mein kho gaya hai. Jungle mein 5 jaadui lakdi ke sandook chhupe hain.
Har sandook ke upar sunehri roshni ki kiran hai. Paas jaakar `E` dabao -> dhakkan khulta hai (Blender wala animation).
5 sandook khol do -> JEET.

**Controls:** WASD chalo | Shift daudo | Space kudo | Mouse dekho | E kholo | R dobara | Esc mouse chhodo
**Run:** Godot 4.7 mein `godot_project/` kholo, F5. Headless test: `godot --headless --path godot_project -- --autotest`
**Screenshots:** `xvfb-run -a godot --rendering-driver opengl3 --path godot_project -- --shot=/tmp/dir`

## Abhi bana hai (v0.1)
- 3rd-person player (Veer), camera collision, 110 ped, 16 lattha, lakdi ki jhopdi, dhundh + roshni
- 5 sandook (Blender agent ka banaya `assets/chest.glb`, animation `open`), HUD (counter + sabse paas ki doori), jeet screen
- Autotest PASS: 5/5 sandook khule, animation chala, jeet trigger hua

## Agle kaam (team ko dena)
- props_artist: asli lakdi ke props (jhopdi, pul, baad, lattha) Blender se, gaon bananaa
- animator: darwaza, hilte ped, aag ka animation; player ka chalne ka animation (rigging untested)
- level_designer + gameplay_designer: dushman/khatre, quests, raat-din, awaaz/music
- reviewer: bugs; art_director: rang/look polish
- Web export (browser mein khelne ke liye): Godot export templates chahiye
