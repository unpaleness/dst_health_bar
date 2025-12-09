local Widget = require "widgets/widget"

-- local HEIGHT_SCALE = 60

local HiBaseWidget = Class(Widget, function(self)
    Widget._ctor(self, "HiBaseWidget")
	self.target = nil
    self.targetLastPosition = nil
    self.offset = Vector3(0, 0, 0)

    self:SetClickable(false)
    self:UpdateWhilePaused(false)
    self:StartUpdating()
end)

function HiBaseWidget:GetPosition()
    if self.target ~= nil and self.target:IsValid() then
        self.targetLastPosition = self.target:GetPosition()
    end
    if self.targetLastPosition == nil then
        return nil
    end
    -- local height = 0
    -- local physics = target.Physics
    -- if physics then
    --     height = physics:GetHeight()
    -- end
    local x, y = TheSim:GetScreenPos(self.targetLastPosition:Get())
    -- return Vector3(x, y + height * HEIGHT_SCALE, 0)
    return Vector3(x, y, 0)
end

function HiBaseWidget:GetOffset()
    return self.offset
end

function HiBaseWidget:SetTarget(target)
    self.target = target
    self:OnUpdate(0)
end

function HiBaseWidget:OnUpdate(dt)
    local pos = self:GetPosition()
    if pos ~= nil then
        self:SetPosition(pos + self:GetOffset())
    end
end

return HiBaseWidget
