local language = {}
language.Name = "Russian"

language.TipText = "Совет: "
language.Tips = {
    "Вы можете использовать !pointshop чтобы стать сувществом, когда вы мертвы.",
    "У предателей есть доступ в свой особый магазин. Используйте !pointshop чтобы открыть его.",
    "Вы можете использовать !role чтобы получить информацию о статусе вашей конкретной роли.",
    "Вы можете использовать !help чтобы получить список всех доступных команд.",
    "Вы можете использоватьe !write чтобы написать сообщение, которое останется в кпк после вашей смерти.",
    "Капитан и Оффицеры Службы Безопасности не могут быть предателями.",
    "Роли станут доступны когда вы умрете, вы можете использовать !ghostrole чтобы использовать их.",
    "Использование команды !kill в чате просто переносит вас обратно в список наблюдателей, не убивая роль.",
    "Смерть в первые 15 секунд после перерождения за существо полностью возмещает его стоимость.",
  	"У нас есть свой сервер в дискорде! Там сможете пообщаться с нами и возможно что то предложить для сервера. https://discord.gg/rFrwmXg8DQ"
}

language.Help = "\n!help - показывает это сообщение помощи\n!helptraitor - показывает все команды предателя\n!helpadmin - показывает все команды администратора\n!traitor - показывает информацию о предателе\n!pointshop или !shop - открывает магазин очков\n!points - показывает ваши очки и жизни\n!alive - показывает список живых игроков (только во время смерти)\n!locatesub - показывает расстояние и направление подводной лодки, только для монстров\n!ghostrole - команда чтоб вселиться в гостроль (как надо !ghostrole pirate)\n!suicide - убивает вашего персонажа\n!version - показывает текущую версию трейтормода\n!write - записывает в ваш журнал смерти\n!roundtime - показывает текущее время раунда !startgamevote - начинает голосование за режим в лобби."
language.HelpTraitor = "\n!toggletraitor - переключает, может ли игрок быть выбран предателем\n!tc [msg] - отправляет сообщение всем предателям\n!tannounce [msg] - отправляет объявление для предателей\n!tdm [Имя] [msg] - отправляет анонимное сообщение данному игроку"
language.HelpAdmin = "\n!traitoralive - проверить, все ли предатели умерли\n!roundinfo - показать информацию о раунде (спойлер!)\n!allpoints - показывает количество очков у всех подключенных клиентов\n!addpoint [Client] [+/-Amount] - добавить очки клиенту\n!addlife [Client] [+/-Amount] - добавить жизнь(и) клиенту\n! оживить [клиент] - оживить персонажа данного клиента\n!void [имя персонажа] - отправить персонажа в пустоту\n!unvoid [имя персонажа] - вернуть персонажа из пустоты\n!vote [текст] [опция1] [опция2] [...] - начать голосование на сервере\n!giveghostrole [текст] [персонаж] - назначить персонажа с указанным именем на роль призрака."

language.TestingMode = "Режим тестирования 1P - нельзя набрать или потерять очки"

language.NoTraitor = "Вы не предатель"
language.TraitorOn = "Вы можете быть выбраны в качестве предателя"
language.TraitorOff = "Вы не можете быть выбраны в качестве предателя.\n\nИспользуйте !toggletraitor, чтобы изменить это."
language.RoundNotStarted = "Раунд не начался"

language.ReceivedPoints = "Вы получили %s очков"

language.AllTraitorsDead = "Все предатели мертвы!"
language.TraitorsAlive = "Есть живые предатели..."

language.Alive = "Жив"
language.Dead = "Мертв"

language.KilledByTraitor = "Ваша смерть может быть вызвана предателем, выполняющим секретное задание"

language.TraitorWelcome = "Вы - предатель!"
language.TraitorDeath = "Вы провалили задание. В результате миссия была отменена, и вы вернетесь в составе команды.\n\nВы больше не предатель, так что играйте хорошо!"
language.TraitorDirectMessage = "Вы получили секретное сообщение от предателя:\n"
language.TraitorBroadcast = "[Предатель %s]: %s"

language.NoObjectivesYet = " > Целей пока нет... Ждите дальнейших указаний."

language.MainObjectivesYou = "Ваши главные цели:"
language.SecondaryObjectivesYou = "Ваши второстепенные цели:"
language.MainObjectivesOther = "Их главными целями были:"
language.SecondaryObjectivesOther = "Их второстепенными целями были:"

language.CrewMember = "Вы член экипажа подводной лодки.\n\nВам были назначены следующие бонусные цели.\n\n"

language.SoloAntagonist = "Вы единственный антагонист."
language.Partners = "Напарники: %s"
language.TcTip = "Используйте !tc для общения с вашими напарниками"

language.TraitorYou = "Вы предатель!"
language.TraitorOther = "Предатель %s"
language.HonkMotherYou = "Вы дитя Красного Носа!"
language.HonkMotherOther = "Клоун %s"
language.CultistYou = "Вы культист хаска!\nЛюди, которых вам удалось превратить в хасков, будут на вашей стороне и смогут помочь вам."
language.CultistOther = "Культист %s"
language.HuskServantYou = "Теперь вы слуга церкви хаска!\nВы напрямую выполняете приказы культистов церкви хаска."
language.HuskServantOther = "Слуга Хаска %s."
language.HuskCultists = "Культисты Хаска: %s\n"
language.HuskServantTcTip = "Вы не можете говорить, но вы можете использовать !tc для общения с культистами хаска."

language.AgentNoticeCodewords = "На этой подводной лодке есть и другие агенты. Вы не знаете их имен, но у вас есть способ общения. Используйте кодовые слова для приветствия агента и кодовый ответ для ответа. Замаскируйте эти слова в обычную фразу, чтобы экипаж ничего не заподозрил"

language.AgentNoticeNoCodewords = "На этой подводной лодке есть и другие агенты. Вы знаете их имена, сотрудничайте с ними, так у вас будет больше шансов на успех."

language.AgentNoticeOnlyTraitor = "Вы единственный предатель на этом корабле, действуйте осторожно"

