extends CollisionShape3D

@export var heightmap: Image

func _ready() -> void:
    var heightmap_shape: HeightMapShape3D = shape
    heightmap.convert(Image.FORMAT_RF)
    heightmap_shape.update_map_data_from_image(heightmap, -INF, 0)
