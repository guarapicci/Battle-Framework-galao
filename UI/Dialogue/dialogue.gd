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

# Signal for when the dialogue is completed.
# Suggested by guarapicci.
signal dialogue_ended

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
var noDelay = false ## Is our current speaker staying in position?

# THINGS THAT CAN BE EDITED DIRECTLY AFTER INSTANTIATION
var backgroundShade = true ## Will the black background shade take effect? Can be modified before adding.

enum textBoxStyle {JAGGED1, JAGGED2, JAGGED3, NARRATION} ## Determines shape of the textbox.
enum speakerPosition {LEFT = 0, CENTER = 1, MIDDLE = 1, RIGHT = 2}
enum speakerDirection {LEFT, RIGHT}
enum speakerEnterMode {LEFT, RIGHT, FADE}
enum speakerExitMode {LEFT, RIGHT, FADE}
enum speakerInternalPosition {LEFT = 1, MIDDLE_LEFT = 21, MIDDLE = 72, MIDDLE_RIGHT = 129, RIGHT = 145}

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
	defineSpeaker("Sonic", "res://characters/sonic/sprites/SonicDialoguePortraits.png", ["Standard", "Thumbs Up", "Confused", "Determined"])
	defineSpeaker("Tails", "res://characters/tails/sprites/TailsDialoguePortraits.png", ["Standard", "Worried", "Determined"])
	defineSpeaker("Knuckles", "res://characters/knuckles/sprites/KnucklesDialoguePortraits.png", ["Standard", "Concerned", "Determined"])
	defineSpeaker("Shadow", "res://characters/shadow/sprites/ShadowDialoguePortraits.png", ["Standard", "Intrigued", "Determined"])
	defineSpeaker("Rouge", "res://characters/rouge/sprites/RougeDialoguePortraits.png", ["Standard", "Disgusted"])
	defineSpeaker("Amy", "res://characters/amy/sprites/AmyDialoguePortraits.png", ["Standard", "Angry", "Happy", "Concerned"])
	defineSpeaker("Cream", "res://characters/cream/sprites/CreamDialoguePortraits.png", ["Standard", "Sad", "Excited"])
	defineSpeaker("Chaos Gamma", "res://characters/chaos_gamma/sprites/ChaosGammaDialoguePortraits.png", ["Standard", "Identifying", "Standard (Guard Robo)"])
	defineSpeaker("Chaos", "res://characters/chaos/sprites/ChaosDialoguePortraits.png", ["Standard"])
	defineSpeaker("Emerl", "res://characters/emerl/sprites/EmerlDialoguePortraits.png", ["Standard", "Intrigued", "Powering Up", "Awakened", "Intrigued (Phi)"])
	defineSpeaker("Eggman", "res://characters/eggman/sprites/EggmanDialoguePortraits.png", ["Standard", "Angry"])
	
	# test, delete once over with
	addSpeaker(["Tails", 1, "Middle", "Left", "Right"], ["Sonic", 0, "Left", "Left", "Right"], ["Knuckles", 0, "Right", "Left", "Right"])
	addDialogue("Testing 1!", 3)

func _ready():
	if backgroundShade == true:
		animationShade.play("Initial")
	
	# Set the initial box style.
	for dialogueValue in dialogueList.size():
		if dialogueList[dialogueValue][0] == "Dialogue":
			dialogueBox.texture.region.position.y = 48 * dialogueList[dialogueValue][1].boxStyle
			break

func _physics_process(delta):
	# Keep refreshing until the first bit of dialogue appears.
	if justStarted == true and not currentDialogue:
		if animationTextbox.current_animation == "Idle":
			setUpDialogue()
			justStarted = false
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
	if Input.is_action_just_pressed("attack1"):
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
		# Let's check if we have dialogue or a speaker change/addition/removal.
		if dialogueList[0][0] == "Dialogue":
			# Get the text currently in the box to disappear.
			textLabel.text = ""
			# Set the textbox style and dialogue.
			dialogueBox.texture.region.position.y = 48 * dialogueList[0][1].boxStyle
			currentDialogue = dialogueList[0][1].dialogue
		elif dialogueList[0][0] == "addSpeaker":
			
			addSpeakerDefinition(dialogueList[0][1], dialogueList[0][2], dialogueList[0][3])
		elif dialogueList[0][0] == "changeSpeaker":
			changeSpeakerDefinition(dialogueList[0][1], dialogueList[0][2], dialogueList[0][3], dialogueList[0][4])
	

