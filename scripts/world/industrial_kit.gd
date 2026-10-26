extends RefCounted
# Reusable exterior kit. Every dimension is in metres. Batching keeps Web draw calls low.
var root: Node3D
var batches: Dictionary = {}
var materials: Dictionary = {}
var building_ranges: Dictionary = {}

func _init(parent: Node3D) -> void:
    root = parent

func material(hex: String) -> StandardMaterial3D:
    if not materials.has(hex):
        var m := StandardMaterial3D.new()
        m.albedo_color = Color(hex)
        m.roughness = 0.87
        if hex in ["#737f7c", "#c8c2a4", "#b9b9a4", "#c7c8b2"]:
            var image := Image.create(64,64,false,Image.FORMAT_RGB8)
            var rng := RandomNumberGenerator.new()
            rng.seed = 1205
            for y in range(64):
                for x in range(64):
                    var value := rng.randf_range(0.94,1.0)
                    image.set_pixel(x,y,Color(value,value,value))
            image.generate_mipmaps()
            m.albedo_texture = ImageTexture.create_from_image(image)
            m.uv1_triplanar = true
            m.uv1_world_triplanar = true
            m.uv1_scale = Vector3(0.7,0.7,0.7)
        materials[hex] = m
    return materials[hex]

func box(pos: Vector3, size: Vector3, color: String, rotation: Vector3 = Vector3.ZERO) -> void:
    var key := color + "box"
    if not batches.has(key): batches[key] = {"mesh": BoxMesh.new(), "color": color, "transforms": []}
    var basis := Basis.from_euler(rotation).scaled(size)
    batches[key].transforms.append(Transform3D(basis, pos))

func wheel(pos: Vector3, radius: float = 0.34) -> void:
    var key := "wheels"
    if not batches.has(key):
        var mesh := CylinderMesh.new()
        mesh.top_radius = 1.0
        mesh.bottom_radius = 1.0
        mesh.height = 1.0
        mesh.radial_segments = 12
        batches[key] = {"mesh": mesh, "color": "#293739", "transforms": []}
    batches[key].transforms.append(Transform3D(Basis.from_euler(Vector3(PI/2,0,0)).scaled(Vector3(radius,radius,0.20)),pos))
    box(pos+Vector3(0,0,0.12),Vector3(radius*0.75,radius*0.75,0.05),"#b4c0bf")

func finish() -> void:
    for entry in batches.values():
        var mm := MultiMesh.new()
        mm.transform_format = MultiMesh.TRANSFORM_3D
        mm.mesh = entry.mesh
        mm.instance_count = entry.transforms.size()
        for i in entry.transforms.size(): mm.set_instance_transform(i,entry.transforms[i])
        var node := MultiMeshInstance3D.new()
        node.multimesh = mm
        node.material_override = material(entry.color)
        root.add_child(node)
        entry["node"] = node

func roof(center: Vector3, w: float, d: float, rise: float, color: String) -> void:
    # Closed triangular gable: no intersecting tilted slabs or roof gaps.
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    st.set_smooth_group(-1)
    var a := Vector3(-w/2,0,-d/2)
    var b := Vector3(w/2,0,-d/2)
    var c := Vector3(-w/2,0,d/2)
    var e := Vector3(w/2,0,d/2)
    var r := Vector3(-w/2,rise,0)
    var s := Vector3(w/2,rise,0)
    for face in [[a,r,s],[a,s,b],[r,c,e],[r,e,s],[a,c,r],[b,s,e]]:
        for v in face: st.add_vertex(v)
    st.generate_normals()
    var node := MeshInstance3D.new()
    node.mesh = st.commit()
    var mat := material(color).duplicate() as StandardMaterial3D
    mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    node.material_override = mat
    node.position = center
    root.add_child(node)

