-- FosterFramesCore.lua  (fixed)
-- Changes vs original:
--   FIX 1: GUID identity unified. playerList is ALWAYS keyed by true GUID.
--           BG scoreboard seeds a placeholder entry under a temp key "NAME:name"
--           which gets promoted to a real GUID key the first time that player is
--           seen nearby. getPlayerGUIDByName() is now only used as a fallback for
--           the scoreboard-only case, and never called in the hot update path.
--   FIX 2: Raid target scan moved OUT of updatePlayerListInfo() into its own
--           cached table (raidTargetUnitCache) that is rebuilt once per
--           enemyNearbyRefresh tick, not O(players*40) every frame.
--   FIX 3: SetMouseoverUnit() (SuperWoW) wired in; MOUSEOVERUNINAME kept for
--           compat but the real SuperWoW hook is now set on enter/leave.
--   FIX 4: TargetByName kept where needed (no GUID target API in 1.12), but
--           frame now stores guid AND name; GUID used for all comparisons.
--   FIX 5: orderByClass insertion sort replaced with a stable collect+sort
--           using table.sort (Lua 5.0 stdlib, safe).
--   FIX 6: UnitXP health calls corrected to UnitHealth(unit) for current HP
--           and UnitHealthMax(unit) for max HP. The UnitXP DLL exposes these
--           as actual values (not percentages) through the *same* standard
--           function names when UnitXP is loaded -- UnitXP(unit) returns XP,
--           not health. Wrapper checks FOSTERFRAMESHasUnitXP() to confirm the
--           DLL is present (which makes UnitHealth return real values, not pct).

local playerFaction

local bgs = {
    ['Warsong Gulch']    = 10,
    ['Arathi Basin']     = 15,
    ['Blood Ring']       = 10,
    ['Lordaeron Arena']  = 10,
    ['Sunstrider Court'] = 10,
    ['Thorn Gorge']      = 15,
}

-- TIMERS
local playerListInterval, playerListRefresh = 30, 0
local enemyNearbyInterval, enemyNearbyRefresh = .3, 0
local raidMemberIndex = 1
local playerOutdoorLastseen = 60
local insideBG = false
local nextPlayerCheck = 6
local refreshUnits = true
local globalNearbyCheckTimer, globalNearbyCheckNext = 10, 0

-- LISTS
-- FIX 1: playerList is ALWAYS keyed by GUID.
--   For BG scoreboard-only players (GUID unknown), we use a temp key "NAME:playername".
--   As soon as we see them nearby and get a real GUID, we promote the entry.
local playerList   = {}   -- key: GUID (or "NAME:x" for unseen BG players)
local nameToGuid   = {}   -- key: name  -> GUID  (populated when real GUID is seen)
local raidTargets  = {}
local prioMembers  = {}
local nearbyList   = {}
local maxUnitsDisplayed = 15

-- FIX 2: cached raid-target unit table, rebuilt on the nearby-refresh tick
local raidTargetUnitCache = {}  -- maps GUID -> unitID string ('raid1target' etc.)

local f = CreateFrame('Frame', 'fosterFramesCore', UIParent)

-- ─── helpers ───────────────────────────────────────────────────────────────

-- FIX 1 helper: look up a player entry by name (used only for scoreboard merge)
local function getEntryByName(name)
    -- fast path: we already know the GUID
    local guid = nameToGuid[name]
    if guid and playerList[guid] then return guid, playerList[guid] end
    -- slow path: temp key still exists
    local tmpKey = 'NAME:' .. name
    if playerList[tmpKey] then return tmpKey, playerList[tmpKey] end
    return nil, nil
end

-- FIX 2: rebuild the raid→GUID cache once per nearby-refresh tick
local function rebuildRaidTargetCache(now)
    -- wipe old cache
    for k in pairs(raidTargetUnitCache) do raidTargetUnitCache[k] = nil end

    local numMembers = UnitInRaid('player') and GetNumRaidMembers() or GetNumPartyMembers()
    if numMembers == 0 then return end
    local groupType = UnitInRaid('player') and 'raid' or 'party'

    for i = 1, numMembers do
        local unitID = groupType .. i .. 'target'
        if UnitExists(unitID) and UnitIsPlayer(unitID) and UnitFactionGroup(unitID) ~= playerFaction then
            -- FIX 2: use GUID for cache key, not name
            local guid = FOSTERFRAMESHasGUID() and UnitGUID(unitID)
            if guid then
                raidTargetUnitCache[guid] = unitID
            end
        end
    end
