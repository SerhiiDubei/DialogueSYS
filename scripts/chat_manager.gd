extends Node
## Система керування чатами (Telegram-style)
## Autoload: ChatManager

## Сигнали
signal message_received(contact_id: String, message: ChatMessage)
signal message_sent(contact_id: String, message: ChatMessage)
signal chat_opened(contact_id: String)
signal new_unread_message(contact_id: String, count: int)

## Чати: Dictionary[contact_id -> Array[ChatMessage]]
var chats: Dictionary = {}  # contact_id -> Array[ChatMessage]
var unread_counts: Dictionary = {}  # contact_id -> int

const SAVE_PATH = "user://chats.json"

func _ready():
	print("💬 ChatManager готовий!")
	_load_chats()

## ==========================================
## ВІДПРАВКА ПОВІДОМЛЕНЬ
## ==========================================

func send_message(contact_id: String, text: String) -> ChatMessage:
	# Відправити повідомлення
	var message = ChatMessage.new("player", text)
	
	if !chats.has(contact_id):
		chats[contact_id] = []
	
	chats[contact_id].append(message)
	message_sent.emit(contact_id, message)
	_save_chats()
	
	# Симуляція відповіді (через 1-3 секунди)
	_simulate_response(contact_id)
	
	return message

func receive_message(contact_id: String, text: String) -> ChatMessage:
	# Отримати повідомлення від контакту
	var message = ChatMessage.new(contact_id, text)
	
	if !chats.has(contact_id):
		chats[contact_id] = []
	
	chats[contact_id].append(message)
	
	# Збільшити лічильник непрочитаних
	unread_counts[contact_id] = unread_counts.get(contact_id, 0) + 1
	
	message_received.emit(contact_id, message)
	new_unread_message.emit(contact_id, unread_counts[contact_id])
	_save_chats()
	
	return message

func _simulate_response(contact_id: String):
	# Симуляція відповіді від контакту
	await get_tree().create_timer(randf_range(1.0, 3.0)).timeout
	
	var responses = [
		"Привіт! Як справи?",
		"Окей, зрозумів",
		"Дякую за повідомлення!",
		"Можемо зустрітись завтра?",
		"Добре, дзвони пізніше",
		"👍",
		"Гаразд, домовились!",
		"Перепишемось!",
	]
	
	receive_message(contact_id, responses[randi() % responses.size()])

## ==========================================
## КЕРУВАННЯ ЧАТАМИ
## ==========================================

func get_chat(contact_id: String) -> Array:
	# Отримати всі повідомлення з контактом
	if !chats.has(contact_id):
		chats[contact_id] = []
	return chats[contact_id]

func get_last_message(contact_id: String) -> ChatMessage:
	# Отримати останнє повідомлення
	var chat = get_chat(contact_id)
	if chat.is_empty():
		return null
	return chat[chat.size() - 1]

func get_unread_count(contact_id: String) -> int:
	# Кількість непрочитаних
	return unread_counts.get(contact_id, 0)

func mark_as_read(contact_id: String):
	# Відмітити як прочитані
	unread_counts[contact_id] = 0
	
	var chat = get_chat(contact_id)
	for msg in chat:
		if !msg.is_from_player():
			msg.is_read = true
	
	_save_chats()

func delete_chat(contact_id: String):
	# Видалити чат
	chats.erase(contact_id)
	unread_counts.erase(contact_id)
	_save_chats()

func get_all_chats() -> Array:
	# Отримати список всіх чатів (відсортований за останнім повідомленням)
	var result = []
	
	for contact_id in chats.keys():
		var chat = chats[contact_id]
		if !chat.is_empty():
			result.append({
				"contact_id": contact_id,
				"last_message": get_last_message(contact_id),
				"unread_count": get_unread_count(contact_id)
			})
	
	# Сортувати за часом останнього повідомлення
	result.sort_custom(func(a, b): 
		return a.last_message.timestamp > b.last_message.timestamp
	)
	
	return result

## ==========================================
## ЗБЕРЕЖЕННЯ/ЗАВАНТАЖЕННЯ
## ==========================================

func _save_chats():
	# Зберегти чати
	var save_data = {}
	
	for contact_id in chats.keys():
		var messages_data = []
		for msg in chats[contact_id]:
			messages_data.append({
				"id": msg.id,
				"sender_id": msg.sender_id,
				"text": msg.text,
				"timestamp": msg.timestamp,
				"is_read": msg.is_read,
				"is_sent": msg.is_sent,
				"is_delivered": msg.is_delivered
			})
		save_data[contact_id] = messages_data
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({
			"chats": save_data,
			"unread_counts": unread_counts
		}))
		file.close()

func _load_chats():
	# Завантажити чати
	if !FileAccess.file_exists(SAVE_PATH):
		return
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if !file:
		return
	
	var content = file.get_as_text()
	file.close()
	
	var data = JSON.parse_string(content)
	if !data:
		return
	
	# Завантажити чати
	var chats_data = data.get("chats", {})
	for contact_id in chats_data.keys():
		chats[contact_id] = []
		for msg_data in chats_data[contact_id]:
			var msg = ChatMessage.new()
			msg.id = msg_data.get("id", "")
			msg.sender_id = msg_data.get("sender_id", "")
			msg.text = msg_data.get("text", "")
			msg.timestamp = msg_data.get("timestamp", 0.0)
			msg.is_read = msg_data.get("is_read", false)
			msg.is_sent = msg_data.get("is_sent", true)
			msg.is_delivered = msg_data.get("is_delivered", false)
			chats[contact_id].append(msg)
	
	# Завантажити лічильники
	var loaded_unread = data.get("unread_counts", {})
	for contact_id in loaded_unread.keys():
		unread_counts[contact_id] = loaded_unread[contact_id]
	
	print("💬 Завантажено %d чатів" % chats.size())
