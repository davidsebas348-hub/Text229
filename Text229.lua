local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local bodyPos, bodyGyro, target

-- Valores por defecto
_G.MAX_RANGE = _G.MAX_RANGE or 25
_G.FOLLOW_DISTANCE = _G.FOLLOW_DISTANCE or 4

-- Toggle global
if _G.AutoFollowEnabled == nil then
    _G.AutoFollowEnabled = true
else
    -- Si ya existe, invertir toggle
    _G.AutoFollowEnabled = not _G.AutoFollowEnabled
end

-- ===== ELIMINAR INSTANCIAS PREVIAS =====
if _G.__AutoFollowHeartbeat then
    _G.__AutoFollowHeartbeat:Disconnect()
    _G.__AutoFollowHeartbeat = nil
end
if _G.__AutoFollowBodyPos then
    _G.__AutoFollowBodyPos:Destroy()
    _G.__AutoFollowBodyPos = nil
end
if _G.__AutoFollowBodyGyro then
    _G.__AutoFollowBodyGyro:Destroy()
    _G.__AutoFollowBodyGyro = nil
end

-- ===== FUNCIONES =====
local function getRandomTarget()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local targets = {}
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("HumanoidRootPart") then
            local objHRP = obj.HumanoidRootPart
            local player = Players:GetPlayerFromCharacter(obj)
            if player ~= LocalPlayer or not player then
                local distance = (objHRP.Position - hrp.Position).Magnitude
                if distance <= (_G.MAX_RANGE or 25) then
                    table.insert(targets, objHRP)
                end
            end
        end
    end

    if #targets > 0 then
        return targets[math.random(1, #targets)]
    end
    return nil
end

local function setupBody(character)
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if not bodyPos then
        bodyPos = Instance.new("BodyPosition")
        bodyPos.MaxForce = Vector3.new(1e4, 1e4, 1e4)
        bodyPos.D = 10
        bodyPos.P = 3000
        bodyPos.Parent = hrp
        _G.__AutoFollowBodyPos = bodyPos
    end

    if not bodyGyro then
        bodyGyro = Instance.new("BodyGyro")
        bodyGyro.MaxTorque = Vector3.new(2e4, 2e4, 2e4)
        bodyGyro.D = 10
        bodyGyro.P = 3000
        bodyGyro.Parent = hrp
        _G.__AutoFollowBodyGyro = bodyGyro
    end
end

local function removeBody()
    if bodyPos then bodyPos:Destroy(); bodyPos = nil end
    if bodyGyro then bodyGyro:Destroy(); bodyGyro = nil end
    target = nil
end

-- ===== HEARTBEAT =====
_G.__AutoFollowHeartbeat = RunService.Heartbeat:Connect(function()
    if not _G.AutoFollowEnabled then
        removeBody()
        return
    end

    local liveFolder = Workspace:FindFirstChild("Live")
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not char or not hrp then
        removeBody()
        return
    end

    local myModel = liveFolder and liveFolder:FindFirstChild(LocalPlayer.Name)

    if myModel and myModel:FindFirstChild("M1ing") then
        if not target or not target.Parent or (target.Position - hrp.Position).Magnitude > (_G.MAX_RANGE or 25) then
            target = getRandomTarget()
        end

        if target then
            setupBody(char)
            local distance = (target.Position - hrp.Position).Magnitude
            if distance > (_G.FOLLOW_DISTANCE or 4) then
                local direction = (target.Position - hrp.Position).Unit
                local followPos = target.Position - direction * (_G.FOLLOW_DISTANCE or 4)
                bodyPos.Position = followPos
                bodyGyro.CFrame = CFrame.new(hrp.Position, target.Position)
            else
                bodyPos.Position = hrp.Position
            end
        else
            removeBody()
        end
    else
        removeBody()
    end
end)
