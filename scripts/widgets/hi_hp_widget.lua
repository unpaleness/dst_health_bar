local Text = require "widgets/text"
local HiBaseWidget = require "widgets/hi_base_widget"
local HiDamageWidget = require "widgets/hi_damage_widget"

local HiHpWidget = Class(HiBaseWidget, function(self, owner, hp)
    HiBaseWidget._ctor(self, "HiHpWidget")
	self.owner = owner
    self.old_hp = 0
    self.hp = hp
    self.offset = Vector3(0, -20, 0)
    self.text = self:AddChild(Text(BODYTEXTFONT, 40, math.floor(self.hp), {1, 1, 1, 1}))
end)

function HiHpWidget:SetHp(new_hp)
    self.old_hp = self.hp
    self.hp = new_hp or 0
    if self.old_hp ~= self.hp then
        self.text:SetString(math.floor(self.hp))
        if not TheNet:IsDedicated() and ThePlayer ~= nil then
            ThePlayer.HUD.overlayroot:AddChild(HiDamageWidget(self.owner, self.hp - self.old_hp))
        end
    end
end

function HiHpWidget:OnUpdate(dt)
    HiBaseWidget.OnUpdate(self, dt)
end

return HiHpWidget
