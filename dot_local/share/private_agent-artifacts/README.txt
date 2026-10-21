Box review artifacts

Open https://box.javanese-pound.ts.net:8443/ while connected to Tailscale.
Reports and downloads appear here when an agent publishes them.

Agents save each task's files in:
  /home/eddies/.local/share/agent-artifacts/<unique-task>/

The direct link for a report is:
  https://box.javanese-pound.ts.net:8443/<unique-task>/report.html

Chezmoi configures this private file server. Tailscale keeps it running after
logout and reboot. No per-session startup command is needed.

Only publish intended review files and their assets. Keep secrets, repository
roots, and symlinks outside this directory. Live web apps need their own running
process and proxy route; this directory serves static files only.
