-- buffs_timers：描述文件专用工具（容器腐烂时间查询、食物增益注册表、debuff 计时、生物巢定时器黑名单）
local function GetPerishTime(inst, c)

    local world_state = _G.TheWorld.state
    local modifier = 1
    local owner = c.inventoryitem and c.inventoryitem.owner or nil
    if not owner and c.occupier then
        owner = c.occupier:GetOwner() --Для птичек?
    end

    if owner then
        if owner.components.preserver ~= nil then
            modifier = owner.components.preserver:GetPerishRateMultiplier(inst) or modifier -- 传入被检查物品, 使容器能够正确显示保鲜度
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
    end

    if inst:GetIsWet() then
        modifier = modifier * TUNING.PERISH_WET_MULT
    end

    if world_state.temperature < 0 then
        if inst:HasTag("frozen") and not c.perishable.frozenfiremult then
            modifier = TUNING.PERISH_COLD_FROZEN_MULT
        else
            modifier = modifier * TUNING.PERISH_WINTER_MULT
        end
    end

    if c.perishable.frozenfiremult then
        modifier = modifier * TUNING.PERISH_FROZEN_FIRE_MULT
    end

    if world_state.temperature > TUNING.OVERHEAT_TEMP then
        modifier = modifier * TUNING.PERISH_SUMMER_MULT
    end

    if c.perishable.localPerishMultiplyer then
        modifier = modifier * c.perishable.localPerishMultiplyer
    end

    modifier = modifier * TUNING.PERISH_GLOBAL_MULT

    local old_val = c.perishable.perishremainingtime
    if old_val ~= nil then
        local delta = old_val / modifier
        if delta ~= nil then --and delta >= 0 then
            if delta < 0 and c.perishable.perishtime and c.perishable.perishtime > 0 then --modifier < 0 !
                return delta, (c.perishable.perishremainingtime - c.perishable.perishtime) / modifier, modifier;
            end
            return delta, nil, modifier
        end
    end
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