func building(b: Dictionary) -> void:
    var start_counts := {}
    for key in batches: start_counts[key] = batches[key].transforms.size()
    var child_start := root.get_child_count()
    var p := Vector3(b.x,0,b.z)
    var w: float = b.w
    var d: float = b.d
    var h: float = b.h
    var color: String = b.color
    var office: bool = b.style == "office"
    box(p+Vector3(0,0.15,0),Vector3(w+1.2,0.3,d+1.2),"#8c9690")
    box(p+Vector3(0,h/2,0),Vector3(w,h,d),color)
    box(p+Vector3(0,0.5,0),Vector3(w+0.1,0.8,d+0.1),"#7f8984")
    if office:
        box(p+Vector3(0,h+0.15,0),Vector3(w+0.7,0.3,d+0.7),"#566967")
    elif b.style == "awning":
        roof(p+Vector3(0,h,0),w+0.8,d+0.8,1.0,"#d2bb88")
    else:
        var rise: float = minf(2.3,d*0.16)
        roof(p+Vector3(0,h,0),w+0.8,d+0.8,rise,"#718b8f" if b.style != "warehouse" and b.style != "third" else "#9a4834")
        box(p+Vector3(0,h+rise+0.08,0),Vector3(w+0.9,0.14,0.22),"#d2d9ce")
        # Roof standing seams and skylight strips.
        for x in range(int(w/2.2)):
            for side in [-1.0,1.0]:
                var slope: float = atan2(rise,d/2)
                box(p+Vector3(-w/2+1+x*2.2,h+rise/2+0.11,side*d/4),Vector3(0.045,0.05,sqrt(d*d/4+rise*rise)),"#96aaab",Vector3(side*slope,0,0))
        if b.style != "third":
            for x in range(int(w/12)):
                box(p+Vector3(-w/2+6+x*12,h+rise*0.65+0.16,-d*0.18),Vector3(3.8,0.12,1.4),"#c9e0d9",Vector3(-atan2(rise,d/2),0,0))
    # Corrugation and a structural rhythm; warm office masonry is distinct.
    if not office:
        for x in range(int(w/0.8)):
            for side in [-1.0,1.0]:
                box(p+Vector3(-w/2+x*0.8, h/2+0.3,side*(d/2+0.04)),Vector3(0.045,h-0.7,0.07),"#879b9b" if b.style != "warehouse" else "#bb694c")
    for side in [-1.0,1.0]:
        box(p+Vector3(0,h-0.15,side*(d/2+0.25)),Vector3(w+0.6,0.17,0.22),"#d0d5c9")
        for x in range(int(w/8)):
            var xx: float = -w/2+4+x*8
            box(p+Vector3(xx,h*0.64,side*(d/2+0.12)),Vector3(2.9,1.15,0.12),"#e0e6d4")
            box(p+Vector3(xx,h*0.64,side*(d/2+0.2)),Vector3(2.6,0.88,0.08),"#496f79")
            box(p+Vector3(xx,h*0.64,side*(d/2+0.27)),Vector3(0.08,0.9,0.08),"#b2c8c6")
        # gutters / downpipes
        box(p+Vector3(w/2-0.4,h/2,side*(d/2+0.35)),Vector3(0.15,h,0.15),"#697e7d")
    # Doors face the site roads. Loading portals occupy end wall.
    var doors: int = 3 if b.style == "garage" else 1
    for i in doors:
        var zz: float = (i-(doors-1)*0.5)*2.5
        box(p+Vector3(w/2+0.08,2.0,zz),Vector3(0.16,4.1,4.2 if doors==1 else 2.25),"#d4d5be")
        box(p+Vector3(w/2+0.18,1.95,zz),Vector3(0.12,3.8,3.8 if doors==1 else 2.0),"#172b32" if b.style == "construction" else "#354d55")
        for y in range(0 if b.style == "construction" else 7):
            box(p+Vector3(w/2+0.26,0.4+y*0.5,zz),Vector3(0.06,0.05,3.8 if doors==1 else 2.0),"#657b7b")
        box(p+Vector3(w/2+3,0.07,zz),Vector3(5.8,0.13,6),"#b7b9a6")
        for sign in [-1,1]: box(p+Vector3(w/2+1.0,0.7,zz+sign*2.5),Vector3(0.2,1.4,0.2),"#e2b74f")
    box(p+Vector3(-w*0.25,1.15,d/2+0.12),Vector3(1,2.3,0.18),"#455e62")
    box(p+Vector3(-w*0.25,2.5,d/2+0.6),Vector3(1.7,0.13,1.3),"#798e88")
    if b.style == "construction":
        # Photo: clad gable, still unfinished around the perimeter.
        for i in range(5):
            box(p+Vector3(-w/2+3+i*7,1.7,d/2+1.2),Vector3(0.12,3.4,0.12),"#b78c51")
        for y in [0.7,2.8]: box(p+Vector3(0,y,d/2+1.2),Vector3(w,0.12,0.12),"#b78c51")
        for i in range(4): box(p+Vector3(-8+i*3,0.4,d/2+4),Vector3(2.5,0.8,1.4),"#bcb4a1")
        for i in range(5): box(p+Vector3(-w/2-2,0.15+i*0.16,0),Vector3(1.4,0.12,8),"#657f86")

    var ranges := {}
    for key in batches:
        var first: int = start_counts.get(key,0)
        if batches[key].transforms.size() > first:
            ranges[key] = [first,batches[key].transforms.size()]
    var nodes: Array[Node3D] = []
    for i in range(child_start,root.get_child_count()): nodes.append(root.get_child(i))
    building_ranges[b.id] = {"ranges":ranges,"nodes":nodes}

