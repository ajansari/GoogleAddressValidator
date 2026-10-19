# Sanity Check and Validation — USPS Address Validator

> **Renumbered in 1.3.0.0:** object and field numbers in this historical document are the pre-1.3 numbers (60093–60192). `docs/1-define/ObjectRegister.md` gives each object's old and new ID.


**Date:** 2026-10-10 · **Reviewer:** Reasoning role, Opus 5.5 · **Resolved by:** Main role (Sonnet 5.5) / AJ Ansari · **Sign-off:** Technical Lead — AJ Ansari, 2026-10-10 (one sign-off with the TDD) (one sign-off on TDD + SanityCheck, Approvers = one person)
**Reviewed:** `docs/2-design/FRD.md` v1.1, `docs/2-design/TDD.md` v0.2 (resolutions applied in FRD v1.2 and TDD v0.3, 2026-10-10), symbol files BC 28.5.54151 W1 (System 28.0.54688.0, System Application 28.5.54151.55108, Base Application 28.5.54151.55594). Re-verified independently through the AL MCP Server (`al_symbolsearch`) and the AL source shipped in the Base Application and System Application packages, read in place without unpacking into the project. Microsoft Learn was not consulted.

## A. Can BC do everything the FRD asks?
| # | FRD requirement | Platform capability relied on | Verified how | Finding | Resolution |
|---|---|---|---|---|---|
| A1 | FR-1, FR-6, FR-7: two HTTPS calls to USPS from a SaaS PTE | HttpClient / HttpRequestMessage / HttpHeaders with SecretText | Base App source: `OAuth20Mgt.Codeunit.al` (namespace System.Security.Authentication) uses `SecretStrSubstNo('Bearer %1', AccessToken)` (l. 340) and `JObject.WriteWithSecretsTo(Secrets, …)` (l. 484); `ImportConsolidationFromAPI.Codeunit.al` calls external APIs | Supported. "Allow HttpClient Requests" is still an environment setting (FRD OQ-20 open; deployment item). | None for design. OQ-20 stays a Step 12 / Deployment item. |
| A2 | FR-6: credentials and token as secrets, company scope | `IsolatedStorage.Set/SetEncrypted(Text, SecretText, DataScope::Company)` | Base App `ICPartner.Table.al` l. 552 `IsolatedStorage.Set(NewSecretKey, ClientSecretText, DataScope::Company)`; `ImportConsolidationFromAPI.Codeunit.al` l. 103–106: `SetEncrypted` when encryption is on and the value is ≤ 215 characters, else `Set` | Supported. The TDD uses `Set` for the key and secret too. Microsoft's pattern encrypts short secrets. | Finding F10: use `SetEncrypted` for Consumer Key and Secret; keep `Set` for the token. |
| A3 | FR-6: wizard listed in Assisted Setup; completed when both values are saved | System App codeunit 1990 "Guided Experience" (System.Environment.Configuration) | Source: `InsertAssistedSetup` 10-parameter overload l. 85 (Title Text[2048], ShortTitle Text[50], Description Text[1024], …, VideoUrl Text[250], VideoCategory, HelpUrl Text[250]); `Exists(Type; ObjectType; ID)` l. 319; `CompleteAssistedSetup(ObjectType; ID)` l. 346; `OnRegisterAssistedSetup` is `internal` l. 448. Enum 1815 "Assisted Setup Group" is Extensible; value `Connect` (10) comes from Base App enumextension 1814 (Microsoft.Utilities). Enum 3710 "Video Category" (System.Media) has value `Uncategorized` | Supported exactly as the TDD specifies. No obsolete markers in the codeunit. | None. |
| A4 | FR-5: log registered with Retention Policy, 2-year custom default | System App codeunits 3905 "Reten. Pol. Allowed Tables", 3902 "Retention Policy Setup"; tables 3900, 3901; enum 3900 (System.DataAdministration) | Source: `AddAllowedTable(TableId; DefaultDateFieldNo): Boolean` l. 45 (checks table ownership through the caller module); `FindOrCreateRetentionPeriod(Code[20]; Enum; DateFormula): Code[20]` l. 136; enum has `Custom` (1) and no 2-year value; "Retention Period Impl." rejects formulas that don't land ≥ 2 days in the past (`<-2Y>` passes). Table 3901 field 4 "Retention Period" `OnValidate` calls `Validate(Enabled, true)`, and field 6 "Apply to all records" sets `Enabled := false` | Supported. The TDD's validate order (Table Id → Apply to all records → Retention Period → Enabled = false last) gives Enabled = false as intended. Apply Retention Policy deletes with the running user's **direct** D. The indirect-permission event `OnApplyRetentionPolicyIndirectPermissionRequired` is `internal`, so the job-queue user needs the ADMIN set. | Note F23: write the job-queue user's permission into Deployment. Keep the TDD's validate order exactly. |
| A5 | FR-4: modal comparison dialog | PageType StandardDialog over a `TableType = Temporary` table | Base App source: `ExportData.Page.al` StandardDialog; `ErrorHandlingParameters.Table.al` uses `TableType = Temporary` | Supported. OK/Cancel can't be disabled (TDD Q1, accepted by AJ). | Finding F5: no open write transaction at `RunModal`. |
| A6 | FR-8, FR-1: table extension on Customer, page extension on Customer Card | Table 18 Customer, page 21 "Customer Card" (Microsoft.Sales.Customer) | Source: `table 18 Customer` (Customer.Table.al l. 67); `page 21 "Customer Card"` (l. 49). Fields 5 Address Text[100], 6 "Address 2" Text[50], 7 City Text[30], 35 "Country/Region Code" Code[10], 91 "Post Code" Code[20], 92 County Text[30] (CaptionClass '5,1,' + Country/Region Code). Card: group "Address & Contact" l. 283 → group AddressDetails l. 286 (Caption 'Address') → field "Post Code" l. 318; group "&Customer" in area(navigation) l. 1110; group "F&unctions" in area(processing) l. 2024; group Category_Process in area(Promoted) l. 2333 | Supported. County sits inside `group(Control10)` with `Visible = IsCountyVisible` (FormatAddress.UseCounty). For a blank Country/Region Code the State field can be hidden on the card. | Note F28. |
| A7 | FR-8: reset Address Validated when a user edits the address | `modify(<field>) { trigger OnAfterValidate() }` in a tableextension | Source: City `OnValidate` → `PostCode.ValidateCity(City, "Post Code", County, "Country/Region Code", …)`; Post Code `OnValidate` → `PostCode.ValidatePostCode(…)`. Both take the other address fields as `var` parameters (PostCode.Table.al l. 131, l. 178) | Supported. Re-entering an unchanged Post Code can still rewrite City and County, and the TDD's per-field `Rec.<Field> <> xRec.<Field>` test then misses that change. | Finding F9. |
| A8 | FR-9 / OQ-12: Accept also updates the linked Contact | Customer `OnModify` → `IsContactUpdateNeeded()` → codeunit 5056 "CustCont-Update".OnModify | Source: Customer.Table.al l. 2597–2607 and l. 3824–3864 (Address, Address 2, City, Post Code and County are all in the list, compared with **xRec**). CustCont-Update l. 41–87: `Contact.Validate("E-Mail", Cust."E-Mail")`, `Contact.TransferFields(Cust)`, `Contact.Modify(true)` | The code path exists. Whether `xRec` differs from `Rec` when `Modify(true)` is called from code after `Get` and direct assignment is runtime behaviour that source can't prove. The TDD's "now verified in source" claims too much. The sync can raise errors (an invalid stored customer e-mail fails `Contact.Validate("E-Mail")`; a user without Contact modify permission) and roll back the whole Accept. | Finding F1 (log loss on rollback). Note F12: sandbox-verify at Step 07/08. |
| A9 | FR-9: Change Log records the Accept | "Change Log Management" | FRD §4.1 i (existence); Change Log reads old values from the database, so direct assignment + `Modify(true)` is recorded | Supported. | None. |
| A10 | §6.1: Tax Area Code limitation | Customer "Tax Area Code" Code[20] | `al_symbolsearch` Customer fields | Field exists; limitation accepted (OQ-13). | None. |
| A11 | FR-4 / OQ-21: "user allowed to modify customers" | System App codeunit 152 "User Permissions" (System.Security.User) `GetEffectivePermission(Option; ObjectId): Record "Expanded Permission" temporary`; table 2000000254 "Expanded Permission" (System.Security.AccessControl) | Source l. 101 and its doc example (identical call shape to TDD §4.13); `al_symbolsearch` fields "Modify Permission" Option; System SymbolReference read in place: Expanded Permission = 2000000254, User = 2000000120, User."User Name" Code[50] | Supported. Accept also needs Contact modify (A8), which the check doesn't cover. | Covered by F1. |
| A12 | Install / new companies: registration | codeunit 2 "Company-Initialize" `OnCompanyInitialize` (Microsoft.Foundation.Company) | Source l. 745–746: `[IntegrationEvent(false, false)] local procedure OnCompanyInitialize()` | Supported (local publishers can be subscribed to). | None. |
| A13 | FR-1.4: address query string | System App codeunit 3060 Uri (System.Utilities) `EscapeDataString(Text): Text` | Source l. 131 | Supported. TDD §4.12 has no `using` row for it. | Finding F8. |
| A14 | FR-6: credentials never visible in the debugger | `[NonDebuggable]` on procedures and page variables; `ExtendedDatatype = Masked` | System App page 9810 "Password Dialog" (System.Security.AccessControl) l. 95–97 | Supported. | None. |
| A15 | FRD §5 / OQ-17: replaceable HTTP layer, fake transport in a separate test app | Public interface implemented in another app; precedent System App "Http Client Handler" / Rest Client | `al_symbolsearch` (System.RestClient); interface in the main app, implemented in the dependent test app | Supported technically. **Security defect:** a public `SetTransport` lets any installed extension inject a transport that receives the token request body (`SecretText` holding client_id and client_secret) and can forward it with `HttpContent.WriteFrom(SecretText)` to its own endpoint. No unwrap is needed, so TDD §11 note 4's reasoning is wrong. Base App's `"Reten. Pol. Allowed Tables"` shows the remedy: `NavApp.GetCallerModuleInfo` (also used in `OnboardingSignal.Codeunit.al` l. 28). | Finding F2 (Blocking). |
| A16 | §7.2: automated tests 1–10, 15–18, 20 in a SaaS sandbox, no Microsoft test libraries | Test codeunits, handlers, `asserterror`, Commit inside code under test | `CommitBehavior` attribute exists (Base App `BankAccReconciliationPost.Codeunit.al` l. 117); test runner availability and test-isolation semantics can't be verified from symbols | **Not verified.** Error-path tests read a log row the codeunit committed just before `Error`. Under test isolation and `asserterror` rollback that row may not survive. The TDD points to a "Not verified" section that does not exist. | Finding F4. |
| A17 | FR-1.3, FR-7: USPS Addresses 3.0 / OAuth contract (required query parameters, JSON paths, status codes, `expires_in` type) | External API | Not verifiable from BC symbols | **Not verified.** If USPS makes `state` mandatory, the FRD precondition "Address + ZIP Code only" sends requests USPS will reject with 400, logged as Error and costing quota. | Note F11: check against the USPS OpenAPI spec before Step 06; TEM check at Step 07. |
| A18 | FR-5: Checked At in each user's time zone | DateTime field | Platform behaviour, not a symbol | Not verifiable from symbols; manual test 11 covers it. | None. |

