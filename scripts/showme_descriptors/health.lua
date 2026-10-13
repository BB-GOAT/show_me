-- health 组件：生物血量与防御
local Describe = function(self, context)
    local entity = context.entity
    if entity.grow_stage then
        return nil -- 石果等生长体不显示血量，由 growable 显示阶段
    end

    local utils = context.utils
    local entries = {}

    local need_send_hp = (context.config.server.display_hp == 1 -- 开
                        or (context.config.server.display_hp == -1 and not context.config.server.is_HealthInfo) -- 自动 + 没开简易血条
                        or context.config.server.display_hp == 0) -- 关（但不是禁止）
                        and (context.config.client.display_hp == -1 or context.config.client.display_hp == 1) -- 客户端设置（自动 / 开）

    if need_send_hp and self.minhealth ~= nil then
        local mx = math.ceil(self.maxhealth - self.minhealth)
        local cur = math.ceil(self.currenthealth - self.minhealth)
        if cur > mx then cur = mx end
        table.insert(entries, { priority = 100, data_key = "hp", params = { cur, mx } }) -- 血量
    end

    if self.absorb ~= 0 or self.playerabsorb ~= 0 then
        local perc = 1 - (1 - self.absorb) * (1 - self.playerabsorb)
        table.insert(entries, { data_key = "armor_character", params = { utils.round2(perc * 100, 0) } }) -- 防御
    end

    if #entries == 0 then
        return nil
    end
    return entries
end

return {
    Describe = Describe
}
