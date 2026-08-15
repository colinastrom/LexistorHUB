--// SSSHUB STEAL + MAIN (FINAL FIX)
--// By Rosomax0 • Developer
--// UI REDESIGNED BY ENI

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId
local CoreGui = game:GetService("CoreGui")

--------------------------------------------------
-- CLEANUP SYSTEM
--------------------------------------------------
local CleanupConnections = {}
local CleanupTasks = {}
local CleanupExtra = {}

local function TrackConnection(conn)
    table.insert(CleanupConnections, conn)
    return conn
end

local function TrackTask(t)
    table.insert(CleanupTasks, t)
    return t
end

local env = (getgenv and getgenv()) or _G
if env.SSSHubCleanup then pcall(env.SSSHubCleanup) end

env.SSSHubCleanup = function()
    for _, conn in ipairs(CleanupConnections) do
        pcall(function() conn:Disconnect() end)
    end
    for _, t in ipairs(CleanupTasks) do
        pcall(function() task.cancel(t) end)
    end
    for _, fn in ipairs(CleanupExtra) do
        pcall(fn)
    end
    if CoreGui:FindFirstChild("SSSHubSteal") then CoreGui.SSSHubSteal:Destroy() end
    if CoreGui:FindFirstChild("SSSNotify") then CoreGui.SSSNotify:Destroy() end
    if CoreGui:FindFirstChild("SSSPopups") then CoreGui.SSSPopups:Destroy() end
    env.SSSHubCleanup = nil
end

if CoreGui:FindFirstChild("SSSHubSteal") then CoreGui.SSSHubSteal:Destroy() end
if CoreGui:FindFirstChild("SSSNotify") then CoreGui.SSSNotify:Destroy() end
if CoreGui:FindFirstChild("SSSPopups") then CoreGui.SSSPopups:Destroy() end

--------------------------------------------------
-- HELPERS
--------------------------------------------------
local function new(cls, props, parent)
    local inst = Instance.new(cls)
    if props then
        for k, v in pairs(props) do inst[k] = v end
    end
    inst.Parent = parent
    return inst
end

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
    Info = Color3.fromRGB(80, 120, 220),
    EnterBase = Color3.fromRGB(45, 120, 220),
    ExitBase = Color3.fromRGB(220, 80, 80)
}

--------------------------------------------------
-- CONFIG SYSTEM
--------------------------------------------------
local ConfigFile = "SSSHubConfig.json"
local Config = {}
local SaveConfigEnabled = true

local function LoadConfig()
    if isfile and isfile(ConfigFile) then
        local success, data = pcall(function() return HttpService:JSONDecode(readfile(ConfigFile)) end)
        if success and type(data) == "table" then Config = data end
    end
end

local function SaveConfig()
    if not SaveConfigEnabled then return end
    if writefile then writefile(ConfigFile, HttpService:JSONEncode(Config)) end
end

LoadConfig()

if Config.SaveConfigEnabled ~= nil then
    SaveConfigEnabled = Config.SaveConfigEnabled
end

local Keybinds = Config.Keybinds or {}

local function GetKeybind(name, default)
    return Keybinds[name] or default
end

local function SetKeybind(name, key)
    Keybinds[name] = key
    Config.Keybinds = Keybinds
    SaveConfig()
end

--------------------------------------------------
-- ACCENT COLOR SYSTEM
--------------------------------------------------
local AccentTracker = { Static = {}, Toggles = {}, Tabs = {} }
local CurrentAccent = Theme.Accent

local function SetAccent(color)
    Theme.Accent = color
    Theme.ToggleOn = color
    CurrentAccent = color
    Config.AccentColor = {math.floor(color.R * 255), math.floor(color.G * 255), math.floor(color.B * 255)}
    SaveConfig()
    for _, elem in ipairs(AccentTracker.Static) do
        if elem and elem.Parent then
            TweenService:Create(elem, TweenInfo.new(0.2), {BackgroundColor3 = color}):Play()
        end
    end
    for _, toggle in ipairs(AccentTracker.Toggles) do
        if toggle.isOn then
            TweenService:Create(toggle.btn, TweenInfo.new(0.2), {BackgroundColor3 = color}):Play()
        end
    end
    for _, tabData in pairs(AccentTracker.Tabs) do
        if tabData.isActive then
            TweenService:Create(tabData.btn, TweenInfo.new(0.2), {BackgroundColor3 = color}):Play()
        end
    end
end

if Config.AccentColor then
    local c = Config.AccentColor
    SetAccent(Color3.fromRGB(c[1], c[2], c[3]))
end

--------------------------------------------------
-- GUI LAYERS (Раздельные ScreenGui для правильного наложения)
--------------------------------------------------
local ScreenGui = new("ScreenGui", {Name = "SSSHubSteal", ResetOnSpawn = false, DisplayOrder = 999998}, CoreGui)
local PopupGui = new("ScreenGui", {Name = "SSSPopups", ResetOnSpawn = false, DisplayOrder = 1000000}, CoreGui)
local NotifyGui = new("ScreenGui", {Name = "SSSNotify", ResetOnSpawn = false, DisplayOrder = 1000001}, CoreGui)

--------------------------------------------------
-- NOTIFICATION SYSTEM
--------------------------------------------------
local NotifyHolder = new("Frame", {Size = UDim2.new(0, 300, 0, 0), Position = UDim2.new(1, -320, 0, 20), BackgroundTransparency = 1, Active = false, AutomaticSize = Enum.AutomaticSize.Y}, NotifyGui)
new("UIListLayout", {FillDirection = Enum.FillDirection.Vertical, HorizontalAlignment = Enum.HorizontalAlignment.Right, VerticalAlignment = Enum.VerticalAlignment.Top, Padding = UDim.new(0, 10)}, NotifyHolder)

local function notify(title, text, notifType)
    notifType = notifType or "success"
    local iconColor = Theme.Success
    local iconText = "🛡"
    if notifType == "warning" then iconColor = Theme.Warning; iconText = "⚠"
    elseif notifType == "error" then iconColor = Theme.Error; iconText = "✕"
    elseif notifType == "info" then iconColor = Theme.Info; iconText = "ℹ" end

    local notif = new("Frame", {Size = UDim2.new(0, 280, 0, 70), Position = UDim2.new(0, 300, 0, 0), BackgroundColor3 = Theme.Card, BorderSizePixel = 0, Active = false}, NotifyHolder)
    new("UICorner", {CornerRadius = UDim.new(0, 8)}, notif)
    local stroke = new("UIStroke", {Color = Theme.Stroke, Thickness = 1.5}, notif)

    local iconCircle = new("Frame", {Size = UDim2.new(0, 40, 0, 40), Position = UDim2.new(0, 12, 0.5, -20), BackgroundColor3 = iconColor, BorderSizePixel = 0, Active = false}, notif)
    new("UICorner", {CornerRadius = UDim.new(1, 0)}, iconCircle)
    new("TextLabel", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = iconText, TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 18, Font = Enum.Font.GothamBold, Active = false}, iconCircle)

    new("TextLabel", {Size = UDim2.new(1, -70, 0, 20), Position = UDim2.new(0, 62, 0, 15), BackgroundTransparency = 1, Text = title, TextColor3 = Theme.Text, Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, Active = false}, notif)
    new("TextLabel", {Size = UDim2.new(1, -70, 0, 16), Position = UDim2.new(0, 62, 0, 38), BackgroundTransparency = 1, Text = text, TextColor3 = Theme.TextDark, Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Active = false}, notif)

    local progress = new("Frame", {Size = UDim2.new(1, 0, 0, 3), Position = UDim2.new(0, 0, 1, -3), BackgroundColor3 = iconColor, BorderSizePixel = 0, Active = false}, notif)
    new("UICorner", {CornerRadius = UDim.new(1, 0)}, progress)

    notif.BackgroundTransparency = 1
    iconCircle.BackgroundTransparency = 1
    progress.BackgroundTransparency = 1
    stroke.Transparency = 1

    TweenService:Create(notif, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 0}):Play()
    TweenService:Create(stroke, TweenInfo.new(0.4), {Transparency = 0}):Play()
    TweenService:Create(iconCircle, TweenInfo.new(0.4), {BackgroundTransparency = 0}):Play()
    TweenService:Create(progress, TweenInfo.new(0.4), {BackgroundTransparency = 0}):Play()

    task.delay(0.4, function() TweenService:Create(progress, TweenInfo.new(2.6), {Size = UDim2.new(0, 0, 0, 3)}):Play() end)
    task.delay(3, function()
        local tweenOut = TweenService:Create(notif, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {Position = UDim2.new(0, 300, 0, 0), BackgroundTransparency = 1})
        tweenOut:Play()
        TweenService:Create(stroke, TweenInfo.new(0.4), {Transparency = 1}):Play()
        TweenService:Create(iconCircle, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
        TweenService:Create(progress, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
        tweenOut.Completed:Wait()
        notif:Destroy()
    end)
end

--------------------------------------------------
-- SOUND & DRAGGABLE
--------------------------------------------------
local ClickSound = new("Sound", {SoundId = "rbxassetid://6895056283", Volume = 0.4}, NotifyGui)
local function playClick() pcall(function() ClickSound:Play() end) end

local function MakeDraggable(frame)
    local dragging, dragInput, mousePos, framePos
    TrackConnection(frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; mousePos = input.Position; framePos = frame.Position
            local endConn
            endConn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    endConn:Disconnect()
                end
            end)
        end
    end))
    TrackConnection(frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end))
    TrackConnection(UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - mousePos
            frame.Position = UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset + delta.Y)
        end
    end))
