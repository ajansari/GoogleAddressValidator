# Problem Statement — USPS Address Validator

**Source:** `requirements/USPS Address Validation for Business Central — PTE spec.md` (AJ Ansari, Oct 10, 2026), frozen as provided.
**Status:** Draft for sign-off at the end of PRE-02 (one approver, so PRE-01's sign-off is combined with PRE-02's).

## Purpose
Customer addresses in Business Central are typed by hand and often wrong or inconsistently formatted (`123 main street`, `Nashvile`, no ZIP+4). A user who opens a Customer Card should be able to check that address against the USPS and, if USPS has a better version, accept it with one click. Every check is logged.

## Business outcome
- A **Validate Address (USPS)** action on the Customer Card sends the customer's main address to the free USPS Addresses 3.0 API (OAuth 2.0 client credentials).
- The user sees the BC address and the USPS version side by side, with changes in bold and USPS delivery notes (missing suite, vacant, business address), and chooses **Accept** or **Ignore**.
- Accept writes the USPS values to the customer exactly as USPS returns them (upper case).
- Every check that reaches USPS writes one log entry, whatever the outcome.

## Target consumers
- **Users:** staff who maintain customers (need the action, the dialog and the log).
- **Administrators:** enter USPS credentials once per company, choose Production or Test (TEM), run Test Connection, manage log retention.
- **Auditors/compliance:** read the processing log (who, when, what was sent, what USPS answered, whether accepted).
- No other systems, BI tools or AI tools consume this version. The log is exposed on a standard list page only.

## Countries and languages
- **Country:** United States only. A blank Country/Region Code, or the configured US code, is treated as US; anything else gets a US-only message.
- **Languages:** the spec names none beyond English. To be confirmed in Step 01 §1.9 (assumed: English only, no translation files).

## In scope (version 1)
- Validate one customer's main address at a time, on demand, from the Customer Card.
- Setup page (credentials in Isolated Storage as `SecretText`, environment, timeout, US country code, Enabled, Test Connection).
- Side-by-side comparison dialog with Accept and Ignore.
- Update of Address, Address 2, City, County (state) and Post Code on Accept.
- Processing log (table, read-only list page, Retention Policy, per-customer filtered action).
- Two permission sets (USE and ADMIN).
- **Added at Step 01 (AJ, 2026-10-10):** an Assisted Setup Wizard to enter the USPS credentials, and a non-editable **Address Validated** Boolean on Customer (see "Scope additions" below).
- Error handling per the spec's table; one token refresh on 401; no other retries.
- An AL test app with a mocked HTTP layer covering acceptance tests 1–10 and 12.

## Scope additions decided at Step 01 (AJ Ansari, 2026-10-10)
Raw input: `requirements/scope-additions-2026-10-10-requirements.md`. Logged as ChangeLog Issue 01-1; sign-off of this document stands, extended to cover them when AJ confirms the parameter sheet.
- **Assisted Setup Wizard** to populate the USPS Consumer Key and Consumer Secret (only those two; environment, Enabled, country code and timeout remain on the setup card).
- **Address Validated** Boolean on Customer (table extension), shown on the Customer Card in the Address FastTab. Default false; not user-editable; set true by code when a check ends in Accept **or Confirmed**; unchanged when Ignored; reset to false when a validated customer's address fields are edited later.

## Explicitly out of scope
- Automatic validation on entry or save; batch or scheduled validation (excluded on purpose: quota and USPS terms).
- Non-US addresses.
- Ship-to Addresses, Vendors, Contacts, sales documents (candidate for a later version, same codeunits).
- Geocoding, residential/commercial rating, tax area updates.
- Adding accepted ZIP codes to the BC Post Code table.
- Showing or writing a USPS firm name.

## Domain vocabulary
USPS Addresses 3.0 API; Consumer Key / Consumer Secret (`client_id` / `client_secret`); TEM (USPS test environment); DPV Confirmation (Y / D / S / N); ZIP+4; Secondary address (suite/apartment); Isolated Storage; `SecretText`; Retention Policy; Customer Card; Post Code table.

