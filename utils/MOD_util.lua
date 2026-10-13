-- 本文件更新时间：2026年3月9日
local MOD_util = {}

local allplayerfn = {}
local allplayerfn_once = {}

---@param fn fun(world: TheWorld, player: ThePlayer): nil 
---@param onlyonce boolean|nil 本局游戏只运行一次？即使换人也不重新触发
function MOD_util:AddPlayerPostInit(fn, onlyonce) -- 好处是不用官方的any接口，其它玩家不会触发PlayerPostInit
    if onlyonce then
        allplayerfn_once[fn] = true
    else
        allplayerfn[fn] = true
    end
end

AddPrefabPostInit("world", function(world)
    local a = true
    world:ListenForEvent("playeractivated", function(self, data)
        if a then
            a = false
            for fn in pairs(allplayerfn_once) do
                fn(self, data)
            end
        end
        for fn in pairs(allplayerfn) do
            fn(self, data)
        end
    end)
end)

---@param modname string 模组ID
---@param config_name string 配置名称
---@param new_config any 新值
---@param client_config boolean|nil 客户端配置
function MOD_util:ChangeModConfig(modname, config_name, new_config, client_config) -- 修改某个模组的某个配置项
    local modconfig = GLOBAL.KnownModIndex:LoadModConfigurationOptions(modname, client_config)
    for _, config_option in pairs (modconfig) do
        if config_option.name == config_name then
            config_option.saved = new_config
        end
    end
    KnownModIndex:SaveConfigurationOptions(function() end, modname, modconfig, client_config)
end

--- @param str any 需要打印的内容
--- @param level number|nil
function MOD_util:Warning(str, level)
    local info = debug.getinfo(level or 2)
    local filename, line = info.source or "???", info.currentline or "???"
    print("[警告] " .. tostring(str) .. "\n本函数调用于 " .. tostring(filename) .. ":" .. tostring(line))
end

function MOD_util:DoTaskInTime(time, fn)
    self.bbgoat_instance = self.bbgoat_instance or CreateEntity("bbgoat_instance")
    return self.bbgoat_instance:DoTaskInTime(time, fn)
end

-- 添加用户命令
function MOD_util:AddUserCommand(command_string, params_table, client_command_fn, paramsoptional)
    local command_data = {
        menusort = 1,
        name = command_string,
        prettyname = nil,
        desc = nil,
        emote = true,
        permission = COMMAND_PERMISSION.USER,
        slash = true,
        usermenu = false,
        servermenu = false,
        params = params_table,
        paramsoptional = paramsoptional,
        localfn = client_command_fn
    }
    AddUserCommand(command_data.name, command_data)
end

return MOD_util