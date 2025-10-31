--!optimize 2

--[[
	apply default surfaces
	applies default surfaces to the currently selected part(s)
]]

local update_surface = require("../update_surface")
local plugtilly = require("../packages/plugtilly")
local info = require("../info")
local Selection = game:GetService("Selection")

local FEATURE_BUTTON = info.apply_default_surfaces_button
local plugin = info.plugin

FEATURE_BUTTON:on_trigger(function()
	local finish_recording = plugtilly.create_recording(plugin, "Apply Default Surfaces to selected part(s)")

	for _, instance in Selection:Get() do
		if instance:IsA("BasePart") then
			instance.RightSurface = Enum.SurfaceType.Smooth
			instance.FrontSurface = Enum.SurfaceType.Smooth
			instance.BottomSurface = Enum.SurfaceType.Smooth
			instance.LeftSurface = Enum.SurfaceType.Smooth
			instance.BackSurface = Enum.SurfaceType.Smooth
			instance.TopSurface = Enum.SurfaceType.Smooth
			update_surface(instance, "RightSurface", nil)
			update_surface(instance, "FrontSurface", nil)
			update_surface(instance, "BottomSurface", Enum.SurfaceType.Inlet)
			update_surface(instance, "LeftSurface", nil)
			update_surface(instance, "BackSurface", nil)
			update_surface(instance, "TopSurface", Enum.SurfaceType.Studs)
		end
	end
	finish_recording(Enum.FinishRecordingOperation.Commit)
end)

return nil
