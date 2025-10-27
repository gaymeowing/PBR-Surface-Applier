
--[[
	plugtilly
	roblox plugin utility
]]

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local RunService = game:GetService("RunService")

type RibbonToolChangedCallback = (current_ribbon_tool: Enum.RibbonTool, previous_ribbon_tool: Enum.RibbonTool) -> ()

export type FinishRecording = (operation: Enum.FinishRecordingOperation, options: {}?) -> ()

export type DockWidgetPluginGuiInfo = {
	initally_enabled_should_override_restore: boolean,
	inital_dock_state: Enum.InitialDockState,
	initally_enabled: boolean,
	inital_size: vector,
	min_size: vector?,
	title: string?,
}

export type PluginInterfaceInfo = {
	clickable_when_viewport_hidden: boolean?,
	enabled: boolean?,
	--[[
		The text to be displayed as a tooltip for the PluginToolbarButton, and as the statusTip for the PluginAction
	]]
	tooltip: string,
	icon: Content,
	name: string?,
	id: string,
}

export type PluginInterfaceActionInfo = PluginInterfaceInfo & {
	allow_binding: boolean?,
	icon_name: string?,
}

export type Setting<V> = (value: V?) -> V

type PluginButton = {
	on_trigger: (plugin_button: PluginButton, f: () -> ()) -> (() -> ()),
	set_enabled: (plugin_button: PluginButton, enabled: boolean) -> (),
	set_active: (plugin_button: PluginButton, active: boolean) -> (),
	is_enabled: (plugin_button: PluginButton) -> boolean,
	destroy: (plugin_button: PluginButton) -> (),
	read button: PluginToolbarButton,
}

type PluginMenuButton = PluginButton & {
	add_seperator: (plugin_menu_button: PluginMenuButton, plugin_action: PluginAction | PluginActionButton) -> PluginMenuButton,
	add_new_action: (plugin_menu_button: PluginMenuButton, id: string, icon: Content, title: string?) -> PluginAction,
	add_action: ((plugin_menu_button: PluginMenuButton, plugin_action: PluginAction) -> PluginAction) &
		((plugin_menu_button: PluginMenuButton, plugin_action_button: PluginActionButton) -> PluginActionButton),
	add_menu: (plugin_menu_button: PluginMenuButton, plugin_menu: PluginMenuButton | PluginMenu) -> PluginMenu,
	show_async: (plugin_menu_button: PluginMenuButton) -> PluginAction,
	destroy: (plugin_menu_button: PluginMenuButton) -> (),
	read menu: PluginMenu,
}

type PluginActionButton = PluginButton & {
	on_trigger: (plugin_action_button: PluginActionButton, f: () -> ()) -> (() -> ()),
	destroy: (plugin_action_button: PluginActionButton) -> (),
	read action: PluginAction,
}

export type PluginMenuActionButton = PluginActionButton & PluginMenuButton

local function UNPACK_INTERFACE_INFO(info: PluginInterfaceInfo): (string, string, string, string, boolean)
	local enabled = info.enabled
	local id = info.id

	return id, info.tooltip, info.icon.Uri :: string, info.name or id,
		if enabled ~= nil then enabled else true
end

local function CREATE_TOOLBAR_BUTTON(
	toolbar: PluginToolbar, id: string, tooltip: string, icon: string,
	name: string, enabled: boolean, info: PluginInterfaceInfo
): PluginToolbarButton
	local button = toolbar:CreateButton(id, tooltip, icon, name)

	if info.clickable_when_viewport_hidden then
		button.ClickableWhenViewportHidden = true
	end

	button.Enabled = enabled
	return button
end

--[[
	Gives the actual name of the plugin, as plugins that are loaded in via
	the plugins folder have "user_" appended to the beginning and ".rbxm"
 	appended at the end of their instance name.
]]
local function GET_NAME(plugin: Plugin): string
	local name = plugin.Name
	return string.match(name, "user_(.-)%.rbxm") or name
end

local plugin_button_prototype = {} :: PluginButton
(plugin_button_prototype :: any).__index = plugin_button_prototype

function plugin_button_prototype.set_enabled(plugin_button, enabled)
	plugin_button.button.Enabled = enabled
end

