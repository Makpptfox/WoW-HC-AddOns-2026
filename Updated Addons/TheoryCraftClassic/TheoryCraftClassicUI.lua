
-- Stores the MultiActionBarButton connected to its absolute slot_id
-- NOTE: paginated ActionBars have their FrameName reused. So there is NEVER a 1-to-1 mapping of slot_id => frame_id
-- See: TheoryCraft_FindActionButton
local slot_id_action_bar_map = {}

local _TOOLTIPTAB = 1
local _BUTTONTEXTTAB = 2
local _ADVANCEDTAB = 3

local _, class = UnitClass("player")

-- REM: called from inside TheoryCraft_AddButtonText and from whatever bartender4 code exists
-- REM: MultiActionBars will be setup even if they are not visible
function TheoryCraft_SetUpButton(parentname, button_type, slot_id)
	local parent_button = _G[parentname]

	if not parent_button then
		return
	end

	-- Only the MultiActionBar buttons need slot configurations
	if slot_id ~= nil then
		slot_id_action_bar_map[slot_id] = parent_button
	end

	-- If the text subframe has already been created, we're good to go
	local button_tc_text = getglobal(parentname.."_TCText")
	if button_tc_text and button_tc_text.type then 
		return
	end

	-- Looks like this is creating the sub-frame FontString for each button, so it can be written later.
	-- ??? I guess this would overwrite one that already existed (but without type set?)
	button_tc_text = parent_button:CreateFontString(parentname.."_TCText", "ARTWORK") -- TODO: why artwork level, shouldn't it be OVERLAY?

	button_tc_text:SetFont("Fonts\\ARIALN.TTF", TheoryCraft_Settings["FontSize"], "OUTLINE")

	-- NOTE: by calling SetPoint(TOPLEFT)
	--       and        SetPoint(BOTTOMRIGHT)
	--       in theory this is scaling self to the size of the parent.
	--       see: https://wowpedia.fandom.com/wiki/API_Region_SetAllPoints
	-- ??? SetPoint probably doesn't even matter at this point, it'll get overwritten when the actual settings are read
	button_tc_text:SetPoint("TOPLEFT",     parent_button, "TOPLEFT",     0, 0)
	--button_tc_text:SetPoint("BOTTOMRIGHT", parent_button, "BOTTOMRIGHT", 0, 0)
	-- NOTE: it looks like button_type is only used for checking whether this button is part of the SpellBook
	button_tc_text.type      = button_type
	--button_tc_text.specialid = specialid
	button_tc_text:SetText(" ")
	button_tc_text:Show()

end

local function round(arg1, decplaces)
	if (decplaces == nil) then decplaces = 0 end
	if arg1 == nil then arg1 = 0 end
	return string.format ("%."..decplaces.."f", arg1)
end

function TheoryCraft_GenBoxEditChange()
	TheoryCraft_Settings["GenerateList"] = TheoryCraftGenBox_Text:GetText()
end

function TheoryCraft_CustomizedEditChange()
	TheoryCraft_Settings["Customized"] = TheoryCraftCustomized_Text:GetText()
end

local function UpdateCustomOutfit()
	if TheoryCraft_Data.outfit == 2 then
		TheoryCraftCustomOutfit:Show()
	else
		TheoryCraftCustomOutfit:Hide()
		return
	end
	local i = 1
	local i2 = 1
	TheoryCraftCustomLeft:SetText()
	TheoryCraftCustomRight:SetText()
	TheoryCraftCustomLeft:SetHeight(1)
	TheoryCraftCustomRight:SetHeight(1)
	local text = 1
	while (TheoryCraft_SlotNames[i]) do
		if (TheoryCraftCustomLeft:GetText(text) == nil) or (string.find(TheoryCraftCustomLeft:GetText(text), TheoryCraft_SlotNames[i].slot) == nil) then
			if string.find(TheoryCraft_SlotNames[i].slot, "%d+") then
				text = string.sub(TheoryCraft_SlotNames[i].slot, 1, string.find(TheoryCraft_SlotNames[i].slot, "%d+")-1)
			else
				text = TheoryCraft_SlotNames[i].slot
			end
			if TheoryCraftCustomLeft:GetText() then
				TheoryCraftCustomLeft:SetText(TheoryCraftCustomLeft:GetText().."\n"..text)
			else
				TheoryCraftCustomLeft:SetText(text)
			end
			if TheoryCraft_Settings["CustomOutfit"].slots[TheoryCraft_SlotNames[i].slot] then
				text = TheoryCraft_Settings["CustomOutfit"].slots[TheoryCraft_SlotNames[i].slot]["name"]
			else
				text = " "
			end
			if TheoryCraftCustomRight:GetText() then
				TheoryCraftCustomRight:SetText(TheoryCraftCustomRight:GetText().."\n"..text)
			else
				TheoryCraftCustomRight:SetText(text)
			end
			TheoryCraftCustomLeft:SetHeight(11+TheoryCraftCustomLeft:GetHeight())
			TheoryCraftCustomRight:SetHeight(TheoryCraftCustomLeft:GetHeight())
		end
		i = i + 1
	end
end

local function TheoryCraftAddStat(text, text2)
	if (text == nil) or (text2 == nil) then return end
	if TheoryCraftStatsLeft:GetText() then
		TheoryCraftStatsLeft:SetText(TheoryCraftStatsLeft:GetText().."\n"..text)
		TheoryCraftStatsRight:SetText(TheoryCraftStatsRight:GetText().."\n"..text2)
	else
		TheoryCraftStatsLeft:SetText(text)
		TheoryCraftStatsRight:SetText(text2)
	end
	TheoryCraftStatsLeft:SetHeight(10+TheoryCraftStatsLeft:GetHeight())
	TheoryCraftStatsRight:SetHeight(TheoryCraftStatsLeft:GetHeight())
end

local function TheoryCraftAddVital(text, text2)
	if (text == nil) or (text2 == nil) then return end
	if TheoryCraftVitalsLeft:GetText() then
		TheoryCraftVitalsLeft:SetText(TheoryCraftVitalsLeft:GetText().."\n"..text)
		TheoryCraftVitalsRight:SetText(TheoryCraftVitalsRight:GetText().."\n"..text2)
	else
		TheoryCraftVitalsLeft:SetText(text)
		TheoryCraftVitalsRight:SetText(text2)
	end
	TheoryCraftVitalsLeft:SetHeight(10+TheoryCraftVitalsLeft:GetHeight())
	TheoryCraftVitalsRight:SetHeight(TheoryCraftVitalsLeft:GetHeight())
end

