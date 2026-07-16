-- 本文件更新时间：2026年3月9日
local MOD_util = {}

local allplayerfn = {}
local allplayerfn_once = {}

---@param fn fun(world: TheWorld, player: ThePlayer): nil 
---@param onlyonce boolean|nil 本局游戏只运行一次？即使换人也不重新触发
function MOD_util:AddPlayerPostInit(fn, onlyonce) -- 好处是不用官方的any接口，作为客机时其它玩家不会触发PlayerPostInit
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
            for fn, v in pairs(allplayerfn_once) do
                fn(self, data)
            end
        end
        for fn, v in pairs(allplayerfn) do
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

-- 记录需要加载的第三方Assets
local RegisterModAssetsFns = rawget(_G, "BBGoatRegisterModAssetsFns")
if not RegisterModAssetsFns then
    RegisterModAssetsFns = {}
    _G.BBGoatRegisterModAssetsFns = RegisterModAssetsFns -- 设置在全局环境以便从其它地方访问(如果你想复制我的代码，请不要修改这个变量名)

    local OldStart = _G.Start
    _G.Start = function(...)
        for i,v in ipairs(RegisterModAssetsFns) do
            v()
        end
        OldStart(...)
    end

    local OldRegisterPrefabs = _G.ModManager.RegisterPrefabs
    _G.ModManager.RegisterPrefabs = function(...)
        OldRegisterPrefabs(...)
        for i,v in ipairs(RegisterModAssetsFns) do
            v()
        end
    end
end

-- 判断Assets是否有效
local function IsValidAssets(modname, assets)
    if not KnownModIndex:GetModInfo(modname) then
        return false
    end
    for i, asset in ipairs(assets) do
        if not asset or not asset.type or not asset.file then
            return false
        end
        if not kleifileexists(_G.MODS_ROOT .. modname .. "/" .. asset.file) then
            return false
        end
    end
    return true
end

--- @param modname string 模组ID
--- @param assets table 需要加载的资源表
function MOD_util:RegisterOtherModAssets(modname, assets) -- 加载指定模组的指定Assets
    if not IsValidAssets(modname, assets) then
        self:Warning("[MOD_util:RegisterOtherModAssets] 尝试加载的Assets无效，目标modname = " .. tostring(modname), 3)
        return
    end
    table.insert(RegisterModAssetsFns, function()
        local pref = _G.Prefab("MOD_"..modname, nil, assets, {}, true)
        pref.search_asset_first_path = _G.MODS_ROOT .. modname.. "/"
        _G.RegisterSinglePrefab(pref)

        TheSim:LoadPrefabs({pref.name})
        if not table.contains(_G.ModManager.loadedprefabs, pref.name) then -- 防止重复添加
            table.insert(_G.ModManager.loadedprefabs, pref.name)
        end
    end)
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

-- 检查模组信息..防人之心不可无，希望我永远用不到
--[[
function MOD_util:DoCrash()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:SetParent(inst.entity)
end

function MOD_util:CheckReallyTime(finaltime)
	--示例 20260626 y+m+d
	if finaltime < tonumber(os.date("%Y%m%d")) then
		MOD_util:DoCrash()
	end
end

local wannacheck = true
local authorname = "冰冰羊"
function MOD_util:CheckAuthor(_env)
	local info = _env and _env.modinfo or env and env.modinfo
	local author = info and info.author
	if author ~= authorname and not string.find(author, authorname) then
		local randomtime = math.random(3, 10)
		self:DoTaskInTime(randomtime, self.DoCrash)
	end
end

function MOD_util:CheckModName(checkname, _env)
	local modname = _env and _env.modname or env and env.modname
	if modname ~= checkname and not string.find(modname, checkname) then
		local randomtime = math.random(3, 10)
		self:DoTaskInTime(randomtime, self.DoCrash)
	end
end]]

return MOD_util