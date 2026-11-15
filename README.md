# FiveM QBCore Companion Ped Menu Resource

DTWSpawner_Ped_Menu is a FiveM resource and QBCore companion ped menu that lets authorized administrators spawn configured companion peds, manage multiple active companions, toggle follow behavior, and use configured DPEmotes-compatible animation dictionaries and animation names for companion idle behavior.

## Install

1. Create a resource folder named `DTWSpawner_Ped_Menu` inside your FiveM server resources directory.
2. Add the resource files:
   - `fxmanifest.lua`
   - `config.lua`
   - `client/main.lua`
   - `server/main.lua`
3. Ensure the required dependencies are installed and started:
   - `qb-core`
   - `qb-menu`
4. Add the resource to `server.cfg` after its dependencies:

```cfg
ensure qb-core
ensure qb-menu
ensure DTWSpawner_Ped_Menu
```

5. Confirm that every configured ped model is provided by this resource or by another streamed resource that starts before this resource.
6. Edit `config.lua` to add, remove, or modify companion entries.

A companion entry uses this structure:

```lua
{
    id = 'my_companion',
    label = 'My Companion',
    model = 'model_name',
    animation = {
        dict = 'animation_dictionary',
        name = 'animation_name'
    },
    scenario = nil
}
```

The animation dictionary and animation name must be valid GTA V animation values. They can use the same dictionary and animation names used by DPEmotes.

## Use

1. Give the player the QBCore permission configured by `Config.AdminPermission`.
2. Join the server with that player.
3. Run the configured admin command in chat:

```text
/companions
```

4. Select a configured companion from the menu.
5. The companion spawns near the player and follows automatically when follow mode is enabled.
6. Select the follow option to switch between following and staying in place with its configured idle animation or scenario.
7. Select Remove all companions to delete every active companion and its map blip, if blips are enabled.

Configuration options include:

```lua
Config.AdminCommand = 'companions'
Config.AdminPermission = 'admin'
Config.MaxCompanions = 3
Config.SpawnDistance = 1.5
Config.FollowDistance = 2.0
Config.FollowSpeed = 1.0
Config.EnableBlips = false
```

The server validates administrator permissions and companion IDs before approving a spawn request. Invalid models and unavailable streamed assets produce an in-game error notification.

---

More FiveM resource projects by EnderDevelopment: https://github.com/EnderDevelopment

Project page: https://dash.enderdevelopment.com/community/ce25bab5-c2c0-42b4-a627-616f7ccc9a84?utm_source=github&utm_medium=readme&utm_campaign=auto_publish&utm_content=ce25bab5-c2c0-42b4-a627-616f7ccc9a84
