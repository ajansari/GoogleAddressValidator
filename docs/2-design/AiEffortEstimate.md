# AI Effort Estimate — USPS Address Validator

**Date:** 2026-10-10 · **Estimated by:** Main role, Sonnet 5.5 (Medium) · **Basis:** `docs/2-design/TDD.md` v0.2 · **AI tool:** Claude Code · **Reviewed by:** AJ Ansari (pending, with the TDD at Step 04)

> **What this is.** The tokens, cost, and elapsed time the framework expects to spend finishing this
> project with the recorded models, for reading next to the Human Effort Estimate
> (`docs/2-design/HumanEffortEstimate.md`: 65.4 senior-developer hours) before the build starts, and against the measured usage
> table in `ProjectProgress.md` after it. Every number in §2 is a **baseline placeholder until
> calibrated** (§6); the margin in §5 says how far to trust the totals.

## 1. Inputs
| Input | Value | Source |
|---|---|---|
| Objects by type and complexity | 22 objects with IDs plus 1 interface: 3 tables (2 simple, 1 medium) + 1 table extension (medium), 5 pages (3 medium, 2 simple), 6 main-app codeunits (2 complex, 3 medium-or-simple helpers) + 5 test-app codeunits, 2 enums, 2 permission sets | TDD §12 |
| Batches | 6 (B1–B5 main app, B6 test app) | TDD §3 |
| Languages | en-US only, no translation files | `docs/1-define/ProjectParameters.md` §1.9 |
| Main model and effort | Sonnet 5.5, Medium | `ocpfFramework/framework.json`, ProjectMemory §1.7 |
| Light model and effort | Haiku 5.5, Medium | same |
| Reasoning model and effort | Opus 5.5, High | same |
| Generator (parallel batches) | inherits Main (Sonnet 5.5, Medium) | Ops § Roles → Parallel batches |
| AI tool | Claude Code | intake |
| Approvals the plan will raise | 20 (Rule 6 gates + Rule 6a decisions + step-close boxes, Steps 04–12) | counted in §4 |

## 2. Token estimate per step × model × token type
Built from the template's baselines (generation output per object × type multiplier, reasoning-role document 25k in / 8k out, a compile-and-fix round per batch) plus a **fixed per-step carry** (runbook core ≈ 25k tokens plus the step file ≈ 6k, re-read each turn at cache-read rate). The cache write and cache read columns are not template baselines: they come from this project's own first measurements (Steps 02 and 03: a Reasoning-role document cost roughly 130–190k cache-write and 2–4.7M cache-read tokens) and are **uncalibrated** — they are the largest source of error. Baselines used (placeholders until calibrated): generation 80,250 output tokens for the 22 objects (simple 1,500 · medium 3,000 · complex 6,000; codeunits ×1.5); compile-and-fix: 3 rounds; reasoning documents: Sanity Check, Gap-Fit, Code Review.

Tokens in thousands (k). Claude Code: the last column is `—`.
| Step | Model | Input | Output | Cache write | Cache read | Basis (objects × baseline, documents, rounds) | AI credits (Copilot) |
|---|---|---|---|---|---|---|---|
| 04 | Opus 5.5 (Reasoning) | 25k | 8k | 130k | 2,000k | Sanity Check: 1 reasoning document | — |
| 04 | Sonnet 5.5 (Main) | 10k | 12k | 50k | 1,500k | resolve findings, update TDD/FRD, ChangeLog | — |
| 05 | Sonnet 5.5 (Main) | 15k | 20k | 80k | 2,500k | Build Plan, scaffold, analyzer settings, BCQuality and patterns fetch | — |
| 06 | Sonnet 5.5 (Generator) | 40k | 80k | 400k | 4,000k | 80,250 output tokens over 22 objects in 6 batches (baseline per object × type multiplier) | — |
| 06 | Haiku 5.5 (Light) | 330k | 22k | 150k | 1,500k | pre-flight of 22 objects, input-heavy | — |
| 06 | Sonnet 5.5 (Main) | 20k | 25k | 100k | 3,500k | integration, Object Register, ChangeLog, one commit per batch | — |
| 07 | Sonnet 5.5 (Main) | 90k | 30k | 150k | 6,000k | 3 compile-and-fix rounds | — |
| 07 | Opus 5.5 (Reasoning) | 50k | 16k | 250k | 4,000k | 2 root-cause diagnosis rounds | — |
| 08 | Opus 5.5 (Reasoning) | 25k | 8k | 130k | 2,000k | Gap-Fit: 1 reasoning document | — |
| 08 | Sonnet 5.5 (Main) | 10k | 10k | 50k | 1,500k | record classification, gap-fill | — |
| 09 | Opus 5.5 (Reasoning) | 30k | 12k | 150k | 3,000k | Code Review and scorecard | — |
| 09 | Sonnet 5.5 (Main) | 15k | 15k | 80k | 2,500k | apply fixes, recompile round | — |
| 10 | Sonnet 5.5 (Main) | 10k | 30k | 60k | 2,000k | PostDevTDD and FRD update | — |
| 11 | Sonnet 5.5 (Main) | 15k | 40k | 100k | 3,000k | five mandatory documents, release candidate build | — |
| 12 | Sonnet 5.5 (Main) | 10k | 10k | 60k | 2,000k | release test coordination, triage | — |
| **Total** | | **695k** | **338k** | **1,940k** | **41,000k** | | — |

