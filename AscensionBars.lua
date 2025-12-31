-- Happy new year everyone!
-- Please leave feedback to improve the add on
-- ==========================================================
-- AscensionBars - Version 5.0.0
-- ==========================================================
local ADDON_NAME = "AscensionBars"
local AB = LibStub("AceAddon-3.0"):NewAddon(ADDON_NAME, "AceEvent-3.0", "AceConsole-3.0")

-- ==========================================================
-- 1. DEFAULT SETTINGS
-- ==========================================================
local lastUpdate = 0

local defaults = {
    profile = {
        barHeightXP = 5,
        barHeightRep = 6,
        textHeight = 15,
        textSize = 12,
        yOffset = -2,
        paragonTextSize = 14,
        paragonTextYOffset = -100,
        paragonOnTop = false,
        splitParagonText = false,
        paragonTextGap = 5,
        paragonPendingColor = { r = 0, g = 1, b = 0, a = 1.0 },
        showOnMouseover = false,
        hideInCombat = false,
        useClassColorXP = true,
        xpBarColor = { r = 0.0, g = 0.4, b = 0.9, a = 1.0 },
        showRestedBar = true,
        restedBarColor = { r = 0.6, g = 0.4, b = 0.8, a = 0.6 },
        useReactionColorRep = true,
        repBarColor = { r = 0.0, g = 1.0, b = 0.0, a = 1.0 },
        textColor = { r = 1.0, g = 1.0, b = 1.0, a = 1.0 },
        repColors = {
            [1] = { r = 0.8, g = 0.133, b = 0.133, a = 0.70 },
            [2] = { r = 1.0, g = 0.0, b = 0.0, a = 0.70 },
            [3] = { r = 0.933, g = 0.4, b = 0.133, a = 0.70 },
            [4] = { r = 1.0, g = 1.0, b = 0.0, a = 0.70 },
            [5] = { r = 0.0, g = 1.0, b = 0.0, a = 0.70 },
            [6] = { r = 0.0, g = 1.0, b = 0.533, a = 0.70 },
            [7] = { r = 0.0, g = 1.0, b = 0.8, a = 0.70 },
            [8] = { r = 0.0, g = 1.0, b = 1.0, a = 0.70 },
            [9] = { r = 0.858, g = 0.733, b = 0.008, a = 0.70 },
            [10] = { r = 0.639, g = 0.208, b = 0.933, a = 0.70 },
            [11] = { r = 0.255, g = 0.412, b = 0.882, a = 0.70 },
        },
        showPercentage = true,
        showAbsoluteValues = true,
        fontOutline = "OUTLINE",
        sparkEnabled = true,
        animationSpeed = 1.0,
        backgroundAlpha = 0.5,
        barGap = 2,
        useGradient = false,
        gradientStartColor = { r = 1, g = 0, b = 0, a = 1 },
        gradientEndColor = { r = 0, g = 1, b = 0, a = 1 },
        debugMode = false,
    }
}

local CONSTANTS = {
    TEXTURE_BAR = "Interface\\Buttons\\WHITE8X8",
    TEXTURE_SPARK = "Interface\\CastingBar\\UI-CastingBar-Spark",
    UPDATE_THROTTLE = 1,
    DEFAULT_GAP = 30,
    MIN_TEXT_WIDTH = 100,
    ANCHOR_POINTS = {
        TOP = "TOP",
        BOTTOM = "BOTTOM",
        LEFT = "LEFT",
        RIGHT = "RIGHT",
        CENTER = "CENTER"
    },
    MAX_BAR_HEIGHT = 50,
    MIN_BAR_HEIGHT = 1,
    MAX_TEXT_SIZE = 24,
    MIN_TEXT_SIZE = 8,
}

-- Texture pool for performance
local texturePool = {}

