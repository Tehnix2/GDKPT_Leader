GDKPT.RaidLeader.RecoverFromMember = {}

local RecoveryFrame = nil
local memberList = {}
local recoveryInProgress = false
local expectedDataCount = 0
local receivedDataCount = 0

function GDKPT.RaidLeader.RecoverFromMember.ShowUI()
    if RecoveryFrame then
        RecoveryFrame:Show()
        GDKPT.RaidLeader.RecoverFromMember.RefreshMemberList()
        return
    end
    
    -- Create frame
    RecoveryFrame = CreateFrame("Frame", "GDKPT_RecoveryFrame", UIParent)
    RecoveryFrame:SetSize(400, 500)
    RecoveryFrame:SetPoint("CENTER")
    RecoveryFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    RecoveryFrame:SetMovable(true)
    RecoveryFrame:EnableMouse(true)
    RecoveryFrame:RegisterForDrag("LeftButton")
    RecoveryFrame:SetScript("OnDragStart", RecoveryFrame.StartMoving)
    RecoveryFrame:SetScript("OnDragStop", RecoveryFrame.StopMovingOrSizing)
    
    -- Title
    local title = RecoveryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -15)
    title:SetText("|cffff8800Crash Recovery|r")
    
    -- Warning text
    local warning = RecoveryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    warning:SetPoint("TOP", 0, -40)
    warning:SetWidth(360)
    warning:SetText("|cffff0000WARNING:|r This will request auction data from a selected raid member. Use this if you crashed and lost data.")
    warning:SetJustifyH("LEFT")
    
    -- Status text
    local statusText = RecoveryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    statusText:SetPoint("TOP", 0, -80)
    statusText:SetWidth(360)
    statusText:SetText("")
    statusText:SetJustifyH("CENTER")
    RecoveryFrame.statusText = statusText
    
    -- Scroll frame for member list
    local scrollFrame = CreateFrame("ScrollFrame", nil, RecoveryFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 20, -110)
    scrollFrame:SetPoint("BOTTOMRIGHT", -40, 50)
    
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(340, 1)
    scrollFrame:SetScrollChild(scrollChild)
    RecoveryFrame.scrollChild = scrollChild
    
    -- Close button
    local closeBtn = CreateFrame("Button", nil, RecoveryFrame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -5, -5)
    closeBtn:SetScript("OnClick", function() RecoveryFrame:Hide() end)
    
    GDKPT.RaidLeader.RecoverFromMember.RefreshMemberList()
end

