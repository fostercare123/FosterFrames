	_G = getfenv(0)
	-------------------------------------------------------------------------------
	AUTOMATIONSETTINGSInit = function(color)
		local content = _G['fosterFramesSettingsContent']
		local container = _G['fosterFramesSettingsautomationContainer']

		if not container then
			container = CreateFrame('Frame', 'fosterFramesSettingsautomationContainer', content)
			container:SetAllPoints(content)
			container:EnableMouse(true)
			container:Hide()
			
			local checkBoxAutoN, checkBoxAuto  = 4, {    [1] = {['id'] = 'openWorldScanning', 	['label'] = 'Scan Players in Open World (Non-BG)'},
																[2] = {['id'] = 'smartDistanceSorting', ['label'] = 'Sort Frames by Distance (Closest first)'},
																[3] = {['id'] = 'efcDistanceTracking', 	['label'] = 'Track Distance to Flag Carrier (WSG)'},
			[4] = {['id'] = 'efcBGannouncement', 	['label'] = 'Alert Chat when EFC has Low Health'},
			}			
			-- automation header
			container.automation = container:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
			container.automation:SetPoint('TOPLEFT', container, 'TOPLEFT', 20, -20)
			container.automation:SetText'Automation & Battlegrounds'

			container.automationList = {}
			for i = 1, checkBoxAutoN, 1 do
				container.automationList[i] = CreateFrame('CheckButton', 'fosterFramesAutomationCheckButton'..i, container, 'UICheckButtonTemplate')
				container.automationList[i]:SetHeight(24) 	container.automationList[i]:SetWidth(24)
				container.automationList[i]:SetPoint('TOPLEFT', i == 1 and container.automation or container.automationList[i-1], 'BOTTOMLEFT', 0, i == 1 and -10 or -10)
				_G[container.automationList[i]:GetName()..'Text']:SetText(checkBoxAuto[i]['label'])
				_G[container.automationList[i]:GetName()..'Text']:SetPoint('LEFT', container.automationList[i], 'RIGHT', 6, 0)

				container.automationList[i].id = checkBoxAuto[i]['id']
				container.automationList[i]:SetScript('OnClick', function()
					FOSTERFRAMESPLAYERDATA[this.id]	= this:GetChecked()
					if FOSTERFRAMESsettings then FOSTERFRAMESsettings() end
				end)
			end
		end

		for i = 1, table.getn(container.automationList) do
			_G[container.automationList[i]:GetName()..'Text']:SetTextColor(color['r'], color['g'], color['b'], .9)
			container.automationList[i]:SetChecked(FOSTERFRAMESPLAYERDATA[container.automationList[i].id])
		end
	end
	-------------------------------------------------------------------------------