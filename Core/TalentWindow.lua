-- Core/TalentWindow.lua
local _, addon = ...

local FIXED_TALENT_WINDOW_SCALE = 0.7

local function IsApplyingTalentsCastActive()
    local bar = OverlayPlayerCastingBarFrame
    return bar and bar:IsShown() and bar.unit == "player" and bar.spellID == 384255
end

local function IsPlayerCastingOrChanneling()
    return UnitCastingInfo("player") ~= nil
        or UnitChannelInfo("player") ~= nil
        or IsApplyingTalentsCastActive()
end
addon.IsPlayerCastingOrChanneling = IsPlayerCastingOrChanneling

local function QueueTalentWindowOpenAfterCombat()
    addon._pendingOpenTalentWindow = true
    if addon._openAfterCombatWatcher then
        return
    end

    local watcher = CreateFrame("Frame")
    addon._openAfterCombatWatcher = watcher
    watcher:RegisterEvent("PLAYER_REGEN_ENABLED")
    watcher:SetScript("OnEvent", function(self)
        self:UnregisterEvent("PLAYER_REGEN_ENABLED")
        addon._openAfterCombatWatcher = nil

        if not addon._pendingOpenTalentWindow then
            return
        end
        addon._pendingOpenTalentWindow = nil

        C_Timer.After(0.05, function()
            if addon.OpenTalentWindow then
                addon.OpenTalentWindow()
            end
        end)
    end)
end

local function NotifyCombatBlockedOpen()
    local now = GetTime()
    if addon._lastCombatOpenMsg and (now - addon._lastCombatOpenMsg) < 1.0 then
        return
    end
    addon._lastCombatOpenMsg = now
    addon.Print("In combat. Scale will return after combat ends (Blizzard API restriction).")
end

local function QueueTalentScaleRefreshAfterCombat()
    if addon._pendingTalentScaleRefresh then
        return
    end
    addon._pendingTalentScaleRefresh = true

    if addon._scaleRefreshWatcher then
        return
    end

    local watcher = CreateFrame("Frame")
    addon._scaleRefreshWatcher = watcher
    watcher:RegisterEvent("PLAYER_REGEN_ENABLED")
    watcher:SetScript("OnEvent", function(self)
        self:UnregisterEvent("PLAYER_REGEN_ENABLED")
        addon._scaleRefreshWatcher = nil

        if not addon._pendingTalentScaleRefresh then
            return
        end
        addon._pendingTalentScaleRefresh = nil

        C_Timer.After(0.05, function()
            if addon.RefreshTalentWindowAppearance then
                addon.RefreshTalentWindowAppearance()
            end
        end)
    end)
end

local GetOpenTalentFrame

local function AnchorTalentCastBarToFrame(frame)
    local bar = OverlayPlayerCastingBarFrame
    if not bar or not frame then
        return
    end

    if not bar._mtOriginalParent then
        bar._mtOriginalParent = bar:GetParent()
    end
    if not bar._mtOriginalPoint then
        local p, relTo, relPoint, x, y = bar:GetPoint(1)
        bar._mtOriginalPoint = {
            point = p or "CENTER",
            relativeTo = relTo,
            relativePoint = relPoint or "CENTER",
            x = x or 0,
            y = y or 0,
        }
    end

    if bar:GetParent() ~= frame then
        bar:SetParent(frame)
    end

    bar:ClearAllPoints()
    local applyButton = frame.TalentsFrame and frame.TalentsFrame.ApplyButton
    if applyButton and applyButton:IsShown() then
        bar:SetPoint("BOTTOM", applyButton, "TOP", 0, 8)
    else
        bar:SetPoint("BOTTOM", frame, "BOTTOM", 0, 52)
    end
    bar:SetFrameStrata("DIALOG")
    bar:SetFrameLevel((frame:GetFrameLevel() or 1) + 500)
end

local function RestoreTalentCastBarAnchor()
    local bar = OverlayPlayerCastingBarFrame
    if not bar then
        return
    end

    local originalParent = bar._mtOriginalParent
    local originalPoint = bar._mtOriginalPoint

    if originalParent then
        bar:SetParent(originalParent)
    else
        bar:SetParent(UIParent)
    end

    bar:ClearAllPoints()
    if originalPoint then
        bar:SetPoint(
            originalPoint.point or "CENTER",
            originalPoint.relativeTo or UIParent,
            originalPoint.relativePoint or "CENTER",
            originalPoint.x or 0,
            originalPoint.y or 0
        )
    else
        bar:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
