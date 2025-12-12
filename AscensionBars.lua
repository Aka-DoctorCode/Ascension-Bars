-- =========================================================================
-- 1. CONFIGURACIÓN Y VALORES POR DEFECTO
-- =========================================================================
local ADDON_NAME = "AscensionBars"

-- Valores iniciales
local DEFAULTS = {
    -- Dimensiones
    barHeightXP = 5,
    barHeightRep = 6,
    textHeight = 15,
    yOffset = -2,
    
    -- Texto Paragon
    paragonTextSize = 14,
    paragonTextYOffset = -100, 
    paragonOnTop = true,
    splitParagonText = false, 
    paragonTextGap = 5,
    
    -- Visibilidad
    showOnMouseover = false,
    hideInCombat = false,

    -- Rendimiento
    paragonScanThrottle = 60,

    -- COLORES
    useClassColorXP = true,
    xpBarColor = {r=0.0, g=0.4, b=0.9, a=1.0},
    
    useReactionColorRep = true,
    repBarColor = {r=0.0, g=1.0, b=0.0, a=1.0},
    
    textColor = {r=1.0, g=1.0, b=1.0, a=1.0},
    
    -- RESTED XP
    showRestedBar = true,
    restedBarColor = {r=0.6, g=0.4, b=0.8, a=1.0},
}

-- Referencia a la base de datos activa
local db

-- Constantes Visuales
local CONSTANTS = {
    TEXTURE_BAR = "Interface\\Buttons\\WHITE8X8",
    TEXTURE_SPARK = "Interface\\CastingBar\\UI-CastingBar-Spark",
    COLOR_RESTED = {r=0.6, g=0.4, b=0.8, a=1.0},
    COLOR_PARAGON_PENDING = "|cFF00FF00",
    COLOR_CONFIG = {r=0.9, g=0.9, b=0.0, a=1.0}, 
}

-- Colores de Reputación
local REP_COLORS = {
    [1] = {r=0.8, g=0.133, b=0.133, a=1.0},   -- Hated
    [2] = {r=1.0, g=0.0, b=0.0, a=1.0},       -- Hostile
    [3] = {r=0.933, g=0.4, b=0.133, a=1.0},   -- Unfriendly
    [4] = {r=1.0, g=1.0, b=0.0, a=1.0},       -- Neutral
    [5] = {r=0.0, g=1.0, b=0.0, a=1.0},       -- Friendly
    [6] = {r=0.0, g=1.0, b=0.533, a=1.0},     -- Honored
    [7] = {r=0.0, g=1.0, b=0.8, a=1.0},       -- Revered
    [8] = {r=0.0, g=1.0, b=1.0, a=1.0},       -- Exalted
    [9] = {r=0.858, g=0.733, b=0.008, a=1.0}, -- Paragon
    [10] = {r=0.639, g=0.208, b=0.933, a=1.0}, -- Maxed
    [11] = {r=0.255, g=0.412, b=0.882, a=1.0}, -- Renown
}

-- Estado interno
local state = {
    lastParagonScanTime = 0,
    cachedPendingParagons = {},
    wasMaxLevel = nil, -- Ya no limitaremos la actualización con esto para evitar bugs visuales
    playerClassColor = RAID_CLASS_COLORS[select(2, UnitClass("player"))],
    isConfigMode = false,
    inCombat = false,
    isHovering = false 
}

-- Fuente
local standardFontPath = GameFontNormal:GetFont()
local FONT_TO_USE = standardFontPath or "Fonts\\FRIZQT__.TTF"

local coloredPipe = string.format("|cff%02x%02x%02x | |r",
    state.playerClassColor.r * 255, state.playerClassColor.g * 255, state.playerClassColor.b * 255)

-- Declaración anticipada
local UpdateDisplay, UpdateLayout, UpdateVisibility

-- =========================================================================
-- 2. PANEL DE OPCIONES
-- =========================================================================
local OptionsPanel = CreateFrame("Frame", "AscensionBarsOptions", UIParent)
OptionsPanel.name = "Ascension Bars"

--Helpers UI
local function CreateCheckbox(name, parent, labelText, onClick)
    local check = CreateFrame("CheckButton", name, parent, "ChatConfigCheckButtonTemplate")
    _G[name .. "Text"]:SetText(labelText)
    check:SetScript("OnClick", function(self)
        local isChecked = self:GetChecked()
        if onClick then onClick(isChecked) end
    end)
    return check
end

