local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

if CoreGui:FindFirstChild("Tutorial") then
    CoreGui.Tutorial:Destroy()
end

local UI = Instance.new("ScreenGui")
UI.Name = "Tutorial"
UI.Parent = CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 550, 0, 350)
MainFrame.Position = UDim2.new(0.5, -275, 0.5, -175)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = UI

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 40)
TopBar.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local TopBarCorner = Instance.new("UICorner")
TopBarCorner.CornerRadius = UDim.new(0, 8)
TopBarCorner.Parent = TopBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -20, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Tutorial"
Title.TextColor3 = Color3.fromRGB(240, 240, 240)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 130, 1, -40)
Sidebar.Position = UDim2.new(0, 0, 0, 40)
Sidebar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainFrame

local SidebarCorner = Instance.new("UICorner")
SidebarCorner.CornerRadius = UDim.new(0, 8)
SidebarCorner.Parent = Sidebar

local Container = Instance.new("Frame")
Container.Size = UDim2.new(1, -140, 1, -50)
Container.Position = UDim2.new(0, 135, 0, 45)
Container.BackgroundTransparency = 1
Container.Parent = MainFrame

local Tabs = {
    Main = Instance.new("ScrollingFrame"),
    Scripts = Instance.new("ScrollingFrame")
}

local TabButtons = {}

local UIListLayoutSidebar = Instance.new("UIListLayout")
UIListLayoutSidebar.Padding = UDim.new(0, 5)
UIListLayoutSidebar.Parent = Sidebar

local UIPaddingSidebar = Instance.new("UIPadding")
UIPaddingSidebar.PaddingTop = UDim.new(0, 10)
UIPaddingSidebar.PaddingLeft = UDim.new(0, 10)
UIPaddingSidebar.Parent = Sidebar

local function CreateTab(name, id)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, -10, 0, 32)
    Button.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Button
