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
    print("PASS mesh invariants: outward roof normals, metric AABB, orthogonal rotated details; actual 1.75 m adult and both complete trailer envelopes")
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
