GDKPT.RaidLeader.Core = {}

GDKPT.RaidLeader.Core.version = 0.33

GDKPT.RaidLeader.Core.addonPrefix = "GDKP"  



-------------------------------------------------------------------
-- Items that will not get auto looted, based on item name
-------------------------------------------------------------------

GDKPT.RaidLeader.Core.AutoLootIgnoreList = {
    ["Nether Vortex"] = true,
    ["Ashes of Al'ar"] = true,
    ["Splinter of Atiesh"] = true,
    ["Sceptre of Smiting"] = true
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
    splitCount = 25         
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
GDKPT.RaidLeader.Core.AuctionedItems = GDKPT.RaidLeader.Core.AuctionedItems or {}



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
    elseif cmd == "auction" or cmd == "a" then 
       GDKPT.RaidLeader.AuctionStart.StartAuctionFromSlashCommand()
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
    end

end


