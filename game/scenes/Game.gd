extends Control
## Visual-novel runtime / interpreter.
##
## Reads a chapter JSON from res://story/<id>.json and steps through a list of
## commands. UI is built in code so the .tscn stays trivial and robust.
##
## Command reference (each command is a Dictionary keyed by its verb):
##   {"bg": "name"}                          -> show background assets/bg/name.png
##   {"music": "name"} | {"music": ""}       -> play / stop bgm
##   {"sfx": "name"}                         -> one-shot sound
##   {"show": "char", "at": "center",        -> show character sprite
##            "expr": "neutral"}                 (at: left|center|right)
##   {"hide": "char"} | {"hide": "all"}      -> remove sprite(s)
##   {"say": "Name", "text": "...", "color"} -> dialogue line (waits for input)
##   {"narrate": "..."}                      -> narration line (no speaker)
##   {"choice": [{"text": "...", "goto": "block", "set": {...}}]}
##   {"set": {"flag": value}}                -> set story flags
##   {"goto": "block"}                       -> jump to another block
##   {"next_chapter": "chapterXX"}           -> load next chapter file
##   {"end": "ending_id"}                    -> roll credits / ending screen

const STORY_DIR := "res://story/"
const BG_DIR := "res://assets/bg/"
const CHAR_DIR := "res://assets/char/"

var _story: Dictionary = {}
var _blocks: Dictionary = {}
var _block: Array = []
var _index: int = 0

var _typing: bool = false
var _text_tween: Tween
var _choice_active: bool = false

# --- UI nodes (built in _build_ui) -------------------------------------------
var _bg: TextureRect
var _char_slots: Dictionary = {}        # "left"/"center"/"right" -> TextureRect
var _dialogue_panel: PanelContainer
var _name_label: Label
var _text_label: RichTextLabel
var _continue_hint: Label
var _choice_box: VBoxContainer
var _menu_button: Button
var _quick_menu: PanelContainer


func _ready() -> void:
	_build_ui()
	# Resume from the current GameState position (set by MainMenu before load).
	load_chapter(GameState.current_chapter, GameState.current_block, GameState.current_index)


# =============================================================================
#  Story loading / interpretation
# =============================================================================

