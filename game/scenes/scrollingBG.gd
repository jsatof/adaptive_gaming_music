extends Node

export(float) var speed = .4

func _ready():
	self.material.set_shader_param("speed", speed)
