# Functional Requirements Document — USPS Address Validator

**Version:** 2.0 DRAFT, CR-1 amendments in §10 pending sign-off (1.2 was signed off; FR-4 / test 12 clarified 03-2; FR-2, FR-5, FR-7, FR-8, §7.2 aligned with TDD decisions, ChangeLog 04-1) · **Date:** 2026-10-10 · **Author:** Reasoning role (Opus 5.5), for AJ Ansari · **Sign-off:** Dev Manager — AJ Ansari, 2026-10-10
**Sources:** `docs/1-define/ProblemStatement.md`, the PRE-02 expanded entity list and gap log, `docs/1-define/ProjectParameters.md`; behaviour from `requirements/USPS Address Validation for Business Central — PTE spec.md` and `requirements/scope-additions-2026-10-10-requirements.md`.

## 1. Purpose and scope
People type customer addresses into Business Central by hand, so many are wrong or inconsistent: misspelled cities, long-form street names, ZIP codes without the +4. USPS Address Validator lets a user who is maintaining a customer check that customer's main address against the United States Postal Service (the free USPS Addresses 3.0 service). The user sees the Business Central address and the USPS version side by side and accepts the USPS version with one click, or ignores it. Every check that reaches USPS is logged, so there is a record of who checked which customer, when, what was sent, what USPS answered and whether the suggestion was accepted. A read-only **Address Validated** indicator on the customer shows whether the current address has been confirmed by USPS or accepted from USPS. An administrator sets the service up once per company, and an Assisted Setup wizard helps them enter the USPS credentials. Expected result: cleaner US customer addresses for mailing and shipping, with an audit trail, and use of the USPS service that stays within its quota and its terms.

### 1.1 Out of scope
- **Automatic validation when an address is entered or saved, and batch or scheduled validation of many customers.** Excluded on purpose. The USPS hourly quota makes them impractical, and the USPS terms prohibit using the API to build or clean address lists.
- **Non-US addresses.** USPS validates US addresses only.
- **Ship-to Addresses, Vendors, Contacts (as their own validation target) and sales documents.** These are candidates for a later version (see §6.1).
- **Geocoding, residential/commercial rating and tax area updates.** Not in the spec. The resulting Tax Area Code limitation is described in §6.1.
- **Adding accepted ZIP codes to the Business Central Post Code table.** Spec default: no.
- **Showing or writing a USPS firm name.** Spec default: not shown, not written.
- **Updating open sales or service documents when a USPS address is accepted** (PRE-02, Standards §6.2). Accept changes the customer only. Open documents keep the address they were created with, and posted documents keep the address they were sent to.
- **The Validate Address action on the Customer List** (PRE-02 G4). Deferred, see §6.1.
- **Showing Address Validated anywhere other than the Customer Card.** It was not requested at Step 01. It can be added later if asked for.
- **Translations.** English (United States) only (§8).

### 1.2 Functional requirements

#### FR-1 Validate Address (USPS) action
1. The Customer Card has a **Validate Address (USPS)** action. It is promoted, and it also appears under Actions > Functions.
2. When the user chooses it, any unsaved changes on the card are saved first. This makes sure the address USPS checks is the one on screen (acceptance test 13).
3. The action then checks these preconditions in order and stops with the matching message from FR-7 if one fails. **Nothing is sent to USPS and nothing is logged when a precondition fails:**
   - The service is enabled and the USPS credentials are present.
   - The customer's country is US. A blank Country/Region Code, or the US country/region code configured in setup, counts as US. Anything else gets the US-only message.
   - Address is filled in, plus either City and State or the ZIP Code.
   - State, when filled in, is a 2-letter USPS state code.
4. The extension gets an access token, reusing the cached one if it is still valid, and asks USPS to validate the address. The request never includes the customer's name or number.
5. It compares the USPS address with the Business Central address (FR-3) and shows one of the outcomes in FR-2.
6. Every check that reaches USPS writes **exactly one** log entry, whatever the outcome (FR-5).

#### FR-2 Outcomes
| Outcome | What the user sees | Customer address updated | Address Validated | Log result |
|---|---|---|---|---|
| USPS address equals the BC address (including when only letter case differs) | Message: the address is confirmed by USPS, no changes | No | Set to **Yes** | Confirmed |
| USPS address differs | Comparison dialog (FR-4) with Accept and Ignore | Only on Accept | **Yes** on Accept; **unchanged** on Ignore | Suggestion Accepted or Suggestion Ignored |
| USPS finds no match, or several matches | Message with the USPS reason text | No | Reset to **No** if it was Yes, for a user who is allowed to modify customers (OQ-15) | Not Found |
| Quota exceeded, credential, network, server or parse error | Error message with the next step (FR-7) | No | Unchanged (OQ-15) | Error |

When the result is Confirmed, the customer's **address fields** are not changed. Only the Address Validated indicator is set. This is a change from the spec's original "customer not updated", made by the Step 01 scope addition (Parameters §1.6a).

#### FR-3 What counts as different
- Each value is compared after trimming spaces and ignoring upper/lower case.
- If only letter case differs, the outcome is **Confirmed** and no dialog is shown.
- A new ZIP+4 on a 5-digit ZIP counts as a difference, so the dialog is shown (spec default; OQ-3).
- The five values compared are Address, Address 2, City, State and ZIP Code.

#### FR-4 Comparison dialog
- A modal dialog with two read-only columns: **Current (BC)** on the left and **USPS suggestion** on the right. The rows are Address, Address 2, City, State and ZIP Code. Values that changed are shown in **bold**.
- Below the grid, the dialog shows any USPS delivery notes:
  - A missing or unconfirmed suite/apartment number (delivery-point confirmation D or S).
  - Address not confirmed (N).
  - Vacant address.
  - Business address.
  - Any correction or match text USPS returns.
- For delivery-point confirmation D, S and N the dialog shows a warning line but **Accept stays available**.
- **Accept USPS Address** writes the five USPS values to the customer exactly as USPS returns them (upper case), sets Address Validated to Yes, and closes the dialog.
- **Ignore** closes the dialog and changes nothing. Closing with X or Esc counts as Ignore.
- **Accept is not possible** for a user who isn't allowed to modify customers. That user can still run the check and see the dialog, which shows why Accept is unavailable; pressing OK then closes the dialog as Ignore (acceptance test 12). The comparison dialog is a standard dialog: OK means Accept USPS Address, and Cancel, X and Esc mean Ignore.
- **Accept is blocked with a message**, and nothing is truncated, if a USPS value is longer than the customer field can hold. City and State hold at most 30 characters.
- **Accept stops with a message** if someone else changed the customer's address while the dialog was open.
- When Accept is disabled or blocked (no permission to modify customers, a value too long, or the address changed meanwhile), nothing is written to the customer and the log entry is **Suggestion Ignored** with Accepted = No (OQ-21, decided).
- On Accept, the standard ZIP-code lookup must **not** replace the USPS city or ZIP with values from the Post Code table. The values written are exactly the ones USPS returned.
- The ZIP Code is written as `12345-6789`, or as `12345` when USPS returns no +4.
- The USPS call and the dialog both happen **before** anything is written. The customer update and the log entry are then saved together, so either both are saved or neither is.

#### FR-5 Processing log
- Each entry records:
  - an entry number;
  - the customer;
  - when the check ran ("Checked At", shown to each user in their own time zone);
  - the user who ran it;
  - the result (Confirmed, Suggestion Accepted, Suggestion Ignored, Not Found, Error);
  - whether the suggestion was accepted (Yes/No);
  - the five original address values sent;
  - the five USPS values, which are blank for Not Found and Error;
  - the delivery-point confirmation (Y, D, S, N);
  - the match and correction codes;
  - the USPS message (match, correction or error text);
  - the HTTP status (0 when there was no response);
  - the environment (Production or Test).
- The log never stores tokens, credentials or request URLs.
- The log is **read-only for everyone**. Entries can't be edited. Only administrators (the ADMIN permission set) can delete entries, and normally only through Retention Policy.
- The log page shows the newest entries first. The Customer Card has a **USPS Validation Log** action that opens the log filtered to that customer.
- The log is registered with Retention Policy. Default retention is 2 years, set up as a custom retention period because Business Central's standard periods have no 2-year value (OQ-8, decided). The retention policy is created **disabled** on install; an administrator enables it in Retention Policies, where the period can also be changed (decided 2026-10-10).
- For a check that ends in an error, the log entry is saved **before** the error message is shown, so it survives the failure.
- Data classification: Customer Content, except the user, which is End-User Identifiable Information.
- Deleting a customer does not delete its log entries.