-- ==========================================================
-- 2. OPTIONS TABLE
-- ==========================================================
function AB:GetOptionsTable()
    local options = {
        name = "Ascension Bars",
        type = "group",
        childGroups = "tab",
        args = {
            configMode = {
                name = "Config Mode",
                desc = "Show dummy bars to visualize changes in real-time.",
                type = "toggle",
                order = 0,
                get = function() return self.state.isConfigMode end,
                set = function(_, val)
                    self.state.isConfigMode = val
                    self:UpdateDisplay()
                end,
            },
            general = {
                name = "Appearance",
                type = "group",
                order = 10,
                args = {
                    headerPos = { type = "header", name = "Position & Size", order = 1 },
                    yOffset = {
                        name = "Vertical Position (Y)",
                        type = "range",
                        min = -1080,
                        max = 0,
                        step = 1,
                        bigStep = 10,
                        order = 2,
                        get = function() return self.db.profile.yOffset end,
                        set = function(_, v)
                            self.db.profile.yOffset = v
                            self:UpdateDisplay()
                        end,
                    },
                    barHeightXP = {
                        name = "XP Bar Height",
                        type = "range",
                        min = CONSTANTS.MIN_BAR_HEIGHT,
                        max = CONSTANTS.MAX_BAR_HEIGHT,
                        step = 1,
                        order = 3,
                        get = function() return self.db.profile.barHeightXP end,
                        set = function(_, v)
                            self.db.profile.barHeightXP = v
                            self:UpdateDisplay()
                        end,
                    },
                    barHeightRep = {
                        name = "Reputation Bar Height",
                        type = "range",
                        min = CONSTANTS.MIN_BAR_HEIGHT,
                        max = CONSTANTS.MAX_BAR_HEIGHT,
                        step = 1,
                        order = 4,
                        get = function() return self.db.profile.barHeightRep end,
                        set = function(_, v)
                            self.db.profile.barHeightRep = v
                            self:UpdateDisplay()
                        end,
                    },
                    textSize = {
                        name = "Font Size",
                        type = "range",
                        min = CONSTANTS.MIN_TEXT_SIZE,
                        max = CONSTANTS.MAX_TEXT_SIZE,
                        step = 1,
                        order = 5,
                        get = function() return self.db.profile.textSize end,
                        set = function(_, v)
                            self.db.profile.textSize = v
                            self:UpdateDisplay()
                        end,
                    },
                    globalColor = {
                        name = "Text Color",
                        type = "color",
                        hasAlpha = true,
                        order = 6,
                        get = function()
                            local t = self.db.profile.textColor
                            return t.r, t.g, t.b, t.a
                        end,
                        set = function(_, r, g, b, a)
                            local t = self.db.profile.textColor
                            t.r, t.g, t.b, t.a = r, g, b, a
                            self:UpdateDisplay()
                        end,
                    },
                }
            },
            behavior = {
                name = "Visibility",
                type = "group",
                order = 20,
                args = {
                    showOnMouseover = {
                        name = "Show on Mouseover",
                        type = "toggle",
                        order = 1,
                        get = function() return self.db.profile.showOnMouseover end,
                        set = function(_, v)
                            self.db.profile.showOnMouseover = v
                            self:UpdateDisplay()
                        end,
                    },
                    hideInCombat = {
                        name = "Hide in Combat",
                        type = "toggle",
                        order = 2,
                        get = function() return self.db.profile.hideInCombat end,
                        set = function(_, v)
                            self.db.profile.hideInCombat = v
                            self:UpdateDisplay()
                        end,
                    },
                }
            },
            colors = {
                name = "Colors",
                type = "group",
                order = 30,
                args = {
                    headerXP = { type = "header", name = "Experience", order = 1 },
                    useClassColorXP = {
                        name = "Use Class Color",
                        type = "toggle",
                        order = 2,
                        width = "full",
                        get = function() return self.db.profile.useClassColorXP end,
                        set = function(_, v)
                            self.db.profile.useClassColorXP = v
                            self:UpdateDisplay()
                        end,
                    },
                    xpBarColor = {
                        name = "Custom XP Color",
                        type = "color",
                        hasAlpha = true,
                        order = 3,
                        disabled = function() return self.db.profile.useClassColorXP end,
                        get = function()
                            local c = self.db.profile.xpBarColor
                            return c.r, c.g, c.b, c.a
                        end,
                        set = function(_, r, g, b, a)
                            local c = self.db.profile.xpBarColor
                            c.r, c.g, c.b, c.a = r, g, b, a
                            self:UpdateDisplay()
                        end,
                    },
                    showRestedBar = {
                        name = "Show Rested Bar",
                        type = "toggle",
                        order = 4,
                        get = function() return self.db.profile.showRestedBar end,
                        set = function(_, v)
                            self.db.profile.showRestedBar = v
                            self:UpdateDisplay()
                        end,
                    },
                    restedBarColor = {
                        name = "Rested Color",
                        type = "color",
                        hasAlpha = true,
                        order = 5,
                        disabled = function() return not self.db.profile.showRestedBar end,
                        get = function()
                            local c = self.db.profile.restedBarColor
                            return c.r, c.g, c.b, c.a
                        end,
                        set = function(_, r, g, b, a)
                            local c = self.db.profile.restedBarColor
                            c.r, c.g, c.b, c.a = r, g, b, a
                            self:UpdateDisplay()
                        end,
                    },
                    headerRep = { type = "header", name = "Reputation", order = 10 },
                    useReactionColorRep = {
                        name = "Use Reaction Colors",
                        type = "toggle",
                        order = 11,
                        width = "full",
                        get = function() return self.db.profile.useReactionColorRep end,
                        set = function(_, v)
                            self.db.profile.useReactionColorRep = v
                            self:UpdateDisplay()
                        end,
                    },
                    repBarColor = {
                        name = "Custom Rep Color",
                        type = "color",
                        hasAlpha = true,
                        order = 12,
                        disabled = function() return self.db.profile.useReactionColorRep end,
                        get = function()
                            local c = self.db.profile.repBarColor
                            return c.r, c.g, c.b, c.a
                        end,
                        set = function(_, r, g, b, a)
                            local c = self.db.profile.repBarColor
                            c.r, c.g, c.b, c.a = r, g, b, a
                            self:UpdateDisplay()
                        end,
                    },
                }
            },
            paragonSettings = {
                name = "Paragon Alerts",
                type = "group",
                order = 40,
                args = {
                    paragonOnTop = {
                        name = "Show on Top",
                        type = "toggle",
                        order = 1,
                        get = function() return self.db.profile.paragonOnTop end,
                        set = function(_, v)
                            self.db.profile.paragonOnTop = v
                            self:UpdateDisplay()
                        end,
                    },
                    split = {
                        name = "Split Lines",
                        type = "toggle",
                        order = 2,
                        get = function() return self.db.profile.splitParagonText end,
                        set = function(_, v)
                            self.db.profile.splitParagonText = v
                            self:UpdateDisplay()
                        end,
                    },
                    paragonTextSize = {
                        name = "Text Size",
                        type = "range",
                        min = 10,
                        max = 40,
                        step = 1,
                        order = 3,
                        get = function() return self.db.profile.paragonTextSize end,
                        set = function(_, v)
                            self.db.profile.paragonTextSize = v
                            self:UpdateDisplay()
                        end,
                    },
                    paragonTextYOffset = {
                        name = "Vertical Offset (Y)",
                        type = "range",
                        min = -1000,
                        max = 500,
                        step = 5,
                        order = 4,
                        get = function() return self.db.profile.paragonTextYOffset end,
                        set = function(_, v)
                            self.db.profile.paragonTextYOffset = v
                            self:UpdateDisplay()
                        end,
                    },
                    pColor = {
                        name = "Alert Color",
                        type = "color",
                        order = 5,
                        get = function()
                            local c = self.db.profile.paragonPendingColor
                            return c.r, c.g, c.b
                        end,
                        set = function(_, r, g, b)
                            local c = self.db.profile.paragonPendingColor
                            c.r, c.g, c.b = r, g, b
                            self:UpdateDisplay()
                        end,
                    },
                }
            },
            standingColors = {
                name = "Faction Colors",
                type = "group",
                order = 50,
                args = {}
            },
            advanced = {
                name = "Advanced",
                type = "group",
                order = 60,
                args = {
                    showPercentage = {
                        name = "Show Percentage",
                        type = "toggle",
                        order = 1,
                        get = function() return self.db.profile.showPercentage end,
                        set = function(_, v)
                            self.db.profile.showPercentage = v
                            self:UpdateDisplay()
                        end,
                    },
                    showAbsoluteValues = {
                        name = "Show Absolute Values",
                        type = "toggle",
                        order = 2,
                        get = function() return self.db.profile.showAbsoluteValues end,
                        set = function(_, v)
                            self.db.profile.showAbsoluteValues = v
                            self:UpdateDisplay()
                        end,
                    },
                    sparkEnabled = {
                        name = "Show Spark",
                        type = "toggle",
                        order = 3,
                        get = function() return self.db.profile.sparkEnabled end,
                        set = function(_, v)
                            self.db.profile.sparkEnabled = v
                            self:UpdateDisplay()
                        end,
                    },
                    debugMode = {
                        name = "Debug Mode",
                        desc = "Enable debug output in chat",
                        type = "toggle",
                        order = 10,
                        get = function() return self.db.profile.debugMode end,
                        set = function(_, v)
                            self.db.profile.debugMode = v
                            self:ToggleDebugMode()
                        end,
                    },
                }
            },
        }
    }

    local labels = {
        "1. Hated", "2. Hostile", "3. Unfriendly", "4. Neutral", "5. Friendly",
        "6. Honored", "7. Revered", "8. Exalted", "9. Paragon", "10. Maxed", "11. Renown"
    }

    for i = 1, 11 do
        options.args.standingColors.args["rank" .. i] = {
            name = labels[i],
            type = "color",
            hasAlpha = true,
            order = i,
            get = function()
                local c = self.db.profile.repColors[i]
                return c.r, c.g, c.b, c.a
            end,
            set = function(_, r, g, b, a)
                local c = self.db.profile.repColors[i]
                c.r, c.g, c.b, c.a = r, g, b, a
                self:UpdateDisplay()
            end,
        }
    end

    return options
