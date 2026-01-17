@tool
extends EditorScript

# Скрипт для швидкого налаштування OpenRouter API ключа в AI Assistant Hub
# Запустіть через: File → Run Script → виберіть цей файл

func _run() -> void:
	var api_key = "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"
	
	if api_key.is_empty():
		print("❌ ПОМИЛКА: API ключ порожній!")
		return
	
	if not ClassDB.class_exists("LLMConfigManager"):
		print("❌ ПОМИЛКА: LLMConfigManager не знайдено.")
		print("   Переконайтеся, що AI Assistant Hub плагін активовано.")
		return
	
	var config = LLMConfigManager.new("openrouter_api")
	config.save_key(api_key)
	
	print("✅ API ключ успішно збережено для OpenRouter!")
	print("")
	print("📝 Наступні кроки:")
	print("   1. Відкрийте вкладку 'AI Hub' (внизу редактора)")
	print("   2. Виберіть провайдер 'OpenRouter' зі списку")
	print("   3. Натисніть 'Refresh Models' щоб побачити доступні GPT моделі")
	print("   4. Виберіть модель (рекомендую: openai/gpt-4-turbo)")
	print("   5. Натисніть 'New assistant type' щоб створити асистента")
	print("")
	print("💡 Найкращі моделі для кодування:")
	print("   - openai/gpt-4-turbo (найкраща)")
	print("   - openai/gpt-4")
	print("   - openai/gpt-3.5-turbo (швидка та дешевша)")
