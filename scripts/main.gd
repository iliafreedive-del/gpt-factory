extends Node3D
const Kit = preload("res://scripts/world/industrial_kit.gd")
var site: Dictionary
var kit
var cam: Camera3D
var focus := Vector3(-15,0,-8)
var distance := 310.0
var azimuth := 0.65
var elevation := 0.85
var dragging := false
var panning := false
var labels: Array[Label3D] = []
var selected: StaticBody3D
var status: Label
var scale_label: Label
var scale_line: ColorRect
var tools_panel: PanelContainer
var details_panel: PanelContainer
var label_mode := false
var edit_mode := false
var current_view := 1
var viewport_size := Vector2.ZERO

func _ready() -> void:
    site = JSON.parse_string(FileAccess.get_file_as_string("res://data/site.json"))
    kit = Kit.new(self)
    _lighting()
    _grounds()
    for b in site.buildings:
        kit.building(b)
        _selectable(b)
    for zone in site.zones: _zone(zone)
    _infrastructure()
    kit.finish()
    _camera()
    _interface()
    _update_camera()

func _lighting() -> void:
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-52,-35,0)
    sun.light_color = Color("#fff1d0")
    sun.light_energy = 0.65
    sun.shadow_enabled = true
    sun.shadow_bias = 0.06
    sun.shadow_normal_bias = 2.0
    sun.directional_shadow_max_distance = 600
    sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
    add_child(sun)
    var world := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color("#263e49")
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color("#b9d2d1")
    env.ambient_light_energy = 0.3
    env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
    world.environment = env
    add_child(world)

func _grounds() -> void:
    kit.box(Vector3(-15,-1.9,-7),Vector3(326,3.5,207),"#617573")
    kit.box(Vector3(-15,-0.25,-7),Vector3(323,0.5,204),"#c8c2a4")
    kit.box(Vector3(-29,0.015,-6),Vector3(259,0.04,161),"#b9b9a4")
    kit.box(Vector3(106,0.025,22),Vector3(43,0.05,93),"#abb1a2")
    kit.box(Vector3(-28,0.09,-87),Vector3(288,0.12,8),"#9ba77c")
    kit.box(Vector3(140,0.09,0),Vector3(9,0.12,150),"#9ba77c")
    # Separate paved circulation from gravel and storage aprons.
    for r in site.roads:
        kit.box(Vector3(r.x,0.06,r.z),Vector3(r.w+0.8,0.12,r.d+0.8),"#ded9bb")
        kit.box(Vector3(r.x,0.13,r.z),Vector3(r.w,0.12,r.d),"#737f7c")
        if r.w > r.d:
            for i in range(int(r.w/9)):
                kit.box(Vector3(r.x-r.w/2+3+i*9,0.2,r.z),Vector3(3,0.025,0.12),"#dad8b9")
        else:
            for i in range(int(r.d/9)):
                kit.box(Vector3(r.x,0.2,r.z-r.d/2+3+i*9),Vector3(0.12,0.025,3),"#dad8b9")
    # Purposeful concrete panel joints across the principal yards.
    for x in range(-140,62,8):
        kit.box(Vector3(x,0.08,-58),Vector3(0.05,0.03,36),"#a0a695")
    for z in range(-77,-39,8): kit.box(Vector3(-40,0.08,z),Vector3(211,0.03,0.05),"#a0a695")

func _zone(z: Dictionary) -> void:
    var p := Vector3(z.x,0,z.z)
    kit.box(p+Vector3(0,0.11,0),Vector3(z.w,0.12,z.d),"#c7c8b2")
    for side in [-1,1]:
        kit.box(p+Vector3(0,0.18,side*z.d/2),Vector3(z.w,0.03,0.12),"#e3c770")
        kit.box(p+Vector3(side*z.w/2,0.18,0),Vector3(0.12,0.03,z.d),"#e3c770")
    match z.kind:
        "trailers":
            for row in range(maxi(1,int(z.d/4))):
                for col in range(maxi(1,int(z.w/6))):
                    var at := p+Vector3(-z.w/2+3+col*6,0,-z.d/2+2+row*4)
                    kit.trailer(at,false,(row+col)%5==0)
                    kit.box(at+Vector3(0,0.19,1.8),Vector3(5.2,0.02,0.08),"#eeebcf")
        "frames":
            for row in range(maxi(1,int(z.d/3))):
                for col in range(maxi(1,int(z.w/5))):
                    for level in range(2): kit.trailer(p+Vector3(-z.w/2+2.5+col*5,level*0.18,-z.d/2+1.5+row*3),true)
        "containers":
            for row in range(8):
                for col in range(2):
                    var colors := ["#b26043","#537a80","#be9855","#7e8d68"]
                    kit.container(p+Vector3(-4+col*8,0,-19+row*5),colors[(row+col)%4])
        "steel", "scrap":
            for i in range(12):
                kit.box(p+Vector3((i%3)*3-3,0.3+(i%2)*0.2,(i/3)*3-4),Vector3(2.1,0.25,0.8),"#566c6d")
    _label(z.name,p+Vector3(0,1,0),false)

