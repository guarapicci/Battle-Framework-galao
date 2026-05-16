extends Node3D

@onready var global_counter = 0.0

@onready var player1: BattleCharacter = %"main player"
@onready var camera: Node3D = $"Stage world/CameraRoot"
@onready var link_stage1: Node3D = $platform_stage1
@onready var trigger_stage1: Area3D = %"Stage1 trigger"

@onready var dialogue_blueprint: PackedScene = preload("res://UI/Dialogue/dialogue.tscn")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var camera_pivot = camera.get_node("Pivot")
	var inner_camera = camera.get_node("Pivot/Camera")
	
	player1.global_position = $"Stage world/Node3D2".position
	player1.camera = camera_pivot
	player1.scale = Vector3(4, 4, 4)
	
	# set player ID to bind it to controller 1
	player1.player_id = 1
	inner_camera.player_id_to_track = 1
	
	MusicPlayer.play_track(null)
	
	#dialogue.addSpeaker(["Emerl", "Standard", "Left", "Left", "Left"])
	get_tree().create_timer(0.6).timeout.connect(func():
		_lock_all_interactive()
		await _trigger_dialogue_intro()
		_unlock_all_interactive()
		pass
		)
	pass # Replace with function body.


func _trigger_dialogue_intro():
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
	await dialogue_scene_root.dialogue_ended
	print("dialogue is over. carrying on with hub world...")
	pass

func _trigger_dialogue_stage_1():
	var dialogue_scene_root: DialogueSequence = dialogue_blueprint.instantiate()
	dialogue_scene_root.addSpeaker(["Sonic", "Standard", "Left", "Right", "Left"],
	["Emerl", "Standard", "Middle", "Right", "Left"],
	["Tails", "Standard", "Right", "Right", "Left"]
	)
	dialogue_scene_root.addDialogue("(This place looks durable enough...)","Sonic")
	dialogue_scene_root.changeSpeaker("Sonic", "Confused", "Right")
	dialogue_scene_root.addDialogue("How about we spar a little?\n peaks your interest?", "Sonic")
	dialogue_scene_root.changeSpeaker("Tails", "Determined", "Left")
	dialogue_scene_root.addDialogue("Where? When?", "Tails")
	dialogue_scene_root.changeSpeaker("Sonic", "Standard", "Left")
	dialogue_scene_root.addDialogue("Right here.", "Sonic")
	dialogue_scene_root.changeSpeaker("Sonic", "Determined", "Right")
	dialogue_scene_root.addDialogue("Right now.", "Sonic")
	add_child(dialogue_scene_root)
	dialogue_scene_root.process_mode = Node.PROCESS_MODE_ALWAYS
	_lock_all_interactive()
	await dialogue_scene_root.dialogue_ended
	print("dialogue is over. triggering match with stage 1 presets...")
	print("added dialogue scene 1.")
	MatchSetup.cpu_players = 2
	MatchSetup.human_players = 1
	MatchSetup.stage_list = ["emeraldbeach"]
	MatchSetup.current_stage_index = 0
	MatchSetup.character_choices = {1: "sonic", 2:"tails", 3:"knuckles"}
	SceneChanger.change_scene_to_file("res://match_scene/match_scene.tscn")
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#global_counter += delta
	#print("frame_time_total ", global_counter)
	pass

func _lock_all_interactive() -> void:
	player1.input_enabled = false
	pass
func _unlock_all_interactive() -> void:
	player1.input_enabled = true
	pass

func _trigger_callback_stage1(body: Node3D) -> void:
	print("detected collision on stage 1 stand")
	if(body == %"main player"):
		trigger_stage1.monitoring = false
		_trigger_dialogue_stage_1()
		pass
	pass # Replace with function body.
