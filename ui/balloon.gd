extends CanvasLayer
## A basic dialogue balloon for use with Dialogue Manager.
## Використовує класи для різних типів діалогів: MainMenuBalloon, RegularDialogueBalloon


## The dialogue resource
@export var dialogue_resource: DialogueResource

## Start from a given title when using balloon as a [Node] in a scene.
@export var start_from_title: String = ""

## If running as a [Node] in a scene then auto start the dialogue.
@export var auto_start: bool = false

## The action to use for advancing the dialogue
@export var next_action: StringName = &"ui_accept"

## The action to use to skip typing the dialogue
@export var skip_action: StringName = &"ui_cancel"

## A sound player for voice lines (if they exist).
@onready var audio_stream_player: AudioStreamPlayer = %AudioStreamPlayer

## Temporary game states
var temporary_game_states: Array = []

## See if we are waiting for the player
var is_waiting_for_input: bool = false

## See if we are running a long mutation and should hide the balloon
var will_hide_balloon: bool = false

## A dictionary to store any ephemeral variables
var locals: Dictionary = {}

var _locale: String = TranslationServer.get_locale()

## Поточний title діалогу (для визначення стилю)
var current_dialogue_title: String = ""

## Тип діалогу (визначає стиль)
enum DialogueType {
	MAIN_MENU,           # Головне меню - синій стиль
	CHARACTER_SELECTION, # Вибір персонажа - зелений стиль
	DIALOGUE             # Звичайний діалог - червоний стиль
}

var dialogue_type: DialogueType = DialogueType.DIALOGUE

## The current line
var dialogue_line: DialogueLine:
	set(value):
		if value:
			dialogue_line = value
			apply_dialogue_line()
		else:
			# The dialogue has finished so close the balloon
			if owner == null:
				queue_free()
			else:
				hide()
	get:
		return dialogue_line

## A cooldown timer for delaying the balloon hide when encountering a mutation.
var mutation_cooldown: Timer = Timer.new()

## The base balloon anchor
@onready var balloon: Control = %Balloon

## The label showing the name of the currently speaking character
@onready var character_label: RichTextLabel = %CharacterLabel

## The label showing the currently spoken dialogue
@onready var dialogue_label: DialogueLabel = %DialogueLabel

## The menu of responses
@onready var responses_menu: DialogueResponsesMenu = %ResponsesMenu

## Indicator to show that player can progress dialogue.
@onready var progress: Polygon2D = %Progress


func _ready() -> void:
	balloon.hide()
	Engine.get_singleton("DialogueManager").mutated.connect(_on_mutated)

	# If the responses menu doesn't have a next action set, use this one
	if responses_menu.next_action.is_empty():
		responses_menu.next_action = next_action

	mutation_cooldown.timeout.connect(_on_mutation_cooldown_timeout)
	add_child(mutation_cooldown)
	
	# Налаштування кольорів контейнерів (викликаємо після того, як всі елементи готові)
	# За замовчуванням використовуємо червоний стиль (DIALOGUE)
	call_deferred("_setup_colors_by_type")

	if auto_start:
		if not is_instance_valid(dialogue_resource):
			assert(false, DMConstants.get_error_message(DMConstants.ERR_MISSING_RESOURCE_FOR_AUTOSTART))
		start()


## Налаштування кольорів UI контейнерів на основі типу діалогу
func _setup_colors_by_type() -> void:
	_setup_colors_for_type(dialogue_type)

