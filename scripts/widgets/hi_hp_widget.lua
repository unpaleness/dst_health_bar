local Text = require "widgets/text"
local HiBaseWidget = require "widgets/hi_base_widget"

local HiHpWidget = Class(HiBaseWidget, function(self, owner, hp)
    HiBaseWidget._ctor(self, "HiHpWidget")
	self.owner = owner
    self.offset = Vector3(0, -20, 0)
    self.text = self:AddChild(Text(BODYTEXTFONT, 40, math.floor(hp), {1, 1, 1, 1}))
    self:OnUpdate(0)
end)

function HiHpWidget:SetHp(hp)
    self.text:SetString(math.floor(hp))
end

return HiHpWidget
