# Show Me (中文) 代码结构说明

> 基于 v0.61.2（git 8bd0865）整理。行号为该版本快照，代码更新后会漂移，以"区块 + 函数名"定位为准。
> 用途：后续重构/修 BUG 时先查此文档，确认要改的部分在整体架构中的位置与牵连面。

---

## 一、模组功能概述

鼠标悬停在实体（生物/物品/建筑）上时，在悬浮提示下方追加多行属性信息：血量、饥饿、伤害、食物数值、腐烂时间、工具耐久、农作物压力、计时器翻译等。附带两个独立功能：**容器高亮**（手持/配方材料匹配箱子内容时箱子染色）与**范围显示**（避雷针/高出平均值的树干等画地圈）、**淘气值显示**。

核心设计：**服务器算数据，客户端做渲染**。服务器只传输"词条 id + 参数列表"的紧凑编码串，客户端根据本地语言表还原成完整翻译文本——省流量，且天然支持多语言（中/繁/英）。

---

## 二、文件清单

| 文件 | 行数 | 角色 |
|---|---|---|
| `modinfo.lua` | 286 | 模组元数据 + 全部配置项定义（语言/食物样式/血量/容器颜色/淘气值等） |
| `modmain.lua` | 3197 | 核心：语言系统、编码协议、服务器描述生成（GetTestString）、客户端 hoverer hook、容器高亮 |
| `bbgoat_upvaluehelper.lua` | 215 | 通用工具库（冰冰羊维护，同步自 bbgoat_utils）：递归查找/替换函数上值、查找事件回调 |
| `scripts/showme_naughtiness.lua` | 103 | 淘气值：服务端 hook kramped 组件同步 netvar；客户端两种显示路径 |
| `scripts/showme_range_indicators.lua` | 58 | 范围圈挂载逻辑（服务端，监听拾取/装备/丢弃/移除事件） |
| `scripts/prefabs/showme_range.lua` | 112 | 两个非网络化范围圈 prefab（避雷针圈 lhr / 高出平均值的树干圈 ocep） |
| `showme_chs.lua` / `showme_cht.lua` / `showme_en.lua` | 429×3 | 语言包，三文件结构完全一致，7 张表（见六） |

---

## 三、核心数据流（悬停提示链路）

```
[客户端] 鼠标悬停实体
   → hook widgets/hoverer 的 text.SetString 被触发（每次刷新文本都会跑）
   → 取鼠标下实体（HUD 物品栏 or 世界实体）
   → 距上次请求 ≥1s 或目标变化时：SendModRPCToServer(ShowMeSHint.Hint, guid, entity)

[服务器] AddModRPCHandler("ShowMeSHint","Hint") 收到
   → 校验 checknumber(guid) + checkentity(item)
   → GetTestString(item, player) 生成编码串 "…\2…\2…"
   → player.player_classified.net_showme_hint2:set(guid .. ";" .. 编码串)

[客户端] player_classified 监听 showme_hint_dirty2
   → 缓存到 inst.showme_hint2
   → 下一次 hoverer SetString 时 CheckUserHint() 校验 GUID 匹配
   → UnpackData 按 "\2" 拆条 → 每条 decodeDataPrefix 解出 id → MY_DATA_BY_ID[id] 找回词条
   → 调用词条 fn 或 DefaultDisplayFn 渲染 → 追加到原 hover 文本
   → 重写 hoverer.UpdatePosition 按总行数上移，防止提示超出屏幕
```

关键点：
- `desc_table` 是服务器端本次悬停的"待发送数据"数组；`cn(key, ...)` 是唯一的标准写入口；`table.insert(desc_table, "@" .. str)` 是旁路（绕过 MY_DATA，直接发原文）。
- `\2` 是条目分隔符，`,` 是参数分隔符，`;` 分隔 GUID 与正文。
- 客户端 `hidden` 标志决定该条是否渲染（服务器也可通过配置直接不发）。

---

## 四、modmain.lua 六大区块

