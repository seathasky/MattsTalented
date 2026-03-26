-- MattsTalentedDefaults.lua
local _, addon = ...

addon.defaults = {
    Const = {
        DB_NAME = "MattsTalentedDB",
        MIN_WIDTH = 180,
        MAX_WIDTH = 300,
        ADDON_FONT = "Interface\\AddOns\\MattsTalented\\Media\\Fonts\\MattFave.ttf",
        TALENT_CHANGE_SOUND = "Interface\\AddOns\\MattsTalented\\Media\\Audio\\tc.mp3",
        FRAME_HEIGHT = 30,
        TITLE_HEIGHT = 20,
        OPTIONS_ROW_HEIGHT = 24,
        HOVER_UPDATE_INTERVAL = 0.05,
        BUILD_REFRESH_INTERVAL = 1.0,
    },
    SavedVariables = {
        point = "CENTER",
        relativePoint = "CENTER",
        xOfs = 0,
        yOfs = 0,
        hideMainBar = false,
        useMinimalTheme = true,
        scaleTalentWindow = true,
        disableAudio = false,
        showEquipmentBar = true,
        showLineTitles = true,
        showBarIcons = true,
        showInstanceReminderPopup = true,
        mainFrameScale = 1.0,
        textStyle = 5,
        barWidth = 180,
        bgAlphaPercent = 55,
        textColorR = 0.92,
        textColorG = 0.94,
        textColorB = 0.96,
        minimap = {
            hide = false,
        },
    },
}
