local cargo = {}
Traitormod.Cargo = cargo
local config, ps = Traitormod.Config.Cargo, Traitormod.Pointshop
local json, prompts = require("json"), require("textpromptutils")
local sessions = {}

function cargo.Validate(client, item, allowUnselected)
    return cargo.State ~= nil and Game.RoundStarted
        and client ~= nil and client.Character ~= nil and client.Character.IsHuman
        and not client.Character.IsDead and not client.Character.IsIncapacitated
        and item ~= nil and not item.Removed and item.Prefab.Identifier == "vt_cargo_console"
        and (allowUnselected == true or client.Character.SelectedItem == item) and item.CanClientAccess(client)
end

function cargo.CanManage(client)
    for slot = 0, client.Character.Inventory.Capacity - 1 do
        local card = client.Character.Inventory.GetItemAt(slot)
        if card ~= nil and card.GetComponentString("IdCard") ~= nil and card.HasTag(config.AccessTag) then return true end
    end
    return false
end

function cargo.Start()
    sessions = {}
    local state = { Budget = config.Budget, Reserved = 0, Orders = {}, NextOrderId = 0, Products = {}, Used = {}, Packages = {}, Elapsed = 0, Time = 0 }
    cargo.State = state
    for _, categoryId in ipairs(config.Categories) do
        local category = ps.AllCategories[categoryId]
        if category ~= nil then
            for index, product in ipairs(category.Products) do
                if product.Items ~= nil and #product.Items > 0 then
                    local valid = true
                    for _, entry in ipairs(product.Items) do
                        local id = type(entry) == "string" and entry or entry.Identifier
                        if ItemPrefab.GetItemPrefab(id) == nil then
                            valid = false
                            break
                        end
                    end
                    if valid then state.Products[#state.Products + 1] = { Id = categoryId .. ":" .. index, Category = category, Product = product } end
                end
            end
        end
    end
    local home, submarine, port, helm
    for item in Item.ItemList do
        if item.HasTag("vt_cargo_helm") then
            submarine = item.Submarine
            helm = item.GetComponentString("Steering")
        end
        if item.HasTag("vt_cargo_home") and item.Submarine == Submarine.MainSub then home = item.GetComponentString("DockingPort") end
    end
    if submarine == nil then return end
    local ship = { Submarine = submarine, Home = home, Helm = helm, Crates = {}, Markers = {}, Fixed = {}, State = "Home", LastSale = 0 }
    for item in Item.ItemList do
        if item.Submarine == submarine then
            if item.HasTag("vt_cargo_port") then port = item.GetComponentString("DockingPort") end
            if item.HasTag("vt_cargo_crate") and item.OwnInventory ~= nil then ship.Crates[#ship.Crates + 1] = item end
            if item.HasTag("vt_cargo_large") then ship.Markers[#ship.Markers + 1] = item end
            if item.ParentInventory == nil or item.HasTag("vt_cargo_crate") then ship.Fixed[item] = true end
        end
    end
    table.sort(ship.Crates, function(a, b) return a.ID < b.ID end)
    table.sort(ship.Markers, function(a, b) return a.ID < b.ID end)
    ship.Port = port
    state.Ship = ship
end

function cargo.Capacity()
    local ship = cargo.State.Ship
    local slots, markers, total = {}, {}, 0
    if ship == nil then return slots, markers, total end
    for _, crate in ipairs(ship.Crates) do
        if not crate.Removed and crate.Submarine == ship.Submarine then
            local inventory = crate.OwnInventory
            total = total + inventory.Capacity
            for slot = 0, inventory.Capacity - 1 do
                if inventory.GetItemAt(slot) == nil then
                    slots[#slots + 1] = { Container = crate, Inventory = inventory, Slot = slot, Position = crate.WorldPosition, Submarine = ship.Submarine }
                end
            end
        end
    end
    for _, marker in ipairs(ship.Markers) do
        if not marker.Removed then
            local occupied = false
            for item in Item.ItemList do
                if item.Submarine == ship.Submarine and item.ParentInventory == nil and not ship.Fixed[item]
                    and math.abs(item.WorldPosition.X - marker.WorldPosition.X) < config.LargeAreaSize / 2
                    and math.abs(item.WorldPosition.Y - marker.WorldPosition.Y) < config.LargeAreaSize / 2 then occupied = true break end
            end
            if not occupied then markers[#markers + 1] = { Position = marker.WorldPosition, Submarine = ship.Submarine } end
        end
    end
    return slots, markers, total
end

function cargo.SaleGoods()
    local ship, goods = cargo.State.Ship, {}
    if ship == nil then return goods, 0 end
    local candidates = {}
    for _, crate in ipairs(ship.Crates) do
        if not crate.Removed and crate.Submarine == ship.Submarine then
            for item in crate.OwnInventory.AllItems do candidates[item] = true end
        end
    end
    for item in Item.ItemList do
        if item.Submarine == ship.Submarine and item.ParentInventory == nil and not ship.Fixed[item] then
            for _, marker in ipairs(ship.Markers) do
                if not marker.Removed and math.abs(item.WorldPosition.X - marker.WorldPosition.X) < config.LargeAreaSize / 2
                    and math.abs(item.WorldPosition.Y - marker.WorldPosition.Y) < config.LargeAreaSize / 2 then candidates[item] = true break end
            end
        end
    end
    local value = 0
    for item in pairs(candidates) do
        -- containers are sold only when empty, so unpriced contents are never deleted
        local empty = item.OwnInventory == nil or item.OwnInventory.IsEmpty()
        local package = cargo.State.Packages[item]
        local price = package ~= nil and ItemPrefab.GetItemPrefab(package.Definition.Identifier).DefaultPrice or item.Prefab.DefaultPrice
        local identifier = package ~= nil and package.Definition.Identifier or item.Prefab.Identifier.Value
        if not item.Removed and not ship.Fixed[item] and empty and price ~= nil
            and not config.SaleExcluded[identifier] then
            local amount = math.floor(price.Price * config.SaleMultiplier * item.ConditionPercentage / 100)
            if amount > 0 then
                goods[#goods + 1] = { Item = item, Price = amount }
                value = value + amount
            end
        end
    end
    return goods, value
end

function cargo.ShipSnapshot()
    local ship = cargo.State.Ship
    local slots, markers, total = cargo.Capacity()
    local _, sales = cargo.SaleGoods()
    return { State = ship ~= nil and ship.State or "NoShip", SlotsFree = #slots, SlotsTotal = total,
        LargeFree = #markers, LargeTotal = ship ~= nil and #ship.Markers or 0, SalesValue = sales, LastSale = ship ~= nil and ship.LastSale or 0 }
end

function cargo.Snapshot(client, shipSnapshot, incremental)
    local state = cargo.State
    local snapshot = { Orders = state.Orders, Budget = state.Budget, Reserved = state.Reserved, CanManage = cargo.CanManage(client), Text = {} }
    for _, key in ipairs({ "Title", "Close", "Budget", "Reserved", "Reason", "Submit", "Approve", "Reject", "Orders", "Quantity", "Pending", "Accepted", "Outbound", "Loaded", "Delivered", "Rejected", "Capacity", "Large", "LastSale", "Ship", "Sales", "NoShip", "Empty", "Search", "Cart", "Home", "Trading", "Returning", "Catalog", "Back", "Next", "Refresh", "NativeActions", "Choose", "Submitted", "Denied", "NoFunds", "NoStock", "LoadFailed" }) do
        snapshot.Text[key] = Traitormod.GetText("Cargo" .. key)
    end
    if incremental then
        snapshot.ProductStates = {}
        for _, entry in ipairs(state.Products) do
            local stock = math.max(0, (entry.Product.Limit or 99999) - (state.Used[entry.Id] or 0))
            snapshot.ProductStates[#snapshot.ProductStates + 1] = { Id = entry.Id,
                Price = ps.GetProductPrice(client, entry.Product), Stock = stock, MaxQuantity = math.min(stock, config.MaxQuantity) }
        end
    else
        snapshot.Products = {}
        for _, entry in ipairs(state.Products) do
            local record = ps.GetGuiProduct(client, entry.Category, entry.Product, entry.Id)
            record.Currency = "кр"
            record.Stock = math.max(0, (entry.Product.Limit or 99999) - (state.Used[entry.Id] or 0))
            record.Limit, record.MaxQuantity = entry.Product.Limit or 99999, math.min(record.Stock, config.MaxQuantity)
            record.DisabledReason, record.CooldownRemaining, record.CloseAfterPurchase = "", 0, false
            record.AllowQuantity = true
            snapshot.Products[#snapshot.Products + 1] = record
        end
    end
    snapshot.Ship = shipSnapshot or cargo.ShipSnapshot()
    return snapshot
end

function cargo.Submit(client, payload)
    local state, entries = cargo.State, {}
    local active = 0
    for _, order in ipairs(state.Orders) do
        if order.Status ~= "Delivered" and order.Status ~= "Rejected" then
            active = active + 1
        end
    end
    if type(payload.Entries) ~= "table" or #payload.Entries == 0 or #payload.Entries + active > config.MaxOrders
        or type(payload.Reason) ~= "string" or #payload.Reason > 384 or payload.Reason:find("%c") or not payload.Reason:find("%S") then return false, "CargoDenied" end
    local quantities = {}
    for _, request in ipairs(payload.Entries) do
        if type(request) ~= "table" then return false, "CargoDenied" end
        local entry
        for _, product in ipairs(state.Products) do
            if product.Id == request.Id then
                entry = product
                break
            end
        end
        if entry == nil or type(request.Quantity) ~= "number" or request.Quantity < 1
            or request.Quantity ~= math.floor(request.Quantity) or request.Quantity > config.MaxQuantity then return false, "CargoDenied" end
        local product = entry.Product
        quantities[entry.Id] = (quantities[entry.Id] or 0) + request.Quantity
        if quantities[entry.Id] + (state.Used[entry.Id] or 0) > (product.Limit or 99999) then return false, "CargoNoStock" end
        if product.CanBuy ~= nil and not product.CanBuy(client, product) then return false, "CargoDenied" end
        local record = ps.GetGuiProduct(client, entry.Category, product, entry.Id)
        entries[#entries + 1] = { Id = state.NextOrderId + #entries + 1, Product = entry.Id, Name = record.Name, IconIdentifier = record.IconIdentifier,
            Quantity = request.Quantity, Price = record.Price * request.Quantity, Reason = payload.Reason, Author = client.Name, Status = "Pending" }
    end
    for index = #state.Orders, 1, -1 do
        local order = state.Orders[index]
        if #state.Orders + #entries > config.MaxOrders and (order.Status == "Delivered" or order.Status == "Rejected") then table.remove(state.Orders, index) end
    end
    for _, order in ipairs(entries) do state.Orders[#state.Orders + 1] = order end
    state.NextOrderId = state.NextOrderId + #entries
    return true, "CargoSubmitted"
end

function cargo.FindOrder(id)
    for _, order in ipairs(cargo.State.Orders) do if order.Id == id then return order end end
end

function cargo.Decide(client, action, id)
    if not cargo.CanManage(client) then return false, "CargoDenied" end
    local state, order = cargo.State, cargo.FindOrder(id)
    if order == nil or (order.Status ~= "Pending" and order.Status ~= "Accepted") then return false, "CargoDenied" end
    if action == "reject" then
        if order.Status == "Accepted" then
            state.Reserved = state.Reserved - order.Price
            state.Used[order.Product] = state.Used[order.Product] - order.Quantity
        end
        order.Status = "Rejected"
        return true
    end
    if order.Status ~= "Pending" then return false, "CargoDenied" end
    local product
    for _, entry in ipairs(state.Products) do if entry.Id == order.Product then product = entry.Product break end end
    if order.Price > state.Budget - state.Reserved then return false, "CargoNoFunds" end
    if (state.Used[order.Product] or 0) + order.Quantity > (product.Limit or 99999) then return false, "CargoNoStock" end
    state.Reserved = state.Reserved + order.Price
    state.Used[order.Product] = (state.Used[order.Product] or 0) + order.Quantity
    order.Status = "Accepted"
    order.Manager = client
    return true
end

function cargo.LoadNext()
    local state, ship = cargo.State, cargo.State.Ship
    if ship.Loading then return end
    local order = ship.Trip[ship.NextOrder]
    if order == nil then
        ship.State, ship.Trading, ship.Trip = "Returning", false, nil
        state.Dirty = true
        return
    end
    local product
    for _, entry in ipairs(state.Products) do if entry.Id == order.Product then product = entry.Product break end end
    local items = {}
    for _ = 1, order.Quantity do
        local bundle = product.Items
        if product.ItemRandom then bundle = { bundle[math.random(#bundle)] } end
        for _, entry in ipairs(bundle) do items[#items + 1] = type(entry) == "string" and { Identifier = entry } or entry end
    end
    local slots, markers = cargo.Capacity()
    local destinations = {}
    for index, item in ipairs(items) do
        local prefab = ItemPrefab.GetItemPrefab(item.Identifier)
        if prefab == nil then
            order.Status = "Accepted"
            ship.NextOrder = ship.NextOrder + 1
            state.Dirty = true
            return
        end
        if item.IsInstallation then
            if #markers == 0 then
                order.Status = "Accepted"
                ship.NextOrder = ship.NextOrder + 1
                state.Dirty = true
                return
            end
            destinations[index] = table.remove(markers, 1)
        else
            local found
            for slotIndex, destination in ipairs(slots) do
                if destination.Inventory.CanBePutInSlot(prefab, destination.Slot, item.Condition or item.MaxCondition) then
                    found = slotIndex
                    break
                end
            end
            if found ~= nil then destinations[index] = table.remove(slots, found)
            elseif #markers > 0 then destinations[index] = table.remove(markers, 1)
            else order.Status = "Accepted" ship.NextOrder = ship.NextOrder + 1 state.Dirty = true return end
        end
    end
    ship.Loading = true
    local shipment, waiting = {}, 0
    for index, item in ipairs(items) do
        if item.IsInstallation then
            shipment[index] = { Identifier = "vt_cargo_package", Condition = item.Condition or item.MaxCondition }
            waiting = waiting + 1
        else shipment[index] = item end
    end
    local activation = product
    if waiting > 0 then
        activation = {}
        for key, value in pairs(product) do if key ~= "Action" then activation[key] = value end end
    end
    ps.ActivateProduct(order.Manager, activation, order.Price, shipment, destinations, function(success, spawned)
        if cargo.State ~= state then return end
        if success then
            local batch = { Product = product, Manager = order.Manager, Price = order.Price, Items = spawned, Waiting = waiting }
            for index, definition in ipairs(items) do
                if definition.IsInstallation then
                    local package = spawned[index]
                    state.Packages[package] = { Definition = definition, Batch = batch, Index = index }
                    package.Description = Traitormod.FormatText("CargoPackageContents", ItemPrefab.GetItemPrefab(definition.Identifier).Name.Value)
                end
            end
            state.Budget, state.Reserved = state.Budget - order.Price, state.Reserved - order.Price
            order.Status = "Loaded"
        else
            for _, item in ipairs(spawned) do if not item.Removed then Entity.Spawner.AddEntityToRemoveQueue(item) end end
            order.Status = "Accepted"
        end
        state.Dirty = true
        ship.Loading, ship.NextOrder = false, ship.NextOrder + 1
        if success then order.Manager = nil end
    end)
end

function cargo.ResolvePackage(item, replacement, client)
    local package = cargo.State.Packages[item]
    if package == nil then return end
    local batch = package.Batch
    batch.Items[package.Index], batch.Waiting = replacement or false, batch.Waiting - 1
    cargo.State.Packages[item] = nil
    if batch.Waiting == 0 and batch.Product.Action ~= nil then
        local items = {}
        for _, obj in ipairs(batch.Items) do if obj and not obj.Removed then items[#items + 1] = obj end end
        if #items > 0 then
            local success, reason = ps.RunProductAction(client or batch.Manager, batch.Product, items, batch.Price)
            if not success then Traitormod.SendMessage(client or batch.Manager, reason or Traitormod.Language.PointshopCannotBeUsed) end
        end
    end
end

function cargo.Unpack(client, item)
    local state = cargo.State
    local package = state ~= nil and state.Packages[item] or nil
    if package == nil or package.Unpacking or not Game.RoundStarted
        or item.Removed or client.Character == nil or not client.Character.IsHuman or client.Character.IsDead
        or client.Character.IsIncapacitated or client.Character.SelectedItem ~= item or not item.CanClientAccess(client)
        or client.Character.Submarine ~= Submarine.MainSub then return false end
    package.Unpacking = true
    local position = client.Character.AnimController.GetLimb(LimbType.Torso).WorldPosition
    ps.SpawnItem(client, package.Definition, function(spawned)
        if cargo.State ~= state then return end
        cargo.ResolvePackage(item, spawned, client)
        Entity.Spawner.AddEntityToRemoveQueue(item)
    end, { Position = position, Submarine = Submarine.MainSub })
    return true
end

local function navigateHome(ship)
    local port, home, helm = ship.Port, ship.Home, ship.Helm
    if home == nil or home.Item.Removed or home.Docked and home.DockingTarget ~= port then return end
    if port.Docked then return end

    local berth = home.Item.WorldPosition - (port.Item.WorldPosition - ship.Submarine.WorldPosition)
        - Vector2(0, port.GetDir(home) * port.DockedDistance * port.Item.Scale)
    local approach = berth - Vector2(0, ship.Submarine.Borders.Height)
    local position = ship.Submarine.WorldPosition
    if not ship.DockApproach then
        if math.abs(position.X - approach.X) < ship.Submarine.Borders.Width * 4
            and Vector2.Distance(position, approach) < ship.Submarine.Borders.Width * 4 then
            ship.DockApproach = true
            helm.PosToMaintain = approach
            helm.MaintainPos = true
            helm.UnsentChanges = true
        end
    elseif not ship.AtBerth and Vector2.Distance(position, approach) < 200 then
        ship.AtBerth = true
        helm.PosToMaintain = berth
        helm.UnsentChanges = true
    elseif ship.AtBerth then
        local delta = home.Item.WorldPosition - port.Item.WorldPosition
        local tolerance = port.DistanceTolerance
        if math.abs(delta.X) <= tolerance.X and math.abs(delta.Y) <= tolerance.Y
            and ship.Submarine.Velocity.Length() < 0.6 then
            port.Dock(home)
        end
    end
end

function cargo.Think(deltaTime)
    local state = cargo.State
    if state == nil or not Game.RoundStarted then return end
    state.Time = state.Time + deltaTime
    state.Elapsed = state.Elapsed + deltaTime
    if state.Elapsed < 0.5 then return end
    state.Elapsed = 0
    for index = #state.Orders, 1, -1 do
        local order = state.Orders[index]
        if order.Status == "Delivered" and order.DeliveredAt ~= nil and state.Time - order.DeliveredAt >= config.DeliveredHistorySeconds then
            table.remove(state.Orders, index)
            state.Dirty = true
        end
    end
    if state.Dirty then
        state.Dirty = false
        local shipSnapshot
        for client, session in pairs(sessions) do
            if session.Gui then
                shipSnapshot = shipSnapshot or cargo.ShipSnapshot()
                cargo.Send(client, nil, shipSnapshot)
            end
        end
    end
    local lost = {}
    for item in pairs(state.Packages) do
        if item.Removed then lost[#lost + 1] = item end
    end
    for _, item in ipairs(lost) do cargo.ResolvePackage(item) end
    local ship = state.Ship
    if ship == nil or ship.Submarine.Removed or ship.Port == nil then return end
    local home = ship.Port.Docked and ship.Port.IsLocked and ship.Port.DockingTarget == ship.Home
    if home then
        if ship.Loading then return end
        for _, order in ipairs(state.Orders) do
            if order.Status == "Loaded" then
                order.Status, order.DeliveredAt = "Delivered", state.Time
                state.Dirty = true
            elseif order.Status == "Outbound" then order.Status = "Accepted" state.Dirty = true end
        end
        if ship.State ~= "Home" then state.Dirty = true end
        ship.State, ship.Trip, ship.Trading, ship.Sales = "Home", nil, false, nil
        ship.DockApproach, ship.AtBerth, ship.DockedAt = nil, nil, nil
        return
    end
    if ship.State == "Home" then
        ship.State, ship.Trip, ship.NextOrder = "Outbound", {}, 1
        state.Dirty = true
        for _, order in ipairs(state.Orders) do
            if order.Status == "Accepted" then order.Status = "Outbound" ship.Trip[#ship.Trip + 1] = order end
        end
    end
    local outpost = Level.Loaded ~= nil and Level.Loaded.EndOutpost or nil
    local arrived = outpost ~= nil and ship.Port.Docked and ship.Port.IsLocked
        and ship.Port.DockingTarget ~= nil and ship.Port.DockingTarget.Item.Submarine == outpost
    if ship.State == "Outbound" and arrived then
        ship.State, ship.Trading, ship.Sales = "Trading", true, cargo.SaleGoods()
        ship.DockedAt = state.Time
        state.Dirty = true
        for _, sale in ipairs(ship.Sales) do Entity.Spawner.AddEntityToRemoveQueue(sale.Item) end
    end
    if ship.Trading then
        if ship.Sales ~= nil then
            for _, sale in ipairs(ship.Sales) do
                if not sale.Item.Removed then return end
            end
            ship.LastSale = 0
            for _, sale in ipairs(ship.Sales) do
                ship.LastSale = ship.LastSale + sale.Price
                cargo.ResolvePackage(sale.Item)
            end
            state.Budget = state.Budget + ship.LastSale
            state.Dirty = true
            ship.Sales = nil
        end
        if arrived then cargo.LoadNext() end
    end
    if ship.State == "Returning" then
        if arrived then
            if state.Time - ship.DockedAt >= 10 then
                ship.Port.Undock(false)
                ship.Helm.SetDestinationLevelStart()
                ship.Helm.UnsentChanges = true
            end
        else
            navigateHome(ship)
        end
    end
end

function cargo.Send(client, result, shipSnapshot)
    local session = sessions[client]
    if session == nil or not cargo.Validate(client, session.Item, session.Gui) then return end
    local snapshot = cargo.Snapshot(client, shipSnapshot, session.Gui and session.CatalogSent)
    snapshot.Result = result
    if result ~= nil and result.Action == "submit" then snapshot.SubmitAccepted = result.Success end
    if session.Gui then
        local message = Networking.Start("VoidTraitor_CargoSnapshot")
        message.WriteUInt16(UShort(session.Item.ID))
        -- Manager is a server-side reference, it is not sent
        local orders = {}
        for _, order in ipairs(snapshot.Orders) do
            local entry = {}
            for key, value in pairs(order) do if key ~= "Manager" then entry[key] = value end end
            orders[#orders + 1] = entry
        end
        snapshot.Orders = orders
        message.WriteString(json.encode(snapshot))
        Networking.Send(message, client.Connection, DeliveryMethod.Reliable)
        session.CatalogSent = true
        return
    end
    local text = snapshot.Text
    local lines = { text.Budget .. ": " .. snapshot.Budget .. " / " .. text.Reserved .. ": " .. snapshot.Reserved,
        text.Ship .. ": " .. (text[snapshot.Ship.State] or snapshot.Ship.State),
        text.Capacity .. ": " .. snapshot.Ship.SlotsFree .. "/" .. snapshot.Ship.SlotsTotal .. " + " .. snapshot.Ship.LargeFree .. "/" .. snapshot.Ship.LargeTotal,
        text.Sales .. ": " .. snapshot.Ship.SalesValue }
    local buttons = {}
    if session.View == "catalog" then
        for index = (session.Page - 1) * 8 + 1, math.min(session.Page * 8, #snapshot.Products) do
            local product = snapshot.Products[index]
            buttons[#buttons + 1] = { Label = product.Name .. " — " .. product.Price .. " кр", Action = "product", Payload = { Id = product.Id } }
        end
        if session.Page * 8 < #snapshot.Products then buttons[#buttons + 1] = { Label = text.Next, Action = "page", Payload = { Page = session.Page + 1 } } end
        if session.Page > 1 then buttons[#buttons + 1] = { Label = text.Back, Action = "page", Payload = { Page = session.Page - 1 } } end
    elseif session.View == "order" then
        local order = cargo.FindOrder(session.Order)
        if order ~= nil then
            lines[#lines + 1] = order.Name .. " ×" .. order.Quantity .. " — " .. order.Price .. " кр\n" .. order.Author .. ": " .. order.Reason .. "\n" .. (text[order.Status] or order.Status)
            if snapshot.CanManage and (order.Status == "Pending" or order.Status == "Accepted") then
                if order.Status == "Pending" then buttons[#buttons + 1] = { Label = text.Approve, Action = "approve", Payload = { OrderId = order.Id } } end
                buttons[#buttons + 1] = { Label = text.Reject, Action = "reject", Payload = { OrderId = order.Id } }
            end
        end
    else
        buttons[#buttons + 1] = { Label = text.Catalog, Action = "view", Payload = { View = "catalog" } }
        for index = (session.Page - 1) * 8 + 1, math.min(session.Page * 8, #snapshot.Orders) do
            local order = snapshot.Orders[index]
            buttons[#buttons + 1] = { Label = "#" .. order.Id .. " " .. order.Name .. " ×" .. order.Quantity .. " — " .. order.Price .. " кр (" .. (text[order.Status] or order.Status) .. ")", Action = "order", Payload = { OrderId = order.Id } }
        end
        if session.Page * 8 < #snapshot.Orders then buttons[#buttons + 1] = { Label = text.Next, Action = "page", Payload = { Page = session.Page + 1 } } end
        if session.Page > 1 then buttons[#buttons + 1] = { Label = text.Back, Action = "page", Payload = { Page = session.Page - 1 } } end
    end
    if session.Product ~= nil then
        for _, product in ipairs(snapshot.Products) do
            if product.Id == session.Product then lines[#lines + 1] = text.Choose .. ": " .. product.Name .. "\n" .. product.Description .. "\n" .. product.Price .. " кр / " .. product.Stock end
        end
    end
    lines[#lines + 1] = text.NativeActions
    local terminal = session.Item.GetComponentString("Terminal")
    local body = table.concat(lines, "\n\n")
    if terminal.ShowMessage ~= body then
        terminal.ShowMessage = body
        terminal.SyncHistory()
    end
    buttons[#buttons + 1] = { Label = text.Refresh, Action = "view", Payload = { View = "main" } }
    buttons[#buttons + 1] = { Label = text.Close, Action = "close", Payload = {} }
    local options = {}
    for _, button in ipairs(buttons) do options[#options + 1] = button.Label end
    local prompt = {}
    session.Prompt = prompt
    prompts.Prompt(text.Title, options, client, function(index, response)
        if response ~= client or sessions[client] ~= session or session.Prompt ~= prompt then return end
        local button = buttons[index]
        if button ~= nil then cargo.Action(client, session.Item, button.Action, button.Payload) end
    end, "InfoFrameTabButton.Mission")
end

function cargo.Open(client, item, gui)
    if not cargo.Validate(client, item, gui == true) then return false end
    sessions[client] = { Item = item, Gui = gui == true, View = "main", Page = 1 }
    cargo.Send(client)
    return true
end

function cargo.Action(client, item, action, payload)
    local session = sessions[client]
    if session == nil or session.Item ~= item then return false end
    if action == "close" then
        if session.Gui then sessions[client] = nil else session.Prompt = nil end
        return true
    end
    if not cargo.Validate(client, item, session.Gui) then return false end
    local success, reason = true, nil
    if action == "submit" then success, reason = cargo.Submit(client, payload)
    elseif action == "approve" or action == "reject" then success, reason = cargo.Decide(client, action, payload.OrderId)
    elseif action == "view" and (payload.View == "main" or payload.View == "catalog") then session.View, session.Page = payload.View, 1
    elseif action == "page" and type(payload.Page) == "number" and payload.Page == math.floor(payload.Page) and payload.Page >= 1
        and payload.Page <= math.ceil((session.View == "catalog" and #cargo.State.Products or #cargo.State.Orders) / 8) then session.Page = payload.Page
    elseif action == "product" then
        for _, entry in ipairs(cargo.State.Products) do if entry.Id == payload.Id then session.Product, session.View = payload.Id, "main" break end end
    elseif action == "order" and cargo.FindOrder(payload.OrderId) ~= nil then session.Order, session.View = payload.OrderId, "order"
    elseif action ~= "refresh" then return false end
    if reason ~= nil then Traitormod.SendChatMessage(client, Traitormod.GetText(reason)) end
    cargo.Send(client, { Action = action, Success = success, Message = reason ~= nil and Traitormod.GetText(reason) or "" })
    if success and (action == "submit" or action == "approve" or action == "reject") then
        local shipSnapshot
        for other, otherSession in pairs(sessions) do
            if other ~= client and otherSession.Gui then
                shipSnapshot = shipSnapshot or cargo.ShipSnapshot()
                cargo.Send(other, nil, shipSnapshot)
            end
        end
    end
    return success
end

Networking.Receive("VoidTraitor_CargoOpen", function(message, client) cargo.Open(client, Entity.FindEntityByID(message.ReadUInt16()), true) end)
Networking.Receive("VoidTraitor_CargoAction", function(message, client)
    local item, action, text = Entity.FindEntityByID(message.ReadUInt16()), message.ReadString(), message.ReadString()
    if #action > 24 or #text > 8192 then return end
    local ok, payload = pcall(json.decode, text)
    if ok and type(payload) == "table" then cargo.Action(client, item, action, payload) end
end)

Hook.Patch("Traitormod.Cargo.Native", "Barotrauma.Items.Components.CustomInterface", "ServerEventRead", function(instance, parameters)
    local item, client, message = instance.Item, parameters["c"], parameters["msg"]
    if item.Prefab.Identifier == "vt_cargo_package" then
        local unpack = message.ReadBoolean()
        parameters.PreventExecution = true
        if unpack and not cargo.Unpack(client, item) then Traitormod.SendChatMessage(client, Traitormod.GetText("CargoUnpackDenied")) end
        return
    end
    if item.Prefab.Identifier ~= "vt_cargo_console" then return end
    local quantity, reason, menu, submit = message.ReadString(), message.ReadString(), message.ReadBoolean(), message.ReadBoolean()
    parameters.PreventExecution = true
    if not cargo.Validate(client, item) then return end
    if menu then cargo.Open(client, item, false)
    elseif submit then
        local session = sessions[client]
        if session ~= nil and session.Item == item and session.Product ~= nil then
            cargo.Action(client, item, "submit", { Entries = { { Id = session.Product, Quantity = tonumber(quantity) } }, Reason = reason })
        end
    end
end, Hook.HookMethodType.Before)

Hook.Add("think", "Traitormod.Cargo.Think", cargo.Think)
Hook.Add("roundEnd", "Traitormod.Cargo.End", function() cargo.State, sessions = nil, {} end)
Hook.Add("client.disconnected", "Traitormod.Cargo.Disconnect", function(client) sessions[client] = nil end)
return cargo
