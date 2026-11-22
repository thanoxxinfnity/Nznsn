# HORROR PLAN — "KHILAUNA NAGAR" (working title)   [21 Nov 2026]
Poppy-Playtime-jaisa khilauna-factory horror, par ek POORE SHEHAR ke saath. Realistic 3D (dabba nahi), mobile (touch). Sab kuch ORIGINAL (naam, kirdaar, kahani) — kisi game ka asset/character copy nahi.

## Kahani (3 act)
Khilauna Nagar: ek poora shehar jo "Rangeela Toys" company ne apne mazdooron ke liye banaya. 30 saal pehle ek raat mein poori aabaadi gayab ho gayi. Tum ho NEHA (ya naam badlo), ek purani mazdoor ki beti; maa ki aakhri chitthi mili: "Meri gudiya ko neeche mat le jaana."
- Act 1 — Factory gate: chhodi hui factory, bijli band, khilaune har jagah. Pehla "gudiya" dikhti hai jo seedhi khadi ghoor rahi hai. Pehla seekha: roshni = surakshit, andhera = khatra. Pehla jaan-leva chase.
- Act 2 — Shehar: 4 mohalle (school, aspatal, mela/carnival, metro) — har ek ka apna monster aur paheli. Tum diaries/tapes se sachchai jodte ho: company ne mazdooron ki "yaadein" khilaunon mein bhar di thi.
- Act 3 — "Maa Ghar" neeche: sabse bada khilauna "Gudiya Maa" tumhari maa ki awaaz mein bolta hai. Do ant: (a) maa ko azaad karo (shehar ko jalao) (b) tum uski jagah lo.

## Monster (original, har ek ka alag khauf)
1. GUDIYA — patli chini-mitti ki gudiya; tabhi hilti jab tum use NAHI dekh rahe. (roshni wali paheli)
2. LAMBU KAKA — 3 meter lamba, lambe haath, awaaz se tumhe dhoondhta hai. (chup rehne ki paheli)
3. KHOKHLA — bachon ke khilauno ka jhund, alag-alag; bijli band hote hi chalte hain.
4. GUDIYA MAA — final boss; shehar mein gaana gungunati hai.

## Gameplay
- First-person, touch controls (joystick, drag-look, buttons: TORCH, HIDE/INTERACT, RUN, CROUCH)
- Torch (batteri khatam hoti hai), chhupna (almari/bed ke neeche), darwaze/chaabi/switch pahelis, fuse-box se bijli
- Dar-meter (fear): andhera + monster nazdeek -> screen kaanpti, dil ki dhak-dhak, awaaz ghatti/badhti
- Chase: bhaagna + darwaze band karna + chhupna. Checkpoint save.
- Diaries/tapes/voice notes se kahani. Jump-scare kam, dar (dread) zyada (awaaz + roshni + intezaar)

## Shehar (bada, par phone par chalega)
Ek hi giant map nahi — 6 "mohalle" (levels) jinhe darwaze/metro/lift jodte hain; har ek alag load. Bahar se dikhta bada shehar (skybox/door ki imaaratein), andar tum chhote level mein = phone par smooth.

## Tech
Godot 4.7 (GL compatibility -> mobile): SpotLight torch + shadows, fog, baked-ish lighting, procedural awaaz (hum/whispers/dil ki dhak) — Sfx.gd jaisa; monster AI (patrol -> hear -> chase -> lose -> search); NavigationRegion3D.

## 3D model pipeline (APIs)
image/text -> 3D API -> GLB -> Blender headless: decimate (phone ke liye <= 15-30k tri), texture chhota (1024-2048), pivot/scale theek -> Godot.
Models STATIC milte hain; monster ko chalne ke liye RIG + ANIMATION chahiye: Tripo aur Meshy rig/animate API deti hain.
Router: scripts/model3d.py (chat router jaisa): ek API fail/limit -> agli.

## 5 APIs jo main sujhata hoon (user se key chahiye; pricing/free-credit khud check karna)
1. Tripo3D — image/text->3D + auto-rig + animation (monster ke liye sabse kaam ki)
2. Meshy — image/text->3D, PBR texture, rig + animation library
3. Rodin (Hyper3D) — sabse achhi quality; claude.ai connector pehle se juda hai par user ko authorize karna hai
4. Hunyuan3D (Tencent) — fal.ai / Replicate ke raaste; sasta, achhi quality
5. TRELLIS (Microsoft) ya Stability SF3D — fal.ai / Replicate / NVIDIA NIM ke raaste; sasta
Image banane ke liye alag image-generator chahiye (Gemini free key par image band hai); ya seedha text->3D.

## Milestones
H0 plan+APIs jodna -> H1 engine slice: 1 kamra/gallery, torch, fear, touch, 1 monster chase (primitive placeholder) -> H2 pehla asli model pipeline (API->GLB->Blender->Godot) -> H3 Act 1 poora (factory) + APK -> H4 baaki mohalle.

## Khule sawal
1. Dar ka star: halka (Poppy jaisa) ya bahut gehra (gore/zyada khauf)? 2. Naam/kirdaar (Neha?) badalna hai? 3. Awaaz Hindi mein (voice-over) chahiye? 4. Pehle Block City jaari rakhein ya ab sirf horror?

## Update 21 Nov: image->3D MUFT raasta chala (HF Space Hunyuan3D-2.1 + Blender optimize). Quota kam (~2 model/din) -> zyada ke liye HF PRO ya paid API.

## Naya (22 Nov, user ki maang) — Hath, darwaze, aakhri bhaag
- **First-person hath:** poore asli hath, har ungli alag (5 ungliyan, har ek mein 3 jod/bones). Torch pakadna, darwaza dhakelna, chaabi ghumana, almari kholna — sab ungli se. Rigged hand chahiye (Blender mein finger bones + weights; sirf M04 AI-mesh kaafi nahi, usme ungliyan juddi hain).
- **Darwaze:** hinge par saaf khulte hain (dheere/tez dhakka, chaabi wale, almari ke darwaze, lift/shutter). Awaaz + halka creak. Koi clipping/atakna nahi.
- **Koi mesh toota/ulta nahi:** har model par check (normals, holes, floating parts, scale). Godot check + preview par dekhna.
- **Aakhri bhaag — Factory se bhaago (naya ant):** Maa Ghar ke baad factory ka "Yaadon ka engine" (memory core) fatne lagta hai: bijli bhadakti hai, pipe phat-te hain, chhatein girti hain, alarm bajta hai, raasta ek ek karke band hota hai. Timer + raasta: neeche se upar, boiler room -> conveyor hall -> loading dock -> factory gate. Peeche se Khokhla ka jhund aur Lambu Kaka, aage tootay raaste/aag. Chhup ke ya daud ke bachna hai; gate khulne se pehle fuse + chaabi chahiye. Do ant: (a) bach ke bahar nikalo (maa ko aazad karne wala), (b) peeche mud ke Gudiya Maa ko le jao.
