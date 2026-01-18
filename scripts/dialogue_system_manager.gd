extends Node
## Централізована система керування діалогами та персонажами
## Замінює hardcode логіку на функції
## ⚠️ Autoload скрипт - НЕ використовуй class_name!

signal character_talked(character_id: String)
signal limit_reached()
signal all_conversations_completed()
# Note: ці сигнали можуть бути використані іншими системами для реакції на події

## Конфігурація персонажів
var characters: Dictionary = {}

## Посилання на SaveSystem (autoload)
var save_system:
	get:
		return get_node("/root/SaveSystem")

func _ready():
	print("🎮 DialogueSystemManager готовий!")
	_init_characters()

## =====================================
## ІНІЦІАЛІЗАЦІЯ
## =====================================

func _init_characters():
	"""Реєструє всіх персонажів у системі"""
	register_character({
		"id": "alex",
		"name": "Алекс",
		"emoji": "👨",
		"description": "Твій старий друг",
		"available": true
	})
	
	register_character({
		"id": "bohdan",
		"name": "Богдан",
		"emoji": "🧔",
		"description": "Спокійний хлопець",
		"available": true
	})
	
	register_character({
		"id": "dana",
		"name": "Дана",
		"emoji": "👩",
		"description": "Весела дівчина",
		"available": true
	})
	
	register_character({
		"id": "ira",
		"name": "Іра",
		"emoji": "👱‍♀️",
		"description": "Прямолінійна особа",
		"available": true
	})
	
	print("📋 Зареєстровано персонажів: ", characters.keys())

## =====================================
## РЕЄСТРАЦІЯ
## =====================================

func register_character(data: Dictionary):
	"""Додає персонажа в систему"""
	if !data.has("id"):
		push_error("❌ Персонаж має мати 'id'!")
		return
	
	characters[data.id] = {
		"id": data.id,
		"name": data.get("name", "Unknown"),
		"emoji": data.get("emoji", "❓"),
		"description": data.get("description", ""),
		"available": data.get("available", true)
	}
	
	print("✅ Зареєстровано: ", data.id)

## =====================================
## ОСНОВНІ ПЕРЕВІРКИ (для .dialogue файлів)
## =====================================

func can_talk_to(character_id: String) -> bool:
	"""ЧИ МОЖНА ГОВОРИТИ З ПЕРСОНАЖЕМ?
	Використовується в .dialogue файлах:
	- Поговорити з X [if dialogue_system.can_talk_to("alex")]
	"""
	# Персонаж не існує
	if !characters.has(character_id):
		push_warning("⚠️ Персонаж не знайдений: " + character_id)
		return false
	
	# Персонаж недоступний
	if !characters[character_id].available:
		return false
	
	# Вже говорили
	if save_system.has_talked_to(character_id):
		return false
	
	# Ліміт вичерпано
	if !save_system.can_talk_to_new_character():
		return false
	
	return true

func has_talked_to(character_id: String) -> bool:
	"""ЧИ ВЖЕ ГОВОРИЛИ З ПЕРСОНАЖЕМ?
	- ✅ X (вже) [if dialogue_system.has_talked_to("alex")]
	"""
	return save_system.has_talked_to(character_id)

func is_limit_reached() -> bool:
	"""ЧИ ДОСЯГНУТО ЛІМІТУ?
	- 🍺 В бар [if dialogue_system.is_limit_reached()]
	"""
	return save_system.all_characters_completed()

func get_conversations_left() -> int:
	"""СКІЛЬКИ РОЗМОВ ЗАЛИШИЛОСЬ?"""
	return save_system.get_conversations_left()

func get_completed_count() -> int:
	"""СКІЛЬКИ ПЕРСОНАЖІВ ПРОЙДЕНО?"""
	return save_system.get_completed_characters_count()

## =====================================
## ВИКОНАННЯ ДІЙ (для .dialogue файлів)
## =====================================

func mark_talked(character_id: String):
	"""ВІДМІТИТИ ЩО ПОГОВОРИЛИ
	Використовується в .dialogue:
	do dialogue_system.mark_talked("alex")
	"""
	if !characters.has(character_id):
		push_error("❌ Персонаж не знайдений: " + character_id)
		return
	
	save_system.mark_character_talked(character_id)
	character_talked.emit(character_id)
	
	if save_system.all_characters_completed():
		limit_reached.emit()

## =====================================
## ДОПОМІЖНІ ФУНКЦІЇ
## =====================================

func get_character_info(character_id: String) -> Dictionary:
	"""Отримати інфо про персонажа"""
	if characters.has(character_id):
		return characters[character_id]
	return {}

func get_character_name(character_id: String) -> String:
	"""Отримати ім'я персонажа"""
	if characters.has(character_id):
		return characters[character_id].name
	return "Unknown"

func get_character_status_text(character_id: String) -> String:
	"""Отримати текст статусу для UI
	Повертає: "Поговорити з X", "✅ X (вже)", "🚫 (ліміт)"
	"""
	if !characters.has(character_id):
		return "❌ Невідомий персонаж"
	
	var char_name = characters[character_id].name
	
	if has_talked_to(character_id):
		return "✅ " + char_name + " (вже говорили)"
	
	if !save_system.can_talk_to_new_character():
		return "🚫 " + char_name + " (ліміт вичерпано)"
	
	return "Поговорити з " + char_name

func get_available_characters() -> Array[String]:
	"""Список ID персонажів з якими МОЖНА говорити"""
	var available: Array[String] = []
	for char_id in characters.keys():
		if can_talk_to(char_id):
			available.append(char_id)
	return available

func get_talked_characters() -> Array[String]:
	"""Список ID персонажів з якими ВЖЕ говорили"""
	return save_system.talked_characters.duplicate()

func get_all_character_ids() -> Array[String]:
	"""Всі ID персонажів"""
	var ids: Array[String] = []
	for id in characters.keys():
		ids.append(id)
	return ids

## =====================================
## АДМІН ФУНКЦІЇ
## =====================================

func reset_all():
	"""Скинути весь прогрес"""
	save_system.reset_progress()
	print("🔄 Діалогова система скинута")

func set_character_available(character_id: String, available: bool):
	"""Встановити доступність персонажа"""
	if characters.has(character_id):
		characters[character_id].available = available
		print("🔧 ", character_id, " доступність: ", available)

func get_status_summary() -> Dictionary:
	"""Повний статус системи"""
	return {
		"total_characters": characters.size(),
		"talked_count": get_completed_count(),
		"available_count": get_available_characters().size(),
		"conversations_left": get_conversations_left(),
		"limit_reached": is_limit_reached(),
		"talked_with": get_talked_characters()
	}

func print_status():
	"""Вивести статус в консоль"""
	var status = get_status_summary()
	print("═══════════════════════════════════")
	print("📊 СТАТУС ДІАЛОГОВОЇ СИСТЕМИ")
	print("═══════════════════════════════════")
	print("Всього персонажів: ", status.total_characters)
	print("Поговорили з: ", status.talked_count, "/", save_system.MAX_CONVERSATIONS)
	print("Доступно зараз: ", status.available_count)
	print("Залишилось спроб: ", status.conversations_left)
	print("Ліміт досягнуто: ", "✅" if status.limit_reached else "❌")
	print("Розмовляли з: ", status.talked_with)
	print("═══════════════════════════════════")
