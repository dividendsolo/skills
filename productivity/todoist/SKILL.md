---
name: todoist
description: Triage today's Todoist list by splitting it into ideas vs errands. Ideas get auto-captured into the Obsidian _inbox (to process later in Obsidian); errands are left in Todoist for the user to do actively. Use when the user invokes /todoist, says "process my tasks", "go through my todoist", "clear my today list", or wants today's pile sorted and the ideas offloaded.
---

# Todoist — Split Today into Ideas vs Errands

When run, take today's Todoist list and sort it into two species, then route each to its home:

- **Ideas / projects** — anything that needs thinking, research, building, or organizing before it's actionable. These get **auto-captured into the Obsidian `_inbox`** and **completed in Todoist**, so they leave the task list and live where the user develops ideas.
- **Errands / actions** — a single concrete thing the user just does (cut hair, migrate email, call/book/pay X). These are **left in Todoist, untouched** — the user does these actively and doesn't want them organized.

The goal: get the idea-clutter out of Todoist and into Obsidian so "today" only holds real errands.

The Todoist MCP tools are deferred. Load them with `ToolSearch` (e.g. `select:mcp__todoist__find-tasks,mcp__todoist__complete-tasks,mcp__todoist__reschedule-tasks`). Use `reschedule-tasks` for any date move, never `update-tasks` (it destroys recurrence).

**Obsidian capture target:** `/Users/james/Vaults/zettelkasten/_inbox/Captured from Todoist - <YYYY-MM-DD>.md` (today's date). Append if it already exists for today; create it if not.

## Workflow

### 1. Pull up today

Fetch today's list with `find-tasks`, `filter: "today | overdue"`, limit 100. If empty, say so and stop.

### 2. Classify each task: idea or errand

Sort every task into **Idea** or **Errand**:

- **Errand** — one concrete action, done in a single sitting, no thinking required: *cut hair, migrate inbox-zero to Proton, book X, pay Y, reply to Z.* → leave in Todoist.
- **Idea** — needs developing, researching, building, deciding, or organizing; often phrased "investigate…", "create a…", "should I…", "organize…", "explore…": *YouTube-as-text, web UI for VPS crons, organize Obsidian.* → capture to Obsidian.
  - **Watch for disguised ideas:** a task phrased like a single action can really be a *process/system to design and implement* (e.g. "translate inbox-zero to Proton Mail" = rebuild a whole workflow, not a one-shot errand). If doing it well means designing a system/process, it's an idea → Obsidian.

Present the proposed split as two short lists so the user can veto or reclassify before anything moves. Honor any correction. (Default to auto-running unless the split looks genuinely ambiguous — the user wants this fast, not a per-task interview.)

### 3. Capture ideas to Obsidian, then complete them

For each **idea**, append an entry to today's capture note (`_inbox/Captured from Todoist - <YYYY-MM-DD>.md`). Create the note if missing, starting it with `[[Home 🏡]]` and an `# Captured from Todoist — <date>` heading. Each entry:

```
## <task title>
<one or two sentences of context — what it means / the open question, pulled from the task description and what's known. Enough that future-me knows what they meant.>
Status: #to-process
```

Then mark those tasks complete in Todoist with `complete-tasks` (they now live in Obsidian).

### 4. Leave errands

Don't touch the errands — no rescheduling, no completing, no reprioritizing. Just list what remains in today so the user sees their active list.

### 5. Wrap up

One line: *"N ideas captured to Obsidian (`_inbox/Captured from Todoist - <date>.md`), M errands left in today: …"* The user processes the captured ideas in Obsidian separately.

## Rules

- **Ideas → Obsidian + complete; errands → leave alone.** That's the whole job.
- **Auto-process by default.** The user wants ideas offloaded automatically; only pause to confirm when a task's classification is genuinely ambiguous.
- Always write idea context, not just the title — a bare title is useless to process later.
- Capture to the Obsidian note *before* completing the Todoist task, so nothing is lost if something fails.
- Use `reschedule-tasks` (never `update-tasks`) if a date ever needs moving, to preserve recurrence.
- Keep lists compact and scannable.
