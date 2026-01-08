GDKPT.RaidLeader.Core = {}

GDKPT.RaidLeader.Core.version = "1.0"

GDKPT.RaidLeader.Core.addonPrefix = "GDKP"  



-------------------------------------------------------------------
-- Items that will not get auto looted, based on item name
-------------------------------------------------------------------

GDKPT.RaidLeader.Core.AutoLootIgnoreList = {
    ["Nether Vortex"] = true,
    ["Ashes of Al'ar"] = true,
    ["Splinter of Atiesh"] = true,
}



-------------------------------------------------------------------
-- Auction Settings and reloading
-------------------------------------------------------------------

-- default auction settings
GDKPT.RaidLeader.Core.DefaultAuctionParameters = {
    duration = 20,         
    extraTime = 5,          
    startBid = 50,         
    minIncrement = 10,             
}

GDKPT.RaidLeader.Core.AuctionSettings = nil

-- Initialize settings from saved variables or defaults
function GDKPT.RaidLeader.Core.InitSettings()

    local savedSettings = GDKPT_RaidLeader_Core_AuctionSettings or {}

    -- Apply defaults for any missing settings
    for k, v in pairs(GDKPT.RaidLeader.Core.DefaultAuctionParameters) do
        if savedSettings[k] == nil then
            savedSettings[k] = v
        end
    end
    -- Save back to the saved variable
    GDKPT_RaidLeader_Core_AuctionSettings = savedSettings
    GDKPT.RaidLeader.Core.AuctionSettings = GDKPT_RaidLeader_Core_AuctionSettings
end

-------------------------------------------------------------------
-- Message Throttling Delay
-------------------------------------------------------------------

GDKPT.RaidLeader.Core.MessageThrottleDelay = 1.0  -- seconds between messages


-------------------------------------------------------------------
-- Active Auctions, used for storing data of ongoing auctions
-------------------------------------------------------------------

-- Next auction ID counter to continue from after reloads
GDKPT.RaidLeader.Core.nextAuctionId = 1  

GDKPT_RaidLeader_Core_ActiveAuctions = GDKPT_RaidLeader_Core_ActiveAuctions or {}
GDKPT.RaidLeader.Core.ActiveAuctions = GDKPT_RaidLeader_Core_ActiveAuctions




function GDKPT.RaidLeader.Core.InitActiveAuctions()
    -- Load saved active auctions
    GDKPT.RaidLeader.Core.ActiveAuctions = GDKPT_RaidLeader_Core_ActiveAuctions
    
    -- Find the highest auction ID to continue from
    local maxId = 0
    for auctionId, _ in pairs(GDKPT.RaidLeader.Core.ActiveAuctions) do
        local numId = tonumber(auctionId)
        if numId and numId > maxId then
            maxId = numId
        end
    end
    GDKPT.RaidLeader.Core.nextAuctionId = maxId + 1
end


-------------------------------------------------------------------
-- Table that stores AuctionedItems with index itemHash so we can more
-- easily find duplicates. itemHash is generated from bag/slot info
-- and timeStamp of Auction start.
-------------------------------------------------------------------

-- Initialized in GDKPT.RaidLeader.AuctionStart.StartAuction and filled in AuctionEnd

GDKPT_RaidLeader_Core_AuctionedItems = GDKPT_RaidLeader_Core_AuctionedItems or {}
GDKPT.RaidLeader.Core.AuctionedItems = GDKPT_RaidLeader_Core_AuctionedItems


function GDKPT.RaidLeader.Core.InitAuctionedItems()
    GDKPT.RaidLeader.Core.AuctionedItems = GDKPT_RaidLeader_Core_AuctionedItems
end


-------------------------------------------------------------------
-- Player Won Items table
-------------------------------------------------------------------

GDKPT_RaidLeader_Core_PlayerWonItems = GDKPT_RaidLeader_Core_PlayerWonItems or {}
GDKPT.RaidLeader.Core.PlayerWonItems = GDKPT_RaidLeader_Core_PlayerWonItems

function GDKPT.RaidLeader.Core.InitPlayerWonItems()
    GDKPT.RaidLeader.Core.PlayerWonItems = GDKPT_RaidLeader_Core_PlayerWonItems
end


