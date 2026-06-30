local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = game.workspace.CurrentCamera

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

local function Remove(player)
    local data = ESP[player]
    if not data then
        return
    end

    if data.Box then data.Box:Remove() end
    if data.BoxOutline then data.BoxOutline:Remove() end
    if data.Health then data.Health:Remove() end
    if data.HealthOutline then data.HealthOutline:Remove() end
    if data.Name then data.Name:Remove() end

    if data.Skeleton then
        for _, line in pairs(data.Skeleton) do
            line:Remove()
        end
    end

    ESP[player] = nil
end

local function Add(player)
    if player == Players.LocalPlayer then
        return 
    end

    local function CharacterSetup(character)
        Remove(player)

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
        Remove(player)
    end)
end

for _, player in Players:GetPlayers() do
    Add(player)
end

Players.PlayerAdded:Connect(Add)
Players.PlayerRemoving:Connect(Remove)

RunService.RenderStepped:Connect(function()
    local localPlayer = Players.LocalPlayer
    if not localPlayer then return end

    for player, data in pairs(ESP) do
        local character = data.Character
        if not character then continue end
        
        local root = character:FindFirstChild("HumanoidRootPart")
        local humanoid = character:FindFirstChild("Humanoid")
        local head = character:FindFirstChild("Head")
        if not root or not humanoid or not head then continue end

        if humanoid.Health <= 0 then
            data.Box.Visible = false
            data.BoxOutline.Visible = false
            data.Health.Visible = false
            data.HealthOutline.Visible = false
            data.Name.Visible = false
            for _, line in pairs(data.Skeleton) do line.Visible = false end
            continue
        end

        if localPlayer.Team and player.Team and localPlayer.Team == player.Team then
            data.Box.Visible = false
            data.BoxOutline.Visible = false
            data.Health.Visible = false
            data.HealthOutline.Visible = false
            data.Name.Visible = false
            for _, line in pairs(data.Skeleton) do line.Visible = false end
            continue
        end

        local pos, visible = Camera:WorldToViewportPoint(root.Position)

        if visible then
            local raycastParams = RaycastParams.new()
            raycastParams.FilterType = Enum.RaycastFilterType.Exclude
            raycastParams.FilterDescendantsInstances = {localPlayer.Character, character, Camera}
            
            local rayDirection = head.Position - Camera.CFrame.Position
            local raycastResult = workspace:Raycast(Camera.CFrame.Position, rayDirection, raycastParams)
            
            local espColor = Color3.new(1, 1, 1)
            if raycastResult then
                espColor = Color3.new(1, 0, 0)
            else
                espColor = Color3.new(0, 1, 0)
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
            data.Health.Color = Color3.new(1, 0, 0):Lerp(Color3.new(0, 1, 0), healthPercent)
            data.Health.Thickness = 1
            data.Health.ZIndex = 2
            data.Health.Visible = true

            data.Name.Position = Vector2.new(x, (yPosition - data.Name.TextBounds.Y) - 2)
            data.Name.Size = math.max(math.min(math.abs(14 * scale), 14), 13)
            data.Name.Text = player.Name .. " [" .. math.floor(pos.Z) .. "m]"
            data.Name.Center = true
            data.Name.Color = Color3.new(1, 1, 1)
            data.Name.Outline = true
            data.Name.OutlineColor = Color3.new(0, 0, 0)
            data.Name.Visible = true

            for i, bonePair do
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
            data.Box.Visible = false
            data.BoxOutline.Visible = false
            data.Health.Visible = false
            data.HealthOutline.Visible = false
            data.Name.Visible = false
            for _, line in pairs(data.Skeleton) do line.Visible = false end
        end
    end
end)