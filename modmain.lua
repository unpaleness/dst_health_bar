local HiHpWidget = nil
local HiDamageWidget = nil

if not GLOBAL.TheNet:IsDedicated() then
    Assets = {
        Asset("IMAGE", "images/hp_bg.tex"),
        Asset("ATLAS", "images/hp_bg.xml"),
        Asset("IMAGE", "images/hp_white.tex"),
        Asset("ATLAS", "images/hp_white.xml"),
    }

    HiHpWidget = require "widgets/hi_hp_widget"
    HiDamageWidget = require "widgets/hi_damage_widget"

    GLOBAL.HI_SETTINGS = require "hi_settings"
    GLOBAL.HI_SETTINGS:Load()
end

-- Client methods

local function HiClientTryCreateHpWidget(inst)
    -- print("HiClientTryCreateHpWidget", inst)
    if GLOBAL.TheNet:IsDedicated() or GLOBAL.ThePlayer == nil then
        return
    end
	if inst:IsAsleep() then
		return
	end
    local widget = inst._hiHpWidget
    if widget ~= nil then
        return
    end
    local riderGUID = inst._hiCurrentRiderGuidReplicated:value()
    if inst:HasTag("INLIMBO") and (riderGUID == nil or riderGUID == 0) then
        return
    end
    widget = GLOBAL.ThePlayer.HUD.overlayroot:AddChild(HiHpWidget(inst._hiCurrentHealthClient, inst._hiMaxHealthClient))
    widget:SetTarget(inst)
    inst._hiHpWidget = widget
    GLOBAL.HI_SETTINGS.cached_hp_widgets[inst._hiServerGuidReplicated:value()] = widget
    GLOBAL.HI_SETTINGS.cached_hp_widgets_num = GLOBAL.HI_SETTINGS.cached_hp_widgets_num + 1
    -- print("HiClientTryCreateHpWidget", inst, ", cached widgets: ", GLOBAL.HI_SETTINGS.cached_hp_widgets_num)
end

local function HiClientTryRemoveHpWidget(inst)
    -- print("HiClientTryRemoveHpWidget", inst)
    if GLOBAL.TheNet:IsDedicated() then
        return
    end
    local widget = inst._hiHpWidget
    if widget == nil then
        return
    end
    if widget.inst and widget.inst:IsValid() then
        widget:InitRemoving()
    end
    inst._hiHpWidget = nil
    GLOBAL.HI_SETTINGS.cached_hp_widgets[inst._hiServerGuidReplicated:value()] = nil
    GLOBAL.HI_SETTINGS.cached_hp_widgets_num = GLOBAL.HI_SETTINGS.cached_hp_widgets_num - 1
    -- print("HiClientTryRemoveHpWidget", inst, ", cached widgets: ", GLOBAL.HI_SETTINGS.cached_hp_widgets_num)
end

local function HiClientTryUpdateHpWidget(inst)
    local widget = inst._hiHpWidget
    if widget == nil then
        return
    end
    widget:UpdateHp(inst._hiCurrentHealthClient, inst._hiMaxHealthClient)
end

local function HiClientTrySpawnDamageWidget(inst)
    if GLOBAL.TheNet:IsDedicated() or GLOBAL.ThePlayer == nil or inst._hiCurrentHealthClient == nil or not GLOBAL.CanEntitySeeTarget(GLOBAL.ThePlayer, inst) then
        -- print("HiClientTrySpawnDamageWidget cannot spawn damage indicator for", inst)
        return
    end
    local damage_widget = GLOBAL.ThePlayer.HUD.overlayroot:AddChild(HiDamageWidget(inst._hiCurrentHealthReplicated:value() - inst._hiCurrentHealthClient))
    damage_widget:SetTarget(inst)
end

