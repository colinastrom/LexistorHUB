--// SSSHUB STEAL + MAIN
--// By Rosomax0 • Developer
--// UI REDESIGNED BY ENI
--// Exploit: Delta CodeX

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId

local GuiParent = game:GetService("CoreGui")
if type(gethui) == "function" then
    pcall(function()
        local hui = gethui()
        if hui then GuiParent = hui end
    end)
end

if GuiParent:FindFirstChild("SSSHubSteal") then GuiParent.SSSHubSteal:Destroy() end
if GuiParent:FindFirstChild("SSSNotify") then GuiParent.SSSNotify:Destroy() end

--// THEME
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

--// CONFIG SYSTEM
local ConfigFile = "SSSHubConfig.json"
local JobsFile = "SavedJobIDs.json"
local Config = {}
local SaveConfigEnabled = true

local function LoadJSON(path)
    if type(isfile) ~= "function" or type(readfile) ~= "function" then return nil end
    local okExists, exists = pcall(isfile, path)
    if not okExists or not exists then return nil end
    local okRead, txt = pcall(readfile, path)
    if not okRead or type(txt) ~= "string" then return nil end
    local okDecode, data = pcall(function() return HttpService:JSONDecode(txt) end)
    if okDecode and type(data) == "table" then return data end
    return nil
end

local function SaveJSON(path, data)
    if type(writefile) ~= "function" then return end
    local okEncode, encoded = pcall(function() return HttpService:JSONEncode(data) end)
    if okEncode then pcall(writefile, path, encoded) end
end

Config = LoadJSON(ConfigFile) or {}

if Config.SaveConfigEnabled ~= nil then
    SaveConfigEnabled = Config.SaveConfigEnabled
end

local Keybinds = Config.Keybinds or {}

local function SaveConfig(force)
    if (not SaveConfigEnabled) and (not force) then return end
    Config.Keybinds = Keybinds
    SaveJSON(ConfigFile, Config)
end

if Config.AccentColor and type(Config.AccentColor) == "table" then
    local c = Config.AccentColor
    if c[1] and c[2] and c[3] then
        Theme.Accent = Color3.fromRGB(c[1], c[2], c[3])
        Theme.ToggleOn = Theme.Accent
    end
end

--// HELPERS
local function new(className, props, parent)
    local inst = Instance.new(className)
    if props then
        for k, v in pairs(props) do inst[k] = v end
    end
    inst.Parent = parent
    return inst
end

local function tween(obj, time, props, style, dir)
    local info = TweenInfo.new(time, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out)
    local t = TweenService:Create(obj, info, props)
    t:Play()
    return t
end

local function corner(parent, radius)
    return new("UICorner", {CornerRadius = UDim.new(0, radius or 8)}, parent)
end

local function addStroke(parent, color, thickness)
    return new("UIStroke", {Color = color or Theme.Stroke, Thickness = thickness or 1}, parent)
end

local function UrlEncode(str)
    if str == nil then return "" end
    str = tostring(str)
    str = string.gsub(str, "\n", "\r\n")
    str = string.gsub(str, "([^%w%-%_%.%~])", function(c) return string.format("%%%02X", string.byte(c)) end)
    str = string.gsub(str, " ", "+")
    return str
end

--// ACCENT SYSTEM
local AccentTracker = { Static = {}, Toggles = {}, Tabs = {} }
local CurrentAccent = Theme.Accent

local function SetAccent(color)
    Theme.Accent = color
    Theme.ToggleOn = color
    CurrentAccent = color
    Config.AccentColor = {math.floor(color.R * 255), math.floor(color.G * 255), math.floor(color.B * 255)}
    SaveConfig()
    for _, elem in ipairs(AccentTracker.Static) do
        if elem and elem.Parent then tween(elem, 0.2, {BackgroundColor3 = color}) end
    end
    for _, toggle in ipairs(AccentTracker.Toggles) do
        if toggle.isOn and toggle.btn and toggle.btn.Parent then tween(toggle.btn, 0.2, {BackgroundColor3 = color}) end
    end
    for _, tabData in pairs(AccentTracker.Tabs) do
        if tabData.isActive and tabData.btn and tabData.btn.Parent then tween(tabData.btn, 0.2, {BackgroundColor3 = color}) end
    end
end

--// SOUND
local ClickSound = new("Sound", {SoundId = "rbxassetid://6895056283", Volume = 0.4}, Workspace)
local function playClick() pcall(function() ClickSound:Play() end) end

