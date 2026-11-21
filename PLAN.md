# PLAN — "Block City" (Minecraft-look, GTA-jaisa open world)   [21 Nov 2026]

## Concept (original naam, kahani, assets — GTA ka kuch copy nahi)
Blocky/voxel look (sab kuch dabbe jaisa), par gameplay GTA jaisa: khula shahar, gaadi chalao, missions/tasks lo, paisa kamao, police se bacho.
Default: sirf Minecraft ka LOOK (block todna/rakhna NAHI) — user bole to baad mein add.

## Pillars
1. Open world: ek block-shahar + jungle + gaon + highway + paani (v1 ~1 km x 1 km, chunk-streaming)
2. Player: blocky character; daud/kudo/tairo; gaadi chalao; halke hathiyaar
3. Missions: phone/marker se mission; types: delivery, taxi, race, chase, collect, heist-lite; 5 story missions + side tasks; paisa + reputation; wanted-level + police
4. Zinda duniya: NPC paidal-log, traffic, din-raat, mausam
5. HUD: minimap, health, paisa, mission tracker

## Tech (Godot 4.7, GL compatibility = halke device/browser par bhi chale)
- World: procedural chunks (16x16), heightmap+biome+roads+buildings -> ArrayMesh per chunk (face culling/greedy), collision per chunk, WorkerThreadPool mein generate
- Characters blocky: 6 dabbe (sar, dhad, 2 haath, 2 pair) -> animation CODE se (Blender credits bachte hain)
- Gaadiyan: Blender blocky models (5 variants), Godot VehicleBody3D
- Imaarat: modular kit (deewar/chhat/darwaza/khidki) Blender se, Godot mein jodke shahar
- Mission system: data-driven (JSON/Resource) taaki naye missions jaldi bane

## Blender + models (credits ki kahani)
- Pehle Fable 5.2 (Sim, ~$0.7 bacha => ~5-10 bpy calls): SIRF ek baar "blocky toolkit" likhwana (bpy library: box_builder, palette, humanoid, car, building_module) + sabse mushkil asset
- Uske baad Codex gpt-6.1-sol ($599) mukhya Blender coder; backup NVIDIA kimi, Gemini, Coarena, seek (config/team_models.json chain "blender": sim -> codex -> ...)
- Toolkit se baaki model sirf function call: sasta model bhi theek kaam kare
- Sabse achha 3D-model banane wala model dhoondhna: ek hi kaam (blocky gaadi) 4 modelon ko do, validator + tasveer se number do (benchmark)

## Milestones (har ek ke end mein autotest + screenshots + commit)
- M0 DONE: tools, team, v0.1 jungle demo
- M1 Block world: chunk terrain, biome, sadak, imaarat, din-raat
- M2 Player + gaadi chalana
- M3 NPC + traffic
- M4 Mission system + 5 story missions + HUD/minimap
- M5 Police/wanted + combat
- M6 Polish: awaaz, save/load, export (browser/Android)

## Sach (scope)
GTA 6 asli mein hazaaron log + saalon ka kaam hai. Hum "GTA-jaisa blocky vertical slice" bana rahe hain: chhota par poora khelne layak. M1-M2 pehle.

## Khule sawal (default likha hai; user badle to badlo)
1. Sirf Minecraft look (default) ya block todna/rakhna bhi?
2. Khelna kahan: PC / phone / browser? (default: browser + PC)
3. Setting: modern beach-shahar (default) theek hai?
