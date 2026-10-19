# Human Unit Test Script — Google Address Validator

**Version under test:** 1.3.0.0 (release candidate; the same behaviour as 1.2.0.4, which passed this script manually on 2026-10-19; 1.3.0.0 renumbers the objects and fields, so repeat the cases that touch stored data and the upgrade) for the cases in section 3a (TC-30 to TC-44, written for 1.1.x) and section 3b (TC-45 to TC-56, version 1.2: TC-45 to TC-52 for SC-4, TC-53 to TC-56 for SC-5 and SC-5a); TC-01 to TC-29 were written for 0.0.0.7 and passed on it (1.0.0.0 smoke-tested), and are re-run on 1.1.x and 1.2.x only where sections 3a and 3b say so, plus TC-18 to TC-20 whose expected texts changed in 1.2 · **Package:** `outputAppPackage/Google_Address_Validator_1.2.0.4.app` · **Environment:** SaaS sandbox, test company (name contains TEST) · **Date:** ______________
**Tester name:** ______________________ · **Tester role (Administrator / User / Read-only):** ______________________ · **Date finished:** ______________
**Written for:** a tester who is not a developer. Every step says what to click and what must appear. This script replaces the USPS-build script (kept at `docs/4-prove/USPSbuild/HumanUnitTestScript.USPSbuild-0.0.0.4.md`); nothing in it was run against Google yet.

> **This extension has no API endpoints.** It adds one action to the Customer Card, a setup card, an Assisted Setup wizard and a read-only log. So the usual green-team (it works) / red-team (it fails safely) checklist for an API is adapted here to the Customer Card flow. Every case says which part of the Functional Requirements Document (FRD 2.0 §7.2 acceptance tests 1–23, or an FR) it covers. FRD tests 1–10, 15–18, 20 and 22 are also run automatically by the test app (`docs/4-prove/AutomatedTestGuide.md`); this script covers what a person must see, plus the live Google behaviour.

> **Read this first: live Google cases, and the real-address rule.**
> - A case marked **Needs live Google: Yes** sends a real request to Google Maps Platform and needs a **real API key** from a Google Cloud project with billing and the Address Validation API enabled (`docs/4-prove/Deployment.md`). A case marked **No** works without a real key.
> - **Use real addresses only for any case that reaches Google.** Google's terms forbid sending made-up US addresses to the live service (FRD §5, §7.1); a violation can cost the project its USPS validation. The sample addresses below are real, publicly known addresses and are examples only; they were not checked against the live service. If you prefer, use any real US address you are sure of, but misspell the street or leave off the ZIP+4 where the case says so. **Never invent an address for a case marked Yes.**
> - If you have no real key or cannot run a live case, write **Blocked - no live Google** (and the reason) in the Pass / Fail column and the date in Notes. **Never write Pass for a case you did not run.** Step 12 cannot be signed off on blocked live cases (FRD tests 1, 2, 4, 5 and 14 must pass once against live Google); the Dev Manager decides what to do with them.
> - Cases marked **Needs live Google: No** may use a made-up key such as `test` and made-up addresses **only where the case says the check stops before anything is sent**; cases that do reach Google with a wrong key (TC-22) still use a real address.

## 1. Setup

| # | Precondition | How to check |
|---|---|---|
| S1 | `Google_Address_Validator_1.3.0.0.app` is installed in the sandbox, by `docs/4-prove/SandboxInstall.md` (for TC-36, over a sandbox that had 1.0.0.0, see that case). | **Extension Management** (search for it): **Google Address Validator**, version **1.2.0.4**, status **Installed**. |
| S2 | You work in a **test company** whose name contains **TEST**. Never test in a company with real customers. | Top of the screen shows the company name. If not, choose the company name, then **Select Company**. |
| S3 | Three test users exist, each with the permission sets shown. **Admin tester**: `OBCFGAV GAV, ADMIN` plus the permission sets needed to edit customers and contacts (for example **D365 BASIC**, **D365 CUSTOMER, EDIT**; or SUPER). **Normal tester**: `OBCFGAV GAV, USE` plus the same customer and contact editing sets. **Read-only tester**: `OBCFGAV GAV, USE` plus read-only access to customers (for example **D365 BASIC, VIEW**), and **no** permission to modify customers. | **Users** page: open each user and read **User Permission Sets**. |
| S4 | The company is a **US** company (so the Customer Card shows **State** and **ZIP Code**). | Open a Customer Card: the Address group shows **State** and **ZIP Code** (TC-15 records what you see). |
| S5 | Test customers exist (create them with **Customers > New**; give each a Name and the address shown, leave Country/Region Code blank unless stated). See the list below. | Open **Customers** and find them. |
| S6 | The setup card is **Google Address Validation Setup** (search for it). Its state is described in each case. | See each case. |
| S7 | Two browser windows (or one normal and one private window) are available, signed in as two different users, for TC-13 and TC-24. | n/a |
| S8 | You have a **real Google Maps API key** for the live cases, restricted to the Address Validation API, in a project with billing on and a daily cap and budget alert set (`docs/4-prove/Deployment.md`). Do not paste the key anywhere but the setup card or the wizard. | n/a |
| S9 | **Allow HttpClient Requests** is **On** for the extension (TC-15 step 3 checks and records the default). | Extension Management > **Google Address Validator** > Manage > Configure. |

**Test customers** (create these in the test company; numbers are free to choose, the names below are labels used in this script):

| Label | Name | Address | City | State | ZIP Code | Country/Region | Used by |
|---|---|---|---|---|---|---|---|
| C-TYPO | Test Typo | 1600 Amphitheater Parkway | Mountain View | CA | 94043 | (blank) | TC-01, TC-04, TC-05, TC-11 (copy), TC-12, TC-24. *Example only: a real address with the street misspelled and no ZIP+4, so Google is expected to suggest the correct spelling and the +4. If Google does not suggest anything different, use another real address you are sure of, misspelled or without the +4.* |
| C-TYPO2 | Test Typo 2 | same as C-TYPO | same | same | same | (blank) | TC-06, TC-23 |
| C-ROUTE | Test Route | Amphitheatre Parkway (no house number) | Mountain View | CA | 94043 | (blank) | TC-07. *A real street without a house number; Google is expected to match only the street.* |
| C-OFFICE | Test Office | (a real office building address you know that houses many tenants, without a suite number) | (its city) | (its state) | (its ZIP) | (blank) | TC-08 (optional). *You supply this one; do not guess.* |
| C-ROOT | Test Root | 1600 Pennsylvania Avenue NW | Washington | DC | 20500 | (blank) | TC-09, TC-10, TC-11, TC-14, TC-22, TC-27 |
| C-RUSSIA | Test Russia | Tverskaya Street 1 | Moscow | (empty) | 125009 | RU (create the code **RU** under Country/Regions if it does not exist, with ISO Code `RU`) | TC-20. *Never sent to Google; Google does not cover Russia, so any text will do.* |
| C-BLANK | Test Blank | (empty) | (empty) | (empty) | (empty) | (blank) | TC-18. *Never sent.* |
| C-BADSTATE | Test Bad State | 123 Main Street | Springfield | Illinois | (empty) | (blank) | TC-19. *Never sent.* |

**Suggested order** (so that setup states build on each other): **TC-17 first**, in a fresh test company where no API key has been entered yet; then TC-02 (wizard), TC-01, TC-03; then TC-04 to TC-16 and TC-21 to TC-28 in number order. TC-25 needs the privacy notice not yet answered: do it before TC-01 if you can arrange that (TC-01 and TC-25 are two ends of the same notice).

### 1.1 Coverage of FRD 2.0 §7.2

| FRD test | Covered here by | Also automated |
|---|---|---|
| 1 Confirmed (live once) | TC-05 | Yes |
| 2 Accepted (live once) | TC-04 | Yes (bold is manual only) |
| 3 Ignored and Esc | TC-06 | Yes (Esc is manual only) |
| 4 Not found (live once) | TC-07 | Yes |
| 5 Missing suite (live once) | TC-08 (optional, needs a suitable real address) | Yes |
| 6 Letter case | not repeated by hand | Yes |
| 7 Country not covered (was Non-US; the refused country is now RU) | TC-20, TC-50 | Yes |
| 8 Wrong key | TC-22 | Yes |
| 9 Quota and timeout | not repeatable by hand (see TC-29) | Yes |
| 10 One request, no name or number | not repeatable by hand | Yes |
| 11 Time zones | TC-13 | No (manual) |
| 12 No permission to modify | TC-23 | No (manual) |
| 13 Unsaved edit | TC-11 | No (manual) |
| 14 Setup page and Test Connection (live once) | TC-03 | No (manual) |
| 15–18, 20 Address Validated rules | TC-09 (and TC-04 to TC-07) | Yes |
| 19 Address Validated on the card | TC-09 | No (manual) |
| 21 Assisted Setup wizard | TC-02 | No (manual) |
| 22 API or billing disabled (live once, spike) | TC-28 | Yes |
| 23 Attribution line | TC-04 step 1 | Yes (one test) |
| FR-9 Contact sync, GA-25 | TC-12 | No |
| GA-10 HttpClient off | TC-27 | No |
| F26 Bold values and Esc | TC-04, TC-06 | No (cannot be seen from AL) |
| **FRD 2.1 Appendix C (version 1.1)** | | |
| 24 Each card has Validate Address, the indicator and the log action | TC-30, then TC-31 to TC-34 | No (manual) |
| 25 to 29, 31 to 33, 35, 36, 38 to 41, 43 to 45 | one smoke pass per group in TC-31 to TC-34 sees them work once; the rules are tested by the automated tests (`docs/4-prove/AutomatedTestGuide.md`, rows 62 to 134) | Yes |
| 30 No modify permission on a non-customer table | TC-35 | No (manual) |
| 34 Upgrade from 1.0.0.0 in two companies, second run, fresh install | TC-36 | No (manual, Standards §9.6) |
| 37 Customer Card log shows 1.0.0.0 and 1.1 entries | TC-37 | No (manual) |
| 42 Accept on a company Contact that has a duplicate | TC-38 | No (manual, needs a client) |
| SC-2 (1.1.0.10) Google names, search terms, Record No. column | TC-43 (and the Record No. assertion in the automated tests) | Partly (`AssertLogSource`) |
| FR-18.6 (1.1.0.12) a blank country is filled in with the setup's US code on Accept and Confirmed (generalised in 1.2.0.0 to the country Google found) | TC-44, TC-49 (and `TestAcceptSetsUsCountry`, `TestConfirmedSetsUsCountry`, `TestNotFoundKeepsBlankCountry`) | Yes (Vendor, Location) |
| **SC-4 (1.2.0.x) validation in the 40 countries Google covers** | | |
| Supported Countries page, 40 rows, Enabled the only editable field | TC-45 | Partly |
| A country switched off is refused | TC-46 | Yes |
| Canada validates and keeps CA; Germany without a state; a country Google does not cover; a mismatch | TC-47, TC-48, TC-50, TC-52 | Yes (rows 135 to 149) |
| A blank country is filled in; the dialog line | TC-49, TC-51 | Yes (country), no (dialog line) |
| **SC-5 / SC-5a (1.2.0.3, 1.2.0.4) Blank Country Handling** | | |
| A Danish address with no country (default country US, Let Google decide) is found in Denmark and DK is filled in | TC-53 | Yes (`TestBlankCountryDanishAddressInferred`, rows 150 to 155) |
| A US address with a state and ZIP code and no country is checked as US, with USPS data | TC-54 | Yes (`TestBlankCountryUsShapeHintsUs`) |
| An Italian address with province MI is found in Italy after the repeat without a country | TC-55 | Yes (`TestItalianProvinceRetriesWithoutRegion`) |
| Use default country: every blank-country record is checked as the default country; a blank default sends no country | TC-56 | Yes (`TestBlankCountryUseDefaultSendsDefault`, `TestBlankCountryUseDefaultBlankDefaultSendsNoRegion`) |