local function CreateSlider(name, parent, min, max, step, labelText, dbKey)
    local slider = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
    slider:SetMinMaxValues(min, max)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    slider:SetWidth(180)
    
    _G[name .. "Low"]:SetText(min)
    _G[name .. "High"]:SetText(max)
    _G[name .. "Text"]:SetText(labelText)
    
    local decBtn = CreateFrame("Button", name.."Dec", slider, "UIPanelButtonTemplate")
    decBtn:SetSize(20, 20)
    decBtn:SetText("-")
    decBtn:SetPoint("RIGHT", slider, "LEFT", -5, 0)
    decBtn:SetScript("OnClick", function()
        local val = slider:GetValue()
        slider:SetValue(val - step)
    end)
    
    local incBtn = CreateFrame("Button", name.."Inc", slider, "UIPanelButtonTemplate")
    incBtn:SetSize(20, 20)
    incBtn:SetText("+")
    incBtn:SetPoint("LEFT", slider, "RIGHT", 5, 0)
    incBtn:SetScript("OnClick", function()
        local val = slider:GetValue()
        slider:SetValue(val + step)
    end)
    
    local valueText = slider:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    valueText:SetPoint("LEFT", incBtn, "RIGHT", 10, 0)
    valueText:SetText(min) 
    
    slider:SetScript("OnValueChanged", function(self, value)
        valueText:SetText(string.format("%.0f", value))
        if db then 
            db[dbKey] = value
            -- Al mover sliders, forzamos actualización completa
            if UpdateDisplay then UpdateDisplay() end
        end
    end)
    slider:HookScript("OnShow", function(self)
        if db and db[dbKey] then
            self:SetValue(db[dbKey])
            valueText:SetText(string.format("%.0f", db[dbKey]))
        end
    end)
    return slider
end

local function CreateColorPicker(name, parent, labelText, dbKey, useAlpha)
    local frame = CreateFrame("Button", name, parent)
    frame:SetSize(20, 20)
    local swatch = frame:CreateTexture(nil, "OVERLAY")
    swatch:SetAllPoints()
    swatch:SetColorTexture(1, 1, 1)
    frame.swatch = swatch
    local label = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    label:SetPoint("LEFT", frame, "RIGHT", 10, 0)
    label:SetText(labelText)
    frame:SetScript("OnClick", function()
        if not db then return end
        local r, g, b, a = db[dbKey].r, db[dbKey].g, db[dbKey].b, db[dbKey].a or 1.0
        local info = {
            r = r, g = g, b = b, a = a,
            hasOpacity = useAlpha or false,
            swatchFunc = function()
                local nr, ng, nb = ColorPickerFrame:GetColorRGB()
                local na = ColorPickerFrame:GetColorAlpha()
                db[dbKey].r, db[dbKey].g, db[dbKey].b = nr, ng, nb
                if useAlpha then db[dbKey].a = na end
                swatch:SetColorTexture(nr, ng, nb, useAlpha and na or 1.0)
                if UpdateDisplay then UpdateDisplay() end
            end,
            cancelFunc = function()
                db[dbKey].r, db[dbKey].g, db[dbKey].b, db[dbKey].a = r, g, b, a
                swatch:SetColorTexture(r, g, b, useAlpha and a or 1.0)
                if UpdateDisplay then UpdateDisplay() end
            end,
        }
        ColorPickerFrame:SetupColorPickerAndShow(info)
    end)
    frame:HookScript("OnShow", function()
        if db and db[dbKey] then
            local a = db[dbKey].a or 1.0
            swatch:SetColorTexture(db[dbKey].r, db[dbKey].g, db[dbKey].b, useAlpha and a or 1.0)
        end
    end)
    return frame
end

