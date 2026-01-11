GDKPT.RaidLeader.HistorySync = {}

-------------------------------------------------------------------
-- Handle history sync requests from raid members
-------------------------------------------------------------------

local function HandleHistorySyncRequest(sender, requestData)
    print(string.format(GDKPT.RaidLeader.Core.addonPrintString .. "History sync request from %s", sender))
    
    -- Add raid leader check
    if not IsRaidLeader() and not IsRaidOfficer() then
        print(GDKPT.RaidLeader.Core.errorPrintString .. "Only raid leader/officer can sync history")
        return
    end
    
    -- Use the member addon's history table (since raid leader runs both addons)
    local leaderHistory = GDKPT and GDKPT.Core and GDKPT.Core.History or {}
    
    if not leaderHistory or #leaderHistory == 0 then
        print(GDKPT.RaidLeader.Core.errorPrintString .. "Leader has no history to share!")
        SendAddonMessage(GDKPT.RaidLeader.Core.addonPrefix, "HISTORY_SYNC:", "WHISPER", sender)
        return
    end
    
    -- Parse simple request: just the member's total count
    local memberCount = tonumber(requestData) or 0
    local leaderCount = #leaderHistory
    
    print(string.format(GDKPT.RaidLeader.Core.addonPrintString .. "Member has %d entries, Leader has %d entries", 
        memberCount, leaderCount))
    
    -- If member has same or more entries, they might be up to date
    -- But we'll send everything anyway and let deduplication handle it
    if memberCount >= leaderCount then
        print(GDKPT.RaidLeader.Core.addonPrintString .. "Member appears up to date, but sending all entries for verification")
    end
    
    -- Copy all entries to send
    local entriesToSend = {}
    for _, entry in ipairs(leaderHistory) do
        table.insert(entriesToSend, entry)
    end
    
    -- Sort by timestamp (oldest first)
    table.sort(entriesToSend, function(a, b) return (a.timestamp or 0) < (b.timestamp or 0) end)
    
    print(string.format(GDKPT.RaidLeader.Core.addonPrintString .. "Sending %d entries to %s", 
        #entriesToSend, sender))
    
    -- Send in batches with delay to prevent FPS drops
    local delay = 0.1
    
    for i, entry in ipairs(entriesToSend) do
        -- Extract item ID from link
        local itemID = 0
        if entry.link and entry.link ~= "nil" and entry.link ~= "Bulk Auction" then
            local extractedID = entry.link:match("item:(%d+)")
            itemID = tonumber(extractedID) or 0
        end
        
        -- Format: timestamp,winner,bid,itemID,isAdjustment,isBulk,bulkCount
        local msg = string.format("HISTORY_SYNC:%d,%s,%d,%d,%d,%d,%d",
            entry.timestamp or time(),
            entry.winner or "Unknown",
            entry.bid or 0,
            itemID,
            entry.isAdjustment and 1 or 0,
            entry.isBulkAuction and 1 or 0,
            entry.bulkItemCount or 0
        )
        
        -- Send with delay and whisper to sender only
        local delayTime = (i - 1) * delay
        C_Timer.After(delayTime, function()
            SendAddonMessage(GDKPT.RaidLeader.Core.addonPrefix, msg, "WHISPER", sender)
            
            -- Progress updates every 50 entries
            if i % 50 == 0 or i == #entriesToSend then
                print(string.format(GDKPT.RaidLeader.Core.addonPrintString .. "Sent %d/%d entries to %s", 
                    i, #entriesToSend, sender))
            end
        end)
    end
    
    -- Send final completion message after all entries
    C_Timer.After((#entriesToSend) * delay + 0.5, function()
        print(string.format(GDKPT.RaidLeader.Core.addonPrintString .. "Completed sync to %s (%d entries sent)", 
            sender, #entriesToSend))
    end)
end

-------------------------------------------------------------------
-- Register event handler for history sync requests
-------------------------------------------------------------------

local historySyncFrame = CreateFrame("Frame")
historySyncFrame:RegisterEvent("CHAT_MSG_ADDON")

historySyncFrame:SetScript("OnEvent", function(self, event, prefix, msg, channel, sender)
    if prefix ~= GDKPT.RaidLeader.Core.addonPrefix then return end

    if not IsRaidLeader() and not IsRaidOfficer() then
        return
    end
    
    local cmd, data = msg:match("([^:]+):(.*)")
    if not cmd then return end
    
    if cmd == "REQUEST_HISTORY_SYNC_FROM_LEADER" then
        if IsRaidLeader() and GDKPT.RaidLeader and GDKPT.RaidLeader.HistorySync then
           print(string.format(GDKPT.Core.print .. "Forwarding history sync request from %s to RaidLeader addon", sender))
           HandleHistorySyncRequest(sender, data)
        end
        return
    end
end)