### ① 环境准备（约 1–130 行）
- `GLOBAL.setmetatable(env, {__index=rawget(GLOBAL)})`：给 mod 环境漏写 `GLOBAL` 的祖传代码兜底。
- 冲突检测：开启 **Insight**（`workshop-2189004162`）时拒绝加载。
- `Import(name)`：`kleiloadlua` + `setfenv(f, _G)`，把文件载入全局环境（绕过 mod 隔离）。
- `GetGlobal(name, default)`：全局变量安全读取/创建。`round2(num, idp)`：浮点格式化。
- **配置读取样板**（重复约 10 处）：`tonumber(GetModConfigData(name, true))` 读本地配置，失败再 `GetModConfigData(name)` 读服务器配置——实现"本地设置优先"。重构时可收敛为一个 helper。
- 关键派生变量：`is_PvP`、`SERVER_SIDE`（GetIsServer）、`CLIENT_SIDE`（GetIsClient 或非专用主机）。注意 `SERVER_SIDE and not TheNet:IsDedicated()` 的主机也是 CLIENT_SIDE。
- 需要跨端共享的配置：`food_order/food_style`（食物格式）、`display_hp`、`food_estimation`、`show_food_units`、`show_uses`、`item_info_mod`、`chestR/G/B`（容器颜色）、`show_nutrients/show_fuel/show_fueled/show_planar_resist/show_naughtiness/T_crop/show_buddle_item`。

### ② 语言系统与 MY_DATA 定义（约 130–640 行）
- `MY_DATA / MY_STRINGS / SHOWME_STRINGS / FOOD_TAGS / INTERNAL_TIMERS / INTERNAL_STAGES / STRESS_TAGS / OTHER_TAGS / OTHER_TITLES` 定义在 mod 环境（故意全局，供其它模组调用，容器高亮 API 依赖 `rawget(m,"SHOWME_STRINGS")`）。
- 先载入简中（默认底表），再按配置/系统语言载入 cht/en，`LinkTables` 用 metatable `__index` 回退到简中。
- **编码协议**：`MY_STRINGS` 按 `orderedPairs` 顺序给每条分配自增 id；`MY_DATA[k].sym = "?id:"`；`MY_DATA_BY_ID[id] = k` 反查表。**改 MY_STRINGS 的键顺序会导致 id 变化，但因为编码串与解码表在同一进程同一份文件，两端一致所以安全；若拆分文件或服务端/客户端版本不一致则会错乱——这是协议的脆弱点。**
- `MY_DATA[key] = { desc, id, sym, fn, percent, sign, hidden }`：
  - `fn(arr)` 自定义渲染，`arr = { data=MY_DATA条目, param={...}, param_str }`；
  - `sign`：正数加 `+` 前缀；`percent`：末尾加 `%`；`hidden`：客户端不渲染。
- 自定义 fn 亮点：`buff`（增益名+倍率%+持续）、`frigde`（冰箱倍率分档文案）、`harvest`（蜂箱产物倒计时）、`perish`（按第二参切换"陈腐/变质"前缀）、`children`（生物巢"屋内+屋外/上限"）、`strength`（BOSS 伤害+PVP 修正）、`loyal`（>9000 显示"臣服"）、`fresh`（鱼桶返鲜/作弊返鲜）。
- `DataTimerFn(seconds)`：秒 → `h:mm:ss`（自动补零）。
- `GetPrefabFancyName(prefab)`：STRINGS.NAMES 查不到时 SpawnPrefab 取 `GetDisplayName` 再 Remove（解决部分容器内不显示中文）。
- `ConvertTemperature`：游戏温度单位 → ℃（×0.5）/℉；`MainConvertTemperature` 优先借用【综合状态显示】的换算函数 `AOS_Temperature_fn`。
- `MY_DATA.will_die / will_dry / grow_in / just_time` 全部重定向到 `perish` 的渲染（仅文案不同）。

### ③ 客户端初始化与 AOS 兼容（约 640–840 行）
- 两个服务器 RPC（客户端→服务器的"能力声明"）：
  - `ShowMe.AOS`：客户端开了综合状态显示类模组 → 服务器之后发温度用其格式；
  - `ShowMe.Estimate`：客户端要看"腐烂后数值" → `GetTestString` 里 `ed:GetHealth(viewer)` 等按"预计值"计算。
