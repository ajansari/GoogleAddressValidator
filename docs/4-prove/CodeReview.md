# Code Review — Google Address Validator

> **Renumbered in 1.3.0.0:** object and field numbers in this historical document are the pre-1.3 numbers (60093–60192). `docs/1-define/ObjectRegister.md` gives each object's old and new ID.


**Date:** 2026-10-16 · **Reviewer:** Reasoning role, Opus 5.5 · **Fixes applied by:** Main role (Sonnet 5.5), for AJ Ansari

**Reviewed:**
- **Code:** main app 0.0.0.6 at commit 3fc61f1 (`src/` clean in the working tree, 23 files) and test app 0.0.0.6 at commit 3b0c642 (6 files, 55 tests: 60125 = 18, 60126 = 29, 60127 = 8).
- **Design:** `docs/2-design/TDD.md` §14 including 2.17 (normative, signed off 2026-10-16), §13 where §14 does not replace it, and `docs/4-prove/PostDevTDD.md` Part B.
- **Standards:** Parts 1, 2, 4, 7 and 11, plus §3.2–§3.3 and §8.2–§8.3.
- **AL Guidelines:** *Vibe Coding Rules*, fetched 2026-10-16 (error-handling, testing, code-style and performance pages; alguidelines.dev has no separate "Best Practices" page).
- **BCQuality:** snapshot 86d809b, condensed pass (`skills/entry.md` routes this goal to the `al-code-review` super-skill; leaf articles read directly, `knowledge-index.json` not rebuilt). Read against the code: security (`secrettext-with-httpclient`, `prefer-oauth2-over-api-keys-for-external-http-calls`, `getlasterrortext-storage-is-privacy-not-security`, `do-not-grant-rights-beyond-a-users-entitlement`, `commitbehavior-attribute-scopes-explicit-commits`, `validate-unauthenticated-response-before-use`), web-services (`handle-httpclient-platform-failure-before-response-access`), privacy (`getlasterrortext-customer-content-in-errors`), error-handling (`log-writes-must-survive-rollback`), testing (`reset-per-test-state-before-the-isinitialized-guard`, `ui-handlers-in-tests`, `test-one-when-per-test`).
- **Compile:** not re-run by the reviewer; 0 errors / 0 warnings taken from ChangeLog 08-3. CodeCop, UICop and PerTenantExtensionCop are on in `.vscode/settings.json`; no `#pragma` in either app.
- **Not re-reported:** gaps GA-01 to GA-07 (fixed in 0.0.0.6) and the scheduled items GA-08, GA-10 to GA-26 (`docs/4-prove/GapAnalysis.md`). The earlier USPS review is `docs/4-prove/CodeReview.USPSbuild-0.0.0.4.md`.

**PostDevTDD Part B behaviours confirmed to still hold:** B-2 caller read as first statement of every guarded public procedure (60098:15; 60113:16, 25; 60114:11, 21, 32, 44), test GUID sandbox-only (60098:72); B-3 privacy notice created on demand plus `Commit` before every approval check, after the preconditions and before `FillOriginal` and the send; B-4 `CanModify` passed to the Writer, `SetForceUpdateContact(true)` before `Modify(true)`, `Insert(true)`; B-5 `SetLoadFields` and `HasUsableZip`; B-7 log "Customer No." without `ValidateTableRelation = false`, `OnInsert` `TestField`, `RunPageView`; B-8 wizard `var` block last. B-6 (USPS client) no longer applies.

## 0. Scorecard
First pass graded the code at 0.0.0.6 (overall **C**, Major CR9G-01). Re-graded below by the Reasoning role (Opus 5.5) after the 3a/3b fixes landed: main **0.0.0.7**, tests **0.0.0.7**, 2026-10-16.
| Dimension | Grade | Evidence |
|---|---|---|
| Standards compliance | **A** | The Part 7 table still has no hits. The fixes added Locked tokens and kept every Caption, ToolTip and ApplicationArea; §1.8 file names unchanged. No `#pragma`; analyzers on. |
| Correctness and robustness | **B** | CR9G-10 and CR9G-11 fixed (60119:219, :32, :40-43). One new Minor remains: CR9G-19 (empty or duplicated Google message in AccessDenied and CouldNotRead). `CanModify` is set before every use. JSON reads null-safe. |
| Readability and maintainability | **B** | CR9G-07, 08 and 09 fixed; dead-code scan clean in both apps. The Minor CR9G-06 literal drift is still open; CR9G-21 and CR9G-22 are Notes. |
| Performance | **A** | CR9G-13 fixed: `GetEffectivePermission` runs once per call (60113:60). `SetLoadFields` and the key-backed `RunPageView` in place. CR9G-22 is a Note. |
| Security and permissions | **A** | CR9G-12 fixed: caller checks are the first statements of 60113:36 and :56; every public entry of 60113 and 60114 with side effects is guarded. SecretText end to end, `[NonDebuggable]` on the key paths, the key only in the header. CR9G-14 and CR9G-17 remain Notes. |
| Upgrade safety | **A** | 0.0.0.7 changes code and labels only, no schema, so Add. Nothing ever installed (GA-26). The 0/0 compile with analyzers shows no Pending or Removed references. |
| Translation readiness | **A** | CR9G-05 fixed (Lib :117). Every placeholder label in both apps has a Comment, including 60119:437 and Lib :118. Technical tokens Locked. §1.9 US wording. CR9G-21 is a Note. |
| Test coverage | **C** | The Major CR9G-01 was fixed in this step (Clear in all three Prepares). CR9G-02 and CR9G-03 fixed with 6 new tests, 61 in total, every expectation matching the main-app labels. New Minor CR9G-20. Tests never run (GA-23). |
| **Overall** (the lowest grade above) | **C** | Lowest is Test coverage (C), from a Major fixed in this step. No Critical, no F. |