end

local function EnsureTalentCastBarHook()
    local bar = OverlayPlayerCastingBarFrame
    if not bar or bar._mtHooked then
        return
    end

    bar._mtHooked = true
    bar:HookScript("OnShow", function(self)
        local frame = GetOpenTalentFrame and GetOpenTalentFrame()
        if frame and frame:IsShown() then
            AnchorTalentCastBarToFrame(frame)
        end
    end)
    bar:HookScript("OnUpdate", function(self)
        if not self:IsShown() or self.spellID ~= 384255 then
            return
        end

        local frame = GetOpenTalentFrame and GetOpenTalentFrame()
        if frame and frame:IsShown() then
            AnchorTalentCastBarToFrame(frame)
        end
    end)
end

local function EnforceMinimalCurrencyHeaderColors(talentsFrame)
    if not talentsFrame then
        return
    end

    local function ForceWhite(fontString)
        if not fontString then
            return
        end
        fontString:SetTextColor(1, 1, 1, 1)
        fontString:SetAlpha(1)
        fontString:SetShadowColor(0, 0, 0, 0.85)
    end

    local classDisplay = talentsFrame.ClassCurrencyDisplay
    if classDisplay then
        classDisplay:SetFrameStrata("HIGH")
        classDisplay:SetFrameLevel((talentsFrame:GetFrameLevel() or 1) + 260)
        ForceWhite(classDisplay.CurrencyLabel)
        if classDisplay.CurrentAmountContainer then
            classDisplay.CurrentAmountContainer:SetFrameLevel(classDisplay:GetFrameLevel() + 1)
            ForceWhite(classDisplay.CurrentAmountContainer.CurrencyAmount)
        end
    end

    local specDisplay = talentsFrame.SpecCurrencyDisplay
    if specDisplay then
        specDisplay:SetFrameStrata("HIGH")
        specDisplay:SetFrameLevel((talentsFrame:GetFrameLevel() or 1) + 260)
        ForceWhite(specDisplay.CurrencyLabel)
        if specDisplay.CurrentAmountContainer then
            specDisplay.CurrentAmountContainer:SetFrameLevel(specDisplay:GetFrameLevel() + 1)
            ForceWhite(specDisplay.CurrentAmountContainer.CurrencyAmount)
        end
    end
end

local function ApplyMinimalTabSkin(frame)
    if not frame then
        return
    end

    local selectedTabID = nil
    if frame.GetTab then
        selectedTabID = frame:GetTab()
    elseif frame.TabSystem then
        selectedTabID = frame.TabSystem.selectedTabID
    end

    local tabIDs = { frame.specTabID, frame.talentTabID, frame.spellBookTabID }
    local tabKeys = {
        "LeftActive", "MiddleActive", "RightActive",
        "Left", "Middle", "Right",
        "LeftHighlight", "MiddleHighlight", "RightHighlight",
    }

    for i = 1, #tabIDs do
        local tabID = tabIDs[i]
        local tabButton = tabID and frame.GetTabButton and frame:GetTabButton(tabID)
        if tabButton then
            if not tabButton._mtMinimalBG then
                for j = 1, #tabKeys do
                    local r = tabButton[tabKeys[j]]
                    if r then
                        r:SetAlpha(0)
                        r:Hide()
                    end
                end

                local bg = CreateFrame("Frame", nil, tabButton, "BackdropTemplate")
                bg:SetPoint("TOPLEFT", tabButton, "TOPLEFT", 0, 0)
                bg:SetPoint("BOTTOMRIGHT", tabButton, "BOTTOMRIGHT", 0, 0)
                bg:SetFrameStrata(tabButton:GetFrameStrata())
                bg:SetFrameLevel(tabButton:GetFrameLevel())
                bg:EnableMouse(false)
                bg:SetBackdrop({
                    bgFile = "Interface\\Buttons\\WHITE8x8",
                    edgeFile = "Interface\\Buttons\\WHITE8x8",
                    edgeSize = 1,
                })
                tabButton._mtMinimalBG = bg
            end

            local isSelected = (selectedTabID == tabID)
            if tabButton._mtMinimalBG then
                if isSelected then
                    tabButton._mtMinimalBG:SetBackdropColor(0.17, 0.17, 0.18, 0.95)
                    tabButton._mtMinimalBG:SetBackdropBorderColor(0.72, 0.65, 0.20, 1)
                else
                    tabButton._mtMinimalBG:SetBackdropColor(0.10, 0.10, 0.11, 0.92)
                    tabButton._mtMinimalBG:SetBackdropBorderColor(0.22, 0.23, 0.25, 1)
                end
                tabButton._mtMinimalBG:Show()
            end

            if tabButton.Text then
                tabButton.Text:SetTextColor(1, 1, 1, 1)
            end
        end
    end

    if frame.SetTab and not frame._mtMinimalTabHooked then
        frame._mtMinimalTabHooked = true
        hooksecurefunc(frame, "SetTab", function()
            ApplyMinimalTabSkin(frame)
        end)
    end
