GDKPT.RaidLeader.Export = {}

-------------------------------------------------------------------
-- Main Export Frame
-------------------------------------------------------------------

local ExportFrame = CreateFrame("Frame", "GDKPT_ExportFrame", UIParent, "BackdropTemplate")
ExportFrame:SetSize(600, 500)
ExportFrame:SetPoint("CENTER")
ExportFrame:SetMovable(true)
ExportFrame:EnableMouse(true)
ExportFrame:RegisterForDrag("LeftButton")
ExportFrame:SetScript("OnDragStart", ExportFrame.StartMoving)
ExportFrame:SetScript("OnDragStop", ExportFrame.StopMovingOrSizing)
ExportFrame:SetFrameStrata("DIALOG")
ExportFrame:SetFrameLevel(100)
ExportFrame:Hide()

ExportFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    edgeSize = 32,
    insets = {left = 8, right = 8, top = 8, bottom = 8}
})
ExportFrame:SetBackdropColor(0, 0, 0, 0.95)

GDKPT.RaidLeader.Export.ExportFrame = ExportFrame

local TitleBar = CreateFrame("Frame", nil, ExportFrame)
TitleBar:SetSize(400, 30)
TitleBar:SetPoint("TOP", 0, 12)
TitleBar:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
    tile = true,
    edgeSize = 16,
    tileSize = 16,
    insets = {left = 5, right = 5, top = 5, bottom = 5}
})
TitleBar:SetBackdropColor(0.1, 0.1, 0.1, 1)

local TitleText = TitleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
TitleText:SetPoint("CENTER")
TitleText:SetText("|cffFFC125GDKPT Data Export|r")


local CloseButton = CreateFrame("Button", nil, ExportFrame, "UIPanelCloseButton")
CloseButton:SetPoint("TOPRIGHT", -5, -5)
CloseButton:SetSize(32, 32)
CloseButton:SetScript("OnClick", function() ExportFrame:Hide() end)

local RaidNameLabel = ExportFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
RaidNameLabel:SetPoint("TOPLEFT", 20, -50)
RaidNameLabel:SetText("Raid Name:")

local RaidNameBox = CreateFrame("EditBox", "GDKPT_RaidNameBox", ExportFrame, "InputBoxTemplate")
RaidNameBox:SetSize(200, 25)
RaidNameBox:SetPoint("LEFT", RaidNameLabel, "RIGHT", 10, 0)
RaidNameBox:SetAutoFocus(false)
RaidNameBox:SetMaxLetters(50)
RaidNameBox:SetText("Unnamed Raid")

ExportFrame.RaidNameBox = RaidNameBox

local FormatLabel = ExportFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
FormatLabel:SetPoint("TOPLEFT", 20, -85)
FormatLabel:SetText("Export Format:")

local FormatDropdown = CreateFrame("Frame", "GDKPT_FormatDropdown", ExportFrame, "UIDropDownMenuTemplate")
FormatDropdown:SetPoint("LEFT", FormatLabel, "RIGHT", -15, -2)

local selectedFormat = "CSV" 


local function FormatDropdown_Initialize(self, level)
    local info = UIDropDownMenu_CreateInfo()
    
    -- CSV Option
    info.text = "CSV (Spreadsheet)"
    info.value = "CSV"
    info.func = function()
        selectedFormat = "CSV"
        UIDropDownMenu_SetSelectedValue(FormatDropdown, "CSV")
    end
    info.checked = (selectedFormat == "CSV")
    UIDropDownMenu_AddButton(info, level)
    
    -- Plain Text Option
    info.text = "Plain Text"
    info.value = "TEXT"
    info.func = function()
        selectedFormat = "TEXT"
        UIDropDownMenu_SetSelectedValue(FormatDropdown, "TEXT")
    end
    info.checked = (selectedFormat == "TEXT")
    UIDropDownMenu_AddButton(info, level)
    
    -- Screenshot Option
    info.text = "Screenshot (Item Links)"
    info.value = "SCREENSHOT"
    info.func = function()
        selectedFormat = "SCREENSHOT"
        UIDropDownMenu_SetSelectedValue(FormatDropdown, "SCREENSHOT")
    end
    info.checked = (selectedFormat == "SCREENSHOT")
    UIDropDownMenu_AddButton(info, level)
    
    -- JSON Option
    info.text = "JSON"
    info.value = "JSON"
    info.func = function()
        selectedFormat = "JSON"
        UIDropDownMenu_SetSelectedValue(FormatDropdown, "JSON")
    end
    info.checked = (selectedFormat == "JSON")
    UIDropDownMenu_AddButton(info, level)
