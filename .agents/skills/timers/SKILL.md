---
name: timers
description: Create, change, pause, run, or inspect James's scheduled jobs (cron-style, run by launchd) with the `timers` CLI. Use when James asks to run something on a schedule, "every morning", "every 15 minutes", "remind me", set up an automation, or asks what jobs or automations are running.
---

# timers

`timers` keeps one TOML file per job in `~/repos/personal/agent-automations/timers/jobs/<name>.toml` and loads each enabled job into launchd. James manages them by hand with `timers ui` (also a Rex panel). Never write launchd plists or crontab entries yourself.

## Commands

```sh
timers                       # table: schedule, state, last run, result, next run
timers ls --all              # plus non-timers launch agents and crontab
timers add NAME --command CMD (--schedule CRON | --every 15m) [--cwd DIR] [--tab SESSION] [--description TEXT] [--expires DATE] [--disabled]
timers add NAME --check CHECK [--on-change CMD] (--schedule CRON | --every 15m) [--expires DATE] [--description TEXT]
timers enable NAME | timers disable NAME
timers snooze NAME|all [30m | 2h | 1d | 14:30]   # skip runs until then; default 1h
timers unsnooze NAME|all
timers rm NAME
timers run NAME              # run now through launchd
timers logs NAME             # last 60 lines of output
```

To change an existing job, edit its TOML file, then run `timers sync`. Settings: `description`, `schedule` or `every`, `cwd`, `tab`, `enabled`, `expires`, and either `command` or `check` with `on_change`.

## Choosing settings

- Names are lowercase-with-dashes and say the job, such as `morning-report`.
- `--schedule` is 5-field cron in local time (`30 8 * * 1-5` = weekdays 8:30) or `@hourly`/`@daily`/`@weekly`. A schedule can't restrict both day of month and weekday. Use `--every 30s|15m|2h|1d` for intervals.
- Commands run in zsh with James's PATH from when the job was synced.
- For an agent job James should watch or continue, use `--tab SESSION` and an interactive prompt, such as `--tab agents --command "pi 'morning report'"`. It opens a Rex tab in that session.
- For an unattended agent job, run headless with output in the log, such as `--command "pi -p 'summarize ...'"`.
- When the request is ambiguous about time, ask once. Otherwise pick sensible defaults and say what you chose.

## Watches

Use a watch when James wants to know when something changes, not to run something on a clock. Watches never send macOS notifications themselves. To get James's attention, open or reuse a Rex tab whose program reports its status (OSC 7501); Rex marks the tab and can notify him. A watch runs a check, a program in `timers/checks/` that prints what is true now as JSON. It compares the result with the last run and acts only on changes, so nothing expensive runs when nothing changed. The first run only records a baseline.

- `--on-change CMD` runs a shell command once per change, with `{job}` and any field the check prints, such as `{id}`, `{url}`, or `{summary}`, filled in and quoted.
- `--expires DATE` deletes the watch after that date. A check can also end its watch by printing `"done": true`.

Checks that exist: `review-requests` (new MRs where James is a reviewer) and `feedback-addressed` (MRs where someone replied, resolved, or pushed after James's last comment). Both standing watches already run and hand changes to `review-queue --request` (a background Rex tab with a brief) and `review-queue --follow-up`; don't add duplicates.

When James wants to focus, or says to pause or snooze his timers, run `timers snooze all` with the length he gives (default 1h). Snoozed watches catch up on the next run after the snooze ends.

To add a check, write an executable in `timers/checks/` that prints `{"items": [{"id", "url", "summary", "state"}], "done": false}`. An item counts as changed when its id is new or its `state` differs, so put only the facts that should trigger a change in `state`. Keep checks cheap and stateless.

## After creating or changing a job

Run `timers` and confirm the job shows `on` with the expected next run. If James wants proof it works, run `timers run NAME`, then check `timers logs NAME`. Tell James the job name, schedule, and command.
