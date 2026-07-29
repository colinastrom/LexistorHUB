--// SSSHUB STEAL + MAIN
--// By Rosomax0 • Developer
--// MODIFIED BY ENI FOR R0

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
local autoSwingEnabled = false
local autoLockEnabled = false
local autoEquipEnabled = false
local antiAfkEnabled = false
local antiCheatBypassEnabled = false

local humanoid
local rootPart
local normalSpeed = 16

local ESPs = {}
local PetESPs = {}
local AntiFall
local autoSwingConnection
local autoLockConnection
local autoEquipConnection
local antiAfkConnection
local antiCheatConnection

local LOCK_STATE_ATTR = "LockState"
local LOCK_ENDS_ATTR = "LockEndsAt"
local STATE_LOCKED = "Locked"
local STATE_COOLDOWN = "Cooldown"
local STATE_IDLE = "Idle"

--------------------------------------------------
-- CHARACTER
--------------------------------------------------
local function setupCharacter(character)
    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")
    normalSpeed = humanoid.WalkSpeed
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
-- PETS ESP (BROAD SCAN)
--------------------------------------------------

local function removePetESP(pet)
    if PetESPs[pet] then
        PetESPs[pet]:Destroy()
        PetESPs[pet] = nil
    end
end

local function createPetESP(pet)
    removePetESP(pet)

    local folder = Instance.new("Folder")
    folder.Name = "PetESP"
    folder.Parent = pet

    local highlight = Instance.new("Highlight")
    highlight.Adornee = pet
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.FillColor = Color3.fromRGB(255, 180, 50)
    highlight.OutlineColor = Color3.fromRGB(255, 120, 0)
    highlight.Enabled = petsEspEnabled
    highlight.Parent = folder

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "PetESP_Name"
    billboard.Adornee = pet
    billboard.Size = UDim2.new(0, 100, 0, 18)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.AlwaysOnTop = true
    billboard.Enabled = petsEspEnabled
    billboard.Parent = folder

    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, 0, 1, 0)
    text.BackgroundTransparency = 1
    text.Text = "🐾 " .. pet.Name
    text.TextColor3 = Color3.fromRGB(255, 200, 50)
    text.TextStrokeTransparency = 0.5
    text.TextSize = 12
    text.Font = Enum.Font.GothamBold
    text.Parent = billboard

    PetESPs[pet] = folder
end

-- Проверка: похож ли объект на питомца
local function isPetModel(obj)
    if not obj:IsA("Model") then return false end
    if obj == LocalPlayer.Character then return false end
    
    -- Не игрок
    for _, player in ipairs(Players:GetPlayers()) do
        if obj == player.Character then return false end
    end
    
    -- Имеет Humanoid (питомцы обычно имеют)
    if obj:FindFirstChildOfClass("Humanoid") then
        -- Но не игрок
        if not Players:GetPlayerFromCharacter(obj) then
            return true
        end
    end
    
    -- Имеет PrimaryPart и маленький размер (питомцы маленькие)
    local primaryPart = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
    if primaryPart then
        -- Проверяем имя против шаблонов
        if petTemplateNames[obj.Name] then
            return true
        end
    end
    
    return false
end

local function scanPetsInWorkspace()
    -- Сканируем всё в workspace
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if isPetModel(obj) and not PetESPs[obj] then
            createPetESP(obj)
        end
    end
    
    -- Также сканируем внутри персонажей игроков (питомцы следуют за игроком)
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then
            for _, obj in ipairs(player.Character:GetDescendants()) do
                if isPetModel(obj) and not PetESPs[obj] then
                    createPetESP(obj)
                end
            end
        end
    end
end

local function updatePetESP()
    for pet, folder in pairs(PetESPs) do
        if not pet.Parent then
            removePetESP(pet)
        else
            for _, obj in ipairs(folder:GetChildren()) do
                if obj:IsA("Highlight") or obj:IsA("BillboardGui") then
                    obj.Enabled = petsEspEnabled
                end
            end
        end
    end
end

task.spawn(function()
    while task.wait(1) do
        if petsEspEnabled then
            scanPetsInWorkspace()
            updatePetESP()
        end
    end
end)

