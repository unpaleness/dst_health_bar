local Text = require "widgets/text"
local Screen = require "widgets/screen"
local TEMPLATES = require "widgets/redux/templates"

local PADDING_VERTICAL_BIG = 75
local PADDING_VERTICAL_SMALL = 50
local WIDTH = 600
local FONT_SIZE = 40
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
local OPACITY_TITLE = "Opacity"
local HP_NUMBER_OPACITY_TITLE = "HP number opacity"
local HP_BAR_OPACITY_TITLE = "HP bar opacity"
local DAMAGE_NUMBER_OPACITY_TITLE = "Damage number opacity"

local HiSettingsScreen = Class(Screen, function(self)
    Screen._ctor(self, "HiSettingsScreen")
    self.bg = self:AddChild(TEMPLATES.RectangleWindow())
    self.bg:SetVAnchor(ANCHOR_MIDDLE)
    self.bg:SetHAnchor(ANCHOR_MIDDLE)
    self.elements = {}
    self.size_y = 0

    -- Title opacity
    self.title_opacity = self:AddChild(Text(CHATFONT, FONT_SIZE, OPACITY_TITLE, UICOLOURS.GOLD))
    self:RegisterElement(self.title_opacity, Vector3(0, 0, 0))

    -- Spinner hp number opacity
    self.spinner_hp_number_opacity = self:AddChild(TEMPLATES.LabelSpinner(HP_NUMBER_OPACITY_TITLE, OPACITY_OPTIONS, 400, 150, nil, nil, nil, FONT_SIZE, -75, function(selected, old)
        HI_SETTINGS.data.hp_number_opacity = selected
    end))
    self.spinner_hp_number_opacity.spinner:SetSelected(HI_SETTINGS.data.hp_number_opacity)
    self:RegisterElement(self.spinner_hp_number_opacity, Vector3(0, PADDING_VERTICAL_BIG, 0))

    -- Spinner hp bar opacity
    self.spinner_hp_bar_opacity = self:AddChild(TEMPLATES.LabelSpinner(HP_BAR_OPACITY_TITLE, OPACITY_OPTIONS, 400, 150, nil, nil, nil, FONT_SIZE, -75, function(selected, old)
        HI_SETTINGS.data.hp_bar_opacity = selected
    end))
    self.spinner_hp_bar_opacity.spinner:SetSelected(HI_SETTINGS.data.hp_bar_opacity)
    self:RegisterElement(self.spinner_hp_bar_opacity, Vector3(0, PADDING_VERTICAL_SMALL, 0))

    -- Spinner damage number opacity
    self.spinner_damage_number_opacity = self:AddChild(TEMPLATES.LabelSpinner(DAMAGE_NUMBER_OPACITY_TITLE, OPACITY_OPTIONS, 400, 150, nil, nil, nil, FONT_SIZE, -75, function(selected, old)
        HI_SETTINGS.data.damage_number_opacity = selected
    end))
    self.spinner_damage_number_opacity.spinner:SetSelected(HI_SETTINGS.data.damage_number_opacity)
    self:RegisterElement(self.spinner_damage_number_opacity, Vector3(0, PADDING_VERTICAL_SMALL, 0))

    -- Button apply
    self.button_apply = self:AddChild(TEMPLATES.StandardButton(
        function()
            HI_SETTINGS:Save()
        end, "Apply", {150, 75}))
    self:RegisterElement(self.button_apply, Vector3(-100, PADDING_VERTICAL_BIG, 0))

    self.size_y = self.size_y - PADDING_VERTICAL_BIG

    -- Button close
    self.button_close = self:AddChild(TEMPLATES.StandardButton(
        function()
            TheFrontEnd:PopScreen()
            SetAutopaused(false)
        end, "Close", {150, 75}))
    self:RegisterElement(self.button_close, Vector3(100, PADDING_VERTICAL_BIG, 0))

    self:FinalizeElements()

    SetAutopaused(true)
end)

function HiSettingsScreen:RegisterElement(element, offset)
    if element == nil then
        return
    end

    table.insert(self.elements, element)

    element:SetVAnchor(ANCHOR_MIDDLE)
    element:SetHAnchor(ANCHOR_MIDDLE)

    local element_position = offset or Vector3(0, 0, 0)
    self.size_y = self.size_y + element_position.y
    element_position.y = -self.size_y
    element:SetPosition(element_position)
end

function HiSettingsScreen:FinalizeElements()
    local center_y = self.size_y / 2
    for i, element in ipairs(self.elements) do
        local element_position = element:GetPosition()
        element_position.y = element_position.y + center_y
        element:SetPosition(element_position)
    end
    self.bg:SetSize(WIDTH, self.size_y + PADDING_VERTICAL_SMALL * 2)
end

return HiSettingsScreen
