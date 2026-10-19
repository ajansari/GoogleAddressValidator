# Technical Design Document — USPS Address Validator

> **Renumbered in 1.3.0.0:** object and field numbers in this historical document are the pre-1.3 numbers (60093–60192). `docs/1-define/ObjectRegister.md` gives each object's old and new ID.


**Version:** 1.0 (signed off 2026-10-10) with §13 Sanity Check amendments, **and §14 Change Request CR-1, signed off by AJ Ansari 2026-10-16 (Technical Lead), including 2.17 Naming.** This file is kept as the historical design record. The **as-built** specification of the Google build is `docs/4-prove/PostDevTDD.md`; the USPS build is `docs/4-prove/PostDevTDD.USPSbuild-0.0.0.4.md`. Corrections to this text recorded at Step 10: §14 2.14 keeps the name of 60126 but 2.17 renames it "Provider Tests" (2.17 wins); 2.17 says test app 0.0.0.4 (built as 0.0.0.5, then 0.0.0.7); the "§4 Naming decision" referred to in the §14 intro is 2.17; 2.17 caption sentence is superseded by AJ Ansari's decision of 2026-10-16 (neutral captions: setup page "Address Validation Setup"); 2.4 gains the caller check on `ValidateAddress` and `TestConnection` (08-3); 2.5 reads only `error.message` and the ErrorInfo `reason` (09-3); 2.11 gains `TestConnectionFailedNoMessageErr` (09-3); §13.1.4 and 2.10: the orchestrator entry procedures carry a caller check, so a foreign caller gets `CallerNotAllowedErr` (09-3).
**Built from:** `docs/2-design/FRD.md` v1.2, `docs/1-define/ProjectParameters.md` (confirmed 2026-10-10), symbol files BC 28.5.54151 W1 in `.alpackages/` (System 28.0.54688.0, System Application 28.5.54151.55108, Base Application 28.5.54151.55594), read through the AL MCP Server and from the packages' own symbol reference and shipped AL source.
**Self-sufficiency:** a developer or agent who has never seen this project must be able to produce every object from this document alone. Cite the FRD; do not restate it.

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

## 13. Sanity Check amendments (normative, Step 04, 2026-10-10)
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

## Self-sufficiency check
- [x] Every FRD entity maps to at least one object in §4 (FRD §6: setup → 60095/60096; wizard → 60097; log → 60109/60110; comparison → 60111/60112; enums → 60093/60094; Address Validated → 60116/60117; orchestration → 60113; API client → 60114 + 60115 + interface; install → 60099/60100; permission sets → 60101/60102; test app → 60123–60127; standard Customer, Country/Region, Post Code, Contact, isolated storage and Retention Policy are referenced where used).
- [x] Every ID is inside an allocated range with its buffer intact (26 unallocated; each module ≥ 20 %).
- [x] Every source table number and `using` namespace comes from the symbol file (Customer 18, Country/Region 9, User 2000000120, Expanded Permission 2000000254, Retention Period 3900, Retention Policy Setup 3901, Guided Experience 1990, Company-Initialize 2, Uri 3060, User Permissions 152).
- [x] Every field decision (include / exclude / rename / FlowField) is written, not defaulted.
- [x] No new `Option` anywhere; every enum has its `Extensible` answer and reason recorded, and the value is written explicitly in the object (Standards §1.9).
- [x] Every deletion behaviour and every caption-locking decision names who decided (caption locking N/A).
- [x] No rule in this document needs knowledge that lives outside it, except the external USPS contract and the items flagged as not verified (verified against TEM at Step 07). Design questions Q1–Q6 were decided by AJ Ansari on 2026-10-10 (§11).

---

## 14. Change Request CR-1 — amendments for version 2.0 (normative, signed off by AJ Ansari 2026-10-16)
**Where this section and an earlier section differ, this section wins** (including §13). Drafted by the Reasoning role (Opus 5.5) from FRD §10. Decisions Q1–Q11: see FRD §10.

Header: Version 2.0 (CR-1), built from FRD v2.0. §13 keeps its role. **A new §14 "CR-1 amendments" wins over the earlier sections it names.** Object names below use neutral names for objects whose content changed. App-level names (prefix, namespace, the "USPS" in the setup/log/wizard/install object names, the permission sets) follow the §4 Naming decision.

### 2.1 Interfaces
```al
interface "obcfusps Http Transport"          // replaces "obcfusps USPS Transport"
{
    /// Sends Request with TimeoutMs. false = no HTTP response (timeout, DNS, blocked); HttpStatus = 0 then.
    procedure Send(var Request: HttpRequestMessage; TimeoutMs: Integer; var HttpStatus: Integer; var ResponseBody: Text): Boolean;
}

interface "obcfusps Address Provider"
{
    procedure ValidateAddress(var TempAddressBuffer: Record "obcfusps Address Buffer" temporary; Transport: Interface "obcfusps Http Transport"; TimeoutMs: Integer): Boolean;
    procedure TestConnection(Transport: Interface "obcfusps Http Transport"; TimeoutMs: Integer; var ErrorText: Text): Boolean;
    procedure HasCredentials(): Boolean;
    procedure DisplayName(): Text;           // 'Google Maps' (Locked; attribution, G13)
}
```
**Why one generic `Send` and not one method per call:**
- The provider builds the whole request: URL, headers including the SecretText key, and body.
- The transport only sends it, so every future provider reuses the same transport and the same fake.
- The fake can read the request URI and body, so test 10 can assert "no key in the URL, no customer name in the body".

The secret stays protected: it travels inside the `HttpRequestMessage` as a SecretText header and cannot be unwrapped online.

### 2.2 Enum 60094 "obcfusps Address Provider" (reuses the ID of the removed "obcfusps USPS Environment")
- Values `0 " "`, `1 Google` (Caption 'Google Maps').
- **`Extensible = false`**, because each value needs a provider codeunit in this app (Standards §1.9, closed code-driven set; AJ to confirm).
- Dispatch is a `case` in the Address Service, not enum `implements`. An implementing enum would need an implementation for the blank value 0, which Standards §1.9 requires on a table-field enum.

### 2.3 Buffer table 60111: renamed "obcfusps Address Buffer" (Caption 'Address Buffer'), still `TableType = Temporary`
| No. | Field | Type | Change |
|---|---|---|---|
| 1–7 | Primary Key, Customer No., Original × 5 | unchanged | — |
| 8–12 | "Suggested Address", "Suggested Address 2", "Suggested City", "Suggested State", "Suggested ZIP Code" | Text[250] | renamed from "USPS …" |
| 13 | "DPV Confirmation" | Code[10] | kept (`uspsData.dpvConfirmation`) |
| 14 | Vacant | Boolean | source becomes `uspsData.dpvVacant = 'Y'` |
| 15 | Business | Boolean | source becomes `metadata.business` |
| 16 | "Validation Granularity" | Text[30] | replaces Match Codes |
| 17 | "Next Action" | Text[30] | replaces Correction Codes (possibleNextAction) |
| 18 | "Provider Message" | Text[2048] | renamed from "USPS Message" |
| 19–21 | HTTP Status, Not Found, User Message | unchanged | — |
| 22 | Provider | Enum "obcfusps Address Provider" | replaces Environment |
| 23 | "Address Complete" | Boolean | new |
| 24 | "Has Replaced" | Boolean | new |
| 25 | "Has Inferred" | Boolean | new |
| 26 | "Has Spell Corrected" | Boolean | new |
| 27 | "Has Unconfirmed" | Boolean | new |
| 28 | "PO Box" | Boolean | new |
| 29 | "Missing Components" | Text[250] | new; `missingComponentTypes` joined with ", " |

Renumbering is free because nothing is installed (TDD §8).

### 2.4 Codeunit 60114: becomes "obcfusps Address Service" (provider-neutral facade, `Access = Public`)
- Holds `Transport`, `TransportSet`, `Provider: Interface "obcfusps Address Provider"`, `ProviderSet`.
- `procedure SetTransport(NewTransport: Interface "obcfusps Http Transport")` and `procedure SetProvider(NewProvider: Interface "obcfusps Address Provider")`. Both keep the §13.2 caller check, unchanged; SetProvider is the new test seam.
- `procedure ValidateAddress(var TempAddressBuffer…): Boolean`:
  1. `ClearResult`.
  2. If `Setup.Get` fails or Provider is blank: fail with SetupIncompleteErr.
  3. Resolve the provider: the injected one, else `case Setup.Provider of Google: GoogleClient`. Blank or unknown: SetupIncompleteErr.
  4. If `not Provider.HasCredentials()`: MissingApiKeyErr.
  5. Set `Buffer.Provider`.
  6. Call `Provider.ValidateAddress(Buffer, GetTransport(), Setup."Timeout (Seconds)" * 1000)`.
  7. `SaveBuffer` (the §13.2 persistence contract is kept).
- `procedure TestConnection(var ErrorText: Text): Boolean` delegates the same way.
- `procedure ProviderDisplayName(): Text`.
- `GetTransport()` falls back to codeunit 60115.

### 2.5 Codeunit 60119 "obcfusps Google Address Client" (new; `implements "obcfusps Address Provider"`; `Access = Internal`)
The only object with Google-specific logic.

**Endpoint (Locked):** `EndpointTok = 'https://addressvalidation.googleapis.com/v1:validateAddress'`.

**Request** (`[NonDebuggable]` where the key is handled):
```al
Request.Method(PostTok); Request.SetRequestUri(EndpointTok);
Request.GetHeaders(Headers); Headers.Add(ApiKeyHeaderTok, CredentialMgt.GetApiKey());   // 'X-Goog-Api-Key', SecretText (L1, G3)
Content.WriteFrom(BodyText); Content.GetHeaders(CH); CH.Remove('Content-Type'); CH.Add('Content-Type','application/json');
```
- **Fallback, only if the spike shows the header is refused:** `Request.SetSecretRequestUri(SecretStrSubstNo(EndpointWithKeyTok, ApiKey))` with `'…:validateAddress?key=%1'`. The URL then holds the key as SecretText and is never logged.
- **Body** is built with `JsonObject`:
  - `address`:
    - `regionCode` 'US'
    - `addressLines`: [Original Address, plus Original Address 2 if not blank]
    - `locality` (if not blank)
    - `administrativeArea` (upper-cased, if not blank)
    - `postalCode` (if not blank)
  - `enableUspsCass`: true (Q3)
  - No name or number; nothing else.

**Response** (by name, missing = '' / false / empty):
| JSON path | Buffer field |
|---|---|
| `result.verdict.validationGranularity` | Validation Granularity |
| `result.verdict.possibleNextAction` | Next Action |
| `result.verdict.addressComplete` / `hasReplacedComponents` / `hasInferredComponents` / `hasSpellCorrectedComponents` / `hasUnconfirmedComponents` | Address Complete / Has … |
| `result.address.missingComponentTypes[]` | Missing Components |
| **Suggested values, source A (Q2 recommended):** `result.uspsData.standardizedAddress` when `firstAddressLine` is non-blank: `firstAddressLine` → Address, `secondAddressLine` → Address 2, `city`, `state`, `zipCode` + '-' + `zipCodeExtension` (when non-blank) | Suggested × 5 |
| **Source B (fallback):** `result.address.postalAddress`: `addressLines[0]` → Address, `addressLines[1]` → Address 2, `locality`, `administrativeArea`, `postalCode` (a 9-digit value without a dash gets formatted `12345-6789`) | Suggested × 5 |
| `result.uspsData.dpvConfirmation`, `dpvVacant`, `errorMessage` | DPV Confirmation, Vacant, Provider Message (appended) |
| `result.metadata.business`, `poBox` | Business, PO Box |

**Outcome logic:**
- HTTP 200, JSON parses, `result.verdict` present:
  - Granularity is PREMISE or SUB_PREMISE and suggested Address/City/State/ZIP are non-blank: return true.
  - Granularity is PREMISE or SUB_PREMISE but no address can be read: UnexpectedResponseErr.
  - Any other granularity: `"Not Found" := true`; `User Message := StrSubstNo(NotValidatedMsg, Reason)`, where Reason = `StrSubstNo(MissingPartsTxt, Missing Components)` when there are missing components, else '' (Q-dependent wording). Provider Message := 'validationGranularity=…; possibleNextAction=…; missing=…'. Return false.
