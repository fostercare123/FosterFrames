
_G = getfenv(0)

print = function(m) DEFAULT_CHAT_FRAME:AddMessage(m) end

tlength = function(t)	local i = 0 for k, j in ipairs(t) do i = i + 1 end return i end

FOSTERFRAMESVERSION = 3.0

local hasSuperWOW = false
local hasNampower = false

function FOSTERFRAMESHasSuperWOW()
	-- The addon can load if any SuperWOW-like environment is found,
	-- but specific functions will be checked at call-site to prevent crashes.
	return (type(UnitGUID) == 'function' or type(SetAutoloot) == 'function' or SUPERWOW_VERSION ~= nil)
end

function FOSTERFRAMESHasGUID()
	return type(UnitGUID) == 'function'
end

function FOSTERFRAMESHasCastInfo()
	return type(UnitCastingInfo) == 'function' and type(UnitChannelInfo) == 'function'
end

function FOSTERFRAMESHasNampower()
	return hasNampower
end

function FOSTERFRAMESPrintDependencyStatus()
	local superwowState = hasSuperWOW and '|cff00ff00yes|r' or '|cffff1a1ano|r'
	local nampowerState = hasNampower and '|cff00ff00yes|r' or '|cffff1a1ano|r'

	print('[FosterFrames] Dependency status: SuperWOW=' .. superwowState .. ', Nampower=' .. nampowerState)
end

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
	-- options
	['scale']					= 1,
	['groupsize']				= 5,
	['layout']					= 'block',
	['frameMovable'] 			= true,
	['enableFrames']			= true,
	-- features
	['mouseOver']				= false,
	['targetFrameCastbar']		= true,
	['integratedTargetFrameCastbar']		= true,
	['targetDebuffTimers']		= false,
	['playerTargetCounter']		= false,
	-- bgs
	['efcBGannouncement']		= true,
	['efcDistanceTracking']		= true,
	-- optionals
	['displayNames']			= true,
	--['displayHealthValues'] = false,
	['displayManabar']			= false,
	['displayOnlyNearby']		= false,
	['castTimers']				= false,		
	['targetCounter']			= false,
	['offX']				= 0,
	['offY']				= 0,
}
end


local playerFaction, insideBG = false
------------ UI ELEMENTS ------------------
local enemyFactionColor
local fosterFramesDisplayShow = false

local settings = CreateFrame('Frame', 'fosterFramesSettings', UIParent)
settings:ClearAllPoints()
settings:SetWidth(450) settings:SetHeight(340)
settings:SetFrameLevel(60)
settings:SetPoint('CENTER', UIParent, 0, 0)
settings:SetBackdrop({bgFile   = [[Interface\Tooltips\UI-Tooltip-Background]],
				  edgeFile = [[Interface\DialogFrame\UI-DialogBox-Border]],
				  insets   = {left = 11, right = 12, top = 12, bottom = 11}})
settings:SetBackdropColor(0, 0, 0, 1)
settings:SetBackdropBorderColor(.2, .2, .2)
settings:SetMovable(true) settings:SetUserPlaced(true)
settings:SetClampedToScreen(true)
settings:RegisterForDrag'LeftButton' settings:EnableMouse(true)
settings:SetScript('OnDragStart', function() settings:StartMoving() end)
settings:SetScript('OnDragStop', function() settings:StopMovingOrSizing() end)
tinsert(UISpecialFrames, 'fosterFramesSettings')
settings:Hide()

-- Sidebar
settings.sidebar = CreateFrame('Frame', nil, settings)
settings.sidebar:SetWidth(100)
settings.sidebar:SetPoint('TOPLEFT', settings, 'TOPLEFT', 11, -40)
settings.sidebar:SetPoint('BOTTOMLEFT', settings, 'BOTTOMLEFT', 11, 11)
settings.sidebar:SetBackdrop({bgFile = [[Interface\Tooltips\UI-Tooltip-Background]]})
settings.sidebar:SetBackdropColor(.1, .1, .1, .5)

-- Content Area
settings.content = CreateFrame('Frame', 'fosterFramesSettingsContent', settings)
settings.content:SetPoint('TOPLEFT', settings.sidebar, 'TOPRIGHT', 5, 0)
settings.content:SetPoint('BOTTOMRIGHT', settings, 'BOTTOMRIGHT', -12, 11)
settings.content:SetBackdrop({bgFile = [[Interface\Tooltips\UI-Tooltip-Background]]})
settings.content:SetBackdropColor(.05, .05, .05, .5)

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

-- Sidebar Buttons
settings.numTabs = 3
local tabNames = {'General', 'Features', 'Optionals'}
settings.tabs = {}
for i = 1, settings.numTabs do
	settings.tabs[i] = CreateFrame('Button', 'fosterFramesSettingsSideButton'..i, settings.sidebar, 'UIPanelButtonTemplate')
	settings.tabs[i]:SetWidth(90) settings.tabs[i]:SetHeight(24)
	settings.tabs[i]:SetText(tabNames[i])
	settings.tabs[i]:SetPoint('TOP', settings.sidebar, 'TOP', 0, -10 - (i-1)*30)
	
	settings.tabs[i].id = i
	settings.tabs[i]:SetScript('OnClick', function()	
		local activeContainerName = string.lower(tabNames[this.id])
		for j = 1, settings.numTabs do	
			local containerName = string.lower(tabNames[j])
			local container = _G['fosterFramesSettings'..containerName..'Container']
			if container then
				if j == this.id then
					container:Show()
				else
					container:Hide()
				end
			end
		end
	end)
