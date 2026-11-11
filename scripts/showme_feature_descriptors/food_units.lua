-- food_units：食材的填充单位
local ing = require("cooking").ingredients

local Describe = function(context)
    local food = ing[context.entity.prefab]
    if not food or not food.tags then
        return nil
    end

    -- 服务端禁止时不发送；否则客户端显式设置优先，默认档(-1)跟随服务器
    if context.config.server.show_food_units == 2 then
        return nil
    end
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