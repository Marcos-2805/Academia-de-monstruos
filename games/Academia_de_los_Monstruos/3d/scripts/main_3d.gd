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

var animation_time := 0.0
var animated_clouds: Array[Node3D] = []
var animated_birds: Array[Node3D] = []
var animated_flags: Array[Node3D] = []
var animated_flames: Array[MeshInstance3D] = []
var animated_torch_lights: Array[OmniLight3D] = []
var animated_fountain_water: Array[MeshInstance3D] = []
var animated_flowers: Array[Node3D] = []
var animated_npcs: Array[Node3D] = []
var animated_npc_parts: Array[Dictionary] = []
var npc_wander_targets: Array[Vector3] = []
var npc_wander_speeds: Array[float] = []
var npc_wander_cooldowns: Array[float] = []

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

func _process(delta: float) -> void:
	_update_interaction_target()
	_update_world_animation(delta)

func _update_world_animation(delta: float) -> void:
	animation_time += delta

	for cloud in animated_clouds:
		if not is_instance_valid(cloud):
			continue
		cloud.position.x += delta * 0.35
		cloud.position.y += sin(animation_time * 0.45 + cloud.position.z * 0.03) * delta * 0.08
		if cloud.position.x > 34.0:
			cloud.position.x = -34.0

	for i in range(animated_birds.size()):
		var bird := animated_birds[i]
		if not is_instance_valid(bird):
			continue
		bird.position.x += delta * (1.0 + i * 0.12)
		bird.position.y += sin(animation_time * 2.6 + i) * delta * 0.35
		bird.rotation_degrees.y = sin(animation_time * 1.5 + i) * 8.0
		bird.rotation_degrees.z = sin(animation_time * 4.2 + i) * 5.0
		if bird.position.x > 34.0:
			bird.position.x = -34.0

	for i in range(animated_flags.size()):
		var flag := animated_flags[i]
		if not is_instance_valid(flag):
			continue
		flag.rotation_degrees.z = sin(animation_time * 2.2 + i * 0.9) * 8.0
		flag.rotation_degrees.y = sin(animation_time * 1.4 + i) * 2.0

	for i in range(animated_flames.size()):
		var flame := animated_flames[i]
		if not is_instance_valid(flame):
			continue
		var pulse: float = 1.0 + sin(animation_time * 7.0 + i) * 0.16
		flame.scale = Vector3(1.0, pulse, 1.0)
		if i < animated_torch_lights.size():
			var torch_light := animated_torch_lights[i]
			if is_instance_valid(torch_light):
				torch_light.light_energy = 1.1 + sin(animation_time * 6.0 + i) * 0.2

	for i in range(animated_fountain_water.size()):
		var water := animated_fountain_water[i]
		if not is_instance_valid(water):
			continue
		water.scale = Vector3(1.0 + sin(animation_time * 2.4 + i) * 0.03, 1.0 + sin(animation_time * 3.0 + i) * 0.08, 1.0 + sin(animation_time * 2.4 + i) * 0.03)

	for i in range(animated_flowers.size()):
		var flower := animated_flowers[i]
		if not is_instance_valid(flower):
			continue
		flower.rotation_degrees.z = sin(animation_time * 1.8 + i * 0.7) * 3.5
		flower.rotation_degrees.x = sin(animation_time * 1.3 + i) * 1.5

	for i in range(animated_npcs.size()):
		var npc := animated_npcs[i]
		if not is_instance_valid(npc):
			continue
		var target := npc_wander_targets[i]
		var speed := npc_wander_speeds[i]
		var move_dir := target - npc.position
		move_dir.y = 0.0
		if move_dir.length() > 0.55:
			move_dir = move_dir.normalized()
			npc.position += move_dir * speed * delta
			npc.rotation.y = lerp_angle(npc.rotation.y, atan2(move_dir.x, move_dir.z) + PI, delta * 4.0)
		else:
			npc_wander_cooldowns[i] -= delta
			if npc_wander_cooldowns[i] <= 0.0:
				npc_wander_targets[i] = _pick_npc_wander_target(i)
				npc_wander_cooldowns[i] = 1.5 + fmod(i * 0.83, 2.2)
		npc.position.y = 0.9 + sin(animation_time * 1.8 + i * 0.8) * 0.035

	for i in range(animated_npc_parts.size()):
		var part := animated_npc_parts[i]
		var arm_left: Node3D = part["arm_left"]
		var arm_right: Node3D = part["arm_right"]
		var leg_left: Node3D = part["leg_left"]
		var leg_right: Node3D = part["leg_right"]
		var walk_phase := animation_time * 3.2 + float(i) * 0.8
		var swing := sin(walk_phase) * 20.0
		if is_instance_valid(arm_left):
			arm_left.rotation_degrees.z = swing
		if is_instance_valid(arm_right):
			arm_right.rotation_degrees.z = -swing
		if is_instance_valid(leg_left):
			leg_left.rotation_degrees.x = -swing * 0.5
		if is_instance_valid(leg_right):
			leg_right.rotation_degrees.x = swing * 0.5