end

-- NOTE: This implementation body is intentionally kept identical to the stable version.
-- It was moved from Core/Core.lua to keep responsibilities split.
local function ApplyMinimalTalentSkin(frame)
    if not frame then
        return
    end

    local function HideRegion(region)
        if region and region.Hide then
            region:Hide()
        end
    end

    if frame.NineSlice then frame.NineSlice:Hide() end
    if frame.Inset then frame.Inset:Hide() end

    if not frame._mtMinimalBorder then
        local border = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        border:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -24)
        border:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -4, 4)
        border:SetFrameLevel((frame:GetFrameLevel() or 1) + 100)
        border:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
        border:SetBackdropBorderColor(0.18, 0.20, 0.24, 1)
        frame._mtMinimalBorder = border
    end
    frame._mtMinimalBorder:Show()

    local talentsFrame = frame.TalentsFrame
    if talentsFrame then
        HideRegion(talentsFrame.BottomBar)
        HideRegion(talentsFrame.Background)
        HideRegion(talentsFrame.OverlayBackgroundRight)
        HideRegion(talentsFrame.OverlayBackgroundMid)
        HideRegion(talentsFrame.Clouds1)
        HideRegion(talentsFrame.Clouds2)
        HideRegion(talentsFrame.AirParticlesClose)
        HideRegion(talentsFrame.AirParticlesFar)
        HideRegion(talentsFrame.ActivationExpandFx)
        HideRegion(talentsFrame.ActivationClassFx)
        HideRegion(talentsFrame.ActivationClassFx2)
        HideRegion(talentsFrame.ActivationClassFx3)
        HideRegion(talentsFrame.ActivationClassFx4)
        HideRegion(talentsFrame.ActivationTitansFX)
        HideRegion(talentsFrame.BackgroundFlash)
        HideRegion(talentsFrame.FxModelScene)

        if talentsFrame.specBackgrounds then
            for i = 1, #talentsFrame.specBackgrounds do
                HideRegion(talentsFrame.specBackgrounds[i])
            end
        end
        if talentsFrame.classActivationTextures then
            for i = 1, #talentsFrame.classActivationTextures do
                HideRegion(talentsFrame.classActivationTextures[i])
            end
        end

        if talentsFrame.BlackBG then
            talentsFrame.BlackBG:Show()
            talentsFrame.BlackBG:SetColorTexture(0.10, 0.10, 0.11, 0.86)
        end

        EnforceMinimalCurrencyHeaderColors(talentsFrame)

        if talentsFrame.ButtonsParent and not talentsFrame._mtMinimalButtonsBar then
            local bar = CreateFrame("Frame", nil, talentsFrame, "BackdropTemplate")
            bar:SetPoint("TOPLEFT", talentsFrame.ButtonsParent, "TOPLEFT", 0, 0)
            bar:SetPoint("BOTTOMRIGHT", talentsFrame.ButtonsParent, "BOTTOMRIGHT", 0, 0)
            bar:SetFrameStrata(talentsFrame:GetFrameStrata())
            bar:SetFrameLevel(math.max(1, (talentsFrame.ButtonsParent:GetFrameLevel() or 1) - 1))
            bar:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 1,
            })
            bar:SetBackdropColor(0.12, 0.12, 0.13, 0.82)
            bar:SetBackdropBorderColor(0.22, 0.23, 0.25, 1)
            talentsFrame._mtMinimalButtonsBar = bar
        end
        if talentsFrame._mtMinimalButtonsBar then
            talentsFrame._mtMinimalButtonsBar:Show()
        end

        if talentsFrame.WarmodeButton then
            local wm = talentsFrame.WarmodeButton
            HideRegion(wm.Indent); HideRegion(wm.Ring); HideRegion(wm.FireModelScene); HideRegion(wm.OrbModelScene)
            if wm.Orb then wm.Orb:SetAlpha(0.05) end
            if wm.Swords then wm.Swords:SetAlpha(0.55) end
        end
        if talentsFrame.PvPTalentSlotTray then
            local tray = talentsFrame.PvPTalentSlotTray
            HideRegion(tray.Label)
            local slots = tray.Slots
            if slots then
                for i = 1, #slots do
                    local slot = slots[i]
                    if slot then HideRegion(slot.Shadow); HideRegion(slot.Border) end
                end
            end
        end
        if talentsFrame.ApplyButton and talentsFrame.ApplyButton.YellowGlow then
            HideRegion(talentsFrame.ApplyButton.YellowGlow)
        end
    end

    if frame.PortraitContainer then frame.PortraitContainer:Hide() end
    if frame._mtClassIcon then frame._mtClassIcon:Hide() end

    if not frame._mtSpecIconFrame then
        local iconFrame = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        iconFrame:SetSize(24, 24)
        iconFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -29)
        iconFrame:SetFrameStrata("DIALOG")
        iconFrame:SetFrameLevel((frame:GetFrameLevel() or 1) + 320)
        iconFrame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        iconFrame:SetBackdropColor(0.10, 0.10, 0.11, 0.95)
        iconFrame:SetBackdropBorderColor(0.22, 0.23, 0.25, 1)

        local icon = iconFrame:CreateTexture(nil, "ARTWORK")
        icon:SetDrawLayer("OVERLAY", 7)
        icon:SetPoint("TOPLEFT", iconFrame, "TOPLEFT", 2, -2)
        icon:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", -2, 2)

        frame._mtSpecIconFrame = iconFrame
        frame._mtSpecIcon = icon
    end

    if not frame._mtTalentedTag then
        local tag = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        tag:SetSize(260, 30)
        tag:SetPoint("BOTTOMLEFT", frame._mtSpecIconFrame, "TOPLEFT", 0, 3)
        tag:SetFrameStrata("DIALOG")
        tag:SetFrameLevel((frame:GetFrameLevel() or 1) + 321)
        tag:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        tag:SetBackdropColor(0.10, 0.10, 0.11, 0.95)
        tag:SetBackdropBorderColor(0.22, 0.23, 0.25, 1)

        local text = tag:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        text:SetPoint("CENTER", tag, "CENTER", 0, 0)
        text:SetFont(addon.GetSelectedFontPath(), addon.IsUsingAddonFontStyle() and 17 or 18, "")
        text:SetTextColor(1, 1, 1, 1)

        frame._mtTalentedTag = tag
        frame._mtTalentedTagText = text
    end

    local specIndex = GetSpecialization()
    local specIcon = specIndex and select(4, GetSpecializationInfo(specIndex)) or nil
    if specIcon then
        frame._mtSpecIcon:SetTexture(specIcon)
        frame._mtSpecIcon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
    else
        local _, classFile = UnitClass("player")
        local coords = classFile and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[string.upper(classFile)]
        frame._mtSpecIcon:SetTexture("Interface\\TargetingFrame\\UI-Classes-Circles")
        if coords then frame._mtSpecIcon:SetTexCoord(coords[1], coords[2], coords[3], coords[4]) else frame._mtSpecIcon:SetTexCoord(0, 1, 0, 1) end
    end

    frame._mtSpecIconFrame:Show()
    frame._mtSpecIcon:Show()
    if frame._mtTalentedTag and frame._mtTalentedTagText then
        frame._mtTalentedTagText:SetFont(addon.GetSelectedFontPath(), addon.IsUsingAddonFontStyle() and 17 or 18, "")
        local specName = specIndex and select(2, GetSpecializationInfo(specIndex)) or nil
        if not specName or specName == "" then specName = "Unknown" end
        frame._mtTalentedTagText:SetText(string.format("Talented - Spec: %s", specName))
        local width = math.floor((frame._mtTalentedTagText:GetStringWidth() or 0) + 22)
        if width < 220 then width = 220 end
        if width > 420 then width = 420 end
        frame._mtTalentedTag:SetWidth(width)
        frame._mtTalentedTag:Show()
    end

    ApplyMinimalTabSkin(frame)
