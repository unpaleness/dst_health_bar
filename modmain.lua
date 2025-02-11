local HiHpWidget = nil
local HiDamageWidget = nil
if not GLOBAL.TheNet:IsDedicated() then
	HiHpWidget = require "widgets/hi_hp_widget"
	HiDamageWidget = require "widgets/hi_damage_widget"
end

-- Client methods

local function HiClientTryCreateHpWidget(inst)
	if not GLOBAL.TheNet:IsDedicated() and GLOBAL.ThePlayer ~= nil and inst.hi_hp_widget == nil then
		inst.hi_hp_widget = GLOBAL.ThePlayer.HUD.overlayroot:AddChild(HiHpWidget(inst))
		inst.hi_hp_widget:SetHp(inst._hi_current_health:value())
	end
end

local function HiClientTryRemoveHpWidget(inst)
	if not GLOBAL.TheNet:IsDedicated() and inst.hi_hp_widget ~= nil then
		inst.hi_hp_widget:Kill()
		inst.hi_hp_widget = nil
	end
end

local function HiClientOnHealthCurrentDirty(inst)
	if inst._hi_current_health == nil then
		return
	end
	local health = inst._hi_current_health:value()
	if health <= 0 then
		HiClientTryRemoveHpWidget(inst)
		return
	end
	if inst.hi_hp_widget ~= nil then
		inst.hi_hp_widget:SetHp(inst._hi_current_health:value())
	end
end

local function HiClientOnDamageCurrentDirty(inst)
	if inst._hi_current_damage == nil then
		return
	end
	if not GLOBAL.TheNet:IsDedicated() and GLOBAL.ThePlayer ~= nil then
		GLOBAL.ThePlayer.HUD.overlayroot:AddChild(HiDamageWidget(inst, inst._hi_current_damage:value()))
	end
end

local function HiClientOnEntityActive(inst)
	-- print("HiClientOnEntityActive: {", inst, "}")
	if inst:IsAsleep() then
		return
	end
	if inst.entity:HasTag("INLIMBO") then
		return
	end
	if inst._hi_current_health ~= nil and inst._hi_current_health:value() > 0 then
		HiClientTryCreateHpWidget(inst)
	end
end

local function HiClientOnEntityPassive(inst)
	-- print("HiClientOnEntityPassive: {", inst, "}")
	HiClientTryRemoveHpWidget(inst)
end

-- Server methods

local function HiServerOnHealthDelta(inst, data)
	local health_component = inst.components.health
    if health_component == nil then
		-- print("HiServerOnHealthDelta: {", inst, "} have no \"health_component\" component")
		return
	end
	inst._hi_current_health:set(health_component.currenthealth)
	inst._hi_current_damage:set_local(data.amount)
	inst._hi_current_damage:set(data.amount)
	-- print("HiServerOnHealthDelta: {", inst, "} new _hi_current_health value: ", inst._hi_current_health:value())
end

-- Subscription on all prefabs initialization. Here we create network variables, make subscriptions on events

AddPrefabPostInitAny(function(inst)
	-- print("AddPrefabPostInitAny: {", inst, "}: Start")
	inst._hi_current_health = GLOBAL.net_float(inst.GUID, "components.health._hi_current_health", "hi_on_current_health_dirty")
	inst._hi_current_damage = GLOBAL.net_float(inst.GUID, "components.health._hi_current_damage", "hi_on_current_damage_dirty")
	local health_component = inst.components.health
	if health_component ~= nil then
		inst._hi_current_health:set(health_component.currenthealth)
	end
	if GLOBAL.TheWorld.ismastersim then
		-- print("AddPrefabPostInitAny: {", inst, "}: setting up server subscriptions")
		inst:ListenForEvent("healthdelta", HiServerOnHealthDelta)
	end
	if not GLOBAL.TheNet:IsDedicated() then
		-- print("AddPrefabPostInitAny: {", inst, "}: setting up client subscriptions")
		inst:ListenForEvent("exitlimbo", HiClientOnEntityActive)
		inst:ListenForEvent("entitywake", HiClientOnEntityActive)
		inst:ListenForEvent("enterlimbo", HiClientOnEntityPassive)
		inst:ListenForEvent("entitysleep", HiClientOnEntityPassive)
		inst:ListenForEvent("onremove", HiClientOnEntityPassive)
		HiClientOnEntityActive(inst)
		inst:ListenForEvent("hi_on_current_health_dirty", HiClientOnHealthCurrentDirty)
		inst:ListenForEvent("hi_on_current_damage_dirty", HiClientOnDamageCurrentDirty)
	end
end)
