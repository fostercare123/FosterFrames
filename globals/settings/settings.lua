
print = function(m) DEFAULT_CHAT_FRAME:AddMessage(m) end
tlength = function(t)	local i = 0 for k, j in pairs(t) do i = i + 1 end return i end

FOSTERFRAMESVERSION = 3.0

-- Initialize SavedVariables immediately if they don't exist
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
	['openWorldScanning']		= true,
	['specSpecificIcons']		= true,
	['smartDistanceSorting']	= false,
	['ccAnnounce']				= false,
	['displayHealthValues']     = false,
	['displayManaValues']       = false,
	-- bgs
	['efcBGannouncement']		= true,
	['efcDistanceTracking']		= true,
	-- optionals
	['displayNames']			= true,
	['displayManabar']			= false,
	['displayOnlyNearby']		= false,
	['castTimers']				= false,		
	['targetCounter']			= false,
	['offX']				= 0,
	['offY']				= 0,
    }
end

local hasSuperWOW = false
local hasNampower = false
local hasUnitXP = false

local function FOSTERFRAMESHasSuperWOW_Internal()
	return (type(UnitGUID) == 'function' or type(SetAutoloot) == 'function' or SUPERWOW_VERSION ~= nil)
end

function FOSTERFRAMESHasSuperWOW()
	if FosterFrames.Config.hasSuperWOW ~= nil then return FosterFrames.Config.hasSuperWOW end
	return FOSTERFRAMESHasSuperWOW_Internal()
end

function FOSTERFRAMESHasGUID()
	return type(UnitGUID) == 'function'
end

function FOSTERFRAMESHasSpecDetection()
	return type(UnitTalent) == 'function' or type(UnitSpec) == 'function'
end

function FOSTERFRAMESGetUnitSpec(unit)
    if not unit or not UnitExists(unit) then return nil end
    
    -- Try SuperWOW UnitSpec directly
    if type(UnitSpec) == 'function' then
        local spec = UnitSpec(unit)
        if spec and spec ~= "" then return spec end
    end
    
    -- Fallback/Alternative: UnitTalent scanning
    if type(UnitTalent) == 'function' then
        local tabs = { [1]=0, [2]=0, [3]=0 }
        for i=1, 3 do
            local _, _, points = UnitTalent(unit, i)
            tabs[i] = points or 0
        end
        
        local maxPoints, specIndex = 0, 1
        for i, points in pairs(tabs) do
            if points > maxPoints then
                maxPoints = points
                specIndex = i
            end
        end
        
        local _, class = UnitClass(unit)
        if not class then return nil end
        
        local specs = {
            ['WARRIOR'] = {[1]='Arms', [2]='Fury', [3]='Protection'},
            ['PALADIN'] = {[1]='Holy', [2]='Protection', [3]='Retribution'},
            ['HUNTER']  = {[1]='BeastMastery', [2]='Marksmanship', [3]='Survival'},
            ['ROGUE']   = {[1]='Assassination', [2]='Combat', [3]='Subtlety'},
            ['PRIEST']  = {[1]='Holy', [2]='Discipline', [3]='Shadow'},
            ['SHAMAN']  = {[1]='Elemental', [2]='Enhancement', [3]='Restoration'},
            ['MAGE']    = {[1]='Arcane', [2]='Fire', [3]='Frost'},
            ['WARLOCK'] = {[1]='Affliction', [2]='Demonology', [3]='Destruction'},
            ['DRUID']   = {[1]='Balance', [2]='Feral', [3]='Restoration'}
        }
        
        if specs[class] then return specs[class][specIndex] end
    end
    
    return nil
end

function FOSTERFRAMESHasCastInfo()
	return type(UnitCastingInfo) == 'function' and type(UnitChannelInfo) == 'function'
end

function FOSTERFRAMESHasNampower()
	return FosterFrames.Config.hasNampower
end

function FOSTERFRAMESHasUnitXP()
	return FosterFrames.Config.hasUnitXP
end

function FOSTERFRAMESPrintDependencyStatus()
	local superwowState = FosterFrames.Config.hasSuperWOW and '|cff00ff00yes|r' or '|cffff1a1ano|r'
	local nampowerState = FosterFrames.Config.hasNampower and '|cff00ff00yes|r' or '|cffff1a1ano|r'
	local unitxpState = FosterFrames.Config.hasUnitXP and '|cff00ff00yes|r' or '|cffff1a1ano|r'

	print('|cffae7cee[FosterFrames]|r Dependency status: SuperWOW=' .. superwowState .. ', Nampower=' .. nampowerState .. ', UnitXP=' .. unitxpState)
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
	['openWorldScanning']		= true,
	['specSpecificIcons']		= true,
	['smartDistanceSorting']	= false,
	['ccAnnounce']				= false,
	-- bgs
	['efcBGannouncement']		= true,
	['efcDistanceTracking']		= true,
	-- optionals
	['displayNames']			= true,
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
settings.numTabs = 4
local tabNames = {'General', 'Tactical', 'Automation', 'Appearance'}
settings.tabs = {}
for i = 1, settings.numTabs do
	settings.tabs[i] = CreateFrame('Button', 'fosterFramesSettingsSideButton'..i, settings.sidebar, 'UIPanelButtonTemplate')
	settings.tabs[i]:SetWidth(90) settings.tabs[i]:SetHeight(24)
	settings.tabs[i]:SetText(tabNames[i])
	settings.tabs[i]:SetPoint('TOP', settings.sidebar, 'TOP', 0, -10 - (i-1)*30)
	
	settings.tabs[i].id = i
	settings.tabs[i]:SetScript('OnClick', function()	
		for j = 1, settings.numTabs do	
			local containerName = string.lower(tabNames[j])
			local container = getglobal('fosterFramesSettings'..containerName..'Container')
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
		if fosterFrameDisplay and fosterFrameDisplay.bg then fosterFrameDisplay.bg:Hide() end
	else
		FOSTERFRAMESPLAYERDATA['frameMovable'] = true
		this:SetText('Lock')
		if fosterFrameDisplay and fosterFrameDisplay.bg then fosterFrameDisplay.bg:Show() end
	end
	if FOSTERFRAMESsettings then FOSTERFRAMESsettings() end
end)

