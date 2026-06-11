# Deriv Strategy Promotion Loop

Use this workflow whenever improving, testing, promoting, or integrating Deriv trading strategies.

## Rules

1. **Do not promote unproven strategies**
   - A strategy may enter the UI/agent catalog only when the source lab row has `passed: true`.
   - Backtest pass is not live/demo proof. Label it `backtest_passed` until demo execution validates it.
   - A strategy is `demo_success` only after broker-verified demo campaign evidence reaches all gates:
     - Account return: `>= 10%`
     - Win rate: `>= 80%`
     - Max drawdown: `< 30%`
   - `enabled: true` is allowed only for `validationStatus: "demo_success"`. Backtest candidates and failed demo rows must stay disabled until manually re-tested or promoted by verified evidence.

2. **Strategies are plugin/catalog data**
   - Do not hardcode strategy IDs into frontend/shared types.
   - Strategy IDs are open strings so third-party packs can add new strategies without a rebuild.
   - Use catalog JSON or daemon API data as the source of truth.
   - `brokerSymbol` means the strategy has a Deriv execution target. `brokerMappingConfidence: "proxy"` means the broker target is an explicitly labelled proxy and must be revalidated.
   - Proxy rows without broker-verified campaign evidence stay `validationStatus: "needs_mapping"` rather than `backtest_passed`. Do not put them in the normal demo loop until an exact Deriv active symbol is found or a separate proxy-validation run is explicitly requested.
   - Deriv active-symbol discovery on 2026-06-06 found no active `XRP`, `BNB`, `AAPL`, `Apple`, or exact `SPX` symbol; `OTC_SPC` is US 500, `OTC_NDX` is US Tech 100, and `OTC_DJI` is Wall Street 30. Keep those mappings labelled as proxy unless a later active-symbol query proves an exact symbol exists.
   - `executable: true` means the web/desktop Deriv client has an order adapter for that strategy. `adapterStatus: "campaign_candle_adapter"` means it can be campaign-tested by the demo runner but not fired from the UI engine yet.
   - Generated/promoted catalog path:
     - `clients/web/public/trading/deriv-strategy-catalog.json`
   - Runtime plugin/variant catalog path:
     - `clients/web/public/trading/deriv-variant-catalog.json`
   - `/api/trading/strategies` must merge the base catalog with runtime plugin/variant packs so web, desktop, mobile, and agents can inspect new strategies without a rebuild.
   - Daemon runtime override:
     - Set `T3RNEL_STRATEGY_CATALOG=/path/to/catalog.json`
   - Recent retune packs must use batch-scoped `sourceStrategyId` values and preserve the original family as `baseStrategyId`. A broker-verified loss cools siblings in the same exact source batch after `1` source loss. The broader base family cools only after the base-family loss threshold, currently `2`, so a single one-cent base loss does not freeze every fresh retune batch.

3. **Promotion command**
   - Promote passed strategies from a lab report:
     ```bash
     python3 scripts/promote_deriv_strategy_catalog.py \
       --report reports/trading-strategy-lab/deriv_strategy_lab_YYYYMMDDTHHMMSSZ.json
     ```
   - The promoter filters out anything without `passed: true`.
   - Verify the generated catalog before using it:
     ```bash
     python3 scripts/verify_deriv_strategy_catalog.py
     ```
   - Probe broker candle availability and strategy signal adapters without trading:
     ```bash
     python3 scripts/deriv_catalog_candle_probe.py
     ```

