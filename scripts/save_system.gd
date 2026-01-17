extends Node
## Система збереження прогресу діалогів
## ⚠️ Autoload скрипт - НЕ використовуй class_name!

# ⚠️ ЛІМІТ: можна говорити тільки з 2 персонажами з 4!
const MAX_CONVERSATIONS: int = 2

# Пройдені діалоги
var completed_dialogues: Array[String] = []

# Персонажі, з якими поговорили
var talked_characters: Array[String] = []

func _ready():
	load_game_data()
	print("✅ SaveSystem готовий!")

# Чи досягнуто ліміт розмов (2 з 4)
func all_characters_completed() -> bool:
	return talked_characters.size() >= MAX_CONVERSATIONS

# Чи є ще спроби для розмов?
func has_conversations_left() -> bool:
	return talked_characters.size() < MAX_CONVERSATIONS

# Чи можна говорити з новим персонажем?
func can_talk_to_new_character() -> bool:
	return has_conversations_left()

# Відмітити діалог як пройдений
func mark_dialogue_completed(dialogue_id: String) -> void:
	if not dialogue_id in completed_dialogues:
		completed_dialogues.append(dialogue_id)
		print("✅ Діалог пройдено: ", dialogue_id)

# Відмітити персонажа як пройденого
func mark_character_talked(character_name: String) -> void:
	if not character_name in talked_characters:
		talked_characters.append(character_name)
		print("✅ Поговорили з: ", character_name, " (", talked_characters.size(), "/", MAX_CONVERSATIONS, ")")
		if all_characters_completed():
			print("⚠️ ЛІМІТ ДОСЯГНУТО! Використано всі ", MAX_CONVERSATIONS, " спроби. Можна йти в бар!")

# Перевірити чи діалог пройдений
func is_dialogue_completed(dialogue_id: String) -> bool:
	return dialogue_id in completed_dialogues

# Перевірити чи говорили з персонажем
func has_talked_to(character_name: String) -> bool:
	return character_name in talked_characters

# Отримати кількість пройдених персонажів
func get_completed_characters_count() -> int:
	return talked_characters.size()

# Скинути прогрес (для тестування)
func reset_progress() -> void:
	completed_dialogues.clear()
	talked_characters.clear()
	print("🔄 Прогрес скинуто")
	save_game_data()

# Отримати кількість спроб, що залишились
func get_conversations_left() -> int:
	return MAX_CONVERSATIONS - talked_characters.size()

## ==========================================
## ЗБЕРЕЖЕННЯ/ЗАВАНТАЖЕННЯ
## ==========================================

func save_game_data():
	"""Зберегти прогрес в файл"""
	var save_dict = {
		"completed_dialogues": completed_dialogues,
		"talked_characters": talked_characters
	}
	var file = FileAccess.open("user://save_game.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_dict))
		file.close()
		print("💾 Прогрес збережено.")
	else:
		push_error("❌ Не вдалося зберегти прогрес.")

func load_game_data():
	# Завантажити прогрес з файлу
	if FileAccess.file_exists("user://save_game.json"):
		var file = FileAccess.open("user://save_game.json", FileAccess.READ)
		if file:
			var content = file.get_as_text()
			file.close()
			var save_dict = JSON.parse_string(content)
			if save_dict:
				# Явне приведення типів з JSON Array -> Array[String]
				var loaded_dialogues = save_dict.get("completed_dialogues", [])
				var loaded_characters = save_dict.get("talked_characters", [])
				
				completed_dialogues.clear()
				talked_characters.clear()
				
				for item in loaded_dialogues:
					completed_dialogues.append(str(item))
				for item in loaded_characters:
					talked_characters.append(str(item))
				
				print("📂 Прогрес завантажено.")
				print("   Пройдені діалоги: ", completed_dialogues)
				print("   Поговорено з: ", talked_characters)
			else:
				push_error("❌ Помилка парсингу збережених даних.")
		else:
			push_error("❌ Не вдалося завантажити прогрес.")
	else:
		print("🆕 Нова гра: файл збереження не знайдено.")