## Налаштування кольорів UI контейнерів для конкретного типу
func _setup_colors_for_type(type: DialogueType) -> void:
	# Визначаємо колір ободка залежно від типу
	var border_color: Color
	var bg_color: Color
	var type_name: String
	
	if type == DialogueType.MAIN_MENU:
		# СИНІЙ стиль для головного меню
		border_color = Color(0.2, 0.5, 1.0, 1.0)  # Яскраво-синій
		bg_color = Color(0.1, 0.15, 0.25, 1.0)  # Темно-синій фон
		type_name = "ГОЛОВНОГО МЕНЮ (синій)"
	elif type == DialogueType.CHARACTER_SELECTION:
		# ЗЕЛЕНИЙ стиль для вибору персонажа
		border_color = Color(0.2, 1.0, 0.5, 1.0)  # Яскраво-зелений
		bg_color = Color(0.1, 0.25, 0.15, 1.0)  # Темно-зелений фон
		type_name = "ВИБОРУ ПЕРСОНАЖА (зелений)"
	else:
		# ЧЕРВОНИЙ стиль для звичайних діалогів
		border_color = Color(1, 0, 0, 1)  # Червоний
		bg_color = Color(0.2, 0.2, 0.3, 1.0)  # Темний фон
		type_name = "ДІАЛОГУ (червоний)"
	
	print("Налаштування кольорів для ", type_name, "...")  # Debug
	
	# Змінити колір тексту імені персонажа
	if character_label:
		if type == DialogueType.MAIN_MENU:
			character_label.modulate = Color(0.7, 0.9, 1.0, 1.0)  # Світло-синій для меню
		elif type == DialogueType.CHARACTER_SELECTION:
			character_label.modulate = Color(0.7, 1.0, 0.85, 1.0)  # Світло-зелений для вибору персонажа
		else:
			character_label.modulate = Color(1, 1, 1, 0.8)  # Білий з прозорістю
	
	# Змінити колір фону PanelContainer
	var panel_container = balloon.get_node_or_null("MarginContainer/PanelContainer")
	if panel_container and panel_container is PanelContainer:
		print("Знайдено PanelContainer, змінюю колір...")  # Debug
		var style_box = StyleBoxFlat.new()
		style_box.bg_color = bg_color  # Фон залежно від типу діалогу
		style_box.border_color = border_color  # Колір рамки залежно від типу діалогу
		style_box.border_width_left = 3
		style_box.border_width_top = 3
		style_box.border_width_right = 3
		style_box.border_width_bottom = 3
		style_box.corner_radius_top_left = 10
		style_box.corner_radius_top_right = 10
		style_box.corner_radius_bottom_right = 10
		style_box.corner_radius_bottom_left = 10
		panel_container.add_theme_stylebox_override("panel", style_box)
	
	# Змінити колір індикатора Progress
	if progress:
		if type == DialogueType.MAIN_MENU:
			progress.color = Color(0.7, 0.9, 1.0, 0.8)  # Світло-синій для меню
		elif type == DialogueType.CHARACTER_SELECTION:
			progress.color = Color(0.7, 1.0, 0.85, 0.8)  # Світло-зелений для вибору персонажа
		else:
			progress.color = Color(1, 1, 1, 0.8)  # Білий індикатор
	
	# Визначаємо кольори для кнопок
	var bg_color_normal: Color
	var bg_color_hover: Color
	var bg_color_disabled: Color
	
	if type == DialogueType.MAIN_MENU:
		bg_color_normal = Color(0.15, 0.25, 0.4, 1)  # Темно-синій для меню
		bg_color_hover = Color(0.25, 0.35, 0.5, 1)  # Світліший синій для меню
		bg_color_disabled = Color(0.08, 0.12, 0.2, 1)  # Дуже темний синій для меню
	elif type == DialogueType.CHARACTER_SELECTION:
		bg_color_normal = Color(0.15, 0.3, 0.2, 1)  # Темно-зелений для вибору персонажа
		bg_color_hover = Color(0.2, 0.4, 0.3, 1)  # Світліший зелений при наведенні
		bg_color_disabled = Color(0.08, 0.15, 0.1, 1)  # Дуже темний зелений
	else:
		bg_color_normal = Color(0.2, 0.2, 0.3, 1)  # Темний фон кнопки
		bg_color_hover = Color(0.3, 0.3, 0.4, 1)  # Світліший при наведенні
		bg_color_disabled = Color(0.1, 0.1, 0.15, 1)  # Дуже темний
	
	# Змінити кольори кнопок відповідей
	var button_style_normal = StyleBoxFlat.new()
	button_style_normal.bg_color = bg_color_normal
	button_style_normal.border_color = border_color
	button_style_normal.border_width_left = 2
	button_style_normal.border_width_top = 2
	button_style_normal.border_width_right = 2
	button_style_normal.border_width_bottom = 2
	button_style_normal.corner_radius_top_left = 5
	button_style_normal.corner_radius_top_right = 5
	button_style_normal.corner_radius_bottom_right = 5
	button_style_normal.corner_radius_bottom_left = 5
	
	var button_style_hover = StyleBoxFlat.new()
	button_style_hover.bg_color = bg_color_hover
	button_style_hover.border_color = border_color
	button_style_hover.border_width_left = 2
	button_style_hover.border_width_top = 2
	button_style_hover.border_width_right = 2
	button_style_hover.border_width_bottom = 2
	button_style_hover.corner_radius_top_left = 5
	button_style_hover.corner_radius_top_right = 5
	button_style_hover.corner_radius_bottom_right = 5
	button_style_hover.corner_radius_bottom_left = 5
	
	var button_style_focus = StyleBoxFlat.new()
	button_style_focus.bg_color = bg_color_hover  # Такий самий як hover
	button_style_focus.border_color = border_color
	button_style_focus.border_width_left = 2
	button_style_focus.border_width_top = 2
	button_style_focus.border_width_right = 2
	button_style_focus.border_width_bottom = 2
	button_style_focus.corner_radius_top_left = 5
	button_style_focus.corner_radius_top_right = 5
	button_style_focus.corner_radius_bottom_right = 5
	button_style_focus.corner_radius_bottom_left = 5
	
	var button_style_disabled = StyleBoxFlat.new()
	button_style_disabled.bg_color = bg_color_disabled
	button_style_disabled.border_color = border_color
	button_style_disabled.border_width_left = 2
	button_style_disabled.border_width_top = 2
	button_style_disabled.border_width_right = 2
	button_style_disabled.border_width_bottom = 2
	button_style_disabled.corner_radius_top_left = 5
	button_style_disabled.corner_radius_top_right = 5
	button_style_disabled.corner_radius_bottom_right = 5
	button_style_disabled.corner_radius_bottom_left = 5
	
	# Застосовуємо стилі кнопок через theme override
	# Правильний синтаксис для Godot 4: add_theme_stylebox_override("назва_стилю", style)
	if responses_menu:
		responses_menu.add_theme_stylebox_override("normal", button_style_normal)
		responses_menu.add_theme_stylebox_override("hover", button_style_hover)
		responses_menu.add_theme_stylebox_override("focus", button_style_focus)
		responses_menu.add_theme_stylebox_override("disabled", button_style_disabled)
	
	# Також застосовуємо до balloon для успадкування
	balloon.add_theme_stylebox_override("normal", button_style_normal)
	balloon.add_theme_stylebox_override("hover", button_style_hover)
	balloon.add_theme_stylebox_override("focus", button_style_focus)
	balloon.add_theme_stylebox_override("disabled", button_style_disabled)
	
	print("Кольори налаштовано! Стиль для ", type_name, " встановлено.")  # Debug


