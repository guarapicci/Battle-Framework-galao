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

# Y'know what? Let's also have signals for our YES/NO options.
signal dialogue_pick_yes
signal dialogue_pick_no

# Labels for text.
@onready var textLabel = $CanvasLayer/TextMask/Text
@onready var textLabelFiller = $CanvasLayer/TextFiller
@onready var animationTextbox = $AnimationPlayerTextbox
@onready var animationShade = $AnimationPlayerShade

# Labels for buttons.
@onready var buttonYes = $CanvasLayerForeground/ButtonYes
@onready var buttonNo = $CanvasLayerForeground/ButtonNo
@onready var animationButtonYes = $CanvasLayerForeground/ButtonYes/AnimationPlayer
@onready var animationButtonNo = $CanvasLayerForeground/ButtonNo/AnimationPlayer

# Sound banks.
@onready var soundBankTalk = $AudioStreamTalk
@onready var soundBankExtra = $AudioStreamExtra

# Labels for fadeouts.
@onready var whiteForeground = $CanvasLayerForeground/WhiteForeground
@onready var blackForeground = $CanvasLayerForeground/BlackForeground
@onready var whiteBackground = $CanvasLayerBackground/WhiteBackground
@onready var blackBackground = $CanvasLayerBackground/BlackBackground

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
var continueAmount: int = 0 ## How much times will the user have to manually continue the current strip of dialogue?
var continueOption = false ## Can the player continue the current text?
var continueLinesLeft: int = 2 ## How much lines are left before the text waits to continue?
var choosing = false ## Is the player currently picking an option?
var chooseOption = 1 ## What choice is the player hovering over? 0 is NO, 1 is YES.
var nextTextbox = 0 ## What's the next jagged-type textbox that will be on display?

# THINGS THAT CAN BE EDITED DIRECTLY AFTER INSTANTIATION
var backgroundShade = true ## Will the black background shade take effect? Can be modified before adding.

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
@onready var dialoguePointer = $CanvasLayer/DialoguePointer
@onready var continueIndicator = $CanvasLayer/ContinueIndicator
@onready var continueAnimation = $CanvasLayer/ContinueIndicator/AnimationPlayer

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
	defineSpeaker("Sonic", "res://characters/sonic/sprites/SonicDialoguePortraits.png", ["Standard", "Thumbs Up", "Confused", "Determined"], "res://assets/audio/sfx/Dialogue/DialogueRegular.wav")
	defineSpeaker("Tails", "res://characters/tails/sprites/TailsDialoguePortraits.png", ["Standard", "Worried", "Determined"], "res://assets/audio/sfx/Dialogue/DialogueRegular.wav")
	defineSpeaker("Knuckles", "res://characters/knuckles/sprites/KnucklesDialoguePortraits.png", ["Standard", "Concerned", "Determined"], "res://assets/audio/sfx/Dialogue/DialogueLowPitch.wav")
	defineSpeaker("Shadow", "res://characters/shadow/sprites/ShadowDialoguePortraits.png", ["Standard", "Intrigued", "Determined"], "res://assets/audio/sfx/Dialogue/DialogueLowPitch.wav")
	defineSpeaker("Rouge", "res://characters/rouge/sprites/RougeDialoguePortraits.png", ["Standard", "Disgusted"], "res://assets/audio/sfx/Dialogue/DialogueHighPitch.wav")
	defineSpeaker("Amy", "res://characters/amy/sprites/AmyDialoguePortraits.png", ["Standard", "Angry", "Happy", "Concerned"], "res://assets/audio/sfx/Dialogue/DialogueHighPitch.wav")
	defineSpeaker("Cream", "res://characters/cream/sprites/CreamDialoguePortraits.png", ["Standard", "Sad", "Excited"], "res://assets/audio/sfx/Dialogue/DialogueHighPitch.wav")
	defineSpeaker("Chaos Gamma", "res://characters/chaos_gamma/sprites/ChaosGammaDialoguePortraits.png", ["Standard", "Identifying", "Standard (Guard Robo)"], "res://assets/audio/sfx/Dialogue/DialogueLowPitch.wav")
	defineSpeaker("Chaos", "res://characters/chaos/sprites/ChaosDialoguePortraits.png", ["Standard"], "res://assets/audio/sfx/Dialogue/DialogueLowPitch.wav")
	defineSpeaker("Emerl", "res://characters/emerl/sprites/EmerlDialoguePortraits.png", ["Standard", "Intrigued", "Powering Up", "Awakened", "Intrigued (Phi)"], "res://assets/audio/sfx/Dialogue/DialogueRegular.wav")
	defineSpeaker("Eggman", "res://characters/eggman/sprites/EggmanDialoguePortraits.png", ["Standard", "Angry"], "res://assets/audio/sfx/Dialogue/DialogueRegular.wav")
	# NOTICE: Feel free to add your own speakers under this if you want to!
	
	# test, delete once over with
	addSpeaker(["Amy", 0, "Left", "Left", "Right"], ["Emerl", 0, "Right", "Right", "Left"])
	changeSpeaker("Amy", "Concerned", "Right")
	# TODO: fix changeSpeaker poses grabbing based on current index instead of master index
	addDialogue("That's not... the... ThornRing,\nis it...?", "Amy")
	addOption()
	addDialogue("It snew", "Emerl")
	changeSpeaker("Amy", 2, "Right")
	addDialogue("what", "Amy")
	addDialogue("what do you mean", "Amy")
	addDialogue("I'm listening.")

