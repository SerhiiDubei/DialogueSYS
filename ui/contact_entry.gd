extends HBoxContainer
## Елемент контакту в списку

signal call_pressed()

var contact_id: String = ""

func setup(contact: ContactResource, call_data: Dictionary = {}):
	# Налаштувати елемент
	contact_id = contact.id
	
	# Отримуємо посилання на ноди
	var photo: TextureRect = get_node_or_null("Photo")
	var name_label: Label = get_node_or_null("VBox/Name")
	var info_label: Label = get_node_or_null("VBox/Info")
	var call_button: Button = get_node_or_null("CallButton")
	
	# Фото
	if photo and contact.photo:
		photo.texture = contact.photo
	
	# Ім'я
	if name_label:
		name_label.text = contact.display_name
	
	# Додаткова інформація
	if info_label:
		if !call_data.is_empty():
			# Для недавніх дзвінків
			var time_dict = call_data.get("time", {})
			var time_str = "%02d:%02d" % [time_dict.get("hour", 0), time_dict.get("minute", 0)]
			var success = "✅" if call_data.get("success", false) else "❌"
			info_label.text = "%s %s" % [success, time_str]
		else:
			# Для звичайного списку
			info_label.text = contact.phone_number
	
	# Кнопка дзвінка
	if call_button:
		call_button.pressed.connect(_on_call_pressed)
		call_button.disabled = !PhoneSystemManager.can_make_call(contact_id)
	else:
		push_error("CallButton не знайдено в contact_entry!")

func _on_call_pressed():
	call_pressed.emit()
