--!optimize 2

--[[
	PBR Surface Applier
	applies pbr versions of surfaces to parts
]]

local pbr_surfaces = require("./packages/pbr_surfaces")
local plugtilly = require("./packages/plugtilly")
local Selection = game:GetService("Selection")

local SELECTION_CONNECTIONS = {} :: { RBXScriptConnection }
local STRING_PLACE_ID = tostring(game.PlaceId) :: string
local SELECTION_CHANGED_CONNECTION: RBXScriptConnection
local NAME = plugtilly.name(plugin)
local ENABLED = false

local APPLY_DEFAULT_SURFACES_TIP = "Sets the TopSurface to be Stud and the BottomSurface to be Inlet for the selected Part(s)"
local APPLY_DEFAULT_SURFACES_NAME = "Apply Default Surfaces"
local TOOLBAR = plugin:CreateToolbar(NAME)
local APPLY_DEFAULT_SURFACES_ACTION = plugin:CreatePluginAction(
	"SURFACE_APPLIER_ADD_DEFAULT_SURFACES",
	APPLY_DEFAULT_SURFACES_NAME,
	APPLY_DEFAULT_SURFACES_TIP,
	Content.fromUri("rbxassetid://133631232996249").Uri :: string,
	true
)
local AUTO_APPLY_BUTTON = TOOLBAR:CreateButton(
	"Auto Apply Surfaces",
	"Enables/Disables automatically applying PBR versions of old Roblox Surfaces to selected Part(s)",
	Content.fromUri("rbxassetid://133631232996249").Uri :: string
)
local APPLY_DEFAULT_SURFACES_BUTTON = TOOLBAR:CreateButton(
	APPLY_DEFAULT_SURFACES_NAME,
	APPLY_DEFAULT_SURFACES_TIP,
	Content.fromUri("rbxassetid://133631232996249").Uri :: string
)
local ENABLED_FOR_PLACES = plugtilly.setting(
	plugin, "EnabledForPlaces", {} :: { [string]: true? }
)

local function IS_PLASTIC(part: BasePart): boolean
	if part.Material ~= Enum.Material.Plastic then
		warn(`[{NAME}]: Cannot apply surfaces to`, part, "because its Material is not Enum.Material.Plastic")
		return false
	end

	return true
end

local function UPDATE_ON_PROPERTY_CHANGE(part: BasePart, property: keyof<BasePart>)
	local connection = part:GetPropertyChangedSignal(property):Connect(function()
		if not IS_PLASTIC(part) then
			return
		end

		local finish_recording = plugtilly.create_recording(
			plugin, "Update Surface Textures for a selected Part"
		)

		pbr_surfaces.clear_surfaces(part)
		pbr_surfaces.apply_from_properties(part)
		finish_recording(Enum.FinishRecordingOperation.Commit)
	end)

	table.insert(SELECTION_CONNECTIONS, connection)
end

local function SWAP_REMOVE<V>(t: { V }, v: V)
	local index = table.find(t, v)

	if index then
		if index ~= 1 then
			local len = #t
			t[index] = t[len]
			t[len] = nil
		else
			t[1] = nil
		end
	end
end

local function apply_default_surfaces()
	local finish_recording = plugtilly.create_recording(plugin, "Apply Default Surfaces to Part(s) in Selection")

	for _, instance in Selection:Get() do
		if instance:IsA("BasePart") then
			instance.RightSurface = Enum.SurfaceType.Smooth
			instance.FrontSurface = Enum.SurfaceType.Smooth
			instance.BottomSurface = Enum.SurfaceType.Inlet
			instance.LeftSurface = Enum.SurfaceType.Smooth
			instance.BackSurface = Enum.SurfaceType.Smooth
			instance.TopSurface = Enum.SurfaceType.Studs
		end
	end
	finish_recording(Enum.FinishRecordingOperation.Commit)
end

local function auto_apply_surfaces_for_part(part: BasePart): boolean
	if not IS_PLASTIC(part) then
		return false
	end

	UPDATE_ON_PROPERTY_CHANGE(part, "Transparency")
	UPDATE_ON_PROPERTY_CHANGE(part, "Material")
	UPDATE_ON_PROPERTY_CHANGE(part, "Color")

	pbr_surfaces.clear_surfaces(part)
	pbr_surfaces.apply_from_properties(part)

	for _, surface in pbr_surfaces.surfaces do
		UPDATE_ON_PROPERTY_CHANGE(part, surface)
	end

	return true
end

local function disconnect_selection_connections()
	for _, connection in SELECTION_CONNECTIONS do
		connection:Disconnect()
	end
	table.clear(SELECTION_CONNECTIONS)
end

local function auto_apply_surfaces_for_selection()
	for _, instance in Selection:Get() do
		if not instance:IsA("BasePart") then
			continue
		end

		local success = auto_apply_surfaces_for_part(instance)

		if not success then
			local connection: RBXScriptConnection

			connection = instance:GetPropertyChangedSignal("Material"):Connect(function()
				local success = auto_apply_surfaces_for_part(instance)

				if success then
					SWAP_REMOVE(SELECTION_CONNECTIONS, connection)
					connection:Disconnect()
				end
			end)
			table.insert(SELECTION_CONNECTIONS, connection)
		end
	end
end

local function enable()
	if not SELECTION_CHANGED_CONNECTION then
		SELECTION_CHANGED_CONNECTION = Selection.SelectionChanged:Connect(function()
			disconnect_selection_connections()
			auto_apply_surfaces_for_selection()
		end)
		auto_apply_surfaces_for_selection()
	end

	AUTO_APPLY_BUTTON:SetActive(true)
	ENABLED = true
end

game:GetPropertyChangedSignal("PlaceId"):Connect(function()
	STRING_PLACE_ID = tostring(game.PlaceId)
end)

APPLY_DEFAULT_SURFACES_ACTION.Triggered:Connect(apply_default_surfaces)
APPLY_DEFAULT_SURFACES_BUTTON.Click:Connect(apply_default_surfaces)

AUTO_APPLY_BUTTON.ClickableWhenViewportHidden = true
AUTO_APPLY_BUTTON.Click:Connect(function()
	local enabled_places = ENABLED_FOR_PLACES()

	if ENABLED then
		if STRING_PLACE_ID ~= "0" then
			enabled_places[STRING_PLACE_ID] = nil
			ENABLED_FOR_PLACES(enabled_places)
		end

		if SELECTION_CHANGED_CONNECTION then
			SELECTION_CHANGED_CONNECTION:Disconnect()
			disconnect_selection_connections()
		end

		AUTO_APPLY_BUTTON:SetActive(false)
		ENABLED = false
	else
		if STRING_PLACE_ID ~= "0" then
			enabled_places[STRING_PLACE_ID] = true
			ENABLED_FOR_PLACES(enabled_places)
		end
		enable()
	end
end)

if ENABLED_FOR_PLACES()[STRING_PLACE_ID] then
	enable()
end
