-- Серверные строки. Подписи клиентского GUI лежат в Void traitor pack/Lua/language/russian.lua.
local language = {}
language.Name = "Russian"

local path = Traitormod.Path .. "/Lua/language/russian/"

-- Общие команды, системные сообщения и серверные события
assert(loadfile(path .. "core.lua"))(language)

-- Роли антагонистов и цели
assert(loadfile(path .. "roles_objectives.lua"))(language)

-- Гост-роли
assert(loadfile(path .. "ghostroles.lua"))(language)

-- PointShop
assert(loadfile(path .. "pointshop.lua"))(language)

-- Игровые режимы, итог раунда и голосования
assert(loadfile(path .. "gamemodes.lua"))(language)

-- Discord
assert(loadfile(path .. "discord.lua"))(language)

return language
