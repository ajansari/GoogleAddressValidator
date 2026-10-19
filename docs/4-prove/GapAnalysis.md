# Gap-Fit Analysis — Google Address Validator

> **Renumbered in 1.3.0.0:** object and field numbers in this historical document are the pre-1.3 numbers (60093–60192). `docs/1-define/ObjectRegister.md` gives each object's old and new ID.


**Date:** 2026-10-16 · **Compared by:** Reasoning role, Opus 5.5 · **Recorded by:** Main role (Sonnet 5.5), for AJ Ansari
**Compared:** `docs/2-design/FRD.md` v1.3 baseline §1–§9 **plus §10 CR-1 (v2.0, normative; signed off by AJ Ansari 2026-10-16, ChangeLog 07a-2)** · `docs/2-design/TDD.md` §14 including 2.17 (normative, signed off 2026-10-16), with §13 where §14 does not supersede it, and §1–§12 where neither does · `docs/4-prove/PostDevTDD.md` Part B (Step 09 behaviours that must survive) · as built: main app working tree on top of commit af839f4, **uncommitted** (Google Address Validator 0.0.0.5); test app working tree on top of 1dd0b9f, **uncommitted** (Google Address Validator Tests 0.0.0.5) · `docs/0-project/ChangeLog.md` through Issue 08-2 · `docs/0-project/Roadmap.md` · earlier records `docs/4-prove/GapAnalysis.USPSbuild-0.0.0.4.md` and `docs/4-prove/CodeReview.USPSbuild-0.0.0.4.md`.
**How platform facts were checked:** System Application 28.5 shipped source in `.alpackages/` (Privacy Notice). Microsoft Learn was not used.

