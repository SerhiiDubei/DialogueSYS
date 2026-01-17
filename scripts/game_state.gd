extends Node

## Стан гри для діалогів
## Передається в DialogueManager через extra_game_states

# Параметри героя (0..100)
var p_alcohol: int = 0      # Любов до алкоголю
var p_straight: int = 0     # Прямолінійність
var p_charm: int = 0        # Харизма
var p_patience: int = 0     # Терпіння

# Прапорці - хто погодився піти на пиво
var agreed_alex: bool = false
var agreed_bohdan: bool = false
var agreed_dana: bool = false
var agreed_ira: bool = false

func _ready():
	# Ініціалізація буде через діалог
	pass

## Перевірка, чи доступний L2 для персонажа
func has_l2_alex() -> bool:
	return p_charm >= 50

func has_l2_bohdan() -> bool:
	return p_patience >= 50

func has_l2_dana() -> bool:
	return p_alcohol >= 50

func has_l2_ira() -> bool:
	return p_straight <= 50

## Отримати кількість тих, хто погодився
func get_agreed_count() -> int:
	var count = 0
	if agreed_alex: count += 1
	if agreed_bohdan: count += 1
	if agreed_dana: count += 1
	if agreed_ira: count += 1
	return count
