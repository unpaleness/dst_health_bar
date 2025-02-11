local Text = require "widgets/text"
local HiBaseWidget = require "widgets/hi_base_widget"

local LIFETIME = 1.0
local SPEED = 40.0

local HiDamageWidget = Class(HiBaseWidget, function(self, owner)
    HiBaseWidget._ctor(self, "HiDamageWidget")
	self.owner = owner
    self.text = self:AddChild(Text(TALKINGFONT, 30, "", {1, 0, 0, 1}))
    self.time = 0

    local random_angle = math.random() * math.pi * 2.0
    self.direction = Vector3(math.sin(random_angle), math.cos(random_angle), 0)
end)

function HiDamageWidget:SetHP(new_hp)
    local hp = new_hp or 0
    local hp = hp > 0 and math.ceil(hp) or math.floor(hp)
    self.text:SetString(hp)
    self:OnUpdate(0)
end

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
