# USPS Address Validator — User Guide

**Version:** 0.0.0.4 · **Date:** 2026-10-16 · **Language:** English (United States) · **For:** customer service and sales administration staff who maintain customers, and the Business Central administrator who sets the extension up

## 1. What this extension does for you
USPS Address Validator checks a customer's address against the United States Postal Service while you are on the Customer Card. You see your address and the USPS version side by side, and you can accept the USPS version with one click or keep what you have. A read-only **Address Validated** field on the customer tells you whether the current address has been confirmed by USPS, and every check that reaches USPS is written to a log.

## 2. Before you start
- **Permission set.** To validate addresses you need `OBCFUSPS USPS, USE` ("USPS Address Validator - Use"). To set the extension up, enter the credentials, or work with the setup page, you need `OBCFUSPS USPS, ADMIN` ("USPS Address Validator - Admin"). Your Business Central administrator assigns these on the **Users** page.
- **To accept a suggested address** you also need permission to modify customers. Without it you can still run the check and see the suggestion, but you cannot accept it.
- **Setup must be done once per company**, by an administrator (section 4.1). Until then the check tells you that validation is not set up.
- **The credentials are your company's own.** The Consumer Key and Consumer Secret come from a USPS developer account that your company holds. The extension does not supply them.
- **A word about USPS access.** USPS now asks for a license or paid usage, and getting onboarded to the USPS service may currently be blocked. A change of address-check provider is under discussion but has not been decided. Until credentials are in place, validation cannot run.
- **Only US addresses can be checked.** Customers in other countries cannot be validated.

## 3. Getting there
- **Validating an address:** open a customer (search for **Customers**, then open the **Customer Card**). The action is **Validate Address (USPS)**, shown on the ribbon and also under **Actions**, then **Functions**.
- **The Address Validated field:** on the Customer Card, in the Address & Contact FastTab, right after **Post Code**.
- **The log for one customer:** on the Customer Card, under **Customer**, choose **USPS Validation Log**. The whole log is also found by searching for **USPS Validation Log**.
- **Setup (administrator):** search for **Assisted Setup** and choose **Set up USPS address validation**, or search for **USPS Address Validation Setup**.

## 4. Tasks

