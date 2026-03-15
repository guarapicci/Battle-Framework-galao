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
var afterMovingEdgeCase = false ## Did we just go through a movement edge case?
var edgeCaseStoredPosition ## What's the position that our one speaker was just in?

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
	addSpeaker("Tails", 4, 1, "Left", "Right")
	addDialogue("Testing 1!", 3)
	addDialogue("Hey, we need help with this dialogue set!")
	addSpeaker("Knuckles", 1, "Left", "Fade", "Left", false)
	addSpeaker("Sonic", 0, "Right", "Left", "Right")
	changeSpeaker("Sonic", 2, "Left")
	addDialogue("Too bad Emerl's a goner.")
	changeSpeaker("Tails", 1, "Left")
	addDialogue("Really, Sonic?")
	changeSpeaker("Sonic", 2, "Right")
	addDialogue("I mean, c'mon, it's related, right?", 2)
	changeSpeaker("Knuckles", 2, "Right")
	addDialogue("Not cool, Sonic. You'd know better than to joke around like that.")

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
			# This is an edge variable that disables initial character movement based on
			# if the next variable also adds a speaker and if there is no delay between the two.
			var movingEdgeCase = false
			if dialogueList[1]:
				if dialogueList[1][0] == "addSpeaker" and dialogueList[0][6] == false:
					movingEdgeCase = true
			addSpeakerDefinition(dialogueList[0][1], dialogueList[0][2], dialogueList[0][3], dialogueList[0][4], dialogueList[0][5], dialogueList[0][6], movingEdgeCase, afterMovingEdgeCase)
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

## This function is used to add a Speaker to the current dialogue list.[br]
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
## [b]setDelay[/b]: Choose if you want there to be a delay whilst the speaker is entering.
func addSpeaker(setName: String, setPose, setPosition, setEnterMode, setDirection, setDelay: bool = true):
	# Change the position to match the direction we're going in.
	if setPosition is String:
		match setPosition.to_upper():
			"LEFT":
				setPosition = 0
			"RIGHT":
				setPosition = 2
			_:
				setPosition = 1
				
	dialogueList.append(["addSpeaker", setName, setPose, setPosition, setEnterMode, setDirection, setDelay])

