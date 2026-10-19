# Gap-Fit Analysis — USPS Address Validator

**Date:** 2026-10-16 · **Compared by:** Reasoning role, Opus 5.5 · **Recorded by:** Main role (Sonnet 5.5), for AJ Ansari
**Compared:** `docs/2-design/FRD.md` v1.2 (§1–§9; the CR-1 v2.0 draft in §10 is excluded, sign-off pending) · `docs/2-design/TDD.md` v1.0 (§1–§13; the CR-1 draft in §14 is excluded) · as-built at commit af839f4 (main app 0.0.0.2; test app 0.0.0.1 in the sibling repository at 1dd0b9f) · `docs/0-project/ChangeLog.md` through Issue 07-WAIVER

## 1. Three-way comparison
| # | Requirement / design element | FRD | TDD | As built | Gap? |
|---|---|---|---|---|---|
| 1 | Validate Address (USPS) action: promoted and under Functions; saves the card first | FR-1.1–1.2 | §4.15 | `obcfuspsCustomerCard.PageExt.al:23-46`: SaveRecord, Commit, Category_Process actionref | No |
| 2 | Preconditions in order; nothing sent and nothing logged on failure | FR-1.3, FR-7 | §4.13 CheckPreconditions | `obcfuspsAddressValidation.Codeunit.al:102-143`, messages returned before any call | No |
| 3 | Token reuse; name and number never sent | FR-1.4, §5 | §4.12 | `obcfuspsUSPSAPIClient.Codeunit.al:127-139, 202-230` | No |
| 4 | Outcomes Confirmed / Suggestion / Not Found / Error | FR-2 | §4.13, §13.1 | `obcfuspsAddressValidation.Codeunit.al:29-73, 196-237` | No |
| 5 | What counts as different (trim, case, +4) | FR-3 | §4.13 ValuesDiffer | `obcfuspsAddressValidation.Codeunit.al:75-78, 156-169`; ZIP+4 joined `obcfuspsUSPSAPIClient.Codeunit.al:307-311` | No |
| 6 | Comparison dialog: bold rows, delivery notes, D/S/N warning, OK = Accept, Cancel/Esc = Ignore, reason when blocked | FR-4 | §4.9, §11 Q1 | `obcfuspsUSPSAddressCompare.Page.al` | No |
| 7 | Accept writes five values as returned, no Post Code lookup, no truncation, concurrency check, flag = Yes | FR-4 | §4.13 AcceptSuggestion, §13.1.2 | `obcfuspsValidationWriter.Codeunit.al:67-98` (direct assignment, Modify(true)) | **G3** (blank values are accepted) |
| 8 | Customer write and log row in one transaction; write failure logged as Error | FR-4, FR-7 | §13.1.2–3 | `obcfuspsAddressValidation.Codeunit.al:210-237` (Writer.Run, LogWriteFailure) | **G6** |
| 9 | Log fields, read-only, ADMIN delete, newest first, per-customer action, data classification | FR-5 | §4.6, §4.7, §10 | `obcfuspsUSPSValidationLog.Table.al`, `obcfuspsUSPSLogEntries.Page.al`, page extension `:48-58` | No (G2 touches who can insert) |
| 10 | Error row committed before the error is shown | FR-5 | §4.13(4), §13.1.4 | `obcfuspsAddressValidation.Codeunit.al:22-23, 204-206` | No (G5 is the residual risk) |
| 11 | Retention Policy: custom 2 years, created disabled | FR-5, OQ-8 | §4.16 | `obcfuspsSetupRegistration.Codeunit.al:20-39` | No |
| 12 | Setup card: Enabled, Environment, TEM note, US code, Timeout, masked key, write-only secret, Test Connection | FR-6 | §4.3, §4.4, §13.7 | `obcfuspsUSPSSetup.Table.al`, `obcfuspsUSPSSetup.Page.al` | No |
| 13 | Credentials as secrets in isolated storage, company scope; encrypted when on | FR-6 | §4.11, §13.3 | `obcfuspsUSPSCredentialMgt.Codeunit.al:107-119` | No |
| 14 | Token cache: company scope, 60 s before USPS expiry, cleared on key, secret or environment change | FR-6 | §4.11 | `obcfuspsUSPSCredentialMgt.Codeunit.al:10-25, 60-105`; `obcfuspsUSPSSetup.Table.al:26-32` | No |
| 15 | Assisted Setup wizard: key and secret only; complete once both saved | FR-6, OQ-16 | §4.5, §4.16 | `obcfuspsUSPSSetupWizard.Page.al`, `obcfuspsSetupRegistration.Codeunit.al:41-52`, `obcfuspsUSPSCredentialMgt.Codeunit.al:121-127` | No |
| 16 | Error handling and messages; one token refresh only | FR-7 | §4.12 status table | `obcfuspsUSPSAPIClient.Codeunit.al:147-166, 249-281` | **G7, G8** (FRD wording) |
| 17 | Address Validated rules (set, reset, unchanged, edit reset) | FR-8 | §4.14, §13.4 | `obcfuspsCustomer.TableExt.al`, `obcfuspsValidationWriter.Codeunit.al:100-114` | **G2** (can be bypassed) |
| 18 | USPS-specific logic in one place | §5 | §6 (URLs, JSON, status codes in 60114) | 60114 holds URLs, JSON and status codes; DPV interpretation sits in 60112, the environment enum and token cache in 60094/60095/60098 | **G14** (Intentional) |
| 19 | One customer per user action (no batch) | §5 | §4.12 `Access = Public` | 60114 `ValidateAddress` is callable by any extension | **G4** |
| 20 | Permission sets USE / ADMIN | §5, §6, OQ-11 | §10 | `OBCFUSPSUSPSUSE.PermissionSet.al`, `OBCFUSPSUSPSADMIN.PermissionSet.al`: line-for-line equal to TDD §10 | No |
| 21 | Identity, IDs, enums, labels | §5 | §1, §2, §7 | Namespace and prefix on every file; IDs inside `app.json` idRanges; labels as in §7 plus the logged additions | **G9, G10** (TDD counts and folder name) |
| 22 | Object inventory | §6 | §4, §12 | 25 objects with IDs plus 1 interface, all built | **G13** (Intentional additions) |
| 23 | At most two HTTPS calls per check | §7 | §4.12 (worst case 3) | `obcfuspsUSPSAPIClient.Codeunit.al:73-83` | **G7** |
| 24 | Acceptance tests and test app | §7.2 | §12a, §13.5 | 24 automated tests built (FRD 1–10, 15–18, 20; A1–A7), never run | **G15** |
| 25 | Live USPS contract (TEM and production) | §7.2 | §13.8 F11, §13.9.1 | Never exercised | **G16** |
| 26 | Platform checks to do in a sandbox (Contact sync, US captions, HttpClient default) | §4.1 h, OQ-19, OQ-20 | §13.7 F12, F28 | Not done (no sandbox install, 07-WAIVER) | **G17** |
| 27 | Languages: en-US only, no translation files | §8 | §7 | `Translations/` holds only the generated `USPS Address Validator.g.xlf` (ignored by `*.g.xlf`) and `.gitkeep`. No target file, and no file for a language out of scope | No |
| 28 | CR-1 provider change (Google) | §10 (draft) | §14 (draft) | Not built | **G1** (Intentional) |

