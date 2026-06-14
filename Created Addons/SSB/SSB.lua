-- Soulseeker Begone --

local function CleanText(text)
    if type(text) == "string" then
        -- Replacing specifically "-Soulseeker" as I can't seem to make it work in any another way
		-- It makes some funny things sometimes, but 99% of the time it works just fine...
        return text:gsub("%-Soulseeker", "")
    end
    return text
end

-- Applying it to the chatframe
for i = 1, NUM_CHAT_WINDOWS do
    local frame = _G["ChatFrame"..i]
    if frame then
        local originalAddMessage = frame.AddMessage
        frame.AddMessage = function(self, text, ...)
            return originalAddMessage(self, CleanText(text), ...)
        end
    end
end