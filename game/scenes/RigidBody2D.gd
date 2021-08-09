extends RigidBody2D

var incave = false

var can_click = true 

var anim_mode = "IDLE"
var animation

var OOBX = 75
var OOBY = 85

var PunchEnd
var dir = "left"
var AttAnim = false
func attack():
	if $Attack.is_stopped():
		$Attack.start()
		$PunchSFX.play()
		$Punch/PunchBox.set_deferred("disabled", false)
		AttAnim = true
		can_click = false
		if linear_velocity.x == 0:
			if dir == "left":
				$Punch/PunchBox.position.x -= 9.5
				PunchEnd = 9.5
			if dir == "right":
				$Punch/PunchBox.position.x += 9.5
				PunchEnd = -9.5
		if linear_velocity.x < 0:
			linear_velocity.x += -50
			$Punch/PunchBox.position.x -= 9.5
			PunchEnd = 9.5
		if linear_velocity.x > 0:
			linear_velocity.x += 50
			$Punch/PunchBox.position.x += 9.5
			PunchEnd = -9.5
	
func _on_Attack_timeout():
	can_click = true
	AttAnim = false
	$Punch/PunchBox.position.x += PunchEnd
	$Punch/PunchBox.set_deferred("disabled", true)

var hurt = false
export (float) var max_health = 3
onready var health = max_health setget _set_health

func _set_health(value):
	health = clamp(value, 0, max_health)
	if health == 0:
		death()

func _ready():
	get_node("AnimationPlayer").play("FULL")

func _on_Hitbox_area_entered(_area):
	damage()

func damage():
	if $Invuln.is_stopped():
		$Invuln.start()
		$Hurt.play()
		_set_health(health - 1)
		$Stomp/StompBox.scale.x = 0
		if(health == 2):
			if incave == true:
				$MixingDeskMusic.queue_bar_transition("2heartC")
			else:
				$MixingDeskMusic.queue_bar_transition("2heart")
			get_node("AnimationPlayer").play("2_HEART")
		if(health == 1):
			if incave == true:
				$MixingDeskMusic.queue_bar_transition("1heartC")
			else:
				$MixingDeskMusic.queue_bar_transition("1heart")
			get_node("AnimationPlayer").play("1_HEART")
		hurt = true
		can_click = false
		if health != 0:
			linear_velocity.y = -150
			linear_velocity.x = 0
			$KB.start()

func _on_Invuln_timeout():
	$Stomp/StompBox.scale.x = 1
		
func _on_KB_timeout():
	can_click = true
	hurt = false
	
func death():
	if $DeathTime.is_stopped():
		linear_velocity.x = 0
		can_click = false
		get_node("AnimationPlayer").play("DEAD")
		$MixingDeskMusic.stop("1heart")
		$MixingDeskMusic.stop("2heart")
		$MixingDeskMusic.stop("3heart")
		$MixingDeskMusic.stop("1heartC")
		$MixingDeskMusic.stop("2heartC")
		$MixingDeskMusic.stop("3heartC")
		$Death.play()
		$Smoke.play("smoke")
		incave = false
		$DeathTime.start()
	
func _on_DeathTime_timeout():
	can_click = true
	hurt = false
	linear_velocity.y = 0
	global_position.x = -62
	global_position.y = 50
	
	# manually set the frame for the hud sprite
	assert(get_node("HUD/Node/Health") != null)
	get_node("HUD/Node/Health").frame = 0
	
	$MixingDeskMusic.play("3heart")
	_set_health(3)
	
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
			elif is_on_ground and Input.is_action_just_pressed("jump") and health != 0:
				$Jump.play()
				apply_central_impulse(Vector2.UP * jump_force)
				change_state(AIR)
		
		RUN:
			anim_mode = "RUN"
			if not move_direction.x:
				change_state(IDLE)
			elif state.get_contact_count() == 0:
				change_state(AIR)
			elif is_on_ground and Input.is_action_just_pressed("jump") and health != 0:
				$Jump.play()
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
				OOBX = global_position.x
				OOBY = global_position.y
				
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
	if can_click:
		return Vector2(
			Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
			Input.get_action_strength("aim_down") - Input.get_action_strength("aim_up")
		)
	else:
		return Vector2(0, 0)