end

--------------------------------------------------
-- SETTINGS & STATE
--------------------------------------------------
local autoRunSpeed = (Config.AutoRunSpeed and Config.AutoRunSpeed > 0) and Config.AutoRunSpeed or 38
local wallHopPower = (Config.WallHopPower and Config.WallHopPower > 0) and Config.WallHopPower or 80
local wallHopDuration = (Config.WallHopDuration and Config.WallHopDuration > 0) and Config.WallHopDuration or 0.3

local UP_DISTANCE = 20
local DOWN_DISTANCE = 17

local autoRun = Config["Auto Run"] or false
local espEnabled = Config["Player ESP"] or false
local petsEspEnabled = Config["Pets ESP"] or false
local antiFallEnabled = Config["Anti Fall"] or false
local antiAfkEnabled = Config["Anti AFK"] or false
local antiKnockbackEnabled = Config["Anti Knockback"] or false
local autoLockEnabled = Config["Auto Lock Base"] or false
local wallHopEnabled = Config["Wall Hop"] or false

local humanoid = nil
local rootPart = nil
local normalSpeed = 16

local ESPs = {}
local AntiFall = nil
local antiKnockbackConnection = nil
local autoLockConnection = nil
local antiAfkConnection = nil
local autoRunConnection = nil

local LOCK_STATE_ATTR = "LockState"
local STATE_IDLE = "Idle"
local STATE_LOCKED = "Locked"

local lastJumpTime = 0

local function setupCharacter(character)
    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")
    normalSpeed = humanoid.WalkSpeed
    TrackConnection(humanoid.StateChanged:Connect(function(_, newState)
        if newState == Enum.HumanoidStateType.Jumping then lastJumpTime = os.clock() end
    end))
end
if LocalPlayer.Character then setupCharacter(LocalPlayer.Character) end
TrackConnection(LocalPlayer.CharacterAdded:Connect(setupCharacter))

--------------------------------------------------
-- AUTO RUN
--------------------------------------------------
local function startAutoRun()
    if autoRunConnection then return end
    autoRunConnection = TrackConnection(RunService.Heartbeat:Connect(function()
        if humanoid and humanoid.Health > 0 then
            humanoid.WalkSpeed = autoRunSpeed
            local camera = workspace.CurrentCamera
            if camera then
                local lookVector = camera.CFrame.LookVector
                humanoid:Move(Vector3.new(lookVector.X, 0, lookVector.Z), false)
            end
        end
    end))
end

local function stopAutoRun()
    if autoRunConnection then autoRunConnection:Disconnect(); autoRunConnection = nil end
    if humanoid and humanoid.Health > 0 then humanoid.WalkSpeed = normalSpeed end
end

--------------------------------------------------
-- PLAYER ESP
--------------------------------------------------
local function removeESP(player) if ESPs[player] then ESPs[player]:Destroy(); ESPs[player] = nil end end

local function createESP(player, character)
    if player == LocalPlayer then return end
    removeESP(player)
    local folder = new("Folder", {Name = "PlayerESP"}, character)
    new("Highlight", {Adornee = character, DepthMode = Enum.HighlightDepthMode.AlwaysOnTop, FillTransparency = 0.75, OutlineTransparency = 0, FillColor = Color3.fromRGB(255, 255, 255), OutlineColor = Color3.fromRGB(255, 255, 255), Enabled = espEnabled}, folder)
    local head = character:FindFirstChild("Head")
    if head then
        local billboard = new("BillboardGui", {Name = "ESP_Name", Adornee = head, Size = UDim2.new(0, 120, 0, 20), StudsOffset = Vector3.new(0, 2.5, 0), AlwaysOnTop = true, Enabled = espEnabled}, folder)
        local text = new("TextLabel", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = player.Name, TextStrokeTransparency = 0.5, TextSize = 15, Font = Enum.Font.GothamBold}, billboard)
        task.spawn(function()
            local hue = 0
            while text.Parent do
                hue = (hue + 0.01) % 1
                text.TextColor3 = Color3.fromHSV(hue, 1, 1)
                task.wait(0.03)
            end
        end)
    end
    ESPs[player] = folder
end

local function updateESP()
    for _, folder in pairs(ESPs) do
        if folder and folder.Parent then
            for _, object in ipairs(folder:GetChildren()) do
                if object:IsA("Highlight") or object:IsA("BillboardGui") then object.Enabled = espEnabled end
            end
        end
    end
end

local function setupESP(player)
    if player == LocalPlayer then return end
    TrackConnection(player.CharacterAdded:Connect(function(character) task.wait(0.5); createESP(player, character) end))
    if player.Character then createESP(player, player.Character) end
end

for _, player in ipairs(Players:GetPlayers()) do setupESP(player) end
TrackConnection(Players.PlayerAdded:Connect(setupESP))
TrackConnection(Players.PlayerRemoving:Connect(function(player) removeESP(player) end))

table.insert(CleanupExtra, function()
    for player, folder in pairs(ESPs) do pcall(function() folder:Destroy() end); ESPs[player] = nil end
end)

--------------------------------------------------
-- PETS ESP
--------------------------------------------------
local espTracker = {}
local petFilterName = ""
local petFilterMPS = 0

local function removePetESP(pet)
    local esp = espTracker[pet]
    if esp then
        if esp.billboard then esp.billboard:Destroy() end
        if esp.highlight then esp.highlight:Destroy() end
        espTracker[pet] = nil
    end
end

local function getPetName(pet) return pet:GetAttribute("Species") or pet.Name end
local function getPetMPS(pet)
    local tag = pet:FindFirstChild("ItemNameTag", true)
    if tag then
        local mpsLabel = tag:FindFirstChild("MPS", true)
        if mpsLabel and mpsLabel:IsA("TextLabel") and mpsLabel.Text ~= "" then return mpsLabel.Text end
    end
    return "?"
end

local function getPetMPSValue(pet)
    local mpsText = getPetMPS(pet)
    local lowerText = mpsText:lower()
    local mult = 1
    if lowerText:find("k") then mult = 1000
    elseif lowerText:find("m") then mult = 1000000
    elseif lowerText:find("b") then mult = 1000000000 end
    local numStr = mpsText:gsub("[^%d%.]", "")
    local val = tonumber(numStr)
    if val then return val * mult end
    return 0
end

