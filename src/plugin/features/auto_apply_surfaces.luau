--!optimize 2

--[[
	auto apply surfaces
	Enables/Disables automatically applying PBR versions of old Roblox Surfaces to selected Part(s)
]]

local safe_descendant_added = require("../safe_descendant_added")
local update_surface = require("../update_surface")
local pbr_surfaces = require("../../pbr_surfaces")
local plugtilly = require("../packages/plugtilly")
local values = require("../packages/values")
local info = require("../info")
local Selection = game:GetService("Selection")

local CONVERT_AND_UPDATE_ACTION = "Convert Roblox Surfaces to PBR Surfaces and Update PBR Surface Textures for a selected Part"
local UPDATE_ACTION = "Update PBR Surface Textures for a selected Part"
local DISPLAY_ACTION_NAME = "Auto Apply Surfaces"
local STRING_PLACE_ID = tostring(game.PlaceId)

local OTHER_SELECTED_CONNECTIONS = table.create(100) :: { RBXScriptConnection }
local SELECTED_PART_CONNECTIONS = table.create(100) :: { RBXScriptConnection }
local APPLYING_FOR_PARTS = {} :: { [BasePart]: true? }
local SELECTION_CHANGED_CONNECTION: RBXScriptConnection
local OTHER_SELECTED_CONNECTIONS_COUNT = 0
local SELECTED_PART_CONNECTIONS_COUNT = 0
local SELECTION: { Instance }

local SURFACE_NORMALS = values(pbr_surfaces.surface_normal :: { pbr_surfaces.SurfaceNormal })
local BOTTOM_SURFACE_NORMAL = pbr_surfaces.surface_normal.bottom
local RIGHT_SURFACE_NORMAL = pbr_surfaces.surface_normal.right
local FRONT_SURFACE_NORMAL = pbr_surfaces.surface_normal.front
local LEFT_SURFACE_NORMAL = pbr_surfaces.surface_normal.left
local BACK_SURFACE_NORMAL = pbr_surfaces.surface_normal.back
local TOP_SURFACE_NORMAL = pbr_surfaces.surface_normal.top
local FEATURE_INFO = info.auto_apply_surfaces
local FEATURE_ENABLED_FOR_PLACES = FEATURE_INFO.enabled_for_places
local FEATURE_BUTTON = FEATURE_INFO.button
local plugin = info.plugin

-- alias to table.find because every time its used here, table.find will always find something
local ASSERT_FIND = table.find :: <V>(t: { V }, v: V, init: number?) -> number

local function ADD_PART_CONNECTION(connection: RBXScriptConnection): RBXScriptConnection
	SELECTED_PART_CONNECTIONS_COUNT += 1
	SELECTED_PART_CONNECTIONS[SELECTED_PART_CONNECTIONS_COUNT] = connection
	return connection
end

local function SWAP_REMOVE_PART_CONNECTION(index: number)
	SELECTED_PART_CONNECTIONS[index] = SELECTED_PART_CONNECTIONS[SELECTED_PART_CONNECTIONS_COUNT]
	SELECTED_PART_CONNECTIONS[SELECTED_PART_CONNECTIONS_COUNT] = nil
	SELECTED_PART_CONNECTIONS_COUNT -= 1
end

local function cleanup_previous_selection()
	for index, connection in SELECTED_PART_CONNECTIONS do
		-- luau arrays don't shrink
		SELECTED_PART_CONNECTIONS[index] = nil
		connection:Disconnect()
	end

	for index, connection in OTHER_SELECTED_CONNECTIONS do
		OTHER_SELECTED_CONNECTIONS[index] = nil
		connection:Disconnect()
	end

	OTHER_SELECTED_CONNECTIONS_COUNT = 0
	SELECTED_PART_CONNECTIONS_COUNT = 0
	table.clear(APPLYING_FOR_PARTS)
end

local function on_attribute_changed(part: BasePart, attribute: string)
	if
		attribute == BOTTOM_SURFACE_NORMAL
		or attribute == RIGHT_SURFACE_NORMAL
		or attribute == FRONT_SURFACE_NORMAL
		or attribute == LEFT_SURFACE_NORMAL
		or attribute == BACK_SURFACE_NORMAL
		or attribute == TOP_SURFACE_NORMAL
	then
		local finish_recording = plugtilly.create_recording(plugin, UPDATE_ACTION, DISPLAY_ACTION_NAME)
		update_surface(part, attribute :: any, pbr_surfaces.get_surface(part, attribute))
		finish_recording(Enum.FinishRecordingOperation.Commit)
	end
end

local function on_changed(part: BasePart, property: keyof<BasePart>)
	if
		property == "Transparency" or
		property == "Material" or
		property == "Color"
	then
		local finish_recording = plugtilly.create_recording(plugin, UPDATE_ACTION, DISPLAY_ACTION_NAME)
		update_surface(part, BOTTOM_SURFACE_NORMAL, pbr_surfaces.get_surface(part, BOTTOM_SURFACE_NORMAL))
		update_surface(part, RIGHT_SURFACE_NORMAL, pbr_surfaces.get_surface(part, RIGHT_SURFACE_NORMAL))
		update_surface(part, FRONT_SURFACE_NORMAL, pbr_surfaces.get_surface(part, FRONT_SURFACE_NORMAL))
		update_surface(part, LEFT_SURFACE_NORMAL, pbr_surfaces.get_surface(part, LEFT_SURFACE_NORMAL))
		update_surface(part, BACK_SURFACE_NORMAL, pbr_surfaces.get_surface(part, BACK_SURFACE_NORMAL))
		update_surface(part, TOP_SURFACE_NORMAL, pbr_surfaces.get_surface(part, TOP_SURFACE_NORMAL))
		finish_recording(Enum.FinishRecordingOperation.Commit)
	elseif
		property == "BottomSurface" or
		property == "RightSurface" or
		property == "FrontSurface" or
		property == "LeftSurface" or
		property == "BackSurface" or
		property == "TopSurface"
	then
		local finish_recording = plugtilly.create_recording(plugin, CONVERT_AND_UPDATE_ACTION)
		local property_surface_type = (part :: any)[property] :: Enum.SurfaceType

		if property_surface_type ~= Enum.SurfaceType.Smooth then
			local surface_type = pbr_surfaces.convert_roblox_surface_to_pbr_surface(part, property)
			update_surface(part, property, surface_type)
		else
			update_surface(part, property, pbr_surfaces.get_surface(part, property))
		end
		finish_recording(Enum.FinishRecordingOperation.Commit)
	end
