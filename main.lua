--=========================================================
--  SSS HUB — Unified (Roblox, Luau)
--  Исправлено: убран CanvasGroup для совместимости
--=========================================================

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local TeleportService  = game:GetService("TeleportService")
local HttpService      = game:GetService("HttpService")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local Workspace        = game:GetService("Workspace")
local VirtualUser      = game:GetService("VirtualUser")

local LP = Players.LocalPlayer or Players.PlayerAdded:Wait()

local SafeAPI = {
    isfile   = typeof(isfile)   == "function" and isfile   or function() return false end,
    readfile = typeof(readfile) == "function" and readfile or function() return "" end,
    writefile= typeof(writefile)== "function" and writefile or function() end,
    HttpGet  = typeof(game.HttpGet) == "function" and function(url) return game:HttpGet(url) end or function() return "" end,
    setclip  = typeof(setclipboard) == "function" and setclipboard or function() end,
    firetouch= typeof(firetouchinterest) == "function" and firetouchinterest or function() end,
}

local C = {
    BG     = Color3.fromRGB(9, 10, 16),
    CARD   = Color3.fromRGB(16, 19, 30),
    HOVER  = Color3.fromRGB(23, 27, 42),
    TEXT   = Color3.fromRGB(240, 242, 248),
    SUB    = Color3.fromRGB(148, 153, 170),
    ACC1   = Color3.fromRGB(64, 118, 255),
    ACC2   = Color3.fromRGB(158, 77, 255),
    GRAY   = Color3.fromRGB(56, 60, 76),
    GREEN  = Color3.fromRGB(46, 204, 113),
    BLUE   = Color3.fromRGB(52, 152, 219),
    YELLOW = Color3.fromRGB(243, 186, 47),
    RED    = Color3.fromRGB(235, 87, 87),
    TEAL   = Color3.fromRGB(29, 209, 161),
    PINK   = Color3.fromRGB(232, 62, 140),
}

local ConfigFile = "SSSHubConfig.json"
local JobsFile   = "SSSHubJobs.json"
local Config     = {}

local function LoadJSON(path)
    if not SafeAPI.isfile(path) then return nil end
    local ok, txt = pcall(SafeAPI.readfile, path)
    if not ok then return nil end
    local ok2, data = pcall(HttpService.JSONDecode, HttpService, txt)
    if ok2 and type(data) == "table" then return data end
    return nil
end

local function SaveJSON(path, data)
    if not SafeAPI.writefile then return end
    pcall(SafeAPI.writefile, path, HttpService:JSONEncode(data))
end

Config = LoadJSON(ConfigFile) or {}
local Keybinds = Config.Keybinds or {}

local function SaveConfig()
    Config.Keybinds = Keybinds
    SaveJSON(ConfigFile, Config)
end

if Config.AccentColor then
    local c = Config.AccentColor
    C.ACC1 = Color3.fromRGB(c[1], c[2], c[3])
end

local State = {
    AutoRun      = Config.AutoRun      or false,
    ESP          = Config.ESP          or false,
    PetsESP      = Config.PetsESP      or false,
    AntiKnockback= Config.AntiKnockback or false,
    AntiFall     = Config.AntiFall     or false,
    AntiAFK      = Config.AntiAFK      ~= false,
    AutoLock     = Config.AutoLock     or false,
    WallHop      = Config.WallHop      or false,
    SaveConfig   = Config.SaveConfig   ~= false,
}
local SavedJobs = LoadJSON(JobsFile) or {}

local function new(cls, props, parent)
    local o = Instance.new(cls)
    for k,v in pairs(props) do o[k] = v end
    o.Parent = parent
    return o
end

local function tw(obj, t, props, style, dir)
    local tr = TweenService:Create(obj, TweenInfo.new(t,
        style or Enum.EasingStyle.Quart,
        dir   or Enum.EasingDirection.Out), props)
    tr:Play()
    return tr
end

local function corner(p, r) return new("UICorner", {CornerRadius=UDim.new(0,r), Parent=p}) end
local function grad(p, c1, c2, rot)
    return new("UIGradient", {Parent=p, Color=ColorSequence.new(c1,c2), Rotation=rot or 0})
end

local gui = new("ScreenGui", {Name="SSSHub", IgnoreGuiInset=true,
    ZIndexBehavior=Enum.ZIndexBehavior.Sibling, ResetOnSpawn=false})
pcall(function() gui.Parent = game:GetService("CoreGui") end)
if not gui.Parent then gui.Parent = LP:WaitForChild("PlayerGui") end

local notifHolder = new("Frame", {BackgroundTransparency=1,
    Position=UDim2.new(1,-316,0,14), Size=UDim2.new(0,302,1,-28), Parent=gui})
new("UIListLayout", {Padding=UDim.new(0,10), Parent=notifHolder})

local KIND = {
    Success = {c=C.GREEN,  i="✔"},
    Info    = {c=C.BLUE,   i="i"},
    Warning = {c=C.YELLOW, i="!"},
    Error   = {c=C.RED,    i="✖"},
}