local function InitOptionsPanel()
    local title = OptionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Ascension Bars Configuration")

    -- Scrollable content (panel may be larger than visible area)
    local scroll = CreateFrame("ScrollFrame", "AscensionBarsOptionsScrollFrame", OptionsPanel, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 16, -50)
    scroll:SetPoint("BOTTOMRIGHT", -30, 16)
    local content = CreateFrame("Frame", "AscensionBarsOptionsContent", scroll)
    content:SetSize(360, 720)
    scroll:SetScrollChild(content)

    -- 1. MODO CONFIG
    local chkConfig = CreateCheckbox("AscensionChkConfig", content, "|cFFFFD100Config Mode (Show All)|r", function(isChecked)
        state.isConfigMode = isChecked
        UpdateDisplay()
    end)
    chkConfig:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -16)

    -- 2. VISIBILIDAD
    local subVis = OptionsPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    subVis:SetPoint("TOPLEFT", chkConfig, "BOTTOMLEFT", 0, -10)
    subVis:SetText("Visibility Settings")

    local chkMouseover = CreateCheckbox("AscensionChkMouseover", content, "Show Only on Mouseover", function(isChecked)
        db.showOnMouseover = isChecked
        UpdateDisplay() -- Importante: UpdateDisplay llama a UpdateLayout y Visibility
    end)
    chkMouseover:SetPoint("TOPLEFT", subVis, "BOTTOMLEFT", 0, -10)

    local chkCombat = CreateCheckbox("AscensionChkCombat", content, "Hide in Combat", function(isChecked)
        db.hideInCombat = isChecked
        UpdateDisplay()
    end)
    chkCombat:SetPoint("LEFT", chkMouseover, "RIGHT", 200, 0)

    -- 3. DIMENSIONES Y POSICIÓN
    local subDim = OptionsPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    subDim:SetPoint("TOPLEFT", chkMouseover, "BOTTOMLEFT", 0, -20)
    subDim:SetText("Bar Size & Position")

    local sliderXP = CreateSlider("AscensionSliderXP", content, 1, 50, 1, "XP Height", "barHeightXP")
    sliderXP:SetPoint("TOPLEFT", subDim, "BOTTOMLEFT", 20, -20) 
    
    local sliderRep = CreateSlider("AscensionSliderRep", content, 1, 50, 1, "Reputation Height", "barHeightRep")
    sliderRep:SetPoint("TOPLEFT", sliderXP, "BOTTOMLEFT", 0, -30)

    local sliderY = CreateSlider("AscensionSliderY", content, -1080, 0, 1, "Bar Vertical Position (Y)", "yOffset")
    sliderY:SetPoint("TOPLEFT", sliderRep, "BOTTOMLEFT", 0, -30)

    -- 4. COLORES
    local subCol = OptionsPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    subCol:SetPoint("TOPLEFT", sliderY, "BOTTOMLEFT", -20, -20) 
    subCol:SetText("--- Colors & Text ---")

    local chkClassColor = CreateCheckbox("AscensionChkClassColor", content, "Use Class Color for XP", function(isChecked)
        db.useClassColorXP = isChecked
        UpdateDisplay()
    end)
    chkClassColor:SetPoint("TOPLEFT", subCol, "BOTTOMLEFT", 0, -10)
    
    local cpXP = CreateColorPicker("AscensionCPXP", content, "Custom XP Color", "xpBarColor", true)
    cpXP:SetPoint("LEFT", chkClassColor, "RIGHT", 160, 0)

    local chkReactColor = CreateCheckbox("AscensionChkReactColor", content, "Use Reaction Colors for Rep", function(isChecked)
        db.useReactionColorRep = isChecked
        UpdateDisplay()
    end)
    chkReactColor:SetPoint("TOPLEFT", chkClassColor, "BOTTOMLEFT", 0, -10)

    local cpRep = CreateColorPicker("AscensionCPRep", content, "Custom Rep Color", "repBarColor", true)
    cpRep:SetPoint("LEFT", chkReactColor, "RIGHT", 160, 0)

    local cpText = CreateColorPicker("AscensionCPText", content, "Text Color", "textColor", true)
    cpText:SetPoint("TOPLEFT", chkReactColor, "BOTTOMLEFT", 0, -15)

    -- 5. RESTED XP
    local subRested = OptionsPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    subRested:SetPoint("TOPLEFT", cpText, "BOTTOMLEFT", 0, -20)
    subRested:SetText("--- Rested XP Bar ---")
    
    local chkShowRested = CreateCheckbox("AscensionChkShowRested", content, "Show Rested XP Overlay", function(isChecked)
        db.showRestedBar = isChecked
        UpdateDisplay()
    end)
    chkShowRested:SetPoint("TOPLEFT", subRested, "BOTTOMLEFT", 0, -10)
    
    local cpRested = CreateColorPicker("AscensionCPRested", content, "Rested XP Color", "restedBarColor", true)
    cpRested:SetPoint("LEFT", chkShowRested, "RIGHT", 160, 0)

    -- 6. PARAGON TEXT
    local subPara = OptionsPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    subPara:SetPoint("TOPLEFT", chkShowRested, "BOTTOMLEFT", 0, -20)
    subPara:SetText("--- Paragon Reward Text ---")
    
    local chkParaTop = CreateCheckbox("AscensionChkParaTop", content, "Detach Text (Keep at Screen Top)", function(isChecked)
        db.paragonOnTop = isChecked
        UpdateDisplay() -- Forzar actualización al cambiar anclaje
    end)
    chkParaTop:SetPoint("TOPLEFT", subPara, "BOTTOMLEFT", 0, -10)
    
    local chkSplitText = CreateCheckbox("AscensionChkSplitText", content, "Show Separate Lines for Each Reward", function(isChecked)
        db.splitParagonText = isChecked
        UpdateDisplay()
    end)
    chkSplitText:SetPoint("LEFT", chkParaTop, "RIGHT", 200, 0)

    local sliderParaSize = CreateSlider("AscensionSliderParaSize", content, 8, 30, 1, "Text Size", "paragonTextSize")
    sliderParaSize:SetPoint("TOPLEFT", chkParaTop, "BOTTOMLEFT", 20, -20)

    local sliderTextGap = CreateSlider("AscensionSliderTextGap", content, 0, 50, 1, "Reward Text Spacing", "paragonTextGap")
    sliderTextGap:SetPoint("LEFT", sliderParaSize, "RIGHT", 100, 0) 

    local sliderParaY = CreateSlider("AscensionSliderParaY", content, -800, 50, 1, "Text Y Offset", "paragonTextYOffset")
    sliderParaY:SetPoint("TOPLEFT", sliderParaSize, "BOTTOMLEFT", 0, -30)
    
    OptionsPanel:HookScript("OnShow", function()
        chkConfig:SetChecked(state.isConfigMode)
        if db then
            chkClassColor:SetChecked(db.useClassColorXP)
            chkReactColor:SetChecked(db.useReactionColorRep)
            chkParaTop:SetChecked(db.paragonOnTop)
            chkSplitText:SetChecked(db.splitParagonText)
            chkMouseover:SetChecked(db.showOnMouseover)
            chkCombat:SetChecked(db.hideInCombat)
            chkShowRested:SetChecked(db.showRestedBar)
        end
    end)
