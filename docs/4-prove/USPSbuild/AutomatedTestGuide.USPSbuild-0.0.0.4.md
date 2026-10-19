# Running the automated tests for USPS Address Validator

**The agent does not upload or run anything in Business Central unless a developer explicitly asks it to.** It writes the tests and this guide; a
person installs the test app and runs the tests in a sandbox, then reports what the page showed. Plan on
twenty minutes the first time (installing the test framework is most of it) and five minutes after that.

> **Status:** these 34 tests have been written and compiled but **never run**. Expect that a few fail the first time because of the tests, not the extension; report each one exactly as §8 says. `docs/4-prove/AutomatedTestScripts.md` says *what* the tests are and what they leave out; this guide says how to run them. Both are revised every time the tests change.

## 1. What you are installing

| | |
|---|---|
| The extension under test | `outputAppPackage/USPS_Address_Validator_0.0.0.4.app` (install it first, by `docs/4-prove/SandboxInstall.md`) |
| The test app | `outputAppPackage/USPS_Address_Validator_Tests_0.0.0.3.app` **in the sibling folder** `USPSAddressValidator.Tests` (full path `/Users/ajansari/Documents/AL/USPSAddressValidator.Tests/outputAppPackage/`). It is a separate extension called **USPS Address Validator Tests**, publisher OnlyBCFans, whose only job is to test the one above. It requires the main app **0.0.0.4** and is never installed in production |
| Test codeunits in the test app | 3 codeunits (60125, 60126, 60127), 34 test methods, listed in §6. (Two more codeunits, 60123 and 60124, are helpers; they hold no tests and do not appear on the AL Test Tool page.) |
| Test framework apps the test app needs | **Test Runner** (for the page). The three libraries **Library Assert**, **Any**, **Library Variable Storage** are listed in §3 because the framework installs them as standard; this test app's own `app.json` does not list them as dependencies (it has its own checking code), so if one of the three is not offered, carry on and tell the agent |
| The page you run tests from | **AL Test Tool** (page 130451), which comes with Microsoft's **Test Runner** app (§3) |
| Sandbox | `sandbox` (a SaaS sandbox; the test app refuses to work anywhere else), company **TEST USPS** or any company whose name contains **TEST** |

## 2. Before you start

- **A sandbox only.** Microsoft allows automated tests in online sandboxes and forbids them in production.
  Two limits apply in a sandbox: no single test method may run longer than fifteen minutes, and Microsoft
  recommends not running tests for more than one or two hours a day.
- **The permission to install extensions** (§2 of `SandboxInstall.md`): Admin Center access, the
  **D365 Extension MGT** user group, or the **EXTEND. MGT. - ADMIN** permission set.
- **Run as a user with SUPER (all permissions).** The tests change the privacy-notice approval and the USPS setup.
- **A company named with TEST, nothing else.** The tests **overwrite and delete the USPS setup, the stored Consumer Key and Secret and the cached token of the company they run in**, and delete every customer whose number starts with `USPSUT`. The first test that runs in a company whose name does **not** contain the letters **TEST** stops with the error *These tests overwrite and delete the USPS setup and credentials. Run them only in a test company whose name contains TEST.* Use the company `TEST USPS`, create one (search **Companies**), never a company with real data. After the tests, enter the real USPS credentials again in that company if you need them (the tests cannot restore them).
- **The tests record organization-wide consent while they run.** To pass the privacy check, the test setup sets the USPS privacy notice (`OBCFUSPS-ADDRESS`, *USPS Address Validation*) to **Agreed for the whole organization** and puts the earlier state back when each test cleans up (Code Review T-05). Do not run the tests in an environment where agreement to that notice must stay exactly as it is; if a run is stopped half-way, check the **Privacy Notices** page afterwards.
- **One test uses a part never tried.** `TestPrivacyRefusedSendsNothing` (row 26) clicks **Disagree** on Business Central's own **Privacy Notice** page through a test handler that has never been run. If it fails, report it as usual; it may be the test, not the extension.
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