# Adds a DialogueEntry class that stores all the info of a single piece of dialogue
class DialogueEntry:
	# Our info
	var dialogue: String = ""
	var boxStyle: int = textBoxStyle.JAGGED1
	var speaker: String = ""
	
	# Parameterized constructor
	func _init(setDialogue: String = "", setBoxStyle: int = textBoxStyle.JAGGED1, setSpeaker: String = ""):
		dialogue = setDialogue
		boxStyle = setBoxStyle
		speaker = setSpeaker

# Adds new dialogue to the queue using the class
func addDialogue(setDialogue: String, setBoxStyle: int = textBoxStyle.JAGGED1, setSpeaker: String = ""):
	# Instantiate a class
	var dialogue = DialogueEntry.new(setDialogue, setBoxStyle, setSpeaker)
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

## This function is used to add a Speaker to the current dialogue list.
## It uses up to 3 arrays as parameters, each with their own sub-parameters.
## In order, they are...[br]
## [br]
## [b]setName[/b]: The name of the speaker you want to enter.[br]
## [b]setPose[/b]: The pose you want the speaker to be in.[br]
## [b]setPosition[/b]: The position you want the speaker to end up in.
## You can set this to be "Left", "Middle", or "Right".[br]
## [b]setEnterMode[/b]: How you want the speaker to enter.
## You can set this to be "Left" (comes in from the left), "Right" (comes in from the right),
## or "Fade" (fades into the frame).[br]
## [b]setDirection[/b]: Sets where the character is facing.
## You can set this to be "Left" or "Right".[br]
func addSpeaker(storedSpeaker1: Array, storedSpeaker2: Array = [], storedSpeaker3: Array = []):
	# Change the position to match the direction we're going in.
	# This is a lengthy process for all of our speakers...
	# NOTICE: Optimization would be nice, but this works for now.
	if storedSpeaker1[2] is String:
		match storedSpeaker1[2].to_upper():
			"LEFT":
				storedSpeaker1[2] = 0
			"RIGHT":
				storedSpeaker1[2] = 2
			_:
				storedSpeaker1[2] = 1
	
	if storedSpeaker2 != []:
		if storedSpeaker2[2] is String:
			match storedSpeaker2[2].to_upper():
				"LEFT":
					storedSpeaker2[2] = 0
				"RIGHT":
					storedSpeaker2[2] = 2
				_:
					storedSpeaker2[2] = 1
	
	if storedSpeaker3 != []:
		if storedSpeaker3[2] is String:
			match storedSpeaker3[2].to_upper():
				"LEFT":
					storedSpeaker3[2] = 0
				"RIGHT":
					storedSpeaker3[2] = 2
				_:
					storedSpeaker3[2] = 1
	
	dialogueList.append(["addSpeaker", storedSpeaker1, storedSpeaker2, storedSpeaker3])

