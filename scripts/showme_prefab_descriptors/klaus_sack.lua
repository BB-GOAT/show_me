-- klaus_sack：显示赃物袋重要战利品
local function Describe(context)
    local server_setting = context.config.server.show_klaus_sack_loot
    local need_send_loot = (server_setting ~= 2) and context.config.client.show_klaus_sack_loot == 1
    if not need_send_loot then
        return nil
    end
    if not context.entity.components.klaussacklock then
        return nil
    end
    local component = TheWorld and TheWorld.components.klaussackloot
    if not component or type(component.loot) ~= "table" then
        return nil
    end

    local loot = {}
    local function Summarize(pool, regular_loot)
        for bundle_index, bundle in ipairs(pool) do
            if type(bundle) == "table" then
                for _, prefab in ipairs(bundle) do
                    if type(prefab) == "string" then
                        if loot[prefab] == nil then
                            loot[prefab] = {
                                amount = 0,
                                important = regular_loot and (bundle_index == 3 or bundle_index == 4),
                            }
                        end
                        loot[prefab].amount = loot[prefab].amount + 1
                    end
                end
            end
        end
    end
    -- 先扫描常规包裹：金块、木炭等先出现在前两包，因此不会标记为重要物品
    Summarize(component.loot, true)
    if _G.IsSpecialEventActive(SPECIAL_EVENTS.WINTERS_FEAST) and type(component.wintersfeast_loot) == "table" then
        Summarize(component.wintersfeast_loot, false)
    end

    local prefabs = {}
    for prefab, data in pairs(loot) do
        if data.important then
            table.insert(prefabs, prefab)
        end
    end
    table.sort(prefabs)
    if #prefabs == 0 then
        return nil
    end

    local entries = { { data_key = "klaus_sack_loot" } }
    for _, prefab in ipairs(prefabs) do
        table.insert(entries, {
            data_key = "perish_product",
            params = { prefab, loot[prefab].amount },
        })
    end
    return entries
end

return {
    Describe = Describe,
}