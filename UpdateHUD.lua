local Widget = require "widgets/widget"
local Text = require "widgets/text"

local MessageWidget = Class(Widget, function(self, owner, text, colour)
    Widget._ctor(self, "MessageWidget")
    self:SetScale(2, 2)

    self.mytext = self:AddChild(Text(NUMBERFONT, 18, text or "", colour))

    local w, h = self.mytext:GetRegionSize() -- 获取文字区域大小

    self.start_x = w - 5 -- 起始X轴位置
    self.target_x = -(w + 5) -- 目标X轴位置
    self.start_y = h / 2 + 45 -- 起始Y轴位置
    self.target_y = self.start_y -- 目标Y轴位置（设为和起始位置一致，稍后往上移）

    -- 设置锚点
    self:SetHAnchor(2) -- 设置原点x坐标位置，0、1、2分别对应屏幕中、左、右
    self:SetVAnchor(2) -- 设置原点y坐标位置，0、1、2分别对应屏幕中、上、下
    self.mytext:SetHAlign(2) -- 设置右对齐

    self:MoveTo(
        { x = self.start_x, y = self.start_y, z = 0 }, -- 开始位置 from
        { x = self.target_x, y = self.start_y, z = 0}, -- 结束位置 to
        0.5, -- 移动时长 time
        nil -- 移动完成后执行的函数 fn
    )
end)

function MessageWidget:VerticalMoving(id)-- 移动位置（向上移动）
    self.target_y = self.target_y + 25
    local pos = self:GetPosition()
    self:MoveTo(
        { x = pos.x, y = pos.y, z = 0 },
        { x = self.target_x, y = self.target_y, z = 0},
        0.5,
        nil
    )
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------

_G.UpdateText = function(text, ...) print(text) end

local function RegisterHUD(self)
    local messages = {}

    -- 添加新的消息显示函数
    function self:ShowMessage(text, second, colour)
        -- 处理颜色
        if colour then
            if type(colour) == "string" and WEBCOLOURS[colour] then
                colour = (WEBCOLOURS[colour]) -- 设置颜色
            elseif type(colour) == "table" and #colour == 4 then
                -- 自定义颜色，示例： RGB(0,255,255)
            else
                text = text .. "(自定义颜色设置失败)"
                colour = nil
            end
        end

        -- 创建新的 widget
        local message = self:AddChild(MessageWidget(self.owner, text, colour))

        -- 每条旧消息上移
        for i, msg in pairs(messages) do
            msg:VerticalMoving(i)
        end

        -- 插入到旧消息列表
        table.insert(messages, 1, message)

        -- 启动销毁定时器
        message.inst:DoTaskInTime(second or 10, function()
            message:Kill()
            for i = #messages, 1, -1 do
                if messages[i] == message then
                    table.remove(messages, i)
                    break
                end
            end
        end)
    end

    _G.UpdateText = function(text, second, colour)
        text = tostring(text)
        second = type(second) == "number" and second
        print(text) -- 同时在日志显示

        if not string.find(text, "\n") then
            -- 没有换行，直接显示
            self:ShowMessage(text, second, colour)
        else
            -- 有换行，逐行拆分
            for text in string.gmatch(text, "([^\n]+)") do
                self:ShowMessage(text, second, colour)
            end
        end
    end
end

local timerTask

local onFindFrontEnd = function()
    if timerTask ~= nil then
        timerTask:Cancel()
        timerTask = nil
    end

    RegisterHUD(_G.TheFrontEnd.overlayroot)
end

if not TheNet:IsDedicated() then
    timerTask = _G.scheduler:ExecutePeriodic(1/2, function () -- 创建一个定时任务，每秒检查前端界面是否存在
        if _G.TheFrontEnd ~= nil then
            onFindFrontEnd()
        end
    end)
end