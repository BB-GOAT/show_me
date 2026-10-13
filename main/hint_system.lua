-- hint_system：信息显示
local tonumber = _G.tonumber

local TheNet = _G.TheNet
local SERVER_SIDE = TheNet:GetIsServer()    --服务器
local CLIENT_SIDE = TheNet:GetIsClient() or (SERVER_SIDE and not TheNet:IsDedicated())    --本地

local show_naughtiness = GetModConfigData("Show_naughtiness") -- 显示淘气值

local function printinvalid(rpcname, player) -- 客户端发送无效RPC时的处理
    print(string.format("Invalid %s RPC from (%s) %s", rpcname, player.userid or "", player.name or ""))

    --This event is for MODs that want to handle players sending invalid rpcs
    _G.TheWorld:PushEvent("invalidrpc", { player = player, rpcname = rpcname })
end

local function decodeDataPrefix(str)
    local _, stop_pos, id = string.find(str, "^%?(%d+):")
    return tonumber(id) or 0, stop_pos and (stop_pos + 1) or 2
end

local MY_DATA_BY_ID = {}
do
    local i = 1
    for k in _G.orderedPairs(MY_STRINGS) do
        MY_DATA_BY_ID[i] = k
        i = i + 1
    end
end

local function DefaultDisplayFn(arr) --输入有一个特殊的结构：{ data, param }。 data 是对 MY_DATA 元素的引用，param 是对数组 p 的引用。
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

