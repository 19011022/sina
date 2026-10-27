# sina thresholds

| Resource | OK | WARN | BAD |
|---|---|---|---|
| CPU load (% of cores, 1 min) | < 70 | 70–100 | ≥ 100 |
| RAM available | > 20 % | 10–20 % | ≤ 10 % |
| Swap in use | < 512 MB | ≥ 512 MB | ≥ 1 GB |
| Disk (root) | < 75 % | 75–90 % | ≥ 90 % |
| Inodes | < 85 % | 85–95 % | ≥ 95 % |
| File descriptors | < 70 % | 70–90 % | ≥ 90 % |
| OOM kills (24 h) | 0 | ≥ 1 | ≥ 1 with tight RAM |
| Failed systemd units | 0 | ≥ 1 | – |
| Container restart rate | 0 | > 10/min | > 100/min |

Swap is judged by active swapping (vmstat delta), not only by occupancy. Thresholds live at the top of `collect.go` in the source.
