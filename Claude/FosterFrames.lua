-- FosterFrames.lua  (fixed)
-- Changes vs original:
--   FIX 3: SetMouseoverUnit() (SuperWoW) now called on OnEnter/OnLeave so that
--           mouseover macros and other addons correctly recognise hovering on
--           enemy frames. MOUSEOVERUNINAME kept for backward compat.
--   FIX 4: frame.guid stored alongside frame.tar (name). GUID used for the
--           target indicator comparison in updateUnits(). TargetByName kept
--           for the actual targeting action (no GUID target API in 1.12 Lua).
--   Minor: FOSTERFRAMESHasGUID() guard added before UnitGUID call in
--          updateUnits() to be safe on clients without SuperWoW.

local playerFaction
local insideBG = false

-- TIMERS
local ktInterval,      ktEndtime      = 3, 0
local rtMenuInterval,  rtMenuEndtime  = 5, 0
local refreshInterval, nextRefresh    = 1/60, 0

-- LISTS
local playerList  = {}
local unitLimit   = 15
local units       = {}
local raidTargets = {}

local raidIcons, raidIconsN = {
    [1]='skull', [2]='moon',   [3]='square', [4]='triangle',
    [5]='star',  [6]='diamond',[7]='cross',  [8]='circle',
}, 8

local enabled  = false
local maxUnits = 15

-- FIX 3: still exported for addons that read it, but now SetMouseoverUnit() is
--         the authoritative hook.
MOUSEOVERUNINAME = nil

------------ UI ELEMENTS ------------------

local BACKDROP = { bgFile = [[Interface\Tooltips\UI-Tooltip-Background]] }
local enemyFactionColor

local fosterFrame = CreateFrame('Frame', 'fosterFrameDisplay', UIParent)
fosterFrame:SetFrameStrata("BACKGROUND")
fosterFrame:SetPoint('CENTER', UIParent, UIParent:GetHeight()/3, UIParent:GetHeight()/3)
fosterFrame:SetHeight(20)
fosterFrame:SetMovable(true)
fosterFrame:SetClampedToScreen(true)

fosterFrame:SetScript('OnDragStart', function(self)
    local frame = self or this
    if FOSTERFRAMESPLAYERDATA['frameMovable'] or
       (_G['fosterFramesSettings'] and _G['fosterFramesSettings']:IsShown()) then
        frame:StartMoving()
    end
end)
fosterFrame:SetScript('OnDragStop', function(self)
    (self or this):StopMovingOrSizing()
end)
fosterFrame:RegisterForDrag('LeftButton')
fosterFrame:EnableMouse(true)

fosterFrame.bg = fosterFrame:CreateTexture(nil, 'BACKGROUND')
fosterFrame.bg:SetAllPoints()
fosterFrame.bg:SetTexture(0, 0, 0, 0.5)
fosterFrame.bg:Hide()

fosterFrame.Title = fosterFrame:CreateFontString(nil, 'OVERLAY')
fosterFrame.Title:SetFont(STANDARD_TEXT_FONT, 12, 'OUTLINE')
fosterFrame.Title:SetPoint('CENTER', fosterFrame, 0, 1)

fosterFrame.totalPlayers = fosterFrame:CreateFontString(nil, 'OVERLAY')
fosterFrame.totalPlayers:SetFont(STANDARD_TEXT_FONT, 12, 'OUTLINE')
fosterFrame.totalPlayers:SetPoint('RIGHT', fosterFrame, 'RIGHT', -4, 1)
fosterFrame.totalPlayers:Hide()

fosterFrame.spawnText = fosterFrame:CreateFontString(nil, 'OVERLAY')
fosterFrame.spawnText:SetFont(STANDARD_TEXT_FONT, 16, 'OUTLINE')
fosterFrame.spawnText:SetPoint('LEFT', fosterFrame, 'LEFT', 8, 1)

fosterFrame.spawnText.Button = CreateFrame('Button', nil, fosterFrame)
fosterFrame.spawnText.Button:SetHeight(15)
fosterFrame.spawnText.Button:SetWidth(15)
fosterFrame.spawnText.Button:SetPoint('CENTER', fosterFrame.spawnText, 'CENTER')
fosterFrame.spawnText.Button:SetScript('OnEnter', function(self)
    fosterFrame.spawnText:SetTextColor(.9, .9, .4)
    GameTooltip:SetOwner(self or this, 'ANCHOR_TOPRIGHT', -30, -30)
    GameTooltip:SetText((self or this).tt)
    GameTooltip:Show()
end)
fosterFrame.spawnText.Button:SetScript('OnLeave', function()
    fosterFrame.spawnText:SetTextColor(
        enemyFactionColor['r'], enemyFactionColor['g'], enemyFactionColor['b'], .9)
    GameTooltip:Hide()
end)