local function getPetMutation(pet)
    local tag = pet:FindFirstChild("ItemNameTag", true)
    if tag then
        local mutLabel = tag:FindFirstChild("Mutation", true)
        if mutLabel and mutLabel:IsA("TextLabel") and mutLabel.Text ~= "" and mutLabel.Visible then return mutLabel.Text end
    end
    local mutAttr = pet:GetAttribute("Mutation")
    if mutAttr and mutAttr ~= "" then return mutAttr end
    return nil
end

local function passesFilter(pet)
    local name = getPetName(pet):lower()
    local mps = getPetMPSValue(pet)
    if petFilterName ~= "" and not name:find(petFilterName:lower()) then return false end
    if petFilterMPS > 0 and mps < petFilterMPS then return false end
    return true
end

local function createPetESP(pet)
    local adornPart = nil
    for _, desc in ipairs(pet:GetDescendants()) do
        if desc:IsA("MeshPart") or desc:IsA("BasePart") then adornPart = desc break end
    end
    if not adornPart then return nil end

    local billboard = new("BillboardGui", {Name = "PetESP", Adornee = adornPart, Size = UDim2.new(0, 150, 0, 50), AlwaysOnTop = true, LightInfluence = 0, MaxDistance = 0, ExtentsOffset = Vector3.new(0, 3, 0)}, pet)
    new("UIListLayout", {FillDirection = Enum.FillDirection.Vertical, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Top, Padding = UDim.new(0, 1)}, billboard)

    local nameLabel = new("TextLabel", {Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1, Text = getPetName(pet), TextColor3 = Color3.fromRGB(255, 255, 255), Font = Enum.Font.GothamBold, TextSize = 11}, billboard)
    new("UIStroke", {Thickness = 1.5, Color = Color3.new(0, 0, 0)}, nameLabel)

    local mpsLabel = new("TextLabel", {Size = UDim2.new(1, 0, 0, 13), BackgroundTransparency = 1, Text = getPetMPS(pet), TextColor3 = Color3.fromRGB(100, 255, 100), Font = Enum.Font.GothamBold, TextSize = 10}, billboard)
    new("UIStroke", {Thickness = 1.5, Color = Color3.new(0, 0, 0)}, mpsLabel)

    local mutLabel = new("TextLabel", {Size = UDim2.new(1, 0, 0, 13), BackgroundTransparency = 1, Text = "", TextColor3 = Color3.fromRGB(255, 215, 0), Font = Enum.Font.GothamBold, TextSize = 10, Visible = false}, billboard)
    new("UIStroke", {Thickness = 1.5, Color = Color3.new(0, 0, 0)}, mutLabel)

    local highlight = new("Highlight", {Name = "PetESPHighlight", Adornee = pet, FillTransparency = 0.7, OutlineTransparency = 0.3, DepthMode = Enum.HighlightDepthMode.AlwaysOnTop, FillColor = Color3.fromRGB(0, 255, 100), OutlineColor = Color3.fromRGB(255, 255, 255)}, pet)

    local function updatePetESP()
        if not passesFilter(pet) then
            billboard.Enabled = false
            highlight.Enabled = false
            return
        else
            billboard.Enabled = petsEspEnabled
            highlight.Enabled = petsEspEnabled
        end
        local mut = getPetMutation(pet)
        if mut then
            mutLabel.Text = mut
            mutLabel.Visible = true
            highlight.FillColor = Color3.fromRGB(255, 215, 0)
            highlight.OutlineColor = Color3.fromRGB(255, 215, 0)
        else
            mutLabel.Visible = false
            highlight.FillColor = Color3.fromRGB(0, 255, 100)
            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        end
        nameLabel.Text = getPetName(pet)
        mpsLabel.Text = getPetMPS(pet)
    end
    updatePetESP()
    return {billboard = billboard, highlight = highlight, update = updatePetESP}
end

local function setupPetESP(pet)
    if espTracker[pet] then return end
    if pet:GetAttribute("Species") == nil then return end
    local esp = createPetESP(pet)
    if esp then espTracker[pet] = esp end
end

local function scanPets()
    local runtimePets = Workspace:FindFirstChild("RuntimePets")
    if not runtimePets then return end
    for _, pet in ipairs(runtimePets:GetChildren()) do setupPetESP(pet) end
end

local runtimePetsFolder = Workspace:FindFirstChild("RuntimePets")
if runtimePetsFolder then
    TrackConnection(runtimePetsFolder.ChildAdded:Connect(function(child) task.wait(0.1); setupPetESP(child) end))
    TrackConnection(runtimePetsFolder.ChildRemoved:Connect(function(child) removePetESP(child) end))
end

TrackConnection(Workspace.ChildAdded:Connect(function(child)
    if child.Name == "RuntimePets" and child:IsA("Folder") then
        TrackConnection(child.ChildAdded:Connect(function(pet) task.wait(0.1); setupPetESP(pet) end))
        TrackConnection(child.ChildRemoved:Connect(function(pet) removePetESP(pet) end))
        for _, pet in ipairs(child:GetChildren()) do setupPetESP(pet) end
    end
end))

scanPets()

TrackTask(task.spawn(function()
    while task.wait(0.5) do
        if petsEspEnabled then
            for pet, esp in pairs(espTracker) do
                if pet.Parent then esp.update() else removePetESP(pet) end
            end
            scanPets()
        else
            for pet, esp in pairs(espTracker) do removePetESP(pet) end
        end
    end
end))

table.insert(CleanupExtra, function()
    for pet, esp in pairs(espTracker) do pcall(function() removePetESP(pet) end) end
end)

--------------------------------------------------
-- ANTI KNOCKBACK
--------------------------------------------------
local function startAntiKnockback()
    if antiKnockbackConnection then return end
    antiKnockbackConnection = TrackConnection(RunService.Heartbeat:Connect(function()
        if not rootPart or not humanoid or humanoid.Health <= 0 then return end
        local vel = rootPart.AssemblyLinearVelocity
        local now = os.clock()
        local horizontal = Vector3.new(vel.X, 0, vel.Z)
        local isJumpVelocity = (now - lastJumpTime) < 0.3
        local clamped = false
        local y = vel.Y
        if horizontal.Magnitude > 40 then horizontal = horizontal.Unit * 40; clamped = true end
        if y > 35 and not isJumpVelocity then y = 35; clamped = true end
        if clamped then rootPart.AssemblyLinearVelocity = Vector3.new(horizontal.X, y, horizontal.Z) end
    end))
end

local function stopAntiKnockback()
    if antiKnockbackConnection then antiKnockbackConnection:Disconnect(); antiKnockbackConnection = nil end
end

--------------------------------------------------
-- AUTO LOCK BASE
--------------------------------------------------
local function findMyPlot()
    local plotsFolder = Workspace:FindFirstChild("Plots")
    if not plotsFolder then return nil end
    for _, plot in ipairs(plotsFolder:GetChildren()) do
        if plot:IsA("Model") and plot:GetAttribute("OwnerUserId") == LocalPlayer.UserId then return plot end
    end
    return nil
end

local lastLockState = nil

local function startAutoLock()
    if autoLockConnection then return end
    autoLockConnection = TrackTask(task.spawn(function()
        while autoLockEnabled do
            local myPlot = findMyPlot()
            if myPlot and rootPart and humanoid then
                local lockObj = myPlot:FindFirstChild("Lock")
                if lockObj and lockObj.Name == "Lock" then
                    local currentState = lockObj:GetAttribute(LOCK_STATE_ATTR) or STATE_IDLE
                    local pad = lockObj:FindFirstChild("Pad")
                    if currentState ~= lastLockState then
                        if currentState == STATE_IDLE then
                            notify("База открыта", "База разблокирована", "warning")
                        elseif currentState == STATE_LOCKED then
                            notify("База закрыта", "Auto Lock активирован", "success")
                        end
                        lastLockState = currentState
                    end
                    if currentState == STATE_IDLE and pad then
                        pcall(function() firetouchinterest(rootPart, pad, 0) end)
                        task.wait(0.1)
                        pcall(function() firetouchinterest(rootPart, pad, 1) end)
                    end
                end
            end
            task.wait(1)
        end
    end))
