extends Node3D

var ballNode = null#$Ball
# Called when the node enters the scene tree for the first time.
func _ready():
	ballNode = $Ball
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("ui_accept"):
		spawn_ball()
	pass
	

func spawn_ball():
	print("trying to spawn ball")
	var ball = ballNode.duplicate()
	add_child(ball)
	ball.global_transform = Transform3D.IDENTITY
	ball.global_transform.origin = Vector3(0,1,3)
	var strength = 20*ball.mass
	ball.add_constant_central_force(Vector3(0,0,-strength))
	
