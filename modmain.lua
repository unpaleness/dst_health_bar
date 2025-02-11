local HiHpWidget = nil
local HiDamageWidget = nil
if not GLOBAL.TheNet:IsDedicated() then
	HiHpWidget = require "widgets/hi_hp_widget"
	HiDamageWidget = require "widgets/hi_damage_widget"
end

local function HiTryCreateHpWidget(inst)
	if not GLOBAL.TheNet:IsDedicated() and GLOBAL.ThePlayer ~= nil and inst.hi_hp_widget == nil then
		inst.hi_hp_widget = GLOBAL.ThePlayer.HUD.overlayroot:AddChild(HiHpWidget(inst))
		inst.hi_hp_widget:SetHp(inst._hi_currenthealth:value())
	end
end

local function HiTryRemoveHpWidget(inst)
	if not GLOBAL.TheNet:IsDedicated() and inst.hi_hp_widget ~= nil then
		inst.hi_hp_widget:Kill()
		inst.hi_hp_widget = nil
	end
end

local function HiOnHealthCurrentDirty(inst)
	if inst._hi_currenthealth == nil then
		return
	end
	local health = inst._hi_currenthealth:value()
	if health <= 0 then
		HiTryRemoveHpWidget(inst)
		return
	end
	HiTryCreateHpWidget(inst)
	if inst.hi_hp_widget ~= nil then
		inst.hi_hp_widget:SetHp(inst._hi_currenthealth:value())
	end
end

local function HiOnHealthDelta(inst, data)
	local health = inst.components.health
    if health == nil then
		print("HiOnHealthDelta: {", inst, "} have no \"health\" component")
		return
	end
	inst._hi_currenthealth:set(health.currenthealth * data.newpercent)
	print("HiOnHealthDelta: {", inst, "} new _hi_currenthealth value: ", inst._hi_currenthealth:value())
end

-- local function HiOnEntityWake(inst)
-- 	print("HiOnEntityWake: {", inst, "}")
-- 	if not GLOBAL.TheNet:IsDedicated() then
-- 		HiTryCreateHpWidget(inst)
-- 	end
-- end

-- local function HiOnEntitySleep(inst)
-- 	print("HiOnEntitySleep: {", inst, "}")
-- 	HiTryRemoveHpWidget(inst)
-- end

-- AddComponentPostInit("health", function(self, inst)
-- 	if GLOBAL.TheWorld.ismastersim then
-- 		if inst._hi_currenthealth ~= nil then -- already initialized
-- 			return
-- 		end
-- 		-- inst.entity:AddNetwork()
-- 		inst._hi_currenthealth = GLOBAL.net_float(inst.GUID, "components.health._hi_currenthealth", "hi_on_currenthealth_dirty")
-- 		inst._hi_currenthealth:set(inst.components.health.currenthealth)
-- 		inst:ListenForEvent("healthdelta", HiOnHealthDelta)
-- 	end
-- end)

AddPrefabPostInitAny(function(inst)
	print("AddPrefabPostInitAny: {", inst, "}: Start")
	inst._hi_currenthealth = GLOBAL.net_float(inst.GUID, "components.health._hi_currenthealth", "hi_on_currenthealth_dirty")
	local health_component = inst.components.health
	if health_component ~= nil then
		inst._hi_currenthealth:set(health_component.currenthealth)
	end
	if GLOBAL.TheWorld.ismastersim then
		print("AddPrefabPostInitAny: {", inst, "}: setting up server subscriptions")
		inst:ListenForEvent("healthdelta", HiOnHealthDelta)
	end
	if not GLOBAL.TheNet:IsDedicated() then
		print("AddPrefabPostInitAny: {", inst, "}: setting up client subscriptions")
		-- inst:ListenForEvent("entitywake", HiOnEntityWake)
		-- inst:ListenForEvent("entitysleep", HiOnEntitySleep)
		-- inst:ListenForEvent("onremove", HiOnEntitySleep)
		-- if not inst:IsAsleep() then
		-- 	HiOnEntityWake(inst)
		-- end
		inst:ListenForEvent("hi_on_currenthealth_dirty", HiOnHealthCurrentDirty)
		HiOnHealthCurrentDirty(inst)
	end
end)
