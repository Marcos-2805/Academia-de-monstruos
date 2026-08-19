extends Node3D

const WORLD_EXTENT := 42.0
const PLAYER_START := Vector3(0, 0.9, 9)

var player: CharacterBody3D
var ui: CanvasLayer
var info_label: Label
var dialog_panel: ColorRect
var dialog_label: Label
var mission_label: Label

var friendship := 0
var discovered: Array[String] = []
var quest_stage := 0

var interaction_target: Dictionary = {}

var npcs: Array[Dictionary] = []
var creatures: Array[Dictionary] = []

func _ready() -> void:
	_setup_input()
	_create_environment()
	_create_academy()
	_create_npcs()
	_create_creatures()
	_create_floor()
	_create_player()
	_create_ui()

	_show_dialog(
		"Bienvenido a la Academia de los Monstruos. Explora el patio y conoce a Luna."
	)

func _process(_delta: float) -> void:
	_update_interaction_target()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E:
			_interact()

# ============================================================
# CONTROLES
# ============================================================

func _setup_input() -> void:
	_add_key_action("move_forward", KEY_W)
	_add_key_action("move_back", KEY_S)
	_add_key_action("move_left", KEY_A)
	_add_key_action("move_right", KEY_D)

func _add_key_action(action: String, key: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)

	var event := InputEventKey.new()
	event.physical_keycode = key
	InputMap.action_add_event(action, event)

# ============================================================
# ENTORNO
# ============================================================

func _create_environment() -> void:
	var env := WorldEnvironment.new()
	var environment := Environment.new()

	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#8fcce8")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#e4f4ff")
	environment.ambient_light_energy = 0.72
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC

	env.environment = environment
	add_child(env)

	var sun := DirectionalLight3D.new()
	sun.light_energy = 0.9
	sun.rotation_degrees = Vector3(-52, -28, 0)
	sun.shadow_enabled = true
	add_child(sun)

	_create_box("Ground", Vector3(0, -0.15, 0), Vector3(84, 0.3, 84), Color("#79a65a"), false)
	_create_box("AcademySquare", Vector3(0, 0.02, 7), Vector3(30, 0.2, 26), Color("#d6c79d"), false)
	_create_box("PathMain", Vector3(0, 0.03, 20), Vector3(9, 0.2, 26), Color("#e2d1a3"), false)
	_create_box("PathCross", Vector3(0, 0.035, 8), Vector3(30, 0.16, 4.5), Color("#e0cfa1"), false)
	_create_box("Lake", Vector3(0, -0.02, -27), Vector3(84, 0.12, 18), Color("#4ca4c3"), false)

	_create_box("GardenLeft", Vector3(-11, 0.12, 8), Vector3(6, 0.22, 5), Color("#729b58"), false)
	_create_box("GardenRight", Vector3(11, 0.12, 8), Vector3(6, 0.22, 5), Color("#729b58"), false)
	_create_box("GardenFront", Vector3(0, 0.11, 13.0), Vector3(26, 0.2, 2.0), Color("#6f9954"), false)

	for z in [-16, -21, -26, -31, -36]:
		_create_pine(Vector3(-27, 0, z), 1.0 + (abs(z) - 14.0) * 0.03)
		_create_pine(Vector3(27, 0, z), 1.1 + (abs(z) - 14.0) * 0.03)

	for x in [-22, -16, 16, 22]:
		_create_pine(Vector3(x, 0, 18), 0.9)

	for x in [-34, -28, 28, 34]:
		_create_mountain(Vector3(x, 0, -3), 6.0 + abs(x) * 0.04, 15.0, Color("#8ba7b9"))

	_create_volcano(Vector3(31, 0, 28))
	_create_fountain(Vector3(0, 0.1, 12))

	_create_bench(Vector3(-9, 0.45, 10), 0.0)
	_create_bench(Vector3(9, 0.45, 10), 180.0)
	_create_bench(Vector3(-14, 0.45, 5), 90.0)
	_create_bench(Vector3(14, 0.45, 5), -90.0)

	for p in [
		Vector3(-5.3, 0, 16),
		Vector3(5.3, 0, 16),
		Vector3(-5.3, 0, 10),
		Vector3(5.3, 0, 10),
		Vector3(-5.3, 0, 4),
		Vector3(5.3, 0, 4)
	]:
		_create_lamp(p)

	for p in [
		Vector3(-12.0, 0.2, 7.0),
		Vector3(-10.3, 0.2, 8.8),
		Vector3(-9.2, 0.2, 7.0),
		Vector3(9.2, 0.2, 7.0),
		Vector3(10.3, 0.2, 8.8),
		Vector3(12.0, 0.2, 7.0),
		Vector3(-6.8, 0.2, 12.9),
		Vector3(-3.4, 0.2, 12.9),
		Vector3(3.4, 0.2, 12.9),
		Vector3(6.8, 0.2, 12.9)
	]:
		_create_flower_bed(p)

	_create_cloud(Vector3(-24, 18, 2), 1.0)
	_create_cloud(Vector3(18, 20, -6), 0.85)
	_create_cloud(Vector3(2, 23, 13), 0.75)
	_create_cloud(Vector3(-8, 16, -22), 0.65)

	_create_bird(Vector3(-14, 14, -2), 1.0)
	_create_bird(Vector3(7, 16, 8), 0.8)
	_create_bird(Vector3(22, 15, -16), 0.9)
	_create_bird(Vector3(-26, 13, -18), 0.75)

