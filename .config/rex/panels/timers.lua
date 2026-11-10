local panels = require("panels")

rex.action({
	name = "scheduled_jobs",
	title = "Scheduled Jobs",
	description = "See, run, edit, and create timers",
	keywords = "cron launchd timers schedule automation jobs",
	run = function()
		panels.open("Scheduled jobs", "timers ui", { 0.2, 0.2, 0.6, 0.5 })
	end,
})

rex.bind("shift+cmd+t", "scheduled_jobs")
