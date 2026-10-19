# Human Effort Estimate — USPS Address Validator

**Date:** 2026-10-10 · **Estimated by:** Reasoning role, Opus 5.5 · **Basis:** `docs/2-design/TDD.md` v0.2 (Full) · **Reviewed by:** AJ Ansari (pending)

> **What this is.** The billable hours an **experienced senior AL developer** (5+ years of Business
> Central extension work, fluent in AL, the AL tools, and the standards this project applies) would
> need to deliver the same scope by hand, working from the same requirements. It is an **estimate**
> for reading next to the measured AI cost in the usage table (`ProjectProgress.md`) and the AI
> estimate (`docs/2-design/AiEffortEstimate.md`), not a quote, not a timesheet, and not a claim
> about any particular developer. Every assumption is in §1 so the reader can change it.

## 1. Assumptions
| Assumption | Value used | Change it if |
|---|---|---|
| Developer profile | Senior AL developer, works alone, no ramp-up on BC | a team, or a developer new to BC |
| Working day | 8 billable hours | |
| Requirements | As complete as `docs/2-design/FRD.md`; no re-discovery | the human would also gather requirements |
| Testing | Manual sandbox testing by the developer, plus the separate AL test app (TDD §4.19), costed as the automated-tests share | a separate QA function |
| Meetings, reviews, sign-offs | Folded into the requirements and design rows (one approver, AJ Ansari) | several approvers |
| Baselines | §2's baselines (mid-point unless complexity says otherwise) | a rate card or history not yet in the calibration file |
| USPS access | TEM credentials available from day one; USPS behaves as documented | the developer must obtain credentials or reverse-engineer responses |
| Translations | None (US wording only, Parameters §1.9) | a language is added |
| Upgrade code | None (first version, TDD §8) | the app is already installed somewhere |

## 2. Baselines used
**Baselines:** framework default, `ocpfFramework/documentTemplates/HumanEffortBaselines.md` **v1, September 27, 2026**. No partner calibration file exists (`~/.ocpf/HumanEffortBaselines.md` is absent; `~/.ocpf/calibration/` is empty).
| Task | Unit | Baseline (h) |
|---|---|---|
| Requirements write-up (FRD-equivalent) | per 10 entities | 1.5 – 3 |
| Technical design (TDD-equivalent, incl. ID allocation) | per 10 objects | 2 – 4 |
| New table | each | 0.5 – 1.5 |
| Table extension | each | 0.25 – 0.75 |
| List or card page | each | 0.5 – 1.5 |
| Page extension | each | 0.25 – 0.75 |
| Codeunit — helpers, subscribers, simple validation | each | 0.5 – 2 |
| Codeunit — business logic (posting, no. series, complex validation) | each | 3 – 10 |
| Enum or enum extension | each | 0.15 |
| Permission set (VIEW + EDIT pair) | per pair | 0.25 – 0.5 |
| Event publisher or subscriber wiring | each | 0.25 – 0.75 |
| Assisted setup wizard, role-center cues, Departments placement | each feature | 2 – 4 |
| Compile, package, deploy troubleshooting | share of build hours | 5 – 10 % |
| Automated tests (only when in scope) | share of build hours | 20 – 30 % |
| Code review and fixes | share of build hours | 5 – 10 % |
| Documentation set | per project | 2 – 6 |
| Release testing support and fixes | per project | 1 – 4 |

