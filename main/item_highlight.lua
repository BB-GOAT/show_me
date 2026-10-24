-- 物品高亮显示

--[[
--致模组开发者: 你的模组容器可使用以下代码，实现与ShowMe联动容器高亮。    --源开发者 Star 留
    TUNING.MONITOR_CHESTS = TUNING.MONITOR_CHESTS or {}
    TUNING.MONITOR_CHESTS.chestprefab = true    -- chestprefab 即你的容器代码名称

--多容器模式, 优先级高低判断可同时加上
--优先级高于 ShowMe
    TUNING.MONITOR_CHESTS = TUNING.MONITOR_CHESTS or {}
    for _, v in ipairs(容器列表) do
        TUNING.MONITOR_CHESTS[v] = true
    end

--优先级低于 ShowMe
    for k, m in pairs(ModManager.mods) do
        if m and _G.rawget(m, "SHOWME_STRINGS") then
            if m.postinitfns and m.postinitfns.PrefabPostInit and m.postinitfns.PrefabPostInit.treasurechest then
                for _,v in ipairs(容器列表) do
                    m.postinitfns.PrefabPostInit[v] = m.postinitfns.PrefabPostInit.treasurechest
                end
            end
            break
        end
    end
--]]


local SERVER_SIDE = _G.TheNet:GetIsServer()
local CLIENT_SIDE = _G.TheNet:GetIsClient() or (SERVER_SIDE and not _G.TheNet:IsDedicated())

-- 颜色优先使用客户端配置，其次服务器配置，最后使用默认值
local function ResolveChannel(value, name, fallback) -- value：配置值；name：配置项名；fallback：默认值
    value = _G.tonumber(value)
    if value == nil or value < 0 then
        value = _G.tonumber(GetModConfigData(name))
    end
    return value and value >= 0 and value or fallback
end
local color = {
    r = ResolveChannel(GetModConfigData("chestR", true), "chestR", 0.3),
    g = ResolveChannel(GetModConfigData("chestG", true), "chestG", 1),
    b = ResolveChannel(GetModConfigData("chestB", true), "chestB", 1),
}
local api = { color = color, ResolveChannel = ResolveChannel }
if _G.KnownModIndex:IsModEnabledAny("workshop-3363111676") then
    return api
end

local MONITORED_CONTAINER_PREFABS = {
    -- 原版箱子、储物设施与携带容器
    treasurechest = true, dragonflychest = true, pandoraschest = true, minotaurchest = true,
    icebox = true, saltbox = true, cookpot = true, dragonflyfurnace = true,
    chester = true, hutch = true, beargerfur_sack = true, bookstation = true, wardrobe = true,
    backpack = true, candybag = true, icepack = true, piggyback = true,
    krampus_sack = true, seedpouch = true, spicepack = true,
    wobybig = true, wobysmall = true, mushroom_light = true, mushroom_light2 = true,
    fish_box = true, supertacklecontainer = true, tacklecontainer = true, archive_cookpot = true,
    portablecookpot = true, portablespicer = true, sacred_chest = true, boat_ancient_container = true,

    -- 第三方模组
    largechest = true, largeicebox = true,
    safebox = true, safechest = true, safeicebox = true,
    red_treasure_chest = true, purple_treasure_chest = true,
    green_treasure_chest = true, blue_treasure_chest = true,
    venus_icebox = true, chesterchest = true,
    storeroom = true, alchmy_fur = true, myth_granary = true, hiddenmoonlight = true,
    coffin = true, grave = true, musha_rpice = true,
    musha_tallrrrrrice = true, musha_tallrrrrice = true, musha_tallrrrice = true,
    hiddenmoonlight_inf = true, chest_whitewood_inf = true, chest_whitewood_big_inf = true,

    -- 海难/猪镇容器
    ro_bin = true, roottrunk_child = true, corkchest = true, smelter = true,
    thatchpack = true, packim = true, cargoboat = true, piratepack = true,
}

-- 其它模组可通过 TUNING.MONITOR_CHESTS 扩展名单
for prefab in pairs(_G.TUNING.MONITOR_CHESTS or {}) do
    MONITORED_CONTAINER_PREFABS[prefab] = true
end

local entities, tiles = {}, {} -- entities：在加载范围内活动的实体；tiles：现存物品图标
local active_item, ingredient_prefab, ingredient_timer -- 手持实体、配方材料类型、材料提示的 5 秒清除任务

-- 获取手持物品
local function ActivePrefab()
    return active_item and active_item:IsValid() and active_item.prefab or nil