local function TheoryCraftAddMod(text, text2)
	if (text == nil) or (text2 == nil) then return end
	if TheoryCraftModsLeft:GetText() then
		TheoryCraftModsLeft:SetText(TheoryCraftModsLeft:GetText().."\n"..text)
	else
		TheoryCraftModsLeft:SetText(text)
	end
	if TheoryCraftModsRight:GetText() then
		TheoryCraftModsRight:SetText(TheoryCraftModsRight:GetText().."\n"..text2)
	else
		TheoryCraftModsRight:SetText(text2)
	end
end

local function AddMods(mult, mod, all, healing, damage, school, prefix, suffix, pre2)
	local tmp = TheoryCraft_GetStat("All"..mod)*mult
	if tmp ~= 0 then
		if all ~= "DONT" then
			TheoryCraftAddMod(all, prefix..tmp..suffix)
		end
	end
	tmp = TheoryCraft_GetStat("Healing"..mod)*mult
	if tmp ~= 0 then
		TheoryCraftAddMod(healing, prefix..tmp..suffix)
	end
	tmp = TheoryCraft_GetStat("Damage"..mod)*mult
	if tmp ~= 0 then
		TheoryCraftAddMod(damage, prefix..tmp..suffix)
	end
	if pre2 == nil then pre2 = "" end
	for k,v in pairs(TheoryCraft_PrimarySchools) do
		tmp = TheoryCraft_GetStat(v.name..mod)*mult
		if tmp ~= 0 then
			TheoryCraftAddMod(pre2..v.name..school, prefix..tmp..suffix)
		end
	end
end

function TheoryCraft_TabHandler(name)
	--local name = self:GetName()
	name = tonumber(string.sub(name, 15))

	-- Hide all
	TheoryCraftSettingsTab:Hide()
	TheoryCraftCustomOutfit:Hide()
	TheoryCraftOutfitTab:Hide()
	TheoryCraftButtonTextTab:Hide()

	-- Show whichever one was clicked.
	if (name == _TOOLTIPTAB) then
		TheoryCraftSettingsTab:Show()
	elseif (name == _BUTTONTEXTTAB) then
		TheoryCraftButtonTextTab:Show()
	elseif (name == _ADVANCEDTAB) then 
		TheoryCraftOutfitTab:Show()
		TheoryCraft_UpdateOutfitTab()
	end
end

