extends Control
## UI Телефону (як iPhone)

## Вузли (будуть прив'язані в сцені)
@onready var phone_panel: Panel = $PhonePanel
@onready var search_bar: LineEdit = %SearchBar
@onready var tab_bar: TabBar = %TabBar
@onready var contact_list: VBoxContainer = %ContactList
@onready var call_screen: Panel = %CallScreen
@onready var call_photo: TextureRect = %CallPhoto
@onready var call_name: Label = %CallName
@onready var call_status: Label = %CallStatus
@onready var call_timer: Label = %CallTimer
@onready var hangup_button: Button = %HangupButton

# Екран деталей контакту
@onready var detail_screen: Panel = %ContactDetailScreen
@onready var detail_back_button: Button = %BackButton
@onready var detail_photo: TextureRect = %DetailPhoto
@onready var detail_name: Label = %DetailName
@onready var detail_phone: Label = %DetailPhone
@onready var detail_description: Label = %DetailDescription
@onready var detail_call_count: Label = %DetailCallCount
@onready var detail_last_call: Label = %DetailLastCall
@onready var detail_status: Label = %DetailStatus
@onready var detail_call_button: Button = %CallContactButton
@onready var detail_favorite_button: Button = %FavoriteButton
@onready var detail_block_button: Button = %BlockButton

## Шаблон для елементу контакту
var contact_entry_scene = preload("res://ui/contact_entry.tscn")

## Поточний режим
enum Tab { FAVORITES, RECENT, CONTACTS }
var current_tab: Tab = Tab.CONTACTS

## Поточний дзвінок
var current_contact: ContactResource = null
var call_timer_active: bool = false
var current_detail_contact_id: String = ""

func _ready():
	# З'єднати сигнали
	search_bar.text_changed.connect(_on_search_changed)
	tab_bar.tab_changed.connect(_on_tab_changed)
	hangup_button.pressed.connect(_on_hangup_pressed)
	
	PhoneSystemManager.call_started.connect(_on_call_started)
	PhoneSystemManager.call_ended.connect(_on_call_ended)
	PhoneSystemManager.contacts_loaded.connect(_refresh_list)
	
	# Екран деталей
	detail_back_button.pressed.connect(_on_detail_back_pressed)
	detail_call_button.pressed.connect(_on_detail_call_pressed)
	detail_favorite_button.pressed.connect(_on_detail_favorite_pressed)
	detail_block_button.pressed.connect(_on_detail_block_pressed)
	
	# Ховати екран дзвінку та деталей
	call_screen.visible = false
	detail_screen.visible = false
	
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
	
	# Додати обробник натискання на весь контакт
	entry.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton:
			if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_show_contact_details(contact.id)
	)

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

## ==========================================
## ДЕТАЛЬНА ІНФО ПРО КОНТАКТ
## ==========================================

func _show_contact_details(contact_id: String):
	# Показати детальну інфо про контакт
	var contact = PhoneSystemManager.get_contact(contact_id)
	if !contact:
		_show_error("Контакт не знайдено: " + contact_id)
		return
	
	current_detail_contact_id = contact_id
	
	# Заповнити дані
	detail_photo.texture = contact.photo if contact.photo else null
	detail_name.text = contact.display_name
	detail_phone.text = contact.phone_number
	detail_description.text = contact.description if !contact.description.is_empty() else "Немає опису"
	
	# Статистика
	var info = PhoneSystemManager.get_contact_info(contact_id)
	detail_call_count.text = "📞 Дзвінків: %d" % info.get("call_count", 0)
	
	var last_call = info.get("last_call", 0.0)
	if last_call > 0:
		var time_dict = Time.get_datetime_dict_from_unix_time(int(last_call))
		detail_last_call.text = "🕐 Останній дзвінок: %02d.%02d.%04d %02d:%02d" % [
			time_dict.day, time_dict.month, time_dict.year,
			time_dict.hour, time_dict.minute
		]
	else:
		detail_last_call.text = "🕐 Останній дзвінок: немає"
	
	detail_status.text = "📊 Статус: " + info.get("status", "невідомий")
	
	# Кнопки
	detail_call_button.disabled = !info.get("can_call", false)
	
	# Кнопка обраного
	if contact.favorite:
		detail_favorite_button.text = "⭐ Видалити з обраного"
	else:
		detail_favorite_button.text = "⭐ Додати в обране"
	
	# Кнопка блокування
	if contact_id in PhoneSystemManager.blocked:
		detail_block_button.text = "✅ Розблокувати"
	else:
		detail_block_button.text = "🚫 Заблокувати"
	
	# Ховати PhonePanel, показати екран деталей
	phone_panel.visible = false
	detail_screen.visible = true

func _on_detail_back_pressed():
	# Закрити екран деталей, показати PhonePanel
	detail_screen.visible = false
	phone_panel.visible = true
	current_detail_contact_id = ""

func _on_detail_call_pressed():
	# Зателефонувати з екрану деталей
	if current_detail_contact_id.is_empty():
		return
	
	detail_screen.visible = false
	phone_panel.visible = true
	_on_contact_call_pressed(current_detail_contact_id)

func _on_detail_favorite_pressed():
	# Додати/видалити з обраного
	if current_detail_contact_id.is_empty():
		return
	
	var contact = PhoneSystemManager.get_contact(current_detail_contact_id)
	if !contact:
		return
	
	if contact.favorite:
		PhoneSystemManager.remove_from_favorites(current_detail_contact_id)
		detail_favorite_button.text = "⭐ Додати в обране"
	else:
		PhoneSystemManager.add_to_favorites(current_detail_contact_id)
		detail_favorite_button.text = "⭐ Видалити з обраного"
	
	_refresh_list()

func _on_detail_block_pressed():
	# Заблокувати/розблокувати
	if current_detail_contact_id.is_empty():
		return
	
	if current_detail_contact_id in PhoneSystemManager.blocked:
		PhoneSystemManager.unblock_contact(current_detail_contact_id)
		detail_block_button.text = "🚫 Заблокувати"
	else:
		PhoneSystemManager.block_contact(current_detail_contact_id)
		detail_block_button.text = "✅ Розблокувати"
	
	detail_call_button.disabled = current_detail_contact_id in PhoneSystemManager.blocked
