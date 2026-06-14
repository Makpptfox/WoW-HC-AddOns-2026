TheoryCraft_Data.TargetBuffs = {}
TheoryCraft_Data.PlayerBuffs = {}

local function TheoryCraft_AddAllBuffs(target, data, buffs)
	TheoryCraftTooltip:ClearLines()
	local i, buff, locale_table, defaulttarget, _, start, found, type
	if target == "player" then
		local _, _, _, _, _, _, meleemod = UnitDamage("player")
		data["Meleemodifier"]  = -1+meleemod
		data["Rangedmodifier"] = -1+meleemod
	end

	if buffs == "debuffs" then
		locale_table  = TheoryCraft_Debuffs
		defaulttarget = "target"
	else
		locale_table  = TheoryCraft_Buffs
		defaulttarget = "player"
	end
	-- TBC-TODO: rework this since the buff/debuff cap is no longer 16
	for i = 1, 16 do
		if buffs == "debuffs" then
			buff = UnitDebuff(target, i)
		else
			buff = UnitBuff(target, i)
		end
		if buff then
			TheoryCraftTooltipTextLeft1:SetText(nil)
			TheoryCraftTooltip:SetOwner(UIParent,"ANCHOR_NONE")
			if buffs == "debuffs" then
				TheoryCraftTooltip:SetUnitDebuff(target, i)
			else
				TheoryCraftTooltip:SetUnitBuff(target, i)
			end
			-- TODO: SetUnitBuff and SetUnitDebuff have a 3rd argument which is some sort of "filter" (possibly limited to buffs/debuffs the player can do something about, cast or dispell. Function is unclear.)
			ltext = TheoryCraftTooltipTextLeft2
			if (ltext) and (not ltext:IsVisible()) then
				ltext = nil
			end
			if (ltext) then ltext = ltext:GetText() end
			if ltext then
				-- Each row in the table is a sub-table with 2-4 keys: text, type, amount, target
				for k, v in pairs(locale_table) do
					if ((not v.target) and (target == defaulttarget)) or (v.target == target) then
						_, start, found = strfind(ltext, v.text)
						if _ then
							t = v.type
							if (v.amount == nil) then
								data[t] = (data[t] or 0) + tonumber(found)
							elseif (v.amount == "n/100") then
								data[t] = (data[t] or 0) + tonumber(found)/100
							elseif (v.amount == "totem") then
								data[t] = (data[t] or 0) + tonumber(found)/2*5
							elseif (v.amount == "hl") then
								data[t] = (data[t] or 0) + tonumber(found)/2.5*3.5
							elseif (v.amount == "fol") then
								data[t] = (data[t] or 0) + tonumber(found)/1.5*3.5
							else
								data[t] = (data[t] or 0) + v.amount
							end
						end
					end
				end
			end
		end
  	end
end


-- REM: This function is called upon PLAYER_LOGIN(dontgen==true) and whenever a player buff/debuff is changed (aura)
function TheoryCraft_UpdatePlayerBuffs(dontgen)
	local active_stance, has_changed = TCUtils.StanceFormName('UpdatePlayerBuffs')

	local redotalents = false
	-- travel/flight forms are definitely irrelevant. TBC-TODO: add moonkin/tree if necessary
	if TCUtils.CLASS == "DRUID" and has_changed and (active_stance == 'bear' or active_stance == 'cat') then
		redotalents = true
	end

	TheoryCraft_DeleteTable(TheoryCraft_Data.PlayerBuffs)
	TheoryCraft_AddAllBuffs("player", TheoryCraft_Data.PlayerBuffs) -- player buffs
	TheoryCraft_AddAllBuffs("player", TheoryCraft_Data.PlayerBuffs, "debuffs") -- player debuffs

	if dontgen then
		return
	end

	-- Update the button text for only the main action bar when stance changes.
	if has_changed then
		--print('Stance bar changed, UpdateActionBarText')
		TheoryCraft_UpdateActionBarText()
	end

	-- NOTE: this is only ever the case when druid form changes (some talents have specific effects in forms that should NOT apply to other forms)
	if redotalents then
		TheoryCraft_UpdateTalents(true) -- player buffs
	end
	TheoryCraft_LoadStats('player buffs')
	TheoryCraft_UpdateArmor() -- player buffs
	TheoryCraft_GenerateAll() -- player buffs
end

-- REM: This function is called upon PLAYER_LOGIN(dontgen==true) and whenever the current target is changed
-- QUESTION: should it also be called when the target gains/drops a buff?
function TheoryCraft_UpdateTargetBuffs(dontgen)
	local old  = {}
	local old2 = {}

	TCUtils.MergeIntoTable(TheoryCraft_Data.TargetBuffs, old)
	TheoryCraft_DeleteTable(TheoryCraft_Data.TargetBuffs)
	TheoryCraft_AddAllBuffs("target", TheoryCraft_Data.TargetBuffs) -- target buffs
	TheoryCraft_AddAllBuffs("target", TheoryCraft_Data.TargetBuffs, "debuffs") -- target debuffs

	if dontgen then
		return
	end

	TCUtils.MergeIntoTable(TheoryCraft_Data.Stats, old2)
	TheoryCraft_LoadStats('target buffs')
	if (TheoryCraft_IsDifferent(old, TheoryCraft_Data.TargetBuffs)) or (TheoryCraft_IsDifferent(old2, TheoryCraft_Data.Stats)) then
		TheoryCraft_UpdateArmor() -- target buffs
		TheoryCraft_GenerateAll() -- target buffs
	end
end