func _ready():
	if backgroundShade == true:
		animationShade.play("Initial")
	
	# Set the initial box style.
	for dialogueValue in dialogueList.size():
		if dialogueList[dialogueValue][0] == "Dialogue":
			if dialogueList[dialogueValue][1].speaker == "":
				dialogueBox.texture.region.position.y = 48 * 3
			else:
				dialogueBox.texture.region.position.y = 48 * nextTextbox
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
			# Prints the first letter into filler box in case of line overflow
			var formerLineCount: int = textLabelFiller.get_line_count()
			var continuing = false
			textLabelFiller.text += currentDialogue.left(1)
			if textLabelFiller.get_line_count() > formerLineCount:
				continueLinesLeft -= 1
				continuing = true
			if continueLinesLeft == 0:
				continueOption = true
			
			if continueOption == true:
				continueIndicator.visible = true
				continueAnimation.play("Default")
			elif continuing == true and textLabel.get_line_count() > 1:
				# Hide our continue indicator
				continueIndicator.visible = false
				continueAnimation.play("RESET")
				# Move our line and pring a new line onto the existing one.
				continuing = false
				animationPlaying = true
				var tween = create_tween()
				tween.tween_property(textLabel, "position:y", textLabel.position.y - 16, 9.0/60.0)
				# I don't know why the following line is required to not break stuff, but it is!
				tween.tween_property(textLabel, "position:y", textLabel.position.y + 0, 0)
				tween.tween_property(textLabel, "text", textLabel.text + currentDialogue.left(1), 0)
				tween.tween_callback(changeAnimationPlaying)
				currentDialogue = currentDialogue.erase(0)
				delayTimer = 9.0/60.0
			else:
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
	
	if choosing == true:
		if Input.is_action_just_pressed("left1") and chooseOption == 0:
			chooseOption = 1
			soundBankExtra.stream = load("res://assets/audio/sfx/Dialogue/DialoguePick.wav")
			soundBankExtra.play()
		elif Input.is_action_just_pressed("right1") and chooseOption == 1:
			chooseOption = 0
			soundBankExtra.stream = load("res://assets/audio/sfx/Dialogue/DialoguePick.wav")
			soundBankExtra.play()
		
		if chooseOption == 0:
			animationButtonYes.play("Default")
			animationButtonNo.play("Selected")
		else:
			animationButtonYes.play("Selected")
			animationButtonNo.play("Default")
	
	# Speed up the textbox, advance it, or delete it.
	if Input.is_action_just_pressed("attack1"):
		if confirmOption == true:
			confirmOption = false
			setUpDialogue()
		elif continueOption == true:
			continueOption = false
			
			# We have to increase this by 1 line because
			# one of them will instantly be deleted upon continuation.
			continueLinesLeft = 3
		elif choosing == true:
			# Play our sound.
			soundBankExtra.stream = load("res://assets/audio/sfx/Dialogue/DialogueSelect.wav")
			soundBankExtra.play()
			
			# Get our options outta there!
			choosing = false
			var tween = create_tween()
			# Set our ease and transition types.
			tween.set_ease(Tween.EASE_OUT)
			tween.set_trans(Tween.TRANS_EXPO)
	
			tween.tween_property(buttonYes, "position:x", -32, 20.0/60.0)
			tween.parallel().tween_property(buttonNo, "position:x", -32, 20.0/60.0)
			# Emit our signal, change animation playing status, and call our next dialogue input.
			tween.tween_callback(emitChoosingSignal)
			tween.tween_callback(changeAnimationPlaying)
			tween.tween_callback(setUpDialogue)
		else:
			# Speed up the text.
			if dialogueList[0][0] == "Dialogue" and animationPlaying == false:
				goingFast = true

