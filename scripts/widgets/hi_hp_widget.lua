local Text = require "widgets/text"
local HiBaseWidget = require "widgets/hi_base_widget"

local HiHpWidget = Class(HiBaseWidget, function(self, owner)
    HiBaseWidget._ctor(self, "HiHpWidget")
	self.owner = owner
    self.text = self:AddChild(Text(TALKINGFONT, 40, "", {0, 1, 0, 1}))
    self.old_hp = 0
    self.hp = 0
end)

function HiHpWidget:SetHp(new_hp)
    self.hp = new_hp or 0
    self:OnUpdate(0)
end

function HiHpWidget:OnUpdate(dt)
    HiBaseWidget.OnUpdate(self, dt)
    if self.old_hp ~= self.hp then
        self.text:SetString(math.floor(self.hp))
        self.old_hp = self.hp
    end
end

return HiHpWidget
