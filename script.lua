local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ================= SETTINGS =================
local aimRadius = 95
local aimStrength = 0.5 
local showFOV = true
local aimEnabled = true
local espEnabled = false
local partyMembers = {} 

local function isParty(player)
    return table.find(partyMembers, player.Name) ~= nil
end

-- ================= UI SETUP =================
local gui = Instance.new("ScreenGui")
gui.Name = "PluemLabador_ProHUB"
gui.ResetOnSpawn = false
gui.Parent = game.CoreGui 

local mobileBtn = nil
if UIS.TouchEnabled then
    mobileBtn = Instance.new("TextButton", gui)
    mobileBtn.Size = UDim2.new(0, 50, 0, 50)
    mobileBtn.Position = UDim2.new(0, 10, 0.5, -25)
    mobileBtn.Text = "P"
    mobileBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    mobileBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    mobileBtn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", mobileBtn).CornerRadius = UDim.new(1, 0)
    Instance.new("UIStroke", mobileBtn).Color = Color3.fromRGB(255, 255, 255)
end

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 260, 0, 500)
frame.Position = UDim2.new(0, 70, 0.5, -250)
frame.BackgroundColor3 = Color3.fromRGB(10, 15, 25)
frame.BorderSizePixel = 0
frame.ClipsDescendants = true
frame.Visible = true 
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)
Instance.new("UIStroke", frame).Color = Color3.fromRGB(0, 170, 255)

-- UI Drag Logic
local dragging, dragStart, startPos
frame.InputBegan:Connect(function(input)
    if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and input.Target == frame then
        dragging = true dragStart = input.Position startPos = frame.Position
    end
end)
UIS.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UIS.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end end)

local isOpen = true
local function toggleUI()
    isOpen = not isOpen
    TweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Back), {Size = isOpen and UDim2.new(0, 260, 0, 500) or UDim2.new(0, 260, 0, 0)}):Play()
    task.wait(0.4)
    frame.Visible = isOpen
end

if mobileBtn then mobileBtn.MouseButton1Click:Connect(toggleUI) end
UIS.InputBegan:Connect(function(i, gp) if not gp and i.KeyCode == Enum.KeyCode.RightControl then toggleUI() end end)

-- Title
local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 45)
title.Text = "PLUEM LABADOR HUB"
title.TextColor3 = Color3.fromRGB(0, 200, 255)
title.Font = Enum.Font.GothamBlack
title.TextSize = 20
title.BackgroundTransparency = 1
title.TextStrokeTransparency = 0.5

-- Helper Functions
local function createButton(text, y, cb)
    local b = Instance.new("TextButton", frame)
    b.Size = UDim2.new(1, -20, 0, 32)
    b.Position = UDim2.new(0, 10, 0, y)
    b.Text = text
    b.BackgroundColor3 = Color3.fromRGB(20, 35, 60)
    b.TextColor3 = Color3.fromRGB(200, 230, 255)
    b.Font = Enum.Font.GothamBold
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    b.MouseButton1Click:Connect(function() cb(b) end)
    return b
end

