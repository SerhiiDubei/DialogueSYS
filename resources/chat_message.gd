extends Resource
class_name ChatMessage

## Повідомлення в чаті

@export var id: String = ""                      # Унікальний ID
@export var sender_id: String = ""               # ID відправника (contact_id або "player")
@export var text: String = ""                    # Текст повідомлення
@export var timestamp: float = 0.0               # Час відправки (Unix timestamp)
@export var is_read: bool = false                # Прочитане?
@export var is_sent: bool = true                 # Відправлене? (false = в процесі)
@export var is_delivered: bool = false           # Доставлене?

# Додаткові поля для розширення
@export var attachment_type: String = ""         # "image", "file", "audio", "sticker"
@export var attachment_path: String = ""         # Шлях до файлу
@export var reply_to_id: String = ""             # ID повідомлення на яке відповідь

func _init(p_sender_id: String = "", p_text: String = ""):
	id = _generate_id()
	sender_id = p_sender_id
	text = p_text
	timestamp = Time.get_unix_time_from_system()

func _generate_id() -> String:
	return "msg_%d_%d" % [Time.get_ticks_msec(), randi()]

func is_from_player() -> bool:
	return sender_id == "player"

func get_time_string() -> String:
	var time_dict = Time.get_datetime_dict_from_unix_time(int(timestamp))
	return "%02d:%02d" % [time_dict.hour, time_dict.minute]

func get_date_string() -> String:
	var time_dict = Time.get_datetime_dict_from_unix_time(int(timestamp))
	return "%02d.%02d.%04d" % [time_dict.day, time_dict.month, time_dict.year]