end

local function RestoreBlizzardTalentSkin(frame)
    if not frame then return end
    local function ShowRegion(region) if region and region.Show then region:Show() end end

    ShowRegion(frame.NineSlice); ShowRegion(frame.Inset); ShowRegion(frame.PortraitContainer)
    if frame._mtMinimalBorder then frame._mtMinimalBorder:Hide() end
    if frame._mtSpecIconFrame then frame._mtSpecIconFrame:Hide() end
    if frame._mtTalentedTag then frame._mtTalentedTag:Hide() end

    local talentsFrame = frame.TalentsFrame
    if talentsFrame then
        ShowRegion(talentsFrame.BottomBar); ShowRegion(talentsFrame.Background); ShowRegion(talentsFrame.OverlayBackgroundRight)
        ShowRegion(talentsFrame.OverlayBackgroundMid); ShowRegion(talentsFrame.Clouds1); ShowRegion(talentsFrame.Clouds2)
        ShowRegion(talentsFrame.AirParticlesClose); ShowRegion(talentsFrame.AirParticlesFar); ShowRegion(talentsFrame.ActivationExpandFx)
        ShowRegion(talentsFrame.ActivationClassFx); ShowRegion(talentsFrame.ActivationClassFx2); ShowRegion(talentsFrame.ActivationClassFx3)
        ShowRegion(talentsFrame.ActivationClassFx4); ShowRegion(talentsFrame.ActivationTitansFX); ShowRegion(talentsFrame.BackgroundFlash)
        ShowRegion(talentsFrame.FxModelScene)
        if talentsFrame.specBackgrounds then for i = 1, #talentsFrame.specBackgrounds do ShowRegion(talentsFrame.specBackgrounds[i]) end end
        if talentsFrame.classActivationTextures then for i = 1, #talentsFrame.classActivationTextures do ShowRegion(talentsFrame.classActivationTextures[i]) end end
        if talentsFrame._mtMinimalButtonsBar then talentsFrame._mtMinimalButtonsBar:Hide() end
        if talentsFrame.WarmodeButton then
            local wm = talentsFrame.WarmodeButton
            ShowRegion(wm.Indent); ShowRegion(wm.Ring); ShowRegion(wm.FireModelScene); ShowRegion(wm.OrbModelScene)
            if wm.Orb then wm.Orb:SetAlpha(1) end
            if wm.Swords then wm.Swords:SetAlpha(1) end
        end
        if talentsFrame.PvPTalentSlotTray then
            local tray = talentsFrame.PvPTalentSlotTray
            ShowRegion(tray.Label)
            local slots = tray.Slots
            if slots then for i = 1, #slots do local slot = slots[i]; if slot then ShowRegion(slot.Shadow); ShowRegion(slot.Border) end end end
        end
        if talentsFrame.ApplyButton and talentsFrame.ApplyButton.YellowGlow then ShowRegion(talentsFrame.ApplyButton.YellowGlow) end
    end

    local tabIDs = { frame.specTabID, frame.talentTabID, frame.spellBookTabID }
    local tabKeys = { "LeftActive", "MiddleActive", "RightActive", "Left", "Middle", "Right", "LeftHighlight", "MiddleHighlight", "RightHighlight" }
    for i = 1, #tabIDs do
        local tabID = tabIDs[i]
        local tabButton = tabID and frame.GetTabButton and frame:GetTabButton(tabID)
        if tabButton then
            if tabButton._mtMinimalBG then tabButton._mtMinimalBG:Hide() end
            for j = 1, #tabKeys do local r = tabButton[tabKeys[j]]; if r then r:SetAlpha(1); r:Show() end end
        end
    end