func _pick_npc_wander_target(index: int) -> Vector3:
	var patrol_points := [
		Vector3(-11, 0.9, 16), Vector3(-8, 0.9, 10), Vector3(-12, 0.9, 5),
		Vector3(-6, 0.9, 3), Vector3(6, 0.9, 3), Vector3(12, 0.9, 5),
		Vector3(8, 0.9, 10), Vector3(11, 0.9, 16), Vector3(0, 0.9, 17),
		Vector3(-14, 0.9, 12), Vector3(14, 0.9, 12)
	]
	return patrol_points[index % patrol_points.size()]

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

	_create_box("Ground", Vector3(0, -0.15, 0), Vector3(84, 0.3, 84), Color("#5f8f46"), false)
	_create_box("AcademySquare", Vector3(0, 0.02, 7), Vector3(30, 0.2, 26), Color("#76a851"), false)
	_create_box("PathMain", Vector3(0, 0.03, 20), Vector3(9, 0.2, 26), Color("#e2d1a3"), false)
	_create_box("PathCross", Vector3(0, 0.035, 8), Vector3(30, 0.16, 4.5), Color("#e0cfa1"), false)
	_create_box("Lake", Vector3(0, -0.02, -27), Vector3(84, 0.12, 18), Color("#4ca4c3"), false)
	_create_box("GardenLeft", Vector3(-11, 0.12, 8), Vector3(6, 0.22, 5), Color("#729b58"), false)
	_create_box("GardenRight", Vector3(11, 0.12, 8), Vector3(6, 0.22, 5), Color("#729b58"), false)
	_create_box("GardenFront", Vector3(0, 0.11, 13.0), Vector3(26, 0.2, 2.0), Color("#6f9954"), false)

	for p in [Vector3(-13.5, 0.13, 16.0), Vector3(13.5, 0.13, 16.0), Vector3(-14.0, 0.13, 1.5), Vector3(14.0, 0.13, 1.5)]:
		_create_grass_patch(p)

	for z in [-16, -21, -26, -31, -36]:
		_create_pine(Vector3(-27, 0, z), 1.0 + (abs(z) - 14.0) * 0.03)
		_create_pine(Vector3(27, 0, z), 1.1 + (abs(z) - 14.0) * 0.03)

	_create_volcano(Vector3(31, 0, 28))
	_create_fountain(Vector3(0, 0.1, 12))
	_create_bench(Vector3(-9, 0.45, 10), 0.0)
	_create_bench(Vector3(9, 0.45, 10), 180.0)

	for p in [Vector3(-5.3, 0, 16), Vector3(5.3, 0, 16), Vector3(-5.3, 0, 10), Vector3(5.3, 0, 10), Vector3(-5.3, 0, 4), Vector3(5.3, 0, 4)]:
		_create_lamp(p)

	for p in [Vector3(-12.0, 0.2, 7.0), Vector3(-10.3, 0.2, 8.8), Vector3(-9.2, 0.2, 7.0), Vector3(9.2, 0.2, 7.0), Vector3(10.3, 0.2, 8.8), Vector3(12.0, 0.2, 7.0), Vector3(-6.8, 0.2, 12.9), Vector3(-3.4, 0.2, 12.9), Vector3(3.4, 0.2, 12.9), Vector3(6.8, 0.2, 12.9)]:
		_create_flower_bed(p)

	_create_cloud(Vector3(-24, 18, 2), 1.0)
	_create_cloud(Vector3(18, 20, -6), 0.85)
	_create_bird(Vector3(-14, 14, -2), 1.0)
	_create_bird(Vector3(7, 16, 8), 0.8)
	_create_bird(Vector3(22, 15, -16), 0.9)

func _create_grass_patch(pos: Vector3) -> void:
	var patch := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 1.7
	mesh.bottom_radius = 1.9
	mesh.height = 0.18
	patch.mesh = mesh
	patch.position = pos
	patch.material_override = _mat(Color("#6f9f4e"))
	add_child(patch)