## Застосовує стилі до всіх кнопок відповідей
func _apply_button_styles() -> void:
	if not responses_menu:
		return
	
	# Визначаємо колір ободка залежно від типу діалогу
	var border_color: Color
	var bg_color_normal: Color
	var bg_color_hover: Color
	var bg_color_disabled: Color
	
	if dialogue_type == DialogueType.MAIN_MENU:
		# СИНІЙ стиль для головного меню
		border_color = Color(0.2, 0.5, 1.0, 1.0)  # Яскраво-синій
		bg_color_normal = Color(0.15, 0.25, 0.4, 1)
		bg_color_hover = Color(0.25, 0.35, 0.5, 1)
		bg_color_disabled = Color(0.08, 0.12, 0.2, 1)
	elif dialogue_type == DialogueType.CHARACTER_SELECTION:
		# ЗЕЛЕНИЙ стиль для вибору персонажа
		border_color = Color(0.2, 1.0, 0.5, 1.0)  # Яскраво-зелений
		bg_color_normal = Color(0.15, 0.3, 0.2, 1)
		bg_color_hover = Color(0.2, 0.4, 0.3, 1)
		bg_color_disabled = Color(0.08, 0.15, 0.1, 1)
	else:
		# ЧЕРВОНИЙ стиль для звичайних діалогів
		border_color = Color(1, 0, 0, 1)  # Червоний
		bg_color_normal = Color(0.2, 0.2, 0.3, 1)
		bg_color_hover = Color(0.3, 0.3, 0.4, 1)
		bg_color_disabled = Color(0.1, 0.1, 0.15, 1)
	
	# Створюємо стилі для кнопок
	var button_style_normal = StyleBoxFlat.new()
	button_style_normal.bg_color = bg_color_normal
	button_style_normal.border_color = border_color
	button_style_normal.border_width_left = 2
	button_style_normal.border_width_top = 2
	button_style_normal.border_width_right = 2
	button_style_normal.border_width_bottom = 2
	button_style_normal.corner_radius_top_left = 5
	button_style_normal.corner_radius_top_right = 5
	button_style_normal.corner_radius_bottom_right = 5
	button_style_normal.corner_radius_bottom_left = 5
	
	var button_style_hover = StyleBoxFlat.new()
	button_style_hover.bg_color = bg_color_hover
	button_style_hover.border_color = border_color
	button_style_hover.border_width_left = 2
	button_style_hover.border_width_top = 2
	button_style_hover.border_width_right = 2
	button_style_hover.border_width_bottom = 2
	button_style_hover.corner_radius_top_left = 5
	button_style_hover.corner_radius_top_right = 5
	button_style_hover.corner_radius_bottom_right = 5
	button_style_hover.corner_radius_bottom_left = 5
	
	var button_style_focus = StyleBoxFlat.new()
	button_style_focus.bg_color = bg_color_hover  # Такий самий як hover
	button_style_focus.border_color = border_color
	button_style_focus.border_width_left = 2
	button_style_focus.border_width_top = 2
	button_style_focus.border_width_right = 2
	button_style_focus.border_width_bottom = 2
	button_style_focus.corner_radius_top_left = 5
	button_style_focus.corner_radius_top_right = 5
	button_style_focus.corner_radius_bottom_right = 5
	button_style_focus.corner_radius_bottom_left = 5
	
	var button_style_disabled = StyleBoxFlat.new()
	button_style_disabled.bg_color = bg_color_disabled
	button_style_disabled.border_color = border_color
	button_style_disabled.border_width_left = 2
	button_style_disabled.border_width_top = 2
	button_style_disabled.border_width_right = 2
	button_style_disabled.border_width_bottom = 2
	button_style_disabled.corner_radius_top_left = 5
	button_style_disabled.corner_radius_top_right = 5
	button_style_disabled.corner_radius_bottom_right = 5
	button_style_disabled.corner_radius_bottom_left = 5
	
	# Застосовуємо стилі до всіх кнопок у меню відповідей
	for child in responses_menu.get_children():
		if child is Button:
			child.add_theme_stylebox_override("normal", button_style_normal)
			child.add_theme_stylebox_override("hover", button_style_hover)
			child.add_theme_stylebox_override("focus", button_style_focus)
			child.add_theme_stylebox_override("disabled", button_style_disabled)
			var color_name = "СИНІЙ" if dialogue_type == DialogueType.MAIN_MENU else ("ЗЕЛЕНИЙ" if dialogue_type == DialogueType.CHARACTER_SELECTION else "ЧЕРВОНИЙ")
			print("Застосовано %s ободок до кнопки: %s" % [color_name, child.name])  # Debug
	
	print("Стилі кнопок застосовано!")  # Debug


