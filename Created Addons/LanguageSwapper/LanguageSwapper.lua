-- --- GLOBAL VARIABLES ---
-- These variables will be defined during ADDON_LOADED/PLAYER_ENTERING_WORLD events
local CommonLangID = nil
local RacialLangID = nil
local CommonLangName = ""
local RacialLangName = ""

-- --- UI CREATION ---

-- The button is created with UIParent temporarily; it will be reparented later
local f = CreateFrame("Button", "TestLanguageButton", UIParent, "UIPanelButtonTemplate")
f:SetSize(200, 30) 
f:SetPoint("CENTER", 0, 100) 
f:EnableMouse(true)
f:Hide() -- Hidden by default

-- FontString object for the text
local text = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
text:SetAllPoints(f)
text:SetJustifyH("CENTER")
text:SetText("Loading...")

-- Z-INDEX: Crucial to ensure it stays above the CharacterFrame
f:SetFrameStrata("DIALOG") 
f:SetFrameLevel(10)        


-- --- MANAGEMENT FUNCTIONS ---

-- Function to apply font size
local function ApplyFontSize()
    local size = LanguageSwapperDB.fontSize or 10
    text:SetHeight(size)
    text:SetFont(STANDARD_TEXT_FONT, size)
end

-- Updates button text and SAVES language choice
local function UpdateButtonTextAndSave()
    local currentID = DEFAULT_CHAT_FRAME.editBox.languageID
    
    if LanguageSwapperDB then
        LanguageSwapperDB.lastLangID = currentID
    end

    if currentID == RacialLangID then
        text:SetText("Language: " .. (RacialLangName or "?"))
    elseif currentID == CommonLangID then
        text:SetText("Language: " .. (CommonLangName or "?"))
    else
        text:SetText("Lang ID: " .. (currentID or "Press once"))
    end
end

-- Function to apply Lock state and handle movement
local function ApplyLockState()
    if LanguageSwapperDB.locked then
        f:SetMovable(false)
        f:RegisterForDrag() -- Disables drag
        f:SetScript("OnDragStart", nil)
        f:SetScript("OnDragStop", nil)
    else
        f:SetMovable(true)
        f:RegisterForDrag("LeftButton")
        
        f:SetScript("OnDragStart", function(self)
            self:StartMoving()
        end)
        
        f:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            
            -- Calculate button position relative to PaperDollFrame
            local currentX = self:GetLeft() - PaperDollFrame:GetLeft()
            local currentY = self:GetTop() - PaperDollFrame:GetTop()

            -- Immediately re-anchor the button with these relative coordinates
            self:ClearAllPoints()
            self:SetPoint("TOPLEFT", PaperDollFrame, "TOPLEFT", currentX, currentY)
            
            -- Save these relative coordinates
            LanguageSwapperDB.point = "TOPLEFT"
            LanguageSwapperDB.relativePoint = "TOPLEFT"
            LanguageSwapperDB.x = currentX
            LanguageSwapperDB.y = currentY
            
            print("|cff00ff00[LS]|r Position saved (Relative).")
        end)
    end
end

-- Scan player languages
local function ScanPlayerLanguages()
    local numLangs = GetNumLanguages()
    
    if numLangs >= 1 then
        CommonLangName, CommonLangID = GetLanguageByIndex(1)
    end
    if numLangs >= 2 then
        RacialLangName, RacialLangID = GetLanguageByIndex(2)
    else
        RacialLangID = nil
    end
    
    -- Restore language
    if LanguageSwapperDB and LanguageSwapperDB.lastLangID then
        local savedID = LanguageSwapperDB.lastLangID
        if savedID == CommonLangID or savedID == RacialLangID then
            DEFAULT_CHAT_FRAME.editBox.languageID = savedID
        end
    end

    UpdateButtonTextAndSave()
end

-- Click action
local function OnClickButton()
    if not CommonLangID then ScanPlayerLanguages() end

    local currentID = DEFAULT_CHAT_FRAME.editBox.languageID
    
    if currentID == CommonLangID and RacialLangID then
        DEFAULT_CHAT_FRAME.editBox.languageID = RacialLangID
        print("|cff00ffff[LS]|r Switched to " .. RacialLangName .. ".")
    else
        DEFAULT_CHAT_FRAME.editBox.languageID = CommonLangID
        print("|cff00ffff[LS]|r Switched to " .. CommonLangName .. ".")
    end
    
    UpdateButtonTextAndSave()
