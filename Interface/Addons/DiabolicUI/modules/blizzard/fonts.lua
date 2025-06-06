local ADDON, Engine = ...
local Module = Engine:NewModule("Blizzard: Fonts")

local gameLocale = Engine:GetGameLocale()
local isLatin = ({ enUS  = true, enGB = true, deDE = true, esES = true, esMX = true, frFR = true, itIT = true, ptBR = true, ptPT = true })[gameLocale]

-- Client version constants
local ENGINE_LEGION 	= Engine:IsBuild("Legion")
local ENGINE_WOD 		= Engine:IsBuild("WoD")

-- Sets up the module font lists
Module.SetUp = function(self)
	-- shortcuts to the fonts
	local config = self:GetDB("Fonts")
	self.fonts = {
		text_normal = config.fonts.text_normal.path,
		text_narrow = config.fonts.text_narrow.path,
		text_serif = config.fonts.text_serif.path,
		text_serif_italic = config.fonts.text_serif_italic.path,
		header_normal = config.fonts.header_normal.path,
		header_light = config.fonts.header_light.path,
		number = config.fonts.number.path,
		damage = config.fonts.damage.path
	}

	-- hash table to quickly tell us if font face supports the current locale
	local fonts = self.fonts
	self.canIUse = {
		[fonts.text_normal] = config.fonts.text_normal.locales[gameLocale], 
		[fonts.text_narrow] = config.fonts.text_narrow.locales[gameLocale],
		[fonts.text_serif] = config.fonts.text_serif.locales[gameLocale], 
		[fonts.text_serif_italic] = config.fonts.text_serif_italic.locales[gameLocale], 
		[fonts.header_normal] = config.fonts.header_normal.locales[gameLocale], 
		[fonts.header_light] = config.fonts.header_light.locales[gameLocale], 
		[fonts.number] = config.fonts.number.locales[gameLocale], 
		[fonts.damage] = config.fonts.damage.locales[gameLocale]
	}

	self.hasReplacement = {}
	if ENGINE_LEGION then
		for fontID in pairs(config.fonts) do
			local localeTable = config.fonts[fontID]
			if localeTable.replacements then
				for locale, path in pairs(localeTable.replacements) do
					if (locale == gameLocale) then
						self.hasReplacement[fonts[fontID]] = path
					end
				end
			end
		end
	end

end

-- Changes the fonts rendered by the game engine 
-- (These are the fonts rendered directly in the 3D world)
Module.SetGameEngineFonts = function(self)
	local canIUse = self.canIUse
	local fonts = self.fonts

	-- game engine fonts
	-- *These will only be updated when the user
	-- relogs into the game from the character selection screen, 
	-- not when simply reloading the user interface!
	if canIUse[fonts.header_light] then 
		UNIT_NAME_FONT = fonts.header_light 

		-- the following need the string to be the global name of a fontobject. weird. 
		if ENGINE_WOD then
			NAMEPLATE_FONT = "GameFontWhite" -- 12
			NAMEPLATE_SPELLCAST_FONT = "GameFontWhiteTiny" -- 9
			self:SetFont(GameFontWhite, fonts.header_light)

		else 
			NAMEPLATE_FONT = fonts.header_light
		end
	end
	
	-- Legion features much nicer and smoother damage, 
	-- so we should just leave that as it is. 
	if not ENGINE_LEGION then
		if canIUse[fonts.damage] then 
			DAMAGE_TEXT_FONT = fonts.damage 
		end
	end
	
	if canIUse[fonts.text_normal] then 
		STANDARD_TEXT_FONT = fonts.text_normal 
	end
	
	-- default values
	UIDROPDOWNMENU_DEFAULT_TEXT_HEIGHT = 14
	CHAT_FONT_HEIGHTS = { 12, 13, 14, 15, 16, 18, 20, 22 }
	
	if ENGINE_WOD then
		if gameLocale == "ruRU" then -- cyrillic/russian
			if canIUse[fonts.header_light] then
				UNIT_NAME_FONT_CYRILLIC = fonts.header_light
			end
		elseif gameLocale == "koKR" then -- korean
			if canIUse[fonts.header_light] then
				UNIT_NAME_FONT_KOREAN = fonts.header_light
			end
		elseif gameLocale == "zhTW" or gameLocale == "zhCN" then -- chinese
			if canIUse[fonts.header_light] then
				UNIT_NAME_FONT_CHINESE = fonts.header_light
			end
		elseif isLatin then -- roman/latin
			if canIUse[fonts.header_light] then
				UNIT_NAME_FONT_ROMAN = fonts.header_light
			end
		end	
	end
end

