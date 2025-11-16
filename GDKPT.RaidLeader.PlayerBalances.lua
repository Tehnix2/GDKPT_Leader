GDKPT.RaidLeader.PlayerBalance = {} -- Only holds the UpdatePlayerBalance function, the actual balances are stored in GDKPT.RaidLeader.Core.PlayerBalances

--------------------------------------------------------------------
-- Constants
--------------------------------------------------------------------


local ROW_HEIGHT = 24
local ROW_PADDING = 5
local COLORS = {
    positive = "|cff00ff00",
    negative = "|cffff0000",
    zero = "|cff888888",
    rowEven = {0.15, 0.15, 0.15, 0.5},
    rowOdd = {0.1, 0.1, 0.1, 0.5}
}

-- Frame pool for reusing UI elements
local framePool = {}

-------------------------------------------------------------------
-- Create a single player row frame
-------------------------------------------------------------------

local function CreatePlayerRow(parent)
    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(ROW_HEIGHT)
    row:SetWidth(parent:GetWidth())
    row:EnableMouse(true)
    
    -- Background
    row.bg = row:CreateTexture(nil, "BACKGROUND")
    row.bg:SetAllPoints()
    
    -- Hover texture
    row.highlight = row:CreateTexture(nil, "HIGHLIGHT")
    row.highlight:SetAllPoints()
    row.highlight:SetTexture("Interface/ChatFrame/ChatFrameBackground")
    row.highlight:SetVertexColor(1, 1, 1, 0.2)
    row.highlight:SetBlendMode("ADD")
    
    -- Player name
    row.nameText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.nameText:SetJustifyH("LEFT")
    row.nameText:SetPoint("LEFT", ROW_PADDING, 0)
    row.nameText:SetPoint("RIGHT", -50, 0)
    
    -- Gold amount
    row.goldText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.goldText:SetJustifyH("RIGHT")
    row.goldText:SetPoint("RIGHT", -ROW_PADDING, 0)
    
    -- Click handler
    row:SetScript("OnClick", function(self)
        if not self.playerName then return end 
        
        -- Store player name in adjustment state before showing dialog in manual adjustment
        if GDKPT.RaidLeader.AdjustmentState then
            GDKPT.RaidLeader.AdjustmentState.playerName = self.playerName -- playerName is set during the UpdateRow call
        end
        
        -- Show the StaticPopup for adjusting player balance
        local dialog = StaticPopup_Show("GDKPT_ADJUST_PLAYER", self.playerName)
        if dialog then
            dialog.data = self.playerName  -- Pass player name to the dialog
        end
    end)
    
    -- Tooltip handler
    row:SetScript("OnEnter", function(self)
        if not self.playerName then return end
        
        local wonItems = GDKPT.RaidLeader.Core.PlayerWonItems[self.playerName]
        
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:ClearLines()
        GameTooltip:AddLine(self.playerName .. " - Won Items", 1, 1, 1)
        GameTooltip:AddLine(" ")
        
        if wonItems and #wonItems > 0 then
            for _, item in ipairs(wonItems) do
                local itemLink = item.itemLink or ("ItemID: " .. tostring(item.itemID))
                local price = item.price or item.bid or 0
                GameTooltip:AddDoubleLine(itemLink, 
                    string.format("%dg", price), 
                    0.8, 0.8, 0.8, 1, 1, 0)
            end
        else
            GameTooltip:AddLine("|cff888888No won items.|r")
        end
        
        GameTooltip:Show()
    end)
    
    row:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    return row
end

-------------------------------------------------------------------
-- Get all players who should be displayed
-------------------------------------------------------------------

-- This includes online raid/party members and anyone with a balance
local function GetPlayersToDisplay()
    local players = {}
    
    -- Add raid/party members who are online
    local numGroupMembers = GetNumGroupMembers()
    if numGroupMembers > 0 then
        for i = 1, numGroupMembers do
            local name, _, _, _, _, _, _, online = GetRaidRosterInfo(i)
            if name and online then
                players[name] = true
            end
        end
    else
        -- Solo: add self
        local selfName = UnitName("player")
        if selfName then
            players[selfName] = true
        end
    end
    
    -- Add anyone with a balance (even if offline)
    for name in pairs(GDKPT.RaidLeader.Core.PlayerBalances) do
        players[name] = true
    end
    
    return players
end

-------------------------------------------------------------------
-- Format gold amount with color
-------------------------------------------------------------------

local function FormatGold(amount)
    local copper = math.floor(amount * 10000) -- if stored in gold, convert to copper
    if copper < 0 then
        copper = -copper
    end

    local g = math.floor(copper / 10000)
    local s = math.floor((copper % 10000) / 100)
    local c = copper % 100

    local color
    if amount > 0 then
        color = COLORS.positive
    elseif amount < 0 then
        color = COLORS.negative
    else
        color = COLORS.zero
    end

    local sign = (amount < 0) and "-" or ""
    return string.format("%s%s%d g %02d s %02d c|r", color, sign, g, s, c)
end


-------------------------------------------------------------------
-- Update a single row with player data
-------------------------------------------------------------------

-- index is the row number (1-based) for positioning and coloring   
local function UpdateRow(row, playerName, gold, index)
    row.playerName = playerName
    row.gold = gold
    
    row.nameText:SetText(playerName)
    row.goldText:SetText(FormatGold(gold))
    
    -- Alternating row colors
    local bgColor = (index % 2 == 0) and COLORS.rowEven or COLORS.rowOdd
    row.bg:SetVertexColor(unpack(bgColor))
    
    -- Position
    row:SetPoint("TOPLEFT", row:GetParent(), "TOPLEFT", 
        0, -(index - 1) * ROW_HEIGHT)
    row:Show()
end

-------------------------------------------------------------------
-- Main update function
-------------------------------------------------------------------

-- Updates the player balance display in the Raid Leader UI
function GDKPT.RaidLeader.PlayerBalance.UpdatePlayerBalance()
    local contentFrame = GDKPT.RaidLeader.UI.LeaderContentFrame
    
    -- Gather data
    local playerNames = GetPlayersToDisplay()
    local displayData = {}
    -- Collect players with non-zero balance
    for name in pairs(playerNames) do
        local gold = GDKPT.RaidLeader.Core.PlayerBalances[name] or 0
        if gold ~= 0 then
            table.insert(displayData, {name = name, gold = gold})
        end
    end
    
    -- Sort alphabetically
    table.sort(displayData, function(a, b) 
        return a.name < b.name 
    end)
    
    -- Update or create rows
    for i = 1, #framePool do
        local row = framePool[i]
        if i <= #displayData then
            local data = displayData[i]
            UpdateRow(row, data.name, data.gold, i)
        else
            -- Fully reset rows with no data
            row:Hide()
            row.playerName = nil
            row.gold = 0
            row.nameText:SetText("")
            row.goldText:SetText("")
        end
    end
    
    -- Create new rows if needed
    for i = #framePool + 1, #displayData do
        local data = displayData[i]
        local row = CreatePlayerRow(contentFrame)
        framePool[i] = row
        UpdateRow(row, data.name, data.gold, i)
    end
    
    -- Update content height
    local totalHeight = #displayData * ROW_HEIGHT
    local minHeight = GDKPT.RaidLeader.UI.LeaderScrollFrame:GetHeight()
    contentFrame:SetHeight(math.max(minHeight, totalHeight))
end



-------------------------------------------------------------------
-- Initial update
-------------------------------------------------------------------

GDKPT.RaidLeader.PlayerBalance.UpdatePlayerBalance()




