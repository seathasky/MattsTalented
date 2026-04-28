-- MattsTalented.lua
local addonName, addon = ...

addon.name = addonName

local defaultsRoot = addon.defaults or {}
local const = defaultsRoot.Const or {}

addon.const = {
    DB_NAME = const.DB_NAME or "MattsTalentedDB",
    MIN_WIDTH = const.MIN_WIDTH or 180,
    MAX_WIDTH = const.MAX_WIDTH or 300,
    ADDON_FONT = const.ADDON_FONT or "Interface\\AddOns\\MattsTalented\\Media\\Fonts\\MattFave.ttf",
    TALENT_CHANGE_SOUND = const.TALENT_CHANGE_SOUND or "Interface\\AddOns\\MattsTalented\\Media\\Audio\\tc.mp3",
    FRAME_HEIGHT = const.FRAME_HEIGHT or 30,
    TITLE_HEIGHT = const.TITLE_HEIGHT or 20,
    OPTIONS_ROW_HEIGHT = const.OPTIONS_ROW_HEIGHT or 24,
    HOVER_UPDATE_INTERVAL = const.HOVER_UPDATE_INTERVAL or 0.05,
    BUILD_REFRESH_INTERVAL = const.BUILD_REFRESH_INTERVAL or 1.0,
}

addon.svDefaults = defaultsRoot.SavedVariables or {}
addon.stylePresets = {
    { font = "blizzard", justify = "LEFT", label = "Left Blizzard" },
    { font = "blizzard", justify = "CENTER", label = "Center Blizzard" },
    { font = "blizzard", justify = "RIGHT", label = "Right Blizzard" },
    { font = "addon", justify = "LEFT", label = "Left Matt" },
    { font = "addon", justify = "CENTER", label = "Center Matt" },
    { font = "addon", justify = "RIGHT", label = "Right Matt" },
}
