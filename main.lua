--[[
    =================================================================
     Модульный UI-фреймворк для Roblox (LocalScript, Luau)
     Версия 2.0 — с 10 улучшениями
    =================================================================
]]

--============================================================
-- 1. СЕРВИСЫ
--============================================================
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = Workspace.CurrentCamera

--============================================================
-- 2. БАЗОВАЯ ТАБЛИЦА + CLEANUP
--============================================================
local UILib = {}
UILib.IsCapturingKeybind = false
UILib.DraggingFrame = nil -- Улучшение 5: единый drag-контекст

UILib.CleanupConnections = {}
UILib.CleanupTasks = {}

local function track(connection)
    table.insert(UILib.CleanupConnections, connection)
    return connection
end

local function deferCleanup(fn)
    table.insert(UILib.CleanupTasks, fn)
end

function UILib.Cleanup()
    for _, connection in ipairs(UILib.CleanupConnections) do
        if typeof(connection) == "RBXScriptConnection" and connection.Connected then
            connection:Disconnect()
        end
    end
    table.clear(UILib.CleanupConnections)
    for _, fn in ipairs(UILib.CleanupTasks) do
        pcall(fn)
    end
    table.clear(UILib.CleanupTasks)
end

--============================================================
-- 3. ТЕМА
--============================================================
local Theme = {
    Background    = Color3.fromRGB(22, 22, 26),
    Sidebar       = Color3.fromRGB(18, 18, 21),
    Card          = Color3.fromRGB(30, 30, 35),
    CardHover     = Color3.fromRGB(38, 38, 44),
    Border        = Color3.fromRGB(48, 48, 54),
    TextPrimary   = Color3.fromRGB(235, 235, 240),
    TextSecondary = Color3.fromRGB(145, 145, 155),
    TextInactive  = Color3.fromRGB(120, 120, 128),
    Accent        = Color3.fromRGB(88, 101, 242),
    Success       = Color3.fromRGB(87, 201, 124),
    Warning       = Color3.fromRGB(240, 176, 62),
    Error         = Color3.fromRGB(230, 90, 90),
    Info          = Color3.fromRGB(90, 160, 230),
}

local AccentPresets = {
    Color3.fromRGB(88, 101, 242),
    Color3.fromRGB(230, 90, 90),
    Color3.fromRGB(240, 176, 62),
    Color3.fromRGB(87, 201, 124),
    Color3.fromRGB(90, 190, 230),
    Color3.fromRGB(190, 100, 230),
    Color3.fromRGB(240, 120, 170),
    Color3.fromRGB(180, 180, 190),
}

local AccentTracker = { Static = {}, Toggles = {}, Tabs = {} }

local function registerStatic(instance, property)
    table.insert(AccentTracker.Static, {instance = instance, property = property})
end
local function registerToggle(entry)
    table.insert(AccentTracker.Toggles, entry)
end
local function registerTab(entry)
    table.insert(AccentTracker.Tabs, entry)
end

local function tween(instance, props, duration, style, direction)
    duration = duration or 0.2
    style = style or Enum.EasingStyle.Quint
    direction = direction or Enum.EasingDirection.Out
    local t = TweenService:Create(instance, TweenInfo.new(duration, style, direction), props)
    t:Play()
    return t
end

local function SetAccent(color)
    Theme.Accent = color
    for _, e in ipairs(AccentTracker.Static) do
        if e.instance and e.instance.Parent then
            tween(e.instance, {[e.property] = color}, 0.2)
        end
    end
    for _, e in ipairs(AccentTracker.Toggles) do
        if e.getState and e.getState() and e.trackInstance and e.trackInstance.Parent then
            tween(e.trackInstance, {BackgroundColor3 = color}, 0.2)
        end
    end
    for _, e in ipairs(AccentTracker.Tabs) do
        if e.isActive and e.isActive() and e.button and e.button.Parent then
            tween(e.button, {BackgroundColor3 = color}, 0.2)
        end
    end
end

--============================================================
-- 4. ЗВУК
--============================================================
local ClickSound = Instance.new("Sound")
ClickSound.SoundId = "rbxassetid://6895056283"
ClickSound.Volume = 0.5
ClickSound.Parent = Workspace
deferCleanup(function() ClickSound:Destroy() end)

local function playClick()
    ClickSound.TimePosition = 0
    ClickSound:Play()
end

--============================================================
-- 5. КОНФИГ (Улучшение 10: Debounce сохранения)
--============================================================
local Config = {}
Config.Data = {}
Config.SaveConfigEnabled = true
Config.Provider = nil
Config._saveTimer = nil

function Config.SetProvider(provider)
    Config.Provider = provider
end

function Config.Set(key, value)
    Config.Data[key] = value
end

function Config.Get(key, default)
    local value = Config.Data[key]
    if value == nil then return default end
    return value
end

function Config.SaveConfig()
    if not Config.SaveConfigEnabled then return end

    -- Улучшение 10: Debounce — откладываем сохранение на 2 секунды
    if Config._saveTimer then
        task.cancel(Config._saveTimer)
    end
    Config._saveTimer = task.delay(2, function()
        local ok, encoded = pcall(function()
            return HttpService:JSONEncode(Config.Data)
        end)
        if not ok then return end

        if Config.Provider and Config.Provider.Save then
            pcall(Config.Provider.Save, encoded)
        end
    end)
end

function Config.LoadConfig()
    if Config.Provider and Config.Provider.Load then
        local ok, raw = pcall(Config.Provider.Load)
        if ok and raw then
            local decodeOk, decoded = pcall(function()
                return HttpService:JSONDecode(raw)
            end)
            if decodeOk and typeof(decoded) == "table" then
                Config.Data = decoded
            end
        end
    end
    return Config.Data
end

Config.LoadConfig()

--============================================================
-- 6. SCREENGUI + ГЛАВНОЕ ОКНО
--============================================================
local GUI_NAME = "ModularUILibrary"

local existingGui = PlayerGui:FindFirstChild(GUI_NAME)
if existingGui then existingGui:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = GUI_NAME
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 999999
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = PlayerGui