local function createSlider(name, y, default, min, max, cb)
    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(1, -20, 0, 20)
    label.Position = UDim2.new(0, 10, 0, y)
    label.Text = name .. ": " .. math.floor(default)
    label.TextColor3 = Color3.fromRGB(200, 230, 255)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    
    local bar = Instance.new("Frame", frame)
    bar.Size = UDim2.new(1, -20, 0, 6)
    bar.Position = UDim2.new(0, 10, 0, y + 22)
    bar.BackgroundColor3 = Color3.fromRGB(30, 45, 70)
    local fill = Instance.new("Frame", bar)
    fill.Size = UDim2.new((default-min)/(max-min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    
    local sliding = false
    bar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then sliding = true end end)
    UIS.InputChanged:Connect(function(i) 
        if sliding and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local x = math.clamp((i.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            fill.Size = UDim2.new(x, 0, 1, 0)
            local val = min + (x * (max - min))
            label.Text = name .. ": " .. math.floor(val)
            cb(val)
        end
    end)
    UIS.InputEnded:Connect(function() sliding = false end)
end

-- UI Elements
createButton("AIM: ON", 55, function(b) aimEnabled = not aimEnabled b.Text = "AIM: "..(aimEnabled and "ON" or "OFF") end)
createButton("FOV CIRCLE: ON", 95, function(b) showFOV = not showFOV b.Text = "FOV CIRCLE: "..(showFOV and "ON" or "OFF") end)
createButton("ESP: OFF", 135, function(b) espEnabled = not espEnabled b.Text = "ESP: "..(espEnabled and "ON" or "OFF") end)
createSlider("Aim Smoothness", 185, aimStrength * 100, 1, 100, function(v) aimStrength = v / 100 end)
createSlider("FOV Radius", 235, aimRadius, 10, 500, function(v) aimRadius = v end)

-- Party System
local partyFrame = Instance.new("ScrollingFrame", frame)
partyFrame.Size = UDim2.new(1, -20, 0, 120)
partyFrame.Position = UDim2.new(0, 10, 0, 320)
partyFrame.BackgroundColor3 = Color3.fromRGB(15, 25, 40)
partyFrame.BorderSizePixel = 0
Instance.new("UIListLayout", partyFrame).Padding = UDim.new(0, 4)

createButton("REFRESH PARTY LIST", 285, function()
    for _, v in pairs(partyFrame:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local pBtn = Instance.new("TextButton", partyFrame)
            pBtn.Size = UDim2.new(1, 0, 0, 25)
            pBtn.BackgroundColor3 = isParty(p) and Color3.fromRGB(50, 205, 50) or Color3.fromRGB(40, 55, 80)
            pBtn.Text = p.Name
            pBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            Instance.new("UICorner", pBtn).CornerRadius = UDim.new(0, 4)
            pBtn.MouseButton1Click:Connect(function()
                local idx = table.find(partyMembers, p.Name)
                if idx then table.remove(partyMembers, idx) else table.insert(partyMembers, p.Name) end
                pBtn.BackgroundColor3 = isParty(p) and Color3.fromRGB(50, 205, 50) or Color3.fromRGB(40, 55, 80)
            end)
        end
    end
end)

-- ================= ESP & AIM Logic =================
local fov = Drawing.new("Circle")
fov.Thickness = 1
fov.Color = Color3.new(1,1,1)

local function createESP(player)
    if player == LocalPlayer then return end
    local highlight = Instance.new("Highlight", game.CoreGui)
    local billboard = Instance.new("BillboardGui", game.CoreGui)
    billboard.Size = UDim2.new(0,200,0,50)
    billboard.AlwaysOnTop = true
    billboard.ExtentsOffset = Vector3.new(0, 4, 0)
    
    local nameLabel = Instance.new("TextLabel", billboard)
    nameLabel.Size = UDim2.new(1,0,1,0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextStrokeColor3 = Color3.new(0,0,0)
    
    RunService.RenderStepped:Connect(function()
        if espEnabled and player.Character and player.Character:FindFirstChild("Head") then
            local inParty = isParty(player)
            highlight.Adornee = player.Character
            highlight.Enabled = true
            
            -- ปรับสีเขียว/แดง และลดความเข้ม (FillTransparency 0.6)
            highlight.FillColor = inParty and Color3.fromRGB(50, 205, 50) or Color3.fromRGB(220, 20, 60)
            highlight.FillTransparency = 0.6
            
            billboard.Adornee = player.Character.Head
            billboard.Enabled = true
            nameLabel.TextColor3 = inParty and Color3.fromRGB(50, 205, 50) or Color3.fromRGB(255, 255, 255)
            nameLabel.Text = (inParty and "[PARTY] " or "") .. player.Name
        else
            highlight.Enabled = false billboard.Enabled = false
        end
    end)
end

for _, p in pairs(Players:GetPlayers()) do createESP(p) end
Players.PlayerAdded:Connect(createESP)

local function getTarget()
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    local closest, dist = nil, aimRadius
    local myChar = LocalPlayer.Character
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 and not isParty(p) then
            local part = p.Character:FindFirstChild("Head") or p.Character:FindFirstChild("HumanoidRootPart")
            if part then
                local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local res = workspace:Raycast(Camera.CFrame.Position, (part.Position - Camera.CFrame.Position), RaycastParams.new())
                    local canLock = not res or res.Instance:IsDescendantOf(p.Character) or res.Instance:FindFirstAncestorWhichIsA("VehicleSeat")
                    if canLock then local mag = (Vector2.new(pos.X, pos.Y) - center).Magnitude if mag < dist then dist = mag closest = part end end
                end
            end
        end
    end
    return closest
end

RunService.RenderStepped:Connect(function()
    fov.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    fov.Radius = aimRadius
    fov.Visible = showFOV
    if aimEnabled then local t = getTarget() if t then Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, t.Position), aimStrength) end end
end)
