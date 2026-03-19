--StartDebug()

local angelItems = RegisterMod("Angel Drop Items Remake", 1)

local configData = {
    ["normalMode"] = true,
    ["greedMode"] = true,
    ["useAngelPool"] = true,
    ["fallenAngels"] = true,
    ["dropChance"] = 50,
    ["dropChanceIncrease"] = 0,

    -- Room type settings
    ["ROOM_NULL"] = 0,
    ["ROOM_DEFAULT"] = 0,
    ["ROOM_SHOP"] = 0,
    ["ROOM_ERROR"] = 1,
    ["ROOM_TREASURE"] = 0,
    ["ROOM_BOSS"] = 0,
    ["ROOM_MINIBOSS"] = 0,
    ["ROOM_SECRET"] = 0,
    ["ROOM_SUPERSECRET"] = 1,
    ["ROOM_ARCADE"] = 0,
    ["ROOM_CURSE"] = 0,
    ["ROOM_CHALLENGE"] = 0,
    ["ROOM_LIBRARY"] = 0,
    ["ROOM_SACRIFICE"] = 1,
    ["ROOM_DEVIL"] = 1,
    ["ROOM_ANGEL"] = 1,
    ["ROOM_DUNGEON"] = 0,
    ["ROOM_BOSSRUSH"] = 0,
    ["ROOM_ISAACS"] = 0,
    ["ROOM_BARREN"] = 0,
    ["ROOM_CHEST"] = 0,
    ["ROOM_DICE"] = 0,
    ["ROOM_BLACK_MARKET"] = 0,
    ["ROOM_GREED_EXIT"] = 0,
    ["ROOM_PLANETARIUM"] = 0,
    ["ROOM_TELEPORTER"] = 0,
    ["ROOM_TELEPORTER_EXIT"] = 0,
    ["ROOM_ULTRASECRET"] = 1
}

local json = require("json")

local roomState = 0
local failedRolls = 0

if ModConfigMenu then
    local name = "Angels Drop Items Remake"
    local cat = "General"

    -- Normal mode
    ModConfigMenu.AddSetting(
        name,
        cat,
        {
            Type = ModConfigMenu.OptionType.BOOLEAN,
            CurrentSetting = function()
                return configData["normalMode"]
            end,
            Display = function()
                if configData["normalMode"] then
                    return "Enabled in normal mode"
                else
                    return "Disabled in normal mode"
                end
            end,
            OnChange = function(value)
                configData["normalMode"] = value
            end
        }
    )

    -- Greed mode
    ModConfigMenu.AddSetting(
        name,
        cat,
        {
            Type = ModConfigMenu.OptionType.BOOLEAN,
            CurrentSetting = function()
                return configData["greedMode"]
            end,
            Display = function()
                if configData["greedMode"] then
                    return "Enabled in greed mode"
                else
                    return "Disabled in greed mode"
                end
            end,
            OnChange = function(value)
                configData["greedMode"] = value
            end
        }
    )

    -- Use angel pool
    ModConfigMenu.AddSetting(
        name,
        cat,
        {
            Type = ModConfigMenu.OptionType.BOOLEAN,
            CurrentSetting = function()
                return configData["useAngelPool"]
            end,
            Display = function()
                if configData["useAngelPool"] then
                    return "Use angel room pool"
                else
                    return "Use current room pool"
                end
            end,
            OnChange = function(value)
                configData["useAngelPool"] = value
            end,
            Info = {"Specifies if the item dropped is going to be from angel room pool, or use the pool from the current room."}
        }
    )

    -- Fallen angels
    ModConfigMenu.AddSetting(
        name,
        cat,
        {
            Type = ModConfigMenu.OptionType.BOOLEAN,
            CurrentSetting = function()
                return configData["fallenAngels"]
            end,
            Display = function()
                if configData["fallenAngels"] then
                    return "Fight fallen angels on refights"
                else
                    return "Fight normal angels on refights"
                end
            end,
            OnChange = function(value)
                configData["fallenAngels"] = value
            end,
            Info = {"When you have a key piece dropped by that specific angel, they'll be replaced by their fallen version."}
        }
    )

    -- Drop chance
    ModConfigMenu.AddSetting(
        name,
        cat,
        {
            Type = ModConfigMenu.OptionType.NUMBER,
            CurrentSetting = function()
                return configData["dropChance"]
            end,
            Minimum = 0,
            Maximum = 100,
            Display = function()
                return "Item drop chance: " .. configData["dropChance"] .. "%"
            end,
            OnChange = function(value)
                configData["dropChance"] = value
            end
        }
    )

    -- Drop chance increase on failed roll
    ModConfigMenu.AddSetting(
        name,
        cat,
        {
            Type = ModConfigMenu.OptionType.NUMBER,
            CurrentSetting = function()
                return configData["dropChanceIncrease"]
            end,
            Minimum = 0,
            Maximum = 100,
            Display = function()
                return "Drop chance increase on failed attempt: " .. configData["dropChanceIncrease"] .. "%"
            end,
            OnChange = function(value)
                configData["dropChanceIncrease"] = value
            end,
            Info = {"When the chance for item drop fails, the chance is increased the next time by this value."}
        }
    )

    -- Removed: "Rooms" tab and all room type settings from ModConfigMenu.
    -- Room behavior is still driven by configData defaults defined at the top of the file.
