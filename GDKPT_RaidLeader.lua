-- Parallelized GDKP Addon for 3.3.5 servers
-- RaidLeader Version


local version = 0.24

local addonPrefix = "GDKP"  -- Variable for addon communication to member addon


-- Global default settings that can be adjusted ingame
local AuctionSettings = {     
    duration = 20,          -- Auction Duration
    extraTime = 5,          -- additional time per bid
    startBid = 50,          -- staring gold amound
    minIncrement = 10,      -- minimum increment from previous bid for bidding
    splitCount = 25         -- amount of players to split the gold by
}

local ActiveAuctions = {}  -- Table that tracks all active auctions
local nextAuctionId = 1    -- Auction Index inside the table


local GDKP_Pot = 0         -- Total pot




-------------------------------------------------------------------
-- Leader Frame that holds all adjustable settings
-------------------------------------------------------------------

    local GDKPLeaderFrame = CreateFrame("Frame","GDKPLeaderFrame",UIParent)

    GDKPLeaderFrame:SetSize(400,600)
    GDKPLeaderFrame:SetMovable(true)
    GDKPLeaderFrame:EnableMouse(true)
    GDKPLeaderFrame:RegisterForDrag("LeftButton")
    GDKPLeaderFrame:SetPoint("CENTER")
    GDKPLeaderFrame:Hide()
    GDKPLeaderFrame:SetFrameLevel(10)
    GDKPLeaderFrame:SetBackdrop({                           
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",     
        edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
        edgeSize = 20,
        insets = { left = 5, right = 5, top = 5, bottom = 5 }
    })

    GDKPLeaderFrame:SetScript("OnDragStart", GDKPLeaderFrame.StartMoving)
    GDKPLeaderFrame:SetScript("OnDragStop", GDKPLeaderFrame.StopMovingOrSizing)


    _G["GDKPLeaderFrame"] = GDKPLeaderFrame 
    tinsert(UISpecialFrames,"GDKPLeaderFrame")


    local CloseGDKPLeaderFrameButton = CreateFrame("Button","", GDKPLeaderFrame, "UIPanelCloseButton")
    CloseGDKPLeaderFrameButton:SetPoint("TOPRIGHT", -5, -5)
    CloseGDKPLeaderFrameButton:SetSize(35, 35)



    local GDKPLeaderFrameTitleBar = CreateFrame("Frame", "", GDKPLeaderFrame, nil)
    GDKPLeaderFrameTitleBar:SetSize(180, 25)
    GDKPLeaderFrameTitleBar:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
        tile = true,
        edgeSize = 16,
        tileSize = 16,
        insets = { left = 5, right = 5, top = 5, bottom = 5 }
    })
    GDKPLeaderFrameTitleBar:SetPoint("TOP", 0, 0)


    local GDKPLeaderFrameTitleText = GDKPLeaderFrameTitleBar:CreateFontString("")
    GDKPLeaderFrameTitleText:SetFont("Fonts\\FRIZQT__.TTF", 14)
    GDKPLeaderFrameTitleText:SetText("|cffFFC125GDKPT Leader " .. "- v " .. version .. "|r")
    GDKPLeaderFrameTitleText:SetPoint("CENTER", 0, 0)


   GDKPLeaderFrame:RegisterEvent("CHAT_MSG_ADDON")
   GDKPLeaderFrame:RegisterEvent("ADDON_LOADED")




