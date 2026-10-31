local category = {}

category.Identifier = "pointshop"

category.Roles = {
    {
        Identifier = "assistant",
        Name = "GhostRoleAssistantName",
        Description = "GhostRoleAssistantDescription",
        Price = 0,
        Icon = "job:assistant",
        Action = function(client)
            Traitormod.LostLivesThisRound[Traitormod.GetClientAccountKey(client)] = false
        end,
    },
}

return category
