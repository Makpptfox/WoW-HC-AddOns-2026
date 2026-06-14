-- This file contains utility functions only that are broadly useful in multiple other files.
-- FUTURE: this could be copied into other mods if it made sense to do so.

-- Only global in this file.
TCUtils = {}

-- Set the Race and Class for this current session (obviously cannot change without logout)
do
	-- TODO: move these API calls into API wrappers?
	-- first param is localized string, which we can ignore
	local _, class = UnitClass("player")
	-- see: https://wowpedia.fandom.com/wiki/API_UnitRace
	local _, race  = UnitRace("player")

	TCUtils.RACE  = race
	TCUtils.CLASS = class
end

local active_stance = 'none'

-- Returns:
--   nil  if class has no stances
--   none if no stances for this class are active
--   name of the active form/stance
-- NOTE: src is purely for debugging
TCUtils.StanceFormName = function(src)
	--if src then
	--	print('StanceFormName', src)
	--end

	local num_forms = GetNumShapeshiftForms()
	if num_forms == 0 then
		return nil
	end
	local active_name = 'none'

	-- NOTE: cannot rely on absolute positionals for any stance/form because someone might skip training, or not have it talented.
	--       GetNumShapeshiftForms() always returns the number you have, not the maximum number you COULD have.
	local spellId_map = {
		-- warrior
		[2457]  = 'battle',
		[71]    = 'defensive',
		[2458]  = 'berserker',
		-- druid
		[5487]  = 'bear',
		[9634]  = 'bear', -- direbear
		[1066]  = 'aquatic',
		[768]   = 'cat',
		[783]   = 'travel',
		[33943] = 'flight',
		[40120] = 'flight', -- swift flight
		[24858] = 'moonkin',
		[33891] = 'tree'
		-- NOTE: paladin auras are technically stances, but are skipped for now. Too many ranks to deal with. FUTURE-TODO
	}

	-- NOTE: alternatively could query the stance # and compare to a table of spellIDs (and ignore class entirely)
	for i=1, num_forms, 1 do
		--iconID, active, castable, spellId = GetShapeshiftFormInfo(index)
		local _, active, _, spellId = GetShapeshiftFormInfo(i)

		if active then
			if TCUtils.CLASS == 'ROGUE' then
				-- multiple ranks of stealth, its all the same
				active_name = 'stealth'

			else
				-- look up the stance by the spellId
				active_name = spellId_map[spellId]
			end
			-- we found the active one, don't need to keep checking
			break
		end
	end

	-- Determine changed status
	-- FUTURE-TODO: If we need to know whether stance changed in multiple different locations (that may happen in arbitrary order)
	--              then this instant update of current => old may not be sustainable.
	--              ideally we need some sort of custom event to be triggered, but I don't think that is actually possible.
	local has_changed = (active_stance ~= active_name)
	--print(active_stance, active_name)
	-- Update the currently active stance/form
	active_stance = active_name

	return active_name, has_changed
end

-- /run TCUtils.DebugPoints('FrameGlobalName')
TCUtils.DebugPoints = function(name)
	local frame = _G[name]
	if frame == nil then
		print('cannot find: ' .. name)
		return
	end
	local n = frame:GetNumPoints()
	print('num points: '..n)
	local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint(1)
	local relativeName = 'Unknown'
	if relativeTo ~= nil then
		relativeName = relativeTo:GetName()
	end
	print('point:', point)
	print('relativeName:', relativeName)
	print('relativePoint:', relativePoint)
	print('xoffset:', xOfs)
	print('yoffset:', yOfs)
end

TCUtils.DebugChildren = function(name)
	local frame = _G[name]
	if frame == nil then
		print('cannot find: ' .. name)
		return
	end
	local child_frames  = { frame:GetChildren() }
	local child_regions = { frame:GetRegions()  } 
	for _, c in ipairs(child_frames) do
		print(c:GetName())
	end 
	for _, c in ipairs(child_regions) do
		print(c:GetName())
	end
end

-- Recursively writes table data in a lua parsable format.
TCUtils.dump = function(o)
	if type(o) == 'table' then
	   local s = '{ '
	   for k,v in pairs(o) do
		  if type(k) ~= 'number' then k = '"'..k..'"' end
		  s = s .. '['..k..'] = ' .. TCUtils.dump(v) .. ','
	   end
	   return s .. '} '
	else
	   return tostring(o)
	end
end

