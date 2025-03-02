local Text = require "widgets/text"
local Screen = require "widgets/screen"
local TEMPLATES = require "widgets/redux/templates"

local PADDING_VERTICAL_BIG = 75
local PADDING_VERTICAL_SMALL = 50
local WIDTH = 600
local FONT_SIZE = 40
local OPACITY_OPTIONS = {
    { text = "0%",   data = 0.0 },
    { text = "10%",  data = 0.1 },
    { text = "20%",  data = 0.2 },
    { text = "30%",  data = 0.3 },
    { text = "40%",  data = 0.4 },
    { text = "50%",  data = 0.5 },
    { text = "60%",  data = 0.6 },
    { text = "70%",  data = 0.7 },
    { text = "80%",  data = 0.8 },
    { text = "90%",  data = 0.9 },
    { text = "100%", data = 1.0 },
}

local OPACITY_TITLE = "Opacity"
local COLOUR_TITLE = "Health bar colour"

local OPACITY_SPINNDERS_DATA = {
    { text = "Health number", index = 1, offset_y = PADDING_VERTICAL_BIG },
    { text = "Health bar",    index = 2, offset_y = PADDING_VERTICAL_SMALL },
    { text = "Damage number", index = 3, offset_y = PADDING_VERTICAL_SMALL },
}

local COLOUR_SPINNERS_DATA = {
    { text = "Neutral", index = 1, offset_y = PADDING_VERTICAL_BIG },
    { text = "Friend",  index = 2, offset_y = PADDING_VERTICAL_SMALL },
    { text = "Hostile", index = 3, offset_y = PADDING_VERTICAL_SMALL },
    { text = "Player",  index = 4, offset_y = PADDING_VERTICAL_SMALL },
}

local function MakeColourOptions()
    local options = {}
    for i, v in ipairs(HI_SETTINGS:GetAllColours()) do
        table.insert(options, { text = v.text, data = i })
    end
    return options
end

local HiSettingsScreen = Class(Screen, function(self)
    Screen._ctor(self, "HiSettingsScreen")
    self.bg = self:AddChild(TEMPLATES.RectangleWindow())
    self.bg:SetVAnchor(ANCHOR_MIDDLE)
    self.bg:SetHAnchor(ANCHOR_MIDDLE)
    self.elements = {}
    self.size_y = 0

    self:AddOpacitySpinners()
    self:AddColourSpinners()

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

function HiSettingsScreen:AddOpacitySpinners()
    -- Title opacity
    local title = self:AddChild(Text(CHATFONT, FONT_SIZE, OPACITY_TITLE, UICOLOURS.GOLD))
    self:RegisterElement(title, Vector3(0, 0, 0))

    self.opacity_spinners = {}
    for i, v in ipairs(OPACITY_SPINNDERS_DATA) do
        local spinner = self:AddChild(TEMPLATES.LabelSpinner(v.text, OPACITY_OPTIONS, 400, 150, nil, nil, nil, FONT_SIZE, -75))
        spinner.spinner:SetOnChangedFn(function(selected, old)
            HI_SETTINGS:SetOpacity(v.index, selected)
        end)
        spinner.spinner:SetSelected(HI_SETTINGS:GetOpacity(v.index))
        self:RegisterElement(spinner, Vector3(0, v.offset_y, 0))
    end
end

function HiSettingsScreen:AddColourSpinners()
    -- Title colour
    local title = self:AddChild(Text(CHATFONT, FONT_SIZE, COLOUR_TITLE, UICOLOURS.GOLD))
    self:RegisterElement(title, Vector3(0, PADDING_VERTICAL_BIG, 0))

    self.colour_spinners = {}
    for i, v in ipairs(COLOUR_SPINNERS_DATA) do
        local spinner = self:AddChild(TEMPLATES.LabelSpinner(v.text, MakeColourOptions(), 400, 150, nil, nil, nil, FONT_SIZE, -75))
        spinner.spinner:SetOnChangedFn(function(selected, old)
            HI_SETTINGS:SetColourIndex(v.index, selected)
            spinner.spinner:SetTextColour(HI_SETTINGS:GetColour(v.index))
        end)
        spinner.spinner:SetSelected(HI_SETTINGS:GetColourIndex(v.index))
        spinner.spinner:SetTextColour(HI_SETTINGS:GetColour(v.index))
        self:RegisterElement(spinner, Vector3(0, v.offset_y, 0))
    end
end

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
