-- equippable 组件：装备的精神回复与移速加成（dapperness 为 DS 遗产组件，存在时必伴随 equippable，Describe 内按组件形态分流）

-- 与原版 sanity 更新路径一致，包含角色覆盖、潮湿豁免与精神倍率。
local function GetEquipmentSanity(item, viewer)
    local c = item.components
    if c.dapperness then -- 兼容使用旧版独立组件的模组
        return c.dapperness.dapperness * 60
    end

    local equippable = c.equippable
    if not equippable then return end
    local sanity = viewer and viewer.components.sanity
    local value
    if sanity and sanity.get_equippable_dappernessfn then
        value = sanity.get_equippable_dappernessfn(viewer, equippable)
    end
    if not value then -- 与原版一致，角色回调未给出结果时使用装备自身的计算。
        value = equippable.GetDapperness
            and equippable:GetDapperness(viewer, sanity and sanity.no_moisture_penalty)
            or equippable.dapperness
    end
    return value * (sanity and sanity.dapperness_mult or 1) * TUNING.SANITY_DAPPERNESS * 60
end

local Describe = function(self, context)
    local entries = {}

    -- item_info_mod：客户端显式开启优先，客户端为默认档(0)时跟随服务器设置
    local item_info_mod = context.config.client.item_info_mod
    if item_info_mod == 0 then
        item_info_mod = context.config.server.item_info_mod
    end
    if item_info_mod == 0 then
        local val = GetEquipmentSanity(context.entity, context.player)
        if val and val ~= 0 then
            table.insert(entries, { data_key = "sanity", params = { context.utils.round2(val, 1) } })
        end
    end

    -- 移速（仅在可装备item上显示）
    if self.walkspeedmult and self.walkspeedmult ~= 1 then
        local added_speed = math.floor((self.walkspeedmult - 1) * 100 + 0.5)
        table.insert(entries, { data_key = "speed", params = { added_speed } })
    end

    if #entries == 0 then
        return nil
    end
    return entries
end

return {
    Describe = Describe,
}
