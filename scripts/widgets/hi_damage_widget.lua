local Text = require "widgets/text"
local HiBaseWidget = require "widgets/hi_base_widget"

local LIFETIME = 1.0
local SPEED = 40.0

local HiDamageWidget = Class(HiBaseWidget, function(self, owner, damage)
    HiBaseWidget._ctor(self, "HiDamageWidget")
	self.owner = owner
    self.text = self:AddChild(Text(TALKINGFONT, 30, "", {1, 0, 0, 1}))
    self.time = 0

    local random_angle = math.random() * math.pi * 2.0
    self.direction = Vector3(math.sin(random_angle), math.cos(random_angle), 0)

    local d = damage or 0
    local d = d > 0 and math.ceil(d) or math.floor(d)
    self.text:SetString(d)
end)

function HiDamageWidget:OnUpdate(dt)
    local local_dt = (dt ~= nil) and dt or 0
    self.offset = self.offset + self.direction * local_dt * SPEED

    HiBaseWidget.OnUpdate(self, dt)

    self.time = self.time + local_dt
    if self.time > LIFETIME then
        self:Kill()
    end
end

return HiDamageWidget