## 1. Three-way comparison
| # | Requirement / design element | FRD | TDD | As built | Gap? |
|---|---|---|---|---|---|
| 1 | Q1: suggested values in the log only for Suggestion Accepted and Confirmed; 2-year retention kept | §10 Q1, FR-5 | 2.10 (option a) | `obcfgavValidationWriter.Codeunit.al:44, 56-62`; tests assert blank for Ignored, Not Found and Error | No |
| 2 | Q2: USPS `standardizedAddress` when `firstAddressLine` is set, else Google `postalAddress`; 9-digit ZIP gets a dash | FR-4 | 2.5 | `obcfgavGoogleAddressClient.Codeunit.al:272-304` | No (GA-08 note) |
| 3 | Q3: `enableUspsCass` always true | Q3 | 2.5 | client `:108`; the probe body leaves it out (`:113-125`) | No |
| 4 | Q4: validated only at PREMISE or SUB_PREMISE, and only with Street, City, State and ZIP filled | FR-8 | 2.5 | client `:209-219` | No (closes USPS G3) |
| 5 | Q5: Street = Address + " " + Address 2; trim, upper case, drop periods and commas, collapse spaces | FR-3 | 2.10 | `obcfgavAddressValidation.Codeunit.al:188-197, 210-218`; dialog bolding `obcfgavAddressCompare.Page.al:174-181` | No |
| 6 | Q6: Confirmed with a note | FR-2, FR-8 | 2.10 | `obcfgavAddressValidation.Codeunit.al:74-83, 199-208` (D, S, N, CONFIRM_ADD_SUBPREMISES) | **GA-07** |
| 7 | Q7: Test Connection as a free probe (empty `addressLines`) | FR-6 | 2.5 | client `:21-48, 113-125` | No (spike, GA-24) |
| 8 | Q8: Provider visible, read-only | FR-6 | 2.8 | `obcfgavSetup.Page.al:29-35` | No |
| 9 | Q9: "Suggestion from Google Maps" line under the grid | FR-4, §5 | 2.10, 2.11 | `obcfgavAddressCompare.Page.al:116-127, 172, 243`; test `TestAttributionShown` | No (app ToS / privacy policy still open: GA-12) |
| 10 | Q10: Provider enum `Extensible = false`, values blank and Google | — | 2.2 | `obcfgavAddressProvider.Enum.al` | No |
| 11 | Q11: full rename (prefix, namespace, app names, file and object names, permission sets, `OBCFGAV-ApiKey`, `OBCFGAV-ADDRESS`, `OBCFGAV-2Y`) | Q11 | 2.17 | every file and `app.json` match the 2.17 table; the test app's `app.json` id is unchanged | **GA-03, GA-04, GA-05, GA-16** |
| 12 | Validate Address action: caption, promoted, under Functions, saves the card first | FR-1.1–1.2 | 2.10 | `obcfgavCustomerCard.PageExt.al:23-47` | No |
| 13 | Preconditions: enabled, provider set, key present; US; address plus City/State or a ZIP-like code (CR9-08); 2-letter state | FR-1.3 | 2.10 | `obcfgavAddressValidation.Codeunit.al:122-175` | No |
| 14 | One POST per check; no name or number; key in the `X-Goog-Api-Key` header as SecretText, never in the URL | FR-1.4, §5, §7 | 2.5 | client `:13-19, 60-111`; tests `TestRequestShape`, `TestKeyOnlyInHeader`, `TestNoCustomerDataSent` | No |
| 15 | Privacy notice: created on demand, approval checked after the preconditions and before any send; Test Connection also gated | (Step 09) | PostDevTDD B-3 | `obcfgavAddressValidation.Codeunit.al:62-65, 112-120`; `obcfgavSetup.Page.al:95-98`; `obcfgavSetupRegistration.Codeunit.al:22-36` | **GA-02** (bypass), **GA-12** (wording and link) |
| 16 | Outcomes and the Not Found reason ("missing or unconfirmed") | FR-2 | 2.5 | client `:221-227` (missing components only) | **GA-06** |
| 17 | Dialog: warning line, notes, OK = Accept, values written as returned, no truncation, concurrency check, flag set to Yes | FR-4 | 2.10, §13.1 | `obcfgavAddressCompare.Page.al`; `obcfgavValidationWriter.Codeunit.al:73-105` | No |
| 18 | Log fields 1–23, Provider instead of Environment, never the key or URLs | FR-5 | 2.10 | `obcfgavValidationLog.Table.al` | No |
| 19 | Retention: custom 2 years, policy created disabled | FR-5 | 2.9 | `obcfgavSetupRegistration.Codeunit.al:38-57` | No (GA-26 if anything was ever installed) |
| 20 | Setup: one API key, write-only, masked; company-scope isolated storage, encrypted when encryption is on; wizard asks only for the key | FR-6 | 2.7, 2.8 | `obcfgavCredentialMgt.Codeunit.al`, `obcfgavSetup.Page.al`, `obcfgavSetupWizard.Page.al` | No |
| 21 | Error table: 400 API_KEY_INVALID or 401, 403 by reason, 429, 5xx, unreadable; status decides when reason is missing | FR-7 | 2.5 | client `:142-169, 333-365` | No |
| 22 | No retries of any kind | FR-7, §5 | 2.5, 2.6 | one `Send` per path; tests `TestQuotaNoRetry`, `TestNoResponseNoRetry` | No |
| 23 | Address Validated rules | FR-8 | 2.10, §13.4 | `obcfgavValidationWriter.Codeunit.al:107-121`; `obcfgavCustomer.TableExt.al:58-70` | No (GA-01 is the bypass) |
| 24 | All provider-specific logic in one codeunit per provider | §5 | 2.5, 2.10 | 60119, but the DPV and next-action reading is in 60113 and the "USPS data" note in 60112 | **GA-11** (Intentional) |
| 25 | One customer per user action (cost, provider terms) | §5, §1.1 | 2.4 (`Access = Public`) | 60114 `ValidateAddress` and `TestConnection` are callable by any extension | **GA-02** |
| 26 | Caller check: read in the public procedure itself, test app allowed only in a sandbox | — | §13.2, 2.4, 2.7, B-2 | `obcfgavCredentialMgt.Codeunit.al:11-19, 62-75`; `obcfgavAddressService.Codeunit.al:7-25`; `obcfgavAddressValidation.Codeunit.al:12-28` | No |
| 27 | Step 09 behaviours | — | B-4 to B-8 | `SetForceUpdateContact` (Writer `:93`); CanModify passed in (Writer `:24-32`); null-safe JSON (client `:315-331, 399-412`); log rename propagation (Log `:20-24`); `OnInsert` TestField (Log `:125-128`); `RunPageView` (PageExt `:58`); `SetLoadFields` (60113 `:55`); `EnsurePrivacyNotice` + Commit (60113 `:117-118`); wizard `var` block last | No |
| 28 | Writer 60118 access | — | 2.10 silent; Roadmap R-08-1 | `obcfgavValidationWriter.Codeunit.al:7` `Access = Public` | **GA-01** |
| 29 | Labels (complete delta) | — | 2.11 | all labels match, except the caption family and the caller text | **GA-04, GA-05** |
| 30 | Permission sets | §5 | 2.12, §10 | `OBCFGAVGAVUSE/ADMIN.PermissionSet.al` match, plus Setup Registration X (B-3) | No (GA-13 note) |
| 31 | Object Register delta | — | 2.13 | 60094 reused, 60119 and 60128 added; the register's counts are wrong | **GA-18** |
| 32 | Test app | §7.2 | 2.14 | 6 codeunits, 54 tests (60125: 18, 60126: 28, 60127: 8), never run | **GA-17, GA-23** |
| 33 | Spike checklist | §4.1 n | 14.y | nothing run | **GA-24** |
| 34 | Sanity Check delta review | — | 2.16 | no CR-1 content in `docs/2-design/SanityCheck.md` | **GA-14** |
| 35 | Languages: en-US, no translation files | §8 | §7 | no target-language file; only generated `*.g.xlf` (gitignored), including a stale `USPS Address Validator.g.xlf` | No (GA-21 note) |
| 36 | Platform checks owed to a sandbox (Contact sync, US captions, HttpClient default, HTTP phase raising) | §4.1 h, OQ-19, OQ-20 | §13.7 F12/F28, §13.9 | not done | **GA-10, GA-25** |

## 2. Gaps
Classification per `ocpfFramework/runbookSteps/08.md`: **Intentional** (the reasoning is recorded), **Oversight** (fixed now through Steps 05–07, or scheduled in `docs/0-project/Roadmap.md`), **Spec stale** (the code is right and the FRD/TDD need updating — recorded here, applied at Step 10).

