local Utils = require("avante.utils")

local M = {}

M.defaults = {
	debug = false,
	---@alias Provider "claude" | "openai" | "azure" | "gemini" | "cohere" | "copilot" | [string]
	provider = "claude", -- Only recommend using Claude
	auto_suggestions_provider = "claude",
	system_prompt = [[
You are an excellent programming expert.
]],
	behaviour = {
		auto_suggestions = false, -- Experimental stage
		auto_set_highlight_group = true,
		auto_set_keymaps = true,
		auto_apply_diff_after_generation = false,
		support_paste_from_clipboard = false,
	},
	history = {
		storage_path = vim.fn.stdpath("state") .. "/avante",
		paste = {
			extension = "png",
			filename = "pasted-%Y-%m-%d-%H-%M-%S",
		},
	},
	highlights = {
		diff = {
			current = "DiffText",
			incoming = "DiffAdd",
		},
	},
	mappings = {
		diff = {
			ours = "co",
			theirs = "ct",
			all_theirs = "ca",
			both = "cb",
			cursor = "cc",
			next = "]x",
			prev = "[x",
		},
		suggestion = {
			accept = "<M-l>",
			next = "<M-]>",
			prev = "<M-[>",
			dismiss = "<C-]>",
		},
		jump = {
			next = "]]",
			prev = "[[",
		},
		submit = {
			normal = "<CR>",
			insert = "<C-s>",
		},
		-- NOTE: The following will be safely set by avante.nvim
		ask = "<leader>aa",
		edit = "<leader>ae",
		refresh = "<leader>ar",
		toggle = {
			default = "<leader>at",
			debug = "<leader>ad",
			hint = "<leader>ah",
			suggestion = "<leader>as",
		},
		sidebar = {
			switch_windows = "<Tab>",
			reverse_switch_windows = "<S-Tab>",
		},
	},
	windows = {
		---@alias AvantePosition "right" | "left" | "top" | "bottom"
		position = "right",
		wrap = true, -- similar to vim.o.wrap
		width = 30, -- default % based on available width in vertical layout
		height = 30, -- default % based on available height in horizontal layout
		sidebar_header = {
			align = "center", -- left, center, right for title
			rounded = true,
		},
		input = {
			prefix = "> ",
		},
		edit = {
			border = "rounded",
		},
	},
	--- @class AvanteConflictConfig
	diff = {
		autojump = true,
	},
	--- @class AvanteHintsConfig
	hints = {
		enabled = true,
	},
}

---@type avante.Config
M.options = {}

---@class avante.ConflictConfig: AvanteConflictConfig
---@field mappings AvanteConflictMappings
---@field highlights AvanteConflictHighlights
M.diff = {}

---@type Provider[]
M.providers = {}

---@param opts? avante.Config
function M.setup(opts)
	vim.validate({ opts = { opts, "table", true } })

	M.options = vim.tbl_deep_extend(
		"force",
		M.defaults,
		opts or {},
		---@type avante.Config
		{
			behaviour = {
				support_paste_from_clipboard = M.support_paste_image(),
			},
		}
	)
	M.providers = vim.iter(M.defaults)
		:filter(function(_, value)
			return type(value) == "table" and value.endpoint ~= nil
		end)
		:fold({}, function(acc, k)
			acc = vim.list_extend({}, acc)
			acc = vim.list_extend(acc, { k })
			return acc
		end)

	vim.validate({ provider = { M.options.provider, "string", false } })

	M.diff = vim.tbl_deep_extend(
		"force",
		{},
		M.options.diff,
		{ mappings = M.options.mappings.diff, highlights = M.options.highlights.diff }
	)

	if next(M.options.vendors) ~= nil then
		for k, v in pairs(M.options.vendors) do
			M.options.vendors[k] = type(v) == "function" and v() or v
		end
		vim.validate({ vendors = { M.options.vendors, "table", true } })
		M.providers = vim.list_extend(M.providers, vim.tbl_keys(M.options.vendors))
	end
end

---@param opts? avante.Config
function M.override(opts)
	vim.validate({ opts = { opts, "table", true } })

	M.options = vim.tbl_deep_extend("force", M.options, opts or {})
	M.diff = vim.tbl_deep_extend(
		"force",
		{},
		M.options.diff,
		{ mappings = M.options.mappings.diff, highlights = M.options.highlights.diff }
	)

	if next(M.options.vendors) ~= nil then
		for k, v in pairs(M.options.vendors) do
			M.options.vendors[k] = type(v) == "function" and v() or v
			if not vim.tbl_contains(M.providers, k) then
				M.providers = vim.list_extend(M.providers, { k })
			end
		end
		vim.validate({ vendors = { M.options.vendors, "table", true } })
	end
end

M = setmetatable(M, {
	__index = function(_, k)
		if M.options[k] then
			return M.options[k]
		end
	end,
})

M.support_paste_image = function()
	return Utils.has("img-clip.nvim") or Utils.has("img-clip")
end

M.get_window_width = function()
	return math.ceil(vim.o.columns * (M.windows.width / 100))
end
M.has_provider = function(provider)
	return M.options[provider] ~= nil or M.vendors[provider] ~= nil
end

M.get_provider = function(provider)
	if M.options[provider] ~= nil then
		return vim.deepcopy(M.options[provider], true)
	elseif M.vendors[provider] ~= nil then
		return vim.deepcopy(M.vendors[provider], true)
	else
		error("Failed to find provider: " .. provider, 2)
	end
end

M.BASE_PROVIDER_KEYS = {
	"endpoint",
	"model",
	"deployment",
	"api_version",
	"proxy",
	"allow_insecure",
	"api_key_name",
	"timeout",
	-- internal
	"local",
	"_shellenv",
	"tokenizer_id",
	"use_xml_format",
}

return M
