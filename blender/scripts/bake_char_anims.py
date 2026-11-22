"""blender -b --python bake_char_anims.py -- <rig.fbx (mixamorig, WithSkin)> <anim_dir...> <out.glb>
Character ke apne Blender rig par Mixamo clips lagao (hips ki location cm->m, character ke size ke hisaab se) aur GLB export karo (mesh + armature + clips).
Rest-pose ka farak Blender bone-local rotations se handle hota hai. CLIPS env (comma separated) se clips chuno, warna CLIPSET default."""
import bpy, sys, os, glob
a = sys.argv[sys.argv.index("--") + 1:]; rig = a[0]; dirs = a[1:-1]; out = a[-1]
DEFAULT = "BreathingIdle,ZombieIdle,ZombieWalk,ZombieRunning,MutantWalking,MutantRun,InjuredWalk,InjuredIdle,SneakWalk,CrouchedWalking,RunningTired,ZombieAttack,ZombieBiting,MutantSwiping,MutantJumpAttack,Punching,ZombieScream,MutantRoaring,Taunt,LookOverShoulder,Terrified,ZombieCrawl,Crawling,HitReaction,ZombieDeath,MutantDying,FallingBackDeath,Dying,ZombieStandUp,GettingUp,Stunned,DizzyIdle,Crying,Singing,Praying,Opening,OpeningDoorInwards,HidingGrab"
want = [c for c in os.environ.get("CLIPS", DEFAULT).split(",") if c]
files = {}
for d in dirs:
    for f in sorted(glob.glob(os.path.join(d, "*.fbx"))): files.setdefault(os.path.splitext(os.path.basename(f))[0], f)
if rig.endswith(".blend"):
    bpy.ops.wm.open_mainfile(filepath=rig)
else:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=rig, automatic_bone_orientation=False)
arm = next(o for o in bpy.data.objects if o.type == "ARMATURE"); arm.name = "Armature"
hb = arm.data.bones["mixamorig:Hips"]; hip_h = (arm.matrix_world @ hb.head_local).z
s = 0.01 * hip_h / 0.9979  # lib hips ~99.8cm
arm.animation_data_create()
n = 0
for stem in want:
    if stem not in files: print("MISSING", stem); continue
    before = set(bpy.data.objects)
    bpy.ops.import_scene.fbx(filepath=files[stem], automatic_bone_orientation=False)
    new = set(bpy.data.objects) - before
    a2 = next((o for o in new if o.type == "ARMATURE"), None)
    if not a2 or not a2.animation_data or not a2.animation_data.action: continue
    act = a2.animation_data.action; act.name = stem; act.use_fake_user = True
    for lay in act.layers:
        for st in lay.strips:
            for cb in st.channelbags:
                for fc in cb.fcurves:
                    if fc.data_path.endswith("location") and "Hips" in fc.data_path:
                        for kp in fc.keyframe_points: kp.co.y *= s; kp.handle_left.y *= s; kp.handle_right.y *= s
    tr = arm.animation_data.nla_tracks.new(); tr.name = stem; tr.strips.new(stem, 1, act).name = stem
    for o in new: bpy.data.objects.remove(o)
    n += 1
print("BAKED", n, "clips hip_h", round(hip_h, 3), "s", round(s, 5))
bpy.ops.object.select_all(action="SELECT")
bpy.ops.export_scene.gltf(filepath=out, export_format="GLB", use_selection=True, export_animation_mode="NLA_TRACKS", export_force_sampling=True, export_optimize_animation_size=True, export_image_format="JPEG", export_jpeg_quality=85)
print("DONE", out, os.path.getsize(out) // 1024, "KB")
