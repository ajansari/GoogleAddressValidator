# As-Built Technical Design Document — USPS Address Validator

**Version:** as-built 1.0 for main app **0.0.0.4** and test app **0.0.0.3** · **Date:** 2026-10-16 · **Author:** Main role (Sonnet 5.5) at Step 10, for AJ Ansari · **Review:** Dev Manager — AJ Ansari, once at the Step 11 → 12 hand-off
**Built from:** the signed-off TDD 1.0 (`docs/2-design/TDD.md` §§1–13, kept unchanged as the historical record), `docs/0-project/ChangeLog.md` through Issue 09-WAIVER, `docs/4-prove/GapAnalysis.md` (every *Spec stale* item applied here), `docs/4-prove/CodeReview.md`, and the code in `src/` and `/Users/ajansari/Documents/AL/USPSAddressValidator.Tests/src`.
**What is not in here:** the CR-1 provider change (`docs/2-design/TDD.md` §14, `docs/2-design/FRD.md` §10) is an unsigned draft and is **not built**. Where this document says "USPS", that is the code as it exists.

## How to read this document
1. **Part A** is the deviation summary: every difference between the signed-off TDD and the code, with its ChangeLog reference.
2. **Part B** is the as-built delta, object by object. **Where Part B and Part C differ, Part B wins.** It is normative for regenerating the system.
3. **Part C** is the original specification (TDD 1.0 §§1–12), unchanged text, so that every unchanged object keeps its full specification in one place. Its pointer lines to §13 now point to Part D.
4. **Part D** is the Sanity Check amendments (TDD 1.0 §13), unchanged text; Part B overrides them where marked.
Reading order for a developer starting from nothing: A, B, then C for the object being built, then D.

# Part A — Deviation summary
| Ref | What differs from TDD 1.0 | Why | ChangeLog |
|---|---|---|---|
| A1 | New codeunit 60118 "obcfusps Validation Writer" (write phase, log insert), 25 IDs allocated + 1 interface (not 24) | F1: failed write must still be logged | 04-1, B4-1 |
| A2 | Writer exposes `WasAddressChanged()` and `InsertLogEntry(...)`; Setup `MarkSetupCompleteIfReady`; internal `DeleteToken` | Generation detail | B1-1, B4-1 |
| A3 | Credentials: `SetEncrypted` when `EncryptionEnabled()`, no length test, no fallback | `SecretText.Unwrap()` is OnPrem-only | B1-1 |
| A4 | Caller check compares Guid to Guid via `Evaluate(TestAppId, TestAppIdTok)` | `Format(Guid)` has braces and upper case | B1-1, B2-1 |
| A5 | `ValidateAddress` persists the buffer row (`SaveBuffer`); orchestrator never inserts it | Who owns the row was unspecified | B2-1, B4-1 |
| A6 | Orchestrator has no `Permissions` property; all log inserts run inside 60118 (`tabledata log = i`) | Least privilege | B4-1 |
| A7 | `TryValidateCustomerAddress` returns true for Not Found and for the address-changed case | Result contract | B4-1 |
| A8 | Test app: `AssertEqualText/Int/Bool`, shortened test names, `InitSetup` refuses to run outside a company whose name contains TEST, credentials are not restored | AL has no overloads; credentials are per-app | B6-1 |
| A9 | Source folder is `src/Setup/` (not `src/Foundation/`) | Named at Step 05 | 05-1 (Gap G10) |
| A10 | Worst case is three HTTPS calls, not two | Single token refresh (FR-7) | Gap G7 |
| A11 | A write-failure Error log row keeps the five USPS values | Better audit trail | Gap G6 |
| A12 | USPS error text reaches the user only for HTTP 400 and 404 | Matches the FR-7 table | Gap G8 |
| A13 | Step 09 changes B-1 to B-13 below (caller check, privacy notice, Contact sync, rename propagation, ZIP precondition, log sort and `OnInsert`, null-safe `expires_in`, writer decoupling, etc.) | Code review | 09-1, 09-2 |
| A14 | Known open gaps carried: G2 (60118 Public), G3 (blank USPS fields accepted), G4 (60114 Public), G5, G15–G17 | Scheduled with CR-1 / sandbox | 08-1, Roadmap R-08-1..6 |
| A15 | Builds: main 0.0.0.4, test app 0.0.0.3; both 0 errors / 0 warnings; **never installed in a tenant**, so no automated or manual test has run | Gates waived by AJ | 07-WAIVER, 09-WAIVER |

# Part B — As-built delta (normative)
## B-1 System identity and versions
Main app `app.json` version **0.0.0.4**; test app **0.0.0.3**, dependency on main app `0.0.0.4`. Everything else in Part C §1 stands, except the test-app `version` and dependency listed there are the first-build values. Files live in `src/Setup/` and `src/Validation/`.

## B-2 Caller check (replaces TDD §13.2 and the check text in §4.11–§4.13)
- Codeunit 60098 owns the one check: `internal procedure CheckCallerAllowed(CallerModuleInfo: ModuleInfo)`. It reads `NavApp.GetCurrentModuleInfo`; allows the call when `CallerModuleInfo.Id` equals this app's id; allows the test app (`Evaluate(TestAppId, TestAppIdTok)`, GUID `ebe1c8ca-a413-4f2b-9de7-37d8c1ae4d5a`) **only when `Codeunit "Environment Information".IsSandbox()` is true** (`using System.Environment;`); otherwise `Error(CallerNotAllowedErr)`.
- **The caller must be read by the public procedure itself, as its first statement**: `NavApp.GetCallerModuleInfo(CallerModuleInfo);` then the check. Done in 60098 `SetConsumerKey`, `SetConsumerSecret`, `ClearToken`; 60113 `SetTransport`; 60114 `SetTransport` (60113 and 60114 call `CredentialMgt.CheckCallerAllowed`). Reading it inside a helper always names this app and silently defeats the check (Code Review CR9-01; pattern candidate P1).
- `TestAppIdTok` and `CallerNotAllowedErr` exist only in 60098. There are no local `CheckCaller` procedures.

## B-3 Privacy notice (new; Code Review CR9-04, CR9-24)
- Id `OBCFUSPS-ADDRESS`, name `'USPS Address Validation'`, link `https://about.usps.com/who/legal/privacy-policy/` (unconfirmed, FRD OQ-23). Labels `PrivacyNoticeIdTok`, `PrivacyNoticeNameTxt` (`MaxLength = 250`), `PrivacyNoticeLinkTok` in codeunit 60100.
- Codeunit 60100: `procedure PrivacyNoticeId(): Code[50]` and `procedure EnsurePrivacyNotice()` (calls `Codeunit "Privacy Notice".CreatePrivacyNotice(Id, Name, Link)`, idempotent: returns false when it exists). `RegisterAll` calls it. (`using System.Privacy;`)
- Codeunit 60113 `ConfirmPrivacyNotice()`: `SetupRegistration.EnsurePrivacyNotice(); Commit(); exit(PrivacyNotice.ConfirmPrivacyNoticeApproval(SetupRegistration.PrivacyNoticeId()))`. Called in `TryValidateCustomerAddress` **after `CheckPreconditions` and before `FillOriginal` and the HTTP phase**. If false: `UserMessage := PrivacyNoticeNotApprovedErr`, return false, nothing sent, nothing logged.
- Page 60096 Test Connection action: `EnsurePrivacyNotice(); Commit();` then `ConfirmPrivacyNoticeApproval`; if false `Error(ShowTextTok, PrivacyNoticeNotApprovedErr)`.
- New labels: `PrivacyNoticeNotApprovedErr` in 60113 ('The privacy notice for sending addresses to USPS has not been agreed to, so nothing was sent.') and in page 60096 ('…, so the connection was not tested.').
- Permission set 60101 USE gains `codeunit "obcfusps Setup Registration" = X` (ADMIN already had it).

## B-4 Codeunit 60118 "obcfusps Validation Writer"
`Access = Public` (gap G2, scheduled to become Internal with CR-1), `Permissions = tabledata "obcfusps USPS Validation Log" = i`. `Init(NewCustomerNo; NewOutcome; var TempResult; NewAccepted; NewCanModify: Boolean)` — **`NewCanModify` is new**: the orchestrator passes `CanModifyCustomers()` once, and the Writer no longer references 60113. `SetAddressValidated` exits when `CanModify` is false. `WriteAcceptedSuggestion` calls **`Customer.SetForceUpdateContact(true)` before `Customer.Modify(true)`**, because on a code-driven modify `xRec` equals `Rec` and the linked Contact would otherwise not be updated (CR9-05; pattern candidate P2). `InsertLogEntry(...)` uses `Log.Insert(true)`.

## B-5 Codeunit 60113 "obcfusps Address Validation"
- `SetTransport` per B-2. `Customer.SetLoadFields("No.", "Country/Region Code", Address, "Address 2", City, County, "Post Code")` before the read-only `Customer.Get`.
- `CheckPreconditions` precondition 3: `(Customer.Address = '') or (not HasUsableZip(Customer."Post Code") and ((Customer.City = '') or (Customer.County = '')))`, where `HasUsableZip` is true when the trimmed Post Code has at least 5 characters and its first five are digits (the same rule `BuildAddressUrl` uses; CR9-08).
- `RunWriter` passes `CanModifyCustomers()` to `Writer.Init`. Duplicate caller-check code and labels removed (CR9-13).

## B-6 Codeunit 60114 "obcfusps USPS API Client"
`SetTransport` per B-2. `ParseTokenResponse` reads `expires_in` with the null-safe `GetText` helper: `if not Evaluate(ExpiresIn, GetText(JObject, ExpiresInTok)) then ExpiresIn := 0;` (0 means do not cache; CR9-07). Still `Access = Public` (G4). `ParseAddressResponse` still accepts blank required fields (G3).

## B-7 Validation Log table 60109 and Customer Card extension 60117
"Customer No." no longer has `ValidateTableRelation = false`, so a customer rename rewrites log rows as TDD §13.7 F14 decided (CR9-06; "User ID" keeps it; pattern candidate P3). New `trigger OnInsert() begin Rec.TestField("Customer No."); end;`. The page extension's `obcfuspsValidationLog` action has `RunPageView = sorting("Customer No.", "Checked At") order(descending);` (key `CustomerCheckedAt`) besides `RunPageLink` (Standards §11.1 parts 1 and 4; CR9-10). Page 60110 keeps its own `SourceTableView` newest-first.

## B-8 Wizard 60097
Variable block moved after the procedures (layout only, CR9-15).

## B-9 Test app (60123–60127), version 0.0.0.3
- `namespace OnlyBCFans.USPSAddress;` only; no redundant `using` of its own namespace (CR9-11). Library `InitSetup` additionally calls `ApprovePrivacyNotice()` (creates the notice if missing, saves the current approval state once, sets Agreed) and `CleanUp` restores the saved state; `DisagreePrivacyNotice()`, `PrivacyNotApprovedText()`, `CouldNotReadText(...)`, `UnexpectedResponseText()` added. The test app can run only in a SaaS sandbox (the caller check accepts its GUID only there).
- Test A2 (60125): `EditCustomerThenAcceptHandler` now calls `Commit()` after `Customer.Modify()` (CR9 T-01).
- Codeunit 60126 gains: `TestRequestUrlHasAddressOnly`, `TestTokenNoResponseLogged`, `TestBadRequestShowsUSPSText`, `TestServerErrorLogged`, `TestUnreadableAddressResponse`, `TestTokenWithoutAccessToken`, `TestPostCodeMustBeZipLike`, `TestConnectionSucceeds`, `TestConnectionFails`, `TestPrivacyRefusedSendsNothing` (modal handler `DisagreePrivacyHandler` on page "Privacy Notice", `Reject.Invoke`). Total automated tests: 34 (24 + 10). None has run (G15).
- TDD §4.19 as built: `AssertEqualText/Int/Bool`; `LastLogEntry(CustomerNo; var Log): Boolean`; no `[MessageHandler]`; Fake extras `SetFailCustomerModify`, `GetFailText` and the `OnBeforeModifyEvent` subscriber (Gap G12).

## B-10 Permission sets
60101 USE: as TDD §10 plus `codeunit "obcfusps Setup Registration" = X`. 60102 ADMIN: includes USE; also lists `codeunit "obcfusps Setup Registration" = X` (redundant, harmless).

## B-11 Object inventory (replaces the counts in TDD §2 and the Object Register footer)
25 allocated IDs (module A 60093–60102, module B 60109–60118 plus 60134 tail unused, test app 60123–60127) plus the interface `"obcfusps USPS Transport"`; 25 IDs unallocated (A 60103–60108, B 60119–60122, tail 60134–60142, C 60128–60133). Additional objects not named in the FRD (Gap G13, intentional): 60118 Writer, 60111 buffer, 60115 Http Transport, the transport interface, 60100 Setup Registration.

## B-12 Consolidated wording corrections (Gap G11)
§4.6 "written … by codeunit 60113 only" → the single insert is 60118 `InsertLogEntry`. §4.13 Properties: no `Permissions` on 60113; the log insert lives in 60118. §4.11: `MarkAssistedSetupCompleteIfReady` is `MarkSetupCompleteIfReady`; `ClearToken` (public, checked) wraps the internal `DeleteToken`; Storage row per Part D §13.3 as built. Users of the word "Foundation" for the folder mean `src/Setup/`.

## B-13 Known limitations and verification still owed
G2, G3, G4 (security/robustness hardening, scheduled with CR-1); G5 (HTTP phase may raise if "Allow HttpClient Requests" is off); G15–G17 (no sandbox run; live USPS contract unverified; Contact sync, US captions and HttpClient default unchecked); the privacy-policy link (OQ-23); the notice's platform consent text says data is shared with Microsoft services; the access token is stored with `IsolatedStorage.Set` (CR9-03, decision stands).

# Part C — Original specification (TDD 1.0 §§1–12, unchanged text)
Pointers in this text to "§13" mean Part D. Part B overrides it.