deferCleanup(function()
    if ScreenGui and ScreenGui.Parent then ScreenGui:Destroy() end
end)

local MainFrame = Instance.new("Frame")
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.Size = UDim2.new(0, 0, 0, 0)
MainFrame.BackgroundColor3 = Theme.Background
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.ClipsDescendants = true
MainFrame.ZIndex = 1
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Thickness = 1.5
MainStroke.Color = Theme.Border
MainStroke.Parent = MainFrame

local UIScaleObj = Instance.new("UIScale")
UIScaleObj.Parent = MainFrame

local function computeScale()
    local vp = Camera and Camera.ViewportSize or Vector2.new(1280, 720)
    return math.clamp(math.min(vp.X / 500, vp.Y / 390), 0.62, 1.15)
end

local function updateScale()
    tween(UIScaleObj, {Scale = computeScale()}, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
end

if Camera then
    track(Camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale))
end
track(Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    Camera = Workspace.CurrentCamera
    if Camera then
        updateScale()
        track(Camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale))
    end
end))
updateScale()

--============================================================
-- 7. DRAG (Улучшение 5: Оптимизация — один глобальный обработчик)
--============================================================
local function makeDraggable(dragHandle, target)
    dragHandle.Active = true

    track(dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            UILib.DraggingFrame = {
                target = target,
                startInput = input.Position,
                startPos = target.Position,
            }

            local conn
            conn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    UILib.DraggingFrame = nil
                    conn:Disconnect()
                end
            end)
            track(conn)
        end
    end))
end

-- Единый глобальный обработчик перемещения
track(UserInputService.InputChanged:Connect(function(input)
    if not UILib.DraggingFrame then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch then
        local d = UILib.DraggingFrame
        local delta = input.Position - d.startInput
        d.target.Position = UDim2.new(
            d.startPos.X.Scale, d.startPos.X.Offset + delta.X,
            d.startPos.Y.Scale, d.startPos.Y.Offset + delta.Y
        )
    end
end))

--============================================================
-- 8. САЙДБАР + ЗАГОЛОВОК
--============================================================
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 130, 1, 0)
Sidebar.BackgroundColor3 = Theme.Sidebar
Sidebar.BorderSizePixel = 0
Sidebar.ZIndex = 2
Sidebar.Parent = MainFrame

local SidebarPadding = Instance.new("UIPadding")
SidebarPadding.PaddingTop = UDim.new(0, 10)
SidebarPadding.PaddingLeft = UDim.new(0, 5)
SidebarPadding.Parent = Sidebar

local SidebarLayout = Instance.new("UIListLayout")
SidebarLayout.FillDirection = Enum.FillDirection.Vertical
SidebarLayout.Padding = UDim.new(0, 5)
SidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
SidebarLayout.Parent = Sidebar

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, -130, 0, 50)
Header.Position = UDim2.new(0, 130, 0, 0)
Header.BackgroundColor3 = Theme.Background
Header.BorderSizePixel = 0
Header.ZIndex = 2
Header.Parent = MainFrame

local Logo = Instance.new("Frame")
Logo.Size = UDim2.new(0, 30, 0, 30)
Logo.Position = UDim2.new(0, 12, 0, 10)
Logo.BackgroundColor3 = Theme.Accent
Logo.BorderSizePixel = 0
Logo.ZIndex = 3
Logo.Parent = Header

local LogoCorner = Instance.new("UICorner")
LogoCorner.CornerRadius = UDim.new(0, 8)
LogoCorner.Parent = Logo
registerStatic(Logo, "BackgroundColor3")

local TitleLabel = Instance.new("TextLabel")
TitleLabel.BackgroundTransparency = 1
TitleLabel.Position = UDim2.new(0, 52, 0, 6)
TitleLabel.Size = UDim2.new(1, -100, 0, 20)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Text = "UI Framework"
TitleLabel.TextColor3 = Theme.TextPrimary
TitleLabel.TextSize = 15
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.ZIndex = 3
TitleLabel.Parent = Header

local SubtitleLabel = Instance.new("TextLabel")
SubtitleLabel.BackgroundTransparency = 1
SubtitleLabel.Position = UDim2.new(0, 52, 0, 25)
SubtitleLabel.Size = UDim2.new(1, -100, 0, 16)
SubtitleLabel.Font = Enum.Font.Gotham
SubtitleLabel.Text = "v2.0 Enhanced"
SubtitleLabel.TextColor3 = Theme.TextSecondary
SubtitleLabel.TextSize = 12
SubtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
SubtitleLabel.ZIndex = 3
SubtitleLabel.Parent = Header

local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 28, 0, 28)
CloseButton.Position = UDim2.new(1, -38, 0, 11)
CloseButton.BackgroundColor3 = Theme.Card
CloseButton.BorderSizePixel = 0
CloseButton.Text = "×"
CloseButton.TextColor3 = Theme.TextSecondary
CloseButton.TextSize = 18
CloseButton.Font = Enum.Font.GothamBold
CloseButton.ZIndex = 3
CloseButton.Parent = Header

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseButton

track(CloseButton.MouseEnter:Connect(function()
    tween(CloseButton, {BackgroundColor3 = Theme.CardHover}, 0.15)
end))
track(CloseButton.MouseLeave:Connect(function()
    tween(CloseButton, {BackgroundColor3 = Theme.Card}, 0.15)
end))

makeDraggable(Header, MainFrame)

--============================================================
-- 9. KEYBIND РЕЕСТР
--============================================================
local KeybindRegistry = {}

--============================================================
-- 10. ВКЛАДКИ И СТРАНИЦЫ
--============================================================
local PageContainer = Instance.new("Frame")
PageContainer.BackgroundTransparency = 1
PageContainer.Position = UDim2.new(0, 140, 0, 55)
PageContainer.Size = UDim2.new(1, -150, 1, -60)
PageContainer.ZIndex = 2
PageContainer.Parent = MainFrame

local Tabs = {}
local ActiveTabName = nil

