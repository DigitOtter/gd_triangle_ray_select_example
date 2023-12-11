extends Node

@onready
var triangle_ray_select: TriangleRaySelect = TriangleRaySelect.new()

var mesh_triangle_point: MeshTrianglePoint = null
var triangle_transform: TriangleTransform = null

var selectable_meshes: Array[MeshInstance3D]

@onready
var time: float = 0.0

@onready
var print_time: float = 0.0

@onready
var indicator: MeshInstance3D = load("res://dot.tscn").instantiate()

func _get_uv_coordinates(mesh_triangle_point: MeshTrianglePoint) -> Vector2:
	# Gets uv coordinates of a mesh_triangle_point
	# Note: Does not follow skeleton/blendshape transforms! The function should only be used with an up-to-date mesh_triangle_point
	if not mesh_triangle_point.mesh_instance:
		return Vector2.INF
	
	var triangle_vertices: PackedVector3Array = self.triangle_ray_select.get_triangle_vertices(mesh_triangle_point)
	if triangle_vertices.size() != 3:
		return Vector2.INF
	
	var barycentric_point: Vector3 = \
		Geometry3D.get_triangle_barycentric_coords(mesh_triangle_point.point_on_triangle, triangle_vertices[0], triangle_vertices[1], triangle_vertices[2])
	
	# Get mesh data. If this function is called often, consider only calling surface_get_arrays() once and storing the data somewhere
	var mesh_arrays: Array = mesh_triangle_point.mesh_instance.mesh.surface_get_arrays(mesh_triangle_point.surface_id)
	var uv_data: PackedVector2Array =  mesh_arrays[Mesh.ARRAY_TEX_UV]
	
	# Get UV position using barycentric coordinates
	var uv_pos: Vector2 = \
	uv_data[mesh_triangle_point.vertex_ids[0]] * barycentric_point[0] + \
	uv_data[mesh_triangle_point.vertex_ids[1]] * barycentric_point[1] + \
	uv_data[mesh_triangle_point.vertex_ids[2]] * barycentric_point[2]
	
	return uv_pos

func _move_cat_root_skeleton(time):
	var skeleton: Skeleton3D = $"chibi_cat/Chibi Cat/Skeleton3D"
	var bone_id: int = skeleton.find_bone("root")
	var skel_pos: Vector3 = skeleton.get_bone_pose_position(bone_id)
	skel_pos.x = 0.10 * cos(2*PI/3.33 * time)
	skel_pos.y = 0.15 * sin(2*PI/3.33 * time)
	skeleton.set_bone_pose_position(bone_id, skel_pos)

func _ready():
	self.selectable_meshes = [ $MeshInstance3D, $"chibi_cat/Chibi Cat/Skeleton3D/cat" ]

func _input(event):
	if event.is_pressed() and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var camera: Camera3D = get_viewport().get_camera_3d()
		var pixel: Vector2i  = event.position
		
		# Select the triangle that's closest to the camera's origin
		self.mesh_triangle_point = self.triangle_ray_select.select_triangle_from_meshes_cam(self.selectable_meshes, camera, pixel)
		print(mesh_triangle_point)
		print("Point on triangle:        ", self.mesh_triangle_point.point_on_triangle)
		print("Distance to origin:       ", self.mesh_triangle_point.ray_origin_dist)
		print("Triangle vertice indices: ", self.mesh_triangle_point.vertex_ids)
		
		if self.mesh_triangle_point.mesh_instance:
			# Create transform for point_on_triangle from triangle vertices
			self.triangle_transform  = self.triangle_ray_select.get_triangle_transform_msi(self.mesh_triangle_point, Transform3D(Basis(), self.mesh_triangle_point.point_on_triangle))
			
			var uv_coords: Vector2 = self._get_uv_coordinates(self.mesh_triangle_point)
			print("UV Coordinate: ", uv_coords)

func _process(delta):
	# Every second, print the position of last point_on_triangle
	self.time += delta
	#self._move_cat_root_skeleton(self.time)
	
	self.print_time += delta
	if self.mesh_triangle_point and self.mesh_triangle_point.mesh_instance:
		# Get current triangle vertice positions
		var updated_vertice_positions: PackedVector3Array = self.triangle_ray_select.get_triangle_vertices(self.mesh_triangle_point)
		
		# Get point pose on triangle
		var updated_point_pose: Transform3D = self.triangle_transform.adjust_transform(updated_vertice_positions, 0.0)
		
		if self.indicator.get_parent() != self.mesh_triangle_point.mesh_instance:
			if self.indicator.get_parent():
				self.indicator.get_parent().remove_child(self.indicator)
			self.mesh_triangle_point.mesh_instance.add_child(self.indicator)
			self.indicator.owner = self.mesh_triangle_point.mesh_instance
		
		self.indicator.visible = true
		self.indicator.transform = updated_point_pose
		
		if self.print_time >= 1.0:
			self.print_time = 0.0
			print("Current point position: ", updated_point_pose.origin)
	else:
		self.indicator.visible = false