- HTTP 200 without `result.verdict`, or invalid JSON: UnexpectedResponseErr.
- Any other status: read `error.code`, `error.status`, `error.message` and the first `error.details[]` whose `@type` ends with `google.rpc.ErrorInfo` → `reason`. Then apply this table:

| HTTP | status / reason | User Message label |
|---|---|---|
| (no response) | — | NotRespondingErr, status 0 |
| 400 | reason API_KEY_INVALID | ApiKeyRejectedErr |
| 400 | other | `StrSubstNo(CouldNotReadErr, message)` |
| 401 | any | ApiKeyRejectedErr |
| 403 | SERVICE_DISABLED | ApiDisabledErr |
| 403 | BILLING_DISABLED | BillingDisabledErr |
| 403 | reason starting `API_KEY_` and ending `_BLOCKED` | ApiKeyRestrictedErr |
| 403 | other | `StrSubstNo(AccessDeniedErr, message)` |
| 429 | any | QuotaErr |
| 500–599 | any | NotRespondingErr |
| other | — | UnexpectedResponseErr |

Provider Message = Google `error.message`; it never contains the key when the header is used (spike item). No retry anywhere.

**TestConnection:**
- Sends body `{"address":{"regionCode":"US","addressLines":[]}}`.
- Returns true on 400 whose reason is not `API_KEY_INVALID`, and on 200.
- Otherwise ErrorText := `StrSubstNo(TestConnectionFailedErr, <label from the table>, message)`.
- Never logs.
- If the spike disproves the free probe, switch to one fixed real address (Q7).

**Labels:** §2.11. `HasCredentials` = `CredentialMgt.HasApiKey()`. `DisplayName` = `GoogleMapsTok` ('Google Maps', Locked).

### 2.6 Codeunit 60115: renamed "obcfusps Http Transport Impl." (`implements "obcfusps Http Transport"`, `Access = Public`)
```al
[NonDebuggable] procedure Send(var Request: HttpRequestMessage; TimeoutMs: Integer; var HttpStatus: Integer; var ResponseBody: Text): Boolean
begin HttpStatus := 0; ResponseBody := ''; Client.Timeout(TimeoutMs);
      if not Client.Send(Request, Response) then exit(false);
      HttpStatus := Response.HttpStatusCode(); Response.Content().ReadAs(ResponseBody); exit(true); end;
```
All USPS tokens are removed (Bearer, GET, Accept).

### 2.7 Codeunit 60098 Credential Mgt.
| Keep / change / remove | Procedures |
|---|---|
| Keep, renamed | `procedure SetApiKey(NewValue: SecretText)`: CheckCaller (unchanged), StoreCredential (unchanged §13.3 rule), `MarkSetupCompleteIfReady()` |
| New | `procedure HasApiKey(): Boolean`; `internal procedure GetApiKey(): SecretText` |
| Removed | `SetConsumerKey`/`Secret`, `HasConsumerKey`/`Secret`, `HasCredentials`, `GetConsumerKey`/`Secret`, `GetCachedToken`, `SetCachedToken`, `ClearToken`, `DeleteToken` |

- Storage key: `ApiKeyStorageTok = 'OBCFUSPS-GoogleApiKey'` (Locked). The four old keys are removed.
- "Complete" means HasApiKey.
- A later provider with two secrets (Smarty: auth-id plus auth-token) adds its own named keys here or in its codeunit. Not built now.

### 2.8 Setup table 60095, setup card 60096, wizard 60097
- **Table:** field 3 becomes `Provider: Enum "obcfusps Address Provider"`, `InitValue = Google`, no OnValidate (no token). Caption 'Address Validation Setup'. Fields 2, 4 and 5 unchanged.
- **Card:**
  - Caption 'Address Validation Setup'.
  - General: Enabled, Provider (`Editable = false`, Q8), US Country/Region Code, Timeout. TestEnvironmentNote is removed.
  - Group `Credentials`, Caption 'Google Maps': `field(apiKey; ApiKeyText)` (Masked, `[NonDebuggable]` variable; the MaskedPlaceholderTok pattern is unchanged), then `field(keyGuidance; KeyGuidance)` (read-only note, KeyGuidanceTxt).
  - Test Connection calls `AddressService.TestConnection`; the tooltip changes.
  - Assisted Setup action unchanged.
- **Wizard:**
  - Step 1 has one field, `apiKey`.
  - `NextEnabled := (Step = 0) or ((Step = 1) and (ApiKeyText <> ''))`.
  - `FinishWizard`: `CredentialMgt.SetApiKey(ApiKeyText)`.
  - Captions 'Set Up Address Validation' and group 'Google Maps API Key'.

### 2.9 Install 60099 and Registration 60100
- Install: unchanged.
- Registration: logic unchanged. The three assisted-setup labels change (§2.11). The retention period follows Q1 (if Q1 = c, the period may change; no code change otherwise).

### 2.10 Log table 60109, list page 60110, orchestrator 60113, Writer 60118, compare page 60112, Customer extensions
- **Log 60109**, same field numbers where meaning is kept:
  - Fields 12–16 renamed "Suggested …" (Captions 'Suggested Address', …).
  - 17 DPV kept.
  - **18 "Validation Granularity" Text[30], 19 "Next Action" Text[30]** replace Match/Correction Codes.
  - 20 renamed "Provider Message".
  - 21 HTTP Status.
  - **22 Provider** (enum) replaces Environment.
  - **23 "Address Complete"** Boolean.
  - Caption 'Address Validation Log'. Data classification unchanged.
  - **If Q1 = (a)**, Writer leaves fields 12–16 blank unless Result = Suggestion Accepted or Confirmed.
- **Log page 60110:** columns and tooltips follow the table. 'USPS' becomes 'the address validation service' or 'Google Maps' in the tooltips (Provider column). Caption 'Address Validation Log'.
- **Orchestrator 60113:**
  - `ApiClient` becomes `AddressService: Codeunit "obcfusps Address Service"`.
  - `SetTransport` parameter type becomes `Interface "obcfusps Http Transport"`.
  - **New** `procedure SetProvider(NewProvider: Interface "obcfusps Address Provider")` (caller check), passed through.
  - CheckPreconditions condition 1: `Enabled and (Provider <> " ") and CredentialMgt.HasApiKey()`.
  - `AnyValueDiffers`: the Street compare is `ValuesDiffer(Addr + ' ' + Addr2, SugAddr + ' ' + SugAddr2)`, plus City, State, ZIP (Q5).
  - `Normalize`: UpperCase, DelChr of '.' and ',', collapse double spaces, trim.
  - Confirmed: `UserMessage := StrSubstNo(ConfirmedMsg, AddressService.ProviderDisplayName())`, and the delivery note is appended (Q6).
  - Labels per §2.11.
  - `HandleUSPSFailure` is renamed `HandleProviderFailure`.
  - Transaction flow and §13.1 are unchanged. The `Commit()` after ValidateAddress stays, harmless now that no token is written.
- **Writer 60118:** `InsertLogEntry` maps the renamed and new fields; `Provider` replaces Environment. Q1 logic if (a). Flow unchanged.
- **Compare page 60112:**
  - Caption 'Suggested Address'.
  - Right group Caption 'Suggested'.
  - **New** `field(attribution; AttributionText)` (ShowCaption = false) = `StrSubstNo(AttributionTxt, ProviderName)`. `SetData` gets a 4th parameter, `ProviderName: Text`.
  - `DeliveryWarning`: D or `Next Action` = CONFIRM_ADD_SUBPREMISES → missing; S → unconfirmed; N → not deliverable.
  - `DeliveryNotes`: Has Replaced, Has Inferred, Has Spell Corrected, Has Unconfirmed, Vacant, Business, PO Box, then Provider Message when Not Found is false.
- **Table extension 60116:** unchanged.
- **Page extension 60117:**
  - Action caption 'Validate Address'.
  - ToolTip: 'Check this customer''s address with the address validation service (Google Maps) and accept or ignore the suggested address.'
  - Log action 'Address Validation Log'.
  - Field ToolTip: 'Specifies whether the current address was confirmed by, or accepted from, the address validation service. It is set by Validate Address and cleared when the address is edited.'

### 2.11 Labels (complete delta)
**Removed:**
- 60114: ProdBaseUrlTok, TemBaseUrlTok, TokenPathTok, AddressPathTok, all OAuth and USPS JSON tokens, EnvironmentMissingErr.
- 60115: BearerTok, GetTok, AcceptTok, AuthorizationTok.
- 60098: Consumer/AccessToken/TokenValidUntil storage tokens.
- 60096: TestEnvironmentNoteTxt.
- 60114: CredentialsRejectedErr.

**Changed (new text):**
| Label (object) | Text |
|---|---|
| SetupIncompleteErr (60113, 60114) | Address validation is not set up. Contact your administrator. |
| NotUSAddressErr (60113) | Address validation works for US addresses only. |
| ConfirmedMsg (60113) | The address is confirmed by %1. No changes are needed. (%1 = provider name) |
| AddressChangedMsg (60113) | The customer's address was changed while the suggested address was open, so nothing was updated. Run Validate Address again. |
| NoPermissionTxt (60113) | You can't accept the suggested address because you don't have permission to change customers. Choose OK or Cancel to close without changes. |
| ValueTooLongTxt (60113) | You can't accept the suggested address because the suggested value for %1 is longer than %2 characters. Choose OK or Cancel to close without changes. |
| InstructionTxt (60112) | Changed values are shown in bold. Choose OK to accept the suggested address, or Cancel to keep the current address. |
| DpvUnconfirmedSecondaryTxt / DpvNotConfirmedTxt / VacantTxt / BusinessTxt (60112) | The suite or apartment number could not be confirmed. / USPS could not confirm this address as deliverable. / USPS data reports that this address is vacant. / This is a business address. |
| ConnectionOkMsg (60096) | The connection to Google Maps works. The API key was accepted. |
| Wizard (60097) | Welcome: "Enter the API key from your Google Cloud project. Billing and the Address Validation API must be enabled for that project. The key is stored securely for this company and isn't shown again after you save it." Scope: "You turn the service on and test the connection on the Address Validation Setup page." Finish: "Choose Finish to save the API key." |
| Assisted setup (60100) | 'Set up address validation' / 'Address validation' / 'Enter the Google Maps API key used to validate customer addresses.' |
| CallerNotAllowedErr (3 objects) | This procedure can only be called by the Address Validator app. (depends on §4 naming) |

**New:**
| Label (object) | Text |
|---|---|
| ConfirmedNoteMsg (60113) | The address is confirmed by %1. No changes are needed. Note: %2 |
| MissingApiKeyErr (60114, 60119) | Enter the API key first. |
| NotValidatedMsg (60119) | Google Maps could not confirm this address to the building. %1 |
| MissingPartsTxt (60119) | Missing or unconfirmed: %1. |
| ApiKeyRejectedErr (60119) | Google Maps rejected the API key. Contact your administrator. |
| ApiDisabledErr (60119) | The Address Validation API is not enabled in the Google Cloud project of this API key. Contact your administrator. |
| BillingDisabledErr (60119) | Billing is not enabled for the Google Cloud project of this API key. Contact your administrator. |
| ApiKeyRestrictedErr (60119) | The API key is not allowed to call the Address Validation API. Check the key's restrictions. Contact your administrator. |
| AccessDeniedErr (60119) | Google Maps refused the request: %1 |
| CouldNotReadErr (60119, moved) | Google Maps could not read the address: %1 |
| QuotaErr (60119) | The Google Maps request limit has been reached. Try again later. |
| NotRespondingErr (60119) | Google Maps is not responding. Try again later. |
| UnexpectedResponseErr (60119) | Unexpected response from Google Maps. Contact your administrator. |
| TestConnectionFailedErr (60119) | The connection to Google Maps failed. %1 Google message: %2 |
| ReplacedTxt / InferredTxt / SpellCorrectedTxt / UnconfirmedTxt / PoBoxTxt (60112) | Part of the address was replaced, for example the ZIP Code. / Missing parts of the address were added. / The spelling of part of the address was corrected. / Some parts of the address could not be confirmed. / This is a PO box. |
| AttributionTxt (60112) | Suggestion from %1 |
| KeyGuidanceTxt (60096) | Use an API key that is restricted to the Address Validation API, and set a daily quota and a budget alert in the Google Cloud console. |

