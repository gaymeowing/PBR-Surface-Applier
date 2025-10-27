
--[[
	PBR Surface
	applies pbr versions of old roblox surfaces to parts
]]

--[=[
	TODO: in future when studio supports string enums properly, convert usage of the roblox enum Enum.SurfaceType to be a string enum

	--[[
		Used to determine what surface should be displayed on a SurfaceNormal of a
		[Part](https://create.roblox.com/docs/reference/engine/classes/BasePart)
	]]
	export type SurfaceType =
		--- A surface with a checker pattern using inlets and Roblox Studs.
		| "Universal"
		--- A surface with Roblox Stud shaped inlets where Roblox Studs would be.
		| "Inlet"
		--- A surface with Roblox Studs.
		| "Stud"
		-- A surface with an "X" pattern.
		| "Weld"
]=]

--[[
	Used to determine what side of a [Part](https://create.roblox.com/docs/reference/engine/classes/BasePart)
	should have a specific [Enum.SurfaceType](https://create.roblox.com/docs/reference/engine/enums/SurfaceType)
]]
export type SurfaceNormal =
	--- The right surface of a [Part](https://create.roblox.com/docs/reference/engine/classes/BasePart).
	| "RightSurface"
	--- The top surface of a [Part](https://create.roblox.com/docs/reference/engine/classes/BasePart).
	| "TopSurface"
	--- The back surface of a [Part](https://create.roblox.com/docs/reference/engine/classes/BasePart).
	| "BackSurface"
	--- The left surface of a [Part](https://create.roblox.com/docs/reference/engine/classes/BasePart).
	| "LeftSurface"
	--- The bottom surface of a [Part](https://create.roblox.com/docs/reference/engine/classes/BasePart).
	| "BottomSurface"
	--- The front surface of a [Part](https://create.roblox.com/docs/reference/engine/classes/BasePart).
	| "FrontSurface"


-- set surface is just a wrapper around SetAttribute,
-- so instead of having a function call a function with the exact same arguments
-- set surface is just a type cast on SetAttribute
--[[
	Sets the *`surface`* for the specified *`surface_normal`* on the *`part`*, by setting an attribute on *`part`*
	with the name of *`surface_normal`* to be *`surface`*.
]]
local SET_SURFACE = game.SetAttribute :: (part: BasePart, surface_normal: SurfaceNormal, surface: Enum.SurfaceType?) -> ()
--[[
	Gets the [Enum.SurfaceType](https://create.roblox.com/docs/reference/engine/enums/SurfaceType)
	for the specified *`surface_normal`* on the *`part`*, by getting an attribute on *`part`*
	with the name of *`surface_normal`*.
]]
local GET_SURFACE = game.GetAttribute :: (part: BasePart, surface_normal: SurfaceNormal) -> Enum.SurfaceType?

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
	-- setting to -math.huge because Roblox Surfaces apply below all other Decals/Textures
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
-- restricting these to be SurfaceNormal so incase SurfaceNormal ever has its enum items changed ill get a type error here too
-- alongside some nice autocomplete :3
local BOTTOM_SURFACE_NAME: SurfaceNormal = "BottomSurface"
local RIGHT_SURFACE_NAME: SurfaceNormal = "RightSurface"
local FRONT_SURFACE_NAME: SurfaceNormal = "FrontSurface"
local LEFT_SURFACE_NAME: SurfaceNormal = "LeftSurface"
local BACK_SURFACE_NAME: SurfaceNormal = "BackSurface"
local TOP_SURFACE_NAME: SurfaceNormal = "TopSurface"

local function SAFE_GET_TEXTURE_FOR_SURFACE(surface: Enum.SurfaceType): Texture?
	if surface == Enum.SurfaceType.Studs then
		return STUDS_TEXTURE
	elseif surface ==  Enum.SurfaceType.Inlet then
		return INLET_TEXTURE
	elseif surface == Enum.SurfaceType.Universal then
		return UNIVERSAL_TEXTURE
	elseif surface == Enum.SurfaceType.Weld or surface == Enum.SurfaceType.Glue then
		return WELD_TEXTURE
	else
		return nil
	end
end

local function UNSAFE_GET_TEXTURE_FOR_SURFACE(surface: Enum.SurfaceType): Texture
	local texture = SAFE_GET_TEXTURE_FOR_SURFACE(surface)

	if not texture then
		error(`[PBR SURFACES]: Surface '{surface}' has no Texture. Only Studs, Inlet, Universal, Weld, and Glue have Textures.`, 2)
	end
	return texture
end

--[[
	Converts the *`surface_normal`* property of *`part`* to be an
	[attribute](https://create.roblox.com/docs/studio/properties#instance-attributes),
	and sets the *`surface_normal`* property to be
	[Enum.SurfaceType.Smooth](https://create.roblox.com/docs/reference/engine/enums/SurfaceType#Smooth).
	If there isn't a PBR Surface Texture for the
	[Enum.SurfaceType](https://create.roblox.com/docs/reference/engine/enums/SurfaceType)
	value of the *`surface_normal`* property, then no
	[attribute](https://create.roblox.com/docs/studio/properties#instance-attributes)
	will be made.

	Returns the value of the *`surface_normal`*
	[attribute](https://create.roblox.com/docs/studio/properties#instance-attributes)
	if the [attribute](https://create.roblox.com/docs/studio/properties#instance-attributes) was made.
]]
local function CONVERT_ROBLOX_SURFACE_TO_PBR_SURFACE(
	part: BasePart, surface_normal: SurfaceNormal
): Enum.SurfaceType?
	local surface_type: Enum.SurfaceType = (part :: any)[surface_normal]

	if surface_type ~= Enum.SurfaceType.Smooth then
		(part :: any)[surface_normal] = Enum.SurfaceType.Smooth

		if SAFE_GET_TEXTURE_FOR_SURFACE(surface_type) then
			SET_SURFACE(part, surface_normal, surface_type)
			return surface_type
		end
	end

	return nil
end

local function surface_normal_to_normal_id(surface_normal: SurfaceNormal): Enum.NormalId
	return if surface_normal == RIGHT_SURFACE_NAME then
			Enum.NormalId.Right
		elseif surface_normal == TOP_SURFACE_NAME then
			Enum.NormalId.Top
		elseif surface_normal == BACK_SURFACE_NAME then
			Enum.NormalId.Back
		elseif surface_normal == LEFT_SURFACE_NAME then
			Enum.NormalId.Left
		elseif surface_normal == BOTTOM_SURFACE_NAME then
			Enum.NormalId.Bottom
		else
			Enum.NormalId.Front
end

local function get_transparency(transparency: number): number?
	return if transparency ~= 0 then transparency else nil
end

local function CREATE_CLONE_METHOD<I>(instance: I): () -> I
	return function()
		return (instance :: any):Clone()
	end
end

local function APPLY_TO_SURFACE(
	color: Color3,
	surface: Enum.SurfaceType,
	face: Enum.NormalId,
	texture_name: string
): Texture
	local texture = UNSAFE_GET_TEXTURE_FOR_SURFACE(surface):Clone()
	texture.Name = texture_name
	texture.Color3 = color
	texture.Face = face
	return texture
end

--[[
	Adds SurfaceNormal [Textures](https://create.roblox.com/docs/reference/engine/classes/Texture)
	to *`part`* based on the SurfaceNormal arguments provided for each side of *`part`*
]]
local function APPLY_SURFACES(
	part: BasePart,
	right_surface: Enum.SurfaceType?,
	top_surface: Enum.SurfaceType?,
	back_surface: Enum.SurfaceType?,
	left_surface: Enum.SurfaceType?,
	bottom_surface: Enum.SurfaceType?,
	front_surface: Enum.SurfaceType?
)
	local transparency = get_transparency(part.Transparency)

	if transparency == 1 then
		return
	end

	local color = part.Color

	if transparency then
		if right_surface then
			local texture = APPLY_TO_SURFACE(color, right_surface, Enum.NormalId.Right, RIGHT_SURFACE_NAME)
			texture.Transparency = transparency
			texture.Parent = part
		end

		if top_surface then
			local texture = APPLY_TO_SURFACE(color, top_surface, Enum.NormalId.Top, TOP_SURFACE_NAME)
			texture.Transparency = transparency
			texture.Parent = part
		end

		if back_surface then
			local texture = APPLY_TO_SURFACE(color, back_surface, Enum.NormalId.Back, BACK_SURFACE_NAME)
			texture.Transparency = transparency
			texture.Parent = part
		end

		if left_surface then
			local texture = APPLY_TO_SURFACE(color, left_surface, Enum.NormalId.Left, LEFT_SURFACE_NAME)
			texture.Transparency = transparency
			texture.Parent = part
		end

		if bottom_surface then
			local texture = APPLY_TO_SURFACE(color, bottom_surface, Enum.NormalId.Bottom, BOTTOM_SURFACE_NAME)
			texture.Transparency = transparency
			texture.Parent = part
		end

		if front_surface then
			local texture = APPLY_TO_SURFACE(color, front_surface, Enum.NormalId.Front, FRONT_SURFACE_NAME)
			texture.Transparency = transparency
			texture.Parent = part
		end
	else
		if right_surface then
			APPLY_TO_SURFACE(color, right_surface, Enum.NormalId.Right, RIGHT_SURFACE_NAME).Parent = part
		end

		if top_surface then
			APPLY_TO_SURFACE(color, top_surface, Enum.NormalId.Top, TOP_SURFACE_NAME).Parent = part
		end

		if back_surface then
			APPLY_TO_SURFACE(color, back_surface, Enum.NormalId.Back, BACK_SURFACE_NAME).Parent = part
		end

		if left_surface then
			APPLY_TO_SURFACE(color, left_surface, Enum.NormalId.Left, LEFT_SURFACE_NAME).Parent = part
		end

		if bottom_surface then
			APPLY_TO_SURFACE(color, bottom_surface, Enum.NormalId.Bottom, BOTTOM_SURFACE_NAME).Parent = part
		end

		if front_surface then
			APPLY_TO_SURFACE(color, front_surface, Enum.NormalId.Front, FRONT_SURFACE_NAME).Parent = part
		end
	end
end

local function DESTROY_IF_CHILD_FOUND(instance: Instance, child_name: string)
	local child = instance:FindFirstChild(child_name)

	if child then
		child:Destroy()
	end
end

--[[
	Destroys all SurfaceNormal [Textures](https://create.roblox.com/docs/reference/engine/classes/Texture)
	parented to *`part`*
]]
local function DESTROY_SURFACES(part: BasePart)
	DESTROY_IF_CHILD_FOUND(part, RIGHT_SURFACE_NAME)
	DESTROY_IF_CHILD_FOUND(part, TOP_SURFACE_NAME)
	DESTROY_IF_CHILD_FOUND(part, BACK_SURFACE_NAME)
	DESTROY_IF_CHILD_FOUND(part, LEFT_SURFACE_NAME)
	DESTROY_IF_CHILD_FOUND(part, BOTTOM_SURFACE_NAME)
	DESTROY_IF_CHILD_FOUND(part, FRONT_SURFACE_NAME)
end

local pbr_surfaces = {
	convert_roblox_surface_to_pbr_surface = CONVERT_ROBLOX_SURFACE_TO_PBR_SURFACE,
	--[[
		Returns a copy of the [Texture](https://create.roblox.com/docs/reference/engine/classes/Texture) used for
		[Enum.SurfaceType.Universal](https://create.roblox.com/docs/reference/engine/enums/SurfaceType#Universal)
	]]
	universal_texture = CREATE_CLONE_METHOD(UNIVERSAL_TEXTURE),
	--[[
		Returns a copy of the [Texture](https://create.roblox.com/docs/reference/engine/classes/Texture) used for
		[Enum.SurfaceType.Studs](https://create.roblox.com/docs/reference/engine/enums/SurfaceType#Studs)
	]]
	studs_texture = CREATE_CLONE_METHOD(STUDS_TEXTURE),
	--[[
		Returns a copy of the [Texture](https://create.roblox.com/docs/reference/engine/classes/Texture) used for
		[Enum.SurfaceType.Inlet](https://create.roblox.com/docs/reference/engine/enums/SurfaceType#Inlet)
	]]
	inlet_texture = CREATE_CLONE_METHOD(INLET_TEXTURE),
	--[[
		Returns a copy of the [Texture](https://create.roblox.com/docs/reference/engine/classes/Texture) used for
		[Enum.SurfaceType.Weld](https://create.roblox.com/docs/reference/engine/enums/SurfaceType#Weld) and
		[Enum.SurfaceType.Glue](https://create.roblox.com/docs/reference/engine/enums/SurfaceType#Glue)
	]]
	weld_texture = CREATE_CLONE_METHOD(WELD_TEXTURE),
	destroy_surfaces = DESTROY_SURFACES,
	apply_surfaces = APPLY_SURFACES,
	get_surface = GET_SURFACE,
	set_surface = SET_SURFACE,
	--- Table including each SurfaceNormal string enum
	surface_normal = table.freeze({
		--- The right surface of a [Part](https://create.roblox.com/docs/reference/engine/classes/BasePart).
		right = RIGHT_SURFACE_NAME,
		--- The top surface of a [Part](https://create.roblox.com/docs/reference/engine/classes/BasePart).
		top = TOP_SURFACE_NAME,
		--- The back surface of a [Part](https://create.roblox.com/docs/reference/engine/classes/BasePart).
		back = BACK_SURFACE_NAME,
		--- The left surface of a [Part](https://create.roblox.com/docs/reference/engine/classes/BasePart).
		left = LEFT_SURFACE_NAME,
		--- The bottom surface of a [Part](https://create.roblox.com/docs/reference/engine/classes/BasePart).
		bottom = BOTTOM_SURFACE_NAME,
		--- The front surface of a [Part](https://create.roblox.com/docs/reference/engine/classes/BasePart).
		front = FRONT_SURFACE_NAME,
	}),
}

--[[
	Sets the *`surface`* for the specified *`surface_normal`* on the *`part`*, by setting an
	[attribute](https://create.roblox.com/docs/studio/properties#instance-attributes) on *`part`*
	with the name of *`surface_normal`* to be *`surface`*.

	The *`surface`* is then applied to the specified *`surface_normal`* by parenting a
	[Texture](https://create.roblox.com/docs/reference/engine/classes/Texture) to the *`part`*.
	If *`surface`* is `nil` or *`part`* is fully transparent, then no [Texture](https://create.roblox.com/docs/reference/engine/classes/Texture)
	is applied with the current applied [Texture](https://create.roblox.com/docs/reference/engine/classes/Texture)
	for *`surface_normal`* being destroyed if it exists.
]]
function pbr_surfaces.update_surface(part: BasePart, surface_normal: SurfaceNormal, surface: Enum.SurfaceType?)
	SET_SURFACE(part, surface_normal, surface)
	local texture = part:FindFirstChild(surface_normal)

	if texture then
		texture:Destroy()
	end

	if not surface then
		return
	end
	local transparency = get_transparency(part.Transparency)

	if transparency == 1 then
		return
	end

	texture = UNSAFE_GET_TEXTURE_FOR_SURFACE(surface):Clone()

	if transparency then
		texture.Transparency = transparency
	end

	texture.Face = surface_normal_to_normal_id(surface_normal)
	texture.Name = surface_normal
	texture.Color3 = part.Color
	texture.Parent = part
end

--[[
	Converts the SurfaceNormal properties of *`part`* to be SurfaceNormal
	[Attributes](https://create.roblox.com/docs/studio/properties#instance-attributes)
]]
function pbr_surfaces.convert_roblox_surfaces_to_pbr_surfaces(part: BasePart)
	APPLY_SURFACES(
		part,
		CONVERT_ROBLOX_SURFACE_TO_PBR_SURFACE(part, "RightSurface"),
		CONVERT_ROBLOX_SURFACE_TO_PBR_SURFACE(part, "TopSurface"),
		CONVERT_ROBLOX_SURFACE_TO_PBR_SURFACE(part, "BackSurface"),
		CONVERT_ROBLOX_SURFACE_TO_PBR_SURFACE(part, "LeftSurface"),
		CONVERT_ROBLOX_SURFACE_TO_PBR_SURFACE(part, "BottomSurface"),
		CONVERT_ROBLOX_SURFACE_TO_PBR_SURFACE(part, "FrontSurface")
	)
end

--[[
	Destroys all current SurfaceNormal [Textures](https://create.roblox.com/docs/reference/engine/classes/Texture)
	parented to *`part`*, and then parents new SurfaceNormal [Textures](https://create.roblox.com/docs/reference/engine/classes/Texture)
	to *`part`* based on its current SurfaceNormal [Attributes](https://create.roblox.com/docs/studio/properties#instance-attributes).
]]
function pbr_surfaces.update_from_attributes(part: BasePart)
	DESTROY_SURFACES(part)
	APPLY_SURFACES(
		part,
		GET_SURFACE(part, RIGHT_SURFACE_NAME),
		GET_SURFACE(part, TOP_SURFACE_NAME),
		GET_SURFACE(part, BACK_SURFACE_NAME),
		GET_SURFACE(part, LEFT_SURFACE_NAME),
		GET_SURFACE(part, BOTTOM_SURFACE_NAME),
		GET_SURFACE(part, FRONT_SURFACE_NAME)
	)
end

--[[
	Removes all SurfaceNormal attributes from *`part`*, and destroys all SurfaceNormal
	[Textures](https://create.roblox.com/docs/reference/engine/classes/Texture) parented to *`part`*
]]
function pbr_surfaces.clear_surfaces(part: BasePart)
	SET_SURFACE(part, "RightSurface", nil)
	SET_SURFACE(part, "TopSurface", nil)
	SET_SURFACE(part, "BackSurface", nil)
	SET_SURFACE(part, "LeftSurface", nil)
	SET_SURFACE(part, "BottomSurface", nil)
	SET_SURFACE(part, "FrontSurface", nil)
	DESTROY_SURFACES(part)
end

return table.freeze(pbr_surfaces)