-------------------------------------------------------------------
-- Input fields to adjust global settings
-------------------------------------------------------------------



    -- Auction Duration
    local DurationLabel = GDKPLeaderFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    DurationLabel:SetPoint("TOPLEFT", GDKPLeaderFrame, "TOPLEFT", 30, -50)
    DurationLabel:SetText("Auction Duration in Seconds:")

    local DurationBox = CreateFrame("EditBox", nil, GDKPLeaderFrame, "BackdropTemplate")
    DurationBox:SetSize(50, 25)
    DurationBox:SetPoint("TOPRIGHT", GDKPLeaderFrame, "TOPRIGHT", -100, -45)
    DurationBox:SetAutoFocus(false)
    DurationBox:SetText(AuctionSettings.duration)

    DurationBox:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })

    DurationBox:SetBackdropColor(0, 0, 0, 1)
    DurationBox:SetBackdropBorderColor(1, 1, 1, 1)
    DurationBox:SetTextInsets(5, 5, 3, 3)
    DurationBox:SetFontObject("GameFontHighlight")


    local SaveDurationButton = CreateFrame("Button", nil, GDKPLeaderFrame, "GameMenuButtonTemplate")
    SaveDurationButton:SetPoint("RIGHT", DurationBox, "RIGHT", 75, 0)
    SaveDurationButton:SetSize(50, 20)
    SaveDurationButton:SetText("Save")
    SaveDurationButton:SetNormalFontObject("GameFontNormalLarge")
    SaveDurationButton:SetHighlightFontObject("GameFontHighlightLarge")


    SaveDurationButton:SetScript("OnClick", function()
        AuctionSettings.duration = tonumber(DurationBox:GetText()) or AuctionSettings.duration
        print("Auctions now last for " .. AuctionSettings.duration .. " seconds.")
        if IsInRaid() then
            SendChatMessage(string.format("[GDKPT] Auction duration has been changed to %d seconds.", AuctionSettings.duration),"RAID")
        end
        DurationBox:ClearFocus()
    end)

    DurationBox:SetScript("OnEnterPressed", function()
        SaveDurationButton:Click() 
    end)

    -- Extra time per bid on an auction


    local extraTimeLabel = GDKPLeaderFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    extraTimeLabel:SetPoint("TOPLEFT", GDKPLeaderFrame, "TOPLEFT", 30, -100)
    extraTimeLabel:SetText("Extra time per bid in seconds:")


    local ExtraTimeBox = CreateFrame("EditBox", nil, GDKPLeaderFrame, "BackdropTemplate")
    ExtraTimeBox:SetSize(50, 25)
    ExtraTimeBox:SetPoint("TOPRIGHT", GDKPLeaderFrame, "TOPRIGHT", -100, -95)
    ExtraTimeBox:SetAutoFocus(false)
    ExtraTimeBox:SetText(AuctionSettings.extraTime)

    ExtraTimeBox:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })


    ExtraTimeBox:SetBackdropColor(0, 0, 0, 1)
    ExtraTimeBox:SetBackdropBorderColor(1, 1, 1, 1)
    ExtraTimeBox:SetTextInsets(5, 5, 3, 3)
    ExtraTimeBox:SetFontObject("GameFontHighlight")



    local SaveExtraTimeButton = CreateFrame("Button", nil, GDKPLeaderFrame, "GameMenuButtonTemplate")
    SaveExtraTimeButton:SetPoint("RIGHT", ExtraTimeBox, "RIGHT", 75, 0)
    SaveExtraTimeButton:SetSize(50, 20)
    SaveExtraTimeButton:SetText("Save")
    SaveExtraTimeButton:SetNormalFontObject("GameFontNormalLarge")
    SaveExtraTimeButton:SetHighlightFontObject("GameFontHighlightLarge")


    SaveExtraTimeButton:SetScript("OnClick", function()
        AuctionSettings.extraTime = tonumber(ExtraTimeBox:GetText()) or AuctionSettings.extraTime
        print("Each bid now increases the auction duration by " .. AuctionSettings.extraTime .. " seconds.")
        if IsInRaid() then
            SendChatMessage(string.format("[GDKPT] Each bid now increases the auction duration by %d seconds.", AuctionSettings.extraTime),"RAID")
        end
        ExtraTimeBox:ClearFocus()
    end)

    ExtraTimeBox:SetScript("OnEnterPressed", function()
        SaveExtraTimeButton:Click() 
    end)


    -- Starting bid

    local StartBidLabel = GDKPLeaderFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    StartBidLabel:SetPoint("TOPLEFT", GDKPLeaderFrame, "TOPLEFT", 30, -150)
    StartBidLabel:SetText("Starting Bid for all Items in gold:")


    local StartBidBox = CreateFrame("EditBox", nil, GDKPLeaderFrame, "BackdropTemplate")
    StartBidBox:SetSize(50, 25)
    StartBidBox:SetPoint("TOPRIGHT", GDKPLeaderFrame, "TOPRIGHT", -100, -145)
    StartBidBox:SetAutoFocus(false)
    StartBidBox:SetText(AuctionSettings.startBid)


    StartBidBox:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })


    StartBidBox:SetBackdropColor(0, 0, 0, 1)
    StartBidBox:SetBackdropBorderColor(1, 1, 1, 1)
    StartBidBox:SetTextInsets(5, 5, 3, 3)
    StartBidBox:SetFontObject("GameFontHighlight")


    local SaveStartBidButton = CreateFrame("Button", nil, GDKPLeaderFrame, "GameMenuButtonTemplate")
    SaveStartBidButton:SetPoint("RIGHT", StartBidBox, "RIGHT", 75, 0)
    SaveStartBidButton:SetSize(50, 20)
    SaveStartBidButton:SetText("Save")
    SaveStartBidButton:SetNormalFontObject("GameFontNormalLarge")
    SaveStartBidButton:SetHighlightFontObject("GameFontHighlightLarge")


    SaveStartBidButton:SetScript("OnClick", function()
        AuctionSettings.startBid = tonumber(StartBidBox:GetText()) or AuctionSettings.startBid
        print("Starting Bid for all auctions is now " .. AuctionSettings.startBid .. " gold.")
        if IsInRaid() then
            SendChatMessage(string.format("[GDKPT] Starting bid is now %d gold.", AuctionSettings.startBid),"RAID")
        end
        StartBidBox:ClearFocus()
    end)

    StartBidBox:SetScript("OnEnterPressed", function()
        SaveStartBidButton:Click()
    end)


    -- Minimum increment


    local MinIncLabel = GDKPLeaderFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    MinIncLabel:SetPoint("TOPLEFT", GDKPLeaderFrame, "TOPLEFT", 30, -200)
    MinIncLabel:SetText("Minimum increment in gold: ")


    local MinIncBox = CreateFrame("EditBox", nil, GDKPLeaderFrame, "BackdropTemplate")
    MinIncBox:SetSize(50, 25)
    MinIncBox:SetPoint("TOPRIGHT", GDKPLeaderFrame, "TOPRIGHT", -100, -195)
    MinIncBox:SetAutoFocus(false)
    MinIncBox:SetText(AuctionSettings.minIncrement)

    MinIncBox:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })


    MinIncBox:SetBackdropColor(0, 0, 0, 1)
    MinIncBox:SetBackdropBorderColor(1, 1, 1, 1)
    MinIncBox:SetTextInsets(5, 5, 3, 3)
    MinIncBox:SetFontObject("GameFontHighlight")




    local SaveMinIncButton = CreateFrame("Button", nil, GDKPLeaderFrame, "GameMenuButtonTemplate")
    SaveMinIncButton:SetPoint("RIGHT", MinIncBox, "RIGHT", 75, 0)
    SaveMinIncButton:SetSize(50, 20)
    SaveMinIncButton:SetText("Save")
    SaveMinIncButton:SetNormalFontObject("GameFontNormalLarge")
    SaveMinIncButton:SetHighlightFontObject("GameFontHighlightLarge")


    SaveMinIncButton:SetScript("OnClick", function()
        AuctionSettings.minIncrement = tonumber(MinIncBox:GetText()) or AuctionSettings.minIncrement
        print("Minimum increment is now " .. AuctionSettings.minIncrement .. " gold.")
        if IsInRaid() then
            SendChatMessage(string.format("[GDKPT] Minimum increments are now %d gold.", AuctionSettings.minIncrement),"RAID")
        end
        MinIncBox:ClearFocus()
    end)

    MinIncBox:SetScript("OnEnterPressed", function()
        SaveMinIncButton:Click()
    end)


    -- Amount of players to split the total gold by 


    local SplitByCountLabel = GDKPLeaderFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    SplitByCountLabel:SetPoint("TOPLEFT", GDKPLeaderFrame, "TOPLEFT", 30, -250)
    SplitByCountLabel:SetText("Amount of players to split gold by: ")


    local SplitByCountBox = CreateFrame("EditBox", nil, GDKPLeaderFrame, "BackdropTemplate")
    SplitByCountBox:SetSize(50, 25)
    SplitByCountBox:SetPoint("TOPRIGHT", GDKPLeaderFrame, "TOPRIGHT", -100, -245)
    SplitByCountBox:SetAutoFocus(false)
    SplitByCountBox:SetText(AuctionSettings.splitCount)


    SplitByCountBox:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })


    SplitByCountBox:SetBackdropColor(0, 0, 0, 1)
    SplitByCountBox:SetBackdropBorderColor(1, 1, 1, 1)
    SplitByCountBox:SetTextInsets(5, 5, 3, 3)
    SplitByCountBox:SetFontObject("GameFontHighlight")


    local SaveSplitByCountButton = CreateFrame("Button", nil, GDKPLeaderFrame, "GameMenuButtonTemplate")
    SaveSplitByCountButton:SetPoint("RIGHT", SplitByCountBox, "RIGHT", 75, 0)
    SaveSplitByCountButton:SetSize(50, 20)
    SaveSplitByCountButton:SetText("Save")
    SaveSplitByCountButton:SetNormalFontObject("GameFontNormalLarge")
    SaveSplitByCountButton:SetHighlightFontObject("GameFontHighlightLarge")

    SaveSplitByCountButton:SetScript("OnClick", function()
        AuctionSettings.splitCount = tonumber(SplitByCountBox:GetText()) or AuctionSettings.splitCount
        print("Total pot is now being split by " .. AuctionSettings.splitCount .. " players.")
        if IsInRaid() then
            SendChatMessage(string.format("[GDKPT] The total pot will be split by %d players.", AuctionSettings.splitCount),"RAID")
        end
        SplitByCountBox:ClearFocus()
    end)


    SplitByCountBox:SetScript("OnEnterPressed", function()
        SaveSplitByCountButton:Click()
    end)





