-- let cmd+s save
rex.bind("cmd+s", "com.superlogical.terminal.write", { data = "\019" })

dofile(os.getenv("HOME") .. "/repos/projects/rex-res/lua/plugin.lua").setup({
	prefix = false,
})

local terminal = "com.superlogical.terminal"
local editors = { vi = true, vim = true, nvim = true, view = true, vimx = true }
local keys = { left = "ctrl+h", right = "ctrl+l", up = "ctrl+k", down = "ctrl+j" }
-- Rex can't report the app's tab style, so keep this in sync with Toggle Tab Style.
local tab_style = "vertical" -- "horizontal" when tabs are on top
local tab_actions = tab_style == "vertical" and { up = "client.tab.previous", down = "client.tab.next" }
	or { left = "client.tab.previous", right = "client.tab.next" }

-- This is the c-hjkl navigation that lets me move between panes and tabs
rex.action({
	name = "navigate",
	title = "Move between Rex panes and tabs, seamlesly",
	args = { direction = "string" },
	repeats = true,
	run = function(ctx, args)
		local direction = args.direction
		assert(keys[direction], "Unknown navigation direction")
		-- Physical keys go to Vim first; commands from Vim must not be sent back.
		if ctx.origin == "key" then
			local process = assert(rex.block.call(terminal, "process", {}))
			local name = process.foreground and process.foreground.name:lower() or ""
			local editor = name:gsub("^g", ""):gsub("diff$", "")
			if editors[editor] or name:find("fzf", 1, true) then
				rex.client.queue("pane.send_key", { key = keys[direction] })
				return
			end
		end

		local focused = assert(rex.session.focus_block({ block_id = ctx.block_id }))
		local moved = assert(rex.session.focus_direction({ direction = direction, wrap = false }))
		if moved.revision == focused.revision and tab_actions[direction] then
			rex.client.queue(tab_actions[direction])
		end
	end,
})

for direction, key in pairs(keys) do
	rex.bind(key, "navigate", { direction = direction })
end

rex.action({
	name = "open_opencode",
	title = "Open OpenCode in a new tab",
	run = function(ctx)
		local process = assert(rex.block.call(terminal, "process", {}))
		local cwd = process.foreground and process.foreground.cwd
		if not cwd then
			cwd = assert(rex.block.call(terminal, "pwd", {})).pwd
		end
		assert(cwd, "The focused terminal has no working directory")

		local window = assert(rex.session.new_window({
			layout = rex.layout.block({
				flavor = terminal .. ".shell",
				options = {
					-- Load your PATH and keep the shell so Rex can identify OpenCode.
					command = { "/bin/zsh", "-lic", "opencode" },
					shell = "none",
					cwd = cwd,
				},
			}),
		}))
		-- A queued client action runs before the app has received the new tab, so select it from a separate process.
		assert(rex.exec.start({
			os.getenv("HOME") .. "/.local/bin/rex",
			"--client",
			ctx.client_id,
			"do",
			"session.select",
			"session_id=" .. ctx.session_id,
			"window_id=" .. window.window_id,
		}, { detach = true }))
	end,
})

-- rex.bind("ctrl+n", "open_opencode")