end

local function stopAutoLock()
    if autoLockConnection then task.cancel(autoLockConnection); autoLockConnection = nil end
    lastLockState = nil
end

--------------------------------------------------
-- WALL HOP
--------------------------------------------------
local wallHopActive = false

TrackConnection(RunService.Heartbeat:Connect(function()
    if not wallHopEnabled or not rootPart or not humanoid or humanoid.Health <= 0 then
        wallHopActive = false
        return
    end

    if wallHopActive then return end

    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude

    local forwardDirection = rootPart.CFrame.LookVector
    local result = workspace:Raycast(rootPart.Position, forwardDirection * 3, rayParams)

    if result then
        wallHopActive = true
        task.spawn(function()
            local bv = Instance.new("BodyVelocity")
            bv.MaxForce = Vector3.new(1, 1, 1) * math.huge
            bv.Velocity = Vector3.new(forwardDirection.X * (wallHopPower * 0.4), wallHopPower, forwardDirection.Z * (wallHopPower * 0.4))
            bv.Parent = rootPart

            local startTime = os.clock()
            while os.clock() - startTime < wallHopDuration do
                if not rootPart or not humanoid or humanoid.Health <= 0 or not wallHopEnabled then break end
                local cam = workspace.CurrentCamera
                if cam then
                    local look = cam.CFrame.LookVector
                    bv.Velocity = Vector3.new(look.X * (wallHopPower * 0.4), wallHopPower, look.Z * (wallHopPower * 0.4))
                end
                task.wait()
            end

            if bv then bv:Destroy() end
            wallHopActive = false
        end)
    end
end))

--------------------------------------------------
-- ANTI FALL, ANTI AFK, ENTER/EXIT BASE
--------------------------------------------------
local function CreateAntiFall()
    if not rootPart then return nil end
    local Part = Instance.new("Part")
    Part.Name = "AntiFall_Circle_800x800"
    Part.Shape = Enum.PartType.Cylinder
    Part.Size = Vector3.new(2, 800, 800)
    Part.CFrame = CFrame.new(rootPart.Position.X, rootPart.Position.Y - 7, rootPart.Position.Z) * CFrame.Angles(0, 0, math.rad(90))
    Part.Anchored = true
    Part.CanCollide = true
    Part.Material = Enum.Material.Glass
    Part.Color = Color3.fromRGB(80, 210, 255)
    Part.Transparency = 0.45
    Part.Parent = workspace
    return Part
end

local function RemoveAntiFall()
    if AntiFall then AntiFall:Destroy(); AntiFall = nil end
end

table.insert(CleanupExtra, function() pcall(RemoveAntiFall) end)

local function startAntiAfk()
    if antiAfkConnection then return end
    local VirtualUser = game:GetService("VirtualUser")
    antiAfkConnection = TrackConnection(LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end))
end

local function stopAntiAfk()
    if antiAfkConnection then antiAfkConnection:Disconnect(); antiAfkConnection = nil end
end

local baseDebounce = false

local function smoothVerticalMove(distance, direction)
    if not rootPart or baseDebounce then return end
    baseDebounce = true
    task.spawn(function()
        local char = LocalPlayer.Character
        if not char or not rootPart then baseDebounce = false return end

        local collideStates = {}
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                collideStates[part] = part.CanCollide
                part.CanCollide = false
            end
        end

        local wasAnchored = rootPart.Anchored
        rootPart.Anchored = true

        local startPos = rootPart.Position
        local targetY = startPos.Y + (distance * direction)
        local steps = math.max(math.abs(distance) * 4, 10)
        local stepSize = (distance / steps) * direction

        for i = 1, steps do
            if not rootPart or not rootPart.Parent then break end
            rootPart.CFrame = rootPart.CFrame + Vector3.new(0, stepSize, 0)
            task.wait(0.01)
        end

        if rootPart and rootPart.Parent then
            rootPart.CFrame = CFrame.new(rootPart.Position.X, targetY, rootPart.Position.Z) * CFrame.Angles(0, math.rad(rootPart.Orientation.Y), 0)
            rootPart.Anchored = wasAnchored
            rootPart.AssemblyLinearVelocity = Vector3.zero
        end

        for part, state in pairs(collideStates) do
            if part and part.Parent then part.CanCollide = state end
        end

        task.wait(0.2)
        baseDebounce = false
    end)
end

--------------------------------------------------
-- SAVED JOB IDS & SERVER HOP
--------------------------------------------------
local FileName = "SavedJobIDs.json"
local SavedJobs = {}

if isfile and isfile(FileName) then
    local success, data = pcall(function() return HttpService:JSONDecode(readfile(FileName)) end)
    if success and type(data) == "table" then SavedJobs = data end
end

local function SaveJobs()
    if writefile then writefile(FileName, HttpService:JSONEncode(SavedJobs)) end
end

local ServerSearching = false

local function SafeTeleport(jobId)
    local ok = pcall(function() TeleportService:TeleportToPlaceInstance(PlaceId, jobId, LocalPlayer) end)
    if not ok then notify("Server Hop", "Teleport failed", "error") end
end

local function GetServers()
    local AllServers = {}
    local Cursor = nil
    for Page = 1, 5 do
        local Url = "https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?limit=100"
        if Cursor then Url = Url .. "&cursor=" .. HttpService:UrlEncode(Cursor) end
        local Success, Result = pcall(function() return game:HttpGet(Url) end)
        if not Success then break end
        local DecodeSuccess, Data = pcall(function() return HttpService:JSONDecode(Result) end)
        if not DecodeSuccess or type(Data) ~= "table" then break end
        if type(Data.data) == "table" then
            for _, Server in ipairs(Data.data) do
                if Server.id and Server.playing and Server.maxPlayers then table.insert(AllServers, Server) end
            end
        end
        Cursor = Data.nextPageCursor
        if not Cursor then break end
        task.wait(0.25)
    end
    return AllServers
end

local function FindServer(Mode)
    local BestServer = nil
    for Attempt = 1, 5 do
        local Servers = GetServers()
        for _, Server in ipairs(Servers) do
            if Server.id ~= game.JobId and Server.playing < Server.maxPlayers then
                if Mode == "BUSY" then
                    if not BestServer or Server.playing > BestServer.playing then BestServer = Server end
                elseif Mode == "EMPTY" then
                    if not BestServer or Server.playing < BestServer.playing then BestServer = Server end
                end
            end
        end
        if BestServer then return BestServer end
        task.wait(1)
    end
    return nil
end

--------------------------------------------------
-- UI FRAMEWORK
--------------------------------------------------
local ToggleBtnFloat = new("TextButton", {Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0, 20, 0.5, -20), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Text = "⚡", TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 16, Font = Enum.Font.GothamBold, Visible = false}, ScreenGui)
new("UICorner", {CornerRadius = UDim.new(0, 10)}, ToggleBtnFloat)
new("UIStroke", {Color = Theme.Stroke, Thickness = 1.5}, ToggleBtnFloat)
table.insert(AccentTracker.Static, ToggleBtnFloat)

local Main = new("Frame", {Size = UDim2.new(0, 440, 0, 0), Position = UDim2.new(0.5, -220, 0.5, -155), BackgroundColor3 = Theme.Background, BorderSizePixel = 0, Active = true}, ScreenGui)
TweenService:Create(Main, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(0, 440, 0, 310)}):Play()
MakeDraggable(Main)
new("UICorner", {CornerRadius = UDim.new(0, 10)}, Main)
new("UIStroke", {Color = Theme.Stroke, Thickness = 1.5}, Main)

local Sidebar = new("Frame", {Size = UDim2.new(0, 130, 1, 0), BackgroundColor3 = Theme.Sidebar, BorderSizePixel = 0}, Main)
new("UICorner", {CornerRadius = UDim.new(0, 10)}, Sidebar)

