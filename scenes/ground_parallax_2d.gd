extends Parallax2D

@export var textures_folder = "res://assets/environment/ground"
@export var terrain_area = Vector2(1000, 1000)

var textures: Array[Texture2D]

func _ready() -> void:
	# _load_textures()
	# _spawn_terrain()
	pass

func _load_textures():
	var dir = DirAccess.open(textures_folder)
	if not dir:
		return

	dir.list_dir_begin()
	var file = dir.get_next()
	while file != "":
		if file.ends_with(".png"):
			var path = textures_folder.path_join(file)
			var texture = load(path)
			if texture is Texture2D:
				textures.append(texture)
		file = dir.get_next()
	dir.list_dir_end()

func _spawn_terrain():
	var cell_size = textures.front().get_height()
	var image = Image.create(terrain_area.x, terrain_area.y, false, Image.FORMAT_RGBA8)

	for x in range(0, terrain_area.x, cell_size):
		for y in range(0, terrain_area.y, cell_size):
			var texture = textures.pick_random()
			var texture_image = texture.get_image()
			texture_image.convert(Image.FORMAT_RGBA8)
			image.blit_rect(texture_image, Rect2i(0, 0, cell_size, cell_size), Vector2i(x, y))

	var final_texture = ImageTexture.create_from_image(image) as Texture2D
	$Sprite2D.texture = final_texture
