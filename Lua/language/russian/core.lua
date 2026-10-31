local language = ...

-- Советы и справка
language.TipText = "Совет: "
language.Tips = {
    "После смерти используйте !pointshop, чтобы выбрать доступное существо для перерождения.",
    "У особых ролей есть доступ к своим разделам магазина. Используйте !pointshop, чтобы открыть его.",
    "Используйте !role, чтобы получить информацию о своей текущей роли и целях.",
    "Используйте !help, чтобы получить список основных доступных команд.",
    "Используйте !write, чтобы записать сообщение, которое останется в КПК после вашей смерти.",
    "В режиме Secret капитан и офицеры службы безопасности не выбираются антагонистами.",
    "После смерти могут стать доступны гост-роли. Используйте !ghostrole, чтобы открыть их список.",
    "Если вы управляете гост-ролью, !kill или !suicide вернёт вас в наблюдатели и освободит роль. Обычного персонажа эти команды убивают.",
    "Смерть в первые 15 секунд после перерождения за существо полностью возмещает его стоимость.",
  	"У сервера есть Discord-сообщество: там можно пообщаться и предложить идеи для сервера. https://discord.gg/rFrwmXg8DQ"
}

-- Справка по командам
language.Help = "\n!help - показывает это сообщение помощи\n!helptraitor - показывает команды антагониста\n!helpadmin - показывает команды администратора\n!traitor или !role - показывает информацию о вашей роли и целях\n!pointshop или !shop - открывает магазин очков\n!points - показывает ваши очки, жизни и шанс стать антагонистом\n!status - показывает ваши навыки и активные временные эффекты\n!alive - показывает список живых игроков (для мёртвых игроков и администраторов)\n!locatesub - показывает расстояние и направление до подводной лодки, только для монстров\n!ghostrole - показывает доступные гост-роли; !ghostrole pirate - занять роль pirate\n!suicide - покидает гост-роль или убивает обычного персонажа\n!version - показывает текущую версию Traitor Mod\n!write - записывает сообщение в журнал смерти\n!roundtime - показывает текущее время раунда\n!startgamevote - начинает голосование за режим в лобби."
language.HelpTraitor = "\n!toggletraitor - переключает, может ли игрок быть выбран антагонистом\n!tc [msg] - отправляет сообщение всем антагонистам\n!tannounce [msg] - отправляет объявление всем антагонистам\n!tdm [имя] [msg] - отправляет анонимное сообщение указанному игроку"
language.HelpAdmin = "\n!traitoralive - проверить, остались ли живые антагонисты\n!roundinfo - показать информацию о раунде (спойлер!)\n!endroundnow - немедленно завершить Secret во время финального отсчёта\n!allpoints - показывает количество очков у всех подключённых клиентов\n!addpoint [клиент] [+/-количество] - добавить или убрать очки у клиента\n!addlife [клиент] [+/-количество] - добавить или убрать жизни у клиента\n!revive [клиент] - оживить персонажа данного клиента\n!void [имя персонажа] - отправить персонажа в пустоту\n!unvoid [имя персонажа] - вернуть персонажа из пустоты\n!vote [текст] [вариант1] [вариант2] [...] - начать голосование на сервере\n!giveghostrole [название гост-роли] [персонаж] - назначить персонажу гост-роль."

-- Статус персонажа
language.StatusTitle = "Статус персонажа"
language.StatusSkillsHeader = "Навыки:"
language.StatusEffectsHeader = "Активные временные эффекты:"
language.StatusNoEffects = "- Нет активных временных эффектов"
language.StatusAliveRequired = "Вы должны быть живы, чтобы использовать эту команду."
language.StatusUnknownEffect = "Неизвестный эффект"
language.StatusSkillLine = "- %s: %d"
language.StatusSkillLineWithBonus = "- %s: %d + %d = %d"
language.StatusEffectLine = "- %s — %s"
language.StatusSkillWeapons = "Оружие"
language.StatusSkillMechanical = "Механика"
language.StatusSkillElectrical = "Электрика"
language.StatusSkillMedical = "Медицина"
language.StatusSkillSurgery = "Хирургия"
language.StatusSkillHelm = "Управление"

