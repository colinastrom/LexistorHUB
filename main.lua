--// SSSHUB STEAL + MAIN
--// By Rosomax0 • Developer
--// FULLY FIXED & REFACTORED

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

local LP = Players.LocalPlayer
local PlaceId = game.PlaceId

if CoreGui:FindFirstChild("SSSHub") then CoreGui.SSSHub:Destroy() end
if CoreGui:FindFirstChild("SSSNotify") then CoreGui.SSSNotify:Destroy() end

local Theme = {
    Background = Color3.fromRGB(20, 20, 25),
    Sidebar = Color3.fromRGB(25, 25, 30),
    Card = Color3.fromRGB(30, 30, 38),
    CardHover = Color3.fromRGB(40, 40, 50),
    Stroke = Color3.fromRGB(50, 50, 60),
    Accent = Color3.fromRGB(120, 80, 220),
    Text = Color3.fromRGB(240, 240, 245),
    TextDark = Color3.fromRGB(150, 150, 160),
    ToggleOff = Color3.fromRGB(45, 45, 55),
    ToggleOn = Color3.fromRGB(120, 80, 220),
    Success = Color3.fromRGB(40, 180, 80),
    Warning = Color3.fromRGB(220, 150, 50),
    Error = Color3.fromRGB(200, 60, 60),
    Info = Color3.fromRGB(80, 120, 220)
}

-- Config System
local ConfigFile = "SSSHubConfig.json"
local JobsFile = "SSSHubJobs.json"
local Config = {}

local function LoadJSON(path)
    if isfile and isfile(path) then
        local ok, txt = pcall(readfile, path)
        if ok and txt then
            local ok2, data = pcall(HttpService.JSONDecode, HttpService, txt)
            if ok2 and type(data) == "table" then return data end
        end
    end
    return nil
end

local function SaveJSON(path, data)
    if writefile then pcall(writefile, path, HttpService:JSONEncode(data)) end
end

Config = LoadJSON(ConfigFile) or {}
local Keybinds = Config.Keybinds or {}

local function SaveConfig()
    Config.Keybinds = Keybinds
    SaveJSON(ConfigFile, Config)
end

-- Accent Tracker
local AccentTracker = { Static = {}, Toggles = {}, Tabs = {} }
local CurrentAccent = Theme.Accent

local function SetAccent(color)
    Theme.Accent = color
    Theme.ToggleOn = color
    CurrentAccent = color
    Config.AccentColor = {math.floor(color.R * 255), math.floor(color.G * 255), math.floor(color.B * 255)}
    SaveConfig()
    for _, elem in ipairs(AccentTracker.Static) do
        if elem and elem.Parent then TweenService:Create(elem, TweenInfo.new(0.2), {BackgroundColor3 = color}):Play() end
    end
    for _, toggle in ipairs(AccentTracker.Toggles) do
        if toggle.isOn then TweenService:Create(toggle.btn, TweenInfo.new(0.2), {BackgroundColor3 = color}):Play() end
    end
    for _, tabData in pairs(AccentTracker.Tabs) do
        if tabData.isActive then TweenService:Create(tabData.btn, TweenInfo.new(0.2), {BackgroundColor3 = color}):Play() end
    end
end

if Config.AccentColor then
    local c = Config.AccentColor
    SetAccent(Color3.fromRGB(c[1], c[2], c[3]))
end

-- State
local State = {
    autoRun = Config.autoRun or false,
    espEnabled = Config.espEnabled or false,
    petsEspEnabled = Config.petsEspEnabled or false,
    wallHopEnabled = Config.wallHopEnabled or false,
    antiFallEnabled = Config.antiFallEnabled or false,
    antiAfkEnabled = Config.antiAfkEnabled ~= false,
    autoLockEnabled = Config.autoLockEnabled or false,
    antiKnockbackEnabled = Config.antiKnockbackEnabled or false,
    saveConfigEnabled = Config.saveConfigEnabled ~= false
}

local SavedJobs = LoadJSON(JobsFile) or {}

-- Helpers
local function new(cls, props, parent)
    local o = Instance.new(cls)
    for k, v in pairs(props) do o[k] = v end
    o.Parent = parent
    return o
end

local function tw(obj, t, props, style, dir)
    local tr = TweenService:Create(obj, TweenInfo.new(t, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out), props)
    tr:Play()
    return tr
end

local function corner(p, r) return new("UICorner", {CornerRadius = UDim.new(0, r), Parent = p}) end

local function AddHover(btn, baseColor, hoverColor)
    local bc = baseColor or Theme.Card
    local hc = hoverColor or Theme.CardHover
    btn.MouseEnter:Connect(function() tw(btn, 0.2, {BackgroundColor3 = hc}) end)
    btn.MouseLeave:Connect(function() tw(btn, 0.2, {BackgroundColor3 = bc}) end)
end

-- Notifications
local NotifyGui = new("ScreenGui", {Name = "SSSNotify", ResetOnSpawn = false, DisplayOrder = 999999, Parent = CoreGui})
local NotifyHolder = new("Frame", {BackgroundTransparency = 1, Position = UDim2.new(1, -320, 0, 20), Size = UDim2.new(0, 300, 1, -40), Parent = NotifyGui})
new("UIListLayout", {Padding = UDim.new(0, 10), Parent = NotifyHolder})