-- NOTE: this is actually the Vitals & Talents tab
function TheoryCraft_UpdateOutfitTab()
	if not TheoryCraftOutfitTab:IsVisible() then
		return
	end

	-- ####### Draw talent area (at bottom of window) #######
	-- NOTE: this area is of dubious value
	-- The intended purpose is to tweak your talent setup and see what effect that might have on your dps/hps
	-- This is probably out of scope for this mod, Spreadsheet simulators are much more accurate these days.
	local i = 1
	local i2 = 1
	while i < 4 do
		i2 = 1
		-- hide all buttons and clear the accompaning text.
		-- Will be redrawn by the subsequent loop below
		-- similar to remove classes from a group, and re-set on a single element.
		getglobal("TheoryCraftTalentTree"..i):SetText(" ")
		while getglobal("TheoryCraftTalent"..i..i2) do
			getglobal("TheoryCraftTalent"..i..i2):Hide()
			i2 = i2+1
		end
		i = i+1
	end
	i2 = 1
	local number
	local title, rank, i3, _, currank
	local highestnumber = 0
	-- redraw all talent text and buttons
	-- REM: not all talents apply for all classes, so only relevant ones will be redrawn.
	while i2 < 4 do
		i = 1
		number = 1

		while (TheoryCraft_Talents[i]) do
			if (class == TheoryCraft_Talents[i].class) and (TheoryCraft_Talents[i].dontlist == nil) and (((TheoryCraft_Talents[i].tree == i2) and (TheoryCraft_Talents[i].forcetree == nil)) or (TheoryCraft_Talents[i].forcetree == i2)) then
				rank = getglobal("TheoryCraftTalent"..i2..number)
				-- NOTE: "rank" appears to be a frame, specifically a button
				i3 = 1
				while (TheoryCraft_Locale.TalentTranslator[i3]) and (TheoryCraft_Locale.TalentTranslator[i3].id ~= TheoryCraft_Talents[i].name) do
					i3 = i3 + 1
				end
				if (TheoryCraft_Locale.TalentTranslator[i3]) and (rank ~= nil) then
                    -- TODO: it would be nice to be able to access this through rank instead of through the global namespace.
					title = getglobal("TheoryCraftTalent"..i2..number.."Label")
					title:SetText(TheoryCraft_Locale.TalentTranslator[i3].translated)

					_, _, _, _, currank = GetTalentInfo(TheoryCraft_Talents[i].tree, TheoryCraft_Talents[i].number)
					if ((TheoryCraft_Talents[i].forceto == nil) or (TheoryCraft_Talents[i].forceto == -1)) then
						rank:SetText(currank)
					else
						rank:SetText(TheoryCraft_Talents[i].forceto)
					end
					-- Clear the button textures, so its just the number
					-- TODO: These are not working, but I don't care.
					--rank:SetNormalTexture(nil)
					--rank:SetPushedTexture(nil)
					--rank:SetHighlightTexture(nil)

					-- https://wowwiki-archive.fandom.com/wiki/API_FontInstance_SetTextColor
					-- Button:SetTextColor was deleted in 3.0. Instead use FontInstance:SetTextColor

					-- Built in colors: GameFontNormalSmall, GameFontGreenSmall, GameFontRedSmall
					-- reset the color
					rank:SetNormalFontObject("GameFontNormalSmall")

					-- If the talent is modified from what your actual talents are.
					if (TheoryCraft_Talents[i].forceto) and (TheoryCraft_Talents[i].forceto ~= -1) then
						-- maybe modify the color
						if TheoryCraft_Talents[i].forceto > currank then
							rank:SetNormalFontObject("GameFontGreenSmall")
						elseif TheoryCraft_Talents[i].forceto < currank then
							rank:SetNormalFontObject("GameFontRedSmall")
						end
					end

					rank:Show()
					number = number + 1
				end
			end
			i = i+1
		end
		if highestnumber < number then highestnumber = number end
		i2 = i2 + 1
	end

	-- This is placing the "Talents" title JUST high enough to not push talent columns off the bottom.
	-- Maximum of 8 talents in a column, so this is of dubious value
	TheoryCraftTalentTitle:SetPoint("BOTTOMLEFT", TheoryCraftOutfitTab, "BOTTOMLEFT", 20, 42+10*highestnumber)

	-- ####### Draw the vitals area (at top of window) #######

	-- First reset everything
	TheoryCraftVitalsLeft:SetText()
	TheoryCraftVitalsRight:SetText()
	TheoryCraftVitalsLeft:SetHeight(2)
	TheoryCraftVitalsRight:SetHeight(2)

	TheoryCraftStatsLeft:SetText()
	TheoryCraftStatsRight:SetText()
	TheoryCraftStatsLeft:SetHeight(2)
	TheoryCraftStatsRight:SetHeight(2)

	TheoryCraftModsLeft:SetText()
	TheoryCraftModsRight:SetText()
	TheoryCraftModsLeft:SetHeight(2)
	TheoryCraftModsRight:SetHeight(2)

	local totalmana = TheoryCraft_GetStat("totalmana")+TheoryCraft_GetStat("manarestore")

	-- Calculate everything according to class formulae

	TheoryCraftAddVital("Health", math.floor(TheoryCraft_GetStat("totalhealth")))
	if class == "HUNTER" then
		TheoryCraftAddVital("Mana", math.floor(TheoryCraft_GetStat("totalmana")))
		TheoryCraftAddVital("Attack Power", math.floor(TheoryCraft_GetStat("attackpower")))
		TheoryCraftAddVital("Ranged Attack Power", math.floor(TheoryCraft_GetStat("rangedattackpower")))
		TheoryCraftAddVital("Crit Chance", round(TheoryCraft_GetStat("meleecritchancereal"), 2).."%")
		TheoryCraftAddVital("Ranged Crit Chance", round(TheoryCraft_GetStat("rangedcritchance"), 2).."%")
		TheoryCraftAddVital("Agi per Crit", round(TheoryCraft_agipercrit, 2))
		TheoryCraftAddVital("Normal Regen", round(TheoryCraft_Data.Stats["regen"]*2, 2).." / Tick")
		TheoryCraftAddVital("Regen Whilst Casting", round(TheoryCraft_Data.Stats["icregen"]*2, 2).." / Tick")
		TheoryCraftAddStat("Stamina", math.floor(TheoryCraft_GetStat("stamina")))
		TheoryCraftAddStat("Strength", math.floor(TheoryCraft_GetStat("strength")))
		TheoryCraftAddStat("Agility", math.floor(TheoryCraft_GetStat("agility")))
		TheoryCraftAddStat("Intellect", math.floor(TheoryCraft_GetStat("intellect")))
		TheoryCraftAddStat("Spirit", math.floor(TheoryCraft_GetStat("spirit")))
	elseif (class == "ROGUE") or (class == "WARRIOR") then
		TheoryCraftAddVital("Attack Power", math.floor(TheoryCraft_GetStat("attackpower")))
		TheoryCraftAddVital("Crit Chance", round(TheoryCraft_GetStat("meleecritchancereal"), 2).."%")
		TheoryCraftAddVital("Agi per Crit", round(TheoryCraft_agipercrit, 2))
		TheoryCraftAddStat("Stamina", math.floor(TheoryCraft_GetStat("stamina")))
		TheoryCraftAddStat("Strength", math.floor(TheoryCraft_GetStat("strength")))
		TheoryCraftAddStat("Agility", math.floor(TheoryCraft_GetStat("agility")))
	elseif (class == "PALADIN") then
		TheoryCraftAddVital("Mana", math.floor(TheoryCraft_GetStat("totalmana")))
		TheoryCraftAddVital("Attack Power", math.floor(TheoryCraft_GetStat("attackpower")))
		TheoryCraftAddVital("Crit Chance", round(TheoryCraft_GetStat("meleecritchancereal"), 2).."%")
		TheoryCraftAddVital("Agi per Crit", round(TheoryCraft_agipercrit, 2))
		TheoryCraftAddVital("Normal Regen", round(TheoryCraft_Data.Stats["regen"]*2, 2).." / Tick")
		TheoryCraftAddVital("Regen Whilst Casting", round(TheoryCraft_Data.Stats["icregen"]*2, 2).." / Tick")
		TheoryCraftAddStat("Stamina", math.floor(TheoryCraft_GetStat("stamina")))
		TheoryCraftAddStat("Intellect", math.floor(TheoryCraft_GetStat("intellect")))
		TheoryCraftAddStat("Strength", math.floor(TheoryCraft_GetStat("strength")))
		TheoryCraftAddStat("Agility", math.floor(TheoryCraft_GetStat("agility")))
		TheoryCraftAddStat("Spirit", math.floor(TheoryCraft_GetStat("spirit")))
	elseif (class == "DRUID") then
		if UnitManaMax("player") == 100 then
			TheoryCraftAddVital("Attack Power", math.floor(TheoryCraft_GetStat("attackpower")))
			TheoryCraftAddVital("Crit Chance", round(TheoryCraft_GetStat("meleecritchancereal"), 2).."%")
			TheoryCraftAddVital("Agi per Crit", round(TheoryCraft_agipercrit, 2))
			TheoryCraftAddStat("Stamina", math.floor(TheoryCraft_GetStat("stamina")))
			TheoryCraftAddStat("Strength", math.floor(TheoryCraft_GetStat("strength")))
			TheoryCraftAddStat("Agility", math.floor(TheoryCraft_GetStat("agility")))
		else
			TheoryCraftAddVital("Mana", math.floor(TheoryCraft_GetStat("totalmana")))
			TheoryCraftAddVital("Normal Regen", round(TheoryCraft_Data.Stats["regen"]*2, 2).." / Tick")
			TheoryCraftAddVital("Regen Whilst Casting", round(TheoryCraft_Data.Stats["icregen"]*2, 2).." / Tick")
			TheoryCraftAddStat("Stamina", math.floor(TheoryCraft_GetStat("stamina")))
			TheoryCraftAddStat("Intellect", math.floor(TheoryCraft_GetStat("intellect")))
			TheoryCraftAddStat("Spirit", math.floor(TheoryCraft_GetStat("spirit")))
		end
	else
		TheoryCraftAddVital("Mana", math.floor(TheoryCraft_GetStat("totalmana")))
		TheoryCraftAddVital("Normal Regen", round(TheoryCraft_Data.Stats["regen"]*2, 2).." / Tick")
		TheoryCraftAddVital("Regen Whilst Casting", round(TheoryCraft_Data.Stats["icregen"]*2, 2).." / Tick")
		TheoryCraftAddStat("Stamina", math.floor(TheoryCraft_GetStat("stamina")))
		TheoryCraftAddStat("Intellect", math.floor(TheoryCraft_GetStat("intellect")))
		TheoryCraftAddStat("Spirit", math.floor(TheoryCraft_GetStat("spirit")))
	end

	TheoryCraftModsLeft:SetHeight(288-TheoryCraftStatsLeft:GetHeight()-TheoryCraftVitalsLeft:GetHeight()-10*highestnumber)
	TheoryCraftModsRight:SetHeight(TheoryCraftModsLeft:GetHeight())

	local proceffect
	if TheoryCraft_GetStat("FrostboltNetherwind") ~= 0 then
		proceffect = 1
	end
	if TheoryCraft_GetStat("Beastmanarestore") ~= 0 then
		proceffect = 1
	end
	if TheoryCraft_Data.EquipEffects["procs"] then
		if TheoryCraft_IsDifferent(TheoryCraft_Data.EquipEffects["procs"], { }) then
			proceffect = 1
		end
	end
	if proceffect then
		TheoryCraftAddMod("Proc Effect", " ")
	end

	if TheoryCraft_GetStat("CritReport") ~= 0 then
		TheoryCraftAddMod("Crit Chance", "+"..(TheoryCraft_GetStat("CritReport")).."%")
	end
	if (class ~= "HUNTER") and (class ~= "WARRIOR") and (class ~= "ROGUE") then
		if TheoryCraft_GetStat("Allcritchance") ~= 0 then
			TheoryCraftAddMod("Spell Crit Chance", round(TheoryCraft_Data.Stats["critchance"], 2).."% + "..(TheoryCraft_GetStat("Allcritchance")).."%")
		else
			TheoryCraftAddMod("Spell Crit Chance", round(TheoryCraft_Data.Stats["critchance"], 2).."%")
		end
	end
	AddMods(1, "critchance", "DONT", "Heal Crit Chance", "Damage Spell Crit Chance", " Crit Chance", "+", "%")
	AddMods(1, "", "+Damage and Healing", "+Healing", "+Spell Damage", " Damage", "", "", "+")
	if TheoryCraft_GetStat("Undead") ~= 0 then
		TheoryCraftAddMod("+Damage to Undead", TheoryCraft_GetStat("Undead"))
	end
	if TheoryCraft_GetStat("AttackPowerReport") ~= 0 then
		TheoryCraftAddMod("Attack Power", "+"..(TheoryCraft_GetStat("AttackPowerReport")))
	end
	if TheoryCraft_GetStat("RangedAttackPowerReport") ~= 0 then
		TheoryCraftAddMod("Ranged Attack Power", "+"..(TheoryCraft_GetStat("RangedAttackPowerReport")))
	end
	if TheoryCraft_GetStat("BlockValueReport") ~= 0 then
		TheoryCraftAddMod("Shield Block Value", TheoryCraft_GetStat("BlockValueReport"))
	end
	AddMods(1, "hitchance", "Spell Hit Chance", "", "Damage Spell Hit Chance", " Hit Chance", "+", "%")
	if TheoryCraft_GetStat("Meleehitchance") ~= 0 then
		TheoryCraftAddMod("Hit Chance", "+"..(TheoryCraft_GetStat("Meleehitchance")).."%")
	end
	AddMods(1, "penetration", "Spell Penetration", "", "Damage Spell Penetration", " Penetration", "", "")
	if TheoryCraft_GetStat("manaperfive") ~= 0 then
		TheoryCraftAddMod("Mana Per Five", TheoryCraft_GetStat("manaperfive"))
	end
	if TheoryCraft_GetStat("ICPercent") ~= 0 then
		TheoryCraftAddMod("Spirit In 5 Rule", (TheoryCraft_GetStat("ICPercent")*100).."%")
	end
	if TheoryCraft_GetStat("manarestore") ~= 0 then
		TheoryCraftAddMod("Mana Restore", TheoryCraft_GetStat("manarestore"))
	end
	--UpdateCustomOutfit() -- probably remove in the future
