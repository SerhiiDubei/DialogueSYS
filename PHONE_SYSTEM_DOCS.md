# 📱 Система Телефонних Дзвінків - Документація

## 🎯 Огляд

Повнофункціональна система телефону в стилі iPhone з підтримкою:
- 📞 5 типів дзвінків (від швидкого чату до багатосценних діалогів)
- 🔍 Пошук контактів
- ⭐ Обрані контакти
- 🕐 Історія дзвінків
- 💾 Автозбереження

---

## 📦 Архітектура

```
PhoneSystemManager (Autoload)
├── ContactResource (.tres файли)
├── PhoneUI (Сцена телефону)
└── ContactEntry (Елемент списку)
```

---

## 📝 ContactResource

Базовий клас для контактів. Кожен контакт = окремий `.tres` файл.

### Властивості:

```gdscript
# Основне
id: String                    # Унікальний ID
display_name: String          # Ім'я для відображення
phone_number: String          # Номер телефону
photo: Texture2D             # Фото контакту
description: String          # Опис
favorite: bool               # Обране
tags: Array[String]          # Теги

# Статус
status: int                  # 0=Available, 1=Busy, 2=NoAnswer, 3=WrongNumber, 4=Blocked

# Тип дзвінку
call_type: int               # 0=NoAnswer, 1=WrongNumber, 2=Quick, 3=Short, 4=Full, 5=MultiScene

# Діалог
dialogue_file: String        # Шлях до .dialogue
dialogue_start: String       # Початковий title

# Умови
condition_flag: String       # Потрібний прапорець
condition_time_start: int    # Час початку (0-23)
condition_time_end: int      # Час кінця (0-24)
condition_quest: String      # ID квесту

# Швидкі повідомлення (для Quick типу)
quick_messages: Array[String]
```

---

## 🎮 PhoneSystemManager (Autoload)

Головна система керування дзвінками.

### Основні функції:

#### ✅ Перевірки

```gdscript
can_call(contact_id: String) -> bool
# ЧИ МОЖНА ЗАТЕЛЕФОНУВАТИ?
# Перевіряє: існування, блокування, умови

PhoneSystemManager.can_call("alex")  # true/false
```

#### 📞 Дзвінки

```gdscript
make_call(contact_id: String)
# ЗАТЕЛЕФОНУВАТИ
# Викликає сигнал call_started

PhoneSystemManager.make_call("mom")

end_call(success: bool = true)
# ЗАВЕРШИТИ ДЗВІНОК
# Додає в історію

PhoneSystemManager.end_call(true)
```

#### 🔍 Пошук

```gdscript
search_contacts(query: String) -> Array[ContactResource]
# Пошук по імені, номеру, опису

var results = PhoneSystemManager.search_contacts("мама")

get_all_contacts() -> Array[ContactResource]
# Всі контакти (відсортовані)

get_favorites() -> Array[ContactResource]
# Тільки обрані

get_recent_contacts() -> Array[Dictionary]
# Історія дзвінків
```

#### 📇 Управління

```gdscript
get_contact(contact_id: String) -> ContactResource
add_to_favorites(contact_id: String)
remove_from_favorites(contact_id: String)
block_contact(contact_id: String)
unblock_contact(contact_id: String)
get_contact_info(contact_id: String) -> Dictionary
```

### Сигнали:

```gdscript
contact_called(contact_id: String)
call_started(contact_id: String, contact: ContactResource)
call_ended(contact_id: String, success: bool)
contact_added(contact_id: String)
contact_removed(contact_id: String)
contacts_loaded()
```

---

## 📞 Типи Дзвінків

### 0️⃣ NoAnswer - Не відповідає
- 3 секунди очікування
- Повідомлення "Абонент не відповідає"
- Автоматичне завершення

### 1️⃣ WrongNumber - Старий номер
- 2 секунди очікування
- Повідомлення "Номер не обслуговується"
- Автоматичне завершення

### 2️⃣ Quick - Швидкий чат
- 1-4 швидкі повідомлення
- 1.5 секунди між повідомленнями
- Використовує `quick_messages` масив

