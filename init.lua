-- adapted from arjuncgore/waywall_barebones_config
local waywall = require("waywall")
local helpers = require("waywall.helpers")

local TYPING_STATE = false
local TYPING_MSG = nil

local TOGGLE_TYPING = function()
	if TYPING_STATE then
		if TYPING_MSG then TYPING_MSG:close() end
		TYPING_STATE = false
		return
	end
	TYPING_STATE = true
	TYPING_MSG = waywall.text("TYPING", {
		x = 10,
		y = 10,
		color = "#1E5CA8",
		size = 12,
		depth = 1,
	})
end

-- TOOLS OR KEYBINDS U NEED TO CHANGE AND SHIT
local ninjabrain = "/usr/local/bin/Ninjabrain-Bot-1.5.2.jar"
--keys
local toggleninja = "*-g"
local thin = "*-b"
local tall = "*-v"
local wide = "*-z"
local typemap = "Shift_R"
--remappings
local typingmapping = {
	["CAPSLOCK"] = "F3",
}
local defaultmapping = {
	["R"] = "ESC",
}
for r,n in pairs(typingmapping) do defaultmapping[r] = n end
-- godsense 0.02291165
local nsense = 5.52192927
local tsense = 0.13730547

--helppp
local ninjastat = function()
	local handle = io.popen("pgrep -f 'Ninjabrain.*jar'")
	if not handle then return nil end
	local result = handle:read("*l")
	handle:close()
	return result ~= nil
end


local config = {
}

config.input = {
	layout = "us",
	options = "",
	remaps = defaultmapping,
	confine_pointer = false,
	repeat_delay = 300,
	repeat_rate = 20,
	sensitivity = nsense,
}

config.theme = {
	background = "#1E5CA8FF",
	ninb_anchor = {
		position = "topright",
		y = 150,
	},
	ninb_opacity = 1,
}

local make_mapping = function(confunc, enable, enmap, disable, dismap)
	return function()
		if confunc() then
			waywall.set_remaps(enmap)
			enable()
		else
			waywall.set_remaps(dismap)
			disable()
		end
		return false
	end
end

local make_image = function(path, dest)
	local this = nil

	return function(enable)
		if enable and not this then
			this = waywall.image(path, dest)
		elseif this and not enable then
			this:close()
			this = nil
		end
	end
end

local make_mirror = function(options)
	local this = nil

	return function(enable)
		if enable and not this then
			this = waywall.mirror(options)
		elseif this and not enable then
			this:close()
			this = nil
		end
	end
end

local make_res = function(width, height, enable, disable)
	return function()
		local active_width, active_height = waywall.active_res()

		if active_width == width and active_height == height then
			waywall.set_resolution(0, 0)
			disable()
		else
			waywall.set_resolution(width, height)
			enable()
		end
		return false
	end
end

local images = {
}

local mirrors = {
	eye_measure = make_mirror({
		src = { x = 155, y = 8177, w = 30, h = 30 },
		dst = { x = 0, y = 165, w = 1110, h = 1110},
	}),
}

local normal_sense = function()
	mirrors.eye_measure(false)
	waywall.set_sensitivity(nsense)
end

local tall_enable = function()
	mirrors.eye_measure(true)
	waywall.set_sensitivity(tsense)
end

local resolutions = {
	thin = make_res(340, 1080, normal_sense, normal_sense),
	tall = make_res(340, 16384, tall_enable, normal_sense),
	wide = make_res(2560, 340, normal_sense, normal_sense),
}

local mappings = {
	typing = make_mapping(function() return not TYPING_STATE end, TOGGLE_TYPING, typingmapping, TOGGLE_TYPING, defaultmapping)
}

config.actions = {
	-- only raw actions go here everything else should go below to get wrapped by typing toggle
	[typemap] = mappings.typing,
}
local wrappedactions = {
	[thin] = resolutions.thin,
	[tall] = resolutions.tall,
	[wide] = resolutions.wide,
	[toggleninja] = function()
		if not ninjastat() then
			waywall.exec("java -Dawt.useSystemAAFontSettings=on -jar " .. ninjabrain)
			waywall.show_floating(true)
		else
			helpers.toggle_floating()
		end
		return false
	end
}

local wrapper = function(wrapped)
	return function()
		if TYPING_STATE then return false end
		return wrapped()
	end
end

for i,v in pairs(wrappedactions) do config.actions[i]=wrapper(v) end

return config
