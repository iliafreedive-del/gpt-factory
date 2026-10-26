extends Node3D
const Kit = preload("res://scripts/world/industrial_kit.gd")
var site: Dictionary
var kit
var cam: Camera3D
var plan_overlay: Node3D
var focus := Vector3(95,0,25)
var distance := 430.0
var azimuth := 0.5
var elevation := 0.95
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
    _plan_overlay()
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
    sun.directional_shadow_max_distance = 900
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

func _points(values: Array) -> PackedVector2Array:
    var result := PackedVector2Array()
    for point in values: result.append(Vector2(point[0],point[1]))
    return result

func _grounds() -> void:
    kit.board(_points(site.presentation_outline),3.8,"#b9bdac","#617573")
    for parcel in site.parcels: kit.polygon(_points(parcel.points),0.025,parcel.color)
    # The presentation board is cut away at the excluded southern neighbours;
    # the exclusion polygon is data for checks only, never a rendered quarter.
    for r in site.roads:
        var points := _points(r.points)
        kit.road(points,r.width)
        if r.markings:
            for i in range(points.size()-1):
                var a := Vector3(points[i].x,0.14,points[i].y)
                var b := Vector3(points[i+1].x,0.14,points[i+1].y)
                var length := a.distance_to(b)
                for j in range(int(length/10)):
                    var at := a.lerp(b,(j*10.0+2)/length)
                    kit.beam(at,at+(b-a).normalized()*2.7,0.09,"#d4d3b6")

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
            for row in range(maxi(1,int(z.d/5))):
                for col in range(2):
                    var colors := ["#b26043","#537a80","#be9855","#7e8d68"]
                    kit.container(p+Vector3(-4+col*8,0,-z.d/2+2.5+row*5),colors[(row+col)%4])
        "steel", "scrap":
            for i in range(12):
                kit.box(p+Vector3((i%3)*3-3,0.3+(i%2)*0.2,(i/3)*3-4),Vector3(2.1,0.25,0.8),"#566c6d")
    _label(z.name,p+Vector3(0,1,0),false)

func _infrastructure() -> void:
    kit.railway(_points(site.rail.points),site.rail.gauge)
    kit.gantry(site.gantry)
    kit.tower_crane(site.tower_crane)
    for fence in site.fences: kit.fence(_points(fence))
    for leaf in site.open_gate_leaves: kit.fence(_points(leaf),1.9)
    var checkpoint := Vector3(site.checkpoint.point[0],0,site.checkpoint.point[1])
    kit.box(checkpoint+Vector3(0,1.4,0),Vector3(3.2,2.8,3),"#c7c5ae")
    kit.box(checkpoint+Vector3(0,3,0),Vector3(3.7,0.2,3.5),"#657d78")
    kit.box(checkpoint+Vector3(0,1.6,1.55),Vector3(2.2,1.0,0.08),"#4b6f79")
    var gate := Vector3(site.checkpoint.gate[0],0,site.checkpoint.gate[1])
    kit.box(gate+Vector3(4,0.9,0),Vector3(0.4,1.8,0.4),"#bdad74")
    kit.beam(gate+Vector3(4,1.6,0),gate+Vector3(4,5.8,-3.5),0.16,"#d2b65b")
    for line in site.tree_lines:
        var points := _points(line.points)
        for segment in range(points.size()-1):
            var a := points[segment]
            var b := points[segment+1]
            var count := int(a.distance_to(b)/line.spacing)
            for i in count:
                var point := a.lerp(b,float(i)/maxi(1,count))
                kit.tree(Vector3(point.x,0,point.y),i+segment)
    for prop in site.props:
        var at := Vector3(prop.point[0],0,prop.point[1])
        match prop.kind:
            "pallet":kit.pallet(at)
            "truck":kit.truck(at)
            "forklift":kit.forklift(at)
            "steel":
                for level in range(3): kit.box(at+Vector3(0,0.3+level*0.2,0),Vector3(5.5,0.14,1.2),"#657776")
    # Lamps and small signs follow traced roads, not a rectangular invented grid.
    for index in [0,2,3,5]:
        var line: Dictionary = site.roads[index]
        var points := _points(line.points)
        for i in range(0,points.size(),2):
            var p := Vector3(points[i].x+line.width/2+1,0,points[i].y)
            kit.box(p+Vector3(0,3.5,0),Vector3(0.14,7,0.14),"#526e70")
            kit.box(p+Vector3(-0.7,7,0),Vector3(1.5,0.14,0.14),"#526e70")
            kit.box(p+Vector3(-1.3,6.9,0),Vector3(0.6,0.16,0.4),"#d7dbbd")

