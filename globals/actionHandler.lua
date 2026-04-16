
_G = getfenv(0)

	-- Modernized Action Handler for SuperWOW / TurtleWoW 1.12.1
	-- Handles Mouseover casting integration for standard action bars.

	local SPELLINFO_SINGLE_TARGET_BUFF_SPELLS = {
		['Mark of the Wild'] = true,
		['Thorns'] = true,
		['Power Word: Fortitude'] = true,
		['Divine Spirit'] = true,
		['Shadow Protection'] = true,
		['Power Word: Shield'] = true,
		['Renew'] = true,
		['Arcane Intellect'] = true,
		['Arcane Brilliance'] = true,
		['Dampen Magic'] = true,
		['Amplify Magic'] = true,
		['Blessing of Might'] = true,
		['Blessing of Wisdom'] = true,
		['Blessing of Kings'] = true,
		['Blessing of Sanctuary'] = true,
		['Blessing of Light'] = true,
		['Blessing of Salvation'] = true,
		['Blessing of Protection'] = true,
		['Blessing of Freedom'] = true,
		['Lay on Hands'] = true,
		['Holy Light'] = true,
		['Flash of Light'] = true,
		['Cleanse'] = true,
		['Purify'] = true,
	}

	local function castingChecks(spell)
		if not FOSTERFRAMESPLAYERDATA['mouseOver'] or MOUSEOVERUNINAME == nil then return false end
		if not spell then return false end
		if SPELLINFO_SINGLE_TARGET_BUFF_SPELLS[spell] then return false end
		
		-- target mouseover unit
		TargetByName(MOUSEOVERUNINAME, true)
		return true
	end

	local function reTarget(b, currentTarget)
		if b then 
			if currentTarget == nil then ClearTarget()	
			else
				TargetByName(currentTarget, true)
			end
		end
	end

	local AHTooltip = CreateFrame("GameTooltip", "AHTooltip", UIParent, "GameTooltipTemplate")
	AHTooltip:SetOwner(UIParent, "ANCHOR_NONE")

	local UseAction_Original = UseAction
	UseAction = function(slot, checkFlags, checkSelf)
		AHTooltip:ClearLines()
		AHTooltip:SetAction(slot)
		local textLeft = getglobal("AHTooltipTextLeft1")
		local spellName = textLeft and textLeft:GetText()
		
		local currentTarget = UnitExists'target' and UnitName'target' or nil
		local b = castingChecks(spellName)
		
		UseAction_Original(slot, checkFlags, checkSelf)
		
		reTarget(b, currentTarget)	
	end

	local CastSpellByName_Original = CastSpellByName
	CastSpellByName = function(spellName, onself)
		local currentTarget = UnitExists'target' and UnitName'target' or nil
		local b = castingChecks(spellName)
		
		CastSpellByName_Original(spellName, onself)
		
		reTarget(b, currentTarget)
	end
