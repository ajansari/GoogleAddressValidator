# Running the automated tests for Google Address Validator

**The agent does not upload or run anything in Business Central unless a developer explicitly asks it to.** It writes the tests and this guide; a
person installs the test app and runs the tests in a sandbox, then reports what the page showed. Plan on
twenty minutes the first time (installing the test framework is most of it) and five minutes after that.

> **Status:** these 155 tests (the 61 of 1.0.0.0 in rows 1 to 61, 73 for version 1.1 in rows 62 to 134, and 21 for version 1.2 in rows 135 to 155: 15 for SC-4, the 40 countries, 4 for SC-5 and 2 for SC-5a, the blank-country handling) have been written and compiled (main app 1.1.0.8 and test app 0.0.0.16 compiled with 0 errors and 0 warnings; the later builds, main 1.2.0.4 and test app 0.0.0.23 (previous 0.0.0.22), are recorded in the ChangeLog and were not re-checked here) but **never run**. Two older tests changed in 0.0.0.21: rows 16 and 106 now use Russia (RU) instead of Canada, because Canada is covered from 1.2. Expect that a few fail the first time because of the tests, not the extension; report each one exactly as §8 says. Rows 1 to 61 are expected to pass against 1.2.0.2 (FRD test 35) with the changes named above (row 16 moved to RU; the incomplete-address and state-code texts that rows 17 and 46 expect are now the country-neutral ones, read from the test library), with one exception to watch: the 1.1.0.4 change that makes the country part of the validated address (row 57 edits the city only, so it should still pass). `docs/4-prove/AutomatedTestScripts.md` says *what* the tests are and what they leave out; this guide says how to run them. Both are revised every time the tests change. This guide replaces the USPS-build guide (34 tests), kept at `docs/4-prove/USPSbuild/AutomatedTestGuide.USPSbuild-0.0.0.4.md`.

## 1. What you are installing