end

-- These are apparently the handlers for when an option in the dropdown boxes are selected.
function TheoryCraft_Combo1Click(self)
	local optionID = self:GetID()
	UIDropDownMenu_SetSelectedID(TheoryCrafttryfirst, optionID)
	TheoryCraft_Settings["tryfirst"] = self.value
	TheoryCraft_DeleteTable(TheoryCraft_UpdatedButtons)
end

function TheoryCraft_Combo2Click(self)
	local optionID = self:GetID()
	UIDropDownMenu_SetSelectedID(TheoryCrafttrysecond, optionID)
	TheoryCraft_Settings["trysecond"] = self.value
	TheoryCraft_DeleteTable(TheoryCraft_UpdatedButtons)
end

function TheoryCraft_Combo3Click(self)
	local optionID = self:GetID()
	UIDropDownMenu_SetSelectedID(TheoryCrafttryfirstsfg, optionID)
	TheoryCraft_Settings["tryfirstsfg"] = self.value
	TheoryCraft_DeleteTable(TheoryCraft_UpdatedButtons)
end

function TheoryCraft_Combo4Click(self)
	local optionID = self:GetID()
	UIDropDownMenu_SetSelectedID(TheoryCrafttrysecondsfg, optionID)
	TheoryCraft_Settings["trysecondsfg"] = self.value
	TheoryCraft_DeleteTable(TheoryCraft_UpdatedButtons)
end
local info = {}

-- Add a button within a dropdown
local function AddButton(i, text, value, func, remaining)
	TheoryCraft_DeleteTable(info)
	info.remaining = true
	info.text = text
	info.value = value
	info.func = func
	UIDropDownMenu_AddButton(info)
	if (func == TheoryCraft_Combo1Click) and (TheoryCraft_Settings["tryfirst"] == value) then
		UIDropDownMenu_SetSelectedID(TheoryCrafttryfirst, i)
	end
	if (func == TheoryCraft_Combo2Click) and (TheoryCraft_Settings["trysecond"] == value) then
		UIDropDownMenu_SetSelectedID(TheoryCrafttrysecond, i)
	end
	if (func == TheoryCraft_Combo3Click) and (TheoryCraft_Settings["tryfirstsfg"] == value) then
		UIDropDownMenu_SetSelectedID(TheoryCrafttryfirstsfg, i)
	end
	if (func == TheoryCraft_Combo4Click) and (TheoryCraft_Settings["trysecondsfg"] == value) then
		UIDropDownMenu_SetSelectedID(TheoryCrafttrysecondsfg, i)
	end
--[[
	if (func == TheoryCraft_OutfitClick) and ((TheoryCraft_Data["outfit"] == value) or ((TheoryCraft_Data["outfit"] == nil) and (value == 1))) then
		UIDropDownMenu_SetSelectedID(TheoryCraftoutfit, i)
	end
--]]
	return i + 1
end

function TheoryCraft_InitDropDown(this)
	local a
	local i = 1
