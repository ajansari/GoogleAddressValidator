# Functional Requirements Document — Google Address Validator

**Version:** 2.1 AS-BUILT BASELINE (Step 10, 2026-10-18), for Google Address Validator main app **1.2.0.4** (previous build 1.2.0.3, and 1.2.0.2 before it) and test app **0.0.0.23** (previous build 0.0.0.22). **SC-5 and SC-5a (2026-10-18, main 1.2.0.3 and 1.2.0.4) change how a record with a blank Country/Region Code is handled (FR-19.2, FR-19.3, FR-19.5, FR-19.7):** a new Setup option Blank Country Handling (Let Google decide, the default, or Use default country) decides whether the country is worked out from the address (a US state with a 5- or 9-digit ZIP code means US, a Canadian postal code means Canada, anything else sends no region and Google names the country) or the Default Country/Region Code is used for every such record; a guessed US or Canadian region that ends in Not Found is tried once more without a region. Not installed or run anywhere; the decisions in SC-5a are awaiting AJ Ansari's confirmation (OQ-61 to OQ-64). **SC-4 (2026-10-18, main 1.2.0.2) adds FR-19 Countries:** addresses are validated in the 40 countries Google's Address Validation API covers, not only the US (a supported-country table, a Default Country/Region Code, a region per check, per-region input rules, country fill-in from the result); it replaces every earlier statement that validation is US only (not yet installed or run anywhere). FR-18.6 (1.1.0.12) is generalised by it: a blank Country/Region Code is filled in with the country Google found, else the hint, when a check ends in Accept or Confirmed. **SC-2 (2026-10-18, main 1.1.0.10) is folded in:** the Setup, wizard, assisted-setup and Log names now start with "Google Address Validation" and start with the provider's name, and the Setup and Log pages are found in Tell Me search by "Google" (FR-5, FR-6, §7 wording); the log has a new **Record No.** column (FR-5) and an upgrade step that fills it on existing rows (FR-16.6). The SC-2 change is not yet installed or run anywhere. It is FRD 2.0 (the 1.0.0.0 baseline) with the whole SC-1 scope change (version 1.1, Appendix C of the draft) folded into §1–§9: the new requirements are FR-10 to FR-18, acceptance tests 24–45 and open questions OQ-34 to OQ-49 in the body, and the later decisions the Appendix did not yet contain are applied (Step 08 Spec stale items GA-1.1-04, -05, -06, -09, -11, -15; Step 09 Code Review CR-1.1-01, -02, -04, -07, N-1). There is **one** current statement of requirements here; Appendix C is now only a short change record. · **Date:** 2026-10-18 · **Author:** Reasoning role (Opus 5.5) for AJ Ansari (FRD 2.0 and the SC-1 draft); consolidated by the Main role (Sonnet 5.5) at Step 10
**Sign-off:** CR-1 decisions Q1–Q11 signed off by AJ Ansari (Dev Manager) on 2026-10-16 (ChangeLog 07a-2); SC-1 design (the Appendix C text) signed off by AJ Ansari on 2026-10-17 (ChangeLog SC-1b, amended by the Sanity Check, SC-1c). Three later decisions were taken by the Main role under AJ Ansari's standing instruction to finish without questions and were **confirmed by AJ Ansari on 2026-10-18**: D3 (FR-12.4, OQ-50), the log read restriction (FR-5, CR-1.1-01, OQ-51) and the country rule (FR-8, CR-1.1-04, OQ-52). He also confirmed GF-04 (Record No. is a snapshot) and the release-candidate handling in §9 (Release candidate). Dev Manager review of this as-built baseline happens once, at the Step 11 → 12 hand-off, together with Step 11's documents.
**History and the pre-BUILD version.** The FRD as it stood before the SC-1 scope change (FRD 2.0, the 1.0.0.0 baseline) is in git commit `b31d1e0` (`git show b31d1e0:docs/2-design/FRD.md`); list every revision of this file with `git log --follow docs/2-design/FRD.md`. The text of FRD 1.3 (the USPS Address Validator build, 0.0.0.4) is kept at `docs/2-design/FRD.USPSbuild-1.3.md`. The text as it stood before the first Step 10 (1.2 with the unsigned CR-1 draft) is kept at `docs/2-design/FRD.preStep10.md`. None of those is edited. The raw SC-1 draft by the Reasoning role is `docs/2-design/SC-1-Amendments-Draft.md` (working draft, not part of this FRD).
**Sources:** `docs/1-define/ProblemStatement.md`, the PRE-02 expanded entity list and gap log, `docs/1-define/ProjectParameters.md`, `docs/0-project/ChangeLog.md` (CR-1, 07a-1 to 07a-3, 08-3, 09-3, SC-1 to SC-1h, B1-1, B2-1/B3-1/B4-1, 08-SC1), `docs/4-prove/GapAnalysis.md`, `docs/4-prove/CodeReview.md`, `docs/2-design/SanityCheck.md`; original behaviour from `requirements/USPS Address Validation for Business Central — PTE spec.md`, `requirements/scope-additions-2026-10-10-requirements.md` and `requirements/scope-additions-2026-10-17-more-master-data-requirements.md`.
**Word "USPS":** it appears below only as data (DPV, CASS, `uspsData`, USPS standardized address) or as history. The service is Google Maps Platform Address Validation.

## 1. Purpose and scope
People type customer addresses into Business Central by hand, so many are wrong or inconsistent: misspelled cities, long-form street names, ZIP codes without the +4. Google Address Validator lets a user who is maintaining master data — a customer, ship-to address, customer or vendor bank account, vendor, order or remit address, the company (its address and its ship-to address), a location, responsibility center, bank account, employee, employee alternative address, contact, contact alternative address or resource (FR-10) — check that record's address with an address validation provider. This version uses the **Google Maps Platform Address Validation API**, with USPS CASS processing for US addresses. The provider sits behind a replaceable interface so another provider can be added later. The user sees the Business Central address and the suggested address side by side and accepts the suggestion with one click, or ignores it. Every check that reaches the provider is logged: who checked which record, when, what was sent, what the provider answered, and whether the suggestion was accepted. A read-only **Address Validated** indicator on each of those records shows whether the current address was confirmed by, or accepted from, the provider. An administrator sets the service up once per company, and an Assisted Setup wizard helps them enter the provider's API key. Expected result: cleaner US addresses in master data for mailing and shipping, with an audit trail, within the provider's free monthly allowance and its terms.

### 1.1 Out of scope
- **Automatic validation when an address is entered or saved, and batch or scheduled validation of many customers.** Excluded on purpose. Each check is a billable request, every check needs a user decision, and the design keeps volume inside the free allowance. The provider terms also forbid artificial addresses (§7.1).
- **Countries Google does not cover.** Validation works in the 40 countries listed in FR-19 (US and Puerto Rico with USPS data); an address in any other country is refused with a message and nothing is sent. Countries are never validated by another provider. (Replaces the earlier US-only statement and the SC-3 answer for the record, AJ Ansari, 2026-10-18; built as SC-4.)
- **Every transaction and document table:** sales, purchase, transfer, service, reminder, finance charge, and their archives and posted versions.
- **Job, Job Task, Service Item, Work Center, Machine Center, Union, all templates and Standard Address** (AJ Ansari, 2026-10-17). Any other table than the 16 sources of FR-10 is refused (FR-7).
- **Employee alternative-address activation** (dates, Alt. Address Code) is not changed.
- **Geocoding, residential/commercial rating and tax area updates.** Google returns a geocode and a residential flag; neither is used or stored. The resulting Tax Area Code limitation is described in §6.1.
- **Adding accepted ZIP codes to the Business Central Post Code table.** Decided: no (OQ-7).
- **Showing or writing a firm name.** Not shown, not written.
- **Updating documents, journals or any other record that copied an address** (PRE-02, Standards §6.2). Accept changes only the record checked and the records standard Business Central itself keeps in step with it (FR-9). Open documents keep the address they were created with, and posted documents keep the address they were sent to.
- **The Validate Address action on any list page** (PRE-02 G4). Deferred, see §6.1.
- **Showing Address Validated anywhere other than the card pages named in FR-10.**
- **Showing results on a map, Google Places Autocomplete, and Google's feedback call (`provideValidationFeedback`).**
- **A second provider (Smarty, Geocodio, USPS).** The design must allow one to be added as one new codeunit and one enum value (§5); none is built.
- **Telemetry.** None is emitted (OQ-32, decided).
- **Translations.** English (United States) only (§8).

### 1.2 Functional requirements

#### FR-1 Validate Address action
0. **Scope of FR-1 to FR-9.** They are written for the Customer, the original source. Wherever they say customer, Customer Card or customer address, they apply to every address source in FR-10, its card page and its address fields, with the exceptions in FR-10 to FR-17. The Customer's behaviour and messages are exactly as in 1.0.0.0, except for the five changes listed in FR-18.
1. The Customer Card has a **Validate Address** action. It is promoted, and it also appears under Actions > Functions.
2. When the user chooses it, any unsaved changes on the card are saved first. This makes sure the address that is checked is the one on screen (acceptance test 13).
3. The action then checks these preconditions in order and stops with the matching message from FR-7 if one fails. **Nothing is sent to the provider and nothing is logged when a precondition fails:**
   - The record is one this app can validate, it exists, and it is not blocked due to privacy (FR-17). This check runs after the record is found and before the setup, country and address checks.
   - The service is enabled, a provider is selected, and the provider's API key is present.
   - The block's country is one the extension can validate (FR-19.3 to FR-19.5): its region is in the supported-country table and is turned on; when the record has no country, the region is the one the Blank Country Handling setting gives (the Default Country/Region Code under Use default country, a region worked out from the state, ZIP code or postal code under Let Google decide, or none), and a region that is chosen must be supported and turned on. A country that Google does not cover, one an administrator turned off, or one without an ISO Code gets its own message (FR-7, FR-19.9). This replaces the earlier US-only rule.
   - The address has the parts its region needs (FR-19.4): for the US and Puerto Rico, a street plus a ZIP-like Post Code (its first five characters are digits) or City and State; for Canada, a street plus a postal code like A1A 1A1 or City and Province; for every other region, a street plus a City or a Post Code.
   - State, when filled in for the US, Puerto Rico or Canada, is a 2-letter code. (Google would accept a full name, but the comparison and Accept write the 2-letter code, so the rule stays.) There is no state rule for other regions.
   - The Business Central **privacy notice** for sending addresses to Google has been agreed to. The notice is named **Google Address Validation** and links to Google's privacy policy (`https://policies.google.com/privacy`; the link is **unconfirmed**, OQ-31). If the user or administrator has not agreed, the message in FR-7 is shown and nothing is sent or logged. The notice is created by the extension at install, on company creation, and again, if missing, before each check, so an upgraded environment has it too. **Caveat:** the consent text itself is supplied by the Business Central platform and says the data is shared with "Microsoft services"; it cannot be replaced by the extension and is therefore inaccurate for Google. In a company where no administrator has decided on the notice (for example an evaluation company) the platform lets the check pass without showing it. Deployment.md explains both points to administrators.
4. The extension sends **one** validation request to the provider, with one exception (FR-19.5, SC-5a): when the region was only guessed from the address (Blank Country Handling = Let Google decide; US or Canada) and the answer is Not Found, the request is repeated once without a region. There is no token and no other second call. The request never includes the customer's name or number. The API key travels in a request header and is never part of a URL.
5. It compares the suggestion with the Business Central address (FR-3) and shows one of the outcomes in FR-2.
6. Every check that reaches the provider writes **exactly one** log entry, whatever the outcome (FR-5).
7. **One record (address block) per user action, enforced.** The orchestration that runs a check and the service that talks to the provider can be used only by this app (and, in a sandbox only, by its test app). Another extension calling them is refused with: "This procedure can only be called by the Google Address Validator app." This keeps the privacy notice, the log and the one-check-per-user-action rule from being bypassed. A check is designed for an interactive user; running one without a user interface (job queue, API) is not supported.

#### FR-2 Outcomes
| Outcome | What the user sees | Customer address updated | Address Validated | Log result |
|---|---|---|---|---|
| The provider **validated** the address (FR-8) and the suggestion equals the BC address (FR-3) | Message: confirmed by Google Maps, no changes needed. The delivery warning line of FR-4 (DPV D, S, N or `CONFIRM_ADD_SUBPREMISES`) is added to the message when there is one. | No | Set to **Yes** (users who can modify customers) | Confirmed |
| Validated, and the suggestion differs | Comparison dialog (FR-4) | Only on Accept | **Yes** on Accept; **unchanged** on Ignore | Suggestion Accepted / Suggestion Ignored |
| The provider answered but could **not validate** the address to building level (FR-8) | Message: "Google Maps couldn't confirm this address." plus what is missing or unconfirmed | No | Reset to **No** if it was Yes, for a user who can modify customers | Not Found |
| Key, API-disabled, billing, quota, invalid request, network, server or parse error | Error message with the next step (FR-7) | No | Unchanged | Error |

When the result is Confirmed, the customer's **address fields** are not changed. Only the Address Validated indicator is set. The delivery warning line is the only delivery signal added to the Confirmed message; the other FR-4 notes (replaced, inferred, spell-corrected, unconfirmed parts, vacant, business, PO box) and a bare `CONFIRM` next action appear in the dialog or the log only (Gap Analysis GA-07, decided 2026-10-16).

#### FR-3 What counts as different
- The compared values are **Street** (Address + " " + Address 2, compared as one string), City, State and ZIP Code.
- Each value is normalized before comparing: trimmed, upper case, periods and commas removed, runs of spaces collapsed to one.
- If only letter case or that punctuation differs, the outcome is **Confirmed** and no dialog is shown.
- A new ZIP+4 on a 5-digit ZIP counts as a difference, so the dialog is shown (OQ-3).
- In the dialog, each row is bolded by a row-by-row comparison using the same normalization.

#### FR-4 Comparison dialog
- A modal dialog titled **Suggested Address**, with two read-only columns: **Current (BC)** on the left and **Suggested** on the right. The rows are Address, Address 2, City, State / Province and ZIP / Postal Code. When the record has no country and one can be filled in, a read-only line "The Country/Region will be set to X." is shown (FR-19.7). Values that changed are shown in **bold**. Directly under the grid, an attribution line: **"Suggestion from Google Maps"** (the provider supplies the display name). An instruction line reads: "Changed values are shown in bold. Choose OK to accept the suggested address, or Cancel to keep the current address."
- The dialog shows delivery notes from the provider result:
  - **Warning line** (Accept stays available):
    - DPV **D**, or next action `CONFIRM_ADD_SUBPREMISES`: "The suite or apartment number is missing."
    - DPV **S**: "The suite or apartment number could not be confirmed."
    - DPV **N**: "USPS could not confirm this address as deliverable."
  - **Notes:**
    - part of the address was replaced (for example the ZIP Code);
    - missing parts were added;
    - spelling was corrected;
    - some parts could not be confirmed;
    - USPS data reports the address is vacant;
    - this is a business address;
    - this is a PO box;
    - any message USPS processing returns with the result.
