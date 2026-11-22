extends RefCounted
## One person's sheet: attributes, the Reach talent, skill steps and traits (PLAN.md section 2).
## Numbers here are starting values; content sets them.

var id: String = ""
var body: int = 10
var hands: int = 10
var mind: int = 10
var standing: int = 10
var reach: int = 0
## Skill name to step (1 to 5).
var skills: Dictionary = {}
var traits: Array[String] = []


## Health equals Body.
func health() -> int:
	return body


## The ebb limit equals Standing.
func ebb_limit() -> int:
	return standing


## The average of Hands and Mind, rounded down.
func quickness() -> int:
	return (hands + mind) / 2


func step_of(skill: String) -> int:
	return int(skills.get(skill, 0))


func to_dict() -> Dictionary:
	return {
		"id": id, "body": body, "hands": hands, "mind": mind, "standing": standing,
		"reach": reach, "skills": skills.duplicate(), "traits": traits.duplicate(),
	}


static func from_dict(d: Dictionary) -> RefCounted:
	var s: RefCounted = (load("res://rules/character_sheet.gd") as GDScript).new()
	s.id = str(d.get("id", ""))
	s.body = int(d.get("body", 10))
	s.hands = int(d.get("hands", 10))
	s.mind = int(d.get("mind", 10))
	s.standing = int(d.get("standing", 10))
	s.reach = int(d.get("reach", 0))
	var sk: Dictionary = d.get("skills", {})
	for k: Variant in sk:
		s.skills[str(k)] = int(sk[k])
	for t: Variant in d.get("traits", []):
		s.traits.append(str(t))
	return s
