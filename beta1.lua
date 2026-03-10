-- // NASA HUB v1-beta.28 // --
-- Advanced Script Hub with Unlock All & Enhanced Anti-Contest

-- Prevent multiple instances
if _G.NasaHub then
    game:GetService("CoreGui"):FindFirstChild("NasaHub"):Destroy()
end
_G.NasaHub = true

-- Load Rayfield UI Library
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
    Name = "NasaHub | v1-beta.28",
    LoadingTitle = "Unlock All + Anti-Contest",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "NasaHub",
        FileName = "Config"
    },
    Discord = {
        Enabled = false
    },
    KeySystem = false
})

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local TeleportService = game:GetService("TeleportService")
local MarketplaceService = game:GetService("MarketplaceService")
local CollectionService = game:GetService("CollectionService")

-- Local Player
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

-- Configuration Table
local Config = {
    -- Movement
    SpeedEnabled = false,
    SpeedPower = 22,
    SpeedMode = "CFrame",
    
    -- Combat
    AutoGreen = false,
    HitboxEnabled = false,
    HitboxSize = 2,
    
    -- Defense
    RingEnabled = false,
    RingRadius = 12,
    AntiContest = false,
    AntiContestMode = "Jitter", -- "Jitter", "Teleport", "Phase", "Launch"
    AntiContestStrength = 1,
    AutoDefense = false,
    DefenseMode = "Shield",
    DefenseDistance = 15,
    DefenseCooldown = 0,
    
    -- Unlock All
    AutoCollect = false,
    AutoClaim = false,
    UnlockRadius = 50,
    UnlockInterval = 1,
    
    -- Visuals
    RingColor = Color3.new(0, 1, 0),
    ContestedColor = Color3.new(1, 0, 0)
}

-- Cache for performance
local Cache = {
    Ring = nil,
    RingLabel = nil,
    ScreenGui = nil,
    OriginalParts = {},
    Connections = {},
    LastDefenseTime = 0,
    LastUnlockTime = 0,
    NearbyThreats = {},
    UnlockedItems = {},
    OriginalPositions = {}
}

-- UI Elements Storage
local UI = {}

-- Create Tabs
local MainTab = Window:CreateTab("Main", "home")
local DefenseTab = Window:CreateTab("Defense", "shield")
local UnlockTab = Window:CreateTab("Unlock All", "star")
local SettingsTab = Window:CreateTab("Settings", "settings")

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

local function CleanupCache()
    -- Clean up ring
    if Cache.Ring and Cache.Ring.Parent then
        Cache.Ring:Destroy()
    end
    Cache.Ring = nil
    Cache.RingLabel = nil
    
    -- Clean up GUI
    if Cache.ScreenGui and Cache.ScreenGui.Parent then
        Cache.ScreenGui:Destroy()
    end
    Cache.ScreenGui = nil
    
    -- Restore original hitbox sizes
    for part, size in pairs(Cache.OriginalParts) do
        if part and part.Parent then
            part.Size = size
            part.Transparency = 0
        end
    end
    Cache.OriginalParts = {}
end

local function CreateRing()
    if Cache.Ring then return end
    
    -- Create ring part
    local Ring = Instance.new("Part")
    Ring.Name = "ContestRing"
    Ring.Shape = Enum.PartType.Cylinder
    Ring.Anchored = true
    Ring.CanCollide = false
    Ring.CanQuery = false
    Ring.CanTouch = false
    Ring.Transparency = 0.7
    Ring.Material = Enum.Material.Neon
    Ring.BrickColor = BrickColor.new("Lime green")
    Ring.Size = Vector3.new(0.1, Config.RingRadius * 2, Config.RingRadius * 2)
    Ring.Rotation = Vector3.new(0, 0, 90)
    Ring.Parent = Workspace
    
    -- Add BillboardGui for text
    local Billboard = Instance.new("BillboardGui")
    Billboard.Name = "RingLabel"
    Billboard.Size = UDim2.new(0, 100, 0, 30)
    Billboard.StudsOffset = Vector3.new(0, 3, 0)
    Billboard.AlwaysOnTop = true
    Billboard.Parent = Ring
    
    local TextLabel = Instance.new("TextLabel")
    TextLabel.Size = UDim2.new(1, 0, 1, 0)
    TextLabel.BackgroundTransparency = 1
    TextLabel.Text = "OPEN"
    TextLabel.TextColor3 = Config.RingColor
    TextLabel.TextStrokeTransparency = 0.5
    TextLabel.TextScaled = true
    TextLabel.Font = Enum.Font.GothamBold
    TextLabel.Parent = Billboard
    
    Cache.Ring = Ring
    Cache.RingLabel = TextLabel
