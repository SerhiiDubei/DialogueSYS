extends Control

func _ready():
	# Чекаємо, поки DialogueManager буде готовий
	await get_tree().process_frame
	
	if not Engine.has_singleton("DialogueManager"):
		push_error("DialogueManager не знайдено! Увімкніть плагін в Project Settings -> Plugins")
		return
	
	var dialogue_manager = Engine.get_singleton("DialogueManager")
	
	# Спробуємо завантажити .tres, якщо не вийде - завантажимо .dialogue напряму
	var resource = null
	if ResourceLoader.exists("res://demo_dialogue.dialogue.tres"):
		resource = load("res://demo_dialogue.dialogue.tres")
	else:
		# Завантажуємо .dialogue напряму - Godot автоматично скомпілює
		if ResourceLoader.exists("res://demo_dialogue.dialogue"):
			resource = load("res://demo_dialogue.dialogue")
	
	if resource:
		dialogue_manager.show_dialogue_balloon(resource, "start")
	else:
		push_error("Не вдалося завантажити діалоговий ресурс!")
		push_error("Переконайтеся, що файл demo_dialogue.dialogue існує і відкритий в Godot Editor")
