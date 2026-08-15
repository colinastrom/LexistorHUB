--// SSSHUB STEAL + MAIN
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

if CoreGui:FindFirstChild("SSSHubSteal") then CoreGui.SSSHubSteal:Destroy() end
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

if Config.AccentColor then
    local c = Config.AccentColor
    Theme.Accent = Color3.fromRGB(c[1], c[2], c[3])
    Theme.ToggleOn = Color3.fromRGB(c[1], c[2], c[3])
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
-- SOUND
--------------------------------------------------
local ClickSound = Instance.new("Sound")
ClickSound.SoundId = "rbxassetid://6895056283"
ClickSound.Volume = 0.4
ClickSound.Parent = workspace

local function playClick()
    pcall(function() ClickSound:Play() end)
end

--------------------------------------------------
-- DRAGGABLE
--------------------------------------------------
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

--------------------------------------------------
-- NOTIFICATION SYSTEM (как на фото)
--------------------------------------------------
local NotifyGui = Instance.new("ScreenGui")
NotifyGui.Name = "SSSNotify"
NotifyGui.ResetOnSpawn = false
NotifyGui.DisplayOrder = 999999
NotifyGui.Parent = CoreGui

local NotifyHolder = Instance.new("Frame")
NotifyHolder.Size = UDim2.new(0, 300, 0, 0)
NotifyHolder.Position = UDim2.new(1, -320, 0, 20)
NotifyHolder.BackgroundTransparency = 1
NotifyHolder.Active = false
NotifyHolder.AutomaticSize = Enum.AutomaticSize.Y
NotifyHolder.Parent = NotifyGui

local NotifyLayout = Instance.new("UIListLayout")
NotifyLayout.FillDirection = Enum.FillDirection.Vertical
NotifyLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
NotifyLayout.VerticalAlignment = Enum.VerticalAlignment.Top
NotifyLayout.Padding = UDim.new(0, 10)
NotifyLayout.Parent = NotifyHolder

