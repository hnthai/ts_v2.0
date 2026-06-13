extends Control
## Main menu: new game, continue, settings, quit.

func _ready() -> void:
	var bg := TextureRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	if ResourceLoader.exists("res://assets/bg/title.png"):
		bg.texture = load("res://assets/bg/title.png")
	else:
		var cr := ColorRect.new()
		cr.color = Color("#0a0813")
		cr.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(cr)
	add_child(bg)

	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.35)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	var title := Label.new()
	title.text = "HỆ THỐNG SƯ TÔN VÔ ĐỊCH"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color("#ffd45e"))
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 80
	add_child(title)

	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_CENTER)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 16)
	col.position.y += 40
	add_child(col)

	_add_button(col, "Chơi mới", _on_new_game)
	if GameState.has_save():
		_add_button(col, "Chơi tiếp", _on_continue)
	_add_button(col, "Cài đặt", _on_settings)
	_add_button(col, "Thoát", _on_quit)

	Audio.play_bgm("theme_title")


func _add_button(parent: Node, text: String, cb: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(320, 56)
	b.add_theme_font_size_override("font_size", 26)
	b.pressed.connect(cb)
	parent.add_child(b)


func _on_new_game() -> void:
	GameState.reset_progress()
	GameState.save_game()
	get_tree().change_scene_to_file("res://scenes/Game.tscn")


func _on_continue() -> void:
	GameState.load_game()
	get_tree().change_scene_to_file("res://scenes/Game.tscn")


func _on_settings() -> void:
	get_tree().change_scene_to_file("res://scenes/Settings.tscn")


func _on_quit() -> void:
	get_tree().quit()
