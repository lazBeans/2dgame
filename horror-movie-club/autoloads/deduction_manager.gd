## PURPOSE: Manages sequence-based puzzle completion routines and coordinates 
## chained dialogue events between clue resolutions and chapter deductions.
extends Control

# ==========================================
# NODE REFERENCES
# ==========================================

## Parent control container holding choice option selection buttons.
@onready var option_container: Control = $OptionContainer

## First choice selection button.
@onready var option_a_button: Button = $OptionContainer/OptionAButton

## Second choice selection button.
@onready var option_b_button: Button = $OptionContainer/OptionBButton

# ==========================================
# GAMEPLAY & ATTEMPT STATE
# ==========================================

## Identifier string of the active chapter retrieved from GameManager.
var current_ch: String = GameManager.current_chapter

## Total remaining retry attempts allowed for the master deduction sequence.
var deduction_chances: int = 3

## Counter tracking incorrect choices selected during the current deduction run.
var wrong_count: int = 0

# ==========================================
# EVIDENCE & CLUE DATA QUEUES
# ==========================================

## Dictionary mapping clue keys to correct/wrong segment resource file paths.
var master_evidences: Dictionary = {}

## Queue of remaining clue keys to evaluate for the current chapter sequence.
var master_clues: Array = []

## Identifier string of the clue currently actively presented to the player.
var current_clue: String = ""


# ==========================================
# INITIALIZATION & CORE LOOP
# ==========================================

## Connects UI button signals with self-binding, hides node visibility, and starts deduction setup.
func _ready() -> void:
	visible = false
	option_a_button.pressed.connect(_on_button_pressed.bind(option_a_button))
	option_b_button.pressed.connect(_on_button_pressed.bind(option_b_button))
	
	initiate_deduction()

## Resets tracking state, loads required chapter segment data from FileManager, 
## populates the clue queue, and starts the clue evaluation loop.
func initiate_deduction() -> void:
	if wrong_count > 0:
		wrong_count = 0
		
	master_evidences = FileManager.load_required_segments(current_ch)
	
	if not master_evidences.is_empty():
		master_clues = master_evidences.keys()
		
	deduction_loop()

## Pops the next clue key from the queue, converts choice file paths into a typed 
## Array[String], shuffles their presentation order, and forwards paths for loading.
func deduction_loop() -> void:
	current_clue = master_clues.pop_front()
	var current_clue_options: Dictionary = master_evidences.get(current_clue)
	
	var current_clue_options_paths: Array[String] = []
	current_clue_options_paths.assign(current_clue_options.values())
	current_clue_options_paths.shuffle()
	
	get_options(current_clue_options_paths)

## Loads SegmentData resource instances from the given file paths and triggers UI option setup.
func get_options(paths: Array[String]) -> void:
	var data_a: SegmentData = load(paths[0]) as SegmentData
	var data_b: SegmentData = load(paths[1]) as SegmentData
		
	setup_options(data_a, data_b)


# ==========================================
# BUTTON & SELECTION HANDLING
# ==========================================

## Binds descriptions and metadata IDs from SegmentData resources to buttons and displays the UI container.
func setup_options(option_a_resource: SegmentData, option_b_resource: SegmentData) -> void:
	option_a_button.text = option_a_resource.description
	option_a_button.set_meta("resource_id", option_a_resource.id)
	
	option_b_button.text = option_b_resource.description
	option_b_button.set_meta("resource_id", option_b_resource.id)
	
	option_container.show()

## Evaluates button input metadata, increments wrong count for incorrect picks, hides choice UI, 
## and advances the queue or evaluates final sequence success, retry, or game-over routing.
func _on_button_pressed(selected_option: Button) -> void:
	var selected_id: String = selected_option.get_meta("resource_id")
	
	if selected_id.ends_with("wrong"):
		wrong_count += 1
	
	option_container.hide()
	
	if not master_clues.is_empty():
		deduction_loop()
	else:
		if wrong_count == 0 and deduction_chances > 0:
			visible = false
			
			var dialogic_timeline: String = current_ch + "_culprits"
			Dialogic.start(dialogic_timeline)
			
		elif wrong_count > 0 and deduction_chances > 0:
			deduction_chances -= 1
			
			if deduction_chances > 0:
				Dialogic.start("try_again")
				master_clues.clear()
				initiate_deduction()
			else:
				Dialogic.start("game_over")
