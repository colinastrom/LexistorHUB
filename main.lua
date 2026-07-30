--// SSSHUB STEAL + MAIN
--// By Rosomax0 • Developer
--// MODIFIED BY ENI FOR LO

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

--------------------------------------------------
-- DRAGGABLE FUNCTION
--------------------------------------------------
local function MakeDraggable(frame)
    local dragging = false
    local dragInput, mousePos, framePos

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            mousePos = input.Position
            framePos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - mousePos
            frame.Position = UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset + delta.Y)
        end
    end)
end

--------------------------------------------------
-- SETTINGS
--------------------------------------------------
local FAST_SPEED = 38
local UP_DISTANCE = 20
local DOWN_DISTANCE = 17

local autoRun = false
local espEnabled = false
local wallHopEnabled = false
local antiFallEnabled = false
local petsEspEnabled = false
local antiKnockbackEnabled = false
local autoLockEnabled = false
local antiAfkEnabled = false
local antiCheatBypassEnabled = false

local humanoid
local rootPart
local normalSpeed = 16

local ESPs = {}
local AntiFall
local antiKnockbackConnection
local autoLockConnection
local antiAfkConnection
local antiCheatConnection

-- Anti-Knockback state
local lastJumpTime = 0
local lastSafePos = nil
local isCountering = false
local counterEndTime = 0

local LOCK_STATE_ATTR = "LockState"
local STATE_IDLE = "Idle"

--------------------------------------------------
-- CHARACTER
--------------------------------------------------
local function setupCharacter(character)
    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")
    normalSpeed = humanoid.WalkSpeed
    
    -- Track jumps for anti-knockback
    humanoid.StateChanged:Connect(function(_, newState)
        if newState == Enum.HumanoidStateType.Jumping then
            lastJumpTime = os.clock()
        end
    end)
end

if LocalPlayer.Character then
    setupCharacter(LocalPlayer.Character)
end

LocalPlayer.CharacterAdded:Connect(function(character)
    setupCharacter(character)
end)

--------------------------------------------------
-- AUTO RUN + SPEED
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

task.spawn(function()
    while task.wait(0.05) do
        if humanoid and humanoid.Health > 0 then
            if autoRun then
                humanoid.WalkSpeed = FAST_SPEED
            else
                humanoid.WalkSpeed = normalSpeed
            end
        end
    end
end)

--------------------------------------------------
-- PLAYER ESP
--------------------------------------------------
local function removeESP(player)
    if ESPs[player] then
        ESPs[player]:Destroy()
        ESPs[player] = nil
    end
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
    if player.Character then
        createESP(player, player.Character)
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    setupESP(player)
end

Players.PlayerAdded:Connect(setupESP)
Players.PlayerRemoving:Connect(function(player)
    removeESP(player)
end)

--------------------------------------------------
-- PETS ESP (CLEAN + FILTER)
--------------------------------------------------
local espTracker = {}
local petFilterName = "" -- Фильтр по имени (пусто = все)
local petFilterMPS = 0   -- Фильтр по MPS (0 = все)

local function removePetESP(pet)
    local esp = espTracker[pet]
    if esp then
        if esp.billboard then esp.billboard:Destroy() end
        if esp.highlight then esp.highlight:Destroy() end
        espTracker[pet] = nil
    end
end

local function getPetName(pet)
    local species = pet:GetAttribute("Species")
    return species or pet.Name
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
    -- Извлекаем число из текста типа "$7.3m/s" -> 7300000
    local num = mpsText:gsub("[%$%,%/s]", "")
    local mult = 1
    if mpsText:lower():find("k") then mult = 1000 end
    if mpsText:lower():find("m") then mult = 1000000 end
    if mpsText:lower():find("b") then mult = 1000000000 end
    
    local val = tonumber(num)
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
    if mutAttr and mutAttr ~= "" then
        return mutAttr
    end
    return nil
end

-- Проверка фильтра
local function passesFilter(pet)
    local name = getPetName(pet):lower()
    local mps = getPetMPSValue(pet)
    
    if petFilterName ~= "" and not name:find(petFilterName:lower()) then
        return false
    end
    
    if petFilterMPS > 0 and mps < petFilterMPS then
        return false
    end
    
    return true
end

local function createPetESP(pet)
    local adornPart = nil
    for _, desc in ipairs(pet:GetDescendants()) do
        if desc:IsA("MeshPart") or desc:IsA("BasePart") then
            adornPart = desc
            break
        end
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
    nameLabel.Name = "PetName"
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
    mpsLabel.Name = "MPS"
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
    mutLabel.Name = "Mutation"
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
        -- Проверка фильтра
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
    
    return {
        billboard = billboard,
        highlight = highlight,
        update = updateESP,
    }
end

local function setupPetESP(pet)
    if espTracker[pet] then return end
    if pet:GetAttribute("Species") == nil then return end
    
    local esp = createPetESP(pet)
    if esp then
        espTracker[pet] = esp
    end
end

