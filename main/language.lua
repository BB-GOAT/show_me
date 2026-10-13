local tonumber = _G.tonumber
local tostring = _G.tostring

-- 加载语言
for k,v in pairs(Import(MODROOT .. "showme_chs.lua")) do
    env[k] = v
end

-- 从 "?idx:" 前缀解码到 MY_STRINGS 中的索引
local function decodeDataPrefix(str)
    local _, stop_pos, id = string.find(str, "^%?(%d+):")
    return tonumber(id) or 0, stop_pos and (stop_pos + 1) or 2
end

local function encodeDataPrefix(idx)
    return "?" .. tostring(idx) .. ":"
end

-- 语言调用
local MY_DATA_BY_ID = {}
do
    local i = 1
    for k,str in _G.orderedPairs(MY_STRINGS) do
        MY_DATA[k] = {
            desc = str,    -- MY_DATA.armor.desc 则显示 防御：
            id = i,    -- 索引ID
            sym = encodeDataPrefix(i), -- 编码后的前缀（如 "?1:"）
            fn = nil, --默认值: desc .. " " .. param1，可覆盖例如：MY_DATA.buff.fn
            percent = nil, --在数字末尾添加“%”，例如：MY_DATA.sanity_character.percent = true
        }
        MY_DATA_BY_ID[i] = k
        i = i + 1
    end
end

do
    local support_languages = {
        -- zh = "chs", --Chinese for Steam
        -- zhr = "chs", --Chinese for WeGame
        -- ch = "chs", --Chinese mod
        -- chs = "chs", --Chinese mod
        -- sc = "chs", --simple Chinese
        -- chinese = "chs", --Chinese mod
        zht = "cht", --traditional Chinese for Steam
        tc = "cht", --traditional Chinese
        cht = "cht", --Chinese mod
        en = "en", --English
    }

    -- 链接字符串表
    local function LinkTables(tbl, fallback)
        _G.setmetatable(tbl, {
            __index = fallback,  -- 查找 tbl 中不存在的键时回退到 fallback
        })

        -- 对嵌套表格也进行同样的操作
        for key, value in pairs(tbl) do
            if type(value) == "table" then
                LinkTables(value, fallback[key])
            end
        end
    end

    local lang = GetModConfigData("lang", true)
    if lang == "auto" then
        lang = GetModConfigData("lang")
    end
    print("Detected language for ShowMe: ", lang, lang == "auto" and _G.LanguageTranslator.defaultlang or "en")

    if lang == "auto" then
        lang = _G.LanguageTranslator.defaultlang or "en"
    end
    lang = lang:lower()

    if support_languages[lang] then
        local lang_data = Import(MODROOT .. "showme_" .. support_languages[lang] .. ".lua") -- 加载语言
        for k,v in pairs(lang_data) do
            if k ~= "MY_STRINGS" then
                LinkTables(v, env[k])
                env[k] = v
            else
                for key, value in pairs(v) do
                    if MY_DATA[key] then
                        MY_DATA[key].desc = value
                    end
                end
            end
        end
    end
end

return {
    decodeDataPrefix = decodeDataPrefix,
    MY_DATA_BY_ID = MY_DATA_BY_ID,
}