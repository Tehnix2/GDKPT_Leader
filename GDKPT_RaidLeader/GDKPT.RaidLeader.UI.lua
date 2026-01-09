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
            print(GDKPT.RaidLeader.Core.addonPrintString .. "Duration is now: " .. inputNumber .. " seconds.")
        else
            print(GDKPT.RaidLeader.Core.errorPrintString.. "Invalid or zero value entered. Setting restored.")
            DurationBox:SetText(GDKPT.RaidLeader.Core.AuctionSettings.duration)
            return
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
        local inputNumber = tonumber(ExtraTimeBox:GetText())
        if inputNumber and inputNumber >= 0 then
            GDKPT.RaidLeader.Core.AuctionSettings.extraTime = inputNumber
            print(GDKPT.RaidLeader.Core.addonPrintString .. "Extra time per bid is now: " .. inputNumber .. " seconds.")
        else
            print(GDKPT.RaidLeader.Core.errorPrintString.. "Invalid or negative value entered. Setting restored.")
            ExtraTimeBox:SetText(GDKPT.RaidLeader.Core.AuctionSettings.extraTime)
            return
        end

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
        local inputNumber = tonumber(StartBidBox:GetText())
        if inputNumber and inputNumber >= 0 then
            GDKPT.RaidLeader.Core.AuctionSettings.startBid = inputNumber
            print(GDKPT.RaidLeader.Core.addonPrintString .. "Starting bid for all auctions is now: " .. inputNumber .. " gold.")
        else
            print(GDKPT.RaidLeader.Core.errorPrintString.. "Invalid or negative value entered. Setting restored.")
            StartBidBox:SetText(GDKPT.RaidLeader.Core.AuctionSettings.startBid)
            return
        end

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
        local inputNumber = tonumber(MinIncBox:GetText())
        if inputNumber and inputNumber >= 0 then
            GDKPT.RaidLeader.Core.AuctionSettings.minIncrement = inputNumber
            print(GDKPT.RaidLeader.Core.addonPrintString .. "Minimum increment is now: " .. inputNumber .. " gold.")
        else
            print(GDKPT.RaidLeader.Core.errorPrintString.. "Invalid or negative value entered. Setting restored.")
            MinIncBox:SetText(GDKPT.RaidLeader.Core.AuctionSettings.minIncrement)
            return
        end

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
end



-------------------------------------------------------------------
-- LeaderFrame that shows the player balances
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



-------------------------------------------------------------------
-- Toggle button for leader frame
-------------------------------------------------------------------



local function ToggleLeaderFrame()
    if LeaderFrame:IsVisible() then
        LeaderFrame:Hide()
        LeaderToggleButton:Show() 
    else
        LeaderFrame:Show()
    end
end


local function ShowGDKPLeaderFrame()
    if GDKPLeaderFrame and not GDKPLeaderFrame:IsVisible() then
        GDKPLeaderFrame:Show()
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
    if IsInRaid() and (IsRaidLeader() or IsRaidOfficer()) then
        if not LeaderFrame:IsVisible() then
            LeaderToggleButton:Show()
        end
    else
        LeaderToggleButton:Hide()
        LeaderFrame:Hide()
        GDKPLeaderFrame:Hide()
    end
end


local EventFrame = CreateFrame("Frame")
EventFrame:RegisterEvent("RAID_ROSTER_UPDATE")    
EventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")   
EventFrame:RegisterEvent("PLAYER_LOGIN")           
EventFrame:RegisterEvent("ADDON_LOADED")   
EventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

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
-- Frame exposing for other files
-------------------------------------------------------------------

GDKPT.RaidLeader.UI.GDKPLeaderFrame = GDKPLeaderFrame
GDKPT.RaidLeader.UI.LeaderFrame = LeaderFrame
GDKPT.RaidLeader.UI.LeaderContentFrame = LeaderContentFrame
GDKPT.RaidLeader.UI.LeaderScrollFrame = LeaderScrollFrame   