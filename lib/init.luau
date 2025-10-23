
--[[
	PBR Surface
	applies pbr versions of old roblox surfaces to parts
]]

local function CREATE_TEXTURE(
	color: Content,
	normal: Content,
	studs_per_tile: number
): Texture
	local texture = Instance.new("Texture")
	texture.StudsPerTileU = studs_per_tile
	texture.StudsPerTileV = studs_per_tile
	texture.NormalMapContent = normal
	texture.ColorMapContent = color
	texture.ZIndex = -math.huge
	return texture
end

local UNIVERSAL_TEXTURE = CREATE_TEXTURE(
	Content.fromAssetId(117054089688385),
	Content.fromAssetId(102661331765015),
	2
)
local INLET_TEXTURE = CREATE_TEXTURE(
	Content.fromAssetId(113737834938153),
	Content.fromAssetId(137521479017320),
	1
)
local STUDS_TEXTURE = CREATE_TEXTURE(
	Content.fromAssetId(136114195695129),
	Content.fromAssetId(122912203485725),
	1
)
local WELD_TEXTURE = CREATE_TEXTURE(
	Content.fromAssetId(118503201716558),
	Content.fromAssetId(82754842470978),
	2
)

local BOTTOM_SURFACE_NAME = "BottomSurface"
local RIGHT_SURFACE_NAME = "RightSurface"
local FRONT_SURFACE_NAME = "FrontSurface"
local LEFT_SURFACE_NAME = "LeftSurface"
local BACK_SURFACE_NAME = "BackSurface"
local TOP_SURFACE_NAME = "TopSurface"
local SURFACE_NAMES = table.freeze({
	BOTTOM_SURFACE_NAME, RIGHT_SURFACE_NAME, FRONT_SURFACE_NAME,
	LEFT_SURFACE_NAME, BACK_SURFACE_NAME, TOP_SURFACE_NAME
})

local function get_texture_for_surface(surface: Enum.SurfaceType): Texture?
	return if surface == Enum.SurfaceType.Studs then
			STUDS_TEXTURE:Clone()
		elseif surface ==  Enum.SurfaceType.Inlet then
			INLET_TEXTURE:Clone()
		elseif surface == Enum.SurfaceType.Universal then
			UNIVERSAL_TEXTURE:Clone()
		elseif surface == Enum.SurfaceType.Weld or surface == Enum.SurfaceType.Glue then
			WELD_TEXTURE:Clone()
		else
			nil
end

local function get_transparency(transparency: number): number?
	return if transparency ~= 0 then transparency else nil
end

local function APPLY_TO_SURFACE(
	part: BasePart,
	color: Color3,
	surface: Enum.SurfaceType,
	face: Enum.NormalId,
	texture_name: string
)
	local texture = get_texture_for_surface(surface)

	if texture then
		texture.Name = texture_name
		texture.Color3 = color
		texture.Face = face
		texture.Parent = part
	end
end

local function APPLY_TO_SURFACE_WITH_TRANSPARENCY(
	part: BasePart,
	color: Color3,
	surface: Enum.SurfaceType,
	face: Enum.NormalId,
	texture_name: string,
	transparency: number
)
	local texture = get_texture_for_surface(surface)

	if texture then
		texture.Transparency = transparency
		texture.Name = texture_name
		texture.Color3 = color
		texture.Face = face
		texture.Parent = part
	end
end

local function APPLY(
	part: BasePart,
	right: Enum.SurfaceType?,
	top: Enum.SurfaceType?,
	back: Enum.SurfaceType?,
	left: Enum.SurfaceType?,
	bottom: Enum.SurfaceType?,
	front: Enum.SurfaceType?
)
	local transparency = get_transparency(part.Transparency)

	if transparency == 1 then
		return
	end

	local color = part.Color

	if transparency then
		if right then
			APPLY_TO_SURFACE_WITH_TRANSPARENCY(part, color, right, Enum.NormalId.Right, RIGHT_SURFACE_NAME, transparency)
		end

		if top then
			APPLY_TO_SURFACE_WITH_TRANSPARENCY(part, color, top, Enum.NormalId.Top, TOP_SURFACE_NAME, transparency)
		end

		if back then
			APPLY_TO_SURFACE_WITH_TRANSPARENCY(part, color, back, Enum.NormalId.Back, BACK_SURFACE_NAME, transparency)
		end

		if left then
			APPLY_TO_SURFACE_WITH_TRANSPARENCY(part, color, left, Enum.NormalId.Left, LEFT_SURFACE_NAME, transparency)
		end

		if bottom then
			APPLY_TO_SURFACE_WITH_TRANSPARENCY(part, color, bottom, Enum.NormalId.Bottom, BOTTOM_SURFACE_NAME, transparency)
		end

		if front then
			APPLY_TO_SURFACE_WITH_TRANSPARENCY(part, color, front, Enum.NormalId.Front, FRONT_SURFACE_NAME, transparency)
		end
	else
		if right then
			APPLY_TO_SURFACE(part, color, right, Enum.NormalId.Right, RIGHT_SURFACE_NAME)
		end

		if top then
			APPLY_TO_SURFACE(part, color, top, Enum.NormalId.Top, TOP_SURFACE_NAME)
		end

		if back then
			APPLY_TO_SURFACE(part, color, back, Enum.NormalId.Back, BACK_SURFACE_NAME)
		end

		if left then
			APPLY_TO_SURFACE(part, color, left, Enum.NormalId.Left, LEFT_SURFACE_NAME)
		end

		if bottom then
			APPLY_TO_SURFACE(part, color, bottom, Enum.NormalId.Bottom, BOTTOM_SURFACE_NAME)
		end

		if front then
			APPLY_TO_SURFACE(part, color, front, Enum.NormalId.Front, FRONT_SURFACE_NAME)
		end
	end
end

local function CREATE_CLONE_METHOD(texture: Texture): () -> Texture
	return function()
		return texture:Clone()
	end
end

local pbr_surfaces = {
	universal = CREATE_CLONE_METHOD(UNIVERSAL_TEXTURE),
	studs = CREATE_CLONE_METHOD(STUDS_TEXTURE),
	inlet = CREATE_CLONE_METHOD(INLET_TEXTURE),
	weld = CREATE_CLONE_METHOD(WELD_TEXTURE),
	surfaces = SURFACE_NAMES,
	apply = APPLY,
}

function pbr_surfaces.apply_from_properties(part: BasePart)
	APPLY(
		part, part.RightSurface, part.TopSurface, part.BackSurface,
		part.LeftSurface, part.BottomSurface, part.FrontSurface
	)
end

function pbr_surfaces.clear_surface_textures(part: BasePart)
	for _, child in part:GetChildren() do
		if child.ClassName == "Texture" and table.find(SURFACE_NAMES, child.Name) then
			child:Destroy()
		end
	end
end

return table.freeze(pbr_surfaces)
