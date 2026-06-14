-- DynamicTooltip --

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("LOOT_CLOSED")

local GameTooltip = GameTooltip
local UIParent = UIParent
local InCombatLockdown = InCombatLockdown
local IsMouselooking = IsMouselooking
local CursorIsVisible = CursorIsVisible
local UnitExists = UnitExists
local select = select
local GetMouseFoci = GetMouseFoci
local GetMouseFocus = GetMouseFocus

-- Anchor interception
hooksecurefunc("GameTooltip_SetDefaultAnchor", function(tooltip, parent)
    if not InCombatLockdown() then
        tooltip:SetOwner(parent, "ANCHOR_CURSOR_RIGHT", 39, -45)
    end
end)

-- Default anchor using exact fstack coordinates
local function setTooltipDefaultAnchor()
    GameTooltip:SetOwner(UIParent, "ANCHOR_NONE")
    GameTooltip:ClearAllPoints()
    GameTooltip:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -54, 97)
end

local function setTooltipCursorAnchor()
    GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR_RIGHT", 39, -45)
    GameTooltip:ClearAllPoints()
end

-- Force tooltip content regeneration
local function rebuildTooltip()
    -- 3D world or UnitFrames
    if UnitExists("mouseover") then
        GameTooltip:SetUnit("mouseover")
        GameTooltip:Show()
    else
        -- Action bars, buffs, etc.
        local focus
        if GetMouseFoci then
            focus = select(1, GetMouseFoci())
        elseif GetMouseFocus then
            focus = GetMouseFocus()
        end

        if focus and focus:GetScript("OnEnter") then
            focus:GetScript("OnEnter")(focus)
        end
    end
end

frame:SetScript("OnEvent", function(self, event)
    -- Restore tooltip hidden by loot interaction (Not working everytime? Need to check)
    if event == "LOOT_CLOSED" then
        if UnitExists("mouseover") then
            if not InCombatLockdown() then
                setTooltipCursorAnchor()
            else
                setTooltipDefaultAnchor()
            end
            rebuildTooltip()
        end
        return
    end

    -- Ignore combat state changes if tooltip is hidden
    if not GameTooltip:IsShown() then
        return
    end

    if event == "PLAYER_REGEN_DISABLED" then
        setTooltipDefaultAnchor()
        rebuildTooltip()
    elseif event == "PLAYER_REGEN_ENABLED" then
        setTooltipCursorAnchor()
        rebuildTooltip()
    end
end)

local updateTimer = 0
local lostTargetTimer = nil
frame:SetScript("OnUpdate", function(self, elapsed)
    updateTimer = updateTimer + elapsed
    
    if updateTimer >= 0.1 then
        updateTimer = updateTimer % 0.1
        
        if GameTooltip:IsShown() then
            if IsMouselooking() or (CursorIsVisible and not CursorIsVisible() and (IsMouseButtonDown("LeftButton") or IsMouseButtonDown("RightButton"))) then
                GameTooltip:Hide()
                lostTargetTimer = nil
                return
            end

            local owner = GameTooltip:GetOwner()
            local tooltipUnit = GameTooltip:GetUnit()
            local hoverFrame
            if GetMouseFoci then
                hoverFrame = select(1, GetMouseFoci())
            elseif GetMouseFocus then
                hoverFrame = GetMouseFocus()
            end

            -- Required to disable the fadeout glitch when a having a target and tooltip is anchored to mouse
            if owner == UIParent and tooltipUnit and not UnitExists("mouseover") then
                lostTargetTimer = (lostTargetTimer or 0) + 0.1
                if lostTargetTimer >= 0.1 then
                    GameTooltip:Hide()
                    lostTargetTimer = nil
                end
                return
            end
            lostTargetTimer = nil

            if owner and not owner:IsVisible() then
                GameTooltip:Hide()
                lostTargetTimer = nil
            end
        else
            lostTargetTimer = nil
        end
    end
end)