-- testdata
-- local xyz = { a="foobar", b=100, c={'x', 'y', 'z'}, d={h="hello", i={j="jello", k={l="lunatic", m={n="nope"}}, x="be with you" }}, e="egg"}; TCUtils.pretty_print(xyz)
-- local xyz = { a=TCUtils.dump,  b=100, d={}, x="sukoshi"}; TCUtils.pretty_print(xyz)
TCUtils.pretty_print = function(tbl, indent)
	indent = indent or ""
	-- 3 layers deep max
	if string.len(indent) > 9 then
		print(indent, '[[maximum depth]]')
		return
	end
	-- NOTE: at the top level, we expect to recieve a table as input... but just in case
	if type(tbl) ~= 'table' then
		print(indent, tostring(tbl))
		return
	end

	-- First use a temp table to sort the keys
	local tkeys = {}
	for k in pairs(tbl) do table.insert(tkeys, k) end
	table.sort(tkeys)

	for _, k in ipairs(tkeys) do
		local v = tbl[k]
		if type(v) == 'table' then
			print(indent, tostring(k)..': (table)')
			-- increase indent by 3 for the next recursion
			TCUtils.pretty_print(v, indent.."   ")

		elseif type(v) == 'function' then
			print(indent, tostring(k)..': (func)')
		else
			print(indent, tostring(k)..':', tostring(v))
		end
	end
end

TCUtils.findpattern = function(text, pattern, start)
	if (text and pattern and (string.find(text, pattern, start))) then
		return string.sub(text, string.find(text, pattern, start))
	else
		return ""
	end
end

-- NOTE: this returns a string
TCUtils.round = function(num, precision)
	if (precision == nil) then precision = 0 end
	if (num == nil) then num = 0 end
	-- NOTE: There is not a Math function that does this.
	return string.format("%."..precision.."f", num)
end

-- Quick and dirty way of testing if a value is found within an array-like table.
-- We do this by transforming an array-like table {'a','b','c'}
-- into a truth_table {'a'=true, 'b'=true, 'c'=true} so we can quickly tell that any key returning true exists.
-- We then cache the result into truth_tables so that we only have to do this transformation once.
local truth_tables = {}
TCUtils.array_include = function(arr, val)
	-- Since {'a', 'b'} ~= {'a', 'b'} in lua, we have to first stringify the table before using it as a key.
	-- REM: order matters
	local str = table.concat(arr, ',')
	-- If the transformation hasn't already been done.
	if not truth_tables[str] then
		--print("Creating truthtable")
		local tmp = {}
		-- transform it into a truth_table
		for _, l in ipairs(arr) do tmp[l] = true end
		truth_tables[str] = tmp
	end
	-- using the truth_table as a proxy, does the value exist?
	return truth_tables[str][val]
end

-- Recursively merge contents from tab1 into tab2
TCUtils.MergeIntoTable = function(tab1, tab2)
	for k, v in pairs(tab1) do
		if type(v) == "table" then
			-- If the destination value doesn't happen to be a table,
			-- the best we can do is overwrite it with a new empty table.
			if type(tab2[k] ~= "table") then
				tab2[k] = {}
			end
			-- recursively continue the merge
			TCUtils.MergeIntoTable(v, tab2[k])
		else
			tab2[k] = v
		end
	end
end


-- Copied from: https://wowwiki-archive.fandom.com/wiki/UIOBJECT_GameTooltip#Example:_Looping_through_all_tooltip_lines
-- Looks like there are 20 lines by default (left and right each, so 40 text regions)
-- then an additional 10 textures, and 2 others (which also say textures, but don't have a name)
-- total of 52 sub-regions
-- however extras CAN be created
-- NOTE: empty spacer lines are printed
-- EXAMPLE: TC_EnumerateTooltipLines_helper(TheoryCraftTooltip:GetRegions())
function TC_EnumerateTooltipLines_helper(...)
	-- REM: "#" is the length operator ( example: mytable = {1,2,3}; print(#mytable) => 3 )
	-- TODO: couldn't I use instead:
	-- for k, v in pairs(arg) do -- where arg is the table of arguments collected within "..."
    for i = 1, select("#", ...) do
		-- REM: returns all arguments from index "i" and beyond.
		--      since we only store the first one as "region" we are getting them 1 at a time.
        local region = select(i, ...)
        if region and region:GetObjectType() == "FontString" then
            local text = region:GetText() -- string or nil
			if text then
				print(region:GetName(), 'FontString', i, text)
			end
		--elseif region then
		--	print(region:GetName(), region:GetObjectType(), i)
        end
    end
end

-- -------------------------------------------
