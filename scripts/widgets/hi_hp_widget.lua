local Text = require "widgets/text"
local HiBaseWidget = require "widgets/hi_base_widget"
local Widget = require "widgets/widget"
local NineSlice = require "widgets/nineslice"

local HP_SIZE_X = 150
local HP_SIZE_Y = 20
local BOX_BG_PADDING = 6
local BOX_INNER_PADDING = 6
local BOX_BG_MIN_SIZE = 6
local HP_WIDGET_OFFSET = Vector3(0, -20, 0)
local HP_WIDGET_RIDER_OFFSET = Vector3(0, 50, 0)

local STATE_NEUTRAL = 1
local STATE_FRIEND = 2
local STATE_HOSTILE = 3
local STATE_PLAYER = 4

local VISIBILITY_INDEX_ME = 1
local VISIBILITY_INDEX_OTHER_PLAYER = 2
local VISIBILITY_INDEX_BOSS = 3
local VISIBILITY_INDEX_STRUCTURE = 4
local VISIBILITY_INDEX_OTHER = 5
local VISIBILITY_INDEX_WALL_BOAT = 6
local VISIBILITY_INDEX_HOSTILE = 7
local VISIBILITY_INDEX_FRIEND = 8

local SHOW_MAX_HP = 1
local SHOW_ONLY_IN_COMBAT = 2

local FONT_SIZE_MAX = 50
local FONT_SIZE_MIN = 10

local function GetScaledValues(value)
    -- Let's say 0.25 scale will be at value <= 1 and 1 scale will be at value >= 200
    local cap_min = 1
    local cap_max = 20000
    local result_min = 0.25
    local result_max = 1
    -- local clamped_value = math.min(cap_max, math.max(math.abs(value), cap_min))
    local clamped_value = math.clamp(math.abs(value), cap_min, cap_max)
    local scale = math.log(clamped_value) / math.log(cap_max) * (result_max - result_min) + result_min
    local scale_x = math.max(math.floor(HP_SIZE_X * scale), BOX_BG_MIN_SIZE)
    local scale_y = math.max(math.floor(HP_SIZE_Y * scale), BOX_BG_MIN_SIZE)
    local scale_font = math.max(math.floor(FONT_SIZE_MAX * scale), FONT_SIZE_MIN)
    return scale_x, scale_y, scale_font
end

local function GetHpWidgetState(target)
    if target == nil then
        return STATE_NEUTRAL
    end
    if target:HasTag("player") then
        return STATE_PLAYER
    end
    local playerGuid = ThePlayer and ThePlayer._hiServerGuidReplicated:value() or 0
    local combatTargetGuid = target._hiCombatTargetGuidReplicated:value()
    if combatTargetGuid == playerGuid then
        return STATE_HOSTILE
    end
    local followTargetGuid = target._hiFollowTargetGuidReplicated:value()
    if followTargetGuid == playerGuid or target:HasTag("companion") then
        return STATE_FRIEND
    end

    return STATE_NEUTRAL
end

local HiHpWidget = Class(HiBaseWidget, function(self, hp, maxHp)
    HiBaseWidget._ctor(self, "HiHpWidget")
    self.offset = HP_WIDGET_OFFSET
    self.hpBarSizeX = HP_SIZE_X
    self.hpBarSizeY = HP_SIZE_Y
    self.textSize = FONT_SIZE_MAX
    self.hp = 0
    self.maxHp = 0
    self.state = STATE_NEUTRAL
    self.isBoss = false
    self.isStructure = false
    self.isWallOrBoat = false
    self.isRider = false
    self.isVisibleBySettings = true
    self.showOnlyInCombat = false
    self.isToRemove = false
    -- for showOnlyInCombat mode
    self.isAttacking = false
    self.attackersNum = 0
    self.isRided = false
    self.hideHpTimeout = 2
    self.LastCombatActionTs = -math.huge
    --
    -- animation
    self.fadeAnimTime = 0.5
    self.fadeOpacity = 0
    --
    self.boxBg = self:AddChild(NineSlice("images/hp_bg.xml"))
    self.boxBg:SetSize(self.hpBarSizeX - BOX_BG_PADDING, self.hpBarSizeY - BOX_BG_PADDING)
    self.box = self:AddChild(NineSlice("images/hp_white.xml"))
    self.box:SetSize(self.hpBarSizeX - BOX_INNER_PADDING, self.hpBarSizeY - BOX_INNER_PADDING)
    self.text = self:AddChild(Text(BODYTEXTFONT, self.textSize, math.floor(hp), { 1, 1, 1, 1 }))
    self.text:SetPosition(0, -(self.hpBarSizeY + self.textSize) * 0.5)
    self:ApplySettings()
    self:UpdateHp(hp, maxHp)
    self:UpdateWhilePaused(false)
end)

function HiHpWidget:UpdateCombatAction()
    if self.isAttacking or self.attackersNum > 0 or self.isRided then
        self.LastCombatActionTs = GetTime()
    end
end

function HiHpWidget:GetOffset()
    local offset = self._base.GetOffset(self)
    if self.isRider then
        offset = offset + HP_WIDGET_RIDER_OFFSET
    end
    return offset
end

function HiHpWidget:SetImageTint(tint)
    self.box:SetTint(tint[1], tint[2], tint[3], tint[4] * self.fadeOpacity * HI_SETTINGS:GetHealthBarOpacity())
end