--------------------------------------------------
-- AUTO SWING (COMBAT)
--------------------------------------------------
local function startAutoSwing()
    if autoSwingConnection then return end

    autoSwingConnection = RunService.Heartbeat:Connect(function()
        if not humanoid or humanoid.Health <= 0 then return end

        local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")

        if tool then
            pcall(function()
                tool:Activate()
            end)
        end
    end)
end

local function stopAutoSwing()
    if autoSwingConnection then
        autoSwingConnection:Disconnect()
        autoSwingConnection = nil
    end
end

--------------------------------------------------
-- AUTO EQUIP BAT
--------------------------------------------------
local function startAutoEquip()
    if autoEquipConnection then return end

    autoEquipConnection = task.spawn(function()
        while autoEquipEnabled do
            if humanoid and humanoid.Health > 0 then
                local currentTool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")

                if not currentTool then
                    local backpack = LocalPlayer:FindFirstChild("Backpack")
                    if backpack then
                        for _, item in ipairs(backpack:GetChildren()) do
                            if item:IsA("Tool") and item.Name:match("Bat") then
                                pcall(function()
                                    humanoid:EquipTool(item)
                                end)
                                break
                            end
                        end
                    end
                end
            end
            task.wait(0.5)
        end
    end)
end

local function stopAutoEquip()
    if autoEquipConnection then
        task.cancel(autoEquipConnection)
        autoEquipConnection = nil
    end
end

--------------------------------------------------
-- AUTO LOCK BASE
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

local function tryLockViaNetwork(plotName)
    -- Пробуем все возможные пути к Network модулю
    local possiblePaths = {
        ReplicatedStorage:FindFirstChild("Modules"),
        ReplicatedStorage:FindFirstChild("Shared"),
        ReplicatedStorage:FindFirstChild("Shared") and ReplicatedStorage.Shared:FindFirstChild("Services"),
        ReplicatedStorage:FindFirstChild("Shared") and ReplicatedStorage.Shared:FindFirstChild("Modules"),
    }
    
    for _, path in ipairs(possiblePaths) do
        if path then
            local networkModule = path:FindFirstChild("Network")
            if networkModule then
                local success, network = pcall(function()
                    return require(networkModule)
                end)
                if success and network then
                    -- Пробуем send
                    if network.send then
                        pcall(function()
                            network.send("request_lock_base", plotName)
                        end)
                        pcall(function()
                            network.send("lock_base", plotName)
                        end)
                        pcall(function()
                            network:send("request_lock_base", plotName)
                        end)
                        return true
                    end
                    -- Пробуем FireServer
                    if network.FireServer then
                        pcall(function()
                            network:FireServer("request_lock_base", plotName)
                        end)
                        return true
                    end
                end
            end
        end
    end
    return false
end

local function tryLockViaProximityPrompt(plot)
    -- Ищем ProximityPrompt на Lock > Pad
    local lockObj = plot:FindFirstChild("Lock")
    if not lockObj then return false end
    
    local pad = lockObj:FindFirstChild("Pad")
    if not pad then 
        -- Может Pad это сам lockObj
        pad = lockObj 
    end
    
    -- Ищем все ProximityPrompt
    for _, descendant in ipairs(pad:GetDescendants()) do
        if descendant:IsA("ProximityPrompt") then
            pcall(function()
                fireproximityprompt(descendant)
            end)
            return true
        end
    end
    
    -- Также на самом Lock
    for _, descendant in ipairs(lockObj:GetDescendants()) do
        if descendant:IsA("ProximityPrompt") then
            pcall(function()
                fireproximityprompt(descendant)
            end)
            return true
        end
    end
    
    return false
end

local function tryLockViaRemote(plotName)
    -- Пробуем найти RemoteEvent в разных местах
    local searchFolders = {
        ReplicatedStorage,
        ReplicatedStorage:FindFirstChild("Remotes"),
        ReplicatedStorage:FindFirstChild("Events"),
        ReplicatedStorage:FindFirstChild("Network"),
        ReplicatedStorage:FindFirstChild("Shared"),
    }
    
    local remoteNames = {
        "request_lock_base", "LockBase", "RequestLock", "LockPlot",
        "lockBase", "lock_base", "BaseLock", "Lock"
    }
    
    for _, folder in ipairs(searchFolders) do
        if folder then
            for _, remoteName in ipairs(remoteNames) do
                local remote = folder:FindFirstChild(remoteName)
                if remote and remote:IsA("RemoteEvent") then
                    pcall(function()
                        remote:FireServer(plotName)
                    end)
                    return true
                end
                if remote and remote:IsA("RemoteFunction") then
                    pcall(function()
                        remote:InvokeServer(plotName)
                    end)
                    return true
                end
            end
        end
    end
    return false
