	-------------------------------------------------------------------------------
	local settings = _G['fosterFramesSettings']
	
	local container = CreateFrame('Frame', 'fosterFramesSettingsfeaturesContainer', settings)
	container:SetWidth(settings:GetWidth()) container:SetHeight(settings:GetHeight())
	container:SetPoint('CENTER', settings)
	container:EnableMouse(true)
	container:EnableMouseWheel(true)
	container:Hide()
	-------------------------------------------------------------------------------
		local checkBoxFeaturesN, checkBoxFeatures  = 3, { 	[1] = {['id'] = 'targetFrameCastbar', 	['label'] = 'Moveable Target Cast Bar'},
														[2] = {['id'] = 'integratedTargetFrameCastbar', 	['label'] = 'Integrated Target Cast Bar'},
														[3] = {['id'] = 'useUnitXP',            ['label'] = 'Use Absolute Health/Mana (UnitXP)'},
													},	
														[2] = {['id'] = 'targetFrameCastbar', 	['label'] = 'Movable Target Cast Bar'},														
														[3] = {['id'] = 'integratedTargetFrameCastbar', 	['label'] = 'Integrated Target Cast Bar'},
														[4] = {['id'] = 'targetDebuffTimers', 	['label'] = 'Debuff Timers On Target'},
														
													}
	local checkBoxFeaturesBGN, checkBoxFeaturesBG = 0, {},
															
														}
	-------------------------------------------------------------------------------
	-- features
	container.features = container:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
	container.features:SetPoint('LEFT', container, 'TOPLEFT', 45, -30)
	container.features:SetText'Features'

	container.featuresList = {}
	for i = 1, checkBoxFeaturesN, 1 do
		container.featuresList[i] = CreateFrame('CheckButton', 'fosterFramesFeaturesCheckButton'..i, container, 'UICheckButtonTemplate')
		container.featuresList[i]:SetHeight(20) 	container.featuresList[i]:SetWidth(20)
		container.featuresList[i]:SetPoint('LEFT', i == 1 and container.features or container.featuresList[i-1], 'LEFT', 0, i == 1 and -40 or -30)
		_G[container.featuresList[i]:GetName()..'Text']:SetText(checkBoxFeatures[i]['label'])
		_G[container.featuresList[i]:GetName()..'Text']:SetPoint('LEFT', container.featuresList[i], 'RIGHT', 4, 0)
		container.featuresList[i].id = checkBoxFeatures[i]['id']
		container.featuresList[i]:SetScript('OnClick', function()
			FOSTERFRAMESPLAYERDATA[this.id]	= this:GetChecked()
			FOSTERFRAMESsettings()
		end)
	end
	-------------------------------------------------------------------------------
	-- BG features removed)
	end
	
	-------------------------------------------------------------------------------
	TACTICALSETTINGSInit = function(color)
		for i = 1, checkBoxFeaturesN do
			_G[container.featuresList[i]:GetName()..'Text']:SetTextColor(color['r'], color['g'], color['b'], .9)
			container.featuresList[i]:SetChecked(FOSTERFRAMESPLAYERDATA[checkBoxFeatures[i]['id']])
		end
		
		for i = 1, checkBoxFeaturesBGN do
			_G[container.bgList[i]:GetName()..'Text']:SetTextColor(color['r'], color['g'], color['b'], .9)
			container.bgList[i]:SetChecked(FOSTERFRAMESPLAYERDATA[checkBoxFeaturesBG[i]['id']])
		end
		

	end
	-------------------------------------------------------------------------------