local function scanPets()
    local runtimePets = Workspace:FindFirstChild("RuntimePets")
    if not runtimePets then return end
    
    for _, pet in ipairs(runtimePets:GetChildren()) do
        setupPetESP(pet)
    end
end

local runtimePetsFolder = Workspace:FindFirstChild("RuntimePets")
if runtimePetsFolder then
    runtimePetsFolder.ChildAdded:Connect(function(child)
        task.wait(0.1)
        setupPetESP(child)
    end)
    runtimePetsFolder.ChildRemoved:Connect(function(child)
        removePetESP(child)
    end)
end

Workspace.ChildAdded:Connect(function(child)
    if child.Name == "RuntimePets" and child:IsA("Folder") then
        child.ChildAdded:Connect(function(pet)
            task.wait(0.1)
            setupPetESP(pet)
        end)
        child.ChildRemoved:Connect(function(pet)
            removePetESP(pet)
        end)
        for _, pet in ipairs(child:GetChildren()) do
            setupPetESP(pet)
        end
    end
end)

scanPets()

task.spawn(function()
    while task.wait(0.5) do
        if petsEspEnabled then
            for pet, esp in pairs(espTracker) do
                if pet.Parent then
                    esp.update()
                else
                    removePetESP(pet)
                end
            end
            scanPets()
        else
            for pet, esp in pairs(espTracker) do
                removePetESP(pet)
            end
        end
    end
end)
--------------------------------------------------
-- ANTI KNOCKBACK (POSITION LOCK)
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
        
        -- Детект knocksback: горизонтальная скорость > 40 или вертикальная > 35 (не прыжок)
        if horizontalSpeed > 40 or (upwardSpeed > 35 and not isJumpVelocity) then
            isCountering = true
            counterEndTime = now + 0.5
        end
        
        if isCountering and now < counterEndTime then
            -- ПОЛНОСТЬЮ обнуляем velocity
            rootPart.AssemblyLinearVelocity = Vector3.zero
            -- Телепортируем обратно на безопасную позицию
            if lastSafePos then
                rootPart.CFrame = CFrame.new(lastSafePos)
            end
        else
            isCountering = false
            -- Сохраняем безопасную позицию каждый кадр
            lastSafePos = rootPart.Position
        end
    end)
end

local function stopAntiKnockback()
    if antiKnockbackConnection then
        antiKnockbackConnection:Disconnect()
        antiKnockbackConnection = nil
    end
end

--------------------------------------------------
-- AUTO LOCK BASE (БЕЗ 20-минутной блокировки)
--------------------------------------------------
local function findMyPlot()
    local plotsFolder = Workspace:FindFirstChild("Plots")
    if not plotsFolder then return nil end

    for _, plot in ipairs(plotsFolder:GetChildren()) do
        if plot:IsA("Model") then
            local ownerUserId = plot:GetAttribute("OwnerUserId")
            if ownerUserId == LocalPlayer.UserId then
                return plot
            end
        end
    end
    return nil
end

local function getNetworkModule()
    local shared = ReplicatedStorage:FindFirstChild("Shared")
    if shared then
        local services = shared:FindFirstChild("Services")
        if services then
            return services:FindFirstChild("Network")
        end
    end
    return nil
end

local function startAutoLock()
    if autoLockConnection then return end

    local skipCooldownDebounce = false

    autoLockConnection = task.spawn(function()
        while autoLockEnabled do
            local myPlot = findMyPlot()

            if myPlot and rootPart and humanoid then
                -- Ищем ТОЛЬКО "Lock" (не "Lock 24hr")
                local lockObj = myPlot:FindFirstChild("Lock")
                
                if lockObj and lockObj.Name == "Lock" then
                    local currentState = lockObj:GetAttribute(LOCK_STATE_ATTR) or STATE_IDLE
                    local pad = lockObj:FindFirstChild("Pad")

                    if currentState == STATE_IDLE and pad then
                        -- Трогаем ТОЛЬКО Pad
                        pcall(function()
                            firetouchinterest(rootPart, pad, 0)
                        end)
                        task.wait(0.1)
                        pcall(function()
                            firetouchinterest(rootPart, pad, 1)
                        end)

                    elseif currentState == "Cooldown" then
                        if not skipCooldownDebounce then
                            skipCooldownDebounce = true

                            -- Скип кулдауна через Network
                            local netMod = getNetworkModule()
                            if netMod then
                                local success, network = pcall(function()
                                    return require(netMod)
                                end)
                                if success and network and network.send then
                                    pcall(function()
                                        network.send("request_skip_cooldown", myPlot.Name)
                                    end)
                                end
                            end

                            -- Скип через ProximityPrompt на Pad
                            if pad then
                                local prompt = pad:FindFirstChild("SkipCooldownPrompt")
                                if prompt and prompt:IsA("ProximityPrompt") then
                                    pcall(function()
                                        fireproximityprompt(prompt)
                                    end)
                                end
                            end

                            task.wait(5)
                            skipCooldownDebounce = false
                        end
                    end
                end
            end
            task.wait(0.5)
        end
    end)
