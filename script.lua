local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- SETTINGS
local aimRadius = 95
local aimSmoothness = 0.5
local showFOV = true
local espEnabled = true
local aimbotEnabled = true
local streamMode = false

local partyList = {}
local target = nil
local uiVisible = true

-- UI
local gui = Instance.new("ScreenGui", game.CoreGui)

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 220, 0, 380)
frame.Position = UDim2.new(0, 20, 0.5, -190)
frame.BackgroundColor3 = Color3.fromRGB(20,20,20)

UIS.InputBegan:Connect(function(input, gp)
    if gp then return end

    -- 🎮 Ctrl ขวา เปิด/ปิด UI
    if input.KeyCode == Enum.KeyCode.RightControl then
        uiVisible = not uiVisible
        frame.Visible = uiVisible
    end

    -- 🔥 F5 เปิด/ปิด ESP
    if input.KeyCode == Enum.KeyCode.F5 then
        espEnabled = not espEnabled
        print("ESP:", espEnabled and "ON" or "OFF")
    end

    -- 🔥 F6 เปิด/ปิด AIMBOT
    if input.KeyCode == Enum.KeyCode.F6 then
        aimbotEnabled = not aimbotEnabled
        print("AIMBOT:", aimbotEnabled and "ON" or "OFF")
    end
end)

local function createButton(text, posY, callback)
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(1, -10, 0, 30)
    btn.Position = UDim2.new(0, 5, 0, posY)
    btn.Text = text
    btn.BackgroundColor3 = Color3.fromRGB(40,40,40)
    btn.TextColor3 = Color3.new(1,1,1)

    btn.MouseButton1Click:Connect(function()
        callback(btn)
    end)
end

-- FOV BOX
local fovBox = Instance.new("TextBox", frame)
fovBox.Size = UDim2.new(1, -10, 0, 30)
fovBox.Position = UDim2.new(0, 5, 0, 5)
fovBox.Text = tostring(aimRadius)

fovBox.FocusLost:Connect(function()
    local num = tonumber(fovBox.Text)
    if num then aimRadius = num end
end)

-- SMOOTH BOX
local smoothBox = Instance.new("TextBox", frame)
smoothBox.Size = UDim2.new(1, -10, 0, 30)
smoothBox.Position = UDim2.new(0, 5, 0, 40)
smoothBox.Text = tostring(aimSmoothness)

smoothBox.FocusLost:Connect(function()
    local num = tonumber(smoothBox.Text)
    if num then aimSmoothness = math.clamp(num,0.01,1) end
end)

-- BUTTONS
createButton("AIMBOT: ON", 75, function(btn)
    aimbotEnabled = not aimbotEnabled
    btn.Text = "AIMBOT: "..(aimbotEnabled and "ON" or "OFF")
end)

createButton("ESP: ON", 110, function(btn)
    espEnabled = not espEnabled
    btn.Text = "ESP: "..(espEnabled and "ON" or "OFF")
end)

createButton("FOV: ON", 145, function(btn)
    showFOV = not showFOV
    btn.Text = "FOV: "..(showFOV and "ON" or "OFF")
end)

createButton("STREAM: OFF", 180, function(btn)
    streamMode = not streamMode
    btn.Text = "STREAM: "..(streamMode and "ON" or "OFF")
end)

-- PLAYER LIST
local playerListFrame = Instance.new("Frame", frame)
playerListFrame.Size = UDim2.new(1, -10, 0, 150)
playerListFrame.Position = UDim2.new(0, 5, 0, 220)
playerListFrame.BackgroundColor3 = Color3.fromRGB(30,30,30)

local layout = Instance.new("UIListLayout", playerListFrame)

local function refreshPlayerList()
    for _,v in pairs(playerListFrame:GetChildren()) do
        if v:IsA("TextButton") then
            v:Destroy()
        end
    end

    for _,p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local btn = Instance.new("TextButton", playerListFrame)
            btn.Size = UDim2.new(1, 0, 0, 25)
            btn.Text = p.Name

            if partyList[p.Name] then
                btn.BackgroundColor3 = Color3.fromRGB(0,120,0)
            else
                btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
            end

            btn.TextColor3 = Color3.new(1,1,1)

            btn.MouseButton1Click:Connect(function()
                if partyList[p.Name] then
                    partyList[p.Name] = nil
                else
                    partyList[p.Name] = true
                end
            end)
        end
    end
