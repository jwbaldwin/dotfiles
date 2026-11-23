local terminal = "com.superlogical.terminal"
local max_items = 2000
local chunk_bytes = 983040

local function terminal_text(block_id)
	local screen = assert(rex.block.call(terminal, "format", {
		block_id = block_id,
		trim = true,
		unwrap = true,
		max_bytes = chunk_bytes,
	}))
	local parts = { screen.content }
	local offset = #screen.content
	local more = screen.id ~= nil
	while more do
		local part = assert(rex.block.call(terminal, "blob_read", {
			block_id = block_id,
			id = screen.id,
			offset = offset,
			max_bytes = chunk_bytes,
		}))
		parts[#parts + 1] = part.data
		offset = offset + #part.data
		more = not part.eof and #part.data > 0
	end
	return table.concat(parts)
end

local function pi_session_file(cwd)
	local folder = os.getenv("HOME") .. "/.pi/agent/sessions/--" .. cwd:sub(2):gsub("/", "-") .. "--"
	local newest = assert(rex.exec({ "/bin/sh", "-c", 'ls -t -- "$1"/*.jsonl 2>/dev/null | head -n 1', "sh", folder }))
	local path = newest.stdout:gsub("%s+$", "")
	return path ~= "" and path or nil
end

local function add_strings(value, out)
	if type(value) == "string" then
		out[#out + 1] = value
	elseif type(value) == "table" then
		for _, v in pairs(value) do
			add_strings(v, out)
		end
	end
end

-- What James and the agent wrote, plus tool arguments. Tool output and the system prompt would bury them in noise.
local function session_text(session_file)
	local file = assert(io.open(session_file, "r"))
	local transcript = file:read("*a")
	file:close()

	local texts = {}
	-- Rex's io.lines cuts lines at 4 KiB, so split the whole file instead.
	for line in transcript:gmatch("[^\n]+") do
		local role = line:match('^{"type":"message".-"message":{"role":"(%a+)"')
		if role == "user" or role == "assistant" then
			local entry = assert(rex.json.decode(line))
			local content = entry.message.content
			if type(content) == "string" then
				texts[#texts + 1] = content
			elseif type(content) == "table" then
				for _, part in ipairs(content) do
					if part.type == "text" then
						texts[#texts + 1] = part.text
					elseif part.type == "toolCall" then
						add_strings(part.arguments, texts)
					end
				end
			end
		end
	end
	return table.concat(texts, "\n")
end

local function looks_like_file(token)
	return token:find("/", 1, true) or token:find("%.%a%w*$")
end

local function absolute_path(token, cwd, home)
	if token:sub(1, 2) == "~/" then
		return home .. token:sub(2)
	elseif token:sub(1, 1) == "/" then
		return token
	end
	return cwd .. "/" .. token:gsub("^%./", "")
end

-- Newest mention first, so the latest work is at the top of the picker.
local function mentioned_paths(text, cwd, home)
	local tokens = {}
	for token in text:gmatch("[%w_%.%-/~+@]+") do
		tokens[#tokens + 1] = token
	end

	local paths, seen = {}, {}
	for i = #tokens, 1, -1 do
		local token = tokens[i]:gsub("[:%d]+$", ""):gsub("%.+$", "")
		if #token > 1 and looks_like_file(token) then
			local path = absolute_path(token, cwd, home)
			if not seen[path] then
				seen[path] = true
				paths[#paths + 1] = path
			end
		end
	end
	return paths
end

local function existing_files(paths)
	if #paths == 0 then
		return {}
	end
	local argv = { "/bin/sh", "-c", 'for p; do [ -f "$p" ] && printf "%s\\n" "$p"; done', "sh" }
	for _, path in ipairs(paths) do
		argv[#argv + 1] = path
	end
	local result = assert(rex.exec(argv, { timeout = 10 }))
	local files = {}
	for line in result.stdout:gmatch("[^\n]+") do
		files[#files + 1] = line
		if #files == max_items then
			break
		end
	end
	return files
end

local function display_path(path, cwd, home)
	if path:sub(1, #cwd + 1) == cwd .. "/" then
		return path:sub(#cwd + 2)
	elseif path:sub(1, #home + 1) == home .. "/" then
		return "~" .. path:sub(#home + 1)
	end
	return path
end

rex.action({
	name = "mentioned_files",
	title = "Mentioned Files",
	description = "Pick files mentioned in the focused agent session and open them in Neovim to the right",
	keywords = "files nvim neovim agent pi claude codex session open",
	run = function(ctx)
		local home = os.getenv("HOME")
		local process = assert(rex.block.call(terminal, "process", { block_id = ctx.block_id }))
		local cwd = process.foreground and process.foreground.cwd
		assert(cwd, "The focused terminal has no working directory")

		-- Pi's fullscreen mode keeps no scrollback, but its session log has the whole conversation.
		local session_file = process.foreground.argv0 == "pi" and pi_session_file(cwd)
		local text = session_file and session_text(session_file) or terminal_text(ctx.block_id)
		local files = existing_files(mentioned_paths(text, cwd, home))
		if #files == 0 then
			error("No existing files are mentioned in this session", 0)
		end

		local items = {}
		for _, path in ipairs(files) do
			items[#items + 1] = {
				id = path,
				title = path:match("[^/]+$"),
				subtitle = display_path(path, cwd, home):match("^(.*)/[^/]+$"),
				icon = "document",
				selected = true,
			}
		end

		local chosen = rex.ui.pick({
			title = "Open session files in Neovim",
			placeholder = "Filter files",
			confirm = "Open in Neovim",
			multiple = true,
			items = items,
		})
		if chosen == nil or #chosen == 0 then
			return
		end

		local command = { "nvim", "--" }
		for _, path in ipairs(chosen) do
			command[#command + 1] = path
		end
		assert(rex.session.new_split({
			anchor_id = ctx.block_id,
			direction = "horizontal",
			side = "after",
			focus = true,
			layout = rex.layout.block({
				flavor = terminal .. ".shell",
				options = { command = command, cwd = cwd },
			}),
		}))
	end,
})

rex.bind("shift+cmd+f", "mentioned_files")
