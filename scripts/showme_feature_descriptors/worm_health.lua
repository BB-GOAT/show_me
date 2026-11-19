-- worm_health: 巨大洞穴蠕虫身体血量
local Describe = function(context)
    local worm = context.entity.worm
    if not worm or not worm:IsValid() then
        return nil
    end

    local health = worm.components and worm.components.health
    if not health or health:IsInvincible() then
        return nil
    end

    -- 与 health 一致
    local server_hp = context.config.server.display_hp
    local client_hp = context.config.client.display_hp
    local need_send_hp = server_hp ~= 2
        and (client_hp == -1 or client_hp == 1)
        and not (server_hp == -1 and context.config.server.is_HealthInfo and client_hp == -1)

    if not need_send_hp or not health.minhealth then
        return nil
    end

    local max_with_penalty = health.GetMaxWithPenalty and health:GetMaxWithPenalty() or health.maxhealth
    local min_health = math.min(health.minhealth, max_with_penalty)
    local mx = math.ceil(max_with_penalty - min_health)
    local cur = math.min(math.ceil(health.currenthealth - min_health), mx)
    return { priority = 100, data_key = "hp", params = { cur, mx } }
end

return {
    fields = { worm = true },
    Describe = Describe,
}