#### FR-6 Setup
- **Setup card** (one per company):

  | Setting | Default | Notes |
  |---|---|---|
  | Enabled | No | While this is off, the Customer Card action reports that setup is incomplete. |
  | Environment | Test (TEM) | Production or Test (TEM). The Test environment still uses the production credentials, and the card must make that clear. |
  | Consumer Key | (blank) | Shown masked. |
  | Consumer Secret | (blank) | Write-only; never shown after it is entered. |
  | US Country/Region Code | US | |
  | Timeout (seconds) | 10 | |

- The USPS credentials are stored in Business Central's isolated storage for the company, as secrets. They are never stored in a table field and never appear in the log, telemetry, messages or the debugger.
- **Test Connection** asks USPS for a token and reports success or the USPS error. It does not call the address service, so it uses none of the address quota.
- The access token is cached for the company, shared by all users, and kept until 60 seconds before it expires. The expiry comes from what USPS returns, never from a fixed lifetime.
- Changing the Consumer Key, Consumer Secret or Environment clears the cached token.
- **Assisted Setup wizard** (Step 01 addition): a guided page, listed in Business Central's Assisted Setup, where an administrator enters **only the Consumer Key and Consumer Secret**. The same storage, masking and token-clearing rules apply. The wizard does **not** set the environment, enable the service or run Test Connection; those stay on the setup card (Parameters §1.6). The credentials can also still be entered and changed on the setup card; the wizard is the guided first-time path. The wizard counts as completed in Assisted Setup once both values are saved (OQ-16, decided).

#### FR-7 Error handling
No failure changes the customer. Every failure that happens after the preconditions are met is logged.

| Condition | Message to the user | Logged as |
|---|---|---|
| Setup disabled or credentials missing | USPS address validation is not set up. Contact your administrator. | Not logged |
| Customer country is not US | USPS validates US addresses only. | Not logged |
| Address blank, or both City/State and ZIP Code blank | Enter a street address and either city and state or ZIP Code. | Not logged |
| State is not a 2-letter code | Enter the 2-letter state code in the State field. | Not logged |
| USPS rejects the request (HTTP 400) | "USPS could not read the address:" + USPS message | Error |
| No match, insufficient data, invalid delivery address or multiple matches (HTTP 404) | "USPS could not find this address:" + USPS message | Not Found |
| Credentials rejected (401/403) after one token refresh | USPS rejected the credentials. Contact your administrator. | Error |
| Hourly quota reached (429) | The hourly USPS limit has been reached. Try again later. | Error |
| USPS server error (5xx), timeout or no connection | USPS is not responding. Try again later. | Error |
| Response can't be read | Unexpected response from USPS. Contact your administrator. | Error |

- The only automatic retry is a single token refresh after a credentials rejection on the address call. A failing check therefore cannot use up the quota.
- The response is read field by field by name. Missing or extra fields are tolerated, because USPS can change its formats without notice.
- When USPS returns an error, the user sees the USPS error message and the log stores it.
- If saving the customer fails after USPS answered (for example the linked Contact cannot be updated, or a permission or another extension stops the save), the customer stays unchanged, the check is logged as **Error** with the failure text, and the user sees that text (decided 2026-10-10).

#### FR-8 Address Validated (Step 01 addition, Parameters §1.6a)
- A Yes/No indicator on each customer, shown on the Customer Card in the **Address** group of the **Address & Contact** FastTab.
- Default **No** for every new customer. Customers that already exist when the extension is installed also start at No.
- **Users can't edit it.** Only the extension changes it.
- Set to **Yes** when a check ends in **Accept** or **Confirmed**. For a user who is not allowed to modify customers, Confirmed does **not** set it (OQ-21).
- Reset to **No** when a check on a customer ends in **Not Found**, for a user who is allowed to modify customers (OQ-15; for other users it stays unchanged, decided 2026-10-10). Errors (quota, credentials, network, server, parse) leave it unchanged.
- **Unchanged** when the user chooses **Ignore**, closes the dialog, Accept is disabled, Accept is blocked (value too long, or the address changed while the dialog was open), or the check ends in an Error. If it was No it stays No; if it was Yes it stays Yes.
- Reset to **No** when a validated customer's Address, Address 2, City, State or ZIP Code is edited by a user afterwards (OQ-14, decided). Country/Region Code does not count. Edits that write the fields without the standard field validation (some imports and integrations) may not be detected; this is a known limitation.
- The extension's own Accept does **not** count as an edit. After Accept the value is Yes.

#### FR-9 Side effects of updating the customer (recorded so they are not mistaken for defects)
- **Contact address sync (PRE-02 G3).** When the customer is saved through the standard update, Business Central also keeps the linked Contact (business relation) in step. Accepting a USPS address is therefore expected to update the linked Contact's address too. See OQ-12; partly verified, §4.1.
- **Change Log (PRE-02 G6).** If the Change Log is turned on for customers, it records the Accept as a field change. The same applies to Address Validated changes on Confirmed or Accept.
- **Last Date Modified.** This changes on Accept, and on Confirmed when Address Validated changes.
- **Open documents** are not updated (§1.1).
- **Tax Area Code** is not re-evaluated (§6.1).

## 2. Business objectives and value
| # | Objective | Value delivered | Measured by |
|---|---|---|---|
| O1 | Correct, consistently formatted US customer addresses | Fewer returned or misdelivered mailings and shipments; addresses in USPS standard form with ZIP+4 | Share of checks ending Confirmed or Suggestion Accepted; acceptance tests 1–2 |
| O2 | One-click correction without retyping | Faster maintenance and no typing errors when the USPS version is accepted | Accept writes all five values exactly as returned (test 2) |
| O3 | Auditability | Each check shows who, when, what was sent, what USPS answered and the decision | One log entry per check that reaches USPS (tests 1–9) |
| O4 | Stay within USPS quota and terms | Continued free access to the USPS service | On-demand checks only, no batch, no retries beyond one token refresh (test 9); terms question OQ-1 answered before build |
| O5 | Quick, safe onboarding | An administrator can enter credentials without exposing them | Wizard listed in Assisted Setup; secret never displayed after entry (tests 14, 21) |
| O6 | Visible validation status | Users can see whether a customer's current address has been validated | Address Validated follows FR-8 (tests 15–20) |

## 3. Target consumers
| Consumer | Kind (user / system / AI tool / report) | What they need from the extension |
|---|---|---|
| Staff who maintain customers | User | The Validate Address action, the outcome messages, the comparison dialog with Accept/Ignore, the Address Validated indicator, and the per-customer log action. Needs the USE set plus their normal permission to modify customers (needed for Accept). |
| Administrators | User | The setup card (enable, environment, timeout, US code, Test Connection), the Assisted Setup wizard for the credentials, log deletion and Retention Policy. Needs the ADMIN set. |
| Auditors / compliance | User | Read-only access to the processing log: who, when, what was sent, what USPS answered, whether it was accepted (see OQ-11 on the permission set). |
| USPS Addresses 3.0 API | System (external provider) | Receives at most one token request and one address request per check, never the customer name or number. |
| Retention Policy (standard BC) | System | Deletes old log entries on the configured schedule. |
| Automated test app | System (test) | A way to simulate USPS responses so automated tests never use the USPS quota (OQ-17). |
| Reports, BI tools, AI tools | — | None in this version. The log is available on a standard list page only. |

## 4. Platform requirements
From Parameters §1.1 and §1.4:
- **Deployment:** Business Central online, per-tenant extension (SaaS PTE). Publisher OnlyBCFans. Namespace OnlyBCFans.USPSAddress.
- **Version:** Business Central 2026 release wave 1 (28.0) minimum; recommended 28.5. AL runtime 17.0.
- **Localization:** United States. The customer address fields the extension reads and writes are the same in every localization. Validation itself is only meaningful for US addresses.
- **Symbols used for design:** BC 28.5 W1 symbols (System Application, Base Application, Application). Any US-specific caption or field must be checked against a US sandbox before design relies on it (OQ-19).
- **Outbound internet access:** the environment must allow this extension to make outbound HTTP calls ("Allow HttpClient Requests" in Extension Management). Sandboxes, especially ones copied from production, can block them.
- **Dependencies:** Microsoft apps only (System Application, Base Application). The test app depends on this app.
- **Object IDs:** 60093–60142 for both apps (Parameters §1.2).

### 4.1 Verified platform capabilities
Checked on 2026-10-10. Symbols come from `.alpackages/` (BC 28.5 W1), read through the AL MCP Server (`al_symbolsearch`, `al_inspectpage`) and by reading the packages' symbol reference directly. Microsoft Learn was used only where the symbols can't answer, which is the case for built-in AL data types.

