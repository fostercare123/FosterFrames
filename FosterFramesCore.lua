local playerFaction
local bgs = {['Warsong Gulch'] = 10, 
			 ['Arathi Basin'] = 15, 
			 ['Blood Ring'] = 10,
			 ['Lordaeron Arena'] = 10,
			 ['Sunstrider Court'] = 10,
			 ['Thorn Gorge'] = 15,
			 --['Alterac Valley'] = 40
			 }
-- TIMERS
local playerListInterval, playerListRefresh, enemyNearbyInterval, enemyNearbyRefresh = 30, 0, .3, 0
local raidMemberIndex = 1
local playerOutdoorLastseen = 60
local insideBG = false
local nextPlayerCheck = 6	-- timer since last seen in seconds
local refreshUnits = true
local globalNearbyCheckTimer, globalNearbyCheckNext = 10, 0
-- LISTS
local playerList = {}
local raidTargets = {}
local prioMembers = {}
local nearbyList = {}
local pendingBGPlayers = {}
local cachedRaidTargets = {}
local maxUnitsDisplayed = 15
local playerTargetCounterList = {}
-- DUMMY FRAME
local f = CreateFrame('Frame', 'fosterFramesCore', UIParent)
--
local playerTargetCounter = 0

-- confirm hostile nearbyPlayers
local function applyNearbyPlayer(v, now, nextCheck)
	local id = v['guid'] or v['name']
	
	if playerList[id] == nil then
		-- if we only have name, check if we already have this player by GUID
		if not v['guid'] then
			for guid, p in pairs(playerList) do
				if p.name == v.name then
					id = guid
					break
				end
			end
		end
		
		if playerList[id] == nil then
			playerList[id] = v
			refreshUnits = true
		end
	end

	local p = playerList[id]
	if p then
		refreshUnits = true
		p['health'] = v['health']
		if v['maxhealth'] then p['maxhealth'] = v['maxhealth'] end
		if v['mana'] then p['mana'] = v['mana'] end
		if v['maxmana'] then p['maxmana'] = v['maxmana'] end
		if v['sex'] then p['sex'] = v['sex'] end
		if v['powerType'] then p['powerType'] = v['powerType'] end
		
		-- Update GUID if we just found it
		if v['guid'] and not p['guid'] then
			playerList[v['guid']] = p
			playerList[v['name']] = nil
			p['guid'] = v['guid']
		end

		if now > enemyNearbyRefresh then
			p['targetcount'] = p['targetcount'] and p['targetcount'] + 1 or 1
		end

		p['nextCheck'] = nextCheck
		p['nearby'] = true
	end
end

local function verifyUnitInfo(unit, now)
	now = now or GetTime()
	if UnitExists(unit) and UnitIsPlayer(unit) and UnitFactionGroup(unit) ~= playerFaction then
		local u = {}
		u['name'] = UnitName(unit)
		local _, c = UnitClass(unit)
		u['class'] = c
		
		u['health'] = UnitHealth(unit)
		u['maxhealth'] = UnitHealthMax(unit)
		
		u['mana'] = UnitMana(unit)
		u['maxmana'] = UnitManaMax(unit)
		local power = UnitPowerType(unit)
		u['powerType'] = power == 3 and 'energy' or power == 1 and 'rage' or 'mana'

		u['guid'] = FOSTERFRAMESHasGUID() and UnitGUID(unit)
		
		applyNearbyPlayer(u, now, now + nextPlayerCheck)
		
		-- update fc health text
		local p = FOSTERFRAMECOREgetPlayer(u['guid'] or u['name'])
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

local function cacheRaidTargets()
	local numRaidMembers = UnitInRaid('player') and GetNumRaidMembers() or GetNumPartyMembers() 
	if numRaidMembers == 0 then 
		cachedRaidTargets = {}
		return 
	end
	
	local groupType = UnitInRaid('player') and 'raid' or 'party'
	local newCache = {}
	for i=1, numRaidMembers do
		local rTarget = groupType .. i .. 'target'
		if UnitExists(rTarget) then
			local name = UnitName(rTarget)
			if name then
				newCache[name] = rTarget
			end
		end
	end
	cachedRaidTargets = newCache
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

