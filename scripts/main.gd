extends Node3D

# 1 Godot world unit is 1 real metre. Initial dimensions/positions are estimates.
var cam: Camera3D
var target := Vector3(0, 0, 0)
var distance := 305.0
var azimuth := 0.75
var elevation := 0.75
var rotating := false
var moving := false
var selected: StaticBody3D
var info: Label
var warehouse_items: Array[StaticBody3D] = []
var edit_mode := false

func _ready() -> void:
    _ground()
    _site_layout()
    _road(Vector3(0, 0.04, 31), Vector2(245, 13))
    _road(Vector3(15, 0.04, -35), Vector2(12, 130))
    # Illustrated site topology, NOT an accurate georeferenced survey.
    _building("ЛГЦ • действующий", Vector3(53, 0, -62), Vector3(51, 9, 19), Color("#98abb2"), true)
    _building("Новый цех • строительство", Vector3(116, 0, -62), Vector3(47, 10, 23), Color("#aebdc3"), true)
    _building("Чужое здание", Vector3(118, 0, 6), Vector3(48, 8, 27), Color("#8a6261"), true)
    _building("Красный склад комплектующих", Vector3(-21, 0, -55), Vector3(62, 7, 22), Color("#a84939"), true)
    _building("Цех 2 • малярка / сборка", Vector3(-57, 0, 8), Vector3(81, 8, 24), Color("#a7afb0"), true)
    _building("Цех 1 • сварка / сборка", Vector3(-140, 0, 5), Vector3(60, 8, 24), Color("#96aaa9"), true)
    _site_details()
    for i in range(12):
        _crate(Vector3(-40 + (i % 6) * 5, 0, -78 + int(i / 6) * 5))
    _camera()
    _ui()
    _update_cam()

func _ground() -> void:
    var terrain := MeshInstance3D.new()
    var plane := PlaneMesh.new()
    plane.size = Vector2(420, 260)
    terrain.mesh = plane
    terrain.material_override = _material(Color("#d8cfb9"))
    add_child(terrain)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-55, -25, 0)
    sun.light_energy = 1.1
    add_child(sun)
    var environment := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color("#e8eff1")
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color("#ffffff")
    env.ambient_light_energy = 0.7
    environment.environment = env
    add_child(environment)

func _material(color: Color) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 0.95
    return mat

func _part(parent: Node3D, dimensions: Vector3, at: Vector3, color: Color) -> MeshInstance3D:
    var piece := MeshInstance3D.new()
    var cube := BoxMesh.new()
    cube.size = dimensions
    piece.mesh = cube
    piece.position = at
    piece.material_override = _material(color)
    parent.add_child(piece)
    return piece

func _road(center: Vector3, dimensions: Vector2) -> void:
    _part(self, Vector3(dimensions.x, 0.06, dimensions.y), center, Color("#a29f95"))

func _building(title: String, at: Vector3, size: Vector3, tint: Color, roof: bool) -> void:
    var building := StaticBody3D.new()
    building.name = title
    building.position = at
    building.set_meta("size_m", size)
    add_child(building)
    _part(building, size, Vector3(0, size.y * 0.5, 0), tint)
    var hit := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    hit.shape = shape
    hit.position.y = size.y * 0.5
    building.add_child(hit)
    if roof:
        # Two inclined planes form the pitched sheet-metal roof.
        var half := size.z * 0.5
        var rise := min(3.2, half * 0.3)
        var slope_length := sqrt(half * half + rise * rise)
        for direction in [-1, 1]:
            var incline := MeshInstance3D.new()
            var roof_mesh := BoxMesh.new()
            roof_mesh.size = Vector3(size.x + 0.8, 0.22, slope_length + 0.5)
            incline.mesh = roof_mesh
            incline.rotation.x = direction * atan2(rise, half)
            incline.position = Vector3(0, size.y + rise * 0.5, direction * half * 0.5)
            incline.material_override = _material(tint.lightened(0.18))
            building.add_child(incline)
    # Approximate a wide, dark industrial door at the visible gable end.
    _part(building, Vector3(0.18, size.y * 0.63, min(7.0, size.z * 0.45)), Vector3(size.x * 0.5 + 0.13, size.y * 0.32, 0), Color("#243139"))
    var text := Label3D.new()
    text.text = title
    text.font_size = 40
    text.pixel_size = 0.028
    text.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    text.position = Vector3(0, size.y + 5, 0)
    text.no_depth_test = true
    text.outline_size = 8
    building.add_child(text)

func _crate(at: Vector3) -> void:
    var box := StaticBody3D.new()
    box.name = "Место хранения • образец"
    box.position = at
    box.set_meta("size_m", Vector3(2.2, 1.2, 1.5))
    _part(box, Vector3(2.2, 1.2, 1.5), Vector3(0, 0.6, 0), Color("#be8951"))
    var collider := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(2.2, 1.2, 1.5)
    collider.shape = shape
    collider.position.y = 0.6
    box.add_child(collider)
    add_child(box)
    warehouse_items.append(box)

