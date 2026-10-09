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

var deduction_chances: int = 3

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
	
	initiate_deduction()
	
func initiate_deduction() -> void:
	
	print("Master evidences keys: ", master_evidences.keys())
	print("Master evidences values: ", master_evidences.values())
	
	if not master_evidences.is_empty():
		master_clues = master_evidences.keys()
		for clue in master_clues:	
			print("Master clue: ", clue)
		
	deduction_loop()
	
		
func deduction_loop() -> void:
	current_clue = master_clues.pop_front()
	current_clue_options = master_evidences.get(current_clue)
	print("Clues: ", current_clue_options.keys())
	
	current_clue_options_paths = current_clue_options.values()
	current_clue_options_paths.shuffle()
	
	# print("Option Path Index 0: ", current_clue_options_paths[0])
	# print("Option Path Index 1: ", current_clue_options_paths[1])
	
	get_options()

func get_options() -> void:
	
	if ResourceLoader.exists(current_clue_options_paths[0]) and ResourceLoader.exists( current_clue_options_paths[1]):
		var data_a: Resource = load(current_clue_options_paths[0])
		var data_b: Resource = load(current_clue_options_paths[1])
			
		print("Data a: ", data_a.description)
		print("Data b: ", data_b.description)
		
		setup_options(data_a, data_b)
		

# ==========================================
# BUTTON SETUP
# ==========================================
func setup_options(option_a_resource, option_b_resource) -> void:
	
	option_a_button.text = option_a_resource.description
	option_a_button.set_meta("resource_id", option_a_resource.id)
	print("Option a meta id: ", option_a_button.get_meta("resource_id"))
	
	option_b_button.text = option_b_resource.description
	option_b_button.set_meta("resource_id", option_b_resource.id)
	print("Option b meta id: ", option_b_button.get_meta("resource_id"))
	
	option_container.show()
	
func _on_button_pressed(selected_option: Button) -> void:
	var selected_id = selected_option.get_meta("resource_id")
	print("Selected id: ", selected_id)
	user_choice.append(selected_id)
	option_container.hide()
	
	print(selected_id)
	
	if not master_clues.is_empty():
		deduction_loop()
	else:
		if user_choice.all(func(verify): return verify.ends_with("correct")) and deduction_chances > 0:
			visible = false
			
			print("Deduction Success!")
			
			var dialogic_timeline: String = current_ch + "_culprits"
			Dialogic.start(dialogic_timeline)
			
		elif user_choice.any(func(verify): return verify.ends_with("wrong")) and deduction_chances > 0:
			
			deduction_chances = deduction_chances - 1
			
			print("Try again!")
			Dialogic.start("try_again")
			
			master_clues.clear()
			user_choice.clear()
			
			initiate_deduction()
			
		elif deduction_chances <= 1:
			
			print("Game over.")
			Dialogic.start("game_over")
			get_tree().change_scene_to_file("res://scenes/ui/main_menu/MainMenu.tscn")
			
	
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