end

local function on_destroying(part: BasePart, third_connection: RBXScriptConnection)
	local third_connection_index = ASSERT_FIND(SELECTED_PART_CONNECTIONS, third_connection)
	local second_connection_index = third_connection_index - 1
	local first_connection_index = second_connection_index - 1

	SELECTED_PART_CONNECTIONS[first_connection_index]:Disconnect()
	SELECTED_PART_CONNECTIONS[second_connection_index]:Disconnect()
	third_connection:Disconnect()

	if third_connection_index ~= SELECTED_PART_CONNECTIONS_COUNT then
		SWAP_REMOVE_PART_CONNECTION(third_connection_index)
		SWAP_REMOVE_PART_CONNECTION(second_connection_index)
		SWAP_REMOVE_PART_CONNECTION(first_connection_index)
	else
		SELECTED_PART_CONNECTIONS[first_connection_index] = nil
		SELECTED_PART_CONNECTIONS[second_connection_index] = nil
		SELECTED_PART_CONNECTIONS[third_connection_index] = nil
	end
	APPLYING_FOR_PARTS[part] = nil
end

local function auto_apply_for_part(part: BasePart)
	if APPLYING_FOR_PARTS[part] then
		return
	end
	local third_connection: RBXScriptConnection

	ADD_PART_CONNECTION(part.AttributeChanged:Connect(function(attribute)
		on_attribute_changed(part, attribute)
	end))
	ADD_PART_CONNECTION(part.Changed:Connect(function(property)
		on_changed(part, property :: any)
	end))
	third_connection = ADD_PART_CONNECTION(part.Destroying:Connect(function()
		on_destroying(part, third_connection)
	end))
	APPLYING_FOR_PARTS[part] = true

	local finish_recording = plugtilly.try_create_recording(plugin, CONVERT_AND_UPDATE_ACTION)

	if not finish_recording then
		return
	end

	for _, surface_normal in SURFACE_NORMALS do
		local surface_type = pbr_surfaces.convert_roblox_surface_to_pbr_surface(part, surface_normal)
			or pbr_surfaces.get_surface(part, surface_normal)
		update_surface(part, surface_normal, surface_type)
	end

	finish_recording(Enum.FinishRecordingOperation.Commit)
end

local function auto_apply_surfaces_for_selection()
	SELECTION = Selection:Get()
	cleanup_previous_selection()

	for _, instance in SELECTION do
		if instance:IsA("BasePart") and instance.ClassName ~= "Terrain" then
			auto_apply_for_part(instance)
		end

		local connection = instance.DescendantAdded:Connect(function(descendant)
			if
				descendant.ClassName ~= "Terrain"
				and descendant:IsA("BasePart")
				and not table.find(SELECTION, descendant)
			then
				auto_apply_for_part(descendant)
			end
		end)

		for _, descendant: BasePart in instance:QueryDescendants("BasePart") do
			if
				descendant.ClassName ~= "Terrain"
				and not table.find(SELECTION, descendant)
			then
				auto_apply_for_part(descendant :: any)
			end
		end

		OTHER_SELECTED_CONNECTIONS_COUNT += 1
		OTHER_SELECTED_CONNECTIONS[OTHER_SELECTED_CONNECTIONS_COUNT] = connection
	end
end

local function enable_auto_apply_surfaces()
	SELECTION_CHANGED_CONNECTION = Selection.SelectionChanged:Connect(auto_apply_surfaces_for_selection)
	auto_apply_surfaces_for_selection()
	FEATURE_BUTTON:set_active(true)
	FEATURE_INFO.active = true
end

game:GetPropertyChangedSignal("PlaceId"):Connect(function()
	STRING_PLACE_ID = tostring(game.PlaceId)
end)

FEATURE_BUTTON:on_trigger(function()
	local enabled_for_places = FEATURE_ENABLED_FOR_PLACES()

	if FEATURE_INFO.active then
		if STRING_PLACE_ID ~= "0" then
			enabled_for_places[STRING_PLACE_ID] = nil
			FEATURE_ENABLED_FOR_PLACES(enabled_for_places)
		end

		if SELECTION_CHANGED_CONNECTION then
			SELECTION_CHANGED_CONNECTION:Disconnect()
			cleanup_previous_selection()
		end

		FEATURE_BUTTON:set_active(false)
		FEATURE_INFO.active = false
	else
		if STRING_PLACE_ID ~= "0" then
			enabled_for_places[STRING_PLACE_ID] = true
			FEATURE_ENABLED_FOR_PLACES(enabled_for_places)
		end
		enable_auto_apply_surfaces()
	end
end)

if FEATURE_ENABLED_FOR_PLACES()[STRING_PLACE_ID] then
	enable_auto_apply_surfaces()
end

return nil
