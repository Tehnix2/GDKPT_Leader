GDKPT.RaidLeader.MessageHandler = {}


-------------------------------------------------------------------
-- Message throttling input field to adjust sendThrottle and
-- SafeSendAddonMessage(prefix,msg,channel)
-- Function to send data to raid members in a throttled way to
-- potentially fix desyncing issues
-------------------------------------------------------------------

GDKPT.RaidLeader.MessageHandler.MessageQueue = {}
local isSending = false
local sendThrottle = 1 -- throttling between different messages
local timeSinceLastSend = 0

-- Message Throttling Input Field

local MessageThrottleLabel = GDKPLeaderFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
MessageThrottleLabel:SetPoint("BOTTOMLEFT", GDKPLeaderFrame, "BOTTOMLEFT", 30, 100)
MessageThrottleLabel:SetText("Message Throttling in seconds: ")

local MessageThrottleBox = CreateFrame("EditBox", nil, GDKPLeaderFrame, "BackdropTemplate")
MessageThrottleBox:SetSize(50, 25)
MessageThrottleBox:SetPoint("BOTTOMRIGHT", GDKPLeaderFrame, "BOTTOMRIGHT", -100, 95)
MessageThrottleBox:SetAutoFocus(false)
MessageThrottleBox:SetText(sendThrottle)

MessageThrottleBox:SetBackdrop(
    {
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        edgeSize = 12,
        insets = {left = 3, right = 3, top = 3, bottom = 3}
    }
)

MessageThrottleBox:SetBackdropColor(0, 0, 0, 1)
MessageThrottleBox:SetBackdropBorderColor(1, 1, 1, 1)
MessageThrottleBox:SetTextInsets(5, 5, 3, 3)
MessageThrottleBox:SetFontObject("GameFontHighlight")

local SaveMessageThrottleButton = CreateFrame("Button", nil, GDKPLeaderFrame, "GameMenuButtonTemplate")
SaveMessageThrottleButton:SetPoint("RIGHT", MessageThrottleBox, "RIGHT", 75, 0)
SaveMessageThrottleButton:SetSize(50, 20)
SaveMessageThrottleButton:SetText("Save")
SaveMessageThrottleButton:SetNormalFontObject("GameFontNormalLarge")
SaveMessageThrottleButton:SetHighlightFontObject("GameFontHighlightLarge")

SaveMessageThrottleButton:SetScript(
    "OnClick",
    function()
        sendThrottle = tonumber(MessageThrottleBox:GetText()) or sendThrottle
        print("Messages can now only sync every " .. sendThrottle .. " seconds.")
        if IsInRaid() then
            SendChatMessage(string.format("[GDKPT] Messages can now only sync every %d seconds.", sendThrottle), "RAID")
        end
        MessageThrottleBox:ClearFocus()
    end
)

MessageThrottleBox:SetScript(
    "OnEnterPressed",
    function()
        SaveMessageThrottleButton:Click()
    end
)

-- Use OnUpdate of a hidden frame to simulate message throttling
local GDKPT_MessageFrame = CreateFrame("Frame", nil, UIParent)

-- Function to process the queue by sending messages one at a time using OnUpdate
local function ProcessQueue(self, elapsed)
    -- Accumulate elapsed time
    timeSinceLastSend = timeSinceLastSend + elapsed

    -- Only attempt to send if the throttle time has passed AND there are messages
    if #GDKPT.RaidLeader.MessageHandler.MessageQueue > 0 and timeSinceLastSend >= sendThrottle then
        -- Reset the timer
        timeSinceLastSend = 0

        -- Get the first message to send
        local msgData = table.remove(GDKPT.RaidLeader.MessageHandler.MessageQueue, 1)
        SendAddonMessage(msgData.prefix, msgData.msg, msgData.channel)
    end

    -- If the queue is now empty, stop the OnUpdate loop
    if #GDKPT.RaidLeader.MessageHandler.MessageQueue == 0 then
        GDKPT_MessageFrame:SetScript("OnUpdate", nil)
        isSending = false
    end
end

-- Attach the OnUpdate script to the frame.
-- Note: We initially set it to nil and only enable it when the queue starts processing.

-- Function to safely queue a message for eventual sending
function GDKPT.RaidLeader.MessageHandler.SafeSendAddonMessage(prefix, msg, channel)
    table.insert(GDKPT.RaidLeader.MessageHandler.MessageQueue, {prefix = prefix, msg = msg, channel = channel})

    -- If the queue isn't already being processed, start the process
    -- by setting the OnUpdate script (if it's not already running).
    if not isSending then
        isSending = true
        timeSinceLastSend = 0 -- Reset timer immediately when starting queue processing
        GDKPT_MessageFrame:SetScript("OnUpdate", ProcessQueue)
    end
end








-------------------------------------------------------------------
-- 
-------------------------------------------------------------------



-------------------------------------------------------------------
-- 
-------------------------------------------------------------------


-------------------------------------------------------------------
-- 
-------------------------------------------------------------------


-------------------------------------------------------------------
-- 
-------------------------------------------------------------------


-------------------------------------------------------------------
-- 
-------------------------------------------------------------------