language.GhostRoleAvailable = "[Роли] Доступна новая роль: %s (‖color:gui.orange‖!ghostrole‖color:end‖ откроет меню гостролей, а ‖color:gui.orange‖!ghostrole %s‖color:end‖ сразу примет роль)"
language.GhostRolesDisabled = "Роли отключены"
language.GhostRolesSpectator = "Только наблюдатели могут использовать роли"
language.GhostRolesInGame = "Вы должны быть в игре, чтобы использовать роли призраков"
language.GhostRolesDead = "(Мертв)"
language.GhostRolesTaken = "(Уже взяты)"
language.GhostRolesNotFound = "Роль не найдена, вы правильно ввели имя? Доступные роли: \n\n"
language.GhostRolesTook = "Кто-то уже взял эту роль."
language.GhostRolesAlreadyDead = "Похоже, эта роль уже мертва, жаль!"
language.GhostRolesReminder = "Доступны роли: %s\n\n‖color:gui.orange‖!ghostrole‖color:end‖ откроет меню гостролей, а ‖color:gui.orange‖!ghostrole имя‖color:end‖ сразу выберет роль."

language.MidRoundSpawnWelcome = ">> Возрождение посреди раунда активно! <<\n\nРаунд уже начался, но вы можете появиться мгновенно!"
language.MidRoundSpawn = "Вы хотите появиться мгновенно или дождаться следующего раунда?\n"
language.MidRoundSpawnMission = "> Возродиться"
language.MidRoundSpawnCoalition = "> Возродиться в Коалиции"
language.MidRoundSpawnSeparatists = "> Возродиться у сепаратистов"
language.MidRoundSpawnWait = "> Ждать"

language.RoundSummary = "| Краткое содержание раунда |"
language.Gamemode = "Режим игры: %s"
language.RandomEvents = "Случайные события: %s"
language.ObjectiveCompleted = "Задач выполнено: %s"
language.ObjectiveFailed = "Задач провалено: %s"

language.CrewWins = "Экипаж успешно выполнил задание!"
language.TraitorHandcuffed = "Экипаж заковал предателя в наручники %s"
language.TraitorsWin = "Предатели успешно выполнили свои задачи!"

language.TraitorsRound = "Предатели раунда:"
language.NoTraitors = "Предателей нет"
language.TraitorAlive = "Вы выжили будучи предателем"

language.PointsInfo = "У вас %s очков и %s/%s жизней"
language.TraitorInfo = "Ваш шанс стать предателем составляет %s%%, по сравнению с остальными членами экипажа."

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

language.Codewords = "Кодовые слова: %s"
language.CodeResponses = "Кодовые ответы: %s"

language.OtherTraitors = "Список предателей: %s"

language.CommandTip = "(Введите !traitor в чате, чтобы показать это сообщение снова)"
language.CommandNotActive = "Эта команда деактивирована"

language.Completed = "(Завершено)"

language.Objective = "Основные цели:"
language.SubObjective = "Доп. цели (необязательные):"

language.NoObjectives = "Нет целей"
language.NoObjectivesYet = "Целей пока нет..."

language.ObjectiveAssassinate = "Уничтожить %s"
language.ObjectiveAssassinateDrunk = "Убить %s, будучи пьяным"
language.ObjectiveAssassinatePressure = "Раздавить %s высоким давлением"
language.ObjectiveBananaSlip = "Заставить поскользнуться %s на бананах (%s/%s) раз"
language.ObjectiveDestroyCaly = "Разрушить %s каликсанид(а)"
language.ObjectiveDetonateLocation = "Подорвать заряд в %s"
language.ObjectiveDetonateLocationWithVictim = "Подорвать заряд в %s и вывести из строя %s"
language.ObjectiveDetonateLocationBridge = "мостике"
language.ObjectiveDetonateLocationMedbay = "медичке"
language.ObjectiveDetonateLocationShield = "щитовой"
language.ObjectiveDrunkSailor = "Напоить %s более чем на 80%"
language.ObjectiveGrowMudraptors = "Вырастить (%s/%s) грязевых рапторов"
language.ObjectiveHusk = "Полностью превратить %s хаска"
language.ObjectiveTurnHusk = "Превратить себя в хаска"
language.ObjectiveSurvive = "Выполнить хотя бы одну задачу и пережить смену"
language.ObjectiveStealCaptainID = "Украсть удостоверение капитана"
language.ObjectiveStealID = "Украсть удостоверение %s на %s секунд"
language.ObjectiveKidnap = "Надеть наручники на %s на %s секунд"
language.ObjectivePoisonCaptain = "Отравить %s используя %s"
language.ObjectiveWreckGift = "Захватить подарок"

language.ObjectiveFinishAllObjectives = "Завершить все цели и получить 1 жизнь"
language.ObjectiveFinishRoundFast = "Завершить раунд менее чем за 20 минут"
language.ObjectiveHealCharacters = "Вылечить на (%s/%s) хп"
language.ObjectiveKillMonsters = "Убить (%s/%s) %s"
language.ObjectiveRepair = "Починить (%s/%s) %s"
language.ObjectiveRepairHull = "Заварить (%s/%s) пробоин в корпусе"
language.ObjectiveSecurityTeamSurvival = "Убедитесь, что хотя бы один оффицер службы безопасности выжил"

language.ObjectiveText = "Убейте экипаж, чтобы завершить миссию"

language.AssassinationNextTarget = "Не высовываться до дальнейших указаний"
language.AssassinationNewObjective = "Ваша следующая цель для убийства - %s"
language.CultistNextTarget = "Церковь хаска ценит ваши усилия, скоро будет назначена новая цель"
language.HuskNewObjective = "Ваша следующая цель - %s"
language.AssassinationEveryoneDead = "Отличная работа агент, вы справились!"
language.HonkmotherNextTarget = "Красный нос доволен вашей работой, но вам еще многое предстоит сделать, ждите дальнейших указаний."
language.HonkmotherNewObjective = "Ваша следующая цель - %s, раздавите её давлением."