local function notify(title, text, notifType)
    notifType = notifType or "success"
    local iconColor = Theme.Success
    local iconText = "🛡"
    if notifType == "warning" then iconColor = Theme.Warning; iconText = "⚠"
    elseif notifType == "error" then iconColor = Theme.Error; iconText = "✕"
    elseif notifType == "info" then iconColor = CurrentAccent; iconText = "ℹ" end

    local notif = new("Frame", {Size = UDim2.new(0, 280, 0, 70), Position = UDim2.new(0, 300, 0, 0), BackgroundColor3 = Theme.Card, BorderSizePixel = 0, Parent = NotifyHolder})
    corner(notif, 8)
    local stroke = new("UIStroke", {Color = Theme.Stroke, Thickness = 1.5, Parent = notif})
    
    local iconCircle = new("Frame", {Size = UDim2.new(0, 40, 0, 40), Position = UDim2.new(0, 12, 0.5, -20), BackgroundColor3 = iconColor, BorderSizePixel = 0, Parent = notif})
    corner(iconCircle, 1)
    new("TextLabel", {Text = iconText, TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 18, Font = Enum.Font.GothamBold, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Parent = iconCircle})
    
    new("TextLabel", {Text = title, TextColor3 = Theme.Text, TextSize = 14, Font = Enum.Font.GothamBold, BackgroundTransparency = 1, Position = UDim2.new(0, 62, 0, 15), Size = UDim2.new(1, -70, 0, 20), TextXAlignment = Enum.TextXAlignment.Left, Parent = notif})
    new("TextLabel", {Text = text, TextColor3 = Theme.TextDark, TextSize = 12, Font = Enum.Font.Gotham, BackgroundTransparency = 1, Position = UDim2.new(0, 62, 0, 38), Size = UDim2.new(1, -70, 0, 16), TextXAlignment = Enum.TextXAlignment.Left, Parent = notif})
    
    local progress = new("Frame", {Size = UDim2.new(1, 0, 0, 3), Position = UDim2.new(0, 0, 1, -3), BackgroundColor3 = iconColor, BorderSizePixel = 0, Parent = notif})
    corner(progress, 1)
    
    notif.BackgroundTransparency = 1
    iconCircle.BackgroundTransparency = 1
    progress.BackgroundTransparency = 1
    stroke.Transparency = 1
    
    tw(notif, 0.4, {Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 0})
    tw(stroke, 0.4, {Transparency = 0})
    tw(iconCircle, 0.4, {BackgroundTransparency = 0})
    tw(progress, 0.4, {BackgroundTransparency = 0})
    
    task.delay(0.4, function() tw(progress, 2.6, {Size = UDim2.new(0, 0, 0, 3)}) end)
    task.delay(3, function()
        tw(notif, 0.4, {Position = UDim2.new(0, 300, 0, 0), BackgroundTransparency = 1})
        tw(stroke, 0.4, {Transparency = 1})
        tw(iconCircle, 0.4, {BackgroundTransparency = 1})
        tw(progress, 0.4, {BackgroundTransparency = 1})
        task.delay(0.4, function() notif:Destroy() end)
    end)
end

-- Character Setup
local humanoid, rootPart, normalSpeed = nil, nil, 16
local lastJumpTime = 0

local function setupCharacter(char)
    humanoid = char:WaitForChild("Humanoid", 3)
    rootPart = char:WaitForChild("HumanoidRootPart", 3)
    if humanoid then
        normalSpeed = humanoid.WalkSpeed
        humanoid.StateChanged:Connect(function(_, newState)
            if newState == Enum.HumanoidStateType.Jumping then lastJumpTime = os.clock() end
        end)
    end
end
if LP.Character then setupCharacter(LP.Character) end
LP.CharacterAdded:Connect(setupCharacter)

