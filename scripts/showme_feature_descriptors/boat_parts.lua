-- boat_parts：查看船部件时在查看者身上打 120 秒标记 供修理材料显示修理值
local function AddBoatStatus(viewer)
    if viewer.boat_status_task then
        viewer.boat_status_task:Cancel()
    end
    viewer.boat_status_task = viewer:DoTaskInTime(120, function(inst)
        inst.boat_status_task = nil
    end)
end

local Describe = function(context)
    AddBoatStatus(context.player)
    return nil
end

return {
    prefabs = { boat = true, anchor = true, mast = true, boat_leak = true, mast_malbatross = true, steeringwheel = true },
    Describe = Describe,
}
