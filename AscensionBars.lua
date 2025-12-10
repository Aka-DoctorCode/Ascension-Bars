-----------------------------
-- AscensionBars XP & Rep Top Bars
-- WoW Addon to display a slim experience and reputation bar anchored to the top of the screen.
-----------------------------

-- === CONFIGURATION OPTIONS ===
local TEXT_CENTERED = false
local TEXT_MOUSEOVER_ONLY = false

-- === Hide Blizzard XP and Reputation Bars ===
local function HideDefaultXPAndRepBars()
    if MainMenuExpBar then
        MainMenuExpBar:UnregisterAllEvents()
        MainMenuExpBar:Hide()
        MainMenuExpBar.Show = function() end
    end

    if MainMenuBarMaxLevelBar then
        MainMenuBarMaxLevelBar:Hide()
        MainMenuBarMaxLevelBar.Show = function() end
    end

    if ReputationWatchBar then
        ReputationWatchBar:UnregisterAllEvents()
        ReputationWatchBar:Hide()
        ReputationWatchBar.Show = function() end
    end

    if ReputationWatchStatusBar then
        ReputationWatchStatusBar:Hide()
        ReputationWatchStatusBar.Show = function() end
    end

    if ReputationWatchBarOverlayFrame then
        ReputationWatchBarOverlayFrame:Hide()
        ReputationWatchBarOverlayFrame.Show = function() end
    end

    if StatusTrackingBarManager then
        StatusTrackingBarManager:UnregisterAllEvents()
        StatusTrackingBarManager:Hide()
        StatusTrackingBarManager.Show = function() end
    end
end

C_Timer.After(1, HideDefaultXPAndRepBars)

-- === VARIABLES ===
local _, playerClass = UnitClass("player")
local classColor = RAID_CLASS_COLORS[playerClass]
local classColor = RAID_CLASS_COLORS[playerClass]
local wasMaxLevel = nil

-- === CUSTOM COLORS ===
local CUSTOM_REP_COLORS = {
    [1] = {r=0.8, g=0.133, b=0.133}, -- Hated #CC2222
    [2] = {r=1.0, g=0.0, b=0.0},     -- Hostile #FF0000
    [3] = {r=0.933, g=0.4, b=0.133}, -- Unfriendly #EE6622
    [4] = {r=1.0, g=1.0, b=0.0},     -- Neutral #FFFF00
    [5] = {r=0.0, g=1.0, b=0.0},     -- Friendly #00FF00
    [6] = {r=0.0, g=1.0, b=0.533},   -- Honored #00FF88
    [7] = {r=0.0, g=1.0, b=0.8},     -- Revered #00FFCC
    [8] = {r=0.0, g=1.0, b=1.0},     -- Exalted #00FFFF
    [9] = {r=0.858, g=0.733, b=0.008}, -- Paragon #dbbb02
    [10] = {r=0.639, g=0.208, b=0.933}, -- Maxed #a335ee
    [11] = {r=0.255, g=0.412, b=0.882}, -- Renown #4169E1 (Royal Blue)
}

local function GetGradientColor(percent)
    local r1, g1, b1 = 0.8, 0.133, 0.133
    local r2, g2, b2 = 0.858, 0.733, 0.008
    percent = math.min(math.max(percent, 0), 1)
    
    return {
        r = r1 + (r2 - r1) * percent,
        g = g1 + (g2 - g1) * percent,
        b = b1 + (b2 - b1) * percent
    }
end

-- === HELPERS ===
local coloredPipe = string.format("|cff%02x%02x%02x | |r",
    classColor.r * 255, classColor.g * 255, classColor.b * 255)

