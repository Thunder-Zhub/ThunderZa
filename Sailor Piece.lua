local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- [[ SERVICES ]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- [[ CONFIGURATION ]]
local ICON_ID = "rbxassetid://129491563059955"
local CurrentTarget = nil 

-- [[ 1. CLEANUP OLD UI ]]
if CoreGui:FindFirstChild("ThunderToggleGui") then CoreGui.ThunderToggleGui:Destroy() end
if CoreGui:FindFirstChild("ThunderLoading") then CoreGui.ThunderLoading:Destroy() end

-- [[ 2. LOADING SCREEN ]]
local function runLoadingScreen()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ThunderLoading"
    ScreenGui.Parent = CoreGui
    ScreenGui.DisplayOrder = 999

    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(1, 0, 1, 0)
    MainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    MainFrame.BackgroundTransparency = 1
    MainFrame.Parent = ScreenGui

    local Icon = Instance.new("ImageLabel")
    Icon.Size = UDim2.fromOffset(100, 100)
    Icon.Position = UDim2.new(0.5, -50, 0.45, -50)
    Icon.BackgroundTransparency = 1
    Icon.Image = ICON_ID
    Icon.ImageTransparency = 1
    Icon.Parent = MainFrame

    TweenService:Create(MainFrame, TweenInfo.new(0.5), {BackgroundTransparency = 0.6}):Play()
    TweenService:Create(Icon, TweenInfo.new(0.5), {ImageTransparency = 0.1}):Play()

    task.spawn(function()
        while MainFrame.Parent do
            Icon.Rotation = Icon.Rotation + 3
            task.wait()
        end
    end)

    task.wait(2) 
    ScreenGui:Destroy()
end

runLoadingScreen()

-- [[ 3. MAIN WINDOW ]]
local Window = Fluent:CreateWindow({
    Title = "THUNDER Z HUB | Sailor Piece 0.1",
    SubTitle = "by Thunder", 
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = false, 
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl 
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "home" }),
    Stats = Window:AddTab({ Title = "Stats", Icon = "bar-chart" }),
    FPSBoost = Window:AddTab({ Title = "FPS Boost", Icon = "zap" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local Options = Fluent.Options

-- [[ 4. TOGGLE BUTTON ]]
do
    local ScreenGui = Instance.new("ScreenGui")
    local ToggleButton = Instance.new("ImageButton")
    ScreenGui.Name = "ThunderToggleGui"
    ScreenGui.Parent = CoreGui
    ToggleButton.Name = "ToggleButton"
    ToggleButton.Parent = ScreenGui
    ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    ToggleButton.BackgroundTransparency = 0.5
    ToggleButton.Position = UDim2.new(0.05, 0, 0.2, 0)
    ToggleButton.Size = UDim2.fromOffset(45, 45)
    ToggleButton.Image = ICON_ID
    Instance.new("UICorner", ToggleButton).CornerRadius = UDim.new(0, 12)
    ToggleButton.Draggable = true
    ToggleButton.Active = true
    ToggleButton.MouseButton1Click:Connect(function() Window:Minimize() end)
end

-- [[ 5. GAME LOGIC ]]
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local LevelValue = LocalPlayer:WaitForChild("Data"):WaitForChild("Level")
local QuestRemote = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("QuestAccept")
local HitRemote = ReplicatedStorage:WaitForChild("CombatSystem"):WaitForChild("Remotes"):WaitForChild("RequestHit")
local StatRemote = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("AllocateStat")

local function setAnchor(state)
    local character = LocalPlayer.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        character.HumanoidRootPart.Anchored = state
    end
end

local function getTargetMob()
    if CurrentTarget and CurrentTarget.Parent and CurrentTarget:FindFirstChild("Humanoid") and CurrentTarget.Humanoid.Health > 0 then
        return CurrentTarget
    end

    local lvl = LevelValue.Value
    local mobs = workspace:WaitForChild("NPCs"):GetChildren()
    for _, mob in pairs(mobs) do
        if mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 and mob:FindFirstChild("HumanoidRootPart") then
            local name = mob.Name
            if (lvl <= 99 and string.find(name, "Thief") and not string.find(name, "Boss")) or
               (lvl >= 100 and lvl <= 249 and name == "ThiefBoss") or
               (lvl >= 250 and lvl <= 499 and string.find(name, "Monkey") and not string.find(name, "Boss")) or
               (lvl >= 500 and lvl <= 749 and name == "MonkeyBoss") or
               (lvl >= 750 and lvl <= 999 and string.find(name, "DesertBandit") and not string.find(name, "Boss")) or
               (lvl >= 1000 and lvl <= 1499 and name == "DesertBoss") or
               (lvl >= 1500 and lvl <= 1999 and string.find(name, "FrostRogue")) or
               (lvl >= 2000 and name == "SnowBoss") then
                CurrentTarget = mob
                return mob
            end
        end
    end
    CurrentTarget = nil
    return nil
end

-- [[ AUTO FARM ]]
Tabs.Main:AddToggle("AutoFarm", { Title = "Auto Farm", Default = false }):OnChanged(function()
    task.spawn(function()
        while Options.AutoFarm.Value do
            local char = LocalPlayer.Character
            
            -- [[ ตรวจสอบการตาย และรอ 10 วินาที ]]
            if not char or not char:FindFirstChild("Humanoid") or char.Humanoid.Health <= 0 then
                setAnchor(false)
                CurrentTarget = nil
                -- รอจนกว่าตัวละครจะเกิดใหม่
                repeat task.wait(1) until LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") and LocalPlayer.Character.Humanoid.Health > 0
                -- เมื่อเกิดแล้ว ให้รออีก 5 วินาทีตามที่สั่ง
                task.wait(5) 
                char = LocalPlayer.Character -- อัปเดตตัวแปรตัวละครใหม่
            end

            local hasQuest = PlayerGui:FindFirstChild("QuestUI") and PlayerGui.QuestUI.Quest.Visible
            
            if not hasQuest then
                CurrentTarget = nil
                local lvl = LevelValue.Value
                local targetNPC = "QuestNPC1"
                if lvl <= 99 then targetNPC = "QuestNPC1"
                elseif lvl <= 249 then targetNPC = "QuestNPC2"
                elseif lvl <= 499 then targetNPC = "QuestNPC3"
                elseif lvl <= 749 then targetNPC = "QuestNPC4"
                elseif lvl <= 999 then targetNPC = "QuestNPC5"
                elseif lvl <= 1499 then targetNPC = "QuestNPC6"
                elseif lvl >= 1500 and lvl <= 1999 then targetNPC = "QuestNPC7"
                elseif lvl >= 2000 then targetNPC = "QuestNPC8" end

                local npc = workspace.ServiceNPCs:FindFirstChild(targetNPC)
                if npc and char:FindFirstChild("HumanoidRootPart") then
                    char.HumanoidRootPart.CFrame = npc:GetModelCFrame() * CFrame.new(0, 0, 3)
                    task.wait(0.3)
                    setAnchor(true)
                    QuestRemote:FireServer(targetNPC)
                    task.wait(0.5)
                    setAnchor(false)
                end
            else
                local target = getTargetMob()
                if target and char:FindFirstChild("HumanoidRootPart") then
                    repeat
                        if not Options.AutoFarm.Value or not target.Parent or target.Humanoid.Health <= 0 or char.Humanoid.Health <= 0 then break end
                        
                        char.HumanoidRootPart.CFrame = target.HumanoidRootPart.CFrame * CFrame.new(0, 0, 4)
                        
                        if not char:FindFirstChildOfClass("Tool") then
                            local tool = LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
                            if tool then char.Humanoid:EquipTool(tool) end
                        end

                        for i = 1, 10 do 
                            if target.Humanoid.Health <= 0 then break end
                            HitRemote:FireServer()
                        end
                        task.wait(0.05) 
                    until target.Humanoid.Health <= 0 or not Options.AutoFarm.Value or char.Humanoid.Health <= 0
                    CurrentTarget = nil
                end
            end
            task.wait(0.2) 
        end
        setAnchor(false)
    end)
end)

-- [[ STATS, FPS & OTHERS ]]
Tabs.Stats:AddDropdown("StatSelect", { Title = "Select Stat", Values = {"Melee", "Defense", "Sword", "Power"}, Default = 1 })
Tabs.Stats:AddToggle("AutoStat", { Title = "Auto Stat", Default = false }):OnChanged(function()
    task.spawn(function()
        while Options.AutoStat.Value do
            for i = 1, 5 do StatRemote:FireServer(Options.StatSelect.Value, 1) end
            task.wait(1)
        end
    end)
end)

Tabs.Settings:AddSlider("AttackBurstCount", { Title = "Attack Speed (Visual Only)", Default = 50, Min = 1, Max = 100, Rounding = 0 })

Tabs.FPSBoost:AddButton({ Title = "Optimize Graphics", Callback = function()
    settings().Rendering.QualityLevel = 1
    for _, v in pairs(game:GetDescendants()) do
        if v:IsA("Part") then v.Material = Enum.Material.SmoothPlastic
        elseif v:IsA("Texture") or v:IsA("Decal") then v:Destroy() end
    end
end})

LocalPlayer.Idled:Connect(function()
    game:GetService("VirtualUser"):CaptureController()
    game:GetService("VirtualUser"):ClickButton2(Vector2.zero)
end)

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:SetFolder("ThunderZHub/SailorPiece")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)
Window:SelectTab(1)