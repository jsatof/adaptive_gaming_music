extends KinematicBody2D

const GRAVITY = 10
const SPEED = 45
const FLOOR = Vector2(0, -1)

var velocity = Vector2()

var direction = -1

func _on_Top_area_entered(_area):
	self.queue_free()

func _physics_process(_delta):
	velocity.x = SPEED * direction
	if direction == -1:
		get_node("AnimatedSprite").set_flip_h(false)
	else:
		get_node("AnimatedSprite").set_flip_h(true)
	$AnimatedSprite.play("walk")
	velocity.y += GRAVITY
	velocity = move_and_slide(velocity, FLOOR)
	if is_on_wall():
		direction = direction * -1
		$RayCast2D.position.x *= -1
	if $RayCast2D.is_colliding() == false:
		direction = direction * -1
		$RayCast2D.position.x *= -1