func _camera() -> void:
    cam = Camera3D.new()
    cam.projection = Camera3D.PROJECTION_ORTHOGONAL
    cam.far = 1200.0
    cam.current = true
    add_child(cam)

func _update_cam() -> void:
    var dir := Vector3(sin(azimuth) * cos(elevation), sin(elevation), cos(azimuth) * cos(elevation))
    cam.position = target + dir * 300.0
    cam.look_at(target)
    cam.size = distance

func _ui() -> void:
    var canvas := CanvasLayer.new()
    add_child(canvas)
    var panel := PanelContainer.new()
    panel.position = Vector2(16, 16)
    canvas.add_child(panel)
    var column := VBoxContainer.new()
    panel.add_child(column)
    var title := Label.new()
    title.text = "АЛЯСКА  •  ЦИФРОВОЙ ЗАВОД  •  КАРТА v0.2"
    column.add_child(title)
    info = Label.new()
    info.text = "1 единица = 1 метр | ПЛАНИРОВКА ПРЕДВАРИТЕЛЬНАЯ"
    column.add_child(info)
    var controls := Label.new()
    controls.text = "Колесо — масштаб  •  ПКМ — поворот\nWASD — перемещение камеры  •  ЛКМ — выбрать\nE — режим перемещения  •  стрелки — двигать объект"
    column.add_child(controls)
    var btn := Button.new()
    btn.text = "Включить / выключить редактор [E]"
    btn.pressed.connect(func(): edit_mode = not edit_mode; _status())
    column.add_child(btn)
    _status()

func _status() -> void:
    if info == null:
        return
    var caption := "Редактирование" if edit_mode else "Просмотр"
    if selected != null:
        var dims: Vector3 = selected.get_meta("size_m", Vector3.ZERO)
        caption += " | " + selected.name + " | габариты: " + str(dims) + " м"
    else:
        caption += " | выбери объект"
    info.text = caption + " | ТЕРРИТОРИЯ v0.2"

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
            distance = maxf(12, distance * 0.85)
            _update_cam()
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
            distance = minf(440, distance * 1.15)
            _update_cam()
        elif event.button_index == MOUSE_BUTTON_RIGHT:
            rotating = event.pressed
        elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
            var origin := cam.project_ray_origin(event.position)
            var destination := origin + cam.project_ray_normal(event.position) * 1000.0
            var query := PhysicsRayQueryParameters3D.create(origin, destination)
            var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
            if not hit.is_empty() and hit["collider"] is StaticBody3D:
                selected = hit["collider"]
                _status()
    elif event is InputEventMouseMotion and rotating:
        azimuth -= event.relative.x * 0.007
        elevation = clampf(elevation - event.relative.y * 0.006, 0.22, 1.38)
        _update_cam()
    elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
        edit_mode = not edit_mode
        _status()

func _process(delta: float) -> void:
    var pan := 0.4 * distance * delta
    if Input.is_key_pressed(KEY_W): target.z -= pan
    if Input.is_key_pressed(KEY_S): target.z += pan
    if Input.is_key_pressed(KEY_A): target.x -= pan
    if Input.is_key_pressed(KEY_D): target.x += pan
    if edit_mode and selected != null:
        var step := 12.0 * delta
        if Input.is_key_pressed(KEY_UP): selected.position.z -= step
        if Input.is_key_pressed(KEY_DOWN): selected.position.z += step
        if Input.is_key_pressed(KEY_LEFT): selected.position.x -= step
        if Input.is_key_pressed(KEY_RIGHT): selected.position.x += step
    _update_cam()

# Site geometry is a traceable draft based on annotated 2GIS screenshots.
# Every coordinate uses metres; surveyed measurements can replace these constants.
func _site_layout() -> void:
    _zone("Двор производства", Vector3(-72, 0.015, -14), Vector2(214, 119), Color("#d9d4bf"))
    _zone("ЛГЦ / зона нового корпуса", Vector3(98, 0.017, -78), Vector2(141, 73), Color("#cbc9bc"))
    _zone("Открытый склад / чёрные рамы", Vector3(-71, 0.025, -97), Vector2(72, 25), Color("#f0e5c9"))
    _zone("Подъезд и маневрирование", Vector3(80, 0.027, -28), Vector2(154, 23), Color("#bcb9b0"))
    _zone("Сборка и выдача", Vector3(-100, 0.029, 45), Vector2(108, 18), Color("#e6dbbe"))
    _zone("Площадка готовой продукции", Vector3(-89, 0.032, 71), Vector2(128, 30), Color("#eee0b6"))
    _zone("Отгрузка дилерам", Vector3(-10, 0.033, 74), Vector2(48, 30), Color("#e6d8b0"))
    _road_between(Vector3(-179, 0.065, -35), Vector3(-179, 0.065, 37), 9.0)
    _road_between(Vector3(-179, 0.065, -35), Vector3(-102, 0.065, -35), 9.0)
    _road_between(Vector3(-102, 0.065, -35), Vector3(-102, 0.065, -13), 9.0)
    _road_between(Vector3(15, 0.065, 31), Vector3(145, 0.065, 31), 11.0)
    _road_between(Vector3(15, 0.065, 31), Vector3(15, 0.065, 92), 11.0)
    _road_between(Vector3(15, 0.065, -35), Vector3(15, 0.065, -115), 11.0)
    _road_between(Vector3(15, 0.065, -35), Vector3(151, 0.065, -35), 11.0)
    _road_between(Vector3(151, 0.065, -35), Vector3(151, 0.065, 31), 9.0)
    _road_between(Vector3(-153, 0.065, 64), Vector3(-25, 0.065, 64), 8.0)
    # Approximate property boundary; the third-party building is outside it.
    var edge: Array[Vector3] = [
        Vector3(-204, 0.14, -123), Vector3(156, 0.14, -123),
        Vector3(156, 0.14, -29), Vector3(155, 0.14, 36),
        Vector3(22, 0.14, 36), Vector3(22, 0.14, 101),
        Vector3(-202, 0.14, 101), Vector3(-204, 0.14, -123)
    ]
    for i in range(edge.size()-1):
        _boundary(edge[i], edge[i+1])
    _road_between(Vector3(22, 0.07, 101), Vector3(22, 0.07, 132), 11.0)