end

-- 判断 prefab 是否匹配手持物品或配方材料
local function Matches(prefab)
    return prefab ~= nil and (prefab == ActivePrefab() or prefab == ingredient_prefab)
end

-- 判断实体是否为可高亮的地面物品或展示料理
local function IsWorldItem(inst)
    if not _G.ThePlayer or not inst.replica.inventoryitem
        or not inst.entity:IsVisible() or inst:HasTag("INLIMBO") then
        return false
    end
    local parent = inst.entity:GetParent()
    if parent then
        -- 恶液储存箱料理有父实体；只允许 takeitem 指向的展示料理
        return parent.prefab == "gelblob_storage" and parent.takeitem:value() == inst
    end
    return not inst.replica.inventoryitem:IsHeld()
end

-- 设置或恢复实体颜色
---@param inst table 目标实体
---@param matches boolean 是否匹配查找条件
local function SetEntityHighlight(inst, matches)
    if not matches and not inst.b_ShowMe_changed_color then
        return
    end
    if inst.ShowMeColor then
        if not matches or not inst.b_ShowMe_changed_color then
            inst.ShowMeColor(not matches)
        end
    elseif inst.AnimState then
        if matches then
            inst.AnimState:SetMultColour(color.r, color.g, color.b, 1)
        else
            inst.AnimState:SetMultColour(1, 1, 1, 1) -- 取消高亮时恢复默认颜色，不保存原色。
        end
        if inst.ShowMe_chest_table then
            inst.AnimState:SetLightOverride(matches and 0.5 or 0)
        end
    end
    inst.b_ShowMe_changed_color = matches and true or nil -- 沿用旧版高亮标记，仅重置本模组染色过的实体。
end

-- 根据当前查找目标重新判断实体的颜色
local function UpdateEntity(inst)
    if not entities[inst] or not inst:IsValid() then
        return
    end
    local contents = inst.ShowMe_chest_table -- 客户端解析后的容器内容集合，以 prefab 为键
    local active = ActivePrefab() -- 当前手持物品
    local matches_contents = contents and ((active and contents[active]) -- 容器内容是否命中任一查找目标
        or (ingredient_prefab and contents[ingredient_prefab]))
    SetEntityHighlight(inst, matches_contents or (Matches(inst.prefab) and IsWorldItem(inst)))
end

-- 登记实体，由事件维护活动集合，返回高亮刷新回调
local function TrackEntity(inst)
    local function Wake() -- 唤醒后重新登记，并更新高亮。
        entities[inst] = true
        UpdateEntity(inst)
    end
    local function Sleep()
        entities[inst] = nil
        SetEntityHighlight(inst, false)
    end
    -- 主机可能保留已休眠的实体；客机直接登记
    entities[inst] = (not SERVER_SIDE or inst.entity:IsAwake()) and true or nil
    inst:ListenForEvent("entitywake", Wake)
    inst:ListenForEvent("entitysleep", Sleep)
    inst:ListenForEvent("onremove", function() entities[inst] = nil end)
    return UpdateEntity
end