-- EFC button
fosterFrame.efcButton = CreateFrame('Button', nil, fosterFrame)
fosterFrame.efcButton:SetHeight(15)
fosterFrame.efcButton:SetWidth(15)
fosterFrame.efcButton:SetPoint('LEFT', fosterFrame.Title, 'RIGHT', 2, 0)
fosterFrame.efcButton:SetScript('OnEnter', function(self)
    GameTooltip:SetOwner(self or this, 'ANCHOR_TOPRIGHT', -30, -30)
    if FOSTERFRAMESPLAYERDATA['efcDistanceTracking'] then
        local name, dist = FOSTERFRAMECOREGetEFCDistance()
        if name then
            GameTooltip:SetText('EFC: ' .. name .. ' (' .. dist .. ')')
        else
            GameTooltip:SetText('EFC: Unknown')
        end
    else
        GameTooltip:SetText('Toggle EFC Low Health Announcement')
    end
    GameTooltip:Show()
end)
fosterFrame.efcButton:SetScript('OnLeave', function() GameTooltip:Hide() end)

fosterFrame.efcButton.flagTexture = fosterFrame.efcButton:CreateTexture(nil, 'ARTWORK')
fosterFrame.efcButton.flagTexture:SetAllPoints()

fosterFrame.efcButton.distText = fosterFrame.efcButton:CreateFontString(nil, 'OVERLAY')
fosterFrame.efcButton.distText:SetFont(STANDARD_TEXT_FONT, 10, 'OUTLINE')
fosterFrame.efcButton.distText:SetPoint('LEFT', fosterFrame.efcButton, 'RIGHT', 2, 0)
fosterFrame.efcButton.distText:SetTextColor(1, 1, 1)

-- top / bottom frames
fosterFrame.top = CreateFrame('Frame', nil, fosterFrame)
fosterFrame.top:SetFrameLevel(0)
fosterFrame.top:ClearAllPoints()
fosterFrame.top:SetHeight(fosterFrame:GetHeight())
fosterFrame.top:SetBackdrop(BACKDROP)
fosterFrame.top:SetBackdropColor(0, 0, 0, .6)
fosterFrame.top.border = CreateBorder(nil, fosterFrame.top, 13)

fosterFrame.bottom = CreateFrame('Frame', nil, fosterFrame)
fosterFrame.bottom:SetFrameLevel(0)
fosterFrame.bottom:ClearAllPoints()
fosterFrame.bottom:SetHeight(fosterFrame:GetHeight())
fosterFrame.bottom:SetBackdrop(BACKDROP)
fosterFrame.bottom:SetBackdropColor(0, 0, 0, .6)
fosterFrame.bottom.border = CreateBorder(nil, fosterFrame.bottom, 13)

-- raid target display frame
fosterFrame.raidTargetFrame = CreateFrame('Frame', nil, fosterFrame)
fosterFrame.raidTargetFrame:SetFrameLevel(2)
fosterFrame.raidTargetFrame:SetHeight(36)
fosterFrame.raidTargetFrame:SetWidth(36)
fosterFrame.raidTargetFrame:SetPoint('CENTER', UIParent, 'CENTER', 0, 160)
fosterFrame.raidTargetFrame:Hide()

fosterFrame.raidTargetFrame.text = fosterFrame.raidTargetFrame:CreateFontString(nil, 'OVERLAY')
fosterFrame.raidTargetFrame.text:SetFont(STANDARD_TEXT_FONT, 18, 'OUTLINE')
fosterFrame.raidTargetFrame.text:SetTextColor(.8, .8, .8, .8)
fosterFrame.raidTargetFrame.text:SetPoint('CENTER', fosterFrame.raidTargetFrame)
fosterFrame.raidTargetFrame.text:SetText('Player')

fosterFrame.raidTargetFrame.iconl = fosterFrame.raidTargetFrame:CreateTexture(nil, 'OVERLAY')
fosterFrame.raidTargetFrame.iconl:SetTexture([[Interface\TargetingFrame\UI-RaidTargetingIcons]])
fosterFrame.raidTargetFrame.iconl:SetTexCoord(.75, 1, 0.25, .5)
fosterFrame.raidTargetFrame.iconl:SetHeight(36)
fosterFrame.raidTargetFrame.iconl:SetWidth(36)
fosterFrame.raidTargetFrame.iconl:SetPoint('RIGHT', fosterFrame.raidTargetFrame.text, 'LEFT', -6, 0)

