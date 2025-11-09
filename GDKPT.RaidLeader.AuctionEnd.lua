GDKPT.RaidLeader.AuctionEnd = {}



-------------------------------------------------------------------
--- Function to process the end of the auction with a given auction id
-------------------------------------------------------------------


local function ProcessAuctionEnd(id)
    local auction = GDKPT.RaidLeader.Core.ActiveAuctions[id]
    auction.hasEnded = true


    -- Update GDKP pot if there was a valid bid by a player
    if auction.topBidder ~= "" and auction.tipBidder ~= "Bulk" and auction.currentBid > 0 then
        GDKPT.RaidLeader.Core.GDKP_Pot = GDKPT.RaidLeader.Core.GDKP_Pot + auction.currentBid
    end

    -- Store won item for the winning player in the PlayerWonItems table
    if auction.topBidder ~= "Bulk" and auction.currentBid > 0 then
        local player = auction.topBidder
        GDKPT.RaidLeader.Core.PlayerWonItems[player] = GDKPT.RaidLeader.Core.PlayerWonItems[player] or {} -- Initialize if not present

        -- Add won item details
        table.insert(GDKPT.RaidLeader.Core.PlayerWonItems[player], {
            auctionId = id,
            itemID = auction.itemID,
            itemLink = auction.itemLink,
            stackCount = auction.stackCount,
            price = auction.currentBid,
            manuallyAdjusted = false,         -- only changed to true on a manual adjustment
            winningBid = auction.currentBid,  -- probably obsolete? can just use price
            bid = auction.currentBid,         -- probably obsolete? can just use price
            itemHash = auction.itemHash,      -- for checking duplicate items, itemHash should be unique for each auctioned item cause its based on timestamp + bag + slot
            traded = false,                   -- trade parameters
            fullyTraded = false,
            inTradeSlot = nil,
            amountPaid = 0,
            remainingQuantity = auction.stackCount,  -- for partial trades
            timestamp = time(),               -- time when the item was won 
        })
    end

    -- Update AuctionedItems tracking if the item was won by a player (not bulk) for future reference 
    if auction.topBidder ~= "Bulk" and auction.currentBid > 0 and auction.itemHash and GDKPT.RaidLeader.Core.AuctionedItems[auction.itemHash] then
        local trackedAuctionItem = GDKPT.RaidLeader.Core.AuctionedItems[auction.itemHash]  -- unique item instance based on itemHash
        trackedAuctionItem.winner = auction.topBidder
        trackedAuctionItem.winningBid = auction.currentBid
        trackedAuctionItem.hasEnded = true
    end

    -- Deduct gold from the winning bidder's balance, unless won by bulk, and update roster display
    if auction.topBidder ~= "Bulk" then
        GDKPT.RaidLeader.Core.PlayerBalances[auction.topBidder] = (GDKPT.RaidLeader.Core.PlayerBalances[auction.topBidder] or 0) - auction.currentBid
        GDKPT.RaidLeader.PlayerBalance.UpdatePlayerBalance()
    end

    -- Send addon message to all raidmember to update that auction row
    local endMsg = string.format(
        "AUCTION_END:%d:%d:%d:%s:%d",
        id,
        GDKPT.RaidLeader.Core.GDKP_Pot,
        auction.itemID,
        auction.topBidder,
        auction.currentBid
    )
    SendAddonMessage(GDKPT.RaidLeader.Core.addonPrefix, endMsg, "RAID")

    -- Announce auction result
    if auction.topBidder ~= "" then
        SendChatMessage(string.format("[GDKPT] Auction for %s finished! Winner: %s with %d gold!",auction.itemLink,auction.topBidder,auction.currentBid),"RAID")
    else -- No bids placed, so item goes to bulk
        auction.topBidder = "Bulk"
        SendChatMessage(string.format("[GDKPT] Auction for %s finished! No bids. Adding this item to the bulk.",auction.itemLink),"RAID")
    end
end



-------------------------------------------------------------------
--- Function to handle auction updates every second
-------------------------------------------------------------------


local function HandleAuctionUpdates(self, elapsed)
    self.timeSinceLastCheck = (self.timeSinceLastCheck or 0) + elapsed
    if self.timeSinceLastCheck < 1 then return end
    self.timeSinceLastCheck = 0

    for _, auctionId in ipairs(GDKPT.RaidLeader.Utils.GetFinishedAuctions()) do
        ProcessAuctionEnd(auctionId)
    end
end



-------------------------------------------------------------------
--- Frame to check for ended auctions
-------------------------------------------------------------------


local auctionTimerFrame = CreateFrame("Frame")


auctionTimerFrame:SetScript("OnUpdate", function(self, elapsed)
    HandleAuctionUpdates(self, elapsed)
end)




