
--[[
	PBR Attribute Stripper
	most jank code ive ever written, but this is a cli for removing SurfaceNormal attributes from BaseParts
	in the Workspace of a place file, or instances in a model file
]]

local process = require("@lune/process")
local roblox = require("@lune/roblox")
local stdio = require("@lune/stdio")
local fs = require("@lune/fs")

local BOTTOM_SURFACE_NAME = "BottomSurface"
local RIGHT_SURFACE_NAME = "RightSurface"
local FRONT_SURFACE_NAME = "FrontSurface"
local LEFT_SURFACE_NAME = "LeftSurface"
local BACK_SURFACE_NAME = "BackSurface"
local TOP_SURFACE_NAME = "TopSurface"
local VERSION = "0.1.0"
local ARGS = process.args
local OUTPUT_PATH: string
local INPUT_PATH: string
local OVERWRITE = false

-- returns if its a place file, if its an xml file
local function IS_PLACE_FILE(path: string): (boolean, boolean)
	local path_end = string.sub(path, #path - 6, #path)
	local is_xml = path_end == ".rbxlx"

	return is_xml or string.sub(path_end, 2, 6) == ".rbxl", is_xml
end

local function SWAP_REMOVE<V>(t: { V }, index: number, len: number): V
	if len ~= 1 then
		local value = t[index]
		t[index] = t[len]
		t[len] = nil
		return value
	else
		local value = t[len]
		t[len] = nil
		return value
	end
end

-- returns if its a model file, if its an xml file
local function IS_MODEL_FILE(path: string): (boolean, boolean)
	local path_end = string.sub(path, #path - 6, #path)
	local is_xml = path_end == ".rbxmx"

	return is_xml or string.sub(path_end, 2, 6) == ".rbxm", is_xml
end

local function BOLD(...: string)
	return stdio.style("bold") .. table.concat({ ... }, " ") .. stdio.color("reset")
end

local function DIM(...: string)
	return stdio.style("dim") .. table.concat({ ... }, " ") .. stdio.color("reset")
end

local function PRINTNL(...: any)
	print(table.concat({ ... }, "\n") .. "\n")
end

local ARGS_INDEX = 1
local ARG = ARGS[ARGS_INDEX]

local function print_help()
	PRINTNL(
		`{BOLD("PBR Surface Attribute Stripper")} {DIM(VERSION)}`,
		"Strips PBR SurfaceNormal Attributes from Part(s) in Workspace in a Roblox place file (.rbxl, .rbxlx).",
		"Or Part(s) in a Roblox model file (.rbxm, .rbxmx).\n",

		BOLD("USAGE"),
		"\tpbrsas <input roblox file> [flags]\n",

		BOLD("ARGS"),
		"\t<roblox file>\tPath to the roblox file to strip PBR SurfaceNormal Attributes from.\n",

		BOLD("OPTIONS"),
		"\t-ow, --overwrite\tOverwrites the input file with the stripped version",
		"\t-o, --output <output>\tWhere to output the result",
		"\t-h, --help\tPrints help information (what you're seeing currently)",
		"\t-v, --version\tPrints the version of PBR Surface Attribute Stripper you're using"
	)
end

if #ARGS == 0 then
	print_help()
	return
end

for _, argument in ARGS do
	if ARG == "-h" or ARG == "--h" or ARG == "--help" or ARG == "-help" or ARG == "help" then
		print_help()
		return
	elseif ARG == "-v" or ARG == "--v" or ARG == "--version" or ARG == "-version" or ARG == "version" then
		print(`PBR Surface Attribute Stripper (pbrsas) {VERSION}`)
		return
	end
end

ARGS_INDEX += 1

while ARGS_INDEX <= #ARGS do
	local arg = ARGS[ARGS_INDEX]

	if arg == "-input" or arg == "-i" or arg == "--input" or arg == "--i" then
		if INPUT_PATH then
			error("")
		end
		ARGS_INDEX += 1
		local input_path = ARGS[ARGS_INDEX]

		if not fs.isFile(input_path) then
			error(`Expected file path for option "input", got "{input_path}" instead.`)
		end

		if IS_PLACE_FILE(input_path) or IS_MODEL_FILE(input_path) then
			INPUT_PATH = input_path
		else
			error(`Expected Roblox file for option "input", got "{input_path}" instead.`)
		end
	elseif arg == "-output" or arg == "-o" or arg == "--output" or arg == "--o" then
		if OVERWRITE then
			error("Cannot use output when overwrite is enabled")
		elseif OUTPUT_PATH then
			error("Cannot define more than 1 output path")
		end
		ARGS_INDEX += 1
		local output_path = ARGS[ARGS_INDEX]

		fs.isFile(output_path)

		if IS_PLACE_FILE(output_path) or IS_MODEL_FILE(output_path) then
			OUTPUT_PATH = output_path
		else
			error(`Expected file path for option "output", got "{output_path}" instead.`)
		end
	elseif arg == "-overwrite" or arg == "-ow" or arg == "--overwrite" or arg == "--ow" then
		if OUTPUT_PATH then
			error("Cannot use overwrite when an output path has already been provided")
		elseif OVERWRITE then
			error("Cannot define overwrite more than once")
		end

		OVERWRITE = true
	elseif IS_MODEL_FILE(arg) or IS_PLACE_FILE(arg) then
		if INPUT_PATH then
			error("Cannot define more than 1 input path")
		end

		if not fs.isFile(arg) then
			error(`Expected file path for option "input", got "{arg}" instead.`)
		end

		if IS_PLACE_FILE(arg) or IS_MODEL_FILE(arg) then
			INPUT_PATH = arg
		else
			error(`Expected Roblox file for option "input", got "{arg}" instead.`)
		end
	end
end

if not INPUT_PATH then
	error("No valid input path provided")
end

if not (OUTPUT_PATH or OVERWRITE) then
	error("No valid output path provided or overwrite flag")
end

local is_place = IS_PLACE_FILE(INPUT_PATH) and IS_PLACE_FILE(OUTPUT_PATH)
local is_model = IS_MODEL_FILE(INPUT_PATH) and IS_MODEL_FILE(OUTPUT_PATH)

local function clear_surface_normal_attributes(part: roblox.Instance)
	part:SetAttribute(RIGHT_SURFACE_NAME, nil)
	part:SetAttribute(TOP_SURFACE_NAME, nil)
	part:SetAttribute(BACK_SURFACE_NAME, nil)
	part:SetAttribute(LEFT_SURFACE_NAME, nil)
	part:SetAttribute(BOTTOM_SURFACE_NAME, nil)
	part:SetAttribute(FRONT_SURFACE_NAME, nil)
end

local function process_instances(instances: { roblox.Instance })
	local queue = table.clone(instances)
	local queue_len = #queue

	while queue_len ~= 0 do
		local instance = SWAP_REMOVE(queue, 1, queue_len)
		queue_len -= 1

		if instance:IsA("BasePart") then
			clear_surface_normal_attributes(instance)
		end

		if instance:FindFirstChildWhichIsA("BasePart", true) then
			local descendants = instance:GetDescendants()
			local descendants_len = #descendants

			table.move(descendants, 1, descendants_len, queue_len + 1, queue)
			queue_len += descendants_len
		end
	end
end

if not is_model then
	error("Both input and output paths must point to Roblox model files")
elseif not is_place then
	error("Both input and output paths must point to Roblox place files")
elseif is_model then
	local model_instances = roblox.deserializeModel(fs.readFile(INPUT_PATH))

	process_instances(model_instances)

	if OVERWRITE then
		local _, is_xml = IS_MODEL_FILE(INPUT_PATH)
		fs.writeFile(INPUT_PATH, roblox.serializeModel(model_instances, is_xml))
	elseif OUTPUT_PATH then
		local _, is_xml = IS_MODEL_FILE(OUTPUT_PATH)
		fs.writeFile(OUTPUT_PATH, roblox.serializeModel(model_instances, is_xml))
	else
		local _, is_xml = IS_MODEL_FILE(INPUT_PATH)
		print(roblox.serializeModel(model_instances, is_xml))
	end
elseif is_place then
	local game = roblox.deserializePlace(fs.readFile(INPUT_PATH))
	local workspace = game:FindFirstAncestorOfClass("Workspace")

	if not workspace then
		error("No workspace found in place file")
	end
	process_instances(workspace:GetDescendants())

	if OVERWRITE then
		local _, is_xml = IS_PLACE_FILE(INPUT_PATH)
		fs.writeFile(INPUT_PATH, roblox.serializePlace(game, is_xml))
	elseif OUTPUT_PATH then
		local _, is_xml = IS_PLACE_FILE(OUTPUT_PATH)
		fs.writeFile(OUTPUT_PATH, roblox.serializePlace(game, is_xml))
	else
		local _, is_xml = IS_PLACE_FILE(INPUT_PATH)
		print(roblox.serializePlace(game, is_xml))
	end
end
