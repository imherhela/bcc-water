Core = exports.vorp_core:GetCore()
-- Prompts
local Prompts = {}
local PumpGroup = GetRandomIntInRange(0, 0xffffff)
local WaterGroup = GetRandomIntInRange(0, 0xffffff)
-- Water
Filling = false
PlayerCoords = vector3(0, 0, 0)
DevModeActive = Config.devMode.active

function DebugPrint(message)
    if DevModeActive then
        print(message)
    end
end

-- Create and start prompts
local function CreatePrompt(keyCode, textKey, groups)
    DebugPrint("Creating prompt with keyCode: " .. keyCode .. ", textKey: " .. textKey)
    local prompt = UiPromptRegisterBegin()
    UiPromptSetControlAction(prompt, keyCode)
    UiPromptSetText(prompt, CreateVarString(10, 'LITERAL_STRING', _U(textKey)))
    UiPromptSetEnabled(prompt, true)
    UiPromptSetHoldMode(prompt, 1000)
    for _, group in ipairs(groups) do
        UiPromptSetGroup(prompt, group, 0)
    end
    UiPromptRegisterEnd(prompt)
    DebugPrint("Prompt created successfully.")
    return prompt
end

local function StartPrompts()
    DebugPrint("Starting prompts...")
    Prompts.FillCanteenPrompt = CreatePrompt(Config.keys.fillCanteen.code, 'fillCanteen', { WaterGroup, PumpGroup })
    Prompts.FillBucketPrompt = CreatePrompt(Config.keys.fillBucket.code, 'fillBucket', { WaterGroup, PumpGroup })
    Prompts.FillBottlePrompt = CreatePrompt(Config.keys.fillBottle.code, 'fillBottle', { WaterGroup, PumpGroup })
    Prompts.WashPrompt = CreatePrompt(Config.keys.wash.code, 'wash', { WaterGroup, PumpGroup })
    Prompts.DrinkPrompt = CreatePrompt(Config.keys.drink.code, 'drink', { WaterGroup, PumpGroup })
    DebugPrint("Prompts started successfully.")
end

-- Create prompt text on-screen when not using prompt buttons
local function DrawText(x, y, z, text)
    local _, _x, _y = GetScreenCoordFromWorldCoord(x, y, z)
    BgSetTextScale(0.35, 0.35)
    SetTextFontForCurrentCommand(9)
    BgSetTextColor(255, 255, 255, 215)
    DisplayText(CreateVarString(10, 'LITERAL_STRING', text, Citizen.ResultAsLong()), _x, _y)
end

---@param itemType string
---@param pump boolean
local function ManageItems(itemType, pump)
    DebugPrint("ManageItems function called with itemType: " .. itemType .. ", pump: " .. tostring(pump))

    local config = pump and Config.pump or Config.wild

    if (itemType == 'bucket' and config.multi.buckets) or (itemType == 'bottle' and config.multi.bottles) then
        OpenInputMenu(itemType, pump)
    else
        if Core.Callback.TriggerAwait('bcc-water:GetItem', itemType, 1, pump) then
            if itemType == 'bucket' then
                BucketFill(pump)
            else
                BottleFill(pump)
            end
        end
    end
end

-- Start main functions when character is selected
RegisterNetEvent('vorp:SelectedCharacter', function()
    DebugPrint("Character selected, starting main functions...")
    StartPrompts()

    if Config.pump.active then
        DebugPrint("Triggering PumpWater event.")
        TriggerEvent('bcc-water:PumpWater')
    end

    if Config.wild.active then
        DebugPrint("Triggering WildWater event.")
        TriggerEvent('bcc-water:WildWater')
    end

    while true do
        Wait(1000)
        PlayerCoords = GetEntityCoords(PlayerPedId())
			TriggerServerEvent("bcc-water:CheckSickness")
    end
 end)

 -- Command to restart main functions for development
CreateThread(function()
    if Config.devMode.active then
        RegisterCommand(Config.devMode.command, function()
            DebugPrint("Restarting main functions for development...")
            StartPrompts()

            if Config.pump.active then
                DebugPrint("Triggering PumpWater event for development.")
                TriggerEvent('bcc-water:PumpWater')
            end

            if Config.wild.active then
                DebugPrint("Triggering WildWater event for development.")
                TriggerEvent('bcc-water:WildWater')
            end

            while true do
                Wait(1000)
                PlayerCoords = GetEntityCoords(PlayerPedId())
            end
                TriggerServerEvent("bcc-water:CheckSickness")
        end, false)
    end
end)