- 手写 `AddPlayersPreInit/PostInit/AfterInit` 三层链：替换 `package.loaded["prefabs/player_common"]` 的 `MakePlayerCharacter`，使 hook 覆盖所有原版+模组角色。
- `FixClient(inst)`（玩家生成后）：发 Estimate RPC → 修补状态栏 `status.temperature/worldtemp.num.SetString` 做温度转换（仅旧版 AOS 路径）→ 发 AOS RPC → 初始化淘气值 UI（见七）。

### ④ 服务器端核心（约 840–2870 行）
- **模组枚举**：`GetAllModNames / SearchForModsByName` → `mods.active_mods_by_name`；检测"简易血条/Health Bar"（`is_HealthInfo`）与 "Display food values"，影响 `need_send_hp` 与食物显示。
- `GetPerishTime(inst, c)`：复刻 perishable 组件全部腐烂倍率（preserver 组件、冰箱/冷冻、foodpreserver、鸟笼、spoiler、潮湿、冬季/夏季、frozenfiremult、全局倍率），返回 `剩余时间, 新鲜分界时间, modifier`。
- **`cn(key, ...)`**：把 `MY_DATA[key].sym .. "参数,参数"` 追加进 `desc_table`——所有标准输出的唯一入口。
- `KNOWN_BUFFS`：已知食物 BUFF 表（效率/防御/攻击/防水/感电/发光/生命恢复），duration/power 从 TUNING 键名取，`shift` 表示 power 需 +1。
- `GetDebuffTime(viewer, buff_name)`：查玩家身上 debuff 剩余时间（用于武器伤害/护甲的"含 BUFF"显示）。
- `AddBoatStatus(viewer)`：查看船部件后 120 秒内，物品会显示"修理: X"（`boat_status_task` 标记）。
- `USELESS_TIMERS / IsUselessTimer`：计时器显示黑名单（`all` 通配 + 按 prefab）。
- 农作物数据：`AddComponentPostInit("farming_manager")` 用 **Upvaluehelper** 抽 `OnSave/GetDebugString` 的上值 grid（`_nutrientgrid/_moisturegrid/_drinkersgrid/_overlaygrid`），`GetTileNutrientsAtPoint/GetTileMoistureAtPoint` 供作物压力显示用。优先走 `OldGetTileDataAtPoint`（原版函数，若拿到）。
- `safe_tuning(path, default)`：安全读取 `TUNING.A.B.C` 嵌套值——**desc_handlers 全靠它保证游戏更新后不炸**。
- **`desc_handlers` 注册表**（按 prefab 分发，`add_entity_description` 调度）：蝙蝠棒、遗迹蝙蝠、废墟帽、盐、弹弓全系弹药/枪管、WX-78 全部模块。handler 可返回 string / string数组 / nil（用 cn 旁路自行写入）。**这是模组里已经"半重构"过的样板，后续主流程重构应延续此模式。**
- `song_handlers`：女武神战歌（按 `item.songdata` 分发）；`process_potion`：阿比盖尔药水（按 `potion_tunings` 的字段特征分发）。
- **`GetTestString(item, viewer)`**（全局函数，约 1600 行——最大的屎山）：
  - **生物分支**（`c.health and not item.grow_stage`）：血量（minhealth 修正）、饥饿（beefalo 特判）、精神、随从主人/忠诚、击杀数、伤害（PVP 修正 + 位面伤害/抵抗 + AoE）、防御（absorb×playerabsorb）、驯服度、growable 阶段、精神光环（falloff 换算）、食人花眼球草/叶肉倒计时估算、asuna 模组特判。
  - **物品分支**：烹饪锅、冷却、growable、护甲（含防御 BUFF + 位面防御 + 第三方 phys 吸收 + 耐久）、武器伤害（位面抵抗公式 `(√(4d+64)-8)×4` + 攻击 BUFF + 第三方 phys_dmg 类型）、zupalexsrangedweapons 箭伤、攻击/施法范围、工具效率 BUFF、保温（SetInsulationEx / GetInsulation 两条路径）、回精神（dapperness×54）、防水、船桨动力、**食物**（GetHealth/Hunger/Sanity × eater 吸收倍率 × 食物记忆倍率 + 食物温度 + Warly BUFF 遍历 `cooking.recipes` + 香料死代码）、肥料、腐烂时间（含 stale/spoiled 分界倒计时、宠物饥饿、critter 特判）、填充单位、治疗、工具耐久（C_FINITEUSES_PREFAB 特殊倍率）、温度、建筑燃料、堆肥桶、乐器范围、 crystallizable、装备饥饿减免（beargervest 等写死）、主人识别（mine/stealable/owner 三级）、occupiable（笼中鸟饥饿）、干燥架、鞍具、服饰耐久（按 FUELTYPE 分类决定是否显示）、贸易价值、冰箱倍率、修理值、收获、**弹弓弹药**（⚠️ 每次查看遍历 `_G.Prefabs` + `debug.getinfo` 提取 data，无缓存——性能热点）、冬季盛宴树、池塘鱼数、水族箱、雨量计（inSine 插值）、温度计、香料BUFF、月亮裂隙、船部件、`o_t_list` 特定 prefab 标签（⚠️ 用列表下标 i 判断分支，插入一项全错）、重生护符、避雷针 charge、燃料值、**`item:GetShowItemInfo(viewer)` 第三方接口**（返回 3 条自定义文本）、可采摘（草/树苗倒计时、移植次数）、旧农场作物、捆绑包内容、Pickler、Thirst 模组（cwater）、好感度、堆叠>999 实际数量、寄居蟹装饰度、铥矿奖章噩梦阶段倒计时、woby 饥饿、**作物压力**（T_crop，stressors_testfns 逐项调用）、beerpower/waterpower/gaspower 模组、childspawner（鱼人屋"屋内+屋外"特殊逻辑）、武器对目标的抗性（冰杖/吹箭/排箫）、inlove、timer/worldsettingstimer 遍历（黑名单过滤）、新晾肉架快照。
  - 返回 `table.concat(desc_table, "\2")`。