end

local function UpdateHitboxes()
    if not Config.HitboxEnabled then
        -- Restore original sizes
        for part, size in pairs(Cache.OriginalParts) do
            if part and part.Parent then
                part.Size = size
                part.Transparency = 0
            end
        end
        Cache.OriginalParts = {}
        return
    end
    
    -- Apply hitbox expansion to all players
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            if root then
                -- Store original size if not already stored
                if not Cache.OriginalParts[root] then
                    Cache.OriginalParts[root] = root.Size
                end
                
                -- Apply new size
                root.Size = Vector3.new(Config.HitboxSize, Config.HitboxSize, Config.HitboxSize)
                root.Transparency = 0.5
                
                -- Also expand head for better hit detection
                local head = player.Character:FindFirstChild("Head")
                if head and not Cache.OriginalParts[head] then
                    Cache.OriginalParts[head] = head.Size
                    head.Size = Vector3.new(Config.HitboxSize * 0.8, Config.HitboxSize * 0.8, Config.HitboxSize * 0.8)
                    head.Transparency = 0.5
                end
            end
        end
    end
end

-- ============================================
-- ENHANCED ANTI-CONTEST FUNCTIONS
-- ============================================

local function JitterAntiContest(rootPart)
    -- Random micro-teleports to make you hard to hit
    local jitterX = math.random(-15, 15) / (50 / Config.AntiContestStrength)
    local jitterZ = math.random(-15, 15) / (50 / Config.AntiContestStrength)
    
    rootPart.CFrame = rootPart.CFrame + Vector3.new(jitterX, 0, jitterZ)
    
    -- Visual feedback
    local effect = Instance.new("Part")
    effect.Name = "JitterEffect"
    effect.Size = Vector3.new(1, 1, 1)
    effect.Position = rootPart.Position
    effect.Anchored = true
    effect.CanCollide = false
    effect.Transparency = 0.7
    effect.BrickColor = BrickColor.new("Really blue")
    effect.Material = Enum.Material.Neon
    effect.Parent = Workspace
    
    local mesh = Instance.new("SpecialMesh")
    mesh.MeshType = Enum.MeshType.Sphere
    mesh.Parent = effect
    
    Debris:AddItem(effect, 0.2)
end

local function TeleportAntiContest(rootPart)
    -- Teleport to random nearby position
    local randomAngle = math.random() * 2 * math.pi
    local randomRadius = math.random(3, 8) * Config.AntiContestStrength
    local offset = Vector3.new(
        math.cos(randomAngle) * randomRadius,
        0,
        math.sin(randomAngle) * randomRadius
    )
    
    -- Store original position for teleport effect
    local originalPos = rootPart.Position
    rootPart.CFrame = rootPart.CFrame + offset
    
    -- Create teleport trail
    local beam = Instance.new("Part")
    beam.Name = "TeleportBeam"
    beam.Size = Vector3.new(0.5, 0.5, (originalPos - rootPart.Position).Magnitude)
    beam.CFrame = CFrame.lookAt(originalPos, rootPart.Position) * CFrame.new(0, 0, -beam.Size.Z/2)
    beam.Anchored = true
    beam.CanCollide = false
    beam.Transparency = 0.5
    beam.BrickColor = BrickColor.new("Bright violet")
    beam.Material = Enum.Material.Neon
    beam.Parent = Workspace
    
    Debris:AddItem(beam, 0.3)
    
    -- Start and end effects
    for _, pos in ipairs({originalPos, rootPart.Position}) do
        local effect = Instance.new("Part")
        effect.Name = "TeleportEffect"
        effect.Size = Vector3.new(2, 2, 2)
        effect.Position = pos
        effect.Anchored = true
        effect.CanCollide = false
        effect.Transparency = 0.6
        effect.BrickColor = BrickColor.new("Bright blue")
        effect.Material = Enum.Material.Neon
        effect.Parent = Workspace
        
        local mesh = Instance.new("SpecialMesh")
        mesh.MeshType = Enum.MeshType.Sphere
        mesh.Parent = effect
        
        Debris:AddItem(effect, 0.3)
    end
end

