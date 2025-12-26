GDKPT.RaidLeader.AuctionEnd = {}



-------------------------------------------------------------------
-- Function to process the end of the auction with a given auction id
-------------------------------------------------------------------


local function ProcessAuctionEnd(id)
    local auction = GDKPT.RaidLeader.Core.ActiveAuctions[id]
    auction.hasEnded = true

    -- If noone has bid on an auction, we now set it to Bulk
    if auction.topBidder == "" then auction.topBidder = "Bulk" end


    -- Update GDKP pot if there was a valid bid by a player
    if auction.topBidder ~= "" and auction.topBidder ~= "Bulk" and auction.currentBid > 0 then
        GDKPT.RaidLeader.Core.GDKP_Pot = GDKPT.RaidLeader.Core.GDKP_Pot + auction.currentBid
    end

    -- Store won item for the winning player in the PlayerWonItems table
    if auction.topBidder ~= "Bulk" and auction.currentBid > 0 then
        local player = auction.topBidder
        GDKPT.RaidLeader.Core.PlayerWonItems[player] = GDKPT.RaidLeader.Core.PlayerWonItems[player] or {} -- Initialize if not present


        if auction.isBulkAuction and auction.bulkItems then
            -- Add each bulk item to player's won items
            for _, bulkItem in ipairs(auction.bulkItems) do
                table.insert(GDKPT.RaidLeader.Core.PlayerWonItems[player], {
                    auctionId = id,
                    itemID = bulkItem.itemID,
                    itemLink = bulkItem.itemLink,
                    stackCount = bulkItem.stackCount,
                    price = 0, -- Bulk items don't have individual prices
                    manuallyAdjusted = false,
                    winningBid = auction.currentBid,
                    bid = auction.currentBid,
                    itemInstanceHash = bulkItem.itemInstanceHash,
                    traded = false,
                    fullyTraded = false,
                    inTradeSlot = nil,
                    amountPaid = 0,
                    remainingQuantity = bulkItem.stackCount,
                    timestamp = time(),
                    isBulkItem = true,
                    bulkAuctionId = id,
                    bagID = bulkItem.bagID,  
                    slotID = bulkItem.slotID,  
                })
            end
        else 
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
                auctionHash = auction.auctionHash,      -- for checking duplicate items, itemHash should be unique for each auctioned item cause its based on timestamp + bag + slot
                itemInstanceHash = auction.itemInstanceHash,-- not based on timestamp hash
                traded = false,                   -- trade parameters
                fullyTraded = false,
                inTradeSlot = nil,
                amountPaid = 0,
                remainingQuantity = auction.stackCount,  -- for partial trades
                timestamp = time(),               -- time when the item was won 
            })
        end
    end

    -- Update AuctionedItems tracking if the item was won by a player (not bulk) for future reference 
    if auction.auctionHash and GDKPT.RaidLeader.Core.AuctionedItems[auction.auctionHash] then
        local trackedAuctionItem = GDKPT.RaidLeader.Core.AuctionedItems[auction.auctionHash]  -- unique item instance based on auctionHash
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

    if auction.topBidder ~= "" and auction.topBidder ~= "Bulk" then
        if auction.isBulkAuction then
            -- Special message for bulk auction wins
            SendChatMessage(string.format("[GDKPT] Bulk Auction finished! Winner: %s with %d gold for %d items!",auction.topBidder,auction.currentBid,
                    #auction.bulkItems),"RAID")
        else
            -- Normal auction message
            SendChatMessage(string.format("[GDKPT] Auction for %s finished! Winner: %s with %d gold!",auction.itemLink,auction.topBidder, auction.currentBid),"RAID")
        end
    else
        -- No bids placed, so item goes to bulk
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




