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
local maxUnitsDisplayed = 15
local playerTargetCounterList = {}
-- DUMMY FRAME
local f = CreateFrame('Frame', 'fosterFramesCore', UIParent)
--
local playerTargetCounter = 0

local function fillPlayerList()
	local factionID
	local gotData = false
	local l = {}
	
	if UnitFactionGroup('player') == 'Alliance' then factionID = 0 else factionID = 1 end
	-- get opposing faction players from scoreboard
	for i=1, GetNumBattlefieldScores() do
		local name, killingBlows, honorableKills, deaths, honorGained, faction, rank, race, class = GetBattlefieldScore(i)
		if faction == factionID then
			-- In scoreboard we only have names, use name as key if GUID not known
			l[name] = {['name'] = name, ['class'] = string.upper(class)}
			l[name]['powerType']  =  l[name]['class'] == 'ROGUE' and 'energy' or l[name]['class'] == 'WARRIOR' and 'rage' or 'mana'
			gotData = true
		end
	end	
	
	-- add new players or update existing
	for name, v in pairs(l) do
		if playerList[name] == nil then	
			playerList[name] = v 		
			refreshUnits = true 
		end
	end
	-- remove absent players
	for name, v in pairs(playerList) do
		if l[name] == nil then	
			playerList[name] = nil
			-- check if a nearby player left
			for r, t in pairs(nearbyList) do
				if t['name'] == name then
					nearbyList[r] = nil
				end
			end				
			refreshUnits = true 
		end
	end

	return gotData
end

-- confirm hostile nearbyPlayers
local function applyNearbyPlayer(v, now, nextCheck)
	local identifier = v.guid or v.name
	local p = playerList[identifier] or playerList[v.name]
	
	if not p then
		if not insideBG then
			playerList[identifier] = v
			p = playerList[identifier]
			refreshUnits = true
		else
			return -- Don't add if in BG but not in scoreboard?
		end
	end

	if p then
		refreshUnits = true
		p['health'] = v['health']
		if v['maxhealth'] then p['maxhealth'] = v['maxhealth'] end
		if v['mana'] then p['mana'] = v['mana'] end
		if v['maxmana'] then p['maxmana'] = v['maxmana'] end
		if v['sex'] then p['sex'] = v['sex'] end
		if v['powerType'] then p['powerType'] = v['powerType'] end
		if v['guid'] then p['guid'] = v['guid'] end

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
		u['guid'] = UnitGUID(unit)
		
		if not insideBG then
			local _, c = UnitClass(unit)
			u['class'] = c
		end

		-- Use UnitXP for actual health values if available
		if FOSTERFRAMESHasUnitXP() and type(UnitXP) == 'function' then
			u['health'] = UnitXP(unit) or UnitHealth(unit)
			u['maxhealth'] = UnitXP(unit, true) or UnitHealthMax(unit) -- Assuming UnitXP(u, true) returns max
		else
			u['health'] = UnitHealth(unit)
			u['maxhealth'] = UnitHealthMax(unit)
		end
		
		u['mana'] = UnitMana(unit)
		u['maxmana'] = UnitManaMax(unit)
		local power = UnitPowerType(unit)
		u['powerType'] = power == 3 and 'energy' or power == 1 and 'rage' or 'mana'

		applyNearbyPlayer(u, now, now + nextPlayerCheck)
		
		-- update fc health text
		local p = playerList[u.guid or u.name]
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
		local unitID = (UnitExists('target') and v['guid'] == UnitGUID('target')) and 'target' or (UnitExists('mouseover') and v['guid'] == UnitGUID('mouseover')) and 'mouseover' or nil
		
		-- Also check raid targets
		if not unitID then
			for i=1, 40 do
				local rTarget = 'raid'..i..'target'
				if UnitExists(rTarget) and UnitName(rTarget) == v['name'] then
					unitID = rTarget
					break
				end
			end
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
		if e['class'] < v['class'] or (e['class'] == v['class'] and e['name'] < v['name']) then
			table.insert(l, j, e)
			return l
		end
	end
	table.insert(l, e)
	return l
end

local function orderUnitsforOutput()
	local list, listb = {}, {}
	local i = 1
	
	for k, v in pairs(playerList) do
		if v['nearby'] then
			i = verifynearbylist(v)
			if i ~= 0 then
				nearbyList[i] = v
			else
				table.insert(nearbyList, v)
			end
		else
			i = verifynearbylist(v)
			if i ~= 0 then table.remove(nearbyList, i) end
			listb = orderByClass(listb, v)
		end
	end
	
	i = 0
	-- maintain same order
	for k, v in pairs(nearbyList) do
		table.insert(list, v)
		i = i + 1
		if i == maxUnitsDisplayed then return list end
	end
	for k, v in pairs(listb) do
		table.insert(list, v)
		i = i + 1
		if i == maxUnitsDisplayed then return list end
	end
	
	return list
end

local function resetTargetCount()
	for k, v in pairs(playerList) do
		v['targetcount'] = 0
	end
end

--- GLOBAL ACCESS ---
function FOSTERFRAMECOREgetPlayer(name)
	return playerList[name]
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
	removeRaidTarget(tar, icon)
	if playerList[tar] then
		raidTargets[tar] = {['name'] = tar, ['icon'] = icon}
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
	if insideBG then RequestBattlefieldScoreData() end

	verifyUnitInfo('target', now)
	verifyUnitInfo('mouseover', now)
	getRaidMembersTarget(now)

	if now > enemyNearbyRefresh then
		resetTargetCount()
		checkPrioMembers(now)
		enemyNearbyRefresh = now + enemyNearbyInterval
	end

	updatePlayerListInfo(now)

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
	if not FOSTERFRAMESHasUnitXP or not FOSTERFRAMESHasUnitXP() or not FOSTERFRAMESHasSuperWOW or not FOSTERFRAMESHasSuperWOW() then
		f:UnregisterEvent'UPDATE_BATTLEFIELD_SCORE'
		FOSTERFRAMESInitialize(nil)
		f:SetScript('OnUpdate', nil)
		return
	end

	playerFaction = UnitFactionGroup('player')
	insideBG = bgs[GetZoneText()] and true or false
	
	playerList = {}
	raidTargets = {}
	prioMembers = {}
	nearbyList = {}
	playerListRefresh = 0

	local maxUnits = bgs[GetZoneText()] and bgs[GetZoneText()] or maxUnitsDisplayed
	
	if insideBG then 
		f:RegisterEvent'UPDATE_BATTLEFIELD_SCORE'
	else
		f:UnregisterEvent'UPDATE_BATTLEFIELD_SCORE'
	end
	
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
		local now = GetTime()
		if now > playerListRefresh then
			if fillPlayerList() then
				playerListRefresh = now + playerListInterval
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
		print('bg info:')
		for i=1, GetNumBattlefieldScores() do
			local name = GetBattlefieldScore(i)
			print(name)
		end	
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
			print(v['name'])
		end
	end
end
