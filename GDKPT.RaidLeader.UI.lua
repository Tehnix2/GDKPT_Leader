GDKPT.RaidLeader.UI = {}



-------------------------------------------------------------------
-- Leader Frame that holds all adjustable settings
-------------------------------------------------------------------

local GDKPLeaderFrame = CreateFrame("Frame", "GDKPLeaderFrame", UIParent)

GDKPLeaderFrame:SetSize(400, 600)
GDKPLeaderFrame:SetMovable(true)
GDKPLeaderFrame:EnableMouse(true)
GDKPLeaderFrame:RegisterForDrag("LeftButton")
GDKPLeaderFrame:SetPoint("CENTER")
GDKPLeaderFrame:Hide()
GDKPLeaderFrame:SetFrameLevel(10)
GDKPLeaderFrame:SetBackdrop(
    {
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
        edgeSize = 20,
        insets = {left = 5, right = 5, top = 5, bottom = 5}
    }
)

GDKPLeaderFrame:SetScript("OnDragStart", GDKPLeaderFrame.StartMoving)
GDKPLeaderFrame:SetScript("OnDragStop", GDKPLeaderFrame.StopMovingOrSizing)

_G["GDKPLeaderFrame"] = GDKPLeaderFrame
tinsert(UISpecialFrames, "GDKPLeaderFrame")

local CloseGDKPLeaderFrameButton = CreateFrame("Button", "", GDKPLeaderFrame, "UIPanelCloseButton")
CloseGDKPLeaderFrameButton:SetPoint("TOPRIGHT", -5, -5)
CloseGDKPLeaderFrameButton:SetSize(35, 35)

local GDKPLeaderFrameTitleBar = CreateFrame("Frame", "", GDKPLeaderFrame, nil)
GDKPLeaderFrameTitleBar:SetSize(180, 25)
GDKPLeaderFrameTitleBar:SetBackdrop(
    {
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
        tile = true,
        edgeSize = 16,
        tileSize = 16,
        insets = {left = 5, right = 5, top = 5, bottom = 5}
    }
)
GDKPLeaderFrameTitleBar:SetPoint("TOP", 0, 0)

local GDKPLeaderFrameTitleText = GDKPLeaderFrameTitleBar:CreateFontString("")
GDKPLeaderFrameTitleText:SetFont("Fonts\\FRIZQT__.TTF", 14)
GDKPLeaderFrameTitleText:SetText("|cffFFC125GDKPT Leader " .. "- v " .. GDKPT.RaidLeader.Core.version .. "|r")
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

DurationBox:SetBackdrop(
    {
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        edgeSize = 12,
        insets = {left = 3, right = 3, top = 3, bottom = 3}
    }
)

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


SaveDurationButton:SetScript(
    "OnClick",
    function()
        local inputNumber = tonumber(DurationBox:GetText())
        if inputNumber and inputNumber > 0 then
            GDKPT.RaidLeader.Core.AuctionSettings.duration = inputNumber
            print("|cff00ff00[GDKP Leader]|r SAVED: Duration is now: " .. inputNumber .. " seconds.")
        else
            print("|cffff0000[GDKP Leader]|r ERROR: Invalid or zero value entered. Setting restored.")
            DurationBox:SetText(GDKPT.RaidLeader.Core.AuctionSettings.duration)
        end
        
        if IsInRaid() then
            SendChatMessage(
                string.format("[GDKPT] Auction duration has been changed to %d seconds.", GDKPT.RaidLeader.Core.AuctionSettings.duration),
                "RAID"
            )
            GDKPT.RaidLeader.Sync.SyncSettings()
        end
        DurationBox:ClearFocus()
    end
)

DurationBox:SetScript(
    "OnEnterPressed",
    function()
        SaveDurationButton:Click()
    end
)




-- Extra time per bid on an auction
  
local extraTimeLabel = GDKPLeaderFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
extraTimeLabel:SetPoint("TOPLEFT", GDKPLeaderFrame, "TOPLEFT", 30, -100)
extraTimeLabel:SetText("Extra time per bid in seconds:")

local ExtraTimeBox = CreateFrame("EditBox", nil, GDKPLeaderFrame, "BackdropTemplate")
ExtraTimeBox:SetSize(50, 25)
ExtraTimeBox:SetPoint("TOPRIGHT", GDKPLeaderFrame, "TOPRIGHT", -100, -95)
ExtraTimeBox:SetAutoFocus(false)

