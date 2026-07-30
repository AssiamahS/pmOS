# pmOS

Project manager on the iPhone, talking straight to the Claude Code taskboard on the Mac.

Companion app to [pm](https://github.com/AssiamahS/pm) — the Mac runs `pm-api`
on the Tailscale interface; pmOS reads and writes the same deliverables and
taskboard the `pm` MCP serves to Claude Code.

- **Today** — on-track ring, overdue and landing-this-week deliverables
- **Projects** — per-project cards with progress and deadline chips
- **Board** — the raw taskboard, tap to complete
- **+ Need it by** — commit a deliverable to a date; it lands on the Claude
  taskboard with a deadline so the next session sees it

Settings → server URL (`http://<tailscale-ip>:8796`) + optional `X-PM-Key`.

XcodeGen project (`project.yml` is the source of truth); CI archives with
cloud-managed signing and uploads to TestFlight on every push to main.
