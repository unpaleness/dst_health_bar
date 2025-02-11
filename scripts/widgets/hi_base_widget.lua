local Widget = require "widgets/widget"

local HiBaseWidget = Class(Widget, function(self, owner)
    Widget._ctor(self, "HiBaseWidget")
	self.owner = owner
    self.offset = Vector3(0, 0, 0)
    self.screen_offset = Vector3(0, 0, 0)

    self:Show()
    self:StartUpdating()
end)

function HiBaseWidget:SetOffset(offset)
    self.offset = offset
    self:OnUpdate(0)
end

function HiBaseWidget:SetScreenOffset(x,y)
    self.screen_offset.x = x
    self.screen_offset.y = y
    self:OnUpdate(0)
end

function HiBaseWidget:GetScreenOffset()
    return self.screen_offset.x, self.screen_offset.y
end

function HiBaseWidget:OnUpdate(dt)
    if self.owner ~= nil and self.owner:IsValid() and self.owner.Transform ~= nil then
        local x, y = TheSim:GetScreenPos(self.owner.Transform:GetWorldPosition())
        local pos = Vector3(x, y, 0)
        self:SetPosition(pos + self.screen_offset + self.offset)
    end
end

return HiBaseWidget