local function notify(title, text, notifType)
    notifType = notifType or "success"
    local iconColor = Theme.Success
    local iconText = "🛡"
    if notifType == "warning" then iconColor = Theme.Warning; iconText = "⚠"
    elseif notifType == "error" then iconColor = Theme.Error; iconText = "✕"
    elseif notifType == "info" then iconColor = Theme.Info; iconText = "ℹ" end

    local notif = Instance.new("Frame")
    notif.Size = UDim2.new(0, 280, 0, 70)
    notif.Position = UDim2.new(0, 300, 0, 0)
    notif.BackgroundColor3 = Theme.Card
    notif.BorderSizePixel = 0
    notif.Active = false
    notif.Parent = NotifyHolder

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = notif

    local stroke = Instance.new("UIStroke")
    stroke.Color = Theme.Stroke
    stroke.Thickness = 1.5
    stroke.Parent = notif

    local iconCircle = Instance.new("Frame")
    iconCircle.Size = UDim2.new(0, 40, 0, 40)
    iconCircle.Position = UDim2.new(0, 12, 0.5, -20)
    iconCircle.BackgroundColor3 = iconColor
    iconCircle.BorderSizePixel = 0
    iconCircle.Active = false
    iconCircle.Parent = notif

    local iconCorner = Instance.new("UICorner")
    iconCorner.CornerRadius = UDim.new(1, 0)
    iconCorner.Parent = iconCircle

    local shieldIcon = Instance.new("TextLabel")
    shieldIcon.Size = UDim2.new(1, 0, 1, 0)
    shieldIcon.BackgroundTransparency = 1
    shieldIcon.Text = iconText
    shieldIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
    shieldIcon.TextSize = 18
    shieldIcon.Font = Enum.Font.GothamBold
    shieldIcon.Active = false
    shieldIcon.Parent = iconCircle

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -70, 0, 20)
    titleLbl.Position = UDim2.new(0, 62, 0, 15)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = title
    titleLbl.TextColor3 = Theme.Text
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 14
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Active = false
    titleLbl.Parent = notif

    local textLbl = Instance.new("TextLabel")
    textLbl.Size = UDim2.new(1, -70, 0, 16)
    textLbl.Position = UDim2.new(0, 62, 0, 38)
    textLbl.BackgroundTransparency = 1
    textLbl.Text = text
    textLbl.TextColor3 = Theme.TextDark
    textLbl.Font = Enum.Font.Gotham
    textLbl.TextSize = 12
    textLbl.TextXAlignment = Enum.TextXAlignment.Left
    textLbl.Active = false
    textLbl.Parent = notif

    local progress = Instance.new("Frame")
    progress.Size = UDim2.new(1, 0, 0, 3)
    progress.Position = UDim2.new(0, 0, 1, -3)
    progress.BackgroundColor3 = iconColor
    progress.BorderSizePixel = 0
    progress.Active = false
    progress.Parent = notif

    local progressCorner = Instance.new("UICorner")
    progressCorner.CornerRadius = UDim.new(1, 0)
    progressCorner.Parent = progress

    notif.BackgroundTransparency = 1
    iconCircle.BackgroundTransparency = 1
    shieldIcon.TextTransparency = 1
    titleLbl.TextTransparency = 1
    textLbl.TextTransparency = 1
    stroke.Transparency = 1
    progress.BackgroundTransparency = 1

    local tweenIn = TweenService:Create(notif, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 0})
    tweenIn:Play()
    TweenService:Create(stroke, TweenInfo.new(0.4), {Transparency = 0}):Play()
    TweenService:Create(iconCircle, TweenInfo.new(0.4), {BackgroundTransparency = 0}):Play()
    TweenService:Create(shieldIcon, TweenInfo.new(0.4), {TextTransparency = 0}):Play()
    TweenService:Create(titleLbl, TweenInfo.new(0.4), {TextTransparency = 0}):Play()
    TweenService:Create(textLbl, TweenInfo.new(0.4), {TextTransparency = 0}):Play()
    TweenService:Create(progress, TweenInfo.new(0.4), {BackgroundTransparency = 0}):Play()

    task.delay(0.4, function()
        TweenService:Create(progress, TweenInfo.new(2.6), {Size = UDim2.new(0, 0, 0, 3)}):Play()
    end)

    task.delay(3, function()
        local tweenOut = TweenService:Create(notif, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {Position = UDim2.new(0, 300, 0, 0), BackgroundTransparency = 1})
        tweenOut:Play()
        TweenService:Create(stroke, TweenInfo.new(0.4), {Transparency = 1}):Play()
        TweenService:Create(iconCircle, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
        TweenService:Create(shieldIcon, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
        TweenService:Create(titleLbl, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
        TweenService:Create(textLbl, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
        TweenService:Create(progress, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
        tweenOut.Completed:Wait()
        notif:Destroy()
    end)
end

--------------------------------------------------
-- SETTINGS & STATE
--------------------------------------------------
local FAST_SPEED = 38
local UP_DISTANCE = 20
local DOWN_DISTANCE = 17

local autoRun = Config.autoRun or false
local espEnabled = Config.espEnabled or false
local wallHopEnabled = Config.wallHopEnabled or false
local antiFallEnabled = Config.antiFallEnabled or false
local petsEspEnabled = Config.petsEspEnabled or false
local antiKnockbackEnabled = Config.antiKnockbackEnabled or false
local autoLockEnabled = Config.autoLockEnabled or false
local antiAfkEnabled = Config.antiAfkEnabled or false

local humanoid = nil
local rootPart = nil
local normalSpeed = 16

local ESPs = {}
local AntiFall = nil
local antiKnockbackConnection = nil
local autoLockConnection = nil
local antiAfkConnection = nil

local LOCK_STATE_ATTR = "LockState"
local STATE_IDLE = "Idle"
local STATE_LOCKED = "Locked"

local lastJumpTime = 0
local lastSafePos = nil
local isCountering = false
local counterEndTime = 0

local function setupCharacter(character)
    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")
    normalSpeed = humanoid.WalkSpeed
    humanoid.StateChanged:Connect(function(_, newState)
        if newState == Enum.HumanoidStateType.Jumping then lastJumpTime = os.clock() end
    end)
end
if LocalPlayer.Character then setupCharacter(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(setupCharacter)

--------------------------------------------------
-- AUTO RUN
--------------------------------------------------
RunService.Heartbeat:Connect(function()
    if humanoid and humanoid.Health > 0 then
        if autoRun then
            humanoid.WalkSpeed = FAST_SPEED
            local camera = workspace.CurrentCamera
            if camera then
                local lookVector = camera.CFrame.LookVector
                humanoid:Move(Vector3.new(lookVector.X, 0, lookVector.Z), false)
            end
        else
            humanoid.WalkSpeed = normalSpeed
        end
    end
end)

--------------------------------------------------
-- PLAYER ESP
--------------------------------------------------
local function removeESP(player)
    if ESPs[player] then ESPs[player]:Destroy(); ESPs[player] = nil end
end

local function createESP(player, character)
    if player == LocalPlayer then return end
    removeESP(player)
    local folder = Instance.new("Folder")
    folder.Name = "PlayerESP"
    folder.Parent = character
    local highlight = Instance.new("Highlight")
    highlight.Adornee = character
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillTransparency = 0.75
    highlight.OutlineTransparency = 0
    highlight.FillColor = Color3.fromRGB(255, 255, 255)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.Enabled = espEnabled
    highlight.Parent = folder
    local head = character:FindFirstChild("Head")
    if head then
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "ESP_Name"
        billboard.Adornee = head
        billboard.Size = UDim2.new(0, 120, 0, 20)
        billboard.StudsOffset = Vector3.new(0, 2.5, 0)
        billboard.AlwaysOnTop = true
        billboard.Enabled = espEnabled
        billboard.Parent = folder
        local text = Instance.new("TextLabel")
        text.Size = UDim2.new(1, 0, 1, 0)
        text.BackgroundTransparency = 1
        text.Text = player.Name
        text.TextStrokeTransparency = 0.5
        text.TextSize = 15
        text.Font = Enum.Font.GothamBold
        text.Parent = billboard
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
                if object:IsA("Highlight") or object:IsA("BillboardGui") then
                    object.Enabled = espEnabled
                end
            end
        end
    end
end

local function setupESP(player)
    if player == LocalPlayer then return end
    player.CharacterAdded:Connect(function(character)
        task.wait(0.5)
        createESP(player, character)
    end)
    if player.Character then createESP(player, player.Character) end
end

for _, player in ipairs(Players:GetPlayers()) do setupESP(player) end
Players.PlayerAdded:Connect(setupESP)
Players.PlayerRemoving:Connect(function(player) removeESP(player) end)

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

local function getPetName(pet)
    return pet:GetAttribute("Species") or pet.Name
end

local function getPetMPS(pet)
    local tag = pet:FindFirstChild("ItemNameTag", true)
    if tag then
        local mpsLabel = tag:FindFirstChild("MPS", true)
        if mpsLabel and mpsLabel:IsA("TextLabel") and mpsLabel.Text ~= "" then
            return mpsLabel.Text
        end
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
        if mutLabel and mutLabel:IsA("TextLabel") and mutLabel.Text ~= "" and mutLabel.Visible then
            return mutLabel.Text
        end
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
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "PetESP"
    billboard.Adornee = adornPart
    billboard.Size = UDim2.new(0, 150, 0, 50)
    billboard.AlwaysOnTop = true
    billboard.LightInfluence = 0
    billboard.MaxDistance = 0
    billboard.ExtentsOffset = Vector3.new(0, 3, 0)
    billboard.Parent = pet
    
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Top
    layout.Padding = UDim.new(0, 1)
    layout.Parent = billboard
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0, 14)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = getPetName(pet)
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 11
    nameLabel.Parent = billboard
    local nameStroke = Instance.new("UIStroke")
    nameStroke.Thickness = 1.5
    nameStroke.Color = Color3.new(0, 0, 0)
    nameStroke.Parent = nameLabel
    
    local mpsLabel = Instance.new("TextLabel")
    mpsLabel.Size = UDim2.new(1, 0, 0, 13)
    mpsLabel.BackgroundTransparency = 1
    mpsLabel.Text = getPetMPS(pet)
    mpsLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    mpsLabel.Font = Enum.Font.GothamBold
    mpsLabel.TextSize = 10
    mpsLabel.Parent = billboard
    local mpsStroke = Instance.new("UIStroke")
    mpsStroke.Thickness = 1.5
    mpsStroke.Color = Color3.new(0, 0, 0)
    mpsStroke.Parent = mpsLabel
    
    local mutLabel = Instance.new("TextLabel")
    mutLabel.Size = UDim2.new(1, 0, 0, 13)
    mutLabel.BackgroundTransparency = 1
    mutLabel.Text = ""
    mutLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    mutLabel.Font = Enum.Font.GothamBold
    mutLabel.TextSize = 10
    mutLabel.Visible = false
    mutLabel.Parent = billboard
    local mutStroke = Instance.new("UIStroke")
    mutStroke.Thickness = 1.5
    mutStroke.Color = Color3.new(0, 0, 0)
    mutStroke.Parent = mutLabel
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "PetESPHighlight"
    highlight.Adornee = pet
    highlight.FillTransparency = 0.7
    highlight.OutlineTransparency = 0.3
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillColor = Color3.fromRGB(0, 255, 100)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.Parent = pet
    
    local function updateESP()
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
    updateESP()
    return {billboard = billboard, highlight = highlight, update = updateESP}
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
    runtimePetsFolder.ChildAdded:Connect(function(child) task.wait(0.1) setupPetESP(child) end)
    runtimePetsFolder.ChildRemoved:Connect(function(child) removePetESP(child) end)
end

Workspace.ChildAdded:Connect(function(child)
    if child.Name == "RuntimePets" and child:IsA("Folder") then
        child.ChildAdded:Connect(function(pet) task.wait(0.1) setupPetESP(pet) end)
        child.ChildRemoved:Connect(function(pet) removePetESP(pet) end)
        for _, pet in ipairs(child:GetChildren()) do setupPetESP(pet) end
    end
end)

scanPets()

task.spawn(function()
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
end)

--------------------------------------------------
-- ANTI KNOCKBACK
--------------------------------------------------
local function startAntiKnockback()
    if antiKnockbackConnection then return end
    antiKnockbackConnection = RunService.Heartbeat:Connect(function()
        if not rootPart or not humanoid or humanoid.Health <= 0 then return end
        local currentVel = rootPart.AssemblyLinearVelocity
        local now = os.clock()
        local horizontalSpeed = Vector3.new(currentVel.X, 0, currentVel.Z).Magnitude
        local upwardSpeed = currentVel.Y
        local timeSinceJump = now - lastJumpTime
        local isJumpVelocity = timeSinceJump < 0.3
        if horizontalSpeed > 40 or (upwardSpeed > 35 and not isJumpVelocity) then
            isCountering = true
            counterEndTime = now + 0.5
        end
        if isCountering and now < counterEndTime then
            rootPart.AssemblyLinearVelocity = Vector3.zero
            if lastSafePos then rootPart.CFrame = CFrame.new(lastSafePos) end
        else
            isCountering = false
            lastSafePos = rootPart.Position
        end
    end)
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
        if plot:IsA("Model") then
            if plot:GetAttribute("OwnerUserId") == LocalPlayer.UserId then return plot end
        end
    end
    return nil
end

local lastLockState = nil

local function startAutoLock()
    if autoLockConnection then return end
    autoLockConnection = task.spawn(function()
        while autoLockEnabled do
            local myPlot = findMyPlot()
            if myPlot and rootPart and humanoid then
                local lockObj = myPlot:FindFirstChild("Lock")
                if lockObj and lockObj.Name == "Lock" then
                    local currentState = lockObj:GetAttribute(LOCK_STATE_ATTR) or STATE_IDLE
                    local pad = lockObj:FindFirstChild("Pad")
                    if currentState ~= lastLockState then
                        if currentState == STATE_IDLE then
                            task.spawn(function() notify("База открыта", "База разблокирована", "warning") end)
                        elseif currentState == STATE_LOCKED then
                            task.spawn(function() notify("База закрыта", "Auto Lock активирован", "success") end)
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
    end)
end

local function stopAutoLock()
    if autoLockConnection then task.cancel(autoLockConnection); autoLockConnection = nil end
    lastLockState = nil
end

--------------------------------------------------
-- WALL HOP
--------------------------------------------------
local wallHopActive = false
local wallHopWasClimbing = false
local wallHopClearTimer = 0

RunService.Heartbeat:Connect(function()
    if not wallHopEnabled or not rootPart or not humanoid then
        wallHopActive = false
        wallHopWasClimbing = false
        return
    end
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    local forwardDirection = rootPart.CFrame.LookVector
    local result = workspace:Raycast(rootPart.Position, forwardDirection * 3, rayParams)
    if result then
        wallHopActive = true
        wallHopWasClimbing = true
        wallHopClearTimer = 0
        local upVel = 20 + math.random(-1, 3)
        local currentVel = rootPart.AssemblyLinearVelocity
        rootPart.AssemblyLinearVelocity = Vector3.new(currentVel.X, upVel, currentVel.Z)
    else
        if wallHopWasClimbing then
            wallHopClearTimer = wallHopClearTimer + 1
            if wallHopClearTimer < 8 then
                rootPart.AssemblyLinearVelocity = Vector3.new(forwardDirection.X * 25, 30, forwardDirection.Z * 25)
            else
                wallHopWasClimbing = false
                wallHopClearTimer = 0
            end
        end
        wallHopActive = false
    end
end)

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

local function startAntiAfk()
    if antiAfkConnection then return end
    local VirtualUser = game:GetService("VirtualUser")
    antiAfkConnection = LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end

local function stopAntiAfk()
    if antiAfkConnection then antiAfkConnection:Disconnect(); antiAfkConnection = nil end
end

local baseDebounce = false

local function smoothVerticalMove(distance, direction)
    if not rootPart or baseDebounce then return end
    baseDebounce = true
    local startPos = rootPart.Position
    local targetY = startPos.Y + (distance * direction)
    task.spawn(function()
        local originalCollide = rootPart.CanCollide
        pcall(function() rootPart.CanCollide = false end)
        local steps = math.abs(distance) * 4
        local stepSize = (distance / steps) * direction
        for i = 1, steps do
            if not rootPart then break end
            rootPart.CFrame = rootPart.CFrame + Vector3.new(0, stepSize, 0)
            task.wait(0.005)
        end
        if rootPart then
            rootPart.CFrame = CFrame.new(rootPart.Position.X, targetY, rootPart.Position.Z) * CFrame.Angles(0, math.rad(rootPart.Orientation.Y), 0)
            pcall(function() rootPart.CanCollide = originalCollide end)
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
                if Server.id and Server.playing and Server.maxPlayers then
                    table.insert(AllServers, Server)
                end
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
-- UI FRAMEWORK (КАК НА ФОТО)
--------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SSSHubSteal"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 999999
ScreenGui.Parent = CoreGui

-- Floating Toggle Button
local ToggleBtnFloat = Instance.new("TextButton")
ToggleBtnFloat.Size = UDim2.new(0, 0, 0, 0)
ToggleBtnFloat.Position = UDim2.new(0, 20, 0.5, -20)
ToggleBtnFloat.BackgroundColor3 = Theme.Accent
ToggleBtnFloat.BorderSizePixel = 0
ToggleBtnFloat.Text = "⚡"
ToggleBtnFloat.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtnFloat.TextSize = 16
ToggleBtnFloat.Font = Enum.Font.GothamBold
ToggleBtnFloat.Visible = false
ToggleBtnFloat.Parent = ScreenGui

local FloatCorner = Instance.new("UICorner")
FloatCorner.CornerRadius = UDim.new(0, 10)
FloatCorner.Parent = ToggleBtnFloat

local FloatStroke = Instance.new("UIStroke")
FloatStroke.Color = Theme.Stroke
FloatStroke.Thickness = 1.5
FloatStroke.Parent = ToggleBtnFloat

table.insert(AccentTracker.Static, ToggleBtnFloat)

-- Main Window
local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 440, 0, 0)
Main.Position = UDim2.new(0.5, -220, 0.5, -155)
Main.BackgroundColor3 = Theme.Background
Main.BorderSizePixel = 0
Main.Active = true
Main.Parent = ScreenGui

TweenService:Create(Main, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(0, 440, 0, 310)}):Play()

MakeDraggable(Main)

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Theme.Stroke
MainStroke.Thickness = 1.5
MainStroke.Parent = Main

-- Sidebar
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 130, 1, 0)
Sidebar.BackgroundColor3 = Theme.Sidebar
Sidebar.BorderSizePixel = 0
Sidebar.Parent = Main

local SidebarCorner = Instance.new("UICorner")
SidebarCorner.CornerRadius = UDim.new(0, 10)
SidebarCorner.Parent = Sidebar

-- Header
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, -130, 0, 50)
Header.Position = UDim2.new(0, 130, 0, 0)
Header.BackgroundTransparency = 1
Header.Parent = Main

local Logo = Instance.new("Frame")
Logo.Size = UDim2.new(0, 26, 0, 26)
Logo.Position = UDim2.new(0, 15, 0.5, -13)
Logo.BackgroundColor3 = Theme.Accent
Logo.Parent = Header

local LogoCorner = Instance.new("UICorner")
LogoCorner.CornerRadius = UDim.new(0, 8)
LogoCorner.Parent = Logo

local LogoIcon = Instance.new("TextLabel")
LogoIcon.Size = UDim2.new(1, 0, 1, 0)
LogoIcon.BackgroundTransparency = 1
LogoIcon.Text = "⚡"
LogoIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
LogoIcon.TextSize = 14
LogoIcon.Font = Enum.Font.GothamBold
LogoIcon.Parent = Logo

table.insert(AccentTracker.Static, Logo)

local TitleLbl = Instance.new("TextLabel")
TitleLbl.Size = UDim2.new(0, 150, 0, 16)
TitleLbl.Position = UDim2.new(0, 50, 0, 10)
TitleLbl.BackgroundTransparency = 1
TitleLbl.Text = "SSS HUB STEAL"
TitleLbl.TextColor3 = Theme.Text
TitleLbl.TextSize = 11
TitleLbl.Font = Enum.Font.GothamBold
TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
TitleLbl.Parent = Header

local SubTitleLbl = Instance.new("TextLabel")
SubTitleLbl.Size = UDim2.new(0, 200, 0, 12)
SubTitleLbl.Position = UDim2.new(0, 50, 0, 27)
SubTitleLbl.BackgroundTransparency = 1
SubTitleLbl.Text = "Game Enhancement"
SubTitleLbl.TextColor3 = Theme.TextDark
SubTitleLbl.TextSize = 8
SubTitleLbl.Font = Enum.Font.Gotham
SubTitleLbl.TextXAlignment = Enum.TextXAlignment.Left
SubTitleLbl.Parent = Header

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 22, 0, 22)
CloseBtn.Position = UDim2.new(1, -32, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(80, 30, 30)
CloseBtn.BorderSizePixel = 0
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 10
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = Header

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseBtn

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

-- Sidebar Layout
local SidebarLayout = Instance.new("UIListLayout")
SidebarLayout.FillDirection = Enum.FillDirection.Vertical
SidebarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
SidebarLayout.VerticalAlignment = Enum.VerticalAlignment.Top
SidebarLayout.Padding = UDim.new(0, 5)
SidebarLayout.Parent = Sidebar

-- Tab System
local Pages = {}
local TabButtons = {}
local CurrentActivePage = nil

local function switchTab(tabName)
    for name, page in pairs(Pages) do
        if name == tabName then
            page.Visible = true
            CurrentActivePage = page
        else
            page.Visible = false
        end
    end
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
    local TabBtn = Instance.new("TextButton")
    TabBtn.Size = UDim2.new(0.9, 0, 0, 30)
    TabBtn.BackgroundColor3 = Theme.Sidebar
    TabBtn.BorderSizePixel = 0
    TabBtn.Text = "  " .. icon .. "  " .. text
    TabBtn.TextColor3 = Theme.TextDark
    TabBtn.TextSize = 11
    TabBtn.Font = Enum.Font.GothamBold
    TabBtn.TextXAlignment = Enum.TextXAlignment.Left
    TabBtn.Parent = Sidebar

    local TabCorner = Instance.new("UICorner")
    TabCorner.CornerRadius = UDim.new(0, 6)
    TabCorner.Parent = TabBtn

    TabBtn.MouseButton1Click:Connect(function()
        playClick()
        switchTab(text)
    end)

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

    local Page = Instance.new("ScrollingFrame")
    Page.Size = UDim2.new(1, -150, 1, -60)
    Page.Position = UDim2.new(0, 135, 0, 55)
    Page.BackgroundTransparency = 1
    Page.BorderSizePixel = 0
    Page.ScrollBarThickness = 2
    Page.ScrollBarImageColor3 = Theme.Stroke
    Page.Visible = false
    Page.Parent = Main

    local PageLayout = Instance.new("UIListLayout")
    PageLayout.FillDirection = Enum.FillDirection.Vertical
    PageLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    PageLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    PageLayout.Padding = UDim.new(0, 8)
    PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
    PageLayout.Parent = Page

    Pages[text] = Page
    TabButtons[text] = {btn = TabBtn, isActive = false}
    AccentTracker.Tabs[text] = TabButtons[text]

    return Page
end

-- One separator after all tabs
local TabSeparator = Instance.new("Frame")
TabSeparator.Size = UDim2.new(0.8, 0, 0, 1)
TabSeparator.BackgroundTransparency = 0.5
TabSeparator.BackgroundColor3 = Theme.Stroke
TabSeparator.BorderSizePixel = 0
TabSeparator.Parent = Sidebar

-- Hover Function
local function AddHover(btn)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.CardHover}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Card}):Play()
    end)
