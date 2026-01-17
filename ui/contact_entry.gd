extends HBoxContainer
## Елемент контакту в списку

signal call_pressed()

@onready var photo: TextureRect = $Photo
@onready var name_label: Label = $VBox/Name
@onready var info_label: Label = $VBox/Info
@onready var call_button: Button = $CallButton

var contact_id: String = ""

func setup(contact: ContactResource, call_data: Dictionary = {}):
	"""Налаштувати елемент"""
	contact_id = contact.id
	
	# Фото
	if contact.photo:
		photo.texture = contact.photo
	
	# Ім'я
	name_label.text = contact.display_name
	
	# Додаткова інформація
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
	call_button.pressed.connect(_on_call_pressed)
	call_button.disabled = !PhoneSystemManager.can_call(contact_id)

func _on_call_pressed():
	call_pressed.emit()
