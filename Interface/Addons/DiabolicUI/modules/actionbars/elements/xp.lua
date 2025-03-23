local _, Engine = ...
local Module = Engine:GetModule("ActionBars")
local BarWidget = Module:SetWidget("Bar: XP")
local StatusBar = Engine:GetHandler("StatusBar")
local L = Engine:GetLocale()
local C = Engine:GetDB("Data: Colors")
local F = Engine:GetDB("Library: Format")

-- Lua API
local _G = _G
local math_floor = math.floor
local math_min = math.min
local select = select
local tonumber = tonumber
local tostring = tostring
local unpack = unpack

-- WoW API
-- Legion
local C_ArtifactUI = _G.C_ArtifactUI
local GetArtifactArtInfo = C_ArtifactUI and C_ArtifactUI.GetArtifactArtInfo
local GetArtifactKnowledgeLevel = C_ArtifactUI and C_ArtifactUI.GetArtifactKnowledgeLevel
local GetArtifactKnowledgeMultiplier = C_ArtifactUI and C_ArtifactUI.GetArtifactKnowledgeMultiplier
local GetCostForPointAtRank = C_ArtifactUI and C_ArtifactUI.GetCostForPointAtRank
local GetEquippedArtifactInfo = C_ArtifactUI and C_ArtifactUI.GetEquippedArtifactInfo
local GetTotalPurchasedRanks = C_ArtifactUI and C_ArtifactUI.GetTotalPurchasedRanks
local GetHonorExhaustion = _G.GetHonorExhaustion
local GetHonorRestState = _G.GetHonorRestState
local GetMaxPlayerHonorLevel = _G.GetMaxPlayerHonorLevel
local UnitHonorLevel = _G.UnitHonorLevel
local UnitPrestige = _G.UnitPrestige

-- BfA
local Item = _G.Item
local C_AzeriteItem = _G.C_AzeriteItem
local FindActiveAzeriteItem = C_AzeriteItem and C_AzeriteItem.FindActiveAzeriteItem
local GetAzeriteItemXPInfo = C_AzeriteItem and C_AzeriteItem.GetAzeriteItemXPInfo
local GetPowerLevel = C_AzeriteItem and C_AzeriteItem.GetPowerLevel

local BreakUpLargeNumbers = _G.BreakUpLargeNumbers
local CreateFrame = _G.CreateFrame
local GetRestState = _G.GetRestState
local GetTimeToWellRested = _G.GetTimeToWellRested
local GetXPExhaustion = _G.GetXPExhaustion
local HasArtifactEquipped = _G.HasArtifactEquipped
local HideUIPanel = _G.HideUIPanel
local IsResting = _G.IsResting
local IsXPUserDisabled = _G.IsXPUserDisabled
local MAX_PLAYER_LEVEL_TABLE = _G.MAX_PLAYER_LEVEL_TABLE
local SocketInventoryItem = _G.SocketInventoryItem
local UnitHasVehicleUI = _G.UnitHasVehicleUI
local UnitHasVehiclePlayerFrameUI = _G.UnitHasVehiclePlayerFrameUI
local UnitHonor = _G.UnitHonor
local UnitHonorMax = _G.UnitHonorMax
local UnitLevel = _G.UnitLevel
local UnitRace = _G.UnitRace
local UnitXP = _G.UnitXP
local UnitXPMax = _G.UnitXPMax

-- WoW Frames & Objects
local GameTooltip = _G.GameTooltip

-- Client version constants
local ENGINE_BFA = Engine:IsBuild("BfA")
local ENGINE_LEGION = Engine:IsBuild("Legion")
local ENGINE_MOP = Engine:IsBuild("MoP")
local ENGINE_CATA = Engine:IsBuild("Cata")

-- Track XP/Rep/Artifact bar visibility
local XPBARVISIBLE

-- Pandaren can get 300% rested bonus
local maxRested = select(2, UnitRace("player")) == "Pandaren" and 3 or 1.5