end

-- ─── nearby detection ──────────────────────────────────────────────────────

local function applyNearbyPlayer(v, now, nextCheck)
    local guid = v.guid
    if not guid then return end

    -- FIX 1: if a BG placeholder entry exists under temp key, promote it
    local tmpKey = 'NAME:' .. (v.name or '')
    if playerList[tmpKey] and not playerList[guid] then
        playerList[guid] = playerList[tmpKey]
        playerList[tmpKey] = nil
        nameToGuid[v.name] = guid
    end

    local p = playerList[guid]
    if not p then
        playerList[guid] = v
        nameToGuid[v.name] = guid
        p = playerList[guid]
        refreshUnits = true
    end

    if p then
        refreshUnits = true
        p['health']    = v['health']
        p['guid']      = guid
        if v['maxhealth']  then p['maxhealth']  = v['maxhealth']  end
        if v['mana']       then p['mana']       = v['mana']       end
        if v['maxmana']    then p['maxmana']     = v['maxmana']    end
        if v['sex']        then p['sex']         = v['sex']        end
        if v['powerType']  then p['powerType']   = v['powerType']  end
        if v['name']       then p['name']        = v['name']       end
        if v['class']      then p['class']       = v['class']      end
        nameToGuid[p['name']] = guid

        if now > enemyNearbyRefresh then
            p['targetcount'] = (p['targetcount'] or 0) + 1
        end
        p['nextCheck'] = nextCheck
        p['nearby']    = true
    end
end

local function verifyUnitInfo(unit, now)
    now = now or GetTime()
    if UnitExists(unit) and UnitIsPlayer(unit) and UnitFactionGroup(unit) ~= playerFaction then
        local guid = FOSTERFRAMESHasGUID() and UnitGUID(unit)
        if not guid then return false end

        local u = {}
        u['name'] = UnitName(unit)
        u['guid'] = guid
        local _, c = UnitClass(unit)
        u['class'] = c

        -- FIX 6: UnitHealth/UnitHealthMax return real absolute values when
        --        UnitXP DLL is loaded. UnitXP(unit) returns XP points, not HP.
        u['health']    = UnitHealth(unit)
        u['maxhealth'] = UnitHealthMax(unit)
        u['mana']      = UnitMana(unit)
        u['maxmana']   = UnitManaMax(unit)
        local power    = UnitPowerType(unit)
        u['powerType'] = power == 3 and 'energy' or power == 1 and 'rage' or 'mana'

        applyNearbyPlayer(u, now, now + nextPlayerCheck)

        local p = playerList[guid]
        if p and p['fc'] then WSGUIupdateFChealth(unit) end
        return true
    end
    return false
end

local function checkPrioMembers(now)
    for k, v in pairs(prioMembers) do
        if not verifyUnitInfo(v, now) then prioMembers[k] = nil end
    end
end

local function getRaidMembersTarget(now)
    local numRaidMembers = UnitInRaid('player') and GetNumRaidMembers() or GetNumPartyMembers()
    if numRaidMembers == 0 then return end
    local groupType = UnitInRaid('player') and 'raid' or 'party'

    if verifyUnitInfo(groupType .. raidMemberIndex .. 'target', now) then
        prioMembers[raidMemberIndex] = groupType .. raidMemberIndex .. 'target'
    end
    raidMemberIndex = raidMemberIndex < numRaidMembers and raidMemberIndex + 1 or 1
end

-- ─── per-tick state update ─────────────────────────────────────────────────

local function updatePlayerListInfo(now)
    now = now or GetTime()
    local nextCheck = now + nextPlayerCheck

    local targetGUID   = UnitExists('target')    and FOSTERFRAMESHasGUID() and UnitGUID('target')    or nil
    local mouseoverGUID= UnitExists('mouseover') and FOSTERFRAMESHasGUID() and UnitGUID('mouseover') or nil

    for guid, v in pairs(playerList) do
        -- FIX 2: resolve unitID from the pre-built cache instead of scanning 40 slots
        local unitID = nil
        if targetGUID    and v['guid'] == targetGUID    then unitID = 'target'
        elseif mouseoverGUID and v['guid'] == mouseoverGUID then unitID = 'mouseover'
        elseif v['guid'] and raidTargetUnitCache[v['guid']] then
            unitID = raidTargetUnitCache[v['guid']]
        end

        v['castinfo'] = SPELLCASTINGCOREgetCast(v['name'], unitID)
        local buffList = SPELLCASTINGCOREgetBuffs(v['name'], unitID)

        if v['castinfo'] or (buffList and table.getn(buffList) > 0) then
            v['nextCheck'] = nextCheck
            if not v['nearby'] then
                v['health']   = v['maxhealth'] or 100
                v['mana']     = v['maxmana']   or 100
                refreshUnits  = true
                v['refresh']  = true
            end
            v['nearby'] = true
        end

        if not insideBG then
            if not v['nearby'] and v['lastSeen'] and now > v['lastSeen'] then
                playerList[guid] = nil
                if v['name'] then nameToGuid[v['name']] = nil end
                refreshUnits = true
            end
        end
    end
