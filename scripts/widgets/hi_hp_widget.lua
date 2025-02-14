local Text = require "widgets/text"
local HiBaseWidget = require "widgets/hi_base_widget"
local Widget = require "widgets/widget"

local STATES = 4

local function GetHpState(hp, max_hp)
    return math.max(0, math.min(math.floor(hp * STATES / max_hp), STATES - 1))
end

local function GetHpScale(max_hp)
    return math.log(max_hp) / 10
end

local function GetImageName(state)
    return "icon-" .. tostring(state) .. ".tex"
end

local HiHpWidget = Class(HiBaseWidget, function(self, hp, max_hp)
    HiBaseWidget._ctor(self, "HiHpWidget")
    self.offset = Vector3(0, -20, 0)
    self.state = GetHpState(hp, max_hp)
    self.scale = GetHpScale(max_hp)
    self.hp = hp
    self.image = self:AddChild(Image("images/heart.xml", GetImageName(self.state)))
    self.text = self:AddChild(Text(BODYTEXTFONT, 40, math.floor(hp), {1, 1, 1, 1}))
    self:SetScale(self.scale)
end)

function HiHpWidget:Kill()
    self.image:Kill()
    self.text:Kill()
    Widget.Kill(self)
end

function HiHpWidget:UpdateHp(hp, max_hp)
    if hp ~= self.hp then
        self.hp = hp
        self.text:SetString(math.floor(self.hp))
    end
    local new_state = GetHpState(self.hp, max_hp)
    if new_state ~= self.state then
        self.state = new_state
        self.image:SetTexture("images/heart.xml", GetImageName(self.state))
    end
    local new_scale = GetHpScale(max_hp)
    if new_scale ~= self.scale then
        self.scale = new_scale
        self:SetScale(self.scale)
    end
end

return HiHpWidget
