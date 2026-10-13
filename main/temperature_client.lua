local tonumber = _G.tonumber

local TheNet = _G.TheNet
local SERVER_SIDE = TheNet:GetIsServer()    --服务器
local CLIENT_SIDE = TheNet:GetIsClient() or (SERVER_SIDE and not TheNet:IsDedicated())    --本地

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

if CLIENT_SIDE then
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
        end
        if AOS then
            SendModRPCToServer(MOD_RPC.ShowMe.AOS)
        end
    end

    MOD_util:AddPlayerPostInit(function(world, inst)
        FixClient(inst)
    end)
end