## 3. Estimate by task
"Build hours" for the share rows = rows 3–14 = **29.6 h**.
| # | Task | Object(s) / scope | Complexity and why | Hours | Framework step |
|---|---|---|---|---|---|
| 1 | Requirements | 21 entity rows (FRD §6) → 2.1 units | Mid (2.25): spec existed; scope additions and 22 open questions | 4.7 | 02 |
| 2 | Technical design | 23 objects (22 IDs + 1 interface) → 2.3 units | High (4): external OAuth API, secret handling, test seam, shared ID range with a test app | 9.2 | 03 |
| 3 | New tables | 60095 Setup (0.5, simple), 60109 Log (1.0, 22 fields, two classifications), 60111 Address Buffer (0.5, temporary) | Low to mid, as stated | 2.0 | 06 |
| 4 | Table extension | 60116 Customer | High (0.75): field plus five validate triggers with reset logic | 0.75 | 06 |
| 5 | List or card pages | 60096 Setup card (1.5: masked credentials, Test Connection, singleton); 60110 Log list (0.5); 60112 Comparison dialog (1.5: grid, per-row bold style, notes, blocked state) | As stated | 3.5 | 06 |
| 6 | Page extension | 60117 Customer Card | Mid (0.5): field, two actions, promoted ref | 0.5 | 06 |
| 7 | Assisted setup wizard | 60097 | Low (2): two masked fields, three steps, no test step | 2.0 | 06 |
| 8 | Business-logic codeunit | 60113 Address Validation | Mid (6): preconditions, comparison, dialog, transaction and commit boundaries, concurrency check, flag rules | 6.0 | 06 |
| 9 | Business-logic codeunit | 60114 USPS API Client | High end of mid (8): OAuth token and cache, one-refresh retry, status table, tolerant JSON, secret-safe request body | 8.0 | 06 |
| 10 | Helper codeunits and interface | 60098 Credential Mgt. (1.5), 60115 Http Transport (1.0), 60099 Install (0.5), 60100 Setup Registration (1.5: retention plus assisted setup), interface obcfusps USPS Transport (0.5) | As stated | 5.0 | 06 |
| 11 | Enums | 60093, 60094 | Fixed baseline | 0.3 | 06 |
| 12 | Permission sets | 60101 USE, 60102 ADMIN (one pair) | High (0.5): indirect insert, ADMIN-only delete, per-batch grants | 0.5 | 06 |
| 13 | Event subscriber wiring | Company-Initialize.OnCompanyInitialize (60100) | Mid | 0.5 | 06 |
| 14 | Upgrade code / translations | none | TDD §8; Parameters §1.9 | 0.0 | — |
| 15 | Compile, package, deploy troubleshooting | 10 % of 29.6 | High end: outbound HTTP in sandboxes ("Allow HttpClient Requests"), TEM behaviour | 3.0 | 07 |
| 16 | Automated tests | 30 % of 29.6 — test app 60123–60127 (fake transport, library, three test codeunits) | High end: fake transport and many status paths | 8.9 | 06 / 07 |
| 17 | Code review and fixes | 10 % of 29.6 | High end: secrets and transaction boundaries need careful review | 3.0 | 09 |
| 18 | Documentation set | per project | Mid (4) | 4.0 | 11 |
| 19 | Release testing support and fixes | per project | Mid-high (3): manual tests 11–14, 19 and 21; live TEM and production checks | 3.0 | 12 |

## 4. Totals
| Phase | Hours | Days (8 h) |
|---|---|---|
| DEFINE + DESIGN | 13.9 | 1.7 |
| BUILD | 41.5 (29.6 build + 3.0 troubleshooting + 8.9 tests) | 5.2 |
| PROVE | 10.0 | 1.3 |
| **Total** | **65.4** | **8.2** |

**Sanity anchor:** the baselines file's anchor (10 objects = 15–30 h) scaled to this project's 23 objects is **34.5 – 69 h**, and the 0.5× – 2× band around it is 17.3 – 138 h. This estimate (65.4 h) is **inside** the band. It sits near the top of the scaled anchor because the anchor's typical PTE has no external OAuth service, no secret storage, no replaceable transport layer and no separate test app (worth 8.9 h here). This project has all four, while it has no API pages and no translations.