local function SyncContents(inst) -- inst：容器实体；服务器收集内容并写入网络字段
    local container = inst.components.container -- 服务器端容器组件
    if not container then
        return
    end
    local contents, prefabs = {}, {} -- 去重后的物品类型集合，以及用于排序、拼接的类型列表
    for _, item in pairs(container.slots) do -- item：槽位内物品；忽略槽位编号
        contents[item.prefab] = true
        local bundle = item.components and item.components.unwrappable -- 捆绑包的内容组件
        for _, saved in ipairs(bundle and bundle.itemdata or {}) do -- saved：包内单件物品的存档数据
            contents[saved.prefab] = true
        end
    end
    for prefab in pairs(contents) do -- prefab：去重后的物品类型名
        prefabs[#prefabs + 1] = prefab
    end
    table.sort(prefabs) -- 调换槽位不应产生新的网络内容
    local serialized = table.concat(prefabs, " ") -- 沿用以空格分隔 prefab 的网络格式
    if inst.net_ShowMe_chest:value() ~= serialized then
        inst.net_ShowMe_chest:set(serialized)
    end
end

-- 读取容器的同步内容，并更新该容器高亮
local function ReadContents(inst)
    inst.ShowMe_chest_table = {}
    for prefab in inst.net_ShowMe_chest:value():gmatch("%S+") do -- prefab：从网络字符串拆出的类型名
        inst.ShowMe_chest_table[prefab] = true
    end
    UpdateEntity(inst)
end
for prefab in pairs(MONITORED_CONTAINER_PREFABS) do -- prefab：需要安装内容同步钩子的容器类型
    AddPrefabPostInit(prefab, function(inst) -- inst：新建容器，主客机声明相同网络字段
        inst.net_ShowMe_chest = _G.net_string(inst.GUID, "ShowMe_chestlq_.", "ShowMe_chest_dirty")
        if CLIENT_SIDE then
            inst.ShowMe_chest_table = {}
            if not inst.replica.inventoryitem then
                TrackEntity(inst)
            end
            inst:ListenForEvent("ShowMe_chest_dirty", ReadContents)
        end
        if SERVER_SIDE then
            for _, event in ipairs({ "itemget", "itemlose", "onclose" }) do -- event：容器内容变化事件名
                inst:ListenForEvent(event, SyncContents)
            end
            inst:DoTaskInTime(0, SyncContents)
        end
    end)
end

-- 原版 takeitem 没有 dirty 事件，使用net_event替代持续查询
AddPrefabPostInit("gelblob_storage", function(storage) -- storage：恶液储存箱实体
    storage._showme_food_changed = _G.net_event(storage.GUID, "ShowMe_gelblob_food_changed") -- 料理变化通知
    if CLIENT_SIDE then
        local previous_food -- 上次展示的料理，用于料理更换后刷新旧实体
        local function refresh() -- 重新判断旧料理和当前展示料理的高亮
            if previous_food then
                UpdateEntity(previous_food)
            end
            previous_food = storage.takeitem:value()
            if previous_food then
                UpdateEntity(previous_food)
            end
        end
        -- 等本帧实体反序列化结束后再读取 takeitem
        storage:ListenForEvent("ShowMe_gelblob_food_changed", function()
            storage:DoTaskInTime(0, refresh)
        end)
        storage:DoTaskInTime(0, refresh)
    end
    if SERVER_SIDE then
        local holder = storage.components.inventoryitemholder -- 服务器端持物组件，恶液储存箱没有 container
        local function Notify(previous_food, ...) -- previous_food：原料理
            if storage.takeitem:value() ~= previous_food then
                storage._showme_food_changed:push() -- 部分取走堆叠时实体未变，不发送通知
            end
            return ...
        end
        for _, name in ipairs({ "onitemgivenfn", "onitemtakenfn" }) do -- name：待包装的取放回调字段名
            local previous = holder[name] -- 保存原回调，保持原有料理处理逻辑
            holder[name] = function(...)
                local food = storage.takeitem:value() -- 调用原回调前的展示料理
                return Notify(food, previous(...))
            end
        end
    end
end)

if not CLIENT_SIDE then -- 服务器止步于此
    return api
end

-- 每张 Image 自己保存原色；图层销毁后没有额外引用需要清理
local function TintImage(image, matches) -- image：图标或附加图层；matches：是否需要高亮
    if matches then
        image._showme_original_tint = image._showme_original_tint or image.tint -- 高亮前的 RGBA 表
        local alpha, tint = image._showme_original_tint[4], image.tint -- 原透明度，当前图标颜色
        if tint[1] ~= color.r or tint[2] ~= color.g or tint[3] ~= color.b or tint[4] ~= alpha then
            image:SetTint(color.r, color.g, color.b, alpha)
        end
    elseif image._showme_original_tint then
        image:SetTint(unpack(image._showme_original_tint))
        image._showme_original_tint = nil
    end
end

-- 刷新 tile（ItemTile 控件）及其各层图片，排除鼠标光标上的物品
local function UpdateTile(tile)
    local item = tile.item -- 该图标展示的物品实体
    local matches = _G.ThePlayer ~= nil and item:IsValid() and item ~= active_item -- 图标是否需要高亮
        and not tile.isactivetile and Matches(item.prefab)
    TintImage(tile.image, matches)
    for _, image in ipairs(tile.image.layers or {}) do -- image：多层物品图标的附加图片
        TintImage(image, matches)
    end
end

AddClassPostConstruct("widgets/itemtile", function(tile) -- tile：刚完成构造的物品图标控件
    if not tile.image then
        return
    end
    tiles[tile] = true
    tile.inst:ListenForEvent("onremove", function() tiles[tile] = nil end)
    local function refresh() -- 在原版图标换层后更新颜色
        -- 原版监听器会重建图层；在它们执行完后染色
        tile.inst:DoTaskInTime(0, function() UpdateTile(tile) end)
    end
    tile.inst:ListenForEvent("imagechange", refresh, tile.item)
    if tile.item:HasClientSideInventoryImageOverrides() then
        tile.inst:ListenForEvent("clientsideinventoryflagschanged", refresh, _G.ThePlayer)
    end
    UpdateTile(tile)
end)
-- 查找目标变化时，更新所有现存物品图标
local function RefreshTiles()
    for tile in pairs(tiles) do -- tile：已登记的物品图标控件
        UpdateTile(tile)
    end
end
-- 查找目标或颜色配置变化时，更新所有活动实体和图标
local RefreshAll = function()
    for inst in pairs(entities) do -- inst：已登记且处于活动状态的世界实体
        UpdateEntity(inst)
    end
    RefreshTiles()
end
api.Refresh = RefreshAll

AddClassPostConstruct("components/inventoryitem_replica", function(replica) -- replica：物品的客户端可读接口
    local inst = replica.inst -- replica 所属的物品实体
    local refresh = TrackEntity(inst) -- 更新该物品高亮的回调
    for _, event in ipairs({ "enterlimbo", "exitlimbo", "onputininventory", "ondropped" }) do -- event：物品状态事件名
        inst:ListenForEvent(event, refresh)
    end
    if not SERVER_SIDE then
        -- 客机不执行服务器拾取事件；classified 挂接/解绑才是 IsHeld 的状态边界
        local function AfterChange(...) -- 状态改变后延迟刷新，并原样返回原方法的全部结果
            inst:DoTaskInTime(0, refresh)
            return ...
        end
        for _, name in ipairs({ "AttachClassified", "DetachClassified" }) do -- name：classified 挂接或解绑方法名
            local previous = replica[name] -- 保存原方法，保持原有挂接、解绑行为
            replica[name] = function(self, ...) -- self：当前 replica；其余参数原样传给原方法
                return AfterChange(previous(self, ...))
            end
        end
    end
    inst:DoTaskInTime(0, refresh) -- 返回构造函数后 replica 才写入 inst.replica
end)

-- 切换查找目标时取消旧的配方材料清除任务
local function CancelIngredientTimer()
    if ingredient_timer then
        ingredient_timer:Cancel()
        ingredient_timer = nil
    end
end

-- 更新本地手持查找目标；player：事件玩家；item：新手持物品，nil 表示放下
local function SetActiveItem(player, item)
    if player ~= _G.ThePlayer then
        return
    end
    CancelIngredientTimer()
    local changed = ingredient_prefab ~= nil or (active_item and active_item.prefab) ~= (item and item.prefab) -- 查找类型是否变化
    active_item, ingredient_prefab = item, nil
    if changed then
        RefreshAll()
    else
        RefreshTiles()
    end
end

MOD_util:AddPlayerPostInit(function(world, player)
    if player ~= _G.ThePlayer then return end
    RefreshAll()

    player:ListenForEvent("newactiveitem", function(_, data) SetActiveItem(player, data and data.item) end) -- data.item：新的手持物品
    local function ClearSearch() SetActiveItem(player, nil) end -- 玩家离开时清除查找与材料计时器
    player:ListenForEvent("playerdeactivated", ClearSearch)
    player:ListenForEvent("onremove", ClearSearch)
end)

local IngredientUI = require("widgets/ingredientui") -- 原版配方材料控件类
local old_OnGainFocus = IngredientUI.OnGainFocus -- 原焦点方法，保留原版与先加载模组的行为
-- 鼠标聚焦材料时查找同类物品；self：材料控件；其余参数与返回值保持原样
function IngredientUI:OnGainFocus(...)
    local owner = self -- 沿父控件查找带有 owner（玩家）字段的控件
    while owner and not owner.owner do
        owner = owner.parent
    end
    local texture = self.ing and self.ing.texture -- 材料图标的纹理路径
    local prefab = type(texture) == "string" and texture:match("([^/]+)%.tex$") -- 从纹理文件名提取材料类型
    if owner and owner.owner == _G.ThePlayer and prefab then
        CancelIngredientTimer()
        if ingredient_prefab ~= prefab then
            ingredient_prefab = prefab
            RefreshAll()
        end
        ingredient_timer = _G.ThePlayer:DoTaskInTime(5, function()
            ingredient_prefab, ingredient_timer = nil, nil
            RefreshAll()
        end)
    end
    if old_OnGainFocus then
        return old_OnGainFocus(self, ...)
    end
end
return api