func _create_pine(pos: Vector3, scale_factor: float) -> void:
	var root := Node3D.new()
	root.position = pos
	root.scale = Vector3.ONE * scale_factor
	add_child(root)

	var trunk := MeshInstance3D.new()
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.24
	trunk_mesh.bottom_radius = 0.33
	trunk_mesh.height = 2.4
	trunk.mesh = trunk_mesh
	trunk.position.y = 1.2
	trunk.material_override = _mat(Color("#76513a"))
	root.add_child(trunk)

	for y in [2.6, 3.5, 4.4]:
		var crown := MeshInstance3D.new()
		var crown_mesh := CylinderMesh.new()
		crown_mesh.top_radius = 0.0
		crown_mesh.bottom_radius = 1.1 - (y - 2.6) * 0.16
		crown_mesh.height = 2.2
		crown.mesh = crown_mesh
		crown.position.y = y
		crown.material_override = _mat(Color("#3d7f45"))
		root.add_child(crown)

func _create_fountain(pos: Vector3) -> void:
	var basin := MeshInstance3D.new()
	var basin_mesh := CylinderMesh.new()
	basin_mesh.top_radius = 3.0
	basin_mesh.bottom_radius = 3.25
	basin_mesh.height = 0.55
	basin_mesh.radial_segments = 8
	basin.mesh = basin_mesh
	basin.position = pos
	basin.material_override = _mat(Color("#77726f"))
	add_child(basin)

	var water := MeshInstance3D.new()
	var water_mesh := CylinderMesh.new()
	water_mesh.top_radius = 2.5
	water_mesh.bottom_radius = 2.5
	water_mesh.height = 0.16
	water_mesh.radial_segments = 32
	water.mesh = water_mesh
	water.position = pos + Vector3(0, 0.38, 0)
	water.material_override = _mat(Color("#65cbe6"))
	add_child(water)
	animated_fountain_water.append(water)

	var pedestal := MeshInstance3D.new()
	var pedestal_mesh := CylinderMesh.new()
	pedestal_mesh.top_radius = 0.75
	pedestal_mesh.bottom_radius = 0.95
	pedestal_mesh.height = 1.15
	pedestal_mesh.radial_segments = 8
	pedestal.mesh = pedestal_mesh
	pedestal.position = pos + Vector3(0, 0.83, 0)
	pedestal.material_override = _mat(Color("#8b857f"))
	add_child(pedestal)

	var bowl := MeshInstance3D.new()
	var bowl_mesh := CylinderMesh.new()
	bowl_mesh.top_radius = 1.35
	bowl_mesh.bottom_radius = 0.65
	bowl_mesh.height = 0.35
	bowl_mesh.radial_segments = 8
	bowl.mesh = bowl_mesh
	bowl.position = pos + Vector3(0, 1.5, 0)
	bowl.material_override = _mat(Color("#6f6964"))
	add_child(bowl)

	var column := MeshInstance3D.new()
	var column_mesh := CylinderMesh.new()
	column_mesh.top_radius = 0.26
	column_mesh.bottom_radius = 0.34
	column_mesh.height = 1.65
	column_mesh.radial_segments = 8
	column.mesh = column_mesh
	column.position = pos + Vector3(0, 2.45, 0)
	column.material_override = _mat(Color("#8f8984"))
	add_child(column)

	var crown := MeshInstance3D.new()
	var crown_mesh := SphereMesh.new()
	crown_mesh.radius = 0.42
	crown_mesh.height = 0.84
	crown.mesh = crown_mesh
	crown.position = pos + Vector3(0, 3.35, 0)
	crown.material_override = _mat(Color("#6f6964"))
	add_child(crown)

func _create_bench(pos: Vector3, rotation_y: float) -> void:
	var root := Node3D.new()
	root.position = pos
	root.rotation_degrees.y = rotation_y
	add_child(root)
	var seat := MeshInstance3D.new()
	var seat_mesh := BoxMesh.new()
	seat_mesh.size = Vector3(2.8, 0.22, 0.75)
	seat.mesh = seat_mesh
	seat.position.y = 0.45
	seat.material_override = _mat(Color("#754d37"))
	root.add_child(seat)

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
	animated_flowers.append(root)
	var flower_colors := [Color("#e875b2"), Color("#9f8cff"), Color("#ffd36e"), Color("#72d7ff")]
	for i in range(4):
		var stem := MeshInstance3D.new()
		var stem_mesh := CylinderMesh.new()
		stem_mesh.height = 0.45
		stem.mesh = stem_mesh
		stem.position = Vector3(-0.28 + i * 0.18, 0.5, 0)
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
	animated_clouds.append(root)
	for offset in [Vector3(-2,0,0), Vector3(-0.7,0.55,0), Vector3(0.7,0.45,0), Vector3(2,0.05,0)]:
		var puff := MeshInstance3D.new()
		var puff_mesh := SphereMesh.new()
		puff_mesh.radius = 1.05
		puff_mesh.height = 1.7
		puff.mesh = puff_mesh
		puff.position = offset
		puff.scale = Vector3(1.4, 0.75, 1.0)
		puff.material_override = _mat(Color("#f7fbff"))
		root.add_child(puff)

