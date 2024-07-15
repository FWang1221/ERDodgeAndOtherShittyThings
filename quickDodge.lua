-- This file should be in your Game folder (usually C:\Program Files (x86)\Steam\steamapps\common\ELDEN RING\Game) + quickDodge. This file path should be C:\Program Files (x86)\Steam\steamapps\common\ELDEN RING\Game\quickDodge\quickDodge.lua

BACKSTEP_REPLACE_BACKWARDS_DODGE = FALSE -- When dodging backwards, backstep instead.
SPRINTING_R2_ON_BACKSTEP_R2 = TRUE -- When pressing R2 from a backstep, execute the sprinting R2 instead of standing R2.
INSTANT_SPRINTING_FROM_DODGE = TRUE -- If you hold the dodge button from a dodge, you exit it in a sprint.
SPRINTING_ATTACKS_WHILE_HOLDING_DODGE = TRUE -- If you hold the dodge button from a dodge, instead of queueing a dodge attack, you queue a sprinting attack
FAST_DODGE_R2 = TRUE -- When exiting from a dodge, the R2 attack is noticeably faster
FIRST_R1_CHAINS_TO_SECOND_R2 = FALSE -- Your standing R1 chains to your second standing R2 instead of the first standing R2.
DODGE_R1_CHAINS_TO_SECOND_R2 = FALSE
SPRINT_R1_CHAINS_TO_SECOND_R2 = FALSE
BACKSTEP_R1_CHAINS_TO_SECOND_R2 = FALSE
SPRINT_R2_CHAINS_TO_SECOND_R2 = FALSE

DODGE_CANCEL_GRACE_PERIOD = 0.3 -- Measured in seconds. Can dodge cancel out of attacks within the first few seconds here.

CUSTOM_DODGE_CHAIN_TIMING = -1 -- Measured in seconds. If you want to chain a dodge into another dodge, you can set the timing here. -1 means it's disabled.

CUSTOM_WEIGHT_OVERRIDE = -1 -- -1 for inactive, 1 for Light, 2 for Medium, 3 for Heavy, 4 for Overweight

-- If you see this message you have the Github version.











-- Table to hold the backup functions
rawset(_G, "backupEnv", {})

-- Function to create a replacement
function createReplacement(functionName, originalFunction, newFunction)
    -- Check if the function already exists in the backup environment using rawget
    if rawget(backupEnv, functionName) == nil then
        -- Store the original function in the backup environment
        backupEnv[functionName] = originalFunction
    end
    
    -- Create a wrapper that calls the new function
    return function(...)
        -- Call the new function
        return newFunction(...)
    end
end

-- Function to restore the original function
function restoreFunction(functionName)
    -- Check if the backup environment has the original function using rawget
    local originalFunction = rawget(backupEnv, functionName)
    if originalFunction then
        -- Return the original function
        return originalFunction
    elseif rawget(_G, functionName) then
        return rawget(_G, functionName)
    else
        return nil
    end
end

-- Function to create a detour
function createDetour(originalFunction, newFunction)
    -- Store the original function in the new function's environment
    local original = originalFunction
    -- Create a wrapper that calls the new function first, then the original function
    return function(...)
        -- Call the new function
        newFunction(...)
        -- Call the original function
        return original(...)
    end
end

-- Function to create a detour
function createPostDetour(originalFunction, newFunction)
    -- Store the original function in the new function's environment
    local original = originalFunction
    -- Create a wrapper that calls the new function first, then the original function
    return function(...)
        -- Call the original function
        local originalResult = original(...)
        -- Call the new function
        newFunction(...)
        return originalResult
    end
end

function customWeightOverride()
    if CUSTOM_WEIGHT_OVERRIDE == -1 then
        return
    end
    if CUSTOM_WEIGHT_OVERRIDE == 1 then
        SetVariable("MoveWeightIndex", MOVE_WEIGHT_LIGHT)
        SetVariable("EvasionWeightIndex", EVASION_WEIGHT_INDEX_LIGHT)
    elseif CUSTOM_WEIGHT_OVERRIDE == 2 then
        SetVariable("MoveWeightIndex", MOVE_WEIGHT_NORMAL)
        SetVariable("EvasionWeightIndex", EVASION_WEIGHT_INDEX_MEDIUM)
    elseif CUSTOM_WEIGHT_OVERRIDE == 3 then
        SetVariable("MoveWeightIndex", MOVE_WEIGHT_HEAVY)
        SetVariable("EvasionWeightIndex", EVASION_WEIGHT_INDEX_HEAVY)
    elseif CUSTOM_WEIGHT_OVERRIDE == 4 then
        SetVariable("MoveWeightIndex", MOVE_WEIGHT_HEAVY)
        SetVariable("EvasionWeightIndex", EVASION_WEIGHT_INDEX_OVERWEIGHT)
    end
