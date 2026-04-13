	-------------------------------------------------------------------------------
	FEATURESSETTINGSInit = function(color)
		local content = _G['fosterFramesSettingsContent']
		local container = _G['fosterFramesSettingsfeaturesContainer']

		if not container then
			container = CreateFrame('Frame', 'fosterFramesSettingsfeaturesContainer', content)
			container:SetAllPoints(content)
			container:EnableMouse(true)
			container:Hide()
			
			local checkBoxFeaturesN, checkBoxFeatures  = 4, {
																[1] = {['id'] = 'mouseOver', 			['label'] = 'Mouseover Cast On Frames'},	
																[2] = {['id'] = 'targetFrameCastbar', 	['label'] = 'Movable Target Cast Bar'},														
																[3] = {['id'] = 'integratedTargetFrameCastbar', 	['label'] = 'Integrated Target Cast Bar'},
																[4] = {['id'] = 'targetDebuffTimers', 	['label'] = 'Debuff Timers On Target'},
																
															}
			local checkBoxFeaturesBGN, checkBoxFeaturesBG  = 1, {	[1] = {['id'] = 'efcBGannouncement', 	['label'] = 'Low Health EFC Announcement'},
																	
																}
			
			-- features
			container.features = container:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
			container.features:SetPoint('TOPLEFT', container, 'TOPLEFT', 20, -20)
			container.features:SetText'Features'

			container.featuresList = {}
			for i = 1, checkBoxFeaturesN, 1 do
				container.featuresList[i] = CreateFrame('CheckButton', 'fosterFramesFeaturesCheckButton'..i, container, 'UICheckButtonTemplate')
				container.featuresList[i]:SetHeight(24) 	container.featuresList[i]:SetWidth(24)
				container.featuresList[i]:SetPoint('TOPLEFT', i == 1 and container.features or container.featuresList[i-1], 'BOTTOMLEFT', 0, i == 1 and -10 or -10)
				_G[container.featuresList[i]:GetName()..'Text']:SetText(checkBoxFeatures[i]['label'])
				_G[container.featuresList[i]:GetName()..'Text']:SetPoint('LEFT', container.featuresList[i], 'RIGHT', 6, 0)
				container.featuresList[i].id = checkBoxFeatures[i]['id']
				container.featuresList[i]:SetScript('OnClick', function()
					FOSTERFRAMESPLAYERDATA[this.id]	= this:GetChecked()
					FOSTERFRAMESsettings()
				end)
			end
			
			container.bgLabel = container:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
			container.bgLabel:SetPoint('TOPLEFT', container.featuresList[checkBoxFeaturesN], 'BOTTOMLEFT', 0, -20)
			container.bgLabel:SetText'Battlegrounds'
			
			container.bgList = {}
			for i = 1, checkBoxFeaturesBGN, 1 do
				container.bgList[i] = CreateFrame('CheckButton', 'fosterFramesFeaturesBGCheckButton'..i, container, 'UICheckButtonTemplate')
				container.bgList[i]:SetHeight(24) 	container.bgList[i]:SetWidth(24)
				container.bgList[i]:SetPoint('TOPLEFT', i == 1 and container.bgLabel or container.bgList[i-1], 'BOTTOMLEFT', 0, i == 1 and -10 or -10)
				_G[container.bgList[i]:GetName()..'Text']:SetText(checkBoxFeaturesBG[i]['label'])
				_G[container.bgList[i]:GetName()..'Text']:SetPoint('LEFT', container.bgList[i], 'RIGHT', 6, 0)
				container.bgList[i].id = checkBoxFeaturesBG[i]['id']
				container.bgList[i]:SetScript('OnClick', function()
					FOSTERFRAMESPLAYERDATA[this.id]	= this:GetChecked()
					FOSTERFRAMESsettings()
				end)
			end
		end

		for i = 1, table.getn(container.featuresList) do
			_G[container.featuresList[i]:GetName()..'Text']:SetTextColor(color['r'], color['g'], color['b'], .9)
			container.featuresList[i]:SetChecked(FOSTERFRAMESPLAYERDATA[container.featuresList[i].id])
		end
		
		for i = 1, table.getn(container.bgList) do
			_G[container.bgList[i]:GetName()..'Text']:SetTextColor(color['r'], color['g'], color['b'], .9)
			container.bgList[i]:SetChecked(FOSTERFRAMESPLAYERDATA[container.bgList[i].id])
		end
	end
	-------------------------------------------------------------------------------