-------------------------------------------------------------------
-- Player Balance table
-------------------------------------------------------------------

GDKPT_RaidLeader_Core_PlayerBalances = GDKPT_RaidLeader_Core_PlayerBalances or {}
GDKPT.RaidLeader.Core.PlayerBalances = GDKPT_RaidLeader_Core_PlayerBalances

function GDKPT.RaidLeader.Core.InitPlayerBalances()
    GDKPT.RaidLeader.Core.PlayerBalances = GDKPT_RaidLeader_Core_PlayerBalances
end


-------------------------------------------------------------------
-- Total Gold Pot
-------------------------------------------------------------------

GDKPT.RaidLeader.Core.GDKP_Pot = 0 



-------------------------------------------------------------------
-- Pot Split
-------------------------------------------------------------------

GDKPT.RaidLeader.Core.PotFinalized = false



-------------------------------------------------------------------
-- Standardized RaidLeader addon [GDKPT RaidLeader] print string
-------------------------------------------------------------------

GDKPT.RaidLeader.Core.addonPrintString = "|cff00ff00[GDKPT Leader]|r "
GDKPT.RaidLeader.Core.errorPrintString = "|cffff0000[GDKPT Leader]|r "


-------------------------------------------------------------------
-- When a pot split happens store the current amount of raid members
-- for proper data export
-------------------------------------------------------------------

GDKPT.RaidLeader.Core.ExportSplitCount = 1

-------------------------------------------------------------------
-- Saved Snapshots of Raid Data for saving/loading and exporting 
-- later instead of instantly
-------------------------------------------------------------------

GDKPT_RaidLeader_Core_SavedSnapshots = GDKPT_RaidLeader_Core_SavedSnapshots or {}
GDKPT.RaidLeader.Core.SavedSnapshots = GDKPT_RaidLeader_Core_SavedSnapshots

function GDKPT.RaidLeader.Core.InitSavedSnapshots()
    GDKPT.RaidLeader.Core.SavedSnapshots = GDKPT_RaidLeader_Core_SavedSnapshots
end



-------------------------------------------------------------------
-- Bulk Auction List
-------------------------------------------------------------------

GDKPT_RaidLeader_Core_BulkAuctionList = GDKPT_RaidLeader_Core_BulkAuctionList or {}
GDKPT.RaidLeader.Core.BulkAuctionList = GDKPT_RaidLeader_Core_BulkAuctionList

function GDKPT.RaidLeader.Core.InitBulkAuctionList()
    GDKPT.RaidLeader.Core.BulkAuctionList = GDKPT_RaidLeader_Core_BulkAuctionList
end


-------------------------------------------------------------------
-- Auction History
-------------------------------------------------------------------

GDKPT_RaidLeader_Core_History = GDKPT_RaidLeader_Core_History or {}
GDKPT.RaidLeader.Core.History = GDKPT_RaidLeader_Core_History

function GDKPT.RaidLeader.Core.InitHistory()
    GDKPT.RaidLeader.Core.History = GDKPT_RaidLeader_Core_History
end



-------------------------------------------------------------------
-- Slash Commands
-------------------------------------------------------------------

