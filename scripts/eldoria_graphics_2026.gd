extends Node
class_name EldoriaGraphics2026

## Primer módulo gráfico de Fase 4.
## Se mantiene separado del script de lógica para que el proyecto pueda
## evolucionar hacia una arquitectura visual más profesional.

@export var enable_fog: bool = true
@export var enable_glow: bool = true
@export var shadow_distance: float = 140.0
@export var ambient_energy: float = 0.62
@export var sun_energy: float = 1.0

func apply_to_world(root: Node3D) -> void:
	if root == null:
		return

	var environment_node := root.get_node_or_null("Environment2026") as WorldEnvironment
	if environment_node == null:
		environment_node = WorldEnvironment.new()
		environment_node.name = "Environment2026"
		root.add_child(environment_node)

	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#d9e9f4")
	environment.ambient_light_energy = ambient_energy
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_BG
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 0.92
	environment.tonemap_white = 1.05

	if enable_glow:
		environment.glow_enabled = true
		environment.glow_intensity = 0.45
		environment.glow_strength = 0.7
		environment.glow_bloom = 0.08
		environment.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN

	if enable_fog:
		environment.fog_enabled = true
		environment.fog_light_color = Color("#9fc9df")
		environment.fog_light_energy = 0.10
		environment.fog_density = 0.0018
		environment.fog_height = 5.0
		environment.fog_height_density = 0.006

	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("#1d7dcc")
	sky_material.sky_horizon_color = Color("#78c8f0")
	sky_material.ground_horizon_color = Color("#7da66f")
	sky_material.ground_bottom_color = Color("#273126")
	sky_material.energy_multiplier = 0.90
	sky.sky_material = sky_material
	environment.sky = sky
	environment_node.environment = environment

	var sun := root.get_node_or_null("Sun2026") as DirectionalLight3D
	if sun == null:
		sun = DirectionalLight3D.new()
		sun.name = "Sun2026"
		root.add_child(sun)

	sun.light_energy = sun_energy
	sun.light_color = Color("#ffe7c9")
	sun.rotation_degrees = Vector3(-48.0, -32.0, 0.0)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = shadow_distance
	sun.directional_shadow_fade_start = shadow_distance * 0.46
	sun.shadow_bias = 0.03

func make_pbr_material(
	color: Color,
	roughness: float = 0.7,
	metallic: float = 0.0,
	specular: float = 0.5
) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = clamp(rourghness_safe(roughness), 0.0, 1.0)
	material.metallic = clamp(metallic, 0.0, 1.0)
	material.specular = clamp(specular, 0.0, 1.0)
	material.diffuse_mode = BaseMaterial3D.DIFFUSE_BURLEY
	material.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	return material

func rourghness_safe(value: float) -> float:
	# Mantener el módulo robusto aunque se pase un valor fuera de rango.
	return value

func make_water_material(color: Color = Color("#2f8fb0")) -> StandardMaterial3D:
	var material := make_pbr_material(color, 0.02, 0.0, 0.8)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color.a = 0.92
	material.metallic_specular = 0.0
	return material

func make_emissive_material(
	color: Color,
	energy: float = 2.0
) -> StandardMaterial3D:
	var material := make_pbr_material(color, 0.35, 0.0, 0.35)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	return material
