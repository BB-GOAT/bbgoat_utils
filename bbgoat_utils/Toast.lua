local _G = GLOBAL

if TheNet:IsDedicated() then -- 专用服务器
    return function(text)
        print(tostring(text))
    end
end

local Widget = require "widgets/widget"
local Image = require "widgets/image"
local Text = require "widgets/text"

local TOAST_FONT = "bbgoat_toast_font"
local TOAST_FONT_FILE = MODROOT .. "fonts/" .. TOAST_FONT .. ".zip"
table.insert(_G.FONTS, {
    filename = TOAST_FONT_FILE,
    alias = TOAST_FONT,
    fallback = _G.DEFAULT_FALLBACK_TABLE,
})

local TOAST_ATLAS = "images/bbgoat_toast.xml"
Assets = Assets or {}
table.insert(Assets, Asset("ATLAS", TOAST_ATLAS))
table.insert(Assets, Asset("IMAGE", "images/bbgoat_toast.tex"))

local FONT_SIZE = 32       -- 基础字号，中文缩放取整后为28
local PADDING_X = 24       -- 文字左右各侧内边距（像素）
local PADDING_Y = 8        -- 文字上下各侧内边距（像素）
local EDGE_MARGIN = 20     -- 距屏幕顶部及所在侧边缘的距离（像素）
local ENTER_DURATION = 0.8 -- 入场移动、淡入时长（秒）
local EXIT_DURATION = 0.6  -- 出场淡出时长（秒）
local ENTER_DISTANCE = 70  -- 入场时（从最终位置下方）向上移动的距离（像素）
local BACKGROUNDS = {
    info = RGB(72, 187, 248), -- #48BBF8
    success = RGB(71, 210, 121), -- #47D279
    warning = RGB(255, 178, 67), -- #FFB243
    error = RGB(255, 100, 100), -- #FF6464
}

-- 入场与退场共用的贝塞尔缓动曲线
local function ToastEase(progress)
    if progress <= 0 then
        return 0
    elseif progress >= 1 then
        return 1
    end

    local low, high = 0, 1
    local t
    for i = 1, 18 do
        t = (low + high) / 2
        local remaining = 1 - t
        local x = 3 * remaining * remaining * t * 0.22
            + 3 * remaining * t * t * 0.12 + t * t * t
        if x < progress then
            low = t
        else
            high = t
        end
    end

    t = (low + high) / 2
    local remaining = 1 - t
    return 3 * remaining * remaining * t * 0.58
        + 3 * remaining * t * t * 0.98 + t * t * t
end

local BACKGROUND_SLICES = {
    { "top_left", -1, 1 }, { "top_center", 0, 1 }, { "top_right", 1, 1 },
    { "mid_left", -1, 0 }, { "mid_center", 0, 0 }, { "mid_right", 1, 0 },
    { "bottom_left", -1, -1 }, { "bottom_center", 0, -1 }, { "bottom_right", 1, -1 },
}

local function AddToastBackground(message, toast_type, colour)
    local style = toast_type == "error" and "error" or "info"
    local margin = style == "error" and 28 or 8
    local cap = 12
    -- 九宫格拉伸背景，保留圆角与阴影的边缘尺寸
    for _, slice in ipairs(BACKGROUND_SLICES) do
        local horizontal, vertical = slice[2], slice[3]
        local image = message:AddChild(Image(TOAST_ATLAS, style .. "_" .. slice[1] .. ".tex"))
        image:SetSize(horizontal == 0 and message.width - cap * 2 or cap + margin,
            vertical == 0 and message.height - cap * 2 or cap + margin)
        image:SetPosition(horizontal * (message.width / 2 - cap / 2 + margin / 2),
            vertical * (message.height / 2 - cap / 2 + margin / 2))
        image:SetTint(colour[1], colour[2], colour[3], colour[4] or 1)
        image:SetClickable(false)
    end
end

local ToastLayer = Class(Widget, function(self, position)
    Widget._ctor(self, "BBGOAT_ToastLayer")
    self.messages = {}
    self.horizontal_sign = position == "left" and 1 or -1
    -- 使用屏幕像素；左右各自锚定对应屏幕边缘，互不影响排列
    self:SetScaleMode(SCALEMODE_NONE)
    self:SetHAnchor(position == "left" and ANCHOR_LEFT or ANCHOR_RIGHT)
    self:SetVAnchor(ANCHOR_TOP)
    self:SetClickable(false)
end)

function ToastLayer:Reflow()
    local top = EDGE_MARGIN
    for _, message in ipairs(self.messages) do
        message.slot_x = self.horizontal_sign * (EDGE_MARGIN + message.width / 2)
        message.slot_y = -top - message.height / 2
        message:SetPosition(message.slot_x, message.slot_y - message.offset_y)
        top = top + message.height
    end
end