local function PhaseAntiContest(rootPart)
    -- Phase through attacks by going semi-transparent
    local character = LocalPlayer.Character
    
    -- Make character semi-transparent
    for _, part in ipairs(character:GetChildren()) do
        if part:IsA("BasePart") then
            part.Transparency = 0.7
            part.CanCollide = false
        end
    end
    
    -- Rapid small movements
    for i = 1, 10 * Config.AntiContestStrength do
        local phaseX = math.random(-10, 10) / 30
        local phaseZ = math.random(-10, 10) / 30
        rootPart.CFrame = rootPart.CFrame + Vector3.new(phaseX, 0, phaseZ)
        
        -- Create phase particles
        local particle = Instance.new("Part")
        particle.Name = "PhaseParticle"
        particle.Size = Vector3.new(0.3, 0.3, 0.3)
        particle.Position = rootPart.Position + Vector3.new(math.random(-3, 3), math.random(-2, 2), math.random(-3, 3))
        particle.Anchored = true
        particle.CanCollide = false
        particle.Transparency = 0.5
        particle.BrickColor = BrickColor.new("Cyan")
        particle.Material = Enum.Material.Neon
        particle.Parent = Workspace
        
        local mesh = Instance.new("SpecialMesh")
        mesh.MeshType = Enum.MeshType.Sphere
        mesh.Parent = particle
        
        Debris:AddItem(particle, 0.3)
        
        task.wait(0.01)
    end
    
    -- Restore visibility after 1 second
    task.wait(1)
    for _, part in ipairs(character:GetChildren()) do
        if part:IsA("BasePart") then
            part.Transparency = 0
            part.CanCollide = true
        end
    end
end

local function LaunchAntiContest(rootPart)
    -- Launch yourself away from threats
    local character = LocalPlayer.Character
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    
    -- Find direction away from nearest threat
    local nearestThreat = nil
    local nearestDistance = Config.RingRadius * 2
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                local distance = (targetRoot.Position - rootPart.Position).Magnitude
                if distance < nearestDistance then
                    nearestDistance = distance
                    nearestThreat = targetRoot
                end
            end
        end
    end
    
    if nearestThreat then
        -- Launch away from threat
        local launchDirection = (rootPart.Position - nearestThreat.Position).Unit
        local launchPower = 30 * Config.AntiContestStrength
        
        -- Apply velocity for smooth launch
        rootPart.Velocity = launchDirection * launchPower
        
        -- Create launch trail
        local trail = Instance.new("Part")
        trail.Name = "LaunchTrail"
        trail.Size = Vector3.new(1, 1, 5)
        trail.CFrame = rootPart.CFrame * CFrame.new(0, 0, 2.5)
        trail.Anchored = true
        trail.CanCollide = false
        trail.Transparency = 0.5
        trail.BrickColor = BrickColor.new("Bright orange")
        trail.Material = Enum.Material.Neon
        trail.Parent = Workspace
        
        Debris:AddItem(trail, 0.5)
        
        -- Boost effect
        local boost = Instance.new("Part")
        boost.Name = "LaunchBoost"
        boost.Size = Vector3.new(2, 2, 2)
        boost.Position = rootPart.Position
        boost.Anchored = true
        boost.CanCollide = false
        boost.Transparency = 0.6
        boost.BrickColor = BrickColor.new("Bright orange")
        boost.Material = Enum.Material.Neon
        boost.Parent = Workspace
        
        local mesh = Instance.new("SpecialMesh")
        mesh.MeshType = Enum.MeshType.Sphere
        mesh.Parent = boost
        
        Debris:AddItem(boost, 0.3)
    end
end

-- ============================================
-- UNLOCK ALL FUNCTIONS
-- ============================================

local function FindUnlockables()
    local unlockables = {}
    
    -- Find collectibles in workspace
    for _, obj in ipairs(Workspace:GetDescendants()) do
        -- Check if object is collectible/unlockable
        if obj:IsA("Part") or obj:IsA("MeshPart") or obj:IsA("Model") then
            local name = obj.Name:lower()
            if name:find("coin") or name:find("gem") or name:find("crystal") or 
               name:find("token") or name:find("chest") or name:find("reward") or
               name:find("orb") or name:find("star") or name:find("ball") or
               CollectionService:HasTag(obj, "Collectible") then
                
                -- Get position
                local position
                if obj:IsA("Model") then
                    local primary = obj:FindFirstChild("PrimaryPart") or obj:FindFirstChildOfClass("Part")
                    if primary then
                        position = primary.Position
                    end
                else
                    position = obj.Position
                end
                
                if position then
                    table.insert(unlockables, {
                        Object = obj,
                        Position = position,
                        Name = obj.Name
                    })
                end
            end
        end
    end
    
    -- Find GUI buttons/claims
    for _, gui in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
        if gui:IsA("TextButton") or gui:IsA("ImageButton") then
            local text = gui.Text and gui.Text:lower() or ""
            if text:find("claim") or text:find("collect") or text:find("get") or
               text:find("unlock") or text:find("buy") or text:find("redeem") or
               gui.Name:lower():find("claim") or gui.Name:lower():find("collect") then
                table.insert(unlockables, {
                    Object = gui,
                    IsGUI = true,
                    Name = gui.Name
                })
            end
        end
    end
    
    return unlockables