end

local function stopAutoLock()
    if autoLockConnection then
        task.cancel(autoLockConnection)
        autoLockConnection = nil
    end
end

--------------------------------------------------
-- ANTI ANTI-CHEAT (LIGHTWEIGHT)
--------------------------------------------------
local kickHooked = false

local function startAntiCheatBypass()
    if antiCheatConnection then return end

    if not kickHooked then
        kickHooked = true
        pcall(function()
            if hookmetamethod then
                local oldNamecall
                oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
                    local method = getnamecallmethod()
                    if method == "Kick" and self == LocalPlayer then
                        return
                    end
                    return oldNamecall(self, ...)
                end)
            end
        end)
        pcall(function()
            if hookmetamethod then
                local oldIndex
                oldIndex = hookmetamethod(game, "__index", function(self, key)
                    if key == "Kick" and self == LocalPlayer then
                        return function() end
                    end
                    return oldIndex(self, key)
                end)
            end
        end)
    end

    antiCheatConnection = task.spawn(function()
        while antiCheatBypassEnabled do
            local playerData = LocalPlayer:FindFirstChild("Player Data")
            if playerData then
                local stats = playerData:FindFirstChild("stats")
                if stats then
                    local bans = stats:FindFirstChild("#Anti Cheat Bans")
                    local kicks = stats:FindFirstChild("#Anti Cheat Kicks")
                    if bans then pcall(function() bans.Value = 0 end) end
                    if kicks then pcall(function() kicks.Value = 0 end) end
                end
            end
            task.wait(3)
        end
    end)
end

local function stopAntiCheatBypass()
    if antiCheatConnection then
        task.cancel(antiCheatConnection)
        antiCheatConnection = nil
    end
end

--------------------------------------------------
-- WALL HOP (ПЛАВНЫЙ ПОЛЁТ + ЗАЧИСТКА КРАЯ)
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
        -- Блоки впереди есть — плавно поднимаем вверх
        wallHopActive = true
        wallHopWasClimbing = true
        wallHopClearTimer = 0
        
        local upVel = 20 + math.random(-1, 3) -- 19-23, чуть быстрее
        local currentVel = rootPart.AssemblyLinearVelocity
        rootPart.AssemblyLinearVelocity = Vector3.new(currentVel.X, upVel, currentVel.Z)
    else
        -- Блоков впереди нет
        if wallHopWasClimbing then
            -- Мы только что лазили — даём рывок чтобы перелезть край
            wallHopClearTimer = wallHopClearTimer + 1
            
            if wallHopClearTimer < 8 then
                -- Рывок вверх + вперёд (8 кадров ≈ 0.13 сек)
                local currentVel = rootPart.AssemblyLinearVelocity
                rootPart.AssemblyLinearVelocity = Vector3.new(
                    forwardDirection.X * 25,
                    30,
                    forwardDirection.Z * 25
                )
            else
                -- Закончили зачистку
                wallHopWasClimbing = false
                wallHopClearTimer = 0
            end
        end
        
        wallHopActive = false
    end
end)
--------------------------------------------------
-- ANTI FALL CIRCLE
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
    if AntiFall then
        AntiFall:Destroy()
        AntiFall = nil
    end
end

--------------------------------------------------
-- ANTI AFK
--------------------------------------------------
local function startAntiAfk()
    if antiAfkConnection then return end
    local VirtualUser = game:GetService("VirtualUser")
    antiAfkConnection = LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end

local function stopAntiAfk()
    if antiAfkConnection then
        antiAfkConnection:Disconnect()
        antiAfkConnection = nil
    end
end

--------------------------------------------------
-- SAVED JOB IDS
--------------------------------------------------
local FileName = "SavedJobIDs.json"
local SavedJobs = {}

if isfile and isfile(FileName) then
    local success, data = pcall(function()
        return HttpService:JSONDecode(readfile(FileName))
    end)
    if success and type(data) == "table" then
        SavedJobs = data
    end
end

local function SaveJobs()
    if writefile then
        writefile(FileName, HttpService:JSONEncode(SavedJobs))
    end
end

--------------------------------------------------
-- GUI
--------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SSSHubSteal"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 999999
ScreenGui.Parent = game:GetService("CoreGui")

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 270, 0, 340)
Main.Position = UDim2.new(0.5, -135, 0.5, -170)
Main.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
Main.BorderSizePixel = 0
Main.Active = true
Main.Parent = ScreenGui

MakeDraggable(Main)

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 9)
MainCorner.Parent = Main

