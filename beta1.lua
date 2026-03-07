local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
    Name = "NasaHub | v1-beta.3", 
    LoadingTitle = "NasaHub: Instance Stresser",
    ConfigurationSaving = {Enabled = false}
})

local Main = Window:CreateTab("Main")
local Def = Window:CreateTab("Defense")

-- Variables
local Speed, SPower = false, 50
local Green, Flood = false, false
local AntiContest, ACPower = false, 5 
local LagIntensity = 15 -- New variable for lag power

local LagFolder = Instance.new("Folder", workspace)
LagFolder.Name = "NasaHub_Beta_Data"

-- MAIN TAB
Main:CreateSection("Movement & Utilities")
Main:CreateToggle({Name = "Master Walkspeed", Callback = function(v) Speed = v end})
Main:CreateSlider({
    Name = "Speed Power", 
    Range = {16, 200}, 
    CurrentValue = 50, 
    Increment = 1,
    Flag = "SpeedSlider",
    Callback = function(v) SPower = v end
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

    -- 1. Improved Walkspeed
    if Speed and char:FindFirstChild("Humanoid") and char.Humanoid.MoveDirection.Magnitude > 0 then 
        hrp.CFrame += char.Humanoid.MoveDirection * (SPower/100) 
    end

    -- 2. GHOST LAG SWITCH (Optimized for 2026 Stressing)
    if Flood and UIS:IsKeyDown(Enum.KeyCode.V) then
        for i = 1, LagIntensity do
            local b = Instance.new("Part")
            -- Use large, complex shapes to force lighting/physics updates
            b.Size = Vector3.new(50, 50, 50) 
            b.Position = hrp.Position + Vector3.new(math.random(-10,10), 0, math.random(-10,10))
            
            -- Make them invisible to you but heavy for the server
            b.Transparency = 1 
            b.CanCollide = true
            b.Anchored = false 
            b.Massless = false
            b.Material = Enum.Material.ForceField -- Expensive material for GPUs to render
            
            b.Parent = LagFolder
            
            -- Auto-delete blocks after 0.5 seconds to prevent YOU from crashing
            game:GetService("Debris"):AddItem(b, 0.5)
        end
    end

    -- 3. Anti-Contest Jitter
    if AntiContest then
        local Jitter = Vector3.new(math.random(-ACPower, ACPower)/15, 0, math.random(-ACPower, ACPower)/15)
        hrp.CFrame = hrp.CFrame * CFrame.new(Jitter) * CFrame.Angles(0, math.rad(math.random(-ACPower, ACPower)), 0)
    end
end)
