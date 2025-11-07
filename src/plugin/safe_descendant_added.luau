--!optimize 2

--[[
	safe descendant added
	runs the given callback on descendant added for the provided instance,
	and for all current descendants of the instance
	returns the RBXScriptConnection for DescendantAdded
]]

local function safe_descendant_added<I>(
	instance: Instance, selector: string, f: (descendant: I & Instance) -> ()
): RBXScriptConnection
	for _, descendant in instance:QueryDescendants(selector) do
		f(descendant)
	end

	return instance.DescendantAdded:Connect(f)
end

return safe_descendant_added