local function HiClientOnHealthDirty(inst)
    local healthValue = inst._hiCurrentHealthReplicated:value()
    local maxHealthValue = inst._hiMaxHealthReplicated:value()
    local healthValueClient = inst._hiCurrentHealthClient or 0
	local maxHealthValueClient = inst._hiMaxHealthClient or 0
    -- print("HiClientOnHealthDirty:", inst, ":", healthValueClient, " -> ", healthValue, " / ", maxHealthValueClient, " -> ", maxHealthValue)
	if inst._hiCurrentHealthClient ~= nil and healthValue ~= healthValueClient then
    	HiClientTrySpawnDamageWidget(inst)
	end
    inst._hiCurrentHealthClient = healthValue
	inst._hiMaxHealthClient = maxHealthValue
    if healthValue > 0 and maxHealthValue > 0 then
        HiClientTryCreateHpWidget(inst)
    end
    HiClientTryUpdateHpWidget(inst)
    if healthValue <= 0  or maxHealthValue <= 0 then
        HiClientTryRemoveHpWidget(inst)
    end
end

local function HiClientOnCombatTargetDirty(inst)
	local hpWidget = inst._hiHpWidget
	if hpWidget ~= nil then
		hpWidget:UpdateState()
        local targetGuid = inst._hiCombatTargetGuidReplicated:value()
        hpWidget.isAttacking = targetGuid ~= nil and targetGuid ~= 0
	end
end

local function HiClientOnFollowTargetDirty(inst)
	local hpWidget = inst._hiHpWidget
	if hpWidget ~= nil then
		hpWidget:UpdateState()
	end
end

local function HiClientOnEntityActive(inst)
    -- print("HiClientOnEntityActive", inst)
    if inst == nil or not inst:IsValid() then
        return
    end
	HiClientOnHealthDirty(inst)
end

local function HiClientOnEntityPassive(inst)
    -- print("HiClientOnEntityPassive", inst)
    if inst == nil or not inst:IsValid() then
        return
    end
    inst._hiCurrentHealthClient = nil
    HiClientTryRemoveHpWidget(inst)
end

local function HiClientOnCurrentRiderGuidDirty(inst)
    -- print("HiClientOnCurrentRiderGuidDirty", inst)
    local oldRiderGuid = inst._hiCurrentRiderGuid
    local newRiderGuid = inst._hiCurrentRiderGuidReplicated:value()
    -- we should make rideable entity widget visible while rided
    local widgetRideable = GLOBAL.HI_SETTINGS.cached_hp_widgets[inst._hiServerGuidReplicated:value()]
    if newRiderGuid ~= 0 then
        -- This is a workaround to show hp on beefalo for master sim as it is going to LIMBO then is ridden
        HiClientOnEntityActive(inst)
        local widget = GLOBAL.HI_SETTINGS.cached_hp_widgets[newRiderGuid]
        -- we adjust hp bar of the new rider to exclude collision with a rideable entity
        if widget then
            widget.isRider = true
        end
        if widgetRideable then
            widgetRideable.isRided = true
        end
    else
        if widgetRideable then
            widgetRideable.isRided = false
        end
    end
    if oldRiderGuid ~= 0 then
        local widget = GLOBAL.HI_SETTINGS.cached_hp_widgets[oldRiderGuid]
        -- we restore hp bar position of the old rider
        if widget then
            widget.isRider = false
        end
    end
    inst._hiCurrentRiderGuid = newRiderGuid
end

-- local function HiOnAttackersNumDirty(inst)
--     local widget = GLOBAL.HI_SETTINGS.cached_hp_widgets[inst._hiServerGuidReplicated:value()]
--     if widget ~= nil then
--         widget.attackersNum = inst._hiAttackersNumReplicated:value()
--     end
-- end

