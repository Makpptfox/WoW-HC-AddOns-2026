-- this lua file is mostly used for initialization

TheoryCraft_AddonName = "TheoryCraftClassic"
TheoryCraft_FormattedName = TheoryCraft_AddonName.."|cff00aeff(Redux)|r"
TheoryCraft_Version   = GetAddOnMetadata(TheoryCraft_AddonName, "Version") -- Read from TOC file

TheoryCraft_TooltipData = {}
TheoryCraft_Data = {}
TheoryCraft_Data.armormult = 1
TheoryCraft_Data.armormultinternal = 1
TheoryCraft_Data.Target = {}

TheoryCraft_Data.BaseData = {}
TheoryCraft_Data.BaseData["Allcritbonus"] = 0.5
TheoryCraft_Data.BaseData["Allthreat"] = 1
TheoryCraft_Data.BaseData["Allmodifier"] = 1
TheoryCraft_Data.BaseData["AllUpFrontmodifier"] = 1
TheoryCraft_Data.BaseData["Allbaseincrease"] = 1
TheoryCraft_Data.BaseData["AllUpFrontbaseincrease"] = 1
TheoryCraft_Data.BaseData["manacostall"] = 1
TheoryCraft_Data.BaseData["Huntercritbonus"] = 0.5
TheoryCraft_Data.BaseData["Rangedcritbonus"] = 1
TheoryCraft_Data.BaseData["Rangedmodifier"] = 1
TheoryCraft_Data.BaseData["Rangedbaseincrease"] = 1
TheoryCraft_Data.BaseData["Meleecritbonus"] = 1
TheoryCraft_Data.BaseData["Meleemodifier"] = 1
TheoryCraft_Data.BaseData["Meleebaseincrease"] = 1


TheoryCraft_Data.Stats = {}

TheoryCraft_UpdatedButtons = {}

-- experimental support for bartender 4
if Bartender4 and LibStub then 
	local lib, oldversion = LibStub:NewLibrary("TheoryCraftClassic", 1)
	local LAB = LibStub("LibActionButton-1.0", true)
	local CBH = LibStub("CallbackHandler-1.0")
	if (LAB and CBH) then
		lib.callbacks = lib.callbacks or CBH:New(lib)
		LAB.RegisterCallback(lib, "OnButtonUpdate", function(event, self)
			if self._state_type == "action" then
				TheoryCraft_ButtonUpdate(self) -- bartender
			end
		end)
		LAB.RegisterCallback(lib, "OnButtonCreated", function(event, self)
			TheoryCraft_SetUpButton(self:GetName(), "Normal")
		end)
	end
end

-- recursively nil every value in the table
function TheoryCraft_DeleteTable(tab1)
	for k, v in pairs(tab1) do
		if type(v) == "table" then
			TheoryCraft_DeleteTable(v)
		else
			tab1[k] = nil
		end
	end
end

local function round(arg1, decplaces)
	if (decplaces == nil) then decplaces = 0 end
	if arg1 == nil then arg1 = 0 end
	return string.format ("%."..decplaces.."f", arg1)
end

-- This was apparently some kinda monitoring function to parse data about critical strike chances
-- because some sorta internal wow data wasn't yet known.
--[[
function TheoryCraft_WatchCritRate(arg1)
	local _, _, hit = strfind(arg1, "Your (.+) heals ")
	local _, _, crit= strfind(arg1, "Your (.+) critically")
	if (not hit) and (not crit) then return end
	if crit then hit = crit end
	local foundcc
	for k = 1,20 do
		if TheoryCraft_TooltipData[hit.."("..k..")"] then
			foundcc = TheoryCraft_TooltipData[ TheoryCraft_TooltipData[hit.."("..k..")"] ]["crithealchance"]
		end
	end
	if foundcc == nil then
		return
	end
	if not TheoryCraft_Settings["critchancedata"] then
		TheoryCraft_Settings["critchancedata"] = {}
	end
	if (TheoryCraft_Data.outfit) and (TheoryCraft_Data.outfit ~= -1) and (TheoryCraft_Data.outfit ~= 1) then
		return
	end
	local _, tmp2 = UnitStat("player", 4)
	local tmp = tmp2..":"..(foundcc-TheoryCraft_Data.Stats["critchance"])
	if not TheoryCraft_Settings["critchancedata"][tmp] then
		TheoryCraft_Settings["critchancedata"][tmp] = {}
		TheoryCraft_Settings["critchancedata"][tmp].casts = 0
		TheoryCraft_Settings["critchancedata"][tmp].crits = 0
	end
	TheoryCraft_Settings["critchancedata"][tmp].casts = TheoryCraft_Settings["critchancedata"][tmp].casts+1
	if crit then
		TheoryCraft_Settings["critchancedata"][tmp].crits = TheoryCraft_Settings["critchancedata"][tmp].crits+1
	end
	if class == "PALADIN" then
		if (TheoryCraft_Settings["critchancedata"][tmp].casts == 15000) or ((TheoryCraft_Settings["critchancedata"][tmp].casts > 15000) and (math.floor(TheoryCraft_Settings["critchancedata"][tmp].casts/100) == TheoryCraft_Settings["critchancedata"][tmp].casts/100)) then
			if TheoryCraft_Settings["hidecritdata"] then return end
			local cc = (TheoryCraft_Settings["critchancedata"][tmp].crits/TheoryCraft_Settings["critchancedata"][tmp].casts-(foundcc-TheoryCraft_Data.Stats["critchance"])/100)*100
			-- Some kinda messaging to post your critical chance over how many casts you've made for data collection purposes.
			-- I don't think this matters anymore.
		end
	end
end
--]]