# ============================================================
# DECORACIÓN DEL PATIO Y CIELO
# ============================================================

func _create_bench(pos: Vector3, rotation_y: float) -> void:
	var root := Node3D.new()
	root.position = pos
	root.rotation_degrees.y = rotation_y
	add_child(root)

	var seat := MeshInstance3D.new()
	var seat_mesh := BoxMesh.new()
	seat_mesh.size = Vector3(2.8, 0.22, 0.75)
	seat.mesh = seat_mesh
	seat.position = Vector3(0, 0.45, 0)
	seat.material_override = _mat(Color("#754d37"))
	root.add_child(seat)

	for x in [-1.05, 1.05]:
		var leg := MeshInstance3D.new()
		var leg_mesh := BoxMesh.new()
		leg_mesh.size = Vector3(0.18, 0.55, 0.18)
		leg.mesh = leg_mesh
		leg.position = Vector3(x, 0.18, 0)
		leg.material_override = _mat(Color("#4e3729"))
		root.add_child(leg)

func _create_lamp(pos: Vector3) -> void:
	var root := Node3D.new()
	root.position = pos
	add_child(root)

	var post := MeshInstance3D.new()
	var post_mesh := CylinderMesh.new()
	post_mesh.top_radius = 0.09
	post_mesh.bottom_radius = 0.12
	post_mesh.height = 2.8
	post.mesh = post_mesh
	post.position.y = 1.4
	post.material_override = _mat(Color("#3f3b43"))
	root.add_child(post)

	var cap := MeshInstance3D.new()
	var cap_mesh := SphereMesh.new()
	cap_mesh.radius = 0.24
	cap_mesh.height = 0.48
	cap.mesh = cap_mesh
	cap.position.y = 2.85
	cap.material_override = _mat(Color("#f4d37c"))
	root.add_child(cap)

	var light := OmniLight3D.new()
	light.position = Vector3(0, 2.85, 0)
	light.omni_range = 4.0
	light.light_energy = 0.65
	light.light_color = Color("#ffd98a")
	root.add_child(light)

func _create_flower_bed(pos: Vector3) -> void:
	var root := Node3D.new()
	root.position = pos
	add_child(root)

	var soil := MeshInstance3D.new()
	var soil_mesh := CylinderMesh.new()
	soil_mesh.top_radius = 0.62
	soil_mesh.bottom_radius = 0.72
	soil_mesh.height = 0.18
	soil.mesh = soil_mesh
	soil.position.y = 0.09
	soil.material_override = _mat(Color("#5d4735"))
	root.add_child(soil)

	var flower_colors := [Color("#e875b2"), Color("#9f8cff"), Color("#ffd36e"), Color("#72d7ff")]

	for i in range(4):
		var stem := MeshInstance3D.new()
		var stem_mesh := CylinderMesh.new()
		stem_mesh.top_radius = 0.025
		stem_mesh.bottom_radius = 0.04
		stem_mesh.height = 0.45
		stem.mesh = stem_mesh
		stem.position = Vector3(-0.28 + i * 0.18, 0.38 + (i % 2) * 0.03, (-0.12 if i % 2 == 0 else 0.12))
		stem.material_override = _mat(Color("#4d873f"))
		root.add_child(stem)

		var bloom := MeshInstance3D.new()
		var bloom_mesh := SphereMesh.new()
		bloom_mesh.radius = 0.12
		bloom_mesh.height = 0.24
		bloom.mesh = bloom_mesh
		bloom.position = stem.position + Vector3(0, 0.3, 0)
		bloom.material_override = _mat(flower_colors[i % flower_colors.size()])
		root.add_child(bloom)

