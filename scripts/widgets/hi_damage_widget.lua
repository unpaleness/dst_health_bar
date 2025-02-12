local Text = require "widgets/text"
local HiBaseWidget = require "widgets/hi_base_widget"

local LIFETIME = 1.0
local SPEED = 100.0
local ACCELERATION = -100.0
local COLOR_DAMAGE = {1, 0, 0, 1}
local COLOR_HEAL = {0, 1, 0, 1}

local HiDamageWidget = Class(HiBaseWidget, function(self, owner, hp_diff)
    HiBaseWidget._ctor(self, "HiDamageWidget")
	self.owner = owner
    self.time = 0

    local random_angle = math.random() * math.pi
    self.direction = Vector3(math.cos(random_angle), math.sin(random_angle), 0)

    local hp_diff_string = tostring(math.ceil(math.abs(hp_diff)))
    local value_color = COLOR_DAMAGE
    if hp_diff > 0 then
        value_color = COLOR_HEAL
        hp_diff_string = "+" .. hp_diff_string
    end
    self.text = self:AddChild(Text(BODYTEXTFONT, 40, hp_diff_string, value_color))
    self:OnUpdate(0)
end)

function HiDamageWidget:OnUpdate(dt)
    self.time = self.time + dt
    local delta = Vector3(self.direction.x * dt * SPEED, dt * (self.direction.y * SPEED + ACCELERATION * self.time), 0)
    self.offset = self.offset + delta

    HiBaseWidget.OnUpdate(self, dt)

    self.time = self.time + dt
    if self.time > LIFETIME then
        self:Kill()
    end
end

return HiDamageWidget
