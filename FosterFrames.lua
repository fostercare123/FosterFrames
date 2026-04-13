
local playerFaction
local insideBG = false
-- TIMERS
local ktInterval, ktEndtime = 3, 0
local rtMenuInterval, rtMenuEndtime = 5, 0
local refreshInterval, nextRefresh = 1/60, 0
-- LISTS
local playerList = {}
local unitLimit = 15
local units = {}
local raidTargets = {}
local raidIcons, raidIconsN = { [1] = 'skull', [2] = 'moon', [3] = 'square', [4] = 'triangle',  
								[5] = 'star', [6] = 'diamond', [7] = 'cross', [8] = 'circle'}, 8

local enabled = false
local maxUnits = 15

MOUSEOVERUNINAME = nil
---

------------ UI ELEMENTS ------------------
--local TEXTURE = [[Interface\AddOns\fosterFrames\globals\resources\barTexture.tga]]
local BACKDROP = {bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],}
local enemyFactionColor

local 	fosterFrame = CreateFrame('Frame', 'fosterFrameDisplay', UIParent)
		fosterFrame:SetFrameStrata("BACKGROUND")
		fosterFrame:SetPoint('CENTER', UIParent, UIParent:GetHeight()/3, UIParent:GetHeight()/3)		
		fosterFrame:SetHeight(20)
		
		--fosterFrame:SetBackdrop(BACKDROP)
		--fosterFrame:SetBackdropColor(0, 0, 0, .6)
		
		fosterFrame:SetMovable(true)
		fosterFrame:SetClampedToScreen(true)
		
		fosterFrame:SetScript('OnDragStart', function(self)
			local frame = self or this
			if FOSTERFRAMESPLAYERDATA['frameMovable'] or (_G['fosterFramesSettings'] and _G['fosterFramesSettings']:IsShown()) then
				frame:StartMoving()
			end
		end)
		fosterFrame:SetScript('OnDragStop', function(self)
			local frame = self or this
			if FOSTERFRAMESPLAYERDATA['frameMovable'] or (_G['fosterFramesSettings'] and _G['fosterFramesSettings']:IsShown()) then
				frame:StopMovingOrSizing()
			end
		end)
		fosterFrame:RegisterForDrag('LeftButton')
	
		
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
		fosterFrame.spawnText.Button:SetHeight(15)	fosterFrame.spawnText.Button:SetWidth(15)
		fosterFrame.spawnText.Button:SetPoint('CENTER', fosterFrame.spawnText, 'CENTER')
		fosterFrame.spawnText.Button:SetScript('OnEnter', function(self)
			fosterFrame.spawnText:SetTextColor(.9, .9, .4)
			GameTooltip:SetOwner(self or this, 'ANCHOR_TOPRIGHT', -30, -30)
			GameTooltip:SetText((self or this).tt)
			GameTooltip:Show()
		end)
		fosterFrame.spawnText.Button:SetScript('OnLeave', function()
			fosterFrame.spawnText:SetTextColor(enemyFactionColor['r'], enemyFactionColor['g'], enemyFactionColor['b'], .9)
			GameTooltip:Hide()
		end)
		
		
		-- efc low announcement button
		fosterFrame.efcButton = CreateFrame('Button', nil, fosterFrame)
		fosterFrame.efcButton:SetHeight(15)	fosterFrame.efcButton:SetWidth(15)
		fosterFrame.efcButton:SetPoint('LEFT', fosterFrame.Title, 'RIGHT', 2, 0)
		fosterFrame.efcButton:SetScript('OnEnter', function(self)
			GameTooltip:SetOwner(self or this, 'ANCHOR_TOPRIGHT', -30, -30)
			GameTooltip:SetText('Toggle EFC Low Health Announcement')
			GameTooltip:Show()
		end)
		fosterFrame.efcButton:SetScript('OnLeave', function()
			GameTooltip:Hide()
		end)	

		fosterFrame.efcButton.flagTexture = fosterFrame.efcButton:CreateTexture(nil, 'ARTWORK')
		fosterFrame.efcButton.flagTexture:SetAllPoints()

		--fosterFrame.efcButton:Hide()
		
			
		-- top frame
		
		fosterFrame.top = CreateFrame('Frame', nil, fosterFrame)
		fosterFrame.top:SetFrameLevel(0)
		fosterFrame.top:ClearAllPoints()		
		fosterFrame.top:SetHeight(fosterFrame:GetHeight())
		fosterFrame.top:SetBackdrop(BACKDROP)
		fosterFrame.top:SetBackdropColor(0, 0, 0, .6)
		
		--border
		fosterFrame.top.border = CreateBorder(nil, fosterFrame.top, 13)
		
		-- bottom frame
		fosterFrame.bottom = CreateFrame('Frame', nil, fosterFrame)
		--fosterFrame.bottom:SetFrameStrata("BACKGROUND")
		fosterFrame.bottom:SetFrameLevel(0)
		fosterFrame.bottom:ClearAllPoints()		
		fosterFrame.bottom:SetHeight(fosterFrame:GetHeight())
		
		fosterFrame.bottom:SetBackdrop(BACKDROP)
		fosterFrame.bottom:SetBackdropColor(0, 0, 0, .6)
		
		--border
		fosterFrame.bottom.border = CreateBorder(nil, fosterFrame.bottom, 13)
		
		--fosterFrame.bottom:Hide()
		
		----- raidTarget
		fosterFrame.raidTargetFrame = CreateFrame('Frame', nil, fosterFrame)
		fosterFrame.raidTargetFrame:SetFrameLevel(2)
		fosterFrame.raidTargetFrame:SetHeight(36)	fosterFrame.raidTargetFrame:SetWidth(36)
		fosterFrame.raidTargetFrame:SetPoint('CENTER', UIParent,'CENTER', 0, 160)
		fosterFrame.raidTargetFrame:Hide()
	
		fosterFrame.raidTargetFrame.text = fosterFrame.raidTargetFrame:CreateFontString(nil, 'OVERLAY')
		fosterFrame.raidTargetFrame.text:SetFont(STANDARD_TEXT_FONT, 18, 'OUTLINE')
		fosterFrame.raidTargetFrame.text:SetTextColor(.8, .8, .8, .8)
		fosterFrame.raidTargetFrame.text:SetPoint('CENTER', fosterFrame.raidTargetFrame)
		fosterFrame.raidTargetFrame.text:SetText('Player')
	
		fosterFrame.raidTargetFrame.iconl = fosterFrame.raidTargetFrame:CreateTexture(nil, 'OVERLAY')
		fosterFrame.raidTargetFrame.iconl:SetTexture([[Interface\TargetingFrame\UI-RaidTargetingIcons]])
		fosterFrame.raidTargetFrame.iconl:SetTexCoord(.75, 1, 0.25, .5)
		fosterFrame.raidTargetFrame.iconl:SetHeight(36)	fosterFrame.raidTargetFrame.iconl:SetWidth(36)
		fosterFrame.raidTargetFrame.iconl:SetPoint('RIGHT', fosterFrame.raidTargetFrame.text, 'LEFT', -6, 0)
		
		fosterFrame.raidTargetFrame.iconr = fosterFrame.raidTargetFrame:CreateTexture(nil, 'OVERLAY')
		fosterFrame.raidTargetFrame.iconr:SetTexture([[Interface\TargetingFrame\UI-RaidTargetingIcons]])
		fosterFrame.raidTargetFrame.iconr:SetTexCoord(.75, 1, 0.25, .5)
		fosterFrame.raidTargetFrame.iconr:SetHeight(36)	fosterFrame.raidTargetFrame.iconr:SetWidth(36)
		fosterFrame.raidTargetFrame.iconr:SetPoint('LEFT', fosterFrame.raidTargetFrame.text, 'RIGHT', 6, 0)

		-- raidTarget menu
		local rtMenuIconsize = 26
		fosterFrame.raidTargetMenu = CreateFrame('Frame', nil, fosterFrame)
		fosterFrame.raidTargetMenu:SetFrameLevel(7)
		fosterFrame.raidTargetMenu:SetHeight(rtMenuIconsize*2+4)	fosterFrame.raidTargetMenu:SetWidth(rtMenuIconsize*4+10)
		fosterFrame.raidTargetMenu:SetBackdrop(BACKDROP)
		fosterFrame.raidTargetMenu:SetBackdropColor(0, 0, 0, .6)
		--fosterFrame.raidTargetMenu:SetPoint('CENTER', UIParent,'CENTER', 0, 160)
		fosterFrame.raidTargetMenu:Hide()
		
		fosterFrame.raidTargetMenu.border = CreateBorder(nil, fosterFrame.raidTargetMenu, 10)
		
		fosterFrame.raidTargetMenu.icons = {}
		for j = 1, raidIconsN, 1 do
			fosterFrame.raidTargetMenu.icons[j] = CreateFrame('Button', 'fosterFrame.raidTargetMenu.icons'..j, fosterFrame.raidTargetMenu)
			fosterFrame.raidTargetMenu.icons[j]:SetHeight(rtMenuIconsize)	fosterFrame.raidTargetMenu.icons[j]:SetWidth(rtMenuIconsize)
			if j == 1 then
				fosterFrame.raidTargetMenu.icons[j]:SetPoint('TOPLEFT', fosterFrame.raidTargetMenu, 'TOPLEFT', 1, -1)
			elseif j < 5 then
				fosterFrame.raidTargetMenu.icons[j]:SetPoint('LEFT', fosterFrame.raidTargetMenu.icons[j-1], 'RIGHT', 2, 0)
			else
				fosterFrame.raidTargetMenu.icons[j]:SetPoint('TOP', fosterFrame.raidTargetMenu.icons[j-4], 'BOTTOM', 0, -2)
			end
			fosterFrame.raidTargetMenu.icons[j].id = j
			
			fosterFrame.raidTargetMenu.icons[j].tex = fosterFrame.raidTargetMenu.icons[j]:CreateTexture(nil, 'OVERLAY')
			fosterFrame.raidTargetMenu.icons[j].tex:SetTexture([[Interface\TargetingFrame\UI-RaidTargetingIcons]])
			fosterFrame.raidTargetMenu.icons[j].tex:SetAlpha(.6)
			local tCoords = RAID_TARGET_TCOORDS[raidIcons[j]]
			fosterFrame.raidTargetMenu.icons[j].tex:SetTexCoord(tCoords[1], tCoords[2], tCoords[3], tCoords[4])
			fosterFrame.raidTargetMenu.icons[j].tex:SetAllPoints()
			
			fosterFrame.raidTargetMenu.icons[j]:SetScript('OnEnter', function(self)
															(self or this).tex:SetAlpha(1)
														end)
														
			fosterFrame.raidTargetMenu.icons[j]:SetScript('OnLeave', function(self)
															(self or this).tex:SetAlpha(.6)
														end)							
		end

		--spawn raidtarget menu
		local function spawnRTMenu(b, target)
			fosterFrame.raidTargetMenu:SetPoint('TOP', b,'BOTTOM', rtMenuIconsize/2, 0)
			if fosterFrame.raidTargetMenu.target and fosterFrame.raidTargetMenu.target == target and rtMenuEndtime > GetTime() then
					fosterFrame.raidTargetMenu:Hide()
					return
			end
			
			fosterFrame.raidTargetMenu.target = target
			fosterFrame.raidTargetMenu:Show()
			rtMenuEndtime = GetTime() + rtMenuInterval
			
			for j = 1, raidIconsN, 1 do
				fosterFrame.raidTargetMenu.icons[j]:SetScript('OnClick', function(self)
					FOSTERFRAMECORESendRaidTarget(raidIcons[(self or this).id], target)
					fosterFrame.raidTargetMenu:Hide()
					rtMenuEndtime = 0
				end)
			end
		end