-- Change some of the Blizzard font objects to use the fonts we've chosen.
-- (These are the fonts rendered by the user interface's 2D engine.)
Module.SetFontObjects = function(self)
	local fonts = self.fonts
	
	self:SetFont(NumberFontNormal, fonts.number)

	self:SetFont(FriendsFont_Large, fonts.header_light)
	self:SetFont(GameFont_Gigantic, fonts.header_light) -- not present in WotLK
	self:SetFont(ChatBubbleFont, fonts.text_normal) -- not present in WotLK...?
	self:SetFont(FriendsFont_UserText, fonts.header_light)
	self:SetFont(QuestFont_Large, fonts.header_normal, 14, "", 0, 0, 0) -- 15
	self:SetFont(QuestFont_Shadow_Huge, fonts.header_normal, 16, "", 0, 0, 0) -- 18
	self:SetFont(QuestFont_Super_Huge, fonts.header_light, 18, "", 0, 0, 0) -- 24 garrison mission list -- not present in WotLK
	self:SetFont(DestinyFontLarge, fonts.header_normal) -- 18 -- not present in WotLK
	self:SetFont(DestinyFontHuge, fonts.header_light) -- 32 -- not present in WotLK
	self:SetFont(CoreAbilityFont, fonts.header_light) -- 32 -- not present in WotLK
	self:SetFont(QuestFont_Shadow_Small, fonts.header_normal, nil, "", 0, 0, 0) -- 14 -- not present in WotLK
	self:SetFont(MailFont_Large, fonts.header_normal, nil, "", 0, 0, 0) -- 15
	
	-- floating combat text
	-- Legion features much nicer and smoother damage, 
	-- so we should just leave that as it is. 
	if not ENGINE_LEGION then
		self:SetFont(CombatTextFont, fonts.damage, 100, "", -2.5, -2.5, .35) 
	end

	-- chat font
	-- *Choosing not to override this, as the default chat fonts are fairly good 
	--  and Warcraft/Diablo-looking enough as it is. One of the better Blizzard choices. 
	self:SetFont(ChatFontNormal, nil, nil, "", -.75, -.75, 1)
	
end

Module.SetFont = function(self, fontObject, font, size, style, shadowX, shadowY, shadowA, r, g, b, shadowR, shadowG, shadowB)
	-- simple copout for non-existing fontobjects
	if not fontObject then
		return
	end
	local oldFont, oldSize, oldStyle  = fontObject:GetFont()

	if not font then
		font = oldFont
	end

	if not size then
		size = oldSize
	end

	-- forcefully keep the outlines thin
	if not style then
		style = (oldStyle == "OUTLINE") and "THINOUTLINE" or oldStyle 
	end

	-- don't change the font face if it doesn't support the current locale
	--fontObject:SetFont(self.canIUse[font] and font or self.hasReplacement[font] or oldFont, size, style) 
	if self.canIUse[font] then
		fontObject:SetFont(font, size, style) 
	elseif self.hasReplacement[font] then
		fontObject:SetFont(self.hasReplacement[font], size, style) 
	else
		fontObject:SetFont(oldFont, size, style) 
	end
	if shadowX and shadowY then
		fontObject:SetShadowOffset(shadowX, shadowY)
		fontObject:SetShadowColor(shadowR or 0, shadowG or 0, shadowB or 0, shadowA or 1)
	end
	
	if r and g and b then
		fontObject:SetTextColor(r, g, b)
	end
	
	return fontObject	
end

Module.HookCombatText = function(self)
	-- combat text
	COMBAT_TEXT_HEIGHT = 16
	COMBAT_TEXT_CRIT_MAXHEIGHT = 16
	COMBAT_TEXT_CRIT_MINHEIGHT = 16
	COMBAT_TEXT_SCROLLSPEED = 3

	hooksecurefunc("CombatText_UpdateDisplayedMessages", function() 
		--if COMBAT_TEXT_FLOAT_MODE == "1" then
		--	COMBAT_TEXT_LOCATIONS.startY = 484
		--	COMBAT_TEXT_LOCATIONS.endY = 709
		--end
		COMBAT_TEXT_LOCATIONS.startY = 220
		COMBAT_TEXT_LOCATIONS.endY = 440
	end)
end

-- Change the font object of our own custom fonts,
-- since not all our fonts support all the localized regions. 
Module.SetEngineFontObjects = function(self)
	-- Our replacements are only for Asian realms (zhCN, zhTW, koKR), 
	-- and our fonts are stored in the Microsoft .otf format
	-- which isn't supported in older versions of WoW. 
	if not ENGINE_LEGION then
		return
	end

	local config = self:GetDB("Fonts")
	local fontObjects = config.fontObjects
	for group in pairs(fontObjects) do
		local replacement = fontObjects[group].replacements[gameLocale]
		if replacement then
			for _,objectName in ipairs(fontObjects[group].objects) do
				local fontObject = _G[objectName]
				if fontObject then
					local font, size, style = fontObject:GetFont()
					fontObject:SetFont(replacement, size, style)
				end
			end
		end
	end
end


-- Fonts (especially game engine fonts) need to be set very early in the loading process, 
-- so for this specific module we'll bypass the normal loading order, and just fire away!
Module:SetUp()
Module:SetGameEngineFonts()
Module:SetFontObjects()
Module:SetEngineFontObjects()

if IsAddOnLoaded("Blizzard_CombatText") then
	Module:HookCombatText()
else
	Module.ADDON_LOADED = function(self, event, addon, ...)
		if addon == "Blizzard_CombatText" then
			self:HookCombatText()
			self:UnregisterEvent("ADDON_LOADED")
		end
	end
	Module:RegisterEvent("ADDON_LOADED")
end