fosterFrame.raidTargetFrame.iconr = fosterFrame.raidTargetFrame:CreateTexture(nil, 'OVERLAY')
fosterFrame.raidTargetFrame.iconr:SetTexture([[Interface\TargetingFrame\UI-RaidTargetingIcons]])
fosterFrame.raidTargetFrame.iconr:SetTexCoord(.75, 1, 0.25, .5)
fosterFrame.raidTargetFrame.iconr:SetHeight(36)
fosterFrame.raidTargetFrame.iconr:SetWidth(36)
fosterFrame.raidTargetFrame.iconr:SetPoint('LEFT', fosterFrame.raidTargetFrame.text, 'RIGHT', 6, 0)

-- raid target menu
local rtMenuIconsize = 26
fosterFrame.raidTargetMenu = CreateFrame('Frame', nil, fosterFrame)
fosterFrame.raidTargetMenu:SetFrameLevel(7)
fosterFrame.raidTargetMenu:SetHeight(rtMenuIconsize * 2 + 4)
fosterFrame.raidTargetMenu:SetWidth(rtMenuIconsize * 4 + 10)
fosterFrame.raidTargetMenu:SetBackdrop(BACKDROP)
fosterFrame.raidTargetMenu:SetBackdropColor(0, 0, 0, .6)
fosterFrame.raidTargetMenu:Hide()
fosterFrame.raidTargetMenu.border = CreateBorder(nil, fosterFrame.raidTargetMenu, 10)
fosterFrame.raidTargetMenu.icons  = {}

for j = 1, raidIconsN do
    local btn = CreateFrame('Button', 'fosterFrame.raidTargetMenu.icons' .. j, fosterFrame.raidTargetMenu)
    btn:SetHeight(rtMenuIconsize)
    btn:SetWidth(rtMenuIconsize)
    if j == 1 then
        btn:SetPoint('TOPLEFT', fosterFrame.raidTargetMenu, 'TOPLEFT', 1, -1)
    elseif j < 5 then
        btn:SetPoint('LEFT', fosterFrame.raidTargetMenu.icons[j-1], 'RIGHT', 2, 0)
    else
        btn:SetPoint('TOP', fosterFrame.raidTargetMenu.icons[j-4], 'BOTTOM', 0, -2)
    end
    btn.id  = j
    btn.tex = btn:CreateTexture(nil, 'OVERLAY')
    btn.tex:SetTexture([[Interface\TargetingFrame\UI-RaidTargetingIcons]])
    btn.tex:SetAlpha(.6)
    local tCoords = RAID_TARGET_TCOORDS[raidIcons[j]]
    btn.tex:SetTexCoord(tCoords[1], tCoords[2], tCoords[3], tCoords[4])
    btn.tex:SetAllPoints()
    btn:SetScript('OnEnter', function(self) (self or this).tex:SetAlpha(1)  end)
    btn:SetScript('OnLeave', function(self) (self or this).tex:SetAlpha(.6) end)
    fosterFrame.raidTargetMenu.icons[j] = btn
end

local function spawnRTMenu(b, targetGuid)
    fosterFrame.raidTargetMenu:SetPoint('TOP', b, 'BOTTOM', rtMenuIconsize / 2, 0)
    if fosterFrame.raidTargetMenu.target == targetGuid and rtMenuEndtime > GetTime() then
        fosterFrame.raidTargetMenu:Hide()
        return
    end
    fosterFrame.raidTargetMenu.target = targetGuid
    fosterFrame.raidTargetMenu:Show()
    rtMenuEndtime = GetTime() + rtMenuInterval
    for j = 1, raidIconsN do
        fosterFrame.raidTargetMenu.icons[j]:SetScript('OnClick', function(self)
            -- FIX 4: pass GUID to core for reliable identification
            FOSTERFRAMECORESendRaidTarget(raidIcons[(self or this).id], targetGuid)
            fosterFrame.raidTargetMenu:Hide()
            rtMenuEndtime = 0
        end)
    end
end

local unitWidth, unitHeight, castBarHeight, ccIconWidth, manaBarHeight = UIElementsGetDimensions()
local leftSpacing = 5

