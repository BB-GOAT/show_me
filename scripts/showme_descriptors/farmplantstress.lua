-- farmplantstress 组件：耕地农作物的压力点与压力原因（新版农场系统）
local Describe = function(self, context)
    -- T_crop：客户端显式关闭优先，客户端为默认档(true)时跟随服务器设置
    local T_crop = context.config.client.T_crop
    if T_crop then
        T_crop = context.config.server.T_crop
    end
    if not T_crop or not self.stress_points then
        return nil
    end

    local entity = context.entity
    local utils = context.utils
    local x, y, z = entity.Transform:GetWorldPosition()
    local g = utils.GetTileNutrientsAtPoint(x, y, z)
    local m = utils.GetTileMoistureAtPoint(x, y, z)
    local entries = {
        { data_key = "nutrient", params = { m, g.formula, g.compost, g.manure } },
    }

    -- 压力原因
    local reason = { self.stress_points }
    if self.stressors_testfns then
        for k, fn in pairs(self.stressors_testfns) do
            if k == 'happiness' then
                if self.stressors and self.stressors.happiness then
                    table.insert(reason, k)
                end
            else
                local bool = fn(entity, k, false)
                if bool then
                    table.insert(reason, k)
                end
            end
        end
    end
    table.insert(entries, { data_key = "stress_tag", params = { table.concat(reason, ",") } })

    return entries
end

return {
    Describe = Describe,
}