4. **Demo execution loop**
   - Use the demo account for Codex/agent training runs unless the user explicitly asks to operate the production live system.
   - Record opening balance, closing balance, trade count, wins/losses, drawdown, and active strategies.
   - Demo campaign reports are written under `reports/trading-strategy-lab/deriv_demo_campaign_*.json`.
   - Use the full plugin catalog campaign runner for real demo evidence across all mapped strategies:
     ```bash
     python3 scripts/deriv_demo_catalog_campaign_runner.py \
       --target-balance 24000 \
       --required-passes 20
     ```
   - The catalog runner is demo-only, refuses non-virtual accounts, evaluates broker candles with the strategy adapters, places Deriv multiplier contracts only after a valid strategy signal, learns/retries broker-accepted multiplier candidates per symbol, and writes per-strategy evidence.
   - When a candle-level signal passes but broker execution loses or times out, tighten execution before spending more demo trades. The current runner supports live tick-entry preflight (`--entry-preflight-*`) plus stale-edge exits (`--stale-exit-*`) and records entry preflight, max/min open-contract profit, TP/SL, exit reason, and broker-verified contract IDs in the campaign report.
   - Prefer loss containment over trade volume. Use campaign-wide, source-wide, and base-family stop rules so a losing signal family does not keep spending demo trades while the loop searches for better setups.
   - Do not force a fixed number of open positions. The aim is not “20 open contracts”; the aim is enough independent strategy coverage that at least some scripts regularly find high-quality setups. If too few setups appear, expand or retune the candidate catalog before trading rather than opening blind filler positions.
   - Prefer confirmed setups over single-tick signals. Use `--confirm-signal-checks` and `--confirm-signal-delay` so a signal has to persist before a demo order is placed.
   - If a probed source repeatedly starts campaigns that place no trades because confirmation never persists, cool that exact source with `--skip-source-after-no-trade-campaigns`. This is not broker loss evidence and should not automatically cool the broader base family unless `--skip-base-after-no-trade-campaigns` is explicitly set.
   - For cycle execution across the catalog, use the concurrent wrapper. It fans out bounded demo-only workers, verifies every campaign, rebuilds the catalog, writes a promotion status report, and records per-cycle actions:
     ```bash
     python3 scripts/deriv_concurrent_strategy_cycle.py \
       --cycles 1 \
       --max-strategies 20 \
       --concurrency 20 \
       --max-signal-checks 1
     ```
   - The concurrent wrapper defaults to skipping `demo_rejected`, broker-verified `demo_gate_failed`, and `brokerMappingConfidence: "proxy"` rows after an all-catalog diagnostic cycle. Use explicit flags only when intentionally collecting diagnostic evidence from failed/proxy rows.
   - Avoid repeated one-second `ticks_history` polling across many workers; Deriv rate-limits that pattern. Use `--max-signal-checks 1` for all-catalog cycles, then generate/tune variants from backtests before re-running broker evidence.
   - The controller probe must stay fast enough to optimize between cycles. It writes an eligible-only temporary probe catalog before each scan, then `scripts/deriv_catalog_candle_probe.py` caches candles by `(brokerSymbol, timeframe)` so many variants share one Deriv candle request. The probe summary must include `unique_candle_series`; if it climbs toward strategy count, fix duplicate data access before increasing trade volume. The probe should receive the same `--confirm-signal-checks` and `--confirm-signal-delay` values as the campaign runner so transient public-candle signals are filtered before a demo campaign is started.
   - When broker evidence rejects or gate-fails the current catalog, generate a candidate pack from recent public Deriv candles before spending more demo trades:
     ```bash
     python3 scripts/deriv_recent_variant_lab.py \
       --candle-count 1200 \
       --skip-proxy \
       --max-param-variants 24 \
       --max-risk-variants 40
     ```
   - Before retuning a mature runtime pack, dedupe the research input so repeated source batches do not multiply the same broker/side/adapter/timeframe/base-family scan:
     ```bash
     python3 scripts/deriv_catalog_research_dedupe.py \
       --catalog clients/web/public/trading/deriv-variant-catalog.json \
       --include-broker-symbol 1HZ25V,1HZ90V \
       --include-preferred-side short \
       --max-per-group 1 \
       --output reports/trading-strategy-lab/deriv_watch_short_deduped_YYYYMMDDTHHMMZ.json
     ```
   - Recent-candle variants are research only. Convert a passing variant report into a temporary catalog, then demo-test that catalog with explicit source metadata:
     ```bash
     python3 scripts/promote_deriv_strategy_catalog.py \
       --report reports/trading-strategy-lab/deriv_recent_variant_lab_YYYYMMDDTHHMMSSZ.json \
       --output reports/trading-strategy-lab/deriv_recent_variant_catalog_YYYYMMDDTHHMMSSZ.json \
       --source report:deriv_recent_variant_lab

     python3 scripts/deriv_concurrent_strategy_cycle.py \
       --catalog reports/trading-strategy-lab/deriv_recent_variant_catalog_YYYYMMDDTHHMMSSZ.json \
       --source-report reports/trading-strategy-lab/deriv_recent_variant_lab_YYYYMMDDTHHMMSSZ.json \
       --expected-count 4
     ```
   - Variant cycle reports use `deriv_variant_promotion_loop_*.json`; main UI evidence continues to use `deriv_promotion_loop_*.json` for the 20-strategy catalog.
   - Desktop/web may expose the latest variant catalog at `clients/web/public/trading/deriv-variant-catalog.json` as disabled lab candidates. This is visibility, not promotion: variant rows must remain `enabled: false` and cannot be treated as `demo_success` until broker-verified demo gates pass.
   - The active 2026-06-07 runtime retune pack is `reports/trading-strategy-lab/deriv_recent_variant_lab_20260607T100805Z_runtime_merged_321.json`, with `321` disabled, exact-symbol candidates published to `clients/web/public/trading/deriv-variant-catalog.json`: `16` `R_100`, `105` `1HZ25V`, `21` `1HZ15V`, `34` `1HZ90V`, `12` `BOOM50`, `36` `BOOM900`, `9` `CRASH600`, `9` `CRASH1000`, `6` `cryETHUSD`, plus `73` new exact-symbol candidates from `reports/trading-strategy-lab/deriv_recent_variant_lab_20260607T100805Z.json` across `1HZ10V`, `1HZ30V`, `BOOM150N`, `BOOM300N`, `BOOM600`, `CRASH50`, `CRASH150N`, `CRASH300N`, and `cryBTCUSD`. Those rows are disabled lab candidates only; they cannot be traded until a fresh proof-ready signal appears. Runtime rows record `latestSignal`, `latestSignalSide`, `barsSinceLastSignal`, `signalsTotal`, `signalsLastLookback`, and signal-density fields. Retune packs preserve original `baseStrategyId` values for cross-retune cooldown; do not relabel a failed base family as new unless the strategy logic is genuinely new.
   - Current broker evidence remains failed/unpromoted: demo account `VRTC11987702`, balance `$8117.96`, open contracts `0`, latest 100-row reconcile net P&L `-$15.27`, win rate `18.00%`, `0` demo-success rows, and `0` enabled rows. Broker failure analysis at `reports/trading-strategy-lab/deriv_broker_failure_analysis_20260607T121603Z.json` covers `112` verified demo trades with net P&L `-$13.38`, `2` broker-positive focus groups, and `16` cooled symbol-side groups. The published runtime catalog has `321` rows; `reports/trading-strategy-lab/deriv_variant_promotion_status_20260607T102015Z.json` shows all `321` rows as backtest candidates with `0` demo-success and `0` enabled. After the latest no-trade controller heartbeat at `reports/trading-strategy-lab/deriv_promotion_loop_20260607T121617Z.json`, the guarded controller is complete after iteration `1`, with `0` eligible/probed rows, `0` probe-ok rows, `0` probe errors, `0` controller-scan signals, `0` unique candle series, `0` selected rows, and `0` new proof trades. It writes `eligible_count`, `eligible_strategy_ids`, source/base/symbol counts, `probe_count`, `probe_ok_count`, `probe_error_count`, `signals_now`, and `unique_candle_series` to `clients/web/public/trading/deriv-engine-status.json`, and the daemon also exposes `/api/trading/deriv/engine-status`, so web/desktop/mobile do not estimate the active pool. It must not run a proof order without a live proof-eligible signal, and it must not promote or enable any strategy until broker-verified demo gates pass.
   - A full-catalog no-trade candle probe can show raw signals separately from proof-eligible signals. `reports/trading-strategy-lab/deriv_variant_catalog_candle_probe_20260607T125147Z.json` refreshed the 321-row runtime pack and found `321/321` probe OK, `32` unique candle series, and `5` current raw signals across three groups: `BOOM600` short M1/M5 and `BOOM300N` short M1. `reports/trading-strategy-lab/deriv_proof_readiness_20260607T125200Z.json` classifies `0` groups as proof-ready, `0` diagnostic groups as seedable, `1` BOOM300N group as retune-required, `2` BOOM600 groups as broker-blocked, and `1` group as missing broker-positive evidence. A strict current-signal focus retune, `reports/trading-strategy-lab/deriv_recent_variant_lab_20260607T094856Z.json`, tested `1112` 1HZ25V/1HZ90V short variants with `--require-current-signal` and produced `0` passed rows. The narrower watch short retune, `reports/trading-strategy-lab/deriv_recent_variant_lab_20260607T102229Z.json`, tested `120` 1HZ25V/1HZ90V short variants with `--max-bars-since-signal 2` and produced `0` passed rows. The deduped current-watch retune, `reports/trading-strategy-lab/deriv_recent_variant_lab_20260607T110530Z.json`, tested `176` variants from `reports/trading-strategy-lab/deriv_watch_short_deduped_20260607T1055Z.json` and produced `0` passed rows. Stale catalog signal fields must not be treated as tradable. Do not convert duplicate, stale, thin-evidence, retune-required, broker-blocked, missing-positive, or gate-blocked backtest signals into broker trades.
   - Diagnostic demo seeding is separate from proof execution. `reports/trading-strategy-lab/deriv_recent_variant_lab_20260607T114411Z.json` produced `16` current-signal BOOM300N/CRASH300N research variants; the bounded virtual diagnostic campaign `reports/trading-strategy-lab/deriv_demo_campaign_verified_demo-20260607T114923Z_20260607T114938Z.json` verified `2` CRASH300N trades for `+$0.01`, failed gates, and did not promote anything. `reports/trading-strategy-lab/deriv_recent_variant_lab_20260607T115329Z.json` produced `2` current-signal 1HZ10V research variants; the bounded virtual diagnostic campaign `reports/trading-strategy-lab/deriv_demo_campaign_verified_demo-20260607T115608Z_20260607T115630Z.json` verified `1` 1HZ10V trade for `-$0.13`, failed gates, and did not promote anything. `reports/trading-strategy-lab/deriv_recent_variant_lab_20260607T121310Z.json` produced `12` current-signal BOOM300N research variants; the bounded virtual diagnostic campaign `reports/trading-strategy-lab/deriv_demo_campaign_verified_demo-20260607T121535Z_20260607T121547Z.json` verified `1` BOOM300N trade for `-$0.21`, failed gates, and changed the related BOOM300N diagnostic groups to retune-required. The deduped BOOM300N short retune input `reports/trading-strategy-lab/deriv_boom300n_short_deduped_20260607T1249Z.json` reduced the active family to `9` diverse rows; the fast no-trade retune `reports/trading-strategy-lab/deriv_recent_variant_lab_20260607T124526Z.json` tested `18` M1 variants and produced `0` passed rows, so BOOM300N short remains retune-required. The deduped BOOM600 short retune input `reports/trading-strategy-lab/deriv_boom600_short_deduped_20260607T1252Z.json` reduced that family to `12` diverse rows; `reports/trading-strategy-lab/deriv_recent_variant_lab_20260607T125352Z.json` tested `48` variants and produced `2` passed M1 spike-fade rows, but the temporary passed catalog `reports/trading-strategy-lab/deriv_boom600_passed_catalog_20260607T125352Z.json` lost its live signal across seven exact probes through `reports/trading-strategy-lab/deriv_variant_catalog_candle_probe_20260607T125825Z.json`, so no diagnostic demo trade was placed. The broker-positive watch input `reports/trading-strategy-lab/deriv_watch_positive_short_deduped_20260607T1306Z.json` reduced `1HZ25V`/`1HZ90V` short to `11` diverse rows; `reports/trading-strategy-lab/deriv_recent_variant_lab_20260607T130544Z.json` tested `44` current-signal variants and produced `0` passed rows, so the positive focus groups stay watch-only. Diagnostic rows may inform retunes and failure analysis only; they must not be enabled or labelled successful.
   - The broker-positive current retune at `reports/trading-strategy-lab/deriv_recent_variant_lab_20260607T044731Z.json` tested `204` strategies and produced `0` passed variants, so it must not be merged into the runtime catalog.
   - `scripts/deriv_catalog_candle_probe.py` publishes `clients/web/public/trading/deriv-signal-probe-evidence.json` when it probes the public runtime variant catalog. Web, desktop, and mobile must show this raw full-catalog signal evidence separately from `deriv-engine-status.json`; the latest public probe shows `5` raw signals, `1` diagnostic signal, `0` seedable diagnostic signals, `1` retune-required signal, `0` proof-ready signals, and `321/321` probe coverage after proof readiness rejected all three active groups. The proof-readiness UI captures under `clients/web/test-results/` must verify the 341-row workbench, `USD 8117.96`, `112` verified demo trades, `5` raw signals, `1` diagnostic signal, `0` seedable signals, `1` retune-required signal, `0` proof signals, `321/321` probe coverage, and `catalog: 321 runtime, 20 base`.
   - Verify campaign contract IDs against the broker profit table before promotion:
     ```bash
     python3 scripts/verify_deriv_demo_campaign.py \
       reports/trading-strategy-lab/deriv_demo_campaign_YYYYMMDDTHHMMSSZ.json
     ```
   - Apply only the broker-verified campaign evidence to the catalog with `--campaign-report`; do not hand-edit `demo_success`.
   - Multiple broker-verified reports may be applied when a strategy has cumulative evidence across bounded demo campaigns. Prefer the glob form for long-running loops so the command does not grow with every cycle:
     ```bash
     python3 scripts/promote_deriv_strategy_catalog.py \
       --campaign-report-glob 'reports/trading-strategy-lab/deriv_demo_campaign_verified_*.json'
     ```
   - `demo_success` requires a campaign report with `broker_verification.status == "verified"` plus the 10%/80%/<30% gates.
   - A strategy can be marked `demoRejected: true` only after broker-verified failed demo evidence reaches the configured rejection sample threshold. Positive rows with `>= 80%` demo win rate and positive P&L stay in bounded evidence collection even if they have not yet reached the 10% profit target. Rejection means “paused for this promotion loop until retuned/reset,” not “mathematically impossible forever.”
   - Use `--stake-mode target_gap` only on the Deriv virtual account when collecting proof-capable demo evidence. It sizes each new demo contract toward the remaining 10% strategy profit gap while obeying `--min-stake`, `--max-stake`, `--max-stake-pct`, `--target-trades-to-pass`, loss stops, and preflight checks. Keep fixed `$1` stakes for smoke tests; they can verify broker plumbing, but they cannot realistically prove the 10% account-return gate.
   - When target-gap sizing has recently lost money, run proof mode with `--prefer-broker-positive --require-broker-positive-source --require-broker-positive-base --min-broker-positive-trades 2 --min-broker-positive-pnl 5 --no-prefer-untested` before allowing another proof trade. This prevents a stale or tiny broker win from causing repeated trades in unproven sibling variants.
   - After every verified campaign application, write a promotion status report:
     ```bash
     python3 scripts/deriv_promotion_status_report.py
     ```
   - The status report must show `enabled_non_success: 0` and `unverified_success: 0` before desktop, mobile, web, or agents can treat the catalog as executable.
   - Keep portfolio flat or explicitly report open contracts before ending a run.
   - Never claim “profitable” or “successful” from a backtest alone.

