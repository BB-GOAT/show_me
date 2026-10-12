-- waterproofer 组件：防水率描述
local Describe = function(self, context)
    -- item_info_mod：客户端显式开启优先，客户端为默认档(0)时跟随服务器设置
    local item_info_mod = context.config.client.item_info_mod
    if item_info_mod == 0 then
        item_info_mod = context.config.server.item_info_mod
    end
    if item_info_mod ~= 0 then
        return nil
    end

    local utils = context.utils

    local effectiveness = tonumber(self.effectiveness) or 0
    if effectiveness ~= 0 then
        return { data_key = "waterproof", params = { utils.round2(effectiveness * 100, 0) } }
    end
    return nil
end

return {
    Describe = Describe,
}
