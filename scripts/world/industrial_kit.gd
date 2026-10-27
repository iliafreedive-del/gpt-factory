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
        m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
        if hex in ["#737f7c", "#c8c2a4", "#b9b9a4", "#c7c8b2", "#9da49b"]:
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
    var basis := Basis.from_euler(rotation)*Basis.from_scale(size)
    batches[key].transforms.append(Transform3D(basis, pos))

func wheel(pos: Vector3, radius: float = 0.34, outward: float = 1.0) -> void:
    var key := "wheels"
    if not batches.has(key):
        var mesh := CylinderMesh.new()
        mesh.top_radius = 1.0
        mesh.bottom_radius = 1.0
        mesh.height = 1.0
        mesh.radial_segments = 12
        batches[key] = {"mesh": mesh, "color": "#293739", "transforms": []}
    batches[key].transforms.append(Transform3D(Basis.from_euler(Vector3(PI/2,0,0)).scaled(Vector3(radius,radius,0.20)),pos))
    box(pos+Vector3(0,0,outward*0.12),Vector3(radius*0.75,radius*0.75,0.05),"#b4c0bf")

func cylinder(pos: Vector3, radius: float, height: float, color: String) -> void:
    var key := color+"cylinder"
    if not batches.has(key):
        var mesh := CylinderMesh.new()
        mesh.top_radius=1
        mesh.bottom_radius=1
        mesh.height=1
        mesh.radial_segments=16
        batches[key]={"mesh":mesh,"color":color,"transforms":[]}
    batches[key].transforms.append(Transform3D(Basis.from_scale(Vector3(radius,height,radius)),pos))

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
        if entry.color in ["#82989a", "#acb5a8"]:
            node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

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
        for v in [face[0],face[2],face[1]]: st.add_vertex(v)
    st.generate_normals()
    var node := MeshInstance3D.new()
    node.mesh = st.commit()
    var mat := material(color).duplicate() as StandardMaterial3D
    mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    # Large coplanar triangles otherwise show shadow-map acne in WebGL closeups.
    # Keep directional lighting and cast roof shadows onto the yard/walls.
    mat.disable_receive_shadows = true
    node.material_override = mat
    node.position = center
    root.add_child(node)

func building(b: Dictionary) -> void:
    var start_counts := {}
    for key in batches: start_counts[key] = batches[key].transforms.size()
    var child_start := root.get_child_count()
    if b.style == "awning": _shelter(b)
    else: _building_body(b)

    var ranges := {}
    for key in batches:
        var first: int = start_counts.get(key,0)
        if batches[key].transforms.size() > first:
            ranges[key] = [first,batches[key].transforms.size()]
    var nodes: Array[Node3D] = []
    for i in range(child_start,root.get_child_count()): nodes.append(root.get_child(i))
    var world_transform := Transform3D(Basis(Vector3.UP,deg_to_rad(float(b.get("rotation",0)))),Vector3(b.x,0,b.z))
    for key in ranges:
        for i in range(ranges[key][0],ranges[key][1]): batches[key].transforms[i] = world_transform*batches[key].transforms[i]
    for node in nodes: node.transform = world_transform*node.transform
    building_ranges[b.id] = {"ranges":ranges,"nodes":nodes}

