-- BNFriendsToggle --

local BNGNF
local db

local function UpdateButtonStatus(btn)
    -- Show the current state on the button label.
    if not btn then
        return
    end

    local color = db.hidden and "|cfffff2ccHidden|r" or "|cff00aeffShown|r"
    btn:SetText("BNet Friends: " .. color)
end

local function ForceUIRebuild()
    -- Hide the tooltip and force the friends list to redraw.
    if _G.GameTooltip and _G.GameTooltip:IsShown() then
        _G.GameTooltip:Hide()
    end

    if _G.FriendsList_Update then
        _G.FriendsList_Update()
    end
end

local function FixFriendListEntries()
    -- Rebuild the internal entries table so online and offline groups stay separated.
    local entries = _G.FriendListEntries or _G.FriendsListEntries
    if not entries then
        if _G.FriendsFrame and type(_G.FriendsFrame.friendsList) == "table" then
            entries = _G.FriendsFrame.friendsList
        else
            return
        end
    end

    local scroll = _G.FriendsFrameFriendsScrollFrame
    if not scroll then
        return
    end

    local validCount = scroll.numFriendListEntries or #entries
    for i = #entries, validCount + 1, -1 do
        entries[i] = nil
    end

    local invites = {}
    local bnetOnline, bnetOffline = {}, {}
    local wowOnline, wowOffline = {}, {}

    local TYPE_DIVIDER = _G.FRIENDS_BUTTON_TYPE_DIVIDER or 1
    local TYPE_BNET = _G.FRIENDS_BUTTON_TYPE_BNET or 2
    local TYPE_WOW = _G.FRIENDS_BUTTON_TYPE_WOW or 3

    local numWoWOnline = _G.C_FriendList.GetNumOnlineFriends() or 0
    local _, numBNetOnline = _G.BNGetNumFriends()
    numBNetOnline = numBNetOnline or 0

    local function EntryIsOnline(entry)
        -- Prefer the entry's explicit online flag when available.
        -- If not present, use the native online count fallback.
        if entry.online ~= nil then
            return entry.online
        end

        if entry.buttonType == TYPE_BNET then
            return entry.id <= numBNetOnline
        elseif entry.buttonType == TYPE_WOW then
            return entry.id <= numWoWOnline
        end

        return false
    end

    for _, entry in ipairs(entries) do
        if entry.buttonType == TYPE_BNET then
            if EntryIsOnline(entry) then
                table.insert(bnetOnline, entry)
            else
                table.insert(bnetOffline, entry)
            end
        elseif entry.buttonType == TYPE_WOW then
            if EntryIsOnline(entry) then
                table.insert(wowOnline, entry)
            else
                table.insert(wowOffline, entry)
            end
        elseif entry.buttonType ~= TYPE_DIVIDER then
            table.insert(invites, entry)
        end
    end

    wipe(entries)

    -- Reinsert invites and headers first, then online friends, then offline friends.
    for _, entry in ipairs(invites) do
        table.insert(entries, entry)
    end

    if #invites > 0 and (#bnetOnline > 0 or #wowOnline > 0 or #bnetOffline > 0 or #wowOffline > 0) then
        table.insert(entries, { buttonType = TYPE_DIVIDER, id = 0 })
    end

    for _, entry in ipairs(bnetOnline) do
        table.insert(entries, entry)
    end
    for _, entry in ipairs(wowOnline) do
        table.insert(entries, entry)
    end

    if (#bnetOffline > 0 or #wowOffline > 0) and (#bnetOnline > 0 or #wowOnline > 0) then
        table.insert(entries, { buttonType = TYPE_DIVIDER, id = 0 })
    end

    for _, entry in ipairs(bnetOffline) do
        table.insert(entries, entry)
    end
    for _, entry in ipairs(wowOffline) do
        table.insert(entries, entry)
    end

    local totalHeight = 0
    local HEIGHTS = _G.FRIENDS_BUTTON_HEIGHTS or { [1] = 16, [2] = 34, [3] = 34, [4] = 34, [5] = 31 }
    for _, entry in ipairs(entries) do
        totalHeight = totalHeight + (HEIGHTS[entry.buttonType] or 34)
    end

    scroll.numFriendListEntries = #entries
    scroll.totalFriendListEntriesHeight = totalHeight

    if type(scroll.update) == "function" then
        scroll.update()
    end
end

local function ToggleBNFriends()
    -- Toggle the hidden state, reset the scroll position, and force a full refresh.
    _G.PlaySound(856)
    db.hidden = not db.hidden

    local scroll = _G.FriendsFrameFriendsScrollFrame
    if scroll then
        if type(scroll.SetVerticalScroll) == "function" then
            scroll:SetVerticalScroll(0)
        end

        if scroll.ScrollBar and type(scroll.ScrollBar.SetValue) == "function" then
            scroll.ScrollBar:SetValue(0)
        end

        if scroll.scrollBar and type(scroll.scrollBar.SetValue) == "function" then
            scroll.scrollBar:SetValue(0)
        end
    end

    UpdateButtonStatus(_G.ToggleBNFriendsButton)
    ForceUIRebuild()
end

local function SetupButton()
    if not _G.FriendsFrame then
        return
    end

    local btn = _G.CreateFrame("Button", "ToggleBNFriendsButton", _G.FriendsFrame, "UIPanelButtonTemplate")
    btn:SetSize(140, 25)
    btn:SetPoint("TOPLEFT", _G.FriendsFrame, "TOPLEFT", 190, -56)
    btn:SetScript("OnClick", ToggleBNFriends)
    UpdateButtonStatus(btn)

    _G.hooksecurefunc("FriendsFrame_Update", function()
        if _G.FriendsFrame and _G.FriendsFrame.selectedTab == 1 then
            btn:Show()
        else
            btn:Hide()
        end
    end)
end

local f = _G.CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")

f:SetScript("OnEvent", function(self, event)
    if event ~= "PLAYER_LOGIN" then
        return
    end

    _G.BNToggleSaveData = _G.BNToggleSaveData or {}
    db = _G.BNToggleSaveData

    if db.hidden == nil then
        db.hidden = true
    end

    if not BNGNF then
        -- Patch the native BNGetNumFriends result when hidden mode is on.
        BNGNF = _G.BNGetNumFriends
        _G.BNGetNumFriends = function(...)
            if db and db.hidden then
                return 0, 0, 0, 0
            end
            return BNGNF(...)
        end
    end

    -- Keep the list order correct whenever the friends frame updates.
    _G.hooksecurefunc("FriendsList_Update", FixFriendListEntries)
    _G.hooksecurefunc("FriendsFrame_Update", function()
        if _G.FriendsFrame and _G.FriendsFrame.selectedTab == 1 then
            FixFriendListEntries()
        end
    end)

    if _G.FriendsFrameFriendsScrollFrame and type(_G.FriendsFrameFriendsScrollFrame.update) == "function" then
        _G.hooksecurefunc(_G.FriendsFrameFriendsScrollFrame, "update", FixFriendListEntries)
    end

    SetupButton()

    _G.C_Timer.After(1, function()
        if db and db.hidden then
            ForceUIRebuild()
        end
    end)
end)