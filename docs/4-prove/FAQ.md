# Google Address Validator — Frequently Asked Questions

**Version:** 1.3.0.3 · **Date:** 2026-10-20 · **Language:** English (United States) · **For:** Business Central users who validate addresses, and the administrator who sets the extension up

> Every answer here comes from the User Guide, the Google Setup guide, or the messages the extension shows. Section numbers refer to the User Guide.

## Using the extension

### Does the extension change my customer's address by itself?
Never. The address changes only when you choose **OK** in the suggestion window.

### Which data is sent to Google?
Only the address, city, state and ZIP / postal code, together with the two-letter country code when the record's country is known. The customer's name and number are not sent.

### Can I validate all my customers at once?
No. This version works one record at a time, on request. It is for interactive use only, not for scheduled jobs or integrations.

### Which records can I check?
The Customer Card and 15 more cards: Ship-to Address, Customer Bank Account, Vendor, Order Address, Remit Address, Vendor Bank Account, Company Information (the company address and the ship-to address), Location, Responsibility Center, Bank Account, Employee, Alternative Address, Contact, Contact Alternative Address and Resource. Sales documents, purchase documents, lists and the other tables in section 4.10 cannot be checked.

### Can I check an address outside the United States?
Yes, in the 40 countries on the Supported Countries page (section 4.12), unless an administrator switched the country off. A country Google does not cover, such as Russia, is refused before anything is sent.

### What happens if the record has no Country/Region Code?
It depends on the **Blank Country Handling** setting (section 4.12). By default Google works the country out from the address, and a blank Country/Region Code is filled in from the country Google found.

### Why is Address Validated switched off again?
Someone edited the address after it was validated, someone changed the Country/Region Code (even from blank to the US code), or a later check could not confirm it (section 4.4). On a contact, employee or other linked record it can also follow the record it is linked to (section 4.8).

### I validated a vendor. Why did its contact change as well?
Business Central keeps a vendor's contact in step with the vendor, and the extension keeps the **Address Validated** field in step too (section 4.8).

### I validated the company address. Why is the ship-to address still not validated?
They are checked separately (section 4.7).

### Why does a note say "USPS"?
Google's answer includes US Postal Service delivery data for addresses in the United States and Puerto Rico. Other countries do not have it.

## Permissions and the log

### Which permissions do I need?
To validate addresses you need the `OBCFGAV GAV, USE` permission set. To set the extension up or enter the API key you need `OBCFGAV GAV, ADMIN`. Your administrator assigns them on the **Users** page (section 2).

### Why can I see the suggestion but not accept it?
Accepting needs permission to modify the kind of record you are checking, for example customers. The reason line in the window tells you. Ask your administrator for modify permission on that table.

### Why does Validate Address say the record is blocked due to privacy?
**Privacy Blocked** is on for the record, or for the customer, vendor, employee or contact it belongs to (section 4.9). Nothing was sent or logged.

### Why does the Google Address Validation Log not show entries I know exist?
The log shows you only the entries for the kinds of record you may read yourself (section 4.5). Ask your administrator if you need to see more.

### I deleted a record. Why is its entry still in the log?
The log keeps the record's key and address until the Retention Policy deletes the row (section 4.5). An administrator must switch the Retention Policy on; it starts switched off, and the planned retention is 2 years.

## Cost and Google

### Does it cost money?
Each check is one request on your company's own Google Cloud project. Google's free allowance (5,000 requests a month, shared by all countries and users of the key) covers low volume, then it is about $17 per 1,000 (section 4.12). Check Google's billing report after your first tests to confirm. A billing account on India pricing gets 35,000 free requests instead.

### Do I need my own Google API key?
Yes. The key belongs to your company's Google Cloud project, which needs billing turned on and the Address Validation API enabled. The extension does not supply a key. The Google Setup tab explains each step.

### Does Google need a payment method even if I stay in the free allowance?
Yes. Google requires a billing account with a payment method even when you stay inside the free allowance.

### How do I stop unexpected spending?
Set a daily quota cap on the Address Validation API in Google Cloud. A budget alert only warns you; a quota cap makes the API stop answering when it is reached (Google Setup, steps 6 and 7).

### What if the API key leaks?
Rotate it in Google Cloud: the new key keeps the old key's restrictions, and both work during the transition. Paste the new key into Business Central, confirm checks work, then delete the previous key (Google Setup, "Rotating the key").

## Problems and messages

### It says "Address validation is not set up". What now?
The service is switched off or the API key is missing. Nothing was sent. Tell your administrator (section 4.1).

### It says "Google Maps rejected the API key". What now?
The key was typed wrongly, deleted, or belongs to another project. The administrator checks or replaces the key and runs **Test Connection**.

### It says the Address Validation API or billing is not enabled. What now?
The administrator enables the Address Validation API, or links a paid billing account, on the Google Cloud project that owns the key.

### It says "The Google Maps request limit has been reached". What now?
A quota or the daily cap set in Google Cloud was reached. All users share the one key. Wait and try again later; the administrator can review the cap.

### It says "Google Maps is not responding". What now?
Google had a server problem, took longer than **Timeout (Seconds)**, or could not be reached. Try again later. If it keeps happening, tell your administrator: the environment may not be allowed to make outside web calls, so **Allow HttpClient Requests** should be checked.

### It says "Google Maps couldn't confirm this address". What now?
Google answered but could not confirm the address to the building. Check the spelling and add the missing detail, such as a suite number or ZIP code, then try again.

### It says "Enter the 2-letter state or province code". What now?
In the US, Puerto Rico and Canada the State field must be a two-letter code such as `WA` or `ON`.

### It says the country isn't turned on. What now?
The country is covered by Google but an administrator switched it off. Ask your administrator to turn it on in Google Address Validation Supported Countries (section 4.12).

### It says Google can't tell which country the record is in. What now?
The record's country has no ISO Code. An administrator fills in the ISO Code of that country on the Countries/Regions page.

### The address was changed while the suggestion was open. What now?
Nothing was updated. Run Validate Address again.