func _plan_overlay() -> void:
    plan_overlay = Node3D.new()
    add_child(plan_overlay)
    var overlay_kit = Kit.new(plan_overlay)
    for fence in site.fences:
        var points := _points(fence)
        for i in range(points.size()-1):
            overlay_kit.beam(Vector3(points[i].x,0.4,points[i].y),Vector3(points[i+1].x,0.4,points[i+1].y),0.5,"#d05c48")
    for road in site.roads:
        var points := _points(road.points)
        for i in range(points.size()-1):
            overlay_kit.beam(Vector3(points[i].x,0.2,points[i].y),Vector3(points[i+1].x,0.2,points[i+1].y),0.65,"#69bb61")
    overlay_kit.finish()
    for node in plan_overlay.get_children():
        node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        node.material_override.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    plan_overlay.visible = false

func _selectable(b: Dictionary) -> void:
    var body := StaticBody3D.new()
    body.position = Vector3(b.x,0,b.z)
    body.rotation_degrees.y = b.get("rotation",0)
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
    cam.far = 1800
    cam.near = 0.5
    cam.current = true
    add_child(cam)

func _update_camera() -> void:
    if cam == null:return
    cam.position = focus+Vector3(sin(azimuth)*cos(elevation),sin(elevation),cos(azimuth)*cos(elevation))*650
    cam.look_at(focus)
    cam.size = distance
    var occupied: Array[Rect2] = []
    for l in labels:
        var candidate: bool = label_mode and (l.get_meta("primary") if distance > 180 else (l.get_meta("major") or distance < 130))
        l.visible = candidate
        l.pixel_size = distance/get_viewport().get_visible_rect().size.y*15.0/l.font_size
        if not candidate: continue
        var point := cam.unproject_position(l.position)
        var width: float = minf(l.text.length()*8.0,450)
        var rect := Rect2(point-Vector2(width/2,12),Vector2(width,24)).grow(3)
        for previous in occupied:
            if rect.intersects(previous): l.visible=false;break
        if l.visible: occupied.append(rect)
    if scale_label != null:
        var metres: float = 5 if distance < 40 else (10 if distance < 100 else 25)
        var px: float = metres/distance*get_viewport().get_visible_rect().size.y
        scale_label.text = "%d м  ·  1 ед. = 1 м" % metres
        scale_line.custom_minimum_size.x = px
        scale_line.size.x = px
    if OS.has_feature("web"):
        var state := {"build":site.build,"capture_frame":Engine.get_process_frames(),"viewport_width":get_viewport().get_visible_rect().size.x,"map":site.map_version,"view":current_view,"labels":label_mode,"distance":distance,"selected":selected.get_meta("data").id if selected!=null else "","edit":edit_mode,"selected_x":selected.position.x if selected!=null else 0}
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
    _button(row,"План [5]",func(): _view(5))
    var row2 := HBoxContainer.new()
    c.add_child(row2)
    _button(row2,"−",func():distance=minf(600,distance*1.2);_update_camera())
    _button(row2,"+",func():distance=maxf(18,distance/1.2);_update_camera())
    _button(row2,"Названия [L]",func():label_mode=not label_mode;_update_camera())
    _button(row2,"Сдвиг [E]",func():_toggle_edit())
    _button(row2,"Восток [6]",func():_view(6))
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
    plan_overlay.visible = index == 5
    if index == 5: status.text = "План: красный — забор; зелёный — проезд\nЮжный перечёркнутый квартал исключён"
    azimuth = 0.5
    elevation = 0.95
    match index:
        1: focus=Vector3(95,0,25);distance=430
        2: focus=Vector3(36,0,-22);distance=94;elevation=0.65;azimuth=1.1
        3: focus=Vector3(73,0,-30);distance=145;elevation=0.8;azimuth=0.5
        4: focus=Vector3(-53,0,-1);distance=125;azimuth=0.35
        5: focus=Vector3(96,0,25);distance=325;azimuth=0;elevation=1.565
        6: focus=Vector3(193,0,52);distance=185;azimuth=0.35;elevation=0.95
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
            distance=clampf(distance*(0.88 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 1.12),18,600)
            _update_camera()
        if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
            var origin := cam.project_ray_origin(event.position)
            var query := PhysicsRayQueryParameters3D.create(origin,origin+cam.project_ray_normal(event.position)*1000)
            var hit := get_world_3d().direct_space_state.intersect_ray(query)
            if not hit.is_empty():
                selected = hit.collider
                var b: Dictionary = selected.get_meta("data")
                status.text = "%s\n%.1f × %.1f м · %s\nИсточник: %s" % [b.name,b.w,b.d,b.confidence,"2ГИС + ваша разметка" if b.id in ["red","lgc"] else "контур карты · оценка"]
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
        if event.keycode in [KEY_1,KEY_2,KEY_3,KEY_4,KEY_5,KEY_6]: _view(event.keycode-KEY_1+1)
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
    if OS.has_feature("web"): JavaScriptBridge.eval("window.factoryFrame="+str(Engine.get_process_frames()))
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
