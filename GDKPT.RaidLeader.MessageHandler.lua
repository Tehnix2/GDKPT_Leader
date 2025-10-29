




GDKPT.RaidLeader.MessageHandler = {}


GDKPT.RaidLeader.MessageHandler.MessageQueue = {}
local isSending = false
GDKPT.RaidLeader.MessageHandler.sendThrottle = 1 -- throttling between different messages
local timeSinceLastSend = 0



local GDKPT_MessageFrame = CreateFrame("Frame", nil, UIParent)

local function ProcessQueue(self, elapsed)

    timeSinceLastSend = timeSinceLastSend + elapsed

    if #GDKPT.RaidLeader.MessageHandler.MessageQueue > 0 and timeSinceLastSend >= GDKPT.RaidLeader.MessageHandler.sendThrottle then
        timeSinceLastSend = 0
        local msgData = table.remove(GDKPT.RaidLeader.MessageHandler.MessageQueue, 1)
        SendAddonMessage(msgData.prefix, msgData.msg, msgData.channel)
    end

    if #GDKPT.RaidLeader.MessageHandler.MessageQueue == 0 then
        GDKPT_MessageFrame:SetScript("OnUpdate", nil)
        isSending = false
    end
end



function GDKPT.RaidLeader.MessageHandler.SafeSendAddonMessage(prefix, msg, channel)
    table.insert(GDKPT.RaidLeader.MessageHandler.MessageQueue, {prefix = prefix, msg = msg, channel = channel})

    if not isSending then
        isSending = true
        timeSinceLastSend = 0 
        GDKPT_MessageFrame:SetScript("OnUpdate", ProcessQueue)
    end
end

