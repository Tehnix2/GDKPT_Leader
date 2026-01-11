GDKPT.RaidLeader.PotAdjustment = {}

local AdjustmentFrame = nil

function GDKPT.RaidLeader.PotAdjustment.ShowUI()
    if AdjustmentFrame then
        AdjustmentFrame:Show()
        return
    end
    
    -- Create frame
    AdjustmentFrame = CreateFrame("Frame", "GDKPT_PotAdjustmentFrame", UIParent)
    AdjustmentFrame:SetSize(300, 150)
    AdjustmentFrame:SetPoint("CENTER")
    AdjustmentFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    AdjustmentFrame:SetMovable(true)
    AdjustmentFrame:EnableMouse(true)
    AdjustmentFrame:RegisterForDrag("LeftButton")
    AdjustmentFrame:SetScript("OnDragStart", AdjustmentFrame.StartMoving)
    AdjustmentFrame:SetScript("OnDragStop", AdjustmentFrame.StopMovingOrSizing)
    
    -- Title
    local title = AdjustmentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -15)
    title:SetText("Adjust Pot Manually")
    
    -- Current pot display
    local currentPot = AdjustmentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    currentPot:SetPoint("TOP", 0, -40)
    currentPot:SetText(string.format("Current Pot: %d gold", GDKPT.RaidLeader.Core.GDKP_Pot))
    AdjustmentFrame.currentPot = currentPot
    
    -- Amount input
    local amountLabel = AdjustmentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    amountLabel:SetPoint("TOPLEFT", 20, -70)
    amountLabel:SetText("Adjust by (gold):")
    
    local amountBox = CreateFrame("EditBox", nil, AdjustmentFrame, "InputBoxTemplate")
    amountBox:SetSize(100, 20)
    amountBox:SetPoint("LEFT", amountLabel, "RIGHT", 10, 0)
    amountBox:SetAutoFocus(false)
    amountBox:SetNumeric(true)
    amountBox:SetMaxLetters(6)
    AdjustmentFrame.amountBox = amountBox
    
    -- Apply button
    local applyBtn = CreateFrame("Button", nil, AdjustmentFrame, "UIPanelButtonTemplate")
    applyBtn:SetSize(100, 22)
    applyBtn:SetPoint("BOTTOM", 0, 20)
    applyBtn:SetText("Apply")
    applyBtn:SetScript("OnClick", function()
        local amount = tonumber(amountBox:GetText())
        if not amount then
            print(GDKPT.RaidLeader.Core.errorPrintString .. "Invalid amount")
            return
        end
        
        GDKPT.RaidLeader.PotAdjustment.AdjustPot(amount)
        AdjustmentFrame:Hide()
    end)
    
    -- Close button
    local closeBtn = CreateFrame("Button", nil, AdjustmentFrame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -5, -5)
    closeBtn:SetScript("OnClick", function() AdjustmentFrame:Hide() end)
end

function GDKPT.RaidLeader.PotAdjustment.AdjustPot(amount)
    local oldPot = GDKPT.RaidLeader.Core.GDKP_Pot
    GDKPT.RaidLeader.Core.GDKP_Pot = oldPot + amount
    
    -- Sync to raid
    if IsInRaid() then
        local currentSplitCount = GDKPT.RaidLeader.Utils.GetCurrentSplitCount()
        local msg = string.format("SYNC_POT:%d:%d", GDKPT.RaidLeader.Core.GDKP_Pot, currentSplitCount)
        SendAddonMessage(GDKPT.RaidLeader.Core.addonPrefix, msg, "RAID")
        
        SendChatMessage(string.format("[GDKPT] Pot manually adjusted by %d gold (was %d, now %d)", 
            amount, oldPot, GDKPT.RaidLeader.Core.GDKP_Pot), "RAID")
    end
    
    print(string.format(GDKPT.RaidLeader.Core.addonPrintString .. "Pot adjusted: %d -> %d (%+d)", 
        oldPot, GDKPT.RaidLeader.Core.GDKP_Pot, amount))
end