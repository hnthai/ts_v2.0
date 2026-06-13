extends Control
## Ending / credits screen.

func _ready() -> void:
	Audio.play_bgm("theme_title")
	var bg := ColorRect.new()
	bg.color = Color("#0a0813")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_CENTER)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 18)
	add_child(col)

	var t := Label.new()
	t.text = "— HOÀN —"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 56)
	t.add_theme_color_override("font_color", Color("#ffd45e"))
	col.add_child(t)

	var sub := Label.new()
	sub.text = "Cảm ơn bạn đã đồng hành cùng Diệp Trần\ntrên con đường trở thành Sư Tôn vô địch."
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 24)
	col.add_child(sub)

	var b := Button.new()
	b.text = "Về menu chính"
	b.custom_minimum_size = Vector2(320, 56)
	b.add_theme_font_size_override("font_size", 24)
	b.pressed.connect(func ():
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)
	col.add_child(b)