## 1. System identity
All from `docs/1-define/ProjectParameters.md` — copied, never retyped from memory.
| Item | Value |
|---|---|
| Publisher / Namespace / Prefix | OnlyBCFans / `OnlyBCFans.USPSAddress` (flat; every file of **both** apps declares `namespace OnlyBCFans.USPSAddress;`) / `obcfusps` |
| APIPublisher / APIGroup prefix / APIVersion | N/A — no API pages or API queries (Parameters §1.3) |
| AL runtime / BC minimum / Localization | 17.0 / 28.0.0.0 (platform and application) / US. Source wording is US English; no translation files (Parameters §1.9) |
| Object ID range(s) | 60093–60142, shared by the main app and the test app (§2). After this TDD, the main app's `app.json` `idRanges` becomes `[{60093–60122}, {60134–60142}]` and the test app's becomes `[{60123–60133}]`. The main role makes this change at Step 05, so that `al_getnextobjectid` can never hand the main app an ID that belongs to the test app |
| Permission Set App Code / names | `USPS` / `OBCFUSPS USPS, USE` and `OBCFUSPS USPS, ADMIN` (ADMIN includes USE; no VIEW set — AJ Ansari, 2026-10-10, FRD OQ-11) |
| Features | `NoImplicitWith`, `TranslationFile` (both apps) |
| Test app `app.json` | `"id"`: a new GUID, generated at Step 05 · `"name"`: `"USPS Address Validator Tests"` · `"publisher"`: `"OnlyBCFans"` · `"version"`: `"0.0.0.1"` · `"platform"`/`"application"`: `"28.0.0.0"` · `"runtime"`: `"17.0"` · `"target"`: `"Cloud"` · `"features"`: `["NoImplicitWith","TranslationFile"]` · `"idRanges"`: `[{"from":60123,"to":60133}]` · `"dependencies"`: `[{"id":"2d1d2fd8-0208-4096-a868-8489784df05a","name":"USPS Address Validator","publisher":"OnlyBCFans","version":"0.0.0.1"}]` (the version is raised whenever a test depends on a newer main-app build). No dependency on Microsoft test libraries (§11, note 9). The test app is never deployed to production (FRD §7). **Its folder: the sibling folder `/Users/ajansari/Documents/AL/USPSAddressValidator.Tests/` with its own git repository (AJ Ansari, 2026-10-10, Q2).** |

## 2. Module grouping and ID allocation
Standards §5.1–§5.2: each module gets a contiguous sub-block with a ≥ 20 % growth buffer, plus a tail block for cross-module additions. Object types have separate ID spaces, but IDs are still unique across types here so that the register reads cleanly. Field IDs in the table extension come from the same range (field 60093 on Customer).
| Module | ID sub-block | Allocated | Buffer | Objects |
|---|---|---|---|---|
| A — Setup and Foundation (main app) | 60093–60108 (16) | 60093–60102 (10) | 60103–60108 (6 = 38 %) | 2 enums, setup table, setup card, setup wizard, Credential Mgt., Install, Setup Registration, 2 permission sets |
| B — Validation and USPS API (main app) | 60109–60122 (14) | 60109–60118 (10; 60118 added by §13.1) | 60119–60122 (4 = 29 %; tail 60134–60142 is the overflow) | log table, log page, address buffer (temporary table), comparison dialog, Address Validation, API Client, Http Transport, Customer table extension, Customer Card page extension; interface `"obcfusps USPS Transport"` (interfaces take no ID) |
| C — Test app (separate extension) | 60123–60133 (11) | 60123–60127 (5) | 60128–60133 (6 = 55 %) | fake transport, test library, 3 test codeunits |
| Tail — cross-module additions (main app) | 60134–60142 (9) | — | 9 | reserved |
| **Total** | 60093–60142 (50) | 24 IDs | **26 IDs unallocated** (≥ 10 required, §5.2) | |

## 3. Batch / phase plan
Smallest and simplest batch first (Operating Rule 3). The two permission set objects belong to B1. Each later batch *contributes* the grant lines listed for it in §10, so that each table's `tabledata` grant ships in the batch that introduces the table (Standards §5.3). In parallel mode the generator of B2–B5 doesn't edit B1's files: it returns its grant lines, and the main role adds them to the two permission set files when it integrates that batch. Lint per batch; compile once at Step 07 (Operating Rule 4).
| Batch | Modules / objects | Depends on | Why this order |
|---|---|---|---|
| B1 Foundation | enum 60093, enum 60094, table 60095, codeunit 60098, permissionset 60101, permissionset 60102 (setup grants only) | — | No logic beyond storage; everything else references it |
| B2 USPS API | interface `"obcfusps USPS Transport"`, table 60111 (temporary buffer), codeunit 60115 Http Transport, codeunit 60114 API Client, page 60096 setup card (needs API Client for Test Connection) | B1 | The only USPS-specific code (FRD §5), isolated before anything uses it |
| B3 Log | table 60109, page 60110 | B1 | Simple, read-only; needed by B4 and B5 |
| B4 Validation | page 60112 comparison dialog, codeunit 60118 Validation Writer (§13.1), codeunit 60113 Address Validation, tableextension 60116, pageextension 60117 | B1–B3 | Orchestration last among the runtime pieces; it uses all of them |
| B5 Onboarding | page 60097 wizard, codeunit 60100 Setup Registration, codeunit 60099 Install | B1, B3 | Registers the log (B3) with Retention Policy and the wizard in Assisted Setup |
| B6 Test app | codeunits 60123–60127, test app `app.json` | B1–B5 | Exercises the finished app through the transport interface |

## 4. Per-object specification
Rows that apply to every object below, stated once:
- **API properties:** PageType API, APIPublisher, APIGroup, APIVersion, EntityName, EntitySetName and ODataKeyFields are N/A on every object, because none is an API page.
- **SourceTableView:** none uses const() filters on enums.
- **Parent links (Standards §11.1):** N/A everywhere — no table has a parent-link field.
- **Number series (Standards §11.2):** N/A everywhere — nothing is numbered from a number series.
- **Caption locking (§8.6):** N/A — no API objects.
- **Field properties:** every page field has `Caption`, `ToolTip` and `ApplicationArea = All` (Standards §1.4).
- **Naming and layout:** file names follow Standards §1.8 (object name without spaces or punctuation, then `.<Type>.al`; for example `obcfuspsUSPSSetup.Table.al`). Folders: `src/Foundation/` (module A) and `src/Validation/` (module B).

### 4.1 Enum 60093 "obcfusps Validation Result"
| Property | Value |
|---|---|
| Source table (name / verified number) | N/A (enum) |
| PageType / APIPublisher / APIGroup / APIVersion | N/A |
| EntityName / EntitySetName | N/A |
| ODataKeyFields | N/A |
| `DelayedInsert` / read-only lines | N/A |
| SourceTableView | N/A |
| `using` namespaces | none |
| Deletion behaviour | N/A |
| Caption-locking group | N/A — not an API object |
| Parent link | N/A — no parent-link field |
| Number series | N/A — not numbered |
| Enums | `Caption = 'USPS Validation Result'`. Values: `0 " "` (Caption `' '`), `1 Confirmed` ('Confirmed'), `2 "Suggestion Accepted"` ('Suggestion Accepted'), `3 "Suggestion Ignored"` ('Suggestion Ignored'), `4 "Not Found"` ('Not Found'), `5 Error` ('Error'). **`Extensible = false;`** written explicitly. Decided by AJ Ansari, 2026-10-10, because it is a closed, code-driven set: each value is written by exactly one outcome of the validation routine. The blank value 0 exists because the enum is a table field (Standards §1.9); code never writes 0. Captions contain no commas. |
#### Fields
N/A — enum.

### 4.2 Enum 60094 "obcfusps USPS Environment"
| Property | Value |
|---|---|
| Source table | N/A (enum) |
| API rows, SourceTableView, deletion, caption locking, parent link, number series | N/A, as in §4.1 |
| `using` namespaces | none |
| Enums | `Caption = 'USPS Environment'`. Values: `0 " "` (Caption `' '`), `1 Production` ('Production'), `2 Test` (Caption **'Test (TEM)'**). **`Extensible = false;`**. Decided by AJ Ansari, 2026-10-10: each value maps to one fixed USPS base URL (§4.12). Value 0 is blank because the enum is a table field; the setup table's `InitValue` makes the default Test. Code treats blank as "not set up". Value names are plain identifiers; the parenthesised text is in the caption only. |
#### Fields
N/A — enum.

### 4.3 Table 60095 "obcfusps USPS Setup"
| Property | Value |
|---|---|
| Source table | New table. `Caption = 'USPS Address Validation Setup'`; `DataClassification = CustomerContent;` (table level); `DataPerCompany` default (true) |
| API rows | N/A |
| `using` namespaces | `Microsoft.Foundation.Address` (table 9 "Country/Region", verified) |
| Deletion behaviour | Allow. Singleton per company; nothing references it. The setup page sets `DeleteAllowed = false`. Decided by Reasoning role (draft) — AJ Ansari to confirm at sign-off |
| Caption locking / parent link / number series | N/A |
| Enums | Uses enum 60094 (§4.2) |
| Keys | `key(PK; "Primary Key") { Clustered = true; }` |
| Triggers | None (Standards §1.5). The setup page owns the singleton insert. |
| Procedures | None |
#### Fields
| Source field | Identifier (camelCase, ≤ 30) | Conversion decision | Included / excluded — reason | FlowField or stored | Data type |
|---|---|---|---|---|---|
| 1 "Primary Key" | primaryKey | none | Included — singleton key; never shown on a page | stored | Code[10] |
| 2 Enabled | enabled | none | Included — FR-6 | stored, `InitValue = false` | Boolean |
| 3 Environment | environment | none | Included — FR-6 | stored, `InitValue = Test`. `OnValidate`: `if Rec.Environment <> xRec.Environment then CredentialMgt.ClearToken();` (FR-6) | `enum "obcfusps USPS Environment"` |
| 4 "US Country/Region Code" | usCountryRegionCode | "/" removed, per §4.1 | Included — FR-6 | stored, `InitValue = 'US'`, `TableRelation = "Country/Region"` | Code[10] (matches Customer "Country/Region Code", Code[10], verified) |
| 5 "Timeout (Seconds)" | timeoutSeconds | parentheses removed | Included — FR-6 | stored, `InitValue = 10`, `MinValue = 1`, `MaxValue = 60` (AJ Ansari, 2026-10-10, Q6) | Integer |
Credentials and the token are **not** fields (FR-6). They live in IsolatedStorage, company scope (§4.11).

### 4.4 Page 60096 "obcfusps USPS Setup" (setup card)
| Property | Value |
|---|---|
| Source table | `"obcfusps USPS Setup"` (60095) |
| PageType | `Card`; `Caption = 'USPS Address Validation Setup'`; `UsageCategory = Administration`; `ApplicationArea = All`; `InsertAllowed = false`; `DeleteAllowed = false` (editable singleton) |
| `using` namespaces | none beyond the flat namespace |
| Triggers | `OnOpenPage`: `Rec.Reset(); if not Rec.Get() then begin Rec.Init(); Rec.Insert(); end; RefreshCredentialState();` (singleton table pattern, §6). `OnAfterGetRecord`: `RefreshCredentialState();` |
| Variables | `[NonDebuggable] ConsumerKeyText: Text;` `[NonDebuggable] ConsumerSecretText: Text;` `CredentialMgt: Codeunit "obcfusps USPS Credential Mgt.";` `TestEnvironmentNote: Text;`. `[NonDebuggable]` on page variables is the pattern verified in System App page "Password Dialog" (`PasswordValue`). |
| Layout | `group(General)` (Caption 'General'): `field(enabled; Rec.Enabled)`, `field(environment; Rec.Environment)`, `field(testEnvironmentNote; TestEnvironmentNote)` (Editable = false, ShowCaption = false, MultiLine = true, Style = Attention; holds `TestEnvironmentNoteTxt`, FR-6), `field(usCountryRegionCode; Rec."US Country/Region Code")`, `field(timeoutSeconds; Rec."Timeout (Seconds)")`. `group(Credentials)` (Caption 'USPS Credentials'): `field(consumerKey; ConsumerKeyText)` (Caption 'Consumer Key', `ExtendedDatatype = Masked`), `field(consumerSecret; ConsumerSecretText)` (Caption 'Consumer Secret', `ExtendedDatatype = Masked`). |
| Field validation | `consumerKey`: `OnValidate` calls `[NonDebuggable] local procedure SaveConsumerKey()`: `if ConsumerKeyText <> MaskedPlaceholderTok then begin CredentialMgt.SetConsumerKey(ConsumerKeyText); end; RefreshCredentialState();` (Text converts implicitly to SecretText). `consumerSecret` does the same through `CredentialMgt.SetConsumerSecret`. An empty value deletes the stored credential. |
| Credential display | `RefreshCredentialState()`: `if CredentialMgt.HasConsumerKey() then ConsumerKeyText := MaskedPlaceholderTok else ConsumerKeyText := '';` and the same for the secret. The stored values are never read back into the page: SecretText can't be unwrapped in the cloud (Learn: Unwrap is on-premises only). So the key is shown masked and the secret is write-only (FR-6). |
| Actions | `area(Processing)`: `action(TestConnection)` (Caption 'Test Connection', Image = TestDatabase, ToolTip 'Request a token from USPS with the saved credentials. No address is checked, so no address quota is used.'). `OnAction`: `if ApiClient.TestConnection(ErrorText) then Message(ConnectionOkMsg) else Error(ErrorText);`. `action(AssistedSetup)` (Caption 'Assisted Setup', Image = Setup, RunObject = page "obcfusps USPS Setup Wizard"). `area(Promoted)`: `group(Category_Process) { actionref(TestConnection_Promoted; TestConnection) }` |
| Deletion / enums / caption locking / parent / number series | Covered on the table; N/A |
#### Fields
As on the table (§4.3) plus two page variables (consumerKey, consumerSecret) and one note variable (testEnvironmentNote). All Text; none is stored on the page.