## 2. Test cases — green team (it works)

### TC-01 Privacy notice — agree
**Covers:** FR-1 step 3 · **Language:** en-US · **Needs live Google:** Yes (the check that follows the notice reaches Google) · **Run as:** Admin tester
*Precondition:* setup is Enabled with a real API key (TC-02/TC-03 first), and nobody has answered the privacy notice yet in this environment. (An administrator's Agree applies to everyone; in a company where no administrator has decided on the notice, the platform may let the check pass without showing it. Write down which you saw.)
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | Open Customer **C-TYPO**. Choose **Actions > Functions > Validate Address** (it is also in the promoted **Process** group). | A **Privacy Notice** page opens before anything else happens, with a link to read the notice. Its name is **Google Address Validation**. Nothing has been sent to Google yet. | | |
| 2 | Choose **Agree**. | The notice closes and the check carries on (the suggestion dialog, or a message). | | |
| 3 | Run **Validate Address** again on the same customer. | The privacy notice does **not** appear again. | | |
| 4 | Write down the wording of the notice: does it say the data is shared with **Microsoft services**? | Expected (a known platform limitation, FRD FR-1.3): yes, it says Microsoft. Write what you read: ______ | | |

### TC-02 Assisted Setup wizard
**Covers:** FRD test 21, FR-6 · **Language:** en-US · **Needs live Google:** No · **Run as:** Admin tester
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | Search for **Assisted Setup** and open it. | The list shows **Set up Google address validation** (short title **Google address validation**) with the description **Enter the Google Maps API key used to validate addresses.** | | |
| 2 | Before you start, open **Google Address Validation Setup** and write down the values of **Enabled**, **Default Country/Region Code** and **Timeout (Seconds)**. Close it. | Values noted: ______ | | |
| 3 | In Assisted Setup choose **Set up Google address validation**. | The wizard **Set Up Google Address Validation** opens on **Welcome**. It says to enter the API key from your Google Cloud project, that Billing and the Address Validation API must be enabled for that project, and that the key is stored securely and isn't shown again. A second line says you turn the service on and test the connection on the Address Validation Setup page. **Back** is greyed out. | | |
| 4 | Choose **Next**. | The step **Google Maps API Key** shows **API Key**, masked. **Next** is greyed out while the box is empty. | | |
| 5 | Enter your API key (real for the live cases; any text such as `test` otherwise) and press Tab. | **Next** is now available. | | |
| 6 | Choose **Next**. | The step **Countries** shows **Default Country/Region Code** (blank, not preset to US on a company that never had a setup) and **Blank Country Handling** (**Let Google decide**). **Next** is available. | | |
| 7 | Type `DK` (or another country) in **Default Country/Region Code** and press Tab. | If the country is covered, no message. A country that Google does not cover, or one switched off, shows a message and is still kept. | | |
| 8 | Choose **Next**. | The step **That's it!** says **Choose Finish to save the API key and the country choices.** **Finish** is available. | | |
| 9 | Choose **Back** once, then **Next** again, then **Finish**. | The wizard closes. | | |
| 10 | Open Assisted Setup again. | The row is marked as completed. | | |
| 11 | Open **Google Address Validation Setup**. | **API Key** shows only masked characters (********). The real text is nowhere on the page. **Default Country/Region Code** is the country you chose in step 7 and **Blank Country Handling** is as chosen. **Enabled** and **Timeout (Seconds)** are exactly as you wrote them down in step 2 (the wizard does not turn the service on). | | |
| 12 | Run the wizard again from Assisted Setup. | On the **Google Maps API Key** step the field already shows masked characters and **Next** is available without typing. On the **Countries** step the saved country and handling are shown. Choose **Finish** without changing anything. | | |
| 13 | Open **Google Address Validation Setup** and choose **Test Connection** (privacy notice answered). | The saved key is still in place: the result is the same as before step 12 (the key was not blanked). | | |

### TC-03 Setup card and Test Connection
**Covers:** FRD test 14, FR-6 · **Language:** en-US · **Needs live Google:** Yes (steps 4 and 8; the rest need only an internet connection) · **Run as:** Admin tester
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | Open **Google Address Validation Setup**. | Groups **General** and **Google Maps**. **Provider** is read-only. **API Key** is masked. A note reads **Use an API key that is restricted to the Address Validation API, and set a daily quota and a budget alert in the Google Cloud console.** | | |
| 2 | Turn **Enabled** on. Leave **Default Country/Region Code** (US) and **Timeout (Seconds)** (10) as they are. | Saved without error. | | |
| 3 | Click in **API Key**, replace the masked text with your real key, press Tab. | After you press Tab the box shows masked characters again. Close and reopen the page: the key is not shown. | | |
| 4 | Choose **Test Connection** (promoted action). If the privacy notice appears, choose **Agree**. | The message **The connection to Google Maps works. The API key was accepted.** (Blocked if you have no real key: write Blocked.) | | |
| 5 | Replace the key with the text **wrong** and press Tab. Choose **Test Connection**. | An error that starts **The connection to Google Maps failed. Google Maps rejected the API key. Contact your administrator.** and normally ends with **Google message:** and Google's own text. Needs only an internet connection. Write the exact text: ______ | | |
| 6 | Put the real key back. Choose **Test Connection** once more. | Success message as in step 4. | | |
| 7 | **Billing check (the part the automated tests cannot do).** In the Google Cloud console, open the project's billing report / Address Validation metrics for the last day (billing reports can take about 24 hours to show). | Test Connection requests appear in the API metrics but **no billable Address Validation request** is attributed to them (FRD test 14, the free probe, OQ-28). If a billable SKU appears for them, write it: this is a spike finding. Result: ______ | | |
| 8 | **Test Connection with the privacy notice not agreed** (needs a company where it is not agreed; otherwise write N/A and why). | Error **The privacy notice for sending addresses to Google Maps has not been agreed to, so the connection was not tested.** | | |

### TC-04 Suggestion accepted (FRD test 2, with bold changed values and attribution)
**Covers:** FRD tests 2, 23, FR-4, FR-5, FR-8, F26 · **Language:** en-US · **Needs live Google:** **Yes** · **Run as:** Normal tester
*Precondition:* setup Enabled, real key entered, privacy notice agreed. Customer **C-TYPO** has Address Validated = No.
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | Open **C-TYPO**. Note its address fields on paper. Choose **Validate Address**. | The dialog **Suggested Address** opens: instruction text **Changed values are shown in bold. Choose OK to accept the suggested address, or Cancel to keep the current address.** Two columns: **Current (BC)** on the left (Address, Address 2, City, State, ZIP Code) and **Suggested** on the right. Directly under the grid the line **Suggestion from Google Maps**. | | |
| 2 | **Look at the right column.** (A manual check; the automated tests cannot see bold.) | Every value that is different from the left column (ignoring letter case, periods and commas) is shown in **bold**. Values that are the same are in normal type. Write which rows were bold: ______ | | |
| 3 | Look under **Delivery notes** in the dialog. | Any notes Google returned (for example spelling corrected, a missing suite warning, a business address). Write them: ______ | | |
| 4 | Choose **OK**. | The dialog closes. The Customer Card shows the suggested values exactly as Google returned them (the USPS-standardized address in upper case when Google gives one, otherwise Google's postal address). ZIP Code is written **12345-6789** when Google gave a +4, or five digits when it did not. No error. (No confirmation message is expected; write down if one appears.) | | |
| 5 | Look at **Address Validated** (Address group of the **Address & Contact** FastTab, just after **Post Code / ZIP Code**). | **Yes**. | | |
| 6 | Choose **Related > Customer > Google Address Validation Log** (the action group is called **Customer**; the action is also reachable from the Customer Card's actions menu). | One entry, newest first: **Result = Suggestion Accepted**, **Accepted = Yes**, **Original Address / City / State / ZIP Code** hold what you wrote down in step 1, **Suggested …** columns hold the new values, **Provider = Google Maps**, **User ID** is your user, **HTTP Status** 200, **Validation Granularity** PREMISE or SUB_PREMISE. | | |

### TC-05 Confirmed (FRD tests 1, 16)
**Covers:** FRD tests 1 and 16, FR-2 · **Language:** en-US · **Needs live Google:** **Yes** · **Run as:** Normal tester
*Precondition:* TC-04 done (so the customer now holds exactly what Google returned). A new ZIP+4 on a 5-digit ZIP counts as a difference, so this case only works on an address that already matches.
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | Open **C-TYPO** again and choose **Validate Address**. | **No dialog.** A message **The address is confirmed by Google Maps. No changes are needed.** (If Google also returns a delivery signal, the message ends with **Note:** and the warning text; write it.) | | |
| 2 | Choose OK/close the message. Look at the address fields. | Unchanged. **Address Validated** = **Yes**. | | |
| 3 | Open the **Google Address Validation Log** for the customer. | A new top entry **Result = Confirmed**, **Accepted = No**; the suggested columns are filled (they are kept for Confirmed). | | |

### TC-06 Suggestion ignored, then Esc (FRD tests 3, 17; F26)
**Covers:** FRD tests 3 and 17, FR-4 · **Language:** en-US · **Needs live Google:** **Yes** · **Run as:** Normal tester
*Precondition:* customer **C-TYPO2** (same typo address as C-TYPO) with Address Validated = No.
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | Open **C-TYPO2**, choose **Validate Address**. In the dialog choose **Cancel**. | Dialog closes. Address fields unchanged. **Address Validated** still **No**. | | |
| 2 | Choose **Validate Address** again. This time press **Esc** on the keyboard (a manual check; the automated tests only press Cancel). | Dialog closes. Address fields unchanged. Address Validated still **No**. | | |
| 3 | Open the **Google Address Validation Log** for this customer. | Two entries, both **Result = Suggestion Ignored**, **Accepted = No**; the suggested columns are **blank** (Google results of ignored checks are not kept). | | |
| 4 | Ignore starting from **Yes**. | Not repeatable by hand (editing the address resets the flag, and a validated address gets the Confirmed message, not the dialog). Covered by the automated test `TestCancelLeavesFlagUnchanged`. Write N/A. | n/a | |

### TC-07 Not Found (FRD test 4)
**Covers:** FRD test 4, FR-2, FR-7, FR-8 · **Language:** en-US · **Needs live Google:** **Yes** · **Run as:** Normal tester
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | Open **C-ROUTE** (a real street, no house number) and choose **Validate Address**. | A message that begins **Google Maps couldn't confirm this address.** and usually continues **Missing or unconfirmed:** with the parts Google names (for example street_number). No dialog. The address is unchanged. Write the exact text: ______ | | |
| 2 | Open the **Google Address Validation Log** for this customer. | One entry **Result = Not Found**, **Accepted = No**, **Validation Granularity** ROUTE (or OTHER), **Provider Message** holds `validationGranularity=…; possibleNextAction=…; missing=…`, suggested columns blank. | | |
| 3 | Not Found on a customer that already has Address Validated = Yes (the flag must be reset to No). | Not repeatable by hand (a validated address gets the Confirmed message, and editing it resets the flag first). Covered by the automated test `TestNotFoundClearsFlag`. Write N/A. Here, just check that **Address Validated** on **C-ROUTE** is **No**. | | |

### TC-08 Missing suite warning (FRD test 5) — optional
**Covers:** FRD test 5, FR-4 · **Language:** en-US · **Needs live Google:** **Yes**, and a suitable real address · **Run as:** Normal tester
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | Open **C-OFFICE** (a real multi-tenant office building, no suite) and choose **Validate Address**. | If Google reports the suite as missing: the dialog (or the Confirmed message) shows **The suite or apartment number is missing.** and **OK** is still available. If Google reports something else, write what it returned (this is also a spike finding, TC-30). If you have no such address, write Blocked - no suitable real address. | | |

### TC-09 Address Validated indicator (FRD tests 15–20)
**Covers:** FRD tests 15–20, FR-8 · **Language:** en-US · **Needs live Google:** No for steps 1–4, **Yes** for step 5 · **Run as:** Normal tester
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | Create a **new customer** with **Customers > New**, give it a name and an address, and look at the card without running any check. | **Address Validated** is **No**. | | |
| 2 | Find the field on the card: **Address & Contact** FastTab, **Address** group, just after the ZIP Code field. | **Address Validated** is shown there. | | |
| 3 | Click **Address Validated**. | It cannot be edited. Its tooltip reads **Specifies whether the current address was confirmed by, or accepted from, the address validation service. It is set by Validate Address and cleared when the address is edited.** | | |
| 4 | Open **Customers** (the list). | The field is only on the card, not in the list (not requested). | | |
| 5 | Open **C-TYPO** after TC-04 (flag **Yes**). Change **City** by one letter, press Tab. | **Address Validated** changes to **No** as soon as you leave the City field (or when the card saves). Changing only **Country/Region Code** does **not** reset it. | | |

### TC-10 Log page
**Covers:** FR-5 · **Language:** en-US · **Needs live Google:** No (any check that reaches Google, including a key error, writes a log row) · **Run as:** Admin tester, then Normal tester
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | Search for **Google Address Validation Log** and open it. | A list with the newest entry first (highest **Entry No.** on top). Columns include **Entry No., Source Table, Record No., Address Type, Checked At, User ID, Result, Accepted, Original Address … Original ZIP Code, Suggested Address … Suggested ZIP Code, Delivery Point Confirmation, Validation Granularity, Next Action, Provider Message, HTTP Status, Provider, Address Complete**. | | |
| 2 | Try to edit a cell, add a row, or delete a row. | Not possible; the list is read-only. | | |
| 3 | Look for any column that holds a key, secret, or web address. | None. | | |
| 4 | As **Normal tester**, try to delete an entry. | Not possible. Only administrators (ADMIN set) can delete, normally through Retention Policy. | | |
| 5 | Search for **Retention Policies**, find the **Google Address Validation Log**. | Registered, with a custom 2-year period, **disabled** (an administrator turns it on). Write what you see: ______ | | |

### TC-11 Unsaved edit is the one sent (FRD test 13)
**Covers:** FRD test 13, FR-1 step 2 · **Language:** en-US · **Needs live Google:** **Yes** (a real address is sent) · **Run as:** Normal tester
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | Open **C-ROOT** (1600 Pennsylvania Avenue NW). Change **Address** to **1600 Pennsylvania Ave NW** (a real abbreviation) and **do not** leave the card, do not press anything else. | Card shows the edit. | | |
| 2 | Immediately choose **Validate Address**. | The check starts without asking you to save (the card saves first). | | |
| 3 | When the check ends (dialog, message or error), open the **Google Address Validation Log** for **C-ROOT**. | The newest entry's **Original Address** is **1600 Pennsylvania Ave NW**. | | |

### TC-12 Contact sync after Accept (GA-25, FR-9)
**Covers:** FR-9, OQ-12, GA-25 · **Language:** en-US · **Needs live Google:** **Yes** · **Run as:** Admin tester
*Precondition:* a customer created from a contact, so a linked Contact exists (for example create a Company Contact with the C-TYPO address, then **Create as Customer**; or take a customer which has a Business Relation).
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | Note the Customer's address and the linked Contact's address (search **Contacts**, open the contact with the same name). | Both addresses noted: ______ | | |
| 2 | On the customer run **Validate Address** and **OK** (Accept). | Customer address = suggested values. | | |
| 3 | Open the linked Contact. | The Contact's address is now the suggested address too (expected by FR-9). **If it still holds the old address, that is a finding: write it in Notes and report it (GA-25, FRD §4.1 h).** | | |

### TC-13 Time zones (FRD test 11)
**Covers:** FRD test 11, FR-5 · **Language:** en-US · **Needs live Google:** No (any log row will do) · **Run as:** two users
*Precondition:* at least one log entry exists.
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | User A: choose the gear icon > **My Settings**, set **Time Zone** to Eastern time, **OK**. Open the **Google Address Validation Log** and note **Checked At** of entry ____. | Time noted: ______ | | |
| 2 | User B (second window): in **My Settings** set **Time Zone** to Pacific time. Open the same log entry. | **Checked At** is three hours earlier than User A's value for the same entry. | | |

### TC-14 Rename of a customer keeps its log rows
**Covers:** FR-5 (customer rename), Step 09 CR9-06 · **Language:** en-US · **Needs live Google:** No (an Error log row from TC-22 is enough) · **Run as:** Admin tester
*Precondition:* customer **C-ROOT** has at least one entry in its **Google Address Validation Log**. If not, run **Validate Address** on it once (any outcome that reaches Google writes a row).
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | Open **C-ROOT**'s card. Open **Related > Customer > Google Address Validation Log** and count the rows: ____ | Count noted. | | |
| 2 | Close the log. On the card change the **No.** field to a new unused number (for example add **R** at the end). Confirm the rename question. | The card shows the new number. | | |
| 3 | Open **Google Address Validation Log** from the renamed customer. | The same number of rows as in step 1. Their **Record No.** is the new number (show the hidden **Customer No.** column through Personalization if you want to check it too). | | |
| 4 | Open the unfiltered log (search **Google Address Validation Log**). | No row still shows the old number. | | |

### TC-15 Platform checks only a sandbox can answer (GA-25, OQ-19, OQ-20)
**Covers:** OQ-19, OQ-20, GA-25 · **Language:** en-US · **Needs live Google:** No · **Run as:** Admin tester
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | Open a Customer Card (US company). Look at the Address group. | The captions read **State** and **ZIP Code** (not County / Post Code). Write down what you see: ______ | | |
| 2 | Open a customer whose **Country/Region Code** is **blank**. Is the **State** field visible? | Write down: Visible / Not visible. (If it is not visible, the check still works from the ZIP Code; report it either way.) | | |
| 3 | Search for **Extension Management**, select **Google Address Validator**, choose **Manage > Configure** (or in the Admin Center: **Environments > the sandbox > Manage Apps > the extension**). Look at **Allow HttpClient Requests**. | Write down On or Off right after the install: ______. It must be **On** for the extension to work (OQ-20; it goes into the deployment guide). | | |

### TC-16 Standards §11.3 client checks, adapted to this app
**Covers:** Standards §11.1–§11.3 · **Language:** en-US · **Needs live Google:** No · **Run as:** Normal tester
**This app has no child list parts and no number series fields.** There is no list part on the card, the log cannot be added to by a user (it is read-only), and nothing is numbered by the extension. So the two standard checks reduce to this: the one parent→child entry point is the **Google Address Validation Log** action on the Customer Card (Related > Customer).
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | *Child from every parent entry point.* On a customer that already has at least one log row, choose **Related > Customer > Google Address Validation Log** (the only such action). | The log opens showing only that customer's rows, newest first; each row has **Record No.** equal to the customer's number; no banner **The view is filtered, and the entry is outside the filter**. | | |
| 2 | Run **Validate Address** (any outcome that reaches Google), then choose **Google Address Validation Log** again. | The new row is at the top of the filtered list, with the customer's number in **Record No.**; the banner never appears. | | |
| 3 | Open the unfiltered log (search **Google Address Validation Log**). | No row for a Customer has a blank **Record No.** (only Company Information rows may be blank) | | |
| 4 | *Number series.* | **N/A — this extension has no number series field, no number series on the setup card or the wizard, and creates no numbered records.** | n/a | |

## 3. Test cases — red team (it fails safely)

For every red-team case: **nothing may change on the customer and the message must be the exact text shown.** A message that is different, missing, or a raw platform error is a failure.

### TC-17 No API key
**Covers:** FR-1 step 3, FR-7 · **Needs live Google:** No · **Run as:** Admin tester, then Normal tester
*Precondition:* a test company where no API key has been entered yet (a fresh company, before TC-02). Do this case first. Once a key is saved there is no tested way to clear it from the page; if you cannot get a keyless company, write N/A and why.
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | Admin: open **Google Address Validation Setup**, turn **Enabled** on, enter nothing else. | Saved. | | |
| 2 | Normal tester: open a customer with a full address (C-ROOT; **nothing is sent**) and choose **Validate Address**. | Message **Address validation is not set up. Contact your administrator.** Log: no new row. | | |

### TC-18 Incomplete address
**Covers:** FR-1 step 3, FR-7 · **Needs live Google:** No (nothing is sent) · **Run as:** Normal tester
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | Open **C-BLANK** (all address fields empty). Choose **Validate Address**. | Message **Enter a street address and either a ZIP / postal code or a city (in the US and Canada, a city needs its state or province too).** | | |
| 2 | Open its **Google Address Validation Log**. | Empty (no row; nothing was sent). | | |
| 3 | Give **C-BLANK** Address **123 Main Street** and Post Code **ABCDE** only, run the action. | The same message (ABCDE is not ZIP-like, and there is no city). | | |

### TC-19 Bad state code
**Covers:** FR-1 step 3, FR-7 · **Needs live Google:** No (nothing is sent) · **Run as:** Normal tester
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | Open **C-BADSTATE** (State = Illinois, ZIP Code empty). Choose **Validate Address**. | Message **Enter the 2-letter state or province code in the State field.** | | |
| 2 | Open its log. | Empty. | | |

### TC-20 Country Google does not cover (FRD test 7, changed in 1.2)
**Covers:** FRD test 7 · **Needs live Google:** No (nothing is sent) · **Run as:** Normal tester
*Note:* up to 1.1.x this case used a Canadian customer and the message *Address validation works for US addresses only.* Canada is covered from 1.2, so the case uses Russia, which Google does not cover.
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | Open **C-RUSSIA** (Country/Region **RU**). Choose **Validate Address**. | Message **Google Maps can't validate addresses in (the name of RU as in your Countries/Regions, for example Russian Federation).** No dialog. | | |
| 2 | Open its log. | Empty. Nothing was sent. | | |

### TC-21 Disabled setup
**Covers:** FR-1 step 3, FR-6 · **Needs live Google:** No (nothing is sent) · **Run as:** Admin tester, then Normal tester
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | Admin: open **Google Address Validation Setup**, turn **Enabled** off. | Saved. | | |
| 2 | Normal tester: open **C-ROOT**, choose **Validate Address**. | Message **Address validation is not set up. Contact your administrator.** | | |
| 3 | Open the log for **C-ROOT**. | No new row. | | |
| 4 | Admin: turn **Enabled** back on. | Saved. | | |

### TC-22 Wrong API key (FRD test 8)
**Covers:** FRD test 8, FR-7 · **Needs live Google:** No real key; needs an internet connection; the real address **is** sent, so use C-ROOT · **Run as:** Admin tester, then Normal tester
*Precondition:* Enabled; privacy notice agreed.
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | Admin: on **Google Address Validation Setup** replace the key with `wrong-key-for-test`, press Tab. | Masked again. | | |
| 2 | Normal tester: open **C-ROOT**, choose **Validate Address**. | Message **Google Maps rejected the API key. Contact your administrator.** The address is unchanged. | | |
| 3 | Open the log for **C-ROOT**. | A new row: **Result = Error**, **HTTP Status** 400 (it may be 401 or 403; write what you see), **Provider Message** holds Google's text (for example *API key not valid*). Suggested columns blank. | | |
| 4 | If the sandbox cannot reach the internet, the message in step 2 is instead **Google Maps is not responding. Try again later.** and the HTTP Status is **0**. Write which case you saw. | | | |
| 5 | Admin: put the real key back. | Masked again. | | |

### TC-23 User without permission to modify customers (FRD test 12)
**Covers:** FRD test 12, FR-4, OQ-21 · **Needs live Google:** **Yes** · **Run as:** Read-only tester
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | Sign in as the Read-only tester. Open **C-TYPO2** (Address Validated = No). Choose **Validate Address**. | The check runs and the dialog opens. | | |
| 2 | Look under **Delivery notes** in the dialog. | A red line **You can't accept the suggested address because you don't have permission to change customers. Choose OK or Cancel to close without changes.** | | |
| 3 | Choose **OK**. | Dialog closes. The customer is unchanged. **Address Validated** unchanged. | | |
| 4 | Open the log. | One row **Result = Suggestion Ignored**, **Accepted = No**. | | |
| 5 | If you have an already matching address (like C-TYPO after TC-04): run **Validate Address** as the Read-only tester. | Message **The address is confirmed by Google Maps. No changes are needed.**, and **Address Validated** is **not** set for this user (it stays as it was). Write what you see; otherwise N/A. | | |

### TC-24 Address changed while the dialog is open
**Covers:** FR-4, TDD A2 · **Needs live Google:** **Yes** · **Run as:** two users
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | Window 1 (user A): open **C-TYPO** (reset it to the typo address first, and Address Validated No) and choose **Validate Address** so the dialog is open. **Leave it open.** | Dialog shown. | | |
| 2 | Window 2 (user B): open the same customer, change **City** to **Elsewhere**, press Tab so it saves. | Saved. | | |
| 3 | Window 1: choose **OK**. | Message **The customer's address was changed while the suggested address was open, so nothing was updated. Run Validate Address again.** | | |
| 4 | Reload the customer card in window 1. | **City** is **Elsewhere** (user B's value); the suggested values were not written. | | |
| 5 | Open the log. | A row **Suggestion Ignored**, **Accepted = No**. | | |

### TC-25 Privacy notice refused
**Covers:** FR-1 step 3, FR-7, Step 09 CR9-04 · **Needs live Google:** No (nothing is sent) · **Run as:** Admin tester (or a user who has not answered the notice)
*Precondition:* the notice is not yet agreed. (If it is, ask an administrator to reset it on the **Privacy Notices** page, or use a freshly created sandbox company; if you cannot, write N/A and why.)
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | Open **C-ROOT**, choose **Validate Address**. In the **Privacy Notice** page choose **Disagree**. | Message **The privacy notice for sending addresses to Google Maps has not been agreed to, so nothing was sent.** | | |
| 2 | Open the log. | No new row. | | |
| 3 | Open **Google Address Validation Setup** and choose **Test Connection**; Disagree again. | Error **The privacy notice for sending addresses to Google Maps has not been agreed to, so the connection was not tested.** | | |

### TC-26 Google value too long
**Covers:** FR-4 ("Accept is blocked"), TDD A1 · **Needs live Google:** **Yes** and a lucky address · **Run as:** Normal tester
**Not repeatable on demand.** It only happens if Google returns a value longer than the customer field (for example a City over 30 characters). It is covered by the automated test `TestTooLongBlocksAccept`. If you ever see the red text **You can't accept the suggested address because the suggested value for … is longer than … characters. Choose OK or Cancel to close without changes.**, choose OK and confirm the customer is unchanged and the log shows **Suggestion Ignored**; otherwise write N/A.

### TC-27 "Allow HttpClient Requests" switched off (GA-10)
**Covers:** GA-10, FR-7 · **Needs live Google:** No (the call is blocked before it leaves; use C-ROOT, a real address) · **Run as:** Admin tester · **Sandbox only**
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | Admin: **Extension Management** > select **Google Address Validator** > **Manage > Configure**. Turn **Allow HttpClient Requests** **Off**, save. | Saved. | | |
| 2 | Normal tester: open **C-ROOT**, choose **Validate Address** (setup enabled, privacy notice agreed). | **Write down the exact message.** The design expects an error message and an Error row in the log. | | |
| 3 | Open the log for **C-ROOT**. | **Is there a new row with Result = Error?** Write Yes/No. **If a message appeared but there is no new log row, report it: that is GA-10.** | | |
| 4 | Admin: turn **Allow HttpClient Requests** back **On**. | Saved. | | |

### TC-28 Google API disabled, and billing disabled (FRD test 22)
**Covers:** FRD test 22, FR-7 · **Needs live Google:** **Yes**, and a separate Google Cloud project you can break on purpose · **Run as:** Admin tester
*Precondition:* two throw-away API keys: key A from a project where the Address Validation API is **not enabled**, key B from a project where **billing is turned off**. If you cannot arrange them, write Blocked and why.
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | Enter key A on **Google Address Validation Setup**. Choose **Test Connection**. | **The connection to Google Maps failed. The Address Validation API is not enabled in the Google Cloud project of this API key. Contact your administrator.** followed by **Google message:** and Google's text. | | |
| 2 | Open **C-ROOT**, choose **Validate Address**. | Message **The Address Validation API is not enabled in the Google Cloud project of this API key. Contact your administrator.** Log row **Error**, HTTP Status 403. | | |
| 3 | Enter key B. Choose **Test Connection**, then **Validate Address** on **C-ROOT**. | **Billing is not enabled for the Google Cloud project of this API key. Contact your administrator.** (with **The connection to Google Maps failed.** in front for Test Connection). Log row **Error**, HTTP 403. | | |
| 4 | Put the real key back. | Masked. | | |

### TC-29 Request limit and timeout
**Covers:** FRD test 9 · **Needs live Google:** n/a
**N/A for a manual run** except, if you want to see it once during the spike, setting the Google quota to 1 request per day and checking twice: the second check should give **The Google Maps request limit has been reached. Try again later.** (log Error, HTTP 429). The no-response message **Google Maps is not responding. Try again later.** cannot be forced by hand. Both are covered by the automated tests `TestQuotaNoRetry` and `TestNoResponseNoRetry`. Write N/A or what you saw.

### Spike checklist — TDD §14.y (live Google; real key, real addresses only)
Tick each item or write what you saw in Notes. These are the facts the design assumed from Google's documentation (FRD OQ-33, GA-24) and the automated tests cannot prove. Report anything that differs.
| # | Item | Result / Notes |
|---|---|---|
| 1 | The `X-Goog-Api-Key` header is accepted (the checks in TC-04 to TC-07 succeed). If Google refuses it, report; the design has a fallback. | |
| 2 | For a real US address, `uspsData.standardizedAddress` is present and upper case (the Accept in TC-04 writes upper-case values). | |
| 3 | The suite lands on the first or second address line (write which, for an address with a suite). | |
| 4 | Google's `postalAddress` splits the suite and writes ZIP+4 with a dash (only visible if there is no `uspsData`). | |
| 5 | Error reasons and HTTP codes match: invalid key (400 + API_KEY_INVALID, TC-22), API disabled (403 SERVICE_DISABLED, TC-28), billing disabled (403 BILLING_DISABLED, TC-28), key restricted to another API (403 …_BLOCKED; set one in the console and try), daily cap (429, TC-29). | |
| 6 | The Test Connection probe (no address lines) returns 400 INVALID_ARGUMENT only **after** the key, API and billing checks, and is not billed (TC-03 step 7). | |
| 7 | A request with `enableUspsCass` is billed as Address Validation **Pro**, inside the 5,000 free requests a month (Google billing report by SKU). | |
| 8 | A real street without a house number gives ROUTE or OTHER (TC-07); a real office building without a suite gives `CONFIRM_ADD_SUBPREMISES` / DPV D (TC-08). | |
| 9 | `error.message` never contains the key or a URL with it (read the **Provider Message** column of the Error rows from TC-22 and TC-28). | |
| 10 | Latency is well under the 10-second timeout, and a blocked or unreachable network gives the not-responding message, not a raw error (TC-22 step 4, TC-27). | |
| 11 | Is `standardizedAddress` ever **partly** filled (street set, city, state or ZIP blank)? If you ever get **Unexpected response from Google Maps.** on a real, valid address, copy the log row (GA-08). | |
| 12 | The current Google Maps Platform Service Specific Terms, Address Validation section (30-day storage rule, permitted purposes, the artificial-address clause) — read them once and note the date. | |
| 13 | The privacy-notice link `https://policies.google.com/privacy` opens the intended page (OQ-31) and the "Microsoft services" wording is as in TC-01 step 4. | |

## 3a. Version 1.1 test cases (FRD 2.1 Appendix C; the other master-data cards)
These cases were written for 1.1.0.12 and run on 1.3.0.0 (the current build) or a later build. They cover the five tests FRD Appendix C marks manual (24, 30, 34, 37, 42), a short smoke pass for every group of cards, and four cases added after the Code Review and Gap-Fit (TC-39 to TC-42: the log permission filter, the country rule, the linked-record update and the log after a record is gone). The rules behind the cards (what Accept writes, what resets the indicator, how linked records follow, Privacy Blocked) are tested by the automated tests; this section is only what a person must see. **Nothing in this section has been run.** The real-address rule at the top of this script applies to every case marked Needs live Google: Yes. In total the smoke cases send about 20 requests to Google.

**Records for this section** (create them in the test company; a number or code of your choice, the names are labels): a customer **C-SMOKE** (use any of the 1.0.0.0 customers if you prefer) with a **Ship-to Address** and a **Customer Bank Account**; a vendor **V-SMOKE** with an **Order Address**, a **Remit Address** and a **Vendor Bank Account**; a **Location**, a **Responsibility Center**, a **Bank Account**; an employee **E-SMOKE** with an **Alternative Address**; a company **Contact** with a **Contact Alt. Address**, a person Contact linked to it, and a **Resource**. Give each address the real example **1600 Amphitheater Parkway** (misspelled on purpose), **Mountain View**, **CA**, **94043**, Country/Region blank, so Google is expected to suggest the correct spelling. Do not make up other addresses.

### TC-30 Every card has the action, the field and the log (FRD test 24)
**Covers:** FRD test 24, FR-10, FR-11, FR-12.1 · **Needs live Google:** No (nothing is run) · **Run as:** Normal tester
*Precondition:* the records above exist. For each row, open the card and look; do not choose Validate Address in this case.
| Card (group) | Validate Address on the ribbon (promoted) and under Actions | **Address Validated** shown next to the address, read-only (greyed, cannot be typed in) | **Google Address Validation Log** action present | Pass / Fail | Notes |
|---|---|---|---|---|---|
| Customer Card (Sales and customer) | | | | | |
| Ship-to Address (Sales and customer) | | | | | |
| Customer Bank Account Card (Sales and customer) | | | | | |
| Vendor Card (Purchasing and vendor) | | | | | |
| Order Address (Purchasing and vendor) | | | | | |
| Remit Address (Purchasing and vendor) | | | | | |
| Vendor Bank Account Card (Purchasing and vendor) | | | | | |
| Company Information, company address (Company and organization) | | | | | |
| Company Information, ship-to address: **Validate Ship-to Address** and **Ship-to Address Validated** | | | | | |
| Location Card (Company and organization) | | | | | |
| Responsibility Center Card (Company and organization) | | | | | |
| Bank Account Card (Company and organization) | | | | | |
| Employee Card (People) | | | | | |
| Alternative Address (of the employee) (People) | | | | | |
| Contact Card, for a company and for a person (People) | | | | | |
| Contact Alternative Address Card (People) | | | | | |
| Resource Card, for a person and for a machine (People) | | | | | |
Expected for every row: all three present; the field is not editable. Where the card has a **Functions** group (Customer, Vendor, Employee, Contact, Resource) the action is in it. Write down where each field sits and where the log action is; the user guide's section 3.1 lists the expected places, and a different place is a note, not a failure. **Also check:** there is **no** Validate Address on any list page (Customers, Vendors, Contacts) and on any sales or purchase document.

### Smoke pass — the same steps for every group (TC-31 to TC-34)
For **each card** named in the group's case:
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | Open the card for the record with the misspelled example address. **Address Validated** is **No**. Choose **Validate Address**. If the privacy notice appears, **Agree**. | The **Suggested Address** window opens with the Current and Suggested columns, changed values in bold and the line **Suggestion from Google Maps**. | | |
| 2 | Choose **OK**. | The window closes; the card shows the suggested address; **Address Validated** = **Yes**. | | |
| 3 | Choose the card's **Google Address Validation Log** action. | Exactly the entries of this record: a **Suggestion Accepted** row with **Source Table** (for example *Vendor*), **Record No.** (the key, for example *V-SMOKE*; no name), **Address Type** = Main. The hidden **Customer No.** and **Source** columns can be shown through Personalization: **Customer No.** is blank (it is filled only for customers) and **Source** reads *Vendor V-SMOKE*. | | |
| 4 | Edit the **City** (for example add a letter) and press Tab. | **Address Validated** goes to **No** by itself. | | |
Record a Pass or Fail per card in the group's table below (a row is Pass only when steps 1 to 4 all held).

### TC-31 Smoke: Sales and customer
**Covers:** FRD tests 24, 25, 27 (seen once) · **Needs live Google:** **Yes** · **Run as:** Normal tester
| Card | Steps 1 to 4 | Pass / Fail | Notes |
|---|---|---|---|
| Ship-to Address (of C-SMOKE) | | | |
| Customer Bank Account Card (of C-SMOKE) | | | |
Then, on the **Customer Card of C-SMOKE** (the Customer Card did not change for steps 1 to 4): the customer's own log (**Customer > Google Address Validation Log**) shows no entry for the ship-to address or the bank account (they have their own logs).

### TC-32 Smoke: Purchasing and vendor
**Covers:** FRD tests 24, 25, 27 (seen once), FR-9 (Vendor and Contact) · **Needs live Google:** **Yes** · **Run as:** Normal tester
| Card | Steps 1 to 4 | Pass / Fail | Notes |
|---|---|---|---|
| Vendor Card (V-SMOKE) | | | |
| Order Address (of V-SMOKE) | | | |
| Remit Address (of V-SMOKE) | | | |
| Vendor Bank Account Card (of V-SMOKE) | | | |
Extra check on the Vendor Card, after step 2: open the vendor's linked **Contact** (search **Contacts**). Expected: its address is now the suggested one and its **Address Validated** is **Yes** (the vendor's contact follows the vendor). If the vendor has no contact, write N/A.

### TC-33 Smoke: Company and organization
**Covers:** FRD tests 24, 25, 27, 28 (seen once) · **Needs live Google:** **Yes** · **Run as:** Admin tester (Company Information normally needs an administrator)
| Card | Steps 1 to 4 | Pass / Fail | Notes |
|---|---|---|---|
| Location Card | | | |
| Responsibility Center Card | | | |
| Bank Account Card | | | |
| Company Information, **company address** (**Validate Address**; give it the example address first, then restore the real one afterwards) | | | |
| Company Information, **ship-to address** (**Validate Ship-to Address**; enter the example address in the Ship-to fields) | | | |
Extra checks on Company Information (two blocks are independent):
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | After validating the ship-to address, look at the **Address Validated** field of the company address. | It is unchanged by the ship-to check (it does not turn Yes because the ship-to was checked). | | |
| 2 | Edit a ship-to field (for example **Ship-to City**), press Tab. | **Ship-to Address Validated** goes to **No**; **Address Validated** (company) does not change. | | |
| 3 | Choose **Google Address Validation Log**. | Entries of both blocks, told apart by **Address Type** (Main for the company address, Ship-to for the ship-to address). | | |
| 4 | Put the company's real address back and, if you changed it, tell the administrator. | n/a | | |

### TC-34 Smoke: People
**Covers:** FRD tests 24, 25, 27, 31, 33 (seen once), FR-9, FR-17 (seen once) · **Needs live Google:** **Yes** (except the privacy step) · **Run as:** Normal tester
| Card | Steps 1 to 4 | Pass / Fail | Notes |
|---|---|---|---|
| Employee Card (E-SMOKE) | | | |
| Alternative Address (of E-SMOKE) | | | |
| Contact Card (the company contact) | | | |
| Contact Alternative Address Card (of the company contact) | | | |
| Resource Card (a person resource) | | | |
Extra checks:
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | Use an employee whose **Resource No.** field names an existing Resource (set it on the Employee Card if needed): validate the employee and choose **OK** (step 2 of the smoke steps). Open the linked Resource. | The resource's address is the suggested address and its **Address Validated** is **Yes**. If the employee has no resource, write N/A. | | |
| 2 | Open the **person contact** that belongs to the company contact (the company contact was validated). | If Marketing Setup has **Inherit Address Details** on and the person's address equalled the company's, the person has the new address and **Address Validated** = **Yes**. Otherwise it is unchanged. Write which you saw. | | |
| 3 | Validate Address on the **person** contact and choose **OK**. Then open the company contact. | The company contact's address is unchanged (accepting on a person never changes the company). | | |
| 4 | **Privacy Blocked (no Google needed).** On a test vendor, a test contact, a test employee and a test resource switch **Privacy Blocked** on, one at a time, and choose **Validate Address** on each. Then do the same on the **Order Address** of the blocked vendor. | Each shows *Address validation is not available for this record because it is blocked due to privacy.* Nothing is sent (no Google request in the Google Cloud report) and the log has no new entry. Switch the blocks off again afterwards. | | |

### TC-35 No permission to modify (a table other than Customer) (FRD test 30)
**Covers:** FRD test 30, FR-4, FR-14 · **Needs live Google:** **Yes** · **Run as:** Read-only tester (`OBCFGAV GAV, USE` plus read-only access to vendors, without permission to modify vendors)
*Precondition:* vendor **V-SMOKE** with the misspelled example address and Address Validated = No.
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | Sign in as the Read-only tester. Open **V-SMOKE**. Choose **Validate Address**. | The check runs and the **Suggested Address** window opens. | | |
| 2 | Look under **Delivery notes**. | A red line **You can't accept the suggested address because you don't have permission to change Vendor records. Choose OK or Cancel to close without changes.** | | |
| 3 | Choose **OK**. | The window closes. The vendor's address and **Address Validated** are unchanged. | | |
| 4 | Open the vendor's **Google Address Validation Log**. | One row, **Result = Suggestion Ignored**, **Accepted = No**. | | |
| 5 | Repeat steps 1 to 3 on one card from another group (for example a Location or a Contact), if the Read-only tester can open it. | The same message with that table's name (for example *Location records*). Write N/A if the tester cannot open it. | | |

### TC-36 Upgrade from 1.0.0.0, in two companies (FRD test 34)
**Covers:** FRD test 34, FR-16, Standards §9.6 · **Needs live Google:** No · **Run as:** Admin tester
*Precondition:* a sandbox where **1.0.0.0** is installed and used in **two companies** (say TEST A and TEST B), each with at least one customer that has a log entry and at least one customer with **Address Validated = Yes** whose linked contact has the same address. Write down, per company: the customer numbers, the number of log entries, and the address of each validated customer and of its linked contact (the contact has no Address Validated field before the upgrade). Do not run this case on a sandbox that never had 1.0.0.0: that is the fresh-install check in step 6.
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | Install `outputAppPackage/Google_Address_Validator_1.3.0.0.app` over the earlier version by `docs/4-prove/SandboxInstall.md`, Schema Sync Mode **Force Sync** (1.3.0.0 renumbered every table and field, so **Add** is refused; the old log, flags and setup values are dropped and the API key is kept). On a sandbox that never had the extension, a plain install. | The install completes; after a Force Sync the setup shows the API key still saved and the Validation Log starts empty. | | |
| 2 | In TEST A open **Google Address Validation Log** (search for it). | All the old entries are still there, and every one shows **Source Table** = Customer, **Address Type** = Main, and **Record No.** = the customer's number (this is filled by the 1.1.0.10 upgrade step; show the hidden **Source** column to see *Customer <number>*). | | |
| 3 | In TEST A open a validated customer. | **Address Validated** is still **Yes**. | | |
| 4 | In TEST A open the validated customer's linked contact. | **Address Validated** = **Yes** when the contact's address equals the customer's; unchanged otherwise. | | |
| 5 | Repeat steps 2 to 4 in TEST B. | The same results in the second company (the upgrade runs once per company). | | |
| 5a | In TEST A and in TEST B open **Google Address Validation Supported Countries**. | Both companies show the 40 countries, all **Enabled** (the 1.2 upgrade step seeds the table once per company). Write down that all 40 are on: validation outside the US is now possible for every record. | | |
| 6 | **Second run.** Install the next build (after 1.3.0.0) over 1.3.0.0 when one exists (the agent tells you). Repeat steps 2 and 4. Or write **Blocked - no second build** and the date. | Nothing changes: no log entry is changed again, no contact flag is set again (for a contact whose address you edited after step 4 the field stays **No**). | | |
| 7 | **Fresh install.** In a sandbox that never had this extension, install 1.3.0.0; create a new company. | No error. The new company's **Assisted Setup** entry reads *Enter the Google Maps API key used to validate addresses.* The log is empty. | | |

### TC-37 The Customer Card log shows 1.0.0.0 and 1.1 entries (FRD test 37)
**Covers:** FRD test 37, FR-5 · **Needs live Google:** **Yes** (step 2) · **Run as:** Normal tester
*Precondition:* TC-36 done, so a customer has an entry written by 1.0.0.0.
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | Open that customer. Choose **Customer > Google Address Validation Log**. | The 1.0.0.0 entries are listed, newest first, each with **Record No.** filled in (and **Customer No.**, if you show that column). | | |
| 2 | Run **Validate Address** on the customer (change the address a little first, so it is not already validated), choose **OK**, and open the log again. | The new entry is at the top with **Record No.** filled in, **Source Table** = Customer and **Address Type** = Main; the 1.0.0.0 entries are still below it. | | |
| 3 | Open the log by searching for **Google Address Validation Log**. | The whole log shows entries of different kinds of records (Source Table column), and each has its own **Record No.** (the hidden **Customer No.** column, if shown, is blank for non-customer entries). | | |

### TC-38 No duplicate window during Accept (FRD test 42)
**Covers:** FRD test 42, FR-9 · **Needs live Google:** **Yes** · **Run as:** Admin tester (needs a client; the automated tests cannot see a window)
*Precondition:* in **Marketing Setup**, **Maintain Dupl. Search Strings** is on, and two **company** contacts exist whose name and address are close enough for Business Central to treat them as duplicates (create the second with the same name and the same misspelled example address).
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | **Control.** On the second contact change the **Address** by hand (for example to a slightly different spelling of the same street) and move to another field. | Business Central's standard *possible duplicate contacts* window appears. If it does **not**, this test cannot show anything with these two contacts: change the setup or the data until it does, or write **Blocked** and why. | | |
| 2 | Close that window. Restore the misspelled example address on the second contact (the **Address Validated** field is **No**). Choose **Validate Address**. | The **Suggested Address** window opens. | | |
| 3 | Choose **OK**. | **No** duplicate window appears. The contact's address is the suggested one and **Address Validated** = **Yes**. | | |
| 4 | Edit the address by hand again on that contact. | The standard duplicate window is allowed to appear again (the check is only skipped while the extension writes). | | |

### TC-39 The log shows a user only what the user may read (Code Review CR-1.1-01)
**Covers:** FR-5, FR-17, the log permission rule of `docs/4-prove/Deployment.md` §4 · **Needs live Google:** No (uses entries written by TC-31 to TC-34) · **Run as:** a **Log tester** (new: `OBCFGAV GAV, USE` plus read access to Customers and Vendors, **no** read permission on Employee, Alternative Address, Resource or Contact; for example D365 BASIC, VIEW without the people sets), then the Admin tester · **Nothing here has been run**
*Precondition:* the log already holds entries for a Customer, a Vendor, an Employee, an Alternative Address and a Resource (from TC-31 to TC-34), and the Log tester cannot open the Employee card (check: search **Employees** as that user).
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | Sign in as the Log tester. Open the Customer Card of C-SMOKE and choose **Customer > Google Address Validation Log**. | Only the entries of that customer. | | |
| 2 | Search for **Google Address Validation Log** and open it. Read the **Source Table** column from top to bottom. | Customer and Vendor rows (and the other tables the tester may read) are listed. **No** Employee, Alternative Address or Resource row appears. | | |
| 3 | Choose **Open in Excel** (or **Edit in Excel**) on the page, and the page's **analysis mode** (Analyze) if your client shows it. | The same rows as step 2 and no Employee, Alternative Address or Resource row. If a client offers neither, write N/A. The Excel path and analysis mode are unverified, which is why this step exists. | | |
| 4 | Remove any filter you set. Try to filter **Source Table** to *Employee*. | No rows. | | |
| 5 | Sign in as the Admin tester (`OBCFGAV GAV, ADMIN`) and open the same page. | Every row, including Employee, Alternative Address and Resource. Note: an administrator has direct read on the log table, so a table URL or API is not filtered by the page; this is by design. | | |
| 6 | As the Log tester, try to delete a log entry (the page offers no delete). | No delete is possible. | | |

### TC-40 The country is part of the validated address
**Covers:** Code Review CR-1.1-04, FRD test 39 · **Needs live Google:** **Yes** (3 to 4 requests) · **Run as:** Admin tester (needs to change General Ledger Setup) · **Nothing here has been run**
*Precondition:* customer **C-SMOKE** has a real address you validated (TC-31) so that **Address Validated** is **Yes**, Country/Region Code blank, and the country codes **US** and **CA** exist under Country/Regions. Write down General Ledger Setup, **Require Country/Region Code in Addresses** (the field `Req.Country/Reg. Code in Addr.`), to put it back at the end.
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | **Require Country/Region Code in Addresses = On.** On C-SMOKE change **Country/Region Code** from blank to **US**, press Tab. | The street, city, state and ZIP Code are kept (Business Central does not clear them) **and Address Validated goes to No**. | | |
| 2 | Choose **Validate Address** and accept or confirm, so the field is **Yes** again. Change the country from **US** to **CA**, press Tab. | The address is kept and **Address Validated** goes to **No**. Put the country back to **US** and validate again until it is **Yes**. | | |
| 3 | **Require Country/Region Code in Addresses = Off.** With C-SMOKE at **Yes**, change the country from **US** to **CA**. | Business Central clears City, State and ZIP Code, and **Address Validated** is **No**. Re-enter the address and country **US**. | | |
| 4 | Repeat step 1 on one other card that has the field (for example the Vendor Card V-SMOKE or a Ship-to Address). | Same result as step 1: **No**. | | |
| 5 | On **Company Information**: with the company address validated, change **Country/Region Code**; with the ship-to address validated, change **Ship-to Country/Region Code**. | The first change resets **Address Validated** only; the second resets **Ship-to Address Validated** only. | | |
| 6 | Put General Ledger Setup, **Require Country/Region Code in Addresses**, back to the value you wrote down, and restore the company's real country. | n/a | | |

### TC-41 Linked record: Contact and Resource update, and the Contact rule (confirmed by AJ Ansari, 2026-10-18)
**Covers:** FRD tests 32, 33, 41 and FR-12.4 as built in 1.1.0.3 to 1.1.0.10 · **Needs live Google:** **Yes** (3 requests) · **Run as:** Admin tester · **Nothing here has been run**
*Precondition:* customer **C-SMOKE** with a linked contact (open **Contacts** and find the contact with the customer's name; **Business Relation** shows Customer), **Address Validated** = No on both, and the **Change Log** activated for the Contact table (**Change Log Setup**, table Contact, all fields) if the tenant uses it; otherwise write N/A on the Change Log parts.
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | Write down the contact's **Last Date Modified** and the number of Change Log entries for it (**Change Log Entries**, filtered to table Contact and this contact). | n/a | | |
| 2 | On C-SMOKE choose **Validate Address**; if a suggestion appears choose **OK**, otherwise it is confirmed. | C-SMOKE **Address Validated** = Yes. Open the contact: its **Address Validated** = **Yes**, its **Last Date Modified** is today, and the Change Log has new entries for the contact (at least the **Address Validated** field, and the address fields when the suggestion changed them). | | |
| 3 | Choose **Validate Address** on C-SMOKE again without changing anything (confirmed). Look at the contact and its Change Log. | **No new Change Log entry** is added: the contact already had the same indicator, so the standard update is not run again. | | |
| 4 | Make the address not findable (clear the house number, save) and validate C-SMOKE: it ends in Not Found. Open the contact. | The customer's and the contact's **Address Validated** are both **No**, and the Change Log shows the change. | | |
| 5 | **Rule confirmed by AJ Ansari (2026-10-18); record what you see.** Use a user who may modify **Contact** but **not Customer** (Read-only tester plus Contact edit). Open the **company contact** linked to a customer, make the address misspelled so Google suggests a different one, choose **Validate Address** and **OK**. | **Confirmed behaviour (AJ Ansari, 2026-10-18):** for a Contact source the update of the linked customer, vendor, bank account, employee and the company's persons is part of the same write, so the expected result is an **error message**, a log row with **Result = Error**, and the contact unchanged. Write down exactly what you saw. **Do not mark Fail for either outcome**; AJ Ansari decides which behaviour he wants. | | |
| 6 | Employee to Resource: validate an employee that has a **Resource No.** (TC-34 step 1) and confirm. Open the resource. | The resource's address and **Address Validated** equal the employee's (Business Central's own employee-to-resource update ran). | | |

### TC-42 The log after a record is gone, and the record-gone message
**Covers:** FR-18.2, the log retention rule of `docs/4-prove/Deployment.md` §4a · **Needs live Google:** **Yes** (3 requests) · **Run as:** Normal tester, plus a second session · **Nothing here has been run**
*Precondition:* a throw-away vendor **V-GONE**, a throw-away customer **C-GONE**, and a throw-away vendor **V-BLOCK**, each with the misspelled example address, **Address Validated** = No. Two browser sessions as users who may delete them (S7).
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | Session 1: open **V-GONE**, choose **Validate Address** and **OK**. Session 2: open **Vendors**, delete **V-GONE**. Session 1: open **Google Address Validation Log** from the Vendors list or by search. | The entry is still there: **Source Table** = Vendor, **Record No.** = *V-GONE*, Result Suggestion Accepted. The log keeps the key and the address until the Retention Policy deletes the row. | | |
| 2 | Session 1: open **V-BLOCK**, validate and choose **OK**. Switch **Privacy Blocked** on for V-BLOCK. Open the log. | The entry is still listed. Choose **Validate Address** on V-BLOCK: the privacy message appears and nothing new is logged. Switch the block off afterwards. | | |
| 3 | Session 1: open **C-GONE**, choose **Validate Address** so the **Suggested Address** window is open. Session 2: delete **C-GONE**. Session 1: choose **OK**. | The message *The Customer record no longer exists, so nothing was updated.* The log has one row, Result **Error**. | | |
| 4 | Repeat step 3 on a new throw-away vendor **V-GONE2**. | The message *The Vendor record no longer exists, so nothing was updated.* and an Error row. | | |
| 5 | On a card (for example a Ship-to Address that has been checked), choose **Google Address Validation Log**. | Only the entries of that record, newest first, not the entries of its customer or of other ship-to addresses. | | |

### TC-43 Google names, search, and the log columns (SC-2, 1.1.0.10)
**Covers:** FR-5 (log columns and Record No.), FR-6 (names), FR-16.6 · **Needs live Google:** No (uses entries written by TC-31 to TC-34; a vendor, a ship-to address and the company must each have at least one entry) · **Run as:** Admin tester · **Nothing here has been run**
*Precondition:* 1.3.0.0 is installed and the log holds entries for a customer, a vendor, a ship-to address and the company (Company Information) from TC-31 to TC-34.
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | In **Tell Me**, search for **Google**. | The results include **Google Address Validation Setup** and **Google Address Validation Log**. (The wizard is not a Tell Me page; it is found in step 3.) | | |
| 2 | Search for **Google Maps**, then for **address validation**. | The same two pages are found by each (from 1.2 also **Google Address Validation Supported Countries**). | | |
| 3 | Open **Assisted Setup**. | The entry reads **Set up Google address validation** (also on a company where an older version was already installed: the title is re-registered each time the page opens). | | |
| 4 | Open **Google Address Validation Log**. | The first columns are **Entry No., Source Table, Record No., Address Type, Checked At, User ID, Result, Accepted**, then the original and suggested address columns. **Customer No., Source** and **Source Table No.** are not shown. | | |
| 5 | Find the customer's row. | **Source Table** = Customer, **Record No.** = the customer number (for example *C00010*). | | |
| 6 | Find the vendor's row. | **Source Table** = Vendor, **Record No.** = the vendor number. | | |
| 7 | Find the ship-to address's row. | **Source Table** = Ship-to Address, **Record No.** = the customer number, a space, a slash, a space and the code (for example *C00010 / MAIN*). | | |
| 8 | Find the company's rows (Company Information). | **Record No.** is blank for both the Main and the Ship-to row. | | |
| 9 | Use the gear icon, **Personalize**, and add **Customer No.**, **Source** and **Source Table No.** to the list. | The columns appear. **Customer No.** is filled for customer rows and blank for the others; **Source** shows the table and key (for example *Vendor V-SMOKE*); the layout can be reset. | | |
| 10 | On the Customer Card choose **Customer > Google Address Validation Log**. | Only that customer's rows (the action still filters by the customer). The same action on a Vendor Card shows only that vendor's rows. | | |
| 11 | If the sandbox was upgraded from 1.1.0.8 or earlier (TC-36): open the log unfiltered and find an entry written before the upgrade. | Its **Record No.** is filled (customer entries from the customer number; others from the key of the record, or blank if the record no longer exists). | | |

### TC-44 A blank country is filled in (FR-18.6, 1.1.0.12)
**Covers:** FR-18.6 (FR-11.5, FR-12.3) · **Needs live Google:** **Yes** (4 requests, real addresses only) · **Run as:** Admin tester (all steps except step 7), the Read-only tester (step 7) · **Nothing here has been run**
*Precondition:* 1.3.0.0 is installed; on **Google Address Validation Setup** **Blank Country Handling** is **Use default country** (so that every blank country is treated as the default; write down the old value and put it back afterwards; TC-53 to TC-56 cover Let Google decide) and **Default Country/Region Code** is `US`; the setup is Enabled with a working key. If your General Ledger Setup requires a country in addresses (**Req.Country/Reg. Code in Addr.**), switch that off for this case and switch it back on afterwards, so that Country/Region Code can be left blank. Use real addresses: a vendor **V-CTRY** (real address, **Country/Region Code** blank, written so that Google suggests a change, for example a lower case street name), a location **L-CTRY** (real address, blank country, already in USPS form so that Google confirms it), a vendor **V-CA** with a real Canadian address and country **CA**, and a vendor **V-NF** with a real street but no house number and a blank country.
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | Open **V-CTRY**, check that **Country/Region Code** is blank, choose **Validate Address**, then **OK** on the Suggested Address window. | The address is replaced with the suggestion, **Address Validated** is **Yes**, and **Country/Region Code** is now **US** (the setup's code). | | |
| 2 | Open **L-CTRY**, check that the country is blank, choose **Validate Address** (Google confirms it, so there is no window). | The message says the address is confirmed. **Address Validated** is **Yes** and **Country/Region Code** is now **US**. | | |
| 3 | On **V-CTRY** change **Country/Region Code** to **CA** and check **Address Validated**. | It is **No** (the country is part of the validated address). Filling the country in by the check in steps 1 and 2 did not reset it. | | |
| 4 | Open **V-CA** and choose **Validate Address**. | Since 1.2 Canada is covered, so the check is **not** refused: the request goes to Google, and the country stays **CA** (the details are in TC-47). Before 1.2 this step expected the US-only refusal. | | |
| 5 | Open **V-NF** (blank country) and choose **Validate Address**. | The message begins *Google Maps couldn't confirm this address.* The log entry is **Not Found**. **Country/Region Code** is still **blank**. | | |
| 6 | On a record whose country is already **US** (any record from TC-31), validate it with a changed street name and accept. | **Country/Region Code** is still **US**; only a blank country is ever filled in. | | |
| 7 | Sign in as the Read-only tester. Open a record with a blank country and a real address that Google confirms, and choose **Validate Address**. | The message says the address is confirmed; the record is **not** changed (the tester cannot modify it), so **Address Validated** and the country stay as they were. Write N/A if the Read-only tester cannot open such a record. | | |
| 8 | On **Company Information** with a blank **Ship-to Country/Region Code** and a real ship-to address, choose **Validate Ship-to Address** and accept. | **Ship-to Country/Region Code** is filled in with **US**; the company's own **Country/Region Code** is not touched. | | |

## 3b. Version 1.2 test cases (SC-4: the 40 countries Google covers)
These cases run on **1.3.0.0** or a later build. They cover what a person must see for validation outside the United States: the supported-countries page, a country switched off, a Canadian and a German record, a blank country that is filled in, a country Google does not cover, the line in the Suggested Address window, and a country mismatch. The rules behind them are tested by the automated tests (`docs/4-prove/AutomatedTestGuide.md`, rows 135 to 155, plus rows 1 and 62 onward that were changed). TC-53 to TC-56 (SC-5, SC-5a) cover how a record with a blank Country/Region Code is handled under the Blank Country Handling setting. **Nothing in this section has been run.** The real-address rule at the top of this script applies to every case marked Needs live Google: Yes: use a real Canadian and a real German address you are sure of, never made-up ones. The Google coverage list this script was written from was read on 2026-10-18 (<https://developers.google.com/maps/documentation/address-validation/coverage>). In total TC-45 to TC-52 send about 8 requests to Google, and TC-53 to TC-56 about 6 more (TC-55 can send two for one check).

**Records for this section** (create them in the test company): a vendor **V-CAN** with a real Canadian address (street, city, province as 2-letter code, postal code like A1A 1A1) and **Country/Region Code** `CA`; a vendor **V-DE** with a real German address (street, house number, postal code, city; leave **County / State** empty) and country `DE`; a vendor **V-BLANK** with a real address in Germany (or Canada) and a blank **Country/Region Code**; a vendor **V-RU** with any text address and country `RU`; a vendor **V-MIX** with a real German address but country `FR`. The codes **CA, DE, FR, RU** must exist under **Countries/Regions** with their **ISO Code** filled in (`CA`, `DE`, `FR`, `RU`); create them if missing. Set **Default Country/Region Code** on **Google Address Validation Setup** to blank for TC-49 and put it back afterwards (write down its value first). TC-49 works under either setting of Blank Country Handling.

### TC-45 The Supported Countries page shows the 40 countries
**Covers:** SC-4, FR-19 (supported countries) · **Needs live Google:** No · **Run as:** Admin tester, then the Read-only tester · **Nothing here has been run**
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | In **Tell Me** search for **Google Address Validation Supported Countries** and open it. | The page opens with **40 rows**. Columns: Region Code, Name, Enabled, Preview, Residential and Commercial Data, USPS Delivery Data. | | |
| 2 | Compare with the table in section 4.12 of `docs/4-prove/UserGuide.md`. | The same 40 codes and names. **Enabled** is on for every row. **Preview** is on only for IN and JP. **Residential and Commercial Data** is off only for CO, IT and SG. **USPS Delivery Data** is on only for PR and US. | | |
| 3 | Try to add a row, delete a row, and change **Name** or **Preview**. | Not possible. Only **Enabled** can be changed. | | |
| 4 | Open **Google Address Validation Setup** and choose **Supported Countries**. | The same page opens. | | |
| 5 | Sign in as the Read-only tester and open the page by Tell Me. | The 40 rows are visible and nothing, **Enabled** included, can be changed. | | |

### TC-46 A country that is switched off is refused
**Covers:** SC-4, FR-19 · **Needs live Google:** No (nothing is sent) · **Run as:** Admin tester, then Normal tester · **Nothing here has been run**
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | Admin: on the Supported Countries page turn **Enabled** off for **DE**. | Saved. | | |
| 2 | Normal tester: open **V-DE** and choose **Validate Address**. | Message **Address validation isn't turned on for (the name of Germany as in your Countries/Regions). Ask your administrator to turn it on in Google Address Validation Supported Countries.** No dialog. | | |
| 3 | Open the vendor's **Google Address Validation Log**. | Empty. Nothing was sent. | | |
| 4 | Admin: turn **Enabled** on for **DE** again. | Saved. | | |

### TC-47 A Canadian vendor validates and keeps CA
**Covers:** SC-4, FR-19 · **Needs live Google:** **Yes** · **Run as:** Normal tester · **Nothing here has been run**
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | Open **V-CAN** and choose **Validate Address**. Agree to the privacy notice if it appears. | The request goes to Google (no *can't validate* message). Either a **Suggested Address** window opens, with the column captions **State / Province** and **ZIP / Postal Code**, or the message *The address is confirmed by Google Maps. No changes are needed.* appears. Write which: ______ | | |
| 2 | If a window opened, choose **OK**. | The address is replaced by the suggestion, **Address Validated** is **Yes**, and **Country/Region Code** is still **CA**. | | |
| 3 | Open the vendor's log. | A new row for **V-CAN** with **Result** Confirmed or Suggestion Accepted. No USPS delivery notes are expected (Canada has no USPS data). | | |

### TC-48 A German vendor without a state
**Covers:** SC-4, FR-19 · **Needs live Google:** **Yes** · **Run as:** Normal tester · **Nothing here has been run**
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | Open **V-DE** (County / State is empty) and choose **Validate Address**. | The request goes to Google; no message asks for a state. A Suggested Address window opens or the address is confirmed. | | |
| 2 | If a window opened, choose **OK**. | The street, postal code and city are as suggested. **County / State** is still empty or holds only what Google returned (write which: ______). **Address Validated** is **Yes**. **Country/Region Code** is still **DE**. | | |
| 3 | Clear the **Post Code** and **City** of **V-DE**, leaving only the street, and choose **Validate Address**. | Message **Enter a street address and either a ZIP / postal code or a city (in the US and Canada, a city needs its state or province too).** Nothing is sent. Restore the address afterwards. | | |

### TC-49 A blank country is filled in with the country Google found
**Covers:** SC-4, FR-18.6 generalised · **Needs live Google:** **Yes** · **Run as:** Admin tester · **Nothing here has been run**
*Precondition:* **Default Country/Region Code** on the setup page is blank (note its old value), and **V-BLANK** has a blank **Country/Region Code** and a real address in Germany (or Canada). If **Req.Country/Reg. Code in Addr.** is on in General Ledger Setup, switch it off for this case.
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | Open **V-BLANK** and choose **Validate Address**. | The request goes to Google. The **Suggested Address** window shows the line **The Country/Region will be set to (the country's name).** (if Google suggests a change; if it confirms the address there is no window). | | |
| 2 | Choose **OK** (or close the confirmed message). | **Country/Region Code** is now `DE` (or `CA`), the Country/Region whose ISO Code matches. **Address Validated** is **Yes**. | | |
| 3 | Set the code back to blank, and repeat with a record whose address Google does not find (a real street, no number). | Message *Google Maps couldn't confirm this address.* The country stays **blank**. | | |
| 4 | Restore the **Default Country/Region Code** and General Ledger Setup. | n/a | | |

### TC-50 A country Google does not cover is refused
**Covers:** SC-4 (replaces the former US-only rule), FR-19 · **Needs live Google:** No (nothing is sent) · **Run as:** Normal tester · **Nothing here has been run**
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | Open **V-RU** (country `RU`) and choose **Validate Address**. | Message **Google Maps can't validate addresses in (the name of Russia as in your Countries/Regions).** No dialog. | | |
| 2 | Open its log. | Empty. Nothing was sent. | | |
| 3 | Change the country of **V-RU** to a code whose **ISO Code** is blank and that is not a two-letter code (create one such as `XXX`), and choose **Validate Address**. | Message **Google Maps can't tell which country (name) is. Fill in the ISO Code of this country or region on the Countries/Regions page and try again.** Nothing is sent. Delete the test code afterwards. | | |

### TC-51 The Suggested Address window names the country that will be filled in
**Covers:** SC-4, the comparison dialog line · **Needs live Google:** **Yes** · **Run as:** Normal tester · **Nothing here has been run**
*Precondition:* **V-BLANK** with a blank country and a real address that Google will suggest a change for (a misspelled street).
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | Open **V-BLANK** and choose **Validate Address**. | The window shows, under **Suggestion from Google Maps**, a read-only line captioned **Country/Region** with **The Country/Region will be set to (country).** | | |
| 2 | Choose **Cancel**. | Nothing on the vendor changes; the country stays blank. | | |
| 3 | Set **V-BLANK**'s country to `DE` and run it again. | The line is **not** shown (the record already has a country). | | |

### TC-52 Google finds the address in another country
**Covers:** SC-4, FR-19 · **Needs live Google:** **Yes** · **Run as:** Normal tester · **Nothing here has been run**
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | Open **V-MIX** (a real German address, country `FR`) and choose **Validate Address**. | Message **Google Maps found this address in (Germany), but the record says (France). Check the country and try again.** No window. The vendor is unchanged. (If Google does not find the address at all, the usual *couldn't confirm* message appears instead; write it and use another real address.) | | |
| 2 | Open the vendor's log. | One row, **Result = Not Found**. | | |
| 3 | Change the country to `DE` and run it again. | The address validates as in TC-48. | | |

### TC-53 A Danish address with no country is found in Denmark (SC-5, Let Google decide)
**Covers:** SC-5, FR-19.2, FR-19.3, FR-19.7 · **Needs live Google:** **Yes** (1 request, a real Danish address only) · **Run as:** Admin tester · **Nothing here has been run**
*Precondition:* on **Google Address Validation Setup**, **Blank Country Handling** is **Let Google decide** and **Default Country/Region Code** is `US` (write down the old values and put them back afterwards). The code `DK` exists under **Countries/Regions** with **ISO Code** `DK`. A vendor **V-DK** with a real Danish address (street and number, city, a 4-digit postal code), **County / State** empty and **Country/Region Code** blank. If **Req.Country/Reg. Code in Addr.** is on in General Ledger Setup, switch it off for this case.
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | Open **V-DK** and choose **Validate Address**. | The request goes to Google with no country, so the default US is not used. The address is found in Denmark: either the message says the address is confirmed, or the **Suggested Address** window opens and shows **The Country/Region will be set to Denmark.** (If Google does not find it, the *couldn't confirm* message appears: write it in Notes; that is an unproven part of the design, FRD OQ-65.) | | |
| 2 | Choose **OK** (or close the confirmed message). | **Country/Region Code** is now `DK`. **Address Validated** is **Yes**. | | |
| 3 | Open the vendor's log. | One row for this check. | | |
| 4 | Restore the setup values and General Ledger Setup. | n/a | | |

### TC-54 A US address with a state and ZIP code and no country is checked as US (SC-5, Let Google decide)
**Covers:** SC-5, FR-19.3 · **Needs live Google:** **Yes** (1 request, a real US address only) · **Run as:** Admin tester · **Nothing here has been run**
*Precondition:* **Blank Country Handling** is **Let Google decide** (note the old value). A vendor **V-US** with a real US address, a 2-letter **County / State** (for example TX), a 5-digit **Post Code** and **Country/Region Code** blank, written so that Google suggests a change (for example the street name in lower case). `US` exists with ISO Code `US`.
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | Open **V-US** and choose **Validate Address**. | The **Suggested Address** window shows the US Postal Service form of the address (upper case and a ZIP code with the 4-digit extension, for example 77494-1234), which shows that US delivery data was requested, and the line **The Country/Region will be set to (United States).** | | |
| 2 | Choose **OK**. | The address is replaced, **Address Validated** is **Yes** and **Country/Region Code** is now `US`. | | |
| 3 | Make a second vendor **V-US2** with the same real address but **County / State** left empty and a blank country, and validate it. | It is not recognized as American, so no country is sent and Google works it out. The result may lack the ZIP code extension and the delivery notes (a known limit: choose **Use default country** in a US-only company). Write down what you see. | | |

### TC-55 An Italian address with province MI is found in Italy (SC-5a, the repeat without a country)
**Covers:** SC-5a, FR-19.5 · **Needs live Google:** **Yes** (up to 2 requests for the one check, a real Italian address only) · **Run as:** Admin tester · **Nothing here has been run**
*Precondition:* **Blank Country Handling** is **Let Google decide**. `IT` exists under **Countries/Regions** with ISO Code `IT` and is **Enabled** on the Supported Countries page. A vendor **V-IT** with a real address in Milan: street and number, city Milano, **County / State** `MI`, a real 5-digit **Post Code** (CAP) and **Country/Region Code** blank. (MI is also a US state code, so the address first looks American.) If you can, open the Google Cloud console's API metrics for the Address Validation API before and after, to count the requests.
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | Open **V-IT** and choose **Validate Address**. | The address is found in Italy: confirmed, or the **Suggested Address** window with **The Country/Region will be set to Italy.** The check may have cost **two** requests (first as US, then without a country); the vendor's log has **one** row. If the message is *couldn't confirm* or a country mismatch, write the text in Notes (Google's real answer is unproven, FRD OQ-65). | | |
| 2 | Choose **OK** (or close the confirmed message). | **Country/Region Code** is `IT`. **Address Validated** is **Yes**. | | |
| 3 | Write down how many requests the Google Cloud console counted for step 1. | One or two. Two is the expected cost of a failed guess (Deployment.md section 2c). | | |

### TC-56 Use default country (SC-5)
**Covers:** SC-5, SC-5a, FR-19.2 · **Needs live Google:** Partly (steps 2 and 3 send up to 2 requests; real addresses only) · **Run as:** Admin tester · **Nothing here has been run**
*Precondition:* the vendor **V-DK** of TC-53 with its country blank again. On the setup page set **Blank Country Handling** to **Use default country** and **Default Country/Region Code** to `US` (write down the old values).
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | Open **V-DK** and choose **Validate Address**. | The Danish address is treated as a US address, so it is refused before anything is sent: *Enter a street address and either a ZIP / postal code or a city (in the US and Canada, a city needs its state or province too).* No dialog; the log has no new row. | | |
| 2 | On **V-US** (a US address with a state and ZIP code, blank country) choose **Validate Address**. | It is checked as US because the default is US; the result is the same as in TC-54 step 1. | | |
| 3 | Clear **Default Country/Region Code** (leave **Use default country**) and validate **V-DK** again. | No country is sent and nothing is guessed: Google works the country out, as in TC-53 step 1. | | |
| 4 | Restore the setup values. | n/a | | |

## 4. Language pass
Only **English (United States)** is required at first release; no translation files exist (FRD §8). The tester checks the US wording:
| Page | Term (W1) | Expected in en-US |
|---|---|---|
| Customer Card | County | **State** |
| Customer Card | Post Code | **ZIP Code** |
| Comparison dialog | rows | **Address, Address 2, City, State / Province, ZIP / Postal Code** (from 1.2; 1.1 and 1.0.0.0 had State and ZIP Code); columns **Current (BC)** and **Suggested**; line **Suggestion from Google Maps** |
| Messages | | the texts quoted in the cases above |

## 5. Results
Recorded in `docs/4-prove/ReleaseTestResults.md` at Step 12, not here. Keep your own copy of this script with the Pass / Fail column filled in and attach it.

### Reporting a failure
For every Fail (and every Blocked), send the agent:
1. The **TC number and step** (for example TC-04 step 3) and the **version** (for example 1.3.0.0).
2. What you did, in your own words, and what you expected.
3. The **exact text** of any message (choose **Copy details** on the error if it is offered, otherwise a screenshot), exactly as shown.
4. The **customer number**, your **user**, and the **time**.
5. The **entry number** of the matching row in the **Google Address Validation Log**, if there is one, and a screenshot of that row.
6. For a live case, **never send the API key**; send the log row instead.
Do not retest on a different build and do not edit the script's expected results; report what you saw.

## Before calling this done
- [ ] Every FRD requirement is covered by at least one TC (table in §1.1; tests 6, 9, 10 are automated-only, stated there; Appendix C tests 24, 30, 34, 37 and 42 are TC-30, TC-35, TC-36, TC-37 and TC-38, the other Appendix C tests are automated; TC-39 to TC-42 cover the log permission filter, the country rule, the linked-record update and the log after a record is gone, which no automated test can see; TC-45 to TC-52 cover the SC-4 country rules a person must see; TC-53 to TC-56 cover the SC-5 and SC-5a blank-country cases).
- [ ] Every permission set, every deletion rule, and every error message has a red-team TC (permission: TC-23; deletion: TC-10 step 4; error messages: TC-17 to TC-29).
- [ ] Every parent→child entry point has a green-team TC: the only one is the **Google Address Validation Log** action (TC-16); the log is read-only so no child can be created by hand.
- [ ] Every number-series field has a green-team TC: **none exists in this extension** (TC-16 step 4).
- [ ] Every live case was run with a real key and real addresses, or is marked Blocked (never Pass).
- [ ] A non-developer can run every step without asking a developer.
