extends "res://tests/test_case.gd"

const Shop: GDScript = preload("res://rules/shop.gd")
const Session: GDScript = preload("res://rules/session.gd")
const World: GDScript = preload("res://rules/world_state.gd")
const SaveStore: GDScript = preload("res://rules/save_store.gd")

const PATH: String = "user://test_shop.json"


func _items() -> Dictionary:
	return {"frond": {"slot": "small"}, "salt": {"slot": "supply"}, "token": {"slot": "key"}}


func _shop() -> Dictionary:
	return {"id": "stall", "keeper": {"place": "place.x", "role": "weigher"}, "stock": [
		{"items": ["salt"], "trades": [{"gives": {"salt": 2}, "wants": {"frond": 1}}]},
		{"items": ["salt"], "from_chapter": 2, "trades": [{"gives": {"frond": 1}, "wants": {"salt": 3}}]},
		{"items": ["salt"], "when": {"flag": "market"}, "trades": [{"gives": {"salt": 1}, "wants": {"token": 1}}]}]}


func _world(pack: Dictionary) -> RefCounted:
	var w: RefCounted = World.new()
	w.party.append("hero")
	w.party.append("sefa")
	w.packs["hero"] = pack
	return w


func test_gating() -> void:
	var w: RefCounted = _world({})
	check_eq(Shop.trades(_shop(), w).size(), 1, "chapter 1")
	w.chapter = 2
	check_eq(Shop.trades(_shop(), w).size(), 2, "chapter 2")
	check_eq(Shop.trades(_shop(), w)[1]["index"], 1, "index over the applicable list")
	w.set_flag("market")
	check_eq(Shop.trades(_shop(), w).size(), 3, "flag")


func test_refusal_changes_nothing() -> void:
	var w: RefCounted = _world({"salt": 1})
	var r: Dictionary = Shop.trade(_shop(), w, 0, _items())
	check(not r["ok"], "lacks frond")
	check_eq(w.packs["hero"], {"salt": 1}, "pack untouched")
	check(not Shop.trade(_shop(), w, 5, _items())["ok"], "bad index")


func test_success_across_pack() -> void:
	var w: RefCounted = _world({"frond": 1})
	var r: Dictionary = Shop.trade(_shop(), w, 0, _items())
	check(r["ok"], "traded")
	check_eq(w.packs["hero"], {"salt": 2}, "frond gone, salt in")
	w.packs["hero"] = {"frond": 1}
	w.packs["sefa"] = {"frond": 2}
	w.chapter = 2
	w.packs["hero"] = {"salt": 1}
	w.packs["sefa"] = {"salt": 2}
	check(Shop.trade(_shop(), w, 1, _items())["ok"], "wants spread over the party")
	check_eq(w.packs["hero"], {"frond": 1}, "hero")
	check(not w.packs["sefa"].has("salt"), "sefa emptied")


func test_key_item_never_wanted() -> void:
	var w: RefCounted = _world({"token": 1})
	w.set_flag("market")
	var r: Dictionary = Shop.trade(_shop(), w, 1, _items())
	check(not r["ok"], "key item refused")
	check_eq(w.packs["hero"], {"token": 1}, "token kept")


func test_session_trade_completes_step() -> void:
	var area: Dictionary = {"id": "a", "legend": {".": {}}, "rows": ["..."], "spawn": [0, 0], "exits": [], "things": []}
	var quest: Dictionary = {"id": "s1", "kind": "discover", "giver": "person.x", "chapters": [1, 1],
		"steps": [{"id": "get", "intent": "Get salt.", "points": 1, "difficulty": 8, "requires": {"holds": {"salt": 2}}}],
		"clears": "s1.done", "sets": []}
	var store: RefCounted = SaveStore.new(PATH)
	store.call("clear")
	var s: RefCounted = Session.new_game({"areas": {"a": area}, "quests": [quest], "items": _items(), "shops": {"stall": _shop()}}, store)
	check_eq(s.trades("stall").size(), 1, "one trade")
	check(not s.trade("nowhere", 0)["ok"], "unknown shop")
	s.world.packs["hero"] = {"frond": 1}
	var r: Dictionary = s.trade("stall", 0)
	check(r["ok"], "ok")
	check_eq(r["steps_done"], ["s1:get"], "step done")
	check(store.call("load_state")["state"] != null, "saved")
	store.call("clear")
