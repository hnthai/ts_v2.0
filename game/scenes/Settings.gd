extends Control
## Settings: BGM/SFX volume and text speed.

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#0a0813")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_CENTER)
	col.add_theme_constant_override("separation", 22)
	col.custom_minimum_size = Vector2(560, 0)
	add_child(col)

	var title := Label.new()
	title.text = "Cài đặt"
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color("#ffd45e"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)

	_add_slider(col, "Nhạc nền (BGM)", "bgm_volume", 0.0, 1.0, 0.05)
	_add_slider(col, "Hiệu ứng (SFX)", "sfx_volume", 0.0, 1.0, 0.05)
	_add_slider(col, "Tốc độ chữ", "text_speed", 0.5, 3.0, 0.1)

	var back := Button.new()
	back.text = "Lưu & Quay lại"
	back.custom_minimum_size = Vector2(320, 56)
	back.add_theme_font_size_override("font_size", 24)
	back.pressed.connect(func ():
		GameState.save_settings()
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)
	col.add_child(back)


func _add_slider(parent: Node, label_text: String, key: String, min_v: float, max_v: float, step: float) -> void:
	var row := VBoxContainer.new()
	var lbl := Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 22)
	row.add_child(lbl)

	var slider := HSlider.new()
	slider.min_value = min_v
	slider.max_value = max_v
	slider.step = step
	slider.value = float(GameState.settings.get(key, min_v))
	slider.custom_minimum_size = Vector2(520, 30)
	slider.value_changed.connect(func (v):
		GameState.settings[key] = v
		Audio.apply_volumes()
	)
	row.add_child(slider)
	parent.add_child(row)