--// NOTIFICATION SYSTEM (Перенесено вверх для избежания ошибок области видимости)
local NotifyGui = new("ScreenGui", {Name = "SSSNotify", ResetOnSpawn = false, DisplayOrder = 999999}, GuiParent)
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
    corner(notif, 8)
    addStroke(notif, Theme.Stroke, 1.5)

    local iconCircle = new("Frame", {Size = UDim2.new(0, 40, 0, 40), Position = UDim2.new(0, 12, 0.5, -20), BackgroundColor3 = iconColor, BorderSizePixel = 0, Active = false}, notif)
    corner(iconCircle, 20)
    new("TextLabel", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = iconText, TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 18, Font = Enum.Font.GothamBold, Active = false}, iconCircle)

    new("TextLabel", {Size = UDim2.new(1, -70, 0, 20), Position = UDim2.new(0, 62, 0, 15), BackgroundTransparency = 1, Text = title, TextColor3 = Theme.Text, Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, Active = false}, notif)
    new("TextLabel", {Size = UDim2.new(1, -70, 0, 16), Position = UDim2.new(0, 62, 0, 38), BackgroundTransparency = 1, Text = text, TextColor3 = Theme.TextDark, Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Active = false}, notif)

    local progress = new("Frame", {Size = UDim2.new(1, 0, 0, 3), Position = UDim2.new(0, 0, 1, -3), BackgroundColor3 = iconColor, BorderSizePixel = 0, Active = false}, notif)
    corner(progress, 2)

    notif.BackgroundTransparency = 1
    iconCircle.BackgroundTransparency = 1
    progress.BackgroundTransparency = 1

    for _, child in ipairs(notif:GetDescendants()) do
        if child:IsA("TextLabel") then child.TextTransparency = 1
        elseif child:IsA("UIStroke") then child.Transparency = 1 end
    end

    tween(notif, 0.4, {Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 0}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    tween(iconCircle, 0.4, {BackgroundTransparency = 0})
    tween(progress, 0.4, {BackgroundTransparency = 0})

    for _, child in ipairs(notif:GetDescendants()) do
        if child:IsA("TextLabel") then tween(child, 0.4, {TextTransparency = 0})
        elseif child:IsA("UIStroke") then tween(child, 0.4, {Transparency = 0}) end
    end

    task.delay(0.4, function() tween(progress, 2.6, {Size = UDim2.new(0, 0, 0, 3)}, Enum.EasingStyle.Linear, Enum.EasingDirection.Out) end)

    task.delay(3, function()
        local tweenOut = tween(notif, 0.4, {Position = UDim2.new(0, 300, 0, 0), BackgroundTransparency = 1}, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        tween(iconCircle, 0.4, {BackgroundTransparency = 1})
        tween(progress, 0.4, {BackgroundTransparency = 1})
        for _, child in ipairs(notif:GetDescendants()) do
            if child:IsA("TextLabel") then tween(child, 0.4, {TextTransparency = 1})
            elseif child:IsA("UIStroke") then tween(child, 0.4, {Transparency = 1}) end
        end
        tweenOut.Completed:Wait()
        notif:Destroy()
    end)
end

--// STATE
local FAST_SPEED = 38
local UP_DISTANCE = 20
local DOWN_DISTANCE = 17

local State = {
    autoRun = Config.autoRun or false,
    espEnabled = Config.espEnabled or false,
    petsEspEnabled = Config.petsEspEnabled or false,
    antiFallEnabled = Config.antiFallEnabled or false,
    antiAfkEnabled = Config.antiAfkEnabled or false,
    antiKnockbackEnabled = Config.antiKnockbackEnabled or false,
    autoLockEnabled = Config.autoLockEnabled or false,
    wallHopEnabled = Config.wallHopEnabled or Config["Wall Hop"] or false,
    SaveConfigEnabled = SaveConfigEnabled
}

--// CHARACTER
local humanoid = nil
local rootPart = nil
local normalSpeed = 16
local lastJumpTime = 0
local characterStateChangedConn = nil

local function setupCharacter(character)
    if characterStateChangedConn then
        characterStateChangedConn:Disconnect()
        characterStateChangedConn = nil
    end
    humanoid = character:WaitForChild("Humanoid", 5)
    rootPart = character:WaitForChild("HumanoidRootPart", 5)
    if humanoid then
        normalSpeed = humanoid.WalkSpeed
        characterStateChangedConn = humanoid.StateChanged:Connect(function(_, newState)
            if newState == Enum.HumanoidStateType.Jumping then lastJumpTime = os.clock() end
        end)
    end
end

if LocalPlayer.Character then setupCharacter(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(setupCharacter)

--// AUTO RUN
RunService.Heartbeat:Connect(function()
    if humanoid and humanoid.Health > 0 then
        if State.autoRun then
            if humanoid.WalkSpeed ~= FAST_SPEED then humanoid.WalkSpeed = FAST_SPEED end
            local camera = Workspace.CurrentCamera
            if camera then
                local lookVector = camera.CFrame.LookVector
                humanoid:Move(Vector3.new(lookVector.X, 0, lookVector.Z), false)
            end
        else
            if humanoid.WalkSpeed ~= normalSpeed then humanoid.WalkSpeed = normalSpeed end
        end
    end
end)

--// PLAYER ESP
local ESPs = {}
local RainbowLabels = {}

RunService.Heartbeat:Connect(function()
    local t = os.clock()
    local removeList = {}
    for label in pairs(RainbowLabels) do
        if label and label.Parent then
            label.TextColor3 = Color3.fromHSV((t * 0.3) % 1, 1, 1)
        else
            table.insert(removeList, label)
        end
    end
    for _, label in ipairs(removeList) do RainbowLabels[label] = nil end
end)

local function removeESP(player)
    if ESPs[player] then ESPs[player]:Destroy(); ESPs[player] = nil end
end

local function createESP(player, character)
    if player == LocalPlayer then return end
    removeESP(player)
    local folder = new("Folder", {Name = "PlayerESP"}, character)
    new("Highlight", {Adornee = character, DepthMode = Enum.HighlightDepthMode.AlwaysOnTop, FillTransparency = 0.75, OutlineTransparency = 0, FillColor = Color3.fromRGB(255, 255, 255), OutlineColor = Color3.fromRGB(255, 255, 255), Enabled = State.espEnabled}, folder)
    local head = character:FindFirstChild("Head")
    if head then
        local billboard = new("BillboardGui", {Name = "ESP_Name", Adornee = head, Size = UDim2.new(0, 120, 0, 20), StudsOffset = Vector3.new(0, 2.5, 0), AlwaysOnTop = true, Enabled = State.espEnabled}, folder)
        local text = new("TextLabel", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = player.Name, TextStrokeTransparency = 0.5, TextSize = 15, Font = Enum.Font.GothamBold, TextColor3 = Color3.fromRGB(255, 255, 255)}, billboard)
        RainbowLabels[text] = true
    end
    ESPs[player] = folder
end

local function updateESP()
    for _, folder in pairs(ESPs) do
        if folder and folder.Parent then
            for _, object in ipairs(folder:GetChildren()) do
                if object:IsA("Highlight") or object:IsA("BillboardGui") then object.Enabled = State.espEnabled end
            end
        end
    end
end

local function setupESP(player)
    if player == LocalPlayer then return end
    player.CharacterAdded:Connect(function(character) task.wait(0.5); createESP(player, character) end)
    if player.Character then createESP(player, player.Character) end
end

for _, player in ipairs(Players:GetPlayers()) do setupESP(player) end
Players.PlayerAdded:Connect(setupESP)
Players.PlayerRemoving:Connect(removeESP)

--// PETS ESP
local espTracker = {}
local petFilterName = ""
local petFilterMPS = 0

local function removePetESP(pet)
    local esp = espTracker[pet]
    if not esp then return end
    if esp.billboard then esp.billboard:Destroy() end
    if esp.highlight then esp.highlight:Destroy() end
    espTracker[pet] = nil
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

local function parseMPS(text)
    local lowerText = string.lower(tostring(text))
    local mult = 1
    if lowerText:find("k") then mult = 1000
    elseif lowerText:find("m") then mult = 1000000
    elseif lowerText:find("b") then mult = 1000000000 end
    local numStr = string.gsub(lowerText, "[^%d%.]", "")
    local val = tonumber(numStr)
    if val then return val * mult end
    return 0
end

local function getPetMPSValue(pet) return parseMPS(getPetMPS(pet)) end

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
    local name = string.lower(tostring(getPetName(pet)))
    local mps = getPetMPSValue(pet)
    if petFilterName ~= "" and not name:find(string.lower(petFilterName)) then return false end
    if petFilterMPS > 0 and mps < petFilterMPS then return false end
    return true
end

local function createPetESP(pet)
    local adornPart = pet:FindFirstChildWhichIsA("BasePart", true)
    if not adornPart then return nil end

    local billboard = new("BillboardGui", {Name = "PetESP", Adornee = adornPart, Size = UDim2.new(0, 150, 0, 50), AlwaysOnTop = true, LightInfluence = 0, MaxDistance = 0, ExtentsOffset = Vector3.new(0, 3, 0)}, pet)
    new("UIListLayout", {FillDirection = Enum.FillDirection.Vertical, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Top, Padding = UDim.new(0, 1)}, billboard)

    local nameLabel = new("TextLabel", {Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1, Text = getPetName(pet), TextColor3 = Color3.fromRGB(255, 255, 255), Font = Enum.Font.GothamBold, TextSize = 11}, billboard)
    addStroke(nameLabel, Color3.new(0, 0, 0), 1.5)

    local mpsLabel = new("TextLabel", {Size = UDim2.new(1, 0, 0, 13), BackgroundTransparency = 1, Text = getPetMPS(pet), TextColor3 = Color3.fromRGB(100, 255, 100), Font = Enum.Font.GothamBold, TextSize = 10}, billboard)
    addStroke(mpsLabel, Color3.new(0, 0, 0), 1.5)

    local mutLabel = new("TextLabel", {Size = UDim2.new(1, 0, 0, 13), BackgroundTransparency = 1, Text = "", TextColor3 = Color3.fromRGB(255, 215, 0), Font = Enum.Font.GothamBold, TextSize = 10, Visible = false}, billboard)
    addStroke(mutLabel, Color3.new(0, 0, 0), 1.5)

    local highlight = new("Highlight", {Name = "PetESPHighlight", Adornee = pet, FillTransparency = 0.7, OutlineTransparency = 0.3, DepthMode = Enum.HighlightDepthMode.AlwaysOnTop, FillColor = Color3.fromRGB(0, 255, 100), OutlineColor = Color3.fromRGB(255, 255, 255)}, pet)

    local function updateESP()
        if not passesFilter(pet) then billboard.Enabled = false; highlight.Enabled = false; return end
        billboard.Enabled = State.petsEspEnabled
        highlight.Enabled = State.petsEspEnabled
        local mutation = getPetMutation(pet)
        if mutation then
            mutLabel.Text = mutation
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

local function hookPetsFolder(folder)
    folder.ChildAdded:Connect(function(child) task.wait(0.1); setupPetESP(child) end)
    folder.ChildRemoved:Connect(function(child) removePetESP(child) end)
    for _, child in ipairs(folder:GetChildren()) do setupPetESP(child) end
end

local runtimePetsFolder = Workspace:FindFirstChild("RuntimePets")
if runtimePetsFolder then hookPetsFolder(runtimePetsFolder) end

Workspace.ChildAdded:Connect(function(child)
    if child.Name == "RuntimePets" and child:IsA("Folder") then hookPetsFolder(child) end
end)

scanPets()

task.spawn(function()
    while true do
        task.wait(0.5)
        if State.petsEspEnabled then
            local removeList = {}
            for pet, esp in pairs(espTracker) do
                if pet and pet.Parent then pcall(esp.update)
                else table.insert(removeList, pet) end
            end
            for _, pet in ipairs(removeList) do removePetESP(pet) end
            scanPets()
        else
            if next(espTracker) then
                local removeList = {}
                for pet in pairs(espTracker) do table.insert(removeList, pet) end
                for _, pet in ipairs(removeList) do removePetESP(pet) end
            end
        end
    end
end)

--// ANTI KNOCKBACK
local antiKnockbackConnection = nil
local isCountering = false
local counterEndTime = 0
local lastSafePos = nil

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
            if lastSafePos then
                rootPart.CFrame = CFrame.new(lastSafePos) * CFrame.Angles(0, math.rad(rootPart.Orientation.Y), 0)
            end
        else
            isCountering = false
            lastSafePos = rootPart.Position
        end
    end)
end

local function stopAntiKnockback()
    if antiKnockbackConnection then antiKnockbackConnection:Disconnect(); antiKnockbackConnection = nil end
end

--// AUTO LOCK BASE
local LOCK_STATE_ATTR = "LockState"
local STATE_IDLE = "Idle"
local STATE_LOCKED = "Locked"
local autoLockThread = nil
local lastLockState = nil

local function findMyPlot()
    local plotsFolder = Workspace:FindFirstChild("Plots")
    if not plotsFolder then return nil end
    for _, plot in ipairs(plotsFolder:GetChildren()) do
        if plot:IsA("Model") and plot:GetAttribute("OwnerUserId") == LocalPlayer.UserId then return plot end
    end
    return nil
end

local function startAutoLock()
    if autoLockThread then return end
    autoLockThread = task.spawn(function()
        while State.autoLockEnabled do
            local myPlot = findMyPlot()
            if myPlot and rootPart and humanoid and humanoid.Health > 0 then
                local lockObj = myPlot:FindFirstChild("Lock")
                if lockObj then
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
        autoLockThread = nil
    end)
end

local function stopAutoLock()
    State.autoLockEnabled = false
    if autoLockThread then task.cancel(autoLockThread); autoLockThread = nil end
    lastLockState = nil
end

--// WALL HOP
local wallHopWasClimbing = false
local wallHopClearTimer = 0

RunService.Heartbeat:Connect(function()
    if not State.wallHopEnabled or not rootPart or not humanoid or humanoid.Health <= 0 then
        wallHopWasClimbing = false
        wallHopClearTimer = 0
        return
    end
    local character = LocalPlayer.Character
    if not character then return end

    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {character}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude

    local forwardDirection = rootPart.CFrame.LookVector
    local result = Workspace:Raycast(rootPart.Position, forwardDirection * 3, rayParams)

    if result then
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
    end
end)

--// ANTI FALL
local AntiFall = nil
local antiFallActive = false
local antiFallY = 0

local function removeAntiFall()
    if AntiFall then AntiFall:Destroy(); AntiFall = nil end
end

local function createAntiFall()
    if not rootPart then return end
    removeAntiFall()
    AntiFall = new("Part", {Name = "AntiFall_Circle_800x800", Shape = Enum.PartType.Cylinder, Size = Vector3.new(2, 800, 800), Anchored = true, CanCollide = true, Material = Enum.Material.Glass, Color = Color3.fromRGB(80, 210, 255), Transparency = 0.45}, Workspace)
    antiFallY = rootPart.Position.Y - 7
    AntiFall.CFrame = CFrame.new(rootPart.Position.X, antiFallY, rootPart.Position.Z) * CFrame.Angles(0, 0, math.rad(90))
end

RunService.Heartbeat:Connect(function()
    if State.antiFallEnabled and AntiFall and rootPart and humanoid and humanoid.Health > 0 then
        local velY = rootPart.AssemblyLinearVelocity.Y
        if velY < -55 then
            if not antiFallActive then
                antiFallActive = true
                antiFallY = rootPart.Position.Y - 7
            end
            AntiFall.CFrame = CFrame.new(rootPart.Position.X, antiFallY, rootPart.Position.Z) * CFrame.Angles(0, 0, math.rad(90))
        else
            antiFallActive = false
            AntiFall.CFrame = CFrame.new(rootPart.Position.X, rootPart.Position.Y - 7, rootPart.Position.Z) * CFrame.Angles(0, 0, math.rad(90))
        end
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    if State.antiFallEnabled then createAntiFall() end
end)

--// ANTI AFK
local antiAfkConnection = nil

local function startAntiAfk()
    if antiAfkConnection then return end
    antiAfkConnection = LocalPlayer.Idled:Connect(function()
        pcall(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end)
    end)
end

local function stopAntiAfk()
    if antiAfkConnection then antiAfkConnection:Disconnect(); antiAfkConnection = nil end
end

--// ENTER / EXIT BASE
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
        for _ = 1, steps do
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

--// SERVER HOP
local SavedJobs = LoadJSON(JobsFile) or {}

local function SaveJobs() SaveJSON(JobsFile, SavedJobs) end

local ServerSearching = false
local searchToken = 0

local function GetServers()
    local AllServers = {}
    local Cursor = nil
    for _ = 1, 5 do
        local Url = "https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?limit=100"
        if Cursor then Url = Url .. "&cursor=" .. UrlEncode(Cursor) end
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

local function FindServer(Mode, token)
    local BestServer = nil
    for _ = 1, 5 do
        if token ~= searchToken then return nil end
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

--// MAIN UI
local ScreenGui = new("ScreenGui", {Name = "SSSHubSteal", ResetOnSpawn = false, DisplayOrder = 999998}, GuiParent)

local Main = new("Frame", {Size = UDim2.new(0, 440, 0, 0), Position = UDim2.new(0.5, -220, 0.5, -155), BackgroundColor3 = Theme.Background, BorderSizePixel = 0, Active = true}, ScreenGui)
corner(Main, 10)
addStroke(Main, Theme.Stroke, 1.5)

local uiScale = new("UIScale", {Scale = 1}, Main)

local Header = new("Frame", {Size = UDim2.new(1, -130, 0, 50), Position = UDim2.new(0, 130, 0, 0), BackgroundTransparency = 1, Active = true}, Main)

local Sidebar = new("Frame", {Size = UDim2.new(0, 130, 1, 0), BackgroundColor3 = Theme.Sidebar, BorderSizePixel = 0}, Main)
corner(Sidebar, 10)
new("UIListLayout", {FillDirection = Enum.FillDirection.Vertical, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Top, Padding = UDim.new(0, 5)}, Sidebar)

local Logo = new("Frame", {Size = UDim2.new(0, 26, 0, 26), Position = UDim2.new(0, 15, 0.5, -13), BackgroundColor3 = Theme.Accent}, Header)
corner(Logo, 8)
new("TextLabel", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "⚡", TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 14, Font = Enum.Font.GothamBold}, Logo)
table.insert(AccentTracker.Static, Logo)

