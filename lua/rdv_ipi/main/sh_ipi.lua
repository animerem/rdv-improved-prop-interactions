function IsProp(ent)
    local cls = ent:GetClass()

    if cls == "prop_physics" or cls == "prop_physics_multiplayer" or cls == "prop_ragdoll" then
        return true
    end

    return false
end