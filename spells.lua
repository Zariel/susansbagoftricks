local parent, ns = ...

local temp = {
	Undead = {
		"Will of the Forsaken",
		"Cannibalize",
	},
	NightElf = {
		"Shadowmeld",
	},
	Human = {
		"Every Man for Himself",
	},
	Rogue = {
		"Riposte",
		"Gouge",
		"Blade Flurry",
		"Adrenaline Rush",
		"Killing Spree",
		"Kick",
		"Vanish",
		"Sprint",
		"Stealth",
		"Evasion",
		"Blind",
		"Kindey Shot",
		"Cold Blood",
		"Shadow Step"
	},
	Hunter = {
		"Arcane Shot",
		"Multi Shot",
		"Concussive Shot",
		"Intimidation",
		"Flare",
		"Feign Death",
		"Disengage",
		"Bestial Wrath",
		"Viper Sting",
		"Deterrence",
		"Frost Trap",
		"Freezing Trap",
		"Snake Trap",
		"Kill Command",
		"Explosive Shot",
		"Aimed Shot",
		"Scare Beast",
		"Tranqulizing Shot",
		"Black Arrow",
		"Master's Call",
	},
	Warrior = {
		"Charge",
		"Intercept",
		"Overpower",
		"Bloodrage",
		"Beserker Rage",
		"Mortal Strike",
		"Revenge",
		"Shield Bash",
		"Shield Block",
	},
	Paladin = {
		"Judgment of Light",
		"Judgment of Wisdom",
		"Crusader Strike",
		"Holy Shock",
		"Lay on Hands",
		"Avenger's Shield",
		"Ardent Defender",
		"Hammer of Righteous",
		"Hammer of Justice",
		"Hand of Reckoning",
		"Guardian of the Anchient Kings",
		"Avenging Wrath"
	},
	Shaman = {
		"Thunderstorm",
		"Chain Lightning",
		"Frost Shock",
		"Earth Shock",
		"Wind Shear",
		"Elemental Mastery",
	},
}

local class, race = UnitClass("player"), UnitRace("player")
for type, v in pairs(temp) do
	if(type == class or type == race) then
		for i, spell in pairs(v) do
			ns.spells[spell] = true
		end
	end
end
