# Linear MCP schema cheat sheet

Condensed from a real session where every one of these bit me. If you find yourself about to call an MCP tool, check this first.

## Transport: JSON-RPC over HTTPS, SSE-framed

```
POST https://mcp.linear.app/mcp
Headers:
  Content-Type: application/json
  Accept: application/json, text/event-stream
  Authorization: Bearer <access_token from ~/.hermes/mcp-tokens/linear.json>
Body: { "jsonrpc":"2.0", "id":<n>, "method":"...", "params":{...} }
```

Response is SSE: find the `data: ` line and `JSON.parse(line.slice(6))`. The `Mcp-Session-Id` header in the initialize response is `null` for hosted Linear MCP; you do not need to track sessions.

## `initialize` / `notifications/initialized`

Handshake. `notifications/initialized` may return `method not found` from the server (that's fine, fire and forget). After this, `tools/list` and `tools/call` will work.

## `tools/list`: discover the 35 available tools

Useful ones for board work:

- `list_projects`: find a project by name
- `list_issues`: list issues (the most-bug-prone tool, see below)
- `get_issue`: full description, attachments, branch
- `save_issue`: create or update
- `list_issue_statuses`: see what status names exist for a team
- `list_users`: find assignees
- `list_teams`: get team ID from name
- `save_comment` / `list_comments`: issue thread
- `search_documentation`: Linear's own docs (handy when stuck on a field)

## `list_issues`: the trap-rich one

```ts
// CORRECT
rpc("tools/call", {
  name: "list_issues",
  arguments: { project: docket.id, limit: 50 }
}, ...)

// WRONG (will get MCP error -32602 "unrecognized_keys")
rpc("tools/call", {
  name: "list_issues",
  arguments: { projectId: docket.id, first: 50 }
}, ...)
```

### Field names (all from real responses, not docs)

| You might guess | Actual parameter |
| --- | --- |
| `projectId` | `project` (name, ID, or slug) |
| `first` | `limit` (default 50, max 250) |
| `state` (multi) | `state` (single value only; see below) |
| `query` | `query` (text search of title/description) ✓ |

### The `state` parameter is single-value

Despite comma-separated strings looking like a sensible array, `state: "unstarted,started"` returns zero issues. To get "all open work":

```ts
// Fetch all, filter client-side
const issues = (await listIssues({ project: id, limit: 50 })).issues;
const open = issues.filter(i => i.statusType === "unstarted");
```

### Issue fields (flat, NOT GraphQL shape)

| You might guess | Actual field |
| --- | --- |
| `identifier` (e.g. `"JAM-7"`) | `id` (same value, just `id`) |
| `state.name` | `status` (string, e.g. `"In Review"`) |
| `state.type` | `statusType` (enum: `unstarted`/`started`/`completed`/`canceled`/`backlog`) |
| `priority` (number) | `priority` (`{ value: 0..4, name: "No priority"|"Urgent"|"High"|"Medium"|"Low" }`) |
| `assignee.name` | `assignee` (string, the display name) or `null` |

`statusType` values in the wild for this user:

- `unstarted` → "Todo" (**open, pick it up**)
- `started` → "In Progress" or "In Review" (**owned by another agent, do not touch**)
- `completed` → "Done" (terminal)
- `canceled` → "Cancelled" (terminal)
- `backlog` → "Backlog" (parked, do not pick up without explicit ask)

### Result wrapper

`tools/call` returns:

```json
{
  "result": {
    "content": [{ "type": "text", "text": "<json string of the actual payload>" }],
    "isError": false
  }
}
```

So always: `JSON.parse(result.result.content[0].text)` to get the data. The wrapper key matches the tool name: `{ projects: [...] }` from `list_projects`, `{ issues: [...] }` from `list_issues`, `{ nodes: [...] }` from some other tools (it varies). Empty result is `[]` inside the named key, not `null`.

### Error shape

When `isError: true`, the `content[0].text` is a **plain string** like `MCP error -32602: Input validation error: Invalid arguments for tool list_issues: ...`. Do not `JSON.parse` it; log as-is and read the message.

## `get_issue`

`{ id: "JAM-7" }` returns the full description (not truncated), plus `gitBranchName`, `attachments`, and any linked PRs. Use this whenever the list response says "(truncated, use `get_issue` for full description)".

## `save_issue`

`{ id, state }` to move a card. **`state` is the field name, not `status`** (the skill docs and several references in the wild call it `status`, which gets an MCP error -32602 "unrecognized_keys: status"). The value is the human name (`"In Progress"`, `"In Review"`, `"Done"`), not the `statusType` enum. For new issues, omit `id` and pass `team`, `title`, `description`, optional `project` and `assignee`. **Response is the flat issue object, not wrapped:** `{ id, title, status, statusType, ... }` returned directly, not `{ issue: { id, status, ... } }`. The `{ issue: { ... } }` shape that some skill docs and references show is wrong; reading `.issue.status` will be `undefined`.

## `save_comment`

`{ issueId, body }` where `body` is markdown. The field is `issueId`, **not** `issue` (`issue` returns MCP error -32602 "unrecognized_keys: issue"). Use this to file progress notes, not chat. **Response is the flat comment object, not wrapped:** `{ id, body, createdAt, updatedAt, author: { id, name }, ... }` returned directly, not `{ comment: { id, ... } }`. To delete, use `delete_comment` with `{ id: "<comment id>" }`, useful for cleaning up probes or wrong-target posts.

## Token refresh

`~/.hermes/mcp-tokens/linear.json` has `expires_at` (unix seconds). If `Date.now()/1000 > expires_at + 60`, the call will return `401`. The MCP server does not refresh for you; the user has to re-run the install flow from `mcp-server-install`. Check expiry at the top of any long-running script and fail fast with a clear message.