end

-- ==========================================================
-- 3. INITIALIZATION
-- ==========================================================
function AB:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("AscensionBarsDB", defaults, true)
    LibStub("AceConfig-3.0"):RegisterOptionsTable(ADDON_NAME, self:GetOptionsTable())
    self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(ADDON_NAME, "Ascension Bars")

    self:RegisterChatCommand("ab", function()
        Settings.OpenToCategory(self.optionsFrame.name)
    end)

    self:RegisterChatCommand("abdebug", function()
        self.db.profile.debugMode = not self.db.profile.debugMode
        self:ToggleDebugMode()
        print("AscensionBars: Debug mode " .. (self.db.profile.debugMode and "enabled" or "disabled"))
    end)

    self.state = {
        lastParagonScanTime = 0,
        cachedPendingParagons = {},
        cachedClassColor = nil,
        isConfigMode = false,
        inCombat = false,
        isHovering = false,
        debugMode = false,
        eventHandlers = {},
    }

    self.FONT_TO_USE = GameFontNormal:GetFont() or "Fonts\\FRIZQT__.TTF"

    self:CreateFrames()
end

function AB:OnEnable()
    self:RegisterEvent("PLAYER_XP_UPDATE", "UpdateDisplay")
    self:RegisterEvent("UPDATE_EXHAUSTION", "UpdateDisplay")
    self:RegisterEvent("PLAYER_LEVEL_UP", "UpdateDisplay")
    self:RegisterEvent("UPDATE_FACTION", "OnUpdateFaction")
    self:RegisterEvent("PLAYER_REGEN_DISABLED", "OnCombatStart")
    self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnCombatEnd")
    self:RegisterEvent("QUEST_TURNED_IN", "OnQuestTurnIn")

    self:HideBlizzardFrames()
    self:ScanParagonRewards()
    self:UpdateDisplay()

    -- Initialize debug mode if enabled
    if self.db.profile.debugMode then
        self:ToggleDebugMode()
    end
