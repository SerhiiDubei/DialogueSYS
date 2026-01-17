# 🏗️ Архітектура Діалогової Системи

## 📦 Принцип: **ФУНКЦІЇ замість HARDCODE!**

Замість того щоб писати логіку безпосередньо в `.dialogue` файлах, використовуємо централізовану систему з функціями.

---

## 🎯 3 основні компоненти:

### 1️⃣ **SaveSystem** (Автолоад)
📁 `scripts/save_system.gd`

**Відповідальність:** Збереження та завантаження даних

**Функції:**
```gdscript
has_talked_to(character_id)         # Чи говорили з персонажем?
can_talk_to_new_character()         # Чи є ще спроби?
mark_character_talked(character_id) # Відмітити розмову
get_completed_characters_count()    # Скільки пройдено?
get_conversations_left()            # Скільки залишилось?
all_characters_completed()          # Чи ліміт досягнуто?
reset_progress()                    # Скинути все
save_game_data() / load_game_data() # Збереження/завантаження
```

---

### 2️⃣ **DialogueSystemManager** (Автолоад)
📁 `scripts/dialogue_system_manager.gd`

**Відповідальність:** Логіка діалогів та персонажів

**Ключові функції для `.dialogue` файлів:**

#### ✅ Перевірки (використовуються в `[if condition]`)
```gdscript
can_talk_to(character_id)          # Чи можна говорити?
has_talked_to(character_id)        # Чи вже говорили?
is_limit_reached()                 # Чи ліміт досягнуто?
get_conversations_left()           # Скільки залишилось?
get_completed_count()              # Скільки пройдено?
```

#### ✅ Дії (використовуються в `do ...`)
```gdscript
mark_talked(character_id)          # Відмітити розмову
reset_all()                        # Скинути прогрес
```

#### ✅ Допоміжні функції
```gdscript
get_character_info(character_id)   # Інфо про персонажа
get_character_name(character_id)   # Ім'я персонажа
get_character_status_text(id)      # Текст статусу для UI
get_available_characters()         # Список доступних
get_talked_characters()            # Список пройдених
get_all_character_ids()            # Всі ID персонажів
```

#### ✅ Реєстрація персонажів
```gdscript
register_character({
    "id": "alex",
    "name": "Алекс",
    "emoji": "👨",
    "description": "Твій друг",
    "available": true
})
```

**Сигнали:**
```gdscript
character_talked(character_id)     # Коли поговорили
limit_reached()                    # Коли ліміт досягнуто
all_conversations_completed()      # Коли все пройдено
```

---

### 3️⃣ **GameState**
📁 `scripts/game_state.gd`

**Відповідальність:** Стан гри (параметри гравця, згоди персонажів)

**Параметри гравця (0-100):**
```gdscript
p_alcohol      # Любов до алкоголю
p_straight     # Прямолінійність
p_charm        # Харизма
p_patience     # Терпіння
```

**Згоди персонажів:**
```gdscript
agreed_alex, agreed_bohdan, agreed_dana, agreed_ira
```

**Функції:**
```gdscript
has_l2_alex(), has_l2_bohdan(), has_l2_dana(), has_l2_ira()
get_agreed_count()
```

**Посилання на системи:**
```gdscript
@onready var save_system: SaveSystem
@onready var dialogue_system: DialogueSystemManager
```

---

## 📝 Як використовувати в `.dialogue` файлах:

### ❌ **СТАРИЙ СПОСІБ (HARDCODE):**
```dialogue
- Поговорити з Алексом [if !game_state.save_system.has_talked_to("alex") && game_state.save_system.can_talk_to_new_character()]
	do game_state.save_system.mark_character_talked("alex")
	=> talk_alex
```

### ✅ **НОВИЙ СПОСІБ (ФУНКЦІЇ):**
```dialogue
- Поговорити з Алексом [if game_state.dialogue_system.can_talk_to("alex")]
	do game_state.dialogue_system.mark_talked("alex")
	=> talk_alex
```

---

## 🎨 Приклади використання:

### 1. Меню вибору персонажів:
```dialogue
~ hub_options

- Поговорити з Алексом [if game_state.dialogue_system.can_talk_to("alex")]
	=> talk_alex
- ✅ Алекс (вже) [if game_state.dialogue_system.has_talked_to("alex")]
	NPC: Ти вже говорив з ним!
	=> hub_options

- Поговорити з Богданом [if game_state.dialogue_system.can_talk_to("bohdan")]
	=> talk_bohdan
- ✅ Богдан (вже) [if game_state.dialogue_system.has_talked_to("bohdan")]
	NPC: Ти вже говорив з ним!
	=> hub_options
```

### 2. Відмітка розмови:
```dialogue
~ talk_alex
do game_state.dialogue_system.mark_talked("alex")

Alex: Привіт, друже!
// ... діалог ...
=> hub
```

### 3. Кнопка "В бар":
```dialogue
- 🍺 Відправитись в бар [if game_state.dialogue_system.is_limit_reached()]
	NPC: Час у бар!
	=> bar_scene
```

### 4. Лічильник:
```dialogue
set game_state.p_completed_count = game_state.dialogue_system.get_completed_count()
NPC: Поговорено: [[game_state.p_completed_count]]/2
```

---

## ➕ Як додати нового персонажа:

### Крок 1: Реєструємо в `dialogue_system_manager.gd`
```gdscript
func _init_characters():
	register_character({
		"id": "new_character",
		"name": "Новий Персонаж",
		"emoji": "🧑",
		"description": "Опис",
		"available": true
	})
```

### Крок 2: Додаємо в `demo.dialogue`
```dialogue
# Новий персонаж
- Поговорити з Новим [if game_state.dialogue_system.can_talk_to("new_character")]
	=> talk_new_character
- ✅ Новий (вже) [if game_state.dialogue_system.has_talked_to("new_character")]
	NPC: Вже говорили!
	=> hub_options

~ talk_new_character
do game_state.dialogue_system.mark_talked("new_character")
NewCharacter: Привіт!
// ... діалог ...
=> hub
```

**ВСЕ!** Логіка ліміту, збереження, перевірок працює автоматично!

---

## 🔧 Налаштування:

### Змінити ліміт розмов:
📁 `scripts/save_system.gd`
```gdscript
const MAX_CONVERSATIONS: int = 3  # Було 2
```

### Додати нові параметри персонажів:
📁 `scripts/dialogue_system_manager.gd`
```gdscript
register_character({
	"id": "alex",
	"name": "Алекс",
	"emoji": "👨",
	"difficulty": "easy",      # ← НОВИЙ параметр
	"likes_beer": true         # ← НОВИЙ параметр
})
```

---

## 🐛 Дебаг:

### Вивести статус в консоль:
```gdscript
DialogueSystemManager.print_status()
```

**Виведе:**
```
═══════════════════════════════════
📊 СТАТУС ДІАЛОГОВОЇ СИСТЕМИ
═══════════════════════════════════
Всього персонажів: 4
Поговорили з: 2/2
Доступно зараз: 0
Залишилось спроб: 0
Ліміт досягнуто: ✅
Розмовляли з: ["alex", "dana"]
═══════════════════════════════════
```

### Отримати статус об'єктом:
```gdscript
var status = DialogueSystemManager.get_status_summary()
print(status.talked_count)  # 2
print(status.limit_reached)  # true
```

---

## ✅ Переваги цього підходу:

1. **Менше hardcode** - логіка в одному місці
2. **Легко додавати персонажів** - просто зареєструвати
3. **Легко міняти ліміт** - одна константа
4. **Читабельність** - `can_talk_to("alex")` замість довгої умови
5. **Перевикористання** - функції можна викликати звідки завгодно
6. **Дебаг** - централізоване логування
7. **Масштабованість** - додавати features легше

---

## 📚 Файли системи:

```
scripts/
├── save_system.gd               # Збереження даних
├── dialogue_system_manager.gd   # Логіка діалогів
└── game_state.gd                # Стан гри

dialogue/
└── demo.dialogue                # Діалоги (використовують функції)

project.godot                    # Autoload конфігурація
```

---

## 🎯 Ключова ідея:

**Раніше:** Логіка розкидана по `.dialogue` файлах
**Тепер:** Логіка в `DialogueSystemManager`, діалоги тільки викликають функції

**Це робить код:**
- 🧹 Чистішим
- 📖 Читабельнішим
- 🔧 Легше підтримувати
- ➕ Легше розширювати