language.AbyssHelpPart1 = "Входящий сигнал бедствия... п---гит-! -ы -----яли в безд-- и н-м н--на -о--щь бл-к-рат-р за--щил нас вн--. Вз--ен м- предл---ем что-н--удь, ч-о у н-с е--ь, вк-ю-ая н-ши ---0 оч-ков"
language.AbyssHelpPart2 = "Передача прерывается сразу после этого."
language.AbyssHelpPart3 = "Не могу поверить, что мы выбрались живыми, спасибо вам большое! Вот очки, которые я обещал, возьмите этот грузовой скутер и журнал внутри. В журнале должны быть обещанные очки"
language.AbyssHelpPart4 = "Вот дерьмо! Кто-то пришел! Огромное спасибо! Пожалуйста, найдите способ вытащить нас отсюда, я дам вам %s моих очков, если вы сможете вытащить меня живым."
language.AbyssHelpPart5 = "Вы можете попробовать достать новый аккумулятор для этой подводной лодки и починить ее."
language.AbyssHelpDead = "Думаю, этим все и закончится...."

language.AmmoDelivery = "В оружейную зону субмарины доставлены боеприпасы и снаряды для рельсотрона."
language.BeaconPirate = "Поступили сообщения о печально известном пирате в УЗК, терроризирующем эти воды. Недавно пират был обнаружен на станции маяка - уничтожьте пирата, чтобы получить награду в %s очков для всего экипажа."
language.WreckPirate = "Поступили сообщения о печально известном пирате в УЗК, терроризирующем эти воды, недавно пират был обнаружен внутри затонувшей подводной лодки - ликвидируйте пирата, чтобы получить награду в %s очков для всего экипажа."
language.PirateInside = "Внимание! Опасный пират в УЗК был обнаружен внутри главной подводной лодки!"
language.PirateKilled = "Пират в УЗК убит, команда получила награду в %s очков."
language.UPCPirate = "Вы должны защищать это место чтобы получить %s поинтов, так же вы можете попытаться напасть на подлодку."
language.UPCPirateObjective = "Защищайте это место, чтобы получить %s поинтов в конце раунда, либо идите на главную подлодку. Если вы лично убьёте весь экипаж, который находится на ней, вы получите %s поинтов. Если лодка пуста, удерживайте её изнутри %s секунд и получите %s поинтов за захват."
language.PirateEliminatedCrew = "Пират в УЗК уничтожил весь экипаж на подлодке и получил %s поинтов. Экипаж провалил раунд."
language.PirateCaptureStarted = "Пират в УЗК начал захват подлодки. Вернитесь в течение %s секунд, иначе экипаж провалит раунд."
language.PirateCaptureInterrupted = "Захват подлодки пиратом в УЗК был сорван."
language.PirateCapturedSubmarine = "Пират в УЗК захватил подлодку и получил %s поинтов. Экипаж провалил раунд."

language.ClownMagic = "Вы чувствуете странное ощущение, и внезапно оказываетесь в другом месте"
language.CommunicationsOffline = "Что-то вмешивается во все наши системы связи. По оценкам, связь будет отключена не менее чем на %s минут."
language.CommunicationsBack = "Связь восстановлена"
language.EmergencyTeam = "Группа инженеров и механиков прибыла на подводную лодку, чтобы помочь с ремонтом"
language.ElectricalFixDischarge = "Неизвестная сила отремонтировала необходимые для выживания устройства на подводной лодке. Судя по всему это были фиксики, теперь у вас на 33% починены устройства."
language.FixHull = "Неизвестная сила отремонтировала весь корпус на подводной лодке. Судя по всему это были корпусные-фиксики, теперь у вас корпус починился на 50 едениц."
language.FullElectricalFixDischarge = "Неизвестная сила отремонтировала необходимые для выживания устройства на подводной лодке. Судя по всему фиксики устали смотреть как вы умераете, теперь у вас на 100% починены устройства."
language.FullFixHull = "Неизвестная сила отремонтировала весь корпус на подводной лодке. Судя по всему корпусные-фиксики устали смотреть как вы умераете, теперь у вас корпус починился на 1000 едениц."
language.BreackElectrical = "вам сломали электронику на 33% (wip)"
language.BreackHull = "вам сломали корпус на 50 едениц (wip)"
language.KillElectrical = "вам сломали электронику на 100% (wip)"
language.KillHull = "вам сломали корпус на 1000 едениц (wip)"
language.LightsOff = "Все огни внезапно погасли, но питание по-прежнему включено? Что происходит?"
language.MaintenanceToolsDelivery = "В грузовой отсек корабля доставлены инструменты для технического обслуживания. Инструменты находятся в желтом ящике"
language.MedicalDelivery = "В медицинский отсек корабля доставлено медицинское оборудование. Медицинские принадлежности находятся в красном медицинском ящике"
language.PrisonerAboard = "На борту подводной лодки находится заключенный, держите его живым и в наручниках, пока подводная лодка не прибудет в пункт назначения, чтобы команда получила %s очков"
language.PrisonerYou = "Вы - заключенный! Если вам удастся отойти от подводной лодки на 500 метров, вы будете вознаграждены суммой в размере %s очков."
language.PrisonerSuccess = "Заключенный был успешно доставлен, экипаж получил награду в %s очков."
language.PrisonerFail = "Заключенный сбежал, и награда за транспортировку была отменена"
language.OxygenSafe = "Кислород из генератора кислорода теперь снова безопасен для дыхания"
language.OxygenHusk = "Кислородный генератор был саботирован и теперь содержит яйца трупных паразитов. У тех, кто дышит этим воздухом есть около 15 секунд, чтобы достать подводную маску или скафандр, прежде чем вы получите достаточно большую дозу!"
language.OxygenPoison = "Кислородный генератор был саботирован и теперь содержит страданит. У тех, кто дышит этим воздухом есть около 15 секунд, чтобы достать подводную маску или скафандр, прежде чем вы получите достаточно большую дозу!"
language.PirateCrew = "Внимание! В этих водах замечен пиратский корабль! Уничтожьте пиратский реактор или убейте всех пиратов, чтобы получить награду в %s очков для всего экипажа"
language.EmergencyYou = "Вы являетесь частью команды (Аварийной команды)! Вы должны починить подлодку даже ценной ваша жизни и не дать умереть оставшейся команде на этой подводной лодке! (Помните вы не должны убивать обидчиков или гриферить на подлодке!)"
language.PirateCrewYou = "Вы являетесь частью пиратской команды этой подводной лодки! Защитите подводную лодку от любых грязных коалиций, пытающихся получить то, что принадлежит вам!"
language.PirateCrewSuccess = "Пираты сдались, команда получила награду в %s очков."
language.InvisibilityTraitor = "ПРЕДУПРЕЖДЕНИЕ! На корабле замечен очень странная одежда, будьте на настороже, она имеет странные свойста. Мы заметили что странные сигнатуры видны через тепловизор."
language.FriendPet = "Вы являетесь питомцем! Вы должны служить людям и защищать людку от тварей! (Помните вы не должны убивать обидчиков или гриферить на подлодке!)"

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
language.ShadyMissionBeacon = "‖color:gui.red‖Кажется, маяк был модифицирован.\nСзади висит записка, гласящая: \"8 Медицинских предмета, 4 Кислороднх баллона и 2 заряженых пушки.\"‖color:end‖"