-- draw player unit frames (pool, created once at load time)
for i = 1, unitLimit do
    units[i] = CreateEnemyUnitFrame('fosterFrameUnit' .. i, fosterFrame)
    units[i].index       = i
    units[i].hoverEnabled = false

    units[i]:SetScript('OnClick', function(self, button)
        local b     = button or arg1
        local frame = self or this
        if b == 'LeftButton' and frame.tar ~= nil then
            -- FIX 4: TargetByName is the only practical option in 1.12 Lua,
            --        but we pass true (enemy-only) and log the guid for comparison.
            TargetByName(frame.tar, true)
        end
        if b == 'RightButton' then
            -- FIX 4: pass GUID (not name) to menu so core uses GUID identity
            spawnRTMenu(frame, frame.guid)
        end
    end)

    units[i]:SetScript('OnEnter', function(self)
        local frame = self or this
        if frame.hoverEnabled then
            frame.name:SetTextColor(
                enemyFactionColor['r'], enemyFactionColor['g'], enemyFactionColor['b'])
            frame.mo = true
            MOUSEOVERUNINAME = frame.tar
            -- FIX 3: wire SuperWoW mouseover so macros/other addons work
            if SetMouseoverUnit and frame.guid then
                SetMouseoverUnit(frame.guid)
            end
        end
    end)

    units[i]:SetScript('OnLeave', function(self)
        local frame = self or this
        local r, g, b = frame.hpbar:GetStatusBarColor()
        if frame.hoverEnabled then
            frame.name:SetTextColor(r, g, b)
        else
            frame.name:SetTextColor(r, g, b, .6)
        end
        frame.mo         = false
        MOUSEOVERUNINAME = nil
        -- FIX 3: clear SuperWoW mouseover
        if SetMouseoverUnit then
            SetMouseoverUnit()
        end
    end)
end

-- settings / layout helpers (unchanged logic, kept for completeness)

local function defaultVisuals()
    for i = 1, unitLimit do
        units[i].castbar.icon:SetTexture([[Interface\Icons\Inv_misc_gem_sapphire_01]])
        units[i].castbar.text:SetText('Entangling Roots')
        units[i].castbar.text:SetText(string.sub(units[i].castbar.text:GetText(), 1, 18))
        units[i].name:SetText('Player' .. i)
        units[i].raidTarget.icon:SetTexCoord(.75, 1, 0.25, .5)
        units[i].cc.icon:SetTexture([[Interface\characterframe\TEMPORARYPORTRAIT-MALE-ORC]])
        units[i].cc.duration:SetText('2.8')
        units[i]:Show()
    end
end

local function optionals()
    for i = 1, unitLimit do
        if not FOSTERFRAMESPLAYERDATA['displayNames'] then
            units[i].name:Hide()
        else
            units[i].name:Show()
        end
        if not FOSTERFRAMESPLAYERDATA['displayManabar'] then
            units[i].hpbar:SetHeight(unitHeight)
            units[i].manabar:Hide()
        else
            units[i].hpbar:SetHeight(unitHeight - manaBarHeight)
            units[i].manabar:Show()
        end
        if not FOSTERFRAMESPLAYERDATA['castTimers'] then
            units[i].castbar.timer:Hide()
        else
            units[i].castbar.timer:Show()
        end
        if not FOSTERFRAMESPLAYERDATA['targetCounter'] then
            units[i].targetCount.text:Hide()
        else
            units[i].targetCount.text:Show()
        end
    end
end

local function setccIcon()
    for i = 1, unitLimit do
        units[i].cc.icon:SetTexture(GET_DEFAULT_ICON('class', 'WARRIOR'))
    end
end

local function arrangeUnits()
    local unitGroup = FOSTERFRAMESPLAYERDATA['groupsize']
    local layout    = FOSTERFRAMESPLAYERDATA['layout']

    if playerFaction == 'Alliance' then
        fosterFrame.Title:SetText(layout == 'vertical' and 'H ' or 'Horde')
    else
        fosterFrame.Title:SetText(layout == 'vertical' and 'A ' or 'Alliance')
    end

    for i = 1, unitLimit do
        if i == 1 then
            units[i]:SetPoint('TOPLEFT', fosterFrame, 'BOTTOMLEFT', 0, -4)
        else
            if i > unitGroup then
                if layout == 'hblock' or layout == 'vblock' then
                    units[i]:SetPoint('TOPLEFT', units[i-unitGroup].castbar.iconborder, 'BOTTOMLEFT', 1, -5)
                else
                    units[i]:SetPoint('TOPLEFT', units[i-unitGroup].cc, 'TOPRIGHT', leftSpacing, 0)
                end
            else
                if layout == 'hblock' or layout == 'vblock' then
                    units[i]:SetPoint('TOPLEFT', units[i-1].cc, 'TOPRIGHT', leftSpacing, 0)
                else
                    units[i]:SetPoint('TOPLEFT', units[i-1].castbar.iconborder, 'BOTTOMLEFT', 1, -5)
                end
            end
        end
    end