local function createPage(name)
    local Page = Instance.new("ScrollingFrame")
    Page.Size = UDim2.new(1, 0, 1, 0)
    Page.BackgroundTransparency = 1
    Page.BorderSizePixel = 0
    Page.ScrollBarThickness = 2
    Page.ScrollBarImageColor3 = Theme.Accent
    Page.CanvasSize = UDim2.new(0, 0, 0, 0)
    Page.Visible = false
    Page.ZIndex = 2
    Page.Parent = PageContainer

    -- Улучшение 6: Симметричные отступы
    local Padding = Instance.new("UIPadding")
    Padding.PaddingLeft = UDim.new(0, 4)
    Padding.PaddingRight = UDim.new(0, 8)
    Padding.PaddingTop = UDim.new(0, 4)
    Padding.PaddingBottom = UDim.new(0, 10)
    Padding.Parent = Page

    local Layout = Instance.new("UIListLayout")
    Layout.FillDirection = Enum.FillDirection.Vertical
    Layout.Padding = UDim.new(0, 8)
    Layout.SortOrder = Enum.SortOrder.LayoutOrder
    Layout.Parent = Page

    track(Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Page.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y + 20)
    end))

    return Page
end

local function selectTab(name)
    if ActiveTabName == name then return end
    ActiveTabName = name
    for tabName, data in pairs(Tabs) do
        local isActive = tabName == name
        data.page.Visible = isActive
        tween(data.button, {
            TextColor3 = isActive and Color3.fromRGB(255, 255, 255) or Theme.TextInactive,
            BackgroundColor3 = isActive and Theme.Accent or Theme.Sidebar,
        }, 0.15)
    end
end

local function createTab(name, layoutOrder)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, -10, 0, 34)
    Button.BackgroundColor3 = Theme.Sidebar
    Button.BorderSizePixel = 0
    Button.AutoButtonColor = false
    Button.Font = Enum.Font.Gotham
    Button.Text = name
    Button.TextColor3 = Theme.TextInactive
    Button.TextSize = 13
    Button.ZIndex = 3
    Button.LayoutOrder = layoutOrder
    Button.Parent = Sidebar

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = Button

    local Page = createPage(name)

    track(Button.MouseEnter:Connect(function()
        if ActiveTabName ~= name then
            tween(Button, {BackgroundColor3 = Theme.CardHover}, 0.15)
        end
    end))
    track(Button.MouseLeave:Connect(function()
        if ActiveTabName ~= name then
            tween(Button, {BackgroundColor3 = Theme.Sidebar}, 0.15)
        end
    end))
    track(Button.MouseButton1Click:Connect(function()
        playClick()
        selectTab(name)
    end))

    Tabs[name] = {button = Button, page = Page}
    registerTab({button = Button, isActive = function() return ActiveTabName == name end})

    return Page
end

--============================================================
-- 11. ФАБРИЧНЫЕ ФУНКЦИИ ЭЛЕМЕНТОВ
--============================================================

-- 11.1 CreateToggle
local function CreateToggle(parent, options)
    options = options or {}

    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -10, 0, 38)
    container.BackgroundColor3 = Theme.Card
    container.BorderSizePixel = 0
    container.ZIndex = 5
    container.LayoutOrder = options.layoutOrder or 0
    container.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = container

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 10, 0, 0)
    label.Size = UDim2.new(1, -60, 1, 0)
    label.Font = Enum.Font.Gotham
    label.Text = options.title or "Toggle"
    label.TextColor3 = Theme.TextPrimary
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 6
    label.Parent = container

    local toggleButton = Instance.new("TextButton")
    toggleButton.Text = ""
    toggleButton.AutoButtonColor = false
    toggleButton.Size = UDim2.new(0, 38, 0, 20)
    toggleButton.Position = UDim2.new(1, -48, 0.5, -10)
    toggleButton.BackgroundColor3 = Theme.CardHover
    toggleButton.BorderSizePixel = 0
    toggleButton.ZIndex = 6
    toggleButton.Parent = container

    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(1, 0)
    toggleCorner.Parent = toggleButton

    local circle = Instance.new("Frame")
    circle.Size = UDim2.new(0, 16, 0, 16)
    circle.Position = UDim2.new(0, 2, 0.5, -8)
    circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    circle.BorderSizePixel = 0
    circle.ZIndex = 7
    circle.Parent = toggleButton

    local circleCorner = Instance.new("UICorner")
    circleCorner.CornerRadius = UDim.new(1, 0)
    circleCorner.Parent = circle

    local state = false
    if options.cfgKey and Config.Get(options.cfgKey, nil) ~= nil then
        state = Config.Get(options.cfgKey, false) == true
    elseif options.default then
        state = true
    end

    local function render(animated)
        local duration = animated and 0.2 or 0
        if state then
            tween(circle, {Position = UDim2.new(0, 20, 0.5, -8)}, duration)
            tween(toggleButton, {BackgroundColor3 = Theme.Accent}, duration)
        else
            tween(circle, {Position = UDim2.new(0, 2, 0.5, -8)}, duration)
            tween(toggleButton, {BackgroundColor3 = Theme.CardHover}, duration)
        end
    end

    render(false)
    registerToggle({trackInstance = toggleButton, getState = function() return state end})

    track(toggleButton.MouseButton1Click:Connect(function()
        playClick()
        state = not state
        render(true)
        if options.cfgKey then
            Config.Set(options.cfgKey, state)
            Config.SaveConfig()
        end
        if options.callback then
            task.spawn(options.callback, state)
        end
    end))

    return {
        Instance = container,
        SetState = function(newState, silent)
            state = newState
            render(true)
            if not silent and options.callback then
                task.spawn(options.callback, state)
            end
        end,
        GetState = function() return state end,
    }
end

