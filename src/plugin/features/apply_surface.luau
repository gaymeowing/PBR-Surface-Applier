--!optimize 2

--[[
	apply surface
	tool for applying a surface to multiple specific surfaces of parts at once
]]

local pbr_surfaces = require("../../pbr_surfaces")
local plugtilly = require("../packages/plugtilly")
local info = require("../info")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local AUTO_APPLY_SURFACES_FEATURE_INFO = info.auto_apply_surfaces
local AUTO_APPLY_SURFACES_BUTTON = AUTO_APPLY_SURFACES_FEATURE_INFO.button
local OTHER_FEATURE_BUTTONS = table.freeze({
	info.convert_place_to_pbr_surfaces, info.apply_default_surfaces_button,
	AUTO_APPLY_SURFACES_BUTTON
})
local SURFACE_SELECTION = Instance.new("SurfaceSelection")
local STUDIO_SETTINGS = settings().Studio
local SELECTION_HAS_ADORNEE = false

local FEATURE_INFO = info.apply_surface
local FEATURE_BUTTON = FEATURE_INFO.button
local plugin = info.plugin

local function NORMAL_ID_TO_SURFACE_NORMAL(normal_id: Enum.NormalId): pbr_surfaces.SurfaceNormal
	return if normal_id == Enum.NormalId.Right then
			"RightSurface"
		elseif normal_id == Enum.NormalId.Top then
			"TopSurface"
		elseif normal_id == Enum.NormalId.Back then
			"BackSurface"
		elseif normal_id == Enum.NormalId.Left then
			"LeftSurface"
		elseif normal_id == Enum.NormalId.Bottom then
			"BottomSurface"
		else
			"FrontSurface"
end

local function ON_ACTION_TRIGGERED(action: PluginAction, surface: Enum.SurfaceType)
	local recording_action = `Apply Surface '{surface.Name}'`

	action.Triggered:Connect(function()
		for _, plugin_button in OTHER_FEATURE_BUTTONS do
			plugin_button:set_enabled(false)
			plugin_button:set_active(false)
		end

		FEATURE_BUTTON:set_active(true)
		plugin:Activate(true)

		local mouse = plugin:GetMouse()
		mouse.TargetFilter = SURFACE_SELECTION

		local move_connection = RunService.PostSimulation:Connect(function()
			local target = mouse.Target

			if target then
				SURFACE_SELECTION.TargetSurface = mouse.TargetSurface
				SURFACE_SELECTION.Adornee = target
				SELECTION_HAS_ADORNEE = true
			elseif SELECTION_HAS_ADORNEE then
				SURFACE_SELECTION.Adornee = nil
				SELECTION_HAS_ADORNEE = false
			end
		end)

		local click_connection = mouse.Button1Up:Connect(function()
			local target = mouse.Target

			if not target then
				return
			end

			local finish_recording = plugtilly.create_recording(plugin, recording_action)
			local target_surface_normal = pbr_surfaces.normal_id_to_surface_normal(mouse.TargetSurface)

			;(target :: any)[target_surface_normal] = Enum.SurfaceType.Smooth
			pbr_surfaces.update_surface(target, target_surface_normal, surface)
			finish_recording(Enum.FinishRecordingOperation.Commit)
		end)

		plugin.Deactivation:Once(function()
			if AUTO_APPLY_SURFACES_FEATURE_INFO.active then
				AUTO_APPLY_SURFACES_BUTTON:set_active(true)
			end

			for _, plugin_button in OTHER_FEATURE_BUTTONS do
				plugin_button:set_enabled(true)
			end

			FEATURE_BUTTON:set_active(false)
			SURFACE_SELECTION.Adornee = nil
			click_connection:Disconnect()
			move_connection:Disconnect()
			mouse:Destroy()
		end)
	end)
end

STUDIO_SETTINGS:GetPropertyChangedSignal("Active Color"):Connect(function()
	SURFACE_SELECTION.Color3 = STUDIO_SETTINGS["Active Color"]
end)
SURFACE_SELECTION.Color3 = STUDIO_SETTINGS["Active Color"]
SURFACE_SELECTION.Archivable = false
SURFACE_SELECTION.Parent = CoreGui

ON_ACTION_TRIGGERED(FEATURE_INFO.universal_surface_action, Enum.SurfaceType.Universal)
ON_ACTION_TRIGGERED(FEATURE_INFO.inlet_surface_action, Enum.SurfaceType.Inlet)
ON_ACTION_TRIGGERED(FEATURE_INFO.studs_surface_action, Enum.SurfaceType.Studs)
ON_ACTION_TRIGGERED(FEATURE_INFO.weld_surface_action, Enum.SurfaceType.Weld)

FEATURE_BUTTON:on_trigger(function()
	if plugin:IsActivated() then
		plugin:SelectRibbonTool(Enum.RibbonTool.Select, UDim2.new())
		plugin:Deactivate()
	else
		FEATURE_BUTTON:show_async()
	end
end)

plugin.Unloading:Connect(function()
	SURFACE_SELECTION:Destroy()
end)

return nil
