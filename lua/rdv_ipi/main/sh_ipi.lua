function IsProp(ent)
    if not ent:IsValid() then return false end
    local cls = ent:GetClass()

    if cls == "prop_physics" or cls == "prop_physics_multiplayer" or (cls == "prop_ragdoll" and RDV.LIBRARY.GetConfigOption("IPI::EnablingInteractRagdoll")) or cls == "npc_turret_floor" then
        return true
    end

    return false
end

local function RetryConnection()
    if timer.Exists("IPI::GetNewVersion") then return end
    timer.Create("IPI::GetNewVersion", 5, 0, function()
        print("[IPI] VERSION CHECK ERROR!!!")
        GetNewVersion()
    end)
end

function GetNewVersion()
    timer.Simple(5, function()
        if RDV.LIBRARY.GetConfigOption("IPI::CheckVersion") then
            local your_version = "1.1"

            http.Fetch("https://raw.githubusercontent.com/animerem/addons-version-check/main/checkversion.txt", 
                function(body)
                    local data = util.JSONToTable(body)["improved_prop_interact"]

                    if data ~= your_version then
                        if CLIENT then
                            chat.AddText(Color(220,20,20), "[IPI] ", color_white, "YOUR VERSION: ", your_version)
                            chat.AddText(Color(220,20,20), "[IPI] ", color_white, "A NEW VERSION: ", data)
                        else
                            print("[IPI] YOUR VERSION:", your_version)
                            print("[IPI] A NEW VERSION:", data)
                        end
                    end
                end, 
                function()
                    RetryConnection()
                end
            )
        end
    end)
end
GetNewVersion()