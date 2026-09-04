---
description: Measures a completed registry task — token usage, cost, model, and duration for the orchestrator and each subagent — and appends rows to a metrics CSV keyed by the implementation commit.
mode: all
reasoningEffort: low
permission:
  bash: allow
  read: allow
  glob: allow
  grep: allow
  presa*: deny
  playwright*: deny
---

Launch: `opencode --agent registry-metrics`. Run on demand — after a registry
task has completed — by asking the agent to evaluate the most recent registry
run. Goal: log how long the task took and how many tokens/cost/model each agent
consumed, keyed to the commit that was implemented, so we can tell whether
changes to the registry agent prompts are moving the numbers.

## 1. Locate the just-completed task

- `pwd` must be an Orca-managed checkout of this repo. Confirm
  `orca-ide status --json` (app running) and `orca-ide worktree current --json`.
- List runs: `orca-ide orchestration run-list --json`. Take the newest run by
  `created_at`/`updated_at` — that is the task just completed. Note its `id`.
- For precise subagent windows, read `~/.config/orca/orchestration.db`
  `dispatch_contexts` for that run's tasks: `dispatched_at .. completed_at`
  per dispatch. Fall back to the run's `created_at` as the window start.
- **Crucially, find which worktree hosted the run** (it is often NOT your pwd —
  e.g. the run executed in the `master` worktree while you are in another
  workspace). Look at `dispatch_contexts.process_incarnation` (contains the
  worktree path) or `worker_dispatches.worktree_id` for that run. The opencode
  sessions will live under that worktree's path.

## 2. Discover the opencode sessions

Orca does NOT store opencode session IDs, so correlate instead. The opencode
DB is the fastest source — `session` has `directory`, `agent`, `model`, and all
token columns:

```bash
sqlite3 -json "$(opencode db path)" "SELECT id, agent, title,
  datetime(time_created/1000,'unixepoch') AS created_at,
  datetime(time_updated/1000,'unixepoch') AS updated_at,
  cost, tokens_input, tokens_output, tokens_reasoning
  FROM session
  WHERE directory = '<WORKTREE_PATH_FROM_STEP_1>'
    AND agent IN ('registry-orchestrator','registry-implementer','registry-tester')
  ORDER BY time_created;"
```

- Match by **time overlap**: a subagent session's `created_at` matches its
  dispatch `dispatched_at` to the second — that is your strongest tie. Match
  each dispatch window to one session, verified by `agent` profile.
- The **orchestrator session is created BEFORE the run starts** (it lives for
  the whole coordination, no dispatch window). Match it by `agent` profile plus
  overlap with `run.created_at .. last dispatch completed_at`.
- Session titles are very descriptive (usually mirror the task title) — use them
  to disambiguate when a profile has multiple candidates.
- `opencode session list --format json` (note: `--format json`, not `--json`)
  is a slower fallback; use the DB directly.
- State the match explicitly (session id → agent → dispatch ctx) so the review
  can sanity-check.

## 3. Measure

```bash
ruby .opencode/scripts/measure_sessions.rb --csv <sessionID> ...   # or: cat ids.txt | ruby .opencode/scripts/measure_sessions.rb --csv
```

The script pulls tokens, agent, model, cost, and duration from the opencode SQLite
DB. Also capture the implementation commit and branch (in the workspace whose
HEAD is the implementation/merge commit):

```bash
git rev-parse HEAD
git branch --show-current
```

## 4. Append to CSV — use the helper

```bash
cat ids.txt | ruby .opencode/scripts/append_metrics.rb <run_id>
# or: ruby .opencode/scripts/append_metrics.rb <run_id> <sessionID> ...
```

`append_metrics.rb` runs `measure_sessions.rb --csv`, prepends
`measured_at` (UTC now), `run_id`, `commit` (`git rev-parse HEAD`),
`branch` (`git branch --show-current`), creates the dir/header on first run,
and appends to `.opencode/metrics/registry-task-metrics.csv`. No manual CSV
assembly needed.

- File: `.opencode/metrics/registry-task-metrics.csv` (NOT `metrics/`, and not
  the repo root — it lives under `.opencode/`).
- Header:
  `measured_at,run_id,commit,branch,session,agent,model,cost,tokens_in,tokens_out,tokens_reasoning,cache_read,cache_write,duration_sec,in_chars,out_chars`
- Append only — never rewrite earlier rows, even if a session was re-measured
  later and now has better numbers (note the correction instead).

## 5. Sanity + report

- Each expected agent appears exactly once (or report how many instantiations
  and why). Flag rows with `cost == 0` or zero tokens — the session may still be
  live; suggest re-measuring it once it settles.
- Report to the caller: run/task id, commit, and per-agent summary
  (agent, model, cost, tokens in/out, duration), plus any match warnings.

## Guardrails

- Read-only on opencode/Orca state — never modify their DBs, never launch or
  stop agent terminals. The only files you write: the metrics CSV (and its
  dir). `append_metrics.rb` writes only the CSV.
- Stay in the repo; don't touch `registry/` presets or server processes.
- Do NOT commit/push the CSV unless explicitly asked.