func _infrastructure() -> void:
    # Railway north of the site and two separate gantry running rails.
    for z in [-96.76,-95.24]: kit.box(Vector3(-24,0.35,z),Vector3(285,0.18,0.10),"#59696c")
    kit.box(Vector3(-24,0.07,-96),Vector3(288,0.12,4),"#8b9384")
    for x in range(-165,120,2): kit.box(Vector3(x,0.2,-96),Vector3(0.24,0.16,2.7),"#716a53")
    for z in [-77,-52]:
        kit.box(Vector3(14,0.3,z),Vector3(90,0.17,0.1),"#647b7a")
        for x in range(-30,60,3):kit.box(Vector3(x,0.2,z),Vector3(0.5,0.2,0.9),"#929889")
    for x in [22,28]:
        for z in [-77,-52]:
            kit.box(Vector3(x,5.1,z),Vector3(0.45,10,0.6),"#b18440",Vector3(0,0,0.08 if x==22 else -0.08))
            kit.box(Vector3(x,0.7,z),Vector3(2.4,0.65,0.9),"#586d6a")
        kit.box(Vector3(x,10.1,-64.5),Vector3(0.6,0.8,27),"#d4ab54")
    # Open twin-girder gantry, not a solid roof slab.
    for z in range(-77,-50,3):
        kit.box(Vector3(25,10.15,z),Vector3(6.2,0.25,0.18),"#c69a43")
    for x in [21.6,28.4]:
        kit.box(Vector3(x,10.7,-64.5),Vector3(0.07,0.07,27),"#e0bb68")
        for z in range(-77,-50,3): kit.box(Vector3(x,10.35,z),Vector3(0.06,0.8,0.06),"#e0bb68")
    kit.box(Vector3(25,10.4,-61),Vector3(5.5,0.2,1.6),"#b08b47")
    kit.box(Vector3(25,10.1,-61),Vector3(2,1,2),"#586e73")
    kit.box(Vector3(25,6.3,-61),Vector3(0.06,6.6,0.06),"#394f54")
    kit.box(Vector3(25,2.9,-61),Vector3(0.5,0.4,0.5),"#bba058")
    # Perimeter panels: deliberate open south gate, no road-obstructing fence.
    var points: Array = site.boundary
    for i in points.size():
        var a := Vector3(points[i][0],0,points[i][1])
        var b := Vector3(points[(i+1)%points.size()][0],0,points[(i+1)%points.size()][1])
        var length := a.distance_to(b)
        for j in range(int(length/3)+1):
            var p := a.lerp(b,float(j)/maxf(1,float(int(length/3))))
            if p.z > 71 and p.x > 50 and p.x < 68: continue
            kit.box(p+Vector3(0,1.25,0),Vector3(0.13,2.5,0.13),"#536d67")
            if j < int(length/3):
                var dir := (b-a).normalized()
                var center := p+dir*1.5
                var yaw := atan2(-dir.z,dir.x)
                for y in [0.5,1.3,2.1]: kit.box(center+Vector3(0,y,0),Vector3(3,0.055,0.06),"#7d9282",Vector3(0,yaw,0))
                for k in range(6):kit.box(center+dir*(-1.3+k*0.5)+Vector3(0,1.3,0),Vector3(0.035,1.8,0.035),"#7d9282")
    for x in [50,68]:
        kit.box(Vector3(x,1.8,72),Vector3(0.6,3.6,0.6),"#c5bda0")
    kit.box(Vector3(57,1.1,72),Vector3(12,0.18,0.18),"#d2b557")
    kit.box(Vector3(72,1.4,67),Vector3(3.2,2.8,3),"#d4cfb4")
    kit.box(Vector3(72,3,67),Vector3(3.6,0.2,3.4),"#547574")
    kit.box(Vector3(72,1.7,68.55),Vector3(2.3,0.9,0.1),"#476c78")
    # Buffer planted along railway; staggered trees, not scattered through logistics lanes.
    for i in range(48): kit.tree(Vector3(-158+i*6,0,-87+(i%3)*1.2),i)
    for i in range(27): kit.tree(Vector3(139+(i%2)*3,0,-65+i*5.2),i+2)
    for i in range(18): kit.tree(Vector3(-165,0,-70+i*8),i)
    # Yard furnishings and purposeful cargo staging.
    for i in range(18): kit.pallet(Vector3(-15+(i%6)*1.7,0,-25+(i/6)*1.6))
    for i in range(10): kit.pallet(Vector3(-75+(i%5)*1.6,0,42+(i/5)*1.6))
    kit.forklift(Vector3(9,0,-55))
    kit.forklift(Vector3(-77,0,24))
    kit.forklift(Vector3(67,0,36))
    for z in [-17,-10]:
        for x in [53,55]: kit.box(Vector3(x,2.1,z),Vector3(0.12,4.2,0.12),"#aa895c")
        for y in [0.5,2.1,3.7]: kit.box(Vector3(54,y,z),Vector3(2.2,0.1,0.1),"#bd9f6e")
    for x in [53,55]:
        for y in [1.1,3.2]: kit.box(Vector3(x,y,-13.5),Vector3(0.1,0.1,7),"#bd9f6e")
    for z in [-21,-6]:
        kit.box(Vector3(54,0.65,z),Vector3(3,0.35,0.3),"#d4b04c")
        for x in [52.8,55.2]:kit.box(Vector3(x,0.45,z),Vector3(0.2,0.9,0.3),"#435c60")
    kit.truck(Vector3(45,0,-23))
    kit.truck(Vector3(-17,0,52))
    for i in range(5): kit.container(Vector3(102,0,47+i*4),"#657f83" if i%2==0 else "#af7951")
    # Lamps along main circulation, with offset booms.
    for x in range(-139,70,28):
        kit.box(Vector3(x,3.5,34),Vector3(0.16,7,0.16),"#526e70")
        kit.box(Vector3(x,7,35),Vector3(0.14,0.14,2),"#526e70")
        kit.box(Vector3(x,6.9,36),Vector3(0.7,0.2,0.4),"#d7dbbd")
    # Bay hazard markings at the loading apron and gates.
    for i in range(12): kit.box(Vector3(49+i*0.65,0.22,69),Vector3(0.28,0.03,3.2),"#e1bd58",Vector3(0,-0.6,0))