func _process(delta: float) -> void:
	if is_instance_valid(dialogue_line):
		progress.visible = not dialogue_label.is_typing and dialogue_line.responses.size() == 0 and not dialogue_line.has_tag("voice")


func _unhandled_input(_event: InputEvent) -> void:
	# Only the balloon is allowed to handle input while it's showing
	get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	## Detect a change of locale and update the current dialogue line to show the new language
	if what == NOTIFICATION_TRANSLATION_CHANGED and _locale != TranslationServer.get_locale() and is_instance_valid(dialogue_label):
		_locale = TranslationServer.get_locale()
		var visible_ratio: float = dialogue_label.visible_ratio
		dialogue_line = await dialogue_resource.get_next_dialogue_line(dialogue_line.id)
		if visible_ratio < 1:
			dialogue_label.skip_typing()


## Start some dialogue
func start(with_dialogue_resource: DialogueResource = null, title: String = "", extra_game_states: Array = []) -> void:
	temporary_game_states = [self] + extra_game_states
	is_waiting_for_input = false
	if is_instance_valid(with_dialogue_resource):
		dialogue_resource = with_dialogue_resource
	if not title.is_empty():
		start_from_title = title
		current_dialogue_title = title  # Зберігаємо поточний title для визначення стилю
		
		# DEBUG: Показуємо який title прийшов
		print("🎯 Запуск діалогу з title: '", title, "'")
		
		# Визначаємо тип діалогу на основі title
		if title == "main_menu":
			dialogue_type = DialogueType.MAIN_MENU
			print("   → Тип: MAIN_MENU (синій)")
		elif title == "hub" or title.begins_with("talk_"):
			# Якщо це hub або розмова з персонажем - це вибір персонажа
			dialogue_type = DialogueType.CHARACTER_SELECTION
			print("   → Тип: CHARACTER_SELECTION (зелений)")
		else:
			dialogue_type = DialogueType.DIALOGUE
			print("   → Тип: DIALOGUE (червоний)")
		
		# Оновлюємо стиль залежно від типу
		call_deferred("_setup_colors_by_type")
	dialogue_line = await dialogue_resource.get_next_dialogue_line(start_from_title, temporary_game_states)
	show()


