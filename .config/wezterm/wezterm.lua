local wezterm = require("wezterm")

local config = {
	window_background_opacity = 0.98,
	use_fancy_tab_bar = false,
	-- enable_tab_bar = false,
	hide_tab_bar_if_only_one_tab = true,
	window_decorations = "RESIZE",
	font_size = 15,
	-- font = wezterm.font("Monaspace Argon", { weight = "Regular" }),
	font = wezterm.font("Berkeley Mono", { weight = "Regular" }),
	-- font = wezterm.font("DankMono Nerd Font", { weight = "Regular" }),
	font_rules = {
		{
			italic = true,
			font = wezterm.font("Berkeley Mono", { weight = "Regular", style = "Italic" }),
		},
	},
	harfbuzz_features = {
		"calt=1",
		"dlig=1",
		"clig=1",
		"ss01=1",
		"ss02=1",
		"ss03=1",
		"ss04=1",
		"ss05=1",
		"ss06=1",
		"ss07=1",
		"ss08=1",
	},
	bold_brightens_ansi_colors = "BrightAndBold",
	line_height = 1.35,
	front_end = "WebGpu",
	audible_bell = "Disabled",
	adjust_window_size_when_changing_font_size = true,
	native_macos_fullscreen_mode = true,
	keys = {
		{
			key = "f",
			mods = "CMD|CTRL",
			action = wezterm.action.ToggleFullScreen,
		},
		{
			key = "s",
			mods = "CMD",
			action = wezterm.action.SendKey({ key = "\x13", mods = "CMD" }),
		},
	},
}

local appearance = wezterm.gui.get_appearance()

if appearance:find("Dark") then
	config.color_scheme = "tokyonight_night"
else
	config.color_scheme = "tokyonight_day"
	config.window_background_opacity = 1
end

return config
