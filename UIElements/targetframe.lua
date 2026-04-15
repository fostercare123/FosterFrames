	-------------------------------------------------------------------------------
	local refreshInterval, nextRefresh = 1/60, 0
	local flagCarriers = {}
	local showText = true
	-------------------------------------------------------------------------------
	local TEXTURE = [[Interface\AddOns\fosterFrames\globals\resources\barTexture.tga]]
    local BACKDROP = {bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],}
	
	TargetFrame.EFcast = CreateFrame('StatusBar', 'fosterFramesTargetFrameCastbar', TargetFrame)
    TargetFrame.EFcast:SetStatusBarTexture(TEXTURE)
    TargetFrame.EFcast:SetStatusBarColor(1, .4, 0)
    TargetFrame.EFcast:SetBackdrop(BACKDROP)
    TargetFrame.EFcast:SetBackdropColor(0, 0, 0)
    TargetFrame.EFcast:SetHeight(10)
	TargetFrame.EFcast:SetWidth(160)
	--TargetFrame.EFcast:ClearAllPoints()
	TargetFrame.EFcast:SetPoint('LEFT', TargetFrame, 'LEFT', 26, -45)
	
    TargetFrame.EFcast:SetValue(0)
    TargetFrame.EFcast:Hide()
	
	TargetFrame.EFcast:SetMovable(true) TargetFrame.EFcast:SetUserPlaced(true)
	TargetFrame.EFcast:SetClampedToScreen(true)
	TargetFrame.EFcast:RegisterForDrag'LeftButton' TargetFrame.EFcast:EnableMouse(true)
	local castbarmoveable = false
	TargetFrame.EFcast:SetScript('OnDragStart', function() if castbarmoveable then this:StartMoving() end end)
	TargetFrame.EFcast:SetScript('OnDragStop', function() if castbarmoveable then this:StopMovingOrSizing() end end)
	
	TargetFrame.EFcast.border = CreateBorder(nil, TargetFrame.EFcast, 6.5, 1/8.5)
	TargetFrame.EFcast.border:SetPadding(2.5, 1.7)
	
	TargetFrame.EFcast.spark = TargetFrame.EFcast:CreateTexture(nil, 'OVERLAY')
	TargetFrame.EFcast.spark:SetTexture([[Interface\CastingBar\UI-CastingBar-Spark]])
	TargetFrame.EFcast.spark:SetHeight(26)	
	TargetFrame.EFcast.spark:SetWidth(26)
	TargetFrame.EFcast.spark:SetBlendMode('ADD')

    TargetFrame.EFcast.text = TargetFrame.EFcast:CreateFontString(nil, 'OVERLAY')
    TargetFrame.EFcast.text:SetTextColor(1, 1, 1)
    TargetFrame.EFcast.text:SetFont(STANDARD_TEXT_FONT, 11, 'OUTLINE')
    --TargetFrame.EFcast.text:SetShadowOffset(1, -1)
    TargetFrame.EFcast.text:SetShadowColor(0, 0, 0)
    TargetFrame.EFcast.text:SetPoint('LEFT', TargetFrame.EFcast, 2, .5)
    TargetFrame.EFcast.text:SetText('drag-me')

    TargetFrame.EFcast.timer = TargetFrame.EFcast:CreateFontString(nil, 'OVERLAY')
    TargetFrame.EFcast.timer:SetTextColor(1, 1, 1)
    TargetFrame.EFcast.timer:SetFont(STANDARD_TEXT_FONT, 9, 'OUTLINE')
    --TargetFrame.EFcast.timer:SetShadowOffset(1, -1)
    TargetFrame.EFcast.timer:SetShadowColor(0, 0, 0)
    TargetFrame.EFcast.timer:SetPoint('RIGHT', TargetFrame.EFcast, -1, .5)
    TargetFrame.EFcast.timer:SetText'3.5s'

    TargetFrame.EFcast.icon = TargetFrame.EFcast:CreateTexture(nil, 'OVERLAY', nil, 7)
    TargetFrame.EFcast.icon:SetWidth(18) TargetFrame.EFcast.icon:SetHeight(16)
    TargetFrame.EFcast.icon:SetPoint('RIGHT', TargetFrame.EFcast, 'LEFT', -8, 0)
    TargetFrame.EFcast.icon:SetTexCoord(.1, .9, .15, .85)
	TargetFrame.EFcast.icon:SetTexture([[Interface\Icons\Inv_misc_gem_sapphire_01]])
	
	local ic = CreateFrame('Frame', nil, TargetFrame.EFcast)
    ic:SetAllPoints(TargetFrame.EFcast.icon)
	
	TargetFrame.EFcast.icon.border = CreateBorder(nil, ic, 12.8)
	TargetFrame.EFcast.icon.border:SetPadding(1)
	
	TargetFrame.IntegratedCastBar = CreateFrame('StatusBar', 'fosterFramesTargetFrameCastbar', TargetFrame)
    TargetFrame.IntegratedCastBar:SetStatusBarTexture(TEXTURE)
    TargetFrame.IntegratedCastBar:SetStatusBarColor(1, .4, 0)
    TargetFrame.IntegratedCastBar:SetBackdrop(BACKDROP)
    TargetFrame.IntegratedCastBar:SetBackdropColor(0, 0, 0, .9)
	TargetFrame.IntegratedCastBar:SetPoint('TOPLEFT', TargetFrameNameBackground, 'TOPLEFT')
	TargetFrame.IntegratedCastBar:SetPoint('BOTTOMRIGHT', TargetFrameNameBackground, 'BOTTOMRIGHT')
	TargetFrame.IntegratedCastBar:SetFrameLevel(1)
	TargetFrame.IntegratedCastBar:SetMinMaxValues(0, 10)
	TargetFrame.IntegratedCastBar:SetValue(6)
	--[[
	TargetFrame.IntegratedCastBar.bg = TargetFrame.IntegratedCastBar:CreateTexture(nil, 'ARTWORK')
	TargetFrame.IntegratedCastBar.bg:SetTexture(0, 0, 0, .7)
	TargetFrame.IntegratedCastBar.bg:SetAllPoints()	]]--
	
	TargetFrame.IntegratedCastBar.spark = TargetFrame.IntegratedCastBar:CreateTexture(nil, 'OVERLAY')
	TargetFrame.IntegratedCastBar.spark:SetTexture([[Interface\CastingBar\UI-CastingBar-Spark]])
	TargetFrame.IntegratedCastBar.spark:SetHeight(34)--TargetFrameNameBackground:GetHeight())	
	TargetFrame.IntegratedCastBar.spark:SetWidth(32)
	TargetFrame.IntegratedCastBar.spark:SetBlendMode('ADD')
	
	TargetFrame.IntegratedCastBar.spellText = TargetFrame.IntegratedCastBar:CreateFontString(nil, 'OVERLAY')
    TargetFrame.IntegratedCastBar.spellText:SetTextColor(1, 1, 1)
    TargetFrame.IntegratedCastBar.spellText:SetFont(STANDARD_TEXT_FONT, 10, 'OUTLINE')
    TargetFrame.IntegratedCastBar.spellText:SetShadowColor(0, 0, 0)
    TargetFrame.IntegratedCastBar.spellText:SetPoint('LEFT', TargetFrame.IntegratedCastBar, 1, .5)
    TargetFrame.IntegratedCastBar.spellText:SetText('Polymorph') 
	
	TargetFrame.IntegratedCastBar.timer = TargetFrame.IntegratedCastBar:CreateFontString(nil, 'OVERLAY')
    TargetFrame.IntegratedCastBar.timer:SetTextColor(1, 1, 1)
    TargetFrame.IntegratedCastBar.timer:SetFont(STANDARD_TEXT_FONT, 8, 'OUTLINE')
    TargetFrame.IntegratedCastBar.timer:SetShadowColor(0, 0, 0)
    TargetFrame.IntegratedCastBar.timer:SetPoint('RIGHT', TargetFrame.IntegratedCastBar, -2, .5)
    TargetFrame.IntegratedCastBar.timer:SetText'3.5s'
	-------------------------------------------------------------------------------
	local function round(num, idp)
		local mult = 10^(idp or 0)
		return math.floor(num * mult + 0.5) / mult
	end
	local getTimerLeft = function(tEnd, l)
		local t = tEnd - GetTime()
		local limit = l or 3
		if t > limit then return round(t, 0) else return round(t, 1) end
	end
	-------------------------------------------------------------------------------
	local showCast = function()
		if castbarmoveable then
			if FOSTERFRAMESPLAYERDATA['targetFrameCastbar'] then
				TargetFrame.EFcast:Show()
			else
				TargetFrame.EFcast:Hide()
			end
			if FOSTERFRAMESPLAYERDATA['integratedTargetFrameCastbar'] then
				TargetFrame.IntegratedCastBar:Show()
				--TargetFrameNameBackground:SetDrawLayer'BACKGROUND'
				TargetFrameNameBackground:SetAlpha(.3)
				TargetName:Hide()	
			else
				TargetFrame.IntegratedCastBar:Hide()
				--TargetFrameNameBackground:SetDrawLayer'BORDER'
				TargetFrameNameBackground:SetAlpha(1)
				TargetName:Show()
			end		
		else
			TargetFrame.EFcast:Hide()
			TargetFrame.IntegratedCastBar:Hide()
			--TargetFrameNameBackground:SetDrawLayer'BORDER'
			TargetFrameNameBackground:SetAlpha(1)
			TargetName:Show()
		end
		if UnitExists'target' then
			local v = SPELLCASTINGCOREgetCast(UnitName('target'), 'target')
			if v ~= nil then
				local guid = FOSTERFRAMESHasGUID() and UnitGUID('target')
				if GetTime() < v.timeEnd then
					TargetFrame.EFcast:SetMinMaxValues(0, v.timeEnd - v.timeStart)
					TargetFrame.IntegratedCastBar:SetMinMaxValues(0, v.timeEnd - v.timeStart)
					local sparkPosition
					if v.inverse then
						TargetFrame.EFcast:SetValue(math.mod((v.timeEnd - GetTime()), v.timeEnd - v.timeStart))
						TargetFrame.IntegratedCastBar:SetValue(math.mod((v.timeEnd - GetTime()), v.timeEnd - v.timeStart))
						
						sparkPosition = (v.timeEnd - GetTime()) / (v.timeEnd - v.timeStart)
					else
						TargetFrame.EFcast:SetValue(math.mod((GetTime() - v.timeStart), v.timeEnd - v.timeStart))
						TargetFrame.IntegratedCastBar:SetValue(math.mod((GetTime() - v.timeStart), v.timeEnd - v.timeStart))	

						sparkPosition = (GetTime() - v.timeStart) / (v.timeEnd - v.timeStart)
					end
					
					TargetFrame.EFcast.text:SetText(string.sub(v.spell, 1, 20))
					TargetFrame.IntegratedCastBar.spellText:SetText(string.sub(v.spell, 1, 15))
					TargetFrame.EFcast.timer:SetText(getTimerLeft(v.timeEnd)..'s')
					TargetFrame.IntegratedCastBar.timer:SetText(getTimerLeft(v.timeEnd)..'s')
					TargetFrame.EFcast.icon:SetTexture(v.icon)
					-- border colors
					TargetFrame.EFcast.icon.border:SetColor(v.borderClr[1], v.borderClr[2], v.borderClr[3])
					TargetFrame.EFcast.border:SetColor(v.borderClr[1], v.borderClr[2], v.borderClr[3])
					--
					-- spark
					if not sparkPosition or sparkPosition < 0 then
						sparkPosition = 0
					end
					TargetFrame.IntegratedCastBar.spark:SetPoint('CENTER', TargetFrame.IntegratedCastBar, 'LEFT', sparkPosition * TargetFrameNameBackground:GetWidth(), -1)
					TargetFrame.EFcast.spark:SetPoint('CENTER', TargetFrame.EFcast, 'LEFT', sparkPosition * TargetFrame.EFcast:GetWidth(), 0)
					--
					if FOSTERFRAMESPLAYERDATA['targetFrameCastbar'] then
						TargetFrame.EFcast:Show()
					end
					if FOSTERFRAMESPLAYERDATA['integratedTargetFrameCastbar'] then
						TargetFrame.IntegratedCastBar:Show()
						--TargetFrameNameBackground:SetDrawLayer'BACKGROUND'
						TargetFrameNameBackground:SetAlpha(.3)
						TargetName:Hide()							
					end	
				end
			end
		end
    end
	-------------------------------------------------------------------------------
	TARGETFRAMEsetFC = function(fc)
		flagCarriers = fc
	end
	-------------------------------------------------------------------------------
	local portraitDebuff = CreateFrame('Frame', 'TargetPortraitDebuff', TargetFrame)
	portraitDebuff:SetFrameLevel(0)
	portraitDebuff:SetPoint('TOPLEFT', TargetPortrait, 'TOPLEFT', 7, -2)
	portraitDebuff:SetPoint('BOTTOMRIGHT', TargetPortrait, 'BOTTOMRIGHT', -5.5, 4)
	
	-- circle texture
	portraitDebuff.bgText = TargetFrame:CreateTexture(nil, 'OVERLAY')
	portraitDebuff.bgText:SetPoint('TOPLEFT', TargetPortrait, 'TOPLEFT', 3, -4.5)
	portraitDebuff.bgText:SetPoint('BOTTOMRIGHT', TargetPortrait, 'BOTTOMRIGHT', -4, 3)
	portraitDebuff.bgText:SetVertexColor(.3, .3, .3)
	portraitDebuff.bgText:SetTexture([[Interface\AddOns\fosterFrames\globals\resources\portraitBg.tga]])
	-- debuff texture
	portraitDebuff.debuffText = TargetFrame:CreateTexture()
	portraitDebuff.debuffText:SetPoint('TOPLEFT', TargetPortrait, 'TOPLEFT', 7.5, -8)
	portraitDebuff.debuffText:SetPoint('BOTTOMRIGHT', TargetPortrait, 'BOTTOMRIGHT', -7.5, 4.5)	
	portraitDebuff.debuffText:SetTexCoord(.12, .88, .12, .88)
	-- duration text
	local portraitDurationFrame = CreateFrame('Frame', nil, TargetFrame)
	portraitDurationFrame:SetAllPoints()
	portraitDurationFrame:SetFrameLevel(2)
	
	portraitDebuff.duration = portraitDurationFrame:CreateFontString(nil, 'OVERLAY')--, 'GameFontNormalSmall')
	portraitDebuff.duration:SetFont(STANDARD_TEXT_FONT, 16, 'OUTLINE')
	portraitDebuff.duration:SetTextColor(.9, .9, .2, 1)
	portraitDebuff.duration:SetShadowOffset(1, -1)
	portraitDebuff.duration:SetShadowColor(0, 0, 0)
	portraitDebuff.duration:SetPoint('CENTER', TargetPortrait, 'CENTER', 0, -5)
	-- cooldown spiral
	portraitDebuff.cd = CreateCooldown(portraitDebuff, 1.054, true)
	portraitDebuff.cd:SetAlpha(1)
	-------------------------------------------------------------------------------
	local showPortraitDebuff = function()
		if UnitExists'target' then
			local xtFaction = UnitFactionGroup'target' == 'Alliance' and 'Horde' or 'Alliance'

			if UnitName'target' == flagCarriers[xtFaction] then
				portraitDebuff.debuffText:SetTexture(SPELLINFO_WSG_FLAGS[xtFaction]['icon'])
				portraitDebuff.bgText:Show()
				portraitDebuff.duration:SetText('')
				portraitDebuff.cd:Hide()
				portraitDebuff.bgText:SetVertexColor(.1, .1, .1)
				
			else
				portraitDebuff.cd:Hide()				
				portraitDebuff.debuffText:SetTexture()
				portraitDebuff.duration:SetText('')
				portraitDebuff.bgText:Hide()
			end			
		end
	end
	-------------------------------------------------------------------------------
	local function addExtras(button)
		button.ft = CreateFrame('Frame', button:GetName()..'TextFrame', button)
		button.ft:SetFrameLevel(4)
		button.ft:SetAllPoints()
		
		button.text = button.ft:CreateFontString(nil, 'OVERLAY')
		button.text:SetFont(STANDARD_TEXT_FONT, 10, 'OUTLINE')
		button.text:SetTextColor(.9, .9, .2)
		button.text:SetShadowColor(0, 0, 0)
		button.text:SetPoint('CENTER', button, 'BOTTOM', 0, 1)	

		
		button.f = CreateFrame('Frame', button:GetName()..'CooldownFrame', button)
		button.f:SetAllPoints()
		
		button.cd = CreateCooldown(button.f, .4, true)
		
		local icon = getglobal(button:GetName()..'Icon')
		if icon then icon:SetTexCoord(.05, .95, .05, .95) end
		
		local count = getglobal(button:GetName()..'Count')
		if count then
			count:SetPoint('TOP', button, 'TOP', 0, -1)
		end
	end
	-------------------------------------------------------------------------------
	for i=1, MAX_TARGET_BUFFS do
		addExtras(getglobal('TargetFrameBuff'..i))
	end
	for i=1, MAX_TARGET_DEBUFFS do
		addExtras(getglobal('TargetFrameDebuff'..i))	
		--getglobal('TargetFrameDebuff'..i):SetHeight(5)--getglobal('TargetFrameDebuff'..i..'Icon'):GetHeight()-15)				
	end
	-------------------------------------------------------------------------------
	local checkAddTimer = function(button, debuff, debuffList)
		for k, v in pairs(debuffList) do
			if v.icon and debuff and string.upper(v.icon) == string.upper(debuff) then
				button.text:SetText(getTimerLeft(v.timeEnd, 0))					
				if showText then button.text:Show()	end
				button.cd:SetTimers(v.timeStart, v.timeEnd)
				button.cd:Show()
				
			end
		end
	end
	-------------------------------------------------------------------------------
	local limits = {MAX_TARGET_BUFFS, MAX_TARGET_DEBUFFS}
	local function displayTimers(debuffList)
		if debuffList == nil then return end		
		
		local debuff, button, debuffStack, debuffType
		for i=1, 2 do
			for j=1, limits[i] do
				if i == 1 then
					debuff = UnitBuff('target', j)
					button = getglobal('TargetFrameBuff'..j)
				else
					debuff, debuffStack, debuffType = UnitDebuff('target', j)
					button = getglobal('TargetFrameDebuff'..j)
				end
				if not debuff then break end
				
				button.text:Hide()
				button.cd:Hide()
				
				if FOSTERFRAMESPLAYERDATA['targetDebuffTimers'] then
					checkAddTimer(button, debuff, debuffList)
				end
			end
		end
	end
	-------------------------------------------------------------------------------	
	local dummyFrame = CreateFrame'Frame'
	dummyFrame:SetScript('OnUpdate', function()
		nextRefresh = nextRefresh - arg1
		if nextRefresh < 0 then
			if FOSTERFRAMESPLAYERDATA['targetFrameCastbar'] or FOSTERFRAMESPLAYERDATA['integratedTargetFrameCastbar'] then
				showCast()				
			else
				TargetFrame.EFcast:Hide()
				TargetFrame.IntegratedCastBar:Hide()	
				--TargetFrameNameBackground:SetDrawLayer'BORDER'
				TargetFrameNameBackground:SetAlpha(1)
				TargetName:Show()				
			end
			showPortraitDebuff()
			
			-- debuff timers
			if UnitExists('target') then
				displayTimers(SPELLCASTINGCOREgetBuffs(UnitName('target'), 'target'))
			end
			
			nextRefresh = refreshInterval			
		end
	end)
	
	function TARGETFRAMECASTBARsettings(b)
		castbarmoveable = b
	end	
	-------------------------------------------------------------------------------
	local function eventHandler()
		flagCarriers = {}
	end
	-------------------------------------------------------------------------------
	dummyFrame:RegisterEvent'PLAYER_ENTERING_WORLD'
	dummyFrame:RegisterEvent'ZONE_CHANGED_NEW_AREA'
	dummyFrame:SetScript('OnEvent', eventHandler)
	