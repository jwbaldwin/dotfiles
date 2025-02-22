local wezterm = require("wezterm")

local config = {
	window_background_opacity = 0.98,
	use_fancy_tab_bar = false,
	-- enable_tab_bar = false,
	hide_tab_bar_if_only_one_tab = true,
	window_decorations = "RESIZE | MACOS_FORCE_ENABLE_SHADOW",
	window_padding = {
		-- 	left = 2,
		-- 	right = 2,
		-- 	top = 10,
		bottom = 0,
	},
	font_size = 16,
	-- font = wezterm.font("Monaspace Neon", { weight = "Regular" }),
	-- font = wezterm.font("DankMono Nerd Font", { weight = "Bold" }),
	-- font = wezterm.font("MonoLisa", { weight = "Book" }),
	-- font = wezterm.font("Operator Mono", { weight = 325 }),
	font = wezterm.font("Berkeley Mono", { weight = "Regular" }),
	-- font_rules = {
	-- 	{
	-- 		italic = true,
	-- 		font = wezterm.font("Operator Mono", { weight = "Regular", style = "Italic" }),
	-- 	},
	-- },
	harfbuzz_features = {
		"calt=0",
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
	-- line_height = 1.35,
	-- cell_width = 0.90,
	front_end = "WebGpu",
	audible_bell = "Disabled",
	adjust_window_size_when_changing_font_size = true,
	native_macos_fullscreen_mode = true,
	-- leader = { key = "a", mods = "CTRL" },
	keys = {
		{
			key = "p",
			mods = "LEADER",
			action = wezterm.action.ActivateCommandPalette,
		},
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
		{
			key = ";",
			mods = "CTRL",
			action = wezterm.action.SendKey({ key = "\x1F", mods = "CMD" }),
		},
		-- Tab and Pane management
		-- {
		-- 	key = "l",
		-- 	mods = "LEADER",
		-- 	action = wezterm.action.ActivateLastTab,
		-- },
		-- Split horizontal and vertical
		-- {
		-- 	key = "s",
		-- 	mods = "LEADER",
		-- 	action = wezterm.action.SplitPane({
		-- 		direction = "Right",
		-- 		size = { Percent = 50 },
		-- 	}),
		-- },
		-- {
		-- 	key = "h",
		-- 	mods = "LEADER",
		-- 	action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }),
		-- },
		-- -- Kill pane
		-- {
		-- 	key = "k",
		-- 	mods = "LEADER",
		-- 	action = wezterm.action.CloseCurrentPane({ confirm = true }),
		-- },
		-- -- Move tab left or right, move panes
		-- { key = "[", mods = "LEADER", action = wezterm.action.MoveTabRelative(-1) },
		-- { key = "]", mods = "LEADER", action = wezterm.action.MoveTabRelative(1) },
		-- {
		-- 	key = "LeftArrow",
		-- 	mods = "LEADER",
		-- 	action = wezterm.action.ActivatePaneDirection("Left"),
		-- },
		-- {
		-- 	key = "RightArrow",
		-- 	mods = "LEADER",
		-- 	action = wezterm.action.ActivatePaneDirection("Right"),
		-- },
		-- {
		-- 	key = "UpArrow",
		-- 	mods = "LEADER",
		-- 	action = wezterm.action.ActivatePaneDirection("Up"),
		-- },
		-- {
		-- 	key = "DownArrow",
		-- 	mods = "LEADER",
		-- 	action = wezterm.action.ActivatePaneDirection("Down"),
		-- },
		-- {
		-- 	key = "n",
		-- 	mods = "LEADER",
		-- 	action = wezterm.action.ActivatePaneDirection("Next"),
		-- },
		-- {
		-- 	key = "p",
		-- 	mods = "LEADER",
		-- 	action = wezterm.action.ActivatePaneDirection("Prev"),
		-- },
		-- { key = "Tab", mods = "CTRL", action = "DisableDefaultAssignment" },
		-- { key = "1", mods = "CTRL", action = wezterm.action({ ActivateTab = 0 }) },
		-- { key = "2", mods = "CTRL", action = wezterm.action({ ActivateTab = 1 }) },
		-- { key = "3", mods = "CTRL", action = wezterm.action({ ActivateTab = 2 }) },
		-- { key = "4", mods = "CTRL", action = wezterm.action({ ActivateTab = 3 }) },
		-- { key = "5", mods = "CTRL", action = wezterm.action({ ActivateTab = 4 }) },
		-- { key = "6", mods = "CTRL", action = wezterm.action({ ActivateTab = 5 }) },
		-- { key = "7", mods = "CTRL", action = wezterm.action({ ActivateTab = 6 }) },
		-- { key = "8", mods = "CTRL", action = wezterm.action({ ActivateTab = 7 }) },
		-- { key = "9", mods = "CTRL", action = wezterm.action({ ActivateTab = 8 }) },
	},
}

local appearance = wezterm.gui.get_appearance()

if appearance:find("Dark") then
	config.color_scheme = "tokyonight_night"
	-- config.color_scheme = "Everforest Dark Hard (Gogh)"
else
	config.color_scheme = "tokyonight_day"
	config.window_background_opacity = 1
end

return config