func load_chapter(chapter_id: String, from_block: String = "start", from_index: int = 0) -> void:
	var path := STORY_DIR + chapter_id + ".json"
	if not ResourceLoader.exists(path) and not FileAccess.file_exists(path):
		_fatal("Không tìm thấy chương: " + path)
		return
	var f := FileAccess.open(path, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		_fatal("Chương lỗi định dạng JSON: " + path)
		return
	_story = parsed
	_blocks = _story.get("blocks", {})
	GameState.current_chapter = chapter_id

	var start_block: String = from_block
	if not _blocks.has(start_block):
		start_block = _story.get("start", "start")
	_goto(start_block, from_index)


func _goto(block_name: String, start_index: int = 0) -> void:
	if not _blocks.has(block_name):
		_fatal("Không có block: " + block_name)
		return
	_block = _blocks[block_name]
	_index = start_index
	GameState.current_block = block_name
	_clear_choices()
	_process_next()


func _process_next() -> void:
	# Execute commands until one of them requires waiting for player input.
	while _index < _block.size():
		var cmd: Dictionary = _block[_index]
		_index += 1
		GameState.current_index = _index
		if _execute(cmd):
			return
	# Block ran out without a terminal command -> safety net.
	_show_dialogue("", "(Hết nội dung. Cảm ơn bạn đã chơi bản thử nghiệm!)")


## Returns true if execution should pause and wait for the player.
func _execute(cmd: Dictionary) -> bool:
	if cmd.has("bg"):
		_set_background(cmd["bg"])
		return false
	if cmd.has("music"):
		if String(cmd["music"]).is_empty():
			Audio.stop_bgm()
		else:
			Audio.play_bgm(cmd["music"])
		return false
	if cmd.has("sfx"):
		Audio.play_sfx(cmd["sfx"])
		return false
	if cmd.has("show"):
		_show_character(cmd["show"], cmd.get("at", "center"), cmd.get("expr", ""))
		return false
	if cmd.has("hide"):
		_hide_character(cmd["hide"])
		return false
	if cmd.has("set"):
		for k in cmd["set"].keys():
			GameState.set_flag(k, cmd["set"][k])
		return false
	if cmd.has("if"):
		var actual: Variant = GameState.get_flag(cmd["if"])
		var expected: Variant = cmd.get("eq", true)
		if actual == expected:
			_goto(cmd["goto"])
			return true
		elif cmd.has("else"):
			_goto(cmd["else"])
			return true
		return false # condition false, no else -> fall through to next command
	if cmd.has("goto"):
		_goto(cmd["goto"])
		return true
	if cmd.has("narrate"):
		_show_dialogue("", cmd["narrate"])
		return true
	if cmd.has("say"):
		_show_dialogue(cmd["say"], cmd.get("text", ""), cmd.get("color", ""))
		return true
	if cmd.has("choice"):
		_show_choices(cmd["choice"])
		return true
	if cmd.has("next_chapter"):
		_advance_chapter(cmd["next_chapter"])
		return true
	if cmd.has("end"):
		_end_game(cmd["end"])
		return true
	# Unknown command -> skip.
	return false


func _advance_chapter(next_id: String) -> void:
	GameState.current_chapter = next_id
	GameState.current_block = "start"
	GameState.current_index = 0
	GameState.save_game()
	load_chapter(next_id, "start", 0)


func _end_game(_ending_id: String) -> void:
	GameState.save_game()
	get_tree().change_scene_to_file("res://scenes/Ending.tscn")


# =============================================================================
#  Presentation
# =============================================================================

func _set_background(name: String) -> void:
	var tex := _load_texture(BG_DIR + name)
	if tex:
		# Quick cross-fade.
		var fade := create_tween()
		_bg.texture = tex
		_bg.modulate.a = 0.0
		fade.tween_property(_bg, "modulate:a", 1.0, 0.4)


func _show_character(char_name: String, at: String, expr: String) -> void:
	if not _char_slots.has(at):
		at = "center"
	var slot: TextureRect = _char_slots[at]
	var file := char_name
	if not expr.is_empty():
		file = char_name + "_" + expr
	var tex := _load_texture(CHAR_DIR + file)
	if tex == null:
		tex = _load_texture(CHAR_DIR + char_name)
	slot.texture = tex
	slot.visible = tex != null
	slot.modulate = Color(1, 1, 1, 0)
	var t := create_tween()
	t.tween_property(slot, "modulate:a", 1.0, 0.3)


func _hide_character(who: String) -> void:
	if who == "all":
		for s in _char_slots.values():
			s.visible = false
			s.texture = null
		return
	# Hide by matching slot that currently shows this character is non-trivial
	# without tracking; simplest behaviour: hide all named occurrences.
	for s in _char_slots.values():
		s.visible = false
		s.texture = null


func _show_dialogue(speaker: String, text: String, color_hex: String = "") -> void:
	_dialogue_panel.visible = true
	_name_label.visible = not speaker.is_empty()
	_name_label.text = speaker
	if not color_hex.is_empty():
		_name_label.add_theme_color_override("font_color", Color(color_hex))
	else:
		_name_label.add_theme_color_override("font_color", Color("#ffd45e"))

	_text_label.text = text
	_text_label.visible_ratio = 0.0
	_typing = true
	_continue_hint.visible = false

	var speed: float = max(10.0, 40.0 * float(GameState.settings.get("text_speed", 1.0)))
	var duration: float = float(max(text.length(), 1)) / speed
	if _text_tween and _text_tween.is_running():
		_text_tween.kill()
	_text_tween = create_tween()
	_text_tween.tween_property(_text_label, "visible_ratio", 1.0, duration)
	_text_tween.tween_callback(func ():
		_typing = false
		_continue_hint.visible = true
	)


func _show_choices(choices: Array) -> void:
	_choice_active = true
	_clear_choices()
	_choice_box.visible = true
	for c in choices:
		var btn := Button.new()
		btn.text = String(c.get("text", "..."))
		btn.custom_minimum_size = Vector2(560, 56)
		btn.add_theme_font_size_override("font_size", 24)
		btn.pressed.connect(_on_choice_selected.bind(c))
		_choice_box.add_child(btn)


func _on_choice_selected(choice: Dictionary) -> void:
	if choice.has("set"):
		for k in choice["set"].keys():
			GameState.set_flag(k, choice["set"][k])
	_choice_active = false
	_clear_choices()
	if choice.has("next_chapter"):
		_advance_chapter(choice["next_chapter"])
	elif choice.has("goto"):
		_goto(choice["goto"])
	else:
		_process_next()


func _clear_choices() -> void:
	_choice_box.visible = false
	for c in _choice_box.get_children():
		c.queue_free()


# =============================================================================
#  Input
# =============================================================================

func _unhandled_input(event: InputEvent) -> void:
	if _choice_active or (_quick_menu and _quick_menu.visible):
		return
	var advance := false
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		advance = true
	elif event is InputEventScreenTouch and event.pressed:
		advance = true
	elif event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and event.keycode == KEY_SPACE):
		advance = true
	if not advance:
		return
	get_viewport().set_input_as_handled()
	if _typing:
		# Skip the typewriter and reveal the full line.
		if _text_tween and _text_tween.is_running():
			_text_tween.kill()
		_text_label.visible_ratio = 1.0
		_typing = false
		_continue_hint.visible = true
	else:
		_process_next()


