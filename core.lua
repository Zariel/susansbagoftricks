--[[Copyright (c) 2009 Chris Bannister,
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:
1. Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.
3. The name of the author may not be used to endorse or promote products
   derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.]]

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

local spells = {}
do
	local class, race = UnitClass("player"), UnitRace("player")
	for type, v in pairs(temp) do
		if(type == class or type == race) then
			for i, spell in pairs(v) do
				spells[spell] = true
			end
		end
	end

	if(not next(spells)) then return end
end


local addon = CreateFrame("Frame", nil, UIParent)
local t = addon:CreateTexture(nil, "OVERLAY")

local GetTime = GetTime
local GetSpellCooldown = GetSpellCooldown
local GetSpellInfo = GetSpellInfo
local pi = math.pi
local cos = math.cos
local select = select

local playerName = UnitName("player")

local size = 175
local alpha = 0.85

local steps = 50
local modifier = 1 / steps

-- Taken from oPanel ~~
local cos = math.cos
local cosineInterpolation = function(y1, y2, mu)
	return y1 + (y2 - y1) * (1 - cos(pi * mu)) / 2
end

t:SetHeight(size)
t:SetWidth(size)
t:SetPoint("CENTER", UIParent, "CENTER")
t:SetAlpha(0)
t:SetTexCoord(0.07, 0.93, 0.07, 0.93)
t:Hide()

addon.icon = t

addon.queue = {}
addon.running = false
addon.watched = {}
addon.timer = 0

addon:SetScript("OnEvent", function(self, event, ...)
	return self[event](self, ...)
end)

addon:RegisterEvent("SPELL_UPDATE_COOLDOWN")
addon:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

local cast = {}

local texCache = setmetatable({}, {
	__mode = "k",
	__index = function(self, spell)
		local text = select(3, GetSpellInfo(spell))
		rawset(self, spell, text)
		return text
	end,
})

function addon:COMBAT_LOG_EVENT_UNFILTERED(timeStamp, event, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellId, spellName)
	if(sourceName == playerName and spellName and spells[spellName]) then
		cast[spellName] = true
	end
end

function addon:SPELL_UPDATE_COOLDOWN()
	local start, duration, enabled
	for spell in next, cast do
		start, duration, enabled = GetSpellCooldown(spell)

		if(enabled == 1 and duration > 1.5) then
			self.watched[spell] = start + duration
		end
	end
end

local time
local cosine = 0
local step = 0

addon:SetScript("OnUpdate", function(self, elapsed)
	-- Update watched timers
	-- this can cause problems if a spell comes off cooldown before we expect
	-- it, ie explosion shot from Lock N Load
	time = GetTime()
	for spell, finish in next, self.watched do
		-- Pre empt faster plx
		if(time >= (finish - 0.5)) then
			self.queue[#self.queue + 1] = { spell, time }

			self.watched[spell] = nil
			cast[spell] = nil
		end
	end

	-- Are we running allready?
	if(self.running) then
		if(step > steps) then
			self.icon:Hide()
			self.icon:SetAlpha(0)
			self.icon:SetHeight(size)
			self.icon:SetHeight(size)
			self.running = false
			step = 0
		else
			cosin = cosineInterpolation(0, 1, modifier * step)
			self.icon:SetHeight(cosin * size)
			self.icon:SetWidth(cosin * size)
			self.icon:SetAlpha(cosin * alpha)
			step = step + 1
			return
		end
	end

	if(#self.queue == 0) then return end
	table.sort(self.queue, function(a, b) return a[2] < b[2] end)
	local spell = table.remove(self.queue, 1)[1]
	self.icon:SetTexture(texCache[spell])
	self.running = true
	self.icon:Show()
end)