end

task.spawn(function()
    while true do
        refreshPlayerList()
        task.wait(2)
    end
end)

-- FOV
local fovCircle = Drawing.new("Circle")
fovCircle.Color = Color3.new(1,1,1)
fovCircle.Thickness = 1
fovCircle.Filled = false

-- LOS
local function hasLineOfSight(model)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Head") and model:FindFirstChild("Head") then
        local ray = Ray.new(char.Head.Position, (model.Head.Position - char.Head.Position))
        local hit = workspace:FindPartOnRayWithIgnoreList(ray, {char, model})
        return hit == nil
    end
    return false
end

-- TARGET
local function getClosestTarget()
    local cam = workspace.CurrentCamera
    local center = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)
    local closest, dist = nil, aimRadius

    for _,v in pairs(Players:GetPlayers()) do
        if v ~= LocalPlayer and v.Character then
            local char = v.Character
            local hum = char:FindFirstChild("Humanoid")
            local head = char:FindFirstChild("Head")

            if hum and hum.Health > 0 and head and not partyList[v.Name] then
                local pos, onscreen = cam:WorldToScreenPoint(head.Position)
                if onscreen then
                    local d = (Vector2.new(pos.X,pos.Y)-center).Magnitude
                    if d < dist then
                        dist = d
                        closest = char
                    end
                end
            end
        end
    end
    return closest
end

-- AIM
local function aimAt(t)
    local cam = workspace.CurrentCamera
    local cf = CFrame.new(cam.CFrame.Position, t.Head.Position)
    cam.CFrame = cam.CFrame:Lerp(cf, aimSmoothness)
end

-- ESP LOOP
task.spawn(function()
    while true do
        if espEnabled and not streamMode then
            for _,p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    local char = p.Character
                    local hum = char:FindFirstChild("Humanoid")
                    local head = char:FindFirstChild("Head")

                    if hum and hum.Health > 0 and head then
                        local highlight = char:FindFirstChild("ESPHighlight")
                        if not highlight then
                            highlight = Instance.new("Highlight", char)
                            highlight.Name = "ESPHighlight"
                            highlight.FillTransparency = 1
                            highlight.OutlineTransparency = 0.4
                        end

                        if partyList[p.Name] then
                            highlight.OutlineColor = Color3.fromRGB(0,255,0)
                        else
                            highlight.OutlineColor = Color3.fromRGB(255,255,0)
                        end

                        if not head:FindFirstChild("NameTag") then
                            local bill = Instance.new("BillboardGui", head)
                            bill.Name = "NameTag"
                            bill.Size = UDim2.new(0,80,0,16)
                            bill.StudsOffset = Vector3.new(0,3,0)
                            bill.AlwaysOnTop = true

                            local txt = Instance.new("TextLabel", bill)
                            txt.Size = UDim2.new(1,0,1,0)
                            txt.BackgroundTransparency = 1
                            txt.TextScaled = false
                            txt.TextSize = 12
                            txt.Font = Enum.Font.SourceSansBold
                            txt.Name = "Text"
                        end

                        local txt = head.NameTag.Text
                        txt.Text = p.Name

                        -- 🔥 ตรงที่มึงต้องการ
                        if partyList[p.Name] then
                            txt.TextColor3 = Color3.fromRGB(0,255,0)
                            txt.TextStrokeTransparency = 0
                        else
                            txt.TextColor3 = Color3.fromRGB(255,255,255)
                            txt.TextStrokeTransparency = 0
                        end
                    end
                end
            end
        else
            for _,p in pairs(Players:GetPlayers()) do
                if p.Character then
                    local h = p.Character:FindFirstChild("ESPHighlight")
                    if h then h:Destroy() end

                    local head = p.Character:FindFirstChild("Head")
                    if head and head:FindFirstChild("NameTag") then
                        head.NameTag:Destroy()
                    end
                end
            end
        end
        task.wait(0.15)
    end
end)

-- MAIN LOOP
RunService.RenderStepped:Connect(function()
    local cam = workspace.CurrentCamera

    fovCircle.Radius = aimRadius
    fovCircle.Position = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)
    fovCircle.Visible = showFOV and not streamMode

    if aimbotEnabled then
        target = getClosestTarget()
        if target and hasLineOfSight(target) then
            aimAt(target)
        end
    end
end)
