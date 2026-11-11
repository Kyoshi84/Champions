extends Node
## Przełączanie ekranów: menu -> prolog w karczmie -> ucieczka przez Hufduhof -> Koszary <-> bitwa.

var current: Node = null

func _ready() -> void:
	go("menu")

func go(ekran: String, params: Dictionary = {}) -> void:
	get_tree().paused = false
	if current != null:
		current.queue_free()
		current = null
	var n: Node
	match ekran:
		"karczma":
			n = TavernScene.new()
		"bitwa":
			var b := BattleScene.new()
			b.adv_id = str(params.get("przygoda", "piwnice_carroburga"))
			b.trudnosc = str(params.get("trudnosc", "normal"))
			n = b
		"koszary":
			n = BarracksScene.new()
		_:
			n = MenuScene.new()
	n.set("main", self)
	current = n
	add_child(n)

## Pełnoekranowa plansza fabularna: kolejne strony tekstu, na końcu wywołuje 'po'.
func opowiesc(parent: Node, tytul: String, strony: Array, po: Callable, przycisk_konca: String = "Dalej") -> void:
	var layer := CanvasLayer.new()
	layer.layer = 50
	parent.add_child(layer)
	var idx := [0]
	var holder := [null]
	var pokaz := func(self_ref: Callable):
		if holder[0] != null:
			holder[0].queue_free()
		var ostatnia: bool = idx[0] >= strony.size() - 1
		var ov := UiKit.overlay(tytul, str(strony[idx[0]]), [[przycisk_konca if ostatnia else "Dalej", func():
			if ostatnia:
				layer.queue_free()
				po.call()
			else:
				idx[0] += 1
				self_ref.call(self_ref)]])
		holder[0] = ov
		layer.add_child(ov)
	pokaz.call(pokaz)
