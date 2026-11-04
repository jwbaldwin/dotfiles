local panels = require("panels")

rex.action({
	name = "review_queue",
	title = "Review Queue",
	description = "Pick a GitLab MR waiting on your review and open pi on it",
	keywords = "gitlab mr merge request review",
	run = function()
		panels.open("Review queue", "review-queue", { 0.1, 0.08, 0.8, 0.84 })
	end,
})

rex.bind("shift+cmd+r", "review_queue")
