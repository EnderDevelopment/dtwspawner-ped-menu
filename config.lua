Config = {}

Config.AdminCommand = 'companions'
Config.AdminPermission = 'admin'
Config.MenuTitle = 'Companion Peds'
Config.MaxCompanions = 3
Config.SpawnDistance = 1.5
Config.FollowDistance = 2.0
Config.FollowSpeed = 1.0
Config.AnimationRetryMs = 1500
Config.AnimationTimeoutMs = 5000
Config.EnableBlips = false

-- Add custom entries here. Models must be streamed by this resource or another ensured resource.
-- Animation dictionaries and names use the same values as the corresponding DPEmotes entry.
Config.Companions = {
    {
        id = 'dog_rottweiler',
        label = 'Rottweiler',
        model = 'a_c_rottweiler',
        animation = { dict = 'creatures@rottweiler@amb@world_dog_sitting@base', name = 'base' },
        scenario = nil
    },
    {
        id = 'dog_retriever',
        label = 'Retriever',
        model = 'a_c_retriever',
        animation = { dict = 'creatures@retriever@amb@world_dog_sitting@base', name = 'base' },
        scenario = nil
    },
    {
        id = 'cat',
        label = 'Cat',
        model = 'a_c_cat_01',
        animation = { dict = 'creatures@cat@amb@world_cat_sleeping@base', name = 'base' },
        scenario = nil
    }
}