## Adds a Speaker to the current scene.[br]
## [b]Not intended for coder use.[/b]
func addSpeakerDefinition(setName: String, setPose, setPosition: int, setEnterMode, setDirection, setDelay: bool = true, setMovingEdgeCase: bool = false, setAfterMovingEdgeCase: bool = false):
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
	# Variable for our speaker internal index
	var speakerInternalIndex: int
	
	# Error handling
	if speakerList[0] and speakerList[1] and speakerList[2]:
		print("Cannot add any more characters!")
		return
		
	# Check if a character with that name is already here.
	for speakerListName in speakerList:
		if speakerListName is Array:
			if speakerListName[0] == setName:
				print("There's already a character here named " + setName + "!")
				return
	
	if speakerList[0] == null:
		# Store the name in memory
		speakerList[0] = [setName, setPosition]
		speaker = speaker1
		speakerInternalIndex = 0
	if speakerList[1] == null and speaker == null:
		# Store the name in memory
		speakerList[1] = [setName, setPosition]
		speaker = speaker2
		speakerInternalIndex = 1
	if speakerList[2] == null and speaker == null:
		# Store the name in memory
		speakerList[2] = [setName, setPosition]
		speaker = speaker3
		speakerInternalIndex = 2
	
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
	
	# Set where our speaker will go depending on our destination.
	# There are 9 possible things we can do here.
	# 3 sets for direction, and 3 in each set for number of speakers.
	
	# So first, we have to count how much speakers there are in the first place.
	var speakerCount: int = 0
	for speakerCountIndex in speakerList:
		if speakerCountIndex != null:
			speakerCount += 1
	
	# Now, set our position based on our count and direction.
	var speakerFinalPosition
	# Set the speaker we want to move.
	var speakerListIndex = 0
	
	# Fixes an edge case.
	# When two speakers are added, and another speaker is already there...
	# IF that speaker doesn't move, no delay.
	# ELSE, do add delay.
	if setMovingEdgeCase == true:
		for speakerValue in speakerList.size():
			if speakerList[speakerValue][0] != setName and speakerList[speakerValue] != null:
				edgeCaseStoredPosition = speakerList.slice(speakerValue, speakerValue + 1)
				break
	
	if speakerCount <= 1:
		speakerFinalPosition = speakerInternalPosition.MIDDLE
		speakerList[speakerInternalIndex][1] = speakerInternalPosition.MIDDLE
	elif setPosition == speakerPosition.LEFT:
		# Set all the possibilities of the external speakers.
		match speakerCount:
			3:
				# Check which speaker we've gotta move.
				for speakerMoveIndex in speakerList:
					if (speakerMoveIndex[1] == speakerInternalPosition.MIDDLE_LEFT) and speakerInternalIndex != speakerListIndex:
						moveSpeaker(speakerListIndex, speakerInternalPosition.MIDDLE, setMovingEdgeCase)
					elif (speakerMoveIndex[1] == speakerInternalPosition.MIDDLE_RIGHT) and speakerInternalIndex != speakerListIndex:
						moveSpeaker(speakerListIndex, speakerInternalPosition.RIGHT, setMovingEdgeCase)
					speakerListIndex += 1
				speakerFinalPosition = speakerInternalPosition.LEFT
			2:
				# TODO: replace with while loop that gets the index maybe?
				for speakerMoveIndex in speakerList:
					if speakerMoveIndex != null and speakerInternalIndex != speakerListIndex:
						moveSpeaker(speakerListIndex, speakerInternalPosition.MIDDLE_RIGHT, setMovingEdgeCase)
					speakerListIndex += 1
				speakerFinalPosition = speakerInternalPosition.MIDDLE_LEFT
		pass
	elif setPosition == speakerPosition.MIDDLE:
		match speakerCount:
			3:
				for speakerMoveIndex in speakerList:
					if (speakerMoveIndex[1] == speakerInternalPosition.MIDDLE_LEFT) and speakerInternalIndex != speakerListIndex:
						moveSpeaker(speakerListIndex, speakerInternalPosition.LEFT, setMovingEdgeCase)
					elif (speakerMoveIndex[1] == speakerInternalPosition.MIDDLE_RIGHT) and speakerInternalIndex != speakerListIndex:
						moveSpeaker(speakerListIndex, speakerInternalPosition.RIGHT, setMovingEdgeCase)
					speakerListIndex += 1
				speakerFinalPosition = speakerInternalPosition.MIDDLE
			2:
				for speakerMoveIndex in speakerList:
					if speakerMoveIndex != null and speakerInternalIndex != speakerListIndex:
						if setEnterMode.to_upper() == "LEFT":
							moveSpeaker(speakerListIndex, speakerInternalPosition.MIDDLE_RIGHT, setMovingEdgeCase)
							speakerFinalPosition = speakerInternalPosition.MIDDLE_LEFT
						else:
							moveSpeaker(speakerListIndex, speakerInternalPosition.MIDDLE_LEFT, setMovingEdgeCase)
							speakerFinalPosition = speakerInternalPosition.MIDDLE_RIGHT
					speakerListIndex += 1
	elif setPosition == speakerPosition.RIGHT:
		match speakerCount:
			3:
				for speakerMoveIndex in speakerList:
					if (speakerMoveIndex[1] == speakerInternalPosition.MIDDLE_LEFT) and speakerInternalIndex != speakerListIndex:
						moveSpeaker(speakerListIndex, speakerInternalPosition.LEFT, setMovingEdgeCase)
					elif (speakerMoveIndex[1] == speakerInternalPosition.MIDDLE_RIGHT) and speakerInternalIndex != speakerListIndex:
						moveSpeaker(speakerListIndex, speakerInternalPosition.MIDDLE, setMovingEdgeCase)
					speakerListIndex += 1
				speakerFinalPosition = speakerInternalPosition.RIGHT
			2:
				for speakerMoveIndex in speakerList:
					if speakerMoveIndex != null and speakerInternalIndex != speakerListIndex:
						moveSpeaker(speakerListIndex, speakerInternalPosition.MIDDLE_LEFT, setMovingEdgeCase)
					speakerListIndex += 1
				speakerFinalPosition = speakerInternalPosition.MIDDLE_RIGHT
	speakerList[speakerInternalIndex][1] = speakerFinalPosition
	
	# All movement only happens if there is no edge case occuring.
	if setMovingEdgeCase == false:
		# And finally, set our delay.
		# This tween is blank on purpose in order to set a delay.
		# Also account for edge case.
		if afterMovingEdgeCase == false and speakerCount > 1:
			tween.tween_interval(40.0/60.0)
		elif afterMovingEdgeCase == true:
			# Check if the speaker stays where they are.
			# If they do, then no delay is done.
			# TODO: Fix an edge case that happens here.
			# At this point, I may just have to pass fixing this onto another programmer...
			# If you're a programmer who wants to fix this, here's what you need to know.
			# Say Tails is the only speaker on the board. Knuckles and Sonic are about to enter,
			# both at time same time (Knuckles has delay off, you see.)
			# If Knuckles enters to the left and Sonic enters to the right,
			# leaving Tails still in the middle, then there should be no delay between the characters moving.
			# Else, if Knuckles and Sonic were to enter to either the right or left,
			# making Tails get pushed to the left or right respectively,
			# then Tails should get pushed first, followed by the delay of (40.0/60.0),
			# then have the two other characters join at the same time.
			# Thank you - you're saving a load off my back!
			var speakerStaying = false
			for speakerValue in speakerList.size():
				print(edgeCaseStoredPosition)
				if edgeCaseStoredPosition == speakerList[speakerValue]:
					speakerStaying = true
					break
			if speakerStaying == false:
				tween.tween_interval(40.0/60.0)
	
		# Set where our speaker initially is depending on our mode, and where they're going.
		if (setEnterMode is int and setEnterMode == speakerEnterMode.LEFT) or (setEnterMode is String and setEnterMode.to_upper() == "LEFT"):
			speaker.position.x = -96
			# Set trans and easing, then execute the animation.
			tween.set_trans(Tween.TRANS_EXPO)
			tween.set_ease(Tween.EASE_OUT)
			tween.tween_property(speaker, "position:x", speakerFinalPosition, 40.0/60.0)
		elif (setEnterMode is int and setEnterMode == speakerEnterMode.RIGHT) or (setEnterMode is String and setEnterMode.to_upper() == "RIGHT"):
			speaker.position.x = 240
			# Set trans and easing, then execute the animation.
			tween.set_trans(Tween.TRANS_EXPO)
			tween.set_ease(Tween.EASE_OUT)
			tween.tween_property(speaker, "position:x", speakerFinalPosition, 40.0/60.0)
		elif (setEnterMode is int and setEnterMode == speakerEnterMode.FADE) or (setEnterMode is String and setEnterMode.to_upper() == "FADE"):
			speaker.modulate = Color("ffffff00")
			tween.tween_property(speaker, "position:x", speakerFinalPosition, 0)
			tween.tween_property(speaker, "modulate", Color("ffffffff"), 40.0/60.0)
		else:
			tween.tween_property(speaker, "position:x", speakerFinalPosition, 0)
		
		tween.tween_callback(changeAnimationPlaying)
		
	else:
		# Set our edge cases for two Speakers at once.
		if setMovingEdgeCase == true:
			afterMovingEdgeCase = true
		elif setMovingEdgeCase == false and setAfterMovingEdgeCase == true:
			afterMovingEdgeCase = false
	
	# Finally, let the program know it's ready to move on!
	# We have to define it on a delay depending on if there's delay or not.
	if setDelay == false:
		setUpDialogue()
	else:
		tween.tween_callback(setUpDialogue)
	
# Dedicated function to change this value to false.
# For tweens to do this after they end... why...?
func changeAnimationPlaying():
	animationPlaying = false

# Changes the speaker's location on the grid.
# Not intended for general coder use.
func moveSpeaker(setIndex: int, setPosition: int, setMovingEdgeCase: bool = false):
	# Match the speaker with our node.
	var speaker
	match setIndex:
		0:
			speaker = speaker1
		1:
			speaker = speaker2
		_:
			speaker = speaker3
	
	# Create and move our tween if we have no edge case.
	if setMovingEdgeCase == false:
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
