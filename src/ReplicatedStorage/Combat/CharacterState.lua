local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ConfigFolder = ReplicatedStorage:WaitForChild("Config")
local CombatConfig = require(ConfigFolder:WaitForChild("Combat"))

local CharacterState = {}
CharacterState.__index = CharacterState

function CharacterState.new(character)
    assert(typeof(character) == "Instance", "CharacterState.new expects an Instance")

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return nil
    end

    local self = setmetatable({}, CharacterState)
    self.Character = character
    self.Humanoid = humanoid
    self.Blocking = false
    self.Destroyed = false
    self.LastAttackTime = 0
    self.Stamina = CombatConfig.Stamina.Max
    self.Connections = {}

    table.insert(self.Connections, character.AncestryChanged:Connect(function(_, parent)
        if not parent then
            self:Destroy()
        end
    end))

    table.insert(self.Connections, humanoid.Died:Connect(function()
        self:Destroy()
    end))

    return self
end

function CharacterState:IsAlive()
    local humanoid = self.Humanoid
    return humanoid ~= nil and humanoid.Health > 0 and humanoid.Parent ~= nil
end

function CharacterState:GetHumanoid()
    return self.Humanoid
end

function CharacterState:GetCharacter()
    return self.Character
end

function CharacterState:GetRootPart()
    local character = self.Character
    if not character then
        return nil
    end

    return character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
end

function CharacterState:IsBlocking()
    return self.Blocking
end

function CharacterState:SetBlocking(isBlocking)
    if isBlocking and not self.Blocking then
        if self.Stamina < CombatConfig.Block.StartCost then
            return false
        end
        self:SpendStamina(CombatConfig.Block.StartCost)
    end

    self.Blocking = isBlocking
    return true
end

function CharacterState:CanAttack(attackType)
    if self.Destroyed or not self:IsAlive() then
        return false, "NotAlive"
    end

    local now = os.clock()
    if now - self.LastAttackTime < CombatConfig.AttackCooldown then
        return false, "Cooldown"
    end

    local cost = CombatConfig.Stamina.AttackCost[attackType]
    if cost and self.Stamina < cost then
        return false, "NoStamina"
    end

    return true
end

function CharacterState:RecordAttack(attackType)
    self.LastAttackTime = os.clock()
    local cost = CombatConfig.Stamina.AttackCost[attackType]
    if cost then
        self:SpendStamina(cost)
    end
end

function CharacterState:SpendStamina(amount)
    self.Stamina = math.max(0, self.Stamina - amount)
end

function CharacterState:RegenerateStamina(dt)
    if self.Destroyed then
        return
    end

    local regen = CombatConfig.Stamina.RegenPerSecond * dt
    if self.Blocking then
        regen -= CombatConfig.Block.StaminaDrainPerSecond * dt
    end

    self.Stamina = math.clamp(self.Stamina + regen, 0, CombatConfig.Stamina.Max)

    if self.Blocking and self.Stamina <= 0 then
        self.Blocking = false
    end
end

function CharacterState:ApplyDamage(amount)
    local humanoid = self.Humanoid
    if not humanoid or amount <= 0 then
        return
    end

    humanoid:TakeDamage(amount)
end

function CharacterState:Destroy()
    if self.Destroyed then
        return
    end

    self.Destroyed = true
    for _, connection in ipairs(self.Connections) do
        connection:Disconnect()
    end

    table.clear(self.Connections)
end

return CharacterState
