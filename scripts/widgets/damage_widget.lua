local Text = require "widgets/text"
local BaseWidget = require "widgets/base_widget"

local LIFETIME = 1.0
local SPEED = 40.0

local DamageWidget = Class(BaseWidget, function(self, owner)
    BaseWidget._ctor(self, "DamageWidget")
	self.owner = owner
    self.text = self:AddChild(Text(TALKINGFONT, 30, "", {1, 0, 0, 1}))
    self.time = 0

    local random_angle = math.random() * math.pi * 2.0
    self.direction = Vector3(math.sin(random_angle), math.cos(random_angle), 0)
end)

function DamageWidget:SetHP(new_hp)
    local hp = new_hp > 0 and math.ceil(new_hp) or math.floor(new_hp)
    self.text:SetString(hp)
    self:OnUpdate(0)
end

function DamageWidget:OnUpdate(dt)
    local local_dt = (dt ~= nil) and dt or 0
    self.offset = self.offset + self.direction * local_dt * SPEED

    BaseWidget.OnUpdate(self, dt)

    self.time = self.time + local_dt
    if self.time > LIFETIME then
        self:Kill()
    end
end

return DamageWidget
