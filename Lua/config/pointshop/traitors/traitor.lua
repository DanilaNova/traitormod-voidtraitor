local category = {}

category.Identifier = "traitor"
category.Decoration = "clown"
category.FadeToBlack = true

category.CanAccess = function(client)
    return client.Character and not client.Character.IsDead and Traitormod.RoleManager.HasRole(client.Character, "Traitor")
end

category.Init = function ()
    Hook.Patch("Barotrauma.Items.Components.Projectile", "HandleProjectileCollision", function (instance, ptable)
        local target = ptable["target"]

        if not instance.Launcher then return end
        if not instance.Launcher.HasTag("teleporter") then return end
        if instance.User == nil then return end
        if target == nil then return end
        if target.Body == nil then return end

        if tostring(target.Body.UserData) == "Barotrauma.Limb" then
            local character = target.Body.UserData.character

            local oldPosition = instance.User.WorldPosition
            instance.User.TeleportTo(character.WorldPosition)
            character.TeleportTo(oldPosition)
        else
            instance.User.TeleportTo(instance.Item.WorldPosition)
        end
    end)

    Hook.Patch("Barotrauma.Items.Components.Wearable", "Equip", function(instance, ptable)
        if not instance.Item.HasTag("chocker") then return end
        if not instance.AllowedSlots[2] == InvSlotType.Head then return end

        -- For some reason speechImpediment doesnt work
        if ptable["character"] ~= nil then
            ptable["character"].CanSpeak = false
        end
    end, Hook.HookMethodType.After)

    Hook.Patch("Barotrauma.Items.Components.Wearable", "Unequip", function(instance, ptable)
        if not instance.Item.HasTag("chocker") then return end
        if not instance.AllowedSlots[2] == InvSlotType.Head then return end

        -- For some reason speechImpediment doesnt work
        if ptable["character"] ~= nil then
            ptable["character"].CanSpeak = true
        end
    end, Hook.HookMethodType.After) 

    Traitormod.AddCommand({"!freehandcuffs", "!freehandcuff", "!fhc"}, function (client, args)
        if client.Character == nil or client.Character.IsDead then
            Traitormod.SendMessage(client, "You are dead!")
            return true
        end
        if not client.Character.IsHuman then return true end

        local item = client.Character.Inventory.GetItemInLimbSlot(InvSlotType.RightHand)

        if item ~= nil and item.Prefab.Identifier == "handcuffs" then
            if not item.HasTag("fakehandcuffs") then
                Traitormod.SendMessage(client, "This handcuff is not fake!")
                return true
            end
            item.Drop(client.Character)
        end
        
        return true
    end)
end

