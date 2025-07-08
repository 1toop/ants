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

task.spawn(function()
    while true do
        evt:FireServer(unpack(args2))
        task.wait(interval)
        evt:FireServer(unpack(args1))
        task.wait(interval)
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
window.Size = UDim2.new(0, 350, 0, 250)
window.Position = UDim2.new(0, 10, 0, 10)
window.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
window.Active = true
window.Draggable = true
window.Parent = gui

local macroPath = "AntsMacro.json"

local function packCF(cf)
    local a,b,c,d,e,f,g,h,i,j,k,l = cf:GetComponents()
    return {a,b,c,d,e,f,g,h,i,j,k,l}
end
local function unpackCF(arr)
    if type(arr) ~= "table" or #arr~=12 then return nil end
    return CFrame.new(table.unpack(arr))
end
local function saveMacro(tbl)
    if not writefile then return end
    local serial = {}
    for i,e in ipairs(tbl) do
        local copy = {}
        for k,v in pairs(e) do copy[k]=v end
        if copy.kind=="frame" then
            copy.pos = packCF(copy.pos)
            copy.cam = packCF(copy.cam)
        end
        table.insert(serial,copy)
    end
    local ok,enc = pcall(HttpService.JSONEncode,HttpService,serial)
    if ok then pcall(writefile,macroPath,enc) end
end
local function loadMacro()
    if isfile and isfile(macroPath) then
        local ok,dat = pcall(readfile,macroPath)
        if ok then
            local succ,decoded = pcall(HttpService.JSONDecode,HttpService,dat)
            if succ and typeof(decoded)=="table" then
                -- unpack CFrames
                for _,e in ipairs(decoded) do
                    if e.kind=="frame" then
                        e.pos = unpackCF(e.pos) or CFrame.new()
                        e.cam = unpackCF(e.cam) or workspace.CurrentCamera.CFrame
                    end
                end
                return decoded
            end
        end
    end
    return {}
end
local function clearMacro()
    log = {}
    if delfile and isfile and isfile(macroPath) then pcall(delfile,macroPath) end
end

local windowCorner = Instance.new("UICorner")
windowCorner.CornerRadius = UDim.new(0, 12)
windowCorner.Parent = window

local clearBtn = createButton("Clear", UDim2.new(0, 180, 0, 125), UDim2.new(0, 155, 0, 35), window, Color3.fromRGB(150,100,50))
clearBtn.MouseButton1Click:Connect(function()
    clearMacro()
    updateUI()
end)

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

local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(1, -20, 0, 25)
infoLabel.Position = UDim2.new(0, 10, 0, 175)
infoLabel.Text = "Frames: 0 | Duration: 0s"
infoLabel.BackgroundTransparency = 1
infoLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
infoLabel.TextScaled = true
infoLabel.Font = Enum.Font.SourceSans
infoLabel.Parent = window

local log = loadMacro()
local recording = false
local conn
local start = 0
local loopPlayback = false
local connPlay = nil

local function updateUI()
    if recording then
        recBtn.Text = "Stop Recording"
        recBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
        statusLabel.Text = "Status: Recording..."
        statusLabel.TextColor3 = Color3.fromRGB(220, 50, 50)
    else
        recBtn.Text = "Start Recording"
        recBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
        statusLabel.Text = "Status: Ready"
        statusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    end
    
    local duration = #log > 0 and log[#log].t or 0
    infoLabel.Text = string.format("Frames: %d | Duration: %.1fs", #log, duration)
    
    playBtn.BackgroundColor3 = #log > 0 and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(100, 100, 100)
    clearBtn.BackgroundColor3 = #log > 0 and Color3.fromRGB(150, 100, 50) or Color3.fromRGB(100, 100, 100)
end
recBtn.MouseButton1Click:Connect(function()
    if recording then
        recording=false
        saveMacro(log)
        if conn then conn:Disconnect() end
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

loopBtn.MouseButton1Click:Connect(function()
    loopPlayback = not loopPlayback
    loopBtn.Text = loopPlayback and "Loop: ON" or "Loop: OFF"
    loopBtn.BackgroundColor3 = loopPlayback and Color3.fromRGB(50, 200, 100) or Color3.fromRGB(50, 100, 200)
    
    if not loopPlayback and connPlay then
        connPlay:Disconnect()
        connPlay = nil
    end
end)

clearBtn.MouseButton1Click:Connect(function()
    if recording then return end
    log = {}
    updateUI()
end)

local SPEED = 70
task.spawn(function()
    while true do
        local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
        if hum and hum.WalkSpeed ~= SPEED then 
            hum.WalkSpeed = SPEED 
        end
        task.wait()
    end
end)

local tokensFolder = workspace:WaitForChild("Tokens")
local tokenBlacklist = { ["Star"] = true, ["Worm"] = true }

task.spawn(function()
    local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
    plr.CharacterAdded:Connect(function(char)
        hrp = char:WaitForChild("HumanoidRootPart")
    end)
    while true do
        if not recording then
            for _,tok in ipairs(tokensFolder:GetChildren()) do
                if tokenBlacklist[tok.Name] then
                    continue
                end
                local part = tok:IsA("BasePart") and tok or (tok:IsA("Model") and tok.PrimaryPart)
                if part and hrp then
                    local prev = hrp.CFrame
                    hrp.CFrame = part.CFrame + Vector3.new(0,3,0)
                    task.wait()
                    hrp.CFrame = prev
                end
            end
        end
        task.wait(0.05)
    end
end)

local function inputLog(tp, io)
    if not recording then return end
    log[#log + 1] = {
        t = tick() - start,
        kind = "input",
        ev = tp,
        key = io.KeyCode,
        uitype = io.UserInputType,
        pos = io.Position,
        delta = io.Delta
    }
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
    if entry.kind == "frame" then
        hrp.CFrame = entry.pos
        cam.CFrame = entry.cam
    elseif entry.kind == "input" then
        if entry.uitype == Enum.UserInputType.Keyboard then
            VIM:SendKeyEvent(entry.ev ~= "ended", entry.key, false, game)
        elseif entry.uitype == Enum.UserInputType.MouseButton1 or entry.uitype == Enum.UserInputType.MouseButton2 then
            VIM:SendMouseButtonEvent(entry.pos.X, entry.pos.Y, entry.uitype == Enum.UserInputType.MouseButton1 and 0 or 1, entry.ev ~= "ended", game, 0)
        elseif entry.uitype == Enum.UserInputType.MouseMovement then
            pcall(function()
                if VIM.SendMouseMoveEvent then
                    VIM:SendMouseMoveEvent(entry.pos.X, entry.pos.Y, game)
                end
            end)
        end
    end
end

playBtn.MouseButton1Click:Connect(function()
    if recording or #log == 0 then return end
    
    local char = plr.Character or plr.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    local cam = workspace.CurrentCamera
    local i = 1
    local startT = tick()
    
    statusLabel.Text = "Status: Playing..."
    statusLabel.TextColor3 = Color3.fromRGB(50, 150, 50)
    
    connPlay = RunService.RenderStepped:Connect(function()
        local elapsed = tick() - startT
        
        while i <= #log and log[i].t <= elapsed do
            applyEntry(log[i], hrp, cam)
            i += 1
        end
        
        if i > #log then
            if loopPlayback then
                i = 1
                startT = tick()
            else
                connPlay:Disconnect()
                connPlay = nil
                statusLabel.Text = "Status: Ready"
                statusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
            end
        end
    end)
end)

updateUI()
