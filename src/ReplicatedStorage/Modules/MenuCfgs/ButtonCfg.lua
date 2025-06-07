-- ReplicatedStorage > Modules > MenuCfgs > ButtonCfg.lua

local ButtonCfg = {
	MainMenu = {
		{ Name = "1 - Play",      Image = "rbxassetid://111398819789021", ImageColor = Color3.fromRGB(255,255,255), HoverColor = Color3.fromRGB(220,220,255) },
		{ Name = "2 - Customize", Image = "rbxassetid://107534689617080", ImageColor = Color3.fromRGB(255,255,255), HoverColor = Color3.fromRGB(200,200,255) },
		{ Name = "3 - Shop",      Image = "rbxassetid://79085581388954",  ImageColor = Color3.fromRGB(255,255,255), HoverColor = Color3.fromRGB(255,200,200) },
		{ Name = "4 - Settings",  Image = "rbxassetid://YOUSETTINGS_IMG", ImageColor = Color3.fromRGB(255,255,255), HoverColor = Color3.fromRGB(200,255,200) }
	},
        Selection = {
                { Name = "1 - BasicCombat", Image = "rbxassetid://128114491023651", ImageColor = Color3.fromRGB(255,255,255), HoverColor = Color3.fromRGB(200,255,255) },
                { Name = "2 - BlackLeg",    Image = "rbxassetid://135812261993733", ImageColor = Color3.fromRGB(255,255,255), HoverColor = Color3.fromRGB(255,200,255) },
                { Name = "3 - Rokushiki",   Image = "rbxassetid://128114491023651", ImageColor = Color3.fromRGB(255,255,255), HoverColor = Color3.fromRGB(255,255,200) },
                -- Add more as needed!
        },
	Shop = {
		{ Name = "1 - Swords",         Image = "rbxassetid://00000000000001", ImageColor = Color3.fromRGB(255,255,255), HoverColor = Color3.fromRGB(240,240,200) },
		{ Name = "2 - Fighting Styles",Image = "rbxassetid://00000000000002", ImageColor = Color3.fromRGB(255,255,255), HoverColor = Color3.fromRGB(200,240,240) },
		{ Name = "3 - Fruits",         Image = "rbxassetid://00000000000003", ImageColor = Color3.fromRGB(255,255,255), HoverColor = Color3.fromRGB(255,255,200) }
	}
}
return ButtonCfg
