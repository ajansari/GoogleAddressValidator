# Human Unit Test Script — USPS Address Validator

**Version under test:** 0.0.0.4 · **Package:** `outputAppPackage/USPS_Address_Validator_0.0.0.4.app` · **Environment:** SaaS sandbox, test company (name contains TEST, for example `TEST USPS`) · **Date:** ______________
**Tester name:** ______________________ · **Tester role (Administrator / User / Read-only):** ______________________ · **Date finished:** ______________
**Written for:** a tester who is not a developer. Every step says what to click and what must appear.

> **This extension has no API endpoints.** It adds one action to the Customer Card, a setup card, an Assisted Setup wizard and a read-only log. So the usual green-team (it works) / red-team (it fails safely) checklist for an API is adapted here to the Customer Card flow. Every case below says which part of the Functional Requirements Document (FRD §7.2 acceptance tests 1-21) it covers. FRD tests 1-10, 15-18 and 20 are also covered by the automated tests (`docs/4-prove/AutomatedTestScripts.md`); this script is the manual check of what a person must see on screen.

> **Read this first: live USPS tests may be blocked.** A real run against USPS needs a USPS **Consumer Key and Consumer Secret** for the **Test (TEM)** environment. USPS onboarding is currently blocked (Gap Analysis G16), so you may not have credentials. Each case below shows **Needs live USPS: Yes/No**.
> - **No** cases work with made-up credentials (any text for the key and secret) or none at all. Run them.
> - **Yes** cases need real credentials. If you do not have them, do **not** mark them Pass and do not skip them silently: write **Blocked - no USPS credentials** in the Pass / Fail column and the date in Notes. Step 12 cannot be signed off on those cases (FRD tests 1-3, 14) until credentials exist or the provider decision is made (CR-1); the Dev Manager decides what to do with the blocked rows.
> - Wrong-credentials cases (TC-21) do reach USPS and need an internet connection from the sandbox, but not real credentials.

## 1. Setup

| # | Precondition | How to check |
|---|---|---|
| S1 | The package `USPS_Address_Validator_0.0.0.4.app` is installed in the sandbox, installed by `docs/4-prove/SandboxInstall.md`. | **Extension Management** (search for it): **USPS Address Validator**, version **0.0.0.4**, status **Installed**. |
| S2 | You work in a **test company** whose name contains **TEST**. Never test in a company with real customers. | Top of the screen shows the company name. If not, choose the company name, then **Select Company**. |
| S3 | Three test users exist, each with the permission sets shown. **Admin tester**: `OBCFUSPS USPS, ADMIN` plus the permission sets needed to edit customers (for example **D365 BASIC** and **D365 CUSTOMER, EDIT**; or SUPER). **Normal tester**: `OBCFUSPS USPS, USE` plus the same customer-editing sets. **Read-only tester**: `OBCFUSPS USPS, USE` plus read-only access to customers (for example **D365 READ**) and **no** customer-editing set. | Search **Users**, open the user, look at **User Permission Sets**. |
| S4 | The company is a **US** company (so the Customer Card shows **State** and **ZIP Code**). | Open a Customer Card: the Address group shows **State** and **ZIP Code** (see TC-14 for the check that proves it). |
| S5 | Test customers exist (create them with **Customers > New**; give each a Name and the address shown, leave Country/Region Code blank unless stated). See the list below. | Open **Customers** and find them. |
| S6 | The USPS setup is in the state each case expects. The setup card is **USPS Address Validation Setup** (search for it). | See each case. |
| S7 | Two browser windows (or one normal and one private window) are available, signed in as two different users, for TC-12 and TC-24. | n/a |

**Test customers** (create these in the test company; numbers are free to choose, the names below are labels used in this script):

