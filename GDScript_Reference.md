# GDScript - Основні можливості

## Я розумію та можу працювати з:

### Базовий синтаксис:
- Змінні: `var`, `const`
- Типи: `String`, `int`, `float`, `bool`, `Array`, `Dictionary`, `Vector2`, `Vector3`
- Функції: `func`, `return`, `await`
- Класи: `extends`, `class_name`
- Сигнали: `signal`, `emit()`, `connect()`

### Godot API:
- `Node`, `Control`, `SceneTree`
- `Engine.get_singleton()`, `Engine.has_singleton()`
- `ResourceLoader.load()`, `ResourceLoader.exists()`
- `get_tree()`, `get_node()`, `$NodePath`
- `await get_tree().process_frame`
- `call_deferred()`

### Спеціальні можливості:
- `@onready`, `@export`, `@tool`
- `await` для асинхронного коду
- `match` для pattern matching
- `for`, `while`, `if/elif/else`
- String методи: `rpad()`, `strip_edges()`, `begins_with()`

### Помилки, які я вже виправив:
- ❌ `"=" * 60` → ✅ `"".rpad(60, "=")`
- ❌ Вкладені функції → ✅ Методи класу
- ❌ Неправильні переходи `=> END` → ✅ Правильні переходи `=> q2`

## Готовий працювати з:
- ✅ GDScript скрипти
- ✅ Godot сцени (.tscn)
- ✅ Dialogue Manager API
- ✅ Autoloads та Singletons
- ✅ Ресурси та завантаження
- ✅ Сигнали та події
