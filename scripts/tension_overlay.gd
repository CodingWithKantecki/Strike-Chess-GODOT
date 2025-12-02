extends Control

# Tension overlay for countdown effects
# Draws vignette and warning stripes during countdown

var countdown_active: bool = false
var tension_time: float = 0.0
var fade_progress: float = 0.0  # 0 = invisible, 1 = fully visible
var fade_duration: float = 0.4  # Time to fade in/out
var is_fading_in: bool = false
var is_fading_out: bool = false

func _process(delta):
	# Handle fade in
	if is_fading_in:
		fade_progress = min(1.0, fade_progress + delta / fade_duration)
		if fade_progress >= 1.0:
			is_fading_in = false
		queue_redraw()

	# Handle fade out
	if is_fading_out:
		fade_progress = max(0.0, fade_progress - delta / fade_duration)
		if fade_progress <= 0.0:
			is_fading_out = false
			countdown_active = false
		queue_redraw()

	# Update animation while active
	if countdown_active and fade_progress > 0:
		tension_time += delta
		queue_redraw()

func set_countdown_active(active: bool):
	if active and not countdown_active:
		# Starting countdown - fade in
		countdown_active = true
		tension_time = 0.0
		is_fading_in = true
		is_fading_out = false
	elif not active and countdown_active:
		# Ending countdown - fade out
		is_fading_out = true
		is_fading_in = false

func _draw():
	if not countdown_active and fade_progress <= 0:
		return

	var viewport_size = get_viewport_rect().size
	var pulse = (sin(tension_time * 4.0) + 1.0) / 2.0  # Slower pulsing

	# === VIGNETTE ===
	# Darken edges of screen - draw in bands for efficiency
	var vignette_alpha = 0.4 * fade_progress  # Steady, no pulse
	var vignette_size = 150.0
	var band_size = 10  # Draw in 10px bands instead of 1px lines

	for i in range(0, int(vignette_size), band_size):
		var alpha = vignette_alpha * (1.0 - float(i) / vignette_size)
		var band_color = Color(0, 0, 0, alpha)
		# Top
		draw_rect(Rect2(0, i, viewport_size.x, band_size), band_color)
		# Bottom
		draw_rect(Rect2(0, viewport_size.y - i - band_size, viewport_size.x, band_size), band_color)
		# Left
		draw_rect(Rect2(i, 0, band_size, viewport_size.y), band_color)
		# Right
		draw_rect(Rect2(viewport_size.x - i - band_size, 0, band_size, viewport_size.y), band_color)

	# === RED WARNING STRIPES ===
	var stripe_width = 20.0  # Thicker stripes
	var stripe_spacing = 40.0  # More spacing for thicker stripes
	var stripe_base_alpha = 0.4 + pulse * 0.3
	var stripe_alpha = stripe_base_alpha * fade_progress  # Smooth fade in/out
	var stripe_color = Color(0.9, 0.15, 0.1, stripe_alpha)
	var stripe_offset = fmod(tension_time * 60.0, stripe_spacing)  # Animate stripes

	# Top warning stripes
	var stripe_height = 14.0  # Thicker bars
	for x in range(-int(stripe_spacing * 2), int(viewport_size.x + stripe_spacing * 2), int(stripe_spacing)):
		var stripe_x = x + stripe_offset
		var points = PackedVector2Array([
			Vector2(stripe_x, 0),
			Vector2(stripe_x + stripe_width, 0),
			Vector2(stripe_x + stripe_width + stripe_height, stripe_height),
			Vector2(stripe_x + stripe_height, stripe_height)
		])
		draw_colored_polygon(points, stripe_color)

	# Bottom warning stripes
	for x in range(-int(stripe_spacing * 2), int(viewport_size.x + stripe_spacing * 2), int(stripe_spacing)):
		var stripe_x = x - stripe_offset  # Opposite direction
		var y = viewport_size.y - stripe_height
		var points = PackedVector2Array([
			Vector2(stripe_x, y),
			Vector2(stripe_x + stripe_width, y),
			Vector2(stripe_x + stripe_width - stripe_height, viewport_size.y),
			Vector2(stripe_x - stripe_height, viewport_size.y)
		])
		draw_colored_polygon(points, stripe_color)
