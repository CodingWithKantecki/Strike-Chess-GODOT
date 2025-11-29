extends Node2D
class_name WeatherSystem

# Weather System - matching pygame weather/particle effects
# Supports rain, snow, fog, smoke, fire, and sparks

enum WeatherType { NONE, RAIN, SNOW, FOG, SMOKE, FIRE, SPARKS }

signal weather_changed(weather_type: WeatherType)

var current_weather: WeatherType = WeatherType.NONE
var intensity: float = 1.0
var wind_strength: float = 0.0
var wind_direction: Vector2 = Vector2(1, 0)

# Particle emitters
var rain_particles: GPUParticles2D
var snow_particles: GPUParticles2D
var fog_overlay: ColorRect
var smoke_emitters: Array = []
var fire_emitters: Array = []
var spark_emitters: Array = []

# Preloaded materials
var rain_material: ParticleProcessMaterial
var snow_material: ParticleProcessMaterial

func _ready():
	_setup_rain_particles()
	_setup_snow_particles()
	_setup_fog_overlay()

func _setup_rain_particles():
	"""Create rain particle system."""
	rain_particles = GPUParticles2D.new()
	rain_particles.amount = 500
	rain_particles.lifetime = 1.0
	rain_particles.visibility_rect = Rect2(-1000, -100, 2000, 1200)

	rain_material = ParticleProcessMaterial.new()
	rain_material.direction = Vector3(0, 1, 0)
	rain_material.spread = 5.0
	rain_material.initial_velocity_min = 400.0
	rain_material.initial_velocity_max = 500.0
	rain_material.gravity = Vector3(0, 500, 0)
	rain_material.scale_min = 0.5
	rain_material.scale_max = 1.0
	rain_material.color = Color(0.6, 0.7, 0.9, 0.5)

	# Create elongated rain texture
	var img = Image.create(2, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.7, 0.8, 1.0, 0.6))
	var tex = ImageTexture.create_from_image(img)

	rain_particles.process_material = rain_material
	rain_particles.texture = tex
	rain_particles.emitting = false
	add_child(rain_particles)

func _setup_snow_particles():
	"""Create snow particle system."""
	snow_particles = GPUParticles2D.new()
	snow_particles.amount = 200
	snow_particles.lifetime = 4.0
	snow_particles.visibility_rect = Rect2(-1000, -100, 2000, 1200)

	snow_material = ParticleProcessMaterial.new()
	snow_material.direction = Vector3(0, 1, 0)
	snow_material.spread = 30.0
	snow_material.initial_velocity_min = 30.0
	snow_material.initial_velocity_max = 60.0
	snow_material.gravity = Vector3(0, 20, 0)
	snow_material.scale_min = 2.0
	snow_material.scale_max = 5.0
	snow_material.color = Color(1, 1, 1, 0.8)

	# Turbulence for floating effect
	snow_material.turbulence_enabled = true
	snow_material.turbulence_noise_strength = 2.0
	snow_material.turbulence_noise_speed = Vector3(0.5, 0.5, 0)

	# Create circular snow texture
	var img = Image.create(8, 8, false, Image.FORMAT_RGBA8)
	for x in range(8):
		for y in range(8):
			var dist = Vector2(x - 3.5, y - 3.5).length()
			if dist < 3.5:
				img.set_pixel(x, y, Color(1, 1, 1, 1.0 - dist / 3.5))
			else:
				img.set_pixel(x, y, Color(1, 1, 1, 0))
	var tex = ImageTexture.create_from_image(img)

	snow_particles.process_material = snow_material
	snow_particles.texture = tex
	snow_particles.emitting = false
	add_child(snow_particles)

func _setup_fog_overlay():
	"""Create fog effect overlay."""
	fog_overlay = ColorRect.new()
	fog_overlay.color = Color(0.5, 0.5, 0.6, 0.0)
	fog_overlay.size = Vector2(2000, 1200)
	fog_overlay.position = Vector2(-500, -100)
	fog_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fog_overlay)

func set_weather(weather: WeatherType, new_intensity: float = 1.0):
	"""Set the current weather type."""
	current_weather = weather
	intensity = clamp(new_intensity, 0.0, 2.0)
	_apply_weather()
	emit_signal("weather_changed", weather)

func _apply_weather():
	"""Apply current weather settings."""
	# Stop all weather first
	rain_particles.emitting = false
	snow_particles.emitting = false
	fog_overlay.color.a = 0.0

	match current_weather:
		WeatherType.RAIN:
			rain_particles.emitting = true
			rain_particles.amount = int(500 * intensity)
			rain_material.initial_velocity_min = 400.0 + wind_strength * 50
			rain_material.initial_velocity_max = 500.0 + wind_strength * 50
			# Add wind effect
			if wind_strength > 0:
				rain_material.direction = Vector3(wind_direction.x * wind_strength * 0.5, 1, 0)

		WeatherType.SNOW:
			snow_particles.emitting = true
			snow_particles.amount = int(200 * intensity)
			# Add wind effect
			if wind_strength > 0:
				snow_material.gravity = Vector3(wind_direction.x * wind_strength * 30, 20, 0)

		WeatherType.FOG:
			fog_overlay.color.a = 0.3 * intensity

