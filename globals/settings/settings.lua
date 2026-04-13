
_G = getfenv(0)

print = function(m) DEFAULT_CHAT_FRAME:AddMessage(m) end

tlength = function(t)	local i = 0 for k, j in ipairs(t) do i = i + 1 end return i end

FOSTERFRAMESVERSION = 3.0

local hasUnitXP = false
local hasSuperWOW = false
local hasNampower = false
function FOSTERFRAMESHasUnitXP()
	return hasUnitXP
end

function FOSTERFRAMESHasSuperWOW()
	return hasSuperWOW
end

function FOSTERFRAMESHasNampower()
	return hasNampower
end

function FOSTERFRAMESPrintDependencyStatus()
	local unitxpState = hasUnitXP and '|cff00ff00yes|r' or '|cffff1a1ano|r'
	local superwowState = hasSuperWOW and '|cff00ff00yes|r' or '|cffff1a1ano|r'
	local nampowerState = hasNampower and '|cff00ff00yes|r' or '|cffff1a1ano|r'

	print('[FosterFrames] Dependency status: UnitXP=' .. unitxpState .. ', SuperWOW=' .. superwowState .. ', Nampower=' .. nampowerState)

	if hasSuperWOW and SUPERWOW_VERSION then
		print('[FosterFrames] SuperWOW version: ' .. tostring(SUPERWOW_VERSION))
	end

	if hasNampower and GetNampowerVersion then
		local major, minor, patch = GetNampowerVersion()
		if major then
			print('[FosterFrames] Nampower version: ' .. tostring(major) .. '.' .. tostring(minor or 0) .. '.' .. tostring(patch or 0))
		end
	end
end

if FOSTERFRAMESPLAYERDATA == nil then
	        FOSTERFRAMESPLAYERDATA =
        {
        -- Main
        ['enableFrames']                        = true,
        ['scale']                               = 1,
        ['layout']                              = 'block',
        ['groupsize']                           = 5,
        ['displayOnlyNearby']                   = true, -- Default to true as it's important
        ['frameMovable']                        = true,
        
        -- Tactical (DLL)
        ['targetFrameCastbar']                  = true,
        ['integratedTargetFrameCastbar']        = true,
        ['useUnitXP']                           = true,
        
        -- Display
        ['displayNames']                        = true,
        ['displayManabar']                      = true,
        ['castTimers']                          = true,
        
        -- Positioning
        ['offX']                                = 0,
        ['offY']                                = 0,
        ['settingsOffX']                        = 0,
        ['settingsOffY']                        = 0,
}
end


local playerFaction, insideBG = false
------------ UI ELEMENTS ------------------
local enemyFactionColor
local fosterFramesDisplayShow = false

local settings = CreateFrame('Frame', 'fosterFramesSettings', UIParent)
settings:ClearAllPoints()
settings:SetWidth(400) settings:SetHeight(300)
settings:SetFrameLevel(60)
settings:SetPoint('CENTER', UIParent, -UIParent:GetWidth()/3, 0)
settings:SetBackdrop({bgFile   = [[Interface\Tooltips\UI-Tooltip-Background]],
				  edgeFile = [[Interface\DialogFrame\UI-DialogBox-Border]],
				  insets   = {left = 11, right = 12, top = 12, bottom = 11}})
settings:SetBackdropColor(0, 0, 0, 1)
settings:SetBackdropBorderColor(.2, .2, .2)
settings:SetMovable(true) settings:SetUserPlaced(true)
settings:SetClampedToScreen(true)
settings:RegisterForDrag'LeftButton' settings:EnableMouse(true)
settings:SetScript('OnDragStart', function() (self or this):StartMoving() end)
settings:SetScript('OnDragStop', function() this:StopMovingOrSizing() end)
tinsert(UISpecialFrames, 'fosterFramesSettings')
settings:Hide()

settings.x = CreateFrame('Button', 'fosterFramesSettingsCloseButton', settings, 'UIPanelCloseButton')
settings.x:SetPoint('TOPRIGHT',  -6, -6)

settings.header = settings:CreateTexture(nil, 'ARTWORK')
settings.header:SetWidth(320) settings.header:SetHeight(64)
settings.header:SetPoint('TOP', settings, 0, 12)
settings.header:SetTexture[[Interface\DialogFrame\UI-DialogBox-Header]]
settings.header:SetVertexColor(.2, .2, .2)

settings.header.t = settings:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
settings.header.t:SetPoint('TOP', settings.header, 0, -14)
settings.header.t:SetText'FosterFrames Settings'

-- tabs

settings.numTabs = 3
local tabNames = {'Main', 'Tactical', 'Display'}
local tabElements = {'Left', 'LeftDisabled', 'Middle', 'MiddleDisabled', 'Right', 'RightDisabled'}
settings.tabs = {}
for i = 1, settings.numTabs do
	settings.tabs[i] = CreateFrame('Button', settings:GetName()..'Tab'..i, settings, 'WorldStateScoreFrameTabButtonTemplate')
	settings.tabs[i]:SetText(tabNames[i])
	if i == 1 then
		settings.tabs[i]:SetPoint('TOPLEFT', settings, 'BOTTOMLEFT',0, 3)
	else
		settings.tabs[i]:SetPoint('LEFT', settings.tabs[i-1], 'RIGHT', -12, 0)
	end
	settings.tabs[i].id = i
	for j  = 1, tlength(tabElements) do
		_G[settings.tabs[i]:GetName()..tabElements[j]]:SetVertexColor(.2, .2, .2)
	end
	
	settings.tabs[i]:SetScript('OnClick', function()	
		local activeContainerName = string.lower(tabNames[this.id])
		for j = 1, settings.numTabs do	
			if j ~= this.id then
				local containerName = string.lower(tabNames[j])
				_G['fosterFramesSettings'..containerName..'Container']:Hide()
			end
		end
		_G['fosterFramesSettings'..activeContainerName..'Container']:Show()
		
		PanelTemplates_SetTab(settings, this.id)
	end)