## B. Does the TDD fully and correctly implement the FRD?
The canonical checklist is in `ocpfFramework/runbookSteps/04.md`; every item gets a row, a finding, and a resolution.
| # | Check | Finding (pass / issue) | Evidence | Resolution | Blocking? |
|---|---|---|---|---|---|
| 1 | Every FRD entity maps to ≥ 1 TDD object | **Pass**, with behavioural gaps | All 22 FRD §6 rows map: setup → 60095/60096; wizard → 60097; log → 60109/60110; comparison → 60111/60112; enums → 60093/60094; Address Validated → 60116/60117; orchestration → 60113; API client → 60114/60115 + interface; install → 60099/60100; USE/ADMIN → 60101/60102; test app → 60123–60127; Customer, Country/Region (setup TableRelation, precondition), Post Code (bypassed by direct assignment), Contact (indirect sync), isolated storage, Retention Policy referenced where used. Gaps are in behaviour, not objects: F1, F3, F6 | F1, F3, F6 | Via F1 |
| 2 | Every TDD object has a valid ID inside an allocated range | **Pass**, with a document issue | 24 IDs allocated (A 60093–60102 = 10, B 60109–60117 = 9, C 60123–60127 = 5); buffers A 6, B 5, C 6, tail 9 = 26 unallocated; no duplicate ID across types; table-extension field 60093 is inside the main app's range; interface takes no ID. Main app `[60093–60122, 60134–60142]` + test app `[60123–60133]` = 60093–60142 with no overlap and no gap. `app.json` still reads 60093–60142 (TDD §1: changed at Step 05). `ProjectParameters.md` §1.2 and §1.10 don't record the split. ObjectRegister repeats its "Events" line (l. 38 and 40) | F7 | No |
| 3 | Every source table number verified against the symbol file | **Pass** | Re-verified: Customer 18 (Customer.Table.al l. 67), Customer Card page 21 (l. 49), Country/Region 9 (CountryRegion.Table.al l. 14), User 2000000120 and Expanded Permission 2000000254 (System symbol reference), Retention Period 3900, Retention Policy Setup 3901, codeunits 3902/3905, Guided Experience 1990, enums 1815/1990/3710/3900, User Permissions 152, Uri 3060, Company-Initialize 2, CustCont-Update 5056 | None | No |
| 4 | Every field complies with Localization and Standards Part 3 | **Pass** | Fields read or written: Customer 5, 6, 7, 35, 91, 92 (W1 range 1–9,999, valid for US); "Country/Region"; Retention Policy Setup 1, 4, 5, 6; User."User Name". No BLOB or FlowFilter fields; no localization-only fields. Lengths match: log/buffer originals Text[100]/[50]/[30]/[30]/Code[20]; setup "US Country/Region Code" Code[10] | None | No |
| 5 | Every obsolete / pending field excluded | **Pass** | `al_symbolsearch` Customer fields with obsoleteState Pending/Removed: 0 results; no `Obsolete` markers on the used fields in source; 0 `Obsolete` occurrences in "Guided Experience", "Retention Policy Setup", "Reten. Pol. Allowed Tables", "User Permissions", Uri; `OnCompanyInitialize` not obsolete | None | No |
| 6 | Every `using` namespace sourced from the symbol file | **Issue** | Verified: Microsoft.Sales.Customer, Microsoft.Foundation.Address, Microsoft.Foundation.Company, System.Security.AccessControl, System.Security.User, System.Environment.Configuration, System.DataAdministration, System.Media, System.Utilities (Uri). Issues: §4.12 (60114/60115) has no `using` row although 60114 uses Uri (System.Utilities); §4.5 wizard lists System.Environment.Configuration but its own code doesn't use Guided Experience (60098 does); test-app objects have no `using` rows (Customer, the main app's objects) | F8 | No |
| 7 | `const()` quoting correct on every filtered page | **Pass / N/A** | No `const()` filters: log page `SourceTableView = sorting("Entry No.") order(descending)`; `RunPageLink = "Customer No." = field("No.")` | None | No |
| 8 | Entity, field, APIPublisher, APIGroup names ≤ 30 and camelCase | **Pass**, with notes | Longest object names: "obcfusps USPS Credential Mgt." 29, "obcfusps USPS Address Compare" 29, "obcfusps Addr Validated Tests" 29, "obcfusps USPS Validation Log" 28, "obcfusps USPS Address Buffer" 28, "obcfusps USPS Http Transport" 28, "obcfusps Fake USPS Transport" 28; field "obcfusps Address Validated" 26; all field names ≤ 22; all control identifiers camelCase and ≤ 30. Procedure `MarkAssistedSetupCompleteIfReady` is 32 and actionref `obcfuspsValidateAddress_Promoted` is 32: both compile (Customer Card has 40-character actionref names; CustCont-Update has 47-character procedure names), but they exceed the ≤ 30 house check this review was asked to apply. APIPublisher/APIGroup N/A | F20 (Note) | No |
| 9 | R / RW designations match Standards §2.2 | **Pass**, with a note | Setup RW (card editable, Insert/DeleteAllowed false); log R (Editable/Insert/Modify false; DeleteAllowed left true on purpose so ADMIN can delete, FR-5). §2.2's audit-table row (written for API pages) lists DeleteAllowed = false; the TDD departs from it but names no decider. Comparison page R; Customer RW only through Accept/Confirmed/Not Found | F13 (Note) | No |
| 10 | Growth buffers planned per module block | **Pass** | A 6 (38 %), B 5 (36 %), C 6 (55 %), tail 9; total 26 ≥ 10 (§5.2); each block ≥ 5 | None | No |
| 11 | Permission sets planned, grants enumerated, names ≤ 20 | **Pass**, with notes | "OBCFUSPS USPS, USE" 18, "OBCFUSPS USPS, ADMIN" 20; captions 28/30; App Code USPS. Every owned table has tabledata: Setup (USE R, ADMIN RIMD), Log (USE Ri + codeunit 60113 `Permissions = … = i`; ADMIN RD, no M), Buffer (USE RIMD). Every executed object granted: USE has 60098, 60113, 60114, 60115, pages 60110, 60112; ADMIN adds pages 60096, 60097 and codeunit 60100. Each grant ships in the batch that introduces its table (B1/B2/B3). No read-only set: departs from §5.3, decided by AJ (OQ-11). Auditors therefore get USE, which can also run checks (accepted). Retention needs a job-queue user with ADMIN (A4). Accept also needs Contact modify through the sync (A8, F1) | F1, F23 | No |
| 12 | Every target language supported by BC, reviewer named, terminology source named | **N/A** | Parameters §1.9: en-US only (Microsoft built-in, source language), reviewer AJ Ansari, terminology Microsoft; source wording "US wording, no translation files" | — | No |
| 13 | Every PRE-02 regional term in the glossary, verified or flagged | **N/A** | No glossary is created under "US wording, no translation files" (Parameters §1.9). US captions "State"/"ZIP Code" are the extension's own labels and captions; the Customer Card's County caption is OQ-19 (open, US sandbox) | — | No |
| 14 | Every API page/query has a group and caption-locking decision with a decider | **N/A** | No API pages or queries (Parameters §1.3, TDD §4) | — | No |
| 15 | Every message/error/confirmation is a Label with Comments on placeholders | **Pass**, with notes | TDD §7: every FR-7 message is present with matching text; placeholder labels carry Comments (ValueTooLongTxt, CouldNotReadErr, NotFoundMsg, TestConnectionFailedErr, BearerTok); tokens Locked; AA0074 suffixes correct; MaxLength on the Assisted Setup labels. `Error(TempBuf."User Message")`, `Message(TempBuf."User Message")` and `Error(ErrorText)` pass composed text containing USPS-supplied content as the format string | F17 (Note) | No |
| 16 | Every entity's deletion behaviour explicitly decided, referencing fields re-checked | **Pass**, with notes | Log: allow; Customer delete leaves entries (FR-5); `"Customer No."` TableRelation with ValidateTableRelation = false. Customer **rename** cascades through that TableRelation and rewrites "Customer No." on log rows, which the TDD doesn't mention. User delete leaves "User ID" (no cascade). Setup: allow, singleton, page DeleteAllowed = false. Setup "US Country/Region Code" → Country/Region: deleting or renaming the code isn't blocked (rename cascades into setup; delete leaves a dangling code the precondition still compares). Buffer: temporary. Customer table extension: the field is removed with the Customer row; no OnDelete code; standard OnDelete untouched. `Contact.TransferFields(Cust)` in CustCont-Update copies by field number, so field 60093 would clash only if another extension adds field 60093 of another type to Contact (none today) | F14, F27 (Notes) | No |

