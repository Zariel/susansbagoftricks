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

local GetTime = GetTime
local GetSpellCooldown = GetSpellCooldown
local GetSpellName = GetSpellName
local pi = math.pi/2
local math_sin = math.sin

local playerName = UnitName("player")

local addon = CreateFrame("Frame", nil, UIParent)
local t = addon:CreateTexture(nil, "OVERLAY")

local size = 175
local alpha = 0.85

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

addon.spells = {}

local spells = {
	undead = {
		-- Undead
		"Will of the Forsaken",
		"Cannibalize",
	},
	NightElf = {
		"Shadowmeld",
	},
	Rogue = {
		-- Rogue
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
		"Tranqulizing Shot"
	},
	warrior = {
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
}

if spells[UnitClass("player")] then
	addon.spells = {}
	for k, spell in pairs(spells[UnitClass("player")]) do
		addon.spells[spell] = true
	end
end

if spells[UnitRace("player")] then
	addon.spells = addon.spells or {}
	for k, spell in pairs(select(2, spells[UnitRace("player")])) do
		addon.spells[spell] = true
	end
end

if not addon.spells then return end

spells = nil

addon:SetScript("OnEvent", function(self, event, ...)
	return self[event](self, ...)
end)

addon:RegisterEvent("SPELL_UPDATE_COOLDOWN")
addon:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

local cast = {}

function addon:COMBAT_LOG_EVENT_UNFILTERED(timeStamp, event, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellId, spellName)
	if sourceName == playerName and spellName and self.spells[spellName] then
		cast[spellName] = true
	end
end

function addon:SPELL_UPDATE_COOLDOWN()
	local start, duration, enabled
	for spell in pairs(self.spells) do
		start, duration, enabled = GetSpellCooldown(spell)
		if enabled == 1 and duration > 1.5 and cast[spell] then
			self.watched[spell] = start + duration
		end
	end
end

addon:SetScript("OnUpdate", function(self, elapsed)
	-- Update watched timers
	local time = GetTime()
	for spell, finish in pairs(self.watched) do
		if time > finish then
			table.insert(self.queue, spell)
			self.watched[spell] = nil
			cast[spell] = nil
		end
	end

	-- Are we running allready?
	if self.running then
		self.timer = self.timer + (elapsed * 1.35)
		local s = math_sin(self.timer)
		if self.timer > pi then
			self.icon:SetAlpha(0)
			self.icon:Hide()
			self.icon:SetHeight(size)
			self.icon:SetHeight(size)
			self.timer = 0
			self.running = false
		else
			self.icon:SetHeight(s * size)
			self.icon:SetWidth(s * size)
			self.icon:SetAlpha(s * alpha)
			return
		end
	end

	if #self.queue == 0 then return end

	local spell = table.remove(self.queue, 1)
	self.icon:SetTexture(select(3, GetSpellInfo(spell)))
	self.running = true
	self.icon:Show()
end)
