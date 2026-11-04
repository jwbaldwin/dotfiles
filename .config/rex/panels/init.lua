local M = {}

function M.open(label, program, bounds)
	local _, err = rex.session.new_layer({
		bounds = bounds,
		focus = true,
		layout = rex.layout.block({
			flavor = "com.superlogical.terminal.shell",
			label = label,
			options = {
				-- A login, interactive zsh loads mise, so glab, jq, fzf, uv, and pi are on PATH.
				command = { "/bin/zsh", "-lic", program },
				shell = "none",
			},
		}),
	})
	if err ~= nil then
		error(err, 0)
	end
end

return M
