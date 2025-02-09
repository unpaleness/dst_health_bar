-- Init started

for i, v in ipairs({ "_G", "setmetatable", "rawget" }) do
	env[v] = GLOBAL[v]
end

setmetatable(env,
{
	__index = function(table, key) return rawget(_G, key) end
})

modpath = package.path:match("([^;]+)")
package.path = package.path:sub(#modpath + 2) .. ";" .. modpath

--\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

PrefabFiles = {}
Assets = {}

--\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

local mem = setmetatable({}, { __mode = "v" })
local function argtohash(...) local str = ""; for i, v in ipairs(arg) do str = str .. tostring(v) end; return hash(str) end
local function memget(...) return mem[argtohash(...)] end
local function memset(value, ...) mem[argtohash(...)] = value end

GlobalNS =
{
	Dummy = function() end,
	True = function() return true end,
	ClampRemap = function(v, ...) return Remap(Clamp(v, ...), ...) end,

	Parallel = function(root, key, fn, lowprio)
		if type(root) == "table" then
			local oldfn = root[key]
			local newfn = oldfn and memget("PARALLEL", oldfn, fn)
			if not oldfn or newfn then
				root[key] = newfn or fn
			else
				if lowprio then
					root[key] = function(...) oldfn(...) return fn(...) end
				else
					root[key] = function(...) fn(...) return oldfn(...) end
				end
				memset(root[key], "PARALLEL", oldfn, fn)
			end
		end
	end,

	Sequence = function(root, key, fn, noselect)
		if type(root) == "table" then
			local oldfn = root[key] or GlobalNS.Dummy
			local newfn = memget("SEQUENCE", oldfn, fn)
			if newfn then
				root[key] = newfn
			else
				root[key] = function(...)
					local ret = { oldfn(...) }
					for i, v in pairs({ fn(ret[1], ...) }) do
						ret[i] = v
					end
					return unpack(ret)
				end
				memset(root[key], "SEQUENCE", oldfn, fn)
			end
		end
	end,

	Branch = function(root, key, fn)
		if type(root) == "table" then
			local oldfn = root[key]
			if oldfn then
				local newfn = memget("BRANCH", oldfn, fn)
				if newfn then
					root[key] = newfn
				else
					root[key] = function(...) return fn(oldfn, ...) end
					memset(root[key], "BRANCH", oldfn, fn)
				end
			end
		end
	end,

	GetUpvalue = function(fn, ...)
		local prevfn, i
		for _, name in ipairs(arg) do
			for _i = 1, math.huge do
				local _name, _upvalue = debug.getupvalue(fn, _i)
				if _upvalue == nil then
					return
				elseif _name == name then
					fn, i, prevfn = _upvalue, _i, fn
					break
				end
			end
		end
		return fn, i, prevfn
	end,

	BranchUpvalue = function(fn, ...)
		local upvalue = table.remove(arg)
		local fn, i, prevfn = GlobalNS.GetUpvalue(fn, unpack(arg))
		if type(fn) ~= "function" then
			debug.setupvalue(prevfn, i, upvalue(fn))
		else
			debug.setupvalue(prevfn, i, function(...) return upvalue(fn, ...) end)
		end
	end,

	Browse = function(table, ...)
		for i, v in ipairs(arg) do
			if type(table) ~= "table" then
				return
			end
			table = table[v]
		end
		return table
	end,

	OnEntityReplicated = function(inst, fn, lowprio)
		if TheWorld.ismastersim or inst.Network == nil then
			StartThread(fn, inst.GUID, inst)
		else
			GlobalNS.Parallel(inst, "OnEntityReplicated", fn, lowprio)
		end
	end,
}

if rawget(_G, "GlobalNS") == nil then
	rawset(_G, "GlobalNS", GlobalNS)
else
	for name, data in pairs(GlobalNS) do
		_G["GlobalNS"][name] = data
	end
	GlobalNS = _G["GlobalNS"]
end

-- Init ended

table.insert(PrefabFiles, "health_proxy")

-- Server only methods
if TheNet:GetIsServer() then
	AddComponentPostInit("health", function(self, inst)
		if inst.health_proxy == nil then
			inst.health_proxy = inst:SpawnChild("health_proxy")
			print("Created health proxy for ", inst, ": ", inst.health_proxy)
		end
	end)
end

-- Client only methods
if not TheNet:IsDedicated() then
	postinitfns.ControlsPostInit = {}

	function AddControlsPostInit(fn)
		table.insert(postinitfns.ControlsPostInit, fn)
	end

	AddSimPostInit(function()
		AddClassPostConstruct("widgets/controls", function(...)
			for i, v in ipairs(postinitfns.ControlsPostInit) do v(...) end
		end)
	end)

	-- AddControlsPostInit(function(self, owner)
	-- local HpWidget = require "widgets/hpwidget"
	-- self.hpwidget = self.top_root:AddChild(HpWidget(owner))
	-- self.hpwidget:SetPosition(0, 0)
	-- end)
end