end

local function CollectNearestUnlockables()
    local character = LocalPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    local unlockables = FindUnlockables()
    local collected = 0
    
    for _, item in ipairs(unlockables) do
        -- Check if already unlocked
        if Cache.UnlockedItems[item.Object] then
            continue
        end
        
        -- Check distance
        local distance
        if item.Position then
            distance = (item.Position - rootPart.Position).Magnitude
        else
            distance = 0 -- GUI elements are always accessible
        end
        
        if distance <= Config.UnlockRadius or item.IsGUI then
            -- Attempt to collect
            local success = pcall(function()
                if item.IsGUI then
                    -- Click GUI button
                    if item.Object.Visible and item.Object.Active then
                        VirtualInputManager:SendMouseButtonEvent(
                            item.Object.AbsolutePosition.X + item.Object.AbsoluteSize.X/2,
                            item.Object.AbsolutePosition.Y + item.Object.AbsoluteSize.Y/2,
                            0, true, game, 0
                        )
                        task.wait(0.1)
                        VirtualInputManager:SendMouseButtonEvent(
                            item.Object.AbsolutePosition.X + item.Object.AbsoluteSize.X/2,
                            item.Object.AbsolutePosition.Y + item.Object.AbsoluteSize.Y/2,
                            0, false, game, 0
                        )
                    end
                else
                    -- Teleport to collectible
                    rootPart.CFrame = CFrame.new(item.Position)
                    
                    -- Try to fire touch events
                    if item.Object:IsA("BasePart") then
                        firetouchinterest(rootPart, item.Object, 0)
                        task.wait(0.1)
                        firetouchinterest(rootPart, item.Object, 1)
                    end
                end
                
                -- Mark as collected
                Cache.UnlockedItems[item.Object] = true
                collected = collected + 1
                
                -- Visual effect
                local effect = Instance.new("Part")
                effect.Name = "CollectEffect"
                effect.Size = Vector3.new(2, 2, 2)
                effect.Position = item.Position or rootPart.Position
                effect.Anchored = true
                effect.CanCollide = false
                effect.Transparency = 0.4
                effect.BrickColor = BrickColor.new("Bright yellow")
                effect.Material = Enum.Material.Neon
                effect.Parent = Workspace
                
                local mesh = Instance.new("SpecialMesh")
                mesh.MeshType = Enum.MeshType.Sphere
                mesh.Parent = effect
                
                Debris:AddItem(effect, 0.5)
            end)
        end
    end
    
    if collected > 0 then
        Rayfield:Notify({
            Title = "Unlock All",
            Content = "Collected " .. collected .. " items!",
            Duration = 1
        })
    end
end

-- ============================================
-- MAIN TAB
-- ============================================

MainTab:CreateSection("Movement Settings")

UI.SpeedToggle = MainTab:CreateToggle({
    Name = "Master Walkspeed",
    CurrentValue = false,
    Flag = "SpeedToggle",
    Callback = function(value)
        Config.SpeedEnabled = value
    end
})

UI.SpeedMode = MainTab:CreateDropdown({
    Name = "Speed Mode",
    Options = {"CFrame (Smooth)", "Velocity (Fast)", "WalkSpeed (Basic)"},
    CurrentOption = "CFrame (Smooth)",
    Flag = "SpeedMode",
    Callback = function(value)
        if value == "CFrame (Smooth)" then
            Config.SpeedMode = "CFrame"
        elseif value == "Velocity (Fast)" then
            Config.SpeedMode = "Velocity"
        elseif value == "WalkSpeed (Basic)" then
            Config.SpeedMode = "WalkSpeed"
        end
    end
})

