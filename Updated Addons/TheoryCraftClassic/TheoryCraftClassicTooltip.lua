local _, class = UnitClass("PLAYER")
--local armormult

-- NOTE: this file only contains this one function (helpers ignored)


function TheoryCraft_AddTooltipInfo(game_tooltip_frame, dontshow)
	if TheoryCraft_Settings["off"] then return end

	local rgb -- This is for extracting colors from the capture groups during gsub (extra return values essentially)
	local leftline, rightline

	--[[
	local tooltipdata = nil
	if tooltipdata == nil then
		if (game_tooltip_frame:NumLines() == 1) and (getglobal(game_tooltip_frame:GetName().."TextLeft1"):GetText() ~= "Attack") then
			local _, _, name, rank = strfind(getglobal(game_tooltip_frame:GetName().."TextLeft1"):GetText(), "(.+)%((%d+)%)")
			print(name)
			print(rank)
			if not name then return nil end
			rank = tonumber(rank)

			local spellname, spellrank
			local i2 = 1
			while (true) do
				spellname, spellrank = GetSpellBookItemName(i2,BOOKTYPE_SPELL)
				if spellname == nil then return end
				spellrank = tonumber(TCUtils.findpattern(spellrank2, "%d+"))
				if spellrank == nil then spellrank2 = 0 end
				if ((spellname == name) or (name == string.sub(spellname, 1, string.len(name)))) and (spellrank == rank) then 
					game_tooltip_frame:SetSpell(i2,BOOKTYPE_SPELL) -- NOTE: this method no longer exists. See SetSpellByID
					return game_tooltip_frame
				end
				i2 = i2 + 1
			end

			print(spellname)
			print(spellrank)
		end
		game_tooltip_frame:Show()
		return game_tooltip_frame
	end
--]]

	-- Returns the name and ID of the item displayed on a GameTooltip.
	-- TODO: how does this work with macros?
	spellName, spellID = GameTooltip:GetSpell()

	-- TheoryCraft does not care if this tooltip is not for a spell of any sort. Ignore it!!!
	--print(spellName, spellID)
	if spellName == nil or spellID == nil then return end

	tooltipdata = TheoryCraft_GenerateSpellData(spellID)

	if tooltipdata == nil then return end

	--TCUtils.pretty_print(tooltipdata)

	-- First does this spell have a healing component?
	local show_heal_lines = (tooltipdata["minheal"] ~= nil)
	-- Second, if its a drain or holynova type effect, do NOT display the healing portion of these spells UNLESS checkbox "both heal and damage" is active.
	if ((tooltipdata["drain"] == 1) or (tooltipdata["holynova"] == 1)) and (not TheoryCraft_Settings["healanddamage"]) then
		show_heal_lines = false
	end

	-- ~~~~~~~~~~ Gsub replacer functions ~~~~~~~~~~
	-- When invoked as 3rd param to gusb, the function is called every time gsub finds a match; the arguments to this function are the captures,
	-- while the value that the function returns is used as the replacement string.
	-- see: https://www.lua.org/pil/20.3.html

	-- Execution order is replace_var, resolve_or, resolve_if, do_color

	local function do_color(r, g, b)
		r = tonumber(r)
		g = tonumber(g)
		b = tonumber(b)
		-- if missing
		if (not r) or (not g) or (not b) then return "invalid colour" end
		-- if out of range
		if (r > 1) or (r < 0) or (g > 1) or (g < 0) or (b > 1) or (b < 0) then return "invalid colour" end

		-- Save the color, for future use, but NOT embed the color string within this section of the tooltip.
		if true then
			-- REM: declared at AddTooltipInfo level.
			rgb = {r,g,b}
			return ""

		-- NOTE: This will never be hit, but maintained for future reference.
		else
			-- translate the decimal values into a string color escape sequence
			return "|c"..string.format("%.2x", math.floor(r*255))..
						 string.format("%.2x", math.floor(g*255))..
						 string.format("%.2x", math.floor(b*255)).."ff"
		end
	end

	-- $VAR$ as defined in the tooltip format strings
	local function replace_var(var)
		local returnvalue
		-- n2 is the capture group
		-- so save it, then delete it.
		local _, _, n2 = strfind(var, "|(.+)|")
		var = string.gsub(var, "%|.+%|", "")

		-- any numeric var could be in this format "$critchance,1$"
		-- So extract the numeric precision from the variable string.
		local _, _, precision = strfind(var, ",(%d+)")
		if precision then
			precision = tonumber(precision)
			var = string.gsub(var, ",%d+", "")
		else
			precision = 0
		end

		-- Text only replacements (not using calculated spell data)
		local tmp
		if var == "hitorheal" then
			tmp = TheoryCraft_TooltipOrs.hitorhealhit
			if tooltipdata.isheal then
				tmp = TheoryCraft_TooltipOrs.hitorhealheal
			end
			return tmp
		end
		if var == "damorheal" then
			tmp = TheoryCraft_TooltipOrs.damorhealdam
			if tooltipdata.isheal then
				tmp = TheoryCraft_TooltipOrs.damorhealheal
			end
			return tmp
		end
		if var == "damorap"   then
			tmp = TheoryCraft_TooltipOrs.damorapdam
			if tooltipdata.ismelee or tooltipdata.isranged then
				tmp = TheoryCraft_TooltipOrs.damorapap 
			end
			return tmp
		end

		-- If the variable in this line is a healing type AND we aren't supposed to show healing lines, we can skip it
		if (not show_heal_lines) and ((var == "nextcritheal") or (var == "healrange") or (var == "hps") or (var == "hpsdam") or (var == "crithealrange")) then
			return "$NOT FOUND$"
		end

		-- A spellrank of 0 means spell has no ranks, so skip it.
		if var == "spellrank" and tooltipdata.spellrank == 0 then
			return "$NOT FOUND$"
		end

		-- If spellpen is 0, skip it.
		if var == "penetration" and tonumber(tooltipdata["penetration"]) == 0 then
			return "$NOT FOUND$"
		end
		-- if mana-cost is skipped (autoshot only apparently)
		if var == "basemanacost" and tooltipdata["dontshowmana"] then
			return "$NOT FOUND$"
		end

		-- if an outfit is active, show that in the tooltip info
		if TheoryCraft_Data["outfit"] ~= 1 then
			if var == "outfitname" then
				if (TheoryCraft_Data["outfit"] == 2) and (TheoryCraft_Settings["CustomOutfitName"]) then
					return TheoryCraft_Settings["CustomOutfitName"]
				else
					if TheoryCraft_Outfits[TheoryCraft_Data["outfit"]] then
						return TheoryCraft_Outfits[TheoryCraft_Data["outfit"]].name
					end
				end
			end
		end

		-- This section handles ranges.
		-- If (the min == the max) then only show a single number instead (not a range afterall)
		-- TODO: ideally in the single number case, set "returnvalue", and let the final "return round()" do the work.

		if var == "healrange" and tooltipdata["minheal"] then
			if tooltipdata["minheal"] == tooltipdata["maxheal"] then
				return TCUtils.round(tooltipdata["minheal"], precision)
			else
				return TCUtils.round(tooltipdata["minheal"], precision) .. TheoryCraft_Locale.to .. TCUtils.round(tooltipdata["maxheal"], precision)
			end
		end

		if var == "dmgrange" and tooltipdata["mindamage"] then
			if tooltipdata["mindamage"] == tooltipdata["maxdamage"] then
				return TCUtils.round(tooltipdata["mindamage"], precision)
			else
				return TCUtils.round(tooltipdata["mindamage"], precision) .. TheoryCraft_Locale.to .. TCUtils.round(tooltipdata["maxdamage"], precision)
			end
		end

		if ((var == "critdmgrange") or (var == "igniterange")) and (tooltipdata["critdmgmin"]) then
			if ((TheoryCraft_Settings["sepignite"]) and (var == "critdmgrange")) and (tooltipdata["critdmgmaxminusignite"]) then
				if tooltipdata["critdmgminminusignite"] == tooltipdata["critdmgmaxminusignite"] then
					return TCUtils.round(tooltipdata["critdmgminminusignite"], precision)
				else
					return TCUtils.round(tooltipdata["critdmgminminusignite"], precision) .. TheoryCraft_Locale.to .. TCUtils.round(tooltipdata["critdmgmaxminusignite"], precision)
				end
			else
				if (tooltipdata["critdmgminminusignite"] == nil) and (var == "igniterange") then
					return "$NOT FOUND$"
				end
				if tooltipdata["critdmgmin"] == tooltipdata["critdmgmax"] then
					return TCUtils.round(tooltipdata["critdmgmin"], precision)
				else
					return TCUtils.round(tooltipdata["critdmgmin"], precision) .. TheoryCraft_Locale.to .. TCUtils.round(tooltipdata["critdmgmax"], precision)
				end
			end
		end

		if ((var == "crithealrange") and (tooltipdata["crithealmin"])) then
			if tooltipdata["crithealmin"] == tooltipdata["crithealmax"] then
				return TCUtils.round(tooltipdata["crithealmin"], precision)
			else
				return TCUtils.round(tooltipdata["crithealmin"], precision) .. TheoryCraft_Locale.to .. TCUtils.round(tooltipdata["crithealmax"], precision)
			end
		end

		if n2 then
			if tooltipdata[n2]      == nil then return "$NOT FOUND$" end
			if tooltipdata[n2][var] == nil then return "$NOT FOUND$" end
			returnvalue = tooltipdata[n2][var]
		else
			-- catchall everything else that doesn't have special logic above.
			if tooltipdata[var] == nil then return "$NOT FOUND$" end
			returnvalue = tooltipdata[var]
		end

		if (TCUtils.array_include({"maxoomdam", "maxevocoomdam", "maxoomheal", "maxevocoodam"}, var)) then
			if returnvalue < 0 then 
				returnvalue = "Infinite"  
			else 
				returnvalue = TCUtils.round(returnvalue/1000, 2).."k"
			end
		end

		if (tonumber(returnvalue)) then
			return TCUtils.round(returnvalue, precision)
		else
			return returnvalue
		end
	end -- replace_var

	-- REM: "%" is the escape character, so %% = %, %$ = $
	local function resolve_or(first, second)
		if strfind(first,  "%$NOT FOUND%$") then first  = nil end
		if strfind(second, "%$NOT FOUND%$") then second = nil end
		return first or second or "$NOT FOUND$"
	end

	local function resolve_if(line)
		if strfind(line, "%$NOT FOUND%$") then return "" end
		return line
	end

	-- ~~~~~~~~~~ end replacers ~~~~~~~~~~

	-- This exists so that "i" and "tempstring" cease to exist afterward
	do
		tooltipdata["cooldownremaining"] = nil
		local i = 1
		local tmpstring
		while getglobal(game_tooltip_frame:GetName().."TextLeft"..i) do
			tmpstring = getglobal(game_tooltip_frame:GetName().."TextLeft"..i):GetText() or ""
			if string.find(tmpstring, (TheoryCraft_Locale.CooldownRem) or "Cooldown remaining: ") then
				tooltipdata["cooldownremaining"] = getglobal(game_tooltip_frame:GetName().."TextLeft"..i):GetText()
			end
			i = i + 1
		end
	end

	-- Empty the entire tooltip, TC will repopulate it from scratch
	game_tooltip_frame:ClearLines()

	local _, titletext
	for _, line in ipairs(TheoryCraft_TooltipFormat) do
		-- Handle titles (special case)
		if line.title then
			-- Titles are stored until some line in their section is going to be displayed, and ONLY then displayed (once)
			titletext = line.title
			-- continue
		else
			local show = false

			-- REM: can be either "true" or a string matching the condition that must be fulfilled
			if line.show == true then
				-- simplest case, always show.
				show = true

			elseif line.show == "critmelee" then
				show = (TheoryCraft_Settings["crit"]) and ((tooltipdata.ismelee) or (tooltipdata.isranged))

			elseif line.show == "critwithdam" then
				show = (TheoryCraft_Settings["crit"] and TheoryCraft_Settings["critdam"]) and (tooltipdata.ismelee == nil) and (tooltipdata.isranged == nil)

			elseif line.show == "critwithoutdam" then
				show = (TheoryCraft_Settings["crit"] and (not TheoryCraft_Settings["critdam"])) and (tooltipdata.ismelee == nil) and (tooltipdata.isranged == nil)

			elseif line.show == "averagedam" then
				show = TheoryCraft_Settings["averagedam"] and (not TheoryCraft_Settings["averagedamnocrit"])

			elseif line.show == "averagedamnocrit" then
				show = TheoryCraft_Settings["averagedam"] and TheoryCraft_Settings["averagedamnocrit"]

			elseif line.show == "max" then
				show = TheoryCraft_Settings["max"] and (not TheoryCraft_Settings["maxtime"])

			elseif line.show == "maxtime" then
				show = TheoryCraft_Settings["max"] and TheoryCraft_Settings["maxtime"]

			elseif line.show == "maxevoc" then
				show = TheoryCraft_Settings["maxevoc"] and (not TheoryCraft_Settings["maxtime"])

			elseif line.show == "maxevoctime" then
				show = TheoryCraft_Settings["maxevoc"] and TheoryCraft_Settings["maxtime"]

			else
				-- get whatver the corresponding checkbox state is
				show = TheoryCraft_Settings[line.show]
			end

			-- invert whatever the resulting state is
			if line.inverse then show = (not show) end

			-- REM: can the line be shown according to checkbox settings & the most basic melee/ranged filtering
			-- Essentially a continue statement if not to be shown
			if show then
				-- Handle left
				leftline = line.left
				if leftline then
					leftline = string.gsub(leftline, "%$(.-)%$", replace_var)
					leftline = string.gsub(leftline, "#OR(.-)/(.-)OR#", resolve_or)
					leftline = string.gsub(leftline, "#IF(.-)IF#", resolve_if)
					-- Nil it out if necessary
					if strfind(leftline, "%$NOT FOUND%$") then leftline = nil end
				end

				-- Handle right
				rightline = line.right
				if rightline then
					rightline = string.gsub(rightline, "%$(.-)%$", replace_var)
					rightline = string.gsub(rightline, "#OR(.-)/(.-)OR#", resolve_or)
					rightline = string.gsub(rightline, "#IF(.-)IF#", resolve_if)
					-- Nil it out if necessary
					if strfind(rightline, "%$NOT FOUND%$") then rightline = nil end
				end

				-- Reset the color to default (may be overridden by line specific configs)
				rgb = TheoryCraft_Colours["AddedLine"]
				local l_rgb, r_rgb -- right and left specific override colors
				if leftline then
					-- REM: ".-" is a lazy match
					-- REM: color captures are stored into "rgb"
					leftline = string.gsub(leftline, "#c(.-),(.-),(.-)#", do_color)
					-- set both left and right color to the same
					l_rgb = rgb
					r_rgb = rgb
				end

				if rightline then
					-- REM: color captures are stored into "rgb"
					rightline = string.gsub(rightline, "#c(.-),(.-),(.-)#", do_color)
					r_rgb = rgb
				end

				-- Now that we know whether the line has data to be displayed
				-- Handle title (as needed)
				if titletext and leftline then
					if TheoryCraft_Settings["titles"] then
						-- always white. TODO: do we want to configure this in Colours.lua?
						game_tooltip_frame:AddLine(titletext, 1,1,1)
					end
					titletext = nil
				end

				-- NOTE: Configs with right lines will never wrap
				if leftline and rightline then
					-- Adds Line to tooltip with textLeft on left side of line and textRight on right side 
					game_tooltip_frame:AddDoubleLine(leftline, rightline, l_rgb[1], l_rgb[2], l_rgb[3], r_rgb[1], r_rgb[2], r_rgb[3])
				elseif leftline then
					game_tooltip_frame:AddLine(leftline, l_rgb[1], l_rgb[2], l_rgb[3], line.wrap)
				end
				-- If there is only a non-nil rightline, do nothing.
			end -- end "continue"
		end
	end -- end for pairs(TheoryCraft_TooltipFormat)

	game_tooltip_frame:Show()
end