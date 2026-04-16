	_G = getfenv(0)
	-------------------------------------------------------------------------------
	GENERALSSETTINGSInit = function(color)
		local content = _G['fosterFramesSettingsContent']
		local container = _G['fosterFramesSettingsgeneralContainer']
		
		if not container then
			container = CreateFrame('Frame', 'fosterFramesSettingsgeneralContainer', content)
			container:SetAllPoints(content)
			container:EnableMouse(true)
			container:Hide()
			
			local checkBoxGeneralN, checkBoxGeneral  = 1, { 	[1] = {['id'] = 'enableFrames', 		['label'] = 'Enable Addon (Show Frames)'},
															}
			
			-- general checkbox
			container.generalList = {}
			for i = 1, checkBoxGeneralN, 1 do
				container.generalList[i] = CreateFrame('CheckButton', 'fosterFramesGeneralCheckButton'..i, container, 'UICheckButtonTemplate')
				container.generalList[i]:SetHeight(24) 	container.generalList[i]:SetWidth(24)
				if i == 1 then
					container.generalList[i]:SetPoint('TOPLEFT', container, 'TOPLEFT', 20, -20)
				else
					container.generalList[i]:SetPoint('TOPLEFT', container.generalList[i-1], 'BOTTOMLEFT', 0, -10)
				end
				_G[container.generalList[i]:GetName()..'Text']:SetText(checkBoxGeneral[i]['label'])
				_G[container.generalList[i]:GetName()..'Text']:SetPoint('LEFT', container.generalList[i], 'RIGHT', 6, 0)
				container.generalList[i].id = checkBoxGeneral[i]['id']
				container.generalList[i]:SetScript('OnClick', function()
					FOSTERFRAMESPLAYERDATA[this.id] = this:GetChecked()
					if FOSTERFRAMESsettings then FOSTERFRAMESsettings() end
				end)
			end
			
			-- scale
			container.scale = container:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
			container.scale:SetPoint('TOPLEFT', container.generalList[checkBoxGeneralN], 'BOTTOMLEFT', 0, -20)
			container.scale:SetText'Global Scale'

			container.scaleSlider = CreateFrame('Slider', 'fosterFramesScaleSlider', container, 'OptionsSliderTemplate')
			container.scaleSlider:SetWidth(215) 	container.scaleSlider:SetHeight(16)
			container.scaleSlider:SetPoint('TOPLEFT', container.scale, 'BOTTOMLEFT', 10, -10)
			container.scaleSlider:SetMinMaxValues(0.8, 1.5)
			container.scaleSlider:SetValueStep(.05)
			_G[container.scaleSlider:GetName()..'Low']:SetText'0.8'
			_G[container.scaleSlider:GetName()..'High']:SetText'1.5'

			container.scaleSlider:SetScript('OnValueChanged', function() 
				FOSTERFRAMESPLAYERDATA['scale'] = this:GetValue() 
				if fosterFrameDisplay then
					fosterFrameDisplay:SetScale(FOSTERFRAMESPLAYERDATA['scale'])
				end
			end)
		end

		_G[container.scaleSlider:GetName()..'Low']:SetTextColor(color['r'], color['g'], color['b'], .9)
		_G[container.scaleSlider:GetName()..'High']:SetTextColor(color['r'], color['g'], color['b'], .9)
		
		for i = 1, table.getn(container.generalList) do
			_G[container.generalList[i]:GetName()..'Text']:SetTextColor(color['r'], color['g'], color['b'], .9)
			container.generalList[i]:SetChecked(FOSTERFRAMESPLAYERDATA[container.generalList[i].id])
		end
		
		container.scaleSlider:SetValue(FOSTERFRAMESPLAYERDATA['scale'])
	end

    APPEARANCESETTINGSInit = function(color)
		local content = _G['fosterFramesSettingsContent']
		local container = _G['fosterFramesSettingsappearanceContainer']
		
		if not container then
			container = CreateFrame('Frame', 'fosterFramesSettingsappearanceContainer', content)
			container:SetAllPoints(content)
			container:EnableMouse(true)
			container:Hide()

            local checkBoxAppearanceN, checkBoxAppearance  = 2, { 	[1] = {['id'] = 'displayNames', 		['label'] = 'Show Player Names on Frames'},
                                                                    [2] = {['id'] = 'displayManabar', 		['label'] = 'Show Mana/Rage/Energy Bar'},
            }			
			-- appearance checkboxes
			container.appearanceList = {}
			for i = 1, checkBoxAppearanceN, 1 do
				container.appearanceList[i] = CreateFrame('CheckButton', 'fosterFramesAppearanceCheckButton'..i, container, 'UICheckButtonTemplate')
				container.appearanceList[i]:SetHeight(24) 	container.appearanceList[i]:SetWidth(24)
				if i == 1 then
					container.appearanceList[i]:SetPoint('TOPLEFT', container, 'TOPLEFT', 20, -20)
				else
					container.appearanceList[i]:SetPoint('TOPLEFT', container.appearanceList[i-1], 'BOTTOMLEFT', 0, -10)
				end
				_G[container.appearanceList[i]:GetName()..'Text']:SetText(checkBoxAppearance[i]['label'])
				_G[container.appearanceList[i]:GetName()..'Text']:SetPoint('LEFT', container.appearanceList[i], 'RIGHT', 6, 0)
				container.appearanceList[i].id = checkBoxAppearance[i]['id']
				container.appearanceList[i]:SetScript('OnClick', function()
					FOSTERFRAMESPLAYERDATA[this.id] = this:GetChecked()
					if FOSTERFRAMESsettings then FOSTERFRAMESsettings() end
				end)
			end

			-- layout
			container.layout = container:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
			container.layout:SetPoint('TOPLEFT', container.appearanceList[checkBoxAppearanceN], 'BOTTOMLEFT', 0, -20)
			container.layout:SetText'Frame Layout'

			container.layoutSlider = CreateFrame('Slider', 'fosterFramesLayoutSlider', container, 'OptionsSliderTemplate')
			container.layoutSlider:SetWidth(215) 	container.layoutSlider:SetHeight(16)
			container.layoutSlider:SetPoint('TOPLEFT', container.layout, 'BOTTOMLEFT', 10, -10)
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
				if FOSTERFRAMESsettings then FOSTERFRAMESsettings() end
			end)
		end

		_G[container.layoutSlider:GetName()..'Low']:SetTextColor(color['r'], color['g'], color['b'], .9)
		_G[container.layoutSlider:GetName()..'High']:SetTextColor(color['r'], color['g'], color['b'], .9)
		
		for i = 1, table.getn(container.appearanceList) do
			_G[container.appearanceList[i]:GetName()..'Text']:SetTextColor(color['r'], color['g'], color['b'], .9)
			container.appearanceList[i]:SetChecked(FOSTERFRAMESPLAYERDATA[container.appearanceList[i].id])
		end
		
		container.layoutSlider:SetValue(FOSTERFRAMESPLAYERDATA['layout'] == 'horizontal' and 0 or FOSTERFRAMESPLAYERDATA['layout'] == 'hblock' and 1 or FOSTERFRAMESPLAYERDATA['layout'] == 'block' and 2 or FOSTERFRAMESPLAYERDATA['layout'] == 'vblock' and 3 or 4)
	end
	-------------------------------------------------------------------------------