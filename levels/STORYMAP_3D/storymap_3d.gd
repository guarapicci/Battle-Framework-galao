extends Node3D

@onready var player1: BattleCharacter = $"Stage world/Sonic"
@onready var camera: Node3D = $"Stage world/CameraRoot"
@onready var dialogue_blueprint: PackedScene = preload("res://UI/Dialogue/dialogue.tscn")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var camera_pivot = camera.get_node("Pivot")
	var inner_camera = camera.get_node("Pivot/Camera")
	
	player1.global_position = $"Stage world/Node3D2".position
	player1.camera = camera_pivot
	player1.scale = Vector3(4, 4, 4)
	player1.player_id = 1
	inner_camera.player_id_to_track = 1
	
	#dialogue.addSpeaker(["Emerl", "Standard", "Left", "Left", "Left"])
	get_tree().create_timer(1.2).timeout.connect(func():
		_trigger_dialogue_stage1()
		print("added dialogue scene 1.")
		)
	pass # Replace with function body.


func _trigger_dialogue_stage1():
	var dialogue_scene_root: DialogueSequence = dialogue_blueprint.instantiate()
	dialogue_scene_root.addSpeaker(["Tails", "Standard", "Right", "Left", "Left"])
	dialogue_scene_root.addDialogue("As much as i advocate against violence...","Tails")
	dialogue_scene_root.addDialogue("my hands are itching for \n absolute destruction!", "Tails")
	dialogue_scene_root.addSpeaker(
		["Sonic", "Confused", "Left", "Left", "Right"],
		 ["Emerl", "Standard", "Left", "Left", "Right"])
	dialogue_scene_root.addDialogue("Whoa, buddy, slow down!\n we just got here.", "Sonic")
	dialogue_scene_root.changeSpeaker("Sonic", "Standard", "Left")
	dialogue_scene_root.addDialogue("(I gotta find something to keep \nhim busy fast -)", "Sonic")
	dialogue_scene_root.changeSpeaker("Sonic", "Determined", "Left")
	dialogue_scene_root.addDialogue("(- or else this ocean might not stay \nblue for long!)", "Sonic")
	add_child(dialogue_scene_root)
	dialogue_scene_root.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	await dialogue_scene_root.dialogue_ended
	print("dialogue is over. carrying on with hub world...")
	get_tree().paused = false
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
