-- pond_fish：池塘系的剩余鱼数
local Describe = function(context)
    local fishable = context.entity.components.fishable
    if fishable and fishable.fishleft then
        return { data_key = fishable.fishleft == 1 and "fish" or "fishes", params = { fishable.fishleft } }
    end
    return nil
end

return {
    prefabs = { pond = true, pond_mos = true, pond_cave = true, oasislake = true },
    Describe = Describe,
}