end

f:SetScript("OnClick", OnClickButton)


-- --- EVENT HANDLING ---
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

-- Visibility hooks (matching PaperDoll visibility)
PaperDollFrame:HookScript("OnShow", function()
    f:Show()
    UpdateButtonTextAndSave()
end)

PaperDollFrame:HookScript("OnHide", function()
    f:Hide()
end)


eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "LanguageSwapper" then
        if not LanguageSwapperDB then
            LanguageSwapperDB = {
                point = "TOPLEFT",
                relativePoint = "TOPLEFT",
                x = 134,
                y = -57,
                width = 125,
                height = 15,
                lastLangID = nil,
                locked = true, 
                fontSize = 10 
            }
        end
        
        -- Set parent to PaperDollFrame
        f:SetParent(PaperDollFrame)
        
        -- Apply saved position
        f:ClearAllPoints()
        f:SetPoint(LanguageSwapperDB.point, PaperDollFrame, LanguageSwapperDB.relativePoint, LanguageSwapperDB.x, LanguageSwapperDB.y)
        f:SetSize(LanguageSwapperDB.width, LanguageSwapperDB.height)
        
        ApplyFontSize()
        ApplyLockState()
        
        -- If the frame is visible on load (e.g., UI reload with window open)
        if PaperDollFrame:IsVisible() then
             f:Show()
        end

    elseif event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(1, ScanPlayerLanguages)
    end
end)

-- --- SLASH COMMANDS ---
SLASH_LANGSWAP1 = "/lang"
SLASH_LANGSWAP2 = "/language"

SlashCmdList["LANGSWAP"] = function(msg)
    local command, rest = msg:match("^(%S*)%s*(.-)$")
    
    if command == "lock" then
        LanguageSwapperDB.locked = true
        ApplyLockState()
        print("|cff00ff00[LS]|r Button LOCKED.")
        
    elseif command == "unlock" then
        LanguageSwapperDB.locked = false
        ApplyLockState()
        print("|cff00ff00[LS]|r Button UNLOCKED.")
        
    elseif command == "size" then
        local w, h = rest:match("^(%d+)%s+(%d+)$")
        if w and h then
            f:SetSize(tonumber(w), tonumber(h))
            LanguageSwapperDB.width = tonumber(w)
            LanguageSwapperDB.height = tonumber(h)
            print("|cff00ff00[LS]|r Size set to "..w.."x"..h)
        else
            print("Usage: /lang size <width> <height>")
        end

    elseif command == "fontsize" then
        local size = rest:match("^(%d+)$")
        if size then
            local newSize = tonumber(size)
            if newSize >= 6 and newSize <= 30 then
                LanguageSwapperDB.fontSize = newSize
                ApplyFontSize()
                print("|cff00ff00[LS]|r Font size set to "..newSize..".")
            else
                print("|cffFF0000[LS] Error:|r Size must be between 6 and 30.")
            end
        else
            print("Usage: /lang fontsize <size> (Example: /lang fontsize 10)")
        end
        
    elseif command == "reset" then
        f:ClearAllPoints()
        -- Reset relative to PaperDollFrame
        f:SetPoint("TOPLEFT", PaperDollFrame, "TOPLEFT", 134, -57)
        f:SetSize(125, 15)
        
        LanguageSwapperDB.locked = true
        LanguageSwapperDB.fontSize = 10
        LanguageSwapperDB.point = "TOPLEFT"
        LanguageSwapperDB.relativePoint = "TOPLEFT"
        LanguageSwapperDB.x = 134
        LanguageSwapperDB.y = -57
        LanguageSwapperDB.width = 125
        LanguageSwapperDB.height = 15
        
        ApplyLockState()
        ApplyFontSize()
        print("|cff00ff00[LS]|r Configuration reset.")
        
    else
        print("|cff00ff00[LS] Commands:|r")
        print("  /lang lock    : Lock the button")
        print("  /lang unlock  : Unlock the button")
        print("  /lang size 125 15")
        print("  /lang fontsize 10")
        print("  /lang reset")
    end
end