--[[
local function HiClientOnCombinedDamageStringDirty(inst)
	local combinedDamageStringReplicated = inst._hiCombinedDamageString:value()
	print("HiClientOnCombinedDamageStringDirty:", inst, ": pack: ", combinedDamageStringReplicated)
	local tokens = string.split(combinedDamageStringReplicated, ";")
	for i, token in ipairs(tokens) do
		print("HiClientOnCombinedDamageStringDirty:", inst, ": tokens: ", i, " - ", token)
	end
	if #tokens < 2 then
		print("HiClientOnCombinedDamageStringDirty:", inst, " bad params pack")
		return
	end
	local value = GLOBAL.tonumber(tokens[1]) or 0
	local type = tokens[2]
	if value == nil then
		print("HiClientOnCombinedDamageStringDirty:", inst, " bad value")
		return
	end
	if value ~= 0 then
        if not GLOBAL.TheNet:IsDedicated() and GLOBAL.ThePlayer ~= nil then
            GLOBAL.ThePlayer.HUD.overlayroot:AddChild(HiDamageWidget(inst, value, type))
        end
	end
end
]]

local function HiClientOnExitLimbo(inst)
    -- print("HiClientOnExitLimbo", inst)
    HiClientOnEntityActive(inst)
end

local function HiClientOnWake(inst)
    -- print("HiClientOnWake", inst)
    HiClientOnEntityActive(inst)
end

local function HiClientOnEnterLimbo(inst)
    -- print("HiClientOnEnterLimbo", inst)
    HiClientOnEntityPassive(inst)
end

local function HiClientOnSleep(inst)
    -- print("HiClientOnSleep", inst)
    HiClientOnEntityPassive(inst)
end

local function HiClientOnRemove(inst)
    -- print("HiClientOnRemove", inst)
    HiClientOnEntityPassive(inst)
end

local function HiOnIsInInventoryDirty(inst)
    local widget = GLOBAL.HI_SETTINGS.cached_hp_widgets[inst._hiServerGuidReplicated:value()]
    if widget ~= nil then
        widget.isInInventory = inst._hiIsInInventoryReplicated:value()
    end
end

-- Server methods

local function HiServerOnHealthDelta(inst, data)
    local health_component = inst.components.health
    if health_component == nil then
        -- print("HiServerOnHealthDelta", inst, " have no \"health_component\" component")
        return
    end
    inst._hiCurrentHealthReplicated:set(health_component.currenthealth)
end

local function HiServerOnStartFollowing(inst, data)
	-- print("HiServerOnStartFollowing", inst, data.leader)
	local leader = data.leader
	local isNewTargetPlayer = leader and leader == GLOBAL.ThePlayer or false
	inst._hiFollowTargetGuidReplicated:set(isNewTargetPlayer and leader._hiServerGuidReplicated:value() or 0)
end

local function HiServerOnStopFollowing(inst, data)
	-- print("HiServerOnStopFollowing", inst, data.leader)
	inst._hiFollowTargetGuidReplicated:set(0)
end

--[[
local function HiServerOnAttacked(inst, data)
	local combatComponent = inst.components.combat
    if combatComponent == nil then
		print("HiServerOnHealthDelta", inst, "have no \"combat\" component")
		return
	end
	if data == nil or data.original_damage == nil or data.damageresolved == nil then
		return
	end
	local damage_blocked = data.original_damage - data.damageresolved
	if damage_blocked > 0 then
		local damage_string = tostring(damage_blocked) .. ";blocked"
		inst._hiCombinedDamageString:set_local(damage_string)
		inst._hiCombinedDamageString:set(damage_string)
	end
end
]]

local function HiServerOnRiderChange(inst, data)
    -- print("HiServerOnRiderChanged", inst, data and data.newrider and data.newrider.GUID or 0)
    if data and data.newrider then
        inst._hiCurrentRiderGuidReplicated:set(data.newrider.GUID)
    else
        inst._hiCurrentRiderGuidReplicated:set(0)
    end
end

local function HiServerOnInInventoryChange(inst)
    local intentoryItemComponent = inst.components.inventoryitem
    if intentoryItemComponent ~= nil then
        inst._hiIsInInventoryReplicated:set(intentoryItemComponent.owner ~= nil)
    end