-- Тестовый режим и базовые состояния
language.TestingMode = "Режим тестирования 1P - нельзя набрать или потерять очки"
language.CMDSwitchTestAvailable = "Для переключения команды используйте !switchtest."
language.CMDSwitchTestUnavailable = "Команда !switchtest доступна только в тестовом режиме Attack & Defends или «Прятки», когда на сервере один активный игрок."
language.CMDSwitchTestChanged = "Тестовая команда переключена: %s."
language.RoundNotStarted = "Раунд не начался"
language.ReceivedPoints = "Вы получили %s очков"
language.Alive = "Жив"
language.Dead = "Мёртв"

-- Возрождение посреди раунда
language.MidRoundSpawnWelcome = ">> Возрождение посреди раунда активно! <<\n\nРаунд уже начался, но вы можете появиться мгновенно!"
language.MidRoundSpawn = "Вы хотите появиться мгновенно или дождаться следующего раунда?\n"
language.MidRoundSpawnMission = "> Возродиться"
language.MidRoundSpawnCoalition = "> Возродиться в Коалиции"
language.MidRoundSpawnSeparatists = "> Возродиться у сепаратистов"
language.MidRoundSpawnWait = "> Ждать"

-- Очки, опыт и жизни
language.PointsInfo = "У вас %s очков и %s/%s жизней"
language.Points = " (%s очков)"
language.Experience = " (%s опыта)"
language.SkillsIncreased = "Хорошая работа по улучшению ваших навыков"
language.PointsAwarded = "Вы получили %s очков"
language.PointsAwardedRound = "В этом раунде вы получили:\n%s очков"
language.ExperienceAwarded = "Вы получили %s опыта"
language.LivesGained = "Вы набрали %s. Теперь у вас есть %s/%s жизней"
language.ALife = "жизнь"
language.Lives = " жизни"
language.Death = "Вы потеряли жизнь. У вас осталось %s, прежде чем вы потеряете очки"
language.NoLives = "Вы потеряли все свои жизни. В результате вы потеряли часть очков"
language.MaxLives = "У вас максимальное количество жизней"

-- Общие ответы и состояния целей
language.CommandTip = "(Введите !traitor в чате, чтобы показать это сообщение снова)"
language.CommandNotActive = "Эта команда деактивирована"
language.Completed = "(Завершено)"
language.Failed = "(Провалено)"
language.SubObjective = "Доп. цели (необязательные):"
language.HuskNewObjective = "Ваша следующая цель - %s"