## C. What the object structure will look like when built
```
USPS Address Validator (main app; idRanges 60093–60122 + 60134–60142; namespace OnlyBCFans.USPSAddress)
├── Module A — Setup and Foundation (60093–60108)
│   ├── enum 60093  "obcfusps Validation Result"      (Extensible = false)
│   ├── enum 60094  "obcfusps USPS Environment"       (Extensible = false)
│   ├── table 60095 "obcfusps USPS Setup"             (singleton)
│   ├── page 60096  "obcfusps USPS Setup"             (Card, Test Connection)
│   ├── page 60097  "obcfusps USPS Setup Wizard"      (NavigatePage)
│   ├── codeunit 60098 "obcfusps USPS Credential Mgt." (IsolatedStorage, Company)
│   ├── codeunit 60099 "obcfusps USPS Install"        (Subtype Install)
│   ├── codeunit 60100 "obcfusps Setup Registration"  (Retention + Assisted Setup; Company-Initialize subscriber)
│   ├── permissionset 60101 "OBCFUSPS USPS, USE"
│   ├── permissionset 60102 "OBCFUSPS USPS, ADMIN"    (includes USE)
│   └── 60103–60108 buffer
├── Module B — Validation and USPS API (60109–60122)
│   ├── table 60109 "obcfusps USPS Validation Log"
│   ├── page 60110  "obcfusps USPS Log Entries"       (List, read-only, newest first)
│   ├── table 60111 "obcfusps USPS Address Buffer"    (TableType = Temporary)
│   ├── page 60112  "obcfusps USPS Address Compare"   (StandardDialog)
│   ├── codeunit 60113 "obcfusps Address Validation"  (orchestration)
│   ├── codeunit 60114 "obcfusps USPS API Client"     (only USPS-specific logic)
│   ├── codeunit 60115 "obcfusps USPS Http Transport" (implements interface)
│   ├── interface   "obcfusps USPS Transport"         (no ID)
│   ├── tableextension 60116 "obcfusps Customer"      (field 60093 "obcfusps Address Validated")
│   ├── pageextension 60117 "obcfusps Customer Card"
│   └── 60118–60122 buffer
└── Tail 60134–60142 (reserved)

USPS Address Validator Tests (sibling folder ../USPSAddressValidator.Tests; idRanges 60123–60133; depends on main app)
├── codeunit 60123 "obcfusps Fake USPS Transport"  (SingleInstance, implements interface)
├── codeunit 60124 "obcfusps Test Library"
├── codeunit 60125 "obcfusps Validation Tests"     (Subtype Test)
├── codeunit 60126 "obcfusps API Client Tests"     (Subtype Test)
├── codeunit 60127 "obcfusps Addr Validated Tests" (Subtype Test)
└── 60128–60133 buffer
```

