---
description: Issue Fixing Workflow
auto_execution_mode: 1
---

# Issue Fixing Workflow

## Primary Diagnosis Phase
- Understand the problem by viewing logs, installing required diagnostic tools, and checking everything you need to definitive about the error
- Go through the code step by step from the highest level until the point where the error is occuring
- Confirm what is happening by checking logs in sequence proving the code path
- Check configs and environment variables
- Check database tables

## Multi-Language Testing Validation
- If issue involves user-facing features, run multi-language tests to validate:
  - `./streetz-docker.sh --test-env start` - Start test environment
  - `./streetz-docker.sh --test-multi-lang unit` - Test unit layer across languages
  - `./streetz-docker.sh --test-multi-lang integration` - Test API layer across languages
  - `./streetz-docker.sh --test-multi-lang ui` - Test UI layer across languages
  - `./streetz-docker.sh --test-env stop` - Stop test environment
- Review test results to identify language-specific issues or patterns
- Use test environment logs for additional diagnostic information

## Resolution and Validation
- Present the full process to the user and the potential problem and proposed fix unless the fix if a typo (fix immediately and retest until working), a missing/broken repository implementation (fix immeditately and retest until working), 
- Get user approval before implementation, unless the user says keep going until its fixed
- If you make a fix and it doesn't work, you must revert it before trying the next fix
- Validate fixes using both production and test environments
- Re-run relevant multi-language tests to ensure fix works across all supported languages
- Repeat the process until the problem is resolved
- Do not make continuous changes to code without removing failing fixes
- If required, you can add debug logs to assist in troubleshooting but you don't need to remove these unless they are excessive
- Cleanup afterwards by removing temporary debug logs if added, but you can leave useful debugging, especially if a similar issue might occur