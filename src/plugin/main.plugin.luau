--!optimize 2

--[[
	PBR Surface Applier
	applies pbr versions of surfaces to parts
]]

local info = require("./info")
local plugtilly = require("./packages/plugtilly")
local pbr_surfaces = require("../pbr_surfaces")
local values = require("./packages/values")
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Selection = game:GetService("Selection")
local CoreGui = game:GetService("CoreGui")

local PLUGIN_NAME = plugtilly.name(plugin)
local TOOLBAR = plugin:CreateToolbar(PLUGIN_NAME)

info.auto_apply_surfaces = {
	enabled_for_places = plugtilly.setting(plugin, "AutoApplyEnabledForPlaces", {}),
	button = plugtilly.create_action_button(plugin, TOOLBAR, {
		id = "Auto Apply Surfaces",
		tooltip = "Enables/Disables automatically applying PBR versions of old Roblox Surfaces to selected Part(s)",
		icon = Content.fromAssetId(133631232996249),
		clickable_when_viewport_hidden = true,
		allow_binding = true,
	}),
	active = false,
}

info.apply_default_surfaces_button = plugtilly.create_action_button(plugin, TOOLBAR, {
	id = "Apply Default Surfaces",
	tooltip = "Sets the TopSurface to be Stud and the BottomSurface to be Inlet for the selected Part(s)",
	icon = Content.fromAssetId(133631232996249),
	clickable_when_viewport_hidden = true,
	allow_binding = true,
})

local apply_surface_button = plugtilly.create_menu_action_button(plugin, TOOLBAR, {
	id = "Apply Surface",
	tooltip = "Applies the selected Surface in the menu using a tool similar to the Decal/Texture Per Face applier tool in studio.",
	icon = Content.fromAssetId(133631232996249),
	clickable_when_viewport_hidden = true,
	allow_binding = true,
})

info.apply_surface = {
	universal_surface_action = apply_surface_button:add_new_action("Universal", Content.fromAssetId(133631232996249)),
	inlet_surface_action = apply_surface_button:add_new_action("Inlet", Content.fromAssetId(133631232996249)),
	studs_surface_action = apply_surface_button:add_new_action("Studs", Content.fromAssetId(133631232996249)),
	weld_surface_action = apply_surface_button:add_new_action("Weld", Content.fromAssetId(133631232996249)),
	button = apply_surface_button,
}

info.convert_place_to_pbr_surfaces = plugtilly.create_action_button(plugin, TOOLBAR, {
	id = "Convert Place to PBR Surfaces",
	tooltip = "Converts every Part in the current Place to use PBR Surfaces instead of Roblox Surfaces",
	icon = Content.fromAssetId(133631232996249),
	clickable_when_viewport_hidden = true,
	allow_binding = false,
})

info.plugin_name = PLUGIN_NAME
info.toolbar = TOOLBAR
info.plugin = plugin

for _, module in script.Parent.features:GetChildren() do
	(require)(module :: any)
end
