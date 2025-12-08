local fishFolder = script.Parent:WaitForChild("Fish")
local RarityModule = require(fishFolder:WaitForChild("Rarities"))
local Rarities = RarityModule.Rarities or RarityModule
local LocationModule = require(fishFolder:WaitForChild("Locations"))
local FishList = require(fishFolder:WaitForChild("FishList"))

local locations = LocationModule.Locations or {}

return {
    Rarities = Rarities,
    Locations = locations,
    DefaultLocation = LocationModule.DefaultLocation or next(locations) or "Shores",
    Fish = FishList,
}