-- 11.2 CreateButton
local function CreateButton(parent, options)
    options = options or {}

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -10, 0, 33)
    button.BackgroundColor3 = Theme.Card
    button.BorderSizePixel = 0
    button.AutoButtonColor = false
    button.Font = Enum.Font.Gotham
    button.Text = options.title or "Button"
    button.TextColor3 = Theme.TextPrimary
    button.TextSize = 13
    button.ZIndex = 5
    button.LayoutOrder = options.layoutOrder or 0
    button.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = button

    track(button.MouseEnter:Connect(function()
        tween(button, {BackgroundColor3 = Theme.CardHover}, 0.15)
    end))
    track(button.MouseLeave:Connect(function()
        tween(button, {BackgroundColor3 = Theme.Card}, 0.15)
    end))
    track(button.MouseButton1Click:Connect(function()
        playClick()
        if options.callback then task.spawn(options.callback) end
    end))

    return button
end

-- 11.3 CreateSlider (Улучшение 4: форматирование значений)
local function CreateSlider(parent, title, min, max, default, callback, layoutOrder, options)
    options = options or {}
    local suffix = options.suffix or ""
    local formatFunc = options.format

    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -10, 0, 50)
    container.BackgroundColor3 = Theme.Card
    container.BorderSizePixel = 0
    container.ZIndex = 5
    container.LayoutOrder = layoutOrder or 0
    container.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = container

    local titleLabel = Instance.new("TextLabel")
    titleLabel.BackgroundTransparency = 1
    titleLabel.Position = UDim2.new(0, 10, 0, 6)
    titleLabel.Size = UDim2.new(1, -70, 0, 16)
    titleLabel.Font = Enum.Font.Gotham
    titleLabel.Text = title
    titleLabel.TextColor3 = Theme.TextPrimary
    titleLabel.TextSize = 13
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.ZIndex = 6
    titleLabel.Parent = container

    local valueLabel = Instance.new("TextLabel")
    valueLabel.BackgroundTransparency = 1
    valueLabel.Position = UDim2.new(1, -60, 0, 6)
    valueLabel.Size = UDim2.new(0, 50, 0, 16)
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextColor3 = Theme.TextSecondary
    valueLabel.TextSize = 13
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.ZIndex = 6
    valueLabel.Parent = container

    local sliderTrack = Instance.new("Frame")
    sliderTrack.Position = UDim2.new(0, 10, 0, 32)
    sliderTrack.Size = UDim2.new(1, -20, 0, 6)
    sliderTrack.BackgroundColor3 = Theme.CardHover
    sliderTrack.BorderSizePixel = 0
    sliderTrack.ZIndex = 6
    sliderTrack.Parent = container

    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent = sliderTrack

    local fill = Instance.new("Frame")
    fill.BackgroundColor3 = Theme.Accent
    fill.BorderSizePixel = 0
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.ZIndex = 7
    fill.Parent = sliderTrack

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = fill
    registerStatic(fill, "BackgroundColor3")

    local knob = Instance.new("Frame")
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = UDim2.new(0, 0, 0.5, 0)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.ZIndex = 8
    knob.Parent = sliderTrack

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob

    local currentValue = default
    local dragging = false

    local function formatValue(val)
        if formatFunc then return formatFunc(val) end
        return tostring(val) .. suffix
    end

    local function alphaFromValue(value)
        if max == min then return 0 end
        return math.clamp((value - min) / (max - min), 0, 1)
    end

    local function setFromAlpha(alpha, fireCallback)
        alpha = math.clamp(alpha, 0, 1)
        currentValue = math.floor(min + (max - min) * alpha + 0.5)
        fill.Size = UDim2.new(alpha, 0, 1, 0)
        knob.Position = UDim2.new(alpha, 0, 0.5, 0)
        valueLabel.Text = formatValue(currentValue)
        if fireCallback and callback then
            task.spawn(callback, currentValue)
        end
    end

    setFromAlpha(alphaFromValue(default), false)

    local function updateFromInput(input)
        local alpha = math.clamp(
            (input.Position.X - sliderTrack.AbsolutePosition.X) / sliderTrack.AbsoluteSize.X,
            0, 1
        )
        setFromAlpha(alpha, true)
    end

    local function beginDrag(input)
        dragging = true
        updateFromInput(input)
    end

    track(knob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            beginDrag(input)
        end
    end))
    track(sliderTrack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            beginDrag(input)
        end
    end))
    track(UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            updateFromInput(input)
        end
    end))
    track(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))

    return {
        Instance = container,
        SetValue = function(value) setFromAlpha(alphaFromValue(value), false) end,
        GetValue = function() return currentValue end,
    }
end

-- 11.4 CreateKeybindButton (Улучшение 1: сохранение в конфиг)
local function CreateKeybindButton(parent, name, defaultKey, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -10, 0, 38)
    container.BackgroundColor3 = Theme.Card
    container.BorderSizePixel = 0
    container.ZIndex = 5
    container.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = container

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 10, 0, 0)
    label.Size = UDim2.new(1, -110, 1, 0)
    label.Font = Enum.Font.Gotham
    label.Text = name
    label.TextColor3 = Theme.TextPrimary
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 6
    label.Parent = container

    local keyButton = Instance.new("TextButton")
    keyButton.Size = UDim2.new(0, 90, 0, 26)
    keyButton.Position = UDim2.new(1, -100, 0.5, -13)
    keyButton.BackgroundColor3 = Theme.CardHover
    keyButton.BorderSizePixel = 0
    keyButton.Font = Enum.Font.GothamBold
    keyButton.TextColor3 = Theme.TextPrimary
    keyButton.TextSize = 12
    keyButton.ZIndex = 6
    keyButton.Parent = container

    local keyCorner = Instance.new("UICorner")
    keyCorner.CornerRadius = UDim.new(0, 6)
    keyCorner.Parent = keyButton

    local currentKey = nil
    local listening = false

    -- Улучшение 1: Загрузка сохранённой клавиши из конфига
    local savedKeyName = Config.Get("Keybind_" .. name, defaultKey and defaultKey.Name or nil)
    if savedKeyName then
        local savedKey = Enum.KeyCode[savedKeyName]
        if savedKey then
            defaultKey = savedKey
        end
    end

    local function registerKey(keyCode)
        if currentKey and KeybindRegistry[currentKey] and KeybindRegistry[currentKey].name == name then
            KeybindRegistry[currentKey] = nil
        end
        currentKey = keyCode
        if keyCode then
            KeybindRegistry[keyCode] = {name = name, callback = callback}
            -- Улучшение 1: Сохранение в конфиг
            Config.Set("Keybind_" .. name, keyCode.Name)
            Config.SaveConfig()
        end
        keyButton.Text = keyCode and keyCode.Name or "None"
    end

    registerKey(defaultKey)

    local function startListening()
        if listening then return end
        listening = true
        UILib.IsCapturingKeybind = true
        keyButton.Text = "..."

        local inputConn
        local timeoutTask

        local function stopListening(newKey)
            listening = false
            UILib.IsCapturingKeybind = false
            if inputConn then inputConn:Disconnect() end
            if timeoutTask then task.cancel(timeoutTask) end
            if newKey then
                registerKey(newKey)
            else
                keyButton.Text = currentKey and currentKey.Name or "None"
            end
        end

        inputConn = UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
            if input.KeyCode == Enum.KeyCode.Escape then
                stopListening(nil)
            else
                stopListening(input.KeyCode)
            end
        end)

        timeoutTask = task.delay(6, function()
            stopListening(nil)
        end)
    end

    track(keyButton.MouseButton1Click:Connect(function()
        playClick()
        startListening()
    end))

    return {
        Instance = container,
        GetKey = function() return currentKey end,
    }