## Emits a signal for the option picked.
func emitChoosingSignal():
	if chooseOption == 1:
		dialogue_pick_yes.emit()
	else:
		dialogue_pick_no.emit()

func setUpDialogue():
	# Remove the last used object if we just started.
	if justStarted == true:
		justStarted = false
	else:
		dialogueList.remove_at(0)
	# Remove speed-up mode and the pointer.
	goingFast = false
	dialoguePointer.position.x = -32
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
			# Reset our box position.
			textLabel.position.y = 7
			# Set our filler text.
			textLabelFiller.text = dialogueList[0][1].dialogue
			# Reset our lines left for dialouge continuation.
			continueLinesLeft = 2
			# Reset filler text.
			textLabelFiller.text = ""
			# Set the textbox style and dialogue.
			if dialogueList[0][1].speaker == "":
				dialogueBox.texture.region.position.y = 48 * 3
			else:
				dialogueBox.texture.region.position.y = 48 * nextTextbox
				if nextTextbox >= 2:
					nextTextbox = 0
				else:
					nextTextbox += 1
			currentDialogue = dialogueList[0][1].dialogue
			# Reset our talk sound.
			talkSound = "res://assets/audio/sfx/Dialogue/DialogueRegular.wav"
			if dialogueList[0][1].speaker:
				animationPlaying = true
				delayTimer = 22.0/60.0
				
				# Have the pointer flip depending on speaker direction,
				# and have it find the speaker and track pointer's position based on speaker position.
				# Set animation tweens for pointer, and disable animationPlaying after!
				
				# First, check if our speaker exists.
				var speakerIndex
				for speakerValue in speakerList.size():
					if speakerList[speakerValue][0] == dialogueList[0][1].speaker:
						speakerIndex = speakerValue
						break
				if speakerIndex == null:
					print("There's no character with name " + dialogueList[0][1].speaker + "!")
					return
				
				# Set which speaker we're referencing.
				var speaker
				match speakerIndex:
					0:
						speaker = speaker1
					1:
						speaker = speaker2
					_:
						speaker = speaker3
				
				# Get the speaker's references.
				var startingPosition = speaker.position.x
				var endingPosition = speaker.position.x
				
				# Set up our speaker pointer.
				if speaker.flip_h == true:
					startingPosition += 27
					endingPosition += 7
					dialoguePointer.flip_h = true
				else:
					startingPosition += 37
					endingPosition += 57
					dialoguePointer.flip_h = false
				
				# Animate our speaker pointer.
				dialoguePointer.position.x = startingPosition
				var tween = create_tween()
				tween.set_ease(Tween.EASE_OUT)
				tween.set_trans(Tween.TRANS_EXPO)
				tween.tween_property(dialoguePointer, "position:x", endingPosition, (22.0/60.0))
				tween.tween_callback(changeAnimationPlaying)
				
				# Switch our talk sound.
				var speakerMasterIndex
				for speakerValue in speakerMasterList.size():
					if speakerMasterList[speakerValue].name == dialogueList[0][1].speaker:
						speakerMasterIndex = speakerValue
						break
				if speakerMasterIndex == null:
					print("There's no character with name " + dialogueList[0][1] + "in the defined list of speakers!")
					return
				
				talkSound = speakerMasterList[speakerMasterIndex].sound
		
			soundBankTalk.stream = load(talkSound)
		elif dialogueList[0][0] == "addSpeaker":
			addSpeakerDefinition(dialogueList[0][1], dialogueList[0][2], dialogueList[0][3])
		elif dialogueList[0][0] == "changeSpeaker":
			changeSpeakerDefinition(dialogueList[0][1], dialogueList[0][2], dialogueList[0][3])
		elif dialogueList[0][0] == "removeSpeaker":
			removeSpeakerDefinition(dialogueList[0][1], dialogueList[0][2], dialogueList[0][3])
		elif dialogueList[0][0] == "toggleFade":
			toggleFadeDefinition(dialogueList[0][1], dialogueList[0][2])
		elif dialogueList[0][0] == "addOption":
			addOptionDefinition()
	

