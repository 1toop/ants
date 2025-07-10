local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local VIM = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local plr = Players.LocalPlayer

local gui = Instance.new("ScreenGui", plr:WaitForChild("PlayerGui"))
gui.ResetOnSpawn = false
gui.Name = "RecorderGUI"

local rep = game:GetService("ReplicatedStorage")
local evt = rep:WaitForChild("Events", 9e9):WaitForChild("Server_Event", 9e9)
local args1 = {[1] = "UseTool"; [2] = 1}
local args2 = {[1] = "UseTool"; [2] = 2}
local interval = 1/70

local autoDigRunning = true
local macroPlaybackRunning = false
local tokenCollectionRunning = true

task.spawn(function()
    while true do
        if autoDigRunning and evt and evt.FireServer then
            pcall(function()
                evt:FireServer(unpack(args2))
            end)
            task.wait(interval)
            pcall(function()
                evt:FireServer(unpack(args1))
            end)
            task.wait(interval)
        else
            task.wait(0.1)
        end
    end
end)

local function createButton(text, position, size, parent, color)
    local button = Instance.new("TextButton")
    button.Size = size or UDim2.new(1, -20, 0, 30)
    button.Position = position or UDim2.new(0, 10, 0, 10)
    button.Text = text
    button.BackgroundColor3 = color or Color3.fromRGB(70, 70, 70)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextScaled = true
    button.Font = Enum.Font.SourceSansBold
    button.BorderSizePixel = 0
    button.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = button
    
    button.MouseEnter:Connect(function()
        local tween = TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(90, 90, 90)})
        tween:Play()
    end)
    
    button.MouseLeave:Connect(function()
        local tween = TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = color or Color3.fromRGB(70, 70, 70)})
        tween:Play()
    end)
    
    return button
end

local window = Instance.new("Frame")
window.Size = UDim2.new(0, 350, 0, 380)
window.Position = UDim2.new(0, 10, 0, 10)
window.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
window.Active = true
window.Draggable = true
window.Parent = gui

local macroPath = "AntsMacro.json"
local collectedPath = "CollectedTokens.json"

local collectedSet = {}
if isfile and isfile(collectedPath) then
    local ok, dat = pcall(readfile, collectedPath)
    if ok then
        local suc, arr = pcall(HttpService.JSONDecode, HttpService, dat)
        if suc and typeof(arr) == "table" then
            for _, name in ipairs(arr) do 
                collectedSet[name] = true 
            end
        end
    end
end

local windowCorner = Instance.new("UICorner")
windowCorner.CornerRadius = UDim.new(0, 12)
windowCorner.Parent = window

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 35)
title.Position = UDim2.new(0, 0, 0, 0)
title.Text = "натро макро"
title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextScaled = true
title.Font = Enum.Font.SourceSansBold
title.BorderSizePixel = 0
title.Parent = window

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = title

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 25)
statusLabel.Position = UDim2.new(0, 10, 0, 45)
statusLabel.Text = "Status: Ready"
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
statusLabel.TextScaled = true
statusLabel.Font = Enum.Font.SourceSans
statusLabel.Parent = window

local recBtn = createButton("Start Recording", UDim2.new(0, 15, 0, 80), UDim2.new(0, 155, 0, 35), window, Color3.fromRGB(220, 50, 50))
local playBtn = createButton("Play", UDim2.new(0, 180, 0, 80), UDim2.new(0, 155, 0, 35), window, Color3.fromRGB(50, 150, 50))
local loopBtn = createButton("Loop: OFF", UDim2.new(0, 15, 0, 125), UDim2.new(0, 155, 0, 35), window, Color3.fromRGB(50, 100, 200))
local stopMacroBtn = createButton("Stop Macro", UDim2.new(0, 180, 0, 125), UDim2.new(0, 155, 0, 35), window, Color3.fromRGB(200, 50, 50))

local autoDigBtn = createButton("AutoDig: ON", UDim2.new(0, 15, 0, 170), UDim2.new(0, 155, 0, 35), window, Color3.fromRGB(50, 200, 50))
local tokenBtn = createButton("Token Collection: ON", UDim2.new(0, 180, 0, 170), UDim2.new(0, 155, 0, 35), window, Color3.fromRGB(50, 200, 50))

