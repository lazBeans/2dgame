## PURPOSE: Acts as a centralized global event bus (observer pattern).
## Declares decoupled game-wide signals to allow clean cross-scene communication 
## without creating rigid parent-child script dependencies.
extends Node

# ==========================================
# GLOBAL GAME SIGNALS
# ==========================================

## Emitted when new evidence is unlocked and added to the pending queue.
signal evidence_queued(evidence_id: String)

## Emitted when the detective board UI should reset its visuals and connections.
signal board_reset

## Emitted when the active chapter progresses.
signal chapter_changed(current_chapter: String)

## Emitted when all required deduction segments are successfully linked.
signal all_segments_unlocked(connection_data: Variant)

## Emitted when the detective board UI is opened or closed.
signal board_toggled(is_open: bool)

signal all_evidence_connected
