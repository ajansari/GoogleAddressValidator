# ChangeLog — USPS Address Validator

## Issue PRE01-1 — Plugin 3.1.0 predates runbook 5.2.0.0 layout
**Problem:** The plugin's `start` skill (3.1.0) placed `.ocpf/framework.json`, a root-level `RunbookChangelog.md`, and a root-level `scripts/`, but runbook 5.2.0.0 expects everything under `ocpfFramework/`.
**Root cause:** The installed plugin is older than the runbook fetched from GitHub's `main`.
**Resolution:** AJ's project was moved to the `ocpfFramework/` layout by hand (marker, changelog, scripts, `.mcp.json` path). The plugin's own `dashboard` skill and `ocpf-generator` agent are not in 3.1.0, so their files were fetched from the framework repository instead.
**Files affected:** `ocpfFramework/framework.json`, `ocpfFramework/RunbookChangelog.md`, `ocpfFramework/scripts/`, `.mcp.json`.
**Updated:** TDD, FRD — no (not written yet).

## Issue PRE01-2 — Project-local sub-agents may not load in the creating session
**Problem:** Claude Code loads a new `.claude/agents/` folder only at the next session start.
**Root cause:** The folder did not exist when this session began.
**Resolution:** This session delegates to the plugin's `ocpf-bc:ocpf-*` agents with the recorded model passed on every call; effort for those roles is the session's until the next session.
**Files affected:** `.claude/agents/ocpf-light.md`, `ocpf-reasoning.md`, `ocpf-generator.md`.
**Updated:** TDD, FRD — no.

## Issue 01-1 — Scope additions: Assisted Setup Wizard and Address Validated field
**Problem:** The signed-off problem statement and the original spec had no credentials wizard and no persistent indicator that a customer's address was validated.
**Root cause:** Requested by AJ Ansari during Step 01 (Box 4); not in the spec. Raw words: `requirements/scope-additions-2026-10-10-requirements.md`.
**Resolution:** Added to `docs/1-define/ProblemStatement.md` (scope, entity list) and `docs/1-define/ProjectParameters.md` §1.6/§1.6a. AJ decided: the wizard configures only Consumer Key and Secret; Address Validated becomes true on Accept and on Confirmed, is unchanged on Ignore, and resets to false when the address of a validated customer is edited. Adds a table extension and a wizard page; expected total stays well inside 50 IDs.
**Files affected:** ProblemStatement.md, ProjectParameters.md, ObjectRegister.md.
**Updated:** TDD, FRD — no (written later; both must carry the additions).

## Issue 01-2 — Permission set naming differs from the Standards default
**Problem:** The spec asks for sets named USE and ADMIN; the Standards' default pair is VIEW and EDIT.
**Root cause:** Spec predates the naming standard.
**Resolution:** Sheet records `OBCFUSPS USPS, USE` and `OBCFUSPS USPS, ADMIN` (Standards §5.4 allows further role words). To be confirmed in the FRD.
**Files affected:** ProjectParameters.md §1.3.
**Updated:** TDD, FRD — no.

## Issue 02-1 — FRD drafted by the Reasoning role
**Problem:** Step 02 requires the FRD to be drafted by the Reasoning role on the §1.7 model.
**Root cause:** n/a (procedure record).
**Resolution:** Draft produced by sub-agent `ocpf-bc:ocpf-reasoning` (the project-local copy was not loaded in this session, see Issue PRE01-2), called with `model: opus`; the report's first line read `Model: Opus 5.5`, matching §1.7. Saved as `docs/2-design/FRD.md` v0.1. It verified platform capabilities against the BC 28.5 W1 symbols and Microsoft Learn; four items could not be fully verified and are carried as OQ-12, OQ-17, OQ-19, OQ-20. Findings worth noting: BC's built-in HTTP mocking for tests is on-premises only (OQ-17); the standard Retention Policy periods have no 2-year value (OQ-8); the Customer Card FastTab is "Address & Contact", field goes in its "Address" group.
**Files affected:** docs/2-design/FRD.md.
**Updated:** TDD — not yet written; FRD — yes (new).

## Issue 02-2 — Usage script misses sub-agent transcripts
**Problem:** `ocpf-usage.py` showed no row for the Opus 5.5 Reasoning-role run at Step 02.
**Root cause:** This Claude Code version writes sub-agent transcripts to `<session>/subagents/agent-*.jsonl`; the script only reads top-level `*.jsonl`.
**Resolution:** Measured by running the unmodified script with `--transcripts` on a scratch folder of links to all transcripts. The framework script was not edited. Report to the framework author; repeat this method for later steps until fixed.
**Files affected:** ProjectProgress.md (usage table).
**Updated:** TDD, FRD — no.

