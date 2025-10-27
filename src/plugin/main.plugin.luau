--!optimize 2

--[[
	PBR Surface Applier
	applies pbr versions of surfaces to parts
]]

local plugtilly = require("./packages/plugtilly")
local pbr_surfaces = require("../pbr_surfaces")
local values = require("./packages/values")
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
local APPLY_SURFACE_BUTTON = plugtilly.create_menu_action_button(plugin, TOOLBAR, {
	id = "Apply Surface",
	tooltip = "Applies the selected Surface in the menu using a tool similar to the Decal/Texture Per Face applier tool in studio.",
	icon = Content.fromAssetId(133631232996249),
	clickable_when_viewport_hidden = true,
	allow_binding = true,
})
local BOTTOM_SURFACE_NORMAL = pbr_surfaces.surface_normal.bottom
local RIGHT_SURFACE_NORMAL= pbr_surfaces.surface_normal.right
local FRONT_SURFACE_NORMAL = pbr_surfaces.surface_normal.front
local LEFT_SURFACE_NORMAL = pbr_surfaces.surface_normal.left
local BACK_SURFACE_NORMAL = pbr_surfaces.surface_normal.back
local TOP_SURFACE_NORMAL = pbr_surfaces.surface_normal.top
local STRING_PLACE_ID = tostring(game.PlaceId) :: string
local STUDIO_SETTINGS = settings().Studio
local ENABLE_AUTO_APPLY: () -> ()
local AUTO_APPLY_ACTIVE = false

local function UPDATE_SURFACE(
	part: BasePart, surface_normal: pbr_surfaces.SurfaceNormal, surface_type: Enum.SurfaceType?
)
	if surface_type and surface_type ~= Enum.SurfaceType.Smooth then
		-- the error doesn't matter here
		pcall(pbr_surfaces.update_surface, part, surface_normal, surface_type)
	else
		local texture = part:FindFirstChild(surface_normal)

		if texture then
			texture:Destroy()
		end
		part:SetAttribute(surface_normal, Enum.SurfaceType.Smooth)
	end
end

local function UPDATE_SURFACES_FROM_ATTRIBUTES(part: BasePart)
	UPDATE_SURFACE(part, BOTTOM_SURFACE_NORMAL, pbr_surfaces.get_surface(part, BOTTOM_SURFACE_NORMAL))
	UPDATE_SURFACE(part, RIGHT_SURFACE_NORMAL, pbr_surfaces.get_surface(part, RIGHT_SURFACE_NORMAL))
	UPDATE_SURFACE(part, FRONT_SURFACE_NORMAL, pbr_surfaces.get_surface(part, FRONT_SURFACE_NORMAL))
	UPDATE_SURFACE(part, LEFT_SURFACE_NORMAL, pbr_surfaces.get_surface(part, LEFT_SURFACE_NORMAL))
	UPDATE_SURFACE(part, BACK_SURFACE_NORMAL, pbr_surfaces.get_surface(part, BACK_SURFACE_NORMAL))
	UPDATE_SURFACE(part, TOP_SURFACE_NORMAL, pbr_surfaces.get_surface(part, TOP_SURFACE_NORMAL))
end