local unitWidth, unitHeight, castBarHeight, ccIconWidth, manaBarHeight = UIElementsGetDimensions()
local leftSpacing = 5
-- draw player units
for i = 1, unitLimit,1 do
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


-- function for settings use
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
		-- display player's names
		if not FOSTERFRAMESPLAYERDATA['displayNames'] then
			units[i].name:Hide()
		else
			units[i].name:Show()
		end
		
		-- display mana bar
		if not FOSTERFRAMESPLAYERDATA['displayManabar'] then
			units[i].hpbar:SetHeight(unitHeight)
			units[i].manabar:Hide()
		else
			units[i].hpbar:SetHeight(unitHeight - manaBarHeight)
			units[i].manabar:Show()
		end
		
		-- display cast timer
		if not FOSTERFRAMESPLAYERDATA['castTimers'] then
			units[i].castbar.timer:Hide()
		else
			units[i].castbar.timer:Show()
		end

		-- display target counter
		if not FOSTERFRAMESPLAYERDATA['targetCounter'] then
			units[i].targetCount.text:Hide()
		else
			units[i].targetCount.text:Show()
		end
	end
end
local function setccIcon()
	local d = 'WARRIOR'
	for i = 1, unitLimit do
		units[i].cc.icon:SetTexture(GET_DEFAULT_ICON('class', d))
	end
