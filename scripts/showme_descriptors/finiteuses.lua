-- finiteuses 组件：工具、武器的剩余使用次数
local C_FINITEUSES_PREFAB = { -- 各 prefab 的“次数”显示换算倍率
    spiderden_bedazzler = 0.05,
    spider_repellent = 0.1,
    spider_whistle = 0.5,
}

local Describe = function(self, context)
    -- 服务器 show_uses 禁止档强制不发送；两项生效值均为客户端显式设置优先，默认档跟随服务器
    if context.config.server.show_uses == 2 then
        return nil
    end
    local item_info_mod = context.config.client.item_info_mod
    if item_info_mod == 0 then
        item_info_mod = context.config.server.item_info_mod
    end
    local show_uses = context.config.client.show_uses
    if show_uses == -1 then
        show_uses = context.config.server.show_uses
    end
    if item_info_mod ~= 0 or show_uses == 0 then
        return nil
    end
    if context.entity:HasTag("hide_percentage") then
        return nil
    end

    local mult = C_FINITEUSES_PREFAB[context.entity.prefab]
    if self.consumption then
        for _, v in pairs(self.consumption) do
            local new_mult = 1 / v
            if mult == nil or new_mult > mult then
                mult = new_mult
            end
        end
    end
    if mult == nil then
        mult = 1
    end

    local cur = math.floor(self.current * mult + 0.5)
    if self.current * mult > cur then
        cur = cur + 1
    end

    return {
        data_key = "uses_of",
        params = { cur, math.floor(self.total * mult + 0.5) },
    }
end

return {
    Describe = Describe,
}
