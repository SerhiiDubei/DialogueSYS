extends Control

## Проста сцена тільки з діалогом - без візуалізації

var game_state: Node
var dialogue_resource: DialogueResource

func _ready():
	# Створюємо GameState
	game_state = preload("res://scripts/game_state.gd").new()
	game_state.name = "game_state"
	add_child(game_state)
	
	# Завантажуємо діалоговий ресурс
	dialogue_resource = load("res://dialogue/demo.dialogue")
	
	if not dialogue_resource:
		push_error("Не вдалося завантажити res://dialogue/demo.dialogue")
		return
	
	# Чекаємо, поки DialogueManager буде готовий
	await get_tree().process_frame
	
	if not Engine.has_singleton("DialogueManager"):
		push_error("DialogueManager не знайдено! Увімкніть плагін в Project Settings -> Plugins")
		return
	
	var dialogue_manager = Engine.get_singleton("DialogueManager")
	
	# Використовуємо кастомний balloon напряму
	var balloon_path = "res://ui/balloon.tscn"
	if ResourceLoader.exists(balloon_path):
		print("Використовую кастомний balloon: ", balloon_path)
		# Запускаємо діалог з кастомним balloon
		dialogue_manager.show_dialogue_balloon_scene(balloon_path, dialogue_resource, "main_menu", [game_state])
	else:
		push_error("Файл balloon.tscn не знайдено: " + balloon_path)
		# Fallback на стандартний balloon
		dialogue_manager.show_dialogue_balloon(dialogue_resource, "main_menu", [game_state])