end

--------------------------------------------------
-- KEYBIND REBIND SYSTEM
--------------------------------------------------
local isListeningKeybind = false

local function CreateKeybindButton(parent, name, defaultKey, callback)
    local currentKey = GetKeybind(name, defaultKey)
    
    local keyBtn = Instance.new("TextButton")
    keyBtn.Size = UDim2.new(0, 35, 0, 18)
    keyBtn.Position = UDim2.new(1, -80, 0.5, -9)
    keyBtn.BackgroundColor3 = Theme.Background
    keyBtn.BorderSizePixel = 0
    keyBtn.Text = currentKey or "None"
    keyBtn.TextColor3 = Theme.TextDark
    keyBtn.TextSize = 9
    keyBtn.Font = Enum.Font.GothamBold
    keyBtn.Parent = parent

    local keyCorner = Instance.new("UICorner")
    keyCorner.CornerRadius = UDim.new(0, 4)
    keyCorner.Parent = keyBtn

    local keyStroke = Instance.new("UIStroke")
    keyStroke.Color = Theme.Stroke
    keyStroke.Thickness = 1
    keyStroke.Parent = keyBtn

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
        UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed or isListeningKeybind then return end
            if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == currentKey then
                callback()
            end
        end)
    end

    return keyBtn
end

