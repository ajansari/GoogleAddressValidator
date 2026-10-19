# Automated Test Scripts — USPS Address Validator

**Kind created:** AL Test Framework (native) test codeunits, in a separate test app. No API-level automation (the extension has no API endpoints). · **Date:** 2026-10-16
**Test app:** `USPS Address Validator Tests` 0.0.0.3 (`/Users/ajansari/Documents/AL/USPSAddressValidator.Tests`, package `outputAppPackage/USPS_Address_Validator_Tests_0.0.0.3.app` in that folder), object IDs 60123-60127, depends on main app 0.0.0.4. How a person installs and runs them: `docs/4-prove/AutomatedTestGuide.md`.
**Status: 34 test procedures, written and compiled (0 errors, 0 warnings), never run.** Nothing has been installed in a tenant yet (Gap Analysis G15).

How they work: USPS is never called. The tests replace the web layer with a fake (`obcfusps Fake USPS Transport`, 60123) that returns queued token and address answers and counts calls. Each test starts with `Prepare()` (clean up leftovers, reset the fake, write a test setup with made-up credentials, approve the privacy notice) and ends with `CleanUp()`. Test customers are numbered `USPSUT1`, `USPSUT2`, … and are deleted at the end. Messages are checked against copies of the main app's label texts, so a changed label fails the test.

## 1. What each test covers

Codeunit 60125 `obcfusps Validation Tests`:
| # | Procedure | Covers | Asserts | Deliberately does not cover |
|---|---|---|---|---|
| 1 | `TestMatchingAddressIsConfirmed` | FRD test 1 | Returns true; outcome Confirmed; user message is the confirmed text; log row Confirmed, Accepted = No | That the message box appears on screen (the test calls the testable procedure, not the action) |
| 2 | `TestAcceptedUpdatesCustomer` | FRD test 2 | Dialog accepted: customer holds the five USPS values (ZIP `62701-1234`), Address Validated Yes, log Suggestion Accepted with Accepted = Yes, original and USPS addresses stored | Bold changed values (cannot be seen from AL), Contact sync |
| 3 | `TestIgnoredLoggedEachTime` | FRD test 3 | Cancel twice: two Suggestion Ignored rows, customer unchanged | Esc and the X button (the test presses Cancel); see HumanUnitTestScript TC-06 |
| 4 | `TestNotFoundReportedAndLogged` | FRD test 4 | HTTP 404: outcome Not Found, text `USPS could not find this address: Address not found.`, log Not Found with the USPS message | The live USPS wording |
| 5 | `TestDeliveryWarningThenAccept` | FRD test 5 | Delivery-point code D: dialog shows `The suite or apartment number is missing.`; Accept still works | Codes S and N, vacant and business notes |
| 6 | `TestLetterCaseConfirmed` | FRD test 6 | Lower-case values: Confirmed, no dialog, log Confirmed, fields unchanged | Other whitespace variations |
| 7 | `TestNonUSRefusedNoCall` | FRD test 7 | Country CA: returns false, US-only text, 0 token and 0 address calls, no log row | Blank country (counts as US) |
| 8 | `TestPreconditionsBlockTheCall` | TDD test A6 | Setup disabled, empty address, State `Illinois`: the right message each time, 0 calls, no log row | No credentials; privacy notice (own test in 60126) |
| 9 | `TestTooLongBlocksAccept` | TDD test A1 | USPS City over 30 characters: dialog shows the blocked-accept reason, outcome Suggestion Ignored, customer unchanged, log Ignored, Accepted = No | Other fields too long (only City) |
| 10 | `TestChangedDuringDialog` | TDD test A2 | Customer City edited and committed inside the dialog handler, then OK: outcome Suggestion Ignored, address-changed text, customer keeps the other user's edit, flag false, log Ignored | A truly second user session (see TC-24 in the manual script); depends on Commit working under the test runner (risk R2) |
| 11 | `TestFailedWriteLogged` | TDD test A7 | A test subscriber makes the customer modify fail: returns false, outcome Error, log Error with the failure text, customer unchanged | Real-world write failures (Contact update, other extensions) |