-- update unit info: casts, cc, inactive
local function updatePlayerListInfo(now)
	now = now or GetTime()
	local nextCheck = now + nextPlayerCheck

	for k, v in pairs(playerList) do
		-- Determine unitID if target or mouseover using GUID for reliability
		local unitID = (UnitExists('target') and FOSTERFRAMESHasGUID() and v['guid'] == UnitGUID('target')) and 'target' or (UnitExists('mouseover') and FOSTERFRAMESHasGUID() and v['guid'] == UnitGUID('mouseover')) and 'mouseover' or nil
		
		-- Use cache for raid targets (O(1) lookup)
		if not unitID then
			unitID = cachedRaidTargets[v['name']]
		end

		v['castinfo'] = SPELLCASTINGCOREgetCast(v['name'], unitID)
		local buffList = SPELLCASTINGCOREgetBuffs(v['name'], unitID)
		
		if v['castinfo'] or (buffList and table.getn(buffList) > 0) then
			v['nextCheck'] = nextCheck	
			-- set health to 100 for newly seen players if unknown
			if v['nearby'] == false then
				v['health'] = v['maxhealth'] or 100
				v['mana'] = v['maxmana'] or 100
				refreshUnits = true
				v['refresh'] = true
			end
			v['nearby'] = true
		end
		
		-- outdoors
		if not insideBG then
			if not v['nearby'] and v['lastSeen'] and now > v['lastSeen'] then
				playerList[k] = nil
				refreshUnits = true				
			end
		end		
	end
end

local function calculateEFCDistance(now)
	if not FOSTERFRAMESPLAYERDATA['efcDistanceTracking'] then return end
	
	local enemyFaction = playerFaction == 'Alliance' and 'Horde' or 'Alliance'
	local efcName = raidTargets[enemyFaction] and raidTargets[enemyFaction]['name']
	if not efcName then return end

	local efcUnit = nil
	-- scan units
	if UnitExists('target') and UnitName('target') == efcName then efcUnit = 'target'
	elseif UnitExists('mouseover') and UnitName('mouseover') == efcName then efcUnit = 'mouseover'
	else
		for i=1, 40 do
			local rTarget = 'raid'..i..'target'
			if UnitExists(rTarget) and UnitName(rTarget) == efcName then
				efcUnit = rTarget
				break
			end
		end
	end

	if efcUnit then
		local distance = 'unknown'
		if CheckInteractDistance(efcUnit, 3) then distance = '< 10yd'
		elseif CheckInteractDistance(efcUnit, 2) then distance = '< 11yd'
		elseif CheckInteractDistance(efcUnit, 4) then distance = '< 28yd'
		end
		
		if playerList[efcName] then
			playerList[efcName]['efcDistance'] = distance
		end
	end
end

local function globalNearbyMaintenance(now)
	now = now or GetTime()
	local nextSeen = now + playerOutdoorLastseen
	for k, v in pairs(playerList) do
		-- remove inactive player
		if v['nextCheck'] and v['nearby'] then
			if now > v['nextCheck'] then	
				refreshUnits = true 	
				v['nearby'] = false
				v['health'] = v['maxhealth'] or 100
				v['mana'] = v['class'] == 'WARRIOR' and 0 or v['maxmana'] or 100
				
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

local function verifynearbylist(p)
	for k, v in pairs(nearbyList) do
		if v['name'] == p['name'] then
			return k
		end
	end
	return 0
end

local function orderByClass(l, e)
	for j, v in pairs(l) do
		local eClass = e['class'] or 'WARRIOR'
		local vClass = v['class'] or 'WARRIOR'
		local eName = e['name'] or 'Unknown'
		local vName = v['name'] or 'Unknown'
		
		if eClass < vClass or (eClass == vClass and eName < vName) then
			table.insert(l, j, e)
			return l
		end
	end
	table.insert(l, e)
	return l
end