func _create_cloud(pos: Vector3, scale_factor: float) -> void:
	var root := Node3D.new()
	root.position = pos
	root.scale = Vector3.ONE * scale_factor
	add_child(root)

	var offsets := [Vector3(-2.0, 0.0, 0), Vector3(-0.7, 0.55, 0), Vector3(0.7, 0.45, 0), Vector3(2.0, 0.05, 0), Vector3(0.0, 0.15, 0.55)]

	for i in range(offsets.size()):
		var puff := MeshInstance3D.new()
		var puff_mesh := SphereMesh.new()
		puff_mesh.radius = 1.35 if i == 1 or i == 2 else 1.05
		puff_mesh.height = puff_mesh.radius * 1.7
		puff.mesh = puff_mesh
		puff.position = offsets[i]
		puff.scale = Vector3(1.4, 0.75, 1.0)
		puff.material_override = _mat(Color("#f7fbff"))
		root.add_child(puff)

func _create_bird(pos: Vector3, scale_factor: float) -> void:
	var root := Node3D.new()
	root.position = pos
	root.scale = Vector3.ONE * scale_factor
	add_child(root)

	var wing_left := MeshInstance3D.new()
	var wing_mesh_left := BoxMesh.new()
	wing_mesh_left.size = Vector3(0.75, 0.08, 0.22)
	wing_left.mesh = wing_mesh_left
	wing_left.rotation_degrees.z = -18.0
	wing_left.position = Vector3(-0.34, 0, 0)
	wing_left.material_override = _mat(Color("#39404b"))
	root.add_child(wing_left)

	var wing_right := MeshInstance3D.new()
	var wing_mesh_right := BoxMesh.new()
	wing_mesh_right.size = Vector3(0.75, 0.08, 0.22)
	wing_right.mesh = wing_mesh_right
	wing_right.rotation_degrees.z = 18.0
	wing_right.position = Vector3(0.34, 0, 0)
	wing_right.material_override = _mat(Color("#39404b"))
	root.add_child(wing_right)

# ============================================================
# SUELO FÍSICO
# ============================================================

func _create_floor() -> void:
	var floor_body := StaticBody3D.new()
	floor_body.name = "WorldFloor"

	var collision := CollisionShape3D.new()
	collision.name = "FloorCollision"

	var shape := BoxShape3D.new()
	shape.size = Vector3(84.0, 1.0, 84.0)

	collision.shape = shape
	floor_body.position = Vector3(0.0, -0.5, 0.0)
	floor_body.add_child(collision)
	add_child(floor_body)

# ============================================================
# ACADEMIA
# ============================================================

