	-------------------------------------------------------------------------------
	local function castingChecks(spell)
		if not FOSTERFRAMESPLAYERDATA['mouseOver'] or MOUSEOVERUNINAME == nil			then	return false	end
		
		if SPELLINFO_SINGLE_TARGET_BUFF_SPELLS[spell]	then	return false	end
		
		-- target mouseover unit
		local p = FOSTERFRAMECOREgetPlayer(MOUSEOVERUNINAME)
		FOSTERFRAMES_Target(MOUSEOVERUNINAME, p and p.guid)
		return true
	end
	-------------------------------------------------------------------------------
	local function reTarget(b, currentTarget)
		if b then 
			if currentTarget == nil then	ClearTarget()	
			else
				local p = FOSTERFRAMECOREgetPlayer(currentTarget)
				FOSTERFRAMES_Target(currentTarget, p and p.guid)
			end
		end
	end
	-------------------------------------------------------------------------------
	local AHTooltip = CreateFrame("GameTooltip","AHTooltip",UIParent,"GameTooltipTemplate")
	AHTooltip:SetOwner(UIParent,"ANCHOR_NONE")

	UseActionAH = UseAction
	function UseAction( slot, checkFlags, checkSelf )
		AHTooltip:ClearLines()
		AHTooltip:SetAction(slot)
		local spellName = AHTooltipTextLeft1:GetText()
		
		local currentTarget = UnitExists'target' and UnitName'target' or nil
		local b = castingChecks(spellName)
		
		UseActionAH( slot, checkFlags, checkSelf )
		
		reTarget(b, currentTarget)	
	end
	-------------------------------------------------------------------------------
	CastSpellByNameAH = CastSpellByName;
	function CastSpellByName(spellName, onself)
		
		local currentTarget = UnitExists'target' and UnitName'target' or nil
		local b = castingChecks(spellName)
		
		CastSpellByNameAH(spellName, onself)
		
		reTarget(b, currentTarget)
	end
	-------------------------------------------------------------------------------