end

UIDropDownMenu_Initialize(FormatDropdown, FormatDropdown_Initialize)
UIDropDownMenu_SetSelectedValue(FormatDropdown, "CSV")
UIDropDownMenu_SetWidth(FormatDropdown, 140)

-- Generate Button
local GenerateButton = CreateFrame("Button", nil, ExportFrame, "GameMenuButtonTemplate")
GenerateButton:SetSize(150, 30)
GenerateButton:SetPoint("TOP", ExportFrame, "TOP", 0, -115)
GenerateButton:SetText("Generate Export")
GenerateButton:SetNormalFontObject("GameFontNormalLarge")
GenerateButton:SetHighlightFontObject("GameFontHighlightLarge")

-- Scroll Frame for Export Data
local ScrollFrame = CreateFrame("ScrollFrame", nil, ExportFrame, "UIPanelScrollFrameTemplate")
ScrollFrame:SetPoint("TOPLEFT", 20, -155)
ScrollFrame:SetPoint("BOTTOMRIGHT", -40, 50)

local ExportTextBox = CreateFrame("EditBox", nil, ScrollFrame)
ExportTextBox:SetMultiLine(true)
ExportTextBox:SetAutoFocus(false)
ExportTextBox:SetFontObject(ChatFontNormal)
ExportTextBox:SetWidth(ScrollFrame:GetWidth() - 20)
ExportTextBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
ExportTextBox:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)

ScrollFrame:SetScrollChild(ExportTextBox)
ExportFrame.ExportTextBox = ExportTextBox

-- Instructions
local Instructions = ExportFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
Instructions:SetPoint("BOTTOM", 0, 15)
Instructions:SetText("|cffffaa00Click inside the box and press Ctrl+A then Ctrl+C to copy all data|r")

-- Copy All Button
local CopyAllButton = CreateFrame("Button", nil, ExportFrame, "GameMenuButtonTemplate")
CopyAllButton:SetSize(100, 25)
CopyAllButton:SetPoint("BOTTOMLEFT", 20, 10)
CopyAllButton:SetText("Select All")
CopyAllButton:SetScript("OnClick", function()
    ExportTextBox:SetFocus()
    ExportTextBox:HighlightText()
end)

-------------------------------------------------------------------
-- Export Generation Functions
-------------------------------------------------------------------

local function GenerateCSVExport(raidName)
    local output = {}
    local totalPot = GDKPT.RaidLeader.Core.GDKP_Pot
    local splitCount = GDKPT.RaidLeader.Core.AuctionSettings.splitCount
    local totalCut = math.floor(totalPot / splitCount)
    local currentDate = date("%Y-%m-%d %H:%M:%S")
    
    table.insert(output, "GDKPT Raid Export")
    table.insert(output, "")
    table.insert(output, "Raid Name," .. raidName)
    table.insert(output, "Date," .. currentDate)
    table.insert(output, "Total Pot," .. totalPot)
    table.insert(output, "Split Count," .. splitCount)
    table.insert(output, "Cut Per Player," .. totalCut)
    table.insert(output, "")
    table.insert(output, "")
    
    table.insert(output, "Auction ID,Item Name,Winner,Final Bid,Status")
    
    local auctions = {}
    for id, auction in pairs(GDKPT.RaidLeader.Core.ActiveAuctions) do
        table.insert(auctions, {id = id, auction = auction})
    end
    
    table.sort(auctions, function(a, b) return a.id < b.id end)
    
    for _, data in ipairs(auctions) do
        local id = data.id
        local auction = data.auction
        
        if auction.topBidder and auction.topBidder ~= "" and auction.topBidder ~= "Bulk" then
            local itemName = GetItemInfo(auction.itemLink) or "Unknown Item"
            itemName = itemName:gsub(",", ";")
            
            local status = auction.hasEnded and "Completed" or "Active"
            local bid = auction.currentBid or 0
            
            table.insert(output, string.format("%d,%s,%s,%d,%s",
                id, itemName, auction.topBidder, bid, status))
        end
    end
    
    table.insert(output, "")
    table.insert(output, "")
    
    table.insert(output, "Player Balances")
    table.insert(output, "Player Name,Balance,Status")
    
    local balances = {}
    for name, balance in pairs(GDKPT.RaidLeader.Core.PlayerBalances) do
        table.insert(balances, {name = name, balance = balance})
    end
    
    table.sort(balances, function(a, b) return a.balance < b.balance end)
    
    for _, data in ipairs(balances) do
        local status = data.balance < 0 and "Owes" or (data.balance > 0 and "Owed" or "Settled")
        table.insert(output, string.format("%s,%d,%s", data.name, data.balance, status))
    end
    
    return table.concat(output, "\n")