func move_building(id: String, delta: Vector3) -> void:
    var geometry: Dictionary = building_ranges[id]
    for key in geometry.ranges:
        var span: Array = geometry.ranges[key]
        for i in range(span[0],span[1]):
            var transform: Transform3D = batches[key].transforms[i]
            transform.origin += delta
            batches[key].transforms[i] = transform
            batches[key].node.multimesh.set_instance_transform(i,transform)
    for node in geometry.nodes: node.position += delta

func trailer(p: Vector3, frame_only: bool = false, covered: bool = false) -> void:
    # 4.3m including A-frame drawbar, 1.9m wide; estimates, not a product CAD model.
    for side in [-0.82,0.82]:
        box(p+Vector3(0,0.64,side),Vector3(2.9,0.12,0.12),"#526a70")
    for x in [-1.3,-0.5,0.4,1.3]: box(p+Vector3(x,0.64,0),Vector3(0.1,0.1,1.7),"#657e82")
    box(p+Vector3(1.95,0.62,0),Vector3(1.3,0.1,0.1),"#9cacaa")
    for side in [-1.0,1.0]:
        box(p+Vector3(1.6,0.62,side*0.35),Vector3(1.1,0.1,0.08),"#899e9e",Vector3(0,side*0.5,0))
    if frame_only: return
    box(p+Vector3(0,0.76,0),Vector3(2.9,0.12,1.7),"#b1bdb4")
    for z in [-0.86,0.86]:
        box(p+Vector3(0,1.12,z),Vector3(2.95,0.66,0.07),"#c6d2ca")
        box(p+Vector3(0,1.47,z),Vector3(3.02,0.06,0.09),"#edf0d9")
        for x in [-1.35,0,1.35]: box(p+Vector3(x,1.12,z),Vector3(0.06,0.7,0.10),"#839a9a")
    for x in [-1.45,1.45]: box(p+Vector3(x,1.1,0),Vector3(0.07,0.66,1.7),"#c2cdc5")
    for z in [-1.0,1.0]:
        wheel(p+Vector3(-0.15,0.37,z))
        box(p+Vector3(-0.15,0.85,z),Vector3(0.95,0.14,0.44),"#8fa5a7")
    for z in [-0.65,0.65]: box(p+Vector3(-1.52,0.8,z),Vector3(0.08,0.17,0.23),"#b54330")
    box(p+Vector3(2.2,0.32,0),Vector3(0.08,0.6,0.08),"#869d9b")
    if covered: box(p+Vector3(0,1.7,0),Vector3(2.85,1.4,1.65),"#546f7a")

