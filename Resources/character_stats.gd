extends Resource
class_name CharacterStats


signal level_up_notification()
signal update_stats()


class Ability:
	var min_modifier: float
	var max_modifier: float
	
	var ability_score: int = 25:
		set(value):
			ability_score = clamp(value, 0, 100)
			
	func _init(_min: float, _max: float) -> void:
		min_modifier = _min
		max_modifier = _max
		
	func percentile_lerp(min_bound: float, max_bound: float) -> float:
		return lerp(min_bound, max_bound, ability_score / 100.0)
		
	func get_modifier() -> float:
		return percentile_lerp(min_modifier, max_modifier)
		
	func increase() -> void:
		ability_score += randi_range(2, 5)


var level := 1
var xp := 0:
	set(value):
		xp = value
		
		var boundary = percentage_level_up_boundary()
		
		while xp > boundary:
			xp -= boundary
			level_up()
			boundary = percentage_level_up_boundary()
		update_stats.emit()


const MIN_DASH_COOLDOWN := 1.5
const MAX_DASH_COOLDOWN := 0.5


# Damage bonus 
var strength := Ability.new(2.0, 12.0)
# Movement speed
var speed := Ability.new(3.0, 7.0)
# HP bonus
var endurance := Ability.new(5.0, 25.0)
# Crit chance
var agility := Ability.new(0.05, 0.25)


func get_base_speed() -> float:
	return speed.get_modifier()


func get_damage_modifier() -> float:
	return strength.get_modifier()


func get_crit_chance() -> float:
	return agility.get_modifier()


func get_max_hp() -> int:
	return 20 + int(level * endurance.get_modifier())


func get_dash_cooldown() -> float:
	return agility.percentile_lerp(MIN_DASH_COOLDOWN, MAX_DASH_COOLDOWN)


func level_up() -> void:
	level += 1
	strength.increase()
	speed.increase()
	endurance.increase()
	agility.increase()
	level_up_notification.emit()


func percentage_level_up_boundary() -> int:
	return int(50 * pow(1.2, level))


func cubic_level_up_boundary() -> int:
	return int(50 + pow(level, 3))


func _init() -> void:
	pass