end
 
 
local function arrangeUnits()
	local unitGroup, layout = FOSTERFRAMESPLAYERDATA['groupsize'], FOSTERFRAMESPLAYERDATA['layout']
	
	-- adjust title
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
		fosterFrame.top:Show()--SetAlpha(1)
		fosterFrame.bottom:Show()--SetAlpha(1)
		fosterFrame.spawnText:SetText('-')		
	else
		fosterFrame.spawnText.Button.tt = 'Unlock'
		fosterFrame.top:Hide()--SetAlpha(0)
		fosterFrame.bottom:Hide()--SetAlpha(0)
		fosterFrame.spawnText:SetText('+')
	end
	fosterFrame:EnableMouse(FOSTERFRAMESPLAYERDATA['frameMovable'])
end

local function SetupFrames(maxU)
	maxUnits = maxU
	-- get player's faction
	playerFaction = UnitFactionGroup('player')
	
	if playerFaction == 'Alliance' then 
		enemyFactionColor = RGB_FACTION_COLORS['Horde']
		fosterFrame.Title:SetText('Horde')
	else 
		enemyFactionColor = RGB_FACTION_COLORS['Alliance']
		fosterFrame.Title:SetText('Alliance')		
	end
	
	fosterFrame.Title:SetTextColor(enemyFactionColor['r'], enemyFactionColor['g'], enemyFactionColor['b'], .9)
	fosterFrame.spawnText:SetTextColor(enemyFactionColor['r'], enemyFactionColor['g'], enemyFactionColor['b'], .9)
	fosterFrame.totalPlayers:SetTextColor(enemyFactionColor['r'], enemyFactionColor['g'], enemyFactionColor['b'], .9)
		
	-- width of the draggable frame
	local col = FOSTERFRAMESPLAYERDATA['layout'] == 'hblock' and 5 or FOSTERFRAMESPLAYERDATA['layout'] == 'vblock' and 2 or FOSTERFRAMESPLAYERDATA['layout'] == 'vertical' and 1 or maxUnits / FOSTERFRAMESPLAYERDATA['groupsize']
	fosterFrame:SetWidth((unitWidth + ccIconWidth + 5)*col +  leftSpacing*(col-1))
	
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
		
		
	fosterFrame.efcButton.flagTexture:SetTexture('Interface\\WorldStateFrame\\'..playerFaction..'Flag')
