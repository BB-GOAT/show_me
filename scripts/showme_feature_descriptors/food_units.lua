-- food_units：食材的填充单位（eg 蔬菜类/肉类 值），prefabs 集合直接取自烹饪材料表
local ing = require("cooking").ingredients

local prefabs = {}
for k in pairs(ing) do
    prefabs[k] = true
end

local Describe = function(context)
    local food = ing[context.entity.prefab]
    if not food or not food.tags then
        return nil
    end

    -- show_food_units 数值档：2=服务器禁止；客户端显式设置优先，默认档(-1)跟随服务器
    local show_food_units = context.config.client.show_food_units
    if show_food_units == -1 then
        show_food_units = context.config.server.show_food_units
    end
    if show_food_units == 2 then
        return nil
    end

    local entries = {}
    for k, v in pairs(food.tags) do
        if k ~= "precook" and k ~= "dried" then
            table.insert(entries, { data_key = "units_of", params = { v, k } })
        end
    end
    if #entries == 0 then
        return nil
    end
    return entries
end

return {
    prefabs = prefabs,
    Describe = Describe,
}
