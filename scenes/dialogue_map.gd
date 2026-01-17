extends Control
## Проста карта діалогів - без зайвих плагінів

@onready var main_menu_btn: Button = $VBoxContainer/MainMenuBtn
@onready var persha_proba_btn: Button = $VBoxContainer/PershaProbaBnt
@onready var dzhin_tolik_btn: Button = $VBoxContainer/DzhinTolikBtn

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
	
	# Підключаємо кнопки
	main_menu_btn.pressed.connect(func(): start_dialogue("main_menu"))
	persha_proba_btn.pressed.connect(func(): start_dialogue("перша_проба"))
	dzhin_tolik_btn.pressed.connect(func(): start_dialogue("джин_толік"))
	
	print("Карта діалогів готова!")

func start_dialogue(title: String):
	if not Engine.has_singleton("DialogueManager"):
		push_error("DialogueManager не знайдено!")
		return
	
	var dialogue_manager = Engine.get_singleton("DialogueManager")
	var balloon_path = "res://ui/balloon.tscn"
	
	if ResourceLoader.exists(balloon_path):
		print("Запускаю діалог: ", title)
		dialogue_manager.show_dialogue_balloon_scene(balloon_path, dialogue_resource, title, [game_state])
	else:
		push_error("Файл balloon.tscn не знайдено: " + balloon_path)
