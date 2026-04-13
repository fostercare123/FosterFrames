
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
	local f
	local gotData = false
	local l = {}
	
	if UnitFactionGroup('player') == 'Alliance' then f = 0 else f = 1 end
	-- get opposing faction players
	for i=1, GetNumBattlefieldScores() do
		local name, killingBlows, honorableKills, deaths, honorGained, faction, rank, race, class = GetBattlefieldScore(i)
		if faction == f then
			l[name] = {['name'] = name, ['class'] = string.upper(class)}
			l[name]['powerType']  =  l[name]['class'] == 'ROGUE' and 'energy' or l[name]['class'] == 'WARRIOR' and 'rage' or 'mana'
			gotData = true
		end
	end	
	
	-- add new players
	for k, v in pairs(l) do
		if playerList[v['name']] == nil then	
			playerList[v['name']] = v 		
			refreshUnits = true 
		end
	end
	-- remove aabsent players
	for k, v in pairs(playerList) do
		if l[v['name']] == nil then	
			playerList[v['name']] = nil
			-- check if a nearby player left
			for r, t in pairs(nearbyList) do
				if t['name'] == v['name'] then
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
	if insideBG then
		if playerList[v['name']] then
				--if not playerList[v['name']]['nearby'] or playerList[v['name']]['health'] 	~= v['health'] or playerList[v['name']]['mana'] ~= v['mana'] then
				refreshUnits = true

				playerList[v['name']]['health'] 	= v['health']

				if v['maxhealth']	then	playerList[v['name']]['maxhealth'] 	= v['maxhealth']		end
				if v['mana']	then		playerList[v['name']]['mana'] 		= v['mana']				end
				if v['maxmana']	then		playerList[v['name']]['maxmana'] 	= v['maxmana']			end

				if v['sex']	then			playerList[v['name']]['sex']		= v['sex'] 				end
				if v['powerType'] then		playerList[v['name']]['powerType']	= v['powerType'] 		end

				if now > enemyNearbyRefresh then
					playerList[v['name']]['targetcount'] = playerList[v['name']]['targetcount'] and  playerList[v['name']]['targetcount'] + 1 or 1
				end
				--end

			playerList[v['name']]['nextCheck'] 	= nextCheck
			playerList[v['name']]['nearby'] 	= true			
		end
	else
		refreshUnits = true
		playerList[v['name']] = v

		playerList[v['name']]['nextCheck'] 	= nextCheck
		playerList[v['name']]['nearby'] 	= true

		--if GetTime() > enemyNearbyRefresh then
		--	playerList[v['name']]['targetcount'] = playerList[v['name']]['targetcount'] and  playerList[v['name']]['targetcount'] + 1 or 1
		--end
	end
end

local function verifyUnitInfo(unit, now) --/run print(UnitIsPlayer('target') and 'true' or 'false')
	now = now or GetTime()
	if UnitExists(unit) and UnitIsPlayer(unit) and UnitFactionGroup(unit) ~= playerFaction then --UnitIsEnemy(unit, 'player') then
		local u = {}
		u['name']		= UnitName(unit)
		if not insideBG then
			local _, c = UnitClass(unit)
			u['class']		= c
		end
		u['health'] 	= UnitHealth(unit)
		u['maxhealth'] 	= UnitHealthMax(unit)
		u['mana'] 		= UnitMana(unit)
		u['maxmana']	= UnitManaMax(unit)
		local power = UnitPowerType(unit)
		u['powerType']  =  power == 3 and 'energy' or power == 1 and 'rage' or 'mana'

		applyNearbyPlayer(u, now, now + nextPlayerCheck)
		-- update fc health text
		if playerList[u['name']] and playerList[u['name']]['fc'] then WSGUIupdateFChealth(unit) end
		
		
		return true
	end
	return false
end

local function checkPrioMembers(now)
	for k, v in pairs(prioMembers) do
		if not verifyUnitInfo(v, now) then	prioMembers[k] = nil end
	end
