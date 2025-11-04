local Widget = require "widgets/widget"

local HEIGHT_SCALE = 60

local function GetPosition(target)
    if target ~= nil and target:IsValid() then
        local height = 0
        -- local physics = target.Physics
        -- if physics then
        --     height = physics:GetHeight()
        -- end
        local x, y = TheSim:GetScreenPos(target:GetPosition():Get())
        return Vector3(x, y + height * HEIGHT_SCALE, 0)
    end
    return nil
end

local HiBaseWidget = Class(Widget, function(self)
    Widget._ctor(self, "HiBaseWidget")
	self.target = nil
    self.offset = Vector3(0, 0, 0)

    self:SetClickable(false)
    self:UpdateWhilePaused(false)
    self:StartUpdating()
end)

function HiBaseWidget:GetOffset()
    return self.offset
end

function HiBaseWidget:SetTarget(target)
    self.target = target
    self:OnUpdate(0)
end

function HiBaseWidget:OnUpdate(dt)
    local pos = GetPosition(self.target)
    -- if self.target.prefab == "frog" then
    --     print("HiBaseWidget:OnUpdate", self.target, pos or "<nil>")
    -- end
    if pos ~= nil then
        self:SetPosition(pos + self:GetOffset())
    end
end

return HiBaseWidget