end

local function HiServerProcessHealthComponent(health)
	health.inst._hiCurrentHealthReplicated:set(health.currenthealth)
	health.inst._hiMaxHealthReplicated:set(health.maxhealth)
	local OldSetMaxHealth = health.SetMaxHealth
	health.SetMaxHealth = function(self, amount)
		OldSetMaxHealth(self, amount)
		health.inst._hiMaxHealthReplicated:set(amount)
	end
end

local function HiServerProcessCombatComponent(combat)
	local function OnChangeTarget(component, oldTarget, newTarget)
        if oldTarget ~= newTarget then
            -- print("ChangeTarget {", component.inst, "}: old: ", oldTarget and oldTarget or "<nil>", ", new: ", newTarget and newTarget or "<nil>")
            component.inst._hiCombatTargetGuidReplicated:set(newTarget and newTarget._hiServerGuidReplicated:value() or 0)
            -- if oldTarget ~= nil then
            --     oldTarget._hiAttackersNumReplicated:set(oldTarget._hiAttackersNumReplicated:value() - 1)
            -- end
            -- if newTarget ~= nil then
            --     newTarget._hiAttackersNumReplicated:set(newTarget._hiAttackersNumReplicated:value() + 1)
            -- end
        end
	end
	local OldEngageTarget = combat.EngageTarget
	combat.EngageTarget = function(self, target)
		local oldTarget = self.target
		OldEngageTarget(self, target)
		local newTarget = self.target
		OnChangeTarget(self, oldTarget, newTarget)
	end
	local OldDropTarget = combat.DropTarget
	combat.DropTarget = function(self, target)
		local oldTarget = self.target
		OldDropTarget(self, target)
		local newTarget = self.target
		OnChangeTarget(self, oldTarget, newTarget)
	end
end

-- Subscription on all prefabs initialization. Here we create network variables, make subscriptions on events. This should be done on both client and server