### 4.5 Page 60097 "obcfusps USPS Setup Wizard"
| Property | Value |
|---|---|
| Source table | none (page variables only) |
| PageType | `NavigatePage`; `Caption = 'Set Up USPS Address Validation'`; `ApplicationArea = All`; no UsageCategory (it is reached from Assisted Setup and from the setup card action) |
| `using` namespaces | `System.Environment.Configuration` (codeunit 1990 "Guided Experience", verified; Access Public) |
| Variables | `Step: Integer` (0 Welcome, 1 Credentials, 2 Finish); `[NonDebuggable] ConsumerKeyText: Text;` `[NonDebuggable] ConsumerSecretText: Text;` `BackEnabled, NextEnabled, FinishEnabled: Boolean` |
| Layout | `group(WelcomeStep)` (Visible = Step = 0): instructional fields showing `WizardWelcomeTxt` and `WizardScopeTxt`. `group(CredentialsStep)` (Visible = Step = 1): `field(consumerKey; ConsumerKeyText)` (Masked) and `field(consumerSecret; ConsumerSecretText)` (Masked), each with `OnValidate`: `UpdateControls();`. `group(FinishStep)` (Visible = Step = 2): `WizardFinishTxt`. |
| Actions | `ActionBack` (Caption 'Back', InFooterBar = true, Enabled = BackEnabled, Image = PreviousRecord): `Step -= 1; UpdateControls();`. `ActionNext` (Caption 'Next', InFooterBar = true, Enabled = NextEnabled, Image = NextRecord): `Step += 1; UpdateControls();`. `ActionFinish` (Caption 'Finish', InFooterBar = true, Enabled = FinishEnabled, Image = Approve): `FinishWizard(); CurrPage.Close();`. These are the NavigatePage footer actions, verified as the pattern in 40+ Microsoft NavigatePage wizards. |
| Procedures | `local procedure UpdateControls()`: `BackEnabled := Step > 0; NextEnabled := (Step = 0) or ((Step = 1) and (ConsumerKeyText <> '') and (ConsumerSecretText <> '')); FinishEnabled := Step = 2;`. `[NonDebuggable] local procedure FinishWizard()`: `CredentialMgt.SetConsumerKey(ConsumerKeyText); CredentialMgt.SetConsumerSecret(ConsumerSecretText);` (each also clears the cached token and marks the assisted setup complete, §4.11). The wizard never touches Environment, Enabled, US Country/Region Code or Timeout, and never calls USPS (FR-6). Closing without Finish saves nothing. |
| Triggers | `OnOpenPage`: `Step := 0; UpdateControls();` |
| Other N/A rows | as §4.1 |
#### Fields
Page variables only (consumerKey, consumerSecret: Text, masked).

### 4.6 Table 60109 "obcfusps USPS Validation Log"
| Property | Value |
|---|---|
| Source table | New table. `Caption = 'USPS Validation Log'`; `DataClassification = CustomerContent;` (table level); `LookupPageId` and `DrillDownPageId` = page "obcfusps USPS Log Entries" |
| `using` namespaces | `Microsoft.Sales.Customer` (table 18 Customer, verified); `System.Security.AccessControl` (table 2000000120 User, field 2 "User Name" Code[50], verified) |
| Deletion behaviour | **Allow, no cascade, no block.** Deleting a Customer leaves its log entries (FR-5). The extension subscribes to nothing on Customer delete, so a Customer that has log entries can still be deleted, and the log keeps the orphaned Customer No. as audit data. Decided by AJ Ansari ("no cascade delete", FRD FR-5); allow-instead-of-block is the Reasoning role's reading, because the FRD lets customers be deleted. Log entries are deleted only through ADMIN's `D` permission (§10) or Retention Policy |
| Keys | `key(PK; "Entry No.") { Clustered = true; }` and `key(CustomerCheckedAt; "Customer No.", "Checked At")` |
| Triggers | None |
| Enums | Uses 60093 and 60094 |
| Other N/A rows | as §4.1 |
#### Fields
All are stored; none is a FlowField. All are CustomerContent except where noted. All are written once, at insert, by codeunit 60113 only.
| Source field | Identifier | Conversion decision | Included — reason | FlowField or stored | Data type |
|---|---|---|---|---|---|
| 1 "Entry No." | entryNo | "No." becomes `No` (§4.2) | FR-5 | stored, `AutoIncrement = true` | Integer |
| 2 "Customer No." | customerNo | — | FR-5 | stored; `TableRelation = Customer."No."`, `ValidateTableRelation = false` (deleted customers stay readable) | Code[20] (= Customer "No.", verified) |
| 3 "Checked At" | checkedAt | — | FR-5; also the Retention Policy date field | stored. DateTime is shown in each user's time zone (FRD §4.1 l, manual test 11) | DateTime |
| 4 "User ID" | userId | — | FR-5. **`DataClassification = EndUserIdentifiableInformation`** | stored; `TableRelation = User."User Name"`, `ValidateTableRelation = false` | Code[50] |
| 5 Result | result | — | FR-5 | stored | `enum "obcfusps Validation Result"` |
| 6 Accepted | accepted | — | FR-5 | stored | Boolean |
| 7 "Original Address" | originalAddress | — | FR-5 (value sent) | stored | Text[100] |
| 8 "Original Address 2" | originalAddress2 | — | FR-5 | stored | Text[50] |
| 9 "Original City" | originalCity | — | FR-5 | stored | Text[30] |
| 10 "Original State" | originalState | US wording ("State" holds Customer County, FRD OQ-4) | FR-5 | stored | Text[30] |
| 11 "Original ZIP Code" | originalZipCode | — | FR-5 | stored | Code[20] |
| 12 "USPS Address" | uspsAddress | — | FR-5; blank for Not Found and Error | stored | Text[250] (longer than the customer field, so the log stores what USPS returned even when Accept is blocked; `CopyStr` to 250 as a last guard) |
| 13 "USPS Address 2" | uspsAddress2 | — | FR-5 | stored | Text[250] |
| 14 "USPS City" | uspsCity | — | FR-5 | stored | Text[250] |
| 15 "USPS State" | uspsState | — | FR-5 | stored | Text[250] |
| 16 "USPS ZIP Code" | uspsZipCode | formatted `12345-6789` or `12345` | FR-5 | stored | Text[250] |
| 17 "DPV Confirmation" | dpvConfirmation | Caption 'Delivery Point Confirmation' | FR-5. Kept as **Code[10], not an enum**, on purpose: it is USPS's code value, stored exactly as returned (FRD §5), and an unknown future code must be stored, not rejected. It is not a value set this extension owns (Standards §1.9 applies to fixed sets the design owns) | stored | Code[10] |
| 18 "Match Codes" | matchCodes | comma-separated `matches[].code` | FR-5 | stored | Text[100] |
| 19 "Correction Codes" | correctionCodes | comma-separated `corrections[].code` | FR-5 | stored | Text[100] |
| 20 "USPS Message" | uspsMessage | match, correction or error text | FR-5 | stored | Text[2048] |
| 21 "HTTP Status" | httpStatus | 0 = no response | FR-5 | stored | Integer |
| 22 Environment | environment | — | FR-5 | stored | `enum "obcfusps USPS Environment"` |
Excluded on purpose: token, credentials, request URL (FR-5), and customer name (not requested).

### 4.7 Page 60110 "obcfusps USPS Log Entries"
| Property | Value |
|---|---|
| Source table | `"obcfusps USPS Validation Log"` (60109) |
| PageType | `List`; `Caption = 'USPS Validation Log'`; `UsageCategory = Lists`; `ApplicationArea = All`; **`Editable = false; InsertAllowed = false; ModifyAllowed = false;`**. `DeleteAllowed` stays at its default (true): only ADMIN holds `D` on the table (§10), so a USE user who tries to delete gets the platform's permission error (FR-5: "Only administrators can delete entries") |
| SourceTableView | `sorting("Entry No.") order(descending)` — newest first (FR-5) |
| Layout | `repeater(Entries)`: every field of §4.6 in table order, each with its control identifier from §4.6. Captions: 'Entry No.', 'Customer No.', 'Checked At', 'User ID', 'Result', 'Accepted', 'Original Address', 'Original Address 2', 'Original City', 'Original State', 'Original ZIP Code', 'USPS Address', 'USPS Address 2', 'USPS City', 'USPS State', 'USPS ZIP Code', 'Delivery Point Confirmation', 'Match Codes', 'Correction Codes', 'USPS Message', 'HTTP Status', 'Environment'. ToolTips: 'Specifies the …' sentence per field (for example 'Specifies the address values that were sent to USPS.') |
| Opened filtered | From the Customer Card: `RunPageLink = "Customer No." = field("No.")` (§4.15) |
| Other N/A rows | as §4.1 |

### 4.8 Table 60111 "obcfusps USPS Address Buffer"
| Property | Value |
|---|---|
| Source table | New table, **`TableType = Temporary;`** `Caption = 'USPS Address Buffer'`; `DataClassification = CustomerContent;` |
| Purpose | Argument table (§6). Carries one check from Address Validation to the API Client and back, and is the dialog page's source |
| Keys | `key(PK; "Primary Key") { Clustered = true; }` |
| Deletion behaviour | N/A — temporary |
| Other N/A rows | as §4.1 |
#### Fields
All stored (temporary).
| No. / Source field | Identifier | Data type | Notes |
|---|---|---|---|
| 1 "Primary Key" | primaryKey | Integer | always 0 |
| 2 "Customer No." | customerNo | Code[20] | |
| 3–7 "Original Address", "Original Address 2", "Original City", "Original State", "Original ZIP Code" | originalAddress … originalZipCode | Text[100], Text[50], Text[30], Text[30], Code[20] | Snapshot of the five customer values sent (Address, Address 2, City, County, Post Code) |
| 8–12 "USPS Address", "USPS Address 2", "USPS City", "USPS State", "USPS ZIP Code" | uspsAddress … uspsZipCode | Text[250] each | As returned; ZIP formatted (§4.12) |
| 13 "DPV Confirmation" | dpvConfirmation | Code[10] | `additionalInfo.DPVConfirmation` |
| 14 Vacant | vacant | Boolean | `additionalInfo.vacant = 'Y'` |
| 15 Business | business | Boolean | `additionalInfo.business = 'Y'` |
| 16 "Match Codes" | matchCodes | Text[100] | |
| 17 "Correction Codes" | correctionCodes | Text[100] | |
| 18 "USPS Message" | uspsMessage | Text[2048] | |
| 19 "HTTP Status" | httpStatus | Integer | 0 = no response |
| 20 "Not Found" | notFound | Boolean | true only for an address-call 404 |
| 21 "User Message" | userMessage | Text[2048] | The composed, user-facing failure text (a label from §7) |
| 22 Environment | environment | `enum "obcfusps USPS Environment"` | Set by the API Client |