- `SERVER_SIDE` 独立块：暗影收割者 `GetShowItemInfo`（等级/击杀进度/吸血/饥饿）。

### ⑤ 客户端 UI hook + 网络变量（约 2870–3130 行）
- `CheckUserHint(inst)`：从本地 `ThePlayer.player_classified.showme_hint2` 取串，按 `;` 拆 GUID 校验。
- `UnpackData(str, div)`：按分隔符纯 Lua 拆串（不用 gmatch，处理空段）。
- `AddClassPostConstruct("widgets/hoverer")`：
  - 重写 `hoverer.text.SetString`：先清原文本尾部/中间多余换行（DFV 兼容），解码渲染追加，`text.cnt_lines` 记录行数供 UpdatePosition 用；`NEWLINES_SHIFT` 懒生成换行前缀表。
  - 重写 `hoverer.UpdatePosition`：按 `cnt_lines - 3` 每行上移 30px，clamp 到屏幕内。
- `AddModRPCHandler("ShowMeSHint","Hint")`：服务器校验后调 `GetTestString`，结果写 `net_showme_hint2`。
- `AddPrefabPostInit("player_classified")`：注册 `net_showme_hint2`（net_string，事件名 `showme_hintbua.`）；`show_naughtiness` 时注册 `net_showme_kramped`（actions/threshold 两个 net_smallbyte）；客户端监听 dirty 事件缓存值。

