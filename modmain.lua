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
    GLOBAL.HI_LOC = require "hi_localization"
end

-- Client methods

local function HiClientTryCreateHpWidget(inst)
    -- print("HiClientTryCreateHpWidget", inst, inst._hiServerGuidReplicated:value())
    local serverGuid = inst._hiServerGuidReplicated:value()
    if GLOBAL.TheNet:IsDedicated() or GLOBAL.ThePlayer == nil then
        -- print("HiClientTryCreateHpWidget", inst, serverGuid, "is dedic or player is invalid")
        return nil
    end
    local widget = inst._hiHpWidget
    if widget ~= nil then
        -- print("HiClientTryCreateHpWidget", inst, serverGuid, "widget exists, return it")
        return widget
    end
	if inst:IsAsleep() then
        -- print("HiClientTryCreateHpWidget", inst, serverGuid, "entity is asleep")
		return nil
	end
    if inst._hiCurrentHealth <= 0 or inst._hiMaxHealth <= 0 then
        -- print("HiClientTryCreateHpWidget", inst, serverGuid, "client hp is not initialized yet")
        return nil
    end
    local riderGuid = inst._hiCurrentRiderGuidReplicated:value()
    if inst:HasTag("INLIMBO") and (riderGuid == nil or riderGuid == 0) then
        -- print("HiClientTryCreateHpWidget", inst, serverGuid, "is in limbo and doesn't have rider")
        return nil
    end
    widget = GLOBAL.ThePlayer.HUD.overlayroot:AddChild(HiHpWidget(inst._hiCurrentHealth, inst._hiMaxHealth))
    widget:SetTarget(inst)
    inst._hiHpWidget = widget
    GLOBAL.HI_SETTINGS.cached_hp_widgets[serverGuid] = widget
    GLOBAL.HI_SETTINGS.cached_hp_widgets_num = GLOBAL.HI_SETTINGS.cached_hp_widgets_num + 1
    -- print("HiClientTryCreateHpWidget", inst, ", cached widgets: ", GLOBAL.HI_SETTINGS.cached_hp_widgets_num)
    -- print("HiClientTryCreateHpWidget", inst, serverGuid, "everything's good, return newly created widget")
    return widget
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
    -- print("HiClientTryRemoveHpWidget", inst, ", cached widgets: ", GLOBAL.HI_SETTINGS.cached_hp_widgets_num)
end

local function HiClientTryUpdateHpWidgetHp(inst)
    local widget = inst._hiHpWidget
    if widget == nil then
        return
    end
    widget:UpdateHp(inst._hiCurrentHealth, inst._hiMaxHealth)
end

local function HiClientTrySpawnDamageWidget(inst)
    if GLOBAL.TheNet:IsDedicated() or GLOBAL.ThePlayer == nil or inst._hiCurrentHealth <= 0 or not GLOBAL.CanEntitySeeTarget(GLOBAL.ThePlayer, inst) then
        -- print("HiClientTrySpawnDamageWidget cannot spawn damage indicator for", inst)
        return
    end
    local damage_widget = GLOBAL.ThePlayer.HUD.overlayroot:AddChild(HiDamageWidget(inst._hiCurrentHealthReplicated:value() - inst._hiCurrentHealth))
    damage_widget:SetTarget(inst)
end

local function HiClientOnHealthDirty(inst)
    local healthValue = inst._hiCurrentHealthReplicated:value()
    local maxHealthValue = inst._hiMaxHealthReplicated:value()
    local healthValueClient = inst._hiCurrentHealth
	local maxHealthValueClient = inst._hiMaxHealth
    -- print("HiClientOnHealthDirty:", inst, ":", healthValueClient, " -> ", healthValue, " / ", maxHealthValueClient, " -> ", maxHealthValue)
	if inst._hiCurrentHealth ~= 0 and healthValue ~= healthValueClient then
    	HiClientTrySpawnDamageWidget(inst)
	end
    inst._hiCurrentHealth = healthValue
	inst._hiMaxHealth = maxHealthValue
    if healthValue > 0 and maxHealthValue > 0 then
        HiClientTryCreateHpWidget(inst)
    end
    HiClientTryUpdateHpWidgetHp(inst)
    if healthValue <= 0  or maxHealthValue <= 0 then
        HiClientTryRemoveHpWidget(inst)
    end
end