-------------------------------------------------------------------
-- Button to sync the current auction settings to raidmembers
-------------------------------------------------------------------

    local function SyncSettings()
        local data = string.format("%d,%d,%d,%d,%d",
            AuctionSettings.duration,
            AuctionSettings.extraTime,
            AuctionSettings.startBid,
            AuctionSettings.minIncrement,
            AuctionSettings.splitCount
        )
    
        if IsInRaid() then
            SendAddonMessage(addonPrefix, "SETTINGS:" .. data, "RAID")
            print("|cff00ff00[GDKPT Leader]|r Sync current auction settings to raid members.")
        else
            print("|cffff8800[GDKPT Leader]|r Must be in a raid to sync settings.")
        end
    end

    



    local SyncSettingsButton = CreateFrame("Button", nil, GDKPLeaderFrame, "GameMenuButtonTemplate")
    SyncSettingsButton:SetPoint("CENTER", GDKPLeaderFrame, "CENTER", 0, -100)
    SyncSettingsButton:SetSize(150, 20)
    SyncSettingsButton:SetText("Sync Settings")
    SyncSettingsButton:SetNormalFontObject("GameFontNormalLarge")
    SyncSettingsButton:SetHighlightFontObject("GameFontHighlightLarge")

    SyncSettingsButton:SetScript("OnClick", function()
        SyncSettings()
    end)






