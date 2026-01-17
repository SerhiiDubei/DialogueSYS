extends Panel
## Екран чату (Telegram-style)

signal back_pressed()

## Вузли
@onready var back_button: Button = %BackButton
@onready var avatar: TextureRect = %Avatar
@onready var contact_name_label: Label = %ContactName
@onready var contact_status_label: Label = %ContactStatus
@onready var messages_container: ScrollContainer = %MessagesContainer
@onready var messages_list: VBoxContainer = %MessagesList
@onready var message_input: LineEdit = %MessageInput
@onready var send_button: Button = %SendButton

## Шаблони
var message_bubble_scene = preload("res://ui/message_bubble.tscn")

## Поточний контакт
var current_contact_id: String = ""
var current_contact: ContactResource = null

func _ready():
	# Підключити сигнали
	back_button.pressed.connect(_on_back_pressed)
	send_button.pressed.connect(_on_send_pressed)
	message_input.text_submitted.connect(_on_message_submitted)
	
	# Підписатися на нові повідомлення
	ChatManager.message_received.connect(_on_message_received)
	ChatManager.message_sent.connect(_on_message_sent)

func open_chat(contact_id: String):
	# Відкрити чат з контактом
	current_contact_id = contact_id
	current_contact = PhoneSystemManager.get_contact(contact_id)
	
	if !current_contact:
		push_error("Контакт не знайдено: " + contact_id)
		return
	
	# Налаштувати верхню панель
	contact_name_label.text = current_contact.display_name
	contact_status_label.text = "онлайн" if current_contact.status == "Available" else "був(ла) недавно"
	avatar.texture = current_contact.photo if current_contact.photo else null
	
	# Завантажити повідомлення
	_load_messages()
	
	# Відмітити як прочитане
	ChatManager.mark_as_read(contact_id)
	ChatManager.chat_opened.emit(contact_id)
	
	# Фокус на поле вводу
	message_input.grab_focus()

func _load_messages():
	# Завантажити всі повідомлення
	# Очистити список
	for child in messages_list.get_children():
		child.queue_free()
	
	var messages = ChatManager.get_chat(current_contact_id)
	
	if messages.is_empty():
		# Показати привітання
		_add_system_message("Почніть розмову!")
		return
	
	# Додати всі повідомлення
	for msg in messages:
		_add_message_bubble(msg)
	
	# Прокрутити вниз
	await get_tree().process_frame
	messages_container.scroll_vertical = int(messages_container.get_v_scroll_bar().max_value)

func _add_message_bubble(message: ChatMessage):
	# Додати бульбашку повідомлення
	var bubble = message_bubble_scene.instantiate()
	messages_list.add_child(bubble)
	bubble.setup(message, current_contact)

func _add_system_message(text: String):
	# Системне повідомлення (по центру, сірий текст)
	var label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	label.add_theme_font_size_override("font_size", 12)
	messages_list.add_child(label)

func _on_send_pressed():
	_send_message()

func _on_message_submitted(_text: String):
	_send_message()

func _send_message():
	var text = message_input.text.strip_edges()
	
	if text.is_empty():
		return
	
	# Відправити повідомлення
	var message = ChatManager.send_message(current_contact_id, text)
	
	# Додати бульбашку
	_add_message_bubble(message)
	
	# Очистити поле
	message_input.clear()
	message_input.grab_focus()
	
	# Прокрутити вниз
	await get_tree().process_frame
	messages_container.scroll_vertical = int(messages_container.get_v_scroll_bar().max_value)

func _on_message_received(contact_id: String, message: ChatMessage):
	# Нове повідомлення від контакту
	if contact_id != current_contact_id:
		return  # Не наш чат
	
	# Додати бульбашку
	_add_message_bubble(message)
	
	# Прокрутити вниз
	await get_tree().process_frame
	messages_container.scroll_vertical = int(messages_container.get_v_scroll_bar().max_value)
	
	# Відмітити як прочитане
	ChatManager.mark_as_read(contact_id)

func _on_message_sent(contact_id: String, _message: ChatMessage):
	# Повідомлення відправлено (вже додано в _send_message)
	pass

func _on_back_pressed():
	back_pressed.emit()
