local session = require("auto-session")

session.setup {
  log_level = "error",
  auto_save_enabled = true,
  auto_restore_enabled = true,
  auto_session_use_git_branch = true
}
