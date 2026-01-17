extends Node
## Система керування телефонними дзвінками
## Autoload: PhoneSystemManager

## Сигнали
signal contact_called(contact_id: String)
signal call_started(contact_id: String, contact: ContactResource)
signal call_ended(contact_id: String, success: bool)
signal contact_added(contact_id: String)
signal contact_removed(contact_id: String)
signal contacts_loaded()

## Контакти
var contacts: Dictionary = {}  # id -> ContactResource
var recent_calls: Array[Dictionary] = []  # {contact_id, time, success, duration}
var blocked: Array[String] = []

## Поточний дзвінок
var current_call_id: String = ""
var call_start_time: float = 0.0

## Налаштування
const MAX_RECENT_CALLS: int = 50
const CONTACTS_FOLDER: String = "res://contacts/"

func _ready():
	print("📱 PhoneSystemManager готовий!")
	_load_contacts_from_folder()
	_load_contacts_data()  # Завантажити збережені дані (обране, статистику)
	_load_call_history()

## ==========================================
## ЗАВАНТАЖЕННЯ КОНТАКТІВ
## ==========================================

func _load_contacts_from_folder():
	# Завантажити всі контакти з папки contacts/
	var dir = DirAccess.open(CONTACTS_FOLDER)
	if !dir:
		push_warning("⚠️ Папка contacts/ не знайдена")
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	var count = 0
	
	while file_name != "":
		if file_name.ends_with(".tres"):
			var full_path = CONTACTS_FOLDER + file_name
			var contact = load(full_path)
			if contact is ContactResource:
				register_contact(contact)
				count += 1
		file_name = dir.get_next()
	
	dir.list_dir_end()
	print("📇 Завантажено контактів: ", count)
	contacts_loaded.emit()

func register_contact(contact: ContactResource):
	# Додати контакт в телефонну книгу
	if contact.id.is_empty():
		push_error("❌ Контакт має мати ID!")
		return
	
	contacts[contact.id] = contact
	contact_added.emit(contact.id)

## ==========================================
## ДЗВІНКИ
## ==========================================

func can_call(contact_id: String) -> bool:
	# ЧИ МОЖНА ЗАТЕЛЕФОНУВАТИ?
	if !contacts.has(contact_id):
		return false
	
	var contact = contacts[contact_id]
	
	# Перевірка блокування
	if contact_id in blocked:
		return false
	
	# Перевірка статусу
	if contact.status == 4:  # Blocked
		return false
	
	# Перевірка умов
	if !_check_conditions(contact):
		return false
	
	return true

func make_call(contact_id: String):
	# ЗАТЕЛЕФОНУВАТИ
	if !can_call(contact_id):
		push_warning("⚠️ Не можна зателефонувати: " + contact_id)
		return
	
	if !current_call_id.is_empty():
		push_warning("⚠️ Вже йде дзвінок!")
		return
	
	var contact = contacts[contact_id]
	current_call_id = contact_id
	call_start_time = Time.get_ticks_msec() / 1000.0
	
	# Оновити статистику
	contact.call_count += 1
	contact.last_call_time = call_start_time
	
	print("📞 Дзвінок: ", contact.display_name)
	contact_called.emit(contact_id)
	call_started.emit(contact_id, contact)

func end_call(success: bool = true):
	# ЗАВЕРШИТИ ДЗВІНОК
	if current_call_id.is_empty():
		return
	
	var duration = Time.get_ticks_msec() / 1000.0 - call_start_time
	
	# Додати в історію
	_add_to_recent({
		"contact_id": current_call_id,
		"time": Time.get_datetime_dict_from_system(),
		"success": success,
		"duration": duration
	})
	
	print("🔚 Дзвінок завершено: ", current_call_id, " (", "%.1f" % duration, "s)")
	call_ended.emit(current_call_id, success)
	
	current_call_id = ""
	call_start_time = 0.0

## ==========================================
## ПОШУК ТА ФІЛЬТРИ
## ==========================================

func search_contacts(query: String) -> Array[ContactResource]:
	# Пошук контактів
	if query.is_empty():
		return get_all_contacts()
	
	var search = query.to_lower()
	var results: Array[ContactResource] = []
	
	for contact in contacts.values():
		if (contact.display_name.to_lower().contains(search) or
			contact.phone_number.contains(search) or
			contact.description.to_lower().contains(search)):
			results.append(contact)
	
	return results

func get_all_contacts() -> Array[ContactResource]:
	# Всі контакти (відсортовані за ім'ям)
	var result: Array[ContactResource] = []
	for contact in contacts.values():
		result.append(contact)
	
	result.sort_custom(func(a, b): return a.display_name < b.display_name)
	return result

func get_favorites() -> Array[ContactResource]:
	# Тільки обрані
	var result: Array[ContactResource] = []
	for contact in contacts.values():
		if contact.favorite:
			result.append(contact)
	
	result.sort_custom(func(a, b): return a.display_name < b.display_name)
	return result

func get_recent_contacts() -> Array[Dictionary]:
	# Останні дзвінки
	return recent_calls.duplicate()

