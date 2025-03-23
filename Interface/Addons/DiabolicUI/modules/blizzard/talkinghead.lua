local _, Engine = ...
local Module = Engine:NewModule("Blizzard: TalkingHead")

-- Lua API
local _G = _G
local ipairs = ipairs
local table_remove = table.remove

-- WoW API
local AlertFrame = _G.AlertFrame

-- WoW Objects
local UIParent = _G.UIParent
local UIPARENT_MANAGED_FRAME_POSITIONS = _G.UIPARENT_MANAGED_FRAME_POSITIONS

Module.InitializeTalkingHead = function(self)
	local content = _G.TalkingHeadFrame

	-- This means the addon hasn't been loaded, 
	-- so we register a listener and return.
	if (not content) then
		return self:RegisterEvent("ADDON_LOADED", "WaitForTalkingHead")
	end

	-- Put the actual talking head into our /glock holder
	content:ClearAllPoints()
	content:SetPoint("BOTTOM", self.frame, "BOTTOM", 0, 0)
	content.ignoreFramePositionManager = true

	-- Kill off Blizzard's repositioning
	UIParent:UnregisterEvent("TALKINGHEAD_REQUESTED")
	UIPARENT_MANAGED_FRAME_POSITIONS["TalkingHeadFrame"] = nil

	-- Iterate through all alert subsystems in order to find the one created for TalkingHeadFrame, and then remove it.
	-- We do this to prevent alerts from anchoring to this frame when it is shown.
	local AlertFrame = _G.AlertFrame
	for index, alertFrameSubSystem in ipairs(AlertFrame.alertFrameSubSystems) do
		if (alertFrameSubSystem.anchorFrame and (alertFrameSubSystem.anchorFrame == content)) then
			table_remove(AlertFrame.alertFrameSubSystems, index)
		end
	end

end

Module.WaitForTalkingHead = function(self, event, ...)
	local addon = ...
	if (addon ~= "Blizzard_TalkingHeadUI") then
		return
	end

	self:InitializeTalkingHead()
	self:UnregisterEvent("ADDON_LOADED", "WaitForTalkingHead")
end

Module.OnInit = function(self)
	self.config = self:GetDB("Blizzard").talkinghead

	-- Create our container frame
	self.frame = Engine:CreateFrame("Frame", nil, "UICenter")
	self.frame:Place(unpack(self.config.position))
	self.frame:Size(unpack(self.config.size))

end

Module.OnEnable = function(self)
	self:InitializeTalkingHead()
end