- The buttons are the standard dialog buttons: **OK** accepts the suggested address, and **Cancel**, X and Esc keep the current address (Ignore). There are no separately named Accept or Ignore buttons.
- OK **writes the five suggested values** to the record's address block (the customer, for a Customer) exactly as the provider returned them, sets Address Validated to Yes, and closes the dialog. Which values are suggested: the USPS standardized address (upper case) when the provider returns one, otherwise Google's postal address (mixed case) (decision Q2). The only reformatting is the ZIP format below.
- **OK is not possible** for a user who isn't allowed to modify the record's table. That user can still run the check and see the dialog; for a Customer it shows "You can't accept the suggested address because you don't have permission to change customers. Choose OK or Cancel to close without changes." (acceptance test 12); for any other source "You can't accept the suggested address because you don't have permission to change <table> records. Choose OK or Cancel to close without changes." (test 30). Pressing OK then closes the dialog as Ignore.
- **Accept is blocked with a message**, and nothing is truncated, if a suggested value is longer than the customer field can hold: "You can't accept the suggested address because the suggested value for <field> is longer than <n> characters. Choose OK or Cancel to close without changes." City and State hold at most 30 characters.
- **Accept stops with a message** if someone else changed the address while the dialog was open: for a Customer "The customer's address was changed while the suggested address was open, so nothing was updated. Run Validate Address again."; for other sources "The address was changed while the suggested address was open, so nothing was updated. Run Validate Address again."
- When Accept is disabled or blocked (no permission, a value too long, or the address changed meanwhile), nothing is written to the customer and the log entry is **Suggestion Ignored** with Accepted = No (OQ-21).
- On Accept, the standard ZIP-code lookup must **not** replace the suggested city or ZIP with values from the Post Code table.
- The ZIP Code is written as `12345-6789`, or as `12345` when the provider returns no +4.
- The provider call and the dialog both happen **before** anything is written. The customer update and the log entry are then saved together, so either both are saved or neither is (but see FR-7: a failed write is itself logged). On a Confirmed or Not Found outcome, the update of linked records that FR-12.4 describes is a separate step after the check is committed.

