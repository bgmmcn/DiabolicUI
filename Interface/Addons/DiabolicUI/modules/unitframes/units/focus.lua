local Addon, Engine = ...
local Module = Engine:GetModule("UnitFrames")
local UnitFrameWidget = Module:SetWidget("Unit: Focus")

local UnitFrame = Engine:GetHandler("UnitFrame")
local StatusBar = Engine:GetHandler("StatusBar")
local C = Engine:GetDB("Data: Colors")

-- Lua API
local _G = _G
local pairs = pairs
local table_concat = table.concat
local table_insert = table.insert
local tostring = tostring
local unpack = unpack

-- WoW API
local UnitClass = _G.UnitClass
local UnitIsEnemy = _G.UnitIsEnemy
local UnitIsFriend = _G.UnitIsFriend
local UnitIsPlayer = _G.UnitIsPlayer
local UnitIsTapDenied = _G.UnitIsTapDenied
local UnitPlayerControlled = _G.UnitPlayerControlled
local UnitReaction = _G.UnitReaction

local postUpdateHealth = function(health, unit, curHealth, maxHealth, isUnavailable)

	local r, g, b
	if (not isUnavailable) then
		if UnitIsPlayer(unit) then
			local _, class = UnitClass(unit)
			r, g, b = unpack(class and C.Class[class] or C.Class.UNKNOWN)
		elseif UnitPlayerControlled(unit) then
			if UnitIsFriend("player", unit) then
				r, g, b = unpack(C.Reaction[5])
			elseif UnitIsEnemy(unit, "player") then
				r, g, b = unpack(C.Reaction[1])
			else
				r, g, b = unpack(C.Reaction[4])
			end
		elseif (not UnitIsFriend("player", unit)) and UnitIsTapDenied(unit) then
			r, g, b = unpack(C.Status.Tapped)
		elseif UnitReaction(unit, "player") then
			r, g, b = unpack(C.Reaction[UnitReaction(unit, "player")])
		else
			r, g, b = unpack(C.Orb.HEALTH[1])
		end
	elseif (isUnavailable == "dead") or (isUnavailable == "ghost") then
		r, g, b = unpack(C.Status.Dead)
	elseif (isUnavailable == "offline") then
		r, g, b = unpack(C.Status.Disconnected)
	end

	if r then
		if not((r == health.r) and (g == health.g) and (b == health.b)) then
			health:SetStatusBarColor(r, g, b)
			health.r, health.g, health.b = r, g, b
		end
	end

end

local UpdateLayers = function(self)
	if self:IsMouseOver() then
		self.BorderNormalHighlight:Show()
		--self.PortraitBorderNormalHighlight:Show()
		self.BorderNormal:Hide()
		--self.PortraitBorderNormal:Hide()
	else
		self.BorderNormal:Show()
		--self.PortraitBorderNormal:Show()
		self.BorderNormalHighlight:Hide()
		--self.PortraitBorderNormalHighlight:Hide()
	end
end