new("TextLabel", {Size = UDim2.new(0, 150, 0, 16), Position = UDim2.new(0, 50, 0, 10), BackgroundTransparency = 1, Text = "SSS HUB STEAL", TextColor3 = Theme.Text, TextSize = 11, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left}, Header)
new("TextLabel", {Size = UDim2.new(0, 200, 0, 12), Position = UDim2.new(0, 50, 0, 27), BackgroundTransparency = 1, Text = "Game Enhancement • Delta CodeX", TextColor3 = Theme.TextDark, TextSize = 8, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left}, Header)

local CloseBtn = new("TextButton", {Size = UDim2.new(0, 22, 0, 22), Position = UDim2.new(1, -32, 0, 5), BackgroundColor3 = Color3.fromRGB(80, 30, 30), BorderSizePixel = 0, Text = "X", TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 10, Font = Enum.Font.GothamBold}, Header)
corner(CloseBtn, 6)

local ToggleBtnFloat = new("TextButton", {Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0, 20, 0.5, -20), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Text = "⚡", TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 16, Font = Enum.Font.GothamBold, Visible = false}, ScreenGui)
corner(ToggleBtnFloat, 10)
addStroke(ToggleBtnFloat, Theme.Stroke, 1.5)
table.insert(AccentTracker.Static, ToggleBtnFloat)

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
        if input == dragInput and dragging and mousePos and framePos then
            local delta = input.Position - mousePos
            frame.Position = UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset + delta.Y)
        end
    end)
