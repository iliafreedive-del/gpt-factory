extends SceneTree
# Independent physical invariants: outward roof normals, metric dimensions,
# and orthogonal local axes for rotated architectural details.
func _initialize() -> void:
    var parent := Node3D.new()
    root.add_child(parent)
    var kit = load("res://scripts/world/industrial_kit.gd").new(parent)
    kit.roof(Vector3.ZERO,10,8,2,"#71878a")
    var roof_mesh: ArrayMesh = parent.get_child(0).mesh
    var normals: PackedVector3Array = roof_mesh.surface_get_arrays(0)[Mesh.ARRAY_NORMAL]
    for i in range(12):
        if normals[i].y < 0.5:
            push_error("Roof slope normal points inward: %s" % normals[i])
            quit(1)
            return
    if not roof_mesh.get_aabb().size.is_equal_approx(Vector3(10,2,8)):
        push_error("Roof geometry no longer uses metric dimensions")
        quit(1)
        return
    kit.box(Vector3.ZERO,Vector3(10,0.1,5),"#82989a",Vector3(0.2,0.3,0.1))
    kit.finish()
    var transform: Transform3D = kit.batches["#82989abox"].transforms[0]
    var axes := transform.basis
    if absf(axes.x.dot(axes.y))>0.001 or absf(axes.x.dot(axes.z))>0.001 or absf(axes.y.dot(axes.z))>0.001:
        push_error("Rotated industrial detail was skewed by global-axis scaling")
        quit(1)
        return
    if not axes.get_scale().is_equal_approx(Vector3(10,0.1,5)):
        push_error("Rotating a detail changed its metric dimensions")
        quit(1)
        return
    var reference_root := Node3D.new()
    root.add_child(reference_root)
    var person_kit = load("res://scripts/world/industrial_kit.gd").new(reference_root)
    person_kit.person(Vector3.ZERO)
    var adult := _batch_bounds(person_kit)
    if absf(adult.size.y-1.75)>0.001 or absf(adult.position.y)>0.001:
        push_error("Adult scale reference must stand exactly 1.75 m from sole to crown")
        quit(1)
        return
    for tandem in [false,true]:
        var trailer_kit = load("res://scripts/world/industrial_kit.gd").new(reference_root)
        trailer_kit.trailer(Vector3.ZERO,false,false,tandem)
        var trailer := _batch_bounds(trailer_kit)
        var nominal_length: float = 5.5 if tandem else 4.4
        var nominal_width: float = 2.5 if tandem else 2.3
        if absf(trailer.size.x-nominal_length)>0.1 or absf(trailer.size.z-nominal_width)>0.1:
            push_error("Trailer mesh does not fit the stated human-scale reference: %s" % trailer.size)
            quit(1)
            return
        if trailer.position.y < -0.001:
            push_error("Trailer wheel intersects the local ground")
            quit(1)
            return
    var shape_root := Node3D.new()
    root.add_child(shape_root)
    var shape_kit = load("res://scripts/world/industrial_kit.gd").new(shape_root)
    shape_kit.hip_roof(Vector3.ZERO,44,27,2.5,"#87928b")
    var hip: ArrayMesh = shape_root.get_child(0).mesh
    for normal in hip.surface_get_arrays(0)[Mesh.ARRAY_NORMAL]:
        if normal.y <= 0.1:
            push_error("Hipped roof has an inward slope normal")
            quit(1)
            return
    if not hip.get_aabb().size.is_equal_approx(Vector3(44,2.5,27)):
        push_error("Hipped roof changed the metric envelope")
        quit(1)
        return
    var outline := [[0,0],[6,0],[6,2],[2,2],[2,6],[0,6]]
    shape_kit._outlined_volume({"outline":outline,"h":4,"color":"#c3c5b7"})
    var roof_area := 0.0
    for node in shape_root.get_children():
        if not node is MeshInstance3D or node.mesh.get_aabb().position.y<4:continue
        var vertices: PackedVector3Array = node.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
        for i in range(0,vertices.size(),3):
            var triangle := PackedVector2Array()
            for j in range(3):triangle.append(Vector2(vertices[i+j].x,vertices[i+j].z))
            if Geometry2D.is_point_in_polygon(Vector2(4,4),triangle):
                push_error("Polygonal roof filled the recessed courtyard")
                quit(1)
                return
            roof_area += (vertices[i+1]-vertices[i]).cross(vertices[i+2]-vertices[i]).length()/2
    if absf(roof_area-20.0)>0.001:
        push_error("Concave roof area must be 20 m², not its 36 m² bounding box")
        quit(1)
        return
    _collision_outline_check.call_deferred(outline)

func _collision_outline_check(outline: Array) -> void:
    var holder := Node3D.new()
    holder.position = Vector3(400,0,400)
    root.add_child(holder)
    var body := StaticBody3D.new()
    holder.add_child(body)
    var hit := CollisionPolygon3D.new()
    var points := PackedVector2Array()
    for point in outline:points.append(Vector2(point[0],point[1]))
    hit.polygon=points
    hit.rotation.x=PI/2
    hit.depth=4
    hit.position.y=2
    body.add_child(hit)
    await physics_frame
    await physics_frame
    var space := holder.get_world_3d().direct_space_state
    var solid := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(401,10,401),Vector3(401,-1,401)))
    var court := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(404,10,404),Vector3(404,-1,404)))
    if solid.is_empty() or not court.is_empty():
        push_error("Polygon selection must hit the building and leave the courtyard empty")
        quit(1)
        return
    print("PASS mesh invariants: metric roofs and human/vehicle scales; hipped slopes; concave roof area; real physics picking leaves recessed courtyard empty")
    quit(0)

func _batch_bounds(kit) -> AABB:
    var result := AABB()
    var first := true
    for entry in kit.batches.values():
        for transform in entry.transforms:
            var bounds: AABB = transform*entry.mesh.get_aabb()
            result = bounds if first else result.merge(bounds)
            first = false
    return result
