class_name FloatingText
extends Label

## Krátký text, který vystoupá vzhůru a zmizí, např. „+40 kr“ po zaplacení.

const RISE := 40.0
const DURATION := 1.2


static func spawn(parent: Node, at: Vector2, message: String, color := Color(1.0, 0.85, 0.3)) -> void:
	var label := FloatingText.new()
	label.text = message
	label.modulate = color
	label.size = Vector2(120, 28)
	label.position = at - label.size / 2.0
	parent.add_child(label)


func _ready() -> void:
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mouse_filter = MOUSE_FILTER_IGNORE
	add_theme_font_size_override("font_size", 20)
	add_theme_constant_override("outline_size", 4)
	add_theme_color_override("font_outline_color", Color.BLACK)
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "position:y", position.y - RISE, DURATION) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, DURATION * 0.6).set_delay(DURATION * 0.4)
	tween.chain().tween_callback(queue_free)