end

-------------------------------------------


function setupSettings()
	if not FOSTERFRAMESHasUnitXP() then
		print('|cffff1a1a[FosterFrames] UnitXP SP3 is required. FosterFrames will stay disabled until UnitXP is active.')
		return
	end

	if not FOSTERFRAMESHasSuperWOW() then
		print('|cffff1a1a[FosterFrames] SuperWOW is required. FosterFrames will stay disabled until SuperWOW is active.')
		return
	end

	playerFaction = UnitFactionGroup'player'
	if playerFaction == 'Alliance' then 
		enemyFactionColor = RGB_FACTION_COLORS['Horde']
	else 
		enemyFactionColor = RGB_FACTION_COLORS['Alliance']	
	end
	settings.header.t:SetTextColor(enemyFactionColor['r'], enemyFactionColor['g'], enemyFactionColor['b'], .9)

	GENERALSSETTINGSInit(enemyFactionColor)
	FEATURESSETTINGSInit(enemyFactionColor)
	OPTIONALSSETTINGSInit(enemyFactionColor)

	-- general tab by default
	for j = 1, settings.numTabs do
		local containerName = string.lower(tabNames[j])
		_G['fosterFramesSettings'..containerName..'Container']:Hide()
	end
			
	_G['fosterFramesSettingsgeneralContainer']:Show()
	PanelTemplates_SetTab(settings, 1)
	
	settings:Show()
	
	if FOSTERFRAMESPLAYERDATA['enableFrames'] then
		if _G['fosterFrameDisplay']:IsShown() then
			fosterFramesDisplayShow = true
		else
			fosterFramesDisplayShow = false
			
			_G['fosterFrameDisplay']:Show()
		end		
		--tinsert(UISpecialFrames, 'fosterFrameDisplay')
	end
	
	FOSTERFRAMESsettings()
	if TARGETFRAMECASTBARsettings then TARGETFRAMECASTBARsettings(true) end
end

local closeSettings = function()
	--settings:Hide() 
	if not fosterFramesDisplayShow and not insideBG then 
		_G['fosterFrameDisplay']:Hide() 
	end 

	if TARGETFRAMECASTBARsettings then TARGETFRAMECASTBARsettings(false) end
end
-- x button
settings.x:SetScript('OnClick', function() 
	 --closeSettings()
	 settings:Hide()
end)

local function eventHandler()
	if event == 'PLAYER_LOGIN' then
		playerFaction = UnitFactionGroup'player'
		hasUnitXP = type(UnitXP) == 'function'
		hasSuperWOW = type(SUPERWOW_VERSION) ~= 'nil' or type(SUPERWOW_STRING) ~= 'nil' or type(SetAutoloot) == 'function'
		hasNampower = type(GetNampowerVersion) == 'function'
		local tc = playerFaction == 'Alliance' and 'FF1A1A' or '00ADF0'
		print('|cff' ..tc.. '[FosterFrames] Use |cffffffff/ffs|cff' ..tc.. ' to open Settings.')
		if hasUnitXP and hasSuperWOW then
			print('|cff' ..tc.. '[FosterFrames] Loaded (UnitXP + SuperWOW mode).')
			FOSTERFRAMESPrintDependencyStatus()
		else
			if not hasUnitXP then
				print('|cffff1a1a[FosterFrames] UnitXP SP3 was not detected. Addon disabled.')
			end
			if not hasSuperWOW then
				print('|cffff1a1a[FosterFrames] SuperWOW was not detected. Addon disabled.')
			end
			print('|cffff1a1a[FosterFrames] Runtime extensions: SuperWOW=' .. (hasSuperWOW and 'yes' or 'no') .. ', Nampower=' .. (hasNampower and 'yes' or 'no') .. '.')
		end
		_G['fosterFrameDisplay']:SetScale(FOSTERFRAMESPLAYERDATA['scale'])
		_G['fosterFrameDisplay']:SetPoint('CENTER', UIParent, FOSTERFRAMESPLAYERDATA['offX'], FOSTERFRAMESPLAYERDATA['offY'])
	elseif event == 'PLAYER_LOGOUT' then
		local point, relativeTo, relativePoint, xOfs, yOfs = _G['fosterFrameDisplay']:GetPoint()
		FOSTERFRAMESPLAYERDATA['offX'] = xOfs
		FOSTERFRAMESPLAYERDATA['offY'] = yOfs
	elseif event == 'ZONE_CHANGED_NEW_AREA' then
		if IsInsideBG then insideBG = IsInsideBG() end
	end
end

local f = CreateFrame'Frame'
f:RegisterEvent'PLAYER_LOGIN'
f:RegisterEvent'PLAYER_LOGOUT'
f:RegisterEvent'ZONE_CHANGED_NEW_AREA'
f:SetScript('OnEvent', eventHandler)

settings:SetScript('OnHide', closeSettings)


SLASH_FOSTERFRAMESSETTINGS1 = '/ffs'
SLASH_FOSTERFRAMESSETTINGS2 = '/fosterframes'
SLASH_FOSTERFRAMESSETTINGS3 = '/ffsettings'
SlashCmdList["FOSTERFRAMESSETTINGS"] = function(msg)
	if settings:IsShown() then
		closeSettings()
	else
		setupSettings()
	end
end
