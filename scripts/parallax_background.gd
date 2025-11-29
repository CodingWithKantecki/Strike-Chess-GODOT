extends ParallaxBackground
class_name GameParallaxBackground

# Parallax Background System - matching pygame graphics.py
# Supports multiple themes with different layers and scroll speeds

enum Theme { CITY, JUNGLE, WCP }

var current_theme: Theme = Theme.CITY
var scroll_speed: float = 50.0
var auto_scroll: bool = true

# Theme layer configurations (path, speed_multiplier)
var theme_layers: Dictionary = {
	Theme.CITY: [
		{"path": "res://assets/parallax/city/1_layer_Background.png", "speed": 0.02},
		{"path": "res://assets/parallax/city/2_layer_Water.png", "speed": 0.1, "alpha": 0.47},
		{"path": "res://assets/parallax/city/3_layer.png", "speed": 0.2},
		{"path": "res://assets/parallax/city/4_layer_Lights.png", "speed": 0.3},
		{"path": "res://assets/parallax/city/5_layer.png", "speed": 0.4},
		{"path": "res://assets/parallax/city/6_layer.png", "speed": 0.5},
		{"path": "res://assets/parallax/city/7_layer.png", "speed": 0.55},
		{"path": "res://assets/parallax/city/8_layer_shading.png", "speed": 0.6},
	],
	Theme.JUNGLE: [
		{"path": "res://assets/parallax/jungle/Layer_0011_0.png", "speed": 0.1},
		{"path": "res://assets/parallax/jungle/Layer_0010_1.png", "speed": 0.15},
		{"path": "res://assets/parallax/jungle/Layer_0009_2.png", "speed": 0.2},
		{"path": "res://assets/parallax/jungle/Layer_0008_3.png", "speed": 0.25},
		{"path": "res://assets/parallax/jungle/Layer_0007_4.png", "speed": 0.3},
		{"path": "res://assets/parallax/jungle/Layer_0006_5.png", "speed": 0.35},
		{"path": "res://assets/parallax/jungle/Layer_0005_6.png", "speed": 0.4},
		{"path": "res://assets/parallax/jungle/Layer_0004_7.png", "speed": 0.45},
		{"path": "res://assets/parallax/jungle/Layer_0003_8.png", "speed": 0.5},
		{"path": "res://assets/parallax/jungle/Layer_0002_9.png", "speed": 0.55},
		{"path": "res://assets/parallax/jungle/Layer_0001_10.png", "speed": 0.6},
		{"path": "res://assets/parallax/jungle/Layer_0000_11.png", "speed": 0.65},
	],
	Theme.WCP: [
		{"path": "res://assets/parallax/wcp/WCP_1.png", "speed": 0.1},
		{"path": "res://assets/parallax/wcp/WCP_2.png", "speed": 0.2},
		{"path": "res://assets/parallax/wcp/WCP_3.png", "speed": 0.35},
		{"path": "res://assets/parallax/wcp/WCP_4.png", "speed": 0.5},
		{"path": "res://assets/parallax/wcp/WCP_5.png", "speed": 0.65},
	]
}

var parallax_layers: Array = []

func _ready():
	# Try to load city theme by default, fall back to simple background
	set_theme(Theme.CITY)

func set_theme(theme: Theme):
	"""Change the parallax theme."""
	current_theme = theme
	_clear_layers()
	_load_theme_layers()

func _clear_layers():
	"""Remove all existing parallax layers."""
	for layer in parallax_layers:
		layer.queue_free()
	parallax_layers.clear()

func _load_theme_layers():
	"""Load layers for the current theme."""
	if not theme_layers.has(current_theme):
		return

	var layers_config = theme_layers[current_theme]

	for i in range(layers_config.size()):
		var config = layers_config[i]
		var texture = load(config["path"]) if ResourceLoader.exists(config["path"]) else null

		if texture == null:
			continue

		# Create ParallaxLayer
		var layer = ParallaxLayer.new()
		layer.motion_scale = Vector2(config["speed"], 0)
		layer.motion_mirroring = Vector2(texture.get_width(), 0)

		# Create Sprite2D for the texture
		var sprite = Sprite2D.new()
		sprite.texture = texture
		sprite.centered = false
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

		# Apply alpha if specified
		if config.has("alpha"):
			sprite.modulate.a = config["alpha"]

		layer.add_child(sprite)
		add_child(layer)
		parallax_layers.append(layer)

func _process(delta):
	if auto_scroll:
		scroll_offset.x -= scroll_speed * delta

func set_scroll_speed(speed: float):
	"""Set the horizontal scroll speed."""
	scroll_speed = speed

func set_auto_scroll(enabled: bool):
	"""Enable/disable automatic scrolling."""
	auto_scroll = enabled

func get_theme_for_chapter(chapter_index: int) -> Theme:
	"""Get the appropriate theme for a story chapter."""
	# Chapter 1: WCP theme (main menu style)
	# Chapters 2-8: Jungle theme
	# Chapter 9+: City theme
	if chapter_index == 0:
		return Theme.WCP
	elif chapter_index < 8:
		return Theme.JUNGLE
	else:
		return Theme.CITY
