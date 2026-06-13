extends Node
## Global game state: progress, story flags, and save/load.
## Registered as an autoload singleton (see project.godot).

const SAVE_PATH := "user://savegame.json"
const SETTINGS_PATH := "user://settings.json"

# Where the player currently is in the story.
var current_chapter: String = "chapter01"
var current_block: String = "start"
var current_index: int = 0

# Arbitrary story flags / choices the player has made (branching, endings...).
var flags: Dictionary = {}

# Player-facing settings.
var settings: Dictionary = {
	"bgm_volume": 0.8,
	"sfx_volume": 0.9,
	"text_speed": 1.0, # characters-per-second multiplier
}


func _ready() -> void:
	load_settings()


# --- Story flags --------------------------------------------------------------

func set_flag(key: String, value: Variant) -> void:
	flags[key] = value


func get_flag(key: String, default: Variant = null) -> Variant:
	return flags.get(key, default)


func reset_progress() -> void:
	current_chapter = "chapter01"
	current_block = "start"
	current_index = 0
	flags.clear()


# --- Save / load --------------------------------------------------------------

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> void:
	var data := {
		"chapter": current_chapter,
		"block": current_block,
		"index": current_index,
		"flags": flags,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))
		f.close()


func load_game() -> bool:
	if not has_save():
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	current_chapter = parsed.get("chapter", "chapter01")
	current_block = parsed.get("block", "start")
	current_index = int(parsed.get("index", 0))
	flags = parsed.get("flags", {})
	return true


# --- Settings -----------------------------------------------------------------

func save_settings() -> void:
	var f := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(settings, "\t"))
		f.close()
	Audio.apply_volumes()


func load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var f := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) == TYPE_DICTIONARY:
		for k in parsed.keys():
			settings[k] = parsed[k]
