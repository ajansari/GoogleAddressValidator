# Code Review — USPS Address Validator

**Date:** 2026-10-16 · **Reviewer:** Reasoning role, Opus 5.5 · **Fixes applied by:** Main role (Sonnet 5.5), for AJ Ansari
**Reviewed:** every AL file at commit af839f4 (main app 0.0.0.2, 21 files) and test app commit 1dd0b9f (5 files), against `docs/2-design/TDD.md` v1.0 (§1–§13; the CR-1 draft in §14 is excluded), Standards Parts 1, 2, 4, 7 and 11 (plus §3.2–§3.3 and §8.1–§8.3), the AL Guidelines *Vibe Coding Rules* (alguidelines.dev, fetched 2026-10-16), and the BCQuality snapshot 86d809b (microsoft/BCQuality, fetched 2026-10-11). Known gaps G1–G17 (`docs/4-prove/GapAnalysis.md`) are referenced, not re-reported.

## 0. Scorecard
First review graded the code at af839f4 (overall **F**, Critical CR9-01). Re-graded below by the Reasoning role (Opus 5.5) after the 3a/3b fixes landed (main 0.0.0.3, tests 0.0.0.2); the 3c fixes (main 0.0.0.4, tests 0.0.0.3) were applied afterwards, compiled 0/0 and are marked where a grade depends on them.
| Dimension | Grade | Evidence |
|---|---|---|
| Standards compliance | **A** | Part 7 re-checked on every changed line: labels for all new text, `MaxLength` on the notice name, `Locked` on the ID and link, no placeholders without a Comment, 4-space indentation, one `using` per namespace used. CR9-11 fixed. |
| Correctness and robustness | **D** | Several Majors fixed in this step: CR9-05 (`SetForceUpdateContact`) and CR9-06 (rename propagation restored). Minors CR9-07, 08, 10 fixed. New Major CR9-24 (raw error when the privacy notice is missing after an upgrade) fixed in 0.0.0.4 (lazy `EnsurePrivacyNotice`). G3 scheduled with CR-1 (AJ, 08-1). |
| Readability and maintainability | **A** | CR9-13 to CR9-16 fixed: one caller check, no duplicate security labels, no 60113↔60118 cycle, `var` last everywhere, no unused Fake or Library procedures. Notes only. |
| Performance | **A** | CR9-17 `SetLoadFields` and the key-backed `RunPageView` (CR9-10) fixed. No record loops, no FlowFields. |
| Security and permissions | **D** | One Critical (CR9-01) and one Major (CR9-04) fixed in this step: caller read inside every guarded public procedure, test GUID sandbox-only, privacy notice confirmed before addresses leave BC, USE covers 60100, secrets stay SecretText with `[NonDebuggable]`. G2 and G4 open but scheduled with CR-1 and accepted by AJ by name (ChangeLog 08-1). |
| Upgrade safety | **C** | 0/0 compile proves no Pending/Removed references; 0.0.0.4 schema is additive (Add). Major CR9-24 (notice created at install only) fixed in this step by the lazy creation in 0.0.0.4. Holds only if the 0.0.0.4 fix is confirmed on a sandbox upgrade. |
| Translation readiness | **A** | §1.9 is "US wording, no translation files". Every new string is a label, no hard-coded text, `Tok` labels Locked. |
| Test coverage | **C** | Major T-01 fixed. 33 meaningful tests (24 + 9 new + privacy-refused test), expected strings checked against the main app's labels; T-05 (approval state restored in CleanUp) and T-06 (privacy-refused test, blank-parameter URL assertion) applied in tests 0.0.0.3. Nothing has run yet (G15): the AL Test Tool run is still owed. |
| **Overall** (the lowest grade above) | **D** | Lowest are Security and Correctness (D). No F remains: Critical CR9-01 is resolved in code. |

Rubric:
| Grade | Meaning |
|---|---|
| **A** | no findings |
| **B** | minor findings only |
| **C** | at least one major, fixed in this step |
| **D** | several majors, or one critical, fixed in this step |
| **F** | a critical left unresolved or accepted |

## 1. Findings by dimension
Severity is **Critical / Major / Minor / Note**. KB = knowledge-backed by a BCQuality article. **[Design]** = the fix changes an FRD or TDD rule, so AJ is asked separately (§3b).

