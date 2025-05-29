getgenv().settings = {
    autoattack = false,
    minWait = 0.00001,
    maxWait = 0.00005,
    precision = 0.00001
}

local fov = 60
local predictionFactor = 0.1
local enemyDetectedColor = Color3.fromRGB(255, 0, 0)
local aimbotEnabled = false

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- واجهة المستخدم
local screenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
screenGui.ResetOnSpawn = false

local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0, 150, 0, 40)
frame.Position = UDim2.new(0.5, -75, 0.1, 0)
frame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
frame.Active = true
frame.Draggable = true

local toggleButton = Instance.new("TextButton", frame)
toggleButton.Size = UDim2.new(1, 0, 1, 0)
toggleButton.BackgroundColor3 = Color3.fromRGB(128, 128, 128)
toggleButton.BackgroundTransparency = 0.2
toggleButton.Text = "الأيمبوت معطّل"

-- دائرة FOV
local FOVring = Drawing.new("Circle")
FOVring.Visible = false
FOVring.Thickness = 2
FOVring.Color = Color3.fromRGB(128, 0, 128)
FOVring.Filled = false
FOVring.Radius = fov
FOVring.Position = camera.ViewportSize / 2

RunService.RenderStepped:Connect(function()
    if aimbotEnabled then
        FOVring.Visible = true
        FOVring.Position = camera.ViewportSize / 2
    else
        FOVring.Visible = false
    end
end)

-- كشف الأعداء
local function isEnemy(player)
    return player.Team == nil or localPlayer.Team == nil or player.Team ~= localPlayer.Team
end

local function isAlive(player)
    return player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0
end

local function isPartVisible(part)
    local origin = camera.CFrame.Position
    local direction = (part.Position - origin).Unit
    local distance = (part.Position - origin).Magnitude

    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {localPlayer.Character, part.Parent}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.IgnoreWater = true

    local raycastResult = Workspace:Raycast(origin, direction * distance, raycastParams)
    return not raycastResult
end

local function isWithinFov(targetPosition)
    local screenCenter = camera.ViewportSize / 2
    local targetScreenPos, onScreen = camera:WorldToViewportPoint(targetPosition)
    if not onScreen then return false end
    local dx, dy = targetScreenPos.X - screenCenter.X, targetScreenPos.Y - screenCenter.Y
    local distanceFromCenter = math.sqrt(dx * dx + dy * dy)
    return distanceFromCenter <= fov
end

local function getClosestVisibleEnemy()
    local bestHitbox, closestDistance = nil, math.huge
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= localPlayer and isEnemy(player) and isAlive(player) then
            local head = player.Character:FindFirstChild("Head")
            if head and isPartVisible(head) and isWithinFov(head.Position) then
                local distance = (head.Position - localPlayer.Character.HumanoidRootPart.Position).Magnitude
                if distance < closestDistance then
                    closestDistance = distance
                    bestHitbox = head
                end
            end
        end
    end
    return bestHitbox
end

local function predictMovement(hitbox)
    return hitbox.Position + (hitbox.Velocity * predictionFactor)
end

-- زر التبديل
toggleButton.MouseButton1Click:Connect(function()
    aimbotEnabled = not aimbotEnabled
    toggleButton.Text = aimbotEnabled and "الأيمبوت مفعّل" or "الأيمبوت معطّل"
end)

-- التصويب التلقائي
RunService.RenderStepped:Connect(function()
    if aimbotEnabled then
        local targetHitbox = getClosestVisibleEnemy()
        if targetHitbox then
            local targetPosition = predictMovement(targetHitbox)
            local currentPosition = camera.CFrame.Position
            local smoothFactor = 0.2
            camera.CFrame = CFrame.new(currentPosition, targetPosition):Lerp(CFrame.new(currentPosition, targetPosition), smoothFactor)
        end
    end
end)

-- تنبيه
game.StarterGui:SetCore("SendNotification", {
    Title = "vip v3.7",
    Text = "xxxxxthefox",
    Icon = "rbxassetid://115469660765124",
    Duration = 20
})
