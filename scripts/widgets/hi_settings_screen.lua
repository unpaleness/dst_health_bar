local Text = require "widgets/text"
local Screen = require "widgets/screen"
local TEMPLATES = require "widgets/redux/templates"

local PADDING_VERTICAL_BIG = 75
local PADDING_VERTICAL_SMALL = 50
local WIDTH = 800
local HEIGHT = 600
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
local VISIBILITIES_TITLE = "Health bar visibility"

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

local VISIBILITY_CHECKBOXES_DATA = {
    { text = "Me", offset_y = PADDING_VERTICAL_BIG },
    { text = "Other players", offset_y = PADDING_VERTICAL_SMALL },
    { text = "Bosses", offset_y = PADDING_VERTICAL_SMALL },
    { text = "Structures", offset_y = PADDING_VERTICAL_SMALL },
    { text = "Other entities", offset_y = PADDING_VERTICAL_SMALL },
    { text = "Walls, boats, bumpers", offset_y = PADDING_VERTICAL_SMALL },
    { text = "Enemies", offset_y = PADDING_VERTICAL_SMALL },
    { text = "Friends", offset_y = PADDING_VERTICAL_SMALL },
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
    local column1_y = self.size_y

    self.size_y = 0
    self:AddVisibilityCheckboxes()
    local column2_y = self.size_y

    self.size_y = math.max(column1_y, column2_y)

    -- Button close
    self.button_close = self:AddChild(TEMPLATES.StandardButton(
        function()
            self:Close()
        end, "Close", {150, 75}))
    self:RegisterElement(self.button_close, Vector3(0, PADDING_VERTICAL_BIG, 0))

    self:FinalizeElements()

    self.defaut_focus = self.button_close
    self.last_focus = self.button_close

    for i, v in ipairs(self.opacity_spinners) do
        if (i > 1) then
            v:SetFocusChangeDir(MOVE_UP, self.opacity_spinners[i - 1])
        end
        if (i < #self.opacity_spinners) then
            v:SetFocusChangeDir(MOVE_DOWN, self.opacity_spinners[i + 1])
        end
        if i == #self.opacity_spinners then
            v:SetFocusChangeDir(MOVE_DOWN, self.colour_spinners[1])
        end
        local right_index = (i < #self.visibility_checkboxes) and i or #self.visibility_checkboxes
        v:SetFocusChangeDir(MOVE_RIGHT, self.visibility_checkboxes[right_index])
    end

    for i, v in ipairs(self.colour_spinners) do
        if (i > 1) then
            v:SetFocusChangeDir(MOVE_UP, self.colour_spinners[i - 1])
        end
        if (i < #self.colour_spinners) then
            v:SetFocusChangeDir(MOVE_DOWN, self.colour_spinners[i + 1])
        end
        if i == #self.colour_spinners then
            v:SetFocusChangeDir(MOVE_DOWN, self.button_close)
        end
        if i == 1 then
            v:SetFocusChangeDir(MOVE_UP, self.opacity_spinners[#self.opacity_spinners])
        end
        local right_index = (i + #self.opacity_spinners < #self.visibility_checkboxes) and i + #self.opacity_spinners or #self.visibility_checkboxes
        v:SetFocusChangeDir(MOVE_RIGHT, self.visibility_checkboxes[right_index])
    end

    for i, v in ipairs(self.visibility_checkboxes) do
        if (i > 1) then
            v:SetFocusChangeDir(MOVE_UP, self.visibility_checkboxes[i - 1])
        end
        if (i < #self.visibility_checkboxes) then
            v:SetFocusChangeDir(MOVE_DOWN, self.visibility_checkboxes[i + 1])
        end
        if i == #self.visibility_checkboxes then
            v:SetFocusChangeDir(MOVE_DOWN, self.button_close)
        end
        local left_table = (i <= #self.opacity_spinners) and self.opacity_spinners or self.colour_spinners
        local left_index = (i <= #self.opacity_spinners) and i or ((i <= #self.opacity_spinners + #self.colour_spinners) and i - #self.opacity_spinners or #self.colour_spinners)
        v:SetFocusChangeDir(MOVE_LEFT, left_table[left_index])
    end

    self.button_close:SetFocusChangeDir(MOVE_LEFT, self.colour_spinners[#self.colour_spinners])
    self.button_close:SetFocusChangeDir(MOVE_RIGHT, self.visibility_checkboxes[#self.visibility_checkboxes])
    self.button_close:SetFocusChangeDir(MOVE_UP, self.colour_spinners[#self.colour_spinners])

    SetAutopaused(true)
end)

function HiSettingsScreen:Close()
    TheFrontEnd:PopScreen()
    SetAutopaused(false)
end

function HiSettingsScreen:AddOpacitySpinners()
    -- Title opacity
    local title = self:AddChild(Text(CHATFONT, FONT_SIZE, OPACITY_TITLE, UICOLOURS.GOLD))
    self:RegisterElement(title, Vector3(-200, 0, 0))

    self.opacity_spinners = {}
    for i, v in ipairs(OPACITY_SPINNDERS_DATA) do
        local spinner = self:AddChild(TEMPLATES.LabelSpinner(v.text, OPACITY_OPTIONS, 400, 150, nil, nil, nil, FONT_SIZE, -75))
        spinner.spinner:SetOnChangedFn(function(selected, old)
            HI_SETTINGS:SetOpacity(v.index, selected)
        end)
        spinner.spinner:SetSelected(HI_SETTINGS:GetOpacity(v.index))
        table.insert(self.opacity_spinners, spinner)
        self:RegisterElement(spinner, Vector3(-200, v.offset_y, 0))
    end
end

function HiSettingsScreen:AddColourSpinners()
    -- Title colour
    local title = self:AddChild(Text(CHATFONT, FONT_SIZE, COLOUR_TITLE, UICOLOURS.GOLD))
    self:RegisterElement(title, Vector3(-200, PADDING_VERTICAL_BIG, 0))

    self.colour_spinners = {}
    for i, v in ipairs(COLOUR_SPINNERS_DATA) do
        local spinner = self:AddChild(TEMPLATES.LabelSpinner(v.text, MakeColourOptions(), 400, 150, nil, nil, nil, FONT_SIZE, -75))
        spinner.spinner:SetOnChangedFn(function(selected, old)
            HI_SETTINGS:SetColourIndex(v.index, selected)
            spinner.spinner:SetTextColour(HI_SETTINGS:GetColour(v.index))
        end)
        spinner.spinner:SetSelected(HI_SETTINGS:GetColourIndex(v.index))
        spinner.spinner:SetTextColour(HI_SETTINGS:GetColour(v.index))
        table.insert(self.colour_spinners, spinner)
        self:RegisterElement(spinner, Vector3(-200, v.offset_y, 0))
    end
end

function HiSettingsScreen:AddVisibilityCheckboxes()
    -- Title visibilities
    local title = self:AddChild(Text(CHATFONT, FONT_SIZE, VISIBILITIES_TITLE, UICOLOURS.GOLD))
    self:RegisterElement(title, Vector3(200, 0, 0))

    self.visibility_checkboxes = {}
    for i, v in ipairs(VISIBILITY_CHECKBOXES_DATA) do
        local checkbox = self:AddChild(TEMPLATES.LabelCheckbox(function(w)
            local new_visibility = not HI_SETTINGS:GetVisibility(i)
            HI_SETTINGS:SetVisibility(i, new_visibility)
            w.checked = new_visibility
            w:Refresh()
        end, HI_SETTINGS:GetVisibility(i), v.text))
        table.insert(self.visibility_checkboxes, checkbox)
        self:RegisterElement(checkbox, Vector3(200, v.offset_y, 0))
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

function HiSettingsScreen:OnControl(control, down)
    if HiSettingsScreen._base.OnControl(self,control, down) then
        return true
    end
    if not down and control == CONTROL_CANCEL then
        self:Close()
    end
end

return HiSettingsScreen
