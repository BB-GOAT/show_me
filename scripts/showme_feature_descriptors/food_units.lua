-- food_units：食材的填充单位（eg 蔬菜类/肉类 值）
-- 食材注册（cooking.AddIngredientValues）可发生在任意模组 modmain 乃至运行时，路由键无法快照，
-- 经 MatchPrefab 供调度层运行时动态匹配（与原版 modmain 的 ing[prefab] 动态查询语义一致）
local ing = require("cooking").ingredients

local Describe = function(context)
    local food = ing[context.entity.prefab]
    if not food or not food.tags then
        return nil
    end

    -- show_food_units 数值档：客户端显式设置优先，默认档(-1)跟随服务器；0(客户端关)与 2(服务器禁止)都在生成层拦截不发送
    local show_food_units = context.config.client.show_food_units
    if show_food_units == -1 then
        show_food_units = context.config.server.show_food_units
    end
    if show_food_units == 0 or show_food_units == 2 then
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
    MatchPrefab = function(prefab)
        return ing[prefab] ~= nil
    end,
    Describe = Describe,
}
