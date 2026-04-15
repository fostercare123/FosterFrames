	-------------------------------------------------------------------------------
	TACTICALSETTINGSInit = function(color)
		local content = _G['fosterFramesSettingsContent']
		local container = _G['fosterFramesSettingstacticalContainer']

		if not container then
			container = CreateFrame('Frame', 'fosterFramesSettingstacticalContainer', content)
			container:SetAllPoints(content)
			container:EnableMouse(true)
			container:Hide()
			
			local checkBoxTacticalN, checkBoxTactical  = 6, {    
																[1] = {['id'] = 'mouseOver', 			['label'] = 'Enable Mouseover Cast (on Frames)'},
																[2] = {['id'] = 'targetFrameCastbar', 	['label'] = 'Movable Casting Bar for Target'},
																[3] = {['id'] = 'integratedTargetFrameCastbar', 	['label'] = 'Compact Casting Bar (inside Name)'},
																[4] = {['id'] = 'targetDebuffTimers', 	['label'] = 'Show Timer Text on Target Debuffs'},
			[5] = {['id'] = 'specSpecificIcons', 	['label'] = 'Show Talent Spec Icons (instead of Class)'},
			[6] = {['id'] = 'ccAnnounce', 	        ['label'] = 'Announce CCs to Chat (/say, /bg)'},
															}
			
			-- tactical header
			container.tactical = container:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
			container.tactical:SetPoint('TOPLEFT', container, 'TOPLEFT', 20, -20)
			container.tactical:SetText'Tactical Features'

			container.tacticalList = {}
			for i = 1, 6, 1 do
				container.tacticalList[i] = CreateFrame('CheckButton', 'fosterFramesTacticalCheckButton'..i, container, 'UICheckButtonTemplate')
				container.tacticalList[i]:SetHeight(24) 	container.tacticalList[i]:SetWidth(24)
				container.tacticalList[i]:SetPoint('TOPLEFT', i == 1 and container.tactical or container.tacticalList[i-1], 'BOTTOMLEFT', 0, i == 1 and -10 or -10)
				_G[container.tacticalList[i]:GetName()..'Text']:SetText(checkBoxTactical[i]['label'])
				_G[container.tacticalList[i]:GetName()..'Text']:SetPoint('LEFT', container.tacticalList[i], 'RIGHT', 6, 0)
				container.tacticalList[i].id = checkBoxTactical[i]['id']
				container.tacticalList[i]:SetScript('OnClick', function()
					FOSTERFRAMESPLAYERDATA[this.id]	= this:GetChecked()
					FOSTERFRAMESsettings()
				end)
			end
		end

		for i = 1, table.getn(container.tacticalList) do
			_G[container.tacticalList[i]:GetName()..'Text']:SetTextColor(color['r'], color['g'], color['b'], .9)
			container.tacticalList[i]:SetChecked(FOSTERFRAMESPLAYERDATA[container.tacticalList[i].id])
		end
	end
	-------------------------------------------------------------------------------