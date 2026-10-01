## PURPOSE: Acts as a centralized global event bus (observer pattern).
## Declares decoupled game-wide signals to allow clean cross-scene communication 
## without creating rigid parent-child script dependencies.
extends Node

# ==========================================
# GLOBAL GAME SIGNALS
# ==========================================
signal evidence_queued(evidence_id: String)
signal board_reset
signal chapter_changed(current_chapter: String)
signal all_segments_unlocked(connection_data: Variant)
signal board_toggled(is_open: bool)
