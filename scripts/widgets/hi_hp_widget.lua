local Text = require "widgets/text"
local HiBaseWidget = require "widgets/hi_base_widget"
local Widget = require "widgets/widget"

local HP_INNER_SIZE_X = 196
local HP_INNER_SIZE_Y = 46
local STATE_HOSTILE = 0
local STATE_FRIEND = 1
local STATE_NEUTRAL = 2
local STATE_HIDDEN = 3

local function GetHpScale(max_hp)
    local result = math.log(max_hp) / 10
    return math.max(result, 0.1)
end

local function GetHpWidgetState(target)
    -- if target:HasTag("hostile")
    --     or target:HasTag("monster")
    --     or target:HasTag("epic")
    -- then
    --     return STATE_HOSTILE
    -- elseif target:HasTag("companion")
    --     or target:HasTag("pet")
    --     or target:HasTag("player")
    -- then
    --     return STATE_FRIEND
    -- end
    local combat_target_value = target._hi_combat_target_repicated:value()
    -- print("GetHpWidgetState: {", target, "}: target: ", combat_target_value, ", player: ", ThePlayer.GUID)
    if combat_target_value ~= nil and combat_target_value == ThePlayer.GUID then
        return STATE_HOSTILE
    else
        return STATE_FRIEND
    end

    return STATE_HIDDEN
end

local HiHpWidget = Class(HiBaseWidget, function(self, hp, max_hp)
    HiBaseWidget._ctor(self, "HiHpWidget")
    -- self:SetScaleMode(SCALEMODE_PROPORTIONAL)
    -- self:SetMaxPropUpscale(MAX_HUD_SCALE)
    self.offset = Vector3(0, -20, 0)
    self.scale = 1
    self.hp = 0
    self.state = STATE_HIDDEN
    self.image_bg = self:AddChild(Image("images/hpbar.xml", "HpBg.tex"))
    self.image = self:AddChild(Image("images/hpbar.xml", "HpRed.tex"))
    self.text = self:AddChild(Text(BODYTEXTFONT, 40, math.floor(hp), { 1, 1, 1, 1 }))
    self:UpdateHp(hp, max_hp)
    self:Hide()
    self:UpdateWhilePaused(false)
end)

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

function HiHpWidget:OnUpdate(dt)
    HiBaseWidget.OnUpdate(self, dt)
    local state = GetHpWidgetState(self.target)
    if state ~= self.state then
        self.state = state
        if self.state == STATE_HOSTILE then
            self.image:SetTexture("images/hpbar.xml", "HpRed.tex")
            self:Show()
        elseif self.state == STATE_FRIEND then
            self.image:SetTexture("images/hpbar.xml", "HpGreen.tex")
            self:Show()
        elseif self.state == STATE_NEUTRAL then
            self.image:SetTexture("images/hpbar.xml", "HpGreen.tex")
            self:Show()
        else
            self:Hide()
        end
    end
end

return HiHpWidget