Codeunit 60126 `obcfusps API Client Tests`:
| # | Procedure | Covers | Asserts | Deliberately does not cover |
|---|---|---|---|---|
| 12 | `TestRejectedCredsLogged` | FRD test 8 | Token 401: credentials-rejected text, log Error HTTP 401, 1 token call, 0 address calls | 403 on the token call |
| 13 | `TestQuotaNoRetry` | FRD test 9 (a) | Address 429: quota text, log Error HTTP 429, exactly 1 address call (no retry) | Other `Retry-After` handling (none exists) |
| 14 | `TestNoResponseNoRetry` | FRD test 9 (b) | Address call with no response: not-responding text, log Error HTTP 0, 1 address call | Real timeouts and the Timeout setting |
| 15 | `TestTokenReusedNextCheck` | FRD test 10 | Two checks: 1 token call, 2 address calls | Token expiry timing (60 seconds before) |
| 16 | `TestCachedTokenRejectedRetry` | TDD test A5 | Cached token rejected with 401: one refresh and one retry; 1 token call and 2 address calls in the second check | A second refresh (not allowed by design) |
| 17 | `TestRequestUrlHasAddressOnly` | TDD §4.12, T-02 (a) | Request URL holds `state=IL` (upper-cased), `ZIPCode=62701`, `ZIPPlus4=1234`, `streetAddress=`; no `secondaryAddress=` when blank; the customer name and number never appear | Encoding of special characters |
| 18 | `TestTokenNoResponseLogged` | T-02 (b) | Token call with no response: not-responding text, log Error HTTP 0, 1 token call, 0 address calls | |
| 19 | `TestBadRequestShowsUSPSText` | T-02 (c) | Address 400: `USPS could not read the address: Address is invalid.`, log Error with USPS message and HTTP 400 | |
| 20 | `TestServerErrorLogged` | T-02 (d) | Address 503: not-responding text, log Error HTTP 503, 1 address call | Other 5xx codes |
| 21 | `TestUnreadableAddressResponse` | T-02 (e) | Address 200 with text that is not JSON: unexpected-response text, log Error HTTP 200, flag unchanged | JSON without an `address` object |
| 22 | `TestTokenWithoutAccessToken` | T-02 (f) | Token 200 with `{}`: unexpected-response text, log Error, 1 token call, 0 address calls | |
| 23 | `TestPostCodeMustBeZipLike` | CR9-08 | Post Code `ABCDE` and no city or state: address-incomplete text, no log, 0 calls | |
| 24 | `TestConnectionSucceeds` | FRD test 14 (logic only) | Test Connection logic with a token 200: true, empty error text, 1 token call, no address call | The setup page, the masked fields, the real USPS answer |
| 25 | `TestConnectionFails` | FRD test 14 (logic only) | Token 401: false, error text contains the credentials-rejected text | |
| 26 | `TestPrivacyRefusedSendsNothing` | Code Review CR9-04 | Privacy notice set to Disagreed: nothing is sent (0 calls), no log row, flag unchanged, the privacy text returned | Agree path (every other test runs with Agreed); the Test Connection privacy check |