| Label | Name | Address | City | State | ZIP Code | Country/Region | Used by |
|---|---|---|---|---|---|---|---|
| C-TYPO | Test Typo | 475 Lenfant Plaza SW | Washington | DC | 20260 | (blank) | TC-04 to TC-14, TC-24. *Example only, not verified with USPS. If USPS says it cannot find it, use any real US street address you are sure of, but misspell the street or leave off the ZIP+4 so USPS suggests a different spelling.* |
| C-NOWHERE | Test Nowhere | 1 Nowhere Lane | Springfield | IL | 62701 | (blank) | TC-07 |
| C-CANADA | Test Canada | 123 Main Street | Toronto | ON | M5V3L9 | CA (create the code **CA** under Country/Regions if it does not exist) | TC-18 |
| C-BLANK | Test Blank | (empty) | (empty) | (empty) | (empty) | (blank) | TC-16 |
| C-BADSTATE | Test Bad State | 123 Main Street | Springfield | Illinois | (empty) | (blank) | TC-17 |
| C-ROOT | Test Root | 123 Main Street | Springfield | IL | 62701 | (blank) | TC-01, TC-10, TC-13, TC-19, TC-21, TC-25, TC-27 |

**Suggested order** (so that setup states build on each other): TC-20 first, in a fresh company before the wizard has been run (it needs the setup *not* complete); then TC-01, TC-02, TC-03; then the rest in number order.

### 1.1 Coverage of FRD §7.2

| FRD test | Covered here by | Also automated |
|---|---|---|
| 1 Confirmed | TC-05 | Yes |
| 2 Accepted | TC-04 | Yes (bold is manual only) |
| 3 Ignored and Esc | TC-06 | Yes (Esc is manual only) |
| 4 Not found | TC-07 | Yes |
| 5 Missing suite | not repeated by hand (needs a special address) | Yes |
| 6 Letter case | not repeated by hand | Yes |
| 7 Non-US | TC-18 | Yes |
| 8 Wrong secret | TC-21 | Yes |
| 9 Quota and timeout | not repeatable by hand | Yes |
| 10 Token reuse | not repeatable by hand | Yes |
| 11 Time zones | TC-12 | No (manual) |
| 12 No permission to modify | TC-23 | No (manual) |
| 13 Unsaved edit | TC-10 | No (manual) |
| 14 Setup page and Test Connection | TC-03 | No (manual) |
| 15-18, 20 Address Validated rules | TC-08 (and TC-04 to TC-06) | Yes |
| 19 Address Validated on the card | TC-08 | No (manual) |
| 21 Assisted Setup wizard | TC-02 | No (manual) |

## 2. Test cases - green team (it works)