func _create_academy() -> void:
	_create_box("AcademyMain", Vector3(0, 5.2, -1.8), Vector3(22, 10.4, 13.4), Color("#817971"), true)
	_create_box("AcademyBase", Vector3(0, 0.9, -1.1), Vector3(24, 1.8, 11.8), Color("#5c4b7c"), true)
	_create_box("AcademyFacade", Vector3(0, 5.15, 5.10), Vector3(20.0, 9.5, 0.35), Color("#9b8f85"), false)

	for x in [-10.0, 10.0]:
		_create_box("FacadeButtress", Vector3(x, 5.1, 5.30), Vector3(1.0, 9.8, 0.55), Color("#6d655f"), false)

	_create_box("FacadeCornice", Vector3(0, 9.7, 5.32), Vector3(20.5, 0.7, 0.6), Color("#c1b2a0"), false)

	_create_box("TowerLeft", Vector3(-8.5, 6.2, -1), Vector3(4.2, 12.4, 8), Color("#6a4e90"), true)
	_create_box("TowerRight", Vector3(8.5, 6.2, -1), Vector3(4.2, 12.4, 8), Color("#6a4e90"), true)
	_create_box("TowerCenter", Vector3(0, 7.2, -1), Vector3(5.2, 14.4, 7), Color("#76579d"), true)

	_create_roof(Vector3(-8.5, 14.0, -1), 3.7, Color("#4b396b"))
	_create_roof(Vector3(8.5, 14.0, -1), 3.7, Color("#4b396b"))
	_create_roof(Vector3(0, 16.2, -1), 4.4, Color("#4b396b"))

	for x in [-6.0, 6.0]:
		_create_window(Vector3(x, 7.0, 5.34), Vector2(2.4, 3.0))

	_create_window(Vector3(0, 8.0, 5.34), Vector2(2.6, 3.2))

	for x in [-8.5, 8.5]:
		_create_window(Vector3(x, 8.9, 3.15), Vector2(1.7, 2.5))

	_create_window(Vector3(0, 9.8, 2.65), Vector2(1.8, 2.5))

	_create_box("EntranceSteps", Vector3(0, 0.35, 5.2), Vector3(10, 0.7, 5), Color("#c7b58a"), true)
	_create_box("MainDoor", Vector3(0, 2.5, 5.38), Vector3(3.8, 4.8, 0.35), Color("#382c49"), false)
	_create_box("DoorGlow", Vector3(0, 2.5, 5.58), Vector3(3.15, 4.15, 0.06), Color("#87cdf0"), false)

	for x in [-2.25, 2.25]:
		_create_box("DoorPillar", Vector3(x, 3.0, 5.48), Vector3(0.6, 5.8, 0.7), Color("#c1b2a0"), false)

	_create_box("DoorLintel", Vector3(0, 5.9, 5.48), Vector3(5.1, 0.7, 0.7), Color("#c1b2a0"), false)
	_create_roof(Vector3(0, 7.25, 5.25), 3.2, Color("#4b396b"))

	for x in [-9.0, -6.0, -3.0, 3.0, 6.0, 9.0]:
		_create_box("Battlement", Vector3(x, 10.35, 5.25), Vector3(1.45, 1.0, 0.8), Color("#b3a59a"), false)

	for x in [-9.6, -8.5, -7.4, 7.4, 8.5, 9.6]:
		_create_box("TowerBattlement", Vector3(x, 12.75, 3.0), Vector3(0.7, 1.0, 1.0), Color("#b3a59a"), false)

	_create_flag(Vector3(-8.5, 18.0, -1), Color("#a97ad8"))
	_create_flag(Vector3(8.5, 18.0, -1), Color("#a97ad8"))
	_create_flag(Vector3(0, 20.6, -1), Color("#d58be8"))
	_create_torch(Vector3(-3.7, 4.6, 5.65))
	_create_torch(Vector3(3.7, 4.6, 5.65))

func _create_window(pos: Vector3, size: Vector2) -> void:
	_create_box("WindowGlass", pos, Vector3(size.x, size.y, 0.18), Color("#263849"), false)

	var frame_color := Color("#c1b2a0")
	var thickness := 0.22

	_create_box("WindowFrameTop", pos + Vector3(0, size.y * 0.5 + thickness * 0.5, 0.08), Vector3(size.x + 2.0 * thickness, thickness, 0.28), frame_color, false)
	_create_box("WindowFrameBottom", pos + Vector3(0, -size.y * 0.5 - thickness * 0.5, 0.08), Vector3(size.x + 2.0 * thickness, thickness, 0.28), frame_color, false)
	_create_box("WindowFrameLeft", pos + Vector3(-size.x * 0.5 - thickness * 0.5, 0, 0.08), Vector3(thickness, size.y, 0.28), frame_color, false)
	_create_box("WindowFrameRight", pos + Vector3(size.x * 0.5 + thickness * 0.5, 0, 0.08), Vector3(thickness, size.y, 0.28), frame_color, false)
	_create_box("WindowCrossVertical", pos + Vector3(0, 0, 0.1), Vector3(0.18, size.y, 0.22), frame_color, false)
	_create_box("WindowCrossHorizontal", pos + Vector3(0, 0, 0.1), Vector3(size.x, 0.18, 0.22), frame_color, false)