function TheoryCraft_UpdateArmor()
	local oldmit = TheoryCraft_Data.armormultinternal
	TheoryCraft_Data.armormultinternal = 1
	local armor
	if UnitIsPlayer("target") then
		if (TheoryCraft_MitigationPlayers[UnitName("target")]) and (TheoryCraft_MitigationPlayers[UnitName("target")][1]) then
			armor = TheoryCraft_MitigationPlayers[UnitName("target")][1]-TheoryCraft_GetStat("Sunder")
		else
			local unitlevel = UnitLevel("target")
			if unitlevel == -1 then unitlevel = 60 end
			local uc = UnitClass("target")
			if UnitClass("target") == nil then
				return
			end
			for i = 0,60 do
				if (TheoryCraft_MitigationPlayers[uc..":"..unitlevel+i]) and (TheoryCraft_MitigationPlayers[uc..":"..unitlevel+i][1]) then
					armor = TheoryCraft_MitigationPlayers[uc..":"..unitlevel+i][1]-TheoryCraft_GetStat("Sunder")
					break
				end
				if (TheoryCraft_MitigationPlayers[uc..":"..unitlevel-i]) and (TheoryCraft_MitigationPlayers[uc..":"..unitlevel-i][1]) then
					armor = TheoryCraft_MitigationPlayers[uc..":"..unitlevel-i][1]-TheoryCraft_GetStat("Sunder")
					break
				end
			end
		end
	else
		if (TheoryCraft_MitigationMobs[UnitName("target")]) and (TheoryCraft_MitigationMobs[UnitName("target")][1]) then
			armor = TheoryCraft_MitigationMobs[UnitName("target")][1]-TheoryCraft_GetStat("Sunder")
		end
	end
	if armor then
		if armor < 0 then armor = 0 end
		TheoryCraft_Data.armormultinternal = 1 - (armor / (85 * UnitLevel("player") + 400 + armor))
	end
	if TheoryCraft_Data.armormultinternal ~= oldmit then
		TheoryCraft_DeleteTable(TheoryCraft_UpdatedButtons)
	end
end


function TheoryCraft_UpdateTarget(dontgen)
	local old = {}
	TCUtils.MergeIntoTable(TheoryCraft_Data.Target, old)
	TheoryCraft_DeleteTable(TheoryCraft_Data.Target)

	-- REM: the target is a localized string
	local racetar = UnitCreatureType("target")
	if (TCUtils.RACE == "Troll") and (racetar == TheoryCraft_Locale.ID_Beast) then
		TheoryCraft_Data.Target["Allbaseincrease"] = 0.05
		TheoryCraft_Data.Target["Rangedmodifier"]  = 0.05
		TheoryCraft_Data.Target["Meleemodifier"]   = 0.05
	end
	local slaying = 0
	if (racetar == TheoryCraft_Locale.ID_Humanoid) then
		slaying = TheoryCraft_GetStat("humanoidslaying")
	end
	if (racetar == TheoryCraft_Locale.ID_Beast) or (racetar == TheoryCraft_Locale.ID_Giant) or (racetar == TheoryCraft_Locale.ID_Dragonkin) then
		slaying = TheoryCraft_GetStat("monsterslaying")
	end
	if racetar then
		TheoryCraft_Data.Target["All"] = TheoryCraft_GetStat(racetar)
	end

	TheoryCraft_Data.Target["Allbaseincrease"] = (TheoryCraft_Data.Target["Allbaseincrease"] or 0)+slaying
	TheoryCraft_Data.Target["Rangedmodifier"] = (TheoryCraft_Data.Target["Rangedmodifier"] or 0)+slaying
	TheoryCraft_Data.Target["Meleemodifier"] = (TheoryCraft_Data.Target["Meleemodifier"] or 0)+slaying
	TheoryCraft_Data.Target["Allcritbonus"] = slaying
	TheoryCraft_Data.Target["Rangedcritbonus"] = slaying
	TheoryCraft_Data.Target["Meleecritbonus"] = slaying

	if (dontgen == nil) and (TheoryCraft_IsDifferent(old, TheoryCraft_Data.Target)) then
		TheoryCraft_GenerateAll() -- update target
	end
	if TheoryCraft_Settings["dontresist"] then
		TheoryCraft_DeleteTable(TheoryCraft_UpdatedButtons)
	end
	TheoryCraft_UpdateArmor()
end

--- IsDifferent, returns true if the two tables are different else nil ---

function TheoryCraft_IsDifferent(oldtable, newtable)
	if newtable == nil then return true end
	if oldtable == nil then return true end
	for k,v in pairs(oldtable) do
		if type(v) == "table" then
			if TheoryCraft_IsDifferent(v, newtable[k]) then
				return true
			end
		elseif newtable[k] ~= v then
			if not (((v == nil) and (newtable[k] == 0)) or ((newtable[k] == nil) and (v == 0))) then
				return true
			end
		end
	end
	for k,v in pairs(newtable) do
		if type(v) == "table" then
			if TheoryCraft_IsDifferent(v, oldtable[k]) then
				return true
			end
		elseif (oldtable[k] ~= v) then
			if not (((v == nil) and (oldtable[k] == 0)) or ((oldtable[k] == nil) and (v == 0))) then
				return true
			end
		end
	end
end

--- OnLoad ---

-- TODO: This should only set defaults if they are missing, not overwrite things that already exist.
local function SetDefaults()
	-- REM: SavedVariablesPerCharacter
	-- REM: When saving variables between game sessions, SavedVariables and SavedVariablesPerCharacter load after the last file. This overwrites any default values set earlier.
	
	TheoryCraft_Settings["dataversion"] = TheoryCraft_DataVersion -- So that we know if we need to reset the defaults again.

	-- Checkbox defaults
	TheoryCraft_Settings["embed"] = true
	TheoryCraft_Settings["combinedot"] = true
	TheoryCraft_Settings["procs"] = true
	TheoryCraft_Settings["healanddamage"] = true
	TheoryCraft_Settings["embedstyle1"] = true
	TheoryCraft_Settings["buttontext"] = true
	TheoryCraft_Settings["mitigation"] = true
	TheoryCraft_Settings["tryfirst"] = "averagedam"
	TheoryCraft_Settings["trysecond"] = "averagehealnocrit"
	TheoryCraft_Settings["tryfirstsfg"] = 0
	TheoryCraft_Settings["trysecondsfg"] = -1
	TheoryCraft_Settings["GenerateList"] = ""
	TheoryCraft_Settings["dontresist"] = true

	-- Resistances
	TheoryCraft_Settings["resistscores"] = {}
	TheoryCraft_Settings["resistscores"]["Arcane"] = 0
	TheoryCraft_Settings["resistscores"]["Fire"]   = 0
	TheoryCraft_Settings["resistscores"]["Nature"] = 0
	TheoryCraft_Settings["resistscores"]["Frost"]  = 0
	TheoryCraft_Settings["resistscores"]["Shadow"] = 0

	-- Button text values
	TheoryCraft_Settings["buttontextx"] = 0.5
	TheoryCraft_Settings["buttontexty"] = 0.5
	-- REM: these are stored as decimals between 0/1 because that is how SetTextColor expects values
	TheoryCraft_Settings["ColR"] = 1
	TheoryCraft_Settings["ColG"] = 1
	TheoryCraft_Settings["ColB"] = 1
	TheoryCraft_Settings["ColR2"] = 1
	TheoryCraft_Settings["ColG2"] = 1
	TheoryCraft_Settings["ColB2"] = 175/255
	TheoryCraft_Settings["FontSize"] = 12
	--TheoryCraft_Settings["FontPath"] = "Fonts\\ArialN.TTF"