ExtraTimeBox:SetBackdrop(
    {
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        edgeSize = 12,
        insets = {left = 3, right = 3, top = 3, bottom = 3}
    }
)

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

SaveExtraTimeButton:SetScript(
    "OnClick",
    function()
        GDKPT.RaidLeader.Core.AuctionSettings.extraTime = tonumber(ExtraTimeBox:GetText()) or GDKPT.RaidLeader.Core.AuctionSettings.extraTime
        print("Each bid now increases the auction duration by " .. GDKPT.RaidLeader.Core.AuctionSettings.extraTime .. " seconds.")
        if IsInRaid() then
            SendChatMessage(
                string.format(
                    "[GDKPT] Each bid now increases the auction duration by %d seconds.",
                    GDKPT.RaidLeader.Core.AuctionSettings.extraTime
                ),
                "RAID"
            )
            GDKPT.RaidLeader.Sync.SyncSettings()
        end
        ExtraTimeBox:ClearFocus()
    end
)

ExtraTimeBox:SetScript(
    "OnEnterPressed",
    function()
        SaveExtraTimeButton:Click()
    end
)


-- Starting bid

local StartBidLabel = GDKPLeaderFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
StartBidLabel:SetPoint("TOPLEFT", GDKPLeaderFrame, "TOPLEFT", 30, -150)
StartBidLabel:SetText("Starting Bid for all Items in gold:")

local StartBidBox = CreateFrame("EditBox", nil, GDKPLeaderFrame, "BackdropTemplate")
StartBidBox:SetSize(50, 25)
StartBidBox:SetPoint("TOPRIGHT", GDKPLeaderFrame, "TOPRIGHT", -100, -145)
StartBidBox:SetAutoFocus(false)

StartBidBox:SetBackdrop(
    {
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        edgeSize = 12,
        insets = {left = 3, right = 3, top = 3, bottom = 3}
    }
)

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

SaveStartBidButton:SetScript(
    "OnClick",
    function()
        GDKPT.RaidLeader.Core.AuctionSettings.startBid = tonumber(StartBidBox:GetText()) or GDKPT.RaidLeader.Core.AuctionSettings.startBid
        print("Starting Bid for all auctions is now " .. GDKPT.RaidLeader.Core.AuctionSettings.startBid .. " gold.")
        if IsInRaid() then
            SendChatMessage(string.format("[GDKPT] Starting bid is now %d gold.", GDKPT.RaidLeader.Core.AuctionSettings.startBid), "RAID")
            GDKPT.RaidLeader.Sync.SyncSettings()
        end
        StartBidBox:ClearFocus()
    end
)

StartBidBox:SetScript(
    "OnEnterPressed",
    function()
        SaveStartBidButton:Click()
    end
)



-- Minimum increment

local MinIncLabel = GDKPLeaderFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
MinIncLabel:SetPoint("TOPLEFT", GDKPLeaderFrame, "TOPLEFT", 30, -200)
MinIncLabel:SetText("Minimum increment in gold: ")

local MinIncBox = CreateFrame("EditBox", nil, GDKPLeaderFrame, "BackdropTemplate")
MinIncBox:SetSize(50, 25)
MinIncBox:SetPoint("TOPRIGHT", GDKPLeaderFrame, "TOPRIGHT", -100, -195)
MinIncBox:SetAutoFocus(false)

MinIncBox:SetBackdrop(
    {
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        edgeSize = 12,
        insets = {left = 3, right = 3, top = 3, bottom = 3}
    }
)

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

SaveMinIncButton:SetScript(
    "OnClick",
    function()
        GDKPT.RaidLeader.Core.AuctionSettings.minIncrement = tonumber(MinIncBox:GetText()) or GDKPT.RaidLeader.Core.AuctionSettings.minIncrement
        print("Minimum increment is now " .. GDKPT.RaidLeader.Core.AuctionSettings.minIncrement .. " gold.")
        if IsInRaid() then
            SendChatMessage(
                string.format("[GDKPT] Minimum increments are now %d gold.", GDKPT.RaidLeader.Core.AuctionSettings.minIncrement),
                "RAID"
            )
            GDKPT.RaidLeader.Sync.SyncSettings()
        end
        MinIncBox:ClearFocus()
    end
)