# Adds a DialogueEntry class that stores all the info of a single piece of dialogue
class DialogueEntry:
	# Our info
	var dialogue: String = ""
	var speaker: String = ""
	
	# Parameterized constructor
	func _init(setDialogue: String = "", setSpeaker: String = ""):
		dialogue = setDialogue
		speaker = setSpeaker

# Adds new dialogue to the queue using the class
func addDialogue(setDialogue: String, setSpeaker: String = ""):
	# Instantiate a class
	var dialogue = DialogueEntry.new(setDialogue, setSpeaker)
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
## This function is used to define a Speaker for the global list.
## If you want to do this, it's recommended to do it in the main dialogue file itself![br]
## [br]
## [b]setName[/b]: The name of the speaker you want to define.[br]
## [b]setPoseTexture[/b]: The image file of the pose textures you want.
## Each pose must be in a resolution of 96x96, and should be in one file, reading poses from left to right.[br]
## [b]setPoses[/b]: The names of each individual pose. Make sure you name them all![br]
## [b]setSound[/b]: The audio blip you want to play whenever the speaker is speaking.
func defineSpeaker(setName: String, setPoseTexture: String, setPoses: Array = ["Standard"], setSound: String = "res://assets/audio/sfx/Dialogue/DialogueRegular.wav"):
	var speaker = DialogueSpeaker.new(setName, setPoseTexture, setPoses, setSound)
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
	if animationPlaying == true:
		animationPlaying = false
	else:
		animationPlaying = true

# Changes the speaker's location on the grid.
# Not intended for general coder use.
func moveSpeaker(setIndex: int, setPosition: int, setDelay: bool = false):
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
		# Set a delay to account for removing speakers
		if setDelay == true:
			tween.tween_interval(40.0/60.0)
		tween.tween_property(speaker, "position:x", setPosition, 40.0/60.0)
	
		# Finally, save our position into memory.
		speakerList[setIndex][1] = setPosition
	
func changeSpeaker(setName: String, setPose = -1, setDirection = -1):
	dialogueList.append(["changeSpeaker", setName, setPose, setDirection])

# Changes the speaker's pose and/or direction.
func changeSpeakerDefinition(setName: String, setPose = -1, setDirection = -1):
	animationPlaying = true
	
	# First, check if our speaker exists in our current scene.
	var speakerIndex
	for speakerValue in speakerList.size():
		if speakerList[speakerValue][0] == setName:
			speakerIndex = speakerValue
			break
	if speakerIndex == null:
		print("There's no character with name " + setName + "!")
		return
	
	# Next, check where the index is in our Master List for poses.
	# Chances are that we don't need the error check here, but it's still nice
	# to have just in case.
	var speakerPoseIndex
	for speakerValue in speakerMasterList.size():
		if speakerMasterList[speakerValue].name == setName:
			speakerPoseIndex = speakerValue
			break
	if speakerPoseIndex == null:
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
		for speakerPose in speakerMasterList[speakerPoseIndex].poses.size():
			# ...if the speaker pose name matches up with our given parameter...
			if speakerMasterList[speakerPoseIndex].poses[speakerPose] == setPose:
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
	tween.tween_callback(setUpDialogue)

## This function is used to remove a Speaker from the current dialogue list.
## It uses up to 3 arrays as parameters, each with their own sub-parameters.
## In order, they are...[br]
## [br]
## [b]setName[/b]: The name of the speaker you wnt to exit.
## [b]setExitMode[/b]: How you want the speaker to exit.
## You can set this to be "Left" (exits to the left), "Right" (comes in from the right),
## or "Fade" (fades out of the frame).
func removeSpeaker(storedSpeaker1: Array, storedSpeaker2: Array = [], storedSpeaker3: Array = []):
	dialogueList.append(["removeSpeaker", storedSpeaker1, storedSpeaker2, storedSpeaker3])