# =============================================================================
#  Helpers
# =============================================================================

func _load_texture(base_path: String) -> Texture2D:
	for ext in [".png", ".webp", ".jpg", ".jpeg"]:
		var p: String = base_path + ext
		if ResourceLoader.exists(p):
			return load(p)
	return null


func _fatal(msg: String) -> void:
	push_error(msg)
	_show_dialogue("Lỗi", msg)


# =============================================================================
#  UI construction
# =============================================================================

func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	_bg = TextureRect.new()
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)

	# Character layer with three anchored slots.
	var char_layer := Control.new()
	char_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	char_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(char_layer)
	for slot_name in ["left", "center", "right"]:
		var tr := TextureRect.new()
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		tr.custom_minimum_size = Vector2(420, 620)
		tr.size = Vector2(420, 620)
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tr.visible = false
		match slot_name:
			"left":
				tr.position = Vector2(40, 100)
			"center":
				tr.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
				tr.position = Vector2(430, 100)
			"right":
				tr.position = Vector2(820, 100)
		char_layer.add_child(tr)
		_char_slots[slot_name] = tr

	# Dialogue box.
	_dialogue_panel = PanelContainer.new()
	_dialogue_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_dialogue_panel.offset_left = 40
	_dialogue_panel.offset_right = -40
	_dialogue_panel.offset_top = -230
	_dialogue_panel.offset_bottom = -24
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.04, 0.09, 0.86)
	style.border_color = Color("#ffd45e")
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(18)
	_dialogue_panel.add_theme_stylebox_override("panel", style)
	add_child(_dialogue_panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	_dialogue_panel.add_child(vb)

	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", 28)
	_name_label.add_theme_color_override("font_color", Color("#ffd45e"))
	vb.add_child(_name_label)

	_text_label = RichTextLabel.new()
	_text_label.bbcode_enabled = true
	_text_label.fit_content = true
	_text_label.scroll_active = false
	_text_label.custom_minimum_size = Vector2(0, 120)
	_text_label.add_theme_font_size_override("normal_font_size", 24)
	_text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(_text_label)

	_continue_hint = Label.new()
	_continue_hint.text = "▼ chạm để tiếp tục"
	_continue_hint.add_theme_font_size_override("font_size", 16)
	_continue_hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.55))
	_continue_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vb.add_child(_continue_hint)

	# Choices.
	_choice_box = VBoxContainer.new()
	_choice_box.set_anchors_preset(Control.PRESET_CENTER)
	_choice_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_choice_box.add_theme_constant_override("separation", 14)
	_choice_box.visible = false
	add_child(_choice_box)

	# Top-right quick menu button.
	_menu_button = Button.new()
	_menu_button.text = "☰"
	_menu_button.add_theme_font_size_override("font_size", 26)
	_menu_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_menu_button.position = Vector2(-72, 16)
	_menu_button.custom_minimum_size = Vector2(56, 48)
	_menu_button.pressed.connect(_toggle_quick_menu)
	add_child(_menu_button)

	_build_quick_menu()


func _build_quick_menu() -> void:
	_quick_menu = PanelContainer.new()
	_quick_menu.set_anchors_preset(Control.PRESET_CENTER)
	_quick_menu.visible = false
	var qs := StyleBoxFlat.new()
	qs.bg_color = Color(0.05, 0.04, 0.09, 0.96)
	qs.border_color = Color("#ffd45e")
	qs.set_border_width_all(2)
	qs.set_corner_radius_all(12)
	qs.set_content_margin_all(20)
	_quick_menu.add_theme_stylebox_override("panel", qs)
	add_child(_quick_menu)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	_quick_menu.add_child(col)

	var title := Label.new()
	title.text = "Tạm dừng"
	title.add_theme_font_size_override("font_size", 26)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)

	var btn_resume := Button.new()
	btn_resume.text = "Tiếp tục"
	btn_resume.custom_minimum_size = Vector2(280, 50)
	btn_resume.pressed.connect(_toggle_quick_menu)
	col.add_child(btn_resume)

	var btn_save := Button.new()
	btn_save.text = "Lưu game"
	btn_save.custom_minimum_size = Vector2(280, 50)
	btn_save.pressed.connect(func ():
		GameState.save_game()
		btn_save.text = "Đã lưu ✓"
	)
	col.add_child(btn_save)

	var btn_menu := Button.new()
	btn_menu.text = "Về menu chính"
	btn_menu.custom_minimum_size = Vector2(280, 50)
	btn_menu.pressed.connect(func ():
		GameState.save_game()
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)
	col.add_child(btn_menu)


func _toggle_quick_menu() -> void:
	_quick_menu.visible = not _quick_menu.visible