end

-- Something to do with custom gear sets. Kill it for now.
-- Maybe use: frame:SetScript("OnHyperlinkClick", ChatFrame_OnHyperlinkShow)
--            or ChatFrame_OnHyperlinkShow() 
--[[
function TheoryCraft_SetItemRef(link, text, button)
	if (IsAltKeyDown()) and (string.sub(link, 1, 4) == "item") then
		TheoryCraft_AddToCustom(link)
		TheoryCraft_UpdateGear(true) -- irrelevant
		TheoryCraft_LoadStats() -- irrelevant
		TheoryCraft_GenerateAll() -- irrelevant
	else
		TheoryCraft_Data["SetItemRef"](link, text, button)
	end
end
--]]

function TheoryCraft_OnLoad(self)
	-- Register the persistent events
	self:RegisterEvent("ADDON_LOADED")
	self:RegisterEvent("PLAYER_LOGIN")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("PLAYER_LEAVING_WORLD")

	-- For debugging purposes
	--self:RegisterEvent("LUA_WARNING")

	-- NOTE: when ADDON_LOADED fires, these will be overwritten by the data from disk.
	TheoryCraft_MitigationMobs    = {}
	TheoryCraft_MitigationPlayers = {}
	TheoryCraft_SetBonuses        = {}
	TheoryCraft_Settings          = {}

	-- REM: allows frame to be closed with ESC key.
	tinsert(UISpecialFrames, "TheoryCraft")   -- eg table.insert
	self:SetClampedToScreen(true)

	-- Register the slash commands
	SLASH_TheoryCraft1 = "/theorycraft"
	SLASH_TheoryCraft2 = "/tc"
	SlashCmdList["TheoryCraft"] = TheoryCraft_Command

	-- Convert "Shadow" into "[Ss][Hh][Aa][Dd][Oo][Ww]". Luas-poormans case-insensitive match.
	local s
	local function bothcase(a)
		return "["..string.upper(a)..string.lower(a).."]"
	end
	for k, v in pairs(TheoryCraft_PrimarySchools) do
		if (type(v) == "table") and v.text then
			v.text = string.gsub(v.text, "(.)", bothcase)
		end
	end

	-- Expand TheoryCraft_EquipEveryLine.
	-- anything with "schoolname" should instead be multiple lines, 1 per spell school
	local i = 1
	local s2 = 1
	local i3 = 1
	local newones = {}
	while (TheoryCraft_EquipEveryLine[i]) do
		s2 = TheoryCraft_EquipEveryLine[i].text
		if (strfind(TheoryCraft_EquipEveryLine[i].text, "schoolname")) then
			local i2 = 1
			--local type = 1
			local s3 = 1
			while TheoryCraft_PrimarySchools[i2] do
				s3 = s2
				
				s3 = string.gsub(s2, "schoolname", TheoryCraft_PrimarySchools[i2].text)
				if i2 == 1 then
					TheoryCraft_EquipEveryLine[i].text = s3
					TheoryCraft_EquipEveryLine[i].type = TheoryCraft_PrimarySchools[i2].name
				else
					newones[i3] = {}
					newones[i3].me = TheoryCraft_EquipEveryLine[i].me
					newones[i3].amount = TheoryCraft_EquipEveryLine[i].amount
					newones[i3].text = s3
					newones[i3].type = TheoryCraft_PrimarySchools[i2].name
					i3 = i3 + 1
				end
				i2 = i2 + 1
			end
		end
		i = i + 1
	end

	i2 = 1
	-- Append any newones to the end of the EquipEveryLine table
	while newones[i2] do
		TheoryCraft_EquipEveryLine[i] = {}
		TheoryCraft_EquipEveryLine[i].me = newones[i2].me
		TheoryCraft_EquipEveryLine[i].amount = newones[i2].amount
		TheoryCraft_EquipEveryLine[i].text = newones[i2].text
		TheoryCraft_EquipEveryLine[i].type = newones[i2].type
		i2 = i2 + 1
		i = i + 1
	end

	-- Expand TheoryCraft_EquipEveryRight.
	-- anything with "schoolname" should instead be multiple lines, 1 per spell school
	local i = 1
	local s2 = 1
	local i3 = 1
	local newones = {}
	while (TheoryCraft_EquipEveryRight[i]) do
		s2 = TheoryCraft_EquipEveryRight[i].text
		if (strfind(TheoryCraft_EquipEveryRight[i].text, "schoolname")) then
			local i2 = 1
			--local type = 1
			local s3 = 1
			while TheoryCraft_PrimarySchools[i2] do
				s3 = s2
				s3 = string.gsub(s2, "schoolname", TheoryCraft_PrimarySchools[i2].text)
				if i2 == 1 then
					TheoryCraft_EquipEveryRight[i].text = s3
					TheoryCraft_EquipEveryRight[i].type = TheoryCraft_PrimarySchools[i2].name
				else
					newones[i3] = {}
					newones[i3].me = TheoryCraft_EquipEveryRight[i].me
					newones[i3].amount = TheoryCraft_EquipEveryRight[i].amount
					newones[i3].text = s3
					newones[i3].type = TheoryCraft_PrimarySchools[i2].name
					i3 = i3 + 1
				end
				i2 = i2 + 1
			end
		end
		i = i + 1
	end
	i2 = 1
	while newones[i2] do
		TheoryCraft_EquipEveryRight[i] = {}
		TheoryCraft_EquipEveryRight[i].me = newones[i2].me
		TheoryCraft_EquipEveryRight[i].amount = newones[i2].amount
		TheoryCraft_EquipEveryRight[i].text = newones[i2].text
		TheoryCraft_EquipEveryRight[i].type = newones[i2].type
		i2 = i2 + 1
		i = i + 1
	end

	-- Expand TheoryCraft_Equips.
	-- anything with "schoolname" should instead be multiple lines, 1 per spell school
	local i = 1
	local s2 = 1
	local i3 = 1
	local newones = {}
	while (TheoryCraft_Equips[i]) do
		s2 = TheoryCraft_Equips[i].text
		if (strfind(TheoryCraft_Equips[i].text, "schoolname")) then
			local i2 = 1
			--local type = 1
			local s3 = 1
			while TheoryCraft_PrimarySchools[i2] do
				s3 = string.gsub(s2, "schoolname", TheoryCraft_PrimarySchools[i2].text)
				if i2 == 1 then
					TheoryCraft_Equips[i].text = s3
					TheoryCraft_Equips[i].type = TheoryCraft_PrimarySchools[i2].name
				else
					newones[i3] = {}
					newones[i3].me = TheoryCraft_Equips[i].me
					newones[i3].amount = TheoryCraft_Equips[i].amount
					newones[i3].text = s3
					newones[i3].type = TheoryCraft_PrimarySchools[i2].name
					i3 = i3 + 1
				end
				i2 = i2 + 1
			end
		end
		i = i + 1
	end
	i2 = 1
	while newones[i2] do
		TheoryCraft_Equips[i] = {}
		TheoryCraft_Equips[i].me = newones[i2].me
		TheoryCraft_Equips[i].amount = newones[i2].amount
		TheoryCraft_Equips[i].text = newones[i2].text
		TheoryCraft_Equips[i].type = newones[i2].type
		i2 = i2 + 1
		i = i + 1
	end


	local class = TCUtils.CLASS

	i = 1
	-- in gamedata
	while TheoryCraft_Spells[class][i] do
		if TheoryCraft_Spells[class][i].id then
			-- Add these entries into MinMax{}
			if TheoryCraft_Spells[class][i].id == "Aimed Shot" then
				TheoryCraft_Locale.MinMax.aimedshotname = TheoryCraft_Locale.SpellTranslator[ TheoryCraft_Spells[class][i].id ]
			elseif TheoryCraft_Spells[class][i].id == "Multi-Shot" then
				TheoryCraft_Locale.MinMax.multishotname = TheoryCraft_Locale.SpellTranslator[ TheoryCraft_Spells[class][i].id ]
			elseif TheoryCraft_Spells[class][i].id == "Arcane Shot" then
				TheoryCraft_Locale.MinMax.arcaneshotname = TheoryCraft_Locale.SpellTranslator[ TheoryCraft_Spells[class][i].id ]
			elseif TheoryCraft_Spells[class][i].id == "Auto Shot" then
				TheoryCraft_Locale.MinMax.autoshotname = TheoryCraft_Locale.SpellTranslator[ TheoryCraft_Spells[class][i].id ]
			end

			-- Add a localized attribute "name" onto the spell data.
			if TheoryCraft_Locale.SpellTranslator[TheoryCraft_Spells[class][i].id] then
				TheoryCraft_Spells[class][i].name = TheoryCraft_Locale.SpellTranslator[ TheoryCraft_Spells[class][i].id ]
			else
				-- use "id" as a default "name"
				print("TheoryCraft error, no translation found for: "..TheoryCraft_Spells[class][i].id)
				TheoryCraft_Spells[class][i].name = TheoryCraft_Spells[class][i].id
			end
		end
		i = i + 1
	end

	print(TheoryCraft_FormattedName, TheoryCraft_Version, TheoryCraft_Locale.LoadText)
