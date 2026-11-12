-- childspawner 组件：生物巢居民数与再生/复活倒计时
local REGEN_TIMER_NAME

local function GetRegenTimerName(utils)
    if not REGEN_TIMER_NAME then
        REGEN_TIMER_NAME = utils.Upvaluehelper.GetUpvalue(WorldSettings_ChildSpawner_PreLoad, "CHILDSPAWNER_REGENPERIOD_TIMERNAME")
        assert(REGEN_TIMER_NAME, "[Show Me] 无法获取 CHILDSPAWNER_REGENPERIOD_TIMERNAME")
    end
    return REGEN_TIMER_NAME
end

local function IsRegenPending(self)
    return self.regening and ((self.numchildrenoutside + self.childreninside < self.maxchildren)
        or self.maxemergencychildren and (self.numemergencychildrenoutside + self.emergencychildreninside < self.maxemergencychildren))
end

local function GetRegenInfo(self, utils)
    if not IsRegenPending(self) then
        return nil
    end

    local timer_name = GetRegenTimerName(utils)
    if self.useexternaltimer then
        local world_timer = self.inst.components.worldsettingstimer
        if not world_timer then
            return nil
        end

        return {
            time = world_timer:GetTimeLeft(timer_name),
            name = timer_name,
            paused = world_timer:IsPaused(timer_name),
        }
    else
        local task = self.task
        local period = task and task.period
        local remaining = self.timetonextregen
        if not period or not (period > 0 and period < math.huge)
            or not (remaining > -math.huge and remaining < math.huge)
        then
            return nil
        end
        -- 每次更新扣除一个周期，剩余值小于 0 才再生；floor 得到首次更新后还需等待的周期数
        local later_updates = math.max(0, math.floor(remaining / period))
        -- 预计剩余时间 = 距下次更新的时间 + 后续周期数 × 更新周期，不细算浮点残差和帧对齐
        local regen_time = math.max(0, GetTaskRemaining(task)) + later_updates * period
        if not (regen_time >= 0 and regen_time < math.huge) then
            return nil
        end

        return {
            time = regen_time,
            name = timer_name,
        }
    end
end

local function IsSpawnerHouse(prefab)
    return prefab == "mermhouse_crafted" or prefab == "mermwatchtower"
end

local Describe = function(self, context)
    local entity = context.entity
    local prefab = entity.prefab
    local utils = context.utils

    local inside = self.childreninside
    local maximum = self.maxchildren
    local child_name = utils.GetPrefabFancyName(self.childname or context.modenv.MY_DATA.children.desc) .. ": "

    local entries = {}

    if IsSpawnerHouse(prefab) then -- 用于鱼人屋
        local outside = self.CountChildrenOutside and self:CountChildrenOutside() or 0    -- 外出的（过滤失效实体）
        local total = inside + outside -- 屋内 + 屋外
        local cur_max = child_name .. total .. " / " .. maximum

        table.insert(entries, { description = cur_max })
    else
        table.insert(entries, {
            data_key = "children",
            params = { utils.round2(inside, 0), utils.round2(maximum, 0) },
        })
    end

    local regen = GetRegenInfo(self, utils)
    if regen and regen.time then
        table.insert(entries, {
            data_key = "timer",
            params = {
                utils.round2(regen.time, 0),
                regen.name,
                regen.paused and 1 or nil,
            },
        })
    end

    return entries
end

return {
    Describe = Describe,
}
