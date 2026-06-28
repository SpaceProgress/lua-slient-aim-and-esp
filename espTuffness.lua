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
    ToggleKey = Enum.KeyCode.H
}

local FovHidden = false
local ESP = {}

local Bones = {
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

local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 2
FOVCircle.NumSides = 100
FOVCircle.Radius = Config.MaxFOV
FOVCircle.Color = Color3.fromRGB(255, 0, 100)
FOVCircle.Transparency = 0.75
FOVCircle.Visible = Config.DrawFOV
FOVCircle.Filled = false

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Config.ToggleKey then
        FovHidden = not FovHidden
    end
end)

local function RemoveESP(player)
    local data = ESP[player]
    if not data then return end

    local drawings = {data.Box, data.BoxOutline, data.Health, data.HealthOutline, data.Name}
    for _, drawing in ipairs(drawings) do
        if drawing then
            pcall(function() drawing:Destroy() end)
        end
    end

    if data.Skeleton then
        for _, line in ipairs(data.Skeleton) do
            if line then
                pcall(function() line:Destroy() end)
            end
        end
    end

    ESP[player] = nil
end

local function AddESP(player)
    if player == LocalPlayer then return end

    local function CharacterSetup(character)
        RemoveESP(player)

        local skeletonLines = {}
        for i = 1, #Bones do
            table.insert(skeletonLines, Drawing.new("Line"))
        end

        ESP[player] = {
            Character = character,
            Box = Drawing.new("Square"),
            BoxOutline = Drawing.new("Square"),
            Health = Drawing.new("Line"),
            HealthOutline = Drawing.new("Line"),
            Name = Drawing.new("Text"),
            Skeleton = skeletonLines
        }
    end

    if player.Character then
        CharacterSetup(player.Character)
    end

    player.CharacterAdded:Connect(CharacterSetup)
    player.CharacterRemoving:Connect(function()
        RemoveESP(player)
    end)
end

for _, player in ipairs(Players:GetPlayers()) do 
    AddESP(player) 
end

Players.PlayerAdded:Connect(AddESP)
Players.PlayerRemoving:Connect(RemoveESP)

local function GetClosestTarget()
    local mousePos = UserInputService:GetMouseLocation()
    local closest, shortest = nil, Config.MaxFOV

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer or not player.Character then continue end
        if Config.TeamCheck and player.Team == LocalPlayer.Team then continue end

        local char = player.Character
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then continue end

        local targetPart = char:FindFirstChild(Config.TargetPart) or char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
        if not targetPart then continue end

        local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
        if not onScreen then continue end

        local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
        if dist < shortest then
            shortest = dist
            closest = targetPart
        end
    end

    return closest
end

