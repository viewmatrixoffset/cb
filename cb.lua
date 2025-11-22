local Decimals = 4
local Clock = os.clock()
local ValueText = "Value Is Now :"

local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/drillygzzly/Roblox-UI-Libs/main/1%20Tokyo%20Lib%20(FIXED)/Tokyo%20Lib%20Source.lua"))({
    cheatname = "Omni Services",
    gamename = "Counter Blox",
})

library:init()

local Window1 = library.NewWindow({
    title = "Omni | Counter Blox",
    size = UDim2.new(0, 510, 0.6, 6)
})

local Tab1 = Window1:AddTab(" Combat ")
local VisualsTab = Window1:AddTab(" Visuals ")
local SettingsTab = library:CreateSettingsTab(Window1)

-- services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- combat tab
local CombatSection = Tab1:AddSection("Combat", 1)

-- triggerbot storage
local TriggerbotEnabled = false
local TriggerbotTeamCheck = true
local TriggerbotDelay = 0

-- for tb, to check if we are looking at enemy
local function IsLookingAtEnemy()
    local camera = workspace.CurrentCamera
    if not camera then return false end
    
    local ray = Ray.new(camera.CFrame.Position, camera.CFrame.LookVector * 1000)
    local hit = workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character})
    
    if hit then
        local targetPlayer = Players:GetPlayerFromCharacter(hit.Parent)
        if targetPlayer and targetPlayer ~= LocalPlayer then
            if TriggerbotTeamCheck and LocalPlayer.Team and targetPlayer.Team == LocalPlayer.Team then
                return false
            end
            return true
        end
    end
    return false
end

-- triggerbot buttons
CombatSection:AddToggle({
    text = "Triggerbot",
    state = false,
    tooltip = "Automatically shoot when aiming at enemy",
    flag = "Triggerbot_Enabled",
    risky = true,
    callback = function(v)
        TriggerbotEnabled = v
        print("Triggerbot:", v)
    end
}):AddBind({
    enabled = true,
    text = "Toggle Key",
    tooltip = "Key to toggle triggerbot on/off",
    mode = "toggle",
    bind = "None",
    flag = "Triggerbot_Toggle",
    state = false,
    nomouse = false,
    risky = false,
    noindicator = false,
    callback = function(v)
        TriggerbotEnabled = v
        print("Triggerbot toggled:", v)
    end,
    keycallback = function(v)
        print("Triggerbot key set to:", v)
    end
})

-- team check for tb
CombatSection:AddToggle({
    text = "Team Check",
    state = true,
    tooltip = "Don't shoot teammates",
    flag = "Triggerbot_TeamCheck",
    risky = false,
    callback = function(v)
        TriggerbotTeamCheck = v
        print("Triggerbot Team Check:", v)
    end
})

-- tb delay slider
CombatSection:AddSlider({
    enabled = true,
    text = "Trigger Delay",
    tooltip = "Delay before shooting (ms)",
    flag = "Triggerbot_Delay",
    suffix = "ms",
    dragging = true,
    focused = false,
    min = 0,
    max = 500,
    increment = 10,
    risky = false,
    callback = function(v)
        TriggerbotDelay = v
        print("Triggerbot Delay:", v)
    end
})

-- triggerbot logic
local LastShot = 0
local ShootCooldown = 0.1

RunService.RenderStepped:Connect(function()
    if not TriggerbotEnabled then return end
    
    local currentTime = tick()
    if currentTime - LastShot < ShootCooldown then return end
    
    if IsLookingAtEnemy() then
        if TriggerbotDelay > 0 then
            task.wait(TriggerbotDelay / 1000)
        end
        mouse1press()
        task.wait(0.01)
        mouse1release()
        LastShot = currentTime
    end
end)

-- visuals tab
local VisualsSection = VisualsTab:AddSection("ESP Settings", 1)

-- esp variables (cache & variables)
local Highlights = {} -- cache
local BoxESPs = {} -- cache
local HealthBars = {} -- cache
local HighlightEnabled = false
local BoxESPEnabled = false
local HealthESPEnabled = false
local TeamCheckEnabled = false
local EnemyColor = Color3.fromRGB(255, 0, 0)
local TeamColor = Color3.fromRGB(0, 255, 0)