local function notify(kind, title, text, duration)
    duration = duration or 4
    local k = KIND[kind] or KIND.Info
    local n = new("Frame", {Size=UDim2.new(1,0,0,78), BackgroundTransparency=1, Parent=notifHolder})
    local card = new("Frame", {Size=UDim2.new(1,0,1,0), Position=UDim2.new(0,340,0,0),
        BackgroundColor3=C.CARD, Parent=n})
    corner(card, 12)
    local st = new("UIStroke", {Parent=card, Thickness=1.2, Transparency=.25, Color=k.c})

    local stripe = new("Frame", {Size=UDim2.new(0,4,1,-24), Position=UDim2.new(0,0,0,12),
        BackgroundColor3=k.c, Parent=card})
    corner(stripe, 2)

    local bub = new("Frame", {Size=UDim2.new(0,38,0,38), Position=UDim2.new(0,14,.5,0),
        AnchorPoint=Vector2.new(0,.5), BackgroundColor3=k.c, BackgroundTransparency=.82, Parent=card})
    corner(bub, 19)
    new("TextLabel", {Text=k.i, TextColor3=k.c, TextSize=17, Font=Enum.Font.GothamBold,
        BackgroundTransparency=1, Size=UDim2.new(1,0,1,0), Parent=bub})

    new("TextLabel", {Text=title, TextColor3=C.TEXT, TextSize=15, Font=Enum.Font.GothamBold,
        BackgroundTransparency=1, Position=UDim2.new(0,62,0,12), Size=UDim2.new(1,-100,0,20),
        TextXAlignment=Enum.TextXAlignment.Left, Parent=card})
    new("TextLabel", {Text=text, TextColor3=C.SUB, TextSize=13, Font=Enum.Font.Gotham,
        BackgroundTransparency=1, Position=UDim2.new(0,62,0,36), Size=UDim2.new(1,-76,0,30),
        TextXAlignment=Enum.TextXAlignment.Left, TextYAlignment=Enum.TextYAlignment.Top,
        TextWrapped=true, Parent=card})

    local close = new("TextButton", {Text="✕", TextColor3=C.SUB, TextSize=14, AutoButtonColor=false,
        Font=Enum.Font.GothamBold, BackgroundTransparency=1, Size=UDim2.new(0,24,0,24),
        Position=UDim2.new(1,-28,0,10), Parent=card})
    close.Activated:Connect(function()
        tw(card, .35, {Position=UDim2.new(0,340,0,0)}, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        task.delay(.35, function() n:Destroy() end)
    end)

    local prog = new("Frame", {Size=UDim2.new(1,-24,0,3), Position=UDim2.new(0,12,1,-8),
        BackgroundColor3=k.c, Parent=card})
    corner(prog, 2)
    tw(prog, duration, {Size=UDim2.new(0,0,0,3)}, Enum.EasingStyle.Linear)

    tw(card, .45, {Position=UDim2.new(0,0,0,0)}, Enum.EasingStyle.Back)
    task.delay(duration, function() if n.Parent then
        tw(card, .35, {Position=UDim2.new(0,340,0,0)}, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        task.delay(.35, function() n:Destroy() end)
    end end)
end

local main = new("Frame", {AnchorPoint=Vector2.new(.5,.5), Position=UDim2.new(.5,0,.5,0),
    Size=UDim2.new(0,430,0,640), BackgroundColor3=C.BG, ClipsDescendants=true, BackgroundTransparency=1})
main.Parent = gui
corner(main, 18)
local winStroke = new("UIStroke", {Parent=main, Thickness=1.4, Transparency=.45})
grad(winStroke, C.ACC1, C.ACC2, 90)
local scale = new("UIScale", {Scale=.92, Parent=main})

-- АВТО-МАСШТАБ ПОД ЭКРАН ТЕЛЕФОНА
local function updateScale()
    local cam = workspace.CurrentCamera
    if not cam then return end
    local s = math.min(cam.ViewportSize.X / 480, cam.ViewportSize.Y / 690)
    s = math.clamp(s, 0.5, 1.2)
    tw(scale, .2, {Scale = s})
end
updateScale()
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    if workspace.CurrentCamera then
        workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
    end
    updateScale()
end)
if workspace.CurrentCamera then
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
end

local header = new("TextButton", {Text="", BackgroundColor3=C.BG, BorderSizePixel=0,
    Size=UDim2.new(1,0,0,64), Parent=main, AutoButtonColor=false})
local logo = new("TextLabel", {Text="SS", TextSize=26, Font=Enum.Font.GothamBlack,
    BackgroundTransparency=1, Position=UDim2.new(0,16,0,12), Size=UDim2.new(0,44,0,40), Parent=header})
grad(logo, C.ACC1, C.ACC2, 45)
new("TextLabel", {Text="SSS HUB", TextColor3=C.TEXT, TextSize=18, Font=Enum.Font.GothamBlack,
    BackgroundTransparency=1, Position=UDim2.new(0,66,0,10), Size=UDim2.new(0,240,0,24),
    TextXAlignment=Enum.TextXAlignment.Left, Parent=header})
new("TextLabel", {Text="GAME ENHANCEMENT", TextColor3=C.SUB, TextSize=11, Font=Enum.Font.Gotham,
    BackgroundTransparency=1, Position=UDim2.new(0,66,0,34), Size=UDim2.new(0,240,0,16),
    TextXAlignment=Enum.TextXAlignment.Left, Parent=header})

local minBtn = new("TextButton", {Text="—", TextColor3=C.SUB, TextSize=16, Font=Enum.Font.GothamBold,
    BackgroundColor3=C.CARD, Size=UDim2.new(0,36,0,30), Position=UDim2.new(1,-48,0,17),
    AutoButtonColor=false, Parent=header})
corner(minBtn, 8)
minBtn.MouseEnter:Connect(function() tw(minBtn,.15,{BackgroundColor3=C.HOVER}) end)
minBtn.MouseLeave:Connect(function() tw(minBtn,.15,{BackgroundColor3=C.CARD}) end)

local minimized = false
minBtn.Activated:Connect(function()
    minimized = not minimized
    tw(main, .45, {Size=UDim2.new(0,430,0, minimized and 64 or 640)}, Enum.EasingStyle.Back)
    minBtn.Text = minimized and "□" or "—"
end)

local dragStart, startPos
header.InputBegan:Connect(function(inp)
    if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
        dragStart, startPos = inp.Position, main.Position
        local conn; conn = inp.Changed:Connect(function()
            if inp.UserInputState == Enum.UserInputState.End then
                dragStart = nil; conn:Disconnect()
            end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(inp)
    if dragStart and (inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch) then
        local d = inp.Position - dragStart
        main.Position = startPos + UDim2.new(0,d.X,0,d.Y)
    end
end)

local tabBar = new("Frame", {BackgroundTransparency=1, Position=UDim2.new(0,14,0,72),
    Size=UDim2.new(1,-28,0,44), Parent=main})
new("UIListLayout", {FillDirection=Enum.FillDirection.Horizontal, Padding=UDim.new(0,8), Parent=tabBar})
local indicator = new("Frame", {BackgroundColor3=C.ACC1, Parent=tabBar, ZIndex=0})
corner(indicator, 10)
grad(indicator, C.ACC1, C.ACC2, 35)

local pagesBox = new("Frame", {BackgroundTransparency=1, Position=UDim2.new(0,14,0,126),
    Size=UDim2.new(1,-28,1,-140), ClipsDescendants=true, Parent=main})

local tabs, pages = {}, {}
local function addTab(name)
    local btn = new("TextButton", {Text=name, Font=Enum.Font.GothamBold, TextSize=13,
        TextColor3=C.SUB, BackgroundTransparency=1, Size=UDim2.new(1/4,-6,1,0),
        AutoButtonColor=false, Parent=tabBar, ZIndex=1})
    local pg = new("Frame", {Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
        Visible=false, Parent=pagesBox})
    local sf = new("ScrollingFrame", {Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
        BorderSizePixel=0, ScrollBarThickness=0, Parent=pg})
    
    -- Сохраняем layout в переменную при создании!
    local layout = new("UIListLayout", {Padding=UDim.new(0,10), Parent=sf})
    new("UIPadding", {PaddingRight=UDim.new(0,2), Parent=sf})

    -- Используем сохранённую переменную
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        sf.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y+20)
    end)

    table.insert(tabs, btn); table.insert(pages, pg)
    return sf, btn
end

local function selectTab(i)
    for idx, btn in ipairs(tabs) do
        local active = idx==i
        tw(btn, .25, {TextColor3 = active and C.TEXT or C.SUB})
        if active then
            tw(indicator, .35, {Position=btn.Position, Size=btn.Size}, Enum.EasingStyle.Back)
        end
        local pg = pages[idx]
        if active then
            pg.Visible = true
        else
            pg.Visible = false
        end
    end
end

local function rowBase(parent, height)
    local row = new("Frame", {Size=UDim2.new(1,0,0,height or 62), BackgroundColor3=C.CARD,
        BorderSizePixel=0, Parent=parent})
    corner(row, 12)
    local hit = new("TextButton", {Text="", BackgroundTransparency=1, Size=UDim2.new(1,0,1,0),
        AutoButtonColor=false, Parent=row})
    hit.MouseEnter:Connect(function() tw(row,.15,{BackgroundColor3=C.HOVER}) end)
    hit.MouseLeave:Connect(function() tw(row,.15,{BackgroundColor3=C.CARD}) end)
    return row, hit
end

local function bubble(row, icon, color)
    local b = new("Frame", {Size=UDim2.new(0,40,0,40), Position=UDim2.new(0,11,.5,0),
        AnchorPoint=Vector2.new(0,.5), BackgroundColor3=color, BackgroundTransparency=.82, Parent=row})
    corner(b, 20)
    new("TextLabel", {Text=icon, TextColor3=color, TextSize=17, Font=Enum.Font.GothamBold,
        BackgroundTransparency=1, Size=UDim2.new(1,0,1,0), Parent=b})
end