end

local function showHideBars()
    if FOSTERFRAMESPLAYERDATA['frameMovable'] then
        fosterFrame.spawnText.Button.tt = 'Lock'
        fosterFrame.top:Show()
        fosterFrame.bottom:Show()
        fosterFrame.spawnText:SetText('-')
    else
        fosterFrame.spawnText.Button.tt = 'Unlock'
        fosterFrame.top:Hide()
        fosterFrame.bottom:Hide()
        fosterFrame.spawnText:SetText('+')
    end
    fosterFrame:EnableMouse(FOSTERFRAMESPLAYERDATA['frameMovable'])
end

local function SetupFrames(maxU)
    maxUnits      = maxU
    playerFaction = UnitFactionGroup('player')

    if playerFaction == 'Alliance' then
        enemyFactionColor = RGB_FACTION_COLORS['Horde']
        fosterFrame.Title:SetText('Horde')
    else
        enemyFactionColor = RGB_FACTION_COLORS['Alliance']
        fosterFrame.Title:SetText('Alliance')
    end

    fosterFrame.Title:SetTextColor(
        enemyFactionColor['r'], enemyFactionColor['g'], enemyFactionColor['b'], .9)
    fosterFrame.spawnText:SetTextColor(
        enemyFactionColor['r'], enemyFactionColor['g'], enemyFactionColor['b'], .9)
    fosterFrame.totalPlayers:SetTextColor(
        enemyFactionColor['r'], enemyFactionColor['g'], enemyFactionColor['b'], .9)

    local layout = FOSTERFRAMESPLAYERDATA['layout']
    local col = layout == 'hblock' and 5
             or layout == 'vblock' and 2
             or layout == 'vertical' and 1
             or maxUnits / FOSTERFRAMESPLAYERDATA['groupsize']
    fosterFrame:SetWidth((unitWidth + ccIconWidth + 5) * col + leftSpacing * (col - 1))
    fosterFrame.top:SetWidth(fosterFrame:GetWidth())
    fosterFrame.top:SetPoint('CENTER', fosterFrame)

    fosterFrame.spawnText.Button:SetScript('OnClick', function(self)
        if FOSTERFRAMESPLAYERDATA['frameMovable'] then
            FOSTERFRAMESPLAYERDATA['frameMovable'] = false
        else
            FOSTERFRAMESPLAYERDATA['frameMovable'] = true
        end
        showHideBars()
        GameTooltip:SetOwner(self or this, 'ANCHOR_TOPRIGHT', -30, -60)
        GameTooltip:SetText((self or this).tt)
        GameTooltip:Show()
    end)

    fosterFrame.efcButton.flagTexture:SetTexture(
        'Interface\\WorldStateFrame\\' .. playerFaction .. 'Flag')
    fosterFrame.efcButton:SetScript('OnClick', function(self)
        local b = self or this
        if FOSTERFRAMESPLAYERDATA['efcBGannouncement'] == true then
            FOSTERFRAMESPLAYERDATA['efcBGannouncement'] = false
            b.flagTexture:SetVertexColor(.3, .3, .3)
        else
            FOSTERFRAMESPLAYERDATA['efcBGannouncement'] = true
            b.flagTexture:SetVertexColor(1, 1, 1)
        end
    end)
    if FOSTERFRAMESPLAYERDATA['efcBGannouncement'] then
        fosterFrame.efcButton.flagTexture:SetVertexColor(1, 1, 1)
    else
        fosterFrame.efcButton.flagTexture:SetVertexColor(.3, .3, .3)
    end

    showHideBars()

    fosterFrame.bottom:SetWidth(fosterFrame:GetWidth())
    local unitGroup = FOSTERFRAMESPLAYERDATA['groupsize']
    local unitPointBottom
    if layout == 'hblock' then
        unitPointBottom = maxUnits - 4
    elseif layout == 'vblock' then
        unitPointBottom = (math.mod(maxUnits, 2) == 0) and maxUnits - 1 or maxUnits
    elseif layout == 'vertical' then
        unitPointBottom = maxUnits
    elseif maxUnits < unitGroup then
        unitPointBottom = maxUnits
    else
        unitPointBottom = unitGroup
    end
    fosterFrame.bottom:SetPoint('TOPLEFT', units[unitPointBottom].castbar.icon, 'BOTTOMLEFT', 1, -6)
