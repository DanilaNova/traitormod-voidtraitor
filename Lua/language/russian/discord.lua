local language = ...

-- Названия режимов
language.DiscordModeSecret = "Миссии с предателями"
language.DiscordModeMission = "Миссия"
language.DiscordModeAttackDefend = "Attack & Defend"
language.DiscordModeHideAndSeek = "Прятки"
language.DiscordModePvP = "PvP"
language.DiscordModeMultiplayerCampaign = "Кампания"
language.DiscordModeUnknown = "Неизвестно"

-- Статус сервера
language.DiscordStatusLobbyText = "Лобби"
language.DiscordStatusRoundText = "Игра"
language.DiscordStatusUnknownText = "Неизвестно"
language.DiscordNextRoundPrefix = "Следующий"
language.DiscordNoSelectionText = "Не выбрано"
language.DiscordNoDurationText = "—"
language.DiscordFooterText = "VoidTraitor"

-- Поля Discord-сообщений
language.DiscordFieldRound = "Раунд"
language.DiscordFieldMode = "Режим"
language.DiscordFieldStatus = "Статус"
language.DiscordFieldPlayers = "Игроков"
language.DiscordPlayersValue = "%d из %d"
language.DiscordFieldDuration = "Время раунда"
language.DiscordFieldMap = "Карта"
language.DiscordFieldSubmarine = "Подлодка"

-- Формат длительности
language.DiscordDurationHoursMinutes = "%d ч %d мин"
language.DiscordDurationMinutesSeconds = "%d мин %d сек"
language.DiscordDurationSeconds = "%d сек"

-- События сервера и игроков
language.DiscordServerStarted = "Сервер запущен: **%s**"
language.DiscordPlayerConnected = "На сервер зашёл **%s**\nИгроков сейчас: **%d/%d**"
language.DiscordPlayerDisconnected = "С сервера вышел **%s**\nИгроков сейчас: **%d/%d**"
language.DiscordRoundStarted = "Раунд начинается #**%d**\nРежим: **%s**\nИгроков на старте: **%d/%d**"
language.DiscordRoundEndedGeneric = "Раунд #**%d** завершился, длился **%s**."
language.DiscordRoundEndedAttackDefend = "Раунд #**%d** завершился, длился **%s**, победила **%s**."
language.DiscordRoundEndedSecret = "Раунд #**%d** завершился. Выжившие антагонисты: **%d/%d**. Выжившие члены экипажа: **%d/%d**. Длительность: **%s**. Антагонисты: **%s**."

-- Результаты раунда
language.DiscordWinnerTeamBlue = "синяя команда"
language.DiscordWinnerTeamRed = "красная команда"
language.DiscordWinnerTeamUnknown = "неизвестная команда"
language.DiscordUnknownTraitors = "неизвестно"

-- Ошибки и служебные сообщения webhook
language.DiscordReadJsonFailed = "Не удалось прочитать JSON-файл Discord: %s"
language.DiscordDebugResponse = "Ответ Discord %s: %s | %s"
language.DiscordWebhookFailed = "Ошибка Discord webhook: %s"
language.DiscordStatusManualSetup = "Тестовое статус-сообщение для ручной настройки. Скопируйте ID этого сообщения в Discord и вставьте его в config.Discord.Status.MessageId."
language.DiscordTestMessageFailed = "Не удалось отправить тестовое статус-сообщение Discord: %s | %s"
language.DiscordTestMessageSent = "Тестовое статус-сообщение Discord отправлено один раз. Скопируйте его ID вручную и вставьте в config.Discord.Status.MessageId."
language.DiscordStatusMessageIdMissingManual = "Не указан ID статус-сообщения Discord. Скопируйте ID тестового сообщения вручную и вставьте его в config.Discord.Status.MessageId."
language.DiscordStatusMessageIdMissingAuto = "Не указан ID статус-сообщения Discord. Укажите config.Discord.Status.MessageId или включите AutoCreateMessageIfMissing."
language.DiscordCreateMessageFailed = "Не удалось создать статус-сообщение Discord: %s | %s"
language.DiscordParseMessageIdFailed = "Не удалось разобрать ID статус-сообщения Discord из ответа."
language.DiscordStatusMessageCreated = "Статус-сообщение Discord создано. ID сообщения: %s"
language.DiscordStatusRateLimited = "Discord ограничил запросы к статусу. Следующая попытка через %s сек."
language.DiscordStatusUpdateFailed = "Не удалось обновить статус-сообщение Discord: %s | %s"