end

MakeDraggable(Header)

local uiVisible = true

local function toggleUI(show)
    uiVisible = show
    if show then
        Main.Visible = true
        Main.Size = UDim2.new(0, 440, 0, 0)
        tween(Main, 0.3, {Size = UDim2.new(0, 440, 0, 310)}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        tween(ToggleBtnFloat, 0.2, {Size = UDim2.new(0, 0, 0, 0)})
        task.delay(0.2, function() ToggleBtnFloat.Visible = false end)
    else
        tween(Main, 0.3, {Size = UDim2.new(0, 440, 0, 0)}, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        task.delay(0.3, function() Main.Visible = false end)
        ToggleBtnFloat.Visible = true
        ToggleBtnFloat.Size = UDim2.new(0, 0, 0, 0)
        tween(ToggleBtnFloat, 0.3, {Size = UDim2.new(0, 40, 0, 40)}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    end
end

CloseBtn.MouseButton1Click:Connect(function() playClick(); toggleUI(false) end)
ToggleBtnFloat.MouseButton1Click:Connect(function() playClick(); toggleUI(true) end)

--// CAMERA SCALE
local camConn = nil
local function updateScale()
    local cam = Workspace.CurrentCamera
    if not cam then return end
    local viewport = cam.ViewportSize
    local scale = math.clamp(math.min(viewport.X / 480, viewport.Y / 360), 0.65, 1.15)
    tween(uiScale, 0.15, {Scale = scale})
end

local function hookCamera(cam)
    if camConn then camConn:Disconnect(); camConn = nil end
    if cam then
        camConn = cam:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
        updateScale()
    end
end

hookCamera(Workspace.CurrentCamera)
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function() hookCamera(Workspace.CurrentCamera) end)

--// TAB SYSTEM
local Pages = {}
local TabButtons = {}

local function switchTab(tabName)
    for name, page in pairs(Pages) do page.Visible = (name == tabName) end
    for name, data in pairs(TabButtons) do
        if name == tabName then
            tween(data.btn, 0.2, {BackgroundColor3 = CurrentAccent})
            data.btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            data.isActive = true
        else
            tween(data.btn, 0.2, {BackgroundColor3 = Theme.Sidebar})
            data.btn.TextColor3 = Theme.TextDark
            data.isActive = false
        end
    end
end

local function CreateTab(text, icon)
    local TabBtn = new("TextButton", {Size = UDim2.new(0.9, 0, 0, 30), BackgroundColor3 = Theme.Sidebar, BorderSizePixel = 0, Text = "  " .. icon .. "  " .. text, TextColor3 = Theme.TextDark, TextSize = 11, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left}, Sidebar)
    corner(TabBtn, 6)
    TabBtn.MouseButton1Click:Connect(function() playClick(); switchTab(text) end)
    TabBtn.MouseEnter:Connect(function()
        if not TabButtons[text] or not TabButtons[text].isActive then tween(TabBtn, 0.2, {BackgroundColor3 = Color3.fromRGB(35, 35, 45)}) end
    end)
    TabBtn.MouseLeave:Connect(function()
        if not TabButtons[text] or not TabButtons[text].isActive then tween(TabBtn, 0.2, {BackgroundColor3 = Theme.Sidebar}) end
    end)
    local Page = new("ScrollingFrame", {Size = UDim2.new(1, -150, 1, -60), Position = UDim2.new(0, 135, 0, 55), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2, ScrollBarImageColor3 = Theme.Stroke, Visible = false, CanvasSize = UDim2.new(0, 0, 0, 0)}, Main)
    local PageLayout = new("UIListLayout", {FillDirection = Enum.FillDirection.Vertical, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Top, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, Page)
    PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Page.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + 20)
    end)
    Pages[text] = Page
    TabButtons[text] = {btn = TabBtn, isActive = false}
    AccentTracker.Tabs[text] = TabButtons[text]
    return Page
end

new("Frame", {Size = UDim2.new(0.8, 0, 0, 1), BackgroundTransparency = 0.5, BackgroundColor3 = Theme.Stroke, BorderSizePixel = 0}, Sidebar)

local function AddHover(btn, baseColor, hoverColor)
    local bc = baseColor or Theme.Card
    local hc = hoverColor or Theme.CardHover
    btn.MouseEnter:Connect(function() tween(btn, 0.2, {BackgroundColor3 = hc}) end)
    btn.MouseLeave:Connect(function() tween(btn, 0.2, {BackgroundColor3 = bc}) end)
end

--// KEYBIND SYSTEM
local isListeningKeybind = false
local KeybindRegistry = {}

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or isListeningKeybind then return end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        local keyName = input.KeyCode.Name
        for _, bind in pairs(KeybindRegistry) do
            if bind.Key == keyName and bind.Callback then pcall(bind.Callback) end
        end
    end
end)