local Header = new("Frame", {Size = UDim2.new(1, -130, 0, 50), Position = UDim2.new(0, 130, 0, 0), BackgroundTransparency = 1}, Main)

local Logo = new("Frame", {Size = UDim2.new(0, 26, 0, 26), Position = UDim2.new(0, 15, 0.5, -13), BackgroundColor3 = Theme.Accent}, Header)
new("UICorner", {CornerRadius = UDim.new(0, 8)}, Logo)
new("TextLabel", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "⚡", TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 14, Font = Enum.Font.GothamBold}, Logo)
table.insert(AccentTracker.Static, Logo)

new("TextLabel", {Size = UDim2.new(0, 150, 0, 16), Position = UDim2.new(0, 50, 0, 10), BackgroundTransparency = 1, Text = "SSS HUB STEAL", TextColor3 = Theme.Text, TextSize = 11, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left}, Header)
new("TextLabel", {Size = UDim2.new(0, 200, 0, 12), Position = UDim2.new(0, 50, 0, 27), BackgroundTransparency = 1, Text = "Game Enhancement", TextColor3 = Theme.TextDark, TextSize = 8, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left}, Header)

local CloseBtn = new("TextButton", {Size = UDim2.new(0, 22, 0, 22), Position = UDim2.new(1, -32, 0, 5), BackgroundColor3 = Color3.fromRGB(80, 30, 30), BorderSizePixel = 0, Text = "X", TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 10, Font = Enum.Font.GothamBold}, Header)
new("UICorner", {CornerRadius = UDim.new(0, 6)}, CloseBtn)

CloseBtn.MouseButton1Click:Connect(function()
    playClick()
    TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {Size = UDim2.new(0, 440, 0, 0)}):Play()
    task.wait(0.3)
    Main.Visible = false
    ToggleBtnFloat.Visible = true
    ToggleBtnFloat.Size = UDim2.new(0, 0, 0, 0)
    TweenService:Create(ToggleBtnFloat, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(0, 40, 0, 40)}):Play()
end)

ToggleBtnFloat.MouseButton1Click:Connect(function()
    playClick()
    TweenService:Create(ToggleBtnFloat, TweenInfo.new(0.2), {Size = UDim2.new(0, 0, 0, 0)}):Play()
    task.wait(0.2)
    ToggleBtnFloat.Visible = false
    Main.Visible = true
    Main.Size = UDim2.new(0, 440, 0, 0)
    TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(0, 440, 0, 310)}):Play()
end)

local SidebarLayout = new("UIListLayout", {FillDirection = Enum.FillDirection.Vertical, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Top, Padding = UDim.new(0, 5)}, Sidebar)

local Pages = {}
local TabButtons = {}

local function switchTab(tabName)
    for name, page in pairs(Pages) do page.Visible = (name == tabName) end
    for name, data in pairs(TabButtons) do
        if name == tabName then
            TweenService:Create(data.btn, TweenInfo.new(0.2), {BackgroundColor3 = CurrentAccent}):Play()
            data.btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            data.isActive = true
        else
            TweenService:Create(data.btn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Sidebar}):Play()
            data.btn.TextColor3 = Theme.TextDark
            data.isActive = false
        end
    end
end

local function CreateTab(text, icon)
    local TabBtn = new("TextButton", {Size = UDim2.new(0.9, 0, 0, 30), BackgroundColor3 = Theme.Sidebar, BorderSizePixel = 0, Text = "  " .. icon .. "  " .. text, TextColor3 = Theme.TextDark, TextSize = 11, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left}, Sidebar)
    new("UICorner", {CornerRadius = UDim.new(0, 6)}, TabBtn)

    TabBtn.MouseButton1Click:Connect(function() playClick(); switchTab(text) end)

    TabBtn.MouseEnter:Connect(function()
        if not TabButtons[text] or not TabButtons[text].isActive then
            TweenService:Create(TabBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(35, 35, 45)}):Play()
        end
    end)
    TabBtn.MouseLeave:Connect(function()
        if not TabButtons[text] or not TabButtons[text].isActive then
            TweenService:Create(TabBtn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Sidebar}):Play()
        end
    end)

    local Page = new("ScrollingFrame", {Size = UDim2.new(1, -150, 1, -60), Position = UDim2.new(0, 135, 0, 55), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2, ScrollBarImageColor3 = Theme.Stroke, Visible = false, CanvasSize = UDim2.new(0, 0, 0, 0)}, Main)
    new("UIListLayout", {FillDirection = Enum.FillDirection.Vertical, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Top, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, Page)

    Pages[text] = Page
    TabButtons[text] = {btn = TabBtn, isActive = false}
    AccentTracker.Tabs[text] = TabButtons[text]

    return Page
end

new("Frame", {Size = UDim2.new(0.8, 0, 0, 1), BackgroundTransparency = 0.5, BackgroundColor3 = Theme.Stroke, BorderSizePixel = 0}, Sidebar)

local function AddHover(btn, baseColor, hoverColor)
    local bc = baseColor or Theme.Card
    local hc = hoverColor or Theme.CardHover
    btn.MouseEnter:Connect(function() TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = hc}):Play() end)
    btn.MouseLeave:Connect(function() TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = bc}):Play() end)
end

--------------------------------------------------
-- KEYBIND REBIND SYSTEM
--------------------------------------------------
local isListeningKeybind = false

local function CreateKeybindButton(parent, name, defaultKey, callback)
    local currentKey = GetKeybind(name, defaultKey)
    local keyBtn = new("TextButton", {Size = UDim2.new(0, 35, 0, 18), Position = UDim2.new(1, -80, 0.5, -9), BackgroundColor3 = Theme.Background, BorderSizePixel = 0, Text = currentKey or "None", TextColor3 = Theme.TextDark, TextSize = 9, Font = Enum.Font.GothamBold}, parent)
    new("UICorner", {CornerRadius = UDim.new(0, 4)}, keyBtn)
    new("UIStroke", {Color = Theme.Stroke, Thickness = 1}, keyBtn)

    keyBtn.MouseButton1Click:Connect(function()
        playClick()
        if isListeningKeybind then return end
        isListeningKeybind = true
        keyBtn.Text = "..."
        keyBtn.BackgroundColor3 = CurrentAccent

        local conn
        conn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            if input.KeyCode == Enum.KeyCode.Escape then
                keyBtn.Text = currentKey or "None"
                keyBtn.BackgroundColor3 = Theme.Background
                isListeningKeybind = false
                conn:Disconnect()
                return
            end
            if input.UserInputType == Enum.UserInputType.Keyboard then
                local newKey = input.KeyCode.Name
                currentKey = newKey
                SetKeybind(name, newKey)
                keyBtn.Text = newKey
                keyBtn.BackgroundColor3 = Theme.Background
                isListeningKeybind = false
                conn:Disconnect()
                notify("Keybind", name .. " → " .. newKey, "success")
            end
        end)
    end)

    if currentKey then
        TrackConnection(UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed or isListeningKeybind then return end
            if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == currentKey then
                callback()
            end
        end))
    end
    return keyBtn
end

