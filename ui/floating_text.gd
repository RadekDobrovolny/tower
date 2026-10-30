class_name FloatingText
extends RichTextLabel

## Krátký text, který vystoupá vzhůru a zmizí, např. „+40 kr“ po zaplacení („kr“ se ukáže jako mince).

const RISE := 40.0
const DURATION := 1.2
const SIZE := Vector2(180, 28)


static func spawn(parent: Node, at: Vector2, message: String, color := Color(1.0, 0.85, 0.3)) -> void:
	var label := FloatingText.new()
	label.add_theme_color_override("default_color", color)
	label.text = "[center]%s[/center]" % UiIcons.money_bbcode(message, 18)
	label.size = SIZE
	label.position = at - SIZE / 2.0
	parent.add_child(label)


func _init() -> void:
	bbcode_enabled = true
	scroll_active = false
	autowrap_mode = TextServer.AUTOWRAP_OFF
	mouse_filter = MOUSE_FILTER_IGNORE
	add_theme_font_override("normal_font", preload("res://assets/fonts/ChakraPetch-SemiBold.ttf"))
	add_theme_font_size_override("normal_font_size", 18)
	add_theme_constant_override("outline_size", 4)
	add_theme_color_override("font_outline_color", Color.BLACK)


func _ready() -> void:
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "position:y", position.y - RISE, DURATION) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, DURATION * 0.6).set_delay(DURATION * 0.4)
	tween.chain().tween_callback(queue_free)