local function FormatXP()
    local maxLevel = GetMaxPlayerLevel()
    local currentLevel = UnitLevel("player")

    if currentLevel == maxLevel then
        return string.format("Level %d (Max)", currentLevel)
    end

    local currentXP = UnitXP("player")
    local maxXP = UnitXPMax("player")
    local percent = (maxXP > 0) and (currentXP / maxXP * 100) or 0

    local restedXP = GetXPExhaustion()
    local restedPercent = restedXP and (maxXP > 0 and restedXP / maxXP * 100 or 0) or 0

    local baseText = string.format(
        "Level %d%s%s/%s (%.1f%%)",
        currentLevel,
        coloredPipe,
        BreakUpLargeNumbers(currentXP),
        BreakUpLargeNumbers(maxXP),
        percent
    )

    if restedXP and restedPercent > 1 then
        return string.format("%s%sRested %.1f%%", baseText, coloredPipe, restedPercent)
    end

    return baseText
end

local function FormatRep(name, reaction, min, max, value, forcedLabel, isMaxed)
    -- reaction is 1-8 (Hated to Exalted)
    local standingLabel = forcedLabel or (_G["FACTION_STANDING_LABEL"..reaction] or "??")
    
    if isMaxed then
        return string.format("%s (%s)", name, standingLabel)
    end

    local current = value - min
    local cap = max - min
    local percent = (cap > 0) and (current / cap * 100) or 0
    
    -- Format: FactionName (Standing) Value/Max (Percent%)
    return string.format("%s (%s) %s/%s (%.1f%%)", 
        name, 
        standingLabel, 
        BreakUpLargeNumbers(current), 
        BreakUpLargeNumbers(cap), 
        percent)
end

-- === CREATE FRAMES ===

-- 1. XP Bar
local xpBar = CreateFrame("StatusBar", "LanacanXPBar_XP", UIParent)
xpBar:SetHeight(5)
xpBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
xpBar:SetStatusBarColor(classColor.r, classColor.g, classColor.b)
-- XP Spark
local xpSpark = xpBar:CreateTexture(nil, "OVERLAY")
xpSpark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
xpSpark:SetSize(6, 6)
xpSpark:SetBlendMode("ADD")
-- XP Text
local xpTxFrame = CreateFrame("Frame", "LanacanXPBar_XPText", UIParent)
xpTxFrame:SetHeight(15)
local xpText = xpTxFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
xpText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
xpText:SetAllPoints(true)

-- 2. Rep Bar
local repBar = CreateFrame("StatusBar", "LanacanXPBar_Rep", UIParent)
repBar:SetHeight(6)
repBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
-- Rep Spark
local repSpark = repBar:CreateTexture(nil, "OVERLAY")
repSpark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
repSpark:SetSize(6, 6)
repSpark:SetBlendMode("ADD")
-- Rep Text
local repTxFrame = CreateFrame("Frame", "LanacanXPBar_RepText", UIParent)
repTxFrame:SetHeight(15)
local repText = repTxFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
repText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
repText:SetAllPoints(true)

-- 3. Text Holder (For Centering)
local textHolder = CreateFrame("Frame", "AscensionBars_TextHolder", UIParent)
-- Original was -12. Subtracting 2 => -13.5
textHolder:SetPoint("TOP", UIParent, "TOP", 0, -13.5)
textHolder:SetHeight(15)

-- 4. Paragon Reward Text
local paragonText = textHolder:CreateFontString(nil, "OVERLAY", "GameFontNormal")
paragonText:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE, THICK")
paragonText:SetPoint("TOP", textHolder, "BOTTOM", 0, -30)
paragonText:SetText("|cFF00FF00PARAGON REWARD PENDING!|r")
paragonText:Hide()