end

--- OnShow ---

-- REM: this is for tooltip only
-- NOTE: this is not yet restricted to action bar tooltips, this applies to everything. Players, npcs, campfires, chat buttons... etc.
function TheoryCraft_OnTooltipShow()
	--print('TheoryCraft_OnTooltipShow')
   	TheoryCraft_AddTooltipInfo(GameTooltip)
end

--[[
function TheoryCraft_OnUpdate()
	print('TheoryCraft_OnUpdate')
   	TheoryCraft_AddTooltipInfo(GameTooltip)
	--if (TheoryCraft_OnTooltipShow_Save) then
	--   	TheoryCraft_OnTooltipShow_Save()
	--end
end
--]]

-- (un)register events TC cares about
local function register_events(self, unregister)
	-- Events to be registered and unregistered as the player hits loading screens
	local event_list = {
		"UNIT_AURA",
		"PLAYER_EQUIPMENT_CHANGED",
		"PLAYER_TARGET_CHANGED",
		"UNIT_MANA",
		"UNIT_SPELLCAST_SUCCEEDED",
		"UNIT_SPELLCAST_START",
		"CHARACTER_POINTS_CHANGED",
		"UNIT_POWER_UPDATE",
		"COMBAT_LOG_EVENT_UNFILTERED",
		"PLAYER_REGEN_ENABLED",
		"ACTIONBAR_SLOT_CHANGED"
	}
	for i = 1, #event_list, 1 do
		if unregister then
			self:UnregisterEvent(event_list[i])
		else
			self:RegisterEvent(event_list[i])
		end
	end
end