--为玩家添加一个提示，通过该提示将发送数据（在项目名称下弹出带有信息的文本）
do
    --如果该函数与发送的信息（在player_classified中）完全匹配，则返回一个提示。
    --返回一个提示，要么是 ""。
    local function CheckUserHint(inst)
        local c = _G.ThePlayer and _G.ThePlayer.player_classified
        if c == nil then --没有本地玩家或 classified
            return ""
        end
        --c.showme_hint
        local i = string.find(c.showme_hint2,';',1,true)
        if i == nil then --字符串格式不正确情况下
            return ""
        end
        local guid = _G.tonumber(c.showme_hint2:sub(1,i-1))
        if guid ~= inst.GUID then --guid不匹配 (或nil情况下)
            return ""
        end
        return c.showme_hint2:sub(i+1)
    end
    if CLIENT_SIDE then
        local function UnpackData(str,div)
            local pos,arr = 0,{}
            -- for each divider found
            for st,sp in function() return string.find(str,div,pos,true) end do
                table.insert(arr,string.sub(str,pos,st-1)) -- 在当前分隔符左侧附加字符
                pos = sp + 1 -- Jump past current divider
            end
            table.insert(arr,string.sub(str,pos)) -- 在最后一个分隔符右侧附加字符
            return arr
        end

        local save_target
        local last_check_time = 0 --最后一次查看时间, 每 2 秒过期一次。
        AddClassPostConstruct("widgets/hoverer",function(hoverer) --hoverer=self
            local old_SetString = hoverer.text.SetString
            local NEWLINES_SHIFT = {
                '', --无信息
                '', -- 1 条信息
                '', -- 2 条信息
                '\n ',
            }
            local function InitNewLinesShift(idx)
                local str = NEWLINES_SHIFT[idx]
                if str then
                    return str
                end
                str = '\n' .. InitNewLinesShift(idx-1)
                NEWLINES_SHIFT[idx] = str
                return str
            end
            hoverer.text.SetString = function(text,str) --text=self
                text.cnt_lines = nil
                local target = _G.TheInput:GetHUDEntityUnderMouse()
                if target ~= nil then
                    local function par(w)
                        return w.parent and (w.parent.item or par(w.parent)) or nil
                    end
                    target = target.widget ~= nil and par(target.widget)
                else
                    target = _G.TheInput:GetWorldEntityUnderMouse()
                end
                if type(target) ~= "table" or not target.GUID then
                    target = nil
                end
                if target ~= nil then
                    --print(tostring(target))
                    --检查数据是否匹配。
                    local str2 = CheckUserHint(target)
                    if str2 ~= "" then
                        --首先清除旧行到新行的过渡，因为你永远不知道添加了什么样的模组。
                        local cnt_newlines, _ = 0 --计算行末尾的行转换（DFV 兼容）
                        while cnt_newlines < #str do
                            local ch = str:sub(#str-cnt_newlines,#str-cnt_newlines)
                            if ch ~= "\n" and ch ~= " " then
                                break
                            end
                            cnt_newlines = cnt_newlines + 1
                        end
                        --清除该行的废弃信息
                        if cnt_newlines > 0 then
                            str = str:sub(1,#str-cnt_newlines)
                        end
                        --print(#str,"clear")
                        --清除线路中间废弃信息
                        if string.find(str,"\n\n",1,true) ~= nil then
                            str = str:gsub("[\n]+","\n")
                        end

                        if string.find(str,"\n",1,true) ~= nil then
                            _,cnt_newlines = str:gsub("\n","\n") --计算内部的转换数量（如果有的话）
                        else
                            cnt_newlines = 0
                        end

                        --从生成的打包字符串中提取数据。
                        str2 = UnpackData(str2,"\2")
                        local arr2 = {} --以易于理解的形式形成一组数据。
                        for i,v in ipairs(str2) do
                            if v ~= "" then
                                local idx, param_start = decodeDataPrefix(v)
                                local param_str = v:sub(param_start)
                                local data = { param = UnpackData(param_str,","), param_str=param_str }
                                local key = MY_DATA_BY_ID[idx]; -- if "@", must pass nil
                                if key ~= nil then
                                    data.data = MY_DATA[key]
                                end
                                table.insert(arr2,data)
                            end
                        end
                        arr2.str2= str2
                        --形成一个字符串
                        for i=#arr2,1,-1 do
                            local v = arr2[i]
                            if v.data ~= nil then
                                if v.data.hidden == nil then
                                    if v.data.fn ~= nil then
                                        arr2[i] = v.data.fn(v)
                                    else
                                        arr2[i] = DefaultDisplayFn(v)
                                    end
                                else
                                    table.remove(arr2,i)
                                end
                            else
                                arr2[i] = DefaultDisplayFn(v)
                            end
                        end
                        str2 = table.concat(arr2,'\n')
                        text.cnt_lines = cnt_newlines + #arr2 + 1
                        str = str .. '\n' .. str2 .. (NEWLINES_SHIFT[text.cnt_lines] or InitNewLinesShift(text.cnt_lines))
                    end
                    --如果这是第一次，那么会发送请求。
                    if target ~= save_target or last_check_time + 1 < _G.GetTime() then
                        save_target = target
                        last_check_time = _G.GetTime()
                        _G.SendModRPCToServer(_G.MOD_RPC.ShowMeSHint.Hint, save_target.GUID, save_target)        --客户端向服务器发送请求的RPC
                    end
                -- else
                    --print("target nil")
                end
                return old_SetString(text,str)
            end

            local XOFFSET = 10

            hoverer.UpdatePosition = function(self,x,y)
                local YOFFSETDOWN = 10
                local cnt_lines = self.text and self.text.cnt_lines
                if cnt_lines then
                    local extra = cnt_lines - 3
                    if extra > 0 then
                        YOFFSETDOWN = YOFFSETDOWN - extra * 30
                    end
                end


                local scale = self:GetScale()
                local scr_w, scr_h = _G.TheSim:GetScreenSize()
                local w = 0
                local h = 0

                if self.text ~= nil and self.str ~= nil then
                    local w0, h0 = self.text:GetRegionSize()
                    w = math.max(w, w0)
                    h = math.max(h, h0)
                end
                if self.secondarytext ~= nil and self.secondarystr ~= nil then
                    local w1, h1 = self.secondarytext:GetRegionSize()
                    w = math.max(w, w1)
                    h = math.max(h, h1)
                end

                w = w * scale.x * .5
                h = h * scale.y * .5

                self:SetPosition(
                    math.clamp(x, XOFFSET + w, scr_w - w - XOFFSET),
                    math.clamp(y, YOFFSETDOWN + h, scr_h + 9999),
                0)
            end


        end)
    end

    --服务器上的处理程序
    AddModRPCHandler("ShowMeSHint", "Hint", function(player, guid, item) --服务器RPC执行客户端发来的请求
        if not (_G.checknumber(guid) and _G.checkentity(item)) then
            printinvalid("ShowMeSHint.Hint", player)
            return
        end

        if player.player_classified == nil then
            print("ERROR: player_classified not found!")
            return
        end
        if item ~= nil and item.components ~= nil then
            local s = GetTestString(item, player) --在服务器上形成一个字符串（GetTestString 为 modmain2 HOST 分区定义的 env 全局，本 handler 仅服务器端运行时解析，届时必已定义）
            if s and s ~= "" then
                player.player_classified.net_showme_hint2:set(tostring(guid)..";"..s) --将其打包成一行并将其发送回同一玩家
            end
        end
    end)

    --联网
    -- showme_hint2 => "showme_hintbua." -- hash value: 78865, Ratio: 0.000078865
    AddPrefabPostInit("player_classified",function(inst)
        inst.showme_hint2 = ""
        inst.net_showme_hint2 = _G.net_string(inst.GUID, "showme_hintbua.", "showme_hint_dirty2")
        if show_naughtiness then
            inst.net_showme_kramped = {
                actions = _G.net_smallbyte(inst.GUID, "showme_kramped_actions", "showme_kramped_dirty"),
                threshold = _G.net_smallbyte(inst.GUID, "showme_kramped_threshold", "showme_kramped_dirty"),
            }
        end
        if CLIENT_SIDE then
            inst:ListenForEvent("showme_hint_dirty2",function(inst)
                inst.showme_hint2 = inst.net_showme_hint2:value()
            end)
            if show_naughtiness then
                inst:ListenForEvent("showme_kramped_dirty",function(inst)
                    OnShowMeNaughtyAction() -- 见 showme_naughtiness.lua
                end)
            end
        end
    end)
end