-- Logic: AutoRun
RunService.Heartbeat:Connect(function()
    if humanoid and humanoid.Health > 0 then
        if State.autoRun then
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

-- Logic: Player ESP
local ESPs = {}
local RainbowLabels = {}
RunService.Heartbeat:Connect(function()
    local t = tick()
    for lbl, _ in pairs(RainbowLabels) do
        if lbl and lbl.Parent then lbl.TextColor3 = Color3.fromHSV((t * 0.3) % 1, 1, 1)
        else RainbowLabels[lbl] = nil end
    end
end)

local function removeESP(p) if ESPs[p] then ESPs[p]:Destroy(); ESPs[p] = nil end end
local function createESP(p, ch)
    if p == LP then return end
    removeESP(p)
    local f = Instance.new("Folder"); f.Name = "SSS_ESP"; f.Parent = ch
    local hl = Instance.new("Highlight")
    hl.Adornee = ch; hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.FillTransparency = 0.75; hl.OutlineTransparency = 0
    hl.FillColor = Color3.fromRGB(255, 255, 255); hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    hl.Enabled = State.espEnabled; hl.Parent = f
    local head = ch:FindFirstChild("Head")
    if head then
        local bb = Instance.new("BillboardGui")
        bb.Adornee = head; bb.Size = UDim2.new(0, 120, 0, 20)
        bb.StudsOffset = Vector3.new(0, 2.5, 0); bb.AlwaysOnTop = true
        bb.Enabled = State.espEnabled; bb.Parent = f
        local txt = Instance.new("TextLabel")
        txt.Size = UDim2.new(1, 0, 1, 0); txt.BackgroundTransparency = 1
        txt.Text = p.Name; txt.TextStrokeTransparency = 0.5
        txt.TextSize = 15; txt.Font = Enum.Font.GothamBold; txt.Parent = bb
        RainbowLabels[txt] = true
    end
    ESPs[p] = f
end

local function updateESP()
    for _, f in pairs(ESPs) do
        if f and f.Parent then
            for _, o in ipairs(f:GetChildren()) do
                if o:IsA("Highlight") or o:IsA("BillboardGui") then o.Enabled = State.espEnabled end
            end
        end
    end
end

local function setupESP(p)
    if p == LP then return end
    p.CharacterAdded:Connect(function(ch) task.wait(0.5); createESP(p, ch) end)
    if p.Character then createESP(p, p.Character) end
end
for _, p in ipairs(Players:GetPlayers()) do setupESP(p) end
Players.PlayerAdded:Connect(setupESP)
Players.PlayerRemoving:Connect(removeESP)

-- Logic: Pets ESP
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

local function getPetName(p) return p:GetAttribute("Species") or p.Name end
local function getPetMPS(p)
    local tag = p:FindFirstChild("ItemNameTag", true)
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
    return num and num * mult or 0
end

local function getPetMutation(p)
    local tag = p:FindFirstChild("ItemNameTag", true)
    if tag then
        local mut = tag:FindFirstChild("Mutation", true)
        if mut and mut:IsA("TextLabel") and mut.Text ~= "" and mut.Visible then return mut.Text end
    end
    local attr = p:GetAttribute("Mutation")
    if attr and attr ~= "" then return attr end
    return nil
end

local function passesFilter(p)
    local name = getPetName(p):lower()
    local mps = parseMPS(getPetMPS(p))
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
    bb.Size = UDim2.new(0, 150, 0, 50); bb.AlwaysOnTop = true
    bb.LightInfluence = 0; bb.MaxDistance = 0
    bb.ExtentsOffset = Vector3.new(0, 3, 0); bb.Parent = pet
    
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Top
    layout.Padding = UDim.new(0, 1); layout.Parent = bb
    
    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size = UDim2.new(1, 0, 0, 14); nameLbl.BackgroundTransparency = 1
    nameLbl.Text = getPetName(pet); nameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLbl.Font = Enum.Font.GothamBold; nameLbl.TextSize = 11; nameLbl.Parent = bb
    local ns = Instance.new("UIStroke"); ns.Thickness = 1.5; ns.Color = Color3.new(0, 0, 0); ns.Parent = nameLbl
    
    local mpsLbl = Instance.new("TextLabel")
    mpsLbl.Size = UDim2.new(1, 0, 0, 13); mpsLbl.BackgroundTransparency = 1
    mpsLbl.Text = getPetMPS(pet); mpsLbl.TextColor3 = Color3.fromRGB(100, 255, 100)
    mpsLbl.Font = Enum.Font.GothamBold; mpsLbl.TextSize = 10; mpsLbl.Parent = bb
    local ms = Instance.new("UIStroke"); ms.Thickness = 1.5; ms.Color = Color3.new(0, 0, 0); ms.Parent = mpsLbl
    
    local mutLbl = Instance.new("TextLabel")
    mutLbl.Size = UDim2.new(1, 0, 0, 13); mutLbl.BackgroundTransparency = 1
    mutLbl.Text = ""; mutLbl.TextColor3 = Color3.fromRGB(255, 215, 0)
    mutLbl.Font = Enum.Font.GothamBold; mutLbl.TextSize = 10
    mutLbl.Visible = false; mutLbl.Parent = bb
    local mts = Instance.new("UIStroke"); mts.Thickness = 1.5; mts.Color = Color3.new(0, 0, 0); mts.Parent = mutLbl
    
    local hl = Instance.new("Highlight")
    hl.Name = "PetESPHighlight"; hl.Adornee = pet
    hl.FillTransparency = 0.7; hl.OutlineTransparency = 0.3
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.FillColor = Color3.fromRGB(0, 255, 100); hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    hl.Parent = pet
    
    local function update()
        if not passesFilter(pet) then bb.Enabled = false; hl.Enabled = false; return end
        bb.Enabled = State.petsEspEnabled; hl.Enabled = State.petsEspEnabled
        local mutation = getPetMutation(pet)
        if mutation then
            mutLbl.Text = mutation; mutLbl.Visible = true
            hl.FillColor = Color3.fromRGB(255, 215, 0); hl.OutlineColor = Color3.fromRGB(255, 215, 0)
        else
            mutLbl.Visible = false
            hl.FillColor = Color3.fromRGB(0, 255, 100); hl.OutlineColor = Color3.fromRGB(255, 255, 255)
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

-- Logic: Anti Knockback
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
local function stopAntiKnockback() if antiKbConn then antiKbConn:Disconnect(); antiKbConn = nil end end

-- Logic: Auto Lock Base
local LOCK_ATTR = "LockState"
local STATE_IDLE, STATE_LOCKED = "Idle", "Locked"
local autoLockThread, lastLockState = nil, nil
local function findMyPlot()
    local plots = Workspace:FindFirstChild("Plots")
    if not plots then return nil end
    for _, plot in ipairs(plots:GetChildren()) do
        if plot:IsA("Model") and plot:GetAttribute("OwnerUserId") == LP.UserId then return plot end
    end
    return nil
end

local function startAutoLock()
    if autoLockThread then return end
    autoLockThread = task.spawn(function()
        while State.autoLockEnabled do
            local plot = findMyPlot()
            if plot and rootPart and humanoid then
                local lockObj = plot:FindFirstChild("Lock")
                if lockObj and lockObj.Name == "Lock" then
                    local cur = lockObj:GetAttribute(LOCK_ATTR) or STATE_IDLE
                    local pad = lockObj:FindFirstChild("Pad")
                    if cur ~= lastLockState then
                        if cur == STATE_IDLE then notify("База открыта", "База разблокирована", "warning")
                        elseif cur == STATE_LOCKED then notify("База закрыта", "Auto Lock активирован", "success") end
                        lastLockState = cur
                    end
                    if cur == STATE_IDLE and pad then
                        pcall(function() firetouchinterest(rootPart, pad, 0) end)
                        task.wait(0.1)
                        pcall(function() firetouchinterest(rootPart, pad, 1) end)
                    end
                end
            end
            task.wait(1)
        end
        autoLockThread = nil
    end)
end
local function stopAutoLock()
    State.autoLockEnabled = false
    if autoLockThread then task.cancel(autoLockThread); autoLockThread = nil end
    lastLockState = nil
end

-- Logic: Wall Hop
local wallHopActive, wallHopWasClimbing, wallHopClear = false, false, 0
RunService.Heartbeat:Connect(function()
    if not State.wallHopEnabled or not rootPart or not humanoid then
        wallHopActive = false; wallHopWasClimbing = false; return
    end
    local char = LP.Character
    if not char then return end
    local rp = RaycastParams.new()
    rp.FilterDescendantsInstances = {char}
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

-- Logic: Anti Fall
local AntiFall = nil
local function createAntiFall()
    if not rootPart then return end
    if AntiFall then AntiFall:Destroy() end
    AntiFall = Instance.new("Part")
    AntiFall.Name = "AntiFall_Circle_800x800"
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
local function removeAntiFall() if AntiFall then AntiFall:Destroy(); AntiFall = nil end end

LP.CharacterAdded:Connect(function()
    task.wait(0.5)
    if State.antiFallEnabled then createAntiFall() end
end)

-- Logic: Anti AFK
local antiAfkConn = nil
local function startAntiAfk()
    if antiAfkConn then return end
    local VirtualUser = game:GetService("VirtualUser")
    antiAfkConn = LP.Idled:Connect(function()
        pcall(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.zero) end)
    end)
end
local function stopAntiAfk() if antiAfkConn then antiAfkConn:Disconnect(); antiAfkConn = nil end end
if State.antiAfkEnabled then startAntiAfk() end

-- Logic: Enter/Exit Base
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

-- Logic: Server Hop
local searchToken = 0
local function GetServers()
    local all = {}
    local cursor = nil
    for page = 1, 5 do
        local url = "https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?limit=100"
        if cursor then url = url .. "&cursor=" .. HttpService:UrlEncode(cursor) end
        local ok, res = pcall(function() return game:HttpGet(url) end)
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

local function FindServer(mode, myToken)
    local best = nil
    for _ = 1, 5 do
        if myToken ~= searchToken then return nil end
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

local function SaveJobs() SaveJSON(JobsFile, SavedJobs) end

-- UI Framework
local ScreenGui = new("ScreenGui", {Name = "SSSHub", ResetOnSpawn = false, DisplayOrder = 999999, Parent = CoreGui})

local Main = new("Frame", {Size = UDim2.new(0, 440, 0, 0), Position = UDim2.new(0.5, -220, 0.5, -155), BackgroundColor3 = Theme.Background, BorderSizePixel = 0, Active = true, Parent = ScreenGui})
corner(Main, 10)
new("UIStroke", {Color = Theme.Stroke, Thickness = 1.5, Parent = Main})

local function MakeDraggable(frame)
    local dragging, dragInput, mousePos, framePos
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; mousePos = input.Position; framePos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - mousePos
            frame.Position = UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset + delta.Y)
        end
    end)
