-- Modernized Rogue tracking for SuperWOW / TurtleWoW 1.18.1
-- Debuffs and combo points are tracked directly via UnitDebuff and GetComboPoints.
-- Blade Flurry energy regeneration is handled by the server.

local UNIQUE_ROGUE_DEBUFFS = {
    ['Rupture'] = true,
    ['Garrote'] = true,
}

local function updateRogueDebuffs(unit, guid)
    if not guid then return end
    local p = FOSTERFRAMECOREgetPlayer(guid)
    if not p then return end

    for i=1, 40 do
        local name, rank, icon, count, debuffType, duration, expirationTime = UnitDebuff(unit, i)
        if not name then break end
        if UNIQUE_ROGUE_DEBUFFS[name] then
            -- Optional: custom logic to highlight these debuffs on the frame
        end
    end
end