local function CreateKeybindButton(parent, name, defaultKey, callback)
    local currentKey = Keybinds[name] or defaultKey
    local keyBtn = new("TextButton", {Size = UDim2.new(0, 35, 0, 18), Position = UDim2.new(1, -80, 0.5, -9), BackgroundColor3 = Theme.Background, BorderSizePixel = 0, Text = currentKey or "None", TextColor3 = Theme.TextDark, TextSize = 9, Font = Enum.Font.GothamBold}, parent)
    corner(keyBtn, 4)
    addStroke(keyBtn, Theme.Stroke, 1)

    local function setRegistry(key)
        if key and key ~= "" then KeybindRegistry[name] = {Key = key, Callback = callback}
        else KeybindRegistry[name] = nil end
    end
    setRegistry(currentKey)

    keyBtn.MouseButton1Click:Connect(function()
        playClick()
        if isListeningKeybind then return end
        isListeningKeybind = true
        keyBtn.Text = "..."
        keyBtn.BackgroundColor3 = CurrentAccent

        local conn = nil
        local timeoutThread = nil

        local function finishListening(restoreText)
            isListeningKeybind = false
            if conn and conn.Connected then conn:Disconnect() end
            if timeoutThread then pcall(function() task.cancel(timeoutThread) end) end
            keyBtn.BackgroundColor3 = Theme.Background
            keyBtn.Text = restoreText or currentKey or "None"
        end

        conn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            if input.KeyCode == Enum.KeyCode.Escape then finishListening(); return end
            if input.UserInputType == Enum.UserInputType.Keyboard then
                local newKey = input.KeyCode.Name
                currentKey = newKey
                Keybinds[name] = newKey
                SaveConfig()
                setRegistry(newKey)
                finishListening(newKey)
                notify("Keybind", name .. " → " .. newKey, "success")
            end
        end)

        timeoutThread = task.delay(6, function()
            if isListeningKeybind then finishListening() end
        end)
    end)
    return keyBtn