## 2. Gaps
Classification per `ocpfFramework/runbookSteps/08.md`: **Intentional** (the reasoning is recorded), **Oversight** (fixed now through Steps 05–07, or scheduled in `docs/0-project/Roadmap.md`), **Spec stale** (the code is right and the FRD/TDD need updating — recorded here, applied at Step 10).

| # | Gap | Classification | Why | Resolution | ChangeLog / Roadmap ref | Decided by |
|---|---|---|---|---|---|---|
| G1 | CR-1 (Google provider, FRD §10 / TDD §14) is not in the code | Intentional | ChangeLog CR-1: documents are amended and signed off "before any code changes"; sign-off is pending | No action at Step 08. If CR-1 is signed off it goes through the remediation window `07a` (Ops § Usage & Cost → 7), not as a gap fix | CR-1 | AJ Ansari (2026-10-11, direction) |
| G2 | Codeunit 60118 "obcfusps Validation Writer" is `Access = Public` (`obcfuspsValidationWriter.Codeunit.al:7`). Any extension can call `Init(...)` + `Run()` to set Address Validated = Yes on any customer with no USPS check, or call `InsertLogEntry(...)` (`:38-65`) to write a forged log row. The insert runs on the Writer's own `Permissions = tabledata log = i` (`:8`). This breaks FRD §5 "Address Validated is changed only by the extension, under the rules in FR-8", and FR-5 / FRD §6 "inserted by the extension only" | Oversight | TDD §13.1.2 does not state Access for 60118; the generator chose Public. The test app does not call 60118 | Scheduled: fold into CR-1 rework batch R4 (`Access = Internal;` on 60118) | Roadmap R-08-1 | AJ Ansari (2026-10-16) |
| G3 | A USPS HTTP 200 whose `address` object exists but has blank `streetAddress`, `city`, `state` or `ZIPCode` is treated as a valid suggestion (`obcfuspsUSPSAPIClient.Codeunit.al:297-326`). `FitsCustomerFields` accepts blanks (`obcfuspsAddressValidation.Codeunit.al:188-194`), so OK writes blanks over the customer's address and sets Address Validated = Yes. Breaks FR-7 "Response can't be read → Unexpected response … Error" and FRD §5 "No failure changes the customer" | Oversight | TDD §4.12 only covers "no `address` object, or invalid JSON". CR-1 TDD §14 2.5 already adds this guard for Google | Fix: in `ParseAddressResponse`, return false when USPS street, city, state or 5-digit ZIP is blank (Address 2 may stay blank). Add an automated test (fake 200 with blank `streetAddress` → Error, customer unchanged) | Roadmap R-08-2 | AJ Ansari (2026-10-16): fold into CR-1 R2 |
| G4 | Codeunit 60114 "obcfusps USPS API Client" is `Access = Public` (`obcfuspsUSPSAPIClient.Codeunit.al:7`). Any other extension can call `ValidateAddress` in a loop with the company's stored USPS credentials: batch validation with no user decision and no log row. Weakens FRD §5 "One customer per user action" | Oversight (proposed; AJ to confirm) | TDD §4.12 states Public without a reason. The test app injects its fake through 60113, not 60114 | Fix with G2: `Access = Internal;` on 60114. 60113 keeps the caller-checked `SetTransport` seam | Roadmap R-08-3 | AJ Ansari (2026-10-16): fold into CR-1 |
| G5 | The HTTP phase (`ApiClient.ValidateAddress`, `obcfuspsAddressValidation.Codeunit.al:49`) is not wrapped in a `Codeunit.Run`. If a platform call raises instead of returning false (e.g. `HttpClient.Send` with "Allow HttpClient Requests" off), `TryValidateCustomerAddress` raises: no Error row is logged and the "never raises" contract of TDD §13.1.4 breaks | Oversight, scheduled (verify first) | TDD §13.9 items 2 and 3 accept this as unverified | In the first sandbox round, test with Allow HttpClient Requests **off** and with no network. Only if an error is raised, wrap the HTTP phase and log the caught error | Roadmap: "Sandbox: HttpClient blocked path" | Reasoning role (proposed); AJ Ansari to accept |
| G6 | When the customer write fails after USPS answered, the Error row keeps the five USPS values (`LogWriteFailure`, `obcfuspsAddressValidation.Codeunit.al:227-237`). FR-5 says they are blank for Not Found and Error. TDD §4.13 assumed blank, which no longer holds after the F1 decision (§13.1.3) | Spec stale (confirmed) | Keeping what USPS answered on a write-failure row is more useful for audit | Step 10: FR-5 reads "blank for Not Found and for Error rows where USPS gave no address; a write-failure Error keeps them", and TDD §13.1.3 states it. If AJ prefers literal FR-5, a one-line code fix | — | AJ Ansari (2026-10-16) |
| G7 | FRD §7 says "At most two HTTPS calls per check". FR-7's single token refresh allows three. As built (`obcfuspsUSPSAPIClient.Codeunit.al:73-83`) matches TDD §4.12 "Worst case is 3" and test A5 | Spec stale | The FRD bullet predates its own FR-7 refresh rule | Step 10: FRD §7 reads "at most two in the normal case; three when a cached token is rejected (FR-7)" | — | AJ Ansari at Step 10 |
| G8 | FR-7 bullet "When USPS returns an error, the user sees the USPS error message" versus the FR-7 table, whose 401/403, 429, 5xx and unreadable messages carry no USPS text. As built the USPS text is shown only for 400 and 404 (and in Test Connection). The log always stores it | Spec stale (confirmed) | The code follows the TDD and the FR-7 table | Step 10: narrow the bullet to "for 400 and 404; the log stores it in every case". If AJ wants USPS text on every error, that is a code change to 60114 | — | AJ Ansari (2026-10-16) |
| G9 | TDD §2 Total row says "24 IDs, 26 unallocated". With 60118 added (§13.1) it is 25 allocated, 25 unallocated. The Object Register footer says "All 24 objects: Built (not yet compiled)", but 25 IDs plus 1 interface are built and compiled clean in 0.0.0.2 | Spec stale | Counts not refreshed after F1 and Step 07 | Step 10 (PostDevTDD §2) and Object Register status update | 04-1, 07-2 | Record |
| G10 | TDD §4 "Folders: `src/Foundation/` (module A)" versus `src/Setup/` in the Build Plan and as built | Spec stale | Folder named at Step 05; TDD not updated | Step 10: PostDevTDD names `src/Setup/` | 05-1 | Record |
| G11 | TDD body text superseded by §13 amendments but never consolidated: §4.6 "written … by codeunit 60113 only" (now 60118 `InsertLogEntry`); §4.13 Properties row lists `Permissions = … = i` on 60113; §4.11 `MarkAssistedSetupCompleteIfReady` and `ClearToken` (now `MarkSetupCompleteIfReady`, internal `DeleteToken`); §4.11 Storage row versus §13.3 | Spec stale | Recorded in ChangeLog B1-1, B4-1, B2-1 and TDD §13; only consolidation is missing | Step 10: PostDevTDD writes the as-built text in §4 | B1-1, B2-1, B4-1 | Record |
| G12 | TDD §4.19 test-app specification versus as built: `AssertEqual` overloads (built as `AssertEqualText/Int/Bool`), `LastLogEntry(CustomerNo): Record` (built as `LastLogEntry(CustomerNo; var Log): Boolean`), "Uses `[MessageHandler]`" (none), Fake extras `SetFailCustomerModify` / `GetFailText` and the `OnBeforeModifyEvent` subscriber | Spec stale | Accepted deviations in ChangeLog B6-1. §13.5 updated but §4.19 not | Step 10 | B6-1 | AJ Ansari (2026-10-10, B6-1) |
| G13 | Objects built that are not FRD entities: 60118 Writer, 60111 buffer, 60115 Http Transport, interface "obcfusps USPS Transport", 60100 Setup Registration | Intentional | Each implements an FRD §6 row or rule (API client row plus OQ-17 test seam; Install row; F1 failure-logging rule). Gap fill, not scope creep | None. PostDevTDD keeps them | 04-1, B2-1, B4-1, B5-1 | AJ Ansari (OQ-17, F1) |
| G14 | USPS-specific knowledge outside 60114: DPV D/S/N interpretation and "USPS" wording in 60112, the Environment enum 60094 and setup field, OAuth token caching in 60098 | Intentional | TDD §6 reads FRD §5 as "60114 is the only object that knows USPS URLs, JSON and status codes". Holds as built. CR-1 shows what it costs: 15 main-app files change for a new provider | None for the USPS build. Input to the CR-1 design | CR-1 | AJ Ansari (TDD sign-off 2026-10-10) |
| G15 | FRD §7.2 acceptance: the 24 automated tests and manual tests 11–14, 19, 21 have never run; no package installed in a sandbox | Oversight, scheduled | Step 07 closed under 07-WAIVER (AJ Ansari, 2026-10-16) | First sandbox round (TEST company, AL Test Tool) before Step 12, and after any 0.0.0.3 fix build | 07-WAIVER | AJ Ansari |
| G16 | The live USPS contract (F11: is `state` required, `expires_in` type, error body shape) and tests 1–3 against TEM and production cannot be verified: USPS onboarding is blocked | Oversight, scheduled (external) | ChangeLog CR-1: USPS now needs a license, sign-up link does not load | Decided by the provider decision. USPS kept: run TEM checks of TDD §13.8. CR-1: the Google spike checklist (TDD §14) replaces them | CR-1 | AJ Ansari |
| G17 | Platform checks sent to the sandbox: FRD §4.1 h / F12 (Contact sync on `Modify(true)` from code), OQ-19 / F28 (US captions; State visibility for blank country), OQ-20 (Allow HttpClient Requests default) | Oversight, scheduled | No sandbox install yet (07-WAIVER) | With G15's sandbox round. OQ-20 goes to `docs/4-prove/Deployment.md` (F23) | 04-1 | AJ Ansari |