category.Products = {
    {
        Identifier = "explosiveautoinjector",
        Price = 1100,
        Limit = 1,
        IsLimitGlobal = false,
        Action = function (client)
            local prefabInjector = ItemPrefab.GetItemPrefab("autoinjectorheadset")
            local prefabExplosive = ItemPrefab.GetItemPrefab("c4block")
            Entity.Spawner.AddItemToSpawnQueue(prefabInjector, client.Character.Inventory, nil, nil, function (item)
                Entity.Spawner.AddItemToSpawnQueue(prefabExplosive, client.Character.Inventory, nil, nil, function (item2)
                    item2.Tags = "syringe"
                    item2.Description = "A modified C-4 Block that can be put inside an Auto-Injector headset."
                    item2.set_InventoryIconColor(Color(0, 0, 255))
                    item2.SpriteColor = Color(0, 0, 255, 255)

                    local color = item2.SerializableProperties[Identifier("SpriteColor")]
                    Networking.CreateEntityEvent(item2, Item.ChangePropertyEventData(color, item2))            
                    local invColor = item2.SerializableProperties[Identifier("InventoryIconColor")]
                    Networking.CreateEntityEvent(item2, Item.ChangePropertyEventData(invColor, item2))
                end)
            end)
        end
    },

    {
        Identifier = "invisibilitygear",
        Price = 2650,
        Limit = 1,
        IsLimitGlobal = true,
        Items = {"artmod_clownclothhide"},
		Action = function ()
			local text = Traitormod.Language.InvisibilityTraitor
			Traitormod.RoundEvents.SendEventMessage(text, "GameModeIcon.PVP")
		end
    },

    {
        Identifier = "teleporterrevolver",
        Price = 1150,
        Limit = 1,
        IsLimitGlobal = false,
        Action = function (client)
            local revolver = ItemPrefab.GetItemPrefab("revolver")
            Entity.Spawner.AddItemToSpawnQueue(revolver, client.Character.Inventory, nil, nil, function (item)
                item.Tags = "teleporter"
                item.Description = "‖color:gui.red‖A special revolver with teleportation features...‖color:end‖"

                item.set_InventoryIconColor(Color(0, 0, 255, 255))
                item.SpriteColor = Color(0, 0, 255, 255)

                local color = item.SerializableProperties[Identifier("SpriteColor")]
                Networking.CreateEntityEvent(item, Item.ChangePropertyEventData(color, item))            
                local invColor = item.SerializableProperties[Identifier("InventoryIconColor")]
                Networking.CreateEntityEvent(item, Item.ChangePropertyEventData(invColor, item))

                for i = 1, 6, 1 do
                    Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.GetItemPrefab("revolverround"), item.OwnInventory)
                end
            end)
        end
    },

    {
        Identifier = "choke",
        Price = 375,
        Limit = 1,
        IsLimitGlobal = false,
        Action = function (client)
            local revolver = ItemPrefab.GetItemPrefab("ironhelmet")
            Entity.Spawner.AddItemToSpawnQueue(revolver, client.Character.Inventory, nil, nil, function (item)
                item.Tags = "chocker"
                item.Description = Traitormod.Language.Pointshop.choke_desc

                item.set_InventoryIconColor(Color(255, 0, 0, 50))
                item.SpriteColor = Color(255, 0, 0, 50)

                local color = item.SerializableProperties[Identifier("SpriteColor")]
                Networking.CreateEntityEvent(item, Item.ChangePropertyEventData(color, item))            
                local invColor = item.SerializableProperties[Identifier("InventoryIconColor")]
                Networking.CreateEntityEvent(item, Item.ChangePropertyEventData(invColor, item))

            end)
        end
    },

    {
        Identifier = "fakehandcuffs",
        Price = 300,
        Limit = 2,
        IsLimitGlobal = false,
        Action = function (client)
            -- logic is implemented in pointshop/traitor.lua
            local handcuffs = ItemPrefab.GetItemPrefab("handcuffs")
            Entity.Spawner.AddItemToSpawnQueue(handcuffs, client.Character.Inventory, nil, nil, function (item)
                item.Tags = "fakehandcuffs"
                Traitormod.SendChatMessage(client, Traitormod.Language.FakeHandcuffsUsage , Color.Aqua)
            end)
        end
    },

    {
        Price = 2700,
        Limit = 1,
        IsLimitGlobal = true,
        Items = {"shotgununique", 
        "shotgunshell", "shotgunshell", "shotgunshell", "shotgunshell", "shotgunshell", "shotgunshell", "shotgunshell", "shotgunshell","shotgunshell", "shotgunshell", "shotgunshell", "shotgunshell", "shotgunshell", "shotgunshell", "shotgunshell", "shotgunshell"},
    },

    {
        Price = 640,
        Limit = 2,
        IsLimitGlobal = true,
        Items = {"shotgunshell", "shotgunshell", "shotgunshell", "shotgunshell", "shotgunshell", "shotgunshell", "shotgunshell", "shotgunshell"},
    },

    {
        Price = 2950,
        Limit = 1,
        IsLimitGlobal = true,
        Items = {"smgunique", "smgmagazine", "smgmagazine"},
    },

    {
        Price = 650,
        Limit = 2,
        IsLimitGlobal = true,
        Items = {"smgmagazine", "smgmagazine"},
    },

    {
        Price = 750,
        Limit = 1,
        IsLimitGlobal = false,
        Items = {"flamerunique", "incendiumfueltank"},
    },

    {
        Price = 800,
        Limit = 2,
        IsLimitGlobal = false,
        Items = {"timeddetonator"},
    },

    {
        Price = 700,
        Limit = 3,
        IsLimitGlobal = false,
        Items = {"uex"},
    },

    {
        Price = 500,
        Limit = 3,
        IsLimitGlobal = false,
        Items = {"stungrenade"},
    },

    {
        Price = 530,
        Limit = 3,
        IsLimitGlobal = false,
        Items = {"badcreepingorange"},
    },

    {
        Identifier = "monsterattractorbeacon",
        Price = 3000,
        Limit = 1,
        IsLimitGlobal = true,
        Action = function (client)
            Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.GetItemPrefab("sonarbeacon"), client.Character.Inventory, nil, nil, function (item)
                item.Description = Traitormod.Language.MonsterBeaconDescription
                item.set_InventoryIconColor(Color(196, 90, 32, 255))
                item.SpriteColor = Color(196, 90, 32, 255)

                local color = item.SerializableProperties[Identifier("SpriteColor")]
                Networking.CreateEntityEvent(item, Item.ChangePropertyEventData(color, item))
                local invColor = item.SerializableProperties[Identifier("InventoryIconColor")]
                Networking.CreateEntityEvent(item, Item.ChangePropertyEventData(invColor, item))

                Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.GetItemPrefab("batterycell"), item.OwnInventory, nil, nil, function (batteryCell)
                    batteryCell.NonPlayerTeamInteractable = true
                    local prop = batteryCell.SerializableProperties[Identifier("NonPlayerTeamInteractable")]
                    Networking.CreateEntityEvent(batteryCell, Item.ChangePropertyEventData(prop, batteryCell))
                end)

                local interface = item.GetComponentString("CustomInterface")
                interface.customInterfaceElementList[2].Signal = "Monster Beacon"
                item.CreateServerEvent(interface, interface)

                Traitormod.AddMonsterBeacon(item, client.Character)
            end)
        end
    },

    {
        Identifier = "ReactorShutdown",
        Price = 500,
        Limit = 1,
        IsLimitGlobal = true,
        Timeout = 60,
        Subcategory = {
            { Identifier = "traitor_sabotage" },
            { Identifier = "traitor_sabotage_criticalsystems" },
        },

        CanBuy = function ()
            return not Traitormod.RoundEvents.IsEventActive("ReactorShutdown")
        end,

        Action = function ()
            if Traitormod.RoundEvents.TriggerEvent("ReactorShutdown") then
                return true
            end

            return false, Traitormod.Language.PointshopCannotBeUsed
        end
    },

    {
        Identifier = "SupercapacitorFailure",
        Price = 1250,
        Limit = 1,
        IsLimitGlobal = true,
        Timeout = 90,
        Subcategory = {
            { Identifier = "traitor_sabotage" },
            { Identifier = "traitor_sabotage_criticalsystems" },
        },

        CanBuy = function ()
            return not Traitormod.RoundEvents.IsEventActive("SupercapacitorFailure")
        end,

        Action = function ()
            if Traitormod.RoundEvents.TriggerEvent("SupercapacitorFailure") then
                return true
            end

            return false, Traitormod.Language.PointshopCannotBeUsed
        end
    },

    {
        Identifier = "JunctionBoxOverload",
        Price = 3500,
        Limit = 1,
        IsLimitGlobal = true,
        Timeout = 120,
        Subcategory = {
            { Identifier = "traitor_sabotage" },
            { Identifier = "traitor_sabotage_criticalsystems" },
        },

        CanBuy = function ()
            return not Traitormod.RoundEvents.IsEventActive("JunctionBoxOverload")
        end,

        Action = function ()
            if Traitormod.RoundEvents.TriggerEvent("JunctionBoxOverload") then
                return true
            end

            return false, Traitormod.Language.PointshopCannotBeUsed
        end
    },

    {
        Identifier = "OxygenSufforin",
        Price = 1300,
        Limit = 1,
        IsLimitGlobal = true,
        Timeout = 120,
        Subcategory = {
            { Identifier = "traitor_sabotage" },
            { Identifier = "traitor_sabotage_oxygensabotage" },
        },

        CanBuy = function ()
            return not Traitormod.RoundEvents.IsEventActive("OxygenSufforin")
        end,

        Action = function ()
            if Traitormod.RoundEvents.TriggerEvent("OxygenSufforin") then
                return true
            end

            return false, Traitormod.Language.PointshopCannotBeUsed
        end
    },

    {
        Identifier = "OxygenParalyzant",
        Price = 1800,
        Limit = 1,
        IsLimitGlobal = true,
        Timeout = 120,
        Subcategory = {
            { Identifier = "traitor_sabotage" },
            { Identifier = "traitor_sabotage_oxygensabotage" },
        },

        CanBuy = function ()
            return not Traitormod.RoundEvents.IsEventActive("OxygenParalyzant")
        end,

        Action = function ()
            if Traitormod.RoundEvents.TriggerEvent("OxygenParalyzant") then
                return true
            end

            return false, Traitormod.Language.PointshopCannotBeUsed
        end
    },

    {
        Identifier = "OxygenMorbusine",
        Price = 2500,
        Limit = 1,
        IsLimitGlobal = true,
        Timeout = 120,
        Subcategory = {
            { Identifier = "traitor_sabotage" },
            { Identifier = "traitor_sabotage_oxygensabotage" },
        },

        CanBuy = function ()
            return not Traitormod.RoundEvents.IsEventActive("OxygenMorbusine")
        end,

        Action = function ()
            if Traitormod.RoundEvents.TriggerEvent("OxygenMorbusine") then
                return true
            end

            return false, Traitormod.Language.PointshopCannotBeUsed
        end
    },

    {
        Identifier = "OxygenCyanide",
        Price = 3200,
        Limit = 1,
        IsLimitGlobal = true,
        Timeout = 120,
        Subcategory = {
            { Identifier = "traitor_sabotage" },
            { Identifier = "traitor_sabotage_oxygensabotage" },
        },

        CanBuy = function ()
            return not Traitormod.RoundEvents.IsEventActive("OxygenCyanide")
        end,

        Action = function ()
            if Traitormod.RoundEvents.TriggerEvent("OxygenCyanide") then
                return true
            end

            return false, Traitormod.Language.PointshopCannotBeUsed
        end
    },

    {
        Identifier = "turnofflights",
        Price = 425,
        Limit = 1,
        IsLimitGlobal = true,
        Subcategory = {
            { Identifier = "traitor_sabotage" },
        },

        CanBuy = function (client, product)
            return not Traitormod.RoundEvents.IsEventActive("LightsOff")
        end,

        Action = function ()
            if Traitormod.RoundEvents.TriggerEvent("LightsOff") then
                return true
            end

            return false, Traitormod.Language.PointshopCannotBeUsed
        end
    },

    {
        Identifier = "turnoffcommunications",
        Price = 740,
        Limit = 1,
        IsLimitGlobal = true,
        Subcategory = {
            { Identifier = "traitor_sabotage" },
        },
        
        CanBuy = function (client, product)
            return not Traitormod.RoundEvents.IsEventActive("CommunicationsOffline")
        end,

        Action = function ()
            if Traitormod.RoundEvents.TriggerEvent("CommunicationsOffline") then
                return true
            end

            return false, Traitormod.Language.PointshopCannotBeUsed
        end
    },
}

return category