end

local function startAutoLock()
    if autoLockConnection then return end

    autoLockConnection = task.spawn(function()
        while autoLockEnabled do
            local myPlot = findMyPlot()

            if myPlot then
                local lockObj = myPlot:FindFirstChild("Lock")
                local currentState = lockObj and lockObj:GetAttribute(LOCK_STATE_ATTR) or STATE_IDLE

                if currentState == STATE_IDLE then
                    -- Способ 1: Network модуль
                    tryLockViaNetwork(myPlot.Name)
                    
                    -- Способ 2: ProximityPrompt
                    tryLockViaProximityPrompt(myPlot)
                    
                    -- Способ 3: RemoteEvent
                    tryLockViaRemote(myPlot.Name)
                end
            end
            task.wait(math.random(3, 5))
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
-- ANTI ANTI-CHEAT
--------------------------------------------------
local function disableWorkspaceProbe()
    local probe = Workspace:FindFirstChild("AntiCheatProbe")
    if probe then
        if probe:IsA("Script") or probe:IsA("LocalScript") then
            pcall(function()
                probe.Disabled = true
            end)
            pcall(function()
                probe:Destroy()
            end)
        elseif probe:IsA("BasePart") then
            pcall(function()
                probe.CanTouch = false
                probe.CanCollide = false
                probe.CanQuery = false
                probe.Transparency = 1
            end)
        end
    end

    if probe then
        for _, child in ipairs(probe:GetDescendants()) do
            if child:IsA("Script") or child:IsA("LocalScript") then
                pcall(function()
                    child.Disabled = true
                end)
            end
        end
    end
end

local function disableNilAntiCheat()
    if not getnilinstances then return end

    local nilInstances = getnilinstances()

    for _, instance in ipairs(nilInstances) do
        local name = instance.Name and instance.Name:lower() or ""

        if name:find("anticheat")
        or name:find("anti_cheat")
        or name:find("antichet")
        or name:find("detection")
        or name:find("flag") then

            if instance:IsA("Script") or instance:IsA("LocalScript") then
                pcall(function()
                    instance.Disabled = true
                end)
            end

            if instance:IsA("BasePart") then
                pcall(function()
                    instance.CanTouch = false
                    instance.CanCollide = false
                    instance.CanQuery = false
                end)
            end
        end
    end
end

local function resetBanCounters()
    local playerData = LocalPlayer:FindFirstChild("Player Data")
    if not playerData then return end

    local stats = playerData:FindFirstChild("stats")
    if not stats then return end

    local bans = stats:FindFirstChild("#Anti Cheat Bans")
    local kicks = stats:FindFirstChild("#Anti Cheat Kicks")

    if bans then
        pcall(function()
            bans.Value = 0
        end)
    end

    if kicks then
        pcall(function()
            kicks.Value = 0
        end)
    end
end

local function startAntiCheatBypass()
    if antiCheatConnection then return end

    disableWorkspaceProbe()
--------------------------------------------------
-- ANTI ANTI-CHEAT (KICK HOOK + DISABLE)
--------------------------------------------------

local kickHooked = false

-- Перехват LocalPlayer:Kick()
local function hookKick()
    if kickHooked then return end
    kickHooked = true
    
    local mt = getrawmetatable(game)
    local oldNamecall = mt.__namecall
    local oldIndex = mt.__index
    
    if setreadonly then
        setreadonly(mt, false)
    end
    
    -- Перехват namecall (когда вызывается :Kick())
    mt.__namecall = newcclosure and newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        
        if method == "Kick" and self == LocalPlayer then
            return -- Блокируем кик
        end
        
        return oldNamecall(self, ...)
    end) or function(self, ...)
        local method = getnamecallmethod()
        if method == "Kick" and self == LocalPlayer then
            return
        end
        return oldNamecall(self, ...)
    end
    
    -- Также перехват index (на случай если античит вызывает .Kick как свойство)
    mt.__index = newcclosure and newcclosure(function(self, key)
        if key == "Kick" and self == LocalPlayer then
            return function() end -- Возвращаем пустую функцию
        end
        return oldIndex(self, key)
    end) or function(self, key)
        if key == "Kick" and self == LocalPlayer then
            return function() end
        end
        return oldIndex(self, key)
    end
    
    if setreadonly then
        setreadonly(mt, true)
    end
