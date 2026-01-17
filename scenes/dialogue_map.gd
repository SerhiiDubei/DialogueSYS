extends Control
## Лінійна карта діалогів - візуалізація та навігація між діалогами

@onready var worldmap_view: WorldmapView = $WorldmapView
@onready var dialogue_graph: WorldmapGraph = $WorldmapView/DialogueGraph
@onready var current_dialogue_label: Label = $UI/CurrentDialogue
@onready var start_button: Button = $UI/StartButton

var game_state: Node
var dialogue_resource: DialogueResource

# Мапа: індекс вузла -> назва діалогу
var node_to_dialogue: Dictionary = {
	0: "main_menu",
	1: "перша_проба",
	2: "джин_толік"
}

# Мапа: назва діалогу -> індекс вузла
var dialogue_to_node: Dictionary = {}

func _ready():
	# Ініціалізуємо зворотну мапу
	for node_idx in node_to_dialogue:
		dialogue_to_node[node_to_dialogue[node_idx]] = node_idx
	
	# Створюємо GameState
	game_state = preload("res://scripts/game_state.gd").new()
	game_state.name = "game_state"
	add_child(game_state)
	
	# Завантажуємо діалоговий ресурс
	dialogue_resource = load("res://dialogue/demo.dialogue")
	
	if not dialogue_resource:
		push_error("Не вдалося завантажити res://dialogue/demo.dialogue")
		return
	
	# Налаштовуємо карту
	setup_dialogue_map()
	
	# Підключаємо сигнали
	start_button.pressed.connect(_on_start_button_pressed)
	worldmap_view.node_gui_input.connect(_on_node_clicked)
	worldmap_view.node_mouse_entered.connect(_on_node_hovered)
	worldmap_view.node_mouse_exited.connect(_on_node_exited)

func setup_dialogue_map():
	# Створюємо вузли для кожного діалогу
	# Лінійна структура: main_menu -> перша_проба -> джин_толік
	
	# Створюємо WorldmapNodeData для кожного вузла
	var node_data_0 = WorldmapNodeData.new()
	node_data_0.name = "Головне меню"
	node_data_0.id = "main_menu"
	node_data_0.cost = 1.0
	
	var node_data_1 = WorldmapNodeData.new()
	node_data_1.name = "Перша проба"
	node_data_1.id = "перша_проба"
	node_data_1.cost = 1.0
	
	var node_data_2 = WorldmapNodeData.new()
	node_data_2.name = "Джин Толік"
	node_data_2.id = "джин_толік"
	node_data_2.cost = 1.0
	
	# Встановлюємо кількість вузлів
	dialogue_graph.set("node_count", 3)
	
	# Встановлюємо дані та позиції для кожного вузла
	dialogue_graph.set("node_0/data", node_data_0)
	dialogue_graph.set("node_0/position", Vector2(200, 300))
	
	dialogue_graph.set("node_1/data", node_data_1)
	dialogue_graph.set("node_1/position", Vector2(500, 300))
	
	dialogue_graph.set("node_2/data", node_data_2)
	dialogue_graph.set("node_2/position", Vector2(800, 300))
	
	# Встановлюємо кількість з'єднань
	dialogue_graph.set("connection_count", 2)
	
	# З'єднуємо вузли лінійно (0 -> 1 -> 2)
	dialogue_graph.set("connection_0/nodes", Vector2i(0, 1))  # main_menu -> перша_проба
	dialogue_graph.set("connection_0/costs", Vector2(1, INF))  # Односторонній зв'язок
	
	dialogue_graph.set("connection_1/nodes", Vector2i(1, 2))  # перша_проба -> джин_толік
	dialogue_graph.set("connection_1/costs", Vector2(1, INF))  # Односторонній зв'язок
	
	# Оновлюємо відображення
	dialogue_graph.queue_redraw()
	worldmap_view.queue_redraw()
	
	print("Карта діалогів створена:")
	print("  0: main_menu (Головне меню)")
	print("  1: перша_проба (Перша проба)")
	print("  2: джин_толік (Джин Толік)")

func _on_node_clicked(event: InputEvent, path: NodePath, node_index: int, resource: WorldmapNodeData):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# Клік по вузлу - запускаємо діалог
		if node_index in node_to_dialogue:
			var dialogue_title = node_to_dialogue[node_index]
			start_dialogue(dialogue_title)

func _on_node_hovered(path: NodePath, node_index: int, resource: WorldmapNodeData):
	# Показуємо назву діалогу при наведенні
	if node_index in node_to_dialogue:
		var dialogue_title = node_to_dialogue[node_index]
		current_dialogue_label.text = "Поточний діалог: " + dialogue_title

func _on_node_exited(path: NodePath, node_index: int, resource: WorldmapNodeData):
	# Очищаємо текст при виході
	current_dialogue_label.text = "Поточний діалог: -"

func _on_start_button_pressed():
	# Запускаємо діалог з головного меню
	start_dialogue("main_menu")

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