func _zone(title: String, center: Vector3, dimensions: Vector2, tint: Color) -> void:
    _part(self, Vector3(dimensions.x, 0.065, dimensions.y), center, tint)
    var t := Label3D.new()
    t.text = title
    t.font_size = 30
    t.pixel_size = 0.035
    t.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    t.position = center + Vector3(0, 0.7, 0)
    t.modulate = Color("#536056")
    t.outline_size = 4
    add_child(t)

func _road_between(a: Vector3, b: Vector3, width_m: float) -> void:
    var v := b-a
    var center := (a+b)*0.5
    var piece := _part(self, Vector3(width_m, 0.075, v.length()), center, Color("#aaa79b"))
    piece.rotation.y = atan2(-v.x, v.z)

func _boundary(a: Vector3, b: Vector3) -> void:
    var v := b-a
    var fence := _part(self, Vector3(0.14, 1.6, v.length()), (a+b)*0.5+Vector3(0,0.75,0), Color("#6b7474"))
    fence.rotation.y = atan2(-v.x, v.z)
    for i in range(int(v.length()/8.0)+1):
        var p := a + v * (float(i)/maxf(1.0,float(int(v.length()/8.0)))) 
        _part(self, Vector3(0.22, 2.1, 0.22), p+Vector3(0,1.0,0), Color("#49545a"))

func _site_details() -> void:
    # Visible production staging, compact material piles and truck access.
    _zone("Ожидание пескоструя", Vector3(-154, 0.10, -21), Vector2(34, 14), Color("#c8b7a3"))
    _zone("Ожидание малярки", Vector3(-72, 0.10, 34), Vector2(44, 9), Color("#c2b8a5"))
    _zone("Рамы и траверсы", Vector3(-72, 0.10, -103), Vector2(65, 13), Color("#e0d5b6"))
    _zone("Склад готовых прицепов", Vector3(-95, 0.10, 73), Vector2(97, 24), Color("#e4d7ae"))
    _zone("Контейнерная площадка", Vector3(49, 0.11, -14), Vector2(56, 17), Color("#d0c4ae"))
    for i in range(8):
        _part(self, Vector3(5.6, 2.5, 2.4), Vector3(26+float(i%4)*7.0, 1.3, -17+float(i/4)*3.6), Color("#697c83") if i%2 == 0 else Color("#a9734c"))
    for i in range(7):
        _part(self, Vector3(5.5, 0.28, 2.2), Vector3(-98+float(i)*8.0, 0.3, -105), Color("#414a4f"))
    for i in range(12):
        var x := -190.0 + float(i%6)*7.5
        var z := 83.0 + float(i/6)*8.0
        _part(self, Vector3(2.1, 0.7, 4.1), Vector3(x,0.45,z), Color("#95a9a9"))
    for i in range(17):
        var x := -196.0 + float(i%9)*25.0
        var z := -129.0 if i < 9 else 113.0
        _tree(Vector3(x,0,z))
    for i in range(7):
        _tree(Vector3(171.0,0,-120+float(i)*28))
    _zone("ЛГЦ: въезд и разгрузка", Vector3(61,0.095,-38), Vector2(45,12), Color("#dad1bd"))
    _zone("Строящийся цех: подъезд", Vector3(119,0.095,-38), Vector2(43,12), Color("#dbd2bf"))

func _tree(pos: Vector3) -> void:
    _part(self, Vector3(0.45,2.3,0.45), pos+Vector3(0,1.2,0), Color("#806c53"))
    var crown := MeshInstance3D.new()
    var mesh := SphereMesh.new()
    mesh.radius = 2.4
    mesh.height = 4.8
    crown.mesh = mesh
    crown.position = pos+Vector3(0,4.3,0)
    crown.material_override = _material(Color("#7e9b65"))
    add_child(crown)
