extends Control
## A dialogue system set up like that of Sonic Battle (GBA).
## When instantiating this node, there are certain variables you can set before
## you make the dialogue appear as a child.
##
## To use this, simply drag and drop this Scene from the file system
## into the map you want to use the dialogue in.
##
## Created by ShinySkink9185, being borrowed from Klonoa Project Test.
## I hope Mobi doesn't mind me shilling it...!

# Labels for text.
@onready var textLabel = $CanvasLayer/Text
@onready var animationTextbox = $AnimationPlayerTextbox
@onready var animationShade = $AnimationPlayerShade

# Sound banks.
@onready var soundBankTalk = $AudioStreamTalk
@onready var soundBankExtra = $AudioStreamExtra

var delayTimer := 0.0 ## Time before the next sequence is printed.
var currentDialogue: String = "" ## Dialogue storage in memory that's yet to be printed.
var confirmOption = false ## Can the player advance the text?
var dialogueList := [] ## List of all actions currently on storage.
var speakerMasterList := [] ## List of all Speakers currently on storage.
var speakerList := [null, null, null] ## List of what character each Speaker file is.
var animationPlaying = true ## Is an animation currently playing?
var goingFast = false ## Is the text advancing at high speed?
var justStarted = true ## Did we just start this thing? Prevents the first line from breaking.

# THINGS THAT CAN BE EDITED DIRECTLY AFTER INSTANTIATION
var backgroundShade = true ## Will the black background shade take effect? Can be modified before adding.

enum textBoxStyle {JAGGED1, JAGGED2, JAGGED3, NARRATION} ## Determines shape of the textbox.
enum speakerPosition {LEFT = 0, CENTER = 1, MIDDLE = 1, RIGHT = 2}
enum speakerDirection {LEFT, RIGHT}
enum speakerEnterMode {LEFT, RIGHT, FADE}
enum speakerExitMode {LEFT, RIGHT, FADE}

var speaker1Entering = false
var speaker2Entering = false
var speaker3Entering = false

var talkSound = "res://assets/audio/sfx/Dialogue/DialogueRegular.wav" ## The talk sound that's currently being used.

# Storage for textures.
@onready var speaker1 = $CanvasLayerCharacters/Speaker1
@onready var speaker2 = $CanvasLayerCharacters/Speaker2
@onready var speaker3 = $CanvasLayerCharacters/Speaker3
@onready var dialogueBox = $CanvasLayer/DialogueBox

# TODO: make fadeouts a thing.
# Fadeout length is usually 33 frames out of 60.

# Default is 5 frames.
const TEXTSPEED = (1.0/60.0) * 5.0
const TEXTSPEEDFAST = (1.0/60.0)

func _init():
	# Define the built-in characters
	# If you wish to add more characters, set them up here!
	# Otherwise, you might have to define them every time you want to use them
	# in a scene, and that's too slow...
	# TODO: find out what dialogue sounds each character has
	# TODO: add more characters
	defineSpeaker("Sonic", "res://characters/sonic/sprites/SonicDialoguePortraits.png", ["Standard", "Thumbs Up", "Confused", "Determined"])
	defineSpeaker("Tails", "res://characters/tails/sprites/TailsDialoguePortraits.png", ["Standard", "Worried", "Determined"])
	defineSpeaker("Knuckles", "res://characters/knuckles/sprites/KnucklesDialoguePortraits.png", ["Standard", "Concerned", "Determined"])
	
	# test, delete once over with
	addSpeaker("Tails", 0, 1, "Left", "Right")
	addDialogue("Testing 1!", 3)
	addDialogue("Testing 2!")
	addSpeaker("Sonic", 0, 0, "Right", "Left", false)
	addSpeaker("Knuckles", 1, 2, "Left", "Right")
	addDialogue("This text is really long and boring...", 1)

func _ready():
	if backgroundShade == true:
		animationShade.play("Initial")
	
	# Set the initial box style.
	for dialogueValue in dialogueList.size():
		if dialogueList[dialogueValue - 1][0] == "Dialogue":
			dialogueBox.texture.region.position.y = 48 * dialogueList[dialogueValue - 1][1].boxStyle
			break