end

if InterfaceOptions_AddOnCategory then
    InterfaceOptions_AddOnCategory(OptionsPanel)
else
    local category = Settings.RegisterCanvasLayoutCategory(OptionsPanel, "Ascension Bars")
    Settings.RegisterAddOnCategory(category)
end
InitOptionsPanel()

-- =========================================================================
-- 3. CREACIÓN DE FRAMES
-- =========================================================================

-- FRAME INVISIBLE PARA DETECTAR MOUSEOVER (Hitbox)
local HoverFrame = CreateFrame("Frame", "AscensionBars_HoverFrame", UIParent)
HoverFrame:SetFrameStrata("BACKGROUND") 
-- El HoverFrame debe recibir el ratón, pero las barras NO, para evitar conflictos
HoverFrame:EnableMouse(true)

local function CreateAscensionBar(name, color)
    local bar = CreateFrame("StatusBar", name, UIParent)
    bar:SetStatusBarTexture(CONSTANTS.TEXTURE_BAR)
    if color then
        bar:SetStatusBarColor(color.r, color.g, color.b, color.a or 1.0)
    end
    
    -- Desactivamos ratón en las barras visuales para que no "roben" el hover
    bar:EnableMouse(false)
    
    local spark = bar:CreateTexture(nil, "OVERLAY")
    spark:SetTexture(CONSTANTS.TEXTURE_SPARK)
    spark:SetSize(6, 6)
    spark:SetBlendMode("ADD")
    
    -- Overlay de Rested XP (para la barra XP solamente)
    local restedOverlay = nil
    if name == "AscensionXPBar_XP" then
        restedOverlay = bar:CreateTexture(nil, "ARTWORK")
        restedOverlay:SetTexture(CONSTANTS.TEXTURE_BAR)
        restedOverlay:SetAllPoints(bar)
        restedOverlay:Hide()
    end
    
    local txFrame = CreateFrame("Frame", name.."_TextFrame", UIParent)
    local text = txFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetFont(FONT_TO_USE, 12, "OUTLINE")
    text:SetAllPoints(true)
    
    return { bar = bar, spark = spark, txFrame = txFrame, text = text, restedOverlay = restedOverlay }
end

local XP = CreateAscensionBar("AscensionXPBar_XP", state.playerClassColor)
local Rep = CreateAscensionBar("AscensionXPBar_Rep", nil)

local textHolder = CreateFrame("Frame", "AscensionBars_TextHolder", UIParent)
textHolder:SetPoint("TOP", UIParent, "TOP", 0, -13.5)

local paragonText = textHolder:CreateFontString(nil, "OVERLAY", "GameFontNormal")
paragonText:SetFont(FONT_TO_USE, 14, "OUTLINE, THICK")
paragonText:SetPoint("TOP", textHolder, "BOTTOM", 0, -17)
paragonText:Hide()

-- =========================================================================
-- 4. LÓGICA CORE Y VISIBILIDAD
-- =========================================================================

local function SetGroupAlpha(alpha)
    XP.bar:SetAlpha(alpha)
    XP.txFrame:SetAlpha(alpha)
    Rep.bar:SetAlpha(alpha)
    Rep.txFrame:SetAlpha(alpha)
    paragonText:SetAlpha(alpha)
end

UpdateVisibility = function()
    if not db then return end

    -- 1. Si estamos en modo config, forzar visible
    if state.isConfigMode then
        SetGroupAlpha(1)
        return
    end

    -- 2. Combate tiene prioridad
    if db.hideInCombat and state.inCombat then
        SetGroupAlpha(0)
        return
    end

    -- 3. Mouseover
    if db.showOnMouseover then
        if state.isHovering then
            SetGroupAlpha(1)
        else
            SetGroupAlpha(0)
        end
    else
        -- Comportamiento normal (siempre visible)
        SetGroupAlpha(1)
    end
end