## 5. What would move this estimate
- **Sanity Check amendments (Step 04):** the added writer codeunit (60118), the caller checks, the never-raising Try procedure and seven more automated tests add about 2.5 h (build rows 8 and 16), so the total reads about 67.9 h. The baseline rows above are unchanged.
- Q1 (dialog buttons; decided 2026-10-10: StandardDialog kept): switching later to a Card with footer actions would add about 0.5–1 h on the dialog.
- Q2 (test app location; decided: sibling folder): restructuring the repository instead would add about 1 h of setup.
- Q5 (decided: test 12 stays manual): automating test 12 with Microsoft's lower-permission test library adds about 1 h, if that library can be installed in the sandbox.
- USPS behaving differently from its published contract (TDD Not verified items) moves rows 9, 15 and 19.
- A second language, or the deferred Ship-to, Vendor and Customer List scope (FRD §6.1), would add rows.
- An existing installation before 1.0.0.0 would require upgrade code (1–3 h per upgrade codeunit).

## Before calling this done
- [x] Every object in the Object Register appears in §3, alone or in a group.
- [x] Every row's hours can be traced to a §2 baseline and a stated complexity reason.
- [x] §2 names which baselines were used (framework default with its version, or the partner calibration file with its date) and reproduces only the rows used.
- [x] The total is within 0.5× – 2× of the sanity anchor scaled by object count, or §4 states why not.
- [x] §1 lists every assumption a reader would need to change to reuse this estimate.
- [x] The step column lets the usage table sum these hours per framework step.


---

## SC-1 addendum (1.1.0.0)

**Date:** 2026-10-17 · **Estimated by:** Reasoning role, Opus 5.5 (report first line checked against §1.7) · **Basis:** `docs/2-design/TDD.md` §15 and `docs/2-design/FRD.md` Appendix C (FRD 2.1), signed off 2026-10-17 and amended by the Sanity Check · **Reviewed by:** AJ Ansari (pending)

The human effort to take 1.0.0.0 as built (`docs/4-prove/PostDevTDD.md` Part B) to 1.1.0.0: 15 new address sources, the generic engine, the linked-record sync, the upgrade and the test-app additions. Same conventions as the estimate above, so the two read side by side. Note: the estimate above still prices the USPS 1.0 design (23 objects, 65.4 h); no human estimate of 1.0.0.0 as built exists.

### 1. Assumptions
| Assumption | Value used | Change it if |
|---|---|---|
| Developer profile | Senior AL developer, works alone, already knows this app; no ramp-up | a developer new to the codebase (add 4–6 h of reading) |
| Working day | 8 billable hours | |
| Requirements | As complete as FRD Appendix C; the decisions (OQ-34–49) are taken by AJ Ansari | the developer must gather the scope |
| Changed 1.0 objects | Costed at the baseline row for the work they gain, not as new objects | the change is a rewrite |
| Template reuse | 60116 and 60117 are the templates for the 30 extensions; later extensions priced below mid-point | each card needs its own design |
| Design review | Its own row (S3) | reviews folded in again (subtract 5.1 h) |
| Testing | Manual sandbox testing plus test codeunits 60129, 60130 and the 60124 additions as the 30 % automated-tests share; the OQ-41 checkpoint and the two-company upgrade test are their own rows | a separate QA function |
| Upgrade test environment | A sandbox with 1.0.0.0 in two companies is available | it must be built (add about 1 h) |
| Batches | One at a time (TDD 15.19); 60101 and 60113 edited in B1 and B4 | parallel batches |
| Translations | None (US wording only, Parameters §1.9) | a language is added |
| Sign-offs | Folded into S1 and S2 (one approver) | several approvers |
| Baselines | Section 2 rows, mid-point unless the row states a reason | a partner calibration file appears |

