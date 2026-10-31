class_name JunkDealerPopup
extends ColorRect

## Okno vesmírného vetešníka. Zastaví hru a nabídne prodej vylepšení. Běží i při pauze
## (process_mode Always).


func _ready() -> void:
	hide()
	%DealerDecline.pressed.connect(_close)


func open(dealer: JunkDealer, offers: Array[ShopItem]) -> void:
	for child in %DealerOffers.get_children():
		child.queue_free()
	for item in offers:
		var button := ActionButton.new()
		button.setup(null, item.label.call())
		button.set_cost(dealer.refund(item))
		button.pressed.connect(_sell.bind(dealer, item))
		%DealerOffers.add_child(button)
	var handout := dealer.station.sale_items().is_empty()
	var lines: Array = Lines.JUNK_DEALER_HANDOUT if handout else Lines.JUNK_DEALER_OFFER
	%DealerBody.text = Lines.pick(lines)
	get_tree().paused = true
	show()


func _sell(dealer: JunkDealer, item: ShopItem) -> void:
	dealer.sell(item)
	_close()


func _close() -> void:
	hide()
	get_tree().paused = false
