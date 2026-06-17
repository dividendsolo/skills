---
name: todoist
description: Triage the Todoist inbox by splitting it into ideas vs errands. Ideas get auto-captured into the Obsidian _inbox (to process later in Obsidian); errands are left in Todoist for the user to do actively. Use when the user invokes /todoist, says "process my tasks", "go through my todoist", "clear my inbox", or wants the inbox pile sorted and the ideas offloaded.
---

# Todoist — Split the Inbox into Ideas vs Errands

James keeps a single flat Todoist inbox (no projects, no due dates) as his capture pile. When run, take the Todoist inbox and sort it into two species, then route each to its home:

- **Ideas / projects** — anything that needs thinking, research, building, or organizing before it's actionable. These get **auto-captured into the Obsidian `_inbox`** and **completed in Todoist**, so they leave the task list and live where the user develops ideas.
- **Errands / actions** — a single concrete thing the user just does (cut hair, migrate email, call/book/pay X). These are **left in Todoist, untouched** — the user does these actively and doesn't want them organized.

The goal: get the idea-clutter out of Todoist and into Obsidian so the inbox only holds real errands.

The Todoist MCP tools are deferred. Load them with `ToolSearch` (e.g. `select:mcp__todoist__find-tasks,mcp__todoist__complete-tasks,mcp__todoist__reschedule-tasks`). Use `reschedule-tasks` for any date move, never `update-tasks` (it destroys recurrence).

**Obsidian capture target:** `/Users/james/Vaults/zettelkasten/_inbox/Captured from Todoist - <YYYY-MM-DD>.md` (today's date). Append if it already exists for today; create it if not.

## Workflow

### 1. Pull up the inbox

Fetch the inbox with `find-tasks`, `projectId: "inbox"`, limit 100. If empty, say so and stop.

### 2. Classify each task: idea or errand

Sort every task into **Idea** or **Errand**:

- **Errand** — one concrete action, done in a single sitting, no thinking required: *cut hair, migrate inbox-zero to Proton, book X, pay Y, reply to Z.* → leave in Todoist.
- **Idea** — needs developing, researching, building, deciding, or organizing; often phrased "investigate…", "create a…", "should I…", "organize…", "explore…": *YouTube-as-text, web UI for VPS crons, organize Obsidian.* → capture to Obsidian.
  - **Watch for disguised ideas:** a task phrased like a single action can really be a *process/system to design and implement* (e.g. "translate inbox-zero to Proton Mail" = rebuild a whole workflow, not a one-shot errand). If doing it well means designing a system/process, it's an idea → Obsidian.

Present the proposed split as two short lists so the user can veto or reclassify before anything moves. Honor any correction. (Default to auto-running unless the split looks genuinely ambiguous — the user wants this fast, not a per-task interview.)

### 3. Capture ideas to Obsidian, then complete them

For each **idea**, append an entry to today's capture note (`_inbox/Captured from Todoist - <YYYY-MM-DD>.md`). Create the note if missing, starting it with `[[Home 🏡]]` and an `# Captured from Todoist — <date>` heading.

**Type each captured item** so the unprocessed inbox is scannable at a glance (search `tag:#task` etc.). The `Status:` line carries `#to-process`, then exactly one type tag, then the task's Todoist labels (see below):

- `#task` — a real thing to DO that will need executing/scheduling (e.g. *buy more FICO, migrate email to Proton*). These are the don't-lose-it items; be precise, don't inflate.
- `#idea` — something to develop, build, or decide before it's actionable (app ideas, skills to build, "should I…").
- `#reference` — material to read/mine/compare, not build (a gist, an article, links to triage).
- `#ephemeral` — someday/low-stakes, fine to lose (a film to watch, a stray musing).

**Carry the Todoist labels over as tags.** Each Todoist task's `labels` (e.g. `productivity`, `dev-work`, `app-idea`, `security`, `investing`) map one-to-one onto Obsidian inline tags, appended after the type tag. This keeps Todoist and the vault in sync so the user never re-tags. Labels are already hyphenated (`dev-work`), which is tag-safe — use them verbatim with a `#` prefix.

**If a task has no labels,** still capture it, but note it in the wrap-up so the user can add a label next time (e.g. *"breathing-app idea had no label — what should it be?"*). The user tries to label everything; your job is to remind them of the ones that slipped through, not to invent labels yourself.

Each entry:

```
## <task title>
<one or two sentences of context — what it means / the open question, pulled from the task description and what's known. Enough that future-me knows what they meant.>
Status: #to-process #<task|idea|reference|ephemeral> #<label1> #<label2> …
```

Then mark those tasks complete in Todoist with `complete-tasks` (they now live in Obsidian).

### 4. Leave errands

Don't touch the errands — no rescheduling, no completing, no reprioritizing. Just list what remains in the inbox so the user sees their active list.

### 5. Wrap up

One line: *"N ideas captured to Obsidian (`_inbox/Captured from Todoist - <date>.md`), M errands left in the inbox: …"* The user processes the captured ideas in Obsidian separately.

## Rules

- **Ideas → Obsidian + complete; errands → leave alone.** That's the whole job.
- **Auto-process by default.** The user wants ideas offloaded automatically; only pause to confirm when a task's classification is genuinely ambiguous.
- Always write idea context, not just the title — a bare title is useless to process later.
- Capture to the Obsidian note *before* completing the Todoist task, so nothing is lost if something fails.
- Use `reschedule-tasks` (never `update-tasks`) if a date ever needs moving, to preserve recurrence.
- Keep lists compact and scannable.
