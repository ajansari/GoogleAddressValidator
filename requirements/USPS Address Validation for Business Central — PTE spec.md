# USPS Address Validation for Business Central — PTE spec

Oct 10, 2026 · @AJ Ansari

A per-tenant extension adds a Validate Address action to the Customer Card that sends the customer's address to the free USPS Addresses 3.0 API, shows the USPS version beside the BC version, lets the user accept or ignore it, and logs every check.

## What we need from USPS

We need one USPS business account, one registered app, and that app's Consumer Key and Consumer Secret. There is no fee. The old Web Tools XML API (user ID only) was retired on January 25, 2026, so the OAuth-based API below is the only option.

- [ ] Create or sign in to a USPS Business Account through the [Customer Onboarding Portal](https://cop.usps.com/cop-navigator?wf=API&showCC=false). It configures the account for APIs.
- [ ] In the portal, open My Apps and add an app (suggested name: `BC Address Validation`).
- [ ] Copy the Consumer Key and Consumer Secret from the app's Credentials section. These become `client_id` and `client_secret`.
- [ ] Confirm the app's product includes Addresses. The default product does.
- [ ] Have an authorized company representative accept the [USPS API terms](https://developers.usps.com/terms-and-conditions). See Constraints and risks.
- [ ] Decide who owns the USPS account long term. Credentials are tied to it and must not be shared outside the company.

| Item | Value |
| --- | --- |
| Production base URL | `https://apis.usps.com` |
| Test base URL (TEM) | `https://apis-tem.usps.com`, used with the same production credentials |
| Token endpoint | `POST /oauth2/v3/token` |
| Address endpoint | `GET /addresses/v3/address` |
| Auth | OAuth 2.0 client credentials; bearer token in the `Authorization` header |
| OAuth scope | `addresses` |
| Default quota | About 60 calls per hour per API; HTTP 429 when exceeded |
| Quota increase | Service request through the USPS [Email Us](https://emailus.usps.com/s/usps-APIs) page; no published tiers |
| Support | Same Email Us page |

The 60 per hour figure comes from third-party reports. USPS's own pages confirm an hourly quota and the 429 response but do not print the number. Read the actual quota on the app's product page in the portal.

## Scope

Version 1 validates one customer's main address at a time, on demand, from the Customer Card.

| In scope | Out of scope for v1 |
| --- | --- |
| Validate Address action on the Customer Card | Automatic validation on address entry or save |
| US addresses only (Country/Region Code blank or the configured US code) | Non-US addresses |
| Side-by-side comparison dialog with Accept and Ignore | Ship-to Addresses, Vendors, Contacts, sales documents |
| Update of the customer's address fields on Accept | Batch or scheduled validation of many customers |
| Processing log of every check | Geocoding, residential/commercial rating, tax area updates |
| Setup page for credentials and environment |  |

Batch validation is excluded on purpose. The hourly quota makes it impractical, and USPS terms prohibit using the API to build or clean address lists.

## User flow

1. The user opens a Customer Card and chooses Validate Address (USPS). The action is promoted and also sits under Actions > Functions.
2. The app saves any unsaved changes on the card, then checks preconditions: setup is enabled, the country is US, and Address, plus either City and State or ZIP Code, are filled in.
3. The app gets a token (cached if still valid) and calls the USPS address endpoint.
4. The app compares the USPS address with the BC address and shows one of the outcomes below.
5. The app writes one log entry for every check that reaches USPS, whatever the outcome.

| Outcome | What the user sees | Customer updated | Log result |
| --- | --- | --- | --- |
| USPS address equals BC address | Message: address confirmed by USPS, no changes | No | Confirmed |
| USPS address differs | Comparison dialog with Accept and Ignore | Only on Accept | Suggestion accepted or Suggestion ignored |
| USPS finds no match, or several matches | Message with the USPS reason text | No | Not found |
| Quota exceeded, credential, network or server error | Error message with next step | No | Error |

### Comparison dialog

The dialog is a modal page with two columns, Current (BC) on the left and USPS suggestion on the right. Fields are read-only and changed values are shown in bold.

| Row | Current (BC) | USPS suggestion |
| --- | --- | --- |
| Address | 123 main street | 123 MAIN ST |
| Address 2 | suite 4 | STE 4 |
| City | Nashvile | NASHVILLE |
| State | TN | TN |
| ZIP Code | 37201 | 37201-1234 |

Below the grid the dialog shows USPS delivery notes when present: missing or unconfirmed suite/apartment number, vacant address, business address, and any correction text USPS returns.

- **Accept USPS Address** writes the five USPS values to the customer and closes the dialog.
- **Ignore** closes the dialog and changes nothing. Closing with X or Esc counts as Ignore.

### What counts as different

Values are compared after trimming spaces and ignoring upper/lower case. A new ZIP+4 on a 5-digit ZIP counts as a difference. If only letter case differs, the outcome is Confirmed and no dialog is shown.

## USPS API contract

Each check makes at most two HTTPS calls: one for a token when the cached one has expired, and one for the address. Both use AL `HttpClient` with a configurable timeout (default 10 seconds).

### Token

```
POST {base URL}/oauth2/v3/token
Content-Type: application/json

{ "client_id": "<Consumer Key>", "client_secret": "<Consumer Secret>", "grant_type": "client_credentials" }
```

The response carries `access_token`, `token_type` (Bearer), `issued_at`, `expires_in` (seconds) and `scope`. The app caches the token until 60 seconds before expiry, calculated from `expires_in`; the lifetime is never hard-coded. A 401 on the address call clears the cache and retries once with a new token.

### Address request

```
GET {base URL}/addresses/v3/address?streetAddress=...&secondaryAddress=...&city=...&state=...&ZIPCode=...&ZIPPlus4=...
Accept: application/json
Authorization: Bearer <access_token>
```

All values are URL-encoded. Empty parameters are omitted.

| USPS parameter | BC Customer field | Rule |
| --- | --- | --- |
| `streetAddress` | Address (Text 100) | Required |
| `secondaryAddress` | Address 2 (Text 50) | Sent when not blank |
| `city` | City (Text 30) | Required unless ZIP Code is present |
| `state` | County (Text 30) | Must be a 2-letter USPS state code; block the call otherwise |
| `ZIPCode` | Post Code (Code 20) | First 5 digits |
| `ZIPPlus4` | Post Code | The 4 digits after the first 5, with or without a hyphen; omitted if absent |

The request never includes the customer name or number. Confirm the required-parameter rules against the Addresses 3.0 spec in the portal during build; the spec page needs a signed-in session.

### Address response (HTTP 200)

```json
{
  "firm": null,
  "address": {
    "streetAddress": "3120 M ST NW",
    "secondaryAddress": null,
    "city": "WASHINGTON",
    "state": "DC",
    "ZIPCode": "20007",
    "ZIPPlus4": "3704",
    "urbanization": null
  },
  "additionalInfo": {
    "deliveryPoint": "20",
    "carrierRoute": "C036",
    "DPVConfirmation": "Y",
    "DPVCMRA": "N",
    "business": "Y",
    "centralDeliveryPoint": "N",
    "vacant": "N"
  },
  "corrections": [ { "code": "", "text": "" } ],
  "matches": [ { "code": "31", "text": "Single Response - exact match" } ]
}
```

| Response field | Used for |
| --- | --- |
| `address.streetAddress` | Suggested Address |
| `address.secondaryAddress` | Suggested Address 2 |
| `address.city` | Suggested City |
| `address.state` | Suggested State (County) |
| `address.ZIPCode` + `address.ZIPPlus4` | Suggested Post Code, written as `12345-6789`, or `12345` when no +4 is returned |
| `additionalInfo.DPVConfirmation` | Delivery note in the dialog; stored in the log |
| `additionalInfo.vacant`, `additionalInfo.business` | Delivery notes in the dialog |
| `corrections[].text`, `matches[].text` | Shown in the dialog; codes stored in the log |

`DPVConfirmation` values: Y = confirmed; D = street confirmed, suite or apartment missing; S = street confirmed, suite or apartment not recognized; N = not confirmed. For D, S and N the dialog shows a warning line but still allows Accept.

The parser reads fields by name and tolerates missing or extra fields. USPS reserves the right to change response formats without notice, and already renamed `addressAdditionalInfo` to `additionalInfo` in 2025.

## BC objects

The extension adds 2 tables, 2 enums, 3 pages, 1 page extension, 3 codeunits and 2 permission sets. Object IDs come from our PTE range (50000 to 99999); names take our standard affix.

| Type | Name | Purpose |
| --- | --- | --- |
| Table | USPS Addr. Validation Setup | Single-record setup |
| Table | USPS Addr. Validation Log | One entry per check |
| Enum | USPS Validation Result | Confirmed, Suggestion Accepted, Suggestion Ignored, Not Found, Error |
| Enum | USPS Environment | Production, Test (TEM) |
| Page (Card) | USPS Addr. Validation Setup | Credentials, environment, Test Connection action |
| Page (List) | USPS Addr. Validation Log | Read-only log, newest first |
| Page (StandardDialog) | USPS Address Comparison | Current vs. USPS suggestion, Accept and Ignore |
| Page extension | Customer Card | Validate Address (USPS) action; USPS Validation Log action filtered to the customer |
| Codeunit | USPS Address Validation | Orchestrates preconditions, call, comparison, dialog, update, log |
| Codeunit | USPS API Client | Token handling, HTTP calls, JSON parsing |
| Codeunit | USPS Addr. Validation Install | Registers the log table with Retention Policy |
| Permission set | USPS ADDR - USE | Run the action, read the log |
| Permission set | USPS ADDR - ADMIN | Setup, credentials, log deletion |

### Build notes

- **Transactions.** The HTTP call and the modal dialog run before any database write. The customer update and the log insert then happen in one transaction after the dialog closes. For error outcomes, the log entry is committed before the message is shown.
- **Writing the address.** Address and Address 2 are written with `Validate`. City, County and Post Code are assigned directly, then `Modify(true)`. Validating City or Post Code runs the standard Post Code table logic, which can overwrite the USPS values with a different city or ZIP.
- **Field lengths.** If a USPS value is longer than the BC field (City is 30 characters), Accept is blocked with a message. Nothing is truncated silently.
- **Concurrency.** Before writing, the app re-reads the customer and stops with a message if the address changed while the dialog was open.
- **Sandboxes.** Outbound HTTP can be blocked for extensions in sandboxes, notably ones copied from production. If calls fail there, turn on Allow HttpClient Requests for this extension in Extension Management.
- **Target.** BC online, runtime 12 (2023 wave 2) or later, so credentials can use `SecretText`.

## Processing log

Every check that reaches USPS writes exactly one log entry with the original address, the USPS address, whether the suggestion was accepted, who ran it and when.

| Field | Type | Notes |
| --- | --- | --- |
| Entry No. | Integer, auto-increment | Primary key |
| Customer No. | Code 20 | Table relation to Customer; no cascade delete |
| Checked At | DateTime | See date and time below |
| User ID | Code 50 | The user who ran the check |
| Result | Enum USPS Validation Result |  |
| Suggestion Accepted | Boolean | Yes only when the user chose Accept; shown as Yes/No |
| Original Address, Address 2, City, County, Post Code | Same types as Customer | The BC values sent to USPS |
| USPS Address, Address 2, City, State, ZIP Code | Text 100, 50, 50, 2; Code 20 | Blank for Not Found and Error |
| DPV Confirmation | Code 1 | Y, D, S or N |
| Match Code, Correction Codes | Text 30, Text 100 | As returned by USPS |
| USPS Message | Text 250 | Match, correction or error text |
| HTTP Status | Integer | 200, 400, 401, 404, 429, 5xx; 0 for no response |
| Environment | Enum USPS Environment | Production or Test |

### Date and time

Checked At is a single DateTime field set with `CurrentDateTime`. Business Central stores DateTime values in UTC and displays them in the time zone from each user's My Settings. Every user therefore sees the entry in their own local date and time with no conversion code. Reports and API exports of the field return UTC.

### Behavior

- The log page is read-only. Entries cannot be edited by anyone.
- Only USPS ADDR - ADMIN can delete entries, and normally only through Retention Policy.
- Default retention is 2 years, configurable in Retention Policies.
- The log never stores tokens, credentials or raw request URLs.
- Fields are classified as CustomerContent; User ID as EndUserIdentifiableInformation.

## Setup, security and permissions

An administrator enters the USPS credentials once per company on the setup page; they are stored in Isolated Storage, never in a table field.

| Setup field | Default | Notes |
| --- | --- | --- |
| Enabled | No | The Customer Card action reports that setup is incomplete while this is off |
| Environment | Test (TEM) | Switches the base URL between `apis-tem.usps.com` and `apis.usps.com` |
| Consumer Key |  | Stored in Isolated Storage, company scope; displayed masked |
| Consumer Secret |  | Stored in Isolated Storage, company scope; write-only on the page |
| US Country/Region Code | US | A blank customer country is also treated as US |
| Timeout (seconds) | 10 |  |

- **Test Connection** requests a token and reports success or the USPS error. It does not call the address endpoint, so it uses none of the address quota.
- The access token is cached in Isolated Storage with its expiry time and is shared by all users in the company.
- Credentials and tokens are handled as `SecretText` and never appear in the log, telemetry, messages or the debugger.
- Changing the Consumer Key, Secret or Environment clears the cached token.
- Users need USPS ADDR - USE plus their normal permission to modify customers. A user who cannot modify customers can run a check but Accept is disabled.

## Error handling

No failure changes the customer, and every failure after the preconditions is logged.

| Condition | Message to the user | Logged |
| --- | --- | --- |
| Setup disabled or credentials missing | USPS address validation is not set up. Contact your administrator. | No |
| Customer country is not US | USPS validates US addresses only. | No |
| Address blank, or both City/State and ZIP Code blank | Enter a street address and either city and state or ZIP Code. | No |
| State is not a 2-letter code | Enter the 2-letter state code in the State field. | No |
| HTTP 400 | USPS could not read the address: followed by the USPS message | Error |
| HTTP 404 (no match, insufficient data, invalid delivery address, multiple matches) | USPS could not find this address: followed by the USPS message | Not Found |
| HTTP 401 or 403 after one token refresh | USPS rejected the credentials. Contact your administrator. | Error |
| HTTP 429 | The hourly USPS limit has been reached. Try again later. | Error |
| HTTP 5xx, timeout or no connection | USPS is not responding. Try again later. | Error |
| Response cannot be parsed | Unexpected response from USPS. Contact your administrator. | Error |

USPS error bodies have the shape `{ "error": { "code": "404", "message": "..." } }`; the app shows and logs `error.message`. There are no automatic retries other than the single token refresh, so a failing call cannot burn through the quota.

## Constraints and risks

Two USPS conditions shape this design: a low hourly quota and terms that limit what the data may be used for.

| Risk | Effect | Mitigation in this spec |
| --- | --- | --- |
| Quota of about 60 address calls per hour, shared by all users of the app credentials | Checks fail with 429 during busy periods | On-demand only, no auto-validation, no retries, clear message; request an increase from USPS if needed |
| Terms allow the API only to facilitate USPS shipping or mailing | Using it purely for CRM data hygiene may be outside the terms | Confirm we ship or mail to these customers by USPS; get sign-off from whoever accepts the terms |
| Terms prohibit data mining and building or cleaning address lists | USPS can throttle or revoke access | No batch function; one customer per user action |
| Terms prohibit changing the form or content of API responses | Reformatting USPS data may breach the terms | Accepted values are stored exactly as USPS returns them, in upper case |
| Terms call the Addressing API an operational test that can be withdrawn, and refer to a separate license | The free service could change or end | Keep all USPS logic in one codeunit so the provider can be swapped; ask USPS whether this clause covers Addresses 3.0 |
| USPS may change request and response formats without notice | The integration can break | Tolerant parser, clear parse error, TEM environment for retesting |
| Security incidents involving USPS data or credentials must be reported to USPS within 72 hours | Compliance duty | Add to the incident response checklist; restrict the ADMIN permission set |

This is a reading of the published terms, not legal advice. The terms were last updated January 22, 2026.

## Acceptance tests

The build is accepted when all of these pass in a sandbox against the USPS test environment, and tests 1 to 3 pass once against production.

| # | Scenario | Expected |
| --- | --- | --- |
| 1 | Customer address already matches USPS exactly | Confirmed message; no dialog; log entry Confirmed, Accepted = No |
| 2 | Address with a typo and no ZIP+4; user chooses Accept | Dialog shows both versions with changes in bold; customer updated with USPS values; log entry Suggestion Accepted, Accepted = Yes, both addresses stored |
| 3 | Same as 2; user chooses Ignore, then repeats and closes with Esc | Customer unchanged both times; two log entries Suggestion Ignored, Accepted = No |
| 4 | Address that does not exist | USPS not-found message; customer unchanged; log entry Not Found with USPS message |
| 5 | Office building address without a suite number | Dialog shows the missing-suite warning (DPV = D); Accept still available |
| 6 | Address differs from USPS only in letter case | Confirmed; no dialog |
| 7 | Customer with Country/Region Code CA | US-only message; no USPS call; no log entry |
| 8 | Wrong Consumer Secret in setup | Credentials message; log entry Error with HTTP 401 |
| 9 | Simulated HTTP 429 and timeout (mocked client in the test app) | Correct message for each; log entry Error; no retry |
| 10 | Two checks within the token lifetime | Only one token request is made |
| 11 | Two users in different time zones open the same log entry | Each sees Checked At in their own local time |
| 12 | User without modify permission on Customer | Check runs; Accept disabled |
| 13 | Unsaved address edit on the card, then Validate Address | The edited address is the one sent to USPS |
| 14 | Setup page | Secret is never displayed after entry; Test Connection succeeds with valid credentials |

An AL test app covers 1 to 10 and 12 with a mocked HTTP layer, so automated tests never use the USPS quota.

## Open questions

Each has a default that the spec assumes until someone decides otherwise.

- [ ] Do we ship or mail to these customers through USPS? This decides whether our use fits the USPS terms. No default; needed before build.
- [ ] Upper case: USPS returns `123 MAIN ST`, all capitals. Default: store as returned, per the terms.
- [ ] Should a new ZIP+4 alone trigger the dialog? Default: yes.
- [ ] Which field holds the state on our Customer Card? Default: County, labeled State in the US localization.
- [ ] Are Puerto Rico and other US territories set up as separate country codes in our BC? Default: only the one configured US code is validated.
- [ ] If USPS returns a firm name, should it be shown? Default: not shown, not written.
- [ ] Should accepted ZIP codes be added to the BC Post Code table? Default: no.
- [ ] Log retention period. Default: 2 years.
- [ ] Expected checks per hour across all users. If above about 40, request a quota increase before go-live.
- [ ] Does this extend to Ship-to Addresses and Vendors in a later version? Default: later, same codeunits.

## Sources

- [USPS Developer Portal: Getting Started](https://developers.usps.com/getting-started) for onboarding steps, base URLs, default product and quota increases
- [USPS Developer Portal: FAQs](https://developers.usps.com/faq) for the test environment, 429 quota errors and credentials
- [USPS API Terms and Conditions](https://developers.usps.com/terms-and-conditions), updated January 22, 2026
- [USPS api-examples on GitHub](https://github.com/USPS/api-examples) for token and address request and response examples and error messages
- [USPS api-examples pull request 85](https://github.com/USPS/api-examples/pull/85.patch) for the current response field names
- [Smarty: USPS API rate limit](https://www.smarty.com/blog/usps-api-rate-limit) and [GeoPostcodes: USPS API rate limit](https://www.geopostcodes.com/blog/usps-api-rate-limit/) for the 60 per hour default and the Web Tools retirement date; both are vendors of competing services