-- chams
local function CreateHighlight(character)
    if not character then return end
    
    if Highlights[character] then
        pcall(function() Highlights[character]:Destroy() end)
        Highlights[character] = nil
    end
    
    local success, highlight = pcall(function()
        local h = Instance.new("Highlight")
        h.Adornee = character
        h.FillColor = EnemyColor
        h.FillTransparency = 0.5
        h.OutlineTransparency = 0
        h.OutlineColor = Color3.fromRGB(255, 255, 255)
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.Parent = CoreGui
        return h
    end)
    
    if success and highlight then
        Highlights[character] = highlight
        return highlight
    end
    return nil
end

local function RemoveHighlight(character)
    if Highlights[character] then
        pcall(function() Highlights[character]:Destroy() end)
        Highlights[character] = nil
    end
end

local function UpdateAllHighlights()
    if not HighlightEnabled then
        for char, highlight in pairs(Highlights) do
            pcall(function() highlight:Destroy() end)
        end
        Highlights = {}
        return
    end
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local isTeammate = TeamCheckEnabled and LocalPlayer.Team and player.Team and player.Team == LocalPlayer.Team
            
            if isTeammate then
                if player.Character then RemoveHighlight(player.Character) end
            else
                local character = player.Character
                if character and character:FindFirstChild("HumanoidRootPart") then
                    local highlight = Highlights[character]
                    if not highlight or not highlight.Parent then
                        highlight = CreateHighlight(character)
                    end
                    if highlight then highlight.FillColor = EnemyColor end
                else
                    RemoveHighlight(character)
                end
            end
        end
    end
end

-- box esp
local function CreateBoxESP(player)
    if BoxESPs[player] then
        for _, v in pairs(BoxESPs[player]) do pcall(function() v:Remove() end) end
    end
    
    local box = {
        TL = Drawing.new("Line"), TR = Drawing.new("Line"),
        BL = Drawing.new("Line"), BR = Drawing.new("Line"),
        L = Drawing.new("Line"), R = Drawing.new("Line"),
        T = Drawing.new("Line"), B = Drawing.new("Line")
    }
    
    for _, line in pairs(box) do
        line.Visible = false
        line.Thickness = 2
        line.Transparency = 1
    end
    
    BoxESPs[player] = box
    return box
end

local function RemoveBoxESP(player)
    if BoxESPs[player] then
        for _, line in pairs(BoxESPs[player]) do pcall(function() line:Remove() end) end
        BoxESPs[player] = nil
    end
end

local function UpdateBoxESP(player, box)
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") or not character:FindFirstChild("Humanoid") then
        for _, line in pairs(box) do line.Visible = false end
        return
    end
    
    local humanoid = character.Humanoid
    if humanoid.Health <= 0 then
        for _, line in pairs(box) do line.Visible = false end
        return
    end
    
    local camera = workspace.CurrentCamera
    local hrp = character.HumanoidRootPart
    local rootPos, onScreen = camera:WorldToViewportPoint(hrp.Position)
    
    if not onScreen then
        for _, line in pairs(box) do line.Visible = false end
        return
    end
    
    local head = character:FindFirstChild("Head")
    local headPos = head and camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0)) or rootPos
    local legPos = camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
    
    local height = math.abs(headPos.Y - legPos.Y)
    local width = height * 0.5
    local corner = width * 0.25
    
    local x1, y1 = rootPos.X - width * 0.5, headPos.Y
    local x2, y2 = rootPos.X + width * 0.5, legPos.Y
    
    box.TL.From, box.TL.To = Vector2.new(x1, y1), Vector2.new(x1 + corner, y1)
    box.TR.From, box.TR.To = Vector2.new(x2, y1), Vector2.new(x2 - corner, y1)
    box.BL.From, box.BL.To = Vector2.new(x1, y2), Vector2.new(x1 + corner, y2)
    box.BR.From, box.BR.To = Vector2.new(x2, y2), Vector2.new(x2 - corner, y2)
    box.L.From, box.L.To = Vector2.new(x1, y1), Vector2.new(x1, y1 + height * 0.25)
    box.R.From, box.R.To = Vector2.new(x2, y1), Vector2.new(x2, y1 + height * 0.25)
    box.T.From, box.T.To = Vector2.new(x1, y2), Vector2.new(x1, y2 - height * 0.25)
    box.B.From, box.B.To = Vector2.new(x2, y2), Vector2.new(x2, y2 - height * 0.25)
    
    for _, line in pairs(box) do
        line.Color = EnemyColor
        line.Visible = true
    end