func _create_flag(pos: Vector3, color: Color) -> void:
	var pole := MeshInstance3D.new()
	var pole_mesh := CylinderMesh.new()
	pole_mesh.top_radius = 0.06
	pole_mesh.bottom_radius = 0.08
	pole_mesh.height = 4.0
	pole.mesh = pole_mesh
	pole.position = pos
	pole.material_override = _mat(Color("#6b4630"))
	add_child(pole)

	var banner := MeshInstance3D.new()
	var banner_mesh := BoxMesh.new()
	banner_mesh.size = Vector3(1.6, 1.0, 0.08)
	banner.mesh = banner_mesh
	banner.position = pos + Vector3(0.8, 1.0, 0)
	banner.material_override = _mat(color)
	add_child(banner)

func _create_torch(pos: Vector3) -> void:
	var holder := MeshInstance3D.new()
	var holder_mesh := CylinderMesh.new()
	holder_mesh.top_radius = 0.11
	holder_mesh.bottom_radius = 0.14
	holder_mesh.height = 0.9
	holder.mesh = holder_mesh
	holder.position = pos
	holder.material_override = _mat(Color("#5b3b29"))
	add_child(holder)

	var flame := MeshInstance3D.new()
	var flame_mesh := SphereMesh.new()
	flame_mesh.radius = 0.25
	flame_mesh.height = 0.5
	flame.mesh = flame_mesh
	flame.position = pos + Vector3(0, 0.55, 0)
	flame.material_override = _mat(Color("#ff8a3d"))
	add_child(flame)

	var light := OmniLight3D.new()
	light.position = pos + Vector3(0, 0.55, 0)
	light.omni_range = 5.0
	light.light_energy = 1.2
	light.light_color = Color("#ffb35c")
	add_child(light)

# ============================================================
# NPC
# ============================================================

func _create_npcs() -> void:
	_npc("Profesora Luna", Vector3(-5, 0.9, 8), Color("#c18cff"), "Profesora Luna")
	_npc("Profesor Bruno", Vector3(5, 0.9, 8), Color("#f0a35a"), "Profesor Bruno")
	_npc("Vera", Vector3(-9, 0.9, 14), Color("#ff77a8"), "Vera")
	_npc("Nico", Vector3(9, 0.9, 14), Color("#69d3ff"), "Nico")
	_npc("Director Magnus", Vector3(0, 0.9, -5), Color("#8796af"), "Director Magnus")

# ============================================================
# CRIATURAS
# ============================================================

func _create_creatures() -> void:
	_creature("Pompón", Vector3(12, 0.75, 16), Color("#ff9bd7"), "Activa pequeñas runas")
	_creature("Glim", Vector3(-14, 0.6, 23), Color("#fff3a3"), "Revela secretos")
	_creature("Brasa", Vector3(30, 0.8, 32), Color("#ff6b35"), "Enciende antorchas")
	_creature("Moko", Vector3(-27, 0.7, 29), Color("#72dc8e"), "Atraviesa pequeñas grietas")

# ============================================================
# JUGADOR
# ============================================================

func _create_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Player"
	player.set_script(load("res://scripts/player_3d.gd"))
	player.position = PLAYER_START
	add_child(player)

# ============================================================
# INTERFAZ
# ============================================================

func _create_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)

	info_label = Label.new()
	info_label.position = Vector2(24, 20)
	info_label.add_theme_font_size_override("font_size", 18)
	info_label.text = "ACADEMIA DE LOS MONSTRUOS"
	ui.add_child(info_label)

	mission_label = Label.new()
	mission_label.position = Vector2(24, 50)
	mission_label.add_theme_font_size_override("font_size", 16)
	mission_label.text = "Misión: Conoce a Luna"
	ui.add_child(mission_label)

	dialog_panel = ColorRect.new()
	dialog_panel.position = Vector2(130, 560)
	dialog_panel.size = Vector2(1020, 110)
	dialog_panel.color = Color(0.05, 0.08, 0.12, 0.9)
	ui.add_child(dialog_panel)

	dialog_label = Label.new()
	dialog_label.position = Vector2(25, 18)
	dialog_label.size = Vector2(970, 78)
	dialog_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialog_label.add_theme_font_size_override("font_size", 19)
	dialog_panel.add_child(dialog_label)

# ============================================================
# DETECTAR INTERACCIONES
# ============================================================

