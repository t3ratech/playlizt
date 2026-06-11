<!--
Created in Windsurf 2.1.32 (GPT-5.3 Codex)
Author       : Tsungai Kaviya
Copyright    : TeraTech Solutions (Pvt) Ltd
Date/Time    : 2026-05-05 09:14:00
Email        : tkaviya@t3ratech.co.zw
-->

---
trigger: always_on
---

# Commit Message Rules
1. First line: Brief summary of changes describing what changed
2. Second line: Blank line
3. Remaining lines: Detailed bullet points of all changes made
4. Commit messages must be based ONLY on the diff between the last commit and current file state
5. Commit messages must be consise and non repetitive
6. Never include credentials, passwords, or any sensitive information in commit messages
7. Never resolve Git conflicts automatically
8. Commit and push automatically when the user explicitly requests it

# Git Workflow Rules

## Command Structure
- ALWAYS use single combined command: bash t3rnel-docker.sh --db-sync-export && git pull origin [branch] && git add [files] && git commit -m "[message]" && git push origin [branch]
- Never split into separate commands
- For recurring operational actions (build/run/log/export/parity checks), route commands through `t3rnel-docker.sh` instead of ad-hoc scripts.

## Pre-Commit Checks
1. Run git status to review all changes
2. Review each changed file carefully
3. Always check ARCHITECTURE.md and README.md to ensure changes align with system architecture and documentation and if not, either ask the user to update the documentation, or change code to suit the documented architecture.

## Review Process
1. Show complete commit command for review
2. Execute immediately when user explicitly approves
3. Verify all changes match expectations

## Temporary Files Policy
- Ensure every tracked change is included in the commit (except temporary/log files).
- Delete temp/log files before staging or add their patterns to `.gitignore` so they are excluded permanently.
- Mention in the review step which files were deleted or ignored so the user can confirm.

## Handling Deleted Files
- Always include deleted files in the commit
- Use git status to identify deleted files (they'll appear as "deleted:" in the output)
- Use git add --all or git add -A to stage all changes including deletions
- Alternatively, use git rm <filename> to stage a deletion for a specific file
- Always verify that deleted files appear in the "Changes to be committed" section before committing
- Include information about deleted files in the commit message bullet points