func _create_bird(pos: Vector3, scale_factor: float) -> void:
	var root := Node3D.new()
	root.position = pos
	root.scale = Vector3.ONE * scale_factor
	add_child(root)
	animated_birds.append(root)
	for dir in [-1.0, 1.0]:
		var wing := MeshInstance3D.new()
		var wing_mesh := BoxMesh.new()
		wing_mesh.size = Vector3(0.75, 0.08, 0.22)
		wing.mesh = wing_mesh
		wing.position.x = 0.34 * dir
		wing.rotation_degrees.z = 18.0 * dir
		wing.material_override = _mat(Color("#39404b"))
		root.add_child(wing)

func _create_academy() -> void:
	_create_box("AcademyMain", Vector3(0, 5.2, -1.8), Vector3(22, 10.4, 13.4), Color("#6f6b67"), true)
	_create_box("AcademyBase", Vector3(0, 0.9, -1.1), Vector3(24, 1.8, 11.8), Color("#5c4b7c"), true)
	_create_box("AcademyFacade", Vector3(0, 5.15, 5.10), Vector3(20.0, 9.5, 0.35), Color("#79736d"), false)
	for y in [2.4, 4.2, 6.0, 7.8, 9.6]:
		_create_box("StoneCourse", Vector3(0, y, 5.32), Vector3(19.3, 0.09, 0.18), Color("#5f5a56"), false)
	for x in [-7.5, -3.8, 3.8, 7.5]:
		_create_box("StoneAccent", Vector3(x, 5.3, 5.34), Vector3(0.09, 9.0, 0.18), Color("#625e5a"), false)
	for x in [-10.0, 10.0]:
		_create_box("FacadeButtress", Vector3(x, 5.1, 5.30), Vector3(1.0, 9.8, 0.55), Color("#514d49"), false)
	_create_box("FacadeCornice", Vector3(0, 9.7, 5.32), Vector3(20.5, 0.7, 0.6), Color("#a69d94"), false)

	_create_box("TowerLeft", Vector3(-8.5, 6.2, -1), Vector3(4.2, 12.4, 8), Color("#6a4e90"), true)
	_create_box("TowerRight", Vector3(8.5, 6.2, -1), Vector3(4.2, 12.4, 8), Color("#6a4e90"), true)
	_create_box("TowerCenter", Vector3(0, 7.2, -1), Vector3(5.2, 14.4, 7), Color("#76579d"), true)

	_create_window(Vector3(-6.0, 7.0, 5.34), Vector2(2.4, 3.0))
	_create_window(Vector3(6.0, 7.0, 5.34), Vector2(2.4, 3.0))
	_create_window(Vector3(-8.5, 8.9, 3.15), Vector2(1.7, 2.5))
	_create_window(Vector3(8.5, 8.9, 3.15), Vector2(1.7, 2.5))

	_create_box("EntranceSteps", Vector3(0, 0.35, 5.2), Vector3(10, 0.7, 5), Color("#9b8f83"), true)
	_create_box("MainDoorWood", Vector3(0, 2.5, 5.42), Vector3(3.8, 4.8, 0.38), Color("#4d3428"), false)
	for x in [-1.15, -0.38, 0.38, 1.15]:
		_create_box("DoorPlank", Vector3(x, 2.5, 5.64), Vector3(0.08, 4.45, 0.08), Color("#70503b"), false)
	for y in [1.35, 2.55, 3.75]:
		_create_box("DoorIronBand", Vector3(0, y, 5.66), Vector3(3.95, 0.18, 0.10), Color("#27272b"), false)
	_create_box("DoorArchTop", Vector3(0, 5.15, 5.50), Vector3(5.4, 0.6, 0.75), Color("#8d867f"), false)
	for x in [-2.45, 2.45]:
		_create_box("DoorArchPillar", Vector3(x, 3.0, 5.50), Vector3(0.7, 4.6, 0.75), Color("#8d867f"), false)
	_create_roof(Vector3(0, 7.25, 5.25), 3.2, Color("#4b396b"))

