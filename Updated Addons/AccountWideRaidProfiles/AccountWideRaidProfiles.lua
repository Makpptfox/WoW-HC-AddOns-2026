--[[
AccountWideRaidProfiles

Make Blizzard raid profile settings account-wide.

zlib License

(C) 2017-2021 Haoqian he

This software is provided 'as-is', without any express or implied
warranty.  In no event will the authors be held liable for any damages
arising from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute it
freely, subject to the following restrictions:

1. The origin of this software must not be misrepresented; you must not
   claim that you wrote the original software. If you use this software
   in a product, an acknowledgment in the product documentation would be
   appreciated but is not required.
2. Altered source versions must be plainly marked as such, and must not be
   misrepresented as being the original software.
3. This notice may not be removed or altered from any source distribution.
--]]

local addonName = ...
local DB = AccountWideRaidProfilesDB
local frameStyleCVar = "useCompactPartyFrames"
local reloadDialog = "ACCOUNT_WIDE_RAID_PROFILES_RELOAD_DIALOG"

StaticPopupDialogs[reloadDialog] = {
    text = "AccountWideRaidProfiles has applied raid profile settings. Reload UI now?",
    button1 = YES,
    button2 = NO,
    OnAccept = function()
        ReloadUI()
    end,
    OnCancel = function()
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00["..addonName.."]|r Reload skipped. Changes may require /reload to take effect.")
    end,
    timeout = 0,
    hideOnEscape = 1,
}

local function Print(msg)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00["..addonName.."]|r "..msg)
    end
end

local function IsFunction(name)
    return type(_G[name]) == "function"
end

local function CanUseRaidProfiles()
    return IsFunction("GetNumRaidProfiles")
        and IsFunction("GetRaidProfileName")
        and IsFunction("GetRaidProfileFlattenedOptions")
        and IsFunction("SetRaidProfileOption")
        and IsFunction("SetActiveRaidProfile")
        and IsFunction("CreateNewRaidProfile")
        and IsFunction("DeleteRaidProfile")
        and IsFunction("GetActiveRaidProfile")
        and IsFunction("SetRaidProfileSavedPosition")
end

local function CopyTable(src)
    if type(src) ~= "table" then
        return src
    end
    local dst = {}
    for k,v in pairs(src) do
        dst[k] = CopyTable(v)
    end
    return dst
end

local function trim(value)
    if type(value) ~= "string" then
        return value
    end
    return value:match("^%s*(.-)%s*$")
end

local function EnsureDB()
    if not AccountWideRaidProfilesDB then
        AccountWideRaidProfilesDB = {}
    end
    DB = AccountWideRaidProfilesDB
    if not DB.profiles then
        DB.profiles = {}
        DB.options = {}
        DB.positions = {}
    end
end

local function StoreAll()
    if not CanUseRaidProfiles() then
        return
    end
    EnsureDB()
    DB.frameStyle = GetCVar(frameStyleCVar)
    DB.lastProfile = GetActiveRaidProfile()

    DB.profiles = {}
    DB.options = {}
    DB.positions = {}

    for i = 1, GetNumRaidProfiles() do
        local name = GetRaidProfileName(i)
        if name then
            DB.profiles[i] = name
            DB.options[i] = CopyTable(GetRaidProfileFlattenedOptions(name) or {})
            DB.positions[i] = {GetRaidProfileSavedPosition(name)}
        end
    end
end

local function DeleteAllRaidProfiles()
    if not CanUseRaidProfiles() then
        return
    end
    local names = {}
    for i = 1, GetNumRaidProfiles() do
        local name = GetRaidProfileName(i)
        if name then
            names[#names + 1] = name
        end
    end
    for _, name in ipairs(names) do
        DeleteRaidProfile(name)
    end
end

local function LoadAll()
    if not CanUseRaidProfiles() or not AccountWideRaidProfilesDB or not AccountWideRaidProfilesDB.profiles then
        return
    end
    local data = AccountWideRaidProfilesDB
    DeleteAllRaidProfiles()

    if data.frameStyle then
        SetCVar(frameStyleCVar, data.frameStyle)
    end

    for i, name in ipairs(data.profiles) do
        if name then
            CreateNewRaidProfile(name)
            local opts = data.options[i] or {}
            for option, value in pairs(opts) do
                SetRaidProfileOption(name, option, value)
            end
            if data.positions[i] then
                SetRaidProfileSavedPosition(name, unpack(data.positions[i]))
            end
        end
    end

    if data.lastProfile then
        SetActiveRaidProfile(data.lastProfile)
    end
end

local function OnProfileChanged()
    StoreAll()
end

local function SetupHooks()
    if IsFunction("SetRaidProfileOption") then
        hooksecurefunc("SetRaidProfileOption", OnProfileChanged)
    end
    if IsFunction("SetActiveRaidProfile") then
        hooksecurefunc("SetActiveRaidProfile", OnProfileChanged)
    end
    if IsFunction("SetRaidProfileSavedPosition") then
        hooksecurefunc("SetRaidProfileSavedPosition", OnProfileChanged)
    end
    if IsFunction("CreateNewRaidProfile") then
        hooksecurefunc("CreateNewRaidProfile", OnProfileChanged)
    end
    if IsFunction("DeleteRaidProfile") then
        hooksecurefunc("DeleteRaidProfile", OnProfileChanged)
    end
    if IsFunction("SetCVar") then
        hooksecurefunc("SetCVar", function(name, value)
            if name == frameStyleCVar then
                StoreAll()
            end
        end)
    end
end

local isInitialized = false

local function OnEvent(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        EnsureDB()
    elseif event == "PLAYER_ENTERING_WORLD" then
        if isInitialized then return end
        isInitialized = true

        if not CanUseRaidProfiles() then
            Print("Raid profile APIs are unavailable on this client. The addon cannot synchronize raid profiles.")
            return
        end
        
        C_Timer.After(0.5, function()
            if DB.profiles and #DB.profiles > 0 then
                LoadAll()
                Print("Loaded account-wide raid profile settings.")
            else
                StoreAll()
                Print("Stored current raid profile settings for account-wide use.")
            end
            SetupHooks()

            if type(CompactUnitFrameProfiles_ApplyAutoSelectProfiles) == "function" then
                CompactUnitFrameProfiles_ApplyAutoSelectProfiles()
            end
        end)
    elseif event == "PLAYER_LOGOUT" then
        if CanUseRaidProfiles() then
            StoreAll()
        end
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_LOGOUT")
eventFrame:SetScript("OnEvent", OnEvent)

SLASH_ACCOUNTWIDERAIDPROFILES1 = "/awrp"
SlashCmdList["ACCOUNTWIDERAIDPROFILES"] = function(msg)
    msg = trim(msg and msg:lower() or "")
    if msg == "store" then
        StoreAll()
        Print("Raid profile settings stored account-wide.")
    elseif msg == "restore" then
        LoadAll()
        Print("Raid profile settings restored from account-wide data.")
    elseif msg == "status" then
        if DB and DB.profiles and #DB.profiles > 0 then
            Print("Account-wide raid profiles active. Stored profiles: "..#DB.profiles)
        else
            Print("No account-wide raid profile data stored yet.")
        end
    else
        Print("Usage: /awrp store | restore | status")
    end
end
