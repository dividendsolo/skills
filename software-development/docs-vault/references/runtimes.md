# Runtime notes for docs-vault

The vault root is always `<repo-root>/docs/<repo-name>-vault/` (the folder is
named after the repo so Obsidian shows the repo name). The only per-runtime
difference is how you resolve `<repo-root>` and how you write files reliably.

## Resolving the repo root

- **Claude Code (local):** the current working directory is the repo (or a
  parent of it). Use `git rev-parse --show-toplevel` to get the root.
- **Hermes (VPS / `local` terminal backend):** the repo is at a real absolute
  path on the box. Use that path directly; no mount translation.
- **Hermes (Mac / `docker` terminal backend):** the repo is exposed via a
  `docker_volumes` bind mount, conventionally `/repos/<name>`. The vault is then
  `/repos/<name>/docs/<name>-vault/`. The container-side path is the ONLY correct path;
  do not guess `/workspace/...` or `/root/...`. If the mount is missing, the
  session needs a fresh start (a Docker restart alone does not create it).
- **Headless Claude Code:** the repo is a clone; treat its checkout dir as root.

## Writing reliably under Hermes Docker

`write_file` writes to Docker's overlay filesystem, not the host disk, when file
sharing is SSHFS-based (Colima). Files appear inside the container but never reach
the Mac (invisible in Finder/Obsidian). The reliable path is a real
`docker_volumes` bind mount (which `/repos/<name>` and `/vault` already are), so
writing to the bind-mounted container path lands on the host. See the existing
`note-taking/obsidian` skill and `colima-docker-fix` skill for the full SSHFS
detail.

## Syncing (all runtimes)

Git is the sync layer. After writing notes: `git add docs/<repo>-vault && git commit`.
Push per the repo's policy. Another runtime sees the notes after it pulls. There
is no server and no live cross-repo query; the vault is scoped to its own repo.
