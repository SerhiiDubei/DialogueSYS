extends MarginContainer
## Бульбашка повідомлення (Telegram-style)

@onready var bubble_panel: PanelContainer = %BubblePanel
@onready var message_text: RichTextLabel = %MessageText
@onready var time_label: Label = %TimeLabel

# Кольори як в Telegram
const COLOR_INCOMING = Color(0.95, 0.95, 0.95)  # Світло-сірий
const COLOR_OUTGOING = Color(0.5, 0.75, 1.0)    # Блакитний
const COLOR_TEXT_INCOMING = Color(0, 0, 0)
const COLOR_TEXT_OUTGOING = Color(1, 1, 1)

func setup(message: ChatMessage, contact: ContactResource):
	# Налаштувати бульбашку
	var is_outgoing = message.is_from_player()
	
	# Текст повідомлення
	message_text.text = message.text
	
	# Час
	time_label.text = message.get_time_string()
	
	# Стиль залежно від відправника
	if is_outgoing:
		# Наше повідомлення (справа, синє)
		size_flags_horizontal = SIZE_FILL
		bubble_panel.size_flags_horizontal = SIZE_SHRINK_END
		
		# Колір фону
		var style = StyleBoxFlat.new()
		style.bg_color = COLOR_OUTGOING
		style.corner_radius_top_left = 15
		style.corner_radius_top_right = 15
		style.corner_radius_bottom_left = 15
		style.corner_radius_bottom_right = 3
		style.content_margin_left = 12
		style.content_margin_right = 12
		style.content_margin_top = 8
		style.content_margin_bottom = 8
		bubble_panel.add_theme_stylebox_override("panel", style)
		
		# Колір тексту
		message_text.add_theme_color_override("default_color", COLOR_TEXT_OUTGOING)
		time_label.add_theme_color_override("font_color", COLOR_TEXT_OUTGOING.darkened(0.2))
		
	else:
		# Вхідне повідомлення (зліва, сіре)
		size_flags_horizontal = SIZE_FILL
		bubble_panel.size_flags_horizontal = SIZE_SHRINK_BEGIN
		
		# Колір фону
		var style = StyleBoxFlat.new()
		style.bg_color = COLOR_INCOMING
		style.corner_radius_top_left = 15
		style.corner_radius_top_right = 15
		style.corner_radius_bottom_left = 3
		style.corner_radius_bottom_right = 15
		style.content_margin_left = 12
		style.content_margin_right = 12
		style.content_margin_top = 8
		style.content_margin_bottom = 8
		bubble_panel.add_theme_stylebox_override("panel", style)
		
		# Колір тексту
		message_text.add_theme_color_override("default_color", COLOR_TEXT_INCOMING)
		time_label.add_theme_color_override("font_color", COLOR_TEXT_INCOMING.lightened(0.4))