language.SuperBallastFlora = "В этой области обнаружена высокая концентрация спор балластной флоры, рекомендуется обыскать насосы на предмет балластной флоры!"

language.Answer = "Ответить"
language.Ignore = "Игнорировать"

language.SecretSummary = "Задачи выполнены: %s - Очки получены: %s\n"
language.SecretTraitorAssigned = "Вы были избраны предателем, проголосуйте,им именно вы хотите быть."

language.ItemsBought = "Предметы, купленные в магазине"
language.CrewBoughtItem = "Игроки купили предметы в магазине"
language.PointsGained = "Общее количество набранных очков"
language.PointsLost = "Общее количество потерянных очков"
language.Spawns = "Появившиеся игроки"
language.Traitor = "Выбран в качестве предателя"
language.TraitorDeaths = "Умер предатель"
language.TraitorMainObjectives = "Основные задачи выполнены"
language.TraitorSubObjectives = "Доп. цели выполнени"
language.CrewDeaths = "Смерти"
language.Rounds = "Общая статистика раунда"

language.Yes = "Да"
language.No = "Нет"

language.PointshopInGame = "Вы должны быть в игре, чтобы использовать магазин"
language.PointshopCannotBeUsed = "Этот товар нельзя приобрести в данный момент"
language.PointshopWait = "Вам придется подождать %s секунд, прежде чем вы сможете приобрести этот товар"
language.PointshopNoPoints = "У вас недостаточно очков для покупки этого товара"
language.PointshopNoStock = "Этого товара нет в наличии"
language.PointshopPurchased = "Приобретено \"%s\" за %s баллов\n\nНовый баланс очков составляет: %s очков."
language.PointshopGoBack = ">> Вернуться назад <<"
language.PointshopCancel = ">> Отменить <<"
language.PointshopWishBuy = "Ваш текущий баланс: %s очков\nЧто вы хотите купить?"
language.PointshopInstallation = "товар, который вы собираетесь купить, будет установлен в вашем точном месте, вы не сможете переместить его в другое место, хотите ли вы продолжить?\n"
language.PointshopNotAvailable = "Магазин недоступен."
language.PointshopWishCategory = "Ваш текущий баланс: %s очков\nВыберите категорию."
language.PointshopRefunded = "Вам было возвращено %s очков за покупку %s"

language.AbilityNoTurretSlots = "На этой подлодке нет свободных слотов под эту пушку."
language.ReactorShutdown = "На реакторе произошёл критический сбой, и он отключился для самосохранения."
language.SupercapacitorFailure = "Из-за короткого замыкания на суперконденсаторы прилетело 220v. Они вышли из строя и потеряли весь запас энергии."
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

language.SubmarineRoyaleEnd = "Раунд заканчивается."
language.CMDLocatePlayer = "Игрок %s находится в %s м от вас, направление %s, на %s."
language.CMDPlaytime = "Ваше время в игре: %s."

