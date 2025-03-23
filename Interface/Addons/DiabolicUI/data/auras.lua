local _, Engine = ...

-- This database will contain lists of categorized Auras
-- for CC, dispellers and so on. 

-- Note: 
-- In some cases the spellID of the spell casting the effect is listed, 
-- while what we would want is the spellID of the applied aura/effect on the target. 
-- Will need to start a public initiative on discord to help people test this out, probably.

-- Using this page for dimishing returns in Legion: http://dr-wow.com/


local auras = {

	-- Diminishing Returns
	dr = {
		-- Seconds after last application before vulnerable again.
		reset = 18,
		resetKnockback = 10,

		-- Part of the normal duration on the [i]th application.
		duration = { 1, .5, .25, 0 },
		durationTaunt = { 1, .65, .42, .27, 0 },
		durationKnockback = { 1, 0 }
	},

	-- Crowd Control
	cc = {
		disorient = {
			[207167] = true,	-- Death Knight - Blinding Sleet
			[207685] = true,	-- Demon Hunter - Sigil of Misery
			[ 33786] = true,	-- Druid - Cyclone
			[186387] = true,	-- Hunter - Bursting Shot
			[213691] = true,	-- Hunter - Scatter Shot
			[ 31661] = true,	-- Mage - Dragon's Breath
			[198909] = true,	-- Monk - Song of Chi-Ji
			[202274] = true,	-- Monk - Incendiary Brew
			[105421] = true,	-- Paladin - Blinding Light
			[   605] = true,	-- Priest - Dominate Mind
			[  8122] = true,	-- Priest - Psychic Scream
			[ 87204] = true,	-- Priest - Sin and Punishment (131556?) (Vampiric Touch Dispel)
			[  2094] = true,	-- Rogue - Blind
			[  5246] = true,	-- Warrior - Intimidating Shout
			[  5782] = true,	-- Warlock - Fear
			[118699] = true,	-- Warlock - Fear (new)
			[  5484] = true,	-- Warlock - Howl of Terror
			[115268] = true,	-- Warlock - Mesmerize (Shivarra)
			[  6358] = true,	-- Warlock - Seduction (Succubus)
		},
		incapacitate = {
			[    99] = true,	-- Druid - Incapacitating Roar
			[236025] = true, 	-- Druid - Enraged Maim
			[209790] = true,	-- Hunter - Freezing Arrow
			[  3355] = true,	-- Hunter - Freezing Trap
			[ 19386] = true,	-- Hunter - Wyvern Sting
			[   118] = true,	-- Mage - Polymorph
			[ 28271] = true,	-- Mage - Polymorph (Turtle)
			[ 28272] = true,	-- Mage - Polymorph (Pig)
			[ 61305] = true,	-- Mage - Polymorph (Black Cat)
			[ 61721] = true,	-- Mage - Polymorph (Rabbit)
			[ 61780] = true,	-- Mage - Polymorph (Turkey)
			[126819] = true,	-- Mage - Polymorph (Porcupine)
			[161353] = true,	-- Mage - Polymorph (Polar Cub)
			[161354] = true,	-- Mage - Polymorph (Monkey)
			[161355] = true,	-- Mage - Polymorph (Penguin)
			[161372] = true,	-- Mage - Polymorph (Peacock)
			[ 82691] = true,	-- Mage - Ring of Frost
			[115078] = true,	-- Monk - Paralysis
			[ 20066] = true,	-- Paladin - Repentance
			[200196] = true,	-- Priest - Holy Word: Chastise
			[  9484] = true,	-- Priest - Shackle Undead
			[  1776] = true,	-- Rogue - Gouge
			[  6770] = true,	-- Rogue - Sap
			[ 51514] = true,	-- Shaman - Hex
			[210873] = true,	-- Shaman - Hex (Compy)
			[211004] = true,	-- Shaman - Hex (Spider)
			[211010] = true,	-- Shaman - Hex (Snake)
			[211015] = true,	-- Shaman - Hex (Cockroach)
			[   710] = true,	-- Warlock - Banish
			[  6789] = true, 	-- Warlock - Mortal Coil
			
			[107079] = true 	-- Pandarian - Quaking Palm
		},
		knockback = {

		},
		root = {

		},
		silence = {

		},
		stun = {
			[108194] = true,	-- Death Knight - Asphyxiate  
			[221562] = true,	-- Death Knight - Asphyxiate?
			[ 91800] = true,	-- Death Knight - Gnaw
			[179057] = true,	-- Demon Hunter - Chaos Nova
			[211881] = true,	-- Demon Hunter - Fel Eruption
			[205630] = true,	-- Demon Hunter - Illidan's Grasp
			[168881] = true,	-- Druid - Maim (5 combo points)
			[168880] = true,	-- Druid - Maim
			[168879] = true,	-- Druid - Maim
			[168878] = true,	-- Druid - Maim
			[168877] = true,	-- Druid - Maim
			[  5211] = true,	-- Druid - Mighty Bash
			[163505] = true,	-- Druid - Rake
			[117526] = true,	-- Hunter - Binding Shot
			[ 24394] = true,	-- Hunter - Intimidation (Pet)
			[117418] = true,	-- Monk - Fists of Fury
			[119381] = true,	-- Monk - Leg Sweep
			[   853] = true,	-- Paladin - Hammer of Justice
			[200200] = true,	-- Priest - Holy Word: Chastise
			[226943] = true,	-- Priest - Mind Bomb
			[199804] = true,	-- Rogue - Between the Eyes
			[  1833] = true,	-- Rogue - Cheap Shot 
			[   408] = true,	-- Rogue - Kidney Shot
			[204399] = true,	-- Shaman - Earthfury (no DR?)
			[118905] = true,	-- Shaman - Static Charge (Capacitor Totem)
			[ 89766] = true,	-- Warlock - Axe Toss (Felguard)
			[ 22703] = true,	-- Warlock - Infernal Awakening (Infernal)
			[ 30283] = true,	-- Warlock - Shadowfury
			[132168] = true,	-- Warrior - Shockwave
			[132169] = true,	-- Warrior - Storm Bolt
			
			[ 20549] = true		-- Tauren - War Stomp
		},
	},
	harm = {},
	help = {},
	zone = {
		[64373] = true -- Armistice (Argent Tournament Zone Buff)
	},

	-- Loss of Control
	-- This will be auto-generated below, just defining them here for semantics.
	loc = {} 
	
}

do
	-- Loss of Control Display Priorities (lower value = higher priority)
	-- *Mostly intended for nameplates, commented out things we want filtered out
	local locPrio = {
		disorient = 3,
		incapacitate = 5,
		--knockback = 2,
		--root = 1,
		--silence = 4,
		stun = 6
	}

	-- CC Display Priorities (lower value = higher priority)
	-- *Mostly intended for unitframes 
	local ccPrio = {
		disorient = 3,
		incapacitate = 5,
		knockback = 2,
		root = 1,
		silence = 4,
		stun = 6
	}

	-- Merge CC categories to allow aura.cc[spellID]
	local categories = {} -- Avoid modifying the table while iterating
	for categoryName in pairs(auras.cc) do
		categories[#categories+1] = categoryName
	end
	for i=1,#categories do
		local categoryName = categories[i]
		for spellID in pairs(auras.cc[categoryName]) do

			-- Using priorities here instead of true/nil, 
			-- to allow modules to filter auras based on category.
			auras.cc[spellID] = ccPrio[categoryName] 
			auras.loc[spellID] = locPrio[categoryName]
		end
	end
end

Engine:NewStaticConfig("Data: Auras", auras)