| # | Gap | Classification | Why | Resolution | ChangeLog / Roadmap ref | Decided by |
|---|---|---|---|---|---|---|
| GA-01 | Codeunit 60118 "obcfgav Validation Writer" is `Access = Public` (`src/Validation/obcfgavValidationWriter.Codeunit.al:7`) and carries `Permissions = tabledata "obcfgav Validation Log" = i` (`:8`). `Init` takes `NewCanModify` from its caller (`:24`). Any extension can call `Init(No, Confirmed, Buffer, false, true)` and `Run()` to set Address Validated = Yes without a check, or call `InsertLogEntry` (`:39`) to write a forged log row. Breaks FRD §5 "Address Validated changed only by the extension under FR-8" and FR-5 "inserted by the extension only". | Oversight | Carried from the USPS build (G2). Roadmap R-08-1 scheduled it with CR-1 batch R4; TDD 2.10 does not mention Access, so it was not done. The test app never calls 60118. | **Fixed in 0.0.0.6:** `Access = Internal;` on 60118 (ChangeLog 08-3). | R-08-1 | AJ Ansari (approved 2026-10-16) |
| GA-02 | Codeunit 60114 "obcfgav Address Service" is `Access = Public` (`src/Validation/obcfgavAddressService.Codeunit.al:5`). `ValidateAddress` (`:27`) and `TestConnection` (`:36`) have no caller check and do not look at `Enabled` (`LoadSetup`, `:88-93`, checks only Provider). The privacy-notice gate exists only in 60113 (`obcfgavAddressValidation.Codeunit.al:62`). So any extension in the tenant can send customer addresses to Google with the company's key: no consent, no log row, no user action, every call billable. Breaks FRD §10 §5 "one customer per user action" and defeats the Step 09 privacy rule (PostDevTDD B-3, CR9-04). | Oversight | Carried from the USPS build (G4). Roadmap R-08-3 said "Access = Internal on API client (and Address Service under CR-1)", but the signed TDD 2.4 says "Access = Public". The test app calls `AddressService.SetTransport` and `TestConnection` directly, so making it Internal would break those tests. | **Fix now (recommended):** keep 60114 Public; make `NavApp.GetCallerModuleInfo(CallerModuleInfo); CredentialMgt.CheckCallerAllowed(CallerModuleInfo);` the first statements of `ValidateAddress` and `TestConnection` (pattern B-2). `ProviderDisplayName` needs no check. TDD 2.4 gains one sentence at Step 10. | R-08-3 | AJ Ansari (decided 2026-10-16: keep Public with caller check; fixed in 0.0.0.6) |
| GA-03 | Enum 60093 caption is `'Validation Result'` (`src/Setup/obcfgavValidationResult.Enum.al:6`). TDD 2.13 and 14.x and BuildPlan R5 call for `'Address Validation Result'`. | Oversight | Missed in R5. | **Fixed in 0.0.0.6:** caption `Address Validation Result`. | BuildPlan R5 | AJ Ansari (approved 2026-10-16) |
| GA-04 | The captions are inconsistent because the TDD contradicts itself. 2.17 says the "setup page, wizard, assisted-setup entry and log are 'Google Address Validation …'", while 2.8, 2.10 and 2.11 give neutral captions. As built, only the setup card follows 2.17 (`'Google Address Validation Setup'`, `obcfgavSetup.Page.al:7`). The setup table, wizard, assisted-setup labels, log table and page, and the Customer Card log action are neutral. Users see one mismatch: the wizard text says "on the Address Validation Setup page" (`obcfgavSetupWizard.Page.al:159`). | Oversight (TDD contradiction) | 2.17 was added after 2.8, 2.10 and 2.11 were drafted; both were signed off together. | AJ chooses. **(a) Recommended:** neutral everywhere: change the page caption to `'Address Validation Setup'` and correct the 2.17 caption sentence at Step 10. **(b)** "Google …" everywhere: change 7 captions and labels plus the wizard text. | 07a-1, 07a-3 | AJ Ansari (decided 2026-10-16: neutral everywhere; fixed in 0.0.0.6, 2.17 caption sentence corrected at Step 10) |
| GA-05 | `CallerNotAllowedErr` reads `'This procedure can only be called by the Address Validator app.'` (`obcfgavCredentialMgt.Codeunit.al:80`). TDD 2.11 said the text "depends on §4 naming"; the app is now Google Address Validator. | Oversight (minor) | Text never settled after the rename. | Settle with GA-04. Recommended: `'… by the Google Address Validator app.'`. | — | AJ Ansari (decided 2026-10-16; fixed in 0.0.0.6) |
| GA-06 | The FR-2 Not Found message promises "what is missing **or unconfirmed**", and the label `MissingPartsTxt` reads "Missing or unconfirmed: %1." (`obcfgavGoogleAddressClient.Codeunit.al:431`). The code reads only `missingComponentTypes` (`:241-263`). `unconfirmedComponentTypes` (FRD §10 fact G6) is never read. | Oversight (TDD did not implement an FRD rule) | TDD 2.5 maps only `missingComponentTypes`. | AJ chooses. **(a) Recommended:** also read `result.address.unconfirmedComponentTypes` and append it to the same list (TDD 2.5 mapping row, plus one test in 60126 using `GoogleNotValidatedJson`). **(b)** Narrow FR-2 and the label to "Missing: %1." | — | AJ Ansari (decided 2026-10-16: option a; fixed in 0.0.0.6 with `TestUnconfirmedPartsInReason`) |
| GA-07 | FR-8 (§10) says the delivery signals "(DPV D/S/N, `CONFIRM_ADD_SUBPREMISES`, `CONFIRM`) … are added to the Confirmed message". As built, only the FR-4 warning line (D, S, N, CONFIRM_ADD_SUBPREMISES) is appended (`obcfgavAddressValidation.Codeunit.al:77-81, 199-208`). `CONFIRM` and the FR-4 notes (replaced, inferred, spell-corrected) are not. | Spec stale (proposed) | Q6 as decided says "missing-suite or delivery-N signal", and TDD 2.10 appends "the delivery note" = DeliveryWarning. Test `TestConfirmedWithNote` covers it. | Step 10: FR-2 and FR-8 read "the delivery warning line of FR-4 (DPV D, S, N or CONFIRM_ADD_SUBPREMISES)". If AJ wants `CONFIRM` too, that is a new label and a code fix. | — | AJ Ansari (decided 2026-10-16: narrow the FRD, as built; applied at Step 10) |
| GA-08 | If `uspsData.standardizedAddress.firstAddressLine` is set but city, state or ZIP is blank, the result is an Error ("Unexpected response", `client:210-218`), with no fallback to `postalAddress` (`:280-292`). | Intentional | Matches TDD 2.5 exactly. Google says `uspsData` is not always populated (fact G7); partial `uspsData` is not documented. | None now. Add to the spike: "Is `standardizedAddress` ever partial?" If so, fall back to Source B per field. | — | Reasoning role (proposed); AJ Ansari to accept |
| GA-10 | The HTTP phase (`AddressService.ValidateAddress`, `obcfgavAddressValidation.Codeunit.al:68`) is not wrapped in a `Codeunit.Run`. If `HttpClient.Send` raises an error instead of returning false (for example with "Allow HttpClient Requests" off), `TryValidateCustomerAddress` raises: no Error row, and the "never raises" rule of §13.1.4 breaks. | Oversight, scheduled (verify first) | Carried from USPS G5; TDD §13.9 item 2. | First sandbox round: Allow HttpClient Requests **off**, and no network. Wrap the phase only if it raises. | R-08-4 | AJ Ansari (run), Reasoning role (diagnose) |
| GA-11 | Some provider-specific reading sits outside 60119: DPV codes and the next-action token `CONFIRM_ADD_SUBPREMISES` are read in 60113 (`:199-208, 310`); the note "USPS data reports that this address is vacant" is in 60112 (`:240`). | Intentional | TDD 2.10 puts DeliveryWarning outside the client on purpose, and ChangeLog 07a-3 accepts it. "USPS" here is data wording (2.17). | Step 10: FRD §5 reads "all provider-specific request and response handling lives in one codeunit per provider; the buffer is the neutral contract and uses DPV and Google verdict terms". No code change. | 07a-3 | AJ Ansari (07a-3) |
| GA-12 | **Privacy notice wording and link.** Name `'Google Address Validation'`, link `https://policies.google.com/privacy` (`obcfgavSetupRegistration.Codeunit.al:79-81`). Neither FRD §10 nor TDD §14 states them. The consent text is fixed by the platform: System Application 28.5 `PrivacyNoticeImpl.Codeunit.al:20` says the data is shared "with **Microsoft services**…", inaccurate for Google and not overridable (`OnBeforeShowPrivacyNotice` is `internal`). In an evaluation company where no administrator has decided, approval passes without showing the notice (`:98-100`). Also open: Q9 / OQ-29 (the app's own Terms of Use and Privacy Policy); `app.json` `privacyStatement` and `EULA` are blank. | Spec stale, plus an open confirmation | The code is a reasonable reading of the Step 09 rule; FRD and TDD need the rule written; the link is unconfirmed (replaces OQ-23). | Step 10: FRD FR-1.3 and FR-6, and PostDevTDD state the rule, name, link and platform-text caveat. AJ confirms the link and accepts the caveat. Deployment.md (Step 11) explains it to administrators. | R-09-2 | AJ Ansari (to confirm) |
| GA-13 | **Customer permissions.** The permission sets cover only this extension's objects. Accept modifies the Customer and, via `SetForceUpdateContact(true)` (`obcfgavValidationWriter.Codeunit.al:93`), the linked Contact. `CanModifyCustomers` checks only Customer. A user who may modify Customers but not Contacts gets a write-failure Error, logged per §13.1.3; the customer stays unchanged. | Intentional (record) | TDD §10: users also need their normal Business Central permissions. | Step 11: Deployment.md and UserGuide list Customer read/modify and Contact modify. Sandbox: one check as a non-SUPER user (TDD §13.9 item 6), including the privacy prompt for a non-admin. | — | AJ Ansari (TDD sign-off 2026-10-10) |
| GA-14 | TDD 2.16 asked for a Sanity Check delta review of CR-1. `docs/2-design/SanityCheck.md` has no CR-1 content. | Oversight (process, no code) | Remediation 07a went from sign-off straight to build. | This analysis checked every 2.16 item against the code (§13.1 flow, caller checks, one key, §2.14 test list, Q1 storage, attribution, artificial-address rule, key never in URL or log, enum `Extensible`). Test Connection billing stays a spike item. The main role appends a "CR-1 delta (07a)" section to SanityCheck.md, or AJ asks for a separate Reasoning-role pass. | — | AJ Ansari (to decide) |
| GA-15 | Nothing has been committed since af839f4 (main) and 1dd0b9f (tests). The rename and batches R1–R6 are uncommitted; `docs/`, `src/logo/` and the packages are untracked (USPS-build CR9-22 carried). | Oversight (process) | Runbook: one commit per batch. | Commit both repositories before Step 09, once AJ agrees. | CR9-22 | AJ Ansari |
| GA-16 | TDD 2.17 says "test app 0.0.0.4"; it was built and shipped as 0.0.0.5. TDD 2.15 says "Step 07 compile … at 0.0.0.3". | Spec stale | ChangeLog 07a-3: test 0.0.0.4 had warning AA0021 and is kept, but 0.0.0.5 is the clean build. | Step 10 (PostDevTDD identity section). | 07a-3 | Record |
| GA-17 | Test objects built beyond 2.14: extra tests (`TestKeyRejected401`, `TestOtherForbidden`, `TestUnmappedStatus`, `TestNoVerdict200`, `TestGranularityNotValidated`, `TestSubPremiseValidated`, `TestKeyOnlyInHeader`, `TestNoCustomerDataSent`, `TestPostCodeMustBeZipLike`, `TestTestConnection200`, `…ApiOff`, `…NoResponse`, `…NoKey`, `TestPrivacyRefusedSendsNothing`, `TestConfirmedWithNote`, `TestProviderSeamDialog`, `TestAttributionShown`); fake extras (`GetLastRequestMethod`, `GetLastTimeoutMs`, `LastRequestHadKeyHeader`); library extras. Total 54 tests. | Intentional (gap fill), spec stale | They strengthen FRD §7.2 (tests 8, 10, 22, 23) and keep the Step 09 tests. | Step 10 (PostDevTDD test list); Step 11 (AutomatedTestScripts.md lists all 54). | 07a-3 | Record |
| GA-18 | `docs/1-define/ObjectRegister.md` counts are wrong. The footer says "All 26 IDs"; the correct number is **27** (A 60093–60102 = 10, B 60109–60119 = 11, C 60123–60128 = 6). The header still says "25 of 50 unallocated"; the correct number is **23**. | Spec stale | Not refreshed after R2 and R6. | Main role corrects the register now. | 07a-3 | Record |
| GA-19 | Open-question numbers collide in the FRD. The 1.3 baseline added OQ-23 (USPS privacy link) and OQ-24 (telemetry), while §10 §9 defines OQ-23 to OQ-30 for CR-1. OQ-30 ("naming") is resolved by revised Q11. | Spec stale | Two edits of §9 were made in parallel. | Step 10: keep §10's OQ-23 to OQ-30; renumber the two 1.3 rows as OQ-31 (privacy link, now Google) and OQ-32 (telemetry); mark OQ-30 resolved. | 10-1 | AJ Ansari (to accept) |
| GA-20 | Document headers are stale: the FRD title and header still say "USPS Address Validator" and call CR-1 "pending, unsigned"; FRD §10 and TDD §14 headings say "sign-off pending"; the TDD header says "2.0 DRAFT"; the §14 intro refers to a "§4 Naming decision" that is now 2.17; TDD 2.14 keeps the name of 60126 while 2.17 renames it "Provider Tests" (built per 2.17, which wins). | Spec stale | Sign-off was recorded only in ChangeLog 07a-2. | Step 10 consolidation. | 07a-2 | Record |
| GA-21 | Stale USPS wording outside the code: `docs/1-define/ProjectParameters.md` line 18 (old icon source), lines 63–68 ("USPS credentials", "USPS address"), line 94; `docs/3-build/BuildPlan.md` is titled "USPS Address Validator"; `docs/4-prove/SandboxInstall.md` §1 says the test app "needs this 0.0.0.4 build first" (should be 0.0.0.5); the test app's `.vscode/launch.json` has `startupCompany: "TEST USPS"` (still passes the TEST guard); stale generated `USPS Address Validator.g.xlf` files remain in `Translations/` (gitignored). **In code:** every remaining "USPS" is data wording, as 2.17 allows. | Spec stale / document fixes | Rename sweep covered code, not documents. | SandboxInstall §1: fix now. The rest at Step 10. The stale `.g.xlf` files may be deleted (not packages). | 07a-3 | Record |
| GA-22 | Project root hygiene (Operating Rule 9): `images/` and `ProjectDashboard-f1.html` sit in the root, along with the known stray `OnlyBCFans_USPS Address Validator_0.0.0.2.app` (08-1) and a stray `OnlyBCFans_USPS Address Validator Tests_0.0.0.1.app` in the test app's root (R-11-1). | Oversight (hygiene, no code) | Created during 07a-2 and earlier compiles. | AJ decides where `images/` goes (suggestion: `src/logo/source/`) and what `ProjectDashboard-f1.html` is. Stray `.app` files stay unless AJ says otherwise. | 08-1, R-11-1 | AJ Ansari |
| GA-23 | FRD §10 §7.2 acceptance tests have never run: the 54 automated tests, and manual tests 11–14, 19, 21 and 23. Nothing is installed in a sandbox. | Oversight, scheduled | 07-WAIVER and 09-WAIVER; the remediation build has not been installed either. | First sandbox round (TEST company, AL Test Tool; page id still open, R-11-1) before Step 12. The privacy-refused test needs a user who can approve for the organization; otherwise the platform shows a message and the test fails. | R-08-5, R-09-1 | AJ Ansari |
| GA-24 | Every item on the spike checklist (TDD 14.y) is open: header accepted; `uspsData` case and line split; error reasons; free probe; Pro SKU; ROUTE / CONFIRM_ADD_SUBPREMISES on real addresses; key never in `error.message`; `Send` returns false. `HttpHeaders.ContainsSecret` and `Request.Content().ReadAs` in the fake compile but are not observed at runtime. Also GA-08. | Oversight, scheduled (external) | Needs a real key and real addresses (FRD §5). | Spike before Step 12; findings that change code go through Step 07. | R-08-6 | AJ Ansari |
| GA-25 | Platform checks owed to a sandbox: Contact sync after `SetForceUpdateContact` (F12, FR-9); US captions and State visibility (OQ-19, F28); the "Allow HttpClient Requests" default (OQ-20). | Oversight, scheduled | No sandbox install yet. | With GA-23's round; OQ-20 goes into Deployment.md. | R-08-5 | AJ Ansari |
| GA-26 | (AJ answered 2026-10-16: nothing was ever installed) Upgrading from a USPS build would leave data behind. Same app id; 2.17 says "nothing is installed, so no rename migration". If any of 0.0.0.1–0.0.0.4 was ever installed, upgrading with Force Sync would leave the old isolated-storage secrets under `OBCFUSPS-*` keys, privacy notice `OBCFUSPS-ADDRESS`, retention period `OBCFUSPS-2Y`, and a Retention Policy Setup row for 60109 pointing at the old period. `RegisterRetentionPolicy` runs only on install and company creation. | Intentional (conditional) | No install is recorded anywhere (07-WAIVER). | If any sandbox ever had a USPS build: **uninstall with "Delete extension data"**, then install 0.0.0.5 with Add, rather than Force Sync. SandboxInstall §1 says so. | — | AJ Ansari (to confirm) |

**What happened to the USPS-build findings**

| Earlier ID | Status on the Google build |
|---|---|
| G1 CR-1 not built | **Closed**: built in 07a |
| G2 Writer Public | **Carried**: GA-01 |
| G3 blank provider fields accepted | **Closed**: client `:210-218` rejects them; test `TestValidatedWithoutAddress` |
| G4 API client Public | **Carried, worse**: GA-02 (privacy bypass) |
| G5 HTTP phase may raise | **Carried**: GA-10 |
| G6 write-failure Error rows keep USPS values | **Obsolete**: superseded by Q1 (`Writer:44`). FRD 1.3's FR-5 text must go at Step 10 |
| G7 three-call worst case | **Obsolete**: one call, no token |
| G8 USPS text only for 400/404 | **Obsolete**: replaced by the §10 FR-7 table |
| G9 counts | **Replaced** by GA-18 |
| G10 folder name | **Closed in practice**: `src/Setup/`. TDD §4 still says Foundation (Step 10) |
| G11 consolidation | **Replaced** by GA-20 and the Step 10 list below |
| G12 test-app spec drift | **Replaced** by GA-17 |
| G13 objects not in the FRD | **Narrowed**: FRD §10 §6 now names the service, client, interfaces and enum. Writer 60118, buffer 60111 and Setup Registration 60100 remain intentional gap fill |
| G14 USPS logic spread | **Partly resolved** by CR-1; the remainder is GA-11 |
| G15 tests never run | **Carried**: GA-23 |
| G16 live USPS contract | **Replaced** by the Google spike: GA-24 |
| G17 platform checks | **Carried**: GA-25 |

| Earlier Code Review ID | Status |
|---|---|
| CR9-01 caller check read in a helper | **Closed (survived)**, B-2 |
| CR9-02 test GUID sandbox-only | **Closed** |
| CR9-03 token stored with Set | **Obsolete** (no token) |
| CR9-04 privacy notice | **Closed in 60113**, but bypassable through 60114 (GA-02) |
| CR9-05 SetForceUpdateContact | **Closed**; sandbox confirmation owed (GA-25) |
| CR9-06, 07, 08, 10, 11, 14, 15, 17, 24, T-01, T-05, T-06 | **Closed (survived)** |
| CR9-09 typed `********` ignored | **Note**, still applies (`obcfgavSetup.Page.al:144`) |
| CR9-12 Standards §1.1 wording | **Open** (Standards author) |
| CR9-13 duplicated labels | **Partly back**: `SetupIncompleteErr` (60113, 60114), `MissingApiKeyErr` (60114, 60119), `ShowTextTok` (60113, 60096). Step 09 |
| CR9-16 unused fake procedures | **Obsolete** (fake rewritten) |
| CR9-18, 20, 21 | **Notes carried** |
| CR9-19 | **Partly obsolete**: `BuildAddressUrl` is gone; manual LF in `AddNote` remains |
| CR9-22 untracked files | **Carried**: GA-15 |
| CR9-23 telemetry | **Open**: GA-19 / OQ-32 |
| T-02 untested paths | **Obsolete** (replaced by the Google tests) |
| T-03 | **Note** |
| T-04 runner isolation | **Open**: GA-23 |
| P1–P5 pattern candidates | Still not flagged to the library (R-09-2) |

**Handed to Step 09 (code quality, not FRD/TDD divergence):** dead locals in 60119 `ReadError` (`ErrorCode`, `ErrorStatus`, `:26-27, 129-130, 341-351`); hard-coded literals `'D'`, `'S'`, `'N'` (`obcfgavAddressValidation.Codeunit.al:201-205`) and `'Strong'`, `'Standard'` (`obcfgavAddressCompare.Page.al:207-208`); a trailing space in the Not Found message when the reason is blank (`client:224`); "Google message: " with nothing after it when there is no response (`client:38`); the duplicated labels listed above.

**Documents to consolidate at Step 10:**
- `docs/2-design/FRD.md`: new 2.0 baseline with §10 folded into §1–§9; title Google Address Validator; sign-off 2026-10-16; GA-06, GA-07, GA-11, GA-12, GA-19; obsolete USPS-build items G6, G7, G8 removed.
- `docs/2-design/TDD.md`: header and §14 status (sign-off recorded), §14 intro reference to 2.17, 2.14 versus 2.17, and GA-04 or GA-02 if AJ changes 2.4. Original text kept as the historical record.
- `docs/4-prove/PostDevTDD.md`: rewrite for 0.0.0.5; keep the USPS version beside it as `PostDevTDD.USPSbuild-0.0.0.4.md`.
- `docs/1-define/ObjectRegister.md`: GA-18. `docs/1-define/ProjectParameters.md`: lines 18, 63–68, 94. `docs/2-design/SanityCheck.md`: GA-14. `docs/3-build/BuildPlan.md`: title. `docs/0-project/Roadmap.md` and `ProjectMemory.md`: status of R-08-1 to R-08-6, R-09-1, R-09-2, R-11-1.
- Step 11: Documentation, UserGuide, AutomatedTestScripts (54 tests); HumanUnitTestScript (tests 4, 5, 8, 10, 14, 21, 22, 23 changed); Deployment.md (Google Cloud project, billing, API enablement, key restriction and daily cap and budget alert, key-rotation incident step, remove the USPS 72-hour duty, Customer and Contact permissions, privacy-notice caveat, OQ-20); AutomatedTestGuide (test app 0.0.0.5, page id); Acknowledgements (Google documentation and terms).
- `docs/4-prove/SandboxInstall.md` §1: fix now (GA-21, GA-26). `docs/1-define/TranslationGlossary.md`: N/A.

## 3. Gap-fill work items
| Item | Objects / IDs | Batch | Status |
|---|---|---|---|
| GF-1 Lock down the Writer (GA-01) | codeunit 60118: `Access = Internal` | Fix-08G, main **0.0.0.6** | Done, compiled 0/0, packaged |
| GF-2 Caller check on the Address Service (GA-02) | codeunit 60114: `ValidateAddress`, `TestConnection` | Fix-08G | Done (approved 2026-10-16) |
| GF-3 Enum caption (GA-03) | enum 60093 | Fix-08G | Done |
| GF-4 Caption family and caller text (GA-04, GA-05) | page 60096 (option a), or 60095, 60097, 60100, 60109, 60110, 60117 (option b); 60098 label | Fix-08G | Done (neutral captions; unconfirmed parts read) |
| GF-5 Unconfirmed components in the Not Found reason (GA-06, option a) | codeunit 60119 `ReadAddress`; test app 60126, one new test (test app **0.0.0.6**) | Fix-08G | Done (neutral captions; unconfirmed parts read) |

No new object IDs are needed. Growth buffers stay intact: A 60103–60108, B 60120–60122, tail 60134–60142, C 60129–60133.

## 4. Unexplained divergences
None is unexplained: every gap above has a classification and a reason. Open verification items, with an owner:
| Divergence | Owner | Due |
|---|---|---|
| GA-23: 54 automated and 7 manual tests never run; nothing installed | AJ Ansari | First sandbox round, before Step 12 |
| GA-24: Google spike checklist (TDD 14.y), plus partial `standardizedAddress` | AJ Ansari | Before Step 12 (real key, real addresses) |
| GA-25: Contact sync, US captions and State visibility, HttpClient default | AJ Ansari | With GA-23; OQ-20 before first deployment |
| GA-10: HttpClient-blocked path | AJ Ansari (run), Reasoning role (diagnose) | With GA-23 |
| GA-12: privacy link and wording, app ToS / privacy policy (Q9, OQ-29) | AJ Ansari | Before first deployment |
| GA-26: any USPS build ever installed? | AJ Ansari | Before the first sandbox install |

## Before calling this done
- [x] Every gap has a classification and a route.
- [x] GF-1 to GF-5 applied and compiled 0 errors / 0 warnings, packaged at 0.0.0.6 (main) and 0.0.0.6 (tests). **Install and retest: not done** (nothing is installed; carried as GA-23).
- [x] §4 rows have owners; AJ Ansari agreed to carry them (2026-10-16).

---

## SC-1 Gap-Fit (1.1.0.3)
**Date:** 2026-10-18 · **Compared by:** Reasoning role, Opus 5.5 (report first line checked against §1.7) · **Recorded by:** Main role, for AJ Ansari · **Compared:** FRD Appendix C (FR-10..FR-18, tests 24–45), TDD §15.1–15.23, PostDevTDD Part F, ChangeLog through SC-1g, Object Register "SC-1 additions", HumanUnitTestScript §3a, against main 1.1.0.3 and test app 0.0.0.11; what changed since 1.0.0.0 was read from `git diff` of both repositories. Platform facts were read from the Base Application 28.5 source shipped in `.alpackages/`.

**Result:** the main app follows FRD Appendix C and TDD §15; every one of the 37 main-app IDs and both test codeunits is at its planned ID, name and file; every FR-10..FR-18 element and the five Customer changes (FR-18) are in the code and nowhere else. No main-app code fix is needed. 15 gaps: 5 Oversight (3 fixed now, 2 scheduled), 6 Spec stale, 4 Intentional.

| # | Gap | Class | Resolution |
|---|---|---|---|
| GA-1.1-01 | Test 44 (`TestPersonJoinsCompanyFlag`) could not pass as written: standard BC copies the company address to a person only when the person's address is blank or equals the previous company's | Oversight (test defect) | Fixed: the person is created with a blank address (test app 0.0.0.12) |
| GA-1.1-02 | (a) Test 28: no test that Accept on one Company Information block leaves the other untouched. (b) Test 25: `AssertLogSource` does not check the key in the description | Oversight | (a) fixed: `TestShipToAcceptKeepsMain`. (b) scheduled (Roadmap R-08-7) |
| GA-1.1-03 | Test documents behind the code (121 vs 127 tests; five rows missing) | Oversight (documents) | Fixed: counts 127 = 24+29+8+48+18; rows 122–127 |
| GA-1.1-04 | The linked-update gate: 60113 gates on `CanModify`, 60139 checks `Contact.WritePermission()` per contact branch and `Resource.ReadPermission()`; TDD 15.6 put the Contact check in 60113 | Spec stale | Code is right (the TDD gate would have blocked Employee → Resource); applied at Step 10 |
| GA-1.1-05 | 15.5 details: typed `FieldNo("Privacy Blocked")` per table; parent read through RecordRef; `OpenSource` load fields | Spec stale | Applied at Step 10 |
| GA-1.1-06 | D1 (skip when the linked flag already matches), D2 (Write Guard around the standard updates), D4 (person flag follows only a changed company address or flag) not in TDD 15.13 | Spec stale | Applied at Step 10 (SC-1f) |
| GA-1.1-07 | Contact source: the linked update is part of the write (D3); a failure shows and logs Error | Intentional (to confirm) | Decided by the Main role under AJ Ansari's instruction; **AJ Ansari to confirm before Step 12** — the alternative is a one-branch change in 60139 `OnRun` |
| GA-1.1-08 | Recorded deviations: `SaveSource` / `IsPrivacyBlocked` without `AddressType`; `GetTableCaption`; 60101 and 60113 edited in two batches; explicit upgrade tags; 60130 manual binding | Intentional | ChangeLog B1-1, SC-1c, SC-1e, B4-1 |
| GA-1.1-09 | Identity and counts in TDD 15.1 and PostDevTDD Part F are stale (1.1.0.0, 0.0.0.8, 121 tests) | Spec stale | Step 10 |
| GA-1.1-10 | Object Register headings, rows and buffers stale after B2–B4 | Spec stale | Fixed now |
| GA-1.1-11 | FRD §1–§9 and header still carry 1.0 text; Appendix C governs | Spec stale | Step 10: FRD 2.1 baseline with Appendix C folded in |
| GA-1.1-12 | No light-role pre-flight for B2–B4; OQ-41 checkpoint replaced; Step 07 gate waived | Intentional | AJ Ansari's instruction; ChangeLog B2-1/B3-1/B4-1, SC-1g |
| GA-1.1-13 | Nothing of 1.1 has been installed or run (127 tests, TC-30..TC-38, TDD 15.21 items) | Oversight, scheduled | First install at Step 12; failures go to the Reasoning role, fixes ship as 1.1.0.4+ |
| GA-1.1-14 | The Country/Region reset is tested on Customer only | Oversight, scheduled | Roadmap R-08-8: generic `TestCountryResets<Tag>` |
| GA-1.1-15 | The linked update is the full standard Contact update (Last Date Modified and Change Log entries change on the Contact) | Intentional (record) | Step 10: FR-9 and PostDevTDD; Step 11: UserGuide and Deployment |

**Acceptance tests 24–45:** automated tests exist for 25–29, 31–33, 35, 36, 38–41, 43–45 (names in the Reasoning role's report and in `docs/4-prove/AutomatedTestGuide.md`); manual cases TC-30..TC-38 in `docs/4-prove/HumanUnitTestScript.md` cover 24, 30, 34, 37, 42. Test 44 was fixed (GA-1.1-01), test 28's write independence added (GA-1.1-02 a).

**Open items with owners:** GA-1.1-07 (AJ Ansari confirms D3, before Step 12); GA-1.1-13 (AJ Ansari runs; Reasoning role diagnoses; Step 12); GA-1.1-02 b and GA-1.1-14 (Roadmap).

### Before calling this done
- [x] Every gap has a classification and a route.
- [x] Oversight fixes GF-1.1-1/2/3 applied; test app 0.0.0.12 compiled 0 errors / 0 warnings against main 1.1.0.3.
- [ ] AJ Ansari agrees to carry the open items.
