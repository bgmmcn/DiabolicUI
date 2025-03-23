local _, Engine = ...
local Handler = Engine:GetHandler("UnitFrame")
local C = Engine:GetDB("Data: Colors")
local F = Engine:GetDB("Library: Format")

-- Lua API
local _G = _G
local math_floor = math.floor

-- WoW API
local UnitAlternatePowerInfo = _G.UnitAlternatePowerInfo
local UnitPower = _G.UnitPower
local UnitPowerMax = _G.UnitPowerMax

-- Sourced from BlizzardInterfaceResources/Resources/EnumerationTables.lua
local ALTERNATE_POWER_INDEX = Enum and Enum.PowerType.Alternate or ALTERNATE_POWER_INDEX or 10

local Update = function(self, event, unit, powerType)
	local AltPower = self.AltPower
	if (unit ~= self.unit) and (unit ~= self:GetRealUnit()) and (unit ~= "vehicle") then 
		return 
	end 

	-- We're only interested in alternate power here
	if ((event == "UNIT_POWER_UPDATE" or event == "UNIT_MAXPOWER") and (powerType ~= "ALTERNATE")) then 
		return 
	end 

	local barType, minPower, startInset, endInset, smooth, hideFromOthers, showOnRaid, opaqueSpark, opaqueFlash, anchorTop, powerName, powerTooltip = UnitAlternatePowerInfo(unit)

	if (not barType) or (event == "UNIT_POWER_BAR_HIDE") then 
		return AltPower:Hide()
	end 

	local power = UnitPower(unit, ALTERNATE_POWER_INDEX)
	local powermax = UnitPowerMax(unit, ALTERNATE_POWER_INDEX)

	AltPower:SetMinMaxValues(0, powermax) 
	AltPower:SetValue(power) 

	if AltPower.Value then
		if (power == 0 or powermax == 0) and (not AltPower.Value.showAtZero) then
			AltPower.Value:SetText(EMPTY)
		else
			if AltPower.Value.showDeficit then
				if AltPower.Value.showPercent then
					if AltPower.Value.showMaximum then
						AltPower.Value:SetFormattedText("%s / %s - %d%%", F.Short(powermax - power), F.Short(powermax), math_floor(power/powermax * 100))
					else
						AltPower.Value:SetFormattedText("%s / %d%%", F.Short(powermax - power), math_floor(power/powermax * 100))
					end
				else
					if AltPower.Value.showMaximum then
						AltPower.Value:SetFormattedText("%s / %s", F.Short(powermax - power), F.Short(powermax))
					else
						AltPower.Value:SetFormattedText("%s", F.Short(powermax - power))
					end
				end
			else
				if AltPower.Value.showPercent then
					if AltPower.Value.showMaximum then
						AltPower.Value:SetFormattedText("%s / %s - %d%%", F.Short(power), F.Short(powermax), math_floor(power/powermax * 100))
					else
						AltPower.Value:SetFormattedText("%s / %d%%", F.Short(power), math_floor(power/powermax * 100))
					end
				else
					if AltPower.Value.showMaximum then
						AltPower.Value:SetFormattedText("%s / %s", F.Short(power), F.Short(powermax))
					else
						AltPower.Value:SetFormattedText("%s", F.Short(power))
					end
				end
			end
		end
	end

	if (not AltPower:IsShown()) then 
		AltPower:Show()
	end 

	if AltPower.PostUpdate then
		return AltPower:PostUpdate(power, powermax)
	end		
end 

local Enable = function(self)
	local AltPower = self.AltPower
	if AltPower then 
		AltPower._owner = self

		self:RegisterEvent("UNIT_POWER_UPDATE", Update) 
		self:RegisterEvent("UNIT_MAXPOWER", Update) 
		self:RegisterEvent("UNIT_POWER_BAR_SHOW", Update)
		self:RegisterEvent("UNIT_POWER_BAR_HIDE", Update)
		self:RegisterEvent("PLAYER_ENTERING_WORLD", Update)

		return true
	end 
end

local Disable = function(self)
	local AltPower = self.AltPower
	if AltPower then 
		self:UnregisterEvent("UNIT_POWER_UPDATE", Update)
		self:UnregisterEvent("UNIT_MAXPOWER", Update)
		self:UnregisterEvent("UNIT_POWER_BAR_SHOW", Update)
		self:UnregisterEvent("UNIT_POWER_BAR_HIDE", Update)
		self:UnregisterEvent("PLAYER_ENTERING_WORLD", Update)
	end 
end

Handler:RegisterElement("AltPower", Enable, Disable, Update)
