-- Core/Events.lua
local addonName, addon = ...

local C = addon.const

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")

local function IsPlayerCastingOrChanneling()
    if addon.IsPlayerCastingOrChanneling then
        return addon.IsPlayerCastingOrChanneling()
    end
    return UnitCastingInfo("player") ~= nil or UnitChannelInfo("player") ~= nil
end

local function RefreshBuildNameWhenReady(allowSound, retriesLeft)
    if IsPlayerCastingOrChanneling() then
        if (retriesLeft or 0) > 0 then
            C_Timer.After(0.20, function()
                RefreshBuildNameWhenReady(allowSound, (retriesLeft or 0) - 1)
            end)
        end
        return
    end

    addon.RefreshBuildName(allowSound)
end

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddonName = ...
        if loadedAddonName ~= addonName then
            return
        end

        addon.InitializeSavedVariables()
        addon.InitializeMainUI()
        if addon.InitializeOptions then
            addon.InitializeOptions()
        end
        if addon.RegisterSlashCommands then
            addon.RegisterSlashCommands()
        end
        if addon.EnsureTalentWindowHooks then
            addon.EnsureTalentWindowHooks()
        end
        addon._soundReady = false
        C_Timer.NewTicker(C.BUILD_REFRESH_INTERVAL, function()
            RefreshBuildNameWhenReady(true, 0)
        end)

        self:UnregisterEvent("ADDON_LOADED")
        return
    end

    if event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(0.5, function()
            RefreshBuildNameWhenReady(false, 5)
        end)
        C_Timer.After(2.0, function()
            addon._soundReady = true
        end)
        return
    end

    if event == "PLAYER_SPECIALIZATION_CHANGED" then
        local unit = ...
        if unit and unit ~= "player" then
            return
        end
        C_Timer.After(0.05, function()
            if addon.RefreshTalentWindowAppearance then
                addon.RefreshTalentWindowAppearance()
            end
            addon.RefreshBuildName(false)
        end)
        return
    end
end)
