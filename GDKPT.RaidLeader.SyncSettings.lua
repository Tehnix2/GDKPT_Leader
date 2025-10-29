

GDKPT.RaidLeader.SyncSettings = {}

-------------------------------------------------------------------
-- Button to sync the current auction settings to raidmembers
-------------------------------------------------------------------

local function SyncSettings()
    local data =
        string.format(
        "%d,%d,%d,%d,%d",
        GDKPT.RaidLeader.Core.AuctionSettings.duration,
        GDKPT.RaidLeader.Core.AuctionSettings.extraTime,
        GDKPT.RaidLeader.Core.AuctionSettings.startBid,
        GDKPT.RaidLeader.Core.AuctionSettings.minIncrement,
        GDKPT.RaidLeader.Core.AuctionSettings.splitCount
    )

    if IsInRaid() then
        SendAddonMessage(GDKPT.RaidLeader.Core.addonPrefix, "SETTINGS:" .. data, "RAID")
        print("|cff00ff00[GDKPT Leader]|r Sync current auction settings to raid members.")
    else
        print("|cffff8800[GDKPT Leader]|r Must be in a raid to sync settings.")
    end
end



local SyncSettingsButton = CreateFrame("Button", nil, GDKPLeaderFrame, "GameMenuButtonTemplate")
SyncSettingsButton:SetPoint("CENTER", GDKPLeaderFrame, "CENTER", -100, -50)
SyncSettingsButton:SetSize(150, 20)
SyncSettingsButton:SetText("Sync Settings")
SyncSettingsButton:SetNormalFontObject("GameFontNormalLarge")
SyncSettingsButton:SetHighlightFontObject("GameFontHighlightLarge")

SyncSettingsButton:SetScript(
    "OnClick",
    function()
        SyncSettings()
    end
)




local ResetAuctionsButton = CreateFrame("Button", nil, GDKPLeaderFrame, "GameMenuButtonTemplate")
ResetAuctionsButton:SetPoint("CENTER", GDKPLeaderFrame, "CENTER", -100, -80)
ResetAuctionsButton:SetSize(150, 20)
ResetAuctionsButton:SetText("Reset All Auctions")
ResetAuctionsButton:SetNormalFontObject("GameFontNormalLarge")
ResetAuctionsButton:SetHighlightFontObject("GameFontHighlightLarge")