--[[
	if string.find(this:GetName(), "TheoryCraftoutfit") then
		for k, v in pairs(TheoryCraft_Outfits) do
			if ((v.class == nil) or (class == v.class)) then
				i = AddButton(i, (v.shortname or v.name), k, TheoryCraft_OutfitClick)
			end
		end
		return
	end
--]]

	-- NOTE: ComboXClick are the names of the UI element we are initializing.
	if string.find(this:GetName(), "sfg") then
		if string.find(this:GetName(), "TheoryCrafttryfirst") then
			a = TheoryCraft_Combo3Click
		else
			a = TheoryCraft_Combo4Click
		end
		i = AddButton(i, "0.01", 2, a)
		i = AddButton(i, "0.1", 1, a)
		i = AddButton(i, "1", 0, a)
		i = AddButton(i, "10", -1, a)
		i = AddButton(i, "100", -2, a)
		i = AddButton(i, "1000", -3, a)
		return
	end

	if string.find(this:GetName(), "TheoryCrafttryfirst") then
		a = TheoryCraft_Combo1Click
	else
		a = TheoryCraft_Combo2Click
	end
	i = AddButton(i, "Do Nothing", "donothing", a)
	i = AddButton(i, "Min Damage", "mindamage", a)
	i = AddButton(i, "Max Damage", "maxdamage", a)
	i = AddButton(i, "Average Damage", "averagedam", a)
	i = AddButton(i, "Ave Dam (no crits)", "averagedamnocrit", a)
	i = AddButton(i, "DPS", "dps", a)
	i = AddButton(i, "With Dot DPS", "withdotdps", a)
	i = AddButton(i, "DPM", "dpm", a)
	i = AddButton(i, "Total Damage", "maxoomdamfloored", a)
	i = AddButton(i, "Total Damage (left)", "maxoomdamremaining", a)
	i = AddButton(i, "Min Heal", "minheal", a)
	i = AddButton(i, "Max Heal", "maxheal", a)
	i = AddButton(i, "Average Heal", "averageheal", a)
	i = AddButton(i, "Ave Heal (no crits)", "averagehealnocrit", a)
	i = AddButton(i, "HPS", "hps", a)
	i = AddButton(i, "With Hot HPS", "withhothps", a)
	i = AddButton(i, "HPM", "hpm", a)
	i = AddButton(i, "Total Healing", "maxoomhealfloored", a)
	i = AddButton(i, "Total Healing (left)", "maxoomhealremaining", a)
	i = AddButton(i, "Spellcasts remaining", "spellcasts", a)
end

-- NOTE: TheoryCraft_Talents[i].forceto is an override of what you're actual talents are with what the player wants to experiment with.
function TheoryCraft_SetTalent(name)
	--local name = self:GetName()
	local i = 1
	local i2 = tonumber(string.sub(name, 18, 18))
	local numberneeded = tonumber(string.sub(name, 19, 19))
	local number = 1
	local newrank = 0
	local _, currank, maxRank
	number = 1
	while (TheoryCraft_Talents[i]) do
		if (class == TheoryCraft_Talents[i].class) and (TheoryCraft_Talents[i].dontlist == nil) and (((TheoryCraft_Talents[i].tree == i2) and (TheoryCraft_Talents[i].forcetree == nil)) or (TheoryCraft_Talents[i].forcetree == i2)) then
			if (number == numberneeded) then
				nameneeded = TheoryCraft_Talents[i].name
				_, _, _, _, currank, maxRank= GetTalentInfo(TheoryCraft_Talents[i].tree, TheoryCraft_Talents[i].number)
				if (TheoryCraft_Talents[i].forceto == nil) or (TheoryCraft_Talents[i].forceto == -1) then
					newrank = currank + 1
				else
					newrank = TheoryCraft_Talents[i].forceto + 1
				end
				if newrank > maxRank then
					newrank = 0
				end
				break
			end
			number = number + 1
		end
		i = i+1
	end
	i = 1
	while (TheoryCraft_Talents[i]) do
		if (class == TheoryCraft_Talents[i].class) then
			if (TheoryCraft_Talents[i].name == nameneeded) then
				TheoryCraft_Talents[i].forceto = newrank
			end
		end
		i = i+1
	end
	TheoryCraft_UpdateTalents() -- manually adjusting talents in the vitals tab
end

-- Set the checkbox state according to what is saved in settings.
function TheoryCraft_InitCheckboxState()
	TheoryCraft_SetCheckBox("embedstyle1")
	TheoryCraft_SetCheckBox("embedstyle2")
	TheoryCraft_SetCheckBox("embedstyle3")
	TheoryCraft_SetCheckBox("titles")
	TheoryCraft_SetCheckBox("embed")
	TheoryCraft_SetCheckBox("crit")
	TheoryCraft_SetCheckBox("critdam")
	TheoryCraft_SetCheckBox("sepignite")
	TheoryCraft_SetCheckBox("rollignites")
	TheoryCraft_SetCheckBox("dps")
	TheoryCraft_SetCheckBox("combinedot")
	TheoryCraft_SetCheckBox("dotoverct")
	TheoryCraft_SetCheckBox("hps")
	TheoryCraft_SetCheckBox("dpsdam")
	TheoryCraft_SetCheckBox("averagedam")
	TheoryCraft_SetCheckBox("procs")
	TheoryCraft_SetCheckBox("mitigation")
	TheoryCraft_SetCheckBox("resists")
	TheoryCraft_SetCheckBox("averagethreat")
	TheoryCraft_SetCheckBox("plusdam")
	TheoryCraft_SetCheckBox("damcoef")
	TheoryCraft_SetCheckBox("dameff")
	TheoryCraft_SetCheckBox("damfinal")
	TheoryCraft_SetCheckBox("healanddamage")
	TheoryCraft_SetCheckBox("nextagi")
	TheoryCraft_SetCheckBox("nextstr")
	TheoryCraft_SetCheckBox("nextcrit")
	TheoryCraft_SetCheckBox("nexthit")
	TheoryCraft_SetCheckBox("nextpen")
	TheoryCraft_SetCheckBox("mana")
	TheoryCraft_SetCheckBox("dpm")
	TheoryCraft_SetCheckBox("hpm")
	TheoryCraft_SetCheckBox("max")
	TheoryCraft_SetCheckBox("maxevoc")
	TheoryCraft_SetCheckBox("lifetap")
	TheoryCraft_SetCheckBox("dontcrit")
	TheoryCraft_SetCheckBox("dontresist") -- TODO: rename to "includeresist"
	TheoryCraft_SetCheckBox("buttontext")

	TheoryCraftresistArcane:SetText(TheoryCraft_Settings["resistscores"]["Arcane"])
	TheoryCraftresistFire:SetText(TheoryCraft_Settings["resistscores"]["Fire"])
	TheoryCraftresistNature:SetText(TheoryCraft_Settings["resistscores"]["Nature"])
	TheoryCraftresistFrost:SetText(TheoryCraft_Settings["resistscores"]["Frost"])
	TheoryCraftresistShadow:SetText(TheoryCraft_Settings["resistscores"]["Shadow"])

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

