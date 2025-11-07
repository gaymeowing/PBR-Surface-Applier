--!optimize 2

--[[
	convert place to pbr surfaces
	converts all Roblox Surfaces in the current place to PBR Surfaces
]]

local plugtilly = require("../packages/plugtilly")
local pbr_surfaces = require("../../pbr_surfaces")
local info = require("../info")

local FEATURE_BUTTON = info.convert_place_to_pbr_surfaces
local plugin = info.plugin

FEATURE_BUTTON:on_trigger(function()
	local finish_recording = plugtilly.create_recording(plugin, "Convert Place to PBR Surfaces")
	FEATURE_BUTTON:set_enabled(false)
	FEATURE_BUTTON:set_active(true)

	for _, part: BasePart in game:QueryDescendants("BasePart") do
		if part.ClassName ~= "Terrain" then
			pbr_surfaces.convert_roblox_surfaces_to_pbr_surfaces(part :: any)
		end
	end

	finish_recording(Enum.FinishRecordingOperation.Commit)
	FEATURE_BUTTON:set_enabled(true)
	FEATURE_BUTTON:set_active(false)
end)

return nil
