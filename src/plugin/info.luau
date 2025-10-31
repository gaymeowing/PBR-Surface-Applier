
--[[
	plugin info
	shared state for the pbr surface applier plugin
]]

local plugtilly = require("./packages/plugtilly")

type PluginInfo = {
	apply_default_surfaces_button: plugtilly.PluginActionButton,
	convert_place_to_pbr_surfaces: plugtilly.PluginActionButton,
	toolbar: PluginToolbar,
	plugin_name: string,
	plugin: Plugin,

	auto_apply_surfaces: {
		enabled_for_places: plugtilly.Setting<{ [string]: true? }>,
		button: plugtilly.PluginActionButton,
		active: boolean,
	},
	apply_surface: {
		button: plugtilly.PluginMenuActionButton,
		universal_surface_action: PluginAction,
		studs_surface_action: PluginAction,
		inlet_surface_action: PluginAction,
		weld_surface_action: PluginAction,
	},
}

return {} :: PluginInfo
