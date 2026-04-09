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

---@param client Barotrauma.Networking.Client
---@param product Pointshop.Product
---@return integer
ps.GetProductLimit = function (client, product)
    if product.IsLimitGlobal then
        if ps.GlobalProductLimits[product.Identifier] == nil then
            ps.GlobalProductLimits[product.Identifier] = product.Limit or defaultLimit
        end

        return ps.GlobalProductLimits[product.Identifier]
    else
        if ps.LocalProductLimits[client.SteamID] == nil then
            ps.LocalProductLimits[client.SteamID] = {}
        end

        local localProductLimit = ps.LocalProductLimits[client.SteamID]

        if localProductLimit[product.Identifier] == nil then
            localProductLimit[product.Identifier] = product.Limit or defaultLimit
        end

        return localProductLimit[product.Identifier]
    end
end

---@param client Barotrauma.Networking.Client
---@param product Pointshop.Product
---@param amount integer?
---@return boolean
ps.UseProductLimit = function (client, product, amount)
    amount = amount or 1

    if product.IsLimitGlobal then
        if ps.GlobalProductLimits[product.Identifier] == nil then
            ps.GlobalProductLimits[product.Identifier] = product.Limit or defaultLimit
        end

        if ps.GlobalProductLimits[product.Identifier] > 0 then
            ps.GlobalProductLimits[product.Identifier] = ps.GlobalProductLimits[product.Identifier] - amount
            return true
        else
            return false
        end
    else
        if ps.LocalProductLimits[client.SteamID] == nil then
            ps.LocalProductLimits[client.SteamID] = {}
        end

        local localProductLimit = ps.LocalProductLimits[client.SteamID]

        if localProductLimit[product.Identifier] == nil then
            localProductLimit[product.Identifier] = product.Limit or defaultLimit
        end

        if localProductLimit[product.Identifier] > 0 then
            localProductLimit[product.Identifier] = localProductLimit[product.Identifier] - amount
            return true
        else
            return false
        end
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
        local formatString = Traitormod.Language.PointshopSubcategorySlots or "%d/%d"
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
ps.ValidateClient = function(client)
    if not config.PointShopConfig.Enabled then
        Traitormod.SendMessage(client, Traitormod.Language.CommandNotActive)
        return false
    end

    if not client.InGame then
        Traitormod.SendMessage(client, Traitormod.Language.PointshopInGame)
        return false
    end

    return true
end

---@param client Barotrauma.Networking.Client
---@param item Pointshop.Item
---@param onSpawned fun(obj: Barotrauma.Item)
ps.SpawnItem = function(client, item, onSpawned)
    local prefab = ItemPrefab.GetItemPrefab(item.Identifier)
    local condition = item.Condition or item.MaxCondition

    if prefab == nil then
        Traitormod.SendMessage(client, "PointShop Error: Could not find item with identifier " .. item.Identifier .. " please report this error.")
        Traitormod.Error("PointShop Error: Could not find item with identifier " .. item.Identifier)
        return
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

        if onSpawned then onSpawned(item) end
    end

    if item.IsInstallation then
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
end

---@param client Barotrauma.Networking.Client
---@param product Pointshop.Product
---@param paidPrice integer
ps.ActivateProduct = function (client, product, paidPrice)
    local spawnedItems = {}
    local spawnedItemCount = 0

    local function OnSpawned(item)
        table.insert(spawnedItems, item)

        spawnedItemCount = spawnedItemCount + 1

        if spawnedItemCount == #product.Items and product.Action then
            product.Action(client, product, spawnedItems, paidPrice)
        end
    end

    if product.Items then
        if product.ItemRandom then
            local randomIndex = math.random(1, #product.Items)
            local item = product.Items[randomIndex]

            if type(item) == "string" then
                item = {Identifier = item}
            end

            ps.SpawnItem(client, item, OnSpawned)
        else
            for _, value in pairs(product.Items) do
                if type(value) == "string" then
                    value = {Identifier = value}
                end

                ps.SpawnItem(client, value, OnSpawned)
            end
        end
    end

    if (product.Items == nil or #product.Items == 0) and product.Action then
        local success, result = product.Action(client, product, nil, paidPrice)
        if success == false then
            return false, result
        end
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

    return product.Price + (product.Limit - ps.GetProductLimit(client, product)) * (product.PricePerLimit or 0) - mult
end

---@param client Barotrauma.Networking.Client
---@param product Pointshop.Product
---@return Pointshop.ProductBuyFailureReason?
ps.BuyProduct = function(client, product)
    local price = 0
    local points = nil
    local previousTimeout = nil

    if not ps.CanClientSeeProduct(client, product) then
        return Traitormod.Language.PointshopCannotBeUsed
    end

    if not Traitormod.Config.TestMode then
        points = Traitormod.GetData(client, "Points") or 0
        price = ps.GetProductPrice(client, product)

        if product.CanBuy then
            local success, result = product.CanBuy(client, product)
            if not success then
                return result or Traitormod.Language.PointshopCannotBeUsed
            end
        end

        if price > points then
            return ps.ProductBuyFailureReason.NoPoints
        end

        if product.Timeout ~= nil then
            previousTimeout = ps.Timeouts[client.SteamID]
            if ps.Timeouts[client.SteamID] ~= nil and Timer.GetTime() < ps.Timeouts[client.SteamID] then
                local time = math.ceil(ps.Timeouts[client.SteamID] - Timer.GetTime())
                return string.format(Traitormod.Language.PointshopWait, time)
            end

            ps.Timeouts[client.SteamID] = Timer.GetTime() + product.Timeout
        end

        if not ps.UseProductLimit(client, product) then
            return ps.ProductBuyFailureReason.NoStock
        end

        Traitormod.SetData(client, "Points", points - price)
    end

    -- Activate the product
    local success, result = ps.ActivateProduct(client, product, price)
    if success == false then
        if not Traitormod.Config.TestMode then
            Traitormod.SetData(client, "Points", points)
            ps.UseProductLimit(client, product, -1)

            if product.Timeout ~= nil then
                ps.Timeouts[client.SteamID] = previousTimeout
            end
        end

        return result or Traitormod.Language.PointshopCannotBeUsed
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

ps.TrackRefund = function (client, product, paidPrice)
    ps.Refunds[client] = { Product = product, Time = Timer.GetTime(), Price = paidPrice }
end

Traitormod.AddCommand({"!pointshop", "!pointsshop", "!ps", "!shop"}, function (client, args)
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

    ps.ShowCategory(client)

    return true
end)

Hook.Add("roundStart", "TraitormMod.PointShop.RoundStart", function ()
    for key, value in pairs(Client.ClientList) do
        ps.Timeouts[value.SteamID] = Timer.GetTime() + 300
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

Hook.Add("roundEnd", "TraitorMod.PointShop.RoundEnd", function ()
    ps.ResetProductLimits()
    ps.ActiveCategories = {}

    if Traitormod.Config.TestMode then return end
    if config.PointShopConfig.DeathSpawnRefundAtEndRound then
        for client, refundTable in pairs(ps.Refunds) do
            if client.Character ~= nil and not client.Character.IsPet then -- client.Character is surely alive
                -- it will also remove elements in the ps.Refunds
                refundTable.Price = refundTable.Price * math.min(client.Character.Vitality / client.Character.MaxVitality, 1)
                refundProduct(client, refundTable)
            end
        end
    end 
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
        ps.Timeouts[client.SteamID] = Timer.GetTime() + config.PointShopConfig.DeathTimeoutTime
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
    end
end

ps.ValidateConfig()

return ps
