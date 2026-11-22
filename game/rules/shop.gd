extends RefCounted
## A stall that swaps goods for goods. A shop's stock entries are gated by chapter and flag like
## everything else; each may list trades. There is no coin. Key items can never be wanted.

const Area: GDScript = preload("res://rules/area.gd")


## The trades that apply now: [{"index", "gives", "wants"}], the index counted over this list.
static func trades(shop: Dictionary, world: RefCounted) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for entry: Dictionary in shop.get("stock", []):
		var cond: Dictionary = {}
		for key: String in ["chapter_min", "chapter_max", "flag", "not_flag"]:
			var from_key: String = {"chapter_min": "from_chapter", "chapter_max": "to_chapter"}.get(key, key)
			if entry.has(from_key):
				cond[key] = entry[from_key]
		if entry.has("when"):
			cond.merge(entry["when"] as Dictionary)
		if not Area.holds(cond, world):
			continue
		for t: Dictionary in entry.get("trades", []):
			out.append({"index": out.size(), "gives": (t["gives"] as Dictionary).duplicate(), "wants": (t["wants"] as Dictionary).duplicate()})
	return out


## Item id -> count the party's packs hold together.
static func held(world: RefCounted) -> Dictionary:
	var total: Dictionary = {}
	for id: String in world.get("party"):
		for item: Variant in (world.get("packs").get(id, {}) as Dictionary):
			total[str(item)] = int(total.get(str(item), 0)) + int(world.get("packs")[id][item])
	return total


## Performs trade `index` of trades(). `items` is item id -> item JSON. Returns {"ok", "error",
## "gave", "took"}; a refused trade changes nothing. Wanted goods leave the packs in party
## order; given goods go to the first member's pack.
static func trade(shop: Dictionary, world: RefCounted, index: int, items: Dictionary) -> Dictionary:
	var out: Dictionary = {"ok": false, "error": "", "gave": {}, "took": {}}
	var list: Array[Dictionary] = trades(shop, world)
	if index < 0 or index >= list.size():
		out["error"] = "no trade %d" % index
		return out
	var wants: Dictionary = list[index]["wants"]
	var gives: Dictionary = list[index]["gives"]
	var party: Array = world.get("party")
	if party.is_empty():
		out["error"] = "no party"
		return out
	for item: String in wants:
		if not items.has(item) or str((items[item] as Dictionary).get("slot", "")) == "key":
			out["error"] = "'%s' cannot be traded" % item
			return out
	for item: String in gives:
		if not items.has(item):
			out["error"] = "unknown item '%s'" % item
			return out
	var have: Dictionary = held(world)
	for item: String in wants:
		if int(have.get(item, 0)) < int(wants[item]):
			out["error"] = "the party lacks '%s'" % item
			return out
	var packs: Dictionary = world.get("packs")
	for item: String in wants:
		var left: int = int(wants[item])
		for id: String in party:
			var pack: Dictionary = packs.get(id, {})
			var take: int = mini(left, int(pack.get(item, 0)))
			if take <= 0:
				continue
			left -= take
			if int(pack[item]) == take:
				pack.erase(item)
			else:
				pack[item] = int(pack[item]) - take
	var first: Dictionary = packs.get(str(party[0]), {})
	for item: String in gives:
		first[item] = int(first.get(item, 0)) + int(gives[item])
	packs[str(party[0])] = first
	out["ok"] = true
	out["gave"] = gives
	out["took"] = wants
	return out
