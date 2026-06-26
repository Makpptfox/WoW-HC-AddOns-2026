-- BNFriendsToggle --

local BNGNF
local db
local isSorting = false

local function UpdateButtonStatus(btn)
    if not btn then return end
    local color = db.hidden and "|cfffff2ccHidden|r" or "|cff00aeffShown|r"
    btn:SetText("BNet Friends: " .. color)
end

local function ClearStaleFriendTooltip()
    if _G.GameTooltip and _G.GameTooltip:IsShown() then
        _G.GameTooltip:Hide()
    end
end

-- resort and redraw together to keep text and id in sync
local function RefreshFriendsList()
    if _G.C_FriendList and _G.C_FriendList.SortFriends then
        isSorting = true
        _G.C_FriendList.SortFriends()
        isSorting = false
    end

    ClearStaleFriendTooltip()

    local scroll = _G.FriendsFrameFriendsScrollFrame
    if scroll then
        if _G.HybridScrollFrame_SetOffset then
            _G.HybridScrollFrame_SetOffset(scroll, 0)
        end
        if scroll.ScrollBar then
            scroll.ScrollBar:SetValue(0)
        end
    end

    -- force redraw
    if _G.FriendsFrame and _G.FriendsFrame:IsVisible() and _G.FriendsFrame_Update then
        _G.FriendsFrame_Update()
    end

    -- catch async sort result
    _G.C_Timer.After(0.2, function()
        if _G.FriendsFrame and _G.FriendsFrame:IsVisible() then
            if _G.FriendsFrame_Update then
                _G.FriendsFrame_Update()
            end
            ClearStaleFriendTooltip()
        end
    end)
end

local function ToggleBNFriends()
    _G.PlaySound(856)

    db.hidden = not db.hidden

    local btn = _G["ToggleBNFriendsButton"]
    UpdateButtonStatus(btn)

    RefreshFriendsList()
end

-- debounce updates events (login/logoff/remove/add)
local refreshGeneration = 0
local function ScheduleNetworkRefresh()
    refreshGeneration = refreshGeneration + 1
    local myGeneration = refreshGeneration

    _G.C_Timer.After(0.3, function()
        -- verify latest call
        if myGeneration == refreshGeneration then
            RefreshFriendsList()
        end
    end)
end

local f = _G.CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("FRIENDLIST_UPDATE")
f:RegisterEvent("BN_FRIEND_INFO_CHANGED")
f:RegisterEvent("BN_FRIEND_LIST_SIZE_CHANGED")

f:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        _G.BNToggleSaveData = _G.BNToggleSaveData or {}
        db = _G.BNToggleSaveData

        if db.hidden == nil then
            db.hidden = true
        end

        -- capture original only after login
        if not BNGNF then
            BNGNF = _G.BNGetNumFriends

            _G.BNGetNumFriends = function(...)
                if db and db.hidden then
                    return 0, 0, 0, 0
                end

                return BNGNF(...)
            end
        end

        if _G.FriendsFrame then
            local btn = _G.CreateFrame(
                "Button",
                "ToggleBNFriendsButton",
                _G.FriendsFrame,
                "UIPanelButtonTemplate"
            )

            btn:SetSize(140, 25)
            btn:SetPoint("TOPLEFT", _G.FriendsFrame, "TOPLEFT", 190, -56)

            btn:SetScript("OnClick", ToggleBNFriends)

            UpdateButtonStatus(btn)

            _G.hooksecurefunc("FriendsFrame_Update", function()
                if _G.FriendsFrame.selectedTab == 1 then
                    btn:Show()
                else
                    btn:Hide()
                end
            end)
        end

        -- allow Battle.net list to finish initializing first
        _G.C_Timer.After(1, function()
            if db and db.hidden then
                RefreshFriendsList()
            end
        end)

    -- realign indices on network events
    elseif db and db.hidden and not isSorting then
        if event == "FRIENDLIST_UPDATE"
        or event == "BN_FRIEND_INFO_CHANGED"
        or event == "BN_FRIEND_LIST_SIZE_CHANGED" then
            ScheduleNetworkRefresh()
        end
    end
end)

_G.SLASH_BNFTDEBUG1 = "/bnftdebug"
_G.SlashCmdList = _G.SlashCmdList or {}

_G.SlashCmdList["BNFTDEBUG"] = function()
    local scroll = _G.FriendsFrameFriendsScrollFrame

    if not (scroll and scroll.buttons) then
        print("BNFriendsToggle: no FriendsFrameFriendsScrollFrame.buttons found.")
        return
    end

    print("BNFriendsToggle: hidden=" .. tostring(db and db.hidden))

    for i, button in ipairs(scroll.buttons) do
        if button:IsShown() then
            local nameText = button.name and button.name:GetText() or "?"

            print(string.format(
                "  row %d: text=%s  buttonType=%s  id=%s",
                i,
                tostring(nameText),
                tostring(button.buttonType),
                tostring(button.id)
            ))
        end
    end
end