1. Install `outputAppPackage/USPS_Address_Validator_0.0.0.4.app` by `docs/4-prove/SandboxInstall.md`, if it is
   not already installed at that exact version. (A test app is built against one version of the
   extension; a different version installed is the most common reason the test app refuses to install.)
2. Install `USPS_Address_Validator_Tests_0.0.0.3.app` from the sibling folder (`/Users/ajansari/Documents/AL/USPSAddressValidator.Tests/outputAppPackage/`) the same way — same route, same steps,
   **Schema Sync Mode = Add** (the test app has no tables of its own).
3. On **Extension Management**, confirm both are **Installed**: **USPS Address Validator** at **0.0.0.4** and **USPS Address Validator Tests** at **0.0.0.3**.
4. Make sure your user has a company named with **TEST** selected (top of the screen).

## 5. Open the AL Test Tool and load the tests

1. Choose the **Search for Page or Report** icon, type **AL Test Tool**, and open it. (It is page
   **130451**. If the search finds nothing, the **Test Runner** app from §3 is not installed.)
2. The page opens on a test suite called **DEFAULT** (the **Suite Name** field at the top). Leave it.
3. Choose **Manage Tests**, then **Get Test Codeunits**. A list of every test codeunit installed in the
   environment opens.
4. Select the codeunits from §6 — `60125 obcfusps Validation Tests`, `60126 obcfusps API Client Tests`, `60127 obcfusps Addr Validated Tests` — and choose **OK**. One line per
   codeunit appears, each followed by one line per test method; the **Line Type** column says which is
   which, **Codeunit ID** and **Name** say what they are. You should end with 3 codeunit lines and 34 method lines.
5. Every line has its **Run** checkbox ticked. Leave them ticked; the one-at-a-time procedure in §7
   does not depend on them.

The list stays on the page between sessions. After a new build of the test app, choose
**Manage Tests → Update Test Methods** so the lines match the new code.

## 6. What each test checks

One row per test method. Run them in this order the first time; later, run only what a fix touched.

