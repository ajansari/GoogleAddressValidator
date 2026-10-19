# Build Plan — Google Address Validator (the first plan below is the original USPS build; remediation 07a follows)

> **Renumbered in 1.3.0.0:** object and field numbers in this historical document are the pre-1.3 numbers (60093–60192). `docs/1-define/ObjectRegister.md` gives each object's old and new ID.


**Date:** 2026-10-10 · **From:** `docs/2-design/TDD.md` v1.0 §3 (with §13) · **Approved by:** AJ Ansari, 2026-10-10 (one approval for the whole plan, Operating Rule 6)
**Approval mode:** whole plan once, **all batches in parallel** (chosen by AJ Ansari, 2026-10-10): one background `ocpf-generator` per batch on the Main model (Sonnet 5.5, Medium), light-role pre-flight (Haiku 5.5) on each batch as it returns, the main role integrating. Fast mode: not offered (Main model is Sonnet).

## 1. Scaffold
| Item | Value |
|---|---|
| `app.json` | written at Step 01 §1.10; at Step 05 `idRanges` set to the TDD split `[60093–60122]` and `[60134–60142]` (test app `[60123–60133]`); name, publisher, version `0.0.0.1`, logo, runtime 17.0, features `NoImplicitWith` and `TranslationFile` confirmed current against `docs/1-define/ProjectParameters.md` |
| Folders | `src/Setup/` (module A), `src/Validation/` (module B), `src/logo/`, `Translations/` (no target files: US wording) |
| Test app | separate project at `/Users/ajansari/Documents/AL/USPSAddressValidator.Tests/` with its own `app.json` (id `ebe1c8ca-a413-4f2b-9de7-37d8c1ae4d5a`, name "USPS Address Validator Tests", idRanges `[60123–60133]`, dependency on this app 0.0.0.1), `.vscode/settings.json` analyzers, `.gitignore`, and its own git repository (no commits yet). Its GUID is the `TestAppIdTok` in TDD §13.2 |
| Analyzers (`.vscode/settings.json`) | CodeCop, UICop, PerTenantExtensionCop (SaaS PTE; never AppSourceCop) in both projects |
| `ocpfFramework/scripts/` | `al-analyze.sh`, `al-mcp.sh`, `al-mcp-call.sh`, notify, dashboard and usage scripts present |
| `.gitignore` | Ops § Repository Hygiene block present and verified with `git check-ignore` (Step 01); `Translations/` and `src/` tracked |
| BCQuality snapshot | fetched to `/Users/ajansari/Documents/AL/USPSAddressValidator.bcquality/` (outside the project root), commit `86d809b5252a`, 2026-10-10, LICENSE kept |
| Patterns library | fetched to `ocpfFramework/patterns/` (gitignored), `ajansari/ocpfBCALPatterns` commit `2d5553b5d477`, 2026-10-10, LICENSE kept |
| Translation tooling | N/A — source wording is US, no translation files (Parameters §1.9) |
| Business Central Copilot Blueprint | N/A — no Copilot feature (Parameters §1.6) |
| AL tools and symbols | AL MCP Server answers; BC 28.5 W1 symbols in `.alpackages/` (Standards §Symbols); the test app gets this app's `.app` symbol package at Step 07 |

