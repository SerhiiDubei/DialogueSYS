extends HBoxContainer
## Елемент контакту в списку

signal call_pressed()

var contact_id: String = ""
var _contact_data: ContactResource = null
var _call_data: Dictionary = {}

func setup(contact: ContactResource, call_data: Dictionary = {}):
	# Зберігаємо дані і викликаємо _apply_setup в наступному кадрі
	_contact_data = contact
	_call_data = call_data
	contact_id = contact.id
	
	# Якщо вже в дереві - застосувати зараз, інакше чекати _ready
	if is_inside_tree():
		call_deferred("_apply_setup")

func _ready():
	# Якщо дані є - застосувати
	if _contact_data:
		_apply_setup()

func _apply_setup():
	if !_contact_data:
		return
	
	var contact = _contact_data
	var call_data = _call_data
	
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
		# Перевірити чи вже підключено
		if !call_button.pressed.is_connected(_on_call_pressed):
			call_button.pressed.connect(_on_call_pressed)
		call_button.disabled = !PhoneSystemManager.can_make_call(contact_id)

func _on_call_pressed():
	call_pressed.emit()
