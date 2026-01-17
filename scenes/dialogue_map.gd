extends Control
## Проста карта діалогів - без зайвих плагінів

@onready var main_menu_btn: Button = $VBoxContainer/MainMenuBtn
@onready var persha_proba_btn: Button = $VBoxContainer/PershaProbaBnt
@onready var dzhin_tolik_btn: Button = $VBoxContainer/DzhinTolikBtn
@onready var background: ColorRect = $Background
@onready var title_label: Label = $Title
@onready var vbox: VBoxContainer = $VBoxContainer

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
	
	# Підключаємося до сигналу завершення діалогу
	if Engine.has_singleton("DialogueManager"):
		var dialogue_manager = Engine.get_singleton("DialogueManager")
		dialogue_manager.dialogue_ended.connect(_on_dialogue_ended)
	
	print("Карта діалогів готова!")

func start_dialogue(title: String):
	if not Engine.has_singleton("DialogueManager"):
		push_error("DialogueManager не знайдено!")
		return
	
	# Ховаємо меню під час діалогу
	hide_menu()
	
	var dialogue_manager = Engine.get_singleton("DialogueManager")
	var balloon_path = "res://ui/balloon.tscn"
	
	if ResourceLoader.exists(balloon_path):
		print("Запускаю діалог: ", title)
		dialogue_manager.show_dialogue_balloon_scene(balloon_path, dialogue_resource, title, [game_state])
	else:
		push_error("Файл balloon.tscn не знайдено: " + balloon_path)
		# Якщо діалог не запустився, показуємо меню назад
		show_menu()

func hide_menu():
	background.visible = false
	title_label.visible = false
	vbox.visible = false

func show_menu():
	background.visible = true
	title_label.visible = true
	vbox.visible = true

func _on_dialogue_ended(_resource: DialogueResource):
	# Показуємо меню після завершення діалогу
	show_menu()