UI.SpeedSlider = MainTab:CreateSlider({
    Name = "Speed Power",
    Range = {16, 500},
    Increment = 5,
    CurrentValue = 22,
    Flag = "SpeedSlider",
    Callback = function(value)
        Config.SpeedPower = value
    end
})

MainTab:CreateSection("Combat Settings")

UI.GreenToggle = MainTab:CreateToggle({
    Name = "0.44s Auto-Green (Press E)",
    CurrentValue = false,
    Flag = "GreenToggle",
    Callback = function(value)
        Config.AutoGreen = value
    end
})

UI.HitboxToggle = MainTab:CreateToggle({
    Name = "Expand Ball Hitbox",
    CurrentValue = false,
    Flag = "HitboxToggle",
    Callback = function(value)
        Config.HitboxEnabled = value
        UpdateHitboxes()
    end
})

UI.HitboxSlider = MainTab:CreateSlider({
    Name = "Hitbox Size",
    Range = {2, 30},
    Increment = 1,
    CurrentValue = 2,
    Flag = "HitboxSlider",
    Callback = function(value)
        Config.HitboxSize = value
        UpdateHitboxes()
    end
})

-- ============================================
-- DEFENSE TAB
-- ============================================

DefenseTab:CreateSection("Detection Systems")

UI.RingToggle = DefenseTab:CreateToggle({
    Name = "Enable 3D Contest Ring",
    CurrentValue = false,
    Flag = "RingToggle",
    Callback = function(value)
        Config.RingEnabled = value
        
        if value then
            CreateRing()
        elseif Cache.Ring then
            Cache.Ring:Destroy()
            Cache.Ring = nil
            Cache.RingLabel = nil
        end
    end
})

UI.RadiusSlider = DefenseTab:CreateSlider({
    Name = "Detection Radius",
    Range = {5, 50},
    Increment = 1,
    CurrentValue = 12,
    Flag = "RadiusSlider",
    Callback = function(value)
        Config.RingRadius = value
        if Cache.Ring then
            Cache.Ring.Size = Vector3.new(0.1, value * 2, value * 2)
        end
    end
})

DefenseTab:CreateSection("Enhanced Anti-Contest")

UI.AntiContestToggle = DefenseTab:CreateToggle({
    Name = "Enable Anti-Contest",
    CurrentValue = false,
    Flag = "AntiContestToggle",
    Callback = function(value)
        Config.AntiContest = value
    end
})

UI.AntiContestMode = DefenseTab:CreateDropdown({
    Name = "Anti-Contest Mode",
    Options = {"Jitter (Micro-Teleports)", "Teleport (Short Range)", "Phase (Ghost Mode)", "Launch (Escape)"},
    CurrentOption = "Jitter (Micro-Teleports)",
    Flag = "AntiContestMode",
    Callback = function(value)
        if value == "Jitter (Micro-Teleports)" then
            Config.AntiContestMode = "Jitter"
        elseif value == "Teleport (Short Range)" then
            Config.AntiContestMode = "Teleport"
        elseif value == "Phase (Ghost Mode)" then
            Config.AntiContestMode = "Phase"
        elseif value == "Launch (Escape)" then
            Config.AntiContestMode = "Launch"
        end
    end
})

UI.AntiContestStrength = DefenseTab:CreateSlider({
    Name = "Anti-Contest Strength",
    Range = {0.5, 3},
    Increment = 0.5,
    CurrentValue = 1,
    Flag = "AntiContestStrength",
    Callback = function(value)
        Config.AntiContestStrength = value
    end
})

DefenseTab:CreateSection("Auto Defense System")

UI.AutoDefenseToggle = DefenseTab:CreateToggle({
    Name = "Enable Auto Defense",
    CurrentValue = false,
    Flag = "AutoDefenseToggle",
    Callback = function(value)
        Config.AutoDefense = value
        if value then
            Rayfield:Notify({
                Title = "Auto Defense",
                Content = "System activated!",
                Duration = 2
            })
        end
    end
})

UI.DefenseMode = DefenseTab:CreateDropdown({
    Name = "Defense Mode",
    Options = {"Shield (Repel)", "Dodge (Evade)", "Counter (Aggressive)"},
    CurrentOption = "Shield (Repel)",
    Flag = "DefenseMode",
    Callback = function(value)
        if value == "Shield (Repel)" then
            Config.DefenseMode = "Shield"
        elseif value == "Dodge (Evade)" then
            Config.DefenseMode = "Dodge"
        elseif value == "Counter (Aggressive)" then
            Config.DefenseMode = "Counter"
        end
    end
})

