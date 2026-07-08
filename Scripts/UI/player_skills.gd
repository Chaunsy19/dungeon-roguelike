extends RefCounted

const SKILL_XP_REQUIREMENT_SCALE := 1.15

var constitution_damage_xp_progress := 0.0
var skills := {
	"woodcutting": {
		"level": 1,
		"xp": 0,
		"xp_to_next": 30
	},
	"constitution": {
		"level": 1,
		"xp": 0,
		"xp_to_next": 30
	}
}


func gain_xp(skill_name: String, amount: int) -> int:
	if not skills.has(skill_name):
		return 0

	var skill: Dictionary = skills[skill_name]
	var levels_gained := 0
	skill["xp"] += amount

	while skill["xp"] >= skill["xp_to_next"]:
		skill["xp"] -= skill["xp_to_next"]
		skill["level"] += 1
		levels_gained += 1
		skill["xp_to_next"] = get_next_skill_xp_requirement(skill["xp_to_next"])

	return levels_gained


func gain_constitution_xp_from_damage(amount: float) -> int:
	constitution_damage_xp_progress += amount * 0.33
	var xp_to_add := 0

	while constitution_damage_xp_progress >= 1.0:
		constitution_damage_xp_progress -= 1.0
		xp_to_add += 1

	if xp_to_add <= 0:
		return 0

	return gain_xp("constitution", xp_to_add)


func get_level(skill_name: String) -> int:
	if not skills.has(skill_name):
		return 1

	return skills[skill_name]["level"]


func get_xp(skill_name: String) -> int:
	if not skills.has(skill_name):
		return 0

	return skills[skill_name]["xp"]


func get_xp_to_next(skill_name: String) -> int:
	if not skills.has(skill_name):
		return 0

	return skills[skill_name]["xp_to_next"]


func get_label_text(skill_name: String) -> String:
	return "Level: %s XP %s / %s" % [
		get_level(skill_name),
		get_xp(skill_name),
		get_xp_to_next(skill_name)
	]


func get_next_skill_xp_requirement(current_requirement: int) -> int:
	return max(current_requirement + 1, int(ceil(current_requirement * SKILL_XP_REQUIREMENT_SCALE)))