func _selectable(b: Dictionary) -> void:
    var body := StaticBody3D.new()
    body.position = Vector3(b.x,0,b.z)
    body.set_meta("data",b)
    var plaque := Label3D.new()
    plaque.text = b.name.split(" · ")[0].to_upper()
    plaque.font_size = 42
    plaque.pixel_size = 0.017
    plaque.position = Vector3(b.w/2+0.35,b.h-0.6,0)
    plaque.rotation_degrees.y = 90
    plaque.modulate = Color("#f1e7bd")
    plaque.outline_size = 7
    body.add_child(plaque)
    var hit := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(b.w,b.h,b.d)
    hit.shape = shape
    hit.position.y = b.h/2
    body.add_child(hit)
    add_child(body)
    _label(b.name,Vector3(b.x,b.h+4,b.z),true,b.id in ["lgc","new","red","shop1","shop2","black","third"])
    labels[-1].set_meta("building_id",b.id)

func _label(caption: String, pos: Vector3, major: bool, primary: bool = false) -> void:
    var l := Label3D.new()
    l.text = caption
    l.position = pos
    l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    l.font_size = 34 if major else 26
    l.pixel_size = 0.032
    l.modulate = Color("#edf0db") if major else Color("#e8c878")
    l.outline_modulate = Color("#203c45")
    l.outline_size = 10
    l.no_depth_test = true
    l.visible = false
    l.set_meta("major",major)
    l.set_meta("primary",primary)
    add_child(l)
    labels.append(l)

func _camera() -> void:
    cam = Camera3D.new()
    cam.projection = Camera3D.PROJECTION_ORTHOGONAL
    cam.far = 1200
    cam.near = 0.5
    cam.current = true
    add_child(cam)