SLASH_GDKPTLEADER1 = "/gdkpleader"
SlashCmdList["GDKPTLEADER"] = function(message)
    local cmd, param = message:match("^(%S+)%s*(.*)")
    cmd = cmd or ""

    if cmd == "" or cmd == "help" then
        print("|cff00ff00[GDKP Leader]|r Commands:")
        print("  /gdkpleader auction [itemlink] - starts auction for linked item ")
        print("  /gdkpleader hide - hides the leader frame")
        print("  /gdkpleader reset - reset the current session")
        print("  /gdkpleader show - shows the Leader frame ")
        print("  /gdkpleader syncdata - sends current auction data to raidmembers")
        print("  /gdkpleader syncsettings - sends global gdkp parameters to raidmembers")
        print("  /gdkpleader version - shows current leader addon version")
        print("  /gdkpleader versioncheck - causes everyone to post their GDKPT version in raid chat")
    --elseif cmd == "auction" or cmd == "a" then 
    --   GDKPT.RaidLeader.AuctionStart.StartAuctionFromSlashCommand()
    elseif cmd == "auction" or cmd == "a" then 
       local bag, slot = param:match("(%d+):(%d+)")
       if bag and slot then
           local itemLink = GetContainerItemLink(tonumber(bag), tonumber(slot))
           if itemLink then
               GDKPT.RaidLeader.AuctionStart.StartAuction(itemLink, tonumber(bag), tonumber(slot))
           else
               GDKPT.RaidLeader.AuctionStart.StartAuctionFromSlashCommand()
           end
       else
           GDKPT.RaidLeader.AuctionStart.StartAuctionFromSlashCommand()
       end
    elseif cmd == "hide" or cmd == "h" then
        --   GDKPLeaderFrame:Hide()
    elseif cmd == "reset" or cmd == "r" then
        GDKPT.RaidLeader.Reset.ResetAllAuctions()
    elseif cmd == "show" or cmd == "s" then
        GDKPLeaderFrame:Show()
    elseif cmd == "syncdata" or cmd == "sendauctiondata" then
        --    SendAuctionData()
        print("Auction Data is sent to raidmembers.")
    elseif cmd == "syncsettings" or cmd == "sendsettings" then
        print("Sending global GDKP settings to raidmembers.") 
        SyncSettings()
    elseif cmd == "version" or cmd == "v" or cmd == "vers" then
        print("Current GDKPT Leader Addon Version: " .. version)
    elseif cmd == "versioncheck" then
        VersionCheck()
    elseif cmd == "leader" then
        LeaderFrame:Show()
    elseif cmd == "debug" or cmd == "d" then
        print("|cff00ff00[GDKPT Leader]|r Debug Info:")
        print("PlayerWonItems table:")
        for player, items in pairs(GDKPT.RaidLeader.Core.PlayerWonItems) do
            print(string.format("  %s has %d items:", player, #items))
            for i, item in ipairs(items) do
                print(string.format("    %d. ItemID=%d, Traded=%s, Link=%s", 
                    i, item.itemID, tostring(item.traded), item.itemLink or "nil"))
            end
        end
        if not next(GDKPT.RaidLeader.Core.PlayerWonItems) then
            print("  (empty)")
        end
    elseif cmd == "export" or cmd == "e" then
        if GDKPT.RaidLeader.Export then
            GDKPT.RaidLeader.Export.Show()
        end
    elseif cmd == "loot" or cmd == "l" then
        if param ~= "" then
            GDKPT.RaidLeader.AuctionStart.StartAuctionForCorpseLootFromSlashCommand(tonumber(param))
        else
            GDKPT.RaidLeader.AuctionStart.PrintLootSlotsForCorpseAuction()
        end
    elseif cmd == "save" or cmd == "snapshot" then
        local name = param ~= "" and param or nil
        GDKPT.RaidLeader.RaidSnapshots.SaveSnapshot(name)
    elseif cmd == "snapshots" or cmd == "list" then
        GDKPT.RaidLeader.RaidSnapshots.ShowUI()
    elseif cmd == "unload" then
        GDKPT.RaidLeader.RaidSnapshots.UnloadSnapshot()
    elseif cmd == "bulk" or cmd == "b" then
        if param ~= "" then
            GDKPT.RaidLeader.BulkAuction.ToggleItemInBulkList()
        else
            GDKPT.RaidLeader.BulkAuction.ShowBulkList()
        end
    elseif cmd == "debughistory" or cmd == "dh" then
        print("|cff00ff00[GDKPT Leader]|r Debug History:")
        print(string.format("History table size: %d", #GDKPT.RaidLeader.Core.History))
        print(string.format("Saved variable size: %d", GDKPT_RaidLeader_Core_History and #GDKPT_RaidLeader_Core_History or 0))
    
        -- Show first few entries
        if #GDKPT.RaidLeader.Core.History > 0 then
            print("First 3 entries:")
            for i = 1, math.min(3, #GDKPT.RaidLeader.Core.History) do
                local entry = GDKPT.RaidLeader.Core.History[i]
                print(string.format("  %d: %s won for %dg at %s", 
                    i, 
                    entry.winner or "?",
                    entry.bid or 0,
                    entry.timestamp and date("%Y-%m-%d %H:%M:%S", entry.timestamp) or "?"
                ))
            end
        end
    end
end