func _building_body(b: Dictionary) -> void:
    var p := Vector3.ZERO
    var w: float = b.w
    var d: float = b.d
    var h: float = b.h
    var color: String = b.color
    var office: bool = b.style == "office"
    if b.has("roof_color") and (office or b.get("roof_type","") == "flat"):
        material(b.roof_color).disable_receive_shadows = true
    box(p+Vector3(0,0.15,0),Vector3(w+1.2,0.3,d+1.2),"#8c9690")
    box(p+Vector3(0,h/2,0),Vector3(w,h,d),color)
    box(p+Vector3(0,0.5,0),Vector3(w+0.1,0.8,d+0.1),"#7f8984")
    if office or b.get("roof_type","") == "flat":
        box(p+Vector3(0,h+0.15,0),Vector3(w+0.5,0.3,d+0.5),b.get("roof_color","#6e7770"))
        for side in [-1,1]: box(p+Vector3(0,h+0.4,side*d/2),Vector3(w,0.5,0.18),color)
        for x in range(maxi(1,int(w/13))):
            box(p+Vector3(-w/2+5+x*13,h+0.4,0),Vector3(1.8,0.5,1.5),"#b6c1b4")
            box(p+Vector3(-w/2+5+x*13,h+0.7,0),Vector3(1.4,0.15,1.1),"#6e8585")
    else:
        var bays: int = b.get("roof_bays",1)
        var bay_depth: float = d/bays
        var rise: float = minf(2.4,bay_depth*0.16)
        var roof_color: String = b.get("roof_color", "#71878a" if b.style not in ["warehouse","third"] else "#8b4d3b")
        if b.style == "awning": roof_color = "#bda776"
        for bay in range(bays):
            var center_z: float = -d/2+bay_depth*(bay+0.5)
            roof(p+Vector3(0,h,center_z),w+0.7,bay_depth+0.3,rise,roof_color)
            box(p+Vector3(0,h+rise+0.06,center_z),Vector3(w+0.7,0.1,0.18),"#acb5a8")
            for x in range(int(w/3)):
                for side in [-1,1]:
                    var slope: float = atan2(rise,bay_depth/2)
                    # Local rotation must precede dimension scaling: the old global-axis
                    # scaling skewed roof seams and caused the triangular shadow streaks.
                    box(p+Vector3(-w/2+1+x*3,h+rise/2+0.07,center_z+side*bay_depth/4),Vector3(0.035,0.035,sqrt(bay_depth*bay_depth/4+rise*rise)),"#82989a",Vector3(side*slope,0,0))
            if b.style in ["black","masonry"]:
                for x in range(int(w/18)):
                    box(p+Vector3(-w/2+9+x*18,h+rise*0.65+0.12,center_z-bay_depth*0.18),Vector3(3.5,0.12,1.2),"#a9c1bc",Vector3(-atan2(rise,bay_depth/2),0,0))
    # Corrugation and a structural rhythm; warm office masonry is distinct.
    if not office and b.style != "masonry":
        for x in range(int(w/0.8)):
            for side in [-1.0,1.0]:
                box(p+Vector3(-w/2+x*0.8, h/2+0.3,side*(d/2+0.04)),Vector3(0.045,h-0.7,0.07),"#879b9b" if b.style != "warehouse" else "#bb694c")
    var window_y: float = 1.7 if office else h*0.64
    for side in [-1.0,1.0]:
        box(p+Vector3(0,h-0.15,side*(d/2+0.25)),Vector3(w+0.6,0.17,0.22),"#d0d5c9")
        for x in range(int(w/8) if b.get("windows",true) and not b.has("ribbon_faces") else 0):
            var xx: float = -w/2+4+x*8
            box(p+Vector3(xx,window_y,side*(d/2+0.12)),Vector3(2.9,1.15,0.12),"#e0e6d4")
            box(p+Vector3(xx,window_y,side*(d/2+0.2)),Vector3(2.6,0.88,0.08),"#496f79")
            box(p+Vector3(xx,window_y,side*(d/2+0.27)),Vector3(0.08,0.9,0.08),"#b2c8c6")
        # gutters / downpipes
        box(p+Vector3(w/2-0.4,h/2,side*(d/2+0.35)),Vector3(0.15,h,0.15),"#697e7d")
    if b.style == "masonry" or office:
        for y in range(1,int(h*2)):
            for side in [-1,1]: box(p+Vector3(0,y*0.5,side*(d/2+0.035)),Vector3(w,0.025,0.045),"#9c9c8b")
    elif b.style != "awning":
        for z in range(int(d/0.7)):
            var zz: float = -d/2+z*0.7
            for side in [-1,1]:
                box(p+Vector3(side*(w/2+0.05),h/2,zz),Vector3(0.06,h-0.2,0.035),"#91a4a4" if b.style not in ["warehouse","third"] else "#ab7056")
    # Doors face the site roads. Loading portals occupy end wall.
    var front: float = b.get("front_sign",1.0)
    var doors: int = 4 if b.style == "black" else (3 if b.style == "garage" else 1)
    var portal_h: float = b.get("door_h", 2.3 if office else (5.0 if b.style == "construction" else minf(4.0,h-0.5)))
    var portal_w: float = b.get("door_w",1.1 if office else (5.2 if b.style == "construction" else (2.0 if b.style == "garage" else 3.8)))
    var threshold: float = 0.35 if office else 0.0
    for i in doors:
        var zz: float = (i-(doors-1)*0.5)*(d/4 if b.style == "black" else 2.5)
        box(p+Vector3(front*(w/2+0.08),threshold+portal_h/2,zz),Vector3(0.16,portal_h+0.3,portal_w+0.4),"#b4c0b8")
        box(p+Vector3(front*(w/2+0.18),threshold+portal_h/2,zz),Vector3(0.12,portal_h,portal_w),"#172b32" if b.style == "construction" else "#354d55")
        for y in range(0 if office or b.style == "construction" else 7):
            box(p+Vector3(front*(w/2+0.26),0.3+y*(portal_h-0.6)/6.0,zz),Vector3(0.06,0.05,portal_w),"#657b7b")
        if office and b.get("arched_entry",false):
            _arched_entry(Vector3(front*(w/2+0.28),threshold,zz),front)
        elif office:
            # Brick entrance porch from the annotated workshop reference, not a freight shutter.
            for step in range(3):
                box(p+Vector3(w/2+1.9-step*0.55,0.06+step*0.06,zz),Vector3(1.2,0.12+step*0.12,2.2),"#ae9275")
            box(p+Vector3(front*(w/2+1.1),2.9,zz),Vector3(2.5,0.15,2.8),"#697e78")
            for side in [-1,1]:
                box(p+Vector3(front*(w/2+2.1),1.4,zz+side*1.25),Vector3(0.075,2.8,0.075),"#617b75")
                beam(p+Vector3(front*(w/2+0.3),1.0,zz+side*1.25),p+Vector3(front*(w/2+2.2),0.8,zz+side*1.25),0.055,"#617b75")
            box(p+Vector3(front*(w/2+0.26),1.8,zz),Vector3(0.04,0.9,0.7),"#71908f")
        else:
            box(p+Vector3(front*(w/2+3),0.07,zz),Vector3(5.8,0.13,6),"#b7b9a6")
            for sign in [-1,1]: box(p+Vector3(front*(w/2+1.0),0.7,zz+sign*(portal_w/2+0.7)),Vector3(0.2,1.4,0.2),"#d0ad57")
    box(p+Vector3(-w*0.25,1.15,d/2+0.12),Vector3(1,2.3,0.18),"#455e62")
    box(p+Vector3(-w*0.25,2.5,d/2+0.6),Vector3(1.7,0.13,1.3),"#798e88")
    if b.style == "construction":
        # Photo: clad gable, still unfinished around the perimeter.
        for side in [-1,1]:
            for x in [w/2+0.6,w/2+2.4]:
                for z in [side*3.4,side*5.4]:box(p+Vector3(front*x,2.1,z),Vector3(0.1,4.2,0.1),"#a78e60")
                for y in [1.3,3.6]:box(p+Vector3(front*x,y,side*4.4),Vector3(0.1,0.1,2.0),"#b89f70")
            box(p+Vector3(front*(w/2+1.5),3.6,side*4.4),Vector3(2.1,0.12,2.2),"#ae9870")
        cylinder(p+Vector3(front*(w/2+1.4),0.45,portal_w/2+0.9),0.3,0.9,"#9e4935")
        # The southern neighbour is only about half a metre away: keep staging
        # on the open gable apron instead of drawing pallets through its wall.
        for i in range(5): box(p+Vector3(front*(w/2+4),0.20+i*0.14,-3),Vector3(1.4,0.12,5),"#7e9292")

    _facade_details(b)