## D. Findings summary
| Severity | Count | Open |
|---|---|---|
| Blocking | 2 (F1, F2) | 0 (resolved, §E) |
| Should fix before BUILD | 8 (F3–F10) | 0 (resolved, §E) |
| Note | 18 (F11–F28) | 0 open; 4 carried as tasks to later steps (F11, F23, F26, F28) |

## E. Findings and resolutions
Resolved by the main role (Sonnet 5.5) on 2026-10-10; "AJ" = AJ Ansari, who decided the items marked *AJ*. TDD references are to v0.3 §13.
| # | Severity | Finding (short) | Resolution | Decided by | Status |
|---|---|---|---|---|---|
| F1 | Blocking | A failed customer write (e.g. Contact sync error) rolls back the log row, so a check that used USPS quota goes unlogged | TDD §13.1: Commit after the HTTP phase; write phase in new codeunit 60118 run with `if Writer.Run()`; on failure insert an Error log row with the failure text and Commit; never-raising `TryValidateCustomerAddress`. FRD FR-7 gets the sentence | *AJ*: log as Error | Resolved |
| F2 | Blocking | Public `SetTransport` lets any extension capture the client_id/client_secret request body | TDD §13.2: `NavApp.GetCallerModuleInfo` check on `SetTransport` (60113, 60114) and on the credential setters (60098); allowed callers = this app and the test app's GUID (fixed at Step 05); §11 note 4 replaced | *AJ*: caller check | Resolved |
| F3 | Should fix | FRD v1.1 contradicted decided Q4 (Not Found), Q5 (test 12) and OQ-8(b) | FRD v1.2: FR-2, FR-8 (Not Found only for users who can modify customers), §7.2 and OQ-17 (test 12 manual), FR-5 and OQ-8 (policy created disabled) | AJ (decided in Step 03) | Resolved |
| F4 | Should fix | Error-path test design unproven; TDD cited a missing "Not verified" section | TDD §13.1.4 (Try procedure, no `asserterror`) and §13.9 (the Not verified section now exists) | Main role | Resolved |
| F5 | Should fix | `RunModal` could run inside an open write transaction | TDD §13.1.1: Commit right after `ValidateAddress` | Main role | Resolved |
| F6 | Should fix | Test-plan gaps (long value, address changed meanwhile, Not Found/Error flag, token refresh, preconditions, write failure) and tests overwrite real credentials | TDD §13.5: tests A1–A7, dedicated test company, save/restore credentials | Main role | Resolved |
| F7 | Should fix | ProjectParameters did not record the ID split | `ProjectParameters.md` §1.2 updated; `app.json` changes at Step 05; duplicate Events line removed from the Object Register | AJ confirms at sign-off | Resolved |
| F8 | Should fix | Missing or unneeded `using` rows | TDD §13.6 | Main role | Resolved |
| F9 | Should fix | Reset misses City/County rewritten by Post Code validation | TDD §13.4: all five fields compared in every trigger | Main role | Resolved |
| F10 | Should fix | Consumer Key and Secret not encrypted at rest | TDD §13.3: `SetEncrypted` when available and ≤ 215 characters | Main role | Resolved |
| F11 | Note | USPS contract unverified (is `state` mandatory?) | TDD §13.8: check the USPS OpenAPI specs before Step 06; TEM at Step 07 | Task, AJ/main role | Carried |
| F12 | Note | Contact sync "verified in source" overstated | TDD §13.7: partly verified, sandbox check at Step 07/08 | Main role | Resolved |
| F13 | Note | Log list DeleteAllowed departs from §2.2 audit row | TDD §13.7: kept for ADMIN, decider recorded | *AJ* | Resolved |
| F14 | Note | Customer rename rewrites log rows | TDD §13.7: accepted | *AJ* | Resolved |
| F15 | Note | Stale references in the TDD | Header and cross-references updated in v0.3 | Main role | Resolved |
| F16 | Note | Token 400 / fresh-token 401 wording vs FR-7 | No change; inside FR-7's single-refresh rule (TDD §13.8) | Main role | Closed |
| F17 | Note | Composed text used as the format string | TDD §13.1.5: Locked passthrough label | Main role | Resolved |
| F18 | Note | Missing ToolTips/Captions, `TestEnvironmentNote` unassigned, `StyleExpr` | TDD §13.7 | Main role | Resolved |
| F19 | Note | Blank Environment selectable | TDD §13.7: `ValuesAllowed` | Main role | Resolved |
| F20 | Note | Two names of 32 characters | TDD §13.7: renamed | Main role | Resolved |
| F21 | Note | Public credential setters | Covered by F2's caller check | Main role | Resolved |
| F22 | Note | Dangling setup country code | No action | Main role | Closed |
| F23 | Note | Retention and assisted-setup deployment notes | TDD §13.8: into `Deployment.md` at Step 11 | Task | Carried |
| F24 | Note | Version skew between step file and core runbook | Not a project defect: the reviewing agent held the old `CLAUDE.md` from session start; the file on disk was already updated (ChangeLog UPD-1, UPD-2) | Main role | Closed |
| F25 | Note | Message shown while locks are held | TDD §13.1.4: message shown after the transaction ends | Main role | Resolved |
| F26 | Note | Bold and Esc only manually testable | TDD §13.8: stated in the Human Unit Test Script at Step 11 | Task | Carried |
| F27 | Note | `TransferFields` field-number clash risk | Field 60093 reserved in the Object Register | Main role | Resolved |
| F28 | Note | State control hidden for a blank country | TDD §13.7: checked in the US sandbox with OQ-19 | Task | Carried |

