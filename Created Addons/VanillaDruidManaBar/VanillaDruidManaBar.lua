-- VanillaDruidManaBar --

local addonName, addon = ...

local _, class = UnitClass("player")
if class ~= "DRUID" then
    return
end

local previousMana = UnitPower("player", 0)
local nextTickTime = 0
local fsrEndTime = 0
local waitingForFirstTick = false

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("UNIT_DISPLAYPOWER")
f:RegisterEvent("UNIT_POWER_UPDATE")
f:RegisterEvent("UNIT_MAXPOWER")
f:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")

f:SetScript("OnUpdate", function()
    previousMana = UnitPower("player", 0)
end)

local bar = CreateFrame("StatusBar", "VanillaDruidManaBar", PlayerFrame)
bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
bar:SetStatusBarColor(0, 0, 1)
bar:EnableMouse(true)
bar:SetMovable(true)
bar:RegisterForDrag("LeftButton")
bar:SetClampedToScreen(true)
bar:Hide()

-- text overlay sublevel 1
local textLeft = bar:CreateFontString(nil, "ARTWORK", "TextStatusBarText")
textLeft:SetDrawLayer("ARTWORK", 7) -- force override template layer
textLeft:SetPoint("LEFT", bar, "LEFT", 5, 0)

local textRight = bar:CreateFontString(nil, "ARTWORK", "TextStatusBarText")
textRight:SetDrawLayer("ARTWORK", 7)
textRight:SetPoint("RIGHT", bar, "RIGHT", -4, 0)

-- spark overlay sublevel 2
local spark = bar:CreateTexture(nil, "OVERLAY", nil, 1)
spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
spark:SetBlendMode("ADD")
spark:SetWidth(18)
spark:Hide()

-- border overlay sublevel 3
local border = bar:CreateTexture(nil, "OVERLAY", nil, 2)
border:SetPoint("CENTER", bar, "CENTER", 0, -2)
border:SetTexture("Interface\\AddOns\\VanillaDruidManaBar\\VanillaDruidManaBar.png")

local function UpdateDepth()
    if VDManaBar and not VDManaBar.locked then
        -- float above ui for easier dragging
        bar:SetFrameStrata("HIGH")
        bar:SetFrameLevel(PlayerFrame:GetFrameLevel() + 10)
    else
        bar:SetFrameStrata("BACKGROUND")
        bar:SetFrameLevel(math.max(1, PlayerFrame:GetFrameLevel() - 1))
    end
end

bar:SetScript("OnEnter", function(self)
    if VDManaBar and not VDManaBar.locked then
        GameTooltip_SetDefaultAnchor(GameTooltip, self)
        GameTooltip:SetText("Move me to the correct position then lock me in the options.", 1.0, 1.0, 1.0)
        GameTooltip:Show()
    end
end)

bar:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

bar:SetScript("OnUpdate", function(self)
    local currMana = UnitPower("player", 0)
    local maxMana = UnitPowerMax("player", 0)
    local now = GetTime()
    
    if VDManaBar and VDManaBar.trackTicks and currMana < maxMana then
        local w = self:GetWidth()
        local offset = 2
        local travelWidth = w - (offset * 2)
        
        if now < fsrEndTime then
            spark:Show()
            local progress = (fsrEndTime - now) / 5
            progress = math.max(0, math.min(1, progress))
            
            spark:SetPoint("CENTER", self, "LEFT", offset + (progress * travelWidth), 0)
            spark:SetVertexColor(1, 0, 0)
        elseif waitingForFirstTick then
            spark:Hide()
        else
            spark:Show()
            if nextTickTime == 0 then nextTickTime = now + 2 end
            while now >= nextTickTime do
                nextTickTime = nextTickTime + 2
            end
            
            local progress = 1 - ((nextTickTime - now) / 2)
            progress = math.max(0, math.min(1, progress))
            
            spark:SetPoint("CENTER", self, "LEFT", offset + (progress * travelWidth), 0)
            spark:SetVertexColor(1, 1, 1)
        end
    else
        spark:Hide()
    end
end)

local function UpdateFontSize(size)
    local font, _, flags = textLeft:GetFont()
    textLeft:SetFont(font, size, flags)
    textRight:SetFont(font, size, flags)
end

local function UpdateMana()
    local maxMana = UnitPowerMax("player", 0)
    local currMana = UnitPower("player", 0)
    
    bar:SetMinMaxValues(0, maxMana)
    bar:SetValue(currMana)
    
    if VDManaBar.showPercent and maxMana > 0 then
        textLeft:SetText(math.floor((currMana / maxMana) * 100) .. "%")
    else
        textLeft:SetText("")
    end
    
    if VDManaBar.showValue then
        textRight:SetText(currMana)
    else
        textRight:SetText("")
    end
end