func _arched_entry(p: Vector3, front: float) -> void:
    # Brick archivolts from video 00:08. Estimated human-scale geometry.
    for side in [-1,1]:
        for row in range(9):
            box(p+Vector3(front*0.1,0.1+row*0.2,side*0.78),Vector3(0.20,0.17,0.45),"#b59a7d")
    for ring in range(3):
        var radius: float = 0.70+ring*0.22
        for i in range(18):
            var angle: float = (i+0.5)*PI/18
            box(p+Vector3(front*0.13,1.72+sin(angle)*radius,cos(angle)*radius),Vector3(0.23,0.19,radius*PI/18-0.012),"#b59a7d" if i%3 else "#a88c70",Vector3(PI/2-angle,0,0))
    box(p+Vector3(front*0.03,1.04,0),Vector3(0.12,2.08,1.02),"#503f36")
    box(p+Vector3(front*0.11,1.24,-0.34),Vector3(0.05,0.05,0.15),"#c6c3ab")
    box(p+Vector3(front*0.15,2.49,0),Vector3(0.08,0.24,0.90),"#e2ddd0")

func _shelter(b: Dictionary) -> void:
    # Outdoor canvas station: open sides, bracing, roof and rolled curtain.
    var w: float = b.w
    var d: float = b.d
    var h: float = b.h
    box(Vector3(0,0.1,0),Vector3(w,0.2,d),"#959c90")
    roof(Vector3(0,h,0),w+0.45,d+0.35,0.65,b.get("roof_color","#c2bdaa"))
    for x in [-w/2,w/2]:
        for j in range(4):
            var z: float = -d/2+j*d/3
            box(Vector3(x,h/2,z),Vector3(0.13,h,0.13),"#6d7871")
        beam(Vector3(x,h,-d/2),Vector3(x,h,d/2),0.14,"#727c74")
        beam(Vector3(x,0.25,-d/2),Vector3(x,h,-d/2+d/3),0.075,"#727c74")
    for z in [-d/2,d/2]:
        beam(Vector3(-w/2,h,z),Vector3(w/2,h,z),0.13,"#727c74")
        for i in range(4):
            var x: float = -w/2+i*w/3
            beam(Vector3(x,h,z),Vector3(0,h+0.65,z),0.07,"#727c74")
    box(Vector3(0,1.4,-d/2),Vector3(w,2.8,0.08),"#aaa894")
    box(Vector3(0,h-0.25,d/2),Vector3(w,0.45,0.25),"#c9c4b0")
    pallet(Vector3(-2,0.15,-2),false)
    box(Vector3(-2,1.05,-2),Vector3(2.8,0.10,1.6),"#8f9690")
    for x in [-3.1,-0.9]:
        for z in [-2.6,-1.4]: box(Vector3(x,0.6,z),Vector3(0.07,0.9,0.07),"#68776f")