end

-- ==========================================================
-- 4. FRAME CREATION
-- ==========================================================
function AB:CreateFrames()
    self.textHolder = CreateFrame("Frame", "AscensionBars_TextHolder", UIParent)
    self.textHolder:SetFrameStrata("HIGH")
    self.textHolder:SetClipsChildren(false)
    self.textHolder:SetHeight(20)

    self.HoverFrame = CreateFrame("Frame", "AscensionBars_HoverFrame", UIParent)
    self.HoverFrame:SetFrameStrata("BACKGROUND")
    self.HoverFrame:EnableMouse(true)
    self.HoverFrame:SetScript("OnEnter", function()
        self.state.isHovering = true
        self:UpdateVisibility()
    end)
    self.HoverFrame:SetScript("OnLeave", function()
        self.state.isHovering = false
        self:UpdateVisibility()
    end)

    self.XP = self:CreateBar("AscensionXPBar_XP")
    self.Rep = self:CreateBar("AscensionXPBar_Rep")
    self.paragonText = self.textHolder:CreateFontString(nil, "OVERLAY", "GameFontNormal")
end

function AB:CreateBar(name)
    local bar = CreateFrame("StatusBar", name, UIParent)
    bar:SetFrameStrata("LOW")
    bar:SetStatusBarTexture(CONSTANTS.TEXTURE_BAR)
    bar:SetClipsChildren(true)

    -- Use texture pool for background
    local bg = self:AcquireTexture(bar)
    bg:SetAllPoints(true)
    bg:SetTexture(CONSTANTS.TEXTURE_BAR)
    bg:SetVertexColor(0, 0, 0, self.db.profile.backgroundAlpha or 0.5)
    bg:SetDrawLayer("BACKGROUND", -1)

    local spark = bar:CreateTexture(nil, "ARTWORK")
    spark:SetTexture(CONSTANTS.TEXTURE_SPARK)
    spark:SetSize(6, 6)
    spark:SetBlendMode("ADD")

    local rested = (name == "AscensionXPBar_XP") and bar:CreateTexture(nil, "ARTWORK") or nil

    local txFrame = CreateFrame("Frame", nil, self.textHolder)
    local text = txFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetAllPoints(true)

    return {
        bar = bar,
        spark = spark,
        txFrame = txFrame,
        text = text,
        restedOverlay = rested,
        background = bg
    }
end

-- ==========================================================
-- 5. UTILITY FUNCTIONS
-- ==========================================================
function AB:GetClassColor()
    if not self.state.cachedClassColor then
        local class = select(2, UnitClass("player"))
        self.state.cachedClassColor = RAID_CLASS_COLORS[class] or { r = 1, g = 1, b = 1, a = 1 }
    end
    return self.state.cachedClassColor
end

function AB:AcquireTexture(parent)
    for i = 1, #texturePool do
        if not texturePool[i]:IsShown() and texturePool[i]:GetParent() == parent then
            texturePool[i]:Show()
            return texturePool[i]
        end
    end
    local tex = parent:CreateTexture(nil, "BACKGROUND")
    table.insert(texturePool, tex)
    return tex
