-- Core/UI.lua
local _, addon = ...

local C = addon.const

function addon.UpdateTitleBarVisibility()
    if not addon.mainFrame or not addon.mainFrame.titleBar then
        return
    end

    local frame = addon.mainFrame
    local hoverZone = frame.hoverZone
    local showTitle = hoverZone and hoverZone:IsMouseOver() or frame:IsMouseOver()
    frame.titleBar:SetShown(showTitle)
end

function addon.UpdateFontButton()
    return
end

function addon.ApplyTextColor()
    if not addon.mainFrame then
        return
    end

    local db = addon.GetDB()
    local r = (db and db.textColorR) or addon.DEFAULT_TEXT_COLOR_R
    local g = (db and db.textColorG) or addon.DEFAULT_TEXT_COLOR_G
    local b = (db and db.textColorB) or addon.DEFAULT_TEXT_COLOR_B

    if addon.mainFrame.buildText then
        addon.mainFrame.buildText:SetTextColor(r, g, b, 1)
    end
    if addon.mainFrame.titleText then
        addon.mainFrame.titleText:SetTextColor(r, g, b, 1)
    end
    if addon.mainFrame.buildFxText then
        addon.mainFrame.buildFxText:SetTextColor(r, g, b, 1)
    end
end

function addon.ApplyFontMode()
    if not addon.mainFrame then
        return
    end

    local preset = addon.stylePresets[addon.GetTextStyleIndex()] or addon.stylePresets[5]
    local useAddon = (preset.font == "addon")
    local justify = preset.justify or "CENTER"
    local f = addon.mainFrame
    local defaultFont = addon.DEFAULT_FONT

    if f.buildText then
        if useAddon then f.buildText:SetFont(C.ADDON_FONT, 14, "") else f.buildText:SetFont(defaultFont, 12, "") end
        f.buildText:SetJustifyH(justify)
    end
    if f.titleText then
        if useAddon then f.titleText:SetFont(C.ADDON_FONT, 11, "") else f.titleText:SetFont(defaultFont, 10, "") end
    end
    if f.talentsText then
        if useAddon then f.talentsText:SetFont(C.ADDON_FONT, 10, "") else f.talentsText:SetFont(defaultFont, 10, "") end
    end
    if f.buildFxText then
        if useAddon then f.buildFxText:SetFont(C.ADDON_FONT, 14, "") else f.buildFxText:SetFont(defaultFont, 12, "") end
        f.buildFxText:SetJustifyH(justify)
    end
    if addon.ApplyTalentWindowTextStyle then
        addon.ApplyTalentWindowTextStyle()
    end

    addon.ApplyTextColor()
    addon.UpdateFontButton()
end

function addon.ToggleFontMode()
    local db = addon.GetDB()
    if not db then
        return
    end

    if InCombatLockdown() or UnitAffectingCombat("player") then
        addon.Print("Text style changes are disabled in combat. Style cycling (1-6) resumes after combat.")
        return
    end

    local current = addon.GetTextStyleIndex()
    local nextStyle = current + 1
    if nextStyle > #addon.stylePresets then
        nextStyle = 1
    end

    db.textStyle = nextStyle
    addon.ApplyFontMode()
    local styleLabel = (addon.stylePresets[nextStyle] and addon.stylePresets[nextStyle].label) or tostring(nextStyle)
    addon.Print("Text style " .. tostring(nextStyle) .. "/6: " .. styleLabel)
end

function addon.ApplyFrameAlpha()
    if not addon.mainFrame then
        return
    end

    local db = addon.GetDB()
    local alphaPercent = (db and db.bgAlphaPercent) or addon.DEFAULT_BG_ALPHA_PERCENT
    local alpha = math.max(0, math.min(100, alphaPercent)) / 100
    addon.mainFrame:SetBackdropColor(0, 0, 0, alpha)
end

function addon.UpdateColorSwatch()
    if not addon.mainFrame or not addon.mainFrame.colorSwatch then
        return
    end

    local db = addon.GetDB()
    addon.mainFrame.colorSwatch:SetColorTexture(
        (db and db.textColorR) or addon.DEFAULT_TEXT_COLOR_R,
        (db and db.textColorG) or addon.DEFAULT_TEXT_COLOR_G,
        (db and db.textColorB) or addon.DEFAULT_TEXT_COLOR_B,
        1
    )