--	fosterFrame.efcButton.flagTexture:SetVertexColor(.3, .3, .3)
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
		fosterFrame.efcButton.flagTexture:SetVertexColor( 1, 1, 1)
	else fosterFrame.efcButton.flagTexture:SetVertexColor(.3, .3, .3)	end
		
		
	showHideBars()
	
	-- bottom frame
	fosterFrame.bottom:SetWidth(fosterFrame:GetWidth())
	--fosterFrame.bottom:SetPoint('CENTER', fosterFrame, 0, -((unitHeight + castBarHeight + 15) * unitGroup))
	local unitPointBottom = FOSTERFRAMESPLAYERDATA['layout'] == 'hblock' and maxUnits - 4 or FOSTERFRAMESPLAYERDATA['layout'] == 'vblock' and (math.mod(maxUnits,2) == 0 and maxUnits - 1 or math.mod(maxUnits,2) ~= 0 and maxUnits) or maxUnits < FOSTERFRAMESPLAYERDATA['groupsize'] and maxUnits or FOSTERFRAMESPLAYERDATA['groupsize']
	fosterFrame.bottom:SetPoint('TOPLEFT', units[unitPointBottom].castbar.icon, 'BOTTOMLEFT', 1, -6)
	
	-- Settings are slash-command only: /ffs
		
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
	
	for k,v in pairs(playerList) do
		-- set for redrawn
		
		local colour = RAID_CLASS_COLORS[v['class']]
		local powerColor = RGB_POWER_COLORS[v['powerType']]
		
		-- hightlight nearby unit
		if v['nearby'] then		
			if colour then
				units[i].hpbar:SetStatusBarColor(colour.r, colour.g, colour.b)
			end
			units[i].hoverEnabled = true
			if not units[i].mo then
				units[i].name:SetTextColor(colour.r, colour.g, colour.b)	
			end			
			units[i].manabar:SetStatusBarColor(powerColor[1], powerColor[2], powerColor[3])			
			units[i].cc.icon:SetVertexColor(1, 1, 1, 1)
						
		else
			units[i].hoverEnabled = false
			units[i].hpbar:SetStatusBarColor(colour.r / 2, colour.g / 2, colour.b / 2, .7)
			units[i].manabar:SetStatusBarColor(powerColor[1] / 2, powerColor[2] / 2, powerColor[3] / 2)
			if not units[i].mo then
				units[i].name:SetTextColor(colour.r / 2, colour.g / 2, colour.b / 2, .7)
			end		
			
			--units[i].targetCount.text:SetTextColor(.898 / 2, .898 / 2, .199 / 2)

			if v['fc'] then
				units[i].cc.icon:SetVertexColor(1, 1, 1, 1)
			else
				units[i].cc.icon:SetVertexColor(.4, .4, .4, .7)--v['fc'] and 1, 1, 1, 1 or .4, .4, .4, .6)
			end
			units[i].cc.cd:Hide()
			
		end
				
		--units[i].name:SetText(v['name'])
		units[i].name:SetText(string.sub(v['name'], 1, 7))
		
		-- button function to target unit
		units[i].tar = v['name']
		
		-- target count
		units[i].targetCount.text:SetText(v['targetcount'] and (v['targetcount'] > 0 and v['targetcount'] or '') or '')
		
		-- hp & mana
                local maxHP = v['maxhealth'] and v['maxhealth'] or 100
                local currHP = v['health'] and v['health'] or (not v['nearby'] and maxHP) or 100
                units[i].hpbar:SetMinMaxValues(0, maxHP)
                units[i].hpbar:SetValue(currHP)
                units[i].hpText:SetText(currHP > 100 and currHP or "")

                local maxMana = v['maxmana'] and v['maxmana'] or 100
                local currMana = v['mana'] and v['mana'] or (not v['nearby'] and maxMana) or 100
                units[i].manabar:SetMinMaxValues(0, maxMana)
                units[i].manabar:SetValue(currMana)
                units[i].manaText:SetText((currMana > 100 and v['class'] ~= 'WARRIOR' and v['class'] ~= 'ROGUE') and currMana or "")
		
		--units[i]:Show()
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
		local unitPointBottom = FOSTERFRAMESPLAYERDATA['layout'] == 'vertical' and i or i > FOSTERFRAMESPLAYERDATA['groupsize'] and FOSTERFRAMESPLAYERDATA['groupsize'] or i
		
		if FOSTERFRAMESPLAYERDATA['layout'] == 'hblock' or FOSTERFRAMESPLAYERDATA['layout'] == 'vblock' then
			local a = math.floor(i/FOSTERFRAMESPLAYERDATA['groupsize'])
			unitPointBottom = a  == 0 and 1 or (a * FOSTERFRAMESPLAYERDATA['groupsize']) +1
		end
		
		fosterFrame.bottom:SetPoint('TOPLEFT', units[unitPointBottom].castbar.icon, 'BOTTOMLEFT', 1, -6)
		
		--/Script print(math.floor(4/5))
	end