MinIncBox:SetScript(
    "OnEnterPressed",
    function()
        SaveMinIncButton:Click()
    end
)



--[[


-- Amount of players to split the total gold by

local SplitByCountLabel = GDKPLeaderFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
SplitByCountLabel:SetPoint("TOPLEFT", GDKPLeaderFrame, "TOPLEFT", 30, -250)
SplitByCountLabel:SetText("Amount of players to split gold by: ")

local SplitByCountBox = CreateFrame("EditBox", nil, GDKPLeaderFrame, "BackdropTemplate")
SplitByCountBox:SetSize(50, 25)
SplitByCountBox:SetPoint("TOPRIGHT", GDKPLeaderFrame, "TOPRIGHT", -100, -245)
SplitByCountBox:SetAutoFocus(false)

SplitByCountBox:SetBackdrop(
    {
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        edgeSize = 12,
        insets = {left = 3, right = 3, top = 3, bottom = 3}
    }
)

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

SaveSplitByCountButton:SetScript(
    "OnClick",
    function()
        GDKPT.RaidLeader.Core.AuctionSettings.splitCount = tonumber(SplitByCountBox:GetText()) or GDKPT.RaidLeader.Core.AuctionSettings.splitCount
        print("Total pot is now being split by " .. GDKPT.RaidLeader.Core.AuctionSettings.splitCount .. " players.")
        if IsInRaid() then
            SendChatMessage(
                string.format("[GDKPT] The total pot will be split by %d players.", GDKPT.RaidLeader.Core.AuctionSettings.splitCount),
                "RAID"
            )
            GDKPT.RaidLeader.Sync.SyncSettings()
        end
        SplitByCountBox:ClearFocus()
    end
)

SplitByCountBox:SetScript(
    "OnEnterPressed",
    function()
        SaveSplitByCountButton:Click()
    end
)


]]

-------------------------------------------------------------------
-- Function gets called on addon loaded to set auction settings to saved variables
-------------------------------------------------------------------


function GDKPT.RaidLeader.UI.UpdateSettingsUI()
    local settings = GDKPT.RaidLeader.Core.AuctionSettings
   
    -- Set EditBox Text
    DurationBox:SetText(tostring(settings.duration))
    ExtraTimeBox:SetText(tostring(settings.extraTime))
    StartBidBox:SetText(tostring(settings.startBid))
    MinIncBox:SetText(tostring(settings.minIncrement))
   -- SplitByCountBox:SetText(tostring(settings.splitCount))
end



-------------------------------------------------------------------
-- Message Handler UI
-------------------------------------------------------------------

local MessageThrottleLabel = GDKPLeaderFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
MessageThrottleLabel:SetPoint("TOPLEFT", GDKPLeaderFrame, "TOPLEFT", 30, -300)
MessageThrottleLabel:SetText("Message Throttling in seconds: ")

local MessageThrottleBox = CreateFrame("EditBox", nil, GDKPLeaderFrame, "BackdropTemplate")
MessageThrottleBox:SetSize(50, 25)
MessageThrottleBox:SetPoint("TOPRIGHT", GDKPLeaderFrame, "TOPRIGHT", -100, -295)
MessageThrottleBox:SetAutoFocus(false)
MessageThrottleBox:SetText(GDKPT.RaidLeader.MessageHandler.sendThrottle)

MessageThrottleBox:SetBackdrop(
    {
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        edgeSize = 12,
        insets = {left = 3, right = 3, top = 3, bottom = 3}
    }
)

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

SaveMessageThrottleButton:SetScript(
    "OnClick",
    function()
        sendThrottle = tonumber(MessageThrottleBox:GetText()) or GDKPT.RaidLeader.MessageHandler.sendThrottle
        print("Messages can now only sync every " .. GDKPT.RaidLeader.MessageHandler.sendThrottle .. " seconds.")
        if IsInRaid() then
            SendChatMessage(string.format("[GDKPT] Messages can now only sync every %d seconds.", GDKPT.RaidLeader.MessageHandler.sendThrottle), "RAID")
        end
        MessageThrottleBox:ClearFocus()
    end
)

MessageThrottleBox:SetScript(
    "OnEnterPressed",
    function()
        SaveMessageThrottleButton:Click()
    end
)