**New Locked tokens (60119):**
- Endpoint, `X-Goog-Api-Key`, `Content-Type`, `application/json`, `POST`.
- `Google Maps` (GoogleMapsTok).
- JSON names: address, regionCode, US, addressLines, locality, administrativeArea, postalCode, enableUspsCass, result, verdict, validationGranularity, possibleNextAction, addressComplete, has… ×4, missingComponentTypes, postalAddress, uspsData, standardizedAddress, firstAddressLine, secondAddressLine, city, state, zipCode, zipCodeExtension, dpvConfirmation, dpvVacant, errorMessage, metadata, business, poBox, error, message, status, details, @type, reason.
- Values: PREMISE, SUB_PREMISE, API_KEY_INVALID, SERVICE_DISABLED, BILLING_DISABLED, ErrorInfo suffix.

**60098:** ApiKeyStorageTok.

### 2.12 Permission sets (names per §4)
USE:
- remove `codeunit "obcfusps USPS API Client"`
- add `codeunit "obcfusps Address Service" = X`, `codeunit "obcfusps Google Address Client" = X`
- `codeunit "obcfusps Http Transport Impl." = X` (renamed)
- `tabledata/table "obcfusps Address Buffer"` (renamed)

ADMIN: unchanged apart from renamed objects. Interfaces and enums need no entries.

### 2.13 Object Register delta (`docs/1-define/ObjectRegister.md`)
| ID | Before | After |
|---|---|---|
| 60093 | Enum Validation Result | unchanged (Caption 'Address Validation Result') |
| 60094 | Enum USPS Environment | **Enum "obcfusps Address Provider"** (ID reused; nothing installed, so reuse is safe) |
| 60095–60100 | setup, card, wizard, Credential Mgt., Install, Registration | modified (names per §4) |
| 60111 | USPS Address Buffer | "obcfusps Address Buffer" |
| 60114 | USPS API Client | **"obcfusps Address Service"** |
| 60115 | USPS Http Transport | "obcfusps Http Transport Impl." |
| — | Interface USPS Transport | **removed**; new interfaces "obcfusps Http Transport" and "obcfusps Address Provider" |
| **60119** | buffer B | **Codeunit "obcfusps Google Address Client"** |
| 60120–60122 | buffer B | buffer B (3 = 21 % of module B, still at least 20 %) |
| **60128** | buffer C | **Codeunit (test app) "obcfusps Fake Address Provider"** |
| 60129–60133 | buffer C | buffer C (5) |

Unallocated: 23 of 50 (at least 10 required). No ID is freed: 60094 is reused.

### 2.14 Test app (`/Users/ajansari/Documents/AL/USPSAddressValidator.Tests/src`)
- **60123 Fake transport.**
  - Implements `"obcfusps Http Transport"`, with one queue (Responds, Status, Body).
  - `Send(var Request…)` increments `Calls` and captures `LastUri := Request.GetRequestUri()`, `LastBody` (from `Request.Content.ReadAs`) and `LastMethod`.
  - Procedures: `Reset`, `EnqueueResponse(Status; Body)`, `EnqueueNoResponse`, `CallCount()`, `GetLastRequestUri()`, `GetLastRequestBody()`.
  - The FailCustomerModify subscriber is kept.
  - Removed: token queue, `TokenCallCount`, `GetLastAddressUrl`.
  - Whether the fake can check that the key header is present (`Headers.ContainsSecret`) is a spike item.
- **60124 Library.**
  - `InitSetup`: Provider Google, `SetApiKey('test-key')`; the test-company guard stays. `CleanUp`: `SetApiKey(empty)`.
  - `TokenJson`/`AddressJson` are replaced by `GoogleResultJson(Line1; Line2; City; State; Zip5; Plus4; Granularity; NextAction; DPV; Vacant; Business; WithUspsData: Boolean)` and `GoogleErrorJson(HttpCode; Status; Reason; Message)`.
  - `AssertCallCounts(Expected: Integer)` takes a single count. Text helpers follow §2.11.
- **60125 Validation Tests.**
  - Tests 1–7, A1, A2, A6 and A7: single enqueue.
  - Test 4: 200 with `ROUTE`. Test 5: DPV `D` and `CONFIRM_ADD_SUBPREMISES`.
  - **New:**
    - `TestRequestShape` (test 10): URI equals the endpoint with no `key=`; body has regionCode US, `enableUspsCass: true` and the address lines; no customer No. or name; `CallCount() = 1`.
    - `TestProviderSeam`: inject 60128 through `Validator.SetProvider` and check Confirmed, the dialog and the log run unchanged with a non-Google provider.
    - `TestPunctuationConfirmed` (Q5).
    - `TestStreetSplitConfirmed` (Q5).
- **60126 API Client Tests** (keep the object name; its subject is now the Google client).
  - Test 8 becomes 400 `API_KEY_INVALID`. Test 9 (a, b) adjusted.
  - **Removed:** `TestTokenReusedNextCheck` (old test 10), `TestCachedTokenRejectedRetry` (A5).
  - **New:**
    - `TestApiDisabled`, `TestBillingDisabled` (test 22)
    - `TestKeyRestricted`
    - `TestInvalidArgumentMessage`
    - `Test5xx`
    - `TestUnparsable200`
    - `TestValidatedWithoutAddress` → Unexpected
    - `TestNotValidatedOther` → Not Found with missing parts
    - `TestFallbackPostalAddress` (no `uspsData`)
    - `TestTestConnectionProbeOk` (400 INVALID_ARGUMENT → true)
    - `TestTestConnectionKeyRejected`
- **60127 Addr Validated Tests:** enqueue helpers only. A3 uses granularity `OTHER`; A4 stays 429.
- **New 60128 "obcfusps Fake Address Provider":** implements `"obcfusps Address Provider"`, `SingleInstance`, returns a preset buffer, `DisplayName = 'Test Provider'`.
- **Test app `app.json`:** bump the dependency version to the rework build. The name and description follow §4. The id is unchanged (TestAppIdTok stays).

### 2.15 Rework batch plan (for `docs/3-build/BuildPlan.md`)
| Batch | Files | Order reason |
|---|---|---|
| R1 Foundation | enum 60094 (replace file `obcfuspsUSPSEnvironment.Enum.al` with `obcfuspsAddressProvider.Enum.al`), table 60095, codeunit 60098, permission sets (setup lines) | Everything references it |
| R2 Provider layer | interface Http Transport (new file; delete `obcfuspsUSPSTransport.Interface.al`), interface Address Provider (new), 60115, buffer 60111, 60119 Google client (new), 60114 Address Service, page 60096 | The only provider-specific code, isolated first |
| R3 Log | 60109, 60110 | Needed by R4 |
| R4 Validation | 60112, 60118, 60113, 60117 | Uses R1–R3 |
| R5 Onboarding | 60097, 60100 | Labels and wizard |
| R6 Test app | 60123, 60124, 60125, 60126, 60127, new 60128, `app.json` | Exercises the finished app |

Then one Step 07 compile, at the next Revision (0.0.0.3), with 0/0.

### 2.16 Sanity Check delta review (`docs/2-design/SanityCheck.md`)
Re-check:
- F1/F5/F25 (§13.1): unchanged flow; confirm the Commit after a token-less HTTP phase.
- F2/F21 (§13.2): caller check now on SetTransport, **SetProvider** and SetApiKey; ClearToken is gone.
- F10 (§13.3): one key.
- F6 (§13.5): test list as in §2.14.
- F11 and §13.8/§13.9 item 1: the USPS contract is replaced by the Google spike list.
- §11 note 6 (Allow HttpClient).
- FR-8 definitions.
- **New checks:**
  - storage terms (Q1)
  - attribution
  - artificial-address rule
  - key never in a URL or log
  - Test Connection billing
  - the new enum's `Extensible` decision

---


