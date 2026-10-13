-- change_modsettings：游戏内实时修改模组设置
-- 通过 /showme 命令打开客户端配置屏幕，点“应用”后无需重启立即生效：

local TheNet = _G.TheNet
local SERVER_SIDE = TheNet:GetIsServer()    --服务器
local CLIENT_SIDE = TheNet:GetIsClient() or (SERVER_SIDE and not TheNet:IsDedicated())    --本地

local function printinvalid(rpcname, player)
    print(string.format("Invalid %s RPC from (%s) %s", rpcname, player.userid or "", player.name or ""))
    _G.TheWorld:PushEvent("invalidrpc", { player = player, rpcname = rpcname })
end

---@param client_config table modmain2 的内存客户端配置表（直接覆盖其内容）
---@param player_config table modmain2 的玩家个性化配置表（服务器端使用）
---@param deps table 模块依赖：SetupLanguage/ApplyRenderConfig/ChestColor/RefreshChests/ResolveChannel，由 modmain2 通过各模块 return 的导出注入
return function(client_config, player_config, deps)
    --- 应用配置屏幕提交的客户端配置：覆盖内存配置表与本地效果，并同步给服务器
    ---@param keyed_settings table {配置名 = 新值}，来自配置屏幕“应用”时提交的数据
    local function ApplyLiveConfig(keyed_settings)
        if type(keyed_settings) ~= "table" then
            return
        end

        -- 覆盖内存中的客户端配置，descriptor 通过 context.config.client 读取
        for config_name in pairs(client_config) do
            local new_value = keyed_settings[config_name]
            if new_value ~= nil then
                client_config[config_name] = new_value
            end
        end

        -- 箱子高亮颜色是纯客户端效果，重绘使已高亮的箱子应用新颜色
        -- 颜色表与重绘函数来自 main/chest_highlight.lua 的 return 导出，由 modmain2 通过 deps 注入
        local chest_color = deps.ChestColor
        if chest_color ~= nil then
            chest_color.r = deps.ResolveChannel(keyed_settings.chestR, "chestR", 0.3)
            chest_color.g = deps.ResolveChannel(keyed_settings.chestG, "chestG", 1)
            chest_color.b = deps.ResolveChannel(keyed_settings.chestB, "chestB", 1)
        end
        if deps.RefreshChests ~= nil then
            deps.RefreshChests()
        end

        if deps.ApplyRenderConfig ~= nil then
            deps.ApplyRenderConfig()
        end

        if keyed_settings.lang ~= nil and deps.SetupLanguage ~= nil then
            deps.SetupLanguage(keyed_settings.lang)
        end

        -- 把新配置同步给服务器，服务器将其存为本玩家的个性化配置（player_config）
        if CLIENT_SIDE and _G.ThePlayer ~= nil then
            SendModRPCToServer(MOD_RPC.ShowMe.SendConfig, _G.ZipAndEncodeString(client_config))
        end
    end

    --- 移除不支持实时修改的配置项后构造屏幕
    local function PushConfigScreenOnlyLive(construct_fn)
        local config_options = _G.KnownModIndex:LoadModConfigurationOptions(modname, true)
        local removed = {}
        if config_options ~= nil then
            -- 标记保留项：live_config 项及其前面的分隔行
            local keep, pending_headers = {}, {}
            for index, option in ipairs(config_options) do
                if option.name == nil or option.name == "" then
                    table.insert(pending_headers, index)
                else
                    if option.live_config then
                        keep[index] = true
                        for _, header_index in ipairs(pending_headers) do
                            keep[header_index] = true
                        end
                    end
                    pending_headers = {}
                end
            end
            for index = #config_options, 1, -1 do
                if not keep[index] then
                    table.insert(removed, 1, { index = index, option = config_options[index] })
                    table.remove(config_options, index)
                end
            end
        end

        local ok, screen = _G.pcall(construct_fn)

        -- 恢复配置表：屏幕实例构造时已持有自己的选项快照
        for _, item in ipairs(removed) do
            table.insert(config_options, item.index, item.option)
        end

        if ok and screen ~= nil then
            _G.TheFrontEnd:PushScreen(screen)
        end
    end

    --- 打开 Show Me 的游戏内配置屏幕（客户端配置）
    local function OpenShowMeConfigScreen()
        local frontend = _G.TheFrontEnd
        if frontend == nil then
            return
        end
        -- 已打开配置屏幕时不重复压栈
        local active_screen = frontend:GetActiveScreen()
        if active_screen ~= nil and (active_screen.name == "ModConfigurationScreen" or active_screen.name == "RemiNewModConfigurationScreen") then
            return
        end
        -- 开启【配置扩展】模组时优先使用它的设置屏幕
        if _G.KnownModIndex:IsModEnabledAny("workshop-3317960157") then
            local ok, RemiConfigScreen = _G.pcall(_G.require, "widgets/remi_newmodconfigurationscreen")
            if ok and RemiConfigScreen ~= nil then
                PushConfigScreenOnlyLive(function()
                    return RemiConfigScreen(modname, true, ApplyLiveConfig)
                end)
                return
            end
        end
        PushConfigScreenOnlyLive(function()
            local ModConfigurationScreen = _G.require("screens/redux/modconfigurationscreen")
            return ModConfigurationScreen(modname, true)
        end)
    end

    -- 服务器：接收玩家发来的个性化配置
    AddModRPCHandler("ShowMe","SendConfig",function(player, config)
        if not _G.checkstring(config) then
            printinvalid("ShowMe.SendConfig", player)
            return
        end
        config = _G.DecodeAndUnzipString(config)
        if _G.type(config) ~= "table" then
            printinvalid("ShowMe.SendConfig", player)
            return
        end

        -- 只保留 client_config 中已有配置键的标量值，客户端无法借此注入任意数据
        local valid_config = {}
        for config_name in pairs(client_config) do
            local value = config[config_name]
            local value_type = _G.type(value)
            if value_type == "number" or value_type == "boolean" or value_type == "string" then
                valid_config[config_name] = value
            end
        end
        player_config[player] = valid_config
    end)

    -- 原版配置屏幕没有应用回调，hook 其 Apply：应用时把屏幕收集的新配置实时生效
    AddClassPostConstruct("screens/redux/modconfigurationscreen", function(self)
        local oldApply = self.Apply
        self.Apply = function(screen)
            if screen.modname == modname and screen.client_config then
                local settings = screen:CollectSettings()
                oldApply(screen)
                local keyed_settings = {}
                for _, option in ipairs(settings or {}) do
                    keyed_settings[option.name] = option.saved
                end
                ApplyLiveConfig(keyed_settings)
            else
                oldApply(screen)
            end
        end
    end)

    -- /showme 命令：在游戏内打开配置屏幕
    MOD_util:AddUserCommand("showme", {}, function()
        OpenShowMeConfigScreen()
    end)

    -- 开启【配置扩展】模组时，把 Show Me 注册进 /recfg 面板的模组列表
    AddGamePostInit(function()
        local reconfigurable_mods = _G.rawget(_G, "REMI_RECONFIGURABLE_MODS")
        if reconfigurable_mods ~= nil then
            reconfigurable_mods[modname] = ApplyLiveConfig
        end
    end)

end