| # | Dimension | File / object | Finding | Rule | Severity | Resolution (proposed) | ChangeLog ref |
|---|---|---|---|---|---|---|---|
| CR9-01 | Security | `src/Setup/obcfuspsUSPSCredentialMgt.Codeunit.al:129-140` (`CheckCaller`, called at :12, :21, :95); `src/Validation/obcfuspsAddressValidation.Codeunit.al:89-100` (`CheckCaller`, called at :13) | `NavApp.GetCallerModuleInfo` is called inside a **local helper**. It returns the module that called *that helper*, always this app, so the F2 caller check always passes. Microsoft's System Application 28.5 says so in `RetenPolAllowedTables.Codeunit.al:35`: "This line of code must be here, in the facade to catch the correct caller module info." 60114 does it correctly, inline in `SetTransport` (:15), but 60113 calls it, so the chain is open. **Impact:** any extension in the tenant can call `"obcfusps Address Validation".SetTransport(<own transport>)` and then `TryValidateCustomerAddress`; its transport receives the token request body holding the Consumer Key and Secret as SecretText and can forward it. The same extension can overwrite or delete the stored credentials via `SetConsumerKey`/`SetConsumerSecret`. Not covered by G2/G4: `Access = Internal` on 60114/60118 would not close it, because 60113 and 60098 stay Public. Tests cannot see the defect (the test app is an allowed caller anyway). | TDD §13.2 (F2); KB `security/internal-access-is-not-a-security-boundary.md`, `security/isolatedstorage-access-must-be-local-or-internal.md` | **Critical** | In each guarded public procedure (60098 `SetConsumerKey`, `SetConsumerSecret`, `ClearToken`; 60113 `SetTransport`; 60114 `SetTransport`), call `NavApp.GetCallerModuleInfo(CallerModuleInfo)` as the **first statement of the public procedure**, then call one shared `internal procedure CheckCallerAllowed(CallerModuleInfo: ModuleInfo)` in 60098 (compares with `NavApp.GetCurrentModuleInfo` and the test-app GUID, raises `CallerNotAllowedErr`). Delete the two local `CheckCaller` procedures and duplicated labels (also clears CR9-13). Add one sentence to TDD §13.2: "GetCallerModuleInfo is called in the public procedure itself, never in a helper." Pattern candidate P1. | — |
| CR9-02 | Security | 60098:147, 60113:257, 60114:449 (`TestAppIdTok`) | The test-app GUID is allowed in every environment, production included. The GUID is in the shipped source, so a per-tenant extension uploaded with that id passes the caller check in production. Uploading needs admin rights, so risk is low. | TDD §13.2 | Minor **[Design]** | In the shared check (CR9-01), accept the test GUID only when `EnvironmentInformation.IsSandbox()`. Amend TDD §13.2. | — |
| CR9-03 | Security | 60098:89 | The access token is stored with `IsolatedStorage.Set`, not `SetEncrypted`. Recorded TDD §4.11 decision (long JWT versus the 215-character limit). Token lives at most `expires_in` minus 60 s, company-scoped. | KB `security/isolatedstorage-setencrypted-for-sensitive-values.md` vs TDD §4.11 | Note | No change; decision stands. CR-1 (Google API key, no token) removes it. | — |
| CR9-04 | Security (privacy) | `src/Validation/obcfuspsAddressValidation.Codeunit.al:48-50`; `obcfuspsUSPSAPIClient.Codeunit.al:25-44`; `obcfuspsSetupRegistration.Codeunit.al:14-18` | Customer address data is sent to an external service with no Business Central Privacy Notice registered and no approval check. Verified in the symbols: `codeunit "Privacy Notice"` exposes `CreatePrivacyNotice(Id; IntegrationName; Link)`, `ConfirmPrivacyNoticeApproval(Id)` and `GetPrivacyNoticeApprovalState(Id)`; its `OnRegisterPrivacyNotices` event is internal in 28.5. | KB `privacy/privacy-notice-consent-for-external-data-transfer.md` | Major **[Design]** | (a) `RegisterAll` creates notice `OBCFUSPS-ADDRESS` (with the provider's privacy link). 60113 calls `ConfirmPrivacyNoticeApproval` after the preconditions and before the HTTP phase; `TestConnection` does the same. If refused: return `PrivacyNoticeNotApprovedErr`, send nothing, log nothing. Needs one FRD rule (FR-1.3, FR-6) and TDD §4.13/§4.16 lines. (b) AJ accepts by name that the admin's **Enabled** switch is the consent, recorded in the ChangeLog. Applies equally to CR-1. | — |
| CR9-05 | Correctness | `src/Validation/obcfuspsValidationWriter.Codeunit.al:81-87` | On Accept, the five address fields are assigned in code and `Customer.Modify(true)` runs. Customer `OnModify` updates the linked Contact only when `IsContactUpdateNeeded()` sees `Rec <> xRec` (BaseApp 28.5 `Customer.Table.al:2597-2608`, `:3824-3860`). On a code-driven Modify, `xRec` mirrors `Rec`, so the Contact is not updated and FRD §4.1 h / FR-9 fails silently. Concrete code cause behind the F12/G17 sandbox check. | KB `data-modeling/xrec-is-a-before-image-only-in-some-triggers.md`; FRD §4.1 h | **Major** | Add `Customer.SetForceUpdateContact(true);` before `Customer.Modify(true);` in `WriteAcceptedSuggestion` (public, `Customer.Table.al:4148`). G17 sandbox check stays as confirmation. No design change. Pattern candidate P2. | — |
| CR9-06 | Correctness | `src/Validation/obcfuspsUSPSValidationLog.Table.al:20-25` (also `"User ID"`, :30-36) | `"Customer No."` has `TableRelation = Customer."No."` **with `ValidateTableRelation = false`**, which also turns off rename propagation. TDD §13.7 F14 (accepted 2026-10-10) says a customer rename rewrites Customer No. on log rows through the table relation. As built, a renamed customer's log rows keep the old number, so the Customer Card action "USPS Validation Log" (RunPageLink) shows no history after a rename. | KB `data-modeling/validate-table-relation-false-suppresses-rename-propagation.md`; TDD §4.6, §13.7 F14 | **Major** **[Design]** | (a) Recommended: delete `ValidateTableRelation = false` on `"Customer No."` (never needed: 60118 assigns directly with no `Validate`; log rows of deleted customers stay readable). Restores F14 as decided. (b) Keep it and change F14 to "the log keeps the number the customer had at check time". Leave `"User ID"` unless AJ wants the same rule. Pattern candidate P3. | — |
| CR9-07 | Correctness | `obcfuspsUSPSAPIClient.Codeunit.al:183-186` | `JToken.AsValue().AsText()` without an `IsNull` check. `"expires_in": null` raises a runtime error, breaking the never-raises contract of TDD §13.1.4. The module's own `GetText` (:364-377) handles null. | KB `web-services/check-json-null-before-converting-values.md` | Minor | Replace with `if not Evaluate(ExpiresIn, GetText(JObject, ExpiresInTok)) then ExpiresIn := 0;`. | — |
| CR9-08 | Correctness | 60113:120-125 vs 60114:209-219 | Precondition 3 accepts any non-blank Post Code in place of City and State. `BuildAddressUrl` sends `ZIPCode` only when the first 5 characters are digits. A customer with only Address and Post Code `'ABCDE'` passes the precondition, so USPS gets street only: wasted calls and an Error row instead of the precondition message. | FRD FR-1.3; TDD §4.13 | Minor **[Design]** | Precondition 3 counts the Post Code only when its first 5 characters are digits. Amend FR-1.3 and TDD §4.13. | — |
| CR9-09 | Correctness | `obcfuspsUSPSSetup.Page.al:150, :158` | A real key or secret typed as exactly `********` is silently ignored. Negligible. | — | Note | None. | — |
| CR9-10 | Correctness (Part 11) | `obcfuspsUSPSValidationLog.Table.al` (no `OnInsert`); `obcfuspsCustomerCard.PageExt.al:50-58` | Under §11.1's definition the log **is** a child table of Customer; TDD §4 says "Parent links N/A everywhere". Against the six parts: (1) link by property — yes, but `RunPageView = sorting(<link field>)` is missing; (4) `TestField` in the table's `OnInsert` — missing; (2), (3), (5), (6) fine or n/a. §11.2 number series: none. | Standards §11.1 parts 1 and 4; TDD §4 | Minor **[Design]** | Add `RunPageView = sorting("Customer No.", "Checked At") order(descending);` to the `obcfuspsValidationLog` action (uses key `CustomerCheckedAt`, keeps newest-first). Add `trigger OnInsert() begin Rec.TestField("Customer No."); end;` to 60109. Correct TDD §4 "Parent links" and §4.6. | — |
| CR9-11 | Standards | test app `obcfuspsTestLibrary.Codeunit.al:4`, `obcfuspsValidationTests.Codeunit.al:4`, `obcfuspsAddrValidatedTests.Codeunit.al:4` | `using OnlyBCFans.USPSAddress;` repeats the file's own namespace (redundant). 60126 omits it (drift inside batch B6). TDD §13.6 prescribed it. | Standards §1.1 | Minor **[Design]** | Remove the 3 lines; amend TDD §13.6. | — |
| CR9-12 | Standards | Standards Guide §1.1 | §1.1 says "One `using` directive per file"; the code correctly has one per namespace used (60100 needs 4), so the literal text cannot be followed. | Standards §1.1 | Note | Surface to the Standards Guide author. No code change. | — |
| CR9-13 | Readability | 60098:129-148, 60113:89-100 + :243, :256-258, 60114:9-22 + :438, :448-449, 60096:187 | Batch drift: the same caller check exists 3 times in 2 shapes (inline in B2, local helper in B1/B4, where CR9-01 lives). Duplicated labels: `TestAppIdTok` ×3, `CallerNotAllowedErr` ×3, `SetupIncompleteErr` ×2, `ShowTextTok` ×2. | Step 09 "redundant code" | Minor | Fixed by CR9-01's single helper. Keep `SetupIncompleteErr` only in 60113 if 60114's copy is unreachable from the UI. | — |
| CR9-14 | Readability | `obcfuspsValidationWriter.Codeunit.al:104, :118` | Circular dependency: 60113 runs 60118, and 60118 instantiates 60113 to call `CanModifyCustomers()`. | Step 09 | Minor | Add `CanModify: Boolean` to `Writer.Init(...)`, computed once by 60113; delete the 60113 global in 60118. | — |
| CR9-15 | Readability | `obcfuspsUSPSSetupWizard.Page.al:146-161` | Drift: wizard declares globals between triggers and procedures. Every other main-app object puts the `var` block last. | Step 09 | Minor | Move the `var` block after `FinishWizard`. | — |
| CR9-16 | Readability (dead code) | test app `obcfuspsFakeUSPSTransport.Codeunit.al:44-49` (`EnqueueTokenNoResponse`), `:75-78` (`GetLastAddressUrl`) | Two public procedures never called by any test. | Standards §1.5 | Minor | Use them in the T-02 tests (preferred), or delete them. | — |
| CR9-17 | Performance | `obcfuspsAddressValidation.Codeunit.al:41` | Read-only `Customer.Get` loads the whole wide row; only 7 fields used. | KB `performance/use-setloadfields-for-partial-records.md` | Minor | Before :41 add `Customer.SetLoadFields("No.", "Country/Region Code", Address, "Address 2", City, County, "Post Code");`. | — |
| CR9-18 | Performance | 60109 keys | Retention Policy filters on `"Checked At"` and no key starts with it. Volume low (TDD §11 note 2). | KB `performance/design-covering-keys-from-read-pattern.md` | Note | None now. | — |
| CR9-19 | Readability | 60114:202, 60112:194-198 | `BuildAddressUrl(var ...)` does not need `var`; the hand-built LF could use "Type Helper".`LFSeparator()`. | — | Note | Optional. | — |
| CR9-20 | Readability | public procedures of 60098, 60113, 60114, 60118 | No `///` XML doc on public procedures. | KB `style/xmldoc-for-public-library-procedures.md` | Note | Optional, for a PTE. | — |
| CR9-21 | Security | `app.json` `resourceExposurePolicy` | `allowDebugging`, `allowDownloadingSource`, `includeSourceInSymbolFile` all true. Acceptable for a PTE (every secret path is `[NonDebuggable]`); also what exposes the test GUID (CR9-02). | — | Note | Keep; document in `docs/4-prove/Deployment.md` (Step 11). | — |
| CR9-22 | Readability (repository) | project root | `src/logo/` was untracked although `app.json:12` names `src/logo/AppLogo.png`, so a fresh clone cannot build. `docs/`, `.gitignore`, `ProjectProgress.md` also untracked; stray root `.app` remains (ChangeLog 08-1). | Ops § Repository Hygiene | Note | Main role: commit `src/logo/AppLogo.png` and the docs; stray `.app` is AJ's call. | 08-1 |
| CR9-23 | Error handling | whole app | No telemetry emitted (TDD §7 decision). AL Guidelines ask for telemetry in error handling. | AL Guidelines *Vibe Coding Rules* | Note | Surfaced (§5). If wanted later: `Session.LogMessage` on Error outcomes with HTTP status only, no address. | — |
| T-01 | Test coverage | test app `obcfuspsValidationTests.Codeunit.al:236-257`, handler `:311-320`; main 60113:70-72, :215 | Test A2's `ModalPageHandler` runs `Customer.Modify()` inside `RunModal`. After the handler returns, `RunWriter` runs `if not Writer.Run()` in that open write transaction; the platform refuses ("Codeunit.Run is allowed in write transactions only if the return value is not used"). The test fails with a platform error instead of exercising `AddressChangedMsg`. Production is unaffected. | KB `performance/al-methods-limited-during-write-transactions.md`, `performance/codeunit-run-requires-prior-commit-inside-transaction.md` | **Major** | Add `Commit();` after `Customer.Modify();` in `EditCustomerThenAcceptHandler`, modeling a committed edit from another session. Confirm on the first test run (G15). Pattern candidate P4. | — |
| T-02 | Test coverage | test app 60126 | Untested: (a) the request URL (name and number never sent, ZIP+4 split, `UpperCase` of state, blank parameters omitted; `LastAddressUrl` captured but never asserted); (b) token no-response; (c) address 400 → `CouldNotReadErr` with USPS text; (d) 5xx → `NotRespondingErr`; (e) 200 with invalid JSON or no `address` → `UnexpectedResponseErr`; (f) token 200 without `access_token`; (g) `TestConnection` success and failure; (h) G3's blank-address case (R-08-2). | TDD §4.12; FRD FR-1, FR-7 | Minor | Add tests (a)–(g) to 60126; no new IDs. Test app version 0.0.0.2, dependency raised to the new main build. | — |
| T-03 | Test coverage | test app `obcfuspsTestLibrary.Codeunit.al:68-79` | Expected message texts are copies of the main app's labels; necessary, and a changed label fails the test, which catches drift. | — | Note | None. | — |
| T-04 | Test coverage | test app launch config (`startupObjectId` 130401) | Whether the AL Test Tool's runner isolation leaves `Commit()` effective (TDD §13.9 item 5) decides whether every `if Writer.Run()` sees a clean transaction. Not verifiable without a run. | KB `testing/testisolation-belongs-on-the-test-runner.md` | Note | Watch on the first run (G15). If writer tests fail with the write-transaction message, select the runner without isolation. | — |

| CR9-24 | Upgrade safety / Correctness | `obcfuspsAddressValidation.Codeunit.al` (ConfirmPrivacyNotice), `obcfuspsUSPSSetup.Page.al` (Test Connection), `obcfuspsSetupRegistration.Codeunit.al` | Found in the post-fix review. The privacy notice was created only by the install codeunit and on company creation, so an upgrade from 0.0.0.1/0.0.0.2 left it missing and `ConfirmPrivacyNoticeApproval` raised "The privacy notice … does not exist" on every validation and Test Connection, breaking the never-raises rule (TDD §13.1.4). | System App `PrivacyNoticeImpl`:79-83 | **Major** | Fixed in 0.0.0.4: `EnsurePrivacyNotice()` (idempotent `CreatePrivacyNotice`) is called before every confirm, followed by `Commit()`. TDD §4.13 line at Step 10. Pattern candidate P5. | 09-2 |
| T-05 | Test coverage | test library | `SetApprovalState(Agreed)` as SUPER records organization-wide consent and was never restored. | — | Minor | Fixed in tests 0.0.0.3: state saved in `InitSetup`, restored in `CleanUp`. | 09-2 |
| T-06 | Test coverage | test app 60126 | Privacy-refused path and blank-URL-parameter omission untested. | — | Minor | Fixed in tests 0.0.0.3: `TestPrivacyRefusedSendsNothing` (modal handler on page "Privacy Notice", Disagree) and URL assertions for `streetAddress=` present and `secondaryAddress=` absent. Unrun. | 09-2 |

Already-known gaps still open in code, **not re-reported**: G2 (R-08-1), G3 (R-08-2), G4 (R-08-3), G5 (R-08-4), G15/G17 (R-08-5), G16. CR9-01 is **not** a duplicate of G2/G4: it is a broken check in objects that stay Public after R-08-1 and R-08-3.

## 2. Dead-code and obsolete-reference scan
Standards §1.5, 100 % of files. Searched for empty triggers, commented-out code, `// TODO`, duplicate field exposures and unused procedures. Obsolete references: the 0/0 compile with analyzers (ChangeLog 07-2) proves none to `Pending` or `Removed` symbols. The one subscribed event, `Company-Initialize.OnCompanyInitialize`, is active in BaseApp 28.5.
| File | Result | Notes |
|---|---|---|
| src/Setup/OBCFUSPSUSPSADMIN.PermissionSet.al | Clean | |
| src/Setup/OBCFUSPSUSPSUSE.PermissionSet.al | Clean | |
| src/Setup/obcfuspsSetupRegistration.Codeunit.al | Clean | |
| src/Setup/obcfuspsUSPSCredentialMgt.Codeunit.al | Clean | CR9-01 / CR9-13 are defects, not dead code |
| src/Setup/obcfuspsUSPSEnvironment.Enum.al | Clean | |
| src/Setup/obcfuspsUSPSInstall.Codeunit.al | Clean | |
| src/Setup/obcfuspsUSPSSetup.Page.al | Clean | |
| src/Setup/obcfuspsUSPSSetup.Table.al | Clean | |
| src/Setup/obcfuspsUSPSSetupWizard.Page.al | Clean | CR9-15 is layout only |
| src/Setup/obcfuspsValidationResult.Enum.al | Clean | |
| src/Validation/obcfuspsAddressValidation.Codeunit.al | Clean | |
| src/Validation/obcfuspsCustomer.TableExt.al | Clean | |
| src/Validation/obcfuspsCustomerCard.PageExt.al | Clean | |
| src/Validation/obcfuspsUSPSAPIClient.Codeunit.al | Clean | `//` hits are URL labels only |
| src/Validation/obcfuspsUSPSAddressBuffer.Table.al | Clean | |
| src/Validation/obcfuspsUSPSAddressCompare.Page.al | Clean | |
| src/Validation/obcfuspsUSPSHttpTransport.Codeunit.al | Clean | |
| src/Validation/obcfuspsUSPSLogEntries.Page.al | Clean | |
| src/Validation/obcfuspsUSPSTransport.Interface.al | Clean | `///` XML doc, not commented-out code |
| src/Validation/obcfuspsUSPSValidationLog.Table.al | Clean | |
| src/Validation/obcfuspsValidationWriter.Codeunit.al | Clean | |
| Tests/src/obcfuspsFakeUSPSTransport.Codeunit.al | **Not clean** | `EnqueueTokenNoResponse`, `GetLastAddressUrl` unused (CR9-16) |
| Tests/src/obcfuspsTestLibrary.Codeunit.al | Clean | redundant `using` (CR9-11) |
| Tests/src/obcfuspsValidationTests.Codeunit.al | Clean | redundant `using` (CR9-11) |
| Tests/src/obcfuspsAPIClientTests.Codeunit.al | Clean | |
| Tests/src/obcfuspsAddrValidatedTests.Codeunit.al | Clean | redundant `using` (CR9-11) |

## 3. Fix batch presented for approval
Main-app fixes: build 0.0.0.3, then 0.0.0.4. Test-app fixes: 0.0.0.2, then 0.0.0.3 (dependency raised to the matching main build).
| Findings | Approved by | Date | Recompiled / repackaged / retested |
|---|---|---|---|
| 3a, no design change: CR9-01 (+ TDD §13.2 sentence at Step 10), CR9-05, CR9-07, CR9-13, CR9-14, CR9-15, CR9-17; test app T-01, T-02, CR9-16 | AJ Ansari | 2026-10-16 | 0.0.0.3 / Tests 0.0.0.2 compiled 0/0 and verified by the Reasoning role. **Retest pending: AJ installs and runs the AL Test Tool.** ChangeLog 09-1. |
| 3b, design-rule changes: CR9-04 option (a), CR9-06 option (a), CR9-08, CR9-10, CR9-11, CR9-02 | AJ Ansari | 2026-10-16 | Same builds. FRD/TDD amendments at Step 10. **Retest pending.** |
| 3c, found in the post-fix review: CR9-24, T-05, T-06 | AJ Ansari | 2026-10-16 | Main 0.0.0.4 / Tests 0.0.0.3 compiled 0 errors / 0 warnings (CodeCop, UICop, PerTenantExtensionCop) and packaged. Reasoning-role confirmation of CR9-24 and **retest pending**. ChangeLog 09-2. |

## 4. Pattern candidates
Flagged to the human for the OCPF BC AL Patterns Library, never added unilaterally.
| Pattern | Where it recurred | Flagged to |
|---|---|---|
| P1 "`NavApp.GetCallerModuleInfo` must be the first call in the public facade procedure, never in a helper" (otherwise the check silently passes) | B1 (60098) and B4 (60113); correct in B2 (60114) | AJ Ansari |
| P2 "Code-driven `Customer.Modify(true)` after address changes needs `SetForceUpdateContact(true)`, or the Contact is not synced (xRec = Rec)" | B4 (60118); general to any code changing Customer contact fields | AJ Ansari |
| P3 "`ValidateTableRelation = false` on a log or audit field turns off rename propagation" | B3 (60109 Customer No., User ID) | AJ Ansari |
| P4 "A test handler that writes during `RunModal` makes the next `if Codeunit.Run()` fail; Commit in the handler" | B6 (60125 A2) | AJ Ansari |
| P5 "Create a Privacy Notice lazily and idempotently before `ConfirmPrivacyNoticeApproval`; install-only creation raises after an upgrade" | 60100/60113 | AJ Ansari |
| (carried from 07-3) "Label to SecretText needs a Text in between" | B6 | AJ Ansari (already flagged) |

## 5. Conflicts surfaced
| Conflict | Sources | Decision | Decided by |
|---|---|---|---|
| Indentation: AL Guidelines says two spaces; the Standards Guide says four | AL Guidelines vs Standards §1.6 | Standards wins; code uses 4 spaces | Standards precedence |
| Telemetry: AL Guidelines asks for it; TDD §7 says none | AL Guidelines vs TDD §7 | Open — CR9-23 | *(awaiting: AJ Ansari)* |
| AL Guidelines "use TryFunctions" vs the code's `Codeunit.Run` write phase | AL Guidelines vs BCQuality `performance/use-tryfunction-for-error-catching-not-rollback.md`, TDD §13.1 | The code is right: a TryFunction does not roll back | Reasoning role |
| Build output: BCQuality says gitignore the `.app` output folder; OCPF says packages are git-tracked | BCQuality vs runbook | OCPF rule wins | Runbook |
| Privacy Notice registration: BCQuality recommends subscribing to `OnRegisterPrivacyNotices`, but it is `internal` in System Application 28.5 | BCQuality vs downloaded symbols | Symbols win: use `CreatePrivacyNotice` (CR9-04) | Operating Rule 2 |
| Access token stored with `Set`, not `SetEncrypted` | BCQuality vs TDD §4.11 | TDD decision stands (CR9-03); moot under CR-1 | AJ Ansari (TDD sign-off 2026-10-10) |
| "One `using` directive per file" (literal reading) | Standards §1.1 vs required multi-namespace files | Code right; Standards wording to clarify (CR9-12) | *(awaiting: AJ Ansari, as framework author)* |

## Before calling this done
- [x] Every dimension in §0 is graded with evidence, and Overall is the lowest of the eight (D).
- [ ] Every Critical and Major finding is resolved or explicitly accepted by name. CR9-01, CR9-04, CR9-05, CR9-06, CR9-24, T-01 resolved in code; G2/G3/G4 accepted and scheduled by AJ Ansari (08-1). Pending: install and retest.
- [x] §2 shows every file clean.
- [ ] Every code fix went through the Step 07 cycle: compiled and packaged 0/0 at 0.0.0.4 / Tests 0.0.0.3; **AJ's sandbox install and AL Test Tool run not yet recorded.**
- [ ] Changes committed (both repos still uncommitted) — AJ to ask.
- [ ] Pattern candidates P1–P5 flagged to AJ Ansari.
