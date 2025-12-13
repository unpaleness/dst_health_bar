local Text = require "widgets/text"
local Screen = require "widgets/screen"
local TEMPLATES = require "widgets/redux/templates"

local PADDING_VERTICAL_BIG = 75
local PADDING_VERTICAL_SMALL = 50
local HEIGHT = 600
local COLUMN_WIDTH = 400
local COLUMNS_NUM = 3

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
local COLOUR_TITLE = "Colour"
local VISIBILITIES_TITLE = "Visibility"
local OTHERS_TITLE = "Logic"

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

local OTHER_CHECKBOXES_DATA = {
    { text = "Max health", offset_y = PADDING_VERTICAL_BIG },
    { text = "Only in battle", offset_y = PADDING_VERTICAL_SMALL },
    { text = "Player out of battle", offset_y = PADDING_VERTICAL_SMALL },
    { text = "Allies out of battle", offset_y = PADDING_VERTICAL_SMALL },
    { text = "Show on mouse over", offset_y = PADDING_VERTICAL_SMALL },
    { text = "Show vehicle health", offset_y = PADDING_VERTICAL_SMALL },
}

local FADE_ANIMATION_TIME_TEXT = "Fade anim"
local FADE_ANIMATION_TIME_DATA = {
    { text = "100ms", data = 0.1 },
    { text = "200ms", data = 0.2 },
    { text = "300ms", data = 0.3 },
    { text = "400ms", data = 0.4 },
    { text = "500ms", data = 0.5 },
}

local HIDE_OUT_OF_COMBAT_TIME_TEXT = "Hide out of combat"
local HIDE_OUT_OF_COMBAT_TIME_DATA = {
    { text = "0s", data = 0 },
    { text = "1s", data = 1 },
    { text = "2s", data = 2 },
    { text = "3s", data = 3 },
    { text = "4s", data = 4 },
}

