-- healer 组件：物品的治疗量
local Describe = function(self, context)
    -- item_info_mod：客户端显式开启优先，客户端为默认档(0)时跟随服务器设置
    local item_info_mod = context.config.client.item_info_mod
    if item_info_mod == 0 then
        item_info_mod = context.config.server.item_info_mod
    end
    if item_info_mod ~= 0 then
        return nil
    end
    local heal = context.utils.round2(self.health, 1)
    if heal == 0 and context.entity.prefab == "spider_healer_item" then
        heal = TUNING.HEALING_MEDSMALL -- 治疗蛛巢切割器的治疗量未写入组件，取同档常量
    end
    if heal and heal ~= 0 then
        return {
            data_key = "heal",
            params = { heal },
        }
    end
    return nil
end

return {
    Describe = Describe,
}