func _update_interaction_target() -> void:
	interaction_target = {}
	var best_distance := 2.8

	for npc in npcs:
		var d: float = player.global_position.distance_to(npc.position)
		if d < best_distance:
			best_distance = d
			interaction_target = npc

	for creature in creatures:
		if discovered.has(creature.name):
			continue
		var d: float = player.global_position.distance_to(creature.position)
		if d < best_distance:
			best_distance = d
			interaction_target = creature

# ============================================================
# INTERACTUAR
# ============================================================

func _interact() -> void:
	if interaction_target.is_empty():
		_show_dialog("No hay nadie cerca. Explora la academia y sus alrededores.")
		return

	if interaction_target.type == "npc":
		_talk_to_npc(interaction_target.name)
	else:
		_meet_creature(interaction_target.name)

# ============================================================
# DIÁLOGOS
# ============================================================

func _talk_to_npc(name: String) -> void:
	match name:
		"Profesora Luna":
			if quest_stage == 0:
				quest_stage = 1
				mission_label.text = "Misión: Encuentra a Glim"
				_show_dialog("Luna: He sentido una presencia extraña en el bosque. Busca a Glim y vuelve conmigo.")
			else:
				friendship += 3
				_show_dialog("Luna: Cada criatura que descubres te acerca a la verdad. Amistad +3.")
		"Profesor Bruno":
			_show_dialog("Bruno: Cuando termine esta poción quizá deje de humear. ¡Quizá!")
		"Vera":
			friendship += 2
			_show_dialog("Vera: No pienso perder contra un alumno nuevo. Pero admito que tienes potencial. Amistad +2.")
		"Nico":
			_show_dialog("Nico: Hay un camino detrás de la academia que llega hasta el lago. Nunca voy solo.")
		"Director Magnus":
			_show_dialog("Magnus: La Torre Antigua está cerrada por un motivo. Todavía no estás preparado.")

# ============================================================
# ENCONTRAR CRIATURA
# ============================================================

func _meet_creature(name: String) -> void:
	if discovered.has(name):
		return

	discovered.append(name)
	friendship += 5
	var ability := ""

	for creature in creatures:
		if creature.name == name:
			ability = creature.ability
			break

	if name == "Glim" and quest_stage == 1:
		quest_stage = 2
		mission_label.text = "Misión: Vuelve con Luna"
		_show_dialog("¡Has encontrado a Glim! Su luz ha revelado un Fragmento de luz. Vuelve con Luna.")
	else:
		_show_dialog("¡Has descubierto a %s! Habilidad: %s. Amistad +5." % [name, ability])

# ============================================================
# MOSTRAR DIÁLOGO
# ============================================================

func _show_dialog(text: String) -> void:
	dialog_label.text = text
	dialog_panel.visible = true

# ============================================================
# CREAR NPC
# ============================================================

func _npc(name: String, pos: Vector3, color: Color, display_name: String) -> void:
	var root := _make_character(pos, color)
	root.name = name

	var label := Label3D.new()
	label.text = display_name
	label.position = Vector3(0, 2.7, 0)
	label.font_size = 32
	label.modulate = Color.WHITE
	root.add_child(label)

	npcs.append({"type": "npc", "name": name, "position": root.global_position})

# ============================================================
# CREAR CRIATURA
# ============================================================

func _creature(name: String, pos: Vector3, color: Color, ability: String) -> void:
	var root := Node3D.new()
	root.position = pos
	root.name = name
	add_child(root)

	var body := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.6
	mesh.height = 1.2
	body.mesh = mesh
	body.material_override = _mat(color)
	root.add_child(body)

	var eye1 := MeshInstance3D.new()
	var eye_mesh := SphereMesh.new()
	eye_mesh.radius = 0.06
	eye_mesh.height = 0.12
	eye1.mesh = eye_mesh
	eye1.position = Vector3(-0.18, 0.15, -0.52)
	eye1.material_override = _mat(Color("#2b2438"))
	root.add_child(eye1)

	var eye2 := eye1.duplicate() as MeshInstance3D
	eye2.position.x = 0.18
	root.add_child(eye2)

	var label := Label3D.new()
	label.text = name
	label.position = Vector3(0, 1.2, 0)
	label.font_size = 28
	root.add_child(label)

	creatures.append({"type": "creature", "name": name, "position": root.global_position, "ability": ability})

# ============================================================
# PERSONAJE NPC
# ============================================================

