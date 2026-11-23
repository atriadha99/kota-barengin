class_name GridDrawer
extends MeshInstance3D

## Menggambar garis grid 16x16 tipis dan tajam di atas tanah
func _ready() -> void:
	var imm := ImmediateMesh.new()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 1.0, 1.0, 0.35)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	imm.surface_begin(Mesh.PRIMITIVE_LINES, mat)
	var grid_size := CityData.GRID_SIZE
	var tile_size := CityData.TILE_SIZE
	var total_size := CityData.MAP_SIZE
	var y_elev := 0.02

	for i in range(grid_size + 1):
		var pos: float = i * tile_size
		# Garis sejajar sumbu Z (X konstan)
		imm.surface_add_vertex(Vector3(pos, y_elev, 0.0))
		imm.surface_add_vertex(Vector3(pos, y_elev, total_size))
		# Garis sejajar sumbu X (Z konstan)
		imm.surface_add_vertex(Vector3(0.0, y_elev, pos))
		imm.surface_add_vertex(Vector3(total_size, y_elev, pos))

	imm.surface_end()
	mesh = imm