language.Pointshop = {
    abilities = "Способности",
    abilities_captain = "Капитан",
    abilities_security = "Служба безопасности",
    abilities_security_turrets = "Поставить пушку",
    abilities_mechanic = "Механик",
    abilities_engineer = "Инженер",
    abilities_medical = "Медик",
    abilities_surgeon = "Хирург",
    CaptainHelmBoost = "Навигация +100 на 5 минут",
    SecurityMindSense = "Wall Hack на 5 минут",
    SecurityTurretCoilgun = "Поставить Coilgun",
    SecurityTurretChaingun = "Поставить Chaingun",
    SecurityTurretFlakcannon = "Поставить Flak Cannon",
    SecurityTurretPulseLaser = "Поставить Pulse Laser",
    SecurityTurretDoubleCoilgun = "Поставить двойную магнитную пушку",
    SecurityTurretRailgun = "Поставить Railgun",
    MechanicMechanicalRepair = "Починить механику на 15%",
    MechanicHullRepair = "Починить корпус на 50%",
    MechanicSkillBoost = "Механика +100 на 5 минут",
    EngineerElectricalRepair = "Починить электрику на 10%",
    EngineerSkillBoost = "Инженерия +100 на 5 минут",
    MedicSkillBoost = "Медицина +100 и хирургия +70 на 5 минут",
    SurgeonSkillBoost = "Хирургия +100 и медицина +70 на 5 минут",
    traitor_sabotage = "Саботаж",
    traitor_sabotage_criticalsystems = "Критические системы",
    traitor_sabotage_oxygensabotage = "Саботаж кислорода",
    traitor_sabotage_poisons = "Яды",
    ReactorShutdown = "Отключение реактора",
    SupercapacitorFailure = "Поломка суперконденсаторов",
    JunctionBoxOverload = "Поломка электрощитков",
    OxygenSufforin = "Заразить кислород: Страданит",
    OxygenParalyzant = "Заразить кислород: Парализатор",
    OxygenMorbusine = "Заразить кислород: Морбузин",
    OxygenCyanide = "Заразить кислород: Цианид",
    WeakBallastFlora = "Слабая балластная флора",
    VentCreatures = "Существа в вентиляции",
    ClownCrateSurprise = "Клоунский ящик-сюрприз",
    fakehandcuffs = "Поддельные наручники",
    choke = "кляп",
    choke_desc = "‖color:gui.red‖Заглушает цель‖color:end‖",
    jailgrenade = "DarkRP Тюремная граната",
    jailgrenade_desc = "‖color:gui.red‖ Особая граната с интересным сюрпризом...‖color:end‖",
    clowngearcrate = "Ящик клоунского снаряжения",
    clowntalenttree = "Дерево талантов клоуна",
    invisibilitygear = "Одежда невидомости",
    clownmagic = "Магия клоуна (случайным образом меняет местами людей)",
    randomizelights = "Случайное освещение",
    fuelrodlowquality = "Пустой топливный стержень",
    BreackHull = "Сломать корпус на 50 едениц",
    BreackElectrical = "Сломать электронику на 33%",
    KillElectrical = "УНИЧТОЖИТЬ всю электронику",
    KillHull = "УНИЧТОЖИТЬ весь корпус",
    SuperBallastFlora = "Распространить супер баластную флору",
    HiddenPirate = "Призвать баластного пирата",
    FixHull = "Починить корпус на 50 едениц",
    ElectricalFixDischarge = "Починить электронику на 33%",
    FullFixHull = "ПОЛНОСТЬЮ починить весь корпус",
    FullElectricalFixDischarge = "ПОЛНОСТЬЮ починить всю электронику",
    MaintenanceToolsDelivery = "Доставить на подлодку ремонтные инструменты",
    MedicalDelivery = "Доставить на подлодку медецинские припасы",
    AmmoDelivery = "Доставить на подлодку боеприпасы",
    EmergencyTeam = "Позвать инженеров и механиков для починки подлодке",
    gardeningkit = "Набор для садоводства",
    randomitem = "Случайный предмет",
    clownsuit = "Костюм клоуна",
	maidfit = "костюм горничной", 
    randomegg = "Случайное яйцо",
    assistantbot = "Бот-помощник",
    organs = "Органы",
    firstaidkit = "Аптечка первой помощи",
	randomize_crazy_all = "Рандомные безумные предметы",
	randomize_normal_all = "Рандомные нормальные предметы",
	randomize_materials = "Рандомные ресурсы",
	randomize_medical = "Рандомная медецина",
	randomize_weapons = "Рандомные пушки",

    firemanscarrytalent = "Талант 'перенос на плече'",
    stungunammo = "Патроны для электрошокера (x4)",
    revolverammo = "Патроны для револьвера (x6)",
    smgammo = "Магазин для ПП (x2)",
    shotgunammo = "Снаряды для дробовика (x8)",
    streamchalk = "Потоковый мел",
    uri = "Ури - инопланетный корабль",
    seashark = "Морская акула МК II",
    Beaver = "Барсук",
    barsuk = "Барсук",
    huskattractorbeacon = "Маяк аттрактора хаска",
    monsterattractorbeacon = "Маяк приманки чудовищ",
    huskautoinjector = "Автоинжектор Хаска",
    huskedbloodpack = "Зараженная кровь",
    spawnhusk = "Призвать хасков",
    huskoxygensupply = "Подача зараженного кислорода",
    explosiveautoinjector = "Взрывной автоинжектор",
    teleporterrevolver = "Револьвер телепортации",
    poisonoxygensupply = "Подача ядовитого кислорода",
    turnofflights = "Выключить свет на 3 минуты",
    turnoffcommunications = "Выключить связь на 2 минуты",
    spawnasSpinelingmorbusine = "Появиться в виде морбузиновго шипостая",
    spawnascrawler = "Появиться в виде Ползуна",
    spawnascrawlerhusk = "Появиться в виде Ползуна-хаска",
    spawnaslegacycrawler = "Появиться в виде Ползуна(устаревший)",
    spawnaslegacyhusk = "Появиться в виде Хаска(устаревший)",
    spawnascrawlerbaby = "Появиться в виде Детеныша ползуна",
    spawnasmudraptorbaby = "Появиться в виде Детеныша грязевого раптора",
    spawnasthresherbaby = "Появиться в виде Детеныша акульего тигра",
    spawnasspineling = "Появиться в виде Шипостая",
    spawnasmudraptor = "Появиться в виде Грязевого раптор",
    spawnasmantis = "Появиться в виде Богомола",
    spawnashusk = "Появиться в виде Хаска",
    spawnashuskedhuman = "Появиться в виде Человека-хаска",
    spawnasbonethresher = "Появиться в виде Костяного акульего тигра",
    spawnastigerthresher = "Появиться в виде Акульего тигра",
    spawnaslegacymoloch = "Появиться в виде Молоха(устаревший)",
    spawnaslegacycarrier = "Появиться в виде Разносчика(устаревший)",
    spawnashammerhead = "Появиться в виде Молотоглава",
    spawnasfractalguardian = "Появиться в виде Фрактального стража",
    spawnasgiantspineling = "Появиться в виде Гигантского шипостая",
    spawnasveteranmudraptor = "Появиться в виде Грязевого раптора-ветерана",
    spawnaslatcher = "Появиться в виде Блокиратора",
    spawnascharybdis = "Появиться в виде Харибды",
    spawnasendworm = "Появиться в виде Червя рока",
    spawnaspeanut = "Появиться в виде Орешка",
    spawnasClownOrangeboy = "Появиться в виде Оранжевого парня клоуна",
    spawnasClownPeanut = "Появиться в виде Орешка клоуна",
    spawnasClownPsilotoad = "Появиться в виде Псиложабы клоуна",
    spawnasMudraptorpet = "Появиться в виде питомца раптора",
    spawnasDefensebot = "Появиться в виде защищающего бота",
    STransformedMudraptor = "Появиться в виде дружелюбного взрослого раптора",
    Huskmutanthunteraddict = "Появиться в виде джентльмен мутанта хаск",
    spawnasMoloch = "Появиться в виде Молоха",
    spawnasLeucocyte = "Появиться в виде лекойцита",
    spawnasMolochblack = "Появиться в виде Черного молоха",
    spawnasorangeboy = "Появиться в виде Оранжевого парня",
    spawnasHammerhead_mhusk = "Появиться в виде Молотоглава хаска",
    spawnaWatcher = "Появиться в виде Смотритель",
    spawnascthulhu = "Появиться в виде Ктулху",
    spawnaspsilotoad = "Появиться в виде Псиложабы",
    spawnasHammerheadmatriarch = "Появиться в виде Молотоглава матриарха",
    spawnasHammerheadmatriarchhusk = "Появиться в виде Молотоглава матриарха хаска",
    spawnasCoelanthhusk = "Появиться в виде Целакант хаска",
    spawnasBonethresherhusk = "Появиться в виде Костяного акульего тигра хаска",
    spawnasTigerthresherhusk = " Появиться в виде Акульего тигра хаска",
    spawnasSnatcher = "Появиться в виде Похитителя",
    spawnasMolochhusk = "Появиться в виде Молоха хаска",
    spawnasMolochblackhusk = "Появиться в виде Черного молоха хаска",
    spawnasMantishusk = "Появиться в виде Креветки хаска",
    spawnasHuskmutanthunterranged = "Появиться в виде Охотника",
    spawnasHuskmutanttigerthresher = "Появиться в виде Мутанта акульего тигра",
    spawnasHuskmutantcrawler = "Появиться в виде Мутанта ползуна",
    spawnasHuskmutantmudraptor = "Появиться в виде Мутанта раптора",
    spawnasHuskmutantarmoredpucs = "Появиться в виде джаггернаута",
    spawnasEndwormhuskhead = "Появиться в виде головы червя рока хаска",
    spawnasEndwormhusk = "Появиться в виде Червя рока хаска",
    spawnasCharybdishusk = "Появиться в виде Харибды хаска",
    spawnasWatcherhusk = "Появиться в виде Смотрителя хаска",
    spawnasLegacycrawlerhusk = "Появиться в виде креветки(устаревший)", 
    clown = "клоун",
    cultist = "культисть",
    traitor = "предатель",
    deathspawn = "Переродиться",
    wiring = "Проводка",
    ores = "Руды",
    security = "Безопасность",
    ships = "Корабли",
    materials = "Материалы",
    medical = "Медицина",
    maintenance = "Обслуживание",
    other = "Прочее",
    skillbooks = "Книги навыков",
    attackdefend_scouts = "Скауты",
    attackdefend_soldiers = "Солдаты",
    attackdefend_stormtroopers = "Штурмовики",
    attackdefend_snipers = "Снайперы",
    attackdefend_medics = "Медики",
    attackdefend_clowns = "Клоуны",
    attackdefend_juggernauts = "Джаггернауты",
    attackdefend_captains = "Капитаны",
    attackdefend_engineers = "Инженеры",
    attackdefend_gunners = "Артиллеристы",
	randomize = "Казино предметов",
    surgery = "Хирургия",
    otherresources = "Остальные ресурсы",
    teamRed = "Команда красные",
    teamBlue = "Команда синие",
    teamRedDB = "Команда красные",
    teamBlueDB = "Команда синие",
    teamRedWatter = "Команда красные",
    teamBlueWatter = "Команда синие",
	spawnRed = "Команда красные",
	spawnBlue = "Команда синие",
    deathspawnhusk = "Переродиться за хасков",
    deadspawnfromsub = "Переродиться в подлодке",
    deathspawnfriend = "Переродиться за дружулюбных существ",
    deathtrigerevent = "Вызвать хорошие ивенты",
    deathtrigereventevil = "Вызвать плохие ивенты",
    deathtrigereventrandom = "Вызвать случайные ивенты",
    deathtrigereventabilities = "Способности экипажа",
    idcardlocator = "Локатор удостоверений личности",
    idcardlocator_desc = "‖color:gui.red‖Локатор удостоверений личности‖color:end‖",
    idcardlocator_result = "%s - %s - %s метров",
	coalition_scout = "Скаут - с дубинкой и ппшками",
	coalition_soldier_1 = "Солдат - c пистолетом-пулеметом",
	coalition_soldier_2 = "Солдат - с дробовиком",
	coalition_stormtrooper_1 = "Штурмовик - с штурмовой винтовкой",
	coalition_stormtrooper_2 = "Штурмовик - c гремелкой и электровинтовкой",
	coalition_sniper_1 = "Снайпер - c ружьем и 30мл гранатами",
	coalition_sniper_2 = "Снайпер - c винчестером и ревиком",
	coalition_medic = "Медик - с медециной всей россии",
	coalition_clown_1 = "Клоун - с молотками и с рандомными гранатами",
	coalition_clown_2 = "Клоун - с драбашом и с стан дробошом",
	coalition_clown_3 = "Клоун - с 3 клоунскими пушками",
	coalition_juggernaut_1 = "Джагернаут - с огромной безумной батареей",
	coalition_juggernaut_2 = "Джагернаут - с отрубателей голов секирой",
	coalition_captain_1 = "Капитан - с двумя улучшенными револьверами",
	coalition_captain_2 = "Капитан - с пиратской штурмовой винтовкой и ревиком",
	coalition_engineer_1 = "Инженер - с разрядником и закаленным ломом",
	coalition_engineer_2 = "Инженер - с ускорителем распадом",
	coalition_gunner_1 = "Артелерист - с ручным гранатамётом",
	coalition_gunner_2 = "Артелерист - с гранатамётом",
	separatists_scout = "Скаут - с дубинкой и ппшками",
	separatists_soldier_1 = "Солдат - c пистолетом-пулеметом",
	separatists_soldier_2 = "Солдат - с дробовиком",
	separatists_stormtrooper_1 = "Штурмовик - с штурмовой винтовкой",
	separatists_stormtrooper_2 = "Штурмовик - c гремелкой и электровинтовкой",
	separatists_sniper_1 = "Снайпер - c ружьем и 30мл гранатами",
	separatists_sniper_2 = "Снайпер - c винчестером и ревиком",
	separatists_medic = "Медик - с медециной всей россии",
	separatists_clown_1 = "Клоун - с молотками и с рандомными гранатами",
	separatists_clown_2 = "Клоун - с драбашом и с стан дробошом",
	separatists_clown_3 = "Клоун - с 3 клоунскими пушками",
	separatists_juggernaut_1 = "Джагернаут - с огромной безумной батареей",
	separatists_juggernaut_2 = "Джагернаут - с отрубателей голов секирой",
	separatists_captain_1 = "Капитан - с двумя улучшенными револьверами",
	separatists_captain_2 = "Капитан - с пиратской штурмовой винтовкой и ревиком",
	separatists_engineer_1 = "Инженер - с разрядником и закаленным ломом",
	separatists_engineer_2 = "Инженер - с ускорителем распадом",
	separatists_gunner_1 = "Артелерист - с ручным гранатамётом",
	separatists_gunner_2 = "Артелерист - с гранатамётом",
}

