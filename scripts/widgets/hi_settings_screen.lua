local Screen = require "widgets/screen"
local TEMPLATES = require "widgets/redux/templates"

local OPACITY_OPTIONS = {
    { text = "0%",   data = 0 },
    { text = "10%",  data = 0.1 },
    { text = "20%",  data = 0.2 },
    { text = "30%",  data = 0.3 },
    { text = "40%",  data = 0.4 },
    { text = "50%",  data = 0.5 },
    { text = "60%",  data = 0.6 },
    { text = "70%",  data = 0.7 },
    { text = "80%",  data = 0.8 },
    { text = "90%",  data = 0.9 },
    { text = "100%", data = 1 },
}

local HiSettingsScreen = Class(Screen, function(self)
    Screen._ctor(self, "HiSettingsScreen")
	self.root = self:AddChild(TEMPLATES.ScreenRoot("HiSettingsScreenRoot"))
    self.settings = {}
    self.root.spinner_hp_bar_opacity = self:AddChild(TEMPLATES.LabelSpinner("Health bar opacity", OPACITY_OPTIONS, nil, nil, 50, nil, nil, nil, nil, function(selected, old)
        -- print("HiSettingsScreen.spinner_hp_bar_opacity changed: ", selected and selected or "<nil>", old and old or "<nil>")
        HI_SETTINGS.data.hp_bar_opacity = selected
    end))
    self.root.spinner_hp_bar_opacity:SetVAnchor(ANCHOR_MIDDLE)
    self.root.spinner_hp_bar_opacity:SetHAnchor(ANCHOR_MIDDLE)
    self.root.spinner_hp_bar_opacity:SetPosition(0, 50)
    self.root.spinner_hp_bar_opacity.spinner:SetSelected(HI_SETTINGS.data.hp_bar_opacity)
    self.root.button_apply = self:AddChild(TEMPLATES.StandardButton(
        function()
            HI_SETTINGS:Save()
        end, "Apply", {100, 50}))
    self.root.button_apply:SetVAnchor(ANCHOR_MIDDLE)
    self.root.button_apply:SetHAnchor(ANCHOR_MIDDLE)
    self.root.button_apply:SetPosition(-75, 0)
    self.root.button_close = self:AddChild(TEMPLATES.StandardButton(
        function()
            TheFrontEnd:PopScreen()
            SetAutopaused(false)
        end, "Close", {100, 50}))
    self.root.button_close:SetVAnchor(ANCHOR_MIDDLE)
    self.root.button_close:SetHAnchor(ANCHOR_MIDDLE)
    self.root.button_close:SetPosition(75, 0)
    SetAutopaused(true)
end)

return HiSettingsScreen
