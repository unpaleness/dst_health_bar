local Widget = require "widgets/widget"
local HiSettingsScreen = require "widgets/hi_settings_screen"
local TEMPLATES = require "widgets/redux/templates"

local HiSettingsButtonWidget = Class(Widget, function(self)
    Widget._ctor(self, "HiSettingsButtonWidget")
    self.button = self:AddChild(TEMPLATES.StandardButton(
        function()
            HI_SETTINGS:Load()
            local settings_screen = HiSettingsScreen()
            ThePlayer.HUD:OpenScreenUnderPause(settings_screen)
        end, "HI", {50, 50}))
    self.button:SetPosition(25, -25)
end)

return HiSettingsButtonWidget