local function title(row, text)
    new("TextLabel", {Text=text, TextColor3=C.TEXT, TextSize=14, Font=Enum.Font.GothamBold,
        BackgroundTransparency=1, Position=UDim2.new(0,64,0,0), Size=UDim2.new(1,-180,1,0),
        TextXAlignment=Enum.TextXAlignment.Left, Parent=row})
end

local KeybindRegistry = {}
local isListeningKeybind = false

local function RegisterKeybind(name, key, callback)
    KeybindRegistry[name] = {Key = key, Callback = callback}
end

UserInputService.InputBegan:Connect(function(inp, gp)
    if gp or isListeningKeybind then return end
    if inp.UserInputType ~= Enum.UserInputType.Keyboard then return end
    local k = inp.KeyCode.Name
    for _, bind in pairs(KeybindRegistry) do
        if bind.Key == k and bind.Callback then bind.Callback(); break end
    end
end)

local function addKeybindBtn(parent, name, defaultKey, action, xPos)
    local btn = new("TextButton", {
        Size = UDim2.new(0,34,0,18),
        Position = xPos or UDim2.new(1,-130,.5,-9),
        BackgroundColor3 = C.GRAY,
        Text = defaultKey or "-",
        TextColor3 = C.TEXT,
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false,
        Parent = parent
    })
    corner(btn, 4)
    local current = Keybinds[name] or defaultKey
    if current then RegisterKeybind(name, current, action) end
    btn.Text = current or "-"

    btn.Activated:Connect(function()
        if isListeningKeybind then return end
        isListeningKeybind = true
        btn.Text = "..."
        tw(btn, .1, {BackgroundColor3=C.ACC1})
        local conn
        conn = UserInputService.InputBegan:Connect(function(input, g)
            if g then return end
            if input.KeyCode == Enum.KeyCode.Escape then
                btn.Text = current or "-"
                tw(btn, .1, {BackgroundColor3=C.GRAY})
                isListeningKeybind = false; conn:Disconnect(); return
            end
            if input.UserInputType == Enum.UserInputType.Keyboard then
                current = input.KeyCode.Name
                Keybinds[name] = current; SaveConfig()
                RegisterKeybind(name, current, action)
                btn.Text = current; tw(btn, .1, {BackgroundColor3=C.GRAY})
                isListeningKeybind = false; conn:Disconnect()
                notify("Info", "Keybind", name.." → "..current, 3)
            end
        end)
    end)
    return btn
end

local AccentToggles = {}
local function setAccent(color)
    C.ACC1 = color
    Config.AccentColor = {math.floor(color.R * 255), math.floor(color.G * 255), math.floor(color.B * 255)}
    SaveConfig()
    grad(winStroke, C.ACC1, C.ACC2, 90)
    grad(logo, C.ACC1, C.ACC2, 45)
    grad(indicator, C.ACC1, C.ACC2, 35)
    for _, t in ipairs(AccentToggles) do
        if t.isOn then tw(t.track, .2, {BackgroundColor3=C.ACC1}) end
    end
end

local function addToggle(page, o)
    local row, hit = rowBase(page)
    bubble(row, o.icon, o.color); title(row, o.title)

    local status = new("TextLabel", {TextColor3=C.SUB, TextSize=12, Font=Enum.Font.GothamBold,
        BackgroundTransparency=1, Position=UDim2.new(1,-96,0,0),
        Size=UDim2.new(0,34,1,0), TextXAlignment=Enum.TextXAlignment.Right, Parent=row})

    local track = new("Frame", {Size=UDim2.new(0,46,0,26),
        Position=UDim2.new(1,-56,.5,0),
        AnchorPoint=Vector2.new(1,.5), BackgroundColor3=C.GRAY, Parent=row})
    corner(track, 13)
    local knob = new("Frame", {Size=UDim2.new(0,20,0,20), Position=UDim2.new(0,3,.5,0),
        AnchorPoint=Vector2.new(0,.5), BackgroundColor3=C.TEXT, Parent=track})
    corner(knob, 10)

    local on = false
    local tData = {track=track, isOn=false}
    table.insert(AccentToggles, tData)

    local function set(v, silent)
        on = v
        tData.isOn = v
        tw(knob, .3, {Position = v and UDim2.new(1,-23,.5,0) or UDim2.new(0,3,.5,0)}, Enum.EasingStyle.Back)
        tw(track, .3, {BackgroundColor3 = v and C.ACC1 or C.GRAY})
        status.Text = v and "ON" or "OFF"
        tw(status, .2, {TextColor3 = v and C.TEXT or C.SUB})
        if not silent and o.callback then o.callback(v) end
    end
    
    local function toggleAction()
        set(not on)
    end

    hit.Activated:Connect(toggleAction)

    local hasKb = o.keybind ~= nil
    if hasKb then
        addKeybindBtn(row, o.title, o.keybind, toggleAction, UDim2.new(1,-132,.5,-9))
    end

    set(o.default or false, true)
    return {Set=set, Get=function() return on end}
end

local function addButton(page, o)
    local row, hit = rowBase(page)
    bubble(row, o.icon, o.color); title(row, o.title)

    local chev = new("TextLabel", {Text="❯", TextColor3=C.SUB, TextSize=14, Font=Enum.Font.GothamBold,
        BackgroundTransparency=1, Position=UDim2.new(1,-34,0,0), Size=UDim2.new(0,20,1,0), Parent=row})

    if o.keybind then
        addKeybindBtn(row, o.title, o.keybind, function() if o.callback then o.callback() end end, UDim2.new(1,-70,.5,-9))
    end
    if o.accent then
        local s = new("UIStroke", {Parent=row, Thickness=1.4, Transparency=.2})
        grad(s, C.ACC1, C.ACC2, 90)
    end
    hit.MouseEnter:Connect(function() tw(chev,.2,{Position=UDim2.new(1,-30,0,0), TextColor3=C.TEXT}) end)
    hit.MouseLeave:Connect(function() tw(chev,.2,{Position=UDim2.new(1,-34,0,0), TextColor3=C.SUB}) end)
    hit.Activated:Connect(function() if o.callback then o.callback() end end)
end

local function addSlider(page, o)
    local row = new("Frame", {Size=UDim2.new(1,0,0,62), BackgroundColor3=C.CARD, BorderSizePixel=0, Parent=page})
    corner(row, 12)
    bubble(row, o.icon, o.color)
    new("TextLabel", {Text=o.title, TextColor3=C.TEXT, TextSize=14, Font=Enum.Font.GothamBold,
        BackgroundTransparency=1, Position=UDim2.new(0,64,0,0), Size=UDim2.new(1,-120,0,20),
        TextXAlignment=Enum.TextXAlignment.Left, Parent=row})
    local valLbl = new("TextLabel", {Text=tostring(o.default), TextColor3=C.TEXT, TextSize=12, Font=Enum.Font.GothamBold,
        BackgroundTransparency=1, Position=UDim2.new(1,-50,0,0), Size=UDim2.new(0,40,0,20),
        TextXAlignment=Enum.TextXAlignment.Right, Parent=row})

    local track = new("Frame", {Size=UDim2.new(1,-90,0,6), Position=UDim2.new(0,64,0,38), BackgroundColor3=C.GRAY, Parent=row})
    corner(track, 3)
    local pct = (o.default - o.min) / (o.max - o.min)
    local fill = new("Frame", {Size=UDim2.new(pct,0,1,0), BackgroundColor3=C.ACC1, Parent=track})
    corner(fill, 3)
    local knob = new("Frame", {Size=UDim2.new(0,14,0,14), Position=UDim2.new(pct,-7,.5,0), AnchorPoint=Vector2.new(0,.5), BackgroundColor3=C.TEXT, Parent=track})
    corner(knob, 7)

    local dragging = false
    local function update(input)
        local rel = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local val = math.floor(o.min + (o.max - o.min) * rel)
        tw(fill, .1, {Size=UDim2.new(rel,0,1,0)})
        tw(knob, .1, {Position=UDim2.new(rel,-7,.5,0)})
        valLbl.Text = tostring(val)
        if o.callback then o.callback(val) end
    end

    knob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update(input)
        end
    end)
