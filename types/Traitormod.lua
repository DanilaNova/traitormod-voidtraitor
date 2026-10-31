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
---@field PricePerLimit integer?
---@field Limit integer?
---@field IsLimitGlobal boolean? default is false
---@field IsLimitGlobalAcrossCategories boolean? Share the limit between all players and products with the same Identifier in different categories
---@field CategoryIdentifier string? Internal category identifier used to scope product limits
---@field Action ?fun(client: Barotrauma.Networking.Client, product: Pointshop.Product, spawnedItems: Barotrauma.Item[]?, paidPrice: integer)
---@field CanBuy ?fun(client: Barotrauma.Networking.Client, product: Pointshop.Product): boolean, Pointshop.ProductBuyFailureReason?
---@field Items (string | Pointshop.Item)[]?
---@field ItemRandom boolean?
---@field RoundPrice { PriceReduction: integer, StartTime: number, EndTime: number }?
---@field Timeout number?
---@field Enabled boolean?
---@field Slots Pointshop.Slots?

---@class Pointshop.Slots
---@field Identifier string
---@field Limit integer
---@field Reserve boolean? Reserve slot on buying

---@class Pointshop.Item
---@field Identifier string
---@field IsInstallation boolean?
---@field Condition number?
---@field MaxCondition number?

---@class Pointshop.Product.Identifier : string
---@alias Pointshop.ProductBuyFailureReason string |  Pointshop.ProductBuyFailureReason.Enum

---@class Traitormod
---@field SelectedGamemode Gamemode