ResetAuctionsButton:SetScript("OnClick", function()
    StaticPopupDialogs["GDKPT_CONFIRM_RESET"] = {
        text = "Are you sure you want to reset ALL auctions and player balances? This cannot be undone!",
        button1 = "Yes, Reset Everything",
        button2 = "Cancel",
        OnAccept = function()
            GDKPT.RaidLeader.Core.ResetAllAuctions()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
    StaticPopup_Show("GDKPT_CONFIRM_RESET")
end)

local SyncAuctionsButton = CreateFrame("Button", nil, GDKPLeaderFrame, "GameMenuButtonTemplate")
SyncAuctionsButton:SetPoint("CENTER", GDKPLeaderFrame, "CENTER", 100, -80)
SyncAuctionsButton:SetSize(150, 20)
SyncAuctionsButton:SetText("Sync Auctions")
SyncAuctionsButton:SetNormalFontObject("GameFontNormalLarge")
SyncAuctionsButton:SetHighlightFontObject("GameFontHighlightLarge")

SyncAuctionsButton:SetScript("OnClick", function()
    if GDKPT.RaidLeader.SyncSettings and GDKPT.RaidLeader.SyncSettings.SyncActiveAuctions then
        GDKPT.RaidLeader.SyncSettings.SyncActiveAuctions()
    end
end)


local function SyncActiveAuctions(targetPlayer)
    local channel = targetPlayer and "WHISPER" or "RAID"
    local target = targetPlayer or nil
    
    local activeAuctions = {}
    local completedAuctions = {}
    
    -- Initialize pot and clear player balances before rebuilding
    local rebuiltPot = 0
    if wipe then
        wipe(GDKPT.RaidLeader.Core.PlayerBalances)
    else
        GDKPT.RaidLeader.Core.PlayerBalances = {}
    end

    -- Separate active and completed auctions and rebuild pot/balances
    for auctionId, auction in pairs(GDKPT.RaidLeader.Core.ActiveAuctions) do
        if auction.hasEnded then
            table.insert(completedAuctions, {id = auctionId, auction = auction})
        else
            table.insert(activeAuctions, {id = auctionId, auction = auction})
        end

        -- Rebuild pot and player balances from ALL auctions
        if auction.currentBid and auction.currentBid > 0 then
            rebuiltPot = rebuiltPot + auction.currentBid
            
            if auction.topBidder and auction.topBidder ~= "" then
                local player = auction.topBidder
                if not GDKPT.RaidLeader.Core.PlayerBalances[player] then
                    GDKPT.RaidLeader.Core.PlayerBalances[player] = 0
                end
                GDKPT.RaidLeader.Core.PlayerBalances[player] = 
                    GDKPT.RaidLeader.Core.PlayerBalances[player] - auction.currentBid
            end
        end
    end

    local messageDelay = 0
    local delayIncrement = 0.5  -- Increased from 0.1 to reduce message spam

    -- Send active auctions
    for _, data in ipairs(activeAuctions) do
        local auction = data.auction
        local auctionId = data.id
        local remainingDuration = math.max(0, auction.endTime - time())
        local stackCount = auction.stackCount or 
            GDKPT.RaidLeader.Utils.GetInventoryStackCount(auction.itemLink) or 1
    
        local msg = string.format(
            "AUCTION_START:%d:%d:%d:%d:%d:%d:%s",
            auctionId,
            auction.itemID,
            auction.startBid,
            GDKPT.RaidLeader.Core.AuctionSettings.minIncrement,
            remainingDuration,
            stackCount,
            auction.itemLink
        )
        
        C_Timer.After(messageDelay, function()
            if targetPlayer then
                SendAddonMessage(GDKPT.RaidLeader.Core.addonPrefix, msg, channel, target)
            else
                GDKPT.RaidLeader.MessageHandler.SafeSendAddonMessage(
                    GDKPT.RaidLeader.Core.addonPrefix, msg, channel)
            end
            
            -- Send current bid if present
            if auction.currentBid > 0 and auction.topBidder ~= "" then
                C_Timer.After(0.25, function()
                    local remainingTimeForUpdate = math.max(0, auction.endTime - time())
                    local updateMsg = string.format(
                        "AUCTION_UPDATE:%d:%d:%s:%d:%d:%s",
                        auctionId,
                        auction.currentBid,
                        auction.topBidder,
                        remainingTimeForUpdate,
                        auction.itemID,
                        auction.itemLink
                    )
                    
                    if targetPlayer then
                        SendAddonMessage(GDKPT.RaidLeader.Core.addonPrefix, 
                            updateMsg, channel, target)
                    else
                        GDKPT.RaidLeader.MessageHandler.SafeSendAddonMessage(
                            GDKPT.RaidLeader.Core.addonPrefix, updateMsg, channel)
                    end
                end)
            end
        end)
        
        messageDelay = messageDelay + delayIncrement
    end

    -- Send completed auctions
    for _, data in ipairs(completedAuctions) do
        local auction = data.auction
        local auctionId = data.id
        local stackCount = auction.stackCount or 1
        
        C_Timer.After(messageDelay, function()
            -- Send start message with 0 duration for completed auctions
            local msg = string.format(
                "AUCTION_START:%d:%d:%d:%d:%d:%d:%s",
                auctionId,
                auction.itemID,
                auction.startBid,
                GDKPT.RaidLeader.Core.AuctionSettings.minIncrement,
                0,  -- FIXED: Send 0 duration instead of endTime
                stackCount,
                auction.itemLink
            )
            
            if targetPlayer then
                SendAddonMessage(GDKPT.RaidLeader.Core.addonPrefix, msg, channel, target)
            else
                GDKPT.RaidLeader.MessageHandler.SafeSendAddonMessage(
                    GDKPT.RaidLeader.Core.addonPrefix, msg, channel)
            end
            
            -- Send end message
            C_Timer.After(0.25, function()
                local endMsg = string.format(
                    "AUCTION_END:%d:%d:%d:%s:%d",
                    auctionId,
                    auction.currentBid or 0,
                    auction.itemID,
                    auction.topBidder or "",  -- FIXED: Changed from "Bulk" to ""
                    auction.currentBid or 0
                )
                
                if targetPlayer then
                    SendAddonMessage(GDKPT.RaidLeader.Core.addonPrefix, endMsg, channel, target)
                else
                    GDKPT.RaidLeader.MessageHandler.SafeSendAddonMessage(
                        GDKPT.RaidLeader.Core.addonPrefix, endMsg, channel)
                end
            end)
        end)
        
        messageDelay = messageDelay + delayIncrement
    end

    local totalCount = #activeAuctions + #completedAuctions
    if targetPlayer then
        print(string.format("|cff00ff00[GDKPT Leader]|r Synced %d auctions (%d active, %d completed) to %s.", 
            totalCount, #activeAuctions, #completedAuctions, targetPlayer))
    else
        print(string.format("|cff00ff00[GDKPT Leader]|r Synced %d auctions (%d active, %d completed) to raid.", 
            totalCount, #activeAuctions, #completedAuctions))
    end

    GDKPT.RaidLeader.Core.GDKP_Pot = rebuiltPot

    -- Send pot sync after all auctions
    C_Timer.After(messageDelay + 0.5, function()
        local potMsg = string.format("SYNC_POT:%d:%d", 
            GDKPT.RaidLeader.Core.GDKP_Pot, 
            GDKPT.Core.leaderSettings.splitCount)
        if targetPlayer then
            SendAddonMessage(GDKPT.RaidLeader.Core.addonPrefix, potMsg, channel, target)
        else
            GDKPT.RaidLeader.MessageHandler.SafeSendAddonMessage(
                GDKPT.RaidLeader.Core.addonPrefix, potMsg, channel)
        end
    end)

    GDKPT.RaidLeader.UI.UpdateRosterDisplay()
end





--[[

local function SyncActiveAuctions(targetPlayer)
    local channel = targetPlayer and "WHISPER" or "RAID"
    local target = targetPlayer or nil
    
    local activeAuctions = {}
    local completedAuctions = {}
    
    --Initialize pot and clear player balances before rebuilding
    local rebuiltPot = 0
    if wipe then
        wipe(GDKPT.RaidLeader.Core.PlayerBalances)
    else
        GDKPT.RaidLeader.Core.PlayerBalances = {}
    end

    -- Separate active and completed auctions and rebuild pot/balances
    for auctionId, auction in pairs(GDKPT.RaidLeader.Core.ActiveAuctions) do
        -- Separate auctions
        if auction.hasEnded then
            table.insert(completedAuctions, {id = auctionId, auction = auction})
        else
            table.insert(activeAuctions, {id = auctionId, auction = auction})
        end

        -- ADDED: Rebuild pot and player balances from ALL auctions
        if auction.currentBid and auction.currentBid > 0 then
            -- Add to total pot
            rebuiltPot = rebuiltPot + auction.currentBid
            
            -- Add to the player's balance (i.e., their debt to the pot)
            if auction.topBidder and auction.topBidder ~= "" then
                local player = auction.topBidder
                -- Ensure the player has an entry in the table
                if not GDKPT.RaidLeader.Core.PlayerBalances[player] then
                    GDKPT.RaidLeader.Core.PlayerBalances[player] = 0
                end
                -- Add this item's cost to their total balance
                GDKPT.RaidLeader.Core.PlayerBalances[player] = GDKPT.RaidLeader.Core.PlayerBalances[player] - auction.currentBid
            end
        end
    end

    -- Send active auctions
    for _, data in ipairs(activeAuctions) do
        local auction = data.auction
        local auctionId = data.id
        local remainingDuration = math.max(0, auction.endTime - time())
        local stackCount = auction.stackCount or GDKPT.RaidLeader.Utils.GetInventoryStackCount(auction.itemLink) or 1
    
        local msg = string.format(
            "AUCTION_START:%d:%d:%d:%d:%d:%d:%s",
            auctionId,
            auction.itemID,
            auction.startBid,
            GDKPT.RaidLeader.Core.AuctionSettings.minIncrement,
            remainingDuration,
            stackCount,
            auction.itemLink
        )
        
        C_Timer.After(0.1 * auctionId, function()
            if targetPlayer then
                SendAddonMessage(GDKPT.RaidLeader.Core.addonPrefix, msg, channel, target)
            else
                GDKPT.RaidLeader.MessageHandler.SafeSendAddonMessage(GDKPT.RaidLeader.Core.addonPrefix, msg, channel)
            end
            
            -- Send current bid if present
            if auction.currentBid > 0 and auction.topBidder ~= "" then
                C_Timer.After(0.05, function()

                    local remainingTimeForUpdate = math.max(0, auction.endTime - time())
                    local updateMsg = string.format(
                        "AUCTION_UPDATE:%d:%d:%s:%d:%d:%s",
                        auctionId,
                        auction.currentBid,
                        auction.topBidder,
                        remainingTimeForUpdate,
                        auction.itemID,
                        auction.itemLink
                    )
                    
                    if targetPlayer then
                        SendAddonMessage(GDKPT.RaidLeader.Core.addonPrefix, updateMsg, channel, target)
                    else
                        GDKPT.RaidLeader.MessageHandler.SafeSendAddonMessage(GDKPT.RaidLeader.Core.addonPrefix, updateMsg, channel)
                    end
                end)
            end
        end)
    end

    -- Send completed auctions
    for _, data in ipairs(completedAuctions) do
        local auction = data.auction
        local auctionId = data.id
        local stackCount = auction.stackCount or 1
        
        C_Timer.After(0.1 * (#activeAuctions + auctionId), function()
            -- Send start message
            local msg = string.format(
                "AUCTION_START:%d:%d:%d:%d:%d:%d:%s",
                auctionId,
                auction.itemID,
                auction.startBid,
                GDKPT.RaidLeader.Core.AuctionSettings.minIncrement,
                auction.endTime,
                stackCount,
                auction.itemLink
            )
            
            if targetPlayer then
                SendAddonMessage(GDKPT.RaidLeader.Core.addonPrefix, msg, channel, target)
            else
                GDKPT.RaidLeader.MessageHandler.SafeSendAddonMessage(GDKPT.RaidLeader.Core.addonPrefix, msg, channel)
            end
            
            -- Send end message
            C_Timer.After(0.1, function()
                local endMsg = string.format(
                    "AUCTION_END:%d:%d:%d:%s:%d",
                    auctionId,
                    auction.currentBid or 0, -- include current bid for completed auction
                    auction.itemID,
                    auction.topBidder or "Bulk", -- Using "Bulk" as a default seems odd, maybe use ""?
                    auction.currentBid or 0
                )
                
                if targetPlayer then
                    SendAddonMessage(GDKPT.RaidLeader.Core.addonPrefix, endMsg, channel, target)
                else
                    GDKPT.RaidLeader.MessageHandler.SafeSendAddonMessage(GDKPT.RaidLeader.Core.addonPrefix, endMsg, channel)
                end
            end)
        end)
    end

    local totalCount = #activeAuctions + #completedAuctions
    if targetPlayer then
        print(string.format("|cff00ff00[GDKPT Leader]|r Synced %d auctions (%d active, %d completed) to %s.", 
            totalCount, #activeAuctions, #completedAuctions, targetPlayer))
    else
        print(string.format("|cff00ff00[GDKPT Leader]|r Synced %d auctions (%d active, %d completed) to raid.", 
            totalCount, #activeAuctions, #completedAuctions))
    end

    GDKPT.RaidLeader.Core.GDKP_Pot = rebuiltPot
    



    -- Instead, add it once at the very end of the function:
    C_Timer.After(0.2 * (#activeAuctions + #completedAuctions + 1), function()
        local potMsg = string.format("SYNC_POT:%d:%d", GDKPT.RaidLeader.Core.GDKP_Pot, GDKPT.Core.leaderSettings.splitCount)
        if targetPlayer then
            SendAddonMessage(GDKPT.RaidLeader.Core.addonPrefix, potMsg, channel, target)
        else
            GDKPT.RaidLeader.MessageHandler.SafeSendAddonMessage(GDKPT.RaidLeader.Core.addonPrefix, potMsg, channel)
        end
    end)

    GDKPT.RaidLeader.UI.UpdateRosterDisplay()

end

]]


GDKPT.RaidLeader.SyncSettings.SyncActiveAuctions = SyncActiveAuctions







-- Function to sync player balances
local function SyncPlayerBalances(targetPlayer)
    local channel = targetPlayer and "WHISPER" or "RAID"
    local target = targetPlayer or nil
    
    -- Build a comma-separated list of player:balance pairs
    local balanceData = {}
    for playerName, balance in pairs(GDKPT.RaidLeader.Core.PlayerBalances) do
        table.insert(balanceData, string.format("%s:%d", playerName, balance))
    end
    
    if #balanceData > 0 then
        local msg = "SYNC_BALANCES:" .. table.concat(balanceData, ",")
        
        if targetPlayer then
            SendAddonMessage(GDKPT.RaidLeader.Core.addonPrefix, msg, channel, target)
        else
            GDKPT.RaidLeader.MessageHandler.SafeSendAddonMessage(GDKPT.RaidLeader.Core.addonPrefix, msg, channel)
        end
        
        print(string.format("|cff00ff00[GDKPT Leader]|r Synced balances for %d players.", #balanceData))
    end
end

GDKPT.RaidLeader.SyncSettings.SyncPlayerBalances = SyncPlayerBalances







GDKPLeaderFrame:SetScript(
    "OnEvent",
    function(self, event, ...)
        if event == "CHAT_MSG_ADDON" then
            local prefix, message, distribution, sender = ...

            if prefix == GDKPT.RaidLeader.Core.addonPrefix then
                local action = select(1, strsplit(":", message, 2))
                action = GDKPT.RaidLeader.Utils.trim(action)

                if action == "REQUEST_SETTINGS_SYNC" then
                    print("GDKPT Leader: Received setting sync request from " .. sender .. ". Syncing settings.")
                    SyncSettings()
                elseif action == "REQUEST_AUCTION_SYNC" then
                    print("GDKPT Leader: Received auction sync request from " .. sender)
                    SyncActiveAuctions(sender)
                    
                    C_Timer.After(0.5, function()
                        SyncPlayerBalances(sender)
                    end)
                end
            end
        end
    end
)

