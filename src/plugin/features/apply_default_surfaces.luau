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

local function apply_default_surfaces_for_part(part: BasePart)
	part.RightSurface = Enum.SurfaceType.Smooth
	part.FrontSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.LeftSurface = Enum.SurfaceType.Smooth
	part.BackSurface = Enum.SurfaceType.Smooth
	part.TopSurface = Enum.SurfaceType.Smooth
	update_surface(part, "RightSurface", nil)
	update_surface(part, "FrontSurface", nil)
	update_surface(part, "BottomSurface", Enum.SurfaceType.Inlet)
	update_surface(part, "LeftSurface", nil)
	update_surface(part, "BackSurface", nil)
	update_surface(part, "TopSurface", Enum.SurfaceType.Studs)
end

FEATURE_BUTTON:on_trigger(function()
	local finish_recording = plugtilly.create_recording(plugin, "Apply Default Surfaces to selected part(s)")

	for _, instance in Selection:Get() do
		if instance:IsA("BasePart") then
			apply_default_surfaces_for_part(instance)
		end

		for _, descendant in instance:GetDescendants() do
			if descendant:IsA("BasePart") then
				apply_default_surfaces_for_part(descendant)
			end
		end
	end
	finish_recording(Enum.FinishRecordingOperation.Commit)
end)

return nil
