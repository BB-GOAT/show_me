-- healer 组件：物品的治疗量
local Describe = function(self, context)
    if context.config.client.item_info_mod ~= 0 then
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
