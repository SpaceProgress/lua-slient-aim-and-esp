local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = game.workspace.CurrentCamera

local ESP = {}

local function Add(player)
    if player == Players.LocalPlayer then
        return 
    end

    ESP[player] = {
        Character = player.Character,
        Box = Drawing.new("Square"),
        BoxOutline = Drawing.new("Square"),
        Health = Drawing.new("Line"),
        HealthOutline = Drawing.new("Line"),
        Name = Drawing.new("Text"),
    }

    player.CharacterAdded:Connect(function(character)
        if ESP[player] then
            ESP[player].Character = character
        end
    end)

    player.CharacterRemoving:Connect(function()
        if ESP[player] then
            ESP[player].Character = nil
        end
    end)
end

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

    ESP[player] = nil
end

for _, player in Players:GetPlayers() do
    Add(player)
end

Players.PlayerAdded:Connect(Add)
Players.PlayerRemoving:Connect(Remove)

RunService.RenderStepped:Connect(function()
    for player, data in pairs(ESP) do
        local character = data.Character

        if not character then
            continue
        end
        
        local root = character:FindFirstChild("HumanoidRootPart")
        if not root then
            continue
        end

        local humanoid = character:FindFirstChild("Humanoid")
        if not humanoid then
            continue
        end

        local pos, visible = Camera:WorldToViewportPoint(root.Position)

        if visible then
            local scale = 1 / (pos.Z * math.tan(math.rad(Camera.FieldOfView * 0.5)) * 2) * 1000
            local width, height = math.floor(4.5 * scale), math.floor(6.5 * scale)
            local x, y = math.floor(pos.X), math.floor(pos.Y)
            local xPosition, yPosition = math.floor(x - width * 0.5), math.floor((y - height * 0.5) + (0.5 * scale))

            data.Box.Position = Vector2.new(xPosition, yPosition)
            data.Box.Size = Vector2.new(width, height)
            data.Box.Visible = true
            data.Box.Color = Color3.new(1, 1, 1)
            data.Box.ZIndex = 2
            data.Box.Thickness = 1

            data.BoxOutline.Position = Vector2.new(xPosition, yPosition)
            data.BoxOutline.Size = Vector2.new(width, height)
            data.BoxOutline.Visible = true
            data.BoxOutline.Color = Color3.new(0, 0, 0)
            data.BoxOutline.ZIndex = 1
            data.BoxOutline.Thickness = 2

            local healthPercent = 100 / (humanoid.MaxHealth / humanoid.Health)

            data.HealthOutline.From = Vector2.new(xPosition - 3, yPosition)
            data.HealthOutline.To = Vector2.new(xPosition - 3, yPosition + height)
            data.HealthOutline.Color = Color3.new(0, 0, 0)
            data.HealthOutline.Thickness = 2
            data.HealthOutline.ZIndex = 1
            data.HealthOutline.Visible = true

            data.Health.From = Vector2.new(xPosition - 3, (yPosition + height) - 1)
            data.Health.To = Vector2.new(xPosition - 3, ((data.Health.From.Y - ((height / 100) * healthPercent))) + 2)
            data.Health.Color = Color3.new(1, 0, 0):Lerp(Color3.new(0, 1, 0), healthPercent * 0.01)
            data.Health.Thickness = 1
            data.Health.ZIndex = 2
            data.Health.Visible = true

            data.Name.Position = Vector2.new(x, (yPosition - data.Name.TextBounds.Y) - 2)
            data.Name.Size = math.max(math.min(math.abs(14 * scale), 14), 13)
            data.Name.Text = player.Name
            data.Name.Center = true
            data.Name.Color = Color3.new(1, 1, 1)
            data.Name.Outline = true
            data.Name.OutlineColor = Color3.new(0, 0, 0)
            data.Name.Visible = true
        else
            data.Box.Visible = false
            data.BoxOutline.Visible = false
            data.Health.Visible = false
            data.HealthOutline.Visible = false
            data.Name.Visible = false
        end
    end
end)