func _update_camera() -> void:
    if cam == null:return
    cam.position = focus+Vector3(sin(azimuth)*cos(elevation),sin(elevation),cos(azimuth)*cos(elevation))*400
    cam.look_at(focus)
    cam.size = distance
    for l in labels:
        l.visible = label_mode and (l.get_meta("primary") if distance > 180 else (l.get_meta("major") or distance < 130))
        l.pixel_size = distance/get_viewport().get_visible_rect().size.y*15.0/l.font_size
    if scale_label != null:
        var metres: float = 5 if distance < 40 else (10 if distance < 100 else 25)
        var px: float = metres/distance*get_viewport().get_visible_rect().size.y
        scale_label.text = "%d м  ·  1 ед. = 1 м" % metres
        scale_line.custom_minimum_size.x = px
        scale_line.size.x = px
    if OS.has_feature("web"):
        var state := {"build":site.build,"map":site.map_version,"view":current_view,"labels":label_mode,"distance":distance,"selected":selected.get_meta("data").id if selected!=null else "","edit":edit_mode,"selected_x":selected.position.x if selected!=null else 0}
        var pick_points := {}
        for body in get_children():
            if body is StaticBody3D and body.has_meta("data"):
                var b: Dictionary = body.get_meta("data")
                var point := cam.unproject_position(body.position+Vector3(0,b.h/2,0))
                pick_points[b.id] = [point.x,point.y]
        state["pick_points"] = pick_points
        JavaScriptBridge.eval("window.factoryState="+JSON.stringify(state))

func _panel(parent: Node, anchors: int, offsets: Vector4, color: Color) -> PanelContainer:
    var panel := PanelContainer.new()
    parent.add_child(panel)
    panel.set_anchors_and_offsets_preset(anchors)
    panel.offset_left = offsets.x
    panel.offset_top = offsets.y
    panel.offset_right = offsets.z
    panel.offset_bottom = offsets.w
    var style := StyleBoxFlat.new()
    style.bg_color = color
    style.corner_radius_top_left = 9
    style.corner_radius_top_right = 9
    style.corner_radius_bottom_left = 9
    style.corner_radius_bottom_right = 9
    style.content_margin_left = 16
    style.content_margin_right = 16
    style.content_margin_top = 12
    style.content_margin_bottom = 12
    panel.add_theme_stylebox_override("panel",style)
    return panel

func _text(parent: Node, text: String, size: int = 16, color: Color = Color("#e3e9d8")) -> Label:
    var l := Label.new()
    l.text = text
    l.add_theme_font_size_override("font_size",size)
    l.add_theme_color_override("font_color",color)
    parent.add_child(l)
    return l

func _button(parent: Node, caption: String, action: Callable) -> void:
    var button := Button.new()
    button.text = caption
    button.add_theme_font_size_override("font_size",15)
    button.pressed.connect(action)
    parent.add_child(button)

func _interface() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    var top := _panel(layer,Control.PRESET_TOP_LEFT,Vector4(20,20,320,115),Color("#203940ed"))
    var title := VBoxContainer.new()
    top.add_child(title)
    _text(title,"АЛЯСКА  /  FACTORY ATLAS",23)
    _text(title,"01   ТЕРРИТОРИЯ И ЭКСТЕРЬЕР",12,Color("#d9bb6c"))
    _text(title,"Цифровой двойник · Красноярск",13)
    var version := _panel(layer,Control.PRESET_TOP_RIGHT,Vector4(-266,20,-20,108),Color("#203940ed"))
    var column := VBoxContainer.new()
    version.add_child(column)
    _text(column,"BUILD "+site.build+"   /   MAP "+site.map_version,17)
    _text(column,"ПЛАНИРОВКА ПРЕДВАРИТЕЛЬНАЯ",11,Color("#e1bd6c"))
    _text(column,"Ориентация севера не подтверждена",11)
    var tools := _panel(layer,Control.PRESET_BOTTOM_LEFT,Vector4(20,-126,485,-20),Color("#203940ed"))
    tools_panel = tools
    var c := VBoxContainer.new()
    tools.add_child(c)
    var row := HBoxContainer.new()
    c.add_child(row)
    _button(row,"Общий вид [1]",func(): _view(1))
    _button(row,"ЛГЦ [2]",func(): _view(2))
    _button(row,"Двор [3]",func(): _view(3))
    _button(row,"Цеха [4]",func(): _view(4))
    var row2 := HBoxContainer.new()
    c.add_child(row2)
    _button(row2,"−",func():distance=minf(380,distance*1.2);_update_camera())
    _button(row2,"+",func():distance=maxf(18,distance/1.2);_update_camera())
    _button(row2,"Названия [L]",func():label_mode=not label_mode;_update_camera())
    _button(row2,"Сдвиг [E]",func():_toggle_edit())
    _text(c,"ПКМ: орбита   ·   СКМ / WASD: сдвиг   ·   колесо: масштаб",12)
    var info := _panel(layer,Control.PRESET_BOTTOM_RIGHT,Vector4(-418,-126,-20,-20),Color("#203940ed"))
    details_panel = info
    var details := VBoxContainer.new()
    info.add_child(details)
    status = _text(details,"Выберите здание: размеры и источник\nЖёлтые зоны — логистические площадки",12)
    scale_label = _text(details,"",13,Color("#dfc77e"))
    scale_line = ColorRect.new()
    scale_line.color = Color("#dfc77e")
    scale_line.custom_minimum_size = Vector2(70,3)
    scale_line.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
    details.add_child(scale_line)

