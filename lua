local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local sensitivity = 1
local waveFrequency = 2
local waveAmplitude = 2
local mode = 1
local spiralRadiusMultiplier = 0.5
local spiralHeightMultiplier = 2
local isStationary = false
local stationaryPosition = Vector3.new()

local LocalPlayer = game:GetService("Players").LocalPlayer

local function sethiddenproperty(instance, propertyName, value)
    local success, errorMessage = pcall(function()
        instance[propertyName] = value
    end)
    if not success then
        warn("Failed to set hidden property:", errorMessage)
    end
end

sethiddenproperty(LocalPlayer, "SimulationRadius", 9999999)
for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
    if player ~= LocalPlayer then
        sethiddenproperty(player, "SimulationRadius", 0)
    end
end

local function checkSimulationRadius()
    local LocalPlayer = game:GetService("Players").LocalPlayer
    local radius = LocalPlayer.SimulationRadius
    print("Local Player's Current Simulation Radius:", radius)
    
    for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
        if player ~= LocalPlayer then
            print("Other Player's Current Simulation Radius:", player.SimulationRadius)
        end
    end
end

local NetworkAccess = coroutine.create(function()
    settings().Physics.AllowSleep = false
    while true do
        sethiddenproperty(LocalPlayer, "SimulationRadius", math.huge)
        for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
            if player ~= LocalPlayer then
                sethiddenproperty(player, "SimulationRadius", 0)
            end
        end
        wait() -- ajajdrjjdkdkeek
    end
end)

coroutine.resume(NetworkAccess)

checkSimulationRadius()

