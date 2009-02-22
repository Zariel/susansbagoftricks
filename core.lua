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

local addon = CreateFrame("Frame", nil, UIParent)
local t = addon:CreateTexture(nil, "OVERLAY")

local size = 125
local alpha = 0.8

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

addon.spells = {
	-- Undead
	["Will of the Forsaken"] = true,
	["Cannibalize"] = true,

	-- Rogue
	["Riposte"] = true,
	["Gouge"] = true,
	["Blade Flurry"] = true,
	["Adrenaline Rush"] = true,
	["Killing Spree"] = true,
	["Kick"] = true,
	["Vanish"] = true,
	["Sprint"] = true,
	["Stealth"] = true,
	["Evasion"] = true,
	["Blind"] = true,
	["Kindey Shot"] = true,
	["Cold Blood"] = true,
	["Shadow Step"] = true,
}

addon:SetScript("OnEvent", function(self, event, ...)
	return self[event](self, ...)
end)

addon:RegisterEvent("SPELL_UPDATE_COOLDOWN")

function addon:SPELL_UPDATE_COOLDOWN()
	for spell in pairs(self.spells) do
		local start, duration, enabled = GetSpellCooldown(spell)
		if enabled == 1 and duration > 1.5 then
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