-------------------------------------------------------------------
-- Versioncheck button
-------------------------------------------------------------------

    local function VersionCheck()
        if IsInRaid() then
            print("|cffff8800[GDKPT Leader]|r Checking raid members GDKPT versions.")
            SendAddonMessage(addonPrefix, "VERSION_CHECK:0","RAID")
        else 
            print("|cffff8800[GDKPT Leader]|r Must be in a raid to check for GDKPT versions.")
        end
    end


    local VersionCheckButton = CreateFrame("Button", nil, GDKPLeaderFrame, "GameMenuButtonTemplate")
    VersionCheckButton:SetPoint("CENTER", GDKPLeaderFrame, "CENTER", 0, -140)
    VersionCheckButton:SetSize(150, 20)
    VersionCheckButton:SetText("Version Check")
    VersionCheckButton:SetNormalFontObject("GameFontNormalLarge")
    VersionCheckButton:SetHighlightFontObject("GameFontHighlightLarge")

    VersionCheckButton:SetScript("OnClick", function()
        VersionCheck()
    end)






-------------------------------------------------------------------
-- Message throttling input field to adjust sendThrottle and 
-- SafeSendAddonMessage(prefix,msg,channel)
-- Function to send data to raid members in a throttled way to 
-- potentially fix desyncing issues
-------------------------------------------------------------------


    local MessageQueue = {}
    local isSending = false
    local sendThrottle = 1   -- throttling between different messages
    local timeSinceLastSend = 0



    -- Message Throttling Input Field



    local MessageThrottleLabel = GDKPLeaderFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    MessageThrottleLabel:SetPoint("BOTTOMLEFT", GDKPLeaderFrame, "BOTTOMLEFT", 30, 100)
    MessageThrottleLabel:SetText("Message Throttling in seconds: ")


    local MessageThrottleBox = CreateFrame("EditBox", nil, GDKPLeaderFrame, "BackdropTemplate")
    MessageThrottleBox:SetSize(50, 25)
    MessageThrottleBox:SetPoint("BOTTOMRIGHT", GDKPLeaderFrame, "BOTTOMRIGHT", -100, 95)
    MessageThrottleBox:SetAutoFocus(false)
    MessageThrottleBox:SetText(sendThrottle)


    MessageThrottleBox:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })


    MessageThrottleBox:SetBackdropColor(0, 0, 0, 1)
    MessageThrottleBox:SetBackdropBorderColor(1, 1, 1, 1)
    MessageThrottleBox:SetTextInsets(5, 5, 3, 3)
    MessageThrottleBox:SetFontObject("GameFontHighlight")


    local SaveMessageThrottleButton = CreateFrame("Button", nil, GDKPLeaderFrame, "GameMenuButtonTemplate")
    SaveMessageThrottleButton:SetPoint("RIGHT", MessageThrottleBox, "RIGHT", 75, 0)
    SaveMessageThrottleButton:SetSize(50, 20)
    SaveMessageThrottleButton:SetText("Save")
    SaveMessageThrottleButton:SetNormalFontObject("GameFontNormalLarge")
    SaveMessageThrottleButton:SetHighlightFontObject("GameFontHighlightLarge")


    SaveMessageThrottleButton:SetScript("OnClick", function()
        sendThrottle = tonumber(MessageThrottleBox:GetText()) or sendThrottle
        print("Messages can now only sync every " .. sendThrottle .. " seconds.")
        if IsInRaid() then
            SendChatMessage(string.format("[GDKPT] Messages can now only sync every %d seconds.", sendThrottle),"RAID")
        end
        MessageThrottleBox:ClearFocus()
    end)

    MessageThrottleBox:SetScript("OnEnterPressed", function()
        SaveMessageThrottleButton:Click()
    end)


    -- Use OnUpdate of a hidden frame to simulate message throttling
    local GDKPT_MessageFrame = CreateFrame("Frame", nil, UIParent)


    -- Function to process the queue by sending messages one at a time using OnUpdate
    local function ProcessQueue(self, elapsed)
        -- Accumulate elapsed time
        timeSinceLastSend = timeSinceLastSend + elapsed

        -- Only attempt to send if the throttle time has passed AND there are messages
        if #MessageQueue > 0 and timeSinceLastSend >= sendThrottle then
        
            -- Reset the timer
            timeSinceLastSend = 0
        
            -- Get the first message to send
            local msgData = table.remove(MessageQueue, 1)
            SendAddonMessage(msgData.prefix, msgData.msg, msgData.channel)
        end
    
        -- If the queue is now empty, stop the OnUpdate loop
        if #MessageQueue == 0 then
            GDKPT_MessageFrame:SetScript("OnUpdate", nil)
            isSending = false
        end
    end

    -- Attach the OnUpdate script to the frame.
    -- Note: We initially set it to nil and only enable it when the queue starts processing.


    -- Function to safely queue a message for eventual sending
    local function SafeSendAddonMessage(prefix, msg, channel)
        table.insert(MessageQueue, {prefix = prefix, msg = msg, channel = channel})

        -- If the queue isn't already being processed, start the process 
        -- by setting the OnUpdate script (if it's not already running).
        if not isSending then
            isSending = true
            timeSinceLastSend = 0 -- Reset timer immediately when starting queue processing
            GDKPT_MessageFrame:SetScript("OnUpdate", ProcessQueue)
        end
    end











------------------------------------------------------------------------
-- StartAuction(itemLink)
-- Function that handles starting a new auction on the member frame
-- called through ingame mouseover /gdkpleader auction [itemlink] macro
------------------------------------------------------------------------




    local function StartAuction(itemLink)

        if not IsRaidLeader() and not IsRaidOfficer() then
            print("|cffff0000Only the Raid Leader or an Officer can start auctions.|r")
            return
        end

        local itemID = tonumber(itemLink:match("item:(%d+)"))
        if not itemID then
            print("|cffff0000Invalid item link. Cannot start an auction for this item.|r")
            return
        end

        -- every /gdkpleader auctioned item gets stored in a new row of the ActiveAuctions table with row index auctionID

        local auctionId = nextAuctionId
        nextAuctionId = nextAuctionId + 1

        -- Store item information from /gdkp auction [itemlink] mouseovered item in a table
        ActiveAuctions[auctionId] = {
            id = auctionId,
            itemID = itemID,
            itemLink = itemLink,
            startTime = GetTime(),
            endTime = GetTime() + AuctionSettings.duration,
            startBid = AuctionSettings.startBid,
            currentBid = 0,
            topBidder = "",
            history = {}     
        }

        -- Announce to raid and send data to member addons
        local msg = string.format("AUCTION_START:%d:%d:%d:%d:%d:%s",
            auctionId,
            itemID,
            AuctionSettings.startBid,
            AuctionSettings.minIncrement,
            ActiveAuctions[auctionId].endTime,
            itemLink
        )
        SendChatMessage(string.format("[GDKPT] Bidding starts on %s! Starting at %d gold.", itemLink, AuctionSettings.startBid), "RAID")

        C_Timer.After(1, function()
            SafeSendAddonMessage(addonPrefix, msg, "RAID")
        end)
    end








-------------------------------------------------------------------
-- HandleBid() function is triggered from the event frame below
-- whenever a raidmember is bidding on an item
-------------------------------------------------------------------




    local function HandleBid(sender, auctionId, bidAmount)

        -- auctionId and bidAmount get sent over as string, so need to conver to number
        auctionId = tonumber(auctionId)
        bidAmount = tonumber(bidAmount)
    
        local auction = ActiveAuctions[auctionId]

        if not auction then return end -- Auction doesn't exist or is over


        -- Validate the incoming bid once more for safety reasons

        if bidAmount and bidAmount < auction.currentBid + AuctionSettings.minIncrement then
            print("Incoming bid is incorrect")
            return 
        end


        -- If the incoming bid is validated, then update the currentBid and topBidder for this auction
        if bidAmount and sender then
            auction.currentBid = bidAmount
            auction.topBidder = sender
        
            -- Adding a bid increases the duration of the auction by extraTime
            auction.endTime = auction.endTime + AuctionSettings.extraTime

            -- Send the update to all members
            local updateMsg = string.format("AUCTION_UPDATE:%d:%d:%s:%d",
                auctionId,
                auction.currentBid, 
                auction.topBidder,
                auction.endTime
            )
            SafeSendAddonMessage(addonPrefix, updateMsg, "RAID")
            SendChatMessage(string.format("[GDKPT] %s is now the highest bidder on %s with %d gold! ", auction.topBidder, auction.itemLink, auction.currentBid), "RAID")
        end
    end









-------------------------------------------------------------------
-- Function that checks if the person sending an addon message is 
-- part of the raid
-------------------------------------------------------------------


    local function IsSenderInMyRaid(sender)
        if IsInRaid() then
            for i = 1, GetNumRaidMembers() do
                local name = GetRaidRosterInfo(i)
                if name and name == sender then
                    return true
                end
            end
        return false
        end
    end





-------------------------------------------------------------------
-- eventFrame that receives incoming messages from raid member Addon
-- gets called when a player presses the bidButton to bid on an item
-------------------------------------------------------------------


    -- Event handler for addon messages
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("CHAT_MSG_ADDON")

    eventFrame:SetScript("OnEvent", function(self, event, prefix, msg, channel, sender)
        if prefix ~= addonPrefix or not IsSenderInMyRaid(sender) then return end

        local cmd, data = msg:match("([^:]+):(.*)")
        if cmd == "BID" then
            local auctionId, bidAmount = data:match("([^:]+):([^:]+)")
            HandleBid(sender, auctionId, bidAmount)
        end
    end)







-------------------------------------------------------------------
-- Auction End logic
-------------------------------------------------------------------




local timerFrame = CreateFrame("Frame")









-- Timer to process the message queue and check for auction ends
timerFrame:SetScript("OnUpdate", function(self, elapsed)
    
    -- **1. MESSAGE QUEUE LOGIC (Runs every 0.2 seconds)**
    -- Process one message from the queue with a delay to prevent flooding.
    if GetTime() - (self.lastMessageSent or 0) > 0.2 and #MessageQueue > 0 then
        local message = table.remove(MessageQueue, 1)
        SendAddonMessage(message.prefix, message.msg, message.channel)
        self.lastMessageSent = GetTime()
    end
    
    
    -- **2. AUCTION ENDING LOGIC (Throttle to 1 second)**
    self.timeSinceLastCheck = (self.timeSinceLastCheck or 0) + elapsed
    
    if self.timeSinceLastCheck >= 1 then
        self.timeSinceLastCheck = 0

        local now = GetTime()
        local finishedAuctions = {}
        
        for id, auction in pairs(ActiveAuctions) do
            if now >= auction.endTime then
                table.insert(finishedAuctions, id)
            end
        end

        for _, id in ipairs(finishedAuctions) do
            local auction = ActiveAuctions[id]
            
            -- Your Chat Message announcing the winner (uses SendChatMessage, which is fine)
            if auction.topBidder ~= "" then
                SendChatMessage(string.format("[GDKPT] Auction for %s finished! Winner: %s with %d gold!", auction.itemLink, auction.topBidder, auction.currentBid), "RAID")
            else
                auction.topBidder = "Bulk"
                SendChatMessage(string.format("[GDKPT] Auction for %s finished! No bids. Adding this item to the bulk.", auction.itemLink), "RAID")
            end

           
            if auction.topBidder ~= "" and auction.currentBid > 0 then
                GDKP_Pot = GDKP_Pot + auction.currentBid
            end
            
            -- Send message to member addon to remove the row of the finished auction


            local endMsg = string.format("AUCTION_END:%d:%d:%d:%s:%d", id, GDKP_Pot, auction.itemID, auction.topBidder, auction.currentBid )
            
            SafeSendAddonMessage(addonPrefix, endMsg, "RAID") 
            
            -- Remove from active auctions
            ActiveAuctions[id] = nil
        end
    end
end)


-------------------------------------------------------------------
-- If a raid member requests a settings sync, then run 
-- SyncSettings() automatically
-------------------------------------------------------------------


   -- Helper function to trim whitespace from a string
   local function trim(s)
       return s:match("^%s*(.-)%s*$") or s
   end


   GDKPLeaderFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "CHAT_MSG_ADDON" then
            local prefix, message, distribution, sender = ...
            
            if prefix == addonPrefix then
                
                -- Check for requested action
                -- Use strsplit to handle the action and then trim to guard against whitespace issues
                local action = select(1, strsplit(":", message, 2))
                action = trim(action)
                
                if action == "REQUEST_SETTINGS_SYNC" then
                    print("GDKPT Leader: Received setting sync request from " .. sender .. ". Automatically syncing settings.")
                    SyncSettings()
                end
            end
        end
    end)









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
            StartAuction(param)
        elseif cmd == "hide" or cmd == "h" then
         --   GDKPLeaderFrame:Hide()   
        elseif cmd == "reset" or cmd == "r" then
        --    ResetSession()
        elseif cmd == "show" or cmd == "s" then
             GDKPLeaderFrame:Show()
        elseif cmd == "syncdata" or cmd == "sendauctiondata" then
        --    SendAuctionData()
            print("Auction Data is sent to raidmembers.")
        elseif cmd == "syncsettings" or cmd == "sendsettings" then
            print("Sending global GDKP settings to raidmembers.")  --TODO: Create SendSettings function to re-send the global settings to member addon
            SyncSettings()
        elseif cmd == "version" or cmd == "v" or cmd == "vers" then
            print("Current GDKPT Leader Addon Version: " .. version)
        elseif cmd == "versioncheck" then
            VersionCheck()
        end
    end