<!--
Created in Windsurf 2.1.32 (GPT-5.3 Codex)
Author       : Tsungai Kaviya
Copyright    : TeraTech Solutions (Pvt) Ltd
Date/Time    : 2026-05-05 09:14:00
Email        : tkaviya@t3ratech.co.zw
-->

# T3raCode Rules

## Implementation Rules

1. **NO SAMPLE CODE, FAKE CODE, OR PARTIAL IMPLEMENTATIONS.** This system handles REAL MONEY! Absolutely no hardcoded defaults, placeholders, TODO/FIXME markers, or fallbacks. The system MUST FAIL FAST AND HARD when configuration is missing or invalid & MUST FAIL TO COMPILE/RUN rather than have dummy/fake implementations or temporary code. Do NOT do defensive coding to make it fail gently. Do NOT create a function/file unless you implement it END TO END, IN FULL! This is the MOST IMPORTANT RULE!!!!!!!!!!
2. I DO NOT WANT CONSTANT INTERRUPTION! Once I give you an instruction, DO NOT TALK TO ME until the required outcome has been COMPLETED AND VERIFIED END TO END. Do not ask me for approvals, do not update me, do not ask me questions when you already have a highly recommended solution, just implement and I prefer to change it afterwards if required. DO NOT TALK TO ME UNTIL YOU HIT A BLOCKER! Even if you hit a blocker, do EVERYTHING ELSE INCLUDING DOCUMENTATION until you are absolutely stuck and the only thing you can do is waiting on that blocker.
3. Never introduce new technologies, refactor broadly, or alter architecture without explicit user approval.
4. Document everything as you go along. We have 2 documentations ARCHITECTURE.md in the root folder is for technical, highly detailed development information (including business information for context), while README.md is more for end users and can even be used as a marketing document. Update both documents with every change to the system, even before you implement something, so that if you cannot complete, we know what the idea is. Do not use tenses such as "to be implemented" or "changed from xxx". JUST Say "This system does xyz". NEVER reference the past or the future.
5. **NO PARTIAL WORK**: Complete all phases end-to-end. The user should receive a fully working and tested system. If requested explicitly, the system should be deployed and verified.
6. **SILENT EXECUTION**: For the most part, work silently. Only communicate when everything is 100% complete, unless there is a blocker you cannot circumvent alone, meanwhile do all other non blocked work end to end and only talk to the user when there is nothing else left to do
7. **NO INTERRUPTIONS**: Do not stop, do not pause, do not ask questions (unless absolutely necessary), do not provide progress updates until EVERYTHING is done.

## How We Interact With The System
1. **NO shell redirection shortcuts** - Never use `&>`, `2>&1 |`, or similar. Always run commands directly with full verbose output.
2. **Fix Bugs Immediately** - When you see errors, stop and fix them. Don't continue hoping they'll resolve.
3. **No Git Without Permission** - Never run git add/commit/push without explicit user instruction.
4. **Prefer Hard Failures** - A crash with a clear error message is better than silent incorrect behavior that hides bugs.
5. **IDE First** - Always use the IDE (Windsurf/Cascade) for editing files and running commands. Never use external tools when IDE tools are available.
6. **Single Ops Entry Point — `t3rnel-services.sh`** — Every start, stop, restart, build, rebuild, test, lint, migration, service probe, log tail, and cleanup command runs through `./t3rnel-services.sh`. No ad-hoc `docker run`, no `docker compose up` directly, no `cargo run` outside the script, no `pnpm dev` outside the script. If a command is missing from the script, **add it to the script** instead of bypassing it. The script is the memory of every operational command in the project; bypassing it is how commands get forgotten.
7. **Never run unbounded Rust workspace tests** — Do not run `cargo test --workspace` or equivalent full-workspace Rust tests in the default/high-parallelism mode. It has crashed the development PC. Use targeted crate/module tests, `cargo test --workspace --lib`, or an explicit serialized/low-resource command such as `CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUSTFLAGS='-C debuginfo=0' cargo test --workspace --lib --jobs 1`, and prefer `t3rnel-services.sh` entries that enforce those limits.