end

SetWeightIndex = createPostDetour(SetWeightIndex, customWeightOverride)

rawset(_G, "buttonToggleThing", true)

function rebindSprint()

    if env(GetStamina) <= 0 then

        buttonToggleThing = false
    elseif env(ActionDuration, ACTION_ARM_L3) <= 0 then
        buttonToggleThing = true
    end

    if env(ActionDuration, ACTION_ARM_L3) > 0 and env(GetStamina) > 0 and buttonToggleThing then
        act(2002, 100220)

        buttonToggleThing = true
    end
end

Update = createPostDetour(Update, rebindSprint)

rawset(_G, "g_EventsLog", { ["CMSG"] = "", ["TIME"] = 0 })

function LogEventsAndTiming(state)
    g_EventsLog["CMSG"] = state
    g_EventsLog["TIME"] = os.clock()
end

ExecEvent = createDetour(ExecEvent, LogEventsAndTiming)

ACTION_ARM_L3_BACK = ACTION_ARM_L3

function ExecEvasionMonkeyPatchPre()

    if c_HasActionRequest == FALSE then
        return FALSE
    end

    if (env(ActionRequest, ACTION_ARM_L3) == TRUE or env(ActionDuration, ACTION_ARM_L3) > 0) and env(ActionRequest, ACTION_ARM_SP_MOVE) == TRUE and c_IsStealth == FALSE then
        StealthTransitionIndexUpdate()
        ExecEvent("W_Stealth_to_Stealth_Idle")
        c_HasActionRequest = TRUE
        return TRUE
    elseif (env(ActionRequest, ACTION_ARM_L3) == TRUE or env(ActionDuration, ACTION_ARM_L3) > 0) and env(ActionRequest, ACTION_ARM_SP_MOVE) == TRUE and c_IsStealth == TRUE then
        StealthTransitionIndexUpdate()
        ExecEvent("W_Stealth_to_Idle")
        c_HasActionRequest = TRUE
        return TRUE
    end

    ACTION_ARM_L3 = 666

end

function ExecEvasionMonkeyPatchPost()

    ACTION_ARM_L3 = ACTION_ARM_L3_BACK

end

ExecEvasion = createDetour(ExecEvasion, ExecEvasionMonkeyPatchPre)
ExecEvasion = createPostDetour(ExecEvasion, ExecEvasionMonkeyPatchPost)

function fixDodges()
    c_RollingAngle = GetVariable("MoveAngle")
    c_ArtsRollingAngle = GetVariable("MoveAngle")
end

GetConstVariable = createPostDetour(GetConstVariable, fixDodges)


rawset(_G, "canUpdateSelf", true)

function checkForUpdates()

    if (env(ActionDuration, ACTION_ARM_SP_MOVE) > 15000) and (env(ActionDuration, ACTION_ARM_R1) > 15000) and (env(ActionDuration, ACTION_ARM_L1) > 15000) and canUpdateSelf then
        updateSelf()
        canUpdateSelf = false
        act(1000, -100000)
    end

end

function updateSelf()
    -- Define the URL of the Lua script to download
    local url = "https://raw.githubusercontent.com/FWang1221/ERDodgeAndOtherShittyThings/master/quickDodge.lua"
    -- Define the command to download the file using curl (cross-platform)
    local download_command = 'curl -o quickDodge/quickDodge.lua ' .. url

    -- Download the Lua script using os.execute
    os.execute(download_command)
end

Update = createDetour(Update, checkForUpdates)

