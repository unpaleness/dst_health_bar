if not GLOBAL.TheNet:IsDedicated() then
    Assets = {
        Asset("IMAGE", "images/hp_bg.tex"),
        Asset("ATLAS", "images/hp_bg.xml"),
        Asset("IMAGE", "images/hp_white.tex"),
        Asset("ATLAS", "images/hp_white.xml"),
    }
end

local HiHpWidget = nil
local HiDamageWidget = nil
if not GLOBAL.TheNet:IsDedicated() then
    HiHpWidget = require "widgets/hi_hp_widget"
    HiDamageWidget = require "widgets/hi_damage_widget"
end

-- Client methods

local function HiClientShouldShowHp(inst)
    return not inst:IsAsleep() and not inst:HasTag("INLIMBO")
end

local function HiClientTryCreateHpWidget(inst)
    if GLOBAL.TheNet:IsDedicated() or GLOBAL.ThePlayer == nil then
        return
    end
	if not HiClientShouldShowHp(inst) then
		return
	end
    local widget = inst._hi_hp_widget
    if widget ~= nil then
        return
    end
    -- print("HiClientTryCreateHpWidget: {", inst, "}")
    widget = GLOBAL.ThePlayer.HUD.overlayroot:AddChild(HiHpWidget(inst._hi_current_health_client, inst._hi_max_health_client))
    widget:SetTarget(inst)
    inst._hi_hp_widget = widget
end

local function HiClientTryRemoveHpWidget(inst)
    if GLOBAL.TheNet:IsDedicated() then
        return
    end
    local widget = inst._hi_hp_widget
    if widget == nil then
        return
    end
    -- print("HiClientTryRemoveHpWidget: {", inst, "}, hp: ", widget.hp, ", state: ", widget.state, ", scale: ", widget.scale, ", pos: ", widget:GetPosition())
    widget:Kill()
    inst._hi_hp_widget = nil
end

local function HiClientTryUpdateHpWidget(inst)
    local widget = inst._hi_hp_widget
    if widget == nil then
        return
    end
    widget:UpdateHp(inst._hi_current_health_client, inst._hi_max_health_client)
end

local function HiClientTrySpawnDamageWidget(inst)
    if GLOBAL.TheNet:IsDedicated() or GLOBAL.ThePlayer == nil or inst._hi_current_health_client == nil then
        return
    end
    local damage_widget = GLOBAL.ThePlayer.HUD.overlayroot:AddChild(HiDamageWidget(inst._hi_current_health_replicated
    :value() - inst._hi_current_health_client))
    damage_widget:SetTarget(inst)
end

local function HiClientOnHealthDirty(inst)
    local health_value = inst._hi_current_health_replicated:value()
    local max_health_value = inst._hi_max_health_replicated:value()
    local health_value_client = inst._hi_current_health_client or 0
	local max_health_value_client = inst._hi_max_health_client or 0
    -- print("HiClientOnHealthDirty: {", inst, "}:", health_value_client, " -> ", health_value, " / ", max_health_value_client, " -> ", max_health_value)
	if inst._hi_current_health_client ~= nil and health_value ~= health_value_client then
    	HiClientTrySpawnDamageWidget(inst)
	end
    inst._hi_current_health_client = health_value
	inst._hi_max_health_client = max_health_value
    if health_value > 0 and max_health_value > 0 then
        HiClientTryCreateHpWidget(inst)
    end
    HiClientTryUpdateHpWidget(inst)
    if health_value <= 0  or max_health_value <= 0 then
        HiClientTryRemoveHpWidget(inst)
    end
end

--[[
local function HiClientOnCombinedDamageStringDirty(inst)
	local combined_damage_string_replicated = inst._hi_combined_damage_string:value()
	print("HiClientOnCombinedDamageStringDirty: {", inst, "}: pack: ", combined_damage_string_replicated)
	local tokens = string.split(combined_damage_string_replicated, ";")
	for i, token in ipairs(tokens) do
		print("HiClientOnCombinedDamageStringDirty: {", inst, "}: tokens: ", i, " - ", token)
	end
	if #tokens < 2 then
		print("HiClientOnCombinedDamageStringDirty: {", inst, "} bad params pack")
		return
	end
	local value = GLOBAL.tonumber(tokens[1]) or 0
	local type = tokens[2]
	if value == nil then
		print("HiClientOnCombinedDamageStringDirty: {", inst, "} bad value")
		return
	end
	if value ~= 0 then
        if not GLOBAL.TheNet:IsDedicated() and GLOBAL.ThePlayer ~= nil then
            GLOBAL.ThePlayer.HUD.overlayroot:AddChild(HiDamageWidget(inst, value, type))
        end
	end
end
]]

local function HiClientOnEntityActive(inst)
    -- print("HiClientOnEntityActive: {", inst, "}")
	HiClientOnHealthDirty(inst)
end

local function HiClientOnEntityPassive(inst)
    -- print("HiClientOnEntityPassive: {", inst, "}")
    inst._hi_current_health_client = nil
    HiClientTryRemoveHpWidget(inst)
end

local function HiClientOnExitLimbo(inst)
    -- print("HiClientOnExitLimbo: {", inst, "}")
    HiClientOnEntityActive(inst)
end

local function HiClientOnWake(inst)
    -- print("HiClientOnWake: {", inst, "}")
    HiClientOnEntityActive(inst)
end

local function HiClientOnEnterLimbo(inst)
    -- print("HiClientOnEnterLimbo: {", inst, "}")
    HiClientOnEntityPassive(inst)
end

local function HiClientOnSleep(inst)
    -- print("HiClientOnSleep: {", inst, "}")
    HiClientOnEntityPassive(inst)
end