-- Various string formatting for our tooltips and bars
local shortXPString = "%s%%"
local longXPString = "%s / %s"
local fullXPString = "%s / %s - %s%%"
local restedString = " (%s%% %s)"
local shortLevelString = "%s %d"

-- Just to avoid some updates we don't need
local vehicleEvents = {
	UNIT_ENTERING_VEHICLE = "player", 
	UNIT_EXITING_VEHICLE = "player", 
	UNIT_ENTERED_VEHICLE = "player",
	UNIT_EXITED_VEHICLE = "player"
}

local GetEquippedArtifactXP = function(pointsSpent, artifactXP, artifactTier)
	local numPoints = 0
	local xpForNextPoint = GetCostForPointAtRank(pointsSpent, artifactTier)
	while ((artifactXP >= xpForNextPoint) and (xpForNextPoint > 0)) do
		artifactXP = artifactXP - xpForNextPoint
		pointsSpent = pointsSpent + 1
		numPoints = numPoints + 1
		xpForNextPoint = GetCostForPointAtRank(pointsSpent, artifactTier)
	end
	return numPoints, artifactXP, xpForNextPoint
end


-- Bar Templates
----------------------------------------------------------

local Bar = Engine:CreateFrame("Frame")
local Bar_MT = { __index = Bar }

-- shown if we're in a BG in the Legion expansion or higher
local Bar_Honor = setmetatable({}, { __index = Bar })
local Bar_Honor_MT = { __index = Bar_Honor }