-- Scripts de Hover
HoverFrame:SetScript("OnEnter", function()
    state.isHovering = true
    UpdateVisibility()
end)
HoverFrame:SetScript("OnLeave", function()
    state.isHovering = false
    UpdateVisibility()
end)

local function HideBlizzardFrames()
    local framesToHide = {
        MainMenuExpBar, MainMenuBarMaxLevelBar, ReputationWatchBar,
        ReputationWatchStatusBar, ReputationWatchBarOverlayFrame, StatusTrackingBarManager
    }
    for _, frame in pairs(framesToHide) do
        if frame then
            if frame.UnregisterAllEvents then frame:UnregisterAllEvents() end
            frame:Hide()
            frame.Show = function() end
        end
    end
end

UpdateLayout = function(isMaxLevel)
    if not db then return end 

    local effectiveMaxLevel = isMaxLevel
    if state.isConfigMode then effectiveMaxLevel = false end

    XP.bar:SetHeight(db.barHeightXP)
    Rep.bar:SetHeight(db.barHeightRep)
    XP.txFrame:SetHeight(db.textHeight)
    Rep.txFrame:SetHeight(db.textHeight)
    textHolder:SetHeight(db.textHeight)
    
    paragonText:SetFont(FONT_TO_USE, db.paragonTextSize or 14, "OUTLINE, THICK")
    paragonText:SetSpacing(db.paragonTextGap or 5) 
    paragonText:ClearAllPoints()
    
    local textYOffset = db.paragonTextYOffset or -17
    if db.paragonOnTop then
        paragonText:SetPoint("TOP", UIParent, "TOP", 0, textYOffset)
    else
        paragonText:SetPoint("TOP", textHolder, "BOTTOM", 0, textYOffset)
    end

    if db.textColor then
        XP.text:SetTextColor(db.textColor.r, db.textColor.g, db.textColor.b, db.textColor.a or 1.0)
        Rep.text:SetTextColor(db.textColor.r, db.textColor.g, db.textColor.b, db.textColor.a or 1.0)
    end

    XP.bar:ClearAllPoints()
    Rep.bar:ClearAllPoints()
    XP.txFrame:ClearAllPoints()
    Rep.txFrame:ClearAllPoints()
    
    local startY = db.yOffset
    
    -- === POSICIONAMIENTO Y HITBOX ===
    if effectiveMaxLevel then
        XP.bar:Hide()
        XP.txFrame:Hide()
        Rep.bar:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, startY)
        Rep.bar:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", 0, startY)
        
        -- Ajustar Hitbox para cubrir Rep
        HoverFrame:ClearAllPoints()
        HoverFrame:SetPoint("TOPLEFT", Rep.bar, "TOPLEFT", 0, 10) 
        HoverFrame:SetPoint("BOTTOMRIGHT", Rep.bar, "BOTTOMRIGHT", 0, -10)
    else
        XP.bar:Show()
        XP.txFrame:Show()
        XP.bar:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, startY)
        XP.bar:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", 0, startY)
        
        local repOffset = startY - (db.barHeightXP + 2)
        Rep.bar:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, repOffset)
        Rep.bar:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", 0, repOffset)
        
        -- Ajustar Hitbox para cubrir XP y Rep
        HoverFrame:ClearAllPoints()
        HoverFrame:SetPoint("TOPLEFT", XP.bar, "TOPLEFT", 0, 10)
        HoverFrame:SetPoint("BOTTOMRIGHT", Rep.bar, "BOTTOMRIGHT", 0, -10)
    end
end

local function ScanParagonRewards()
    if not C_Reputation or not C_Reputation.GetNumFactions then 
        state.cachedPendingParagons = {}
        return 
    end
    local pending = {}
    local numFactions = C_Reputation.GetNumFactions()
    for i = 1, numFactions do
        local factionData = C_Reputation.GetFactionDataByIndex(i)
        if factionData and factionData.factionID and C_Reputation.IsFactionParagon(factionData.factionID) then
            local _, _, rewardQuestID, hasRewardPending = C_Reputation.GetFactionParagonInfo(factionData.factionID)
            if hasRewardPending and rewardQuestID and rewardQuestID > 0 then
                table.insert(pending, {name = factionData.name, id = factionData.factionID})
            end
        end
    end
    state.cachedPendingParagons = pending
    state.lastParagonScanTime = GetTime()
    UpdateDisplay()
end

local function FormatXP()
    local currentXP = UnitXP("player")
    local maxXP = UnitXPMax("player")
    local percent = (maxXP > 0) and (currentXP / maxXP * 100) or 0
    local baseText = string.format("Level %d%s%s/%s (%.1f%%)",
        UnitLevel("player"), coloredPipe, BreakUpLargeNumbers(currentXP), BreakUpLargeNumbers(maxXP), percent)
    
    local restedXP = GetXPExhaustion()
    if restedXP and restedXP > 0 then
        local restedPct = (maxXP > 0) and (restedXP / maxXP * 100) or 0
        if restedPct > 1 then
            return string.format("%s%sRested %.1f%%", baseText, coloredPipe, restedPct)
        end
    end
    return baseText