function GetEvasionRequestCustom()

    local dodgeDecider = FALSE

    dodgeDecider = env(ActionRequest, ACTION_ARM_SP_MOVE)
    if (os.clock() - g_EventsLog["TIME"] < DODGE_CANCEL_GRACE_PERIOD) and (string.find(g_EventsLog["CMSG"], "ttack")) then
        if env(ActionDuration, ACTION_ARM_SP_MOVE) > 0 then
            dodgeDecider = TRUE
        end
    end

    local move_angle = GetVariable("MoveAngle")
    local stick_level = GetVariable("MoveSpeedLevel")


    if env(GetStamina) < STAMINA_MINIMUM or env(ActionDuration, ACTION_ARM_L3) > 0 then
        return ATTACK_REQUEST_INVALID
    end
    if (dodgeDecider == TRUE and stick_level > 0.05) then
        if (move_angle > 135 or move_angle < -135) and BACKSTEP_REPLACE_BACKWARDS_DODGE == TRUE then
            return ATTACK_REQUEST_BACKSTEP
        else
            return ATTACK_REQUEST_ROLLING
        end
    elseif env(ActionDuration, ACTION_ARM_L1) > 0 then
        if env(ActionRequest, ACTION_ARM_EMERGENCYSTEP) == TRUE then
            if env(IsEmergencyEvasionPossible, 0) == TRUE or env(IsEmergencyEvasionPossible, 1) == TRUE then
                return ATTACK_REQUEST_EMERGENCYSTEP
            end
        elseif env(ActionRequest, ACTION_ARM_BACKSTEP) == TRUE then
            return ATTACK_REQUEST_BACKSTEP
        else
            return ATTACK_REQUEST_INVALID
        end
    elseif env(ActionRequest, ACTION_ARM_BACKSTEP) == TRUE then
        return ATTACK_REQUEST_BACKSTEP
    end
    return ATTACK_REQUEST_INVALID
end

function DefaultBackStep_onUpdateCustom()
    act(DisallowAdditiveTurning, TRUE)

    if EvasionCommonFunction(FALL_TYPE_DEFAULT, "W_AttackRightBackstep", "W_AttackRightHeavyDash",
        "W_AttackLeftLight1", "W_AttackLeftHeavy1", "W_AttackBothBackstep", "W_AttackBothHeavyDash",
        QUICKTYPE_BACKSTEP) == TRUE then
        return
    end
end

function Rolling_onUpdateCustom()
    act(DisallowAdditiveTurning, TRUE)
    SetThrowAtkInvalid()

    if env(GetSpEffectID, 100390) == TRUE then
        ResetDamageCount()
    end

    SetEnableAimMode()

    if SPRINTING_ATTACKS_WHILE_HOLDING_DODGE == TRUE and env(ActionDuration, ACTION_ARM_SP_MOVE) > 0 then

        if EvasionCommonFunction(FALL_TYPE_DEFAULT, "W_AttackRightLightDash", "W_AttackRightHeavyDash",         "W_AttackLeftLight1", "W_AttackLeftHeavy1", "W_AttackBothDash", "W_AttackBothHeavyDash", QUICKTYPE_ROLLING) == TRUE then
            return
        end
    elseif FAST_DODGE_R2 == TRUE then

        if EvasionCommonFunction(FALL_TYPE_DEFAULT, "W_AttackRightLightStep", "W_AttackRightHeavy1End",         "W_AttackLeftLight1", "W_AttackLeftHeavy1", "W_AttackBothLightStep", "W_AttackBothHeavy1End", QUICKTYPE_ROLLING) == TRUE then
            return
        end
    else
        if EvasionCommonFunction(FALL_TYPE_DEFAULT, "W_AttackRightLightStep", "W_AttackRightHeavy1Start",         "W_AttackLeftLight1", "W_AttackLeftHeavy1", "W_AttackBothLightStep", "W_AttackBothHeavy1Start", QUICKTYPE_ROLLING) == TRUE then
            return
        end
    end

    if env(IsAnimEnd, 1) == TRUE then
        ExecEventAllBody("W_Idle")
        return
    end
    SetRollingTurnCondition(FALSE)

    if env(ActionDuration, ACTION_ARM_SP_MOVE) > 0 and SPRINTING_ATTACKS_WHILE_HOLDING_DODGE == TRUE then
        SetVariable("ToggleDash", 1)
    end
end

