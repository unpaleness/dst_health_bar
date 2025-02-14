local Widget = require "widgets/widget"

local function GetPosition(target)
    if target ~= nil and target:IsValid() and target.Transform ~= nil then
        local x, y = TheSim:GetScreenPos(target.Transform:GetWorldPosition())
        return Vector3(x, y, 0)
    end
    return nil
end

local HiBaseWidget = Class(Widget, function(self)
    Widget._ctor(self, "HiBaseWidget")
	self.target = nil
    self.offset = Vector3(0, 0, 0)

    self:UpdateWhilePaused(false)
    self:StartUpdating()
end)

function HiBaseWidget:SetTarget(target)
    self.target = target
end

function HiBaseWidget:OnUpdate(dt)
    local pos = GetPosition(self.target)
    if pos ~= nil then
        self:SetPosition(pos + self.offset)
        if not self.shown then
            self:Show()
        end
    else
        if self.shown then
            self:Hide()
        end
    end
end

return HiBaseWidget
