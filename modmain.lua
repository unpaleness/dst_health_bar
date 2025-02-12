local HiHpWidget = nil
local HiDamageWidget = nil
if not GLOBAL.TheNet:IsDedicated() then
	HiHpWidget = require "widgets/hi_hp_widget"
	HiDamageWidget = require "widgets/hi_damage_widget"
end

-- Client methods

local function HiClientTryCreateHpWidget(inst)
	if not GLOBAL.TheNet:IsDedicated() and GLOBAL.ThePlayer ~= nil and inst.hi_hp_widget == nil then
		inst.hi_hp_widget = GLOBAL.ThePlayer.HUD.overlayroot:AddChild(HiHpWidget(inst, inst._hi_current_health_replicated:value()))
	end
end

local function HiClientTryRemoveHpWidget(inst)
	if not GLOBAL.TheNet:IsDedicated() and inst.hi_hp_widget ~= nil then
		inst.hi_hp_widget:Kill()
		inst.hi_hp_widget = nil
	end
end

local function HiClientOnHealthCurrentDirty(inst)
	local health_value_replicated = inst._hi_current_health_replicated:value()
	if health_value_replicated > 0 and inst.hi_hp_widget == nil then
		HiClientTryCreateHpWidget(inst)
	end
	-- if health value was initialized locally on client and diff ~= 0 then show damage/heal indicator
	if inst._hi_current_health_client ~= nil and inst._hi_current_health_client ~= health_value_replicated then
        if not GLOBAL.TheNet:IsDedicated() and GLOBAL.ThePlayer ~= nil then
            GLOBAL.ThePlayer.HUD.overlayroot:AddChild(HiDamageWidget(inst, health_value_replicated - inst._hi_current_health_client))
        end
		if inst.hi_hp_widget ~= nil then
			inst.hi_hp_widget:SetHp(health_value_replicated)
		end
	end
	if health_value_replicated <= 0 then
		HiClientTryRemoveHpWidget(inst)
		return
	end
	inst._hi_current_health_client = health_value_replicated
end

local function HiClientOnEntityActive(inst)
	-- print("HiClientOnEntityActive: {", inst, "}")
	if inst:IsAsleep() then
		return
	end
	if inst.entity:HasTag("INLIMBO") then
		return
	end
	local health_value_replicated = inst._hi_current_health_replicated:value()
	if health_value_replicated > 0 then
		inst._hi_current_health_client = health_value_replicated
		HiClientTryCreateHpWidget(inst)
	end
end

local function HiClientOnEntityPassive(inst)
	-- print("HiClientOnEntityPassive: {", inst, "}")
	inst._hi_current_health_client = nil
	HiClientTryRemoveHpWidget(inst)
end

-- Server methods

local function HiServerOnHealthDelta(inst, data)
	local health_component = inst.components.health
    if health_component == nil then
		-- print("HiServerOnHealthDelta: {", inst, "} have no \"health_component\" component")
		return
	end
	inst._hi_current_health_replicated:set(health_component.currenthealth)
	-- print("HiServerOnHealthDelta: {", inst, "} new _hi_current_health_replicated value: ", inst._hi_current_health_replicated:value())
end

-- Subscription on all prefabs initialization. Here we create network variables, make subscriptions on events

AddPrefabPostInitAny(function(inst)
	-- print("AddPrefabPostInitAny: {", inst, "}: Start")
	-- authorized health value, caluclated on server, replicated to client
	inst._hi_current_health_replicated = GLOBAL.net_float(inst.GUID, "components.health._hi_current_health_replicated", "hi_on_current_health_dirty")
	local health_component = inst.components.health
	-- as health component persists only on server this will set the value on server and trigger synchronization to client
	if health_component ~= nil then
		inst._hi_current_health_replicated:set(health_component.currenthealth)
	end
	if GLOBAL.TheWorld.ismastersim then
		-- print("AddPrefabPostInitAny: {", inst, "}: setting up server subscriptions")
		inst:ListenForEvent("healthdelta", HiServerOnHealthDelta)
	end
	if not GLOBAL.TheNet:IsDedicated() then
		-- print("AddPrefabPostInitAny: {", inst, "}: setting up client subscriptions")
		-- introduce this value as the last value stored by client to calculate health diff upon replicated health value update
		inst._hi_current_health_client = nil
		inst:ListenForEvent("exitlimbo", HiClientOnEntityActive)
		inst:ListenForEvent("entitywake", HiClientOnEntityActive)
		inst:ListenForEvent("enterlimbo", HiClientOnEntityPassive)
		inst:ListenForEvent("entitysleep", HiClientOnEntityPassive)
		inst:ListenForEvent("onremove", HiClientOnEntityPassive)
		HiClientOnEntityActive(inst)
		inst:ListenForEvent("hi_on_current_health_dirty", HiClientOnHealthCurrentDirty)
		-- inst:ListenForEvent("hi_on_current_damage_dirty", HiClientOnDamageCurrentDirty)
	end
end)
