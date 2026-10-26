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
    print("PASS mesh invariants: outward roof normals, metric AABB, orthogonal rotated details")
    quit(0)