end

--// UI ELEMENT CREATORS
local function CreateToggle(parent, opts)
    local text = opts.title
    local cfgKey = opts.cfgKey or text

    local Container = new("Frame", {Size = UDim2.new(1, -10, 0, 38), BackgroundColor3 = Theme.Card, BorderSizePixel = 0, LayoutOrder = opts.layoutOrder or 0, Name = text}, parent)
    corner(Container, 8)
    addStroke(Container, Theme.Stroke, 1)

    new("TextLabel", {Size = UDim2.new(1, -120, 1, 0), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1, Text = text, TextColor3 = Theme.Text, TextSize = 12, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left}, Container)

    local ToggleBtn = new("TextButton", {Size = UDim2.new(0, 38, 0, 19), Position = UDim2.new(1, -48, 0.5, -10), BackgroundColor3 = Theme.ToggleOff, BorderSizePixel = 0, Text = ""}, Container)
    corner(ToggleBtn, 10)
    local Circle = new("Frame", {Size = UDim2.new(0, 15, 0, 15), Position = UDim2.new(0, 2, 0.5, -8), BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0}, ToggleBtn)
    corner(Circle, 10)

    local state = false
    local toggleData = {btn = ToggleBtn, isOn = false}
    table.insert(AccentTracker.Toggles, toggleData)

    local function updateVisual()
        toggleData.isOn = state
        if state then
            tween(ToggleBtn, 0.2, {BackgroundColor3 = Theme.ToggleOn})
            tween(Circle, 0.2, {Position = UDim2.new(1, -17, 0.5, -8)})
        else
            tween(ToggleBtn, 0.2, {BackgroundColor3 = Theme.ToggleOff})
            tween(Circle, 0.2, {Position = UDim2.new(0, 2, 0.5, -8)})
        end
    end

    local function setState(newState, silent)
        state = newState
        updateVisual()
        if not silent then
            State[cfgKey] = newState
            Config[cfgKey] = newState
            SaveConfig()
            if opts.callback then opts.callback(newState) end
        end
    end

    ToggleBtn.MouseButton1Click:Connect(function() playClick(); setState(not state) end)

    if opts.defaultKeybind then
        CreateKeybindButton(Container, cfgKey, opts.defaultKeybind, function() playClick(); setState(not state) end)
    end

    if State[cfgKey] then
        task.spawn(function() task.wait(0.1); setState(true, true) end)
    end
    return Container
end

local function CreateButton(parent, opts)
    local btn = new("TextButton", {Size = UDim2.new(1, -10, 0, 33), BackgroundColor3 = Theme.Card, BorderSizePixel = 0, Text = opts.title, TextColor3 = Theme.Text, TextSize = 11, Font = Enum.Font.GothamBold, LayoutOrder = opts.layoutOrder or 0, Name = opts.title}, parent)
    corner(btn, 8)
    addStroke(btn, Theme.Stroke, 1)
    AddHover(btn)
    btn.MouseButton1Click:Connect(function() playClick(); if opts.callback then opts.callback() end end)
    if opts.defaultKeybind then
        CreateKeybindButton(btn, opts.cfgKey or opts.title, opts.defaultKeybind, function() playClick(); if opts.callback then opts.callback() end end)
    end
    return btn
end