function AttackRightLight1_onUpdateCustom()
    local r1 = "W_AttackRightLight2"

    if g_ComboReset == TRUE then
        r1 = "W_AttackRightLight1"
    end
    if FIRST_R1_CHAINS_TO_SECOND_R2 == TRUE then
        if AttackCommonFunction(r1, "W_AttackRightHeavy2Start", "W_AttackLeftLight1", "W_AttackLeftHeavy1",
            "W_AttackBothLight2", "W_AttackBothHeavy2Start", FALSE, TRUE, 1) == TRUE then
            return
        end
    else
        if AttackCommonFunction(r1, "W_AttackRightHeavy1Start", "W_AttackLeftLight1", "W_AttackLeftHeavy1",
            "W_AttackBothLight2", "W_AttackBothHeavy1Start", FALSE, TRUE, 1) == TRUE then
            return
        end
    end
end

function AttackBothLight1_onUpdateCustom()
    local b1 = "W_AttackBothLight2"
    if g_ComboReset == TRUE then
        b1 = "W_AttackBothLight1"
    end
    if FIRST_R1_CHAINS_TO_SECOND_R2 == TRUE then
        if AttackCommonFunction("W_AttackRightLight2", "W_AttackRightHeavy2Start", "W_AttackBothLeft2",
            "W_AttackLeftHeavy1", b1, "W_AttackBothHeavy2Start", FALSE, TRUE, 1) == TRUE then
            return
        end
    else
        if AttackCommonFunction("W_AttackRightLight2", "W_AttackRightHeavy1Start", "W_AttackBothLeft2",
            "W_AttackLeftHeavy1", b1, "W_AttackBothHeavy1Start", FALSE, TRUE, 1) == TRUE then
            return
        end

    end
end

function AttackRightLightStep_onUpdateCustom()
    local r1 = "W_AttackRightLightSubStart"
    if g_ComboReset == TRUE then
        r1 = "W_AttackRightLight1"
    end
    if AttackCommonFunction(r1, "W_AttackRightHeavy2Start", "W_AttackLeftLight1", "W_AttackLeftHeavy1",
        "W_AttackBothLight1", "W_AttackBothHeavy2Start", FALSE, TRUE, 1) == TRUE then
        return
    end
end

function AttackBothLightStep_onUpdateCustom()
    local b1 = "W_AttackBothLightSubStart"
    if g_ComboReset == TRUE then
        b1 = "W_AttackBothLight1"
    end
    if AttackCommonFunction("W_AttackRightLight1", "W_AttackRightHeavy2Start", "W_AttackLeftLight1",
        "W_AttackLeftHeavy1", b1, "W_AttackBothHeavy2Start", FALSE, TRUE, 1) == TRUE then
        return
    end
end

function AttackRightLightDash_onUpdateCustom()
    local r1 = "W_AttackRightLightSubStart"
    if g_ComboReset == TRUE then
        r1 = "W_AttackRightLight1"
    end
    if AttackCommonFunction(r1, "W_AttackRightHeavy2Start", "W_AttackLeftLight1", "W_AttackLeftHeavy1",
        "W_AttackBothLight1", "W_AttackBothHeavy2Start", FALSE, TRUE, 1) == TRUE then
        return
    end
end

function AttackBothDash_onUpdateCustom()
    local b1 = "W_AttackBothLightSubStart"
    if g_ComboReset == TRUE then
        b1 = "W_AttackBothLight1"
    end
    if AttackCommonFunction("W_AttackRightLight1", "W_AttackRightHeavy2Start", "W_AttackLeftLight1",
        "W_AttackLeftHeavy1", b1, "W_AttackBothHeavy2Start", FALSE, TRUE, 1) == TRUE then
        return
    end
end

function AttackRightBackstep_onUpdateCustom()
    local r1 = "W_AttackRightLightSubStart"
    if g_ComboReset == TRUE then
        r1 = "W_AttackRightLight1"
    end
    if AttackCommonFunction(r1, "W_AttackRightHeavy2Start", "W_AttackLeftLight1", "W_AttackLeftHeavy1",
        "W_AttackBothLight1", "W_AttackBothHeavy2Start", FALSE, TRUE, 1) == TRUE then
        return
    end
end