RunService.RenderStepped:Connect(function()
    FOVCircle.Position = UserInputService:GetMouseLocation()
    FOVCircle.Visible = Config.DrawFOV and not FovHidden

    if not LocalPlayer then return end

    for player, data in pairs(ESP) do
        local character = data.Character
        
        local function HideData()
            if data.Box then data.Box.Visible = false end
            if data.BoxOutline then data.BoxOutline.Visible = false end
            if data.Health then data.Health.Visible = false end
            if data.HealthOutline then data.HealthOutline.Visible = false end
            if data.Name then data.Name.Visible = false end
            if data.Skeleton then
                for _, line in ipairs(data.Skeleton) do line.Visible = false end
            end
        end

        if not character or not character:IsDescendantOf(Workspace) then 
            HideData()
            continue 
        end
        
        local root = character:FindFirstChild("HumanoidRootPart")
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local head = character:FindFirstChild("Head")
        
        if not root or not humanoid or not head or humanoid.Health <= 0 or (Config.TeamCheck and LocalPlayer.Team and player.Team and LocalPlayer.Team == player.Team) then
            HideData()
            continue
        end

        local pos, visible = Camera:WorldToViewportPoint(root.Position)

        if visible then
            local raycastParams = RaycastParams.new()
            raycastParams.FilterType = Enum.RaycastFilterType.Exclude
            raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, character, Camera}
            
            local rayDirection = head.Position - Camera.CFrame.Position
            local raycastResult = Workspace:Raycast(Camera.CFrame.Position, rayDirection, raycastParams)
            
            local espColor = Color3.fromRGB(52, 235, 113)
            if raycastResult then
                espColor = Color3.fromRGB(235, 64, 52)
            end

            local scale = 1 / (pos.Z * math.tan(math.rad(Camera.FieldOfView * 0.5)) * 2) * 1000
            local width, height = math.floor(4.5 * scale), math.floor(6.5 * scale)
            local x, y = math.floor(pos.X), math.floor(pos.Y)
            local xPosition, yPosition = math.floor(x - width * 0.5), math.floor((y - height * 0.5) + (0.5 * scale))

            data.Box.Position = Vector2.new(xPosition, yPosition)
            data.Box.Size = Vector2.new(width, height)
            data.Box.Visible = true
            data.Box.Color = espColor
            data.Box.ZIndex = 2
            data.Box.Thickness = 1

            data.BoxOutline.Position = Vector2.new(xPosition, yPosition)
            data.BoxOutline.Size = Vector2.new(width, height)
            data.BoxOutline.Visible = true
            data.BoxOutline.Color = Color3.new(0, 0, 0)
            data.BoxOutline.ZIndex = 1
            data.BoxOutline.Thickness = 2

            local healthPercent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)

            data.HealthOutline.From = Vector2.new(xPosition - 5, yPosition)
            data.HealthOutline.To = Vector2.new(xPosition - 5, yPosition + height)
            data.HealthOutline.Color = Color3.new(0, 0, 0)
            data.HealthOutline.Thickness = 2
            data.HealthOutline.ZIndex = 1
            data.HealthOutline.Visible = true

            data.Health.From = Vector2.new(xPosition - 5, (yPosition + height))
            data.Health.To = Vector2.new(xPosition - 5, yPosition + (height * (1 - healthPercent)))
            data.Health.Color = Color3.fromRGB(235, 64, 52):Lerp(Color3.fromRGB(52, 235, 113), healthPercent)
            data.Health.Thickness = 1
            data.Health.ZIndex = 2
            data.Health.Visible = true

            data.Name.Position = Vector2.new(x, (yPosition - data.Name.TextBounds.Y) - 2)
            data.Name.Size = math.max(math.min(math.abs(14 * scale), 14), 13)
            data.Name.Text = player.DisplayName .. " [" .. math.floor(pos.Z) .. "m]"
            data.Name.Center = true
            data.Name.Color = Color3.new(1, 1, 1)
            data.Name.Outline = true
            data.Name.OutlineColor = Color3.new(0, 0, 0)
            data.Name.Visible = true

            for i, bonePair in ipairs(Bones) do
                local part1 = character:FindFirstChild(bonePair[1])
                local part2 = character:FindFirstChild(bonePair[2])
                local line = data.Skeleton[i]

                if part1 and part2 and line then
                    local out1, vis1 = Camera:WorldToViewportPoint(part1.Position)
                    local out2, vis2 = Camera:WorldToViewportPoint(part2.Position)

                    if vis1 and vis2 then
                        line.From = Vector2.new(out1.X, out1.Y)
                        line.To = Vector2.new(out2.X, out2.Y)
                        line.Color = espColor
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
            HideData()
        end
    end
end)

local OldBulletRayCast = nil
local OldKnifeRayCast = nil

local function Redirect(origin, direction, distance, ignoreList, isKnife)
    local target = GetClosestTarget()
    if target then
        local newDirection = (target.Position - origin).Unit
        if isKnife then
            return OldKnifeRayCast(origin, newDirection, distance, ignoreList)
        else
            return OldBulletRayCast(origin, newDirection, distance, ignoreList)
        end
    end

    if isKnife then
        return OldKnifeRayCast(origin, direction, distance, ignoreList)
    else
        return OldBulletRayCast(origin, direction, distance, ignoreList)
    end
end

local function ForceHook()
    for _, v in ipairs(getgc(true)) do
        if typeof(v) == "table" and rawget(v, "BulletRayCast") and rawget(v, "KnifeRayCast") then
            if not OldBulletRayCast then
                OldBulletRayCast = v.BulletRayCast
                OldKnifeRayCast = v.KnifeRayCast
                
                v.BulletRayCast = function(a, b, c, d)
                    return Redirect(a, b, c, d, false)
                end
                
                v.KnifeRayCast = function(a, b, c, d)
                    return Redirect(a, b, c, d, true)
                end
                return true
            end
        end
    end
    return false
end

task.spawn(function()
    local tries = 0
    while tries < 25 and not OldBulletRayCast do
        if ForceHook() then
            break
        end
        tries = tries + 1
        task.wait(0.6)
    end
end)