local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 32)
TopBar.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
TopBar.BorderSizePixel = 0
TopBar.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -40, 1, 0)
Title.Position = UDim2.new(0, 9, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "SSS HUB STEAL"
Title.TextColor3 = Color3.fromRGB(240, 240, 245)
Title.TextSize = 11
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

local HideButton = Instance.new("TextButton")
HideButton.Size = UDim2.new(0, 22, 0, 22)
HideButton.Position = UDim2.new(1, -27, 0, 5)
HideButton.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
HideButton.BorderSizePixel = 0
HideButton.Text = "—"
HideButton.TextColor3 = Color3.fromRGB(255, 255, 255)
HideButton.TextSize = 11
HideButton.Font = Enum.Font.GothamBold
HideButton.Parent = TopBar

local function CreateButton(parent, text, position, size)
    local button = Instance.new("TextButton")
    button.Size = size
    button.Position = position
    button.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    button.BorderSizePixel = 0
    button.Text = text
    button.TextColor3 = Color3.fromRGB(235, 235, 240)
    button.TextSize = 8
    button.Font = Enum.Font.GothamBold
    button.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 5)
    corner.Parent = button

    return button
end

local MainTab = CreateButton(Main, "MAIN", UDim2.new(0, 3, 0, 38), UDim2.new(0.33, -4, 0, 25))
local CombatTab = CreateButton(Main, "COMBAT", UDim2.new(0.33, 1, 0, 38), UDim2.new(0.33, -4, 0, 25))
local ServerTab = CreateButton(Main, "SERVER", UDim2.new(0.66, -1, 0, 38), UDim2.new(0.34, -4, 0, 25))

local MainPage = Instance.new("Frame")
MainPage.Size = UDim2.new(1, -10, 1, -70)
MainPage.Position = UDim2.new(0, 5, 0, 68)
MainPage.BackgroundTransparency = 1
MainPage.Parent = Main

local CombatPage = Instance.new("Frame")
CombatPage.Size = UDim2.new(1, -10, 1, -70)
CombatPage.Position = UDim2.new(0, 5, 0, 68)
CombatPage.BackgroundTransparency = 1
CombatPage.Visible = false
CombatPage.Parent = Main

local ServerPage = Instance.new("Frame")
ServerPage.Size = UDim2.new(1, -10, 1, -70)
ServerPage.Position = UDim2.new(0, 5, 0, 68)
ServerPage.BackgroundTransparency = 1
ServerPage.Visible = false
ServerPage.Parent = Main

--------------------------------------------------
-- MAIN PAGE BUTTONS
--------------------------------------------------
local AutoRunButton = CreateButton(MainPage, "AUTO RUN     OFF", UDim2.new(0, 5, 0, 5), UDim2.new(1, -10, 0, 26))
local ESPButton = CreateButton(MainPage, "ESP     OFF", UDim2.new(0, 5, 0, 40), UDim2.new(1, -10, 0, 26))
local PetsEspButton = CreateButton(MainPage, "PETS ESP     OFF", UDim2.new(0, 5, 0, 75), UDim2.new(1, -10, 0, 26))
-- Кнопка открытия меню фильтров
local PetFilterButton = CreateButton(MainPage, "FILTER", UDim2.new(0, 90, 0, 75), UDim2.new(0, 70, 0, 26))

-- Меню фильтров
local PetFilterMenu = Instance.new("Frame")
PetFilterMenu.Size = UDim2.new(0, 260, 0, 120)
PetFilterMenu.Position = UDim2.new(0.5, -130, 0.5, -60)
PetFilterMenu.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
PetFilterMenu.BorderSizePixel = 0
PetFilterMenu.Visible = false
PetFilterMenu.Active = true
PetFilterMenu.ZIndex = 20
PetFilterMenu.Parent = ScreenGui

MakeDraggable(PetFilterMenu)

local PetFilterCorner = Instance.new("UICorner")
PetFilterCorner.CornerRadius = UDim.new(0, 8)
PetFilterCorner.Parent = PetFilterMenu

local PetFilterTitle = Instance.new("TextLabel")
PetFilterTitle.Size = UDim2.new(1, -10, 0, 22)
PetFilterTitle.Position = UDim2.new(0, 5, 0, 3)
PetFilterTitle.BackgroundTransparency = 1
PetFilterTitle.Text = "PET FILTERS"
PetFilterTitle.TextColor3 = Color3.fromRGB(235, 235, 240)
PetFilterTitle.TextSize = 10
PetFilterTitle.Font = Enum.Font.GothamBold
PetFilterTitle.TextXAlignment = Enum.TextXAlignment.Left
PetFilterTitle.ZIndex = 21
PetFilterTitle.Parent = PetFilterMenu

-- Поле имени
local nameLabel = Instance.new("TextLabel")
nameLabel.Size = UDim2.new(0.4, 0, 0, 20)
nameLabel.Position = UDim2.new(0, 5, 0, 30)
nameLabel.BackgroundTransparency = 1
nameLabel.Text = "Name:"
nameLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
nameLabel.TextSize = 9
nameLabel.Font = Enum.Font.Gotham
nameLabel.TextXAlignment = Enum.TextXAlignment.Left
nameLabel.ZIndex = 21
nameLabel.Parent = PetFilterMenu