5. **UI/MCP integration**
   - `/api/trading/strategies` must return the runtime catalog plus merged plugin/variant packs when present.
   - Web/desktop/mobile should display catalog records, filters, status, logs, and adapter mapping state.
   - Web/desktop/mobile must separate `demo_success`, `demo_rejected`, broker-verified `demo_gate_failed`, source-family `source_cooldown`, `demo_testing`, and `backtest_passed` instead of using a generic “passed” label for all rows.
   - Web/desktop/mobile must also distinguish base templates from runtime/plugin variants. The current UI intentionally shows the merged 341-row active catalog as 20 base templates plus 321 runtime variants, not as 341 proven strategies.
   - Web/desktop/mobile must surface the Deriv engine status from `clients/web/public/trading/deriv-engine-status.json` or `/api/trading/deriv/engine-status`, including `scanning`, selected count, stale/interrupted/completed state, latest skip reasons, exact controller eligible counts, exact `eligible_strategy_ids`, and probe OK/error counts for controller-filtered lists.
   - Reconcile and analysis runs publish static fallback files at `clients/web/public/trading/deriv-balance-evidence.json`, `deriv-history-evidence.json`, `deriv-log-evidence.json`, and `deriv-failure-analysis.json`. Use daemon endpoints as primary and these files only as read-only UI fallback; never write API keys or tokens into them.
   - Web/desktop/mobile must surface broker failure analysis from `/api/trading/deriv/failure-analysis` or `clients/web/public/trading/deriv-failure-analysis.json`, including verified trade count, net P&L, focus groups, and cooled symbol-side groups, so retuning decisions are visible alongside the strategy workbench.
   - Web/desktop/mobile must split proof-readiness diagnostics into seedable diagnostics and retune-required groups. A group with verified negative diagnostic evidence must show `retune_exit_filters_before_demo_seed` or equivalent retune action and cannot look ready for another demo seed.
   - Mobile must expose the same broker evidence feed as desktop, plus daemon risk rails and kill-switch control through `/api/trading/rails` and `/api/trading/killswitch`.
   - Agents should treat `executable: false` as “research candidate only” until an adapter maps the strategy to a broker/order type.

6. **Iteration**
   - Start from the highest return/profit-factor passed strategies.
   - If demo gates fail, tune thresholds and rerun, then promote only the new passed catalog/report state.
   - Keep useful UI improvements flowing while demo campaigns run: search, filters, trade detail levels, logs, strategy mapping state, manual/auto controls, and equity/drawdown views.