end
--	attempt to get enemy info from raid's targets
-- 	check one every frame rather than all every other frame
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
		local c = v['castinfo']
		v['castinfo'] 	= SPELLCASTINGCOREgetCast(v['name'])
		local unitID = (UnitExists('target') and v['name'] == UnitName('target')) and 'target' or (UnitExists('mouseover') and v['name'] == UnitName('mouseover')) and 'mouseover' or nil
                local buffList = SPELLCASTINGCOREgetBuffs(v['name'], unitID)
		
		if v['castinfo'] or tlength(buffList) > 0 then
			v['nextCheck'] 	= nextCheck	
			-- set health to 100 for newly seen players
			if v['nearby'] == false then	v['health'] = v['maxhealth'] and v['maxhealth'] or 100	v['mana'] = v['maxmana'] and v['maxmana'] or 100	refreshUnits 	= true	v['refresh'] 	= true	end
			v['nearby'] 	= true
			
		end
		
		-- outdoors
		if not insideBG then
			if not v['nearby'] and v['lastSeen'] and now > v['lastSeen'] then
				playerList[v['name']] 	= nil
				refreshUnits 			= true				
			end
		end		
	end
end

local function globalNearbyMaintenance(now)
	now = now or GetTime()
	local nextSeen	= now + playerOutdoorLastseen
	for k, v in pairs(playerList) do
		-- remove inactive player
		if v['nextCheck'] and v['nearby'] then
			if now > v['nextCheck'] then	
				refreshUnits 	= true 	
				v['nearby'] 	= false
				v['health']		= v['maxhealth'] and v['maxhealth'] or 100
				v['mana'] 		= v['class'] == 'WARRIOR' and 0 or v['maxmana'] and v['maxmana']  or 100
				
				if not insideBG then v['lastSeen'] = nextSeen	end 
			end	
		end
	end
end

local function removeRaidTarget(tar, icon)
	-- one icon one target
	for k, v in pairs(raidTargets) do
		if v['icon'] == icon or v['name'] == tar then
			raidTargets[v['name']] = nil
		end
	end
end

local function verifynearbylist( p)
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
	-- order nearby units first -- this loop avoid units jumping from hopping around in the unit matrix
	local i = 1
	
	for k, v in pairs(playerList) do
		if v['nearby'] then
			i = verifynearbylist(v)
			if i ~= 0  then
				nearbyList[i] = v
			else
				table.insert(nearbyList, v)
			end
		else
			i = verifynearbylist(v)
			if i ~= 0 then table.remove(nearbyList, i)	end
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

local playerTargetCounterMaintenance = function()
	if not insideBG then playerTargetCounter = 0 return end
	
	local currentTarget = UnitName'target'
	for k, v in pairs(playerTargetCounterList) do
		if not playerList[v] or not playerList[v]['nearby'] then
			playerTargetCounterList[v] = nil
		--[[else
			TargetByName(v, true)
			if  UnitName'target' ~= v or UnitName'targettarget' ~= UnitName'player' then
				playerTargetCounterList[v] = nil
			end]]--
		end
	end
	--[[
	if not currentTarget then
		ClearTarget()
	else
		TargetByName(currentTarget, true)
	end]]--
end

--- GLOBAL ACCESS ---
function FOSTERFRAMECOREgetPlayer(name)
	return playerList[name]
end

function FOSTERFRAMECOREUpdateFlagCarriers(fc)
	for k, v in pairs(playerList) do
		-- no carriers
		local f = v['fc']
		if fc[playerFaction] == nil then
			v['fc'] = false
		else
			v['fc'] = (v['name'] == fc[playerFaction]) and true or false
		end
		-- refresh if player's fc status changed
		v['refresh'] = f ~= v['fc'] and true or false
	end
	
	refreshUnits = true
	TARGETFRAMEsetFC(fc)
	WSGUIupdateFC(fc)
	WSGHANDLERsetFlagCarriers(fc)
	--[[
	if fc['Alliance'] then
		print('Alliance: ' .. fc['Alliance'])
	else
		print('Alliance: none')
	end
	if fc['Horde'] then
		print('Horde: ' .. fc['Horde'])
	else
		print('Horde: none')
	end]]--
end

function FOSTERFRAMECORESetPlayersData(list)
	local nextCheck = GetTime() + nextPlayerCheck
	
	for k, v in pairs(list) do
		if playerList[k] then
			playerList[k]['health'] 	= v['health']
			playerList[k]['nextCheck'] 	= nextCheck
			playerList[k]['nearby'] 	= true

			refreshUnits = true
		end
	end
end

-- raid target functions
function  FOSTERFRAMECORESendRaidTarget(icon, name)
	if name == nil or (raidTargets[name] and raidTargets[name]['icon'] == icon) then
		name = 0
	end
	
	sendMSG('RT', name, icon, insideBG)
	FOSTERFRAMECORESetRaidTarget(nil, name, icon)
