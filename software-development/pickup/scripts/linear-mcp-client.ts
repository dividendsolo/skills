// Minimal Linear MCP client over HTTP+JSON-RPC.
// Use this for any ad-hoc Linear scripting; it's the only sane way to talk
// to the hosted MCP without dragging in mcp-remote or stdio plumbing.
//
// Usage:
//   const linear = new LinearMcpClient();
//   await linear.init();
//   const projects = await linear.call<{ projects: Project[] }>("list_projects", {});

import { readFileSync } from "node:fs";

const MCP_URL = "https://mcp.linear.app/mcp";

export class LinearMcpError extends Error {
  constructor(public code: number, message: string) {
    super(`Linear MCP error ${code}: ${message}`);
  }
}

export class LinearMcpClient {
  private token: string;
  private expiresAt: number;
  private initialized = false;

  constructor(tokenPath = `${process.env.HOME}/.hermes/mcp-tokens/linear.json`) {
    const t = JSON.parse(readFileSync(tokenPath, "utf8")) as {
      access_token: string; expires_at: number;
    };
    this.token = t.access_token;
    this.expiresAt = t.expires_at;
  }

  private checkExpiry(): void {
    if (Date.now() / 1000 > this.expiresAt) {
      throw new Error(
        "Linear token expired; re-run the Linear MCP install flow " +
        "(see skill: mcp-server-install).",
      );
    }
  }

  async init(): Promise<void> {
    this.checkExpiry();
    // Handshake. Server may return method-not-found for the "initialized"
    // notification; that's fine, it's a notification, not a request.
    await this.rpc("initialize", {
      protocolVersion: "2024-11-05",
      capabilities: {},
      clientInfo: { name: "hermes-linear-client", version: "0.1.0" },
    });
    try { await this.rpc("notifications/initialized", {}); }
    catch { /* fire-and-forget */ }
    this.initialized = true;
  }

  async call<T = any>(toolName: string, args: Record<string, any> = {}): Promise<T> {
    if (!this.initialized) await this.init();
    const res = await this.rpc("tools/call", { name: toolName, arguments: args });
    const content = res?.result?.content?.[0];
    if (!content) throw new Error(`No content in tool result for ${toolName}`);
    if (res?.result?.isError) {
      // Error payload is a plain string in content[0].text, not JSON
      throw new LinearMcpError(-32602, content.text);
    }
    return JSON.parse(content.text) as T;
  }

  private async rpc(method: string, params: any, id = 1): Promise<any> {
    const body = JSON.stringify({ jsonrpc: "2.0", id, method, params });
    const r = await fetch(MCP_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Accept: "application/json, text/event-stream",
        Authorization: `Bearer ${this.token}`,
      },
      body,
    });
    if (!r.ok) {
      throw new LinearMcpError(r.status, await r.text().catch(() => r.statusText));
    }
    const text = await r.text();
    const dataLine = text.split("\n").find((l) => l.startsWith("data: "));
    if (!dataLine) throw new Error(`No data line in response: ${text.slice(0, 200)}`);
    return JSON.parse(dataLine.slice(6));
  }
}

// CLI use: `bun linear-mcp-client.ts list_projects`
if (import.meta.main) {
  const [tool, ...rest] = process.argv.slice(2);
  if (!tool) {
    console.error("usage: bun linear-mcp-client.ts <tool-name> [args-json]");
    process.exit(2);
  }
  const args = rest[0] ? JSON.parse(rest[0]) : {};
  const client = new LinearMcpClient();
  await client.init();
  const out = await client.call(tool, args);
  console.log(JSON.stringify(out, null, 2));
}
