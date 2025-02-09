local Text = require "widgets/text"
local Widget = require "widgets/widget"

local HpWidget = Class(Widget, function(self, owner)
    Widget._ctor(self, "HpWidget")
	self.owner = owner
    self.text = self:AddChild(Text(TALKINGFONT, 40, "", {0, 1, 0, 1}))
    self.offset = Vector3(0, 0, 0)
    self.screen_offset = Vector3(0, 0, 0)
    self.old_hp = 0
    self.hp = 0

    self:Show()
    self:StartUpdating()
end)

function HpWidget:SetTarget(target)
    self.target = target
    self:OnUpdate()
end

function HpWidget:SetOffset(offset)
    self.offset = offset
    self:OnUpdate()
end

function HpWidget:SetScreenOffset(x,y)
    self.screen_offset.x = x
    self.screen_offset.y = y
    self:OnUpdate()
end

function HpWidget:SetHP(new_hp)
    self.hp = new_hp
    self:OnUpdate()
end

function HpWidget:GetScreenOffset()
    return self.screen_offset.x, self.screen_offset.y
end

function HpWidget:OnUpdate(dt)
    if self.target ~= nil and self.target:IsValid() then
	    print("HpWidget:OnUpdate ", self.target, ": ", self.target.components.health.currenthealth)
        local x, y
        if self.target.AnimState ~= nil then
            x, y = TheSim:GetScreenPos(self.target.AnimState:GetSymbolPosition(self.symbol or "", self.offset.x, self.offset.y, self.offset.z))
        else
            x, y = TheSim:GetScreenPos(self.target.Transform:GetWorldPosition())
        end
        self:SetPosition(x + self.screen_offset.x, y + self.screen_offset.y, 0)
        if self.old_hp ~= self.hp then
            self.text:SetString(self.hp)
            self.old_hp = self.hp
        end
    end
end

return HpWidget
