# Project Memory — USPS Address Validator

Anchor file. Current step lives in `ProjectProgress.md`; the reasoning behind decisions lives in `docs/0-project/ChangeLog.md`.

## Where things live
- Raw requirements: `requirements/USPS Address Validation for Business Central — PTE spec.md`
- Progress and usage: `ProjectProgress.md`
- Framework files: `ocpfFramework/` (edition: Full, runbook 5.2.0.0, placed as `CLAUDE.md`)

## Decisions recorded at PRE-01
- Working language: English (AJ, 2026-10-10)
- Notifications: Claude app push + sound; Remote Control on for every session (AJ, 2026-10-10). Sound test heard; Claude app push untested until Remote Control connects.
- Extension name: USPS Address Validator (AJ, 2026-10-10)
- Publisher: OnlyBCFans (AJ, 2026-10-10)
- Dashboard explained and understood (AJ, 2026-10-10). AJ wants the dashboard tracked in git; since runbook 5.3.0.0 it is `ProjectDashboard.html` in the project root, tracked.
- App icon: `src/logo/AppLogo.png`, from `images/usps-address-validation-icon-512.png` (AJ, 2026-10-10)

## Model and effort assignment (PRE-01, AJ, 2026-10-10)
| Role | Model | Harness identifier | Effort | Materialized in |
|---|---|---|---|---|
| Main | Sonnet 5.5 | `claude-sonnet-5-5` (session) | Medium | this session |
| Light | Haiku 5.5 | `haiku` | Medium | `.claude/agents/ocpf-light.md` |
| Reasoning | Opus 5.5 | `opus` | High | `.claude/agents/ocpf-reasoning.md` |
| Generator | Sonnet 5.5 (Main) | `sonnet` | Medium (Main) | `.claude/agents/ocpf-generator.md` |

First-session note: the session that creates `.claude/agents/` may not load the new definitions until the next session; until then delegate to the plugin's `ocpf-bc:*` agents with the `model` parameter on every call.

## Step 01 decisions (AJ, 2026-10-10)
Target SaaS PTE; country US; localization US; BC 28 / runtime 17.0; prefix `obcfusps`; namespace `OnlyBCFans.USPSAddress`; App Code `USPS`; ID range 60093-60142; wizard Yes (credentials only); cues No; departments No; Copilot No; framework files ignored (dashboard.html tracked); en-US source, US wording, no translation files. Full sheet: `docs/1-define/ProjectParameters.md`.

## Step 02 decisions (AJ, 2026-10-10)
USPS shipping/mailing confirmed (OQ-1). Retention custom 2 years. Permission sets USE + ADMIN only (ADMIN includes USE). Credentials via wizard and setup card. Tests use a replaceable HTTP layer. Address Validated: resets on edit of the five address fields, resets on Not Found, unchanged on Error/Ignore/blocked Accept; Confirmed sets it only for users who can modify customers. Contact sync and stale Tax Area accepted. Acceptance tests 15-21 added.

## Sign-offs
- PRE-01 + PRE-02 combined (Approvers = one person): AJ approved `docs/1-define/ProblemStatement.md` and the expanded entity list as Functional Consultant and Technical Lead, 2026-10-10.

## Framework
Runbook 5.4.2.0 (updated from 5.4.1.0 on 2026-10-10, ChangeLog Issues UPD-1 to UPD-4).

## Live documents
- **Framework:** runbook 5.8.0.0, plugin 5.8.0, Operations Guide 5.8.0.0, Standards Guide v1.12.1.0, updated 2026-10-17 by AJ Ansari (ChangeLog 12-3); the 5.7.3.0 copies are in `ocpfFramework/state/previous/`. Sub-agents now include `ocpf-reviewer` (Sonnet 5.5, medium, the Main assignment).
- `docs/4-prove/ReleaseTestResults.md` and `docs/0-project/TestingFeedback.md` (TF-01): the 0.0.0.7 release round, 2026-10-17, no findings. **Last installed version:** `1.0.0.0` in `sandbox` (smoke-tested, AJ Ansari, 2026-10-17); production: none at close — AJ deploys `Google_Address_Validator_1.0.0.0.app` through the Admin Center. Project closed at Step 12 (ChangeLog 12-2); `ProjectProgress.md` has every row Completed.
- `README.md` (repository root): public landing page, added by AJ Ansari 2026-10-17 (ChangeLog 11-4). Update its status note and version when a release candidate is built.
- `LICENSE` (repository root): PolyForm Shield License 1.0.0, Required Notice "Copyright 2026 AnsariCo, Inc. dba OnlyBCFans", added by AJ Ansari 2026-10-17 (ChangeLog 11-3); summarized in `docs/4-prove/Documentation.md` §9 and `docs/4-prove/Deployment.md` §1.
- `docs/2-design/FRD.md` v1.0, signed off by AJ Ansari as Dev Manager, 2026-10-10.