end

function AB:DebugPrint(msg)
    if self.db.profile.debugMode then
        print("AscensionBars: " .. msg)
    end
end

function AB:ToggleDebugMode()
    if self.db.profile.debugMode then
        self:DebugPrint("Debug mode enabled")
        -- You can add more debug features here
    else
        self:DebugPrint("Debug mode disabled")
    end
end

-- ==========================================================
-- 6. RENDER LOGIC
-- ==========================================================
function AB:UpdateTextAnchors(factionName, isMaxLevel)
    local profile = self.db.profile
    local effectiveMax = isMaxLevel and not self.state.isConfigMode
    local gap = CONSTANTS.DEFAULT_GAP

    self.XP.txFrame:ClearAllPoints()
    self.Rep.txFrame:ClearAllPoints()
    self.textHolder:ClearAllPoints()
    self.textHolder:SetPoint("TOP", UIParent, "TOP", 0, profile.yOffset - 13.5)

    local w1 = self.XP.text:GetStringWidth() + 5
    local w2 = self.Rep.text:GetStringWidth() + 5
    if w1 < 10 then w1 = CONSTANTS.MIN_TEXT_WIDTH end
    if w2 < 10 then w2 = CONSTANTS.MIN_TEXT_WIDTH end

    if effectiveMax or (not self.state.isConfigMode and not factionName) then
        -- Single bar mode (Max Level or no reputation)
        local target = (effectiveMax and factionName) and self.Rep or self.XP
        self.textHolder:SetWidth(target == self.Rep and w2 or w1)
        target.txFrame:SetAllPoints(self.textHolder)
        target.text:SetJustifyH("CENTER")
    else
        -- Divided bar mode (Config or Leveling)
        self.textHolder:SetWidth(w1 + gap + w2)

        self.XP.txFrame:SetPoint("LEFT", self.textHolder, "LEFT")
        self.XP.txFrame:SetPoint("TOP", self.textHolder, "TOP")
        self.XP.txFrame:SetPoint("BOTTOM", self.textHolder, "BOTTOM")
        self.XP.txFrame:SetWidth(w1)
        self.XP.text:SetJustifyH("LEFT")

        self.Rep.txFrame:SetPoint("LEFT", self.XP.txFrame, "RIGHT", gap, 0)
        self.Rep.txFrame:SetPoint("TOP", self.textHolder, "TOP")
        self.Rep.txFrame:SetPoint("BOTTOM", self.textHolder, "BOTTOM")
        self.Rep.txFrame:SetWidth(w2)
        self.Rep.text:SetJustifyH("LEFT")
    end
end

function AB:UpdateDisplay()
    local now = GetTime()
    if now - lastUpdate < CONSTANTS.UPDATE_THROTTLE and not self.state.isConfigMode then
        return
    end
    lastUpdate = now

    self:DebugPrint("UpdateDisplay called")

    local profile = self.db.profile
    local isMax = UnitLevel("player") >= GetMaxPlayerLevel()

    self:UpdateLayout(isMax)
    self:UpdateVisibility()

    if self.state.isConfigMode then
        self:RenderConfig()
        return
    end

    if not isMax then
        local cur, mx = UnitXP("player"), UnitXPMax("player")
        local color = profile.useClassColorXP and self:GetClassColor() or profile.xpBarColor
        self.XP.bar:SetStatusBarColor(color.r, color.g, color.b, 1.0)
        self.XP.bar:SetMinMaxValues(0, mx)
        self.XP.bar:SetValue(cur)

        if profile.sparkEnabled then
            local pct = (mx > 0) and (cur / mx) or 0
            self.XP.spark:SetPoint("CENTER", self.XP.bar, "LEFT", self.XP.bar:GetWidth() * pct, 0)
            self.XP.spark:Show()
        else
            self.XP.spark:Hide()
        end

        if profile.showRestedBar then
            local rested = GetXPExhaustion()
            if rested and rested > 0 then
                local rw = self.XP.bar:GetWidth() * (math.min(cur + rested, mx) / mx)
                self.XP.restedOverlay:SetSize(rw, profile.barHeightXP)
                self.XP.restedOverlay:SetPoint("LEFT", self.XP.bar, "LEFT")
                self.XP.restedOverlay:SetColorTexture(
                    profile.restedBarColor.r,
                    profile.restedBarColor.g,
                    profile.restedBarColor.b,
                    profile.restedBarColor.a
                )
                self.XP.restedOverlay:Show()
            else
                if self.XP.restedOverlay then
                    self.XP.restedOverlay:Hide()
                end
            end
        end
        self.XP.text:SetText(self:FormatXP())
    end

    local name = self:RenderReputation()
    self:UpdateTextAnchors(name, isMax)
