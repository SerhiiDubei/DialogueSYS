extends Control
## UI Телефону (як iPhone)

## Вузли (будуть прив'язані в сцені)
@onready var search_bar: LineEdit = %SearchBar
@onready var tab_bar: TabBar = %TabBar
@onready var contact_list: VBoxContainer = %ContactList
@onready var call_screen: Panel = %CallScreen
@onready var call_photo: TextureRect = %CallPhoto
@onready var call_name: Label = %CallName
@onready var call_status: Label = %CallStatus
@onready var call_timer: Label = %CallTimer
@onready var hangup_button: Button = %HangupButton

## Шаблон для елементу контакту
var contact_entry_scene = preload("res://ui/contact_entry.tscn")

## Поточний режим
enum Tab { FAVORITES, RECENT, CONTACTS }
var current_tab: Tab = Tab.CONTACTS

## Поточний дзвінок
var current_contact: ContactResource = null
var call_timer_active: bool = false

func _ready():
	# З'єднати сигнали
	search_bar.text_changed.connect(_on_search_changed)
	tab_bar.tab_changed.connect(_on_tab_changed)
	hangup_button.pressed.connect(_on_hangup_pressed)
	
	PhoneSystemManager.call_started.connect(_on_call_started)
	PhoneSystemManager.call_ended.connect(_on_call_ended)
	PhoneSystemManager.contacts_loaded.connect(_refresh_list)
	
	# Ховати екран дзвінку
	call_screen.visible = false
	
	# Налаштувати вкладки
	tab_bar.add_tab("⭐ Обрані")
	tab_bar.add_tab("🕐 Недавні")
	tab_bar.add_tab("👥 Контакти")
	tab_bar.current_tab = 2  # Контакти за замовчуванням
	
	_refresh_list()

## ==========================================
## СПИСОК КОНТАКТІВ
## ==========================================

func _refresh_list():
	# Оновити список контактів
	# Очистити список
	for child in contact_list.get_children():
		child.queue_free()
	
	var contacts: Array[ContactResource] = []
	
	# Отримати контакти залежно від вкладки
	match current_tab:
		Tab.FAVORITES:
			contacts = PhoneSystemManager.get_favorites()
		Tab.RECENT:
			_show_recent_calls()
			return
		Tab.CONTACTS:
			var query = search_bar.text
			contacts = PhoneSystemManager.search_contacts(query)
	
	# Додати контакти в список
	for contact in contacts:
		_add_contact_entry(contact)
	
	# Якщо список порожній
	if contacts.is_empty():
		var label = Label.new()
		label.text = "Контактів не знайдено"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		contact_list.add_child(label)

func _add_contact_entry(contact: ContactResource):
	# Додати елемент контакту
	var entry = contact_entry_scene.instantiate()
	contact_list.add_child(entry)
	
	# Налаштувати елемент
	entry.setup(contact)
	entry.call_pressed.connect(func(): _on_contact_call_pressed(contact.id))

func _show_recent_calls():
	# Показати недавні дзвінки
	var recent = PhoneSystemManager.get_recent_contacts()
	
	if recent.is_empty():
		var label = Label.new()
		label.text = "Немає недавніх дзвінків"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		contact_list.add_child(label)
		return
	
	for call_data in recent:
		var contact_id = call_data.contact_id
		var contact = PhoneSystemManager.get_contact(contact_id)
		if !contact:
			continue
		
		var entry = contact_entry_scene.instantiate()
		contact_list.add_child(entry)
		entry.setup(contact, call_data)
		entry.call_pressed.connect(func(): _on_contact_call_pressed(contact_id))

## ==========================================
## ДЗВІНКИ
## ==========================================

func _on_contact_call_pressed(contact_id: String):
	# Натиснуто кнопку дзвінка
	if !PhoneSystemManager.can_call(contact_id):
		_show_error("Неможливо зателефонувати")
		return
	
	PhoneSystemManager.make_call(contact_id)

func _on_call_started(_contact_id: String, contact: ContactResource):
	# Дзвінок почався
	current_contact = contact
	
	# Показати екран дзвінка
	call_screen.visible = true
	call_photo.texture = contact.photo if contact.photo else null
	call_name.text = contact.display_name
	call_status.text = "Виклик..."
	call_timer.text = "00:00"
	
	# Обробити тип дзвінка
	match contact.call_type:
		0:  # NoAnswer
			_handle_no_answer()
		1:  # WrongNumber
			_handle_wrong_number()
		2:  # Quick
			_handle_quick_chat()
		3:  # Short
			_handle_short_dialogue()
		4:  # Full
			_handle_full_dialogue()
		5:  # MultiScene
			_handle_multi_scene_dialogue()