- `docs/2-design/TDD.md` v1.0 and `SanityCheck.md`, signed off by AJ Ansari (Technical Lead) 2026-10-10; FRD v1.2; `HumanEffortEstimate.md` (65.4 h), `AiEffortEstimate.md` (about $16, ±30 %), `docs/1-define/ObjectRegister.md` (all Planned).

## Step 03 decisions (AJ, 2026-10-10)
Enums not extensible; StandardDialog kept (OK = Accept, Cancel = Ignore); test app in sibling folder `USPSAddressValidator.Tests` with its own git repo; retention policy created disabled; Address Validated unchanged on Not Found for users who cannot modify customers; test 12 manual; timeout 1-60 s.

## Step 04 decisions (AJ, 2026-10-10)
Failed customer write is logged as Error; caller check on SetTransport and credential setters (test app GUID fixed at Step 05); Log list keeps ADMIN-only delete; customer rename may rewrite log rows; ID split main 60093-60122 + 60134-60142, test app 60123-60133; codeunit 60118 added.

## Step 05 decisions (AJ, 2026-10-10)
Batch mode: all batches in parallel (project-local ocpf-generator per batch on the Main model). Test app: sibling folder with its own git repo, GUID ebe1c8ca-a413-4f2b-9de7-37d8c1ae4d5a. Fast mode not offered (Main model is Sonnet).

## Step 07 state (2026-10-10)
Builds: main app 0.0.0.2 clean (0.0.0.1 kept, 1 non-code warning); test app 0.0.0.1 clean, built against main 0.0.0.2. The AL MCP `al_publish` / `al_auth_login` fail in this session with a null-reference error, so AJ publishes from VS Code (AL: Publish without debugging, environment `sandbox`) and reports. Last installed version in any tenant: none yet. Next: sandbox round 1 (24 automated tests in a TEST company via the AL Test Tool, plus manual checks), then diagnoses, then the Step 07 close.

## Provider change under discussion (2026-10-11)
USPS Addresses API moved to a license plus paid usage (from 2026-08-01) and AJ cannot complete onboarding. AJ's volume: under 1,000 checks a month; "matched" is enough, USPS-grade delivery data is nice to have. Options researched (Google Address Validation: 5,000 free/month on Pro; Smarty: 42-day trial then about $552/yr; Geocodio: 2,500 free/day, no DPV; USPS: about $10/month, unconfirmed). AJ chose to spike Google first. A provider switch changes the signed-off FRD/TDD and the tests, so it will come back as a decision. Step 07's sandbox round is on hold meanwhile.

## Open decisions
- Tasks carried from the Sanity Check (awaiting: AJ): F11 check the USPS OpenAPI specs (is `state` mandatory?) before Step 06; F23 retention/deployment notes and 72-hour incident checklist into Deployment.md; F26 note bold/Esc as manual in the test script; F28 State visibility for blank country in a US sandbox.
- Provider decision: Google vs Smarty vs Geocodio vs USPS, after the Google spike (awaiting: AJ).
- FRD follow-ups before go-live (awaiting: AJ): OQ-9 read real USPS quota; OQ-18 ask USPS about the 'operational test' clause; OQ-19 check US captions State/ZIP Code in a US sandbox; OQ-20 check Allow HttpClient Requests default in production.

## Step 08 decisions (AJ, 2026-10-16)
G2/G3/G4 code fixes fold into CR-1 (docs/0-project/Roadmap.md). G6/G8 Spec stale, applied at Step 10. Step 07 gate waived (no sandbox test yet; last installed version: none). Framework now 5.7.3.0.

## Step 09–10 state (2026-10-16)
Main app 0.0.0.4 and test app 0.0.0.3 built clean; neither installed (waivers 07, 09). As-built docs: `docs/4-prove/PostDevTDD.md` and FRD 1.3 (pre-Step-10 copy `docs/2-design/FRD.preStep10.md`). Obligations before Step 12: Roadmap R-09-1, R-09-2, R-08-4..6. CR-1 (Google) still unsigned.

