extends Node
## РЎРёСЃС‚РµРјР° Р·Р±РµСЂРµР¶РµРЅРЅСЏ РїСЂРѕРіСЂРµСЃСѓ РґС–Р°Р»РѕРіС–РІ
## вљ пёЏ Autoload СЃРєСЂРёРїС‚ - РќР• РІРёРєРѕСЂРёСЃС‚РѕРІСѓР№ class_name!

# вљ пёЏ Р›Р†РњР†Рў: РјРѕР¶РЅР° РіРѕРІРѕСЂРёС‚Рё С‚С–Р»СЊРєРё Р· 2 РїРµСЂСЃРѕРЅР°Р¶Р°РјРё Р· 4!
const MAX_CONVERSATIONS: int = 2

# РџСЂРѕР№РґРµРЅС– РґС–Р°Р»РѕРіРё
var completed_dialogues: Array[String] = []

# РџРµСЂСЃРѕРЅР°Р¶С–, Р· СЏРєРёРјРё РїРѕРіРѕРІРѕСЂРёР»Рё
var talked_characters: Array[String] = []

func _ready():
	load_game_data()
	print("вњ… SaveSystem РіРѕС‚РѕРІРёР№!")

# Р§Рё РґРѕСЃСЏРіРЅСѓС‚Рѕ Р»С–РјС–С‚ СЂРѕР·РјРѕРІ (2 Р· 4)
func all_characters_completed() -> bool:
	return talked_characters.size() >= MAX_CONVERSATIONS

# Р§Рё С” С‰Рµ СЃРїСЂРѕР±Рё РґР»СЏ СЂРѕР·РјРѕРІ?
func has_conversations_left() -> bool:
	return talked_characters.size() < MAX_CONVERSATIONS

# Р§Рё РјРѕР¶РЅР° РіРѕРІРѕСЂРёС‚Рё Р· РЅРѕРІРёРј РїРµСЂСЃРѕРЅР°Р¶РµРј?
func can_talk_to_new_character() -> bool:
	return has_conversations_left()

# Р’С–РґРјС–С‚РёС‚Рё РґС–Р°Р»РѕРі СЏРє РїСЂРѕР№РґРµРЅРёР№
func mark_dialogue_completed(dialogue_id: String) -> void:
	if not dialogue_id in completed_dialogues:
		completed_dialogues.append(dialogue_id)
		print("вњ… Р”С–Р°Р»РѕРі РїСЂРѕР№РґРµРЅРѕ: ", dialogue_id)
		save_game_data()

# Р’С–РґРјС–С‚РёС‚Рё РїРµСЂСЃРѕРЅР°Р¶Р° СЏРє РїСЂРѕР№РґРµРЅРѕРіРѕ
func mark_character_talked(character_name: String) -> void:
	if not character_name in talked_characters:
		talked_characters.append(character_name)
		print("вњ… РџРѕРіРѕРІРѕСЂРёР»Рё Р·: ", character_name, " (", talked_characters.size(), "/", MAX_CONVERSATIONS, ")")
		save_game_data()
		if all_characters_completed():
			print("вљ пёЏ Р›Р†РњР†Рў Р”РћРЎРЇР“РќРЈРўРћ! Р’РёРєРѕСЂРёСЃС‚Р°РЅРѕ РІСЃС– ", MAX_CONVERSATIONS, " СЃРїСЂРѕР±Рё. РњРѕР¶РЅР° Р№С‚Рё РІ Р±Р°СЂ!")

# РџРµСЂРµРІС–СЂРёС‚Рё С‡Рё РґС–Р°Р»РѕРі РїСЂРѕР№РґРµРЅРёР№
func is_dialogue_completed(dialogue_id: String) -> bool:
	return dialogue_id in completed_dialogues

# РџРµСЂРµРІС–СЂРёС‚Рё С‡Рё РіРѕРІРѕСЂРёР»Рё Р· РїРµСЂСЃРѕРЅР°Р¶РµРј
func has_talked_to(character_name: String) -> bool:
	return character_name in talked_characters

# РћС‚СЂРёРјР°С‚Рё РєС–Р»СЊРєС–СЃС‚СЊ РїСЂРѕР№РґРµРЅРёС… РїРµСЂСЃРѕРЅР°Р¶С–РІ
func get_completed_characters_count() -> int:
	return talked_characters.size()

# РћС‚СЂРёРјР°С‚Рё РєС–Р»СЊРєС–СЃС‚СЊ СЃРїСЂРѕР±, С‰Рѕ Р·Р°Р»РёС€РёР»РёСЃСЊ
func get_conversations_left() -> int:
	return MAX_CONVERSATIONS - talked_characters.size()

# РЎРєРёРЅСѓС‚Рё РїСЂРѕРіСЂРµСЃ (РґР»СЏ С‚РµСЃС‚СѓРІР°РЅРЅСЏ)
func reset_progress() -> void:
	completed_dialogues.clear()
	talked_characters.clear()
	print("рџ”„ РџСЂРѕРіСЂРµСЃ СЃРєРёРЅСѓС‚Рѕ")
	save_game_data()

func save_game_data():
	var save_dict = {
		"completed_dialogues": completed_dialogues,
		"talked_characters": talked_characters
	}
	var file = FileAccess.open("user://save_game.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_dict))
		file.close()
		print("рџ’ѕ РџСЂРѕРіСЂРµСЃ Р·Р±РµСЂРµР¶РµРЅРѕ.")
	else:
		push_error("вќЊ РќРµ РІРґР°Р»РѕСЃСЏ Р·Р±РµСЂРµРіС‚Рё РїСЂРѕРіСЂРµСЃ.")

func load_game_data():
	if FileAccess.file_exists("user://save_game.json"):
		var file = FileAccess.open("user://save_game.json", FileAccess.READ)
		if file:
			var content = file.get_as_text()
			file.close()
			var save_dict = JSON.parse_string(content)
			if save_dict:
				completed_dialogues = save_dict.get("completed_dialogues", [])
				talked_characters = save_dict.get("talked_characters", [])
				print("рџ“‚ РџСЂРѕРіСЂРµСЃ Р·Р°РІР°РЅС‚Р°Р¶РµРЅРѕ.")
				print("   РџСЂРѕР№РґРµРЅС– РґС–Р°Р»РѕРіРё: ", completed_dialogues)
				print("   РџРѕРіРѕРІРѕСЂРµРЅРѕ Р·: ", talked_characters)
			else:
				push_error("вќЊ РџРѕРјРёР»РєР° РїР°СЂСЃРёРЅРіСѓ Р·Р±РµСЂРµР¶РµРЅРёС… РґР°РЅРёС….")
		else:
			push_error("вќЊ РќРµ РІРґР°Р»РѕСЃСЏ Р·Р°РІР°РЅС‚Р°Р¶РёС‚Рё РїСЂРѕРіСЂРµСЃ.")
	else:
		print("рџ†• РќРѕРІР° РіСЂР°: С„Р°Р№Р» Р·Р±РµСЂРµР¶РµРЅРЅСЏ РЅРµ Р·РЅР°Р№РґРµРЅРѕ.")