end

function AB:RenderReputation()
    local profile = self.db.profile
    local name, reaction, min, max, value, factionID, standingLabel
    local p = self.state.cachedPendingParagons

    if #p > 0 then
        local pc = profile.paragonPendingColor
        local hex = string.format("|cff%02x%02x%02x",
            math.floor((pc.r or 0) * 255),
            math.floor((pc.g or 1) * 255),
            math.floor((pc.b or 0) * 255)
        )

        local text = ""
        if profile.splitParagonText then
            local lines = {}
            for _, info in ipairs(p) do
                table.insert(lines, hex .. string.upper(info.name) .. " REWARD PENDING!|r")
            end
            text = table.concat(lines, "\n")
        else
            local names = {}
            for _, info in ipairs(p) do
                table.insert(names, string.upper(info.name))
            end
            local factionStr = ""
            if #names == 1 then
                factionStr = names[1]
            elseif #names == 2 then
                factionStr = names[1] .. " AND " .. names[2]
            else
                local last = table.remove(names)
                factionStr = table.concat(names, ", ") .. " AND " .. last
            end
            text = hex .. factionStr .. " REWARD" .. (#p > 1 and "S" or "") .. " PENDING!|r"
        end

        self.paragonText:SetFont(self.FONT_TO_USE, profile.paragonTextSize, "OUTLINE, THICK")
        self.paragonText:SetText(text)
        self.paragonText:Show()
        self.paragonText:ClearAllPoints()
        if profile.paragonOnTop then
            self.paragonText:SetPoint("TOP", UIParent, "TOP", 0, profile.paragonTextYOffset)
        else
            self.paragonText:SetPoint("TOP", self.textHolder, "BOTTOM", 0, profile.paragonTextYOffset)
        end

        name, reaction, min, max, value, standingLabel = p[1].name, 9, 0, 1, 1, "Reward Pending"
    else
        self.paragonText:Hide()
        local data = C_Reputation.GetWatchedFactionData()
        if data then
            name, reaction, factionID = data.name, data.reaction, data.factionID
            min, max, value = data.currentReactionThreshold, data.nextReactionThreshold, data.currentStanding
            if C_Reputation.IsFactionParagon(factionID) then
                local cv, th = C_Reputation.GetFactionParagonInfo(factionID)
                min, max, value, standingLabel, reaction = 0, th, cv % th, "Paragon", 9
            elseif C_Reputation.IsMajorFaction(factionID) then
                local md = C_MajorFactions.GetMajorFactionData(factionID)
                min, max, value, standingLabel, reaction = 0, md.renownLevelThreshold,
                    md.renownReputationEarned, "Renown " .. md.renownLevel, 11
            else
                standingLabel = _G["FACTION_STANDING_LABEL" .. reaction] or "???"
            end
        end
    end

    if name then
        self.Rep.bar:Show()
        self.Rep.txFrame:Show()
        local color = profile.useReactionColorRep and profile.repColors[reaction] or profile.repBarColor
        self.Rep.bar:SetStatusBarColor(color.r, color.g, color.b, color.a or 1.0)
        self.Rep.bar:SetMinMaxValues(min, max)
        self.Rep.bar:SetValue(value)

        if profile.sparkEnabled then
            local pct = (max - min > 0) and (value - min) / (max - min) or 0
            self.Rep.spark:SetPoint("CENTER", self.Rep.bar, "LEFT", self.Rep.bar:GetWidth() * pct, 0)
            self.Rep.spark:Show()
        else
            self.Rep.spark:Hide()
        end

        local pct = (max - min > 0) and ((value - min) / (max - min) * 100) or 0
        local valueStr = BreakUpLargeNumbers(value - min)
        local maxStr = BreakUpLargeNumbers(max - min)

        if profile.showAbsoluteValues and profile.showPercentage then
            self.Rep.text:SetText(string.format("%s (%s) %s/%s (%.1f%%)",
                name, standingLabel, valueStr, maxStr, pct))
        elseif profile.showAbsoluteValues then
            self.Rep.text:SetText(string.format("%s (%s) %s/%s",
                name, standingLabel, valueStr, maxStr))
        elseif profile.showPercentage then
            self.Rep.text:SetText(string.format("%s (%s) %.1f%%",
                name, standingLabel, pct))
        else
            self.Rep.text:SetText(string.format("%s (%s)", name, standingLabel))
        end
    else
        self.Rep.bar:Hide()
        self.Rep.txFrame:Hide()
    end
    return name
end

-- ==========================================================
-- 7. VISUALIZATION - CONFIG MODE
-- ==========================================================
function AB:RenderConfig()
    self.textHolder:Show()
    self.textHolder:SetAlpha(1)
    self.textHolder:SetFrameStrata("HIGH")

    local profile = self.db.profile
    local tc = profile.textColor

    -- XP BAR
    self.XP.bar:Show()
    self.XP.txFrame:Show()
    local xc = profile.useClassColorXP and self:GetClassColor() or profile.xpBarColor
    self.XP.bar:SetStatusBarColor(xc.r, xc.g, xc.b, 1)
    self.XP.bar:SetMinMaxValues(0, 100)
    self.XP.bar:SetValue(75)

    self.XP.text:SetText("experience information")
    self.XP.text:SetTextColor(tc.r, tc.g, tc.b, 1)

    if profile.showRestedBar then
        local w = self.XP.bar:GetWidth()
        if self.XP.restedOverlay then
            self.XP.restedOverlay:SetSize(w * 0.25, profile.barHeightXP)
            self.XP.restedOverlay:ClearAllPoints()
            self.XP.restedOverlay:SetPoint("LEFT", self.XP.bar, "LEFT", w * 0.75, 0)
            self.XP.restedOverlay:SetColorTexture(
                profile.restedBarColor.r,
                profile.restedBarColor.g,
                profile.restedBarColor.b,
                profile.restedBarColor.a
            )
            self.XP.restedOverlay:Show()
        end
    else
        if self.XP.restedOverlay then
            self.XP.restedOverlay:Hide()
        end
    end

    -- REPUTATION BAR
    self.Rep.bar:Show()
    self.Rep.txFrame:Show()
    local rc = profile.useReactionColorRep and profile.repColors[9] or profile.repBarColor
    self.Rep.bar:SetStatusBarColor(rc.r, rc.g, rc.b, 1)
    self.Rep.bar:SetMinMaxValues(0, 100)
    self.Rep.bar:SetValue(50)

    self.Rep.text:SetText("reputation information")
    self.Rep.text:SetTextColor(tc.r, tc.g, tc.b, 1)

    -- PARAGON TEXT
    local pc = profile.paragonPendingColor
    local hex = string.format("|cff%02x%02x%02x",
        math.floor((pc.r or 0) * 255),
        math.floor((pc.g or 1) * 255),
        math.floor((pc.b or 0) * 255)
    )
    self.paragonText:SetFont(self.FONT_TO_USE, profile.paragonTextSize, "OUTLINE, THICK")

    if profile.splitParagonText then
        self.paragonText:SetText(hex .. "[CONFIG] FACTION A REWARD|r\n" .. hex .. "[CONFIG] FACTION B REWARD|r")
    else
        self.paragonText:SetText(hex .. "[CONFIG] MULTIPLE REWARDS PENDING!|r")
    end

    self.paragonText:Show()
    self.paragonText:ClearAllPoints()
    if profile.paragonOnTop then
        self.paragonText:SetPoint("TOP", UIParent, "TOP", 0, profile.paragonTextYOffset)
    else
        self.paragonText:SetPoint("TOP", self.textHolder, "BOTTOM", 0, profile.paragonTextYOffset)
    end

    self:UpdateTextAnchors("Config", false)
end

-- ==========================================================
-- 8. LAYOUT & SYSTEM
-- ==========================================================
function AB:UpdateLayout(isMax)
    local profile = self.db.profile
    local effectiveMax = isMax and not self.state.isConfigMode

    self.XP.bar:SetHeight(profile.barHeightXP)
    self.Rep.bar:SetHeight(profile.barHeightRep)

    local font, _, flags = self.XP.text:GetFont()
    local outline = profile.fontOutline or "OUTLINE"
    self.XP.text:SetFont(font, profile.textSize, outline)
    self.Rep.text:SetFont(font, profile.textSize, outline)

    local tc = profile.textColor
    self.XP.text:SetTextColor(tc.r, tc.g, tc.b, tc.a)
    self.Rep.text:SetTextColor(tc.r, tc.g, tc.b, tc.a)

    -- Update background alpha
    if self.XP.background then
        self.XP.background:SetVertexColor(0, 0, 0, profile.backgroundAlpha)
    end
    if self.Rep.background then
        self.Rep.background:SetVertexColor(0, 0, 0, profile.backgroundAlpha)
    end

    local startY = profile.yOffset
    self.XP.bar:ClearAllPoints()
    self.Rep.bar:ClearAllPoints()

    if effectiveMax then
        self.XP.bar:Hide()
        self.XP.txFrame:Hide()
        self.Rep.bar:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, startY)
        self.Rep.bar:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", 0, startY)
    else
        self.XP.bar:Show()
        self.XP.txFrame:Show()
        self.XP.bar:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, startY)
        self.XP.bar:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", 0, startY)
        self.Rep.bar:SetPoint("TOPLEFT", self.XP.bar, "BOTTOMLEFT", 0, -profile.barGap)
        self.Rep.bar:SetPoint("TOPRIGHT", self.XP.bar, "BOTTOMRIGHT", 0, -profile.barGap)
    end
