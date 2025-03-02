local Text = require "widgets/text"
local HiBaseWidget = require "widgets/hi_base_widget"
local Widget = require "widgets/widget"
local NineSlice = require "widgets/nineslice"

local HP_SIZE_X = 150
local HP_SIZE_Y = 20
local BOX_BG_PADDING = 6
local BOX_INNER_PADDING = 6
local BOX_BG_MIN_SIZE = 6
local STATE_HOSTILE = 0
local STATE_FRIEND = 1
local STATE_NEUTRAL = 2
local STATE_PLAYER = 3
local FONT_SIZE_MAX = 50
local FONT_SIZE_MIN = 10
local TINT_HOSTILE = {0.75, 0.25, 0.25, 1}
local TINT_FRIEND = {0.25, 0.75, 0.25, 1}
local TINT_NEUTRAL = {0.75, 0.75, 0.75, 1}
local TINT_PLAYER = {0.75, 0.25, 0.75, 1}

local function GetScaledValues(value)
    -- Let's say 0.25 scale will be at value <= 1 and 1 scale will be at value >= 200
    local cap_min = 1
    local cap_max = 20000
    local result_min = 0.25
    local result_max = 1
    local clamped_value = math.min(cap_max, math.max(math.abs(value), cap_min))
    local scale = math.log(clamped_value) / math.log(cap_max) * (result_max - result_min) + result_min
    local scale_x = math.max(math.floor(HP_SIZE_X * scale), BOX_BG_MIN_SIZE)
    local scale_y = math.max(math.floor(HP_SIZE_Y * scale), BOX_BG_MIN_SIZE)
    local scale_font = math.max(math.floor(FONT_SIZE_MAX * scale), FONT_SIZE_MIN)
    return scale_x, scale_y, scale_font
end

local function GetHpWidgetState(target)
    if target:HasTag("player") then
        return STATE_PLAYER
    end
    local player_id = ThePlayer.userid
    local follow_target_value = target._hi_follow_target_replicated:value()
    if follow_target_value == player_id or target:HasTag("companion") then
        return STATE_FRIEND
    end
    local combat_target_value = target._hi_combat_target_replicated:value()
    if combat_target_value == player_id then
        return STATE_HOSTILE
    end

    return STATE_NEUTRAL
end

local HiHpWidget = Class(HiBaseWidget, function(self, hp, max_hp)
    HiBaseWidget._ctor(self, "HiHpWidget")
    self.offset = Vector3(0, -20, 0)
    self.hp_bar_size_x = HP_SIZE_X
    self.hp_bar_size_y = HP_SIZE_Y
    self.text_size = FONT_SIZE_MAX
    self.hp = 0
    self.state = STATE_NEUTRAL
    self.box_bg = self:AddChild(NineSlice("images/hp_bg.xml"))
    self.box_bg:SetSize(self.hp_bar_size_x - BOX_BG_PADDING, self.hp_bar_size_y - BOX_BG_PADDING)
    self.box = self:AddChild(NineSlice("images/hp_white.xml"))
    self.box:SetSize(self.hp_bar_size_x - BOX_INNER_PADDING, self.hp_bar_size_y - BOX_INNER_PADDING)
    self.text = self:AddChild(Text(BODYTEXTFONT, self.text_size, math.floor(hp), { 1, 1, 1, 1 }))
    self.text:SetPosition(0, -(self.hp_bar_size_y + self.text_size) * 0.5)
    self:SetHpBarOpacity(HI_SETTINGS.data.hp_bar_opacity)
    self:SetHpNumberOpacity(HI_SETTINGS.data.hp_number_opacity)
    self:UpdateHp(hp, max_hp)
    self:UpdateWhilePaused(false)
end)

function HiHpWidget:SetHpBarOpacity(a)
    self.box_bg:SetFadeAlpha(a)
    self.box:SetFadeAlpha(a)
end

function HiHpWidget:SetHpNumberOpacity(a)
    self.text:SetFadeAlpha(a)
end

function HiHpWidget:SetImageTint(tint)
    self.box:SetTint(tint[1], tint[2], tint[3], tint[4])
end

function HiHpWidget:SetTarget(target)
    HiBaseWidget.SetTarget(self, target)
    self:UpdateState(true)
end

function HiHpWidget:Kill()
    self.box_bg:Kill()
    self.box:Kill()
    self.text:Kill()
    Widget.Kill(self)
end

function HiHpWidget:UpdateHp(hp, max_hp)
    if hp ~= self.hp then
        self.hp = hp
        self.text:SetString(math.floor(self.hp))
    end
    if max_hp ~= nil and max_hp == 0 then
        print("HiHpWidget:UpdateHp: max_hp is 0")
        return
    end
    local x, y, text_size = GetScaledValues(max_hp)
    if self.hp_bar_size_x ~= x or self.hp_bar_size_y ~= y then
        self.hp_bar_size_x = x
        self.hp_bar_size_y = y
        self.text_size = text_size
        self.box_bg:SetSize(self.hp_bar_size_x - BOX_BG_PADDING, self.hp_bar_size_y - BOX_BG_PADDING)
        self.text:SetSize(self.text_size)
        self.text:SetPosition(0, -(self.hp_bar_size_y + self.text_size) * 0.5)
    end
    local hp_bar_filler_size_x = math.max((self.hp_bar_size_x - BOX_INNER_PADDING) * hp / max_hp, 0)
    self.box:SetPosition((BOX_INNER_PADDING - self.hp_bar_size_x + hp_bar_filler_size_x) * 0.5, 0, 0)
    self.box:SetSize(hp_bar_filler_size_x, self.hp_bar_size_y - BOX_INNER_PADDING)
end

function HiHpWidget:UpdateState(force)
    local state = GetHpWidgetState(self.target)
    if state ~= self.state or force then
        self.state = state
        if self.state == STATE_PLAYER then
            self:SetImageTint(TINT_PLAYER)
        elseif self.state == STATE_HOSTILE then
            self:SetImageTint(TINT_HOSTILE)
        elseif self.state == STATE_FRIEND then
            self:SetImageTint(TINT_FRIEND)
        elseif self.state == STATE_NEUTRAL then
            self:SetImageTint(TINT_NEUTRAL)
        end
    end
end

function HiHpWidget:ApplySettings()
    self:SetHpBarOpacity(HI_SETTINGS.data.hp_bar_opacity)
    self:SetHpNumberOpacity(HI_SETTINGS.data.hp_number_opacity)
end

function HiHpWidget:OnUpdate(dt)
    HiBaseWidget.OnUpdate(self, dt)

    local is_target_visible = CanEntitySeeTarget(ThePlayer, self.target)
    if is_target_visible then
        self:Show()
    else
        self:Hide()
    end
end

return HiHpWidget
