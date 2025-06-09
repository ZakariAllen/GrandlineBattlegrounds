--ReplicatedStorage.Modules.Effects.AnimationUtils

local AnimationUtils = {}

function AnimationUtils.PlayAnimation(animator: Instance, animId: any, priority: Enum.AnimationPriority?)
    if not animator or not animId then
        return nil
    end

    local id = tostring(animId)
    if not id:match("^rbxassetid://") then
        id = "rbxassetid://" .. id
    end

    local animation = Instance.new("Animation")
    animation.AnimationId = id

    local track = animator:LoadAnimation(animation)
    track.Priority = priority or Enum.AnimationPriority.Action
    track.Looped = false
    track:Play()

    return track
end

return AnimationUtils
