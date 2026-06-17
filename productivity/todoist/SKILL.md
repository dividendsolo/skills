---
name: todoist
description: Triage the Todoist inbox by the 5-minute rule. Tiny check-offs (<5 min) stay in Todoist for the user to tick off; everything else is captured into the Obsidian _inbox (typed + labeled) and completed in Todoist, leaving the inbox empty. Use when the user invokes /todoist, says "process my tasks", "go through my todoist", "clear my inbox", or wants the pile triaged.
---

# Todoist — Triage the Inbox by the 5-Minute Rule

James keeps a single flat Todoist inbox (no projects, no due dates) as his capture pile. Todoist is **capture + a scratchpad for tiny check-offs only** — it is not where real work lives. His pipeline:

**Capture (Todoist) → Organize (Obsidian inbox) → Process (schedule onto Calendar / Deep Work) → Execute.**

So when run, sort the Todoist inbox by **effort**, not by idea-vs-errand:

- **Quick check-off (≤5 min)** — a tiny thing he just ticks off (pay a bill, order X, a one-line reply, a quick lookup). **Leave it in Todoist**; he executes these directly there.
- **Everything else (>5 min / needs real time, thought, building, or scheduling)** — task, idea, reference, or someday item alike. **Capture it into the Obsidian `_inbox`** (typed + labeled) and **complete it in Todoist**. He wants substantial work "out and captured, ready to execute in the future" — later pulled onto the calendar into a Deep Work block, usually next-day or later.

The goal of a run: Todoist ends **empty or holding only quick check-offs**; everything substantial is in the Obsidian inbox, tagged and ready to schedule.

The Todoist MCP tools are deferred. Load them with `ToolSearch` (e.g. `select:mcp__todoist__find-tasks,mcp__todoist__complete-tasks,mcp__todoist__reschedule-tasks`). Use `reschedule-tasks` for any date move, never `update-tasks` (it destroys recurrence).

**Obsidian capture target:** `/Users/james/Vaults/zettelkasten/_inbox/Captured from Todoist - <YYYY-MM-DD>.md` (today's date). Append if it already exists for today; create it if not.

## Workflow

### 1. Pull up the inbox

Fetch the inbox with `find-tasks`, `projectId: "inbox"`, limit 100. If empty, say so and stop.

### 2. Classify each task by the 5-minute rule

Sort every task into **Quick check-off** or **Capture**:

- **Quick check-off (≤5 min)** — trivial, single-sitting, no real thought: *pay Y, order X, one-line reply, quick lookup.* → leave in Todoist.
- **Capture (>5 min / needs real work)** — anything that takes meaningful time, thought, building, research, or scheduling. → capture to Obsidian.
  - **Watch for disguised work:** a task phrased like a one-shot action can really be a *project/system* (e.g. "migrate email to Proton" = a multi-step workflow, not a 5-min errand). If doing it well takes more than ~5 minutes, it captures to Obsidian.
  - **When in doubt, capture it.** Better in the Obsidian inbox tagged and ready than lingering in Todoist.

Present the proposed split as two short lists so the user can veto or reclassify before anything moves. Honor any correction. (Default to auto-running unless genuinely ambiguous — the user wants this fast, not a per-task interview.)

### 3. Capture the >5-min items to Obsidian, then complete them

For each **capture** item, append an entry to today's capture note (`_inbox/Captured from Todoist - <YYYY-MM-DD>.md`). Create the note if missing, starting it with `[[Home 🏡]]` and an `# Captured from Todoist — <date>` heading.

**Type each captured item** so the unprocessed inbox is scannable at a glance (search `tag:#task` etc.). The `Status:` line carries `#to-process`, then exactly one type tag, then the task's Todoist labels (see below):

- `#task` — a real thing to DO that will need executing/scheduling (e.g. *buy more FICO, migrate email to Proton, set up a cron*). These are the don't-lose-it items; be precise, don't inflate.
- `#idea` — something to develop, build, or decide before it's actionable (app ideas, skills to build, "should I…").
- `#reference` — material to read/mine/compare, not build (a gist, an article, links to triage).
- `#ephemeral` — someday/low-stakes, fine to lose (a film to watch, a stray musing).

**Carry the Todoist labels over as tags.** Each Todoist task's `labels` (e.g. `productivity`, `dev-work`, `app-idea`, `security`, `investing`, `to-consume`) map one-to-one onto Obsidian inline tags, appended after the type tag. This keeps Todoist and the vault in sync so the user never re-tags. Labels are already hyphenated (`dev-work`), which is tag-safe — use them verbatim with a `#` prefix.

**If a task has no labels,** still capture it, but note it in the wrap-up so the user can add a label next time (e.g. *"breathing-app idea had no label — what should it be?"*). The user tries to label everything; your job is to remind them of the ones that slipped through, not to invent labels yourself.

Each entry:

```
## <task title>
<one or two sentences of context — what it means / the open question, pulled from the task description and what's known. Enough that future-me knows what they meant.>
Status: #to-process #<task|idea|reference|ephemeral> #<label1> #<label2> …
```

Then mark those tasks complete in Todoist with `complete-tasks` (they now live in Obsidian).

### 4. Leave the quick check-offs

Don't touch the ≤5-min check-offs — no rescheduling, no completing. Just list what remains so the user sees the quick wins still on his plate.

### 5. Wrap up

One line: *"N items captured to Obsidian (`_inbox/Captured from Todoist - <date>.md`), M quick check-offs left in Todoist: …"* Note any captured item that arrived unlabeled. The user later pulls the captured items onto his calendar/Deep Work himself.

## Rules

- **>5 min → Obsidian (typed + labeled) + complete in Todoist; ≤5 min → leave in Todoist.** That's the whole job. Never treat substantial work as "staying in Todoist."
- **Auto-process by default.** Only pause to confirm when a task's classification is genuinely ambiguous.
- Always write context, not just the title — a bare title is useless to process later.
- Capture to the Obsidian note *before* completing the Todoist task, so nothing is lost if something fails.
- Use `reschedule-tasks` (never `update-tasks`) if a date ever needs moving, to preserve recurrence.
- Keep lists compact and scannable.
