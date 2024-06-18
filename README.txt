# Improved qb-storerobbery

## Description
QB-StoreRobbery is an improved version of the basic qb-storerobbery script, using ox_inventory, ox_lib, ps-ui, and ps-dispatch. It provides a realistic and immersive store robbery experience in your FiveM server, including features like safe cracking, cash register looting, police dispatch alerts, and configurable reward systems.

## Dependencies
This resource requires the following dependencies to function correctly:
- [QBCore](https://github.com/qbcore-framework/qb-core)
- [PS-UI](https://github.com/Project-Sloth/ps-ui)
- [PS-Dispatch](https://github.com/Project-Sloth/ps-dispatch)
- [OX_Inventory](https://github.com/overextended/ox_inventory)
- [OX_Lib](https://github.com/overextended/ox_lib)

## Features
- **Safe Cracking**: Players can crack safes using a numeric code scrambling minigame. If successful, they will receive a cash reward.
- **Cash Register Looting**: Players can loot cash registers using lockpicks. Advanced lockpicks increase the chance of success.
- **Police Dispatch Alerts**: Integrated with PS-Dispatch to notify police of ongoing store robberies.
- **Configurable Rewards**: Set minimum and maximum cash rewards for both safes and registers.
- **Progress Notifications**: Players receive notifications about the progress and outcome of their robbery attempts.
- **Anti-Exploit Measures**: Includes distance checks and status verifications to prevent exploit attempts.

## Configuration
The script is highly configurable via the `config.lua` file. Here you can set various parameters such as reward amounts, reset times, and notification positions.

### Example `config.lua`
```lua
Config = {}
-- REGISTERES EARN
Config.minEarn = 3000
Config.maxEarn = 8460
Config.RegisterEarnings = math.random(Config.minEarn, Config.maxEarn)
--
Config.MinimumStoreRobberyPolice = 0
Config.resetTime = (60 * 1000) * 30
Config.tickInterval = 1000

Config.Notification = {
    position = 'center-right'
}

Config.SafeCrackingTime = (60 * 1000) * 4 -- 4 minutes for safe cracking
Config.SafeMinEarn = 33470
Config.SafeMaxEarn = 48700

Config.Registers = {
    [1] = { vector3(-47.24, -1757.65, 29.53), robbed = false, time = 0, safeKey = 1, camId = 4 },
    [2] = { vector3(-48.58, -1759.21, 29.59), robbed = false, time = 0, safeKey = 1, camId = 4 },
    -- Add more registers as needed
}

Config.Safes = {
    [1] = { vector4(-43.43, -1748.3, 29.42, 52.5), type = 'keypad', robbed = false, camId = 4 },
    [2] = { vector4(-1478.94, -375.5, 39.16, 229.5), type = 'padlock', robbed = false, camId = 5 },
    -- Add more safes as needed
}
```

## Installation
1. Ensure all dependencies are installed.
2. Clone or download the qb-storerobbery resource.
3. Add the resource to your server's resources directory.
4. Configure the `config.lua` file to suit your server's needs.
5. Add `ensure qb-storerobbery` to your server.cfg file.

## Support
For support, join our Discord community: [Support Discord](https://discord.gg/hKGXaD68Es)

## License
This project is licensed under the MIT License.

### What is the MIT License?
The MIT License is a permissive free software license originating at the Massachusetts Institute of Technology (MIT). It is a simple and easy-to-understand license that places very few restrictions on reuse, making it a popular choice for open-source projects. The key points of the MIT License are:
- It allows users to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the software.
- It requires that the original license and copyright notice be included in all copies or substantial portions of the software.
- It is provided "as is", without warranty of any kind, express or implied.