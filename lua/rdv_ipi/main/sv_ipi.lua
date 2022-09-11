util.AddNetworkString("IPI::NetworkString")

// Prop Conditions 

local function IsSmallProp(prop)
    return prop:GetPhysicsObject():GetMass() <= 35
end

local function IsPropNear(ply)
    local dist

    if ply:IsBot() then
        dist = ply.fBot_PropMaxDist
    else
        dist = RDV.LIBRARY.GetConfigOption("IPI::MaximumDistance")
    end

    if ply.fProp_Dist < dist then
        return true
    end

    return false
end

local function IsPropCarriable(ply, ent)
    local mass
    
    if ply:IsBot() then
        mass = ply.fBot_PropCarryStrength
    else
        mass = RDV.LIBRARY.GetConfigOption("IPI::CarryStrength")
    end

    if 35 * mass >= ent:GetPhysicsObject():GetMass() then
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
    local power

    if ply:IsBot() then
        power = ply.fBot_PropThrowPower
    else
        power = RDV.LIBRARY.GetConfigOption("IPI::ThrowPower")
    end

    ent:GetPhysicsObject():SetVelocity(ply:GetAimVector() * power + ply:GetVelocity())
end

local function RotateProp(ply, ang, x, y)
    local sense
    
    if ply:IsBot() then
        sense = 10 / ply.fBot_PropAngSense
    else
        sense = 10 / RDV.LIBRARY.GetConfigOption("IPI::AngSensitivity")
    end

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

        if IsPropNear(ply) then
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

hook.Add("PlayerInitialSpawn", "IPI::PlayerInitialSpawn", function(ply, trans)
    if not trans and ply:IsBot() then
        ply.fBot_PropAngSense = 1
        ply.fBot_PropCarryStrength = 1
        ply.fBot_PropThrowPower = 1
        ply.fBot_PropMaxDist = 108
    end
end)

hook.Add("KeyPress", "IPI::KeyPress", function(ply, key)
    if !RDV.LIBRARY.GetConfigOption("IPI::Enabling") then return end

    if key == IN_USE then
        local tr = ply:GetEyeTraceNoCursor()
        local ent = tr.Entity

        if tr.Hit and ent then
            if IsProp(ent) then
                if ply.bProp_Interact or ply.bProp_Interact_Physgun then return end

                ply.fProp_Dist = (tr.HitPos - ply:EyePos()):Length()                    
                if not IsPropNear(ply) then return end

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
        RotateProp(ply, ply.angProp_Current, ucmd:GetMouseX(), ucmd:GetMouseY())

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

local bVManipAnim_NoRun = false

hook.Add("PlayerUse", "IPI::PlayerUse", function(ply, item)
    bVManipAnim_NoRun = true
    return hook_prop_interact_use(ply, item)
end)

timer.Simple(0.5, function()
    local VManipUseHook = hook.GetTable().PlayerUse.VManip_UseAnim
    if not VManipUseHook then return end

    hook.Add("PlayerUse", "VManip_UseAnim", function(ply, ent)
        if IsProp(ent) then
            if not IsPropCarriable(ply, ent) then
                return VManipUseHook(ply, ent)
            end
        else
            return VManipUseHook(ply, ent)
        end
    end)
end)