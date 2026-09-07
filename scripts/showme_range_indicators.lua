local _G = GLOBAL
PrefabFiles = { "showme_range" }

local function GetIndicatorPrefab(inst)
    local prefab = inst.prefab
    if prefab == "oceantree_pillar" then
        return "ocep_range_indicator"
    else
        return "lhr_range_indicator"
    end
end

local function SpawnRangeIndicator(inst, d)
    if not d then return nil end
    local x, y, z = inst.Transform:GetWorldPosition()
    local indicator = _G.SpawnPrefab(d)
    if indicator then
        indicator.Transform:SetPosition(x, 0, z)
    end
    return indicator
end

local showmePRL = {
    "oceantree_pillar",
    "lightning_rod",
    "nightstick",
    "fimbul_axe",
    "tourmalinecore",
}

for _, v in pairs(showmePRL) do
    AddPrefabPostInit(v, function(inst)
        inst:DoTaskInTime(.5, function()
            local d = GetIndicatorPrefab(inst)
            if not d then return end

            local indicator = SpawnRangeIndicator(inst, d)  -- 初始生成（后续会被巡检控制）

            -- 用周期性巡检来控制显示/隐藏
            inst:DoPeriodicTask(.5, function()
                local isInLimbo = inst:HasTag("INLIMBO")
                local isLightningRod = inst:HasTag("lightningrod")
                local hasIndicator = indicator and indicator:IsValid()

                if isInLimbo and isLightningRod and hasIndicator then
                    -- 拾取/进入容器
                    indicator:Remove()
                    indicator = nil
                    inst:AddTag("Showme_RTag")  -- 标记已移除
                elseif not isInLimbo and isLightningRod and not hasIndicator and inst:HasTag("Showme_RTag") then
                    -- 丢弃到地面
                    indicator = SpawnRangeIndicator(inst, d)
                    inst:RemoveTag("Showme_RTag")
                end
            end)

            -- 物品被摧毁时清理
            inst:ListenForEvent("onremove", function()
                if indicator and indicator:IsValid() and indicator.Remove then
                    indicator:Remove()
                    indicator = nil
                end
            end)
        end)
    end)
end