### 2.17 Naming — Q11 revised (AJ Ansari, 2026-10-16; this subsection wins over every object name used elsewhere in §14)
Full rename, remediation 07a. Nothing is installed in any tenant, so no rename migration is needed.
- **Prefix** `obcfusps` → `obcfgav`; **namespace** `OnlyBCFans.USPSAddress` → `OnlyBCFans.GoogleAddress` (both apps); **App Code** `USPS` → `GAV`; permission sets `OBCFGAV GAV, USE` and `OBCFGAV GAV, ADMIN` (16 and 19 characters). App `name` **Google Address Validator**; test app `name` **Google Address Validator Tests**; package file `Google_Address_Validator_<version>.app` (older `USPS_Address_Validator_*.app` packages are kept, never deleted). App id, publisher, object IDs, field IDs and idRanges do not change. Next build 0.0.0.5 (test app 0.0.0.4).
- **Rule:** the word "USPS" disappears from object names, file names and captions of objects that stay; the prefix stays first; `USPS` survives only where it is the data (Google's `uspsData`, DPV, CASS, "USPS-standardized"). IsolatedStorage keys, privacy notice id and retention period code change prefix: `OBCFGAV-ApiKey`, `OBCFGAV-ADDRESS`, `OBCFGAV-2Y`.
- **Object names (new):**
| ID | New name | File |
|---|---|---|
| 60093 | Enum "obcfgav Validation Result" | obcfgavValidationResult.Enum.al |
| 60094 | Enum "obcfgav Address Provider" | obcfgavAddressProvider.Enum.al |
| 60095 / 60096 / 60097 | Table / Page "obcfgav Setup"; Page "obcfgav Setup Wizard" | obcfgavSetup.Table.al / .Page.al, obcfgavSetupWizard.Page.al |
| 60098 | Codeunit "obcfgav Credential Mgt." | obcfgavCredentialMgt.Codeunit.al |
| 60099 / 60100 | Codeunit "obcfgav Install"; "obcfgav Setup Registration" | obcfgavInstall.Codeunit.al, obcfgavSetupRegistration.Codeunit.al |
| 60101 / 60102 | Permission sets "OBCFGAV GAV, USE" / "OBCFGAV GAV, ADMIN" | OBCFGAVGAVUSE.PermissionSet.al, OBCFGAVGAVADMIN.PermissionSet.al |
| 60109 / 60110 | Table "obcfgav Validation Log"; Page "obcfgav Log Entries" | obcfgavValidationLog.Table.al, obcfgavLogEntries.Page.al |
| 60111 | Table "obcfgav Address Buffer" | obcfgavAddressBuffer.Table.al |
| 60112 | Page "obcfgav Address Compare" | obcfgavAddressCompare.Page.al |
| 60113 / 60114 / 60115 | Codeunits "obcfgav Address Validation"; "obcfgav Address Service"; "obcfgav Http Transport Impl." | obcfgavAddressValidation.Codeunit.al, obcfgavAddressService.Codeunit.al, obcfgavHttpTransportImpl.Codeunit.al |
| 60116 / 60117 | TableExt "obcfgav Customer"; PageExt "obcfgav Customer Card" | obcfgavCustomer.TableExt.al, obcfgavCustomerCard.PageExt.al |
| 60118 / 60119 | Codeunits "obcfgav Validation Writer"; "obcfgav Google Address Client" | obcfgavValidationWriter.Codeunit.al, obcfgavGoogleAddressClient.Codeunit.al |
| — | Interfaces "obcfgav Http Transport", "obcfgav Address Provider" | obcfgavHttpTransport.Interface.al, obcfgavAddressProvider.Interface.al |
| Customer field 60093 | "obcfgav Address Validated" | — |
| Test app 60123–60128 | "obcfgav Fake Http Transport", "obcfgav Test Library", "obcfgav Validation Tests", "obcfgav Provider Tests" (was API Client Tests), "obcfgav Addr Validated Tests", "obcfgav Fake Address Provider" | obcfgav*.Codeunit.al |
- **Captions:** wherever §14 or the code carries "USPS" in a caption, tooltip or message for an object that stays, it reads "Google" or is neutral per §2.11. The setup page, wizard, assisted-setup entry and log are "Google Address Validation …".
- **Open (needs AJ's decision before the build):** the app icon `src/logo/AppLogo.png` is the USPS-themed image (`images/usps-address-validation-icon-512.png`); a Google-neutral icon is needed or the icon is dropped.

### 14.x Impact on existing files

**Main app, `src/`**
| File | Status | Why |
|---|---|---|
| Setup/OBCFUSPSUSPSADMIN.PermissionSet.al | modified | Renamed objects (and the set name per §4) |
| Setup/OBCFUSPSUSPSUSE.PermissionSet.al | modified | New codeunits 60114/60119; renamed buffer and transport |
| Setup/obcfuspsSetupRegistration.Codeunit.al | modified | Assisted-setup labels |
| Setup/obcfuspsUSPSCredentialMgt.Codeunit.al | modified | One API key; token code removed |
| Setup/obcfuspsUSPSEnvironment.Enum.al | **removed** | Environment retired; ID 60094 reused |
| Setup/obcfuspsAddressProvider.Enum.al | **new** | Provider selector (60094) |
| Setup/obcfuspsUSPSInstall.Codeunit.al | unchanged | Calls RegisterAll only |
| Setup/obcfuspsUSPSSetup.Page.al | modified | API key field, Provider, Test Connection, labels |
| Setup/obcfuspsUSPSSetup.Table.al | modified | Environment field becomes Provider |
| Setup/obcfuspsUSPSSetupWizard.Page.al | modified | One field |
| Setup/obcfuspsValidationResult.Enum.al | modified (caption only) | 'Address Validation Result' |
| Setup/.gitkeep, Validation/.gitkeep, logo/AppLogo.png | unchanged | Icon change only if §4 option C (the icon shows USPS?) |
| Validation/obcfuspsAddressValidation.Codeunit.al | modified | Service type, SetProvider, preconditions, normalization, labels |
| Validation/obcfuspsCustomer.TableExt.al | unchanged | No provider text |
| Validation/obcfuspsCustomerCard.PageExt.al | modified | Captions and tooltips |
| Validation/obcfuspsUSPSAPIClient.Codeunit.al | **removed** (replaced) | Becomes `obcfuspsAddressService.Codeunit.al` (60114) |
| Validation/obcfuspsAddressService.Codeunit.al | **new** | Facade |
| Validation/obcfuspsGoogleAddressClient.Codeunit.al | **new** | 60119 |
| Validation/obcfuspsUSPSAddressBuffer.Table.al | **removed** (renamed) | Becomes `obcfuspsAddressBuffer.Table.al`, new fields |
| Validation/obcfuspsUSPSAddressCompare.Page.al | modified | Attribution, notes, captions (file name per §4) |
| Validation/obcfuspsUSPSHttpTransport.Codeunit.al | **removed** (renamed) | Becomes `obcfuspsHttpTransportImpl.Codeunit.al`, one Send |
| Validation/obcfuspsUSPSTransport.Interface.al | **removed** | Replaced by `obcfuspsHttpTransport.Interface.al` |
| Validation/obcfuspsHttpTransport.Interface.al, obcfuspsAddressProvider.Interface.al | **new** | Seam and provider interface |
| Validation/obcfuspsUSPSLogEntries.Page.al | modified | Columns and captions |
| Validation/obcfuspsUSPSValidationLog.Table.al | modified | Fields 12–23 |
| Validation/obcfuspsValidationWriter.Codeunit.al | modified | Field mapping, Provider, Q1 |

**Test app, `USPSAddressValidator.Tests/src`**
| File | Status | Why |
|---|---|---|
| obcfuspsFakeUSPSTransport.Codeunit.al | modified (renamed per §4, e.g. `obcfuspsFakeHttpTransport`) | One Send, request capture |
| obcfuspsTestLibrary.Codeunit.al | modified | Google JSON builders, SetApiKey, single call count |
| obcfuspsValidationTests.Codeunit.al | modified | Enqueue changes, tests 4/5, 4 new tests |
| obcfuspsAPIClientTests.Codeunit.al | modified | 2 tests removed, about 11 added |
| obcfuspsAddrValidatedTests.Codeunit.al | modified | Enqueue changes |
| obcfuspsFakeAddressProvider.Codeunit.al | **new** | Seam test (60128) |
| app.json (outside src) | modified | Dependency version (and name per §4) |

Observation outside scope: an untracked `OnlyBCFans_USPS Address Validator_0.0.0.2.app` sits in the project root, next to the proper packages in `outputAppPackage/`. It looks like a default compile output. The main role may want to check it against Ops § Packaging and Operating Rule 9.

---


### 14.y Spike checklist (needs a real Google API key; real addresses only)
- [ ] The `X-Goog-Api-Key` header is accepted by addressvalidation.googleapis.com (else switch to `SetSecretRequestUri` with `?key=`).
- [ ] With `enableUspsCass: true` on a real US address, check:
  - [ ] whether `uspsData.standardizedAddress` is present and upper case
  - [ ] what `secondAddressLine` holds (suite on line 1 or line 2?)
  - [ ] whether `postalAddress.addressLines` splits the suite, and the `postalCode` format (ZIP+4 with a dash?)
  - [ ] whether `metadata` is present, and whether false booleans are omitted
- [ ] Error bodies and HTTP codes:
  - [ ] invalid key (400 + `API_KEY_INVALID`?)
  - [ ] API disabled (403 `SERVICE_DISABLED`?)
  - [ ] billing disabled (403 `BILLING_DISABLED`?)
  - [ ] key restricted to another API (403 `API_KEY_SERVICE_BLOCKED`?)
  - [ ] daily cap reached (429 `RESOURCE_EXHAUSTED`; set the cap to 1 per day to provoke it)
- [ ] An empty `addressLines` request returns 400 INVALID_ARGUMENT **after** the key, API and billing checks, and is **not billed** (Cloud console metrics and the billing report by SKU after 24 h).
- [ ] The CASS request is billed as **Address Validation Pro**, inside the 5,000 free (billing report).
- [ ] A real street without a house number gives ROUTE/OTHER; a real office building without a suite gives `CONFIRM_ADD_SUBPREMISES` / DPV D.
- [ ] `error.message` never contains the key or a URL with it.
- [ ] Latency is well under the 10 s timeout; `HttpClient.Send` returns false (not an error) on timeout and DNS failure (TDD §13.9 item 2).
- [ ] The test fake can tell the key header is present (`HttpHeaders.ContainsSecret` or equivalent) and read the request content.
- [ ] The API key length fits the `SetEncrypted` 215-character limit.
- [ ] The current Google Maps Platform Service Specific Terms, Address Validation section: the 30-day caching rule, permitted purposes and the artificial-address clause (only the archived 2024-05-22 version could be read).
- [ ] "Allow HttpClient Requests" default (OQ-20) and the US captions (OQ-19). Both are unchanged and still open.


---

### Decisions that settle the draft (AJ Ansari, options box, 2026-10-17)
| Ref | Decision |
|---|---|
| Scope | Union out; 15 tables beyond Customer; nothing on transactions or documents; version 1.1.0.0; batches one at a time. |
| IDs | Re-blocked (Sanity Check F-SC1-08): engine and upgrade objects in the unused 1.0 tail 60134–60139; Write Guard in module B's buffer (60120); sources in 60143–60192 (E 60143–60151, F 60152–60164, G 60165–60177, H 60178–60192). `idRanges` becomes `[60093–60122, 60134–60192]`. |
| OQ-34 | Shared field number 60093 on every source table (60094 for the Company Information ship-to flag). |
| OQ-35 | Yes: the flag follows standard address copies. |
| OQ-36 | Yes: a Country/Region change that clears City/ZIP/State resets the flag, Customer included. |
| OQ-37 | Yes: Privacy Blocked = Yes refuses validation, Customer included, **and** child sources of a blocked parent (Ship-to Address and Customer Bank Account via Customer; Order Address, Remit Address and Vendor Bank Account via Vendor; Alternative Address via Employee; Contact Alt. Address via Contact). Not logged, nothing sent. |
| OQ-38 | Yes: one privacy notice and one Setup switch cover all tables, People included. |
| OQ-39 / OQ-40 | Customer No. blank on Ship-to Address and Customer Bank Account entries; one log action for both Company Information blocks. |
| OQ-41 | Yes: after batch 1, a human-requested compile, package and sandbox run of the 61 existing tests before batch 2. |
| OQ-42–46 | Recommended: Customer texts verbatim plus generic texts; no list-page actions; test app 0.0.0.8 (sync tests may change and restore Marketing Setup in TEST); description = table + key, never a name; Address Type enum not extensible. |
| F-SC1-03 | The linked-record flag update on Confirmed and Not Found runs as a separate step after the check is committed; a failure leaves the linked flag unchanged and the check complete. |
| F-SC1-04 | The standard duplicate-contact form is suppressed while the extension writes (Write Guard). |
| F-SC1-05 | Confirmed and Not Found on an Employee propagate to its Resource. |
| F-SC1-06 | `app.json` moves to batch 1. Files 60101 and 60113 are edited in batch 1 and batch 4: a recorded exception, safe because batches run one at a time. |
| F-SC1-13 | Test procedure names are 30 characters or fewer. |
| N-SC1-06 | Explicit upgrade tags instead of `SetAllUpgradeTags()` (a departure from Standards §9.3's preferred form). Decider: AJ Ansari, 2026-10-17. Reason: `SetAllUpgradeTags()` raises `OnGetPerCompanyUpgradeTags` to every installed app and writes all those tags, so on install into an existing company it would mark other extensions' pending upgrades as done. |

Status: Signed off by AJ Ansari (Dev Manager and Technical Lead) on 2026-10-17 as drafted (ChangeLog SC-1b); amended the same day by the Sanity Check resolutions above (`docs/2-design/SanityCheck.md`, section SC-1 Sanity Check). Where this appendix and the sections above disagree, this appendix governs for version 1.1.0.0.

## 15. Scope change SC-1 — amendments for version 1.1.0.0 (signed off by AJ Ansari 2026-10-17, amended by the Sanity Check)

**Baseline.** `docs/4-prove/PostDevTDD.md` Part B (as built, 1.0.0.0) is the baseline. §15 overrides Part B where it says so. Everything else in Part B and Part D stays normative. Step 10 folds §15 into PostDevTDD. Symbols: Base Application 28.5.54151.55594, System 28.0.54688.0, System Application 28.5.54151.55108. Anchors were compile-probed with AL 18.1.43.24897.

### 15.1 Identity
- `app.json`:
  - `version` `1.1.0.0` (first build). Builds after it are 1.1.0.1, 1.1.0.2 …
  - `idRanges` `[{60093–60122}, {60134–60192}]` (the 1.0 tail and the new block merged).
- Test app:
  - `version` `0.0.0.8` (Revision; OQ-44);
  - dependency on main `1.1.0.0`;
  - `idRanges` unchanged `[{60123–60133}]`.
- `app.json` (version and `idRanges`) is edited in B1, so B1 can compile and package for the OQ-41 checkpoint.
- The namespace stays `OnlyBCFans.GoogleAddress` (flat).
- New folders:
  - `src/Sources/` — the 30 extensions, 60135, 60139 and 60120 (Write Guard);
  - `src/Upgrade/` — 60136–60138.
- The Customer extensions stay in `src/Validation/`.

### 15.2 ID allocation (re-blocked, F-SC1-08)
| Module | Block | Used | Spare |
|---|---|---|---|
| A Setup (1.0) | 60103–60108 | — | 6 |
| B Validation (1.0) | 60120–60122 | 60120 (Write Guard) | 2 (60121–60122) |
| D Engine and upgrade (1.0 tail) | 60134–60142 | 60134–60139 | 3 (60140–60142) |
| E Sales and customer | 60143–60151 | 60143–60146 | 5 (60147–60151) |
| F Purchasing and vendor | 60152–60164 | 60152–60159 | 5 (60160–60164) |
| G Company and org | 60165–60177 | 60165–60172 | 5 (60173–60177) |
| H People | 60178–60192 | 60178–60187 | 5 (60188–60192) |

37 new IDs are used in the main app: D 6, E 4, F 8, G 8, H 10 and the Write Guard 60120. Spare in the main app: 31. Test app: 60131–60133 (3) after 60129 and 60130. Standards §5.2 asks 5–6 spare per module block: E–H meet it; D (3) and B (2) do not. Recorded deviation: the spare IDs of the main app are pooled (31), and any block that runs out borrows from the unused 1.0 buffers.

**Field numbers (OQ-34, decided).**
- Field `60093 "obcfgav Address Validated"` on every source table (Customer as built). Field numbers are per table, so one number can repeat across the table extensions of this app.
- Company Information also gets `60094 "obcfgav Ship-to Validated"` (25 characters).
- Customer, Vendor, Bank Account and Contact must share 60093: standard Business Central copies these tables to each other with `TransferFields`, which copies by field number, so the flag travels with the address.

### 15.3 Object plan
| ID | Type | Name | File | Batch |
|---|---|---|---|---|
| 60134 | Enum | "obcfgav Address Type" | `src/Sources/obcfgavAddressType.Enum.al` | B1 |
| 60120 | Codeunit (`EventSubscriberInstance = Manual`) | "obcfgav Write Guard" | `src/Sources/obcfgavWriteGuard.Codeunit.al` | B1 |
| 60135 | Codeunit | "obcfgav Address Source" | `src/Sources/obcfgavAddressSource.Codeunit.al` | B1 |
| 60136 | Codeunit | "obcfgav Upgrade Tags" | `src/Upgrade/obcfgavUpgradeTags.Codeunit.al` | B1 |
| 60137 | Codeunit (Upgrade) | "obcfgav Upgrade Log Source" | `src/Upgrade/obcfgavUpgradeLogSource.Codeunit.al` | B1 |
| 60138 | Codeunit (Upgrade) | "obcfgav Upgrade Contact Flag" | `src/Upgrade/obcfgavUpgradeContactFlag.Codeunit.al` | B3 |
| 60139 | Codeunit | "obcfgav Address Sync Subscr." (subscribers, and `OnRun` for the linked-record update) | `src/Sources/obcfgavAddressSyncSubscr.Codeunit.al` | B4 |
| 60143 / 60144 | TableExt / PageExt | "obcfgav Ship-to Address" / "obcfgav Ship-to Address Card" (extends page "Ship-to Address") | `obcfgavShiptoAddress.TableExt.al` / `obcfgavShiptoAddressCard.PageExt.al` | B2 |
| 60145 / 60146 | TableExt / PageExt | "obcfgav Customer Bank Account" / "obcfgav Cust. Bank Acc. Card" | `obcfgavCustomerBankAccount.TableExt.al` / `obcfgavCustBankAccCard.PageExt.al` | B2 |
| 60152 / 60153 | TableExt / PageExt | "obcfgav Vendor" / "obcfgav Vendor Card" | `obcfgavVendor.TableExt.al` / `obcfgavVendorCard.PageExt.al` | B2 |
| 60154 / 60155 | TableExt / PageExt | "obcfgav Order Address" / "obcfgav Order Address Card" (page "Order Address") | `obcfgavOrderAddress.TableExt.al` / `obcfgavOrderAddressCard.PageExt.al` | B2 |
| 60156 / 60157 | TableExt / PageExt | "obcfgav Remit Address" / "obcfgav Remit Address Card" (page "Remit Address") | `obcfgavRemitAddress.TableExt.al` / `obcfgavRemitAddressCard.PageExt.al` | B2 |
| 60158 / 60159 | TableExt / PageExt | "obcfgav Vendor Bank Account" / "obcfgav Vendor Bank Acc. Card" | `obcfgavVendorBankAccount.TableExt.al` / `obcfgavVendorBankAccCard.PageExt.al` | B2 |
| 60165 / 60166 | TableExt / PageExt | "obcfgav Company Information" / "obcfgav Company Info. Card" (page "Company Information") | `obcfgavCompanyInformation.TableExt.al` / `obcfgavCompanyInfoCard.PageExt.al` | B3 |
| 60167 / 60168 | TableExt / PageExt | "obcfgav Location" / "obcfgav Location Card" | `obcfgavLocation.TableExt.al` / `obcfgavLocationCard.PageExt.al` | B3 |
| 60169 / 60170 | TableExt / PageExt | "obcfgav Responsibility Center" / "obcfgav Resp. Center Card" | `obcfgavResponsibilityCenter.TableExt.al` / `obcfgavRespCenterCard.PageExt.al` | B3 |
| 60171 / 60172 | TableExt / PageExt | "obcfgav Bank Account" / "obcfgav Bank Account Card" | `obcfgavBankAccount.TableExt.al` / `obcfgavBankAccountCard.PageExt.al` | B3 |
| 60178 / 60179 | TableExt / PageExt | "obcfgav Employee" / "obcfgav Employee Card" | `obcfgavEmployee.TableExt.al` / `obcfgavEmployeeCard.PageExt.al` | B3 |
| 60180 / 60181 | TableExt / PageExt | "obcfgav Alternative Address" / "obcfgav Alt. Address Card" | `obcfgavAlternativeAddress.TableExt.al` / `obcfgavAltAddressCard.PageExt.al` | B3 |
| 60182 / 60183 | TableExt / PageExt | "obcfgav Contact" / "obcfgav Contact Card" | `obcfgavContact.TableExt.al` / `obcfgavContactCard.PageExt.al` | B3 |
| 60184 / 60185 | TableExt / PageExt | "obcfgav Contact Alt. Address" / "obcfgav Cont. Alt. Addr. Card" | `obcfgavContactAltAddress.TableExt.al` / `obcfgavContAltAddrCard.PageExt.al` | B3 |
| 60186 / 60187 | TableExt / PageExt | "obcfgav Resource" / "obcfgav Resource Card" | `obcfgavResource.TableExt.al` / `obcfgavResourceCard.PageExt.al` | B3 |
| 60129 | Codeunit (Test), test app | "obcfgav Source Tests" | `../USPSAddressValidator.Tests/src/obcfgavSourceTests.Codeunit.al` | B4 |
| 60130 | Codeunit (Test), test app | "obcfgav Sync Tests" | `../USPSAddressValidator.Tests/src/obcfgavSyncTests.Codeunit.al` | B4 |

- Every name is 30 characters or fewer.
- The extension file paths are under `src/Sources/`. File names follow AA0215: the name with spaces, hyphens and dots removed.
- Changed 1.0 objects: 60096, 60099, 60100, 60101, 60109, 60110, 60111, 60112, 60113, 60118, 60116 (B4, Country/Region reset). 60101 and 60113 are edited again in B4 (recorded exception, F-SC1-06).
- Unchanged: 60117 and every provider, setup and transport object.

### 15.4 Enum 60134 "obcfgav Address Type"
- `Caption = 'Address Type';`
- `Extensible = false` (decided, OQ-46): a closed set that the field map depends on.
- Values: `0 Main` (Caption 'Main'), `1 "Ship-to"` (Caption 'Ship-to').
- No blank value on purpose: Main is the default for every non-company row and for upgraded log rows.

### 15.5 Codeunit 60135 "obcfgav Address Source" (`Access = Internal`)
**using:** `Microsoft.Bank.BankAccount`, `Microsoft.CRM.BusinessRelation`, `Microsoft.CRM.Contact`, `Microsoft.Foundation.Company`, `Microsoft.HumanResources.Employee`, `Microsoft.Inventory.Location`, `Microsoft.Projects.Resources.Resource`, `Microsoft.Purchases.Remittance`, `Microsoft.Purchases.Vendor`, `Microsoft.Sales.Customer`.

**Field map.** `Map: array[7] of Integer`, indexed as: 1 Address, 2 Address 2, 3 City, 4 County (State), 5 Post Code (ZIP), 6 Country/Region Code, 7 Address Validated.
- Built in `GetMap` with a `case SourceTableNo of`, using typed `<Rec>.FieldNo(...)` for base fields so they are compile-checked. The numbers are in 15.22.
- Index 7 = `ValidatedFieldNo()` (60093). For Company Information `AddressType = "Ship-to"`, index 7 = `ShipToValidatedFieldNo()` (60094), and indexes 1–6 = the Ship-to fields 24/25/26/33/32/37.
- `"Ship-to"` for any other table returns false.
- Constants instead of `FieldNo` on the extension fields keep B1 free of forward references (batch 1 compiles alone).

| Procedure | Behaviour |
|---|---|
| `GetMap(SourceTableNo: Integer; AddressType: Enum "obcfgav Address Type"; var Map: array[7] of Integer): Boolean` | As above. `Clear(Map)` first. Unknown table → false |
| `IsSupported(SourceTableNo; AddressType): Boolean` | `GetMap` and `RecRef.Open(SourceTableNo)` and `RecRef.FieldExist(Map[7])`, then `Close` |
| `OpenSource(var SourceRecRef: RecordRef; SourceTableNo; SourceSystemId: Guid; AddressType; ForUpdate: Boolean): Boolean` | `SourceRecRef.Open(SourceTableNo)`. If `ForUpdate`, `SourceRecRef.LockTable()`; otherwise `SourceRecRef.SetLoadFields(Map[1..7])` plus the primary-key fields, field 150 where the table has it, and the parent key field of a child source. `exit(SourceRecRef.GetBySystemId(SourceSystemId))` |
| `GetValue(var SourceRecRef; AddressType; Index: Integer): Text` | `Format(SourceRecRef.Field(Map[Index]).Value)` |
| `GetLength(var SourceRecRef; AddressType; Index): Integer` | `SourceRecRef.Field(Map[Index]).Length` |
| `FillOriginal(var SourceRecRef; AddressType; var TempAddressBuffer)` | `Init()`. Sets Source Table No. := `SourceRecRef.Number`, Address Type, Source SystemId := `SourceRecRef.Field(SourceRecRef.SystemIdNo).Value`, Source Description := `Describe(...)`, "Customer No." := the "No." value **only when Number = Database::Customer**, Original Address / Address 2 / City / State / ZIP from indexes 1–5 (`CopyStr` to the buffer lengths). Never inserts |
| `DiffersFromSnapshot(var SourceRecRef; AddressType; TempAddressBuffer): Boolean` | Any of indexes 1–5 differs from the Original fields (exact compare, as `CustomerDiffersFromSnapshot`) |
| `AssignSuggested(var SourceRecRef; AddressType; TempAddressBuffer)` | Index 1..5 `.Value := CopyStr(Suggested…, 1, Length)` in the order Address, Address 2, City, County = Suggested State, Post Code = Suggested ZIP. Index 7 `.Value := true`. Direct assignment, never `Validate` |
| `GetValidated(var SourceRecRef; AddressType): Boolean` / `SetValidated(var SourceRecRef; AddressType; NewValue: Boolean)` | Index 7 |
| `SaveSource(var SourceRecRef: RecordRef; AddressType; AddressWritten: Boolean)` | See below |
| `IsPrivacyBlocked(var SourceRecRef; AddressType): Boolean` | True when the record itself has field 150 "Privacy Blocked" (checked with `FieldExist(150)` and the field name) and it is true. For a child source, also true when its parent is blocked: Ship-to Address and Customer Bank Account → Customer ("Customer No."); Order Address, Remit Address and Vendor Bank Account → Vendor ("Vendor No."); Alternative Address → Employee ("Employee No."); Contact Alt. Address → Contact ("Contact No."). The parent is read with `SetLoadFields("Privacy Blocked")` and `Get`. A missing parent is not blocked |
| `Describe(var SourceRecRef; AddressType): Text[250]` | `StrSubstNo(DescriptionTok, SourceRecRef.Caption, KeyText)`, where KeyText = the non-blank primary-key values of `KeyIndex(1)` joined by a space. For `"Ship-to"`, `StrSubstNo(BlockDescriptionTok, Description, Format(AddressType))`. `CopyStr` to 250. **No name field is ever read** |

**`SaveSource` per table:**
- **`Database::Customer`, AddressWritten:** `SourceRecRef.SetTable(Customer); Customer.SetForceUpdateContact(true); Customer.Modify(true);` (identical to 1.0.0.0).
- **`Database::Vendor`, AddressWritten:** the same with Vendor.
- **`Database::"Bank Account"`:** `SourceRecRef.Modify(true)`. If AddressWritten: `SourceRecRef.SetTable(BankAccount); BankContUpdate.OnModify(BankAccount);` (codeunit "BankCont-Update").
- **`Database::Employee`, AddressWritten** (a flag-only Employee write is handled by the linked-record update, 15.13):
  1. `SourceRecRef.SetTable(Employee); OldEmployee.GetBySystemId(Employee.SystemId);` (the stored version, before the write)
  2. `SourceRecRef.Modify(true);`
  3. `if Resource.ReadPermission() then EmployeeResourceUpdate.HumanResToRes(OldEmployee, Employee);`
- **Every other case, and flag-only writes:** `SourceRecRef.Modify(true)`.

**Labels (all Locked):** `DescriptionTok '%1%2'` (Comment: %1 = table caption, %2 = key values each preceded by a space), `BlockDescriptionTok '%1 (%2)'` (Comment: %1 = description, %2 = address type).

### 15.6 Codeunit 60113 "obcfgav Address Validation" (changes to Part B-22)
**Public procedures** (each guarded one reads the caller as its first statement, Part D-2):

| Procedure | Access | Behaviour |
|---|---|---|
| `SetTransport`, `SetProvider` | public, checked | unchanged |
| `ValidateCustomerAddress(CustomerNo: Code[20])` | public, checked | unchanged signature and behaviour |
| `TryValidateCustomerAddress(CustomerNo: Code[20]; var Outcome; var UserMessage): Boolean` | public, checked | Caller check; `Clear(Outcome); UserMessage := '';` `Customer.SetLoadFields("No.")`; not found → `NoCustomerErr`, false; else `exit(RunValidation(Database::Customer, Customer.SystemId, Enum::"obcfgav Address Type"::Main, Outcome, UserMessage))` |
| **`ValidateAddress(SourceTableNo: Integer; SourceSystemId: Guid; AddressType: Enum "obcfgav Address Type")`** | public, checked (new) | Same as `ValidateCustomerAddress`, on `RunValidation` |
| **`TryValidateAddress(SourceTableNo: Integer; SourceSystemId: Guid; AddressType: Enum "obcfgav Address Type"; var Outcome: Enum "obcfgav Validation Result"; var UserMessage: Text): Boolean`** | public, checked (new) | `exit(RunValidation(...))` |
| `ValuesDiffer` | public | unchanged |
| `CanModifyCustomers(): Boolean` | public | `exit(CanModifySource(Database::Customer))` |
| **`CanModifySource(SourceTableNo: Integer): Boolean`** | public, not checked (read-only) | `GetEffectivePermission(Table Data, SourceTableNo)."Modify Permission" = Yes` |
| `DeliveryWarning` | internal | unchanged |

**`local procedure RunValidation(SourceTableNo; SourceSystemId; AddressType; var Outcome; var UserMessage): Boolean`.** This is B-22's flow with these replacements:
1. `Clear(Outcome); UserMessage := '';`
2. Not `AddressSource.IsSupported` → `UnsupportedSourceErr`, false.
3. `CanModify := CanModifySource(SourceTableNo)`.
4. Not `AddressSource.OpenSource(SourceRecRef, …, false)` → `NoCustomerErr` when the table is 18, else `NoRecordErr`; false.
4a. `AddressSource.IsPrivacyBlocked(SourceRecRef, AddressType)` → `PrivacyBlockedErr`, false. Not logged and nothing sent (FR-17). Applies to Customer too.
5. `CheckPreconditions(SourceRecRef, AddressType, UserMessage)` — same four checks as B-22, reading index 6 (country), 1 (address), 3 (city), 4 (state) and 5 (ZIP) through `AddressSource.GetValue`.
6. Privacy notice (unchanged).
7. `AddressSource.FillOriginal(...)`, then the provider call and `Commit()` (unchanged).
8. Outcome handling unchanged except:
   - `FitsSourceFields(SourceRecRef, AddressType, Buffer, BlockReason)` replaces `FitsCustomerFields` (lengths from `AddressSource.GetLength`, same caption labels);
   - `NoPermissionTxt` for Customer, `StrSubstNo(NoPermissionRecordTxt, SourceRecRef.Caption)` otherwise;
   - `AddressChangedMsg` for Customer, `AddressChangedRecordMsg` otherwise;
   - `RunWriter`, `HandleProviderFailure` and `LogWriteFailure` lose their `CustomerNo` parameter (the identity is in the buffer);
   - (B4) after `RunWriter` returns true with Outcome Confirmed or Not Found, and when `Contact.WritePermission()`: `LinkedSync.Init(SourceTableNo, SourceSystemId, AddressType); if LinkedSync.Run() then Commit() else ClearLastError();` where `LinkedSync` is codeunit 60139. A failure leaves the linked record's flag unchanged and the check complete (F-SC1-03). `Accept` needs no such step: the standard update runs inside the write, as in 1.0.0.0.

Remove `CheckPreconditions(Customer: Record Customer …)`, `FillOriginal(…, Customer)` and `FitsCustomerFields`.

**New labels:**
- `NoRecordErr 'The record was not found.'`
- `UnsupportedSourceErr 'Address validation is not available for this record.'`
- `PrivacyBlockedErr 'Address validation is not available for this record because it is blocked due to privacy.'`
- `AddressChangedRecordMsg 'The address was changed while the suggested address was open, so nothing was updated. Run Validate Address again.'`
- `NoPermissionRecordTxt 'You can''t accept the suggested address because you don''t have permission to change %1 records. Choose OK or Cancel to close without changes.'`, Comment `'%1 = table caption, for example Vendor'`

Every Customer label stays verbatim. 60113 gains `using` nothing new in B1; its B4 edit adds the `LinkedSync` variable.

### 15.7 Codeunit 60118 "obcfgav Validation Writer" (changes to Part B-20; stays `Access = Internal`)
- `using Microsoft.Sales.Customer` removed. Global `AddressSource: Codeunit "obcfgav Address Source"`. Global `CustomerNo` removed.
- `Init(NewOutcome: Enum "obcfgav Validation Result"; var TempResult: Record "obcfgav Address Buffer" temporary; NewAccepted: Boolean; NewCanModify: Boolean)`
- `InsertLogEntry(LogResult: Enum "obcfgav Validation Result"; var TempResult: Record "obcfgav Address Buffer" temporary; LogAccepted: Boolean)`. As B-20, plus `Log."Customer No." := TempResult."Customer No."`, Source Table No., Address Type, Source SystemId and Source Description from the buffer.
- **`WriteAcceptedSuggestion`:**
  1. `if not AddressSource.OpenSource(SourceRecRef, Buffer."Source Table No.", Buffer."Source SystemId", Buffer."Address Type", true) then Error(SourceNotFoundErr, SourceRecRef.Caption);`
  2. If `DiffersFromSnapshot` → AddressChanged / Ignored / not accepted; exit.
  3. `AssignSuggested`; `BindSubscription(WriteGuard); SaveSource(SourceRecRef, AddressType, true); UnbindSubscription(WriteGuard);` (global `WriteGuard: Codeunit "obcfgav Write Guard"`, see 15.13).
- **`SetAddressValidated(NewValue)`:** `if not CanModify then exit`; `OpenSource(..., true)` else the same Error; exit when `GetValidated = NewValue`; `SetValidated`; `SaveSource(..., false)`.
- Label `SourceNotFoundErr 'The %1 record no longer exists, so nothing was updated.'`, Comment `'%1 = table caption'`. Deviation: for a deleted Customer this replaces the platform "does not exist" text.

### 15.8 Table 60111 "obcfgav Address Buffer" (temporary; additive)
- Add: `30 "Source Table No." Integer`, `31 "Address Type" Enum "obcfgav Address Type"`, `32 "Source SystemId" Guid`, `33 "Source Description" Text[250]`. Captions = names.
- Field 2 "Customer No." stays; it is filled only for Customer.

### 15.9 Table 60109 "obcfgav Validation Log" (additive) and page 60110
**Fields added:**
- `24 "Source Table No." Integer` (Caption 'Source Table No.')
- `25 "Address Type" Enum "obcfgav Address Type"` (Caption 'Address Type')
- `26 "Source SystemId" Guid` (Caption 'Source SystemId', `DataClassification = SystemMetadata`)
- `27 "Source Description" Text[250]` (Caption 'Source')
- `28 "Source Table Caption" Text[249]`: `FieldClass = FlowField; CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Table), "Object ID" = field("Source Table No."))); Editable = false;` Caption 'Source Table'. Add `using System.Reflection` (compile-probed).

**Key added:** `SourceCheckedAt("Source Table No.", "Source SystemId", "Checked At")`.

**OnInsert:** `Rec.TestField("Source Table No."); if Rec."Source Table No." = Database::Customer then Rec.TestField("Customer No.");`

Field 2, its TableRelation and key `CustomerCheckedAt` are unchanged.

**Page 60110:**
- After `customerNo`, add `sourceTableCaption` (ToolTip 'Specifies the kind of record whose address was checked, for example Vendor.'), `sourceDescription` (ToolTip 'Specifies the record whose address was checked, by its key.') and `addressType` (ToolTip 'Specifies which address of the record was checked: the main address or the company''s ship-to address.').
- Add `sourceTableNo` with `Visible = false`.
- customerNo ToolTip → 'Specifies the number of the customer whose address was checked. It is blank for other kinds of records.'

### 15.10 Text-only changes
| Object | Control or label | New text |
|---|---|---|
| 60112 | ToolTips of the five Current controls | 'Specifies the … currently on the record.' (street address / second address line / city / state / ZIP Code) |
| 60096 | enabled | '…When it is off, the Validate Address actions do not send any address to Google Maps.' |
| 60096 | usCountryRegionCode | '…Only addresses with this code, or no code, are checked.' |
| 60096 | TestConnection | '…No address is checked and no business data is sent.' |
| 60100 | `AssistedSetupDescriptionTxt` | 'Enter the Google Maps API key used to validate addresses.' Reaches new companies only (registration is insert-if-missing) |

### 15.11 Table extensions (B2, B3). Template = 60116 as built
Every table extension:
- `field(60093; "obcfgav Address Validated"; Boolean) { Caption = 'Address Validated'; DataClassification = CustomerContent; InitValue = false; Editable = false; }`;
- `modify(Address)`, `modify("Address 2")`, `modify(City)`, `modify(County)`, `modify("Post Code")`, each with `trigger OnAfterValidate() begin ResetAddressValidatedIfChanged(); end;`;
- also `modify("Country/Region Code")` (decided OQ-36), which calls the same five-field compare; the country itself does not count. Company Information "Ship-to Country/Region Code" has no OnValidate, so it gets no trigger;
- `local procedure ResetAddressValidatedIfChanged()` exactly as 60116 (exit when false; any of the five fields `<> xRec` → false);
- the `using` = the table's namespace (15.22).

**Company Information (60165):**
- adds `field(60094; "obcfgav Ship-to Validated"; Boolean)`, Caption 'Ship-to Address Validated', with the same properties;
- `modify` on "Ship-to Address", "Ship-to Address 2", "Ship-to City", "Ship-to County" and "Ship-to Post Code" call `ResetShipToValidatedIfChanged()`, which compares those five against xRec;
- the main-block modifies call `ResetAddressValidatedIfChanged()`;
- no modify on "Ship-to Country/Region Code".

### 15.12 Page extensions (B2, B3). Template = 60117 as built
**Each page extension:**
- **Field** `field(obcfgavAddressValidated; Rec."obcfgav Address Validated")`: Caption 'Address Validated'; ToolTip 'Specifies whether the current address was confirmed by, or accepted from, the address validation service. It is set by Validate Address and cleared when the address is edited.'; `ApplicationArea = All; Editable = false;`. Placed at the field anchor in 15.22.
- **Action** `obcfgavValidateAddress`: Caption 'Validate Address'; ToolTip 'Check the address of this record with the address validation service (Google Maps) and accept or ignore the suggested address.'; `Image = CheckList`. (Customer keeps its 1.0.0.0 text.) `OnAction`:
  ```al
  CurrPage.SaveRecord();
  Commit();
  AddressValidation.ValidateAddress(Database::<Table>, Rec.SystemId, Enum::"obcfgav Address Type"::Main);
  Rec.GetBySystemId(Rec.SystemId);
  CurrPage.Update(false);
  ```
- **Promote:** `actionref(obcfgavValidateAddr_Promoted; obcfgavValidateAddress)` at the promote anchor of 15.22.
- **Log action** `obcfgavValidationLog`: Caption 'Address Validation Log'; ToolTip 'View the address validation checks for this record.'; `Image = Log; RunObject = page "obcfgav Log Entries"; RunPageLink = "Source Table No." = const(<table ID literal from 15.22>), "Source SystemId" = field(SystemId); RunPageView = sorting("Source Table No.", "Source SystemId", "Checked At") order(descending);` at the log anchor.
- **var:** `AddressValidation: Codeunit "obcfgav Address Validation";`

**Company Information (60166):**
- second field `obcfgavShipToValidated` (Caption 'Ship-to Address Validated'; ToolTip 'Specifies whether the current ship-to address was confirmed by, or accepted from, the address validation service. It is set by Validate Ship-to Address and cleared when the ship-to address is edited.') after "Ship-to Country/Region Code";
- second action `obcfgavValidateShipToAddress` (Caption 'Validate Ship-to Address'; ToolTip 'Check the ship-to address of the company with the address validation service (Google Maps) and accept or ignore the suggested address.'; passes `::"Ship-to"`), promoted as `obcfgavValidateShipTo_Promoted`;
- one log action covering both blocks.

### 15.13 Write Guard 60120, Address Sync Subscr. 60139
**Codeunit 60120 "obcfgav Write Guard"** (B1; `Access = Internal; EventSubscriberInstance = Manual`). Bound by 60118 around `SaveSource` of an Accept (15.7).
- `using Microsoft.CRM.Contact;`
- `[EventSubscriber(ObjectType::Table, Database::Contact, 'OnBeforeLaunchDuplicateForm', '', false, false)] local procedure SuppressDuplicateForm(var Contact: Record Contact; var IsHandled: Boolean)` → `IsHandled := true;`

Why: for a company contact whose address changed, standard `CheckDuplicates` runs `Modify(); Commit(); LaunchDuplicateForm` when the client can show pages. A commit and a modal page inside our write would break "a failure is logged as Error and nothing is changed" (F-SC1-04). It is a latent case for Customer in 1.0.0.0. The guard is bound only during our own write.

**Codeunit 60139 "obcfgav Address Sync Subscr."** (B4; `Access = Internal`). `SameAddress` helpers compare Address, Address 2, City, County and Post Code. No outside calls, so Standards §9.5 needs nothing. `using Microsoft.CRM.BusinessRelation; Microsoft.CRM.Contact; Microsoft.Sales.Customer; Microsoft.Purchases.Vendor; Microsoft.Bank.BankAccount; Microsoft.HumanResources.Employee; Microsoft.Projects.Resources.Resource;`

**`OnRun` (the linked-record update), after `Init(SourceTableNo; SourceSystemId; AddressType)`.** Runs in 60113 after the check is committed (15.6), for Confirmed and Not Found only:
- Customer → `SetTable(Customer); CustContUpdate.OnModify(Customer)`; Vendor → `VendContUpdate.OnModify(Vendor)`; "Bank Account" → `BankContUpdate.OnModify(BankAccount)`.
- Employee (F-SC1-05): `SetTable(Employee); OldEmployee := Employee; OldEmployee."obcfgav Address Validated" := not Employee."obcfgav Address Validated"; if Resource.ReadPermission() then EmployeeResourceUpdate.HumanResToRes(OldEmployee, Employee);`. The deliberately different old flag makes subscriber g count the flag as a change, so the Resource is updated.
- Any other source: nothing.

**Subscriptions (all verified `IntegrationEvent(false,false)` in Base Application 28.5):**
| # | Subscription | Body |
|---|---|---|
| b | Table Contact `OnBeforeIsUpdateNeeded(var Contact: Record Contact; xContact: Record Contact; var UpdateNeeded: Boolean)` | `if Contact."obcfgav Address Validated" <> xContact."obcfgav Address Validated" then UpdateNeeded := true;` The loop is finite: CustVendBank-Update writes Customer, Vendor and Bank Account with `Modify()` and no trigger |
| c | Table Contact `OnAfterSyncAddress(var Contact; RecContact; var ContChanged; var ContactBeforeModify)` | If the addresses are the same and the flags differ: `Contact.flag := RecContact.flag; ContChanged := true;` |
| d | Table Contact `OnAfterInheritCompanyToPersonData(var Contact; xContact; NewCompanyContact)` | If the addresses are the same: `Contact.flag := NewCompanyContact.flag` (no Modify; the caller saves) |
| e | Codeunit "CustVendBank-Update" `OnAfterUpdateEmployee(var Employee: Record Employee; Contact: Record Contact)` (raised after `Employee.Modify(true)`) | Exit if `Employee."No." = ''`. If the addresses are the same and the flags differ: `OldEmployee := Employee; Employee.flag := Contact.flag; Employee.Modify(false);` then, when `Resource.ReadPermission()`, `EmployeeResourceUpdate.HumanResToRes(OldEmployee, Employee)` |
| f | Codeunit "Employee/Resource Update" `OnAfterUpdateResource(var Resource: Record Resource; Employee: Record Employee)` | If the addresses are the same: `Resource.flag := Employee.flag` (the standard `Res.Modify(true)` follows) |
| g | Codeunit "Employee/Resource Update" `OnAfterCalculateResourceUpdateNeeded(Employee: Record Employee; xEmployee: Record Employee; var UpdateNeeded: Boolean)` | `if Employee.flag <> xEmployee.flag then UpdateNeeded := true;` |

Country/Region reset on Customer is the table extension edit of 60116 (15.11), not a subscriber.

### 15.14 Upgrade and install (Standards Part 9)
**60136 "obcfgav Upgrade Tags"** (`Access = Internal`, `using System.Upgrade`):
- `GetLogSourceTag(): Code[250]` → `'OBCFGAV-SC1-LogSource-20261017'`
- `GetContactFlagTag(): Code[250]` → `'OBCFGAV-SC1-ContactFlag-20261017'` (Locked labels)
- `SetTagsOnInstall()`: each tag `SetUpgradeTag` when not `HasUpgradeTag`
- `[EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerCompanyUpgradeTags', '', false, false)] local procedure RegisterPerCompanyTags(var PerCompanyUpgradeTags: List of [Code[250]])` adds both tags.

**60137 "obcfgav Upgrade Log Source"** (`Subtype = Upgrade; Access = Internal; Permissions = tabledata "obcfgav Validation Log" = rm, tabledata Customer = r; using Microsoft.Sales.Customer, System.Upgrade`):
- `OnUpgradePerCompany`: tag guard, then `UpgradeLogSource()`, then set the tag.
- `UpgradeLogSource`: loop **all** log rows with `FindSet(true)`, no filter on the field being changed. Skip rows with Source Table No. `<> 0` (safety check). Set Source Table No. = `Database::Customer`, Address Type = Main, Source SystemId = `Customer.SystemId` when `Customer.Get("Customer No.")`, Source Description = `Customer.TableCaption() + ' ' + "Customer No."` (`CopyStr` 250). `Modify(false)`.

**60138 "obcfgav Upgrade Contact Flag"** (B3; same tag pattern; `Permissions = tabledata Contact = rm, tabledata Customer = r, tabledata "Contact Business Relation" = r; using Microsoft.Sales.Customer, Microsoft.CRM.Contact, Microsoft.CRM.BusinessRelation, System.Upgrade`):
- Customers with the flag true (SetLoadFields on No., the five address fields and the flag).
- For each, the Contact Business Relation with "Link to Table" Customer and "No.".
- `Contact.Get("Contact No.")`. If the addresses are the same and the Contact flag is false: set it; `Modify(false)`.

**60099 Install:** `OnInstallAppPerCompany` → `SetupRegistration.RegisterAll(); UpgradeTags.SetTagsOnInstall();`. Explicit tags instead of `SetAllUpgradeTags()` (departure from Standards §9.3; decider AJ Ansari, 2026-10-17; reason in the decisions table). The subscriber to `OnGetPerCompanyUpgradeTags` compiles against an `internal` publisher; whether it fires at runtime is proved by test 34 (fresh install, then a new company).

### 15.15 Permission sets
- **60101 USE** adds `codeunit "obcfgav Address Source" = X` (B1), `codeunit "obcfgav Write Guard" = X` (B1), `codeunit "obcfgav Upgrade Tags" = X` (B1) and `codeunit "obcfgav Address Sync Subscr." = X` (B4).
- **60102 ADMIN:** no change.
- No `tabledata` changes in the permission sets, because there is no new table. Users need their normal Business Central permissions on each source table (FR-14); widening our sets would widen their rights.
- The upgrade codeunits carry their own `Permissions` property (15.14), so the installer's rights do not matter.

### 15.16 Events
- **Published:** none new.
- **Subscribed, new:** 15.13 b–g, the Write Guard's `OnBeforeLaunchDuplicateForm`, and Upgrade Tag `OnGetPerCompanyUpgradeTags`.
- **Existing:** `Company-Initialize.OnCompanyInitialize`, unchanged.

### 15.17 Caller check (Part D-2, updated)
The guarded list adds 60113 `ValidateAddress` and `TryValidateAddress`. `CanModifySource` is not guarded (read-only).

### 15.18 Test app
**60124 Test Library, additions:**
- `CreateSource(SourceTableNo: Integer; Address; Address2; City; State; Zip): Guid`:
  - keys `GAVUT<n>` (Code[10] keys fit);
  - parents created first: Customer for Ship-to and Customer Bank Account; Vendor for Order, Remit and Vendor Bank; Employee for Alternative Address; Contact for Contact Alt. Address;
  - `Insert(true)` with the key set so no number series is used.
- `SaveCompanyInformation` / `RestoreCompanyInformation` and `SetCompanyAddress(AddressType; …)`.
- `SaveMarketingSetup` / `RestoreMarketingSetup` / `SetMarketingSetup(BusRelCodes; InheritAddress)`.
- `SetPrivacyBlocked(SourceTableNo; SourceSystemId; Value)`.
- `GetSourceValue`, `ValidateSourceField(SourceTableNo; SourceSystemId; AddressType; FieldIndex)` (via `FieldRef.Validate`), `AssertSourceAddress`, `AssertSourceValidated(SourceTableNo; SourceSystemId; AddressType; Expected)`.
- `LastLogEntryForSource(SourceTableNo; SourceSystemId; AddressType; var Log)`, `AssertLogSource` (table, type, system ID, description contains the key and **not** the record's Name, Customer No. blank unless table 18).
- `InitSetup` remembers the last log Entry No.
- `CleanUp` deletes: log rows above the remembered Entry No.; every `GAVUT*` record of the 15 tables, children first; **the Contacts that standard Business Central created for `GAVUT*` Vendors and Bank Accounts** (found through Contact Business Relation); then restores Company Information and Marketing Setup.

**60129 "obcfgav Source Tests" (Subtype = Test).** Test procedure names are 30 characters or fewer. Source tags: ShipTo, CustBank, Vendor, OrderAddr, RemitAddr, VendBank, CompanyMain, CompanyShipTo, Location, RespCenter, BankAcc, Employee, AltAddr, Contact, ContAltAddr, Resource.
- `TestAccept<Tag>` × 16 and `TestEditResets<Tag>` × 16, where 16 = the 15 new tables plus the company ship-to block (tests 25, 27);
- `TestCompanyBlocksIndependent` (28);
- Vendor tests (26, 29): `TestVendorConfirmed`, `TestVendorNotFoundClears`, `TestVendorIgnoreKeeps`, `TestVendorErrorKeeps`, `TestVendorNonUSRefused`, `TestVendorChangedInDialog` (generic message), `TestLocationTooLongBlocks`;
- `TestUnsupportedSourceRefused` (Item; 36);
- `TestContactPersonValidates`, `TestContactCompanyValidates` (31);
- `TestCustomerLogKeepsCustNo` and `TestLogDescriptionHasNoName` (37, 38);
- `TestPrivacyBlockedCustomer` and `TestPrivacyBlockedChild` (a Ship-to Address of a blocked Customer): refused, nothing sent, nothing logged (40).

**60130 "obcfgav Sync Tests" (B4):**
- `TestCustAcceptUpdatesCont`, `TestVendAcceptUpdatesCont`, `TestBankAccAcceptUpdatesCont`;
- `TestContEditClearsCustFlag` (32);
- `TestCustNotFoundClearsCont`;
- `TestCompanyAcceptFlagsPerson` (31);
- `TestPersonJoinsCompanyFlag` (person linked to a company takes the company's flag; 44);
- `TestPersonAcceptKeepsCompany` (45);
- `TestContAcceptFlagsEmployee`;
- `TestEmpAcceptUpdatesResource` (33) and `TestEmpNotFoundClearsRes` (43);
- `TestLinkedSyncFailureKeeps` (a failing Contact update after Confirmed leaves the check logged and the linked flag unchanged; 41);
- `TestCountryClearResetsFlag` (39);
- the duplicate-form suppression (42) is manual: it needs a client.

The 61 existing tests are expected to pass unchanged (35): they insert no log rows directly, never set Privacy Blocked, and set the country from blank. They still assert on `Log."Customer No."`, which stays filled for customers.

### 15.19 Batch plan (one at a time; lint each, compile once at Step 07 unless OQ-41)
| Batch | Content | Objects / IDs | Behaviour change |
|---|---|---|---|
| B1 Engine | Address Source, Address Type, Write Guard, generic 60113/60118 incl. the Privacy Blocked precondition, buffer and log fields, log page, texts, upgrade (log), tags, install, USE grants, `app.json` (version 1.1.0.0, `idRanges`) | New 60134, 60135, 60136, 60137, 60120. Changed 60096, 60099, 60100, 60101, 60109, 60110, 60111, 60112, 60113, 60118, `app.json` | Customer: Privacy Blocked refusal (OQ-37) and the generic "record no longer exists" text (15.7). Nothing else. Compiles alone (batch 1 compiles alone) |
| B2 Sales and purchasing | 6 sources | 60143–60146, 60152–60159 | New sources only |
| B3 Company/org and people | 9 sources + upgrade contact flag | 60165–60172, 60178–60187, 60138 | New sources only |
| B4 Rest | Linked-record update and subscribers, Customer Country reset, test app | 60139, 60113 (hook), 60116 (edit), 60101 (line), test app 60124 (edit), 60129, 60130 | OQ-35 and OQ-36 (15.23) |

Files edited in two batches (60101, 60113): a recorded exception to the Build Plan rule, safe because batches run one at a time (AJ Ansari, 2026-10-17).

### 15.20 Object Register delta
Add the rows in 15.3. Allocated range 60093–60192. Customer field 60093 is no longer "reserved": it is the shared Address Validated number (OQ-34). Events as in 15.16.

### 15.21 Not verified
1. That TransferFields copies table-extension fields with the same number (tests 32 and 34).
2. That xRec = Rec on code-driven modifies through RecordRef. A duplicate standard update would be harmless. Microsoft's own pattern is `RecRef.Modify(); RecRef.SetTable(Cust); CustContUpdate.OnModify(Cust)` (VATRegistrationLog.Table.al).
3. That `RecordRef.SetTable` followed by a typed `Modify(true)` raises no concurrency error.
4. That the 15.13 b loop ends in practice. Reasoned from the source; covered by test 32.
5. The US captions on the new cards (OQ-19), and that every anchor in 15.22 exists on the **US-localized** pages: the anchors were verified against W1 symbols only. The first US sandbox install of B2 and B3 is the check.
6. That `Contact.WritePermission()` reflects the user's effective rights in a SaaS sandbox.
7. That the `internal` upgrade-tag publisher fires a PTE subscriber at runtime (test 34).
8. That the new ID range does not overlap another per-tenant extension in the target tenant: check Extension Management before the first upload.

**Self-sufficiency:** every object, ID, file, field number, anchor, signature, label and batch is given in §15, including the source reference in 15.22.

### 15.22 Source reference (verified against Base Application 28.5.54151.55594, 2026-10-17)
**Field numbers.** Format: Address / Address 2 / City / County / Post Code / Country. Lengths are 100 / 50 / 30 / 30 / Code 20 / Code 10 in every row.

**Field anchor.** The `pageextension` layout anchor for the Address Validated field.

**Validate / promote / log anchors.** All three compiled in the probe.

**Page namespace.** Equals the table's namespace.

| # | Table (ID), namespace | PK | Field numbers | Card page (ID) | Field anchor | Validate / promote / log anchors | Notes |
|---|---|---|---|---|---|---|---|
| 1 | Customer (18), `Microsoft.Sales.Customer` | No. | 5/6/7/92/91/35 | Customer Card (21) | `addafter("Post Code")` (as built) | `"F&unctions"` / `Category_Process` / `"&Customer"` | Unchanged. Contact family (TransferFields) |
| 2 | Ship-to Address (222), `Microsoft.Sales.Customer` | Customer No., Code (Code[10]) | 5/6/7/92/91/35 | Ship-to Address (300) | `addafter("Country/Region Code")` (group Control3) | `Processing` / `Promoted` / `"&Address"` | No processing area. List 301 |
| 3 | Customer Bank Account (287), `Microsoft.Sales.Customer` | Customer No., Code (Code[20]) | 6/7/8/18/9/17 | Customer Bank Account Card (423) | `addafter("Post Code")` | `Processing` / `Category_Process` / `Navigation` | No processing area. List 424 |
| 4 | Vendor (23), `Microsoft.Purchases.Vendor` | No. | 5/6/7/92/91/35 | Vendor Card (26) | `addafter("Post Code")` | `"F&unctions"` / `Category_Process` / `"Ven&dor"` | Contact family. `SetForceUpdateContact` exists |
| 5 | Order Address (224), `Microsoft.Purchases.Vendor` | Vendor No., Code (Code[10]) | 5/6/7/92/91/35 | Order Address (368) | `addafter("Country/Region Code")` | `Processing` / `Promoted` / `"&Address"` | List 369 |
| 6 | Remit Address (2224), `Microsoft.Purchases.Remittance` | Code (Code[10]), Vendor No. (that order) | 5/6/7/92/91/35 | Remit Address (2368) | `addafter("Country/Region Code")` | `Processing` / `Promoted` / `Location` (nav group name) | List 2369 |
| 7 | Vendor Bank Account (288), `Microsoft.Purchases.Vendor` | Vendor No., Code (Code[20]) | 6/7/8/18/9/17 | Vendor Bank Account Card (425) | `addafter("Country/Region Code")` | `Processing` / `Promoted` / `Navigation` | Page has no actions at all |
| 8a | Company Information (79) main block, `Microsoft.Foundation.Company` | Primary Key (Code[10]) | 4/5/6/31/30/36 | Company Information (1) | `addafter("Country/Region Code")` (General) | `Processing` / `Promoted` / `Navigation` | Insert/Delete not allowed. Country runs the clear (15.11) |
| 8b | Company Information (79) ship-to block | same | Ship-to Address 24 / Ship-to Address 2 25 / Ship-to City 26 / Ship-to County 33 / Ship-to Post Code 32 / Ship-to Country/Region Code 37 | same page | `addafter("Ship-to Country/Region Code")` (Shipping) | second Validate in `Processing`, promoted in `Promoted` | Ship-to Country has no OnValidate |
| 9 | Location (14), `Microsoft.Inventory.Location` | Code (Code[10]) | 5701/5702/5703/5715/5714/5720 | Location Card (5703) | `addafter("Country/Region Code")` | `Processing` / `Category_Process` / `"&Location"` | |
| 10 | Responsibility Center (5714), `Microsoft.Inventory.Location` | Code (Code[10]) | 3/4/5/15/6/7 | Responsibility Center Card (5714) | `addafter("Country/Region Code")` | `Processing` / `Promoted` / `"&Resp. Ctr."` | County is not in a visibility group |
| 11 | Bank Account (270), `Microsoft.Bank.BankAccount` | No. | 5/6/7/92/91/35 | Bank Account Card (370) | `addafter("Country/Region Code")` (Communication) | `Processing` / `Category_Process` / `"&Bank Acc."` | Contact family. No SetForceUpdateContact (15.5 SaveSource) |
| 12 | Employee (5200), `Microsoft.HumanResources.Employee` | No. | 8/9/10/12/11/25 | Employee Card (5200) | `addafter("Country/Region Code")` (Control13) | `"F&unctions"` / `Category_Process` / `"E&mployee"` | Area is named "Processing". Syncs to Resource (15.5, 15.13); receives from Contact (15.13) |
| 13 | Alternative Address (5201), `Microsoft.HumanResources.Employee` | Employee No., Code (Code[10]) | 5/6/7/9/8/14 | Alternative Address Card (5203) | `addafter("Country/Region Code")` | `Processing` / `Promoted` / `"&Address"` | |
| 14 | Contact (5050), `Microsoft.CRM.Contact` | No. | 5/6/7/92/91/35 | Contact Card (5050, ListPlus) | `addlast(Control37)` (Address group) | `"F&unctions"` / `Category_Process` / `"C&ontact"` | Type enum: Company (0), Person (1). Contact family + persons (15.13) |
| 15 | Contact Alt. Address (5051), `Microsoft.CRM.Contact` | Contact No., Code (Code[10]) | 5/6/7/9/8/10 | Contact Alt. Address Card (5056) | `addafter("Country/Region Code")` | `Processing` / `Promoted` / `"&Alt. Contact Address"` | |
| 16 | Resource (156), `Microsoft.Projects.Resources.Resource` | No. | 6/7/8/54/53/59 | Resource Card (76) | `addafter("Country/Region Code")` (Personal Data) | `"F&unctions"` / `Category_Process` / `"&Resource"` | Type: Person / Machine; both validated |

Other objects used, all verified:

| Object | Namespace | Member used |
|---|---|---|
| Codeunit 5056 "CustCont-Update" | `Microsoft.CRM.BusinessRelation` | `OnModify(var Cust)`, public |
| Codeunit 5057 "VendCont-Update" | `Microsoft.CRM.BusinessRelation` | `OnModify(var Vend)`, public |
| Codeunit 5058 "BankCont-Update" | `Microsoft.CRM.BusinessRelation` | `OnModify(var BankAcc)`, public |
| Codeunit 5055 "CustVendBank-Update" | `Microsoft.CRM.BusinessRelation` | events above |
| Codeunit 5200 "Employee/Resource Update" | `Microsoft.HumanResources.Employee` | `HumanResToRes(OldEmployee, Employee)`, public |
| Table 5054 "Contact Business Relation" | `Microsoft.CRM.BusinessRelation` | "Contact No.", "Link to Table" (enum: Customer 1, Vendor 2, "Bank Account" 3, Employee 4), "No."; key ("Link to Table","No.") |
| Table 5079 "Marketing Setup" | `Microsoft.CRM.Setup` | Bus. Rel. Code for Customers 7 / Vendors 8 / Bank Accs. 9 / Employees 10; Inherit Address Details 26 |
| Table 2000000058 AllObjWithCaption | `System.Reflection` | "Object Caption" Text[249] |
| Codeunit 9999 "Upgrade Tag" | `System.Upgrade` | `HasUpgradeTag`, `SetUpgradeTag`, event `OnGetPerCompanyUpgradeTags(var PerCompanyUpgradeTags: List of [Code[250]])` |

**Contact persons and companies:** both are validated identically; there is no Type rule. Persons that inherit the company address follow the company's flag only through the batch 4 sync rules.

**Per-country behaviour:** US-only for every source. The source's (block's) Country/Region Code must be blank or equal to Setup "US Country/Region Code", unchanged.

---

The `const(<ID>)` in each Address Validation Log action's `RunPageLink` is the literal table ID in the first column. The page namespace equals the table's namespace.

### 15.23 Customer changes in 1.1 (the only ones)
| Change | Batch | Source |
|---|---|---|
| Privacy Blocked = Yes refuses validation | B1 | OQ-37 |
| A deleted customer gives "The Customer record no longer exists, so nothing was updated." (generic) instead of the platform's text when the write finds it gone | B1 | 15.7 |
| A Confirmed or Not Found also updates the linked Contact's flag (separate step after commit; a failure leaves it unchanged) | B4 | OQ-35 |
| A Country/Region change that makes BC clear City, State or ZIP resets Address Validated | B4 | OQ-36 |
| The standard duplicate-contact form no longer interrupts an Accept | B1 | F-SC1-04 |

All 1.0.0.0 Customer message texts stay verbatim. The 61 existing tests are expected to pass unchanged (15.18).

---