func _process(_delta):
	AnimationLoop()

func AnimationLoop():
	if health != 0:
		if can_click:
			AttAnim = false
		if linear_velocity.x < 0:
			if $RayCast2D2.is_colliding():
				get_node("Sprite").set_flip_h(false)
				dir = "right"
			else:
				get_node("Sprite").set_flip_h(true)
				dir = "left"
		if linear_velocity.x > 0:
			if $RayCast2D.is_colliding():
				get_node("Sprite").set_flip_h(true)
				dir = "left"
			else:
				get_node("Sprite").set_flip_h(false)
				dir = "right"
		if Input.is_action_just_pressed("punch"):
			attack()
		animation = anim_mode
		if hurt: 
			get_node("AnimationPlayer").play("DAMAGE")
		elif AttAnim:
			get_node("AnimationPlayer").play("PUNCH")
		else:
			get_node("AnimationPlayer").play(animation)
	else:
		get_node("AnimationPlayer").play("DEATH")

#CAMERA TRIGGERS
func _on_Area2D_area_entered(_area):
	$Camera2D.limit_bottom = -100
func _on_Area2D2_area_entered(_area):
	$Camera2D.limit_bottom = 220
func _on_Area2D3_area_entered(_area):
	$Camera2D.limit_bottom = 145
func _on_Area2D4_area_entered(_area):
	$Camera2D.limit_bottom = -100
func _on_Area2D5_area_entered(_area):
	$Camera2D.limit_bottom = 530
func _on_Area2D6_area_entered(_area):
	$Camera2D.limit_bottom = 145
func _on_Area2D7_area_entered(_area):
	$Camera2D.limit_bottom = 530
func _on_Area2D8_area_entered(_area):
	$Camera2D.limit_bottom = 430

func _on_Stomp_area_entered(_area):
	linear_velocity.y = -150

func _on_OOBTrig_area_entered(_area):
	_set_health(health - 1)
	if health != 0:
		global_position.x = OOBX
		global_position.y = OOBY - 10
		linear_velocity.y = 150
		linear_velocity.x = 0
		if(health == 2):
			get_node("AnimationPlayer").play("2_HEART")
			$MixingDeskMusic.queue_bar_transition("2heart")
		if(health == 1):
			get_node("AnimationPlayer").play("1_HEART")
			$MixingDeskMusic.queue_bar_transition("1heart")


func _on_CaveTrans_area_entered(area):
	if incave == false:
		if(health == 3):
			$MixingDeskMusic.queue_bar_transition("3heartC")
			incave = true
		if(health == 2):
			$MixingDeskMusic.queue_bar_transition("2heartC")
			incave = true
		if(health == 1):
			$MixingDeskMusic.queue_bar_transition("1heartC")
			incave = true


func _on_CaveTrans2_area_entered(area):
	if incave == false:
		if(health == 3):
			$MixingDeskMusic.queue_bar_transition("3heartC")
			incave = true
		if(health == 2):
			$MixingDeskMusic.queue_bar_transition("2heartC")
			incave = true
		if(health == 1):
			$MixingDeskMusic.queue_bar_transition("1heartC")
			incave = true


func _on_ForestTrans_area_entered(area):
	if incave == true:
		if(health == 3):
			$MixingDeskMusic.queue_bar_transition("3heart")
			incave = false
		if(health == 2):
			$MixingDeskMusic.queue_bar_transition("2heart")
			incave = false
		if(health == 1):
			$MixingDeskMusic.queue_bar_transition("1heart")
			incave = false


func _on_ForestTrans2_area_entered(area):
	if incave == true:
		if(health == 3):
			$MixingDeskMusic.queue_bar_transition("3heart")
			incave = false
		if(health == 2):
			$MixingDeskMusic.queue_bar_transition("2heart")
			incave = false
		if(health == 1):
			$MixingDeskMusic.queue_bar_transition("1heart")
			incave = false