-- UI Element Creators
local function CreateToggle(parent, text, callback, layoutOrder, defaultKeybind)
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, -10, 0, 38)
    Container.BackgroundColor3 = Theme.Card
    Container.BorderSizePixel = 0
    Container.LayoutOrder = layoutOrder or 0
    Container.Name = text
    Container.Parent = parent

    local ContainerCorner = Instance.new("UICorner")
    ContainerCorner.CornerRadius = UDim.new(0, 8)
    ContainerCorner.Parent = Container

    local ContainerStroke = Instance.new("UIStroke")
    ContainerStroke.Color = Theme.Stroke
    ContainerStroke.Thickness = 1
    ContainerStroke.Parent = Container

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -120, 1, 0)
    Label.Position = UDim2.new(0, 12, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Theme.Text
    Label.TextSize = 12
    Label.Font = Enum.Font.GothamBold
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Container

    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Size = UDim2.new(0, 38, 0, 19)
    ToggleBtn.Position = UDim2.new(1, -48, 0.5, -10)
    ToggleBtn.BackgroundColor3 = Theme.ToggleOff
    ToggleBtn.BorderSizePixel = 0
    ToggleBtn.Text = ""
    ToggleBtn.Parent = Container

    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.CornerRadius = UDim.new(1, 0)
    ToggleCorner.Parent = ToggleBtn

    local Circle = Instance.new("Frame")
    Circle.Size = UDim2.new(0, 15, 0, 15)
    Circle.Position = UDim2.new(0, 2, 0.5, -8)
    Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Circle.BorderSizePixel = 0
    Circle.Parent = ToggleBtn

    local CircleCorner = Instance.new("UICorner")
    CircleCorner.CornerRadius = UDim.new(1, 0)
    CircleCorner.Parent = Circle

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

    ToggleBtn.MouseButton1Click:Connect(function()
        playClick()
        setToggleState(not state)
    end)

    if defaultKeybind then
        CreateKeybindButton(Container, text, defaultKeybind, function()
            playClick()
            setToggleState(not state)
        end)
    end

    if Config[text] == true then
        task.spawn(function()
            task.wait(0.1)
            setToggleState(true)
        end)
    end

    return Container
end

local function CreateButton(parent, text, callback, layoutOrder, defaultKeybind)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 33)
    btn.BackgroundColor3 = Theme.Card
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = Theme.Text
    btn.TextSize = 11
    btn.Font = Enum.Font.GothamBold
    btn.LayoutOrder = layoutOrder or 0
    btn.Name = text
    btn.Parent = parent
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn
    local stroke = Instance.new("UIStroke")
    stroke.Color = Theme.Stroke
    stroke.Thickness = 1
    stroke.Parent = btn
    AddHover(btn)
    
    btn.MouseButton1Click:Connect(function()
        playClick()
        callback()
    end)

    if defaultKeybind then
        CreateKeybindButton(btn, text, defaultKeybind, function()
            playClick()
            callback()
        end)
    end

    return btn
