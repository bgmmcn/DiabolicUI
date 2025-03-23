local _, Engine = ...
local Module = Engine:NewModule("Alerts")

-- Lua API
local _G = _G
local string_gsub = string.gsub
local string_match = string.match

-- WoW Frames & Objects
local AlertFrame = _G.AlertFrame

Module.OnEnable = function(self)
	if AlertFrame then
		local anchor = Engine:CreateFrame("Frame", nil, "UICenter")
		anchor:SetSize(180,20)
		anchor:SetPoint("BOTTOM", 0, 220)

		AlertFrame:ClearAllPoints()
		AlertFrame:SetAllPoints(anchor)
	end
end

