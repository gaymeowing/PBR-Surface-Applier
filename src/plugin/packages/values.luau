
--[[
	values
	gives an array of all values in a table
]]

local function values<K, V>(t: { [K]: V }): { V }
	local values = {}

	for _, value in t do
		table.insert(values, value)
	end
	return values
end

return values
