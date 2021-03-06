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

if(not next(ns.spells)) then return end

local GetTime = GetTime
local GetSpellCooldown = GetSpellCooldown
local GetSpellInfo = GetSpellInfo
local pi = math.pi
local cos = math.cos
local select = select

local playerName = UnitName("player")

local steps = 75
local modifier = 1 / steps

local size = 175
local alpha = 0.9

local MAX_ICONS = 1
addon.queue = {}
addon.watched = {}
addon.cast = {}

local hide
local iconPool = setmetatable({}, {
	__index = function(self, key)
		if(not key) then return end
		local f = CreateFrame("Frame", nil, addon)
		local t = f:CreateTexture(nil, "OVERLAY")

		f:SetScript("OnHide", function(self)
			self:SetHeight(size)
			self:SetWidth(size)
			self:SetAlpha(0)
			self.step = 0
			self.running = false
		end)

		f:SetPoint("CENTER", UIParent, "CENTER")
		f:SetAlpha(0)
		f:SetHeight(size)
		f:SetWidth(size)

		t:SetAllPoints(f)
		t:SetTexCoord(0.07, 0.93, 0.07, 0.93)

		t.step = 0
		t.running = false

		f.icon = t

		f:Hide()

		rawset(self, key, f)
		return f
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

function addon:COMBAT_LOG_EVENT_UNFILTERED(timeStamp, event, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellId, spellName)
	if(sourceName == playerName and spellName and ns.spells[spellName]) then
		self.cast[spellName] = true
	end
end

function addon:SPELL_UPDATE_COOLDOWN()
	local start, duration, enabled
	local time = GetTime()

	for spell in pairs(self.cast) do
		start, duration, enabled = GetSpellCooldown(spell)

		local expire = start + duration - 0.5
		if(enabled == 1 and duration > 1.5 and expire > time and not self.watched[spell]) then
			-- On Cooldown
			self.watched[spell] = expire
		elseif(self.watched[spell] and self.watched[spell] ~= expire) then
			-- Was on cooldown, not anymore
			self.watched[spell] = 0
			self.cast[spell] = nil
		end
	end
end

local icons = 0
addon:SetScript("OnUpdate", function(self, elapsed)
	-- Dont want to do this here :(
	local time = GetTime()
	for spell, expire in pairs(self.watched) do
		if(expire < time) then
			table.insert(self.queue, spell)
			self.watched[spell] = nil
		end
	end

	-- Are we running allready?
	for id = 1, #self.queue do
		local spell = self.queue[id]
		local icon = iconPool[spell]
		if(icon) then
			if(icon.step > steps) then
				-- Finished
				table.remove(self.queue, id)
				icon:Hide()
			elseif(id < 2) then
				icon.icon:SetTexture(texCache[spell])
				icon:Show()
			else
				return
			end
			if(icon:IsShown()) then
				local cosine = cosineInterpolation(0, 1, modifier * icon.step)
				icon:SetHeight(cosine * size)
				icon:SetWidth(cosine * size)
				icon:SetAlpha(cosine * alpha)
				icon.step = icon.step + 1
			end
		end
	end
end)