end

local function createPopup(name, w, h)
    local f = new("Frame", {Size=UDim2.new(0,w,0,h), Position=UDim2.new(.5,-w/2,.5,-h/2),
        BackgroundColor3=C.CARD, BorderSizePixel=0, Visible=false, Parent=gui, ZIndex=10})
    corner(f, 14)
    new("UIStroke", {Parent=f, Thickness=1.2, Color=C.GRAY})
    local t = new("TextLabel", {Text=name, TextColor3=C.TEXT, TextSize=14, Font=Enum.Font.GothamBold,
        BackgroundTransparency=1, Position=UDim2.new(0,14,0,10), Size=UDim2.new(1,-40,0,20), Parent=f})
    local x = new("TextButton", {Text="✕", TextColor3=C.SUB, TextSize=14, Font=Enum.Font.GothamBold,
        BackgroundTransparency=1, Size=UDim2.new(0,24,0,24), Position=UDim2.new(1,-30,0,8), Parent=f})
    x.Activated:Connect(function() f.Visible = false end)

    local ds, sp2
    f.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
            ds, sp2 = inp.Position, f.Position
            local c; c = inp.Changed:Connect(function()
                if inp.UserInputState==Enum.UserInputState.End then ds=nil; c:Disconnect() end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if ds and (inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch) then
            local d = inp.Position - ds
            f.Position = sp2 + UDim2.new(0,d.X,0,d.Y)
        end
    end)
    return f
end

local humanoid, rootPart, normalSpeed = nil, nil, 16
local lastJumpTime = 0

local function setupCharacter(character)
    humanoid = character:WaitForChild("Humanoid", 3)
    rootPart  = character:WaitForChild("HumanoidRootPart", 3)
    if humanoid then
        normalSpeed = humanoid.WalkSpeed
        humanoid.StateChanged:Connect(function(_, newState)
            if newState == Enum.HumanoidStateType.Jumping then lastJumpTime = os.clock() end
        end)
    end
end
if LP.Character then setupCharacter(LP.Character) end
LP.CharacterAdded:Connect(setupCharacter)

RunService.Heartbeat:Connect(function()
    if humanoid and humanoid.Health > 0 then
        if State.AutoRun then
            humanoid.WalkSpeed = 38
            local cam = workspace.CurrentCamera
            if cam then
                local lv = cam.CFrame.LookVector
                humanoid:Move(Vector3.new(lv.X, 0, lv.Z), false)
            end
        else
            humanoid.WalkSpeed = normalSpeed
        end
    end
end)

local ESPs = {}
local RainbowLabels = {}

RunService.Heartbeat:Connect(function()
    local t = tick()
    for lbl, _ in pairs(RainbowLabels) do
        if lbl and lbl.Parent then
            lbl.TextColor3 = Color3.fromHSV((t*0.3) % 1, 1, 1)
        else
            RainbowLabels[lbl] = nil
        end
    end
end)

local function removeESP(player)
    if ESPs[player] then ESPs[player]:Destroy(); ESPs[player]=nil end
end

local function createESP(player, character)
    if player == LP then return end
    removeESP(player)
    local folder = Instance.new("Folder")
    folder.Name = "SSS_ESP"; folder.Parent = character

    local hl = Instance.new("Highlight")
    hl.Adornee = character; hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.FillTransparency = 0.75; hl.OutlineTransparency = 0
    hl.FillColor = C.ACC1; hl.OutlineColor = C.ACC2
    hl.Enabled = State.ESP; hl.Parent = folder

    local head = character:FindFirstChild("Head")
    if head then
        local bb = Instance.new("BillboardGui")
        bb.Adornee = head; bb.Size = UDim2.new(0,120,0,20)
        bb.StudsOffset = Vector3.new(0,2.5,0); bb.AlwaysOnTop = true
        bb.Enabled = State.ESP; bb.Parent = folder
        local txt = Instance.new("TextLabel")
        txt.Size = UDim2.new(1,0,1,0); txt.BackgroundTransparency = 1
        txt.Text = player.Name; txt.TextStrokeTransparency = 0.5
        txt.TextSize = 15; txt.Font = Enum.Font.GothamBold; txt.Parent = bb
        RainbowLabels[txt] = true
    end
    ESPs[player] = folder
end

local function updateESP()
    for _, folder in pairs(ESPs) do
        if folder and folder.Parent then
            for _, obj in ipairs(folder:GetChildren()) do
                if obj:IsA("Highlight") or obj:IsA("BillboardGui") then
                    obj.Enabled = State.ESP
                end
            end
        end
    end
end

local function setupPlayerESP(player)
    if player == LP then return end
    player.CharacterAdded:Connect(function(ch) task.wait(0.5); createESP(player, ch) end)
    if player.Character then createESP(player, player.Character) end
end
for _, plr in ipairs(Players:GetPlayers()) do setupPlayerESP(plr) end
Players.PlayerAdded:Connect(setupPlayerESP)
Players.PlayerRemoving:Connect(removeESP)

local PetTracker = {}
local petFilterName = ""
local petFilterMPS = 0

local function removePetESP(pet)
    local e = PetTracker[pet]
    if e then
        if e.billboard then e.billboard:Destroy() end
        if e.highlight then e.highlight:Destroy() end
        PetTracker[pet] = nil
    end
end

local function getPetName(pet) return pet:GetAttribute("Species") or pet.Name end

local function getPetMPS(pet)
    local tag = pet:FindFirstChild("ItemNameTag", true)
    if tag then
        local lbl = tag:FindFirstChild("MPS", true)
        if lbl and lbl:IsA("TextLabel") and lbl.Text ~= "" then return lbl.Text end
    end
    return "?"
end

local function parseMPS(txt)
    local lower = txt:lower()
    local mult = 1
    if lower:find("k") then mult = 1e3
    elseif lower:find("m") then mult = 1e6
    elseif lower:find("b") then mult = 1e9 end
    local num = tonumber(txt:gsub("[^%d%.]", ""))
    return num and num*mult or 0
end

local function getPetMutation(pet)
    local tag = pet:FindFirstChild("ItemNameTag", true)
    if tag then
        local mut = tag:FindFirstChild("Mutation", true)
        if mut and mut:IsA("TextLabel") and mut.Text ~= "" and mut.Visible then
            return mut.Text
        end
    end
    local attr = pet:GetAttribute("Mutation")
    if attr and attr ~= "" then return attr end
    return nil
end

local function passesFilter(pet)
    local name = getPetName(pet):lower()
    local mps = parseMPS(getPetMPS(pet))
    if petFilterName ~= "" and not name:find(petFilterName:lower()) then return false end
    if petFilterMPS > 0 and mps < petFilterMPS then return false end
    return true
end

