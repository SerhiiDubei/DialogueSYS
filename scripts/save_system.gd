extends Node
class_name SaveSystem
## Система збереження прогресу діалогів

# ⚠️ ЛІМІТ: можна говорити тільки з 2 персонажами з 4!
const MAX_CONVERSATIONS: int = 2

# Пройдені діалоги
var completed_dialogues: Array[String] = []

# Персонажі, з якими поговорили
var talked_characters: Array[String] = []

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
