GDKPT.RaidLeader.Reload = {}

-- TODO: on clientside the manual adjustments are not saved to the server yet, so reloading will lose them


-------------------------------------------------------------------
-- Function to rebuild pot and player balances from all auctions
-------------------------------------------------------------------

local function RebuildPotAndBalances()
    -- Initialize pot and clear player balances before rebuilding
    local rebuiltPot = 0
    if wipe then 
        wipe(GDKPT.RaidLeader.Core.PlayerBalances)
    else
        GDKPT.RaidLeader.Core.PlayerBalances = {}
    end
    -- Rebuild pot and player balances from ALL auctions
    for auctionId, auction in pairs(GDKPT.RaidLeader.Core.ActiveAuctions) do
        if auction.currentBid and auction.currentBid > 0 and auction.hasEnded then
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
    GDKPT.RaidLeader.Core.GDKP_Pot = rebuiltPot

    GDKPT.RaidLeader.PlayerBalance.UpdatePlayerBalance() -- Update UI after rebuilding
end 




-------------------------------------------------------------------
-- Function to reload all data
-------------------------------------------------------------------

function GDKPT.RaidLeader.Reload.ReloadAllData()
    RebuildPotAndBalances()
end 

