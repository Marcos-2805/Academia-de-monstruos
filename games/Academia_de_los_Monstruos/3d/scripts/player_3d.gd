extends CharacterBody3D

@export var speed: float = 5.5
@export var acceleration: float = 18.0
@export var gravity: float = 18.0

var yaw := 0.0
var pitch := -0.22
var camera: Camera3D
var spring_arm: SpringArm3D
var visual_root: Node3D

func _ready() -> void:
	_create_visuals()
	_create_camera()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * 0.003
		pitch = clamp(pitch - event.relative.y * 0.002, -0.9, 0.35)
		rotation.y = yaw
		spring_arm.rotation.x = pitch
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		elif event.keycode == KEY_ENTER and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta: float) -> void:
	var input_2d := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var dir := Vector3(input_2d.x, 0.0, input_2d.y)
	if dir.length() > 1.0:
		dir = dir.normalized()

	var basis := global_transform.basis
	var forward := -basis.z
	var right := basis.x
	var move_dir := (right * dir.x + forward * -dir.y)
	move_dir.y = 0.0
	if move_dir.length() > 1.0:
		move_dir = move_dir.normalized()

	var target := move_dir * speed
	velocity.x = move_toward(velocity.x, target.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target.z, acceleration * delta)

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = -0.5

	if move_dir.length() > 0.1:
		var target_yaw := atan2(-move_dir.x, -move_dir.z)
		yaw = lerp_angle(yaw, target_yaw, min(delta * 8.0, 1.0))
		rotation.y = yaw

	move_and_slide()

func _create_camera() -> void:
	spring_arm = SpringArm3D.new()
	spring_arm.spring_length = 6.5
	spring_arm.margin = 0.2
	spring_arm.rotation.x = pitch
	add_child(spring_arm)

	camera = Camera3D.new()
	camera.current = true
	camera.fov = 65.0
	spring_arm.add_child(camera)

func _create_visuals() -> void:
	visual_root = Node3D.new()
	visual_root.name = "PlayerVisual"
	add_child(visual_root)

	var body := MeshInstance3D.new()
	var body_mesh := CapsuleMesh.new()
	body_mesh.height = 1.15
	body_mesh.radius = 0.34
	body.mesh = body_mesh
	body.position = Vector3(0, 1.0, 0)
	body.material_override = _mat(Color("#4f78d7"))
	visual_root.add_child(body)

	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.33
	head_mesh.height = 0.66
	head.mesh = head_mesh
	head.position = Vector3(0, 1.85, 0)
	head.material_override = _mat(Color("#f2c7aa"))
	visual_root.add_child(head)

	var hair := MeshInstance3D.new()
	var hair_mesh := SphereMesh.new()
	hair_mesh.radius = 0.35
	hair_mesh.height = 0.38
	hair.mesh = hair_mesh
	hair.position = Vector3(0, 2.04, -0.01)
	hair.material_override = _mat(Color("#4b2f23"))
	visual_root.add_child(hair)

	var badge := MeshInstance3D.new()
	var badge_mesh := CylinderMesh.new()
	badge_mesh.top_radius = 0.09
	badge_mesh.bottom_radius = 0.09
	badge_mesh.height = 0.03
	badge.mesh = badge_mesh
	badge.position = Vector3(0, 1.2, -0.34)
	badge.rotation_degrees = Vector3(90, 0, 0)
	badge.material_override = _mat(Color("#ffe59c"))
	visual_root.add_child(badge)

func _mat(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.8
	return m