## Issue UPD-1 — Framework updated from runbook 5.2.0.0 to 5.3.2.0
**Problem:** Runbook 5.2.0.0 put the dashboard in the ignored `ocpfFramework/state/`, froze it during long sub-agent turns, and its usage script and renderer missed sub-agent transcripts (see Issue 02-2).
**Root cause:** Fixed upstream in v5.3.0.0 (dashboard moves to a tracked root file), v5.3.1.0 (card overflow) and v5.3.2.0 (sub-agent transcripts counted; throttled every-tool refresh hook).
**Resolution:** AJ approved "Update now" on 2026-10-10. Replaced `CLAUDE.md`, `ocpfFramework/RunbookChangelog.md`, the Ops Guide, all 14 step files, the 17 templates, and the dashboard and usage scripts (Standards Guide unchanged, v1.12.0.0). Merged the unmatched `PostToolUse` hook (`--throttle 45`) into `.claude/settings.local.json`. Dashboard now `ProjectDashboard.html` at the project root, verified not ignored; `ocpfFramework/state/dashboard.html` removed; `.gitignore` rewritten to the 5.3.2.0 block (AJ's dashboard-tracking preference is now met by the new path, so the old exception is gone). Old copies backed up in `ocpfFramework/state/previous/5.2.0.0/`. Step files differ from 5.2.0.0 only in version lines and PRE-01's dashboard path; no completed step needs revisiting. Re-measured usage with the fixed script: Step 02's rows are unchanged (they were already measured with sub-agents included, Issue 02-2, which is now fixed upstream).
**Files affected:** CLAUDE.md, ocpfFramework/*, .claude/settings.local.json, .gitignore, ProjectDashboard.html.
**Updated:** TDD, FRD — no.

## Issue 03-1 — TDD and Human Effort Estimate drafted by the Reasoning role
**Problem:** Step 03 requires the TDD and Human Effort Estimate to be drafted by the Reasoning role on the §1.7 model.
**Root cause:** n/a (procedure record).
**Resolution:** The first delegation was lost when the session ended before its result was recorded (its tokens appear in Step 03's usage row). It was re-run with the project-local `ocpf-reasoning` agent, called with `model: opus`; the report's first line read `Model: Opus 5.5`, matching §1.7. Saved as `docs/2-design/TDD.md` v0.1 and `docs/2-design/HumanEffortEstimate.md`. The agent read the BC 28.5 symbols and the AL source shipped inside the symbol packages, and used Microsoft Learn only for built-in types. It flagged 14 unverified items (mostly the external USPS contract, to be verified against TEM at Step 07). It also reported "runbook version skew" (step file 5.3.2.0, core 5.2.0.0): that was its session context holding the old CLAUDE.md; the file on disk was already 5.3.2.0 after Issue UPD-1.
**Files affected:** docs/2-design/TDD.md, docs/2-design/HumanEffortEstimate.md.
**Updated:** TDD — yes (new); FRD — no.

## Issue 03-2 — FR-4 / test 12 clarified: StandardDialog has fixed OK/Cancel buttons
**Problem:** FRD FR-4 says Accept is "disabled" for a user without customer-modify permission, but a StandardDialog's OK button cannot be disabled or renamed.
**Root cause:** The FRD verified that the StandardDialog page type exists (§4.1 f) but not that its buttons are fixed.
**Resolution:** AJ Ansari chose to keep StandardDialog on 2026-10-10: OK = Accept, Cancel/X/Esc = Ignore; when Accept is not allowed the dialog shows the reason and OK closes as Ignore. FRD updated to v1.1 (FR-4, acceptance test 12). The same session also decided TDD questions Q2–Q6 (see TDD §11).
**Files affected:** docs/2-design/FRD.md, docs/2-design/TDD.md.
**Updated:** TDD — yes; FRD — yes.

## Issue UPD-2 — Framework updated from runbook 5.3.2.0 to 5.3.4.0
**Problem:** Newer runbook published (v5.3.3.0 and v5.3.4.0: dashboard header shows the Claude mark and the Business Central product icon).
**Root cause:** n/a (cosmetic upstream releases).
**Resolution:** AJ approved "Update now" on 2026-10-10. Replaced `CLAUDE.md`, `ocpfFramework/RunbookChangelog.md`, the Ops Guide, all 14 step files, the 17 templates and the dashboard template. Core and step files differ from 5.3.2.0 only in version lines; the usage and dashboard scripts are unchanged; Standards Guide unchanged (v1.12.0.0). Old copies backed up in `ocpfFramework/state/previous/5.3.2.0/`. `ProjectDashboard.html` re-rendered and verified not ignored. No completed step needs revisiting.
**Files affected:** CLAUDE.md, ocpfFramework/*, ProjectDashboard.html.
**Updated:** TDD, FRD — no.

## Issue 04-1 — Sanity Check findings resolved (FRD v1.2, TDD v0.3)
**Problem:** The Step 04 Sanity Check (Reasoning role, report first line `Model: Opus 5.5`, matching §1.7) found 2 blocking issues, 8 to fix before BUILD and 18 notes (`docs/2-design/SanityCheck.md`).
**Root cause:** F1 – the TDD put the customer write and the log insert in one transaction, so a platform error in the Contact sync would drop the log row. F2 – a public test hook was argued safe because secrets cannot be unwrapped, but a SecretText can be forwarded without unwrapping. The others were drafting gaps and FRD/TDD text drift after the Step 03 decisions.
**Resolution:** AJ Ansari decided on 2026-10-10: a failed write is logged as Error (F1), `SetTransport` and the credential setters get a caller check against the test app's ID (F2), the Log list keeps ADMIN-only delete (F13), and a Customer rename may rewrite log rows (F14). All fixes are in TDD v0.3 §13 and its pointer lines, FRD v1.2 (FR-2, FR-5, FR-7, FR-8, §7.2, OQ-8/OQ-17 text), `ProjectParameters.md` §1.2 (ID split), and the Object Register (new codeunit 60118 "obcfusps Validation Writer", buffer B now 4 IDs, 25 IDs unallocated overall; AJ to accept at sign-off). Human Effort Estimate +2.5 h noted; AI Effort Estimate margin note added. Four items carried as tasks: F11 USPS spec check before Step 06, F23 deployment notes, F26 and F28.
**Files affected:** docs/2-design/SanityCheck.md, TDD.md, FRD.md, HumanEffortEstimate.md, AiEffortEstimate.md; docs/1-define/ProjectParameters.md, ObjectRegister.md.
**Updated:** TDD — yes; FRD — yes (clarifications that follow decisions already taken, no new scope).

## Issue 05-1 — Scaffold and Build Plan approved; test app created
**Problem:** Step 05 requires the scaffold, the fixed batch plan and one approval before any code is generated.
**Root cause:** n/a (procedure record).
**Resolution:** AJ Ansari chose "all batches in parallel" and approved the Build Plan on 2026-10-10. Scaffold: `app.json` idRanges set to `[60093–60122]` + `[60134–60142]`; `src/Setup`, `src/Validation`, `Translations/`; `.vscode/settings.json` with CodeCop, UICop, PerTenantExtensionCop; BCQuality snapshot at `../USPSAddressValidator.bcquality/` and the patterns library in `ocpfFramework/patterns/` fetched. The separate test app project was created at `/Users/ajansari/Documents/AL/USPSAddressValidator.Tests/` (own `app.json`, GUID `ebe1c8ca-a413-4f2b-9de7-37d8c1ae4d5a`, idRanges 60123–60133, analyzers, own git repository with no commits); this GUID is the `TestAppIdTok` of TDD §13.2. TDD §3 and §10 now list codeunit 60118 in batch B4 with its Execute grant for USE.
**Files affected:** app.json, .vscode/settings.json, docs/3-build/BuildPlan.md, docs/2-design/TDD.md, ../USPSAddressValidator.Tests/*.
**Updated:** TDD — yes (B4 contents, grant, GUID); FRD — no.

## Issue B3-1 — Batch B3 (Log) generated and pre-flighted
**Problem:** Step 06 batch record (Operating Rule 10 and 7).
**Root cause:** n/a (procedure record).
**Resolution:** Generated by `ocpf-generator` (report first line: Sonnet 5.5, matching §1.7): table 60109 "obcfusps USPS Validation Log" and page 60110 "obcfusps USPS Log Entries", no deviations from the TDD. Pre-flight by `ocpf-light` (report first line: Haiku 5.5, matching §1.7): 0 issues, symbols (Customer 18, User, "User Name" Code[50]) verified against BC 28.5. Grant lines for B3 are added to the permission sets by the main role (pending until B1's pre-flight is back). Committed as one commit.
**Files affected:** src/Validation/obcfuspsUSPSValidationLog.Table.al, src/Validation/obcfuspsUSPSLogEntries.Page.al.
**Updated:** TDD — no; FRD — no.

## Issue B1-1 — Batch B1 (Foundation) generated, pre-flighted and fixed
**Problem:** Step 06 batch record, with three deviations from TDD §13.2/§13.3 found in generation and pre-flight.
**Root cause:** (1) `SecretText.Unwrap()` is OnPrem-scoped, so the 215-character length test in §13.3 cannot be written for a Cloud app. The generator substituted a try-function that falls back to plain storage; the Light pre-flight showed that is unsound (writes inside a try method can be blocked by a server setting, which would silently store the secret unencrypted). (2) The caller check compared `Format(Guid)` (braces, upper case) with a lower-case label, so it would have refused the test app. (3) An internal `DeleteToken` helper was added so internal calls skip the public caller check (sound).
**Resolution:** Generated by `ocpf-generator` (Sonnet 5.5, matching §1.7); pre-flight by `ocpf-light` (Haiku 5.5, matching §1.7). Fixes by the main role: `StoreCredential` now calls `IsolatedStorage.SetEncrypted` directly when `EncryptionEnabled()` and `IsolatedStorage.Set` otherwise, with no fallback; a secret longer than 215 characters therefore errors instead of being stored in clear. The caller check now uses `Evaluate(TestAppId, TestAppIdTok)` and compares Guid to Guid, as codeunits 60113 and 60114 do. The permission sets carry all B1–B5 grant lines (the main role integrated them). Open for the Step 07 compile: implicit BigInteger-to-Duration assignment in `SetCachedToken`, and that both keys round-trip through `GetConsumerKey`/`GetConsumerSecret`.
**Files affected:** src/Setup/ (two enums, setup table, credential codeunit, two permission sets).
**Updated:** TDD — yes (§13.3 amended below); FRD — no.

## Issue B5-1 — Batch B5 (Onboarding) generated and pre-flighted
**Problem:** Step 06 batch record.
**Root cause:** n/a.
**Resolution:** Generated by `ocpf-generator` (Sonnet 5.5) with no TDD deviations beyond naming the wizard's text variables; pre-flight by `ocpf-light` (Haiku 5.5): its only blocking finding, the missing ADMIN grants for the wizard and the registration codeunit, was the main role's integration step and is done. Open for the Step 07 compile: the wizard passes `Text` values to `SecretText` parameters (implicit conversion assumed), and that the local `Company-Initialize.OnCompanyInitialize` event accepts the subscription and fires.
**Files affected:** src/Setup/ (wizard page, registration codeunit, install codeunit).
**Updated:** TDD — no; FRD — no.

## Issue B4-1 — Batch B4 (Validation) generated, pre-flighted and fixed
**Problem:** Step 06 batch record, with deviations from the TDD found in generation and pre-flight.
**Root cause:** The TDD described the write phase (§13.1) at a level that left the shape of the Writer's public API and the buffer hand-over to the generator.
**Resolution:** Generated by `ocpf-generator` (Sonnet 5.5, matching §1.7); pre-flight by `ocpf-light` (Haiku 5.5, matching §1.7), no blocking issues. Accepted deviations: (1) codeunit 60118 also exposes `WasAddressChanged()` and `InsertLogEntry(...)` (the single place a log row is written); (2) codeunit 60113 has no `Permissions` property because every log insert runs inside 60118, which has `tabledata log = i`; (3) the caller check on `SetTransport` compares Guid to Guid via `Evaluate`; (4) `TryValidateCustomerAddress` returns true for Not Found and for the address-changed case, false only for a precondition failure or an Error outcome; (5) the buffer is inserted by the API client's `SaveBuffer` rather than before `ValidateAddress`, and the dialog shares the rows through `Rec.Copy(Buffer, true)`. Fix by the main role: `Customer.Get` in `TryValidateCustomerAddress` no longer raises (new label `NoCustomerErr`), keeping the never-raising contract of §13.1.4. TDD §13.1.2 and §10 updated. The Customer Card anchors (FastTab "Address & Contact", group AddressDetails captioned "Address", field "Post Code") were re-verified with `al_inspectpage`. Open for the Step 07 compile: `Page.LookupMode`, `Action::OK`, `LineBreak[1] := 10`, `NavApp` module-info calls, and the Expanded Permission option members.
**Files affected:** src/Validation/ (dialog page, writer codeunit, orchestration codeunit, Customer table extension, Customer Card page extension).
**Updated:** TDD — yes; FRD — no.

## Issue B2-1 — Batch B2 (USPS API) generated, pre-flighted and fixed
**Problem:** Step 06 batch record, with deviations from the TDD found in generation and pre-flight.
**Root cause:** The TDD did not state who persists the temporary buffer row, and its caller-check wording used the fragile `Format(Guid)` comparison.
**Resolution:** Generated by `ocpf-generator` (Sonnet 5.5, matching §1.7); pre-flight by `ocpf-light` (Haiku 5.5, matching §1.7). Accepted deviations (all judged sound): Guid-to-Guid caller check; `ValidateAddress` persists the buffer row (`SaveBuffer`); `ClearResult` blanks USPS result fields at the start; `SetupIncompleteErr` and `MissingCredentialsErr` declared and used in the API client; `expires_in` parsed with `Evaluate` (0 means do not cache); extra Locked technical labels in §7; the environment note is always visible. Fixes by the main role: B2 permission grants integrated; `Comment` added to the `ShowTextTok` passthrough label (setup card and orchestrator); `ReadUSPSErrorMessage` made `[NonDebuggable]`; TDD §13.2 amended with the as-built check and the buffer persistence contract. Open for the Step 07 compile: the built-in HTTP and JSON members (`JsonObject.WriteWithSecretsTo` with a SecretText result is used by Base Application "OAuth 2.0 Mgt." and is the model), the Image enum values on the setup card, and the BigInteger-to-Duration assignment in codeunit 60098.
**Files affected:** src/Validation/ (interface, buffer table, Http Transport, API Client); src/Setup/obcfuspsUSPSSetup.Page.al; src/Validation/obcfuspsAddressValidation.Codeunit.al (label comment only).
**Updated:** TDD — yes; FRD — no.

## Issue B6-1 — Batch B6 (Test app) generated, pre-flighted and fixed
**Problem:** Step 06 batch record, with two compile-level defects and one rule that could not be met.
**Root cause:** (1) AL has no procedure overloading, so three `AssertEqual` overloads would not compile. (2) Fifteen test procedure names exceeded the 30-character house limit. (3) TDD §13.5(b) required saving and restoring the credentials, but the credential getters are `internal` and isolated storage is per app, so the test app cannot read them. (4) Main code commits mid-flow (`Commit()`), so a failed test would leave data behind that the runner's rollback cannot remove.
**Resolution:** Generated by `ocpf-generator` (Sonnet 5.5, matching §1.7) in the sibling project `USPSAddressValidator.Tests`; pre-flight by `ocpf-light` (Haiku 5.5, matching §1.7): all 24 automated tests (FRD 1–10, 15–18, 20 and A1–A7) present, every asserted message matches the main app's labels, no internal member of the main app is called, no Microsoft test library referenced. Fixes by the main role: `AssertEqual` renamed `AssertEqualText`/`AssertEqualInt`/`AssertEqualBool` (library and all call sites); the 15 long test names shortened; `Lib.CleanUp()` now runs at the start of every `Prepare`. AJ Ansari decided on 2026-10-10: a code guard plus a documented rule. `Lib.InitSetup` errors unless the company name contains TEST; the Human Unit Test Script (Step 11) states that tests run only in a dedicated test company and that the TEM credentials are re-entered there for manual test 14 and the live checks. Accepted deviations: SingleInstance Library; `LastLogEntry(CustomerNo; var Log): Boolean`; extra assert helpers; the Fake adds `SetFailCustomerModify`/`GetFailText` and a Customer `OnBeforeModifyEvent` subscriber for test A7; no `MessageHandler`; test 7 without `asserterror` (TDD §13.1.4). Open for the Step 07 compile: Customer field names in the test code, the `OnBeforeModifyEvent` signature, and `Commit()` behaviour under test isolation (TDD §13.9 item 5).
**Files affected:** ../USPSAddressValidator.Tests/src/ (five codeunits).
**Updated:** TDD — yes (§13.5 as decided); FRD — no.

## Issue 07-1 — First compile: Business Foundation symbols missing
**Problem:** The first compile failed with AL1022: package 'Business Foundation' 28.5 not found in `.alpackages/`.
**Root cause:** The Step 01 global symbol download had fetched System, System Application, Base Application and Application but not Business Foundation, a dependency of Base Application.
**Resolution:** `al_downloadsymbols` (global sources, no sign-in) re-run by the main role; `Microsoft_Business Foundation_28.5.54151.54365.app` added. No code change. Symbol Source in `ProjectParameters.md` §1.4 now also lists Business Foundation 28.5.54151.54365.
**Files affected:** .alpackages/ (ignored by git).
**Updated:** TDD — no; FRD — no.

## Issue 07-2 — Stray backup file produced warning AL1025; build 0.0.0.1 not clean
**Problem:** The compile of build 0.0.0.1 reported 0 errors and 1 warning (AL1025: `ocpfFramework/state/previous/5.2.0.0/gitignore.txt` matches no definition), which fails Operating Rule 5.
**Root cause:** The framework-update backup (Issue UPD-1) stored a copy of `.gitignore` as a `.txt` file inside the project tree, and the AL compiler scans the whole project folder.
**Resolution:** Renamed the backup to `gitignore.backup.md` (nothing deleted). Build 0.0.0.2 compiles with 0 errors, 0 warnings. The 0.0.0.1 package is kept (never delete a package) but is not the clean build. Lesson recorded: framework backups must not use extensions the AL compiler recognises.
**Files affected:** ocpfFramework/state/previous/5.2.0.0/.
**Updated:** TDD — no; FRD — no.
**Analyzer proof:** a scratch copy with a table lacking a permission set produced PTE0004 and AA0215, confirming CodeCop/UICop/PerTenantExtensionCop are engaged, so the clean results are real.

## Issue 07-3 — Test app: Label cannot be converted to SecretText (AL0122 x2)
**Problem:** The first compile of `USPSAddressValidator.Tests` failed with two AL0122 errors in `obcfuspsTestLibrary.Codeunit.al` (InitSetup).
**Root cause:** The TDD §4.19 literals `'test-key'`/`'test-secret'` became Locked labels (Standards §8.3) and the generator assigned them through a `SecretText` variable; AL converts `Text` to `SecretText` implicitly but not `Label`. Diagnosed by the Reasoning role (report first line Opus 5.5, matching §1.7): a one-off (no other site in either project), not caught by lint because no Standards rule or Step 05 check covers SecretText conversions; the compile is the check. Candidate for the Patterns Library ("Label to SecretText needs a Text in between"), for AJ to decide.
**Resolution:** AJ Ansari approved the fix on 2026-10-10: a `Text` variable between the label and the call. The test app now compiles with 0 errors, 0 warnings.
**Files affected:** ../USPSAddressValidator.Tests/src/obcfuspsTestLibrary.Codeunit.al.
**Updated:** TDD — no; FRD — no.

## Issue UPD-3 — Framework updated from runbook 5.3.4.0 to 5.4.1.0
**Problem:** Newer runbook published (v5.3.5.0, v5.4.0.0, v5.4.1.0: in-place dashboard refresh with a countdown, an F1 dashboard theme, collapsible tiles).
**Root cause:** n/a (dashboard-only upstream releases).
**Resolution:** AJ approved "Update now" on 2026-10-10 while Step 07 was open. Replaced `CLAUDE.md`, `ocpfFramework/RunbookChangelog.md`, the Ops Guide, all 14 step files, the 17 templates and the dashboard scripts and templates (new `dashboard-f1.html`; new generated sidecar `ocpfFramework/state/dashboard-data.js`, ignored with the rest of `state/`). Core and step files differ from 5.3.4.0 only in version lines; the usage script is unchanged; Standards Guide unchanged. Old copies backed up in `ocpfFramework/state/previous/5.3.4.0/` (extensions the AL compiler ignores). A scratch compile after the update is clean (0 errors, 0 warnings), and `ProjectDashboard.html` is re-rendered and not ignored. The brand theme stays; the F1 theme is on request. No completed step needs revisiting.
**Files affected:** CLAUDE.md, ocpfFramework/*, ProjectDashboard.html.
**Updated:** TDD — no; FRD — no.

## Issue UPD-4 — Framework updated from runbook 5.4.1.0 to 5.4.2.0
**Problem:** Newer runbook published (v5.4.2.0: both dashboard themes always rendered, sub-agent counters, every card collapsible).
**Root cause:** n/a (dashboard-only upstream release).
**Resolution:** AJ approved "Update now" on 2026-10-10 while Step 07 was open. Replaced `CLAUDE.md`, `ocpfFramework/RunbookChangelog.md`, the Ops Guide, all 14 step files, the 17 templates and the dashboard scripts and templates. Core and step files differ from 5.4.1.0 only in version lines; the usage script is unchanged; Standards Guide unchanged. Old copies backed up in `ocpfFramework/state/previous/5.4.1.0/`. Both `ProjectDashboard.html` and the new `ProjectDashboard-f1.html` are written at the project root and are tracked (verified not ignored). A scratch compile after the update is clean (0 errors, 0 warnings). No completed step needs revisiting.
**Files affected:** CLAUDE.md, ocpfFramework/*, ProjectDashboard.html, ProjectDashboard-f1.html.
**Updated:** TDD — no; FRD — no.

## Issue CR-1 — Change request: replace the USPS API with Google Address Validation behind a provider interface
**Problem:** From 2026-08-01 the USPS Addresses API requires a signed license, a funded Enterprise Payment Account and per-use fees, requested through the Business Portal. AJ Ansari cannot complete onboarding (sign-up link does not load). The signed-off FRD v1.2 and TDD v1.0 are built on the USPS API (OAuth token, Consumer Key/Secret, test and production environments, USPS terms).
**Root cause:** External: USPS changed access and pricing after the spec was written. The spec had already flagged this as a risk ("the free service could change or end") and asked for the provider logic to stay in one place.
**Resolution (direction decided by AJ Ansari, 2026-10-11):** introduce a provider interface and implement Google Address Validation (API key, no token step); retire the USPS client and its OAuth handling (build 0.0.0.2 stays in git). AJ's volume is under 1,000 checks a month; "matched" is enough, USPS delivery data is nice to have. Google's free tier (5,000 a month on Pro, 1,000 on Enterprise) covers that. Candidates researched: Google, Smarty (42-day trial, then about $552 a year), Geocodio (2,500 free a day, no delivery-point validation), USPS (about $10 a month, unconfirmed). The live call (API key, real responses, SKU billed) is confirmed in a spike when it is time to test; until then the design uses only fields verified in Google's documentation. Step 07's sandbox round of the USPS build is on hold. The FRD, TDD, tests, Sanity Check and Object Register are amended through the normal sequence (draft by the Reasoning role, review, AJ's sign-off) before any code changes.
**Files affected:** to be listed by the amendment (FRD, TDD, ObjectRegister, ProjectParameters, source under src/, test app).
**Updated:** TDD — yes, §14 (draft, sign-off pending); FRD — yes, §10 (draft, sign-off pending). Decisions Q1–Q11 recorded in FRD §10. The draft came from the Reasoning role (report first line Opus 5.5, matching §1.7).

## Issue FW-5.7.3.0 — Framework updated 5.4.2.0 → 5.7.3.0
**Problem:** Project ran on runbook 5.4.2.0; 5.7.3.0 published.
**Root cause:** Routine framework update, approved by AJ via /ocpf-bc:update-framework (Step 07 In Progress).
**Resolution:** Replaced CLAUDE.md (backup: ocpfFramework/state/previous/CLAUDE.md.5.4.2.0), changelog, step files, templates, Ops Guide, Standards Guide (pin v1.12.1.0), scripts; sub-agent definitions rewritten from new bodies keeping model/effort. No file moves (layout already current). Notable: agent no longer publishes to any environment (human uploads; SandboxInstall.md and AutomatedTestGuide.md templates added); Step 07 agent-run API pass removed.
**Files affected:** CLAUDE.md, ocpfFramework/*, .claude/agents/ocpf-*.md.
**Updated:** TDD no, FRD no.

## Issue 07-WAIVER — Step 07 closed without confirmed sandbox testing
**Problem:** Step 07's exit gate requires the human to confirm sandbox testing is clean; AJ had not confirmed a test of 0.0.0.2.
**Root cause:** AJ chose "Skip the gate and move on anyway" (2026-10-16) after being told Rule 5 expects this before PROVE.
**Resolution:** Step 07 closed, Step 08 opened. No last installed version recorded. SandboxInstall.md written for 0.0.0.2. Provider decision (USPS vs alternatives) still open and may force rebuilds.
**Files affected:** ProjectProgress.md, ocpfFramework/state/usage.json, docs/4-prove/SandboxInstall.md.
**Updated:** TDD no, FRD no.

## Issue 08-1 — Gap-Fit Test completed; code fixes deferred to CR-1
**Problem:** Gap analysis (Reasoning role, Opus 5.5) found 17 gaps: G2/G3/G4 Oversight needing code, G5/G15–G17 verification, G6–G12 Spec stale, G1/G13/G14 Intentional.
**Root cause:** Writer and API client generated `Access = Public`; blank USPS address fields not rejected; some TDD/FRD text not consolidated after BUILD amendments.
**Resolution:** AJ decided (2026-10-16): fold G2/G3/G4 into CR-1 rework (Roadmap R-08-1..3); G6 keep USPS values on write-failure Error rows and G8 show USPS text for 400/404 only — both applied to FRD/TDD at Step 10. No code changed, no new package. Stray `OnlyBCFans_USPS Address Validator_0.0.0.2.app` in the project root is not the canonical package (`outputAppPackage/USPS_Address_Validator_0.0.0.2.app`); left in place, not deleted.
**Files affected:** docs/4-prove/GapAnalysis.md, docs/0-project/Roadmap.md.
**Updated:** TDD/FRD no (deferred to Step 10).

## Issue 09-1 — Code review fixes applied, build 0.0.0.3 (AJ Ansari approved 2026-10-16)
**Problem:** Code review (Reasoning role, Opus 5.5) found 1 Critical, 4 Major, 13 Minor (docs/4-prove/CodeReview.md).
**Root cause:** (CR9-01) `NavApp.GetCallerModuleInfo` read inside a local helper so the F2 caller check always passed; (CR9-04) no Privacy Notice before addresses leave BC; (CR9-05) code-driven Customer.Modify leaves xRec = Rec so Contact sync skipped; (CR9-06) `ValidateTableRelation = false` switched off rename propagation; (T-01) test handler wrote inside RunModal.
**Resolution:** CR9-01/02/13: caller captured in each public procedure, shared internal `CheckCallerAllowed` in 60098, test-app GUID accepted only in sandboxes, duplicate labels removed. CR9-04(a): Privacy Notice `OBCFUSPS-ADDRESS` registered in 60100, approval confirmed in 60113 after preconditions and in the Setup page Test Connection action; new permission X on 60100 for USE set. CR9-05: `SetForceUpdateContact(true)`. CR9-06(a): property removed. CR9-07, 08, 10, 14, 15, 17 applied. Test app 0.0.0.2: T-01 Commit, 8 new tests (request URL, token no response, 400, 5xx, unreadable 200, token without access_token, bad ZIP, Test Connection ×2), unused Fake procedures now used, redundant usings removed, privacy approval set in test setup. Main 0.0.0.3 and test 0.0.0.2 both compile 0 errors / 0 warnings with CodeCop, UICop, PerTenantExtensionCop. G2/G3/G4 stay scheduled with CR-1 (Roadmap R-08-1..3). Open: USPS privacy-policy link in the notice is unverified, AJ to confirm; CR9-23 telemetry and Standards §1.1 wording left for AJ.
**Files affected:** src/Setup/*, src/Validation/*, app.json (0.0.0.3), USPSAddressValidator.Tests/src/*, docs/4-prove/SandboxInstall.md. FRD/TDD amendments (§13.2 sentence, test-GUID sandbox rule, FR-1.3 ZIP rule, privacy-notice rule, F14 restored, §4 parent links, §13.6) are applied at Step 10.
**Updated:** TDD/FRD no, deferred to Step 10 by design.

## Issue 09-2 — Post-fix review findings fixed, build 0.0.0.4 (AJ Ansari approved 2026-10-16)
**Problem:** Post-fix review found Major CR9-24: privacy notice created only at install, so an upgraded environment raised "privacy notice does not exist" on every validation and Test Connection. Minors T-05, T-06 in the test app.
**Root cause:** My CR9-04 fix registered the notice in `RegisterAll` only; upgrades run no install code.
**Resolution:** `EnsurePrivacyNotice()` in 60100 (idempotent), called before every confirmation (60113 and Setup page Test Connection, each followed by Commit). Tests 0.0.0.3: approval state saved/restored, privacy-refused test, URL assertions. Main 0.0.0.4 and Tests 0.0.0.3 compile 0 errors / 0 warnings; packages in outputAppPackage/. Reasoning role (Opus 5.5) did the post-fix review; overall scorecard D, no F.
**Files affected:** src/Setup/obcfuspsSetupRegistration.Codeunit.al, obcfuspsUSPSSetup.Page.al, src/Validation/obcfuspsAddressValidation.Codeunit.al, app.json (0.0.0.4), test app src + app.json (0.0.0.3), docs/4-prove/CodeReview.md, SandboxInstall.md.
**Updated:** TDD §4.13 one line at Step 10.

## Issue 09-WAIVER — Step 09 closed without sandbox install and retest
**Problem:** Step 09's exit gate requires code fixes to be retested; builds 0.0.0.4 / Tests 0.0.0.3 were never installed, no AL Test Tool run exists.
**Root cause:** AJ Ansari chose "Close Step 09 with retest waived" (2026-10-16), as with 07-WAIVER.
**Resolution:** Step 09 closed; the install and full test run (24+10 automated tests, manual tests, G5/G15/G17 checks, privacy-notice and upgrade path) are carried as an obligation before Step 12 (Roadmap R-08-5). Overall scorecard D, no F.
**Files affected:** ProjectProgress.md, docs/0-project/Roadmap.md.
**Updated:** TDD no, FRD no.

## Issue 10-1 — Design documents updated to as-built
**Problem:** Step 10 requires an as-built TDD and a re-baselined FRD from the Gap Analysis and Code Review outcomes.
**Root cause:** n/a (procedure record).
**Resolution:** `docs/4-prove/PostDevTDD.md` written: Part A deviation summary (15 rows), Part B as-built delta by object (normative; all *Spec stale* G6–G12 and Step 09 changes), Part C original TDD §§1–12, Part D original §13 amendments. `docs/2-design/FRD.md` updated in place to 1.3 (FR-1 ZIP and privacy-notice preconditions, FR-5 write-failure rows, FR-6, FR-7 privacy row, three-call worst case, USPS text for 400/404 only, OQ-23, OQ-24); pre-Step-10 copy kept at `docs/2-design/FRD.preStep10.md` because `docs/` is not under git. CR-1 draft sections (FRD §10, TDD §14) left as unsigned drafts, not as-built. Object Register footer corrected. No translation glossary change (en-US only, no translation files). The original `docs/2-design/TDD.md` is unchanged.
**Files affected:** docs/4-prove/PostDevTDD.md, docs/2-design/FRD.md, FRD.preStep10.md, docs/1-define/ObjectRegister.md, docs/0-project/ProjectMemory.md.
**Updated:** TDD — new as-built file; FRD — yes.

## Issue 11-1 — Step 11 documents written; release candidate deferred
**Problem:** Step 11 requires the five mandatory documents, the automated-test documents when AL tests exist, and the release-candidate answer.
**Root cause:** n/a (procedure record).
**Resolution:** Written by Main-role writer agents (report first lines: Sonnet 5.5, matching §1.7) from the templates and the code: Documentation.md (no API pages exist, so it documents the public AL surface; ER diagram rendered with mermaid-cli, node v24.11.1, exit 0), UserGuide.md, Deployment.md, HumanUnitTestScript.md (27 cases), AutomatedTestScripts.md (34 tests), AutomatedTestGuide.md; Acknowledgements.md by the main role. Automated tests were already decided and built (OQ-22), so the opt-in question was not re-asked; the human has not run them (waivers 07-WAIVER, 09-WAIVER). AJ Ansari answered the release-candidate question 2026-10-16: **keep testing on 0.x builds**; Step 12 testers start from main 0.0.0.4 (+ tests 0.0.0.3). Open points from the writers carried in Roadmap R-11-1: AL Test Tool page id (launch.json says 130401, guide uses 130451), unverified menu paths and BC page wording, FRD FR-4 button names (code uses OK/Cancel), stray test-app root `.app` file, Documentation commit SHA line.
**Files affected:** docs/4-prove/{Documentation,UserGuide,Deployment,HumanUnitTestScript,AutomatedTestScripts,AutomatedTestGuide}.md, docs/0-project/Acknowledgements.md, ocpfFramework/framework.json (tooling.mermaid).
**Updated:** TDD no; FRD wording FR-4 button names to correct at Step 12 review.

## Issue 07a-1 — Remediation 07a opened: implement CR-1 with a full rename
**Problem:** The shipped design is USPS-only; CR-1 (Google Address Validation behind a provider interface) was drafted but unsigned, and AJ Ansari asked for the app to be renamed to Google Address Validator with every USPS/usps reference changed.
**Root cause:** External (USPS access terms, ChangeLog CR-1); naming decision Q11 (2026-10-11) had kept the prefix and object names.
**Resolution:** AJ Ansari (2026-10-16) chose to start remediation 07a and a **full rename including the prefix**: `obcfusps` → `obcfgav`, App Code `GAV`, namespace `OnlyBCFans.GoogleAddress`, app names Google Address Validator / … Tests. FRD §10 Q11 and a new TDD §14 2.17 record it; `docs/1-define/ProjectParameters.md` §1.1/§1.3 updated. Window `07a` opened (usage.json, ProjectProgress.md); Step 12's window closed and reopens when the project returns to it. Awaiting AJ's sign-off of FRD §10 / TDD §14 and the app-icon decision before any code is regenerated.
**Files affected:** docs/2-design/FRD.md, docs/2-design/TDD.md, docs/1-define/ProjectParameters.md, ocpfFramework/state/usage.json, ProjectProgress.md.
**Updated:** TDD — yes (§14 2.17, draft); FRD — yes (§10 Q11, draft).

## Issue 07a-2 — CR-1 signed off; new app icon
**Problem:** Remediation 07a needed sign-off of the CR-1 documents and an icon decision.
**Root cause:** n/a (procedure record).
**Resolution:** AJ Ansari signed off FRD §10 (Q1–Q11, Q11 revised to the full rename) and TDD §14 including 2.17 on 2026-10-16, as Dev Manager and Technical Lead. AJ asked for the icon to be redone in a Google theme: new original icon (map pin with check on an address card, blue background, no Google logo) at `images/google-address-validation-icon-300.png` / `.svg`, copied to `src/logo/AppLogo.png`; the old USPS icon stays at `images/usps-address-validation-icon-512.png`. Google's brand-guideline conditions for any use of Google marks are not checked; the icon uses generic colours and no Google logo.
**Files affected:** src/logo/AppLogo.png, images/.
**Updated:** TDD — no; FRD — no.

## Issue 07a-3 — CR-1 rework built: Google Address Validator 0.0.0.5
**Problem:** Remediation 07a: replace the USPS API with Google Address Validation behind a provider interface, with the full rename.
**Root cause:** USPS access terms (CR-1).
**Resolution:** Mechanical rename first (26 files, compiled 0/0). Then batches R1–R5 (Foundation, Provider layer incl. new codeunit 60119 Google Address Client, Log, Validation, Onboarding) generated in parallel by `ocpf-generator` (report first lines Sonnet 5.5, matching §1.7); R6 test app by `ocpf-generator` (Sonnet 5.5). Pre-flight by `ocpf-light` (Haiku 5.5, matching §1.7): 22 files, 2 findings fixed (label Comment; Admin permission set caption 32→30 characters), observations: USPS wording kept only as data wording, dead locals in the Google client, privacy link unconfirmed, standard Customer permissions not in the sets. Main 0.0.0.5 and test app 0.0.0.5 compile 0 errors / 0 warnings with CodeCop, UICop, PerTenantExtensionCop. The first test-app package `Google_Address_Validator_Tests_0.0.0.4.app` was built with 1 warning (AA0021 variable order) and is kept but is not the clean build; 0.0.0.5 is. Deviations accepted: delivery-warning text lives in codeunit 60113 (`DeliveryWarning`); log Suggested* fields filled only for Suggestion Accepted/Confirmed (Q1); storage key `OBCFGAV-ApiKey` per 2.17. Schema: new app objects renamed, so any installed 0.0.0.1–0.0.0.4 needs Force Sync (SandboxInstall §1).
**Not verified:** Google live call (header accepted, error `reason` values, `secondAddressLine`, boolean text form), `Headers.ContainsSecret` and request-body reads in the fake transport, privacy-approval flow, Google privacy link, standard object permissions; nothing installed or run.
**Files affected:** src/ (all), test app src/ (6 files), app.json (both), docs/4-prove/SandboxInstall.md, docs/1-define/ObjectRegister.md, docs/3-build/BuildPlan.md.
**Updated:** TDD — §14 as signed off; the as-built PostDevTDD, FRD baseline 1.3, Documentation, UserGuide, Deployment and test scripts still describe the USPS build and must be redone (Steps 08–11 on the new build).

## Issue 08-2 — Steps 08–11 reopened on the Google build
**Problem:** After remediation 07a the Gap Analysis, Code Review, PostDevTDD, FRD 1.3 and every Step 11 document describe the USPS build 0.0.0.4.
**Root cause:** The design changed after those steps closed (CR-1).
**Resolution:** AJ Ansari chose (2026-10-16) to redo Steps 08–11 on 0.0.0.5 before Step 12. The USPS-build records are kept beside the new ones: `docs/4-prove/GapAnalysis.USPSbuild-0.0.0.4.md`, `docs/4-prove/CodeReview.USPSbuild-0.0.0.4.md`; the pre-Step-10 FRD copy stays at `docs/2-design/FRD.preStep10.md`. Step 08 window reopened (second entry in usage.json).
**Files affected:** docs/4-prove/, ocpfFramework/state/usage.json, ProjectProgress.md.
**Updated:** TDD — no; FRD — no.

## Issue 08-3 — Gap-Fit on the Google build; fixes applied, build 0.0.0.6 (AJ Ansari approved 2026-10-16)
**Problem:** The Step 08 Gap-Fit on 0.0.0.5 (Reasoning role, Opus 5.5) found 26 gaps: GA-01 Writer Public; GA-02 Address Service Public with no caller check or privacy gate; GA-03 enum caption; GA-04/05 caption and caller-text inconsistency; GA-06 unconfirmed components not read; GA-07 FRD wording; the rest Spec stale or scheduled verification.
**Root cause:** Writer and facade access left Public by design text (TDD 2.4, 2.10 silent); TDD 2.17 contradicted 2.8/2.10/2.11 on captions; TDD 2.5 mapped only missing components.
**Resolution:** AJ approved all: Writer `Access = Internal`; caller check as first statements of `ValidateAddress` and `TestConnection` in 60114 (TDD 2.4 amended at Step 10); enum caption `Address Validation Result`; neutral captions (setup page `Address Validation Setup`) and caller text names the Google Address Validator app; Google client reads `unconfirmedComponentTypes` (+ test `TestUnconfirmedPartsInReason`); FRD FR-2/FR-8 narrowed to the delivery warning line as built (Step 10). Main 0.0.0.6 and test app 0.0.0.6 compile 0 errors / 0 warnings, packaged. AJ answered that nothing was ever installed (SandboxInstall: Add). CR-1 delta of the Sanity Check appended to SanityCheck.md. Both repositories to be committed. Obligations carried: Roadmap R-08-4..6, R-09-1, R-09-2, R-11-1, R-12-1, R-12-2.
**Files affected:** src/ (7 files), test app (2 files + app.json), app.json, docs/4-prove/{GapAnalysis,SandboxInstall}.md, docs/2-design/SanityCheck.md, docs/1-define/ObjectRegister.md, docs/0-project/Roadmap.md.
**Updated:** TDD — at Step 10; FRD — at Step 10.

## Issue 09-3 — Code review (Google build) fixes applied, build 0.0.0.7 (AJ Ansari approved 2026-10-16)
**Problem:** The Step 09 review of 0.0.0.6 (Reasoning role, Opus 5.5; `docs/4-prove/CodeReview.md`) graded overall C: one Major (CR9G-01: a fake provider injected in one test leaks into later tests, so `TestAttributionShown` fails in a full run), 11 Minors, notes.
**Root cause:** Globals of a test codeunit persist between its test methods; batches R2/R4/R6 were written in parallel and drifted (dead locals, duplicated labels, literals, a trailing space, a double `CanModifyCustomers()`); the orchestrator was left a public surface.
**Resolution:** 3a, main 0.0.0.7: Google client (dead locals/labels and the redundant credentials check removed, trimmed Not Found message), Address Service `SetupIncompleteText()`, 60113 DPV Locked tokens and `CanModify` computed once, 60112 `Format(PageStyle::…)`. 3b: caller check as first statements of 60113 `ValidateCustomerAddress`/`TryValidateCustomerAddress` (D-1 a; Documentation and TDD §13.1.4 get one sentence at Step 10/11); new label `TestConnectionFailedNoMessageErr` (D-2; TDD 2.11 one row at Step 10). Tests 0.0.0.7: `Clear(Validator)` in every `Prepare`, six new tests (DPV S, DPV N warning, boolean flags and notes, seam Not Found / Error / no credentials), lib label Comment, trimmed expected text. AJ closed conflict rows: no telemetry (CR9-23 closed), tests keep in-house assert helpers. Main 0.0.0.7 and tests 0.0.0.7 compile 0 errors / 0 warnings, packaged. Re-grade by the Reasoning role pending/recorded in CodeReview.md. Pattern candidates P6, P7 flagged to AJ (with P1–P5).
**Files affected:** src/ (4 files changed in each app plus labels), both app.json (0.0.0.7); 61 tests (60125 = 24, 60126 = 29, 60127 = 8), docs/4-prove/{CodeReview,SandboxInstall}.md.
**Updated:** TDD — 2.5 (error fields), 2.11, §13.1.4 at Step 10; FRD — no.

## Issue 09-WAIVER-2 — Step 09 (Google build) closed without sandbox install and test run
**Problem:** Step 09's exit gate requires code fixes to be installed and retested; main 0.0.0.7 and tests 0.0.0.7 have not been installed and the 61 automated tests have not run.
**Root cause:** AJ Ansari chose "Waive by name, carry to before Step 12" (2026-10-16), as in 07-WAIVER and 09-WAIVER. AJ also accepted by name the Minors CR9G-19 (empty/duplicated Google message in two error labels), CR9G-20 (missing test for Test Connection with no message) and CR9G-06 residual (test literals not shared); Notes CR9G-21 to CR9G-24 carried.
**Resolution:** Step 09 closed; overall scorecard C, no F. Obligations: Roadmap R-09-1, R-08-4..6, R-12-1, R-12-2, R-11-1. Documents to update at Step 10/11: TDD 2.5 (error fields), 2.11 (new label), §13.1.4 and PostDevTDD B-2 (caller check on 60113 entry procedures), Documentation §3.2/§3.3.
**Files affected:** docs/4-prove/CodeReview.md, ProjectProgress.md.
**Updated:** TDD — at Step 10; FRD — no.

## Issue 10-2 — Design documents updated to the Google as-built
**Problem:** Step 10 reopened after remediation 07a: FRD 1.3 and PostDevTDD described the USPS build.
**Root cause:** CR-1 changed the design after Step 10 first closed (10-1).
**Resolution:** Main-role writers (report first lines Sonnet 5.5, matching §1.7). `docs/2-design/FRD.md` rewritten in place as 2.0 AS-BUILT BASELINE for Google (CR-1 §10 folded into §1–§9, Step 08/09 requirements added, GA-07/11/12/19 applied, OQ-23..OQ-33, tests 1–23 mapped to the 61 automated tests); `docs/4-prove/PostDevTDD.md` rewritten as the Google as-built TDD (Part A 21 deviations, Part B B-1..B-23 normative, Part C pointer to the original TDD, Part D §13 rules restated, Part E limitations). USPS versions kept: `FRD.USPSbuild-1.3.md`, `PostDevTDD.USPSbuild-0.0.0.4.md`, `FRD.preStep10.md`. `docs/2-design/TDD.md` kept as the historical record with an updated header and §14 status, and the list of corrections applied by the as-built. ProjectParameters, BuildPlan title, ObjectRegister, ProjectMemory updated. Not changed: translation glossary (en-US, no translation files).
**Files affected:** docs/2-design/FRD.md, TDD.md, docs/4-prove/PostDevTDD.md, docs/1-define/ProjectParameters.md, ObjectRegister.md, docs/3-build/BuildPlan.md, docs/0-project/ProjectMemory.md.
**Updated:** TDD — as-built file; FRD — yes.

## Issue 11-2 — Step 11 documents rewritten for the Google build; release candidate again deferred
**Problem:** After remediation 07a every Step 11 document described the USPS build.
**Root cause:** CR-1 changed the design after Step 11 first closed (11-1).
**Resolution:** Rewritten by Main-role writer agents (report first lines Sonnet 5.5, matching §1.7) from the templates, the code and the Google as-built docs: Documentation.md (public AL surface, ER diagram rendered with mermaid-cli node v24.11.1 exit 0, image not viewed), UserGuide.md, Deployment.md (Google Cloud project, key restriction, daily cap and budget alert, key rotation, Customer/Contact permissions, privacy-notice caveats; USPS 72-hour duty removed), HumanUnitTestScript.md (29 cases), AutomatedTestScripts.md and AutomatedTestGuide.md (61 tests), Acknowledgements.md by the main role. USPS-build versions kept in docs/4-prove/USPSbuild/. SandboxInstall §5 captions corrected. Automated tests were already decided (OQ-22). Open points carried (Roadmap R-11-1 extended): AL Test Tool page id (130401 vs 130451), unverified BC menu paths and page wording, Google pricing figure from FRD (read 2026-10-08), test-app `.vscode/launch.json` still names company "TEST USPS" (passes the TEST guard).
**Files affected:** docs/4-prove/*.md, docs/0-project/Acknowledgements.md, docs/4-prove/USPSbuild/.
**Updated:** TDD no; FRD no.

## Issue 11-3 — PolyForm Shield License added
**Problem:** The repository carried no license, and `app.json` `EULA` was blank (noted in Documentation §8, OQ-29).
**Root cause:** Licensing was never part of the intake; AJ Ansari asked for it on 2026-10-17, to match the other OnlyBCFans repositories.
**Resolution:** `LICENSE` written at the repository root from the same verbatim PolyForm Shield License 1.0.0 text used by obcfBCObjectRegistry, ocpfBcVsCodeExtension and ocpfBcAgenticDevFramework, with `Required Notice: Copyright 2026 AnsariCo, Inc. dba OnlyBCFans (https://OnlyBCFans.com)` and a `Licensor Line of Business:` line naming address validation for Business Central. `app.json` `EULA` points at the file on GitHub (as ocpfBCAPIsV3 does). Documentation §9 and Deployment §1 carry the summary; Documentation §8's "EULA blank" sentence corrected. The Object Registry's optional Additional Terms and COMMERCIAL.md were not copied; they can be added if AJ wants commercial-embedding terms for this app. No code change, no new package.
**Files affected:** LICENSE, app.json, docs/4-prove/Documentation.md, docs/4-prove/Deployment.md, docs/0-project/ProjectMemory.md.
**Updated:** TDD — no; FRD — no.

## Issue 11-4 — README.md added
**Problem:** The repository had no README; the GitHub landing page showed nothing about the app.
**Root cause:** Not part of the Step 11 document set. AJ Ansari asked for one on 2026-10-17.
**Resolution:** `README.md` written at the repository root in the style of the other OnlyBCFans/OnlyCopilotFans extension repositories: purpose, USPS-to-Google history, features, out of scope, requirements, getting started, repository layout, document map, license section with the Required Notice. States the pre-release status (0.0.0.7, not installed in any tenant).
**Files affected:** README.md, docs/0-project/ProjectMemory.md.
**Updated:** TDD — no; FRD — no.

## Issue 12-1 — Release round on 0.0.0.7 passed; release candidate 1.0.0.0 built
**Problem:** The release-candidate question was deferred twice at Step 11 (11-1, 11-2); the project was testing on 0.x builds.
**Root cause:** Step 12's rule: offer the question again the first time a round passes clean. AJ Ansari reported on 2026-10-17 that the users tested 0.0.0.7 in `sandbox` and were happy, with no findings (TestingFeedback TF-01), and that the Dev Manager review of PostDevTDD, FRD 2.0 and the Step 11 documents was done.
**Resolution:** `docs/4-prove/ReleaseTestResults.md` written (29 cases Pass in aggregate, first release so no upgrade path, no translations). Last installed version recorded: 0.0.0.7 in `sandbox`. AJ chose *Yes, build 1.0.0.0* (Rule 6a, Major bump). `app.json` 0.0.0.7 → 1.0.0.0, no code change; `ocpfFramework/scripts/al-analyze.sh` pte profile, 0 errors / 0 warnings; `outputAppPackage/Google_Address_Validator_1.0.0.0.app`. Schema additive only (identical objects), Sync Mode Add. Because the package that ships must be the one tested, 1.0.0.0 needs a sandbox smoke pass before production; ReleaseTestResults §6 records it as pending. Test app not rebuilt (its 0.0.0.7 build targets main 0.0.0.7 and is sandbox-only). SandboxInstall §1, Deployment §1 and §2, README status, ProjectMemory and Roadmap (R-08-4..6, R-09-1, R-09-2, R-11-1, R-12-1 closed) updated.
**Files affected:** app.json, outputAppPackage/Google_Address_Validator_1.0.0.0.app, docs/4-prove/ReleaseTestResults.md, docs/0-project/TestingFeedback.md, docs/4-prove/SandboxInstall.md, docs/4-prove/Deployment.md, README.md, docs/0-project/ProjectMemory.md, docs/0-project/Roadmap.md.
**Updated:** TDD — no; FRD — no.

## Issue 12-2 — 1.0.0.0 smoke-tested; Step 12 closed, project released
**Problem:** Step 12 could not close until the release candidate itself had been tested as the file that ships.
**Root cause:** AJ Ansari confirmed on 2026-10-17 that 1.0.0.0 was installed in `sandbox` over 0.0.0.7 and smoke-tested with no findings, and chose *close the project*.
**Resolution:** Last installed version 1.0.0.0 (`sandbox`). ReleaseTestResults §6 names `outputAppPackage/Google_Address_Validator_1.0.0.0.app` as the package that ships, as it is; Deployment §1 and README updated. The production deploy is AJ's (Admin Center → Manage Apps, Schema Sync Mode Add — nothing was ever installed in production). `ProjectProgress.md` Step 12 → Completed; usage rows for Step 12 written by the usage script and the calibration file exported to `~/.ocpf/calibration/`. Still unconfirmed: whether the 61 automated tests were run (Roadmap R-09-1 note).
**Files affected:** ProjectProgress.md, docs/4-prove/ReleaseTestResults.md, docs/4-prove/Deployment.md, README.md, docs/0-project/ProjectMemory.md, ocpfFramework/state/usage.json.
**Updated:** TDD — no; FRD — no.

## Issue 12-3 — Framework updated from runbook 5.7.3.0 to 5.8.0.0 (AJ Ansari approved 2026-10-17)
**Problem:** The project's pinned runbook was one version behind the published 5.8.0.0 (October 16, 2026).
**Root cause:** AJ Ansari ran `/ocpf-bc:update-framework` after Step 12 closed and chose *Update now*. Nothing in 5.8.0.0 reopens finished work: the new pre-review applies to Step 07 (already closed), and the usage scripts were already the 5.8.0 ones for the Step 12 measurement.
**Resolution:** Layout was already `ocpfFramework-1`, so no files moved. Backed up to `ocpfFramework/state/previous/` (runbook, changelog, Operations Guide, step files, templates, scripts, three sub-agent definitions, each `.5.7.3.0`). Replaced: `CLAUDE.md` (5.8.0.0), `ocpfFramework/RunbookChangelog.md`, `ocpfFramework/opsGuide/ocpfOperationsGuide.md` (5.8.0.0), all 14 step files (each `Runbook version: 5.8.0.0`), all 25 document templates (adds `FeatureDataModel.md`), and the scripts from the plugin 5.8.0 (`al-analyze.sh`, `al-mcp.sh`, `al-mcp-call.sh`, `ocpf-dashboard.py`, both dashboard templates, `ocpf-usage.py`, `ocpf-notify.sh`). Standards Guide unchanged at v1.12.1.0 (pin unchanged; prelude README refreshed). Patterns library not refreshed (separate repository, refreshed on request only). Sub-agents: `ocpf-light`, `ocpf-reasoning`, `ocpf-generator` rewritten from the new bodies keeping their recorded models and efforts (haiku medium, opus high, sonnet medium); new `ocpf-reviewer` added on the Main model and effort (sonnet medium), and added to `.gitignore`. `ocpfFramework/framework.json`: `runbookVersion` 5.8.0.0, `pluginVersion` 5.8.0, `commitSha` 590832a, `declinedUpdateVersion` cleared. Dashboard re-rendered once with the new scripts. Revisit: nothing. Note for any later fix build: the Step 07 pre-review would now run on it.
**Files affected:** CLAUDE.md, ocpfFramework/ (all untracked), .claude/agents/ (untracked), .gitignore, docs/0-project/ProjectMemory.md, ProjectDashboard.html, ProjectDashboard-f1.html.
**Updated:** TDD — no; FRD — no.

## Issue SC-1 — Scope change: address validation on master data beyond Customer (AJ Ansari, 2026-10-17)
**Problem:** Version 1.0.0.0 validates Customer addresses only. AJ Ansari wants the same Validate Address action and non-editable Address Validated flag on the other master-data tables that hold an address.
**Root cause:** New requirement after release (raw input in `requirements/scope-additions-2026-10-17-more-master-data-requirements.md`). The in-scope tables were taken from the Base Application 28.5 symbols (not from memory): Ship-to Address 222, Customer Bank Account 287, Vendor 23, Order Address 224, Remit Address 2224 (not 229), Vendor Bank Account 288, Company Information 79 (two blocks), Location 14, Responsibility Center 5714, Bank Account 270, Employee 5200, Alternative Address 5201, Contact 5050, Contact Alt. Address 5051, Resource 156. Excluded by AJ Ansari: every transaction and document table, Job, Job Task, Service Item, Work Center, Machine Center, Union, templates.
**Resolution:** Decisions in the options box: Union out of scope; ID range extended by 50 (60143–60192); version minor bump to 1.1.0.0; batches one at a time. Approach: make the validation engine table-agnostic (RecordRef plus a per-table address field map), keep the Customer behavior and the public `ValidateCustomerAddress` unchanged, add log fields (source table, source SystemId, description) beside `Customer No.`, one table extension and one page extension per table, unique field numbers per table (Customer's 60093 stays reserved for `Contact.TransferFields`). Next: FRD and TDD amendments (reasoning role), Sanity Check, Build Plan, one approval for the plan. No code changed yet.
**Draft:** the Reasoning role (report first line: Opus 5.5, matching §1.7) returned findings F1–F14, a verified table reference, FRD 2.1 text, TDD §15 text and open questions OQ-34..46, saved unedited as `docs/2-design/SC-1-Amendments-Draft.md` (working draft, not part of the signed-off FRD/TDD). It corrects two statements made to AJ Ansari in chat: unique field numbers per table (F1: the Contact-family tables should share 60093) and modify permissions on new tables (F6: none needed).
**Files affected:** requirements/scope-additions-2026-10-17-more-master-data-requirements.md, docs/2-design/SC-1-Amendments-Draft.md, docs/0-project/ChangeLog.md, docs/0-project/ProjectMemory.md.
**Updated:** TDD — pending; FRD — pending.

## Issue SC-1a — SC-1 design decisions and amendments integrated (AJ Ansari, 2026-10-17)
**Problem:** The Reasoning role's draft (SC-1) needed AJ Ansari's decisions before it could be integrated.
**Root cause:** Findings F1–F5 change the proposal given in chat (shared field number, flag sync, Country/Region reset, Customer-side code path) and OQ-34..46 were open.
**Resolution:** AJ Ansari decided in the options box: OQ-34 shared field number 60093 (60094 for the Company Information ship-to flag); OQ-35 flag follows standard address copies; OQ-36 Country/Region clearing resets the flag, Customer included; OQ-37 Privacy Blocked refuses validation, Customer included; OQ-38 one privacy notice/switch for all tables; OQ-39/40 Customer No. blank on Ship-to Address and Customer Bank Account, one Company Information log action; OQ-41 checkpoint after batch 1; OQ-42–46 recommended defaults. Appended as `docs/2-design/FRD.md` Appendix C (FRD 2.1 DRAFT) and `docs/2-design/TDD.md` §15 with a decisions table; the original sections are untouched and the appendix governs for 1.1.0.0. Two items drift from 1.0.0.0 Customer behavior by decision (OQ-36, OQ-37, plus Contact update on Confirmed under OQ-35) and will need test changes.
**Files affected:** docs/2-design/FRD.md, docs/2-design/TDD.md, docs/0-project/ChangeLog.md, docs/0-project/ProjectMemory.md.
**Updated:** TDD — yes (draft, unsigned); FRD — yes (draft, unsigned).

## Issue SC-1b — Design sign-off for SC-1 and Sanity Check started (AJ Ansari, 2026-10-17)
**Problem:** FRD Appendix C (2.1 draft) and TDD §15 needed the Dev Manager and Technical Lead sign-off before the Sanity Check.
**Root cause:** Approvers is one person (PRE-01), so one sign-off covers both documents.
**Resolution:** AJ Ansari signed off both in the options box on 2026-10-17 and chose to proceed to the Sanity Check. The Sanity Check is delegated to the Reasoning role (Opus 5.5, `ocpf-reasoning`, background) with a brief to spot-verify the draft against the symbols rather than trust it. The sign-off covers the design as drafted; any blocking Sanity Check finding reopens the affected section.
**Files affected:** docs/0-project/ChangeLog.md, docs/0-project/ProjectMemory.md.
**Updated:** TDD — no; FRD — no.

## Issue SC-1c — Sanity Check of SC-1 resolved (AJ Ansari, 2026-10-17)
**Problem:** The Sanity Check on FRD Appendix C and TDD §15 found 2 blocking, 13 should-fix and 8 notes (`docs/2-design/SanityCheck.md`, section SC-1 Sanity Check).
**Root cause:** The draft left OQ-37 undesigned and depended on the unsigned draft report; it also missed three standard-BC side effects (flag-only contact update inside the write, the duplicate-contact form, Employee→Resource) and had thin growth buffers.
**Resolution:** AJ Ansari decided in the options box: OQ-37 covers the record and child sources of a blocked parent; linked-record update as a separate step after commit; duplicate form suppressed during Accept; Employee→Resource propagated; IDs re-blocked (engine 60134–60139, Write Guard 60120, sources 60143–60192); 60101 and 60113 edited in B1 and B4 as a recorded exception; test names ≤ 30; explicit upgrade tags (a departure from Standards §9.3, decider AJ Ansari — `SetAllUpgradeTags()` would mark other extensions' pending upgrades done on install into an existing company; verified in the shipped System Application source). The main role applied all of it to FRD Appendix C (adds FR-17, FR-18, tests 40–45, OQ table) and TDD §15 (adds 60120, 15.13 rewritten, 15.22 source reference, 15.23 Customer changes; every object renumbered), and updated ProjectParameters §1.2 and the Object Register. Reasoning-role models: Opus 5.5 (both reports).
**Files affected:** docs/2-design/FRD.md, docs/2-design/TDD.md, docs/2-design/SanityCheck.md, docs/1-define/ProjectParameters.md, docs/1-define/ObjectRegister.md, docs/0-project/ChangeLog.md, docs/0-project/ProjectMemory.md.
**Updated:** TDD — yes; FRD — yes. `app.json` is not changed yet (batch 1).

## Issue SC-1d — SC-1 design step closed (AJ Ansari, 2026-10-17)
**Problem:** The SC-1 design cycle (FRD/TDD amendments, Sanity Check, effort estimates) needed its exit gate and usage rows.
**Resolution:** Gate met: FRD Appendix C and TDD §15 signed off and amended by the Sanity Check (0 blocking open); Human Effort addendum (98.7 h, Opus 5.5) and AI Effort addendum (about $65 for Steps 05–12, range $45–85) appended; ProjectParameters §1.2 and the Object Register updated. Usage step `SC1-D` measured by the usage script: Opus 5.5 $9.96, Sonnet 5.5 $2.79, total $12.75 (the Human Effort estimate column carries 25.8 h for S1–S3). `app.json` is untouched until batch 1.
**Files affected:** ProjectProgress.md, ocpfFramework/state/usage.json, docs/2-design/HumanEffortEstimate.md, docs/2-design/AiEffortEstimate.md, docs/2-design/TDD.md, docs/0-project/ChangeLog.md, docs/0-project/ProjectMemory.md.
**Updated:** TDD — yes; FRD — no.

## Issue SC-1e — Step 05 (Plan the Code) for 1.1.0.0 closed; plan approved (AJ Ansari, 2026-10-18)
**Problem:** The SC-1 build needed a Build Plan with fixed IDs and paths and one approval before any code.
**Resolution:** `docs/3-build/BuildPlan.md` section "SC-1 — Build Plan" written from TDD §15: B1 engine (5 new objects plus 11 changed files incl. `app.json`), B2 sales and purchasing (12), B3 company/org and people (19), B4 sync, Customer reset and test app (3 new plus edits). 37 main-app IDs and 2 test codeunits, each in exactly one batch; 60101 and 60113 edited in B1 and B4 (recorded exception). Batch mode: one at a time, stop after B1 for the OQ-41 sandbox checkpoint. Folders `src/Sources/` and `src/Upgrade/` created; `app.json` unchanged until B1. AJ Ansari approved the whole plan by name in the options box on 2026-10-18. Usage step `SC1-05`: Sonnet 5.5 $0.29.
**Files affected:** docs/3-build/BuildPlan.md, src/Sources/.gitkeep, src/Upgrade/.gitkeep, ProjectProgress.md, ocpfFramework/state/usage.json.
**Updated:** TDD — no; FRD — no.

## Issue B1-1 — SC-1 batch B1 (engine) generated, pre-flighted, compiled clean (AJ Ansari, 2026-10-18)
**Problem:** Batch B1 of the 1.1.0.0 plan: make the validation engine table-agnostic without changing Customer behaviour beyond FR-18.
**Resolution:** Written by the main role (sequential mode, Sonnet 5.5): new 60134 Address Type, 60120 Write Guard, 60135 Address Source, 60136 Upgrade Tags, 60137 Upgrade Log Source; changed 60113, 60118, 60109 (fields 24–28, key SourceCheckedAt, OnInsert), 60110, 60111 (fields 30–33), 60112, 60096, 60099, 60100, 60101, `app.json`. Pre-flight by the light role (Haiku 5.5, report first line checked): 0 blocking; applied: unused `AddressType` removed from `IsPrivacyBlocked`, 4-space indentation of 60137's `Permissions`. Checkpoint compile (OQ-41, analyzers on): `1.1.0.0` compiled with 7 AA0021 warnings (variable order by type) — never installed; fixed; `1.1.0.1` compiled 0 errors, 0 warnings, `outputAppPackage/Google_Address_Validator_1.1.0.1.app`. Deviations from TDD 15.5: `SaveSource(var SourceRecRef; AddressWritten)` has no `AddressType` parameter (unused); `IsPrivacyBlocked(var SourceRecRef)` likewise; added `GetTableCaption(SourceTableNo)` so the "record no longer exists" message has a caption when the record is gone. Open for the sandbox: the platform behaviours in TDD 15.21 (xRec on code-driven modify, the local-event subscription at runtime, the internal upgrade-tag publisher).
**Files affected:** src/Sources/*, src/Upgrade/*, src/Validation/obcfgavAddressValidation.Codeunit.al, obcfgavValidationWriter.Codeunit.al, obcfgavValidationLog.Table.al, obcfgavAddressBuffer.Table.al, obcfgavLogEntries.Page.al, obcfgavAddressCompare.Page.al, src/Setup/*, app.json, docs/4-prove/SandboxInstall.md.
**Updated:** TDD — no (deviations recorded here); FRD — no.

## Issue B2-1 / B3-1 / B4-1 — SC-1 batches B2, B3, B4 generated and compiled (AJ Ansari asked for everything to be completed without interruptions, 2026-10-18)
**Problem:** Build the remaining batches of 1.1.0.0 after B1, with no stop at the OQ-41 checkpoint (AJ Ansari: "Don't bother me until everything is done").
**Resolution:** AJ Ansari's instruction replaces the OQ-41 stop after B1; the sandbox checkpoint is now one install of the final package. B2 (6 sources) and B3 (9 sources, company with two blocks) were generated by script from the verified source reference (TDD 15.22) and TDD 15.3 names/IDs: 30 table and page extensions, each pair checked by the compiler; upgrade codeunit 60138. B4: 60139 Address Sync Subscr. (`OnRun` linked-record update for Customer, Vendor, Bank Account and Employee; subscribers b–g), the hook in 60113 (`RunLinkedSync` after the writer's commit, failure swallowed so the check stays complete), Customer Country/Region reset in 60116, USE grant. Test app: library additions to 60124, new 60129 (16 accept and 16 edit-resets variants plus privacy, unsupported, log, vendor and company tests) and 60130 (sync tests); the `Subtype = Test` codeunit 60130 uses `EventSubscriberInstance = Manual` (compiler rule AL0501) and binds itself only in the failure test. Compile: main 1.1.0.2 0 errors / 0 warnings; test app 0.0.0.9 0 / 0 against it (0.0.0.8 built with 3 warnings, never installed). Process deviations: no per-batch light-role pre-flight for B2–B4 (the 30 extensions are one generated template, compiled clean); the Step 07 pre-review (reviewer, Sonnet 5.5) and an Opus 5.5 review of the runtime-risk code run on the whole result instead. No tests have been run.
**Files affected:** src/Sources/*, src/Upgrade/obcfgavUpgradeContactFlag.Codeunit.al, src/Validation/obcfgavAddressValidation.Codeunit.al, obcfgavCustomer.TableExt.al, src/Setup/OBCFGAVGAVUSE.PermissionSet.al, app.json (1.1.0.2), test app src/* and app.json.
**Updated:** TDD — no; FRD — no.

## Issue SC-1f — Pre-review and runtime review of 1.1 resolved; builds 1.1.0.3 / 0.0.0.11 (AJ Ansari's standing instruction to finish without questions, 2026-10-18)
**Problem:** The Step 07 pre-review (reviewer, Sonnet 5.5, first line checked) and an Opus 5.5 runtime review (first line checked) of the whole 1.1 code found no blocking defect but 4 test-app cleanup defects, 5 test gaps and 5 runtime points (D1–D5), two of them needing a design decision (D3, D4).
**Resolution:** Fixed in code: D1 (skip the linked update when the linked flag already matches), D2 (Write Guard bound around the standard update calls), D4 (person flag follows only a changed company address or flag), D5 (SetLoadFields/SetCurrentKey in 60138). D3 decided by the main role, taking the reviewer's recommended option, because AJ Ansari asked not to be interrupted: for a Contact source the linked-record update stays part of the write (FRD FR-12.4 amended; to be confirmed by AJ Ansari — it is a one-line revert to a separate step if he prefers). Test app: Remit Address, Order Address, Vendor Bank Account and person-contact cleanup, `RestoreCompanyInformation` no longer forces the indicators to No, tests added (`TestContEditClearsVendFlag`, `TestContEditClearsBankFlag`, `TestContConfirmedFlagsCust`, `TestContNotFoundClearsCust`, `TestContEditClearsEmpFlag`), all five address fields in the edit-resets variants, countries US/CA ensured. Not done: persisting the test baselines in a table (a failed run can leave Company Information or Marketing Setup altered; manual recovery is in AutomatedTestGuide). Main 1.1.0.3 and test app 0.0.0.11 compile with 0 errors and 0 warnings; main 1.1.0.2 and test 0.0.0.9/0.0.0.10 exist in the package folders and were never installed. Docs updated by a writer agent (Sonnet 5.5) and the main role.
**Files affected:** src/Sources/obcfgavAddressSyncSubscr.Codeunit.al, src/Upgrade/obcfgavUpgradeContactFlag.Codeunit.al, app.json, test app src/* and app.json, docs/*.
**Updated:** TDD — no (15.13 as written; PostDevTDD F-8 records the as-built); FRD — yes (FR-12.4).

## Issue SC-1g — Step 07 closed for 1.1 with a waiver; Steps 08 and 09 opened (AJ Ansari's instruction to run through Step 11, 2026-10-18)
**Problem:** The Step 07 exit gate needs a sandbox install and test by the human, which can't happen inside this session.
**Resolution:** Same waiver as in 1.0 (Step 07 waiver, Step 08 decisions): Step 07's gate is waived for 1.1.0.3 by AJ Ansari's standing instruction; recorded risk: nothing has been installed or run; last installed version in any tenant remains 1.0.0.0 in `sandbox`. The Step 12 release test is where the first install happens and its results decide whether a fix round (1.1.0.4+) is needed. Steps 08 and 09 run in parallel on the Opus 5.5 reasoning role (they read the same code and the findings are independent).
**Files affected:** ProjectProgress.md, ocpfFramework/state/usage.json.
**Updated:** TDD — no; FRD — no.

## Issue 08-SC1 — Step 08 Gap-Fit for 1.1.0.3 (Reasoning role Opus 5.5, first line checked; AJ Ansari's instruction, 2026-10-18)
**Problem:** Formal three-way comparison of FRD Appendix C, TDD §15 and the as-built 1.1.0.3 code.
**Resolution:** 15 gaps: 5 Oversight (3 fixed now in the test app and test documents, 2 scheduled), 6 Spec stale, 4 Intentional; no main-app code change. Fixed: GA-1.1-01 (`TestPersonJoinsCompanyFlag` could not pass: the person must start with a blank address for BC to inherit the company's), GA-1.1-02 a (new `TestShipToAcceptKeepsMain`), GA-1.1-03 (test counts now 127 = 24+29+8+48+18, rows 122–127 in AutomatedTestGuide), GA-1.1-10 (Object Register headings and test-app buffer). Test app 0.0.0.12 compiled 0 errors / 0 warnings against main 1.1.0.3. Spec stale, applied at Step 10: GA-1.1-04 (60113 gates the linked update on `CanModify`; 60139 checks `Contact.WritePermission()` per branch and `Resource.ReadPermission()` for Employee), GA-1.1-05 (typed `FieldNo("Privacy Blocked")` per table, parent read through RecordRef, `OpenSource` load fields), GA-1.1-06 (D1/D2/D4), GA-1.1-09 (identity and counts), GA-1.1-11 (FRD sections 1–9 not yet folded with Appendix C), GA-1.1-15 (the linked update is the full standard Contact update: Last Date Modified and Change Log entries change). Intentional: GA-1.1-07 Contact-source exception (D3, still awaiting AJ Ansari's confirmation), GA-1.1-08, GA-1.1-12, GA-1.1-15. Scheduled: GA-1.1-02 b (assert the key in the description), GA-1.1-14 (Country reset test on the 15 new tables). GA-1.1-13: nothing of 1.1 has been installed or run — first install is Step 12.
**Files affected:** docs/4-prove/GapAnalysis.md, USPSAddressValidator.Tests/src/obcfgavSyncTests.Codeunit.al, obcfgavSourceTests.Codeunit.al, test app app.json, docs/4-prove/AutomatedTestGuide.md, AutomatedTestScripts.md, HumanUnitTestScript.md, Documentation.md, README.md, docs/1-define/ObjectRegister.md.
**Updated:** TDD — no (Step 10); FRD — no (Step 10).

## Issue SC-1h — Step 09 Code Review of 1.1 resolved; builds 1.1.0.5 / 0.0.0.15 (AJ Ansari's standing instruction, 2026-10-18)
**Problem:** Code Review (Reasoning role Opus 5.5, first line checked): 0 Critical, 1 Major (CR-1.1-01: the log exposes every source's addresses to every USE user), 10 Minor, 12 Notes; post-fix pass: 2 new Minors (N-1, N-2) and 7 Notes. Three findings change design rules and needed a decision.
**Resolution:** The main role took the reviewer's recommended option for each, because AJ Ansari asked not to be interrupted (**to be confirmed by AJ Ansari; each is a small revert**): CR-1.1-01 option (a) — USE gets indirect read, page 60110 filters to the source tables the user may read; CR-1.1-02 — field 26 inherits CustomerContent; CR-1.1-04 option (a) — the country is part of the validated address, which supersedes the 1.0 decision OQ-14 ("the country does not count"); `CanModifyCustomers` kept (public 1.0 API). Fixed: CR-1.1-01, -02, -04, -05, -06, -07, -08, -14, -15, -16, -19, -22(1), N-1, N-2. Accepted: CR-1.1-11 and the Notes. Builds: main 1.1.0.4 then 1.1.0.5 (the country rule in the four propagation compares), test app 0.0.0.14 then 0.0.0.15, all 0 errors / 0 warnings; scorecard overall **C** (Security), no F; details in `docs/4-prove/CodeReview.md`. Pattern candidates P8–P10 flagged. Retest owed: nothing has been installed.
**Files affected:** src/Setup/OBCFGAVGAVUSE.PermissionSet.al, src/Validation/obcfgavLogEntries.Page.al, obcfgavValidationLog.Table.al, obcfgavValidationWriter.Codeunit.al, obcfgavAddressValidation.Codeunit.al, src/Sources/* (16 table extensions, 60135, 60139), src/Upgrade/obcfgavUpgradeContactFlag.Codeunit.al, app.json, test app src/* and app.json, docs/4-prove/CodeReview.md.
**Updated:** TDD — pending (Step 10: 15.9 field 26, 15.11 country, 15.15 USE `ri`); FRD — pending (Step 10: FR-8, FR-13/14, FR-18.4).

## Issue SC-1i — Steps 10 and 11 for 1.1 complete; release candidate decided; hand-off to Step 12 (AJ Ansari's instruction to run through Step 11, 2026-10-18)
**Problem:** Apply the Spec-stale classifications, re-baseline the FRD, write the as-built reference and the Step 11 documents for 1.1; answer the release-candidate question.
**Resolution:** Step 10 (writer agent, Sonnet 5.5): `docs/2-design/FRD.md` is the FRD 2.1 as-built baseline for 1.1.0.5 with Appendix C folded into sections 1–9 and the pointer to the pre-BUILD FRD (git commit b31d1e0); `docs/4-prove/PostDevTDD.md` Part F is the as-built reference (F-A..F-I, deviations F-1..F-16, 12 unproven platform behaviours); ProjectParameters corrected; the original TDD stays as the historical design; there is no TranslationGlossary (US wording). New open decisions numbered in the FRD: OQ-50 (Contact-source linked update, D3), OQ-51 (log read restriction, CR-1.1-01), OQ-52 (country rule, CR-1.1-04), all taken by the main role under AJ Ansari's instruction and **awaiting his confirmation**. Step 11 (writer agent, Sonnet 5.5): UserGuide, Documentation (schema diagram redrawn; SVG rendered with mermaid-cli, exit 0; the PNG render failed so the layout has not been seen), HumanUnitTestScript (TC-39..TC-42 added), Deployment, SandboxInstall, AutomatedTestGuide (131 rows reconciled with the code), AutomatedTestScripts, Acknowledgements, README. **Release candidate (Rule 6a, decided by the main role under AJ Ansari's instruction; confirm or change):** no renamed package — the last build, `outputAppPackage/Google_Address_Validator_1.1.0.5.app` (test app 0.0.0.15), is the candidate; fixes during the release test continue 1.1.0.6, 1.1.0.7 …; the package that passes Step 12 ships as it is. Package built: outputAppPackage/Google_Address_Validator_1.1.0.5.app (previous build 1.1.0.4). Schema: additive only → upload with Schema Sync Mode = Add. Install: you upload it — docs/4-prove/SandboxInstall.md, §1 updated for this build. Then: tell me the version and environment you installed; I record it as the last installed version. Usage rows for SC1-08..SC1-11 are in ProjectProgress (08 includes the parallel Code Review agent's tokens because the two windows overlapped).
**Files affected:** docs/2-design/FRD.md, docs/4-prove/*.md, README.md, docs/1-define/ProjectParameters.md, docs/0-project/Acknowledgements.md, ProjectProgress.md, ocpfFramework/state/usage.json.
**Updated:** TDD — no (historical, with the corrections in PostDevTDD F-F); FRD — yes.

## Issue SC-1j — Plain-language message when Google cannot confirm an address (AJ Ansari, 2026-10-18, from the first screenshot of the running app)
**Problem:** The message for a Not Found result showed Google's technical component names: "Google Maps could not confirm this address to the building. Missing or unconfirmed: street_number, postal_code." (AJ Ansari: not user-friendly). It showed that the app runs.
**Root cause:** `obcfgavGoogleAddressClient.Codeunit.al` put the raw `missingComponentTypes` / `unconfirmedComponentTypes` values into the user text.
**Resolution:** New text: "Google Maps couldn't confirm this address. Please check the street number and ZIP Code, then try again." (with no parts named: "…Please check it and try again."). Google's field names are mapped to plain words (street number, street name, apartment or suite number, building, city, neighborhood, state, county, ZIP Code, ZIP+4 extension, country, floor, PO box), de-duplicated and joined with "and"; unknown types fall back to the name with underscores replaced by spaces. The raw list is still stored in the buffer and in the log's Provider Message for support. Test library labels and the two provider tests updated. Main 1.1.0.7 (1.1.0.6 built with one analyzer warning, never installed) and test app 0.0.0.16 compile 0 errors / 0 warnings. This is the first evidence that 1.1 runs in a sandbox; **no installation record has been given, so the last installed version stays unrecorded until AJ Ansari says which build and environment.** Package built: outputAppPackage/Google_Address_Validator_1.1.0.7.app (previous build 1.1.0.6). Schema: additive only (no change since 1.1.0.5) → upload with Schema Sync Mode = Add. Install: you upload it — docs/4-prove/SandboxInstall.md, §1 updated for this build. Then: tell me the version and environment you installed; I record it as the last installed version.
**Files affected:** src/Validation/obcfgavGoogleAddressClient.Codeunit.al, app.json, test app (library, provider tests, app.json), user and test documents.
**Updated:** TDD — no; FRD — no (message wording only).

## Issue SC-1k — "Suggested Address - 0" title on the comparison dialog (AJ Ansari, 2026-10-18, from the second screenshot of the running app)
**Problem:** The dialog title read "Suggested Address - 0".
**Root cause:** Business Central appends the page's data caption — the primary key of the page's current record — to the title. The dialog's source table is the temporary Address Buffer whose key "Primary Key" is the integer 0, so the "0" was that key. It was already so in 1.0.0.0 (page 60112 was unchanged in this respect).
**Resolution:** Page 60112 sets `DataCaptionExpression = RecordCaption`, filled in `SetData` from the buffer's Source Description (table caption and key, never a name), so the title now reads, for example, "Suggested Address - Customer 10000". Main 1.1.0.8 compiles 0 errors / 0 warnings; the test app 0.0.0.16 is unaffected (the dialog's controls did not change). Not seen running: AJ Ansari to confirm on the next install. Package built: outputAppPackage/Google_Address_Validator_1.1.0.8.app (previous build 1.1.0.7). Schema: additive only (no change) → upload with Schema Sync Mode = Add. Install: you upload it — docs/4-prove/SandboxInstall.md, §1 updated. Then: tell me the version and environment you installed.
**Files affected:** src/Validation/obcfgavAddressCompare.Page.al, app.json, user and test documents (version).
**Updated:** TDD — no; FRD — no.

## Issue SC-2 — Google names for setup and log; the log shows Record No. instead of a blank Customer No. (AJ Ansari, 2026-10-18, from the third screenshot)
**Problem:** (1) The setup and log should say "Google Address ..." so they are easy to find. (2) The log page still led with a Customer No. column that is blank for vendors, employees and the other sources; it should show which table and a field holding the number of whatever record it is.
**Root cause:** The log kept the 1.0 column and a generic description; there was no source-neutral key field.
**Resolution:** Names: Setup page and table, setup wizard, assisted-setup title and short title, Log page and table, and the log action on every card now start with "Google Address Validation ..."; Tell Me search terms ("Google", "Google Maps", "address validation") on the Setup and Log pages. Log: new field 29 "Record No." (Text[100]) and buffer field 34, filled by `AddressSource.RecordKeyText` (the non-blank parts of the record's first key joined by " / ", for example `C00010 / MAIN`; blank for Company Information); the page shows Entry No., Source Table, Record No., Address Type, Checked At, User ID, Result, Accepted and the address columns, and hides Customer No., Source and Source Table No. (available through Personalization); field 2 "Customer No." stays in the table for the Customer Card's log action and 1.0 data (schema additive, Sync Mode Add); new upgrade codeunit 60140 (tag OBCFGAV-SC1-RecordNo-20261018) fills Record No. on existing rows. **Decision GF-04 (taken by the main role, recommended option; AJ Ansari to confirm):** Record No. is a snapshot as it was when the check ran and does not follow a later rename (the Customer Card still filters by Customer No., which does).
**Files affected:** src/Setup/* (captions, registration), src/Validation/obcfgavLogEntries.Page.al, obcfgavValidationLog.Table.al, obcfgavAddressBuffer.Table.al, obcfgavValidationWriter.Codeunit.al, src/Sources/obcfgavAddressSource.Codeunit.al, 16 page extensions, src/Upgrade/obcfgavUpgradeRecordNo.Codeunit.al and obcfgavUpgradeTags.Codeunit.al, test library, documents.
**Updated:** TDD — no (PostDevTDD F-17..F-19); FRD — yes (FR-5, FR-6, FR-16.6).

## Issue SC-2a — Review of SC-2 resolved; builds 1.1.0.10 / 0.0.0.18 (Reasoning role Opus 5.5, first line checked)
**Problem:** The Gap-Fit and Code Review of SC-2: 2 Major (CR-SC2-01 two Company Information tests failed on the new Record No. assertion; CR-SC2-02 the new assisted-setup title never reaches a company where the app is already installed), 6 Minor, 4 Notes; overall C (Correctness, Test coverage), no F.
**Resolution:** Fixed: CR-SC2-01 (the assertion now checks the exact value, the key parts joined by " / ", blank when the key is blank — it also tests the separator); CR-SC2-02 (the assisted-setup item is registered without the Exists guard and again by a subscriber to Guided Experience `OnRegisterAssistedSetup`; the System Application versions a changed item and keeps its Completed status, read in its source; the event publisher is `internal`, so whether our subscriber fires is proved only in the sandbox); CR-SC2-03/04 (60140 no longer filters on the field it changes, `SetLoadFields`, `ReadPermission` check); CR-SC2-05 (one `JoinKeyParts` shared by `Describe` and `RecordKeyText`); CR-SC2-06 (tooltip says snapshot and blank for Company Information); CR-SC2-07 (wizard `AdditionalSearchTerms` removed: a NavigatePage without UsageCategory is not a Tell Me page; documents corrected); CR-SC2-09 (field order); CR-SC2-08 (this entry and the Object Register). Accepted: CR-SC2-10..12 (Remit Address reads `REMIT / VENDOR` in key order; 60140 not in a permission set like 60137/60138; the enum, permission-set captions and tooltip phrases keep their wording). Both apps compile 0 errors / 0 warnings; main 1.1.0.9 and test app 0.0.0.17 exist in the package folders, never installed. Package built: outputAppPackage/Google_Address_Validator_1.1.0.10.app (previous build 1.1.0.9). Schema: additive only (field 29 on the log, field 34 on the temporary buffer) → upload with Schema Sync Mode = Add. Install: you upload it — docs/4-prove/SandboxInstall.md, §1 updated for this build. Then: tell me the version and environment you installed; I record it as the last installed version. Retest owed: nothing of SC-2 has been run.
**Files affected:** as in SC-2, plus src/Upgrade/obcfgavUpgradeRecordNo.Codeunit.al, src/Setup/obcfgavSetupRegistration.Codeunit.al, test library, documents.
**Updated:** TDD — no; FRD — yes.

## Issue SC-2b — GF-04 confirmed by AJ Ansari (2026-10-18)
**Decision:** AJ Ansari confirmed that Record No. on the Google Address Validation Log is a snapshot of the number as it was when the check ran and does not follow a later rename (the Customer Card's log action still follows a customer rename through Customer No.). Closes GF-04 / the "to confirm" note in SC-2.
**Files affected:** docs/0-project/ChangeLog.md, docs/0-project/ProjectMemory.md.
**Updated:** TDD — no; FRD — no.

## Issue SC-2c — Validate Address action icon changed to Map (AJ Ansari, 2026-10-18)
**Problem:** The Validate Address actions used `Image = CheckList`; AJ Ansari asked for `Map`.
**Resolution:** `Image = Map` on all 17 Validate Address / Validate Ship-to Address actions (Customer Card, the 15 other card extensions and Company Information's second action). The Address Validation Log actions keep `Image = Log`. Compiled 0 errors / 0 warnings (the compiler accepts `Map`). Not seen on screen. Main 1.1.0.11 (previous build 1.1.0.10); the test app 0.0.0.18 is unchanged (it does not use images). Package built: outputAppPackage/Google_Address_Validator_1.1.0.11.app (previous build 1.1.0.10). Schema: additive only (no change) → upload with Schema Sync Mode = Add. Install: you upload it — docs/4-prove/SandboxInstall.md, §1 updated. Then: tell me the version and environment you installed.
**Files affected:** 17 page extensions under src/, app.json, docs/4-prove/PostDevTDD.md, Documentation.md and the version references.
**Updated:** TDD — no; FRD — no.

## Issue SC-3 — Open decisions confirmed; US country code filled in on validation (AJ Ansari, 2026-10-18)
**Decisions (AJ Ansari):** (1) OQ-50 / D3 — keep as is: for a Contact source the update of linked records is part of the write, which is standard Business Central behaviour. (2) OQ-51 — go with the recommendation: the log read restriction stays. (3) OQ-52 — the country is part of the validated address, and AJ Ansari added a requirement: when an address is validated and it is a US address, populate the Country/Region Code as US; Canadian addresses as CA if Canada were validated. Answer recorded: Canada is **not** validated today — the engine accepts only a blank country or the setup's single US code, and the request to Google hard-codes region US. Google's Address Validation API covers about 40 region codes (US and Puerto Rico with USPS CASS, Canada, Mexico, much of Europe, Australia, New Zealand, Japan and India pre-GA, and others; list at developers.google.com/maps/documentation/address-validation/coverage), so other countries are possible; supporting Canada needs a list of allowed countries in Setup, the region sent per country, per-country postal-code and province checks, and USPS delivery data (DPV) is US-only. Not built: AJ Ansari has not asked for it. (4) Release candidate — the last build ships as it is; when ready AJ Ansari will delete all older package versions by hand and then tell the agent to squash the local and remote git history; **nobody squashes history or force-pushes until he says so**, and the agent never deletes packages.
**Resolution (code):** `AddressSource.SetUsCountryIfBlank` fills a blank Country/Region Code of the checked address block with the setup's "US Country/Region Code" on Accept and on Confirmed (for users who may modify the record); direct assignment without validation, so the indicator is not reset by it; a non-blank country is never changed and a Not Found never fills it; the linked Contact/Resource gets the country through the standard update (Accept, and Confirmed when the linked indicator differs). Customer change number 6 (FR-18.6). Tests added: `TestAcceptSetsUsCountry`, `TestConfirmedSetsUsCountry`, `TestNotFoundKeepsBlankCountry` (134 in all). Main 1.1.0.12 (previous build 1.1.0.11) and test app 0.0.0.19 compile 0 errors / 0 warnings; nothing run. Package built: outputAppPackage/Google_Address_Validator_1.1.0.12.app (previous build 1.1.0.11). Schema: additive only (no change) → upload with Schema Sync Mode = Add. Install: you upload it — docs/4-prove/SandboxInstall.md, §1 updated for this build. Then: tell me the version and environment you installed; I record it as the last installed version.
**Files affected:** src/Sources/obcfgavAddressSource.Codeunit.al, src/Validation/obcfgavValidationWriter.Codeunit.al, app.json, test app src/obcfgavSourceTests.Codeunit.al and app.json, documents.
**Updated:** TDD — no; FRD — yes (FR-18.6, confirmed decisions, non-US scoped out).

## Issue SC-4 — Address validation in the 40 countries Google covers (AJ Ansari, 2026-10-18)
**Problem:** Validation was US only. AJ Ansari asked for all 40 countries Google's Address Validation API covers, the supported countries shown in Business Central and in the documents, and the record's country filled in from the validated address (US for the USA, CA for Canada, DE for Germany, ...). Costs: the same Address Validation Pro SKU in every country (5,000 free requests a month then about $17 per 1,000; India has its own SKU with 35,000 free), so the free cap is shared by all countries.
**Resolution (main 1.2.0.0 built, then 1.2.0.1 after the review; Reasoning role Opus 5.5 reviewed the whole delta, first line checked):** New table 60141 `Supported Country` (region code, name, enabled, preview, residential data, USPS delivery data), seeded with the 40 regions, **all enabled** (AJ Ansari's choice), on install, company initialization and upgrade (60148, tag OBCFGAV-SC4-Countries-20261018); list page 60142 "Google Address Validation Supported Countries" (only Enabled editable) reachable from Setup; codeunit 60147 `Country Mgt.` (BC country code → ISO region through the Country/Region ISO Code, `UK` → `GB`, a 2-letter code as is; region classes; enabled/not-covered checks; the BC code for a region). The Setup field "US Country/Region Code" keeps its name and now has the caption "Default Country/Region Code": it is the country assumed for a blank record country and is blank-able (blank = let Google infer). The request sends `regionCode` from the record's country, else the default, else none, and `enableUspsCass` only for US/PR; a result region different from the hinted region is a Not Found (US and PR count as the same class); a blank-country record whose result region is not supported or not enabled is a Not Found. Per-region preconditions: US/PR (state code, ZIP or city+state), CA (province code, postal code A1A 1A1 or city+state), every other country (street plus city or postal code, no state rule). For countries outside US/CA/PR a suggestion without state, city or postal code keeps the record's own value; address lines after the first (and `sublocality`) become Address 2. The country is filled in on Accept and on Confirmed from the result region, else the hint (replaces the US-only fill of SC-3); the comparison dialog shows the country that will be filled in. Wording is country-neutral ("State / Province", "ZIP / Postal Code"). Review findings fixed: US/PR mismatch regression, blanking of City or ZIP outside US/CA, Address 2 loss, missing-ISO-Code message, BC-code choice order, USE-only seeding guard, classification, wording. Tests: new codeunit 60131 (15 tests) and two refusal tests moved from CA to RU; test app 0.0.0.21. Both apps compile 0 errors / 0 warnings.
**Decisions taken by the main role, recommended options, awaiting AJ Ansari's confirmation:** (1) the Minor version bump to **1.2.0.x** (new feature; no 1.2.0.0 package has been installed; 1.1.0.13 would be possible but would leave a higher-numbered package in the folder); (2) the 1.0.0.0 message texts for incomplete address and state code, and the State/ZIP captions, are now country-neutral, and two existing tests moved from CA to RU — this breaks the FRD commitment that all 1.0.0.0 texts stay verbatim (FR-18 intro), accepted because the old texts name the US; (3) Brazil, Mexico, India and Japan stay enabled although their address shapes (district/sublocality, preview status) are not proven against live responses: a live probe per country is recommended before relying on them (an administrator can turn a country off on the Supported Countries page); (4) the dialog shows the country that will be filled in. Not done: warning on a Setup default that is not covered (review m8), the mismatch message wording when the hint comes from the default (m3), names resolved through the Country/Region record (m6), logging the regions (N5).
**Process:** no pre-build Sanity Check (the design was settled in conversation); the combined Gap-Fit and Code Review ran after the build. Package built: outputAppPackage/Google_Address_Validator_1.2.0.1.app (previous build 1.2.0.0). Schema: additive only (new table 60141, buffer fields 35–37 on the temporary buffer, Setup caption only) → upload with Schema Sync Mode = Add. Install: you upload it — docs/4-prove/SandboxInstall.md, §1 updated for this build. Then: tell me the version and environment you installed; I record it as the last installed version.
**Files affected:** src/Setup (table, page, codeunit registration, permission sets, Setup page and table), src/Sources/obcfgavCountryMgt.Codeunit.al, obcfgavAddressSource.Codeunit.al, src/Upgrade (tags, countries), src/Validation (validation, Google client, buffer, dialog, log wording, writer), test app (library, 60131, two tests), documents.
**Updated:** TDD — no (PostDevTDD Part G); FRD — yes (FR-19, FR-18.6).

## Issue SC-4a — India key and cost clarified; the not-covered message accepted (AJ Ansari, 2026-10-18)
**Question:** does India need a new API key? **Answer:** no. The same Google Cloud project and key serve every country; Google's release notes (July 25, 2024) only say India is a preview feature, and nothing in them or in the pricing categories page names a separate key, endpoint or request for India. **Correction of my earlier statement:** India does not have "its own SKU" for requests: Google's pricing page gives a higher free allowance (Pro 35,000 requests a month, instead of 5,000) to billing accounts that are billed at India pricing, so it depends on the billing account, not on the address country. Corrected in the FRD, UserGuide, Documentation, Deployment, GoogleSetupGuide and README. **Decision (AJ Ansari):** the message "Google Maps can't validate addresses in <country>" is accepted as written.
**Files affected:** the documents above, docs/0-project/ChangeLog.md.
**Updated:** TDD — no; FRD — yes (cost wording).

## Issue SC-4b — Assisted Setup and Setup page brought in line with the 40 countries (AJ Ansari's question, 2026-10-18)
**Problem:** After SC-4 the Setup page already had the Default Country/Region Code and a Supported Countries action, but the setup wizard still said nothing about countries or the privacy effect of all 40 being on, the Supported Countries action was not promoted, and a default country that cannot be validated (not covered, turned off, or without an ISO Code) was accepted silently.
**Resolution:** Wizard welcome text now says one key works for every country Google supports; the scope text says the default country and the country switches are on the Google Address Validation Setup page, that all supported countries are on after installation and that addresses in them, including those of employees and contacts, can be sent to Google, and to turn off the countries not wanted. Setup page: the Supported Countries action is promoted next to Test Connection; changing the Default Country/Region Code shows a message when it is not covered, turned off or lacks an ISO Code (the value is still saved). No schema change. Main 1.2.0.2 (previous build 1.2.0.1) compiles 0 errors / 0 warnings; the test app 0.0.0.21 is unchanged. Package built: outputAppPackage/Google_Address_Validator_1.2.0.2.app (previous build 1.2.0.1). Schema: additive only (no change) → upload with Schema Sync Mode = Add. Install: you upload it — docs/4-prove/SandboxInstall.md, §1 updated. Then: tell me the version and environment you installed. Note: the assisted-setup tile text is unchanged here; the wizard body text changes only affect the page, so they reach every company with the new build.
**Files affected:** src/Setup/obcfgavSetupWizard.Page.al, obcfgavSetup.Page.al, app.json, documents (version).
**Updated:** TDD — no; FRD — no (review item m8 is now done).

## Issue SC-5 — Blank country is worked out from the address (AJ Ansari's test of a Danish address in a US company, 2026-10-18)
**Problem:** A Danish address with no country, in a company whose default country is US, was sent to Google as a US address (the default was the region hint), so it could not resolve to Denmark.
**Root cause:** In SC-4 a blank record country always took the Setup default as the region hint; Google inference was only used when the default was blank.
**Resolution:** New Setup field 6 "Blank Country Handling" (enum 60149: **Let Google decide** = 0, the default for new and upgraded installs, or **Use default country**). With Let Google decide, a record without a country is recognized as US when its state is a US state or territory code and its ZIP code has 5 or 9 digits (so USPS data is still requested), as Canada when its postal code looks like A1A 1A1, and otherwise no region is sent and Google works the country out from the address; the result region (must be supported and enabled, else Not Found) is mapped to the BC Country/Region and filled in on Accept and Confirmed (SC-4). With Use default country the behaviour is the one of 1.2.0.0–1.2.0.2. `CountryMgt.RegionForRecord` replaces `RegionForCheck` for records (the Setup page still uses `RegionForCheck` for its default-country warning); `HasUsableCanadianPostalCode` moved into Country Mgt. No other schema change (one new field on the Setup table, one new enum). Tests: four new tests in 60131 (Danish address inferred, US shape hints US with USPS CASS, Canadian postal code hints CA, Use default sends the default); the library's `InitSetup` selects Use default country so the 1.0/1.1 tests keep their meaning; 153 tests in all; test app 0.0.0.22. Main 1.2.0.3 (previous build 1.2.0.2) and test app compile 0 errors / 0 warnings. Not proven: Google's real inference for a Danish address (live probe needed); the US-state heuristic cannot tell an address in another country that happens to use a US state code and a 5-digit postal code (set the country on such records). Package built: outputAppPackage/Google_Address_Validator_1.2.0.3.app (previous build 1.2.0.2). Schema: additive only (new field 6 on the Setup table) → upload with Schema Sync Mode = Add. Install: you upload it — docs/4-prove/SandboxInstall.md, §1 updated. Then: tell me the version and environment you installed; I record it as the last installed version.
**Files affected:** src/Setup (enum 60149, Setup table and page), src/Sources/obcfgavCountryMgt.Codeunit.al, src/Validation/obcfgavAddressValidation.Codeunit.al, app.json, test app (library, 60131, app.json), documents.
**Updated:** TDD — no (PostDevTDD Part G); FRD — yes (FR-19).

## Issue SC-5a — Review of SC-5 resolved; builds 1.2.0.4 / 0.0.0.23 (Reasoning role Opus 5.5, first line checked; decisions by the main role under AJ Ansari's standing instruction, to be confirmed)
**Problem:** Review of SC-5: one new test could not pass (`TestBlankCountryUseDefaultSendsDefault` stopped at the US input rule), the US-state shortcut collides with Italian province codes (MI, PA, CA, AL, ... with a 5-digit CAP look US), the upgrade silently switched existing Setup rows to Let Google decide, Use default country with a blank default no longer behaved as in 1.2.0.2, tooltips were out of date, and the ChangeLog/Object Register claims were incomplete (the Object Register did not list enum 60149; SandboxInstall §1 and the FRD were not updated in the SC-5 commit, contrary to what SC-5 said).
**Decisions (recommended options):** (1) Existing tenants switch to **Let Google decide** with **no upgrade step** (Standards §9.1: meaning of field 4 changes for upgraded setups; recorded here; Deployment notes tell administrators to review Blank Country Handling; AJ Ansari's own sandbox is the only installed tenant). (2) **Retry once without a region** when a heuristically guessed region (US from state+ZIP, CA from postal code) ends in Not Found — one extra billable request only in that case — instead of restricting the heuristic. (3) A US record without a recognizable state and ZIP shape gets no USPS data under Let Google decide: accepted and documented (US-only companies can choose Use default country). (4) Military codes AA, AE, AP added to the US list; territories GU, VI, AS, MP not added (Google does not cover dependent territories). Enum 60149 `Extensible = false` (closed two-value setting, recorded decision).
**Resolution:** `RegionForRecord` returns whether the region was inferred; `RunValidation` retries once with no region (buffer refilled) when an inferred region gives Not Found; Use default country with a blank default sends no region and does not guess; tooltips reworded; tests: the Use-default test now uses ZIP 15500 (passes the US rule, does not look US), new `TestBlankCountryUseDefaultBlankDefaultSendsNoRegion` and `TestItalianProvinceRetriesWithoutRegion` (155 tests in all). Main 1.2.0.4 (previous build 1.2.0.3) and test app 0.0.0.23 compile 0 errors / 0 warnings. Not proven: Google's real answers (Danish, Italian, and the first-attempt result for a collision address). Package built: outputAppPackage/Google_Address_Validator_1.2.0.4.app (previous build 1.2.0.3). Schema: additive only (no change since 1.2.0.3) → upload with Schema Sync Mode = Add. Install: you upload it — docs/4-prove/SandboxInstall.md, §1 updated for this build. Then: tell me the version and environment you installed; I record it as the last installed version.
**Files affected:** src/Sources/obcfgavCountryMgt.Codeunit.al, src/Validation/obcfgavAddressValidation.Codeunit.al, src/Setup/obcfgavSetup.Page.al, app.json, test app (60131, app.json), documents.
**Updated:** TDD — no; FRD — yes (FR-19.3, FR-19.5).

## Issue 12-3 — Release round for 1.2.0.4 passed; automated tests skipped (AJ Ansari, 2026-10-19)
**Problem:** The 155 automated tests could not be run in pocSandbox through the AL MCP.
**Root cause:** `al_auth_login`/`al_publish` fail inside the server with a missing ASP.NET data-protection key (log: "The key {a44b976c-…} was not found in the key ring"); `al_run_tests` was denied by the permission classifier; no TEST-named company exists in pocSandbox and no tool creates one.
**Resolution:** AJ Ansari skipped the automated run and reported all manual tests passed. Step 12 closed for SC-1..SC-5 on 1.2.0.4. An empty `TokenCache.dat` was renamed to `TokenCache.dat.stale-20261019` (no effect).
**Files affected:** docs/4-prove/ReleaseTestResults.md (§7), ProjectProgress.md.
**Updated:** TDD — no; FRD — no.

## Issue 12-4 — Online help page and `help` link (AJ Ansari, 2026-10-19)
**Problem:** The app had no help link and the guides were Markdown only.
**Root cause:** Not part of the original scope.
**Resolution:** `docs/help/index.html` (built by `docs/help/build.py` from `docs/4-prove/UserGuide.md`, `Documentation.md` and `GoogleSetupGuide.md`, with the app icon, the OnlyBCFans day logo and the banner style in day mode; internal review codes and build-status notes are left out of the page). `app.json` `help` = `https://ajansari.github.io/GoogleAddressValidator/help/` (needs GitHub Pages on `main` /docs); version 1.2.0.5, compiled 0/0, package built. No AL code changed, so Steps 09–11 are not re-run. Exception to "the tested package ships as it is": 1.2.0.5 differs from the tested 1.2.0.4 only in `app.json`; AJ Ansari decides which ships.
**Files affected:** app.json, docs/help/*, README.md, docs/4-prove/ReleaseTestResults.md.
**Updated:** TDD — no; FRD — no.

## Issue FW-3 — Framework updated 5.8.0.0 → 5.8.2.0 (AJ Ansari, 2026-10-19)
**Problem:** A newer runbook was published (5.8.1.0 and 5.8.2.0).
**Resolution:** Runbook (`CLAUDE.md`), changelog, step files, document templates, Ops Guide 5.8.2.0, Standards Guide v1.13.1.0 (was v1.12.1.0), scripts and dashboard templates replaced; old runbook and changelog saved in `ocpfFramework/state/previous/`. Sub-agent definitions were already identical to the new ones and kept with their models. No file moves (layout already current). Notable for this project: 5.8.1.0 allocates object IDs per object type (Standards §5.0, Ops § Object IDs) and moves agent-run tests to the roadmap (the human runs them) — read both before the planned renumbering to 92800+.
**Files affected:** CLAUDE.md, ocpfFramework/*.
**Updated:** TDD — no; FRD — no.

## Issue SC-6 — Renumbering to 92800+ per object type, version 1.3.0.0 (AJ Ansari, 2026-10-19)
**Problem:** AJ Ansari wanted the app in his own range, starting at 92800, and under the new per-type rule (Standards §5.0, Ops § Object IDs, framework 5.8.1.0).
**Resolution:** Every object ID rewritten per object type, in the old ID order: main app 92800–92829 (`app.json` `idRanges` `[92800–92829]`; highest used: codeunit 92816), test app 92830–92849. Field numbers on the standard tables 60093 → 92800 and 60094 → 92801. The AddressSource codeunit's shared field numbers and the test library's field numbers follow. No other code changed. Version 1.3.0.0 (test app 0.0.0.24, dependency 1.3.0.0). Compiled 0 errors, 0 warnings with the PTE analyzers (both apps). Per-type check (Ops § Object IDs) passes: each type is exactly the first *n* IDs of its range. The living documents (FRD, PostDevTDD, ObjectRegister (regenerated from the code with a *Was* column), ProjectParameters, Documentation, UserGuide, test guides, Deployment, SandboxInstall, README) were rewritten; the TDD, BuildPlan, SanityCheck, GapAnalysis, CodeReview, ChangeLog, estimates and the archived USPS-build documents are historical records and keep the old numbers, which map through the table below.
**Deployment impact:** Every table ID and field ID changed, so a tenant with 1.2.x or earlier needs Force Sync (data in the old Setup, Log, Buffer, Supported Country tables and the Address Validated columns is dropped; the API key and permission assignments survive) or uninstall with data deletion. A first production install is unaffected. Recorded in `docs/4-prove/Deployment.md` §1 and `docs/4-prove/SandboxInstall.md` §1.
**Package decision:** AJ Ansari chose 1.3.0.0 as the shipping package. It differs from the manually tested 1.2.0.4 only by the renumbering and the help link, so a sandbox install and a repeat of the manual cases is needed before production (ReleaseTestResults §8).
**Files affected:** src/ (all 64 objects), app.json, the test app (src and app.json), docs (above).
**Updated:** TDD — no (historical); FRD — yes (ID statements).

Old → new object IDs:

| Type | Old ID | New ID | Name |
|---|---|---|---|
| codeunit | 60098 | 92800 | obcfgav Credential Mgt. |
| codeunit | 60099 | 92801 | obcfgav Install |
| codeunit | 60100 | 92802 | obcfgav Setup Registration |
| codeunit | 60113 | 92803 | obcfgav Address Validation |
| codeunit | 60114 | 92804 | obcfgav Address Service |
| codeunit | 60115 | 92805 | obcfgav Http Transport Impl. |
| codeunit | 60118 | 92806 | obcfgav Validation Writer |
| codeunit | 60119 | 92807 | obcfgav Google Address Client |
| codeunit | 60120 | 92808 | obcfgav Write Guard |
| codeunit | 60135 | 92809 | obcfgav Address Source |
| codeunit | 60136 | 92810 | obcfgav Upgrade Tags |
| codeunit | 60137 | 92811 | obcfgav Upgrade Log Source |
| codeunit | 60138 | 92812 | obcfgav Upgrade Contact Flag |
| codeunit | 60139 | 92813 | obcfgav Address Sync Subscr. |
| codeunit | 60140 | 92814 | obcfgav Upgrade Record No. |
| codeunit | 60147 | 92815 | obcfgav Country Mgt. |
| codeunit | 60148 | 92816 | obcfgav Upgrade Countries |
| enum | 60093 | 92800 | obcfgav Validation Result |
| enum | 60094 | 92801 | obcfgav Address Provider |
| enum | 60134 | 92802 | obcfgav Address Type |
| enum | 60149 | 92803 | obcfgav Blank Country Handling |
| page | 60096 | 92800 | obcfgav Setup |
| page | 60097 | 92801 | obcfgav Setup Wizard |
| page | 60110 | 92802 | obcfgav Log Entries |
| page | 60112 | 92803 | obcfgav Address Compare |
| page | 60142 | 92804 | obcfgav Supported Countries |
| pageextension | 60117 | 92800 | obcfgav Customer Card |
| pageextension | 60144 | 92801 | obcfgav Ship-to Address Card |
| pageextension | 60146 | 92802 | obcfgav Cust. Bank Acc. Card |
| pageextension | 60153 | 92803 | obcfgav Vendor Card |
| pageextension | 60155 | 92804 | obcfgav Order Address Card |
| pageextension | 60157 | 92805 | obcfgav Remit Address Card |
| pageextension | 60159 | 92806 | obcfgav Vendor Bank Acc. Card |
| pageextension | 60166 | 92807 | obcfgav Company Info. Card |
| pageextension | 60168 | 92808 | obcfgav Location Card |
| pageextension | 60170 | 92809 | obcfgav Resp. Center Card |
| pageextension | 60172 | 92810 | obcfgav Bank Account Card |
| pageextension | 60179 | 92811 | obcfgav Employee Card |
| pageextension | 60181 | 92812 | obcfgav Alt. Address Card |
| pageextension | 60183 | 92813 | obcfgav Contact Card |
| pageextension | 60185 | 92814 | obcfgav Cont. Alt. Addr. Card |
| pageextension | 60187 | 92815 | obcfgav Resource Card |
| permissionset | 60101 | 92800 | OBCFGAV GAV, USE |
| permissionset | 60102 | 92801 | OBCFGAV GAV, ADMIN |
| table | 60095 | 92800 | obcfgav Setup |
| table | 60109 | 92801 | obcfgav Validation Log |
| table | 60111 | 92802 | obcfgav Address Buffer |
| table | 60141 | 92803 | obcfgav Supported Country |
| tableextension | 60116 | 92800 | obcfgav Customer |
| tableextension | 60143 | 92801 | obcfgav Ship-to Address |
| tableextension | 60145 | 92802 | obcfgav Customer Bank Account |
| tableextension | 60152 | 92803 | obcfgav Vendor |
| tableextension | 60154 | 92804 | obcfgav Order Address |
| tableextension | 60156 | 92805 | obcfgav Remit Address |
| tableextension | 60158 | 92806 | obcfgav Vendor Bank Account |
| tableextension | 60165 | 92807 | obcfgav Company Information |
| tableextension | 60167 | 92808 | obcfgav Location |
| tableextension | 60169 | 92809 | obcfgav Responsibility Center |
| tableextension | 60171 | 92810 | obcfgav Bank Account |
| tableextension | 60178 | 92811 | obcfgav Employee |
| tableextension | 60180 | 92812 | obcfgav Alternative Address |
| tableextension | 60182 | 92813 | obcfgav Contact |
| tableextension | 60184 | 92814 | obcfgav Contact Alt. Address |
| tableextension | 60186 | 92815 | obcfgav Resource |
| codeunit | 60123 | 92830 | obcfgav Fake Http Transport |
| codeunit | 60124 | 92831 | obcfgav Test Library |
| codeunit | 60125 | 92832 | obcfgav Validation Tests |
| codeunit | 60126 | 92833 | obcfgav Provider Tests |
| codeunit | 60127 | 92834 | obcfgav Addr Validated Tests |
| codeunit | 60128 | 92835 | obcfgav Fake Address Provider |
| codeunit | 60129 | 92836 | obcfgav Source Tests |
| codeunit | 60130 | 92837 | obcfgav Sync Tests |
| codeunit | 60131 | 92838 | obcfgav Country Tests |

## Issue SC-7 — Default country asked in Assisted Setup; kept API key; app.json brief and description; build 1.3.0.1 (AJ Ansari, 2026-10-19)
**Problem:** The Default Country/Region Code was preset to US by `InitValue` on the Setup table and was not asked anywhere in Assisted Setup; running the wizard again showed an empty API key; `app.json` had no brief or description.
**Root cause:** SC-4 changed the field's meaning but kept the 1.0 `InitValue = 'US'`; the wizard was never extended past the API key.
**Resolution:** Setup field 4 has no initial value; field 6 Blank Country Handling states `InitValue = "Let Google decide"`. The wizard (page 92801) has a new **Countries** step (Default Country/Region Code, Blank Country Handling) on a temporary copy of the setup record, saved on Finish; it shows the saved API key masked on a repeat run and does not overwrite it unless it was typed over. `app.json` brief (76 characters) and description (178). Version 1.3.0.1 compiled 0 errors, 0 warnings. Existing setups keep their stored value (an installed US stays US); no upgrade step. No schema change (Add is enough over 1.3.0.0). The automated tests were not changed (they set the country explicitly) and were not run.
**Files affected:** src/Setup/obcfgavSetup.Table.al, src/Setup/obcfgavSetupWizard.Page.al, app.json, UserGuide, Documentation, PostDevTDD, FRD, HumanUnitTestScript (TC-02), Deployment, SandboxInstall.
**Updated:** TDD — no; FRD — yes (wizard rows).

## Issue SC-8 — Website URL missing from build 1.3.0.1; build 1.3.0.2 (AJ Ansari, 2026-10-19)
**Problem:** AJ Ansari added `url` to `app.json` at 02:11:03, after the 1.3.0.1 package was compiled (02:10:20), so 1.3.0.1 has an empty URL.
**Resolution:** Revision bump to 1.3.0.2 (mechanical) and a new package with `url` = https://github.com/ajansari/GoogleAddressValidator/. No code change. 1.3.0.1 was never installed. Compiled 0 errors, 0 warnings.
**Files affected:** app.json, Deployment, SandboxInstall, README.
**Updated:** TDD — no; FRD — no.

## Issue SC-9 — Help folder moved from docs/help to help/ at the repository root (AJ Ansari, 2026-10-19)
**Problem:** The help page needed to live at the repository root.
**Resolution:** `git mv docs/help help`; `help/build.py` resolves the repository root one level up (run `python3 help/build.py`); README updated. Earlier entries (SC-6 etc.) name the old path. The `help` URL in `app.json` is unchanged (`https://ajansari.github.io/GoogleAddressValidator/help/`) because it works when GitHub Pages is served from the **root** of `main` (Settings → Pages → Deploy from branch → `main` / `/ (root)`), not from `/docs`. Exception to Operating Rule 9 (nothing else in the project root): AJ Ansari's decision. No package change.
**Files affected:** help/*, README.md, docs/4-prove/ReleaseTestResults.md.
**Updated:** TDD — no; FRD — no.

## Issue SC-10 — Help page moved into docs/ (AJ Ansari, 2026-10-19; replaces SC-9)
**Problem:** GitHub Pages "Deploy from a branch" can only publish `/ (root)` or `/docs`; AJ Ansari chose `/docs`.
**Resolution:** `index.html`, `template.html`, `build.py` and `assets/` moved from `help/` straight into `docs/` (`git mv`); `help/` no longer exists, so the project root is back to the Operating Rule 9 layout. `docs/build.py` finds the repository root one level up (`python3 docs/build.py`). With Pages on `main` / `/docs` the page is the site root, so `app.json` `help` is now `https://ajansari.github.io/GoogleAddressValidator/` (it was `.../help/`). Version 1.3.0.3 (1.3.0.2 would have carried the old link), compiled 0 errors, 0 warnings; the manifest `Help` and `Url` were read back from the package. Nothing installed. Earlier entries name the old paths.
**Files affected:** docs/index.html, docs/template.html, docs/build.py, docs/assets/, app.json, README, Deployment, SandboxInstall.
**Updated:** TDD — no; FRD — no.