end

-- health ESP
local function CreateHealthBar(player)
    if HealthBars[player] then
        for _, v in pairs(HealthBars[player]) do pcall(function() v:Remove() end) end
    end
    
    local healthBar = {
        Outline = Drawing.new("Square"),
        Bar = Drawing.new("Square"),
        Text = Drawing.new("Text")
    }
    
    healthBar.Outline.Visible = false
    healthBar.Outline.Color = Color3.fromRGB(0, 0, 0)
    healthBar.Outline.Thickness = 1
    healthBar.Outline.Filled = false
    
    healthBar.Bar.Visible = false
    healthBar.Bar.Filled = true
    
    healthBar.Text.Visible = false
    healthBar.Text.Color = Color3.fromRGB(255, 255, 255)
    healthBar.Text.Size = 13
    healthBar.Text.Center = true
    healthBar.Text.Outline = true
    
    HealthBars[player] = healthBar
    return healthBar
end

local function RemoveHealthBar(player)
    if HealthBars[player] then
        for _, element in pairs(HealthBars[player]) do pcall(function() element:Remove() end) end
        HealthBars[player] = nil
    end
end

local function UpdateHealthBar(player, healthBar)
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") or not character:FindFirstChild("Humanoid") then
        healthBar.Outline.Visible = false
        healthBar.Bar.Visible = false
        healthBar.Text.Visible = false
        return
    end
    
    local humanoid = character.Humanoid
    if humanoid.Health <= 0 then
        healthBar.Outline.Visible = false
        healthBar.Bar.Visible = false
        healthBar.Text.Visible = false
        return
    end
    
    local camera = workspace.CurrentCamera
    local rootPos, onScreen = camera:WorldToViewportPoint(character.HumanoidRootPart.Position)
    
    if not onScreen then
        healthBar.Outline.Visible = false
        healthBar.Bar.Visible = false
        healthBar.Text.Visible = false
        return
    end
    
    local head = character:FindFirstChild("Head")
    local headPos = head and camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0)) or rootPos
    local legPos = camera:WorldToViewportPoint(character.HumanoidRootPart.Position - Vector3.new(0, 3, 0))
    
    local height = math.abs(headPos.Y - legPos.Y)
    local barWidth = 4
    local barX = rootPos.X - height * 0.25 - barWidth - 5
    
    local healthPercent = humanoid.Health / humanoid.MaxHealth
    local barFillHeight = height * healthPercent
    
    healthBar.Outline.Size = Vector2.new(barWidth + 2, height + 2)
    healthBar.Outline.Position = Vector2.new(barX - 1, headPos.Y - 1)
    healthBar.Outline.Visible = true
    
    healthBar.Bar.Size = Vector2.new(barWidth, barFillHeight)
    healthBar.Bar.Position = Vector2.new(barX, headPos.Y + (height - barFillHeight))
    healthBar.Bar.Color = healthPercent > 0.6 and Color3.fromRGB(0, 255, 0) or healthPercent > 0.3 and Color3.fromRGB(255, 255, 0) or Color3.fromRGB(255, 0, 0)
    healthBar.Bar.Visible = true
    
    healthBar.Text.Text = tostring(math.floor(humanoid.Health))
    healthBar.Text.Position = Vector2.new(barX + barWidth / 2, headPos.Y - 15)
    healthBar.Text.Visible = true
end

-- visuals toggles
VisualsSection:AddToggle({
    text = "Highlight ESP",
    state = false,
    tooltip = "Enable 3D player highlights",
    flag = "Highlight_Enabled",
    risky = false,
    callback = function(v)
        HighlightEnabled = v
        print("Highlight ESP:", v)
        UpdateAllHighlights()
    end
})

VisualsSection:AddToggle({
    text = "Box ESP",
    state = false,
    tooltip = "Enable 2D box ESP",
    flag = "BoxESP_Enabled",
    risky = false,
    callback = function(v)
        BoxESPEnabled = v
        print("Box ESP:", v)
        if not v then
            for player, box in pairs(BoxESPs) do RemoveBoxESP(player) end
        else
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then CreateBoxESP(player) end
            end
        end
    end
})