## Apply any changes to the balloon given a new [DialogueLine].
func apply_dialogue_line() -> void:
	mutation_cooldown.stop()

	progress.hide()
	is_waiting_for_input = false
	balloon.focus_mode = Control.FOCUS_ALL
	balloon.grab_focus()

	character_label.visible = not dialogue_line.character.is_empty()
	character_label.text = tr(dialogue_line.character, "dialogue")

	dialogue_label.hide()
	dialogue_label.dialogue_line = dialogue_line

	responses_menu.hide()
	responses_menu.responses = dialogue_line.responses
	
	# Оновлюємо тип діалогу на основі поточного dialogue_line
	# Якщо current_dialogue_title ще не встановлений, використовуємо логіку визначення
	# Але НЕ змінюємо dialogue_type, якщо він вже встановлений (з start())
	if current_dialogue_title.is_empty() and dialogue_type == DialogueType.DIALOGUE:
		# За замовчуванням вважаємо, що це звичайний діалог (не main_menu)
		current_dialogue_title = "other"
		# dialogue_type вже DIALOGUE за замовчуванням, тому не змінюємо
		call_deferred("_setup_colors_by_type")
	
	# Застосовуємо стилі до нових кнопок після їх створення
	await get_tree().process_frame
	_apply_button_styles()

	# Show our balloon
	balloon.show()
	will_hide_balloon = false

	dialogue_label.show()
	if not dialogue_line.text.is_empty():
		dialogue_label.type_out()
		await dialogue_label.finished_typing

	# Wait for next line
	if dialogue_line.has_tag("voice"):
		audio_stream_player.stream = load(dialogue_line.get_tag_value("voice"))
		audio_stream_player.play()
		await audio_stream_player.finished
		next(dialogue_line.next_id)
	elif dialogue_line.responses.size() > 0:
		balloon.focus_mode = Control.FOCUS_NONE
		responses_menu.show()
		# Застосовуємо стилі до кнопок після показу меню
		await get_tree().process_frame
		_apply_button_styles()
	elif dialogue_line.time != "":
		var time: float = dialogue_line.text.length() * 0.02 if dialogue_line.time == "auto" else dialogue_line.time.to_float()
		await get_tree().create_timer(time).timeout
		next(dialogue_line.next_id)
	else:
		is_waiting_for_input = true
		balloon.focus_mode = Control.FOCUS_ALL
		balloon.grab_focus()


## Go to the next line
func next(next_id: String) -> void:
	# Оновлюємо тип діалогу перед переходом до наступної лінії
	if next_id == "main_menu" or (next_id != "" and "main_menu" in next_id and next_id != "END" and next_id != "NULL"):
		current_dialogue_title = "main_menu"
		dialogue_type = DialogueType.MAIN_MENU
		call_deferred("_setup_colors_by_type")
	elif next_id == "hub" or "talk_" in next_id:
		# Якщо це hub або розмова з персонажем - це вибір персонажа
		current_dialogue_title = next_id
		dialogue_type = DialogueType.CHARACTER_SELECTION
		call_deferred("_setup_colors_by_type")
	elif next_id != "" and next_id != "END" and next_id != "NULL":
		# Якщо next_id веде до іншого title (не main_menu), це звичайний діалог
		current_dialogue_title = "other"
		dialogue_type = DialogueType.DIALOGUE
		call_deferred("_setup_colors_by_type")
	
	dialogue_line = await dialogue_resource.get_next_dialogue_line(next_id, temporary_game_states)


#region Signals


func _on_mutation_cooldown_timeout() -> void:
	if will_hide_balloon:
		will_hide_balloon = false
		balloon.hide()


func _on_mutated(_mutation: Dictionary) -> void:
	if not _mutation.is_inline:
		is_waiting_for_input = false
		will_hide_balloon = true
		mutation_cooldown.start(0.1)


func _on_balloon_gui_input(event: InputEvent) -> void:
	# See if we need to skip typing of the dialogue
	if dialogue_label.is_typing:
		var mouse_was_clicked: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed()
		var skip_button_was_pressed: bool = event.is_action_pressed(skip_action)
		if mouse_was_clicked or skip_button_was_pressed:
			get_viewport().set_input_as_handled()
			dialogue_label.skip_typing()
			return

	if not is_waiting_for_input: return
	if dialogue_line.responses.size() > 0: return

	# When there are no response options the balloon itself is the clickable thing
	get_viewport().set_input_as_handled()

	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		next(dialogue_line.next_id)
	elif event.is_action_pressed(next_action) and get_viewport().gui_get_focus_owner() == balloon:
		next(dialogue_line.next_id)


func _on_responses_menu_response_selected(response: DialogueResponse) -> void:
	next(response.next_id)


#endregion
