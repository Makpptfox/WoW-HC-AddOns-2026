-- RaidDispelHighlight --

local CONFIG = {
    PULSE_SPEED = 4,
    COLORS = {
        Curse   = {r=0.6, g=0.0, b=1.0},
        Disease = {r=0.6, g=0.4, b=0.0},
        Magic   = {r=0.2, g=0.6, b=1.0},
        Poison  = {r=0.0, g=0.6, b=0.0},
    }
}

local playerClass = select(2, UnitClass("player"))
local canCure = {}
local activeFrames = {} 
local frameStates = {}

-- Setup dispel capabilities based on player class
local function InitDispelLogic()
    local classes = {
        PRIEST = { Magic = true, Disease = true },
        MAGE   = { Curse = true },
        DRUID  = { Poison = true, Curse = true },
        PALADIN = { Poison = true, Disease = true, Magic = true }
    }
    canCure = classes[playerClass] or {}
end

-- Scan for dispellable debuffs
local function UpdateFrameAuras(frame)
    if not frame.unit or frame:IsForbidden() then return end
    
    local found = {}
    for i = 1, 40 do
        local _, _, _, debuffType = UnitDebuff(frame.unit, i)
        if not _ then break end
        
        if debuffType and canCure[debuffType] then
            local alreadyListed = false
            for _, v in ipairs(found) do 
                if v == debuffType then alreadyListed = true break end 
            end
            if not alreadyListed then table.insert(found, debuffType) end
        end
    end

    if #found > 0 then
        activeFrames[frame] = found
    else
        activeFrames[frame] = nil
        frameStates[frame] = nil
    end
end

-- Animation handling
local function OnUpdate()
    local now = GetTime()
    -- Use cosine to ensure alpha starts at 0 (base color)
    local alpha = (1 - math.cos(now * CONFIG.PULSE_SPEED)) / 2 
    
    for frame, debuffs in pairs(activeFrames) do
        if frame:IsVisible() and frame.unit then
            if not frameStates[frame] then 
                frameStates[frame] = { index = 1, lastSwitch = 0 } 
            end
            
            local state = frameStates[frame]

            -- Rotate debuff types only when pulse is near 0
            if #debuffs > 1 and alpha < 0.05 and (now - state.lastSwitch) > 0.5 then
                state.index = (state.index % #debuffs) + 1
                state.lastSwitch = now
            end

            local currentType = debuffs[state.index] or debuffs[1]
            local targetColor = CONFIG.COLORS[currentType]
            
            -- Get settings base color (class color or the default one)
            local _, unitClass = UnitClass(frame.unit)
            local baseColor = RAID_CLASS_COLORS[unitClass] or {r=0, g=1, b=0}
            
            frame.healthBar:SetStatusBarColor(
                baseColor.r + (targetColor.r - baseColor.r) * alpha,
                baseColor.g + (targetColor.g - baseColor.g) * alpha,
                baseColor.b + (targetColor.b - baseColor.b) * alpha
            )
        else
            activeFrames[frame] = nil
            frameStates[frame] = nil
        end
    end
end

local core = CreateFrame("Frame")
core:SetScript("OnUpdate", OnUpdate)
core:RegisterEvent("PLAYER_LOGIN")

core:SetScript("OnEvent", function()
    InitDispelLogic()
    hooksecurefunc("CompactUnitFrame_UpdateAuras", UpdateFrameAuras)
end)