local function CreateToggle(parent, text, callback, layoutOrder, defaultKeybind)
    local Container = new("Frame", {Size = UDim2.new(1, -10, 0, 38), BackgroundColor3 = Theme.Card, BorderSizePixel = 0, LayoutOrder = layoutOrder or 0, Name = text}, parent)
    new("UICorner", {CornerRadius = UDim.new(0, 8)}, Container)
    new("UIStroke", {Color = Theme.Stroke, Thickness = 1}, Container)

    new("TextLabel", {Size = UDim2.new(1, -120, 1, 0), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1, Text = text, TextColor3 = Theme.Text, TextSize = 12, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left}, Container)

    local ToggleBtn = new("TextButton", {Size = UDim2.new(0, 38, 0, 19), Position = UDim2.new(1, -48, 0.5, -10), BackgroundColor3 = Theme.ToggleOff, BorderSizePixel = 0, Text = ""}, Container)
    new("UICorner", {CornerRadius = UDim.new(1, 0)}, ToggleBtn)
    local Circle = new("Frame", {Size = UDim2.new(0, 15, 0, 15), Position = UDim2.new(0, 2, 0.5, -8), BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0}, ToggleBtn)
    new("UICorner", {CornerRadius = UDim.new(1, 0)}, Circle)

    local state = false
    local toggleData = {btn = ToggleBtn, isOn = false}
    table.insert(AccentTracker.Toggles, toggleData)

    local function setToggleState(newState)
        state = newState
        callback(state)
        Config[text] = state
        SaveConfig()
        toggleData.isOn = newState
        if state then
            TweenService:Create(ToggleBtn, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = Theme.ToggleOn}):Play()
            TweenService:Create(Circle, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.new(1, -17, 0.5, -8)}):Play()
        else
            TweenService:Create(ToggleBtn, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = Theme.ToggleOff}):Play()
            TweenService:Create(Circle, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.new(0, 2, 0.5, -8)}):Play()
        end
    end

    ToggleBtn.MouseButton1Click:Connect(function() playClick(); setToggleState(not state) end)

    if defaultKeybind then
        CreateKeybindButton(Container, text, defaultKeybind, function() playClick(); setToggleState(not state) end)
    end

    if Config[text] == true then
        task.spawn(function() task.wait(0.1); setToggleState(true) end)
    end
    return Container
end

local function CreateSlider(parent, title, min, max, default, callback, layoutOrder)
    local Container = new("Frame", {Size = UDim2.new(1, -10, 0, 45), BackgroundColor3 = Theme.Card, BorderSizePixel = 0, LayoutOrder = layoutOrder or 0}, parent)
    new("UICorner", {CornerRadius = UDim.new(0, 8)}, Container)

    new("TextLabel", {Size = UDim2.new(0.6, 0, 0, 20), Position = UDim2.new(0, 10, 0, 5), BackgroundTransparency = 1, Text = title, TextColor3 = Theme.Text, TextSize = 11, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left}, Container)
    local ValLbl = new("TextLabel", {Size = UDim2.new(0.4, -10, 0, 20), Position = UDim2.new(0.6, 0, 0, 5), BackgroundTransparency = 1, Text = tostring(default), TextColor3 = Theme.Accent, TextSize = 11, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Right}, Container)

    local Track = new("Frame", {Size = UDim2.new(1, -20, 0, 6), Position = UDim2.new(0, 10, 0, 32), BackgroundColor3 = Theme.Background, BorderSizePixel = 0}, Container)
    new("UICorner", {CornerRadius = UDim.new(1, 0)}, Track)

    local Fill = new("Frame", {Size = UDim2.new((default - min) / (max - min), 0, 1, 0), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0}, Track)
    new("UICorner", {CornerRadius = UDim.new(1, 0)}, Fill)

    local Knob = new("Frame", {Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(Fill.Size.X.Scale, -7, 0.5, -7), BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0}, Track)
    new("UICorner", {CornerRadius = UDim.new(1, 0)}, Knob)

    local dragging = false
    local function update(input)
        local rel = math.clamp((input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
        local val = math.clamp(math.floor(min + (max - min) * rel), min, max)
        Fill.Size = UDim2.new(rel, 0, 1, 0)
        Knob.Position = UDim2.new(rel, -7, 0.5, -7)
        ValLbl.Text = tostring(val)
        if callback then callback(val) end
    end

    Knob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true end
    end)
    Track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true; update(input) end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
    TrackConnection(UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then update(input) end
    end))
    return Container
end

-- ИСПРАВЛЕНО: Меню создаются в отдельном PopupGui
local function CreatePopupMenu(title, width, height)
    local menu = new("Frame", {Size = UDim2.new(0, width, 0, height), Position = UDim2.new(0.5, -width/2, 0.5, -height/2), BackgroundColor3 = Theme.Card, BorderSizePixel = 0, Visible = false, Active = true}, PopupGui)
    MakeDraggable(menu)
    new("UICorner", {CornerRadius = UDim.new(0, 8)}, menu)
    new("UIStroke", {Color = Theme.Stroke, Thickness = 1.5}, menu)
    
    new("TextLabel", {Size = UDim2.new(1, -10, 0, 25), Position = UDim2.new(0, 10, 0, 5), BackgroundTransparency = 1, Text = title, TextColor3 = Theme.Text, TextSize = 12, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left}, menu)
    
    local closeBtn = new("TextButton", {Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(1, -25, 0, 5), BackgroundColor3 = Color3.fromRGB(80, 30, 30), BorderSizePixel = 0, Text = "X", TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 9, Font = Enum.Font.GothamBold}, menu)
    new("UICorner", {CornerRadius = UDim.new(0, 5)}, closeBtn)
    closeBtn.MouseButton1Click:Connect(function() playClick(); menu.Visible = false end)

    local content = new("Frame", {Size = UDim2.new(1, -20, 1, -45), Position = UDim2.new(0, 10, 0, 35), BackgroundTransparency = 1, Active = false}, menu)
    new("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Top}, content)

    return menu, content
end

--------------------------------------------------
-- BUILD PAGES
--------------------------------------------------
local BypassMenu, BypassContent = CreatePopupMenu("BYPASS", 260, 280)
local PetFilterMenu, PetFilterContent = CreatePopupMenu("PET FILTERS", 260, 200)

local MainPage = CreateTab("Main", "🏠")
local CombatPage = CreateTab("Combat", "⚔️")
local ServerPage = CreateTab("Server", "📡")
local SettingsPage = CreateTab("Settings", "⚙️")

-- MAIN PAGE
CreateToggle(MainPage, "Auto Run", function(state)
    autoRun = state
    if state then startAutoRun() else stopAutoRun() end
    notify("Auto Run", state and "Enabled" or "Disabled", "info")
end, 1)

CreateSlider(MainPage, "Auto Run Speed", 16, 120, autoRunSpeed, function(val)
    autoRunSpeed = val
    Config.AutoRunSpeed = val
    SaveConfig()
end, 2)

CreateToggle(MainPage, "Player ESP", function(state)
    espEnabled = state
    updateESP()
    notify("Player ESP", state and "Enabled" or "Disabled", "info")
end, 3, "T")

CreateToggle(MainPage, "Pets ESP", function(state)
    petsEspEnabled = state
    if not petsEspEnabled then
        for pet, _ in pairs(espTracker) do removePetESP(pet) end
    end
    notify("Pets ESP", state and "Enabled" or "Disabled", "info")
end, 4, "Y")

CreateToggle(MainPage, "Anti Fall", function(state)
    antiFallEnabled = state
    if antiFallEnabled then AntiFall = CreateAntiFall() else RemoveAntiFall() end
    notify("Anti Fall", state and "Enabled" or "Disabled", "info")
end, 5)

CreateToggle(MainPage, "Anti AFK", function(state)
    antiAfkEnabled = state
    if antiAfkEnabled then startAntiAfk() else stopAntiAfk() end
    notify("Anti AFK", state and "Enabled" or "Disabled", "info")
end, 6)

CreateButton(MainPage, "Pet Filter", function()
    PetFilterMenu.Visible = not PetFilterMenu.Visible
end, 7)

CreateButton(MainPage, "Bypass Menu", function()
    BypassMenu.Visible = not BypassMenu.Visible
end, 8, "B")

-- COMBAT PAGE
CreateToggle(CombatPage, "Anti Knockback", function(state)
    antiKnockbackEnabled = state
    if antiKnockbackEnabled then startAntiKnockback() else stopAntiKnockback() end
    notify("Anti Knockback", state and "Enabled" or "Disabled", "info")
end, 1, "G")

CreateToggle(CombatPage, "Auto Lock Base", function(state)
    autoLockEnabled = state
    if autoLockEnabled then startAutoLock() else stopAutoLock() end
    notify("Auto Lock", state and "Enabled" or "Disabled", "info")
end, 2)

--------------------------------------------------
-- SETTINGS PAGE
--------------------------------------------------
local SaveConfigContainer = new("Frame", {Size = UDim2.new(1, -10, 0, 38), BackgroundColor3 = Theme.Card, BorderSizePixel = 0, LayoutOrder = 1}, SettingsPage)
new("UICorner", {CornerRadius = UDim.new(0, 8)}, SaveConfigContainer)
new("UIStroke", {Color = Theme.Stroke, Thickness = 1}, SaveConfigContainer)

new("TextLabel", {Size = UDim2.new(1, -65, 1, 0), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1, Text = "Save Config", TextColor3 = Theme.Text, TextSize = 12, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left}, SaveConfigContainer)

local SaveConfigToggleBtn = new("TextButton", {Size = UDim2.new(0, 38, 0, 19), Position = UDim2.new(1, -48, 0.5, -10), BackgroundColor3 = SaveConfigEnabled and Theme.ToggleOn or Theme.ToggleOff, BorderSizePixel = 0, Text = ""}, SaveConfigContainer)
new("UICorner", {CornerRadius = UDim.new(1, 0)}, SaveConfigToggleBtn)
local SaveConfigCircle = new("Frame", {Size = UDim2.new(0, 15, 0, 15), Position = SaveConfigEnabled and UDim2.new(1, -17, 0.5, -8) or UDim2.new(0, 2, 0.5, -8), BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0}, SaveConfigToggleBtn)
new("UICorner", {CornerRadius = UDim.new(1, 0)}, SaveConfigCircle)

local saveConfigToggleData = {btn = SaveConfigToggleBtn, isOn = SaveConfigEnabled}
table.insert(AccentTracker.Toggles, saveConfigToggleData)

SaveConfigToggleBtn.MouseButton1Click:Connect(function()
    playClick()
    SaveConfigEnabled = not SaveConfigEnabled
    Config.SaveConfigEnabled = SaveConfigEnabled
    SaveConfig()
    saveConfigToggleData.isOn = SaveConfigEnabled
    if SaveConfigEnabled then
        TweenService:Create(SaveConfigToggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.ToggleOn}):Play()
        TweenService:Create(SaveConfigCircle, TweenInfo.new(0.2), {Position = UDim2.new(1, -17, 0.5, -8)}):Play()
        notify("Config", "Auto-save enabled", "success")
    else
        TweenService:Create(SaveConfigToggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.ToggleOff}):Play()
        TweenService:Create(SaveConfigCircle, TweenInfo.new(0.2), {Position = UDim2.new(0, 2, 0.5, -8)}):Play()
        notify("Config", "Auto-save disabled", "warning")
    end
