-- NPCBrain.lua
-- Controls wandering and combat behaviour for NPCs using existing movesets.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local NPCBrain = {}
NPCBrain.__index = NPCBrain

local Movesets = {
    BlackLeg = require(script.Movesets.BlackLeg),
    Rokushiki = require(script.Movesets.Rokushiki),
    BasicCombat = require(script.Movesets.BasicCombat),
}

--// Utility -----------------------------------------------------------
local function findTarget(myChar, radius)
    local root = myChar:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local closest, dist
    for _, plr in ipairs(Players:GetPlayers()) do
        local char = plr.Character
        local tRoot = char and char:FindFirstChild("HumanoidRootPart")
        if tRoot then
            local d = (tRoot.Position - root.Position).Magnitude
            if d <= radius and (not closest or d < dist) then
                closest, dist = char, d
            end
        end
    end
    return closest
end

local function weightedChoice(list)
    local sum = 0
    for _, opt in ipairs(list) do
        sum += opt.weight
    end
    local r = math.random() * sum
    for _, opt in ipairs(list) do
        r -= opt.weight
        if r <= 0 then
            return opt.name
        end
    end
    return list[#list].name
end

--// Constructor -------------------------------------------------------
function NPCBrain.new(character, movesetName)
    local self = setmetatable({}, NPCBrain)

    self.Character = character
    self.Moveset = Movesets[movesetName]
    self.Target = nil
    self.State = "Wander" -- or "Engage"
    self.LastAction = 0
    self.Attacking = false

    self:chooseNewWanderGoal()
    return self
end

--// Wander behaviour --------------------------------------------------
function NPCBrain:chooseNewWanderGoal()
    local root = self.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local wanderRadius = 40
    local offset = Vector3.new(
        math.random(-wanderRadius, wanderRadius),
        0,
        math.random(-wanderRadius, wanderRadius)
    )
    self.WanderGoal = root.Position + offset
end

function NPCBrain:updateWander(dt)
    local target = findTarget(self.Character, 40)
    if target then
        self.Target = target
        self.State = "Engage"
        return
    end

    local root = self.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local dir = self.WanderGoal - root.Position
    if dir.Magnitude < 3 then
        self:chooseNewWanderGoal()
    else
        root.CFrame = root.CFrame + dir.Unit * dt * 10
    end
end

--// Engage behaviour --------------------------------------------------
function NPCBrain:updateEngage(dt)
    if not self.Target or not self.Target.Parent then
        self.Target = nil
        self.State = "Wander"
        return
    end

    local root = self.Character:FindFirstChild("HumanoidRootPart")
    local tRoot = self.Target:FindFirstChild("HumanoidRootPart")
    if not root or not tRoot then
        self.Target = nil
        self.State = "Wander"
        return
    end

    local dist = (root.Position - tRoot.Position).Magnitude
    if dist > 60 then
        self.Target = nil
        self.State = "Wander"
        return
    end

    if self.Attacking then return end

    self.LastAction += dt
    if self.LastAction < 0.5 then return end
    self.LastAction = 0

    local choice = weightedChoice({
        {name = "attack", weight = 0.4},
        {name = "block", weight = 0.3},
        {name = "dash", weight = 0.3},
    })

    if choice == "attack" then
        self:tryAttack()
    elseif choice == "block" then
        self:tryBlock()
    else
        self:tryDashAway()
    end
end

--// Actions -----------------------------------------------------------
function NPCBrain:tryAttack()
    -- Rely on combat system to enforce any attack cooldowns.
    if not self.Moveset.attack then return end
    self.Attacking = true
    task.spawn(function()
        for i = 1, self.Moveset.comboLength or 5 do
            if not self.Target or not self.Target.Parent then break end
            local hit = self.Moveset.attack(self.Character, self.Target, i)
            if not hit then break end
            if i < (self.Moveset.comboLength or 5) then
                task.wait(self.Moveset.comboDelay or 0.3)
            end
        end
        self.Attacking = false
    end)
end

function NPCBrain:tryBlock()
    -- Blocking uses the shared combat cooldowns.
    if not self.Moveset.block then return end
    self.Moveset.block(self.Character, 1 + math.random())
end

function NPCBrain:tryDashAway()
    -- Dashing uses the shared combat cooldowns.
    if not self.Moveset.dash then return end
    self.Moveset.dash(self.Character)
end

--// Update loop -------------------------------------------------------
function NPCBrain:Start()
    RunService.Heartbeat:Connect(function(dt)
        if self.State == "Wander" then
            self:updateWander(dt)
        else
            self:updateEngage(dt)
        end
    end)
end

return NPCBrain