-- Серверные события и объявления
language.AbyssHelpPart1 = "Входящий сигнал бедствия... п---гит-! -ы -----яли в безд-- и н-м н--на -о--щь бл-к-рат-р за--щил нас вн--. Вз--ен м- предл---ем что-н--удь, ч-о у н-с е--ь, вк-ю-ая н-ши ---0 оч-ков"
language.AbyssHelpPart2 = "Передача прерывается сразу после этого."
language.AbyssHelpPart3 = "Не могу поверить, что мы выбрались живыми! Огромное вам спасибо. Вот обещанные очки. Возьмите этот грузовой скутер и журнал внутри — в нём должны быть обещанные очки."
language.AbyssHelpPart4 = "Вот дерьмо! Кто-то пришел! Огромное спасибо! Пожалуйста, найдите способ вытащить нас отсюда, я дам вам %s моих очков, если вы сможете вытащить меня живым."
language.AbyssHelpPart5 = "Вы можете попробовать достать новый аккумулятор для этой подводной лодки и починить ее."
language.AbyssHelpDead = "Думаю, этим всё и закончится..."
language.AmmoDelivery = "В оружейную зону субмарины доставлены боеприпасы и снаряды для рельсотрона."
language.BeaconPirate = "Поступили сообщения о печально известном пирате в УЗК, терроризирующем эти воды. Недавно его обнаружили на станции маяка. Уничтожьте пирата, чтобы весь экипаж получил награду в %s очков."
language.WreckPirate = "Поступили сообщения о печально известном пирате в УЗК, терроризирующем эти воды. Недавно его обнаружили внутри затонувшей подводной лодки. Ликвидируйте пирата, чтобы весь экипаж получил награду в %s очков."
language.PirateInside = "Внимание! Опасный пират в УЗК был обнаружен внутри главной подводной лодки!"
language.PirateKilled = "Пират в УЗК убит, команда получила награду в %s очков."
language.UPCPirate = "Защищайте это место, чтобы получить %s очков. Также вы можете попытаться напасть на подлодку."
language.UPCPirateObjective = "Защищайте это место, чтобы получить %s очков в конце раунда, либо отправляйтесь на главную подлодку. Если вы лично убьёте весь экипаж на ней, вы получите %s очков. Если лодка пуста, удерживайте её изнутри %s секунд и получите %s очков за захват."
language.PirateEliminatedCrew = "Пират в УЗК уничтожил весь экипаж на подлодке и получил %s очков. Экипаж провалил раунд."
language.PirateCaptureStarted = "Пират в УЗК начал захват подлодки. Вернитесь в течение %s секунд, иначе экипаж провалит раунд."
language.PirateCaptureInterrupted = "Захват подлодки пиратом в УЗК был сорван."
language.PirateCapturedSubmarine = "Пират в УЗК захватил подлодку и получил %s очков. Экипаж провалил раунд."
language.ClownMagic = "Вы чувствуете что-то странное и внезапно оказываетесь в другом месте."
language.CommunicationsOffline = "Что-то вмешивается во все наши системы связи. По оценкам, связь будет отключена не менее чем на %s минут."
language.CommunicationsBack = "Связь восстановлена"
language.EmergencyTeam = "Группа инженеров и механиков прибыла на подводную лодку, чтобы помочь с ремонтом."
language.ElectricalFixDischarge = "Неизвестная сила отремонтировала необходимые для выживания устройства на подводной лодке. Судя по всему, это были фиксики: устройства восстановлены на 33%."
language.FixHull = "Неизвестная сила отремонтировала корпус подводной лодки. Судя по всему, это были корпусные фиксики: прочность корпуса восстановлена на 50 единиц."
language.FullElectricalFixDischarge = "Неизвестная сила полностью отремонтировала необходимые для выживания устройства на подводной лодке. Судя по всему, фиксики устали смотреть, как вы умираете."
language.FullFixHull = "Неизвестная сила отремонтировала корпус подводной лодки. Судя по всему, корпусные фиксики устали смотреть, как вы умираете: прочность корпуса восстановлена на 1000 единиц."
language.BreackElectrical = "Электроника повреждена на 33%."
language.BreackHull = "Корпус повреждён на 50 единиц."
language.KillElectrical = "Электроника полностью выведена из строя."
language.KillHull = "Корпус повреждён на 1000 единиц."
language.LightsOff = "Все огни внезапно погасли, но питание по-прежнему включено? Что происходит?"
language.MaintenanceToolsDelivery = "В грузовой отсек корабля доставлены инструменты для технического обслуживания. Они находятся в жёлтом ящике."
language.MedicalDelivery = "В медицинский отсек корабля доставлены медицинские принадлежности. Они находятся в красном медицинском ящике."
language.PrisonerAboard = "На борту находится заключённый. Держите его живым и в наручниках до прибытия в пункт назначения, чтобы команда получила %s очков."
language.PrisonerYou = "Вы — заключённый! Если вам удастся отойти от подводной лодки на 500 метров, вы получите %s очков."
language.PrisonerSuccess = "Заключённый успешно доставлен. Экипаж получил награду в %s очков."
language.PrisonerFail = "Заключённый сбежал. Награда за транспортировку отменена."
language.OxygenSafe = "Воздух из кислородного генератора снова безопасен для дыхания."
language.OxygenHusk = "Кислородный генератор был саботирован: в воздух попали яйца трупных паразитов. У тех, кто дышит этим воздухом, есть около 15 секунд, чтобы надеть маску или скафандр, прежде чем заражение станет опасным!"
language.OxygenPoison = "Кислородный генератор был саботирован: в воздух попал страданит. У тех, кто дышит этим воздухом, есть около 15 секунд, чтобы надеть маску или скафандр, прежде чем доза станет опасной!"
language.PirateCrew = "Внимание! В этих водах замечен пиратский корабль! Уничтожьте пиратский реактор или убейте всех пиратов, чтобы весь экипаж получил награду в %s очков."
language.EmergencyYou = "Вы член аварийной команды! Почините подлодку даже ценой своей жизни и постарайтесь спасти оставшийся экипаж. Помните: эта роль не даёт права убивать игроков или гриферить на подлодке."
language.PirateCrewYou = "Вы являетесь частью пиратской команды этой подводной лодки! Защитите подводную лодку от любых грязных коалиций, пытающихся получить то, что принадлежит вам!"
language.PirateCrewSuccess = "Пираты сдались, команда получила награду в %s очков."
language.InvisibilityTraitor = "ПРЕДУПРЕЖДЕНИЕ! На корабле замечена очень странная одежда. Будьте настороже: она обладает необычными свойствами. Странные сигнатуры этой одежды видны через тепловизор."
language.FriendPet = "Вы питомец! Помогайте людям и защищайте экипаж от существ. Помните: эта роль не даёт права убивать игроков или гриферить на подлодке."
language.ShadyMissionPart1 = "Вы засекли странную радиопередачу, похоже, они ищут кого-то, кто выполнит для них работу."
language.ShadyMissionPart2 = "\"О, привет! Мы ищем человека, который выполнит для нас одно простое задание. Мы готовы заплатить за него до 3000 очков. Заинтересованы?\""
language.ShadyMissionPart2Answer = "Конечно! Что это?"
language.ShadyMissionPart3 = "\"В этом районе, куда направляется ваша подводная лодка, есть старая разбитая подводная лодка, где нам нужно разместить некоторые припасы. Поскольку сейчас у нас нет припасов, вам придется достать их самостоятельно. Нам понадобится минимум 8 любых медицинских предметов, 4 кислородных баллона, 2 заряженных пистолета любого типа и специальный гидролокационный маяк. За эти припасы мы заплатим 1500 очков, если вы добавите другие припасы, мы дадим вам до 1500 дополнительных очков.\""
language.ShadyMissionPart3Answer = "Звучит подозрительно, зачем вам понадобилось класть эти припасы в затонувшую подводную лодку?!"
language.ShadyMissionPart4 = "\"Теперь это не твое дело, сделаешь ты это или нет?\""
language.ShadyMissionPart4AnswerAccept = "Принять предложение"
language.ShadyMissionPart4AnswerDeny = "Отклонить предложение"
language.ShadyMissionPart5 = "\"Отлично! Просто положите все припасы и специальный сонарный маяк в металлический ящик и оставьте его на затонувшем корабле.\""
language.ShadyMissionPart5Answer = "Я сделаю все возможное"
language.ShadyMissionBeacon = "‖color:gui.red‖Кажется, маяк был модифицирован.\nСзади висит записка: \"8 медицинских предметов, 4 кислородных баллона и 2 заряженных пистолета.\"‖color:end‖"
language.SuperBallastFlora = "В этой области обнаружена высокая концентрация спор балластной флоры, рекомендуется обыскать насосы на предмет балластной флоры!"
language.Answer = "Ответить"
language.Ignore = "Игнорировать"
language.ItemsBought = "Предметы, купленные в магазине"
language.CrewBoughtItem = "Игроки купили предметы в магазине"
language.PointsGained = "Общее количество набранных очков"
language.PointsLost = "Общее количество потерянных очков"
language.Spawns = "Появившиеся игроки"
language.CrewDeaths = "Смерти"
language.Rounds = "Общая статистика раунда"
language.Yes = "Да"
language.No = "Нет"

