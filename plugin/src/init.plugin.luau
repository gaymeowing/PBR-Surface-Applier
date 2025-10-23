--!optimize 2

--[[
	PBR Surface Applier
	applies pbr versions of surfaces to parts
]]

local pbr_surfaces = require("./packages/pbr_surfaces")
local plugtilly = require("./packages/plugtilly")
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Selection = game:GetService("Selection")
local CoreGui = game:GetService("CoreGui")

local PLUGIN_NAME = plugtilly.name(plugin)
local TOOLBAR = plugin:CreateToolbar(PLUGIN_NAME)
local AUTO_APPLY_SURFACES_BUTTON = plugtilly.create_action_button(plugin, TOOLBAR, {
	id = "Auto Apply Surfaces",
	tooltip = "Enables/Disables automatically applying PBR versions of old Roblox Surfaces to selected Part(s)",
	icon = Content.fromAssetId(133631232996249),
	clickable_when_viewport_hidden = true,
	allow_binding = true,
})
local APPLY_DEFAULT_SURFACES_BUTTON = plugtilly.create_action_button(plugin, TOOLBAR, {
	id = "Apply Default Surfaces",
	tooltip = "Sets the TopSurface to be Stud and the BottomSurface to be Inlet for the selected Part(s)",
	icon = Content.fromAssetId(133631232996249),
	clickable_when_viewport_hidden = true,
	allow_binding = true,
})
local STRING_PLACE_ID = tostring(game.PlaceId) :: string
local STUDIO_SETTINGS = settings().Studio
local ENABLE_AUTO_APPLY: () -> ()
local AUTO_APPLY_ACTIVE = false

do -- auto apply surfaces

	local AUTO_APPLY_ENABLED_FOR_PLACES = plugtilly.setting(
		plugin, "AutoApplyEnabledForPlaces", {} :: { [string]: boolean }
	)
	local SELECTION_CONNECTIONS = {} :: { RBXScriptConnection }
	local SELECTION_CHANGED_CONNECTION: RBXScriptConnection
	local PREVIOUS_SELECTION = {} :: { Instance }

	local function disconnect_selection_connections()
		for _, connection in SELECTION_CONNECTIONS do
			connection:Disconnect()
		end
		table.clear(SELECTION_CONNECTIONS)
	end

	local function update_part(part: BasePart)
		local finish_recording = plugtilly.create_recording(plugin, "Update Surface Textures for a selected Part")
		pbr_surfaces.clear_surface_textures(part)
		pbr_surfaces.apply_from_properties(part)
		finish_recording(Enum.FinishRecordingOperation.Commit)
	end

	local function on_changed(part: BasePart, property: string)
		if
			property == "BottomSurface" or
			property == "RightSurface" or
			property == "FrontSurface" or
			property == "LeftSurface" or
			property == "BackSurface" or
			property == "TopSurface" or
			property == "Transparency" or
			property == "Material" or
			property == "Color"
		then
			update_part(part)
		end
	end

	local function auto_apply_surfaces_for_selection()
		local selection = Selection:Get()

		if #selection == #PREVIOUS_SELECTION then
			local is_equal = true

			for index, instance in selection do
				if PREVIOUS_SELECTION[index] ~= instance then
					is_equal = false
					break
				end
			end

			if is_equal then
				return
			end
		end

		PREVIOUS_SELECTION = selection
		disconnect_selection_connections()

		for index, instance in selection do
			if not instance:IsA("BasePart") then
				continue
			end

			table.insert(SELECTION_CONNECTIONS, instance.Changed:Connect(function(property)
				on_changed(instance, property)
			end))
			update_part(instance)
		end
	end

	function ENABLE_AUTO_APPLY()
		if not SELECTION_CHANGED_CONNECTION then
			SELECTION_CHANGED_CONNECTION = Selection.SelectionChanged:Connect(auto_apply_surfaces_for_selection)
			auto_apply_surfaces_for_selection()
		end

		AUTO_APPLY_SURFACES_BUTTON:set_active(true)
		AUTO_APPLY_ACTIVE = true
	end

	game:GetPropertyChangedSignal("PlaceId"):Connect(function()
		STRING_PLACE_ID = tostring(game.PlaceId)
	end)

	AUTO_APPLY_SURFACES_BUTTON:on_trigger(function()
		local enabled_places = AUTO_APPLY_ENABLED_FOR_PLACES()

		if AUTO_APPLY_ACTIVE then
			if STRING_PLACE_ID ~= "0" then
				enabled_places[STRING_PLACE_ID] = nil
				AUTO_APPLY_ENABLED_FOR_PLACES(enabled_places)
			end

			if SELECTION_CHANGED_CONNECTION then
				SELECTION_CHANGED_CONNECTION:Disconnect()
				disconnect_selection_connections()
			end

			AUTO_APPLY_SURFACES_BUTTON:set_active(false)
			AUTO_APPLY_ACTIVE = false
		else
			if STRING_PLACE_ID ~= "0" then
				enabled_places[STRING_PLACE_ID] = true
				AUTO_APPLY_ENABLED_FOR_PLACES(enabled_places)
			end
			ENABLE_AUTO_APPLY()
		end
	end)

	if AUTO_APPLY_ENABLED_FOR_PLACES()[STRING_PLACE_ID] then
		ENABLE_AUTO_APPLY()
	end