end

local function CreatePopupMenu(title, width, height)
    local menu = Instance.new("Frame")
    menu.Size = UDim2.new(0, width, 0, height)
    menu.Position = UDim2.new(0.5, -width/2, 0.5, -height/2)
    menu.BackgroundColor3 = Theme.Card
    menu.BorderSizePixel = 0
    menu.Visible = false
    menu.Active = true
    menu.ZIndex = 20
    menu.Parent = ScreenGui
    MakeDraggable(menu)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = menu
    local stroke = Instance.new("UIStroke")
    stroke.Color = Theme.Stroke
    stroke.Thickness = 1.5
    stroke.Parent = menu
    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -10, 0, 25)
    titleLbl.Position = UDim2.new(0, 10, 0, 5)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = title
    titleLbl.TextColor3 = Theme.Text
    titleLbl.TextSize = 12
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.ZIndex = 21
    titleLbl.Parent = menu
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 20, 0, 20)
    closeBtn.Position = UDim2.new(1, -25, 0, 5)
    closeBtn.BackgroundColor3 = Color3.fromRGB(80, 30, 30)
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 9
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.ZIndex = 21
    closeBtn.Parent = menu
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 5)
    closeCorner.Parent = closeBtn
    closeBtn.MouseButton1Click:Connect(function() playClick() menu.Visible = false end)
    return menu
end

--------------------------------------------------
-- BUILD PAGES
--------------------------------------------------
local BypassMenu
local PetFilterMenu

local MainPage = CreateTab("Main", "🏠")
local CombatPage = CreateTab("Combat", "⚔️")
local ServerPage = CreateTab("Server", "📡")
local SettingsPage = CreateTab("Settings", "⚙️")

-- MAIN PAGE
CreateToggle(MainPage, "Auto Run", function(state)
    autoRun = state
    Config.autoRun = state
    SaveConfig()
    notify("Auto Run", state and "Enabled" or "Disabled", "info")
end, 1)

CreateToggle(MainPage, "Player ESP", function(state)
    espEnabled = state
    Config.espEnabled = state
    SaveConfig()
    updateESP()
    notify("Player ESP", state and "Enabled" or "Disabled", "info")
end, 2, "T")

CreateToggle(MainPage, "Pets ESP", function(state)
    petsEspEnabled = state
    Config.petsEspEnabled = state
    SaveConfig()
    if not petsEspEnabled then
        for pet, _ in pairs(espTracker) do removePetESP(pet) end
    end
    notify("Pets ESP", state and "Enabled" or "Disabled", "info")
end, 3, "Y")

CreateToggle(MainPage, "Anti Fall", function(state)
    antiFallEnabled = state
    Config.antiFallEnabled = state
    SaveConfig()
    if antiFallEnabled then AntiFall = CreateAntiFall() else RemoveAntiFall() end
    notify("Anti Fall", state and "Enabled" or "Disabled", "info")
end, 4)

CreateToggle(MainPage, "Anti AFK", function(state)
    antiAfkEnabled = state
    Config.antiAfkEnabled = state
    SaveConfig()
    if antiAfkEnabled then startAntiAfk() else stopAntiAfk() end
    notify("Anti AFK", state and "Enabled" or "Disabled", "info")
end, 5)

CreateButton(MainPage, "Pet Filter", function()
    PetFilterMenu.Visible = not PetFilterMenu.Visible
end, 6)

CreateButton(MainPage, "Bypass Menu", function()
    BypassMenu.Visible = not BypassMenu.Visible
end, 7, "B")

-- COMBAT PAGE
CreateToggle(CombatPage, "Anti Knockback", function(state)
    antiKnockbackEnabled = state
    Config.antiKnockbackEnabled = state
    SaveConfig()
    if antiKnockbackEnabled then startAntiKnockback() else stopAntiKnockback() end
    notify("Anti Knockback", state and "Enabled" or "Disabled", "info")
end, 1, "G")

CreateToggle(CombatPage, "Auto Lock Base", function(state)
    autoLockEnabled = state
    Config.autoLockEnabled = state
    SaveConfig()
    if autoLockEnabled then startAutoLock() else stopAutoLock() end
    notify("Auto Lock", state and "Enabled" or "Disabled", "info")
end, 2)

--------------------------------------------------
-- SETTINGS PAGE
--------------------------------------------------
-- Save Config Toggle
local SaveConfigContainer = Instance.new("Frame")
SaveConfigContainer.Size = UDim2.new(1, -10, 0, 38)
SaveConfigContainer.BackgroundColor3 = Theme.Card
SaveConfigContainer.BorderSizePixel = 0
SaveConfigContainer.LayoutOrder = 1
SaveConfigContainer.Parent = SettingsPage

local SaveConfigCorner = Instance.new("UICorner")
SaveConfigCorner.CornerRadius = UDim.new(0, 8)
SaveConfigCorner.Parent = SaveConfigContainer

local SaveConfigStroke = Instance.new("UIStroke")
SaveConfigStroke.Color = Theme.Stroke
SaveConfigStroke.Thickness = 1
SaveConfigStroke.Parent = SaveConfigContainer

local SaveConfigLabel = Instance.new("TextLabel")
SaveConfigLabel.Size = UDim2.new(1, -65, 1, 0)
SaveConfigLabel.Position = UDim2.new(0, 12, 0, 0)
SaveConfigLabel.BackgroundTransparency = 1
SaveConfigLabel.Text = "Save Config"
SaveConfigLabel.TextColor3 = Theme.Text
SaveConfigLabel.TextSize = 12
SaveConfigLabel.Font = Enum.Font.GothamBold
SaveConfigLabel.TextXAlignment = Enum.TextXAlignment.Left
SaveConfigLabel.Parent = SaveConfigContainer

local SaveConfigToggleBtn = Instance.new("TextButton")
SaveConfigToggleBtn.Size = UDim2.new(0, 38, 0, 19)
SaveConfigToggleBtn.Position = UDim2.new(1, -48, 0.5, -10)
SaveConfigToggleBtn.BackgroundColor3 = SaveConfigEnabled and Theme.ToggleOn or Theme.ToggleOff
SaveConfigToggleBtn.BorderSizePixel = 0
SaveConfigToggleBtn.Text = ""
SaveConfigToggleBtn.Parent = SaveConfigContainer

