local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- SETTINGS
local aimRadius = 110
local aimSmoothness = 0.5
local showFOV = true
local espEnabled = true
local wallhackEnabled = true -- ในที่นี้คือ Lock ทะลุกำแพง
local aimbotEnabled = true
local streamMode = false

local partyList = {}
local target = nil
local uiVisible = true

-- UI SETUP
local gui = Instance.new("ScreenGui", game.CoreGui)
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 220, 0, 420)
frame.Position = UDim2.new(0, 20, 0.5, -210)
frame.BackgroundColor3 = Color3.fromRGB(20,20,20)

-- HOTKEYS
UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightControl then
        uiVisible = not uiVisible
        frame.Visible = uiVisible
    elseif input.KeyCode == Enum.KeyCode.F5 then
        espEnabled = not espEnabled
    elseif input.KeyCode == Enum.KeyCode.Q then
        aimbotEnabled = not aimbotEnabled
    elseif input.KeyCode == Enum.KeyCode.Z then
        wallhackEnabled = not wallhackEnabled
    end
end)

local function createButton(text, posY, callback)
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(1, -10, 0, 30)
    btn.Position = UDim2.new(0, 5, 0, posY)
    btn.BackgroundColor3 = Color3.fromRGB(40,40,40)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Text = text
    btn.MouseButton1Click:Connect(function() callback(btn) end)
    return btn
end

-- TEXT BOXES (FOV & SMOOTH)
local fovBox = Instance.new("TextBox", frame)
fovBox.Size = UDim2.new(1, -10, 0, 30)
fovBox.Position = UDim2.new(0, 5, 0, 5)
fovBox.Text = tostring(aimRadius)
fovBox.BackgroundColor3 = Color3.fromRGB(30,30,30)
fovBox.TextColor3 = Color3.new(1,1,1)
fovBox.FocusLost:Connect(function() aimRadius = tonumber(fovBox.Text) or aimRadius end)

local smoothBox = Instance.new("TextBox", frame)
smoothBox.Size = UDim2.new(1, -10, 0, 30)
smoothBox.Position = UDim2.new(0, 5, 0, 40)
smoothBox.Text = tostring(aimSmoothness)
smoothBox.BackgroundColor3 = Color3.fromRGB(30,30,30)
smoothBox.TextColor3 = Color3.new(1,1,1)
smoothBox.FocusLost:Connect(function() 
    local num = tonumber(smoothBox.Text)
    if num then aimSmoothness = math.clamp(num, 0.01, 1) end
end)

-- BUTTONS
local aimBtn = createButton("AIMBOT: ON", 75, function(b) aimbotEnabled = not aimbotEnabled end)
local espBtn = createButton("ESP: ON", 110, function(b) espEnabled = not espEnabled end)
local whBtn = createButton("WALLHACK LOCK: ON", 145, function(b) wallhackEnabled = not wallhackEnabled end)
createButton("FOV: ON", 180, function(b) showFOV = not showFOV b.Text = "FOV: "..(showFOV and "ON" or "OFF") end)
createButton("STREAM: OFF", 215, function(b) streamMode = not streamMode b.Text = "STREAM: "..(streamMode and "ON" or "OFF") end)

-- SCROLLING PLAYER LIST
local playerListFrame = Instance.new("ScrollingFrame", frame)
playerListFrame.Size = UDim2.new(1, -10, 0, 150)
playerListFrame.Position = UDim2.new(0, 5, 0, 255)
playerListFrame.BackgroundColor3 = Color3.fromRGB(30,30,30)
playerListFrame.ScrollBarThickness = 4
playerListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y

local layout = Instance.new("UIListLayout", playerListFrame)
layout.SortOrder = Enum.SortOrder.Name

local function refreshPlayerList()
    local currentPlayers = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            currentPlayers[p.Name] = true
            local btn = playerListFrame:FindFirstChild(p.Name)
            if not btn then
                btn = Instance.new("TextButton", playerListFrame)
                btn.Name = p.Name
                btn.Size = UDim2.new(1, 0, 0, 25)
                btn.TextColor3 = Color3.new(1,1,1)
                btn.MouseButton1Click:Connect(function() partyList[p.Name] = not partyList[p.Name] end)
            end
            btn.Text = p.Name
            btn.BackgroundColor3 = partyList[p.Name] and Color3.fromRGB(0,120,0) or Color3.fromRGB(50,50,50)
        end
    end
    for _, v in pairs(playerListFrame:GetChildren()) do
        if v:IsA("TextButton") and not currentPlayers[v.Name] then v:Destroy() end
    end