## Adds a Speaker to the current scene.[br]
## [b]Not intended for coder use.[/b]
func addSpeakerDefinition(storedSpeaker1: Array, storedSpeaker2: Array = [], storedSpeaker3: Array = []):
	# NOTICE: There could probably be a way to optimize this for all three Speakers
	# instead of having to repeat the same code three times. Optimizations are welcome,
	# but not required.
	
	# REFERENCE:
	# [0]: setName
	# [1]: setPose
	# [2]: setPosition
	# [3]: setEnterMode
	# [4]: setDirection
	var setName1 = storedSpeaker1[0]
	var setPose1 = storedSpeaker1[1]
	var setPosition1 = storedSpeaker1[2]
	var setEnterMode1 = storedSpeaker1[3]
	var setDirection1 = storedSpeaker1[4]
	
	var setName2
	var setPose2
	var setPosition2
	var setEnterMode2
	var setDirection2
	
	if storedSpeaker2 != []:
		setName2 = storedSpeaker2[0]
		setPose2 = storedSpeaker2[1]
		setPosition2 = storedSpeaker2[2]
		setEnterMode2 = storedSpeaker2[3]
		setDirection2 = storedSpeaker2[4]
	
	var setName3
	var setPose3
	var setPosition3
	var setEnterMode3
	var setDirection3
	
	if storedSpeaker3 != []:
		setName3 = storedSpeaker3[0]
		setPose3 = storedSpeaker3[1]
		setPosition3 = storedSpeaker3[2]
		setEnterMode3 = storedSpeaker3[3]
		setDirection3 = storedSpeaker3[4]
	
	animationPlaying = true
	
	var speakersAdded: int
	# How much speakers are we adding?
	if storedSpeaker3 != []:
		speakersAdded = 3
	elif storedSpeaker2 != []:
		speakersAdded = 2
	else:
		speakersAdded = 1
	
	# First, check if the speakers actually exist.
	var speakerIndex1
	for speakerValue in speakerMasterList.size():
		if speakerMasterList[speakerValue].name == setName1:
			speakerIndex1 = speakerValue
			break
	if speakerIndex1 == null:
		print("There's no character with name " + setName1 + "!")
		return
	
	var speakerIndex2
	if speakersAdded >= 2:
		for speakerValue in speakerMasterList.size():
			if speakerMasterList[speakerValue].name == setName2:
				speakerIndex2 = speakerValue
				break
		if speakerIndex2 == null:
			print("There's no character with name " + setName2 + "!")
			return
	
	var speakerIndex3
	if speakersAdded == 3:
		for speakerValue in speakerMasterList.size():
			if speakerMasterList[speakerValue].name == setName3:
				speakerIndex3 = speakerValue
				break
		if speakerIndex3 == null:
			print("There's no character with name " + setName3 + "!")
			return
	
	# Variable where our texture'll be stored
	var addedSpeaker1
	var addedSpeaker2
	var addedSpeaker3
	# Variable for our tween
	var tween = create_tween()
	# Variable for our speaker internal index
	var speakerInternalIndex1: int
	var speakerInternalIndex2: int
	var speakerInternalIndex3: int
	
	# Error handling
	var currentSpeakerStorage = 0
	for currentSpeaker in speakerList:
		if currentSpeaker != null:
			currentSpeakerStorage += 1
	
	if storedSpeaker3 != []:
		currentSpeakerStorage += 3
	elif storedSpeaker2 != []:
		currentSpeakerStorage += 2
	else:
		currentSpeakerStorage += 1
	
	if currentSpeakerStorage > 3:
		print("Cannot add any more characters!")
		return
	
	# Check if a character with the same name as one of our added Speakers is already here.
	for speakerListName in speakerList:
		if speakerListName is Array:
			if speakerListName[0] == setName1 or speakerListName[0] == setName2 or speakerListName[0] == setName3:
				print("There's already a character here named " + speakerListName[0] + "!")
				return
	
	# Stores our speakers in current memory.
	if speakerList[0] == null:
		speakerList[0] = [setName1, setPosition1]
		addedSpeaker1 = speaker1
		speakerInternalIndex1 = 0
	if speakerList[1] == null:
		if addedSpeaker1 == null:
			speakerList[1] = [setName1, setPosition1]
			addedSpeaker1 = speaker2
			speakerInternalIndex1 = 1
		elif storedSpeaker2 != []:
			speakerList[1] = [setName2, setPosition2]
			addedSpeaker2 = speaker2
			speakerInternalIndex2 = 1
	if speakerList[2] == null:
		if addedSpeaker1 == null:
			speakerList[2] = [setName1, setPosition1]
			addedSpeaker1 = speaker3
			speakerInternalIndex1 = 2
		elif storedSpeaker2 != [] and addedSpeaker2 == null:
			speakerList[2] = [setName2, setPosition2]
			addedSpeaker2 = speaker3
			speakerInternalIndex2 = 2
		elif storedSpeaker3 != []:
			speakerList[2] = [setName3, setPosition3]
			addedSpeaker3 = speaker3
			speakerInternalIndex3 = 2
	
	# Set our pose directions.
	if (setDirection1 is int and setDirection1 == speakerDirection.LEFT) or (setDirection1 is String and setDirection1.to_upper() == "LEFT"):
		addedSpeaker1.flip_h = true
	else:
		addedSpeaker1.flip_h = false
	
	if storedSpeaker2 != []:
		if (setDirection2 is int and setDirection2 == speakerDirection.LEFT) or (setDirection2 is String and setDirection2.to_upper() == "LEFT"):
			addedSpeaker2.flip_h = true
		else:
			addedSpeaker2.flip_h = false
	
	if storedSpeaker3 != []:
		if (setDirection3 is int and setDirection3 == speakerDirection.LEFT) or (setDirection3 is String and setDirection3.to_upper() == "LEFT"):
			addedSpeaker3.flip_h = true
		else:
			addedSpeaker3.flip_h = false
	
	# Set the pose textures.
	addedSpeaker1.texture.atlas = load(speakerMasterList[speakerIndex1].poseTexture)
	
	if storedSpeaker2 != []:
		addedSpeaker2.texture.atlas = load(speakerMasterList[speakerIndex2].poseTexture)
	
	if storedSpeaker3 != []:
		addedSpeaker3.texture.atlas = load(speakerMasterList[speakerIndex3].poseTexture)
	
	# Define which pose we're doing.
	var poseIndex1 = null
	var poseIndex2 = null
	var poseIndex3 = null
	
	if setPose1 is int:
		# This is pretty easy.
		poseIndex1 = setPose1
	elif setPose1 is String:
		# This, however, is a little bit harder...
		# We have to find exactly which pose it is.
		# So, for each pose in our index...
		for speakerPose1 in speakerMasterList[speakerIndex1].poses.size():
			# if the speaker pose name matches up with our given parameter...
			if speakerMasterList[speakerIndex1].poses[speakerPose1] == setPose1:
				# ...then we set our pose index.
				poseIndex1 = speakerPose1
				break
	
	if storedSpeaker2 != []:
		if setPose2 is int:
			poseIndex2 = setPose2
		elif setPose2 is String:
			for speakerPose2 in speakerMasterList[speakerIndex2].poses.size():
				if speakerMasterList[speakerIndex2].poses[speakerPose2] == setPose2:
					poseIndex2 = speakerPose2
					break
	
	if storedSpeaker3 != []:
		if setPose3 is int:
			poseIndex3 = setPose3
		elif setPose3 is String:
			for speakerPose3 in speakerMasterList[speakerIndex3].poses.size():
				if speakerMasterList[speakerIndex3].poses[speakerPose3] == setPose3:
					poseIndex3 = speakerPose3
					break
	
	# Error handling.
	if poseIndex1 == null:
		print("Not a valid pose! Relying on default.")
		poseIndex1 = 0
	
	if storedSpeaker2 != [] and poseIndex2 == null:
		print("Not a valid pose! Relying on default.")
		poseIndex2 = 0
	
	if storedSpeaker3 != [] and poseIndex3 == null:
		print("Not a valid pose! Relying on default.")
		poseIndex3 = 0
	
	# Set the pose coordinates.
	addedSpeaker1.texture.region.position.x = poseIndex1 * 96
	
	if storedSpeaker2 != []:
		addedSpeaker2.texture.region.position.x = poseIndex2 * 96
	
	if storedSpeaker3 != []:
		addedSpeaker3.texture.region.position.x = poseIndex3 * 96
	
	# Set where our speaker will go depending on our destination.
	# There are a lot of possible things we can do here.
	# 3 sets for direction, and 3 in each set for number of speakers.
	
	# So first, we have to count how much speakers there are in the first place.
	var speakerCount: int = 0
	for speakerCountIndex in speakerList:
		if speakerCountIndex != null:
			speakerCount += 1
	
	# Now, set our position based on our count and direction.
	var speakerFinalPosition1
	var speakerFinalPosition2
	var speakerFinalPosition3
	
	# Set the speaker we want to move.
	var speakerListIndex = 0
	
	if speakerCount <= 1:
		# No speakers beforehand, one speaker entering
		speakerFinalPosition1 = speakerInternalPosition.MIDDLE
		speakerList[speakerInternalIndex1][1] = speakerInternalPosition.MIDDLE
		noDelay = true
	elif speakerCount <= 2:
		# No speakers beforehand, two speakers entering
		if storedSpeaker2 != []:
			# First enters to right, second enters to left
			if (setPosition1 == speakerPosition.RIGHT) or (setPosition2 == speakerPosition.LEFT):
				speakerFinalPosition1 = speakerInternalPosition.MIDDLE_RIGHT
				speakerFinalPosition2 = speakerInternalPosition.MIDDLE_LEFT
			# First enters to left, second enters to right (default)
			else:
				speakerFinalPosition1 = speakerInternalPosition.MIDDLE_LEFT
				speakerFinalPosition2 = speakerInternalPosition.MIDDLE_RIGHT
			noDelay = true
		# One speaker beforehand, one speaker entering
		else:
			# Current moves to right, new enters to left
			if (setPosition1 == speakerPosition.LEFT) or (setPosition1 == speakerPosition.MIDDLE and setEnterMode1.to_upper() == "LEFT"):
				for speakerMoveIndex in speakerList:
					if speakerMoveIndex != null and speakerInternalIndex1 != speakerListIndex:
						moveSpeaker(speakerListIndex, speakerInternalPosition.MIDDLE_RIGHT)
					speakerListIndex += 1
				speakerFinalPosition1 = speakerInternalPosition.MIDDLE_LEFT
			# Current moves to left, new enters to right
			else:
				for speakerMoveIndex in speakerList:
					if speakerMoveIndex != null and speakerInternalIndex1 != speakerListIndex:
						moveSpeaker(speakerListIndex, speakerInternalPosition.MIDDLE_LEFT)
					speakerListIndex += 1
				speakerFinalPosition1 = speakerInternalPosition.MIDDLE_RIGHT
	else:
		# No speakers beforehand, three speakers entering
		if storedSpeaker3 != []:
			if setPosition1 == speakerPosition.RIGHT:
				speakerFinalPosition1 = speakerInternalPosition.RIGHT
			elif setPosition1 == speakerPosition.MIDDLE:
				speakerFinalPosition1 = speakerInternalPosition.MIDDLE
			else:
				speakerFinalPosition1 = speakerInternalPosition.LEFT
			
			if setPosition2 == speakerPosition.LEFT:
				speakerFinalPosition2 = speakerInternalPosition.LEFT
			elif setPosition2 == speakerPosition.LEFT:
				speakerFinalPosition2 = speakerInternalPosition.RIGHT
			else:
				speakerFinalPosition2 = speakerInternalPosition.MIDDLE
			
			if setPosition3 == speakerPosition.LEFT:
				speakerFinalPosition3 = speakerInternalPosition.LEFT
			elif setPosition3 == speakerPosition.MIDDLE:
				speakerFinalPosition3 = speakerInternalPosition.MIDDLE
			else:
				speakerFinalPosition3 = speakerInternalPosition.RIGHT
			noDelay = true
		# One speaker beforehand, two speakers entering
		elif storedSpeaker2 != []:
			# Current speaker moves to the right, new speaker 1 moves to the left, new speaker 2 moves to the middle
			if (setPosition1 == speakerPosition.LEFT and setPosition2 == speakerPosition.MIDDLE) or (setPosition1 == speakerPosition.LEFT and setPosition2 == speakerPosition.LEFT):
				for speakerMoveIndex in speakerList:
					if speakerMoveIndex != null and speakerInternalIndex1 != speakerListIndex and speakerInternalIndex2 != speakerListIndex:
						moveSpeaker(speakerListIndex, speakerInternalPosition.RIGHT)
					speakerListIndex += 1
				speakerFinalPosition1 = speakerInternalPosition.LEFT
				speakerFinalPosition2 = speakerInternalPosition.MIDDLE
			# Current speaker moves to the right, new speaker 1 moves to the middle, new speaker 2 moves to the left
			elif (setPosition1 == speakerPosition.MIDDLE and setPosition2 == speakerPosition.LEFT):
				for speakerMoveIndex in speakerList:
					if speakerMoveIndex != null and speakerInternalIndex1 != speakerListIndex and speakerInternalIndex2 != speakerListIndex:
						moveSpeaker(speakerListIndex, speakerInternalPosition.RIGHT)
					speakerListIndex += 1
				speakerFinalPosition1 = speakerInternalPosition.MIDDLE
				speakerFinalPosition2 = speakerInternalPosition.LEFT
			# Current speaker moves to the middle, new speaker 1 moves to the left, new speaker 2 moves to the right
			elif (setPosition1 == speakerPosition.LEFT and setPosition2 == speakerPosition.RIGHT):
				for speakerMoveIndex in speakerList:
					if speakerMoveIndex != null and speakerInternalIndex1 != speakerListIndex and speakerInternalIndex2 != speakerListIndex:
						moveSpeaker(speakerListIndex, speakerInternalPosition.MIDDLE)
					speakerListIndex += 1
				speakerFinalPosition1 = speakerInternalPosition.LEFT
				speakerFinalPosition2 = speakerInternalPosition.RIGHT
			# Current speaker moves to the middle, new speaker 1 moves to the right, new speaker 2 moves to the left
			elif (setPosition1 == speakerPosition.RIGHT and setPosition2 == speakerPosition.LEFT):
				for speakerMoveIndex in speakerList:
					if speakerMoveIndex != null and speakerInternalIndex1 != speakerListIndex and speakerInternalIndex2 != speakerListIndex:
						moveSpeaker(speakerListIndex, speakerInternalPosition.MIDDLE)
					speakerListIndex += 1
				speakerFinalPosition1 = speakerInternalPosition.RIGHT
				speakerFinalPosition2 = speakerInternalPosition.LEFT
			# Current speaker moves to the left, new speaker 1 moves to the right, new speaker 2 moves to the middle
			elif (setPosition1 == speakerPosition.RIGHT and setPosition2 == speakerPosition.MIDDLE):
				for speakerMoveIndex in speakerList:
					if speakerMoveIndex != null and speakerInternalIndex1 != speakerListIndex and speakerInternalIndex2 != speakerListIndex:
						moveSpeaker(speakerListIndex, speakerInternalPosition.LEFT)
					speakerListIndex += 1
				speakerFinalPosition1 = speakerInternalPosition.RIGHT
				speakerFinalPosition2 = speakerInternalPosition.MIDDLE
			# Current speaker moves to the left, new speaker 1 moves to the middle, new speaker 2 moves to the right
			else:
				for speakerMoveIndex in speakerList:
					if speakerMoveIndex != null and speakerInternalIndex1 != speakerListIndex and speakerInternalIndex2 != speakerListIndex:
						moveSpeaker(speakerListIndex, speakerInternalPosition.LEFT)
					speakerListIndex += 1
				speakerFinalPosition1 = speakerInternalPosition.MIDDLE
				speakerFinalPosition2 = speakerInternalPosition.RIGHT
		
		# Two speakers beforehand, one speaker entering
		else:
			if setPosition1 == speakerPosition.LEFT:
				for speakerMoveIndex in speakerList:
					if speakerMoveIndex != null and speakerInternalIndex1 != speakerListIndex:
						if speakerList[speakerListIndex][1] == speakerInternalPosition.MIDDLE_LEFT:
							moveSpeaker(speakerListIndex, speakerInternalPosition.MIDDLE)
						else:
							moveSpeaker(speakerListIndex, speakerInternalPosition.RIGHT)
					speakerListIndex += 1
				speakerFinalPosition1 = speakerInternalPosition.LEFT
			elif setPosition1 == speakerPosition.MIDDLE:
				for speakerMoveIndex in speakerList:
					if speakerMoveIndex != null and speakerInternalIndex1 != speakerListIndex:
						if speakerList[speakerListIndex][1] == speakerInternalPosition.MIDDLE_LEFT:
							moveSpeaker(speakerListIndex, speakerInternalPosition.LEFT)
						else:
							moveSpeaker(speakerListIndex, speakerInternalPosition.RIGHT)
					speakerListIndex += 1
				speakerFinalPosition1 = speakerInternalPosition.MIDDLE
			else:
				for speakerMoveIndex in speakerList:
					if speakerMoveIndex != null and speakerInternalIndex1 != speakerListIndex:
						if speakerList[speakerListIndex][1] == speakerInternalPosition.MIDDLE_LEFT:
							moveSpeaker(speakerListIndex, speakerInternalPosition.LEFT)
						else:
							moveSpeaker(speakerListIndex, speakerInternalPosition.MIDDLE)
					speakerListIndex += 1
				speakerFinalPosition1 = speakerInternalPosition.RIGHT
	
	# Set our delay, assuming our speakers don't just stay where they are.
	if noDelay == false:
		tween.tween_interval(40.0/60.0)
	
	# Set where our speakers initially are depending on our mode, and where they're going.
	if (setEnterMode1 is int and setEnterMode1 == speakerEnterMode.LEFT) or (setEnterMode1 is String and setEnterMode1.to_upper() == "LEFT"):
		addedSpeaker1.position.x = -96
		# Set trans and easing, then execute the animation.
		tween.set_trans(Tween.TRANS_EXPO)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(addedSpeaker1, "position:x", speakerFinalPosition1, 40.0/60.0)
	elif (setEnterMode1 is int and setEnterMode1 == speakerEnterMode.RIGHT) or (setEnterMode1 is String and setEnterMode1.to_upper() == "RIGHT"):
		addedSpeaker1.position.x = 240
		# Set trans and easing, then execute the animation.
		tween.set_trans(Tween.TRANS_EXPO)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(addedSpeaker1, "position:x", speakerFinalPosition1, 40.0/60.0)
	elif (setEnterMode1 is int and setEnterMode1 == speakerEnterMode.FADE) or (setEnterMode1 is String and setEnterMode1.to_upper() == "FADE"):
		addedSpeaker1.modulate = Color("ffffff00")
		tween.tween_property(addedSpeaker1, "position:x", speakerFinalPosition1, 0)
		tween.tween_property(addedSpeaker1, "modulate", Color("ffffffff"), 40.0/60.0)
	else:
		tween.tween_property(addedSpeaker1, "position:x", speakerFinalPosition1, 0)
	
	speakerList[speakerInternalIndex1][1] = speakerFinalPosition1
	
	if storedSpeaker2 != []:
		tween.set_parallel(true)
		if (setEnterMode2 is int and setEnterMode2 == speakerEnterMode.LEFT) or (setEnterMode2 is String and setEnterMode2.to_upper() == "LEFT"):
			addedSpeaker2.position.x = -96
			# Set trans and easing, then execute the animation.
			tween.set_trans(Tween.TRANS_EXPO)
			tween.set_ease(Tween.EASE_OUT)
			tween.tween_property(addedSpeaker2, "position:x", speakerFinalPosition2, 40.0/60.0)
		elif (setEnterMode2 is int and setEnterMode2 == speakerEnterMode.RIGHT) or (setEnterMode2 is String and setEnterMode2.to_upper() == "RIGHT"):
			addedSpeaker2.position.x = 240
			# Set trans and easing, then execute the animation.
			tween.set_trans(Tween.TRANS_EXPO)
			tween.set_ease(Tween.EASE_OUT)
			tween.tween_property(addedSpeaker2, "position:x", speakerFinalPosition2, 40.0/60.0)
		elif (setEnterMode2 is int and setEnterMode2 == speakerEnterMode.FADE) or (setEnterMode2 is String and setEnterMode2.to_upper() == "FADE"):
			addedSpeaker2.modulate = Color("ffffff00")
			tween.tween_property(addedSpeaker2, "position:x", speakerFinalPosition2, 0)
			tween.tween_property(addedSpeaker2, "modulate", Color("ffffffff"), 40.0/60.0)
		else:
			tween.tween_property(addedSpeaker2, "position:x", speakerFinalPosition2, 0)
		
		speakerList[speakerInternalIndex2][1] = speakerFinalPosition2
	
	if storedSpeaker3 != []:
		if (setEnterMode3 is int and setEnterMode3 == speakerEnterMode.LEFT) or (setEnterMode3 is String and setEnterMode3.to_upper() == "LEFT"):
			addedSpeaker3.position.x = -96
			# Set trans and easing, then execute the animation.
			tween.set_trans(Tween.TRANS_EXPO)
			tween.set_ease(Tween.EASE_OUT)
			tween.tween_property(addedSpeaker3, "position:x", speakerFinalPosition3, 40.0/60.0)
		elif (setEnterMode3 is int and setEnterMode3 == speakerEnterMode.RIGHT) or (setEnterMode3 is String and setEnterMode3.to_upper() == "RIGHT"):
			addedSpeaker3.position.x = 240
			# Set trans and easing, then execute the animation.
			tween.set_trans(Tween.TRANS_EXPO)
			tween.set_ease(Tween.EASE_OUT)
			tween.tween_property(addedSpeaker3, "position:x", speakerFinalPosition3, 40.0/60.0)
		elif (setEnterMode3 is int and setEnterMode3 == speakerEnterMode.FADE) or (setEnterMode3 is String and setEnterMode3.to_upper() == "FADE"):
			addedSpeaker3.modulate = Color("ffffff00")
			tween.tween_property(addedSpeaker3, "position:x", speakerFinalPosition3, 0)
			tween.tween_property(addedSpeaker3, "modulate", Color("ffffffff"), 40.0/60.0)
		else:
			tween.tween_property(addedSpeaker3, "position:x", speakerFinalPosition3, 0)
		
		speakerList[speakerInternalIndex3][1] = speakerFinalPosition3
	
	tween.set_parallel(false)
	tween.tween_callback(changeAnimationPlaying)
	noDelay = false
	
	# Finally, let the program know it's ready to move on!
	tween.tween_callback(setUpDialogue)
	