## Google build state (2026-10-16)
App renamed Google Address Validator (prefix obcfgav, namespace OnlyBCFans.GoogleAddress); main 0.0.0.7 / tests 0.0.0.7 built 0/0, never installed (waivers 07, 09, 09-2). As-built docs: `docs/4-prove/PostDevTDD.md`, `docs/2-design/FRD.md` 2.0; USPS-build copies: `PostDevTDD.USPSbuild-0.0.0.4.md`, `FRD.USPSbuild-1.3.md`, `GapAnalysis`/`CodeReview.USPSbuild-0.0.0.4.md`. Step 11 documents (Documentation, UserGuide, Deployment, test scripts, Acknowledgements) still describe the USPS build and are rewritten at Step 11. Obligations before Step 12: Roadmap R-08-4..6, R-09-1, R-09-2, R-11-1, R-12-1. Open (awaiting: AJ): Google privacy link, app Terms of Use/Privacy Policy (OQ-29/31), live spike (OQ-33).

## Standing preferences
| Preference | Date | Given by |
|---|---|---|
| Work in English | 2026-10-10 | AJ |
| Notify by sound and Claude app push | 2026-10-10 | AJ |
| Track the dashboard page in git (`ProjectDashboard.html`, project root) | 2026-10-10 | AJ |

## Scope change SC-1 — master-data tables beyond Customer (AJ Ansari, 2026-10-17)
Raw input: `requirements/scope-additions-2026-10-17-more-master-data-requirements.md`. 15 more tables (list in ChangeLog SC-1). Decided: Union out; ID range +50 (60143–60192, `app.json` and Object Register not yet updated); version 1.1.0.0; batches one at a time (batch 1 = engine rewire, Customer unchanged). Design status: FRD/TDD amendments being drafted, not yet signed off (awaiting: AJ Ansari). Released 1.0.0.0 stays the baseline; do not change `app.json` version until the first 1.1 build.