## 3. Cost
At the prices in `ocpfFramework/state/pricing.json` (fetched from the publisher, 2026-10-10).
| Model | Input (USD) | Output (USD) | Cache write (USD) | Cache read (USD) | Total (USD) |
|---|---|---|---|---|---|
| Sonnet 5.5 (Main) | 0.39 | 1.92 | 1.82 | 2.45 | 6.58 |
| Sonnet 5.5 (Generator) | 0.08 | 0.80 | 1.00 | 0.40 | 2.28 |
| Haiku 5.5 (Light) | 0.03 | 0.01 | 0.02 | 0.01 | 0.08 |
| Opus 5.5 (Reasoning) | 0.52 | 0.88 | 3.30 | 2.20 | 6.90 |
| **Total** | | | | | **15.84** |

*Prices: https://platform.claude.com/docs/en/about-claude/pricing, read 2026-10-10.* Haiku 5.5 is priced at its up-to-100,000-token-prompt rates. Range at the margin in §5: **$11.09 – $20.60**.

For scale, measured so far (`ProjectProgress.md`): PRE-01 to Step 02 about $5.1, Step 03 $7.51 (Opus 5.5 $5.75, Sonnet 5.5 $1.77), of which roughly $3 was a TDD draft lost when a session ended and re-run. That TDD draft, the largest document of the project (72 tool calls, about 16.7M cache-read tokens), cost well above the cache-read figure assumed here for a Reasoning-role document (2–4M). Steps 04, 08 and 09 read the same TDD and FRD, so expect each to land nearer the high end of this estimate, perhaps $1–3 more per document than the Reasoning rows show.

## 4. Wall-clock estimate from BUILD on
Covers Full Step 05 onward (Step 04 shown too, since it follows this step). Per step: generation time (output tokens ÷ the default **50 tokens/s**) + sub-agent waits (about 15–20 min per reasoning document, 40 min for the generators and pre-flight at Step 06, from the 8–24 min measured on the FRD and TDD drafts) + compile-and-test rounds (**3 rounds × 20 min agent time + 30 min human sandbox test each**, Step 07) + **approvals × 30 minutes** (20 counted in §1).
| Step | Generation | Sub-agent waits | Compile-and-test rounds | Approvals × 30 min | Step total |
|---|---|---|---|---|---|
| 04 | 7 min | 15 min | 0 min | 2 × 30 min | 82 min |
| 05 | 7 min | 0 min | 0 min | 3 × 30 min | 97 min |
| 06 | 42 min | 40 min | 0 min | 1 × 30 min | 112 min |
| 07 | 15 min | 20 min | 150 min | 4 × 30 min | 305 min |
| 08 | 6 min | 15 min | 0 min | 2 × 30 min | 81 min |
| 09 | 9 min | 20 min | 0 min | 2 × 30 min | 89 min |
| 10 | 10 min | 0 min | 0 min | 1 × 30 min | 40 min |
| 11 | 13 min | 0 min | 0 min | 3 × 30 min | 103 min |
| 12 | 3 min | 0 min | 0 min | 2 × 30 min | 63 min |
| **Total** | 112 min | 110 min | 150 min | 20 approvals | **972 min (16.2 h)** |

This assumes every approval is answered within 30 minutes. Slower approvals extend the elapsed time by exactly the extra wait.

## 5. Margin
The Step 04 amendments (one more codeunit, seven more automated tests) add roughly 5 % to the generation and test rows of Steps 06 and 07; this is inside the margin below and the tables are not re-cut.
**±30 %** applies until calibrated; the framework's target is **±10 %**, reached when three or more measured projects exist in the calibration store. **This estimate carries:** ±30 % — uncalibrated, 0 projects in the store. The cache columns have no calibration behind them at all, so treat the cost as an order of magnitude and read the first measured steps (05, 06) against it.

## 6. Calibration store
`~/.ocpf/calibration/<project>-<date>.json`, one file per finished project, written by the `usage` skill at project close (Full Step 12): per step, per model tokens by type, elapsed, turns, decisions, plus the object counts by type. The estimator reads every file there and derives per-object and per-step averages when present.
| Files read | Projects | Averages derived (per-object output, per-step carry, throughput) | Used in §2 / §4? |
|---|---|---|---|
| none (`~/.ocpf/calibration/` is empty) | — | none — §2 baselines used | No — baselines stood in |