end)

new("TextLabel", {Size = UDim2.new(1, -10, 0, 20), BackgroundTransparency = 1, Text = "Accent Color", TextColor3 = Theme.Text, TextSize = 12, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 2}, SettingsPage)

local ColorContainer = new("Frame", {Size = UDim2.new(1, -10, 0, 40), BackgroundTransparency = 1, LayoutOrder = 3}, SettingsPage)
new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 8)}, ColorContainer)

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
    local swatch = new("TextButton", {Size = UDim2.new(0, 28, 0, 28), BackgroundColor3 = preset.color, BorderSizePixel = 0, Text = ""}, ColorContainer)
    new("UICorner", {CornerRadius = UDim.new(0, 6)}, swatch)
    local swatchStroke = new("UIStroke", {Color = Color3.fromRGB(255, 255, 255), Thickness = 0}, swatch)
    AddHover(swatch, preset.color, preset.color)

    if CurrentAccent == preset.color then
        swatchStroke.Thickness = 2
        selectedSwatchStroke = swatchStroke
    end

    swatch.MouseButton1Click:Connect(function()
        playClick()
        if selectedSwatchStroke then selectedSwatchStroke.Thickness = 0 end
        swatchStroke.Thickness = 2
        selectedSwatchStroke = swatchStroke
        SetAccent(preset.color)
        notify("Accent Color", preset.name, "success")
    end)
end

new("TextLabel", {Size = UDim2.new(1, -10, 0, 40), BackgroundTransparency = 1, Text = "Click on a key (e.g. T, Y, G) next to a function to rebind it.\nPress ESC to cancel.", TextColor3 = Theme.TextDark, TextSize = 10, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, LayoutOrder = 4}, SettingsPage)

--------------------------------------------------
-- BYPASS MENU CONTENT
--------------------------------------------------
CreateToggle(BypassContent, "Wall Hop", function(state)
    wallHopEnabled = state
    notify("Wall Hop", state and "Enabled" or "Disabled", "info")
end, 1)

CreateSlider(BypassContent, "Wall Hop Power", 50, 200, wallHopPower, function(val)
    wallHopPower = val
    Config.WallHopPower = val
    SaveConfig()
end, 2)

CreateSlider(BypassContent, "Wall Hop Duration", 1, 10, math.floor(wallHopDuration * 10), function(val)
    wallHopDuration = val / 10
    Config.WallHopDuration = wallHopDuration
    SaveConfig()
end, 3)

-- ИСПРАВЛЕНО: Кнопки с цветами
local EnterBaseBtn = new("TextButton", {Size = UDim2.new(1, -10, 0, 33), BackgroundColor3 = Theme.EnterBase, BorderSizePixel = 0, Text = "Enter Base", TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 11, Font = Enum.Font.GothamBold, LayoutOrder = 4, Name = "Enter Base"}, BypassContent)
new("UICorner", {CornerRadius = UDim.new(0, 8)}, EnterBaseBtn)
new("UIStroke", {Color = Theme.Stroke, Thickness = 1}, EnterBaseBtn)
AddHover(EnterBaseBtn, Theme.EnterBase, Color3.fromRGB(60, 140, 240))

EnterBaseBtn.MouseButton1Click:Connect(function() playClick(); smoothVerticalMove(DOWN_DISTANCE, -1); notify("Enter Base", "Moving down", "info") end)
CreateKeybindButton(EnterBaseBtn, "Enter Base", "Q", function() playClick(); smoothVerticalMove(DOWN_DISTANCE, -1); notify("Enter Base", "Moving down", "info") end)

local ExitBaseBtn = new("TextButton", {Size = UDim2.new(1, -10, 0, 33), BackgroundColor3 = Theme.ExitBase, BorderSizePixel = 0, Text = "Exit Base", TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 11, Font = Enum.Font.GothamBold, LayoutOrder = 5, Name = "Exit Base"}, BypassContent)
new("UICorner", {CornerRadius = UDim.new(0, 8)}, ExitBaseBtn)
new("UIStroke", {Color = Theme.Stroke, Thickness = 1}, ExitBaseBtn)
AddHover(ExitBaseBtn, Theme.ExitBase, Color3.fromRGB(240, 100, 100))

ExitBaseBtn.MouseButton1Click:Connect(function() playClick(); smoothVerticalMove(UP_DISTANCE, 1); notify("Exit Base", "Moving up", "info") end)
CreateKeybindButton(ExitBaseBtn, "Exit Base", "R", function() playClick(); smoothVerticalMove(UP_DISTANCE, 1); notify("Exit Base", "Moving up", "info") end)

--------------------------------------------------
-- PET FILTER MENU CONTENT
--------------------------------------------------
new("TextLabel", {Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Text = "Name:", TextColor3 = Theme.TextDark, TextSize = 10, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 1}, PetFilterContent)

local nameBox = new("TextBox", {Size = UDim2.new(1, 0, 0, 25), BackgroundColor3 = Theme.Background, BorderSizePixel = 0, Text = "", PlaceholderText = "e.g. Dragon", TextColor3 = Theme.Text, PlaceholderColor3 = Theme.TextDark, TextSize = 10, Font = Enum.Font.Gotham, LayoutOrder = 2}, PetFilterContent)
new("UICorner", {CornerRadius = UDim.new(0, 6)}, nameBox)
new("UIStroke", {Color = Theme.Stroke, Thickness = 1}, nameBox)

