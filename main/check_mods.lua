-- server_mods：服务器端启用模组检测
local TheNet = _G.TheNet

local GetGlobal=function(gname,default)
    local res=_G.rawget(_G,gname)
    if res == nil and default ~= nil then
        _G.rawset(_G,gname,default)
        return default
    end
    return res
end

-- 增加其他模组的兼容性
local mods = GetGlobal("mods",{}) -- 冰冰羊：什么屎山代码..不敢删..

-- 只在主机上工作：原 modmain2 HOST 分区门控原样随迁，非服务器端不执行检测与共享表挂载
if TheNet and TheNet:GetIsServer() then

--检测启用的模组
local mod_names     --названия всех модов (чтобы не дергать джвижок)
local mod_names_nover --названия модов с обрезанной версией (если смысловая часть достаточно длинная)
mod_names = {}
mod_names_nover = {}
local function GetAllModNames()
    if not (_G.KnownModIndex and _G.KnownModIndex.savedata and _G.KnownModIndex.savedata.known_mods
        and _G.ModManager and _G.ModManager.enabledmods)
    then
        return
    end
    local folders = {} --ассоциативный массив включенных модов (по папкам)
    for _,v in ipairs(_G.ModManager.enabledmods) do
        folders[v]=true
    end
    for folder, mod in pairs(_G.KnownModIndex.savedata.known_mods) do
        local name = mod.modinfo.name
        if name then
            mod_names[name]=folders[folder] and true or false
            --print("NEW_MOD: "..name.." "..tostring(mod_names[name]))
            local s=string.match(name,"^(.-)([0-9%._ ]+)$")
            if s then
                mod_names_nover[s]=name --обрезаем номер версии с конца
                --вместо true сохраняем полное имя мода (чтобы идентифицировать его в системе)
            else
                mod_names_nover[name]=name
            end
        end
    end
end
GetAllModNames()
mods.mod_names = mod_names
mods.mod_names_nover = mod_names_nover

local function SearchForModsByName()
    mods.active_mods_by_name = {}
    if not (_G.KnownModIndex and _G.KnownModIndex.savedata and _G.KnownModIndex.savedata.known_mods) then
        print("ERROR COMMON LIB: Can't find KnownModIndex!")
        return
    end
    for name,mod in pairs(_G.KnownModIndex.savedata.known_mods) do
        if (mod.enabled or mod.temp_enabled or _G.KnownModIndex:IsModForceEnabled(name)) --Мод активен
            and not mod.temp_disabled --И не отключен
        then
            local real_name = mod.modinfo.name
            if real_name == nil then
                print("SHOW_ME ERROR: real_name of a mod is nil,",tostring(name))
                --TODO: error if TUNING.STAR_DEBUG
            else
                mods.active_mods_by_name[real_name] = true
            end
        end
    end
end
SearchForModsByName()

local is_HealthInfo = nil --检查服务器血量显示模组
for name in pairs(mods.active_mods_by_name) do
    if name:find("简易血条",1,true) or name:find("Health Bar",1,true) then
        is_HealthInfo = true
        break
    end
end

local is_DisplayFoodValues = mods.active_mods_by_name["Display food values"]

return {
    is_HealthInfo = is_HealthInfo,
    is_DisplayFoodValues = is_DisplayFoodValues,
}
end

return {}