UI.DefenseDistance = DefenseTab:CreateSlider({
    Name = "Detection Distance",
    Range = {5, 30},
    Increment = 1,
    CurrentValue = 15,
    Flag = "DefenseDistance",
    Callback = function(value)
        Config.DefenseDistance = value
    end
})

UI.DefenseCooldown = DefenseTab:CreateSlider({
    Name = "Cooldown (Seconds)",
    Range = {0, 5},
    Increment = 0.5,
    CurrentValue = 0,
    Flag = "DefenseCooldown",
    Callback = function(value)
        Config.DefenseCooldown = value
    end
})

-- ============================================
-- UNLOCK ALL TAB
-- ============================================

UnlockTab:CreateSection("Unlock All System")

UI.AutoCollectToggle = UnlockTab:CreateToggle({
    Name = "Auto Collect Items",
    CurrentValue = false,
    Flag = "AutoCollectToggle",
    Callback = function(value)
        Config.AutoCollect = value
    end
})

UI.UnlockRadius = UnlockTab:CreateSlider({
    Name = "Collection Radius",
    Range = {10, 200},
    Increment = 5,
    CurrentValue = 50,
    Flag = "UnlockRadius",
    Callback = function(value)
        Config.UnlockRadius = value
    end
})

UI.UnlockInterval = UnlockTab:CreateSlider({
    Name = "Collection Interval (s)",
    Range = {0.5, 5},
    Increment = 0.5,
    CurrentValue = 1,
    Flag = "UnlockInterval",
    Callback = function(value)
        Config.UnlockInterval = value
    end
})

UnlockTab:CreateButton({
    Name = "Scan for Unlockables",
    Callback = function()
        local items = FindUnlockables()
        Rayfield:Notify({
            Title = "Unlock All",
            Content = "Found " .. #items .. " unlockable items",
            Duration = 3
        })
    end
})

UnlockTab:CreateButton({
    Name = "Collect All Now",
    Callback = function()
        CollectNearestUnlockables()
    end
})

UnlockTab:CreateButton({
    Name = "Clear Collection Cache",
    Callback = function()
        Cache.UnlockedItems = {}
        Rayfield:Notify({
            Title = "Unlock All",
            Content = "Collection cache cleared",
            Duration = 2
        })
    end
})

UnlockTab:CreateSection("Auto Claim Features")

UI.AutoClaimToggle = UnlockTab:CreateToggle({
    Name = "Auto Claim Rewards",
    CurrentValue = false,
    Flag = "AutoClaimToggle",
    Callback = function(value)
        Config.AutoClaim = value
    end
})

UnlockTab:CreateButton({
    Name = "Claim All GUI Buttons",
    Callback = function()
        local claimed = 0
        for _, gui in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
            if gui:IsA("TextButton") or gui:IsA("ImageButton") then
                local text = gui.Text and gui.Text:lower() or ""
                if text:find("claim") or text:find("collect") or text:find("get") or
                   gui.Name:lower():find("claim") then
                    if gui.Visible and gui.Active then
                        fireclickdetector(gui)
                        claimed = claimed + 1
                        task.wait(0.1)
                    end
                end
            end
        end
        Rayfield:Notify({
            Title = "Auto Claim",
            Content = "Claimed " .. claimed .. " rewards",
            Duration = 2
        })
    end
})

-- ============================================
-- SETTINGS TAB
-- ============================================

SettingsTab:CreateSection("UI Settings")

SettingsTab:CreateButton({
    Name = "Destroy UI",
    Callback = function()
        CleanupCache()
        Rayfield:Destroy()
        _G.NasaHub = nil
    end
})

SettingsTab:CreateButton({
    Name = "Rejoin Game",
    Callback = function()
        CleanupCache()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end
})

-- Auto Defense Functions (from previous version)
local function PerformShieldDefense()
    local character = LocalPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    -- Create shield effect
    local shield = Instance.new("Part")
    shield.Name = "DefenseShield"
    shield.Shape = Enum.PartType.Ball
    shield.Size = Vector3.new(5, 5, 5)
    shield.Position = rootPart.Position
    shield.Anchored = true
    shield.CanCollide = false
    shield.Transparency = 0.3
    shield.BrickColor = BrickColor.new("Bright blue")
    shield.Material = Enum.Material.Neon
    shield.Parent = Workspace
    
    local mesh = Instance.new("SpecialMesh")
    mesh.MeshType = Enum.MeshType.Sphere
    mesh.Parent = shield
    Debris:AddItem(shield, 1)
    
    -- Repel nearby players
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                local distance = (targetRoot.Position - rootPart.Position).Magnitude
                if distance < 10 then
                    local direction = (targetRoot.Position - rootPart.Position).Unit
                    targetRoot.CFrame = targetRoot.CFrame + direction * 5
                end
            end
        end
    end