local nameBox = Instance.new("TextBox")
nameBox.Size = UDim2.new(0.55, 0, 0, 20)
nameBox.Position = UDim2.new(0.4, 0, 0, 30)
nameBox.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
nameBox.BorderSizePixel = 0
nameBox.Text = ""
nameBox.PlaceholderText = "e.g. Dragon"
nameBox.TextColor3 = Color3.fromRGB(255, 255, 255)
nameBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
nameBox.TextSize = 9
nameBox.Font = Enum.Font.Gotham
nameBox.ZIndex = 21
nameBox.Parent = PetFilterMenu

local nameBoxCorner = Instance.new("UICorner")
nameBoxCorner.CornerRadius = UDim.new(0, 4)
nameBoxCorner.Parent = nameBox

-- Поле MPS
local mpsLabel = Instance.new("TextLabel")
mpsLabel.Size = UDim2.new(0.4, 0, 0, 20)
mpsLabel.Position = UDim2.new(0, 5, 0, 55)
mpsLabel.BackgroundTransparency = 1
mpsLabel.Text = "Min MPS:"
mpsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
mpsLabel.TextSize = 9
mpsLabel.Font = Enum.Font.Gotham
mpsLabel.TextXAlignment = Enum.TextXAlignment.Left
mpsLabel.ZIndex = 21
mpsLabel.Parent = PetFilterMenu

local mpsBox = Instance.new("TextBox")
mpsBox.Size = UDim2.new(0.55, 0, 0, 20)
mpsBox.Position = UDim2.new(0.4, 0, 0, 55)
mpsBox.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
mpsBox.BorderSizePixel = 0
mpsBox.Text = "0"
mpsBox.TextColor3 = Color3.fromRGB(255, 255, 255)
mpsBox.TextSize = 9
mpsBox.Font = Enum.Font.Gotham
mpsBox.ZIndex = 21
mpsBox.Parent = PetFilterMenu

local mpsBoxCorner = Instance.new("UICorner")
mpsBoxCorner.CornerRadius = UDim.new(0, 4)
mpsBoxCorner.Parent = mpsBox

-- Кнопка Apply
local applyBtn = CreateButton(PetFilterMenu, "APPLY", UDim2.new(0.2, 5, 0, 85), UDim2.new(0.6, -10, 0, 25))
applyBtn.ZIndex = 21

-- Кнопка Clear
local clearBtn = CreateButton(PetFilterMenu, "CLEAR", UDim2.new(0.8, 0, 0, 85), UDim2.new(0.2, -5, 0, 25))
clearBtn.ZIndex = 21

PetFilterButton.MouseButton1Click:Connect(function()
    PetFilterMenu.Visible = not PetFilterMenu.Visible
end)

applyBtn.MouseButton1Click:Connect(function()
    petFilterName = nameBox.Text
    petFilterMPS = tonumber(mpsBox.Text) or 0
    PetFilterMenu.Visible = false
end)

clearBtn.MouseButton1Click:Connect(function()
    nameBox.Text = ""
    mpsBox.Text = "0"
    petFilterName = ""
    petFilterMPS = 0
end)

local AntiFallButton = CreateButton(MainPage, "ANTI FALL     OFF", UDim2.new(0, 5, 0, 110), UDim2.new(1, -10, 0, 26))
local AntiCheatButton = CreateButton(MainPage, "ANTI ANTI-CHEAT     OFF", UDim2.new(0, 5, 0, 145), UDim2.new(1, -10, 0, 26))
local AntiAfkButton = CreateButton(MainPage, "ANTI AFK     OFF", UDim2.new(0, 5, 0, 180), UDim2.new(1, -10, 0, 26))
local BypassButton = CreateButton(MainPage, "BYPASS", UDim2.new(0, 5, 1, -35), UDim2.new(0, 80, 0, 28))

AutoRunButton.MouseButton1Click:Connect(function()
    autoRun = not autoRun
    AutoRunButton.Text = "AUTO RUN     " .. (autoRun and "ON" or "OFF")
end)

ESPButton.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    ESPButton.Text = "ESP     " .. (espEnabled and "ON" or "OFF")
    updateESP()
end)

PetsEspButton.MouseButton1Click:Connect(function()
    petsEspEnabled = not petsEspEnabled
    PetsEspButton.Text = "PETS ESP     " .. (petsEspEnabled and "ON" or "OFF")
    if not petsEspEnabled then
        for pet, _ in pairs(espTracker) do
            removePetESP(pet)
        end
    end
end)

AntiFallButton.MouseButton1Click:Connect(function()
    antiFallEnabled = not antiFallEnabled
    if antiFallEnabled then
        AntiFall = CreateAntiFall()
    else
        RemoveAntiFall()
    end
    AntiFallButton.Text = "ANTI FALL     " .. (antiFallEnabled and "ON" or "OFF")
end)