func _facade_details(b: Dictionary) -> void:
    var w: float = b.w
    var d: float = b.d
    var h: float = b.h
    # Panel joints and long glazing replace the repeated little warehouse windows.
    for face in b.get("ribbon_faces",[]):
        var side: float = -1.0 if face == "-z" else 1.0
        var y: float = b.get("ribbon_y",2.0)
        var length: float = w-3.0
        box(Vector3(0,y,side*(d/2+0.16)),Vector3(length,1.05,0.11),"#e0ded0")
        box(Vector3(0,y,side*(d/2+0.23)),Vector3(length-0.15,0.86,0.07),"#698080")
        for i in range(int(length/1.45)+1):
            box(Vector3(-length/2+i*1.45,y,side*(d/2+0.29)),Vector3(0.06,1.0,0.06),"#c9c9b9")
        box(Vector3(0,y-0.65,side*(d/2+0.14)),Vector3(w,0.20,0.20),"#aeafa1")
        for i in range(int(w/6)+1):
            box(Vector3(-w/2+i*6,h/2,side*(d/2+0.11)),Vector3(0.12,h,0.15),"#c8c6b6")
    if b.get("blue_lower",false):
        box(Vector3(-w/2-0.10,1.65,0),Vector3(0.12,3.0,d-0.4),"#6b86a2")
        for i in range(int(d/0.45)):
            box(Vector3(-w/2-0.18,1.65,-d/2+0.3+i*0.45),Vector3(0.06,2.9,0.035),"#8b9fae")
        # A broad working entrance, rather than a human door, opens to the passage.
        box(Vector3(-w/2-0.21,1.55,2.0),Vector3(0.08,2.85,3.8),"#263638")
        box(Vector3(-w/2-0.45,3.25,2.0),Vector3(1.0,0.12,5.5),"#8a9288")
        for z in [-0.6,4.6]:
            box(Vector3(-w/2-0.85,1.6,z),Vector3(0.065,3.2,0.065),"#777f74")
    if b.get("exhaust",false):
        var at := Vector3(1.6,0,-d/2-1.0)
        box(at+Vector3(0,1.05,0),Vector3(1.4,2.1,1.3),"#a9a68a")
        cylinder(at+Vector3(0,4.15,0),0.49,4.1,"#b8b291")
        for y in [2.5,4.0,5.5]:
            cylinder(at+Vector3(0,y,0),0.54,0.09,"#c4c0a7")
        pipe(at+Vector3(0,6.1,0),Vector3(1.6,h-0.4,-d/2+0.5),0.40,"#b8b291")
        for side in [-1,1]:
            box(at+Vector3(side*0.72,3.0,0),Vector3(0.07,6,0.07),"#8c9280")
        for y in range(12):
            box(at+Vector3(0.65,0.5+y*0.43,-0.55),Vector3(0.40,0.035,0.035),"#7b8579")
    if b.get("roof_weathering",false):
        # Small flat-roof seams and patch repairs; no invented roof storey.
        for i in range(int(w/4)):
            box(Vector3(-w/2+2+i*4,h+0.315,0),Vector3(0.035,0.012,d-0.8),"#7d847b")
        for i in range(3):
            box(Vector3(-w/3+i*w/4,h+0.32,-d/5),Vector3(2.4,0.015,1.8),"#858c7f")