local SaveConfigToggleCorner = Instance.new("UICorner")
SaveConfigToggleCorner.CornerRadius = UDim.new(1, 0)
SaveConfigToggleCorner.Parent = SaveConfigToggleBtn

local SaveConfigCircle = Instance.new("Frame")
SaveConfigCircle.Size = UDim2.new(0, 15, 0, 15)
SaveConfigCircle.Position = SaveConfigEnabled and UDim2.new(1, -17, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
SaveConfigCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SaveConfigCircle.BorderSizePixel = 0
SaveConfigCircle.Parent = SaveConfigToggleBtn

local SaveConfigCircleCorner = Instance.new("UICorner")
SaveConfigCircleCorner.CornerRadius = UDim.new(1, 0)
SaveConfigCircleCorner.Parent = SaveConfigCircle

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

-- Accent Color Section
local ColorLabel = Instance.new("TextLabel")
ColorLabel.Size = UDim2.new(1, -10, 0, 20)
ColorLabel.BackgroundTransparency = 1
ColorLabel.Text = "Accent Color"
ColorLabel.TextColor3 = Theme.Text
ColorLabel.TextSize = 12
ColorLabel.Font = Enum.Font.GothamBold
ColorLabel.TextXAlignment = Enum.TextXAlignment.Left
ColorLabel.LayoutOrder = 2
ColorLabel.Parent = SettingsPage

local ColorContainer = Instance.new("Frame")
ColorContainer.Size = UDim2.new(1, -10, 0, 40)
ColorContainer.BackgroundTransparency = 1
ColorContainer.LayoutOrder = 3
ColorContainer.Parent = SettingsPage

local ColorLayout = Instance.new("UIListLayout")
ColorLayout.FillDirection = Enum.FillDirection.Horizontal
ColorLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
ColorLayout.VerticalAlignment = Enum.VerticalAlignment.Center
ColorLayout.Padding = UDim.new(0, 8)
ColorLayout.Parent = ColorContainer

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
    local swatch = Instance.new("TextButton")
    swatch.Size = UDim2.new(0, 28, 0, 28)
    swatch.BackgroundColor3 = preset.color
    swatch.BorderSizePixel = 0
    swatch.Text = ""
    swatch.Parent = ColorContainer

    local swatchCorner = Instance.new("UICorner")
    swatchCorner.CornerRadius = UDim.new(0, 6)
    swatchCorner.Parent = swatch

    local swatchStroke = Instance.new("UIStroke")
    swatchStroke.Color = Color3.fromRGB(255, 255, 255)
    swatchStroke.Thickness = 0
    swatchStroke.Parent = swatch

    AddHover(swatch)

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

-- Info text
local InfoLabel = Instance.new("TextLabel")
InfoLabel.Size = UDim2.new(1, -10, 0, 40)
InfoLabel.BackgroundTransparency = 1
InfoLabel.Text = "Click on a key (e.g. T, Y, G) next to a function to rebind it.\nPress ESC to cancel."
InfoLabel.TextColor3 = Theme.TextDark
InfoLabel.TextSize = 10
InfoLabel.Font = Enum.Font.Gotham
InfoLabel.TextXAlignment = Enum.TextXAlignment.Left
InfoLabel.TextWrapped = true
InfoLabel.LayoutOrder = 4
InfoLabel.Parent = SettingsPage

--------------------------------------------------
-- BYPASS MENU
--------------------------------------------------
BypassMenu = CreatePopupMenu("BYPASS", 200, 200)

-- Wall Hop Toggle (direct creation)
local WallHopContainer = Instance.new("Frame")
WallHopContainer.Size = UDim2.new(0, 180, 0, 35)
WallHopContainer.Position = UDim2.new(0, 10, 0, 35)
WallHopContainer.BackgroundColor3 = Theme.Background
WallHopContainer.BorderSizePixel = 0
WallHopContainer.ZIndex = 21
WallHopContainer.Parent = BypassMenu

local WallHopCorner = Instance.new("UICorner")
WallHopCorner.CornerRadius = UDim.new(0, 6)
WallHopCorner.Parent = WallHopContainer

local WallHopLabel = Instance.new("TextLabel")
WallHopLabel.Size = UDim2.new(1, -50, 1, 0)
WallHopLabel.Position = UDim2.new(0, 10, 0, 0)
WallHopLabel.BackgroundTransparency = 1
WallHopLabel.Text = "Wall Hop"
WallHopLabel.TextColor3 = Theme.Text
WallHopLabel.TextSize = 11
WallHopLabel.Font = Enum.Font.GothamBold
WallHopLabel.TextXAlignment = Enum.TextXAlignment.Left
WallHopLabel.ZIndex = 22
WallHopLabel.Parent = WallHopContainer

local WallHopToggleBtn = Instance.new("TextButton")
WallHopToggleBtn.Size = UDim2.new(0, 38, 0, 19)
WallHopToggleBtn.Position = UDim2.new(1, -44, 0.5, -10)
WallHopToggleBtn.BackgroundColor3 = Theme.ToggleOff
WallHopToggleBtn.BorderSizePixel = 0
WallHopToggleBtn.Text = ""
WallHopToggleBtn.ZIndex = 22
WallHopToggleBtn.Parent = WallHopContainer

local WallHopToggleCorner = Instance.new("UICorner")
WallHopToggleCorner.CornerRadius = UDim.new(1, 0)
WallHopToggleCorner.Parent = WallHopToggleBtn

local WallHopCircle = Instance.new("Frame")
WallHopCircle.Size = UDim2.new(0, 15, 0, 15)
WallHopCircle.Position = UDim2.new(0, 2, 0.5, -8)
WallHopCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
WallHopCircle.BorderSizePixel = 0
WallHopCircle.ZIndex = 23
WallHopCircle.Parent = WallHopToggleBtn

local WallHopCircleCorner = Instance.new("UICorner")
WallHopCircleCorner.CornerRadius = UDim.new(1, 0)
WallHopCircleCorner.Parent = WallHopCircle

local wallHopState = false
local wallHopToggleData = {btn = WallHopToggleBtn, isOn = false}
table.insert(AccentTracker.Toggles, wallHopToggleData)

WallHopToggleBtn.MouseButton1Click:Connect(function()
    playClick()
    wallHopState = not wallHopState
    wallHopEnabled = wallHopState
    wallHopToggleData.isOn = wallHopState
    Config["Wall Hop"] = wallHopState
    SaveConfig()
    if wallHopState then
        TweenService:Create(WallHopToggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.ToggleOn}):Play()
        TweenService:Create(WallHopCircle, TweenInfo.new(0.2), {Position = UDim2.new(1, -17, 0.5, -8)}):Play()
    else
        TweenService:Create(WallHopToggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.ToggleOff}):Play()
        TweenService:Create(WallHopCircle, TweenInfo.new(0.2), {Position = UDim2.new(0, 2, 0.5, -8)}):Play()
    end
    notify("Wall Hop", wallHopState and "Enabled" or "Disabled", "info")
end)

