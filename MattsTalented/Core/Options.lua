-- Core/Options.lua
local _, addon = ...
local C = addon.const

local function QueueOptionsPanelAfterCombat()
    addon._pendingOpenOptionsPanel = true
    if addon._optionsAfterCombatWatcher then
        return
    end

    local watcher = CreateFrame("Frame")
    addon._optionsAfterCombatWatcher = watcher
    watcher:RegisterEvent("PLAYER_REGEN_ENABLED")
    watcher:SetScript("OnEvent", function(self)
        self:UnregisterEvent("PLAYER_REGEN_ENABLED")
        addon._optionsAfterCombatWatcher = nil

        if not addon._pendingOpenOptionsPanel then
            return
        end
        addon._pendingOpenOptionsPanel = nil

        C_Timer.After(0.05, function()
            if addon.OpenOptionsPanel then
                addon.OpenOptionsPanel()
            end
        end)
    end)
end

local function OpenOptionsPanel()
    if InCombatLockdown() or UnitAffectingCombat("player") then
        QueueOptionsPanelAfterCombat()
        addon.Print("In combat. Options will open after combat ends (Blizzard API restriction).")
        return
    end

    if Settings and addon._optionsCategory and addon._optionsCategory.GetID then
        Settings.OpenToCategory(addon._optionsCategory:GetID())
        return
    end

    if InterfaceOptionsFrame_OpenToCategory and addon._optionsPanel then
        InterfaceOptionsFrame_OpenToCategory(addon._optionsPanel)
        InterfaceOptionsFrame_OpenToCategory(addon._optionsPanel)
    end
end

local function ApplyOptionsNow()
    if addon.ApplyMainFrameVisibility then
        addon.ApplyMainFrameVisibility()
    end
    if addon.RefreshBuildName then
        addon.RefreshBuildName(false)
    end
    if addon.RefreshEquipmentName then
        addon.RefreshEquipmentName()
    end
    if addon.EnsureTalentWindowHooks then
        addon.EnsureTalentWindowHooks()
    end
    if addon.RefreshTalentWindowAppearance then
        addon.RefreshTalentWindowAppearance()
    end
end

local function ApplyBarStyleNow()
    if addon.ApplyFrameAlpha then
        addon.ApplyFrameAlpha()
    end
    if addon.ApplyTextColor then
        addon.ApplyTextColor()
    end
    if addon.ApplyFontMode then
        addon.ApplyFontMode()
    end
    if addon.UpdateFrameWidth then
        addon.UpdateFrameWidth()
    end
    if addon.ApplyMainFrameScale then
        addon.ApplyMainFrameScale()
    end
end