-- Способности профессий и случайные эффекты
language.AbilityNoTurretSlots = "На этой подлодке нет свободных слотов под эту пушку."
language.ReactorShutdown = "На реакторе произошёл критический сбой, и он отключился для самосохранения."
language.SupercapacitorFailure = "Из-за короткого замыкания на суперконденсаторы подалось напряжение 220 В. Они вышли из строя и потеряли весь запас энергии."
language.JunctionBoxOverload = "Из-за сбоя в реакторе на электрощитки прилетело огромное напряжение. Все щитки требуют ремонта."
language.OxygenSufforin = "В кислородной системе появился опасный реагент. Воздух кажется неправильным."
language.OxygenParalyzant = "Кто-то испортил кислородную систему. Воздух вызывает тревогу."
language.OxygenMorbusine = "Кислородная система была саботирована. Воздух ощущается токсичным."
language.OxygenCyanide = "Кислородная система была саботирована. Воздух внезапно стал смертельно опасным."
language.WeakBallastFlora = "Слабая форма балластной флоры заразила несколько балластных насосов."
language.CaptainHelmBoost = "Вы чувствуете воодушевление, теперь вы намного лучше управляете подлодкой на 5 минут."
language.SecurityMindSense = "Вы чувствуете странные ощущения, теперь вы можете 5 минут видеть всех сквозь стены, но у этого есть побочный эффект..."
language.MechanicMechanicalRepair = "Механик позвал фиксиков помочь с ремонтом, но они не очень старались и починили всю механику на 15%."
language.MechanicHullRepair = "Механик позвал корпусных фиксиков помочь с ремонтом, и они починили весь корпус на 50%."
language.MechanicSkillBoost = "Вы чувствуете воодушевление, теперь вы намного лучше чините корпус и механику на 5 минут."
language.EngineerElectricalRepair = "Инженер позвал фиксиков помочь с ремонтом, но они не очень старались и починили всю электрику на 10%."
language.EngineerSkillBoost = "Вы чувствуете воодушевление, теперь вы намного лучше чините электроприборы на 5 минут."
language.MedicSkillBoost = "Вы чувствуете воодушевление, теперь вы намного лучше занимаетесь медициной и можете хирургировать на 5 минут."
language.SurgeonSkillBoost = "Вы чувствуете воодушевление, теперь вы намного лучше хирургируете на 5 минут."
language.SecurityTurretInstalled = "Служба безопасности установила %s на свободный слот турели."
language.EuropeanForceTurretInstalled = "Европейская сила установила %s на свободный слот турели."
language.VentCreaturesWarning = "Где-то в вентиляции раздаются чужие шорохи и тихий скрежет. Внутри точно кто-то есть."
language.ClownCrateWarning = "На подлодке появился подозрительный клоунский ящик."
language.ClownCrateMonster = "Клоунский ящик открылся, и оттуда выпрыгнуло что-то опасное."
language.ClownCratePet = "Клоунский ящик открылся, и оттуда вылез странный питомец."
language.ClownCrateNpc = "Клоунский ящик открылся, и внутри оказался очень растерянный человек."
language.ClownCrateLoot = "Клоунский ящик раскрылся и вывалил добычу из поинтшопа."
language.RescueSuccess = "Спасение прошло успешно. Каждый живой член экипажа получил %s очков."
language.RescueFail = "Операция по спасению провалилась."
language.WreckRescue = "В разрушенной подлодке замечен выживший. Доставьте его живым на основную лодку, и каждый живой член экипажа получит %s очков."
language.BeaconRescue = "На маяке замечен выживший. Доставьте его живым на основную лодку, и каждый живой член экипажа получит %s очков."
language.RescueYou = "Останьтесь в живых и доберитесь до основной подлодки. Если вы спасётесь, экипаж получит награду."
language.WreckRescueName = "Выживший из обломков"
language.BeaconRescueName = "Выживший с маяка"