end

-- 11.5 CreatePopupMenu (Улучшение 8: высокий ZIndex)
local function CreatePopupMenu(title, width, height)
    local menu = Instance.new("Frame")
    menu.AnchorPoint = Vector2.new(0.5, 0.5)
    menu.Position = UDim2.new(0.5, 0, 0.5, 0)
    menu.Size = UDim2.new(0, width, 0, height)
    menu.BackgroundColor3 = Theme.Background
    menu.BorderSizePixel = 0
    menu.Active = true
    menu.ZIndex = 100 -- Улучшение 8: очень высокий ZIndex
    menu.Visible = false
    menu.Parent = ScreenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = menu

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1.5
    stroke.Color = Theme.Border
    stroke.Parent = menu

    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 36)
    header.BackgroundColor3 = Theme.Card
    header.BorderSizePixel = 0
    header.ZIndex = 101
    header.Parent = menu

    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 10)
    headerCorner.Parent = header

    local headerMask = Instance.new("Frame")
    headerMask.BackgroundColor3 = Theme.Card
    headerMask.BorderSizePixel = 0
    headerMask.Position = UDim2.new(0, 0, 1, -10)
    headerMask.Size = UDim2.new(1, 0, 0, 10)
    headerMask.ZIndex = 101
    headerMask.Parent = header

    local titleLabel = Instance.new("TextLabel")
    titleLabel.BackgroundTransparency = 1
    titleLabel.Position = UDim2.new(0, 12, 0, 0)
    titleLabel.Size = UDim2.new(1, -50, 1, 0)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Text = title
    titleLabel.TextColor3 = Theme.TextPrimary
    titleLabel.TextSize = 14
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.ZIndex = 102
    titleLabel.Parent = header

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 24, 0, 24)
    closeBtn.Position = UDim2.new(1, -32, 0.5, -12)
    closeBtn.BackgroundColor3 = Theme.CardHover
    closeBtn.Text = "×"
    closeBtn.TextColor3 = Theme.TextSecondary
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 16
    closeBtn.BorderSizePixel = 0
    closeBtn.ZIndex = 102
    closeBtn.Parent = header

    local closeBtnCorner = Instance.new("UICorner")
    closeBtnCorner.CornerRadius = UDim.new(0, 6)
    closeBtnCorner.Parent = closeBtn

    track(closeBtn.MouseButton1Click:Connect(function()
        playClick()
        menu.Visible = false
    end))

    local content = Instance.new("Frame")
    content.Position = UDim2.new(0, 10, 0, 44)
    content.Size = UDim2.new(1, -20, 1, -54)
    content.BackgroundTransparency = 1
    content.ZIndex = 101
    content.Parent = menu

    local contentLayout = Instance.new("UIListLayout")
    contentLayout.FillDirection = Enum.FillDirection.Vertical
    contentLayout.Padding = UDim.new(0, 8)
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Parent = content

    makeDraggable(header, menu)

    return menu, content
end