end

-- target indicator, raid icons, optionals
local function updateUnits()
	local now = GetTime()
	-- killTarget announcement
	if ktEndtime < now then
		fosterFrame.raidTargetFrame:Hide()
	end
	-- raidicons menu
	if rtMenuEndtime < now then
		fosterFrame.raidTargetMenu:Hide()
	end
	local currentTarget = UnitName'target'
	
	local i = 1
	
	for k, v in pairs(playerList) do
		
		-- target indicator
		if currentTarget == v['name'] then
			units[i].border:SetColor(enemyFactionColor['r'], enemyFactionColor['g'], enemyFactionColor['b'])
			
			units[i].hpbar:SetBackdropColor(enemyFactionColor['r'] - .6, enemyFactionColor['g'] - .6, enemyFactionColor['b'] - .6, .6)
			units[i].manabar:SetBackdropColor(enemyFactionColor['r'] - .6, enemyFactionColor['g'] - .6, enemyFactionColor['b'] - .6, .6)			
		else
			units[i].border:SetColor(.1, .1, .1)
			
			units[i].hpbar:SetBackdropColor(0, 0, 0, .6)
			units[i].manabar:SetBackdropColor(0, 0, 0, .6)
		end

		
		-- castbar
                local unitID = (UnitExists('target') and v['name'] == UnitName('target')) and 'target' or (UnitExists('mouseover') and v['name'] == UnitName('mouseover')) and 'mouseover' or nil
                local castInfo = SPELLCASTINGCOREgetCast(v['name'], unitID)
                units[i].castbar:Hide()
                if castInfo ~= nil then
                        units[i].castbar:SetMinMaxValues(0, castInfo.timeEnd - castInfo.timeStart)

                        if castInfo.inverse then
                                units[i].castbar:SetValue(math.mod((castInfo.timeEnd - now), castInfo.timeEnd - castInfo.timeStart))
                        else
                                units[i].castbar:SetValue(math.mod((now - castInfo.timeStart), castInfo.timeEnd - castInfo.timeStart))
                        end
                        units[i].castbar.text:SetText(castInfo.spell)
                        local charLim = FOSTERFRAMESPLAYERDATA['castTimers'] and 14 or 15
                        units[i].castbar.text:SetText(string.sub(units[i].castbar.text:GetText(), 1, charLim))

                        units[i].castbar.timer:SetText(getTimerLeft(castInfo.timeEnd, now))--..'s')

                        units[i].castbar.icon:SetTexture(castInfo.icon)
                        
                        -- Set border color for interrupt indication if SuperWOW is present
                        if castInfo.borderClr then
                                units[i].castbar.b:SetColor(castInfo.borderClr[1], castInfo.borderClr[2], castInfo.borderClr[3])
                        else
                                units[i].castbar.b:SetColor(.1, .1, .1)
                        end
                        
                        units[i].castbar:Show()
                end
			
		-- icon display (class-only mode)
		units[i].cc.icon:SetTexture(v['fc'] and SPELLINFO_WSG_FLAGS[playerFaction]['icon'] or GET_DEFAULT_ICON('class', v['class']))
		units[i].cc.cd:Hide()
		
		units[i].cc.border:SetColor(.1, .1, .1)
		units[i].cc.duration:SetText('')
		
		-- RAID ICON
		if raidTargets[v['name']] then
			local tCoords = RAID_TARGET_TCOORDS[raidTargets[v['name']]['icon']]
			units[i].raidTarget.icon:SetTexCoord(tCoords[1], tCoords[2], tCoords[3], tCoords[4])
			units[i].raidTarget:Show()
		else
			units[i].raidTarget:Hide()
		end	
		
		--if not v['nearby'] then
		--	if FOSTERFRAMESPLAYERDATA['displayOnlyNearby'] then units[i]:Hide()	else units[i]:Show() end
		--end
		if FOSTERFRAMESPLAYERDATA['displayOnlyNearby'] and not v['nearby'] then units[i]:Hide()	else units[i]:Show() end
				
		i = i + 1
		if i > unitLimit then return end
	end