func _on_call_ended(_contact_id: String, _success: bool):
	# Дзвінок завершено
	call_timer_active = false
	await get_tree().create_timer(0.5).timeout
	call_screen.visible = false
	current_contact = null

func _on_hangup_pressed():
	# Покласти слухавку
	PhoneSystemManager.end_call(false)

## ==========================================
## ТИПИ ДЗВІНКІВ
## ==========================================

func _handle_no_answer():
	# Не відповідає
	await get_tree().create_timer(3.0).timeout
	call_status.text = "Абонент не відповідає"
	await get_tree().create_timer(2.0).timeout
	PhoneSystemManager.end_call(false)

func _handle_wrong_number():
	# Старий номер
	await get_tree().create_timer(2.0).timeout
	call_status.text = "Номер не обслуговується"
	await get_tree().create_timer(2.0).timeout
	PhoneSystemManager.end_call(false)

func _handle_quick_chat():
	# Швидкий чат
	call_status.text = "З'єднано"
	_start_call_timer()
	
	# Показати швидкі повідомлення
	if current_contact.quick_messages.is_empty():
		current_contact.quick_messages = [
			"Алло?",
			"Зайнятий, передзвоню!",
			"*Гудки*"
		]
	
	for message in current_contact.quick_messages:
		call_status.text = message
		await get_tree().create_timer(1.5).timeout
	
	PhoneSystemManager.end_call(true)

func _handle_short_dialogue():
	# Короткий діалог
	call_status.text = "З'єднано"
	_start_call_timer()
	
	if current_contact.dialogue_file.is_empty():
		_handle_quick_chat()  # Fallback
		return
	
	# Запустити діалог
	var dialogue = load(current_contact.dialogue_file)
	if dialogue:
		DialogueManager.show_example_dialogue_balloon(
			dialogue,
			current_contact.dialogue_start
		)
		await DialogueManager.dialogue_ended
	
	PhoneSystemManager.end_call(true)

func _handle_full_dialogue():
	# Повний діалог
	_handle_short_dialogue()  # Та сама логіка

func _handle_multi_scene_dialogue():
	# Багатосценний діалог
	call_status.text = "З'єднано"
	_start_call_timer()
	
	if current_contact.dialogue_file.is_empty():
		_handle_quick_chat()
		return
	
	# Запустити багатосценний діалог
	var dialogue = load(current_contact.dialogue_file)
	if !dialogue:
		PhoneSystemManager.end_call(false)
		return
	
	# 9 сцен (як приклад)
	var scenes = [
		"scene_1", "scene_2", "scene_3",
		"scene_4", "scene_5", "scene_6",
		"scene_7", "scene_8", "scene_9"
	]
	
	for i in range(scenes.size()):
		# Показати індикатор сцени
		call_timer.text = "Частина %d/%d" % [i + 1, scenes.size()]
		
		# Запустити сцену
		DialogueManager.show_example_dialogue_balloon(
			dialogue,
			scenes[i]
		)
		await DialogueManager.dialogue_ended
		
		# Пауза між сценами
		if i < scenes.size() - 1:
			await get_tree().create_timer(0.5).timeout
	
	PhoneSystemManager.end_call(true)

## ==========================================
## ТАЙМЕР ДЗВІНКА
## ==========================================

func _start_call_timer():
	# Запустити таймер дзвінка
	call_timer_active = true
	_update_call_timer()

func _update_call_timer():
	# Оновити таймер
	var elapsed = 0
	while call_timer_active:
		var minutes = elapsed / 60
		var seconds = elapsed % 60
		call_timer.text = "%02d:%02d" % [minutes, seconds]
		await get_tree().create_timer(1.0).timeout
		elapsed += 1

## ==========================================
## ПОДІЇ UI
## ==========================================

func _on_search_changed(_new_text: String):
	# Пошук змінився
	_refresh_list()

func _on_tab_changed(tab: int):
	# Вкладка змінилась
	current_tab = tab as Tab
	_refresh_list()

func _show_error(message: String):
	# Показати помилку
	# TODO: Додати UI для помилок
	print("❌ ", message)

## ==========================================
## ПУБЛІЧНІ МЕТОДИ
## ==========================================

func open_phone():
	# Відкрити телефон
	visible = true

func close_phone():
	# Закрити телефон
	visible = false
	# Якщо йде дзвінок - завершити
	if !PhoneSystemManager.current_call_id.is_empty():
		PhoneSystemManager.end_call(false)