-- Команды: ответы, usage и ошибки
language.CMDLocatePlayer = "Игрок %s находится в %s м от вас, направление %s, на %s."
language.CMDPlaytime = "Ваше время в игре: %s."
language.FakeHandcuffsUsage = "Вы можете освободиться от этих наручников с помощью !fhc."
language.Pets = "Питомцы"
language.SmallCreatures = "Мелкие существа"
language.LargeCreatures = "Крупные существа"
language.AbyssCreature = "Существо бездны"
language.ElectricalDevices = "Электрические устройства"
language.MechanicalDevices = "Механические устройства"
language.CMDAliveToUse = "Вы должны быть живы, чтобы использовать эту команду"
language.CMDAliveDeadOnly = "Вы должны быть мертвы, чтобы использовать эту команду, если у вас нет прав администратора."
language.CMDNoRole = "У вас нет особой роли"
language.CMDAlreadyDead = "Вы уже мертвы!"
language.CMDHandcuffed = "Вы не можете использовать эту команду, пока скованы наручниками"
language.CMDKnockedDown = "Вы не можете использовать эту команду, пока вы без сознания"
language.GamemodeNone = "Режим игры: Нет"
language.CMDPermisionPoints = "У вас нет прав на добавление очков"
language.CMDInvalidNumber = "Неверное значение числа"
language.CMDClientNotFound = "Не удалось найти клиента с этим именем или Steam ID."
language.CMDCharacterNotFound = "Не удалось найти персонажа с указанным именем"
language.CMDAdminAddedPointsEveryone = "Администратор добавил %s очков всем"
language.CMDAdminAddedPoints = "Администратор добавил %s очков %s"
language.CMDAdminAddedLives = "Администратор добавил %s жизней %s"
language.CMDOnlyMonsters = "Только монстры могут использовать эту команду"
language.CMDLocateSub = "Подводная лодка находится на расстоянии %s м от вас, направление: %s."
language.CMDRoundTime = "Этот раунд длится уже %s минут"
language.CMDMonsterBroadcast = "[%s %s]: %s"
language.UnknownCommand = "Неизвестная команда. Напишите !help, чтобы посмотреть список доступных команд."
language.MonsterBeaconDescription = "‖color:196, 90, 32, 255‖Модифицированный сонарный маяк. Если оставить его активным на 30 секунд, он приманит стаю чудовищ снаружи подлодки.‖color:end‖"
language.ReachedClassLimit = "Достигнут лимит класса"
language.CMDVersion = "Запущен Evil Factory's Traitor Mod v%s"
language.Unknown = "Неизвестно"
language.CommandError = "Ошибка команды: %s"
language.CMDFreeHandcuffsDead = "Вы мертвы!"
language.CMDFreeHandcuffsNotFake = "Эти наручники не фальшивые!"
language.CMDDeathLogUnable = "Вы не можете писать в журнал смерти."
language.CMDDeathLogWrote = "Записано в журнал смерти: \"%s\"."
language.CMDMidRoundAlreadySpawned = "Вы уже появлялись."
language.CMDMidRoundNotInGame = "Вы не в игре."
language.CMDTraitorChatUsage = "Использование: !tc [сообщение]"
language.CMDTraitorAnnounceUsage = "Использование: !tannounce [сообщение]"
language.CMDTraitorDirectMessageUsage = "Использование: !tdm [имя] [сообщение]"
language.CMDTraitorDirectMessageNameNotFound = "Имя не найдено."
language.CMDInGameToUse = "Вы должны быть в игре, чтобы использовать эту команду."
language.CMDPlayersSubmarineRoyaleOnly = "Эта команда доступна только в Submarine Royale."
language.CMDVoteUsage = "Использование: !vote \"Текст\" \"Вариант 1\" \"Вариант 2\" ... \"Вариант N\""
language.CMDVoteResultsHeader = [=[Результаты голосования: %s

]=]
language.CMDVoteResultsLine = [=[%s: %s голосов
]=]
language.CMDAllPointsLine = "%s: %s очков - %s веса"
language.CMDAddPointUsage = "Неверное количество аргументов. Использование: !addpoint \"Имя клиента\" 500"
language.CMDAddLifeUsage = "Неверное количество аргументов. Использование: !addlife \"Имя клиента\" 1"
language.CMDAlreadyMaximumLives = "У %s уже максимальное количество жизней."
language.CMDCharacterDeadOrMissing = "Персонаж клиента мёртв или отсутствует."
language.CMDVoidSent = "Персонаж отправлен в войд."
language.CMDVoidNotInVoid = "Этот персонаж не находится в войде."
language.CMDVoidRemoved = "Персонаж убран из войда."
language.CMDReviveSuccess = "Персонаж %s оживлён и получил 1 жизнь обратно."
language.CMDReviveAnnounce = "Администратор оживил %s."
language.CMDReviveNotDead = "Персонаж %s не мёртв."
language.CMDReviveNotFound = "Персонаж %s не найден."
language.CMDOngoingEvents = "Текущие события: "
language.CMDGiveGhostRoleUsage = "Использование: !giveghostrole <название гост-роли> <персонаж>"
language.CMDAssignRoleCharacterUsage = "Использование: !assignrole <персонаж> <роль>"
language.CMDAssignRoleClientUsage = "Использование: !assignrole <клиент> <роль>"
language.CMDAssignRoleNotFound = "Не удалось найти роль для назначения."
language.CMDAssignRoleSuccess = "Игроку %s назначена роль %s."
language.CMDTriggerEventUsage = "Использование: !triggerevent <название события>"
language.CMDTriggerEventNotFound = "Событие %s не существует."
language.CMDTriggerEventSuccess = "Запущено событие %s."
language.CMDOClock = "%s часов"
language.CMDMonsterUsage = "Использование: !monster сообщение"
language.CMDCommandCooldown = "Подождите немного перед повторным использованием этой команды."
language.CMDDropPointsUsage = "Использование: !droppoints количество"
language.CMDDropPointsInvalidAmount = "Укажите корректное число от 100 до 100000."
language.CMDDropPointsNotEnough = "У вас недостаточно очков для сброса."
language.CMDDropPointsFailed = "Не удалось выбросить очки. Попробуйте ещё раз."
language.CMDDropPointsDropped = "Выброшено %s очков."

