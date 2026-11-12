-- buffs_timers：描述文件专用工具（容器腐烂时间查询、食物增益注册表、debuff 计时、生物巢定时器黑名单）

-- 与 perishable.Update 使用相同的环境条件
local function IsFinite(value)
    return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

local function GetPerishTime(inst, c)
    local perishable = c.perishable
    local remaining = perishable and perishable.perishremainingtime
    if not IsFinite(remaining) then return end
    local total = perishable.perishtime
    if total and not IsFinite(total) then return end

    local world = TheWorld
    local state = world.state
    local modifier = 1
    local additional_decay = 0 -- 酸雨额外消耗的腐烂时间/秒，不受普通腐烂倍率影响
    local owner = c.inventoryitem and c.inventoryitem.owner or nil
    if not owner and c.occupier then
        owner = c.occupier:GetOwner()
    end
    local pos = (owner or inst):GetPosition()
    local temperature = owner and owner:HasTag("pocketdimension_container")
        and state.temperature or GetTemperatureAtXZ(pos.x, pos.z)

    if owner then
        if owner.components.preserver then
            modifier = owner.components.preserver:GetPerishRateMultiplier(inst) or modifier
        elseif owner:HasTag("fridge") then
            if inst:HasTag("frozen") and not owner:HasTag("nocool") and not owner:HasTag("lowcool") then
                modifier = TUNING.PERISH_COLD_FROZEN_MULT
            else
                modifier = TUNING.PERISH_FRIDGE_MULT
            end
        elseif owner:HasTag("foodpreserver") then
            modifier = TUNING.PERISH_FOOD_PRESERVER_MULT
        elseif owner:HasTag("cage") and inst:HasTag("small_livestock") then
            modifier = TUNING.PERISH_CAGE_MULT
        end
        if owner:HasTag("spoiler") then
            modifier = modifier * TUNING.PERISH_GROUND_MULT
        end
    else
        modifier = TUNING.PERISH_GROUND_MULT
        if state.isacidraining and not c.rainimmunity and world.Map:CanPointHaveAcidRain(pos.x, 0, pos.z) then
            local rate = c.moisture and c.moisture:_GetMoistureRateAssumingRain() or state.precipitationrate
            additional_decay = (total and total > 0 and total or 0) * rate * TUNING.ACIDRAIN_PERISHABLE_ROT_PERCENT
        end
    end

    -- 原版字段拼写为 ignorewentness，鱼等物品可豁免潮湿加速。
    if inst:GetIsWet() and not perishable.ignorewentness then
        modifier = modifier * TUNING.PERISH_WET_MULT
    end
    if temperature < 0 then
        if inst:HasTag("frozen") and not perishable.frozenfiremult then
            modifier = TUNING.PERISH_COLD_FROZEN_MULT
        else
            modifier = modifier * TUNING.PERISH_WINTER_MULT
        end
    end
    if perishable.frozenfiremult then
        modifier = modifier * TUNING.PERISH_FROZEN_FIRE_MULT
    end
    if temperature > TUNING.OVERHEAT_TEMP then
        modifier = modifier * TUNING.PERISH_SUMMER_MULT
    end
    modifier = modifier * (perishable.localPerishMultiplyer or 1) * TUNING.PERISH_GLOBAL_MULT
    modifier = modifier + additional_decay -- 阶段倒计时也使用实际的总耗损速率

    -- 零倍率没有有限倒计时；也不向显示层传递 NaN 或无穷值。
    if not IsFinite(modifier) or modifier == 0 then return nil, nil, modifier end
    local time = math.max(0, remaining) / modifier
    if not IsFinite(time) then return end
    if modifier < 0 and total and total > 0 then
        local fresh = math.max(0, total - remaining) / -modifier
        if not IsFinite(fresh) then return end
        return time, fresh, modifier
    end
    return time, nil, modifier
end

-- 食物 BUFF 信息显示：name 存 SHOWME_STRINGS 键名（其它模块运行时查询，兼容实时切换语言功能）；duration/power 存 TUNING 键名
local KNOWN_BUFFS = {
    buff_workeffectiveness = {
        name = "xiaolv",
        duration = 'BUFF_WORKEFFECTIVENESS_DURATION',
        power = 'BUFF_WORKEFFECTIVENESS_MODIFIER',
    },
    buff_playerabsorption = {
        name = "fangyu",
        duration = 'BUFF_PLAYERABSORPTION_DURATION',
        power = 'BUFF_PLAYERABSORPTION_MODIFIER',
        shift = true,
    },
    buff_attack = {
        name = "gongji",
        duration = 'BUFF_ATTACK_DURATION',
        power = 'BUFF_ATTACK_MULTIPLIER',
    },
    buff_moistureimmunity = {
        name = "fangshui",
        duration = 'BUFF_MOISTUREIMMUNITY_DURATION',
        --power = 'BUFF_WORKEFFECTIVENESS_MODIFIER',
    },
    buff_electricattack = {
        name = "gandian",
        duration = 'BUFF_ELECTRICATTACK_DURATION',
        --power = 'BUFF_WORKEFFECTIVENESS_MODIFIER',
    },
    wormlight_light_greater = {
        name = "faguang",
        duration = function()
            return TUNING.WORMLIGHT_DURATION and TUNING.WORMLIGHT_DURATION * 4 -- multiplier is hardcoded, sadly. See wormlight.lua
        end,
        --power = 'BUFF_WORKEFFECTIVENESS_MODIFIER',
    },
    healthregenbuff = {
        name = "huifu",
        duration = 'JELLYBEAN_DURATION',
        --power = 'BUFF_WORKEFFECTIVENESS_MODIFIER',
    },
}
--debuff时间
local function GetDebuffTime(viewer, buff_name)
    local d = viewer.components.debuffable
    if not d then
        return
    end
    for k,v in pairs(d.debuffs) do
        if k == buff_name then
            local timer = v.inst.components.timer
            if timer and timer.GetTimeLeft then
                local tm = timer:GetTimeLeft('buffover')
                return tm
            end
            break
        end
    end
end

local USELESS_TIMERS = {	-- 生物巢定时器屏蔽
    --default for all prefabs
    toadstool = { channeltick = true },
    all = { ChildSpawner_SpawnPeriod = true, dominant = true },
	wobybig = { decay = true },	-- 沃比的消失屏蔽掉
    wobysmall = { decay = true },
    hermitcrab = { speak_time = true, complain_time = true, salad = true },
}

local function IsUselessTimer(prefab,name)
    local data = USELESS_TIMERS[prefab]
    if not data then
        return USELESS_TIMERS.all[name]
    end
    if data == name then
        return true
    end
    if type(data) == 'table' and data[name] then
        return true
    end
    return USELESS_TIMERS.all[name]
end

return {
    GetPerishTime = GetPerishTime,
    KNOWN_BUFFS = KNOWN_BUFFS,
    GetDebuffTime = GetDebuffTime,
    IsUselessTimer = IsUselessTimer,
}