| | |
|---|---|
| The extension under test | `outputAppPackage/Google_Address_Validator_1.3.0.0.app` (install it first, by `docs/4-prove/SandboxInstall.md`) |
| The test app | `Google_Address_Validator_Tests_0.0.0.24.app` **in the sibling folder** `USPSAddressValidator.Tests` (full path `/Users/ajansari/Documents/AL/USPSAddressValidator.Tests/outputAppPackage/Google_Address_Validator_Tests_0.0.0.24.app`). It is a separate extension called **Google Address Validator Tests**, publisher OnlyBCFans, whose only job is to test the one above. It requires the main app **1.3.0.0** and is never installed in production |
| Test codeunits in the test app | 6 codeunits (codeunit 92832, codeunit 92833, codeunit 92834, codeunit 92836, codeunit 92837, codeunit 92838), 155 test methods (24 + 29 + 8 + 54 + 19 + 21), listed in §6. (Three more codeunits, codeunit 92830, codeunit 92831 and codeunit 92835, are helpers; they hold no tests and do not appear on the AL Test Tool page.) |
| Test framework apps the test app needs | **Test Runner** (for the page). The three libraries **Library Assert**, **Any**, **Library Variable Storage** are listed in §3 because the framework installs them as standard; this test app's own `app.json` lists only the main app as a dependency (it has its own checking code), so if one of the three is not offered, carry on and tell the agent |
| The page you run tests from | **AL Test Tool**, which comes with Microsoft's **Test Runner** app (§3). **The page number is not settled:** the test app's `.vscode/launch.json` says 130401, an earlier version of this guide said 130451, and neither has been checked in a sandbox. Do not rely on a number: find the page by searching **AL Test Tool** (§5) and tell the agent the number you see |
| Sandbox | `sandbox` (a SaaS sandbox; the test app refuses to work anywhere else), in a company whose name contains **TEST** (the test app's `launch.json` still names the company `TEST USPS`; that company name is fine if it exists, any name containing TEST is) |

## 2. Before you start

- **A sandbox only.** Microsoft allows automated tests in online sandboxes and forbids them in production.
  Two limits apply in a sandbox: no single test method may run longer than fifteen minutes, and Microsoft
  recommends not running tests for more than one or two hours a day.
- **The permission to install extensions** (§2 of `SandboxInstall.md`): Admin Center access, the
  **D365 Extension MGT** user group, or the **EXTEND. MGT. - ADMIN** permission set.
- **Run as a user with SUPER (all permissions).** The tests change the privacy-notice approval and the address validation setup.
- **A company named with TEST, nothing else.** The tests **overwrite and delete the address validation setup and the stored API key of the company they run in**, and delete every customer whose number starts with `GAVUT` (from version 1.1 also every other test record whose key starts with `GAVUT`, see the next point). The first test that runs in a company whose name does **not** contain the letters **TEST** stops with the error *These tests overwrite and delete the address validation setup and credentials. Run them only in a test company whose name contains TEST. This company is …*. Use a test company only, never one with real customers. Afterwards the company's setup record is back as it was, but **the API key is gone** (the tests put in the made-up key `test-key` and clear it at clean-up): re-enter the real key on **Google Address Validation Setup** if the company needs it.
- **What the 1.1 tests create and clean up (codeunits 92836 and codeunit 92837).** They need a **TEST** company, the same as the older tests, and they stop with the same error otherwise. Each test creates its own records with keys that start with `GAVUT` in the 15 new source tables (Ship-to Address, Customer Bank Account, Vendor, Order Address, Remit Address, Vendor Bank Account, Location, Responsibility Center, Bank Account, Employee, Alternative Address, Contact, Contact Alt. Address, Resource), with their parent Customer, Vendor, Employee or Contact where a table needs one. The tests in `codeunit 92836` also **change Company Information's address and ship-to address** (they save the real ones first and put them back) and the edit tests **switch the General Ledger Setup field Req.Country/Reg. Code in Addr. on** (saved and restored the same way). The sync tests in `codeunit 92837` **create Business Relation codes `GAVUTC`, `GAVUTV`, `GAVUTB` and `GAVUTE`** (for customers, vendors, bank accounts and employees), **change Marketing Setup** (the business-relation codes and the Inherit Address Details switch) and **switch Req.Country/Reg. Code in Addr. on and off** in General Ledger Setup; they save these first and restore them at the end of each test. They also **insert the countries US and CA** when those are missing. Standard Business Central also creates Contacts for the test vendors and bank accounts; the clean-up finds them through their Contact Business Relation and deletes them. At the end of every test (`CleanUp`) the test deletes: the log entries it created; every `GAVUT*` record in those tables, children first; the linked contacts; the `GAVUT*` Business Relation codes; and it restores Company Information, Marketing Setup and the General Ledger Setup field. **Expected result after a clean run:** no `GAVUT*` record anywhere, Marketing Setup, Company Information and the General Ledger Setup field **Req.Country/Reg. Code in Addr.** as they were, no new entry in Address Validation Log.
- **The tests' saved baselines live in memory only.** Company Information (address and ship-to address), Marketing Setup (the four business-relation codes and **Inherit Address Details**) and the General Ledger Setup field **Req.Country/Reg. Code in Addr.** are saved at the start of a test and put back at its clean-up, but nothing is written to a table. **A crashed, cancelled or timed-out run can leave any of the three altered in the TEST company**, and the next run then saves the altered values as if they were the real ones.
- **Before the first run write down:** the Company Information **address and ship-to address** (Address, Address 2, City, County, Post Code, Country/Region Code, and the Ship-to equivalents), the **Marketing Setup** business-relation codes (for customers, vendors, bank accounts, employees) and **Inherit Address Details**, and the General Ledger Setup field **Req.Country/Reg. Code in Addr.** (**Require Country/Region Code in Addresses** in the field's caption on some versions: it is the switch that makes Business Central keep the address when the country changes).
- **Manual recovery after a failed or interrupted run:** (1) search for `GAVUT*` in the Customers, Vendors, Contacts, Employees, Resources, Locations, Responsibility Centers, Bank Accounts and **Business Relations** pages and delete what is left (children first: ship-to, bank account and alternative addresses before their parents; the Contacts that Business Central created for test vendors and bank accounts last); (2) open **Company Information** and put back the values you wrote down; (3) open **Marketing Setup** and put back the codes and the switch; (4) open **General Ledger Setup** and put back **Req.Country/Reg. Code in Addr.**; (5) check the **Privacy Notices** page (below). The Business Relation codes the tests create are `GAVUTC`, `GAVUTV`, `GAVUTB` and `GAVUTE`. The countries **US** and **CA** are inserted when missing and are left in place; they are harmless, delete them only if the company must not have them.
- **Do not run the automated tests in a company whose Company Information, Marketing Setup or General Ledger Setup matter.** Use a copy of a sandbox for the tests.
- **The 1.1 tests do not call Google and need no key**, like the older ones.
- **The tests record organization-wide consent while they run.** To pass the privacy check, the test setup sets the Google privacy notice (`OBCFGAV-ADDRESS`, *Google Address Validation*) to **Agreed for the whole organization** and puts the earlier state back when each test cleans up. Do not run the tests in an environment where agreement to that notice must stay exactly as it is; if a run is stopped half-way, check the **Privacy Notices** page afterwards.
- **One test uses a part never tried.** `TestPrivacyRefusedSendsNothing` (row 53) clicks **Disagree** (the page's `Reject` action) on Business Central's own **Privacy Notice** page through a test handler that has never been run. If it fails, report it as usual; it may be the test, not the extension. It needs a user who is allowed to decide the notice for the organization (SUPER is).
- **The tests never call Google.** They use a simulated web layer, so no API key, no billing and no quota are involved and the made-up address data in them is never sent anywhere.
- **The extension under test installed first**, at the version §1 names. The test app depends on it and
  will refuse to install without it.

## 3. Install the test framework (once per sandbox)

The page that runs tests lives in Microsoft's Test Runner. The three libraries are small Microsoft apps the framework installs as standard (see §1: this test app does not depend on them). All
four are free and published by Microsoft. Install them in this order; each takes under a minute.

| Order | App | Publisher | App ID |
|---|---|---|---|
| 1 | **Test Runner** (brings the **AL Test Tool** page) | Microsoft | `23de40a6-dfe8-4f80-80db-d70f83ce8caf` |
| 2 | **Library Assert** | Microsoft | `dd0be2ea-f733-4d65-bb34-a28f4624fb14` |
| 3 | **Any** | Microsoft | `e7320ebb-08b3-4406-b1ec-b4927d3e280b` |
| 4 | **Library Variable Storage** | Microsoft | `5095f467-0a01-4b99-99d1-9ff1237d286f` |

For each one:

1. Open the sandbox, choose the **Search for Page or Report** icon (magnifying glass, top right), type
   **Microsoft Marketplace Apps**, and open the page. It lists the Business Central apps available to
   this environment.
2. Find the app by the exact name in the table. Check the publisher is **Microsoft**.
3. Select it and choose **Install**; accept the terms and wait for the confirmation.
4. Open **Extension Management** the same way, choose **Refresh**, and confirm the app shows as
   **Installed**.

**If Test Runner is not listed, stop and tell the agent.** (If one of the three libraries is not listed, you can carry on; say so in your report.) Do not look for the file on disk or
in a Docker image. A developer can install a Microsoft app that the page doesn't show by its App ID
(the table above) through the Admin Center API — the agent knows the route — and if that isn't possible
for this sandbox, the agent will say plainly that the test app cannot be installed there and what the
alternatives are. Two Microsoft test apps — **Tests-TestLibraries** and **System Application Test
Library** — are *not* available in online sandboxes at all, which is why this project's tests use none of them.

## 4. Install the extension under test, then the test app

1. Install `outputAppPackage/Google_Address_Validator_1.3.0.0.app` by `docs/4-prove/SandboxInstall.md`, if it is
   not already installed at that exact version. (A test app is built against one version of the
   extension; a different version installed is the most common reason the test app refuses to install.)
2. Install `Google_Address_Validator_Tests_0.0.0.24.app` from the sibling folder (`/Users/ajansari/Documents/AL/USPSAddressValidator.Tests/outputAppPackage/`) the same way — same route, same steps,
   **Schema Sync Mode = Add** (the test app has no tables of its own).
3. On **Extension Management**, confirm both are **Installed**: **Google Address Validator** at **1.2.0.4** and **Google Address Validator Tests** at **0.0.0.23**.
4. Make sure your user has a company named with **TEST** selected (top of the screen).

## 5. Open the AL Test Tool and load the tests

1. Choose the **Search for Page or Report** icon, type **AL Test Tool**, and open it. (**Find the page by
   searching its name, not by a page number:** the number is unresolved, see §1. Tell the agent the number
   the page shows if you can see it. If the search finds nothing, the **Test Runner** app from §3 is not
   installed.)
2. The page opens on a test suite called **DEFAULT** (the **Suite Name** field at the top). Leave it.
3. Choose **Manage Tests**, then **Get Test Codeunits**. A list of every test codeunit installed in the
   environment opens.
4. Select the codeunits from §6 — `codeunit 92832 obcfgav Validation Tests`, `codeunit 92833 obcfgav Provider Tests`, `codeunit 92834 obcfgav Addr Validated Tests`, `codeunit 92836 obcfgav Source Tests`, `codeunit 92837 obcfgav Sync Tests`, `codeunit 92838 obcfgav Country Tests` — and choose **OK**. One line per
   codeunit appears, each followed by one line per test method; the **Line Type** column says which is
   which, **Codeunit ID** and **Name** say what they are. You should end with 6 codeunit lines and 155 method lines.
5. Every line has its **Run** checkbox ticked. Leave them ticked; the one-at-a-time procedure in §7
   does not depend on them.

The list stays on the page between sessions. After a new build of the test app, choose
**Manage Tests → Update Test Methods** so the lines match the new code.

## 6. What each test checks

One row per test method. Run them in this order the first time; later, run only what a fix touched.

| # | Codeunit (ID · name) | Test method | What it checks | Expected result | Setup it needs first |
|---|---|---|---|---|---|
| 1 | `codeunit 92832 · obcfgav Validation Tests` | `TestMatchingAddressIsConfirmed` | An address Google says is identical is confirmed without a dialog, the customer is flagged Address Validated, and a Confirmed log row is written. | **Success** | none |
| 2 | `codeunit 92832 · obcfgav Validation Tests` | `TestAcceptedUpdatesCustomer` | Accepting a suggestion writes the five suggested values (ZIP as 62701-1234) to the customer and logs Suggestion Accepted with both addresses. | **Success** | none |
| 3 | `codeunit 92832 · obcfgav Validation Tests` | `TestIgnoredLoggedEachTime` | Cancelling the comparison dialog twice leaves the customer unchanged and writes two Suggestion Ignored log rows. | **Success** | none |
| 4 | `codeunit 92832 · obcfgav Validation Tests` | `TestNotFoundReportedAndLogged` | When Google can only match the street (not the building) the user gets the not-confirmed message and a Not Found log row is written. | **Success** | none |
| 5 | `codeunit 92832 · obcfgav Validation Tests` | `TestDeliveryWarningThenAccept` | A missing suite or apartment number (code D) shows the warning in the dialog, and Accept still works. | **Success** | none |
| 6 | `codeunit 92832 · obcfgav Validation Tests` | `TestLetterCaseConfirmed` | An address that differs only in upper/lower case counts as confirmed, with no dialog and no change to the customer. | **Success** | none |
| 7 | `codeunit 92832 · obcfgav Validation Tests` | `TestPunctuationConfirmed` | Periods, commas and repeated spaces are not a difference: the address is confirmed with no dialog. | **Success** | none |
| 8 | `codeunit 92832 · obcfgav Validation Tests` | `TestStreetSplitConfirmed` | A street and an apartment line that Google splits differently from the customer's lines still count as the same address. | **Success** | none |
| 9 | `codeunit 92832 · obcfgav Validation Tests` | `TestConfirmedWithNote` | An identical address with a missing-suite signal stays Confirmed and the confirmation message carries the missing-suite note. | **Success** | none |
| 10 | `codeunit 92832 · obcfgav Validation Tests` | `TestConfirmedDpvUnconfirmed` | An identical address whose suite could not be confirmed (code S) stays Confirmed, with that note in the message. | **Success** | none |
| 11 | `codeunit 92832 · obcfgav Validation Tests` | `TestDeliveryWarningNotDeliverable` | Code N shows the "could not confirm this address as deliverable" warning in the dialog. | **Success** | none |
| 12 | `codeunit 92832 · obcfgav Validation Tests` | `TestBooleanFlagsAndNotes` | Google's "vacant" and "business" flags show as notes in the dialog, and "address complete" is stored in the log. | **Success** | none |
| 13 | `codeunit 92832 · obcfgav Validation Tests` | `TestSeamNotFound` | A different (simulated) provider that reports "not found" gets the same Not Found handling and log row, with no web call. | **Success** | none |
| 14 | `codeunit 92832 · obcfgav Validation Tests` | `TestSeamError` | A simulated provider failure is logged as Error, the user gets its text, and the customer is unchanged. | **Success** | none |
| 15 | `codeunit 92832 · obcfgav Validation Tests` | `TestSeamNoCredentials` | A provider without credentials gives the "Enter the API key first" error before any call, with HTTP status 0 in the log. | **Success** | none |
| 16 | `codeunit 92832 · obcfgav Validation Tests` | `TestNonUSRefusedNoCall` | A customer in Russia (RU), a country Google does not cover, is refused with the not-covered message (*Google Maps can't validate addresses in …*, the country name as in Business Central), nothing is sent and nothing is logged. Moved from Canada to Russia in 0.0.0.21. | **Success** | none |
| 17 | `codeunit 92832 · obcfgav Validation Tests` | `TestPreconditionsBlockTheCall` | Disabled setup, no API key, no provider, an empty address and a state written out in full are each refused with the right message, nothing is sent and nothing is logged. | **Success** | none |
| 18 | `codeunit 92832 · obcfgav Validation Tests` | `TestTooLongBlocksAccept` | If Google returns a city longer than the customer field, Accept is blocked with the reason, the customer is unchanged, and the check is logged as Suggestion Ignored. | **Success** | none |
| 19 | `codeunit 92832 · obcfgav Validation Tests` | `TestChangedDuringDialog` | If the customer's address is changed while the dialog is open, Accept writes nothing, shows the address-changed message and logs Suggestion Ignored. | **Success** | none |
| 20 | `codeunit 92832 · obcfgav Validation Tests` | `TestFailedWriteLogged` | If saving the customer fails after Google answered, the customer stays unchanged and the failure is logged as Error with the failure text. | **Success** | none |
| 21 | `codeunit 92832 · obcfgav Validation Tests` | `TestRequestShape` | Exactly one request goes out; it carries the street, city, state and ZIP, the key only in a header, and never the customer's name or number. | **Success** | none |
| 22 | `codeunit 92832 · obcfgav Validation Tests` | `TestProviderSeam` | A different (simulated) provider runs the same check, message and log, and the web layer is not used. | **Success** | none |
| 23 | `codeunit 92832 · obcfgav Validation Tests` | `TestProviderSeamDialog` | The dialog names the simulated provider and Accept works unchanged. | **Success** | none |
| 24 | `codeunit 92832 · obcfgav Validation Tests` | `TestAttributionShown` | The dialog shows the line "Suggestion from Google Maps". | **Success** | none |
| 25 | `codeunit 92833 · obcfgav Provider Tests` | `TestKeyRejected400` | A rejected key (400, key invalid) gives the key-rejected message and an Error log row with HTTP status 400. | **Success** | none |
| 26 | `codeunit 92833 · obcfgav Provider Tests` | `TestKeyRejected401` | A 401 answer gives the same key-rejected message and an Error row with HTTP status 401. | **Success** | none |
| 27 | `codeunit 92833 · obcfgav Provider Tests` | `TestQuotaNoRetry` | The request-limit answer (429) gives the limit message, an Error log row, and exactly one call (no retry). | **Success** | none |
| 28 | `codeunit 92833 · obcfgav Provider Tests` | `TestNoResponseNoRetry` | No answer from Google gives the not-responding message, an Error log row with HTTP status 0, and exactly one call. | **Success** | none |
| 29 | `codeunit 92833 · obcfgav Provider Tests` | `TestApiDisabled` | "API not enabled" (403) gives the API-not-enabled message and an Error log row. | **Success** | none |
| 30 | `codeunit 92833 · obcfgav Provider Tests` | `TestBillingDisabled` | "Billing not enabled" (403) gives the billing message and an Error log row. | **Success** | none |
| 31 | `codeunit 92833 · obcfgav Provider Tests` | `TestKeyRestricted` | A key restricted from this API (403) gives the check-the-key's-restrictions message. | **Success** | none |
| 32 | `codeunit 92833 · obcfgav Provider Tests` | `TestOtherForbidden` | Any other 403 shows "Google Maps refused the request:" and Google's own text. | **Success** | none |
| 33 | `codeunit 92833 · obcfgav Provider Tests` | `TestInvalidArgumentMessage` | Any other 400 shows "Google Maps could not read the address:" and Google's own text. | **Success** | none |
| 34 | `codeunit 92833 · obcfgav Provider Tests` | `Test5xx` | A server error (503) gives the not-responding message and an Error log row with HTTP status 503. | **Success** | none |
| 35 | `codeunit 92833 · obcfgav Provider Tests` | `TestUnmappedStatus` | A status nobody planned for (404) gives the unexpected-response message and an Error log row. | **Success** | none |
| 36 | `codeunit 92833 · obcfgav Provider Tests` | `TestUnparsable200` | An answer that is not readable gives the unexpected-response message and an Error log row. | **Success** | none |
| 37 | `codeunit 92833 · obcfgav Provider Tests` | `TestNoVerdict200` | An answer with no verdict gives the unexpected-response message and an Error log row. | **Success** | none |
| 38 | `codeunit 92833 · obcfgav Provider Tests` | `TestValidatedWithoutAddress` | A "validated" answer with no usable address is treated as an unexpected response, not as a validation. | **Success** | none |
| 39 | `codeunit 92833 · obcfgav Provider Tests` | `TestUnconfirmedPartsInReason` | The not-confirmed message lists the missing parts first, then the unconfirmed ones. | **Success** | none |
| 40 | `codeunit 92833 · obcfgav Provider Tests` | `TestNotValidatedOther` | A not-confirmed answer on a validated customer gives Not Found with the missing parts, resets Address Validated to No, and leaves the address alone. | **Success** | none |
| 41 | `codeunit 92833 · obcfgav Provider Tests` | `TestGranularityNotValidated` | Every precision level below building (ROUTE, PREMISE_PROXIMITY, BLOCK, unspecified) is Not Found, even when an address comes back. | **Success** | none |
| 42 | `codeunit 92833 · obcfgav Provider Tests` | `TestSubPremiseValidated` | A match down to the suite (SUB_PREMISE) counts as validated just like a building match. | **Success** | none |
| 43 | `codeunit 92833 · obcfgav Provider Tests` | `TestFallbackPostalAddress` | When Google gives no USPS-standardized address, its postal address is used and a 9-digit ZIP gets its dash. | **Success** | none |
| 44 | `codeunit 92833 · obcfgav Provider Tests` | `TestKeyOnlyInHeader` | The API key is in a request header only, never in the URL, the body or the log. | **Success** | none |
| 45 | `codeunit 92833 · obcfgav Provider Tests` | `TestNoCustomerDataSent` | The customer's name and number are never sent, and a blank second address line adds no empty line. | **Success** | none |
| 46 | `codeunit 92833 · obcfgav Provider Tests` | `TestPostCodeMustBeZipLike` | A Post Code that is not ZIP-like (ABCDE) with no city and state is refused as an incomplete address, nothing is sent. | **Success** | none |
| 47 | `codeunit 92833 · obcfgav Provider Tests` | `TestTestConnectionProbeOk` | Test Connection sends one request with no address lines and no log row, and treats "invalid request" as "the key works". | **Success** | none |
| 48 | `codeunit 92833 · obcfgav Provider Tests` | `TestTestConnection200` | Test Connection also reports success when Google answers 200. | **Success** | none |
| 49 | `codeunit 92833 · obcfgav Provider Tests` | `TestTestConnectionKeyRejected` | Test Connection reports the failure with the key-rejected reason and Google's message. | **Success** | none |
| 50 | `codeunit 92833 · obcfgav Provider Tests` | `TestTestConnectionApiOff` | Test Connection reports the failure with the API-not-enabled reason and Google's message. | **Success** | none |
| 51 | `codeunit 92833 · obcfgav Provider Tests` | `TestTestConnectionNoResponse` | Test Connection reports the failure with the not-responding reason when there is no answer. | **Success** | none |
| 52 | `codeunit 92833 · obcfgav Provider Tests` | `TestTestConnectionNoKey` | Test Connection with no key stored says "Enter the API key first" and sends nothing. | **Success** | none |
| 53 | `codeunit 92833 · obcfgav Provider Tests` | `TestPrivacyRefusedSendsNothing` | If the privacy notice is disagreed, nothing is sent to Google, nothing is logged and the privacy message is shown. Uses a modal handler on the page Privacy Notice that has never been tried. | **Success** | none |
| 54 | `codeunit 92834 · obcfgav Addr Validated Tests` | `TestAcceptSetsFlagFromFalse` | Accepting a suggestion sets Address Validated from No to Yes. | **Success** | none |
| 55 | `codeunit 92834 · obcfgav Addr Validated Tests` | `TestConfirmedSetsFlag` | A confirmed address sets Address Validated to Yes and leaves the address fields alone. | **Success** | none |
| 56 | `codeunit 92834 · obcfgav Addr Validated Tests` | `TestCancelLeavesFlagUnchanged` | Cancelling the dialog leaves Address Validated unchanged, whether it was No or Yes. | **Success** | none |
| 57 | `codeunit 92834 · obcfgav Addr Validated Tests` | `TestEditingAddressResetsFlag` | Editing the city of a validated customer resets Address Validated to No. | **Success** | none |
| 58 | `codeunit 92834 · obcfgav Addr Validated Tests` | `TestAcceptKeepsFlagTrue` | Accepting a suggestion on an already validated customer leaves Address Validated at Yes (Accept is not counted as an edit). | **Success** | none |
| 59 | `codeunit 92834 · obcfgav Addr Validated Tests` | `TestNewCustomerIsNotValidated` | A new customer starts with Address Validated = No. | **Success** | none |
| 60 | `codeunit 92834 · obcfgav Addr Validated Tests` | `TestNotFoundClearsFlag` | An address Google cannot confirm to the building resets Address Validated to No on a validated customer. | **Success** | none |
| 61 | `codeunit 92834 · obcfgav Addr Validated Tests` | `TestErrorKeepsFlag` | A Google error (request limit) leaves Address Validated unchanged. | **Success** | none |
| 62 | `codeunit 92836 · obcfgav Source Tests` | `TestAcceptShipTo` | FRD test 25. Accepting a suggestion on a Ship-to Address writes the five suggested values, sets its Address Validated to Yes, and writes one log entry naming the table, record, address type and key (Customer No. blank). | **Success** | none |
| 63 | `codeunit 92836 · obcfgav Source Tests` | `TestAcceptCustBank` | FRD test 25. Accepting a suggestion on a Customer Bank Account writes the five suggested values, sets its Address Validated to Yes, and writes one log entry naming the table, record, address type and key (Customer No. blank). | **Success** | none |
| 64 | `codeunit 92836 · obcfgav Source Tests` | `TestAcceptVendor` | FRD test 25. Accepting a suggestion on a Vendor writes the five suggested values, sets its Address Validated to Yes, and writes one log entry naming the table, record, address type and key (Customer No. blank). | **Success** | none |
| 65 | `codeunit 92836 · obcfgav Source Tests` | `TestAcceptOrderAddr` | FRD test 25. Accepting a suggestion on a Order Address writes the five suggested values, sets its Address Validated to Yes, and writes one log entry naming the table, record, address type and key (Customer No. blank). | **Success** | none |
| 66 | `codeunit 92836 · obcfgav Source Tests` | `TestAcceptRemitAddr` | FRD test 25. Accepting a suggestion on a Remit Address writes the five suggested values, sets its Address Validated to Yes, and writes one log entry naming the table, record, address type and key (Customer No. blank). | **Success** | none |
| 67 | `codeunit 92836 · obcfgav Source Tests` | `TestAcceptVendBank` | FRD test 25. Accepting a suggestion on a Vendor Bank Account writes the five suggested values, sets its Address Validated to Yes, and writes one log entry naming the table, record, address type and key (Customer No. blank). | **Success** | none |
| 68 | `codeunit 92836 · obcfgav Source Tests` | `TestAcceptCompanyMain` | FRD test 25. Accepting a suggestion on a Company Information (company address) writes the five suggested values, sets its Address Validated to Yes, and writes one log entry naming the table, record, address type and key (Customer No. blank). | **Success** | none |
| 69 | `codeunit 92836 · obcfgav Source Tests` | `TestAcceptCompanyShipTo` | FRD test 25. Accepting a suggestion on a Company Information (ship-to address) writes the five suggested values, sets its Address Validated to Yes, and writes one log entry naming the table, record, address type and key (Customer No. blank). | **Success** | none |
| 70 | `codeunit 92836 · obcfgav Source Tests` | `TestAcceptLocation` | FRD test 25. Accepting a suggestion on a Location writes the five suggested values, sets its Address Validated to Yes, and writes one log entry naming the table, record, address type and key (Customer No. blank). | **Success** | none |
| 71 | `codeunit 92836 · obcfgav Source Tests` | `TestAcceptRespCenter` | FRD test 25. Accepting a suggestion on a Responsibility Center writes the five suggested values, sets its Address Validated to Yes, and writes one log entry naming the table, record, address type and key (Customer No. blank). | **Success** | none |
| 72 | `codeunit 92836 · obcfgav Source Tests` | `TestAcceptBankAcc` | FRD test 25. Accepting a suggestion on a Bank Account writes the five suggested values, sets its Address Validated to Yes, and writes one log entry naming the table, record, address type and key (Customer No. blank). | **Success** | none |
| 73 | `codeunit 92836 · obcfgav Source Tests` | `TestAcceptEmployee` | FRD test 25. Accepting a suggestion on a Employee writes the five suggested values, sets its Address Validated to Yes, and writes one log entry naming the table, record, address type and key (Customer No. blank). | **Success** | none |
| 74 | `codeunit 92836 · obcfgav Source Tests` | `TestAcceptAltAddr` | FRD test 25. Accepting a suggestion on a Alternative Address writes the five suggested values, sets its Address Validated to Yes, and writes one log entry naming the table, record, address type and key (Customer No. blank). | **Success** | none |
| 75 | `codeunit 92836 · obcfgav Source Tests` | `TestAcceptContact` | FRD test 25. Accepting a suggestion on a Contact writes the five suggested values, sets its Address Validated to Yes, and writes one log entry naming the table, record, address type and key (Customer No. blank). | **Success** | none |
| 76 | `codeunit 92836 · obcfgav Source Tests` | `TestAcceptContAltAddr` | FRD test 25. Accepting a suggestion on a Contact Alt. Address writes the five suggested values, sets its Address Validated to Yes, and writes one log entry naming the table, record, address type and key (Customer No. blank). | **Success** | none |
| 77 | `codeunit 92836 · obcfgav Source Tests` | `TestAcceptResource` | FRD test 25. Accepting a suggestion on a Resource writes the five suggested values, sets its Address Validated to Yes, and writes one log entry naming the table, record, address type and key (Customer No. blank). | **Success** | none |
| 78 | `codeunit 92836 · obcfgav Source Tests` | `TestEditResetsShipTo` | FRD test 27. Editing any of Address, Address 2, City, State, ZIP Code or Country/Region Code of a validated Ship-to Address sets its Address Validated back to No. | **Success** | none |
| 79 | `codeunit 92836 · obcfgav Source Tests` | `TestEditResetsCustBank` | FRD test 27. Editing any of Address, Address 2, City, State, ZIP Code or Country/Region Code of a validated Customer Bank Account sets its Address Validated back to No. | **Success** | none |
| 80 | `codeunit 92836 · obcfgav Source Tests` | `TestEditResetsVendor` | FRD test 27. Editing any of Address, Address 2, City, State, ZIP Code or Country/Region Code of a validated Vendor sets its Address Validated back to No. | **Success** | none |
| 81 | `codeunit 92836 · obcfgav Source Tests` | `TestEditResetsOrderAddr` | FRD test 27. Editing any of Address, Address 2, City, State, ZIP Code or Country/Region Code of a validated Order Address sets its Address Validated back to No. | **Success** | none |
| 82 | `codeunit 92836 · obcfgav Source Tests` | `TestEditResetsRemitAddr` | FRD test 27. Editing any of Address, Address 2, City, State, ZIP Code or Country/Region Code of a validated Remit Address sets its Address Validated back to No. | **Success** | none |
| 83 | `codeunit 92836 · obcfgav Source Tests` | `TestEditResetsVendBank` | FRD test 27. Editing any of Address, Address 2, City, State, ZIP Code or Country/Region Code of a validated Vendor Bank Account sets its Address Validated back to No. | **Success** | none |
| 84 | `codeunit 92836 · obcfgav Source Tests` | `TestEditResetsCompanyMain` | FRD test 27. Editing any of Address, Address 2, City, State, ZIP Code or Country/Region Code of a validated Company Information (company address) sets its Address Validated back to No. | **Success** | none |
| 85 | `codeunit 92836 · obcfgav Source Tests` | `TestEditResetsCompanyShipTo` | FRD test 27. Editing any of the six address fields of a validated Company Information (ship-to address) sets its Address Validated back to No. | **Success** | none |
| 86 | `codeunit 92836 · obcfgav Source Tests` | `TestEditResetsLocation` | FRD test 27. Editing any of Address, Address 2, City, State, ZIP Code or Country/Region Code of a validated Location sets its Address Validated back to No. | **Success** | none |
| 87 | `codeunit 92836 · obcfgav Source Tests` | `TestEditResetsRespCenter` | FRD test 27. Editing any of Address, Address 2, City, State, ZIP Code or Country/Region Code of a validated Responsibility Center sets its Address Validated back to No. | **Success** | none |
| 88 | `codeunit 92836 · obcfgav Source Tests` | `TestEditResetsBankAcc` | FRD test 27. Editing any of Address, Address 2, City, State, ZIP Code or Country/Region Code of a validated Bank Account sets its Address Validated back to No. | **Success** | none |
| 89 | `codeunit 92836 · obcfgav Source Tests` | `TestEditResetsEmployee` | FRD test 27. Editing any of Address, Address 2, City, State, ZIP Code or Country/Region Code of a validated Employee sets its Address Validated back to No. | **Success** | none |
| 90 | `codeunit 92836 · obcfgav Source Tests` | `TestEditResetsAltAddr` | FRD test 27. Editing any of Address, Address 2, City, State, ZIP Code or Country/Region Code of a validated Alternative Address sets its Address Validated back to No. | **Success** | none |
| 91 | `codeunit 92836 · obcfgav Source Tests` | `TestEditResetsContact` | FRD test 27. Editing any of Address, Address 2, City, State, ZIP Code or Country/Region Code of a validated Contact sets its Address Validated back to No. | **Success** | none |
| 92 | `codeunit 92836 · obcfgav Source Tests` | `TestEditResetsContAltAddr` | FRD test 27. Editing any of Address, Address 2, City, State, ZIP Code or Country/Region Code of a validated Contact Alt. Address sets its Address Validated back to No. | **Success** | none |
| 93 | `codeunit 92836 · obcfgav Source Tests` | `TestEditResetsResource` | FRD test 27. Editing any of Address, Address 2, City, State, ZIP Code or Country/Region Code of a validated Resource sets its Address Validated back to No. | **Success** | none |
| 94 | `codeunit 92836 · obcfgav Source Tests` | `TestCompanyBlocksIndependent` | FRD test 28. On Company Information the company address and the ship-to address validate, write and reset independently of each other. | **Success** | none |
| 95 | `codeunit 92836 · obcfgav Source Tests` | `TestShipToAcceptKeepsMain` | FRD test 28. Accept on the company ship-to block writes only that block; the main block and its indicator are untouched. | **Success** | none |
| 96 | `codeunit 92836 · obcfgav Source Tests` | `TestPrivacyBlockedChildren` | FRD test 40. The children of a Privacy Blocked parent (Customer Bank Account, Order Address, Remit Address, Vendor Bank Account, Alternative Address, Contact Alt. Address) are refused with the privacy message; nothing is sent and nothing is logged. | **Success** | none |
| 97 | `codeunit 92836 · obcfgav Source Tests` | `TestVendorGoneDuringDialog` | FR-18.2. If the Vendor is deleted while the dialog is open, nothing is written and the message *The Vendor record no longer exists, so nothing was updated.* is shown; the outcome is Error. | **Success** | none |
| 98 | `codeunit 92836 · obcfgav Source Tests` | `TestCustomerGoneDuringDialog` | FR-18.2. The same for a Customer deleted while the dialog is open: *The Customer record no longer exists, so nothing was updated.* | **Success** | none |
| 99 | `codeunit 92836 · obcfgav Source Tests` | `TestAcceptSetsUsCountry` | FR-18.6. Accepting a suggestion on a Vendor whose Country/Region Code is blank fills it in with the country code (the setup's Default Country/Region Code, or the country Google found), writes the suggested address and sets Address Validated to Yes. | **Success** | none |
| 100 | `codeunit 92836 · obcfgav Source Tests` | `TestConfirmedSetsUsCountry` | FR-18.6. A Confirmed result on a Location whose Country/Region Code is blank fills it in with the setup's Default Country/Region Code (US) and sets Address Validated to Yes. | **Success** | none |
| 101 | `codeunit 92836 · obcfgav Source Tests` | `TestNotFoundKeepsBlankCountry` | FR-18.6. A Not Found result on a Vendor whose Country/Region Code is blank leaves the country blank. | **Success** | none |
| 102 | `codeunit 92836 · obcfgav Source Tests` | `TestVendorConfirmed` | FRD test 26. A Confirmed result on a Vendor sets its Address Validated and logs Confirmed. | **Success** | none |
| 103 | `codeunit 92836 · obcfgav Source Tests` | `TestVendorNotFoundClears` | FRD test 26. A Not Found result on a validated Vendor resets Address Validated and leaves the address. | **Success** | none |
| 104 | `codeunit 92836 · obcfgav Source Tests` | `TestVendorIgnoreKeeps` | FRD test 26. Cancelling the dialog on a Vendor keeps the address and the indicator and logs Suggestion Ignored. | **Success** | none |
| 105 | `codeunit 92836 · obcfgav Source Tests` | `TestVendorErrorKeeps` | FRD test 26. A provider failure on a Vendor is logged as Error and the record is unchanged. | **Success** | none |
| 106 | `codeunit 92836 · obcfgav Source Tests` | `TestVendorNonUSRefused` | FRD test 29. A Vendor with Country/Region RU is refused with the not-covered message for Russia, nothing is sent and nothing is logged. Moved from CA to RU in 0.0.0.21, because Canada is covered from 1.2. | **Success** | none |
| 107 | `codeunit 92836 · obcfgav Source Tests` | `TestVendorChangedInDialog` | FRD test 26 and FR-4. If the Vendor is edited while the dialog is open, nothing is written and the generic address-changed message is shown. | **Success** | none |
| 108 | `codeunit 92836 · obcfgav Source Tests` | `TestLocationTooLongBlocks` | A suggested city longer than the Location field blocks Accept with the reason; the record is unchanged. | **Success** | none |
| 109 | `codeunit 92836 · obcfgav Source Tests` | `TestUnsupportedSourceRefused` | FRD test 36. A table that is not a source (an Item) is refused with *Address validation is not available for this record.*; nothing is sent or logged. | **Success** | none |
| 110 | `codeunit 92836 · obcfgav Source Tests` | `TestContactPersonValidates` | FRD test 31. A person Contact is validated like a company. | **Success** | none |
| 111 | `codeunit 92836 · obcfgav Source Tests` | `TestContactCompanyValidates` | FRD test 31. A company Contact is validated. | **Success** | none |
| 112 | `codeunit 92836 · obcfgav Source Tests` | `TestCustomerLogKeepsCustNo` | FRD tests 37 and 38. A Customer log entry keeps Customer No. and also carries the source table, type and system ID (and, from 0.0.0.18, a Record No. that holds the key of the record). | **Success** | none |
| 113 | `codeunit 92836 · obcfgav Source Tests` | `TestLogDescriptionHasNoName` | FRD test 38. The log's source description contains the table and key and never the record's name. | **Success** | none |
| 114 | `codeunit 92836 · obcfgav Source Tests` | `TestPrivacyBlockedCustomer` | FRD test 40. A Privacy Blocked Customer is refused with the privacy message, nothing is sent and nothing is logged. | **Success** | none |
| 115 | `codeunit 92836 · obcfgav Source Tests` | `TestPrivacyBlockedChild` | FRD test 40. A Ship-to Address of a Privacy Blocked Customer is refused the same way. | **Success** | none |
| 116 | `codeunit 92837 · obcfgav Sync Tests` | `TestCustAcceptUpdatesCont` | FRD test 32. Accept on a Customer updates the linked Contact's address and Address Validated. | **Success** | none |
| 117 | `codeunit 92837 · obcfgav Sync Tests` | `TestVendAcceptUpdatesCont` | FRD test 32. Accept on a Vendor updates the linked Contact's address and Address Validated. | **Success** | none |
| 118 | `codeunit 92837 · obcfgav Sync Tests` | `TestBankAccAcceptUpdatesCont` | FRD test 32. Accept on a Bank Account updates the linked Contact's address and Address Validated. | **Success** | none |
| 119 | `codeunit 92837 · obcfgav Sync Tests` | `TestContEditClearsCustFlag` | FRD test 32. Editing the Contact's address clears the Customer's Address Validated (proves that TransferFields copies the shared field number). | **Success** | none |
| 120 | `codeunit 92837 · obcfgav Sync Tests` | `TestCustNotFoundClearsCont` | FRD tests 32 and FR-12.4. A Not Found result on a Customer also clears the Contact's Address Validated. | **Success** | none |
| 121 | `codeunit 92837 · obcfgav Sync Tests` | `TestLinkedSyncFailureKeeps` | FRD test 41. When the linked Contact update fails after a Confirmed, the check stays logged as Confirmed, the Customer is validated and the Contact is unchanged. Binds its own subscriber by hand (see below). | **Success** | none |
| 122 | `codeunit 92837 · obcfgav Sync Tests` | `TestCompanyAcceptFlagsPerson` | FRD test 31. With Inherit Address Details on, a person that shared the company's address takes the company's new address and indicator. | **Success** | none |
| 123 | `codeunit 92837 · obcfgav Sync Tests` | `TestPersonJoinsCompanyFlag` | FRD test 44. A person linked to a validated company takes the company's address and indicator. | **Success** | none |
| 124 | `codeunit 92837 · obcfgav Sync Tests` | `TestPersonAcceptKeepsCompany` | FRD test 45. Accept on a person Contact never changes the company Contact. | **Success** | none |
| 125 | `codeunit 92837 · obcfgav Sync Tests` | `TestContAcceptFlagsEmployee` | FRD tests 32 and FR-12.4. Accept on a Contact linked to an Employee gives the Employee the address and the indicator. | **Success** | none |
| 126 | `codeunit 92837 · obcfgav Sync Tests` | `TestEmpAcceptUpdatesResource` | FRD test 33. Accept on an Employee with a linked Resource updates the Resource's address and indicator. | **Success** | none |
| 127 | `codeunit 92837 · obcfgav Sync Tests` | `TestEmpNotFoundClearsRes` | FRD test 43. A Not Found result on an Employee never leaves the linked Resource at Yes. | **Success** | none |
| 128 | `codeunit 92837 · obcfgav Sync Tests` | `TestContEditClearsVendFlag` | FRD test 32. Editing the Contact's address clears the Vendor's Address Validated. | **Success** | none |
| 129 | `codeunit 92837 · obcfgav Sync Tests` | `TestContEditClearsBankFlag` | FRD test 32. Editing the Contact's address clears the Bank Account's Address Validated. | **Success** | none |
| 130 | `codeunit 92837 · obcfgav Sync Tests` | `TestContConfirmedFlagsCust` | FR-12.4. Confirmed on the linked Contact gives the Customer the indicator. | **Success** | none |
| 131 | `codeunit 92837 · obcfgav Sync Tests` | `TestContNotFoundClearsCust` | FR-12.4. Not Found on the linked Contact clears the Customer's indicator. | **Success** | none |
| 132 | `codeunit 92837 · obcfgav Sync Tests` | `TestContEditClearsEmpFlag` | FR-12.4. Editing a Contact linked to an Employee clears the Employee's indicator. | **Success** | none |
| 133 | `codeunit 92837 · obcfgav Sync Tests` | `TestCountryChangeResetsFlag` | FRD test 39. With General Ledger Setup **Req.Country/Reg. Code in Addr.** on, Business Central keeps the city when the country changes from US to CA, yet Address Validated is reset to No (the country is part of the validated address). | **Success** | none |
| 134 | `codeunit 92837 · obcfgav Sync Tests` | `TestCountryClearResetsFlag` | FRD test 39. With **Req.Country/Reg. Code in Addr.** off, a country change makes Business Central clear the city, and Address Validated is reset to No. | **Success** | none |
| 135 | `codeunit 92838 · obcfgav Country Tests` | `TestCanadaConfirmed` | SC-4. A Canadian vendor (CA, Ontario, M5H 2N2) is checked: the request carries region CA and no USPS CASS processing, the result is Confirmed, and Address Validated is Yes. | **Success** | none |
| 136 | `codeunit 92838 · obcfgav Country Tests` | `TestCanadaBadPostalCodeBlocks` | SC-4. A Canadian record with a postal code that is not of the form A1A 1A1 (12345) and no city or province is refused as an incomplete address; nothing is sent. | **Success** | none |
| 137 | `codeunit 92838 · obcfgav Country Tests` | `TestGermanyConfirmedWithoutState` | SC-4. A German vendor is checked: the request carries region DE, the State stays blank, the result is Confirmed, and no state is asked for. | **Success** | none |
| 138 | `codeunit 92838 · obcfgav Country Tests` | `TestGermanyNeedsCityOrPostalCode` | SC-4. A German record with only a street is refused as an incomplete address; nothing is sent. | **Success** | none |
| 139 | `codeunit 92838 · obcfgav Country Tests` | `TestUnsupportedCountryRefused` | SC-4. A record in Russia (RU) is refused with the not-covered message; nothing is sent and nothing is logged. | **Success** | none |
| 140 | `codeunit 92838 · obcfgav Country Tests` | `TestDisabledCountryRefused` | SC-4. When an administrator has turned a country off on the Supported Countries page, a record in it is refused with the not-turned-on message; nothing is sent or logged. | **Success** | none |
| 141 | `codeunit 92838 · obcfgav Country Tests` | `TestBlankCountryFilledFromResult` | SC-4, FR-18.6. A record with no country, with no default country in the setup, gets its Country/Region Code filled in from the region Google returned. | **Success** | none |
| 142 | `codeunit 92838 · obcfgav Country Tests` | `TestBlankCountryResultNotEnabled` | SC-4. A record with no country whose result is in a country that is turned off ends as Not Found, and the country stays blank. | **Success** | none |
| 143 | `codeunit 92838 · obcfgav Country Tests` | `TestRegionMismatchIsNotFound` | SC-4. When the record says one country and Google finds the address in another, the check ends as Not Found with the mismatch message naming both countries. | **Success** | none |
| 144 | `codeunit 92838 · obcfgav Country Tests` | `TestPuertoRicoResultMatchesUs` | SC-4. A result in Puerto Rico for a US record is not a mismatch. | **Success** | none |
| 145 | `codeunit 92838 · obcfgav Country Tests` | `TestSingaporeKeepsCity` | SC-4. In Singapore Google names no city, so the record's own city is kept. | **Success** | none |
| 146 | `codeunit 92838 · obcfgav Country Tests` | `TestGermanyKeepsPostalCode` | SC-4. When Google names no postal code in Germany, the record's own postal code is kept. | **Success** | none |
| 147 | `codeunit 92838 · obcfgav Country Tests` | `TestSublocalityActsAsAddress2` | SC-4. When Google gives a sublocality and no second address line, the sublocality becomes Address 2. | **Success** | none |
| 148 | `codeunit 92838 · obcfgav Country Tests` | `TestIsoCodeDiffersFromCode` | SC-4. The region sent is taken from the Country/Region's ISO Code, not from its Code (a country coded ZGB with ISO Code GB is sent as GB). | **Success** | none |
| 149 | `codeunit 92838 · obcfgav Country Tests` | `TestCountryWithoutIsoCodeRefused` | SC-4. A country with no ISO Code that cannot be read as a two-letter code is refused with the message that asks for its ISO Code; nothing is sent. | **Success** | none |
| 150 | `codeunit 92838 · obcfgav Country Tests` | `TestBlankCountryDanishAddressInferred` | SC-5. In a company whose default country is US with Blank Country Handling = Let Google decide, a Danish address with no country (Kobenhavn V, 1550, no state) is sent with no region; the simulated answer names Denmark, the result is Confirmed, and Country/Region Code is filled in with DK. | **Success** | none |
| 151 | `codeunit 92838 · obcfgav Country Tests` | `TestBlankCountryUsShapeHintsUs` | SC-5. With Let Google decide, a record with no country, state TX and ZIP 77494 is sent with region US and with USPS CASS processing requested. | **Success** | none |
| 152 | `codeunit 92838 · obcfgav Country Tests` | `TestBlankCountryCanadianPostalCodeHintsCa` | SC-5. With Let Google decide, a record with no country and the postal code M5H 2N2 is sent with region CA; the result is Confirmed and the country is filled in with CA. | **Success** | none |
| 153 | `codeunit 92838 · obcfgav Country Tests` | `TestBlankCountryUseDefaultSendsDefault` | SC-5, reworked in SC-5a. With Blank Country Handling = Use default country (default country US), a record with no country, no state and ZIP 15500 (it passes the US input rule and does not look like a US address under Let Google decide) is sent with region US, the default. | **Success** | none |
| 154 | `codeunit 92838 · obcfgav Country Tests` | `TestBlankCountryUseDefaultBlankDefaultSendsNoRegion` | SC-5a. With Use default country and a blank default country, a US-shaped record (TX, 77494) is sent with no region: nothing is guessed. | **Success** | none |
| 155 | `codeunit 92838 · obcfgav Country Tests` | `TestItalianProvinceRetriesWithoutRegion` | SC-5a. A Milan address (province MI, a US state code, and CAP 20121) with no country, under Let Google decide, is first sent as US; the first simulated answer is Not Found (street level); the request is repeated once with no region, the second answer names Italy and is Confirmed, the country is filled in with IT, and exactly two requests were sent. | **Success** | none |

**Notes on rows 135 to 155 (version 1.2, SC-4, SC-5, SC-5a).** Codeunit `92838 obcfgav Country Tests` holds 21 tests, in the order above (the order of the AL Test Tool; rows 150 to 155 are the blank-country tests of SC-5 and SC-5a, and row 153 was reworked in SC-5a), that need the main app 1.2.0.4: the country rules (Canada, Germany, Russia, a country switched off, a country with no ISO Code), the region sent and the CASS switch, the country fill-in and the mismatch, and which values are kept when Google names none, and (rows 150 to 155) how a record without a country is handled under Let Google decide and Use default country, including the repeat without a region. The test library switches the setup to **Use default country** before each test, so rows 1 to 149 keep their meaning, and the blank-country tests set the option they need; the library saves the whole setup row (including **Blank Country Handling** and **Default Country/Region Code**) in memory and puts it back at clean-up, but a crashed run loses that copy, so write both down in §2 before the run and check them on the setup page afterwards. Rows 1 to 134 keep their numbers. The tests insert missing Countries/Regions (CA, DE, US, SG, BR, ZGB, ZZZ) and switch a supported country off and on again; a crashed run can leave one switched off, so after a failure open **Google Address Validation Supported Countries** and check that **Enabled** is on for all 40 rows. The clean-up of every test switches **every** country that is off back on, so a country an administrator switched off in the TEST company is on again after a run: note your choices first and set them again afterwards. No row has been run.

**Notes on rows 62 to 134 (version 1.1).** *0.0.0.19 (FR-18.6):* rows 99 to 101 are new: the setup's US Country/Region Code fills a blank country on Accept and on Confirmed, and Not Found leaves it blank; because of them every later row of `codeunit 92836` and `codeunit 92837` moved down by three compared with the earlier edition of this guide. *0.0.0.18 (SC-2):* the library procedure `AssertLogSource` that most of the log-checking rows call (the Accept rows 62 to 77, the Confirmed, Not Found and Error rows, the Sync tests that check a log source) now also asserts **Record No.**: it must equal the non-blank parts of the source record's first key joined by ' / ' (for example `C00010 / MAIN`), and be blank when every key part is blank (Company Information), which also checks the separator. The first version of this assertion wrongly required a non-blank value for Company Information; the Code Review (CR-SC2-01) caught it and it was fixed in 0.0.0.18, so rows 68 and 69 are not expected to fail on it. If a row fails on this assertion it points at the Record No. written by the main app 1.1.0.12 or at the test's own key reading. `codeunit 92836 obcfgav Source Tests` (rows 62 to 115) covers FRD tests 25 to 29, 31, 36 to 38, 40 and 47 and the record-gone message (FR-18.2); `codeunit 92837 obcfgav Sync Tests` (rows 116 to 134) covers FRD tests 31 to 33, 39, 41, 43 to 45 and the linked-record rules. Rows are in the order of the AL Test Tool, which lists the methods in the order they appear in each codeunit. The tests that Appendix C marks manual (24, 30, 34, 37 as a screen check, 42) are in `docs/4-prove/HumanUnitTestScript.md` section 3a, not here. Codeunit 92837 is declared with `EventSubscriberInstance = Manual` (the compiler requires it for a test codeunit that holds an event subscriber), and `TestLinkedSyncFailureKeeps` binds the codeunit to itself only for the duration of that one test; all other tests in it run unbound. The Sync tests change and restore Marketing Setup (§2).

A method whose job is to prove that something is *refused* still shows **Success** when the refusal
happens as designed; the test catches the error itself. **Failure** always means the extension did
something the design did not intend — or that §2 (a company named TEST, run as SUPER) was not followed.
Every test prepares its own data and cleans up, so "none" in the last column means nothing beyond §2 and §4.

## 7. Run the tests one at a time

Running one method at a time is the whole point of this guide: a single failure then points at a single
line of this table, and the agent gets a precise report.

For each row of §6, in order:

1. Do what the row's **Setup it needs first** column says, if anything.
2. Click the line of that test method in the AL Test Tool so it is the active line.
3. Choose **Run Tests**, then **Active Line** in the prompt that appears (the choices are **All**,
   **Active Codeunit**, **Active Line**). Only that method runs.
4. Read the **Result** column on that line: **Success**, **Failure**, or **Skipped**. **Duration** shows how
   long it took.
5. **On Failure, open the Error Message.** Click the **Error Message** cell on that line: it holds the
   full message and the call stack. Copy the whole text — the first line names what the test expected and
   what it got (for example `Validation result. Expected: Confirmed. Actual: Error.`); the stack below it names the method and line in the extension
   where it happened.
6. Record the row's result in §9 before moving to the next row. A failed test does not stop you from
   running the rest; run them all, then report once.

**Watch for these first-run signs and report them word for word:**
- A failure whose text mentions a **write transaction**, or says `Codeunit.Run` is not allowed (rows 2, 19, 20 and the rows of codeunit 92834 that accept a suggestion are the likely ones). This is the open question about how the test runner isolates tests (Code Review T-04). **Do not change the test runner yourself**; report it.
- The error *Run them only in a test company whose name contains TEST* means §2 was not followed: switch company and run again.
- A failure on row 53 that mentions the **Privacy Notice** page or the action **Reject**: the never-tried handler (§2). Report it; do not retry on a different user.

The totals at the bottom of the page — **Successful Tests**, **Failed Tests**, **Skipped Tests**,
**Tests not Executed** — count every line in the suite, so they only mean something once every row has
been run.

**To run everything in one go** (a second pass after fixes, for instance): choose **Run Tests → All**,
or tick **Run** only on the lines you want and choose **Run Selected Tests**. Results land in the same
columns.

## 8. Reading the result, and what to send the agent

| Result | Meaning | Send the agent |
|---|---|---|
| **Success** | The method ran and every check in it held | Nothing but the row number |
| **Failure** | A check did not hold, or the code raised an error the test did not expect | The row number, the full **Error Message** text, and anything you did differently from §2 and §6 |
| **Skipped** | The method was not run | The row number and the Error Message text if there is one |
| Empty | The line has not been run yet | — |

The agent diagnoses from the message and the stack, fixes the extension (or the test, when the test was
wrong), and builds new packages — both the extension and the test app, at a higher version. You then
repeat §4 (install the new versions), **Manage Tests → Update Test Methods**, and §7 for the rows that
failed, then one full pass of everything before the step closes. **A failing test is a defect** in this
framework, the same as a compiler error: the step does not close with a Failure on the page.

## 9. Results of this pass

| Date | Tester | Sandbox | Extension version | Test app version | Rows passed | Rows failed (numbers) | Notes |
|---|---|---|---|---|---|---|---|
| | | | 1.3.0.0 | 0.0.0.24 | | | |

**Run order for the first pass of 1.2:** rows 1 to 61 first (they must pass; rows 16, 17 and 46 expect the new texts), then rows 62 to 115 (`codeunit 92836`), then rows 116 to 134 (`codeunit 92837`), then rows 135 to 155 (`codeunit 92838`). After a failure in the Source or Sync tests, do the hand check of §2 (leftover `GAVUT*` records, Marketing Setup, Company Information and General Ledger Setup) before running more tests.

## 10. Before copying this sandbox anywhere

Uninstall the test app (**Extension Management → select `Google Address Validator Tests` → Uninstall**) before a
sandbox is copied to production or handed to users: test codeunits have no business in a production
environment, and Microsoft refuses to run them there anyway. The three library apps and Test Runner can
stay; they do nothing on their own. Also check the **Privacy Notices** page (§2) and re-enter the real Google Maps API key in any company the tests ran in.

## Sources (read October 15, 2026)

- *Testing the application overview* (sandbox rules, limits) — <https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testing-application>
- *Test the advanced sample extension* (Test Tool walkthrough, error message and call stack) — <https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-extension-advanced-example-test>
- *Install and uninstall apps* (Extension Management, marketplace) — <https://learn.microsoft.com/en-us/dynamics365/business-central/ui-extensions-install-uninstall>
- The **AL Test Tool** page and the **Test Runner**, **Any**, **Library Assert**, and **Library Variable Storage** apps, with their IDs and the page's exact captions and actions — Microsoft's BCApps repository, `src/Tools/Test Framework/` — <https://github.com/microsoft/BCApps/tree/main/src/Tools/Test%20Framework>
- *Manage Marketplace apps* (the Microsoft Marketplace Apps page) — <https://learn.microsoft.com/en-us/dynamics365/business-central/admin-manage-appsource-apps>
- Availability of the test framework apps in online sandboxes (Test Runner from the marketplace since 17.2; Tests-TestLibraries never; the three libraries by App ID, as practitioners report — no Microsoft page confirms it) — Freddy Kristiansen, *Running tests in Business Central Online Sandbox environments* (February 2021) — <https://freddysblog.com/2021/02/15/running-tests-in-business-central-online-sandbox-environments/>