local function HandleWaterInteraction(configType, promptGroup, actions, promptNameFunc, canInteractFunc)
    while true do
        local sleep = 1000
        local playerPed = PlayerPedId()

        if IsEntityDead(playerPed) or not IsPedOnFoot(playerPed) or Filling or not canInteractFunc() then
            goto END
        end

        sleep = 0

        if Config.usePrompt then
            UiPromptSetActiveGroupThisFrame(promptGroup, CreateVarString(10, 'LITERAL_STRING', promptNameFunc()))
            for _, action in ipairs(actions) do
                UiPromptSetVisible(Prompts[action.prompt], configType[action.configKey])
            end
        else
            for _, action in ipairs(actions) do
                if configType[action.configKey] then
                    local key = Config.keys[action.fullKey]
                    DrawText(
                        PlayerCoords.x,
                        PlayerCoords.y,
                        PlayerCoords.z + (action.offset or 0.2),
                        ('~t6~%s~q~ - %s'):format(key.char or tostring(key.code), _U(action.fullKey))
                    )
                end
            end
        end

        for _, action in ipairs(actions) do
            if configType[action.configKey] then
                local doAction = false

                if Config.usePrompt then
                    doAction = PromptHasHoldModeCompleted(Prompts[action.prompt])
                else
                    local key = Config.keys[action.fullKey]
                    doAction = IsControlJustReleased(0, key.code)
                end

                if doAction then
                    Wait(500)
                    local canPerform = true
                    if action.callback then
                        canPerform = Core.Callback.TriggerAwait(action.callback, action.itemType)
                    end
                    if canPerform then
                        if action.param then
                            action.func(table.unpack(action.param))
                        else
                            action.func()
                        end
                        DebugPrint("Action performed: " .. action.fullKey)
                    else
                        Filling = false
                        goto END
                    end
                end
            end
        end

        ::END::
        Wait(sleep)
    end
end

AddEventHandler('bcc-water:PumpWater', function()
    DebugPrint("PumpWater event triggered.")

    local pumpActions = {
        {configKey = 'canteen', prompt = 'FillCanteenPrompt', callback = 'bcc-water:GetCanteenLevel', func = CanteenFill, param = {true}, fullKey = 'fillCanteen', offset = 0.2},
        {configKey = 'bucket',  prompt = 'FillBucketPrompt', func = ManageItems, param = {'bucket', true}, fullKey = 'fillBucket', offset = 0.1},
        {configKey = 'bottle',  prompt = 'FillBottlePrompt', func = ManageItems, param = {'bottle', true}, fullKey = 'fillBottle', offset = 0},
        {configKey = 'wash',    prompt = 'WashPrompt', func = WashPlayer, param = {'stand'}, fullKey = 'wash', offset = 0.3},
        {configKey = 'drink',   prompt = 'DrinkPrompt', func = PumpDrink, param = {}, fullKey = 'drink', offset = 0.4}
    }
    
    HandleWaterInteraction(
        Config.pump,
        PumpGroup,
        pumpActions,
        function() return _U('waterPump') end,
        function()
            for _, obj in ipairs(Config.objects) do
                if DoesObjectOfTypeExistAtCoords(PlayerCoords.x, PlayerCoords.y, PlayerCoords.z, 0.75, joaat(obj), false) then
                    return true
                end
            end
            return false
        end
    )
end)

AddEventHandler('bcc-water:WildWater', function()
    DebugPrint("WildWater event triggered.")

    local wildActions = {
        {configKey = 'canteen', prompt = 'FillCanteenPrompt', callback = 'bcc-water:GetCanteenLevel', func = CanteenFill, param = {false}, fullKey = 'fillCanteen', offset = 0.2},
        {configKey = 'bucket',  prompt = 'FillBucketPrompt', func = ManageItems, param = {'bucket', false}, fullKey = 'fillBucket', offset = 0.1},
        {configKey = 'bottle',  prompt = 'FillBottlePrompt', func = ManageItems, param = {'bottle', false}, fullKey = 'fillBottle', offset = 0},
        {configKey = 'wash',    prompt = 'WashPrompt', func = WashPlayer, param = {'ground'}, fullKey = 'wash', offset = 0.3},
        {configKey = 'drink',   prompt = 'DrinkPrompt', func = WildDrink, param = {}, fullKey = 'drink', offset = 0.4}
    }
    
    HandleWaterInteraction(
        Config.wild,
        WaterGroup,
        wildActions,
        function()
            local hash = GetWaterMapZoneAtCoords(PlayerCoords.x, PlayerCoords.y, PlayerCoords.z)
            for _, loc in pairs(Locations) do
                if loc.hash == hash then return loc.name end
            end
            return _U('wildWater') -- fallback
        end,
        function()
            local ped = PlayerPedId()
            if not IsEntityInWater(ped) then return false end
            local hash = GetWaterMapZoneAtCoords(PlayerCoords.x, PlayerCoords.y, PlayerCoords.z)
            for _, loc in pairs(Locations) do
                if loc.hash == hash then
                    return (not Config.crouch or GetPedCrouchMovement(ped) ~= 0) and IsPedStill(ped)
                end
            end
            return false
        end
    )
end)

