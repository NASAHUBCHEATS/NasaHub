local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({Name = "NasaHub | v1-beta.1", LoadingTitle = "NasaHub: Instance Stresser"})

local Main, Def, Unl = Window:CreateTab("Main"), Window:CreateTab("Defense"), Window:CreateTab("Unlocks")
local Speed, SPower, Green, Flood, AutoD, Target = false, 50, false, false, false, "None"

local LagFolder = Instance.new("Folder", workspace)
LagFolder.Name = "NasaHub_Beta_Data"

Main:CreateToggle({Name = "Master Walkspeed", Callback = function(v) Speed = v end})
Main:CreateSlider({Name = "Speed", Range = {16, 200}, CurrentValue = 50, Callback = function(v) SPower = v end})
Main:CreateToggle({Name = "0.44s Auto-Green", Callback = function(v) Green = v end})
Main:CreateToggle({Name = "Block Lag (Hold V)", Callback = function(v) Flood = v end})

Def:CreateToggle({Name = "Auto-Guard", Callback = function(v) AutoD = v end})
local PList = Def:CreateDropdown({Name = "Target", Options = {"None"}, Callback = function(v) Target = v end})

Unl:CreateButton({Name = "Visual Unlock", Callback = function() 
    local a = game.Players.LocalPlayer.Character:FindFirstChild("Animate")
    if a then a.jump.JumpAnim.AnimationId, a.walk.WalkAnim.AnimationId = "rbxassetid://123456789", "rbxassetid://987654321" end
end})

local UIS, VIM, RS = game:GetService("UserInputService"), game:GetService("VirtualInputManager"), game:GetService("RunService")

UIS.InputBegan:Connect(function(i, g)
    if not g and Green and i.KeyCode == Enum.KeyCode.E then task.wait(0.44) VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game) end
end)

UIS.InputEnded:Connect(function(i)
    if i.KeyCode == Enum.KeyCode.V then LagFolder:ClearAllChildren() end
end)

spawn(function() while task.wait(3) do local t = {"None"} for _,p in pairs(game.Players:GetPlayers()) do if p ~= game.Players.LocalPlayer then table.insert(t, p.Name) end end PList:Refresh(t) end end)

RS.Heartbeat:Connect(function()
    local p = game.Players.LocalPlayer
    local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if Speed and p.Character.Humanoid.MoveDirection.Magnitude > 0 then hrp.CFrame += p.Character.Humanoid.MoveDirection * (SPower/80) end
    if Flood and UIS:IsKeyDown(Enum.KeyCode.V) then
        for i = 1, 12 do
            local b = Instance.new("Part")
            b.Size, b.Position, b.Transparency, b.CanCollide, b.Anchored, b.Parent = Vector3.new(25,25,25), Vector3.new(0,5,0), 1, true, false, LagFolder
        end
    end
    if AutoD and Target ~= "None" then
        local t = game.Players:FindFirstChild(Target)
        if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") then
            local pos = t.Character.HumanoidRootPart.Position + (t.Character.HumanoidRootPart.CFrame.LookVector * -4)
            hrp.CFrame = CFrame.new(pos, t.Character.HumanoidRootPart.Position)
        end
    end
end)
