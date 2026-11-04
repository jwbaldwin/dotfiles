---
name: timers
description: Create, change, pause, run, or inspect James's scheduled jobs (cron-style, run by launchd) with the `timers` CLI. Use when James asks to run something on a schedule, "every morning", "every 15 minutes", "remind me", set up an automation, or asks what jobs or automations are running.
---

# timers

`timers` keeps one TOML file per job in `~/repos/personal/agent-automations/timers/jobs/<name>.toml` and loads each enabled job into launchd. James manages them by hand with `timers ui` (shift+cmd+j in Rex). Never write launchd plists or crontab entries yourself.

## Commands

```sh
timers                       # table: schedule, state, last run, result, next run
timers ls --all              # plus non-timers launch agents and crontab
timers add NAME --command CMD (--schedule CRON | --every 15m) [--cwd DIR] [--tab SESSION] [--description TEXT] [--disabled]
timers enable NAME | timers disable NAME
timers rm NAME
timers run NAME              # run now through launchd
timers logs NAME             # last 60 lines of output
```

To change an existing job, edit its TOML file, then run `timers sync`. Settings: `description`, `schedule` or `every`, `cwd`, `tab`, `enabled`, `command`.

## Choosing settings

- Names are lowercase-with-dashes and say the job, such as `morning-report`.
- `--schedule` is 5-field cron in local time (`30 8 * * 1-5` = weekdays 8:30) or `@hourly`/`@daily`/`@weekly`. A schedule can't restrict both day of month and weekday. Use `--every 30s|15m|2h|1d` for intervals.
- Commands run in zsh with James's PATH from when the job was synced.
- For an agent job James should watch or continue, use `--tab SESSION` and an interactive prompt, such as `--tab agents --command "pi 'morning report'"`. It opens a Rex tab in that session.
- For an unattended agent job, run headless with output in the log, such as `--command "pi -p 'summarize ...'"`.
- When the request is ambiguous about time, ask once. Otherwise pick sensible defaults and say what you chose.

## After creating or changing a job

Run `timers` and confirm the job shows `on` with the expected next run. If James wants proof it works, run `timers run NAME`, then check `timers logs NAME`. Tell James the job name, schedule, and command.
