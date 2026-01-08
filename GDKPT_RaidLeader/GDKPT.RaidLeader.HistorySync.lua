GDKPT.RaidLeader.HistorySync = {}

-------------------------------------------------------------------
-- Handle history sync requests from raid members
-------------------------------------------------------------------

local function HandleHistorySyncRequest(sender, memberHistoryHashes)
    print(string.format(GDKPT.RaidLeader.Core.addonPrintString .. "History sync request from %s", sender))
    
    -- Use the member addon's history table (since raid leader runs both addons)
    local leaderHistory = GDKPT and GDKPT.Core and GDKPT.Core.History or {}
    
    if not leaderHistory or #leaderHistory == 0 then
        print(GDKPT.RaidLeader.Core.errorPrintString .. "Leader has no history to share!")
        SendAddonMessage(GDKPT.RaidLeader.Core.addonPrefix, "HISTORY_SYNC:", "RAID")
        return
    end
    
    -- Parse member's existing entry hashes
    local memberHashes = {}
    local memberHashCount = 0
    if memberHistoryHashes and memberHistoryHashes ~= "" then
        for hash in memberHistoryHashes:gmatch("[^,]+") do
            memberHashes[hash] = true
            memberHashCount = memberHashCount + 1
        end
    end
    
    print(string.format(GDKPT.RaidLeader.Core.addonPrintString .. "Member has %d existing entries", memberHashCount))
    
    -- Collect entries that member doesn't have
    local entriesToSend = {}
    
    for _, entry in ipairs(leaderHistory) do
        local hash = string.format("%d_%s_%d", 
            entry.timestamp or 0,
            entry.winner or "",
            entry.bid or 0
        )
        
        if not memberHashes[hash] then
            table.insert(entriesToSend, entry)
        end
    end
    
    print(string.format(GDKPT.RaidLeader.Core.addonPrintString .. "Found %d entries to send (leader has %d total)", 
        #entriesToSend, #leaderHistory))
    
    if #entriesToSend == 0 then
        SendAddonMessage(GDKPT.RaidLeader.Core.addonPrefix, "HISTORY_SYNC:", "RAID")
        print(GDKPT.RaidLeader.Core.addonPrintString .. "Member history is up to date.")
        return
    end
    
    -- Sort by timestamp (oldest first)
    table.sort(entriesToSend, function(a, b) return (a.timestamp or 0) < (b.timestamp or 0) end)
    
    -- Send entries - extract item ID from link
    local totalEntries = #entriesToSend
    
    for i, entry in ipairs(entriesToSend) do
        -- Extract item ID from link
        local itemID = 0
        if entry.link and entry.link ~= "nil" then
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
        
        -- Send with delay to avoid flooding
        local delay = (i - 1) * 0.05
        C_Timer.After(delay, function()
            SendAddonMessage(GDKPT.RaidLeader.Core.addonPrefix, msg, "RAID")
            
            -- Progress updates every 100 entries
            if i % 100 == 0 or i == totalEntries then
                print(string.format(GDKPT.RaidLeader.Core.addonPrintString .. "Sent %d/%d entries", 
                    i, totalEntries))
            end
        end)
    end
    
    print(string.format(GDKPT.RaidLeader.Core.addonPrintString .. "Queued %d history entries to %s (will take ~%.1f seconds)", 
        totalEntries, sender, totalEntries * 0.05))
end

-------------------------------------------------------------------
-- Register event handler for history sync requests
-------------------------------------------------------------------

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("CHAT_MSG_ADDON")

eventFrame:SetScript("OnEvent", function(self, event, prefix, msg, channel, sender)
    if prefix ~= GDKPT.RaidLeader.Core.addonPrefix then return end
    
    local cmd, data = msg:match("^([^:]+):(.*)$")
    if not cmd then return end
    
    if cmd == "REQUEST_HISTORY_SYNC" then
        HandleHistorySyncRequest(sender, data)
    end
end)