Not verified by this review (external or runtime behaviour): see TDD §13.9.

## Before calling this step done
- [x] Every row in B has a finding and, where not a pass, a resolution named. *(The resolutions are written into the TDD v0.3 and FRD v1.2, §E.)*
- [x] 0 blocking issues open. *(F1 and F2 resolved, §E.)*
- [x] Every change made here is in `docs/0-project/ChangeLog.md` with who decided (Issue 04-1).

---

## CR-1 delta (remediation 07a, 2026-10-16)
TDD §14 2.16 asked for a delta review of the CR-1 change. It was covered by the Step 08 Gap-Fit on the Google build (Reasoning role, Opus 5.5; `docs/4-prove/GapAnalysis.md`, row GA-14) and recorded here by the Main role, as decided by AJ Ansari on 2026-10-16. Each item below was checked against the code (0.0.0.5) and, where it needed a fix, against 0.0.0.6.
| # | Check | Result |
|---|---|---|
| D1 | §13.1 flow: no write transaction open at a dialog or after the HTTP phase; Commit after the provider call | Pass (`obcfgavAddressValidation.Codeunit.al`, Commit after `ValidateAddress`; no token cache to write) |
| D2 | Caller check read inside each guarded public procedure | Pass for `SetApiKey`, `SetTransport`, `SetProvider`; **gap GA-02** (`ValidateAddress`, `TestConnection` of the Address Service) fixed in 0.0.0.6 |
| D3 | One API key only; no OAuth token, secret or environment left | Pass |
| D4 | Key only as SecretText, in a header, never in a URL, log, message or label; never unwrapped | Pass (`obcfgavGoogleAddressClient.Codeunit.al`, `[NonDebuggable]` BuildRequest) |
| D5 | Q1 log storage: suggested values only for Suggestion Accepted and Confirmed | Pass (Writer, tests assert blank for Ignored, Not Found, Error) |
| D6 | Attribution line "Suggestion from Google Maps" shown | Pass (`obcfgavAddressCompare.Page.al`, `TestAttributionShown`) |
| D7 | No artificial or made-up US addresses in any live path (Google terms) | Pass: the fake transport has no live path; live spike uses real addresses only |
| D8 | Provider enum `Extensible = false` with blank value 0 | Pass |
| D9 | Test list of 2.14 present; tests untouched by internal members | Pass (54 tests, never run: GA-23) |
| D10 | Test Connection billing (free invalid-request probe) | Not verified: spike item (TDD 14.y) |
| D11 | Writer access | **Gap GA-01**, fixed in 0.0.0.6 (`Access = Internal`) |
Open and carried: GA-10 (HTTP phase may raise), GA-12 (privacy link and platform consent text), GA-23 to GA-26 (sandbox round, spike, prior installs).