end

function addon.OpenTextColorPicker()
    local db = addon.GetDB()
    if not db then
        return
    end

    local function ApplyColor(r, g, b)
        db.textColorR = r
        db.textColorG = g
        db.textColorB = b
        addon.ApplyTextColor()
        addon.UpdateColorSwatch()
    end

    if ColorPickerFrame and ColorPickerFrame.SetupColorPickerAndShow then
        ColorPickerFrame:SetupColorPickerAndShow({
            r = db.textColorR or addon.DEFAULT_TEXT_COLOR_R,
            g = db.textColorG or addon.DEFAULT_TEXT_COLOR_G,
            b = db.textColorB or addon.DEFAULT_TEXT_COLOR_B,
            hasOpacity = false,
            swatchFunc = function()
                local r, g, b = ColorPickerFrame:GetColorRGB()
                ApplyColor(r, g, b)
            end,
            cancelFunc = function(previousValues)
                if previousValues and previousValues.r and previousValues.g and previousValues.b then
                    ApplyColor(previousValues.r, previousValues.g, previousValues.b)
                end
            end,
        })
        return
    end

    if ColorPickerFrame then
        local previous = {
            r = db.textColorR or addon.DEFAULT_TEXT_COLOR_R,
            g = db.textColorG or addon.DEFAULT_TEXT_COLOR_G,
            b = db.textColorB or addon.DEFAULT_TEXT_COLOR_B,
        }
        ColorPickerFrame.hasOpacity = false
        ColorPickerFrame.opacity = 0
        ColorPickerFrame:SetColorRGB(
            db.textColorR or addon.DEFAULT_TEXT_COLOR_R,
            db.textColorG or addon.DEFAULT_TEXT_COLOR_G,
            db.textColorB or addon.DEFAULT_TEXT_COLOR_B
        )
        ColorPickerFrame.func = function()
            local r, g, b = ColorPickerFrame:GetColorRGB()
            ApplyColor(r, g, b)
        end
        ColorPickerFrame.cancelFunc = function()
            ApplyColor(previous.r, previous.g, previous.b)
        end
        ColorPickerFrame:Show()
    end
end

function addon.UpdateFrameWidth()
    if not addon.mainFrame then
        return
    end

    addon.mainFrame:SetWidth(addon.GetBarWidth())
end

function addon.ApplyMainFrameScale()
    if not addon.mainFrame then
        return
    end
    addon.mainFrame:SetScale(addon.GetMainFrameScale and addon.GetMainFrameScale() or 1.0)
end

function addon.ApplyMainFrameVisibility()
    if not addon.mainFrame then
        return
    end

    local db = addon.GetDB()
    local hideMainBar = db and db.hideMainBar
    addon.mainFrame:SetShown(not hideMainBar)

    if not hideMainBar then
        addon.UpdateTitleBarVisibility()
    end
end