local function InitPrefab(inst)
    if inst == nil then
        return
    end
    if inst._hiInitializedLocal ~= nil and inst._hiInitializedLocal then
        return
    end
    inst._hiInitializedLocal = true
    -- print("InitPrefab:", inst, ": Start")
    -- authorized health value, caluclated on server, replicated to client
    -- possibly overhead here as it is added to every single prefab, but seems to work
    inst._hiServerGuidReplicated = GLOBAL.net_int(inst.GUID, "_hiServerGuidReplicated", "hiOnServerGuidDirty")
    inst._hiServerGuidReplicated:set(inst.GUID)
    inst._hiCurrentHealthReplicated = GLOBAL.net_float(inst.GUID, "_hiCurrentHealthReplicated", "hiOnCurrentHealthDirty")
    inst._hiMaxHealthReplicated = GLOBAL.net_float(inst.GUID, "_hiMaxHealthReplicated", "hiOnMaxHealthDirty")
	inst._hiCombatTargetGuidReplicated = GLOBAL.net_int(inst.GUID, "_hiCombatTargetGuidReplicated", "hiOnCombatTargetDirty")
	inst._hiFollowTargetGuidReplicated = GLOBAL.net_int(inst.GUID, "_hiFollowTargetGuidReplicated", "hiOnFollowTargetDirty")
    inst._hiCurrentRiderGuidReplicated = GLOBAL.net_int(inst.GUID, "_hiCurrentRiderGuidReplicated", "hiOnCurrentRiderGuidDirty")
    inst._hiIsInInventoryReplicated = GLOBAL.net_bool(inst.GUID, "_hiIsInInventoryReplicated", "hiOnIsInInventoryDirty")
    -- inst._hiAttackersNumReplicated = GLOBAL.net_int(inst.GUID, "_hiAttackersNumReplicated", "hiOnAttackersNumDirty")
    -- this is a packed value+string data about damage replicated to client
    -- inst._hiCombinedDamageString = GLOBAL.net_string(inst.GUID, "_hiCombinedDamageString_replicated", "hiOnCombinedDamageStringDirty")
    if GLOBAL.TheWorld.ismastersim then
        -- print("AddPrefabPostInitAny:", inst, ": setting up server subscriptions")
        inst:ListenForEvent("healthdelta", HiServerOnHealthDelta)
        inst:ListenForEvent("startfollowing", HiServerOnStartFollowing)
        inst:ListenForEvent("stopfollowing", HiServerOnStopFollowing)
        -- inst:ListenForEvent("attacked", HiServerOnAttacked)
        inst:ListenForEvent("riderchanged", HiServerOnRiderChange)
        inst:ListenForEvent("onputininventory", HiServerOnInInventoryChange)
        inst:ListenForEvent("ondropped", HiServerOnInInventoryChange)
    end
    if not GLOBAL.TheNet:IsDedicated() then
        -- print("AddPrefabPostInitAny:", inst, ": setting up client subscriptions")
        -- introduce this value as the last value stored by client to calculate health diff upon replicated health value update
        inst._hiCurrentHealthClient = nil
        inst._hiMaxHealthClient = nil
        inst._hiCurrentRiderGuid = 0
        inst:ListenForEvent("exitlimbo", HiClientOnExitLimbo)
        inst:ListenForEvent("entitywake", HiClientOnWake)
        inst:ListenForEvent("enterlimbo", HiClientOnEnterLimbo)
        inst:ListenForEvent("entitysleep", HiClientOnSleep)
        inst:ListenForEvent("onremove", HiClientOnRemove)
        -- HiClientOnEntityActive(inst)
        inst:ListenForEvent("hiOnCurrentHealthDirty", HiClientOnHealthDirty)
        inst:ListenForEvent("hiOnMaxHealthDirty", HiClientOnHealthDirty)
        inst:ListenForEvent("hiOnCombatTargetDirty", HiClientOnCombatTargetDirty)
        inst:ListenForEvent("hiOnFollowTargetDirty", HiClientOnFollowTargetDirty)
        -- inst:ListenForEvent("hiOnCombinedDamageStringDirty", HiClientOnCombinedDamageStringDirty)
        inst:ListenForEvent("hiOnCurrentRiderGuidDirty", HiClientOnCurrentRiderGuidDirty)
        -- inst:ListenForEvent("hiOnAttackersNumDirty", HiOnAttackersNumDirty)
        inst:ListenForEvent("hiOnIsInInventoryDirty", HiOnIsInInventoryDirty)
    end
end

AddPrefabPostInitAny(function(inst)
    InitPrefab(inst)
end)

AddComponentPostInit("combat", function(self, inst)
    if GLOBAL.TheWorld.ismastersim then
        InitPrefab(inst)
        HiServerProcessCombatComponent(self)
    end
end)
AddComponentPostInit("health", function(self, inst)
    if GLOBAL.TheWorld.ismastersim then
        InitPrefab(inst)
        HiServerProcessHealthComponent(self)
    end
end)

-- Settings up user configuration in-game widget. Client only

if not GLOBAL.TheNet:IsDedicated() then
    local HiSettingsScreen = require "widgets/hi_settings_screen"
	AddSimPostInit(function()
        AddClassPostConstruct("screens/redux/pausescreen", function(self)
            self.menu:AddItem("HI Settings", function()
                GLOBAL.HI_SETTINGS:Load()
                local settingsScreen = HiSettingsScreen()
                self:unpause()
                GLOBAL.ThePlayer.HUD:OpenScreenUnderPause(settingsScreen)
            end)
            local buttonH = 50 -- magic number from screens/redux/pausescreen.lua
	        local yPos = (buttonH * (#self.menu.items - 1) / 2)
            self.menu:SetPosition(0, yPos, 0)
            self.menu.items[#self.menu.items]:SetScale(.7)
        end)
	end)
end