end

function AB:UpdateVisibility()
    local alpha = 1
    if not self.state.isConfigMode then
        if self.db.profile.hideInCombat and self.state.inCombat then
            alpha = 0
        elseif self.db.profile.showOnMouseover and not self.state.isHovering then
            alpha = 0
        end
    end
    self.XP.bar:SetAlpha(alpha)
    self.Rep.bar:SetAlpha(alpha)
    self.textHolder:SetAlpha(alpha)
end

function AB:HideBlizzardFrames()
    local frames = {
        MainMenuExpBar,
        MainMenuBarMaxLevelBar,
        ReputationWatchBar,
        StatusTrackingBarManager
    }
    for _, frame in pairs(frames) do
        if frame then
            frame:UnregisterAllEvents()
            frame:Hide()
            frame.Show = function() end
        end
    end
end

function AB:FormatXP()
    local c, m = UnitXP("player"), UnitXPMax("player")
    local pct = (m > 0 and c / m * 100) or 0
    local profile = self.db.profile

    local txt = ""
    if profile.showAbsoluteValues then
        txt = string.format("Level %d | %s/%s",
            UnitLevel("player"),
            BreakUpLargeNumbers(c),
            BreakUpLargeNumbers(m))
        if profile.showPercentage then
            txt = txt .. string.format(" (%.1f%%)", pct)
        end
    elseif profile.showPercentage then
        txt = string.format("Level %d | %.1f%%", UnitLevel("player"), pct)
    else
        txt = string.format("Level %d", UnitLevel("player"))
    end

    local r = GetXPExhaustion()
    if r and r > 0 then
        txt = txt .. string.format(" | Rested %.1f%%", (m > 0 and r / m * 100) or 0)
    end
    return txt