end

local function GeneratePlainTextExport(raidName)
    local output = {}
    local totalPot = GDKPT.RaidLeader.Core.GDKP_Pot
    local splitCount = GDKPT.RaidLeader.Core.AuctionSettings.splitCount
    local totalCut = math.floor(totalPot / splitCount)
    local currentDate = date("%Y-%m-%d %H:%M:%S")
    
    table.insert(output, "=====================================")
    table.insert(output, "       GDKPT RAID EXPORT DATA       ")
    table.insert(output, "=====================================")
    table.insert(output, "")
    table.insert(output, "Raid Name: " .. raidName)
    table.insert(output, "Export Date: " .. currentDate)
    table.insert(output, "")
    table.insert(output, "--- POT SUMMARY ---")
    table.insert(output, string.format("Total Gold Pot: %s", GDKPT.Utils.FormatMoney(totalPot * 10000)))
    table.insert(output, string.format("Split %d ways", splitCount))
    table.insert(output, string.format("Cut Per Player: %s", GDKPT.Utils.FormatMoney(totalCut * 10000)))
    table.insert(output, "")
    table.insert(output, "=====================================")
    table.insert(output, "            AUCTION RESULTS            ")
    table.insert(output, "=====================================")
    table.insert(output, "")
    
    local auctions = {}
    for id, auction in pairs(GDKPT.RaidLeader.Core.ActiveAuctions) do
        if auction.topBidder and auction.topBidder ~= "" and auction.topBidder ~= "Bulk" then
            table.insert(auctions, {id = id, auction = auction})
        end
    end
    
    table.sort(auctions, function(a, b) return a.id < b.id end)
    
    for _, data in ipairs(auctions) do
        local id = data.id
        local auction = data.auction
        local itemName = GetItemInfo(auction.itemLink) or "Unknown Item"
        local bid = auction.currentBid or 0
        
        table.insert(output, string.format("[%d] %s", id, itemName))
        table.insert(output, string.format("    Winner: %s", auction.topBidder))
        table.insert(output, string.format("    Bid: %s", GDKPT.Utils.FormatMoney(bid * 10000)))
        table.insert(output, string.format("    Status: %s", auction.hasEnded and "Completed" or "Active"))
        table.insert(output, "")
    end
    
    table.insert(output, "=====================================")
    table.insert(output, "           PLAYER BALANCES           ")
    table.insert(output, "=====================================")
    table.insert(output, "")
    
    local balances = {}
    for name, balance in pairs(GDKPT.RaidLeader.Core.PlayerBalances) do
        table.insert(balances, {name = name, balance = balance})
    end
    
    table.sort(balances, function(a, b) return a.balance < b.balance end)
    
    for _, data in ipairs(balances) do
        local status = data.balance < 0 and "OWES" or (data.balance > 0 and "OWED" or "SETTLED")
        local formatted = GDKPT.Utils.FormatMoney(math.abs(data.balance) * 10000)
        
        table.insert(output, string.format("%-20s %10s (%s)", data.name, formatted, status))
    end
    
    table.insert(output, "")
    table.insert(output, "=====================================")
    table.insert(output, "       Export generated by GDKPT       ")
    table.insert(output, "=====================================")
    
    return table.concat(output, "\n")
end

