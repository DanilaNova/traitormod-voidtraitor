local role = Traitormod.RoleManager.Roles.Antagonist:new()
role.Name = "Saboteur"

local function isRoleActive(self)
    return Game.RoundStarted
        and self.RoundNumber == Traitormod.RoundNumber
        and self.Character ~= nil
        and not self.Character.IsDead
        and Traitormod.RoleManager.GetRole(self.Character) == self
end

function role:QueueNextSabotage(delaySeconds)
    local this = self
    Timer.Wait(function()
        if isRoleActive(this) then
            this:SabotageLoop(false)
        end
    end, delaySeconds * 1000)
end

function role:SabotageLoop(first)
    if not isRoleActive(self) then return end

    local sabotage = Traitormod.RoleManager.Objectives.Sabotage:new()
    sabotage:Init(self.Character)
    -- every already assigned sabotage raises the reward of the next one by PointsPerSabotage
    sabotage.AmountPoints = sabotage.AmountPoints + (self:CompletedObjectives("Sabotage") * self.PointsPerSabotage)
    sabotage.ExcludedItem = self.LastSabotageItem

    if not sabotage:Start() then
        self:QueueNextSabotage(10)
        return
    end

    self.LastSabotageItem = sabotage.TargetItem
    self:AssignObjective(sabotage)

    local this = self
    sabotage.OnAwarded = function()
        local client = Traitormod.FindClientCharacter(this.Character)
        if client ~= nil then
            Traitormod.Stats.AddClientStat("TraitorMainObjectives", client, 1)
            Traitormod.SendMessage(client, Traitormod.Language.SaboteurNextTarget, "")
        end

        this:QueueNextSabotage(math.random(this.NextObjectiveDelayMin, this.NextObjectiveDelayMax))
    end

    sabotage.OnFailed = function()
        this:QueueNextSabotage(math.random(this.NextObjectiveDelayMin, this.NextObjectiveDelayMax))
    end

    local client = Traitormod.FindClientCharacter(self.Character)
    if client ~= nil and not first then
        Traitormod.SendMessage(client, string.format(Traitormod.Language.SaboteurNewObjective, sabotage.Text), "RepairItemsButton")
        Traitormod.UpdateVanillaTraitor(client, true, self:Greet())
    end
end

