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

local parent, ns = ...
local addon = ns.addon

local GetTime = GetTime
local GetSpellCooldown = GetSpellCooldown
local GetSpellInfo = GetSpellInfo
local pi = math.pi
local cos = math.cos
local select = select

local playerName = UnitName("player")

local steps = 50
local modifier = 1 / steps

local size = 175
local alpha = 0.9

local MAX_ICONS = 2

local iconPool = setmetatable({}, {
	__index = function(self, key)
		local t = addon:CreateTexture(nil, "OVERLAY")

		t:SetScript("OnHide", function()
			t:SetHeight(size)
			t:SetWidth(size)
			t:SetAlpha(0)
			t.step = 0
			t.running = false
		end)

		t:SetHeight(size)
		t:SetWidth(size)
		t:SetPoint("CENTER", UIParent, "CENTER")
		t:SetAlpha(0)
		t:SetTexCoord(0.07, 0.93, 0.07, 0.93)
		t:Hide()

		t.step = 0
		t.running = false

		rawset(self, key, t)
		return t
	end,
})

local texCache = setmetatable({}, {
	__mode = "k",
	__index = function(self, spell)
		local tex = select(3, GetSpellInfo(spell))
		rawset(self, spell, tex)
		return tex
	end,
})

-- Taken from oPanel ~~
local cosineInterpolation = function(y1, y2, mu)
	return y1 + (y2 - y1) * (1 - cos(pi * mu)) / 2
end

addon:SetScript("OnEvent", function(self, event, ...)
	return self[event](self, ...)
end)

addon:RegisterEvent("SPELL_UPDATE_COOLDOWN")
addon:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

local cast = {}

function addon:COMBAT_LOG_EVENT_UNFILTERED(timeStamp, event, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellId, spellName)
	if(sourceName == playerName and spellName and spells[spellName]) then
		cast[spellName] = true
	end
end

function addon:SPELL_UPDATE_COOLDOWN()
	local start, duration, enabled
	local time = GetTime()

	for spell in next, cast do
		start, duration, enabled = GetSpellCooldown(spell)

		if(enabled == 1 and duration > 1.5) then
			self.watched[spell] = start + duration
		elseif(self.watched[spell] or (start + duration) > time) then
			table.insert(self.queue, spell)
		end
	end
end

local icons = 0
addon:SetScript("OnUpdate", function(self, elapsed)
	-- Are we running allready?
	for id, spell in pairs(self.queue) do
		local icon = iconPool[spell]
		if(icon.step > steps) then
			-- Finished
			table.remove(self.queue, id)
			icon:Hide()
			icons = icons - 1
		elseif(icons < MAX_ICONS) then
			icons = icons + 1
			icon:SetFrameLevel(MAX_ICONS - icons)
			icon:Show()
		end
		if(icon:IsShown()) then
			local cosine = cosineInterpolation(0, 1, modifier * icon.step)
			icon:SetHeight(cosine * size)
			icon:SetWidth(cosine * size)
			icon:SetAlpha(cosine * alpha)
			icon.step = icon.step + 1
		end
	end
end)
