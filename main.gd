extends Node

@onready
var triangle_ray_select: TriangleRaySelect = TriangleRaySelect.new()

var selectable_meshes: Array[MeshInstance3D]

func _ready():
	self.selectable_meshes = [ $MeshInstance3D, $"chibi_cat/Chibi Cat/Skeleton3D/cat" ]

func _input(event):
	if event.is_pressed() and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var camera: Camera3D = get_viewport().get_camera_3d()
		var pixel: Vector2i  = event.position
		
		# Select the triangle that's closest to the camera's origin
		var mesh_triangle_point: MeshTrianglePoint = self.triangle_ray_select.select_triangle_from_meshes_cam(self.selectable_meshes, camera, pixel)
		print(mesh_triangle_point)
		print("Point on triangle:        ", mesh_triangle_point.point_on_triangle)
		print("Distance to origin:       ", mesh_triangle_point.ray_origin_dist)
		print("Triangle vertice indices: ", mesh_triangle_point.vertex_ids)