local function orderUnitsforOutput()
	local list = {}
	
	for k, v in pairs(playerList) do
		table.insert(list, v)
	end
	
	table.sort(list, function(a, b)
		-- Sort by nearby first
		if a.nearby ~= b.nearby then
			return a.nearby
		end
		
		-- Then sort by class
		local aClass = a.class or 'WARRIOR'
		local bClass = b.class or 'WARRIOR'
		if aClass ~= bClass then
			return aClass < bClass
		end
		
		-- Then sort by name
		return (a.name or '') < (b.name or '')
	end)
	
	-- Trim to max units
	local result = {}
	for i=1, math.min(table.getn(list), maxUnitsDisplayed) do
		table.insert(result, list[i])
	end
	
	return result
end

local function resetTargetCount()
	for k, v in pairs(playerList) do
		v['targetcount'] = 0
	end
end

local function getPlayerGUIDByName(name)
	for guid, p in pairs(playerList) do
		if p.name == name then return guid end
	end
	return nil
end

--- GLOBAL ACCESS ---
function FOSTERFRAMECOREgetPlayer(nameOrGuid)
	return playerList[nameOrGuid] or playerList[getPlayerGUIDByName(nameOrGuid)]
end

function FOSTERFRAMECOREGetEFCDistance()
	local enemyFaction = playerFaction == 'Alliance' and 'Horde' or 'Alliance'
	local efcName = raidTargets[enemyFaction] and raidTargets[enemyFaction]['name']
	if not efcName then return nil end
	
	local efcUnit = nil
	-- scan units
	if UnitExists('target') and UnitName('target') == efcName then efcUnit = 'target'
	elseif UnitExists('mouseover') and UnitName('mouseover') == efcName then efcUnit = 'mouseover'
	else
		for i=1, 40 do
			local rTarget = 'raid'..i..'target'
			if UnitExists(rTarget) and UnitName(rTarget) == efcName then
				efcUnit = rTarget
				break
			end
		end
	end

	if efcUnit then
		local distance = 'unknown'
		if CheckInteractDistance(efcUnit, 3) then distance = '< 10yd'
		elseif CheckInteractDistance(efcUnit, 2) then distance = '< 11yd'
		elseif CheckInteractDistance(efcUnit, 4) then distance = '< 28yd'
		end
		
		if playerList[efcName] then
			playerList[efcName]['efcDistance'] = distance
		end
		return efcName, distance
	end
	
	if playerList[efcName] then
		return efcName, playerList[efcName]['efcDistance'] or 'unknown'
	end
	return efcName, 'unknown'
end

function FOSTERFRAMECOREUpdateFlagCarriers(fc)
	for k, v in pairs(playerList) do
		local f = v['fc']
		if fc[playerFaction] == nil then
			v['fc'] = false
		else
			v['fc'] = (v['name'] == fc[playerFaction])
		end
		v['refresh'] = (f ~= v['fc'])
	end
	
	refreshUnits = true
	TARGETFRAMEsetFC(fc)
	WSGUIupdateFC(fc)
	WSGHANDLERsetFlagCarriers(fc)
end

function FOSTERFRAMECORESetPlayersData(list)
	local nextCheck = GetTime() + nextPlayerCheck
	for k, v in pairs(list) do
		if playerList[k] then
			playerList[k]['health'] = v['health']
			playerList[k]['nextCheck'] = nextCheck
			playerList[k]['nearby'] = true
			refreshUnits = true
		end
	end
end

function FOSTERFRAMECORESendRaidTarget(icon, name)
	if name == nil or (raidTargets[name] and raidTargets[name]['icon'] == icon) then
		name = 0
	end
	sendMSG('RT', name, icon, insideBG)
	FOSTERFRAMECORESetRaidTarget(nil, name, icon)
end

function FOSTERFRAMECORESetRaidTarget(sender, tar, icon)
	if playerList[tar] then
		removeRaidTarget(tar, icon)
		raidTargets[tar] = {['name'] = playerList[tar].name, ['icon'] = icon}
		if sender ~= nil and sender ~= UnitName'player' then
			FOSTERFRAMESAnnounceRT(raidTargets, playerList[tar])
		end
	end
end

