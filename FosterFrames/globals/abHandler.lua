	-------------------------------------------------------------------------------
	local playerFaction = UnitFactionGroup('player')
	local arathiBases = {
		['Stables'] = true,
		['Gold Mine'] = true,
		['Blacksmith'] = true,
		['Lumber Mill'] = true,
		['Farm'] = true,
	}
	local lastABWarning = {}

	local function warnArathiCap(baseName)
		local now = GetTime()
		if lastABWarning[baseName] and (now - lastABWarning[baseName]) < 1 then
			return
		end
		lastABWarning[baseName] = now

		local msg = 'Enemy is capping ' .. baseName .. '!'
		if RaidNotice_AddMessage and RaidWarningFrame then
			RaidNotice_AddMessage(RaidWarningFrame, msg, ChatTypeInfo['RAID_WARNING'])
		end
		if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
			DEFAULT_CHAT_FRAME:AddMessage('|cffff3030[FosterFrames]|r ' .. msg)
		end
	end
	-------------------------------------------------------------------------------
	local function eventHandler()
		if GetZoneText() ~= 'Arathi Basin' then
			return
		end

		local _, _, assaultBase, assaultFaction = string.find(arg1 or '', 'The (.+) has been assaulted by the (.+)!')
		if assaultBase and assaultFaction and arathiBases[assaultBase] and assaultFaction ~= playerFaction then
			warnArathiCap(assaultBase)
		end
	end
	-------------------------------------------------------------------------------
	local f = CreateFrame'Frame'
	f:RegisterEvent'PLAYER_ENTERING_WORLD'
	f:RegisterEvent'ZONE_CHANGED_NEW_AREA'
	f:RegisterEvent'CHAT_MSG_BG_SYSTEM_ALLIANCE'
	f:RegisterEvent'CHAT_MSG_BG_SYSTEM_HORDE'
	f:SetScript('OnEvent', function()
		if event == 'PLAYER_ENTERING_WORLD' or event == 'ZONE_CHANGED_NEW_AREA' then
			playerFaction = UnitFactionGroup('player')
			lastABWarning = {}
		else
			eventHandler()
		end
	end)
	-------------------------------------------------------------------------------