**Приклад:**
```gdscript
quick_messages = [
	"Алло?",
	"Зайнятий, передзвоню!",
	"*Гудки*"
]
```

### 3️⃣ Short - Короткий діалог
- Запускає діалог з `.dialogue` файлу
- 1 сцена
- Використовує `dialogue_file` та `dialogue_start`

### 4️⃣ Full - Повний діалог
- Розгалужений діалог
- Багато варіантів відповідей
- Та сама логіка що Short, але триваліший

### 5️⃣ MultiScene - Багатосценний діалог
- 9 сцен підряд
- Індикатор прогресу "Частина X/9"
- Пауза між сценами
- Для складних сюжетних ліній

**Приклад структури:**
```dialogue
~ scene_1
// перша сцена
=> scene_2

~ scene_2
// друга сцена
=> scene_3

// ... до scene_9
```

---

## 🎨 PhoneUI

Візуальний інтерфейс телефону.

### Компоненти:

- **SearchBar** - Пошук контактів
- **TabBar** - Вкладки (Обрані, Недавні, Контакти)
- **ContactList** - Список контактів
- **CallScreen** - Екран дзвінка

### Використання:

```gdscript
# Відкрити телефон
var phone = preload("res://ui/phone_ui.tscn").instantiate()
get_tree().current_scene.add_child(phone)

# Або викликати метод
phone.open_phone()
phone.close_phone()
```

---

## 📝 Створення Нового Контакту

### Крок 1: Створити `.tres` файл

**`contacts/new_contact.tres`:**
```gdscript
[gd_resource type="Resource" script_class="ContactResource" load_steps=2 format=3]

[ext_resource type="Script" path="res://resources/contact_resource.gd" id="1"]

[resource]
script = ExtResource("1")
id = "new_contact"
display_name = "Нове Ім'я"
phone_number = "+380 99 000 0000"
description = "Опис"
favorite = false
tags = ["новий"]
status = 0
call_type = 4
dialogue_file = "res://dialogue/phone_calls/new_contact.dialogue"
dialogue_start = "start"
```

### Крок 2: Створити діалог (якщо потрібно)

**`dialogue/phone_calls/new_contact.dialogue`:**
```dialogue
~ start

NewContact: Алло?

- Привіт!
	NewContact: Привіт! Як справи?
	=> END

- Хто це?
	NewContact: Це я, не впізнав?
	=> END
```

### Крок 3: Готово!

Контакт автоматично з'явиться в телефоні при запуску гри.

---

## 🔧 Додавання Контакту Через Код

```gdscript
# Створити новий контакт
var contact = ContactResource.new()
contact.id = "dynamic_contact"
contact.display_name = "Динамічний Контакт"
contact.phone_number = "+380 99 111 2222"
contact.status = 0
contact.call_type = 2
contact.quick_messages = ["Привіт!", "Як справи?", "Бувай!"]

# Зареєструвати
PhoneSystemManager.register_contact(contact)

# Показати повідомлення
print("📱 Новий контакт додано: ", contact.display_name)
```

---

## 🎯 Інтеграція з Діалогами

### З .dialogue файлів:

```dialogue
~ some_scene

NPC: Ось мій номер. Телефонуй!

# Додати контакт
do PhoneSystemManager.register_contact(load("res://contacts/npc.tres"))

# Зателефонувати (якщо треба відразу)
do PhoneSystemManager.make_call("npc")

# Перевірити чи можна дзвонити
NPC: Можеш дзвонити! [if PhoneSystemManager.can_call("npc")]
```

---

## ⚙️ Умови Доступності

### Прапорець:
```gdscript
condition_flag = "met_detective"
# Дзвонити можна тільки якщо є прапорець "met_detective"
```

### Час:
```gdscript
condition_time_start = 9   # 09:00
condition_time_end = 18    # 18:00
# Дзвонити можна тільки з 9:00 до 18:00
```

### Квест:
```gdscript
condition_quest = "investigation"
# Дзвонити можна тільки якщо активний квест "investigation"
```