do -- auto apply surfaces

	local CONVERT_AND_UPDATE_RECORDING_ACTION = "Convert Roblox Surfaces to PBR Surfaces and Update PBR Surface Textures for a selected Part"
	local SURFACE_NORMALS = values(pbr_surfaces.surface_normal :: { pbr_surfaces.SurfaceNormal })
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

	local function create_recording_for_update(): plugtilly.FinishRecording
		return (plugtilly.create_recording(plugin, "Update PBR Surface Textures for a selected Part"))
	end

	local function on_attribute_changed(part: BasePart, attribute: string)
		local surface_type = pbr_surfaces.get_surface(part, attribute :: any)

		if
			surface_type ~= Enum.SurfaceType.Smooth and
			(attribute == BOTTOM_SURFACE_NORMAL or
			attribute == RIGHT_SURFACE_NORMAL or
			attribute == FRONT_SURFACE_NORMAL or
			attribute == LEFT_SURFACE_NORMAL or
			attribute == BACK_SURFACE_NORMAL or
			attribute == TOP_SURFACE_NORMAL)
		then
			local finish_recording = create_recording_for_update()
			UPDATE_SURFACE(part, attribute :: any, surface_type)
			finish_recording(Enum.FinishRecordingOperation.Commit)
		end
	end

	local function on_changed(part: BasePart, property: keyof<BasePart>)
		if
			property == "Transparency" or
			property == "Material" or
			property == "Color"
		then
			local finish_recording = create_recording_for_update()
			UPDATE_SURFACES_FROM_ATTRIBUTES(part)
			finish_recording(Enum.FinishRecordingOperation.Commit)
		elseif
			property == "BottomSurface" or
			property == "RightSurface" or
			property == "FrontSurface" or
			property == "LeftSurface" or
			property == "BackSurface" or
			property == "TopSurface"
		then
			local finish_recording = plugtilly.create_recording(plugin, CONVERT_AND_UPDATE_RECORDING_ACTION)
			local property_surface_type = (part :: any)[property] :: Enum.SurfaceType

			if property_surface_type ~= Enum.SurfaceType.Smooth then
				local surface_type = pbr_surfaces.convert_roblox_surface_to_pbr_surface(part, property)
				UPDATE_SURFACE(part, property, surface_type)
			else
				UPDATE_SURFACE(
					part, property, pbr_surfaces.get_surface(part, property)
				)
			end
			finish_recording(Enum.FinishRecordingOperation.Commit)
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

			table.insert(SELECTION_CONNECTIONS, instance.AttributeChanged:Connect(function(attribute)
				on_attribute_changed(instance, attribute)
			end))
			table.insert(SELECTION_CONNECTIONS, instance.Changed:Connect(function(property)
				on_changed(instance, property :: any)
			end))
			local finish_recording = plugtilly.create_recording(plugin, CONVERT_AND_UPDATE_RECORDING_ACTION)

			for _, surface_normal in SURFACE_NORMALS do
				local surface_type = pbr_surfaces.convert_roblox_surface_to_pbr_surface(instance, surface_normal) or
					pbr_surfaces.get_surface(instance, surface_normal)
				UPDATE_SURFACE(instance, surface_normal, surface_type)
			end
			finish_recording(Enum.FinishRecordingOperation.Commit)
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
		local finish_recording = plugtilly.create_recording(plugin, "Apply Default PBR Surfaces to Part(s) in Selection")

		for _, instance in Selection:Get() do
			if instance:IsA("BasePart") then
				instance.RightSurface = Enum.SurfaceType.Smooth
				instance.FrontSurface = Enum.SurfaceType.Smooth
				instance.BottomSurface = Enum.SurfaceType.Smooth
				instance.LeftSurface = Enum.SurfaceType.Smooth
				instance.BackSurface = Enum.SurfaceType.Smooth
				instance.TopSurface = Enum.SurfaceType.Smooth
				-- do NOT add a update_surfaces method, it is only ever useful for this plugin
				UPDATE_SURFACE(instance, "RightSurface", nil)
				UPDATE_SURFACE(instance, "FrontSurface", nil)
				UPDATE_SURFACE(instance, "BottomSurface", Enum.SurfaceType.Inlet)
				UPDATE_SURFACE(instance, "LeftSurface", nil)
				UPDATE_SURFACE(instance, "BackSurface", nil)
				UPDATE_SURFACE(instance, "TopSurface", Enum.SurfaceType.Studs)
			end
		end
		finish_recording(Enum.FinishRecordingOperation.Commit)
	end)

end

do -- apply surface

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
		local recording_action = `Apply PBR Surface "{surface.Name}"`

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

				local finish_recording = plugtilly.create_recording(plugin, recording_action)
				local target_surface_normal = NORMAL_ID_TO_SURFACE_NORMAL(mouse.TargetSurface)

				;(target :: any)[target_surface_normal] = Enum.SurfaceType.Smooth
				pbr_surfaces.update_surface(target, target_surface_normal, surface)
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