function GDKPT.RaidLeader.RecoverFromMember.RefreshMemberList()
    if not RecoveryFrame then return end
    
    local scrollChild = RecoveryFrame.scrollChild
    
    -- Clear existing buttons
    for _, child in ipairs({scrollChild:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end
    
    -- Get raid members
    memberList = {}
    if IsInRaid() then
        for i = 1, GetNumRaidMembers() do
            local name = GetRaidRosterInfo(i)
            if name and name ~= UnitName("player") then
                table.insert(memberList, name)
            end
        end
    end
    
    table.sort(memberList)
    
    -- Create buttons for each member
    local yOffset = 0
    for _, memberName in ipairs(memberList) do
        local btn = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
        btn:SetSize(320, 25)
        btn:SetPoint("TOP", 0, -yOffset)
        btn:SetText(memberName)
        btn:SetScript("OnClick", function()
            GDKPT.RaidLeader.RecoverFromMember.RequestDataFrom(memberName)
        end)
        
        yOffset = yOffset + 30
    end
    
    scrollChild:SetHeight(math.max(yOffset, 300))
end

function GDKPT.RaidLeader.RecoverFromMember.RequestDataFrom(memberName)
    StaticPopupDialogs["GDKPT_CONFIRM_RECOVERY"] = {
        text = string.format("Request auction data from %s?\n\nThis will OVERWRITE your current data!", memberName),
        button1 = "Yes, Recover",
        button2 = "Cancel",
        OnAccept = function()
            recoveryInProgress = true
            expectedDataCount = 0
            receivedDataCount = 0
            
            -- Update status
            if RecoveryFrame and RecoveryFrame.statusText then
                RecoveryFrame.statusText:SetText("|cff00ff00Requesting data...|r")
            end
            
            -- Send recovery request
            local msg = "REQUEST_RECOVERY_DATA:"
            SendAddonMessage(GDKPT.RaidLeader.Core.addonPrefix, msg, "WHISPER", memberName)
            print(string.format(GDKPT.RaidLeader.Core.addonPrintString .. "Requesting data from %s...", memberName))
            
            -- Timeout after 30 seconds
            C_Timer.After(30, function()
                if recoveryInProgress then
                    recoveryInProgress = false
                    print(GDKPT.RaidLeader.Core.errorPrintString .. "Recovery timeout - no response from member")
                    if RecoveryFrame and RecoveryFrame.statusText then
                        RecoveryFrame.statusText:SetText("|cffff0000Timeout - no response|r")
                    end
                end
            end)
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
    StaticPopup_Show("GDKPT_CONFIRM_RECOVERY")
end

local function UpdateRecoveryStatus()
    if RecoveryFrame and RecoveryFrame.statusText then
        if expectedDataCount > 0 then
            RecoveryFrame.statusText:SetText(string.format("|cff00ff00Receiving: %d/%d|r", 
                receivedDataCount, expectedDataCount))
        end
    end
end

local function CompleteRecovery()
    recoveryInProgress = false
    print(GDKPT.RaidLeader.Core.addonPrintString .. "Recovery complete!")
    
    if RecoveryFrame then
        if RecoveryFrame.statusText then
            RecoveryFrame.statusText:SetText("|cff00ff00Recovery Complete!|r")
        end
        C_Timer.After(2, function()
            if RecoveryFrame then
                RecoveryFrame:Hide()
            end
        end)
    end
    
    -- Update UI
    if GDKPT.RaidLeader.PlayerBalance and GDKPT.RaidLeader.PlayerBalance.UpdatePlayerBalance then
        GDKPT.RaidLeader.PlayerBalance.UpdatePlayerBalance()
    end
    
    -- Sync recovered data to all raid members
    C_Timer.After(1, function()
        if GDKPT.RaidLeader.Sync then
            GDKPT.RaidLeader.Sync.SyncSettings()
            C_Timer.After(0.5, function()
                GDKPT.RaidLeader.Sync.SyncAuctions()
                local totalDelay = (#GDKPT.RaidLeader.Core.ActiveAuctions * 0.5) + 0.5
                GDKPT.RaidLeader.Sync.SyncPot(nil, totalDelay)
            end)
        end
    end)
end

-- Event handler to receive recovery data
local recoveryFrame = CreateFrame("Frame")
recoveryFrame:RegisterEvent("CHAT_MSG_ADDON")
recoveryFrame:SetScript("OnEvent", function(self, event, prefix, msg, channel, sender)
    if prefix ~= GDKPT.RaidLeader.Core.addonPrefix then return end
    if not IsRaidLeader() and not IsRaidOfficer() then return end
    if not recoveryInProgress then return end
    
    local cmd, data = msg:match("^([^:]+):(.*)$")
    if not cmd then return end
    
    if cmd == "RECOVERY_DATA_START" then
        -- Format: auctionCount,potAmount
        local auctionCount, potAmount = data:match("([^,]+),([^,]+)")
        expectedDataCount = tonumber(auctionCount) or 0
        receivedDataCount = 0
        
        -- Clear existing data
        wipe(GDKPT.RaidLeader.Core.ActiveAuctions)
        wipe(GDKPT.RaidLeader.Core.PlayerWonItems)
        wipe(GDKPT.RaidLeader.Core.PlayerBalances)
        
        GDKPT.RaidLeader.Core.GDKP_Pot = tonumber(potAmount) or 0
        
        print(string.format(GDKPT.RaidLeader.Core.addonPrintString .. "Recovery started: %d auctions, %d gold pot", 
            expectedDataCount, GDKPT.RaidLeader.Core.GDKP_Pot))
        UpdateRecoveryStatus()
        
    elseif cmd == "RECOVERY_DATA_AUCTION" then
        -- Format: id,itemID,itemLink,startBid,currentBid,topBidder,startTime,endTime,duration,hasEnded,stackCount
        local parts = {strsplit(",", data)}
        
        local auctionId = tonumber(parts[1])
        local itemID = tonumber(parts[2])
        local itemLink = parts[3]
        local startBid = tonumber(parts[4])
        local currentBid = tonumber(parts[5])
        local topBidder = parts[6]
        local startTime = tonumber(parts[7])
        local endTime = tonumber(parts[8])
        local duration = tonumber(parts[9])
        local hasEnded = parts[10] == "true"
        local stackCount = tonumber(parts[11]) or 1
        
        if auctionId and itemID and itemLink then
            -- Create auction hash
            local auctionHash = string.format("RECOVERY_%d_%d", auctionId, startTime or time())
            local itemInstanceHash = string.format("RECOVERY_ITEM_%d_%s", itemID, itemLink:match("item:([%-?%d:]+)") or "")
            
            GDKPT.RaidLeader.Core.ActiveAuctions[auctionId] = {
                id = auctionId,
                itemID = itemID,
                itemLink = itemLink,
                startTime = startTime or time(),
                endTime = endTime or (time() + 30),
                duration = duration or 30,
                startBid = startBid or 50,
                currentBid = currentBid or 0,
                topBidder = topBidder or "",
                stackCount = stackCount,
                hasEnded = hasEnded,
                auctionHash = auctionHash,
                itemInstanceHash = itemInstanceHash
            }
            
            -- Update next auction ID
            if auctionId >= GDKPT.RaidLeader.Core.nextAuctionId then
                GDKPT.RaidLeader.Core.nextAuctionId = auctionId + 1
            end
            
            receivedDataCount = receivedDataCount + 1
            UpdateRecoveryStatus()
        end
        
    elseif cmd == "RECOVERY_DATA_WON_ITEM" then
        -- Format: playerName,auctionId,itemID,itemLink,price,stackCount
        local playerName, auctionId, itemID, itemLink, price, stackCount = 
            data:match("([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+)")
        
        if playerName and auctionId and itemID then
            GDKPT.RaidLeader.Core.PlayerWonItems[playerName] = GDKPT.RaidLeader.Core.PlayerWonItems[playerName] or {}
            
            table.insert(GDKPT.RaidLeader.Core.PlayerWonItems[playerName], {
                auctionId = tonumber(auctionId),
                itemID = tonumber(itemID),
                itemLink = itemLink,
                stackCount = tonumber(stackCount) or 1,
                price = tonumber(price) or 0,
                bid = tonumber(price) or 0,
                winningBid = tonumber(price) or 0,
                manuallyAdjusted = false,
                traded = false,
                fullyTraded = false,
                inTradeSlot = nil,
                amountPaid = 0,
                remainingQuantity = tonumber(stackCount) or 1,
                timestamp = time(),
                auctionHash = string.format("RECOVERY_%s_%s", auctionId, itemID),
                itemInstanceHash = string.format("RECOVERY_ITEM_%s", itemID)
            })
        end
        
    elseif cmd == "RECOVERY_DATA_BALANCE" then
        -- Format: playerName,balance
        local playerName, balance = data:match("([^,]+),([^,]+)")
        if playerName and balance then
            GDKPT.RaidLeader.Core.PlayerBalances[playerName] = tonumber(balance) or 0
        end
        
    elseif cmd == "RECOVERY_DATA_COMPLETE" then
        CompleteRecovery()
    end
end)