AntiCheatButton.MouseButton1Click:Connect(function()
    antiCheatBypassEnabled = not antiCheatBypassEnabled
    AntiCheatButton.Text = "ANTI ANTI-CHEAT     " .. (antiCheatBypassEnabled and "ON" or "OFF")
    if antiCheatBypassEnabled then startAntiCheatBypass() else stopAntiCheatBypass() end
end)

AntiAfkButton.MouseButton1Click:Connect(function()
    antiAfkEnabled = not antiAfkEnabled
    AntiAfkButton.Text = "ANTI AFK     " .. (antiAfkEnabled and "ON" or "OFF")
    if antiAfkEnabled then startAntiAfk() else stopAntiAfk() end
end)

--------------------------------------------------
-- COMBAT PAGE BUTTONS
--------------------------------------------------
local AntiKnockbackButton = CreateButton(CombatPage, "ANTI KNOCKBACK     OFF", UDim2.new(0, 5, 0, 5), UDim2.new(1, -10, 0, 26))
local AutoLockButton = CreateButton(CombatPage, "AUTO LOCK     OFF", UDim2.new(0, 5, 0, 40), UDim2.new(1, -10, 0, 26))

AntiKnockbackButton.MouseButton1Click:Connect(function()
    antiKnockbackEnabled = not antiKnockbackEnabled
    AntiKnockbackButton.Text = "ANTI KNOCKBACK     " .. (antiKnockbackEnabled and "ON" or "OFF")
    if antiKnockbackEnabled then startAntiKnockback() else stopAntiKnockback() end
end)

AutoLockButton.MouseButton1Click:Connect(function()
    autoLockEnabled = not autoLockEnabled
    AutoLockButton.Text = "AUTO LOCK     " .. (autoLockEnabled and "ON" or "OFF")
    if autoLockEnabled then startAutoLock() else stopAutoLock() end
end)

--------------------------------------------------
-- BYPASS MENU
--------------------------------------------------
local BypassMenu = Instance.new("Frame")
BypassMenu.Size = UDim2.new(0, 150, 0, 125)
BypassMenu.Position = UDim2.new(0.5, 20, 0.5, -60)
BypassMenu.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
BypassMenu.BorderSizePixel = 0
BypassMenu.Visible = false
BypassMenu.Active = true
BypassMenu.ZIndex = 20
BypassMenu.Parent = ScreenGui

MakeDraggable(BypassMenu)

local BypassCorner = Instance.new("UICorner")
BypassCorner.CornerRadius = UDim.new(0, 8)
BypassCorner.Parent = BypassMenu

local BypassTitle = Instance.new("TextLabel")
BypassTitle.Size = UDim2.new(1, -10, 0, 22)
BypassTitle.Position = UDim2.new(0, 5, 0, 3)
BypassTitle.BackgroundTransparency = 1
BypassTitle.Text = "BYPASS"
BypassTitle.TextColor3 = Color3.fromRGB(235, 235, 240)
BypassTitle.TextSize = 10
BypassTitle.Font = Enum.Font.GothamBold
BypassTitle.TextXAlignment = Enum.TextXAlignment.Left
BypassTitle.ZIndex = 21
BypassTitle.Parent = BypassMenu

local WallHopButton = CreateButton(BypassMenu, "WALL HOP     OFF", UDim2.new(0, 5, 0, 28), UDim2.new(1, -10, 0, 27))
WallHopButton.ZIndex = 21

local EnterBase = CreateButton(BypassMenu, "ENTER BASE", UDim2.new(0, 5, 0, 60), UDim2.new(1, -10, 0, 27))
EnterBase.ZIndex = 21

local ExitBase = CreateButton(BypassMenu, "EXIT BASE", UDim2.new(0, 5, 0, 92), UDim2.new(1, -10, 0, 27))
ExitBase.ZIndex = 21

BypassButton.MouseButton1Click:Connect(function()
    BypassMenu.Visible = not BypassMenu.Visible
end)

WallHopButton.MouseButton1Click:Connect(function()
    wallHopEnabled = not wallHopEnabled
    WallHopButton.Text = "WALL HOP     " .. (wallHopEnabled and "ON" or "OFF")
end)

--------------------------------------------------
-- ENTER / EXIT BASE (PHYSICS DROP)
--------------------------------------------------
local baseDebounce = false

local function smoothVerticalMove(distance, direction)
    if not rootPart or baseDebounce then return end
    baseDebounce = true

    local startPos = rootPart.Position
    local targetY = startPos.Y + (distance * direction)
    
    task.spawn(function()
        -- Отключаем коллизию чтобы не застрять в блоках
        local originalCollide = rootPart.CanCollide
        pcall(function() rootPart.CanCollide = false end)
        
        -- Создаём BodyVelocity для физического движения
        local bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(0, math.huge, 0)
        -- Скорость: 60 вниз, 40 вверх (плавно но быстро)
        bv.Velocity = Vector3.new(0, direction * 50, 0)
        bv.Parent = rootPart
        
        local startTime = tick()
        local duration = distance / 50 -- Время = расстояние / скорость
        
        -- Летим пока не достигнем цели
        while rootPart and tick() - startTime < duration do
            task.wait(0.01)
        end
        
        -- Останавливаемся
        if bv then bv:Destroy() end
        
        -- Возвращаем коллизию
        if rootPart then
            pcall(function() rootPart.CanCollide = originalCollide end)
            -- Точная финальная позиция
            rootPart.CFrame = CFrame.new(
                rootPart.Position.X,
                targetY,
                rootPart.Position.Z
            ) * CFrame.Angles(0, math.rad(rootPart.Orientation.Y), 0)
        end
        
        task.wait(0.5)
        baseDebounce = false
    end)
