local Text = require "widgets/text"
local BaseWidget = require "widgets/base_widget"

local HpWidget = Class(BaseWidget, function(self, owner)
    BaseWidget._ctor(self, "HpWidget")
	self.owner = owner
    self.text = self:AddChild(Text(TALKINGFONT, 40, "", {0, 1, 0, 1}))
    self.old_hp = 0
    self.hp = 0
end)

function HpWidget:SetHP(new_hp)
    self.hp = new_hp
    self:OnUpdate(0)
end

function HpWidget:OnUpdate(dt)
    BaseWidget.OnUpdate(self, dt)
    if self.old_hp ~= self.hp then
        self.text:SetString(math.floor(self.hp))
        self.old_hp = self.hp
    end
end

return HpWidget