## Removes a Speaker from the current scene.[br]
## [b]Not intended for coder use.[/b]
func removeSpeakerDefinition(storedSpeaker1: Array, storedSpeaker2: Array = [], storedSpeaker3: Array = []):
	# NOTICE: There could probably be a way to optimize this for all three Speakers
	# instead of having to repeat the same code three times. Optimizations are welcome,
	# but not required.
	
	# REFERENCE:
	# [0]: setName
	# [1]: setExitMode
	var setName1 = storedSpeaker1[0]
	var setExitMode1 = storedSpeaker1[1]
	
	var setName2
	var setExitMode2
	
	if storedSpeaker2 != []:
		setName2 = storedSpeaker2[0]
		setExitMode2 = storedSpeaker2[1]
	
	var setName3
	var setExitMode3
	
	if storedSpeaker3 != []:
		setName3 = storedSpeaker3[0]
		setExitMode3 = storedSpeaker3[1]
	
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
	for speakerValue in speakerList.size():
		if speakerList[speakerValue][0] == setName1:
			speakerIndex1 = speakerValue
			break
	if speakerIndex1 == null:
		print("There's no character with name " + setName1 + "!")
		return
	
	var speakerIndex2
	if speakersAdded >= 3:
		for speakerValue in speakerList.size():
			if speakerList[speakerValue][0] == setName2:
				speakerIndex2 = speakerValue
				break
		if speakerIndex2 == null:
			print("There's no character with name " + setName2 + "!")
			return
	
	var speakerIndex3
	if speakersAdded == 3:
		for speakerValue in speakerList.size():
			if speakerList[speakerValue][0] == setName3:
				speakerIndex3 = speakerValue
				break
		if speakerIndex3 == null:
			print("There's no character with name " + setName3 + "!")
			return
	
	# Variable where our texture'll be stored
	var removedSpeaker1 = null
	var removedSpeaker2 = null
	var removedSpeaker3 = null
	# Variable for our tween
	var tween = create_tween()
	
	# Error handling
	var currentSpeakerStorage = 0
	for currentSpeaker in speakerList:
		if currentSpeaker != null:
			currentSpeakerStorage += 1
	
	if storedSpeaker3 != []:
		currentSpeakerStorage -= 3
	elif storedSpeaker2 != []:
		currentSpeakerStorage -= 2
	else:
		currentSpeakerStorage -= 1
	
	if currentSpeakerStorage < 0:
		print("Cannot remove any more characters!")
		return
	
	# Removes our speakers from current memory.
	if speakerList[0] != null:
		if setName1 == speakerList[0][0] and removedSpeaker1 == null:
			removedSpeaker1 = speaker1
			speakerList[0] = null
		elif setName2 == speakerList[0][0] and storedSpeaker2 != [] and removedSpeaker2 == null:
			removedSpeaker2 = speaker1
			speakerList[0] = null
		elif setName3 == speakerList[0][0] and storedSpeaker3 != [] and removedSpeaker3 == null:
			removedSpeaker3 = speaker1
			speakerList[0] = null
	if speakerList[1] != null:
		if setName1 == speakerList[1][0] and removedSpeaker1 == null:
			removedSpeaker1 = speaker2
			speakerList[1] = null
		elif setName2 == speakerList[1][0] and storedSpeaker2 != [] and removedSpeaker2 == null:
			removedSpeaker2 = speaker2
			speakerList[1] = null
		elif setName3 == speakerList[1][0] and storedSpeaker3 != [] and removedSpeaker3 == null:
			removedSpeaker3 = speaker2
			speakerList[1] = null
	if speakerList[2] != null:
		if setName1 == speakerList[2][0] and removedSpeaker1 == null:
			removedSpeaker1 = speaker3
			speakerList[2] = null
		elif setName2 == speakerList[2][0] and storedSpeaker2 != [] and removedSpeaker2 == null:
			removedSpeaker2 = speaker3
			speakerList[2] = null
		elif setName3 == speakerList[2][0] and storedSpeaker3 != [] and removedSpeaker3 == null:
			removedSpeaker3 = speaker3
			speakerList[2] = null
			
	var speaker1Fading = false
	var speaker2Fading = false
	var speaker3Fading = false
	
	# Set our animations for our speakers depending on our mode.
	if (setExitMode1 is int and setExitMode1 == speakerExitMode.LEFT) or (setExitMode1 is String and setExitMode1.to_upper() == "LEFT"):
		# Set trans and easing, then execute the animation.
		tween.set_trans(Tween.TRANS_EXPO)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(removedSpeaker1, "position:x", -96, 40.0/60.0)
	elif (setExitMode1 is int and setExitMode1 == speakerExitMode.RIGHT) or (setExitMode1 is String and setExitMode1.to_upper() == "RIGHT"):
		tween.set_trans(Tween.TRANS_EXPO)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(removedSpeaker1, "position:x", 240, 40.0/60.0)
	elif (setExitMode1 is int and setExitMode1 == speakerExitMode.FADE) or (setExitMode1 is String and setExitMode1.to_upper() == "FADE"):
		speaker1Fading = true
	else:
		tween.tween_property(removedSpeaker1, "position:x", -96, 0)
	
	if storedSpeaker2 != []:
		tween.set_parallel(true)
		if (setExitMode2 is int and setExitMode2 == speakerExitMode.LEFT) or (setExitMode2 is String and setExitMode2.to_upper() == "LEFT"):
			# Set trans and easing, then execute the animation.
			tween.set_trans(Tween.TRANS_EXPO)
			tween.set_ease(Tween.EASE_OUT)
			tween.tween_property(removedSpeaker2, "position:x", -96, 40.0/60.0)
		elif (setExitMode2 is int and setExitMode2 == speakerExitMode.RIGHT) or (setExitMode2 is String and setExitMode2.to_upper() == "RIGHT"):
			tween.set_trans(Tween.TRANS_EXPO)
			tween.set_ease(Tween.EASE_OUT)
			tween.tween_property(removedSpeaker2, "position:x", 240, 40.0/60.0)
		elif (setExitMode2 is int and setExitMode2 == speakerExitMode.FADE) or (setExitMode2 is String and setExitMode2.to_upper() == "FADE"):
			speaker2Fading = true
		else:
			tween.tween_property(removedSpeaker2, "position:x", -96, 0)
	
	if storedSpeaker3 != []:
		if (setExitMode3 is int and setExitMode3 == speakerExitMode.LEFT) or (setExitMode3 is String and setExitMode3.to_upper() == "LEFT"):
			# Set trans and easing, then execute the animation.
			tween.set_trans(Tween.TRANS_EXPO)
			tween.set_ease(Tween.EASE_OUT)
			tween.tween_property(removedSpeaker3, "position:x", -96, 40.0/60.0)
		elif (setExitMode3 is int and setExitMode3 == speakerExitMode.RIGHT) or (setExitMode3 is String and setExitMode3.to_upper() == "RIGHT"):
			tween.set_trans(Tween.TRANS_EXPO)
			tween.set_ease(Tween.EASE_OUT)
			tween.tween_property(removedSpeaker3, "position:x", 240, 40.0/60.0)
		elif (setExitMode3 is int and setExitMode3 == speakerExitMode.FADE) or (setExitMode3 is String and setExitMode3.to_upper() == "FADE"):
			speaker3Fading = true
		else:
			tween.tween_property(removedSpeaker3, "position:x", -96, 0)
	
	# Set fades as last priority
	if speaker1Fading == true:
		tween.set_trans(Tween.TRANS_LINEAR)
		tween.tween_property(removedSpeaker1, "modulate", Color("000000ff"), 40.0/60.0)
	if speaker2Fading == true:
		tween.set_trans(Tween.TRANS_LINEAR)
		tween.tween_property(removedSpeaker2, "modulate", Color("000000ff"), 40.0/60.0)
	if speaker3Fading == true:
		tween.set_trans(Tween.TRANS_LINEAR)
		tween.tween_property(removedSpeaker3, "modulate", Color("000000ff"), 40.0/60.0)
		
	tween.set_parallel(false)
	
	if speaker1Fading == true:
		tween.tween_property(removedSpeaker1, "position:x", -96, 0)
		tween.tween_property(removedSpeaker1, "modulate", Color("ffffffff"), 0)
	if speaker2Fading == true:
		tween.tween_property(removedSpeaker2, "position:x", -96, 0)
		tween.tween_property(removedSpeaker2, "modulate", Color("ffffffff"), 0)
	if speaker3Fading == true:
		tween.tween_property(removedSpeaker3, "position:x", -96, 0)
		tween.tween_property(removedSpeaker3, "modulate", Color("ffffffff"), 0)
	
	# So first, we have to count how much speakers there are in the first place.
	var speakerCount: int = 0
	for speakerCountIndex in speakerList:
		if speakerCountIndex != null:
			speakerCount += 1
	
	# Set the speaker we want to move.
	var speakerListIndex = 0
	
	# Edge case for the middle speaker to move according to where the rightmost or leftmost speaker moves.
	var toLeft = false
	var toRight = false
	var middleIndex
	
	if speakerCount == 2:
		# One speaker on left, one speaker on right
		for speakerMoveIndex in speakerList:
			if speakerMoveIndex != null:
				if speakerList[speakerListIndex][1] == speakerInternalPosition.LEFT:
					moveSpeaker(speakerListIndex, speakerInternalPosition.MIDDLE_LEFT, true)
					toRight = true
				elif speakerList[speakerListIndex][1] == speakerInternalPosition.RIGHT:
					moveSpeaker(speakerListIndex, speakerInternalPosition.MIDDLE_RIGHT, true)
					toLeft = true
				elif speakerList[speakerListIndex][1] == speakerInternalPosition.MIDDLE:
					middleIndex = speakerListIndex
				
				if middleIndex and toRight == true:
					moveSpeaker(middleIndex, speakerInternalPosition.MIDDLE_RIGHT, true)
					middleIndex = null
				elif middleIndex and toLeft == true:
					moveSpeaker(middleIndex, speakerInternalPosition.MIDDLE_LEFT,true)
					middleIndex = null
				
			speakerListIndex += 1
	elif speakerCount == 1:
		# One speaker on middle
		for speakerMoveIndex in speakerList:
			if speakerMoveIndex != null:
				moveSpeaker(speakerListIndex, speakerInternalPosition.MIDDLE, true)
			speakerListIndex += 1
	elif speakerCount == 0:
		noDelay = true
	
	# Set our delay, assuming our speakers don't just stay where they are.
	if noDelay == false:
		tween.tween_interval(40.0/60.0)
	
	tween.tween_callback(changeAnimationPlaying)
	noDelay = false
	
	# Finally, let the program know it's ready to move on!
	tween.tween_callback(setUpDialogue)