-------------------------------------------------------------------
-- LeaderFrame holds all the leader tools in a small frame
-------------------------------------------------------------------

LeaderFrame = CreateFrame("Frame", "LeaderFrame", UIParent)

LeaderFrame:SetSize(200, 200)
LeaderFrame:SetMovable(true)
LeaderFrame:EnableMouse(true)
LeaderFrame:RegisterForDrag("LeftButton")
LeaderFrame:SetPoint("CENTER")
LeaderFrame:Hide()
LeaderFrame:SetFrameLevel(10)
LeaderFrame:SetBackdrop(
    {
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
        edgeSize = 20,
        insets = {left = 5, right = 5, top = 5, bottom = 5}
    }
)

LeaderFrame:SetScript("OnDragStart", LeaderFrame.StartMoving)
LeaderFrame:SetScript("OnDragStop", LeaderFrame.StopMovingOrSizing)


local CloseLeaderFrameButton = CreateFrame("Button", "", LeaderFrame, "UIPanelCloseButton")
CloseLeaderFrameButton:SetPoint("TOPRIGHT", LeaderFrame, "TOPRIGHT", 5, 5)
CloseLeaderFrameButton:SetSize(35, 35)

local LeaderFrameTitleBar = CreateFrame("Frame", "", LeaderFrame, nil)
LeaderFrameTitleBar:SetSize(150, 25)
LeaderFrameTitleBar:SetBackdrop(
    {
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
        tile = true,
        edgeSize = 16,
        tileSize = 16,
        insets = {left = 5, right = 5, top = 5, bottom = 5}
    }
)
LeaderFrameTitleBar:SetPoint("TOP", LeaderFrame, "TOP", 0, 18)

local LeaderFrameTitleText = LeaderFrameTitleBar:CreateFontString("")
LeaderFrameTitleText:SetFont("Fonts\\FRIZQT__.TTF", 14)
LeaderFrameTitleText:SetText("|cffFFC125GDKPT Leader|r")
LeaderFrameTitleText:SetPoint("CENTER", 0, 0)




-- Scroll Frame and Content

local LeaderScrollFrame = CreateFrame("ScrollFrame", "GDKP_LeaderScrollFrame", LeaderFrame, "UIPanelScrollFrameTemplate")
LeaderScrollFrame:SetSize(190, 150)
LeaderScrollFrame:SetPoint("TOPLEFT", LeaderFrame, 10, -32)
LeaderScrollFrame:SetPoint("BOTTOMRIGHT", LeaderFrame, -10, 30)


local LeaderContentFrame = CreateFrame("Frame", nil, LeaderScrollFrame)
LeaderContentFrame:SetWidth(LeaderScrollFrame:GetWidth() -20)
LeaderContentFrame:SetHeight(1) -- will be adjusted dynamically
LeaderScrollFrame:SetScrollChild(LeaderContentFrame)
LeaderContentFrame:EnableMouse(true)






-----------------------------------------------------------------------------------
-- Manual Gold Balance Adjustments
-----------------------------------------------------------------------------------




function GDKPT.RaidLeader.UI.HandleAdjustmentConfirm(playerName, adjustmentText, auctionId)
    local adjustmentAmount = tonumber(adjustmentText)
    local finalAuctionId = tonumber(auctionId) or -1 

    if not adjustmentAmount or adjustmentAmount == 0 then
        print("|cffff8800[GDKPT Leader]|r Invalid or zero adjustment amount.")
        return
    end

    GDKPT.RaidLeader.AuctionEnd.UpdateDataAfterManualAdjustment(playerName, adjustmentAmount, finalAuctionId)
    
    print(string.format("|cff00ff00[GDKPT Leader]|r Adjustment of %d G applied to %s. (Auction ID: %s)", 
        adjustmentAmount, playerName, finalAuctionId == -1 and "General" or finalAuctionId))

end