func _physics_process(delta):
	# Keep refreshing until the first bit of dialogue appears.
	if animationPlaying == true and not currentDialogue:
		if animationTextbox.current_animation == "Idle":
			setUpDialogue()
			animationPlaying = false
		return
	
	if currentDialogue.length() > 0:
		if delayTimer <= 0:
			# Prints the first letter into box
			textLabel.text += currentDialogue.left(1)
			if goingFast == true:
				delayTimer = TEXTSPEEDFAST
			else:
				delayTimer = TEXTSPEED
			# Erases first letter of stored dialogue
			currentDialogue = currentDialogue.erase(0)
			# Play the dialogue sound
			soundBankTalk.play()
		else:
			delayTimer -= delta
	elif animationPlaying == false:
		confirmOption = true
	
	# Speed up the textbox, advance it, or delete it.
	if Input.is_action_just_pressed("jump1"):
		if confirmOption == true:
			confirmOption = false
			setUpDialogue()
		else:
			# Speed up the text.
			if dialogueList[0][0] == "Dialogue":
				goingFast = true

func setUpDialogue():
	# Remove the last used object if we just started.
	if justStarted == true:
		justStarted = false
	else:
		dialogueList.remove_at(0)
	# Remove speed-up mode.
	goingFast = false
	# If that's all the dialogue, remove the textbox.
	if not dialogueList:
		# TODO: add option for either just deleting it or
		# doing the regular dialogue exit
		animationTextbox.play("Exiting")
				# Taking away the background shade
		if backgroundShade:
			animationShade.play("Exiting")
	else:
		# This accounts for when we have more than one dialogue entity going.
		var moreDialogue = true
		while moreDialogue == true:
			# Let's check if we have dialogue or a speaker change/addition/removal.
			if dialogueList[0][0] == "Dialogue":
				# Get the text currently in the box to disappear.
				textLabel.text = ""
				# Set the textbox style and dialogue.
				dialogueBox.texture.region.position.y = 48 * dialogueList[0][1].boxStyle
				currentDialogue = dialogueList[0][1].dialogue
				moreDialogue = false
			elif dialogueList[0][0] == "addSpeaker":
				var options = [dialogueList[0][1], dialogueList[0][2], dialogueList[0][3], dialogueList[0][4], dialogueList[0][5], dialogueList[0][6]]
				addSpeakerDefinition(options[0], options[1], options[2], options[3], options[4], options[5])
				if options[5] == false:
					print(dialogueList[0])
				elif animationPlaying == false:
					moreDialogue = false
				else:
					pass
	

# Adds a DialogueEntry class that stores all the info of a single piece of dialogue
class DialogueEntry:
	# Our info
	var dialogue: String = ""
	var boxStyle: int = textBoxStyle.JAGGED1
	
	# Parameterized constructor
	func _init(setDialogue: String = "", setBoxStyle: int = textBoxStyle.JAGGED1):
		dialogue = setDialogue
		boxStyle = setBoxStyle

# Adds new dialogue to the queue using the class
func addDialogue(setDialogue: String, setBoxStyle: int = textBoxStyle.JAGGED1):
	# Instantiate a class
	var dialogue = DialogueEntry.new(setDialogue, setBoxStyle)
	# Then, insert that object into our array!
	dialogueList.append(["Dialogue", dialogue]);

# Speaker class that defines a Speaker.
class DialogueSpeaker:
	var name: String
	var poseTexture: String
	var poses: Array
	var sound: String
	
	# Parameterized constructor
	func _init(setName: String, setposeTexture: String, setPoses: Array = ["Standard"], setSound: String = "res://assets/audio/sfx/Dialogue/DialogueRegular.wav"):
		name = setName
		poseTexture = setposeTexture
		poses = setPoses
		sound = setSound

# This defines a speaker.
func defineSpeaker(setName: String, setposeTexture: String, setPoses: Array = ["Standard"], setSound: String = "res://assets/audio/sfx/Dialogue/DialogueRegular.wav"):
	var speaker = DialogueSpeaker.new(setName, setposeTexture, setPoses, setSound)
	speakerMasterList.append(speaker)

# Adds a Speaker to the list of commands.
func addSpeaker(setName: String, setPose, setPosition: int, setEnterMode, setDirection, setDelay: bool = true):
	# TODO: make this append to dialogue list and fix everything from that
	dialogueList.append(["addSpeaker", setName, setPose, setPosition, setEnterMode, setDirection, setDelay])
	pass