## Initial entity / object list (from the spec)
| Type | Name | Tag |
|---|---|---|
| Table | USPS Addr. Validation Setup | setup |
| Table | USPS Addr. Validation Log | document-like log (analytical/audit) |
| Enum | USPS Validation Result | lookup |
| Enum | USPS Environment | lookup |
| Page (NavigatePage) | USPS Assisted Setup Wizard *(added 01)* | setup / onboarding |
| Table extension | Customer — field Address Validated *(added 01)* | existing master (Customer) |
| Page (Card) | USPS Addr. Validation Setup | setup |
| Page (List) | USPS Addr. Validation Log | read-only list |
| Page (StandardDialog) | USPS Address Comparison | dialog |
| Page extension | Customer Card (Validate Address action; log action filtered to customer) | existing master (Customer) |
| Codeunit | USPS Address Validation | orchestration |
| Codeunit | USPS API Client | HTTP/token/JSON |
| Codeunit | USPS Addr. Validation Install | install, Retention Policy registration |
| Permission set | USPS ADDR - USE | permissions |
| Permission set | USPS ADDR - ADMIN | permissions |

Existing BC data read or written: Customer (Address, Address 2, City, County, Post Code, Country/Region Code). Test app: separate AL test app with a mocked HTTP client.

## Duplicates, ambiguities and legacy terms spotted
1. **Object ID range conflict.** The spec says "our PTE range (50000 to 99999)"; the project's `app.json` still has the AL template default `50100–50149` (50 IDs). Needs a decision at Step 01 (Parameter 1.2). The spec's object count (13 objects, plus a test app and possibly more IDs for the test codeunits and mocks) fits in 50 IDs only if the test app has its own range.
2. **"State" is stored in the `County` field** on the Customer table (labelled State in the US localization). The spec's default is County; confirm that the target environment uses US localization or W1, since the field caption differs.
3. **Quota assumption.** "About 60 calls per hour" is third-party; the real quota must be read in the USPS portal before go-live.
4. **USPS terms fit.** The terms allow the API only to facilitate USPS shipping or mailing. This is a business decision, not a code decision, and it blocks the build (see open questions).
5. **Two environments, one set of credentials.** The test URL uses production credentials, so a "Test" setting still needs real secrets; the setup page should make that clear.
6. **Two user rights.** A user without modify permission on Customer can run a check but not Accept; the log entry for that run should read "Suggestion Ignored" or stay open — not defined in the spec (to settle in the FRD).

## Open questions (carried from the spec, each with its default)
- [ ] **Do we ship or mail to these customers through USPS?** Decides whether our use fits the USPS terms. No default; **needed before build.**
- [ ] Upper case: store as returned by USPS. *Default: yes.*
- [ ] A new ZIP+4 alone triggers the dialog. *Default: yes.*
- [ ] State field is County. *Default: yes.*
- [ ] Puerto Rico and other territories: only the one configured US code is validated. *Default: yes.*
- [ ] USPS firm name: not shown, not written. *Default: yes.*
- [ ] Accepted ZIP codes added to the Post Code table. *Default: no.*
- [ ] Log retention. *Default: 2 years.*
- [ ] Expected checks per hour across all users (above ~40 means request a quota increase before go-live). *Unknown.*
- [ ] Ship-to Addresses and Vendors in a later version. *Default: later.*
- [x] Object ID range — decided at Step 01: 60093–60142.
- [x] Target — decided at Step 01: SaaS PTE, BC 28, runtime 17.0, localization US.

---

# PRE-02 — Structured Gap Analysis (Standards Part 6)

Run by the main role (Sonnet 5.5) on 2026-10-10. The extension reads and updates one existing master (Customer) and owns a setup table, an audit-style log and a dialog; it posts nothing and defines no document. Field lengths and table numbers quoted from the spec are **unverified** until checked against the downloaded symbols at Step 03 (Operating Rule 2).

## Checklist results
| Category (Standards §) | Finding | Resolution |
|---|---|---|
| 6.1 Analytical detail tables | The extension touches no ledger. The Log table is its own audit trail, with a single level (one row per check); no detail child needed. | Closed — nothing to add |
| 6.2 Posted / archived versions | Open Sales/Service documents copy the customer's address at creation. Accepting a USPS address changes the Customer only, never existing documents; posted documents correctly keep the address they shipped to. | Closed — behaviour recorded, no change. FRD must state that open documents are not updated |
| 6.3 Reference / lookup tables | Country/Region (read, to decide US); Post Code table (225, read-only reference; spec says accepted ZIPs are not added). Spec assigns City, County and Post Code directly, so the standard Post Code autofill does not run. | Closed — read-only; the direct-assignment rule is carried to the FRD |
| 6.4 Secondary document types | None. | N/A |
| 6.5 Modern vs. legacy tables | None used. | N/A |
| 6.6 Tax framework tables | Customer carries a Tax Area Code in the US localization that depends on the address. Spec puts tax-area updates out of scope. | **Deferred** — a changed ZIP may leave the Tax Area Code stale; flag in the FRD as a known limitation and let the user decide. Owner: AJ (FRD, Step 02) |
| Global vs. localized | The Customer table is global; validation is US-only (jurisdiction-specific by design). | Recorded below |
| Regional terminology | See list below. | Listed for Step 01 §1.9; not resolved here |

