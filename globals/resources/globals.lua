
    HEX_CLASS_COLORS = {
        ['DRUID']   = 'ff7d0a',
        ['HUNTER']  = 'abd473',
        ['MAGE']    = '69ccf0',
        ['PALADIN'] = 'f58cba',
        ['PRIEST']  = 'ffffff',
        ['ROGUE']   = 'fff569',
        ['SHAMAN']  = 'f58cba',--'0070de',
        ['WARLOCK'] = '9482c9',
        ['WARRIOR'] = 'c79c6e',
    }

	RAID_CLASS_COLORS = {
		['DRUID']   = { r = 1.00, g = 0.49, b = 0.04 },
		['HUNTER']  = { r = 0.67, g = 0.83, b = 0.45 },
		['MAGE']    = { r = 0.41, g = 0.80, b = 0.94 },
		['PALADIN'] = { r = 0.96, g = 0.55, b = 0.73 },
		['PRIEST']  = { r = 1.00, g = 1.00, b = 1.00 },
		['ROGUE']   = { r = 1.00, g = 0.96, b = 0.41 },
		['SHAMAN']  = { r = 0.96, g = 0.55, b = 0.73 },
		['WARLOCK'] = { r = 0.58, g = 0.51, b = 0.79 },
		['WARRIOR'] = { r = 0.78, g = 0.61, b = 0.43 },
	}
	
	RGB_SPELL_SCHOOL_COLORS = 
	{
		['physical'] 	= {.9, .9, 0},
		['arcane'] 		= {.9, .4, .9},
		['fire']		= {.9, .4, 0},
		['nature'] 		= {.3, .9, .2},
		['frost'] 		= {.4,.9, .9},
		['shadow'] 		= {.4, .4, .9},
		['holy'] 		= {.9, .4, .9}
	}

	RGB_FACTION_COLORS = 
	{
		['Alliance'] 	= {['r'] = 0, ['g'] = .68, ['b'] = .94}, 
		['Horde'] 		= {['r'] = 1, ['g'] = .1, ['b'] = .1}
	}
	
	RGB_POWER_COLORS =
	{
		['energy']		= {1, 1, 0},
		['focus']		= {1, .5, .25},
		['mana']		= {0, 0, 1},
		['rage']		= {1, 0, 0},
		
	}
	
	RGB_BORDER_DEBUFFS_COLOR =
	{
		--['none']		= {.8, 0, 0}
		['curse']		= {.6, 0, 1},
		['disease']		= {.6, .4, 0},
		['magic'] 		= {.2, .6, 1},
		['physical'] 	= {.8, 0, 0},
		['poison'] 		= {0, .6, 0},		
	}
	
	local iconFolders = 
	{
		['class'] 		= [[Interface\AddOns\fosterFrames\globals\resources\ClassIcons\ClassIcon_]],
	}

	GET_DEFAULT_ICON = function(op, value)
		local dir = iconFolders[op]
		if not value or not dir then return "" end
		return dir .. value
	end
	
	RAID_TARGET_TCOORDS = 
	{
		['star']		= {0, .25, 0, .25},
		['circle']		= {.25, .5, 0, .25},
		['diamond']		= {.5, .75, 0, .25},
		['triangle']	= {.75, 1, 0, .25},
		
		['moon']		= {0, .25, .25, .5},
		['square']		= {.25, .5, .25, .5},
		['cross']		= {.5, .75, .25, .5},
		['skull'] 		= {.75, 1, .25, .5},
	}		
    
	SPELLINFO_WSG_FLAGS = {
		['Alliance'] 	= {['icon'] = [[Interface\Icons\inv_bannervp_02]]},
		['Horde'] 		= {['icon'] = [[Interface\Icons\inv_bannerpvp_01]]},
	}

	--