-- Reset Button
settings.reset = CreateFrame('Button', 'fosterFramesSettingsResetButton', settings.sidebar, 'UIPanelButtonTemplate')
settings.reset:SetWidth(90) settings.reset:SetHeight(24)
settings.reset:SetPoint('BOTTOM', settings.sidebar, 'BOTTOM', 0, 10)
settings.reset:SetText('Reset Pos')
settings.reset:SetScript('OnClick', function()
	if fosterFrameDisplay then
		fosterFrameDisplay:ClearAllPoints()
		fosterFrameDisplay:SetPoint('CENTER', UIParent, 0, 0)
	end
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
	settings.header.t:SetTextColor(0.68, 0.49, 0.93, .9)

	if GENERALSSETTINGSInit then GENERALSSETTINGSInit(enemyFactionColor) end
	if TACTICALSETTINGSInit then TACTICALSETTINGSInit(enemyFactionColor) end
	if AUTOMATIONSETTINGSInit then AUTOMATIONSETTINGSInit(enemyFactionColor) end
	if APPEARANCESETTINGSInit then APPEARANCESETTINGSInit(enemyFactionColor) end

	-- general tab by default
	for j = 1, settings.numTabs do
		local containerName = string.lower(tabNames[j])
		local container = getglobal('fosterFramesSettings'..containerName..'Container')
		if container then container:Hide() end
	end
			
	if getglobal('fosterFramesSettingsgeneralContainer') then getglobal('fosterFramesSettingsgeneralContainer'):Show() end
	
	settings:Show()
	settings.unlock:SetText(FOSTERFRAMESPLAYERDATA['frameMovable'] and 'Lock' or 'Unlock')
	
	if FOSTERFRAMESPLAYERDATA['enableFrames'] and fosterFrameDisplay then
		if fosterFrameDisplay:IsShown() then
			fosterFramesDisplayShow = true
		else
			fosterFramesDisplayShow = false
			fosterFrameDisplay:Show()
		end		
	end
	
	if FOSTERFRAMESsettings then FOSTERFRAMESsettings() end
	if TARGETFRAMECASTBARsettings then TARGETFRAMECASTBARsettings(true) end
end

function closeSettings()
	-- Only hide the display if the user explicitly disabled the addon frames
	if FOSTERFRAMESPLAYERDATA and not FOSTERFRAMESPLAYERDATA['enableFrames'] and fosterFrameDisplay then 
		fosterFrameDisplay:Hide() 
	end

	if TARGETFRAMECASTBARsettings then TARGETFRAMECASTBARsettings(false) end
end
-- x button
settings.x:SetScript('OnClick', function() 
	 closeSettings()
	 settings:Hide()
end)

local function eventHandler()
	if event == 'PLAYER_LOGIN' then
		playerFaction = UnitFactionGroup'player'
		FosterFrames.Config.hasSuperWOW = FOSTERFRAMESHasSuperWOW_Internal()
		FosterFrames.Config.hasNampower = IsAddOnLoaded("Nampower") or IsAddOnLoaded("NampowerSettings")
		FosterFrames.Config.hasUnitXP = IsAddOnLoaded("UnitXP_SP3_Addon")
		local tc = 'ae7cee'
		print('|cff' ..tc.. '[FosterFrames] Use |cffffffff/ffs|cff' ..tc.. ' to open Settings.')
		if FosterFrames.Config.hasSuperWOW then
			print('|cff' ..tc.. '[FosterFrames] Loaded (SuperWOW mode).')
			FOSTERFRAMESPrintDependencyStatus()
		else
			print('|cffae7cee[FosterFrames] SuperWOW was not detected. Addon disabled.')
		end
		if fosterFrameDisplay then
			fosterFrameDisplay:SetScale(FOSTERFRAMESPLAYERDATA['scale'])
			fosterFrameDisplay:SetPoint('CENTER', UIParent, FOSTERFRAMESPLAYERDATA['offX'], FOSTERFRAMESPLAYERDATA['offY'])
		end
	elseif event == 'PLAYER_LOGOUT' then
		if fosterFrameDisplay then
			local point, relativeTo, relativePoint, xOfs, yOfs = fosterFrameDisplay:GetPoint()
			FOSTERFRAMESPLAYERDATA['offX'] = xOfs
			FOSTERFRAMESPLAYERDATA['offY'] = yOfs
		end
	elseif event == 'ZONE_CHANGED_NEW_AREA' then
		if FOSTERFRAMECOREIsInsideBG then
			insideBG = FOSTERFRAMECOREIsInsideBG()
		end
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
		settings:Hide()
	else
		setupSettings()
	end
end