-- TODO: maybe a better name?
function TheoryCraft_RestrictDummyButtonText(this)
	-- Looks like scale is 1 for me... TODO: do I need to worry about scale in the future?
	--print('scale: ' .. this:GetScale())

	local w = round(GetScreenWidth())
	local h = round(GetScreenHeight())

	--print('screen width: ' .. w)
	--print('screen height: ' .. h)

	local xL, xR, yT, yB -- left, right, top, bottom

	-- TODO: maybe "left, bottom, width, height = GetRect()"
	--             "left, bottom, width, height = GetScaledRect()"

	-- Returns the distance from the bottom-left corner of the screen to the center of a region
	xL, yB = this:GetParent():GetCenter()
	xL = round(xL)
	yB = round(yB)

	xR = w - xL
	yT = h - yB

	--print('center offset LxB: ' .. xL .. ' x ' .. yB)
	--print('center offset RxT: ' .. xR .. ' x ' .. yT)

	local fw, fh = this:GetParent():GetSize() -- both should be 100 as set by the xml
	fw = round(fw) -- weird decimals, need rounding
	fh = round(fh)

	--print('parent WxH: ' .. fw .. ' x ' .. fh)

	-- Figure out the proper offsets.
	local offset_L, offset_R, offset_T, offset_B
	offset_L = xL - (fw/2)
	offset_R = xR - (fw/2)
	offset_T = yT - (fh/2)
	offset_B = yB - (fh/2)

	--print('offset_L: ' .. offset_L)
	--print('offset_R: ' .. offset_R)
	--print('offset_T: ' .. offset_T)
	--print('offset_B: ' .. offset_B)

	-- First set this, or else the Insets won't work.
	this:SetClampedToScreen(true)
	-- Set margins from the edges of the screen. No there doesn't seem to be a better way to do this
	-- L & B must be negative to enforce a margin
	-- R & T must be positive to enforce a margin
	this:SetClampRectInsets(-offset_L, offset_R, offset_T, -offset_B)
end


