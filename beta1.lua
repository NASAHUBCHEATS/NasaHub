local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
    Name = "NasaHub | v1-beta.2", 
    LoadingTitle = "NasaHub: Instance Stresser",
    ConfigurationSaving = {Enabled = false}
})

local Main = Window:CreateTab("Main")
local Def = Window:CreateTab("Defense")
local Unl = Window:CreateTab("Unlocks")

-- Variables
local Speed, SPower = false, 50
local Green, Flood = false, false
local AutoD, Target = false, "None"
local AntiContest, ACPower = false, 5 -- New Variables

local LagFolder = Instance.new("Folder", workspace)
LagFolder.Name = "NasaHub_Beta_Data"

-- MAIN TAB
Main:CreateToggle({Name = "Master Walkspeed", Callback = function(v) Speed = v end})
Main:CreateSlider({
    Name = "Speed Power", 
    Range = {16, 200}, 
    CurrentValue = 50, 
    Increment = 1,
    Suffix = " studs",
    Flag = "SpeedSlider",
    Callback = function(v) SPower = v end
})
Main:CreateToggle({Name = "0.44s Auto-Green", Callback = function(v) Green = v end})
Main:CreateToggle({Name = "Block Lag (Hold V)", Callback = function(v) Flood = v end})

-- DEFENSE TAB
Def:CreateToggle({Name = "Auto-Guard", Callback = function(v) AutoD = v end})
local PList = Def:CreateDropdown({
    Name = "Target Player", 
    Options = {"None"}, 
    Callback = function(v) Target = v end
})

Def:CreateSection("Anti-Lock Protection")
Def:CreateToggle({
    Name = "Anti-Contest (Jitter)", 
    Callback = function(v) AntiContest = v end
})
Def:CreateSlider({
    Name = "Anti-Contest Power", 
    Range = {1, 50}, 
    CurrentValue = 5, 
    Increment = 1,
    Suffix = " intensity",
    Flag = "ACSlider",
    Callback = function(v) ACPower = v end
})

-- UNLOCKS TAB
Unl:CreateButton({Name = "Visual Unlock", Callback = function() 
    local a = game.Players.LocalPlayer.Character:FindFirstChild("Animate")
    if a then 
        a.jump.JumpAnim.AnimationId = "rbxassetid://123456789"
        a.walk.WalkAnim.AnimationId = "rbxassetid://987654321" 
    end
end})

-- SERVICES
local UIS, VIM, RS = game:GetService("UserInputService"), game:GetService("VirtualInputManager"), game:GetService("RunService")

-- INPUT LOGIC
UIS.InputBegan:Connect(function(i, g)
    if not g and Green and i.KeyCode == Enum.KeyCode.E then 
        task.wait(0.44) 
        VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game) 
    end
end)

UIS.InputEnded:Connect(function(i)
    if i.KeyCode == Enum.KeyCode.V then LagFolder:ClearAllChildren() end
end)

-- PLAYER LIST REFRESH
spawn(function() 
    while task.wait(3) do 
        local t = {"None"} 
        for _,p in pairs(game.Players:GetPlayers()) do 
            if p ~= game.Players.LocalPlayer then table.insert(t, p.Name) end 
        end 
        PList:Refresh(t) 
    end 
end)

-- MAIN RENDER LOOP
RS.Heartbeat:Connect(function()
    local p = game.Players.LocalPlayer
    local char = p.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- 1. Walkspeed Logic
    if Speed and char.Humanoid.MoveDirection.Magnitude > 0 then 
        hrp.CFrame += char.Humanoid.MoveDirection * (SPower/80) 
    end

    -- 2. Anti-Contest Jitter Logic
    if AntiContest then
        -- Rapidly jitters your CFrame by the ACPower amount
        local Jitter = Vector3.new(
            math.random(-ACPower, ACPower)/10, 
            0, 
            math.random(-ACPower, ACPower)/10
        )
        hrp.CFrame = hrp.CFrame * CFrame.new(Jitter)
        -- Added rotation jitter to confuse auto-aim
        hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(math.random(-ACPower*2, ACPower*2)), 0)
    end

    -- 3. Block Lag Logic
    if Flood and UIS:IsKeyDown(Enum.KeyCode.V) then
        for i = 1, 12 do
            local b = Instance.new("Part")
            b.Size, b.Position, b.Transparency, b.CanCollide, b.Anchored, b.Parent = Vector3.new(25,25,25), hrp.Position, 1, true, false, LagFolder
        end
    end

    -- 4. Auto-Guard Logic
    if AutoD and Target ~= "None" then
        local t = game.Players:FindFirstChild(Target)
        if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") then
            local pos = t.Character.HumanoidRootPart.Position + (t.Character.HumanoidRootPart.CFrame.LookVector * -4)
            hrp.CFrame = CFrame.new(pos, t.Character.HumanoidRootPart.Position)
        end
    end
end)