language.FakeHandcuffsUsage = "Вы можете освободиться от этих наручников, используя !fhc"

language.ShipTooCloseToWall = "Невозможно купить корабль, позиция слишком близко к стене уровня."
language.ShipTooCloseToShip = "Невозможно купить корабль, позиция находится слишком близко к другой подводной лодке."

language.Pets = "Питомцы"
language.SmallCreatures = "Мелкие существа"
language.LargeCreatures = "Крупные существа"
language.AbyssCreature = "Существо бездны"
language.ElectricalDevices = "Электрические устройства"
language.MechanicalDevices = "Механические устройства"

language.CMDAliveToUse = "Вы должны быть живы, чтобы использовать эту команду"
language.CMDNoRole = "У вас нет особой роли"
language.CMDAlreadyDead = "Вы уже мертвы!"
language.CMDHandcuffed = "Вы не можете использовать эту команду, пока скованы наручниками"
language.CMDKnockedDown = "Вы не можете использовать эту команду, пока вы без сознания"
language.GamemodeNone = "Режим игры: Нет"
language.CMDPermisionPoints = "У вас нет прав на добавление очков"
language.CMDInvalidNumber = "Неверное значение числа"
language.CMDClientNotFound = "Не удалось найти клиента с этим именем / steamID"
language.CMDCharacterNotFound = "Не удалось найти персонажа с указанным именем"
language.CMDAdminAddedPointsEveryone = "Администратор добавил %s очков всем"
language.CMDAdminAddedPoints = "Администратор добавил %s очков %s"
language.CMDAdminAddedLives = "Администратор добавил %s жизней %s"
language.CMDOnlyMonsters = "Только монстры могут использовать эту команду"
language.CMDLocateSub = "Подводная лодка находится на расстоянии %sм от вас, в %s"
language.CMDRoundTime = "Этот раунд длится уже %s минут"
language.CMDMonsterBroadcast = "[%s %s]: %s"