end

GetOpenTalentFrame = function()
    if PlayerSpellsFrame and PlayerSpellsFrame:IsShown() then return PlayerSpellsFrame end
    if PlayerTalentFrame and PlayerTalentFrame:IsShown() then return PlayerTalentFrame end
    return nil
end

function addon.ApplyTalentWindowTextStyle(frame)
    if not addon.IsMinimalThemeEnabled() then return end
    frame = frame or (GetOpenTalentFrame and GetOpenTalentFrame())
    if not frame then return end
    local fontPath = addon.GetSelectedFontPath()
    local useAddon = addon.IsUsingAddonFontStyle()
    if frame._mtTalentedTagText then
        frame._mtTalentedTagText:SetFont(fontPath, useAddon and 17 or 18, "")
        if frame._mtTalentedTag then
            local width = math.floor((frame._mtTalentedTagText:GetStringWidth() or 0) + 22)
            if width < 220 then width = 220 end
            if width > 420 then width = 420 end
            frame._mtTalentedTag:SetWidth(width)
        end
    end
end

function addon.RefreshTalentWindowAppearance()
    local frame = GetOpenTalentFrame and GetOpenTalentFrame()
    if not frame then return end

    if addon.IsMinimalThemeEnabled() then
        EnsureTalentCastBarHook()
        AnchorTalentCastBarToFrame(frame)
        ApplyMinimalTalentSkin(frame)
        addon.ApplyTalentWindowTextStyle(frame)
        if frame.SetScale and not InCombatLockdown() then
            if addon.IsTalentScaleEnabled() and not IsPlayerCastingOrChanneling() then frame:SetScale(FIXED_TALENT_WINDOW_SCALE) else frame:SetScale(1) end
        end
    else
        RestoreTalentCastBarAnchor()
        RestoreBlizzardTalentSkin(frame)
        if frame.SetScale and not InCombatLockdown() then frame:SetScale(1) end
    end
