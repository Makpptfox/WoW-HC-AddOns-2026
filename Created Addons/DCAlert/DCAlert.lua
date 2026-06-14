-- DCAlert --

local addonName, addon = ...
local f = CreateFrame("Frame")

local defaults = {
    posX   = 0,
    posY   = -40,
    sound  = true,
    ping   = true,
    locked = false,
}

local db
local function InitDB()
    if not DCAlertDB then DCAlertDB = {} end
    for k, v in pairs(defaults) do
        if DCAlertDB[k] == nil then DCAlertDB[k] = v end
    end
    db = DCAlertDB
end

local INITIAL_RESPONSE_TIME          = 0.15
local RESPONSE_COUNT                 = 10
local RAID_EXTRA                     = 0.3
local INSPECT_EXTRA                  = 3.0
local INSPECT_AFTER_RECOVERY_PERIOD  = 5.0
local TIMEOUT_OFFSET                 = 1.50

local DISCONNECT_SOUND_REPEAT        = 5
local DISCONNECT_SOUND_GAP           = 3.0
local DISCONNECT_SOUND_DELAY         = 0.2
local HIGH_PING_THRESHOLD            = 0.3
local LOADING_GRACE_SECONDS          = 3
local MAX_AVG_RESPONSE_TIME          = 5
local MAX_CONSECUTIVE_TIMEOUTS       = 3

local SOUND_PATH = "Interface\\AddOns\\DCAlert\\Media\\Disconnected_sound.mp3"

addon.status = "Connected"
addon.responseTimes = {}
addon.avg = INITIAL_RESPONSE_TIME
addon.isTesting = false
addon.soundPlayed = false
addon.pingHideSamples = 5
addon.lastRaidRequest = 0
addon.lastRaidResponse = 0
addon.lastInspectRequest = 0
addon.lastInspectResponse = 0
addon.nextRaidSend = 0
addon.nextInspectSend = 0
addon.recoveryInspectActive = false
addon.loadingGraceUntil = nil
addon.inLoadingScreen = false
addon.timeoutCount = 0
addon.isRaidPending = false
addon.isInspectPending = false

local function UnderGrace() return addon.loadingGraceUntil and GetTime() < addon.loadingGraceUntil end

local function ShouldSkipInspect()
    if UnderGrace() or UnitOnTaxi("player") or addon.inLoadingScreen or not HasFullControl() then return true end
    if InspectFrame and InspectFrame:IsShown() then return true end
    return false
end

local function PlayDisconnectSounds()
    if not db.sound then return end
    if addon.soundPlayed and not addon.isTesting then return end
    addon.soundPlayed = true
    local count = 0
    local function repeater()
        if addon.status == "Disconnected" or addon.isTesting then
            count = count + 1
            PlaySoundFile(SOUND_PATH, "Master")
            if count < DISCONNECT_SOUND_REPEAT then C_Timer.After(DISCONNECT_SOUND_GAP, repeater) end
        end
    end
    C_Timer.After(DISCONNECT_SOUND_DELAY, repeater)
end

function addon:SetConnected()
    self.status = "Connected"
    self.soundPlayed = false
    self.timeoutCount = 0
    if self.statusText then
        self.statusText:SetTextColor(0, 1, 0)
        self.statusText:SetText("Connected")
    end
    self.nextInspectSend = GetTime() + self.avg + INSPECT_EXTRA
end

function addon:SetDisconnected()
    if self.status == "Disconnected" then return end
    self.status = "Disconnected"
    print("|cffff0000DCAlert:|r Communication lost! (Timeout > " .. TIMEOUT_OFFSET .. "s x" .. MAX_CONSECUTIVE_TIMEOUTS .. ")")
    if self.statusText then
        self.statusText:SetTextColor(1, 0, 0)
        self.statusText:SetText("Disconnected")
    end
    if self.pingText then self.pingText:Hide() end
    PlayDisconnectSounds()
end

local function HandleChatCommand(msg)
    local cmd, arg = msg:match("^(%S*)%s*(%S*)$")
    cmd = string.lower(cmd or "")
    arg = string.lower(arg or "")
    if cmd == "test" then
        addon.isTesting = true
        addon.statusText:SetTextColor(1, 0, 0)
        addon.statusText:SetText("Disconnected (TEST)")
        PlayDisconnectSounds()
        C_Timer.After(6, function() addon.isTesting = false; addon:SetConnected() end)
    elseif cmd == "lock" then
        db.locked = not db.locked
        print("DCAlert: " .. (db.locked and "Locked" or "Unlocked"))
    elseif cmd == "reset" then
        db.posX, db.posY = 0, -40
        addon.frame:ClearAllPoints()
        addon.frame:SetPoint("TOP", UIParent, "TOP", db.posX, db.posY)
    elseif cmd == "sound" then
        db.sound = (arg == "on")
        print("DCAlert sound: " .. (db.sound and "ON" or "OFF"))
    else
        print("/dcalert test, lock, reset, sound on/off")
    end
end

SLASH_DCAlert1 = "/dcalert"
SlashCmdList["DCAlert"] = HandleChatCommand

