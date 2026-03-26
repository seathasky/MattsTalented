-- Core/InstanceReminder.lua
local _, addon = ...

local function IsDungeonOrRaidInstance()
    local inInstance, instanceType = IsInInstance()
    if not inInstance then
        return false
    end
    return instanceType == "party" or instanceType == "raid"
end

local function GetCurrentInstanceKey()
    if not IsDungeonOrRaidInstance() then
        return nil
    end

    local name, instanceType, difficultyID, difficultyName, maxPlayers, dynamicDifficulty, isDynamic, mapID = GetInstanceInfo()
    if not mapID or mapID == 0 then
        return nil
    end

    return table.concat({
        tostring(mapID),
        tostring(difficultyID or 0),
        tostring(instanceType or ""),
    }, ":"),
    name or "Instance",
    difficultyName or "",
    maxPlayers or 0
end

local function EnsureReminderPopup()
    if addon.instanceReminderPopup then
        return addon.instanceReminderPopup
    end

    local frame = CreateFrame("Frame", "MattsTalentedInstanceReminderPopup", UIParent, "BackdropTemplate")
    frame:SetSize(520, 230)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 90)
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetFrameLevel(200)
    frame:EnableMouse(true)
    frame:SetMovable(false)
    frame:SetClampedToScreen(true)
    frame:Hide()
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    frame:SetBackdropColor(0.04, 0.05, 0.06, 0.95)
    frame:SetBackdropBorderColor(0.48, 0.44, 0.26, 1)

    local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -20)
    title:SetText("Talent Reminder")
    title:SetTextColor(0.88, 0.84, 0.74, 1)
    frame.titleText = title

    local body = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    body:SetPoint("TOPLEFT", frame, "TOPLEFT", 30, -62)
    body:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -30, -62)
    body:SetJustifyH("CENTER")
    body:SetJustifyV("MIDDLE")
    body:SetWordWrap(true)
    body:SetTextColor(0.73, 0.76, 0.80, 1)
    body:SetText("Double-check your loadout before first pull.")
    frame.bodyText = body

    local buildLabel = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    buildLabel:SetPoint("TOPLEFT", body, "BOTTOMLEFT", 0, -20)
    buildLabel:SetPoint("TOPRIGHT", body, "BOTTOMRIGHT", 0, -20)
    buildLabel:SetJustifyH("CENTER")
    buildLabel:SetFont(STANDARD_TEXT_FONT, 13, "")
    buildLabel:SetTextColor(0.70, 0.73, 0.78, 1)
    buildLabel:SetText("Current Talents")
    frame.buildLabelText = buildLabel

    local build = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    build:SetPoint("TOPLEFT", buildLabel, "BOTTOMLEFT", 0, -8)
    build:SetPoint("TOPRIGHT", buildLabel, "BOTTOMRIGHT", 0, -8)
    build:SetJustifyH("CENTER")
    build:SetFont(STANDARD_TEXT_FONT, 26, "OUTLINE")
    build:SetTextColor(0.98, 0.96, 0.90, 1)
    build:SetText("")
    frame.buildText = build

    local details = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    details:SetPoint("TOPLEFT", build, "BOTTOMLEFT", 0, -16)
    details:SetPoint("TOPRIGHT", build, "BOTTOMRIGHT", 0, -16)
    details:SetJustifyH("CENTER")
    details:SetFont(STANDARD_TEXT_FONT, 12, "")
    details:SetTextColor(0.65, 0.69, 0.75, 1)
    frame.detailsText = details

    local closeButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    closeButton:SetSize(220, 26)
    closeButton:SetPoint("BOTTOM", frame, "BOTTOM", 0, 18)
    closeButton:SetFrameStrata("FULLSCREEN_DIALOG")
    closeButton:SetFrameLevel(frame:GetFrameLevel() + 10)
    closeButton:EnableMouse(true)
    closeButton:RegisterForClicks("LeftButtonUp")
    closeButton:SetText("Close Until Next Time")
    closeButton:SetScript("OnClick", function()
        frame:Hide()
    end)

    addon.instanceReminderPopup = frame
    return frame
end

function addon.HideInstanceReminderPopup()
    if addon.instanceReminderPopup then
        addon.instanceReminderPopup:Hide()
    end
end

function addon.ShowInstanceReminderPopup(instanceName, difficultyName, maxPlayers)
    if not addon.IsInstanceReminderPopupEnabled or not addon.IsInstanceReminderPopupEnabled() then
        addon.HideInstanceReminderPopup()
        return
    end

    local frame = EnsureReminderPopup()
    local details = tostring(instanceName or "Instance")
    if difficultyName and difficultyName ~= "" then
        details = details .. " - " .. difficultyName
    end
    if maxPlayers and tonumber(maxPlayers) and tonumber(maxPlayers) > 0 then
        details = details .. " (" .. tostring(maxPlayers) .. " player)"
    end
    frame.detailsText:SetText(details)

    local buildName = addon.GetActiveBuildName and addon.GetActiveBuildName() or nil
    if buildName and buildName ~= "" then
        frame.buildText:SetText(tostring(buildName))
    else
        frame.buildText:SetText("Unknown")
    end

    frame:Show()
end

function addon.CheckInstanceReminderPopup()
    local instanceKey, instanceName, difficultyName, maxPlayers = GetCurrentInstanceKey()
    local db = addon.GetDB and addon.GetDB() or nil
    local previousInstanceKey = (db and db._lastShownInstanceReminderKey) or addon._activeDungeonRaidInstanceKey
    addon._activeDungeonRaidInstanceKey = instanceKey

    if not instanceKey then
        if db then
            db._lastShownInstanceReminderKey = nil
        end
        addon.HideInstanceReminderPopup()
        return
    end

    if previousInstanceKey == instanceKey then
        return
    end

    addon.ShowInstanceReminderPopup(instanceName, difficultyName, maxPlayers)
    if db then
        db._lastShownInstanceReminderKey = instanceKey
    end
end
