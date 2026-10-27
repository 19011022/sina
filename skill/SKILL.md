---
name: sina
description: One-screen health check for Linux servers (Ubuntu VPS with Docker). Use when the user asks whether a server is healthy, why it is slow, running out of disk, memory or inodes, why containers keep restarting, or wants a scriptable OK/WARN/BAD check for cron or monitoring. Installs a single static binary with one verified command; read-only.
---

# sina {{version}}

`sina` is a single static binary (Linux and macOS, amd64 and arm64) that reads `/proc`, `df`, `ps`, `docker` and `journalctl` and prints CPU/load, memory, swap, disk and inodes, the largest mounts and directories, Docker containers (top by CPU/memory, reclaimable space, restart loops), top processes, zombies, journal size, OOM kills in the last 24 h, failed systemd units, the reboot-required flag and file-descriptor usage, followed by an **OK / WARN / BAD** verdict with reasons and suggested actions. It changes nothing on the machine.

## When to use

- The user wants a quick overview of a server's health, or to find what is filling the disk or memory.
- Containers restart repeatedly, the machine is slow, or the user suspects OOM kills.
- The user wants a health check in cron or another monitor (exit code 0 / 1 / 2).

Not for: Windows, metrics over time (use a monitoring stack), or fixing problems by itself.

## Install

Run on the server itself (over SSH). Installing to `/usr/local/bin` needs root; ask the user first.

```bash
curl -fsSL https://get.ottomind.ai/sina/{{version}} | sudo bash     # this exact version (prefer in automation)
curl -fsSL https://get.ottomind.ai/sina | sudo bash                 # latest version
SINA_PREFIX="$HOME/.local/bin" curl -fsSL https://get.ottomind.ai/sina | bash   # without root
```

The installer detects OS/architecture, downloads `sina_<os>_<arch>.tar.gz` from `https://get.ottomind.ai/sina/<version>/`, **stops unless the SHA-256 matches** `SHA256SUMS`, installs the binary and prints `sina --version`. Manual check:

```bash
curl -fsSLO https://get.ottomind.ai/sina/{{version}}/sina_linux_amd64.tar.gz
curl -fsSL https://get.ottomind.ai/sina/{{version}}/SHA256SUMS | grep ' sina_linux_amd64.tar.gz$' | sha256sum -c -
```

## Use

As an agent, always run the non-interactive form; the default TUI needs a terminal:

```bash
sina --plain --no-color
echo "exit: $?"     # 0 = OK, 1 = at least one WARN, 2 = at least one BAD
```

Read the verdict first, then the sections it names. Summarise for the user: overall state, each WARN/BAD with its cause, and the suggested actions. Thresholds are in [references/thresholds.md](references/thresholds.md).

Cron example (ask before adding it):

```bash
*/15 * * * * /usr/local/bin/sina --plain --no-color > /var/log/sina.log 2>&1 || logger -t sina "unhealthy: exit $?"
```

## Ask the user before

- installing on a server, and whether to use `sudo` or a user directory;
- running any suggested action that deletes or restarts something (`docker system prune`, `journalctl --vacuum-*`, removing files, restarting services, rebooting). sina only reports; the decision is the user's;
- adding a cron job or alert.

## Limits

- Built for Ubuntu with Docker; on other systems some sections are empty (no Docker, no systemd, macOS).
- A snapshot, not history: run it again after a change to compare.