local function HiClientOnCombatTargetDirty(inst)
    -- print("HiClientOnCombatTargetDirty", inst)
	local hpWidget = HiClientTryCreateHpWidget(inst)
	if hpWidget ~= nil then
		hpWidget:UpdateState()
    else
        -- print("HiClientOnCombatTargetDirty", inst, "invalid widget!")
	end
end

local function HiClientOnFollowTargetDirty(inst)
    -- print("HiClientOnFollowTargetDirty", inst, inst._hiServerGuidReplicated:value())
	local hpWidget = HiClientTryCreateHpWidget(inst)
	if hpWidget ~= nil then
		hpWidget:UpdateState()
    else
        -- print("HiClientOnFollowTargetDirty", inst, "invalid widget!")
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
    HiClientTryRemoveHpWidget(inst)
end

local function HiClientOnCurrentRiderGuidDirty(inst)
    local oldRiderGuid = inst._hiCurrentRiderGuid
    local newRiderGuid = inst._hiCurrentRiderGuidReplicated:value()
    -- print("HiClientOnCurrentRiderGuidDirty", inst, oldRiderGuid, newRiderGuid)
    -- hack, as on mastersim beefalo goes to limbo and we need to recreate a widget for it
    local widgetRideable = HiClientTryCreateHpWidget(inst)
    if widgetRideable ~= nil then
        widgetRideable:CancelRemoving()
    end
    --
    if newRiderGuid ~= 0 then
        local widget = GLOBAL.HI_SETTINGS.cached_hp_widgets[newRiderGuid]
        -- we adjust hp bar of the new rider to exclude collision with a rideable entity
        if widget then
            widget.isRider = true
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

local function HiClientOnMouseOver(inst)
    -- print("HiClientOnMouseOver", inst)
    local widget = HiClientTryCreateHpWidget(inst)
    if widget ~= nil then
        widget.isHovered = true
    end
end

local function HiClientOnMouseOut(inst)
    -- print("HiClientOnMouseOut", inst)
    local widget = HiClientTryCreateHpWidget(inst)
    if widget ~= nil then
        widget.isHovered = false
    end
end

local function HiOnIsInInventoryDirty(inst)
    local widget = HiClientTryCreateHpWidget(inst)
    if widget ~= nil then
        widget.isInInventory = inst._hiIsInInventoryReplicated:value()
    end
end

local function HiOnIsBeingDomesticatedDirty(inst)
    -- print("HiOnIsBeingDomesticatedDirty", inst)
    local widget = HiClientTryCreateHpWidget(inst)
    if widget ~= nil then
        widget:UpdateState()
    end
end

local function HiOnIsGhostDirty(inst)
    -- print("HiOnIsGhostDirty", inst)
    local widget = HiClientTryCreateHpWidget(inst)
    if widget ~= nil then
        widget:UpdateState()
    end
end

-- Server methods

local function HiServerOnHealthDelta(inst, data)
    local health_component = inst.components.health
    if health_component == nil then
        -- print("HiServerOnHealthDelta", inst, " have no \"health_component\" component")
        return
    end
    local delta = health_component.currenthealth - inst._hiCachedLastHealthValue
    -- print("HiServerOnHealthDelta", inst, health_component.currenthealth, inst._hiCachedLastHealthValue, delta)
    if GLOBAL.math.abs(delta) >= 1 or health_component.currenthealth == health_component.maxhealth then
        inst._hiCurrentHealthReplicated:set(health_component.currenthealth)
        inst._hiCachedLastHealthValue = inst._hiCurrentHealthReplicated:value()
    end
end

local function HiServerOnStartFollowing(inst, data)
	-- print("HiServerOnStartFollowing", inst, data.leader)
	local leader = data.leader
	inst._hiFollowTargetGuidReplicated:set(leader ~= nil and leader._hiServerGuidReplicated:value() or 0)
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
    -- print("HiServerOnRiderChanged", inst, data and data.newrider or nil)
    if data and data.newrider then
        inst._hiCurrentRiderGuidReplicated:set(data.newrider._hiServerGuidReplicated:value())
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

local function HiServerOnDomesticationChange(inst, data)
    if data == nil then
        return
    end
    local old = data.old and data.old or 0
    local new = data.new and data.new or 0
    if old ~= new then
        inst._hiIsBeingDomesticatedReplicated:set(new > 0)
    end
end