## 3. Gap-fill work items
Built with the same discipline as main batches, from the reserved growth IDs, through Steps 05–07.
| Item | Objects / IDs | Batch | Status |
|---|---|---|---|
| GF-1 Lock down the Writer (G2) | codeunit 60118 (`Access = Internal`) | Fix-1 (pre-flight per Step 05, then compile/package at 0.0.0.3) | Scheduled with CR-1 (AJ Ansari, 2026-10-16) |
| GF-2 Reject incomplete USPS addresses (G3) | codeunit 60114 `ParseAddressResponse`; test app 60125 (new test, no new ID) | Fix-1 | Scheduled with CR-1 R2 (AJ Ansari, 2026-10-16) |
| GF-3 Lock down the API client (G4) | codeunit 60114 (`Access = Internal`) | Fix-1 | Scheduled with CR-1 (AJ Ansari, 2026-10-16) |

No new object IDs are needed: the growth buffers (A 60103–60108, B 60119–60122, tail 60134–60142, C 60128–60133) stay intact.

## 4. Unexplained divergences
No divergence is unexplained: every gap above has a classification and a reason. These rows are open verification items, carried with an owner:
| Divergence | Owner | Due |
|---|---|---|
| G15: acceptance tests never run, nothing installed in a sandbox | AJ Ansari | Before Step 12 (first sandbox round) |
| G16: live provider contract unverified (USPS onboarding blocked) | AJ Ansari | At the provider decision (CR-1 sign-off or USPS kept) |
| G17: Contact sync, US captions / State visibility, HttpClient default | AJ Ansari | With the first sandbox round; OQ-20 before first deployment |
| G5: HttpClient-blocked path not observed | AJ Ansari (run), Reasoning role (diagnose) | With the first sandbox round |

## Before calling this done
- [x] Every gap has a classification and a route.
- [ ] Every code-touching resolution went through compile, package, install, retest. *(GF-1 to GF-3 pending AJ Ansari's decision; none applied yet)*
- [x] §4 rows have owners; AJ Ansari accepted carrying them (2026-10-16).
