local angCamera_Current = Angle()
local angPlayer_Current = Angle()
    
local bProp_Interact = false

local eCurrent_Prop = {}
local plyLocal = {}

net.Receive("IPI::NetworkString", function()        
    bProp_Interact = net.ReadBool()
    plyLocal = LocalPlayer()

    if bProp_Interact then
        eCurrent_Prop = net.ReadEntity()
        vecProp_Current = net.ReadVector()
    else 
        eCurrent_Prop = nil
    end
end)

// Main function to determine the rendering of prop interaction
local function hook_prop_interact_render(ang)        
    if not bProp_Interact then return end
    local B = false

    // Do prop rotation rendering
    // Minimal due to rotation occuring on the server
    if plyLocal:KeyDown(IN_RELOAD) then
        B = true
    end
    
    // Do prop position rendering for each axis
    if input.IsKeyDown(KEY_1) then
        B = true
    end
    if input.IsKeyDown(KEY_2) then
        B = true
    end
    if input.IsKeyDown(KEY_3) then
        B = true
    end
    
    // Update when not manipulating prop
    if not B then
        angPlayer_Current = plyLocal:EyeAngles()
        angCamera_Current = ang
    end

    return B
end

// Client-Side Hooks

hook.Add("CalcView", "IPI::CalcView", function(ply, ori, ang)
    if !RDV.LIBRARY.GetConfigOption("IPI::Enabling") then return end

    local interact = hook_prop_interact_render(ang)
    
    if interact then
        plyLocal:SetEyeAngles(angPlayer_Current)            
        return {angles = angCamera_Current}
    end
end)