-- boat_parts：查看船部件时在查看者身上打 120 秒节流标记（repairer.lua 据此显示"修理: X"）
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