func pipe(a: Vector3, b: Vector3, radius: float, color: String) -> void:
    var direction := (b-a).normalized()
    var key := color+"cylinder"
    if not batches.has(key): cylinder(Vector3.ZERO,radius,0.01,color);batches[key].transforms.pop_back()
    var basis := Basis(Quaternion(Vector3.UP,direction))*Basis.from_scale(Vector3(radius,a.distance_to(b),radius))
    batches[key].transforms.append(Transform3D(basis,(a+b)/2))

func person(p: Vector3, rotation_y: float = 0.0, hi_vis: bool = true) -> void:
    # Exactly 1.75 m from sole to crown. An illustrative adult, not a measured worker.
    var before := {}
    for key in batches: before[key] = batches[key].transforms.size()
    var coat := "#d2a653" if hi_vis else "#587780"
    for side in [-1,1]:
        box(Vector3(side*0.115,0.055,0.04),Vector3(0.17,0.11,0.29),"#303e3c")
        box(Vector3(side*0.115,0.45,0),Vector3(0.16,0.68,0.19),"#46575a")
        beam(Vector3(side*0.26,1.35,0),Vector3(side*0.29,0.94,0.03),0.12,coat)
        box(Vector3(side*0.29,0.9,0.04),Vector3(0.10,0.14,0.11),"#c3a186")
    box(Vector3(0,1.13,0),Vector3(0.43,0.64,0.25),coat)
    if hi_vis:
        box(Vector3(0,1.04,0),Vector3(0.445,0.065,0.26),"#d8dfcb")
        for side in [-1,1]: box(Vector3(side*0.12,1.28,-0.135),Vector3(0.045,0.24,0.02),"#d8dfcb")
    cylinder(Vector3(0,1.615,0),0.115,0.27,"#c3a186")
    var transform := Transform3D(Basis(Vector3.UP,rotation_y),p)
    for key in batches:
        for i in range(before.get(key,0),batches[key].transforms.size()):
            batches[key].transforms[i] = transform*batches[key].transforms[i]

func yard_prop(prop: Dictionary) -> void:
    var before := {}
    for key in batches: before[key] = batches[key].transforms.size()
    var at := Vector3.ZERO
    match prop.kind:
        "pallet": pallet(at)
        "truck": truck(at)
        "forklift": forklift(at)
        "frames_stack": frame_stack(at,prop.get("levels",4))
        "trailer": trailer(at,false,prop.get("covered",false),prop.get("tandem",false))
        "person": person(at,0,prop.get("hi_vis",true))
        "car": car(at,prop.get("color","#a7b5b0"))
        "steel":
            for level in range(3): box(at+Vector3(0,0.3+level*0.2,0),Vector3(5.5,0.14,1.2),"#657776")
    var transform := Transform3D(Basis(Vector3.UP,deg_to_rad(float(prop.get("rotation",0)))),Vector3(prop.point[0],0.14,prop.point[1]))
    for key in batches:
        for i in range(before.get(key,0),batches[key].transforms.size()):
            batches[key].transforms[i] = transform*batches[key].transforms[i]

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