### 2. Baselines used
**Baselines:** framework default, `ocpfFramework/documentTemplates/HumanEffortBaselines.md` v1, September 27, 2026. No partner file (`~/.ocpf/HumanEffortBaselines.md` absent). The AI calibration file in `~/.ocpf/calibration/` records AI usage, not human hours.
| Task | Unit | Baseline (h) |
|---|---|---|
| Requirements write-up | per 10 entities | 1.5 – 3 |
| Technical design (incl. ID allocation) | per 10 objects | 2 – 4 |
| New table | each | 0.5 – 1.5 |
| Table extension | each | 0.25 – 0.75 |
| Page extension | each | 0.25 – 0.75 |
| Codeunit — helpers, subscribers, simple validation | each | 0.5 – 2 |
| Codeunit — business logic | each | 3 – 10 |
| Enum or enum extension | each | 0.15 |
| Permission set (pair) | per pair | 0.25 – 0.5 |
| Upgrade codeunit | each | 1 – 3 |
| Event publisher or subscriber wiring | each | 0.25 – 0.75 |
| Compile, package, deploy troubleshooting | share of build hours | 5 – 10 % |
| Automated tests | share of build hours | 20 – 30 % |
| Code review and fixes | share of build hours | 5 – 10 % |
| Documentation set | per project | 2 – 6 |
| Release testing support and fixes | per project | 1 – 4 |

