local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ================= SETTINGS =================
local aimRadius = 95
local aimSmoothness = 0.15
local aimStrength = 0.5
local snapFactor = 3.0
local showFOV = true
local aimEnabled = true
local streamMode = false
local espEnabled = false
local partyMembers = {} 

-- 🔥 PARTY CHECK
local function isParty(player)
    return table.find(partyMembers, player.Name) ~= nil
end

-- ================= UI SETUP =================
local gui = Instance.new("ScreenGui")
gui.Name = "PluemLabador_GUI"
gui.ResetOnSpawn = false
gui.Parent = game.CoreGui 

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 260, 0, 520)
frame.Position = UDim2.new(0, 20, 0.5, -260)
frame.BackgroundColor3 = Color3.fromRGB(20,20,20)
frame.BorderSizePixel = 0
Instance.new("UICorner", frame).CornerRadius = UDim.new(0,10)

local titleLabel = Instance.new("TextLabel", frame)
titleLabel.Size = UDim2.new(1, 0, 0, 40)
titleLabel.BackgroundColor3 = Color3.fromRGB(15,15,15)
titleLabel.Text = "ปลื้มลาบาดอHUB"
titleLabel.TextColor3 = Color3.fromRGB(0, 255, 127)
titleLabel.Font = Enum.Font.FredokaOne
titleLabel.TextSize = 22
Instance.new("UICorner", titleLabel).CornerRadius = UDim.new(0, 10)

local partyList = Instance.new("ScrollingFrame", frame)
partyList.Size = UDim2.new(1, -20, 0, 100)
partyList.Position = UDim2.new(0, 10, 0, 400)
partyList.BackgroundColor3 = Color3.fromRGB(30,30,30)
partyList.BorderSizePixel = 0
partyList.Visible = false
Instance.new("UIListLayout", partyList).Padding = UDim.new(0,2)

-- ================= UI FUNCTIONS =================
local function createButton(text, y, cb)
    local b = Instance.new("TextButton", frame)
    b.Size = UDim2.new(1, -20, 0, 28)
    b.Position = UDim2.new(0, 10, 0, y)
    b.Text = text
    b.BackgroundColor3 = Color3.fromRGB(40,40,40)
    b.TextColor3 = Color3.fromRGB(220,220,220)
    b.Font = Enum.Font.SourceSansBold
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
    b.MouseButton1Click:Connect(function() cb(b) end)
end