end

-- Unlock/Lock Button
settings.unlock = CreateFrame('Button', 'fosterFramesSettingsUnlockButton', settings.sidebar, 'UIPanelButtonTemplate')
settings.unlock:SetWidth(90) settings.unlock:SetHeight(24)
settings.unlock:SetPoint('BOTTOM', settings.sidebar, 'BOTTOM', 0, 40)
settings.unlock:SetText(FOSTERFRAMESPLAYERDATA['frameMovable'] and 'Lock' or 'Unlock')
settings.unlock:SetScript('OnClick', function()
	if FOSTERFRAMESPLAYERDATA['frameMovable'] then
		FOSTERFRAMESPLAYERDATA['frameMovable'] = false
		this:SetText('Unlock')
		if _G['fosterFrameDisplay'].bg then _G['fosterFrameDisplay'].bg:Hide() end
	else
		FOSTERFRAMESPLAYERDATA['frameMovable'] = true
		this:SetText('Lock')
		if _G['fosterFrameDisplay'].bg then _G['fosterFrameDisplay'].bg:Show() end
	end
	FOSTERFRAMESsettings()
end)

-- Reset Button
settings.reset = CreateFrame('Button', 'fosterFramesSettingsResetButton', settings.sidebar, 'UIPanelButtonTemplate')
settings.reset:SetWidth(90) settings.reset:SetHeight(24)
settings.reset:SetPoint('BOTTOM', settings.sidebar, 'BOTTOM', 0, 10)
settings.reset:SetText('Reset Pos')
settings.reset:SetScript('OnClick', function()
	_G['fosterFrameDisplay']:ClearAllPoints()
	_G['fosterFrameDisplay']:SetPoint('CENTER', UIParent, 0, 0)
	FOSTERFRAMESPLAYERDATA['offX'] = 0
	FOSTERFRAMESPLAYERDATA['offY'] = 0
end)

-------------------------------------------


function setupSettings()
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
		local container = _G['fosterFramesSettings'..containerName..'Container']
		if container then container:Hide() end
	end
			
	if _G['fosterFramesSettingsgeneralContainer'] then _G['fosterFramesSettingsgeneralContainer']:Show() end
	
	settings:Show()
	settings.unlock:SetText(FOSTERFRAMESPLAYERDATA['frameMovable'] and 'Lock' or 'Unlock')
	
	if FOSTERFRAMESPLAYERDATA['enableFrames'] then
		if _G['fosterFrameDisplay']:IsShown() then
			fosterFramesDisplayShow = true
		else
			fosterFramesDisplayShow = false
			_G['fosterFrameDisplay']:Show()
		end		
	end
	
	FOSTERFRAMESsettings()
	TARGETFRAMECASTBARsettings(true)
end

local closeSettings = function()
	-- Only hide the display if the user explicitly disabled the addon frames
	if FOSTERFRAMESPLAYERDATA and not FOSTERFRAMESPLAYERDATA['enableFrames'] then 
		_G['fosterFrameDisplay']:Hide() 
	end

	TARGETFRAMECASTBARsettings(false)
end
-- x button
settings.x:SetScript('OnClick', function() 
	 closeSettings()
	 settings:Hide()
end)

local function eventHandler()
	if event == 'PLAYER_LOGIN' then
		playerFaction = UnitFactionGroup'player'
		hasSuperWOW = FOSTERFRAMESHasSuperWOW()
		hasNampower = FOSTERFRAMESHasNampower()
		local tc = playerFaction == 'Alliance' and 'FF1A1A' or '00ADF0'
		print('|cff' ..tc.. '[FosterFrames] Use |cffffffff/ffs|cff' ..tc.. ' to open Settings.')
		if hasSuperWOW then
			print('|cff' ..tc.. '[FosterFrames] Loaded (SuperWOW mode).')
			FOSTERFRAMESPrintDependencyStatus()
		else
			print('|cffff1a1a[FosterFrames] SuperWOW was not detected. Addon disabled.')
		end
		_G['fosterFrameDisplay']:SetScale(FOSTERFRAMESPLAYERDATA['scale'])
		_G['fosterFrameDisplay']:SetPoint('CENTER', UIParent, FOSTERFRAMESPLAYERDATA['offX'], FOSTERFRAMESPLAYERDATA['offY'])
	elseif event == 'PLAYER_LOGOUT' then
		local point, relativeTo, relativePoint, xOfs, yOfs = _G['fosterFrameDisplay']:GetPoint()
		FOSTERFRAMESPLAYERDATA['offX'] = xOfs
		FOSTERFRAMESPLAYERDATA['offY'] = yOfs
	elseif event == 'ZONE_CHANGED_NEW_AREA' then
		insideBG = IsInsideBG()
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
