---@class Pointshop
local ps = {}

local config = Traitormod.Config
local textPromptUtils = require("textpromptutils")

local defaultLimit = 999

---@enum Pointshop.ProductBuyFailureReason.Enum
ps.ProductBuyFailureReason = {
    NoPoints = 1,
    NoStock = 2,
}

---@type table<string, integer>
ps.GlobalProductLimits = {}
---@type table<string, integer>
ps.LocalProductLimits = {}
ps.Timeouts = {}
ps.Refunds = {}
ps.ActiveCategories = {}
ps.AllCategories = {} -- It has config categories parsed as a table

---@param categories Pointshop.Category[]
ps.Initialize = function(categories)
    ps.ActiveCategories = {}
    ps.GuiProductMaps = {}
    ps.GuiProductIds = {}

    -- Adds required categories to a list so it can be used by the gamemode
    for _, category in pairs(categories) do
        local resolvedCategory = ps.AllCategories[category]
        if resolvedCategory ~= nil then
            table.insert(ps.ActiveCategories, resolvedCategory)
        end
    end
end

ps.ValidateConfig = function ()
    for i, category in pairs(config.PointShopConfig.ItemCategories) do
        for k, product in pairs(category.Products) do
            if product.Items then
                for z, item in pairs(product.Items) do
                    if type(item) == "string" then
                        item = {Identifier = item}
                    end

                    if type(item) ~= "table" then
                        Traitormod.Error(string.format("PointShop Error: Inside the Category \"%s\" theres a Product with Identifier \"%s\", that is invalid", category.Identifier, product.Identifier))
                    elseif item.Identifier == nil then
                        Traitormod.Error(string.format("PointShop Error: Inside the Category \"%s\" theres a Product with Identifier \"%s\", that has items without an Identifier", category.Identifier, product.Identifier))
                    elseif ItemPrefab.GetItemPrefab(item.Identifier) == nil then
                        Traitormod.Error(string.format("PointShop Error: Inside the Category \"%s\" theres a Product with Identifier \"%s\", that has an invalid item identifier \"%s\"", category.Identifier, product.Identifier or "", item.Identifier or ""))
                    end
                end
            end
        end
    end
end

ps.ResetProductLimits = function()
    ps.GlobalProductLimits = {}
    ps.LocalProductLimits = {}
end

---@param product Pointshop.Product
---@return boolean
ps.GetProductHasInstallation = function(product)
    if product.Items ~= nil then
        for key, value in pairs(product.Items) do
            if type(value) == "table" and value.IsInstallation then
                return true
            end
        end
    end

    return false
end

local function getProductLimitKey(product)
    if product.IsLimitGlobalAcrossCategories then
        return product.Identifier
    end

    if product.CategoryIdentifier ~= nil then
        return product.CategoryIdentifier .. ":" .. product.Identifier
    end

    return product.Identifier
end

---@param client Barotrauma.Networking.Client
---@param product Pointshop.Product
---@return integer
ps.GetProductLimit = function (client, product)
    local limitKey = getProductLimitKey(product)

    if product.IsLimitGlobal or product.IsLimitGlobalAcrossCategories then
        if ps.GlobalProductLimits[limitKey] == nil then
            ps.GlobalProductLimits[limitKey] = product.Limit or defaultLimit
        end
        return ps.GlobalProductLimits[limitKey]
    else
        local accountKey = Traitormod.GetClientAccountKey(client)
        if ps.LocalProductLimits[accountKey] == nil then
            ps.LocalProductLimits[accountKey] = {}
        end
        local localProductLimit = ps.LocalProductLimits[accountKey]
        if localProductLimit[limitKey] == nil then
            localProductLimit[limitKey] = product.Limit or defaultLimit
        end
        return localProductLimit[limitKey]
    end
end

---@param client Barotrauma.Networking.Client
---@param product Pointshop.Product
---@param amount integer?
---@return boolean
ps.UseProductLimit = function (client, product, amount)
    amount = amount or 1
    local limitKey = getProductLimitKey(product)

    if product.IsLimitGlobal or product.IsLimitGlobalAcrossCategories then
        if ps.GlobalProductLimits[limitKey] == nil then
            ps.GlobalProductLimits[limitKey] = product.Limit or defaultLimit
        end
        local currentLimit = ps.GlobalProductLimits[limitKey]
        if amount > 0 and currentLimit < amount then return false end
        ps.GlobalProductLimits[limitKey] = currentLimit - amount
        if ps.QueueGuiProductStateUpdate ~= nil then
            ps.QueueGuiProductStateUpdate(client, product)
        end
        return true
    else
        local accountKey = Traitormod.GetClientAccountKey(client)
        if ps.LocalProductLimits[accountKey] == nil then
            ps.LocalProductLimits[accountKey] = {}
        end
        local localProductLimit = ps.LocalProductLimits[accountKey]
        if localProductLimit[limitKey] == nil then
            localProductLimit[limitKey] = product.Limit or defaultLimit
        end
        local currentLimit = localProductLimit[limitKey]
        if amount > 0 and currentLimit < amount then return false end
        localProductLimit[limitKey] = currentLimit - amount
        if ps.QueueGuiProductStateUpdate ~= nil then
            ps.QueueGuiProductStateUpdate(client, product)
        end
        return true
    end
end

---@param product Pointshop.Product
---@return string
ps.GetProductName = function (product)
    if product == nil then
        error("GetProductName: argument #1 was nil", 2)
    end

    local name = Traitormod.Language.Pointshop[product.Identifier]

    if name then return name end

    if ItemPrefab.GetItemPrefab(product.Identifier) then
        return ItemPrefab.GetItemPrefab(product.Identifier).Name.Value
    end

    return product.Identifier
end

---@param category Pointshop.Category
---@return string
ps.GetCategoryName = function (category)
    if category == nil then
        error("GetCategoryName: argument #1 was nil", 2)
    end

    if category.Identifier == nil then return "invalid_category" end

    local name = Traitormod.Language.Pointshop[category.Identifier]
    if name then return name end

    return category.Identifier
end

---@param subcategory string|table
---@return table
ps.NormalizeSubcategory = function (subcategory)
    if type(subcategory) == "string" then
        return { Identifier = subcategory }
    end

    return subcategory or {}
end

---@param product Pointshop.Product
---@return table[]
ps.GetProductSubcategoryPath = function (product)
    local subcategory = product.Subcategory
    if subcategory == nil then return {} end

    if type(subcategory) == "string" then
        return { ps.NormalizeSubcategory(subcategory) }
    end

    if subcategory.Identifier ~= nil or subcategory.Name ~= nil then
        return { ps.NormalizeSubcategory(subcategory) }
    end

    local result = {}
    for _, entry in ipairs(subcategory) do
        table.insert(result, ps.NormalizeSubcategory(entry))
    end

    return result
end

---@param subcategory table
---@return string
ps.GetSubcategoryName = function (subcategory)
    if subcategory == nil then
        error("GetSubcategoryName: argument #1 was nil", 2)
    end

    if subcategory.Name ~= nil then return subcategory.Name end

    local identifier = subcategory.Identifier
    if identifier == nil then return "invalid_subcategory" end

    local name = Traitormod.Language.Pointshop[identifier]
    if name then return name end

    return identifier
end

---@param path table[]
---@return string
ps.GetSubcategoryBreadcrumb = function (path)
    local names = {}
    for _, entry in ipairs(path) do
        table.insert(names, ps.GetSubcategoryName(entry))
    end
    return table.concat(names, " > ")
end