func trailer(p: Vector3, frame_only: bool = false, covered: bool = false, tandem: bool = false) -> void:
    # Illustrative approx. 4.4/5.5 m overall lengths including lights and A-frame.
    # Fender-to-fender widths are 2.26/2.51 m; these are not Alaska product CAD.
    var length: float = 4.0 if tandem else 2.9
    var width: float = 1.95 if tandem else 1.70
    var half: float = length/2
    var frame_color := "#303d3e" if frame_only else "#aab8b2"
    for side in [-1,1]:
        box(p+Vector3(0,0.64,side*width/2),Vector3(length,0.14,0.10),frame_color)
        beam(p+Vector3(half-0.5,0.64,side*width/2),p+Vector3(half+1.27,0.64,0),0.10,frame_color)
    for i in range(6 if tandem else 5):
        var x: float = -half+0.08+i*(length-0.16)/(5 if tandem else 4)
        box(p+Vector3(x,0.64,0),Vector3(0.075,0.10,width),frame_color)
    box(p+Vector3(half+1.30,0.64,0),Vector3(0.20,0.13,0.14),"#acb9b1" if not frame_only else frame_color)
    if frame_only: return
    box(p+Vector3(0,0.75,0),Vector3(length,0.10,width),"#8d998d")
    for side in [-1,1]:
        box(p+Vector3(0,1.03,side*(width/2+0.02)),Vector3(length+0.04,0.48,0.055),"#becac3")
        for y in [0.84,0.97,1.10,1.23]:
            box(p+Vector3(0,y,side*(width/2+0.055)),Vector3(length,0.025,0.035),"#d0d8c8")
        for x in [-half+0.1,0.0,half-0.1]:
            box(p+Vector3(x,1.04,side*(width/2+0.08)),Vector3(0.055,0.5,0.06),"#6f8585")
            box(p+Vector3(x,1.12,side*(width/2+0.12)),Vector3(0.08,0.10,0.03),"#a3afab")
        for ax in [-0.56,0.16] if tandem else [-0.18]:
            wheel(p+Vector3(ax,0.34,side*(width/2+0.09)),0.34,side)
        box(p+Vector3(-0.20,0.79,side*(width/2+0.09)),Vector3(1.70 if tandem else 1.05,0.12,0.38),"#8c9b9a")
    for x in [-half,half]: box(p+Vector3(x,1.02,0),Vector3(0.055,0.48,width),"#c0cbc0")
    for side in [-1,1]: box(p+Vector3(-half-0.04,0.72,side*width*0.35),Vector3(0.08,0.16,0.20),"#a84032")
    box(p+Vector3(-half-0.09,0.67,0),Vector3(0.04,0.17,0.40),"#d7d9c7")
    cylinder(p+Vector3(half+0.8,0.34,0),0.045,0.58,"#9baaa5")
    if covered:
        box(p+Vector3(0,1.68,0),Vector3(length-0.05,1.62,width-0.04),"#a9b2ad")
        for x in [-half+0.1,half-0.1]:
            for side in [-1,1]: box(p+Vector3(x,1.65,side*width/2),Vector3(0.025,1.5,0.025),"#d7d7c7")

func frame_stack(p: Vector3, count: int = 4) -> void:
    for x in [-1.05,1.05]: box(p+Vector3(x,0.09,0),Vector3(0.18,0.18,1.95),"#8e7d5e")
    for level in range(count): trailer(p+Vector3(0,-0.40+level*0.23,0),true)

func car(p: Vector3, color: String = "#a7b5b0") -> void:
    # 4.35 m saloon, another familiar size reference in the real courtyard.
    box(p+Vector3(0,0.65,0),Vector3(4.35,0.68,1.76),color)
    box(p+Vector3(-0.2,1.17,0),Vector3(2.30,0.57,1.55),color)
    box(p+Vector3(-0.18,1.25,0),Vector3(2.05,0.34,1.58),"#526b70")
    box(p+Vector3(-0.2,1.47,0),Vector3(1.8,0.07,1.50),color)
    for x in [-1.28,1.28]:
        for side in [-1,1]: wheel(p+Vector3(x,0.30,side*0.87),0.30,side)
    for side in [-1,1]:
        box(p+Vector3(2.20,0.70,side*0.55),Vector3(0.05,0.18,0.38),"#e1dec0")
        box(p+Vector3(-2.20,0.70,side*0.55),Vector3(0.05,0.18,0.30),"#ae5343")

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

