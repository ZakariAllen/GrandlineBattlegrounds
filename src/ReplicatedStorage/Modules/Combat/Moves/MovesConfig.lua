local Moves = {}

local folder = script.Parent

-- Collect module scripts first so we can load them in a deterministic order
local moduleScripts = {}
for _, obj in ipairs(folder:GetChildren()) do
    if obj:IsA("ModuleScript") and obj ~= script then
        table.insert(moduleScripts, obj)
    end
end

table.sort(moduleScripts, function(a, b)
    return a.Name < b.Name
end)

for _, moduleScript in ipairs(moduleScripts) do
    local ok, mod = pcall(require, moduleScript)
    if ok and type(mod) == "table" then
        table.insert(Moves, mod)
    end
end

return Moves
