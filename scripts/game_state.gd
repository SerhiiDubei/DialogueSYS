extends Node
## Стан гри для діалогової системи "4 друзі в барі"

# Параметри гравця (0-100)
var p_alcohol: int = 0     # Любов до алкоголю
var p_straight: int = 0    # Прямолінійність
var p_charm: int = 0       # Харизма
var p_patience: int = 0    # Терпіння

# Прапорці згоди персонажів
var agreed_alex: bool = false
var agreed_bohdan: bool = false
var agreed_dana: bool = false
var agreed_ira: bool = false

# Система збереження прогресу
var save_system: SaveSystem

func _ready():
	# Ініціалізуємо систему збереження
	save_system = SaveSystem.new()
	save_system.name = "SaveSystem"
	add_child(save_system)

# Умови L2 для кожного персонажа
func has_l2_alex() -> bool:
	return p_alcohol >= 60

func has_l2_bohdan() -> bool:
	return p_straight >= 55

func has_l2_dana() -> bool:
	return p_charm >= 60

func has_l2_ira() -> bool:
	return p_patience >= 55

# Скільки персонажів погодились
func get_agreed_count() -> int:
	var count = 0
	if agreed_alex: count += 1
	if agreed_bohdan: count += 1
	if agreed_dana: count += 1
	if agreed_ira: count += 1
	return count
