	-------------------------------------------------------------------------------
	local TEXTURE 	= [[Interface\AddOns\fosterFrames\globals\resources\barTexture]]
	local BACKDROP 	= {bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],}
	local ISTEXTURE = [[Interface\AddOns\fosterFrames\globals\resources\arrow2]]
	-------------------------------------------------------------------------------
	local unitWidth, unitHeight, castBarHeight, ccIconWidth, manaBarHeight = 64, 22, 8, 28, 6
	UIElementsGetDimensions = function()
		return unitWidth, unitHeight, castBarHeight, ccIconWidth, manaBarHeight
	end
	CreateEnemyUnitFrame = function(name, parentFrame)
		-- unit button
		local this = CreateFrame('Button', name, parentFrame)
		--this:SetFrameLevel(0)
		this:SetWidth(unitWidth)	this:SetHeight(unitHeight)
		this:RegisterForClicks('LeftButtonUp', 'RightButtonUp')		
		this.mo = false		
		
		this.border = CreateBorder(nil, this, 12.8, 1/4.5)
															
		-- health statusbar
		this.hpbar = CreateFrame('StatusBar', nil, this)
		this.hpbar:SetFrameLevel(1)
		this.hpbar:SetStatusBarTexture(TEXTURE)
		this.hpbar:SetWidth(unitWidth)	this.hpbar:SetHeight(unitHeight)
		this.hpbar:SetMinMaxValues(0, 100)
		this.hpbar:SetPoint('TOPLEFT', this, 'TOPLEFT')
		
		this.hpbar:SetBackdrop(BACKDROP)
		this.hpbar:SetBackdropColor(0, 0, 0, .6)
		
		SmoothBar(this.hpbar)
			
		-- mana statusbar
		this.manabar = CreateFrame('StatusBar', nil, this)
		this.manabar:SetFrameLevel(1)
		this.manabar:SetStatusBarTexture(TEXTURE)
		this.manabar:SetHeight(manaBarHeight)
		this.manabar:SetWidth(unitWidth)		
		this.manabar:SetPoint('TOPLEFT', this.hpbar, 'BOTTOMLEFT')
		
		this.manabar:SetBackdrop(BACKDROP)
		this.manabar:SetBackdropColor(0, 0, 0)
		
		SmoothBar(this.manabar)
		
		-- cast bar --
		this.ffCastbar = CreateFrame('StatusBar', nil, this)
		--this.ffCastbar:SetFrameLevel(0)
		this.ffCastbar:SetStatusBarTexture(TEXTURE)
		this.ffCastbar:SetHeight(castBarHeight)
		this.ffCastbar:SetWidth((unitWidth + ccIconWidth + 4) - (this.ffCastbar:GetHeight()))	
		this.ffCastbar:SetStatusBarColor(1, .4, 0)
		this.ffCastbar:SetPoint('TOPLEFT', this, 'BOTTOMLEFT', this.ffCastbar:GetHeight(), -3)
		
		this.ffCastbar:SetBackdrop(BACKDROP)
		this.ffCastbar:SetBackdropColor(0, 0, 0, .6)	
		
		this.ffCastbar.b = CreateBorder(nil, this.ffCastbar, 9)	
		this.ffCastbar.b:SetPadding(.4)
		
		this.ffCastbar.iconborder = CreateFrame('Frame', nil, this.ffCastbar)
		this.ffCastbar.iconborder:SetWidth(this.ffCastbar:GetHeight()+1)	this.ffCastbar.iconborder:SetHeight(this.ffCastbar:GetHeight()+1)
		this.ffCastbar.iconborder:SetPoint('RIGHT', this.ffCastbar, 'LEFT')
		
		this.ffCastbar.iconborder.border = CreateBorder(nil, this.ffCastbar.iconborder, 8)
		
		this.ffCastbar.icon = this.ffCastbar.iconborder:CreateTexture(nil, 'ARTWORK')
		this.ffCastbar.icon:SetTexCoord(.078, .92, .079, .937)
		this.ffCastbar.icon:SetAllPoints()
		this.ffCastbar.icon:SetPoint('CENTER', this.ffCastbar.iconborder, 'CENTER')
		
		this.ffCastbar.text = this.ffCastbar:CreateFontString(nil, 'OVERLAY')
		this.ffCastbar.text:SetTextColor(1, 1, 1)
		this.ffCastbar.text:SetFont(STANDARD_TEXT_FONT, 8, 'OUTLINE')
		--this.ffCastbar.text:SetShadowOffset(1, -1)
		this.ffCastbar.text:SetShadowColor(0.4, 0.4, 0.4)
		this.ffCastbar.text:SetPoint('LEFT', this.ffCastbar, 'LEFT', 1, .5)
		
		
		this.ffCastbar.timer = this.ffCastbar:CreateFontString(nil, 'OVERLAY')
		this.ffCastbar.timer:SetFont(STANDARD_TEXT_FONT, 7, 'OUTLINE')
		this.ffCastbar.timer:SetTextColor(1, 1, 1)
		this.ffCastbar.timer:SetShadowColor(0.4, 0.4, 0.4)
		this.ffCastbar.timer:SetPoint('RIGHT', this.ffCastbar, 'RIGHT', 0, 0)
		this.ffCastbar.timer:SetText('1.5')
				--------------

		this.name = this:CreateFontString(nil, 'OVERLAY')
		this.name:SetFont(STANDARD_TEXT_FONT, 11, 'OUTLINE')
		this.name:SetTextColor(.8, .8, .8, .8)
		this.name:SetPoint('CENTER', this.hpbar)
	
		this.hpText = this.hpbar:CreateFontString(nil, 'OVERLAY')
		this.hpText:SetFont(STANDARD_TEXT_FONT, 8, 'OUTLINE')
		this.hpText:SetTextColor(1, 1, 1, .9)
		this.hpText:SetPoint('CENTER', this.hpbar, 0, 0)
		this.hpText:Hide()

		this.manaText = this.manabar:CreateFontString(nil, 'OVERLAY')
		this.manaText:SetFont(STANDARD_TEXT_FONT, 8, 'OUTLINE')
		this.manaText:SetTextColor(1, 1, 1, .9)
		this.manaText:SetPoint('CENTER', this.manabar, 0, 0)
		this.manaText:Hide()
		
		--- TARGET COUNT ---
		this.targetCount = CreateFrame('Frame', nil, this)
		this.targetCount:SetWidth(ccIconWidth-2) this.targetCount:SetHeight(unitHeight-2)
		this.targetCount:SetPoint('CENTER', this,'TOPLEFT', 1, -1)
		this.targetCount:SetFrameLevel(7)
		
		this.targetCount.text = this.targetCount:CreateFontString(nil, 'OVERLAY')--, 'GameFontNormalSmall')
		this.targetCount.text:SetFont(STANDARD_TEXT_FONT, 11, 'OUTLINE')
		this.targetCount.text:SetTextColor(.9, .9, .2, 1)
		this.targetCount.text:SetShadowOffset(1, -1)
		this.targetCount.text:SetShadowColor(0, 0, 0)
		this.targetCount.text:SetPoint('CENTER', this.targetCount)
		this.targetCount.text:SetText('8')
		
		---- RAID TARGET
		this.raidTarget = CreateFrame('Frame', nil, this)
		this.raidTarget:SetWidth(ccIconWidth-2) this.raidTarget:SetHeight(unitHeight-2)
		this.raidTarget:SetPoint('CENTER', this,'TOPRIGHT', 0, -4)
		this.raidTarget:SetFrameLevel(7)
		
		this.raidTarget.icon = this.raidTarget:CreateTexture(nil, 'ARTWORK')
		this.raidTarget.icon:SetTexture([[Interface\TargetingFrame\UI-RaidTargetingIcons]])
		this.raidTarget.icon:SetAllPoints()
		
		
		---- CC ------
		this.cc = CreateFrame('Frame', name..'CC', this)
		this.cc:SetWidth(ccIconWidth) this.cc:SetHeight(unitHeight)
		this.cc:SetPoint('TOPLEFT', this,'TOPRIGHT', 3, 0)
		
		this.cc.border = CreateBorder(nil, this.cc, 12.8, 1/4.5)
		this.cc.border:SetFrameLevel(5)
		
		this.cc.icon = this.cc:CreateTexture(nil, 'ARTWORK')
		this.cc.icon:SetAllPoints()
		this.cc.icon:SetTexCoord(.1, .9, .25, .75)
		
		this.cc.bg = this.cc:CreateTexture(nil, 'BACKGROUND')
		this.cc.bg:SetTexture(0, 0, 0, .6)
		this.cc.bg:SetAllPoints()

		-- dummy frame lvl 5 to draw text above cooldown
		this.cc.durationFrame = CreateFrame('Frame', nil, this.cc)
		this.cc.durationFrame:SetAllPoints()
		this.cc.durationFrame:SetFrameLevel(6)
		
		this.cc.duration = this.cc.durationFrame:CreateFontString(nil, 'OVERLAY')--, 'GameFontNormalSmall')
		this.cc.duration:SetFont(STANDARD_TEXT_FONT, 10, 'OUTLINE')
		this.cc.duration:SetTextColor(.9, .9, .2, 1)
		this.cc.duration:SetShadowOffset(1, -1)
		this.cc.duration:SetShadowColor(0, 0, 0)
		this.cc.duration:SetPoint('BOTTOM', this.cc, 'BOTTOM', 0, 1)
		
		-- cooldown
		this.cc.cd = CreateCooldown(this.cc, .58, true)
		this.cc.cd:SetAlpha(1)
		
		---- TRINKET ----
		this.trinket = CreateFrame('Frame', name..'Trinket', this)
		this.trinket:SetWidth(ccIconWidth) this.trinket:SetHeight(unitHeight)
		this.trinket:SetPoint('TOPLEFT', this.cc, 'TOPRIGHT', 3, 0)
		
		this.trinket.border = CreateBorder(nil, this.trinket, 12.8, 1/4.5)
		this.trinket.border:SetFrameLevel(5)
		
		this.trinket.icon = this.trinket:CreateTexture(nil, 'ARTWORK')
		this.trinket.icon:SetAllPoints()
		this.trinket.icon:SetTexCoord(.1, .9, .25, .75)
		
		this.trinket.bg = this.trinket:CreateTexture(nil, 'BACKGROUND')
		this.trinket.bg:SetTexture(0, 0, 0, .6)
		this.trinket.bg:SetAllPoints()
		
		this.trinket.cd = CreateCooldown(this.trinket, .58, true)
		this.trinket.cd:SetAlpha(1)
	
		return this
	end
	-------------------------------------------------------------------------------
	