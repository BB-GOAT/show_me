-- childspawner 组件：生物巢的居民数（人鱼屋含外出计数与刷新状态，其余显示屋内/上限）
local Describe = function(self, context)
    local entity = context.entity
    local prefab = entity.prefab
    local utils = context.utils

    local function IsSpawnerHouse(prefab)
        return prefab == "mermhouse_crafted" or prefab == "mermwatchtower"
    end

    local inside = math.floor(tonumber(self.childreninside) or 0)
    local maximum = math.floor(tonumber(self.maxchildren) or 0)
    local child_name = utils.GetPrefabFancyName(self.childname or context.modenv.MY_DATA.children.desc) .. ": " -- 直接从官方字符串拿生物名

    if IsSpawnerHouse(prefab) then -- 用于人鱼屋
        local outside = self.CountChildrenOutside and self:CountChildrenOutside() or 0 -- 外出的
        local total = inside + outside -- 屋内 + 屋外

        local cur_max = child_name .. total .. " / " .. maximum

        -- 判定"已停止"的两种依据（满足任一即视为停止）
        local timer = entity.components.worldsettingstimer
        local tm = timer and timer.GetTimeLeft and timer:GetTimeLeft("ChildSpawner_RegenPeriod")

        if total >= maximum or not tm then
            -- 已达上限 或 计时器未在跑（例如白天 StopSpawning / 世界设置禁用）
            cur_max = cur_max .. " (" .. context.modenv.SHOWME_STRINGS.stopped .. ")"
        elseif tm > 0 then
            cur_max = cur_max .. " | " .. context.modenv.OTHER_TITLES.spawn_in .. utils.DataTimerFn(tm)
        end

        return { description = cur_max }
    end

    if inside and maximum then
        return {
            data_key = "children",
            params = { utils.round2(inside, 0), utils.round2(maximum, 0) },
        }
    end
    return nil
end

return {
    Describe = Describe,
}