-- === LAYOUT UPDATE ===
local function UpdateLayout(isMaxLevel)
    -- Reset Points
    xpBar:ClearAllPoints()
    repBar:ClearAllPoints()
    
    xpTxFrame:ClearAllPoints()
    repTxFrame:ClearAllPoints()
    
    if isMaxLevel then
        -- === MAX LEVEL MODE ===
        -- XP Bar: Hidden
        xpBar:Hide()
        xpTxFrame:Hide()
        
        -- Rep Bar: Takes Top Spot (replacing XP), shifted down 2px
        repBar:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, -2)
        repBar:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", 0, -2)
        
    else
        -- === NORMAL MODE ===
        -- XP Bar: Top, shifted down 2px
        xpBar:Show()
        xpTxFrame:Show()
        
        xpBar:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, -2)
        xpBar:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", 0, -2)
        
        -- Rep Bar: Below XP Bar (2px gap)
        -- XP Bar Top = -2. Height = 5. Bottom = -7. Gap = 2.
        -- New Rep Top = -7 - 2 = -9
        repBar:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, -9)
        repBar:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", 0, -9)
    end
end


-- === UPDATE LOOP ===
local function UpdateDisplay()
    local maxLvl = GetMaxPlayerLevel()
    local curLvl = UnitLevel("player")
    local isMax = (curLvl >= maxLvl)
    
    -- Check for state change to re-layout
    if isMax ~= wasMaxLevel then
        UpdateLayout(isMax)
        wasMaxLevel = isMax
    end
    
    -- 1. XP UPDATE (Only if not max)
    if not isMax then
        local currentXP = UnitXP("player")
        local maxXP = UnitXPMax("player")
        local restedXP = GetXPExhaustion()

        -- Bar Color (Rested vs Class)
        if restedXP and restedXP > 0 then
            xpBar:SetStatusBarColor(0.6, 0.4, 0.8)
        else
            xpBar:SetStatusBarColor(classColor.r, classColor.g, classColor.b)
        end
        
        xpBar:SetMinMaxValues(0, maxXP)
        xpBar:SetValue(currentXP)
        
        -- XP Spark
        local barWidth = xpBar:GetWidth()
        local pct = (maxXP > 0) and (currentXP / maxXP) or 0
        xpSpark:ClearAllPoints()
        xpSpark:SetPoint("CENTER", xpBar, "LEFT", barWidth * pct, 0)
        
        -- XP Text
        xpText:SetText("|cFFFFFFFF" .. FormatXP() .. "|r")
        xpTxFrame:SetWidth(xpText:GetStringWidth() + 2)
    end
    
    -- 2. REP UPDATE
    local name, reaction, min, max, value, factionID
    local standingLabel = nil
    local paragonRewardFound = false
    local isFriendshipMaxed = false
    local isFriendshipMaxed = false
    
    -- Function to check for ALL pending paragon rewards
    local function GetPendingParagonFactions()
        if not C_Reputation or not C_Reputation.GetNumFactions then return {} end
        
        local pending = {}
        local numFactions = C_Reputation.GetNumFactions()
        for i = 1, numFactions do
            local factionData = C_Reputation.GetFactionDataByIndex(i)
            if factionData and factionData.factionID then
                if C_Reputation.IsFactionParagon(factionData.factionID) then
                    local currentValue, threshold, rewardQuestID, hasRewardPending = C_Reputation.GetFactionParagonInfo(factionData.factionID)
                    -- A reward is truly pending only if BOTH hasRewardPending is true AND there's a valid quest ID
                    -- The quest ID is the definitive indicator that a reward is ready to be claimed
                    if hasRewardPending and rewardQuestID and rewardQuestID > 0 then
                        table.insert(pending, {name = factionData.name, id = factionData.factionID})
                    end
                end
            end
        end
        return pending
    end

    local pendingFactions = GetPendingParagonFactions()
    
    -- Priority: 
    -- 1. Pending Paragon Reward (Force display)
    -- 2. Watched Faction
    
    if #pendingFactions > 0 then
        -- Override with Paragon Reward Info
        paragonRewardFound = true
        
        -- Use the first one for bar context
        name = pendingFactions[1].name
        factionID = pendingFactions[1].id
        
        -- Format List: A, B and C
        local namesList = {}
        for _, f in ipairs(pendingFactions) do
            table.insert(namesList, string.upper(f.name))
        end
        
        local textStr = ""
        if #namesList == 1 then
            textStr = namesList[1]
        else
            local last = table.remove(namesList)
            textStr = table.concat(namesList, ", ") .. " AND " .. last
        end
        
        local plural = (#pendingFactions > 1) and "S" or ""
        
        -- Force full bar visual
        min = 0
        max = 1
        value = 1
        standingLabel = "Reward Pending"
        reaction = 8 -- Exalted equivalent color usually
        
        paragonText:SetText("|cFF00FF00" .. textStr .. " REWARD" .. plural .. " PENDING!|r")
        paragonText:Show()
        
    else
        paragonText:Hide()
        
        -- Normal Watched Faction
        if C_Reputation and C_Reputation.GetWatchedFactionData then
            local data = C_Reputation.GetWatchedFactionData()
            if data then
                name = data.name
                reaction = data.reaction
                min = data.currentReactionThreshold
                max = data.nextReactionThreshold
                value = data.currentStanding
                factionID = data.factionID
                
                -- Renown Logic (Major Factions)
                if C_Reputation.IsMajorFaction and C_Reputation.IsMajorFaction(factionID) then
                    local majorData = C_MajorFactions and C_MajorFactions.GetMajorFactionData(factionID)
                    if majorData then
                        min = 0
                        max = majorData.renownLevelThreshold
                        value = majorData.renownReputationEarned
                        
                        -- Get Max Renown Level if available
                        local maxRenown = 0
                        local levels = C_MajorFactions.GetRenownLevels(factionID)
                        if levels then
                            maxRenown = #levels
                        end
                        
                        if maxRenown > 0 then
                            standingLabel = string.format("Renown %d/%d", majorData.renownLevel, maxRenown)
                        else
                            standingLabel = "Renown " .. majorData.renownLevel
                        end
                    end
                -- Paragon Logic (Watched but no reward pending)
                elseif factionID and C_Reputation.IsFactionParagon(factionID) then
                    local currentValue, threshold = C_Reputation.GetFactionParagonInfo(factionID)
                    if currentValue then
                        min = 0
                        max = threshold
                        value = currentValue % threshold
                        standingLabel = "Paragon"
                    end
                -- Friendship Logic (Special Ranks)
                else
                    local friendData = C_GossipInfo and C_GossipInfo.GetFriendshipReputation(factionID)
                    if friendData and friendData.friendshipFactionID and friendData.friendshipFactionID > 0 then
                        standingLabel = friendData.reaction
                        if friendData.nextThreshold then
                            min = friendData.reactionThreshold
                            max = friendData.nextThreshold
                            value = friendData.standing
                        else
                            min = 0
                            max = 1
                            value = 1
                            isFriendshipMaxed = true
                        end
                    end
                end
            end
        end
    end
    
    if name then
        repBar:Show()
        repTxFrame:Show()
        
        -- Apply Colors & Logic
        -- We calculate logic first to potentially override min/max/value (e.g. for maxed bars)
        local isPatternMaxed = false
        
        if paragonRewardFound or (factionID and C_Reputation.IsFactionParagon(factionID)) then
            -- Paragon (Gold)
            -- Values are already handled by Paragon logic upstream
            local c = CUSTOM_REP_COLORS[9]
            repBar:SetStatusBarColor(c.r, c.g, c.b)
            
        elseif C_Reputation.IsMajorFaction and C_Reputation.IsMajorFaction(factionID) then
            -- Renown
            local levels = C_MajorFactions.GetRenownLevels(factionID)
            local maxRenown = (levels and #levels > 0) and #levels or 0
            local majorData = C_MajorFactions.GetMajorFactionData(factionID)
            local current = majorData and majorData.renownLevel or 0
            
            -- If current is max or higher, use Maxed Color (Purple) AND FORCE FULL BAR
            if maxRenown > 0 and current >= maxRenown then
                local c = CUSTOM_REP_COLORS[10]
                repBar:SetStatusBarColor(c.r, c.g, c.b)
                -- Force visual full bar (otherwise it might show 0/2500)
                min = 0
                max = 1
                value = 1
                isPatternMaxed = true
                standingLabel = "Renown " .. current
            else
                -- Not maxed yet, use Royal Blue (Renown Progress)
                local c = CUSTOM_REP_COLORS[11]
                repBar:SetStatusBarColor(c.r, c.g, c.b)
            end
            
        else
            -- Classic / Friendship (Reaction Mapped)
            
            -- CHECK FOR EXALTED / MAXED (Non-Paragon)
            local isClassicMaxed = false
            if reaction == 8 then
                if (max == 0) or (min == max) then
                    isClassicMaxed = true
                end
            end
            
            if isClassicMaxed or isFriendshipMaxed then
                local c = CUSTOM_REP_COLORS[10]
                repBar:SetStatusBarColor(c.r, c.g, c.b)
                -- Force visual full bar
                min = 0
                max = 1
                value = 1
                isPatternMaxed = true
            else
                local c = CUSTOM_REP_COLORS[reaction]
                if c then
                    repBar:SetStatusBarColor(c.r, c.g, c.b)
                else
                    repBar:SetStatusBarColor(0.5, 0.5, 0.5) -- Fallback
                end
            end
        end
        
        -- Apply Values to Bar (AFTER logic adjustments)
        repBar:SetMinMaxValues(min, max)
        repBar:SetValue(value)
        
        -- Rep Spark
        local total = max - min
        local curr = value - min
        local pct2 = (total > 0) and (curr / total) or 0
        local barWidth2 = repBar:GetWidth()
        repSpark:ClearAllPoints()
        repSpark:SetPoint("CENTER", repBar, "LEFT", barWidth2 * pct2, 0)
        
        -- Rep Text
        repText:SetText("|cFFFFFFFF" .. FormatRep(name, reaction, min, max, value, standingLabel, isPatternMaxed) .. "|r")
        repTxFrame:SetWidth(repText:GetStringWidth() + 2)
        
    else
        -- No faction watched
        repBar:Hide()
        repTxFrame:Hide()
        paragonText:Hide()
    end
    
    -- === TEXT CENTERING LOGIC ===
    -- Calculate layout based on what is visible
    local gap = 30
    
    if isMax then
        -- Only Rep is potentially visible
        if name then
            textHolder:SetWidth(repTxFrame:GetWidth())
            repTxFrame:ClearAllPoints()
            repTxFrame:SetPoint("CENTER", textHolder, "CENTER")
        end
    else
        -- XP is always visible in Normal Mode
        if name then
            -- Both Visible
            local w1 = xpTxFrame:GetWidth()
            local w2 = repTxFrame:GetWidth()
            textHolder:SetWidth(w1 + gap + w2)
            
            xpTxFrame:ClearAllPoints()
            xpTxFrame:SetPoint("LEFT", textHolder, "LEFT", 0, 0)
            
            repTxFrame:ClearAllPoints()
            repTxFrame:SetPoint("LEFT", xpTxFrame, "RIGHT", gap, 0)
        else
            -- Only XP Visible
            textHolder:SetWidth(xpTxFrame:GetWidth())
            xpTxFrame:ClearAllPoints()
            xpTxFrame:SetPoint("CENTER", textHolder, "CENTER")
        end
    end
end

-- Create update frame
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("PLAYER_XP_UPDATE")
f:RegisterEvent("UPDATE_EXHAUSTION")
f:RegisterEvent("PLAYER_LEVEL_UP")
f:RegisterEvent("UPDATE_FACTION")
f:RegisterEvent("MAJOR_FACTION_RENOWN_LEVEL_CHANGED")
f:RegisterEvent("MAJOR_FACTION_UNLOCKED")

f:SetScript("OnEvent", UpdateDisplay)

-- Initial update
UpdateDisplay()
