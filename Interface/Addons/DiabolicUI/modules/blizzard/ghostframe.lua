local _, Engine = ...
local Module = Engine:NewModule("Blizzard: GhostFrame")

Module.OnInit = function(self)
	local content = GhostFrame
	if (not content) then
		return
	end

	local config = self:GetDB("Blizzard").ghostframe

	local holder = Engine:CreateFrame("Frame", nil, "UICenter")
	holder:Place(unpack(config.position))
	holder:SetWidth(content:GetWidth())
	holder:SetHeight(content:GetHeight())

	content:ClearAllPoints()
	content:SetPoint("BOTTOM", holder, "BOTTOM", 0, 0)

	--	hooksecurefunc(content, "SetPoint", function(self, _, anchor) 
	--		if anchor == "MinimapCluster" or anchor == _G["MinimapCluster"] then
	--			self:ClearAllPoints()
	--			self:SetPoint("BOTTOM", holder, "BOTTOM", 0, 0)
	--		end
	--	end)

end
