-- childspawner 组件：生物巢的居民数（鱼人屋含外出计数，其余显示屋内/上限）
local Describe = function(self, context)
    local entity = context.entity
    local prefab = entity.prefab
    local utils = context.utils

    local function IsSpawnerHouse(prefab)
        return prefab == "mermhouse_crafted" or prefab == "mermwatchtower"
    end

    local inside = math.floor(tonumber(self.childreninside) or 0)
    local maximum = math.floor(tonumber(self.maxchildren) or 0)
    local child_name = utils.GetPrefabFancyName(self.childname or context.modenv.MY_DATA.children.desc) .. ": "

    if IsSpawnerHouse(prefab) then -- 用于鱼人屋
        local outside = self.CountChildrenOutside and self:CountChildrenOutside() or 0 -- 外出的
        local total = inside + outside -- 屋内 + 屋外

        local cur_max = child_name .. total .. " / " .. maximum

        return { description = cur_max }
    end

    return {
        data_key = "children",
        params = { utils.round2(inside, 0), utils.round2(maximum, 0) },
    }
end

return {
    Describe = Describe,
}
