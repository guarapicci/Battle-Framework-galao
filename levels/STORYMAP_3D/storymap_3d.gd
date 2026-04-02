extends Node3D

@onready var player1: BattleCharacter = $"Stage world/Sonic"
@onready var camera: Node3D = $"Stage world/CameraRoot"
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var camera_pivot = camera.get_node("Pivot")
	var inner_camera = camera.get_node("Pivot/Camera")
	
	player1.global_position = $"Stage world/Node3D2".position
	player1.camera = camera_pivot
	player1.scale = Vector3(4, 4, 4)
	player1.player_id = 1
	inner_camera.player_id_to_track = 1
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
