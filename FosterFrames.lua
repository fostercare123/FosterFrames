local playerFaction
local insideBG = false
-- TIMERS
local rtMenuInterval, rtMenuEndtime = 5, 0
local refreshInterval, nextRefresh = 1/60, 0
-- LISTS
local unitLimit = 15
local units = {}
local raidTargets = {}

local raidIcons, raidIconsN = {[1] = 'skull', [2] = 'moon', [3] = 'square', [4] = 'triangle', [5] = 'star', [6] = 'diamond', [7] = 'cross', [8] = 'circle'}, 8

local enabled = false
local maxUnits = 15

MOUSEOVERUNINAME = nil

------------ UI ELEMENTS ------------------

local BACKDROP = {bgFile = [[Interface\Tooltips\UI-Tooltip-Background]]}
local enemyFactionColor

fosterFrameDisplay = CreateFrame('Frame', 'fosterFrameDisplay', UIParent)
fosterFrame = fosterFrameDisplay
fosterFrame:SetFrameStrata("BACKGROUND")
fosterFrame:SetPoint('CENTER', UIParent, UIParent:GetHeight()/3, UIParent:GetHeight()/3)
fosterFrame:SetHeight(20)
fosterFrame:SetMovable(true)
fosterFrame:SetClampedToScreen(true)

fosterFrame:SetScript('OnDragStart', function()
	local frame = this or self
	if FOSTERFRAMESPLAYERDATA['frameMovable'] or (_G['fosterFramesSettings'] and _G['fosterFramesSettings']:IsShown()) then
		frame:StartMoving()
	end
end)
fosterFrame:SetScript('OnDragStop', function()
	local frame = this or self
	frame:StopMovingOrSizing()
end)
fosterFrame:RegisterForDrag'LeftButton'
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
fosterFrame.spawnText.Button:SetHeight(15) fosterFrame.spawnText.Button:SetWidth(15)
fosterFrame.spawnText.Button:SetPoint('CENTER', fosterFrame.spawnText, 'CENTER')
fosterFrame.spawnText.Button:SetScript('OnEnter', function()
	fosterFrame.spawnText:SetTextColor(.9, .9, .4)
	GameTooltip:SetOwner(this, "ANCHOR_TOPRIGHT", -30, -30)
	GameTooltip:SetText(fosterFrame.spawnText.Button.tt)
	GameTooltip:Show()
end)
fosterFrame.spawnText.Button:SetScript('OnLeave', function()
	fosterFrame.spawnText:SetTextColor(enemyFactionColor['r'], enemyFactionColor['g'], enemyFactionColor['b'], .9)
	GameTooltip:Hide()
end)