---

## SC-1 Sanity Check (1.1.0.0, 2026-10-17)
**Reviewer:** Reasoning role, Opus 5.5 (report first line checked against §1.7). **Resolved by:** main role with AJ Ansari's decisions in the options box. **Reviewed:** `docs/2-design/FRD.md` Appendix C and `docs/2-design/TDD.md` §15 as signed off on 2026-10-17, against `requirements/scope-additions-2026-10-17-more-master-data-requirements.md`, ChangeLog SC-1 to SC-1b, PostDevTDD, the as-built `src/` and the test app. The reviewer re-verified the draft against the Base Application 28.5 symbols and shipped source, and compiled a throwaway probe app (AL 18.1) for the AL claims: 60093 repeated across seven table extensions, `addlast(Processing/Promoted/Navigation)` on pages with no such area, and subscribers to every cited event. A negative control failed as it should.

**Verdict: 2 blocking, 13 should-fix, 8 notes. All resolved in the documents (below); runtime and US-localization items are listed in TDD 15.21.**

### Checks that passed
- All 15 tables, namespaces, primary keys, the six address fields' numbers and lengths (100/50/30/30/20/10), pages, field anchors, validate/promote/log anchors, codeunits 5055–5058, 5200 and 9999, tables 5054 and 5079, and every cited event and signature.
- Scope: the 15 sources match the requirement exactly; nothing touches transactions, documents, Job, Job Task, Service Item, Work/Machine Center, Union, templates or Standard Address.
- Schema safety for the installed 1.0.0.0: additive only (log fields 24–28, one key, 15 table extensions, one trigger-only change); nothing renamed, retyped, removed or re-keyed; Schema Sync Mode Add.
- Caller check, telemetry and privacy rules (no names in the log); the 61 existing tests are expected to pass unchanged.

