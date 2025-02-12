local Text = require "widgets/text"
local HiBaseWidget = require "widgets/hi_base_widget"

local LIFETIME = 1.0
local SPEED = 40.0

local HiDamageWidget = Class(HiBaseWidget, function(self, owner, damage)
    HiBaseWidget._ctor(self, "HiDamageWidget")
	self.owner = owner
    self.time = 0

    local random_angle = math.random() * math.pi * 2.0
    self.direction = Vector3(math.sin(random_angle), math.cos(random_angle), 0)

    if damage > 0 then
        self.text = self:AddChild(Text(BODYTEXTFONT, 40, math.ceil(damage), {0, 1, 0, 1}))
    else
        self.text = self:AddChild(Text(BODYTEXTFONT, 40, math.floor(damage), {1, 0, 0, 1}))
    end
end)

function HiDamageWidget:OnUpdate(dt)
    self.offset = self.offset + self.direction * dt * SPEED

    HiBaseWidget.OnUpdate(self, dt)

    self.time = self.time + dt
    if self.time > LIFETIME then
        self:Kill()
    end
end

return HiDamageWidget