end

EnterBase.MouseButton1Click:Connect(function()
    smoothVerticalMove(DOWN_DISTANCE, -1)
end)

ExitBase.MouseButton1Click:Connect(function()
    smoothVerticalMove(UP_DISTANCE, 1)
end)

--------------------------------------------------
-- SERVER PAGE
--------------------------------------------------
local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, -10, 0, 16)
Status.Position = UDim2.new(0, 5, 0, 3)
Status.BackgroundTransparency = 1
Status.Text = "Saved Job ID: " .. #SavedJobs
Status.TextColor3 = Color3.fromRGB(150, 150, 160)
Status.TextSize = 8
Status.Font = Enum.Font.Gotham
Status.TextXAlignment = Enum.TextXAlignment.Left
Status.Parent = ServerPage

local BusyButton = CreateButton(ServerPage, "JOIN RAMAI", UDim2.new(0, 5, 0, 25), UDim2.new(0.5, -8, 0, 27))
local EmptyButton = CreateButton(ServerPage, "JOIN SEPI", UDim2.new(0.5, 3, 0, 25), UDim2.new(0.5, -8, 0, 27))
local CopyButton = CreateButton(ServerPage, "COPY & SAVE", UDim2.new(0, 5, 0, 57), UDim2.new(0.58, -7, 0, 27))
local ReconnectButton = CreateButton(ServerPage, "RECONNECT", UDim2.new(0.58, 2, 0, 57), UDim2.new(0.42, -7, 0, 27))

local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -10, 0, 145)
Scroll.Position = UDim2.new(0, 5, 0, 90)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel = 0
Scroll.ScrollBarThickness = 2
Scroll.ScrollingDirection = Enum.ScrollingDirection.Y
Scroll.Parent = ServerPage

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 4)
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.Parent = Scroll

local Padding = Instance.new("UIPadding")
Padding.PaddingTop = UDim.new(0, 3)
Padding.PaddingBottom = UDim.new(0, 3)
Padding.PaddingLeft = UDim.new(0, 3)
Padding.PaddingRight = UDim.new(0, 3)
Padding.Parent = Scroll

local function UpdateList()
    for _, child in ipairs(Scroll:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    for index, Data in ipairs(SavedJobs) do
        local Row = Instance.new("Frame")
        Row.Size = UDim2.new(1, -6, 0, 30)
        Row.BackgroundColor3 = Color3.fromRGB(38, 38, 45)
        Row.BorderSizePixel = 0
        Row.Parent = Scroll

        local RowCorner = Instance.new("UICorner")
        RowCorner.CornerRadius = UDim.new(0, 7)
        RowCorner.Parent = Row

        local JobText = Instance.new("TextLabel")
        JobText.Size = UDim2.new(1, -145, 1, 0)
        JobText.Position = UDim2.new(0, 8, 0, 0)
        JobText.BackgroundTransparency = 1
        JobText.Text = Data.Name or ("Server " .. index)
        JobText.TextColor3 = Color3.fromRGB(220, 220, 225)
        JobText.TextSize = 8
        JobText.Font = Enum.Font.Gotham
        JobText.TextXAlignment = Enum.TextXAlignment.Left
        JobText.Parent = Row

        local Join = CreateButton(Row, "JOIN", UDim2.new(1, -130, 0.5, -10), UDim2.new(0, 38, 0, 20))
        Join.MouseButton1Click:Connect(function()
            TeleportService:TeleportToPlaceInstance(PlaceId, Data.JobId, LocalPlayer)
        end)

        local Rename = CreateButton(Row, "RENAME", UDim2.new(1, -88, 0.5, -10), UDim2.new(0, 52, 0, 20))
        Rename.MouseButton1Click:Connect(function()
            Data.Name = "Server " .. index
            SaveJobs()
            UpdateList()
        end)

        local Delete = CreateButton(Row, "X", UDim2.new(1, -30, 0.5, -10), UDim2.new(0, 22, 0, 20))
        Delete.MouseButton1Click:Connect(function()
            table.remove(SavedJobs, index)
            SaveJobs()
            UpdateList()
        end)
    end

    Scroll.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y + 6)
    Status.Text = "Saved Job ID: " .. #SavedJobs
end

