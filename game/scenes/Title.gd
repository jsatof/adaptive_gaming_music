extends Node

func _ready():
	$Control/Player/MixingDeskMusic.init_song("3heart")
	$Control/Player/MixingDeskMusic.play("3heart")