StaticPopupDialogs["GDKPT_ADJUST_PLAYER_AMOUNT"] = {
    text = "Adjust Gold Balance for %s\n\n|cff888888Current Balance:|r %s\n\nEnter the adjustment amount (e.g., -100 or 400):", 
    button1 = "Next (Enter Auction ID)",
    button2 = CANCEL,
    hasEditBox = true,
    enterClicksFirstButton = true,
    editBoxHidden = false,
    maxLetters = 10,


    OnAccept = function(self, playerName, ...) 
        local adjustmentText = self.editBox:GetText()
        
        local adjustmentAmount = tonumber(adjustmentText)
        if not adjustmentAmount or adjustmentAmount == 0 then
            print("|cffff8800[GDKPT Leader]|r Invalid or zero adjustment amount. Please enter a non-zero number (e.g., -100).")
            
            local dialog = StaticPopup_Show("GDKPT_ADJUST_PLAYER_AMOUNT", playerName, select(2, ...)) 
            if dialog then
                dialog.data = playerName
            end
            return
        end

        if playerName then 
            local dialog = StaticPopup_Show("GDKPT_ADJUST_SELECT_ID", playerName, adjustmentText) 
            
            if dialog then
                dialog.data = playerName       
                dialog.data2 = adjustmentText  
            end
        else
            print("|cffff0000[GDKPT Leader]|r ERROR: Missing player name in Adjustment Amount confirmation.")
        end
    end,
    OnShow = function(self)
        self.editBox:SetText("")
        self.editBox:SetFocus()
        self.editBox:HighlightText()
    end,
    OnCancel = function()
    end,
    timeout = 0,
    hideOnEscape = true,
}


StaticPopupDialogs["GDKPT_ADJUST_SELECT_ID"] = {
    text = "Enter Auction ID (Number) for %s. Use -1 for a General Adjustment. (Amount: %s)", 
    button1 = "Confirm Adjustment",
    button2 = CANCEL,
    hasEditBox = true,
    enterClicksFirstButton = true,
    editBoxHidden = false,
    maxLetters = 10,

    OnAccept = function(self, playerName, adjustmentText, ...)

   
        local auctionIdText = self.editBox:GetText()
        local auctionId = tonumber(auctionIdText)

        if auctionIdText == "-1" then
            auctionId = -1
        elseif not auctionId or auctionId < 1 then
            print("|cffff8800[GDKPT Leader]|r Invalid Auction ID. Please enter a positive number or -1 for General.")
            
            local dialog = StaticPopup_Show("GDKPT_ADJUST_SELECT_ID", playerName, adjustmentText) 
            if dialog then
                dialog.data = playerName
                dialog.data2 = adjustmentText
            end
            return
        end

        if playerName and adjustmentText then
            GDKPT.RaidLeader.UI.HandleAdjustmentConfirm(playerName, adjustmentText, auctionId)
        else
            print("|cffff0000[GDKPT Leader]|r ERROR: Missing required data in Auction ID confirmation.")
        end
    end,
    OnShow = function(self)
        self.editBox:SetText("")
        self.editBox:SetFocus()
        self.editBox:HighlightText()
    end,
    OnCancel = function()
    end,
    timeout = 0,
    hideOnEscape = true,
}








-----------------------------------------------------------------------------------
-- Player Balances within the LeaderFrame
-----------------------------------------------------------------------------------



local PLAYER_ROW_HEIGHT = 24
local PLAYER_FRAME_POOL = {} 
local GDKPT_PLAYER_ROWS = {} 



