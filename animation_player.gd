extends AnimationPlayer

@onready
var play_forward: bool = false

func _ready():
	self.play("sit")

func _process(_delta):
	pass

func _on_animation_finished(anim_name):
	if self.play_forward:
		self.play("sit")
	else:
		self.play_backwards("sit")
	
	self.play_forward = not self.play_forward