-- high priority, will override almost everything else (not that it's implemented yet...)
local Bar_Reputation = setmetatable({}, { __index = Bar })
local Bar_Reputation_MT = { __index = Bar_Reputation }

-- shown if no reputation is tracked, and user still can gain experience
local Bar_XP = setmetatable({}, { __index = Bar })
local Bar_XP_MT = { __index = Bar_XP }

-- low priority, only shown if player is max level and no reputation is tracked
-- should however be true most of the time for top level players in Legion
local Bar_Artifact = setmetatable({}, { __index = Bar })
local Bar_Artifact_MT = { __index = Bar_Artifact }

-- Standard methods we'll let the module assume always exist 
Bar.UpdateData = function(self) return self.data end
Bar.Update = function(self) end
Bar.OnEnter = function(self) end
Bar.OnLeave = function(self) end

-- Colors
--local C_XP = "XP"
--local C_XP_RESTED = "XPRested"
--local C_XP_BONUS = "XPRestedBonus"

local C_XP = "XPBright"
local C_XP_RESTED = "XPRestedBright"
local C_XP_BONUS = "XPBonusBright"

-- XP Bar Methods
--------------------------------------------------
Bar_XP.UpdateData = function(self)
	self.data.resting = IsResting()
	self.data.restState, self.data.restedName, self.data.mult = GetRestState()
	self.data.restedLeft, self.data.restedTimeLeft = GetXPExhaustion(), GetTimeToWellRested()
	self.data.xp, self.data.xpMax = UnitXP("player"), UnitXPMax("player")
	self.data.color = self.data.restedLeft and C_XP_RESTED or C_XP
	self.data.mult = (self.data.mult or 1) * 100
	if self.data.xpMax == 0 then
		self.data.xpMax = nil
	end
	return self.data
end

Bar_XP.Update = function(self)
	local data = self:UpdateData()
	if (not data.xpMax) then return end
	local r, g, b = unpack(C.General[data.color])
	self.XP:SetStatusBarColor(r, g, b)
	self.XP:SetMinMaxValues(0, data.xpMax)
	self.XP:SetValue(data.xp)
	self.Rested:SetMinMaxValues(0, data.xpMax)
	self.Rested:SetValue(math_min(data.xpMax, data.xp + (data.restedLeft or 0)))
	if (not self.Rested:IsShown()) then
		self.Rested:Show()
	end
	if data.restedLeft then
		local r, g, b = unpack(C.General.XPRestedBonus)
		self.Backdrop:SetVertexColor(r *.25, g *.25, b *.25)
	else
		self.Backdrop:SetVertexColor(r *.25, g *.25, b *.25)
	end
	if self.mouseIsOver then
		if data.restedLeft then
			self.Value:SetFormattedText(fullXPString..F.Colorize(restedString, "OffGreen"), F.Colorize(F.Short(data.xp), "Normal"), F.Colorize(F.Short(data.xpMax), "Normal"), F.Colorize(F.Short(math_floor(data.xp/data.xpMax*100)), "Normal"), F.Short(math_floor(data.restedLeft/data.xpMax*100)), L["Rested"])
		else
			self.Value:SetFormattedText(fullXPString, F.Colorize(F.Short(data.xp), "Normal"), F.Colorize(F.Short(data.xpMax), "Normal"), F.Colorize(F.Short(math_floor(data.xp/data.xpMax*100)), "Normal"))
		end
	else
		self.Value:SetFormattedText(shortXPString, F.Colorize(F.Short(math_floor(data.xp/data.xpMax*100)), "Normal"))
	end
end

Bar_XP.OnEnter = function(self)
	local data = self:UpdateData()
	if not data.xpMax then return end

	if GameTooltip:IsForbidden() then
		return
	end

	GameTooltip_SetDefaultAnchor(GameTooltip, self)
	--GameTooltip:SetOwner(self.Controller, "ANCHOR_NONE")

	local r, g, b = unpack(C.General.Highlight)
	local r2, g2, b2 = unpack(C.General.OffWhite)

	GameTooltip:AddLine(shortLevelString:format(LEVEL, UnitLevel("player")))
	GameTooltip:AddLine(" ")

	GameTooltip:AddLine(F.Colorize(POWER_TYPE_EXPERIENCE, "Normal"))
	GameTooltip:AddDoubleLine(L["Current XP: "], longXPString:format(F.Colorize(F.Short(data.xp), "Normal"), F.Colorize(F.Short(data.xpMax), "Normal")), r2, g2, b2, r2, g2, b2)
	
	-- add rested bonus if it exists
	if data.restedLeft and data.restedLeft > 0 then
		GameTooltip:AddDoubleLine(L["Rested Bonus: "], longXPString:format(F.Colorize(F.Short(data.restedLeft), "Normal"), F.Colorize(F.Short(data.xpMax * maxRested), "Normal")), r2, g2, b2, r2, g2, b2)
	end

	if ENGINE_BFA then 
		local hasAP = FindActiveAzeriteItem()

		if hasAP then 
			local min, max = GetAzeriteItemXPInfo(hasAP)
			local level = GetPowerLevel(hasAP) 

			local r, g, b = unpack(C.General.Highlight)
			GameTooltip:AddLine(" ")
			GameTooltip:AddDoubleLine(F.Colorize(ARTIFACT_POWER, "Normal"), F.Colorize(level, "Highlight"))
			GameTooltip:AddDoubleLine(L["Current Artifact Power: "], longXPString:format(F.Colorize(F.Short(min), "Normal"), F.Colorize(F.Short(max), "Normal")), r, g, b, r, g, b)
		end 
	end  
	
	if data.restState == 1 then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(L["Rested"], unpack(C.General.Highlight))
		GameTooltip:AddLine(L["%s of normal experience\ngained from monsters."]:format(shortXPString:format(data.mult)), unpack(C.General.Green))
		if data.resting and data.restedTimeLeft and data.restedTimeLeft > 0 then
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine(L["Resting"], unpack(C.General.Highlight))
			if data.restedTimeLeft > hour*2 then
				GameTooltip:AddLine(L["You must rest for %s additional\nhours to become fully rested."]:format(F.Colorize(math_floor(data.restedTimeLeft/hour), "OffWhite")), unpack(C.General.Normal))
			else
				GameTooltip:AddLine(L["You must rest for %s additional\nminutes to become fully rested."]:format(F.Colorize(math_floor(data.restedTimeLeft/minute), "OffWhite")), unpack(C.General.Normal))
			end
		end
	elseif data.restState >= 2 then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(L["Normal"], unpack(C.General.Highlight))
		GameTooltip:AddLine(L["%s of normal experience\ngained from monsters."]:format(shortXPString:format(data.mult)), unpack(C.General.Green))

		if not(data.restedTimeLeft and data.restedTimeLeft > 0) then 
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine(L["You should rest at an Inn."], unpack(C.General.DimRed))
		end
	end

	GameTooltip:Show()
end

Bar_XP.OnLeave = function(self)
	if (not GameTooltip:IsForbidden()) then
		GameTooltip:Hide()
	end
end


-- Artifact Bar Methods
--------------------------------------------------
Bar_Artifact.UpdateData = ENGINE_BFA and function(self) 

	local azeriteItemLocation = FindActiveAzeriteItem()
	if azeriteItemLocation then

		self.data.name = ARTIFACT_POWER
		self.data.rank = GetPowerLevel(azeriteItemLocation)
		self.data.equipped = true
		self.data.color = C.Quality[6]
		self.data.barValue, self.data.barMax = GetAzeriteItemXPInfo(azeriteItemLocation)
	else
		self.data.name = nil
		self.data.rank = nil
		self.data.equipped = nil
		self.data.color = nil
		self.data.itemID = nil
		self.data.totalXP = nil
		self.data.unusedPoints = nil
		self.data.barValue = nil
		self.data.barMax = nil
	end
	return self.data


end or function(self)
	local equipped = HasArtifactEquipped()
	if equipped then
		-- artifactTier argument added in 7.2.0. 
		local itemID, altItemID, name, icon, totalXP, usedPoints, quality, _, _, _, _, _, artifactTier = GetEquippedArtifactInfo()
		local unusedPoints, value, max = GetEquippedArtifactXP(usedPoints, totalXP, artifactTier)

		self.data.name = name
		self.data.rank = usedPoints
		self.data.equipped = true
		self.data.color = C.Quality[quality]
		self.data.itemID = itemID
		self.data.totalXP = totalXP
		self.data.unusedPoints = unusedPoints
		self.data.barValue = value
		self.data.barMax = max
	else
		self.data.name = nil
		self.data.rank = nil
		self.data.equipped = nil
		self.data.color = nil
		self.data.itemID = nil
		self.data.totalXP = nil
		self.data.unusedPoints = nil
		self.data.barValue = nil
		self.data.barMax = nil
	end
	return self.data
end

Bar_Artifact.Update = function(self)
	local data = self:UpdateData()
	if (not data.name) then return end
	self.XP:SetStatusBarColor(unpack(data.color))
	self.XP:SetMinMaxValues(0, data.barMax)
	self.XP:SetValue(data.barValue)

	if (self.Rested:IsShown()) then
		self.Rested:Hide()
	end

	if self.mouseIsOver then
		self.Value:SetFormattedText(fullXPString, F.Colorize(F.Short(data.barValue), "Normal"), F.Colorize(F.Short(data.barMax), "Normal"), F.Colorize(F.Short(math_floor(data.barValue/data.barMax*100)), "Normal"))
	else
		self.Value:SetFormattedText(shortXPString, F.Colorize(F.Short(math_floor(data.barValue/data.barMax*100)), "Normal"))
	end

end

Bar_Artifact.OnClick = function(self, button)
	if (button == "LeftButton") then
		local ArtifactFrame = _G.ArtifactFrame
		if ((not ArtifactFrame) and ArtifactFrame_LoadUI) then
			ArtifactFrame_LoadUI()
			ArtifactFrame = _G.ArtifactFrame
		end
		if (ArtifactFrame and ArtifactFrame:IsShown()) then 
			HideUIPanel(ArtifactFrame)
		elseif (ArtifactFrame and (not ArtifactFrame:IsShown())) then
			ShowUIPanel(SocketInventoryItem(16))
			--SocketInventoryItem(16)
		end
	end
end

Bar_Artifact.OnEnter = ENGINE_BFA and function(self)

	local data = self:UpdateData()
	if not data.barMax then return end

	if GameTooltip:IsForbidden() then
		return
	end

	GameTooltip_SetDefaultAnchor(GameTooltip, self)

	local hasAP = FindActiveAzeriteItem()
	local min, max = GetAzeriteItemXPInfo(hasAP)
	local level = GetPowerLevel(hasAP) 

	local r, g, b = unpack(C.General.Highlight)
	local nameR, nameG, nameB = unpack(data.color)
	GameTooltip:AddDoubleLine(ARTIFACT_POWER, level, nameR, nameG, nameB, r, g, b)
	GameTooltip:AddDoubleLine(L["Current Artifact Power: "], longXPString:format(F.Colorize(F.Short(data.barValue), "Normal"), F.Colorize(F.Short(data.barMax), "Normal")), r, g, b, r, g, b)

	GameTooltip:Show()


end or function(self)
	local data = self:UpdateData()
	if not data.barMax then return end

	if GameTooltip:IsForbidden() then
		return
	end

	GameTooltip_SetDefaultAnchor(GameTooltip, self)

	-- artifactTier argument added in 7.2.0. 
	local itemID, altItemID, name, icon, totalXP, usedPoints, quality, _, _, _, _, _, artifactTier = GetEquippedArtifactInfo()
	local unusedPoints, value, max = GetEquippedArtifactXP(usedPoints, totalXP, artifactTier)

	--GameTooltip:AddLine(ARTIFACTS_NUM_PURCHASED_RANKS:format(GetTotalPurchasedRanks()), HIGHLIGHT_FONT_COLOR:GetRGB());

	local r, g, b = unpack(C.General.Highlight)
	local nameR, nameG, nameB = unpack(data.color)
	GameTooltip:AddDoubleLine(data.name, data.rank, nameR, nameG, nameB, r, g, b)

	local r, g, b = unpack(C.General.OffWhite)
	GameTooltip:AddDoubleLine(L["Current Artifact Power: "], longXPString:format(F.Colorize(F.Short(data.barValue), "Normal"), F.Colorize(F.Short(data.barMax), "Normal")), r, g, b, r, g, b)

	local knowledgeLevel = GetArtifactKnowledgeLevel()
	if knowledgeLevel and knowledgeLevel > 0 then
		local knowledgeMultiplier = GetArtifactKnowledgeMultiplier()

		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(ARTIFACTS_KNOWLEDGE_TOOLTIP_LEVEL:format(knowledgeLevel), HIGHLIGHT_FONT_COLOR:GetRGB())

		-- Deducting 100% from the knowledge gain value, since we're displaying the increase, not the total. 
		GameTooltip:AddLine(ARTIFACTS_KNOWLEDGE_TOOLTIP_DESC:format(BreakUpLargeNumbers(knowledgeMultiplier * 100 - 100)), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true)
	end

	if (data.unusedPoints > 0) then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(ARTIFACT_POWER_TOOLTIP_BODY:format(data.unusedPoints), nil, nil, nil, true)
	end

	GameTooltip:AddLine(" ")
	GameTooltip:AddLine(L["<Left-Click to toggle Artifact Window>"], unpack(C.General.OffGreen))
	GameTooltip:Show()
end

Bar_Artifact.OnLeave = function(self)
	if (not GameTooltip:IsForbidden()) then
		GameTooltip:Hide()
	end
end


-- Honor Bar Methods
--------------------------------------------------
Bar_Honor.UpdateData = ENGINE_BFA and function(self)
	local data = self.data

	local current = UnitHonor("player")
	local max = UnitHonorMax("player")

	data.color = C.General.Honor
	data.honor = current
	data.honorMax = max
	data.resting = IsResting()

	return data

end or function(self)
	local data = self.data

	local current = UnitHonor("player")
	local max = UnitHonorMax("player")
	local level = UnitHonorLevel("player")
	local levelMax = GetMaxPlayerHonorLevel()
	local prestige = ENGINE_LEGION and UnitPrestige("player") or 0
	local exhaustionStateID, exhaustionStateName, exhaustionStateMultiplier = GetHonorRestState()
	local exhaustionThreshold = GetHonorExhaustion()

	local exhaustionCountdown = nil
	local timeToWellRested = GetTimeToWellRested()
	if timeToWellRested then
		exhaustionCountdown = timeToWellRested / 60
	end

	data.color = C.General.Honor
	data.honor = current
	data.prestige = prestige
	data.honorMax = max
	data.honorLevel = level
	data.honorLevelMax = levelMax
	data.honorExhaustID = exhaustionStateID
	data.honorExhaustName = exhaustionStateName
	data.honorExhaustThreshold = exhaustionThreshold
	data.honorExhaustPercent = (exhaustionStateMultiplier or 1) * 100
	data.honorExhaustCountdown = exhaustionCountdown
	data.resting = IsResting()
    
	--if (exhaustionStateID == 1) then
		-- rested?
	--end

	return data
end

Bar_Honor.Update = function(self)
	local data = self:UpdateData()
	if (not data.honorMax) then return end

	self.XP:SetStatusBarColor(unpack(data.color))
	self.XP:SetMinMaxValues(0, data.honorMax)
	self.XP:SetValue(data.honor)

	if (self.Rested:IsShown()) then
		self.Rested:Hide()
	end

	if self.mouseIsOver then
		self.Value:SetFormattedText(fullXPString, F.Colorize(F.Short(data.honor), "Normal"), F.Colorize(F.Short(data.honorMax), "Normal"), F.Colorize(F.Short(math_floor(data.honor/data.honorMax*100)), "Normal"))
	else
		self.Value:SetFormattedText(shortXPString, F.Colorize(F.Short(math_floor(data.honor/data.honorMax*100)), "Normal"))
	end
end

-- Not strictly certain if this causes taint or not.
-- It didn't in my own tests. 
Bar_Honor.OnClick = function(self)
	ToggleTalentFrame(PVP_TALENTS_TAB)
end

Bar_Honor.OnEnter = function(self)
	local data = self:UpdateData()
	if not data.honorMax then return end

	if GameTooltip:IsForbidden() then
		return
	end

	GameTooltip_SetDefaultAnchor(GameTooltip, self)

	local r, g, b = unpack(C.General.Highlight)
	local r2, g2, b2 = unpack(C.General.OffWhite)
	local nameR, nameG, nameB = unpack(data.color)

	if (data.prestige and (data.prestige > 0)) then 
		GameTooltip:AddDoubleLine(HONOR, data.honorLevel .. " ("..F.Colorize(data.prestige, "Normal") ..")", nameR, nameG, nameB, r, g, b)
	else 
		GameTooltip:AddDoubleLine(HONOR, data.honorLevel, nameR, nameG, nameB, r, g, b)
	end 
	GameTooltip:AddDoubleLine(L["Current Honor Points: "], longXPString:format(F.Colorize(F.Short(data.honor), "Normal"), F.Colorize(F.Short(data.honorMax), "Normal")), r2, g2, b2, r2, g2, b2)

	GameTooltip:AddLine(" ")
	GameTooltip:AddLine(L["<Left-Click to toggle Honor Talents Window>"], unpack(C.General.OffGreen))

	GameTooltip:Show()
end

Bar_Honor.OnLeave = function(self)
	if (not GameTooltip:IsForbidden()) then
		GameTooltip:Hide()
	end
end



BarWidget.OnEnter = function(self)
	self.Bar.mouseIsOver = true
	self.Bar:OnEnter()
	self:UpdateBar()
end

BarWidget.OnLeave = function(self)
	self.Bar.mouseIsOver = false
	self.Bar:OnLeave()
	self:UpdateBar()
end

BarWidget.Update = function(self, event, unit)
	if event and vehicleEvents[event] and (vehicleEvents[event] ~= unit) then
		return
	end
	if self:UpdateVisibility() then
		self:UpdateBarType()
		self:UpdateBar()
	end
end

BarWidget.OnClick = function(self, ...)
	if (self.Bar.OnClick) then
		self.Bar:OnClick(...)
	end
end

BarWidget.UpdateVisibility = function(self)
	local isXPVisible = Module:IsXPVisible()
	if isXPVisible then
		if (not self.Controller:IsShown()) then
			self.Controller:Show()
		end
	else
		if self.Controller:IsShown() then
			self.Controller:Hide()
		end
	end
	if (XPBARVISIBLE ~= isXPVisible) then
		self:SendMessage("ENGINE_ACTIONBAR_XP_VISIBLE_CHANGED", isXPVisible)
		XPBARVISIBLE = isXPVisible
	end
	return isXPVisible
end

BarWidget.UpdateBarType = function(self)

	-- Get info about visible XP type
	local xp, artifact, honor = Module:IsXPVisible()
	local barType = honor and "honor" or artifact and "artifact" or xp and "xp" or "none"

	-- Initiate a bar change if the XP type has changed
	if (self.barType ~= barType) then

		-- Store the old tooltip state in case it's visible
		local mouseIsOver = self.mouseIsOver 

		-- Kill of old tooltip if visible on bar changes
		self:OnLeave() 

		-- Choose the correct inheritance for our current bar 
		if (barType == "xp") then
			setmetatable(self.Bar, Bar_XP_MT)
		elseif (barType == "artifact") then
			setmetatable(self.Bar, Bar_Artifact_MT)
		elseif (barType == "honor") then
			setmetatable(self.Bar, Bar_Honor_MT)
		end

		-- Store the current bartype
		self.barType = barType 

		-- Show the tooltip belonging to the current bartype
		if mouseIsOver then
			self:OnEnter()
		end
	end
end

BarWidget.UpdateBar = function(self)
	self.Bar:Update()
end

BarWidget.UpdateBarSettings = function(self)
	local structure_config = Module.config.structure.controllers.xp
	local art_config = Module.config.visuals.xp
	local num_bars = tostring(self.Controller:GetParent():GetAttribute("numbars"))

	self.Controller:SetSize(unpack(structure_config.size[num_bars]))
	self.Bar:SetSize(self.Controller:GetSize())
	self.Bar.XP:SetSize(self.Controller:GetSize())
	self.Bar.Rested:SetSize(self.Controller:GetSize())
	self.Bar.Backdrop:SetTexture(art_config.backdrop.textures[num_bars])
end

BarWidget.OnEnable = function(self)
	local structure_config = Module.config.structure.controllers.xp
	local art_config = Module.config.visuals.xp
	local num_bars = tostring(Module.db.num_bars)

	local Main = Module:GetWidget("Controller: Main"):GetFrame()

	local controller = Main:CreateFrame("Frame")
	controller:SetFrameStrata("BACKGROUND")
	controller:SetFrameLevel(0)
	controller:SetSize(unpack(Module.config.structure.controllers.xp.size[num_bars]))
	controller:SetPoint(unpack(Module.config.structure.controllers.xp.position))
	controller:EnableMouse(true)
	controller:SetScript("OnEnter", function() self:OnEnter() end)
	controller:SetScript("OnLeave", function() self:OnLeave() end)
	controller:SetScript("OnMouseUp", function(_, ...) self:OnClick(...) end)
	self.Controller = controller

	local bar = setmetatable(controller:CreateFrame("Frame"), Bar_MT)
	bar:SetSize(controller:GetSize())
	bar:SetAllPoints(controller)
	bar.data = {}

	local backdrop = bar:CreateTexture(nil, "BACKGROUND")
	backdrop:SetSize(unpack(art_config.backdrop.texture_size))
	backdrop:SetPoint(unpack(art_config.backdrop.texture_position))
	backdrop:SetTexture(art_config.backdrop.textures[num_bars])
	backdrop:SetAlpha(.75)
	
	local rested = StatusBar:New(controller)
	rested:SetSize(controller:GetSize())
	rested:SetAllPoints()
	rested:SetFrameLevel(1)
	rested:SetAlpha(art_config.rested.alpha)
	rested:SetStatusBarTexture(art_config.rested.texture)
	rested:SetStatusBarColor(unpack(C.General[C_XP_BONUS]))
	rested:SetSparkTexture(art_config.rested.spark.texture)
	rested:SetSparkSize(unpack(art_config.rested.spark.size))
	rested:SetSparkFlash(2.75, 1.25, .175, .425)
	
	local xp = StatusBar:New(controller)
	xp:SetSize(controller:GetSize())
	xp:SetAllPoints()
	xp:SetFrameLevel(2)
	xp:SetAlpha(art_config.bar.alpha)
	xp:SetStatusBarTexture(art_config.bar.texture)
	xp:SetSparkTexture(art_config.bar.spark.texture)
	xp:SetSparkSize(unpack(art_config.bar.spark.size))
	xp:SetSparkFlash(2.75, 1.25, .35, .85)
	
	local overlay = controller:CreateFrame("Frame")
	overlay:SetFrameStrata("MEDIUM")
	overlay:SetFrameLevel(35) -- above the actionbar artwork
	overlay:SetAllPoints()
	
	local value = overlay:CreateFontString(nil, "OVERLAY")
	value:SetPoint("CENTER")
	value:SetFontObject(art_config.normalFont)
	value:Hide()
	
	bar.Backdrop = backdrop
	bar.Rested = rested
	bar.XP = xp
	bar.Value = value

	self.Bar = bar
	
	-- Our XP/Rep bars aren't secure, so we need to update their sizes
	-- from normal Lua, not the secure environment.
	Main:HookScript("OnAttributeChanged", function(_, name, value) 
		if (name == "numbars") then
			self:UpdateBarSettings()
		elseif (name == "state-page") then
			self.InVehicle = value == "vehicle"
		end
		bar:Update()
	end)
	
	self:RegisterEvent("PLAYER_ALIVE", "Update")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "Update")
	self:RegisterEvent("PLAYER_LEVEL_UP", "Update")
	self:RegisterEvent("PLAYER_XP_UPDATE", "Update")
	self:RegisterEvent("PLAYER_LOGIN", "Update")
	self:RegisterEvent("PLAYER_FLAGS_CHANGED", "Update")
	self:RegisterEvent("DISABLE_XP_GAIN", "Update")
	self:RegisterEvent("ENABLE_XP_GAIN", "Update")
	self:RegisterEvent("PLAYER_UPDATE_RESTING", "Update")
	self:RegisterEvent("UNIT_ENTERING_VEHICLE", "Update")
	self:RegisterEvent("UNIT_ENTERED_VEHICLE", "Update")
	self:RegisterEvent("UNIT_EXITING_VEHICLE", "Update")
	self:RegisterEvent("UNIT_EXITED_VEHICLE", "Update")
	self:RegisterEvent("UNIT_INVENTORY_CHANGED", "Update")

	if ENGINE_MOP then 
		self:RegisterEvent("UPDATE_EXTRA_ACTIONBAR", "Update")
		self:RegisterEvent("UPDATE_OVERRIDE_ACTIONBAR", "Update")
	end

	if ENGINE_LEGION then
		self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", "Update") -- not really needed

		if (not ENGINE_BFA) then 
			self:RegisterEvent("ARTIFACT_XP_UPDATE", "Update")
			self:RegisterEvent("HONOR_LEVEL_UPDATE", "Update")
			self:RegisterEvent("HONOR_PRESTIGE_UPDATE", "Update")
		end 
	end

	if ENGINE_BFA then 
		self:RegisterEvent("AZERITE_ITEM_EXPERIENCE_CHANGED", "Update")
	end 
	
	-- Note to self for later: 
	-- 	ReputationWatchBarStatusBar ( >= WoD)
	-- 	ReputationWatchBar.StatusBar (Legion > )

end

BarWidget.GetFrame = function(self)
	return self.Controller
end

