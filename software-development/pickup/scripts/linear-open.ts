// "What work is open for me to pick up?" Board view filtered to Todo only.
// Honors the user's rule: open = Todo (statusType: unstarted). In Progress and
// In Review are flagged as "owned by other agents" but not shown in detail.
//
// Usage:
//   bun ~/.hermes/scripts/linear-open.ts
//   bun ~/.hermes/scripts/linear-open.ts "My Project Name"
//
// (Project name optional; defaults to the first project whose name contains "docket".)

import { LinearMcpClient } from "./linear-mcp-client.ts";

type Issue = {
  id: string;            // "JAM-7"
  title: string;
  status: string;        // "Todo" | "In Progress" | "In Review" | "Done" | ...
  statusType: "unstarted" | "started" | "completed" | "canceled" | "backlog";
  priority: { value: number; name: string };
  assignee: string | null;
  labels: string[];
  url: string;
  updatedAt: string;
};

type Project = {
  id: string;
  name: string;
  status?: { name: string };
};

const client = new LinearMcpClient();
await client.init();

// 1) Find the project
const wantName = process.argv[2];
const projectsRes = await client.call<{ projects: Project[] }>("list_projects", {});
const projects = projectsRes.projects;
const docket = wantName
  ? projects.find((p) => p.name.toLowerCase().includes(wantName.toLowerCase()))
  : projects.find((p) => /docket/i.test(p.name)) ?? projects[0];

if (!docket) {
  console.log("No matching project. Visible to this token:");
  for (const p of projects) console.log(`  - ${p.name}  ${p.id}`);
  process.exit(1);
}
console.log(`Project: ${docket.name}  (${docket.status?.name ?? "?"})  ${docket.id}\n`);

// 2) Fetch all issues, filter client-side
const issuesRes = await client.call<{ issues: Issue[] }>("list_issues", {
  project: docket.id,
  limit: 50,
});
const issueList = issuesRes.issues;
if (issueList.length === 0) {
  console.log("No issues in this project.");
  process.exit(0);
}

const isOpen = (i: Issue) => i.statusType === "unstarted";
const isOtherActive = (i: Issue) => !isOpen(i) && !["completed", "canceled"].includes(i.statusType);
const isClosed = (i: Issue) => ["completed", "canceled"].includes(i.statusType);

const open = issueList.filter(isOpen);
const otherActive = issueList.filter(isOtherActive);
const closed = issueList.filter(isClosed);

console.log(`Todo (open): ${open.length}   Other-active: ${otherActive.length}   Closed: ${closed.length}   Total: ${issueList.length}`);
if (otherActive.length > 0) {
  const who = otherActive.map((i) => `${i.id} [${i.status}]`).join(", ");
  console.log(`(Other-active: ${who}, owned by other agents)\n`);
} else {
  console.log();
}

// 3) Group open by status, ordered Todo first
const byState = new Map<string, Issue[]>();
for (const i of open) {
  if (!byState.has(i.status)) byState.set(i.status, []);
  byState.get(i.status)!.push(i);
}
const stateOrder = ["Backlog", "Todo", "In Progress", "In Review", "Done", "Cancelled"];
const states = [...byState.keys()].sort((a, b) => {
  const ia = stateOrder.indexOf(a); const ib = stateOrder.indexOf(b);
  return (ia === -1 ? 99 : ia) - (ib === -1 ? 99 : ib);
});
for (const state of states) {
  console.log(`── ${state} (${byState.get(state)!.length}) ──`);
  for (const i of byState.get(state)!) {
    const prio = i.priority?.name && i.priority.name !== "No priority" ? ` [${i.priority.name}]` : "";
    const who = i.assignee ? `  @${i.assignee}` : "";
    const labels = i.labels?.length ? `  {${i.labels.join(",")}}` : "";
    console.log(`  ${i.id.padEnd(8)} ${i.title}${prio}${who}${labels}`);
  }
  console.log();
}
