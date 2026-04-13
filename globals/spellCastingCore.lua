
-- Optimized for SuperWOW / TurtleWoW DLLs
-- Legacy combat log parsing removed

local function convertSuperWOWCast(caster, spellName, icon, startTime, endTime, isChannel, interrupt)
    local v = {}
    v.caster = caster
    v.spell = spellName
    v.icon = icon
    v.timeStart = startTime / 1000
    v.timeEnd = endTime / 1000
    v.inverse = isChannel
    v.borderClr = (interrupt == false) and {.3, .3, .3} or {.1, .1, .1}
    return v
end

-- GLOBAL ACCESS FUNCTIONS
SPELLCASTINGCOREgetCast = function(caster, unit)
    if caster == nil then return nil end
    
    -- In SuperWOW environment, we prioritize direct unit info
    if unit and UnitExists(unit) and FOSTERFRAMESHasSuperWOW() then
        local spell, rank, displayName, icon, startTime, endTime, isStealth, castID, interrupt = UnitCastingInfo(unit)
        if spell then
            return convertSuperWOWCast(caster, spell, icon, startTime, endTime, false, interrupt)
        end
        
        spell, rank, displayName, icon, startTime, endTime, isStealth, interrupt = UnitChannelInfo(unit)
        if spell then
            return convertSuperWOWCast(caster, spell, icon, startTime, endTime, true, interrupt)
        end
    end

    -- If no direct unit ID is provided or SuperWOW info missing, 
    -- we no longer fallback to inaccurate combat log parsing in this version.
    return nil
end

SPELLCASTINGCOREgetHeal = function(target)
    return nil -- Legacy heal tracking removed
end

SPELLCASTINGCOREgetBuffs = function(name, unit)
    local list = {}
    if unit and UnitExists(unit) and FOSTERFRAMESHasSuperWOW() then
        -- Use improved SuperWOW UnitBuff/UnitDebuff if available
        -- Note: FosterFrames UI might need updates to handle this list
        for i=1, 40 do
            local name, rank, icon, count, debuffType, duration, expirationTime = UnitBuff(unit, i)
            if not name then break end
            table.insert(list, {
                ['spell'] = name,
                ['icon'] = icon,
                ['stacks'] = count,
                ['timeEnd'] = expirationTime,
                ['duration'] = duration,
                ['type'] = 'buff'
            })
        end
        for i=1, 40 do
            local name, rank, icon, count, debuffType, duration, expirationTime = UnitDebuff(unit, i)
            if not name then break end
            table.insert(list, {
                ['spell'] = name,
                ['icon'] = icon,
                ['stacks'] = count,
                ['timeEnd'] = expirationTime,
                ['duration'] = duration,
                ['type'] = debuffType
            })
        end
    end
    return list
end

SPELLCASTINGCORErefreshBuff = function(t, b, s)
    -- Legacy logic removed
end

SPELLCASTINGCOREqueueBuff = function(t, s, d)
    return false -- Legacy logic removed
end

SPELLCASTINGCOREaddBuff = function(t, s, d)
    -- Legacy logic removed
end

-- Minimal frame for state management if needed
local f = CreateFrame('Frame', 'spellCastingCore', UIParent)
f:RegisterEvent'PLAYER_ENTERING_WORLD'
f:SetScript('OnEvent', function()
    if event == 'PLAYER_ENTERING_WORLD' then
        -- Reset state if any
    end
end)