end

do -- apply default surfaces

	APPLY_DEFAULT_SURFACES_BUTTON:on_trigger(function()
		local finish_recording = plugtilly.create_recording(plugin, "Apply Default Surfaces to Part(s) in Selection")

		for _, instance in Selection:Get() do
			if instance:IsA("BasePart") then
				instance.RightSurface = Enum.SurfaceType.Smooth
				instance.FrontSurface = Enum.SurfaceType.Smooth
				instance.BottomSurface = Enum.SurfaceType.Inlet
				instance.LeftSurface = Enum.SurfaceType.Smooth
				instance.BackSurface = Enum.SurfaceType.Smooth
				instance.TopSurface = Enum.SurfaceType.Studs
				instance.MaterialVariant = ""
			end
		end
		finish_recording(Enum.FinishRecordingOperation.Commit)
	end)

end

do -- apply surface

	local APPLY_SURFACE_BUTTON = plugtilly.create_menu_action_button(plugin, TOOLBAR, {
		id = "Apply Surface",
		tooltip = "",
		icon = Content.fromAssetId(133631232996249),
		clickable_when_viewport_hidden = true,
		allow_binding = true,
	})
	local UNIVERSAL_ACTION = APPLY_SURFACE_BUTTON:add_new_action(
		"Universal", Content.fromAssetId(0)
	)
	local INLET_ACTION = APPLY_SURFACE_BUTTON:add_new_action(
		"Inlet", Content.fromAssetId(0)
	)
	local STUDS_ACTION = APPLY_SURFACE_BUTTON:add_new_action(
		"Studs", Content.fromAssetId(0)
	)
	local WELD_ACTION = APPLY_SURFACE_BUTTON:add_new_action(
		"Weld", Content.fromAssetId(0)
	)
	local SURFACE_SELECTION = Instance.new("SurfaceSelection")
	local SELECTION_HAS_ADORNEE = false

	local function ON_ACTION_TRIGGERED(action: PluginAction, surface: Enum.SurfaceType)
		action.Triggered:Connect(function()
			APPLY_DEFAULT_SURFACES_BUTTON:set_enabled(false)
			AUTO_APPLY_SURFACES_BUTTON:set_enabled(false)
			AUTO_APPLY_SURFACES_BUTTON:set_active(false)
			APPLY_SURFACE_BUTTON:set_active(true)
			plugin:Activate(true)

			local mouse = plugin:GetMouse()
			mouse.TargetFilter = SURFACE_SELECTION
			mouse.Icon = ""

			local move_connection = mouse.Move:Connect(function()
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

				local finish_recording = plugtilly.create_recording(plugin, "Apply Surface")
				local target_surface = mouse.TargetSurface

				pbr_surfaces.clear_surface_textures(target)

				if target_surface == Enum.NormalId.Right then
					target.RightSurface = surface
					pbr_surfaces.apply(
						target, surface, target.TopSurface, target.BackSurface,
						target.LeftSurface, target.BottomSurface, target.FrontSurface
					)
				elseif target_surface == Enum.NormalId.Top then
					target.TopSurface = surface
					pbr_surfaces.apply(
						target, target.RightSurface, surface, target.BackSurface,
						target.LeftSurface, target.BottomSurface, target.FrontSurface
					)
				elseif target_surface == Enum.NormalId.Back then
					target.BackSurface = surface
					pbr_surfaces.apply(
						target, target.RightSurface, target.TopSurface, surface,
						target.LeftSurface, target.BottomSurface, target.FrontSurface
					)
				elseif target_surface == Enum.NormalId.Left then
					target.LeftSurface = surface
					pbr_surfaces.apply(
						target, target.RightSurface, target.TopSurface, target.BackSurface,
						surface, target.BottomSurface, target.FrontSurface
					)
				elseif target_surface == Enum.NormalId.Bottom then
					target.BottomSurface = surface
					pbr_surfaces.apply(
						target, target.RightSurface, target.TopSurface, target.BackSurface,
						target.LeftSurface, surface, target.FrontSurface
					)
				elseif target_surface == Enum.NormalId.Front then
					target.FrontSurface = surface
					pbr_surfaces.apply(
						target, target.RightSurface, target.TopSurface, target.BackSurface,
						target.LeftSurface, target.BottomSurface, surface
					)
				end

				finish_recording(Enum.FinishRecordingOperation.Commit)
			end)

			plugin.Deactivation:Once(function()
				if AUTO_APPLY_ACTIVE then
					AUTO_APPLY_SURFACES_BUTTON:set_active(true)
				end

				APPLY_DEFAULT_SURFACES_BUTTON:set_enabled(true)
				AUTO_APPLY_SURFACES_BUTTON:set_enabled(true)
				APPLY_SURFACE_BUTTON:set_active(false)
				click_connection:Disconnect()
				move_connection:Disconnect()
				mouse:Destroy()
			end)

			mouse.TargetFilter = SURFACE_SELECTION
			mouse.Icon = ""
		end)
	end

	STUDIO_SETTINGS:GetPropertyChangedSignal("Active Color"):Connect(function()
		SURFACE_SELECTION.Color3 = STUDIO_SETTINGS["Active Color"]
	end)
	SURFACE_SELECTION.Color3 = STUDIO_SETTINGS["Active Color"]
	SURFACE_SELECTION.Archivable = false
	SURFACE_SELECTION.Parent = CoreGui

	ON_ACTION_TRIGGERED(UNIVERSAL_ACTION, Enum.SurfaceType.Universal)
	ON_ACTION_TRIGGERED(INLET_ACTION, Enum.SurfaceType.Inlet)
	ON_ACTION_TRIGGERED(STUDS_ACTION, Enum.SurfaceType.Studs)
	ON_ACTION_TRIGGERED(WELD_ACTION, Enum.SurfaceType.Weld)

	APPLY_SURFACE_BUTTON:on_trigger(function()
		if plugin:IsActivated() then
			plugin:SelectRibbonTool(Enum.RibbonTool.Select, UDim2.new())
			plugin:Deactivate()
		else
			APPLY_SURFACE_BUTTON:show_async()
		end
	end)

	plugin.Unloading:Connect(function()
		SURFACE_SELECTION:Destroy()
	end)

end