function HiHpWidget:SetTarget(target)
    self.isBoss = target:HasTag("epic")
    self.isStructure = target:HasTag("structure")
    self.isWallOrBoat = target:HasTag("boat") or target:HasTag("boatbumper") or target:HasTag("wall")
    self._base.SetTarget(self, target)
    self:UpdateState(true)
end

function HiHpWidget:InitRemoving()
    self.isToRemove = true
end

function HiHpWidget:Kill()
    self.boxBg:Kill()
    self.box:Kill()
    self.text:Kill()
    self._base.Kill(self)
end

function HiHpWidget:UpdateHp(hp, maxHp, force)
    if hp ~= self.hp or maxHp ~= self.maxHp or force then
        -- Don't update this if it is health initialization
        if self.maxHp ~= 0 then
            self.LastCombatActionTs = GetTime()
        end
        self.hp = hp
        self.maxHp = maxHp
        local resultString = tostring(math.floor(self.hp))
        if HI_SETTINGS:GetOtherOption(SHOW_MAX_HP) then
            resultString = resultString .. "/" .. tostring(math.floor(self.maxHp))
        end
        self.text:SetString(resultString)
    end
    local x, y, textSize = GetScaledValues(maxHp)
    if self.hpBarSizeX ~= x or self.hpBarSizeY ~= y then
        self.hpBarSizeX = x
        self.hpBarSizeY = y
        self.textSize = textSize
        self.boxBg:SetSize(self.hpBarSizeX - BOX_BG_PADDING, self.hpBarSizeY - BOX_BG_PADDING)
        self.text:SetSize(self.textSize)
        self.text:SetPosition(0, -(self.hpBarSizeY + self.textSize) * 0.5)
    end
    local hpBarFillerSizeX = math.max((self.hpBarSizeX - BOX_INNER_PADDING) * hp / maxHp, 0)
    self.box:SetPosition((BOX_INNER_PADDING - self.hpBarSizeX + hpBarFillerSizeX) * 0.5, 0, 0)
    self.box:SetSize(hpBarFillerSizeX, self.hpBarSizeY - BOX_INNER_PADDING)
end

function HiHpWidget:UpdateState(force)
    local state = GetHpWidgetState(self.target)
    if state ~= self.state or force then
        self.state = state
        self.isVisibleBySettings = self:GetVisibilityBySettings()
        self.showOnlyInCombat = HI_SETTINGS:GetOtherOption(SHOW_ONLY_IN_COMBAT)
        self:SetImageTint(HI_SETTINGS:GetColour(self.state))
    end
end

function HiHpWidget:UpdateOpacity()
    self:SetImageTint(HI_SETTINGS:GetColour(self.state))
    self.boxBg:SetFadeAlpha(self.fadeOpacity * HI_SETTINGS:GetHealthBarOpacity())
    self.text:SetFadeAlpha(self.fadeOpacity * HI_SETTINGS:GetHealthNumberOpacity())
end

function HiHpWidget:ApplySettings()
    self:UpdateOpacity()
    self:UpdateState(true)
    self:UpdateHp(self.hp, self.maxHp, true)
end

function HiHpWidget:GetVisibilityBySettings()
    if self.state == STATE_PLAYER then
        if self.target == ThePlayer then
            return HI_SETTINGS:GetVisibility(VISIBILITY_INDEX_ME)
        else
            return HI_SETTINGS:GetVisibility(VISIBILITY_INDEX_OTHER_PLAYER)
        end
    else
        if self.isBoss then
            return HI_SETTINGS:GetVisibility(VISIBILITY_INDEX_BOSS)
        elseif self.isStructure then
            return HI_SETTINGS:GetVisibility(VISIBILITY_INDEX_STRUCTURE)
        elseif self.isWallOrBoat then
            return HI_SETTINGS:GetVisibility(VISIBILITY_INDEX_WALL_BOAT)
        elseif self.state == STATE_HOSTILE then
            return HI_SETTINGS:GetVisibility(VISIBILITY_INDEX_HOSTILE)
        elseif self.state == STATE_FRIEND then
            return HI_SETTINGS:GetVisibility(VISIBILITY_INDEX_FRIEND)
        else
            return HI_SETTINGS:GetVisibility(VISIBILITY_INDEX_OTHER)
        end
    end
end

function HiHpWidget:IsVisibleByLogic()
    if self.target == nil then
        return false
    end
    -- if player shouldn't see target (i.e. target is in shadow)
    if not CanEntitySeeTarget(ThePlayer, self.target) then
        return false
    end
    -- always show players, friends and enemies
    if self.state ~= STATE_NEUTRAL then
        return true
    end
    -- if out of combat
    if self.showOnlyInCombat and self.LastCombatActionTs + self.hideHpTimeout < GetTime() then
        return false
    end
    return true
end

function HiHpWidget:OnUpdate(dt)
    self:UpdateCombatAction()
    local isToVisible = not self.isToRemove and self.isVisibleBySettings and self:IsVisibleByLogic()
    if isToVisible and self.fadeOpacity < 1 then
        self.fadeOpacity = math.clamp(self.fadeOpacity + dt / self.fadeAnimTime, 0, 1)
        self:UpdateOpacity()
    end
    if not isToVisible and self.fadeOpacity > 0 then
        self.fadeOpacity = math.clamp(self.fadeOpacity - dt / self.fadeAnimTime, 0, 1)
        self:UpdateOpacity()
    end

    if not isToVisible and self.fadeOpacity == 0 then
        self:Hide()
        if self.isToRemove then
            self:Kill()
        end
        return
    end

    if self.fadeOpacity > 0 then
        self._base.OnUpdate(self, dt)
        self:Show()
    end
end

return HiHpWidget
