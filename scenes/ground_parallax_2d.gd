extends Parallax2D

@export var textures_folder = "res://assets/environment/ground"
@export var terrain_area = Vector2(1000, 1000)
@export var ground0_weight: int = 10

var textures: Array[Texture2D]

func _ready() -> void:
	_load_textures()
	_spawn_terrain()

func _load_textures():
	for i in range(6):
		var path = textures_folder.path_join("ground%d.png" % i)
		var texture = load(path)
		if texture is Texture2D:
			textures.append(texture)

func _pick_weighted() -> Texture2D:
	var total := ground0_weight + textures.size() - 1
	var r = randi() % total
	if r < ground0_weight:
		return textures[0]
	var idx = 1 + (r - ground0_weight)
	return textures[idx]

func _spawn_terrain():
	if textures.is_empty():
		return
	var cell_size = textures.front().get_height()
	var image = Image.create(int(terrain_area.x), int(terrain_area.y), false, Image.FORMAT_RGBA8)

	for x in range(0, int(terrain_area.x), cell_size):
		for y in range(0, int(terrain_area.y), cell_size):
			var texture = _pick_weighted()
			var texture_image = texture.get_image()
			texture_image.convert(Image.FORMAT_RGBA8)
			image.blit_rect(texture_image, Rect2i(0, 0, cell_size, cell_size), Vector2i(x, y))

	var final_texture = ImageTexture.create_from_image(image) as Texture2D
	$Sprite2D.texture = final_texture