local function HiServerOnChangeGhost(inst)
    -- print("HiServerOnChangeGhost", inst, inst:HasTag("playerghost"))
    inst._hiIsGhostReplicated:set(inst:HasTag("playerghost"))
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
        -- print("OnChangeTarget (server)", component.inst, oldTarget, newTarget)
        component.inst._hiCombatTargetGuidReplicated:set(newTarget and newTarget._hiServerGuidReplicated:value() or 0)
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
    inst._hiIsBeingDomesticatedReplicated = GLOBAL.net_bool(inst.GUID, "_hiIsBeingDomesticatedReplicated", "hiOnIsBeingDomesticatedDirty")
    inst._hiIsGhostReplicated = GLOBAL.net_bool(inst.GUID, "_hiIsGhostReplicated", "hiOnIsGhostDirty")
    inst._hiIsGhostReplicated:set(inst:HasTag("playerghost"))
    -- this is a packed value+string data about damage replicated to client
    -- inst._hiCombinedDamageString = GLOBAL.net_string(inst.GUID, "_hiCombinedDamageString_replicated", "hiOnCombinedDamageStringDirty")
    if GLOBAL.TheWorld.ismastersim then
        -- print("AddPrefabPostInitAny:", inst, ": setting up server subscriptions")
        inst._hiCachedLastHealthValue = 0
        inst:ListenForEvent("healthdelta", HiServerOnHealthDelta)
        inst:ListenForEvent("startfollowing", HiServerOnStartFollowing)
        inst:ListenForEvent("stopfollowing", HiServerOnStopFollowing)
        -- inst:ListenForEvent("attacked", HiServerOnAttacked)
        inst:ListenForEvent("riderchanged", HiServerOnRiderChange)
        inst:ListenForEvent("onputininventory", HiServerOnInInventoryChange)
        inst:ListenForEvent("ondropped", HiServerOnInInventoryChange)
        inst:ListenForEvent("domesticationdelta", HiServerOnDomesticationChange)
        inst:ListenForEvent("ms_becameghost", HiServerOnChangeGhost)
        inst:ListenForEvent("ms_respawnedfromghost", HiServerOnChangeGhost)
    end
    if not GLOBAL.TheNet:IsDedicated() then
        -- print("AddPrefabPostInitAny:", inst, ": setting up client subscriptions")
        -- introduce this value as the last value stored by client to calculate health diff upon replicated health value update
        inst._hiCurrentHealth = 0
        inst._hiMaxHealth = 0
        inst._hiCurrentRiderGuid = 0
        inst:ListenForEvent("exitlimbo", HiClientOnExitLimbo)
        inst:ListenForEvent("entitywake", HiClientOnWake)
        inst:ListenForEvent("enterlimbo", HiClientOnEnterLimbo)
        inst:ListenForEvent("entitysleep", HiClientOnSleep)
        inst:ListenForEvent("onremove", HiClientOnRemove)
        inst:ListenForEvent("mouseover", HiClientOnMouseOver)
        inst:ListenForEvent("mouseout", HiClientOnMouseOut)
        -- HiClientOnEntityActive(inst)
        inst:ListenForEvent("hiOnCurrentHealthDirty", HiClientOnHealthDirty)
        inst:ListenForEvent("hiOnMaxHealthDirty", HiClientOnHealthDirty)
        inst:ListenForEvent("hiOnCombatTargetDirty", HiClientOnCombatTargetDirty)
        inst:ListenForEvent("hiOnFollowTargetDirty", HiClientOnFollowTargetDirty)
        -- inst:ListenForEvent("hiOnCombinedDamageStringDirty", HiClientOnCombinedDamageStringDirty)
        inst:ListenForEvent("hiOnCurrentRiderGuidDirty", HiClientOnCurrentRiderGuidDirty)
        inst:ListenForEvent("hiOnIsInInventoryDirty", HiOnIsInInventoryDirty)
        inst:ListenForEvent("hiOnIsBeingDomesticatedDirty", HiOnIsBeingDomesticatedDirty)
        inst:ListenForEvent("hiOnIsGhostDirty", HiOnIsGhostDirty)
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
AddComponentPostInit("domesticatable", function(self, inst)
    if GLOBAL.TheWorld.ismastersim then
        InitPrefab(inst)
        inst._hiIsBeingDomesticatedReplicated:set(self.domestication > 0)
    end
end)

-- Settings up user configuration in-game widget. Client only

if not GLOBAL.TheNet:IsDedicated() then
    local HiSettingsScreen = require "widgets/hi_settings_screen"
	AddSimPostInit(function()
        AddClassPostConstruct("screens/redux/pausescreen", function(self)
            self.menu:AddItem(GLOBAL.HI_LOC:Get("hiButtonSettings"), function()
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