| # | Codeunit (ID · name) | Test method | What it checks | Expected result | Setup it needs first |
|---|---|---|---|---|---|
| 1 | `60125 · obcfusps Validation Tests` | `TestMatchingAddressIsConfirmed` | An address USPS says is identical is confirmed without a dialog, the customer is flagged Address Validated, and a Confirmed log row is written. | **Success** | none |
| 2 | `60125 · obcfusps Validation Tests` | `TestAcceptedUpdatesCustomer` | Accepting a USPS suggestion writes the five USPS values (ZIP as 62701-1234) to the customer and logs Suggestion Accepted with both addresses. | **Success** | none |
| 3 | `60125 · obcfusps Validation Tests` | `TestIgnoredLoggedEachTime` | Cancelling the comparison dialog twice leaves the customer unchanged and writes two Suggestion Ignored log rows. | **Success** | none |
| 4 | `60125 · obcfusps Validation Tests` | `TestNotFoundReportedAndLogged` | When USPS cannot find an address the user gets the not-found message with the USPS reason and a Not Found log row is written. | **Success** | none |
| 5 | `60125 · obcfusps Validation Tests` | `TestDeliveryWarningThenAccept` | A missing suite or apartment number (code D) shows the warning in the dialog, and Accept still works. | **Success** | none |
| 6 | `60125 · obcfusps Validation Tests` | `TestLetterCaseConfirmed` | An address that differs only in upper/lower case counts as confirmed, with no dialog and no change to the customer. | **Success** | none |
| 7 | `60125 · obcfusps Validation Tests` | `TestNonUSRefusedNoCall` | A customer in another country is refused with the US-only message, nothing is sent to USPS and nothing is logged. | **Success** | none |
| 8 | `60125 · obcfusps Validation Tests` | `TestPreconditionsBlockTheCall` | Disabled setup, an empty address and a state written out in full are each refused with the right message, nothing is sent and nothing is logged. | **Success** | none |
| 9 | `60125 · obcfusps Validation Tests` | `TestTooLongBlocksAccept` | If USPS returns a city longer than the customer field, Accept is blocked with the reason, the customer is unchanged, and the check is logged as Suggestion Ignored. | **Success** | none |
| 10 | `60125 · obcfusps Validation Tests` | `TestChangedDuringDialog` | If the customer's address is changed while the dialog is open, Accept writes nothing, shows the address-changed message and logs Suggestion Ignored. | **Success** | none |
| 11 | `60125 · obcfusps Validation Tests` | `TestFailedWriteLogged` | If saving the customer fails after USPS answered, the customer stays unchanged and the failure is logged as Error with the failure text. | **Success** | none |
| 12 | `60126 · obcfusps API Client Tests` | `TestRejectedCredsLogged` | Credentials rejected by USPS give the credentials message and an Error log row with HTTP status 401, and no address call is made. | **Success** | none |
| 13 | `60126 · obcfusps API Client Tests` | `TestQuotaNoRetry` | The hourly-limit answer (429) gives the limit message, an Error log row, and exactly one address call (no retry). | **Success** | none |
| 14 | `60126 · obcfusps API Client Tests` | `TestNoResponseNoRetry` | No answer from USPS gives the not-responding message, an Error log row with HTTP status 0, and exactly one address call. | **Success** | none |
| 15 | `60126 · obcfusps API Client Tests` | `TestTokenReusedNextCheck` | Two checks in a row ask USPS for a token only once. | **Success** | none |
| 16 | `60126 · obcfusps API Client Tests` | `TestCachedTokenRejectedRetry` | A stored token that USPS rejects is replaced once and the address call is repeated once, and the check then succeeds. | **Success** | none |
| 17 | `60126 · obcfusps API Client Tests` | `TestRequestUrlHasAddressOnly` | The request sent to USPS carries the state, ZIP Code, ZIP+4 and street, leaves out a blank second address line, and never contains the customer's name or number. | **Success** | none |
| 18 | `60126 · obcfusps API Client Tests` | `TestTokenNoResponseLogged` | No answer to the token request gives the not-responding message and an Error log row, and no address call is made. | **Success** | none |
| 19 | `60126 · obcfusps API Client Tests` | `TestBadRequestShowsUSPSText` | A USPS 'bad request' answer shows the user USPS's own text and logs it as Error with HTTP status 400. | **Success** | none |
| 20 | `60126 · obcfusps API Client Tests` | `TestServerErrorLogged` | A USPS server error (503) gives the not-responding message and an Error log row with HTTP status 503. | **Success** | none |
| 21 | `60126 · obcfusps API Client Tests` | `TestUnreadableAddressResponse` | An answer that is not readable gives the unexpected-response message, an Error log row, and the customer is not marked validated. | **Success** | none |
| 22 | `60126 · obcfusps API Client Tests` | `TestTokenWithoutAccessToken` | A token answer without a token gives the unexpected-response message and an Error log row, and no address call is made. | **Success** | none |
| 23 | `60126 · obcfusps API Client Tests` | `TestPostCodeMustBeZipLike` | A Post Code that is not ZIP-like (ABCDE) with no city and state is refused as an incomplete address, nothing is sent. | **Success** | none |
| 24 | `60126 · obcfusps API Client Tests` | `TestConnectionSucceeds` | Test Connection reports success when USPS returns a token, using one token call and no address call. | **Success** | none |
| 25 | `60126 · obcfusps API Client Tests` | `TestConnectionFails` | Test Connection reports the credentials-rejected text when USPS refuses the credentials. | **Success** | none |
| 26 | `60126 · obcfusps API Client Tests` | `TestPrivacyRefusedSendsNothing` | If the privacy notice is disagreed, nothing is sent to USPS, nothing is logged and the privacy message is shown. Uses a modal handler on the page Privacy Notice that has never been tried. | **Success** | none |
| 27 | `60127 · obcfusps Addr Validated Tests` | `TestAcceptSetsFlagFromFalse` | Accepting a suggestion sets Address Validated from No to Yes. | **Success** | none |
| 28 | `60127 · obcfusps Addr Validated Tests` | `TestConfirmedSetsFlag` | A confirmed address sets Address Validated to Yes and leaves the address fields alone. | **Success** | none |
| 29 | `60127 · obcfusps Addr Validated Tests` | `TestCancelLeavesFlagUnchanged` | Cancelling the dialog leaves Address Validated unchanged, whether it was No or Yes. | **Success** | none |
| 30 | `60127 · obcfusps Addr Validated Tests` | `TestEditingAddressResetsFlag` | Editing the city of a validated customer resets Address Validated to No. | **Success** | none |
| 31 | `60127 · obcfusps Addr Validated Tests` | `TestAcceptKeepsFlagTrue` | Accepting a suggestion on an already validated customer leaves Address Validated at Yes (Accept is not counted as an edit). | **Success** | none |
| 32 | `60127 · obcfusps Addr Validated Tests` | `TestNewCustomerIsNotValidated` | A new customer starts with Address Validated = No. | **Success** | none |
| 33 | `60127 · obcfusps Addr Validated Tests` | `TestNotFoundClearsFlag` | An address USPS cannot find resets Address Validated to No on a validated customer. | **Success** | none |
| 34 | `60127 · obcfusps Addr Validated Tests` | `TestErrorKeepsFlag` | A USPS error (hourly limit) leaves Address Validated unchanged. | **Success** | none |

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