end

local function PerformDodgeDefense()
    local character = LocalPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    local closestThreat = nil
    local closestDistance = Config.DefenseDistance
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                local distance = (targetRoot.Position - rootPart.Position).Magnitude
                if distance < closestDistance then
                    closestDistance = distance
                    closestThreat = targetRoot
                end
            end
        end
    end
    
    if closestThreat then
        local dodgeDirection = (rootPart.Position - closestThreat.Position).Unit
        rootPart.CFrame = rootPart.CFrame + dodgeDirection * 8
        
        local effect = Instance.new("Part")
        effect.Name = "DodgeEffect"
        effect.Size = Vector3.new(1, 1, 1)
        effect.Position = rootPart.Position
        effect.Anchored = true
        effect.CanCollide = false
        effect.Transparency = 0.5
        effect.BrickColor = BrickColor.new("Bright yellow")
        effect.Material = Enum.Material.Neon
        effect.Parent = Workspace
        
        local mesh = Instance.new("SpecialMesh")
        mesh.MeshType = Enum.MeshType.Sphere
        mesh.Parent = effect
        Debris:AddItem(effect, 0.5)
    end
end

local function PerformCounterDefense()
    local character = LocalPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    local closestPlayer = nil
    local closestDistance = Config.DefenseDistance
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                local distance = (targetRoot.Position - rootPart.Position).Magnitude
                if distance < closestDistance then
                    closestDistance = distance
                    closestPlayer = player
                end
            end
        end
    end
    
    if closestPlayer and closestPlayer.Character then
        local targetRoot = closestPlayer.Character:FindFirstChild("HumanoidRootPart")
        if targetRoot then
            local behindPosition = targetRoot.Position - (targetRoot.CFrame.LookVector * 5)
            rootPart.CFrame = CFrame.new(behindPosition) * CFrame.Angles(0, targetRoot.Orientation.Y, 0)
            
            local effect = Instance.new("Part")
            effect.Name = "CounterEffect"
            effect.Size = Vector3.new(3, 3, 3)
            effect.Position = targetRoot.Position
            effect.Anchored = true
            effect.CanCollide = false
            effect.Transparency = 0.4
            effect.BrickColor = BrickColor.new("Bright red")
            effect.Material = Enum.Material.Neon
            effect.Parent = Workspace
            
            local mesh = Instance.new("SpecialMesh")
            mesh.MeshType = Enum.MeshType.Sphere
            mesh.Parent = effect
            Debris:AddItem(effect, 0.5)
        end
    end
end

local function CheckThreats()
    local character = LocalPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return {} end
    
    local threats = {}
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                local distance = (targetRoot.Position - rootPart.Position).Magnitude
                if distance < Config.DefenseDistance then
                    table.insert(threats, {
                        Player = player,
                        Distance = distance,
                        Root = targetRoot
                    })
                end
            end
        end
    end
    
    table.sort(threats, function(a, b)
        return a.Distance < b.Distance
    end)
    
    return threats
end

-- ============================================
-- MAIN LOOP & EVENT HANDLERS
-- ============================================

-- Character Added Handler
local function onCharacterAdded(character)
    Character = character
    
    -- Wait for humanoid
    local humanoid = character:WaitForChild("Humanoid", 5)
    
    -- Reset hitbox cache for new character
    Cache.OriginalParts = {}
end

-- Player Added Handler
local function onPlayerAdded(player)
    if player ~= LocalPlayer then
        player.CharacterAdded:Connect(function()
            if Config.HitboxEnabled then
                task.wait(0.5)
                UpdateHitboxes()
            end
        end)
    end
end

-- Connect events
LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
Players.PlayerAdded:Connect(onPlayerAdded)

-- Initialize existing players
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        onPlayerAdded(player)
    end
end

-- Auto-Green Input Handler
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and Config.AutoGreen and input.KeyCode == Enum.KeyCode.E then
        task.wait(0.44)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
    end
end)