end
MakeDraggable(Main)

local uiScale = new("UIScale", {Scale = 0.92, Parent = Main})
local function updateScale()
    local cam = workspace.CurrentCamera
    if not cam then return end
    local s = math.min(cam.ViewportSize.X / 480, cam.ViewportSize.Y / 350)
    s = math.clamp(s, 0.5, 1.2)
    tw(uiScale, 0.2, {Scale = s})
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

local Sidebar = new("Frame", {Size = UDim2.new(0, 130, 1, 0), BackgroundColor3 = Theme.Sidebar, BorderSizePixel = 0, Parent = Main})
corner(Sidebar, 10)

local Header = new("Frame", {Size = UDim2.new(1, -130, 0, 50), Position = UDim2.new(0, 130, 0, 0), BackgroundTransparency = 1, Parent = Main})
local Logo = new("Frame", {Size = UDim2.new(0, 26, 0, 26), Position = UDim2.new(0, 15, 0.5, -13), BackgroundColor3 = Theme.Accent, Parent = Header})
corner(Logo, 8)
table.insert(AccentTracker.Static, Logo)
new("TextLabel", {Text = "⚡", TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 14, Font = Enum.Font.GothamBold, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Parent = Logo})
new("TextLabel", {Text = "SSS HUB STEAL", TextColor3 = Theme.Text, TextSize = 11, Font = Enum.Font.GothamBold, BackgroundTransparency = 1, Position = UDim2.new(0, 50, 0, 10), Size = UDim2.new(0, 150, 0, 16), TextXAlignment = Enum.TextXAlignment.Left, Parent = Header})
new("TextLabel", {Text = "Game Enhancement", TextColor3 = Theme.TextDark, TextSize = 8, Font = Enum.Font.Gotham, BackgroundTransparency = 1, Position = UDim2.new(0, 50, 0, 27), Size = UDim2.new(0, 200, 0, 12), TextXAlignment = Enum.TextXAlignment.Left, Parent = Header})

local CloseBtn = new("TextButton", {Size = UDim2.new(0, 22, 0, 22), Position = UDim2.new(1, -32, 0, 5), BackgroundColor3 = Color3.fromRGB(80, 30, 30), BorderSizePixel = 0, Text = "X", TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 10, Font = Enum.Font.GothamBold, Parent = Header})
corner(CloseBtn, 6)

local ToggleBtnFloat = new("TextButton", {Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0, 20, 0.5, -20), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Text = "⚡", TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 16, Font = Enum.Font.GothamBold, Visible = false, Parent = ScreenGui})
corner(ToggleBtnFloat, 10)
table.insert(AccentTracker.Static, ToggleBtnFloat)