### Findings and resolutions
| # | Severity | Finding | Resolution |
|---|---|---|---|
| F-SC1-01 | Blocking | OQ-37 (Privacy Blocked) was decided but not designed | **Resolved.** AJ Ansari: refuse for the record and for child sources of a blocked parent. FR-17, FR-7 row, TDD 15.5 `IsPrivacyBlocked`, 15.6 step 4a, label `PrivacyBlockedErr`, tests 40 |
| F-SC1-02 | Blocking | TDD §15 pointed to the unsigned draft report for the field map, anchors, namespaces and the `const()` literals | **Resolved.** Verified reference table copied into TDD 15.22; draft finding numbers replaced by words; OQ-34..49 table added to FRD §9 |
| F-SC1-03 | Should fix | Flag-only propagation ran the full standard partner→Contact update inside the write | **Resolved.** AJ Ansari: separate step after commit (60139 `OnRun`, called from 60113 in B4); a failure leaves the linked flag unchanged. FR-12.4, 15.6, 15.13, test 41 |
| F-SC1-04 | Should fix | A commit and a modal duplicate-contact form can run inside the write phase | **Resolved.** AJ Ansari: suppress while we write. New codeunit 60120 Write Guard (manual subscriber on `OnBeforeLaunchDuplicateForm`), bound by 60118; FR-9, 15.13, test 42 (manual) |
| F-SC1-05 | Should fix | Employee → Resource left a false Yes | **Resolved.** AJ Ansari: propagate. Subscriber g on `OnAfterCalculateResourceUpdateNeeded`, `HumanResToRes` in the linked update and in subscriber e; FR-12.4, tests 43 |
| F-SC1-06 | Should fix | `app.json` was in B4 though B1 needs the new `idRanges` and version; 60101 edited in two batches | **Resolved.** `app.json` moves to B1. 60101 and 60113 are edited in B1 and B4: recorded exception, safe in one-at-a-time mode (AJ Ansari) |
| F-SC1-07 | Should fix | ProjectParameters §1.2, Object Register and effort estimates not updated | **Parameters and Register done below; effort addenda owed before Step 05** |
| F-SC1-08 | Should fix | Growth buffers below Standards §5.2; wrong spare arithmetic | **Resolved.** AJ Ansari: re-block. Engine in tail 60134–60139, sources 60143–60192 with 5 spare each; D (3) and B (2) are a recorded, pooled deviation (31 spare in the main app) |
| F-SC1-09 | Should fix | Conditional and stale text after the decisions | **Resolved.** "only if OQ-…" text removed; alternative numbering removed; status lines updated |
| F-SC1-10 | Should fix | Customer behaviour changes stated in several places that disagreed | **Resolved.** One list: FR-18 and TDD 15.23; 61 tests expected unchanged |
| F-SC1-11 | Should fix | Upgrade codeunits relied on the installer's rights | **Resolved.** `Permissions` property on 60137 and 60138 (TDD 15.14) |
| F-SC1-12 | Should fix | No `using` rows for the upgrade/sync codeunits and page extensions | **Resolved.** 15.13, 15.14 and 15.22 |
| F-SC1-13 | Should fix | Test plan gaps; ambiguous "x16"; test names over 30 characters; cleanup would leak contacts | **Resolved.** Tests 40–45 added; "16" defined; names shortened (AJ Ansari); CleanUp deletes the linked Contacts (15.18) |
| F-SC1-14 | Should fix | FR-12.2 contradicted FR-16.4 | **Resolved.** FR-12.2 reworded |
| F-SC1-15 | Should fix | Anchors verified on W1 symbols only; target is US | **Recorded** in TDD 15.21 item 5 and FRD §4.1 x; checked at the first US sandbox install of B2/B3 |
| N-SC1-01..08 | Note | Customer `SetTable` path has a Microsoft precedent; rename leaves the old key in the description; caption language is the checking user's; `WritePermission` is conservative; ToolTips; upgrade-tag publisher is `internal`; tenant-wide ID overlap unverifiable; runtime items | **Accepted.** ToolTips now generic text (15.12); tag deviation decided by AJ Ansari (15.14); the rest in 15.21 |

### Decisions taken (AJ Ansari, options box, 2026-10-17)
OQ-37 scope: record plus children. Linked update: separate step after commit. Duplicate form: suppress. Employee→Resource: propagate. IDs: re-block. 60101: recorded exception. Test names: shorten. Upgrade tags: explicit, deviation recorded.

### Before calling this step done
- [x] Every finding has a resolution named.
- [x] 0 blocking issues open (F-SC1-01 and F-SC1-02 resolved).
- [ ] Human and AI Effort Estimate addenda (F-SC1-07), owed before the Build Plan.
- [x] Changes recorded in `docs/0-project/ChangeLog.md` (Issue SC-1c).
