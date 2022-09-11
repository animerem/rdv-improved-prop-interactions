local angCamera_Current = Angle()
local angPlayer_Current = Angle()
    
local bProp_Interact = false

local eCurrent_Prop = nil
local plyLocal = {}

function W(w)
    return ScrW()*(w/1920)
end
function H(h)
    return ScrH()*(h/1080)
end

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

hook.Add("PreDrawHalos", "IPI::PreDrawHalos", function()
    if !RDV.LIBRARY.GetConfigOption("IPI::Enabling") then return end
    if !RDV.LIBRARY.GetConfigOption("IPI::HaloEnabling") then return end

    if eCurrent_Prop ~= nil then
	    halo.Add( { eCurrent_Prop }, RDV.LIBRARY.GetConfigOption("IPI::HaloColor"), 5, 5, 2 )
    end
end)

surface.CreateFont( "IPI:Font", {
	font = "Arial",
	extended = true,
	size = W(40),
	weight = 500,
	antialias = true,
	strikeout = true,
} )

hook.Add("HUDPaint", "IPI::PropInteract", function()
    if !LocalPlayer():Alive() then lerp_alpha = 0 return end
    if !RDV.LIBRARY.GetConfigOption("IPI::Enabling") then return end
    if !RDV.LIBRARY.GetConfigOption("IPI::VisualPressUSE") then return end

    local gc = {
        "prop_physics", "prop_physics_multiplayer", "npc_turret_floor"
    }

    if RDV.LIBRARY.GetConfigOption("IPI::EnablingInteractRagdoll") then
        table.insert(gc, "prop_ragdoll")
    else
        if table.Count(gc) == 4 then
            table.remove(gc, 4)
        end
    end

    if LocalPlayer():GetEyeTrace().Entity and IsValid(LocalPlayer():GetEyeTrace().Entity) and not LocalPlayer():InVehicle() and eCurrent_Prop == nil and LocalPlayer():GetPos():DistToSqr(LocalPlayer():GetEyeTrace().Entity:GetPos()) <= 120 * 120 then
        if table.HasValue(gc, LocalPlayer():GetEyeTrace().Entity:GetClass()) then
            local ent = LocalPlayer():GetEyeTrace().Entity
            local phys = ent:GetPhysicsObject()
            if IsValid(ent) and IsValid(phys) and (35 * RDV.LIBRARY.GetConfigOption("IPI::CarryStrength") > phys:GetMass() or IsSmallProp(ent)) then
                --
            else
                lerp_alpha = Lerp(FrameTime()*3, lerp_alpha or 0, 255)
            end
        else
            lerp_alpha = Lerp(FrameTime()*3, lerp_alpha or 0, 0)
        end
    else
        lerp_alpha = Lerp(FrameTime()*3, lerp_alpha or 0, 0)
    end

    if lerp_alpha > 1 then
        if RDV.LIBRARY.GetConfigOption("IPI::VisualPressUSEVariants") == "Default" then
            surface.SetFont("IPI:Font")
            local use = string.upper(input.LookupBinding('+use'))
            local text = string.format("Нажмите %s чтобы поднять", use)
            local textw = surface.GetTextSize(text)
            local w, h = 50, 50

            draw.RoundedBox(5, (ScrW()*0.513-W(w))-textw/2, ScrH()*0.84-H(h), W(w)+textw, H(h), Color(20,20,20,math.Clamp(lerp_alpha,0,200)))

            local color = RDV.LIBRARY.GetConfigOption("IPI::VisualPressUSEColor")
            draw.SimpleText(text, "IPI:Font", ScrW()*0.5, ScrH()*0.8, Color(color.r,color.g,color.b,lerp_alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        elseif RDV.LIBRARY.GetConfigOption("IPI::VisualPressUSEVariants") == "Two" then
            local use = string.upper(input.LookupBinding('+use'))

            local w, h = 70, 70
            draw.RoundedBox(5, (ScrW()*0.513-W(w)), ScrH()*0.84-H(h), W(w), H(h), Color(0,0,0,math.Clamp(lerp_alpha,0,255)))
            draw.RoundedBox(5, (ScrW()*0.513-W(w-10/2)), ScrH()*0.84-H(h-10/2), W(w-10), H(h-10), Color(212,212,212,math.Clamp(lerp_alpha,0,255)))
            draw.RoundedBox(5, (ScrW()*0.513-W(w-20/2)), ScrH()*0.84-H(h-20/2), W(w-20), H(h-20), Color(0,0,0,math.Clamp(lerp_alpha,0,255)))

            local color = RDV.LIBRARY.GetConfigOption("IPI::VisualPressUSEColor")
            draw.SimpleText(use, "IPI:Font", ScrW()*0.5-W(12), ScrH()*0.8-H(10), Color(color.r,color.g,color.b,lerp_alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        end
    end
end)