| # | Capability the FRD relies on | Verified? | How checked | Result and consequence |
|---|---|---|---|---|
| a | Customer has Address, Address 2, City, County, Post Code and Country/Region Code at the spec's lengths | **Yes** (W1) | Symbols: Customer table fields | Address 100 characters, Address 2 50, City 30, County 30, Post Code 20, Country/Region Code 10. These match the spec. In W1 the captions are "County" and "Post Code". The County caption comes from the customer's Country/Region and its "County Name" setting (both found in the symbols). The **US captions "State" and "ZIP Code" are not verified** because only W1 symbols are available (OQ-19). |
| b | An extension can call the USPS service over HTTPS, and sandboxes can block it | **Yes** (Learn and symbols) | Learn, "Call external services with the HttpClient data type" (updated 2026-06-11). Symbols: "Allow HttpClient Requests" field on the system NAV App Setting table | Calls must be allowed per extension through Extension Management > Configure > Allow HttpClient Requests. The user waits while each call runs, which bounds the timeout. Calls to internal IP addresses are blocked online; this doesn't affect USPS, which is public. Learn's wording ("blocked by default") doesn't state the production default (OQ-20). |
| c | Credentials kept as secrets in isolated storage, per company | **Yes** (Learn and symbols) | Learn: storing a secret value in isolated storage is available from runtime 13.0; the storage scopes are Module, Company, User and CompanyAndUser. Symbols: the secret text type is used throughout the System Application (for example, Azure Functions OAuth2) | Supported on runtime 17.0. Company scope exists. Isolated storage is per app, so the test app can't read this app's stored values directly (a TDD matter). |
| d | A wizard from an extension can be registered in Assisted Setup | **Yes** (symbols) | Symbols: System Application "Guided Experience" codeunit (public) with Insert Assisted Setup (object type and ID, setup group), Complete Assisted Setup and Is Assisted Setup Complete; Guided Experience Type includes "Assisted Setup"; the Assisted Setup Group enum is extensible; the wizard (NavigatePage) page type exists in System Application pages | Supported. |
| e | A custom log table from an extension can be registered with Retention Policy | **Yes** (symbols) | Symbols: "Reten. Pol. Allowed Tables" (Add Allowed Table with default date field and table filters; a table-filter helper that takes either a standard retention period or a date formula); Retention Period table with a "Ret. Period Calculation" date formula | Supported. **The standard periods include no "2 Years" value** (Never Delete, Custom, 1 Week, 28 Days, 1/3/6 Months, 1 Year, 3 Years, 5 Years). A 2-year default needs a custom period (OQ-8). |
| f | A modal dialog page type exists for the comparison | **Yes** (symbols) | Symbols: 91 Base Application pages use the StandardDialog page type (for example "Schedule a Job") | Supported. |
| g | A Yes/No field added to Customer by an extension can be shown read-only on the Customer Card in the address area | **Yes** (symbols) | Symbols: Customer table and Customer Card are not marked non-extensible. Customer Card layout: FastTab "Address & Contact" contains the group "Address" (Address, Address 2, Country/Region Code, City, County, Post Code, map link). The action group "Functions" and a promoted "Process" category exist. Standard Customer already has a read-only field, Last Date Modified | Supported. The FastTab is named **Address & Contact**, and the field goes in its **Address** group. |
| h | Customer save syncs the linked Contact (G3) | **Partly** | Symbols: "CustCont-Update" codeunit with an On Modify (customer) method exists. The call from the customer's save logic is in code, which symbols don't show | Recorded in FR-9 as expected behaviour. To be confirmed in a sandbox at Step 07/08. |
| i | Change Log can record customer field changes (G6) | **Yes** (existence) | Symbols: "Change Log Management" codeunit with Change Log Entry insert rights | Whether anything is recorded depends on each company's Change Log setup. |
| j | Customer carries a Tax Area Code (6.6) | **Yes** (W1) | Symbols: Customer Tax Area Code and Tax Liable fields | The limitation in §6.1 is real. |
| k | Automated tests can simulate USPS responses without calling USPS | **Not in a SaaS sandbox through the platform feature** | Learn, "Mock outbound HttpClient web service calls during testing" (v26+): "This feature is only supported in Business Central on-premises." | The FRD keeps the requirement (tests never use the USPS quota). How it is met (a replaceable HTTP layer in the app, or running tests in an on-premises container) goes to the TDD. See OQ-17. |
| l | Checked At is shown in each user's own time zone | **Not verified from symbols** (a platform behaviour of date-time values, not a symbol) | Taken from the spec | Acceptance test 11 checks it manually in a sandbox. |

## 5. Design rules
The constraints every object must follow:
- **One customer per user action.** No automatic, background, batch or scheduled validation. *Source: spec; USPS terms.*
- **Store USPS values exactly as returned** (upper case, no reformatting). **Never truncate.** If a value doesn't fit, Accept is blocked. *Source: spec; USPS terms.*
- **No failure changes the customer.** Every check that reaches USPS writes exactly one log entry. Nothing is written until the USPS call and the dialog have finished. *Source: spec.*
- **Secrets stay secret.** Credentials and tokens are never stored in a table field. They never appear after entry, or in the log, telemetry, messages or debugger output. *Source: spec.*
- **No retries** apart from one token refresh. *Source: spec.*
- **All USPS-specific logic in one place**, so the address provider can be replaced if USPS withdraws the free service. *Source: spec, risk mitigation.*
- **The customer's name and number are never sent** to USPS. *Source: spec.*
- **Address Validated is changed only by the extension**, under the rules in FR-8. *Source: Parameters §1.6a.*
- **Extend, never modify, standard objects.** The Customer table and Customer Card are extended. *Source: Standards §10.1 (heading "Subscribe; Never Modify").*
- **Mutability follows the data** (Standards §2.2): setup is editable (administrators only); the log is an audit table and read-only to everyone; the customer is master data and is written only by Accept or Confirmed, and only the five address values plus Address Validated.
- **Permission sets are deliverables.** Every table the extension owns is granted in the sets, and the sets are named with the prefix and App Code `USPS`, within 20 characters (Standards §5.3, §5.4; Parameters §1.3). Users also need their normal customer permissions; the extension's sets cover only the extension's own objects (Standards §5.3 deployment note). Naming is OQ-11.
- **Identity.** Every object name starts with the prefix `obcfusps` and stays within 30 characters. The namespace is OnlyBCFans.USPSAddress. Object names in §6 are indicative; final names are set in the TDD (Parameters §1.3).
- **IDs** come from 60093–60142 for both apps, with at least 10 IDs kept unallocated (Parameters §1.2; Standards §5.2).
- **Enums, not options**, and each enum's extensibility is a recorded decision (Standards §1.9, heading).
- **US wording**, with all user-facing text as labels and no translation files (Standards §1.7, heading; Parameters §1.9).

## 6. Entity and object inventory
Read vs. read/write per Standards §2.2. Names are indicative only (TDD finalizes them with the `obcfusps` prefix and the 30-character limit). "US" means the object is only meaningful for US addresses.

| Entity | Source table (name) | Object type(s) | R / RW | Global or localized | Notes |
|---|---|---|---|---|---|
| USPS validation setup | USPS Addr. Validation Setup (new) | Table | RW | Global | Single record per company. Settings in FR-6. Credentials are **not** stored here (isolated storage). Administrators only. |
| USPS validation setup card | USPS Addr. Validation Setup | Page (Card) | RW | Global | Includes Test Connection. Secret is write-only and the key is masked. Administrators only. |
| USPS assisted setup wizard *(Step 01)* | USPS Addr. Validation Setup / isolated storage | Page (guided wizard) | RW | Global | Consumer Key and Secret only. Listed in Assisted Setup. Administrators only. |
| USPS validation log | USPS Addr. Validation Log (new) | Table | R (inserted by the extension only) | Global | One entry per check that reaches USPS. Audit data, so never edited. Deleted only by ADMIN or Retention Policy. |
| USPS validation log list | USPS Addr. Validation Log | Page (List) | R | Global | Newest first. Also opened from the Customer Card, filtered to that customer. |
| USPS address comparison | (temporary; no stored data) | Page (modal dialog) | R | US | Current vs. USPS columns, changes in bold, delivery notes, Accept/Ignore. |
| Validation result | — | Enum | — | Global | Confirmed, Suggestion Accepted, Suggestion Ignored, Not Found, Error. |
| USPS environment | — | Enum | — | Global | Production, Test (TEM). |
| Customer: Address Validated *(Step 01)* | Customer (standard) | Table extension | RW (written by the extension only) | US | Default No; read-only to users; rules in FR-8. |
| Customer Card | Customer (standard) | Page extension | RW (on Accept/Confirmed only) | US (action refuses non-US) | Validate Address (USPS) action (promoted and under Functions); USPS Validation Log action; Address Validated shown read-only in the Address group of Address & Contact. |
| Address validation (orchestration) | Customer, setup, log | Codeunit | RW | US | Preconditions, comparison, dialog, update, logging, Address Validated rules. |
| USPS API client | — | Codeunit | — | US | Token handling and cache, the two HTTPS calls, tolerant reading of responses. The only place with USPS-specific logic. |
| Install | Retention Policy (standard) | Codeunit | W (registration) | Global | Registers the log with Retention Policy (2-year default, OQ-8). Wizard registration in Assisted Setup goes wherever the TDD decides. |
| Permission set USE | — | Permission set | — | Global | Run the action and the dialog, record log entries, read the log. Proposed name `OBCFUSPS USPS, USE` (OQ-11). |
| Permission set ADMIN | — | Permission set | — | Global | Setup, wizard, credentials, log deletion. Proposed name `OBCFUSPS USPS, ADMIN` (OQ-11). |
| Test app *(PRE-02 G7)* | — | Separate AL test extension: simulated USPS responses and test codeunits | — | — | Covers acceptance tests 1–10 and 12, plus the proposed 15–20. Depends on this app. IDs carved from 60093–60142 in the TDD. Simulation approach is OQ-17. |
| Customer (existing) | Customer | Standard | RW | Global | Reads the five address values and Country/Region Code. On Accept writes Address, Address 2, City, County (State) and Post Code (ZIP Code). Writes Address Validated on Accept/Confirmed. |
| Country/Region (existing) | Country/Region | Standard | R | Global | Used to decide whether the customer is US (blank or the configured code). |
| Post Code (existing) | Post Code | Standard | R (not written) | Global | Accepted ZIPs are not added. The standard ZIP lookup must not override USPS values on Accept. |
| Contact (existing) | Contact | Standard | W (indirect, through the standard customer→contact sync) | Global | Not a validation target. The address may follow the customer (FR-9, OQ-12). |
| Isolated storage (platform) | — | Platform storage | RW | Global | Credentials and cached token, company scope, as secrets. |
| Retention Policy (existing) | Retention Policy tables | Standard | W (registration) | Global | Log clean-up. |