-- Main Render Loop
RunService.Heartbeat:Connect(function()
    -- Get current character
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    
    if not character or not humanoid or not rootPart then return end
    
    -- Speed Hack
    if Config.SpeedEnabled then
        local moveDirection = humanoid.MoveDirection
        
        if moveDirection.Magnitude > 0 then
            if Config.SpeedMode == "CFrame" then
                rootPart.CFrame = rootPart.CFrame + moveDirection * (Config.SpeedPower / 60)
            elseif Config.SpeedMode == "Velocity" then
                local currentVelocity = rootPart.Velocity
                local targetVelocity = moveDirection * Config.SpeedPower * 10
                rootPart.Velocity = Vector3.new(
                    targetVelocity.X,
                    currentVelocity.Y,
                    targetVelocity.Z
                )
            elseif Config.SpeedMode == "WalkSpeed" then
                humanoid.WalkSpeed = Config.SpeedPower
            end
        elseif Config.SpeedMode ~= "WalkSpeed" then
            humanoid.WalkSpeed = 16
        end
    else
        humanoid.WalkSpeed = 16
    end
    
    -- Enhanced Anti-Contest
    if Config.AntiContest then
        -- Check if contested
        local contested = false
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
                if targetRoot then
                    local distance = (targetRoot.Position - rootPart.Position).Magnitude
                    if distance < Config.RingRadius then
                        contested = true
                        break
                    end
                end
            end
        end
        
        if contested then
            -- Apply selected anti-contest mode
            if Config.AntiContestMode == "Jitter" then
                JitterAntiContest(rootPart)
            elseif Config.AntiContestMode == "Teleport" then
                TeleportAntiContest(rootPart)
            elseif Config.AntiContestMode == "Phase" then
                PhaseAntiContest(rootPart)
            elseif Config.AntiContestMode == "Launch" then
                LaunchAntiContest(rootPart)
            end
        end
    end
    
    -- Auto Defense System
    if Config.AutoDefense then
        local currentTime = tick()
        if currentTime - Cache.LastDefenseTime >= Config.DefenseCooldown then
            local threats = CheckThreats()
            Cache.NearbyThreats = threats
            
            if #threats > 0 then
                if Config.DefenseMode == "Shield" then
                    PerformShieldDefense()
                elseif Config.DefenseMode == "Dodge" then
                    PerformDodgeDefense()
                elseif Config.DefenseMode == "Counter" then
                    PerformCounterDefense()
                end
                
                Cache.LastDefenseTime = currentTime
            end
        end
    end
    
    -- Auto Collect Unlockables
    if Config.AutoCollect then
        local currentTime = tick()
        if currentTime - Cache.LastUnlockTime >= Config.UnlockInterval then
            CollectNearestUnlockables()
            Cache.LastUnlockTime = currentTime
        end
    end
    
    -- Auto Claim GUI Rewards
    if Config.AutoClaim then
        for _, gui in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
            if gui:IsA("TextButton") or gui:IsA("ImageButton") then
                local text = gui.Text and gui.Text:lower() or ""
                if text:find("claim") or text:find("collect") or text:find("redeem") then
                    if gui.Visible and gui.Active and not Cache.UnlockedItems[gui] then
                        fireclickdetector(gui)
                        Cache.UnlockedItems[gui] = true
                        task.wait(0.2)
                    end
                end
            end
        end
    end
    
    -- Ring Logic
    if Config.RingEnabled and Cache.Ring and Cache.RingLabel then
        Cache.Ring.CFrame = rootPart.CFrame * CFrame.new(0, -2.8, 0) * CFrame.Angles(0, 0, math.rad(90))
        
        local contested = false
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
                if targetRoot then
                    local distance = (targetRoot.Position - rootPart.Position).Magnitude
                    if distance < Config.RingRadius then
                        contested = true
                        break
                    end
                end
            end
        end
        
        Cache.RingLabel.Text = contested and "CONTESTED" or "OPEN"
        Cache.RingLabel.TextColor3 = contested and Config.ContestedColor or Config.RingColor
        Cache.Ring.BrickColor = contested and BrickColor.new("Really red") or BrickColor.new("Lime green")
    end
end)

-- Cleanup on script unload
LocalPlayer.OnTeleport:Connect(function()
    CleanupCache()
end)

-- Success Notification
Rayfield:Notify({
    Title = "NASA HUB v1-beta.28",
    Content = "Loaded! Unlock All + Enhanced Anti-Contest",
    Duration = 3
})