function plugin_button_prototype.set_active(plugin_button, active)
	plugin_button.button:SetActive(active)
end

function plugin_button_prototype.on_trigger(plugin_button, f)
	local connection = plugin_button.button.Click:Connect(f)

	return function()
		connection:Disconnect()
	end
end

function plugin_button_prototype.is_enabled(plugin_button)
	return plugin_button.button.Enabled
end

function plugin_button_prototype.destroy(plugin_button)
	plugin_button.button:Destroy()
end

local plugin_action_button_prototype = setmetatable({}, plugin_button_prototype) :: PluginActionButton
(plugin_action_button_prototype :: any).__index = plugin_action_button_prototype

function plugin_action_button_prototype.on_trigger(plugin_action_button, f)
	local button = plugin_action_button.button

	local triggered_connection = plugin_action_button.action.Triggered:Connect(function()
		if button.Enabled then
			f()
		end
	end)
	local click_connection = button.Click:Connect(f)

	return function()
		triggered_connection:Disconnect()
		click_connection:Disconnect()
	end
end

function plugin_action_button_prototype.destroy(plugin_action_button)
	plugin_action_button.action:Destroy()
	plugin_action_button.button:Destroy()
end

local plugin_menu_button_prototype = setmetatable({}, plugin_button_prototype) :: PluginMenuButton
(plugin_menu_button_prototype :: any).__index = plugin_menu_button_prototype

function plugin_menu_button_prototype.add_new_action(plugin_menu_button, id, icon, title)
	return plugin_menu_button.menu:AddNewAction(id, title or id, icon.Uri :: any)
end

function plugin_menu_button_prototype.add_action(
	plugin_menu_button: PluginMenuButton, plugin_action: PluginAction | PluginActionButton
)
	if type(plugin_action) == "table" then
		return plugin_menu_button.menu:AddAction(plugin_action.action)
	else
		return plugin_menu_button.menu:AddAction(plugin_action :: any)
	end
end

function plugin_menu_button_prototype.add_menu(plugin_menu_button, plugin_menu)
	if type(plugin_menu) == "table" then
		plugin_menu_button.menu:AddMenu(plugin_menu.menu)
		return plugin_menu.menu
	else
		plugin_menu_button.menu:AddMenu(plugin_menu)
		return plugin_menu
	end
end

function plugin_menu_button_prototype.add_seperator(plugin_menu_button)
	plugin_menu_button.menu:AddSeparator()
	return plugin_menu_button
end

function plugin_menu_button_prototype.show_async(plugin_menu_button)
	return plugin_menu_button.menu:ShowAsync()
end

function plugin_menu_button_prototype.destroy(plugin_menu_button)
	plugin_menu_button.button:Destroy()
	plugin_menu_button.menu:Destroy()
end

local plugin_menu_action_button_prototype = setmetatable(
	table.clone(plugin_action_button_prototype),
	plugin_menu_button_prototype
) :: any
plugin_menu_action_button_prototype.__index = plugin_menu_action_button_prototype

function plugin_menu_action_button_prototype.destroy(plugin_menu_action_button)
	plugin_menu_action_button.action:Destroy()
	plugin_menu_action_button.button:Destroy()
	plugin_menu_action_button.menu:Destroy()
end

table.freeze(plugin_menu_action_button_prototype :: any)
table.freeze(plugin_action_button_prototype :: any)
table.freeze(plugin_menu_button_prototype :: any)
table.freeze(plugin_button_prototype)

local plugtilly = {
	name = GET_NAME,
}

function plugtilly.on_ribbon_tool_changed(plugin: Plugin, f: RibbonToolChangedCallback): () -> ()
	local previous_ribbon_tool = plugin:GetSelectedRibbonTool()

	local connection = RunService.PostSimulation:Connect(function()
		local current_ribbon_tool = plugin:GetSelectedRibbonTool()

		if current_ribbon_tool ~= previous_ribbon_tool then
			f(current_ribbon_tool, previous_ribbon_tool)
			previous_ribbon_tool = current_ribbon_tool
		end
	end)

	return function()
		connection:Disconnect()
	end
end

