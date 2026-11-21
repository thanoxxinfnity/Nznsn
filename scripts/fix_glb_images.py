"""GLB ke andar ki JPEG textures ko PIL se dobara likho.
Blender 5.3 ki JPEG (APP1/oiio comments wali) Godot 4.7 ka libjpeg-turbo nahi padh pata -> import crash.
Use: python3 scripts/fix_glb_images.py <file.glb|dir> ...   (sirf image/jpeg badalta hai, baaki sab same)"""
import sys, json, struct, io, pathlib
from PIL import Image


def fix(path):
    b = path.read_bytes()
    jl = struct.unpack('<I', b[12:16])[0]
    j = json.loads(b[20:20 + jl])
    bin_start = 20 + jl + 8
    binlen = struct.unpack('<I', b[20 + jl:24 + jl])[0]
    data = b[bin_start:bin_start + binlen]
    targets = {im['bufferView'] for im in j.get('images', []) if im.get('mimeType') == 'image/jpeg' and 'bufferView' in im}
    if not targets:
        return False
    out = bytearray(); views = j['bufferViews']
    for i, bv in enumerate(views):
        s = bv.get('byteOffset', 0); chunk = data[s:s + bv['byteLength']]
        if i in targets:
            if chunk[6:10] == b'JFIF' and b'Blender:' not in chunk[:600]:
                pass  # pehle se saaf
            else:
                buf = io.BytesIO(); Image.open(io.BytesIO(chunk)).convert('RGB').save(buf, 'JPEG', quality=85)
                chunk = buf.getvalue()
        while len(out) % 4: out += b'\0'
        bv['byteOffset'] = len(out); bv['byteLength'] = len(chunk); out += chunk
    while len(out) % 4: out += b'\0'
    j['buffers'][0]['byteLength'] = len(out)
    js = json.dumps(j, separators=(',', ':')).encode()
    js += b' ' * (-len(js) % 4)
    total = 12 + 8 + len(js) + 8 + len(out)
    path.write_bytes(b'glTF' + struct.pack('<II', 2, total) + struct.pack('<I', len(js)) + b'JSON' + js
                     + struct.pack('<I', len(out)) + b'BIN\0' + bytes(out))
    return True


n = 0
for a in sys.argv[1:]:
    p = pathlib.Path(a)
    for f in (sorted(p.glob('*.glb')) if p.is_dir() else [p]):
        n += fix(f)
print('fixed', n)