func set_wind(strength: float, direction: Vector2 = Vector2(1, 0)):
	"""Set wind parameters."""
	wind_strength = clamp(strength, 0.0, 5.0)
	wind_direction = direction.normalized()
	_apply_weather()

func create_smoke_at(pos: Vector2, duration: float = 3.0):
	"""Create smoke effect at position."""
	var smoke = GPUParticles2D.new()
	smoke.position = pos
	smoke.amount = 50
	smoke.lifetime = 2.0
	smoke.one_shot = true
	smoke.explosiveness = 0.0

	var mat = ParticleProcessMaterial.new()
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 45.0
	mat.initial_velocity_min = 20.0
	mat.initial_velocity_max = 40.0
	mat.gravity = Vector3(0, -30, 0)
	mat.scale_min = 10.0
	mat.scale_max = 30.0
	mat.color = Color(0.3, 0.3, 0.3, 0.6)

	# Fade out
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(0.4, 0.4, 0.4, 0.6))
	gradient.add_point(1.0, Color(0.2, 0.2, 0.2, 0.0))
	var grad_tex = GradientTexture1D.new()
	grad_tex.gradient = gradient
	mat.color_ramp = grad_tex

	smoke.process_material = mat
	smoke.emitting = true
	add_child(smoke)
	smoke_emitters.append(smoke)

	# Auto cleanup
	get_tree().create_timer(duration).timeout.connect(func():
		smoke.queue_free()
		smoke_emitters.erase(smoke)
	)

func create_fire_at(pos: Vector2, duration: float = 5.0, size: float = 1.0):
	"""Create fire effect at position."""
	var fire = GPUParticles2D.new()
	fire.position = pos
	fire.amount = int(100 * size)
	fire.lifetime = 0.8
	fire.one_shot = false

	var mat = ParticleProcessMaterial.new()
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 30.0
	mat.initial_velocity_min = 30.0 * size
	mat.initial_velocity_max = 60.0 * size
	mat.gravity = Vector3(0, -100, 0)
	mat.scale_min = 5.0 * size
	mat.scale_max = 15.0 * size

	# Fire colors
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(1.0, 0.9, 0.2, 1.0))  # Yellow core
	gradient.add_point(0.3, Color(1.0, 0.5, 0.0, 0.9))  # Orange
	gradient.add_point(0.7, Color(0.8, 0.2, 0.0, 0.6))  # Red
	gradient.add_point(1.0, Color(0.2, 0.1, 0.1, 0.0))  # Fade to smoke
	var grad_tex = GradientTexture1D.new()
	grad_tex.gradient = gradient
	mat.color_ramp = grad_tex

	fire.process_material = mat
	fire.emitting = true
	add_child(fire)
	fire_emitters.append(fire)

	# Auto cleanup
	get_tree().create_timer(duration).timeout.connect(func():
		fire.emitting = false
		get_tree().create_timer(1.0).timeout.connect(func():
			fire.queue_free()
			fire_emitters.erase(fire)
		)
	)

func create_sparks_at(pos: Vector2, count: int = 20):
	"""Create spark burst at position."""
	var sparks = GPUParticles2D.new()
	sparks.position = pos
	sparks.amount = count
	sparks.lifetime = 0.5
	sparks.one_shot = true
	sparks.explosiveness = 1.0

	var mat = ParticleProcessMaterial.new()
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 100.0
	mat.initial_velocity_max = 200.0
	mat.gravity = Vector3(0, 400, 0)
	mat.scale_min = 1.0
	mat.scale_max = 3.0
	mat.color = Color(1.0, 0.8, 0.2, 1.0)

	sparks.process_material = mat
	sparks.emitting = true
	add_child(sparks)
	spark_emitters.append(sparks)

	# Auto cleanup
	get_tree().create_timer(1.0).timeout.connect(func():
		sparks.queue_free()
		spark_emitters.erase(sparks)
	)

func create_explosion_at(pos: Vector2, size: float = 1.0):
	"""Create explosion effect (fire + sparks + smoke)."""
	create_sparks_at(pos, int(40 * size))
	create_fire_at(pos, 0.5, size)

	# Delayed smoke
	get_tree().create_timer(0.3).timeout.connect(func():
		create_smoke_at(pos, 2.0)
	)

func clear_all_effects():
	"""Remove all weather and particle effects."""
	current_weather = WeatherType.NONE
	rain_particles.emitting = false
	snow_particles.emitting = false
	fog_overlay.color.a = 0.0

	for smoke in smoke_emitters:
		smoke.queue_free()
	smoke_emitters.clear()

	for fire in fire_emitters:
		fire.queue_free()
	fire_emitters.clear()

	for spark in spark_emitters:
		spark.queue_free()
	spark_emitters.clear()

func get_weather_for_chapter(chapter_index: int) -> WeatherType:
	"""Get weather type for story chapter."""
	# Different weather for different chapters
	match chapter_index:
		0: return WeatherType.NONE      # Tutorial
		1: return WeatherType.NONE      # Clear day
		2: return WeatherType.FOG       # Fog of war
		3: return WeatherType.RAIN      # Storm
		4: return WeatherType.NONE      # Clear
		5: return WeatherType.SNOW      # Winter
		6: return WeatherType.FOG       # Dense fog
		7: return WeatherType.RAIN      # Heavy rain
		8: return WeatherType.NONE      # Final battle
		_: return WeatherType.NONE