local isSick = false

function ApplySicknessEffect(duration, tickInterval)
    if isSick then
        DebugPrint("Sickness effect already active, skipping.")
        return
    end

    isSick = true
    duration = duration or 180
    tickInterval = tickInterval or 15
    local healthPerTick = 50 -- 🔥 Amount of health to remove per tick
    local remaining = duration

    DebugPrint(string.format("Applying sickness effect: duration = %ds, tickInterval = %ds", duration, tickInterval))

    Core.NotifyRightTip("You feel sick from the water...", 4000)

    -- Timer thread (unchanged)
    CreateThread(function()
        while isSick and remaining > 0 do
            Wait(1000)
            remaining -= 1
            if not isSick then
                break
            end
        end
    end)

    -- Animation + Health Tick Thread
    CreateThread(function()
        DebugPrint("Starting sickness animation/health tick thread.")
        local ped = PlayerPedId()

        while isSick and remaining > 0 do
            ClearPedTasks(ped)
            DebugPrint("Cleared ped tasks for sickness animation.")

            local currentHealth = GetEntityHealth(ped)
            local newHealth = currentHealth - healthPerTick

            -- Play animation
            if remaining > (duration / 2) then
                DebugPrint("Playing coughing animation.")
                PlayAnim("amb_wander@code_human_coughing_hacking@male_a@wip_base", "wip_base")
            else
                local vomit = math.random(1, 2) == 1 and "idle_g" or "idle_h"
                DebugPrint("Playing vomiting animation: " .. vomit)
                PlayAnim("amb_misc@world_human_vomit@male_a@idle_c", vomit)
            end

            -- Apply health damage
            if newHealth <= 0 then
                DebugPrint("Player health reached 0 during sickness. Killing player.")
                SetEntityHealth(ped, 0)
                break
            else
                SetEntityHealth(ped, newHealth)
                DebugPrint("Health reduced by sickness. New health: " .. newHealth)
            end

            Wait(tickInterval * 1000)
        end

        if isSick then
            DebugPrint("Sickness ended. Forcing death if still alive.")
            Core.NotifyRightTip("You succumb to the sickness...", 6000)
            SetEntityHealth(ped, 0)
            isSick = false
            ClearPedTasks(ped)
            DebugPrint("Sickness effect fully cleared.")
        end
    end)

    TriggerServerEvent("bcc-water:UpdateSickness", duration)
    DebugPrint("Triggered server event to update sickness status.")
end


RegisterNetEvent("ApplySicknessEffect", function(duration, tick, fatal)
    ApplySicknessEffect(duration, tick, fatal)
end)

RegisterNetEvent("bcc-water:CureSickness", function()
    if isSick then
        isSick = false
        ClearPedTasks(PlayerPedId())
        Core.NotifyRightTip("You feel better after taking the antidote.", 4000)
        TriggerServerEvent("bcc-water:UpdateSickness", 0)
    end
end)

function PlayAnim(dict, anim, flag)
    local ped = PlayerPedId()
    flag = flag or 1 -- default flag if not passed

    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(10)
    end

    TaskPlayAnim(ped, dict, anim, 8.0, -8.0, -1, flag, 0, false, false, false)
end

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then return end

    DebugPrint("Resource stopped, cleaning up...")
    ClearPedTasksImmediately(PlayerPedId())

    if Canteen then
        DeleteObject(Canteen)
    end

    if Container then
        DeleteObject(Container)
    end

    for name, prompt in pairs(Prompts) do
        UiPromptDelete(prompt)
        Prompts[name] = nil
    end
    DebugPrint("Cleanup complete.")
end)