-- NOTE: this is for positioning the button_text relative to the spell icons.
function TheoryCraft_UpdateButtonTextPos(this)
	local this_left, this_bottom = this:GetCenter()
	-- Find the offsets from the parent frame. (both should be positive)
	-- TODO: take into account scaling?
	local p_left, p_bottom, p_width, p_height = this:GetParent():GetRect()
	p_width  = round(p_width)  -- weird decimals, need rounding
	p_height = round(p_height)
	--print('parent WxH: ' .. p_width .. ' x ' .. p_height)

	local offset_x = round(this_left   - p_left)
	local offset_y = round(this_bottom - p_bottom)
	--print('offset x/y: ' .. offset_x .. '/' .. offset_y)

	-- anchor this frame (so if the whole TheoryCraft window moves, things don't get weird)
	this:ClearAllPoints() -- May have already been done by the act of dragging it
	this:SetPoint("CENTER", this:GetParent(), "BOTTOMLEFT", offset_x, offset_y)

	-- Prevent this widget from being saved into layout-local.txt as it will break the anchoring at some point after OnLoad is fired.
	this:SetUserPlaced(false);

	-- also clear screen padding restrictions since the move is finished
	this:SetClampRectInsets(0,0,0,0)

	-- Save the offsets, scaled by parent frame size.
	TheoryCraft_Settings["buttontextx"] = offset_x / p_width
	TheoryCraft_Settings["buttontexty"] = offset_y / p_height
	--print('buttontextx: ' .. TheoryCraft_Settings["buttontextx"])
	--print('buttontexty: ' .. TheoryCraft_Settings["buttontexty"])
end

-- NOTE: can only be called after event VARIABLES_LOADED
function TheoryCraft_InitButtonTextOpts()
	--print('InitButtonTextOpts')
	--TheoryCraftFontPath:SetText(TheoryCraft_Settings["FontPath"])

	TheoryCraftColR:SetText(TheoryCraft_Settings["ColR"]*255)
	TheoryCraftColG:SetText(TheoryCraft_Settings["ColG"]*255)
	TheoryCraftColB:SetText(TheoryCraft_Settings["ColB"]*255)

	TheoryCraftColR2:SetText(TheoryCraft_Settings["ColR2"]*255)
	TheoryCraftColG2:SetText(TheoryCraft_Settings["ColG2"]*255)
	TheoryCraftColB2:SetText(TheoryCraft_Settings["ColB2"]*255)

	TheoryCraftFontSize:SetText(TheoryCraft_Settings["FontSize"])

	TheoryCraftGenBox_Text:SetText(TheoryCraft_Settings["GenerateList"])

	-- Also need to restore the position for the dummy text widget
	-- Since the dummy text is movable we cannot configure an anchor directly in the XML
	local dummy_text = _G['TheoryCraftActionButtonTextPos']
	local parent     = dummy_text:GetParent()

	-- In theory these should always have a value (initial load should create one), but just in case.
	local buttontextx = TheoryCraft_Settings["buttontextx"] or 0.5
	local buttontexty = TheoryCraft_Settings["buttontexty"] or 0.5

	local p_width, p_height = parent:GetSize()
	p_width  = round(p_width)  -- weird decimals, need rounding
	p_height = round(p_height)

	-- Anchor the frame (so if the whole TheoryCraft window moves, things don't get weird)
	dummy_text:ClearAllPoints() -- Just in case
	dummy_text:SetPoint("CENTER", parent, "BOTTOMLEFT", buttontextx*p_width, buttontexty*p_height)
end

-- Format the action button_text based on the significant placevalue configuration dropdown selected.
local function formattext(a, field, places)
	if places == nil then
		places = 0
	end
	if (field == "averagedam") or (field == "averageheal") then
		if TheoryCraft_Settings["dontcrit"] then
			field = field.."nocrit"
		end
	end
	if a[field] == nil then
		return nil
	end
	if (field == "maxoomdam")  or (field == "maxoomdamremaining")  or (field == "maxoomdamfloored") or
	   (field == "maxoomheal") or (field == "maxoomhealremaining") or (field == "maxoomhealfloored") then
		return round(a[field]/1000*10^places)/10^places.."k"
	end
	return round(a[field]*10^places)/10^places
end

-- NOTE: ActionButtonX & SpellButtonX are blizzard created frames of one sort or another.

-- This function creates the ButtonText font objects on each ActionButton that could possibly exist
-- REM: called after VARIABLES_LOADED
function TheoryCraft_AddButtonText(...)
	-- 12 spells per spellbook-page
	if SpellButton1 then
		for i = 1,12 do TheoryCraft_SetUpButton("SpellButton"..i, "SpellBook") end
	end

	if ActionButton1 then
		for i = 1,12 do TheoryCraft_SetUpButton("ActionButton"..i, "Flippable", i) end
		for i = 1,12 do TheoryCraft_SetUpButton("MultiBarRightButton"..i, "Special", 24+i) end
		for i = 1,12 do TheoryCraft_SetUpButton("MultiBarLeftButton"..i, "Special", 36+i) end
		for i = 1,12 do TheoryCraft_SetUpButton("MultiBarBottomRightButton"..i, "Special", 48+i) end
		for i = 1,12 do TheoryCraft_SetUpButton("MultiBarBottomLeftButton"..i, "Special", 60+i) end
	end
	-- TODO: probably defunct, used to be extra bars for stances/stealth/forms etc.
	if BonusActionButton1 then
		for i = 1,12 do TheoryCraft_SetUpButton("BonusActionButton"..i, "Bonus") end
	end
end

-- Helper function, transform a button_name into the button_frame reference
local function updatebutton(button_name)
	local button = getglobal(button_name)
	if button then
		-- REM: TheoryCraft_SetUpButton uses 3 arguments, but since its already setup, we only need 1
		TheoryCraft_ButtonUpdate(button)
	end
end

-- Just the main actionbar
-- REM: may be called many times due to changing pages.
function TheoryCraft_UpdateActionBarText()
	if not TheoryCraft_Data.TalentsHaveBeenRead then
		return
	end

	if ActionButton1 then
		for i = 1,12 do updatebutton("ActionButton"..i) end
	end
end

-- Just the spellbook
-- REM: may be called many times due to changing pages.
local function UpdateSpellBookText()
	if not TheoryCraft_Data.TalentsHaveBeenRead then
		return
	end

	-- 12 spells per spellbook-page
	if SpellButton1 then
		for i = 1,12 do updatebutton("SpellButton"..i) end
	end
end

-- This will handle changing the button color and position as well as what type of text should be shown
function TheoryCraft_UpdateAllButtonText(source)
	if not TheoryCraft_Data.TalentsHaveBeenRead then
		return
	end

	UpdateSpellBookText()
	TheoryCraft_UpdateActionBarText()

	if ActionButton1 then
		for i = 1,12 do updatebutton("MultiBarRightButton"..i) end
		for i = 1,12 do updatebutton("MultiBarLeftButton"..i) end -- ??? I think this is actually "Right2"
		for i = 1,12 do updatebutton("MultiBarBottomRightButton"..i) end
		for i = 1,12 do updatebutton("MultiBarBottomLeftButton"..i) end
	end
	-- TODO: probably defunct, used to be extra bars for stances/stealth/forms etc.
	if BonusActionButton1 then
		for i = 1,12 do updatebutton("BonusActionButton"..i) end
	end

	if _G['Bartender4'] ~= nil then
		for i = 1,120 do updatebutton("BT4Button"..i) end
	end
end

-- Helper to determine which actual ActionBar/ActionButton a spell was placed in, for purposes of ButtonText
-- This works by process of elimination
function TheoryCraft_FindActionButton(slot_id)
	local btn = slot_id_action_bar_map[slot_id] -- maybe nil
	-- If the ActionBar that this slot would be assigned to is currently shown.
	if btn ~= nil and btn:GetParent():IsVisible() then
		-- use the btn as is.
		return btn
	end
	-- otherwise, use the ActionButtonX
	local i = slot_id % 12
	return _G["ActionButton"..i]
end


-- NOTE: maybe this should be an event? ACTIONBAR_PAGE_CHANGED, what about UPDATE_BONUS_ACTIONBAR ?
hooksecurefunc("ChangeActionBarPage", function(i)
	--print("ChangeActionBarPage "..i)
	TheoryCraft_UpdateActionBarText()
end)


-- Don't use this, it is very spammy
-- NOTE: don't use OnUpdate, because that spams every frame (or something like that)
--[[
hooksecurefunc("ActionButton_Update", function(button)
	--print("ActionButton_Update")
	TheoryCraft_ButtonUpdate(button) -- defunct
end)
--]]

if SpellBookFrame_UpdateSpells then
    hooksecurefunc("SpellBookFrame_UpdateSpells", function(i)
        --print("SpellBookFrame_UpdateSpells")
        UpdateSpellBookText()
    end)
end

-- Update a specific button's text (position, color) as well as for any stat/buff changes
function TheoryCraft_ButtonUpdate(this, actionbar_slot_changed)
	if not TheoryCraft_Data.TalentsHaveBeenRead then
		--print("Skipped TheoryCraft_ButtonUpdate - talents not ready")
		return
	end

	-- REM: buttontext is a FontString created on each button during SetupButtons
	local buttontext = _G[this:GetName().."_TCText"]
	if not buttontext then 
		return
	end

	-- Not 100% sure if "Name" always exists, but it seems to be blank for non macros
	local macro_name  = _G[this:GetName().."Name"]
	local button_rank = _G[this:GetName().."_Rank"]

	-- -------------- Helper --------------
	local function toggle_btn_text_fn(show_btn_txt)
		if show_btn_txt then
			-- Show the button text
			buttontext:Show()
			-- Hide the macro_name
			if macro_name then macro_name:Hide() end
			-- Also hide button_rank
			if button_rank then button_rank:Hide() end
		else
			-- Hide the button text
			buttontext:Hide()
			-- Show the macro_name
			if macro_name then macro_name:Show() end
			-- Also show button_rank
			if button_rank then button_rank:Show() end
		end
	end
	-- --------------

	-- If buttontext checkbox is unchecked or the addon is entirely turned off
	if not TheoryCraft_Settings["buttontext"] or TheoryCraft_Settings["off"] then
		toggle_btn_text_fn()
		return
	end

	-- Try to find the spell data from whats in the button
	local spelldata
	-- REM: The ActionButtonID will be empty for spellbook items (obviously)
	if buttontext.type == "SpellBook" then
		local icon = _G[this:GetName().."SpellName"]
		local id   = icon:GetText()

		if (not icon:IsShown()) or (id == nil) then
			buttontext:Hide()
			id = nil
		end

		if id then
			-- NOTE: the subtext could be: "Rank 1" or "racial passive" or "journeyman" things like that.
			local rank = _G[this:GetName().."SubSpellName"]:GetText()
			rank = tonumber(TCUtils.findpattern(rank, "%d+")) or 0
			spelldata = TheoryCraft_GetSpellDataByName(id, rank)
		end

	-- type: "Special", "Flippable", "Bonus" ???
	else
		local action_slot = this:GetAttribute('action') or this.action
		spelldata = TheoryCraft_GetSpellDataByAction(action_slot)
	end

	-- if there is no (valid) spell on this button, also return.
	if not spelldata then
		toggle_btn_text_fn()
		return
	end

	-- font path is broken and not very useful
--[[
	if (buttontext.fontsize ~= TheoryCraft_Settings["FontSize"]) or
	   (buttontext.fontpath ~= TheoryCraft_Settings["FontPath"]) then
		buttontext.fontsize = TheoryCraft_Settings["FontSize"]
		buttontext.fontpath = TheoryCraft_Settings["FontPath"]
		buttontext:SetFont(TheoryCraft_Settings["FontPath"], buttontext.fontsize, "OUTLINE")
	end
--]]
	if (buttontext.fontsize ~= TheoryCraft_Settings["FontSize"]) then
		buttontext.fontsize = TheoryCraft_Settings["FontSize"]
		buttontext:SetFont("Fonts\\ARIALN.TTF", buttontext.fontsize, "OUTLINE")
	end

	if (buttontext.colr ~= TheoryCraft_Settings["ColR"]) or
	   (buttontext.colg ~= TheoryCraft_Settings["ColG"]) or
	   (buttontext.colb ~= TheoryCraft_Settings["ColB"]) or
	   (buttontext.colr2 ~= TheoryCraft_Settings["ColR2"]) or
	   (buttontext.colg2 ~= TheoryCraft_Settings["ColG2"]) or
	   (buttontext.colb2 ~= TheoryCraft_Settings["ColB2"]) then
		buttontext.colr = TheoryCraft_Settings["ColR"]
		buttontext.colg = TheoryCraft_Settings["ColG"]
		buttontext.colb = TheoryCraft_Settings["ColB"]
		buttontext.colr2 = TheoryCraft_Settings["ColR2"]
		buttontext.colg2 = TheoryCraft_Settings["ColG2"]
		buttontext.colb2 = TheoryCraft_Settings["ColB2"]
	end

	if (buttontext.buttontextx ~= TheoryCraft_Settings["buttontextx"]) or (buttontext.buttontexty ~= TheoryCraft_Settings["buttontexty"]) then
		buttontext.buttontextx = TheoryCraft_Settings["buttontextx"]
		buttontext.buttontexty = TheoryCraft_Settings["buttontexty"]
		buttontext:ClearAllPoints()
		-- rescale based on actual button dimensions
		local w,h = this:GetSize()
		-- TODO: using CENTER point seems a little bit further to the left than I think is ideal, but every other point looks much worse.
		buttontext:SetPoint("CENTER", this, "BOTTOMLEFT", TheoryCraft_Settings["buttontextx"]*w, TheoryCraft_Settings["buttontexty"]*h)
	end

	-- Must contain some properties to be valid
	if spelldata then
		local tryfirst  = formattext(spelldata, TheoryCraft_Settings["tryfirst"],  TheoryCraft_Settings["tryfirstsfg"])
		local trysecond = formattext(spelldata, TheoryCraft_Settings["trysecond"], TheoryCraft_Settings["trysecondsfg"])

		if tryfirst then
			buttontext:SetText(tryfirst)
			buttontext:SetTextColor(buttontext.colr, buttontext.colg, buttontext.colb)
		elseif trysecond then
			buttontext:SetText(trysecond)
			buttontext:SetTextColor(buttontext.colr2, buttontext.colg2, buttontext.colb2)
		end

		if tryfirst or trysecond then
			toggle_btn_text_fn(true)
			return
		end
	end

	-- In the case that spelldata was empty, or that tryfirst/trysecond result in no text
	toggle_btn_text_fn()
end


local updatePending = false 

local function TheoryCraft_InstantSpellbookRefresh()
    if not TheoryCraft_UpdateAllButtonText then return end
    
    if SpellBookFrame and SpellBookFrame:IsVisible() then
        TheoryCraft_UpdateAllButtonText('apply')
        updatePending = false
    end
end

-- Update when opening the spellbook
if SpellBookFrame then
    SpellBookFrame:HookScript("OnShow", function()
        if not updatePending then
            updatePending = true
            TheoryCraft_InstantSpellbookRefresh()
        end
    end)
end


-- Update when swaping tabs in spellbook
for i=1, 4 do
    local tabName = "SpellBookSkillLineTab" .. i
    local tab = _G[tabName]
    
    if tab then
        tab:HookScript("OnClick", function()
            if not updatePending then
                updatePending = true
                TheoryCraft_InstantSpellbookRefresh()
            end
        end)
    end
end


local TheoryCraftFallbackFrame = CreateFrame("Frame")
TheoryCraftFallbackFrame:RegisterEvent("PLAYER_ENTERING_WORLD") 
TheoryCraftFallbackFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")

TheoryCraftFallbackFrame:SetScript("OnEvent", function(self, event, ...)
    -- Check event type
    local unit = select(1, ...)
    
    if event == "PLAYER_ENTERING_WORLD" or (event == "UNIT_INVENTORY_CHANGED" and unit == "player") then
        if TheoryCraft_UpdateAllButtonText then
            -- On utilise 'apply' pour garantir un rafraîchissement complet des stats
            TheoryCraft_UpdateAllButtonText('apply') 
        end
    end
end)

-- Realtime updater: refresh visible action button texts periodically
-- This keeps damage/heal indicators on action buttons up-to-date without
-- requiring the user to open the spellbook or change target.
do
	local interval = 1 -- seconds
	if C_Timer and C_Timer.NewTicker then
		C_Timer.NewTicker(interval, function()
			if not TheoryCraft_Settings then return end
			if TheoryCraft_Settings["off"] then return end
			if not TheoryCraft_Settings["buttontext"] then return end
			-- Only refresh when main action buttons are visible to avoid needless work
			if ActionButton1 and ActionButton1:IsVisible() then
				TheoryCraft_UpdateActionBarText()
			end
		end)
	else
		-- Fallback: simple throttled OnUpdate frame
		local f = CreateFrame("Frame")
		local elapsed = 0
		f:SetScript("OnUpdate", function(self, el)
			elapsed = elapsed + el
			if elapsed < interval then return end
			elapsed = 0
			if not TheoryCraft_Settings then return end
			if TheoryCraft_Settings["off"] then return end
			if not TheoryCraft_Settings["buttontext"] then return end
			if ActionButton1 and ActionButton1:IsVisible() then
				TheoryCraft_UpdateActionBarText()
			end
		end)
	end
end