local stopAfter = 0
local tokenRadius = 0
local suspendFrames = false

local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(1, -20, 0, 25)
infoLabel.Position = UDim2.new(0, 10, 0, 215)
infoLabel.Text = "Frames: 0 | Duration: 0s"
infoLabel.BackgroundTransparency = 1
infoLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
infoLabel.TextScaled = true
infoLabel.Font = Enum.Font.SourceSans
infoLabel.Parent = window

local stopBox = Instance.new("TextBox")
stopBox.Size = UDim2.new(0, 320, 0, 25)
stopBox.Position = UDim2.new(0, 15, 0, 245)
stopBox.PlaceholderText = "Stop collecting tokens after (seconds) - 0 = never"
stopBox.Text = "0"
stopBox.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
stopBox.TextColor3 = Color3.fromRGB(255, 255, 255)
stopBox.TextScaled = true
stopBox.Font = Enum.Font.SourceSans
stopBox.BorderSizePixel = 0
stopBox.Parent = window

local stopBoxCorner = Instance.new("UICorner")
stopBoxCorner.CornerRadius = UDim.new(0, 4)
stopBoxCorner.Parent = stopBox

local radiusBox = Instance.new("TextBox")
radiusBox.Size = UDim2.new(0, 320, 0, 25)
radiusBox.Position = UDim2.new(0, 15, 0, 275)
radiusBox.PlaceholderText = "Token collection radius (studs) - 0 = infinite"
radiusBox.Text = tostring(tokenRadius)
radiusBox.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
radiusBox.TextColor3 = Color3.fromRGB(255, 255, 255)
radiusBox.TextScaled = true
radiusBox.Font = Enum.Font.SourceSans
radiusBox.BorderSizePixel = 0
radiusBox.Parent = window

local radiusBoxCorner = Instance.new("UICorner")
radiusBoxCorner.CornerRadius = UDim.new(0, 4)
radiusBoxCorner.Parent = radiusBox

local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(1, -20, 0, 25)
speedLabel.Position = UDim2.new(0, 10, 0, 305)
speedLabel.Text = "AutoSpeed: 70"
speedLabel.BackgroundTransparency = 1
speedLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
speedLabel.TextScaled = true
speedLabel.Font = Enum.Font.SourceSans
speedLabel.Parent = window

local speedBox = Instance.new("TextBox")
speedBox.Size = UDim2.new(0, 320, 0, 25)
speedBox.Position = UDim2.new(0, 15, 0, 330)
speedBox.PlaceholderText = "Walk speed (default: 70)"
speedBox.Text = "70"
speedBox.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
speedBox.TextColor3 = Color3.fromRGB(255, 255, 255)
speedBox.TextScaled = true
speedBox.Font = Enum.Font.SourceSans
speedBox.BorderSizePixel = 0
speedBox.Parent = window

local speedBoxCorner = Instance.new("UICorner")
speedBoxCorner.CornerRadius = UDim.new(0, 4)
speedBoxCorner.Parent = speedBox

stopBox.FocusLost:Connect(function()
    local v = tonumber(stopBox.Text)
    if v and v >= 0 then
        stopAfter = v
    else
        stopAfter = 0
    end
    stopBox.Text = tostring(stopAfter)
end)

radiusBox.FocusLost:Connect(function()
    local v = tonumber(radiusBox.Text)
    if v and v >= 0 then 
        tokenRadius = v 
    else 
        tokenRadius = 0 
    end
    radiusBox.Text = tostring(tokenRadius)
end)

local walkSpeed = 70
speedBox.FocusLost:Connect(function()
    local v = tonumber(speedBox.Text)
    if v and v > 0 then
        walkSpeed = v
    else
        walkSpeed = 70
    end
    speedBox.Text = tostring(walkSpeed)
    speedLabel.Text = "AutoSpeed: " .. walkSpeed
end)

local log = {}
local recording = false
local conn
local start = 0
local loopPlayback = false
local connPlay = nil
local playStartTick = 0

