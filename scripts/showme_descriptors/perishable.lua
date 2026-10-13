-- perishable 组件：生物剩余寿命与物品腐烂时间
local Describe = function(self, context)
    local entity = context.entity
    local c = entity.components
    local utils = context.utils
    -- item_info_mod：客户端显式开启优先，客户端为默认档(0)时跟随服务器设置
    local item_info_mod = context.config.client.item_info_mod
    if item_info_mod == 0 then
        item_info_mod = context.config.server.item_info_mod
    end
    if item_info_mod ~= 0 or self.updatetask == nil then
        return nil
    end

    if c.health ~= nil and not entity.grow_stage then
        -- 生物分支：剩余寿命当作寿命显示
        if c.hunger ~= nil then
            return nil -- 有 hunger 的生物由 hunger 描述文件显示饥饿
        end
        local time = utils.GetPerishTime(entity, c)
        if time == nil then
            return nil
        end
        return {
            priority = 90, -- 与 hunger 互斥，保持原第二位
            data_key = "will_die",
            params = { utils.round2(time / TUNING.TOTAL_DAY_TIME, 1) },
        }
    end

    -- 物品分支：腐烂时间（鱼，死亡到腐烂：x 天）
    local food_estimation = context.config.client.food_estimation -- food_estimation：客户端显式设置优先，客户端为默认档(-1)时跟随服务器设置；"否"时不预测腐烂时间（宠物饥饿倒计时除外）
    if food_estimation == -1 then
        food_estimation = context.config.server.food_estimation
    end
    if food_estimation == 0 and not entity:HasTag("critter") then
        return nil
    end
    local time, fresh, perish_modifier = utils.GetPerishTime(entity, c)
    if time == nil then
        return nil
    end
    local entries = {}
    if time < 0 then
        if fresh then
            table.insert(entries, { data_key = "fresh", params = { utils.round2(fresh / TUNING.TOTAL_DAY_TIME, 1) } })
        end
    elseif time ~= math.huge and time ~= -math.huge then
        if entity:HasTag("critter") then
            -- 宠物饥饿倒计时走服务器文本旁路（无对应协议词条）
            table.insert(entries, { description = context.modenv.OTHER_TITLES.critterhunger .. tostring(utils.round2(time / TUNING.TOTAL_DAY_TIME, 1)) .. context.modenv.SHOWME_STRINGS.days })
        else
            -- 可食生物（鱼等）按新鲜度分界换算剩余倒计时阶段
            local countdown_stage
            local countdown_time = time
            if c.edible ~= nil and perish_modifier > 0 then
                local remaining = c.perishable.perishremainingtime
                local total = c.perishable.perishtime
                if total ~= nil and total > 0 then
                    if remaining >= total * TUNING.PERISH_FRESH then
                        countdown_stage = "stale"
                        countdown_time = (remaining - total * TUNING.PERISH_FRESH) / perish_modifier
                    elseif remaining > total * TUNING.PERISH_STALE then
                        countdown_stage = "spoiled"
                        countdown_time = (remaining - total * TUNING.PERISH_STALE) / perish_modifier
                    end
                end
            end
            table.insert(entries, { data_key = "perish", params = { utils.round2(countdown_time / TUNING.TOTAL_DAY_TIME, 1), countdown_stage or "", utils.round2(time / TUNING.TOTAL_DAY_TIME, 1) } })
        end
    end
    if #entries == 0 then
        return nil
    end
    return entries
end

return {
    Describe = Describe
}