## ==========================================
## УПРАВЛІННЯ КОНТАКТАМИ
## ==========================================

func get_contact(contact_id: String) -> ContactResource:
	# Отримати контакт
	return contacts.get(contact_id)

func add_to_favorites(contact_id: String):
	# Додати в обране
	if contacts.has(contact_id):
		contacts[contact_id].favorite = true
		_save_contacts_data()

func remove_from_favorites(contact_id: String):
	# Видалити з обраного
	if contacts.has(contact_id):
		contacts[contact_id].favorite = false
		_save_contacts_data()

func block_contact(contact_id: String):
	# Заблокувати
	if !contact_id in blocked:
		blocked.append(contact_id)
		_save_contacts_data()

func unblock_contact(contact_id: String):
	# Розблокувати
	blocked.erase(contact_id)
	_save_contacts_data()

func get_contact_info(contact_id: String) -> Dictionary:
	# Інфо про контакт
	if !contacts.has(contact_id):
		return {}
	
	var contact = contacts[contact_id]
	return {
		"id": contact.id,
		"name": contact.display_name,
		"phone": contact.phone_number,
		"description": contact.description,
		"call_count": contact.call_count,
		"last_call": contact.last_call_time,
		"favorite": contact.favorite,
		"can_call": can_call(contact_id),
		"status": contact.get_status_text()
	}

## ==========================================
## УМОВИ
## ==========================================

func _check_conditions(contact: ContactResource) -> bool:
	# Перевірка умов доступності
	# Прапорець
	if !contact.condition_flag.is_empty():
		# TODO: Інтеграція з системою прапорців
		# if !GameState.has_flag(contact.condition_flag):
		#     return false
		pass
	
	# Час
	if contact.condition_time_start != 0 or contact.condition_time_end != 24:
		var time = Time.get_datetime_dict_from_system()
		var hour = time.hour
		if hour < contact.condition_time_start or hour >= contact.condition_time_end:
			return false
	
	# Квест
	if !contact.condition_quest.is_empty():
		# TODO: Інтеграція з квестовою системою
		# if !QuestSystem.is_quest_active(contact.condition_quest):
		#     return false
		pass
	
	return true

## ==========================================
## ІСТОРІЯ ДЗВІНКІВ
## ==========================================

func _add_to_recent(call_data: Dictionary):
	# Додати дзвінок в історію
	recent_calls.insert(0, call_data)
	
	# Обмеження розміру історії
	if recent_calls.size() > MAX_RECENT_CALLS:
		recent_calls.resize(MAX_RECENT_CALLS)
	
	_save_call_history()

func clear_recent():
	# Очистити історію
	recent_calls.clear()
	_save_call_history()

## ==========================================
## ЗБЕРЕЖЕННЯ/ЗАВАНТАЖЕННЯ
## ==========================================

func _save_contacts_data():
	# Зберегти дані контактів (обране, блоковані)
	var data = {
		"favorites": [],
		"blocked": blocked,
		"contacts_stats": {}
	}
	
	for contact in contacts.values():
		if contact.favorite:
			data.favorites.append(contact.id)
		
		data.contacts_stats[contact.id] = {
			"call_count": contact.call_count,
			"last_call_time": contact.last_call_time,
			"dialogue_completed": contact.dialogue_completed
		}
	
	var file = FileAccess.open("user://phone_contacts.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()

func _load_contacts_data():
	# Завантажити дані контактів
	if !FileAccess.file_exists("user://phone_contacts.json"):
		return
	
	var file = FileAccess.open("user://phone_contacts.json", FileAccess.READ)
	if !file:
		return
	
	var content = file.get_as_text()
	file.close()
	
	var data = JSON.parse_string(content)
	if !data:
		return
	
	# Відновити обране
	for contact_id in data.get("favorites", []):
		if contacts.has(contact_id):
			contacts[contact_id].favorite = true
	
	# Відновити блоковані (явне приведення типів)
	var loaded_blocked = data.get("blocked", [])
	blocked.clear()
	for item in loaded_blocked:
		blocked.append(str(item))
	
	# Відновити статистику
	var stats = data.get("contacts_stats", {})
	for contact_id in stats.keys():
		if contacts.has(contact_id):
			var contact = contacts[contact_id]
			var stat = stats[contact_id]
			contact.call_count = stat.get("call_count", 0)
			contact.last_call_time = stat.get("last_call_time", 0.0)
			contact.dialogue_completed = stat.get("dialogue_completed", false)

func _save_call_history():
	# Зберегти історію дзвінків
	var file = FileAccess.open("user://phone_history.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(recent_calls))
		file.close()

func _load_call_history():
	# Завантажити історію дзвінків
	if !FileAccess.file_exists("user://phone_history.json"):
		return
	
	var file = FileAccess.open("user://phone_history.json", FileAccess.READ)
	if !file:
		return
	
	var content = file.get_as_text()
	file.close()
	
	var data = JSON.parse_string(content)
	if data and data is Array:
		# Явне приведення типів Array -> Array[Dictionary]
		recent_calls.clear()
		for item in data:
			if item is Dictionary:
				recent_calls.append(item)
