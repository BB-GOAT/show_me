-- equippable 组件：装备的精神回复与移速加成（dapperness 为 DS 遗产组件，存在时必伴随 equippable，Describe 内按组件形态分流）
local Describe = function(self, context)
    local c = context.entity.components
    local entries = {}

    -- item_info_mod：客户端显式开启优先，客户端为默认档(0)时跟随服务器设置
    local item_info_mod = context.config.client.item_info_mod
    if item_info_mod == 0 then
        item_info_mod = context.config.server.item_info_mod
    end
    if item_info_mod == 0 then
        local val
        if c.dapperness and c.dapperness.dapperness and type(c.dapperness.dapperness) == "number" and c.dapperness.dapperness ~= 0 then
            val = c.dapperness.dapperness
        elseif self.dapperness and type(self.dapperness) == "number" and self.dapperness ~= 0 then
            val = self.dapperness
        end
        if val then
            table.insert(entries, { data_key = "sanity", params = { context.utils.round2(val * 54, 1) } })
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
