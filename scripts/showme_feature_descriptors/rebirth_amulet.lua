-- rebirth_amulet：重生护符系的"可重生"说明
local Describe = function(context)
    if not context.entity.components.hauntable then
        return nil
    end
    return { data_key = "other_tag", params = { "amulet" } }
end

return {
    prefabs = { ancient_amulet_red = true, amulet = true },
    Describe = Describe,
}