func _create_window(pos: Vector3, size: Vector2) -> void:
	_create_box("WindowGlass", pos, Vector3(size.x, size.y, 0.18), Color("#263849"), false)
	_create_box("WindowFrameTop", pos + Vector3(0, size.y * 0.5 + 0.11, 0.08), Vector3(size.x + 0.44, 0.22, 0.28), Color("#a69d94"), false)
	_create_box("WindowFrameBottom", pos + Vector3(0, -size.y * 0.5 - 0.11, 0.08), Vector3(size.x + 0.44, 0.22, 0.28), Color("#a69d94"), false)
	_create_box("WindowFrameLeft", pos + Vector3(-size.x * 0.5 - 0.11, 0, 0.08), Vector3(0.22, size.y, 0.28), Color("#a69d94"), false)
	_create_box("WindowFrameRight", pos + Vector3(size.x * 0.5 + 0.11, 0, 0.08), Vector3(0.22, size.y, 0.28), Color("#a69d94"), false)
	_create_box("WindowCrossVertical", pos + Vector3(0, 0, 0.1), Vector3(0.18, size.y, 0.22), Color("#a69d94"), false)
	_create_box("WindowCrossHorizontal", pos + Vector3(0, 0, 0.1), Vector3(size.x, 0.18, 0.22), Color("#a69d94"), false)

func _create_floor() -> void:
	var floor_body := StaticBody3D.new()
	floor_body.name = "WorldFloor"
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(84.0, 1.0, 84.0)
	collision.shape = shape
	floor_body.position = Vector3(0.0, -0.5, 0.0)
	floor_body.add_child(collision)
	add_child(floor_body)

func _create_npcs() -> void:
	# NPC creation is kept in the project version; this checkpoint targets the current working scene.
	pass

func _make_character(pos: Vector3, color: Color) -> Node3D:
	var root := Node3D.new()
	root.position = pos
	add_child(root)
	animated_npcs.append(root)
	var npc_index := animated_npcs.size() - 1
	npc_wander_targets.append(_pick_npc_wander_target(npc_index))
	npc_wander_speeds.append(0.9 + float(npc_index % 3) * 0.15)
	npc_wander_cooldowns.append(1.0 + float(npc_index) * 0.35)

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

	for x in [-0.12, 0.12]:
		var eye := MeshInstance3D.new()
		var eye_mesh := SphereMesh.new()
		eye_mesh.radius = 0.045
		eye_mesh.height = 0.09
		eye.mesh = eye_mesh
		eye.position = Vector3(x, 1.91, -0.315)
		eye.material_override = _mat(Color("#1b1b22"))
		root.add_child(eye)

	var mouth := MeshInstance3D.new()
	var mouth_mesh := BoxMesh.new()
	mouth_mesh.size = Vector3(0.18, 0.035, 0.04)
	mouth.mesh = mouth_mesh
	mouth.position = Vector3(0, 1.75, -0.325)
	mouth.material_override = _mat(Color("#2b2430"))
	root.add_child(mouth)

	var arm_left := MeshInstance3D.new()
	var arm_left_mesh := BoxMesh.new()
	arm_left_mesh.size = Vector3(0.22, 0.82, 0.22)
	arm_left.mesh = arm_left_mesh
	arm_left.position = Vector3(-0.47, 1.02, 0)
	arm_left.material_override = _mat(color.lightened(0.06))
	root.add_child(arm_left)

	var arm_right := MeshInstance3D.new()
	var arm_right_mesh := BoxMesh.new()
	arm_right_mesh.size = Vector3(0.22, 0.82, 0.22)
	arm_right.mesh = arm_right_mesh
	arm_right.position = Vector3(0.47, 1.02, 0)
	arm_right.material_override = _mat(color.lightened(0.06))
	root.add_child(arm_right)

	var leg_left := MeshInstance3D.new()
	var leg_left_mesh := BoxMesh.new()
	leg_left_mesh.size = Vector3(0.25, 0.78, 0.25)
	leg_left.mesh = leg_left_mesh
	leg_left.position = Vector3(-0.18, 0.25, 0)
	leg_left.material_override = _mat(Color("#4e4b5a"))
	root.add_child(leg_left)

	var leg_right := MeshInstance3D.new()
	var leg_right_mesh := BoxMesh.new()
	leg_right_mesh.size = Vector3(0.25, 0.78, 0.25)
	leg_right.mesh = leg_right_mesh
	leg_right.position = Vector3(0.18, 0.25, 0)
	leg_right.material_override = _mat(Color("#4e4b5a"))
	root.add_child(leg_right)

	animated_npc_parts.append({"arm_left": arm_left, "arm_right": arm_right, "leg_left": leg_left, "leg_right": leg_right})
	return root