function AttackBothBackstep_onUpdateCustom()
    local b1 = "W_AttackBothLightSubStart"
    if g_ComboReset == TRUE then
        b1 = "W_AttackBothLight1"
    end
    if AttackCommonFunction("W_AttackRightLight1", "W_AttackRightHeavy2Start", "W_AttackLeftLight1",
        "W_AttackLeftHeavy1", b1, "W_AttackBothHeavy2Start", FALSE, TRUE, 1) == TRUE then
        return
    end
end

function AttackRightHeavyDash_onUpdateCustom()
    local r1 = "W_AttackRightLightSubStart"
    if g_ComboReset == TRUE then
        r1 = "W_AttackRightLight1"
    end
    if AttackCommonFunction(r1, "W_AttackRightHeavy2Start", "W_AttackLeftLight1", "W_AttackLeftHeavy1",
        "W_AttackBothLight1", "W_AttackBothHeavy2Start", FALSE, TRUE, 1) == TRUE then
        return
    end
end

function AttackBothHeavyDash_onUpdateCustom()
    local b1 = "W_AttackBothLightSubStart"
    if g_ComboReset == TRUE then
        b1 = "W_AttackBothLight1"
    end
    if AttackCommonFunction("W_AttackRightLight1", "W_AttackRightHeavy2Start", "W_AttackLeftLight1",
        "W_AttackLeftHeavy1", b1, "W_AttackBothHeavy2Start", FALSE, TRUE, 1) == TRUE then
        return
    end
end


GetEvasionRequest = createReplacement("GetEvasionRequest", GetEvasionRequest, GetEvasionRequestCustom)

rawset(_G, "g_LastSettingsCheckTime", 0)

function applySettings()

    if SPRINTING_R2_ON_BACKSTEP_R2 == TRUE then
        DefaultBackStep_onUpdate = createReplacement("DefaultBackStep_onUpdate", DefaultBackStep_onUpdate, DefaultBackStep_onUpdateCustom)
    else
        DefaultBackStep_onUpdate = restoreFunction("DefaultBackStep_onUpdate")
    end

    if INSTANT_SPRINTING_FROM_DODGE == TRUE or INSTANT_SPRINTING_FROM_DODGE == TRUE then
        Rolling_onUpdate = createReplacement("Rolling_onUpdate", Rolling_onUpdate, Rolling_onUpdateCustom)
    else
        Rolling_onUpdate = restoreFunction("Rolling_onUpdate")
    end

    if FIRST_R1_CHAINS_TO_SECOND_R2 == TRUE then
        AttackRightLight1_onUpdate = createReplacement("AttackRightLight1_onUpdate", AttackRightLight1_onUpdate, AttackRightLight1_onUpdateCustom)
        AttackBothLight1_onUpdate = createReplacement("AttackBothLight1_onUpdate", AttackBothLight1_onUpdate, AttackBothLight1_onUpdateCustom)
    else
        AttackRightLight1_onUpdate = restoreFunction("AttackRightLight1_onUpdate")
        AttackBothLight1_onUpdate = restoreFunction("AttackBothLight1_onUpdate")
    end

    if DODGE_R1_CHAINS_TO_SECOND_R2 == TRUE then
        AttackRightLightStep_onUpdate = createReplacement("AttackRightLightStep_onUpdate", AttackRightLightStep_onUpdate, AttackRightLightStep_onUpdateCustom)
        AttackBothLightStep_onUpdate = createReplacement("AttackBothLightStep_onUpdate", AttackBothLightStep_onUpdate, AttackBothLightStep_onUpdateCustom)
    else
        AttackRightLightStep_onUpdate = restoreFunction("AttackRightLightStep_onUpdate")
        AttackBothLightStep_onUpdate = restoreFunction("AttackBothLightStep_onUpdate")
    end

    if SPRINT_R1_CHAINS_TO_SECOND_R2 == TRUE then
        AttackRightLightDash_onUpdate = createReplacement("AttackRightLightDash_onUpdate", AttackRightLightDash_onUpdate, AttackRightLightDash_onUpdateCustom)
        AttackBothDash_onUpdate = createReplacement("AttackBothDash_onUpdate", AttackBothDash_onUpdate, AttackBothDash_onUpdateCustom)
    else
        AttackRightLightDash_onUpdate = restoreFunction("AttackRightLightDash_onUpdate")
        AttackBothDash_onUpdate = restoreFunction("AttackBothDash_onUpdate")
    end

    if BACKSTEP_R1_CHAINS_TO_SECOND_R2 == TRUE then
        AttackRightBackstep_onUpdate = createReplacement("AttackRightBackstep_onUpdate", AttackRightBackstep_onUpdate, AttackRightBackstep_onUpdateCustom)
        AttackBothBackstep_onUpdate = createReplacement("AttackBothBackstep_onUpdate", AttackBothBackstep_onUpdate, AttackBothBackstep_onUpdateCustom)
    else
        AttackRightBackstep_onUpdate = restoreFunction("AttackRightBackstep_onUpdate")
        AttackBothBackstep_onUpdate = restoreFunction("AttackBothBackstep_onUpdate")
    end

    if SPRINT_R2_CHAINS_TO_SECOND_R2 == TRUE or true then
        AttackRightHeavyDash_onUpdate = createReplacement("AttackRightHeavyDash_onUpdate", AttackRightHeavyDash_onUpdate, AttackRightHeavyDash_onUpdateCustom)
        AttackBothHeavyDash_onUpdate = createReplacement("AttackBothHeavyDash_onUpdate", AttackBothHeavyDash_onUpdate, AttackBothHeavyDash_onUpdateCustom)
    else
        AttackRightHeavyDash_onUpdate = restoreFunction("AttackRightHeavyDash_onUpdate")
        AttackBothHeavyDash_onUpdate = restoreFunction("AttackBothHeavyDash_onUpdate")
    end