end

local function FormatRep(name, reaction, min, max, value, forcedLabel, isMaxed)
    local standingLabel = forcedLabel or (_G["FACTION_STANDING_LABEL"..reaction] or "??")
    if isMaxed then return string.format("%s (%s)", name, standingLabel) end
    local current, cap = value - min, max - min
    local percent = (cap > 0) and (current / cap * 100) or 0
    return string.format("%s (%s) %s/%s (%.1f%%)", name, standingLabel, BreakUpLargeNumbers(current), BreakUpLargeNumbers(cap), percent)
end

UpdateDisplay = function()
    if not db then return end
    
    -- XP Check
    local maxLvl = GetMaxPlayerLevel()
    local curLvl = UnitLevel("player")
    local isMax = (curLvl >= maxLvl)
    
    -- SIEMPRE actualizar Layout para evitar que se rompa al cambiar opciones
    -- Anteriormente teníamos 'if isMax ~= state.wasMaxLevel', eso causaba el bug.
    UpdateLayout(isMax)
    state.wasMaxLevel = isMax
    
    -- Aplicar reglas de visibilidad al final del renderizado
    UpdateVisibility()

    -- === MODO CONFIGURACIÓN ===
    if state.isConfigMode then
        -- En config mode sobrescribimos colores y textos, el layout ya se actualizó arriba
        local r, g, b
        if db.useClassColorXP then r,g,b = state.playerClassColor.r, state.playerClassColor.g, state.playerClassColor.b 
        else r,g,b = db.xpBarColor.r, db.xpBarColor.g, db.xpBarColor.b end
        
        XP.bar:SetStatusBarColor(r, g, b, db.xpBarColor.a or 1.0)
        XP.bar:SetMinMaxValues(0, 100); XP.bar:SetValue(75)
        XP.spark:SetPoint("CENTER", XP.bar, "LEFT", XP.bar:GetWidth() * 0.75, 0)
        XP.text:SetText("[CONFIG MODE] Level 80 XP BAR")
        XP.txFrame:SetWidth(XP.text:GetStringWidth() + 2)
        XP.bar:Show(); XP.txFrame:Show()
        
        -- Mostrar overlay de rested en config mode si está habilitado
        if db.showRestedBar and XP.restedOverlay then
            XP.restedOverlay:SetAllPoints(XP.bar)
            XP.restedOverlay:SetColorTexture(db.restedBarColor.r, db.restedBarColor.g, db.restedBarColor.b, db.restedBarColor.a or 0.5)
            -- Mostrar al 90% para visualizar
            local width = XP.bar:GetWidth()
            local height = XP.bar:GetHeight()
            XP.restedOverlay:SetSize(width * 0.9, height)
            XP.restedOverlay:SetPoint("LEFT", XP.bar, "LEFT", 0, 0)
            XP.restedOverlay:Show()
        elseif XP.restedOverlay then
            XP.restedOverlay:Hide()
        end

        if db.useReactionColorRep then r,g,b = CONSTANTS.COLOR_CONFIG.r, CONSTANTS.COLOR_CONFIG.g, CONSTANTS.COLOR_CONFIG.b
        else r,g,b = db.repBarColor.r, db.repBarColor.g, db.repBarColor.b end
        
        Rep.bar:SetStatusBarColor(r, g, b, db.repBarColor.a or 1.0)
        Rep.bar:SetMinMaxValues(0, 100); Rep.bar:SetValue(50)
        Rep.spark:SetPoint("CENTER", Rep.bar, "LEFT", Rep.bar:GetWidth() * 0.50, 0)
        Rep.text:SetText("[CONFIG MODE] REPUTATION BAR")
        Rep.txFrame:SetWidth(Rep.text:GetStringWidth() + 2)
        Rep.bar:Show(); Rep.txFrame:Show()
        
        local gap = 30
        textHolder:SetWidth(XP.txFrame:GetWidth() + gap + Rep.txFrame:GetWidth())
        textHolder:ClearAllPoints()
        textHolder:SetPoint("TOP", UIParent, "TOP", 0, db.yOffset - 13.5)
        XP.txFrame:ClearAllPoints()
        XP.txFrame:SetPoint("LEFT", textHolder, "LEFT")
        Rep.txFrame:ClearAllPoints()
        Rep.txFrame:SetPoint("LEFT", XP.txFrame, "RIGHT", gap, 0)
        
        local previewText = "[CONFIG MODE] PARAGON REWARD PENDING!"
        if db.splitParagonText then
            previewText = "[CONFIG MODE] FACTION A REWARD PENDING!\n[CONFIG MODE] FACTION B REWARD PENDING!"
        end
        paragonText:SetText(CONSTANTS.COLOR_PARAGON_PENDING .. previewText .. "|r")
        paragonText:Show()
        return 
    end
    -- ==========================

    -- RENDERIZADO NORMAL
    if not isMax then
        local currentXP, maxXP = UnitXP("player"), UnitXPMax("player")
        local rested = GetXPExhaustion()
        
        -- Determinar color principal de la barra
        local useRested = rested and rested > 0 and not db.showRestedBar
        if useRested then 
            XP.bar:SetStatusBarColor(CONSTANTS.COLOR_RESTED.r, CONSTANTS.COLOR_RESTED.g, CONSTANTS.COLOR_RESTED.b, CONSTANTS.COLOR_RESTED.a or 1.0)
        elseif db.useClassColorXP then
            XP.bar:SetStatusBarColor(state.playerClassColor.r, state.playerClassColor.g, state.playerClassColor.b, state.playerClassColor.a or 1.0)
        else
            XP.bar:SetStatusBarColor(db.xpBarColor.r, db.xpBarColor.g, db.xpBarColor.b, db.xpBarColor.a or 1.0)
        end
        
        XP.bar:SetMinMaxValues(0, maxXP)
        XP.bar:SetValue(currentXP)
        local pct = (maxXP > 0) and (currentXP / maxXP) or 0
        XP.spark:SetPoint("CENTER", XP.bar, "LEFT", XP.bar:GetWidth() * pct, 0)
        
        -- Renderizar overlay de Rested si está habilitado
        if db.showRestedBar and rested and rested > 0 and XP.restedOverlay then
            local currentXP, maxXP = UnitXP("player"), UnitXPMax("player")
            local totalXPWithRested = currentXP + rested
            local cappedRested = math.min(totalXPWithRested, maxXP)
            local barWidth = XP.bar:GetWidth()
            local barHeight = XP.bar:GetHeight()
            local restedWidth = barWidth * (cappedRested / maxXP)
            
            XP.restedOverlay:SetSize(restedWidth, barHeight)
            XP.restedOverlay:SetPoint("LEFT", XP.bar, "LEFT", 0, 0)
            XP.restedOverlay:SetColorTexture(db.restedBarColor.r, db.restedBarColor.g, db.restedBarColor.b, db.restedBarColor.a or 0.5)
            XP.restedOverlay:Show()
        elseif XP.restedOverlay then
            XP.restedOverlay:Hide()
        end
        
        XP.text:SetText(FormatXP())
        XP.txFrame:SetWidth(XP.text:GetStringWidth() + 2)
    end

    -- Reputación
    local name, reaction, min, max, value, factionID, standingLabel
    local paragonRewardFound, isFriendshipMaxed = false, false
    
    if #state.cachedPendingParagons > 0 then
        paragonRewardFound = true
        local p = state.cachedPendingParagons
        
        if db.splitParagonText then
            local lines = {}
            for _, info in ipairs(p) do
                table.insert(lines, CONSTANTS.COLOR_PARAGON_PENDING .. string.upper(info.name) .. " REWARD PENDING!|r")
            end
            paragonText:SetText(table.concat(lines, "\n"))
        else
            local namesList = {}
            for _, info in ipairs(p) do
                table.insert(namesList, string.upper(info.name))
            end
            
            local finalString = ""
            if #namesList == 1 then
                finalString = namesList[1]
            else
                local last = table.remove(namesList) 
                finalString = table.concat(namesList, ", ") .. " AND " .. last
            end
            
            local plural = (#p > 1) and "S" or ""
            paragonText:SetText(CONSTANTS.COLOR_PARAGON_PENDING .. finalString .. " REWARD" .. plural .. " PENDING!|r")
        end
        
        name, factionID = p[1].name, p[1].id
        min, max, value, reaction = 0, 1, 1, 8
        standingLabel = "Reward Pending"
        paragonText:Show()
    else
        paragonText:Hide()
        local data = C_Reputation and C_Reputation.GetWatchedFactionData()
        if data then
            name, reaction, factionID = data.name, data.reaction, data.factionID
            min, max, value = data.currentReactionThreshold, data.nextReactionThreshold, data.currentStanding
            
            if C_Reputation.IsMajorFaction(factionID) then
                local md = C_MajorFactions.GetMajorFactionData(factionID)
                if md then
                    min, max, value = 0, md.renownLevelThreshold, md.renownReputationEarned
                    standingLabel = "Renown " .. md.renownLevel
                end
            elseif C_Reputation.IsFactionParagon(factionID) then
                local cv, th = C_Reputation.GetFactionParagonInfo(factionID)
                if cv then min, max, value, standingLabel = 0, th, cv % th, "Paragon" end
            elseif C_GossipInfo and C_GossipInfo.GetFriendshipReputation(factionID) then
                local fd = C_GossipInfo.GetFriendshipReputation(factionID)
                if fd and fd.friendshipFactionID > 0 then
                    standingLabel = fd.reaction
                    if fd.nextThreshold then min, max, value = fd.reactionThreshold, fd.nextThreshold, fd.standing
                    else min, max, value, isFriendshipMaxed = 0, 1, 1, true end
                end
            end
        end
    end

    if name then
        Rep.bar:Show()
        Rep.txFrame:Show()
        
        local color = {r=0.5, g=0.5, b=0.5}
        
        if db.useReactionColorRep then
            if paragonRewardFound or (factionID and C_Reputation.IsFactionParagon(factionID)) then
                color = REP_COLORS[9]
            elseif C_Reputation.IsMajorFaction(factionID) then
                color = REP_COLORS[11] 
            elseif isFriendshipMaxed or (reaction == 8 and (max == 0 or min == max)) then
                color = REP_COLORS[10] 
                min, max, value = 0, 1, 1 
            else
                color = REP_COLORS[reaction] or color
            end
        else
            color = db.repBarColor
        end

        Rep.bar:SetStatusBarColor(color.r, color.g, color.b, color.a or 1.0)
        Rep.bar:SetMinMaxValues(min, max)
        Rep.bar:SetValue(value)
        local total, curr = max - min, value - min
        local pct2 = (total > 0) and (curr / total) or 0
        Rep.spark:SetPoint("CENTER", Rep.bar, "LEFT", Rep.bar:GetWidth() * pct2, 0)
        Rep.text:SetText(FormatRep(name, reaction, min, max, value, standingLabel, false))
        Rep.txFrame:SetWidth(Rep.text:GetStringWidth() + 2)
    else
        Rep.bar:Hide()
        Rep.txFrame:Hide()
    end

    local gap = 30
    textHolder:ClearAllPoints()
    textHolder:SetPoint("TOP", UIParent, "TOP", 0, db.yOffset - 13.5)

    if isMax or not name then
        local target = (isMax and name) and Rep.txFrame or XP.txFrame
        textHolder:SetWidth(target:GetWidth())
        target:ClearAllPoints()
        target:SetPoint("CENTER", textHolder, "CENTER")
    else
        textHolder:SetWidth(XP.txFrame:GetWidth() + gap + Rep.txFrame:GetWidth())
        XP.txFrame:ClearAllPoints()
        XP.txFrame:SetPoint("LEFT", textHolder, "LEFT")
        Rep.txFrame:ClearAllPoints()
        Rep.txFrame:SetPoint("LEFT", XP.txFrame, "RIGHT", gap, 0)
    end
end 

-- =========================================================================
-- 5. EVENT HANDLER
-- =========================================================================
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("PLAYER_XP_UPDATE")
f:RegisterEvent("UPDATE_EXHAUSTION")
f:RegisterEvent("PLAYER_LEVEL_UP")
f:RegisterEvent("UPDATE_FACTION")
f:RegisterEvent("MAJOR_FACTION_RENOWN_LEVEL_CHANGED")
f:RegisterEvent("MAJOR_FACTION_UNLOCKED")
f:RegisterEvent("PLAYER_REGEN_DISABLED") 
f:RegisterEvent("PLAYER_REGEN_ENABLED")
f:RegisterEvent("QUEST_TURNED_IN")

f:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        if not AscensionBarsDB then AscensionBarsDB = CopyTable(DEFAULTS) end
        db = AscensionBarsDB
        for k, v in pairs(DEFAULTS) do 
            if db[k] == nil then 
                if type(v) == "table" then db[k] = CopyTable(v) else db[k] = v end
            end 
        end
        HideBlizzardFrames()
        state.inCombat = InCombatLockdown() 
        UpdateLayout(UnitLevel("player") >= GetMaxPlayerLevel())
        ScanParagonRewards()
        UpdateVisibility()
        return 
    end

    if not db then return end

    if event == "PLAYER_REGEN_DISABLED" then
        state.inCombat = true
        UpdateVisibility()
    elseif event == "PLAYER_REGEN_ENABLED" then
        state.inCombat = false
        UpdateVisibility()
    elseif event == "QUEST_TURNED_IN" then
        -- Forzar rescaneo inmediato de Paragon cuando se completa una quest
        -- esto asegura que se limpie el texto de recompensa pendiente
        state.lastParagonScanTime = 0
        ScanParagonRewards()
    elseif event == "UPDATE_FACTION" then
        local now = GetTime()
        if (now - state.lastParagonScanTime) >= (db.paragonScanThrottle or 60) then
            ScanParagonRewards()
        else
            UpdateDisplay()
        end
    else
        UpdateDisplay()
    end
end)

if IsLoggedIn() then 
    f:GetScript("OnEvent")(f, "PLAYER_ENTERING_WORLD")
end