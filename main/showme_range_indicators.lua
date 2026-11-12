local _G = GLOBAL

local showmePRL = { -- 显示范围的物品列表
    "oceantree_pillar",
    "lightning_rod",
    "nightstick",        -- 星辰锤，不妥协添加了避雷针标签，当然，没不妥协是不显示范围的
    "fimbul_axe",        -- 棱镜电气斧
    "tourmalinecore",    -- 棱镜电气石
}
for k, v in ipairs(showmePRL) do
    AddPrefabPostInit(v, function(inst)
        inst:DoTaskInTime(.5, function()
            local prefab = k == 1 and "ocep_range_indicator" or "lhr_range_indicator"
            local showme_range

            local function RemoveRange()
                if showme_range then
                    showme_range:Remove()
                    showme_range = nil
                end
            end

            local function RefreshRange()
                -- 初始加载和丢弃时使用相同条件，只有真正具备范围能力且未被持有的实体才显示
                if (k ~= 1 and not inst:HasTag("lightningrod"))
                    or (inst.components.inventoryitem and inst.components.inventoryitem:IsHeld()) then
                    RemoveRange()
                    return
                end
                showme_range = showme_range or _G.SpawnPrefab(prefab)
                if showme_range then
                    local x, _, z = inst.Transform:GetWorldPosition()
                    showme_range.Transform:SetPosition(x, 0, z)
                end
            end

            inst:ListenForEvent("onpickup", RemoveRange)
            inst:ListenForEvent("onputininventory", RemoveRange)
            inst:ListenForEvent("equipped", RemoveRange)
            inst:ListenForEvent("ondropped", RefreshRange)
            inst:ListenForEvent("onremove", RemoveRange)
            RefreshRange()
        end)
    end)
end