-- 11.6 CreateDropdown (Улучшение 2: новый элемент)
local function CreateDropdown(parent, title, options, default, callback, layoutOrder)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -10, 0, 38)
    container.BackgroundColor3 = Theme.Card
    container.BorderSizePixel = 0
    container.ZIndex = 5
    container.LayoutOrder = layoutOrder or 0
    container.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = container

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 10, 0, 0)
    label.Size = UDim2.new(1, -120, 1, 0)
    label.Font = Enum.Font.Gotham
    label.Text = title
    label.TextColor3 = Theme.TextPrimary
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 6
    label.Parent = container

    local dropdownBtn = Instance.new("TextButton")
    dropdownBtn.Size = UDim2.new(0, 100, 0, 26)
    dropdownBtn.Position = UDim2.new(1, -110, 0.5, -13)
    dropdownBtn.BackgroundColor3 = Theme.CardHover
    dropdownBtn.BorderSizePixel = 0
    dropdownBtn.Font = Enum.Font.GothamBold
    dropdownBtn.Text = default or options[1] or "Select"
    dropdownBtn.TextColor3 = Theme.TextPrimary
    dropdownBtn.TextSize = 12
    dropdownBtn.ZIndex = 6
    dropdownBtn.Parent = container

    local ddCorner = Instance.new("UICorner")
    ddCorner.CornerRadius = UDim.new(0, 6)
    ddCorner.Parent = dropdownBtn

    local isOpen = false
    local currentValue = default or options[1]

    local dropdownList = Instance.new("Frame")
    dropdownList.Size = UDim2.new(0, 100, 0, 0)
    dropdownList.Position = UDim2.new(1, -110, 0, 30)
    dropdownList.BackgroundColor3 = Theme.Background
    dropdownList.BorderSizePixel = 0
    dropdownList.Visible = false
    dropdownList.ZIndex = 7
    dropdownList.Parent = container

    local ddListCorner = Instance.new("UICorner")
    ddListCorner.CornerRadius = UDim.new(0, 6)
    ddListCorner.Parent = dropdownList

    local ddListLayout = Instance.new("UIListLayout")
    ddListLayout.Padding = UDim.new(0, 2)
    ddListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ddListLayout.Parent = dropdownList

    local ddListPadding = Instance.new("UIPadding")
    ddListPadding.PaddingTop = UDim.new(0, 4)
    ddListPadding.PaddingBottom = UDim.new(0, 4)
    ddListPadding.PaddingLeft = UDim.new(0, 4)
    ddListPadding.PaddingRight = UDim.new(0, 4)
    ddListPadding.Parent = dropdownList

    local function toggleDropdown(open)
        isOpen = open
        dropdownList.Visible = open
        if open then
            dropdownList.Size = UDim2.new(0, 100, 0, 0)
            tween(dropdownList, {Size = UDim2.new(0, 100, 0, #options * 28 + 8)}, 0.2)
        else
            tween(dropdownList, {Size = UDim2.new(0, 100, 0, 0)}, 0.2)
            task.delay(0.2, function()
                if not isOpen then dropdownList.Visible = false end
            end)
        end
    end

    local function selectOption(option)
        currentValue = option
        dropdownBtn.Text = option
        toggleDropdown(false)
        if callback then task.spawn(callback, option) end
    end

    for i, option in ipairs(options) do
        local optionBtn = Instance.new("TextButton")
        optionBtn.Size = UDim2.new(1, 0, 0, 24)
        optionBtn.BackgroundColor3 = Theme.Card
        optionBtn.BorderSizePixel = 0
        optionBtn.Font = Enum.Font.Gotham
        optionBtn.Text = option
        optionBtn.TextColor3 = Theme.TextPrimary
        optionBtn.TextSize = 12
        optionBtn.LayoutOrder = i
        optionBtn.ZIndex = 8
        optionBtn.Parent = dropdownList

        local optCorner = Instance.new("UICorner")
        optCorner.CornerRadius = UDim.new(0, 4)
        optCorner.Parent = optionBtn

        track(optionBtn.MouseEnter:Connect(function()
            tween(optionBtn, {BackgroundColor3 = Theme.CardHover}, 0.15)
        end))
        track(optionBtn.MouseLeave:Connect(function()
            tween(optionBtn, {BackgroundColor3 = Theme.Card}, 0.15)
        end))
        track(optionBtn.MouseButton1Click:Connect(function()
            playClick()
            selectOption(option)
        end))
    end

    track(dropdownBtn.MouseButton1Click:Connect(function()
        playClick()
        toggleDropdown(not isOpen)
    end))

    return {
        Instance = container,
        GetValue = function() return currentValue end,
        SetValue = function(val) selectOption(val) end,
    }
end

-- 11.7 CreateTextBox (Улучшение 2: новый элемент)
local function CreateTextBox(parent, title, placeholder, defaultText, callback, layoutOrder)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -10, 0, 38)
    container.BackgroundColor3 = Theme.Card
    container.BorderSizePixel = 0
    container.ZIndex = 5
    container.LayoutOrder = layoutOrder or 0
    container.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = container

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 10, 0, 0)
    label.Size = UDim2.new(0, 80, 1, 0)
    label.Font = Enum.Font.Gotham
    label.Text = title
    label.TextColor3 = Theme.TextPrimary
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 6
    label.Parent = container

    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(1, -100, 0, 26)
    textBox.Position = UDim2.new(0, 95, 0.5, -13)
    textBox.BackgroundColor3 = Theme.CardHover
    textBox.BorderSizePixel = 0
   textBox.Font = Enum.Font.Gotham
    textBox.Text = defaultText or ""
    textBox.PlaceholderText = placeholder or ""
    textBox.PlaceholderColor3 = Theme.TextSecondary
    textBox.TextColor3 = Theme.TextPrimary
    textBox.TextSize = 12
    textBox.ClearTextOnFocus = false
    textBox.ZIndex = 6
    textBox.Parent = container

    local tbCorner = Instance.new("UICorner")
    tbCorner.CornerRadius = UDim.new(0, 6)
    tbCorner.Parent = textBox

    track(textBox.FocusLost:Connect(function()
        if callback then task.spawn(callback, textBox.Text) end
    end))

    return {
        Instance = container,
        GetValue = function() return textBox.Text end,
        SetValue = function(val) textBox.Text = val end,
    }
end

-- 11.8 CreateLabel (Улучшение 2: новый элемент)
local function CreateLabel(parent, text, layoutOrder)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -10, 0, 20)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.Text = text
    label.TextColor3 = Theme.TextSecondary
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 5
    label.LayoutOrder = layoutOrder or 0
    label.Parent = parent
    return label
end

-- 11.9 CreateDivider (Улучшение 7: разделитель)
local function CreateDivider(parent, text, layoutOrder)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -10, 0, 20)
    container.BackgroundTransparency = 1
    container.LayoutOrder = layoutOrder or 0
    container.ZIndex = 5
    container.Parent = parent

    local line = Instance.new("Frame")
    line.Size = UDim2.new(1, 0, 0, 1)
    line.Position = UDim2.new(0, 0, 0.5, 0)
    line.BackgroundColor3 = Theme.Border
    line.BorderSizePixel = 0
    line.ZIndex = 6
    line.Parent = container

    if text and text ~= "" then
        local label = Instance.new("TextLabel")
        label.BackgroundTransparency = 1
        label.Position = UDim2.new(0, 10, 0, 0)
        label.Size = UDim2.new(0, 100, 1, 0)
        label.Font = Enum.Font.GothamBold
        label.Text = text
        label.TextColor3 = Theme.TextSecondary
        label.TextSize = 11
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.ZIndex = 7
        label.Parent = container

        local mask = Instance.new("Frame")
        mask.Size = UDim2.new(0, 6, 0, 1)
        mask.Position = UDim2.new(0, 4, 0.5, 0)
        mask.BackgroundColor3 = Theme.Card
        mask.BorderSizePixel = 0
        mask.ZIndex = 7
        mask.Parent = container
    end

    return container