### TC-01 Privacy notice - agree
**Covers:** FRD FR-1 step 3 (privacy notice) · **Language:** en-US · **Needs live USPS:** No (made-up credentials are enough to get past the notice) · **Run as:** Admin tester
*Precondition:* setup is Enabled with a Consumer Key and Secret (made-up is fine) and nobody has answered the privacy notice yet in this environment. (An administrator's Agree applies to everyone.)
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | Open Customer **C-TYPO**. Choose **Actions > Functions > Validate Address (USPS)** (it is also in the promoted **Process** group). | A **Privacy Notice** page opens before anything else happens, with a link to read the notice. Nothing has been sent to USPS yet. | | |
| 2 | Choose **Agree**. | The notice closes and the check carries on (a USPS answer, or an error message such as the credentials message if the credentials are made up). | | |
| 3 | Run **Validate Address (USPS)** again on the same customer. | The privacy notice does **not** appear again. | | |

### TC-02 Assisted Setup wizard
**Covers:** FRD test 21, FR-6 · **Language:** en-US · **Needs live USPS:** No · **Run as:** Admin tester
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | Search for **Assisted Setup** and open it. | The list shows **Set up USPS address validation** (short title **USPS address validation**) with the description **Enter the USPS Consumer Key and Consumer Secret used to validate customer addresses.** | | |
| 2 | Before you start, open **USPS Address Validation Setup** and write down the values of **Enabled**, **Environment**, **US Country/Region Code** and **Timeout (Seconds)**. Close it. | Values noted: ______ | | |
| 3 | In Assisted Setup choose **Set up USPS address validation**. | The wizard **Set Up USPS Address Validation** opens on **Welcome**. It says to enter the Consumer Key and Secret, and that you choose the environment, turn the service on and test the connection on the USPS Address Validation Setup page. **Back** is greyed out. | | |
| 4 | Choose **Next**. | The **USPS Credentials** step shows **Consumer Key** and **Consumer Secret**, both masked. **Next** is greyed out while either box is empty. | | |
| 5 | Enter any text in **Consumer Key** and press Tab. | **Next** is still greyed out (the secret is empty). | | |
| 6 | Enter any text in **Consumer Secret** and press Tab. | **Next** is now available. | | |
| 7 | Choose **Next**. | The step **That's it!** says **Choose Finish to save the credentials.** **Finish** is available. | | |
| 8 | Choose **Back** once, then **Next** again, then **Finish**. | The wizard closes. | | |
| 9 | Open Assisted Setup again. | The USPS row is marked as completed. | | |
| 10 | Open **USPS Address Validation Setup**. | **Consumer Key** and **Consumer Secret** both show only masked characters (********). The real text is nowhere on the page. **Enabled**, **Environment**, **US Country/Region Code** and **Timeout (Seconds)** are exactly as you wrote them down in step 2. | | |

### TC-03 Setup card and Test Connection
**Covers:** FRD test 14, FR-6 · **Language:** en-US · **Needs live USPS:** **Yes** (the success half; the failure half needs only an internet connection) · **Run as:** Admin tester
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | Open **USPS Address Validation Setup**. | Groups **General** and **USPS Credentials**. A highlighted note reads **The Test (TEM) environment also uses your production Consumer Key and Consumer Secret.** **Environment** offers only **Production** and **Test (TEM)** (no blank choice). | | |
| 2 | Set **Environment** to **Test (TEM)**. Turn **Enabled** on. Leave **US Country/Region Code** and **Timeout (Seconds)** as they are (default US and 10). | Saved without error. | | |
| 3 | Click in **Consumer Key**, replace the masked text with your real USPS Test (TEM) key, press Tab. Do the same in **Consumer Secret**. | After you press Tab both boxes show masked characters again. Close and reopen the page: the secret is not shown. | | |
| 4 | Choose **Test Connection** (promoted action). If the privacy notice appears, choose **Agree**. | The message **The connection to USPS works. A token was received.** (Blocked if you have no real credentials: write Blocked.) | | |
| 5 | Replace the Consumer Secret with the text **wrong** and press Tab. Choose **Test Connection**. | An error message that starts **USPS rejected the credentials.** (needs only an internet connection). No address quota is used by Test Connection. | | |
| 6 | Put the real secret back. | Masked again. | | |

### TC-04 Suggestion accepted (FRD test 2, with bold changed values)
**Covers:** FRD test 2, FR-4, FR-5, FR-8 · **Language:** en-US · **Needs live USPS:** **Yes** · **Run as:** Normal tester
*Precondition:* setup Enabled, valid Test (TEM) credentials entered, privacy notice agreed. Customer **C-TYPO** has Address Validated = No.
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | Open **C-TYPO**. Note its address fields on paper. Choose **Validate Address (USPS)**. | The dialog **USPS Address Suggestion** opens: instruction text **Changed values are shown in bold. Choose OK to accept the USPS address, or Cancel to keep the current address.** Two columns: **Current (BC)** on the left (Address, Address 2, City, State, ZIP Code) and **USPS suggestion** on the right. | | |
| 2 | **Look at the right column.** (This is a manual check; the automated tests cannot see bold.) | Every value that is different from the left column is shown in **bold**. Values that are the same are in normal type. | | |
| 3 | Choose **OK**. | The dialog closes. The Customer Card shows the USPS values (upper case, as USPS writes them). ZIP Code is written **12345-6789** when USPS gave a +4, or just five digits when it did not. | | |
| 4 | Look at **Address Validated** (Address group of the **Address & Contact** FastTab). | **Yes**. | | |
| 5 | Choose **Related > Customer > USPS Validation Log** (the action group is called **Customer**). | One entry, newest first, **Result = Suggestion Accepted**, **Accepted = Yes**, **Original Address / City / State / ZIP Code** hold what you wrote down in step 1, **USPS Address ...** columns hold the new values, **User ID** is your user, **HTTP Status** 200, **Environment** Test (TEM). | | |

### TC-05 Confirmed (FRD tests 1, 16)
**Covers:** FRD tests 1 and 16, FR-2 · **Language:** en-US · **Needs live USPS:** **Yes** · **Run as:** Normal tester
*Precondition:* TC-04 done (so the customer now holds exactly what USPS returned). A new +4 on a 5-digit ZIP counts as a difference, so this case only works on an address that already matches.
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | Open **C-TYPO** again and choose **Validate Address (USPS)**. | **No dialog.** A message **The address is confirmed by USPS. No changes are needed.** | | |
| 2 | Choose OK/close the message. Look at the address fields. | Unchanged. **Address Validated** = **Yes**. | | |
| 3 | Open **USPS Validation Log** for the customer. | A new top entry **Result = Confirmed**, **Accepted = No**. | | |

### TC-06 Suggestion ignored, then Esc (FRD tests 3, 17)
**Covers:** FRD tests 3 and 17, FR-4 · **Language:** en-US · **Needs live USPS:** **Yes** · **Run as:** Normal tester
*Precondition:* use a second customer like C-TYPO that has the typo address again (create **Test Typo 2** with the same typo address) and Address Validated = No.
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | Open Test Typo 2, choose **Validate Address (USPS)**. In the dialog choose **Cancel**. | Dialog closes. Address fields unchanged. **Address Validated** still **No**. | | |
| 2 | Choose **Validate Address (USPS)** again. This time press **Esc** on the keyboard (a manual check; the automated tests only press Cancel). | Dialog closes. Address fields unchanged. Address Validated still **No**. | | |
| 3 | Open the **USPS Validation Log** for this customer. | Two entries, both **Result = Suggestion Ignored**, **Accepted = No**. | | |
| 4 | Ignore starting from **Yes**. | Not repeatable by hand (editing the address resets the flag, and a validated address gets the Confirmed message, not the dialog). Covered by the automated test `TestCancelLeavesFlagUnchanged`. Write N/A. | n/a | |

### TC-07 Not found (FRD test 4)
**Covers:** FRD test 4, FR-7 · **Language:** en-US · **Needs live USPS:** **Yes** · **Run as:** Normal tester
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | Open **C-NOWHERE** (1 Nowhere Lane, Springfield, IL 62701) and choose **Validate Address (USPS)**. | A message that begins **USPS could not find this address:** followed by the USPS reason. No dialog. The address is unchanged. | | |
| 2 | Open the **USPS Validation Log** for this customer. | One entry **Result = Not Found**, **Accepted = No**, **USPS Message** holds the USPS reason, USPS Address columns are blank. | | |

### TC-08 Address Validated indicator (FRD tests 15-20)
**Covers:** FRD tests 19, 18, 20, FR-8 · **Language:** en-US · **Needs live USPS:** No for steps 1-4, **Yes** for step 5 · **Run as:** Normal tester
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | Create a **new customer** with **Customers > New**, give it a name and an address, and look at the card without running any check. | **Address Validated** is **No**. | | |
| 2 | Find the field on the card: **Address & Contact** FastTab, **Address** group, just after **ZIP Code**. | **Address Validated** is shown there. | | |
| 3 | Click **Address Validated**. | It cannot be edited (no cursor, no tick box to change). Its tooltip reads **Specifies whether the current address was confirmed by USPS or accepted from USPS. It is set by Validate Address (USPS) and cleared when the address is edited.** | | |
| 4 | Open **Customers** (the list). | The field is only on the card, not in the list (not requested). | | |
| 5 | Open **C-TYPO** after TC-04 (flag **Yes**). Change **City** by one letter, press Tab. | **Address Validated** changes to **No** as soon as you leave the City field (or when the card saves). Changing only **Country/Region Code** does **not** reset it. | | |

### TC-09 Log page
**Covers:** FRD FR-5 · **Language:** en-US · **Needs live USPS:** No (any check that reaches USPS, including a credentials error, writes a log row) · **Run as:** Admin tester, then Normal tester
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | Search for **USPS Validation Log** and open it. | A list with the newest entry first (highest **Entry No.** on top). Columns include **Entry No., Customer No., Checked At, User ID, Result, Accepted, Original Address ... Original ZIP Code, USPS Address ... USPS ZIP Code, Delivery Point Confirmation, Match Codes, Correction Codes, USPS Message, HTTP Status, Environment**. | | |
| 2 | Try to edit a cell, add a row, or delete a row. | Not possible; the list is read-only. | | |
| 3 | Look for any column that holds a key, secret, token or web address. | None. | | |
| 4 | As **Normal tester**, try to delete an entry (select the row, look for Delete). | Not possible. Only administrators (ADMIN set) can delete, normally through Retention Policy. | | |

### TC-10 Unsaved edit is the one sent (FRD test 13)
**Covers:** FRD test 13, FR-1 step 2 · **Language:** en-US · **Needs live USPS:** No (the log row is written even when the credentials are rejected; with real credentials the dialog shows the same address) · **Run as:** Normal tester
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | Open **C-ROOT**. Change **Address** to **999 Test Avenue** and **do not** leave the card, do not press anything else. | Card shows the edit. | | |
| 2 | Immediately choose **Validate Address (USPS)**. | The check starts without asking you to save (the card saves first). | | |
| 3 | When the check ends (dialog, message or error), open the **USPS Validation Log** for **C-ROOT**. | The newest entry's **Original Address** is **999 Test Avenue**. | | |

### TC-11 Contact sync after Accept (Gap G17, FRD §4.1 h)
**Covers:** FR-9, OQ-12, Gap Analysis G17 · **Language:** en-US · **Needs live USPS:** **Yes** · **Run as:** Admin tester
*Precondition:* customer created from a contact so a linked Contact exists (for example create a Company Contact with the typo address, then **Create as Customer**; or take a demo customer which has a Business Relation).
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | Note the Customer's address and the linked Contact's address (search **Contacts**, open the contact with the same name). | Both addresses noted: ______ | | |
| 2 | On the customer run **Validate Address (USPS)** and **OK** (Accept). | Customer address = USPS values. | | |
| 3 | Open the linked Contact. | The Contact's address is now the USPS address too (expected by FR-9). **If it still holds the old address, that is a finding: write it in Notes and report it (Gap G17 / FRD §4.1 h).** | | |

### TC-12 Time zones (FRD test 11)
**Covers:** FRD test 11, FR-5 · **Language:** en-US · **Needs live USPS:** No (any log row will do) · **Run as:** two users
*Precondition:* at least one log entry exists.
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | User A: choose the gear icon > **My Settings**, set **Time Zone** to Eastern time, **OK**. Open the **USPS Validation Log** and note **Checked At** of entry ____. | Time noted: ______ | | |
| 2 | User B (second window): in **My Settings** set **Time Zone** to Pacific time. Open the same log entry. | **Checked At** is three hours earlier than User A's value for the same entry. | | |

### TC-13 Rename of a customer keeps its log rows
**Covers:** Step 09 CR9-06 / TDD §13.7 F14 · **Language:** en-US · **Needs live USPS:** No (an Error log row from TC-21 is enough) · **Run as:** Admin tester
*Precondition:* customer **C-ROOT** has at least one entry in its **USPS Validation Log**. If not, run **Validate Address (USPS)** on it once (any outcome that reaches USPS writes a row).
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | Open **C-ROOT**'s card. Open **Related > Customer > USPS Validation Log** and count the rows: ____ | Count noted. | | |
| 2 | Close the log. On the card change the **No.** field to a new unused number (for example add **R** at the end). Confirm the rename question. | The card shows the new number. | | |
| 3 | Open **USPS Validation Log** from the renamed customer. | The same number of rows as in step 1. Their **Customer No.** is the new number. | | |
| 4 | Open the unfiltered log (search **USPS Validation Log**). | No row still shows the old number. | | |

### TC-14 Platform checks only a sandbox can answer (Gap G17, OQ-19, OQ-20)
**Covers:** OQ-19, OQ-20, F28 · **Language:** en-US · **Needs live USPS:** No · **Run as:** Admin tester
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | Open a Customer Card (US company). Look at the Address group. | The captions read **State** and **ZIP Code** (not County / Post Code). Write down what you see: ______ | | |
| 2 | Open a customer whose **Country/Region Code** is **blank**. Is the **State** field visible? | Write down: Visible / Not visible. (If it is not visible, the check still works from the ZIP Code; report it either way.) | | |
| 3 | Search for **Extension Management**, select **USPS Address Validator**, choose **Manage > Configure** (or in the Admin Center: **Environments > the sandbox > Manage Apps > the extension**). Look at **Allow HttpClient Requests**. | Write down On or Off right after the install: ______. Needed **On** for the extension to work (OQ-20). | | |

### TC-15 Standards §11.3 client checks, adapted to this app
**Covers:** Standards §11.1-§11.3, Operating Rule for Step 07 · **Language:** en-US · **Needs live USPS:** No
**This app has no child list parts and no number series fields.** There is no list part on the card, the log cannot be added to by a user (read-only), and nothing is numbered by the extension. So the two standard checks reduce to this: the single parent-to-child entry point is the **USPS Validation Log** action on the Customer Card.
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | *Child from every parent entry point.* On a customer that already has at least one log row, choose **Related > Customer > USPS Validation Log** (the only such action). | The log opens showing only that customer's rows; each row has **Customer No.** equal to the customer's number; no banner **The view is filtered, and the entry is outside the filter**. | | |
| 2 | Run **Validate Address (USPS)** (any outcome that reaches USPS), then choose **USPS Validation Log** again. | The new row is at the top of the filtered list, with the customer's number filled in; the banner above never appears. | | |
| 3 | Open the unfiltered log (search **USPS Validation Log**). | No row has a blank **Customer No.** | | |
| 4 | *Number series.* | **N/A - this extension has no number series field, no number series on the setup card or the wizard, and creates no numbered records.** | n/a | |

## 3. Test cases - red team (it fails safely)

For every red-team case: **nothing may change on the customer and the message must be the exact text shown.** A message that is different, missing, or a raw platform error is a failure.

### TC-16 Incomplete address
**Covers:** FR-1 step 3, FR-7 · **Needs live USPS:** No · **Run as:** Normal tester
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | Open **C-BLANK** (all address fields empty). Choose **Validate Address (USPS)**. | Message **Enter a street address and either city and state or ZIP Code.** | | |
| 2 | Open its **USPS Validation Log**. | Empty (no row; nothing was sent). | | |
| 3 | Give **C-BLANK** Address **123 Main Street** and Post Code **ABCDE** only, run the action. | The same message (ABCDE is not ZIP-like). | | |

### TC-17 Bad state code
**Covers:** FR-1 step 3, FR-7 · **Needs live USPS:** No · **Run as:** Normal tester
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | Open **C-BADSTATE** (State = Illinois, ZIP Code empty). Choose **Validate Address (USPS)**. | Message **Enter the 2-letter state code in the State field.** | | |
| 2 | Open its log. | Empty. | | |

### TC-18 Non-US customer (FRD test 7)
**Covers:** FRD test 7 · **Needs live USPS:** No · **Run as:** Normal tester
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | Open **C-CANADA** (Country/Region **CA**). Choose **Validate Address (USPS)**. | Message **USPS validates US addresses only.** No dialog. | | |
| 2 | Open its log. | Empty. Nothing was sent. | | |

### TC-19 Disabled setup
**Covers:** FR-1 step 3, FR-6 · **Needs live USPS:** No · **Run as:** Admin tester, then Normal tester
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | Admin: open **USPS Address Validation Setup**, turn **Enabled** off. | Saved. | | |
| 2 | Normal tester: open **C-ROOT**, choose **Validate Address (USPS)**. | Message **USPS address validation is not set up. Contact your administrator.** | | |
| 3 | Open the log for **C-ROOT**. | No new row. | | |
| 4 | Admin: turn **Enabled** back on. | Saved. | | |

### TC-20 No credentials
**Covers:** FR-1 step 3 · **Needs live USPS:** No · **Run as:** Admin tester, then Normal tester
*Precondition:* a company where no credentials have been entered yet (a fresh test company, before TC-02). Do this case first.
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | Admin: open **USPS Address Validation Setup**, turn **Enabled** on, enter nothing else. | Saved. | | |
| 2 | Normal tester: open a customer with a full address and choose **Validate Address (USPS)**. | Message **USPS address validation is not set up. Contact your administrator.** Log: no new row. | | |

### TC-21 Wrong credentials (FRD test 8)
**Covers:** FRD test 8, FR-7 · **Needs live USPS:** No real credentials; needs an internet connection · **Run as:** Normal tester
*Precondition:* Enabled; Consumer Key and Secret are made-up text; privacy notice agreed.
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | Open **C-ROOT**, choose **Validate Address (USPS)**. | Message **USPS rejected the credentials. Contact your administrator.** The address is unchanged. | | |
| 2 | Open the log for **C-ROOT**. | A new row: **Result = Error**, **HTTP Status = 401** (it may be 400 or 403 depending on how USPS answers; write it down), **USPS Message** holds the USPS text. | | |
| 3 | If the sandbox cannot reach the internet, the message in step 1 is instead **USPS is not responding. Try again later.** and the HTTP Status is **0**. Write which case you saw. | | | |

### TC-22 Hourly limit and USPS down
**Covers:** FRD test 9 · **Needs live USPS:** n/a
**N/A for a manual run.** The hourly-limit (HTTP 429) message and the no-response message cannot be forced by hand. They are covered by the automated tests `TestQuotaNoRetry`, `TestNoResponseNoRetry` and `TestServerErrorLogged`. Write N/A.

### TC-23 User without permission to modify customers (FRD test 12)
**Covers:** FRD test 12, OQ-21 · **Needs live USPS:** **Yes** · **Run as:** Read-only tester
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | Sign in as the Read-only tester. Open a fresh customer with the typo address (a new copy of C-TYPO). Choose **Validate Address (USPS)**. | The check runs and the dialog opens. | | |
| 2 | Look under **Delivery notes** in the dialog. | A red line **You can't accept the USPS address because you don't have permission to change customers. Choose OK or Cancel to close without changes.** | | |
| 3 | Choose **OK**. | Dialog closes. The customer is unchanged. **Address Validated** unchanged. | | |
| 4 | Open the log. | One row **Result = Suggestion Ignored**, **Accepted = No**. | | |

### TC-24 Address changed while the dialog is open
**Covers:** FR-4, Gap Analysis A2 (TDD §13.5) · **Needs live USPS:** **Yes** · **Run as:** two users
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | Window 1 (user A): open a customer with the typo address and choose **Validate Address (USPS)** so the dialog is open. **Leave it open.** | Dialog shown. | | |
| 2 | Window 2 (user B): open the same customer, change **City** to **Elsewhere**, press Tab so it saves. | Saved. | | |
| 3 | Window 1: choose **OK**. | Message **The customer's address was changed while the USPS suggestion was open, so nothing was updated. Run Validate Address (USPS) again.** | | |
| 4 | Reload the customer card in window 1. | **City** is **Elsewhere** (user B's value); the USPS values were not written. | | |
| 5 | Open the log. | A row **Suggestion Ignored**, **Accepted = No**. | | |

### TC-25 Privacy notice refused
**Covers:** FR-1 step 3, Step 09 CR9-04 · **Needs live USPS:** No · **Run as:** Admin tester (or a user who has not answered the notice)
*Precondition:* the notice is not yet agreed. (If it is, ask an administrator to reset it on the **Privacy Notices** page, or use a freshly created sandbox company; if you cannot, write N/A and why.)
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | Open **C-ROOT**, choose **Validate Address (USPS)**. In the **Privacy Notice** page choose **Disagree**. | Message **The privacy notice for sending addresses to USPS has not been agreed to, so nothing was sent.** | | |
| 2 | Open the log. | No new row. | | |
| 3 | Open **USPS Address Validation Setup** and choose **Test Connection**; Disagree again. | Error **The privacy notice for sending addresses to USPS has not been agreed to, so the connection was not tested.** | | |

### TC-26 USPS value too long
**Covers:** FR-4 ("Accept is blocked"), A1 · **Needs live USPS:** **Yes** and a lucky address · **Run as:** Normal tester
**Not repeatable on demand.** It only happens if USPS returns a value longer than the customer field (for example a City over 30 characters). It is covered by the automated test `TestTooLongBlocksAccept`. If you ever see the red text **You can't accept the USPS address because the USPS value for ... is longer than ... characters. Choose OK or Cancel to close without changes.**, choose OK and confirm the customer is unchanged and the log shows **Suggestion Ignored**; otherwise write N/A.

### TC-27 "Allow HttpClient Requests" switched off (Gap G5)
**Covers:** Gap Analysis G5 · **Needs live USPS:** No · **Run as:** Admin tester · **Sandbox only**
| Step | Action | Expected result | Pass / Fail | Notes |
|---|---|---|---|---|
| 1 | Admin: **Extension Management** > select **USPS Address Validator** > **Manage > Configure**. Turn **Allow HttpClient Requests** **Off**, save. | Saved. | | |
| 2 | Normal tester: open **C-ROOT**, choose **Validate Address (USPS)** (setup enabled, made-up credentials, privacy notice agreed). | **Write down the exact message.** The design expects an error message and an Error row in the log. | | |
| 3 | Open the log for **C-ROOT**. | **Is there a new row with Result = Error?** Write Yes/No. **If a message appeared but there is no new log row, report it: that is Gap G5.** | | |
| 4 | Admin: turn **Allow HttpClient Requests** back **On**. | Saved. | | |

## 4. Language pass
Only **English (United States)** is required at first release; no translation files exist (FRD §8). The tester checks the US wording:
| Page | Term (W1) | Expected in en-US |
|---|---|---|
| Customer Card | County | **State** |
| Customer Card | Post Code | **ZIP Code** |
| Comparison dialog | rows | **Address, Address 2, City, State, ZIP Code**; columns **Current (BC)** and **USPS suggestion** |
| Messages | | the texts quoted in the cases above |

## 5. Results
Recorded in `docs/4-prove/ReleaseTestResults.md` at Step 12, not here. Keep your own copy of this script with the Pass / Fail column filled in and attach it.

### Reporting a failure
For every Fail (and every Blocked), send the agent:
1. The **TC number and step** (for example TC-04 step 3) and the **version** (0.0.0.4).
2. What you did, in your own words, and what you expected.
3. The **exact text** of any message (choose **Copy details** on the error if it is offered, otherwise a screenshot), exactly as shown.
4. The **customer number**, your **user**, and the **time**.
5. The **entry number** of the matching row in the **USPS Validation Log**, if there is one, and a screenshot of that row.
Do not retest on a different build and do not edit the script's expected results; report what you saw.

## Before calling this done
- [ ] Every FRD requirement is covered by at least one TC (table in §1.1; tests 5, 6, 9, 10 are automated-only, stated there).
- [ ] Every permission set, every deletion rule, and every error message has a red-team TC (permission: TC-23; deletion: TC-09 step 4; error messages: TC-16 to TC-27).
- [ ] Every parent→child entry point has a green-team TC: the only one is the **USPS Validation Log** action (TC-15); the log is read-only so no child can be created by hand.
- [ ] Every number-series field has a green-team TC: **none exists in this extension** (TC-15 step 4).
- [ ] A non-developer can run every step without asking a developer.