func polygon(points: PackedVector2Array, y: float, color: String, surface_material: Material = null) -> void:
    var triangles := Geometry2D.triangulate_polygon(points)
    if triangles.is_empty(): return
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for index in triangles:
        var point := points[index]
        st.set_normal(Vector3.UP)
        st.set_uv(point*0.25)
        st.add_vertex(Vector3(point.x,y,point.y))
    var node := MeshInstance3D.new()
    node.mesh = st.commit()
    var mat := material(color).duplicate() as StandardMaterial3D
    mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    node.material_override = surface_material if surface_material != null else mat
    node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    root.add_child(node)

func concrete_material() -> ShaderMaterial:
    if not materials.has("yard_concrete"):
        var mat := ShaderMaterial.new()
        mat.shader = preload("res://scripts/shaders/yard_concrete.gdshader")
        materials["yard_concrete"] = mat
    return materials["yard_concrete"]

func road(points: PackedVector2Array, width: float, surface: String = "asphalt") -> void:
    if surface == "concrete":
        for outline in Geometry2D.offset_polyline(points,width/2,Geometry2D.JOIN_ROUND,Geometry2D.END_ROUND):
            polygon(outline,0.12,"#9da49b",concrete_material())
        return
    for outline in Geometry2D.offset_polyline(points,width/2+0.35,Geometry2D.JOIN_ROUND,Geometry2D.END_ROUND):
        polygon(outline,0.08,"#c8c5b2")
    for outline in Geometry2D.offset_polyline(points,width/2,Geometry2D.JOIN_ROUND,Geometry2D.END_ROUND):
        polygon(outline,0.12,"#737f7c")

func beam(a: Vector3, b: Vector3, thickness: float, color: String) -> void:
    var direction := (b-a).normalized()
    var up := Vector3.UP if absf(direction.y)<0.95 else Vector3.RIGHT
    var key := color+"box"
    if not batches.has(key): batches[key] = {"mesh":BoxMesh.new(),"color":color,"transforms":[]}
    var basis := Basis.looking_at(direction,up)*Basis.from_scale(Vector3(thickness,thickness,a.distance_to(b)))
    batches[key].transforms.append(Transform3D(basis,(a+b)/2))

func fence(points: PackedVector2Array, height: float = 2.25) -> void:
    for i in range(points.size()-1):
        var a := Vector3(points[i].x,0,points[i].y)
        var b := Vector3(points[i+1].x,0,points[i+1].y)
        var count := maxi(1,ceili(a.distance_to(b)/2.8))
        for j in range(count+1):
            var p := a.lerp(b,float(j)/count)
            box(p+Vector3(0,height/2,0),Vector3(0.12,height,0.12),"#536863")
            if j == count: continue
            var q := a.lerp(b,float(j+1)/count)
            for y in [0.35,height*0.55,height-0.15]: beam(p+Vector3(0,y,0),q+Vector3(0,y,0),0.045,"#7b8b7e")
            for k in range(6):
                var at := p.lerp(q,(k+0.5)/6.0)
                box(at+Vector3(0,height/2,0),Vector3(0.025,height-0.3,0.025),"#7b8b7e")

func railway(points: PackedVector2Array, gauge: float = 1.52) -> void:
    road(points,3.5)
    for i in range(points.size()-1):
        var a := Vector3(points[i].x,0,points[i].y)
        var b := Vector3(points[i+1].x,0,points[i+1].y)
        var normal := (b-a).normalized().cross(Vector3.UP)
        for side in [-1,1]: beam(a+normal*gauge/2*side+Vector3(0,0.3,0),b+normal*gauge/2*side+Vector3(0,0.3,0),0.11,"#5a6767")
        for j in range(int(a.distance_to(b)/1.4)):
            var p := a.lerp(b,float(j)/maxf(1,int(a.distance_to(b)/1.4)))
            beam(p-normal*1.3+Vector3(0,0.2,0),p+normal*1.3+Vector3(0,0.2,0),0.17,"#7a7361")

