local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
    Name = "NasaHub | v1-beta.4", 
    LoadingTitle = "NasaHub: Instance Stresser",
    ConfigurationSaving = {Enabled = false}
})

local Main = Window:CreateTab("Main")
local Def = Window:CreateTab("Defense")

-- Variables
local Speed, SPower = false, 50
local Green, Flood = false, false
local AntiContest, ACPower = false, 5 
local LagIntensity = 15

local LagFolder = Instance.new("Folder", workspace)
LagFolder.Name = "NasaHub_Beta_Data"

-- MAIN TAB
Main:CreateSection("Movement")
Main:CreateToggle({Name = "Master Walkspeed", Callback = function(v) Speed = v end})
Main:CreateSlider({
    Name = "Speed Power", 
    Range = {16, 200}, 
    CurrentValue = 50, 
    Increment = 1,
    Flag = "SpeedSlider",
    Callback = function(v) SPower = v end
})

Main:CreateSection("Combat Timing")
Main:CreateToggle({
    Name = "0.44s Auto-Green (Press E)", 
    CurrentValue = false,
    Callback = function(v) Green = v end
})

Main:CreateSection("Ghost Lag Switch")
Main:CreateToggle({Name = "Invisible Block Lag (Hold V)", Callback = function(v) Flood = v end})
Main:CreateSlider({
    Name = "Lag Intensity", 
    Range = {5, 50}, 
    CurrentValue = 15, 
    Increment = 1,
    Suffix = " blocks/tick",
    Flag = "LagPower",
    Callback = function(v) LagIntensity = v end
})

-- DEFENSE TAB
Def:CreateSection("Protection")
Def:CreateToggle({Name = "Anti-Contest (Jitter)", Callback = function(v) AntiContest = v end})
Def:CreateSlider({
    Name = "Jitter Power", 
    Range = {1, 50}, 
    CurrentValue = 5, 
    Increment = 1,
    Flag = "ACSlider",
    Callback = function(v) ACPower = v end
})

-- SERVICES
local UIS, VIM, RS = game:GetService("UserInputService"), game:GetService("VirtualInputManager"), game:GetService("RunService")

-- AUTO-GREEN LOGIC
UIS.InputBegan:Connect(function(input, processed)
    if not processed and Green and input.KeyCode == Enum.KeyCode.E then 
        -- Standard 0.44s delay for perfect "Green" timing
        task.wait(0.44) 
        -- VIM is used to bypass internal delay checks in most games
        VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game) 
    end
end)

-- CLEANUP LOGIC
UIS.InputEnded:Connect(function(i)
    if i.KeyCode == Enum.KeyCode.V then 
        LagFolder:ClearAllChildren() 
    end
end)

-- MAIN RENDER LOOP
RS.Heartbeat:Connect(function()
    local p = game.Players.LocalPlayer
    local char = p.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- 1. Walkspeed
    if Speed and char:FindFirstChild("Humanoid") and char.Humanoid.MoveDirection.Magnitude > 0 then 
        hrp.CFrame += char.Humanoid.MoveDirection * (SPower/100) 
    end

    -- 2. GHOST LAG SWITCH
    if Flood and UIS:IsKeyDown(Enum.KeyCode.V) then
        for i = 1, LagIntensity do
            local b = Instance.new("Part")
            b.Size = Vector3.new(50, 50, 50) 
            b.Position = hrp.Position + Vector3.new(math.random(-10,10), 0, math.random(-10,10))
            b.Transparency = 1 
            b.CanCollide = true
            b.Anchored = false 
            b.Material = Enum.Material.ForceField
            b.Parent = LagFolder
            game:GetService("Debris"):AddItem(b, 0.4) -- Slightly faster cleanup for stability
        end
    end

    -- 3. Anti-Contest Jitter
    if AntiContest then
        local Jitter = Vector3.new(math.random(-ACPower, ACPower)/15, 0, math.random(-ACPower, ACPower)/15)
        hrp.CFrame = hrp.CFrame * CFrame.new(Jitter) * CFrame.Angles(0, math.rad(math.random(-ACPower, ACPower)), 0)
    end
end)