func container(p: Vector3, color: String) -> void:
    box(p+Vector3(0,1.3,0),Vector3(6.06,2.59,2.44),color)
    for i in range(14):
        for side in [-1.0,1.0]: box(p+Vector3(-2.8+i*0.43,1.3,side*1.25),Vector3(0.08,2.4,0.08),"#738b88")
    for z in [-0.9,0,0.9]: box(p+Vector3(3.07,1.3,z),Vector3(0.06,2.35,0.06),"#ced0b4")

func pallet(p: Vector3, cargo: bool = true) -> void:
    for x in [-0.45,0,0.45]: box(p+Vector3(x,0.14,0),Vector3(0.15,0.26,1),"#9c7f51")
    for z in [-0.4,-0.2,0,0.2,0.4]: box(p+Vector3(0,0.3,z),Vector3(1.2,0.08,0.14),"#c3a06a")
    if cargo:
        box(p+Vector3(0,0.8,0),Vector3(1.05,0.9,0.85),"#b89b70")
        for x in [-0.38,0.38]: box(p+Vector3(x,0.8,0),Vector3(0.06,0.94,0.9),"#e0c596")

func forklift(p: Vector3) -> void:
    box(p+Vector3(0,0.7,0),Vector3(2.0,0.9,1.15),"#dcae44")
    box(p+Vector3(-0.5,1.1,0),Vector3(0.6,0.7,0.9),"#31494e")
    for x in [-0.7,0.5]:
        for z in [-0.65,0.65]:
            wheel(p+Vector3(x,0.35,z),0.3)
            box(p+Vector3(x,1.8,z*0.8),Vector3(0.07,1.3,0.07),"#334e53")
    box(p+Vector3(-0.1,2.5,0),Vector3(1.65,0.12,1.25),"#d8b65c")
    for z in [-0.4,0.4]:
        box(p+Vector3(1.0,1.4,z),Vector3(0.14,2.6,0.14),"#3b5356")
        box(p+Vector3(1.75,0.18,z),Vector3(1.6,0.12,0.14),"#40575a")

func truck(p: Vector3) -> void:
    box(p+Vector3(-1,1.9,0),Vector3(5.5,2.5,2.4),"#d6ded1")
    box(p+Vector3(3,1.3,0),Vector3(2.2,2.1,2.35),"#488c8c")
    box(p+Vector3(3.5,1.8,0),Vector3(1.3,0.9,2.4),"#35535d")
    box(p+Vector3(4.15,0.7,0),Vector3(0.14,0.3,2.5),"#c5d1c8")
    for x in [-2.7,2.8]:
        for z in [-1.25,1.25]: wheel(p+Vector3(x,0.48,z),0.46)

func tree(p: Vector3, seed_value: int) -> void:
    box(p+Vector3(0,1.1,0),Vector3(0.4,2.2,0.4),"#807b58")
    var colors := ["#79975f","#5e8462","#95a96c"]
    var color: String = colors[seed_value%3]
    var key := color+"canopy"
    if not batches.has(key):
        var mesh := SphereMesh.new()
        mesh.radius = 1
        mesh.height = 2
        mesh.radial_segments = 7
        mesh.rings = 3
        batches[key] = {"mesh":mesh,"color":color,"transforms":[]}
    var scale := 1.7+float(seed_value%4)*0.2
    batches[key].transforms.append(Transform3D(Basis.from_euler(Vector3(0,seed_value,0)).scaled(Vector3(scale,scale*1.35,scale)),p+Vector3(0,3.4,0)))
