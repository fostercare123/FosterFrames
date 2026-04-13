	-------------------------------------------------------------------------------
	local msgPrefix = {['RT'] = 'BGEFRT', ['EFC'] = 'BGEFEFC', ['BF'] = 'BGEFEBF'}
	-------------------------------------------------------------------------------
	function sendMSG(typ, d, icon, bg)	
		if icon == nil then icon = '' end
		d = UnitName'player' .. '/' .. d .. '/' .. icon
		local channel = bg and 'BATTLEGROUND' or UnitInRaid('player') and 'RAID' or 'PARTY'
		SendAddonMessage(msgPrefix[typ], d, channel)
	end
	-------------------------------------------------------------------------------
	local raidTarget = function(message)
		local m = '(.+)/(.+)/(.+)'	local fm = string.find(message, m)
				
		if fm then
			local sender 	= string.gsub(message, m, '%1')
			local target 	= string.gsub(message, m, '%2')
			local icon 		= string.gsub(message, m, '%3')
			--print(sender .. ' sets ' .. icon .. ' on ' .. target)
			FOSTERFRAMECORESetRaidTarget(sender, target, icon)
		end
	end
	-------------------------------------------------------------------------------
	local efc = function(message)
		local m = '(.+)/(.+)/(.+)'	local fm = string.find(message, m)
				
		if fm then
			local flagCarriers = {}
			
			local sender 			 = string.gsub(message, m, '%1')
			if sender ~= UnitName'player' then
				flagCarriers['Alliance'] = string.gsub(message, m, '%2')
				flagCarriers['Horde'] 	 = string.gsub(message, m, '%3')
				
				if flagCarriers['Alliance'] == ' ' then flagCarriers['Alliance'] = nil
				--print('no one with alliance flag')
				end
				if flagCarriers['Horde'] 	== ' ' then flagCarriers['Horde'] = nil
				--print('no one with horde flag')
				end
				
				FOSTERFRAMECOREUpdateFlagCarriers(flagCarriers)				
			end
			--print(prefix .. ' - ' .. message)
		end
	end
	-------------------------------------------------------------------------------
	local handleBuff = function(message)
		local m = '(.+)/(.+)/(.+)/(.+)'	local fm = string.find(message, m)
		
		if fm then
			local caster 	= string.gsub(message, m, '%1')
			local tar 		= string.gsub(message, m, '%2')
			local spell		= string.gsub(message, m, '%3')
			local dur		= string.gsub(message, m, '%4')
			
			if caster ~= UnitName'player' then
				SPELLCASTINGCOREaddBuff(tar, spell, dur)
			end
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