local function CreatePopupMenu(title, width, height)
    local menu = new("Frame", {Size = UDim2.new(0, width, 0, height), Position = UDim2.new(0.5, -width / 2, 0.5, -height / 2), BackgroundColor3 = Theme.Card, BorderSizePixel = 0, Visible = false, Active = true, ZIndex = 20}, ScreenGui)
    corner(menu, 8)
    addStroke(menu, Theme.Stroke, 1.5)

    local header = new("Frame", {Size = UDim2.new(1, -10, 0, 28), Position = UDim2.new(0, 5, 0, 2), BackgroundTransparency = 1, Active = true, ZIndex = 21}, menu)
    new("TextLabel", {Size = UDim2.new(1, -30, 1, 0), Position = UDim2.new(0, 8, 0, 0), BackgroundTransparency = 1, Text = title, TextColor3 = Theme.Text, TextSize = 12, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 21}, header)

    local closeBtn = new("TextButton", {Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(1, -24, 0.5, -10), BackgroundColor3 = Color3.fromRGB(80, 30, 30), BorderSizePixel = 0, Text = "X", TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 9, Font = Enum.Font.GothamBold, ZIndex = 21}, header)
    corner(closeBtn, 5)
    closeBtn.MouseButton1Click:Connect(function() playClick(); menu.Visible = false end)
    MakeDraggable(header)

    local content = new("Frame", {Size = UDim2.new(1, -16, 1, -38), Position = UDim2.new(0, 8, 0, 32), BackgroundTransparency = 1, ZIndex = 21}, menu)
    new("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Top}, content)

    return menu, content
end

--// BUILD PAGES
local MainPage = CreateTab("Main", "🏠")
local CombatPage = CreateTab("Combat", "⚔️")
local ServerPage = CreateTab("Server", "📡")
local SettingsPage = CreateTab("Settings", "⚙️")

local BypassMenu, BypassContent = CreatePopupMenu("BYPASS", 220, 210)
local PetFilterMenu, PetFilterContent = CreatePopupMenu("PET FILTERS", 250, 180)

--// MAIN PAGE
CreateToggle(MainPage, {title = "Auto Run", cfgKey = "autoRun", layoutOrder = 1, callback = function(v) notify("Auto Run", v and "Enabled" or "Disabled", "info") end})
CreateToggle(MainPage, {title = "Player ESP", cfgKey = "espEnabled", layoutOrder = 2, defaultKeybind = "T", callback = function(v) updateESP(); notify("Player ESP", v and "Enabled" or "Disabled", "info") end})
CreateToggle(MainPage, {title = "Pets ESP", cfgKey = "petsEspEnabled", layoutOrder = 3, defaultKeybind = "Y", callback = function(v)
    if v then scanPets()
    else
        local removeList = {}
        for pet in pairs(espTracker) do table.insert(removeList, pet) end
        for _, pet in ipairs(removeList) do removePetESP(pet) end
    end
    notify("Pets ESP", v and "Enabled" or "Disabled", "info")
end})
CreateToggle(MainPage, {title = "Anti Fall", cfgKey = "antiFallEnabled", layoutOrder = 4, callback = function(v)
    if v then createAntiFall() else removeAntiFall() end
    notify("Anti Fall", v and "Enabled" or "Disabled", "info")
end})
CreateToggle(MainPage, {title = "Anti AFK", cfgKey = "antiAfkEnabled", layoutOrder = 5, callback = function(v)
    if v then startAntiAfk() else stopAntiAfk() end
    notify("Anti AFK", v and "Enabled" or "Disabled", "info")
end})

CreateButton(MainPage, {title = "Pet Filter", layoutOrder = 6, callback = function() PetFilterMenu.Visible = not PetFilterMenu.Visible end})
CreateButton(MainPage, {title = "Bypass Menu", cfgKey = "bypassMenu", layoutOrder = 7, defaultKeybind = "B", callback = function() BypassMenu.Visible = not BypassMenu.Visible end})

--// COMBAT PAGE
CreateToggle(CombatPage, {title = "Anti Knockback", cfgKey = "antiKnockbackEnabled", layoutOrder = 1, defaultKeybind = "G", callback = function(v)
    if v then startAntiKnockback() else stopAntiKnockback() end
    notify("Anti Knockback", v and "Enabled" or "Disabled", "info")
end})
CreateToggle(CombatPage, {title = "Auto Lock Base", cfgKey = "autoLockEnabled", layoutOrder = 2, callback = function(v)
    if v then startAutoLock() else stopAutoLock() end
    notify("Auto Lock", v and "Enabled" or "Disabled", "info")
end})

--// BYPASS MENU CONTENT
CreateToggle(BypassContent, {title = "Wall Hop", cfgKey = "wallHopEnabled", layoutOrder = 1, callback = function(v) notify("Wall Hop", v and "Enabled" or "Disabled", "info") end})
CreateButton(BypassContent, {title = "Enter Base", cfgKey = "enterBase", layoutOrder = 2, defaultKeybind = "Q", callback = function() smoothVerticalMove(DOWN_DISTANCE, -1); notify("Enter Base", "Moving down", "info") end})
CreateButton(BypassContent, {title = "Exit Base", cfgKey = "exitBase", layoutOrder = 3, defaultKeybind = "R", callback = function() smoothVerticalMove(UP_DISTANCE, 1); notify("Exit Base", "Moving up", "info") end})

--// PET FILTER MENU CONTENT
local function CreateFilterRow(parent, labelText, placeholder, defaultText, layoutOrder)
    local row = new("Frame", {Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, LayoutOrder = layoutOrder}, parent)
    new("TextLabel", {Size = UDim2.new(0, 60, 1, 0), BackgroundTransparency = 1, Text = labelText, TextColor3 = Theme.TextDark, TextSize = 10, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 21}, row)
    local box = new("TextBox", {Size = UDim2.new(1, -65, 1, 0), Position = UDim2.new(0, 65, 0, 0), BackgroundColor3 = Theme.Background, BorderSizePixel = 0, Text = defaultText, PlaceholderText = placeholder, TextColor3 = Theme.Text, PlaceholderColor3 = Theme.TextDark, TextSize = 10, Font = Enum.Font.Gotham, ClearTextOnFocus = false, ZIndex = 21}, row)
    corner(box, 6)
    addStroke(box, Theme.Stroke, 1)
    return box
end

local nameBox = CreateFilterRow(PetFilterContent, "Name:", "e.g. Dragon", "", 1)
local mpsBox = CreateFilterRow(PetFilterContent, "Min MPS:", "0", "0", 2)

local filterButtonRow = new("Frame", {Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, LayoutOrder = 3}, PetFilterContent)

local applyBtn = new("TextButton", {Size = UDim2.new(0.48, 0, 1, 0), Position = UDim2.new(0, 0, 0, 0), BackgroundColor3 = Color3.fromRGB(40, 100, 60), BorderSizePixel = 0, Text = "APPLY", TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 10, Font = Enum.Font.GothamBold, ZIndex = 21}, filterButtonRow)
corner(applyBtn, 6)
AddHover(applyBtn, Color3.fromRGB(40, 100, 60), Color3.fromRGB(50, 120, 70))

local clearBtn = new("TextButton", {Size = UDim2.new(0.48, 0, 1, 0), Position = UDim2.new(0.52, 0, 0, 0), BackgroundColor3 = Color3.fromRGB(100, 40, 40), BorderSizePixel = 0, Text = "CLEAR", TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 10, Font = Enum.Font.GothamBold, ZIndex = 21}, filterButtonRow)
corner(clearBtn, 6)
AddHover(clearBtn, Color3.fromRGB(100, 40, 40), Color3.fromRGB(120, 50, 50))

applyBtn.MouseButton1Click:Connect(function()
    playClick()
    petFilterName = nameBox.Text
    local inputText = string.lower(mpsBox.Text)
    local mult = 1
    if inputText:find("k") then mult = 1000
    elseif inputText:find("m") then mult = 1000000
    elseif inputText:find("b") then mult = 1000000000 end
    local numStr = string.gsub(inputText, "[^%d%.]", "")
    local val = tonumber(numStr)
    petFilterMPS = val and (val * mult) or 0
    PetFilterMenu.Visible = false
    notify("Pet Filter", "Applied successfully", "success")
end)

clearBtn.MouseButton1Click:Connect(function()
    playClick()
    nameBox.Text = ""
    mpsBox.Text = "0"
    petFilterName = ""
    petFilterMPS = 0
    notify("Pet Filter", "Cleared", "info")
end)

--// SERVER PAGE
local StatusLabel = new("TextLabel", {Size = UDim2.new(1, -10, 0, 18), BackgroundTransparency = 1, Text = "Saved Jobs: " .. #SavedJobs, TextColor3 = Theme.TextDark, TextSize = 10, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 0}, ServerPage)

local UpdateServerList

CreateButton(ServerPage, {title = "Copy & Save Job", layoutOrder = 1, callback = function()
    local CurrentJobId = game.JobId
    if #SavedJobs >= 10 then notify("Server Hop", "Max 10 saved jobs!", "warning") return end
    for _, Data in ipairs(SavedJobs) do
        if Data.JobId == CurrentJobId then notify("Server Hop", "Already saved!", "warning") return end
    end
    table.insert(SavedJobs, {JobId = CurrentJobId, Name = "Server " .. (#SavedJobs + 1)})
    SaveJobs()
    if type(setclipboard) == "function" then pcall(setclipboard, CurrentJobId) end
    notify("Server Hop", "Saved & Copied!", "success")
    StatusLabel.Text = "Saved Jobs: " .. #SavedJobs
    UpdateServerList()
end})

CreateButton(ServerPage, {title = "Reconnect", layoutOrder = 2, callback = function() pcall(function() TeleportService:TeleportToPlaceInstance(PlaceId, game.JobId, LocalPlayer) end) end})

CreateButton(ServerPage, {title = "Join Busy Server", layoutOrder = 3, callback = function()
    if ServerSearching then return end
    ServerSearching = true
    searchToken = searchToken + 1
    local token = searchToken
    StatusLabel.Text = "Searching busy..."
    task.spawn(function()
        local Server = FindServer("BUSY", token)
        if token ~= searchToken then ServerSearching = false; return end
        if Server then
            StatusLabel.Text = "Joining: " .. Server.playing .. "/" .. Server.maxPlayers
            task.wait(0.5)
            pcall(function() TeleportService:TeleportToPlaceInstance(PlaceId, Server.id, LocalPlayer) end)
        else
            StatusLabel.Text = "Not found!"
            notify("Server Hop", "No busy servers found", "warning")
        end
        ServerSearching = false
    end)
end})

CreateButton(ServerPage, {title = "Join Empty Server", layoutOrder = 4, callback = function()
    if ServerSearching then return end
    ServerSearching = true
    searchToken = searchToken + 1
    local token = searchToken
    StatusLabel.Text = "Searching empty..."
    task.spawn(function()
        local Server = FindServer("EMPTY", token)
        if token ~= searchToken then ServerSearching = false; return end
        if Server then
            StatusLabel.Text = "Joining: " .. Server.playing .. "/" .. Server.maxPlayers
            task.wait(0.5)
            pcall(function() TeleportService:TeleportToPlaceInstance(PlaceId, Server.id, LocalPlayer) end)
        else
            StatusLabel.Text = "Not found!"
            notify("Server Hop", "No empty servers found", "warning")
        end
        ServerSearching = false
    end)
end})

new("Frame", {Size = UDim2.new(1, -10, 0, 1), BackgroundColor3 = Theme.Stroke, BackgroundTransparency = 0.5, BorderSizePixel = 0, LayoutOrder = 5, Name = "Sep"}, ServerPage)

local ServerListContainer = new("Frame", {Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, LayoutOrder = 6, AutomaticSize = Enum.AutomaticSize.Y}, ServerPage)
new("UIListLayout", {FillDirection = Enum.FillDirection.Vertical, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Top, Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder}, ServerListContainer)

UpdateServerList = function()
    for _, child in ipairs(ServerListContainer:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    for index, Data in ipairs(SavedJobs) do
        local Row = new("Frame", {Size = UDim2.new(1, -4, 0, 30), BackgroundColor3 = Theme.Card, BorderSizePixel = 0, LayoutOrder = index}, ServerListContainer)
        corner(Row, 6)
        addStroke(Row, Theme.Stroke, 1)
        new("TextLabel", {Size = UDim2.new(1, -100, 1, 0), Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1, Text = Data.Name or ("Server " .. index), TextColor3 = Theme.Text, TextSize = 10, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left}, Row)

        local JoinBtn = new("TextButton", {Size = UDim2.new(0, 45, 1, -8), Position = UDim2.new(1, -100, 0, 4), BackgroundColor3 = Color3.fromRGB(40, 80, 50), BorderSizePixel = 0, Text = "JOIN", TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 9, Font = Enum.Font.GothamBold}, Row)
        corner(JoinBtn, 4)
        AddHover(JoinBtn, Color3.fromRGB(40, 80, 50), Color3.fromRGB(50, 100, 60))
        JoinBtn.MouseButton1Click:Connect(function()
            playClick()
            pcall(function() TeleportService:TeleportToPlaceInstance(PlaceId, Data.JobId, LocalPlayer) end)
        end)

        local DeleteBtn = new("TextButton", {Size = UDim2.new(0, 35, 1, -8), Position = UDim2.new(1, -45, 0, 4), BackgroundColor3 = Color3.fromRGB(80, 40, 40), BorderSizePixel = 0, Text = "X", TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 9, Font = Enum.Font.GothamBold}, Row)
        corner(DeleteBtn, 4)
        AddHover(DeleteBtn, Color3.fromRGB(80, 40, 40), Color3.fromRGB(100, 50, 50))
        DeleteBtn.MouseButton1Click:Connect(function()
            playClick()
            table.remove(SavedJobs, index)
            SaveJobs()
            StatusLabel.Text = "Saved Jobs: " .. #SavedJobs
            UpdateServerList()
        end)
    end
end

--// SETTINGS PAGE
CreateToggle(SettingsPage, {title = "Save Config", cfgKey = "SaveConfigEnabled", layoutOrder = 1, callback = function(v)
    SaveConfigEnabled = v
    Config.SaveConfigEnabled = v
    SaveConfig(true)
    notify("Config", v and "Auto-save enabled" or "Auto-save disabled", v and "success" or "warning")
end})

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
    corner(swatch, 6)
    local swatchStroke = addStroke(swatch, Color3.fromRGB(255, 255, 255), 0)
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

--// RIGHT CTRL TOGGLE
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.RightControl then
        uiVisible = not uiVisible
        toggleUI(uiVisible)
    end
end)

--// INITIALIZE FEATURES
if State.espEnabled then updateESP() end
if State.antiAfkEnabled then startAntiAfk() end
if State.antiKnockbackEnabled then startAntiKnockback() end
if State.autoLockEnabled then startAutoLock() end
if State.antiFallEnabled then createAntiFall() end

--// START UI
switchTab("Main")
UpdateServerList()
toggleUI(true)

notify("SSS HUB", "Добро пожаловать в SSS HUB STEAL!", "info")
notify("Exploit", "Delta CodeX", "success")