local function CreatePlayerRow(parent, index)

    local frame = CreateFrame("Frame", nil, parent)
    frame:SetHeight(PLAYER_ROW_HEIGHT)
    frame:SetWidth(parent:GetWidth())
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -(index - 1) * PLAYER_ROW_HEIGHT)
    frame:EnableMouse(true) 

    frame.bg = frame:CreateTexture(nil, "BACKGROUND")
    frame.bg:SetAllPoints(frame)

    -- Player Name
    frame.NameText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.NameText:SetJustifyH("LEFT")
    frame.NameText:SetPoint("LEFT", 5, 0)
    frame.NameText:SetPoint("RIGHT", -50, 0) 
    frame.NameText:SetText("")
    
    -- Gold Amount/Owed
    frame.GoldText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.GoldText:SetJustifyH("RIGHT")
    frame.GoldText:SetPoint("RIGHT", -5, 0)
    frame.GoldText:SetText("")

    local clickButton = CreateFrame("Button", nil, parent) 
    clickButton:SetAllPoints(frame) 

    local buttonTexture = clickButton:CreateTexture(nil, "OVERLAY")
    buttonTexture:SetAllPoints(true)
    buttonTexture:SetTexture("Interface/ChatFrame/ChatFrameBackground")
    buttonTexture:SetVertexColor(1, 1, 1, 0.001)
    
    clickButton:SetFrameLevel(20)
    clickButton:SetFrameStrata("HIGH")


    clickButton.visualFrame = frame 
    clickButton.texture = buttonTexture
    frame.clickButton = clickButton 


    clickButton:SetScript("OnClick", function(self, buttonClicked)
        local visualFrame = self.visualFrame 
        
        if visualFrame and visualFrame.playerName then
            local playerName = visualFrame.playerName
            local currentGold = visualFrame.gold
            
            GDKPT_TEMP_ADJUST_PLAYER = playerName
            
            local goldDisplay = string.format("|c%s%d|r", 
                (currentGold >= 0 and "ff00ff00" or "ffff0000"), currentGold)
            
            local dialog = StaticPopup_Show("GDKPT_ADJUST_PLAYER_AMOUNT", playerName, goldDisplay)

            if dialog then
                dialog.data = playerName
            end
        end
    end)

    clickButton:SetScript("OnEnter", function(self)
        self.texture:SetVertexColor(1, 1, 1, 0.2) 
    end)

    clickButton:SetScript("OnLeave", function(self)
        self.texture:SetVertexColor(1, 1, 1, 0.001) 
    end)
    
    return frame
end



-------------------------------------------------------------------
-- Function that updates the players balances within the leaderframe
-------------------------------------------------------------------



-- Function to update the player list display
function GDKPT.RaidLeader.UI.UpdateRosterDisplay()
    local contentFrame = LeaderContentFrame
    
    local uniquePlayers = {}
    local data = {}
    
    local numGroupMembers = GetNumGroupMembers()
    for i = 1, numGroupMembers do
        local name, _, _, _, _, _, _, online = GetRaidRosterInfo(i)
        
        if name and online then
            uniquePlayers[name] = true
        end
    end
    
    if numGroupMembers == 0 then
        local selfName = UnitName("player")
        if selfName then
             uniquePlayers[selfName] = true
        end
    end


    for name in pairs(GDKPT.RaidLeader.Core.PlayerBalances) do
        uniquePlayers[name] = true 
    end
    
    for name in pairs(uniquePlayers) do
        local gold = GDKPT.RaidLeader.Core.PlayerBalances[name] or 0
        if gold ~= 0 then   -- only add players if they have a non-zero gold amount
            table.insert(data, { name = name, gold = gold })
        end
    end

    for i = 1, #PLAYER_FRAME_POOL do
        PLAYER_FRAME_POOL[i]:Hide()
    end
    wipe(GDKPT_PLAYER_ROWS) 

    local totalHeight = 0
    
    table.sort(data, function(a, b) return a.name < b.name end)

    for i, player in ipairs(data) do
        local frame = PLAYER_FRAME_POOL[i]
        
        if not frame then
            frame = CreatePlayerRow(contentFrame, i)
            table.insert(PLAYER_FRAME_POOL, frame)
        else
            frame:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, -(i - 1) * PLAYER_ROW_HEIGHT)
            frame:Show()
        end

        GDKPT_PLAYER_ROWS[player.name] = frame 
        
        frame.playerName = player.name
        
        frame.NameText:SetText(player.name)
        
        local goldAmount = player.gold
        
        local color
        local prefix = "" 
        
        if goldAmount < 0 then
            color = "|cffff0000" 
            prefix = "-" 
            formattedGold = string.format("%d g", math.abs(goldAmount))
        elseif goldAmount > 0 then
            color = "|cff00ff00"
            formattedGold = string.format("%d g", goldAmount)
        else
            formattedGold = "0"
            color = "|cff888888"  
        end
        
        frame.GoldText:SetText(color .. prefix .. formattedGold .. "|r")

        if i % 2 == 0 then
            frame.bg:SetVertexColor(0.15, 0.15, 0.15, 0.5)
        else
            frame.bg:SetVertexColor(0.1, 0.1, 0.1, 0.5)
        end
        
        totalHeight = totalHeight + PLAYER_ROW_HEIGHT

        frame.gold = goldAmount

    end

    contentFrame:SetHeight(math.max(LeaderScrollFrame:GetHeight(), totalHeight))
end



GDKPT.RaidLeader.UI.UpdateRosterDisplay()








