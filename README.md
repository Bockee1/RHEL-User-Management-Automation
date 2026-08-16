# RHEL-User-Management-Automation
# RHEL Staff Onboarding & User Management Automation

A Bash-based CLI tool that automates user lifecycle management on Red Hat Enterprise Linux (RHEL); built as a Red Hat use case demo for VNigeria's internal hackathon (August 2026).

## The Problem

Manually onboarding new staff onto RHEL systems is repetitive and error-prone: creating accounts one at a time, assigning group access inconsistently, forgetting to force a password reset on first login, and having no centralized way to check who's actually logged in or deactivate access when someone leaves. At scale; even for a small IT/sales team, this becomes a real operational and security risk (over-privileged accounts, stale access, no audit trail).

## What It Does

An interactive menu-driven tool that handles the full lifecycle of a RHEL user account:

- **Batch onboarding**: creates multiple accounts at once from a staff list, with role-based group access instead of blanket permissions
- **On-the-fly single user creation**: for ad hoc onboarding, with an explicit prompt before granting elevated (IT-team) access
- **Login status check**: quickly see last-login activity for all IT-team members
- **Onboarding log viewer**: full audit trail of every account created, skipped, or failed
- **User deactivation**: locks an account (`usermod -L`) without deleting it, preserving data and audit history

## Key Design Decisions

- **Least-privilege by default**: group access (e.g. `it-team`) is granted explicitly per user, not assigned automatically to everyone onboarded — avoids over-privileging new hires who don't need elevated access.
- **Per-user generated passwords** (via `openssl rand`), not a shared default password, with forced reset at first login (`chage -d 0`) and locked-down log file permissions (`chmod 600`), avoids storing plaintext credentials somewhere world-readable.
- **Fails safe**: root-privilege check on startup, confirmation prompts before any destructive or account-creating action, and existing-user checks to prevent accidental overwrites.
- **Full audit logging**: every action (created, skipped, failed, deactivated) is timestamped and written to a persistent log.

## Tech Used

- RHEL (Red Hat Enterprise Linux)
- Bash / shell scripting
- Core Linux user management: `useradd`, `usermod`, `chpasswd`, `chage`, `getent`, `lastlog`

## How to Run

```bash
sudo ./onboard_staff.sh
```

Requires root privileges (the script checks and exits if not run as root). Menu-driven — select an option 1–6 to batch onboard, add a single user, check login status, view logs, deactivate a user, or exit.

For batch onboarding, prepare a staff list at `/tmp/new_staff.txt` in the format:
```
username:role
```
where `role` is `it` for IT-team access, or left blank/anything else for standard access.

## Context

Built as part of VNigeria's Red Hat hackathon, demonstrating a practical RHEL system administration use case: automated, auditable, least-privilege user lifecycle management, the kind of operational tooling relevant to enterprise RHEL deployments.
