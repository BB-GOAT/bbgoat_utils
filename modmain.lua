GLOBAL.setmetatable(env, {
	__index = function(_, k)
		return GLOBAL.rawget(GLOBAL, k)
	end
})

-- 创建虚拟模组信息
local server_folder_name = string.find(modname, "workshop-") and "bbgoat-utils-server" or "bbgoat-utils-server-github"
local modinfo_bbgoat_util = {
    name = modinfo.name .. " - 服务器版", -- 名称
    description = modinfo.description, -- 介绍
    configuration_options = modinfo.configuration_options, -- 配置
    version = modinfo.version, -- 版本
    version_compatible = modinfo.version_compatible, -- 兼容的版本号
    author = modinfo.author, -- 作者
    api_version = modinfo.api_version, -- api版本

    dst_compatible = modinfo.dst_compatible, -- 兼容联机版
    forge_compatible = modinfo.forge_compatible, -- 兼容熔炉
    gorge_compatible = modinfo.gorge_compatible, -- 兼容暴食
    dont_starve_compatible = modinfo.dont_starve_compatible, -- 不兼容单机版

    all_clients_require_mod = false, -- 所有人需要下载，此处设为false，防止游戏提示“其他玩家需要手动下载此模组”
    client_only_mod = false, -- 客户端模组
    server_only_mod = true, -- 服务器模组

    server_filter_tags = modinfo.server_filter_tags, -- 服务器Tag

    folder_name = server_folder_name,
    locale = "zh",
    modinfo_message = "",

    icon_atlas = MODS_ROOT..modname.."/images/modicon.xml",
    iconpath = MODS_ROOT..modname.."/images/modicon.tex",
    icon = "modicon.tex",

	-- force_enabled_server_mod = true, -- 强制开启服务端模组
}

if GLOBAL.rawget(GLOBAL, "BBGOAT_utils") then -- 开启了其它版本的运行库，仅处理虚拟模组信息
    GLOBAL.BBGOAT_utils.MOD_util:AddConversionMod(modname, modinfo_bbgoat_util)

    -- 服务器优先使用非Github版
    if GLOBAL.BBGOAT_utils.server_folder_name and
        string.find(GLOBAL.BBGOAT_utils.server_folder_name, "github") and
        not string.find(server_folder_name, "github")
    then
        GLOBAL.BBGOAT_utils.server_folder_name = server_folder_name -- 供其它模组联动
    end

    return
end

modimport("bbgoat_utils/utils")
modimport("UpdateHUD.lua") -- 屏幕右下角提示HUD

GLOBAL.BBGOAT_utils = {
    env = env,

	PersistentData = PersistentData,
	Upvaluehelper = Upvaluehelper,
	MOD_util = MOD_util,
	BBGOAT_util = BBGOAT_util,
}

MOD_util:AddConversionMod(modname, modinfo_bbgoat_util)

GLOBAL.BBGOAT_utils.server_folder_name = server_folder_name -- 供其它模组联动

-- TODO：在服务器模组列表关闭此模组时，自动关闭其它依赖本模组的模组