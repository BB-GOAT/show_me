local tostring = _G.tostring

-- 当前已加载的目标语言，用于变化检测避免重复重建
local loaded_lang

--- （重）构建语言表：先重置 chs 基础表，再按客户端配置加载目标语言覆盖描述
---@param lang_config string|nil 调用方提供的客户端 lang 配置值；为 nil 时才回退读取 GetModConfigData("lang", true)
---@return string|nil 实际加载的目标语言，nil 表示使用 chs 基础表
local function SetupLanguage(lang_config)
	local chs_data = Import(MODROOT .. "showme_chs.lua")
	for k, v in pairs(chs_data) do
		env[k] = v
	end

	local i = 1
	for k, str in _G.orderedPairs(MY_STRINGS) do
		local data = MY_DATA[k]
		if data == nil then
			data = {}
			MY_DATA[k] = data
		end
		data.desc = str -- MY_DATA.armor.desc 则显示 防御：
		data.id = i -- 索引ID
		data.sym = "?" .. tostring(i) .. ":" -- 编码后的前缀（如 "?1:"）
		i = i + 1
	end

	local lang = lang_config
	if lang == nil then
		lang = GetModConfigData("lang", true)
	end
	if lang == nil or lang == "auto" then
		lang = GetModConfigData("lang")
	end
	if lang == nil or lang == "auto" then
		lang = _G.LanguageTranslator.defaultlang or "en"
	end
	lang = lang:lower()

	local support_languages = {
		zht = "cht", --traditional Chinese for Steam
		tc = "cht", --traditional Chinese
		cht = "cht", --Chinese mod
		en = "en", --English
	}
	local target = support_languages[lang] -- nil 表示使用 chs 基础表
	if target == loaded_lang then
		return loaded_lang -- 语言未变化，无需重建
	end
	loaded_lang = target

	if target ~= nil then
		local lang_data = Import(MODROOT .. "showme_" .. target .. ".lua")
		for k, v in pairs(lang_data) do
			if k ~= "MY_STRINGS" then
				-- 链接字符串表（含嵌套表格）
				local function LinkTables(tbl, fallback)
					_G.setmetatable(tbl, {
						__index = fallback, -- 查找 tbl 中不存在的键时回退到 fallback
					})
					for key, value in pairs(tbl) do
						if type(value) == "table" then
							LinkTables(value, fallback[key])
						end
					end
				end
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
	return loaded_lang
end

return {
	SetupLanguage = SetupLanguage,
}