#### FR-5 Processing log
- Each entry records:
  - an entry number;
  - the customer (Customer No.; filled only for checks of a Customer, and blank for the Ship-to Address and Customer Bank Account entries). It still drives the Customer Card's log action, but the log page hides this column by default (see below);
  - the **Record No.** (SC-2, log field 29, up to 100 characters): the number or key of the record whose address was checked, such as the customer, vendor or employee number. For a record with a two-part key, such as a ship-to address, the parts are joined with " / " (for example "C00010 / MAIN"). It is blank for Company Information, whose key is blank. It is written for every new entry and, by the SC-2 upgrade (FR-16.6), for existing ones;
  - the **source**: its table, the record (by its system ID, which survives renames), the **address type** (Main, or Ship-to for the company's ship-to address), and a **source description** made of the table name and the record's key, for example "Vendor 10000" or "Ship-to Address C00010 MAIN". The description never contains a name: the log stores no name of a customer, vendor, contact, employee or resource (the key itself can still identify a person; the User Guide says so);
  - when the check ran ("Checked At", shown to each user in their own time zone);
  - the user who ran it;
  - the result (Confirmed, Suggestion Accepted, Suggestion Ignored, Not Found, Error);
  - whether the suggestion was accepted (Yes/No);
  - the five original address values sent;
  - the five **suggested** values (Address, Address 2, City, State, ZIP Code) — **kept only for Suggestion Accepted and Confirmed**, and blank for Suggestion Ignored, Not Found and Error. This follows Google's rule that its results may be stored for 30 days, after which they must be deleted or replaced by data the end user confirmed (decision Q1); accepted values become end-user-confirmed customer data. An Error caused by a failed customer write therefore also keeps no suggested values;
  - the provider (Google Maps);
  - the validation granularity, the next action and whether the address is complete, as returned;
  - the delivery-point confirmation (Y, D, S, N or blank), kept when the provider returns it;
  - the provider message (the Google error message, the not-validated reason, or the write-failure text);
  - the user-facing message;
  - the HTTP status (0 when there was no response).
- The log never stores the API key, credentials or request URLs.
- The log is **read-only for everyone**. Entries can't be edited. Only administrators (the ADMIN permission set) can delete entries, and normally only through Retention Policy.
- **Who can read what (CR-1.1-01, confirmed by AJ Ansari, 2026-10-18, OQ-51).** The log copies the address of every source, including people (employees, alternative addresses, contacts, resources, bank accounts). A user of the USE set therefore has only **indirect** read on the log table (reading it through the log page, not directly), and the log page shows only the rows whose source table that user may read (a user who cannot read Employee does not see Employee entries). The ADMIN set keeps direct read and delete on the table, which Retention Policy needs, and the page filter does not cover that direct table access (ADMIN, or an export or analysis route that reads the table directly). This is not covered by an automated test; it needs a sandbox check with a USE-only user.
- The log page ("Google Address Validation Log", found in Tell Me search by "Google", "Google Maps" or "address validation") shows the newest entries first. Its default columns are Entry No., Source Table, Record No., Address Type, Checked At, User ID, Result, Accepted and the original and suggested address columns. Customer No., Source (the description) and Source Table No. are hidden by default and can be shown through Personalization. The Customer Card has a **Google Address Validation Log** action that opens the log filtered to that customer, and still shows the entries written by 1.0.0.0. Every other card in FR-10 has a **Google Address Validation Log** action that shows that record's entries only; Company Information shows both of its blocks.
- The log is registered with Retention Policy. Default retention is 2 years, set up as a custom retention period because Business Central's standard periods have no 2-year value (OQ-8). The retention policy is created **disabled** on install; an administrator enables it in Retention Policies, where the period can also be changed.
- For a check that ends in an error, the log entry is saved **before** the error message is shown, so it survives the failure.
- The log entry's customer link follows a **customer rename**: renaming a customer updates the customer number on its log entries. A renamed source of any kind keeps its entries (they are tied to the system ID); the description keeps the key as it was at the check.
- An entry can't be inserted without a source table, and an entry for a Customer can't be inserted without a customer number.
- Data classification: Customer Content (the source's system ID, field 26, included: it inherits the table's classification, CR-1.1-02), except the user, which is End-User Identifiable Information.
- Deleting a customer, or any other source record, does not delete its log entries.

#### FR-6 Setup
- **Setup card** ("Google Address Validation Setup", one per company; found in Tell Me search by "Google", "Google Maps" or "address validation"):

  | Setting | Default | Notes |
  |---|---|---|
  | Enabled | No | While this is off, the Customer Card action reports that setup is incomplete. |
  | Provider | Google Maps | One value in this version. Shown read-only. |
  | API Key | (blank) | Write-only: shown as a mask once saved, never readable. Typing the mask back in does not change the key. |
  | Default Country/Region Code (field name "US Country/Region Code" kept; caption changed by SC-4) | US | The country assumed for a record whose Country/Region Code is blank when Blank Country Handling is *Use default country* (FR-19.2); ignored for that purpose under *Let Google decide*. May be left blank: no region is then sent. It also decides which Country/Region record is filled in when several share one ISO code (FR-19.7). Changing it to a country that is not covered, turned off or without an ISO Code shows a message; the value is still saved. |
  | Blank Country Handling (SC-5, field 6, enum 92803) | Let Google decide | What happens for a record whose Country/Region Code is blank (FR-19.2, FR-19.3). *Let Google decide*: the country is worked out from the address. *Use default country*: the Default Country/Region Code is used. New installations and upgraded installations both get Let Google decide (no upgrade step; Deployment.md tells administrators to review it). |
  | Timeout (seconds) | 10 | |

- There is **no environment setting**: Google has no test environment. Automated tests never call Google (a simulated transport). Manual tests run against the live service with **real** addresses only (§7.1).
- The API key is stored in Business Central's isolated storage for the company, as a secret (encrypted when encryption is on). It is never stored in a table field and never appears in a URL, the log, messages or the debugger. The setup card also shows advice: use a key restricted to the Address Validation API and set a daily quota and a budget alert in the Google Cloud console.
- **Test Connection** checks the saved key, that the API is enabled, and that billing is on, **without a billable request where possible**: it sends a deliberately incomplete request (no address lines). A 400 invalid-request answer means the key and project are accepted ("The connection to Google Maps works. The API key was accepted."); a key, API-disabled, billing or restriction error is reported ("The connection to Google Maps failed. <reason>", with Google's own message appended when there is one). No address is checked and no customer data is sent. If the spike shows billing or API-enablement errors are not reported for such a request, Test Connection must instead validate one fixed, real public address, which is one billable request inside the free allowance (Q7; OQ-28). Test Connection also requires the privacy notice to be agreed to (FR-1): "The privacy notice for sending addresses to Google Maps has not been agreed to, so the connection was not tested."
- **Assisted Setup wizard**: a guided page ("Set Up Google Address Validation"; listed in Business Central's Assisted Setup as "Set up Google address validation", short title "Google address validation", re-registered each time the Assisted Setup page opens so a new title reaches companies where an older version is installed), where an administrator enters **only the API key** (it also explains that Billing and the Address Validation API must be enabled in the Google Cloud project, and that the service is turned on and tested on the Google Address Validation Setup page). The same storage and masking rules apply. The wizard does **not** enable the service, run Test Connection or change other settings. The key can also be entered on the setup card; the wizard is the guided first-time path. It counts as completed in Assisted Setup once the key is saved (OQ-16).
- **Supported Countries.** An action on the setup card opens the supported-country page (FR-19.1).
- **Outside Business Central (administrator, documented in Deployment.md):**
  - Create a Google Cloud project, enable billing, enable the Address Validation API, and create an API key.
  - Restrict the key to the Address Validation API.
  - Set a daily request cap (for example 100 per day) and a budget alert (for example $1) (OQ-25).
- **Permissions.** The extension's permission sets cover only the extension's own objects. Users also need their normal Business Central permissions: read and modify on the table whose address they check (FR-14), and the permissions of the linked records that Business Central updates with it (FR-9, FR-14).

#### FR-7 Error handling
No failure changes the record. Every failure that happens after the preconditions are met is logged, with no automatic retry of any kind; the one repeat is the region-free second request of FR-19.5, made only when a guessed region ends in Not Found (the log holds one entry for the check, the final result).

| Condition | Message to the user | Logged as |
|---|---|---|
| Setup disabled, no provider, or key missing | Address validation is not set up. Contact your administrator. | Not logged |
| The record isn't one this app can validate (a table or block outside FR-10) | Address validation is not available for this record. | Not logged |
| The record is blocked due to privacy (Privacy Blocked = Yes, or its parent's is; FR-17) | Address validation is not available for this record because it is blocked due to privacy. | Not logged |
| Record not found | For a Customer, "The customer was not found."; otherwise "The record was not found." | Not logged |
| The country is not one Google covers | Google Maps can't validate addresses in %1. (%1 = the country's name) | Not logged |
| The country is covered but turned off | Address validation isn't turned on for %1. Ask your administrator to turn it on in Google Address Validation Supported Countries. | Not logged |
| The country has no ISO Code and cannot be mapped | Google Maps can't tell which country %1 is. Fill in the ISO Code of this country or region on the Countries/Regions page and try again. | Not logged |
| Address blank, or no ZIP / postal code and no city (US and Canada: no ZIP / postal code and no city with its state or province) | Enter a street address and either a ZIP / postal code or a city (in the US and Canada, a city needs its state or province too). | Not logged |
| State or province given for the US, Puerto Rico or Canada is not a 2-letter code | Enter the 2-letter state or province code in the State field. | Not logged |
| Google finds the address in another country than the record says | Google Maps found this address in %1, but the record says %2. Check the country and try again. (a Not Found, logged) | Not Found |
| Record without a country, and Google places it in a country that is not covered or is turned off | The not-covered or not-turned-on text above for the country Google found (a Not Found, logged; the record's country stays blank) | Not Found |
| Privacy notice not agreed to | The privacy notice for sending addresses to Google Maps has not been agreed to, so nothing was sent. | Not logged |
| Key rejected (400 with reason API_KEY_INVALID, or 401) | Google Maps rejected the API key. Contact your administrator. | Error |
| API not enabled for the key's project (403 SERVICE_DISABLED) | The Address Validation API is not enabled in the Google Cloud project of this API key. Contact your administrator. | Error |
| Billing not enabled (403 BILLING_DISABLED) | Billing is not enabled for the Google Cloud project of this API key. Contact your administrator. | Error |
| Key restricted from this API (403 with a reason of the form API_KEY_…_BLOCKED) | The API key is not allowed to call the Address Validation API. Check the key's restrictions. Contact your administrator. | Error |
| Any other 403 | "Google Maps refused the request:" + Google message | Error |
| Request rejected (other 400 INVALID_ARGUMENT) | "Google Maps could not read the address:" + Google message | Error |
| Quota or daily cap reached (429) | The Google Maps request limit has been reached. Try again later. | Error |
| Server error (5xx), timeout, no connection | Google Maps is not responding. Try again later. | Error |
| Response can't be read (bad JSON, no verdict, validated but no usable address, or a validated answer with a blank street, city, state or ZIP) | Unexpected response from Google Maps. Contact your administrator. | Error |
| Answered, but not validated to building level | "Google Maps couldn't confirm this address." + reason (missing or unconfirmed parts of the address, when Google names them) | Not Found |

- Reading the response is field by field by name, tolerant of missing and extra fields and of null values. A missing boolean counts as false.
- When Google's error reason is absent, the HTTP status decides (400 could not read, 401 key rejected, 403 refused, and so on).
- The user sees Google's message text only for "refused" and "could not read" (above); for the other errors the user sees the fixed message and the log keeps Google's text in Provider Message. Test Connection failures show the fixed reason and append Google's message when there is one.
- **Known minor limitation (accepted by AJ Ansari 2026-10-16, CR9G-19):** when Google returns no message, the "refused" and "could not read" texts end after the colon; with a message, Test Connection may show it twice.
- If saving the record fails after the provider answered (for example the linked Contact cannot be updated, or a permission or another extension stops the save), the record stays unchanged, the check is logged as **Error** with the failure text, and the user sees that text. If the record is deleted while the suggestion is open, the save fails with "The <table> record no longer exists, so nothing was updated." (for a Customer this is a 1.1 change, FR-18).
- Checks never raise an unhandled error to the caller except the caller refusal in FR-1.7; the case where the platform itself raises instead of returning when outbound calls are blocked ("Allow HttpClient Requests" off) is to be verified in a sandbox (GA-10).

#### FR-8 Address Validated
- A Yes/No indicator on each customer, shown on the Customer Card in the **Address** group of the **Address & Contact** FastTab. The other sources carry the same indicator (FR-12). The rules below apply per source and per address block.
- Default **No** for every new record, and for records that exist when the extension is installed (the exceptions are in FR-12.2).
- **Users can't edit it.** Only the extension changes it, and only under these rules; no other extension can set it through this app.
- **Validated** (the provider's answer is usable as a suggestion) means `validationGranularity` is `PREMISE` or `SUB_PREMISE` (Q4), **and** a suggested Street, City, State and ZIP can be read.
- **Confirmed** means validated, and the suggestion equals the BC address under FR-3. Delivery signals do not stop Confirmed; the FR-4 warning line is added to the message (Q6, as narrowed by GA-07).
- **Not Found** means HTTP 200 with a readable verdict whose granularity is anything else (`ROUTE`, `PREMISE_PROXIMITY`, `BLOCK`, `OTHER`, unspecified or missing).
- Set to **Yes** when a check ends in **Accept** or **Confirmed**. For a user who is not allowed to modify customers, Confirmed does **not** set it (OQ-21).
- Reset to **No** when a check ends in **Not Found**, for a user who is allowed to modify customers (OQ-15; for other users it stays unchanged). Errors leave it unchanged.
- **Unchanged** when the user chooses Cancel/Ignore, closes the dialog, Accept is disabled or blocked, or the check ends in an Error.
- Reset to **No** when a validated record's Address, Address 2, City, State, ZIP Code **or Country/Region Code** is changed by a user afterwards. **The country is part of the validated address, for every source, the company's ship-to country included (CR-1.1-04, confirmed by AJ Ansari, 2026-10-18, OQ-52).** This replaces the 1.0 rule (OQ-14: "the country does not count") and the interim 1.1 rule (reset only when Business Central clears City, State or ZIP): a change of the country resets the indicator even when Business Central does not clear the address, and a change from blank to a country code (the fill-in of FR-18.6 is not such a change; it is assigned directly) resets it too. For Company Information, the company fields reset only the company indicator and the Ship-to fields (country included) only the ship-to indicator. Edits that write the fields without the standard field validation (some imports and integrations) may not be detected; this is a known limitation.
- The extension's own Accept does **not** count as an edit. After Accept the value is Yes.

#### FR-9 Side effects of updating the customer (recorded so they are not mistaken for defects)
- **Contact address sync (PRE-02 G3).** Accepting a suggestion updates the customer through the standard update, and the extension explicitly asks Business Central to keep the linked Contact (business relation) in step. A user who may modify customers but not contacts therefore gets the write-failure Error of FR-7 and the customer stays unchanged. See OQ-12; the platform behaviour is still to be confirmed in a sandbox (§4.1 h).
- **The Contact family (1.1).** Accepting on a Customer or Vendor updates the linked Contact, as above. Accepting on a Bank Account does the same: the extension asks Business Central to update the linked Contact. Accepting on a Contact lets Business Central update the linked Customer, Vendor, Bank Account and Employee and, when Marketing Setup "Inherit Address Details" is on, the company's persons whose address equalled the company's.
- **Employee → Resource.** Accepting on an Employee with a linked Resource updates the Resource's address, as Business Central does for a user edit.
- Company Information, Location, Responsibility Center, Ship-to, Order and Remit Address, both bank-account address tables and both alternative-address tables have no linked records that are updated.
- **No duplicate-contact form during Accept.** Standard Business Central can commit and open a modal duplicate-contact form when a company contact's address changes. The extension suppresses that form while it writes (the Accept finishes or fails as one step); a duplicate is still found the next time a user edits the contact.
- **The full standard update on linked records (GA-1.1-15).** The update of a linked Contact (or Resource) on Confirmed and Not Found (FR-12.4) is the whole standard update, not a flag-only write: the linked record's Last Date Modified changes and, if the Change Log is on for it, the change is recorded there.
- **Change Log (PRE-02 G6).** If the Change Log is turned on for a source table, it records the Accept as a field change, and Address Validated changes on Confirmed or Accept (on the tables that have a Change Log).
- **Last Date Modified** changes on Accept, and on Confirmed when Address Validated changes.
- **Open documents** are not updated (§1.1).
- **Tax Area Code** is not re-evaluated (§6.1).

#### FR-10 Address sources
Added in version 1.1 (scope change SC-1). Sixteen tables are address sources; Customer is the original one.

| # | Source (table) | Group | Card where the action and indicator appear | Address block(s) | Records BC keeps in step on Accept (FR-9) |
|---|---|---|---|---|---|
| 1 | Customer (18) | Sales and customer | Customer Card | main | Contact |
| 2 | Ship-to Address (222) | Sales and customer | Ship-to Address | main | — |
| 3 | Customer Bank Account (287) | Sales and customer | Customer Bank Account Card | main | — |
| 4 | Vendor (23) | Purchasing and vendor | Vendor Card | main | Contact |
| 5 | Order Address (224) | Purchasing and vendor | Order Address | main | — |
| 6 | Remit Address (2224) | Purchasing and vendor | Remit Address | main | — |
| 7 | Vendor Bank Account (288) | Purchasing and vendor | Vendor Bank Account Card | main | — |
| 8 | Company Information (79) | Company and org | Company Information | main **and** ship-to, independent | — |
| 9 | Location (14) | Company and org | Location Card | main | — |
| 10 | Responsibility Center (5714) | Company and org | Responsibility Center Card | main | — |
| 11 | Bank Account (270) | Company and org | Bank Account Card | main | Contact |
| 12 | Employee (5200) | People | Employee Card | main | Resource |
| 13 | Alternative Address (5201) | People | Alternative Address Card | main | — |
| 14 | Contact (5050), companies and persons | People | Contact Card | main | Customer, Vendor, Bank Account, Employee, persons (inherit) |
| 15 | Contact Alt. Address (5051) | People | Contact Alt. Address Card | main | — |
| 16 | Resource (156), persons and machines | People | Resource Card | main | — |

No other table is a source. Calling the validation for any other table or block is refused (FR-7) with nothing sent or logged.

#### FR-11 Validate Address on every source
1. Every card in FR-10 has a **Validate Address** action:
   - in Actions > Functions where the page has a Functions group (Customer, Vendor, Employee, Contact, Resource), otherwise under Actions;
   - promoted to the Process category where the page has one, otherwise to the page's promoted area.
2. **Company Information has two actions.** "Validate Address" checks the company address (Address, Address 2, City, County, Post Code, Country/Region Code). "Validate Ship-to Address" checks the Ship-to fields. Each has its own indicator, comparison, write and log entry.
3. Everything in FR-1 to FR-7 applies to each source and block:
   - save first;
   - preconditions in the same order;
   - the country rule (FR-19): the block's Country/Region Code, else the region given by Blank Country Handling (FR-19.3), decides the region, which must be supported and turned on;
   - the privacy notice;
   - one request, which carries no name, number or key of the record;
   - the same outcomes, dialog, Accept rules (lengths, concurrency, no truncation) and errors.
4. Every card also has a **Google Address Validation Log** action that opens the log filtered to that record (FR-5).
5. **The country is filled in (FR-18.6, 1.1.0.12).** When the check ends in Accept, or in Confirmed for a user who may modify the record, and the block's Country/Region Code is blank, the code is filled in with the country Google found, else the region that was sent (FR-19.7; 1.1.0.12 filled only the setup's US code). This applies to every source and block; a non-blank country is never changed, and Not Found never fills it in.

#### FR-12 Address Validated on every source
1. Each source table gets a read-only Yes/No **Address Validated**, shown next to its address on its card. Company Information gets a second one, **Ship-to Address Validated**, next to the ship-to address. The indicator is field number 92800 on every source table (field 92801 for the company's ship-to block): one number is shared on purpose, because standard Business Central copies Customer, Vendor, Bank Account and Contact into each other by field number (OQ-34).
2. Default No for new records and for records that exist at install or upgrade. Exceptions: Customer flags from 1.0.0.0 are kept and their linked Contacts are set (FR-16), and records that standard Business Central creates or updates from a validated linked record take that record's flag (point 4).
3. FR-8's set and reset rules apply per source and block:
   - set on Accept or Confirmed;
   - reset on Not Found for users allowed to modify that table;
   - unchanged on Ignore and Error;
   - reset when a user edits Address, Address 2, City, State, ZIP Code or Country/Region Code of that block (FR-8);
   - for Company Information, the company fields reset only the company indicator and the Ship-to fields only the ship-to indicator;
   - the country filled in by FR-18.6 is not an edit: the indicator is not reset by it (the code is assigned directly, without field validation, and for linked records the standard update copies it).
4. **Linked records (decided, OQ-35).** When standard Business Central copies an address between linked records, the copied record's indicator takes the value of the record it was copied from:
   - Customer, Vendor and Bank Account ↔ their Contact;
   - a company contact → its persons (Inherit Address Details);
   - a person linked to a company;
   - Contact → Employee;
   - Employee → Resource.

   A Confirmed or Not Found on a Customer, Vendor, Bank Account or Contact also updates the indicator of its linked records, and on an Employee also its Resource. How that update works, as built:
   - It is the **full standard update** of the linked Contact (or Resource), not a flag-only write (FR-9, GA-1.1-15).
   - It runs as a **separate step after the check is committed**, only for a user allowed to modify the checked table, and **only when the linked record's indicator actually differs** (D1). It runs with the Write Guard bound, so the duplicate-contact form cannot interrupt it (D2).
   - Before a Contact is updated, the user's write permission on Contact is checked; before a Resource is updated, read permission on Resource. If the user lacks it, if the update fails, or if nothing differs, the linked record is left unchanged and the check still completes and stays logged.
   - **Exception for a Contact source (D3).** When the source itself is a Contact, the update of its linked Customer, Vendor, Bank Account, Employee and persons is part of the write, exactly as on Accept; a failure there is logged as Error and the Contact's indicator is unchanged. This was decided by the Main role under AJ Ansari's instruction to complete without questions (2026-10-18, Opus review D3) and was **confirmed by AJ Ansari on 2026-10-18** (OQ-50): the linked update is standard Business Central behaviour and is kept as part of the write.
   - **A person follows its company's indicator only when the company's address (country included) or the company's indicator changed in that modify (D4).**
5. **Known limitation:** writes outside these links that skip field validation (imports, configuration packages, the assisted company setup wizard, other extensions) are not detected. This is the same limitation as 1.0.0.0.

#### FR-13 Log for every source
FR-5 applies to every source as written there. The retention policy, the read-only rule, ADMIN-only deletion and the data classification are unchanged from 1.0.0.0; the read restriction for USE users is in FR-5 (CR-1.1-01).

#### FR-14 Permissions per source
- The USE set lets a user run Validate Address on every source and gives indirect read on the log (FR-5): the log page shows only entries whose source table the user may read. ADMIN keeps direct read and delete on the log table, for Retention Policy.
- To accept, or to change the indicator, the user needs modify permission on the source's table. Confirmed and Not Found change the indicator only for such users (FR-8, per table).
- The records Business Central updates with it (FR-9) need their normal permissions:
  - Contact, for Customer, Vendor and Bank Account;
  - Customer, Vendor, Bank Account and Employee, for a linked Contact;
  - Resource, for an Employee with a linked resource.
- On Accept (and, for a Contact source, on Confirmed and Not Found) a failure there is logged as Error and nothing is changed (FR-7). For the separate linked-record step after a Confirmed or Not Found on the other sources, a missing permission only leaves the linked record unchanged (FR-12.4).
- Company Information normally needs an administrator.

#### FR-15 Contacts: companies and persons
- Company and person contacts are validated the same way. The action is shown for both.
- A person whose address was inherited from its company keeps its own indicator. It follows the company's only through FR-12.4.
- Accept on a person never changes its company.

#### FR-16 Upgrade from 1.0.0.0
1. Installing 1.1.0.0 or later over 1.0.0.0 keeps all data and needs no reinstall (Schema Sync Mode: Add).
2. Every existing log entry becomes a Customer entry: source table Customer, address type Main, the customer's system ID when the customer still exists, description "Customer <No.>".
3. Customer indicators are kept.
4. Each validated customer's linked Contact is marked validated when its address equals the customer's.
5. Each step runs once per company, never on a fresh install, and never twice (Standards §9.3, §9.6). The upgrade steps use explicit upgrade tags, not `SetAllUpgradeTags()`, a recorded departure from Standards §9.3's preferred form (decided by AJ Ansari, 2026-10-17): `SetAllUpgradeTags()` raises the tag event to every installed app and would mark other extensions' pending upgrades as done on an install into an existing company.
6. **SC-2 (1.1.0.10): Record No.** A third step, codeunit 92814 "obcfgav Upgrade Record No." with its own tag, fills the new log field Record No. on existing entries once per company: from Customer No. when it is present, otherwise from the key of the source record found by its system ID (parts joined with " / "), and left blank when the record no longer exists or its key is blank. It runs on an upgrade from any earlier version, never on a fresh install. The schema change (log field 29, buffer field 34) is additive: Schema Sync Mode Add.

#### FR-17 Privacy Blocked
- A record with **Privacy Blocked = Yes** is not validated: the action explains "Address validation is not available for this record because it is blocked due to privacy.", nothing is sent to the provider and nothing is logged. This applies to Customer, Vendor, Contact, Employee and Resource, Customer included.
- The same applies to a child source whose parent is blocked: Ship-to Address and Customer Bank Account (Customer), Order Address, Remit Address and Vendor Bank Account (Vendor), Alternative Address (Employee), Contact Alt. Address (Contact).
- Other sources have no such field and are not affected.
- The check runs after the record is found and before the setup, country and address checks.

#### FR-18 Customer changes in 1.1
These are the only changes to Customer behaviour (six, FR-18.1 to FR-18.6; FR-18.6 applies to every source, not only to Customer); all 1.0.0.0 message texts stayed verbatim and the 61 existing tests were expected to pass unchanged **until SC-4 (1.2.0.x), which changed that commitment**: the incomplete-address message, the state-code message and the State and ZIP captions ("State / Province", "ZIP / Postal Code") now use country-neutral wording, the US-only message is gone, and two of the 61 tests (tests 7 and 29) now use Russia instead of Canada as the refused country. The main role took this decision and it **awaits AJ Ansari's confirmation** (OQ-58). The six changes:
1. Privacy Blocked refuses validation (FR-17).
2. A Customer that disappears while the suggestion is open gives the generic "The Customer record no longer exists, so nothing was updated."
3. A Confirmed or Not Found also updates the linked Contact's indicator (FR-12.4).
4. **The country is part of the validated address** (FR-8, CR-1.1-04): a change of Country/Region Code resets Address Validated, whether or not Business Central clears the address, and a change from blank to a country code (the fill-in of FR-18.6 is not such a change; it is assigned directly) resets it too. (1.0.0.0: the country did not count. Interim 1.1 text: only a change that clears City, State or ZIP.)
5. The standard duplicate-contact form no longer interrupts an Accept (FR-9).
6. **A blank country is filled in (1.1.0.12, applies to every source).** When a check ends in Accept, or in Confirmed for a user who may modify the record, and the record's Country/Region Code is blank, the code is filled in with the country Google found (the result region, mapped through the Country/Region ISO Code), else the region that was sent (FR-19.7; generalises the US-only fill of 1.1.0.12). It is assigned directly, with no field validation, so the Address Validated indicator is not reset by it; for linked records the standard update copies it. A non-blank country is never changed, and Not Found never fills it in. The record's own address block is the one used: the Company Information ship-to block fills the ship-to country, the company block the company country. On Accept the fill-in is part of the same write as the five suggested values; on Confirmed it is a write of its own (the indicator and the country together). Automated tests TestAcceptSetsUsCountry, TestConfirmedSetsUsCountry and TestNotFoundKeepsBlankCountry (US cases) and, from SC-4, TestBlankCountryFilledFromResult; manual case TC-44.

#### FR-19 Countries (SC-4, main 1.2.0.0 and 1.2.0.2; blank-country handling SC-5 and SC-5a, main 1.2.0.3 and 1.2.0.4; not installed or run)
Validation works in the 40 regions Google's Address Validation API covers, not only the US. The list was read from <https://developers.google.com/maps/documentation/address-validation/coverage> on 2026-10-18. AJ Ansari asked for all 40 and chose that all are enabled by default. This section replaces every earlier statement that validation is US only.

1. **Supported-country table (table 92803) and page (page 92804).** One row per region: Region Code (2 letters, key), Name, Enabled, Preview, Residential and Commercial Data, USPS Delivery Data. The 40 regions are AR, AT, AU, BE, BG, BR, CA, CH, CL, CO, CZ, DE, DK, EE, ES, FI, FR, GB, HR, HU, IE, IN, IT, JP, LT, LU, LV, MX, MY, NL, NO, NZ, PL, PR, PT, SE, SG, SI, SK and US. **All are enabled by default.** Preview is set for India and Japan (Google lists them as not yet generally available); Residential and Commercial Data is off for Colombia, Italy and Singapore; USPS Delivery Data is on for the US and Puerto Rico only. The page "Google Address Validation Supported Countries" is opened from the setup card (action Supported Countries) or by Tell Me search; it cannot add or delete rows, and **Enabled is the only editable field** (and only for a user who may write the table: the ADMIN set). A region that is turned off is refused (FR-19.9).
2. **Default Country/Region Code and Blank Country Handling (SC-5, SC-5a).** The setup field named "US Country/Region Code" keeps its name and has the caption "Default Country/Region Code". A second setup field, **Blank Country Handling** (Setup table field 6, enum 92803, closed with two values, `Extensible = false`), says what a record with a blank Country/Region Code gets: **Let Google decide** (the default for new and upgraded installations) or **Use default country**. Under *Use default country* the Default Country/Region Code is the region for every blank-country record; when it is blank, no region is sent and nothing is guessed (as in 1.2.0.2). Under *Let Google decide* the Default Country/Region Code is not used as the region, only to choose among Country/Region records that share an ISO code (FR-19.7). The Setup page warns when the default is not covered, turned off or has no ISO Code.
3. **How the region is chosen.** The block's own Country/Region Code decides first: its Country/Region record's ISO Code is the region; the code `UK` maps to `GB` when the record has no ISO Code; any other 2-letter code with no ISO Code is used as it is. A country that cannot be mapped stops the check with the ISO-Code message (FR-19.9). When the record has no country: under **Use default country**, the Default Country/Region Code is mapped the same way (blank default = no region, no guessing). Under **Let Google decide**, the region is worked out from the record in this order: (a) the postal code has the Canadian form A1A 1A1 (spaces and hyphens ignored; letters and digits alternate) = **CA**; (b) otherwise the State is one of the codes of the 50 US states, DC, PR, AA, AE and AP, and the Post Code (spaces and hyphens ignored) is all digits and 5 or 9 long = **US**; (c) otherwise **no region** is sent and Google works the country out from the address. A region chosen in (a) or (b) is a *guessed* region (see FR-19.5 for the repeat). Guam, the US Virgin Islands, American Samoa and the Northern Mariana Islands are not in the list (Google does not cover dependent territories). A region that is chosen must be in the table and turned on; when none is chosen, the result region is checked instead (FR-19.6 b).
4. **Input rules per region** (checked before anything is sent; nothing is logged when one fails): **US and PR** — a street, plus a ZIP-like Post Code (first five characters digits) or City and State; State, when filled in, is a 2-letter code. **CA** — a street, plus a postal code of the form A1A 1A1 (spaces and hyphens ignored) or City and Province; Province, when filled in, is a 2-letter code. **All other regions** (and no region) — a street plus a City or a Post Code; no state rule.
5. **The request.** `regionCode` is sent only when a region is known (FR-19.3). `enableUspsCass` is sent only for US and PR, so a record recognized as US gets USPS delivery data and a record with no region does not. The request never carries a name or number (FR-1.4). **One repeat (SC-5a):** when the region was guessed from the address (Let Google decide; US or Canada) and the check ends in Not Found, for any reason including a region mismatch, the request is sent once more with no region, and the second answer is the one used and logged; the first answer is not logged. This is the only retry; it costs one extra billable request only in that case. It exists because the guess can be wrong: an Italian province code such as MI, PA, CA or AL is also a US state code, and a 5-digit Italian postal code looks like a ZIP code. Test Connection is unchanged (an incomplete probe).
6. **Handling the result.** (a) **Region mismatch:** when a region was sent and Google places the address in a different one, the check ends as **Not Found** with the mismatch message; the US and Puerto Rico count as one region for this test. (b) **No region sent:** when the record has no country, no region was sent and Google names one, that country must be in the table and turned on; otherwise the check ends as Not Found with the not-covered or not-turned-on message and the record's country stays blank. This is also the check made after the repeat request of FR-19.5. (c) **A suggestion must be usable:** for the US, Puerto Rico, Canada and an unknown region it needs street, city, state and ZIP / postal code, as before. For every other region, when Google's answer has no state, city or postal code, the record's own value is kept rather than blanked; the suggestion needs a street and a city or a postal code. (d) **Extra lines:** address lines after the first, and failing that Google's `sublocality`, go to Address 2. (e) The ZIP+4 format `12345-6789` applies only to the US, Puerto Rico and an unknown region.
7. **Country fill-in (generalises FR-18.6).** On Accept, and on Confirmed for a user who may modify the record, a blank Country/Region Code of the checked block is set to the Business Central code of the country Google found (the result region), else of the region that was sent (a default country or a guessed US or Canada). The code is found through the Country/Region ISO Code (the setup default is preferred when it maps to the same region); if no Country/Region matches, the country stays blank. A non-blank country is never changed, and Not Found never fills it. The comparison dialog shows a line, captioned Country/Region, "The Country/Region will be set to X." when the record has no country and a code can be found (so a Danish address without a country shows Denmark).
8. **Seeding and upgrade.** The 40 rows are inserted at install, at company initialization and by the upgrade codeunit 92816 (once per company, with its own upgrade tag, also set on a fresh install); the page seeds an empty table on open for a user who may write it. Seeding only adds missing rows and never changes Enabled. An upgrade from 1.1.x therefore **enables all 40 countries** (see FR-19.11).
9. **Messages** (exact texts in FR-7): the country is not covered ("Google Maps can't validate addresses in %1."); not turned on ("Address validation isn't turned on for %1. Ask your administrator to turn it on in Google Address Validation Supported Countries."); ISO Code missing ("Google Maps can't tell which country %1 is. Fill in the ISO Code of this country or region on the Countries/Regions page and try again."); region mismatch ("Google Maps found this address in %1, but the record says %2. Check the country and try again."). The incomplete-address and state-code messages and the State and ZIP captions are country-neutral (FR-18 intro).
10. **Permissions.** USE reads the table, runs the page and the country codeunit; ADMIN has full access to the table (turns countries on and off).
11. **Cost and privacy.** Every country uses the same Address Validation Pro SKU: 5,000 free requests a month, then about $17 per 1,000, shared by all countries; Google gives a higher free allowance (35,000 a month) only to billing accounts that are billed at India pricing; that depends on your Google billing account, not on the country of the address, and no separate API key is needed for India (G9). USPS delivery data (CASS, DPV) exists only for the US and Puerto Rico. **Privacy:** with all 40 enabled after an upgrade, addresses outside the US, including those of employees and contacts, can now be sent to Google when a user runs Validate Address. Nothing is sent without that action. Administrators should turn off the countries they do not want on the Supported Countries page; Deployment.md says so. **A failed guess can cost a second request (SC-5a):** under Let Google decide, a record whose region was guessed from its state and ZIP code or postal code, and whose first check ends in Not Found, is checked again without a region, so that check is two billable requests instead of one (FR-19.5).
12. **Not proven.** Live Google responses outside the US have not been seen, and neither has what Google does when no region is sent (the Danish and Italian cases), nor what Google answers first for an address whose region was guessed wrongly: the shape of `administrativeArea` (a code or a name), the use of `sublocality`, and the address shapes of Brazil, Mexico, India and Japan. A live probe per country with real addresses is recommended before relying on a country (OQ-59). Review items not done: OQ-60.
13. **Tests.** Acceptance tests 48–69; automated codeunit 92838 (21 tests: 15 for SC-4, 4 for SC-5 and 2 more for SC-5a, one of the SC-5 four reworked) and the two changed tests 7 and 29. The test library selects Use default country, so the 1.0 and 1.1 tests keep their meaning.
14. **Known limits (SC-5a; decisions awaiting AJ Ansari, OQ-61 to OQ-64).** (a) A US record without a recognizable state and ZIP shape (state missing, spelled out, or a ZIP code that is not 5 or 9 digits) gets no USPS delivery data under Let Google decide, because no region is sent; US-only companies should choose Use default country. (b) Existing installations switch to Let Google decide when 1.2.0.3 or later is installed, with no upgrade step; administrators should review the setting (Deployment.md). (c) The guess cannot tell a US address from another country's address that uses a US state code and a 5-digit postal code (Italian provinces MI, PA, CA, AL, and so on); the repeat without a region (FR-19.5) is the remedy, and setting the country on the record is the sure one.

## 2. Business objectives and value
| # | Objective | Value delivered | Measured by |
|---|---|---|---|
| O1 | Correct, consistently formatted US customer addresses | Fewer returned or misdelivered mailings and shipments; addresses in standardized form (USPS CASS when available) with ZIP+4 | Share of checks ending Confirmed or Suggestion Accepted; acceptance tests 1–2 |
| O2 | One-click correction without retyping | Faster maintenance and no typing errors when the suggestion is accepted | OK writes all five values exactly as returned (test 2) |
| O3 | Auditability | Each check shows who, when, what was sent, what the provider answered and the decision | One log entry per check that reaches the provider (tests 1–9) |
| O4 | Stay inside the free allowance and the provider terms | No recurring cost at under 5,000 checks a month | One request per check (two only when a guessed region fails, FR-19.5), no other retries, a daily cap and a budget alert set (tests 9, 10, 14, 69) |
| O5 | Quick, safe onboarding | An administrator can enter the API key without exposing it | Wizard listed in Assisted Setup; key never displayed after entry (tests 14, 21) |
| O6 | Visible validation status | Users can see whether a customer's current address has been validated | Address Validated follows FR-8 (tests 15–20) |
| O7 | Validated addresses across master data, in the 40 countries Google covers | The same one-click check and status on every master-data record that holds an address | FR-10 to FR-12; tests 24–33 |

## 3. Target consumers
| Consumer | Kind (user / system / AI tool / report) | What they need from the extension |
|---|---|---|
| Staff who maintain customers, vendors, contacts, employees, resources, locations and bank accounts | User | The Validate Address action on each card in FR-10, the outcome messages, the comparison dialog with OK/Cancel, the Address Validated indicator, and the per-record log action. Needs the USE set plus their normal permission to modify the record's table and, for Accept on a linked record, the linked record's table (FR-14). |
| Administrators | User | The setup card (enable, default country, timeout, API key, Test Connection), the Assisted Setup wizard for the key, log deletion and Retention Policy; also Company Information and Responsibility Centers. Needs the ADMIN set, plus the Google Cloud project: billing, API enablement, key restriction, quota cap, budget alert. |
| Auditors / compliance | User | Read-only access to the processing log: who, when, what was sent, what the provider answered, whether it was accepted (OQ-11), limited to the source tables they may read (FR-5). |
| Google Maps Platform Address Validation API | System (external provider) | Receives one POST per check, never the customer name or number, with the API key in a header. |
| Retention Policy (standard BC) | System | Deletes old log entries on the configured schedule. |
| Automated test app | System (test) | A way to simulate provider responses so automated tests never call Google (OQ-17). |
| Reports, BI tools, AI tools | — | None in this version. The log is available on a standard list page only. |

## 4. Platform requirements
From Parameters §1.1 and §1.4:
- **Deployment:** Business Central online, per-tenant extension (SaaS PTE). Publisher OnlyBCFans. Namespace OnlyBCFans.GoogleAddress.
- **Version:** Business Central 2026 release wave 1 (28.0) minimum; recommended 28.5. AL runtime 17.0.
- **Localization:** United States wording. The address fields the extension reads and writes are the same in every localization. Validation works in the 40 countries of FR-19; the Country/Region record needs an ISO Code to be mapped to a region.
- **Symbols used for design:** BC 28.5 W1 symbols (System Application, Base Application, Application, Business Foundation). Any US-specific caption or field must be checked against a US sandbox before design relies on it (OQ-19).
- **Outbound internet access:** the environment must allow this extension to make outbound HTTP calls ("Allow HttpClient Requests" in Extension Management), to `addressvalidation.googleapis.com`. Sandboxes, especially ones copied from production, can block them (OQ-20).
- **Dependencies:** Microsoft apps only. The test app depends on this app.
- **Object IDs:** main app 92800–92829, test app 92830–92849 (Parameters §1.2); IDs are allocated per object type (Standards §5.0). Main app `idRanges` `[92800–92829]`; test app `[92830–92849]`.

### 4.1 Verified platform capabilities
Checked on 2026-10-10 (a–l), 2026-10-11 (m, n) and 2026-10-17 (o–x), from the symbols in `.alpackages/` (BC 28.5 W1) and Microsoft Learn only where symbols can't answer.

| # | Capability the FRD relies on | Verified? | How checked | Result and consequence |
|---|---|---|---|---|
| a | Customer has Address, Address 2, City, County, Post Code and Country/Region Code at the spec's lengths | **Yes** (W1) | Symbols: Customer table fields | Address 100, Address 2 50, City 30, County 30, Post Code 20, Country/Region Code 10. In W1 the captions are "County" and "Post Code". The **US captions "State" and "ZIP Code" are not verified** because only W1 symbols are available (OQ-19). |
| b | An extension can call the Google service over HTTPS, and sandboxes can block it | **Yes** (Learn and symbols) | Learn, "Call external services with the HttpClient data type"; symbols: "Allow HttpClient Requests" | Calls must be allowed per extension. The endpoint is public. Learn's wording ("blocked by default") doesn't state the production default (OQ-20). |
| c | The API key kept as a secret in isolated storage, per company | **Yes** (Learn and symbols) | Learn: secret storage from runtime 13.0, company scope; symbols: secret text type used across the System Application | Supported. One key per company. The encrypted-storage value has a 215-character limit; Google API keys are shorter, but the length is checked at the spike. Isolated storage is per app, so the test app can't read this app's stored values directly. |
| d | A wizard can be registered in Assisted Setup | **Yes** (symbols) | Symbols: Guided Experience codeunit, Assisted Setup group enum, wizard page type | Supported. |
| e | A custom log table can be registered with Retention Policy | **Yes** (symbols) | Symbols: Retention Policy allowed-tables and retention period tables | Supported. **No standard "2 Years" period exists**, so a custom period is used (OQ-8). |
| f | A modal dialog page type exists for the comparison | **Yes** (symbols) | Symbols: StandardDialog page type | Supported. The standard dialog has fixed OK/Cancel buttons (FR-4). |
| g | A Yes/No field added to Customer can be shown read-only on the Customer Card in the address area | **Yes** (symbols) | Symbols: Customer table and card extensible; FastTab "Address & Contact" with group "Address" | Supported. |
| h | Customer save syncs the linked Contact (G3) | **Partly** | Symbols: the contact-update codeunit exists; the call from the save logic is code, which symbols don't show | FR-9 expects it, and the extension asks for it explicitly. Confirm in a sandbox (GA-25). |
| i | Change Log can record customer field changes (G6) | **Yes** (existence) | Symbols | Whether anything is recorded depends on each company's Change Log setup. |
| j | Customer carries a Tax Area Code (6.6) | **Yes** (W1) | Symbols | The limitation in §6.1 is real. |
| k | Automated tests can simulate responses without calling the provider | **Not in a SaaS sandbox through the platform feature** | Learn: the mock feature is on-premises only | Met by a replaceable HTTP layer in the app (OQ-17). |
| l | Checked At is shown in each user's own time zone | **Not verified from symbols** (platform behaviour) | Taken from the spec | Acceptance test 11 checks it manually. |
| m | A secret-text request header and a secret-text request URI are available | **Yes** (Learn) | Learn: HttpHeaders.Add with SecretText and HttpRequestMessage.SetSecretRequestUri, both from runtime 12.0 | Supported on runtime 17.0. The key is sent as a secret-text header. |
| n | Google's response fields, verdict semantics, error shape and billing events (Appendix A) | **From documentation; the live contract is checked at the spike** | Google documentation, 2026-10-08 to 2026-10-11 | See Appendix A and OQ-33. |
| o | The 15 added tables have the six address fields at the Customer lengths | Yes | Symbols | Every length 100/50/30/30/20/10 (TDD 15.22) |
| p | Each card can host a read-only field and the actions | Yes | Symbols + compile probe (AL 18.1) | `area()` is not allowed in a page extension. `addlast(Processing)` / `addlast(Promoted)` / `addlast(Navigation)` work even where the page has none (Vendor Bank Account Card has no actions at all) |
| q | Which tables standard BC copies by field number | Yes | Base App source | Customer, Vendor, Bank Account ↔ Contact (TransferFields) |
| r | Which standard copies use direct assignment | Yes | Base App source | Company contact → persons, Contact → Employee, Employee → Resource. Integration events exist on each |
| s | A Country/Region change clears City/ZIP/State | Yes | Base App source (Post Code.CheckClearPostCodeCityCounty) | Background to FR-8; the extension now resets on any country change, cleared or not |
| t | TransferFields copies table-extension fields with the same number | **Not verified** (platform behaviour) | — | Test 32 |
| u | xRec equals Rec on a code-driven modify | **Partly** (stated in Base App Contact code) | Base App source | Why the extension calls the Bank Account and Employee sync itself (FR-9) |
| v | The standard duplicate-contact form can open inside a write | Yes | Base App source (Contact.CheckDuplicates; event OnBeforeLaunchDuplicateForm) | FR-9: suppressed while the extension writes |
| w | Employee → Resource update ignores a flag-only change | Yes | Base App source (IsResourceUpdateNeeded; event OnAfterCalculateResourceUpdateNeeded) | FR-12.4: the extension makes the flag count |
| x | Page anchors | Yes for W1 symbols and a compile probe; **not** for the US-localized pages | Symbols | First US sandbox install of the new cards |

## 5. Design rules
The constraints every object must follow:
- **One record (address block) per user action.** No automatic, background, batch or scheduled validation. The orchestration and the provider service refuse callers other than this app (FR-1.7). *Source: spec; cost; provider terms.*
- **Store the provider's values as returned; never truncate.** If a value doesn't fit, Accept is blocked. The only reformatting is ZIP+4 as `12345-6789`. *Source: spec; provider terms.*
- **No failure changes the record.** Every check that reaches the provider writes exactly one log entry. Nothing is written until the provider call and the dialog have finished. *Source: spec.*
- **Secrets stay secret.** The API key is never stored in a table field. It never appears after entry, or in the log, messages or debugger output, and never goes into a URL. *Source: spec; Google guidance.*
- **No retries of any kind.** *Source: spec.* **Exception since SC-5a (FR-19.5):** one repeat without a region when a guessed region ends in Not Found.
- **All provider-specific request and response handling lives in one codeunit per provider, behind a provider interface.** A second provider is one new codeunit plus one enum value. The shared buffer is the neutral contract between provider and orchestration and uses DPV and Google verdict terms (Gap Analysis GA-11). The provider enum is not extensible. *Source: spec risk mitigation; decision Q10.*
- **The customer's name and number are never sent** to the provider. *Source: spec.*
- **Never send made-up addresses to the live service** (Google terms §10.2, Appendix A G14). Manual and spike tests use real addresses.
- **Google results shown to users carry the "Google Maps" attribution** (Appendix A G13).
- **Address Validated is changed only by the extension**, under the rules in FR-8, and by standard Business Central when it copies an address between linked records, in which case the indicator travels with the address (FR-12.4). The class that writes the validation result and the log is internal to this app. *Source: Parameters §1.6a.*
- **Extend, never modify, standard objects.** The 16 source tables and their cards (FR-10) are extended.
- **The log never stores a name;** a source is identified by table, system ID, key and address type. *Source: Standards §10.1.*
- **Mutability follows the data** (Standards §2.2): setup is editable (administrators only); the log is an audit table and read-only to everyone; each source is master data and is written only by Accept or Confirmed, and only the five address values plus Address Validated (and the linked records of FR-9).
- **Permission sets are deliverables.** Every table the extension owns is granted in the sets, which are named with the prefix `OBCFGAV` and App Code `GAV`, within 20 characters: `OBCFGAV GAV, USE` and `OBCFGAV GAV, ADMIN` (OQ-11). Users also need their normal permissions on the table they check and on the linked records (Standards §5.3 deployment note).
- **Identity.** Every object name starts with the prefix `obcfgav` and stays within 30 characters. The namespace is OnlyBCFans.GoogleAddress. Object names in §6 are indicative; the final names are in the TDD.
- **IDs** come from 92800–92829 (main app) and 92830–92849 (test app), allocated per object type, with at least 10 IDs per type kept unallocated at the top (Standards §5.2).
- **Enums, not options.**
- **US wording**, with all user-facing text as labels and no translation files (Standards §1.7; Parameters §1.9). Since SC-2 the Setup, wizard and Log captions start with the provider's name so the Setup and Log pages are found in Tell Me search by "Google" ("Google Address Validation Setup", "Set Up Google Address Validation", "Google Address Validation Log", and the log action on every card); the provider's name also appears in messages, the attribution line and the privacy notice. (Through 1.1.0.8 the captions were provider-neutral.)

## 6. Entity and object inventory
Read vs. read/write per Standards §2.2. Names are indicative only (the TDD finalizes them). "US" would mean the object is only meaningful for US addresses; since SC-4 no object is.

| Entity | Source table (name) | Object type(s) | R / RW | Global or localized | Notes |
|---|---|---|---|---|---|
| Address validation setup | Setup (new) | Table | RW | Global | Single record per company. Settings in FR-6. The API key is **not** stored here (isolated storage). Administrators only. |
| Setup card | Setup | Page (Card) | RW | Global | Includes Test Connection and the key guidance. The provider is read-only; the key is write-only and masked. Administrators only. |
| Assisted setup wizard | Setup / isolated storage | Page (guided wizard) | RW | Global | API key (kept when already saved), Default Country/Region Code (blank until chosen) and Blank Country Handling (default Let Google decide). Listed in Assisted Setup. Administrators only. |
| Validation log | Log (new) | Table | R (inserted by the extension only) | Global | One entry per check that reaches the provider, for any source (table, system ID, address type, description; no name). Audit data, never edited. Deleted only by ADMIN or Retention Policy. Customer link follows a rename. USE has indirect read only; ADMIN has direct read and delete (FR-5). |
| Validation log list | Log | Page (List) | R | Global | Newest first. Shows only rows whose source table the user may read. Also opened from each card, filtered to that record (the Customer Card's filter is the customer). |
| Address comparison | (buffer; no stored data) | Page (modal standard dialog) | R | Global | Current vs. Suggested columns, changes in bold, delivery notes, attribution line, OK/Cancel. |
| Address buffer | (temporary) | Table (temporary) | — | Global | The neutral contract between the provider and the orchestration: original and suggested values plus verdict, DPV, message and the source (table, system ID, address type, description). |
| Validation result | — | Enum | — | Global | Confirmed, Suggestion Accepted, Suggestion Ignored, Not Found, Error. |
| Address provider | — | Enum (not extensible) | — | Global | A blank value and Google Maps. |
| Address provider interface | — | Interface | — | Global | What a provider must do (validate, test connection, display name, has credentials). |
| HTTP transport interface | — | Interface (test seam) | — | Global | Sends the request; replaced by a simulated transport in tests. |
| Per source: Address Validated (Customer and the 15 others; Company Information has two) | each FR-10 table | Table extension | RW (written by the extension only) | US | Default No; read-only to users; rules in FR-8 and FR-12. Field 92800 on every table, field 92801 for the company ship-to block. Customer's field 92800 is the same number on purpose. |
| Per source: card (Customer Card and the 15 others) | each FR-10 card | Page extension | RW (on Accept/Confirmed only) | Global, 40 supported regions (the action refuses others) | Validate Address action (promoted; under Functions where the page has them); Address Validation Log action; Address Validated shown read-only next to the address. |
| Address source map | the 16 source tables | Codeunit (internal) | RW | Global | Which fields hold each source's address; opens, reads and writes them through a record reference; Privacy Blocked and parent checks; the list of tables the user may read. |
| Address type | — | Enum (not extensible) | — | Global | Main, Ship-to. |
| Sync rules | Contact, Employee, Resource and the family | Codeunit (internal: the linked-record update, and subscribers) | RW | Global | The indicator follows standard address copies (FR-12.4). |
| Write guard | Contact | Codeunit (manual subscriber) | — | Global | Suppresses the duplicate-contact form during Accept and during the linked-record update. |
| Upgrade | Log, Customer → Contact | 3 upgrade codeunits + tag codeunit | W | Global | FR-16. |
| Address validation (orchestration) | the 16 source tables, setup, log | Codeunit | RW | US | Caller check, preconditions, privacy notice, comparison, dialog, update, logging, Address Validated rules, the linked-record step after the commit. |
| Address service | Setup | Codeunit | — | Global | Picks the provider, applies the timeout, caller check. |
| Google address client | — | Codeunit | — | US | The only Google-specific request and response logic: request, error mapping, tolerant reading of the response. |
| Credential management | Isolated storage | Codeunit | RW | Global | Stores and reads the API key; caller check. |
| Validation writer | the source record, log | Codeunit (internal) | RW | US | Writes the accepted address, Address Validated and the log entry together. |
| Install / setup registration | Retention Policy (standard), Privacy Notice, Assisted Setup | Codeunits | W (registration) | Global | Registers the log with Retention Policy (2-year default, disabled), the privacy notice, and the wizard. |
| Permission set USE | — | Permission set | — | Global | Run the action and the dialog, record log entries, indirect read of the log, register the privacy notice. |
| Permission set ADMIN | — | Permission set | — | Global | Includes USE; setup, wizard, key, direct log read and deletion. |
| Test app *(PRE-02 G7)* | — | Separate AL test extension (Google Address Validator Tests): simulated responses and test codeunits | — | — | 155 automated tests (six test codeunits). Depends on this app. IDs 92830–92849. |
| Source tables (existing; Customer and the 15 others) | the FR-10 tables | Standard | RW | Global | Reads the five address values and Country/Region Code. On Accept writes Address, Address 2, City, County (State) and Post Code (ZIP Code), and Address Validated. |
| Country/Region (existing) | Country/Region | Standard | R | Global | Its ISO Code gives the region sent to Google (FR-19.3); its Name is shown in messages; searched for the code to fill in. |
| Supported country | Supported Country (new, table 92803) | Table | RW (seeded by the extension; the administrator changes Enabled only) | Global | 40 rows, one per region Google covers; FR-19.1. |
| Supported countries page | Supported Country | Page (List, page 92804) | RW (Enabled only) | Global | "Google Address Validation Supported Countries"; opened from Setup or Tell Me. |
| Country management | Supported Country, Country/Region, Setup | Codeunit (internal, codeunit 92815) | RW (seed) | Global | Maps a country to a region, checks the region, finds the code to fill in; FR-19. |
| Upgrade: countries | Supported Country | Codeunit (upgrade, codeunit 92816) | W | Global | Seeds the 40 rows once per company on upgrade (FR-19.8). |
| Post Code (existing) | Post Code | Standard | R (not written) | Global | Accepted ZIPs are not added; the standard ZIP lookup must not override suggested values on Accept. |
| Contact (existing) | Contact | Standard | RW | Global | Validation target (FR-10), and still updated by sync: the address follows its Customer, Vendor and Bank Account, and they follow it (FR-9, OQ-12). |
| Employee, Resource, Customer, Vendor, Bank Account as linked records | the same tables | Standard | W (indirect, through standard sync) | Global | Updated by Business Central when a Contact or Employee is accepted (FR-9, FR-12.4). |
| Isolated storage (platform) | — | Platform storage | RW | Global | API key, company scope, as a secret. No token. |
| Privacy Notice (platform) | Privacy notice tables | Standard | RW (registration, approval) | Global | FR-1.3. |
| Retention Policy (existing) | Retention Policy tables | Standard | W (registration) | Global | Log clean-up. |

### 6.1 Deferred entities
| Entity | Reason deferred | Revisit at |
|---|---|---|
| Tax Area Code on Customer (Standards §6.6) | Tax-area updates are out of scope. **Known limitation:** accepting a different ZIP or state doesn't re-evaluate the customer's Tax Area Code, which can leave it stale. The user has to review it by hand. | Later scoping; acceptability is OQ-13 |
| Validate Address on list pages, any table (G4) | The cards only. It can be added later using the same logic. | Later scoping |
| Union (5209) | Out of scope (AJ Ansari, 2026-10-17). | Later scoping |
| Updating documents that copied an address | Out of scope (§1.1). | Later scoping |
| Countries beyond the 40 | Google does not cover them; they are refused (FR-19). | Only if Google extends its coverage |

## 7. Non-functional requirements
- **Compilation:** 0 errors, 0 warnings with the analyzers (Operating Rule 5), for both the app and the test app. Met for main 1.1.0.5 and tests 0.0.0.15 (ChangeLog SC-1h).
- **Performance:**
  - Exactly one HTTPS call per check.
  - Configurable timeout, default 10 seconds. The user waits while the call runs.
  - The permission check for modifying the source's table runs once per check.
  - A Confirmed or Not Found on a Customer, Vendor, Bank Account, Contact or Employee also updates its linked Contact or Resource: one extra modify, in a separate step after the check is committed, and only when the linked record's indicator differs.
  - The log page opens one record reference per source table once per page open to find the tables the user may read; it reads no data for that.
  - No background work.
- **Compliance / security:**
  - The API key is handled as a secret and never exposed (FR-6). If it is exposed, rotate it in the Google Cloud console and enter the new key in Business Central (add to the incident checklist).
  - The log is classified Customer Content, with the user as End-User Identifiable Information. The ADMIN set is restricted. The log holds the address of people (employees, contacts, resources); its read access is restricted by source table (FR-5), and the description holds a key, never a name.
  - Google terms: stored suggestions are limited to what Q1 allows (FR-5); the attribution line (FR-4); no artificial addresses (§5).
  - The consent text caveat of the privacy notice (FR-1.3).
  - No telemetry is emitted.
- **Deployment:**
  - SaaS PTE on BC 28.0 or later.
  - Upgrade from 1.0.0.0 to 1.1.x keeps all data (Schema Sync Mode Add; FR-16). Each 1.1 package so far, 1.1.0.10 included, has been additive only.
  - "Allow HttpClient Requests" turned on for this extension in every environment that uses it.
  - Go-live only with: billing on, API enabled, key restricted to the Address Validation API, daily cap and budget alert set, Test Connection passing.
  - An environment that ever held a USPS-named build (0.0.0.1–0.0.0.4) must uninstall it with "Delete extension data" before installing; nothing is recorded as ever installed (GA-26).
  - Package versioning per Parameters §1.1.
  - The test app is a separate extension and is not deployed to production.

### 7.1 Constraints and risks
| Risk | Effect | Mitigation |
|---|---|---|
| Pay-as-you-go: billing must be on; beyond 5,000 Pro requests a month it costs $17 per 1,000 (Appendix A G10) | Unexpected cost | Daily cap and budget alert; no batch; one request per check (two when a guessed region fails, FR-19.5); a Test Connection that bills nothing (FR-6) |
| Billing disabled, API disabled or key restricted | Every check fails | Specific messages (FR-7); Test Connection |
| Storing results is limited to 30 days, then delete or replace with end-user-confirmed data (G14) | A 2-year log of Google suggestions could breach the terms | Q1: suggestions kept in the log only for Accepted and Confirmed; accepted values become end-user-confirmed customer data |
| Artificial addresses for US/PR: Google stops USPS validation and reports the customer to USPS (G14) | Loss of CASS data, plus a report | Never test live with made-up addresses; automated tests use the simulated transport |
| Attribution and Terms of Use / Privacy Policy requirements (G13) | Terms breach | Attribution line in the dialog (done); the app's own Terms of Use and Privacy Policy (`app.json` fields are blank) are for AJ to check with the owner of the Google account terms (Q9, OQ-29) |
| Consent text of the platform privacy notice names Microsoft, not Google | Administrators and users see inaccurate wording | Cannot be changed by the extension; Deployment.md explains it (FR-1.3) |
| Provider formats change | Integration breaks | Tolerant reading; spike checklist; unexpected-response message |
| Daily cap reached | Checks fail until the next day | Clear 429 message; the administrator raises the cap |
| `uspsData` not always populated (G7), or only partly populated | No DPV note; a partly populated standardized address is rejected as an unexpected response | Notes fall back to verdict flags; suggested values fall back to Google's postal address when `uspsData` is absent. Whether a partial standardized address ever occurs is a spike question (OQ-33). |
| Other extensions in the tenant calling the provider | Billable, unlogged use of the company's key | Caller checks (FR-1.7); internal writer |
| The log copies the address of people (employees, contacts, resources, bank accounts) into rows any user of the USE set could read | Disclosure inside the company | Indirect read for USE and a source-table filter on the log page (FR-5, CR-1.1-01); ADMIN's direct access is by design; a sandbox check with a USE-only user is owed |
| The assumption that standard Business Central copies the indicator between linked tables by field number is a platform behaviour (§4.1 t) | Linked records show a wrong indicator | Automated test 32; first sandbox round |
| A failed test run can leave Company Information or Marketing Setup altered in the test company | Wrong test baseline | Recovery steps in the Automated Test Guide; tests run only in a company whose name contains TEST |

*A reading of Google Maps Platform Service Specific Terms (archived 2024-05-22 version; the current text to be confirmed), not legal advice.*

### 7.2 Acceptance tests and test app
The build is accepted when all of these (1–69) pass in a sandbox with the simulated transport (automated), and tests 1, 2, 4, 5 and 14 pass once against the live Google service with **real** addresses. Tests 24–47 are the 1.1 tests; tests 48–63 are the SC-4 country tests (7 and 29 changed in SC-4); tests 64–69 are the SC-5 and SC-5a blank-country tests. **Status of the 1.1.0.5 build: none has been run yet.** Version 1.0.0.0 was released after its own Step 12 round (ChangeLog 12-1, 12-2); nothing of 1.1 has been installed in any tenant (Gap Analysis GA-1.1-13; ChangeLog SC-1g waiver), so the first sandbox install of 1.1 and the first run of the 131 tests are owed at Step 12. The OQ-41 checkpoint after batch 1 was replaced by one install of the final package (ChangeLog B2-1/B3-1/B4-1).

| # | Scenario | Expected | How tested |
|---|---|---|---|
| 1 | Customer address already matches the suggestion exactly | Confirmed message; no dialog; log Confirmed, Accepted = No | Automated; live once |
| 2 | Address with a typo and no ZIP+4; user accepts | Dialog shows both versions with changes in bold; customer updated with the suggested values; log Suggestion Accepted, Accepted = Yes, both addresses stored | Automated; live once |
| 3 | Same as 2; user cancels, then repeats and closes with Esc | Customer unchanged both times; two log entries Suggestion Ignored, Accepted = No | Automated |
| 4 | A real street without a house number (Google returns ROUTE or OTHER granularity). No invented address. | Not-found message with the reason; customer unchanged; log Not Found | Automated; live once |
| 5 | Office building without a suite number (DPV D or `CONFIRM_ADD_SUBPREMISES`) | Missing-suite warning shown; Accept still available | Automated; live once |
| 6 | Differs only in letter case or punctuation | Confirmed; no dialog | Automated |
| 7 | Country/Region Code RU (a country Google does not cover; was CA until SC-4) | "Google Maps can't validate addresses in <name>."; no provider call; no log entry | Automated |
| 8 | Wrong API key | Key-rejected message; log Error with HTTP status 400 (or 401 / 403; the spike confirms which) | Automated; live at the spike |
| 9 | Simulated 429 and timeout | Correct message for each; log Error; exactly one request each, no retry | Automated |
| 10 | Any check | Exactly one request; it carries no customer name or number and no key in the URL | Automated |
| 11 | Two users in different time zones open the same log entry | Each sees Checked At in their own local time | Manual |
| 12 | User without permission to modify customers | Check runs; the dialog shows that Accept is not possible; OK closes as Ignore; customer unchanged | Manual |
| 13 | Unsaved address edit, then Validate Address | The edited address is the one sent | Manual |
| 14 | Setup page | API key never displayed after entry; Test Connection succeeds with a valid key and the Google Cloud console shows no billable request for it | Manual; live once |
| 15 | Accept on a customer whose Address Validated is No | Address Validated = Yes | Automated |
| 16 | Confirmed outcome | Address Validated = Yes; address fields unchanged | Automated |
| 17 | Cancel or Esc, starting from No and starting from Yes | Address Validated unchanged in both cases | Automated |
| 18 | User edits the address of a validated customer and saves | Address Validated = No | Automated |
| 19 | Customer Card | Address Validated shown in the Address group of Address & Contact; not editable | Manual |
| 20 | New customer | Address Validated = No | Automated |
| 21 | Assisted Setup wizard | Listed in Assisted Setup; saves the API key (shown masked and kept when one is already saved), the Default Country/Region Code and Blank Country Handling; Enabled, Provider and timeout untouched | Manual |
| 22 | API not enabled, or billing disabled | The specific FR-7 message; log Error | Automated; live once at the spike |
| 23 | Comparison dialog | Shows "Suggestion from Google Maps" | Manual (also covered by one automated test) |
| 24 | Each FR-10 card (the 16 sources, and the company ship-to block as a 17th address block) | Validate Address present and promoted; indicator shown read-only next to the address; log action present | Manual |
| 25 | Accept on each source | The five values written exactly as returned; its indicator Yes; one log entry naming table, record, address type, key and Record No., Customer No. blank except for Customer | Automated |
| 26 | Confirmed, Not Found, Ignore, Error on a Vendor | FR-8 outcomes per source | Automated |
| 27 | Editing Address, Address 2, City, State, ZIP or Country/Region on each source | Its indicator No | Automated |
| 28 | Company Information | Ship-to and company blocks validate, write and reset independently (an Accept on one block leaves the other untouched) | Automated |
| 29 | Vendor with Country/Region RU (was CA until SC-4) | Not-covered message; no call; no log | Automated |
| 30 | User without modify on the source's table | Dialog shows Accept is not possible; record unchanged | Manual |
| 31 | Company and person contacts | Both validate. A person inheriting the company's address takes the company's indicator | Automated (sets Marketing Setup; restores it) |
| 32 | Customer, Vendor, Bank Account ↔ Contact | Accept updates the Contact's address and indicator; editing the Contact's address clears the partner's indicator (proves §4.1 t) | Automated |
| 33 | Employee with a linked Resource | Accept updates the Resource's address and its indicator | Automated |
| 34 | Upgrade from 1.0.0.0 in two companies | FR-16; a second run changes nothing; a fresh install runs no upgrade | Manual (Standards §9.6) |
| 35 | Customer regression | The 61 existing automated tests pass unchanged | Automated |
| 36 | Validation called for an unsupported table | Refused; nothing sent or logged | Automated |
| 37 | Customer Card log action | Shows entries written by 1.0.0.0 and 1.1 | Manual |
| 38 | Log list | Source table, description and type shown; no name stored | Automated + manual |
| 39 | Country change on a validated record (with the Country/Region setting on and off) | Indicator No, whether or not Business Central clears City/ZIP (FR-8, CR-1.1-04). Tested on Customer; the generic test for the 15 other tables is scheduled (Roadmap R-08-8) | Automated (Customer) |
| 40 | Privacy Blocked Customer, and a Ship-to Address of a blocked Customer | Refused with the privacy message; nothing sent; nothing logged | Automated |
| 41 | Linked Contact update fails after a Confirmed | The check stays logged as Confirmed; the Customer's indicator is set; the Contact is unchanged | Automated |
| 42 | Accept on a company Contact that has a duplicate | No duplicate form interrupts the Accept; the address and indicator are written | Manual (needs a client) |
| 43 | Not Found on an Employee with a linked Resource | Both indicators No | Automated |
| 44 | Person linked to a company (created with a blank address, so Business Central inherits the company's) | Takes the company's address and indicator | Automated |
| 45 | Accept on a person contact | The company contact is unchanged | Automated |
| 46 | A user of the USE set only (no read on Employee) opens the log | Employee entries are not shown; entries of tables the user may read are (CR-1.1-01) | Manual (not covered by an automated test) |
| 47 | Blank Country/Region Code, then Accept, Confirmed and Not Found; a record with a country (FR-18.6, generalised by FR-19.7) | Accept and Confirmed fill in the country Google found, else the region that was sent (US with the default US); the indicator is Yes; a non-blank country is not changed; Not Found leaves the country blank | Automated (Vendor Accept, Location Confirmed, Vendor Not Found) + manual (TC-44) |
| 48 | Canadian vendor (ON, postal code M5H 2N2) | Region CA sent, no USPS CASS flag; Confirmed; country stays CA (FR-19) | Automated (TestCanadaConfirmed) |
| 49 | Germany, address without a state | Region DE sent; Confirmed; State stays blank (FR-19.4) | Automated (TestGermanyConfirmedWithoutState) |
| 50 | A country Google does not cover | Not-covered message; nothing sent or logged | Automated (TestUnsupportedCountryRefused; also tests 7 and 29) |
| 51 | A covered country an administrator turned off | Not-turned-on message; nothing sent or logged | Automated (TestDisabledCountryRefused) |
| 52 | Record with no country (and no default); Google finds Germany | Country/Region Code is filled in as the matching BC code (FR-19.7) | Automated (TestBlankCountryFilledFromResult) |
| 53 | Record with no country; Google finds it in a country that is turned off | Not Found with the not-turned-on message; the country stays blank | Automated (TestBlankCountryResultNotEnabled) |
| 54 | Record says one country, Google finds the address in another | Not Found with the mismatch message | Automated (TestRegionMismatchIsNotFound) |
| 55 | Puerto Rico result for a US record | Not a mismatch; the check goes on (US and PR are one class) | Automated (TestPuertoRicoResultMatchesUs) |
| 56 | Singapore: Google names no city | The record's city is kept, not blanked (FR-19.6) | Automated (TestSingaporeKeepsCity) |
| 57 | Germany: Google names no postal code | The record's postal code is kept | Automated (TestGermanyKeepsPostalCode) |
| 58 | Google returns a sublocality and no second address line | The sublocality becomes Address 2 | Automated (TestSublocalityActsAsAddress2) |
| 59 | Country whose ISO Code differs from its Code | The region sent is the ISO Code | Automated (TestIsoCodeDiffersFromCode) |
| 60 | Country without an ISO Code that cannot be mapped | The ISO-Code-missing message; nothing sent | Automated (TestCountryWithoutIsoCodeRefused) |
| 61 | Canadian postal code that is not of the form A1A 1A1 and no city and province | Incomplete-address message; nothing sent | Automated (TestCanadaBadPostalCodeBlocks) |
| 62 | Germany with a street only | Incomplete-address message; nothing sent (FR-19.4) | Automated (TestGermanyNeedsCityOrPostalCode) |
| 63 | Supported Countries page | 40 rows; only Enabled editable; turning one off and on again works; the dialog shows "The Country/Region will be set to X." for a record without a country | Manual (HumanUnitTestScript) |
| 64 | Danish address, no country, default country US, Let Google decide (SC-5) | No region sent; Google names Denmark; Confirmed; Country/Region Code set to DK | Automated (TestBlankCountryDanishAddressInferred) + manual (TC-53) |
| 65 | US address (state TX, ZIP 77494), no country, Let Google decide (SC-5) | Region US sent and USPS CASS requested | Automated (TestBlankCountryUsShapeHintsUs) + manual (TC-54) |
| 66 | Canadian postal code M5H 2N2, no country, Let Google decide (SC-5) | Region CA sent; Confirmed; country set to CA | Automated (TestBlankCountryCanadianPostalCodeHintsCa) |
| 67 | Use default country, default US, a Danish-looking address with ZIP 15500 and no state (SC-5, reworked in SC-5a) | Region US sent (the default, not a guess) | Automated (TestBlankCountryUseDefaultSendsDefault) + manual (TC-56) |
| 68 | Use default country, blank default, a US-shaped address (SC-5a) | No region sent; nothing is guessed | Automated (TestBlankCountryUseDefaultBlankDefaultSendsNoRegion) |
| 69 | Italian address, province MI, 5-digit CAP, no country, Let Google decide (SC-5a); the first (US) request ends in Not Found | A second request is sent with no region; Google finds it in Italy; Confirmed; country set to IT; exactly two requests | Automated (TestItalianProvinceRetriesWithoutRegion) + manual (TC-55) |

**Test app:**
- A separate AL test extension, **Google Address Validator Tests**, that never calls Google. It simulates provider responses (200 validated and not validated, with and without USPS data; 400 key and invalid argument; 401; 403 API disabled, billing and key restricted; 429; 5xx; timeout; unreadable responses), so automated tests use none of the quota.
- It holds **155 automated tests** (test app 0.0.0.23) in six test codeunits: 24 + 29 + 8 (the 61 tests of 1.0.0.0, three codeunits), 54 (sources) and 19 (sync) for 1.1, and 21 (country tests, codeunit 92838: 15 for SC-4, 4 for SC-5, 2 for SC-5a) for 1.2. None has been run. The first 61 cover tests 1–10, 15–18, 20 and 22, and further tests beyond the list above: the privacy notice refusing a send, caller checks, the Confirmed note, the provider seam, Test Connection (success, API off, no response, no key, no message), unconfirmed parts in the Not Found reason, JSON boolean flags and dialog notes, and the DPV S and N warnings.
- The 1.1 codeunits cover tests 25–29, 31–33, 35, 36, 38–41 and 43–45: all 16 sources for Accept and for the edit-resets across the six address fields, privacy, record gone, unsupported table, the company blocks, linked sync and the country rule (both settings of Require Country/Region Code). Library additions create and clean up test records in every source table, using keys starting GAVUT, and save and restore Company Information and Marketing Setup. Test procedure names are 30 characters or fewer.
- Tests 11, 12, 13, 14, 19, 21, 23, 24, 30, 34, 37, 42 and 46 are manual sandbox checks (the 1.1 manual cases are TC-30 to TC-38, with TC-43 and TC-44 added later, in `docs/4-prove/HumanUnitTestScript.md`).
- How responses are simulated is a TDD decision, constrained by §4.1 k (OQ-17).
- Open obligations before Step 12: install, run the 155 tests with the AL Test Tool, run the manual tests, and run the live spike (OQ-33). The privacy-refused test needs a user who can approve for the organization.

## 8. Languages and markets
From Parameters §1.9, written as requirements:

| Language | Country | Required at first release | Reviewer | Customer-language documents | Translatable data |
|---|---|---|---|---|---|
| English (United States), en-US, source language | United States | Yes | AJ Ansari | None (the extension produces no customer-facing documents) | None (the log keeps provider text exactly as returned) |

- Wording is US English, and country-neutral since SC-4: "State / Province" and "ZIP / Postal Code" in the comparison dialog and in messages. The supported-country names are seeded English data.
- Source text is written in US wording.
- No translation files are produced or required. If a language is added later, the parameter sheet is reopened.

## 9. Open questions
Numbers OQ-1 to OQ-22 are as in FRD 1.2. OQ-23 to OQ-30 are the CR-1 questions (decisions Q1–Q11, Appendix B); OQ-31 and OQ-32 are the two questions FRD 1.3 had numbered OQ-23 and OQ-24 (renumbered at Step 10, Gap Analysis GA-19); OQ-33 is added at Step 10. OQ-34 to OQ-49 are the SC-1 questions (version 1.1), all answered by AJ Ansari on 2026-10-17; OQ-50 to OQ-52 were raised at Step 10 for three decisions taken since, which await his confirmation.

| # | Question | Owner | Raised | Resolved |
|---|---|---|---|---|
| OQ-1 | Do we ship or mail to these customers through USPS (USPS terms)? | AJ Ansari | Spec, 2026-10-10 | Resolved 2026-10-10 (AJ confirmed); **superseded** by the move to Google (CR-1) |
| OQ-2 | Store accepted values in upper case, exactly as returned? | AJ Ansari | Spec | Resolved 2026-10-10 (default); **superseded by Q2**: the USPS standardized address (upper case) when present, else Google's postal address |
| OQ-3 | Should a new ZIP+4 alone trigger the dialog? Default: yes. | AJ Ansari | Spec | Resolved 2026-10-10: AJ confirmed the default |
| OQ-4 | Is State held in the County field? Default: yes. | AJ Ansari | Spec | Resolved 2026-10-10: AJ confirmed the default |
| OQ-5 | Puerto Rico and other territories: validate only the one configured US code? Default: yes. | AJ Ansari | Spec | Resolved 2026-10-10: AJ confirmed the default (Google CASS supports PR, but only the configured US code is validated). **Superseded by SC-4** (FR-19): PR is a supported region of its own and counts with the US for the region-mismatch test |
| OQ-6 | Firm name: not shown, not written? Default: yes. | AJ Ansari | Spec | Resolved 2026-10-10: AJ confirmed the default |
| OQ-7 | Add accepted ZIP codes to the Post Code table? Default: no. | AJ Ansari | Spec | Resolved 2026-10-10: AJ confirmed the default |
| OQ-8 | Log retention: custom 2-year period, and is the policy created and enabled on install? | AJ Ansari | Spec / FRD verification | Resolved 2026-10-10: (a) custom 2-year period; (b) policy created disabled, an administrator enables it (AJ) |
| OQ-9 | Expected checks per hour and the real USPS quota. | AJ Ansari | Spec | **Superseded** by OQ-25 (the Google equivalent: daily cap and budget alert) |
| OQ-10 | Ship-to Addresses and Vendors in a later version? Default: later. | AJ Ansari | Spec | Resolved 2026-10-10: later version (AJ confirmed default) |
| OQ-11 | Permission sets: USE / ADMIN names, ADMIN includes USE, separate read-only set? | AJ Ansari | Parameters §1.3 | Resolved 2026-10-10: USE and ADMIN only, ADMIN includes USE, no separate VIEW set (AJ); names now `OBCFGAV GAV, USE` / `OBCFGAV GAV, ADMIN` (Q11) |
| OQ-12 | Is it acceptable that Accept also updates the linked Contact's address through standard sync (G3)? | AJ Ansari | PRE-02 | Resolved 2026-10-10: acceptable (AJ). Platform confirmation owed in a sandbox (GA-25) |
| OQ-13 | Is a possibly stale Tax Area Code after Accept acceptable as a known limitation (§6.1)? | AJ Ansari | PRE-02 6.6 | Resolved 2026-10-10: acceptable (AJ) |
| OQ-14 | Address Validated reset: which fields count as an address edit? | AJ Ansari | FRD | Resolved 2026-10-10: Address, Address 2, City, State, ZIP Code; not Country/Region (AJ). **Superseded in 1.1** (OQ-36 for the clearing case, then CR-1.1-04 / OQ-52): the country is part of the validated address, for all sources |
| OQ-15 | Address Validated when a previously validated customer gets Not Found or Error? | AJ Ansari | FRD | Resolved 2026-10-10: reset to No on Not Found only; Error leaves it unchanged (AJ) |
| OQ-16 | Wizard and setup card: both enter the key? Wizard complete once the key is saved? | AJ Ansari | FRD | Resolved 2026-10-10: both; complete once saved (AJ) |
| OQ-17 | How are provider responses simulated in tests (the platform mock is on-premises only)? | AJ Ansari | FRD verification | Resolved 2026-10-10: replaceable HTTP layer in the app, tests run in a SaaS sandbox (AJ) |
| OQ-18 | Ask USPS whether the "operational test" clause covers Addresses 3.0. | AJ Ansari | Spec risks | **Superseded** by the move to Google (CR-1) |
| OQ-19 | Confirm the US captions "State" / "ZIP Code" on the Customer Card, and the page anchors and captions on the 15 new cards, against a US sandbox (only W1 symbols were available). | AJ Ansari | FRD verification | **Open** — check against a US sandbox in the first sandbox round (GA-25) |
| OQ-20 | Is "Allow HttpClient Requests" on by default in our production environment, or must it be turned on as a deployment step? | AJ Ansari | FRD verification | **Open** — check before first deployment (goes into Deployment.md) |
| OQ-21 | Log result and Address Validated when a dialog check can't be accepted, and Confirmed for a user who can't modify customers. | AJ Ansari | FRD | Resolved 2026-10-10: Suggestion Ignored, Accepted = No, flag unchanged; Confirmed sets the flag only for users who can modify customers (AJ) |
| OQ-22 | Accept the proposed acceptance tests 15–21 and their test-app coverage? | AJ Ansari | FRD | Resolved 2026-10-10: accepted (AJ) |
| OQ-23 | Q1: what the log stores, given Google's 30-day storage terms. | AJ Ansari | CR-1, 2026-10-11 | Resolved 2026-10-16 (CR-1 sign-off, AJ): suggested values kept only for Suggestion Accepted and Confirmed; 2-year retention stays |
| OQ-24 | Q2/Q3: which suggested values Accept writes, and CASS. | AJ Ansari | CR-1 | Resolved 2026-10-16 (AJ): USPS standardized address when present, else Google postal address; CASS always on |
| OQ-25 | AJ sets the daily request cap and the budget alert in the Google Cloud console before go-live (the Google equivalent of OQ-9). | AJ Ansari | CR-1 | **Open** — go-live task for AJ |
| OQ-26 | Q4/Q6: what counts as validated, and Confirmed when delivery signals exist. | AJ Ansari | CR-1 | Resolved 2026-10-16 (AJ): `PREMISE` or `SUB_PREMISE` only; Confirmed with a note (note narrowed to the FR-4 warning line, GA-07, 2026-10-16) |
| OQ-27 | Q5: equality rules. | AJ Ansari | CR-1 | Resolved 2026-10-16 (AJ): Address + Address 2 as one string, ignoring periods, commas and repeated spaces |
| OQ-28 | Q7: Test Connection as a free invalid-request probe. | AJ Ansari | CR-1 | Decided 2026-10-16 (AJ); **verification open**: the spike must prove the probe reports key, API and billing errors, otherwise one real fixed address is used (GA-24) |
| OQ-29 | Q9: does the app need its own public Terms of Use and Privacy Policy that reference Google's terms (`app.json` `privacyStatement` and `EULA` are blank)? | AJ Ansari | CR-1 | **Open** — AJ to check with the owner of the Google account terms (not legal advice); before first deployment |
| OQ-30 | Naming of the extension (Q11). | AJ Ansari | CR-1 | **Resolved 2026-10-16** by revised Q11 (AJ): full rename to Google Address Validator |
| OQ-31 | Confirm the privacy-notice link, now Google's `https://policies.google.com/privacy` (was OQ-23 in FRD 1.3: the USPS link), and accept the platform consent-text caveat (FR-1.3). | AJ Ansari | Step 09 / Step 08 GA-12 | **Open** — before first deployment |
| OQ-32 | Telemetry on Error outcomes (was OQ-24 in FRD 1.3)? | AJ Ansari | Step 09 CR9-23 | Resolved 2026-10-16 (AJ): none. AL Guidelines now agree (add telemetry only when explicitly requested) |
| OQ-33 | Live spike against Google with a real key and real addresses (TDD 14.y): header accepted, error `reason` values, free probe, billed SKU, ROUTE and `CONFIRM_ADD_SUBPREMISES` on real addresses, key never in an error message, whether a partial standardized address ever occurs. | AJ Ansari | Step 08 GA-24 | **Open** — before Step 12 |
| OQ-34 | Field numbering | AJ Ansari | SC-1 | Resolved 2026-10-17: shared number 92800 on every source table (field 92801 for the company ship-to flag) |
| OQ-35 | Does the flag follow standard address copies (Customer, Vendor, Bank Account ↔ Contact, and so on)? | AJ Ansari | SC-1 | Resolved 2026-10-17: yes (FR-12.4) |
| OQ-36 | Does a Country/Region change that clears City/ZIP/State reset the flag, Customer included? | AJ Ansari | SC-1 | Resolved 2026-10-17: yes; **widened by CR-1.1-04** to any country change (OQ-52) |
| OQ-37 | Privacy Blocked | AJ Ansari | SC-1 | Resolved 2026-10-17: refuse, Customer included, and child sources of a blocked parent (FR-17) |
| OQ-38 | People data under the one privacy notice and one Setup switch | AJ Ansari | SC-1 | Resolved 2026-10-17: yes |
| OQ-39 / OQ-40 | Customer No. on Ship-to Address and Customer Bank Account entries; Company Information log action | AJ Ansari | SC-1 | Resolved 2026-10-17: Customer No. blank; one action for both blocks |
| OQ-41 | Checkpoint (compile, package, sandbox run of the 61 tests) after batch 1 | AJ Ansari | SC-1 | Resolved 2026-10-17: yes; **replaced** on 2026-10-18 by one install of the final package, on AJ Ansari's instruction (ChangeLog B2-1/B3-1/B4-1) |
| OQ-42–46 | Wording, list pages, test app, source description, enum extensibility | AJ Ansari | SC-1 | Resolved 2026-10-17: recommended defaults (Customer texts verbatim plus generic texts; no list-page actions; description = table + key, never a name; Address Type enum not extensible) |
| OQ-47 | Linked-record update failure | AJ Ansari | SC-1 (Sanity Check F-SC1-03) | Resolved 2026-10-17: separate step after the commit; the check completes |
| OQ-48 | Duplicate-contact form | AJ Ansari | SC-1 (F-SC1-04) | Resolved 2026-10-17: suppressed while the extension writes |
| OQ-49 | Employee → Resource flag | AJ Ansari | SC-1 (F-SC1-05) | Resolved 2026-10-17: propagated |
| OQ-50 | D3: for a Contact source, is the update of the linked Customer, Vendor, Bank Account, Employee and persons part of the write (a failure is logged as Error and the Contact's indicator is unchanged), or a separate step after the commit like the other sources? | AJ Ansari | Step 07 review D3, 2026-10-18 | **Confirmed by AJ Ansari, 2026-10-18**: a Contact source's linked update is part of the write; it is standard Business Central behaviour and is kept (GA-1.1-07) |
| OQ-51 | CR-1.1-01: the log read restriction (USE indirect read, the log page filtered to the source tables the user may read; ADMIN keeps direct read and delete). | AJ Ansari | Step 09, 2026-10-18 | **Confirmed by AJ Ansari, 2026-10-18.** A sandbox check with a USE-only user is still owed (test 46) |
| OQ-52 | CR-1.1-04: the country is part of the validated address for all sources (a country change resets the indicator even when Business Central does not clear the address; blank to US resets too). | AJ Ansari | Step 09, 2026-10-18 | **Confirmed by AJ Ansari, 2026-10-18**: the country is part of the validated address; this supersedes 1.0 OQ-14 |
| OQ-53 | GF-04: is the log's Record No. a snapshot (the number or key at the time of the check)? | AJ Ansari | SC-2 | **Confirmed by AJ Ansari, 2026-10-18**: yes, a snapshot |
| OQ-54 | Release candidate handling. | AJ Ansari | Step 11, 2026-10-18 | **Confirmed by AJ Ansari, 2026-10-18**: the last build (1.1.0.12 today) ships as it is, with no rename. When AJ Ansari is ready he will delete all older package versions by hand and will then ask the agent to squash the local and remote git history. Until he says so, nobody squashes or force-pushes, and the agent never deletes a package. |
| OQ-55 | Blank Country/Region Code on a record that is validated (FR-18.6). | AJ Ansari | 1.1.0.12, 2026-10-18 | Built in 1.1.0.12: fill in the setup's US code on Accept and Confirmed. **Generalised by SC-4** (FR-19.7): the country Google found, else the hint. Not installed or run |
| OQ-56 | Non-US addresses (for example Canada). | AJ Ansari | 2026-10-18 | **Superseded by SC-4** (FR-19): AJ Ansari asked for all 40 countries Google covers; built in 1.2.0.0 and 1.2.0.2, not installed or run |
| OQ-57 | Version number of SC-4: the Minor bump to **1.2.0.x** (no 1.2.0.0 package was installed; 1.1.0.13 was possible but would leave a higher-numbered package in the folder). | AJ Ansari | SC-4, 2026-10-18 | **Open** (awaiting: AJ Ansari). Taken by the main role; recommended option |
| OQ-58 | The changed 1.0.0.0 texts: the incomplete-address and state-code messages and the State/ZIP captions are country-neutral, the US-only message is gone, tests 7 and 29 moved from CA to RU (breaks the FR-18 "verbatim" commitment). | AJ Ansari | SC-4, 2026-10-18 | **Open** (awaiting: AJ Ansari). Taken by the main role; accepted because the old texts name the US |
| OQ-59 | Brazil, Mexico, India and Japan are enabled although their address shapes (district / sublocality, preview status for India and Japan) are not proven against live responses. | AJ Ansari | SC-4, 2026-10-18 | **Open** (awaiting: AJ Ansari). Recommended: a live probe per country with real addresses before relying on it; an administrator can turn a country off |
| OQ-60 | Review items not done (the warning for a Setup default that is not covered was done in SC-4b, main 1.2.0.2): the mismatch wording when the hint comes from the default, country names resolved through Country/Region, logging the regions. | AJ Ansari | SC-4, 2026-10-18 | **Open** (awaiting: AJ Ansari): accepted for now, schedule or reject |
| OQ-61 | SC-5a: existing tenants switch to *Let Google decide* when 1.2.0.3 or later is installed, with no upgrade step (field 4 changes meaning for upgraded setups; Standards §9.1). | AJ Ansari | SC-5a, 2026-10-18 | **Open** (awaiting: AJ Ansari). Taken by the main role under the standing instruction; recommended option. Deployment.md tells administrators to review Blank Country Handling; AJ Ansari's own sandbox is the only tenant that has ever had the extension installed |
| OQ-62 | SC-5a: when a guessed US or Canadian region ends in Not Found, repeat the request once without a region (one extra billable request only in that case) instead of restricting the guess. | AJ Ansari | SC-5a, 2026-10-18 | **Open** (awaiting: AJ Ansari). Recommended option; the cost note is in FR-19.11 and Deployment.md |
| OQ-63 | SC-5a: a US record without a recognizable state and ZIP shape gets no USPS delivery data under *Let Google decide*; US-only companies choose *Use default country*. | AJ Ansari | SC-5a, 2026-10-18 | **Open** (awaiting: AJ Ansari). Accepted and documented (FR-19.14) |
| OQ-64 | SC-5a: the military codes AA, AE and AP count as US states; Guam, the US Virgin Islands, American Samoa and the Northern Mariana Islands do not (Google does not cover dependent territories). Enum 92803 is closed (`Extensible = false`). | AJ Ansari | SC-5a, 2026-10-18 | **Open** (awaiting: AJ Ansari). Recommended options |
| OQ-65 | Google's real answers: what it does with a Danish address and no region, what it answers first for an Italian province-code address sent as US, and the outside-the-US shapes. | AJ Ansari | SC-5 / SC-5a, 2026-10-18 | **Open** (awaiting: AJ Ansari). Needs a live probe (TC-53, TC-55); nothing has been run |

## Validation against DEFINE
- [x] Every PRE-02 entity appears in §6 or §6.1: the objects, the wizard, the table extension, the test app, the existing tables, and the deferred 6.6, G4 and G5. G1, G2, G3, G6 and G8 are covered in §6, FR-5, FR-6 and FR-9.
- [x] Every PRE-01 consumer use case is addressed in §3 (users, administrators, auditors; no other systems, BI or AI tools).
- [x] Every platform capability assumed here was checked against what BC can do (§4.1). Capabilities only partly verified or not verifiable from symbols (h, k, l; US captions; the live Google contract) are stated as such and carried as OQ-12, OQ-17, OQ-19, OQ-20 and OQ-33, not written as fact.
- [x] §8 covers every target language in Parameters §1.9 (en-US only).
- [x] Provider change (Parameters §1.1, §1.3, §1.6, §1.6a, §1.9): name, prefix `obcfgav`, namespace, App Code `GAV`, permission set names, the wizard asking for the API key only, and the log keeping provider text are all reflected here. (Parameters §1.6's Consumer Key/Secret wording was corrected at the 1.1 Step 10.)
- [x] Every *Spec stale* Step 08 item (GA-07, GA-11, GA-12, GA-19) and the Step 09 behaviours (caller checks, privacy notice, contact sync, log rename propagation, Test Connection no-message wording) are in the requirements.
- [x] Nothing here says *how*. Object IDs, code and final object names are left to the TDD. (Field number 92800/field 92801 is stated in FR-12.1 because it is a requirement of the Contact sync, not a naming choice.)
- [x] (1.1) The SC-1 scope change is folded in: FR-10 to FR-18, tests 24–47, OQ-34 to OQ-56; every Spec stale outcome of the SC-1 Gap Analysis (GA-1.1-04, -05, -06, -09, -11, -15) and the Code Review decisions (CR-1.1-01, -02, -04) are in the requirements or the PostDevTDD (the pure code-level ones: GA-1.1-04, -05, -06 gate details, and field-level facts are in `docs/4-prove/PostDevTDD.md` Part F).

---

## Appendix A. Google facts this design relies on (verified from documentation; the live contract is checked at the spike, OQ-33)

| # | Fact | Source |
|---|---|---|
| G1 | `POST https://addressvalidation.googleapis.com/v1:validateAddress`. The body has `address` (PostalAddress, required) and `enableUspsCass` (bool), plus `previousResponseId`, `languageOptions` and `sessionToken`, none of which we use. The response has `result` (`verdict`, `address`, `geocode`, `metadata`, `uspsData`) and `responseId`. | https://developers.google.com/maps/documentation/address-validation/reference/rest/v1/TopLevel/validateAddress |
| G2 | In `PostalAddress`, `addressLines` is required and the other fields are optional: `regionCode`, `postalCode`, `administrativeArea`, `locality`, `sublocality`. `revision` must be 0. `recipients` and `organization` are discarded, so we don't send them. All input fields together may be at most 280 characters (ours: 100+50+30+30+20+2 = 232). | same |
| G3 | The documented sample passes the key as `?key=API_KEY`. Google's system-parameters page lists the `X-Goog-Api-Key` header as available across all Google REST APIs. We use the header. | https://developers.google.com/maps/documentation/address-validation/requests-validate-address ; https://docs.cloud.google.com/apis/docs/system-parameters (updated 2026-10-09) |
| G4 | CASS is off by default and works for regionCode US and PR only. We turn it on (Q3) for real checks in US and PR only (since SC-4; not for other regions, not for the Test Connection probe). | requests-validate-address; https://developers.google.com/maps/documentation/address-validation/overview (updated 2026-10-08) |
| G5 | `verdict` fields: `inputGranularity`, `validationGranularity`, `geocodeGranularity`, `addressComplete` (unset means false), `hasUnconfirmedComponents`, `hasInferredComponents`, `hasReplacedComponents`, `hasSpellCorrectedComponents`, `possibleNextAction`. Granularity values: `SUB_PREMISE`, `PREMISE`, `PREMISE_PROXIMITY`, `BLOCK`, `ROUTE`, `OTHER`, `GRANULARITY_UNSPECIFIED`. Next-action values: `FIX`, `CONFIRM_ADD_SUBPREMISES` (US only), `CONFIRM`, `ACCEPT`. Google says ACCEPT "does not guarantee validity". | validateAddress reference (ValidationResult section) |
| G6 | `address` has `formattedAddress`, `postalAddress`, `addressComponents[]` (`componentName.text`, `componentType`, `confirmationLevel`, and booleans `inferred`, `spellCorrected`, `replaced`, `unexpected`), plus `missingComponentTypes`, `unconfirmedComponentTypes` and `unresolvedTokens`. `metadata` has `business`, `poBox`, `residential` (unset means unknown). | same |
| G7 | `uspsData` (US/PR, not always populated) contains `standardizedAddress` (`firstAddressLine`, `firm`, `secondAddressLine`, `urbanization`, `cityStateZipAddressLine`, `city`, `state`, `zipCode`, `zipCodeExtension`); `dpvConfirmation` (Y, D, S, N or empty: N = primary and any secondary failed; D = primary confirmed, secondary missing; S = primary confirmed, secondary present but not confirmed; Y = confirmed; empty = not submitted for DPV); `dpvFootnote`, `dpvVacant` (Y/N), `dpvNoStat`, `dpvCmra`, `addressRecordType`, `cassProcessed`; and `errorMessage`, set when USPS processing is suspended because artificial addresses were detected. | same; https://developers.google.com/maps/documentation/address-validation/handle-us-address |
| G8 | Google's recommended logic is FIX / add subpremise / CONFIRM / ACCEPT. Signals: granularity `OTHER`, `missingComponentTypes`, `UNCONFIRMED_AND_SUSPICIOUS`, `unresolvedTokens`, the `has…` flags and DPV. Google says not to rely on `uspsData` alone. | https://developers.google.com/maps/documentation/address-validation/build-validation-logic (2026-10-08); understand-response |
| G9 | **Billing.** "Address Validation Pro" (A2E0-53FF-0BE3) is billed on a "Successful request to the Address Validation API" through ValidateAddress. Feedback requests are free. "Address Validation Enterprise" (10F3-119A-C6EC) applies to an Autocomplete (New) session that ends in ValidateAddress, which we never use. CASS is not named as a SKU trigger. A plain request, with or without CASS, bills as Pro (still to confirm in the billing report at the spike). | https://developers.google.com/maps/billing-and-pricing/sku-details |
| G10 | **Prices.** Pro: 5,000 free a month, then $17 per 1,000. Enterprise: 1,000 free, then $25 per 1,000. At AJ's volume (under 1,000 a month) the expected cost is $0. | https://developers.google.com/maps/billing-and-pricing/pricing (2026-10-08) |
| G11 | **Limits.** 6,000 queries per minute. Daily quota caps are set in the Cloud console, and "your service stops responding" at the cap. The page doesn't say whether failed requests are billed. | https://developers.google.com/maps/documentation/address-validation/usage-and-billing (2026-10-08) |
| G12 | **Error body.** `{"error":{"code":<HTTP>,"message","status":"INVALID_ARGUMENT"…,"details":[{"@type":"type.googleapis.com/google.rpc.ErrorInfo","reason","domain","metadata"}]}}`. Confirmed: 429 = RESOURCE_EXHAUSTED and 403 = PERMISSION_DENIED. The specific `reason` values (API_KEY_INVALID, SERVICE_DISABLED, BILLING_DISABLED, API_KEY_SERVICE_BLOCKED) are **not** confirmed for this API. | https://google.aip.dev/193 |
| G13 | **Policies.** Storing results is "generally restricted" (place IDs exempt). Results not shown on a Google map must carry Google attribution, preferably the logo; the text "Google Maps" is allowed where space is short, not translated and not modified. Apps need Terms of Use and a Privacy Policy that reference Google's terms. | https://developers.google.com/maps/documentation/address-validation/policies (2026-10-08) |
| G14 | **Service Specific Terms, Address Validation section** (archived version of 2024-05-22; the live page would not render). `formattedAddress`, `postalAddress`, `componentName` and `standardizedAddress` may be cached for **30 consecutive days** for "Downstream transactions". After that they must be deleted or replaced with "End User data provided through End User confirmation or correction". §10.2: for US/PR, no "artificially-created addresses"; if one is sent, Google stops USPS validation for the customer and reports the customer's name and address to USPS. | https://cloud.google.com/maps-platform/terms/maps-service-terms/index-20240522 |
| L1 | `HttpHeaders.Add(Name: Text; Value: SecretText)` and `HttpRequestMessage.SetSecretRequestUri(SecretText)` are both available from runtime 12.0 (we target 17.0). | https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httpheaders/httpheaders-add-string-secrettext-method |

## Appendix B. Decision record (AJ Ansari)
Decided 2026-10-11 and signed off 2026-10-16 (ChangeLog CR-1, 07a-2); these decisions are folded into the requirements above.

| # | Question | Decision |
|---|---|---|
| Direction | Provider | Replace the USPS API with Google Maps Platform Address Validation behind a provider interface; the USPS client and OAuth code are retired (reason: from 2026-08-01 the USPS Addresses API needs a signed license and per-use fees) |
| Q1 | Log versus Google's 30-day storage terms | Keep Google's suggested values in the log **only for Suggestion Accepted and Confirmed**; for Ignored and Not Found keep only the originals, result, granularity, next action, delivery code and HTTP status. 2-year retention stays (FR-5) |
| Q2 | Which suggested values Accept writes | USPS `standardizedAddress` (upper case) when present, else Google `postalAddress` (FR-4) |
| Q3 | `enableUspsCass` | On for US and PR only (since SC-4; before SC-4 always on, because only the US was validated) |
| Q4 | What counts as validated | `PREMISE` or `SUB_PREMISE` only (FR-8) |
| Q5 | Equality | Address + Address 2 compared as one street string, ignoring periods, commas and repeated spaces (FR-3) |
| Q6 | Equal values but a missing-suite or delivery-N signal | Confirmed, with the note in the message (narrowed to the FR-4 warning line, GA-07) |
| Q7 | Test Connection | A free invalid-request probe, if the spike proves it reports key, API and billing errors; otherwise one real fixed address (FR-6) |
| Q8 | Provider on the setup card | Visible, read-only |
| Q9 | Google attribution | Text line "Suggestion from Google Maps" in the dialog. Whether a public Terms of Use / Privacy Policy is needed is for AJ to check with the owner of the Google account terms (not legal advice) (OQ-29) |
| Q10 | Provider enum | Not extensible |
| Q11 | Naming | **Revised by AJ Ansari, 2026-10-16: full rename.** App name Google Address Validator, test app Google Address Validator Tests, prefix `obcfusps` → `obcfgav`, namespace → `OnlyBCFans.GoogleAddress`, App Code `USPS` → `GAV`, permission sets `OBCFGAV GAV, USE` / `OBCFGAV GAV, ADMIN`, every object and file name loses "USPS". Publisher, app id, object IDs and field IDs do not change |
| Tests | Live tests | Real addresses only (Google's terms forbid made-up US addresses) |
| Step 08 | GA-02, GA-06, GA-07 (2026-10-16) | Caller check on the provider service; unconfirmed address parts included in the Not Found reason; the Confirmed note is the FR-4 warning line only |
| Step 09 | D-1, D-2 (2026-10-16) | Caller check on the orchestration (FR-1.7); Test Connection failure with no Google message gets its own wording (FR-6) |


---

## Appendix C. Scope change SC-1 — change record for version 1.1 (FRD 2.1)

**This appendix is a record, not a requirement.** Everything it once amended is now in §1–§9 above: FR-10 to FR-18, acceptance tests 24–47, OQ-34 to OQ-56, the edits to FR-1 to FR-9 and to §1.1, §2, §3, §4.1, §5, §6, §6.1 and §7. The working draft, with the full amendment text as signed off on 2026-10-17, is `docs/2-design/SC-1-Amendments-Draft.md` and the history of `docs/2-design/FRD.md` in git.

**What 1.1 added, and why.** Version 1.0.0.0 validated Customer addresses only. AJ Ansari asked (2026-10-17, `requirements/scope-additions-2026-10-17-more-master-data-requirements.md`) for the same Validate Address action and read-only Address Validated indicator on the other master-data tables that hold an address: 15 more tables (FR-10), with the Customer behaviour unchanged except for the changes of FR-18 (five in the SC-1 scope change; a sixth, FR-18.6, the blank-country fill-in for every source, was added in 1.1.0.12). The tables were taken from the Base Application 28.5 symbols, not from memory.

### Decisions that settled the draft (AJ Ansari, options box, 2026-10-17)
| Ref | Decision |
|---|---|
| Scope | Union out; 15 tables beyond Customer; nothing on transactions or documents; version 1.1.0.0; batches one at a time. |
| IDs | Re-blocked for 1.1 (Sanity Check F-SC1-08), then renumbered per object type for 1.3.0.0: main app `idRanges` `[92800–92829]`, test app `[92830–92849]` (`docs/1-define/ObjectRegister.md`). |
| OQ-34 to OQ-49 | See §9. Shared field number 92800; the flag follows standard address copies; a Country/Region change resets the flag; Privacy Blocked refuses, children of a blocked parent too; one privacy notice and switch; Customer No. blank on Ship-to Address and Customer Bank Account; one log action for both Company Information blocks; the OQ-41 checkpoint (later replaced); recommended defaults for wording, list pages, test app, description and enum; linked-record update as a separate step after the commit; duplicate-contact form suppressed; Employee → Resource propagated. |
| F-SC1-03 | The linked-record flag update on Confirmed and Not Found runs as a separate step after the check is committed; a failure leaves the linked flag unchanged and the check complete. |
| F-SC1-04 | The standard duplicate-contact form is suppressed while the extension writes (Write Guard). |
| F-SC1-05 | Confirmed and Not Found on an Employee propagate to its Resource. |
| F-SC1-06 | `app.json` moves to batch 1. Files permission set 92800 and codeunit 92803 are edited in batch 1 and batch 4: a recorded exception, safe because batches run one at a time. |
| F-SC1-13 | Test procedure names are 30 characters or fewer. |
| N-SC1-06 | Explicit upgrade tags instead of `SetAllUpgradeTags()` (a departure from Standards §9.3's preferred form). Decider: AJ Ansari, 2026-10-17 (FR-16.5). |

### Later decisions that changed the draft (2026-10-18)
These are the decisions the signed-off Appendix did not contain. All three were taken under AJ Ansari's standing instruction to finish without questions and were confirmed by AJ Ansari on 2026-10-18 (OQ-50 to OQ-52).
| Ref | Source | Decision | Where it is now |
|---|---|---|---|
| D1, D2 | Step 07 review (ChangeLog SC-1f), GA-1.1-06 | The linked-record update skips when the linked indicator already matches (D1) and runs with the Write Guard bound (D2). | FR-12.4 |
| D3 | Step 07 review, GA-1.1-07 | For a Contact source the linked update is part of the write; a failure is logged as Error. | FR-12.4; OQ-50 |
| D4 | Step 07 review, GA-1.1-06 | A person follows its company's indicator only when the company's address (country included) or indicator changed in that modify. | FR-12.4 |
| GA-1.1-04 | Step 08 | The linked update is gated on the user's right to modify the checked table, plus Contact write permission per branch and Resource read permission (not a Contact check up front). | FR-12.4, FR-14 |
| GA-1.1-15 | Step 08 | The linked update is the full standard Contact (or Resource) update: Last Date Modified and Change Log change on the linked record. | FR-9 |
| CR-1.1-01 | Step 09 | USE has indirect read on the log; the log page shows only rows whose source table the user may read; ADMIN keeps direct read and delete. | FR-5, FR-14; OQ-51 |
| CR-1.1-02 | Step 09 | Log field "Source SystemId" is Customer Content. | FR-5 |
| CR-1.1-04, N-1 | Step 09 | The country is part of the validated address for every source, the company ship-to country included; a country change resets the indicator even when Business Central does not clear the address; blank to US resets too. Supersedes OQ-14 and the clearing-only rule of OQ-36 and the old FR-8/FR-18.4. | FR-8, FR-18.4; OQ-52 |

Status: the Appendix C text was signed off by AJ Ansari (Dev Manager and Technical Lead) on 2026-10-17 as drafted (ChangeLog SC-1b) and amended the same day by the Sanity Check (`docs/2-design/SanityCheck.md`, section SC-1 Sanity Check). The Step 10 consolidation above is reviewed once, at the Step 11 → 12 hand-off.

---