-- Master list of events: https://wowpedia.fandom.com/wiki/Events
-- REM: Normal sequence is:  ADDON_LOADED => PLAYER_LOGIN => PLAYER_ENTERING_WORLD
-- NOTE: VARIABLES_LOADED fires after ALL addon's saved variables have loaded AND after blizzard's cache of account keybinds & macros have synced from the server.
--       therefore may happen after PLAYER_ENTERING_WORLD
function TheoryCraft_OnEvent(self, event, ...)
	-- REM: automatic "..." => "arg{}" is only in lua 5.2
	local arg={...}

	--print(event)

	local UIMem = gcinfo()

	-- Fires each time an individual addon's files and saved_variables have finished loading.
	if event == "ADDON_LOADED" then
		-- arg[1] == name of addon
		--print ('Addon Loaded: ', arg[1])
		-- If its some other addon, nothing to do here.
		if arg[1] ~= TheoryCraft_AddonName then
			return
		end

		--print('TheoryCraft Addon Loaded')

		-- Only process this event once
		self:UnregisterEvent(event)

		-- NOTE: disabled for now.
		--TheoryCraft_Data["SetItemRef"] = SetItemRef
		--SetItemRef = TheoryCraft_SetItemRef

		-- NOTE: OnShow is for ANY tooltip in the world, not just spells
		GameTooltip:HookScript("OnShow", TheoryCraft_OnTooltipShow)
		GameTooltip:HookScript("OnTooltipSetSpell", TheoryCraft_OnTooltipShow)
		-- NOTE: OnTooltipSetSpell is only for spell tooltips, but for some reason is spammed when moused over spells that cannot be moved. (stance bar & talent tree)
		-- TODO: I guess OnTooltip<function> hooks, the function names are probably from this list: https://wowpedia.fandom.com/wiki/Widget_API#GameTooltip
		-- NOTE: this is another possible option, but has its own problems.
		--     hooksecurefunc(GameTooltip, 'SetTalent', function(self, spellID, isInspect, talentGroup) end)

		--GameTooltip:HookScript("OnUpdate", TheoryCraft_OnUpdate)
		-- DO not use OnUpdate, this is spammed constantly (probably every frame?)
		-- abilities that cannot currently be cast, spam nil update events, whereas allowed abilities spam non-nil update events.

		-- TODO: this should run an upgrade script if it is not nil
		if (TheoryCraft_Settings["dataversion"] ~= TheoryCraft_DataVersion) then
			SetDefaults()
		end

		-- Restore checkbox checked status from settings
		TheoryCraft_InitCheckboxState()

		-- Restore the values from settings into the ButtonText Config UI
		TheoryCraft_InitButtonTextOpts()

		-- Adds the text FontString to each action button. (NOTE: apparently doesn't need to wait for any later event)
		TheoryCraft_AddButtonText()

		-- NOTE: this is only intended as a notification, not to actually change what is or is not initialized
		if TheoryCraft_Settings["off"] then
			print("TheoryCraft is currently switched off, use '/tc on' to enabled")
		end

	-- Triggered immediately before PLAYER_ENTERING_WORLD on login and UI Reload, but NOT when entering/leaving instances.
	-- I.E. this only happens once
	elseif event == "PLAYER_LOGIN" then

		--[[
		if _G['Bartender4'] ~= nil then
			for i = 1, 120 do TheoryCraft_SetUpButton("BT4Button"..i, "Normal") end
		end
		]]--

		-- Do this ASAP (many other things depend on this data)
		TheoryCraft_UpdateTalents(true) -- player login

		-- Wait 2 seconds after LOGIN to give a chance for stats/gear/spells etc to be properly loaded and become available for reading
		C_Timer.After(2, function()
			-- NOTE: I think this order of initialization is pretty well fixed.
			TheoryCraft_UpdateGear(true)    -- player login
			TheoryCraft_UpdatePlayerBuffs(true)
			TheoryCraft_UpdateTargetBuffs(true)
			TheoryCraft_LoadStats('player login') -- REM: must be after UpdateGear
			-- TheoryCraft_GenerateAll()
			TheoryCraft_UpdateAllButtonText('login')
		end) -- C_Timer

	-- Fired when the player logs in, /reloads the UI, or zones between map instances, basically whenever the loading screen appears. 
	-- args: isLogin(bool), isReload(bool)
	elseif event == "PLAYER_ENTERING_WORLD" then

		register_events(self)

	-- Fires whenever a loading screen turns on. (not necessarily on logout)
	elseif event == "PLAYER_LEAVING_WORLD" then
		-- Unregister the events
		register_events(self, true)

	elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
		TheoryCraft_ParseCombat(self, event)

	-- TODO: this event no longer exists. Replaced with "COMBAT_LOG_EVENT" in 2.4.0
	--       but its junk anyways, so who cares
	--elseif event == "CHAT_MSG_SPELL_SELF_BUFF" then
	--	TheoryCraft_WatchCritRate(arg[1])

	elseif event == "PLAYER_EQUIPMENT_CHANGED" then
		-- REM: arg[1] is equpimentSlotID, arg[2] is true when slot is now empty, false otherwise
		TheoryCraft_UpdateGear()

	-- This occurs when you are not on the hate list of any NPC, or a few seconds after the latest pvp attack that you were involved with. 
	elseif event == "PLAYER_REGEN_ENABLED" then
		-- If we had previously called UpdateGear but were in combat a the time...
		if TheoryCraft_Data.regenaftercombat then
			TheoryCraft_Data.regenaftercombat = nil
			-- ... now is the time to go ahead and UpdateGear
			TheoryCraft_UpdateGear(nil, true)
		end

	-- arg[1] == player, pet, NPC, or mob
	-- NOTE: we care about both "player" and "target"
	elseif event == "UNIT_AURA" then
		if (arg[1] == "player") then
			TheoryCraft_UpdatePlayerBuffs() -- REM: calls LoadStats
		end

	-- Fired when a unit (player) starts or finishes casting a spell. Use these
	-- to update action button texts immediately so damage indicators reflect
	-- temporary procs / cost changes right after casting.
	elseif (event == "UNIT_SPELLCAST_SUCCEEDED" or event == "UNIT_SPELLCAST_START") and (arg[1] == "player") then
		-- Clear cached button calculations so they will be recomputed
		TheoryCraft_DeleteTable(TheoryCraft_UpdatedButtons)
		-- Immediately refresh visible action bar text
		TheoryCraft_UpdateActionBarText()

	-- Fired when the player's available talent points change. 
	-- arg[1] == change(int) -- -1 for spent, and +1 for leveled up
	elseif event == "CHARACTER_POINTS_CHANGED" then
		TheoryCraft_UpdateTalents()

	elseif event == "PLAYER_TARGET_CHANGED" then
		TheoryCraft_UpdateTarget()
		TheoryCraft_UpdateTargetBuffs()
		TheoryCraft_UpdateAllButtonText('target changed')

	-- Fired when a unit's current power (mana, rage, energy) changes
	--   A spell is cast which changes the unit's power.
	--   The unit reaches full power.
	--   While the unit's power is naturally regenerating or decaying, this event will only fire once every two seconds.
	--   full list of power types: https://wowpedia.fandom.com/wiki/Enum.PowerType
	-- arg[1] == unitID(string), arg[2] == powerType(string)
	elseif event == "UNIT_POWER_UPDATE" then

	elseif (event == "UNIT_MANA") and (arg[1] == "player") then
		if TCUtils.StanceFormName('UNIT_MANA') == 'cat' then
			TheoryCraft_DeleteTable(TheoryCraft_UpdatedButtons)
		end
		-- when either primary or secondary dropdown options are configured for:
		--   maxoomhealremaining  - Total Healing (left)
		--   maxoomdamremaining   - Total Damage (left)
		--   spellcasts           - Spellcasts remaining
		if ((string.find(TheoryCraft_Settings["tryfirst"], "remaining")) or (string.find(TheoryCraft_Settings["trysecond"], "remaining"))) or
		   ((TheoryCraft_Settings["tryfirst"] == "spellcasts") or (TheoryCraft_Settings["trysecond"] == "spellcasts")) then
			TheoryCraft_DeleteTable(TheoryCraft_UpdatedButtons)
		end

	-- arg[1] == action_bar_slot_number(int)   AND no other arguments.
	-- NOTE: this event has many many trigger conditions:
	--       - when a macro has its active spell updated (example, modifier keys, or mouse over targets)
	--       - when spells that have a reagent cost have their reagents quantity changed, or the reagent is moved in bags
	--       - when inventory items that are set to an actionbutton are updated in any way (quantity changes, moved around in bags, bought/sold)
	-- NOTE: this will fire a bunch of times any time the player loads through a loading screen that WASNOT /reload
	elseif event == "ACTIONBAR_SLOT_CHANGED" then
		local button = TheoryCraft_FindActionButton(arg[1])
		if button then
			TheoryCraft_ButtonUpdate(button, true)
		end

	-- TODO: this in theory should work, but I don't know what triggers it at the moment.
	--elseif event == "LUA_WARNING" then
	--	print("a LUA_WARNING has occurred: ", arg[1], arg[2]) -- arg[2] may be the actual warning text, lets not print it for now.
	end

	if TheoryCraft_Settings["showmem"] then
		print(event..": "..gcinfo() - UIMem)
	end
end

-- This is the mouse over for detailed description of each checkbox.
function TheoryCraft_CheckBoxShowDescription(self)
	local name = self:GetName()
	name = string.sub(name, 12)
	if (TheoryCraft_CheckButtons[name] == nil) then
		return
	end

	local class = TCUtils.CLASS

	local text = 1
	if (TheoryCraft_CheckButtons[name].descriptionmelee) and ((class == "ROGUE") or (class == "WARRIOR")) then
		text = TheoryCraft_CheckButtons[name].descriptionmelee
	else
		text = TheoryCraft_CheckButtons[name].description
	end
	if string.find(text, "$cr") then
		text = string.gsub(text, "$cr", round(TheoryCraft_intpercrit(), 2))
	end
	-- Use the default GameTooltip to show the popup descriptions for UI checkboxes.
	GameTooltip_SetDefaultAnchor( GameTooltip, UIParent )
	if TheoryCraft_CheckButtons[name].tooltiptitle then
		GameTooltip:AddLine(TheoryCraft_CheckButtons[name].tooltiptitle, 1,1,1)
	else
		GameTooltip:AddLine(TheoryCraft_CheckButtons[name].short, 1,1,1)
	end
	GameTooltip:AddLine(text, 1,1,0)
	GameTooltip:Show()
end

function TheoryCraft_SetCheckBox(variablename)
	if _G["TheoryCraft"..variablename] then
		_G["TheoryCraft"..variablename]:SetChecked(TheoryCraft_Settings[variablename])
	end
end

function TheoryCraft_CheckBoxSetText(self)
	local name = self:GetName()
	name = string.sub(name, 12)
	if TheoryCraft_CheckButtons[name] == nil then return end

	-- REM: hide is a table of class names for which a given checkbox option is to be disabled (because it doesn't apply to them)
	if TheoryCraft_CheckButtons[name].hide then
		for k,v in pairs(TheoryCraft_CheckButtons[name].hide) do
			if (TCUtils.CLASS == v) then
				getglobal(self:GetName()):Disable()
				getglobal(self:GetName().."Text"):SetTextColor(0.5, 0.5, 0.5)
			end
		end
	end
	_G[self:GetName().."Text"]:SetText(TheoryCraft_CheckButtons[name].short)
end

function TheoryCraft_CheckBoxToggle(self)
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON); -- Standard subtle click sound

	-- REM: true or nil
	local onoff
	if (self:GetChecked()) then
		onoff = true
	end
	local name = self:GetName()
	name = string.sub(name, 12) -- "TheoryCraft"
	if (name == "embedstyle1") or (name == "embedstyle2") or (name == "embedstyle3") then
		-- Clear all
		TheoryCraft_Settings["embedstyle1"] = nil
		TheoryCraft_Settings["embedstyle2"] = nil
		TheoryCraft_Settings["embedstyle3"] = nil
		-- Set the one that was clicked
		TheoryCraft_Settings[name] = onoff
		-- Update the checkboxes in the UI
		TheoryCraft_SetCheckBox("embedstyle1")
		TheoryCraft_SetCheckBox("embedstyle2")
		TheoryCraft_SetCheckBox("embedstyle3")
	else
		TheoryCraft_Settings[name] = onoff
	end

	if name == "dontresist" then
		-- REM: the setting has already been changed to the new setting by this point
		if TheoryCraft_Settings["dontresist"] then
			TheoryCraftresistArcane:Show()
			TheoryCraftresistFire:Show()
			TheoryCraftresistNature:Show()
			TheoryCraftresistFrost:Show()
			TheoryCraftresistShadow:Show()
		else
			TheoryCraftresistArcane:Hide()
			TheoryCraftresistFire:Hide()
			TheoryCraftresistNature:Hide()
			TheoryCraftresistFrost:Hide()
			TheoryCraftresistShadow:Hide()
		end
	end
	if (name == "procs") or (name == "rollignites") or (name == "sepignites") or (name == "combinedot") or (name == "dotoverct") or (name == "dontcrit") then
		TheoryCraft_GenerateAll() -- turning on/off several checkboxes
	end
	if (name == "buttontext") or (name == "dontresist") then
		TheoryCraft_DeleteTable(TheoryCraft_UpdatedButtons)
	end
end

-- NOTE: This handles /tc and all sub-commands
function TheoryCraft_Command(cmd)
	if (cmd == "") then
		if TheoryCraft_Data["firstrun"] == nil then
			PanelTemplates_SetNumTabs(TheoryCraft, 3)
			TheoryCraft.selectedTab = 1
			PanelTemplates_UpdateTabs(TheoryCraft)
		end
		TheoryCraft_Data["firstrun"] = 1

		-- Toggle the main frame.
		if (TheoryCraft:IsVisible()) then
			TheoryCraft:Hide()
		else
			TheoryCraft:Show()
		end
	end

	local cmd_opts = nil
	if strfind(cmd, " ") then
		-- Get the string from just beyond the first space until end
		cmd_opts = string.sub(cmd, strfind(cmd, " ")+1)
		-- Get the string from start until just before first space
		cmd = string.sub(cmd, 1, strfind(cmd, " ")-1)
	end
	if (cmd == "custom") then
		local linkid = string.sub(cmd_opts, string.find(cmd_opts, "item:%d+:%d+:%d+:%d+"))
		TheoryCraft_Settings["CustomOutfitName"] = "Custom"
		TheoryCraft_AddToCustom(linkid)
	end
	if (cmd == "calccrits") then
		if TheoryCraft_Settings["critchancedata"] == nil then
			print("No crits found - self feature works for heals only")
			return
		end
		local _, critrate, int, gear
		local crittable = {}
		for k, v in pairs(TheoryCraft_Settings["critchancedata"]) do
			_, _, int, gear = strfind(k, "(.+):(.+)")
			if crittable[int] == nil then
				crittable[int] = {}
			end
			critrate = v.crits/v.casts-gear/100
			crittable[int].casts = v.casts+(crittable[int].casts or 0)
			crittable[int].critrate = v.casts*(v.crits/v.casts-gear/100)/crittable[int].casts
		end
		local minint = 1000
		local maxint = 0
		local mincrit = 0
		local maxcrit = 0
		for k, v in pairs(crittable) do
			if (tonumber(k) < minint) and (v.casts > 400) then
				minint = tonumber(k)
				mincrit = v.critrate
			end
			if (tonumber(k) > maxint) and (v.casts > 400) then
				maxint = tonumber(k)
				maxcrit = v.critrate
			end
		end
		mincrit = mincrit * 100
		maxcrit = maxcrit * 100
		print("Int | Casts | Crit Chance")
		for k, v in crittable do
			print(k.." | "..v.casts.." | "..round(v.critrate*100,4).."%")
		end
		if minint == 1000 then
			print("Insufficient data to calculate crit rates")
		elseif minint == maxint then
			print("Insufficient range to calculate base crit, assuming 0")
			print("Int Per Crit = "..round(maxint/maxcrit,3))
			print("Base Crit = 0")
		else
			print("Using self data:")
			print("Int Per Crit = "..round((maxint-minint)/(maxcrit-mincrit),3))
			print("Base Crit = "..round((mincrit-minint/((maxint-minint)/(maxcrit-mincrit))),3).."%")
		end
	end
	if (cmd == "armor") or (cmd == "playerarmor") then
		if cmd_opts == nil then cmd_opts = "" end
		cmd_opts = string.upper(cmd_opts)
		local test = {}
		local i = 1
		local ul = UnitLevel("player")
		print(" ")
		if cmd == "armor" then
			for k, v in pairs(TheoryCraft_MitigationMobs) do
				if strfind(string.upper(k), cmd_opts) then
					test[i] = round((v[1] / (85 * ul + 400 + v[1]))*100,1).." | "..v[1].." | "..k
					i = i + 1
					if i > 250 then
						print("Please limit your search - more than 250 mobs were found")
						return
					end
				end
			end
			print("DR | Armor | Mob Name")
		else
			local classname, level, _
			for k, v in pairs(TheoryCraft_MitigationPlayers) do
				if strfind(string.upper(k), cmd_opts) and strfind(string.upper(k), ":") then
					_, _, classname, level = strfind(k, "(.+):(.+)")
					test[i] = classname.." | "..level.." | "..v[1].." | "..round((v[1] / (85 * ul + 400 + v[1]))*100,1)
					i = i + 1
					if i > 250 then
						print("Please limit your search - more than 250 mobs were found")
						return
					end
				end
			end
			print(" ")
			print("Class | Lvl | Armor | DR")
			table.sort(test)
			for k, v in pairs(test) do
				print(v)
			end
			test = {}
			for k, v in pairs(TheoryCraft_MitigationPlayers) do
				if strfind(string.upper(k), cmd_opts) and (not strfind(k, ":")) then
					test[i] = round((v[1] / (85 * ul + 400 + v[1]))*100,1).." | "..v[1].." | "..k
					i = i + 1
					if i > 250 then
						print("Please limit your search - more than 250 mobs were found")
						return
					end
				end
			end
			print(" ")
			print("DR | Armor | Player Name")
		end
		table.sort(test)
		for k, v in pairs(test) do
			print(v)
		end
	end

	if (cmd == "off") and (not TheoryCraft_Settings["off"]) then
		print("TheoryCraft is now switched OFF")
		TheoryCraft_Settings["off"] = true
		-- also re-render all buttontext (which will trigger it to hide)
		TheoryCraft_UpdateAllButtonText()
	end
	if (cmd == "on") and TheoryCraft_Settings["off"] then
		print("TheoryCraft is now switched ON")
		TheoryCraft_Settings["off"] = nil
		-- also re-render all buttontext
		TheoryCraft_UpdateAllButtonText()
	end

	if (cmd == "more") then
		print("/tc showmem")
		print("    Debug infomation, shows the memory usage (in bytes) as each event occurs")
		print("/tc damtodouble")
		print("    Shows how much +damage/+heal is required to double a spells base damage")
		print("/tc dpsmana")
		print("    Adds a dps/mana field to the tooltip")
		print("/tc armorchanges")
		print("    Prints whenever the armor value of the target changes")
		print("/tc armor (mob name)")
		print("    Prints the mobs armor. Leave blank for all.")
		print("/tc playerarmor (player name, or class)")
		print("    Prints a players armor. Leave blank for all.")
		print("/tc calccrits")
		print("    Shows your actual crit rate, from combat. Only works for healers.")
		print("Macro Tooltips")
		print("    If you name a macro the same as the name of the spell, in the format: Pyroblast(x), where x is the rank (or 0 if N/A), TC will show the correct tooltip. If the spell name does not fit, only use as many characters as can fit without leaving the rank off.")
	end

	-- Toggle on or off checkboxes from the UI panel.
	if (cmd == "titles") or (cmd == "dpsmana") or (cmd == "damtodouble") or (cmd == "hidecritdata") or (cmd == "dpsdampercent") or (cmd == "armorchanges") or (cmd == "procs") or (cmd == "hideadvanced") or (cmd == "hpm") or (cmd == "dpm") or (cmd == "dontcritdpm") or (cmd == "dontcrithpm") or (cmd == "nextagi") or (cmd == "nextpen") or (cmd == "embed") or (cmd == "dam") or (cmd == "averagedam") or (cmd == "averagedamnocrit") or (cmd == "crit") or (cmd == "critdam") or (cmd == "sepignite") or (cmd == "rollignites") or (cmd == "dps") or (cmd == "dpsdam") or (cmd == "resists") or (cmd == "timeit") or (cmd == "plusdam") or (cmd == "damcoef") or (cmd == "dameff") or (cmd == "damfinal") or (cmd == "nextcrit") or (cmd == "nexthit") or (cmd == "mana") or (cmd == "max") or (cmd == "maxevoc") or (cmd == "maxtime") or (cmd == "averagethreat") or (cmd == "healanddamage") or (cmd == "lifetap") or (cmd == "showmore") or (cmd == "showmem") then
		local onoff = nil
		if (TheoryCraft_Settings[cmd]) then
			onoff = nil
		else
			onoff = true
		end
		if onoff then
			print(cmd, "is now set to 'on'")
		else
			print(cmd, "is now set to 'off'")
		end
		TheoryCraft_Settings[cmd] = onoff
	end
end

function TheoryCraft_OutfitChange(self)
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON); -- Standard subtle click sound

	local id   = self:GetName()
	local name = self:GetText()

	-- Add all spells to the text box (and then you can selectively remove them)
	if (id == "TheoryCraftSetToAll") then
		TheoryCraftGenBox_Text:SetText("")
		local spellname, spellrank
		local i, i2 = 1
		local first = true
		local class = TCUtils.CLASS
		while (true) do
			spellname, spellrank = GetSpellBookItemName(i,BOOKTYPE_SPELL)
			if spellname == nil then break end
			spellrank = tonumber(TCUtils.findpattern(spellrank, "%d+"))
			if spellrank == nil then spellrank = 0 end
			i2 = 1
			while (TheoryCraft_Spells[class][i2]) and (spellname ~= TheoryCraft_Spells[class][i2].name) do
				i2 = i2 + 1
			end
			if (TheoryCraft_Spells[class][i2] ~= nil) then
				if first then
					TheoryCraftGenBox_Text:SetText(spellname.."("..spellrank..")")
					first = false
				else
					TheoryCraftGenBox_Text:SetText(TheoryCraftGenBox_Text:GetText().."\n"..spellname.."("..spellrank..")")
				end
			end
			i = i + 1
		end
		return
	end
	if (id == "TheoryCraftGenAll") then
		local timer = GetTime()
		TheoryCraft_UpdateGear(true)
		TheoryCraft_LoadStats()
		timer = round((GetTime()-timer)*1000)
		print(" ")
		print("TheoryCraft takes:", timer, "ms to read your gear. self will only occur out of combat, and only when your gear changes.")
		TheoryCraft_Data["reporttimes"] = true
		TheoryCraft_Data["buttonsgenerated"] = 0
		TheoryCraft_Data["timetaken"] = 0
		TheoryCraft_GenerateAll()
		return
	end
	-- Remove all manual adjustments to talent points
	if (id == "TheoryCraftResetButton") then
		TheoryCraft_Data["outfit"] = 1
		local i = 1
		while (TheoryCraft_Talents[i]) do
			TheoryCraft_Talents[i].forceto = -1
			i = i + 1
		end
		--TheoryCraft_UpdateGear(true) -- NOTE: There is currently no way to "Fake" a gear modification, so no need to reset this stuff
		TheoryCraft_UpdateTalents(true)
		TheoryCraft_LoadStats('reset_button')
		TheoryCraft_GenerateAll()
		--UIDropDownMenu_SetSelectedID(TheoryCraftoutfit, 1)
		TheoryCraftCustomOutfit:Hide()
		return
	end
	if (id == "TheoryCraftApplyButtonText") then
		TheoryCraft_UpdateAllButtonText('apply')
	end
	-- TODO: defunct because outfits are disabled.
	if (id == "TheoryCraftClearButton") then
		TheoryCraft_Settings["CustomOutfitName"] = "Custom"
		TheoryCraft_Settings["CustomOutfit"] = nil
		TheoryCraft_UpdateGear(true)
		TheoryCraft_LoadStats()
		TheoryCraft_GenerateAll()
		return
	end
	if (id == "TheoryCraftClose") then
		TheoryCraft:Hide()
		return
	end
	if (id == "TheoryCraftEquipTargetButton") then
		TheoryCraft_Settings["CustomOutfitName"] = UnitName("target")
		TheoryCraft_Settings["CustomOutfit"] = nil
		TheoryCraft_Data["outfit"] = 2
		TheoryCraft_UpdateGear(true)
		local i = 20
		while i > 0 do
			TheoryCraft_AddToCustom(GetInventoryItemLink("target", i))
			i=i-1
		end
		TheoryCraft_UpdateGear(true)
		TheoryCraft_LoadStats()
		TheoryCraft_GenerateAll()
		return
	end
	if (id == "TheoryCraftEquipSelfButton") then
		TheoryCraft_Settings["CustomOutfitName"] = "Self"
		TheoryCraft_Settings["CustomOutfit"] = nil
		TheoryCraft_UpdateGear(true)
		TheoryCraft_LoadStats()
		TheoryCraft_GenerateAll()
		TheoryCraft_Data["outfit"] = 2
		local i = 20
		while i > 0 do
			TheoryCraft_AddToCustom(GetInventoryItemLink("player", i))
			i=i-1
		end
		TheoryCraft_UpdateGear(true)
		TheoryCraft_LoadStats()
		TheoryCraft_GenerateAll()
		return
	end
