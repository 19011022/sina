---
name: sina
description: One-screen health check for Linux servers (Ubuntu VPS with Docker); Linux only. Use when the user asks whether a server is healthy, why it is slow, running out of disk, memory or inodes, why containers keep restarting, or wants a scriptable OK/WARN/BAD check for cron or monitoring. Installs a single static binary with one verified command; read-only.
---

# sina {{version}}

`sina` is a single static binary for Linux (amd64 and arm64) that reads `/proc`, `df`, `ps`, `docker` and `journalctl` and prints CPU/load, memory, swap, disk and inodes, the largest mounts and directories, Docker containers (top by CPU/memory, reclaimable space, restart loops), top processes, zombies, journal size, OOM kills in the last 24 h, failed systemd units, the reboot-required flag and file-descriptor usage, followed by an **OK / WARN / BAD** verdict with reasons and suggested actions. It changes nothing on the machine.

## When to use

- The user wants a quick overview of a server's health, or to find what is filling the disk or memory.
- Containers restart repeatedly, the machine is slow, or the user suspects OOM kills.
- The user wants a health check in cron or another monitor (exit code 0 / 1 / 2).

Not for: Windows, metrics over time (use a monitoring stack), or fixing problems by itself.

## Install

Run it on the server itself. From a laptop, go over SSH; on macOS or Windows sina refuses to run (exit 3), because it reads Linux-only sources. Installing to `/usr/local/bin` needs root; ask the user first, or install into a user directory.

```bash
curl -fsSL https://get.ottomind.ai/sina/{{version}} | sudo bash                          # this exact version (prefer in automation)
curl -fsSL https://get.ottomind.ai/sina | sudo bash                                      # latest version
curl -fsSL https://get.ottomind.ai/sina | SINA_PREFIX="$HOME/.local/bin" bash             # no root; the variable goes after the pipe
ssh my-server 'curl -fsSL https://get.ottomind.ai/sina | sudo bash'                        # from your laptop
```

The installer detects the architecture, downloads `sina_linux_<arch>.tar.gz` from `https://get.ottomind.ai/sina/<version>/`, **stops unless the SHA-256 matches** `SHA256SUMS`, installs the binary (creating the directory if needed, warning if it isn't on `PATH`) and prints `sina --version`. Manual check:

```bash
arch=$(uname -m | sed 's/x86_64/amd64/; s/aarch64/arm64/')
curl -fsSLO https://get.ottomind.ai/sina/{{version}}/sina_linux_${arch}.tar.gz
curl -fsSL https://get.ottomind.ai/sina/{{version}}/SHA256SUMS | grep " sina_linux_${arch}.tar.gz$" | sha256sum -c -
tar -xzf sina_linux_${arch}.tar.gz && ./sina --version
```

## Use

As an agent, always run the non-interactive form; the default TUI needs a terminal:

```bash
sina --plain --no-color
echo "exit: $?"     # 0 = OK, 1 = at least one WARN, 2 = at least one BAD, 3 = not Linux
```

Read the verdict first, then the sections it names. Summarise for the user: overall state, each WARN/BAD with its cause, and the suggested actions. Thresholds: https://skills.ottomind.ai/sina/references/thresholds.md. Without root some numbers are partial (sina says "rerun with sudo" for the largest directories); `sudo sina --plain` gives the full picture but isn't required.

Cron example (ask before adding it):

```bash
*/15 * * * * sina --plain --no-color > "$HOME/sina.log" 2>&1 || logger -t sina "unhealthy: exit $?"   # user crontab; full path if sina isn't on cron's PATH
```

## Ask the user before

- installing on a server, and whether to use `sudo` or a user directory;
- running any suggested action that deletes or restarts something (`docker system prune`, `journalctl --vacuum-*`, removing files, restarting services, rebooting). sina only reports; the decision is the user's;
- adding a cron job or alert.

## Limits

- Linux only (amd64, arm64). Built for Ubuntu with Docker; without Docker or systemd those sections stay empty. The Docker section needs access to the Docker socket (docker group or sudo).
- A snapshot, not history: run it again after a change to compare.