end

-- Checks if the current game mode is enabled in mod config
local function isGameModeEnabled()
    local game = Game()

    if game:IsGreedMode() then
        return configData["greedMode"]
    else
        return configData["normalMode"]
    end
end

function angelItems:newRoom()
    local game = Game()
    local room = game:GetRoom()
    local currentType = room:GetType()

    roomState = 0

    for key, value in pairs(RoomType) do
        if currentType == value then
            roomState = configData[key] or 0
            break
        end
    end
end

-- Entity death: decides if it will drop an item
function angelItems:entityDeath(entity)
    if not isGameModeEnabled() then return end

    if roomState > 0 then
        local shouldDrop = false

        if roomState == 3 then
            -- "Always": drops regardless of key piece
            shouldDrop = true
        else
            local hasUrielKey = false
            local hasGabrielKey = false

            for i = 0, Game():GetNumPlayers() - 1 do
                local player = Game():GetPlayer(i)
                if player:HasCollectible(CollectibleType.COLLECTIBLE_KEY_PIECE_1) then
                    hasUrielKey = true
                end
                if player:HasCollectible(CollectibleType.COLLECTIBLE_KEY_PIECE_2) then
                    hasGabrielKey = true
                end
            end

            local entityHasKey =
                (entity.Type == EntityType.ENTITY_URIEL and hasUrielKey) or
                (entity.Type == EntityType.ENTITY_GABRIEL and hasGabrielKey)

            if roomState == 1 then
                -- "With key": drops only if the player already has the angel's key piece
                shouldDrop = entityHasKey
            elseif roomState == 2 then
                -- "Without key": drops only if the player does NOT have the angel's key piece
                shouldDrop = not entityHasKey
            end
        end

        if shouldDrop then
            -- RandomInt(100) returns 0-99; comparing < effectiveChance ensures
            -- dropChance=100 always passes and dropChance=0 never passes.
            -- effectiveChance is capped at 100 to prevent unbounded growth.
            local effectiveChance = math.min(configData["dropChance"] + (configData["dropChanceIncrease"] * failedRolls), 100)
            if effectiveChance >= 100 or entity:GetDropRNG():RandomInt(100) < effectiveChance then
                local spawnPos = Isaac.GetFreeNearPosition(entity.Position, 50)

                local collectibleToSpawn = 0
                if configData["useAngelPool"] then
                    collectibleToSpawn = Game():GetItemPool():GetCollectible(ItemPoolType.POOL_ANGEL)
                end

                Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, collectibleToSpawn, spawnPos, Vector(0, 0), entity)
                failedRolls = 0
            else
                failedRolls = failedRolls + 1
            end
        end
    end
end

-- Before angel spawns, change to fallen version if the player already has the key piece
function angelItems:preSpawn(entityType, variant, subType, _, _, _, seed)
    if roomState > 0
        and (entityType == EntityType.ENTITY_URIEL or entityType == EntityType.ENTITY_GABRIEL)
        and variant == 0
        and configData["fallenAngels"]
    then
        for i = 0, Game():GetNumPlayers() - 1 do
            local player = Game():GetPlayer(i)

            if (entityType == EntityType.ENTITY_URIEL and player:HasCollectible(CollectibleType.COLLECTIBLE_KEY_PIECE_1)) or
               (entityType == EntityType.ENTITY_GABRIEL and player:HasCollectible(CollectibleType.COLLECTIBLE_KEY_PIECE_2))
            then
                return {entityType, 1, subType, seed}
            end  -- fixed typo: was "ends"
        end
    end
end

-- Copy save data into configData
local function copySaveData(saveData)
    for key, value in pairs(saveData) do
        if key ~= nil and value ~= nil then
            configData[key] = value
        end
    end
end

-- Load save on game start
function angelItems:onStart(isContinued)
    if angelItems:HasData() then
        local ok, saveData = pcall(json.decode, angelItems:LoadData())

        if not ok or type(saveData) ~= "table" then
            failedRolls = 0
            return
        end

        if saveData["config"] ~= nil then
            copySaveData(saveData["config"])
        end

        -- failedRolls is only restored on continued runs; new runs always start at 0
        -- to avoid carrying over accumulated chance from a previous run.
        if isContinued and saveData["failedRolls"] ~= nil then
            failedRolls = saveData["failedRolls"]
        else
            failedRolls = 0
        end
    else
        failedRolls = 0
    end
end

-- Save config and failedRolls on exit
function angelItems:onExit(_)
    angelItems:SaveData(json.encode({["config"] = configData, ["failedRolls"] = failedRolls}))
end

angelItems:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, angelItems.newRoom)

angelItems:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, angelItems.entityDeath, EntityType.ENTITY_URIEL)
angelItems:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, angelItems.entityDeath, EntityType.ENTITY_GABRIEL)
angelItems:AddCallback(ModCallbacks.MC_PRE_ENTITY_SPAWN, angelItems.preSpawn)

angelItems:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, angelItems.onStart)
angelItems:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, angelItems.onExit)
