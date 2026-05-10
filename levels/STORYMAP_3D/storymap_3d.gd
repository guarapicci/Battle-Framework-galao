extends Node3D

@onready var player1: BattleCharacter = $"Stage world/Sonic"
@onready var camera: Node3D = $"Stage world/CameraRoot"
@onready var dialogueScene = load("res://UI/Dialogue/dialogue.tscn")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	var camera_pivot = camera.get_node("Pivot")
	var inner_camera = camera.get_node("Pivot/Camera")
	
	player1.global_position = $"Stage world/Node3D2".position
	player1.camera = camera_pivot
	player1.scale = Vector3(4, 4, 4)
	player1.player_id = 1
	inner_camera.player_id_to_track = 1
	
	var dialogue = dialogueScene.instantiate()
	add_child(dialogue)
	dialogue.addSpeaker(["Sonic", "Standard", "Middle", "Fade", "Right"])
	dialogue.addDialogue("Hey!  I'm Sonic, Sonic the hedgehog!", "Sonic")
	dialogue.addSpeaker(["Tails", "Worried", "Right", "Right", "Left"])
	dialogue.addDialogue("Sonic, I think everyone knows\nwho you are already.", "Tails")
	dialogue.addSpeaker(["Knuckles", "Standard", "Right", "Right", "Left"])
	dialogue.addDialogue("Hey guys what I miss?", "Knuckles")
	dialogue.removeSpeaker(["Knuckles", "Fade"])
	dialogue.addSpeaker(["Amy", "Standard", "Middle", "Right", "Right"])
	dialogue.addDialogue("Not much Knuckles,\n Sonic showing off again.", "Amy")
	dialogue.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	await dialogue.dialogue_ended
	get_tree().paused = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
