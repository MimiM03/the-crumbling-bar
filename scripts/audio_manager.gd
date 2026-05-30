extends Node

@export var bg_music_player: AudioStreamPlayer
@onready var pouring_sfx: AudioStreamPlayer = $PouringSFX
@onready var arrival_sfx: AudioStreamPlayer = $ArrivalSFX

func start_pour():
	if not pouring_sfx.playing:
		pouring_sfx.play()

func stop_pour():
	pouring_sfx.stop()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
