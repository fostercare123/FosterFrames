-- Modernized Shaman tracking for SuperWOW / TurtleWoW 1.18.1
local SHIELDS = {
    ['Water Shield'] = true,
    ['Lightning Shield'] = true,
    ['Earth Shield'] = true, -- TurtleWoW
}

local function updateShamanShields(unit, guid)
    if not guid then return end
    local p = FOSTERFRAMECOREgetPlayer(guid)
    if not p then return end

    local foundShield = false
    for i=1, 40 do
        local name, rank, icon = UnitBuff(unit, i)
        if not name then break end
        if SHIELDS[name] then
            p.activeShield = name
            foundShield = true
            break
        end
    end
    if not foundShield then p.activeShield = nil end
end