if Config["Wall Hop"] == true then
    task.spawn(function()
        task.wait(0.2)
        wallHopState = true
        wallHopEnabled = true
        wallHopToggleData.isOn = true
        TweenService:Create(WallHopToggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.ToggleOn}):Play()
        TweenService:Create(WallHopCircle, TweenInfo.new(0.2), {Position = UDim2.new(1, -17, 0.5, -8)}):Play()
    end)
end

-- Enter Base button
local EnterBaseBtn = Instance.new("TextButton")
EnterBaseBtn.Size = UDim2.new(0, 180, 0, 30)
EnterBaseBtn.Position = UDim2.new(0, 10, 0, 80)
EnterBaseBtn.BackgroundColor3 = Theme.Background
EnterBaseBtn.BorderSizePixel = 0
EnterBaseBtn.Text = "Enter Base"
EnterBaseBtn.TextColor3 = Theme.Text
EnterBaseBtn.TextSize = 11
EnterBaseBtn.Font = Enum.Font.GothamBold
EnterBaseBtn.ZIndex = 21
EnterBaseBtn.Parent = BypassMenu

local EnterBaseCorner = Instance.new("UICorner")
EnterBaseCorner.CornerRadius = UDim.new(0, 6)
EnterBaseCorner.Parent = EnterBaseBtn

AddHover(EnterBaseBtn)

EnterBaseBtn.MouseButton1Click:Connect(function()
    playClick()
    smoothVerticalMove(DOWN_DISTANCE, -1)
    notify("Enter Base", "Moving down", "info")
end)

-- Exit Base button
local ExitBaseBtn = Instance.new("TextButton")
ExitBaseBtn.Size = UDim2.new(0, 180, 0, 30)
ExitBaseBtn.Position = UDim2.new(0, 10, 0, 120)
ExitBaseBtn.BackgroundColor3 = Theme.Background
ExitBaseBtn.BorderSizePixel = 0
ExitBaseBtn.Text = "Exit Base"
ExitBaseBtn.TextColor3 = Theme.Text
ExitBaseBtn.TextSize = 11
ExitBaseBtn.Font = Enum.Font.GothamBold
ExitBaseBtn.ZIndex = 21
ExitBaseBtn.Parent = BypassMenu

local ExitBaseCorner = Instance.new("UICorner")
ExitBaseCorner.CornerRadius = UDim.new(0, 6)
ExitBaseCorner.Parent = ExitBaseBtn

AddHover(ExitBaseBtn)

ExitBaseBtn.MouseButton1Click:Connect(function()
    playClick()
    smoothVerticalMove(UP_DISTANCE, 1)
    notify("Exit Base", "Moving up", "info")
end)

-- Keybinds for Bypass
CreateKeybindButton(EnterBaseBtn, "Enter Base", "Q", function()
    playClick()
    smoothVerticalMove(DOWN_DISTANCE, -1)
    notify("Enter Base", "Moving down", "info")
end)

CreateKeybindButton(ExitBaseBtn, "Exit Base", "R", function()
    playClick()
    smoothVerticalMove(UP_DISTANCE, 1)
    notify("Exit Base", "Moving up", "info")
end)

--------------------------------------------------
-- PET FILTER MENU
--------------------------------------------------
PetFilterMenu = CreatePopupMenu("PET FILTERS", 240, 160)

local filterNameLbl = Instance.new("TextLabel")
filterNameLbl.Size = UDim2.new(0.4, 0, 0, 18)
filterNameLbl.Position = UDim2.new(0, 10, 0, 35)
filterNameLbl.BackgroundTransparency = 1
filterNameLbl.Text = "Name:"
filterNameLbl.TextColor3 = Theme.TextDark
filterNameLbl.TextSize = 10
filterNameLbl.Font = Enum.Font.Gotham
filterNameLbl.TextXAlignment = Enum.TextXAlignment.Left
filterNameLbl.ZIndex = 21
filterNameLbl.Parent = PetFilterMenu

local nameBox = Instance.new("TextBox")
nameBox.Size = UDim2.new(0.55, 0, 0, 22)
nameBox.Position = UDim2.new(0.4, 0, 0, 33)
nameBox.BackgroundColor3 = Theme.Background
nameBox.BorderSizePixel = 0
nameBox.Text = ""
nameBox.PlaceholderText = "e.g. Dragon"
nameBox.TextColor3 = Theme.Text
nameBox.PlaceholderColor3 = Theme.TextDark
nameBox.TextSize = 10
nameBox.Font = Enum.Font.Gotham
nameBox.ZIndex = 21
nameBox.Parent = PetFilterMenu

local nameBoxCorner = Instance.new("UICorner")
nameBoxCorner.CornerRadius = UDim.new(0, 6)
nameBoxCorner.Parent = nameBox

local nameBoxStroke = Instance.new("UIStroke")
nameBoxStroke.Color = Theme.Stroke
nameBoxStroke.Thickness = 1
nameBoxStroke.Parent = nameBox

local filterMpsLbl = Instance.new("TextLabel")
filterMpsLbl.Size = UDim2.new(0.4, 0, 0, 18)
filterMpsLbl.Position = UDim2.new(0, 10, 0, 65)
filterMpsLbl.BackgroundTransparency = 1
filterMpsLbl.Text = "Min MPS:"
filterMpsLbl.TextColor3 = Theme.TextDark
filterMpsLbl.TextSize = 10
filterMpsLbl.Font = Enum.Font.Gotham
filterMpsLbl.TextXAlignment = Enum.TextXAlignment.Left
filterMpsLbl.ZIndex = 21
filterMpsLbl.Parent = PetFilterMenu

local mpsBox = Instance.new("TextBox")
mpsBox.Size = UDim2.new(0.55, 0, 0, 22)
mpsBox.Position = UDim2.new(0.4, 0, 0, 63)
mpsBox.BackgroundColor3 = Theme.Background
mpsBox.BorderSizePixel = 0
mpsBox.Text = "0"
mpsBox.TextColor3 = Theme.Text
mpsBox.TextSize = 10
mpsBox.Font = Enum.Font.Gotham
mpsBox.ZIndex = 21
mpsBox.Parent = PetFilterMenu

local mpsBoxCorner = Instance.new("UICorner")
mpsBoxCorner.CornerRadius = UDim.new(0, 6)
mpsBoxCorner.Parent = mpsBox

local mpsBoxStroke = Instance.new("UIStroke")
mpsBoxStroke.Color = Theme.Stroke
mpsBoxStroke.Thickness = 1
mpsBoxStroke.Parent = mpsBox

-- APPLY button - GREEN
local applyBtn = Instance.new("TextButton")
applyBtn.Size = UDim2.new(0, 95, 0, 28)
applyBtn.Position = UDim2.new(0.05, 5, 0, 105)
applyBtn.BackgroundColor3 = Color3.fromRGB(40, 100, 60)
applyBtn.BorderSizePixel = 0
applyBtn.Text = "APPLY"
applyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
applyBtn.TextSize = 10
applyBtn.Font = Enum.Font.GothamBold
applyBtn.ZIndex = 21
applyBtn.Parent = PetFilterMenu

local applyCorner = Instance.new("UICorner")
applyCorner.CornerRadius = UDim.new(0, 6)
applyCorner.Parent = applyBtn

AddHover(applyBtn)

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