end

function checkSettings()

    if os.clock() - g_LastSettingsCheckTime > 1 then
        g_LastSettingsCheckTime = os.clock()
    else
        return
    end

    local filePath = "quickDodge/quickDodgeSettings.txt"
    -- Function to check if a file exists
    local function fileExists(file)
        local f = io.open(file, "r")
        if f then
            io.close(f)
            return true
        else
            return false
        end
    end

    -- Function to run the file
    local function runFile(file)
        pcall(loadfile(file))
    end

    -- Function to create the file with specified content
    local function createFile(file, content)
        local f = io.open(file, "w")
        f:write(content)
        io.close(f)
    end

    -- Main logic
    if fileExists(filePath) then
        runFile(filePath)
        success, error = pcall(applySettings())
        if not success then
            createFile("quickDodge/errors.txt", error)
        end
    else
        createFile(filePath,
[[    

BACKSTEP_REPLACE_BACKWARDS_DODGE = FALSE -- When dodging backwards, backstep instead.
SPRINTING_R2_ON_BACKSTEP_R2 = TRUE -- When pressing R2 from a backstep, execute the sprinting R2 instead of standing R2.
INSTANT_SPRINTING_FROM_DODGE = TRUE -- If you hold the dodge button from a dodge, you exit it in a sprint.
SPRINTING_ATTACKS_WHILE_HOLDING_DODGE = TRUE -- If you hold the dodge button from a dodge, instead of queueing a dodge attack, you queue a sprinting attack
FAST_DODGE_R2 = TRUE -- When exiting from a dodge, the R2 attack is noticeably faster
FIRST_R1_CHAINS_TO_SECOND_R2 = FALSE -- Your standing R1 chains to your second standing R2 instead of the first standing R2.
DODGE_R1_CHAINS_TO_SECOND_R2 = FALSE
SPRINT_R1_CHAINS_TO_SECOND_R2 = FALSE
BACKSTEP_R1_CHAINS_TO_SECOND_R2 = FALSE
SPRINT_R2_CHAINS_TO_SECOND_R2 = FALSE

DODGE_CANCEL_GRACE_PERIOD = 0.3 -- Measured in seconds. Can dodge cancel out of attacks within the first few seconds here.

CUSTOM_DODGE_CHAIN_TIMING = -1 -- Measured in seconds. If you want to chain a dodge into another dodge, you can set the timing here. -1 means it's disabled.

CUSTOM_WEIGHT_OVERRIDE = -1 -- -1 for inactive, 1 for Light, 2 for Medium, 3 for Heavy, 4 for Overweight
]])
    end
end

Update = createDetour(Update, checkSettings)
