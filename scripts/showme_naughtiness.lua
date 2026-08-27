local _G = GLOBAL
local TheNet = _G.TheNet
local SERVER_SIDE = TheNet:GetIsServer() --服务器
local CLIENT_SIDE = TheNet:GetIsClient() or (SERVER_SIDE and not TheNet:IsDedicated())    --本地

if SERVER_SIDE then
    AddComponentPostInit("kramped", function(self)
        local OnKilledOther
        for i,v in pairs(_G.TheWorld.event_listening.ms_playerjoined[_G.TheWorld]) do
            if _G.debug.getinfo(v, "S").source == "scripts/components/kramped.lua" then
                OnKilledOther = Upvaluehelper.GetUpvalue(v, "OnKilledOther")
            end
        end

        if not OnKilledOther then print("Show Me (中文) 警告：未找到淘气值相关函数 OnKilledOther") return end
        local _OnNaughtyAction, found_i, pre_fn = Upvaluehelper.GetUpvalue(OnKilledOther, "OnNaughtyAction")
        if not (_OnNaughtyAction and found_i and pre_fn) then print("Show Me (中文) 警告：未找到淘气值相关上值 OnNaughtyAction") return end

        local function OnShowMeNaughtyAction(playerdata)
            local player_classified = playerdata and playerdata.player and playerdata.player.player_classified
            if player_classified then
                player_classified.net_showme_kramped.actions:set(playerdata.actions)
                player_classified.net_showme_kramped.threshold:set(playerdata.threshold)
            end
        end

        local OnNaughtyAction = function(how_naughty, playerdata, ...)
            _OnNaughtyAction(how_naughty, playerdata, ...)
            OnShowMeNaughtyAction(playerdata)
        end
        _G.debug.setupvalue(pre_fn, found_i, OnNaughtyAction)

        -- 初始化玩家淘气值数据
        local _activeplayers = Upvaluehelper.GetUpvalue(self.GetDebugString, "_activeplayers")
        if not _activeplayers then print("Show Me (中文) 警告：未找到淘气值相关上值 _activeplayers") return end
        _G.setmetatable(_activeplayers, {
            __newindex = function(self, player, playerdata)
                _G.rawset(self, player, playerdata)
                if TUNING.KRAMPUS_THRESHOLD ~= -1 and OnKilledOther then
                    OnKilledOther(player, { -- 模拟玩家杀死了一只格罗姆
                        victim = {
                            prefab = "glommer",
                            HasTag = function(...) return false end,
                        },
                        stackmult = 0, -- 获得的淘气值 ×0
                    })
                else
                    _activeplayers[player].threshold = 0
                end
            end
        })
    end)
end

if CLIENT_SIDE then
    if _G.KnownModIndex:IsModEnabledAny("workshop-376333686") then
        AddPrefabPostInit("world", function() -- 由于模组加载优先级的关系，延迟执行HOOK
            local classdef = require("widgets/statusdisplays")
            local constructor = classdef._ctor
            local SHOWNAUGHTINESS, found_i, pre_fn = Upvaluehelper.FindUpvalue(constructor, "SHOWNAUGHTINESS", "workshop%-376333686/modmain.lua")
            if not (found_i and pre_fn) then return end
            _G.debug.setupvalue(pre_fn, found_i, true) -- 打开 综合状态显示 的淘气值显示
        end)

        local timetodecay_task
        function OnShowMeNaughtyAction()
            local player_classified = _G.ThePlayer and _G.ThePlayer.player_classified
            if player_classified then
                local actions = player_classified.net_showme_kramped.actions:value()
                local threshold = player_classified.net_showme_kramped.threshold:value()
                _G.ThePlayer:PushEvent("naughtydelta", { -- 调用 综合状态显示 的监听函数
                    actions = actions,
                    threshold = threshold,
                })

                if timetodecay_task then
                    timetodecay_task:Cancel()
                    timetodecay_task = nil
                end
                if actions > 0 then
                    timetodecay_task = _G.TheWorld:DoTaskInTime(TUNING.KRAMPUS_NAUGHTINESS_DECAY_PERIOD, function()
                        player_classified.net_showme_kramped.actions:set_local(actions - 1)
                        OnShowMeNaughtyAction()
                    end)
                end
            end
        end
    else -- 未开启 综合状态显示
        function OnShowMeNaughtyAction()
            local player_classified = _G.ThePlayer and _G.ThePlayer.player_classified
            local last_actions = 0
            if player_classified then
                local actions = player_classified.net_showme_kramped.actions:value()
                local threshold = player_classified.net_showme_kramped.threshold:value()
                local str = string.format(OTHER_TITLES.naughty .. "%d / %d ",actions, threshold)
                if actions > last_actions then
                    _G.ThePlayer.components.talker:Say(str)
                end
                last_actions = actions
            end
        end
    end
end