local Style = function(self, unit)
	local config = Module:GetDB("UnitFrames").visuals.units.focus
	local db = Module:GetConfig("UnitFrames") 

	self:Size(unpack(config.size))
	self:Place(unpack(config.position))

	
	-- Artwork
	-------------------------------------------------------------------

	local Shade = self:CreateTexture(nil, "BACKGROUND")
	Shade:SetSize(unpack(config.shade.size))
	Shade:SetPoint(unpack(config.shade.position))
	Shade:SetTexture(config.shade.texture)
	Shade:SetVertexColor(config.shade.color)

	local Backdrop = self:CreateTexture(nil, "BORDER")
	Backdrop:SetSize(unpack(config.backdrop.texture_size))
	Backdrop:SetPoint(unpack(config.backdrop.texture_position))
	Backdrop:SetTexture(config.backdrop.texture)

	-- border overlay frame
	local Border = self:CreateFrame("Frame")
	Border:SetFrameLevel(self:GetFrameLevel() + 5)
	Border:SetAllPoints()
	
	local BorderNormal = Border:CreateTexture(nil, "BORDER")
	BorderNormal:SetSize(unpack(config.border.texture_size))
	BorderNormal:SetPoint(unpack(config.border.texture_position))
	BorderNormal:SetTexture(config.border.textures.normal)
	
	local BorderNormalHighlight = Border:CreateTexture(nil, "BORDER")
	BorderNormalHighlight:SetSize(unpack(config.border.texture_size))
	BorderNormalHighlight:SetPoint(unpack(config.border.texture_position))
	BorderNormalHighlight:SetTexture(config.border.textures.highlight)
	BorderNormalHighlight:Hide()


	-- Health
	-------------------------------------------------------------------
	local Health = StatusBar:New(self)
	Health:SetSize(unpack(config.health.size))
	Health:SetPoint(unpack(config.health.position))
	Health:SetStatusBarTexture(config.health.texture)
	Health.frequent = 1/120
	Health.PostUpdate = postUpdateHealth

	
	-- Power
	-------------------------------------------------------------------
	local Power = StatusBar:New(self)
	Power:SetSize(unpack(config.power.size))
	Power:SetPoint(unpack(config.power.position))
	Power:SetStatusBarTexture(config.power.texture)
	Power.frequent = 1/120
	

	-- CastBar
	-------------------------------------------------------------------
	local CastBar = StatusBar:New(Health)
	CastBar:Hide()
	CastBar:SetAllPoints()
	CastBar:SetStatusBarTexture(1, 1, 1, .15)
	CastBar:SetSize(Health:GetSize())
	--CastBar:SetSparkTexture(config.castbar.spark.texture)
	--CastBar:SetSparkSize(unpack(config.castbar.spark.size))
	--CastBar:SetSparkFlash(unpack(config.castbar.spark.flash))
	CastBar:DisableSmoothing(true)


	-- Portrait
	-------------------------------------------------------------------
	--[[
	local PortraitHolder = self:CreateFrame("Frame")
	PortraitHolder:SetSize(unpack(config.portrait.size))
	PortraitHolder:SetPoint(unpack(config.portrait.position))
	
	local PortraitBackdrop = PortraitHolder:CreateTexture(nil, "BACKGROUND")
	PortraitBackdrop:SetSize(unpack(config.portrait.texture_size))
	PortraitBackdrop:SetPoint(unpack(config.portrait.texture_position))
	PortraitBackdrop:SetTexture(config.portrait.textures.backdrop)
	
	local Portrait = PortraitHolder:CreateFrame("PlayerModel")
	Portrait:SetFrameLevel(self:GetFrameLevel() + 1)
	Portrait:SetAllPoints()
	
	local PortraitBorder = PortraitHolder:CreateFrame("Frame")
	PortraitBorder:SetFrameLevel(self:GetFrameLevel() + 2)
	PortraitBorder:SetAllPoints()

	local PortraitBorderNormal = PortraitBorder:CreateTexture(nil, "ARTWORK")
	PortraitBorderNormal:SetSize(unpack(config.portrait.texture_size))
	PortraitBorderNormal:SetPoint(unpack(config.portrait.texture_position))
	PortraitBorderNormal:SetTexture(config.portrait.textures.border)

	local PortraitBorderNormalHighlight = PortraitBorder:CreateTexture(nil, "ARTWORK")
	PortraitBorderNormalHighlight:SetSize(unpack(config.portrait.texture_size))
	PortraitBorderNormalHighlight:SetPoint(unpack(config.portrait.texture_position))
	PortraitBorderNormalHighlight:SetTexture(config.portrait.textures.highlight)
	PortraitBorderNormalHighlight:Hide()
	]]


	-- Threat
	-------------------------------------------------------------------
	local Threat = {}
	
	Threat.Border = self:CreateTexture(nil, "BACKGROUND")
	Threat.Border:Hide()
	Threat.Border:SetSize(unpack(config.border.texture_size))
	Threat.Border:SetPoint(unpack(config.border.texture_position))
	Threat.Border:SetTexture(config.border.textures.threat)

	--[[
	Threat.Portrait = Portrait:CreateTexture(nil, "BACKGROUND")
	Threat.Portrait:Hide()
	Threat.Portrait:SetSize(unpack(config.portrait.texture_size))
	Threat.Portrait:SetPoint(unpack(config.portrait.texture_position))
	Threat.Portrait:SetTexture(config.portrait.textures.threat)
	]]
	
	Threat.Hide = function(self)
		self.Border:Hide()
		--self.Portrait:Hide()
	end

	Threat.Show = function(self)
		self.Border:Show()
		--self.Portrait:Show()
	end
	
	Threat.SetVertexColor = function(self, ...)
		self.Border:SetVertexColor(...)
		--self.Portrait:SetVertexColor(...)
	end


	-- Texts
	-------------------------------------------------------------------
	local Name = Border:CreateFontString(nil, "OVERLAY")
	Name:SetFontObject(config.name.font_object)
	Name:SetPoint(unpack(config.name.position))
	Name:SetSize(unpack(config.name.size))
	Name:SetJustifyV("BOTTOM")
	Name:SetJustifyH("CENTER")
	Name:SetIndentedWordWrap(false)
	Name:SetWordWrap(true)
	Name:SetNonSpaceWrap(false)


	self.CastBar = CastBar
	self.Health = Health
	self.Name = Name
	--self.Portrait = Portrait
	self.Power = Power
	self.Threat = Threat

	self.BorderNormal = BorderNormal
	self.BorderNormalHighlight = BorderNormalHighlight
	--self.PortraitBorderNormal = PortraitBorderNormal
	--self.PortraitBorderNormalHighlight = PortraitBorderNormalHighlight

	self:HookScript("OnEnter", UpdateLayers)
	self:HookScript("OnLeave", UpdateLayers)
	
	--self:SetAttribute("toggleForVehicle", true)

end

UnitFrameWidget.OnEnable = function(self)
	local config = Module:GetDB("UnitFrames").visuals.units.focus
	local db = Module:GetConfig("UnitFrames") 

	self.UnitFrame = UnitFrame:New("focus", Engine:GetFrame(), Style) 

end

UnitFrameWidget.GetFrame = function(self)
	return self.UnitFrame
end

