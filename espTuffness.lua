local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Config = {
    TargetPart = "Head",
    MaxFOV = 300,
    TeamCheck = true,
    VisibleCheck = false,
    MaxDistance = 700,
    DrawFOV = true,
}

local fovVisibleState = true
local activeESP = {}

local skeletonBones = {
    {"Head", "UpperTorso"},
    {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"},
    {"LeftUpperArm", "LeftLowerArm"},
    {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"},
    {"RightUpperArm", "RightLowerArm"},
    {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"},
    {"LeftUpperLeg", "LeftLowerLeg"},
    {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"},
    {"RightUpperLeg", "RightLowerLeg"},
    {"RightLowerLeg", "RightFoot"}
}

local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 2
fovCircle.NumSides = 100
fovCircle.Radius = Config.MaxFOV
fovCircle.Color = Color3.fromRGB(255, 0, 100)
fovCircle.Transparency = 0.75
fovCircle.Visible = Config.DrawFOV
fovCircle.Filled = false

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.H then
        fovVisibleState = not fovVisibleState
    end
end)

local function cleanESP(player)
    local drawObjects = activeESP[player]
    if not drawObjects then return end

    if drawObjects.Box then drawObjects.Box:Remove() end
    if drawObjects.BoxOutline then drawObjects.BoxOutline:Remove() end
    if drawObjects.Health then drawObjects.Health:Remove() end
    if drawObjects.HealthOutline then drawObjects.HealthOutline:Remove() end
    if drawObjects.Name then drawObjects.Name:Remove() end

    if drawObjects.Skeleton then
        for _, line in ipairs(drawObjects.Skeleton) do
            line:Remove()
        end
    end

    activeESP[player] = nil
end

local function createESP(player)
    if player == LocalPlayer then return end

    local function setupCharacter(char)
        cleanESP(player)

        local bonesList = {}
        for i = 1, #skeletonBones do
            table.insert(bonesList, Drawing.new("Line"))
        end

        activeESP[player] = {
            Character = char,
            Box = Drawing.new("Square"),
            BoxOutline = Drawing.new("Square"),
            Health = Drawing.new("Line"),
            HealthOutline = Drawing.new("Line"),
            Name = Drawing.new("Text"),
            Skeleton = bonesList
        }
    end

    if player.Character then
        setupCharacter(player.Character)
    end

    player.CharacterAdded:Connect(setupCharacter)
    player.CharacterRemoving:Connect(function()
        cleanESP(player)
    end)
end

for _, player in ipairs(Players:GetPlayers()) do 
    createESP(player) 
end

Players.PlayerAdded:Connect(createESP)
Players.PlayerRemoving:Connect(cleanESP)

local function getTarget()
    local mouseLocation = UserInputService:GetMouseLocation()
    local currentTarget, currentDistance = nil, Config.MaxFOV
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer or not player.Character then continue end
        if Config.TeamCheck and player.Team == LocalPlayer.Team then continue end
        
        local character = player.Character
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then continue end
        
        local part = character:FindFirstChild(Config.TargetPart) or character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
        if not part then continue end
        
        local screenPos, isVisible = Camera:WorldToViewportPoint(part.Position)
        if not isVisible then continue end
        
        local distance = (Vector2.new(screenPos.X, screenPos.Y) - mouseLocation).Magnitude
        if distance < currentDistance then
            currentDistance = distance
            currentTarget = part
        end
    end
    return currentTarget
end

RunService.RenderStepped:Connect(function()
    fovCircle.Position = UserInputService:GetMouseLocation()
    fovCircle.Visible = Config.DrawFOV and fovVisibleState

    if not LocalPlayer then return end

    for player, drawObjects in pairs(activeESP) do
        local character = drawObjects.Character
        if not character then continue end
        
        local root = character:FindFirstChild("HumanoidRootPart")
        local humanoid = character:FindFirstChild("Humanoid")
        local head = character:FindFirstChild("Head")
        
        if not root or not humanoid or not head then continue end

        if humanoid.Health <= 0 or (Config.TeamCheck and LocalPlayer.Team and player.Team and LocalPlayer.Team == player.Team) then
            drawObjects.Box.Visible = false
            drawObjects.BoxOutline.Visible = false
            drawObjects.Health.Visible = false
            drawObjects.HealthOutline.Visible = false
            drawObjects.Name.Visible = false
            for _, line in ipairs(drawObjects.Skeleton) do line.Visible = false end
            continue
        end

        local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position)

        if onScreen then
            local rayParams = RaycastParams.new()
            rayParams.FilterType = Enum.RaycastFilterType.Exclude
            rayParams.FilterDescendantsInstances = {LocalPlayer.Character, character, Camera}
            
            local direction = head.Position - Camera.CFrame.Position
            local hitResult = Workspace:Raycast(Camera.CFrame.Position, direction, rayParams)
            
            local dynamicColor = hitResult and Color3.new(1, 0, 0) or Color3.new(0, 1, 0)

            local scaleFactor = 1 / (screenPos.Z * math.tan(math.rad(Camera.FieldOfView * 0.5)) * 2) * 1000
            local boxWidth = math.floor(4.5 * scaleFactor)
            local boxHeight = math.floor(6.5 * scaleFactor)
            local posX = math.floor(screenPos.X)
            local posY = math.floor(screenPos.Y)
            
            local renderX = math.floor(posX - boxWidth * 0.5)
            local renderY = math.floor((posY - boxHeight * 0.5) + (0.5 * scaleFactor))

            drawObjects.Box.Position = Vector2.new(renderX, renderY)
            drawObjects.Box.Size = Vector2.new(boxWidth, boxHeight)
            drawObjects.Box.Visible = true
            drawObjects.Box.Color = dynamicColor
            drawObjects.Box.ZIndex = 2
            drawObjects.Box.Thickness = 1

            drawObjects.BoxOutline.Position = Vector2.new(renderX, renderY)
            drawObjects.BoxOutline.Size = Vector2.new(boxWidth, boxHeight)
            drawObjects.BoxOutline.Visible = true
            drawObjects.BoxOutline.Color = Color3.new(0, 0, 0)
            drawObjects.BoxOutline.ZIndex = 1
            drawObjects.BoxOutline.Thickness = 2

            local healthRatio = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)

            drawObjects.HealthOutline.From = Vector2.new(renderX - 5, renderY)
            drawObjects.HealthOutline.To = Vector2.new(renderX - 5, renderY + boxHeight)
            drawObjects.HealthOutline.Color = Color3.new(0, 0, 0)
            drawObjects.HealthOutline.Thickness = 2
            drawObjects.HealthOutline.ZIndex = 1
            drawObjects.HealthOutline.Visible = true

            drawObjects.Health.From = Vector2.new(renderX - 5, (renderY + boxHeight))
            drawObjects.Health.To = Vector2.new(renderX - 5, renderY + (boxHeight * (1 - healthRatio)))
            drawObjects.Health.Color = Color3.new(1, 0, 0):Lerp(Color3.new(0, 1, 0), healthRatio)
            drawObjects.Health.Thickness = 1
            drawObjects.Health.ZIndex = 2
            drawObjects.Health.Visible = true

            drawObjects.Name.Position = Vector2.new(posX, (renderY - drawObjects.Name.TextBounds.Y) - 2)
            drawObjects.Name.Size = math.max(math.min(math.abs(14 * scaleFactor), 14), 13)
            drawObjects.Name.Text = string.format("%s [%dm]", player.Name, math.floor(screenPos.Z))
            drawObjects.Name.Center = true
            drawObjects.Name.Color = Color3.new(1, 1, 1)
            drawObjects.Name.Outline = true
            drawObjects.Name.OutlineColor = Color3.new(0, 0, 0)
            drawObjects.Name.Visible = true

            for idx, bonePair in ipairs(skeletonBones) do
                local node1 = character:FindFirstChild(bonePair[1])
                local node2 = character:FindFirstChild(bonePair[2])
                local line = drawObjects.Skeleton[idx]

                if node1 and node2 and line then
                    local p1, v1 = Camera:WorldToViewportPoint(node1.Position)
                    local p2, v2 = Camera:WorldToViewportPoint(node2.Position)

                    if v1 and v2 then
                        line.From = Vector2.new(p1.X, p1.Y)
                        line.To = Vector2.new(p2.X, p2.Y)
                        line.Color = dynamicColor
                        line.Thickness = 1
                        line.ZIndex = 2
                        line.Visible = true
                    else
                        line.Visible = false
                    end
                elseif line then
                    line.Visible = false
                end
            end
        else
            drawObjects.Box.Visible = false
            drawObjects.BoxOutline.Visible = false
            drawObjects.Health.Visible = false
            drawObjects.HealthOutline.Visible = false
            drawObjects.Name.Visible = false
            for _, line in ipairs(drawObjects.Skeleton) do line.Visible = false end
        end
    end
end)

local originalBulletCast = nil
local originalKnifeCast = nil

local function processRaycast(origin, direction, range, filter, melee)
    local targetNode = getTarget()
    if targetNode then
        local alternateDirection = (targetNode.Position - origin).Unit
        if melee then
            return originalKnifeCast(origin, alternateDirection, range, filter)
        else
            return originalBulletCast(origin, alternateDirection, range, filter)
        end
    end
    
    if melee then
        return originalKnifeCast(origin, direction, range, filter)
    else
        return originalBulletCast(origin, direction, range, filter)
    end
end

local function applyHooks()
    for _, obj in ipairs(getgc(true)) do
        if typeof(obj) == "table" and rawget(obj, "BulletRayCast") and rawget(obj, "KnifeRayCast") then
            if not originalBulletCast then
                originalBulletCast = obj.BulletRayCast
                originalKnifeCast = obj.KnifeRayCast
                
                obj.BulletRayCast = function(a, b, c, d)
                    return processRaycast(a, b, c, d, false)
                end
                obj.KnifeRayCast = function(a, b, c, d)
                    return processRaycast(a, b, c, d, true)
                end
                return true
            end
        end
    end
    return false
end

task.spawn(function()
    local limit = 0
    while limit < 25 and not originalBulletCast do
        if applyHooks() then
            break
        end
        limit = limit + 1
        task.wait(0.6)
    end
end)