func _view(index: int) -> void:
    current_view = index
    azimuth = 0.65
    elevation = 0.85
    match index:
        1: focus=Vector3(-15,0,-8);distance=310
        2: focus=Vector3(28,0,-20);distance=85;elevation=0.65;azimuth=0.9
        3: focus=Vector3(-27,0,-56);distance=115;elevation=0.75
        4: focus=Vector3(-85,0,12);distance=125;azimuth=0.45
    _update_camera()

func _toggle_edit() -> void:
    edit_mode = not edit_mode
    status.text = "Сдвиг: выберите здание, стрелки = 1 м" if edit_mode else "Просмотр: выберите здание"
    if edit_mode: status.text += "\nЛокальный эскиз; исходная карта не меняется"
    _update_camera()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_RIGHT: dragging=event.pressed
        if event.button_index == MOUSE_BUTTON_MIDDLE: panning=event.pressed
        if event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
            distance=clampf(distance*(0.88 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 1.12),18,380)
            _update_camera()
        if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
            var origin := cam.project_ray_origin(event.position)
            var query := PhysicsRayQueryParameters3D.create(origin,origin+cam.project_ray_normal(event.position)*1000)
            var hit := get_world_3d().direct_space_state.intersect_ray(query)
            if not hit.is_empty():
                selected = hit.collider
                var b: Dictionary = selected.get_meta("data")
                status.text = "%s\n%.1f × %.1f м · %s\nИсточник: %s" % [b.name,b.w,b.d,b.confidence,"2ГИС, image(6)" if b.confidence.begins_with("MAP") else "оценка · Excel / 2ГИС"]
                _update_camera()
    if event is InputEventMouseMotion:
        if dragging:
            azimuth-=event.relative.x*0.006
            elevation=clampf(elevation+event.relative.y*0.005,0.25,1.45)
        if panning:
            focus+=(-cam.global_basis.x*event.relative.x+cam.global_basis.y*event.relative.y)*distance/get_viewport().get_visible_rect().size.y
            focus.y=0
        _update_camera()
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode in [KEY_1,KEY_2,KEY_3,KEY_4]: _view(event.keycode-KEY_1+1)
        if event.keycode==KEY_L:label_mode=not label_mode;_update_camera()
        if event.keycode==KEY_F and selected!=null:focus=selected.position;distance=70;_update_camera()
        if event.keycode==KEY_E: _toggle_edit()
        if edit_mode and selected!=null:
            var delta := Vector3.ZERO
            match event.keycode:
                KEY_LEFT:delta.x=-1
                KEY_RIGHT:delta.x=1
                KEY_UP:delta.z=-1
                KEY_DOWN:delta.z=1
            if delta!=Vector3.ZERO:
                var b: Dictionary = selected.get_meta("data")
                kit.move_building(b.id,delta)
                selected.position+=delta
                b.x+=delta.x
                b.z+=delta.z
                for l in labels:
                    if l.get_meta("building_id","")==b.id:l.position+=delta
                status.text = "%s: эскиз x=%.1f z=%.1f м\nСтрелки = 1 м · E завершить · перезагрузка сбросит" % [b.name,b.x,b.z]
                _update_camera()

func _process(delta: float) -> void:
    var speed := distance*delta*0.5
    var shift := Vector3.ZERO
    if Input.is_key_pressed(KEY_W):shift.z-=speed
    if Input.is_key_pressed(KEY_S):shift.z+=speed
    if Input.is_key_pressed(KEY_A):shift.x-=speed
    if Input.is_key_pressed(KEY_D):shift.x+=speed
    if shift!=Vector3.ZERO:focus+=shift;_update_camera()
    var size := get_viewport().get_visible_rect().size
    if size!=viewport_size:
        viewport_size=size
        var compact: bool = size.x < 1000
        tools_panel.scale = Vector2(0.85,0.85) if compact else Vector2.ONE
        details_panel.scale = Vector2(0.85,0.85) if compact else Vector2.ONE
        details_panel.offset_left = -350 if compact else -418
        _update_camera()