### 6.1 Deferred entities
| Entity | Reason deferred | Revisit at |
|---|---|---|
| Tax Area Code on Customer (Standards §6.6) | The spec puts tax-area updates out of scope. **Known limitation:** accepting a different ZIP or state doesn't re-evaluate the customer's Tax Area Code, which can leave it stale. The user has to review it by hand. | Version 2 scoping; acceptability is OQ-13 |
| Validate Address on the Customer List (G4) | The spec scopes the Card only. It can be added later using the same logic. | Version 2 scoping |
| Ship-to Address and Vendor validation (G5) | Spec: later version, same logic. | Version 2 scoping (spec OQ, OQ-10) |

## 7. Non-functional requirements
- **Compilation:** 0 errors, 0 warnings with the analyzers (Operating Rule 5), for both the app and the test app.
- **Performance:**
  - At most two HTTPS calls per check (a token only when the cached one has expired, and one address call).
  - Configurable timeout, default 10 seconds. The user waits while the call runs.
  - Two checks within the token lifetime make only one token request (test 10).
  - No background work.
- **Compliance / security:**
  - Credentials and tokens are handled as secrets and never exposed (FR-6).
  - The log is classified Customer Content, with the user as End-User Identifiable Information.
  - The ADMIN set is restricted.
  - Security incidents involving USPS data or credentials must be reported to USPS within 72 hours. Add this to the incident response checklist.
  - The use must fit the USPS terms (OQ-1).
  - Accepted values are stored as returned.
- **Deployment:**
  - SaaS PTE on BC 28.0 or later.
  - "Allow HttpClient Requests" turned on for this extension in every environment that uses it.
  - Production go-live only after the real hourly quota has been read in the USPS portal and expected volume compared with it (OQ-9).
  - Package versioning per Parameters §1.1.
  - The test app is a separate extension and is not deployed to production.

