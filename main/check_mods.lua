-- server_mods：服务器端启用模组检测
local TheNet = _G.TheNet
local active_mods_by_name = {}
if TheNet and TheNet:GetIsServer() then
    for name,mod in pairs(_G.KnownModIndex.savedata.known_mods or {}) do
        if KnownModIndex:IsModEnabledAny(name) then
            local real_name = mod.modinfo.name
            if real_name == nil then
                print("[Show Me] ERROR: real_name of a mod is nil ",tostring(name))
            else
                active_mods_by_name[real_name] = true
            end
        end
    end

    local is_DisplayFoodValues = active_mods_by_name["Display food values"]
    local is_HealthInfo --检查服务器血量显示模组
    for name in pairs(active_mods_by_name) do
        if name:find("简易血条",1,true) or name:find("Health Bar",1,true) then
            is_HealthInfo = true
            break
        end
    end

    return {
        is_HealthInfo = is_HealthInfo,
        is_DisplayFoodValues = is_DisplayFoodValues,
    }
end