local Text = require "widgets/text"
local HiBaseWidget = require "widgets/hi_base_widget"
local Widget = require "widgets/widget"

local HP_INNER_SIZE_X = 196
local HP_INNER_SIZE_Y = 46

local function GetHpScale(max_hp)
    return math.log(max_hp) / 10
end

local HiHpWidget = Class(HiBaseWidget, function(self, hp, max_hp)
    HiBaseWidget._ctor(self, "HiHpWidget")
    -- self:SetScaleMode(SCALEMODE_PROPORTIONAL)
    -- self:SetMaxPropUpscale(MAX_HUD_SCALE)
    self.offset = Vector3(0, -20, 0)
    self.scale = GetHpScale(max_hp)
    self.hp = hp
    self.image_bg = self:AddChild(Image("images/hpbar.xml", "HpBg.tex"))
    self.image = self:AddChild(Image("images/hpbar.xml", "HpRed.tex"))
    self.text = self:AddChild(Text(BODYTEXTFONT, 40, math.floor(hp), {1, 1, 1, 1}))
    self:SetScale(self.scale)
end)

function HiHpWidget:SetTarget(target)
    HiBaseWidget.SetTarget(self, target)
    if self.target:HasTag("Player") then
        self.image:SetTexture("images/hpbar.xml", "HpGreen.tex")
    end
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

return HiHpWidget
