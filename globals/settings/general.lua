	-------------------------------------------------------------------------------
	local settings = _G['fosterFramesSettings']
	
	local container = CreateFrame('Frame', 'fosterFramesSettingsgeneralContainer', settings)
	container:SetWidth(settings:GetWidth()) container:SetHeight(settings:GetHeight())
	container:SetPoint('CENTER', settings)
	container:EnableMouse(true)
	container:EnableMouseWheel(true)
	container:Hide()
	-------------------------------------------------------------------------------
		local checkBoxGeneralN, checkBoxGeneral  = 3, { 	[1] = {['id'] = 'enableFrames', 		['label'] = 'Enable FosterFrames'},
													[2] = {['id'] = 'displayOnlyNearby', 	['label'] = 'Display Nearby Units Only'},
													[3] = {['id'] = 'frameMovable', 		['label'] = 'Unlock Frames (Draggable)'},
													},
													}
	-------------------------------------------------------------------------------
	-- general checkbox
	container.generalList = {}
	for i = 1, checkBoxGeneralN, 1 do
		container.generalList[i] = CreateFrame('CheckButton', 'fosterFramesGeneralCheckButton'..i, container, 'UICheckButtonTemplate')
		container.generalList[i]:SetHeight(20) 	container.generalList[i]:SetWidth(20)
		if i == 1 then
			container.generalList[i]:SetPoint('LEFT', container, 'TOPLEFT', 45, -30)
		else
			container.generalList[i]:SetPoint('LEFT', container.generalList[i-1], 'LEFT', 0, -30)
		end
		_G[container.generalList[i]:GetName()..'Text']:SetText(checkBoxGeneral[i]['label'])
		_G[container.generalList[i]:GetName()..'Text']:SetPoint('LEFT', container.generalList[i], 'RIGHT', 4, 0)
		container.generalList[i].id = checkBoxGeneral[i]['id']
		container.generalList[i]:SetScript('OnClick', function()
			FOSTERFRAMESPLAYERDATA[this.id] = this:GetChecked()
			FOSTERFRAMESsettings()
		end)
	end
	
	-- scale
	container.scale = container:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
	container.scale:SetPoint('LEFT', container.generalList[checkBoxGeneralN], 'LEFT', 0, -30)
	container.scale:SetText'Scale'

	container.scaleSlider = CreateFrame('Slider', 'fosterFramesScaleSlider', container, 'OptionsSliderTemplate')
	container.scaleSlider:SetWidth(215) 	container.scaleSlider:SetHeight(14)
	container.scaleSlider:SetPoint('LEFT', container.scale, 'LEFT', 0, -30)
	container.scaleSlider:SetMinMaxValues(0.8, 1.5)
	container.scaleSlider:SetValueStep(.05)
	_G[container.scaleSlider:GetName()..'Low']:SetText'0.8'
	_G[container.scaleSlider:GetName()..'High']:SetText'1.5'


	container.scaleSlider:SetScript('OnValueChanged', function() 
		FOSTERFRAMESPLAYERDATA['scale'] = this:GetValue() 
		_G['fosterFrameDisplay']:SetScale(FOSTERFRAMESPLAYERDATA['scale'])
	end)

	-- layout

	container.layout = container:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
	container.layout:SetPoint('LEFT', container.scaleSlider, 'LEFT', 0, -50)
	container.layout:SetText'Layout'

	container.layoutSlider = CreateFrame('Slider', 'fosterFramesLayoutSlider', container, 'OptionsSliderTemplate')
	container.layoutSlider:SetWidth(215) 	container.layoutSlider:SetHeight(14)
	container.layoutSlider:SetPoint('LEFT', container.layout, 'LEFT', 0, -30)
	container.layoutSlider:SetMinMaxValues(0, 4)
	container.layoutSlider:SetValueStep(1)
	_G[container.layoutSlider:GetName()..'Low']:SetText'Horizontal'
	_G[container.layoutSlider:GetName()..'High']:SetText'Vertical'


	container.layoutSlider:SetScript('OnValueChanged', function() 
		local v = this:GetValue()
		local a = v == 0 and 'horizontal' or v == 1 and 'hblock' or v == 2 and 'block' or v == 3 and 'vblock' or 'vertical'
		local g = v == 0 and 1 or (v == 1 or v == 2) and 5 or v == 3 and 2 or 15
		FOSTERFRAMESPLAYERDATA['layout'] 	= a
		FOSTERFRAMESPLAYERDATA['groupsize']  = g
		FOSTERFRAMESsettings()
	end)
	
	-------------------------------------------------------------------------------
	MAINSETTINGSInit = function(color)
		_G[container.scaleSlider:GetName()..'Low']:SetTextColor(color['r'], color['g'], color['b'], .9)
		_G[container.scaleSlider:GetName()..'High']:SetTextColor(color['r'], color['g'], color['b'], .9)
		_G[container.layoutSlider:GetName()..'Low']:SetTextColor(color['r'], color['g'], color['b'], .9)
		_G[container.layoutSlider:GetName()..'High']:SetTextColor(color['r'], color['g'], color['b'], .9)
		
		for i = 1, checkBoxGeneralN, 1 do
			_G[container.generalList[i]:GetName()..'Text']:SetTextColor(color['r'], color['g'], color['b'], .9)
			container.generalList[i]:SetChecked(FOSTERFRAMESPLAYERDATA[checkBoxGeneral[i]['id']])
		end
		
		container.scaleSlider:SetValue(FOSTERFRAMESPLAYERDATA['scale'])
		container.layoutSlider:SetValue(FOSTERFRAMESPLAYERDATA['layout'] == 'horizontal' and 0 or FOSTERFRAMESPLAYERDATA['layout'] == 'hblock' and 1 or FOSTERFRAMESPLAYERDATA['layout'] == 'block' and 2 or FOSTERFRAMESPLAYERDATA['layout'] == 'vblock' and 3 or 4)
		
		--container.newversion:SetTextColor(color['r'], color['g'], color['b'], .9)
	end
	-------------------------------------------------------------------------------