local function CreateCheckbox(parent, y, label, tooltip, getValue, setValue)
    local check = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    check:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, y)
    check.Text:SetText(label)
    check:SetScript("OnClick", function(self)
        setValue(self:GetChecked() and true or false)
        ApplyOptionsNow()
    end)
    check:SetScript("OnShow", function(self)
        self:SetChecked(getValue())
    end)
    check:SetScript("OnEnter", function(self)
        if not tooltip or tooltip == "" then
            return
        end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(tooltip, 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    check:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    return check
end

local function CreateLabel(parent, x, y, text)
    local label = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    label:SetText(text)
    return label
end

local function InitializeMinimapLauncher()
    local db = addon.GetDB()
    if not db then
        return
    end

    local LDB = LibStub and LibStub:GetLibrary("LibDataBroker-1.1", true)
    local DBIcon = LibStub and LibStub:GetLibrary("LibDBIcon-1.0", true)
    if not LDB or not DBIcon then
        return
    end

    if not addon._dataObject then
        addon._dataObject = LDB:NewDataObject("MattsTalented", {
            type = "launcher",
            text = "Matt's Talented",
            label = "Matt's Talented",
            icon = "Interface\\AddOns\\MattsTalented\\Media\\Icons\\MT.png",
            OnClick = function(_, button)
                if button == "RightButton" then
                    local cfg = addon.GetDB()
                    if cfg then
                        cfg.hideMainBar = not cfg.hideMainBar
                        ApplyOptionsNow()
                    end
                    return
                end
                OpenOptionsPanel()
            end,
            OnTooltipShow = function(tt)
                tt:AddLine("Matt's Talented", 1, 1, 1)
                tt:AddLine("Left Click: Open Options", 0.9, 0.9, 0.9)
                tt:AddLine("Right Click: Toggle Main Bar", 0.9, 0.9, 0.9)
            end,
        })
    end

    db.minimap = db.minimap or { hide = false }

    if not addon._dbIconRegistered then
        DBIcon:Register("MattsTalented", addon._dataObject, db.minimap)
        addon._dbIconRegistered = true
    end

    if db.minimap.hide then
        DBIcon:Hide("MattsTalented")
    else
        DBIcon:Show("MattsTalented")
    end
end

function addon.InitializeOptions()
    if addon._optionsInitialized then
        InitializeMinimapLauncher()
        return
    end
    addon._optionsInitialized = true

    local panel = CreateFrame("Frame", "MattsTalentedOptionsPanel", UIParent)
    panel.name = "Matt's Talented"
    addon._optionsPanel = panel

    local headerIconFrame = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    headerIconFrame:SetSize(30, 30)
    headerIconFrame:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -12)
    headerIconFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    headerIconFrame:SetBackdropColor(0.02, 0.02, 0.03, 0.90)
    headerIconFrame:SetBackdropBorderColor(0.22, 0.23, 0.25, 1)

    local headerIcon = headerIconFrame:CreateTexture(nil, "ARTWORK")
    headerIcon:SetPoint("TOPLEFT", headerIconFrame, "TOPLEFT", 2, -2)
    headerIcon:SetPoint("BOTTOMRIGHT", headerIconFrame, "BOTTOMRIGHT", -2, 2)
    headerIcon:SetTexture("Interface\\AddOns\\MattsTalented\\Media\\Icons\\MT.png")
    headerIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("LEFT", headerIconFrame, "RIGHT", 8, 0)
    title:SetText("Matt's Talented")

    local subtitle = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    subtitle:SetText("Minimal Talents options")

    CreateCheckbox(
        panel,
        -56,
        "Hide the Talented on-screen window",
        "Hide the on-screen Talented build bar.",
        function()
            local db = addon.GetDB()
            return db and db.hideMainBar and true or false
        end,
        function(value)
            local db = addon.GetDB()
            if db then db.hideMainBar = value end
        end
    )

    CreateCheckbox(
        panel,
        -88,
        "Show Equipment Manager Bar",
        "Show a second bar under Talents with the active Equipment Manager set.",
        function()
            local db = addon.GetDB()
            return db and db.showEquipmentBar and true or false
        end,
        function(value)
            local db = addon.GetDB()
            if db then db.showEquipmentBar = value end
        end
    )

    CreateCheckbox(
        panel,
        -120,
        "Show Line Titles",
        "Show 'Current Talents:' and 'Equipment:' labels in the on-screen bars.",
        function()
            local db = addon.GetDB()
            return db == nil or db.showLineTitles ~= false
        end,
        function(value)
            local db = addon.GetDB()
            if db then db.showLineTitles = value end
        end
    )

    CreateCheckbox(
        panel,
        -152,
        "Use Minimal Theme",
        "Turning this off restores Blizzard default theme and 100% scale.",
        function()
            local db = addon.GetDB()
            return db == nil or db.useMinimalTheme ~= false
        end,
        function(value)
            local db = addon.GetDB()
            if db then db.useMinimalTheme = value end
        end
    )

    CreateCheckbox(
        panel,
        -184,
        "Scale Talent Window (70%)",
        "Applies 70% scale to the talent window when Minimal Theme is enabled.",
        function()
            local db = addon.GetDB()
            return db == nil or db.scaleTalentWindow ~= false
        end,
        function(value)
            local db = addon.GetDB()
            if db then db.scaleTalentWindow = value end
        end
    )

    CreateCheckbox(
        panel,
        -216,
        "Disable Audio",
        "Disables the talent change mp3 sound.",
        function()
            local db = addon.GetDB()
            return db and db.disableAudio and true or false
        end,
        function(value)
            local db = addon.GetDB()
            if db then db.disableAudio = value end
        end
    )

    local styleHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    styleHeader:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -260)
    styleHeader:SetText("On-Screen Window Style")

    CreateLabel(panel, 16, -288, "Width")
    local widthSlider = CreateFrame("Slider", "MattsTalentedOptionsWidthSlider", panel, "OptionsSliderTemplate")
    widthSlider:SetPoint("TOPLEFT", panel, "TOPLEFT", 70, -282)
    widthSlider:SetWidth(220)
    widthSlider:SetMinMaxValues(C.MIN_WIDTH, C.MAX_WIDTH)
    widthSlider:SetValueStep(1)
    widthSlider:SetObeyStepOnDrag(true)
    if _G.MattsTalentedOptionsWidthSliderLow then _G.MattsTalentedOptionsWidthSliderLow:SetText(tostring(C.MIN_WIDTH)) end
    if _G.MattsTalentedOptionsWidthSliderHigh then _G.MattsTalentedOptionsWidthSliderHigh:SetText(tostring(C.MAX_WIDTH)) end
    if _G.MattsTalentedOptionsWidthSliderText then _G.MattsTalentedOptionsWidthSliderText:SetText("") end
    widthSlider:SetScript("OnValueChanged", function(_, value)
        local db = addon.GetDB()
        if not db then
            return
        end
        db.barWidth = addon.ClampBarWidth(value)
        ApplyBarStyleNow()
    end)
    widthSlider:SetScript("OnShow", function(self)
        self:SetValue(addon.GetBarWidth())
    end)

    CreateLabel(panel, 16, -336, "Background Alpha")
    local alphaSlider = CreateFrame("Slider", "MattsTalentedOptionsAlphaSlider", panel, "OptionsSliderTemplate")
    alphaSlider:SetPoint("TOPLEFT", panel, "TOPLEFT", 130, -330)
    alphaSlider:SetWidth(160)
    alphaSlider:SetMinMaxValues(0, 100)
    alphaSlider:SetValueStep(1)
    alphaSlider:SetObeyStepOnDrag(true)
    if _G.MattsTalentedOptionsAlphaSliderLow then _G.MattsTalentedOptionsAlphaSliderLow:SetText("0") end
    if _G.MattsTalentedOptionsAlphaSliderHigh then _G.MattsTalentedOptionsAlphaSliderHigh:SetText("100") end
    if _G.MattsTalentedOptionsAlphaSliderText then _G.MattsTalentedOptionsAlphaSliderText:SetText("") end
    alphaSlider:SetScript("OnValueChanged", function(_, value)
        local db = addon.GetDB()
        if not db then
            return
        end
        db.bgAlphaPercent = math.floor(value + 0.5)
        ApplyBarStyleNow()
    end)
    alphaSlider:SetScript("OnShow", function(self)
        local db = addon.GetDB()
        self:SetValue((db and db.bgAlphaPercent) or addon.DEFAULT_BG_ALPHA_PERCENT)
    end)

    CreateLabel(panel, 16, -384, "Font")
    local fontButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    fontButton:SetSize(130, 22)
    fontButton:SetPoint("TOPLEFT", panel, "TOPLEFT", 70, -378)
    fontButton:SetScript("OnClick", function()
        addon.ToggleFontMode()
        if addon.GetCurrentStyleTooltipText then
            fontButton:SetText("Cycle (" .. tostring(addon.GetTextStyleIndex()) .. "/6)")
        end
    end)
    fontButton:SetScript("OnShow", function()
        fontButton:SetText("Cycle (" .. tostring(addon.GetTextStyleIndex()) .. "/6)")
    end)

    local colorButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    colorButton:SetSize(90, 22)
    colorButton:SetPoint("LEFT", fontButton, "RIGHT", 8, 0)
    colorButton:SetText("Font Color")
    colorButton:SetScript("OnClick", function()
        addon.OpenTextColorPicker()
    end)

    CreateLabel(panel, 16, -428, "Global Scale")
    local scaleSlider = CreateFrame("Slider", "MattsTalentedOptionsMainScaleSlider", panel, "OptionsSliderTemplate")
    scaleSlider:SetPoint("TOPLEFT", panel, "TOPLEFT", 130, -422)
    scaleSlider:SetWidth(160)
    scaleSlider:SetMinMaxValues(60, 140)
    scaleSlider:SetValueStep(1)
    scaleSlider:SetObeyStepOnDrag(true)
    if _G.MattsTalentedOptionsMainScaleSliderLow then _G.MattsTalentedOptionsMainScaleSliderLow:SetText("60%") end
    if _G.MattsTalentedOptionsMainScaleSliderHigh then _G.MattsTalentedOptionsMainScaleSliderHigh:SetText("140%") end
    if _G.MattsTalentedOptionsMainScaleSliderText then _G.MattsTalentedOptionsMainScaleSliderText:SetText("") end
    scaleSlider:SetScript("OnValueChanged", function(_, value)
        local db = addon.GetDB()
        if not db then
            return
        end
        db.mainFrameScale = addon.ClampMainFrameScale((value or 100) / 100)
        ApplyBarStyleNow()
    end)
    scaleSlider:SetScript("OnShow", function(self)
        self:SetValue((addon.GetMainFrameScale and addon.GetMainFrameScale() or 1.0) * 100)
    end)

    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name, panel.name)
        Settings.RegisterAddOnCategory(category)
        addon._optionsCategory = category
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
    end

    addon.OpenOptionsPanel = OpenOptionsPanel
    InitializeMinimapLauncher()
end