func tower_crane(c: Dictionary) -> void:
    var p := Vector3(c.center[0],0,c.center[1])
    var a := Vector3(c.rail_start[0],0.25,c.rail_start[1])
    var b := Vector3(c.rail_end[0],0.25,c.rail_end[1])
    for side in [-1,1]: beam(a+Vector3(side*2,0,0),b+Vector3(side*2,0,0),0.14,"#626d6b")
    for x in [-1.1,1.1]:
        for z in [-1.1,1.1]: box(p+Vector3(x,c.height/2,z),Vector3(0.18,c.height,0.18),"#b8a05e")
    for level in range(int(c.height/2.5)):
        var y: float = level*2.5
        for side in [-1.1,1.1]:
            beam(p+Vector3(-1.1,y,side),p+Vector3(1.1,y+2.5,side),0.1,"#c1a76a")
            beam(p+Vector3(side,y,-1.1),p+Vector3(side,y+2.5,1.1),0.1,"#c1a76a")
            beam(p+Vector3(-1.1,y,side),p+Vector3(1.1,y,side),0.1,"#8f855c")
    box(p+Vector3(0,0.6,0),Vector3(5.5,1.0,5.5),"#5a6b69")
    box(p+Vector3(0,c.height,0),Vector3(3,1.4,3),"#d1b66c")
    box(p+Vector3(-1.7,c.height-0.8,0),Vector3(1.4,2,1.7),"#53727a")
    # Lattice jib faces west over the container strip and loading yard.
    for side in [-0.65,0.65]:
        beam(p+Vector3(-c.boom,c.height+1.2,side),p+Vector3(10,c.height+1.2,side),0.18,"#b8a05e")
        beam(p+Vector3(-c.boom,c.height+2.6,0),p+Vector3(10,c.height+2.6,0),0.14,"#cbb172")
    for x in range(-int(c.boom),10,3):
        beam(p+Vector3(x,c.height+1.2,-0.65),p+Vector3(x+3,c.height+2.6,0),0.09,"#c1a76a")
        beam(p+Vector3(x,c.height+1.2,0.65),p+Vector3(x+3,c.height+2.6,0),0.09,"#c1a76a")
    box(p+Vector3(8,c.height+0.3,0),Vector3(3,2,3),"#7b8375")
    beam(p+Vector3(-c.boom*0.65,c.height+1,0),p+Vector3(-c.boom*0.65,3,0),0.045,"#354b50")
    box(p+Vector3(-c.boom*0.65,2.7,0),Vector3(0.4,0.6,0.4),"#b8a05e")

func gantry(c: Dictionary) -> void:
    var p := Vector3(c.center[0],0,c.center[1])
    for z in [-c.span/2,c.span/2]:
        beam(p+Vector3(-c.travel/2,0.22,z),p+Vector3(c.travel/2,0.22,z),0.13,"#687b76")
        for x in [-2,2]:
            box(p+Vector3(x,c.height/2,z),Vector3(0.35,c.height,0.45),"#ad8d50")
            box(p+Vector3(x,0.5,z),Vector3(1.8,0.5,0.8),"#526b68")
    for x in [-2,2]:
        box(p+Vector3(x,c.height,0),Vector3(0.45,0.7,c.span+1),"#c8aa5e")
    for z in range(-int(c.span/2),int(c.span/2)+1,3): box(p+Vector3(0,c.height,z),Vector3(4,0.18,0.16),"#bba15b")
    box(p+Vector3(0,c.height-0.5,0),Vector3(4,0.6,1.6),"#5d7474")
    beam(p+Vector3(0,c.height,0),p+Vector3(0,2,0),0.045,"#354b50")

func board(points: PackedVector2Array, depth: float, top_color: String, edge_color: String) -> void:
    polygon(points,0,top_color)
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    st.set_smooth_group(-1)
    for i in points.size():
        var p := points[i]
        var q := points[(i+1)%points.size()]
        var a := Vector3(p.x,0,p.y)
        var b := Vector3(q.x,0,q.y)
        var c := b-Vector3(0,depth,0)
        var d := a-Vector3(0,depth,0)
        for vertex in [a,c,b,a,d,c]:st.add_vertex(vertex)
    st.generate_normals()
    var node := MeshInstance3D.new()
    node.mesh = st.commit()
    var mat := material(edge_color).duplicate() as StandardMaterial3D
    mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    node.material_override = mat
    root.add_child(node)