### 4.9 Page 60112 "obcfusps USPS Address Compare" (comparison dialog)
| Property | Value |
|---|---|
| Source table | `"obcfusps USPS Address Buffer"` (60111), temporary by table type |
| PageType | **`StandardDialog`** (verified: 91 Base Application pages use it). `Caption = 'USPS Address Suggestion'`; `Editable = false`; `InsertAllowed = false; ModifyAllowed = false; DeleteAllowed = false;` |
| Buttons | StandardDialog has the platform OK and Cancel buttons. **OK = Accept USPS Address; Cancel, X and Esc = Ignore (FR-4).** The `InstructionTxt` line makes this explicit. When `CanAccept = false` (no permission to modify customers, or a USPS value too long), the page shows the reason (`AcceptBlockedReason`, Style = Unfavorable), and the caller treats OK as Ignore. The page cannot disable the platform OK button — see §11 (Q1, decided) |
| Variables | `CanAccept: Boolean; AcceptBlockedReason: Text; DeliveryNotes: Text; DeliveryWarning: Text;` and per-row style variables `AddressStyle, Address2Style, CityStyle, StateStyle, ZipStyle: Text` |
| Bold for changed | Every USPS-column field sets `StyleExpr = <Row>Style;`. `SetData` sets each style variable to `'Strong'` when `AddressValidation.ValuesDiffer(Original, USPS)` is true, else `'Standard'`. 'Strong' renders bold. The style is decided by the same public comparison procedure the outcome uses (§4.13), so the bold rows match exactly what made the check a suggestion |
| Layout | `group(Instructions)`: `field(instruction; InstructionTxt)` (ShowCaption = false, MultiLine). `grid(Compare)` (`GridLayout = Columns`) holding `group(CurrentBC)` (Caption 'Current (BC)') and `group(USPSSuggestion)` (Caption 'USPS suggestion'). CurrentBC has `field(originalAddress; Rec."Original Address")` (Caption 'Address'), `originalAddress2` ('Address 2'), `originalCity` ('City'), `originalState` ('State'), `originalZipCode` ('ZIP Code'). USPSSuggestion has `uspsAddress`, `uspsAddress2`, `uspsCity`, `uspsState`, `uspsZipCode`, each with `ShowCaption = false` (the rows align with the left column's captions) and its `StyleExpr`. `group(Notes)` (Caption 'Delivery notes'): `field(deliveryWarning; DeliveryWarning)` (ShowCaption = false, Style = Attention, Visible = DeliveryWarning <> ''), `field(deliveryNotes; DeliveryNotes)` (ShowCaption = false, MultiLine), `field(acceptBlockedReason; AcceptBlockedReason)` (ShowCaption = false, Style = Unfavorable, Visible = not CanAccept) |
| Procedures | `procedure SetData(var TempAddressBuffer: Record "obcfusps USPS Address Buffer" temporary; NewCanAccept: Boolean; NewAcceptBlockedReason: Text)`: `Rec.Copy(TempAddressBuffer, true)` (or delete and insert into the page's temporary Rec); set CanAccept and AcceptBlockedReason; compute the five styles; `DeliveryWarning`: DPV `D` → DpvMissingSecondaryTxt, `S` → DpvUnconfirmedSecondaryTxt, `N` → DpvNotConfirmedTxt, otherwise ''. `DeliveryNotes`: lines for `Vacant` (VacantTxt), `Business` (BusinessTxt), and `"USPS Message"` (match and correction text), joined with a line break. Accept stays possible for D, S and N (FR-4) |
| Other N/A rows | as §4.1 |

### 4.10 Interface "obcfusps USPS Transport" (no ID)
The replaceable layer the test app swaps for a fake (FRD OQ-17, decided by AJ Ansari). Only the two HTTPS calls cross it. Credentials and the token cross it **only as SecretText**, which cannot be unwrapped in Business Central online (Learn: SecretText.Unwrap "is supported only in Business Central on-premises"), so no implementation can read them.
```al
namespace OnlyBCFans.USPSAddress;

interface "obcfusps USPS Transport"
{
    /// POSTs RequestBody (JSON) to Url. Returns false when no HTTP response arrived (timeout, no connection, blocked by the environment); HttpStatus = 0 then.
    procedure SendTokenRequest(Url: Text; RequestBody: SecretText; TimeoutMs: Integer; var HttpStatus: Integer; var ResponseBody: Text): Boolean;
    /// GETs Url with "Authorization: Bearer <AccessToken>" and "Accept: application/json". Same return contract.
    procedure SendAddressRequest(Url: Text; AccessToken: SecretText; TimeoutMs: Integer; var HttpStatus: Integer; var ResponseBody: Text): Boolean;
}
```
Rejected alternative: System Application "Rest Client" (codeunit 2351/2360, interface "Http Client Handler", namespace `System.RestClient`, verified). Its `Send` raises an error whose text contains the request URI on a connection failure (verified in `RestClientImpl.SendRequest`), which the extension would have to catch and must never log (FR-5). The local two-method interface keeps status-level control and a smaller fake.

### 4.11 Codeunit 60098 "obcfusps USPS Credential Mgt."
| Property | Value |
|---|---|
| Kind | Codeunit; `Access = Public` (the test app calls the setters); getters are `internal` |
| `using` namespaces | `System.Environment.Configuration` (Guided Experience) |
| Storage | `IsolatedStorage`, **`DataScope::Company`** (shared by all users, FR-6), values set with `IsolatedStorage.Set(Key: Text; Value: SecretText; DataScope)` (Learn, runtime 13.0+). Keys (Locked `Tok` labels): `ConsumerKeyStorageTok = 'OBCFUSPS-ConsumerKey'`, `ConsumerSecretStorageTok = 'OBCFUSPS-ConsumerSecret'`, `AccessTokenStorageTok = 'OBCFUSPS-AccessToken'` (SecretText), `TokenValidUntilStorageTok = 'OBCFUSPS-TokenValidUntil'` (plain Text, `Format(DateTime, 0, 9)`). Not `SetEncrypted`: USPS access tokens are long JWTs (see §13.9) |
| Procedures | `procedure SetConsumerKey(NewValue: SecretText)` and `procedure SetConsumerSecret(NewValue: SecretText)`: `if NewValue.IsEmpty() then IsolatedStorage.Delete(Key, DataScope::Company) else IsolatedStorage.Set(Key, NewValue, DataScope::Company); ClearToken(); MarkAssistedSetupCompleteIfReady();` · `procedure HasConsumerKey(): Boolean`, `HasConsumerSecret(): Boolean`, `HasCredentials(): Boolean` (`IsolatedStorage.Contains(Key, DataScope::Company)`) · `internal procedure GetConsumerKey(): SecretText` and `internal procedure GetConsumerSecret(): SecretText` (`IsolatedStorage.Get(Key, DataScope::Company, Value)`) · `internal procedure GetCachedToken(var AccessToken: SecretText): Boolean`: returns true only if both token keys exist, `Evaluate(ValidUntil, Text, 9)` succeeds, and `CurrentDateTime() < ValidUntil` · `internal procedure SetCachedToken(AccessToken: SecretText; ExpiresInSeconds: BigInteger)`: `if ExpiresInSeconds <= 60 then begin ClearToken(); exit; end;` then store the token and `ValidUntil := CurrentDateTime() + (ExpiresInSeconds - 60) * 1000` (60 s before USPS's expiry; the lifetime always comes from USPS, FR-6) · `procedure ClearToken()`: delete both token keys if present · `local procedure MarkAssistedSetupCompleteIfReady()`: `if HasCredentials() then GuidedExperience.CompleteAssistedSetup(ObjectType::Page, Page::"obcfusps USPS Setup Wizard");` — "complete once both values are saved", from the card or the wizard (FRD OQ-16) |
| Debugging | Every procedure that handles a credential or token value carries `[NonDebuggable]` |
| Other N/A rows | as §4.1 |

### 4.12 Codeunit 60114 "obcfusps USPS API Client" and codeunit 60115 "obcfusps USPS Http Transport"
**60115 "obcfusps USPS Http Transport"** — `implements "obcfusps USPS Transport"`, `Access = Public` (it is the default implementation). Both methods are `[NonDebuggable]`:
```al
procedure SendTokenRequest(Url: Text; RequestBody: SecretText; TimeoutMs: Integer; var HttpStatus: Integer; var ResponseBody: Text): Boolean
var Client: HttpClient; Request: HttpRequestMessage; Response: HttpResponseMessage; Content: HttpContent; ContentHeaders: HttpHeaders;
begin
    HttpStatus := 0; ResponseBody := '';
    Content.WriteFrom(RequestBody);                       // Learn: WriteFrom(SecretText), runtime 12.0
    Content.GetHeaders(ContentHeaders);
    if ContentHeaders.Contains(ContentTypeTok) then ContentHeaders.Remove(ContentTypeTok);
    ContentHeaders.Add(ContentTypeTok, JsonMediaTypeTok);
    Request.Method(PostTok); Request.SetRequestUri(Url); Request.Content(Content);
    Client.Timeout(TimeoutMs);
    if not Client.Send(Request, Response) then exit(false);
    HttpStatus := Response.HttpStatusCode();
    Response.Content().ReadAs(ResponseBody);
    exit(true);
end;
```
`SendAddressRequest` is the same with `Request.Method(GetTok)`, no content, and `Request.GetHeaders(Headers); Headers.Add(AuthorizationTok, SecretStrSubstNo(BearerTok, AccessToken)); Headers.Add(AcceptTok, JsonMediaTypeTok);`. (Learn: HttpHeaders.Add(Text, SecretText), runtime 12.0. SecretStrSubstNo is used the same way in Base App codeunit "OAuth 2.0 Mgt.".)

**60114 "obcfusps USPS API Client"** — `Access = Public`. Holds `Transport: Interface "obcfusps USPS Transport"`, `TransportSet: Boolean` and `CredentialMgt`. The only object with USPS-specific logic (FRD §5).
- **Base URLs** (Locked): Production `ProdBaseUrlTok = 'https://apis.usps.com'`; Test (TEM) `TemBaseUrlTok = 'https://apis-tem.usps.com'`. Paths: `TokenPathTok = '/oauth2/v3/token'`, `AddressPathTok = '/addresses/v3/address'`. Environment blank → `SetupIncompleteErr`.
- **Public procedures:**
  - `procedure SetTransport(NewTransport: Interface "obcfusps USPS Transport")` — `Transport := NewTransport; TransportSet := true;`
  - `procedure TestConnection(var ErrorText: Text): Boolean` — requires `HasCredentials()` (else `ErrorText := MissingCredentialsErr`) and a non-blank Environment (else `ErrorText := EnvironmentMissingErr`). Always requests a **new** token (bypasses the cache); on success caches it and returns true. On failure: `ErrorText := StrSubstNo(TestConnectionFailedErr, <user message>, <USPS message>)`. Never calls the address service and never logs (FR-6).
  - `procedure ValidateAddress(var TempAddressBuffer: Record "obcfusps USPS Address Buffer" temporary): Boolean` — true only when USPS returned HTTP 200 and the address could be read. Fills the USPS fields, "HTTP Status", "USPS Message", Environment, and on failure "User Message" and "Not Found".
- **Local procedures:**
  - `GetTransport(): Interface …` — if not TransportSet, use `DefaultTransport: Codeunit "obcfusps USPS Http Transport"`.
  - `[NonDebuggable] BuildTokenRequestBody(): SecretText` — JsonObject `{"client_id": "Placeholder", "client_secret": "Placeholder", "grant_type": "client_credentials"}`, then `JObject.WriteWithSecretsTo(Secrets, Body)` with `Secrets` = Dictionary of [Text, SecretText] `{'$.client_id': GetConsumerKey(), '$.client_secret': GetConsumerSecret()}` (pattern verified in Base App "OAuth 2.0 Mgt.").
  - `GetAccessToken(ForceNew: Boolean; var AccessToken: SecretText; var FromCache: Boolean; var TempAddressBuffer): Boolean`
  - `[NonDebuggable] ParseTokenResponse(ResponseBody: Text; var AccessToken: SecretText; var ExpiresIn: BigInteger): Boolean` — reads `access_token` (required, non-blank) and `expires_in` (number). Missing token → false.
  - `BuildAddressUrl(TempAddressBuffer): Text`
  - `ParseAddressResponse(ResponseBody: Text; var TempAddressBuffer): Boolean`
  - `ReadUSPSErrorMessage(ResponseBody: Text): Text`
  - `SetFailure(var TempAddressBuffer; HttpStatus: Integer; UserMessage: Text; USPSMessage: Text)`
- **Request mapping** (address call; the customer name and number are never sent, FR-1). Each value goes through `Uri.EscapeDataString` (System App codeunit 3060 "Uri", `System.Utilities`, verified) and is joined as `?name=value&…`. Blank values are omitted.
  | USPS query parameter | From |
  |---|---|
  | `streetAddress` | Original Address |
  | `secondaryAddress` | Original Address 2 |
  | `city` | Original City |
  | `state` | Original State (UpperCase) |
  | `ZIPCode` | first 5 characters of Original ZIP Code, only when they are 5 digits |
  | `ZIPPlus4` | the 4 digits after `-` (or characters 6–9 of a 9-digit value), only when all 4 are digits |
- **Response mapping** (HTTP 200; read field by field by name, missing and extra fields tolerated, FR-7). A helper `GetText(JObject; Name): Text` returns '' for a missing or null value.
  | JSON path | Buffer field |
  |---|---|
  | `address.streetAddress` | USPS Address |
  | `address.secondaryAddress` | USPS Address 2 |
  | `address.city` | USPS City |
  | `address.state` | USPS State |
  | `address.ZIPCode` (+ `'-'` + `address.ZIPPlus4` when non-blank) | USPS ZIP Code |
  | `additionalInfo.DPVConfirmation` | DPV Confirmation |
  | `additionalInfo.vacant = 'Y'` | Vacant |
  | `additionalInfo.business = 'Y'` | Business |
  | `matches[].code` | Match Codes (comma-joined) |
  | `corrections[].code` | Correction Codes (comma-joined) |
  | `matches[].text` and `corrections[].text` | USPS Message (`'; '`-joined, `CopyStr` 2048) |

  Firm (`firm`) is ignored (FRD OQ-6). No `address` object, or invalid JSON → UnexpectedResponseErr, Error.
- **USPS error message:** read `error.message`, else `error_description`, else `error` (string), else ''.
- **HTTP status handling.** "Fail" sets the buffer through SetFailure and returns false. "USPS msg" is the text from `ReadUSPSErrorMessage`.
  | Call | Condition | Result | User Message (label) | Logged as (by 60113) |
  |---|---|---|---|---|
  | token | transport returned false | Fail, status 0 | NotRespondingErr | Error |
  | token | 200, token readable | cache it (`SetCachedToken`) | — | — |
  | token | 200, token not readable | Fail, 200 | UnexpectedResponseErr | Error |
  | token | 400, 401, 403 | Fail, status | CredentialsRejectedErr | Error (test 8: 401) |
  | token | 429 | Fail | QuotaErr | Error |
  | token | 500–599 | Fail | NotRespondingErr | Error |
  | token | any other | Fail | UnexpectedResponseErr | Error |
  | address | transport returned false | Fail, status 0 | NotRespondingErr | Error |
  | address | 200 | parse (above) | — | 60113 compares |
  | address | 400 | Fail | `StrSubstNo(CouldNotReadErr, USPS msg)` | Error |
  | address | 401/403 and the token came **from the cache** | `ClearToken()`, request a new token **once**, repeat the address call once; a second 401/403 → Fail | CredentialsRejectedErr | Error |
  | address | 401/403 and the token was **just fetched** | Fail (a new token would not help; keeps the call count down) | CredentialsRejectedErr | Error |
  | address | 404 | Fail, `"Not Found" := true` | `StrSubstNo(NotFoundMsg, USPS msg)` | Not Found |
  | address | 429 | Fail | QuotaErr | Error |
  | address | 500–599 | Fail | NotRespondingErr | Error |
  | address | any other | Fail | UnexpectedResponseErr | Error |

  No other retry exists (FR-7). Worst case is 3 HTTPS calls: a cached token is rejected, then one token call and one address call. The normal case is ≤ 2 (FRD §7).
- **Timeout:** `Setup."Timeout (Seconds)" * 1000` ms, passed to the transport.

### 4.13 Codeunit 60113 "obcfusps Address Validation" (orchestration)
| Property | Value |
|---|---|
| Kind | Codeunit; `Access = Public`; **`Permissions = tabledata "obcfusps USPS Validation Log" = i;`** (indirect insert; the USE set grants `i`, §10) |
| `using` namespaces | `Microsoft.Sales.Customer` (table 18); `System.Security.User` (codeunit 152 "User Permissions", Access Public, verified); `System.Security.AccessControl` (table 2000000254 "Expanded Permission", verified) |
| Public procedures | `procedure SetTransport(NewTransport: Interface "obcfusps USPS Transport")` — passes it to its API Client instance (test injection). `procedure ValidateCustomerAddress(CustomerNo: Code[20])` — the whole check. `procedure ValuesDiffer(BCValue: Text; USPSValue: Text): Boolean` — `exit(Normalize(BCValue) <> Normalize(USPSValue));` with `Normalize(V) = UpperCase(DelChr(V, '<>', ' '))` (FR-3: trim, ignore case). `procedure CanModifyCustomers(): Boolean` — `TempExpandedPermission := UserPermissions.GetEffectivePermission(TempExpandedPermission."Object Type"::"Table Data", Database::Customer); exit(TempExpandedPermission."Modify Permission" = TempExpandedPermission."Modify Permission"::Yes);` (option members `' ',Yes,Indirect`, verified). **Not** `Customer.WritePermission()`: Learn says that tests Insert, Delete and Modify together, which is too strict for "allowed to modify customers" |
| Transaction boundaries | (1) The caller (§4.15) has already done `CurrPage.SaveRecord(); Commit();`, so the user's own edit is saved and the check starts outside a write transaction. (2) Preconditions, the HTTP calls and the dialog all run **before any write** (FR-4). (3) Each outcome then writes its customer change and its one log entry in **one** transaction, so both are saved or neither is (FR-4). (4) Error outcome: insert the log, `Commit()`, then `Error(UserMessage)`, so the entry survives (FR-5) |
| Flow (pseudo-AL) | See the block below |
| Other N/A rows | as §4.1 |

```al
procedure ValidateCustomerAddress(CustomerNo: Code[20])
begin
    Customer.Get(CustomerNo);
    CheckPreconditions(Customer, Setup);               // errors below; nothing sent, nothing logged
    FillOriginal(TempBuf, Customer);                   // snapshot of the 5 values + Customer No.
    if not ApiClient.ValidateAddress(TempBuf) then begin
        if TempBuf."Not Found" then begin
            if CanModifyCustomers() then SetAddressValidated(CustomerNo, false);   // only if currently true
            InsertLog(TempBuf, Result::"Not Found", false);
            Message(TempBuf."User Message");
            exit;
        end;
        InsertLog(TempBuf, Result::Error, false);
        Commit();
        Error(TempBuf."User Message");
    end;
    if not AnyValueDiffers(TempBuf) then begin            // includes the "letter case only" case (FR-3)
        if CanModifyCustomers() then SetAddressValidated(CustomerNo, true);    // only if currently false (OQ-21)
        InsertLog(TempBuf, Result::Confirmed, false);
        Message(ConfirmedMsg);
        exit;
    end;
    CanAccept := CanModifyCustomers() and FitsCustomerFields(TempBuf, BlockReason);   // NoPermissionTxt / ValueTooLongTxt
    ComparePage.SetData(TempBuf, CanAccept, BlockReason);
    ComparePage.LookupMode(false);
    if (ComparePage.RunModal() = Action::OK) and CanAccept then
        AcceptSuggestion(CustomerNo, TempBuf)          // Accepted or blocked (address changed meanwhile)
    else
        InsertLog(TempBuf, Result::"Suggestion Ignored", false);
end;
```
- **CheckPreconditions**, in this order (FR-1):
  1. `Setup.Get()`, `Enabled`, `Environment <> " "` and `CredentialMgt.HasCredentials()`, else SetupIncompleteErr.
  2. `(Customer."Country/Region Code" = '') or (Customer."Country/Region Code" = Setup."US Country/Region Code")`, else NotUSAddressErr.
  3. `(Address <> '') and (((City <> '') and (County <> '')) or ("Post Code" <> ''))`, else AddressIncompleteErr.
  4. If `County <> ''`: `StrLen(DelChr(County,'<>',' ')) = 2` and both characters in A–Z after UpperCase, else StateCodeErr.
- **AnyValueDiffers:** ValuesDiffer over Address, Address 2, City, State (County) and ZIP (Post Code against the formatted USPS ZIP; a new +4 differs, FR-3).
- **FitsCustomerFields:** `StrLen(USPS x) <= MaxStrLen(Customer.<field>)` for Address (100), Address 2 (50), City (30), County (30) and Post Code (20), all verified. The first failure sets `BlockReason := StrSubstNo(ValueTooLongTxt, <caption>, <max>)`. Never truncate (FRD §5).
- **AcceptSuggestion**, one transaction:
  1. `Customer.LockTable(); Customer.Get(CustomerNo);`
  2. If any of the five current values differs **exactly** from the snapshot: `InsertLog(TempBuf, Result::"Suggestion Ignored", false); Message(AddressChangedMsg); exit;` (OQ-21; flag unchanged).
  3. Otherwise **assign directly, never `Validate`**: `Customer.Address := TempBuf."USPS Address"; Customer."Address 2" := …; Customer.City := …; Customer.County := TempBuf."USPS State"; Customer."Post Code" := TempBuf."USPS ZIP Code";` (`CopyStr` with `MaxStrLen`, which is safe because FitsCustomerFields already passed); `Customer."obcfusps Address Validated" := true; Customer.Modify(true); InsertLog(TempBuf, Result::"Suggestion Accepted", true);`
  - Direct assignment is the mechanism that keeps the Post Code lookup (`PostCode.ValidatePostCode` / `ValidateCity` in Customer `OnValidate`, verified in source) from replacing USPS values, and keeps the table extension's `OnAfterValidate` reset (§4.14) from firing on the extension's own Accept (FR-8).
  - `Modify(true)` runs Customer `OnModify` (verified in source): `SetLastModifiedDateTime` (Last Date Modified, FR-9), `IsContactUpdateNeeded` (Address, Address 2, City, Post Code and County are all in its list) → `UpdateContFromCust.OnModify` (linked-Contact sync, FR-9 G3 — code path verified in source; runtime behaviour partly verified, see 13.7 F12). **AMENDED by §13.1: Commit after the HTTP phase, write phase in codeunit 60118, never-raising `TryValidateCustomerAddress`.**
- **SetAddressValidated(No; Value):** `Customer.LockTable(); Customer.Get(No); if Customer."obcfusps Address Validated" <> Value then begin Customer."obcfusps Address Validated" := Value; Customer.Modify(true); end;`
- **InsertLog(TempBuf; Result; Accepted):** `Log.Init(); Log."Customer No." := …; Log."Checked At" := CurrentDateTime(); Log."User ID" := CopyStr(UserId(), 1, MaxStrLen(Log."User ID")); Log.Result := Result; Log.Accepted := Accepted;` then the 5 originals, the 5 USPS values (blank for Not Found and Error, because the buffer has none), DPV, codes, USPS Message, HTTP Status and Environment; `Log.Insert(true);`. Exactly one call per check that reached USPS (FR-1.6).

### 4.14 Table extension 60116 "obcfusps Customer" (extends table 18 Customer)
| Property | Value |
|---|---|
| Source table | **Customer, table 18**, namespace `Microsoft.Sales.Customer` (verified; not marked non-extensible) |
| `using` namespaces | `Microsoft.Sales.Customer` |
| Deletion behaviour | Unchanged standard behaviour; no `OnDelete` code (see §4.6) |
| Edit-detection decision | **Table-extension field triggers** `modify(<field>) { trigger OnAfterValidate() … }` on Address, "Address 2", City, County and "Post Code" (field names verified: 5 Address Text[100], 6 "Address 2" Text[50], 7 City Text[30], 92 County Text[30], 91 "Post Code" Code[20]). Chosen over `OnAfterValidateEvent` subscribers for two reasons: the field is referenced by symbol, so it is compile-checked and can't hit the silent wrong-`ElementName` failure Standards §10.1 warns about; and the rule sits on the table it guards. Country/Region Code is not watched (FRD OQ-14). **Known limitation (FRD FR-8):** code that assigns these fields without `Validate` (some imports and integrations) does not fire the triggers, so the flag is not reset. The Post Code trigger also covers its side effects on City and County |
| Triggers | Each of the five: `trigger OnAfterValidate() begin ResetAddressValidated(Rec.<Field> <> xRec.<Field>); end;` |
| Procedures | `local procedure ResetAddressValidated(Changed: Boolean) begin if Changed and Rec."obcfusps Address Validated" then Rec."obcfusps Address Validated" := false; end;` (the page saves the record as usual) |
| Other N/A rows | as §4.1 |
#### Fields
| Source field | Identifier | Conversion decision | Included — reason | FlowField or stored | Data type |
|---|---|---|---|---|---|
| 60093 "obcfusps Address Validated" | obcfuspsAddressValidated | prefixed field name (field added to a base table); `Caption = 'Address Validated'` | FR-8 | **stored** (state set by code, not computed); `InitValue = false`; `Editable = false` on the table field as well; `DataClassification = CustomerContent` | Boolean |
Existing customers start at false: a new Boolean column's default is false, so no code is needed (§8).

### 4.15 Page extension 60117 "obcfusps Customer Card" (extends page 21 "Customer Card")
| Property | Value |
|---|---|
| Source | page 21 "Customer Card", namespace `Microsoft.Sales.Customer`, SourceTable Customer (verified with `al_inspectpage`) |
| `using` namespaces | `Microsoft.Sales.Customer` |
| Layout | `addafter("Post Code")` — inside group `AddressDetails` (Caption 'Address') of FastTab `"Address & Contact"`, both verified: `field(obcfuspsAddressValidated; Rec."obcfusps Address Validated") { Caption = 'Address Validated'; ToolTip = 'Specifies whether the current address was confirmed by USPS or accepted from USPS. It is set by Validate Address (USPS) and cleared when the address is edited.'; ApplicationArea = All; Editable = false; }` |
| Actions | `addlast("F&unctions")` (processing group, verified): `action(obcfuspsValidateAddress)` (Caption 'Validate Address (USPS)', Image = CheckList, ToolTip 'Check this customer''s address with the US Postal Service and accept or ignore the suggested address.'). `OnAction`: `CurrPage.SaveRecord(); Commit(); AddressValidation.ValidateCustomerAddress(Rec."No."); Rec.Get(Rec."No."); CurrPage.Update(false);`. `addlast(Category_Process)` (promoted group, verified): `actionref(obcfuspsValidateAddress_Promoted; obcfuspsValidateAddress)`. `addlast("&Customer")` (navigation group, verified): `action(obcfuspsValidationLog)` (Caption 'USPS Validation Log', Image = Log, `RunObject = page "obcfusps USPS Log Entries"; RunPageLink = "Customer No." = field("No.");`, ToolTip 'View the USPS address checks for this customer.') |
| Other N/A rows | as §4.1 |

### 4.16 Codeunit 60100 "obcfusps Setup Registration"
| Property | Value |
|---|---|
| Kind | Codeunit; `Access = Internal`; **`Permissions = tabledata "Retention Period" = ri, tabledata "Retention Policy Setup" = ri;`** (as in Microsoft's codeunit 3999 "Reten. Pol. Install - BaseApp") |
| `using` namespaces | `System.DataAdministration` (codeunit 3905 "Reten. Pol. Allowed Tables", codeunit 3902 "Retention Policy Setup", table 3901 "Retention Policy Setup", table 3900 "Retention Period", enum 3900 "Retention Period Enum" — all verified); `System.Environment.Configuration` (codeunit 1990 "Guided Experience", enum 1815 "Assisted Setup Group", enum 1990 "Guided Experience Type"); `System.Media` (enum 3710 "Video Category"); `Microsoft.Foundation.Company` (codeunit 2 "Company-Initialize") |
| `procedure RegisterAll()` | `RegisterRetentionPolicy(); RegisterAssistedSetup();` Idempotent. Database writes only, no outside calls (Standards §9.5) |
| `RegisterRetentionPolicy()` | (1) `RetenPolAllowedTables.AddAllowedTable(Database::"obcfusps USPS Validation Log", Log.FieldNo("Checked At"));`. The overload `(TableId: Integer; DefaultDateFieldNo: Integer): Boolean` is verified, and the table must belong to the calling app, which it does. (2) `Evaluate(TwoYears, TwoYearsFormulaTok);` with `'<-2Y>'`: Microsoft's standard periods use negative formulas (`'<-1Y>'`, `'<-3Y>'`), and custom formulas must yield a date ≥ 2 days in the past (verified in "Retention Period Impl."). Then `PeriodCode := RetentionPolicySetupCU.FindOrCreateRetentionPeriod(RetentionPeriodCodeTok, Enum::"Retention Period Enum"::Custom, TwoYears);` with code `'OBCFUSPS-2Y'`. The procedure reuses any existing Custom period with the same formula (verified). (3) `if not RetentionPolicySetup.Get(Database::"obcfusps USPS Validation Log") then begin RetentionPolicySetup.Validate("Table Id", …); RetentionPolicySetup.Validate("Apply to all records", true); RetentionPolicySetup.Validate("Retention Period", PeriodCode); RetentionPolicySetup.Validate(Enabled, false); RetentionPolicySetup.Insert(true); end;`. **Enabled = false is the Microsoft install pattern; AJ Ansari confirmed it on 2026-10-10 (Q3, closes FRD OQ-8(b))**. Administrators change the period or enable it in Retention Policies (FR-5) |
| `RegisterAssistedSetup()` | `if not GuidedExperience.Exists(Enum::"Guided Experience Type"::"Assisted Setup", ObjectType::Page, Page::"obcfusps USPS Setup Wizard") then GuidedExperience.InsertAssistedSetup(AssistedSetupTitleTxt, AssistedSetupShortTitleTxt, AssistedSetupDescriptionTxt, 5, ObjectType::Page, Page::"obcfusps USPS Setup Wizard", Enum::"Assisted Setup Group"::Connect, '', Enum::"Video Category"::Uncategorized, '');`. Signature verified (Title Text[2048], ShortTitle Text[50], Description Text[1024], ExpectedDuration Integer, ObjectType, ID, group, VideoUrl Text[250], VideoCategory, HelpUrl Text[250]). `Connect` (caption 'Connect with other systems') is a Base Application value of the extensible "Assisted Setup Group" (verified). If credentials already exist, also `CompleteAssistedSetup` |
| Event subscriber | `[EventSubscriber(ObjectType::Codeunit, Codeunit::"Company-Initialize", 'OnCompanyInitialize', '', false, false)] local procedure RegisterOnCompanyInitialize() begin RegisterAll(); end;`. Verified: `[IntegrationEvent(false, false)] local procedure OnCompanyInitialize()` in Base Application codeunit 2. Needed because Guided Experience Item (table 1990) and the retention tables (3900, 3901, 3903) are per company (no `DataPerCompany = false`), and an install codeunit doesn't run for companies created later. **Why not Microsoft's registration events:** "Guided Experience".`OnRegisterAssistedSetup` and "Reten. Pol. Allowed Tables".`OnRefreshAllowedTables` are declared `internal procedure` in System Application 28.5 (verified), so this extension doesn't subscribe to them |
| Other N/A rows | as §4.1 |

### 4.17 Codeunit 60099 "obcfusps USPS Install"
| Property | Value |
|---|---|
| Kind | `Subtype = Install;` `Access = Internal;` |
| Triggers | `trigger OnInstallAppPerCompany() var SetupRegistration: Codeunit "obcfusps Setup Registration"; begin SetupRegistration.RegisterAll(); end;` No `OnInstallAppPerDatabase` (Standards §1.5). No upgrade tags exist, so there is nothing to `SetAllUpgradeTags` (§8) |
| On install for existing customers | Nothing: the Address Validated column is created with its default, false, for every existing row (FR-8) |
| Other N/A rows | as §4.1 |

### 4.18 Permission sets 60101 and 60102
See §10 for their contents. `Assignable = true;`. **Amended by §13.1:** the USE set also grants Execute on codeunit 60118 "obcfusps Validation Writer" (the ADMIN set includes USE). Captions are `'USPS Address Validator - Use'` (28 characters) and `'USPS Address Validator - Admin'` (30 characters).

### 4.19 Test app objects (60123–60127; namespace `OnlyBCFans.USPSAddress`)
| ID | Object | Specification |
|---|---|---|
| 60123 | codeunit "obcfusps Fake USPS Transport" | `implements "obcfusps USPS Transport"`; **`SingleInstance = true`**, so a test reads the same call counters the API Client wrote, whatever the interface's copy semantics. State: two queues of (Responds: Boolean; Status: Integer; Body: Text) for token and address calls, `TokenCalls`, `AddressCalls`, `LastAddressUrl`. Procedures: `Reset()`, `EnqueueTokenResponse(Status: Integer; Body: Text)`, `EnqueueTokenNoResponse()`, `EnqueueAddressResponse(Status; Body)`, `EnqueueAddressNoResponse()`, `TokenCallCount(): Integer`, `AddressCallCount(): Integer`, `GetLastAddressUrl(): Text`. Each interface method increments its counter and dequeues; an empty queue raises `Error('Unexpected USPS call in test.')` (a Locked label), so an unexpected call fails the test. It never calls USPS (FRD §7.2) |
| 60124 | codeunit "obcfusps Test Library" | Helpers. `InitSetup()`: Setup Get-or-Insert with Enabled = true, Environment = Test, US code 'US', Timeout 10; `CredentialMgt.SetConsumerKey('test-key'); SetConsumerSecret('test-secret'); ClearToken()`. `CreateUSCustomer(Address, Address2, City, State, Zip): Code[20]`: Customer with a unique No. (`'USPSUT'` + a counter, ≤ 20), Country/Region '' , inserted with `Insert(true)`. `TokenJson(ExpiresIn: Integer): Text`. `AddressJson(Street, Secondary, City, State, Zip5, Plus4, DPV, Vacant, Business): Text`. `ErrorJson(Message): Text`. `AssertEqual(Expected; Actual; Msg)` / `AssertTrue` via `Error` (no Microsoft test-library dependency). `LastLogEntry(CustomerNo): Record` |
| 60125 | codeunit "obcfusps Validation Tests" | `Subtype = Test`. Each test: `Fake.Reset(); Lib.InitSetup(); Validator.SetTransport(Fake);`. Uses `[MessageHandler]` and `[ModalPageHandler]` (TestPage of page 60112; `.OK().Invoke()` or `.Cancel().Invoke()`). Covers FRD tests 1–7 (§12a) |
| 60126 | codeunit "obcfusps API Client Tests" | `Subtype = Test`. Covers tests 8, 9 and 10 |
| 60127 | codeunit "obcfusps Addr Validated Tests" | `Subtype = Test`. Covers tests 15–18 and 20 |
Error-path tests wrap the call in `asserterror` and then read the log entry the codeunit committed before its `Error` (see §13.9 item 5; superseded by the never-raising `TryValidateCustomerAddress`, §13.1.4).

## 5. Standard object template
Standards §1.3 is the API page template. No object in this project is an API page, so what applies is its non-API core: the §1.1 header, one flat namespace, `using` lines taken from the symbols, a `Caption` on every object, the §1.4 trio on every page field, labels for every message, and 4-space indentation (§1.6). Pattern every generated object follows:
```al
namespace OnlyBCFans.USPSAddress;

using Microsoft.Sales.Customer;   // only the namespaces the object uses, copied from §4

page 60110 "obcfusps USPS Log Entries"
{
    PageType = List;
    Caption = 'USPS Validation Log';
    SourceTable = "obcfusps USPS Validation Log";
    SourceTableView = sorting("Entry No.") order(descending);
    UsageCategory = Lists;
    ApplicationArea = All;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Entries)
            {
                field(entryNo; Rec."Entry No.")
                {
                    Caption = 'Entry No.';
                    ToolTip = 'Specifies the number of the log entry.';
                    ApplicationArea = All;
                }
                // … remaining fields, same three properties each
            }
        }
    }

    var
        ExampleErr: Label 'Example %1.', Comment = '%1 = what the placeholder holds';
}
```
Tables declare `DataClassification` at table level and override it per field where §4 says so. Enums write `Extensible` explicitly. No empty triggers, no commented-out code, no `// TODO` (§1.5). No `Option` anywhere. No ML properties or `TextConst` (§1.7).

## 6. Design patterns beyond the Standards Guide
| Need | Pattern | Source (cited) |
|---|---|---|
| One place for USPS-specific logic (FRD §5) | Façade: codeunit 60114 is the only object that knows USPS URLs, JSON and status codes | AL Guidelines, *Façade* (alguidelines.dev/docs/patterns/facade-pattern/) |
| Replaceable HTTP layer for tests in a SaaS sandbox | Interface injection: `"obcfusps USPS Transport"` with the default codeunit 60115 and the test fake 60123, injected through public `SetTransport` | Microsoft precedent in the downloaded symbols: System Application interface "Http Client Handler" with default codeunit 2360, injected by `"Rest Client".Initialize(HttpClientHandler)` (namespace `System.RestClient`) |
| Passing one check's many values between objects | Argument table (temporary table 60111) | AL Guidelines, NAV Patterns Archive, *Argument Table* |
| One setup record per company | Singleton / Setup table (`Get` or `Init`+`Insert` in `OnOpenPage`) | AL Guidelines, NAV Patterns Archive, *Setup Table* (Singleton Table) |
| Errors with a next step; log before the error | Label-based `Error` after `Commit` of the audit row | AL Guidelines, *Error Handling* (alguidelines.dev/docs/patterns/error-handling/); FRD FR-5, FR-7 |
| Fake whose state the test reads | Single-instance codeunit | AL Guidelines, NAV Patterns Archive, *Singleton Codeunit* |
| Secrets never visible | SecretText, `[NonDebuggable]` procedures and variables, JSON body built with `WriteWithSecretsTo` | Microsoft precedent in Base Application "OAuth 2.0 Mgt." and System Application "Password Dialog" (shipped source in `.alpackages/`) |

## 7. Labels and translatable text
Standards §8.3. Every message is a `Label` with an AA0074 suffix and a `Comment` for each placeholder. Source wording is US English (Parameters §1.9). No translation files. No telemetry is emitted, so there are no telemetry labels.
| Label (object) | Text | Comment | Locked |
|---|---|---|---|
| SetupIncompleteErr (60113) | USPS address validation is not set up. Contact your administrator. | | No |
| NotUSAddressErr (60113) | USPS validates US addresses only. | | No |
| AddressIncompleteErr (60113) | Enter a street address and either city and state or ZIP Code. | | No |
| StateCodeErr (60113) | Enter the 2-letter state code in the State field. | | No |
| ConfirmedMsg (60113) | The address is confirmed by USPS. No changes are needed. | | No |
| AddressChangedMsg (60113) | The customer's address was changed while the USPS suggestion was open, so nothing was updated. Run Validate Address (USPS) again. | | No |
| NoPermissionTxt (60113) | You can't accept the USPS address because you don't have permission to change customers. Choose OK or Cancel to close without changes. | | No |
| ValueTooLongTxt (60113) | You can't accept the USPS address because the USPS value for %1 is longer than %2 characters. Choose OK or Cancel to close without changes. | %1 = field caption (Address, Address 2, City, State or ZIP Code), %2 = maximum length | No |
| AddressCaptionTxt / Address2CaptionTxt / CityCaptionTxt / StateCaptionTxt / ZipCaptionTxt (60113) | Address / Address 2 / City / State / ZIP Code | | No |
| CouldNotReadErr (60114) | USPS could not read the address: %1 | %1 = message returned by USPS | No |
| NotFoundMsg (60114) | USPS could not find this address: %1 | %1 = message returned by USPS | No |
| CredentialsRejectedErr (60114) | USPS rejected the credentials. Contact your administrator. | | No |
| QuotaErr (60114) | The hourly USPS limit has been reached. Try again later. | | No |
| NotRespondingErr (60114) | USPS is not responding. Try again later. | | No |
| UnexpectedResponseErr (60114) | Unexpected response from USPS. Contact your administrator. | | No |
| MissingCredentialsErr (60114) | Enter the Consumer Key and Consumer Secret first. | | No |
| EnvironmentMissingErr (60114) | Select the USPS environment first. | | No |
| TestConnectionFailedErr (60114) | The connection to USPS failed. %1 USPS message: %2 | %1 = reason shown to the user, %2 = message returned by USPS (can be blank) | No |
| ProdBaseUrlTok / TemBaseUrlTok / TokenPathTok / AddressPathTok (60114) | https://apis.usps.com / https://apis-tem.usps.com / /oauth2/v3/token / /addresses/v3/address | | Yes |
| JSON and parameter name tokens (60114) | client_id, client_secret, grant_type, client_credentials, access_token, expires_in, address, streetAddress, secondaryAddress, city, state, ZIPCode, ZIPPlus4, additionalInfo, DPVConfirmation, vacant, business, matches, corrections, code, text, error, message, error_description, Placeholder | | Yes |
| ContentTypeTok / JsonMediaTypeTok / AuthorizationTok / AcceptTok / BearerTok / PostTok / GetTok (60115) | Content-Type / application/json / Authorization / Accept / Bearer %1 / POST / GET | BearerTok: %1 = access token (SecretText) | Yes |
| ConsumerKeyStorageTok / ConsumerSecretStorageTok / AccessTokenStorageTok / TokenValidUntilStorageTok (60098) | OBCFUSPS-ConsumerKey / OBCFUSPS-ConsumerSecret / OBCFUSPS-AccessToken / OBCFUSPS-TokenValidUntil | | Yes |
| ConnectionOkMsg (60096) | The connection to USPS works. A token was received. | | No |
| TestEnvironmentNoteTxt (60096) | The Test (TEM) environment also uses your production Consumer Key and Consumer Secret. | | No |
| MaskedPlaceholderTok (60096) | ******** | | Yes |
| WizardWelcomeTxt (60097) | Enter the Consumer Key and Consumer Secret from your USPS developer account. They're stored securely for this company and aren't shown again after you save them. | | No |
| WizardScopeTxt (60097) | You choose the environment, turn the service on, and test the connection on the USPS Address Validation Setup page. | | No |
| WizardFinishTxt (60097) | Choose Finish to save the credentials. | | No |
| InstructionTxt (60112) | Changed values are shown in bold. Choose OK to accept the USPS address, or Cancel to keep the current address. | | No |
| DpvMissingSecondaryTxt (60112) | The suite or apartment number is missing. | | No |
| DpvUnconfirmedSecondaryTxt (60112) | USPS could not confirm the suite or apartment number. | | No |
| DpvNotConfirmedTxt (60112) | USPS could not confirm this address for delivery. | | No |
| VacantTxt (60112) | USPS reports that this address is vacant. | | No |
| BusinessTxt (60112) | USPS reports that this is a business address. | | No |
| AssistedSetupTitleTxt (60100) | Set up USPS address validation (`MaxLength = 2048`) | | No |
| AssistedSetupShortTitleTxt (60100) | USPS address validation (`MaxLength = 50`) | | No |
| AssistedSetupDescriptionTxt (60100) | Enter the USPS Consumer Key and Consumer Secret used to validate customer addresses. (`MaxLength = 1024`) | | No |
| RetentionPeriodCodeTok / TwoYearsFormulaTok (60100) | OBCFUSPS-2Y / <-2Y> | | Yes |
Translation files: none (`Translations/` holds no target file; only the regenerated `.g.xlf`). No glossary (Parameters §1.9).

## 8. Upgrade and data migration
Standards Part 9. **No upgrade code is needed.** This is the extension's first version (0.0.0.1 → 1.0.0.0), and no earlier version of it has been installed anywhere, so no existing data must change shape (§9.1). The new Customer field arrives with its default, false, which is the required starting value for existing customers (FR-8). Decided by: Reasoning role draft, for AJ Ansari's sign-off.
| Upgrade codeunit | Trigger (PerCompany / PerDatabase) | Upgrade tag | What it does |
|---|---|---|---|
| none | — | — | — |
Install behaviour is in §4.17 (Retention Policy and Assisted Setup registration per company, idempotent). **For the next version:** add an upgrade codeunit whose `OnUpgradePerCompany` calls `"obcfusps Setup Registration".RegisterAll()`, because install code doesn't run on upgrade. Tags only when data changes, named `OBCFUSPS-<ID>-<Description>-<YYYYMMDD>`.

## 9. Events
Standards Part 10; each Microsoft event verified in the symbol file.
| Direction (published / subscribed) | Event | Object | Why |
|---|---|---|---|
| subscribed | codeunit 2 "Company-Initialize" · `OnCompanyInitialize()` (local IntegrationEvent, verified; namespace `Microsoft.Foundation.Company`) | 60100 "obcfusps Setup Registration" | Registers the log in Retention Policy and the wizard in Assisted Setup for companies created after install |
| (table-extension triggers, not subscriptions) | `OnAfterValidate` on Customer Address, Address 2, City, County, Post Code | 60116 | Address Validated reset (FR-8), §4.14 |
| published | **none** | — | This is a single-tenant PTE with no other app expected to hook in. The provider-replacement need (FRD §5) is met by the transport interface. A later version can add `OnBefore/OnAfterValidateCustomerAddress` on 60113 if a subscriber appears (Standards §10.2, §10.4) |
Not used on purpose: "Guided Experience".`OnRegisterAssistedSetup` and "Reten. Pol. Allowed Tables".`OnRefreshAllowedTables`, both `internal` in System Application 28.5.

## 10. Permission sets
Standards §5.3–§5.4. USE and ADMIN replace the VIEW/EDIT pair (AJ Ansari, OQ-11). ADMIN includes USE. The sets cover only this extension's objects; users also need their normal Business Central permissions, including Customer modify for Accept (FRD §5). Interfaces, enums and extension objects need no entries. The test app has no tables and no permission set.
| Set (≤ 20 chars) | ID | Grants | Batch |
|---|---|---|---|
| OBCFUSPS USPS, USE | 60101 | `tabledata "obcfusps USPS Setup" = R`, `table "obcfusps USPS Setup" = X`, `codeunit "obcfusps USPS Credential Mgt." = X` | B1 |
| | | `tabledata "obcfusps USPS Address Buffer" = RIMD`, `table "obcfusps USPS Address Buffer" = X`, `codeunit "obcfusps USPS API Client" = X`, `codeunit "obcfusps USPS Http Transport" = X` | B2 |
| | | `tabledata "obcfusps USPS Validation Log" = Ri` (read, plus indirect insert through codeunit 60118, which carries `Permissions = tabledata "obcfusps USPS Validation Log" = i`; 60113 carries no Permissions property as built), `table "obcfusps USPS Validation Log" = X`, `page "obcfusps USPS Log Entries" = X` | B3 |
| | | `page "obcfusps USPS Address Compare" = X`, `codeunit "obcfusps Address Validation" = X`, `codeunit "obcfusps Validation Writer" = X` (§13.1) | B4 |
| OBCFUSPS USPS, ADMIN | 60102 | `IncludedPermissionSets = "OBCFUSPS USPS, USE";` `tabledata "obcfusps USPS Setup" = RIMD` | B1 |
| | | `page "obcfusps USPS Setup" = X` | B2 |
| | | `tabledata "obcfusps USPS Validation Log" = RD` (delete for log clean-up; **no M**, so entries can't be edited, FR-5) | B3 |
| | | `page "obcfusps USPS Setup Wizard" = X`, `codeunit "obcfusps Setup Registration" = X` | B5 |

## 11. Special design notes
1. **Singleton:** "obcfusps USPS Setup" holds one record per company. The page inserts it on first open; the Address Validation precondition treats a missing record as "not set up".
2. **High-volume table:** the log gets about one row per manual check, bounded by the USPS hourly quota, so it isn't high volume. Retention Policy keeps it bounded (§4.16).
3. **Naming:** every object starts with `obcfusps` and is ≤ 30 characters. The Customer field carries the prefix in its name, with a clean caption. Page and table 60095/60096 share the name "obcfusps USPS Setup" (different object types; file names differ by type suffix).
4. **(Replaced by §13.2: the reasoning below was wrong; a caller check now guards `SetTransport` and the credential setters.)** ~~Transport injection is public.~~ Another extension could call `SetTransport` on its *own* instance of 60113 or 60114. That affects only that instance (the Customer Card always creates a fresh one with the default transport), and credentials and the token reach any transport only as SecretText, which can't be unwrapped online. `internalsVisibleTo` was rejected because it raises a PTE analyzer warning in Business Central online (Standards §10.3), which would break 0/0.
5. **The test app must live outside the main app's folder tree**, because the AL compiler compiles every `.al` file under the project folder (AJ Ansari, 2026-10-10, Q2). Its IDs (60123–60133) are removed from the main app's `idRanges` (§1).
6. **"Allow HttpClient Requests"** must be on for this extension in every environment (FRD §4.1 b). When it is off, the transport's `Send` returns false and the user sees NotRespondingErr. A dedicated message isn't in the FRD.
7. **Customer security filters** aren't evaluated by `CanModifyCustomers()`. If a security filter blocks the specific customer, `Modify` fails and the whole Accept transaction (customer and log) rolls back.
8. **Comparison dialog buttons:** see §4.9; AJ Ansari chose the StandardDialog behaviour on 2026-10-10 (Q1).
9. **Test runner:** the test app uses only built-in test features (`Subtype = Test`, handlers, `asserterror`), so it has no dependency on Microsoft test libraries. Test 12 (user without customer modify permission) needs a lower-permission user and stays manual (Q5 decided: test 12 stays manual).
10. **Address Validated on Not Found** is reset only for users who can modify customers, the same rule as Confirmed (OQ-21) — decided by AJ Ansari, 2026-10-10 (Q4).

### Decisions taken on the draft (AJ Ansari, 2026-10-10)
| # | Question | Decision |
|---|---|---|
| Q1 | Comparison dialog buttons | StandardDialog kept: OK = Accept, Cancel/Esc/X = Ignore. When Accept is not allowed the dialog shows the reason and OK closes as Ignore. FRD FR-4 and test 12 clarified in FRD v1.1 (ChangeLog 03-2). |
| Q2 | Test app location | Sibling folder `USPSAddressValidator.Tests` with its own app.json and git repository. |
| Q3 | Retention Policy on install | Created with the custom 2-year period, disabled; an administrator enables it. |
| Q4 | Not Found for a user who cannot modify customers | Address Validated left unchanged. |
| Q5 | Test 12 | Manual; no dependency on Microsoft test libraries. |
| Q6 | Timeout bounds | MinValue 1, MaxValue 60, default 10. |

## 12. Object Register
Also maintained standalone as `docs/1-define/ObjectRegister.md`.
| ID | Type | Name | Module | Source table | R / RW | Batch |
|---|---|---|---|---|---|---|
| 60093 | Enum | obcfusps Validation Result (Extensible = false — AJ Ansari: closed, code-driven) | A | — | — | B1 |
| 60094 | Enum | obcfusps USPS Environment (Extensible = false — AJ Ansari: each value maps to a fixed URL) | A | — | — | B1 |
| 60095 | Table | obcfusps USPS Setup | A | (new) | RW | B1 |
| 60096 | Page (Card) | obcfusps USPS Setup | A | 60095 | RW | B2 |
| 60097 | Page (NavigatePage) | obcfusps USPS Setup Wizard | A | — (isolated storage) | RW | B5 |
| 60098 | Codeunit | obcfusps USPS Credential Mgt. | A | — (isolated storage) | RW | B1 |
| 60099 | Codeunit (Install) | obcfusps USPS Install | A | — | W | B5 |
| 60100 | Codeunit | obcfusps Setup Registration — subscribes to Company-Initialize.OnCompanyInitialize | A | Retention Policy Setup 3901, Retention Period 3900 | W | B5 |
| 60101 | PermissionSet | OBCFUSPS USPS, USE | A | — | — | B1 (+B2–B4 lines) |
| 60102 | PermissionSet | OBCFUSPS USPS, ADMIN | A | — | — | B1 (+B2, B3, B5 lines) |
| 60103–60108 | — | buffer A | A | | | |
| 60109 | Table | obcfusps USPS Validation Log | B | (new) | R (insert by code only) | B3 |
| 60110 | Page (List) | obcfusps USPS Log Entries | B | 60109 | R | B3 |
| 60111 | Table (Temporary) | obcfusps USPS Address Buffer | B | (new, temporary) | RW | B2 |
| 60112 | Page (StandardDialog) | obcfusps USPS Address Compare | B | 60111 | R | B4 |
| 60113 | Codeunit | obcfusps Address Validation | B | Customer 18, 60095, 60109 | RW | B4 |
| 60114 | Codeunit | obcfusps USPS API Client | B | 60111 | — | B2 |
| 60115 | Codeunit | obcfusps USPS Http Transport (implements obcfusps USPS Transport) | B | — | — | B2 |
| — | Interface | obcfusps USPS Transport | B | — | — | B2 |
| 60116 | TableExtension | obcfusps Customer (field 60093 "obcfusps Address Validated") | B | Customer 18 | RW | B4 |
| 60117 | PageExtension | obcfusps Customer Card | B | page 21 Customer Card | RW | B4 |
| 60118 | Codeunit | obcfusps Validation Writer (added by §13.1, Sanity Check F1) | B | Customer 18, 60109 | RW | B4 |
| 60119–60122 | — | buffer B (4; tail 60134–60142 is the overflow) | B | | | |
| 60123 | Codeunit (test app) | obcfusps Fake USPS Transport | C | — | — | B6 |
| 60124 | Codeunit (test app) | obcfusps Test Library | C | — | — | B6 |
| 60125 | Codeunit (Test) | obcfusps Validation Tests | C | — | — | B6 |
| 60126 | Codeunit (Test) | obcfusps API Client Tests | C | — | — | B6 |
| 60127 | Codeunit (Test) | obcfusps Addr Validated Tests | C | — | — | B6 |
| 60128–60133 | — | buffer C (test app) | C | | | |
| 60134–60142 | — | tail block (main app) | — | | | |
Events: published none; subscribed `Company-Initialize.OnCompanyInitialize` (60100).

### 12a. Test plan — FRD acceptance tests 1–21
| # | Automated (codeunit · fake setup) or manual |
|---|---|
| 1 | Auto · 60125 · token 200, address 200 equal to customer → Confirmed message (MessageHandler), no dialog, log Confirmed, Accepted = No |
| 2 | Auto · 60125 · address 200 with a different street and a +4; ModalPageHandler → OK → customer has USPS values, flag true, log Suggestion Accepted, Accepted = Yes, both addresses stored. **Bold** checked manually; `ValuesDiffer` unit-tested |
| 3 | Auto · 60125 · two runs, handler → Cancel both times → customer unchanged, two Suggestion Ignored entries |
| 4 | Auto · 60125 · address 404 with error JSON → MessageHandler gets the not-found text; log Not Found with the USPS message |
| 5 | Auto · 60125 · DPV `D` → handler reads the deliveryWarning control text; OK still accepts |
| 6 | Auto · 60125 · lower-case customer values → Confirmed, no dialog (no ModalPageHandler hit) |
| 7 | Auto · 60125 · Country/Region `CA` → `asserterror`, NotUSAddressErr; `Fake.TokenCallCount() = 0` and `AddressCallCount() = 0`; no log |
| 8 | Auto · 60126 · token 401 → CredentialsRejectedErr; log Error, HTTP Status 401 |
| 9 | Auto · 60126 · (a) address 429 → QuotaErr; (b) address no-response → NotRespondingErr; log Error; `AddressCallCount() = 1` (no retry) |
| 10 | Auto · 60126 · one token response with `expires_in` 28800 and two address 200s → `TokenCallCount() = 1` |
| 11 | Manual (sandbox, two time zones) |
| 12 | Manual (user without Customer modify permission) — decided by AJ Ansari, 2026-10-10 (Q5) |
| 13 | Manual (Customer Card, unsaved edit, then action) |
| 14 | Manual (setup card; Test Connection against TEM) |
| 15 | Auto · 60127 · accept on flag = false → true |
| 16 | Auto · 60127 · Confirmed → flag true, address fields unchanged |
| 17 | Auto · 60127 · Cancel from false and from true → unchanged |
| 18 | Auto · 60127 · flag true, `Customer.Validate(City, 'X')` → false; also checks Accept leaves it true |
| 19 | Manual (Customer Card layout, not editable) |
| 20 | Auto · 60127 · new customer → false |
| 21 | Manual (Assisted Setup list, wizard) |
Live USPS: tests 1–3 once against TEM and once against production, manually (FRD §7.2).


# Part D — Sanity Check amendments (TDD 1.0 §13, unchanged text)
## D13. Sanity Check amendments (normative, Step 04, 2026-10-10)
These amendments come from `docs/2-design/SanityCheck.md` (findings F1–F28). **Where this section and an earlier section differ, this section wins.** Decisions by AJ Ansari, 2026-10-10: F1 failed write is logged as Error; F2 caller check; F13 Log list keeps ADMIN-only delete; F14 customer rename may rewrite log rows (accepted). The earlier sections carry a pointer line where they are affected.

### 13.1 Transaction flow and the write phase (F1, F5, F4, F25)
1. **No write transaction is open at a dialog or after the HTTP phase.** `obcfusps USPS API Client`.`ValidateAddress` can write the token cache (`IsolatedStorage`), so the orchestrator calls `Commit()` **immediately after `ValidateAddress` returns**, before outcome handling and before `RunModal`. §4.13's wording "before any write" is replaced by this rule.
2. **New codeunit 60118 "obcfusps Validation Writer"** (module B, ID taken from the module B buffer, which is now 60119–60122; the 25 unallocated IDs overall still exceed the 10 required; AJ to accept at sign-off). It has no `TableNo`. State is passed through instance procedures and the codeunit is run with `if Writer.Run() then`, so a failure is caught without rolling back what was committed before it. `Permissions = tabledata "obcfusps USPS Validation Log" = i;`. Procedures: `Init(CustomerNo: Code[20]; Outcome: Enum "obcfusps Validation Result"; var TempResult: Record "obcfusps USPS Address Buffer" temporary; Accepted: Boolean)` and `OnRun`; **as built (ChangeLog B4-1) it also exposes `WasAddressChanged(): Boolean` (the orchestrator learns the write phase turned an Accept into Suggestion Ignored because the address changed) and `InsertLogEntry(LogCustomerNo; LogResult; var TempResult; LogAccepted)`, the single place a log row is written; the orchestrator calls it for Error rows too.** `OnRun` does, in one transaction, exactly the work §4.13 assigned to its write phase: re-read the customer and run the concurrency check, write the five address values on Accept (direct assignment, then `Modify(true)`), set or reset Address Validated per FR-8, and insert the success log row.
3. **Failure handling.** If `Writer.Run()` returns false, the orchestrator reads `GetLastErrorText()`, inserts a log row with Result = Error, HTTP Status = the USPS status, USPS Message = that text, Accepted = No, calls `Commit()`, and returns the failure to the caller. The customer is unchanged. This covers the Contact sync raising an error, a security filter, or another extension's subscriber failing (FRD FR-7).
4. **Testable core (F4).** Codeunit 60113 gets `procedure TryValidateCustomerAddress(CustomerNo: Code[20]; var Outcome: Enum "obcfusps Validation Result"; var UserMessage: Text): Boolean`. It does everything (preconditions, USPS call, dialog, write phase, logging, commits) and **never raises**: precondition and failure messages come back in `UserMessage` (Outcome blank when nothing was logged) and the return value is false for any precondition failure or Error outcome. `ValidateCustomerAddress` stays the public entry used by the Customer Card; it calls the Try procedure and then shows `UserMessage` with `Message` (informational outcomes) or `Error` (errors), **after** the transaction has ended (this also fixes F25: the message is no longer shown while locks are held). Tests call the Try procedure and assert on Outcome, UserMessage and the log; they never use `asserterror` for these paths.
5. **User text as format string (F17).** Every `Message`/`Error` of composed text uses the Locked passthrough label `ShowTextTok: Label '%1', Locked = true;` so a `%` inside USPS-supplied text is never read as a placeholder.

### 13.2 Caller check on the test-injection and credential procedures (F2, F21)
**As built (ChangeLog B2-1):** the check parses the test app's id with `Evaluate(TestAppId, TestAppIdTok)` and compares Guid to Guid (`CallerModuleInfo.Id <> TestAppId`), because `Format(Guid)` yields braces and upper case. It fails closed if the parse fails. **Buffer persistence contract (§4.12):** `ValidateAddress` saves the one buffer row itself after every outcome (`if not Insert() then Modify()`), so the dialog's `Rec.Copy(Buffer, true)` can read it; the orchestrator (60113) fills the originals with `Init()` and assignments only and never inserts the row.
- Replaces §11 note 4 (its reasoning was wrong: sending a `SecretText` to another endpoint needs no unwrap).
- In `SetTransport` of codeunits 60113 and 60114, and in `SetConsumerKey`, `SetConsumerSecret` and `ClearToken` of codeunit 60098, first run `NavApp.GetCallerModuleInfo(CallerModuleInfo)` and `NavApp.GetCurrentModuleInfo(CurrentModuleInfo)`. Allow the call only when `CallerModuleInfo.Id = CurrentModuleInfo.Id` (this app) or `Format(CallerModuleInfo.Id) = TestAppIdTok`; otherwise `Error(CallerNotAllowedErr)`. `TestAppIdTok: Label 'ebe1c8ca-a413-4f2b-9de7-37d8c1ae4d5a', Locked = true;` — the test app's `app.json` GUID, generated at Step 05 (2026-10-10). Pattern precedent: Base Application "Reten. Pol. Allowed Tables".`AddAllowedTable`.
- New Labels: `CallerNotAllowedErr: Label 'This procedure can only be called by the USPS Address Validator app.';` (AA0074 suffix `Err`).
- `internalsVisibleTo` stays rejected (§11 note 4's second reason stands).

### 13.3 Encryption at rest (F10) — amended in Step 06 (ChangeLog B1-1)
**As built:** `if EncryptionEnabled() then IsolatedStorage.SetEncrypted(Key, Value, DataScope::Company) else IsolatedStorage.Set(Key, Value, DataScope::Company);` with no try and no fallback. The length test below could not be written (`SecretText.Unwrap()` is OnPrem-scoped); a secret over 215 characters errors rather than being stored in clear. The original wording follows.
Consumer Key and Secret are stored as Microsoft stores secrets: `if EncryptionEnabled() and (StrLen(Unwrapped) <= 215) then IsolatedStorage.SetEncrypted(Key, Value, DataScope::Company) else IsolatedStorage.Set(Key, Value, DataScope::Company)`, with the length test in a `[NonDebuggable]` helper. The access token keeps `IsolatedStorage.Set` (a long JWT). §4.11's "Storage" row is amended accordingly.

### 13.4 Address Validated reset (F9)
Every one of the five field triggers in §4.14 (Address, "Address 2", City, County, "Post Code") calls one local procedure `ResetAddressValidatedIfChanged()` that compares **all five** fields against `xRec`; a Post Code validation that rewrites City or County is therefore detected too. The Accept path still skips the reset through the existing suppression mechanism.

### 13.5 Test plan additions (F6)
Automated tests to add (no FRD acceptance-test row exists for them; they are TDD tests):
| # | Where | Scenario |
|---|---|---|
| A1 | 60125 | USPS City longer than 30 characters → dialog shows the reason, OK → customer unchanged, log Suggestion Ignored, Accepted = No |
| A2 | 60125 | Customer address modified inside the ModalPageHandler, then OK → AddressChangedMsg, log Suggestion Ignored, flag unchanged |
| A3 | 60127 | Not Found on a validated customer (user can modify customers) → flag No |
| A4 | 60127 | Error (429) on a validated customer → flag still Yes |
| A5 | 60126 | Cached token rejected (401) on the address call → exactly one token refresh and one retry: `TokenCallCount() = 1` and `AddressCallCount() = 2` |
| A6 | 60125 | Preconditions: setup disabled, address incomplete, State not two letters → the right message from Try, `TokenCallCount() = 0` and `AddressCallCount() = 0`, no log row |
| A7 | 60125 | Write failure path (F1): the fake raises during the write phase (a test subscriber makes `Modify` fail) → log row Result = Error with the failure text, customer unchanged |
**Test hygiene.** `Lib.InitSetup` overwrites the company's setup and the credentials in isolated storage. Therefore: (a) the test codeunits run in a dedicated test company, stated in the Human Unit Test Script, and (b) ~~`InitSetup` first stores the existing key and secret and `CleanUp` restores them~~ — **cannot be built** (the credential getters are `internal` and isolated storage is per app, so the test app cannot read them). **As decided by AJ Ansari, 2026-10-10 (ChangeLog B6-1):** `Lib.InitSetup` refuses to run (`NotTestCompanyErr`) unless `UpperCase(CompanyName())` contains `TEST`; `CleanUp` deletes the test credentials and token; the TEM credentials are re-entered in the test company for manual test 14 and the live checks.

### 13.6 `using` rows (F8)
- Codeunit 60114: `using System.Utilities;` (Uri). Codeunit 60115: none.
- Wizard 60097: remove `System.Environment.Configuration` (the Guided Experience calls live in 60098 and 60100).
- Test objects 60124, 60125, 60127: `using Microsoft.Sales.Customer; using OnlyBCFans.USPSAddress;`.

### 13.7 Page details and small fixes
- **F18:** every display-only page field has a `Caption` and a `ToolTip`; `TestEnvironmentNote` is assigned in `OnOpenPage` (not left empty); where `Style` is used, `StyleExpr = true` is set.
- **F19:** the Environment field on the setup card has `ValuesAllowed = Production, Test;` so the blank value 0 cannot be selected.
- **F20:** rename `MarkAssistedSetupCompleteIfReady` → `MarkSetupCompleteIfReady` and actionref `obcfuspsValidateAddress_Promoted` → `obcfuspsValidateAddr_Promoted` (≤ 30 characters).
- **F12:** the Contact sync is **partly verified**: the code path exists in the shipped source; whether `xRec` differs from `Rec` when `Modify(true)` is called from code is checked in a sandbox at Step 07/08 (FRD §4.1 h). §4.13's "now verified in source" is withdrawn.
- **F13:** the Log list keeps `DeleteAllowed = true` for ADMIN, decided by AJ Ansari, 2026-10-10 (departure from the Standards §2.2 audit-table row, which is written for API pages).
- **F14:** customer rename rewrites `Customer No.` on log rows through the table relation; accepted by AJ Ansari, 2026-10-10 (the log follows the customer and the per-customer log action keeps working).
- **F22:** deleting Country/Region `US` leaves the setup code dangling; harmless to the precondition; no action.
- **F27:** field number 60093 on Customer is reserved in the Object Register, because `Contact.TransferFields(Cust)` copies by field number.
- **F28:** the County/State control on the Customer Card is `Visible = IsCountyVisible`; for a blank Country/Region Code the user may not see State and the precondition falls back to ZIP. Checked in the US sandbox together with FRD OQ-19.

### 13.8 Tasks carried to later steps
- **F11 (before Step 06) — partly done 2026-10-10:** USPS's own `api-examples` Postman collection confirms the token call (`POST https://apis.usps.com/oauth2/v3/token`, JSON body with `client_id`, `client_secret`, `grant_type`) and the address call (`GET https://apis.usps.com/addresses/v3/address` with `streetAddress`, `secondaryAddress`, `city`, `state`; `ZIPCode` and `ZIPPlus4` optional), and the sample token response lists scopes including `addresses`. USPS's README also says an access token needs a valid CRID and MID from the Business Customer Gateway (written for the Labels APIs; to be checked for Addresses at TEM). Still open, checked at TEM in Step 07: whether `state` is mandatory when only a ZIP Code is sent (the FRD precondition stays; a 400 is logged as Error with USPS's text), required parameters, the `expires_in` type. Original wording: check the USPS Addresses 3.0 and OAuth v3 OpenAPI specs for required query parameters (is `state` mandatory?), JSON paths, the token status for bad credentials, the type of `expires_in`, and whether the token endpoint accepts a JSON body. If `state` is required the FRD precondition (Address + ZIP without City/State) changes; that is an FRD change for AJ. Then verify against TEM at Step 07.
- **F23 (Step 11, Deployment.md):** retention deletion needs a job-queue user with direct delete permission on the log (the ADMIN set) and Microsoft's retention-policy permissions; the policy is installed disabled (Q3); include the 72-hour USPS incident-reporting checklist (FRD §7).
- **F26 (Step 11):** bold changed values (test 2) and Esc (test 3) are covered only by manual checks; say so in the Human Unit Test Script.
- **F16 (optional FRD wording):** token 400 maps to the credentials message and an address 401 on a freshly fetched token fails without a refresh; both are inside FR-7's single-refresh rule. No change made.

### 13.9 Not verified (the section earlier parts refer to)
1. USPS Addresses 3.0 contract (external): base URLs, paths, JSON token body vs form encoding, response field names, error body shape, status usage; whether `state` is required (13.8).
2. `HttpClient.Send` returns false rather than raising on timeout and DNS failure.
3. `JsonObject.WriteWithSecretsTo` availability to a Cloud-target extension (fallback: `SecretStrSubstNo` with a JSON template).
4. `IsolatedStorage`: no documented length limit for a SecretText value; whether writes roll back with the database transaction.
5. **Commit and `asserterror` under test isolation**, whether a test runner is available in the SaaS sandbox without Microsoft test libraries, and whether isolated-storage writes made by tests are rolled back (13.1.4 and 13.5 avoid depending on them for the main paths).
6. `User Permissions`.`GetEffectivePermission` for a non-admin user.
7. That the AL compiler includes every `.al` file under a project folder (the basis for the test-app sibling folder).
8. Subscribing to an `internal` integration event from another app is not possible (the design avoids those events).
9. A page over a `TableType = Temporary` table needs no `SourceTableTemporary` property.
10. Whether `RunModal` is refused inside an open write transaction (moot after 13.1.1).
11. Whether `Style` without `StyleExpr` renders (13.7 sets `StyleExpr`).
12. US captions "State" / "ZIP Code" (FRD OQ-19) and the production default of "Allow HttpClient Requests" (FRD OQ-20).
13. `xRec` contents in Customer `OnModify` when called from code (13.7, F12).
Verified from the packages' shipped AL source rather than from symbols alone: Customer `OnModify`, the custom retention period's `'<-2Y>'` sign, `FindOrCreateRetentionPeriod`, Customer Card group and action names.


## Self-sufficiency check (as built)
- [x] Every FRD entity maps to at least one object (Part C §4, Part B); every object in `src/` and the test app is specified in Part B or Part C.
- [x] Every deviation from TDD 1.0 is in Part A with a ChangeLog reference.
- [x] Every ID is inside an allocated range; 25 unallocated.
- [ ] No behaviour was verified against a live tenant: nothing has been installed (07-WAIVER, 09-WAIVER); the external USPS contract is unverified (G16).
- [x] No rule in this document needs knowledge that lives outside it, except the external USPS contract, the unverified items in Part D §13.9, and the items in Part B-13.