SC-1 update (2026-10-17): decisions OQ-34..46 recorded in ChangeLog SC-1a. FRD Appendix C and TDD §15 are drafts awaiting sign-off (awaiting: AJ Ansari). Still owed before Step 05: Human and AI Effort Estimate addenda, Object Register delta, ProjectParameters §1.2 range, `app.json` idRanges.
SC-1 sign-off (2026-10-17): AJ Ansari signed off FRD Appendix C and TDD §15 (ChangeLog SC-1b). Sanity Check running; the batch-plan approval follows it.
SC-1 Sanity Check resolved (2026-10-17, ChangeLog SC-1c): 0 blocking open. Re-blocked IDs: engine 60134–60139, Write Guard 60120, sources 60143–60192. Owed before the Build Plan: Human and AI Effort Estimate addenda (awaiting: AJ Ansari for the Step 05 plan approval). Standing decision: explicit upgrade tags, not SetAllUpgradeTags() (AJ Ansari, 2026-10-17).
SC-1 design step closed (2026-10-17, ChangeLog SC-1d). Next: Step 05 Build Plan for the four batches; needs AJ Ansari's plan approval before any code.
SC-1 Step 05 closed (2026-10-18, ChangeLog SC-1e): Build Plan approved by AJ Ansari; batch mode one at a time, OQ-41 stop after B1; fast mode not offered. Next: Step 06, batch B1.
SC-1 B1 built (2026-10-18, ChangeLog B1-1): main 1.1.0.1 compiled 0/0, not installed. Checkpoint OQ-41 pending: AJ Ansari installs 1.1.0.1 in the sandbox over 1.0.0.0 and runs the 61 existing tests (test app 0.0.0.7); B2 starts only after the result is reported. Last installed version: 1.0.0.0 (sandbox).
SC-1 all batches built (2026-10-18, ChangeLog B2-1/B3-1/B4-1): main 1.1.0.2 and test app 0.0.0.9 compile 0/0; nothing installed or run yet; AJ Ansari waived the OQ-41 stop after B1 and asked not to be interrupted. Reviews running (reviewer Sonnet 5.5, reasoning Opus 5.5). Last installed version still 1.0.0.0 in sandbox.
SC-1 reviews resolved (2026-10-18, ChangeLog SC-1f): main 1.1.0.3 and test app 0.0.0.11 compile 0/0; nothing installed or run. Open for AJ Ansari: confirm D3 (Contact-source linked update is part of the write); install per SandboxInstall.md; run the 121 tests; manual tests 24, 30, 34, 37, 42.
SC-1 Steps 08-11 done (2026-10-18, ChangeLog SC-1i). Step 12 open: AJ Ansari installs main 1.1.0.5 + test app 0.0.0.15 in a TEST-company sandbox, runs 131 automated tests and TC-30..TC-42, reviews PostDevTDD/FRD 2.1/Step 11 docs. Decisions awaiting AJ Ansari's confirmation: D3 (OQ-50), log read restriction (OQ-51), country rule (OQ-52), release candidate = 1.1.0.5 as is. Last installed version: 1.0.0.0 in sandbox. Next build if a fix is needed: 1.1.0.6.
SC-1j (2026-10-18): friendlier Not Found message; main 1.1.0.7 / test app 0.0.0.16 are now the candidate (replaces 1.1.0.5). AJ Ansari reported 'everything works' with a screenshot of the message in a running sandbox but did not state the installed version or whether the 131 tests passed.
SC-2 (2026-10-18, ChangeLog SC-2/SC-2a): Google names and Record No. on the log; candidate is now main 1.1.0.10 / test app 0.0.0.18. Awaiting AJ Ansari: GF-04 (Record No. is a snapshot), plus the earlier D3, log read restriction, country rule, release candidate. Last installed version still unrecorded beyond 1.0.0.0.
SC-2b (2026-10-18): AJ Ansari confirmed GF-04 (Record No. is a snapshot). Still awaiting his confirmation: D3 (Contact-source linked update, OQ-50), the log read restriction (OQ-51), the country rule (OQ-52), and the release candidate = the last build (now 1.1.0.10).
SC-2c: Validate Address icon is Map; candidate build is main 1.1.0.11 / test app 0.0.0.18.
SC-3 (2026-10-18): AJ Ansari confirmed OQ-50 (keep, standard BC behaviour), OQ-51 and OQ-52, and added: fill the US country code on validation (main 1.1.0.12 / test app 0.0.0.19). Release candidate = last build. STANDING INSTRUCTION: when AJ Ansari is ready he deletes old package versions by hand and then asks for the git history (local and remote) to be squashed; do not squash or force-push before he asks, and confirm the remote and branch with him first. Canada/other countries: not validated (US only); Google supports ~40 regions.
SC-4 (2026-10-18, ChangeLog SC-4): 40 countries, all enabled; supported-country table and page; country filled from the result; main 1.2.0.1 / test app 0.0.0.21. Awaiting AJ Ansari: the 1.2.0.x version bump, the changed 1.0.0.0 message texts, BR/MX/IN/JP enabled without a live probe. Not validated by any live Google probe outside the US so far.
SC-4b: wizard and Setup page updated for countries; candidate build main 1.2.0.2 / test app 0.0.0.21.
SC-5 (2026-10-18, ChangeLog SC-5): blank country is worked out from the address (Blank Country Handling = Let Google decide, default); candidate build main 1.2.0.3 / test app 0.0.0.22 (153 tests). AJ Ansari tested a Danish address in a US company: still to be retested with 1.2.0.3.
SC-5a: retry without region added; decisions pending AJ Ansari's confirmation: existing tenants switch to Let Google decide with no upgrade step; retry costs an extra request only on a failed guess. Candidate build main 1.2.0.4 / test app 0.0.0.23 (155 tests).

Step 12 for SC-1..SC-5 closed 2026-10-19 (ChangeLog 12-3): manual tests all passed on 1.2.0.4 (AJ Ansari; version assumed, confirm). Automated tests not run (AL MCP sign-in broken). Production deploy of `Google_Address_Validator_1.2.0.4.app` is AJ's. Standing: AJ deletes old packages by hand, then tells me to squash local and remote git history.

Framework updated to 5.8.2.0 on 2026-10-19 (ChangeLog FW-3). Pending: AJ Ansari's decision on renumbering to 92800+ and which package ships (1.2.0.4 or 1.2.0.5).

1.3.0.0 (2026-10-19, ChangeLog SC-6): renumbered per object type to 92800–92829 (test app 92830–92849); AJ Ansari chose it as the shipping package; needs a sandbox install (Force Sync) and a repeat of the manual cases. Last installed and tested: 1.2.0.4 (sandbox).

1.3.0.1 (2026-10-19, ChangeLog SC-7): default country asked in the wizard (no US preset), API key kept on a repeat wizard run, brief and description in app.json. Needs the sandbox retest (TC-02 changed).

Help page lives in docs/ (ChangeLog SC-10); GitHub Pages must be set to main / /docs; release package is now 1.3.0.3.

Framework updated 5.8.2.0 -> 5.9.5.0 (2026-10-22, AJ Ansari accepted; ChangeLog FW-5.9.5). Old copies in ocpfFramework/state/previous/.