local WIDGET_SCALE_TEXT = "Scale"
local WIDGET_SCALE_DATA = {
    { text = "50%",  data = 0.50 },
    { text = "75%",  data = 0.75 },
    { text = "100%", data = 1.00 },
    { text = "125%", data = 1.25 },
    { text = "150%", data = 1.50 },
    { text = "175%", data = 1.75 },
    { text = "200%", data = 2.00 },
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
    for i = 1, COLUMNS_NUM + 1 do
        table.insert(self.elements, {})
    end

    self.size_y = 0
    self:AddOpacitySpinners(1)
    self.size_y = self.size_y + PADDING_VERTICAL_BIG
    self:AddColourSpinners(1)
    local column1_y = self.size_y

    self.size_y = 0
    self:AddVisibilityCheckboxes(2)
    local column2_y = self.size_y

    self.size_y = 0
    self:AddOtherCheckboxes(3)
    self:AddFadeAnimationTimeSpinner(3)
    self:AddHideOutOfCombatTimeSpinner(3)
    self:AddWidgetScaleSpinner(3)
    local column3_y = self.size_y

    self.size_y = math.max(column1_y, column2_y, column3_y)

    -- Button close
    self.button_close = self:AddChild(TEMPLATES.StandardButton(
        function()
            self:Close()
        end, "Close", {150, 75}))
    self:RegisterElement(self.button_close, COLUMNS_NUM + 1, Vector3(0, PADDING_VERTICAL_BIG, 0))

    self:FinalizeElements()

    self.defaut_focus = self.button_close
    self.last_focus = self.button_close

    for j = 1, COLUMNS_NUM do
        for i, v in ipairs(self.elements[j]) do
            if i > 1 then
                v:SetFocusChangeDir(MOVE_UP, self.elements[j][i - 1])
            end
            if i < #self.elements[j] then
                v:SetFocusChangeDir(MOVE_DOWN, self.elements[j][i + 1])
            end
            if i == #self.elements[j] then
                v:SetFocusChangeDir(MOVE_DOWN, self.button_close)
            end
            if j > 1 then
                local left_index = (i < #self.elements[j - 1]) and i or #self.elements[j - 1]
                v:SetFocusChangeDir(MOVE_LEFT, self.elements[j - 1][left_index])
            end
            if j < COLUMNS_NUM then
                local right_index = (i < #self.elements[j + 1]) and i or #self.elements[j + 1]
                v:SetFocusChangeDir(MOVE_RIGHT, self.elements[j + 1][right_index])
            end
        end
    end

    local up_index = math.floor(COLUMNS_NUM / 2) + 1
    self.button_close:SetFocusChangeDir(MOVE_UP, self.elements[up_index][#self.elements[up_index]])
    if up_index > 1 then
        self.button_close:SetFocusChangeDir(MOVE_LEFT, self.elements[up_index - 1][#self.elements[up_index - 1]])
    end
    if up_index < COLUMNS_NUM then
        self.button_close:SetFocusChangeDir(MOVE_RIGHT, self.elements[up_index + 1][#self.elements[up_index + 1]])
    end

    SetAutopaused(true)
end)

function HiSettingsScreen:Close()
    HI_SETTINGS:Save()
    TheFrontEnd:PopScreen()
    SetAutopaused(false)
end

function HiSettingsScreen:AddOpacitySpinners(column)
    -- Title opacity
    local title = self:AddChild(Text(CHATFONT, FONT_SIZE, OPACITY_TITLE, UICOLOURS.GOLD))
    local offset_x = COLUMN_WIDTH * (column - 1 - (COLUMNS_NUM - 1) / 2)
    self:RegisterElement(title, COLUMNS_NUM + 1, Vector3(offset_x, 0, 0))

    for i, v in ipairs(OPACITY_SPINNDERS_DATA) do
        local spinner = self:AddChild(TEMPLATES.LabelSpinner(v.text, OPACITY_OPTIONS, 400, 150, nil, nil, nil, FONT_SIZE, -75))
        spinner.spinner:SetOnChangedFn(function(selected, old)
            HI_SETTINGS:SetOpacity(v.index, selected)
        end)
        spinner.spinner:SetSelected(HI_SETTINGS:GetOpacity(v.index))
        self:RegisterElement(spinner, column, Vector3(offset_x, v.offset_y, 0))
    end
end

function HiSettingsScreen:AddColourSpinners(column)
    -- Title colour
    local title = self:AddChild(Text(CHATFONT, FONT_SIZE, COLOUR_TITLE, UICOLOURS.GOLD))
    local offset_x = COLUMN_WIDTH * (column - 1 - (COLUMNS_NUM - 1) / 2)
    self:RegisterElement(title, COLUMNS_NUM + 1, Vector3(offset_x, 0, 0))

    for i, v in ipairs(COLOUR_SPINNERS_DATA) do
        local spinner = self:AddChild(TEMPLATES.LabelSpinner(v.text, MakeColourOptions(), 400, 150, nil, nil, nil, FONT_SIZE, -75))
        spinner.spinner:SetOnChangedFn(function(selected, old)
            HI_SETTINGS:SetColourIndex(v.index, selected)
            spinner.spinner:SetTextColour(HI_SETTINGS:GetColour(v.index))
        end)
        spinner.spinner:SetSelected(HI_SETTINGS:GetColourIndex(v.index))
        spinner.spinner:SetTextColour(HI_SETTINGS:GetColour(v.index))
        self:RegisterElement(spinner, column, Vector3(offset_x, v.offset_y, 0))
    end
end

function HiSettingsScreen:AddVisibilityCheckboxes(column)
    -- Title visibilities
    local title = self:AddChild(Text(CHATFONT, FONT_SIZE, VISIBILITIES_TITLE, UICOLOURS.GOLD))
    local offset_x = COLUMN_WIDTH * (column - 1 - (COLUMNS_NUM - 1) / 2)
    self:RegisterElement(title, COLUMNS_NUM + 1, Vector3(offset_x, 0, 0))

    for i, v in ipairs(VISIBILITY_CHECKBOXES_DATA) do
        local checkbox = self:AddChild(TEMPLATES.LabelCheckbox(function(w)
            local new_visibility = not HI_SETTINGS:GetVisibility(i)
            HI_SETTINGS:SetVisibility(i, new_visibility)
            w.checked = new_visibility
            w:Refresh()
        end, HI_SETTINGS:GetVisibility(i), v.text))
        self:RegisterElement(checkbox, column, Vector3(offset_x, v.offset_y, 0))
    end
end

function HiSettingsScreen:AddOtherCheckboxes(column)
    -- Title visibilities
    local title = self:AddChild(Text(CHATFONT, FONT_SIZE, OTHERS_TITLE, UICOLOURS.GOLD))
    local offset_x = COLUMN_WIDTH * (column - 1 - (COLUMNS_NUM - 1) / 2)
    self:RegisterElement(title, COLUMNS_NUM + 1, Vector3(offset_x, 0, 0))

    for i, v in ipairs(OTHER_CHECKBOXES_DATA) do
        local checkbox = self:AddChild(TEMPLATES.LabelCheckbox(function(w)
            local new_value = not HI_SETTINGS:GetOtherOption(i)
            HI_SETTINGS:SetOtherOption(i, new_value)
            w.checked = new_value
            w:Refresh()
        end, HI_SETTINGS:GetOtherOption(i), v.text))
        self:RegisterElement(checkbox, column, Vector3(offset_x, v.offset_y, 0))
    end
end

function HiSettingsScreen:AddFadeAnimationTimeSpinner(column)
    local spinner = self:AddChild(TEMPLATES.LabelSpinner(FADE_ANIMATION_TIME_TEXT, FADE_ANIMATION_TIME_DATA, 400, 150, nil, nil, nil, FONT_SIZE, -75))
    spinner.spinner:SetOnChangedFn(function(selected, old)
        HI_SETTINGS:SetFadeAnimationTime(selected)
    end)
    spinner.spinner:SetSelected(HI_SETTINGS:GetFadeAnimationTime())
    local offset_x = COLUMN_WIDTH * (column - 1 - (COLUMNS_NUM - 1) / 2)
    self:RegisterElement(spinner, column, Vector3(offset_x, PADDING_VERTICAL_SMALL, 0))
end

function HiSettingsScreen:AddHideOutOfCombatTimeSpinner(column)
    local spinner = self:AddChild(TEMPLATES.LabelSpinner(HIDE_OUT_OF_COMBAT_TIME_TEXT, HIDE_OUT_OF_COMBAT_TIME_DATA, 400, 150, nil, nil, nil, FONT_SIZE, -75))
    spinner.spinner:SetOnChangedFn(function(selected, old)
        HI_SETTINGS:SetHideOutOfCombatTime(selected)
    end)
    spinner.spinner:SetSelected(HI_SETTINGS:GetHideOutOfCombatTime())
    local offset_x = COLUMN_WIDTH * (column - 1 - (COLUMNS_NUM - 1) / 2)
    self:RegisterElement(spinner, column, Vector3(offset_x, PADDING_VERTICAL_SMALL, 0))
end

function HiSettingsScreen:AddWidgetScaleSpinner(column)
    local spinner = self:AddChild(TEMPLATES.LabelSpinner(WIDGET_SCALE_TEXT, WIDGET_SCALE_DATA, 400, 150, nil, nil, nil, FONT_SIZE, -75))
    spinner.spinner:SetOnChangedFn(function(selected, old)
        HI_SETTINGS:SetWidgetScale(selected)
    end)
    spinner.spinner:SetSelected(HI_SETTINGS:GetWidgetScale())
    local offset_x = COLUMN_WIDTH * (column - 1 - (COLUMNS_NUM - 1) / 2)
    self:RegisterElement(spinner, column, Vector3(offset_x, PADDING_VERTICAL_SMALL, 0))
end

function HiSettingsScreen:RegisterElement(element, column, offset)
    if element == nil then
        return
    end

    table.insert(self.elements[column], element)

    element:SetVAnchor(ANCHOR_MIDDLE)
    element:SetHAnchor(ANCHOR_MIDDLE)

    local element_position = offset or Vector3(0, 0, 0)
    self.size_y = self.size_y + element_position.y
    element_position.y = -self.size_y
    element:SetPosition(element_position)
end

function HiSettingsScreen:FinalizeElements()
    local center_y = self.size_y / 2
    for j = 1, COLUMNS_NUM + 1 do
        for i, element in ipairs(self.elements[j]) do
            local element_position = element:GetPosition()
            element_position.y = element_position.y + center_y
            element:SetPosition(element_position)
        end
    end
    self.bg:SetSize(COLUMN_WIDTH * COLUMNS_NUM, self.size_y + PADDING_VERTICAL_SMALL * 2)
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