local function HiClientOnRemove(inst)
    -- print("HiClientOnRemove: {", inst, "}")
    HiClientOnEntityPassive(inst)
end


-- Server methods

local function HiServerOnHealthDelta(inst, data)
    local health_component = inst.components.health
    if health_component == nil then
        print("HiServerOnHealthDelta: {", inst, "} have no \"health_component\" component")
        return
    end
    inst._hi_current_health_replicated:set(health_component.currenthealth)
end

local function HiServerOnStartFollowing(inst, data)
	print("HiServerOnStartFollowing {", inst, "}: ", data.leader)
	inst._hi_follow_target_replicated:set(data.leader.GUID)
end

local function HiServerOnStopFollowing(inst, data)
	print("HiServerOnStopFollowing {", inst, "}: ", data.leader)
	inst._hi_follow_target_replicated:set(0)
end

--[[
local function HiServerOnAttacked(inst, data)
	local combat_component = inst.components.combat
    if combat_component == nil then
		print("HiServerOnHealthDelta: {", inst, "} have no \"combat_component\" component")
		return
	end
	if data == nil or data.original_damage == nil or data.damageresolved == nil then
		return
	end
	local damage_blocked = data.original_damage - data.damageresolved
	if damage_blocked > 0 then
		local damage_string = tostring(damage_blocked) .. ";blocked"
		inst._hi_combined_damage_string:set_local(damage_string)
		inst._hi_combined_damage_string:set(damage_string)
	end
end
]]

-- Subscription on all prefabs initialization. Here we create network variables, make subscriptions on events

AddPrefabPostInitAny(function(inst)
    -- print("AddPrefabPostInitAny: {", inst, "}: Start")
    -- authorized health value, caluclated on server, replicated to client
    -- possibly overhead here as it is added to every single prefab, but seems to work
    inst._hi_current_health_replicated = GLOBAL.net_float(inst.GUID, "_hi_current_health_replicated",
        "hi_on_current_health_dirty")
    inst._hi_max_health_replicated = GLOBAL.net_float(inst.GUID, "_hi_max_health_replicated", "hi_on_max_health_dirty")
	inst._hi_combat_target_repicated = GLOBAL.net_int(inst.GUID, "_hi_combat_target_replicated", "_hi_on_combat_target_dirty")
	inst._hi_follow_target_replicated = GLOBAL.net_int(inst.GUID, "_hi_follow_target_replicated", "_hi_on_follow_target_dirty")
    -- this is a packed value+string data about damage replicated to client
    -- inst._hi_combined_damage_string = GLOBAL.net_string(inst.GUID, "_hi_combined_damage_string_replicated", "hi_on_combined_damage_string_dirty")
    local health_component = inst.components.health
    -- as health component persists only on server this will set the value on server and trigger synchronization to client
    if health_component ~= nil then
        inst._hi_current_health_replicated:set(health_component.currenthealth)
        inst._hi_max_health_replicated:set(health_component.currenthealth)
		local OldSetMaxHealth = health_component.SetMaxHealth
		health_component.SetMaxHealth = function(self, amount)
			OldSetMaxHealth(self, amount)
			inst._hi_max_health_replicated:set(amount)
		end
    end
	local combat_component = inst.components.combat
    if combat_component ~= nil then
		local function OnChangeTarget(inst, old_guid, new_guid)
			if old_guid ~= new_guid then
				-- print("ChangeTarget {", inst, "}: old: ", old_guid, ", new: ", new_guid)
				inst._hi_combat_target_repicated:set(new_guid)
			end
		end
		local OldEngageTarget = combat_component.EngageTarget
		combat_component.EngageTarget = function(self, target)
			local old_guid = self.target and self.target.GUID or 0
			OldEngageTarget(self, target)
			local new_guid = self.target and self.target.GUID or 0
			OnChangeTarget(self.inst, old_guid, new_guid)
		end
		local OldDropTarget = combat_component.DropTarget
		combat_component.DropTarget = function(self, target)
			local old_guid = self.target and self.target.GUID or 0
			OldDropTarget(self, target)
			local new_guid = self.target and self.target.GUID or 0
			OnChangeTarget(self.inst, old_guid, new_guid)
		end
    end
    if GLOBAL.TheWorld.ismastersim then
        -- print("AddPrefabPostInitAny: {", inst, "}: setting up server subscriptions")
        inst:ListenForEvent("healthdelta", HiServerOnHealthDelta)
        inst:ListenForEvent("startfollowing", HiServerOnStartFollowing)
		inst:ListenForEvent("stopfollowing", HiServerOnStopFollowing)
        -- inst:ListenForEvent("attacked", HiServerOnAttacked)
    end
    if not GLOBAL.TheNet:IsDedicated() then
        -- print("AddPrefabPostInitAny: {", inst, "}: setting up client subscriptions")
        -- introduce this value as the last value stored by client to calculate health diff upon replicated health value update
        inst._hi_current_health_client = nil
		inst._hi_max_health_client = nil
        inst:ListenForEvent("exitlimbo", HiClientOnExitLimbo)
        inst:ListenForEvent("entitywake", HiClientOnWake)
        inst:ListenForEvent("enterlimbo", HiClientOnEnterLimbo)
        inst:ListenForEvent("entitysleep", HiClientOnSleep)
        inst:ListenForEvent("onremove", HiClientOnRemove)
        HiClientOnEntityActive(inst)
        inst:ListenForEvent("hi_on_current_health_dirty", HiClientOnHealthDirty)
        inst:ListenForEvent("hi_on_max_health_dirty", HiClientOnHealthDirty)
        -- inst:ListenForEvent("hi_on_combined_damage_string_dirty", HiClientOnCombinedDamageStringDirty)
    end
end)
