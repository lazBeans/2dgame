## PURPOSE: Manages sequence-based puzzle completion routines and coordinates 
## chained dialogue events between clue resolutions and chapter deductions.
extends Control

# ==========================================
# ONREADY & STATE VARIABLES
# ==========================================
@onready var option_container: Control = $OptionContainer

@onready var option_a_button: Button = $OptionContainer/OptionAButton
@onready var option_b_button: Button = $OptionContainer/OptionBButton

## Identifier string of the current chapter loaded from GameManager.
var current_ch: String = GameManager.current_chapter

## Array of required event segment IDs for the current chapter sequence.
var master_evidences: Dictionary = FileManager.load_required_segments(current_ch)
var master_clues: Array = []
var current_clue_options: Dictionary = {}
var current_clue_options_paths: Array = []

var user_choice: Array = []
var current_clue: String = ""

# ==========================================
# INITIALIZATION
# ==========================================

## Fetches board markers, sets up slots, and spawns available event segments.
func _ready() -> void:
	visible = false
	option_a_button.pressed.connect(_on_button_pressed.bind(option_a_button))
	option_b_button.pressed.connect(_on_button_pressed.bind(option_b_button))
	
	if not master_evidences.is_empty():
		master_clues = master_evidences.keys()
		
		deduction_loop()
	
		
func deduction_loop() -> void:
	current_clue = master_clues.pop_front()
	current_clue_options = master_evidences.get(current_clue)
	current_clue_options_paths = current_clue_options.values()
	current_clue_options_paths.shuffle()
	
	get_options()

func get_options() -> void:
	
	if ResourceLoader.exists(current_clue_options_paths[0]) and ResourceLoader.exists( current_clue_options_paths[1]):
		var data_a: Resource = load(current_clue_options_paths[0])
		var data_b: Resource = load(current_clue_options_paths[1])
			
		setup_options(data_a, data_b)
		

# ==========================================
# BUTTON SETUP
# ==========================================
func setup_options(option_a_resource, option_b_resource) -> void:
	
	option_a_button.text = option_a_resource.description
	option_a_button.set_meta("resource_id", option_a_resource.id)
	
	option_b_button.text = option_b_resource.description
	option_b_button.set_meta("resource_id", option_a_resource.id)
	
	option_container.show()
	
func _on_button_pressed(selected_option: Button) -> void:
	var selected_id = selected_option.get_meta("resource_id")
	user_choice.append(selected_id)
	option_container.hide()
	
	if not master_clues.is_empty():
		deduction_loop()
	else:
		visible = false
		Dialogic.start(current_ch, "_culprits")
	
# ==========================================
# PUZZLE COMPLETION FLOW
# ==========================================

## Triggers the final clue timeline and connects listener for chapter deduction dialogue.
func handle_puzzle_completion(final_clue_timeline: String) -> void:
	Dialogic.start(final_clue_timeline)
	
	if not Dialogic.timeline_ended.is_connected(_on_clue_dialogue_finished):
		Dialogic.timeline_ended.connect(_on_clue_dialogue_finished)

## Called when clue dialogue finishes to initiate the chapter's master deduction sequence.
func _on_clue_dialogue_finished() -> void:
	if Dialogic.timeline_ended.is_connected(_on_clue_dialogue_finished):
		Dialogic.timeline_ended.disconnect(_on_clue_dialogue_finished)
		
	var chapter_deduction: String = GameManager.current_chapter + "_deduction"
	Dialogic.start(chapter_deduction)
