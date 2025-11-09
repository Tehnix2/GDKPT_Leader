GDKPT.RaidLeader.Sync = {}


-------------------------------------------------------------------
-- Button on the GDKPLeaderFrame to sync the current auction 
-- settings to raidmembers
-------------------------------------------------------------------

local SyncSettingsButton = CreateFrame("Button", nil, GDKPT.RaidLeader.UI.GDKPLeaderFrame, "GameMenuButtonTemplate")
SyncSettingsButton:SetPoint("CENTER", GDKPT.RaidLeader.UI.GDKPLeaderFrame, "CENTER", -100, -50)
SyncSettingsButton:SetSize(150, 20)
SyncSettingsButton:SetText("Sync Settings")
SyncSettingsButton:SetNormalFontObject("GameFontNormalLarge")
SyncSettingsButton:SetHighlightFontObject("GameFontHighlightLarge")


-------------------------------------------------------------------
-- Function to sync current auction settings to raidmembers
-------------------------------------------------------------------


local function SyncSettings()
    local data =
        string.format(
        "%d,%d,%d,%d,%d",
        GDKPT.RaidLeader.Core.AuctionSettings.duration,
        GDKPT.RaidLeader.Core.AuctionSettings.extraTime,
        GDKPT.RaidLeader.Core.AuctionSettings.startBid,
        GDKPT.RaidLeader.Core.AuctionSettings.minIncrement,
        GetNumRaidMembers()  -- should be removed in fute versions
    )

    if IsInRaid() then
        SendAddonMessage(GDKPT.RaidLeader.Core.addonPrefix, "SETTINGS:" .. data, "RAID")
    end
end


-------------------------------------------------------------------
-- Hook up button to sync current auction settings to raidmembers
-------------------------------------------------------------------

SyncSettingsButton:SetScript(
    "OnClick",
    function()
        SyncSettings()
    end
)




-------------------------------------------------------------------
-- Button in the GDKPLeaderFrame to sync current auctions
-------------------------------------------------------------------


local SyncAuctionsButton = CreateFrame("Button", nil, GDKPT.RaidLeader.UI.GDKPLeaderFrame, "GameMenuButtonTemplate")
SyncAuctionsButton:SetPoint("CENTER", GDKPT.RaidLeader.UI.GDKPLeaderFrame, "CENTER", 100, -50)
SyncAuctionsButton:SetSize(150, 20)
SyncAuctionsButton:SetText("Sync Auctions")
SyncAuctionsButton:SetNormalFontObject("GameFontNormalLarge")
SyncAuctionsButton:SetHighlightFontObject("GameFontHighlightLarge")





-------------------------------------------------------------------
-- Function to send current active auctions to a channel
-------------------------------------------------------------------

local function SendActiveAuctions(activeAuctions, channel, targetPlayer, messageDelay, delayIncrement)
    local target = targetPlayer or nil

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
                SendAddonMessage(GDKPT.RaidLeader.Core.addonPrefix, msg, channel)
            end

            -- Send auction update message if bid exists
            if auction.currentBid > 0 and auction.topBidder ~= "" then
                C_Timer.After(0.25, function()
                    local updateMsg = string.format(
                        "AUCTION_UPDATE:%d:%d:%s:%d:%d:%s",
                        auctionId,
                        auction.currentBid,
                        auction.topBidder,
                        remainingDuration,
                        auction.itemID,
                        auction.itemLink
                    )
                    if targetPlayer then
                        SendAddonMessage(GDKPT.RaidLeader.Core.addonPrefix, updateMsg, channel, target)
                    else
                        SendAddonMessage(GDKPT.RaidLeader.Core.addonPrefix, updateMsg, channel)
                    end
                end)
            end
        end)

        messageDelay = messageDelay + delayIncrement
    end

    return messageDelay
end



-------------------------------------------------------------------
-- Function to send completed auctions to a channel
-------------------------------------------------------------------

local function SendCompletedAuctions(completedAuctions, channel, targetPlayer, messageDelay, delayIncrement)
    local target = targetPlayer or nil
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
                0, 
                stackCount,
                auction.itemLink
            )
            if targetPlayer then
                SendAddonMessage(GDKPT.RaidLeader.Core.addonPrefix, msg, channel, target)
            else
                SendAddonMessage(GDKPT.RaidLeader.Core.addonPrefix, msg, channel)
            end
            -- Send end message
            C_Timer.After(0.25, function()
                local endMsg = string.format(
                    "AUCTION_END:%d:%d:%d:%s:%d",
                    auctionId,
                    auction.currentBid or 0,
                    auction.itemID,
                    auction.topBidder or "",  
                    auction.currentBid or 0
                )
                if targetPlayer then
                    SendAddonMessage(GDKPT.RaidLeader.Core.addonPrefix, endMsg, channel, target)
                else
                    SendAddonMessage(GDKPT.RaidLeader.Core.addonPrefix, endMsg, channel)
                end
            end)
        end)
        messageDelay = messageDelay + delayIncrement
    end
    return messageDelay
end


-------------------------------------------------------------------
-- Wrapper function to sync active and completed auctions, either
-- to a specific player if targetPlayer is provided, or to the raid
-------------------------------------------------------------------