language.GameVoteLobbyOnly = "Голосование за режим можно начать только в лобби."
language.LobbyVoteAlreadyActive = "Голосование в лобби уже идёт. Дождись его завершения."
language.GameVoteStarted = "%s начал голосование за режим. У вас %s секунд."
language.GameVoteOptionsHeader = "Голосование за режим:"
language.GameVoteHowToVote = "Чтобы проголосовать, напиши: %s"
language.GameVoteOptionSecret = "Миссии с предателями"
language.GameVoteOptionAttackDefend = "Attack & Defends"
language.GameVoteOptionHideAndSeek = "Прятки"
language.GameVoteAccepted = "Твой голос принят: %s."
language.GameVoteInvalidOption = "Неверный вариант. Используй %s."
language.GameVoteFinished = "Голосование завершено. Победил режим: %s."
language.GameVoteCancelledRoundStarted = "Голосование за режим отменено, потому что раунд уже начался."
language.GameVoteNoSecretSub = "Не удалось подобрать подлодку для режима «Миссии с предателями»."
language.GameVoteNoAttackDefendSub = "Не удалось подобрать подлодку для режима «Attack & Defends»."
language.GameVoteSelectedSecret = "Выбран режим «Миссии с предателями». Подлодка: %s (%s мест)."
language.GameVoteNoHideMap = "Не удалось найти карту для режима «Прятки»."
language.GameVoteSelectedHide = "Выбран режим «Прятки». Карта: %s (%s мест)."
language.GameVoteNoAttackDefendMap = "Не удалось найти карту для режима «Attack & Defends»."
language.GameVoteSelectedAttackDefend = "Выбран режим «Attack & Defends». Подлодка: %s (%s мест)."
language.GameVoteApplyFailed = "Не удалось применить настройки голосования."
language.GameVoteNoVotes = "Никто не проголосовал, выбирается случайный победитель: %s."
language.GameVoteTie = "Ничья между режимами: %s. Выбирается случайный победитель: %s."
language.GameVoteStartedByServer = "Сервер"
language.MapVoteStarted = "%s начал голосование за подлодку. У вас %s секунд."
language.MapVoteOptionsHeader = "Голосование за подлодку:"
language.MapVoteHowToVote = "Чтобы проголосовать, напиши: %s"
language.MapVoteAccepted = "Твой голос принят: %s."
language.MapVoteInvalidOption = "Неверный вариант. Используй %s."
language.MapVoteFinished = "Голосование завершено. Победила подлодка: %s."
language.MapVoteCancelledRoundStarted = "Голосование за подлодку отменено, потому что раунд уже начался."
language.MapVoteNoCandidates = "Не удалось найти подходящие подлодки для %s игроков."
language.MapVoteSelected = "Выбрана подлодка: %s (%s мест)."
language.MapVoteNoVotes = "Никто не проголосовал, выбирается случайная подлодка: %s."
language.MapVoteTie = "Ничья между подлодками: %s. Выбирается случайный победитель: %s."

