print("Hello Constant!")

local SERVER_SIDE = TheNet:GetIsServer()
local CLIENT_SIDE =	 TheNet:GetIsClient() or (SERVER_SIDE and not TheNet:IsDedicated())

local function AddDebugWidget( inst )
    local controls = inst.HUD.controls
    controls.minimap_small = controls.top_root:AddChild( MiniMapWidget( mapscale ) )
end

if CLIENT_SIDE == true then
    AddSimPostInit( AddDebugWidget )
end
