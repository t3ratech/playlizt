---
trigger: always_on
description: 
globs: 
---

# Commit Message Rules
1. First line: Brief summary of changes
2. Second line: Blank line
3. Remaining lines: Detailed bullet points of all changes made
4. Commit messages must be based ONLY on the diff between the last commit and current file state
5. Commit messages must be consise and non repetitive
6. Never include credentials, passwords, or any sensitive information in commit messages
7. Never resolve Git conflicts automatically
8. Never commit and push automatically, always ask for final approval before commit and push

# Git Workflow Rules

## Command Structure
- ALWAYS use single combined command: git pull origin [branch] && git add [files] && git commit -m "[message]" && git push origin [branch]
- Never split into separate commands

## Pre-Commit Checks
1. Run git status to review all changes
2. Review each changed file carefully
3. Always check ARCHITECTURE.md and README.md to ensure changes align with system architecture and documentation and if not, either ask the user to update the documentation, or change to code to suit the architecture.

## Review Process
1. Show complete commit command for review
2. Wait for user approval before execution
3. Verify all changes match expectations

## Handling Deleted Files
- Always include deleted files in the commit
- Use git status to identify deleted files (they'll appear as "deleted:" in the output)
- Use git add --all or git add -A to stage all changes including deletions
- Alternatively, use git rm <filename> to stage a deletion for a specific file
- Always verify that deleted files appear in the "Changes to be committed" section before committing
- Include information about deleted files in the commit message bullet points