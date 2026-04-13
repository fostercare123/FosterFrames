	-------------------------------------------------------------------------------
	local settings = _G['fosterFramesSettings']
	
	local container = CreateFrame('Frame', 'fosterFramesSettingsfeaturesContainer', settings)
	container:SetWidth(settings:GetWidth()) container:SetHeight(settings:GetHeight())
	container:SetPoint('CENTER', settings)
	container:EnableMouse(true)
	container:EnableMouseWheel(true)
	container:Hide()
	-------------------------------------------------------------------------------
	local checkBoxFeaturesN, checkBoxFeatures  = 4, {
														[1] = {['id'] = 'mouseOver', 			['label'] = 'Mouseover Cast On Frames'},	
														[2] = {['id'] = 'targetFrameCastbar', 	['label'] = 'Movable Target Cast Bar'},														
														[3] = {['id'] = 'integratedTargetFrameCastbar', 	['label'] = 'Integrated Target Cast Bar'},
														[4] = {['id'] = 'targetDebuffTimers', 	['label'] = 'Debuff Timers On Target'},
														
													}
	local checkBoxFeaturesBGN, checkBoxFeaturesBG  = 1, {	[1] = {['id'] = 'efcBGannouncement', 	['label'] = 'Low Health EFC Announcement'},
															
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
	container.bgLabel = container:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
	container.bgLabel:SetPoint('LEFT', container.featuresList[checkBoxFeaturesN], 'LEFT', 0, -30)
	container.bgLabel:SetText'Battlegrounds'
	
	container.bgList = {}
	for i = 1, checkBoxFeaturesBGN, 1 do
		container.bgList[i] = CreateFrame('CheckButton', 'fosterFramesFeaturesBGCheckButton'..i, container, 'UICheckButtonTemplate')
		container.bgList[i]:SetHeight(20) 	container.bgList[i]:SetWidth(20)
		container.bgList[i]:SetPoint('LEFT', i == 1 and container.bgLabel or container.bgList[i-1], 'LEFT', 0, i == 1 and -40 or -30)
		_G[container.bgList[i]:GetName()..'Text']:SetText(checkBoxFeaturesBG[i]['label'])
		_G[container.bgList[i]:GetName()..'Text']:SetPoint('LEFT', container.bgList[i], 'RIGHT', 4, 0)
		container.bgList[i].id = checkBoxFeaturesBG[i]['id']
		container.bgList[i]:SetScript('OnClick', function()
			FOSTERFRAMESPLAYERDATA[this.id]	= this:GetChecked()
			FOSTERFRAMESsettings()
		end)
	end
	
	-------------------------------------------------------------------------------
	FEATURESSETTINGSInit = function(color)
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