## This adds a YES/NO option to your dialogue.
func addOption():
	dialogueList.append(["addOption"])

func addOptionDefinition():
	animationPlaying = true
	
	var tween = create_tween()
	# Set our ease and transition types.
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_EXPO)
	
	tween.tween_property(buttonYes, "position:x", 72, 30.0/60.0)
	tween.parallel().tween_property(buttonNo, "position:x", 136, 30.0/60.0)
	tween.tween_callback(changeChoosing)
	chooseOption = 1

## Sets choosing to the opposite value of what it currently is.[br]
## [b]Not intended for coder use.[/b]
func changeChoosing():
	if choosing == false:
		choosing = true
	else:
		choosing = false
		
func toggleFade(fadeColor = "Black", fadeType = 0):
	# Convert our fade colors to values.
	if fadeColor is String:
		if fadeColor.to_upper() == "WHITE":
			fadeColor = 1
		else:
			fadeColor = 0
	
	if fadeType is String:
		if fadeColor.to_upper() == "FOREGROUND":
			fadeType = 1
		else:
			fadeType = 0
	
	# Append this to our dialogue list.
	dialogueList.append(["toggleFade", fadeColor, fadeType])

## Toggles what fades are currently on.
func toggleFadeDefinition(fadeColor: int, fadeType: int):
	# Set up our animation.
	animationPlaying = true
	var tween = create_tween()
	
	var fadeNode
	
	# Set which fade we're using.
	if fadeColor == 1 and fadeType == 1:
		fadeNode = whiteForeground
	elif fadeColor == 1 and fadeType == 0:
		fadeNode = whiteBackground
	elif fadeColor == 0 and fadeType == 1:
		fadeNode = blackForeground
	else:
		fadeNode = blackBackground
	
	# Animate our fades!
	match fadeNode.modulate:
		Color(1.0, 1.0, 1.0, 1.0):
			tween.tween_property(fadeNode, "modulate", Color(1.0, 1.0, 1.0, 0.0), 33.0/60.0)
		_:
			tween.tween_property(fadeNode, "modulate", Color(1.0, 1.0, 1.0, 1.0), 33.0/60.0)
	
	tween.tween_callback(changeAnimationPlaying)
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