function addon.PlayBuildChangeAnimation()
    if not addon.mainFrame or not addon.mainFrame.buildText or not addon.mainFrame.buildFxText then
        return
    end

    local text = addon.mainFrame.buildText
    local fxText = addon.mainFrame.buildFxText
    if not addon.mainFrame.buildGlow then
        local glow = addon.mainFrame:CreateTexture(nil, "ARTWORK", nil, 2)
        glow:SetTexture("Interface\\Cooldown\\star4")
        glow:SetBlendMode("ADD")
        glow:SetPoint("CENTER", fxText, "CENTER", 0, 0)
        glow:SetSize(24, 24)
        glow:SetAlpha(0)
        addon.mainFrame.buildGlow = glow
    end

    local function StartImpactShake()
        if not text.mtShake then
            local shake = text:CreateAnimationGroup()
            local steps = {
                { 3,  0}, {-5,  1}, { 4, -1}, {-4,  1}, { 3, -1},
                {-3,  1}, { 3,  0}, {-3, -1}, { 2,  1}, {-2,  0},
                { 2, -1}, {-2,  1}, { 2,  0}, {-2,  0}, { 1,  0},
                {-1,  0}, { 1,  0}, {-1,  0}, { 1,  0}, { 0,  0},
            }

            for i = 1, #steps do
                local t = shake:CreateAnimation("Translation")
                t:SetOrder(i)
                t:SetDuration(0.05)
                t:SetOffset(steps[i][1], steps[i][2])
                t:SetSmoothing("IN_OUT")
            end

            shake:SetScript("OnFinished", function()
                text:SetAlpha(1.0)
                text:SetScale(1.0)
            end)
            text.mtShake = shake
        end

        if text.mtShake:IsPlaying() then
            text.mtShake:Stop()
        end
        text.mtShake:Play()
    end

    if not fxText.mtAnim then
        local group = fxText:CreateAnimationGroup()

        local alphaIn = group:CreateAnimation("Alpha")
        alphaIn:SetOrder(1)
        alphaIn:SetDuration(0.12)
        alphaIn:SetFromAlpha(0.0)
        alphaIn:SetToAlpha(1.0)
        alphaIn:SetSmoothing("OUT")

        local slideIn = group:CreateAnimation("Translation")
        slideIn:SetOrder(1)
        slideIn:SetDuration(0.22)
        slideIn:SetOffset(-28, 0)
        slideIn:SetSmoothing("OUT")

        local pulseScale = group:CreateAnimation("Scale")
        pulseScale:SetOrder(1)
        pulseScale:SetDuration(0.22)
        pulseScale:SetScale(-0.08, -0.08)
        pulseScale:SetSmoothing("OUT")

        group:SetScript("OnPlay", function()
            text:SetAlpha(0)
            fxText:Show()
            fxText:SetAlpha(0)
            fxText:SetScale(1.08)
            fxText:ClearAllPoints()
            fxText:SetPoint("CENTER", text, "CENTER", 28, 0)
            if addon.mainFrame and addon.mainFrame.buildGlow then
                addon.mainFrame.buildGlow:SetAlpha(0.9)
                addon.mainFrame.buildGlow:SetSize(20, 20)
                addon.mainFrame.buildGlow:SetVertexColor(0.45, 0.85, 1.0, 1)
            end
        end)

        group:SetScript("OnFinished", function()
            text:SetAlpha(1.0)
            fxText:Hide()
            fxText:SetScale(1.0)
            fxText:ClearAllPoints()
            fxText:SetPoint("CENTER", text, "CENTER", 28, 0)
            StartImpactShake()
            if addon.mainFrame and addon.mainFrame.buildGlow then
                addon.mainFrame.buildGlow:SetAlpha(0)
                addon.mainFrame.buildGlow:SetSize(24, 24)
            end
        end)

        group:SetScript("OnUpdate", function(self)
            if not addon.mainFrame or not addon.mainFrame.buildGlow then
                return
            end

            local progress = math.min(1, self:GetElapsed() / math.max(0.01, self:GetDuration()))
            local glow = addon.mainFrame.buildGlow
            glow:SetAlpha((1 - progress) * 0.9)
            local size = 20 + (progress * 54)
            glow:SetSize(size, size)
        end)

        fxText.mtAnim = group
    end

    fxText:SetText(text:GetText() or "")
    if fxText.mtAnim:IsPlaying() then fxText.mtAnim:Stop() end
    text:SetAlpha(1.0)
    text:SetScale(1.0)
    fxText.mtAnim:Play()
end

function addon.RefreshBuildName(allowSound)
    if not addon.mainFrame or not addon.mainFrame.buildText then
        return
    end

    local buildName, configID = addon.GetActiveBuildInfo()
    addon.mainFrame.buildText:SetText(buildName)

    local allowTalentSwitchFX = allowSound and addon._soundReady

    local didRealLoadoutChange = (
        allowTalentSwitchFX
        and addon._lastStableConfigID
        and configID
        and addon._lastStableConfigID ~= configID
    )

    if didRealLoadoutChange then
        addon.PlayBuildChangeAnimation()
        if not addon.IsAudioDisabled or not addon.IsAudioDisabled() then
            PlaySoundFile(C.TALENT_CHANGE_SOUND, "Master")
        end
    end

    addon._lastBuildName = buildName
    if configID then
        addon._lastStableConfigID = configID
    end
    addon.UpdateFrameWidth()
end

