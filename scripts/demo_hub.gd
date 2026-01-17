extends Control

## Головна сцена демо "4 друзі в барі"

var game_state: Node
var dialogue_resource: DialogueResource

func _ready():
	# Створюємо GameState - він буде доступний через поточну сцену
	game_state = preload("res://scripts/game_state.gd").new()
	game_state.name = "game_state"  # Назва для доступу в діалозі
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
	
	# Запускаємо діалог зі старту
	var dialogue_manager = Engine.get_singleton("DialogueManager")
	dialogue_manager.show_dialogue_balloon(dialogue_resource, "start", [game_state])
