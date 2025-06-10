--ReplicatedStorage.Modules.Effects.AnimationUtils

local AnimationUtils = {}

-- Cache created Animation objects so they can be reused across calls.
local animationCache: {[string]: Animation} = {}

function AnimationUtils.PlayAnimation(animator: Instance, animId: any, priority: Enum.AnimationPriority?)
    if not animator or not animId then
        return nil
    end

    local id = tostring(animId)
    if not id:match("^rbxassetid://") then
        id = "rbxassetid://" .. id
    end

    local animation = animationCache[id]
    if not animation then
        animation = Instance.new("Animation")
        animation.AnimationId = id
        animationCache[id] = animation
    end

    local track = animator:LoadAnimation(animation)
    track.Priority = priority or Enum.AnimationPriority.Action
    track.Looped = false
    track:Play()

    return track
end

return AnimationUtils
