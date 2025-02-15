local Text = require "widgets/text"
local HiBaseWidget = require "widgets/hi_base_widget"
local Widget = require "widgets/widget"

local HP_INNER_SIZE_X = 196
local HP_INNER_SIZE_Y = 46
local STATE_HOSTILE = 0
local STATE_FRIEND = 1
local STATE_NEUTRAL = 2
local STATE_PLAYER = 3
local TINT_HOSTILE = {0.75, 0.25, 0.25, 1}
local TINT_FRIEND = {0.25, 0.75, 0.25, 1}
local TINT_NEUTRAL = {0.75, 0.75, 0.75, 1}
local TINT_PLAYER = {0.25, 0.25, 0.75, 1}

local function SetTint(image, tint)
    image:SetTint(tint[1], tint[2], tint[3], tint[4])
end

local function GetHpScale(max_hp)
    local result = math.log(max_hp) / math.log(10) / 5
    return math.min(1, math.max(result, 0.1))
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
    self.image = self:AddChild(Image("images/hp_white.xml", "HpWhite.tex"))
    self.text = self:AddChild(Text(BODYTEXTFONT, 50, math.floor(hp), { 1, 1, 1, 1 }))
    self:UpdateHp(hp, max_hp)
    self:UpdateWhilePaused(false)
end)

function HiHpWidget:SetTarget(target)
    HiBaseWidget.SetTarget(self, target)
    self:UpdateState()
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
        self.image:SetPosition(HP_INNER_SIZE_X * 0.5 * (ratio - 1), 0, 0)
        self.image:SetScale(ratio, 1)
    end
    local new_scale = GetHpScale(max_hp)
    if new_scale ~= self.scale then
        self.scale = new_scale
        self:SetScale(self.scale)
    end
end

function HiHpWidget:UpdateState()
    local state = GetHpWidgetState(self.target)
    if state ~= self.state then
        self.state = state
        if self.state == STATE_PLAYER then
            SetTint(self.image, TINT_PLAYER)
        elseif self.state == STATE_HOSTILE then
            SetTint(self.image, TINT_HOSTILE)
        elseif self.state == STATE_FRIEND then
            SetTint(self.image, TINT_FRIEND)
        elseif self.state == STATE_NEUTRAL then
            SetTint(self.image, TINT_NEUTRAL)
        end
    end
end

return HiHpWidget
