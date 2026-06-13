extends Control
## Splash screen shown on launch, then transitions to the main menu.

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#0a0813")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var title := Label.new()
	title.text = "HỆ THỐNG SƯ TÔN\nVÔ ĐỊCH MẠNH NHẤT"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.set_anchors_preset(Control.PRESET_FULL_RECT)
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Color("#ffd45e"))
	title.modulate.a = 0.0
	add_child(title)

	var t := create_tween()
	t.tween_property(title, "modulate:a", 1.0, 0.8)
	t.tween_interval(1.0)
	t.tween_property(title, "modulate:a", 0.0, 0.6)
	t.tween_callback(func ():
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)