--[[
	Wrapper for Plugin:CreateDockWidgetPluginGui() that instead uses a table for info,
	and also will automatically set the name of the DockWidgetPluginGui based on the plugins name
	and the title if provided in the info table.
	It also sets the DockWidgetPluginGui to have the ZIndexBehavior of Sibling, and to not ResetOnSpawn.
]]
function plugtilly.create_dock_widget_plugin_gui(
	plugin: Plugin, id: string, info: DockWidgetPluginGuiInfo
): DockWidgetPluginGui
	local plugin_name = GET_NAME(plugin)
	local inital_size = info.inital_size
	local min_size = info.min_size or inital_size
	local title = info.title

	local gui = plugin:CreateDockWidgetPluginGui(
		id, DockWidgetPluginGuiInfo.new(
			info.inital_dock_state, info.initally_enabled,
			info.initally_enabled_should_override_restore,
			inital_size.x, inital_size.y,
			min_size.x, min_size.y
		)
	)

	if title then
		gui.Name = `{plugin_name} "{title}"`
		gui.Title = title
	else
		gui.Title = plugin_name
		gui.Name = plugin_name
	end

	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.ResetOnSpawn = false
	return gui
end

--[[
	Wrapper around Plugin:GetSetting() and Plugin:SetSetting(),
	that gives single function that when called it'll give you the current setting value,
	and calling it with an argument will also set the setting.
]]
function plugtilly.setting<V>(plugin: Plugin, key: string, default: V): Setting<V>
	if plugin:GetSetting(key) == nil then
		plugin:SetSetting(key, default)
	end

	return function(...)
		if select("#", ...) ~= 0 then
			local value = select(1, ...)
			plugin:SetSetting(key, value)
			return value
		end

		return plugin:GetSetting(key)
	end
end

function plugtilly.create_menu_action_button(
	plugin: Plugin, toolbar: PluginToolbar, info: PluginInterfaceActionInfo
): PluginMenuActionButton
	local id, tooltip, icon, name, enabled = UNPACK_INTERFACE_INFO(info)
	local button = CREATE_TOOLBAR_BUTTON(toolbar, id, tooltip, icon, name, enabled, info)
	local menu = plugin:CreatePluginMenu(id, name, icon)
	local action = plugin:CreatePluginAction(
		id, name, tooltip, info.icon_name, info.allow_binding
	)

	return table.freeze(setmetatable({
		button = button,
		action = action,
		menu = menu,
	}, plugin_menu_action_button_prototype)) :: any
end

function plugtilly.create_action_button(
	plugin: Plugin, toolbar: PluginToolbar, info: PluginInterfaceActionInfo
): PluginActionButton
	local id, tooltip, icon, name, enabled = UNPACK_INTERFACE_INFO(info)

	return table.freeze(setmetatable({
		action = plugin:CreatePluginAction(id, name, tooltip, info.icon_name, info.allow_binding),
		button = CREATE_TOOLBAR_BUTTON(toolbar, id, tooltip, icon, name, enabled, info),
	}, plugin_action_button_prototype))  :: any
end

function plugtilly.create_menu_button(
	plugin: Plugin, toolbar: PluginToolbar, info: PluginInterfaceInfo
): PluginMenuButton
	local id, tooltip, icon, name, enabled = UNPACK_INTERFACE_INFO(info)
	local button = CREATE_TOOLBAR_BUTTON(toolbar, id, tooltip, icon, name, enabled, info)
	local menu = plugin:CreatePluginMenu(id, name, icon)

	button.Click:Connect(function()
		menu:ShowAsync()
	end)

	return table.freeze(setmetatable({
		button = button,
		menu = menu,
	}, plugin_menu_button_prototype)) :: any
end

function plugtilly.create_recording(plugin: Plugin, action: string): (FinishRecording, string)
	local identifier = ChangeHistoryService:TryBeginRecording(action)

	if not identifier then
		local name = GET_NAME(plugin)

		if RunService:IsEdit() then
			error(`[{name}]: Could not start recording changes for action "{action}"`, 2)
		else
			error(`[{name}]: Cannot use {name} during a playtest.`, 2)
		end
	end

	return function(operation, options)
		ChangeHistoryService:FinishRecording(identifier :: any, operation, options :: any)
	end, identifier
end

return table.freeze(plugtilly)
