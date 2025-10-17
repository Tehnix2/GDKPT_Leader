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
DurationBox:SetText(GDKPT.RaidLeader.Core.AuctionSettings.duration)

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
        GDKPT.RaidLeader.Core.AuctionSettings.duration = tonumber(DurationBox:GetText()) or GDKPT.RaidLeader.Core.AuctionSettings.duration
        print("Auctions now last for " .. GDKPT.RaidLeader.AuctionSettings.Core.duration .. " seconds.")
        if IsInRaid() then
            SendChatMessage(
                string.format("[GDKPT] Auction duration has been changed to %d seconds.", GDKPT.RaidLeader.AuctionSettings.Core.duration),
                "RAID"
            )
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
ExtraTimeBox:SetText(GDKPT.RaidLeader.Core.AuctionSettings.extraTime)

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
StartBidBox:SetText(GDKPT.RaidLeader.Core.AuctionSettings.startBid)

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
MinIncBox:SetText(GDKPT.RaidLeader.Core.AuctionSettings.minIncrement)

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




-- Amount of players to split the total gold by

local SplitByCountLabel = GDKPLeaderFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
SplitByCountLabel:SetPoint("TOPLEFT", GDKPLeaderFrame, "TOPLEFT", 30, -250)
SplitByCountLabel:SetText("Amount of players to split gold by: ")

local SplitByCountBox = CreateFrame("EditBox", nil, GDKPLeaderFrame, "BackdropTemplate")
SplitByCountBox:SetSize(50, 25)
SplitByCountBox:SetPoint("TOPRIGHT", GDKPLeaderFrame, "TOPRIGHT", -100, -245)
SplitByCountBox:SetAutoFocus(false)
SplitByCountBox:SetText(GDKPT.RaidLeader.Core.AuctionSettings.splitCount)

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







-------------------------------------------------------------------
-- 
-------------------------------------------------------------------




-------------------------------------------------------------------
-- 
-------------------------------------------------------------------


-------------------------------------------------------------------
-- 
-------------------------------------------------------------------


-------------------------------------------------------------------
-- 
-------------------------------------------------------------------


-------------------------------------------------------------------
-- 
-------------------------------------------------------------------

GDKPT.RaidLeader.UI.GDKPLeaderFrame = GDKPLeaderFrame