-- Системные сообщения сервера
language.ChatSenderServer = "Сервер"
language.WelcomeMessage = [=[Добро пожаловать в Void Traitor!

Это сервер с собственным Traitor Mod, особыми ролями, целями, магазином и отдельными игровыми режимами.
Здесь мы играем в «Миссии с предателями», «Attack & Defends», «Прятки» и другие режимы.

У сервера есть Discord-сообщество, где публикуются сообщения о запусках, гайды и новости. Там же можно предложить идеи для сервера:
наш сервер — https://discord.gg/rFrwmXg8DQ
сервер партнёров Project Encelada — https://discord.gg/encelada

Для более удобного доступа к меню и магазину можно установить:
Traitor Menu (для работы нужен клиентский LuaCs)
https://steamcommunity.com/sharedfiles/filedetails/?id=2990694897

Команды вводятся в чат без «/»:
!help — список основных команд
!points / !point — очки, жизни и шанс стать антагонистом
!pointshop / !shop / !ps — магазин
!traitor / !role — текущая роль и задачи
!suicide / !kill — покинуть гост-роль или совершить самоубийство.

Правила:
Запрещено быть мудаком.
Запрещено гриферить и убивать игроков вне правил текущего режима или своей роли.
В Secret капитан и офицеры службы безопасности не выбираются антагонистами.]=]

-- Описания специальных предметов
language.ItemDescriptionCultistBeacon = "‖color:160, 32, 240, 255‖Модифицированный сонарный маяк. На нём написано: \"Оставь активным на 30 секунд для сюрприза.\"‖color:end‖"
language.ItemDescriptionActiveHuskEggs = "Крайне активные яйца хаска."
language.ItemDescriptionExplosiveAutoInjector = "Модифицированный блок C-4, который можно положить внутрь автоинжекторной гарнитуры."
language.ItemDescriptionTeleporterRevolver = "‖color:gui.red‖Особый револьвер с функциями телепортации...‖color:end‖"

-- Команда статистики
language.CMDStatsDefaultCategory = "Статистика"
language.CMDStatsNoStats = "Статистика не найдена."
language.CMDStatsAvailable = "Доступная статистика:"
language.CMDStatsNoneAvailable = "Статистика пока недоступна. Начните раунд, чтобы собрать статистику."
language.CMDStatsUsage = "Введите '!stats [option]', чтобы показать статистику."
language.CMDStatsLobbyOnly = "Статистика недоступна в раунде. Используйте эту команду в лобби."
language.CMDStatsUnavailable = "Статистика ещё не загружена."