function addon.StartHoverUpdater()
    if not addon.mainFrame or addon.mainFrame._hoverUpdaterStarted then
        return
    end

    addon.mainFrame._hoverUpdaterStarted = true
    addon.mainFrame._hoverElapsed = 0
    addon.mainFrame:SetScript("OnUpdate", function(self, elapsed)
        self._hoverElapsed = self._hoverElapsed + elapsed
        if self._hoverElapsed < C.HOVER_UPDATE_INTERVAL then
            return
        end

        self._hoverElapsed = 0
        addon.UpdateTitleBarVisibility()
    end)
end

function addon.InitializeMainUI()
    if addon.mainFrame then
        return
    end

    local frame = CreateFrame("Frame", "MattsTalentedMainFrame", UIParent, "BackdropTemplate")
    frame:SetSize(C.MIN_WIDTH, C.FRAME_HEIGHT)
    frame:SetFrameStrata("MEDIUM")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    addon.CreateBackdrop(frame, 0.55)

    local buildText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    buildText:SetPoint("LEFT", frame, "LEFT", 8, 0)
    buildText:SetPoint("RIGHT", frame, "RIGHT", -8, 0)
    buildText:SetJustifyH("CENTER")
    buildText:SetJustifyV("MIDDLE")
    addon.SetAddonFont(buildText, 14, "")
    buildText:SetTextColor(0.92, 0.94, 0.96, 1)
    buildText:SetText("Loading...")

    local buildFxText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    buildFxText:SetPoint("CENTER", buildText, "CENTER", 28, 0)
    buildFxText:SetJustifyH("CENTER")
    buildFxText:SetJustifyV("MIDDLE")
    addon.SetAddonFont(buildFxText, 14, "")
    buildFxText:SetTextColor(0.92, 0.94, 0.96, 1)
    buildFxText:Hide()

    local titleBar = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    titleBar:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, 1)
    titleBar:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", 0, 1)
    titleBar:SetHeight(C.TITLE_HEIGHT)
    titleBar:EnableMouse(true)
    addon.CreateBackdrop(titleBar, 0.80)

    local hoverZone = CreateFrame("Frame", nil, frame)
    hoverZone:SetPoint("TOPLEFT", titleBar, "TOPLEFT", 0, 0)
    hoverZone:SetPoint("TOPRIGHT", titleBar, "TOPRIGHT", 0, 0)
    hoverZone:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    hoverZone:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)

    local title = titleBar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("LEFT", titleBar, "LEFT", 8, 0)
    addon.SetAddonFont(title, 11, "")
    title:SetText("Talented")
    title:SetTextColor(0.92, 0.94, 0.96, 1)

    local talentsButton = CreateFrame("Button", nil, titleBar, "BackdropTemplate")
    talentsButton:SetSize(44, 14)
    talentsButton:SetPoint("RIGHT", titleBar, "RIGHT", -6, 0)
    talentsButton:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    talentsButton:SetBackdropColor(0.05, 0.05, 0.08, 0.85)
    talentsButton:SetBackdropBorderColor(0.20, 0.20, 0.24, 1)

    local talentsText = talentsButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    talentsText:SetPoint("CENTER", talentsButton, "CENTER", 0, 0)
    addon.SetAddonFont(talentsText, 10, "")
    talentsText:SetText("Change")
    talentsText:SetTextColor(0.85, 0.88, 0.92, 1)
    talentsButton:SetScript("OnClick", addon.OpenTalentWindow)
    talentsButton:SetScript("OnEnter", function()
        addon.ShowDefaultTooltip("Change Talents")
    end)
    talentsButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    frame:SetScript("OnDragStart", function()
        frame:StartMoving()
    end)

    frame:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        addon.SaveMainFramePosition()
    end)

    frame.buildText = buildText
    frame.buildFxText = buildFxText
    frame.titleText = title
    frame.titleBar = titleBar
    frame.hoverZone = hoverZone
    frame.talentsText = talentsText
    frame.talentsButton = talentsButton

    addon.mainFrame = frame

    addon.LoadMainFramePosition()
    addon.ApplyMainFrameScale()
    addon.UpdateFrameWidth()
    addon.ApplyFrameAlpha()
    addon.ApplyFontMode()
    addon.RefreshBuildName()
    addon.UpdateTitleBarVisibility()
    addon.StartHoverUpdater()
    addon.ApplyMainFrameVisibility()
end
