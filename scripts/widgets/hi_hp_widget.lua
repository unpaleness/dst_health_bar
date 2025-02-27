local Text = require "widgets/text"
local HiBaseWidget = require "widgets/hi_base_widget"
local Widget = require "widgets/widget"

local HP_INNER_SIZE_X = 284
local HP_INNER_SIZE_Y = 24
local IMAGE_SCALE = 0.5
local STATE_HOSTILE = 0
local STATE_FRIEND = 1
local STATE_NEUTRAL = 2
local STATE_PLAYER = 3
local FONT_SIZE = 50
local TINT_HOSTILE = {0.75, 0.25, 0.25, 1}
local TINT_FRIEND = {0.25, 0.75, 0.25, 1}
local TINT_NEUTRAL = {0.75, 0.75, 0.75, 1}
local TINT_PLAYER = {0.75, 0.25, 0.75, 1}

local function GetHpScale(value)
    -- Let's say 0.25 scale will be at value <= 1 and 1 scale will be at value >= 200
    local cap_min = 1
    local cap_max = 20000
    local result_min = 0.25
    local result_max = 1
    local clamped_value = math.min(cap_max, math.max(math.abs(value), cap_min))
    local result = math.log(clamped_value) / math.log(cap_max) * (result_max - result_min) + result_min
    -- print("GetHpScale: ", math.log(clamped_value), " / ", math.log(cap_max), " * " , (result_max - result_min), " + ", result_min, " = ", result)
    return result
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
    self.scale = 1
    self.hp = 0
    self.state = STATE_NEUTRAL
    self.image_bg = self:AddChild(Image("images/hp_bg.xml", "HpBg.tex"))
    self.image_bg:SetScale(IMAGE_SCALE)
    self.image = self:AddChild(Image("images/hp_white.xml", "HpWhite.tex"))
    self.image:SetScale(IMAGE_SCALE)
    self.text = self:AddChild(Text(BODYTEXTFONT, FONT_SIZE, math.floor(hp), { 1, 1, 1, 1 }))
    self.text:SetPosition(0, -FONT_SIZE / 1.5)
    self:SetOpacity(HI_SETTINGS.data.hp_bar_opacity)
    self:UpdateHp(hp, max_hp)
    self:UpdateWhilePaused(false)
end)

function HiHpWidget:SetOpacity(a)
    self.image_bg:SetFadeAlpha(a)
    self.image:SetFadeAlpha(a)
end

function HiHpWidget:SetImageTint(tint)
    self.image:SetTint(tint[1], tint[2], tint[3], tint[4])
end

function HiHpWidget:SetTarget(target)
    HiBaseWidget.SetTarget(self, target)
    self:UpdateState(true)
end

function HiHpWidget:Kill()
    self.image_bg:Kill()
    if self.image ~= nil then
        self.image:Kill()
    end
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
    if self.image ~= nil then
        local ratio = hp / max_hp
        self.image:SetPosition(HP_INNER_SIZE_X * 0.5 * (ratio - 1) * IMAGE_SCALE, 0, 0)
        self.image:SetScale(ratio * IMAGE_SCALE, IMAGE_SCALE)
    end
    local new_scale = GetHpScale(max_hp)
    if new_scale ~= self.scale then
        self.scale = new_scale
        self:SetScale(self.scale)
    end
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
        self:SetOpacity(HI_SETTINGS.data.hp_bar_opacity)
    end
end

function HiHpWidget:ApplySettings()
    self:SetOpacity(HI_SETTINGS.data.hp_bar_opacity)
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
