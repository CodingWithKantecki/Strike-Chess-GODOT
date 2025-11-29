extends Control

# Fire Effect for Burn Card Panel
# Uses extracted fire.gif frames for animation

var fire_textures: Array[ImageTexture] = []
var current_frame: int = 0
var frame_timer: float = 0.0
var frame_delay: float = 0.09  # 90ms between frames (matching pygame)
var loaded: bool = false

func _ready():
	# Clip fire to stay inside the box
	clip_contents = true
	# Try loading on next frame to ensure node is ready
	call_deferred("load_fire_frames")

func load_fire_frames():
	"""Load fire animation frames from extracted PNGs"""
	fire_textures.clear()

	# Get the project path
	var base_path = "res://assets/fire_frames/"

	for i in range(8):  # 8 frames
		var frame_path = base_path + "fire_%02d.png" % i

		# Try resource loader first
		if ResourceLoader.exists(frame_path):
			var tex = load(frame_path)
			if tex:
				fire_textures.append(tex)
				continue

		# Fallback: Load from file system directly
		var global_path = ProjectSettings.globalize_path(frame_path)
		var image = Image.new()
		var err = image.load(global_path)
		if err == OK:
			var texture = ImageTexture.create_from_image(image)
			fire_textures.append(texture)

	loaded = fire_textures.size() > 0

	if loaded:
		print("Fire effect: Loaded %d frames" % fire_textures.size())
		queue_redraw()
	else:
		print("Fire effect: No frames loaded, using fallback particle effect")

func _process(delta: float):
	# Update animation timer
	frame_timer += delta
	if frame_timer >= frame_delay:
		frame_timer = 0.0
		if fire_textures.size() > 0:
			current_frame = (current_frame + 1) % fire_textures.size()
		queue_redraw()

func _draw():
	if loaded and fire_textures.size() > 0:
		_draw_gif_fire()

func _draw_gif_fire():
	"""Draw fire using loaded GIF frames - three fires across the bottom"""
	var frame = fire_textures[current_frame]
	if frame == null:
		return

	var frame_size = frame.get_size()

	# Scale fire bigger
	var scale = (size.x / frame_size.x) * 1.15
	var draw_size = Vector2(frame_size.x * scale, frame_size.y * scale)

	# Y position - inside the box at bottom
	var y_pos = size.y - draw_size.y + 56

	# Draw left fire
	var left_pos = Vector2(-draw_size.x * 0.36, y_pos)
	draw_texture_rect(frame, Rect2(left_pos, draw_size), false)

	# Draw center fire
	var center_pos = Vector2((size.x - draw_size.x) / 2, y_pos)
	draw_texture_rect(frame, Rect2(center_pos, draw_size), false)

	# Draw right fire
	var right_pos = Vector2(size.x - draw_size.x * 0.64, y_pos)
	draw_texture_rect(frame, Rect2(right_pos, draw_size), false)

func _draw_particle_fire():
	"""Fallback: Draw simple animated fire effect"""
	var time = Time.get_ticks_msec() * 0.001

	# Draw multiple layers of fire
	for layer in range(3):
		var layer_offset = layer * 0.3
		for i in range(12):
			var x_base = size.x * 0.5 + sin(time * 2 + i * 0.8 + layer_offset) * (size.x * 0.3)
			var y_base = size.y * 0.85 - (i * 8) - sin(time * 3 + i) * 5

			# Fire gets smaller as it rises
			var radius = (12 - i) * 1.5 + sin(time * 4 + i * 0.5) * 2

			# Color goes from yellow to orange to red
			var progress = i / 12.0
			var color: Color
			if progress < 0.3:
				color = Color(1.0, 0.9 - progress, 0.0, 0.9 - layer * 0.2)
			elif progress < 0.6:
				color = Color(1.0, 0.6 - progress * 0.5, 0.0, 0.8 - layer * 0.2)
			else:
				color = Color(0.9 - progress * 0.3, 0.2, 0.0, 0.6 - progress * 0.3 - layer * 0.15)

			draw_circle(Vector2(x_base, y_base), radius, color)

	# Base glow
	var glow_intensity = 0.4 + sin(time * 5) * 0.15
	draw_rect(Rect2(10, size.y * 0.7, size.x - 20, size.y * 0.3), Color(1.0, 0.5, 0.0, glow_intensity))
