extends Resource
class_name ContactResource
## Ресурс контакту в телефонній книзі
## Кожен контакт = окремий .tres файл

## Основна інформація
@export var id: String = ""
@export var display_name: String = ""
@export var phone_number: String = ""
@export var photo: Texture2D
@export_multiline var description: String = ""
@export var favorite: bool = false
@export var tags: Array[String] = []

## Статус доступності
@export_enum("Available:0", "Busy:1", "NoAnswer:2", "WrongNumber:3", "Blocked:4")
var status: int = 0  # 0 = Available

## Тип дзвінку
@export_enum("NoAnswer:0", "WrongNumber:1", "Quick:2", "Short:3", "Full:4", "MultiScene:5")
var call_type: int = 4  # 4 = Full (за замовчуванням)

## Посилання на діалог (для Short, Full, MultiScene)
@export var dialogue_file: String = ""  # Шлях до .dialogue файлу
@export var dialogue_start: String = ""  # Початковий title

## Умови доступності (опціонально)
@export var condition_flag: String = ""        # Прапорець який треба мати
@export var condition_time_start: int = 0      # Година початку (0-23)
@export var condition_time_end: int = 24       # Година кінця (0-24)
@export var condition_quest: String = ""       # ID квесту який має бути активний

## Швидкі повідомлення (для Quick типу)
@export var quick_messages: Array[String] = []

## Історія (не експортується, зберігається в SaveSystem)
var call_count: int = 0
var last_call_time: float = 0.0
var dialogue_completed: bool = false

## Допоміжні функції
func get_status_text() -> String:
	match status:
		0: return "Доступний"
		1: return "Зайнятий"
		2: return "Не відповідає"
		3: return "Старий номер"
		4: return "Заблокований"
		_: return "Невідомо"

func get_call_type_text() -> String:
	match call_type:
		0: return "Не відповідає"
		1: return "Старий номер"
		2: return "Швидкий чат"
		3: return "Короткий діалог"
		4: return "Повний діалог"
		5: return "Багатосценний"
		_: return "Невідомо"