local function UpdateVisibility()
    if UnitPowerType("player") ~= 0 then
        bar:Show()
        UpdateMana()
    else
        bar:Hide()
    end
end

local function UpdateBarSize(w, h)
    bar:SetSize(w, h)
    border:SetSize(w + 35, h + 8)
    spark:SetHeight(h + 10)
end

bar:SetScript("OnDragStart", function(self)
    if VDManaBar and not VDManaBar.locked then
        self:StartMoving()
    end
end)

bar:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    
    local x = self:GetLeft() - PlayerFrame:GetLeft()
    local y = self:GetBottom() - PlayerFrame:GetBottom()
    
    VDManaBar.point = "BOTTOMLEFT"
    VDManaBar.relPoint = "BOTTOMLEFT"
    VDManaBar.x = x
    VDManaBar.y = y
    
    self:ClearAllPoints()
    self:SetPoint(VDManaBar.point, PlayerFrame, VDManaBar.relPoint, VDManaBar.x, VDManaBar.y)
    
    if VDManaBarXInput then VDManaBarXInput:SetText(tostring(math.floor(x))) end
    if VDManaBarYInput then VDManaBarYInput:SetText(tostring(math.floor(y))) end
end)

local function CreateInput(name, parent, width, labelText, isNumeric, getFunc, setFunc)
    local box = CreateFrame("EditBox", name, parent, "InputBoxTemplate")
    box:SetSize(width, 20)
    box:SetAutoFocus(false)
    box:SetNumeric(isNumeric)
    
    local lbl = box:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    lbl:SetPoint("BOTTOMLEFT", box, "TOPLEFT", -5, 5)
    lbl:SetText(labelText)

    box:SetScript("OnEnterPressed", function(self)
        local val = tonumber(self:GetText())
        if val then setFunc(val) end
        self:SetText(tostring(math.floor(getFunc())))
        self:ClearFocus()
    end)
    
    box:SetScript("OnEscapePressed", function(self)
        self:SetText(tostring(math.floor(getFunc())))
        self:ClearFocus()
    end)
    
    box:SetText(tostring(math.floor(getFunc())))
    box:SetCursorPosition(0)
    return box
end