local function OrbitAndFollowParts(player, unanchoredParts)
    local targetCharacter = player.Character
    local hrp = targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local numParts = #unanchoredParts
    if numParts == 0 then return end

    local orbitRadius = 10
    local orbitCenter = hrp.Position + Vector3.new(0, 15, 0)
    local angleIncrement = 2 * math.pi / numParts
    local currentAngle = 0
    local verticalRotationSpeed = 0.05

    local stopOrbit = false
    local orbitSpeed = 0.02
    local defaultOffset = 0

    local function updateSettings(speed, radius)
        orbitSpeed = speed
        orbitRadius = radius
    end

    local function updateOffset(offset)
        defaultOffset = offset
    end

    local function getAveragePlaybackLoudness()
        local totalPlaybackLoudness = 0
        local numSounds = 0
        for _, obj in ipairs(workspace:GetChildren()) do
            if obj:IsA("Sound") then
                totalPlaybackLoudness = totalPlaybackLoudness + obj.PlaybackLoudness
                numSounds = numSounds + 1
            end
        end
        if numSounds > 0 then
            return totalPlaybackLoudness / numSounds
        else
            return 0
        end
    end

    RunService.RenderStepped:Connect(function(deltaTime)
        if stopOrbit then
            return
        end

        local musicOffset = getAveragePlaybackLoudness()
        local totalOffset = defaultOffset + (musicOffset * 0.09)

        if isStationary then
            orbitCenter = stationaryPosition
        else
            orbitCenter = hrp.Position + Vector3.new(0, 21, 0)
        end

        for i, part in ipairs(unanchoredParts) do
            local offset
            if mode == 1 then
                offset = math.sin(tick() * waveFrequency + i * angleIncrement) * waveAmplitude
            elseif mode == 2 then
                offset = i * 0.1 * spiralRadiusMultiplier
            elseif mode == 3 then
                if i <= numParts / 2 then
                    offset = math.sin(tick() * waveFrequency + i * angleIncrement) * waveAmplitude
                else
                    offset = math.sin(tick() * waveFrequency + (i - numParts / 2) * angleIncrement) * waveAmplitude
                end
            elseif mode == 4 then
                if i % 2 == 0 then
                    offset = math.sin(tick() * waveFrequency + i * angleIncrement) * waveAmplitude
                else
                    offset = math.sin(tick() * waveFrequency - i * angleIncrement) * waveAmplitude
                end
            end

            local orbitPosition = Vector3.new(
                orbitCenter.X + (orbitRadius + totalOffset) * math.cos(currentAngle + i * angleIncrement),
                orbitCenter.Y + offset * spiralHeightMultiplier,  
                orbitCenter.Z + (orbitRadius + totalOffset) * math.sin(currentAngle + i * angleIncrement)
            )
            part.Position = part.Position:Lerp(orbitPosition, 0.1)
            local direction = (orbitPosition - part.Position).unit
            part.Velocity = direction * orbitSpeed * (orbitRadius + totalOffset)

            local horizontalRotation = CFrame.Angles(0, currentAngle + i * angleIncrement, 0)
            local verticalRotation = CFrame.Angles(0, 0, math.sin(tick()) * verticalRotationSpeed)
            part.CFrame = CFrame.new(part.Position) * horizontalRotation * verticalRotation
        end
        
        currentAngle = currentAngle + orbitSpeed
    end)

    for i,v in ipairs(player.Character:GetDescendants()) do
        if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then 
            RunService.Heartbeat:connect(function()
                if stopOrbit then return end
                v.Velocity = Vector3.new(34, 54, 0)
            end)
        end
    end

    player.Chatted:Connect(function(msg)
        local cmd, arg = msg:match("^(%S+)%s*(.*)")
        if cmd == ".stoporbit" then
            stopOrbit = true
        elseif cmd == ".ospeed" then
            updateSettings(tonumber(arg) or orbitSpeed, orbitRadius)
        elseif cmd == ".oradius" then
            updateSettings(orbitSpeed, tonumber(arg) or orbitRadius)
        elseif cmd == ".offset" then
            updateOffset(tonumber(arg) or defaultOffset)
        elseif cmd == ".mode" then
            mode = tonumber(arg) or mode
        elseif cmd == ".str" then
            sensitivity = tonumber(arg) or sensitivity
            waveFrequency = sensitivity * 0.1
        elseif cmd == ".waveamp" then
            waveAmplitude = tonumber(arg) or waveAmplitude
        elseif cmd == ".wavefreq" then
            waveFrequency = tonumber(arg) or waveFrequency
        elseif cmd == ".storb" then
            isStationary = true
            stationaryPosition = hrp.Position + Vector3.new(0, 15, 0)
        elseif cmd == ".backorb" then
            isStationary = false
        elseif cmd == ".spheight" then
            spiralHeightMultiplier = tonumber(arg) or spiralHeightMultiplier
        elseif cmd == ".oheight" then
            orbitCenter = hrp.Position + Vector3.new(0, tonumber(arg) or 15, 0)
        elseif cmd == ".givevis" then
            local String = arg:lower()
            local Found = {}
            for _, v in pairs(game:GetService("Players"):GetPlayers()) do
                if v.Name:lower():sub(1, #String) == String:lower() or (v.DisplayName and v.DisplayName:lower():sub(1, #String) == String:lower()) then
                    table.insert(Found, v)
                end
            end
            if #Found > 0 then
                for _, player in ipairs(Found) do
                    local unanchoredParts = UpdateUnanchoredParts()
                    OrbitAndFollowParts(player, unanchoredParts)
                end
            else
                print("Player not found.")
            end
        elseif cmd == ".retvis" then
            stopOrbit = true
            a:Disconnect()
        end
    end)
end

local function UpdateUnanchoredParts()
    local unanchoredParts = {}
    if placeId == 112420803 then
        for _, part in ipairs(workspace.Terrain._Game.Folder:GetDescendants()) do
            if part:IsA("BasePart") and not part.Anchored and part.Size == Vector3.new(4, 2, 1) then
                part.Massless = true
                part.CanCollide = false
                part.Anchored = false
                table.insert(unanchoredParts, part)
            end
        end
    else
        local workspaceParts = game.Workspace:GetChildren()
        for _, part in ipairs(workspaceParts) do
            if part:IsA("BasePart") and not part.Anchored then
                part.Massless = true
                part.CanCollide = false
                part.Anchored = false
                table.insert(unanchoredParts, part)
            end
        end
    end
    return unanchoredParts
end

local function StartOrbit()
    local unanchoredParts = UpdateUnanchoredParts()
    OrbitAndFollowParts(Players.LocalPlayer, unanchoredParts)
end

if placeId == 112420803 then
    for i = 1, 10 do
        game.Players:Chat("part/4/2/1")
    end
end

StartOrbit()
