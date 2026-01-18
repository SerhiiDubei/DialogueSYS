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

func setup(message: ChatMessage, _contact: ContactResource):
	# Налаштувати бульбашку
	var is_outgoing = message.is_from_player()
	
	# Текст повідомлення (ЗБІЛЬШЕНИЙ ШРИФТ!)
	message_text.text = message.text
	message_text.add_theme_font_size_override("normal_font_size", 20)
	
	# Час (ЗБІЛЬШЕНИЙ!)
	time_label.text = message.get_time_string()
	time_label.add_theme_font_size_override("font_size", 16)
	
	# Стиль залежно від відправника
	if is_outgoing:
		# Наше повідомлення (справа, синє)
		size_flags_horizontal = SIZE_FILL
		bubble_panel.size_flags_horizontal = SIZE_SHRINK_END
		
		# Колір фону
		var style = StyleBoxFlat.new()
		style.bg_color = COLOR_OUTGOING
		style.corner_radius_top_left = 20
		style.corner_radius_top_right = 20
		style.corner_radius_bottom_left = 20
		style.corner_radius_bottom_right = 5
		style.content_margin_left = 18
		style.content_margin_right = 18
		style.content_margin_top = 14
		style.content_margin_bottom = 14
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
		style.corner_radius_top_left = 20
		style.corner_radius_top_right = 20
		style.corner_radius_bottom_left = 5
		style.corner_radius_bottom_right = 20
		style.content_margin_left = 18
		style.content_margin_right = 18
		style.content_margin_top = 14
		style.content_margin_bottom = 14
		bubble_panel.add_theme_stylebox_override("panel", style)
		
		# Колір тексту
		message_text.add_theme_color_override("default_color", COLOR_TEXT_INCOMING)
		time_label.add_theme_color_override("font_color", COLOR_TEXT_INCOMING.lightened(0.4))