-------------------------------------------------------------------
-- Toggle button for leader frame
-------------------------------------------------------------------



local function ToggleLeaderFrame()
    if LeaderFrame:IsVisible() then
        LeaderFrame:Hide()
        LeaderToggleButton:Show() 
    else
        LeaderFrame:Show()
        --LeaderToggleButton:Hide() 
    end
end


local function ShowGDKPLeaderFrame()
    if GDKPLeaderFrame and not GDKPLeaderFrame:IsVisible() then
        GDKPLeaderFrame:Show()
       -- LeaderToggleButton:Hide()
    end
end




local LeaderToggleButton = CreateFrame("Button", "LeaderToggleButton", UIParent)
LeaderToggleButton:SetSize(40, 40)
LeaderToggleButton:SetPoint("CENTER", UIParent, "CENTER", 0, 0) 
LeaderToggleButton:SetMovable(true)
LeaderToggleButton:EnableMouse(true)
LeaderToggleButton:RegisterForClicks("LeftButtonUp", "RightButtonDown")
LeaderToggleButton:RegisterForDrag("LeftButton","RightButton")
LeaderToggleButton:SetFrameStrata("MEDIUM")
LeaderToggleButton:Hide() 


local toggleIcon = LeaderToggleButton:CreateTexture(nil, "ARTWORK")
toggleIcon:SetTexture("Interface\\Icons\\INV_Misc_Coin_03") 
toggleIcon:SetAllPoints()

local toggleHighlight = LeaderToggleButton:CreateTexture(nil, "HIGHLIGHT")
toggleHighlight:SetAllPoints()
toggleHighlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
toggleHighlight:SetBlendMode("ADD")

local buttonText = LeaderToggleButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
buttonText:SetPoint("CENTER", 0, 30)
buttonText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
buttonText:SetText("GDKPT Leader") 




local function UpdateToggleButtonVisibility()
    if IsInRaid() then
        if not LeaderFrame:IsVisible() then
            LeaderToggleButton:Show()
        end
    else
        LeaderToggleButton:Hide()
        LeaderFrame:Hide()
    end
end


local EventFrame = CreateFrame("Frame")
EventFrame:RegisterEvent("RAID_ROSTER_UPDATE")    
EventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")   
EventFrame:RegisterEvent("PLAYER_LOGIN")           
EventFrame:RegisterEvent("ADDON_LOADED")           

EventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == "GDKPT_RaidLeader" then
            UpdateToggleButtonVisibility()
        end
    end

    if event ~= "ADDON_LOADED" then
        UpdateToggleButtonVisibility()
    end
end)


GDKPLeaderFrame:SetScript(
    "OnHide",
    function()
        if IsInRaid() then 
            LeaderToggleButton:Show()
        end
    end
)



LeaderToggleButton:SetScript("OnClick", function(self, button)
    if button == "LeftButton" then
        ToggleLeaderFrame()
    elseif button == "RightButton" then
        ShowGDKPLeaderFrame()
    end
end)

LeaderToggleButton:SetScript("OnDragStart", LeaderToggleButton.StartMoving)
LeaderToggleButton:SetScript("OnDragStop", LeaderToggleButton.StopMovingOrSizing)


LeaderFrame:SetScript(
    "OnHide",
    function()
        if IsInRaid() then
            LeaderToggleButton:Show()
        end
    end
)





-------------------------------------------------------------------
-- Export Data Button
-------------------------------------------------------------------

local ExportDataButton = CreateFrame("Button", nil, GDKPLeaderFrame, "GameMenuButtonTemplate")
ExportDataButton:SetPoint("CENTER", GDKPLeaderFrame, "CENTER", -100, -80)
ExportDataButton:SetSize(150, 30)
ExportDataButton:SetText("Export Raid Data")
ExportDataButton:SetNormalFontObject("GameFontNormalLarge")
ExportDataButton:SetHighlightFontObject("GameFontHighlightLarge")

ExportDataButton:SetScript("OnClick", function()
    if GDKPT.RaidLeader.Export and GDKPT.RaidLeader.Export.Show then
        GDKPT.RaidLeader.Export.Show()
    end
end)


-------------------------------------------------------------------
-- Frame exposing for other files
-------------------------------------------------------------------

GDKPT.RaidLeader.UI.GDKPLeaderFrame = GDKPLeaderFrame