### 7.1 Constraints and risks
| Risk | Effect | Mitigation |
|---|---|---|
| Quota of about 60 address calls per hour, shared by all users of the credentials (a third-party figure; USPS confirms an hourly quota and the 429 response but doesn't publish the number) | Checks fail with the quota message in busy periods | On-demand only, no retries, clear message. Read the real quota in the portal. If more than about 40 checks per hour are expected, request an increase before go-live. |
| USPS terms allow the API only to facilitate USPS shipping or mailing | Pure CRM data hygiene may be outside the terms | OQ-1 must be answered before build, with sign-off from whoever accepts the terms. |
| Terms prohibit data mining and building or cleaning lists | USPS can throttle or revoke access | No batch function; one customer per action. |
| Terms prohibit changing the form or content of responses | Reformatting may breach the terms | Store exactly as returned, in upper case. |
| Terms call the Addressing API an operational test that can be withdrawn | The free service could change or end | USPS logic isolated in one place. Ask USPS whether the clause covers Addresses 3.0 (OQ-18). |
| USPS can change formats without notice | Integration breaks | Tolerant reading; clear parse-error message; Test (TEM) environment for retesting. |
| Test environment uses production credentials | "Test" still needs real secrets | The setup card states this. |
| 72-hour incident reporting duty | Compliance | Incident checklist; restricted ADMIN set. |

*A reading of the published USPS terms (updated 2026-01-22), not legal advice.*

### 7.2 Acceptance tests and test app
The build is accepted when all of these pass in a sandbox against the USPS test environment, and tests 1–3 pass once against production.

| # | Scenario | Expected |
|---|---|---|
| 1 | Customer address already matches USPS exactly | Confirmed message; no dialog; log Confirmed, Accepted = No |
| 2 | Address with a typo and no ZIP+4; user accepts | Dialog shows both versions with changes in bold; customer updated with USPS values; log Suggestion Accepted, Accepted = Yes, both addresses stored |
| 3 | Same as 2; user ignores, then repeats and closes with Esc | Customer unchanged both times; two log entries Suggestion Ignored, Accepted = No |
| 4 | Address that doesn't exist | Not-found message; customer unchanged; log Not Found with the USPS message |
| 5 | Office building without a suite number | Missing-suite warning (D) shown; Accept still available |
| 6 | Differs only in letter case | Confirmed; no dialog |
| 7 | Country/Region Code CA | US-only message; no USPS call; no log entry |
| 8 | Wrong Consumer Secret | Credentials message; log Error with HTTP 401 |
| 9 | Simulated 429 and timeout | Correct message for each; log Error; no retry |
| 10 | Two checks within the token lifetime | Only one token request |
| 11 | Two users in different time zones open the same log entry | Each sees Checked At in their own local time |
| 12 | User without permission to modify customers | Check runs; the dialog shows that Accept is not possible; OK closes as Ignore; customer unchanged |
| 13 | Unsaved address edit, then Validate Address | The edited address is the one sent |
| 14 | Setup page | Secret never displayed after entry; Test Connection succeeds with valid credentials |
| 15 *(proposed, Step 01 addition)* | Accept on a customer whose Address Validated is No | Address Validated = Yes |
| 16 *(proposed)* | Confirmed outcome | Address Validated = Yes; address fields unchanged |
| 17 *(proposed)* | Ignore or Esc, starting from No and starting from Yes | Address Validated unchanged in both cases |
| 18 *(proposed)* | User edits the address of a validated customer and saves | Address Validated = No |
| 19 *(proposed)* | Customer Card | Address Validated shown in the Address group of Address & Contact; not editable |
| 20 *(proposed)* | New customer | Address Validated = No |
| 21 *(proposed)* | Assisted Setup wizard | Listed in Assisted Setup; saves Key and Secret; Secret never shown afterwards; cached token cleared; environment, Enabled, code and timeout untouched |

**Test app:**
- A separate AL test extension that never calls USPS. It simulates USPS responses (including 400, 401, 404, 429, timeout and unreadable responses), so automated tests use none of the quota.
- It covers tests 1–10 (spec) and proposed 15–18 and 20, plus further tests listed in the TDD (§12a, §13.5).
- Tests 11, 12, 13, 14, 19 and 21 are manual sandbox checks (test 12 manual, decided 2026-10-10).
- How responses are simulated is a TDD decision, constrained by §4.1 k (OQ-17).

## 8. Languages and markets
From Parameters §1.9, written as requirements:

| Language | Country | Required at first release | Reviewer | Customer-language documents | Translatable data |
|---|---|---|---|---|---|
| English (United States), en-US, source language | United States | Yes | AJ Ansari | None (the extension produces no customer-facing documents) | None (the log keeps USPS text exactly as returned) |

- US users see US English wording throughout: "State" and "ZIP Code" in the comparison dialog and in messages.
- Source text is written in US wording.
- No translation files are produced or required. If a language is added later, the parameter sheet is reopened.

## 9. Open questions
| # | Question | Owner | Raised | Resolved |
|---|---|---|---|---|
| OQ-1 | Do we ship or mail to these customers through USPS? This decides whether our use fits the USPS terms. No default. **Blocks build.** | AJ Ansari | Spec, 2026-10-10 | Resolved 2026-10-10: AJ confirmed we ship or mail to these customers through USPS |
| OQ-2 | Store accepted values in upper case, exactly as USPS returns them? Default: yes. | AJ Ansari | Spec | Resolved 2026-10-10: AJ confirmed the default |
| OQ-3 | Should a new ZIP+4 alone trigger the dialog? Default: yes. | AJ Ansari | Spec | Resolved 2026-10-10: AJ confirmed the default |
| OQ-4 | Is State held in the County field? Default: yes. | AJ Ansari | Spec | Resolved 2026-10-10: AJ confirmed the default |
| OQ-5 | Puerto Rico and other territories: validate only the one configured US code? Default: yes. | AJ Ansari | Spec | Resolved 2026-10-10: AJ confirmed the default |
| OQ-6 | USPS firm name: not shown, not written? Default: yes. | AJ Ansari | Spec | Resolved 2026-10-10: AJ confirmed the default |
| OQ-7 | Add accepted ZIP codes to the Post Code table? Default: no. | AJ Ansari | Spec | Resolved 2026-10-10: AJ confirmed the default |
| OQ-8 | Log retention: the default is 2 years, but BC's standard periods have no 2-year option (1 or 3 years are standard; 2 years needs a custom period). (a) Keep 2 years as a custom period, or use 1 or 3 years? (b) Should installing the extension only make the log available in Retention Policies with that default, or also create and turn on the policy? | AJ Ansari | Spec / FRD verification | Resolved 2026-10-10: (a) custom 2-year period; (b) policy created disabled, an administrator enables it (AJ) |
| OQ-9 | Expected checks per hour across all users? If more than about 40, request a quota increase before go-live. Who reads the real quota in the USPS portal? | AJ Ansari | Spec | Open — go-live task for AJ: read the real quota in the USPS portal |
| OQ-10 | Ship-to Addresses and Vendors in a later version? Default: later. | AJ Ansari | Spec | Resolved 2026-10-10: later version (AJ confirmed default) |
| OQ-11 | Permission sets: keep the spec's USE / ADMIN names (`OBCFUSPS USPS, USE`, `OBCFUSPS USPS, ADMIN`) instead of the Standards' default VIEW / EDIT pair (Standards §5.4 allows extra role words such as ADMIN)? Should ADMIN include USE? Standards §5.3 expects a read-only set: is a separate read-only set for auditors (log only, no action) needed? | AJ Ansari | Parameters §1.3 | Resolved 2026-10-10: USE and ADMIN only, ADMIN includes USE, no separate VIEW set (AJ) |
| OQ-12 | Is it acceptable that Accept also updates the linked Contact's address through standard sync (G3)? | AJ Ansari | PRE-02 | Resolved 2026-10-10: acceptable (AJ) |
| OQ-13 | Is a possibly stale Tax Area Code after Accept acceptable as a known v1 limitation (§6.1)? | AJ Ansari | PRE-02 6.6 | Resolved 2026-10-10: acceptable as a known v1 limitation (AJ) |
| OQ-14 | Address Validated reset: (a) Which fields count as an address edit? Proposed: Address, Address 2, City, State, ZIP Code. Should Country/Region Code count too? (b) Edits made by processes that write the fields directly without the standard field validation (some imports, integrations or other extensions) may not be detected. Is resetting on user and validated edits enough? | AJ Ansari | FRD (Parameters §1.6a) | Resolved 2026-10-10: Address, Address 2, City, State, ZIP Code; not Country/Region (AJ) |
| OQ-15 | Address Validated when a previously validated customer gets Not Found or Error on a later check: leave it unchanged (current reading) or reset it to No? | AJ Ansari | FRD | Resolved 2026-10-10: reset to No on Not Found only; Error leaves it unchanged (AJ) |
| OQ-16 | Wizard and setup card: (a) Can the Consumer Key and Secret still also be entered on the setup card (as in the spec), or only through the wizard? Default: both. (b) Does the wizard count as completed in Assisted Setup once both values are saved? | AJ Ansari | FRD (Parameters §1.6) | Resolved 2026-10-10: wizard and setup card both; wizard complete once both values saved (AJ) |
| OQ-17 | Learn says BC's built-in way to simulate HTTP responses in tests is supported on-premises only. Run the automated tests (1–10, 15–18, 20) in a SaaS sandbox using a simulation layer built into the app, or in an on-premises container? Either way the spec rule stands (tests never call USPS). | AJ Ansari | FRD verification | Resolved 2026-10-10: replaceable HTTP layer in the app, tests run in a SaaS sandbox (AJ) |
| OQ-18 | Ask USPS whether the "operational test" clause in the terms covers Addresses 3.0. | AJ Ansari | Spec risks | Open — follow-up task for AJ: ask USPS about the clause before go-live |
| OQ-19 | Confirm the US captions "State" / "ZIP Code" on the Customer Card against a US sandbox (only W1 symbols were available). In W1 the County caption follows the Country/Region "County Name" setting. | AJ Ansari | FRD verification | Open — check against a US sandbox before the TDD relies on the captions |
| OQ-20 | Is "Allow HttpClient Requests" on by default in our production environment, or must it be turned on as a deployment step? | AJ Ansari | FRD verification | Open — check before first deployment |
| OQ-21 | Log result and Address Validated when a dialog check can't be accepted: (a) the user lacks permission to modify customers (closing counts as Ignore, so proposed: Suggestion Ignored); (b) Accept is blocked because a value is too long; (c) the address changed while the dialog was open. Also: on Confirmed for a user who can't modify customers, should Address Validated still be set? | AJ Ansari | ProblemStatement ambiguity 6 / FRD | Resolved 2026-10-10: Suggestion Ignored, Accepted = No, flag unchanged; Confirmed sets the flag only for users who can modify customers (AJ) |
| OQ-22 | Accept the proposed acceptance tests 15–21 for the Step 01 additions, and their test-app coverage (15–18, 20)? | AJ Ansari | FRD | Resolved 2026-10-10: accepted (AJ) |

## Validation against DEFINE
- [x] Every PRE-02 entity appears in §6 or §6.1: objects 1–13, 14a wizard, 14b table extension, 14 test app, the existing tables, and the deferred 6.6, G4 and G5. G1, G2, G3, G6 and G8 are covered in §6, FR-5, FR-6 and FR-9.
- [x] Every PRE-01 consumer use case is addressed in §3 (users, administrators, auditors; no other systems, BI or AI tools).
- [x] Every platform capability assumed here was checked against what BC can do (§4.1). Capabilities only partly verified or not verifiable from symbols (h, k, l; US captions) are stated as such and carried as OQ-12, OQ-17, OQ-19 and OQ-20, not written as fact.
- [x] §8 covers every target language in Parameters §1.9 (en-US only).
- [x] Nothing here says *how*. Table and field IDs, object IDs, code and final object names are left to the TDD.

---

## 10. Change Request CR-1 — amendments for version 2.0 (normative, **sign-off pending**)
**Where this section and an earlier section differ, this section wins.** Raised by AJ Ansari 2026-10-11 (ChangeLog Issue CR-1). Drafted by the Reasoning role (Opus 5.5). FRD sections not mentioned here are unchanged.

### Decisions (AJ Ansari, 2026-10-11)
`Qn` in the text below refers to this table.
| # | Question | Decision |
|---|---|---|
| Direction | Provider | Replace the USPS API with Google Maps Platform Address Validation behind a provider interface; retire the USPS client and OAuth code |
| Q1 | Log versus Google's 30-day storage terms | Keep Google's suggested values in the log **only for Suggestion Accepted and Confirmed**; for Ignored and Not Found keep only the originals, result, granularity, next action, delivery code and HTTP status. 2-year retention stays |
| Q2 | Which suggested values Accept writes | USPS `standardizedAddress` (upper case) when present, else Google `postalAddress` |
| Q3 | `enableUspsCass` | Always on |
| Q4 | What counts as validated | `PREMISE` or `SUB_PREMISE` only |
| Q5 | Equality | Address + Address 2 compared as one street string, ignoring periods, commas and repeated spaces |
| Q6 | Equal values but a missing-suite or delivery-N signal | Confirmed, with the note in the message |
| Q7 | Test Connection | A free invalid-request probe, if the spike proves it reports key, API and billing errors; otherwise one real fixed address |
| Q8 | Provider on the setup card | Visible, read-only |
| Q9 | Google attribution | Text line "Suggestion from Google Maps" in the dialog. Whether a public Terms of Use / Privacy Policy is needed is for AJ to check with the owner of the Google account terms (not legal advice) |
| Q10 | Provider enum | `Extensible = false` |
| Q11 | Naming | Option B: rename the display layer only (app name, test-app name, permission-set captions, assisted-setup texts). Prefix, namespace, object names and permission set names stay |
| Tests | Live tests | Real addresses only (Google's terms forbid made-up US addresses) |

### Google facts this change relies on this design relies on (verified, with URLs)

| # | Fact | Source |
|---|---|---|
| G1 | `POST https://addressvalidation.googleapis.com/v1:validateAddress`. The body has `address` (PostalAddress, required) and `enableUspsCass` (bool), plus `previousResponseId`, `languageOptions` and `sessionToken`, none of which we use. The response has `result` (`verdict`, `address`, `geocode`, `metadata`, `uspsData`) and `responseId`. | https://developers.google.com/maps/documentation/address-validation/reference/rest/v1/TopLevel/validateAddress |
| G2 | In `PostalAddress`, `addressLines` is required and the other fields are optional: `regionCode`, `postalCode`, `administrativeArea`, `locality`, `sublocality`. `revision` must be 0. `recipients` and `organization` are discarded, so we don't send them. All input fields together may be at most 280 characters (ours: 100+50+30+30+20+2 = 232). | same |
| G3 | The documented sample passes the key as `?key=API_KEY`. Google's system-parameters page lists the `X-Goog-Api-Key` header as available across all Google REST APIs. | https://developers.google.com/maps/documentation/address-validation/requests-validate-address ; https://docs.cloud.google.com/apis/docs/system-parameters (updated 2026-10-09) |
| G4 | CASS is off by default and works for regionCode US and PR only. Google says not to enable it unless needed. | requests-validate-address; https://developers.google.com/maps/documentation/address-validation/overview (updated 2026-10-08) |
| G5 | `verdict` fields: `inputGranularity`, `validationGranularity`, `geocodeGranularity`, `addressComplete` (unset means false), `hasUnconfirmedComponents`, `hasInferredComponents`, `hasReplacedComponents`, `hasSpellCorrectedComponents`, `possibleNextAction`. Granularity values: `SUB_PREMISE`, `PREMISE`, `PREMISE_PROXIMITY`, `BLOCK`, `ROUTE`, `OTHER`, `GRANULARITY_UNSPECIFIED`. Next-action values: `FIX`, `CONFIRM_ADD_SUBPREMISES` (US only), `CONFIRM`, `ACCEPT`. Google says ACCEPT "does not guarantee validity". | validateAddress reference (ValidationResult section) |
| G6 | `address` has `formattedAddress`, `postalAddress`, `addressComponents[]` (`componentName.text`, `componentType`, `confirmationLevel` CONFIRMED / UNCONFIRMED_BUT_PLAUSIBLE / UNCONFIRMED_AND_SUSPICIOUS, and booleans `inferred`, `spellCorrected`, `replaced`, `unexpected`), plus `missingComponentTypes`, `unconfirmedComponentTypes` and `unresolvedTokens`. `metadata` has `business`, `poBox`, `residential` (unset means unknown). | same |
| G7 | `uspsData` (US/PR, not always populated) contains:<br>• `standardizedAddress`: `firstAddressLine`, `firm`, `secondAddressLine`, `urbanization`, `cityStateZipAddressLine`, `city`, `state`, `zipCode`, `zipCodeExtension`<br>• `dpvConfirmation`: Y, D, S, N or empty. N = primary and any secondary failed; D = primary confirmed, secondary missing; S = primary confirmed, secondary present but not confirmed; Y = primary and any secondary confirmed; empty = not submitted for DPV<br>• `dpvFootnote`, `dpvVacant` (Y/N), `dpvNoStat`, `dpvCmra`, `addressRecordType`, `cassProcessed` (bool)<br>• `errorMessage`: set when USPS processing is suspended because artificial addresses were detected | same; https://developers.google.com/maps/documentation/address-validation/handle-us-address |
| G8 | Google's recommended logic is FIX / add subpremise / CONFIRM / ACCEPT. Signals: granularity `OTHER`, `missingComponentTypes`, `UNCONFIRMED_AND_SUSPICIOUS`, `unresolvedTokens`, the `has…` flags and DPV. Google says not to rely on `uspsData` alone. | https://developers.google.com/maps/documentation/address-validation/build-validation-logic (2026-10-08); understand-response |
| G9 | **Billing.** "Address Validation Pro" (A2E0-53FF-0BE3) is billed on a "Successful request to the Address Validation API" through ValidateAddress. Feedback requests are free. "Address Validation Enterprise" (10F3-119A-C6EC) applies to an Autocomplete (New) session that ends in ValidateAddress, which we never use. CASS is not named as a SKU trigger. | https://developers.google.com/maps/billing-and-pricing/sku-details |
| G10 | **Prices.** Pro: 5,000 free a month, then $17 per 1,000. Enterprise: 1,000 free, then $25 per 1,000. At AJ's volume (under 1,000 a month) the expected cost is $0. | https://developers.google.com/maps/billing-and-pricing/pricing (2026-10-08) |
| G11 | **Limits.** 6,000 queries per minute. Daily quota caps are set in the Cloud console, and "your service stops responding" at the cap. The page doesn't say whether failed requests are billed. | https://developers.google.com/maps/documentation/address-validation/usage-and-billing (2026-10-08) |
| G12 | **Error body.** `{"error":{"code":<HTTP>,"message","status":"INVALID_ARGUMENT"…,"details":[{"@type":"type.googleapis.com/google.rpc.ErrorInfo","reason","domain","metadata"}]}}`. Confirmed: 429 = RESOURCE_EXHAUSTED and 403 = PERMISSION_DENIED. The specific `reason` values (API_KEY_INVALID, SERVICE_DISABLED, BILLING_DISABLED, API_KEY_SERVICE_BLOCKED) are **not** confirmed for this API. | https://google.aip.dev/193 |
| G13 | **Policies.** Storing results is "generally restricted" (place IDs exempt). Results not shown on a Google map must carry Google attribution, preferably the logo; the text "Google Maps" is allowed where space is short, not translated and not modified. Apps need Terms of Use and a Privacy Policy that reference Google's terms. | https://developers.google.com/maps/documentation/address-validation/policies (2026-10-08) |
| G14 | **Service Specific Terms, Address Validation section** (archived version of 2024-05-22; the live page would not render). `formattedAddress`, `postalAddress`, `componentName` and `standardizedAddress` may be cached for **30 consecutive days** for "Downstream transactions". After that they must be deleted or replaced with "End User data provided through End User confirmation or correction". §10.2: for US/PR, no "artificially-created addresses"; if one is sent, Google stops USPS validation for the customer and reports the customer's name and address to USPS. | https://cloud.google.com/maps-platform/terms/maps-service-terms/index-20240522 |
| L1 | `HttpHeaders.Add(Name: Text; Value: SecretText)` and `HttpRequestMessage.SetSecretRequestUri(SecretText)` are both available from runtime 12.0 (we target 17.0). Learn was used because these are platform methods, not symbols. | https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httpheaders/httpheaders-add-string-secrettext-method ; …/httprequestmessage/httprequestmessage-setsecretrequesturi-method |

Correction to the delegation's summary: the Enterprise SKU is **not** about CASS. It is the Autocomplete-session SKU. A plain ValidateAddress request, with or without CASS, bills as Pro per the SKU page (still to confirm in the billing report at the spike).


**Header:** Version 2.0 (CR-1: USPS Addresses API replaced by Google Maps Platform Address Validation API behind a provider interface; decided by AJ Ansari 2026-10-11) · Date 2026-10-11 · Author Reasoning role (Opus 5.5) · Sign-off: pending.
**Sources:** add `docs/0-project/ChangeLog.md` Issue CR-1.

### §1 Purpose and scope (replace the paragraph)
> People type customer addresses into Business Central by hand, so many are wrong or inconsistent: misspelled cities, long-form street names, ZIP codes without the +4. Address validation lets a user who is maintaining a customer check that customer's main address with an address validation provider. Version 2.0 uses the **Google Maps Platform Address Validation API**, with USPS CASS processing for US addresses. The provider sits behind a replaceable interface so another provider can be added later. The user sees the Business Central address and the suggested address side by side and accepts the suggestion with one click, or ignores it. Every check that reaches the provider is logged: who checked which customer, when, what was sent, what the provider answered, and whether the suggestion was accepted. A read-only **Address Validated** indicator shows whether the current address was confirmed by, or accepted from, the provider. An administrator sets the service up once per company, and an Assisted Setup wizard helps them enter the provider's API key. Expected result: cleaner US customer addresses for mailing and shipping, with an audit trail, within the provider's free monthly allowance and its terms.

### §1.1 Out of scope (changed bullets)
- **Automatic validation on entry or save, and batch or scheduled validation:** *excluded on purpose. Each check is a billable request, every check needs a user decision, and the design keeps volume inside the free allowance. The provider terms also forbid artificial addresses (§7.1).* (Replaces the USPS quota and list-cleaning reasons.)
- **Non-US addresses:** *this version validates US addresses only (the configured US code or a blank country). Google could validate other countries; that is a later decision.*
- **Geocoding, residential rating, tax area updates:** unchanged. Google returns a geocode and a residential flag; neither is used or stored.
- **Showing or writing a firm name:** unchanged (`standardizedAddress.firm` is ignored).
- **New:** *Showing results on a map, Google Places Autocomplete, and the feedback call (`provideValidationFeedback`).*
- **New:** *A second provider (Smarty, Geocodio, USPS). The design must allow one to be added as one new codeunit (§5); none is built.*
- Translations: unchanged.

### FR-1 Validate Address action
1. Caption **Validate Address** (was "Validate Address (USPS)"). Promoted and under Actions > Functions, as before.
2. Unchanged (save first; test 13).
3. Preconditions, same order, same "nothing sent, nothing logged" rule:
   - The service is enabled, a provider is selected, and **the provider's API key is present**.
   - Country US, as before (blank or the configured US code).
   - Address filled in, plus City and State or the ZIP Code. Unchanged.
   - State, when filled in, is a 2-letter code. Unchanged: Google would accept a full state name, but the comparison and Accept write the 2-letter code into County, so the rule stays.
4. *The extension sends **one** validation request to the provider. There is no token and no second call. The request never includes the customer's name or number. The API key is never part of a URL when the provider accepts it in a header.*
5. and 6. Unchanged.

### FR-2 Outcomes (replace the table)
| Outcome | What the user sees | Customer address updated | Address Validated | Log result |
|---|---|---|---|---|
| The provider **validated** the address (FR-8) and the suggestion equals the BC address (FR-3) | Message: confirmed by Google Maps, no changes. Any delivery note (FR-4) is added to the message. | No | Set to **Yes** (users who can modify customers) | Confirmed |
| Validated, and the suggestion differs | Comparison dialog (FR-4) | Only on Accept | Yes on Accept; unchanged on Ignore | Suggestion Accepted / Suggestion Ignored |
| The provider answered but could **not validate** the address to building level (FR-8) | Message: "Google Maps could not confirm this address to the building…" plus what is missing or unconfirmed | No | Reset to No (users who can modify customers) | Not Found |
| Key, API-disabled, billing, quota, invalid request, network, server or parse error | Error message with the next step (FR-7) | No | Unchanged | Error |

Keep the paragraph after the table, with "USPS" replaced by "the provider".

### FR-3 What counts as different (replace)
- The compared values are **Street** (Address + " " + Address 2 compared as one string; see Q5), City, State and ZIP Code.
- Each value is normalized before comparing: trimmed, upper case, periods and commas removed, runs of spaces collapsed to one (Q5).
- If only letter case or that punctuation differs, the outcome is **Confirmed** and no dialog is shown.
- A new ZIP+4 on a 5-digit ZIP still counts as a difference (OQ-3 kept).
- In the dialog, each row is bolded by a row-by-row comparison using the same normalization.

### FR-4 Comparison dialog (changed bullets)
- Columns **Current (BC)** and **Suggested**. Directly under the grid, an attribution line: **"Suggestion from Google Maps"** (G13; the provider supplies the display name).
- The **delivery notes** come from the provider result, not from USPS text:
  - **Warning line** (Accept still available):
    - DPV **D**, or possibleNextAction `CONFIRM_ADD_SUBPREMISES`: "The suite or apartment number is missing."
    - DPV **S**: "The suite or apartment number could not be confirmed."
    - DPV **N**: "USPS could not confirm this address as deliverable."
  - **Notes:**
    - `hasReplacedComponents`: part of the address was replaced (for example the ZIP Code).
    - `hasInferredComponents`: missing parts were added.
    - `hasSpellCorrectedComponents`: spelling corrected.
    - `hasUnconfirmedComponents`: some parts could not be confirmed.
    - `dpvVacant` = Y: vacant.
    - `metadata.business` = true: business address.
    - `metadata.poBox` = true: PO box.
    - `uspsData.errorMessage`, if any.
- **Accept** writes the four suggested values (Street split into Address and Address 2 as the provider returned them, City, State, ZIP) exactly as returned. The only reformatting is the ZIP format rule below. It then sets Address Validated to Yes and closes the dialog. *Which representation is used (USPS standardized, upper case, or Google postal, mixed case) is Q2.*
- Unchanged: Ignore, X/Esc, the no-permission rule (test 12), blocked-when-too-long, address-changed-meanwhile, OQ-21 logging, no Post Code lookup override, the ZIP format `12345-6789` / `12345`, and "call and dialog before anything is written".

### FR-5 Processing log (replace the field list)
Each entry records:
- Entry No., Customer, Checked At, User, Result, Accepted, the five original values: unchanged.
- **Provider** (Google; replaces Environment).
- The five **suggested** values: blank for Not Found and Error. *Their retention depends on Q1.*
- **Validation Granularity**, **Next Action** (possibleNextAction) and **Address Complete**, as returned.
- **DPV Confirmation** (Y, D, S, N or blank), kept when the provider returns it.
- **Provider Message**: the Google error message, the not-validated reason, or the write-failure text.
- HTTP Status (0 when there was no response).
- **Removed:** match codes, correction codes, environment.
- The log never stores the API key, credentials or request URLs. Retention is unchanged (custom 2 years, created disabled), **subject to Q1**. All other bullets are unchanged.

### FR-6 Setup (replace the table and the bullets that follow it)
| Setting | Default | Notes |
|---|---|---|
| Enabled | No | Unchanged |
| Provider | Google Maps | One value in v2.0. Shown read-only (Q8) |
| API Key | (blank) | Write-only: shown as a mask once saved, never readable |
| US Country/Region Code | US | Unchanged |
| Timeout (seconds) | 10 | Unchanged |
- **Environment is removed.** Google has no test environment, and the enum, the setup field and the log field go with it. Automated tests never call Google (fake transport). Manual tests run against the live service with **real** addresses only (§7.1).
- The API key is stored in isolated storage, company scope, as a secret (encrypted when encryption is on). It is never in a table field, a URL (when the header works, G3), the log, telemetry, messages or the debugger.
- **Test Connection** checks the key, that the API is enabled, and that billing is on, **without a billable request where possible.** Proposal: send a deliberately incomplete request (no address lines). A 400 INVALID_ARGUMENT about the request means the key and the project are accepted; a key, API-disabled or billing error is reported. Google bills only "successful" requests (G9). If the spike shows billing or API-enablement errors are not reported for such a request, Test Connection instead validates one fixed, real public address. That is one billable request, inside the 5,000 free (Q7).
- Removed: token caching and "changing the key or environment clears the token".
- **Assisted Setup wizard:** the administrator enters **only the API key**. It is complete in Assisted Setup once the key is saved, and it still never enables, tests or changes other settings. The key can also be entered on the setup card.
- **Outside Business Central (administrator, documented in Deployment.md):**
  - Create a Google Cloud project, enable billing, enable the Address Validation API, and create an API key.
  - Restrict the key to the Address Validation API.
  - Set a daily request cap (for example 100 per day) and a budget alert (for example $1).

### FR-7 Error handling (replace the table)
| Condition | Message to the user | Logged as |
|---|---|---|
| Setup disabled, no provider, or key missing | Address validation is not set up. Contact your administrator. | Not logged |
| Country not US | Address validation works for US addresses only. | Not logged |
| Address incomplete | unchanged | Not logged |
| State not 2 letters | unchanged | Not logged |
| Key rejected (400 with reason API_KEY_INVALID, or 401) | Google Maps rejected the API key. Contact your administrator. | Error |
| API not enabled for the key's project (403 SERVICE_DISABLED) | The Address Validation API is not enabled in the Google Cloud project of this API key. Contact your administrator. | Error |
| Billing not enabled (403 BILLING_DISABLED) | Billing is not enabled for the Google Cloud project of this API key. Contact your administrator. | Error |
| Key restricted from this API (403 API_KEY_…_BLOCKED) | The API key is not allowed to call the Address Validation API. Contact your administrator. | Error |
| Any other 403 | "Google Maps refused the request:" + Google message | Error |
| Request rejected (other 400 INVALID_ARGUMENT) | "Google Maps could not read the address:" + Google message | Error |
| Quota or daily cap reached (429) | The Google Maps request limit has been reached. Try again later. | Error |
| Server error (5xx), timeout, no connection | Google Maps is not responding. Try again later. | Error |
| Response can't be read (bad JSON, no `result.verdict`, validated but no address) | Unexpected response from Google Maps. Contact your administrator. | Error |
| Answered but not validated to building level | "Google Maps could not confirm this address to the building." + reason | Not Found |
- **No automatic retry of any kind** (the token refresh is gone).
- Reading is still field by field by name, tolerant of missing and extra fields. A missing boolean counts as false.
- When an ErrorInfo `reason` is absent, the HTTP status decides (400 → could not read, 401 → key rejected, 403 → refused, and so on).
- The write-failure bullet is unchanged.

### FR-8 Address Validated (definitions added, rules kept)
- **Validated** (the provider's answer is usable as a suggestion) means `verdict.validationGranularity` is `PREMISE` or `SUB_PREMISE`, **and** a suggested Street, City, State and ZIP can be read. Strict reading, Q4.
- **Confirmed** means validated, and the suggestion equals the BC address under FR-3. Delivery signals (DPV D/S/N, `CONFIRM_ADD_SUBPREMISES`, `CONFIRM`) do not stop Confirmed; they are added to the Confirmed message (Q6).
- **Not Found** means HTTP 200 with a readable `result.verdict` whose granularity is anything else: `ROUTE`, `PREMISE_PROXIMITY`, `BLOCK`, `OTHER`, unspecified or missing.
- All other rules stand: set on Accept/Confirmed (Confirmed only for users who can modify customers); reset on Not Found for users who can modify customers; unchanged on Ignore, blocked or Error; reset on a user edit of the five fields; the extension's own Accept doesn't count as an edit.

### §2 Objectives (changed rows)
- O1: unchanged, with "USPS standard form" replaced by "standardized form (USPS CASS when available)".
- **O4: "Stay inside the free allowance and the provider terms."** Value: no recurring cost at under 5,000 checks a month. Measured by: one request per check, no retries, a daily cap and a budget alert set (tests 9, 10, 14).
- O5: "key never displayed after entry".

### §3 Consumers
- Replace the USPS row: **Google Maps Platform Address Validation API** (system, external provider) receives one POST per check, never the customer name or number, and the key in a header.
- Administrators: add "plus the Google Cloud project: billing, API enablement, key restriction, quota cap, budget alert".
- Automated test app: "simulates provider responses so tests never call Google".

### §4 Platform requirements
- Outbound HTTPS to `addressvalidation.googleapis.com`.
- Other bullets unchanged.

### §4.1 Verified capabilities
- b: the endpoint is public (G1).
- c: one key per company. `SetEncrypted` has a 215-character limit; Google API keys are short, but the length is checked at the spike.
- k: unchanged.
- **New m:** a SecretText header and a SecretText request URI are available from runtime 12.0 (L1).
- **New n:** Google's response fields, verdict semantics, error shape and billing events (G1–G12, "Verified from documentation; the live contract is checked at the spike").

### §5 Design rules (changed)
- **One customer per user action:** source becomes "spec; cost; provider terms".
- **Store the provider's values as returned, never truncate.** The only reformatting is ZIP+4 as `12345-6789`. (Replaces "USPS values exactly as returned (upper case)".)
- **Secrets stay secret:** "API key" replaces "credentials and tokens". New: the key never goes into a URL when the header works.
- **No retries** (the token-refresh exception is removed).
- **All provider-specific logic lives in one codeunit per provider, behind a provider interface.** A second provider is one new codeunit plus one enum value. (Replaces "All USPS-specific logic in one place".)
- The customer's name and number are never sent to the provider.
- **New: never send made-up addresses to the live service** (Google terms §10.2, G14). Manual and spike tests use real addresses.
- **New: Google results shown to users carry the "Google Maps" attribution** (G13).
- Other rules unchanged.

### §6 Inventory (changed rows)
- Setup: "Provider, API key in isolated storage".
- Setup card: Test Connection as in FR-6.
- Wizard: "API key only".
- Log: as in FR-5.
- Comparison: "attribution line".
- **Remove** the "USPS environment" enum row.
- **Add:**
  - "Address provider (enum)"
  - "Address provider interface"
  - "HTTP transport interface (test seam)"
  - "Google address client (codeunit; the only Google-specific logic)"
  - "Address service (codeunit; picks the provider)"
- API client row: replaced by the last two.
- Isolated storage: "API key, company scope; no token".
- Customer Card: action "Validate Address", log action "Address Validation Log".

### §7 Non-functional requirements
- **Performance:** one HTTPS call per check. Delete "two checks… one token request (test 10)".
- **Compliance:**
  - Delete the USPS 72-hour reporting duty and OQ-1.
  - Add: if the API key is exposed, rotate it in the Cloud console and enter the new key in Business Central (incident checklist).
  - Add: Google terms on storage (Q1), attribution, and artificial addresses.
- **Deployment:** replace the USPS quota go-live line with "billing on, API enabled, key restricted to the Address Validation API, daily cap and budget alert set, Test Connection passes".

### §7.1 Constraints and risks (replace the table)
| Risk | Effect | Mitigation |
|---|---|---|
| Pay-as-you-go: billing must be on; beyond 5,000 Pro requests a month it costs $17 per 1,000 (G10) | Unexpected cost | Daily cap and budget alert; no batch; one request per check; a Test Connection that bills nothing (FR-6) |
| Billing disabled, API disabled or key restricted | Every check fails | Specific messages (FR-7); Test Connection |
| Storing results is limited to 30 days, then delete or replace with end-user-confirmed data (G14) | A 2-year log of Google suggestions may breach the terms | **Q1** decides what the log stores. Accepted values become end-user-confirmed customer data |
| Artificial addresses for US/PR: Google stops USPS validation and reports the customer to USPS (G14) | Loss of CASS data, plus a report | Never test with made-up addresses; automated tests use the fake transport |
| Attribution and ToS/Privacy-policy requirements (G13) | Terms breach | Attribution line in the dialog; Q9 |
| Provider formats change | Integration breaks | Tolerant reading; spike checklist; parse-error message |
| Daily cap reached | Checks fail until the next day | Clear 429 message; the admin raises the cap |
| `uspsData` not always populated (G7) | No DPV note | Notes fall back to verdict flags; suggested values fall back to `postalAddress` |

The line *"A reading of the published terms (Google Maps Platform Service Specific Terms, archived 2024-05-22 version; the current text to be confirmed), not legal advice."* replaces the USPS line.

### §7.2 Acceptance tests
Intro: "…pass in a sandbox with the fake transport (automated) and once against the live Google service with **real** addresses (1, 2, 4, 5, 14)."

| # | Change |
|---|---|
| 1, 2, 3, 6, 7, 11, 12, 13, 15–20 | Unchanged except wording ("provider" / "Google Maps" for "USPS") |
| 4 | **Changed:** "A real street without a house number (Google returns ROUTE or OTHER granularity)" → Not-found message with the reason; log Not Found. *No invented address.* |
| 5 | **Changed:** "Office building without a suite number (DPV D or `CONFIRM_ADD_SUBPREMISES`)" → missing-suite warning; Accept available |
| 8 | **Changed:** "Wrong API key" → key-rejected message; log Error with HTTP status 400 (or 401 / 403; the spike confirms which) |
| 9 | Unchanged intent: simulated 429 and timeout; exactly one request each |
| 10 | **Replaced** (token reuse removed): "Each check sends exactly one request; the request carries no customer name or number and no key in the URL" |
| 14 | **Changed:** "API key never displayed after entry; Test Connection succeeds with a valid key and the Cloud console shows no billable request for it" |
| 21 | **Changed:** "Wizard listed in Assisted Setup; saves the API key; the key is never shown afterwards; Enabled, Provider, US code and timeout untouched" |
| **22 (new)** | API not enabled, or billing disabled → the specific FR-7 message; log Error (automated with the fake; once live at the spike) |
| **23 (new, manual)** | The comparison dialog shows "Suggestion from Google Maps" |

**Test app paragraph:** "simulates 200 (validated, not validated, with and without `uspsData`), 400 (key, invalid argument), 401, 403 (API disabled, billing, key restricted), 429, 5xx, timeout and unreadable responses". Automated: 1–10, 15–18, 20, 22. Manual: 11–14, 19, 21, 23.

### §8 Languages
Replace "the log keeps USPS text exactly as returned" with "the log keeps provider text exactly as returned".

### §9 Open questions
- **Superseded by CR-1** (keep the rows, mark them):
  - OQ-1 (USPS terms)
  - OQ-9 (USPS hourly quota): replaced by OQ-25
  - OQ-18 (USPS operational-test clause)
- Unchanged and still open: OQ-19, OQ-20.
- OQ-2: "upper case as returned" becomes Q2.
- OQ-5 (PR) stands. Google CASS supports PR, but only the configured US code is validated.
- **New:**
  - OQ-23 = Q1 (storage terms)
  - OQ-24 = Q2/Q3 (CASS and the value source)
  - OQ-25: AJ sets the daily cap and budget alert before go-live
  - OQ-26 = Q4/Q6 (thresholds)
  - OQ-27 = Q5 (normalization)
  - OQ-28 = Q7 (Test Connection)
  - OQ-29 = Q9 (ToS/Privacy policy, attribution)
  - OQ-30 = naming (§4 below)

---

