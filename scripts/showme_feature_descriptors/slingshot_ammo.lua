-- slingshot_ammo：弹弓弹药的伤害与位面伤害
local AMMO_DATA -- 弹弓弹药数据

local function GetAmmoData(utils) -- 首次获取数据
    AMMO_DATA = {}
    for _, v in pairs(Prefabs) do -- 获取官方 Prefab
        if v.fn and debug.getinfo(v.fn, "S").source == "scripts/prefabs/slingshotammo.lua" then -- Prefab 的 Fn
            if v.name:sub(-5) == "_proj" then
                local ammo_data = utils.Upvaluehelper.GetUpvalue(v.fn, "data") -- "v" > "data"
                if ammo_data ~= nil and type(ammo_data) == "table" then
                    AMMO_DATA[ammo_data.name] = ammo_data
                end
            end
        end
    end
end

local Describe = function(context)
    if not AMMO_DATA then
        GetAmmoData(context.utils)
    end
    local ammo_data = AMMO_DATA and AMMO_DATA[context.entity.prefab]
    if ammo_data == nil then
        return nil
    end

    local entries = {}
    if ammo_data.damage ~= nil then
        table.insert(entries, { data_key = "dmg", params = { ammo_data.damage } })
    end
    if ammo_data.planar ~= nil then
        table.insert(entries, { data_key = "basedmg", params = { ammo_data.planar } })
    end
    if #entries == 0 then
        return nil
    end
    return entries
end

return {
    tags = { slingshotammo = true },
    Describe = Describe,
}