language.DiscordModeSecret = "Миссии с предателями"
language.DiscordModeMission = "Миссия"
language.DiscordModeAttackDefend = "Attack & Defend"
language.DiscordModeHideAndSeek = "Прятки"
language.DiscordModePvP = "PvP"
language.DiscordModeMultiplayerCampaign = "Кампания"
language.DiscordModeUnknown = "Неизвестно"
language.DiscordStatusLobbyText = "Лобби"
language.DiscordStatusRoundText = "Игра"
language.DiscordStatusUnknownText = "Неизвестно"
language.DiscordNextRoundPrefix = "Следующий"
language.DiscordNoSelectionText = "Не выбрано"
language.DiscordNoDurationText = "—"
language.DiscordFooterText = "VoidTraitor"
language.DiscordFieldRound = "Раунд"
language.DiscordFieldMode = "Режим"
language.DiscordFieldStatus = "Статус"
language.DiscordFieldPlayers = "Игроков"
language.DiscordPlayersValue = "%d из %d"
language.DiscordFieldDuration = "Время раунда"
language.DiscordFieldMap = "Карта"
language.DiscordFieldSubmarine = "Подлодка"
language.DiscordDurationHoursMinutes = "%d ч %d мин"
language.DiscordDurationMinutesSeconds = "%d мин %d сек"
language.DiscordDurationSeconds = "%d сек"
language.DiscordServerStarted = "Сервер запущен: **%s**"
language.DiscordPlayerConnected = "На сервер зашёл **%s**\nИгроков сейчас: **%d/%d**"
language.DiscordPlayerDisconnected = "С сервера вышел **%s**\nИгроков сейчас: **%d/%d**"
language.DiscordRoundStarted = "Раунд начинается #**%d**\nРежим: **%s**\nИгроков на старте: **%d/%d**"
language.DiscordRoundEndedGeneric = "Раунд #**%d** завершился, длился **%s**."
language.DiscordRoundEndedAttackDefend = "Раунд #**%d** завершился, длился **%s**, победила **%s**."
language.DiscordRoundEndedSecret = "Раунд #**%d** завершился, выжил **%d/%d** предатель и **%d/%d** людей, раунд длился **%s**, предателями были **%s**."
language.DiscordWinnerTeamBlue = "синяя команда"
language.DiscordWinnerTeamRed = "красная команда"
language.DiscordWinnerTeamUnknown = "неизвестная команда"
language.DiscordUnknownTraitors = "неизвестно"

language.DiscordReadJsonFailed = "Не удалось прочитать JSON-файл Discord: %s"
language.DiscordDebugResponse = "Ответ Discord %s: %s | %s"
language.DiscordWebhookFailed = "Ошибка Discord webhook: %s"
language.DiscordStatusManualSetup = "Тестовое статус-сообщение для ручной настройки. Скопируй ID этого сообщения в Discord и вставь его в config.Discord.Status.MessageId"
language.DiscordTestMessageFailed = "Не удалось отправить тестовое статус-сообщение Discord: %s | %s"
language.DiscordTestMessageSent = "Тестовое статус-сообщение Discord отправлено один раз. Скопируй его ID вручную и вставь в config.Discord.Status.MessageId."
language.DiscordStatusMessageIdMissingManual = "Не указан ID статус-сообщения Discord. Скопируй ID тестового сообщения вручную и вставь его в config.Discord.Status.MessageId."
language.DiscordStatusMessageIdMissingAuto = "Не указан ID статус-сообщения Discord. Укажи config.Discord.Status.MessageId или включи AutoCreateMessageIfMissing."
language.DiscordCreateMessageFailed = "Не удалось создать статус-сообщение Discord: %s | %s"
language.DiscordParseMessageIdFailed = "Не удалось разобрать ID статус-сообщения Discord из ответа."
language.DiscordStatusMessageCreated = "Статус-сообщение Discord создано. ID сообщения: %s"
language.DiscordStatusRateLimited = "Discord ограничил запросы к статусу. Следующая попытка через %s сек."
language.DiscordStatusUpdateFailed = "Не удалось обновить статус-сообщение Discord: %s | %s"

language.UnknownCommand = "Неизвестная команда. Напишите !help, чтобы посмотреть список доступных команд."

language.MonsterBeaconDescription = "‖color:196, 90, 32, 255‖Модифицированный сонарный маяк. Если оставить его активным на 30 секунд, он приманит стаю чудовищ снаружи подлодки.‖color:end‖"

language.ReachedClassLimit = "Достигнут лимит класса"
language.PointshopSubcategorySlots = "%d/%d мест"
language.AttackDefendClassFull = "Этот класс уже забит."
language.AttackDefendItemLocked = "Этот предмет класса заблокирован."

language.GhostRolesNone = "Свободных гост ролей сейчас нет."
language.GhostRolesMenuFree = "(Свободна)"
language.GhostRolesMenuTaken = "(Занята)"
language.GhostRolesMenuDead = "(Мертва)"
language.GhostRolesMenuCost = "(%d очков)"
language.GhostRolesMenuCancel = "Закрыть"
language.GhostRolesMenuRefresh = "Обновить"
language.GhostRolesMenuPreviousPage = "Предыдущая страница"
language.GhostRolesMenuNextPage = "Следующая страница"
language.GhostRolesMenuEntry = "%s %s"
language.GhostRolesMenuEmpty = "Сейчас гост роли недоступны. Твои очки: %d"
language.GhostRolesMenuTitle = "Гост роли (%d/%d свободно) | Страница %d/%d | Твои очки: %d"
language.GhostRolesNoPoints = "Для этой гост роли нужно %d очков. Сейчас у тебя %d."
language.GhostRolesPurchased = "Гост роль куплена за %d очков. Новый баланс: %d."
language.GhostRolesAssignFailed = "Не удалось выдать гост роль."

return language