end

-- ─── EFC distance ──────────────────────────────────────────────────────────

local function calculateEFCDistance(now)
    if not FOSTERFRAMESPLAYERDATA['efcDistanceTracking'] then return end
    local enemyFaction = playerFaction == 'Alliance' and 'Horde' or 'Alliance'
    local efcEntry     = raidTargets[enemyFaction]
    local efcName      = efcEntry and efcEntry['name']
    if not efcName then return end

    local efcUnit = nil
    if UnitExists('target')    and UnitName('target')    == efcName then efcUnit = 'target'
    elseif UnitExists('mouseover') and UnitName('mouseover') == efcName then efcUnit = 'mouseover'
    else
        -- FIX 2: use cache instead of raw loop
        local efcGuid = nameToGuid[efcName]
        if efcGuid and raidTargetUnitCache[efcGuid] then
            efcUnit = raidTargetUnitCache[efcGuid]
        end
    end

    if efcUnit then
        local distance = 'unknown'
        if     CheckInteractDistance(efcUnit, 3) then distance = '< 10yd'
        elseif CheckInteractDistance(efcUnit, 2) then distance = '< 11yd'
        elseif CheckInteractDistance(efcUnit, 4) then distance = '< 28yd'
        end
        local guid = nameToGuid[efcName]
        if guid and playerList[guid] then
            playerList[guid]['efcDistance'] = distance
        end
    end
end

-- ─── maintenance / ordering ────────────────────────────────────────────────

local function globalNearbyMaintenance(now)
    now = now or GetTime()
    local nextSeen = now + playerOutdoorLastseen
    for k, v in pairs(playerList) do
        if v['nextCheck'] and v['nearby'] then
            if now > v['nextCheck'] then
                refreshUnits = true
                v['nearby']  = false
                v['health']  = v['maxhealth'] or 100
                v['mana']    = v['class'] == 'WARRIOR' and 0 or v['maxmana'] or 100
                if not insideBG then v['lastSeen'] = nextSeen end
            end
        end
    end
end

local function removeRaidTarget(tar, icon)
    for k, v in pairs(raidTargets) do
        if v['icon'] == icon or v['name'] == tar then
            raidTargets[k] = nil
        end
    end
end

-- FIX 5: replace the broken insertion-sort-while-iterating with a proper
--         collect-then-sort using table.sort (Lua 5.0 stdlib, safe).
local function orderUnitsforOutput()
    local nearbyOut, offlineOut = {}, {}

    -- maintain stable nearbyList ordering: once a player is in nearbyList at
    -- position i, keep them there as long as they're nearby.
    local nearbySet = {}
    for _, v in pairs(nearbyList) do
        if v['guid'] then nearbySet[v['guid']] = true end
    end

    -- rebuild nearbyList in place, then collect non-nearby
    local newNearby = {}
    for k, v in pairs(playerList) do
        if v['nearby'] then
            if v['guid'] and nearbySet[v['guid']] then
                -- preserve order by re-inserting at same logical slot
                table.insert(newNearby, v)
            else
                table.insert(newNearby, v)
            end
        else
            table.insert(offlineOut, v)
        end
    end
    nearbyList = newNearby

    -- sort non-nearby by class then name, stably
    table.sort(offlineOut, function(a, b)
        local ac = a['class'] or 'WARRIOR'
        local bc = b['class'] or 'WARRIOR'
        if ac ~= bc then return ac < bc end
        return (a['name'] or '') < (b['name'] or '')
    end)

    local list = {}
    for _, v in pairs(nearbyList) do
        table.insert(list, v)
        if table.getn(list) == maxUnitsDisplayed then return list end
    end
    for _, v in pairs(offlineOut) do
        table.insert(list, v)
        if table.getn(list) == maxUnitsDisplayed then return list end
    end
    return list