new("TextLabel", {Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Text = "Min MPS:", TextColor3 = Theme.TextDark, TextSize = 10, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 3}, PetFilterContent)

local mpsBox = new("TextBox", {Size = UDim2.new(1, 0, 0, 25), BackgroundColor3 = Theme.Background, BorderSizePixel = 0, Text = "0", TextColor3 = Theme.Text, TextSize = 10, Font = Enum.Font.Gotham, LayoutOrder = 4}, PetFilterContent)
new("UICorner", {CornerRadius = UDim.new(0, 6)}, mpsBox)
new("UIStroke", {Color = Theme.Stroke, Thickness = 1}, mpsBox)

local ButtonRow = new("Frame", {Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, LayoutOrder = 5, Active = false}, PetFilterContent)
new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8)}, ButtonRow)

local applyBtn = new("TextButton", {Size = UDim2.new(0.5, -4, 1, 0), BackgroundColor3 = Color3.fromRGB(40, 100, 60), BorderSizePixel = 0, Text = "APPLY", TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 10, Font = Enum.Font.GothamBold}, ButtonRow)
new("UICorner", {CornerRadius = UDim.new(0, 6)}, applyBtn)
AddHover(applyBtn, Color3.fromRGB(40, 100, 60), Color3.fromRGB(50, 120, 70))

applyBtn.MouseButton1Click:Connect(function()
    playClick()
    petFilterName = nameBox.Text
    local inputText = mpsBox.Text:lower()
    local mult = 1
    if inputText:find("k") then mult = 1000
    elseif inputText:find("m") then mult = 1000000
    elseif inputText:find("b") then mult = 1000000000 end
    local numStr = inputText:gsub("[^%d%.]", "")
    local val = tonumber(numStr)
    if val then petFilterMPS = val * mult else petFilterMPS = 0 end
    PetFilterMenu.Visible = false
    notify("Pet Filter", "Applied successfully", "success")
end)

local clearBtn = new("TextButton", {Size = UDim2.new(0.5, -4, 1, 0), BackgroundColor3 = Color3.fromRGB(100, 40, 40), BorderSizePixel = 0, Text = "CLEAR", TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 10, Font = Enum.Font.GothamBold}, ButtonRow)
new("UICorner", {CornerRadius = UDim.new(0, 6)}, clearBtn)
AddHover(clearBtn, Color3.fromRGB(100, 40, 40), Color3.fromRGB(120, 50, 50))

clearBtn.MouseButton1Click:Connect(function()
    playClick()
    nameBox.Text = ""
    mpsBox.Text = "0"
    petFilterName = ""
    petFilterMPS = 0
    notify("Pet Filter", "Cleared", "info")
end)

--------------------------------------------------
-- SERVER PAGE
--------------------------------------------------
local UpdateServerList

local StatusLabel = new("TextLabel", {Size = UDim2.new(1, -10, 0, 18), BackgroundTransparency = 1, Text = "Saved Jobs: " .. #SavedJobs, TextColor3 = Theme.TextDark, TextSize = 10, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 0}, ServerPage)

CreateButton(ServerPage, "Copy & Save Job", function()
    local CurrentJobId = game.JobId
    if #SavedJobs >= 10 then notify("Server Hop", "Max 10 saved jobs!", "warning"); return end
    for _, Data in ipairs(SavedJobs) do
        if Data.JobId == CurrentJobId then notify("Server Hop", "Already saved!", "warning"); return end
    end
    table.insert(SavedJobs, {JobId = CurrentJobId, Name = "Server " .. (#SavedJobs + 1)})
    SaveJobs()
    if setclipboard then setclipboard(CurrentJobId) end
    notify("Server Hop", "Saved & Copied!", "success")
    StatusLabel.Text = "Saved Jobs: " .. #SavedJobs
    UpdateServerList()
end, 1)

CreateButton(ServerPage, "Reconnect", function() SafeTeleport(game.JobId) end, 2)

CreateButton(ServerPage, "Join Busy Server", function()
    if ServerSearching then return end
    ServerSearching = true
    StatusLabel.Text = "Searching busy..."
    local Server = FindServer("BUSY")
    if Server then
        StatusLabel.Text = "Joining: " .. Server.playing .. "/" .. Server.maxPlayers
        task.wait(0.5)
        SafeTeleport(Server.id)
    else
        StatusLabel.Text = "Not found!"
        notify("Server Hop", "No busy servers found", "warning")
    end
    ServerSearching = false
end, 3)

CreateButton(ServerPage, "Join Empty Server", function()
    if ServerSearching then return end
    ServerSearching = true
    StatusLabel.Text = "Searching empty..."
    local Server = FindServer("EMPTY")
    if Server then
        StatusLabel.Text = "Joining: " .. Server.playing .. "/" .. Server.maxPlayers
        task.wait(0.5)
        SafeTeleport(Server.id)
    else
        StatusLabel.Text = "Not found!"
        notify("Server Hop", "No empty servers found", "warning")
    end
    ServerSearching = false
end, 4)

local serverSep = new("Frame", {Size = UDim2.new(1, -10, 0, 1), BackgroundColor3 = Theme.Stroke, BackgroundTransparency = 0.5, BorderSizePixel = 0, LayoutOrder = 5, Name = "Sep"}, ServerPage)

local ServerListContainer = new("Frame", {Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, LayoutOrder = 6, AutomaticSize = Enum.AutomaticSize.Y}, ServerPage)
local ServerListLayout = new("UIListLayout", {FillDirection = Enum.FillDirection.Vertical, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Top, Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder}, ServerListContainer)

UpdateServerList = function()
    for _, child in ipairs(ServerListContainer:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    for index, Data in ipairs(SavedJobs) do
        local Row = new("Frame", {Size = UDim2.new(1, -4, 0, 30), BackgroundColor3 = Theme.Card, BorderSizePixel = 0, LayoutOrder = index}, ServerListContainer)
        new("UICorner", {CornerRadius = UDim.new(0, 6)}, Row)
        new("UIStroke", {Color = Theme.Stroke, Thickness = 1}, Row)

        new("TextLabel", {Size = UDim2.new(1, -100, 1, 0), Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1, Text = Data.Name or ("Server " .. index), TextColor3 = Theme.Text, TextSize = 10, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left}, Row)

        local JoinBtn = new("TextButton", {Size = UDim2.new(0, 45, 1, -8), Position = UDim2.new(1, -100, 0, 4), BackgroundColor3 = Color3.fromRGB(40, 80, 50), BorderSizePixel = 0, Text = "JOIN", TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 9, Font = Enum.Font.GothamBold}, Row)
        new("UICorner", {CornerRadius = UDim.new(0, 4)}, JoinBtn)
        AddHover(JoinBtn, Color3.fromRGB(40, 80, 50), Color3.fromRGB(50, 100, 60))
        JoinBtn.MouseButton1Click:Connect(function() playClick(); SafeTeleport(Data.JobId) end)

        local DeleteBtn = new("TextButton", {Size = UDim2.new(0, 35, 1, -8), Position = UDim2.new(1, -45, 0, 4), BackgroundColor3 = Color3.fromRGB(80, 40, 40), BorderSizePixel = 0, Text = "X", TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 9, Font = Enum.Font.GothamBold}, Row)
        new("UICorner", {CornerRadius = UDim.new(0, 4)}, DeleteBtn)
        AddHover(DeleteBtn, Color3.fromRGB(80, 40, 40), Color3.fromRGB(100, 50, 50))
        DeleteBtn.MouseButton1Click:Connect(function()
            playClick()
            table.remove(SavedJobs, index)
            SaveJobs()
            UpdateServerList()
            StatusLabel.Text = "Saved Jobs: " .. #SavedJobs
        end)
    end
end

--------------------------------------------------
-- START
--------------------------------------------------
switchTab("Main")
UpdateServerList()
notify("SSS HUB", "Добро пожаловать в SSS HUB STEAL!", "info")