## 2. Batches
Smallest and simplest first. A batch is independently correct; the whole extension compiles once at Step 07. Batches share no object and no file. Generators never edit the two permission set files (B1) or any other batch's files: they return their grant lines and the main role adds them when it integrates the batch.
| Batch | Module(s) | Objects (ID — type — name → file) | Permission grants introduced | Depends on | Pre-flight owner |
|---|---|---|---|---|---|
| B1 Foundation | A | 60093 — Enum — obcfusps Validation Result → `src/Setup/obcfuspsValidationResult.Enum.al`<br>60094 — Enum — obcfusps USPS Environment → `src/Setup/obcfuspsUSPSEnvironment.Enum.al`<br>60095 — Table — obcfusps USPS Setup → `src/Setup/obcfuspsUSPSSetup.Table.al`<br>60098 — Codeunit — obcfusps USPS Credential Mgt. → `src/Setup/obcfuspsUSPSCredentialMgt.Codeunit.al`<br>60101 — PermissionSet — OBCFUSPS USPS, USE → `src/Setup/OBCFUSPSUSPSUSE.PermissionSet.al`<br>60102 — PermissionSet — OBCFUSPS USPS, ADMIN → `src/Setup/OBCFUSPSUSPSADMIN.PermissionSet.al` | USE: Setup R, Credential Mgt. X · ADMIN: includes USE, Setup RIMD | — | Light role (Haiku 5.5) |
| B2 USPS API | A, B | 60096 — Page — obcfusps USPS Setup → `src/Setup/obcfuspsUSPSSetup.Page.al`<br>60111 — Table — obcfusps USPS Address Buffer → `src/Validation/obcfuspsUSPSAddressBuffer.Table.al`<br>60114 — Codeunit — obcfusps USPS API Client → `src/Validation/obcfuspsUSPSAPIClient.Codeunit.al`<br>60115 — Codeunit — obcfusps USPS Http Transport → `src/Validation/obcfuspsUSPSHttpTransport.Codeunit.al`<br>— — Interface — obcfusps USPS Transport → `src/Validation/obcfuspsUSPSTransport.Interface.al` | USE: Address Buffer RIMD, API Client X, Http Transport X · ADMIN: page Setup X | B1 | Light role (Haiku 5.5) |
| B3 Log | B | 60109 — Table — obcfusps USPS Validation Log → `src/Validation/obcfuspsUSPSValidationLog.Table.al`<br>60110 — Page — obcfusps USPS Log Entries → `src/Validation/obcfuspsUSPSLogEntries.Page.al` | USE: Validation Log Ri, page Log Entries X · ADMIN: Validation Log RD (no M) | B1 | Light role (Haiku 5.5) |
| B4 Validation | B | 60112 — Page — obcfusps USPS Address Compare → `src/Validation/obcfuspsUSPSAddressCompare.Page.al`<br>60113 — Codeunit — obcfusps Address Validation → `src/Validation/obcfuspsAddressValidation.Codeunit.al`<br>60116 — TableExtension — obcfusps Customer → `src/Validation/obcfuspsCustomer.TableExt.al`<br>60117 — PageExtension — obcfusps Customer Card → `src/Validation/obcfuspsCustomerCard.PageExt.al`<br>60118 — Codeunit — obcfusps Validation Writer → `src/Validation/obcfuspsValidationWriter.Codeunit.al` | USE: page Address Compare X, codeunit Address Validation X, codeunit Validation Writer X | B1–B3 | Light role (Haiku 5.5) |
| B5 Onboarding | A | 60097 — Page — obcfusps USPS Setup Wizard → `src/Setup/obcfuspsUSPSSetupWizard.Page.al`<br>60099 — Codeunit — obcfusps USPS Install → `src/Setup/obcfuspsUSPSInstall.Codeunit.al`<br>60100 — Codeunit — obcfusps Setup Registration → `src/Setup/obcfuspsSetupRegistration.Codeunit.al` | ADMIN: page Setup Wizard X, codeunit Setup Registration X | B1, B3 | Light role (Haiku 5.5) |
| B6 Test app | C | 60123 — Codeunit — obcfusps Fake USPS Transport → `../USPSAddressValidator.Tests/src/obcfuspsFakeUSPSTransport.Codeunit.al`<br>60124 — Codeunit — obcfusps Test Library → `../USPSAddressValidator.Tests/src/obcfuspsTestLibrary.Codeunit.al`<br>60125 — Codeunit — obcfusps Validation Tests → `../USPSAddressValidator.Tests/src/obcfuspsValidationTests.Codeunit.al`<br>60126 — Codeunit — obcfusps API Client Tests → `../USPSAddressValidator.Tests/src/obcfuspsAPIClientTests.Codeunit.al`<br>60127 — Codeunit — obcfusps Addr Validated Tests → `../USPSAddressValidator.Tests/src/obcfuspsAddrValidatedTests.Codeunit.al` | none (the test app has no tables or permission set) | B1–B5 | Light role (Haiku 5.5) |

