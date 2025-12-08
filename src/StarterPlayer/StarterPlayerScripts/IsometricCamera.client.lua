local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
-- Temporarily allow default camera controls; isometric lock can be re-enabled later.
camera.CameraType = Enum.CameraType.Custom
camera.FieldOfView = 70
