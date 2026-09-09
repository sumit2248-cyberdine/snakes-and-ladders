class_name SnakesRuleSet
extends Resource
## Tunable S&L variant. Data only; SnakesRules reads it. Mirrors LudoRuleSet.

enum FinishRule { EXACT_STAY, EXACT_BOUNCE, OVERFLOW_WIN }

@export var rule_name: String = "Classic"
@export var finish_rule: int = FinishRule.EXACT_STAY
@export var extra_roll_on_six: bool = true
@export var cancel_on_three_sixes: bool = true
@export var extra_roll_on_ladder: bool = false
@export var portal_preset: String = "classic_mb"
@export var bounce_triggers_portal: bool = false


static func classic() -> SnakesRuleSet:
	var r := SnakesRuleSet.new()
	r.rule_name = "Classic"
	r.finish_rule = FinishRule.EXACT_STAY
	r.extra_roll_on_six = true
	r.cancel_on_three_sixes = true
	r.extra_roll_on_ladder = false
	r.portal_preset = "classic_mb"
	return r


static func blitz() -> SnakesRuleSet:
	var r := SnakesRuleSet.new()
	r.rule_name = "Blitz"
	r.finish_rule = FinishRule.OVERFLOW_WIN
	r.extra_roll_on_six = true
	r.cancel_on_three_sixes = false
	r.extra_roll_on_ladder = true
	r.portal_preset = "classic_mb"
	return r


static func quick() -> SnakesRuleSet:
	var r := SnakesRuleSet.new()
	r.rule_name = "Quick"
	r.finish_rule = FinishRule.EXACT_STAY
	r.extra_roll_on_six = true
	r.cancel_on_three_sixes = true
	r.extra_roll_on_ladder = false
	r.portal_preset = "quick"
	return r


static func load_preset(preset_id: String) -> SnakesRuleSet:
	match preset_id:
		"blitz":
			return blitz()
		"quick":
			return quick()
		_:
			return classic()


func flag_dict() -> Dictionary:
	return {
		"rule_name": rule_name,
		"finish_rule": finish_rule,
		"extra_roll_on_six": extra_roll_on_six,
		"cancel_on_three_sixes": cancel_on_three_sixes,
		"extra_roll_on_ladder": extra_roll_on_ladder,
		"portal_preset": portal_preset,
		"bounce_triggers_portal": bounce_triggers_portal,
	}


func apply_flag_dict(d: Dictionary) -> void:
	rule_name = str(d.get("rule_name", rule_name))
	finish_rule = int(d.get("finish_rule", finish_rule))
	extra_roll_on_six = bool(d.get("extra_roll_on_six", extra_roll_on_six))
	cancel_on_three_sixes = bool(d.get("cancel_on_three_sixes", cancel_on_three_sixes))
	extra_roll_on_ladder = bool(d.get("extra_roll_on_ladder", extra_roll_on_ladder))
	portal_preset = str(d.get("portal_preset", portal_preset))
	bounce_triggers_portal = bool(d.get("bounce_triggers_portal", bounce_triggers_portal))