### 4.1 Set up the extension for the first time (administrator)
1. Search for **Assisted Setup** and choose **Set up USPS address validation**. (The guided setup is the same page as **Set Up USPS Address Validation**.)
2. On the **Welcome** step choose **Next**. It reminds you that you choose the environment, turn the service on and test the connection on the setup page afterwards.
3. On the **USPS Credentials** step enter the **Consumer Key** and **Consumer Secret** from your USPS developer account. **Next** stays unavailable until both are filled in.
4. On the last step (**That's it!**) choose **Finish** to save the credentials. They are stored securely for this company and are not shown again.
5. Search for **USPS Address Validation Setup** and open it. Check these fields:
   - **Enabled** – switch this **on**. It starts off, and nothing is sent to USPS while it is off.
   - **Environment** – **Test (TEM)** (the starting value) or **Production**. See the note below.
   - **US Country/Region Code** – the code that stands for the United States (starts as `US`). Only customers with this code, or no country code, are checked.
   - **Timeout (Seconds)** – how long to wait for USPS to answer (starts at 10).
   - **Consumer Key** and **Consumer Secret** – shown masked. You can also enter or replace them here instead of using the wizard. The secret cannot be read back after you save it.
6. Choose **Test Connection**. The first time, Business Central asks you to agree to a privacy notice, "USPS Address Validation", because customer addresses are sent to USPS. Choose to agree. When the credentials work, you see *The connection to USPS works. A token was received.* Test Connection checks the credentials only; no address is sent and no address quota is used.
> **Note – Test (TEM) vs Production:** the Test (TEM) environment is for trying things out, but it **still uses your real production Consumer Key and Consumer Secret** (the setup page reminds you of this). Production checks count against your real USPS hourly quota. Each log entry records which environment was used.

### 4.2 Validate a customer's address
1. Open the **Customer Card** of a US customer.
2. Make sure **Address** and either **City** and **State** or a **Post Code** (ZIP Code) are filled in, and that **State** is the 2-letter code (for example `WA`).
3. Choose **Validate Address (USPS)**. Any unsaved changes on the card are saved first, so USPS checks what you see.
4. The first time you validate, Business Central may show the privacy notice for sending addresses to USPS. If an administrator has already agreed, you are not asked again. If you do not agree, nothing is sent and nothing is logged.
5. Wait a moment while USPS answers. What happens next depends on the answer:
   - **The address is already right.** A message says *The address is confirmed by USPS. No changes are needed.* Nothing on the customer is changed, except that **Address Validated** is switched on. (Differences in upper or lower case alone do not count as a difference.)
   - **USPS suggests a different address.** The **USPS Address Suggestion** window opens. Continue with 4.3.
   - **USPS cannot find the address, or an error occurs.** You see a message. Section 5 explains each one.
> **Tip:** the check is deliberately one customer at a time, on request. There is no automatic or bulk validation.

### 4.3 Read the USPS Address Suggestion window and accept or ignore
1. The window shows two columns: **Current (BC)**, which is what is on the customer now, and **USPS suggestion**. The rows are Address, Address 2, City, State and ZIP Code. Anything USPS would change is shown in **bold**.
2. Under **Delivery notes** you may see a highlighted warning and notes from USPS:
   - *The suite or apartment number is missing.*
   - *USPS could not confirm the suite or apartment number.*
   - *USPS could not confirm this address for delivery.*
   - *USPS reports that this address is vacant.*
   - *USPS reports that this is a business address.*
   - any other text USPS returned.
   A warning does not stop you from accepting; use your judgment, or find out the missing detail from the customer first.
3. To **accept**, choose **OK**. The customer's Address, Address 2, City, State and ZIP Code are replaced with exactly what USPS returned (in upper case, with the ZIP+4 when USPS gave one), and **Address Validated** is switched on. Because the address on the card is updated through the normal save, Business Central also keeps the linked contact's address in step.
4. To **ignore**, choose **Cancel** (or close the window). Nothing on the customer changes, and **Address Validated** stays as it was.
5. Sometimes OK cannot accept the suggestion. A red line titled *Reason you can't accept* then explains why, and OK behaves like Cancel:
   - *You can't accept the USPS address because you don't have permission to change customers. Choose OK or Cancel to close without changes.*
   - *You can't accept the USPS address because the USPS value for Address (or Address 2, City, State, ZIP Code) is longer than N characters. Choose OK or Cancel to close without changes.* Nothing is cut off; correct the address by hand if you want to.
   - If someone changed the customer's address while the window was open, nothing is updated and you see *The customer's address was changed while the USPS suggestion was open, so nothing was updated. Run Validate Address (USPS) again.*
> **Note:** accepting does not update open sales or service documents; they keep the address they were created with. The customer's **Tax Area Code** is also not re-evaluated after a new address is accepted, so check it yourself if tax depends on the address.

### 4.4 Understand the Address Validated field
- It is **No** for every new customer, and for existing customers when the extension is installed. You cannot edit it by hand.
- It becomes **Yes** when a check ends with the address confirmed or the USPS suggestion accepted. (For someone without permission to modify customers, a confirmed address does not set it.)
- It stays as it was when you ignore a suggestion, when you cannot accept one, and when an error happens.
- It goes back to **No** when USPS cannot find the address (for people allowed to modify customers), and when someone later edits the customer's Address, Address 2, City, State or ZIP Code. Changing only the Country/Region does not reset it.
> **Note:** changes made by an import or another integration that bypass the normal field checks may not reset the field.

### 4.5 View the USPS Validation Log
1. On the Customer Card choose **Customer**, then **USPS Validation Log** to see that customer's checks, newest first. Or search for **USPS Validation Log** for every customer.
2. Each line shows the customer, when it was checked (in your own time zone), who ran it, the **Result** (Confirmed, Suggestion Accepted, Suggestion Ignored, Not Found or Error), whether it was **Accepted**, the address that was sent and the address USPS returned, the delivery point confirmation, match and correction codes, the USPS message, the HTTP status (0 means no answer was received) and the environment.
3. The log is read-only. Only administrators can delete entries, and normally this happens by itself through the Retention Policy (section 7). The log keeps entries for customers that were later deleted.
> **Tip:** the log is also where to look for the full USPS text of an error, which the pop-up message does not always show.

## 5. Messages you may see
| Message | What it means | What to do |
|---|---|---|
| USPS address validation is not set up. Contact your administrator. | The service is switched off, or the Consumer Key or Secret is missing, or no environment is chosen. Nothing was sent. | Tell your administrator (section 4.1). |
| USPS validates US addresses only. | The customer's Country/Region Code is not the US code from the setup page. | Nothing to do for a non-US customer. If the code is wrong, correct it. |
| Enter a street address and either city and state or ZIP Code. | Address is empty, or there is neither city and state nor a ZIP Code. | Fill them in, save, and run the check again. |
| Enter the 2-letter state code in the State field. | The State is not a 2-letter code such as `WA`. | Use the 2-letter code. |
| The privacy notice for sending addresses to USPS has not been agreed to, so nothing was sent. | You (or your administrator) did not agree to the privacy notice. | Run the action again and agree, or ask your administrator. |
| USPS could not read the address: *(USPS text)* | USPS rejected the request as malformed. Logged as Error. | Check the address for odd characters or a missing field and try again. |
| USPS could not find this address: *(USPS text)* | No match, not enough data, an invalid delivery address, or several possible matches. Logged as Not Found. **Address Validated** goes back to No if you may modify customers. | Check the spelling and add the missing detail (suite number, ZIP Code), then try again. |
| USPS rejected the credentials. Contact your administrator. | The Consumer Key or Secret was refused, even after one retry. Logged as Error. | Administrator: re-enter the credentials from the USPS developer account and run **Test Connection**. |
| The hourly USPS limit has been reached. Try again later. | USPS limits how many address checks can be made per hour for the credentials, and all users share them. Logged as Error. | Wait and try again later. |
| USPS is not responding. Try again later. | USPS had a server problem, took longer than the **Timeout (Seconds)**, or could not be reached. Logged as Error. | Try again later. If it keeps happening, tell your administrator; the environment may not be allowed to make outside web calls (see the Deployment guide). |
| Unexpected response from USPS. Contact your administrator. | USPS answered in a way the extension cannot read. Logged as Error. | Tell your administrator. |
| The connection to USPS failed. *(reason)* USPS message: *(text)* | Shown by **Test Connection** when the token request fails. | Check the credentials and the **Environment**, then try again. |
| Enter the Consumer Key and Consumer Secret first. / Select the USPS environment first. | Test Connection was run before these were filled in. | Fill them in on the setup page. |
| The privacy notice for sending addresses to USPS has not been agreed to, so the connection was not tested. | Test Connection needs the privacy notice to be agreed to. | Run it again and agree. |
| (a Business Central error text after you chose OK) | The USPS answer was fine but saving the customer failed (for example a permission or another extension stopped the save). The customer is unchanged and the check is logged as Error. | Report the text to your administrator. |

## 6. Frequently asked questions
**Q.** Does the extension change my customer's address by itself?
**A.** Never. The address changes only when you choose **OK** in the suggestion window.

**Q.** Are the customer's name or number sent to USPS?
**A.** No. Only the address, city, state and ZIP Code are sent.

**Q.** Can I validate all my customers at once?
**A.** No. This version works one customer at a time, on request.

**Q.** Why is Address Validated switched off again?
**A.** Someone edited the address after it was validated, or a later check could not find the address (section 4.4).

**Q.** Can I check a Ship-to Address, vendor or contact?
**A.** Not in this version. Only the main address on the customer.

**Q.** Why can I see the suggestion but not accept it?
**A.** Accepting needs permission to modify customers. The red reason line in the window tells you.

**Q.** Can I use the extension while USPS onboarding is blocked?
**A.** No. It needs credentials from your own USPS developer account. A change of provider is being discussed but has not been decided.

## 7. Getting help
Contact your Business Central administrator. Include the customer number, the time of the check, the exact message you saw, and the matching line from the **USPS Validation Log** (its **USPS Message** and **HTTP Status** columns). Administrators can find installation and permission details in `docs/4-prove/Deployment.md`.

The USPS Validation Log is cleaned up by Business Central's Retention Policy, which an administrator must switch on (it starts switched off). The planned retention is 2 years.

## Before calling this done
- [x] Every user-facing page and action from the Object Register appears in a task (setup wizard, setup card and Test Connection, Customer Card action, Address Validated field, comparison window, log).
- [x] Terminology matches this language's BC translation (glossary), not a literal translation. N/A beyond US wording: single language en-US, no translation files.
- [x] Screenshots or captions, if any, are from the actual build. No screenshots; captions were checked against the code of version 0.0.0.4. Nothing has been installed or run in a tenant yet, so the wording of Business Central's own pages (Assisted Setup, the privacy notice dialog) is unconfirmed.