local function GenerateJSONExport(raidName)
    local totalPot = GDKPT.RaidLeader.Core.GDKP_Pot
    local splitCount = GDKPT.RaidLeader.Core.AuctionSettings.splitCount
    local totalCut = math.floor(totalPot / splitCount)
    
    local function escapeJSON(str)
        if not str then return '""' end
        str = tostring(str)
        str = str:gsub('\\', '\\\\')
        str = str:gsub('"', '\\"')
        str = str:gsub('\n', '\\n')
        str = str:gsub('\r', '\\r')
        str = str:gsub('\t', '\\t')
        return '"' .. str .. '"'
    end
    
    local output = {}
    table.insert(output, "{")
    table.insert(output, '  "raidName": ' .. escapeJSON(raidName) .. ',')
    table.insert(output, '  "exportDate": ' .. escapeJSON(date("%Y-%m-%d %H:%M:%S")) .. ',')
    table.insert(output, '  "potSummary": {')
    table.insert(output, '    "totalPot": ' .. totalPot .. ',')
    table.insert(output, '    "splitCount": ' .. splitCount .. ',')
    table.insert(output, '    "cutPerPlayer": ' .. totalCut)
    table.insert(output, '  },')
    table.insert(output, '  "auctions": [')
    
    local auctions = {}
    for id, auction in pairs(GDKPT.RaidLeader.Core.ActiveAuctions) do
        if auction.topBidder and auction.topBidder ~= "" and auction.topBidder ~= "Bulk" then
            table.insert(auctions, {id = id, auction = auction})
        end
    end
    
    table.sort(auctions, function(a, b) return a.id < b.id end)
    
    for i, data in ipairs(auctions) do
        local id = data.id
        local auction = data.auction
        local itemName = GetItemInfo(auction.itemLink) or "Unknown Item"
        local bid = auction.currentBid or 0
        
        table.insert(output, '    {')
        table.insert(output, '      "id": ' .. id .. ',')
        table.insert(output, '      "itemName": ' .. escapeJSON(itemName) .. ',')
        table.insert(output, '      "itemLink": ' .. escapeJSON(auction.itemLink) .. ',')
        table.insert(output, '      "winner": ' .. escapeJSON(auction.topBidder) .. ',')
        table.insert(output, '      "bid": ' .. bid .. ',')
        table.insert(output, '      "status": ' .. escapeJSON(auction.hasEnded and "completed" or "active"))
        table.insert(output, '    }' .. (i < #auctions and ',' or ''))
    end
    
    table.insert(output, '  ],')
    table.insert(output, '  "playerBalances": [')
    
    local balances = {}
    for name, balance in pairs(GDKPT.RaidLeader.Core.PlayerBalances) do
        table.insert(balances, {name = name, balance = balance})
    end
    
    table.sort(balances, function(a, b) return a.name < b.name end)
    
    for i, data in ipairs(balances) do
        local status = data.balance < 0 and "owes" or (data.balance > 0 and "owed" or "settled")
        
        table.insert(output, '    {')
        table.insert(output, '      "player": ' .. escapeJSON(data.name) .. ',')
        table.insert(output, '      "balance": ' .. data.balance .. ',')
        table.insert(output, '      "status": ' .. escapeJSON(status))
        table.insert(output, '    }' .. (i < #balances and ',' or ''))
    end
    
    table.insert(output, '  ]')
    table.insert(output, '}')
    
    return table.concat(output, "\n")
end


-------------------------------------------------------------------
-- Screenshot Export Functions
-------------------------------------------------------------------


local function CreateAndGetScreenshotFrame(name, title, point, x, y)
    local ssFrame = _G[name]
    
    if not ssFrame then
        ssFrame = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
        ssFrame:SetSize(500, 800) 
        ssFrame:SetMovable(true)
        ssFrame:EnableMouse(true)
        ssFrame:RegisterForDrag("LeftButton")
        ssFrame:SetScript("OnDragStart", ssFrame.StartMoving)
        ssFrame:SetScript("OnDragStop", ssFrame.StopMovingOrSizing)
        ssFrame:SetFrameStrata("DIALOG")
        ssFrame:SetFrameLevel(90)
        
        ssFrame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            edgeSize = 32,
            insets = {left = 8, right = 8, top = 8, bottom = 8}
        })
        ssFrame:SetBackdropColor(0.05, 0.05, 0.05, 1)
        
        local closeBtn = CreateFrame("Button", nil, ssFrame, "UIPanelCloseButton")
        closeBtn:SetPoint("TOPRIGHT", -5, -5)
        closeBtn:SetSize(32, 32)
        closeBtn:SetScript("OnClick", function() ssFrame:Hide() end)
        
        local titleBar = CreateFrame("Frame", nil, ssFrame)
        titleBar:SetSize(400, 30)
        titleBar:SetPoint("TOP", 0, 12)
        titleBar:SetBackdrop({
            bgFile = "Interface/Tooltips/UI-Tooltip-Background",
            edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
            tile = true,
            edgeSize = 16,
            tileSize = 16,
            insets = {left = 5, right = 5, top = 5, bottom = 5}
        })
        titleBar:SetBackdropColor(0.1, 0.1, 0.1, 1)
        
        local titleText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        titleText:SetPoint("CENTER")
        titleText:SetText(title) 

        local Label = ssFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        Label:SetPoint("TOPLEFT", 15, -25)
        Label:SetText("Rows:")

        local StartBox = CreateFrame("EditBox", name .. "StartBox", ssFrame, "InputBoxTemplate")
        StartBox:SetSize(30, 25)
        StartBox:SetPoint("LEFT", Label, "RIGHT", 5, 0)
        StartBox:SetAutoFocus(false)
        StartBox:SetMaxLetters(3)
        StartBox:SetNumeric(true)
        ssFrame.StartBox = StartBox

        local ToLabel = ssFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        ToLabel:SetPoint("LEFT", StartBox, "RIGHT", 5, 0)
        ToLabel:SetText("-")

        local EndBox = CreateFrame("EditBox", name .. "EndBox", ssFrame, "InputBoxTemplate")
        EndBox:SetSize(30, 25)
        EndBox:SetPoint("LEFT", ToLabel, "RIGHT", 5, 0)
        EndBox:SetAutoFocus(false)
        EndBox:SetMaxLetters(3)
        EndBox:SetNumeric(true)
        ssFrame.EndBox = EndBox
        
        local UpdateButton = CreateFrame("Button", nil, ssFrame, "GameMenuButtonTemplate")
        UpdateButton:SetSize(70, 20)
        UpdateButton:SetPoint("LEFT", EndBox, "RIGHT", 10, 0)
        UpdateButton:SetText("Update")
        UpdateButton:SetNormalFontObject("GameFontNormalSmall")
        
        ssFrame.InitialData = {}

        if name == "GDKPT_ScreenshotFrame1" then
            StartBox:SetText("1")
            EndBox:SetText("28")
        elseif name == "GDKPT_ScreenshotFrame2" then
            StartBox:SetText("29")
            EndBox:SetText("57")
        end

        local function UpdateContentWithFilter()
            local startRow = tonumber(ssFrame.StartBox:GetText()) or 1
            local endRow = tonumber(ssFrame.EndBox:GetText()) or 999
            
            GDKPT.RaidLeader.Export.PopulateScreenshotContent(
                ssFrame.scrollContent, 
                ssFrame.InitialData.raidName, 
                ssFrame.InitialData.summaryData, 
                ssFrame.InitialData.allAuctions,
                startRow, 
                endRow
            )
        end
        
        UpdateButton:SetScript("OnClick", UpdateContentWithFilter)

        StartBox:SetScript("OnEnterPressed", UpdateContentWithFilter)
        EndBox:SetScript("OnEnterPressed", UpdateContentWithFilter)
       


        local scrollFrame = CreateFrame("ScrollFrame", name .. "ScrollFrame", ssFrame, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", 15, -45)
        scrollFrame:SetPoint("BOTTOMRIGHT", -35, 15)
        
        local scrollContent = CreateFrame("Frame", name .. "ScrollContent", scrollFrame)
        scrollContent:SetWidth(430)
        scrollContent:SetHeight(1)
        scrollFrame:SetScrollChild(scrollContent)
        
        ssFrame.scrollContent = scrollContent
        ssFrame.scrollFrame = scrollFrame
        
        GDKPT.RaidLeader.Export[name] = ssFrame
    end
    
    ssFrame:SetPoint("CENTER", UIParent, "CENTER", x, y)
    return ssFrame
end




local function PopulateScreenshotContent(content, raidName, summaryData, allAuctions, startRow, endRow)
    local auctions = {}
    for _, data in ipairs(allAuctions) do
        if data.id >= startRow and data.id <= endRow then
            table.insert(auctions, data)
        end
    end

    -- Clear previous content
    if content.children then
        for _, child in ipairs(content.children) do
            child:Hide()
        end
        wipe(content.children)
    else
        content.children = {}
    end
    
    local contentWidth = content:GetWidth()
    local yOffset = -10
    
    local raidNameText = content:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    local titleText = string.format("|cffFFD700%s (Auctions %d-%d)|r", raidName, startRow, endRow)
    raidNameText:SetPoint("TOP", content, "TOP", 0, yOffset)
    raidNameText:SetText(titleText)
    table.insert(content.children, raidNameText)
    yOffset = yOffset - 40
    
    local summaryText = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    summaryText:SetPoint("TOP", content, "TOP", 0, yOffset)
    summaryText:SetText(string.format(
        "|cffAAAAAAPlayers:|r |cffFFFFFF%d|r  |cffAAAAAATotal Pot:|r |cffFFD700%s|r  |cffAAAAAACut:|r |cff00FF00%s|r",
        summaryData.splitCount,
        GDKPT.Utils.FormatMoney(summaryData.totalPot * 10000),
        GDKPT.Utils.FormatMoney(summaryData.totalCut * 10000)
    ))
    table.insert(content.children, summaryText)
    yOffset = yOffset - 30
    
    local separator1 = content:CreateTexture(nil, "ARTWORK")
    separator1:SetSize(contentWidth * 0.95, 2)
    separator1:SetPoint("TOP", content, "TOP", 0, yOffset)
    separator1:SetColorTexture(0.5, 0.5, 0.5, 0.8)
    table.insert(content.children, separator1)
    yOffset = yOffset - 10
    
    for i, data in ipairs(auctions) do
        local id = data.id
        local auction = data.auction
        local bid = auction.currentBid or 0
        
        local auctionFrame = CreateFrame("Frame", nil, content)
        auctionFrame:SetSize(contentWidth, 20)
        auctionFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, yOffset)
        table.insert(content.children, auctionFrame)
        
        local numText = auctionFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        numText:SetPoint("LEFT", auctionFrame, "LEFT", 10, 0)
        numText:SetText("|cffCCCCCC" .. id .. ".|r")
        numText:SetJustifyH("LEFT")
        numText:SetWidth(25)
        
        local bidText = auctionFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        bidText:SetPoint("RIGHT", auctionFrame, "RIGHT", -10, 0)
        bidText:SetText("|cffFFD700" .. GDKPT.Utils.FormatMoney(bid * 10000) .. "|r")
        bidText:SetJustifyH("RIGHT")
        bidText:SetWidth(80)
        
        local itemText = auctionFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        itemText:SetPoint("LEFT", numText, "RIGHT", 5, 0)
        itemText:SetText(auction.itemLink)
        itemText:SetJustifyH("LEFT")
        itemText:SetWidth(200)
        
        local winnerText = auctionFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        winnerText:SetPoint("LEFT", itemText, "RIGHT", 5, 0)
        
        local winnerColor = "|cffFFFFFF"
        winnerText:SetText(winnerColor .. auction.topBidder .. "|r")
        winnerText:SetJustifyH("LEFT")
        winnerText:SetPoint("RIGHT", bidText, "LEFT", -5, 0)
        
        yOffset = yOffset - 22
        
        if i % 5 == 0 and i < #auctions then
            local minisep = content:CreateTexture(nil, "ARTWORK")
            minisep:SetSize(contentWidth * 0.95, 1)
            minisep:SetPoint("TOP", content, "TOP", 0, yOffset)
            minisep:SetColorTexture(0.3, 0.3, 0.3, 0.3)
            table.insert(content.children, minisep)
            yOffset = yOffset - 5
        end
    end
    
    yOffset = yOffset - 5
    local separator2 = content:CreateTexture(nil, "ARTWORK")
    separator2:SetSize(contentWidth * 0.95, 2)
    separator2:SetPoint("TOP", content, "TOP", 0, yOffset)
    separator2:SetColorTexture(0.5, 0.5, 0.5, 0.8)
    table.insert(content.children, separator2)
    yOffset = yOffset - 15
    
    local footerText = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    footerText:SetPoint("TOP", content, "TOP", 0, yOffset)

    local raidLeader = GDKPT.RaidLeader.Utils.GetRaidLeaderName() or "N/A"
    local footerString = "|cff888888Generated by GDKPT - " .. date("%Y-%m-%d %H:%M") .. "|r\n|cff888888Raid Leader: |r|cffFFFFFF" .. raidLeader .. "|r"
    footerText:SetText(footerString)
    table.insert(content.children, footerText)
    yOffset = yOffset - 30 
    
    content:SetHeight(math.abs(yOffset) + 20)
    
    content:GetParent():SetVerticalScroll(0)
end
GDKPT.RaidLeader.Export.PopulateScreenshotContent = PopulateScreenshotContent 




local function GenerateScreenshotExport(raidName)
    local totalPot = GDKPT.RaidLeader.Core.GDKP_Pot
    local splitCount = GDKPT.RaidLeader.Core.AuctionSettings.splitCount
    local totalCut = math.floor(totalPot / splitCount)
    
    local summaryData = {
        totalPot = totalPot,
        splitCount = splitCount,
        totalCut = totalCut
    }
    
    local allAuctions = {}
    for id, auction in pairs(GDKPT.RaidLeader.Core.ActiveAuctions) do
        if auction.topBidder then 
            table.insert(allAuctions, {id = id, auction = auction})
        end
    end
    
    table.sort(allAuctions, function(a, b) return a.id < b.id end)

    local ssFrame1 = CreateAndGetScreenshotFrame("GDKPT_ScreenshotFrame1", "|cffFFC125GDKPT Screenshot 1|r", "CENTER", -260, 0)
    ssFrame1.InitialData.raidName = raidName
    ssFrame1.InitialData.summaryData = summaryData
    ssFrame1.InitialData.allAuctions = allAuctions

    local ssFrame2 = CreateAndGetScreenshotFrame("GDKPT_ScreenshotFrame2", "|cffFFC125GDKPT Screenshot 2|r", "CENTER", 260, 0)
    ssFrame2.InitialData.raidName = raidName
    ssFrame2.InitialData.summaryData = summaryData
    ssFrame2.InitialData.allAuctions = allAuctions
    
    GDKPT.RaidLeader.Export.PopulateScreenshotContent(
        ssFrame1.scrollContent, 
        raidName, 
        summaryData, 
        allAuctions,
        tonumber(ssFrame1.StartBox:GetText()), 
        tonumber(ssFrame1.EndBox:GetText())
    )

    GDKPT.RaidLeader.Export.PopulateScreenshotContent(
        ssFrame2.scrollContent, 
        raidName, 
        summaryData, 
        allAuctions,
        tonumber(ssFrame2.StartBox:GetText()), 
        tonumber(ssFrame2.EndBox:GetText())
    )

    ssFrame1:Show()
    ssFrame2:Show()
    
    return "Two screenshot frames are visible. Adjust the 'Rows' fields and click 'Update' to change the content shown."
end







-------------------------------------------------------------------
-- Generate Button Handler
-------------------------------------------------------------------

GenerateButton:SetScript("OnClick", function()
    local raidName = RaidNameBox:GetText()
    if not raidName or raidName == "" then
        raidName = "Unnamed Raid"
    end
    
    local exportData = ""
    
    if selectedFormat == "CSV" then
        exportData = GenerateCSVExport(raidName)
    elseif selectedFormat == "TEXT" then
        exportData = GeneratePlainTextExport(raidName)
    elseif selectedFormat == "SCREENSHOT" then

        ExportFrame:Hide()
        local instructionText = GenerateScreenshotExport(raidName)
        
        ExportTextBox:SetText(instructionText)
        
        print("|cff00ff00[GDKPT Leader]|r " .. instructionText)
        return 
        
    elseif selectedFormat == "JSON" then
        exportData = GenerateJSONExport(raidName)
    end
    
    ExportTextBox:SetText(exportData)
    
    local lines = 1
    for _ in exportData:gmatch("\n") do
        lines = lines + 1
    end
    ExportTextBox:SetHeight(math.max(lines * 14, ScrollFrame:GetHeight()))
    

    C_Timer.After(0.1, function()
        ExportTextBox:SetFocus()
        ExportTextBox:HighlightText()
    end)
    
    print("|cff00ff00[GDKPT Leader]|r Export generated successfully!")
end)

-------------------------------------------------------------------
-- Public Functions
-------------------------------------------------------------------

function GDKPT.RaidLeader.Export.Show()
    ExportFrame:Show()
    
    local defaultName = date("Raid %Y-%m-%d")
    RaidNameBox:SetText(defaultName)
    RaidNameBox:SetCursorPosition(0)
end

function GDKPT.RaidLeader.Export.Hide()
    ExportFrame:Hide()
    
    if GDKPT.RaidLeader.Export.GDKPT_ScreenshotFrame1 then
        GDKPT.RaidLeader.Export.GDKPT_ScreenshotFrame1:Hide()
    end
    if GDKPT.RaidLeader.Export.GDKPT_ScreenshotFrame2 then
        GDKPT.RaidLeader.Export.GDKPT_ScreenshotFrame2:Hide()
    end
end