local function createPetESP(pet)
    local adorn = nil
    for _, d in ipairs(pet:GetDescendants()) do
        if d:IsA("MeshPart") or d:IsA("BasePart") then adorn = d; break end
    end
    if not adorn then return nil end

    local bb = Instance.new("BillboardGui")
    bb.Name = "PetESP"; bb.Adornee = adorn
    bb.Size = UDim2.new(0,150,0,50); bb.AlwaysOnTop = true
    bb.LightInfluence = 0; bb.MaxDistance = 0
    bb.ExtentsOffset = Vector3.new(0,3,0); bb.Parent = pet

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Top
    layout.Padding = UDim.new(0,1); layout.Parent = bb

    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size = UDim2.new(1,0,0,14); nameLbl.BackgroundTransparency = 1
    nameLbl.Text = getPetName(pet); nameLbl.TextColor3 = C.TEXT
    nameLbl.Font = Enum.Font.GothamBold; nameLbl.TextSize = 11; nameLbl.Parent = bb
    local ns = Instance.new("UIStroke"); ns.Thickness = 1.5; ns.Color = Color3.new(0,0,0); ns.Parent = nameLbl

    local mpsLbl = Instance.new("TextLabel")
    mpsLbl.Size = UDim2.new(1,0,0,13); mpsLbl.BackgroundTransparency = 1
    mpsLbl.Text = getPetMPS(pet); mpsLbl.TextColor3 = C.GREEN
    mpsLbl.Font = Enum.Font.GothamBold; mpsLbl.TextSize = 10; mpsLbl.Parent = bb
    local ms = Instance.new("UIStroke"); ms.Thickness = 1.5; ms.Color = Color3.new(0,0,0); ms.Parent = mpsLbl

    local mutLbl = Instance.new("TextLabel")
    mutLbl.Size = UDim2.new(1,0,0,13); mutLbl.BackgroundTransparency = 1
    mutLbl.Text = ""; mutLbl.TextColor3 = C.YELLOW
    mutLbl.Font = Enum.Font.GothamBold; mutLbl.TextSize = 10
    mutLbl.Visible = false; mutLbl.Parent = bb
    local mts = Instance.new("UIStroke"); mts.Thickness = 1.5; mts.Color = Color3.new(0,0,0); mts.Parent = mutLbl

    local hl = Instance.new("Highlight")
    hl.Name = "PetESPHighlight"; hl.Adornee = pet
    hl.FillTransparency = 0.7; hl.OutlineTransparency = 0.3
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.FillColor = C.GREEN; hl.OutlineColor = C.TEXT
    hl.Parent = pet

    local function update()
        if not passesFilter(pet) then
            bb.Enabled = false; hl.Enabled = false; return
        end
        bb.Enabled = State.PetsESP; hl.Enabled = State.PetsESP
        local mutation = getPetMutation(pet)
        if mutation then
            mutLbl.Text = mutation; mutLbl.Visible = true
            hl.FillColor = C.YELLOW; hl.OutlineColor = C.YELLOW
        else
            mutLbl.Visible = false
            hl.FillColor = C.GREEN; hl.OutlineColor = C.TEXT
        end
        nameLbl.Text = getPetName(pet)
        mpsLbl.Text = getPetMPS(pet)
    end
    update()
    return {billboard = bb, highlight = hl, update = update}
end

local function setupPetESP(pet)
    if PetTracker[pet] then return end
    if pet:GetAttribute("Species") == nil then return end
    local esp = createPetESP(pet)
    if esp then PetTracker[pet] = esp end
end

local function scanPets()
    local folder = Workspace:FindFirstChild("RuntimePets")
    if not folder then return end
    for _, pet in ipairs(folder:GetChildren()) do setupPetESP(pet) end
end

local runtimePetsFolder = Workspace:FindFirstChild("RuntimePets")
if runtimePetsFolder then
    runtimePetsFolder.ChildAdded:Connect(function(c) task.wait(0.1); setupPetESP(c) end)
    runtimePetsFolder.ChildRemoved:Connect(function(c) removePetESP(c) end)
end

Workspace.ChildAdded:Connect(function(child)
    if child.Name == "RuntimePets" and child:IsA("Folder") then
        child.ChildAdded:Connect(function(p) task.wait(0.1); setupPetESP(p) end)
        child.ChildRemoved:Connect(function(p) removePetESP(p) end)
        for _, p in ipairs(child:GetChildren()) do setupPetESP(p) end
    end
end)

scanPets()

task.spawn(function()
    while task.wait(0.5) do
        if State.PetsESP then
            for pet, esp in pairs(PetTracker) do
                if pet.Parent then esp.update() else removePetESP(pet) end
            end
            scanPets()
        else
            for pet, _ in pairs(PetTracker) do removePetESP(pet) end
        end
    end
end)

local antiKbConn, isCountering, counterEnd, lastSafePos = nil, false, 0, nil

local function startAntiKnockback()
    if antiKbConn then return end
    antiKbConn = RunService.Heartbeat:Connect(function()
        if not rootPart or not humanoid or humanoid.Health <= 0 then return end
        local vel = rootPart.AssemblyLinearVelocity
        local now = os.clock()
        local hSpeed = Vector3.new(vel.X, 0, vel.Z).Magnitude
        local vSpeed = vel.Y
        local sinceJump = now - lastJumpTime
        local isJump = sinceJump < 0.3

        if hSpeed > 40 or (vSpeed > 35 and not isJump) then
            isCountering = true; counterEnd = now + 0.5
        end
        if isCountering and now < counterEnd then
            rootPart.AssemblyLinearVelocity = Vector3.zero
            if lastSafePos then rootPart.CFrame = CFrame.new(lastSafePos) end
        else
            isCountering = false
            lastSafePos = rootPart.Position
        end
    end)
end

local function stopAntiKnockback()
    if antiKbConn then antiKbConn:Disconnect(); antiKbConn = nil end
end

local LOCK_ATTR = "LockState"
local STATE_IDLE, STATE_LOCKED = "Idle", "Locked"
local autoLockThread, lastLockState = nil, nil

local function findMyPlot()
    local plots = Workspace:FindFirstChild("Plots")
    if not plots then return nil end
    for _, plot in ipairs(plots:GetChildren()) do
        if plot:IsA("Model") and plot:GetAttribute("OwnerUserId") == LP.UserId then
            return plot
        end
    end
    return nil
end

local function startAutoLock()
    if autoLockThread then return end
    autoLockThread = task.spawn(function()
        while State.AutoLock do
            local plot = findMyPlot()
            if plot and rootPart and humanoid then
                local lockObj = plot:FindFirstChild("Lock")
                if lockObj and lockObj.Name == "Lock" then
                    local cur = lockObj:GetAttribute(LOCK_ATTR) or STATE_IDLE
                    local pad = lockObj:FindFirstChild("Pad")
                    if cur ~= lastLockState then
                        if cur == STATE_IDLE then
                            notify("Warning", "База открыта", "База разблокирована")
                        elseif cur == STATE_LOCKED then
                            notify("Success", "База закрыта", "Auto Lock активирован")
                        end
                        lastLockState = cur
                    end
                    if cur == STATE_IDLE and pad then
                        pcall(function() SafeAPI.firetouch(rootPart, pad, 0) end)
                        task.wait(0.1)
                        pcall(function() SafeAPI.firetouch(rootPart, pad, 1) end)
                    end
                end
            end
            task.wait(1)
        end
        autoLockThread = nil
    end)
end

local function stopAutoLock()
    State.AutoLock = false
    if autoLockThread then task.cancel(autoLockThread); autoLockThread = nil end
    lastLockState = nil
end

local wallHopActive, wallHopWasClimbing, wallHopClear = false, false, 0