## Before calling this done
- [x] Every step from here to the last one has a row in §2 per model that will run in it.
- [x] The approvals count is listed in §1 and carried into §4.
- [x] §5 names which margin applies (±30 % uncalibrated or ±10 % calibrated) and why.
- [x] §4 carries the slower-approvals sentence unchanged.
- [x] §6 says whether calibration data was found and used, or the baselines stood in.

---

## SC-1 addendum (version 1.1.0.0) — 2026-10-17

**Estimated by:** Main role, Sonnet 5.5 (Medium) · **Basis:** `docs/2-design/TDD.md` §15 (signed off 2026-10-17, amended by the Sanity Check) · **Calibration read:** one measured project, the 1.0.0.0 build (`~/.ocpf/calibration/Google-Address-Validator-2026-10-17.json`: 27 objects, $90.77 in total, measured Steps 05–12 plus 07a ≈ $65). **Margin: ±30 %** (the template's margin holds until three measured projects exist).

### Inputs
| Input | Value |
|---|---|
| New objects | 37 in the main app (1 enum, 1 Write Guard, 5 helper, upgrade and sync codeunits, 30 table and page extensions), 2 test codeunits |
| Changed objects | 11 (60096, 60099, 60100, 60101, 60109, 60110, 60111, 60112, 60113, 60118, 60116) plus `app.json` and the test library |
| Batches | 4 (B1 engine, B2 sales and purchasing, B3 company/org and people, B4 sync, Customer reset, tests), one at a time |
| Complexity | Two batches are logic-heavy (B1 rewires the validation engine behind the 61 existing tests; B4 is five standard-BC integration subscribers plus a linked-record update). B2 and B3 are 30 near-identical table/page extensions |
| Models | Main Sonnet 5.5 (Medium), Generator Sonnet 5.5, Light Haiku 5.5, Reasoning Opus 5.5 (High) — as recorded in §1.7 |

### Estimate for Steps 05–12 (measured 1.0.0.0 cost as the base)
| Step group | 1.0.0.0 measured | SC-1 factor and why | SC-1 estimate (USD) |
|---|---|---|---|
| 05 Plan | 0.77 | ×1.3: four batches, a field map and 37 fixed IDs | 1.0 |
| 06 Generation | 6.0 | ×1.3: 30 repetitive extensions are cheap; B1 and B4 are the costly batches | 7.8 |
| 07 Compile, pre-review, iterate | 17.0 (included 138 h of waiting and a provider change) | ×1.0: OQ-41 adds a checkpoint round after B1 | 17 |
| 08 Gap-Fit | 6.2 | ×1.2 | 7.4 |
| 09 Code Review | 14.9 | ×1.0: most files are one repeated template, reviewed once | 15 |
| 10 Design documents | 2.6 | ×1.2 | 3.1 |
| 11 Documentation | 5.4 | ×1.3: 17 more cards in the User Guide, test script and reference | 7.0 |
| 12 Release test | 7.2 | ×1.0 | 7.2 |
| **Total Steps 05–12** | **≈ 60** | | **≈ 65 (range 45–85 at ±30 %)** |

By model, the split follows the measured 1.0.0.0 project: Sonnet 5.5 (Main and Generator) about 65 %, Opus 5.5 (Reasoning) about 33 %, Haiku 5.5 (Light) under 1 %.

**Design work already done in this cycle (the SC-1 design step):** two Opus 5.5 reasoning runs (amendment draft; Sanity Check), a third for the Human Effort Estimate addendum, and the main role's integration. Their cost is not estimated here: it is measured by the usage script at the close of the SC-1 design step and appears in `ProjectProgress.md`.

### Wall-clock
- **Agent working time:** about 6–8 hours across Steps 05–12 (generation and compiles are minutes; the reasoning-role reviews are 20–30 minutes each).
- **Human approvals:** about 20 gates (plan approval, the OQ-41 checkpoint install and test round, pre-review decisions, test-round diagnoses, the step-close boxes, release test). At the template's **30 minutes each, that is about 10 hours.**
- **Elapsed, if every answer comes within 30 minutes: about 16–18 hours.** Sandbox install and testing are the human's and dominate in practice: 1.0.0.0's Step 07 took 138 hours elapsed for the same reason.

### What would change this
- A failed `TransferFields` assumption (tests 32 and 34) or a US-localized page without an expected anchor (TDD 15.21) would add a fix round to B2/B3: +$3 to +$8.
- If the 61 existing tests fail after B1, the OQ-41 checkpoint becomes a diagnosis round with the Reasoning role: +$5.
