---
description: Gather comprehensive environment context for debugging and analysis
tags: [devops, debugging, context-gathering]
---

# Gather Environment Context

Use this workflow when you need to understand the full environment context for a service, deployment, or infrastructure issue.

## Steps

1. **Read core documentation**
   - Read `ARCHITECTURE.md`
   - Read `README.md`
   - Read `IMPLEMENTATION_PLAN.md`

2. **Check environment configuration**
   - Check `.windsurf/rules` for project rules and guidelines
   - Check `docker-compose.yml`
   - Check `docs/` directory

3. **Gather related project context when needed**
   - Use `/home/tkaviya/Projects/resources` as an external context source when the task requires direct knowledge about a particular project.
   - Start from project names only. Reference the matching folder when code-level details are required.
   - Always run `git pull` inside any related project folder before viewing code-level details from that folder. If the pull fails, record the failure before using the local checkout.
   - Current `/home/tkaviya/Projects/resources` project names:
     - `G0DM0D3`
     - `Kimi-K2.5`
     - `MiniMax-M2`
     - `Trading`
     - `agentscope`
     - `claude-cowork-linux`
     - `claude-mem`
     - `claw-code`
     - `cline`
     - `crewai`
     - `deer-flow`
     - `docs`
     - `free-claude-code`
     - `gpustack`
     - `gstack`
     - `jcode`
     - `llama.cpp`
     - `ollama`
     - `openclaw`
     - `openfang`
     - `picoclaw`
     - `ruflo`
   - Current `/home/tkaviya/Projects/resources/Trading` project names:
     - `TradingAgents`
     - `claude-execute`

4. **Gather stock trading context when needed**
   - For stock trading, Deriv strategy, historical data, strategy design, testing, and API-key configuration context, use:
     - `/home/tkaviya/Projects/t3ratrade`
     - `/home/tkaviya/Projects/t3ratrade/T3raTradeAI`
     - `/home/tkaviya/Projects/t3ratrade/Docs`
     - `/home/tkaviya/Projects/t3ratrade/Strategies`
     - `/home/tkaviya/Projects/t3ratrade/T3raTradeAI/.windsurf/workflows`
     - `/home/tkaviya/Projects/t3ratrade/.windsurf/workflows`
     - `/home/tkaviya/Projects/t3ratrade/Tests/Data`
   - Always run `git pull` in the relevant repository or project folder before viewing code-level details.
   - Use API-key context to identify required configuration and integration paths only. Never print, copy, commit, or expose secret values.
