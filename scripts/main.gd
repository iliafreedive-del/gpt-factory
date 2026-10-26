extends Node3D

# 1 Godot world unit is 1 real metre. Initial dimensions/positions are estimates.
var cam: Camera3D
var target := Vector3(0, 0, 0)
var distance := 165.0
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
    _road(Vector3(0, 0.04, 31), Vector2(245, 13))
    _road(Vector3(15, 0.04, -35), Vector2(12, 130))
    # Illustrated site topology, NOT an accurate georeferenced survey.
    _building("ЛГЦ • действующий", Vector3(53, 0, -62), Vector3(51, 9, 19), Color("#98abb2"), true)
    _building("Новый цех • строительство", Vector3(116, 0, -62), Vector3(47, 10, 23), Color("#aebdc3"), true)
    _building("Чужое здание", Vector3(118, 0, 6), Vector3(48, 8, 27), Color("#8a6261"), true)
    _building("Красный склад комплектующих", Vector3(-21, 0, -55), Vector3(62, 7, 22), Color("#a84939"), true)
    _building("Цех 2 • малярка / сборка", Vector3(-57, 0, 8), Vector3(81, 8, 24), Color("#a7afb0"), true)
    _building("Цех 1 • сварка / сборка", Vector3(-140, 0, 5), Vector3(60, 8, 24), Color("#96aaa9"), true)
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
    title.text = "АЛЯСКА  •  ЦИФРОВОЙ ЗАВОД"
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
    info.text = caption

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