---

## 💾 Збереження

Система автоматично зберігає:
- ⭐ Обрані контакти
- 🚫 Заблоковані контакти
- 📊 Статистику дзвінків (кількість, час)
- 🕐 Історію дзвінків (50 останніх)

**Файли:**
- `user://phone_contacts.json` - Дані контактів
- `user://phone_history.json` - Історія дзвінків

---

## 🎨 Кастомізація UI

### Змінити стилі телефону:

Відредагуй `ui/phone_ui.tscn`:
- `PhonePanel` - Розмір та колір телефону
- `SearchBar` - Стиль пошуку
- `TabBar` - Вкладки
- `CallScreen` - Екран дзвінка

### Додати власні теми:

```gdscript
# В PhoneUI._ready()
var theme = preload("res://themes/phone_theme.tres")
$PhonePanel.theme = theme
```

---

## 🐛 Дебаг

### Перевірити стан системи:

```gdscript
# Кількість контактів
print("Контактів: ", PhoneSystemManager.contacts.size())

# Поточний дзвінок
print("Дзвінок: ", PhoneSystemManager.current_call_id)

# Історія
print("Історія: ", PhoneSystemManager.recent_calls.size())
```

### Очистити історію:

```gdscript
PhoneSystemManager.clear_recent()
```

---

## 📚 Структура Файлів

```
project/
├── resources/
│   └── contact_resource.gd        # Базовий клас
├── scripts/
│   └── phone_system_manager.gd    # Autoload система
├── ui/
│   ├── phone_ui.gd                # Логіка UI
│   ├── phone_ui.tscn              # Сцена телефону
│   ├── contact_entry.gd           # Елемент контакту
│   └── contact_entry.tscn         # Сцена елементу
├── contacts/                       # .tres файли
│   ├── mom.tres
│   ├── alex.tres
│   ├── detective.tres
│   └── ...
└── dialogue/
    └── phone_calls/                # Діалоги дзвінків
        ├── alex_call.dialogue
        ├── detective_call.dialogue
        └── ...
```

---

## ✅ Приклади Використання

### 1. Відкрити телефон з кнопки:

```gdscript
# game_hud.gd
func _on_phone_button_pressed():
	var phone = preload("res://ui/phone_ui.tscn").instantiate()
	get_tree().current_scene.add_child(phone)
```

### 2. Додати контакт після квесту:

```gdscript
# quest_completed.gd
func _on_quest_done():
	var contact = load("res://contacts/reward_contact.tres")
	PhoneSystemManager.register_contact(contact)
	
	# Показати повідомлення
	NotificationSystem.show("📱 Новий контакт: " + contact.display_name)
```

### 3. Примусовий дзвінок (як катсцена):

```gdscript
# cutscene.gd
func _play_phone_cutscene():
	PhoneSystemManager.make_call("detective")
	await PhoneSystemManager.call_ended
	print("Дзвінок завершено!")
```

---

## 🚀 Розширення Системи

### Додати нові типи дзвінків:

У `PhoneUI._on_call_started()` додай новий `match` case:

```gdscript
6:  # CustomType
	_handle_custom_type()
```

### Додати відеодзвінки:

```gdscript
# ContactResource
@export var supports_video: bool = false

# PhoneUI
func _handle_video_call():
	# Логіка відеодзвінка
	pass
```

### Додати групові дзвінки:

```gdscript
# PhoneSystemManager
func call_group(contact_ids: Array[String]):
	# Логіка групового дзвінка
	pass
```

---

## 🎯 Переваги Системи

✅ **Модульність** - кожен контакт окремо  
✅ **Легко розширювати** - додай `.tres` → готово  
✅ **Функції замість hardcode** - `can_call()`, `call()`  
✅ **5+ типів дзвінків** - від швидких до епічних  
✅ **Автозбереження** - історія, обране, статистика  
✅ **Умови** - час, квести, прапорці  
✅ **Інтеграція** - з діалогами, квестами, прапорцями  

---

**Готово! Система повністю функціональна!** 📱✨