# Adds a Speaker to the current scene.
func addSpeakerDefinition(setName: String, setPose, setPosition: int, setEnterMode, setDirection, setDelay: bool = true):
	animationPlaying = true
	# First, check if this speaker actually exists.
	var speakerIndex
	for speakerValue in speakerMasterList.size():
		if speakerMasterList[speakerValue].name == setName:
			speakerIndex = speakerValue
			break
	if speakerIndex == null:
		print("There's no character with name " + setName + "!")
		return
	
	# Variable where our texture'll be stored
	var speaker
	# Variable for our tween
	var tween = create_tween()
	
	# Error handling
	if speakerList[0] and speakerList[1] and speakerList[2]:
		print("Cannot add any more characters!")
		return
	
	if speakerList[0] == null:
		# Store the name in memory
		speakerList[0] = setName
		# For some reason, I have to define the speaker label like this,
		# or else it will return "Nil."
		speaker = speaker1
	if speakerList[1] == null and speaker == null:
		# Store the name in memory
		speakerList[1] = setName
		speaker = speaker2
	if speakerList[2] == null and speaker == null:
		# Store the name in memory
		speakerList[2] = setName
		speaker = speaker3
	
	# Set the pose direction.
	if (setDirection is int and setDirection == speakerDirection.LEFT) or (setDirection is String and setDirection.to_upper() == "LEFT"):
		speaker.flip_h = true
	else:
		speaker.flip_h = false
	
	# Set the pose texture.
	speaker.texture.atlas = load(speakerMasterList[speakerIndex].poseTexture)
	
	# Define which pose we're doing.
	var poseIndex = null
	if setPose is int:
		# This is pretty easy.
		poseIndex = setPose
	elif setPose is String:
		# This, however, is a little harder...
		# We have to find exactly which pose it is.
		# So, for each pose in our index...
		for speakerPose in speakerMasterList[speakerIndex].poses.size():
			# ...if the speaker pose name matches up with our given parameter...
			if speakerMasterList[speakerIndex].poses[speakerPose] == setPose:
				# ...then we set our pose Index.
				poseIndex = speakerPose
				break
		
	# Error handling.
	if poseIndex == null:
		print("Not a valid pose! Relying on default.")
		poseIndex = 0
	
	# Set the pose coordinates.
	speaker.texture.region.position.x = poseIndex * 96

	# Set where our speaker initially is depending on our mode.
	if (setEnterMode is int and setEnterMode == speakerEnterMode.LEFT) or (setEnterMode is String and setEnterMode.to_upper() == "LEFT"):
		speaker.position.x = -96
		# Set trans and easing, then execute the animation.
		tween.set_trans(Tween.TRANS_EXPO)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(speaker, "position", Vector2(72, speaker.position.y), 40.0/60.0)
		delayTimer = 40.0/60.0
	elif (setEnterMode is int and setEnterMode == speakerEnterMode.RIGHT) or (setEnterMode is String and setEnterMode.to_upper() == "RIGHT"):
		speaker.position.x = 240
		# Set trans and easing, then execute the animation.
		tween.set_trans(Tween.TRANS_EXPO)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(speaker, "position", Vector2(72, speaker.position.y), 40.0/60.0)
		tween.tween_callback(changeAnimationPlaying)
		delayTimer = 40.0/60.0
	else:
		speaker.position.x = 72
	
	# Finally, let the program know it's ready to move on!
	setUpDialogue()
	
# Dedicated function to change this value to false.
# For tweens to do this after they end... why...?
func changeAnimationPlaying():
	animationPlaying = false

# Changes the speaker's pose and/or direction.
func changeSpeakerPose(setName: String, setChange: int, setPose: int = -1, setDirection: int = -1):
	pass

# Animations for the textbox.
func _on_animation_player_animation_finished(anim_name):
	if anim_name == "Initial":
		animationTextbox.play("Idle")
	elif anim_name == "Exiting":
		queue_free()

# Animations for the background shade.
func _on_animation_player_shade_animation_finished(anim_name):
	if anim_name == "Initial":
		animationShade.play("Idle")
	elif anim_name == "Exiting":
		queue_free()
