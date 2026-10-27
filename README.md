# sina

Modern TUI health check for Ubuntu VPSes running Docker workloads. Single
static binary, no runtime deps. Built with [Bubble Tea] + [Lip Gloss].

```
$ sina
```

Tells you in one screen: CPU/load, memory, swap, disk, inodes, top mounts and
top dirs, Docker (containers + reclaimable space + top-by-CPU/mem + restart-loop
detection), top processes, zombies, journal size, OOM kills (24h), failed
systemd units, reboot-required flag, FD usage. Then a clear OK / WARN / BAD
verdict with reasons and suggested actions.

Named after **İbni Sina** (Avicenna), the 11th-century physician whose *Canon
of Medicine* was the standard medical reference for centuries.

## Install

### One-liner (recommended)

```bash
curl -fsSL https://get.ottomind.ai/sina | sudo bash
```

Pin a specific version:

```bash
curl -fsSL https://get.ottomind.ai/sina/0.3.1 | sudo bash
# or
SINA_VERSION=0.3.1 curl -fsSL https://get.ottomind.ai/sina | sudo bash
```

The installer verifies the download against `SHA256SUMS` and stops on a mismatch.
Release files, checksums and the manifest live at `https://get.ottomind.ai/sina/<version>/`
(`latest.json` for the newest).

### For AI agents

Give the agent https://skills.ottomind.ai/sina/SKILL.md (or install the Claude skill
https://skills.ottomind.ai/sina/sina-skill.zip). The skill is [`skill/SKILL.md`](skill/SKILL.md) in this repo.

### Build from source (no GitHub Release needed)

```bash
git clone https://github.com/19011022/sina
cd sina
./install-from-source.sh
```

## Usage

```
sina             # interactive TUI: q quit, r refresh, ↑↓/j/k scroll, space pgdn
sina --plain     # styled but non-interactive (auto-selected when piped)
sina --no-color
sina --version
```

When stdout is **not** a TTY (cron, pipes, redirects), the binary
auto-falls-back to `--plain`.

### Exit codes (plain mode)

- `0` everything OK
- `1` at least one WARN
- `2` at least one BAD

```bash
sina --plain >/var/log/sina.log || \
  curl -fsS https://hooks.slack.com/... -d "vps unhealthy on $(hostname)"
```

## Thresholds

All in one place at the top of `collect.go`:

| Resource | OK | WARN | BAD |
|---|---|---|---|
| CPU load (% of cores, 1m) | <70 | 70–100 | ≥100 |
| RAM available | >20% | 10–20% | ≤10% |
| Swap in use | <512 MB | ≥512 MB | ≥1 GB |
| Disk root | <75% | 75–90% | ≥90% |
| Inodes | <85% | 85–95% | ≥95% |
| File descriptors | <70% | 70–90% | ≥90% |
| OOM kills (24h) | 0 | ≥1 | ≥1 + tight RAM |
| Failed systemd units | 0 | ≥1 | – |
| Container restart rate | 0 | >10/min | >100/min |

## Distribution flow

```
   developer pushes tag v1.2.3
            │
            ▼
   ┌───────────────────────┐   builds linux/darwin × amd64/arm64,
   │ GitHub Actions        │   GitHub Release with SHA256SUMS
   │ release.yml           │
   └──────────┬────────────┘
              │ calls ottomind-ai/get/.github/workflows/yayinla.yml
              ▼
   ┌───────────────────────┐   packages paket.json + skill/, scans for secrets,
   │ shared publish        │   uploads to AWS S3 (published versions can't be
   │ workflow              │   overwritten), updates latest + index; a
   │                       │   Cloudflare Worker serves both addresses
   └──────────┬────────────┘
              ▼
   get.ottomind.ai/sina          installer (curl … | sudo bash), binaries, SHA256SUMS, manifest
   skills.ottomind.ai/sina       SKILL.md and the Claude skill zip
```

## Cutting a release

```bash
git tag v0.3.1
git push origin v0.3.1
```

The release workflow builds the four binaries, publishes a GitHub Release and the
get.ottomind.ai / skills.ottomind.ai files. A published version can't be overwritten;
fix forward with a new version. No secrets: the publish job signs in to AWS with GitHub OIDC
(see ottomind-ai/get).

## Layout

```
.
├── .github/workflows/
│   ├── ci.yml              # vet + gofmt + build on every push/PR
│   └── release.yml         # cross-arch build, GitHub Release, get.ottomind.ai publish on v* tag
├── go.mod
├── install.sh              # curl|bash entrypoint (downloads from get.ottomind.ai, verifies sha256)
├── paket.json              # what get.ottomind.ai publishes (shared publish workflow)
├── skill/                  # SKILL.md for AI agents (skills.ottomind.ai/sina)
├── install-from-source.sh  # git clone + go build (no Release needed)
├── README.md
├── main.go                 # entry, flags, plain/TUI dispatch
├── types.go                # Report data types
├── collect.go              # /proc, df, ps, docker, journalctl probes
├── decide.go               # OK/WARN/BAD logic
├── styles.go               # lipgloss styles + bars + badges
├── render.go               # Report → string (used by both modes)
└── model.go                # Bubble Tea Model/Update/View
```

[Bubble Tea]: https://github.com/charmbracelet/bubbletea
[Lip Gloss]: https://github.com/charmbracelet/lipgloss
