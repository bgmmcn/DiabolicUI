local _, Engine = ...
local Module = Engine:NewModule("Blizzard: PlayerPowerBarAlt")

Module.OnInit = function(self)
	local content = _G.PlayerPowerBarAlt
	if (not content) then
		return
	end

	local config = self:GetDB("Blizzard").altpower

	local holder = Engine:CreateFrame("Frame", nil, "UICenter")
	holder:Place(unpack(config.position))

	content:SetMovable(true)
	content:SetUserPlaced(true)
	content:ClearAllPoints()
	content:SetPoint("BOTTOM", holder, "BOTTOM", 0, 0)

	_G.UIPARENT_MANAGED_FRAME_POSITIONS["PlayerPowerBarAlt"] = nil

	local lockdown
	hooksecurefunc(content, "SetPoint", function(self, _, anchor) 
		if (not lockdown) then
			lockdown = true
			holder:SetWidth(self:GetWidth())
			holder:SetHeight(self:GetHeight())
			self:ClearAllPoints()
			self:SetPoint("BOTTOM", holder, "BOTTOM", 0, 0)
			lockdown = false
		end
	end)
	
end
