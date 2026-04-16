	-------------------------------------------------------------------------------
	local msgPrefix = {['RT'] = 'BGEFRT', ['EFC'] = 'BGEFEFC', ['BF'] = 'BGEFEBF', ['SCAN'] = 'BGEFSCN'}
	-------------------------------------------------------------------------------
	function sendMSG(typ, d, icon, bg)	
		if icon == nil or icon == '' then icon = ' ' end
		d = UnitName'player' .. '/' .. d .. '/' .. icon
		local channel = bg and 'BATTLEGROUND' or UnitInRaid('player') and 'RAID' or 'PARTY'
		if (not UnitInRaid('player') and GetNumPartyMembers() == 0) then return end
		SendAddonMessage(msgPrefix[typ], d, channel)
	end
	-------------------------------------------------------------------------------
	local handleScan = function(message)
		local m = '([^/]+)/([^/]+)/([^/]+)/([^/]+)'
		local _, _, sender, name, class, guid = string.find(message, m)
				
		if sender and sender ~= UnitName'player' then
			local u = {}
			u['name'] = name
			u['class'] = class ~= ' ' and class or nil
			u['guid'] = guid ~= ' ' and guid or nil
			FOSTERFRAMECOREAddSpottedUnit(u)
		end
	end
	-------------------------------------------------------------------------------
	local raidTarget = function(message)
		local m = '([^/]+)/([^/]+)/([^/]+)'
		local _, _, sender, target, icon = string.find(message, m)
				
		if sender then
			FOSTERFRAMECORESetRaidTarget(sender, target, icon)
		end
	end
	-------------------------------------------------------------------------------
	local efc = function(message)
		local m = '([^/]+)/([^/]+)/([^/]+)'
		local _, _, sender, allianceEFC, hordeEFC = string.find(message, m)
				
		if sender and sender ~= UnitName'player' then
			local flagCarriers = {}
			flagCarriers['Alliance'] = allianceEFC ~= ' ' and allianceEFC or nil
			flagCarriers['Horde'] 	 = hordeEFC ~= ' ' and hordeEFC or nil
			
			FOSTERFRAMECOREUpdateFlagCarriers(flagCarriers)				
		end
	end
	-------------------------------------------------------------------------------
	local handleBuff = function(message)
		local m = '([^/]+)/([^/]+)/([^/]+)/([^/]+)'
		local _, _, caster, tar, spell, dur = string.find(message, m)
		
		if caster and caster ~= UnitName'player' then
			SPELLCASTINGCOREaddBuff(tar, spell, dur)
		end
	end
	-------------------------------------------------------------------------------
	local function eventHandler(_, _, prefix, message)
		local msgPrefixValue = prefix or arg1
		local msgData = message or arg2
		local prefixPattern = 'BGEF(.+)'			local fprefix = string.find(msgPrefixValue or '', prefixPattern)
		
		if fprefix then
			-- raid targets
			if  msgPrefixValue == msgPrefix['RT'] then
				raidTarget(msgData)
			-- seen EFC
			elseif  msgPrefixValue == msgPrefix['EFC']  then
				efc(msgData)
			-- spotted enemy
			elseif msgPrefixValue == msgPrefix['SCAN'] then
				handleScan(msgData)
			-- unique debuff
			elseif msgPrefixValue == msgPrefix['BF']  then
				handleBuff(msgData)
			end
		end
	end
	-------------------------------------------------------------------------------
	local f = CreateFrame'frame'
	f:RegisterEvent'CHAT_MSG_ADDON'
	f:SetScript('OnEvent', eventHandler)
	-------------------------------------------------------------------------------