CopyButton.MouseButton1Click:Connect(function()
    local CurrentJobId = game.JobId
    if #SavedJobs >= 3 then
        Status.Text = "Maksimal 3 Job ID!"
        return
    end

    for _, Data in ipairs(SavedJobs) do
        if Data.JobId == CurrentJobId then
            Status.Text = "Job ID sudah ada!"
            return
        end
    end

    table.insert(SavedJobs, {
        JobId = CurrentJobId,
        Name = "Server " .. (#SavedJobs + 1)
    })
    SaveJobs()

    if setclipboard then
        setclipboard(CurrentJobId)
    elseif toclipboard then
        toclipboard(CurrentJobId)
    end

    Status.Text = "Job ID berhasil disimpan!"
    UpdateList()
end)

ReconnectButton.MouseButton1Click:Connect(function()
    TeleportService:TeleportToPlaceInstance(PlaceId, game.JobId, LocalPlayer)
end)

--------------------------------------------------
-- SERVER HOP
--------------------------------------------------
local ServerSearching = false

local function GetServers()
    local AllServers = {}
    local Cursor = nil

    for Page = 1, 5 do
        local Url = "https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?limit=100"
        if Cursor then
            Url = Url .. "&cursor=" .. HttpService:UrlEncode(Cursor)
        end

        local Success, Result = pcall(function()
            return game:HttpGet(Url)
        end)
        if not Success then break end

        local DecodeSuccess, Data = pcall(function()
            return HttpService:JSONDecode(Result)
        end)
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
        Status.Text = "Scan server " .. Attempt .. "/5..."
        local Servers = GetServers()

        for _, Server in ipairs(Servers) do
            if Server.id ~= game.JobId and Server.playing < Server.maxPlayers then
                if Mode == "BUSY" then
                    if not BestServer or Server.playing > BestServer.playing then
                        BestServer = Server
                    end
                elseif Mode == "EMPTY" then
                    if not BestServer or Server.playing < BestServer.playing then
                        BestServer = Server
                    end
                end
            end
        end

        if BestServer then return BestServer end
        task.wait(1)
    end
    return nil
end

BusyButton.MouseButton1Click:Connect(function()
    if ServerSearching then return end
    ServerSearching = true
    Status.Text = "Mencari server ramai..."

    local Server = FindServer("BUSY")
    if Server then
        Status.Text = "Join server ramai: " .. Server.playing .. "/" .. Server.maxPlayers
        task.wait(0.5)
        TeleportService:TeleportToPlaceInstance(PlaceId, Server.id, LocalPlayer)
    else
        Status.Text = "Server ramai tidak ditemukan!"
    end
    ServerSearching = false
end)

EmptyButton.MouseButton1Click:Connect(function()
    if ServerSearching then return end
    ServerSearching = true
    Status.Text = "Mencari server sepi..."

    local Server = FindServer("EMPTY")
    if Server then
        Status.Text = "Join server sepi: " .. Server.playing .. "/" .. Server.maxPlayers
        task.wait(0.5)
        TeleportService:TeleportToPlaceInstance(PlaceId, Server.id, LocalPlayer)
    else
        Status.Text = "Server sepi tidak ditemukan!"
    end
    ServerSearching = false
end)

--------------------------------------------------
-- TAB SWITCHING
--------------------------------------------------
MainTab.MouseButton1Click:Connect(function()
    MainPage.Visible = true
    CombatPage.Visible = false
    ServerPage.Visible = false
    MainTab.BackgroundColor3 = Color3.fromRGB(65, 95, 145)
    CombatTab.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    ServerTab.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
end)

CombatTab.MouseButton1Click:Connect(function()
    MainPage.Visible = false
    CombatPage.Visible = true
    ServerPage.Visible = false
    CombatTab.BackgroundColor3 = Color3.fromRGB(65, 95, 145)
    MainTab.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    ServerTab.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
end)

ServerTab.MouseButton1Click:Connect(function()
    MainPage.Visible = false
    CombatPage.Visible = false
    ServerPage.Visible = true
    ServerTab.BackgroundColor3 = Color3.fromRGB(65, 95, 145)
    MainTab.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    CombatTab.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
end)

--------------------------------------------------
-- HIDE / SHOW
--------------------------------------------------
local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(0, 42, 0, 42)
ToggleButton.Position = UDim2.new(0, 15, 0.5, -21)
ToggleButton.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
ToggleButton.BorderSizePixel = 0
ToggleButton.Text = "LH"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.TextSize = 10
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.Visible = false
ToggleButton.Active = true
ToggleButton.Parent = ScreenGui

MakeDraggable(ToggleButton)

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 9)
ToggleCorner.Parent = ToggleButton

HideButton.MouseButton1Click:Connect(function()
    Main.Visible = false
    ToggleButton.Visible = true
end)

ToggleButton.MouseButton1Click:Connect(function()
    Main.Visible = true
    ToggleButton.Visible = false
end)

--------------------------------------------------
-- START
--------------------------------------------------
MainTab.BackgroundColor3 = Color3.fromRGB(65, 95, 145)
UpdateList()