function ToastLayer:ShowToast(text, second, toast_type, colour, font)
    local background = colour or BACKGROUNDS[toast_type]
    local message = self:AddChild(Widget("BBGOAT_Toast"))
    message:SetClickable(false)

    -- 默认使用提示专用无描边字体，仍可通过第五参数指定其它字体
    font = font or TOAST_FONT

    -- 保留显式换行，按实际文字尺寸布局
    -- 将语言缩放后的实际字号向上取整
    local text_scale = _G.LOC and _G.LOC.GetTextScale() or 1
    local font_size = math.ceil(FONT_SIZE * text_scale) / text_scale
    local label = message:AddChild(Text(font, font_size, text, { 1, 1, 1, 1 }))
    label:SetHAlign(ANCHOR_LEFT)
    -- 专用字库补偿半像素采样偏移，避免停稳后笔画被插值模糊
    if font == TOAST_FONT then
        label:SetPosition(0.5, 0.5)
    end
    label:SetClickable(false)
    local width, height = label:GetRegionSize()
    message.width = math.max(width, 1) + PADDING_X * 2
    message.height = math.max(height, FONT_SIZE) + PADDING_Y * 2

    AddToastBackground(message, toast_type, background)
    label:MoveToFront()

    message.phase = "enter"
    message.phase_elapsed = 0
    message.offset_y = ENTER_DISTANCE
    message:SetFadeAlpha(0)
    table.insert(self.messages, message)
    self:Reflow()
    self:MoveToFront()
    self:StartUpdating()

    -- 从创建时开始计时，暂停时仍继续计时
    message.inst:DoTaskInTime(math.max(second, 0), function()
        message.phase = "out"
        message.phase_elapsed = 0
        message.offset_y = 0
        message:SetPosition(message.slot_x, message.slot_y)
        message:SetFadeAlpha(1)
        self:StartUpdating()
    end)
end

function ToastLayer:OnUpdate(dt)
    dt = math.min(dt, 1 / 30) -- 避免卡顿造成一次推进过多，跳过入场或退场动画

    local animated = false
    local removed = false

    for i = #self.messages, 1, -1 do
        local message = self.messages[i]
        if message.phase ~= "hold" then
            -- 仅推进动画中的提示，入场与退场共用进度计算
            local entering = message.phase == "enter"
            local duration = entering and ENTER_DURATION or EXIT_DURATION
            local elapsed = message.phase_elapsed + dt
            message.phase_elapsed = elapsed
            local progress = ToastEase(elapsed / duration)
            message:SetFadeAlpha(entering and progress or 1 - progress)
            if entering then
                message.offset_y = ENTER_DISTANCE * (1 - progress)
                message:SetPosition(message.slot_x, message.slot_y - message.offset_y)
            end

            if elapsed < duration then
                animated = true
            elseif entering then
                message.phase = "hold"
            else
                -- 按实例所在位置移除，支持不同显示时长交错结束
                table.remove(self.messages, i)
                message:Kill()
                removed = true
            end
        end
    end

    if removed then
        -- 移除后立即补位
        self:Reflow()
    end
    if not animated then
        self:StopUpdating()
    end
end

local function GetToastLayer(position)
    local frontend = _G.TheFrontEnd
    local overlayroot = frontend and frontend.overlayroot
    if not overlayroot then
        return
    end

    -- 省略或传入无效位置时使用右上角；左右分别维护独立的提示队列
    local layer_key = position == "left" and "bbgoat_toast_left_layer" or "bbgoat_toast_layer"
    local layer = overlayroot[layer_key]
    if not layer then
        layer = overlayroot:AddChild(ToastLayer(position))
        overlayroot[layer_key] = layer
    end
    return layer
end

---@param text string 信息文本
---@param second number 显示秒数
---@param colour string|table 背景颜色
---@param position 'left'|'right' 提示位置
---@param font string 信息字体
local Toast = function(text, second, colour, position, font)
    text = tostring(text)
    print(text) -- 同时在日志显示，保留原始换行

    local layer = GetToastLayer(position)
    if not layer then
        return
    end

    -- 提示类型、颜色名和 RGBA 表均设置背景色，文字保持白色
    local toast_type = "info"
    if type(colour) == "string" and BACKGROUNDS[colour] then
        toast_type = colour
        colour = nil
    elseif type(colour) == "string" and WEBCOLOURS[colour] then
        colour = WEBCOLOURS[colour]
    elseif colour and (type(colour) ~= "table" or #colour ~= 4) then
        text = text .. "(自定义颜色设置失败)"
        colour = nil
    end

    -- 保留换行与空白，统一回车换行格式
    text = text:gsub("\r\n", "\n"):gsub("\r", "\n")
    layer:ShowToast(text, type(second) == "number" and second or 10, toast_type, colour, font)
end

return Toast