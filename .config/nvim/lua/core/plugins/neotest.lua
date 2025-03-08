local neotest = require("neotest")

neotest.setup_project(vim.loop.cwd(), {
	adapters = {
		require("neotest-elixir"),
	},
	default_strategy = "iex",
})

neotest.setup({
	adapters = {
		require("neotest-elixir"),
	},
	output_panel = {
		enabled = true,
		open = "vsplit",
	},
	consumers = {
		notify = function(client)
			client.listeners.results = function(adapter_id, results, partial)
				-- Partial results can be very frequent
				if partial then
					return
				end

				local total = 0
				local failure_count = 0

				-- Iterate over the results table to count successes and failures
				for _, result in pairs(results) do
					if result.status == "failed" then
						failure_count = failure_count + 1
					end
					total = total + 1
				end

				-- Format the notification message
				local message = string.format("%d tests, %d failures", total, failure_count)

				-- Use the notify plugin to display the message
				if failure_count > 0 then
					require("notify")(message, "error")
				else
					require("notify")(message, "info")
				end
			end
			return {}
		end,
	},
})