func _make_character(pos: Vector3, color: Color) -> Node3D:
	var root := Node3D.new()
	root.position = pos
	add_child(root)

	var body := MeshInstance3D.new()
	var body_mesh := CapsuleMesh.new()
	body_mesh.height = 1.25
	body_mesh.radius = 0.34
	body.mesh = body_mesh
	body.position = Vector3(0, 0.95, 0)
	body.material_override = _mat(color)
	root.add_child(body)

	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.34
	head_mesh.height = 0.68
	head.mesh = head_mesh
	head.position = Vector3(0, 1.85, 0)
	head.material_override = _mat(Color("#f2c7aa"))
	root.add_child(head)

	return root

# ============================================================
# CREAR BLOQUE
# ============================================================

func _create_box(name: String, pos: Vector3, size: Vector3, color: Color, collision: bool) -> Node3D:
	var body: Node3D
	if collision:
		body = StaticBody3D.new()
	else:
		body = Node3D.new()

	body.name = name
	body.position = pos
	add_child(body)

	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _mat(color)
	body.add_child(mesh_instance)

	if collision:
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = size
		shape.shape = box
		body.add_child(shape)

	return body

# ============================================================
# TEJADOS
# ============================================================

func _create_roof(pos: Vector3, radius: float, color: Color) -> void:
	var mesh_instance := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = radius
	mesh.height = radius * 1.4
	mesh.radial_segments = 4
	mesh_instance.mesh = mesh
	mesh_instance.position = pos
	mesh_instance.material_override = _mat(color)
	add_child(mesh_instance)

# ============================================================
# PINOS
# ============================================================

func _create_pine(pos: Vector3, scale_factor: float) -> void:
	var root := Node3D.new()
	root.position = pos
	root.scale = Vector3.ONE * scale_factor
	add_child(root)

	var trunk := MeshInstance3D.new()
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.18
	trunk_mesh.bottom_radius = 0.24
	trunk_mesh.height = 2.0
	trunk.mesh = trunk_mesh
	trunk.position.y = 1.0
	trunk.material_override = _mat(Color("#6b4630"))
	root.add_child(trunk)

	for y in [2.0, 2.7, 3.4]:
		var cone := MeshInstance3D.new()
		var cone_mesh := CylinderMesh.new()
		cone_mesh.top_radius = 0.0
		cone_mesh.bottom_radius = 1.25 - (y - 2.0) * 0.18
		cone_mesh.height = 1.6
		cone.mesh = cone_mesh
		cone.position.y = y
		cone.material_override = _mat(Color("#3f7b4a"))
		root.add_child(cone)

# ============================================================
# MONTAÑA
# ============================================================

func _create_mountain(pos: Vector3, radius: float, height: float, color: Color) -> void:
	var mesh_instance := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = radius
	mesh.height = height
	mesh_instance.mesh = mesh
	mesh_instance.position = pos + Vector3(0, height * 0.5 - 0.15, 0)
	mesh_instance.material_override = _mat(color)
	add_child(mesh_instance)

# ============================================================
# VOLCÁN
# ============================================================

func _create_volcano(pos: Vector3) -> void:
	_create_mountain(pos, 8.5, 10.0, Color("#8a5a4a"))

	var lava := MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.inner_radius = 2.2
	mesh.outer_radius = 2.7
	lava.mesh = mesh
	lava.position = pos + Vector3(0, 9.7, 0)
	lava.material_override = _mat(Color("#ff7a2f"))
	add_child(lava)

# ============================================================
# FUENTE
# ============================================================

func _create_fountain(pos: Vector3) -> void:
	var base := MeshInstance3D.new()
	var base_mesh := CylinderMesh.new()
	base_mesh.top_radius = 2.2
	base_mesh.bottom_radius = 2.4
	base_mesh.height = 0.7
	base.mesh = base_mesh
	base.position = pos
	base.material_override = _mat(Color("#bbb8be"))
	add_child(base)

	var water := MeshInstance3D.new()
	var water_mesh := CylinderMesh.new()
	water_mesh.top_radius = 1.8
	water_mesh.bottom_radius = 1.8
	water_mesh.height = 0.2
	water.mesh = water_mesh
	water.position = pos + Vector3(0, 0.45, 0)
	water.material_override = _mat(Color("#78d4ef"))
	add_child(water)

# ============================================================
# MATERIAL
# ============================================================

func _mat(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.8
	return material