Codeunit 60127 `obcfusps Addr Validated Tests`:
| # | Procedure | Covers | Asserts | Deliberately does not cover |
|---|---|---|---|---|
| 27 | `TestAcceptSetsFlagFromFalse` | FRD test 15 | Accept on a customer with Address Validated No: outcome Accepted, flag Yes | |
| 28 | `TestConfirmedSetsFlag` | FRD test 16 | Confirmed: flag Yes, address fields unchanged | Users who cannot modify customers (manual TC-23) |
| 29 | `TestCancelLeavesFlagUnchanged` | FRD test 17 | Cancel from No and from Yes: flag unchanged in both, addresses unchanged | Esc |
| 30 | `TestEditingAddressResetsFlag` | FRD test 18 | Flag Yes, `Validate(City)`: flag No before the save, still No after `Modify(true)` | Country/Region edits; imports that skip validation (known limitation) |
| 31 | `TestAcceptKeepsFlagTrue` | FRD test 18, second part | Accept on a customer already Yes: flag stays Yes (Accept is not counted as an edit) | |
| 32 | `TestNewCustomerIsNotValidated` | FRD test 20 | New customer: flag No | |
| 33 | `TestNotFoundClearsFlag` | TDD test A3 | Not Found on a validated customer (user can modify): flag No | Users who cannot modify customers |
| 34 | `TestErrorKeepsFlag` | TDD test A4 | Address 429 on a validated customer: flag stays Yes | |

Codeunit 60124 `obcfusps Test Library` (setup, clean-up, builders, asserts) and 60123 `obcfusps Fake USPS Transport` hold no tests.

**Not covered by any automated test** (all in `docs/4-prove/HumanUnitTestScript.md`): FRD tests 11-14 (time zones, no permission to modify, unsaved edit, the setup page), 19 (card layout), 21 (the wizard); bold values; Esc; Contact sync; the log page; permission sets; customer rename; the privacy-notice Agree path; all live USPS behaviour. **Known untested code paths:** Gap G3 (a 200 answer with blank address fields; no test, because the fix is scheduled with CR-1), G2/G4 (public codeunits), the "Allow HttpClient Requests off" path (G5; sandbox only).

## 2. Maintenance commitment
These tests copy the main app's message texts and call its internal seams (`SetTransport`, `Writer`), so any change to a label, a precondition, a log field or the caller check has to be made in the tests in the same change, and both packages are rebuilt at the next version, with the test app's dependency raised to the new main version. This document and `docs/4-prove/AutomatedTestGuide.md` §6 are revised every time a test is added, renamed or removed; if CR-1 (the Google provider) goes ahead, nearly every one of these tests changes with it.

## 3. Known risks
1. **Untried under the AL Test Tool.** The 34 tests compile but nobody has run them. Expect first-run failures that are test faults, not product faults, and budget a fix round (Gap Analysis G15).
2. **T-04, isolation and `Commit()`.** The production code calls `Commit()` before the write phase and runs the writer with `Codeunit.Run`; the test dialog handler in `TestChangedDuringDialog` also commits. Whether the AL Test Tool's runner isolation lets these commits work is unknown (TDD §13.9 item 5, Code Review T-01 and T-04). If writer tests fail with a platform message about write transactions, the first suspect is the test runner's isolation, not the extension.
3. **SaaS sandbox only.** The extension's caller check lets the test app call the test seams only when the environment is a sandbox (`IsSandbox()`), so the tests cannot run in production, in a Docker container that does not report itself as a sandbox, or on-premises (FRD OQ-17, decided).
4. **Only in a company whose name contains TEST.** `InitSetup` stops with an error in any other company, because the tests overwrite and delete that company's USPS setup, credentials and cached token, and delete all customers numbered `USPSUT*`. The credentials are not restored (they are per app and unreadable from the test app); re-enter the real ones afterwards.
5. **Organization-wide privacy consent while tests run.** The test setup sets the privacy notice `OBCFUSPS-ADDRESS` to Agreed for everyone and restores the earlier state in the clean-up (Code Review T-05). If a run is interrupted, the state may stay Agreed.
6. **One modal handler never tried.** `TestPrivacyRefusedSendsNothing` uses a modal handler on the platform page "Privacy Notice" and its `Reject` action; whether that page, and that action name, behave as assumed under test is unproven.
7. **Run as SUPER.** Changing the privacy approval state and the test setup need a user with broad permissions; run as a SUPER user in the sandbox.