end

--============================================================
-- 12. УВЕДОМЛЕНИЯ (Улучшения 3 и 9)
--============================================================
local NotificationHolder = Instance.new("Frame")
NotificationHolder.AnchorPoint = Vector2.new(1, 0)
NotificationHolder.Position = UDim2.new(1, -20, 0, 20)
NotificationHolder.Size = UDim2.new(0, 260, 0, 0)
NotificationHolder.AutomaticSize = Enum.AutomaticSize.Y
NotificationHolder.BackgroundTransparency = 1
NotificationHolder.ZIndex = 15
NotificationHolder.Parent = ScreenGui

local NotificationLayout = Instance.new("UIListLayout")
NotificationLayout.FillDirection = Enum.FillDirection.Vertical
NotificationLayout.Padding = UDim.new(0, 8)
NotificationLayout.SortOrder = Enum.SortOrder.LayoutOrder
NotificationLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
NotificationLayout.Parent = NotificationHolder

local NotificationColors = {
    success = Theme.Success,
    warning = Theme.Warning,
    error   = Theme.Error,
    info    = Theme.Info,
}

local activeNotifications = {} -- Улучшение 9: трекинг уведомлений
local MAX_NOTIFICATIONS = 3    -- Улучшение 9: лимит

local function Notify(options)
    options = options or {}
    local color = NotificationColors[options.type] or Theme.Info
    local duration = options.duration or 4

    -- Улучшение 9: удаление старых при превышении лимита
    if #activeNotifications >= MAX_NOTIFICATIONS then
        local oldest = table.remove(activeNotifications, 1)
        if oldest and oldest.Parent then
            local hideTween = tween(oldest, {Position = UDim2.new(1, 40, 0, 0)}, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
            hideTween.Completed:Wait()
            oldest:Destroy()
        end
    end

    local notif = Instance.new("Frame")
    notif.Size = UDim2.new(1, 0, 0, 64)
    notif.BackgroundColor3 = Theme.Card
    notif.BorderSizePixel = 0
    notif.ZIndex = 15
    notif.ClipsDescendants = true
    notif.Parent = NotificationHolder

    table.insert(activeNotifications, notif)

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = notif

    local icon = Instance.new("Frame")
    icon.Size = UDim2.new(0, 4, 1, 0)
    icon.BackgroundColor3 = color
    icon.BorderSizePixel = 0
    icon.ZIndex = 16
    icon.Parent = notif

    local titleLabel = Instance.new("TextLabel")
    titleLabel.BackgroundTransparency = 1
    titleLabel.Position = UDim2.new(0, 14, 0, 8)
    titleLabel.Size = UDim2.new(1, -24, 0, 18)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Text = options.title or "Notification"
    titleLabel.TextColor3 = Theme.TextPrimary
    titleLabel.TextSize = 13
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.ZIndex = 16
    titleLabel.Parent = notif

    local textLabel = Instance.new("TextLabel")
    textLabel.BackgroundTransparency = 1
    textLabel.Position = UDim2.new(0, 14, 0, 26)
    textLabel.Size = UDim2.new(1, -24, 0, 26)
    textLabel.Font = Enum.Font.Gotham
    textLabel.Text = options.text or ""
    textLabel.TextColor3 = Theme.TextSecondary
    textLabel.TextSize = 12
    textLabel.TextWrapped = true
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.TextYAlignment = Enum.TextYAlignment.Top
    textLabel.ZIndex = 16
    textLabel.Parent = notif

    local progress = Instance.new("Frame")
    progress.Position = UDim2.new(0, 0, 1, -3)
    progress.Size = UDim2.new(1, 0, 0, 3)
    progress.BackgroundColor3 = color
    progress.BorderSizePixel = 0
    progress.ZIndex = 16
    progress.Parent = notif

    notif.Position = UDim2.new(1, 40, 0, 0)
    tween(notif, {Position = UDim2.new(0, 0, 0, 0)}, 0.3)
    tween(progress, {Size = UDim2.new(0, 0, 0, 3)}, duration, Enum.EasingStyle.Linear)

    -- Улучшение 3: интерактивность — клик для закрытия
    notif.Active = true
    track(notif.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            -- Мгновенное закрытие
            for i, n in ipairs(activeNotifications) do
                if n == notif then
                    table.remove(activeNotifications, i)
                    break
                end
            end
            local hideTween = tween(notif, {Position = UDim2.new(1, 40, 0, 0)}, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
            hideTween.Completed:Wait()
            notif:Destroy()
        end
    end))

    task.delay(duration, function()
        if not notif.Parent then return end
        -- Удаляем из трекинга
        for i, n in ipairs(activeNotifications) do
            if n == notif then
                table.remove(activeNotifications, i)
                break
            end
        end
        local hideTween = tween(notif, {Position = UDim2.new(1, 40, 0, 0)}, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        hideTween.Completed:Wait()
        notif:Destroy()
    end)
end

--============================================================
-- 13. ПЛАВАЮЩАЯ КНОПКА
--============================================================
local FloatingButton = Instance.new("TextButton")
FloatingButton.Size = UDim2.new(0, 46, 0, 46)
FloatingButton.Position = UDim2.new(0, 20, 0, 20)
FloatingButton.BackgroundColor3 = Theme.Accent
FloatingButton.BorderSizePixel = 0
FloatingButton.Text = "="
FloatingButton.TextColor3 = Color3.fromRGB(255, 255, 255)
FloatingButton.TextSize = 20
FloatingButton.Font = Enum.Font.GothamBold
FloatingButton.ZIndex = 10
FloatingButton.Visible = false
FloatingButton.Parent = ScreenGui

local floatCorner = Instance.new("UICorner")
floatCorner.CornerRadius = UDim.new(1, 0)
floatCorner.Parent = FloatingButton
registerStatic(FloatingButton, "BackgroundColor3")

makeDraggable(FloatingButton, FloatingButton)

local uiVisible = true

local function setUIVisible(visible)
    uiVisible = visible
    MainFrame.Visible = visible
    FloatingButton.Visible = not visible
end

track(CloseButton.MouseButton1Click:Connect(function()
    playClick()
    setUIVisible(false)
end))

track(FloatingButton.MouseButton1Click:Connect(function()
    playClick()
    setUIVisible(true)
end))

track(UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    if UILib.IsCapturingKeybind then return end

    if input.KeyCode == Enum.KeyCode.RightControl then
        setUIVisible(not uiVisible)
        return
    end

    local entry = KeybindRegistry[input.KeyCode]
    if entry and entry.callback then
        task.spawn(entry.callback)
    end
end))

--============================================================
-- 14. СБОРКА
--============================================================
local GeneralPage = createTab("General", 1)
local ModulesPage = createTab("Modules", 2)
local NetworkPage = createTab("Network", 3)
local SettingsPage = createTab("Settings", 4)

local ToolsMenu, ToolsContent = CreatePopupMenu("Tools", 320, 260)
local FiltersMenu, FiltersContent = CreatePopupMenu("Filters", 320, 260)

-- General: демонстрация всех элементов
CreateLabel(GeneralPage, "Basic Elements", 1)
CreateDivider(GeneralPage, "Toggles & Buttons", 2)

CreateToggle(GeneralPage, {
    title = "Example Toggle",
    cfgKey = "exampleToggle",
    layoutOrder = 3,
    callback = function(state)
        Notify({title = "Toggle", text = "State: " .. tostring(state), type = state and "success" or "info"})
    end,
})

CreateButton(GeneralPage, {
    title = "Example Button",
    layoutOrder = 4,
    callback = function()
        Notify({title = "Button", text = "Clicked!", type = "info"})
    end,
})

-- Улучшение 4: Slider с суффиксом
CreateSlider(GeneralPage, "Example Slider", 0, 100, 50, function(value) end, 5,
    { suffix = " px" }
)

CreateKeybindButton(GeneralPage, "Example Keybind", Enum.KeyCode.F, function()
    Notify({title = "Keybind", text = "Key pressed!", type = "info"})
end, 6)

-- Улучшение 2: новые элементы
CreateLabel(GeneralPage, "Input Elements", 7)
CreateDivider(GeneralPage, "Dropdown & Text", 8)

CreateDropdown(GeneralPage, "Select Option", {"Option A", "Option B", "Option C"}, "Option A", function(val)
    Notify({title = "Dropdown", text = "Selected: " .. val, type = "info"})
end, 9)

CreateTextBox(GeneralPage, "Enter Name:", "Type here...", "", function(text)
    Notify({title = "TextBox", text = "Entered: " .. text, type = "info"})
end, 10)

-- Modules: popup вызов
CreateButton(ModulesPage, {
    title = "Open Tools",
    layoutOrder = 1,
    callback = function() ToolsMenu.Visible = true end,
})

CreateButton(NetworkPage, {
    title = "Open Filters",
    layoutOrder = 1,
    callback = function() FiltersMenu.Visible = true end,
})

-- Settings: accent + autosave
local presetsContainer = Instance.new("Frame")
presetsContainer.Size = UDim2.new(1, -10, 0, 40)
presetsContainer.BackgroundTransparency = 1
presetsContainer.LayoutOrder = 1
presetsContainer.ZIndex = 5
presetsContainer.Parent = SettingsPage

local presetsLayout = Instance.new("UIListLayout")
presetsLayout.FillDirection = Enum.FillDirection.Horizontal
presetsLayout.Padding = UDim.new(0, 6)
presetsLayout.Parent = presetsContainer

local selectedPresetStroke = nil
for i, color in ipairs(AccentPresets) do
    local presetBtn = Instance.new("TextButton")
    presetBtn.Size = UDim2.new(0, 28, 0, 28)
    presetBtn.BackgroundColor3 = color
    presetBtn.Text = ""
    presetBtn.BorderSizePixel = 0
    presetBtn.LayoutOrder = i
    presetBtn.ZIndex = 5
    presetBtn.Parent = presetsContainer

    local pCorner = Instance.new("UICorner")
    pCorner.CornerRadius = UDim.new(0, 6)
    pCorner.Parent = presetBtn

    local pStroke = Instance.new("UIStroke")
    pStroke.Thickness = 2
    pStroke.Color = Color3.fromRGB(255, 255, 255)
    pStroke.Transparency = (i == 1) and 0 or 1
    pStroke.Parent = presetBtn

    if i == 1 then selectedPresetStroke = pStroke end

    track(presetBtn.MouseButton1Click:Connect(function()
        playClick()
        if selectedPresetStroke then
            selectedPresetStroke.Transparency = 1
        end
        pStroke.Transparency = 0
        selectedPresetStroke = pStroke
        SetAccent(color)
    end))
end

CreateToggle(SettingsPage, {
    title = "Auto Save Config",
    default = true,
    layoutOrder = 2,
    callback = function(state)
        Config.SaveConfigEnabled = state
    end,
})

selectTab("General")

-- Анимация появления
tween(MainFrame, {Size = UDim2.new(0, 440, 0, 340)}, 0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

--============================================================
-- 15. API
--============================================================
UILib.ScreenGui = ScreenGui
UILib.MainFrame = MainFrame
UILib.Config = Config
UILib.CreateToggle = CreateToggle
UILib.CreateButton = CreateButton
UILib.CreateSlider = CreateSlider
UILib.CreateKeybindButton = CreateKeybindButton
UILib.CreatePopupMenu = CreatePopupMenu
UILib.CreateDropdown = CreateDropdown
UILib.CreateTextBox = CreateTextBox
UILib.CreateLabel = CreateLabel
UILib.CreateDivider = CreateDivider
UILib.CreateTab = createTab
UILib.SelectTab = selectTab
UILib.Notify = Notify
UILib.SetAccent = SetAccent
UILib.Pages = {General = GeneralPage, Modules = ModulesPage, Network = NetworkPage, Settings = SettingsPage}
UILib.Popups = {Tools = ToolsMenu, Filters = FiltersMenu}

_G.UILib = UILib

return UILib