end

local function fosterFramesOnUpdate(self, elapsed)
	nextRefresh = nextRefresh - (elapsed or arg1 or 0)
	if nextRefresh < 0 then
		-- update units
		if FOSTERFRAMECOREGetRaidTarget then raidTargets = FOSTERFRAMECOREGetRaidTarget() end
		updateUnits()
	
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
	fosterFrame.raidTargetFrame.text:SetTextColor(RAID_CLASS_COLORS[p['class']].r, RAID_CLASS_COLORS[p['class']].g, RAID_CLASS_COLORS[p['class']].b)
	
	local tCoords = RAID_TARGET_TCOORDS[raidTargets[p['name']]['icon']]
	fosterFrame.raidTargetFrame.iconl:SetTexCoord(tCoords[1], tCoords[2], tCoords[3], tCoords[4])
	fosterFrame.raidTargetFrame.iconr:SetTexCoord(tCoords[1], tCoords[2], tCoords[3], tCoords[4])
	PlaySound('RaidWarning', 'master')
	
	fosterFrame.raidTargetFrame:Show()
	ktEndtime = GetTime() + ktInterval
end

function FOSTERFRAMESInitialize(maxUnits, isBG)
	insideBG = isBG
	MOUSEOVERUNINAME = nil
	if maxUnits then
		SetupFrames(maxUnits)
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
	if not enabled or not insideBG then
		SetupFrames(15)
		defaultVisuals()
		setccIcon()
	else
		SetupFrames(maxUnits)
	end
	
	arrangeUnits()
	
	if FOSTERFRAMESPLAYERDATA['enableFrames'] then
		fosterFrame:Show()
	else
		fosterFrame:Hide()
	end
end

---------------------

local function eventHandler(_, eventName)
	local evt = eventName or event
	if evt == 'PLAYER_ENTERING_WORLD' or evt == 'ZONE_CHANGED_NEW_AREA' and enabled then
		enabled = false
		fosterFrame:Hide()
		--
	end
end

fosterFrame:RegisterEvent'PLAYER_ENTERING_WORLD'
fosterFrame:RegisterEvent'ZONE_CHANGED_NEW_AREA'
fosterFrame:SetScript('OnEvent', eventHandler)


local function debugDisplayPlayerData()
	for k, v in pairs(playerList) do
		print(k..':')
		for i, j in pairs(v) do
			print(i .. ' ' .. tostring(j))
		end
	end
end
local function debugCooldownTest()
	for i = 1, unitLimit do
		units[i].cc.cd:SetTimers(GetTime(), GetTime()+8)
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


