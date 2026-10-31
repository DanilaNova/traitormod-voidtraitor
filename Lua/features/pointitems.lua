LuaUserData.MakeMethodAccessible(Descriptors["Barotrauma.Item"], "set_InventoryIconColor")

Traitormod.PointItems = {}

local function setupPointItem(item, amount, text, onUsed)
    text = text or ""

    Traitormod.PointItems[item] = {}
    Traitormod.PointItems[item].Amount = amount
    Traitormod.PointItems[item].OnUsed = onUsed

    local terminal = item.GetComponentString("Terminal")
    terminal.ShowMessage = text .. "\n" .. Traitormod.FormatText("PointItemTerminalText", amount)
    terminal.SyncHistory()

    item.set_InventoryIconColor(Color(0, 0, 255))
    item.SpriteColor = Color(0, 0, 255, 255)
    item.Scale = 0.5

    local color = item.SerializableProperties[Identifier("SpriteColor")]
    Networking.CreateEntityEvent(item, Item.ChangePropertyEventData(color, item))

    local scale = item.SerializableProperties[Identifier("Scale")]
    Networking.CreateEntityEvent(item, Item.ChangePropertyEventData(scale, item))

    local invColor = item.SerializableProperties[Identifier("InventoryIconColor")]
    Networking.CreateEntityEvent(item, Item.ChangePropertyEventData(invColor, item))
end

Traitormod.SpawnPointItem = function(inventory, amount, text, onSpawn, onUsed)
    local prefab = ItemPrefab.GetItemPrefab("handheldterminal")
    if prefab == nil then return false end

    Entity.Spawner.AddItemToSpawnQueue(prefab, inventory, nil, nil, function(item)
        setupPointItem(item, amount, text, onUsed)
        if onSpawn then
            onSpawn(item)
        end
    end)

    return true
end

Traitormod.DropPointItem = function(client, amount)
    if Traitormod.IsRoundFinalizing() or client == nil or client.Character == nil or client.Character.IsDead then
        return false
    end

    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end

    local currentPoints = math.floor(tonumber(Traitormod.GetData(client, "Points") or 0) or 0)
    if currentPoints < amount then return false end

    local prefab = ItemPrefab.GetItemPrefab("handheldterminal")
    if prefab == nil then return false end

    local character = client.Character
    local position = character.WorldPosition

    local ok = pcall(function()
        Entity.Spawner.AddItemToSpawnQueue(prefab, position, nil, nil, function(item)
            local latestPoints = math.floor(tonumber(Traitormod.GetData(client, "Points") or 0) or 0)
            if latestPoints < amount then
                pcall(function() item.Remove() end)
                return
            end

            setupPointItem(item, amount, "", nil)
            if not Traitormod.Config.TestMode then
                Traitormod.SetData(client, "Points", latestPoints - amount)
            end
            Traitormod.SendMessage(client, Traitormod.FormatText("CMDDropPointsDropped", amount))
        end)
    end)

    return ok
end

Hook.Add("traitormod.terminalWrite", "Traitormod.PointItem", function (item, client, output)
    if string.lower(tostring(output or "")) ~= Traitormod.GetText("PointItemClaimCommand") then return end

    local data = Traitormod.PointItems[item]

    if data == nil then return end

    if Traitormod.IsRoundFinalizing() then
        Traitormod.SendMessage(client, Traitormod.GetText("PointItemClaimUnavailable"))
        return
    end

    Traitormod.AwardPoints(client, data.Amount)
    Traitormod.SendMessage(client, Traitormod.FormatText("ReceivedPoints", data.Amount), "InfoFrameTabButton.Mission")

    if data.OnUsed then
        data.OnUsed(client)
    end

    local terminal = item.GetComponentString("Terminal")
    terminal.ShowMessage = Traitormod.FormatText("PointItemClaimedBy", client.Name)
    terminal.SyncHistory()

    Traitormod.PointItems[item] = nil
end)