Rubric:
| Grade | Meaning |
|---|---|
| **A** | no findings |
| **B** | minor findings only |
| **C** | at least one major, fixed in this step |
| **D** | several majors, or one critical, fixed in this step |
| **F** | a critical left unresolved or accepted |

## 1. Findings by dimension
Severity is **Critical / Major / Minor / Note**. **[Design]** = the fix changes an FRD or TDD rule (asked separately, §3b). KB = backed by a BCQuality article.

| # | Dimension | File / object | Finding | Rule | Severity | Resolution (proposed) | ChangeLog ref |
|---|---|---|---|---|---|---|---|
| CR9G-01 | Test coverage | `Tests/src/obcfgavValidationTests.Codeunit.al:13, 467, 494, 511-526, 573-580` | The global `Validator` (60113) holds its own Address Service instance. `TestProviderSeam` (:467) calls `Validator.SetProvider(FakeProvider)`, which sets `ProviderSet := true` inside that instance (60114:23-24). Globals in a test codeunit keep their values between its test methods, and `Prepare()` only calls `SetTransport`, so every later test in the codeunit runs on the fake provider. `TestAttributionShown` (:511, declared after the seam tests) gets `Reset()` defaults: validated, blank suggested values; the dialog opens with "Suggestion from Test Provider", OK writes a blank address, and the assertion expecting "Suggestion from Google Maps" fails. Passes alone, fails in a full run. | KB `testing/reset-per-test-state-before-the-isinitialized-guard.md` | **Major** | `Clear(Validator);` as the first statement of `Prepare()` in 60125, and for consistency 60126 and 60127. Pattern candidate P6. | — |
| CR9G-02 | Test coverage (dead code) | Test lib `obcfgavTestLibrary.Codeunit.al:792-800` (`DpvUnconfirmedSecondaryText`, `DpvNotDeliverableText`, labels :125-126); `obcfgavFakeAddressProvider.Codeunit.al:51-61` (`PresetFailure`, `SetHasCredentials`) | Four public procedures never called, so the DPV **S** and **N** branches of `DeliveryWarning` (60113:203-206) and the seam's failure and no-credentials paths (60114:86-89) have no test. | Standards §1.5; TDD 2.14 | Minor | Preferred: add tests: (a) Confirmed with DPV S → `ConfirmedNoteText(…, DpvUnconfirmedSecondaryText())`; (b) dialog warning with DPV N; (c) `PresetFailure(msg, true)` gives Not Found through the seam, `(msg, false)` gives Error; (d) `SetHasCredentials(false)` gives Error with `MissingApiKeyText()` and HTTP 0. Otherwise delete them. | — |
| CR9G-03 | Test coverage | Test lib `GoogleResultJson` (:265-327) | All callers pass `Vacant = false, Business = false`; `has*` always `false`. No test parses a JSON boolean `true` or asserts "Address Complete", Has Replaced/Inferred/Spell Corrected/Unconfirmed, Business, PO Box or the dialog's `deliveryNotes`. `GetBoolean` relies on `JsonValue.AsText()` of a JSON boolean (60119:421-424), listed as not verified in ChangeLog 07a-3: if wrong, every test would still pass. | TDD 2.5; FRD FR-4 | Minor | One test: a result with `hasReplacedComponents: true`, `business: true`, `dpvVacant: 'Y'`; assert log "Address Complete" = true and capture `ComparePage.deliveryNotes.Value()` in the handler to assert the Replaced, Vacant and Business texts. | — |
| CR9G-04 | Test coverage | `obcfgavProviderTests.Codeunit.al:422-423`; `obcfgavFakeHttpTransport.Codeunit.al:107` | `TestKeyOnlyInHeader`'s "log does not contain the key" assertion cannot fail because the fake never echoes the key; `ContainsSecret(…) or Contains(…)` would also be true for a plain-Text header, so it does not prove the key travels as SecretText. | KB `security/secrettext-with-httpclient.md` | Note | After the spike confirms `ContainsSecret` at runtime, assert it alone; reword the log assertion as a regression guard. | — |
| CR9G-05 | Translation readiness | Test lib `obcfgavTestLibrary.Codeunit.al:116` | `ProviderMessageTxt` has placeholders but no `Comment` (the main-app copy at 60119:449 has one). | Standards §8.3 | Minor | Copy the `Comment` from 60119:449. | — |
| CR9G-06 | Readability | Test app: 60126:409 comment "G3 and FR-1 step 4"; literals `'OTHER'` (60126:286, 310) while 60127 has `OtherTok`; `'UNAUTHENTICATED'`, `'RESOURCE_EXHAUSTED'`, `'UNAVAILABLE'`, `'NOT_FOUND'`, `'PREMISE_PROXIMITY'`, `'BLOCK'`, `'GRANULARITY_UNSPECIFIED'`, `'US'`; `PremiseTok` declared in four objects, `FixTok` in three | Drift between test codeunits: stale USPS gap id in a comment, inline literals mixed with Locked tokens. | Step 09 consistency | Minor | Correct the comment to "FR-1 step 4 and §5: …". Move shared Google tokens into the library or declare them consistently as `Tok` labels. | — |
| CR9G-07 | Readability (dead code) | `src/Validation/obcfgavGoogleAddressClient.Codeunit.al:26-27, 43, 129-130, 137, 340, 348-349, 356-358, 491, 493` | `ReadError` fills `ErrorCode` and `ErrorStatus`; neither caller (`TestConnection`, `HandleResponse`) reads them. `CodeTok` and `StatusTok` exist only to feed them. `MapError` uses only the HTTP status and reason, as TDD 2.5 intends. | Standards §1.5 | Minor | Signature `ReadError(ResponseBody: Text; var ErrorMessage: Text; var Reason: Text)`; delete the four locals, two out-parameters, the `Evaluate`/status lines and the two labels. Step 10: TDD 2.5 "read `error.message` and the ErrorInfo `reason`" (Spec stale). | — |
| CR9G-08 | Readability (redundant code) | 60119:32-35 and label :436 vs 60114:55-58 and :174 (`MissingApiKeyErr`); 60113:292 vs 60114:173 (`SetupIncompleteErr`); 60113:311 vs 60096:168 (`ShowTextTok`) | The client's `TestConnection` repeats the credentials check the service already makes on the only path that reaches it (60119 is Internal). Two labels duplicated with identical text. | Step 09 | Minor | (a) Delete 60119:32-35 and its `MissingApiKeyErr`. (b) `internal procedure SetupIncompleteText(): Text` in 60114, called from 60113 `CheckPreconditions`; delete the 60113 label. (c) `ShowTextTok` is a Locked `'%1'` passthrough: keep both copies (Note). | — |
| CR9G-09 | Readability (batch drift) | `obcfgavAddressValidation.Codeunit.al:201, 203, 205` (`'D'`,`'S'`,`'N'`); `obcfgavAddressCompare.Page.al:207-208` (`'Strong'`,`'Standard'`) | R4 uses bare literals where R2 uses Locked tokens for the same kind of value; the same procedure already uses `ConfirmAddSubpremisesTok`. | Step 09; Standards §8.3 | Minor | 60113: add `DpvMissingSecondaryTok`, `DpvUnconfirmedSecondaryTok`, `DpvNotConfirmedTok` (Locked). 60112: `exit(Format(PageStyle::Strong))` / `Format(PageStyle::Standard)` (pattern in System App 28.5 `ExtensionManagement.Page.al:479`). | — |
| CR9G-10 | Correctness (UX) | `obcfgavGoogleAddressClient.Codeunit.al:221-224`, label :437 | With no missing/unconfirmed components `Reason` is blank and the Not Found message ends with a trailing space; stored in "User Message" and shown. The test library copies the same format, so tests pass either way. | TDD 2.5 | Minor | `DelChr(StrSubstNo(NotValidatedMsg, Reason), '>', ' ')` and the same in Lib `NotValidatedText`. | — |
| CR9G-11 | Correctness (UX) | `obcfgavGoogleAddressClient.Codeunit.al:38, 46`, label :448 | With no response, Test Connection shows "…failed. Google Maps is not responding. Try again later. Google message: " with nothing after the colon; same at :46 whenever Google's error body has no `message`. | TDD 2.11 | Minor **[Design]** (label text) | New label `TestConnectionFailedNoMessageErr: 'The connection to Google Maps failed. %1'` (Comment) used when `ErrorMessage = ''`. Lib `TestConnectionFailedText(Reason, '')` returns the new form. TDD 2.11 gains one row at Step 10. | — |
| CR9G-12 | Security / Correctness | `obcfgavAddressValidation.Codeunit.al:30-96` (`ValidateCustomerAddress`, `TryValidateCustomerAddress`, Public, no caller check); commits at :69, :118, :254, :267, :283; `RunModal` at :92 and in `ConfirmPrivacyNoticeApproval` | GA-02 closed the service; the orchestrator is still a public surface. (1) Another extension can loop `TryValidateCustomerAddress`: Confirmed and Not Found paths need no UI, so each call is billed and logged against the company's key, breaking FRD §5 "one customer per user action". Consent and logging still hold. (2) With `GuiAllowed() = false` (job queue, API) the dialog `RunModal` and privacy page raise, breaking the "never raises" contract (TDD §13.1.4). (3) It commits the caller's open transaction. | FRD §10 §5; TDD §13.1.4; B-2 | Minor **[Design]** | AJ chooses. **(a) Recommended:** caller check as first statements of both procedures (this app's Customer Card and the test app in a sandbox pass); Documentation §3.2/§3.3 and TDD §13.1.4 gain one sentence. **(b)** Keep public, add `if not GuiAllowed()` precondition with a new `NoUserInterfaceErr`, and document "commits; interactive only". | — |
| CR9G-13 | Performance | `obcfgavAddressValidation.Codeunit.al:85, 263, 103-110` | `CanModifyCustomers()` (`GetEffectivePermission`) runs at :85 and again inside every `RunWriter` (:263), twice on the dialog path. | AL Guidelines Performance | Minor | Compute once in `TryValidateCustomerAddress`, pass to `RunWriter` as a parameter. | — |
| CR9G-14 | Security | `obcfgavGoogleAddressClient.Codeunit.al:70, 138, 359` | **Can Google's `error.message` contain the key? From the code, no path puts it there.** The key travels only in the `X-Goog-Api-Key` header as SecretText (:70), the URL is the fixed `EndpointTok`, the body holds address fields only. Only `error.message` is stored ("Provider Message", CustomerContent) and shown. Google's documented messages describe the condition (project number, or for an IP-restricted key the egress IP), not the key — from knowledge, not verified live. No in-AL redaction is possible without `SecretText.Unwrap()` (OnPrem-scoped). | KB `secrettext-with-httpclient`, `getlasterrortext-storage-is-privacy-not-security` | Note | No code change; keep spike item 14.y "`error.message` never contains the key". | — |
| CR9G-15 | Correctness | `obcfgavGoogleAddressClient.Codeunit.al:44-45` | Test Connection reports success for any 400 whose reason is not `API_KEY_INVALID`, including a 400 with no ErrorInfo; if Google sent an invalid-key 400 without ErrorInfo the key would be reported as working. Matches TDD 2.5 as written. | TDD 2.5 / Q7 | Note | Spike 14.y. No change now. | — |
| CR9G-16 | Readability | Public procedures of 60113 and 60114 (no `///`); `Caption` before/after `PageType` varies; magic numbers `* 1000` (60114:59, :91), `5` (60100:65), LF char (60112:216) | Small style drift (CR9-19, CR9-20 carried). | AL Guidelines Code Style | Note | Optional `///` on public procedures (state "commits; opens a modal dialog"); optional constant for milliseconds. | — |
| CR9G-17 | Security (permissions) | `OBCFGAVGAVUSE.PermissionSet.al` | The sets cover only this extension's objects. Accept also needs Customer Modify and, through `SetForceUpdateContact`, Contact Modify. USE-only users get a logged Error (customer unchanged). `CanModifyCustomers` handles license-clipped users. Same as GA-13. | KB `do-not-grant-rights-beyond-a-users-entitlement` | Note | No code change; Deployment.md and UserGuide list the standard permissions (Step 11). | — |
| CR9G-18 | Test coverage | 60125 `TestPreconditionsBlockTheCall` (5 WHENs), `TestIgnoredLoggedEachTime`, 60127 `TestCancelLeavesFlagUnchanged`; fixed fixture strings | More than one WHEN in some tests; deterministic fixtures. Acceptable (flow-style tests against a fake). | KB `test-one-when-per-test`, `test-data-must-be-random-and-complete` | Note | None. Runner isolation / Commit question (T-04) waits on the first run (GA-23). | — |

| CR9G-19 | Correctness (UX) | 60119:144, :156; labels :432-433; :43 | Found in the post-fix pass; the P7 problem behind CR9G-10/11, not fixed everywhere. (1) With no Google `message`, `CouldNotReadErr` (400 in validate) and `AccessDeniedErr` (403 other) end in "…: " with nothing after the colon; in Test Connection the second becomes "…Google Maps refused the request: ". (2) With a message, a Test Connection 403 other shows the message **twice**. No test covers either. | FR-7 / TDD 2.11 | Minor **[Design]** | In MapError, when `ErrorMessage = ''` use two no-message labels ('Google Maps refused the request.', 'Google Maps could not read the address.'); in TestConnection use `TestConnectionFailedNoMessageErr` whenever the mapped text already contains ErrorMessage; mirror in the library and add tests. | — |
| CR9G-20 | Test coverage | 60119:40-41; 60126 | The D-2 branch "HTTP error, no Google message" has no test; only the no-response branch does. | — | Minor | New test: `Fake.EnqueueResponse(401, Lib.GoogleErrorJson(401, 'UNAUTHENTICATED', '', ''))`, expect `Lib.TestConnectionFailedText(Lib.ApiKeyRejectedText(), '')`. | — |
| CR9G-21 | Translation readiness | 60119:438; Lib :116 | The Comment on `TestConnectionFailedErr` still says "%2 … (can be blank)"; since D-2 it never is. | — | Note | Remove "(can be blank)" in both copies. | — |
| CR9G-22 | Performance | 60113:60, :298 | `CanModify` is computed before Customer.Get, preconditions and the privacy check, so refused calls also pay for it. Correct as written. | — | Note | Optional: move to just before `FillOriginal`. | — |
| CR9G-23 | Documentation | TDD §13.1.4, PostDevTDD Part B-2, Documentation §3.2/§3.3 | D-1 adds an exception to "TryValidateCustomerAddress never raises": it now raises `CallerNotAllowedErr` for any other module. | — | Note (Step 10/11) | One sentence in each document; add 60113:36 and :56 to the B-2 list. | — |
| CR9G-24 | Test coverage | Lib :286-289, :325 | `hasReplacedComponents`, `hasInferredComponents`, `hasSpellCorrectedComponents`, `hasUnconfirmedComponents` and `poBox` are always `false`, so their five dialog notes are never asserted; they share the now-proven `GetBoolean` path. | — | Note | Optional extra fixture. | — |

Already-known items still open in code and **not re-reported**: GA-08, GA-10, GA-12, GA-13, GA-23, GA-24, GA-25. CR9G-12 is **not** GA-02 (GA-02 was the service, fixed).

## 2. Dead-code and obsolete-reference scan
Standards §1.5, 100 % of files: empty triggers, commented-out code, `// TODO`, unused procedures and labels (by script across both apps), duplicate field exposures, `#pragma` (none). Obsolete references: the 0/0 compile with analyzers proves none to Pending or Removed symbols; subscribed events are `Company-Initialize.OnCompanyInitialize` and, in the test app, the platform `OnBeforeModifyEvent`.
| File | Result | Notes |
|---|---|---|
| src/Setup/OBCFGAVGAVADMIN.PermissionSet.al | Clean | `Setup Registration = X` also in included USE set (redundant, harmless) |
| src/Setup/OBCFGAVGAVUSE.PermissionSet.al | Clean | |
| src/Setup/obcfgavAddressProvider.Enum.al | Clean | |
| src/Setup/obcfgavCredentialMgt.Codeunit.al | Clean | |
| src/Setup/obcfgavInstall.Codeunit.al | Clean | |
| src/Setup/obcfgavSetup.Page.al | Clean | `ShowTextTok` duplicate is a Note |
| src/Setup/obcfgavSetup.Table.al | Clean | |
| src/Setup/obcfgavSetupRegistration.Codeunit.al | Clean | |
| src/Setup/obcfgavSetupWizard.Page.al | Clean | |
| src/Setup/obcfgavValidationResult.Enum.al | Clean | |
| src/Validation/obcfgavAddressBuffer.Table.al | Clean | |
| src/Validation/obcfgavAddressCompare.Page.al | Clean | literal styles are CR9G-09 (drift) |
| src/Validation/obcfgavAddressProvider.Interface.al | Clean | |
| src/Validation/obcfgavAddressService.Codeunit.al | Clean | duplicate labels CR9G-08 |
| src/Validation/obcfgavAddressValidation.Codeunit.al | Clean | |
| src/Validation/obcfgavCustomer.TableExt.al | Clean | |
| src/Validation/obcfgavCustomerCard.PageExt.al | Clean | |
| src/Validation/obcfgavGoogleAddressClient.Codeunit.al | Clean | fixed in 0.0.0.7 (CR9G-07, CR9G-08a) |
| src/Validation/obcfgavHttpTransport.Interface.al | Clean | |
| src/Validation/obcfgavHttpTransportImpl.Codeunit.al | Clean | |
| src/Validation/obcfgavLogEntries.Page.al | Clean | |
| src/Validation/obcfgavValidationLog.Table.al | Clean | |
| src/Validation/obcfgavValidationWriter.Codeunit.al | Clean | |
| Tests/src/obcfgavFakeHttpTransport.Codeunit.al | Clean | |
| Tests/src/obcfgavFakeAddressProvider.Codeunit.al | Clean | fixed in 0.0.0.7 (CR9G-02: helpers now used) |
| Tests/src/obcfgavTestLibrary.Codeunit.al | Clean | fixed in 0.0.0.7 (CR9G-02: helpers now used); dead-code scan re-run by the Reasoning role |
| Tests/src/obcfgavValidationTests.Codeunit.al | Clean | defect CR9G-01 is not dead code |
| Tests/src/obcfgavProviderTests.Codeunit.al | Clean | stale comment (CR9G-06) |
| Tests/src/obcfgavAddrValidatedTests.Codeunit.al | Clean | |

## 3. Fix batch presented for approval
| Findings | Approved by | Date | Recompiled / repackaged / retested |
|---|---|---|---|
| **3a, code, no rule change. Main app → 0.0.0.7:** CR9G-07, CR9G-08 (a, b), CR9G-09, CR9G-10, CR9G-13. **Test app → 0.0.0.7, dependency 0.0.0.7:** CR9G-01, CR9G-02 (6 tests), CR9G-03, CR9G-05, CR9G-06 (comment only; literal drift left, see 3c), Lib `NotValidatedText` trim. All verified fixed in the post-fix pass. | AJ Ansari | 2026-10-16 | Compiled 0/0 with analyzers; packaged `outputAppPackage/Google_Address_Validator_0.0.0.7.app` and `Google_Address_Validator_Tests_0.0.0.7.app`; sandbox install and AL Test Tool run (61 tests) **pending** (GA-23) |
| **3b, design-rule changes:** D-1 = CR9G-12 option (a), caller check as first statements of 60113 `ValidateCustomerAddress` / `TryValidateCustomerAddress`; D-2 = CR9G-11, new label `TestConnectionFailedNoMessageErr`. Verified fixed. TDD §13.1.4, TDD 2.11 and Documentation §3.2/§3.3 updated at Step 10/11 (CR9G-23). | AJ Ansari | 2026-10-16 | Same builds as 3a; retest **pending** |
| **3c, post-fix findings:** CR9G-19, CR9G-20, CR9G-06 residual (Minors) | AJ Ansari accepted all three by name | 2026-10-16 | No rebuild; Notes CR9G-21 to CR9G-24 carried |

## 4. Pattern candidates
| Pattern | Where it recurred | Flagged to |
|---|---|---|
| P6 "A test seam injected into a **global** codeunit variable of a test codeunit leaks into every later test method; `Clear` it in `Prepare`" | 60125 `Validator.SetProvider`; latent in 60126 and 60127 `Validator.SetTransport` | AJ Ansari |
| P7 "A message label whose last placeholder can be blank leaves a trailing space or a dangling label; use two labels or trim, and keep the test-library copy the same" | 60119:224, :38/:46, :144/:156 (CR9G-19), mirrored in the test library | AJ Ansari |
| P1–P5 from the USPS review | Still not flagged to the library (Roadmap R-09-2) | AJ Ansari |

## 5. Conflicts surfaced
| Conflict | Sources | Decision | Decided by |
|---|---|---|---|
| Telemetry: AL Guidelines Error Handling Rule 4 now says "add custom telemetry only when the user explicitly requests it", agreeing with TDD §7 (none) | AL Guidelines vs TDD §7 / CR9-23 | No telemetry; CR9-23 can be closed | *(awaiting: AJ Ansari)* |
| "Use TryFunctions … where rollback is required" vs the `Codeunit.Run` write phase | AL Guidelines Error Handling Rule 1 vs TDD §13.1, BCQuality `log-writes-must-survive-rollback` | The code is right: a TryFunction does not roll back | Reasoning role |
| Indentation: two spaces vs four | AL Guidelines Code Style vs Standards §1.6 | Standards wins | Standards precedence |
| Test project should use Library Assert / standard libraries vs the test app's own `AssertEqual*` helpers | AL Guidelines Testing Rules 3–4 vs TDD §4.19 as built | Recorded design stands | *(awaiting: AJ Ansari)* |
| API key vs OAuth2 for the external call | BCQuality `prefer-oauth2-over-api-keys` vs FRD §10 / TDD 2.5 | Design stands (signed off 2026-10-16); key is SecretText in isolated storage, never in a table; rotation manual | AJ Ansari (CR-1 sign-off) |
| `case` dispatch on the provider enum vs interface on the enum | BCQuality `prefer-interface-over-case-branching` vs TDD 2.2 | TDD stands (blank value 0, Standards §1.9) | AJ Ansari (TDD 2.2 sign-off) |
| Random/complete test data vs fixed fixtures | BCQuality `test-data-must-be-random-and-complete` vs test app | Deterministic data acceptable against a fake | Reasoning role (proposed) |
| "One `using` directive per file" (literal) vs files needing several namespaces | Standards §1.1 | Code right; Standards wording to clarify (CR9-12, carried) | *(awaiting: AJ Ansari)* |
| Build output gitignored vs packages tracked | BCQuality vs runbook | OCPF rule wins | Runbook |

## Before calling this done
- [x] Every dimension in §0 is graded with evidence after the fixes landed, and Overall is the lowest of the eight: **C** (Test coverage; Major CR9G-01 fixed in this step). No F.
- [x] Every Critical and Major finding is resolved or accepted by name. CR9G-01 is fixed (60125:717, 60126:660, 60127:214), verified by reading; the test run is still owed.
- [x] Every code fix went through compile and package at 0.0.0.7 (0/0). Install and the 61-test AL Test Tool run **waived by AJ Ansari by name, 2026-10-16** (ChangeLog 09-WAIVER-2); carried before Step 12 (GA-23, R-09-1).
- [x] §2 shows every file clean (dead-code scan of both apps re-run by the Reasoning role).
- [x] Post-fix Minors CR9G-19, CR9G-20 and the CR9G-06 residual accepted by AJ Ansari by name (2026-10-16).
- [x] Both repositories committed once this step closes (see ChangeLog 09-3).
- [ ] Carried to Step 10: TDD 2.5 (CR9G-07), TDD 2.11 row (D-2), TDD §13.1.4 and PostDevTDD Part B-2 list (D-1, CR9G-23); Documentation §3.2/§3.3 at Step 11.
- [x] Pattern candidates P6, P7 (with P1–P5) flagged to AJ Ansari.

---

## SC-1 Code Review (1.1.0.5)
**Date:** 2026-10-18 · **Reviewer:** Reasoning role, Opus 5.5 (both passes; report first lines checked against §1.7) · **Fixes applied by:** Main role (Sonnet 5.5), by AJ Ansari's standing instruction to finish without questions. **Reviewed:** all 60 main-app files and 8 test-app files at 1.1.0.3; BCQuality snapshot 86d809b read leaf article by leaf article (its PowerShell indexer was not run: downloaded code); AL Guidelines reading of 2026-10-16 still applies. 1.1.0.4 and 1.1.0.5 were re-read after the fixes (post-fix pass). Neither app has been installed or run (SC-1g).

### 0. Scorecard (code as it ships: main 1.1.0.5, tests 0.0.0.15)
| Dimension | Grade | Evidence |
|---|---|---|
| Standards compliance | **A** | No hit on the Part 7 table; Caption/ToolTip/ApplicationArea on every new control; file names per §1.8; no `#pragma`; analyzers on, 0 errors / 0 warnings. |
| Correctness and robustness | **B** | Commit before every `Codeunit.Run` with a return value; before-image handled per table; Privacy Blocked refused before anything is sent; linked update after the commit with the failure swallowed; the country compare is now in the 17 reset procedures and the four propagation compares. Notes N-3 and N-6 remain. |
| Readability and maintainability | **B** | Dead code removed (`SetCompanyName`, `GetTableCaption`), unused usings removed, `///` on the new public procedures; CR-1.1-11 (address compare written four ways, `IsParentBlocked` via field 1) accepted as Minor. |
| Performance | **A** | `SetLoadFields` on every read-only open; subscribers do in-memory compares before any database call; `ReadableSourceFilter` opens 16 RecordRefs once per page open and reads no data. |
| Security and permissions | **C** | CR-1.1-01 (Major) fixed in this step: USE has indirect read on the log and page 60110 shows only rows whose source table the user may read; field 26 inherits CustomerContent (CR-1.1-02). Access is Internal on all new codeunits; the caller check is the first statement; RecordRef runs behind an allow-list. |
| Upgrade safety | **A** | Schema additive only (Schema Sync Mode Add from 1.0.0.0); 60137/60138 tag-guarded and idempotent; install sets the tags. |
| Translation readiness | **A** | Every placeholder label has a Comment; no hard-coded text; US wording only. |
| Test coverage | **B** | 131 tests; all 16 sources covered for Accept and edit-resets across six address fields; privacy, record-gone, linked-sync, country (both settings of Require Country/Region Code). None has been run. |
| **Overall (the lowest)** | **C** | Security and permissions, from the Major fixed in this step. No Critical, no F. |

### 1. Findings
Severity Critical / Major / Minor / Note. First pass 23 findings (0 Critical, 1 Major, 10 Minor, 12 Notes); post-fix pass 2 new Minors and 7 Notes.
| # | Dimension | Finding | Severity | Resolution |
|---|---|---|---|---|
| CR-1.1-01 | Security | The log copies the address of every source (Employee, Alternative Address, Resource, Contact persons, Bank Accounts) into rows any USE user could read | Major [Design] | **Fixed (option a, the reviewer's recommendation):** USE `tabledata ... = ri`; page 60110 `Permissions = ... r` and `OnOpenPage` filter (FilterGroup 2) from `AddressSource.ReadableSourceFilter()`. Not covered by an automated test; sandbox check with a USE-only user required (also Open in Excel and analysis mode) |
| CR-1.1-02 | Security | Field 26 "Source SystemId" classified SystemMetadata although it keys a person's record | Minor [Design] | Fixed: inherits CustomerContent |
| CR-1.1-03 | Security | Source Description is a key, not a name, but keys can identify people | Note | UserGuide sentence (Step 11) |
| CR-1.1-04 | Correctness | A country change that Business Central does not clear left the indicator at Yes | Minor [Design] | **Fixed (option a):** country compare in the 17 reset procedures and a `Ship-to Country/Region Code` trigger on Company Information. Supersedes the 1.0 decision OQ-14 ("the country does not count") for all sources, by this review's decision |
| N-1 | Correctness | The four propagation compares (60139 ×3, 60138) still ignored the country | Minor | Fixed in 1.1.0.5 |
| CR-1.1-05 / N-2 | Tests | `TestCountryClearResetsFlag` depended on the GL setting and proved nothing about the new compare | Minor | Fixed: GL setting saved/set/restored; `TestCountryChangeResetsFlag` (setting on); `RunEditResets` covers index 6 |
| CR-1.1-06 | Readability | `Lib.SetCompanyName` unused; `CanModifyCustomers` unused | Minor | `SetCompanyName` deleted; `CanModifyCustomers` kept (public 1.0.0.0 API) and marked |
| CR-1.1-07 | Readability | `GetTableCaption` redundant (RecordRef is already open) | Minor | Deleted |
| CR-1.1-08 | Readability | Five unused `using` in the tests | Minor | Removed |
| CR-1.1-11 | Readability | Address compare written four ways; parent found via field 1; three WritePermission checks | Minor | Accepted, not fixed |
| CR-1.1-14/15/16/19 | Tests | Privacy only for Ship-to; no record-gone test; description key not asserted; wrong message label | Minor | Fixed |
| CR-1.1-22(1) | Docs | New public procedures without `///` | Note | Fixed |
| CR-1.1-09/10/12/13/17/18/20/21/22(2)(3)/23, N-3..N-9 | various | Cache of the field map; lock in read-only path (safe: row is rewritten); quoting drift in generated extensions; constants; upgrade code not unit-testable; clean-up weak spots after an aborted run; N+1 in upgrade; stored text not re-translated; TDD gate wording; subscriber split; `''`→US resets the indicator; two copies of the table list; ADMIN's direct R bypasses the page filter; unverified Excel/analysis mode | Note | Carried (Step 10/11 documents or accepted) |

### 2. Dead-code and obsolete-reference scan
Both apps, 68 files: no empty triggers, no commented-out code, no `// TODO`, no `#pragma`; only `CanModifyCustomers` (public API) was unreferenced and is kept. Obsolete references: none (0/0 compile with analyzers). New subscriptions (Contact ×4, CustVendBank-Update, Employee/Resource Update ×2, Upgrade Tag) are not obsolete in Base Application 28.5.

### 3. Fix batch
Approved under AJ Ansari's standing instruction (ChangeLog SC-1h): main 1.1.0.4 (CR-1.1-01, -02, -04, -07, -22) and 1.1.0.5 (N-1); test app 0.0.0.14 and 0.0.0.15. Package built: `outputAppPackage/Google_Address_Validator_1.1.0.5.app` (previous build 1.1.0.4). Schema: additive only → upload with Schema Sync Mode = Add. Install: you upload it — `docs/4-prove/SandboxInstall.md`, §1 updated. Then: tell me the version and environment you installed.

### 4. Pattern candidates
P8 "an extension field that must follow Business Central's own Customer/Vendor/Bank Account ↔ Contact sync needs the same field number and type on every table extension"; P9 "a log that copies data from several source tables widens read access: give users indirect read and filter the log page to the source tables the user can read"; P10 "find a parent record by its typed key, never by `RecordRef.Field(1)`" — flagged to AJ Ansari for the patterns library.

### Before calling this done
- [x] Critical: none. Major fixed. Dead-code scan clean.
- [x] Fixes recompiled (1.1.0.5 / 0.0.0.15, 0 errors / 0 warnings) and repackaged with the "Package built" block. **Retest is owed**: nothing has been installed (SC-1g waiver).
- [x] §0 graded by the Reasoning role after the fixes; overall C, no F.