-- CLEAR button - RED
local clearBtn = Instance.new("TextButton")
clearBtn.Size = UDim2.new(0, 95, 0, 28)
clearBtn.Position = UDim2.new(0.55, 0, 0, 105)
clearBtn.BackgroundColor3 = Color3.fromRGB(100, 40, 40)
clearBtn.BorderSizePixel = 0
clearBtn.Text = "CLEAR"
clearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
clearBtn.TextSize = 10
clearBtn.Font = Enum.Font.GothamBold
clearBtn.ZIndex = 21
clearBtn.Parent = PetFilterMenu

local clearCorner = Instance.new("UICorner")
clearCorner.CornerRadius = UDim.new(0, 6)
clearCorner.Parent = clearBtn

AddHover(clearBtn)

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
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -10, 0, 18)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Saved Jobs: " .. #SavedJobs
StatusLabel.TextColor3 = Theme.TextDark
StatusLabel.TextSize = 10
StatusLabel.Font = Enum.Font.GothamBold
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.LayoutOrder = 0
StatusLabel.Parent = ServerPage

CreateButton(ServerPage, "Copy & Save Job", function()
    local CurrentJobId = game.JobId
    if #SavedJobs >= 10 then
        notify("Server Hop", "Max 10 saved jobs!", "warning")
        return
    end
    for _, Data in ipairs(SavedJobs) do
        if Data.JobId == CurrentJobId then
            notify("Server Hop", "Already saved!", "warning")
            return
        end
    end
    table.insert(SavedJobs, {JobId = CurrentJobId, Name = "Server " .. (#SavedJobs + 1)})
    SaveJobs()
    if setclipboard then setclipboard(CurrentJobId) end
    notify("Server Hop", "Saved & Copied!", "success")
    StatusLabel.Text = "Saved Jobs: " .. #SavedJobs
    UpdateServerList()
end, 1)

CreateButton(ServerPage, "Reconnect", function()
    TeleportService:TeleportToPlaceInstance(PlaceId, game.JobId, LocalPlayer)
end, 2)

CreateButton(ServerPage, "Join Busy Server", function()
    if ServerSearching then return end
    ServerSearching = true
    StatusLabel.Text = "Searching busy..."
    local Server = FindServer("BUSY")
    if Server then
        StatusLabel.Text = "Joining: " .. Server.playing .. "/" .. Server.maxPlayers
        task.wait(0.5)
        TeleportService:TeleportToPlaceInstance(PlaceId, Server.id, LocalPlayer)
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
        TeleportService:TeleportToPlaceInstance(PlaceId, Server.id, LocalPlayer)
    else
        StatusLabel.Text = "Not found!"
        notify("Server Hop", "No empty servers found", "warning")
    end
    ServerSearching = false
end, 4)

-- Separator
local serverSep = Instance.new("Frame")
serverSep.Size = UDim2.new(1, -10, 0, 1)
serverSep.BackgroundColor3 = Theme.Stroke
serverSep.BackgroundTransparency = 0.5
serverSep.BorderSizePixel = 0
serverSep.LayoutOrder = 5
serverSep.Name = "Sep"
serverSep.Parent = ServerPage

-- Server list container
local ServerListContainer = Instance.new("Frame")
ServerListContainer.Size = UDim2.new(1, 0, 0, 0)
ServerListContainer.BackgroundTransparency = 1
ServerListContainer.LayoutOrder = 6
ServerListContainer.AutomaticSize = Enum.AutomaticSize.Y
ServerListContainer.Parent = ServerPage

local ServerListLayout = Instance.new("UIListLayout")
ServerListLayout.FillDirection = Enum.FillDirection.Vertical
ServerListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
ServerListLayout.VerticalAlignment = Enum.VerticalAlignment.Top
ServerListLayout.Padding = UDim.new(0, 5)
ServerListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ServerListLayout.Parent = ServerListContainer

function UpdateServerList()
    for _, child in ipairs(ServerListContainer:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    for index, Data in ipairs(SavedJobs) do
        local Row = Instance.new("Frame")
        Row.Size = UDim2.new(1, -4, 0, 30)
        Row.BackgroundColor3 = Theme.Card
        Row.BorderSizePixel = 0
        Row.LayoutOrder = index
        Row.Parent = ServerListContainer

        local RowCorner = Instance.new("UICorner")
        RowCorner.CornerRadius = UDim.new(0, 6)
        RowCorner.Parent = Row

        local RowStroke = Instance.new("UIStroke")
        RowStroke.Color = Theme.Stroke
        RowStroke.Thickness = 1
        RowStroke.Parent = Row

        local JobText = Instance.new("TextLabel")
        JobText.Size = UDim2.new(1, -100, 1, 0)
        JobText.Position = UDim2.new(0, 10, 0, 0)
        JobText.BackgroundTransparency = 1
        JobText.Text = Data.Name or ("Server " .. index)
        JobText.TextColor3 = Theme.Text
        JobText.TextSize = 10
        JobText.Font = Enum.Font.Gotham
        JobText.TextXAlignment = Enum.TextXAlignment.Left
        JobText.Parent = Row

        local JoinBtn = Instance.new("TextButton")
        JoinBtn.Size = UDim2.new(0, 45, 1, -8)
        JoinBtn.Position = UDim2.new(1, -100, 0, 4)
        JoinBtn.BackgroundColor3 = Color3.fromRGB(40, 80, 50)
        JoinBtn.BorderSizePixel = 0
        JoinBtn.Text = "JOIN"
        JoinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        JoinBtn.TextSize = 9
        JoinBtn.Font = Enum.Font.GothamBold
        JoinBtn.Parent = Row
        AddHover(JoinBtn)

        local JoinCorner = Instance.new("UICorner")
        JoinCorner.CornerRadius = UDim.new(0, 4)
        JoinCorner.Parent = JoinBtn

        JoinBtn.MouseButton1Click:Connect(function()
            playClick()
            TeleportService:TeleportToPlaceInstance(PlaceId, Data.JobId, LocalPlayer)
        end)

        local DeleteBtn = Instance.new("TextButton")
        DeleteBtn.Size = UDim2.new(0, 35, 1, -8)
        DeleteBtn.Position = UDim2.new(1, -45, 0, 4)
        DeleteBtn.BackgroundColor3 = Color3.fromRGB(80, 40, 40)
        DeleteBtn.BorderSizePixel = 0
        DeleteBtn.Text = "X"
        DeleteBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        DeleteBtn.TextSize = 9
        DeleteBtn.Font = Enum.Font.GothamBold
        DeleteBtn.Parent = Row
        AddHover(DeleteBtn)

        local DelCorner = Instance.new("UICorner")
        DelCorner.CornerRadius = UDim.new(0, 4)
        DelCorner.Parent = DeleteBtn

        DeleteBtn.MouseButton1Click:Connect(function()
            playClick()
            table.remove(SavedJobs, index)
            SaveJobs()
            UpdateServerList()
            StatusLabel.Text = "Saved Jobs: " .. #SavedJobs
        end)
    end
end

-- Auto-update canvas size
task.spawn(function()
    while true do
        task.wait(0.5)
        for _, page in pairs(Pages) do
            local layout = page:FindFirstChildOfClass("UIListLayout")
            if layout then
                page.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
            end
        end
    end
end)

--------------------------------------------------
-- START
--------------------------------------------------
switchTab("Main")
UpdateServerList()
notify("SSS HUB", "Добро пожаловать в SSS HUB STEAL!", "info")