local function toggleUI(show)
    if show then
        Main.Visible = true
        Main.Size = UDim2.new(0, 440, 0, 0)
        tw(Main, 0.3, {Size = UDim2.new(0, 440, 0, 310)}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        tw(ToggleBtnFloat, 0.2, {Size = UDim2.new(0, 0, 0, 0)})
        task.delay(0.2, function() ToggleBtnFloat.Visible = false end)
    else
        tw(Main, 0.3, {Size = UDim2.new(0, 440, 0, 0)}, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        task.delay(0.3, function() Main.Visible = false end)
        ToggleBtnFloat.Visible = true
        ToggleBtnFloat.Size = UDim2.new(0, 0, 0, 0)
        tw(ToggleBtnFloat, 0.3, {Size = UDim2.new(0, 40, 0, 40)}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    end
end

CloseBtn.MouseButton1Click:Connect(function() toggleUI(false) end)
ToggleBtnFloat.MouseButton1Click:Connect(function() toggleUI(true) end)

local SidebarLayout = new("UIListLayout", {FillDirection = Enum.FillDirection.Vertical, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Top, Padding = UDim.new(0, 5), Parent = Sidebar})
local Pages = {}
local TabButtons = {}
local CurrentActivePage = nil

local function switchTab(tabName)
    for name, page in pairs(Pages) do
        page.Visible = (name == tabName)
        if name == tabName then CurrentActivePage = page end
    end
    for name, data in pairs(TabButtons) do
        if name == tabName then
            tw(data.btn, 0.2, {BackgroundColor3 = CurrentAccent})
            data.btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            data.isActive = true
        else
            tw(data.btn, 0.2, {BackgroundColor3 = Theme.Sidebar})
            data.btn.TextColor3 = Theme.TextDark
            data.isActive = false
        end
    end
end

local function CreateTab(text, icon)
    local TabBtn = new("TextButton", {Size = UDim2.new(0.9, 0, 0, 30), BackgroundColor3 = Theme.Sidebar, BorderSizePixel = 0, Text = "  " .. icon .. "  " .. text, TextColor3 = Theme.TextDark, TextSize = 11, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, Parent = Sidebar})
    corner(TabBtn, 6)
    
    TabBtn.MouseButton1Click:Connect(function() switchTab(text) end)
    TabBtn.MouseEnter:Connect(function()
        if not TabButtons[text] or not TabButtons[text].isActive then tw(TabBtn, 0.2, {BackgroundColor3 = Color3.fromRGB(35, 35, 45)}) end
    end)
    TabBtn.MouseLeave:Connect(function()
        if not TabButtons[text] or not TabButtons[text].isActive then tw(TabBtn, 0.2, {BackgroundColor3 = Theme.Sidebar}) end
    end)
    
    local Page = new("ScrollingFrame", {Size = UDim2.new(1, -150, 1, -60), Position = UDim2.new(0, 135, 0, 55), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2, ScrollBarImageColor3 = Theme.Stroke, Visible = false, Parent = Main})
    local PageLayout = new("UIListLayout", {FillDirection = Enum.FillDirection.Vertical, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Top, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = Page})
    
    PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Page.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + 20)
    end)
    
    Pages[text] = Page
    TabButtons[text] = {btn = TabBtn, isActive = false}
    AccentTracker.Tabs[text] = TabButtons[text]
    return Page
end

new("Frame", {Size = UDim2.new(0.8, 0, 0, 1), BackgroundTransparency = 0.5, BackgroundColor3 = Theme.Stroke, BorderSizePixel = 0, Parent = Sidebar})

local function CreateToggle(parent, opts)
    local cfgKey = opts.cfgKey
    local Container = new("Frame", {Size = UDim2.new(1, -10, 0, 38), BackgroundColor3 = Theme.Card, BorderSizePixel = 0, LayoutOrder = opts.layoutOrder or 0, Name = opts.title, Parent = parent})
    corner(Container, 8)
    new("UIStroke", {Color = Theme.Stroke, Thickness = 1, Parent = Container})
    
    new("TextLabel", {Text = opts.title, TextColor3 = Theme.Text, TextSize = 12, Font = Enum.Font.GothamBold, BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -120, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, Parent = Container})
    
    local ToggleBtn = new("TextButton", {Size = UDim2.new(0, 38, 0, 19), Position = UDim2.new(1, -48, 0.5, -10), BackgroundColor3 = Theme.ToggleOff, BorderSizePixel = 0, Text = "", Parent = Container})
    corner(ToggleBtn, 1)
    local Circle = new("Frame", {Size = UDim2.new(0, 15, 0, 15), Position = UDim2.new(0, 2, 0.5, -8), BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0, Parent = ToggleBtn})
    corner(Circle, 1)
    
    local state = false
    local toggleData = {btn = ToggleBtn, isOn = false}
    table.insert(AccentTracker.Toggles, toggleData)
    
    local function setToggleState(newState, silent)
        state = newState
        toggleData.isOn = newState
        tw(Circle, 0.2, {Position = state and UDim2.new(1, -17, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        tw(ToggleBtn, 0.2, {BackgroundColor3 = state and Theme.ToggleOn or Theme.ToggleOff}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        if not silent then
            if cfgKey then
                State[cfgKey] = newState
                Config[cfgKey] = newState
                if State.saveConfigEnabled then SaveConfig() end
            end
            if opts.callback then opts.callback(newState) end
        end
    end
    
    ToggleBtn.MouseButton1Click:Connect(function() setToggleState(not state) end)
    
    if cfgKey and State[cfgKey] then
        task.spawn(function() task.wait(0.1); setToggleState(true, true) end)
    end
    
    return Container
end

local function CreateButton(parent, opts)
    local btn = new("TextButton", {Size = UDim2.new(1, -10, 0, 33), BackgroundColor3 = Theme.Card, BorderSizePixel = 0, Text = opts.title, TextColor3 = Theme.Text, TextSize = 11, Font = Enum.Font.GothamBold, LayoutOrder = opts.layoutOrder or 0, Name = opts.title, Parent = parent})
    corner(btn, 8)
    new("UIStroke", {Color = Theme.Stroke, Thickness = 1, Parent = btn})
    AddHover(btn, Theme.Card, Theme.CardHover)
    btn.MouseButton1Click:Connect(function() if opts.callback then opts.callback() end end)
    return btn
end

local function CreatePopupMenu(title, width, height)
    local menu = new("Frame", {Size = UDim2.new(0, width, 0, height), Position = UDim2.new(0.5, -width/2, 0.5, -height/2), BackgroundColor3 = Theme.Card, BorderSizePixel = 0, Visible = false, Active = true, ZIndex = 20, Parent = ScreenGui})
    MakeDraggable(menu)
    corner(menu, 8)
    new("UIStroke", {Color = Theme.Stroke, Thickness = 1.5, Parent = menu})
    new("TextLabel", {Text = title, TextColor3 = Theme.Text, TextSize = 12, Font = Enum.Font.GothamBold, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 5), Size = UDim2.new(1, -10, 0, 25), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 21, Parent = menu})
    local closeBtn = new("TextButton", {Text = "X", TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 9, Font = Enum.Font.GothamBold, BackgroundColor3 = Color3.fromRGB(80, 30, 30), BorderSizePixel = 0, Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(1, -25, 0, 5), ZIndex = 21, Parent = menu})
    corner(closeBtn, 5)
    closeBtn.MouseButton1Click:Connect(function() menu.Visible = false end)
    return menu
end

-- Keybind System
local isListeningKeybind = false
local KeybindRegistry = {}

local function CreateKeybindButton(parent, name, defaultKey, callback)
    local currentKey = Keybinds[name] or defaultKey
    local keyBtn = new("TextButton", {Size = UDim2.new(0, 35, 0, 18), Position = UDim2.new(1, -80, 0.5, -9), BackgroundColor3 = Theme.Background, BorderSizePixel = 0, Text = currentKey or "None", TextColor3 = Theme.TextDark, TextSize = 9, Font = Enum.Font.GothamBold, Parent = parent})
    corner(keyBtn, 4)
    new("UIStroke", {Color = Theme.Stroke, Thickness = 1, Parent = keyBtn})
    
    if currentKey then
        KeybindRegistry[name] = {Key = currentKey, Callback = callback}
    end
    
    keyBtn.MouseButton1Click:Connect(function()
        if isListeningKeybind then return end
        isListeningKeybind = true
        keyBtn.Text = "..."
        tw(keyBtn, 0.1, {BackgroundColor3 = CurrentAccent})
        
        local conn
        conn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            if input.KeyCode == Enum.KeyCode.Escape then
                keyBtn.Text = currentKey or "None"
                tw(keyBtn, 0.1, {BackgroundColor3 = Theme.Background})
                isListeningKeybind = false
                conn:Disconnect()
                return
            end
            if input.UserInputType == Enum.UserInputType.Keyboard then
                currentKey = input.KeyCode.Name
                Keybinds[name] = currentKey
                if State.saveConfigEnabled then SaveConfig() end
                KeybindRegistry[name] = {Key = currentKey, Callback = callback}
                keyBtn.Text = currentKey
                tw(keyBtn, 0.1, {BackgroundColor3 = Theme.Background})
                isListeningKeybind = false
                conn:Disconnect()
                notify("Keybind", name .. " → " .. currentKey, "success")
            end
        end)
    end)
    return keyBtn
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or isListeningKeybind then return end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        local k = input.KeyCode.Name
        for _, bind in pairs(KeybindRegistry) do
            if bind.Key == k and bind.Callback then bind.Callback() end
        end
    end
end)

-- Build Pages
local BypassMenu = CreatePopupMenu("BYPASS", 200, 200)
local PetFilterMenu = CreatePopupMenu("PET FILTERS", 240, 160)

local MainPage = CreateTab("Main", "🏠")
local CombatPage = CreateTab("Combat", "⚔️")
local ServerPage = CreateTab("Server", "📡")
local SettingsPage = CreateTab("Settings", "⚙️")

-- MAIN PAGE
CreateToggle(MainPage, {title="Auto Run", cfgKey="autoRun", layoutOrder=1, callback=function(v) notify("Auto Run", v and "Enabled" or "Disabled", "info") end})
CreateToggle(MainPage, {title="Player ESP", cfgKey="espEnabled", layoutOrder=2, callback=function(v) updateESP(); notify("Player ESP", v and "Enabled" or "Disabled", "info") end})
CreateToggle(MainPage, {title="Pets ESP", cfgKey="petsEspEnabled", layoutOrder=3, callback=function(v)
    if not v then for pet, _ in pairs(PetTracker) do removePetESP(pet) end end
    notify("Pets ESP", v and "Enabled" or "Disabled", "info")
end})
CreateToggle(MainPage, {title="Anti Fall", cfgKey="antiFallEnabled", layoutOrder=4, callback=function(v)
    if v then createAntiFall() else removeAntiFall() end
    notify("Anti Fall", v and "Enabled" or "Disabled", "info")
end})
CreateToggle(MainPage, {title="Anti AFK", cfgKey="antiAfkEnabled", layoutOrder=5, callback=function(v)
    if v then startAntiAfk() else stopAntiAfk() end
    notify("Anti AFK", v and "Enabled" or "Disabled", "info")
end})

CreateButton(MainPage, {title="Pet Filter", layoutOrder=6, callback=function() PetFilterMenu.Visible = not PetFilterMenu.Visible end})
CreateButton(MainPage, {title="Bypass Menu", layoutOrder=7, callback=function() BypassMenu.Visible = not BypassMenu.Visible end})

-- COMBAT PAGE
CreateToggle(CombatPage, {title="Anti Knockback", cfgKey="antiKnockbackEnabled", layoutOrder=1, callback=function(v)
    if v then startAntiKnockback() else stopAntiKnockback() end
    notify("Anti Knockback", v and "Enabled" or "Disabled", "info")
end})
CreateToggle(CombatPage, {title="Auto Lock Base", cfgKey="autoLockEnabled", layoutOrder=2, callback=function(v)
    if v then startAutoLock() else stopAutoLock() end
    notify("Auto Lock", v and "Enabled" or "Disabled", "info")
end})

-- BYPASS MENU CONTENT
local whRow = new("Frame", {Size = UDim2.new(0, 180, 0, 35), Position = UDim2.new(0, 10, 0, 35), BackgroundColor3 = Theme.Background, BorderSizePixel = 0, ZIndex = 21, Parent = BypassMenu})
corner(whRow, 6)
new("TextLabel", {Text = "Wall Hop", TextColor3 = Theme.Text, TextSize = 11, Font = Enum.Font.GothamBold, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(1, -50, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 22, Parent = whRow})

local whTrack = new("Frame", {Size = UDim2.new(0, 38, 0, 19), Position = UDim2.new(1, -44, 0.5, -10), BackgroundColor3 = Theme.ToggleOff, BorderSizePixel = 0, ZIndex = 22, Parent = whRow})
corner(whTrack, 1)
local whCircle = new("Frame", {Size = UDim2.new(0, 15, 0, 15), Position = UDim2.new(0, 2, 0.5, -8), BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0, ZIndex = 23, Parent = whTrack})
corner(whCircle, 1)

local whToggleData = {btn = whTrack, isOn = false}
table.insert(AccentTracker.Toggles, whToggleData)

local function setWallHop(v)
    State.wallHopEnabled = v
    whToggleData.isOn = v
    Config.wallHopEnabled = v
    if State.saveConfigEnabled then SaveConfig() end
    tw(whCircle, 0.2, {Position = v and UDim2.new(1, -17, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    tw(whTrack, 0.2, {BackgroundColor3 = v and Theme.ToggleOn or Theme.ToggleOff}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    notify("Wall Hop", v and "Enabled" or "Disabled", "info")
end

new("TextButton", {Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), ZIndex = 24, Parent = whRow}).MouseButton1Click:Connect(function()
    setWallHop(not State.wallHopEnabled)
end)

if State.wallHopEnabled then
    task.spawn(function()
        task.wait(0.2)
        setWallHop(true)
    end)
end

local enterBtn = new("TextButton", {Text = "Enter Base", TextColor3 = Theme.Text, TextSize = 11, Font = Enum.Font.GothamBold, BackgroundColor3 = Theme.Background, BorderSizePixel = 0, Size = UDim2.new(0, 180, 0, 30), Position = UDim2.new(0, 10, 0, 80), ZIndex = 21, Parent = BypassMenu})
corner(enterBtn, 6)
AddHover(enterBtn, Theme.Background, Theme.CardHover)
enterBtn.MouseButton1Click:Connect(function()
    smoothVerticalMove(17, -1)
    notify("Enter Base", "Moving down", "info")
end)

local exitBtn = new("TextButton", {Text = "Exit Base", TextColor3 = Theme.Text, TextSize = 11, Font = Enum.Font.GothamBold, BackgroundColor3 = Theme.Background, BorderSizePixel = 0, Size = UDim2.new(0, 180, 0, 30), Position = UDim2.new(0, 10, 0, 120), ZIndex = 21, Parent = BypassMenu})
corner(exitBtn, 6)
AddHover(exitBtn, Theme.Background, Theme.CardHover)
exitBtn.MouseButton1Click:Connect(function()
    smoothVerticalMove(20, 1)
    notify("Exit Base", "Moving up", "info")
end)

-- PET FILTER MENU CONTENT
new("TextLabel", {Text = "Name:", TextColor3 = Theme.TextDark, TextSize = 10, Font = Enum.Font.Gotham, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 35), Size = UDim2.new(0, 40, 0, 18), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 21, Parent = PetFilterMenu})
local nameBox = new("TextBox", {Text = "", PlaceholderText = "e.g. Dragon", TextColor3 = Theme.Text, PlaceholderColor3 = Theme.TextDark, TextSize = 10, Font = Enum.Font.Gotham, BackgroundColor3 = Theme.Background, BorderSizePixel = 0, Size = UDim2.new(0, 130, 0, 22), Position = UDim2.new(0, 60, 0, 33), ZIndex = 21, Parent = PetFilterMenu})
corner(nameBox, 6)
new("UIStroke", {Color = Theme.Stroke, Thickness = 1, Parent = nameBox})

new("TextLabel", {Text = "Min MPS:", TextColor3 = Theme.TextDark, TextSize = 10, Font = Enum.Font.Gotham, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 65), Size = UDim2.new(0, 40, 0, 18), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 21, Parent = PetFilterMenu})
local mpsBox = new("TextBox", {Text = "0", TextColor3 = Theme.Text, TextSize = 10, Font = Enum.Font.Gotham, BackgroundColor3 = Theme.Background, BorderSizePixel = 0, Size = UDim2.new(0, 130, 0, 22), Position = UDim2.new(0, 60, 0, 63), ZIndex = 21, Parent = PetFilterMenu})
corner(mpsBox, 6)
new("UIStroke", {Color = Theme.Stroke, Thickness = 1, Parent = mpsBox})

local applyBtn = new("TextButton", {Text = "APPLY", TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 10, Font = Enum.Font.GothamBold, BackgroundColor3 = Color3.fromRGB(40, 100, 60), BorderSizePixel = 0, Size = UDim2.new(0, 95, 0, 28), Position = UDim2.new(0, 20, 0, 105), ZIndex = 21, Parent = PetFilterMenu})
corner(applyBtn, 6)
AddHover(applyBtn, Color3.fromRGB(40, 100, 60), Color3.fromRGB(50, 120, 70))

local clearBtn = new("TextButton", {Text = "CLEAR", TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 10, Font = Enum.Font.GothamBold, BackgroundColor3 = Color3.fromRGB(100, 40, 40), BorderSizePixel = 0, Size = UDim2.new(0, 95, 0, 28), Position = UDim2.new(0, 125, 0, 105), ZIndex = 21, Parent = PetFilterMenu})
corner(clearBtn, 6)
AddHover(clearBtn, Color3.fromRGB(100, 40, 40), Color3.fromRGB(120, 50, 50))

applyBtn.MouseButton1Click:Connect(function()
    petFilterName = nameBox.Text
    local txt = mpsBox.Text:lower()
    local mult = 1
    if txt:find("k") then mult = 1000
    elseif txt:find("m") then mult = 1000000
    elseif txt:find("b") then mult = 1000000000 end
    local num = tonumber(txt:gsub("[^%d%.]", ""))
    petFilterMPS = num and num * mult or 0
    PetFilterMenu.Visible = false
    notify("Pet Filter", "Applied successfully", "success")
end)

clearBtn.MouseButton1Click:Connect(function()
    nameBox.Text = ""
    mpsBox.Text = "0"
    petFilterName = ""
    petFilterMPS = 0
    notify("Pet Filter", "Cleared", "info")
end)

-- SERVER PAGE
local statusLbl = new("TextLabel", {Text = "Saved Jobs: " .. #SavedJobs, TextColor3 = Theme.TextDark, TextSize = 10, Font = Enum.Font.GothamBold, BackgroundTransparency = 1, Size = UDim2.new(1, -10, 0, 18), LayoutOrder = 0, TextXAlignment = Enum.TextXAlignment.Left, Parent = ServerPage})

CreateButton(ServerPage, {title="Copy & Save Job", layoutOrder=1, callback=function()
    local jid = game.JobId
    if #SavedJobs >= 10 then notify("Server Hop", "Max 10 saved jobs!", "warning") return end
    for _, d in ipairs(SavedJobs) do
        if d.JobId == jid then notify("Server Hop", "Already saved!", "warning") return end
    end
    table.insert(SavedJobs, {JobId = jid, Name = "Server " .. (#SavedJobs + 1)})
    SaveJobs()
    if setclipboard then setclipboard(jid) end
    statusLbl.Text = "Saved Jobs: " .. #SavedJobs
    UpdateServerList()
    notify("Server Hop", "Saved & Copied!", "success")
end})

CreateButton(ServerPage, {title="Reconnect", layoutOrder=2, callback=function()
    pcall(function() TeleportService:TeleportToPlaceInstance(PlaceId, game.JobId, LP) end)
end})

CreateButton(ServerPage, {title="Join Busy Server", layoutOrder=3, callback=function()
    searchToken = searchToken + 1
    local myToken = searchToken
    statusLbl.Text = "Searching busy..."
    local s = FindServer("BUSY", myToken)
    if s and myToken == searchToken then
        statusLbl.Text = "Joining: " .. s.playing .. "/" .. s.maxPlayers
        task.wait(0.5)
        pcall(function() TeleportService:TeleportToPlaceInstance(PlaceId, s.id, LP) end)
    elseif myToken == searchToken then
        statusLbl.Text = "Not found!"
        notify("Server Hop", "No busy servers found", "warning")
    end
end})

CreateButton(ServerPage, {title="Join Empty Server", layoutOrder=4, callback=function()
    searchToken = searchToken + 1
    local myToken = searchToken
    statusLbl.Text = "Searching empty..."
    local s = FindServer("EMPTY", myToken)
    if s and myToken == searchToken then
        statusLbl.Text = "Joining: " .. s.playing .. "/" .. s.maxPlayers
        task.wait(0.5)
        pcall(function() TeleportService:TeleportToPlaceInstance(PlaceId, s.id, LP) end)
    elseif myToken == searchToken then
        statusLbl.Text = "Not found!"
        notify("Server Hop", "No empty servers found", "warning")
    end
end})

local serverSep = new("Frame", {Size = UDim2.new(1, -10, 0, 1), BackgroundColor3 = Theme.Stroke, BackgroundTransparency = 0.5, BorderSizePixel = 0, LayoutOrder = 5, Parent = ServerPage})
local ServerListContainer = new("Frame", {Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, LayoutOrder = 6, AutomaticSize = Enum.AutomaticSize.Y, Parent = ServerPage})
new("UIListLayout", {Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder, Parent = ServerListContainer})

function UpdateServerList()
    for _, c in ipairs(ServerListContainer:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    for i, d in ipairs(SavedJobs) do
        local row = new("Frame", {Size = UDim2.new(1, -4, 0, 30), BackgroundColor3 = Theme.Card, BorderSizePixel = 0, LayoutOrder = i, Parent = ServerListContainer})
        corner(row, 6)
        new("UIStroke", {Color = Theme.Stroke, Thickness = 1, Parent = row})
        new("TextLabel", {Text = d.Name or ("Server " .. i), TextColor3 = Theme.Text, TextSize = 10, Font = Enum.Font.Gotham, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(1, -100, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, Parent = row})
        
        local jBtn = new("TextButton", {Text = "JOIN", TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 9, Font = Enum.Font.GothamBold, BackgroundColor3 = Color3.fromRGB(40, 80, 50), BorderSizePixel = 0, Size = UDim2.new(0, 45, 1, -8), Position = UDim2.new(1, -100, 0, 4), Parent = row})
        corner(jBtn, 4)
        AddHover(jBtn, Color3.fromRGB(40, 80, 50), Color3.fromRGB(50, 100, 60))
        jBtn.MouseButton1Click:Connect(function()
            pcall(function() TeleportService:TeleportToPlaceInstance(PlaceId, d.JobId, LP) end)
        end)
        
        local dBtn = new("TextButton", {Text = "X", TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 9, Font = Enum.Font.GothamBold, BackgroundColor3 = Color3.fromRGB(80, 40, 40), BorderSizePixel = 0, Size = UDim2.new(0, 35, 1, -8), Position = UDim2.new(1, -45, 0, 4), Parent = row})
        corner(dBtn, 4)
        AddHover(dBtn, Color3.fromRGB(80, 40, 40), Color3.fromRGB(100, 50, 50))
        dBtn.MouseButton1Click:Connect(function()
            table.remove(SavedJobs, i)
            SaveJobs()
            statusLbl.Text = "Saved Jobs: " .. #SavedJobs
            UpdateServerList()
        end)
    end
end

-- SETTINGS PAGE
CreateToggle(SettingsPage, {title="Save Config", cfgKey="saveConfigEnabled", layoutOrder=1, callback=function(v) notify("Config", v and "Auto-save enabled" or "Auto-save disabled", v and "success" or "warning") end})

new("TextLabel", {Text = "Accent Color", TextColor3 = Theme.Text, TextSize = 12, Font = Enum.Font.GothamBold, BackgroundTransparency = 1, Size = UDim2.new(1, -10, 0, 20), LayoutOrder = 2, TextXAlignment = Enum.TextXAlignment.Left, Parent = SettingsPage})
local colorRow = new("Frame", {Size = UDim2.new(1, -10, 0, 40), BackgroundTransparency = 1, LayoutOrder = 3, Parent = SettingsPage})
new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, Parent = colorRow})

local ColorPresets = {
    {name = "Purple", color = Color3.fromRGB(120, 80, 220)},
    {name = "Blue", color = Color3.fromRGB(80, 120, 220)},
    {name = "Red", color = Color3.fromRGB(220, 80, 80)},
    {name = "Green", color = Color3.fromRGB(80, 180, 100)},
    {name = "Orange", color = Color3.fromRGB(220, 150, 50)},
    {name = "Pink", color = Color3.fromRGB(220, 80, 180)},
    {name = "Cyan", color = Color3.fromRGB(80, 200, 220)},
    {name = "White", color = Color3.fromRGB(200, 200, 210)}
}

local selectedSwatchStroke = nil
for _, preset in ipairs(ColorPresets) do
    local swatch = new("TextButton", {Size = UDim2.new(0, 28, 0, 28), BackgroundColor3 = preset.color, BorderSizePixel = 0, Text = "", Parent = colorRow})
    corner(swatch, 6)
    local stroke = new("UIStroke", {Color = Color3.fromRGB(255, 255, 255), Thickness = 0, Parent = swatch})
    if CurrentAccent == preset.color then
        stroke.Thickness = 2
        selectedSwatchStroke = stroke
    end
    swatch.MouseButton1Click:Connect(function()
        if selectedSwatchStroke then selectedSwatchStroke.Thickness = 0 end
        stroke.Thickness = 2
        selectedSwatchStroke = stroke
        SetAccent(preset.color)
        notify("Accent Color", preset.name, "success")
    end)
end

-- RIGHTCTRL TOGGLE (ДЛЯ ПК)
local visible = true
UserInputService.InputBegan:Connect(function(inp, gp)
    if gp then return end
    if inp.KeyCode == Enum.KeyCode.RightControl then
        visible = not visible
        toggleUI(visible)
    end
end)

-- Init
switchTab("Main")
UpdateServerList()
tw(Main, 0.5, {Size = UDim2.new(0, 440, 0, 310)}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
notify("SSS HUB", "Welcome! RightCtrl or ⚡ to toggle.", "info")