local function InitSettingsPanel()
    local panel = CreateFrame("Frame")
    panel.name = "VanillaDruidManaBar"

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 10, -15)
    title:SetText("VanillaDruidManaBar")

    local btnReset = CreateFrame("Button", "VDManaBarResetButton", panel, "UIPanelButtonTemplate")
    btnReset:SetSize(120, 22)
    btnReset:SetPoint("TOPRIGHT", -10, -15)
    btnReset:SetText("Reset position")
    btnReset:SetScript("OnClick", function()
        VDManaBar.point = "TOPLEFT"
        VDManaBar.relPoint = "BOTTOMLEFT"
        VDManaBar.x = 300
        VDManaBar.y = 200
        
        bar:ClearAllPoints()
        bar:SetPoint(VDManaBar.point, PlayerFrame, VDManaBar.relPoint, VDManaBar.x, VDManaBar.y)
        
        if VDManaBarXInput then VDManaBarXInput:SetText("112") end
        if VDManaBarYInput then VDManaBarYInput:SetText("22") end
    end)

    local cbLock = CreateFrame("CheckButton", "VDManaBarLockCheck", panel, "UICheckButtonTemplate")
    cbLock:SetSize(25, 25)
    cbLock:SetPoint("TOPLEFT", 10, -50)
    cbLock:SetChecked(VDManaBar.locked)
    cbLock:SetScript("OnClick", function(self)
        VDManaBar.locked = self:GetChecked()
        UpdateDepth()
    end)

    local cbLockLabel = cbLock:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    cbLockLabel:SetPoint("LEFT", cbLock, "RIGHT", 5, 0)
    cbLockLabel:SetText("Lock position")

    local xBox = CreateInput("VDManaBarXInput", panel, 40, "X", false,
        function() return VDManaBar.x end,
        function(val)
            VDManaBar.x = val
            bar:SetPoint(VDManaBar.point, PlayerFrame, VDManaBar.relPoint, VDManaBar.x, VDManaBar.y)
        end)
    xBox:SetPoint("TOPLEFT", 15, -100)

    local yBox = CreateInput("VDManaBarYInput", panel, 40, "Y", false,
        function() return VDManaBar.y end,
        function(val)
            VDManaBar.y = val
            bar:SetPoint(VDManaBar.point, PlayerFrame, VDManaBar.relPoint, VDManaBar.x, VDManaBar.y)
        end)
    yBox:SetPoint("LEFT", xBox, "RIGHT", 40, 0)

    local widthBox = CreateInput("VDManaBarWidthInput", panel, 40, "Width", true,
        function() return VDManaBar.width end,
        function(val)
            if val > 0 then
                VDManaBar.width = val
                UpdateBarSize(VDManaBar.width, VDManaBar.height)
            end
        end)
    widthBox:SetPoint("TOPLEFT", 200, -100)

    local heightBox = CreateInput("VDManaBarHeightInput", panel, 40, "Height", true,
        function() return VDManaBar.height end,
        function(val)
            if val > 0 then
                VDManaBar.height = val
                UpdateBarSize(VDManaBar.width, VDManaBar.height)
            end
        end)
    heightBox:SetPoint("LEFT", widthBox, "RIGHT", 40, 0)

    local cbPercent = CreateFrame("CheckButton", "VDManaBarPercentCheck", panel, "UICheckButtonTemplate")
    cbPercent:SetSize(25, 25)
    cbPercent:SetPoint("TOPLEFT", 10, -140)
    cbPercent:SetChecked(VDManaBar.showPercent)
    cbPercent:SetScript("OnClick", function(self)
        VDManaBar.showPercent = self:GetChecked()
        UpdateMana()
    end)

    local cbPercentLabel = cbPercent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    cbPercentLabel:SetPoint("LEFT", cbPercent, "RIGHT", 5, 0)
    cbPercentLabel:SetText("Show mana %")

    local cbValue = CreateFrame("CheckButton", "VDManaBarValueCheck", panel, "UICheckButtonTemplate")
    cbValue:SetSize(25, 25)
    cbValue:SetPoint("TOPLEFT", 10, -170)
    cbValue:SetChecked(VDManaBar.showValue)
    cbValue:SetScript("OnClick", function(self)
        VDManaBar.showValue = self:GetChecked()
        UpdateMana()
    end)

    local cbValueLabel = cbValue:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    cbValueLabel:SetPoint("LEFT", cbValue, "RIGHT", 5, 0)
    cbValueLabel:SetText("Show total mana")

    local cbTicks = CreateFrame("CheckButton", "VDManaBarTicksCheck", panel, "UICheckButtonTemplate")
    cbTicks:SetSize(25, 25)
    cbTicks:SetPoint("TOPLEFT", 10, -200)
    cbTicks:SetChecked(VDManaBar.trackTicks)
    cbTicks:SetScript("OnClick", function(self)
        VDManaBar.trackTicks = self:GetChecked()
    end)

    local cbTicksLabel = cbTicks:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    cbTicksLabel:SetPoint("LEFT", cbTicks, "RIGHT", 5, 0)
    cbTicksLabel:SetText("Track mana ticks")

    local fontBox = CreateInput("VDManaBarFontInput", panel, 40, "Font size", true,
        function() return VDManaBar.fontSize end,
        function(val)
            if val > 0 then
                VDManaBar.fontSize = val
                UpdateFontSize(VDManaBar.fontSize)
            end
        end)
    fontBox:SetPoint("TOPLEFT", 200, -140)

    local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
    Settings.RegisterAddOnCategory(category)
end

f:SetScript("OnEvent", function(self, event, unit, powerToken)
    if event == "PLAYER_LOGIN" then
        VDManaBar = VDManaBar or {}
        
        local defaults = {
            locked = true,
            point = "BOTTOMLEFT",
            relPoint = "BOTTOMLEFT",
            x = 300,
            y = 200,
            width = 98,
            height = 14,
            fontSize = 12,
            showPercent = true,
            showValue = true,
            trackTicks = true
        }
        
        for k, v in pairs(defaults) do
            if VDManaBar[k] == nil then
                VDManaBar[k] = v
            end
        end

        bar:ClearAllPoints()
        bar:SetPoint(VDManaBar.point, PlayerFrame, VDManaBar.relPoint, VDManaBar.x, VDManaBar.y)
        UpdateBarSize(VDManaBar.width, VDManaBar.height)
        UpdateFontSize(VDManaBar.fontSize)
        UpdateDepth()

        InitSettingsPanel()
        UpdateVisibility()

    elseif event == "UNIT_DISPLAYPOWER" then
        if unit == "player" then
            UpdateVisibility()
        end

    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        if unit == "player" then
            if UnitPower("player", 0) < previousMana then
                fsrEndTime = GetTime() + 5
                waitingForFirstTick = true
            end
        end

    elseif (event == "UNIT_POWER_UPDATE" or event == "UNIT_MAXPOWER") then
        if unit == "player" and powerToken == "MANA" then
            local currMana = UnitPower("player", 0)
            
            if currMana > previousMana then
                local gain = currMana - previousMana
                local maxMana = UnitPowerMax("player", 0)
                
                if gain < (maxMana * 0.15) then
                    nextTickTime = GetTime() + 2
                    
                    if GetTime() >= fsrEndTime then
                        waitingForFirstTick = false
                    end
                end
            end
            
            UpdateMana()
        end
    end
end)