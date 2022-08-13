util.AddNetworkString("IPI::NetworkString")

// Prop Conditions 

local function IsSmallProp(prop)
    return prop:GetPhysicsObject():GetMass() <= 35
end

local function IsPropInRange(ply)
    local dist = ply.fProp_Dist

    if dist < RDV.LIBRARY.GetConfigOption("IPI::MaximumDistance") and dist >= RDV.LIBRARY.GetConfigOption("IPI::MinimumDistance") then
        return true
    end

    return false
end

local function IsPropCarriable(ply, ent)
    local mass = 35 * RDV.LIBRARY.GetConfigOption("IPI::CarryStrength")

    if mass >= ent:GetPhysicsObject():GetMass() then
        return true
    else
        return false
    end

    return false
end

// Object Space Correction/Preservation

local function CalcPreservedCarryAngles(ply, ent)
    local ang = ply:EyeAngles()
    local ea = ent:GetAngles()
    local a = Angle(ea[1], -ang[2] + ea[2], ea[3])
    a:RotateAroundAxis(Vector(0, -1, 0), ang[1])

    return a
end

// Player Prop Manipulation

local function ThrowProp(ent, ply)
    ent:GetPhysicsObject():SetVelocity(ply:GetAimVector() * RDV.LIBRARY.GetConfigOption("IPI::ThrowPower") + ply:GetVelocity())
end

local function RotateProp(ang, x, y)
    local sense = 10 / RDV.LIBRARY.GetConfigOption("IPI::AngSensitivity")

    ang:RotateAroundAxis(Vector(0, 0, 1), x / sense)
    ang:RotateAroundAxis(Vector(0, -1, 0), y / sense)
end

local function NudgeProp(ent, ply, tr)
end


local function hook_prop_interact_use(ply, item)
    if !RDV.LIBRARY.GetConfigOption("IPI::Enabling") then return end

    if IsProp(item) then
        local tr = ply:GetEyeTraceNoCursor()
        if ply.bProp_Interact or ply.bProp_Interact_Physgun then return end

        ply.fProp_Dist = (tr.HitPos - ply:EyePos()):Length()   

        if IsPropInRange(ply) then
            if not IsPropCarriable(ply, item) then
                NudgeProp(item, ply, tr)
            end 
        end

        local phys = item:GetPhysicsObject()

        if 35 * RDV.LIBRARY.GetConfigOption("IPI::CarryStrength") > phys:GetMass() or IsSmallProp(item) then
            return false
        end
    end
end

// Server-Side Hooks

hook.Add("KeyPress", "IPI::KeyPress", function(ply, key)
    if !RDV.LIBRARY.GetConfigOption("IPI::Enabling") then return end

    if key == IN_USE then
        local tr = ply:GetEyeTraceNoCursor()
        local ent = tr.Entity

        if tr.Hit and ent then
            if IsProp(ent) then
                if ply.bProp_Interact or ply.bProp_Interact_Physgun then return end

                ply.fProp_Dist = (tr.HitPos - ply:EyePos()):Length()                    
                if not IsPropInRange(ply) then return end

                if IsPropCarriable(ply, ent) then
                    timer.Simple(0, function()
                        ply:PickupObject(ent)
                    end)
                end
            end
        end
    end
end)

hook.Add("PhysgunPickup", "IPI::PhysgunPickup", function(ply, item)
    if !RDV.LIBRARY.GetConfigOption("IPI::Enabling") then return end

    ply.bProp_Interact_Physgun = true
end)

hook.Add("PhysgunDrop", "IPI::PhysgunDrop", function(ply, item)
    if !RDV.LIBRARY.GetConfigOption("IPI::Enabling") then return end

    ply.bProp_Interact_Physgun = false
end)

hook.Add("OnPlayerPhysicsPickup", "IPI::OnPlayerPhysicsPickup", function(ply, item)
    if !RDV.LIBRARY.GetConfigOption("IPI::Enabling") then return end

    ply.bProp_Interact = true
    ply.bProp_Interact_Physgun = false
    ply.angProp_Current = CalcPreservedCarryAngles(ply, item)

    net.Start("IPI::NetworkString")
        net.WriteBool(true)
        net.WriteEntity(item)
        net.WriteVector(Vector())
    net.Send(ply)
end)

hook.Add("GetPreferredCarryAngles", "IPI::GetPreferredCarryAngles", function(item, ply)
    if !RDV.LIBRARY.GetConfigOption("IPI::Enabling") then return end

    if not ply.bProp_Interact then return end
    local ucmd = ply:GetCurrentCommand()

    if ply:KeyDown(IN_RELOAD) then
        RotateProp(ply.angProp_Current, ucmd:GetMouseX(), ucmd:GetMouseY())

        ply:SetEyeAngles(ply.angPlayer_Current)
    else
        ply.angPlayer_Current = ply:EyeAngles()
    end

    return ply.angProp_Current
end)

hook.Add("OnPlayerPhysicsDrop", "IPI::OnPlayerPhysicsDrop", function(ply, item, thrown)
    if !RDV.LIBRARY.GetConfigOption("IPI::Enabling") then return end

    ply.bProp_Interact = false

    net.Start("IPI::NetworkString")
        net.WriteBool(false)
    net.Send(ply)

    if thrown then
        ThrowProp(item, ply)
    end
end)

// use fix

timer.Simple(0, function()
    local useHooks = hook.GetTable().PlayerUse

    if useHooks then
        for name, call in pairs(useHooks) do
            local _call = call
            call = function(ply, ent)
                timer.Simple(0.5, function() _call(ply, ent) end)
                return hook_prop_interact_use(ply, ent)
            end

            hook.Add("PlayerUse", name, call)
        end
    else
        hook.Add("PlayerUse", "IPI::PlayerUse", function(ply, item)
            return hook_prop_interact_use(ply, item)
        end)
    end
end)