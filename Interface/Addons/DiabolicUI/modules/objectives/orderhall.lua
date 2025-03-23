local _, Engine = ...
if (not Engine:IsBuild("Legion")) then
	return 
end
local Module = Engine:NewModule("OrderHall")

Module.UpdateOrderHallUI = function(self, event, ...)
	local config = self.config
end

Module.CreateOrderHallUI = function(self, event, ...)
	local config = self.config

	self:RegisterEvent("DISPLAY_SIZE_CHANGED", "UpdateOrderHallUI")
	self:RegisterEvent("UI_SCALE_CHANGED", "UpdateOrderHallUI")
	self:RegisterEvent("GARRISON_FOLLOWER_CATEGORIES_UPDATED", "UpdateOrderHallUI")
	self:RegisterEvent("GARRISON_FOLLOWER_ADDED", "UpdateOrderHallUI")
	self:RegisterEvent("GARRISON_FOLLOWER_REMOVED", "UpdateOrderHallUI")

end

Module.KillBlizzard = function(self, event, ...)
	self:GetHandler("BlizzardUI"):GetElement("OrderHall"):Disable()
end

Module.Blizzard_Loaded = function(self, event, addon, ...)
	if addon == "Blizzard_OrderHallUI" then
		self:UnregisterEvent("ADDON_LOADED", "Blizzard_Loaded")
		self:KillBlizzard()
	end
end

Module.OnInit = function(self)
	self.config = self:GetDB("Objectives").zoneinfo.orderhall

	if IsAddOnLoaded("Blizzard_OrderHallUI") then
		self:KillBlizzard()
	else
		self:RegisterEvent("ADDON_LOADED", "Blizzard_Loaded")
	end

end

Module.OnEnable = function(self)

	local parent = Engine:CreateFrame("Frame", nil, "UICenter", "SecureHandlerAttributeTemplate")
	parent:SetSize(2,2)
	parent:SetPoint("TOP")

	RegisterStateDriver(parent, "visibility", "[@target,exists]hide;show")

	self.frame = parent:CreateFrame("Frame")
	self.frame:Hide()
	self.frame:Place("TOP", "UICenter", "TOP", 0, -30)
	self.frame:SetSize(32, 32)

end 