-- EFC button
fosterFrame.efcButton = CreateFrame('Button', nil, fosterFrame)
fosterFrame.efcButton:SetHeight(15) fosterFrame.efcButton:SetWidth(15)
fosterFrame.efcButton:SetPoint('LEFT', fosterFrame.Title, 'RIGHT', 2, 0)
fosterFrame.efcButton:SetScript('OnEnter', function()
	GameTooltip:SetOwner(this, "ANCHOR_TOPRIGHT", -30, -30)
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
fosterFrame.raidTargetFrame:SetHeight(36) fosterFrame.raidTargetFrame:SetWidth(36)
fosterFrame.raidTargetFrame:SetPoint('CENTER', UIParent, 'CENTER', 0, 160)
fosterFrame.raidTargetFrame:Hide()

fosterFrame.raidTargetFrame.text = fosterFrame.raidTargetFrame:CreateFontString(nil, 'OVERLAY')
fosterFrame.raidTargetFrame.text:SetFont(STANDARD_TEXT_FONT, 18, 'OUTLINE')
fosterFrame.raidTargetFrame.text:SetTextColor(.8, .8, .8, .8)
fosterFrame.raidTargetFrame.text:SetPoint('CENTER', fosterFrame.raidTargetFrame)
fosterFrame.raidTargetFrame.text:SetText('Player')

fosterFrame.raidTargetFrame.iconl = fosterFrame.raidTargetFrame:CreateTexture(nil, 'OVERLAY')
fosterFrame.raidTargetFrame.iconl:SetTexture[[Interface\TargetingFrame\UI-RaidTargetingIcons]]
fosterFrame.raidTargetFrame.iconl:SetTexCoord(.75, 1, 0.25, .5)
fosterFrame.raidTargetFrame.iconl:SetHeight(36) fosterFrame.raidTargetFrame.iconl:SetWidth(36)
fosterFrame.raidTargetFrame.iconl:SetPoint('RIGHT', fosterFrame.raidTargetFrame.text, 'LEFT', -6, 0)

fosterFrame.raidTargetFrame.iconr = fosterFrame.raidTargetFrame:CreateTexture(nil, 'OVERLAY')
fosterFrame.raidTargetFrame.iconr:SetTexture[[Interface\TargetingFrame\UI-RaidTargetingIcons]]
fosterFrame.raidTargetFrame.iconr:SetTexCoord(.75, 1, 0.25, .5)
fosterFrame.raidTargetFrame.iconr:SetHeight(36) fosterFrame.raidTargetFrame.iconr:SetWidth(36)
fosterFrame.raidTargetFrame.iconr:SetPoint('LEFT', fosterFrame.raidTargetFrame.text, 'RIGHT', 6, 0)

-- raid target menu
local rtMenuIconsize = 26
fosterFrame.raidTargetMenu = CreateFrame('Frame', nil, fosterFrame)
fosterFrame.raidTargetMenu:SetFrameLevel(7)
fosterFrame.raidTargetMenu:SetHeight(rtMenuIconsize * 2 + 4) fosterFrame.raidTargetMenu:SetWidth(rtMenuIconsize * 4 + 10)
fosterFrame.raidTargetMenu:SetBackdrop(BACKDROP)
fosterFrame.raidTargetMenu:SetBackdropColor(0, 0, 0, .6)
fosterFrame.raidTargetMenu:Hide()
fosterFrame.raidTargetMenu.border = CreateBorder(nil, fosterFrame.raidTargetMenu, 10)
fosterFrame.raidTargetMenu.icons = {}

for j=1, raidIconsN do
	local btn = CreateFrame('Button', 'fosterFrame.raidTargetMenu.icons'..j, fosterFrame.raidTargetMenu)
	btn:SetHeight(rtMenuIconsize) btn:SetWidth(rtMenuIconsize)
	if j == 1 then
		btn:SetPoint('TOPLEFT', fosterFrame.raidTargetMenu, 'TOPLEFT', 1, -1)
	elseif j < 5 then
		btn:SetPoint('LEFT', fosterFrame.raidTargetMenu.icons[j-1], 'RIGHT', 2, 0)
	else
		btn:SetPoint('TOP', fosterFrame.raidTargetMenu.icons[j-4], 'BOTTOM', 0, -2)
	end
	btn.id = j
	btn.tex = btn:CreateTexture(nil, 'OVERLAY')
	btn.tex:SetTexture[[Interface\TargetingFrame\UI-RaidTargetingIcons]]
	btn.tex:SetAlpha(.6)
	local tCoords = RAID_TARGET_TCOORDS[raidIcons[j]]
	btn.tex:SetTexCoord(tCoords[1], tCoords[2], tCoords[3], tCoords[4])
	btn.tex:SetAllPoints()
	btn:SetScript('OnEnter', function() this.tex:SetAlpha(1) end)
	btn:SetScript('OnLeave', function() this.tex:SetAlpha(.6) end)
	fosterFrame.raidTargetMenu.icons[j] = btn
end

local function spawnRTMenu(b, tar)
	fosterFrame.raidTargetMenu:SetPoint('TOP', b, 'BOTTOM', rtMenuIconsize/2, 0)
	if fosterFrame.raidTargetMenu.target == tar and rtMenuEndtime > GetTime() then 
		fosterFrame.raidTargetMenu:Hide()
		return 
	end
	fosterFrame.raidTargetMenu.target = tar
	fosterFrame.raidTargetMenu:Show()
	rtMenuEndtime = GetTime() + rtMenuInterval
	for j=1, raidIconsN do
		fosterFrame.raidTargetMenu.icons[j]:SetScript('OnClick', function()
			FOSTERFRAMECORESendRaidTarget(raidIcons[this.id], tar)
			fosterFrame.raidTargetMenu:Hide()
			rtMenuEndtime = 0
		end)
	end
end

local unitWidth, unitHeight, castBarHeight, ccIconWidth, manaBarHeight = UIElementsGetDimensions()
local leftSpacing = 5

-- draw player unit frames
for i=1, unitLimit do
	units[i] = CreateEnemyUnitFrame('fosterFrameUnit'..i, fosterFrame)
	units[i].index = i
	units[i].hoverEnabled = false

	units[i]:SetScript('OnClick', function(self, button)
			local b = button or arg1
			local frame = self or this
			if b == 'LeftButton' and frame.tar ~= nil  then
				TargetByName(frame.tar, true)
			end
			if b == 'RightButton' then
				spawnRTMenu(frame, frame.tar)
			end
		end)

	units[i]:SetScript('OnEnter', function(self)
		local frame = self or this
		if frame.hoverEnabled then
			frame.name:SetTextColor(enemyFactionColor['r'], enemyFactionColor['g'], enemyFactionColor['b'])
			frame.mo = true
			MOUSEOVERUNINAME = frame.tar
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
		frame.mo = false
		MOUSEOVERUNINAME = nil
	end)
end

local function defaultVisuals()
	for i=1, unitLimit do
		units[i].ffCastbar.icon:SetTexture[[Interface\Icons\Inv_misc_gem_sapphire_01]]
		units[i].ffCastbar.text:SetText('Entangling Roots')
		units[i].ffCastbar.text:SetText(string.sub(units[i].ffCastbar.text:GetText(), 1, 18))
		units[i].name:SetText('Player'.. i)
		
		units[i].raidTarget.icon:SetTexCoord(.75, 1, 0.25, .5)
		
		units[i].cc.icon:SetTexture([[Interface\characterframe\TEMPORARYPORTRAIT-MALE-ORC]])
		units[i].cc.duration:SetText('2.8')
		
		units[i]:Show()
	end
end

local function optionals()
	for i = 1, unitLimit do
		if not FOSTERFRAMESPLAYERDATA['displayNames'] 		then units[i].name:Hide() 	else units[i].name:Show() end
		
		if not FOSTERFRAMESPLAYERDATA['displayManabar'] 	then 
			units[i].hpbar:SetHeight(unitHeight)
			units[i].manabar:Hide()
		else 
			units[i].hpbar:SetHeight(unitHeight - manaBarHeight)
			units[i].manabar:Show() 
		end
		if not FOSTERFRAMESPLAYERDATA['castTimers'] 		then units[i].ffCastbar.timer:Hide() else units[i].ffCastbar.timer:Show() end
		if not FOSTERFRAMESPLAYERDATA['targetCounter'] 		then units[i].targetCount.text:Hide() else units[i].targetCount.text:Show() end
	end
end

local function setccIcon()
	for i=1, unitLimit do
		units[i].cc.icon:SetTexture(GET_DEFAULT_ICON('class', 'WARRIOR'))
	end
end

local function arrangeUnits()
	local unitGroup = FOSTERFRAMESPLAYERDATA['groupsize']
	local layout = FOSTERFRAMESPLAYERDATA['layout']

	if playerFaction == 'Alliance' then fosterFrameDisplay.Title:SetText(layout == 'vertical' and 'H ' or 'Horde') else fosterFrameDisplay.Title:SetText(layout == 'vertical' and 'A ' or 'Alliance') end

	for i=1, unitLimit do
		if i == 1 then
			units[i]:SetPoint('TOPLEFT', fosterFrameDisplay, 'BOTTOMLEFT', 0, -4)
		else
			if i > unitGroup then
				if layout == 'hblock' or layout == 'vblock' then
					units[i]:SetPoint('TOPLEFT', units[i-unitGroup].ffCastbar.iconborder, 'BOTTOMLEFT', 1, -5)
				else
					units[i]:SetPoint('TOPLEFT', units[i-unitGroup].cc, 'TOPRIGHT', leftSpacing, 0)
				end
			else
				if layout == 'hblock' or layout == 'vblock' then
					units[i]:SetPoint('TOPLEFT', units[i-1].cc, 'TOPRIGHT', leftSpacing, 0)
				else
					units[i]:SetPoint('TOPLEFT', units[i-1].ffCastbar.iconborder, 'BOTTOMLEFT', 1, -5)
				end
			end
		end
	end
end

local function showHideBars()
	if FOSTERFRAMESPLAYERDATA['frameMovable'] then
		fosterFrameDisplay.spawnText.Button.tt = 'Lock'
		fosterFrameDisplay.top:Show()
		fosterFrameDisplay.bottom:Show()
		fosterFrameDisplay.spawnText:SetText('-')
	else
		fosterFrameDisplay.spawnText.Button.tt = 'Unlock'
		fosterFrameDisplay.top:Hide()
		fosterFrameDisplay.bottom:Hide()
		fosterFrameDisplay.spawnText:SetText('+')
	end
	fosterFrameDisplay:EnableMouse(FOSTERFRAMESPLAYERDATA['frameMovable'])
end

local function SetupFrames(maxU)
	maxUnits = maxU or 15
	if maxUnits < 1 then maxUnits = 1 end
	playerFaction = UnitFactionGroup('player')

	if playerFaction == 'Alliance' then 
		enemyFactionColor = RGB_FACTION_COLORS['Horde']
		fosterFrameDisplay.Title:SetText('Horde')
	else 
		enemyFactionColor = RGB_FACTION_COLORS['Alliance']
		fosterFrameDisplay.Title:SetText('Alliance')
	end

	fosterFrameDisplay.Title:SetTextColor(enemyFactionColor['r'], enemyFactionColor['g'], enemyFactionColor['b'], .9)
	fosterFrameDisplay.spawnText:SetTextColor(enemyFactionColor['r'], enemyFactionColor['g'], enemyFactionColor['b'], .9)
	fosterFrameDisplay.totalPlayers:SetTextColor(enemyFactionColor['r'], enemyFactionColor['g'], enemyFactionColor['b'], .9)

	local layout = FOSTERFRAMESPLAYERDATA['layout'] or 'block'
	local groupSize = FOSTERFRAMESPLAYERDATA['groupsize'] or 5
	if groupSize < 1 then groupSize = 5 end
	
	local col = layout == 'hblock' and 5 or layout == 'vblock' and 2 or layout == 'vertical' and 1 or math.floor(maxUnits / groupSize)
	if col < 1 then col = 1 end
	
	fosterFrameDisplay:SetWidth((unitWidth + ccIconWidth + 5) * col + leftSpacing * (col - 1))
	fosterFrameDisplay.top:SetWidth(fosterFrameDisplay:GetWidth())
	fosterFrameDisplay.top:SetPoint('CENTER', fosterFrameDisplay)

	fosterFrameDisplay.spawnText.Button:SetScript('OnClick', function()
		if FOSTERFRAMESPLAYERDATA['frameMovable'] then
			FOSTERFRAMESPLAYERDATA['frameMovable'] = false
		else
			FOSTERFRAMESPLAYERDATA['frameMovable'] = true
		end
		showHideBars()
		GameTooltip:SetOwner(this, "ANCHOR_TOPRIGHT", -30, -60)
		GameTooltip:SetText(fosterFrameDisplay.spawnText.Button.tt)
		GameTooltip:Show()
	end)

	fosterFrameDisplay.efcButton.flagTexture:SetTexture('Interface\\WorldStateFrame\\'.. (playerFaction or 'Alliance') ..'Flag')
	fosterFrameDisplay.efcButton:SetScript('OnClick', function()
		if FOSTERFRAMESPLAYERDATA['efcBGannouncement'] == true then
			FOSTERFRAMESPLAYERDATA['efcBGannouncement'] = false
			fosterFrameDisplay.efcButton.flagTexture:SetVertexColor(.3, .3, .3)
		else
			FOSTERFRAMESPLAYERDATA['efcBGannouncement'] = true
			fosterFrameDisplay.efcButton.flagTexture:SetVertexColor(1, 1, 1)
		end
	end)
	
	if FOSTERFRAMESPLAYERDATA['efcBGannouncement'] then
		if fosterFrameDisplay.efcButton.flagTexture then fosterFrameDisplay.efcButton.flagTexture:SetVertexColor(1, 1, 1) end
	else
		if fosterFrameDisplay.efcButton.flagTexture then fosterFrameDisplay.efcButton.flagTexture:SetVertexColor(.3, .3, .3) end
	end
	
	showHideBars()

	fosterFrameDisplay.bottom:SetWidth(fosterFrameDisplay:GetWidth())
	local unitPointBottom
	if layout == 'hblock' then
		unitPointBottom = maxUnits - 4
	elseif layout == 'vblock' then
		unitPointBottom = (math.mod(maxUnits, 2) == 0) and maxUnits - 1 or maxUnits
	elseif layout == 'vertical' then
		unitPointBottom = maxUnits
	elseif maxUnits < groupSize then
		unitPointBottom = maxUnits
	else
		unitPointBottom = groupSize
	end
	
	if unitPointBottom < 1 then unitPointBottom = 1 end
	if units[unitPointBottom] then
		fosterFrameDisplay.bottom:SetPoint('TOPLEFT', units[unitPointBottom].ffCastbar.icon, 'BOTTOMLEFT', 1, -6)
	end
end

local function round(num, idp)
	local mult = 10^(idp or 0)
	return math.floor(num * mult + 0.5) / mult
end

local getTimerLeft = function(tEnd, now)
	now = now or GetTime()
	local t = tEnd - now
	if t > 3 then return round(t, 0) else return round(t, 1) end
end

local function drawUnits(list)
	playerList = list
	local i, nearU = 1, 0

	for k, v in pairs(playerList) do
		local class = v['class'] or 'WARRIOR'
		local powerType = v['powerType'] or 'mana'
		local colour = RAID_CLASS_COLORS[class] or RAID_CLASS_COLORS['WARRIOR']
		local powerColor = RGB_POWER_COLORS[powerType] or RGB_POWER_COLORS['mana']

		if v['nearby'] then
			units[i].hpbar:SetStatusBarColor(colour.r, colour.g, colour.b)
			units[i].hoverEnabled = true
			if not units[i].mo then units[i].name:SetTextColor(colour.r, colour.g, colour.b) end
			units[i].manabar:SetStatusBarColor(powerColor[1], powerColor[2], powerColor[3])
			units[i].cc.icon:SetVertexColor(1, 1, 1, 1)
		else
			units[i].hoverEnabled = false
			units[i].hpbar:SetStatusBarColor(colour.r/2, colour.g/2, colour.b/2, .7)
			units[i].manabar:SetStatusBarColor(powerColor[1]/2, powerColor[2]/2, powerColor[3]/2)
			if not units[i].mo then units[i].name:SetTextColor(colour.r/2, colour.g/2, colour.b/2, .7) end
			if v['fc'] then units[i].cc.icon:SetVertexColor(1, 1, 1, 1) else units[i].cc.icon:SetVertexColor(.4, .4, .4, .7) end
			units[i].cc.cd:Hide()
		end
				
		units[i].name:SetText(string.sub(v['name'] or 'Unknown', 1, 7))
		
		-- button function to target unit
		units[i].tar = v['name']
		units[i].guid = v['guid']
		
		-- cc icon (support for spec icons)
        local icon = v['fc'] and SPELLINFO_WSG_FLAGS[playerFaction]['icon'] or GET_DEFAULT_ICON('class', v['class'])
        if not v['fc'] and FOSTERFRAMESPLAYERDATA['specSpecificIcons'] and v['spec'] then
            icon = GET_DEFAULT_ICON('spec', v['spec'])
        end
		units[i].cc.icon:SetTexture(icon)

		-- target count
		units[i].targetCount.text:SetText(v['targetcount'] and (v['targetcount'] > 0 and v['targetcount'] or '') or '')
		
		-- hp & mana display using UnitXP
		local maxHP = v['maxhealth'] or 100
		local currHP = v['health'] or (not v['nearby'] and maxHP) or 100
		units[i].hpbar:SetMinMaxValues(0, maxHP)
		units[i].hpbar:SetValue(currHP)
		
		if FOSTERFRAMESPLAYERDATA['displayHealthValues'] then
			units[i].hpText:SetText(currHP .. " / " .. maxHP)
		end

		local maxMana = v['maxmana'] or 100
		local currMana = v['mana'] or (not v['nearby'] and maxMana) or 100
		units[i].manabar:SetMinMaxValues(0, maxMana)
		units[i].manabar:SetValue(currMana)
		
		if FOSTERFRAMESPLAYERDATA['displayManaValues'] then
			if v['class'] ~= 'WARRIOR' and v['class'] ~= 'ROGUE' then
				units[i].manaText:SetText(currMana .. " / " .. maxMana)
			else
				units[i].manaText:SetText("")
			end
		end
		
		if FOSTERFRAMESPLAYERDATA['displayOnlyNearby'] and not v['nearby'] then units[i]:Hide()	else units[i]:Show() end

		nearU = v['nearby'] and nearU + 1 or nearU
		i = i + 1
	end
	
	for j=i, unitLimit, 1 do
		if units[j]:IsShown() then
			units[j]:Hide()
		end
	end

	i = i == 1 and 1 or i -1
	
	if not insideBG or FOSTERFRAMESPLAYERDATA['displayOnlyNearby'] then		
		local layout = FOSTERFRAMESPLAYERDATA['layout']
		local unitGroup = FOSTERFRAMESPLAYERDATA['groupsize']
		local unitPointBottom
		if layout == 'vertical' then
			unitPointBottom = i
		elseif layout == 'hblock' or layout == 'vblock' then
			local a = math.floor(i/unitGroup)
			unitPointBottom = a  == 0 and 1 or (a * unitGroup) + 1
		elseif i > unitGroup then
			unitPointBottom = unitGroup
		else
			unitPointBottom = i
		end
		fosterFrame.bottom:SetPoint('TOPLEFT', units[unitPointBottom].ffCastbar.icon, 'BOTTOMLEFT', 1, -6)
	end
end

local function updateUnits()
	local now = GetTime()

	if rtMenuEndtime < now then fosterFrame.raidTargetMenu:Hide() end

	if not fosterFrame.uiList then return end
	local currentTarget = UnitExists'target' and UnitName'target' or nil

	local i = 1
	for k, v in pairs(fosterFrame.uiList) do
		-- border
		if currentTarget == v['name'] then
			units[i].border:SetColor(enemyFactionColor['r'], enemyFactionColor['g'], enemyFactionColor['b'])
			units[i].hpbar:SetBackdropColor(enemyFactionColor['r']-.6, enemyFactionColor['g']-.6, enemyFactionColor['b']-.6, .6)
			units[i].manabar:SetBackdropColor(enemyFactionColor['r']-.6, enemyFactionColor['g']-.6, enemyFactionColor['b']-.6, .6)
		else
			units[i].border:SetColor(.1, .1, .1)
			units[i].hpbar:SetBackdropColor(0, 0, 0, .6)
			units[i].manabar:SetBackdropColor(0, 0, 0, .6)
		end
		
		-- castbar
		local castInfo = v['castinfo']
		units[i].ffCastbar:Hide()
		if castInfo ~= nil then
			units[i].ffCastbar:SetMinMaxValues(0, castInfo.timeEnd - castInfo.timeStart)
			if castInfo.inverse then
				units[i].ffCastbar:SetValue(math.mod((castInfo.timeEnd - now), castInfo.timeEnd - castInfo.timeStart))
			else
				units[i].ffCastbar:SetValue(math.mod((now - castInfo.timeStart), castInfo.timeEnd - castInfo.timeStart))
			end
			local charLim = FOSTERFRAMESPLAYERDATA['castTimers'] and 14 or 15
			units[i].ffCastbar.text:SetText(string.sub(castInfo.spell, 1, charLim))
			units[i].ffCastbar.timer:SetText(getTimerLeft(castInfo.timeEnd, now))
			units[i].ffCastbar.icon:SetTexture(castInfo.icon)
			if castInfo.borderClr then units[i].ffCastbar.b:SetColor(castInfo.borderClr[1], castInfo.borderClr[2], castInfo.borderClr[3]) else units[i].ffCastbar.b:SetColor(.1, .1, .1) end
			units[i].ffCastbar:Show()
		end
		
		-- cc icon
        local icon = v['fc'] and SPELLINFO_WSG_FLAGS[playerFaction]['icon'] or GET_DEFAULT_ICON('class', v['class'])
        if not v['fc'] and FOSTERFRAMESPLAYERDATA['specSpecificIcons'] and v['spec'] then
            icon = GET_DEFAULT_ICON('spec', v['spec'])
        end
		units[i].cc.icon:SetTexture(icon)
		units[i].cc.cd:Hide()
		units[i].cc.border:SetColor(.1, .1, .1)
		units[i].cc.duration:SetText("")

		-- trinket icon
		local trinket = FOSTERFRAMECOREGetTrinketCooldown(v['guid'])
		if trinket then
			units[i].trinket.icon:SetTexture(trinket.icon or [[Interface\Icons\inv_jewelry_trinketpvp_01]])
			units[i].trinket.cd:SetTimers(trinket.start, trinket.end)
			units[i].trinket.cd:Show()
			units[i].trinket:Show()
		else
			units[i].trinket:Hide()
		end
		
		-- raid icon
		if v['name'] and raidTargets[v['name']] then
			local tCoords = RAID_TARGET_TCOORDS[raidTargets[v['name']]['icon']]
			units[i].raidTarget.icon:SetTexCoord(tCoords[1], tCoords[2], tCoords[3], tCoords[4])
			units[i].raidTarget:Show()
		else
			units[i].raidTarget:Hide()
		end

		if FOSTERFRAMESPLAYERDATA['displayOnlyNearby'] and not v['nearby'] then units[i]:Hide()	else units[i]:Show() end

		i = i + 1
		if i > unitLimit then return end
	end
end

local function fosterFramesOnUpdate()
	nextRefresh = nextRefresh - arg1
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

function FOSTERFRAMESInitialize(maxU, isBG)
	insideBG = isBG
	MOUSEOVERUNINAME = nil

	if maxU then
		SetupFrames(maxU)
		arrangeUnits()
		optionals()
		enabled = true

		if insideBG and GetZoneText() == 'Warsong Gulch' then fosterFrame.efcButton:Show() else fosterFrame.efcButton:Hide() end

		if FOSTERFRAMESPLAYERDATA['enableFrames'] or insideBG then fosterFrame:Show() else fosterFrame:Hide() end
		fosterFrame:SetScript('OnUpdate', fosterFramesOnUpdate)
	else
		fosterFrame:SetScript('OnUpdate', nil)
	end
end

function FOSTERFRAMESsettings()
	optionals()
	if not enabled or (not insideBG and (_G['fosterFramesSettings'] and _G['fosterFramesSettings']:IsShown())) then
		SetupFrames(15)
		defaultVisuals()
		setccIcon()
		fosterFrame.efcButton:Show()
		fosterFrame.efcButton.distText:SetText(FOSTERFRAMESPLAYERDATA['efcDistanceTracking'] and '< 28yd' or '')
	else
		SetupFrames(maxUnits)
		if insideBG and GetZoneText() == 'Warsong Gulch' then fosterFrame.efcButton:Show() else fosterFrame.efcButton:Hide() end
	end
	arrangeUnits()
	if FOSTERFRAMESPLAYERDATA['enableFrames'] or insideBG then fosterFrame:Show() else fosterFrame:Hide() end
	
	if not enabled and not (_G['fosterFramesSettings'] and _G['fosterFramesSettings']:IsShown()) then
		for i=1, unitLimit do units[i]:Hide() end
	end
end

-- ─── debug commands ────────────────────────────────────────────────────────

local function debugDisplayPlayerData()
	local list = FOSTERFRAMECOREgetPlayerList and FOSTERFRAMECOREgetPlayerList() or {}
	for k, v in pairs(list) do
		print(k .. ':')
		for i, j in pairs(v) do print(i .. ' ' .. j) end
	end
end

local function debugCooldownTest()
	for i=1, unitLimit do
		units[i].cc.cd:SetTimers(GetTime(), GetTime() + 8)
		units[i].cc.cd:Show()
	end
end

SLASH_FOSTERFRAMES1 = '/ffd'
SLASH_FOSTERFRAMES2 = '/fosterframesdebug'
SlashCmdList["FOSTERFRAMES"] = function(msg)
	if msg then
		if 		msg == 'data' 	then 	debugDisplayPlayerData()	 
		elseif 	msg =='cd' 		then	debugCooldownTest()
		end		
	end
end
