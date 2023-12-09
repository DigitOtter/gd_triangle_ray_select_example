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
