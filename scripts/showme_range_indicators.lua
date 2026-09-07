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
        inst:DoTaskInTime(.5, function ()
            local d
            if k == 1 then -- 根据表的序列赋予不同的SpawnPrefab
                d = "ocep_range_indicator"
            else -- if k > 1 then
                d = "lhr_range_indicator"
            end
            local x, _, z = inst.Transform:GetWorldPosition()

            local showme_range
            if k == 1 or inst:HasTag("lightningrod") then        -- 如果是列表 1 的物品或者拥有避雷针标签的物品就添加上范围圈圈
                if not (inst.components.inventoryitem and inst.components.inventoryitem:IsHeld()) then -- 在物品栏中的物品不显示范围
                    if not showme_range then
                        showme_range = _G.SpawnPrefab(d)
                    end
                    showme_range.Transform:SetPosition(x, 0, z)
                end
            end

            inst:ListenForEvent("onpickup", function() -- 监听拾取
                if showme_range then
                    showme_range:Remove()
                    showme_range = nil
                end
            end)
            inst:ListenForEvent("equipped", function() -- 监听装备
                if showme_range then
                    showme_range:Remove()
                    showme_range = nil
                end
            end)
            inst:ListenForEvent("ondropped", function() -- 监听丢弃
                if not showme_range then
                    showme_range = _G.SpawnPrefab(d)
                end
                x, _, z = inst.Transform:GetWorldPosition()
                showme_range.Transform:SetPosition(x, 0, z)
            end)

            inst:ListenForEvent("onremove", function() -- 监听建筑物品是否被移除，若移除了范围圈圈也跟着移除
                if showme_range then
                    showme_range:Remove()
                    showme_range = nil
                end
            end)
        end)
    end)
end