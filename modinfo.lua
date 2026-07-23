---@diagnostic disable: lowercase-global
local L = locale
local function en_zh(en, zh)
    return L ~= "zh" and L ~= "zhr" and L ~= "zht" and en or zh
end

name = en_zh("BBGOAT Utils", "冰冰羊的模组运行库")
description = [[]]
author = "冰冰羊"
version = "2026-7-23-A"
version_compatible = "2026-7-17"
api_version_dst = 10
priority = 2e53

if not folder_name:find("workshop-") then
    name = name .. en_zh(" - GitHub Ver", " - GitHub 版")
    priority = 2e54
end

dst_compatible = true -- 兼容联机版
forge_compatible = true -- 兼容熔炉
gorge_compatible = true -- 兼容暴食
dont_starve_compatible = false -- 不兼容单机版

server_only_mod = false
client_only_mod = true
all_clients_require_mod = true
-- 补充说明：上面2个都是true是故意的，不会导致游戏出现任何问题。再拿这个说我直接开喷

icon_atlas = "images/modicon.xml"
icon = "modicon.tex"

server_filter_tags = {
    "冰冰羊",
    "bbgoat_utils",
    "bbgoat_utils " .. version
}
configuration_options = {}