end

-- ==========================================================
-- 9. EVENT HANDLERS
-- ==========================================================
function AB:OnUpdateFaction()
    self:ScanParagonRewards()
    self:UpdateDisplay()
end

function AB:OnCombatStart()
    self.state.inCombat = true
    self:DebugPrint("Combat started")
    self:UpdateVisibility()
end

function AB:OnCombatEnd()
    self.state.inCombat = false
    self:DebugPrint("Combat ended")
    self:UpdateVisibility()
end

function AB:OnQuestTurnIn()
    C_Timer.After(1, function()
        self:ScanParagonRewards()
    end)
end

-- ==========================================================
-- 10. PARAGON FUNCTIONS
-- ==========================================================
function AB:ScanParagonRewards()
    local pending = {}
    for i = 1, C_Reputation.GetNumFactions() do
        local d = C_Reputation.GetFactionDataByIndex(i)
        if d and d.factionID and C_Reputation.IsFactionParagon(d.factionID) then
            local _, _, _, hasRewardPending = C_Reputation.GetFactionParagonInfo(d.factionID)
            if hasRewardPending then
                table.insert(pending, { name = d.name })
            end
        end
    end
    self.state.cachedPendingParagons = pending
    self:UpdateDisplay()
end

-- ==========================================================
-- 11. EXTRA UTILITY FUNCTIONS (Optional features)
-- ==========================================================
function AB:AddTooltip(bar, text)
    if not bar or not text then return end

    bar:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
        GameTooltip:SetText(text)
        GameTooltip:Show()
    end)

    bar:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

function AB:LoadPreset(presetName)
    local presets = {
        minimal = {
            barHeightXP = 3,
            barHeightRep = 3,
            textSize = 10,
            showOnMouseover = true,
            showRestedBar = false,
        },
        detailed = {
            barHeightXP = 8,
            barHeightRep = 8,
            textSize = 14,
            showRestedBar = true,
            showAbsoluteValues = true,
            showPercentage = true,
        },
        classic = {
            useClassColorXP = true,
            useReactionColorRep = true,
            barHeightXP = 5,
            barHeightRep = 5,
            textSize = 12,
        }
    }

    if presets[presetName] then
        for k, v in pairs(presets[presetName]) do
            self.db.profile[k] = v
        end
        self:UpdateDisplay()
        self:DebugPrint("Loaded preset: " .. presetName)
    else
        self:DebugPrint("Unknown preset: " .. presetName)
    end
end

-- ==========================================================
-- 12. CLEANUP ON DISABLE
-- ==========================================================
function AB:OnDisable()
    -- Clean up textures from pool
    for i = 1, #texturePool do
        texturePool[i]:Hide()
    end

    -- Reset frames to default state
    self.XP.bar:Hide()
    self.Rep.bar:Hide()
    self.textHolder:Hide()

    self:DebugPrint("Addon disabled")
end
