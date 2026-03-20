-- Core/Core.lua
local _, addon = ...

local C = addon.const
local DEFAULT_FONT = STANDARD_TEXT_FONT

local function GetDefault(name, fallback)
    local value = addon.svDefaults and addon.svDefaults[name]
    if value == nil then
        return fallback
    end
    return value
end

addon.DEFAULT_FONT = DEFAULT_FONT
addon.DEFAULT_BG_ALPHA_PERCENT = GetDefault("bgAlphaPercent", 55)
addon.DEFAULT_TEXT_COLOR_R = GetDefault("textColorR", 0.92)
addon.DEFAULT_TEXT_COLOR_G = GetDefault("textColorG", 0.94)
addon.DEFAULT_TEXT_COLOR_B = GetDefault("textColorB", 0.96)

function addon.GetDB()
    return _G[C.DB_NAME]
end

function addon.Print(message)
    print("|cff66d9ffTalented|r: " .. tostring(message))
end

function addon.InitializeSavedVariables()
    _G[C.DB_NAME] = _G[C.DB_NAME] or {}
    local db = _G[C.DB_NAME]

    for key, value in pairs(addon.svDefaults) do
        if db[key] == nil then
            db[key] = value
        end
    end

    if db.textStyle < 1 then db.textStyle = 1 end
    if db.textStyle > #addon.stylePresets then db.textStyle = #addon.stylePresets end
    if db.barWidth == nil then db.barWidth = C.MIN_WIDTH end
    if db.useMinimalTheme == nil then db.useMinimalTheme = true end
    if db.scaleTalentWindow == nil then db.scaleTalentWindow = true end
    if db.disableAudio == nil then
        db.disableAudio = false
    end
    if db.mainFrameScale == nil then
        db.mainFrameScale = 1.0
    end
    if db.mainFrameScale < 0.6 then db.mainFrameScale = 0.6 end
    if db.mainFrameScale > 1.4 then db.mainFrameScale = 1.4 end
    db.minimap = db.minimap or {}
    if db.minimap.hide == nil then db.minimap.hide = false end

end

function addon.IsMinimalThemeEnabled()
    local db = addon.GetDB()
    return db == nil or db.useMinimalTheme ~= false
end

function addon.IsTalentScaleEnabled()
    local db = addon.GetDB()
    return db == nil or db.scaleTalentWindow ~= false
end

function addon.IsAudioDisabled()
    local db = addon.GetDB()
    return db and db.disableAudio == true
end

function addon.ClampMainFrameScale(value)
    local scale = tonumber(value) or 1.0
    if scale < 0.6 then scale = 0.6 end
    if scale > 1.4 then scale = 1.4 end
    return scale
end

function addon.GetMainFrameScale()
    local db = addon.GetDB()
    return addon.ClampMainFrameScale(db and db.mainFrameScale or 1.0)
end

function addon.CreateBackdrop(frame, bgAlpha)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    frame:SetBackdropColor(0, 0, 0, bgAlpha or 0.50)
    frame:SetBackdropBorderColor(0, 0, 0, 1)
end

function addon.SetAddonFont(fontString, size, flags)
    if not fontString then
        return
    end

    fontString:SetFont(C.ADDON_FONT, size or 12, flags or "")
end

function addon.GetTextStyleIndex()
    local db = addon.GetDB()
    local idx = (db and db.textStyle) or 5
    idx = tonumber(idx) or 5
    if idx < 1 then idx = 1 end
    if idx > #addon.stylePresets then idx = #addon.stylePresets end
    return idx
end

function addon.GetCurrentStyleTooltipText()
    local idx = addon.GetTextStyleIndex()
    local preset = addon.stylePresets[idx]
    local label = (preset and preset.label) or tostring(idx)
    return "Change Talented Font Style (" .. tostring(idx) .. "/6: " .. label .. ")"
end

function addon.GetSelectedFontPath()
    local preset = addon.stylePresets and addon.stylePresets[addon.GetTextStyleIndex()] or nil
    if preset and preset.font == "addon" then
        return C.ADDON_FONT
    end
    return addon.DEFAULT_FONT or DEFAULT_FONT
end

function addon.IsUsingAddonFontStyle()
    local preset = addon.stylePresets and addon.stylePresets[addon.GetTextStyleIndex()] or nil
    return preset and preset.font == "addon" or false
end

function addon.SaveMainFramePosition()
    if not addon.mainFrame then
        return
    end

    local point, _, relativePoint, xOfs, yOfs = addon.mainFrame:GetPoint(1)
    local db = addon.GetDB()
    if not db then
        return
    end

    db.point = point or "CENTER"
    db.relativePoint = relativePoint or "CENTER"
    db.xOfs = xOfs or 0
    db.yOfs = yOfs or 0
end

function addon.LoadMainFramePosition()
    if not addon.mainFrame then
        return
    end

    local db = addon.GetDB()

    addon.mainFrame:ClearAllPoints()
    addon.mainFrame:SetPoint(
        (db and db.point) or "CENTER",
        UIParent,
        (db and db.relativePoint) or "CENTER",
        (db and db.xOfs) or 0,
        (db and db.yOfs) or 0
    )
end

function addon.ClampBarWidth(value)
    local v = tonumber(value) or C.MIN_WIDTH
    if v < C.MIN_WIDTH then v = C.MIN_WIDTH end
    if v > C.MAX_WIDTH then v = C.MAX_WIDTH end
    return math.floor(v + 0.5)
end

function addon.GetBarWidth()
    local db = addon.GetDB()
    return addon.ClampBarWidth(db and db.barWidth or C.MIN_WIDTH)
end

function addon.ShowDefaultTooltip(text)
    if GameTooltip_SetDefaultAnchor then
        GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
    else
        GameTooltip:SetOwner(UIParent, "ANCHOR_NONE")
        GameTooltip:ClearAllPoints()
        GameTooltip:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -16, 64)
    end

    GameTooltip:SetText(text, 1, 1, 1)
    GameTooltip:Show()
end

function addon.GetActiveBuildInfo()
    local specIndex = GetSpecialization()
    local specID = specIndex and select(1, GetSpecializationInfo(specIndex)) or nil
    if not specID then
        return "No active specialization", nil
    end

    local starterBuildActive = (C_ClassTalents.GetStarterBuildActive and C_ClassTalents.GetStarterBuildActive()) or false
    if starterBuildActive then
        return "Starter Build", nil
    end

    local configID = (C_ClassTalents.GetLastSelectedSavedConfigID and C_ClassTalents.GetLastSelectedSavedConfigID(specID)) or nil
    if not configID then
        local configIDs = C_ClassTalents.GetConfigIDsBySpecID and C_ClassTalents.GetConfigIDsBySpecID(specID)
        if configIDs and #configIDs > 0 then
            configID = configIDs[1]
        end
    end

    if not configID then
        return "No saved build", nil
    end

    local configInfo = C_Traits.GetConfigInfo(configID)
    return (configInfo and configInfo.name) or "Unknown build", configID
end

function addon.GetActiveBuildName()
    local name = addon.GetActiveBuildInfo()
    return name
end

function addon.RegisterSlashCommands()
    if addon._slashRegistered then
        return
    end
    addon._slashRegistered = true

    SLASH_MATTSTALENTED1 = "/talented"
    SLASH_MATTSTALENTED2 = "/mt"
    SlashCmdList.MATTSTALENTED = function()
        if addon.OpenOptionsPanel then
            addon.OpenOptionsPanel()
            return
        end
        addon.Print("Options are not ready yet.")
    end
end