function FOSTERFRAMECOREGetRaidTarget()
	return raidTargets
end

function FOSTERFRAMECOREGetRaidTargetbyIcon(icon)
	for k, v in pairs(raidTargets) do
		if v['icon'] == icon then
			return v['name']
		end
	end
end

IsInsideBG = function()
	return insideBG
end

FOSTERFRAMECOREgetPlayerTargetCounter = function()
	return tlength(playerTargetCounterList)
end

local function fosterFramesCoreOnUpdate()
	local now = GetTime()

	verifyUnitInfo('target', now)
	verifyUnitInfo('mouseover', now)

	if now > enemyNearbyRefresh then
		resetTargetCount()
		cacheRaidTargets()
		getRaidMembersTarget(now)
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

local function initializeValues()
	playerFaction = UnitFactionGroup('player')
	insideBG = bgs[GetZoneText()] and true or false
	
	if insideBG then
		f:RegisterEvent'UPDATE_BATTLEFIELD_SCORE'
		RequestBattlefieldScoreData()
	else
		f:UnregisterEvent'UPDATE_BATTLEFIELD_SCORE'
	end
	
	playerList = {}
	raidTargets = {}
	prioMembers = {}
	nearbyList = {}
	playerListRefresh = 0

	local maxUnits = bgs[GetZoneText()] and bgs[GetZoneText()] or maxUnitsDisplayed
	
	f:SetScript('OnUpdate', fosterFramesCoreOnUpdate)
	FOSTERFRAMESInitialize(maxUnits, insideBG)
	bindingsInit()
	WSGUIinit(insideBG)
end

local function eventHandler()
	local evt = event
	if evt == 'PLAYER_ENTERING_WORLD' or evt == 'ZONE_CHANGED_NEW_AREA' then
		initializeValues()
	elseif evt == 'UPDATE_BATTLEFIELD_SCORE' then
		local numScores = GetNumBattlefieldScores()
		for i=1, numScores do
			-- Correct TurtleWoW/Vanilla 1.12.1 return values:
			-- 1:name, 2:killingBlows, 3:honorableKills, 4:deaths, 5:honorGained, 6:faction, 7:race, 8:class, 9:classToken, 10:damageDone, 11:healingDone
			local name, kb, hk, deaths, honor, faction, race, class, classToken = GetBattlefieldScore(i)
			
			-- faction: 0 for Horde, 1 for Alliance
			local enemyFactionID = playerFaction == 'Alliance' and 0 or 1
			
			if faction == enemyFactionID and name then
				local guid = name -- Use name as unique identifier for scoreboard players
				
				if not playerList[guid] then
					local u = {}
					u['name'] = name
					u['class'] = string.upper(classToken or class or 'WARRIOR')
					u['guid'] = guid
					u['nearby'] = false
					u['health'] = nil
					u['maxhealth'] = 100
					playerList[guid] = u
					refreshUnits = true
				end
			end
		end
	elseif evt == 'UNIT_HEALTH' then
		WSGUIupdateFChealth(arg1)
	end
end

f:RegisterEvent'PLAYER_ENTERING_WORLD'
f:RegisterEvent'ZONE_CHANGED_NEW_AREA'
f:RegisterEvent'UNIT_HEALTH'
f:SetScript('OnEvent', eventHandler)

SLASH_FOSTERFRAMECORE1 = '/ffc'
SLASH_FOSTERFRAMECORE2 = '/fostercore'
SlashCmdList["FOSTERFRAMECORE"] = function(msg)
	if msg == 'bg' then
		print('Scoreboard tracking is disabled (Strict GUID mode).')
	elseif msg == 'deps' then
		if FOSTERFRAMESPrintDependencyStatus then
			FOSTERFRAMESPrintDependencyStatus()
		else
			print('[FosterFrames] Dependency status helper is unavailable.')
		end
	elseif msg == 'near' then
		print('nearbyList:')
		for k, v in pairs(nearbyList) do
			print(v['name'])
		end
	else
		print('playerlist:')
		for k, v in pairs(playerList) do
			print(v['name'] .. ' (' .. k .. ')')
		end
	end
end
