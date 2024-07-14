-- This file should be in your Game folder (usually C:\Program Files (x86)\Steam\steamapps\common\ELDEN RING\Game) + quickDodge. This file path should be C:\Program Files (x86)\Steam\steamapps\common\ELDEN RING\Game\quickDodge\quickDodge.lua

DODGE_INSTANTLY = TRUE -- Dodge when you press the dodge button, not when you release it.
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

-- If you see this message you have the Github version.











-- Function to create a replacement
function createReplacement(originalFunction, newFunction)
    -- Store the original function in the new function's environment
    local original = originalFunction
    -- Create a wrapper that calls the new function first, then the original function
    return function(...)
        -- Call the new function
        return newFunction(...)
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

rawset(_G, "g_EventsLog", { ["CMSG"] = "", ["TIME"] = 0 })

function LogEventsAndTiming(state)
    g_EventsLog["CMSG"] = state
    g_EventsLog["TIME"] = os.clock()
end

ExecEvent = createDetour(ExecEvent, LogEventsAndTiming)

function fixDodges()
    c_RollingAngle = GetVariable("MoveAngle")
    c_ArtsRollingAngle = GetVariable("MoveAngle")
end

GetConstVariable = createPostDetour(GetConstVariable, fixDodges)


rawset(_G, "canUpdateSelf", true)

function checkForUpdates()

    if (env(ActionDuration, ACTION_ARM_SP_MOVE) > 5000) and (env(ActionDuration, ACTION_ARM_R1) > 5000) and (env(ActionDuration, ACTION_ARM_L1) > 5000) and canUpdateSelf then
        updateSelf()
        canUpdateSelf = false
        act(1000, -100000)
    end

end

function updateSelf()
    -- Define the URL of the Lua script to download
    local url = "https://raw.githubusercontent.com/FWang1221/ERDodgeAndOtherShittyThings/master/quickDodge.lua"
    -- Define the command to download the file using curl (cross-platform)
    local download_command = 'curl -o quickDodge//quickDodge.lua ' .. url

    -- Download the Lua script using os.execute
    os.execute(download_command)
end

Update = createDetour(Update, checkForUpdates)

function GetEvasionRequestCustom()

    local dodgeDecider = FALSE

    if DODGE_INSTANTLY == TRUE then
        dodgeDecider = env(ActionRequest, ACTION_ARM_SP_MOVE)
    else
        dodgeDecider = env(ActionRequest, ACTION_ARM_ROLLING)
    end
    if (os.clock() - g_EventsLog["TIME"] < DODGE_CANCEL_GRACE_PERIOD) and (string.find(g_EventsLog["CMSG"], "ttack")) then
        if env(ActionDuration, ACTION_ARM_SP_MOVE) > 0 then
            dodgeDecider = TRUE
        end
    end

    local move_angle = GetVariable("MoveAngle")
    local stick_level = GetVariable("MoveSpeedLevel")


    if env(GetStamina) < STAMINA_MINIMUM then
        return ATTACK_REQUEST_INVALID
    end
    if dodgeDecider == TRUE and stick_level > 0.05 then
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



GetEvasionRequest = createReplacement(GetEvasionRequest, GetEvasionRequestCustom)
if SPRINTING_R2_ON_BACKSTEP_R2 == TRUE then
    DefaultBackStep_onUpdate = createReplacement(DefaultBackStep_onUpdate, DefaultBackStep_onUpdateCustom)
end
if INSTANT_SPRINTING_FROM_DODGE == TRUE or INSTANT_SPRINTING_FROM_DODGE == TRUE then
    Rolling_onUpdate = createReplacement(Rolling_onUpdate, Rolling_onUpdateCustom)
end
if FIRST_R1_CHAINS_TO_SECOND_R2 == TRUE then
    AttackRightLight1_onUpdate = createReplacement(AttackRightLight1_onUpdate, AttackRightLight1_onUpdateCustom)
    AttackBothLight1_onUpdate = createReplacement(AttackBothLight1_onUpdate, AttackBothLight1_onUpdateCustom)
end
if DODGE_R1_CHAINS_TO_SECOND_R2 == TRUE then
    AttackRightLightStep_onUpdate = createReplacement(AttackRightLightStep_onUpdate, AttackRightLightStep_onUpdateCustom)
    AttackBothLightStep_onUpdate = createReplacement(AttackBothLightStep_onUpdate, AttackBothLightStep_onUpdateCustom)
end
if SPRINT_R1_CHAINS_TO_SECOND_R2 == TRUE then
    AttackRightLightDash_onUpdate = createReplacement(AttackRightLightDash_onUpdate, AttackRightLightDash_onUpdateCustom)
    AttackBothDash_onUpdate = createReplacement(AttackBothDash_onUpdate, AttackBothDash_onUpdateCustom)
end
if BACKSTEP_R1_CHAINS_TO_SECOND_R2 == TRUE then
    AttackRightBackstep_onUpdate = createReplacement(AttackRightBackstep_onUpdate, AttackRightBackstep_onUpdateCustom)
    AttackBothBackstep_onUpdate = createReplacement(AttackBothBackstep_onUpdate, AttackBothBackstep_onUpdateCustom)
end
if SPRINT_R2_CHAINS_TO_SECOND_R2 == TRUE then
    AttackRightHeavyDash_onUpdate = createReplacement(AttackRightHeavyDash_onUpdate, AttackRightHeavyDash_onUpdateCustom)
    AttackBothHeavyDash_onUpdate = createReplacement(AttackBothHeavyDash_onUpdate, AttackBothHeavyDash_onUpdateCustom)
end