### ⑥ 容器高亮模块（约 3130–3190 行）
- 与"高亮查找"模组（`workshop-3363111676`）互斥（对方开了就整体跳过，省性能）。
- `MONITOR_CHESTS` 大表（约 60 个原版+模组容器）；**对外 API：其它模组往 `TUNING.MONITOR_CHESTS` 塞 prefab 名即可接入**（文件头注释有完整接入说明，含"优先级低于 ShowMe"的 postinitfns 复制法）。
- 服务端：`InitChest` 给每个容器挂独立 net_string；`OnClose`（监听 onclose/itemget/itemlose）把内容 prefab 名单（含捆绑包内物）空格拼接写入 netvar。
- 客户端：`OnShowMeChestDirty` 解析名单到 `inst.ShowMe_chest_table` → `UpdateChestColor`：手持物品（`inventory_classified` 的 activedirty → `_active`）或配方材料（hook `ingredientui.OnGainFocus`，从贴图名反推 prefab，高亮保持 15 秒 `_ing_task`）命中时染色 `SetMultColour(chestR,chestG,chestB)` + `SetLightOverride(.5)`；第三方可用 `inst.ShowMeColor` 接口接管。
- 尾部：`PrefabFiles = {"showme_range"}`；`Show_range` 配置 + 服务端 → `modimport` 范围显示；`show_naughtiness` → `modimport` 淘气值。

---

## 五、scripts 三个文件

### showme_naughtiness.lua
- 服务端 `AddComponentPostInit("kramped")`：遍历 world 事件监听找到 kramped 来源的回调 → Upvaluehelper 抽 `OnKilledOther` 及其上值 `OnNaughtyAction` → 包装后者，每次淘气行为后把 actions/threshold 写进 `player_classified.net_showme_kramped`；再包装 `_activeplayers` 表的 `__newindex`，新玩家加入时"模拟击杀格罗姆（stackmult=0）"触发一次初始化同步。
- 客户端分两路：
  - 开了综合状态显示（`workshop-376333686`）：world postinit 延迟 hook `widgets/statusdisplays` 构造器，用 FindUpvalue 把其 `SHOWNAUGHTINESS` 上值强制 true；`OnShowMeNaughtyAction()`（全局函数，由 modmain 的 dirty 监听调用）推 `naughtydelta` 事件 + 本地 `set_local` 模拟衰减计时。
  - 未开：直接 `ThePlayer.components.talker:Say("淘气值: x / y")`（仅在数值上升时说）。

### showme_range_indicators.lua（服务端）
`showmePRL` 列表（高出平均值的树干/避雷针/星辰锤/棱镜斧/棱镜石）→ AddPrefabPostInit + 0.5s 延迟 → 非 held 状态 SpawnPrefab 对应圈放在脚下；监听 `onpickup/equipped`（删圈）、`ondropped`（重建）、`onremove`（清理）。⚠️ 注意闭包变量 `showme_range` 与 `k` 的对应关系（k==1 用 ocep 圈）。

### prefabs/showme_range.lua
两个非网络化辅助实体：`lhr_range_indicator`（winona_spotlight_placement 动画，橙黄叠加，半径≈避雷针 40 范围×1.5 缩放）、`ocep_range_indicator`（firefighter_placement，蓝紫）。用 `deployhelper.onenablehelper` 显示，`CLASSIFIED/NOCLICK/placer` 标签 + `persists=false`（不存档、不可点）。

---

## 六、语言文件结构（chs/cht/en 三份一致）

| 表 | 用途 | 渲染位置 |
|---|---|---|
| `MY_STRINGS` | 主词条（MY_DATA 的 desc 来源），**键顺序 = 网络协议 id** | 悬停提示各行 |
| `SHOWME_STRINGS` | 辅助词（已暂停/持续/天/阶段…），含拼音键名（xiaolv/chixu/jieduan 等祖传） | fn 内拼接 |
| `FOOD_TAGS` | 食材单位翻译（veggie→蔬菜） | units_of |
| `INTERNAL_TIMERS` | 计时器名翻译（巨量，按 BOSS/生物分组） | timer 行 |
| `INTERNAL_STAGES` | 生长阶段翻译（short→小 等） | growable 行 |
| `STRESS_TAGS` | 作物压力标签（缺肥/缺水…） | stress_tag |
| `OTHER_TAGS` | 硬编码描述（书籍效果/WX78 模块说明） | other_tag |
| `OTHER_TITLES` | `%s` 格式化模板（desc_handlers 用） | desc_handlers |

加载顺序：简中先入底表 → cht/en 通过 metatable 回退链覆盖；`MY_STRINGS` 特殊处理（只更新 desc，id 保持简中顺序，保证三语言 id 一致）。