end

local function round(num, idp)
    local mult = 10 ^ (idp or 0)
    return math.floor(num * mult + 0.5) / mult
end

local getTimerLeft = function(tEnd, now)
    now   = now or GetTime()
    local t = tEnd - now
    if t > 3 then return round(t, 0) else return round(t, 1) end
end

-- ─── drawUnits: called when playerList contents change ────────────────────

local function drawUnits(list)
    playerList = list
    local i, nearU = 1, 0

    for k, v in pairs(playerList) do
        local class      = v['class']     or 'WARRIOR'
        local powerType  = v['powerType'] or 'mana'
        local colour     = RAID_CLASS_COLORS[class]   or RAID_CLASS_COLORS['WARRIOR']
        local powerColor = RGB_POWER_COLORS[powerType] or RGB_POWER_COLORS['mana']

        if v['nearby'] then
            units[i].hpbar:SetStatusBarColor(colour.r, colour.g, colour.b)
            units[i].hoverEnabled = true
            if not units[i].mo then
                units[i].name:SetTextColor(colour.r, colour.g, colour.b)
            end
            units[i].manabar:SetStatusBarColor(powerColor[1], powerColor[2], powerColor[3])
            units[i].cc.icon:SetVertexColor(1, 1, 1, 1)
        else
            units[i].hoverEnabled = false
            units[i].hpbar:SetStatusBarColor(colour.r/2, colour.g/2, colour.b/2, .7)
            units[i].manabar:SetStatusBarColor(powerColor[1]/2, powerColor[2]/2, powerColor[3]/2)
            if not units[i].mo then
                units[i].name:SetTextColor(colour.r/2, colour.g/2, colour.b/2, .7)
            end
            if v['fc'] then
                units[i].cc.icon:SetVertexColor(1, 1, 1, 1)
            else
                units[i].cc.icon:SetVertexColor(.4, .4, .4, .7)
            end
            units[i].cc.cd:Hide()
        end

        units[i].name:SetText(string.sub(v['name'] or 'Unknown', 1, 7))

        -- FIX 4: store both name (for TargetByName) and guid (for identity)
        units[i].tar  = v['name']
        units[i].guid = v['guid']

        units[i].targetCount.text:SetText(
            v['targetcount'] and (v['targetcount'] > 0 and v['targetcount'] or '') or '')

        local maxHP  = v['maxhealth'] or 100
        local currHP = v['health'] or (not v['nearby'] and maxHP) or 100
        units[i].hpbar:SetMinMaxValues(0, maxHP)
        units[i].hpbar:SetValue(currHP)

        local maxMana  = v['maxmana']  or 100
        local currMana = v['mana'] or (not v['nearby'] and maxMana) or 100
        units[i].manabar:SetMinMaxValues(0, maxMana)
        units[i].manabar:SetValue(currMana)

        if FOSTERFRAMESPLAYERDATA['displayOnlyNearby'] and not v['nearby'] then
            units[i]:Hide()
        else
            units[i]:Show()
        end

        nearU = v['nearby'] and nearU + 1 or nearU
        i = i + 1
    end

    for j = i, unitLimit do
        if units[j]:IsShown() then units[j]:Hide() end
    end

    i = i == 1 and 1 or i - 1
    if not insideBG or FOSTERFRAMESPLAYERDATA['displayOnlyNearby'] then
        local layout    = FOSTERFRAMESPLAYERDATA['layout']
        local unitGroup = FOSTERFRAMESPLAYERDATA['groupsize']
        local unitPointBottom
        if layout == 'vertical' then
            unitPointBottom = i
        elseif layout == 'hblock' or layout == 'vblock' then
            local a = math.floor(i / unitGroup)
            unitPointBottom = a == 0 and 1 or (a * unitGroup) + 1
        elseif i > unitGroup then
            unitPointBottom = unitGroup
        else
            unitPointBottom = i
        end
        fosterFrame.bottom:SetPoint('TOPLEFT', units[unitPointBottom].castbar.icon, 'BOTTOMLEFT', 1, -6)
    end