## Gaps found and logged
| # | Gap | Added to scope? | Reason |
|---|---|---|---|
| G1 | Retention Policy registration needs standard Retention Policy tables/codeunits (system objects) | Already in spec (Install codeunit) | No new object; confirm the API at Step 03 |
| G2 | Credentials and token live in Isolated Storage as `SecretText`, not a table | Already in spec | No object; setup page must never expose them |
| G3 | Standard Customer `Modify(true)` also syncs the address to the linked Contact (Business Relation). Accept therefore also updates the Contact's address through standard triggers | Yes — behaviour, no object | Document it in the FRD so it is not read as a side effect; ties to open question on Contacts |
| G4 | Customer **List** is a likely second place users will want the action; spec scopes the Card only | **Deferred** | Out of scope for v1 per spec; trivial to add later through the same codeunits |
| G5 | Ship-to Address and Vendor have the same address fields | **Deferred** | Spec: later version, same codeunits |
| G6 | Standard Change Log (if enabled for Customer) will record the Accept as a field change | Yes — behaviour, no object | Mention in Documentation; no action |
| G7 | A separate AL **test app** with a mocked HTTP layer is required by the spec but is a second extension, with its own `app.json`, ID range and dependency on this app | **Added** as a scope item | Spec acceptance tests 1–10 and 12 depend on it; needs its own IDs and folder, decided at Step 01 |
| G8 | Log table has no clean-up path outside Retention Policy | Already in spec | ADMIN-only delete; confirm in the TDD |

## Expanded, de-duplicated entity list
R = read, W = write, RW = both. Scope: **Global** = works in any localization, **US** = only meaningful for US addresses.
| # | Entity | Tag | R/W intent | Scope |
|---|---|---|---|---|
| 1 | Table USPS Addr. Validation Setup | setup | RW | Global |
| 2 | Table USPS Addr. Validation Log | analytical / audit | W (insert only), R | Global |
| 3 | Enum USPS Validation Result | lookup | — | Global |
| 4 | Enum USPS Environment | lookup | — | Global |
| 5 | Page USPS Addr. Validation Setup (Card) | setup | RW | Global |
| 6 | Page USPS Addr. Validation Log (List) | read-only list | R | Global |
| 7 | Page USPS Address Comparison (StandardDialog) | dialog | R | US |
| 8 | Page extension Customer Card | master (existing Customer) | R, W on Accept | US (action blocked for non-US) |
| 9 | Codeunit USPS Address Validation | orchestration | RW | US |
| 10 | Codeunit USPS API Client | HTTP / JSON | — | US |
| 11 | Codeunit USPS Addr. Validation Install | install | W (Retention Policy) | Global |
| 12 | Permission set USPS ADDR - USE | permissions | — | Global |
| 13 | Permission set USPS ADDR - ADMIN | permissions | — | Global |
| 14a | Page USPS Assisted Setup Wizard *(added at Step 01)* | onboarding | RW (setup) | Global |
| 14b | Table extension Customer: Address Validated *(added at Step 01)* | existing master (Customer) | W by code only | US |
| 14 | **Test app** (separate extension): mock HTTP codeunit(s) and test codeunits | test | — | — |
| — | Existing, read only: Customer (18), Country/Region, Post Code, Contact (via standard sync), Isolated Storage | existing | R / W (Customer only) | Global |

No duplicates or legacy objects found. Objects 1–13 match the spec exactly; 14 is new to the list.

## Regional terminology (for Step 01 §1.9; to be verified against Microsoft's wording, Standards Appendix D)
| BC concept | Where it appears | Variation to check |
|---|---|---|
| State / County | Customer field `County`, spec calls it State | US localization shows "State"; W1 shows "County" |
| ZIP Code / Post Code | Customer field `Post Code`, spec calls it ZIP Code | US shows "ZIP Code"; W1 "Post Code" |
| Address 2 / secondary address | Customer `Address 2` vs USPS `secondaryAddress` | USPS wording is "secondary"; BC is "Address 2" |
| Country/Region Code | Setup field "US Country/Region Code" | Same caption in all localizations |
| Delivery notes (DPV) | Dialog text for Y / D / S / N | USPS terms; no BC equivalent to verify |

## Gaps closed or deferred
Closed: G1, G2, G3, G6, G8 and checklist items 6.1–6.5. Added: G7 (test app). **Deferred with reasoning:** 6.6 (tax area), G4 (Customer List), G5 (Ship-to, Vendor).
