local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
    Name = "NasaHub | v1-beta.4", 
    LoadingTitle = "NasaHub: Physics Stresser",
    ConfigurationSaving = {Enabled = false}
})

local Main = Window:CreateTab("Main")
local Def = Window:CreateTab("Defense")

-- Variables
local Speed, SPower = false, 50
local Flood = false
local AntiContest, ACPower = false, 5 
local PhysicsRadius = 50 -- How far away to grab parts

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

Main:CreateSection("Physics Lag Switch")
Main:CreateToggle({Name = "Velocity Stressor (Hold V)", Callback = function(v) Flood = v end})
Main:CreateSlider({
    Name = "Stressor Radius", 
    Range = {10, 150}, 
    CurrentValue = 50, 
    Increment = 5,
    Suffix = " studs",
    Flag = "PhysRadius",
    Callback = function(v) PhysicsRadius = v end
})

-- DEFENSE TAB
Def:CreateSection("Protection")
Def:CreateToggle({Name = "Anti-Contest (Jitter)", Callback = function(v) AntiContest = v end})

-- SERVICES
local UIS, RS = game:GetService("UserInputService"), game:GetService("RunService")
local p = game.Players.LocalPlayer

-- MAIN RENDER LOOP
RS.Heartbeat:Connect(function()
    local char = p.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- 1. Walkspeed Logic
    if Speed and char:FindFirstChild("Humanoid") and char.Humanoid.MoveDirection.Magnitude > 0 then 
        hrp.CFrame += char.Humanoid.MoveDirection * (SPower/100) 
    end

    -- 2. PHYSICS AUTHORITY STRESSOR (Your New Code)
    if Flood and UIS:IsKeyDown(Enum.KeyCode.V) then
        for _, part in pairs(workspace:GetDescendants()) do
            -- Only target unanchored parts (like dropped items, cars, or debris)
            if part:IsA("BasePart") and not part.Anchored and not part:IsDescendantOf(char) then
                local dist = (part.Position - hrp.Position).Magnitude
                if dist < PhysicsRadius then 
                    -- Apply extreme velocity to force server calculations
                    part.AssemblyLinearVelocity = Vector3.new(1e7, 1e7, 1e7)
                    part.AssemblyAngularVelocity = Vector3.new(1e7, 1e7, 1e7)
                end
            end
        end
    end

    -- 3. Anti-Contest Jitter
    if AntiContest then
        local Jitter = Vector3.new(math.random(-5, 5)/15, 0, math.random(-5, 5)/15)
        hrp.CFrame = hrp.CFrame * CFrame.new(Jitter) * CFrame.Angles(0, math.rad(math.random(-10, 10)), 0)
    end
end)