**Watch for these two first-run signs and report them word for word:**
- A failure whose text mentions a **write transaction** or says `Codeunit.Run` is not allowed (rows 2, 10, 11 and the rows of 60127 that accept a suggestion are the likely ones). This is the open question about how the test runner isolates tests (Code Review T-04). **Do not change the test runner yourself;** report the row numbers and the text.
- The error *Run them only in a test company whose name contains TEST* means §2 was not followed: switch company and run again.

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
| | | | 0.0.0.4 | 0.0.0.3 | | | |

## 10. Before copying this sandbox anywhere

Uninstall the test app (**Extension Management → select `USPS Address Validator Tests` → Uninstall**) before a
sandbox is copied to production or handed to users: test codeunits have no business in a production
environment, and Microsoft refuses to run them there anyway. The three library apps and Test Runner can
stay; they do nothing on their own. Also check the **Privacy Notices** page (§2) and re-enter the real USPS credentials in any company the tests ran in.

## Sources (read October 15, 2026)

- *Testing the application overview* (sandbox rules, limits) — <https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testing-application>
- *Test the advanced sample extension* (Test Tool walkthrough, error message and call stack) — <https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-extension-advanced-example-test>
- *Install and uninstall apps* (Extension Management, marketplace) — <https://learn.microsoft.com/en-us/dynamics365/business-central/ui-extensions-install-uninstall>
- The **AL Test Tool** page and the **Test Runner**, **Any**, **Library Assert**, and **Library Variable Storage** apps, with their IDs and the page's exact captions and actions — Microsoft's BCApps repository, `src/Tools/Test Framework/` — <https://github.com/microsoft/BCApps/tree/main/src/Tools/Test%20Framework>
- *Manage Marketplace apps* (the Microsoft Marketplace Apps page) — <https://learn.microsoft.com/en-us/dynamics365/business-central/admin-manage-appsource-apps>
- Availability of the test framework apps in online sandboxes (Test Runner from the marketplace since 17.2; Tests-TestLibraries never; the three libraries by App ID, as practitioners report — no Microsoft page confirms it) — Freddy Kristiansen, *Running tests in Business Central Online Sandbox environments* (February 2021) — <https://freddysblog.com/2021/02/15/running-tests-in-business-central-online-sandbox-environments/>
