local MovesConfig = {}
local folder = script.Parent
for _, obj in ipairs(folder:GetChildren()) do
    if obj:IsA("ModuleScript") and obj ~= script then
        local ok, mod = pcall(require, obj)
        if ok and type(mod) == "table" then
            table.insert(Moves, mod)
        end
    end
end
return MovesConfig
