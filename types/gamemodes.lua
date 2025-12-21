---@class Gamemode
---@field Name string
---@field RequiredGamemode GamemodeID
---@field CheckRequirements fun(self: self): boolean Invoked when choosing a gamemode
---@field PreStart fun(self: self) Invoked before starting round
---@field Start fun(self: self) Invoked on round start
---@field Think fun(self: self) Invoked on game update
---@field End fun(self: self, missions: Barotrauma.Mission[]) Invoked on round end
---@field TraitorResults fun(self: self)
---@field RoundSummary fun(self: self): string
---@field new fun(self: self, o: table?): any Takes `o` table, sets self as metatable and makes a proxy for missing fields to self. `o` is empty table by default
---@field PointshopCategories string[] Categories used in gamemode. From config


---@class Gamemodes.AttackDefendV2: Gamemode
---@field DefendTime number Time from round start before defenders win. From config
---@field Respawns table<Barotrauma.Networking.Client, RespawnEntry>
---@field ClassCounters table<string, integer>
---@field DefendRespawn number Defenders respawn time. From config
---@field AttackRespawn number Attackers respawn time. From config
---@field DefendCountDown number Time left before defenders win
---@field LastDefendCountDown number Time on last countdown message
---@field IsEnding boolean
---@field WinningPointsTeam1 integer Point given to defendenrs team on victory. From config
---@field WinningPointsTeam2 integer Point given to attackers team on victory. From config
---@field Teams AttackDefendV2.Team[]
---@field protected _SetNewClient fun(self: self, client)

---@class RespawnEntry
---@field Timer number?
---@field OnSpawn classFunction?
---@field JobId string?
---@field ClassId string?
---@field PrevClassId string?

---@class AttackDefendV2.Members: { [Barotrauma.Networking.AccountId]: Barotrauma.Networking.Client }
---@operator len: integer

---@alias GamemodeID
---| "pvp"
---| "campaign"
---| "sandbox"