# Dedicated function to change this value to false.
# For tweens to do this after they end... why...?
func changeAnimationPlaying():
	animationPlaying = false

# Changes the speaker's location on the grid.
# Not intended for general coder use.
func moveSpeaker(setIndex: int, setPosition: int):
	# Match the speaker with our node.
	var speaker
	match setIndex:
		0:
			speaker = speaker1
		1:
			speaker = speaker2
		_:
			speaker = speaker3
	
	# Create and move our tween if the speaker isn't staying where they are.
	if speakerList[setIndex][1] == setPosition:
		noDelay = true
	else:
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_EXPO)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(speaker, "position:x", setPosition, 40.0/60.0)
	
		# Finally, save our position into memory.
		speakerList[setIndex][1] = setPosition
	
func changeSpeaker(setName: String, setPose = -1, setDirection = -1, setDelay: bool = true):
	dialogueList.append(["changeSpeaker", setName, setPose, setDirection, setDelay])

# Changes the speaker's pose and/or direction.
func changeSpeakerDefinition(setName: String, setPose = -1, setDirection = -1, setDelay: bool = true):
	animationPlaying = true
	
	# First, check if our speaker exists.
	var speakerIndex
	for speakerValue in speakerList.size():
		if speakerList[speakerValue][0] == setName:
			speakerIndex = speakerValue
			break
	if speakerIndex == null:
		print("There's no character with name " + setName + "!")
		return
	
	# Set which speaker we're modifying.
	var speaker
	match speakerIndex:
		0:
			speaker = speaker1
		1:
			speaker = speaker2
		_:
			speaker = speaker3
	
	# Set our tween.
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN)
	# Flip the speaker around.
	tween.tween_property(speaker, "scale:x", 0, 10.0/60.0)
	
	# Mid-flip, set the direction and pose.
	if (setDirection is int and setDirection == speakerDirection.LEFT) or (setDirection is String and setDirection.to_upper() == "LEFT"):
		tween.tween_property(speaker, "flip_h", true, 0)
	elif (setDirection is int and setDirection == speakerDirection.RIGHT) or (setDirection is String and setDirection.to_upper() == "RIGHT"):
		tween.tween_property(speaker, "flip_h", false, 0)
	
	# Set the pose coordinates.
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
	tween.tween_property(speaker, "texture:region:position:x", (poseIndex * 96), 0)
	
	# Finish off the flip!
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(speaker, "scale:x", 1, 10.0/60.0)
	tween.tween_callback(changeAnimationPlaying)
	
	# Finally, let the program know it's ready to move on!
	# We have to define it on a delay depending on if there's delay or not.
	if setDelay == false:
		setUpDialogue()
	else:
		tween.tween_callback(setUpDialogue)

# Animations for the textbox.
func _on_animation_player_animation_finished(anim_name):
	if anim_name == "Initial":
		animationTextbox.play("Idle")
	elif anim_name == "Exiting":
		dialogue_ended.emit()
		queue_free()

# Animations for the background shade.
func _on_animation_player_shade_animation_finished(anim_name):
	if anim_name == "Initial":
		animationShade.play("Idle")
