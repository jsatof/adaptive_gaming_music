extends KinematicBody2D

const GRAVITY = 10
const SPEED = 45
const FLOOR = Vector2(0, -1)

var velocity = Vector2()

var direction = -1
var stop = 0

func _on_Side_area_entered(_area):
	$Squish.start()
	$Smoke.start()
	$Hitbox/CollisionShape2D.set_deferred("disabled", true)
	$Side/CollisionShape2D.set_deferred("disabled", true)
	$CollisionShape2D.set_deferred("disabled", true)
	stop = 1
	velocity.x = 0
	$AnimatedSprite.play("dead")
	
func _on_Squish_timeout():
	$AnimatedSprite.play("smoke")

func _on_Smoke_timeout():
	self.queue_free()

func _physics_process(_delta):
	if stop == 0:
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