function role:AssignSubObjectives()
    local pool = {}

    for _, name in ipairs(self.SubObjectives or {}) do
        local template = Traitormod.RoleManager.FindObjective(name)
        if template ~= nil then
            if template.AlwaysActive then
                local objective = template:new()
                objective:Init(self.Character)
                objective.OnAwarded = function()
                    Traitormod.Stats.AddCharacterStat("TraitorSubObjectives", objective.Character, 1)
                end

                if objective:Start() then
                    self:AssignObjective(objective)
                end
            else
                table.insert(pool, name)
            end
        end
    end

    local minSub = self.MinSubObjectives or 0
    local maxSub = self.MaxSubObjectives or 0
    if maxSub <= 0 or #pool == 0 then return end

    local requested = math.random(minSub, maxSub)
    local assigned = 0
    while assigned < requested and #pool > 0 do
        local index = math.random(1, #pool)
        local name = table.remove(pool, index)
        local template = Traitormod.RoleManager.FindObjective(name)

        if template ~= nil then
            local objective = template:new()
            objective:Init(self.Character)
            objective.OnAwarded = function()
                Traitormod.Stats.AddCharacterStat("TraitorSubObjectives", objective.Character, 1)
            end

            if objective:Start() then
                self:AssignObjective(objective)
                assigned = assigned + 1
            end
        end
    end
end

function role:Start()
    Traitormod.Stats.AddCharacterStat("Traitor", self.Character, 1)

    self:SabotageLoop(true)
    self:AssignSubObjectives()

    local text = self:Greet()
    local client = Traitormod.FindClientCharacter(self.Character)
    if client ~= nil then
        Traitormod.SendTraitorMessageBox(client, text)
        Traitormod.UpdateVanillaTraitor(client, true, text)
        Traitormod.SendVanillaTraitorState(client)
        Game.SendDirectChatMessage("", text, nil, ChatMessageType.ServerMessageBoxInGame, client, "RepairItemsButton")
    else
        self.Character.IsTraitor = true
    end
end

function role:End(roundEnd)
    local client = Traitormod.FindClientCharacter(self.Character)
    for _, objective in pairs(self.Objectives or {}) do
        if objective.ClearHighlight ~= nil then
            objective:ClearHighlight(client)
        end
    end

    if not roundEnd then
        self.Character.IsTraitor = false
        if client ~= nil then
            Traitormod.SendMessage(client, Traitormod.Language.TraitorDeath, "InfoFrameTabButton.Traitor")
            Traitormod.UpdateVanillaTraitor(client, false)
        end
    end
end

function role:Transfer(character)
    local oldClient = Traitormod.FindClientCharacter(self.Character)
    if oldClient ~= nil then
        for _, objective in pairs(self.Objectives or {}) do
            if not objective.Awarded and not objective.Failed and not objective.HighlightCleared
                and objective.TargetItem ~= nil and not objective.TargetItem.Removed then
                Traitormod.SetClientItemHighlight(oldClient, objective.TargetItem, false)
            end
        end
    end

    if self.Character ~= nil then
        self.Character.IsTraitor = false
    end

    Traitormod.RoleManager.Roles.Role.Transfer(self, character)
    character.IsTraitor = true

    local client = Traitormod.FindClientCharacter(character)
    if client ~= nil then
        self:SyncClientState(client)
    end
end

function role:SyncClientState(client)
    if not isRoleActive(self) or client == nil or client.Character ~= self.Character then return end

    Traitormod.UpdateVanillaTraitor(client, true, self:Greet())
    Traitormod.SendVanillaTraitorState(client)

    for _, objective in pairs(self.Objectives or {}) do
        if objective.SyncClientState ~= nil then
            objective:SyncClientState(client)
        end
    end
end

function role:ObjectivesToString()
    local primary = Traitormod.StringBuilder:new()
    local secondary = Traitormod.StringBuilder:new()

    for _, objective in pairs(self.Objectives) do
        local buffer = objective.Name == "Sabotage" and primary or secondary
        if objective.Failed then
            buffer:append(" > ", objective.Text, Traitormod.Language.Failed)
        elseif objective.Awarded then
            buffer:append(" > ", objective.Text, Traitormod.Language.Completed)
        else
            buffer:append(" > ", objective.Text, string.format(Traitormod.Language.Points, objective.AmountPoints))
        end
    end

    if #primary == 0 then
        primary(Traitormod.Language.NoObjectivesYet)
    end

    return primary:concat("\n"), secondary:concat("\n")
end

function role:Greet()
    local partners = Traitormod.StringBuilder:new()
    local antagonists = Traitormod.RoleManager.FindAntagonists()
    for _, character in pairs(antagonists) do
        if character ~= self.Character then
            partners('\"%s\" ', character.Name)
        end
    end

    local primary, secondary = self:ObjectivesToString()
    local sb = Traitormod.StringBuilder:new()

    sb("%s\n\n", Traitormod.Language.SaboteurYou)
    sb("%s\n", Traitormod.Language.MainObjectivesYou)
    sb(primary)
    sb("\n\n%s\n", Traitormod.Language.SecondaryObjectivesYou)
    sb(secondary)
    sb("\n\n")

    if #antagonists < 2 then
        sb(Traitormod.Language.SoloAntagonist)
    elseif self.TraitorMethodCommunication == "Names" then
        sb(Traitormod.Language.Partners, partners:concat(" "))
        sb("\n")
        if self.TraitorBroadcast then
            sb(Traitormod.Language.TcTip)
        end
    end

    return sb:concat()
end

function role:OtherGreet()
    local primary, secondary = self:ObjectivesToString()
    local sb = Traitormod.StringBuilder:new()
    sb(Traitormod.Language.SaboteurOther, self.Character.Name)
    sb("\n%s\n", Traitormod.Language.MainObjectivesOther)
    sb(primary)
    sb("\n%s\n", Traitormod.Language.SecondaryObjectivesOther)
    sb(secondary)
    return sb:concat()
end

Hook.Patch("Barotrauma.Networking.GameServer", "SetClientCharacter", function(instance, ptable)
    local client = ptable["client"]
    local character = ptable["newCharacter"]
    if client == nil or character == nil then return end

    Timer.Wait(function()
        if client.Character ~= character then return end
        local currentRole = Traitormod.RoleManager.GetRole(character)
        if currentRole ~= nil and currentRole.Name == "Saboteur" then
            currentRole:SyncClientState(client)
        end
    end, 500)
end, Hook.HookMethodType.After)

return role
