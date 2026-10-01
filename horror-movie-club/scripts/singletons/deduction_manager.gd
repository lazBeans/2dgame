## Script Purpose: Manages puzzle completion sequencing, triggering final clue 
## dialogue timelines and transitioning into chapter deduction phases.
extends Node

## Called when the node enters the scene tree; placeholder for initialization.
func _ready() -> void:
	pass

## Called by the ThreadContainer when the final piece is linked; starts final clue dialogue.
func handle_puzzle_completion(final_clue_timeline: String) -> void:
	print("Final puzzle piece connected! Starting final clue dialogue...")
	
	Dialogic.start(final_clue_timeline)
	
	if not Dialogic.timeline_ended.is_connected(_on_clue_dialogue_finished):
		Dialogic.timeline_ended.connect(_on_clue_dialogue_finished)

## Triggered when the final clue dialogue finishes; launches the chapter deduction phase.
func _on_clue_dialogue_finished() -> void:
	if Dialogic.timeline_ended.is_connected(_on_clue_dialogue_finished):
		Dialogic.timeline_ended.disconnect(_on_clue_dialogue_finished)
		
	var chapter_deduction: String = GameManager.current_chapter + "_deduction"
	print("Dialogue finished. Launching deduction phase: " + chapter_deduction)
	Dialogic.start(chapter_deduction)
	
## Create an ordered segment for validating the reconstructed incident	
func populate_segment_queue(ch: String) -> void:
	var current_ch = GameManager.current_chapter
	var ordered_segments