end

-- TODO: There are 2 sets of text-boxes. Resistances and button_text
--       these should probably be handled by separate functions, but for now this works.
function TheoryCraft_UpdateEditBox(self)
	-- TODO: maybe its a good idea to rename all the frame names to be TheoryCraft_resist_fire and TheoryCraft_dontcrit
	--       that way its really easy to split the string instead of using strfind() and string.gsub()
	--       maybe a universal helper function to remove the "TheoryCraft_" prefix?
	local short_name = string.gsub(self:GetName(), "TheoryCraft", "")
	local text       = self:GetText()

	-- TODO: If an invalid option is chosen, we should immediately update the box value to whatever the default failsafe is.
	--       not just upon reload

	if strfind(short_name, "resist") then
		local resist_type = string.gsub(short_name, "resist", "")

		-- TODO: what the hell does "~" mean in the resist context?
		if not (text == "~") then
			text = tonumber(text)
		end
		if text == nil then
			text = 0
		end
		TheoryCraft_Settings["resistscores"][resist_type] = text
		-- REM: actually "includeresists"
		if TheoryCraft_Settings["dontresist"] then
			TheoryCraft_DeleteTable(TheoryCraft_UpdatedButtons)
		end
		return
	end

	-- One of the many color boxes
	if strfind(short_name, "Col") then
		text = tonumber(text)

		if text == nil or text < 0 then
			text = 0
		elseif text > 255 then
			text = 255
		end
		text = text/255
	end

	-- FontSize box
	if strfind(short_name, "FontSize") then
		text = tonumber(text)

		-- valid font sizes is 12 <--> 20 pt
		if text == nil or text < 12 then
			text = 12
		elseif text > 20 then
			text = 20
		end
	end

	TheoryCraft_Settings[short_name] = text
end
