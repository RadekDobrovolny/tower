extends CanvasLayer

## Herní HUD: zatím jen počet kreditů.

@onready var _credits_label: Label = $CreditsLabel


func _ready() -> void:
	Game.credits_changed.connect(_on_credits_changed)
	_on_credits_changed(Game.credits)


func _on_credits_changed(credits: int) -> void:
	_credits_label.text = "Kredity: %d kr" % credits
