package main

import "testing"

// Sections that could not be measured (Unknown) or are informational must not raise the verdict or add reasons.
func TestUnmeasuredSectionsAreNotProblems(t *testing.T) {
	r := &Report{}
	r.Zombies.Status = StatusUnknown // e.g. ps missing on a slim image
	r.FDs.Status = StatusUnknown
	r.Inodes.Status = StatusInfo
	r.Memory.SwapStatus = StatusUnknown
	d := decide(r)
	if d.Overall != StatusOK {
		t.Fatalf("overall = %v, want OK", d.Overall)
	}
	if len(d.Reasons) != 0 {
		t.Fatalf("reasons = %q, want none", d.Reasons)
	}
}

func TestZombiesWarn(t *testing.T) {
	r := &Report{}
	r.Zombies.Status = StatusWarn
	r.Zombies.Procs = []ZombieProc{{}}
	d := decide(r)
	if d.Overall != StatusWarn || len(d.Reasons) != 1 {
		t.Fatalf("overall = %v reasons = %q, want WARN with one reason", d.Overall, d.Reasons)
	}
}
