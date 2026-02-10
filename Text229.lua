local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local bodyPos, bodyGyro
local target

-- Valores por defecto (se pueden modificar desde TextBox)
_G.MAX_RANGE = _G.MAX_RANGE or 25
_G.FOLLOW_DISTANCE = _G.FOLLOW_DISTANCE or 4

-- Función para obtener un objetivo aleatorio dentro del rango
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

-- Crear BodyPosition y BodyGyro si no existen
local function setupBody(character)
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if not bodyPos then
        bodyPos = Instance.new("BodyPosition")
        bodyPos.MaxForce = Vector3.new(1e4, 1e4, 1e4)
        bodyPos.D = 10
        bodyPos.P = 3000
        bodyPos.Parent = hrp
    end

    if not bodyGyro then
        bodyGyro = Instance.new("BodyGyro")
        bodyGyro.MaxTorque = Vector3.new(2e4, 2e4, 2e4)
        bodyGyro.D = 10
        bodyGyro.P = 3000
        bodyGyro.Parent = hrp
    end
end

-- Eliminar BodyPosition y BodyGyro
local function removeBody()
    if bodyPos then bodyPos:Destroy(); bodyPos = nil end
    if bodyGyro then bodyGyro:Destroy(); bodyGyro = nil end
    target = nil
end

-- Loop principal
RunService.Heartbeat:Connect(function()
    local liveFolder = Workspace:FindFirstChild("Live")
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not char or not hrp then
        removeBody()
        return
    end

    local myModel = liveFolder and liveFolder:FindFirstChild(LocalPlayer.Name)

    if myModel and myModel:FindFirstChild("M1ing") then
        -- Tenemos M1ing
        if not target or not target.Parent or (target.Position - hrp.Position).Magnitude > (_G.MAX_RANGE or 25) then
            target = getRandomTarget()
        end

        if target then
            setupBody(char)
            local distance = (target.Position - hrp.Position).Magnitude
            if distance > (_G.FOLLOW_DISTANCE or 4) then
                local direction = (target.Position - hrp.Position).Unit
                local followPos = target.Position - direction * (_G.FOLLOW_DISTANCE or 4) + Vector3.new(0, 1.5, 0)
                bodyPos.Position = followPos
                bodyGyro.CFrame = CFrame.new(hrp.Position, target.Position)
            else
                -- A distancia de seguimiento, quedarnos tranquilos
                bodyPos.Position = hrp.Position
            end
        else
            -- No hay objetivos dentro del rango
            removeBody()
        end
    else
        -- No tenemos M1ing
        removeBody()
    end
end)