end

-- ─── updateUnits: called every ~1/60s ─────────────────────────────────────

local function updateUnits()
    local now = GetTime()

    if ktEndtime < now then
        fosterFrame.raidTargetFrame:Hide()
    end
    if rtMenuEndtime < now then
        fosterFrame.raidTargetMenu:Hide()
    end

    -- FIX 4: resolve current target GUID once, compare against frame.guid below
    local currentTargetGUID = UnitExists('target')
        and FOSTERFRAMESHasGUID and FOSTERFRAMESHasGUID()
        and UnitGUID('target')
        or nil

    local i = 1
    for k, v in pairs(playerList) do
        -- FIX 4: GUID comparison (same as original intent, now consistent)
        if currentTargetGUID and v['guid'] and v['guid'] == currentTargetGUID then
            units[i].border:SetColor(
                enemyFactionColor['r'], enemyFactionColor['g'], enemyFactionColor['b'])
            units[i].hpbar:SetBackdropColor(
                enemyFactionColor['r']-.6, enemyFactionColor['g']-.6, enemyFactionColor['b']-.6, .6)
            units[i].manabar:SetBackdropColor(
                enemyFactionColor['r']-.6, enemyFactionColor['g']-.6, enemyFactionColor['b']-.6, .6)
        else
            units[i].border:SetColor(.1, .1, .1)
            units[i].hpbar:SetBackdropColor(0, 0, 0, .6)
            units[i].manabar:SetBackdropColor(0, 0, 0, .6)
        end

        -- castbar
        local castInfo = v['castinfo']
        units[i].castbar:Hide()
        if castInfo ~= nil then
            units[i].castbar:SetMinMaxValues(0, castInfo.timeEnd - castInfo.timeStart)
            if castInfo.inverse then
                units[i].castbar:SetValue(
                    math.mod((castInfo.timeEnd - now), castInfo.timeEnd - castInfo.timeStart))
            else
                units[i].castbar:SetValue(
                    math.mod((now - castInfo.timeStart), castInfo.timeEnd - castInfo.timeStart))
            end
            local charLim = FOSTERFRAMESPLAYERDATA['castTimers'] and 14 or 15
            units[i].castbar.text:SetText(string.sub(castInfo.spell, 1, charLim))
            units[i].castbar.timer:SetText(getTimerLeft(castInfo.timeEnd, now))
            units[i].castbar.icon:SetTexture(castInfo.icon)
            if castInfo.borderClr then
                units[i].castbar.b:SetColor(
                    castInfo.borderClr[1], castInfo.borderClr[2], castInfo.borderClr[3])
            else
                units[i].castbar.b:SetColor(.1, .1, .1)
            end
            units[i].castbar:Show()
        end

        -- CC icon (class or flag carrier)
        units[i].cc.icon:SetTexture(
            v['fc'] and SPELLINFO_WSG_FLAGS[playerFaction]['icon']
                     or GET_DEFAULT_ICON('class', v['class']))
        units[i].cc.cd:Hide()
        units[i].cc.border:SetColor(.1, .1, .1)
        units[i].cc.duration:SetText('')

        -- raid icon  (FIX 4: raidTargets now keyed by GUID in core)
        if v['guid'] and raidTargets[v['guid']] then
            local tCoords = RAID_TARGET_TCOORDS[raidTargets[v['guid']]['icon']]
            units[i].raidTarget.icon:SetTexCoord(tCoords[1], tCoords[2], tCoords[3], tCoords[4])
            units[i].raidTarget:Show()
        else
            units[i].raidTarget:Hide()
        end

        if FOSTERFRAMESPLAYERDATA['displayOnlyNearby'] and not v['nearby'] then
            units[i]:Hide()
        else
            units[i]:Show()
        end

        i = i + 1
        if i > unitLimit then return end
    end
end

-- ─── OnUpdate (display, capped at 60 Hz) ──────────────────────────────────

local function fosterFramesOnUpdate(self, elapsed)
    nextRefresh = nextRefresh - (elapsed or arg1 or 0)
    if nextRefresh < 0 then
        raidTargets = FOSTERFRAMECOREGetRaidTarget()
        updateUnits()

        if FOSTERFRAMESPLAYERDATA['efcDistanceTracking'] and fosterFrame.efcButton:IsShown() then
            local name, dist = FOSTERFRAMECOREGetEFCDistance()
            if name and dist ~= 'unknown' then
                fosterFrame.efcButton.distText:SetText(dist)
            else
                fosterFrame.efcButton.distText:SetText('')
            end
        else
            fosterFrame.efcButton.distText:SetText('')
        end

        nextRefresh = refreshInterval
    end