end

-- Альтернативный хук кика (проще)
local function hookKickSimple()
    local oldKick
    oldKick = hookfunc(LocalPlayer.Kick, function(self, ...)
        if self == LocalPlayer then
            return -- Блокируем
        end
        return oldKick(self, ...)
    end)
end

local function disableWorkspaceProbe()
    local probe = Workspace:FindFirstChild("AntiCheatProbe")
    if probe then
        -- Отключаем скрипты внутри
        for _, descendant in ipairs(probe:GetDescendants()) do
            if descendant:IsA("Script") or descendant:IsA("LocalScript") then
                pcall(function()
                    descendant.Disabled = true
                    descendant:Destroy()
                end)
            end
            if descendant:IsA("BasePart") then
                pcall(function()
                    descendant.CanTouch = false
                    descendant.CanCollide = false
                    descendant.CanQuery = false
                end)
            end
        end
        -- Сам probe
        if probe:IsA("Script") or probe:IsA("LocalScript") then
            pcall(function()
                probe.Disabled = true
                probe:Destroy()
            end)
        elseif probe:IsA("BasePart") then
            pcall(function()
                probe.CanTouch = false
                probe.CanCollide = false
                probe.CanQuery = false
                probe.Transparency = 1
            end)
        end
        -- Удаляем целиком
        pcall(function()
            probe:Destroy()
        end)
    end
end

local function disableNilAntiCheat()
    -- Пробуем getnilinstances
    local nilInstances = nil
    
    if getnilinstances then
        nilInstances = getnilinstances()
    elseif getinstances then
        -- Фильтруем только nil
        nilInstances = {}
        for _, inst in ipairs(getinstances()) do
            if inst.Parent == nil then
                table.insert(nilInstances, inst)
            end
        end
    end
    
    if not nilInstances then return end

    for _, instance in ipairs(nilInstances) do
        local name = (instance.Name or ""):lower()
        
        if name:find("anti") or name:find("cheat") or name:find("detect")
        or name:find("flag") or name:find("kick") or name:find("ban")
        or name:find("speed") or name:find("teleport") or name:find("movement") then
            
            if instance:IsA("Script") or instance:IsA("LocalScript") then
                pcall(function()
                    instance.Disabled = true
                end)
                pcall(function()
                    instance:Destroy()
                end)
            end
            
            if instance:IsA("BasePart") then
                pcall(function()
                    instance.CanTouch = false
                    instance.CanCollide = false
                    instance.CanQuery = false
                end)
            end
        end
    end
end

local function resetBanCounters()
    local playerData = LocalPlayer:FindFirstChild("Player Data")
    if not playerData then return end

    local stats = playerData:FindFirstChild("stats")
    if not stats then return end

    local bans = stats:FindFirstChild("#Anti Cheat Bans")
    local kicks = stats:FindFirstChild("#Anti Cheat Kicks")

    if bans then
        pcall(function()
            bans.Value = 0
        end)
    end

    if kicks then
        pcall(function()
            kicks.Value = 0
        end)
    end
end

