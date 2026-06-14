-- BNFriendsToggle --

local _, BNGNF = pcall(function() return _G.BNGetNumFriends end)
local db 

local function UpdateButtonStatus(btn)
    if not btn then return end
    local color = db.hidden and "|cfffff2ccHidden|r" or "|cff00aeffShown|r"
    btn:SetText("BNet Friends: " .. color)
end

_G.BNGetNumFriends = function(...)
    if db and db.hidden then
        return 0, 0, 0, 0
    end
    return BNGNF(...)
end

local function ToggleBNFriends()
    db.hidden = not db.hidden

    local btn = _G["ToggleBNFriendsButton"]
    UpdateButtonStatus(btn)

    -- Force client-side sort to fix index going crazy
    if _G.C_FriendList and _G.C_FriendList.SortFriends then
        _G.C_FriendList.SortFriends()
    end

    -- Reset scroll bar position if it appeared after a on/off
    local scroll = _G.FriendsFrameFriendsScrollFrame
    if scroll then
        if _G.HybridScrollFrame_SetOffset then
            _G.HybridScrollFrame_SetOffset(scroll, 0)
        end
        if scroll.ScrollBar then
            scroll.ScrollBar:SetValue(0)
        end
    end

    if _G.FriendsFrame and _G.FriendsFrame:IsVisible() then
        _G.FriendsFrame:Hide()
        _G.FriendsFrame:Show()
    end
    
    -- Delayed update to catches the sort result
    _G.C_Timer.After(0.2, function()
        if _G.FriendsFrame and _G.FriendsFrame:IsVisible() then
            if _G.FriendsFrame_Update then _G.FriendsFrame_Update() end
        end
    end)
end

local f = _G.CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        _G.BNToggleSaveData = _G.BNToggleSaveData or {}
        db = _G.BNToggleSaveData
        if db.hidden == nil then db.hidden = true end

        if _G.FriendsFrame then
            local btn = _G.CreateFrame("Button", "ToggleBNFriendsButton", _G.FriendsFrame, "UIPanelButtonTemplate")
            btn:SetSize(140, 25)
            btn:SetPoint("TOPLEFT", _G.FriendsFrame, "TOPLEFT", 190, -56)
            
            btn:SetScript("OnClick", ToggleBNFriends)

            UpdateButtonStatus(btn)

            -- Check so the button only spawns on the friends tab
            _G.hooksecurefunc("FriendsFrame_Update", function()
                if _G.FriendsFrame.selectedTab == 1 then
                    btn:Show()
                else
                    btn:Hide()
                end
            end)
        end
        self:UnregisterEvent("PLAYER_LOGIN")
    end
end)