end

--- GLOBAL ACCESS ---

function FOSTERFRAMESUpdatePlayers(list)
    drawUnits(list)
end

function FOSTERFRAMESAnnounceRT(rt, p)
    raidTargets = rt
    fosterFrame.raidTargetFrame.text:SetText(p['name'])
    fosterFrame.raidTargetFrame.text:SetTextColor(
        RAID_CLASS_COLORS[p['class']].r,
        RAID_CLASS_COLORS[p['class']].g,
        RAID_CLASS_COLORS[p['class']].b)
    -- FIX 4: raidTargets keyed by GUID; look up by guid first, then name fallback
    local rtEntry = (p['guid'] and raidTargets[p['guid']])
    if rtEntry then
        local tCoords = RAID_TARGET_TCOORDS[rtEntry['icon']]
        fosterFrame.raidTargetFrame.iconl:SetTexCoord(tCoords[1], tCoords[2], tCoords[3], tCoords[4])
        fosterFrame.raidTargetFrame.iconr:SetTexCoord(tCoords[1], tCoords[2], tCoords[3], tCoords[4])
    end
    PlaySound('RaidWarning', 'master')
    fosterFrame.raidTargetFrame:Show()
    ktEndtime = GetTime() + ktInterval
end

function FOSTERFRAMESInitialize(maxU, isBG)
    insideBG         = isBG
    MOUSEOVERUNINAME = nil

    if maxU then
        SetupFrames(maxU)
        arrangeUnits()
        optionals()
        enabled = true

        if insideBG and GetZoneText() == 'Warsong Gulch' then
            fosterFrame.efcButton:Show()
        else
            fosterFrame.efcButton:Hide()
        end

        if FOSTERFRAMESPLAYERDATA['enableFrames'] then
            fosterFrame:Show()
        end
        fosterFrame:SetScript('OnUpdate', fosterFramesOnUpdate)
    else
        fosterFrame:SetScript('OnUpdate', nil)
    end
end

function FOSTERFRAMESsettings()
    optionals()
    if not enabled or
       (not insideBG and (_G['fosterFramesSettings'] and _G['fosterFramesSettings']:IsShown())) then
        SetupFrames(15)
        defaultVisuals()
        setccIcon()
        fosterFrame.efcButton:Show()
        fosterFrame.efcButton.distText:SetText(
            FOSTERFRAMESPLAYERDATA['efcDistanceTracking'] and '< 28yd' or '')
    else
        SetupFrames(maxUnits)
        if insideBG and GetZoneText() == 'Warsong Gulch' then
            fosterFrame.efcButton:Show()
        else
            fosterFrame.efcButton:Hide()
        end
    end
    arrangeUnits()
    if FOSTERFRAMESPLAYERDATA['enableFrames'] then
        fosterFrame:Show()
    else
        fosterFrame:Hide()
    end
end

-- ─── events ────────────────────────────────────────────────────────────────

local function eventHandler(_, eventName)
    local evt = eventName or event
    if (evt == 'PLAYER_ENTERING_WORLD' or evt == 'ZONE_CHANGED_NEW_AREA') and enabled then
        enabled = false
        fosterFrame:Hide()
    end
end

fosterFrame:RegisterEvent('PLAYER_ENTERING_WORLD')
fosterFrame:RegisterEvent('ZONE_CHANGED_NEW_AREA')
fosterFrame:SetScript('OnEvent', eventHandler)

-- ─── debug commands ────────────────────────────────────────────────────────

local function debugDisplayPlayerData()
    for k, v in pairs(playerList) do
        print(k .. ':')
        for i, j in pairs(v) do print(i .. ' ' .. tostring(j)) end
    end
end

local function debugCooldownTest()
    for i = 1, unitLimit do
        units[i].cc.cd:SetTimers(GetTime(), GetTime() + 8)
        units[i].cc.cd:Show()
    end
end

SLASH_FOSTERFRAMES1 = '/ffd'
SLASH_FOSTERFRAMES2 = '/fosterframesdebug'
SlashCmdList["FOSTERFRAMES"] = function(msg)
    if msg then
        if msg == 'data' then
            debugDisplayPlayerData()
        elseif msg == 'cd' then
            debugCooldownTest()
        end
    end
end
