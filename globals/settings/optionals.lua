	-------------------------------------------------------------------------------
	OPTIONALSSETTINGSInit = function(color)
		local content = _G['fosterFramesSettingsContent']
		local container = _G['fosterFramesSettingsoptionalsContainer']

		if not container then
			container = CreateFrame('Frame', 'fosterFramesSettingsoptionalsContainer', content)
			container:SetAllPoints(content)
			container:EnableMouse(true)
			container:Hide()
			
			local checkBoxOptionalsN, checkBoxOptionals  = 5, { [1] = {['id'] = 'displayNames', 		['label'] = 'Display Names'}, 
																--[2] = {['id'] = 'displayHealthValues', 	['label'] = 'Display Health %'}, 
																[2] = {['id'] = 'displayManabar', 		['label'] = 'Display Mana Bar'},
																[3] = {['id'] = 'castTimers', 			['label'] = 'Display Cast Timers'},
																[4] = {['id'] = 'displayOnlyNearby', 	['label'] = 'Display Nearby Units Only'},
																[5] = {['id'] = 'targetCounter', 		['label'] = 'Display Target Counter'},
																
															}
			
			-- optionals
			container.optionals = container:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
			container.optionals:SetPoint('TOPLEFT', container, 'TOPLEFT', 20, -20)
			container.optionals:SetText'Optionals'

			container.optinalsList = {}
			for i = 1, checkBoxOptionalsN, 1 do
				container.optinalsList[i] = CreateFrame('CheckButton', 'fosterFramesOptionalsCheckButton'..i, container, 'UICheckButtonTemplate')
				container.optinalsList[i]:SetHeight(24) 	container.optinalsList[i]:SetWidth(24)
				container.optinalsList[i]:SetPoint('TOPLEFT', i == 1 and container.optionals or container.optinalsList[i-1], 'BOTTOMLEFT', 0, i == 1 and -10 or -10)
				_G[container.optinalsList[i]:GetName()..'Text']:SetText(checkBoxOptionals[i]['label'])
				_G[container.optinalsList[i]:GetName()..'Text']:SetPoint('LEFT', container.optinalsList[i], 'RIGHT', 6, 0)

				container.optinalsList[i].id = checkBoxOptionals[i]['id']
				container.optinalsList[i]:SetScript('OnClick', function()
					FOSTERFRAMESPLAYERDATA[this.id]	= this:GetChecked()
					FOSTERFRAMESsettings()
				end)
			end
		end

		for i = 1, table.getn(container.optinalsList) do
			_G[container.optinalsList[i]:GetName()..'Text']:SetTextColor(color['r'], color['g'], color['b'], .9)
			container.optinalsList[i]:SetChecked(FOSTERFRAMESPLAYERDATA[container.optinalsList[i].id])
		end
	end
	-------------------------------------------------------------------------------