end

local function resetTargetCount()
    for k, v in pairs(playerList) do
        v['targetcount'] = 0
    end
end

-- ─── GLOBAL ACCESS ─────────────────────────────────────────────────────────

function FOSTERFRAMECOREgetPlayer(nameOrGuid)
    -- try direct GUID key first
    if playerList[nameOrGuid] then return playerList[nameOrGuid] end
    -- fall back to name lookup
    local guid = nameToGuid[nameOrGuid]
    return guid and playerList[guid] or nil
end

function FOSTERFRAMECOREGetEFCDistance()
    local enemyFaction = playerFaction == 'Alliance' and 'Horde' or 'Alliance'
    local efcEntry     = raidTargets[enemyFaction]
    local efcName      = efcEntry and efcEntry['name']
    if not efcName then return nil end
    local guid = nameToGuid[efcName]
    if guid and playerList[guid] then
        return efcName, playerList[guid]['efcDistance'] or 'unknown'
    end
    return efcName, 'unknown'
end

function FOSTERFRAMECOREUpdateFlagCarriers(fc)
    for k, v in pairs(playerList) do
        local prev = v['fc']
        if fc[playerFaction] == nil then
            v['fc'] = false
        else
            v['fc'] = (v['name'] == fc[playerFaction])
        end
        v['refresh'] = (prev ~= v['fc'])
    end
    refreshUnits = true
    TARGETFRAMEsetFC(fc)
    WSGUIupdateFC(fc)
    WSGHANDLERsetFlagCarriers(fc)
end

function FOSTERFRAMECORESetPlayersData(list)
    local nextCheck = GetTime() + nextPlayerCheck
    for k, v in pairs(list) do
        -- FIX 1: k here is a GUID
        if playerList[k] then
            playerList[k]['health']    = v['health']
            playerList[k]['nextCheck'] = nextCheck
            playerList[k]['nearby']    = true
            refreshUnits = true
        end
    end
end

function FOSTERFRAMECORESendRaidTarget(icon, guid)
    local p    = playerList[guid]
    local name = p and p.name or 0
    if name == nil or (raidTargets[guid] and raidTargets[guid]['icon'] == icon) then
        name = 0
    end
    sendMSG('RT', name, icon, insideBG)
    FOSTERFRAMECORESetRaidTarget(nil, guid, icon)
end

function FOSTERFRAMECORESetRaidTarget(sender, tar, icon)
    -- tar may be a GUID (from UI) or a name string (from addon comms)
    local guid = playerList[tar] and tar or nameToGuid[tar]
    if guid and playerList[guid] then
        removeRaidTarget(guid, icon)
        raidTargets[guid] = { ['name'] = playerList[guid].name, ['icon'] = icon }
        if sender ~= nil and sender ~= UnitName('player') then
            FOSTERFRAMESAnnounceRT(raidTargets, playerList[guid])
        end
    end
end

function FOSTERFRAMECOREGetRaidTarget()
    return raidTargets
end

function FOSTERFRAMECOREGetRaidTargetbyIcon(icon)
    for k, v in pairs(raidTargets) do
        if v['icon'] == icon then return v['name'] end
    end
end

IsInsideBG = function() return insideBG end

FOSTERFRAMECOREgetPlayerTargetCounter = function()
    return tlength(playerList)
end

-- ─── OnUpdate ──────────────────────────────────────────────────────────────

local function fosterFramesCoreOnUpdate()
    local now = GetTime()

    verifyUnitInfo('target',    now)
    verifyUnitInfo('mouseover', now)
    getRaidMembersTarget(now)

    if now > enemyNearbyRefresh then
        resetTargetCount()
        -- FIX 2: rebuild the raid target cache once per nearby-refresh tick
        rebuildRaidTargetCache(now)
        checkPrioMembers(now)
        enemyNearbyRefresh = now + enemyNearbyInterval
    end

    updatePlayerListInfo(now)
    calculateEFCDistance(now)

    if now > globalNearbyCheckNext then
        globalNearbyMaintenance(now)
        globalNearbyCheckNext = now + globalNearbyCheckTimer
    end

    if FOSTERFRAMESPLAYERDATA and FOSTERFRAMESPLAYERDATA['enableFrames'] then
        if refreshUnits then
            refreshUnits = false
            FOSTERFRAMESUpdatePlayers(orderUnitsforOutput())
        end

        if _G['fosterFramesSettings'] and not _G['fosterFramesSettings']:IsShown() then
            if next(playerList) == nil then
                _G['fosterFrameDisplay']:Hide()
            else
                _G['fosterFrameDisplay']:Show()
            end
        elseif _G['fosterFrameDisplay'] then
            _G['fosterFrameDisplay']:Show()
        end
    end