RunService.Heartbeat:Connect(function()
    if not State.WallHop or not rootPart or not humanoid then
        wallHopActive = false; wallHopWasClimbing = false; return
    end
    local rp = RaycastParams.new()
    rp.FilterDescendantsInstances = {LP.Character}
    rp.FilterType = Enum.RaycastFilterType.Exclude
    local fwd = rootPart.CFrame.LookVector
    local res = workspace:Raycast(rootPart.Position, fwd * 3, rp)
    if res then
        wallHopActive = true; wallHopWasClimbing = true; wallHopClear = 0
        local upVel = 20 + math.random(-1, 3)
        local cv = rootPart.AssemblyLinearVelocity
        rootPart.AssemblyLinearVelocity = Vector3.new(cv.X, upVel, cv.Z)
    else
        if wallHopWasClimbing then
            wallHopClear = wallHopClear + 1
            if wallHopClear < 8 then
                rootPart.AssemblyLinearVelocity = Vector3.new(fwd.X * 25, 30, fwd.Z * 25)
            else
                wallHopWasClimbing = false; wallHopClear = 0
            end
        end
        wallHopActive = false
    end
end)

local AntiFall = nil
local function createAntiFall()
    if not rootPart then return end
    if AntiFall then AntiFall:Destroy() end
    AntiFall = Instance.new("Part")
    AntiFall.Name = "AntiFall_Circle"
    AntiFall.Shape = Enum.PartType.Cylinder
    AntiFall.Size = Vector3.new(2, 800, 800)
    AntiFall.CFrame = CFrame.new(rootPart.Position.X, rootPart.Position.Y - 7, rootPart.Position.Z) * CFrame.Angles(0, 0, math.rad(90))
    AntiFall.Anchored = true
    AntiFall.CanCollide = true
    AntiFall.Material = Enum.Material.Glass
    AntiFall.Color = Color3.fromRGB(80, 210, 255)
    AntiFall.Transparency = 0.45
    AntiFall.Parent = Workspace
end
local function removeAntiFall()
    if AntiFall then AntiFall:Destroy(); AntiFall = nil end
end

local antiAfkConn = nil
local function startAntiAfk()
    if antiAfkConn then return end
    antiAfkConn = LP.Idled:Connect(function()
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.zero)
        end)
    end)
end
local function stopAntiAfk()
    if antiAfkConn then antiAfkConn:Disconnect(); antiAfkConn = nil end
end
if State.AntiAFK then startAntiAfk() end

local baseDebounce = false
local function smoothVerticalMove(dist, dir)
    if not rootPart or baseDebounce then return end
    baseDebounce = true
    local targetY = rootPart.Position.Y + (dist * dir)
    task.spawn(function()
        local orig = rootPart.CanCollide
        pcall(function() rootPart.CanCollide = false end)
        local steps = math.abs(dist) * 4
        local step = (dist / steps) * dir
        for i = 1, steps do
            if not rootPart then break end
            rootPart.CFrame = rootPart.CFrame + Vector3.new(0, step, 0)
            task.wait(0.005)
        end
        if rootPart then
            rootPart.CFrame = CFrame.new(rootPart.Position.X, targetY, rootPart.Position.Z) * CFrame.Angles(0, math.rad(rootPart.Orientation.Y), 0)
            pcall(function() rootPart.CanCollide = orig end)
        end
        task.wait(0.2)
        baseDebounce = false
    end)
end

local ServerSearching = false

local function GetServers()
    local all = {}
    local cursor = nil
    for page = 1, 5 do
        local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?limit=100"
        if cursor then url = url .. "&cursor=" .. HttpService:UrlEncode(cursor) end
        local ok, res = pcall(function() return SafeAPI.HttpGet(url) end)
        if not ok then break end
        local ok2, data = pcall(function() return HttpService:JSONDecode(res) end)
        if not ok2 or type(data) ~= "table" then break end
        if type(data.data) == "table" then
            for _, s in ipairs(data.data) do
                if s.id and s.playing and s.maxPlayers then table.insert(all, s) end
            end
        end
        cursor = data.nextPageCursor
        if not cursor then break end
        task.wait(0.25)
    end
    return all
end

local function FindServer(mode)
    local best = nil
    for _ = 1, 5 do
        local servers = GetServers()
        for _, s in ipairs(servers) do
            if s.id ~= game.JobId and s.playing < s.maxPlayers then
                if mode == "BUSY" then
                    if not best or s.playing > best.playing then best = s end
                elseif mode == "EMPTY" then
                    if not best or s.playing < best.playing then best = s end
                end
            end
        end
        if best then return best end
        task.wait(1)
    end
    return nil
end

local function SaveJobs()
    SaveJSON(JobsFile, SavedJobs)
end

local BypassMenu = createPopup("BYPASS", 220, 220)
local PetFilterMenu = createPopup("PET FILTERS", 260, 180)

local whRow = new("Frame", {Size=UDim2.new(1,-28,0,38), Position=UDim2.new(0,14,0,40),
    BackgroundColor3=C.CARD, Parent=BypassMenu})
corner(whRow, 10)
new("TextLabel", {Text="Wall Hop", TextColor3=C.TEXT, TextSize=13, Font=Enum.Font.GothamBold,
    BackgroundTransparency=1, Position=UDim2.new(0,12,0,0), Size=UDim2.new(1,-80,1,0),
    TextXAlignment=Enum.TextXAlignment.Left, Parent=whRow})

local whTrack = new("Frame", {Size=UDim2.new(0,46,0,26), Position=UDim2.new(1,-56,.5,0),
    AnchorPoint=Vector2.new(1,.5), BackgroundColor3=C.GRAY, Parent=whRow})
corner(whTrack, 13)
local whKnob = new("Frame", {Size=UDim2.new(0,20,0,20), Position=UDim2.new(0,3,.5,0),
    AnchorPoint=Vector2.new(0,.5), BackgroundColor3=C.TEXT, Parent=whTrack})
corner(whKnob, 10)

local whToggleData = {track=whTrack, isOn=false}
table.insert(AccentToggles, whToggleData)

local function setWallHop(v)
    State.WallHop = v
    whToggleData.isOn = v
    tw(whKnob, .3, {Position = v and UDim2.new(1,-23,.5,0) or UDim2.new(0,3,.5,0)}, Enum.EasingStyle.Back)
    tw(whTrack, .3, {BackgroundColor3 = v and C.ACC1 or C.GRAY})
    Config.WallHop = v; SaveConfig()
    notify(v and "Success" or "Info", "Wall Hop", v and "Enabled" or "Disabled")
end
new("TextButton", {Text="", BackgroundTransparency=1, Size=UDim2.new(1,0,1,0),
    Parent=whRow}).Activated:Connect(function() setWallHop(not State.WallHop) end)
if State.WallHop then task.delay(0.2, function() setWallHop(true) end) end

local enterBtn = new("TextButton", {Text="Enter Base", TextColor3=C.TEXT, TextSize=12,
    Font=Enum.Font.GothamBold, BackgroundColor3=C.HOVER, Size=UDim2.new(1,-28,0,34),
    Position=UDim2.new(0,14,0,88), Parent=BypassMenu})
corner(enterBtn, 10)
enterBtn.Activated:Connect(function()
    smoothVerticalMove(17, -1); notify("Info", "Enter Base", "Moving down")
end)

local exitBtn = new("TextButton", {Text="Exit Base", TextColor3=C.TEXT, TextSize=12,
    Font=Enum.Font.GothamBold, BackgroundColor3=C.HOVER, Size=UDim2.new(1,-28,0,34),
    Position=UDim2.new(0,14,0,130), Parent=BypassMenu})