end

function  FOSTERFRAMECORESetRaidTarget(sender, tar, icon)
	removeRaidTarget(tar, icon)
	
	if playerList[tar] then
		raidTargets[tar] = {['name'] = tar, ['icon'] = icon}
		if sender ~= nil and sender ~= UnitName'player' then
			FOSTERFRAMESAnnounceRT(raidTargets, playerList[tar])
		end
	end
end

function  FOSTERFRAMECOREGetRaidTarget()
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
--
--#################--
---------------------

local function fosterFramesCoreOnUpdate()
        local now = GetTime()
        -- get battleground members on UPDATE_BATTLEFIELD_SCORE
        if insideBG and type(RequestBattlefieldScoreData) == 'function' then RequestBattlefieldScoreData() end

        -- use target & mouseover to further populate list
        verifyUnitInfo('target', now)
        verifyUnitInfo('mouseover', now)

        getRaidMembersTarget(now)
        -- check raid targets every enemyNearbyInterval seconds
        if now > enemyNearbyRefresh then
                resetTargetCount()
                checkPrioMembers(now)
                enemyNearbyRefresh = now + enemyNearbyInterval
        end

        -- update player list
        updatePlayerListInfo(now)

        if now > globalNearbyCheckNext then
                globalNearbyMaintenance(now)
                globalNearbyCheckNext = now + globalNearbyCheckTimer
        end

        if FOSTERFRAMESPLAYERDATA['enableFrames'] then
                if refreshUnits then
                        refreshUnits = false
                        FOSTERFRAMESUpdatePlayers(orderUnitsforOutput())
                end

                if not _G['fosterFramesSettings']:IsShown() then
                        if next(playerList) == nil then
                                _G['fosterFrameDisplay']:Hide()
                        else
                                _G['fosterFrameDisplay']:Show()
                        end
                else
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
        -- enable ui elements
        FOSTERFRAMESInitialize(maxUnits, insideBG)
        bindingsInit()
        WSGUIinit(insideBG)
end

	insideBG = false
	playerFaction = UnitFactionGroup('player')
		
	playerList = {}
	raidTargets = {}
	prioMembers = {}
	nearbyList = {}
	playerListRefresh = 0
		
	local maxUnits = bgs[GetZoneText()] and bgs[GetZoneText()] or maxUnitsDisplayed
	if maxUnits then
		--
		insideBG = bgs[GetZoneText()] and true or false
		
		if insideBG then f:RegisterEvent'UPDATE_BATTLEFIELD_SCORE'	end
		f:SetScript('OnUpdate', fosterFramesCoreOnUpdate)
		-- enable ui elements
		FOSTERFRAMESInitialize(maxUnits, insideBG)
		bindingsInit()
		WSGUIinit(insideBG)
	else
		f:UnregisterEvent'UPDATE_BATTLEFIELD_SCORE'
		-- nil value to disable ui elements
		FOSTERFRAMESInitialize(nil)
		f:SetScript('OnUpdate', nil)
	end
end



    if not playerList[name] then
        -- We don't know their class yet, but we'll try to find out when we target/mouseover
        -- For now, add them as unknown or wait for verifyUnitInfo
        -- SuperWOW often allows getting class from name or GUID if nearby
        playerList[name] = {['name'] = name, ['class'] = 'UNKNOWN', ['nearby'] = true, ['lastSeen'] = GetTime() + playerOutdoorLastseen}
        refreshUnits = true
    else
        playerList[name]['nearby'] = true
        playerList[name]['lastSeen'] = GetTime() + playerOutdoorLastseen
    end
end

local function eventHandler(_, eventName, unit)
        local evt = eventName or event
        if evt == 'PLAYER_ENTERING_WORLD' or evt == 'ZONE_CHANGED_NEW_AREA' then
                initializeValues()
        elseif evt == 'UPDATE_BATTLEFIELD_SCORE' then
                local now = GetTime()
                -- fill player list
                if now > playerListRefresh then
                        if fillPlayerList()     then
                                playerListRefresh = now + playerListInterval
                        end
                end
        elseif evt == 'UNIT_HEALTH' then
                WSGUIupdateFChealth(unit or arg1)

        end
end
	
	elseif evt == 'UNIT_HEALTH' then
		WSGUIupdateFChealth(unit or arg1)
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