local function updateUI()
    if recording then
        recBtn.Text = "Stop Recording"
        recBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
        statusLabel.Text = "Status: Recording..."
        statusLabel.TextColor3 = Color3.fromRGB(220, 50, 50)
    else
        recBtn.Text = "Start Recording"
        recBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
        if not macroPlaybackRunning then
            statusLabel.Text = "Status: Ready"
            statusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        end
    end
    
    local duration = #log > 0 and log[#log].t or 0
    infoLabel.Text = string.format("Frames: %d | Duration: %.1fs", #log, duration)
    
    playBtn.BackgroundColor3 = (#log > 0 and not recording) and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(100, 100, 100)
    stopMacroBtn.BackgroundColor3 = macroPlaybackRunning and Color3.fromRGB(200, 50, 50) or Color3.fromRGB(100, 100, 100)
    
    autoDigBtn.Text = autoDigRunning and "AutoDig: ON" or "AutoDig: OFF"
    autoDigBtn.BackgroundColor3 = autoDigRunning and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
    
    tokenBtn.Text = tokenCollectionRunning and "Token Collection: ON" or "Token Collection: OFF"
    tokenBtn.BackgroundColor3 = tokenCollectionRunning and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
end

autoDigBtn.MouseButton1Click:Connect(function()
    autoDigRunning = not autoDigRunning
    updateUI()
end)

tokenBtn.MouseButton1Click:Connect(function()
    tokenCollectionRunning = not tokenCollectionRunning
    updateUI()
end)

stopMacroBtn.MouseButton1Click:Connect(function()
    if not macroPlaybackRunning then return end
    
    macroPlaybackRunning = false
    
    if connPlay then
        connPlay:Disconnect()
        connPlay = nil
    end
    
    statusLabel.Text = "Status: Macro Stopped"
    statusLabel.TextColor3 = Color3.fromRGB(200, 50, 50)
    updateUI()
    
    task.wait(1)
    if not recording and not macroPlaybackRunning then
        statusLabel.Text = "Status: Ready"
        statusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    end
end)

recBtn.MouseButton1Click:Connect(function()
    if recording then
        recording = false
        if conn then 
            conn:Disconnect() 
            conn = nil
        end
        updateUI()
        return
    end
    
    log = {}
    start = tick()
    recording = true
    updateUI()
    
    local char = plr.Character or plr.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    
    conn = RunService.RenderStepped:Connect(function()
        if not recording then return end
        
        pcall(function()
            log[#log + 1] = {
                t = tick() - start,
                kind = "frame",
                pos = hrp.CFrame,
                cam = workspace.CurrentCamera.CFrame
            }
            
            if #log % 30 == 0 then
                updateUI()
            end
        end)
    end)
end)

loopBtn.MouseButton1Click:Connect(function()
    loopPlayback = not loopPlayback
    loopBtn.Text = loopPlayback and "Loop: ON" or "Loop: OFF"
    loopBtn.BackgroundColor3 = loopPlayback and Color3.fromRGB(50, 200, 100) or Color3.fromRGB(50, 100, 200)
end)

task.spawn(function()
    while true do
        pcall(function()
            local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.WalkSpeed ~= walkSpeed then 
                hum.WalkSpeed = walkSpeed 
            end
        end)
        task.wait(1)
    end
end)

local tokensFolder = workspace:WaitForChild("Tokens")
local tokenBlacklist = {
    ["Star"] = false,
    ["Worm"] = false,
    ["Sunflower Seed"] = false,
    ["Cookie"] = false,
    ["Strawberry"] = false,
    ["Bronze Coin"] = true,
    ["Golden Coin"] = true
}

task.spawn(function()
    local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
    
    plr.CharacterAdded:Connect(function(char)
        hrp = char:WaitForChild("HumanoidRootPart")
    end)
    
    while true do
        pcall(function()
            if not tokenCollectionRunning then
                task.wait(1)
                return
            end
            
            local collectingAllowed = false
            if not recording then
                if stopAfter == 0 then
                    collectingAllowed = true
                elseif playStartTick == 0 then
                    collectingAllowed = true
                else
                    if tick() - playStartTick < stopAfter then 
                        collectingAllowed = true 
                    end
                end
            end
            
            if collectingAllowed and hrp then
                for _, tok in ipairs(tokensFolder:GetChildren()) do
                    if not tokenCollectionRunning then break end
                    
                    if tokenBlacklist[tok.Name] then
                        continue
                    end
                    
                    local part = tok:IsA("BasePart") and tok or (tok:IsA("Model") and tok.PrimaryPart)
                    if playStartTick>0 and tokenRadius>0 and part and hrp and (part.Position-hrp.Position).Magnitude>tokenRadius then
                        continue
                    end
                    
                    if part and hrp then
                        suspendFrames = true
                        local prev = hrp.CFrame
                        hrp.CFrame = part.CFrame + Vector3.new(0,3,0)
                        collectedSet[tok.Name]=true
                        task.wait(0.05)
                        if playStartTick==0 then
                            hrp.CFrame = prev
                        end
                        suspendFrames = false
                    end
                end
            end
        end)
        task.wait(0.05)
    end
end)

local function inputLog(tp, io)
    if not recording then return end
    pcall(function()
        log[#log + 1] = {
            t = tick() - start,
            kind = "input",
            ev = tp,
            key = io.KeyCode,
            uitype = io.UserInputType,
            pos = io.Position,
            delta = io.Delta
        }
    end)
end

UIS.InputBegan:Connect(function(io, gp) 
    if recording and not gp then 
        inputLog("began", io) 
    end 
end)

UIS.InputEnded:Connect(function(io, gp) 
    if recording and not gp then 
        inputLog("ended", io) 
    end 
end)

UIS.InputChanged:Connect(function(io, gp) 
    if recording and not gp then 
        inputLog("changed", io) 
    end 
end)

local function applyEntry(entry, hrp, cam)
    if not hrp or not cam then return end
    
    pcall(function()
        if entry.kind == "frame" then
            if not suspendFrames then
        hrp.CFrame = entry.pos
    end
            cam.CFrame = entry.cam
        elseif entry.kind == "input" then
            if entry.uitype == Enum.UserInputType.Keyboard then
                VIM:SendKeyEvent(entry.ev ~= "ended", entry.key, false, game)
            elseif entry.uitype == Enum.UserInputType.MouseButton1 or entry.uitype == Enum.UserInputType.MouseButton2 then
                VIM:SendMouseButtonEvent(entry.pos.X, entry.pos.Y, entry.uitype == Enum.UserInputType.MouseButton1 and 0 or 1, entry.ev ~= "ended", game, 0)
            elseif entry.uitype == Enum.UserInputType.MouseMovement then
                if VIM.SendMouseMoveEvent then
                    VIM:SendMouseMoveEvent(entry.pos.X, entry.pos.Y, game)
                end
            end
        end
    end)
end

playBtn.MouseButton1Click:Connect(function()
    if recording or #log == 0 or macroPlaybackRunning then return end
    
    macroPlaybackRunning = true
    local char = plr.Character or plr.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    local cam = workspace.CurrentCamera
    local i = 1
    local startT = tick()
    playStartTick = startT
    
    statusLabel.Text = "Status: Playing..."
    statusLabel.TextColor3 = Color3.fromRGB(50, 150, 50)
    updateUI()
    
    connPlay = RunService.RenderStepped:Connect(function()
        if not macroPlaybackRunning or not connPlay then 
            if connPlay then
                connPlay:Disconnect()
                connPlay = nil
            end
            return 
        end
        
        pcall(function()
            local elapsed = tick() - startT
            
            while i <= #log and log[i].t <= elapsed do
                if macroPlaybackRunning then
                    applyEntry(log[i], hrp, cam)
                end
                i += 1
            end
            
            if i > #log then
                if writefile then
                    local arr = {}
                    for name, _ in pairs(collectedSet) do 
                        table.insert(arr, name) 
                    end
                    local ok, enc = pcall(HttpService.JSONEncode, HttpService, arr)
                    if ok then 
                        pcall(writefile, collectedPath, enc) 
                    end
                end
                
                playStartTick = 0
                if loopPlayback and macroPlaybackRunning then
                    i = 1
                    startT = tick()
                    playStartTick = startT
                else
                    macroPlaybackRunning = false
                    connPlay:Disconnect()
                    connPlay = nil
                    statusLabel.Text = "Status: Ready"
                    statusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
                    updateUI()
                end
            end
        end)
    end)
end)

updateUI()