local function BuildUI()
    addon.frame = CreateFrame("Frame", "DCAlertAnchor", UIParent)
    addon.frame:SetPoint("TOP", UIParent, "TOP", db.posX, db.posY)
    addon.frame:SetSize(200, 40)
    addon.frame:SetMovable(true)
    addon.frame:EnableMouse(true)
    addon.frame:RegisterForDrag("LeftButton")
    addon.statusText = addon.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    addon.statusText:SetPoint("TOP", addon.frame, "TOP", 0, 0)
    addon.statusText:SetTextColor(0, 1, 0)
    addon.statusText:SetText("Connected")
    addon.pingText = addon.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    addon.pingText:SetPoint("TOP", addon.statusText, "BOTTOM", 0, -2)
    addon.frame:SetScript("OnDragStart", function(self) if not db.locked and IsAltKeyDown() then self:StartMoving() end end)
    addon.frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local _, _, _, x, y = self:GetPoint()
        db.posX, db.posY = x, y
    end)
end

local function AddResponseTime(delta)
    if delta <= 0 then return end
    table.insert(addon.responseTimes, delta)
    if #addon.responseTimes > RESPONSE_COUNT then table.remove(addon.responseTimes, 1) end
    local sum = 0
    for _, v in ipairs(addon.responseTimes) do sum = sum + v end
    addon.avg = math.min(sum / #addon.responseTimes, MAX_AVG_RESPONSE_TIME)
    if addon.pingHideSamples > 0 then
        addon.pingHideSamples = addon.pingHideSamples - 1
    elseif db.ping and addon.status == "Connected" then
        if addon.avg > HIGH_PING_THRESHOLD then
            addon.pingText:SetText(string.format("High ping: %.0f ms", addon.avg * 1000))
            addon.pingText:Show()
        else
            addon.pingText:Hide()
        end
    end
end

f:SetScript("OnUpdate", function(self, elapsed)
    if addon.isTesting then return end
    local now = GetTime()

    if not UnderGrace() and now >= addon.nextRaidSend then
        RequestRaidInfo()
        addon.lastRaidRequest = now
        addon.isRaidPending = true
        addon.nextRaidSend = now + addon.avg + RAID_EXTRA
    end

    local allowIn = (addon.status == "Connected") or addon.recoveryInspectActive
    if allowIn and not ShouldSkipInspect() and now >= addon.nextInspectSend then
        NotifyInspect("player")
        addon.lastInspectRequest = now
        addon.isInspectPending = true
        addon.nextInspectSend = now + (addon.status == "Connected" and (addon.avg + INSPECT_EXTRA) or INSPECT_AFTER_RECOVERY_PERIOD)
    end

    if not UnderGrace() then
        if addon.status == "Connected" then
            local raidTimeout = (now - addon.lastRaidRequest > addon.avg + TIMEOUT_OFFSET) and (addon.lastRaidResponse < addon.lastRaidRequest)
            local inspectTimeout = not ShouldSkipInspect() and (now - addon.lastInspectRequest > addon.avg + TIMEOUT_OFFSET) and (addon.lastInspectResponse < addon.lastInspectRequest)

            if raidTimeout or inspectTimeout then
                if addon.lastRaidRequest > 0 or addon.lastInspectRequest > 0 then
                    if raidTimeout then addon.lastRaidRequest = now end
                    if inspectTimeout then addon.lastInspectRequest = now end

                    addon.timeoutCount = addon.timeoutCount + 1
                    if addon.timeoutCount >= MAX_CONSECUTIVE_TIMEOUTS then
                        addon:SetDisconnected()
                    end
                end
            end
        else
            local rOk = (addon.lastRaidResponse > addon.lastRaidRequest) and ((addon.lastRaidResponse - addon.lastRaidRequest) <= addon.avg + TIMEOUT_OFFSET)
            if rOk and not addon.recoveryInspectActive then
                addon.recoveryInspectActive = true
                addon.nextInspectSend = now + 0.1
            end
            local iOk = addon.recoveryInspectActive and (addon.lastInspectResponse > addon.lastInspectRequest) and ((addon.lastInspectResponse - addon.lastInspectRequest) <= addon.avg + TIMEOUT_OFFSET)
            if rOk and iOk then addon:SetConnected() end
        end
    end
end)

f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("LOADING_SCREEN_ENABLED")
f:RegisterEvent("LOADING_SCREEN_DISABLED")
f:RegisterEvent("UPDATE_INSTANCE_INFO")
f:RegisterEvent("INSPECT_READY")

f:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        InitDB()
        BuildUI()
    elseif event == "PLAYER_LOGIN" then
        addon.loadingGraceUntil = GetTime() + LOADING_GRACE_SECONDS
        addon.pingHideSamples = 5
    elseif event == "PLAYER_ENTERING_WORLD" then
        addon.loadingGraceUntil = GetTime() + LOADING_GRACE_SECONDS
    elseif event == "LOADING_SCREEN_ENABLED" then
        addon.inLoadingScreen = true
    elseif event == "LOADING_SCREEN_DISABLED" then
        addon.inLoadingScreen = false
        addon.loadingGraceUntil = GetTime() + LOADING_GRACE_SECONDS
    elseif event == "UPDATE_INSTANCE_INFO" then
        local now = GetTime()
        addon.lastRaidResponse = now
        addon.timeoutCount = 0
        if addon.isRaidPending then
            AddResponseTime(now - addon.lastRaidRequest)
            addon.isRaidPending = false
        end
    elseif event == "INSPECT_READY" then
        if arg1 == UnitGUID("player") then
            local now = GetTime()
            addon.lastInspectResponse = now
            addon.timeoutCount = 0
            if addon.isInspectPending then
                AddResponseTime(now - addon.lastInspectRequest)
                addon.isInspectPending = false
            end
            if (not InspectFrame or not InspectFrame:IsShown()) and not InCombatLockdown() then ClearInspectPlayer() end
        end
    end
end)