corner(exitBtn, 10)
exitBtn.Activated:Connect(function()
    smoothVerticalMove(20, 1); notify("Info", "Exit Base", "Moving up")
end)

new("TextLabel", {Text="Name:", TextColor3=C.SUB, TextSize=11,
    Font=Enum.Font.Gotham, BackgroundTransparency=1, Position=UDim2.new(0,14,0,40),
    Size=UDim2.new(0,50,0,20), TextXAlignment=Enum.TextXAlignment.Left, Parent=PetFilterMenu})
local nameBox = new("TextBox", {Text="", PlaceholderText="e.g. Dragon", TextColor3=C.TEXT,
    PlaceholderColor3=C.SUB, TextSize=11, Font=Enum.Font.Gotham, BackgroundColor3=C.BG,
    Size=UDim2.new(1,-80,0,26), Position=UDim2.new(0,70,0,38), Parent=PetFilterMenu})
corner(nameBox, 8)
new("UIStroke", {Parent=nameBox, Thickness=1, Color=C.GRAY})

new("TextLabel", {Text="Min MPS:", TextColor3=C.SUB, TextSize=11,
    Font=Enum.Font.Gotham, BackgroundTransparency=1, Position=UDim2.new(0,14,0,74),
    Size=UDim2.new(0,50,0,20), TextXAlignment=Enum.TextXAlignment.Left, Parent=PetFilterMenu})
local mpsBox = new("TextBox", {Text="0", TextColor3=C.TEXT, PlaceholderColor3=C.SUB,
    TextSize=11, Font=Enum.Font.Gotham, BackgroundColor3=C.BG,
    Size=UDim2.new(1,-80,0,26), Position=UDim2.new(0,70,0,72), Parent=PetFilterMenu})
corner(mpsBox, 8)
new("UIStroke", {Parent=mpsBox, Thickness=1, Color=C.GRAY})

local applyBtn = new("TextButton", {Text="APPLY", TextColor3=C.TEXT, TextSize=11,
    Font=Enum.Font.GothamBold, BackgroundColor3=C.GREEN, Size=UDim2.new(0.45,0,0,30),
    Position=UDim2.new(0.05,0,0,115), Parent=PetFilterMenu})
corner(applyBtn, 8)
applyBtn.Activated:Connect(function()
    petFilterName = nameBox.Text
    local txt = mpsBox.Text:lower()
    local mult = 1
    if txt:find("k") then mult = 1e3 elseif txt:find("m") then mult = 1e6 elseif txt:find("b") then mult = 1e9 end
    local num = tonumber(txt:gsub("[^%d%.]", ""))
    petFilterMPS = num and num * mult or 0
    PetFilterMenu.Visible = false
    notify("Success", "Pet Filter", "Applied successfully")
end)

local clearBtn = new("TextButton", {Text="CLEAR", TextColor3=C.TEXT, TextSize=11,
    Font=Enum.Font.GothamBold, BackgroundColor3=C.RED, Size=UDim2.new(0.45,0,0,30),
    Position=UDim2.new(0.52,0,0,115), Parent=PetFilterMenu})
corner(clearBtn, 8)
clearBtn.Activated:Connect(function()
    nameBox.Text = ""; mpsBox.Text = "0"
    petFilterName = ""; petFilterMPS = 0
    notify("Info", "Pet Filter", "Cleared")
end)

local mainPage,  _ = addTab("🏠 MAIN")
local combatPage, _ = addTab("⚔ COMBAT")
local serverPage, _ = addTab("🖥 SERVER")
local settingsPage,_ = addTab("⚙ SETTINGS")

addToggle(mainPage, {icon="🏃", color=C.BLUE, title="AUTO RUN", keybind="R", default=State.AutoRun,
    callback=function(v)
        State.AutoRun = v; Config.AutoRun = v; SaveConfig()
        notify(v and "Success" or "Info", "Auto Run", v and "Enabled" or "Disabled")
    end})

addToggle(mainPage, {icon="👁", color=C.ACC1, title="PLAYER ESP", keybind="T", default=State.ESP,
    callback=function(v)
        State.ESP = v; Config.ESP = v; SaveConfig(); updateESP()
        notify("Info", "Player ESP", v and "Enabled" or "Disabled")
    end})

addToggle(mainPage, {icon="🐾", color=C.TEAL, title="PETS ESP", keybind="Y", default=State.PetsESP,
    callback=function(v)
        State.PetsESP = v; Config.PetsESP = v; SaveConfig()
        if not v then for pet,_ in pairs(PetTracker) do removePetESP(pet) end end
        notify("Info", "Pets ESP", v and "Enabled" or "Disabled")
    end})

addToggle(mainPage, {icon="🛡", color=C.TEAL, title="ANTI KNOCKBACK", keybind="G", default=State.AntiKnockback,
    callback=function(v)
        State.AntiKnockback = v; Config.AntiKnockback = v; SaveConfig()
        if v then startAntiKnockback() else stopAntiKnockback() end
        notify(v and "Success" or "Info", "Anti Knockback", v and "Enabled" or "Disabled")
    end})

addToggle(mainPage, {icon="🪂", color=C.BLUE, title="ANTI FALL", default=State.AntiFall,
    callback=function(v)
        State.AntiFall = v; Config.AntiFall = v; SaveConfig()
        if v then createAntiFall() else removeAntiFall() end
        notify("Info", "Anti Fall", v and "Enabled" or "Disabled")
    end})

addToggle(mainPage, {icon="🔒", color=C.PINK, title="AUTO LOCK BASE", default=State.AutoLock,
    callback=function(v)
        State.AutoLock = v; Config.AutoLock = v; SaveConfig()
        if v then startAutoLock() else stopAutoLock() end
        notify(v and "Success" or "Info", "Auto Lock", v and "Enabled" or "Disabled")
    end})

addToggle(mainPage, {icon="⏰", color=C.ACC2, title="ANTI AFK", default=State.AntiAFK,
    callback=function(v)
        State.AntiAFK = v; Config.AntiAFK = v; SaveConfig()
        if v then startAntiAfk() else stopAntiAfk() end
        notify("Info", "Anti AFK", v and "Enabled" or "Disabled")
    end})

addButton(mainPage, {icon="🔽", color=C.ACC2, title="PET FILTER",
    callback=function() PetFilterMenu.Visible = not PetFilterMenu.Visible end})

addButton(mainPage, {icon="⚡", color=C.ACC1, title="BYPASS MENU", accent=true, keybind="B",
    callback=function() BypassMenu.Visible = not BypassMenu.Visible end})

addSlider(combatPage, {icon="🚀", color=C.BLUE, title="SPEED", min=16, max=120, default=normalSpeed,
    callback=function(v)
        normalSpeed = v
        if humanoid and not State.AutoRun then humanoid.WalkSpeed = v end
    end})

addSlider(combatPage, {icon="🐇", color=C.TEAL, title="JUMP", min=50, max=220, default=50,
    callback=function(v)
        if humanoid then humanoid.UseJumpPower = true; humanoid.JumpPower = v end
    end})

local statusLbl = new("TextLabel", {Text="Saved Jobs: "..#SavedJobs, TextColor3=C.SUB, TextSize=12,
    Font=Enum.Font.GothamBold, BackgroundTransparency=1, Size=UDim2.new(1,0,0,20), Parent=serverPage})