local function SyncAuctions(targetPlayer)
    local channel = targetPlayer and "WHISPER" or "RAID"
    local target = targetPlayer or nil
    
    local activeAuctions = {}
    local completedAuctions = {}
    

    -- Force proper numeric order
    local auctionIds = {}
    for auctionId in pairs(GDKPT.RaidLeader.Core.ActiveAuctions) do
        table.insert(auctionIds, auctionId)
    end
    table.sort(auctionIds)


    
    -- Separate active and completed auctions
    for auctionId, auction in pairs(GDKPT.RaidLeader.Core.ActiveAuctions) do
        if auction.hasEnded then
            table.insert(completedAuctions, {id = auctionId, auction = auction})
        else
            table.insert(activeAuctions, {id = auctionId, auction = auction})
        end
    end

    

    local messageDelay = 0
    local delayIncrement = 0.5
    
    -- Send active auctions
    messageDelay = SendActiveAuctions(activeAuctions, channel, targetPlayer, messageDelay, delayIncrement)
    -- Send completed auctions
    messageDelay = SendCompletedAuctions(completedAuctions, channel, targetPlayer, messageDelay, delayIncrement)
end



-------------------------------------------------------------------
-- Function to sync the total pot after all auctions have been sent
-------------------------------------------------------------------

local function SyncPot(targetPlayer, messageDelay)
    local channel = targetPlayer and "WHISPER" or "RAID"
    local target = targetPlayer or nil

    C_Timer.After(messageDelay + 0.5, function()
        local potMsg = string.format("SYNC_POT:%d:%d", 
            GDKPT.RaidLeader.Core.GDKP_Pot, 
            GDKPT.Core.leaderSettings.splitCount)
        if targetPlayer then
            SendAddonMessage(GDKPT.RaidLeader.Core.addonPrefix, potMsg, channel, target)
        else
            SendAddonMessage(GDKPT.RaidLeader.Core.addonPrefix, potMsg, channel)
        end
    end)
end 


-------------------------------------------------------------------
-- Function to sync the player balance to raidmembers
-------------------------------------------------------------------

local function SyncPlayerBalances(targetPlayer,messageDelay)
    local channel = targetPlayer and "WHISPER" or "RAID"
    local target = targetPlayer or nil
    
    -- Build a comma-separated list of player:balance pairs
    local balanceData = {}
    for playerName, balance in pairs(GDKPT.RaidLeader.Core.PlayerBalances) do
        table.insert(balanceData, string.format("%s:%d", playerName, balance))
    end
    
    C_Timer.After(messageDelay + 1, function() 
         -- Send the balance data if there is any
        if #balanceData > 0 then
            local msg = "SYNC_BALANCES:" .. table.concat(balanceData, ",")
        
            if targetPlayer then
                SendAddonMessage(GDKPT.RaidLeader.Core.addonPrefix, msg, channel, target)
            else
                SendAddonMessage(GDKPT.RaidLeader.Core.addonPrefix, msg, channel)
            end
        end    
    end)

end




-------------------------------------------------------------------
-- Hook up button to sync current auctions to raidmembers
-- also syncs the pot after auctions
-------------------------------------------------------------------


SyncAuctionsButton:SetScript("OnClick", function()
    SyncAuctions() --no targetPlayer, sends to raid
    SyncPot(nil, (#GDKPT.RaidLeader.Core.ActiveAuctions * 0.5) + 0.5) --sync pot after auctions with delay
end)






-------------------------------------------------------------------
-- Periodically send a message to the client addon for the member
-- addon to enable GDKP functionalities
-------------------------------------------------------------------


function GDKPT.RaidLeader.Sync.StartLeaderHeartbeat()
    if not GDKPT.RaidLeader.HeartbeatTimer then
        GDKPT.RaidLeader.HeartbeatTimer = C_Timer.NewTicker(30, function()
            if IsInRaid() and GDKPT.RaidLeader.Utils.GetRaidLeaderName() == UnitName("player") then
                SendAddonMessage(GDKPT.RaidLeader.Core.addonPrefix, "LEADER_HEARTBEAT:", "RAID")
            end
        end)
    end
end









-------------------------------------------------------------------
-- Event handler to respond to sync requests from raidmembers
-------------------------------------------------------------------



GDKPT.RaidLeader.UI.GDKPLeaderFrame:SetScript(
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
                    local totalDelay = (#GDKPT.RaidLeader.Core.ActiveAuctions * 0.5) + 0.5

                    SyncAuctions(sender)
                    SyncPot(sender, totalDelay)
    
                    C_Timer.After(0.5, function()
                        SyncPlayerBalances(sender, totalDelay + 1)
                    end)
                    GDKPT.RaidLeader.PlayerBalance.UpdatePlayerBalance()   -- this is called everytime someone else requests a sync, might not be a good solution
                end
            end
        end
    end
)





-------------------------------------------------------------------
-- Expose functions
-------------------------------------------------------------------

GDKPT.RaidLeader.Sync.SyncSettings = SyncSettings
GDKPT.RaidLeader.Sync.SyncAuctions = SyncAuctions
GDKPT.RaidLeader.Sync.SyncPlayerBalances = SyncPlayerBalances
