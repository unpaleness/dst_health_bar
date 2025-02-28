local Widget = require "widgets/widget"
local Text = require "widgets/text"
local HiBaseWidget = require "widgets/hi_base_widget"

local LIFETIME = 1.0
local SPEED = 100.0
local ACCELERATION = -100.0
local COLOR_DAMAGE = {1, 0, 0, 1}
local COLOR_HEAL = {0, 1, 0, 1}
local COLOR_BLOCKED = {1, 1, 1, 1}
local FONT_SIZE_MAX = 50
local FONT_SIZE_MIN = 10

local function GetFontSize(value)
    -- Let's say 0.25 scale will be at value <= 1 and 1 scale will be at value >= 200
    local cap_min = 1
    local cap_max = 200
    local result_min = 0.33
    local result_max = 1
    local clamped_value = math.min(cap_max, math.max(math.abs(value), cap_min))
    local scale = math.log(clamped_value) / math.log(cap_max) * (result_max - result_min) + result_min
    return math.max(math.floor(FONT_SIZE_MAX * scale), FONT_SIZE_MIN)
end

local function HiFormatFloat(value)
    local result = math.abs(value)
    -- if result < 1 then
    --     return math.floor(result * 1000 + 0.5) / 1000
    -- end
    return math.floor(result + 0.5)
end

local HiDamageWidget = Class(HiBaseWidget, function(self, hp_diff, type)
    HiBaseWidget._ctor(self, "HiDamageWidget")
    self.time = 0

    local random_angle = math.random() * math.pi
    self.direction = Vector3(math.cos(random_angle), math.sin(random_angle), 0)

    local formatted_hp_diff = HiFormatFloat(hp_diff)
    local hp_diff_string = formatted_hp_diff > 0 and tostring(formatted_hp_diff) or "."
    local value_color = COLOR_DAMAGE
    if type == "blocked" then
        value_color = COLOR_BLOCKED
        hp_diff_string = "BLOCKED " .. hp_diff_string
    elseif hp_diff > 0 then
        value_color = COLOR_HEAL
        hp_diff_string = "+" .. hp_diff_string
    end
    local font_size = GetFontSize(hp_diff)
    self.text = self:AddChild(Text(BODYTEXTFONT, font_size, hp_diff_string, value_color))
    self:UpdateWhilePaused(false)
end)

function HiDamageWidget:Kill()
    self.text:Kill()
    Widget.Kill(self)
end

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
