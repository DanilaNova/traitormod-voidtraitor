---@meta

---@class Team
---@field Name string
---@field Spawns Barotrauma.WayPoint[]
---@field Members Barotrauma.Networking.Client[]
---@field TeamID Barotrauma.CharacterTeamType
---@field RespawnTime number
---@field Color Microsoft.Xna.Framework.Color

---@class RandomEvent
---@field Name string
---@field MinRoundTime number Min round time for triggering event
---@field MaxRoundTime number Max round time for triggering event
---@field MinIntensity number Min game intensity for triggering event
---@field MaxIntensity number Max game intensity for triggering event
---@field ChancePerMinute number Chance of triggering event where 1 is 100%

---@class Pointshop.Category
---@field Identifier string
---@field CanAccess fun(client: Barotrauma.Networking.Client): boolean
---@field Products Pointshop.Product[]

---@class Pointshop.Product
---@field Identifier string
---@field Price integer
---@field Limit integer?
---@field IsLimitGlobal boolean? default is false
---@field Action fun(client: Barotrauma.Networking.Client, product: Pointshop.Product, spawnedItems: Barotrauma.Item[], paidPrice: number)?
---@field CanBuy ?fun(client: Barotrauma.Networking.Client, product: Pointshop.Product): boolean, Pointshop.ProductBuyFailureReason?
---@field Items string[]?

---@alias Pointshop.ProductBuyFailureReason string |  Pointshop.ProductBuyFailureReason.Enum

---@class Traitormod
---@field SelectedGamemode Gamemode