local function createSlider(name, y, default, min, max, cb)
    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(1, -20, 0, 20)
    label.Position = UDim2.new(0, 10, 0, y)
    label.Text = name .. ": " .. math.floor(default)
    label.TextColor3 = Color3.fromRGB(220,220,220)
    label.BackgroundTransparency = 1
    local bar = Instance.new("Frame", frame)
    bar.Size = UDim2.new(1, -20, 0, 8)
    bar.Position = UDim2.new(0, 10, 0, y + 22)
    bar.BackgroundColor3 = Color3.fromRGB(60,60,60)
    local fill = Instance.new("Frame", bar)
    fill.Size = UDim2.new((default-min)/(max-min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    
    local dragging = false
    bar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end end)
    UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
    UIS.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local x = math.clamp((i.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            local val = min + (x * (max - min))
            fill.Size = UDim2.new(x, 0, 1, 0)
            label.Text = name .. ": " .. math.floor(val)
            cb(val)
        end
    end)
end

-- ================= UI ELEMENTS =================
createButton("AIM: ON", 55, function(b) aimEnabled = not aimEnabled b.Text = "AIM: "..(aimEnabled and "ON" or "OFF") end)
createButton("FOV: ON", 90, function(b) showFOV = not showFOV b.Text = "FOV: "..(showFOV and "ON" or "OFF") end)
createButton("ESP & NAMES: OFF", 125, function(b) espEnabled = not espEnabled b.Text = "ESP & NAMES: "..(espEnabled and "ON" or "OFF") end)
createButton("STREAM MODE: OFF", 160, function(b) streamMode = not streamMode b.Text = "STREAM MODE: "..(streamMode and "ON" or "OFF") gui.Parent = streamMode and LocalPlayer:WaitForChild("PlayerGui") or game.CoreGui end)
createSlider("Aim Strength", 210, aimStrength * 100, 0, 100, function(v) aimStrength = v / 100 end)
createSlider("FOV Size", 260, aimRadius, 0, 500, function(v) aimRadius = v end)

-- แก้ไขส่วน MANAGE PARTY ให้ปุ่มเปลี่ยนสถานะชัดเจน
createButton("MANAGE PARTY", 310, function()
    partyList.Visible = not partyList.Visible
    if not partyList.Visible then return end
    
    for _, child in pairs(partyList:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
    
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local pBtn = Instance.new("TextButton", partyList)
            pBtn.Size = UDim2.new(1, 0, 0, 25)
            Instance.new("UICorner", pBtn).CornerRadius = UDim.new(0, 4)
            
            local function updateBtnStyle()
                local isMember = table.find(partyMembers, p.Name)
                pBtn.BackgroundColor3 = isMember and Color3.fromRGB(0, 120, 60) or Color3.fromRGB(45, 45, 45)
                pBtn.TextColor3 = isMember and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)
                pBtn.Text = p.Name .. (isMember and " [SELECTED]" or "")
            end
            
            updateBtnStyle()
            
            pBtn.MouseButton1Click:Connect(function()
                local idx = table.find(partyMembers, p.Name)
                if idx then 
                    table.remove(partyMembers, idx) 
                else 
                    table.insert(partyMembers, p.Name) 
                end
                updateBtnStyle() -- อัปเดตสีปุ่มทันทีที่กด
            end)
        end
    end
end)

-- ================= ESP =================
local fov = Drawing.new("Circle")
fov.Thickness = 1
fov.Color = Color3.new(1,1,1)

local function createESP(player)
    if player == LocalPlayer then return end

    local highlight = Instance.new("Highlight", game.CoreGui)
    local billboard = Instance.new("BillboardGui", game.CoreGui)
    billboard.Size = UDim2.new(0,200,0,50)
    billboard.AlwaysOnTop = true
    billboard.ExtentsOffset = Vector3.new(0,3,0)

    local nameLabel = Instance.new("TextLabel", billboard)
    nameLabel.Size = UDim2.new(1,0,1,0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.TextSize = 14
    nameLabel.TextStrokeTransparency = 0.6

    RunService.RenderStepped:Connect(function()
        if espEnabled and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            local inParty = isParty(player)

            highlight.Adornee = player.Character
            highlight.Enabled = true
            highlight.FillColor = inParty and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
            highlight.OutlineColor = inParty and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 255, 255)

            billboard.Adornee = player.Character:FindFirstChild("Head")
            billboard.Enabled = true

            nameLabel.TextColor3 = inParty and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 255, 255)
            nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)

            nameLabel.Text = (inParty and "[PARTY] " or "") .. player.Name .. " [" .. math.floor(player.Character.Humanoid.Health) .. "]"
        else
            highlight.Adornee = nil
            highlight.Enabled = false
            billboard.Enabled = false
        end
    end)
end

Players.PlayerAdded:Connect(createESP)
for _, p in pairs(Players:GetPlayers()) do createESP(p) end

-- ================= AIM =================
local function getTarget()
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    local closest, dist = nil, aimRadius

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
            
            if isParty(p) then continue end

            local head = p.Character:FindFirstChild("Head")
            if head then
                local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local rayParams = RaycastParams.new()
                    rayParams.FilterType = Enum.RaycastFilterType.Exclude
                    rayParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}

                    local raycastResult = workspace:Raycast(Camera.CFrame.Position, (head.Position - Camera.CFrame.Position), rayParams)

                    if not raycastResult or raycastResult.Instance:IsDescendantOf(p.Character) then
                        local mag = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                        if mag < dist then dist = mag closest = head end
                    end
                end
            end
        end
    end
    return closest
end

local throttle = 0
RunService.RenderStepped:Connect(function(dt)
    throttle += dt
    if throttle > 0.015 then
        local target = getTarget()
        if aimEnabled and target then
            local lookAt = CFrame.new(Camera.CFrame.Position, target.Position)
            local smoothness = math.clamp(aimSmoothness * aimStrength * 10, 0, 1)
            Camera.CFrame = Camera.CFrame:Lerp(lookAt, smoothness)
        end
        throttle = 0
    end
    fov.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    fov.Radius = aimRadius
    fov.Visible = showFOV and not streamMode
end)

UIS.InputBegan:Connect(function(i, gp)
    if not gp and i.KeyCode == Enum.KeyCode.RightControl then
        frame.Visible = not frame.Visible
    end
end)
