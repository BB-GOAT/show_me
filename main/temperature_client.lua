local tonumber = _G.tonumber

local TheNet = _G.TheNet
local SERVER_SIDE = TheNet:GetIsServer()    --服务器
local CLIENT_SIDE = TheNet:GetIsClient() or (SERVER_SIDE and not TheNet:IsDedicated())    --本地

local GetGlobal=function(gname,default)
    local res=_G.rawget(_G,gname)
    if res == nil and default ~= nil then
        _G.rawset(_G,gname,default)
        return default
    end
    return res
end

-- 增加其他模组的兼容性
local mods = GetGlobal("mods",{}) -- 冰冰羊：什么屎山代码..不敢删..

local AOS_Temperature_fn --将游戏中的温度单位转换为摄氏度、华氏度。
local is_Fahrenheit = false
local function ConvertTemperature(val)
    if not val then
        return "???"
    end
    if is_Fahrenheit then
        return math.floor(1.8*(val) + 32.5).."\176F" -- \176 是 ° 的符号，来自【综合状态显示】模组
    else
        return math.floor(val*0.5 + 0.5) .. "\176C"
    end
end

local function MainConvertTemperature(val)
    return AOS_Temperature_fn and AOS_Temperature_fn(tonumber(val)) or ConvertTemperature(tonumber(val))
end

MY_DATA.temperature.sign = true
MY_DATA.temperature.fn = function(arr)
    arr.param[1] = MainConvertTemperature(arr.param[1])
    -- DefaultDisplayFn（renderers.lua 导出，不经 env 共享）的拼接逻辑直接内联：仅 arr.param_str/desc/sign/percent 的纯字符串拼接，温度值已先行换算
    if arr.data == nil then
        return arr.param_str --以来自服务器的形式显示字符串（没有第一个字符）。 对“@”符号的适配
    end
    if arr.data.sign ~= nil and (tonumber(arr.param[1]) or -1) >= 0 then
        arr.param[1] = "+" .. tostring(arr.param[1])
    end
    local s = arr.data.desc .. " " .. tostring(arr.param[1])
    if arr.data.percent ~= nil then
        s = s .. "%"
    end
    return s
end

--尝试检测客户端模组并通过 RPC 发送它们
AddModRPCHandler("ShowMe","AOS",function(inst)
    --调用此函数将禁用此玩家的提示。
    inst.has_AlwaysOnStatus = true
end)

--We climb into the client interface in order to reduce the displayed temperature
if CLIENT_SIDE then
    if not mods.player_preinit_fns then
        mods.player_preinit_fns={}
        --Dirty hack
        local old_MakePlayerCharacter = require("prefabs/player_common")
        local function new_MakePlayerCharacter(...)
            local inst=old_MakePlayerCharacter(...)
            for _,v in ipairs(mods.player_preinit_fns) do
                v(inst)
            end
            return inst
        end
        _G.package.loaded["prefabs/player_common"] = new_MakePlayerCharacter
    end

    local function AddPlayersPreInit(fn)
        table.insert(mods.player_preinit_fns,fn)
    end

    local player_postinit_fns = {}
    local function AddPlayersPostInit(fn) -- <<<--------- Вот она!
        table.insert(player_postinit_fns,fn)
    end

    local done_players = {}
    AddPlayersPreInit(function(inst)
        local s = inst.prefab or inst.name
        if not done_players[s] then
            done_players[s] = true
            AddPrefabPostInit(s,function(inst)
                for _,v in ipairs(player_postinit_fns) do
                    v(inst)
                end
            end)
        end
    end)

    local player_afterinit_fns = {}
    function AddPlayersAfterInit(fn)
        table.insert(player_afterinit_fns,fn)
    end
    AddPlayersPostInit(function(inst)
        if #player_afterinit_fns > 0 then
            inst:DoTaskInTime(0,function(inst)
                for i=1,#player_afterinit_fns do
                    player_afterinit_fns[i](inst)
                end
            end)
        end
    end)

    --А вот и не угадали. Не трогаем интерфейс. Вместо этого определяем настройки и лишь в случае их отсутствия трогаем интерфейс.

    --温度检查。 反向格式和转换为通用摄氏度。
    local function FixTemperature(s)
        if type(s) ~= "string" then
            return s --Вообще не строка. Что за?
        end
        --На конце может быть один из конкретных вариантов строки.
        local sep = s:find("\176",1,true)
        if not sep then
            return s
        end
        local pre, pst = tonumber(s:sub(1,sep-1)), s:sub(sep+1)
        if not pre then
            return s --字符串的第一部分不是数字。
        end
        if pst == "C" then
            return s --这是摄氏温度，无需转换。
        elseif pst == "F" then
            --华氏温度
            is_Fahrenheit = true
            return s
        else
            --我们假设温度以游戏单位为单位，我们用摄氏度来解决这个问题。
            return ConvertTemperature(pre) --TODO：减少中有一个小错误。 在 5.1 的温度下，数字 2 将出现，尽管它应该是 3。
        end
    end

    local AOS_UNITS, AOS_UNIT

    --Interface patching feature on the client. Triggered for all players upon spawn.
    local function FixClient(inst)
        if inst ~= _G.ThePlayer then
            return
        end

        local status = inst.HUD and inst.HUD.controls and inst.HUD.controls.status
        if not status then
            print("ERROR SHOW_ME: Can't fix client side status!")
            return
        end
        local AOS
        AOS_UNITS = TUNING.COMBINED_STATUS_UNITS
        AOS_UNIT = TUNING.COMBINED_STATUS_UNIT
        if (AOS_UNITS and AOS_UNIT and AOS_UNITS[AOS_UNIT]) then
            AOS = true
            AOS_Temperature_fn = AOS_UNITS[AOS_UNIT]
        else --旧版本的 AOS
            if status.temperature then
                AOS = true
                local old_SetString = status.temperature.num.SetString
                status.temperature.num.SetString = function(self,s,...)
                    return old_SetString(self,FixTemperature(s),...)
                end
            end
            if status.worldtemp then
                AOS = true
                local old_SetString = status.worldtemp.num.SetString
                status.worldtemp.num.SetString = function(self,s,...)
                    return old_SetString(self,FixTemperature(s),...)
                end
            end
        end
        if AOS then
            SendModRPCToServer(MOD_RPC.ShowMe.AOS)
        end
    end
    AddPlayersAfterInit(FixClient)
end
