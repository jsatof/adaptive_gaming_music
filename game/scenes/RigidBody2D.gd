extends RigidBody2D

var anim_mode = "IDLE"
var animation

#DYNAMICALLY CHANGING CAMERA
#func _ready():
	#var tilemap_rect = get_parent().get_node("ForegroundOut").get_used_rect()
	#var tilemap_cell_size = get_parent().get_node("ForegroundOut").cell_size
	#$Camera2D.limit_left = tilemap_rect.position.x * tilemap_cell_size.x
	#$Camera2D.limit_right = tilemap_rect.end.x * tilemap_cell_size.x
	#$Camera2D.limit_top = tilemap_rect.position.y * tilemap_cell_size.y
	#$Camera2D.limit_bottom = tilemap_rect.end.y * tilemap_cell_size.y
	#pass

signal new_health(health)
signal death()
export (float) var max_health = 3
onready var health = max_health setget _set_health

func _set_health(value):
	var prev_health = health
	health = clamp(value, 0, max_health)
	if health != prev_health:
		emit_signal("new_health", health)
		if health == 0:
			death()

func _on_Hitbox_area_entered(area):
	damage()

func damage():
	if $Invuln.is_stopped():
		$Invuln.start()
		_set_health(health - 1)
		$Damage.play("damage")
		
func _on_invulnTimer_timeout():
	$Damage.play("rest")
	
func death():
	pass

onready var just_aired_timer : Timer = $JustAiredTimer
onready var _transitions: = {
		IDLE: [RUN, AIR],
		RUN: [IDLE, AIR],
		AIR: [IDLE],
	}
	
const FLOOR_NORMAL := Vector2.UP

enum {
	IDLE,
	RUN,
	AIR,
}

export var move_speed := 80.0
export var air_speed := 8
export var jump_force := 200.0

var _state: int = IDLE

var states_strings := {
	IDLE: "idle",
	RUN: "run",
	AIR: "air",
}


func _integrate_forces(state: Physics2DDirectBodyState) -> void:
	var is_on_ground := state.get_contact_count() > 0 and int(state.get_contact_collider_position(0).y) >= int(global_position.y)
	
	var move_direction := get_move_direction()
	
	match _state:
		IDLE:
			anim_mode = "IDLE"
			linear_velocity.x = 0
			if move_direction.x:
				change_state(RUN)
			elif is_on_ground and Input.is_action_just_pressed("jump"):
				apply_central_impulse(Vector2.UP * jump_force)
				change_state(AIR)
		
		RUN:
			anim_mode = "RUN"
			if not move_direction.x:
				change_state(IDLE)
			elif state.get_contact_count() == 0:
				change_state(AIR)
			elif is_on_ground and Input.is_action_just_pressed("jump"):
				apply_central_impulse(Vector2.UP * jump_force)
				change_state(AIR)
			else:
				state.linear_velocity.x = move_direction.x * move_speed
				
		AIR:
			if linear_velocity.y <= 0:
				anim_mode = "UAIR"
			if linear_velocity.y > 0:
				anim_mode = "DAIR"
			if move_direction.x and linear_velocity.x < 100 and linear_velocity.x > -100 :
				state.linear_velocity.x += move_direction.x * air_speed
			if is_on_ground and just_aired_timer.is_stopped():
				change_state(IDLE)
				
func change_state(target_state: int) -> void:
	if not target_state in _transitions[_state]:
		return
	_state = target_state
	enter_state()
	
func enter_state() -> void:
	match _state:
		IDLE:
			linear_velocity.x = 0
		AIR:
			just_aired_timer.start()
		_:
			return
func get_move_direction() -> Vector2:
	return Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("aim_down") - Input.get_action_strength("aim_up")
	)

func _process(delta):
	
	AnimationLoop()

func AnimationLoop():
	if linear_velocity.x < 0:
		if $RayCast2D2.is_colliding():
			get_node("Sprite").set_flip_h(false)
		else:
			get_node("Sprite").set_flip_h(true)
	if linear_velocity.x > 0:
		if $RayCast2D.is_colliding():
			get_node("Sprite").set_flip_h(true)
		else:
			get_node("Sprite").set_flip_h(false)
	
	animation = anim_mode
	get_node("AnimationPlayer").play(animation)

#CAMERA TRIGGERS
func _on_Area2D_area_entered(area):
	$Camera2D.limit_bottom = -100
func _on_Area2D2_area_entered(area):
	$Camera2D.limit_bottom = 220
func _on_Area2D3_area_entered(area):
	$Camera2D.limit_bottom = 145
func _on_Area2D4_area_entered(area):
	$Camera2D.limit_bottom = -100
func _on_Area2D5_area_entered(area):
	$Camera2D.limit_bottom = 530
func _on_Area2D6_area_entered(area):
	$Camera2D.limit_bottom = 145
func _on_Area2D7_area_entered(area):
	$Camera2D.limit_bottom = 530
func _on_Area2D8_area_entered(area):
	$Camera2D.limit_bottom = 430
