-- edible 组件：食物属性（血量/饥饿/精神、食物温度、食物记忆、Warly 食物 BUFF）
local cooking = require("cooking")

local Describe = function(self, context)
    -- item_info_mod：客户端显式开启优先，客户端为默认档(0)时跟随服务器设置
    local item_info_mod = context.config.client.item_info_mod
    if item_info_mod == 0 then
        item_info_mod = context.config.server.item_info_mod
    end
    if item_info_mod ~= 0 then
        return nil
    end

    local viewer = context.player
    local entity = context.entity
    local utils = context.utils
    local round2 = utils.round2
    local KNOWN_BUFFS = utils.KNOWN_BUFFS
    local prefab = entity.prefab

    local can_eat = false
    if viewer.components.eater then
        can_eat = viewer.components.eater:CanEat(entity)
    end
    if not can_eat then
        return nil
    end

    -- 始终按食物当前新鲜度折算实际收益
    local hp = round2(self:GetHealth(viewer), 1)
    local hg = round2(self:GetHunger(viewer), 1)
    local sn = round2(self:GetSanity(viewer), 1)

    if viewer.FoodValuesChanger ~= nil then -- 一种特殊功能，其目的是在食用时改变食物。
        local hp2, hg2, sn2 = viewer:FoodValuesChanger(entity)
        if sn2 ~= nil then
            hp = round2(hp2, 1)
            hg = round2(hg2, 1)
            sn = round2(sn2, 1)
        end
    end

    local base_mult = viewer.components.foodmemory ~= nil and viewer.components.foodmemory:GetFoodMultiplier(prefab) or 1
    do -- 进食者的吸收倍率，增加 eater 组件检查
        local eater = viewer.components.eater
        -- 永不妥协会把 eater 的血量/精神吸收清零并把原值缓存在玩家实体上（食物收益随时间生效功能），须读缓存值才与实际收益一致
        local hp_mult = (self.healthabsorption or 1) * base_mult * (viewer.modded_healthabsorption or (eater and eater.healthabsorption) or 1)
        local hg_mult = (self.hungerabsorption or 1) * base_mult * (viewer.modded_hungerabsorption or (eater and eater.hungerabsorption) or 1)
        local sn_mult = (self.sanityabsorption or 1) * base_mult * (viewer.modded_sanityabsorption or (eater and eater.sanityabsorption) or 1)
        hp = hp * hp_mult
        hg = hg * hg_mult
        sn = sn * sn_mult
    end

    if prefab == "petals_evil" then
        sn = round2(sn - TUNING.SANITY_TINY, 1)
    end

    local entries = {}

    if hp > 0 then
        hp = "+" .. tostring(hp)
    end
    if hg > 0 then
        hg = "+" .. tostring(hg)
    end
    if sn > 0 then
        sn = "+" .. tostring(sn)
    end
    table.insert(entries, { data_key = "food", params = { hg, sn, hp } })

    if self.temperaturedelta ~= 0 then -- 食物有温度
        if self.temperatureduration ~= 0 and self.chill < 1 and viewer.components.temperature ~= nil then
            local delta_multiplier = 1
            local duration_multiplier = 1
            if self.spice and TUNING.SPICE_MULTIPLIERS[self.spice] then
                if TUNING.SPICE_MULTIPLIERS[self.spice].TEMPERATUREDELTA then
                    delta_multiplier = delta_multiplier + TUNING.SPICE_MULTIPLIERS[self.spice].TEMPERATUREDELTA
                end
                if TUNING.SPICE_MULTIPLIERS[self.spice].TEMPERATUREDURATION then
                    duration_multiplier = duration_multiplier + TUNING.SPICE_MULTIPLIERS[self.spice].TEMPERATUREDURATION
                end
            end
            local delta, duration = self.temperaturedelta * (1 - self.chill) * delta_multiplier, self.temperatureduration * duration_multiplier
            table.insert(entries, { data_key = "food_temperature", params = { round2(delta), round2(duration) } })
        end
    end

    if base_mult ~= 1 then -- 食物储存，例如厨子
        local fm = viewer.components.foodmemory
        if fm.GetBaseFood and fm.foods then
            local rec = fm.foods[fm:GetBaseFood(prefab)]
            if rec then
                local t = GetTaskRemaining(rec.task)
                table.insert(entries, { data_key = "food_memory", params = { round2(base_mult, 2), round2(t) } })
            end
        end
    end

    -- Warly BUFF：遍历食谱查找该食物产物携带的 buff
    local _shown_buffs = {} -- 给食物BUFF加去重表，没错就是为了防止N条 生命恢复 持续 x 天
    for _, struct in pairs(cooking.recipes) do
        for food, v in pairs(struct) do
            if food == prefab and v.prefabs then
                for i, buff_name in ipairs(v.prefabs) do
                    local duration = nil
                    local power = nil
                    local data = KNOWN_BUFFS[buff_name]
                    if data then
                        if type(data.duration) == 'function' then
                            duration = data.duration()
                        else
                            duration = TUNING[data.duration]
                        end
                        if data.power then
                            power = TUNING[data.power]
                        end
                        if data.shift and data.power then
                            power = power + 1
                        end
                        buff_name = context.modenv.SHOWME_STRINGS[data.name] -- name 存键名，运行时查译名（兼容实时切换语言功能）
                    else
                        local up = buff_name:upper()
                        duration = TUNING[up .. '_DURATION']
                        power = TUNING[up .. '_MULTIPLIER'] or TUNING[up .. '_MODIFIER']
                        if buff_name:find("buff_", 1, true) == 1 then
                            buff_name = buff_name:sub(6)
                        end
                        if buff_name:find("buff", #buff_name - 3, true) then
                            buff_name = buff_name:sub(1, #buff_name - 4)
                        end
                    end
                    if duration and not _shown_buffs[buff_name] then
                        _shown_buffs[buff_name] = true
                        duration = round2(duration / TUNING.TOTAL_DAY_TIME, 2)
                        table.insert(entries, { data_key = "buff", params = { buff_name, duration, power } })
                    end
                end
            end
        end
    end

    if #entries == 0 then
        return nil
    end
    return entries
end

return {
    Describe = Describe,
}