end

function addon.EnsureTalentWindowHooks()
    if addon._talentWindowHooksInstalled then return end
    addon._talentWindowHooksInstalled = true

    local function ApplyForOpenFrame()
        addon.RefreshTalentWindowAppearance()
    end

    local function HookFrameOnShow(frame)
        if not frame or frame._mtTalentWindowOnShowHooked then return end
        frame._mtTalentWindowOnShowHooked = true
        frame:HookScript("OnShow", function()
            if InCombatLockdown() or UnitAffectingCombat("player") then
                NotifyCombatBlockedOpen()
                QueueTalentScaleRefreshAfterCombat()
            end
            ApplyForOpenFrame()
        end)
        frame:HookScript("OnHide", function()
            RestoreTalentCastBarAnchor()
        end)
    end

    HookFrameOnShow(PlayerSpellsFrame)

    if not addon._mtTalentFrameLoadHook then
        addon._mtTalentFrameLoadHook = CreateFrame("Frame")
        addon._mtTalentFrameLoadHook:RegisterEvent("ADDON_LOADED")
        addon._mtTalentFrameLoadHook:SetScript("OnEvent", function(_, _, loadedName)
            if loadedName == "Blizzard_PlayerSpells" or loadedName == "Blizzard_ClassTalentUI" or loadedName == "Blizzard_TalentUI" then
                HookFrameOnShow(PlayerSpellsFrame)
                ApplyForOpenFrame()
            end
        end)
    end

C_Timer.After(0.10, ApplyForOpenFrame)
end

function addon.OpenTalentWindow()
    if InCombatLockdown() or UnitAffectingCombat("player") then
        QueueTalentWindowOpenAfterCombat()
        NotifyCombatBlockedOpen()
        return
    end

    addon.EnsureTalentWindowHooks()

    if type(TogglePlayerSpellsFrame) == "function" then
        pcall(TogglePlayerSpellsFrame, Enum and Enum.PlayerSpellsTab and Enum.PlayerSpellsTab.Talents or nil)
        return
    end
    if type(ToggleTalentFrame) == "function" then
        ToggleTalentFrame()
        return
    end
    if PlayerSpellsMicroButton and PlayerSpellsMicroButton.Click then
        PlayerSpellsMicroButton:Click()
    end
end