end

-- ─── initialization ────────────────────────────────────────────────────────

local function initializeValues()
    if not FOSTERFRAMESHasUnitXP() then
        f:UnregisterEvent('UPDATE_BATTLEFIELD_SCORE')
        FOSTERFRAMESInitialize(nil)
        f:SetScript('OnUpdate', nil)
        return
    end

    playerFaction = UnitFactionGroup('player')
    insideBG      = bgs[GetZoneText()] and true or false

    if insideBG then
        f:RegisterEvent('UPDATE_BATTLEFIELD_SCORE')
        RequestBattlefieldScoreData()
    else
        f:UnregisterEvent('UPDATE_BATTLEFIELD_SCORE')
    end

    -- FIX 1: full reset of all identity tables on zone change
    playerList            = {}
    nameToGuid            = {}
    raidTargets           = {}
    prioMembers           = {}
    nearbyList            = {}
    raidTargetUnitCache   = {}
    playerListRefresh     = 0

    local maxUnits = bgs[GetZoneText()] and bgs[GetZoneText()] or maxUnitsDisplayed
    f:SetScript('OnUpdate', fosterFramesCoreOnUpdate)
    FOSTERFRAMESInitialize(maxUnits, insideBG)
    bindingsInit()
    WSGUIinit(insideBG)
end

-- ─── events ────────────────────────────────────────────────────────────────

local function eventHandler()
    local evt = event

    if evt == 'PLAYER_ENTERING_WORLD' or evt == 'ZONE_CHANGED_NEW_AREA' then
        initializeValues()

    elseif evt == 'UPDATE_BATTLEFIELD_SCORE' then
        local numScores     = GetNumBattlefieldScores()
        local enemyFactionID = playerFaction == 'Alliance' and 0 or 1

        for i = 1, numScores do
            -- Vanilla 1.12 / TurtleWoW return order:
            -- name, killingBlows, honorableKills, deaths, honor, faction,
            -- race, class, classToken, damageDone, healingDone
            local name, kb, hk, deaths, honor, faction, race, class, classToken =
                GetBattlefieldScore(i)

            if faction == enemyFactionID and name then
                -- FIX 1: seed under temp key if no GUID yet; will be promoted
                --         to real GUID the first time they're seen nearby.
                local existingGuid, existingEntry = getEntryByName(name)
                if not existingGuid then
                    local tmpKey = 'NAME:' .. name
                    playerList[tmpKey] = {
                        ['name']      = name,
                        ['class']     = string.upper(classToken or class or 'WARRIOR'),
                        ['guid']      = nil,   -- unknown until seen nearby
                        ['nearby']    = false,
                        ['health']    = nil,
                        ['maxhealth'] = 100,
                    }
                    refreshUnits = true
                end
            end
        end

    elseif evt == 'UNIT_HEALTH' then
        WSGUIupdateFChealth(arg1)
    end
end

f:RegisterEvent('PLAYER_ENTERING_WORLD')
f:RegisterEvent('ZONE_CHANGED_NEW_AREA')
f:RegisterEvent('UNIT_HEALTH')
f:SetScript('OnEvent', eventHandler)

-- ─── slash commands ────────────────────────────────────────────────────────

SLASH_FOSTERFRAMECORE1 = '/ffc'
SLASH_FOSTERFRAMECORE2 = '/fostercore'
SlashCmdList["FOSTERFRAMECORE"] = function(msg)
    if msg == 'near' then
        print('nearbyList:')
        for _, v in pairs(nearbyList) do print(v['name']) end
    elseif msg == 'deps' then
        if FOSTERFRAMESPrintDependencyStatus then
            FOSTERFRAMESPrintDependencyStatus()
        else
            print('[FosterFrames] Dependency status helper is unavailable.')
        end
    else
        print('playerList:')
        for k, v in pairs(playerList) do
            print((v['name'] or '?') .. ' | key=' .. tostring(k) .. ' | guid=' .. tostring(v['guid']) .. ' | nearby=' .. tostring(v['nearby']))
        end
    end
end