---

## 七、对外兼容与扩展接口

1. **容器高亮接入**：`TUNING.MONITOR_CHESTS[prefab] = true`（文件头与容器块内注释有两份接入说明）。
2. **物品自定义信息**：给实体挂 `inst.GetShowItemInfo = function(viewer) return str1, str2, str3 end`（暗影收割者即官方风格用例）。
3. **容器染色接管**：`inst.ShowMeColor = function(changed_to_default) end`。
4. **检测的模组**：Insight（冲突拒载）、简易血条/Health Bar（血量显示让位）、Display food values（食物三属性让位）、高亮查找 3363111676（容器高亮让位）、综合状态显示 376333686（温度单位/淘气值 UI 联动）。
5. RPC 通道：`ShowMe.AOS`、`ShowMe.Estimate`（客→服声明）；`ShowMeSHint.Hint`（客→服悬停请求）。netvar：`showme_hintbua.`（hint 串）、`showme_kramped_actions/threshold`、`ShowMe_chestlq_.`（每箱内容名单）。

---

## 八、已知问题与优化候选清单

按"低风险 → 高收益"排序，重构时逐项立项，每项改完在模组设置里过一遍相关功能再提交。

1. **弹弓弹药 Prefabs 遍历无缓存**（GetTestString 内 `HasTag("slingshotammo")` 块）：每次悬停遍历全 `_G.Prefabs` + `debug.getinfo`。应在服务器启动时提取一次缓存到局部表。零行为变化。
2. **配置读取样板收敛**：约 10 处 `tonumber(GetModConfigData(x,true)) or -1 → fallback` 重复，抽 helper。
3. **`o_t_list` 下标分支**：用列表序号 i 决定显示逻辑（i==1 / i>1 and i<=3…），极脆弱。改为每项自带处理方式的注册表。
4. **`GetTestString` 拆分**：1600 行单函数。延续 `desc_handlers` 注册表模式，按功能域拆：生物属性 / 食物 / 装备耐久 / 容器与建筑 / 计时器 / 特定 prefab。注意 `cn` 依赖闭包变量 `desc_table`，拆分时保持传入或改为参数。
5. **死代码清理**：`ed.spice and false` 香料块、注释掉的 desc 拼接、`SPICIAL_STRUCTURES` 拼写、`MY_DATA.fuel.percent` 重复注释行。
6. **拼音键名**（SHOWME_STRINGS.xiaolv/chixu/jieduan 等）：改名需三份语言文件 + modmain 同步，放最后做。
7. **协议脆弱性**（暂不动，只记录）：`?id:` 编码依赖 MY_STRINGS 遍历顺序，服务端/客户端模组版本不一致时显示错乱。重构编码为直接传 key 字符串可根治，但增加流量，需权衡。
8. **全局函数 `GetTestString`**：故意全局（历史兼容？），重构时确认无其它模组依赖后再 local 化。
9. `showme_range_indicators.lua` 闭包 `showme_range` 变量复用与 `k` 魔法序号，可读性差。

## 九、修改注意事项

- `bbgoat_upvaluehelper.lua` 是从【冰冰羊的模组运行库】同步的外部库，**不要本地改造**，要改去上游（GitHub: BB-GOAT/bbgoat_utils）。
- 涉及 kramped / farming_manager / statusdisplays 的 hook 全靠 debug 库抽上值，游戏更新或其它模组先 hook 会取错——Upvaluehelper 的 `fn_filter` 参数可限定来源文件，必要时加上。
- `MY_STRINGS` 加词条会改变后续所有 id；三份语言文件必须同步增删，且 cht/en 的 `MY_STRINGS` 键集合需与 chs 一致（回退链兜底缺失键）。
- 服务器端改 `GetTestString` 输出格式时，确认客户端解码路径（UnpackData / decodeDataPrefix / MY_DATA_BY_ID）兼容。
- 主机（非专用）同时是 SERVER_SIDE 和 CLIENT_SIDE，两段代码都会执行，改动时两端都要测。