---@param productPath table[]
---@param currentPath table[]
---@return boolean
ps.IsPathInside = function (productPath, currentPath)
    if #currentPath > #productPath then return false end

    for index, entry in ipairs(currentPath) do
        local currentIdentifier = entry.Identifier or entry.Name
        local productEntry = productPath[index]
        if productEntry == nil then return false end

        local productIdentifier = productEntry.Identifier or productEntry.Name
        if productIdentifier ~= currentIdentifier then
            return false
        end
    end

    return true
end

---@param category Pointshop.Category
---@param currentPath table[]
---@return table[], Pointshop.Product[]
ps.GetCategoryMenuEntries = function (client, category, currentPath)
    local subcategories = {}
    local subcategoryLookup = {}
    local products = {}

    for _, product in ipairs(category.Products) do
        if ps.CanClientSeeProduct(client, product) then
            local productPath = ps.GetProductSubcategoryPath(product)
            if ps.IsPathInside(productPath, currentPath) then
                if #productPath == #currentPath then
                    table.insert(products, product)
                else
                    local child = productPath[#currentPath + 1]
                    local childKey = child.Identifier or child.Name or tostring(#subcategories + 1)
                    if subcategoryLookup[childKey] == nil then
                        subcategoryLookup[childKey] = child
                        table.insert(subcategories, child)
                    end
                end
            end
        end
    end

    return subcategories, products
end

---@param subcategory table
---@return string?
ps.GetSubcategoryInfo = function (subcategory)
    if subcategory.CounterType == "ClassGroup" and subcategory.Limit ~= nil then
        local selectedGamemode = Traitormod.SelectedGamemode
        local counters = selectedGamemode and selectedGamemode.ClassGroupCounters
        local counterId = subcategory.CounterId or subcategory.Identifier
        local taken = counters and counters[counterId] or 0
        local remaining = math.max(subcategory.Limit - taken, 0)
        local formatString = Traitormod.GetText("PointshopSubcategorySlots")
        return string.format(formatString, remaining, subcategory.Limit)
    end

    return nil
end

---@param subcategory table
---@return string
ps.GetSubcategoryDisplayText = function (subcategory)
    local text = "[" .. ps.GetSubcategoryName(subcategory) .. "]"
    local info = ps.GetSubcategoryInfo(subcategory)
    if info ~= nil then
        text = text .. " - " .. info
    end
    return text
end

---@param product Pointshop.Product
---@return boolean
ps.IsAttackDefendClassProduct = function (product)
    if product == nil then return false end

    local productPath = ps.GetProductSubcategoryPath(product)
    for i = #productPath, 1, -1 do
        local entry = productPath[i]
        if type(entry) == "table" and entry.CounterType == "ClassGroup" then
            return true
        end
    end

    return false
end

---@param client Barotrauma.Networking.Client
---@param category Pointshop.Category
---@param path table[]
---@param message string
ps.ShowCategoryMessageAndReturn = function (client, category, path, message)
    textPromptUtils.Prompt(message, {Traitormod.Language.PointshopGoBack}, client, function (_, client2)
        if not ps.ValidateClient(client2) or not ps.CanClientAccessCategory(client2, category) then
            return
        end

        ps.ShowCategoryItems(client2, category, path)
    end, category.Decoration or "gambler", category.FadeToBlack)
end

---@param client Barotrauma.Networking.Client
---@param name string
---@return Pointshop.Product
ps.FindProductByName = function (client, name)
    for i, category in pairs(ps.ActiveCategories) do
        if ps.CanClientAccessCategory(client, category) then
            for k, product in pairs(category.Products) do
                if ps.CanClientSeeProduct(client, product) and (product.Identifier == name or ps.GetProductName(product) == name) then
                    return product
                end
            end
        end
    end 
end

---@param client Barotrauma.Networking.Client
---@param category Pointshop.Category
---@return boolean
ps.CanClientAccessCategory = function(client, category)
    if category.CanAccess ~= nil then
        return category.CanAccess(client)
    elseif client.Character == nil or client.Character.IsDead or not client.Character.IsHuman then
        return false
    end

    return true
end

---@param client Barotrauma.Networking.Client
---@param product Pointshop.Product
---@return boolean
ps.CanClientSeeProduct = function(client, product)
    if product == nil or product.Enabled == false then
        return false
    end

    if Traitormod.SelectedGamemode ~= nil and Traitormod.SelectedGamemode.RestrictShopToAccessibleCategories then
        local allowed = false
        for _, category in ipairs(ps.ActiveCategories) do
            if category.Identifier == product.CategoryIdentifier and ps.CanClientAccessCategory(client, category) then
                allowed = true
                break
            end
        end
        if not allowed then return false end
    end

    if product.VisibleJobs ~= nil then
        local character = client ~= nil and client.Character or nil
        if character == nil or character.IsDead or not character.IsHuman then
            return false
        end

        for _, job in ipairs(product.VisibleJobs) do
            if character.HasJob(job) then
                return true
            end
        end

        return false
    end

    return true
end

---@param client Barotrauma.Networking.Client
---@return boolean
ps.CanUseShop = function(client)
    if Traitormod.SelectedGamemode == nil or not Traitormod.SelectedGamemode.RestrictShopToAccessibleCategories then return true end
    if client.Character == nil or client.Character.IsDead or not client.Character.IsHuman then return false end
    for _, category in ipairs(ps.ActiveCategories) do
        if ps.CanClientAccessCategory(client, category) then return true end
    end
    return false
end

ps.ValidateClient = function(client)
    if not config.PointShopConfig.Enabled then
        Traitormod.SendMessage(client, Traitormod.Language.CommandNotActive)
        return false
    end

    if not client.InGame then
        Traitormod.SendMessage(client, Traitormod.Language.PointshopInGame)
        return false
    end

    if not ps.CanUseShop(client) then
        Traitormod.SendMessage(client, Traitormod.Language.PointshopNotAvailable)
        return false
    end

    return true
end

---@param item Pointshop.Item
---@return Barotrauma.ItemPrefab?
---@return string?
local function getProductItemPrefab(item)
    local prefab = ItemPrefab.GetItemPrefab(item.Identifier)
    if prefab ~= nil then
        return prefab
    end

    Traitormod.Error("PointShop Error: Could not find item with identifier " .. tostring(item.Identifier))
    return nil, Traitormod.FormatText("PointshopMissingItem", tostring(item.Identifier))
end

---@param client Barotrauma.Networking.Client
---@param product Pointshop.Product
---@param items Barotrauma.Item[]?
---@param paidPrice integer
---@return boolean
---@return Pointshop.ProductBuyFailureReason?
local function runProductAction(client, product, items, paidPrice)
    local ok, success, result = pcall(product.Action, client, product, items, paidPrice)
    if not ok then
        Traitormod.Error("PointShop product " .. tostring(product.Identifier) .. " Action failed: " .. tostring(success))
        return false, Traitormod.Language.PointshopCannotBeUsed
    end

    if success == false then
        return false, result
    end

    return true
end

ps.RunProductAction = runProductAction

---@param client Barotrauma.Networking.Client
---@param item Pointshop.Item
---@param onSpawned fun(obj: Barotrauma.Item)
ps.SpawnItem = function(client, item, onSpawned, destination)
    local prefab, reason = getProductItemPrefab(item)
    local condition = item.Condition or item.MaxCondition

    if prefab == nil then
        Traitormod.SendMessage(client, reason)
        return false
    end

    local function OnSpawn(item)
        local powerContainer = item.GetComponentString("PowerContainer")
        if powerContainer then
            powerContainer.Capacity = powerContainer.Capacity * 10
            powerContainer.Charge = powerContainer.Capacity
        end

        local discharge = item.GetComponentString("ElectricalDischarger")
        if discharge then
            discharge.OutdoorsOnly = false
        end

        local placed = true
        if destination ~= nil and destination.Inventory ~= nil then
            placed = not destination.Container.Removed and destination.Container.Submarine == destination.Submarine
                and destination.Inventory.TryPutItem(item, destination.Slot, false, false, nil, true)
        end
        if onSpawned then onSpawned(item, placed) end
    end

    if destination ~= nil then
        Entity.Spawner.AddItemToSpawnQueue(prefab, destination.Position - destination.Submarine.Position,
            destination.Submarine, condition, nil, OnSpawn)
    elseif item.IsInstallation then
        local position = client.Character.AnimController.GetLimb(LimbType.Torso).WorldPosition
        if client.Character.Submarine == nil then
            Entity.Spawner.AddItemToSpawnQueue(prefab, position, condition, nil, OnSpawn)
        else
            Entity.Spawner.AddItemToSpawnQueue(prefab, position - client.Character.Submarine.Position, client.Character.Submarine, condition, nil, OnSpawn)
        end
    else
        if client.Character.LockHands then
            Entity.Spawner.AddItemToSpawnQueue(prefab, client.Character.WorldPosition, condition, nil, OnSpawn)
        else
            Entity.Spawner.AddItemToSpawnQueue(prefab, client.Character.Inventory, condition, nil, OnSpawn)
        end
    end

    return true
end

---@param client Barotrauma.Networking.Client
---@param product Pointshop.Product
---@param paidPrice integer
---@param itemsToSpawn Pointshop.Item[]
---@return boolean
---@return Pointshop.ProductBuyFailureReason?
ps.ActivateProduct = function (client, product, paidPrice, itemsToSpawn, destinations, onCompleted)
    if #itemsToSpawn == 0 then
        if product.Action then
            return runProductAction(client, product, nil, paidPrice)
        end
        return true
    end

    local spawnedItems = {}
    local spawnedItemCount = 0
    local expectedSpawnCount = #itemsToSpawn
    local placedAll = true

    local function OnSpawned(item, placed)
        table.insert(spawnedItems, item)
        spawnedItemCount = spawnedItemCount + 1
        if placed == false then placedAll = false end
        if spawnedItemCount == expectedSpawnCount then
            local success, result = placedAll, nil
            if placedAll and product.Action then
                success, result = runProductAction(client, product, spawnedItems, paidPrice)
                if not success then Traitormod.SendMessage(client, result or Traitormod.Language.PointshopCannotBeUsed) end
            end
            if onCompleted ~= nil then onCompleted(success, spawnedItems) end
        end
    end

    for index, item in ipairs(itemsToSpawn) do
        ps.SpawnItem(client, item, OnSpawned, destinations ~= nil and destinations[index] or nil)
    end

    return true
end

---@param client Barotrauma.Networking.Client
---@param product Pointshop.Product
---@return integer
ps.GetProductPrice = function (client, product)
    local mult = 0

    if product.RoundPrice then
        local time = Traitormod.RoundTime

        mult = math.remap(time, product.RoundPrice.StartTime * 60, product.RoundPrice.EndTime * 60, 0, product.RoundPrice.PriceReduction)
        mult = math.clamp(mult, 0, product.RoundPrice.PriceReduction)
        mult = math.floor(mult)
    end

    local price = product.Price or 0
    local limit = product.Limit or defaultLimit
    if limit ~= math.huge and (product.PricePerLimit or 0) ~= 0 then
        price = price + (limit - ps.GetProductLimit(client, product)) * product.PricePerLimit
    end
    return price - mult
end

---@param client Barotrauma.Networking.Client
---@param product Pointshop.Product
---@return Pointshop.ProductBuyFailureReason?
ps.BuyProduct = function(client, product)
    local price = 0
    local points = nil
    local previousTimeout = nil
    local accountKey = Traitormod.GetClientAccountKey(client)
    local roundFinalizing = Traitormod.IsRoundFinalizing()

    if not ps.CanClientSeeProduct(client, product) then
        return Traitormod.Language.PointshopCannotBeUsed
    end

    local itemsToSpawn = {}
    if product.Items ~= nil then
        if product.ItemRandom then
            if #product.Items == 0 then
                Traitormod.Error("PointShop product %s has ItemRandom enabled but no items.", tostring(product.Identifier))
                return Traitormod.Language.PointshopCannotBeUsed
            end

            local item = product.Items[math.random(1, #product.Items)]
            if type(item) == "string" then
                item = {Identifier = item}
            end
            table.insert(itemsToSpawn, item)
        elseif next(product.Items) ~= nil then
            for _, value in pairs(product.Items) do
                local item = value
                if type(item) == "string" then
                    item = {Identifier = item}
                end
                table.insert(itemsToSpawn, item)
            end
        end

        for _, item in ipairs(itemsToSpawn) do
            local prefab, itemFailureReason = getProductItemPrefab(item)
            if prefab == nil then
                return itemFailureReason or Traitormod.Language.PointshopCannotBeUsed
            end
        end
    end

    if not Traitormod.Config.TestMode then
        points = Traitormod.GetData(client, "Points") or 0
        price = ps.GetProductPrice(client, product)

        if product.CanBuy then
            local ok, success, result = pcall(product.CanBuy, client, product)
            if not ok then
                Traitormod.Error("PointShop product %s CanBuy failed: %s", tostring(product.Identifier), tostring(success))
                return Traitormod.Language.PointshopCannotBeUsed
            end
            if not success then
                return result or Traitormod.Language.PointshopCannotBeUsed
            end
        end

        if price > points then
            return ps.ProductBuyFailureReason.NoPoints
        end

        if product.Timeout ~= nil then
            previousTimeout = ps.Timeouts[accountKey]
            if ps.Timeouts[accountKey] ~= nil and Timer.GetTime() < ps.Timeouts[accountKey] then
                local time = math.ceil(ps.Timeouts[accountKey] - Timer.GetTime())
                return string.format(Traitormod.Language.PointshopWait, time)
            end

            ps.Timeouts[accountKey] = Timer.GetTime() + product.Timeout
        end

        if not ps.UseProductLimit(client, product) then
            if product.Timeout ~= nil then
                ps.Timeouts[accountKey] = previousTimeout
            end
            return ps.ProductBuyFailureReason.NoStock
        end

        if not roundFinalizing then
            Traitormod.SetData(client, "Points", points - price)
        end
    end

    local paidPrice = roundFinalizing and 0 or price
    local success, result = ps.ActivateProduct(client, product, paidPrice, itemsToSpawn)
    if success == false then
        if not Traitormod.Config.TestMode then
            if not roundFinalizing then
                Traitormod.SetData(client, "Points", points)
            end
            ps.UseProductLimit(client, product, -1)
            if product.Timeout ~= nil then
                ps.Timeouts[accountKey] = previousTimeout
            end
        end
        return result or Traitormod.Language.PointshopCannotBeUsed
    end

    if ps.IsAttackDefendClassProduct ~= nil and ps.IsAttackDefendClassProduct(product) and ps.BroadcastGuiClassLimits ~= nil then
        ps.BroadcastGuiClassLimits()
    end

    if not Traitormod.Config.TestMode then
        Traitormod.Log(string.format("PointShop: %s bought \"%s\".", Traitormod.ClientLogName(client), product.Identifier))
        Traitormod.Stats.AddClientStat("CrewBoughtItem", client, 1)
        Traitormod.Stats.AddListStat("ItemsBought", ps.GetProductName(product), 1)
    end
end

---@param client Barotrauma.Networking.Client
---@param product Pointshop.Product
---@param result Pointshop.ProductBuyFailureReason?
---@param quantity integer?
ps.HandleProductBuy = function (client, product, result, quantity)
    quantity = quantity or 1
    if result == ps.ProductBuyFailureReason.NoPoints then
        textPromptUtils.Prompt(Traitormod.Language.PointshopNoPoints, {}, client, function (id, client) end, "gambler")
    elseif result == ps.ProductBuyFailureReason.NoStock then
        textPromptUtils.Prompt(Traitormod.Language.PointshopNoStock, {}, client, function (id, client) end, "gambler")
    elseif result == nil then
        textPromptUtils.Prompt(
            string.format(
                Traitormod.Language.PointshopPurchased,
                ps.GetProductName(product),
                ps.GetProductPrice(client, product),
                math.floor(Traitormod.GetData(client, "Points") or 0)
            ),
            {},
            client,
            function () end,
            "gambler"
        )
    else
        textPromptUtils.Prompt(result, {}, client, function (id, client) end, "gambler")
    end
end

---@param client Barotrauma.Networking.Client
---@param category Pointshop.Category
---@param path table[]?
ps.ShowCategoryItems = function(client, category, path)
    path = path or {}

    local options = {}
    local productsLookup = {}
    local subcategoriesLookup = {}
    local subcategories, products = ps.GetCategoryMenuEntries(client, category, path)

    table.insert(options, Traitormod.Language.PointshopGoBack)
    table.insert(options, Traitormod.Language.PointshopCancel)

    for _, subcategory in ipairs(subcategories) do
        table.insert(options, ps.GetSubcategoryDisplayText(subcategory))
        subcategoriesLookup[#options] = subcategory
    end

    for _, product in ipairs(products) do
        local limit = product.Limit or defaultLimit
        local price = ps.GetProductPrice(client, product)
        local productInfo = {}

        if price ~= 0 then
            table.insert(productInfo, ("%spt"):format(price))
        end
        if limit ~= math.huge then
            table.insert(productInfo, ("%s/%s products"):format(ps.GetProductLimit(client, product), limit))
        end

        local text = ps.GetProductName(product)
        if #productInfo > 0 then text = text .. " - " .. table.concat(productInfo, " ") end

        table.insert(options, text)
        productsLookup[#options] = product
    end

    local emptyLines = math.floor(#options / 4)
    for i = 1, emptyLines, 1 do
        table.insert(options, "") -- FIXME: some hud scaling settings will hide list items
    end

    local points = Traitormod.GetData(client, "Points") or 0
    local promptText = string.format(Traitormod.Language.PointshopWishBuy, math.floor(points))
    if #path > 0 then
        promptText = promptText .. "\n" .. ps.GetSubcategoryBreadcrumb(path)
    end

    textPromptUtils.Prompt(
        promptText,
        options, client, function (id, client2)
        if id == 1 then
            if #path > 0 then
                local parentPath = {}
                for index = 1, #path - 1 do
                    parentPath[index] = path[index]
                end
                ps.ShowCategoryItems(client2, category, parentPath)
            else
                ps.ShowCategory(client2)
            end
            return
        end

        local subcategory = subcategoriesLookup[id]
        if subcategory ~= nil then
            local nextPath = {}
            for index, entry in ipairs(path) do
                nextPath[index] = entry
            end
            table.insert(nextPath, subcategory)
            ps.ShowCategoryItems(client2, category, nextPath)
            return
        end

        local product = productsLookup[id]
        if product == nil then return end

        -- Check if product needs to be installed
        if ps.GetProductHasInstallation(product) then
            textPromptUtils.Prompt(
            Traitormod.Language.PointshopInstallation,
            {Traitormod.Language.Yes, Traitormod.Language.No}, client2, function (id, client3)
                if id == 1 then
                    if not ps.ValidateClient(client3) or not ps.CanClientAccessCategory(client2, category) then
                        return
                    end

                    local result = ps.BuyProduct(client3, product)
                    if result ~= nil and ps.IsAttackDefendClassProduct(product) then
                        ps.ShowCategoryMessageAndReturn(client3, category, path, result)
                    else
                        ps.HandleProductBuy(client3, product, result)
                    end
                end
            end, category.Decoration or "gambler", category.FadeToBlack)
        else
            if not ps.ValidateClient(client2) or not ps.CanClientAccessCategory(client2, category) then
                return
            end

            local result = ps.BuyProduct(client2, product)
            if result ~= nil and ps.IsAttackDefendClassProduct(product) then
                ps.ShowCategoryMessageAndReturn(client2, category, path, result)
            else
                ps.HandleProductBuy(client2, product, result)
            end
        end
    end, category.Decoration or "gambler", category.FadeToBlack)
end

---@param client Barotrauma.Networking.Client
---@param resend boolean?
ps.ShowCategory = function(client, resend)
    local options = {}
    local categoryLookup = {}

    table.insert(options, Traitormod.Language.PointshopCancel)
    for key, value in pairs(ps.ActiveCategories) do
        if ps.CanClientAccessCategory(client, value) then
            local subcategories, products = ps.GetCategoryMenuEntries(client, value, {})
            if #subcategories > 0 or #products > 0 then
                table.insert(options, ps.GetCategoryName(value))
                categoryLookup[#options] = value
            end
        end
    end

    if #options == 1 then
        textPromptUtils.Prompt(Traitormod.Language.PointshopNotAvailable, {}, client, function (id, client) end, "gambler")
        return
    end

    table.insert(options, "")
    table.insert(options, "") -- FIXME: for some reason when the bar is full, the last item is never shown?

    local points = Traitormod.GetData(client, "Points") or 0

    -- note: we have two different client variables here to prevent cheating
    textPromptUtils.Prompt(string.format(Traitormod.Language.PointshopWishCategory, math.floor(points)), options, client, function (id, client2)
        if id == 256 and resend then
            Timer.Wait(function ()
                ps.ShowCategory(client2, resend)
            end, 1000)
        end
        if categoryLookup[id] == nil then return end

        ps.ShowCategoryItems(client2, categoryLookup[id])
    end, "officeinside")
end


-- GUI pointshop for clients with the pack's Lua. Everyone else, and special shops the GUI
-- doesn't support, use the text prompt shop above.
ps.GuiNet = {
    Ready = "VoidTraitor_PointshopGuiReady",
    Request = "VoidTraitor_PointshopRequest",
    Snapshot = "VoidTraitor_PointshopSnapshot",
    State = "VoidTraitor_PointshopState",
    Balance = "VoidTraitor_PointshopBalance",
    ProductState = "VoidTraitor_PointshopProductState",
    BuyCart = "VoidTraitor_PointshopBuyCart",
    Probe = "VoidTraitor_PointshopProbe",
    PurchaseSound = "VoidTraitor_PointshopPurchaseSound",
    ClassLimits = "VoidTraitor_PointshopClassLimits",
}
local guiNet = ps.GuiNet


ps.GuiClients = ps.GuiClients or {}
ps.GuiProductMaps = ps.GuiProductMaps or {}
ps.GuiProductIds = ps.GuiProductIds or {}

local attackDefendCategories = {
    spawnBlue = true,
    spawnRed = true,
    hideBlue = true,
    hideRed = true,
}

local function hasAttackDefendCategories()
    for _, category in pairs(ps.ActiveCategories) do
        if attackDefendCategories[category.Identifier] then
            return true
        end
    end

    return false
end

local function isGhostClient(client)
    return client.Character == nil or client.Character.IsDead or not client.Character.IsHuman
end

local function getGuiMode(client)
    if hasAttackDefendCategories() then
        return "attackdefend"
    end

    if isGhostClient(client) then
        return "ghost"
    end

    return "shop"
end

local function getProductCooldownRemaining(client, product)
    if product.Timeout == nil then return 0 end
    if ps.Timeouts[Traitormod.GetClientAccountKey(client)] == nil then return 0 end

    return math.max(math.ceil(ps.Timeouts[Traitormod.GetClientAccountKey(client)] - Timer.GetTime()), 0)
end

local function shouldCloseGuiAfterPurchase(product)
    return product.CloseGuiAfterPurchase == true or product.GuiCreature ~= nil or ps.IsAttackDefendClassProduct(product)
end

local function getGuiMessageText(value)
    if value == ps.ProductBuyFailureReason.NoPoints then
        return Traitormod.Language.PointshopNoPoints
    elseif value == ps.ProductBuyFailureReason.NoStock then
        return Traitormod.Language.PointshopNoStock
    elseif value == nil then
        return ""
    end

    return tostring(value)
end

local function toNetInt32(value, fallback)
    local number = tonumber(value)
    if number == nil or number ~= number then
        return fallback or 0
    end

    if number == math.huge then
        return 2147483647
    end

    if number == -math.huge then
        return -2147483648
    end

    number = math.floor(number)
    if number > 2147483647 then return 2147483647 end
    if number < -2147483648 then return -2147483648 end

    return number
end

local function getRoundPriceReduction(product)
    if product.RoundPrice == nil then return 0 end

    local time = Traitormod.RoundTime
    local mult = math.remap(time, product.RoundPrice.StartTime * 60, product.RoundPrice.EndTime * 60, 0, product.RoundPrice.PriceReduction)
    mult = math.clamp(mult, 0, product.RoundPrice.PriceReduction)
    return math.floor(mult)
end

local function getProductPriceWithLimit(product, simulatedLimit)
    local limit = product.Limit or defaultLimit
    local price = product.Price or 0
    if limit ~= math.huge and (product.PricePerLimit or 0) ~= 0 then
        price = price + (limit - simulatedLimit) * product.PricePerLimit
    end
    return price - getRoundPriceReduction(product)
end

local function getProductType(product)
    if ps.IsAttackDefendClassProduct(product) then return "class" end
    if ps.GetProductHasInstallation(product) then return "installation" end
    if product.Action ~= nil and product.Items ~= nil then return "item_action" end
    if product.Action ~= nil then return "action" end
    return "item"
end

local function canUseQuantityInGui(product)
    if product.AllowQuantity ~= nil then
        return product.AllowQuantity == true
    end

    return product.Items ~= nil
        and product.Action == nil
        and product.Timeout == nil
        and product.IsLimitGlobal ~= true
        and product.IsLimitGlobalAcrossCategories ~= true
        and product.ItemRandom ~= true
        and not ps.GetProductHasInstallation(product)
        and not ps.IsAttackDefendClassProduct(product)
end

local function getGuiMaxQuantity(client, product)
    local remaining = math.max(math.floor(ps.GetProductLimit(client, product) or 0), 0)

    if not canUseQuantityInGui(product) then
        return math.min(remaining, 1)
    end

    local configuredMax = tonumber(product.MaxCartQuantity or product.MaxQuantity or product.CartLimit)
    if configuredMax ~= nil then
        return math.max(math.min(remaining, math.floor(configuredMax)), 1)
    end

    return math.max(remaining, 1)
end

local function canUseGuiShop(client)
    if not ps.GuiClients[client] then
        return false
    end
    if not ps.ValidateClient(client) then
        return false
    end

    local mode = getGuiMode(client)
    if mode == "shop" then
        return client.Character ~= nil and not client.Character.IsDead and client.Character.IsHuman
    end

    return true
end

local function getProductStateDisabledReason(client, product)
    if not ps.CanClientSeeProduct(client, product) then
        return Traitormod.Language.PointshopCannotBeUsed
    end

    local stock = ps.GetProductLimit(client, product)
    if stock <= 0 then
        return Traitormod.Language.PointshopNoStock
    end

    if product.CanBuy then
        local ok, success, result = pcall(product.CanBuy, client, product)
        if not ok then
            Traitormod.Error("PointShop GUI: CanBuy failed for product %s: %s", tostring(product.Identifier), tostring(success))
            return Traitormod.Language.PointshopCannotBeUsed
        end

        if not success then
            return result or Traitormod.Language.PointshopCannotBeUsed
        end
    end

    return ""
end

local function getProductDescription(product)
    local pointshopLanguage = Traitormod.Language.Pointshop or {}
    local description = product.Description
        or pointshopLanguage[product.Identifier .. "_desc"]
        or pointshopLanguage[product.Identifier .. "Description"]
    if description ~= nil and tostring(description) ~= "" then
        return tostring(description)
    end

    if product.Items ~= nil then
        for _, item in pairs(product.Items) do
            local identifier = type(item) == "table" and item.Identifier or item
            local prefab = identifier ~= nil and ItemPrefab.GetItemPrefab(identifier) or nil
            if prefab ~= nil and prefab.Description ~= nil and prefab.Description.Value ~= "" then
                return prefab.Description.Value
            end
        end
    end

    return ""
end

local function getManualGuiIconIdentifier(config)
    if type(config) ~= "table" then return "" end

    -- Any existing ItemPrefab identifier can be used here. Examples:
    -- category.Icon = "wrench"
    -- product.Icon = "morphine"
    -- Subcategory = { Identifier = "skillbooks", Icon = "skillbooksubmarinewarfare" }
    local manualIcon = config.GuiIcon or config.IconIdentifier or config.IconItem or config.DisplayIcon or config.Icon
    if type(manualIcon) == "string" and manualIcon ~= "" then
        return manualIcon
    end

    return ""
end

local function getAttackDefendClassJobIdentifier(product)
    local manualJob = product.GuiJobIdentifier or product.JobIdentifier or product.JobId or product.Job
    if type(manualJob) == "string" and manualJob ~= "" then
        return manualJob
    end

    local productPath = ps.GetProductSubcategoryPath(product)
    for index = #productPath, 1, -1 do
        local entry = productPath[index]
        if type(entry) == "table" and entry.CounterType == "ClassGroup" then
            return entry.CounterId or entry.JobIdentifier or entry.Identifier
        end
    end

    return nil
end

local function getAttackDefendClassLimitText(product)
    if not ps.IsAttackDefendClassProduct(product) then return "" end

    local productPath = ps.GetProductSubcategoryPath(product)
    for index = #productPath, 1, -1 do
        local entry = productPath[index]
        if type(entry) == "table" and entry.CounterType == "ClassGroup" then
            return ps.GetSubcategoryInfo(entry) or ""
        end
    end

    return ""
end

local function getPathIdentifiers(product)
    local productPath = ps.GetProductSubcategoryPath(product)
    local pathIdentifiers = {}
    for _, pathEntry in ipairs(productPath) do
        table.insert(pathIdentifiers, tostring(pathEntry.Identifier or pathEntry.Name or ""))
    end

    return table.concat(pathIdentifiers, " > ")
end

local function collectGuiClassLimitEntries(client)
    local entries = {}
    local seen = {}

    if getGuiMode(client) ~= "attackdefend" then
        return entries
    end

    for _, category in ipairs(ps.ActiveCategories) do
        if ps.CanClientAccessCategory(client, category) then
            for _, product in ipairs(category.Products) do
                if ps.IsAttackDefendClassProduct(product) and ps.CanClientSeeProduct(client, product) then
                    local categoryIdentifier = tostring(category.Identifier or "")
                    local pathIdentifiers = getPathIdentifiers(product)
                    local key = categoryIdentifier .. "\30" .. pathIdentifiers
                    if not seen[key] then
                        seen[key] = true
                        table.insert(entries, {
                            CategoryIdentifier = categoryIdentifier,
                            PathIdentifiers = pathIdentifiers,
                            LimitText = getAttackDefendClassLimitText(product),
                        })
                    end
                end
            end
        end
    end

    return entries
end

function ps.SendGuiClassLimits(client)
    if client == nil or client.Connection == nil or not ps.GuiClients[client] then
        return false
    end

    local entries = collectGuiClassLimitEntries(client)

    local netMessage = Networking.Start(guiNet.ClassLimits)
    netMessage.WriteInt32(toNetInt32(#entries, 0))
    for _, entry in ipairs(entries) do
        netMessage.WriteString(entry.CategoryIdentifier)
        netMessage.WriteString(entry.PathIdentifiers)
        netMessage.WriteString(entry.LimitText or "")
    end

    Networking.Send(netMessage, client.Connection)
    return true
end

function ps.BroadcastGuiClassLimits()
    for _, client in pairs(Client.ClientList) do
        ps.SendGuiClassLimits(client)
    end
end

local function getProductIconIdentifier(product)
    local manualIcon = getManualGuiIconIdentifier(product)
    if manualIcon ~= "" then return manualIcon end

    if ps.IsAttackDefendClassProduct(product) then
        local jobIdentifier = getAttackDefendClassJobIdentifier(product)
        if type(jobIdentifier) == "string" and jobIdentifier ~= "" then
            return "job:" .. jobIdentifier
        end
    end

    -- default icon: the first item the product gives
    if product.Items ~= nil then
        for _, item in pairs(product.Items) do
            if type(item) == "string" then
                return item
            elseif type(item) == "table" and type(item.Identifier) == "string" and item.Identifier ~= "" then
                return item.Identifier
            end
        end
    end

    return ""
end

function ps.GetGuiProduct(client, category, product, id)
    local productPath = ps.GetProductSubcategoryPath(product)
    local pathNames = {}
    local pathIdentifiers = {}
    local pathIcons = {}
    for _, pathEntry in ipairs(productPath) do
        table.insert(pathNames, ps.GetSubcategoryName(pathEntry))
        table.insert(pathIdentifiers, tostring(pathEntry.Identifier or pathEntry.Name or ""))
        table.insert(pathIcons, getManualGuiIconIdentifier(pathEntry))
    end

    local remaining = ps.GetProductLimit(client, product)
    local limit = product.Limit or defaultLimit
    local disabledReason = getProductStateDisabledReason(client, product)

    return {
        Id = id,
        Category = ps.GetCategoryName(category),
        Path = table.concat(pathNames, " > "),
        Name = ps.GetProductName(product),
        Description = getProductDescription(product),
        Price = ps.GetProductPrice(client, product),
        Stock = remaining,
        Limit = limit,
        Type = getProductType(product),
        IconIdentifier = getProductIconIdentifier(product),
        AllowQuantity = canUseQuantityInGui(product),
        DisabledReason = disabledReason,
        CategoryIdentifier = tostring(category.Identifier or ""),
        CategoryIconIdentifier = getManualGuiIconIdentifier(category),
        PathIdentifiers = table.concat(pathIdentifiers, " > "),
        PathIconIdentifiers = table.concat(pathIcons, "\31"),
        MaxQuantity = getGuiMaxQuantity(client, product),
        CooldownRemaining = getProductCooldownRemaining(client, product),
        CloseAfterPurchase = shouldCloseGuiAfterPurchase(product),
        LimitText = getAttackDefendClassLimitText(product),
    }
end

function ps.SendGuiSnapshot(client, message, purchaseCompleted, closeAfterPurchase)
    if not canUseGuiShop(client) then
        return false
    end

    local mode = getGuiMode(client)
    local products = {}
    local productMap = {}
    local productIds = {}
    local productIndex = 0

    for categoryIndex, category in ipairs(ps.ActiveCategories) do
        if ps.CanClientAccessCategory(client, category) then
            for productConfigIndex, product in ipairs(category.Products) do
                if ps.CanClientSeeProduct(client, product) then
                    productIndex = productIndex + 1
                    local guiId = tostring(categoryIndex) .. ":" .. tostring(productConfigIndex) .. ":" .. tostring(productIndex)
                    productMap[guiId] = {
                        Id = guiId,
                        Category = category,
                        Product = product,
                    }
                    table.insert(productIds, guiId)

                    table.insert(products, ps.GetGuiProduct(client, category, product, guiId))
                end
            end
        end
    end

    ps.GuiProductMaps[client] = productMap
    ps.GuiProductIds[client] = productIds

    local netMessage = Networking.Start(guiNet.Snapshot)
    netMessage.WriteString(tostring(message or ""))
    netMessage.WriteInt32(toNetInt32(Traitormod.GetData(client, "Points"), 0))
    netMessage.WriteString(mode)
    netMessage.WriteInt32(toNetInt32(#products, 0))

    for _, product in ipairs(products) do
        netMessage.WriteString(tostring(product.Id))
        netMessage.WriteString(tostring(product.Category))
        netMessage.WriteString(tostring(product.Path))
        netMessage.WriteString(tostring(product.Name))
        netMessage.WriteString(tostring(product.Description or ""))
        netMessage.WriteInt32(toNetInt32(product.Price, 0))
        netMessage.WriteInt32(toNetInt32(product.Stock, 0))
        netMessage.WriteInt32(toNetInt32(product.Limit, defaultLimit))
        netMessage.WriteString(tostring(product.Type))
        netMessage.WriteString(tostring(product.IconIdentifier or ""))
        netMessage.WriteBoolean(product.AllowQuantity)
        netMessage.WriteString(tostring(product.DisabledReason or ""))
        netMessage.WriteString(tostring(product.CategoryIdentifier or ""))
        netMessage.WriteString(tostring(product.CategoryIconIdentifier or ""))
        netMessage.WriteString(tostring(product.PathIdentifiers or ""))
        netMessage.WriteString(tostring(product.PathIconIdentifiers or ""))
        netMessage.WriteInt32(toNetInt32(product.MaxQuantity, 1))
        netMessage.WriteInt32(toNetInt32(product.CooldownRemaining, 0))
        netMessage.WriteBoolean(product.CloseAfterPurchase == true)
        netMessage.WriteString(tostring(product.LimitText or ""))
    end


    netMessage.WriteBoolean(purchaseCompleted == true)
    netMessage.WriteBoolean(closeAfterPurchase == true)

    Networking.Send(netMessage, client.Connection)
    return true
end

local function getGuiProductState(client, mapEntry)
    local product = mapEntry.Product
    return {
        Id = mapEntry.Id,
        Price = ps.GetProductPrice(client, product),
        Stock = ps.GetProductLimit(client, product),
        DisabledReason = getProductStateDisabledReason(client, product),
        MaxQuantity = getGuiMaxQuantity(client, product),
        CooldownRemaining = getProductCooldownRemaining(client, product),
    }
end

local function writeGuiProductState(netMessage, state)
    netMessage.WriteString(tostring(state.Id or ""))
    netMessage.WriteInt32(toNetInt32(state.Price, 0))
    netMessage.WriteInt32(toNetInt32(state.Stock, 0))
    netMessage.WriteString(tostring(state.DisabledReason or ""))
    netMessage.WriteInt32(toNetInt32(state.MaxQuantity, 1))
    netMessage.WriteInt32(toNetInt32(state.CooldownRemaining, 0))
end

-- Sends only the fields that change (price, stock, cooldown...); the catalog itself is sent once in the snapshot.
function ps.SendGuiState(client, message, purchaseCompleted, closeAfterPurchase)
    if not canUseGuiShop(client) then
        return false
    end

    local productMap = ps.GuiProductMaps[client]
    local productIds = ps.GuiProductIds[client]
    if productMap == nil or productIds == nil then
        return ps.SendGuiSnapshot(client, message, purchaseCompleted, closeAfterPurchase)
    end

    local states = {}
    for _, productId in ipairs(productIds) do
        local mapEntry = productMap[productId]
        if mapEntry ~= nil then
            table.insert(states, getGuiProductState(client, mapEntry))
        end
    end

    local netMessage = Networking.Start(guiNet.State)
    netMessage.WriteString(tostring(message or ""))
    netMessage.WriteInt32(toNetInt32(Traitormod.GetData(client, "Points"), 0))
    netMessage.WriteString(getGuiMode(client))
    netMessage.WriteInt32(toNetInt32(#states, 0))
    for _, state in ipairs(states) do
        writeGuiProductState(netMessage, state)
    end
    netMessage.WriteBoolean(purchaseCompleted == true)
    netMessage.WriteBoolean(closeAfterPurchase == true)
    Networking.Send(netMessage, client.Connection)
    return true
end

function ps.SendGuiBalance(client)
    if client == nil or client.Connection == nil or not ps.GuiClients[client] or ps.GuiProductMaps[client] == nil then
        return false
    end

    local netMessage = Networking.Start(guiNet.Balance)
    netMessage.WriteInt32(toNetInt32(Traitormod.GetData(client, "Points"), 0))
    Networking.Send(netMessage, client.Connection)
    return true
end

local guiBalanceSuppressed = {}

function ps.NotifyGuiBalanceChanged(client)
    if guiBalanceSuppressed[client] then return true end
    return ps.SendGuiBalance(client)
end

local function sendGuiProductStateUpdate(client, product)
    if client == nil or client.Connection == nil or not ps.GuiClients[client] then
        return false
    end

    local productMap = ps.GuiProductMaps[client]
    local productIds = ps.GuiProductIds[client]
    if productMap == nil or productIds == nil then return false end

    local changedKey = getProductLimitKey(product)
    local states = {}
    for _, productId in ipairs(productIds) do
        local mapEntry = productMap[productId]
        if mapEntry ~= nil and getProductLimitKey(mapEntry.Product) == changedKey then
            table.insert(states, getGuiProductState(client, mapEntry))
        end
    end
    if #states == 0 then return false end

    local netMessage = Networking.Start(guiNet.ProductState)
    netMessage.WriteInt32(toNetInt32(#states, 0))
    for _, state in ipairs(states) do
        writeGuiProductState(netMessage, state)
    end
    Networking.Send(netMessage, client.Connection)
    return true
end

local pendingGlobalGuiProducts = {}
local pendingLocalGuiProducts = {}
local guiProductFlushScheduled = false

local function flushGuiProductUpdates()
    guiProductFlushScheduled = false
    local globalProducts = pendingGlobalGuiProducts
    local localProducts = pendingLocalGuiProducts
    pendingGlobalGuiProducts = {}
    pendingLocalGuiProducts = {}

    for _, product in pairs(globalProducts) do
        for _, client in pairs(Client.ClientList) do
            sendGuiProductStateUpdate(client, product)
        end
    end
    for client, productsForClient in pairs(localProducts) do
        for _, product in pairs(productsForClient) do
            sendGuiProductStateUpdate(client, product)
        end
    end
end

function ps.QueueGuiProductStateUpdate(client, product)
    if product == nil then return end

    local productKey = getProductLimitKey(product)
    if product.IsLimitGlobal or product.IsLimitGlobalAcrossCategories then
        pendingGlobalGuiProducts[productKey] = product
    elseif client ~= nil then
        pendingLocalGuiProducts[client] = pendingLocalGuiProducts[client] or {}
        pendingLocalGuiProducts[client][productKey] = product
    end

    if not guiProductFlushScheduled then
        guiProductFlushScheduled = true
        Timer.Wait(flushGuiProductUpdates, 1)
    end
end

local function sendGuiPurchaseSound(client)
    if client == nil or client.Connection == nil then return false end

    local netMessage = Networking.Start(guiNet.PurchaseSound)
    Networking.Send(netMessage, client.Connection)
    return true
end

local function validateGuiCart(client, entries)
    if #entries == 0 then
        return false, Traitormod.Language.PointshopGuiCartEmpty
    end

    if getGuiMode(client) == "ghost" and #entries > 1 then
        return false, Traitormod.Language.PointshopCannotBeUsed
    end

    local productMap = ps.GuiProductMaps[client]
    if productMap == nil then
        return false, Traitormod.Language.PointshopCannotBeUsed
    end

    local points = Traitormod.GetData(client, "Points") or 0
    local totalPrice = 0
    local simulatedLimits = {}
    local normalizedEntries = {}

    for _, entry in ipairs(entries) do
        local mapEntry = productMap[entry.Id]
        if mapEntry == nil then
            return false, Traitormod.Language.PointshopCannotBeUsed
        end

        local category = mapEntry.Category
        local product = mapEntry.Product

        if ps.IsAttackDefendClassProduct(product) and #entries > 1 then
            return false, Traitormod.Language.PointshopCannotBeUsed
        end

        if not ps.CanClientAccessCategory(client, category) or not ps.CanClientSeeProduct(client, product) then
            return false, Traitormod.Language.PointshopCannotBeUsed
        end

        if product.CanBuy then
            local ok, success, result = pcall(product.CanBuy, client, product)
            if not ok then
                Traitormod.Error("PointShop GUI: CanBuy failed for product %s: %s", tostring(product.Identifier), tostring(success))
                return false, Traitormod.Language.PointshopCannotBeUsed
            end

            if not success then
                return false, result or Traitormod.Language.PointshopCannotBeUsed
            end
        end

        local requestedQuantity = math.floor(tonumber(entry.Quantity) or 1)
        if requestedQuantity < 1 then requestedQuantity = 1 end

        if ps.IsAttackDefendClassProduct(product) and requestedQuantity > 1 then
            return false, Traitormod.Language.PointshopCannotBeUsed
        end

        local maxQuantity = getGuiMaxQuantity(client, product)
        if requestedQuantity > maxQuantity then
            if not canUseQuantityInGui(product) then
                return false, Traitormod.Language.PointshopGuiSinglePurchase or Traitormod.Language.PointshopCannotBeUsed
            end
            return false, Traitormod.Language.PointshopNoStock
        end

        local quantity = requestedQuantity

        local productKey = getProductLimitKey(product)
        if simulatedLimits[productKey] == nil then
            simulatedLimits[productKey] = ps.GetProductLimit(client, product)
        end

        if simulatedLimits[productKey] < quantity then
            return false, Traitormod.Language.PointshopNoStock
        end

        local cooldown = getProductCooldownRemaining(client, product)
        if cooldown > 0 then
            return false, string.format(Traitormod.Language.PointshopWait, cooldown)
        end

        for i = 1, quantity do
            totalPrice = totalPrice + getProductPriceWithLimit(product, simulatedLimits[productKey])
            simulatedLimits[productKey] = simulatedLimits[productKey] - 1
        end

        table.insert(normalizedEntries, {
            Product = product,
            Quantity = quantity,
        })
    end

    if totalPrice > points and not Traitormod.Config.TestMode then
        return false, Traitormod.Language.PointshopNoPoints
    end

    return true, normalizedEntries, totalPrice
end

function ps.BuyGuiCart(client, entries)
    if not canUseGuiShop(client) then
        return
    end

    local valid, normalizedEntries, totalPrice = validateGuiCart(client, entries)
    if not valid then
        ps.SendGuiState(client, normalizedEntries or Traitormod.Language.PointshopCannotBeUsed)
        return
    end

    guiBalanceSuppressed[client] = true
    local boughtCount = 0
    local closeAfterPurchase = false
    for _, entry in ipairs(normalizedEntries) do
        if shouldCloseGuiAfterPurchase(entry.Product) then
            closeAfterPurchase = true
        end

        for i = 1, entry.Quantity do
            local result = ps.BuyProduct(client, entry.Product)
            if result ~= nil then
                guiBalanceSuppressed[client] = nil
                ps.SendGuiState(client, getGuiMessageText(result))
                return
            end
            boughtCount = boughtCount + 1
        end
    end

    guiBalanceSuppressed[client] = nil
    local message = string.format(Traitormod.Language.PointshopGuiPurchased, boughtCount, math.floor(totalPrice or 0))
    sendGuiPurchaseSound(client)
    ps.SendGuiState(client, message, true, closeAfterPurchase)
end


ps.TrackRefund = function (client, product, paidPrice)
    ps.Refunds[client] = { Product = product, Time = Timer.GetTime(), Price = paidPrice }
end

function ps.SendGuiProbe(client, reason)
    if client == nil or client.Connection == nil then return false end

    local netMessage = Networking.Start(guiNet.Probe)
    Networking.Send(netMessage, client.Connection)
    return true
end

function ps.MarkGuiClientReady(client)
    if client == nil then return false end
    ps.GuiClients[client] = true
    return true
end

function ps.RequestGuiSnapshot(client)
    if client == nil then return false end
    ps.GuiClients[client] = true
    if #ps.ActiveCategories == 0 then return false end
    return ps.SendGuiSnapshot(client)
end

function ps.HandleGuiCart(client, entries)
    if client == nil then return false end


    ps.GuiClients[client] = true
    ps.BuyGuiCart(client, entries or {})
    return true
end

function ps.ForgetGuiClient(client)
    ps.GuiClients[client] = nil
    ps.GuiProductMaps[client] = nil
    ps.GuiProductIds[client] = nil
    guiBalanceSuppressed[client] = nil
end

local function openOldPointshop(client)
    ps.ShowCategory(client)
end

local function openGuiOrFallback(client, forced)
    if ps.GuiClients[client] then
        if ps.SendGuiSnapshot(client) then return true end
        if forced then
            Traitormod.SendMessage(client, Traitormod.Language.PointshopGuiUnavailable)
        end
        openOldPointshop(client)
        return true
    end

    ps.SendGuiProbe(client, forced and "forced gui command" or "default shop command")
    Timer.Wait(function()
        if ps.GuiClients[client] and ps.SendGuiSnapshot(client) then return end

        if forced then
            Traitormod.SendMessage(client, Traitormod.Language.PointshopGuiUnavailable)
        end
        openOldPointshop(client)
    end, 750)
    return true
end

ps.OpenGuiOrFallback = openGuiOrFallback

ps.Command = function (client, args)
    if #ps.ActiveCategories == 0 then
        textPromptUtils.Prompt(Traitormod.Language.PointshopNotAvailable, {}, client, function (id, client) end, "gambler")
        return true    
    end

    if not ps.ValidateClient(client) then
        return true
    end

    if #args > 0 then
        local product = ps.FindProductByName(client, args[1])

        if product ~= nil then
            local amount = 1

            if args[2] ~= nil then
                amount = tonumber(args[2]) or amount
            end

            amount = math.min(amount, 8)

            for i=1, amount, 1 do
                local result = ps.BuyProduct(client, product)

                if result == ps.ProductBuyFailureReason.NoPoints then
                    Traitormod.SendMessage(client, Traitormod.Language.PointshopNoPoints)
                end

                if result == ps.ProductBuyFailureReason.NoStock then
                    Traitormod.SendMessage(client, Traitormod.Language.PointshopNoStock)
                end
            end

            return true
        end
    end

    if args[1] == "old" or args[1] == "text" then
        ps.ShowCategory(client)
        return true
    end

    if args[1] == "gui" then
        return openGuiOrFallback(client, true)
    end
    return openGuiOrFallback(client, false)
end


Hook.Add("roundStart", "TraitormMod.PointShop.RoundStart", function ()
    for key, value in pairs(Client.ClientList) do
        ps.Timeouts[Traitormod.GetClientAccountKey(value)] = Timer.GetTime() + 300
    end
end)

local function refundProduct(client, refundTable, increaseProduct)
    -- it will not increase the amount of the product at the end of the round
    if increaseProduct ~= nil then
        -- increase the amount of the product
        ps.UseProductLimit(client, refundTable.Product, increaseProduct)
    end

    Traitormod.AwardPoints(client, refundTable.Price)
    Traitormod.SendMessage(client, string.format(Traitormod.Language.PointshopRefunded, refundTable.Price, ps.GetProductName(refundTable.Product)))

    ps.Refunds[client] = nil
end

ps.FinalizeRefunds = function ()
    if Traitormod.Config.TestMode or not config.PointShopConfig.DeathSpawnRefundAtEndRound then return end

    for client, refundTable in pairs(ps.Refunds) do
        if client.Character ~= nil and not client.Character.IsPet then
            refundTable.Price = refundTable.Price * math.min(client.Character.Vitality / client.Character.MaxVitality, 1)
            refundProduct(client, refundTable)
        end
    end
end

Hook.Add("roundEnd", "TraitorMod.PointShop.RoundEnd", function ()
    ps.ResetProductLimits()
    ps.ActiveCategories = {}
    ps.FinalizeRefunds()
end)

---@param character Barotrauma.Character
Hook.Add("characterDeath", "Traitormod.Pointshop.Death", function (character)
    if character.IsPet then return end
    local client = Traitormod.FindClientCharacter(character)
    if client == nil then return end
    if Traitormod.Config.TestMode then return end

    local refundTable = ps.Refunds[client]

    -- check if the character died in the first 15 seconds in order to get a refund
    if refundTable and refundTable.Time + 15 > Timer.GetTime() then
        refundProduct(client, refundTable, -1)
    else
        ps.Timeouts[Traitormod.GetClientAccountKey(client)] = Timer.GetTime() + config.PointShopConfig.DeathTimeoutTime
    end

    -- this line will make sure it doesnt stay in the memory
    ps.Refunds[client] = nil
end)


for _, category in pairs(config.PointShopConfig.ItemCategories) do
    if category.Init then category.Init() end
    ps.AllCategories[category.Identifier] = category -- Creates a table out of config

    for __, product in pairs(category.Products) do
        if not product.Identifier then
            if product.Items then
                if type(product.Items[1]) == "table" then
                    product.Identifier = product.Items[1].Identifier
                else
                    product.Identifier = product.Items[1]
                end
            else
                Traitormod.Error("Product has no identifier nor any items, unable to figure out an identifier for the product. Category = %s, Name = %s, Price = %s", tostring(category.Identifier), tostring(product.Name),  tostring(product.Price))

                product.Identifier = "unknown_" .. tostring(math.random(1, 100000))
            end
        end
        product.CategoryIdentifier = category.Identifier
    end
end

ps.ValidateConfig()

return ps