local function startAntiCheatBypass()
    if antiCheatConnection then return end

    -- Хукаем кик ПЕРВЫМ делом
    pcall(hookKick)
    pcall(hookKickSimple)
    
    -- Потом отключаем античит
    disableWorkspaceProbe()
    disableNilAntiCheat()
    resetBanCounters()

    -- Постоянный мониторинг
    antiCheatConnection = task.spawn(function()
        while antiCheatBypassEnabled do
            disableWorkspaceProbe()
            disableNilAntiCheat()
            resetBanCounters()
            task.wait(1)
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
-- WALL HOP (STEALTH)
--------------------------------------------------
local wallHopDebounce = false
local wallHopLastTrigger = 0

RunService.Heartbeat:Connect(function()
    if not wallHopEnabled or not rootPart or not humanoid then return end
    if wallHopDebounce then return end

    local currentTime = tick()
    if currentTime - wallHopLastTrigger < 0.4 then return end

    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude

    local forwardDirection = rootPart.CFrame.LookVector
    local result = workspace:Raycast(rootPart.Position, forwardDirection * 2.5, rayParams)

    if result then
        wallHopDebounce = true
        wallHopLastTrigger = currentTime

        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)

        task.spawn(function()
            local hopHeight = math.random(8, 12) / 10
            for i = 1, 3 do
                rootPart.CFrame = rootPart.CFrame + Vector3.new(0, hopHeight, 0)
                task.wait(0.02)
            end
            local forwardNudge = forwardDirection * 2
            rootPart.CFrame = rootPart.CFrame + forwardNudge
            task.wait(0.15)
            wallHopDebounce = false
        end)
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

--------------------------------------------------
-- MAIN FRAME
--------------------------------------------------
local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 270, 0, 370)
Main.Position = UDim2.new(0.5, -135, 0.5, -185)
Main.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
Main.BorderSizePixel = 0
Main.Active = true
Main.Parent = ScreenGui

MakeDraggable(Main)

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 9)
MainCorner.Parent = Main

--------------------------------------------------
-- TOP BAR
--------------------------------------------------
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
--------------------------------------------------
-- BUTTON CREATOR
--------------------------------------------------
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

--------------------------------------------------
-- TABS
--------------------------------------------------
local MainTab = CreateButton(Main, "MAIN", UDim2.new(0, 3, 0, 38), UDim2.new(0.33, -4, 0, 25))
local CombatTab = CreateButton(Main, "COMBAT", UDim2.new(0.33, 1, 0, 38), UDim2.new(0.33, -4, 0, 25))
local ServerTab = CreateButton(Main, "SERVER", UDim2.new(0.66, -1, 0, 38), UDim2.new(0.34, -4, 0, 25))

--------------------------------------------------
-- PAGES
--------------------------------------------------
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
        for pet, _ in pairs(PetESPs) do
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
local AutoSwingButton = CreateButton(CombatPage, "AUTO SWING     OFF", UDim2.new(0, 5, 0, 5), UDim2.new(1, -10, 0, 26))
local AutoEquipButton = CreateButton(CombatPage, "AUTO EQUIP BAT     OFF", UDim2.new(0, 5, 0, 40), UDim2.new(1, -10, 0, 26))
local AutoLockButton = CreateButton(CombatPage, "AUTO LOCK     OFF", UDim2.new(0, 5, 0, 75), UDim2.new(1, -10, 0, 26))

AutoSwingButton.MouseButton1Click:Connect(function()
    autoSwingEnabled = not autoSwingEnabled
    AutoSwingButton.Text = "AUTO SWING     " .. (autoSwingEnabled and "ON" or "OFF")
    if autoSwingEnabled then startAutoSwing() else stopAutoSwing() end
end)

AutoEquipButton.MouseButton1Click:Connect(function()
    autoEquipEnabled = not autoEquipEnabled
    AutoEquipButton.Text = "AUTO EQUIP BAT     " .. (autoEquipEnabled and "ON" or "OFF")
    if autoEquipEnabled then startAutoEquip() else stopAutoEquip() end
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
-- ENTER / EXIT BASE (STEALTH TWEEN)
--------------------------------------------------
local baseDebounce = false

local function smoothVerticalMove(distance, direction)
    if not rootPart or baseDebounce then return end
    baseDebounce = true

    local startPos = rootPart.Position
    local targetY = startPos.Y + (distance * direction)

    local steps = math.random(60, 80)
    local stepDelay = math.random(12, 18) / 1000
    local stepSize = distance / steps * direction

    task.spawn(function()
        for i = 1, steps do
            if not rootPart then break end
            local jitter = math.random(-2, 2) / 100
            rootPart.CFrame = rootPart.CFrame + Vector3.new(
                jitter,
                stepSize + (math.random(-5, 5) / 1000),
                jitter
            )
            task.wait(stepDelay + (math.random(0, 3) / 1000))
        end

        if rootPart then
            rootPart.CFrame = CFrame.new(
                rootPart.Position.X,
                targetY,
                rootPart.Position.Z
            ) * CFrame.Angles(0, math.rad(rootPart.Orientation.Y), 0)
        end

        task.wait(math.random(40, 60) / 100)
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
UpdateList()"
