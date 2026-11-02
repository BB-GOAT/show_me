-- support_pillar：支柱脚手架与完成后的支柱信息
local Describe = function(context)
    local entity = context.entity
    local prefab = entity.prefab
    local site = entity.components.constructionsite
    local plan = CONSTRUCTION_PLANS[prefab]
    if not site or type(plan) ~= "table" or plan[1] == nil then
        return nil
    end

    local max = plan[1].amount
    if not max or max <= 0 then
        return nil
    end

    local is_completed_pillar = entity.reinforced ~= nil
    local entries = {}

    if is_completed_pillar and TUNING.SUPPORT_PILLAR_REINFORCED_LEVELS then
        table.insert(entries, {
            data_key = "reinforce",
            params = { entity.reinforced, TUNING.SUPPORT_PILLAR_REINFORCED_LEVELS },
        })
    end

    local current = site:GetSlotCount(1)
    if not is_completed_pillar or current < max then
        table.insert(entries, {
            data_key = "durability",
            params = { current, max },
        })
    end

    return entries
end

return {
    prefabs = {
        support_pillar_scaffold = true,
        support_pillar_dreadstone_scaffold = true,
        support_pillar = true,
        support_pillar_dreadstone = true,
    },
    Describe = Describe,
}