-- farmplantstress 组件：耕地农作物的压力点与压力原因（新版农场系统）

--- 判断查看者能否查看耕地农作物状态（需装备耕作先驱帽或园艺帽，沃姆伍德可直接查看）
---@param viewer table 玩家
---@return boolean can_view
local function CanViewCropStress(viewer)
    if viewer == nil then
        return false
    end
    if viewer.prefab == "wormwood" then
        return true
    end
    local inv = viewer.components and viewer.components.inventory
    local hat = inv and inv:GetEquippedItem(EQUIPSLOTS.HEAD)
    return (hat and (hat.prefab == "plantregistryhat" or hat.prefab == "nutrientsgoggleshat")) ~= nil
end

local Describe = function(self, context)
    -- T_crop_mode 档位：0 关 / 1 耕作先驱帽或沃姆伍德才显示 / 2 开
    -- 客户端显式配置优先
    local T_crop_mode = context.config.client.T_crop_mode
    if T_crop_mode == nil then
        T_crop_mode = context.config.server.T_crop_mode
    end
    if not T_crop_mode or T_crop_mode == 0 or not self.stress_points then
        return nil
    end
    -- 帽子档：需装备耕作先驱帽或园艺帽，沃姆伍德可直接查看
    if T_crop_mode == 1 and not CanViewCropStress(context.player) then
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

    table.insert(entries, { data_key = "stress_tag", params = reason })

    return entries
end

return {
    Describe = Describe,
}