**Patterns read before generating (per batch):** B2 (setup card) and B5 (wizard): Standards Part 11 and `ocpfFramework/patterns/Pattern-NoSeries-Setup-Field-And-Numbering.md` (no number series here: the rules are recorded as not applicable, and nothing is bound to a no-series field). B3, B4 and B6 (anything inserting log or customer records from a reused variable): `Pattern-Init-Does-Not-Clear-Primary-Key.md`. No child lists or list parts exist, so `Pattern-SubPageLink-FilterGroup4.md` is not needed.

## 3. Pre-flight checklist applied to every batch
Copied from `ocpfFramework/runbookSteps/05.md`, both passes; ticked per batch in the ChangeLog entry that closes the batch.

**Pre-generation** (on the TDD's planned names, main role — done at Step 05, 2026-10-10):
- [x] Identifier length ≤ 30: all 24 object names and the interface are ≤ 30 characters including the prefix; field and control identifiers were re-verified at Step 04 (Sanity Check B8, F20 renames).
- [x] Entity/EntitySet names: N/A, no API pages (Sanity Check B14).
- [x] Reserved-keyword scan, localization field-range filter, `ObsoleteState` filter: Sanity Check rows 4, 5 and 8.

**Post-generation** (on the generated files — light role):
- [ ] Required properties present on every object; file named after its object (Standards §1.8; paths in §2 above).
- [ ] No multilanguage (ML) properties and no `TextConst` (Standards §1.7).
- [ ] Translatable text: no string literal in a user-facing message; AA0074 suffixes; a `Comment` on every placeholder label (Standards §8.3–§8.4); composed user text shown through the Locked passthrough label (TDD §13.1.5).
- [ ] API caption locking: N/A (no API pages or queries).
- [ ] Parent–child pages and number-series fields: N/A (none in the design); recorded per batch.
- [ ] `Rec.` qualification (`NoImplicitWith`).
- [ ] No empty triggers, `// TODO` or commented-out code (Standards §1.5).
- [ ] 4-space indentation, no tabs (Standards §1.6).
- [ ] Permission set names from Parameter 1.3, ≤ 20 characters, captions ≤ 30 (Standards §5.4).
- [ ] `tabledata` coverage for every table the batch introduces (Standards §5.3), grant lines returned for the main role to add.
- [ ] Every reference to a standard object, method, property or enum value verified against the symbols (Operating Rule 2, Standards Appendix B).
- [ ] TDD amendments honoured: §13.1 (Commit after the HTTP phase, Writer codeunit 60118, never-raising Try procedure), §13.2 (caller check), §13.3 (SetEncrypted), §13.4 (reset compares five fields), §13.7 (ToolTips, ValuesAllowed, renamed procedures).
- [ ] Enums write `Extensible = false;` explicitly, with value 0 blank where used as a table field (Standards §1.9).

## 4. Deviations expected
Anything already known to differ from the TDD, with its ChangeLog issue.
| Deviation | ChangeLog issue |
|---|---|
| Codeunit 60118 "obcfusps Validation Writer" added to B4 (Sanity Check F1) | 04-1 |
| `app.json` `idRanges` split to leave the test app's block | 04-1 |
| Test app lives in a sibling folder with its own repository (not under this project root) | 03-2 / TDD §11 |

## Before calling this done
- [x] Every Object Register entry is in exactly one batch (24 entries over B1–B6; the interface included).
- [x] Every table's `tabledata` grant ships in the batch that introduces the table (§2).
- [x] The approval is recorded by name and date.

---

# Remediation 07a — CR-1 rework plan (Google Address Validation, full rename)

**Date:** 2026-10-16 · **From:** `docs/2-design/TDD.md` §14 (signed off by AJ Ansari 2026-10-16, with §14 2.17 naming) · **Approval:** pending (asked once for the whole plan, Operating Rule 6)
**Step 0 — mechanical rename, done and compiled (not a batch):** prefix `obcfusps` → `obcfgav`, namespace `OnlyBCFans.GoogleAddress`, App Code `GAV`, permission sets `OBCFGAV GAV, USE/ADMIN`, 26 files renamed per §14 2.17, `app.json` names, versions main **0.0.0.5** / tests **0.0.0.4**, new icon in `src/logo/AppLogo.png`. Both apps compile 0 errors / 0 warnings on the renamed USPS code, so what follows changes behaviour only. Object IDs and field IDs unchanged.
**Rework batches** (spec: TDD §14 2.1–2.14 for content, 2.15 for order; names per 2.17; the existing renamed files are the starting point):
| Batch | Files (new names) | Spec | Depends on |
|---|---|---|---|
| R1 Foundation | `obcfgavAddressProvider.Enum.al` (60094, replaces `obcfgavEnvironment.Enum.al`), `obcfgavSetup.Table.al`, `obcfgavCredentialMgt.Codeunit.al` (one API key, no token code), `OBCFGAVGAVUSE/ADMIN.PermissionSet.al` (setup lines) | 2.2, 2.7, 2.8, 2.12 | — |
| R2 Provider layer | `obcfgavHttpTransport.Interface.al` (generic `Send`), `obcfgavAddressProvider.Interface.al` (new), `obcfgavHttpTransportImpl.Codeunit.al`, `obcfgavAddressBuffer.Table.al`, `obcfgavGoogleAddressClient.Codeunit.al` (60119, new), `obcfgavAddressService.Codeunit.al` (60114, facade), `obcfgavSetup.Page.al` | 2.1, 2.3–2.6, 2.8 | R1 |
| R3 Log | `obcfgavValidationLog.Table.al`, `obcfgavLogEntries.Page.al` | 2.10 | R1 |
| R4 Validation | `obcfgavAddressCompare.Page.al`, `obcfgavValidationWriter.Codeunit.al`, `obcfgavAddressValidation.Codeunit.al`, `obcfgavCustomerCard.PageExt.al` (+ `obcfgavCustomer.TableExt.al` caption check) | 2.10 | R1–R3 |
| R5 Onboarding | `obcfgavSetupWizard.Page.al`, `obcfgavSetupRegistration.Codeunit.al`, `obcfgavInstall.Codeunit.al` (unchanged), `obcfgavValidationResult.Enum.al` (caption) | 2.8, 2.9, 2.11 | R1 |
| R6 Test app | `obcfgavFakeHttpTransport`, new `obcfgavFakeAddressProvider` (60128), `obcfgavTestLibrary`, `obcfgavValidationTests`, `obcfgavProviderTests`, `obcfgavAddrValidatedTests`, test `app.json` | 2.14 | R1–R5 |
Each batch is pre-flighted per Step 05 (both passes, symbol verification) as it returns; the whole extension then compiles once (0/0, analyzers), is packaged as `outputAppPackage/Google_Address_Validator_0.0.0.5.app` with the "Package built:" block, and the test app as `Google_Address_Validator_Tests_0.0.0.4.app`. Step 08–12 checks are re-run on the new build afterwards (Gap Analysis, Code Review, Step 10 documents, Step 11 documents, Step 12).
**Known external uncertainty:** the live Google call (API key, real responses, SKU billed) is unverified until the spike checklist (TDD §14.y); the code uses only fields verified in Google's documentation (FRD §10 table).


---

# SC-1 — Build Plan for version 1.1.0.0 (Step 05, 2026-10-18)

**From:** `docs/2-design/TDD.md` §15 (15.3 objects, 15.19 batches) · **Status:** approved by AJ Ansari, 2026-10-18 (one approval for the whole plan, Operating Rule 6).
**Batch mode:** **one batch at a time** (chosen by AJ Ansari, 2026-10-17). The main role generates each batch itself or through one background `ocpf-generator` at a time (Sonnet 5.5, Medium, the Main model), pre-flights it (light role, Haiku 5.5), integrates, and commits it separately before the next starts. **OQ-41:** after B1 the plan stops for a human-requested compile, package, sandbox install and a run of the 61 existing tests; B2 starts only after AJ Ansari reports the result. Fast mode: not offered (Main model is Sonnet).

## S1. Scaffold
| Item | State |
|---|---|
| `app.json` | Unchanged now (1.0.0.0, `idRanges` `[60093–60122]`, `[60134–60142]`). Batch 1 sets version 1.1.0.0 and `idRanges` `[60093–60122]`, `[60134–60192]` (F-SC1-06) |
| Folders | `src/Sources/` and `src/Upgrade/` created (with `.gitkeep`); `src/Setup/` and `src/Validation/` unchanged |
| Test app | `/Users/ajansari/Documents/AL/USPSAddressValidator.Tests/` (own repository); version 0.0.0.8 with a dependency on main 1.1.0.0 in B4; `idRanges` `[60123–60133]` unchanged |
| Analyzers | `.vscode/settings.json`: CodeCop, UICop, PerTenantExtensionCop (SaaS PTE), unchanged |
| Compile script, `.gitignore`, symbols, AL tools | Present and verified at 1.0.0.0 (`ocpfFramework/scripts/al-analyze.sh`, BC 28.5 W1 symbols in `.alpackages/`) |
| BCQuality snapshot, patterns library | Already fetched for this project (2026-10-10); not refreshed |
| Translation tooling, Copilot Blueprint | N/A (US wording, no translation files; no Copilot feature) |

## S2. Batches (new objects; IDs and paths fixed)
No object and no file appears in two batches, except the two recorded exceptions in S2.1.

### B1 Engine (module D; first, compiles alone)
**New objects (5 rows):**
- 60134 — Enum — "obcfgav Address Type" → `src/Sources/obcfgavAddressType.Enum.al`
- 60120 — Codeunit — "obcfgav Write Guard" → `src/Sources/obcfgavWriteGuard.Codeunit.al`
- 60135 — Codeunit — "obcfgav Address Source" → `src/Sources/obcfgavAddressSource.Codeunit.al`
- 60136 — Codeunit — "obcfgav Upgrade Tags" → `src/Upgrade/obcfgavUpgradeTags.Codeunit.al`
- 60137 — Codeunit — "obcfgav Upgrade Log Source" → `src/Upgrade/obcfgavUpgradeLogSource.Codeunit.al`

**Changed existing files:**
- 60096 — Page — obcfgav Setup → `src/Setup/obcfgavSetup.Page.al` (tooltip text)
- 60099 — Codeunit — obcfgav Install → `src/Setup/obcfgavInstall.Codeunit.al` (set upgrade tags)
- 60100 — Codeunit — obcfgav Setup Registration → `src/Setup/obcfgavSetupRegistration.Codeunit.al` (description text)
- 60101 — PermissionSet — OBCFGAV GAV, USE → `src/Setup/OBCFGAVGAVUSE.PermissionSet.al` (Execute on 60120, 60135, 60136)
- 60109 — Table — obcfgav Validation Log → `src/Validation/obcfgavValidationLog.Table.al` (fields 24–28, key, OnInsert)
- 60110 — Page — obcfgav Log Entries → `src/Validation/obcfgavLogEntries.Page.al`
- 60111 — Table — obcfgav Address Buffer → `src/Validation/obcfgavAddressBuffer.Table.al` (fields 30–33)
- 60112 — Page — obcfgav Address Compare → `src/Validation/obcfgavAddressCompare.Page.al` (tooltips)
- 60113 — Codeunit — obcfgav Address Validation → `src/Validation/obcfgavAddressValidation.Codeunit.al` (RecordRef flow, Privacy Blocked)
- 60118 — Codeunit — obcfgav Validation Writer → `src/Validation/obcfgavValidationWriter.Codeunit.al`
- `app.json` — version 1.1.0.0, `idRanges` `[60093–60122]`, `[60134–60192]`

### B2 Sales and purchasing (modules E, F)
**New objects (12 rows):**
- 60143 — TableExt — "obcfgav Ship-to Address" → `src/Sources/obcfgavShiptoAddress.TableExt.al`
- 60144 — PageExt — "obcfgav Ship-to Address Card" → `src/Sources/obcfgavShiptoAddressCard.PageExt.al`
- 60145 — TableExt — "obcfgav Customer Bank Account" → `src/Sources/obcfgavCustomerBankAccount.TableExt.al`
- 60146 — PageExt — "obcfgav Cust. Bank Acc. Card" → `src/Sources/obcfgavCustBankAccCard.PageExt.al`
- 60152 — TableExt — "obcfgav Vendor" → `src/Sources/obcfgavVendor.TableExt.al`
- 60153 — PageExt — "obcfgav Vendor Card" → `src/Sources/obcfgavVendorCard.PageExt.al`
- 60154 — TableExt — "obcfgav Order Address" → `src/Sources/obcfgavOrderAddress.TableExt.al`
- 60155 — PageExt — "obcfgav Order Address Card" → `src/Sources/obcfgavOrderAddressCard.PageExt.al`
- 60156 — TableExt — "obcfgav Remit Address" → `src/Sources/obcfgavRemitAddress.TableExt.al`
- 60157 — PageExt — "obcfgav Remit Address Card" → `src/Sources/obcfgavRemitAddressCard.PageExt.al`
- 60158 — TableExt — "obcfgav Vendor Bank Account" → `src/Sources/obcfgavVendorBankAccount.TableExt.al`
- 60159 — PageExt — "obcfgav Vendor Bank Acc. Card" → `src/Sources/obcfgavVendorBankAccCard.PageExt.al`

### B3 Company/org and people (modules G, H)
**New objects (19 rows):**
- 60138 — Codeunit — "obcfgav Upgrade Contact Flag" → `src/Upgrade/obcfgavUpgradeContactFlag.Codeunit.al`
- 60165 — TableExt — "obcfgav Company Information" → `src/Sources/obcfgavCompanyInformation.TableExt.al`
- 60166 — PageExt — "obcfgav Company Info. Card" → `src/Sources/obcfgavCompanyInfoCard.PageExt.al`
- 60167 — TableExt — "obcfgav Location" → `src/Sources/obcfgavLocation.TableExt.al`
- 60168 — PageExt — "obcfgav Location Card" → `src/Sources/obcfgavLocationCard.PageExt.al`
- 60169 — TableExt — "obcfgav Responsibility Center" → `src/Sources/obcfgavResponsibilityCenter.TableExt.al`
- 60170 — PageExt — "obcfgav Resp. Center Card" → `src/Sources/obcfgavRespCenterCard.PageExt.al`
- 60171 — TableExt — "obcfgav Bank Account" → `src/Sources/obcfgavBankAccount.TableExt.al`
- 60172 — PageExt — "obcfgav Bank Account Card" → `src/Sources/obcfgavBankAccountCard.PageExt.al`
- 60178 — TableExt — "obcfgav Employee" → `src/Sources/obcfgavEmployee.TableExt.al`
- 60179 — PageExt — "obcfgav Employee Card" → `src/Sources/obcfgavEmployeeCard.PageExt.al`
- 60180 — TableExt — "obcfgav Alternative Address" → `src/Sources/obcfgavAlternativeAddress.TableExt.al`
- 60181 — PageExt — "obcfgav Alt. Address Card" → `src/Sources/obcfgavAltAddressCard.PageExt.al`
- 60182 — TableExt — "obcfgav Contact" → `src/Sources/obcfgavContact.TableExt.al`
- 60183 — PageExt — "obcfgav Contact Card" → `src/Sources/obcfgavContactCard.PageExt.al`
- 60184 — TableExt — "obcfgav Contact Alt. Address" → `src/Sources/obcfgavContactAltAddress.TableExt.al`
- 60185 — PageExt — "obcfgav Cont. Alt. Addr. Card" → `src/Sources/obcfgavContAltAddrCard.PageExt.al`
- 60186 — TableExt — "obcfgav Resource" → `src/Sources/obcfgavResource.TableExt.al`
- 60187 — PageExt — "obcfgav Resource Card" → `src/Sources/obcfgavResourceCard.PageExt.al`

### B4 Sync, Customer reset, test app (module D, test app C)
**New objects (3 rows):**
- 60139 — Codeunit — "obcfgav Address Sync Subscr." → `src/Sources/obcfgavAddressSyncSubscr.Codeunit.al`
- 60129 — Codeunit — "obcfgav Source Tests" → `../USPSAddressValidator.Tests/src/obcfgavSourceTests.Codeunit.al`
- 60130 — Codeunit — "obcfgav Sync Tests" → `../USPSAddressValidator.Tests/src/obcfgavSyncTests.Codeunit.al`

**Changed existing files:**
- 60113 — `src/Validation/obcfgavAddressValidation.Codeunit.al` (linked-update hook; second batch to edit this file)
- 60116 — TableExt — obcfgav Customer → `src/Validation/obcfgavCustomer.TableExt.al` (Country/Region trigger)
- 60101 — `src/Setup/OBCFGAVGAVUSE.PermissionSet.al` (Execute on 60139; second batch to edit this file)
- 60124 — Codeunit — obcfgav Test Library → `../USPSAddressValidator.Tests/src/obcfgavTestLibrary.Codeunit.al` (additions, 15.18)
- test app `app.json` — version 0.0.0.8, dependency on main 1.1.0.0

### S2.1 Files edited in two batches (recorded exception, F-SC1-06)
60101 (B1, B4) and 60113 (B1, B4). Safe because batches run one at a time; AJ Ansari accepted it on 2026-10-17.

## S3. Order and why
B1 first: it generalizes the engine behind the 61 existing tests and compiles alone (field-number constants and `RecordRef.FieldExist`, no forward reference to later batches). B2 and B3 are repeats of one template (`obcfgavCustomer.TableExt.al`, `obcfgavCustomerCard.PageExt.al`) and depend only on B1. B3 holds Company Information (two flags) and the People group, with the upgrade codeunit 60138 that depends on the Contact extension. B4 last: the sync subscribers need the Contact, Employee and Resource extensions from B2 and B3, and the test app needs every source.

## S4. Patterns read before generating
- B1 and B4 (test library `CreateSource` inserts many records from one variable): Standards Part 11 and `ocpfFramework/patterns/Pattern-Init-Does-Not-Clear-Primary-Key.md`: `Init()` before each insert and the key set explicitly.
- No child list, list part, setup page with a number series, or wizard in this scope.

## S5. Pre-flight
The pre-flight checklist of the first plan (section 3 above) applies unchanged, both passes, ticked per batch in the ChangeLog entry that closes the batch. Additions for this scope:
- **Pre-generation (done 2026-10-18):** all 37 new object names and the pair names are ≤ 30 characters including the prefix (checked by script against TDD 15.3); field names `obcfgav Address Validated` and `obcfgav Ship-to Validated` ≤ 30; no API pages.
- **Post-generation, extra checks:** the field number is 60093 (60094 only on Company Information); every `RunPageLink` uses the literal table ID from TDD 15.22; every `using` matches the namespace in 15.22; each page extension attaches to an anchor listed in 15.22; no `Validate` on Accept (direct assignment); the Customer message texts are verbatim; every procedure in `obcfgavAddressValidation` that reads the caller does so as its first statement.
- **Symbols:** every standard object, event and procedure named in TDD 15.13 and 15.22 is checked against the symbols or shipped source before it is used (Operating Rule 2).

## S6. Deviations expected
| Deviation | ChangeLog issue |
|---|---|
| Explicit upgrade tags instead of `SetAllUpgradeTags()` (Standards §9.3) | SC-1c |
| Growth buffers below Standards §5.2 in modules B (2) and D (3), pooled spare 31 | SC-1c |
| 60101 and 60113 edited in B1 and B4 | SC-1c |
| Customer behaviour changes in 1.1 (TDD 15.23) | SC-1a, SC-1c |

## Before calling this done
- [x] Every object in TDD 15.3 is in exactly one batch with its ID and file path (37 main-app IDs plus the two test codeunits); shared files are the two recorded exceptions.
- [x] No tabledata grant is needed (no new table).
- [x] Approval of the whole plan: AJ Ansari, 2026-10-18.