### 3. Estimate by task
"Build hours" for the share rows are S4–S13 and S15–S22, totalling **40.25 h**.
| # | Task | Object(s) / scope | Complexity and why | Hours | Step |
|---|---|---|---|---|---|
| S1 | Requirements | FRD Appendix C: 21 entities → 2.1 units | High (3): many decisions; linked-record copies read from Base App source; Privacy Blocked extended to child sources | 6.3 | 02 |
| S2 | Technical design | TDD §15: 51 objects (39 new incl. 2 test codeunits; 12 changed) → 5.1 units | 30 extensions (3.0 units) at low (2) = 6.0; the other 21 (2.1 units) at high (4) = 8.4: RecordRef field map, 16-row source reference, re-blocked IDs, upgrade tags, six sync events | 14.4 | 03 |
| S3 | Design review (Sanity Check) | FRD Appendix C + TDD §15 | No baseline row: 1 h per 10 objects (half the TDD row's low end) × 5.1; 16 findings resolved, compile probe | 5.1 | 04 |
| S4 | Enum | 60134 Address Type | Fixed baseline | 0.15 | 06 |
| S5 | Business-logic codeunit | 60135 Address Source | High (7): field map for 16 tables plus the ship-to block via RecordRef; SaveSource per table; Privacy Blocked with parent lookup for 8 child tables | 7.0 | 06 |
| S6 | Helper codeunits | 60120 Write Guard, 60136 Upgrade Tags | Low (0.5 each) | 1.0 | 06 |
| S7 | Subscriber wiring | OnBeforeLaunchDuplicateForm, OnGetPerCompanyUpgradeTags | Mid (0.5 each): manual binding; internal publisher | 1.0 | 06 |
| S8 | Upgrade codeunit | 60137 Upgrade Log Source | Low-mid (1.5) | 1.5 | 06 |
| S9 | Rework business-logic codeunit | 60113 Address Validation | Low end (4): flow kept, every Customer-typed procedure becomes RecordRef-based | 4.0 | 06 |
| S10 | Rework helper codeunit | 60118 Validation Writer | High (1.5) | 1.5 | 06 |
| S11 | Table changes | 60109 Log (0.5); 60111 Buffer (0.25) | Low | 0.75 | 06 |
| S12 | Page and small changes | 60110 (0.25); text in 60112, 60096, 60100, 60099, `app.json` (0.25) | Low | 0.5 | 06 |
| S13 | Permission set | 60101 USE grants | Low | 0.25 | 06 |
| S14 | OQ-41 checkpoint | After B1: compile, package, install, run the 61 tests | No baseline row: 0.5 build and upload + 0.5 test run + 0.5 triage | 1.5 | 07 |
| S15 | Table extensions ×6 (B2) | 60143, 60145, 60152, 60154, 60156, 60158 | Below mid (0.4): template 60116 | 2.4 | 06 |
| S16 | Page extensions ×6 (B2) | 60144, 60146, 60153, 60155, 60157, 60159 | Mid (0.5): anchors differ per page | 3.0 | 06 |
| S17 | Table extensions ×9 (B3) | 60165 (0.75), eight others (0.4 each) | Company Information: second flag and reset | 3.95 | 06 |
| S18 | Page extensions ×9 (B3) | 60166 (0.75), eight others (0.5 each) | Company Information: two fields, two actions | 4.75 | 06 |
| S19 | Upgrade codeunit | 60138 Upgrade Contact Flag | Mid (2) | 2.0 | 06 |
| S20 | Business-logic codeunit | 60139 Address Sync Subscr. (OnRun) | Low end (3) | 3.0 | 06 |
| S21 | Subscriber wiring ×6 | 60139 subscriptions b–g | Mid (0.5 each) | 3.0 | 06 |
| S22 | Small edits | 60113 hook (0.25); 60116 Country/Region (0.25) | Low | 0.5 | 06 |
| S23 | Automated tests | 30 % of 40.25: 60124 additions, 60129 (about 45 tests), 60130 (about 14), 61 existing re-run | High end, as for 1.0 | 12.1 | 06 / 07 |
| S24 | Compile, package, deploy troubleshooting | 10 % of 40.25 | High end: W1-only anchors, two-range `idRanges`, files edited in two batches | 4.0 | 07 |
| S25 | Code review and fixes | 10 % of 40.25 | High end | 4.0 | 09 |
| S26 | Documentation updates | PostDevTDD, FRD baseline, Documentation, UserGuide, HumanUnitTestScript, Deployment, SandboxInstall | Mid (4) | 4.0 | 10 / 11 |
| S27 | Sandbox and release testing support and fixes | Test 24 on 17 address blocks on US cards; tests 30, 37, 38, 42 | High end (4) | 4.0 | 07 / 12 |
| S28 | Upgrade test in two companies | Test 34 | No baseline row: upgrade-codeunit row's high end (3) | 3.0 | 12 |

### 4. Totals
| Phase | Hours | Days (8 h) |
|---|---|---|
| DEFINE + DESIGN (S1–S3) | 25.8 | 3.2 |
| BUILD (S4–S24): 40.25 build + 4.0 troubleshooting + 12.1 tests + 1.5 checkpoint | 57.9 | 7.2 |
| PROVE (S25–S28) | 15.0 | 1.9 |
| **Total SC-1** | **98.7** | **12.3** |

By batch (build hours with their 10 % troubleshooting share; B4 carries the test app): B1 Engine 20.9 h (incl. the 1.5 h checkpoint), B2 5.9 h, B3 11.8 h, B4 19.2 h.

**Margin:** none stated, as in the 1.0 estimate (mid-point baselines with a stated reason, checked against the sanity anchor). **Sanity anchor:** 10 objects = 15–30 h, scaled to 37 new main-app objects = 55.5 – 111 h; the 0.5× – 2× band is 27.8 – 222 h; 98.7 h is inside it, near the top. Design work is 26 % of the total and the test share is 30 %; the 30 template-based extensions pull it down. SC-1 is about 1.5× the 1.0 estimate (65.4 h).

### 5. What would move this estimate
- The OQ-41 checkpoint finds a Customer regression: +1–3 h (S9, S10, S24).
- US-localized anchors differ from W1: about +0.25 h per affected page extension, up to about 4 h.
- A platform assumption in TDD 15.21 fails (TransferFields, the sync loop, the internal upgrade-tag publisher): +2–4 h each, plus retest.
- The automated-tests share at its low end (20 %): −4.0 h.
- Validate Address on list pages (OQ-43, deferred): 15 page extensions at 0.25–0.5 h each, plus tests.
- A target language added; or a developer new to this codebase (+4–6 h of reading).