VisualsSection:AddToggle({
    text = "Health ESP",
    state = false,
    tooltip = "Enable health bar display",
    flag = "HealthESP_Enabled",
    risky = false,
    callback = function(v)
        HealthESPEnabled = v
        print("Health ESP:", v)
        if not v then
            for player, bar in pairs(HealthBars) do RemoveHealthBar(player) end
        else
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then CreateHealthBar(player) end
            end
        end
    end
})

VisualsSection:AddToggle({
    text = "Team Check",
    state = false,
    tooltip = "Don't show ESP on teammates",
    flag = "ESP_TeamCheck",
    risky = false,
    callback = function(v)
        TeamCheckEnabled = v
        print("ESP Team Check:", v)
        UpdateAllHighlights()
    end
})

VisualsSection:AddSeparator({enabled = true, text = "ESP Color"})

VisualsSection:AddColor({
    enabled = true,
    text = "Enemy Color",
    tooltip = "Color for enemies (all ESP)",
    color = Color3.fromRGB(255, 0, 0),
    flag = "ESP_Enemy_Color",
    trans = 0,
    open = false,
    risky = false,
    callback = function(v)
        EnemyColor = v
        print("Enemy Color:", v)
        UpdateAllHighlights()
    end
})

VisualsSection:AddColor({
    enabled = true,
    text = "Team Color",
    tooltip = "Color for teammates (all ESP)",
    color = Color3.fromRGB(0, 255, 0),
    flag = "ESP_Team_Color",
    trans = 0,
    open = false,
    risky = false,
    callback = function(v)
        TeamColor = v
        print("Team Color:", v)
        UpdateAllHighlights()
    end
})

-- if a player leaves etc and to update their positions
local function OnCharacterAdded(character)
    task.wait(0.1)
    if HighlightEnabled then UpdateAllHighlights() end
end

Players.PlayerAdded:Connect(function(player)
    if BoxESPEnabled then CreateBoxESP(player) end
    if HealthESPEnabled then CreateHealthBar(player) end
    player.CharacterAdded:Connect(OnCharacterAdded)
    if player.Character then OnCharacterAdded(player.Character) end
end)

Players.PlayerRemoving:Connect(function(player)
    if player.Character then RemoveHighlight(player.Character) end
    RemoveBoxESP(player)
    RemoveHealthBar(player)
end)

for _, player in pairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        if BoxESPEnabled then CreateBoxESP(player) end
        if HealthESPEnabled then CreateHealthBar(player) end
        if player.Character then OnCharacterAdded(player.Character) end
        player.CharacterAdded:Connect(OnCharacterAdded)
    end
end

-- update loops
local LastESPUpdate = 0
local ESPUpdateInterval = 0.1

RunService.Heartbeat:Connect(function()
    if HighlightEnabled then
        local currentTime = tick()
        if currentTime - LastESPUpdate >= ESPUpdateInterval then
            UpdateAllHighlights()
            LastESPUpdate = currentTime
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if not BoxESPEnabled and not HealthESPEnabled then return end
    
    for player, box in pairs(BoxESPs) do
        if player and player.Parent then
            local isTeammate = TeamCheckEnabled and LocalPlayer.Team and player.Team and player.Team == LocalPlayer.Team
            if isTeammate then
                for _, line in pairs(box) do line.Visible = false end
            else
                UpdateBoxESP(player, box)
            end
        else
            RemoveBoxESP(player)
        end
    end
    
    for player, healthBar in pairs(HealthBars) do
        if player and player.Parent then
            local isTeammate = TeamCheckEnabled and LocalPlayer.Team and player.Team and player.Team == LocalPlayer.Team
            if isTeammate then
                healthBar.Outline.Visible = false
                healthBar.Bar.Visible = false
                healthBar.Text.Visible = false
            else
                UpdateHealthBar(player, healthBar)
            end
        else
            RemoveHealthBar(player)
        end
    end
end)

local Time = (string.format("%."..tostring(Decimals).."f", os.clock() - Clock))
library:SendNotification(("Loaded In "..tostring(Time)), 6)
