--!optimize 2

--[[
	update surface
	wrapper around pbr_surfaces.update_surface that will keep attributes for Enum.SurfaceType.Smooth surfaces
]]

local pbr_surfaces = require("../pbr_surfaces")
local info = require("./info")

local INAVLID_SURFACE_WARNING = `[{info.plugin_name}]: Cannot apply surface '%*' to SurfaceNormal '%*' because surface is not`

local function update_surface(
	part: BasePart, surface_normal: pbr_surfaces.SurfaceNormal, surface_type: Enum.SurfaceType?
)
	if surface_type and surface_type ~= Enum.SurfaceType.Smooth then
		local texture = pbr_surfaces.has_texture_for_surface(surface_type)

		if texture then
			pbr_surfaces.update_surface(part, surface_normal, surface_type)
			return
		end
		warn(string.format(INAVLID_SURFACE_WARNING :: any, surface_type, surface_normal))
	else
		pbr_surfaces.set_surface(part, surface_normal, Enum.SurfaceType.Smooth)
	end

	local texture = part:FindFirstChild(surface_normal)

	if texture then
		texture:Destroy()
	end
end

INAVLID_SURFACE_WARNING ..= table.concat({
	tostring(Enum.SurfaceType.Universal),
	tostring(Enum.SurfaceType.Inlet),
	tostring(Enum.SurfaceType.Studs),
	tostring(Enum.SurfaceType.Glue),
}, ", ")
INAVLID_SURFACE_WARNING ..= `, or {Enum.SurfaceType.Weld}.`

return update_surface
