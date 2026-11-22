"""blender -b --python build_anim_lib.py -- <fbx_dir...> <out.glb>
Mixamo FBX (without skin) -> ek GLB jisme ek mixamo skeleton + sab animations (NLA track har clip ke naam se)."""
import bpy, sys, os, glob
a = sys.argv[sys.argv.index("--") + 1:]; out = a[-1]; dirs = a[:-1]
files = []
for d in dirs: files += sorted(glob.glob(os.path.join(d, "*.fbx")))
seen = {}; base = None
for f in files:
    stem = os.path.splitext(os.path.basename(f))[0]
    if stem.startswith(("YBot_", "SWAT_")): continue
    if stem in seen: continue
    seen[stem] = f
bpy.ops.wm.read_factory_settings(use_empty=True)
for stem, f in seen.items():
    before = set(bpy.data.objects)
    bpy.ops.import_scene.fbx(filepath=f, automatic_bone_orientation=False)
    new = set(bpy.data.objects) - before
    arm = next((o for o in new if o.type == "ARMATURE"), None)
    if arm is None or not arm.animation_data or not arm.animation_data.action: print("SKIP", stem); 
    else:
        act = arm.animation_data.action; act.name = stem; act.use_fake_user = True
        if base is None:
            base = arm; base.name = "Armature"; new.discard(arm)
            for o in list(new):
                if o.type == "MESH": bpy.data.objects.remove(o)
            base.animation_data.action = None
            tracks = base.animation_data
            base["_n"] = 0
            ntr = tracks.nla_tracks.new(); ntr.name = stem; s = ntr.strips.new(stem, 1, act); s.name = stem
            continue
        tr = base.animation_data.nla_tracks.new(); tr.name = stem
        st = tr.strips.new(stem, 1, act); st.name = stem
    for o in new:
        if o.name in bpy.data.objects: bpy.data.objects.remove(o)
print("CLIPS", len(base.animation_data.nla_tracks), "bones", len(base.data.bones), "scale", tuple(base.scale), "rot", tuple(base.rotation_euler))
hips = base.pose.bones.get("mixamorig:Hips"); print("HIPSREST", tuple(hips.bone.head_local) if hips else None)
bpy.ops.object.select_all(action="DESELECT"); base.select_set(True); bpy.context.view_layer.objects.active = base
bpy.ops.export_scene.gltf(filepath=out, export_format="GLB", use_selection=True, export_animation_mode="NLA_TRACKS", export_force_sampling=True, export_optimize_animation_size=True, export_def_bones=False, export_anim_single_armature=True)
print("DONE", out, os.path.getsize(out) // 1024, "KB")