addButton(serverPage, {icon="💾", color=C.GREEN, title="COPY & SAVE JOB",
    callback=function()
        local jid = game.JobId
        if #SavedJobs >= 10 then notify("Warning", "Server Hop", "Max 10 saved jobs!"); return end
        for _, d in ipairs(SavedJobs) do if d.JobId == jid then notify("Warning", "Server Hop", "Already saved!"); return end end
        table.insert(SavedJobs, {JobId=jid, Name="Server "..(#SavedJobs+1)})
        SaveJobs(); SafeAPI.setclip(jid)
        statusLbl.Text = "Saved Jobs: "..#SavedJobs
        notify("Success", "Server Hop", "Saved & Copied!")
    end})

addButton(serverPage, {icon="🔁", color=C.ACC2, title="RECONNECT",
    callback=function()
        pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP) end)
    end})

addButton(serverPage, {icon="🌀", color=C.ACC1, title="JOIN BUSY SERVER",
    callback=function()
        if ServerSearching then return end
        ServerSearching = true; statusLbl.Text = "Searching busy..."
        local s = FindServer("BUSY")
        if s then
            statusLbl.Text = "Joining: "..s.playing.."/"..s.maxPlayers
            task.wait(0.5)
            pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LP) end)
        else
            statusLbl.Text = "Not found!"
            notify("Warning", "Server Hop", "No busy servers found")
        end
        ServerSearching = false
    end})

addButton(serverPage, {icon="🌑", color=C.BLUE, title="JOIN EMPTY SERVER",
    callback=function()
        if ServerSearching then return end
        ServerSearching = true; statusLbl.Text = "Searching empty..."
        local s = FindServer("EMPTY")
        if s then
            statusLbl.Text = "Joining: "..s.playing.."/"..s.maxPlayers
            task.wait(0.5)
            pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LP) end)
        else
            statusLbl.Text = "Not found!"
            notify("Warning", "Server Hop", "No empty servers found")
        end
        ServerSearching = false
    end})

local listContainer = new("Frame", {Size=UDim2.new(1,0,0,0), BackgroundTransparency=1,
    AutomaticSize=Enum.AutomaticSize.Y, Parent=serverPage})
new("UIListLayout", {Padding=UDim.new(0,6), Parent=listContainer})

local function UpdateServerList()
    for _, c in ipairs(listContainer:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    for i, data in ipairs(SavedJobs) do
        local row = new("Frame", {Size=UDim2.new(1,0,0,32), BackgroundColor3=C.CARD, Parent=listContainer})
        corner(row, 8)
        new("UIStroke", {Parent=row, Thickness=1, Color=C.GRAY})
        new("TextLabel", {Text=data.Name or ("Server "..i), TextColor3=C.TEXT, TextSize=12,
            Font=Enum.Font.Gotham, BackgroundTransparency=1, Position=UDim2.new(0,10,0,0),
            Size=UDim2.new(1,-100,1,0), TextXAlignment=Enum.TextXAlignment.Left, Parent=row})

        local jBtn = new("TextButton", {Text="JOIN", TextColor3=C.TEXT, TextSize=10,
            Font=Enum.Font.GothamBold, BackgroundColor3=C.GREEN, Size=UDim2.new(0,44,0,22),
            Position=UDim2.new(1,-92,0,5), Parent=row})
        corner(jBtn, 6)
        jBtn.Activated:Connect(function()
            pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, data.JobId, LP) end)
        end)

        local dBtn = new("TextButton", {Text="✕", TextColor3=C.TEXT, TextSize=12,
            Font=Enum.Font.GothamBold, BackgroundColor3=C.RED, Size=UDim2.new(0,28,0,22),
            Position=UDim2.new(1,-40,0,5), Parent=row})
        corner(dBtn, 6)
        dBtn.Activated:Connect(function()
            table.remove(SavedJobs, i); SaveJobs()
            statusLbl.Text = "Saved Jobs: "..#SavedJobs
            UpdateServerList()
        end)
    end
end
UpdateServerList()

addToggle(settingsPage, {icon="💾", color=C.GREEN, title="SAVE CONFIG", default=State.SaveConfig,
    callback=function(v)
        State.SaveConfig = v; Config.SaveConfig = v; SaveConfig()
        notify(v and "Success" or "Warning", "Config", v and "Auto-save enabled" or "Auto-save disabled")
    end})

new("TextLabel", {Text="Accent Color", TextColor3=C.TEXT, TextSize=13, Font=Enum.Font.GothamBold,
    BackgroundTransparency=1, Size=UDim2.new(1,0,0,20), Parent=settingsPage})

local colorRow = new("Frame", {Size=UDim2.new(1,0,0,40), BackgroundTransparency=1, Parent=settingsPage})
new("UIListLayout", {FillDirection=Enum.FillDirection.Horizontal, Padding=UDim.new(0,8),
    HorizontalAlignment=Enum.HorizontalAlignment.Center, VerticalAlignment=Enum.VerticalAlignment.Center,
    Parent=colorRow})

local ColorPresets = {
    {name="Blue",   c=Color3.fromRGB(64,118,255)},
    {name="Purple", c=Color3.fromRGB(158,77,255)},
    {name="Red",    c=Color3.fromRGB(235,87,87)},
    {name="Green",  c=Color3.fromRGB(46,204,113)},
    {name="Orange", c=Color3.fromRGB(243,186,47)},
    {name="Pink",   c=Color3.fromRGB(232,62,140)},
    {name="Cyan",   c=Color3.fromRGB(29,209,161)},
    {name="White",  c=Color3.fromRGB(200,200,210)},
}

local selectedSwatchStroke = nil
for _, preset in ipairs(ColorPresets) do
    local sw = new("TextButton", {Size=UDim2.new(0,28,0,28), BackgroundColor3=preset.c,
        Text="", Parent=colorRow})
    corner(sw, 6)
    local stroke = new("UIStroke", {Parent=sw, Thickness=0, Color=C.TEXT})
    
    if C.ACC1 == preset.c then
        stroke.Thickness = 2
        selectedSwatchStroke = stroke
    end
    
    sw.Activated:Connect(function()
        if selectedSwatchStroke then selectedSwatchStroke.Thickness = 0 end
        stroke.Thickness = 2
        selectedSwatchStroke = stroke
        setAccent(preset.c)
        notify("Success", "Accent Color", preset.name)
    end)
end

new("TextLabel", {Text="Click keybind buttons to rebind.\nPress ESC to cancel.", TextColor3=C.SUB,
    TextSize=11, Font=Enum.Font.Gotham, BackgroundTransparency=1, Size=UDim2.new(1,0,0,40),
    TextWrapped=true, Parent=settingsPage})

for i, btn in ipairs(tabs) do btn.Activated:Connect(function() selectTab(i) end) end

task.wait(.1)
selectTab(1)
tw(main, .5, {BackgroundTransparency=0})
tw(scale, .5, {Scale=1}, Enum.EasingStyle.Back)

local visible = true
UserInputService.InputBegan:Connect(function(inp, gp)
    if gp then return end
    if inp.KeyCode == Enum.KeyCode.RightControl then
        visible = not visible
        if visible then
            main.Visible = true
            tw(main,.35,{BackgroundTransparency=0}); tw(scale,.35,{Scale=1},Enum.EasingStyle.Back)
        else
            tw(main,.25,{BackgroundTransparency=1},Enum.EasingStyle.Quart,Enum.EasingDirection.In)
            tw(scale,.25,{Scale=.92})
            task.delay(.25, function() main.Visible = false end)
        end
    end
end)

task.wait(.8)
notify("Info", "SSS HUB", "Welcome! RightCtrl — toggle menu.", 5)
