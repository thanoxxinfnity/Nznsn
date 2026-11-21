import bpy, sys
path = sys.argv[sys.argv.index("--")+1]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.obj_import(filepath=path)
for o in bpy.context.scene.objects:
    if o.type == 'MESH':
        d = o.dimensions
        print(f"IMPORTED {o.name}: verts={len(o.data.vertices)} faces={len(o.data.polygons)} dims=({d.x:.2f},{d.y:.2f},{d.z:.2f})")
bpy.ops.wm.save_as_mainfile(filepath=path.replace('.obj','.blend'))
bpy.ops.export_scene.gltf(filepath=path.replace('.obj','.glb'))
print("SAVED blend+glb")