end

-- Check Line of Sight (ใช้เฉพาะตอนปิด Wallhack)
local function hasLineOfSight(model)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Head") and model:FindFirstChild("Head") then
        local ray = Ray.new(char.Head.Position, (model.Head.Position - char.Head.Position).Unit * 1000)
        local hit = workspace:FindPartOnRayWithIgnoreList(ray, {char, model})
        return hit == nil
    end
    return false
end

local function getClosestTarget()
    local cam = workspace.CurrentCamera
    local center = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)
    local closest, dist = nil, aimRadius

    for _, v in pairs(Players:GetPlayers()) do
        if v ~= LocalPlayer and v.Character and not partyList[v.Name] then
            local char = v.Character
            local head = char:FindFirstChild("Head")
            local hum = char:FindFirstChild("Humanoid")

            if hum and hum.Health > 0 and head then
                local pos, onscreen = cam:WorldToScreenPoint(head.Position)
                if onscreen then
                    -- ถ้าเปิด Wallhack จะข้ามการเช็คสิ่งกีดขวางไปเลย
                    if wallhackEnabled or hasLineOfSight(char) then
                        local d = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                        if d < dist then
                            dist = d
                            closest = char
                        end
                    end
                end
            end
        end
    end
    return closest
end

-- ESP & DRAWING
local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 1
fovCircle.Color = Color3.new(1,1,1)

task.spawn(function()
    while true do
        aimBtn.Text = "AIMBOT: "..(aimbotEnabled and "ON" or "OFF")
        espBtn.Text = "ESP: "..(espEnabled and "ON" or "OFF")
        whBtn.Text = "WALLHACK LOCK: "..(wallhackEnabled and "ON" or "OFF")
        refreshPlayerList()
        
        if espEnabled and not streamMode then
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    local char = p.Character
                    local head = char:FindFirstChild("Head")
                    if head then
                        local highlight = char:FindFirstChild("ESPHighlight") or Instance.new("Highlight", char)
                        highlight.Name = "ESPHighlight"
                        highlight.FillTransparency = 1
                        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        
                        local bill = head:FindFirstChild("NameTag") or Instance.new("BillboardGui", head)
                        bill.Name = "NameTag"
                        bill.Size = UDim2.new(0,80,0,16)
                        bill.StudsOffset = Vector3.new(0,3,0)
                        bill.AlwaysOnTop = true
                        
                        local txt = bill:FindFirstChild("Text") or Instance.new("TextLabel", bill)
                        txt.Name = "Text"
                        txt.Size = UDim2.new(1,0,1,0)
                        txt.BackgroundTransparency = 1
                        txt.Text = p.Name
                        txt.TextStrokeTransparency = 0

                        if partyList[p.Name] then
                            highlight.OutlineColor = Color3.fromRGB(0, 255, 0)
                            txt.TextColor3 = Color3.fromRGB(0, 255, 0)
                        else
                            highlight.OutlineColor = Color3.fromRGB(255, 255, 0)
                            txt.TextColor3 = Color3.fromRGB(255, 255, 255)
                        end
                    end
                end
            end
        else
            for _, p in pairs(Players:GetPlayers()) do
                if p.Character then
                    if p.Character:FindFirstChild("ESPHighlight") then p.Character.ESPHighlight:Destroy() end
                    if p.Character:FindFirstChild("Head") and p.Character.Head:FindFirstChild("NameTag") then p.Character.Head.NameTag:Destroy() end
                end
            end
        end
        task.wait(0.5)
    end
end)

RunService.RenderStepped:Connect(function()
    local cam = workspace.CurrentCamera
    fovCircle.Visible = showFOV and not streamMode
    fovCircle.Radius = aimRadius
    fovCircle.Position = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)

    if aimbotEnabled then
        target = getClosestTarget()
        if target then
            local cf = CFrame.new(cam.CFrame.Position, target.Head.Position)
            cam.CFrame = cam.CFrame:Lerp(cf, aimSmoothness)
        end
    end
end)
