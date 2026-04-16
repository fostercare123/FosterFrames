	_G = getfenv(0)
	-------------------------------------------------------------------------------
	local flagCarriers = {}
	local fcHealth = {}
	local sentAnnoucement, healthWarnings = false, {10, 20, 40}
	local nextAnnouncement = 0
	-------------------------------------------------------------------------------
	local h = WorldStateAlwaysUpFrame:CreateFontString(nil, 'OVERLAY')
    h:SetFontObject(GameFontNormalSmall)
    h:SetTextColor(RGB_FACTION_COLORS['Horde']['r'], RGB_FACTION_COLORS['Horde']['g'], RGB_FACTION_COLORS['Horde']['b'])
    h:SetJustifyH'LEFT'
	h:SetText('Horde')
	
	local hb = CreateFrame('Button', nil, WorldStateAlwaysUpFrame)
    hb:SetFrameLevel(2)
    hb:SetAllPoints(h)
    hb:EnableMouse(true)
    
	
	local hh = WorldStateAlwaysUpFrame:CreateFontString(nil, 'OVERLAY')
    hh:SetFontObject(GameFontNormalSmall)
	--hh:SetTextColor(.59, .98, .59)
    hh:SetJustifyH'RIGHT'
    hh:SetPoint('LEFT', h, 'RIGHT', 5, 0)

	
    local a = WorldStateAlwaysUpFrame:CreateFontString(nil, 'OVERLAY')
    a:SetFontObject(GameFontNormalSmall)
	a:SetTextColor(RGB_FACTION_COLORS['Alliance']['r'], RGB_FACTION_COLORS['Alliance']['g'], RGB_FACTION_COLORS['Alliance']['b'])
    a:SetJustifyH'LEFT'
	a:SetText('Alliance')
	
	local ab = CreateFrame('Button', nil, WorldStateAlwaysUpFrame)
    ab:SetFrameLevel(2)
    ab:SetAllPoints(a)
    ab:EnableMouse(true)
    
	
	local ah = WorldStateAlwaysUpFrame:CreateFontString(nil, 'OVERLAY')
    ah:SetFontObject(GameFontNormalSmall)
	--ah:SetTextColor(.59, .98, .59)
    ah:SetJustifyH'RIGHT'
    ah:SetPoint('LEFT', a, 'RIGHT', 5, 0)
	-------------------------------------------------------------------------------
	local OnEnter = function(self)
		local button = self or this
		local label = button == hb and h or a
		label:SetTextColor(.9, .9, .4)
		if label:GetText() ~= '' then
			GameTooltip:SetOwner(button, 'ANCHOR_TOPRIGHT', -40, 10)
			GameTooltip:SetText('Click to target '..label:GetText())
			GameTooltip:Show()
		end
	end
	local OnLeave = function(self)
		local button = self or this
		local label = button == hb and h or a
		local f = label == a and 'Alliance' or 'Horde'
		label:SetTextColor(RGB_FACTION_COLORS[f]['r'], RGB_FACTION_COLORS[f]['g'], RGB_FACTION_COLORS[f]['b'])
		GameTooltip:Hide()
	end
	local target = function(self)
	       local button = self or this
	       local text = button == hb and h or a
        local t = text:GetText()
        TargetByName(t, true)

    end
	
	
	hb:SetScript('OnClick', target)
	hb:SetScript('OnEnter', OnEnter)
	hb:SetScript('OnLeave', OnLeave)
	
	ab:SetScript('OnClick', target)
	ab:SetScript('OnEnter', OnEnter)
	ab:SetScript('OnLeave', OnLeave)
	-------------------------------------------------------------------------------
	WSGUIupdateFC = function(fc)
		flagCarriers = fc
		
		-- AlwaysUpFrame1 = Alliance Flag (taken by Horde EFC)
		if flagCarriers['Horde'] then
			h:SetText(flagCarriers['Horde'])
		else
			h:SetText('')
			hh:SetText('')
			fcHealth['Horde'] = nil
		end
		
		-- AlwaysUpFrame2 = Horde Flag (taken by Alliance EFC)
		if flagCarriers['Alliance'] then
			a:SetText(flagCarriers['Alliance'])
		else
			a:SetText('')
			ah:SetText('')
			fcHealth['Alliance'] = nil
		end
	end
	-------------------------------------------------------------------------------
	local w, timeInterval = 100, 4
	local efcLowHealth = function()
		local playerFaction = UnitFactionGroup'player'
		local enemyFaction = playerFaction == 'Alliance' and 'Horde' or 'Alliance'

		local now = GetTime()
		-- We care about the health of the ENEMY flag carrier (who has OUR flag)
		if flagCarriers[enemyFaction] and fcHealth[enemyFaction] then
			for i = 1, table.getn(healthWarnings) do
				if fcHealth[enemyFaction] < healthWarnings[i] then
					if (not sentAnnoucement or healthWarnings[i] < w) and now > nextAnnouncement then
						nextAnnouncement = now + timeInterval
						w = healthWarnings[i]
						SendChatMessage('Enemy Flag Carrier ('..flagCarriers[enemyFaction]..') has less than '..healthWarnings[i]..'% Health! Get ready to cap!', 'BATTLEGROUND')
						sentAnnoucement = true
					end
					return
				end
			end
		end
		sentAnnoucement = false
	end
	-------------------------------------------------------------------------------
	local function round(num, idp)
		local mult = 10^(idp or 0)
		return math.floor(num * mult + 0.5) / mult
	end
	local getPerc = function(unit)
		return round(((UnitHealth(unit) * 100) / UnitHealthMax(unit)), 1)
	end
	-------------------------------------------------------------------------------
	WSGUIupdateFChealth = function(unit)
		if unit then
			if not UnitIsPlayer(unit) then return end
			local name = UnitName(unit)
			if name == flagCarriers['Horde'] then
				fcHealth['Horde'] = getPerc(unit)
				hh:SetText(fcHealth['Horde']..'%')
			elseif name == flagCarriers['Alliance'] then
				fcHealth['Alliance'] = getPerc(unit)
				ah:SetText(fcHealth['Alliance']..'%')
			end
		end
		
		if FOSTERFRAMESPLAYERDATA['efcBGannouncement'] then
			efcLowHealth()
		end
	end
	-------------------------------------------------------------------------------
	WSGUIinit = function(insideBG)
		if insideBG then
			local hdb = _G['AlwaysUpFrame1DynamicIconButton']
			h:SetPoint('LEFT', hdb, 'RIGHT', 4, 2)
			h:Show()
			h:SetText('')
			hh:Show()		
			hh:SetText('')
			
			local adb = _G['AlwaysUpFrame2DynamicIconButton']
			a:SetPoint('LEFT', adb, 'RIGHT', 4, 2)
			a:Show()
			a:SetText('')			
			ah:Show()
			ah:SetText('')
		else
			h:Hide()
			hh:Hide()
			a:Hide()
			ah:Hide()
			flagCarriers = {}
		end
	end
	-------------------------------------------------------------------------------