Model: Opus 5.5 (claude-opus-5-5)

That matches the Reasoning row of `docs/1-define/ProjectParameters.md` §1.7 (Opus 5.5, `opus`, High).

I wrote no project files. To check things against ground truth I:
- extracted the Base Application, System and System Application symbols and the Base Application's shipped source into the scratchpad;
- compiled a throwaway probe app against the project's `.alpackages` with `ocpfFramework/scripts/al-analyze.sh` (AL 18.1.43.24897). Probe folder: `/private/tmp/claude-501/-Users-ajansari-Documents-AL-USPSAddressValidator/8ab31dc3-c49d-4af2-8438-30afcd1c354e/scratchpad/probe`.

I did not draft the other Step 03 outputs: the Human Effort Estimate addendum, the AI Effort Estimate (that one is the main role's), the Object Register update, the ProjectParameters §1.2 update and `app.json` idRanges. They are still owed.

---

# 1. Findings and risks

**Verdict:** the approach works with the changes below. Five of them change the proposal (F1–F5) and need AJ Ansari's decision before Step 05 (questions in §5).

## F1 (major): unique field numbers are the wrong choice for the four tables that standard sync copies by field number
- **Evidence** (Base App 28.5 source):
  - `CustCont-Update` (5056) line 70/129: `Contact.TransferFields(Cust)`
  - `VendCont-Update` (5057) 73/129: `Cont.TransferFields(Vend)`
  - `BankCont-Update` (5058) 65/129: `Cont.TransferFields(BankAcc)`
  - `CustVendBank-Update` (5055) 97/138/173: `Cust`/`Vend`/`BankAcc.TransferFields(Cont)`, followed by `Modify()` without trigger.
  - Reports "Create Conts. from Customers/Vendors/Bank Accs." also use `Cont.TransferFields(...)`.
  - I searched every `TransferFields(` in the Base App. No other in-scope pair is copied by field number. Employee→Resource, Contact→Employee and company→person contact use direct assignment (F2).
- **Consequence of unique numbers:** the sync copies the address but not the flag. A partner can show Address Validated = Yes beside an address nobody validated.
- **This already happens in 1.0.0.0:** editing a linked Contact's address rewrites the Customer's address through `CustVendBank-Update`, and Customer field 60093 stays Yes, because Contact has no 60093.
- **Recommendation:** give Customer, Vendor, Bank Account and Contact the same field number 60093. Then the flag travels with the address both ways.
  - Simplest form: 60093 on every in-scope table, and 60094 for the Company Information ship-to flag. Field numbers are per table, and the probe compiled the same number in several table extensions of one app.
  - The old note "60093 reserved because Contact.TransferFields copies by field number" is turned around: that copying is exactly why the partners should share it.
- **Not verifiable from symbols:** that `TransferFields` copies table-extension fields with matching numbers is platform behaviour. Acceptance test 32 checks it.
- **Upgrade consequence:** see F9.

## F2 (major): standard copies by direct assignment leave stale flags whatever the numbering
These paths assign the address fields directly, so the flag reset (which runs on validate) never fires:
- **Company contact → its persons:** Contact `DoModify`, when Marketing Setup "Inherit Address Details" is on. It assigns directly, then calls `Cont.Modify()`. Event: Contact `OnAfterSyncAddress(var Contact; RecContact; var ContChanged; var ContactBeforeModify)`.
- **Person linked to a company:** `Contact.InheritCompanyToPersonData`. Event `OnAfterInheritCompanyToPersonData(var Contact; xContact; NewCompanyContact)`.
- **Contact → Employee:** `CustVendBank-Update.UpdateEmployee`, which assigns directly then calls `Employee.Modify(true)`. Event `OnAfterUpdateEmployee(var Employee; Contact)`.
- **Employee → Resource:** `Employee/Resource Update` (5200) `ResUpdate`. Event `OnAfterUpdateResource(var Resource; Employee)`, raised before `Res.Modify(true)`.

A further problem with shared numbering: a flag-only change (Confirmed / Not Found) on one partner does not reach the other. Example: Customer gets Not Found → No, its Contact keeps Yes, and the next Contact edit copies Yes back. That is a false Yes.
- Contact event that fixes the Contact side: `OnBeforeIsUpdateNeeded(var Contact; xContact; var UpdateNeeded)`.
- All five events are `[IntegrationEvent(false,false)]`, verified in the source.

**Recommendation:** batch 4 adds "the flag follows the address" subscribers (TDD 15.13). This changes Customer behaviour (its Contact also gets updated on Confirmed / Not Found), so it is kept out of batch 1. Question OQ-35.

## F3 (major): a pure RecordRef write would break Customer's contact sync and miss Bank Account and Employee sync
- Customer and Vendor rely on `SetForceUpdateContact(true)` (Customer.Table 4148, Vendor.Table 2767). It is a procedure on the typed record and cannot be reached through RecordRef.
- On a code-driven `Modify`, `xRec = Rec` (stated in Contact.OnModify's own comment). So:
  - Bank Account's `IsContactUpdateNeeded` (BankAccount.Table 1931) returns false, and Bank Account has no SetForceUpdateContact.
  - Employee.OnModify's `HumanResToRes(xRec, Rec)` sees no change.
- **Fix:** RecordRef for reading, comparing and assigning, plus a per-table save step in the new Address Source codeunit:
  - Customer, Vendor: `SetTable` → `SetForceUpdateContact(true)` → `Modify(true)`. Customer stays byte-for-byte the 1.0.0.0 call.
  - Bank Account: `Modify(true)`, then `BankCont-Update.OnModify`.
  - Employee: `Modify(true)`, then `Employee/Resource Update.HumanResToRes(old, new)`.
  - Contact: plain `Modify(true)`. Its OnModify re-reads the stored record and syncs.

## F4 (major): a page extension cannot declare an action area, and several cards have none
- The probe got AL0104 "Syntax error" for `area(Processing)` inside a pageextension.
- Cards with no processing area: 300, 423, 368, 2368, 425, 1, 5714, 5203, 5056. Page 425 Vendor Bank Account Card has no actions at all.
- The probe confirmed that `addlast(Processing)`, `addlast(Navigation)` and `addlast(Promoted)` (with an `actionref` directly inside) compile on pages that lack those areas. It compiled every field and action anchor in §2 with 0 errors (the only warnings were the probe's own file names and formatting).

## F5 (medium): a Country/Region change clears City, ZIP and State without resetting the flag
- `Post Code.CheckClearPostCodeCityCounty` (PostCode.Table 309) runs from every main block's Country/Region Code OnValidate.
- When the country changes away from a non-blank value, and GL Setup "Req.Country/Reg. Code in Addr." is off, it sets Post Code, City and County to '' by direct assignment. The flag stays Yes.
- This is latent in 1.0.0.0 for Customer.
- **Fix:** add `modify("Country/Region Code")` that calls the same five-field compare. The country itself still does not count (OQ-14 stands). Company Information "Ship-to Country/Region Code" has no OnValidate, so it needs no trigger.
- Changes Customer behaviour, so it goes in batch 4 for Customer. Question OQ-36.

## F6 (medium): "permission sets need modify rights on new tables" contradicts FR-6 and Standards §5.3
- Standards §5.3 deployment note: extension permission sets grant access to extension objects only.
- SC-1 adds no table, so there is no new `tabledata` grant (PTE0004 only concerns tables). Only `X` on the new codeunits.
- Users need their normal Business Central read/modify permission on each source table and on the linked tables (FR-14).
- Adding `tabledata Vendor = M` and the like to our sets would widen users' rights. Not recommended.

## F7 (medium): the source description must not hold names
- PostDevTDD B-15: the log "never stores … the customer name".
- So "Source Description" = table caption + primary-key values (+ " (Ship-to)"), never Name, First/Last Name or Company Name.
- This also limits the personal data logged for Employee, Alternative Address, Resource and Contact persons.

## F8 (medium): `ValidateAddress(TableId, SystemId)` cannot reach the Company Information ship-to block
- It needs an Address Type parameter (enum Main / Ship-to). The TDD uses `ValidateAddress(SourceTableNo, SourceSystemId, AddressType)`.

## F9 (medium): schema and upgrade for the installed 1.0.0.0
- **Schema is additive only (Sync Mode Add):**
  - new log fields 24–28 and a new key;
  - new temporary-buffer fields (TableType = Temporary, so no schema at all);
  - 15 new table extensions.
  - Nothing renamed, retyped, removed or re-keyed. Log field 2 "Customer No.", key `CustomerCheckedAt` and Customer field 60093 stay exactly as they are.
- **Upgrade code is required (Standards §9.1, §9.3):**
  - Backfill Source Table No. = 18, Address Type = Main, Source SystemId and Description on every existing log row.
  - With F1's shared numbering, copy each validated Customer's flag to its linked Contact when the addresses are equal. Without it, the first edit of any linked contact copies No over the Customer's Yes.
  - Tags are guarded and registered for new companies and on fresh install.
- **The install codeunit must set the new tags.** I recommend explicit per-tag `SetUpgradeTag` instead of `SetAllUpgradeTags()`. `SetAllUpgradeTags()` also sets other extensions' registered tags. This departs from Standards §9.3's "preferred" form; the reason is recorded here.

## F10 (minor): wording
- These labels say "customer": `NoCustomerErr`, `AddressChangedMsg`, `NoPermissionTxt`. So do five ToolTips on the compare page, three on the setup page, and the Assisted Setup description.
- The test library mirrors label texts, so I recommend:
  - keep the Customer texts exactly as they are;
  - add generic variants for the other sources;
  - make the ToolTips neutral.
- A changed Assisted Setup description reaches new companies only, because Guided Experience keeps the registered text.

## F11 (minor): "Privacy Blocked" is ignored today
- Customer, Vendor, Contact, Employee and Resource have `Privacy Blocked` (field 150). Today's validation sends regardless. Question OQ-37.

## F12 (minor): batch 1 can compile alone
- The field map uses field-number constants (60093 / 60094) and `RecordRef.FieldExist`. Batch 1 then has no forward reference to the table extensions of batches 2–3: a table is "not supported" until its extension exists.
- That makes an optional spot-check compile plus a run of the 61 existing tests after batch 1 possible (OQ-41).

## F13 (info): what holds unchanged for all 16 sources
- **Field lengths are identical:** Address 100, Address 2 50, City 30, County 30, Post Code Code[20], Country Code[10]. The buffer and log lengths stay valid.
- **No in-scope base table has a field ≥ 50000**, so there is no collision in 60093–60192.
- **All 15 cards are editable.** Company Information has InsertAllowed = DeleteAllowed = false.
- **Address OnValidate triggers per field:**
  - Address, Address 2 and County: none.
  - City and Post Code: Post Code table lookup/validate (can rewrite City, Post Code, County, Country).
  - Country: the clear in F5. Customer, Vendor and Contact also run VAT registration checks, and Ship-to uses `HandleCountryChangeInShipToAddress`.
  - Accept assigns directly, so none of these run. This is the same as Customer today, and the FR-4 rule "the Post Code table must not override" still holds.
- **Data classification:** the Base App classifies every in-scope address field as CustomerContent, Employee's included. The log keeps CustomerContent.

## F14 (info): test app
- Test library lines 165, 476, 546 and 554 filter the log by "Customer No.". These still work because Customer No. stays filled for customers.
- CleanUp does not know the new tables.
- The fake transport can force a modify failure on Customer only (FakeHttpTransport 121–129).
- There are 5 free test-app IDs (60129–60133).

## Customer-specific code that changes, by file and line
**`src/Validation/obcfgavAddressValidation.Codeunit.al` (60113):**
- 3 `using Microsoft.Sales.Customer` (kept for the wrapper)
- 30–43 `ValidateCustomerAddress` (becomes a wrapper)
- 45–103 `TryValidateCustomerAddress`:
  - 47 Customer variable
  - 60 `CanModify := CanModifyCustomers()`
  - 62–66 `SetLoadFields` / `Get`
  - 67 `CheckPreconditions(Customer, …)`
  - 74 `FillOriginal(…, Customer)`
  - 82 / 100 / 102 `RunWriter(CustomerNo, …)`
- 110–117 `CanModifyCustomers` (`Database::Customer` at 115)
- 129–160 `CheckPreconditions(Customer: Record Customer …)` (142, 147–148, 154)
- 184–193 `FillOriginal` (187 `"Customer No."`)
- 227–242 `FitsCustomerFields` (`MaxStrLen(Customer.…)`)
- 252–264 `HandleProviderFailure(CustomerNo …)` (260)
- 266–281 `RunWriter(CustomerNo …)` (270 `Writer.Init(CustomerNo, …)`)
- 283–293 `LogWriteFailure(CustomerNo …)` (289)
- labels 302 `NoCustomerErr`, 308 `AddressChangedMsg`, 309 `NoPermissionTxt`

**`src/Validation/obcfgavValidationWriter.Codeunit.al` (60118):**
- 3 using
- 21 `InsertLogEntry(CustomerNo, …)`
- 24–32 `Init(NewCustomerNo …)`
- 39–46 `InsertLogEntry(LogCustomerNo …)` / `Log."Customer No."`
- 73–95 `WriteAcceptedSuggestion` (typed Customer: 77–78 LockTable/Get, 87–94 assign + SetForceUpdateContact + Modify)
- 97–105 `CustomerDiffersFromSnapshot`
- 107–121 `SetAddressValidated` (typed)
- 125 `CustomerNo` global

**Other files:**
- `src/Validation/obcfgavValidationLog.Table.al` (60109): 3 using; 20–24 "Customer No."; 120 key; 125–128 `OnInsert TestField("Customer No.")`
- `src/Validation/obcfgavAddressBuffer.Table.al` (60111): 15–18 field 2 "Customer No."
- `src/Validation/obcfgavLogEntries.Page.al` (60110): 27–30 customerNo ToolTip
- `src/Validation/obcfgavAddressCompare.Page.al` (60112): ToolTips 42, 48, 54, 60, 66 ("currently on the customer")
- `src/Validation/obcfgavCustomer.TableExt.al` (60116): no Country/Region modify (F5)
- `src/Validation/obcfgavCustomerCard.PageExt.al` (60117): 36–37 (unchanged; the wrapper keeps the API)
- `src/Setup/obcfgavSetup.Page.al`: 26, 39, 85 (ToolTips)
- `src/Setup/obcfgavSetupRegistration.Codeunit.al`: 86 (`AssistedSetupDescriptionTxt`)

---

# 2. Verified table-by-table reference
Source: Base Application 28.5.54151.55594 `SymbolReference.json`, plus the shipped `.al` source for triggers.

**Field numbers.** Format: Address / Address 2 / City / County / Post Code / Country. Lengths are 100 / 50 / 30 / 30 / Code 20 / Code 10 in every row.

**Field anchor.** The `pageextension` layout anchor for the Address Validated field.

**Validate / promote / log anchors.** All three compiled in the probe.

**Page namespace.** Equals the table's namespace.

| # | Table (ID), namespace | PK | Field numbers | Card page (ID) | Field anchor | Validate / promote / log anchors | Notes |
|---|---|---|---|---|---|---|---|
| 1 | Customer (18), `Microsoft.Sales.Customer` | No. | 5/6/7/92/91/35 | Customer Card (21) | `addafter("Post Code")` (as built) | `"F&unctions"` / `Category_Process` / `"&Customer"` | Unchanged. Contact family (TransferFields) |
| 2 | Ship-to Address (222), `Microsoft.Sales.Customer` | Customer No., Code (Code[10]) | 5/6/7/92/91/35 | Ship-to Address (300) | `addafter("Country/Region Code")` (group Control3) | `Processing` / `Promoted` / `"&Address"` | No processing area. List 301 |
| 3 | Customer Bank Account (287), `Microsoft.Sales.Customer` | Customer No., Code (Code[20]) | 6/7/8/18/9/17 | Customer Bank Account Card (423) | `addafter("Post Code")` | `Processing` / `Category_Process` / `Navigation` | No processing area. List 424 |
| 4 | Vendor (23), `Microsoft.Purchases.Vendor` | No. | 5/6/7/92/91/35 | Vendor Card (26) | `addafter("Post Code")` | `"F&unctions"` / `Category_Process` / `"Ven&dor"` | Contact family. `SetForceUpdateContact` exists |
| 5 | Order Address (224), `Microsoft.Purchases.Vendor` | Vendor No., Code (Code[10]) | 5/6/7/92/91/35 | Order Address (368) | `addafter("Country/Region Code")` | `Processing` / `Promoted` / `"&Address"` | List 369 |
| 6 | Remit Address (2224), `Microsoft.Purchases.Remittance` | Code (Code[10]), Vendor No. (that order) | 5/6/7/92/91/35 | Remit Address (2368) | `addafter("Country/Region Code")` | `Processing` / `Promoted` / `Location` (nav group name) | List 2369 |
| 7 | Vendor Bank Account (288), `Microsoft.Purchases.Vendor` | Vendor No., Code (Code[20]) | 6/7/8/18/9/17 | Vendor Bank Account Card (425) | `addafter("Country/Region Code")` | `Processing` / `Promoted` / `Navigation` | Page has no actions at all |
| 8a | Company Information (79) main block, `Microsoft.Foundation.Company` | Primary Key (Code[10]) | 4/5/6/31/30/36 | Company Information (1) | `addafter("Country/Region Code")` (General) | `Processing` / `Promoted` / `Navigation` | Insert/Delete not allowed. Country runs the clear (F5) |
| 8b | Company Information (79) ship-to block | same | Ship-to Address 24 / Ship-to Address 2 25 / Ship-to City 26 / Ship-to County 33 / Ship-to Post Code 32 / Ship-to Country/Region Code 37 | same page | `addafter("Ship-to Country/Region Code")` (Shipping) | second Validate in `Processing`, promoted in `Promoted` | Ship-to Country has no OnValidate |
| 9 | Location (14), `Microsoft.Inventory.Location` | Code (Code[10]) | 5701/5702/5703/5715/5714/5720 | Location Card (5703) | `addafter("Country/Region Code")` | `Processing` / `Category_Process` / `"&Location"` | |
| 10 | Responsibility Center (5714), `Microsoft.Inventory.Location` | Code (Code[10]) | 3/4/5/15/6/7 | Responsibility Center Card (5714) | `addafter("Country/Region Code")` | `Processing` / `Promoted` / `"&Resp. Ctr."` | County is not in a visibility group |
| 11 | Bank Account (270), `Microsoft.Bank.BankAccount` | No. | 5/6/7/92/91/35 | Bank Account Card (370) | `addafter("Country/Region Code")` (Communication) | `Processing` / `Category_Process` / `"&Bank Acc."` | Contact family. No SetForceUpdateContact (F3) |
| 12 | Employee (5200), `Microsoft.HumanResources.Employee` | No. | 8/9/10/12/11/25 | Employee Card (5200) | `addafter("Country/Region Code")` (Control13) | `"F&unctions"` / `Category_Process` / `"E&mployee"` | Area is named "Processing". Syncs to Resource (F3); receives from Contact (F2) |
| 13 | Alternative Address (5201), `Microsoft.HumanResources.Employee` | Employee No., Code (Code[10]) | 5/6/7/9/8/14 | Alternative Address Card (5203) | `addafter("Country/Region Code")` | `Processing` / `Promoted` / `"&Address"` | |
| 14 | Contact (5050), `Microsoft.CRM.Contact` | No. | 5/6/7/92/91/35 | Contact Card (5050, ListPlus) | `addlast(Control37)` (Address group) | `"F&unctions"` / `Category_Process` / `"C&ontact"` | Type enum: Company (0), Person (1). Contact family + persons (F2) |
| 15 | Contact Alt. Address (5051), `Microsoft.CRM.Contact` | Contact No., Code (Code[10]) | 5/6/7/9/8/10 | Contact Alt. Address Card (5056) | `addafter("Country/Region Code")` | `Processing` / `Promoted` / `"&Alt. Contact Address"` | |
| 16 | Resource (156), `Microsoft.Projects.Resources.Resource` | No. | 6/7/8/54/53/59 | Resource Card (76) | `addafter("Country/Region Code")` (Personal Data) | `"F&unctions"` / `Category_Process` / `"&Resource"` | Type: Person / Machine; both validated |

Other objects used, all verified:

| Object | Namespace | Member used |
|---|---|---|
| Codeunit 5056 "CustCont-Update" | `Microsoft.CRM.BusinessRelation` | `OnModify(var Cust)`, public |
| Codeunit 5057 "VendCont-Update" | `Microsoft.CRM.BusinessRelation` | `OnModify(var Vend)`, public |
| Codeunit 5058 "BankCont-Update" | `Microsoft.CRM.BusinessRelation` | `OnModify(var BankAcc)`, public |
| Codeunit 5055 "CustVendBank-Update" | `Microsoft.CRM.BusinessRelation` | events above |
| Codeunit 5200 "Employee/Resource Update" | `Microsoft.HumanResources.Employee` | `HumanResToRes(OldEmployee, Employee)`, public |
| Table 5054 "Contact Business Relation" | `Microsoft.CRM.BusinessRelation` | "Contact No.", "Link to Table" (enum: Customer 1, Vendor 2, "Bank Account" 3, Employee 4), "No."; key ("Link to Table","No.") |
| Table 5079 "Marketing Setup" | `Microsoft.CRM.Setup` | Bus. Rel. Code for Customers 7 / Vendors 8 / Bank Accs. 9 / Employees 10; Inherit Address Details 26 |
| Table 2000000058 AllObjWithCaption | `System.Reflection` | "Object Caption" Text[249] |
| Codeunit 9999 "Upgrade Tag" | `System.Upgrade` | `HasUpgradeTag`, `SetUpgradeTag`, event `OnGetPerCompanyUpgradeTags(var PerCompanyUpgradeTags: List of [Code[250]])` |

**Contact persons and companies:** both are validated identically; there is no Type rule. Persons that inherit the company address follow the company's flag only through the batch 4 sync rules.

**Per-country behaviour:** US-only for every source. The source's (block's) Country/Region Code must be blank or equal to Setup "US Country/Region Code", unchanged.

---

# 3. FRD amendment text (FRD 2.1, ready to paste)

**Header:** Version 2.1 DRAFT (SC-1, for Google Address Validator 1.1.0.0), 2026-10-17. Drafted by the Reasoning role (Opus 5.5) for AJ Ansari. Sources add `requirements/scope-additions-2026-10-17-more-master-data-requirements.md` and ChangeLog SC-1. Not signed off.

## A. Edits to existing sections

**§1 Purpose.** Replace "lets a user who is maintaining a customer check that customer's main address" with:

> lets a user who is maintaining master data — a customer, ship-to address, customer or vendor bank account, vendor, order or remit address, the company (its address and its ship-to address), a location, responsibility center, bank account, employee, employee alternative address, contact, contact alternative address or resource (FR-10) — check that record's address

Replace "A read-only Address Validated indicator on the customer" with "A read-only Address Validated indicator on each of those records". Replace the end of the paragraph, "cleaner US customer addresses", with "cleaner US addresses in master data".

**§1.1 Out of scope.**
- Delete the bullet "Ship-to Addresses, Vendors, Contacts …".
- Change "Showing Address Validated anywhere other than the Customer Card" to "… anywhere other than the card pages named in FR-10".
- Change "The Validate Address action on the Customer List" to "The Validate Address action on any list page (G4)".
- Generalize "Updating open sales or service documents …" to: "Updating documents, journals or any other record that copied an address. Accept changes only the record checked and the records standard Business Central itself keeps in step with it (FR-9)."
- Add:
  - Every transaction and document table: sales, purchase, transfer, service, reminder, finance charge, and their archives and posted versions.
  - Job, Job Task, Service Item, Work Center, Machine Center, Union, all templates, Standard Address (AJ Ansari, 2026-10-17).
  - Employee alternative-address activation (dates, Alt. Address Code) is not changed.

**FR-1 (new item 0, before item 1):**

> Wherever FR-1 to FR-9 say customer, Customer Card or customer address, they apply to every address source in FR-10, its card page and its address fields, with the exceptions in FR-10 to FR-16. The Customer's behaviour and messages stay exactly as in 1.0.0.0, except where OQ-35 and OQ-36 are approved.

**FR-1.7:** "One customer per user action, enforced" becomes "One record (address block) per user action, enforced". The rest is unchanged. The new generic procedure has the same caller check.

**FR-4:**
- "writes the five suggested values to the customer" becomes "… to the record's address block".
- "permission to modify customers" becomes "permission to modify the record's table".
- The address-changed message: Customer keeps the 1.0.0.0 text. Other sources get "The address was changed while the suggested address was open, so nothing was updated. Run Validate Address again."
- The no-permission text for other sources: "You can't accept the suggested address because you don't have permission to change <table> records. Choose OK or Cancel to close without changes."

**FR-5 (append):**
- Each entry also records the **source**: its table, the record (by its system ID, which survives renames), the **address type** (Main, or Ship-to for the company's ship-to address), and a **source description** made of the table name and the record's key, for example "Vendor 10000" or "Ship-to Address C00010 MAIN". The description never contains a name. The log stores no name of a customer, vendor, contact, employee or resource.
- The log list shows the source table, the source description and the address type.
- **Customer No.** is filled only for checks of a Customer's address. The Customer Card's log action is unchanged and still shows entries written by 1.0.0.0.
- Every other card in FR-10 has an **Address Validation Log** action that shows that record's entries only. Company Information shows both of its blocks.
- A renamed source keeps its entries (system ID). The description keeps the key as it was at the check.
- Deleting any source record keeps its entries.
- An entry can't be inserted without a source table, and an entry for a Customer can't be inserted without a customer number.

**FR-6 Permissions (replace the last bullet):**

> The extension's permission sets cover only the extension's own objects. Users also need their normal Business Central permissions: read and modify on the table whose address they check (FR-14).

**FR-7 (add rows, both "Not logged"):**
- "The record isn't one this app can validate" → "Address validation is not available for this record."
- "Record not found" → for a Customer, the 1.0.0.0 text "The customer was not found."; otherwise "The record was not found."

**FR-8 (add, only if OQ-36 is approved):**

> A Country/Region change that makes Business Central clear City, State or ZIP Code resets Address Validated to No, because one of the five values changed. The country itself still does not count.

**FR-9 (append):**
- **Contact family.** Accepting a suggestion on a Customer or Vendor updates the linked Contact, as Customer does today. Accepting on a Bank Account does the same: the extension asks Business Central to update the linked Contact. Accepting on a Contact lets Business Central update the linked Customer, Vendor, Bank Account and Employee and, when Marketing Setup "Inherit Address Details" is on, the company's persons whose address equalled the company's.
- **Employee → Resource.** Accepting on an Employee with a linked Resource updates the Resource's address, as Business Central does for a user edit.
- Company Information, Location, Responsibility Center, Ship-to, Order and Remit Address, both bank-account address tables and both alternative-address tables have no linked records that are updated.
- Change Log and Last Date Modified behave as for Customer, on tables that have them.

**§2 Objectives (add):**

| # | Objective | Value delivered | Measured by |
|---|---|---|---|
| O7 | Validated US addresses across master data | The same one-click check and status on every master-data record that holds an address | FR-10–FR-12; tests 24–33 |

**§3 Consumers.** The "Staff who maintain customers" row becomes "Staff who maintain customers, vendors, contacts, employees, resources, locations and bank accounts". Administrators also maintain Company Information and Responsibility Centers.

**§4.1 Verified platform capabilities (add rows, checked 2026-10-17):**

| # | Capability | Verified? | How checked | Result and consequence |
|---|---|---|---|---|
| o | The 15 tables have the six address fields at the Customer lengths | Yes | Symbols | Table §2 of the TDD amendment. Every length 100/50/30/30/20/10 |
| p | Each card can host a read-only field and the actions | Yes | Symbols + compile probe (AL 18.1) | `area()` is not allowed in a page extension. `addlast(Processing)` / `addlast(Promoted)` / `addlast(Navigation)` work even where the page has none (Vendor Bank Account Card has no actions at all) |
| q | Which tables standard BC copies by field number | Yes | Base App source | Customer, Vendor, Bank Account ↔ Contact (TransferFields) |
| r | Which standard copies use direct assignment | Yes | Base App source | Company contact → persons, Contact → Employee, Employee → Resource. Integration events exist on each |
| s | A Country/Region change clears City/ZIP/State | Yes | Base App source (Post Code.CheckClearPostCodeCityCounty) | FR-8 addition (OQ-36) |
| t | TransferFields copies table-extension fields with the same number | **Not verified** (platform behaviour) | — | Test 32 |
| u | xRec equals Rec on a code-driven modify | **Partly** (stated in Base App Contact code) | Base App source | Why the extension calls the Bank Account and Employee sync itself (FR-9) |

**§5 Design rules.**
- "One customer per user action" → "One record per user action".
- "Extend, never modify, standard objects" now names the 16 tables and their cards.
- Add: "The log never stores a name; a source is identified by table, system ID, key and address type."
- Add: "Address Validated changes only by the extension and, where OQ-35 is approved, when standard Business Central copies an address between linked records, in which case the indicator travels with the address."

**§6 Inventory (add rows):**

| Entity | Source table | Object type | R/RW | Global or localized | Notes |
|---|---|---|---|---|---|
| Address source map | — | Codeunit (internal) | — | Global | Which fields hold each source's address. Reads and writes them |
| Address type | — | Enum | — | Global | Main, Ship-to |
| Per source: Address Validated | each FR-10 table | Table extension | RW (by the extension only) | US | Default No, read-only |
| Per source: card | each FR-10 card | Page extension | RW (on Accept/Confirmed only) | US | Validate Address, log action, indicator |
| Sync rules (OQ-35) | Contact, Employee, Resource and the family | Codeunit (subscribers) | W | Global | The indicator follows standard address copies |
| Upgrade | Log, Customer → Contact | 2 upgrade codeunits + tag codeunit | W | Global | FR-16 |

The Contact row changes from "Not a validation target" to "Validation target (FR-10), and still updated by sync".

**§6.1 Deferred.**
- Remove the "Ship-to Address and Vendor validation (G5)" row (now delivered).
- Add:
  - "Validate Address on list pages, any table" — later scoping.
  - "Union (5209)" — out (AJ Ansari).
  - "Updating documents that copied an address" — out.

**§7 NFR.**
- Performance: still exactly one HTTPS call per check, and one permission check per check for the source's table.
- Where OQ-35 is approved: a Confirmed or Not Found on a Customer, Vendor or Bank Account also updates its linked Contact (one extra modify).
- Cost: the free monthly allowance and the daily cap now cover checks on all sources. The daily cap stays the control.

## B. New requirements

### FR-10 Address sources
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

### FR-11 Validate Address on every source
1. Every card in FR-10 has a **Validate Address** action:
   - in Actions > Functions where the page has a Functions group (Customer, Vendor, Employee, Contact, Resource), otherwise under Actions;
   - promoted to the Process category where the page has one, otherwise to the page's promoted area.
2. **Company Information has two actions.** "Validate Address" checks the company address (Address, Address 2, City, County, Post Code, Country/Region Code). "Validate Ship-to Address" checks the Ship-to fields. Each has its own indicator, comparison, write and log entry.
3. Everything in FR-1 to FR-7 applies to each source and block:
   - save first;
   - preconditions in the same order;
   - the US rule: the block's Country/Region Code is blank or equal to the setup's US code;
   - the privacy notice;
   - one request, which carries no name, number or key of the record;
   - the same outcomes, dialog, Accept rules (lengths, concurrency, no truncation) and errors.
4. Every card also has an **Address Validation Log** action that opens the log filtered to that record (FR-5).

### FR-12 Address Validated on every source
1. Each source table gets a read-only Yes/No **Address Validated**, shown next to its address on its card. Company Information gets a second one, **Ship-to Address Validated**, next to the ship-to address.
2. Default No for new records and for records that exist at install or upgrade. Exception: Customer flags from 1.0.0.0 are kept (FR-16).
3. FR-8's set and reset rules apply per source and block:
   - set on Accept or Confirmed;
   - reset on Not Found for users allowed to modify that table;
   - unchanged on Ignore and Error;
   - reset when a user edits Address, Address 2, City, State or ZIP Code of that block;
   - for Company Information, the company fields reset only the company indicator and the Ship-to fields only the ship-to indicator.
4. **Linked records (only if OQ-35 is approved).** When standard Business Central copies an address between linked records, the copied record's indicator takes the value of the record it was copied from:
   - Customer, Vendor and Bank Account ↔ their Contact;
   - a company contact → its persons (Inherit Address Details);
   - a person linked to a company;
   - Contact → Employee;
   - Employee → Resource.

   A Confirmed or Not Found on a Customer, Vendor, Bank Account or Contact also updates the indicator of its linked records. For a user who may not modify contacts, the linked Contact is left unchanged and the check still completes.
5. **Known limitation:** writes outside these links that skip field validation (imports, configuration packages, the assisted company setup wizard, other extensions) are not detected. This is the same limitation as 1.0.0.0.

### FR-13 Log for every source
FR-5 applies to every source as amended in A. The retention policy, the read-only rule, ADMIN-only deletion and the data classification are unchanged.

### FR-14 Permissions per source
- The USE set lets a user run Validate Address on every source.
- To accept, or to change the indicator, the user needs modify permission on the source's table. Confirmed and Not Found change the indicator only for such users (FR-8, per table).
- The records Business Central updates with it (FR-9) need their normal permissions:
  - Contact, for Customer, Vendor and Bank Account;
  - Customer, Vendor, Bank Account and Employee, for a linked Contact;
  - Resource, for an Employee with a linked resource.
- A failure there is logged as Error and nothing is changed (FR-7).
- Company Information normally needs an administrator.

### FR-15 Contacts: companies and persons
- Company and person contacts are validated the same way. The action is shown for both.
- A person whose address was inherited from its company keeps its own indicator. It follows the company's only through FR-12.4 (OQ-35).
- Accept on a person never changes its company.

### FR-16 Upgrade from 1.0.0.0
1. Installing 1.1.0.0 over 1.0.0.0 keeps all data and needs no reinstall (Schema Sync Mode: Add).
2. Every existing log entry becomes a Customer entry: source table Customer, address type Main, the customer's system ID when the customer still exists, description "Customer <No.>".
3. Customer indicators are kept.
4. Only if OQ-34's shared field is approved: each validated customer's linked Contact is marked validated when its address equals the customer's.
5. Each step runs once per company, never on a fresh install, and never twice (Standards §9.3, §9.6).

### §7.2 Acceptance tests (add)
| # | Scenario | Expected | How tested |
|---|---|---|---|
| 24 | Each FR-10 card (16 sources incl. the company ship-to block) | Validate Address present and promoted; indicator shown read-only next to the address; log action present | Manual |
| 25 | Accept on each source | The five values written exactly as returned; its indicator Yes; one log entry naming table, record, address type and key, Customer No. blank except for Customer | Automated |
| 26 | Confirmed, Not Found, Ignore, Error on a Vendor | FR-8 outcomes per source | Automated |
| 27 | Editing Address, Address 2, City, State or ZIP on each source | Its indicator No | Automated |
| 28 | Company Information | Ship-to and company blocks validate, write and reset independently | Automated |
| 29 | Vendor with Country/Region CA | US-only message; no call; no log | Automated |
| 30 | User without modify on the source's table | Dialog shows Accept is not possible; record unchanged | Manual |
| 31 | Company and person contacts | Both validate. With OQ-35: a person inheriting the company's address takes the company's indicator | Automated (sets Marketing Setup; restores it) |
| 32 | Customer, Vendor, Bank Account ↔ Contact | Accept updates the Contact's address and indicator; editing the Contact's address clears the partner's indicator (proves §4.1 t) | Automated |
| 33 | Employee with a linked Resource | Accept updates the Resource's address and, with OQ-35, its indicator | Automated |
| 34 | Upgrade from 1.0.0.0 in two companies | FR-16; a second run changes nothing; a fresh install runs no upgrade | Manual (Standards §9.6) |
| 35 | Customer regression | The 61 existing automated tests pass unchanged | Automated |
| 36 | Validation called for an unsupported table | Refused; nothing sent or logged | Automated |
| 37 | Customer Card log action | Shows entries written by 1.0.0.0 and 1.1 | Manual |
| 38 | Log list | Source table, description and type shown; no name stored | Automated + manual |
| 39 | (OQ-36) Country change that clears City/ZIP | Indicator No | Automated |

**Test app:**
- Two new test codeunits (sources; sync).
- Library additions to create and clean up test records in every source table, using keys starting GAVUT, and to save and restore Company Information and Marketing Setup.
- Tests 24, 30, 34 and 37 are manual.

### §9 Open questions (add)
OQ-34 to OQ-46, as in section 5 of this report. Owner: AJ Ansari. Raised: SC-1, 2026-10-17.

---

# 4. TDD amendment text — new §15 (ready to paste)

## 15. Scope change SC-1 — amendments for version 1.1.0.0 (DRAFT, not signed off)

**Baseline.** `docs/4-prove/PostDevTDD.md` Part B (as built, 1.0.0.0) is the baseline. §15 overrides Part B where it says so. Everything else in Part B and Part D stays normative. Step 10 folds §15 into PostDevTDD. Symbols: Base Application 28.5.54151.55594, System 28.0.54688.0, System Application 28.5.54151.55108. Anchors were compile-probed with AL 18.1.43.24897.

### 15.1 Identity
- `app.json`:
  - `version` `1.1.0.0` (first build). Builds after it are 1.1.0.1, 1.1.0.2 …
  - `idRanges` `[{60093–60122}, {60134–60192}]` (the tail and the new block merged).
- Test app:
  - `version` `0.0.0.8` (Revision; OQ-44);
  - dependency on main `1.1.0.0`;
  - `idRanges` unchanged `[{60123–60133}]`.
- The namespace stays `OnlyBCFans.GoogleAddress` (flat).
- New folders:
  - `src/Sources/` — the 30 extensions, 60144 and 60148;
  - `src/Upgrade/` — 60145–60147.
- The Customer extensions stay in `src/Validation/`.

### 15.2 ID allocation (new block 60143–60192; the 1.0 buffers 60103–60108 and 60120–60122 are **not** used and stay as growth for modules A and B)
| Module | Sub-block | Used | Spare |
|---|---|---|---|
| D Engine and upgrade | 60143–60150 | 60143–60148 | 60149–60150 |
| E Sales and customer | 60151–60156 | 60151–60154 | 60155–60156 |
| F Purchasing and vendor | 60157–60166 | 60157–60164 | 60165–60166 |
| G Company and org | 60167–60176 | 60167–60174 | 60175–60176 |
| H People | 60177–60188 | 60177–60186 | 60187–60188 |
| Tail | 60189–60192 | — | 4 |

That is 36 used and 14 spare in the new block, plus 18 spare from 1.0 (A 6, B 3, tail none left after the merge, C 5 in the test app). Standards §5.2 requires 10 or more.

**Field numbers.**
- **Recommended (OQ-34): uniform.**
  - Field `60093 "obcfgav Address Validated"` on every source table (Customer as built).
  - Company Information also gets `60094 "obcfgav Ship-to Validated"` (25 characters).
  - Either way, the four Contact-family tables (Customer, Vendor, Bank Account, Contact) must share 60093 (F1).
- **Alternative if AJ chooses unique numbers:**
  - field number = the table extension's object ID (e.g. Vendor 60157);
  - Company ship-to 60175;
  - 60147 is not built;
  - 60148 gains six subscribers to copy the flag through TransferFields: CustCont-Update `OnAfterTransferFieldsFromCustToCont(var Contact; Customer)`, VendCont-Update `OnAfterTransferFieldsFromVendToCont(var Contact; Vendor)`, BankCont-Update `OnAfterTransferFieldsFromBankAccToCont(var Contact; BankAccount)`, and CustVendBank-Update `OnAfterUpdateCustomer` / `OnAfterUpdateVendor` / `OnAfterUpdateBankAccount`.

### 15.3 Object plan
| ID | Type | Name | File | Batch |
|---|---|---|---|---|
| 60143 | Enum | "obcfgav Address Type" | `src/Sources/obcfgavAddressType.Enum.al` | B1 |
| 60144 | Codeunit | "obcfgav Address Source" | `src/Sources/obcfgavAddressSource.Codeunit.al` | B1 |
| 60145 | Codeunit | "obcfgav Upgrade Tags" | `src/Upgrade/obcfgavUpgradeTags.Codeunit.al` | B1 |
| 60146 | Codeunit (Upgrade) | "obcfgav Upgrade Log Source" | `src/Upgrade/obcfgavUpgradeLogSource.Codeunit.al` | B1 |
| 60147 | Codeunit (Upgrade) | "obcfgav Upgrade Contact Flag" (only with OQ-34 shared) | `src/Upgrade/obcfgavUpgradeContactFlag.Codeunit.al` | B3 |
| 60148 | Codeunit | "obcfgav Address Sync Subscr." (only with OQ-35) | `src/Sources/obcfgavAddressSyncSubscr.Codeunit.al` | B4 |
| 60151 / 60152 | TableExt / PageExt | "obcfgav Ship-to Address" / "obcfgav Ship-to Address Card" (extends page "Ship-to Address") | `obcfgavShiptoAddress.TableExt.al` / `obcfgavShiptoAddressCard.PageExt.al` | B2 |
| 60153 / 60154 | TableExt / PageExt | "obcfgav Customer Bank Account" / "obcfgav Cust. Bank Acc. Card" | `obcfgavCustomerBankAccount.TableExt.al` / `obcfgavCustBankAccCard.PageExt.al` | B2 |
| 60157 / 60158 | TableExt / PageExt | "obcfgav Vendor" / "obcfgav Vendor Card" | `obcfgavVendor.TableExt.al` / `obcfgavVendorCard.PageExt.al` | B2 |
| 60159 / 60160 | TableExt / PageExt | "obcfgav Order Address" / "obcfgav Order Address Card" (page "Order Address") | `obcfgavOrderAddress.TableExt.al` / `obcfgavOrderAddressCard.PageExt.al` | B2 |
| 60161 / 60162 | TableExt / PageExt | "obcfgav Remit Address" / "obcfgav Remit Address Card" (page "Remit Address") | `obcfgavRemitAddress.TableExt.al` / `obcfgavRemitAddressCard.PageExt.al` | B2 |
| 60163 / 60164 | TableExt / PageExt | "obcfgav Vendor Bank Account" / "obcfgav Vendor Bank Acc. Card" | `obcfgavVendorBankAccount.TableExt.al` / `obcfgavVendorBankAccCard.PageExt.al` | B2 |
| 60167 / 60168 | TableExt / PageExt | "obcfgav Company Information" / "obcfgav Company Info. Card" (page "Company Information") | `obcfgavCompanyInformation.TableExt.al` / `obcfgavCompanyInfoCard.PageExt.al` | B3 |
| 60169 / 60170 | TableExt / PageExt | "obcfgav Location" / "obcfgav Location Card" | `obcfgavLocation.TableExt.al` / `obcfgavLocationCard.PageExt.al` | B3 |
| 60171 / 60172 | TableExt / PageExt | "obcfgav Responsibility Center" / "obcfgav Resp. Center Card" | `obcfgavResponsibilityCenter.TableExt.al` / `obcfgavRespCenterCard.PageExt.al` | B3 |
| 60173 / 60174 | TableExt / PageExt | "obcfgav Bank Account" / "obcfgav Bank Account Card" | `obcfgavBankAccount.TableExt.al` / `obcfgavBankAccountCard.PageExt.al` | B3 |
| 60177 / 60178 | TableExt / PageExt | "obcfgav Employee" / "obcfgav Employee Card" | `obcfgavEmployee.TableExt.al` / `obcfgavEmployeeCard.PageExt.al` | B3 |
| 60179 / 60180 | TableExt / PageExt | "obcfgav Alternative Address" / "obcfgav Alt. Address Card" | `obcfgavAlternativeAddress.TableExt.al` / `obcfgavAltAddressCard.PageExt.al` | B3 |
| 60181 / 60182 | TableExt / PageExt | "obcfgav Contact" / "obcfgav Contact Card" | `obcfgavContact.TableExt.al` / `obcfgavContactCard.PageExt.al` | B3 |
| 60183 / 60184 | TableExt / PageExt | "obcfgav Contact Alt. Address" / "obcfgav Cont. Alt. Addr. Card" | `obcfgavContactAltAddress.TableExt.al` / `obcfgavContAltAddrCard.PageExt.al` | B3 |
| 60185 / 60186 | TableExt / PageExt | "obcfgav Resource" / "obcfgav Resource Card" | `obcfgavResource.TableExt.al` / `obcfgavResourceCard.PageExt.al` | B3 |
| 60129 | Codeunit (Test), test app | "obcfgav Source Tests" | `Tests/src/obcfgavSourceTests.Codeunit.al` | B4 |
| 60130 | Codeunit (Test), test app | "obcfgav Sync Tests" | `Tests/src/obcfgavSyncTests.Codeunit.al` | B4 |

- Every name is 30 characters or fewer.
- The extension file paths are under `src/Sources/`. File names follow AA0215: the name with spaces, hyphens and dots removed.
- Changed 1.0 objects: 60096, 60099, 60100, 60101, 60109, 60110, 60111, 60112, 60113, 60118, and 60116 (B4, OQ-36 only).
- Unchanged: 60117 and every provider, setup and transport object.

### 15.4 Enum 60143 "obcfgav Address Type"
- `Caption = 'Address Type';`
- `Extensible = false` is proposed: a closed set that the field map depends on. It must be asked per Step 03 rule (OQ-46).
- Values: `0 Main` (Caption 'Main'), `1 "Ship-to"` (Caption 'Ship-to').
- No blank value on purpose: Main is the default for every non-company row and for upgraded log rows.

### 15.5 Codeunit 60144 "obcfgav Address Source" (`Access = Internal`)
**using:** `Microsoft.Bank.BankAccount`, `Microsoft.CRM.BusinessRelation`, `Microsoft.CRM.Contact`, `Microsoft.Foundation.Company`, `Microsoft.HumanResources.Employee`, `Microsoft.Inventory.Location`, `Microsoft.Projects.Resources.Resource`, `Microsoft.Purchases.Remittance`, `Microsoft.Purchases.Vendor`, `Microsoft.Sales.Customer`.

**Field map.** `Map: array[7] of Integer`, indexed as: 1 Address, 2 Address 2, 3 City, 4 County (State), 5 Post Code (ZIP), 6 Country/Region Code, 7 Address Validated.
- Built in `GetMap` with a `case SourceTableNo of`, using typed `<Rec>.FieldNo(...)` for base fields so they are compile-checked. The numbers are §2 of this report.
- Index 7 = `ValidatedFieldNo()` (60093). For Company Information `AddressType = "Ship-to"`, index 7 = `ShipToValidatedFieldNo()` (60094), and indexes 1–6 = the Ship-to fields 24/25/26/33/32/37.
- `"Ship-to"` for any other table returns false.
- Constants instead of `FieldNo` on the extension fields keep B1 free of forward references (F12).

| Procedure | Behaviour |
|---|---|
| `GetMap(SourceTableNo: Integer; AddressType: Enum "obcfgav Address Type"; var Map: array[7] of Integer): Boolean` | As above. `Clear(Map)` first. Unknown table → false |
| `IsSupported(SourceTableNo; AddressType): Boolean` | `GetMap` and `RecRef.Open(SourceTableNo)` and `RecRef.FieldExist(Map[7])`, then `Close` |
| `OpenSource(var SourceRecRef: RecordRef; SourceTableNo; SourceSystemId: Guid; AddressType; ForUpdate: Boolean): Boolean` | `SourceRecRef.Open(SourceTableNo)`. If `ForUpdate`, `SourceRecRef.LockTable()`; otherwise `SourceRecRef.SetLoadFields(Map[1..7])` plus the primary-key fields. `exit(SourceRecRef.GetBySystemId(SourceSystemId))` |
| `GetValue(var SourceRecRef; AddressType; Index: Integer): Text` | `Format(SourceRecRef.Field(Map[Index]).Value)` |
| `GetLength(var SourceRecRef; AddressType; Index): Integer` | `SourceRecRef.Field(Map[Index]).Length` |
| `FillOriginal(var SourceRecRef; AddressType; var TempAddressBuffer)` | `Init()`. Sets Source Table No. := `SourceRecRef.Number`, Address Type, Source SystemId := `SourceRecRef.Field(SourceRecRef.SystemIdNo).Value`, Source Description := `Describe(...)`, "Customer No." := the "No." value **only when Number = Database::Customer**, Original Address / Address 2 / City / State / ZIP from indexes 1–5 (`CopyStr` to the buffer lengths). Never inserts |
| `DiffersFromSnapshot(var SourceRecRef; AddressType; TempAddressBuffer): Boolean` | Any of indexes 1–5 differs from the Original fields (exact compare, as `CustomerDiffersFromSnapshot`) |
| `AssignSuggested(var SourceRecRef; AddressType; TempAddressBuffer)` | Index 1..5 `.Value := CopyStr(Suggested…, 1, Length)` in the order Address, Address 2, City, County = Suggested State, Post Code = Suggested ZIP. Index 7 `.Value := true`. Direct assignment, never `Validate` |
| `GetValidated(var SourceRecRef; AddressType): Boolean` / `SetValidated(var SourceRecRef; AddressType; NewValue: Boolean)` | Index 7 |
| `SaveSource(var SourceRecRef: RecordRef; AddressType; AddressWritten: Boolean)` | See below |
| `Describe(var SourceRecRef; AddressType): Text[250]` | `StrSubstNo(DescriptionTok, SourceRecRef.Caption, KeyText)`, where KeyText = the non-blank primary-key values of `KeyIndex(1)` joined by a space. For `"Ship-to"`, `StrSubstNo(BlockDescriptionTok, Description, Format(AddressType))`. `CopyStr` to 250. **No name field is ever read** |
| `[InternalEvent(false)] local procedure OnAfterSaveSource(var SourceRecRef: RecordRef; AddressType: Enum "obcfgav Address Type"; AddressWritten: Boolean)` | Raised at the end of `SaveSource`. No subscriber before B4 |

**`SaveSource` per table:**
- **`Database::Customer`, AddressWritten:** `SourceRecRef.SetTable(Customer); Customer.SetForceUpdateContact(true); Customer.Modify(true);` (identical to 1.0.0.0).
- **`Database::Vendor`, AddressWritten:** the same with Vendor.
- **`Database::"Bank Account"`:** `SourceRecRef.Modify(true)`. If AddressWritten: `SourceRecRef.SetTable(BankAccount); BankContUpdate.OnModify(BankAccount);` (codeunit "BankCont-Update").
- **`Database::Employee`, AddressWritten:**
  1. `SourceRecRef.SetTable(Employee); OldEmployee.GetBySystemId(Employee.SystemId);` (the stored version, before the write)
  2. `SourceRecRef.Modify(true);`
  3. `if Resource.ReadPermission() then EmployeeResourceUpdate.HumanResToRes(OldEmployee, Employee);`
- **Every other case, and flag-only writes:** `SourceRecRef.Modify(true)`.
- Then `OnAfterSaveSource(...)`.

**Labels (all Locked):** `DescriptionTok '%1%2'` (Comment: %1 = table caption, %2 = key values each preceded by a space), `BlockDescriptionTok '%1 (%2)'` (Comment: %1 = description, %2 = address type).

### 15.6 Codeunit 60113 "obcfgav Address Validation" (changes to Part B-22)
**Public procedures** (each guarded one reads the caller as its first statement, Part D-2):

| Procedure | Access | Behaviour |
|---|---|---|
| `SetTransport`, `SetProvider` | public, checked | unchanged |
| `ValidateCustomerAddress(CustomerNo: Code[20])` | public, checked | unchanged signature and behaviour |
| `TryValidateCustomerAddress(CustomerNo: Code[20]; var Outcome; var UserMessage): Boolean` | public, checked | Caller check; `Clear(Outcome); UserMessage := '';` `Customer.SetLoadFields("No.")`; not found → `NoCustomerErr`, false; else `exit(RunValidation(Database::Customer, Customer.SystemId, Enum::"obcfgav Address Type"::Main, Outcome, UserMessage))` |
| **`ValidateAddress(SourceTableNo: Integer; SourceSystemId: Guid; AddressType: Enum "obcfgav Address Type")`** | public, checked (new) | Same as `ValidateCustomerAddress`, on `RunValidation` |
| **`TryValidateAddress(SourceTableNo: Integer; SourceSystemId: Guid; AddressType: Enum "obcfgav Address Type"; var Outcome: Enum "obcfgav Validation Result"; var UserMessage: Text): Boolean`** | public, checked (new) | `exit(RunValidation(...))` |
| `ValuesDiffer` | public | unchanged |
| `CanModifyCustomers(): Boolean` | public | `exit(CanModifySource(Database::Customer))` |
| **`CanModifySource(SourceTableNo: Integer): Boolean`** | public, not checked (read-only) | `GetEffectivePermission(Table Data, SourceTableNo)."Modify Permission" = Yes` |
| `DeliveryWarning` | internal | unchanged |

**`local procedure RunValidation(SourceTableNo; SourceSystemId; AddressType; var Outcome; var UserMessage): Boolean`.** This is B-22's flow with these replacements:
1. `Clear(Outcome); UserMessage := '';`
2. Not `AddressSource.IsSupported` → `UnsupportedSourceErr`, false.
3. `CanModify := CanModifySource(SourceTableNo)`.
4. Not `AddressSource.OpenSource(SourceRecRef, …, false)` → `NoCustomerErr` when the table is 18, else `NoRecordErr`; false.
5. `CheckPreconditions(SourceRecRef, AddressType, UserMessage)` — same four checks as B-22, reading index 6 (country), 1 (address), 3 (city), 4 (state) and 5 (ZIP) through `AddressSource.GetValue`.
6. Privacy notice (unchanged).
7. `AddressSource.FillOriginal(...)`, then the provider call and `Commit()` (unchanged).
8. Outcome handling unchanged except:
   - `FitsSourceFields(SourceRecRef, AddressType, Buffer, BlockReason)` replaces `FitsCustomerFields` (lengths from `AddressSource.GetLength`, same caption labels);
   - `NoPermissionTxt` for Customer, `StrSubstNo(NoPermissionRecordTxt, SourceRecRef.Caption)` otherwise;
   - `AddressChangedMsg` for Customer, `AddressChangedRecordMsg` otherwise;
   - `RunWriter`, `HandleProviderFailure` and `LogWriteFailure` lose their `CustomerNo` parameter (the identity is in the buffer).

Remove `CheckPreconditions(Customer: Record Customer …)`, `FillOriginal(…, Customer)` and `FitsCustomerFields`.

**New labels:**
- `NoRecordErr 'The record was not found.'`
- `UnsupportedSourceErr 'Address validation is not available for this record.'`
- `AddressChangedRecordMsg 'The address was changed while the suggested address was open, so nothing was updated. Run Validate Address again.'`
- `NoPermissionRecordTxt 'You can''t accept the suggested address because you don''t have permission to change %1 records. Choose OK or Cancel to close without changes.'`, Comment `'%1 = table caption, for example Vendor'`

Every Customer label stays verbatim.

### 15.7 Codeunit 60118 "obcfgav Validation Writer" (changes to Part B-20; stays `Access = Internal`)
- `using Microsoft.Sales.Customer` removed. Global `AddressSource: Codeunit "obcfgav Address Source"`. Global `CustomerNo` removed.
- `Init(NewOutcome: Enum "obcfgav Validation Result"; var TempResult: Record "obcfgav Address Buffer" temporary; NewAccepted: Boolean; NewCanModify: Boolean)`
- `InsertLogEntry(LogResult: Enum "obcfgav Validation Result"; var TempResult: Record "obcfgav Address Buffer" temporary; LogAccepted: Boolean)`. As B-20, plus `Log."Customer No." := TempResult."Customer No."`, Source Table No., Address Type, Source SystemId and Source Description from the buffer.
- **`WriteAcceptedSuggestion`:**
  1. `if not AddressSource.OpenSource(SourceRecRef, Buffer."Source Table No.", Buffer."Source SystemId", Buffer."Address Type", true) then Error(SourceNotFoundErr, SourceRecRef.Caption);`
  2. If `DiffersFromSnapshot` → AddressChanged / Ignored / not accepted; exit.
  3. `AssignSuggested`; `SaveSource(SourceRecRef, AddressType, true)`.
- **`SetAddressValidated(NewValue)`:** `if not CanModify then exit`; `OpenSource(..., true)` else the same Error; exit when `GetValidated = NewValue`; `SetValidated`; `SaveSource(..., false)`.
- Label `SourceNotFoundErr 'The %1 record no longer exists, so nothing was updated.'`, Comment `'%1 = table caption'`. Deviation: for a deleted Customer this replaces the platform "does not exist" text.

### 15.8 Table 60111 "obcfgav Address Buffer" (temporary; additive)
- Add: `30 "Source Table No." Integer`, `31 "Address Type" Enum "obcfgav Address Type"`, `32 "Source SystemId" Guid`, `33 "Source Description" Text[250]`. Captions = names.
- Field 2 "Customer No." stays; it is filled only for Customer.

### 15.9 Table 60109 "obcfgav Validation Log" (additive) and page 60110
**Fields added:**
- `24 "Source Table No." Integer` (Caption 'Source Table No.')
- `25 "Address Type" Enum "obcfgav Address Type"` (Caption 'Address Type')
- `26 "Source SystemId" Guid` (Caption 'Source SystemId', `DataClassification = SystemMetadata`)
- `27 "Source Description" Text[250]` (Caption 'Source')
- `28 "Source Table Caption" Text[249]`: `FieldClass = FlowField; CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Table), "Object ID" = field("Source Table No."))); Editable = false;` Caption 'Source Table'. Add `using System.Reflection` (compile-probed).

**Key added:** `SourceCheckedAt("Source Table No.", "Source SystemId", "Checked At")`.

**OnInsert:** `Rec.TestField("Source Table No."); if Rec."Source Table No." = Database::Customer then Rec.TestField("Customer No.");`

Field 2, its TableRelation and key `CustomerCheckedAt` are unchanged.

**Page 60110:**
- After `customerNo`, add `sourceTableCaption` (ToolTip 'Specifies the kind of record whose address was checked, for example Vendor.'), `sourceDescription` (ToolTip 'Specifies the record whose address was checked, by its key.') and `addressType` (ToolTip 'Specifies which address of the record was checked: the main address or the company''s ship-to address.').
- Add `sourceTableNo` with `Visible = false`.
- customerNo ToolTip → 'Specifies the number of the customer whose address was checked. It is blank for other kinds of records.'

### 15.10 Text-only changes
| Object | Control or label | New text |
|---|---|---|
| 60112 | ToolTips of the five Current controls | 'Specifies the … currently on the record.' (street address / second address line / city / state / ZIP Code) |
| 60096 | enabled | '…When it is off, the Validate Address actions do not send any address to Google Maps.' |
| 60096 | usCountryRegionCode | '…Only addresses with this code, or no code, are checked.' |
| 60096 | TestConnection | '…No address is checked and no business data is sent.' |
| 60100 | `AssistedSetupDescriptionTxt` | 'Enter the Google Maps API key used to validate addresses.' Reaches new companies only (registration is insert-if-missing) |

### 15.11 Table extensions (B2, B3). Template = 60116 as built
Every table extension:
- `field(60093; "obcfgav Address Validated"; Boolean) { Caption = 'Address Validated'; DataClassification = CustomerContent; InitValue = false; Editable = false; }`;
- `modify(Address)`, `modify("Address 2")`, `modify(City)`, `modify(County)`, `modify("Post Code")`, each with `trigger OnAfterValidate() begin ResetAddressValidatedIfChanged(); end;`;
- with OQ-36, also `modify("Country/Region Code")`;
- `local procedure ResetAddressValidatedIfChanged()` exactly as 60116 (exit when false; any of the five fields `<> xRec` → false);
- the `using` = the table's namespace (§2).

**Company Information (60167):**
- adds `field(60094; "obcfgav Ship-to Validated"; Boolean)`, Caption 'Ship-to Address Validated', with the same properties;
- `modify` on "Ship-to Address", "Ship-to Address 2", "Ship-to City", "Ship-to County" and "Ship-to Post Code" call `ResetShipToValidatedIfChanged()`, which compares those five against xRec;
- the main-block modifies call `ResetAddressValidatedIfChanged()`;
- no modify on "Ship-to Country/Region Code".

### 15.12 Page extensions (B2, B3). Template = 60117 as built
**Each page extension:**
- **Field** `field(obcfgavAddressValidated; Rec."obcfgav Address Validated")`: Caption 'Address Validated'; ToolTip 'Specifies whether the current address was confirmed by, or accepted from, the address validation service. It is set by Validate Address and cleared when the address is edited.'; `ApplicationArea = All; Editable = false;`. Placed at the field anchor in §2.
- **Action** `obcfgavValidateAddress`: Caption 'Validate Address'; ToolTip 'Check this <noun>''s address with the address validation service (Google Maps) and accept or ignore the suggested address.'; `Image = CheckList`. `OnAction`:
  ```al
  CurrPage.SaveRecord();
  Commit();
  AddressValidation.ValidateAddress(Database::<Table>, Rec.SystemId, Enum::"obcfgav Address Type"::Main);
  Rec.GetBySystemId(Rec.SystemId);
  CurrPage.Update(false);
  ```
- **Promote:** `actionref(obcfgavValidateAddr_Promoted; obcfgavValidateAddress)` at the promote anchor.
- **Log action** `obcfgavValidationLog`: Caption 'Address Validation Log'; ToolTip 'View the address validation checks for this <noun>.'; `Image = Log; RunObject = page "obcfgav Log Entries"; RunPageLink = "Source Table No." = const(<ID>), "Source SystemId" = field(SystemId); RunPageView = sorting("Source Table No.", "Source SystemId", "Checked At") order(descending);` at the log anchor.
- **var:** `AddressValidation: Codeunit "obcfgav Address Validation";`

**Nouns:** ship-to address, customer bank account, vendor, order address, remit address, vendor bank account, company, location, responsibility center, bank account, employee, alternative address, contact, contact alternative address, resource.

**Company Information (60168):**
- second field `obcfgavShipToValidated` (Caption 'Ship-to Address Validated'; ToolTip 'Specifies whether the current ship-to address was confirmed by, or accepted from, the address validation service. It is set by Validate Ship-to Address and cleared when the ship-to address is edited.') after "Ship-to Country/Region Code";
- second action `obcfgavValidateShipToAddress` (Caption 'Validate Ship-to Address'; passes `::"Ship-to"`), promoted as `obcfgavValidateShipTo_Promoted`;
- one log action covering both blocks.

### 15.13 Codeunit 60148 "obcfgav Address Sync Subscr." (B4, only with OQ-35; `Access = Internal`)
`SameAddress` helpers compare Address, Address 2, City, County and Post Code. No outside calls, so Standards §9.5 needs nothing.

| # | Subscription (verified) | Body |
|---|---|---|
| a | Codeunit "obcfgav Address Source" `OnAfterSaveSource(var SourceRecRef; AddressType; AddressWritten)` | Exit if `AddressWritten` (the standard update already ran) or `not Contact.WritePermission()`. Then: Customer → `SetTable`, `CustContUpdate.OnModify(Customer)`; Vendor → `VendContUpdate.OnModify(Vendor)`; "Bank Account" → `BankContUpdate.OnModify(BankAccount)` |
| b | Table Contact `OnBeforeIsUpdateNeeded(var Contact: Record Contact; xContact: Record Contact; var UpdateNeeded: Boolean)` | `if Contact."obcfgav Address Validated" <> xContact."obcfgav Address Validated" then UpdateNeeded := true;` The loop is finite: CustVendBank-Update writes Customer, Vendor and Bank Account with `Modify()` and no trigger |
| c | Table Contact `OnAfterSyncAddress(var Contact; RecContact; var ContChanged; var ContactBeforeModify)` | If the addresses are the same and the flags differ: `Contact.flag := RecContact.flag; ContChanged := true;` |
| d | Table Contact `OnAfterInheritCompanyToPersonData(var Contact; xContact; NewCompanyContact)` | If the addresses are the same: `Contact.flag := NewCompanyContact.flag` (no Modify; the caller saves) |
| e | Codeunit "CustVendBank-Update" `OnAfterUpdateEmployee(var Employee: Record Employee; Contact: Record Contact)` | Exit if `Employee."No." = ''`. If the addresses are the same and the flags differ: set it; `Employee.Modify(false)` |
| f | Codeunit "Employee/Resource Update" `OnAfterUpdateResource(var Resource: Record Resource; Employee: Record Employee)` | If the addresses are the same: `Resource.flag := Employee.flag` (the standard `Res.Modify(true)` follows) |

With OQ-36, B4 also adds `modify("Country/Region Code")` to 60116 Customer (the Customer behaviour change).

### 15.14 Upgrade and install (Standards Part 9)
**60145 "obcfgav Upgrade Tags"** (`Access = Internal`, `using System.Upgrade`):
- `GetLogSourceTag(): Code[250]` → `'OBCFGAV-SC1-LogSource-20261017'`
- `GetContactFlagTag(): Code[250]` → `'OBCFGAV-SC1-ContactFlag-20261017'` (Locked labels)
- `SetTagsOnInstall()`: each tag `SetUpgradeTag` when not `HasUpgradeTag`
- `[EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerCompanyUpgradeTags', '', false, false)] local procedure RegisterPerCompanyTags(var PerCompanyUpgradeTags: List of [Code[250]])` adds both tags.

**60146 "obcfgav Upgrade Log Source"** (`Subtype = Upgrade; Access = Internal`):
- `OnUpgradePerCompany`: tag guard, then `UpgradeLogSource()`, then set the tag.
- `UpgradeLogSource`: loop **all** log rows with `FindSet(true)`, no filter on the field being changed. Skip rows with Source Table No. `<> 0` (safety check). Set Source Table No. = `Database::Customer`, Address Type = Main, Source SystemId = `Customer.SystemId` when `Customer.Get("Customer No.")`, Source Description = `Customer.TableCaption() + ' ' + "Customer No."` (`CopyStr` 250). `Modify(false)`.

**60147 "obcfgav Upgrade Contact Flag"** (B3, shared numbering only; same tag pattern):
- Customers with the flag true (SetLoadFields on No., the five address fields and the flag).
- For each, the Contact Business Relation with "Link to Table" Customer and "No.".
- `Contact.Get("Contact No.")`. If the addresses are the same and the Contact flag is false: set it; `Modify(false)`.

**60099 Install:** `OnInstallAppPerCompany` → `SetupRegistration.RegisterAll(); UpgradeTags.SetTagsOnInstall();`. Explicit tags instead of `SetAllUpgradeTags()`, because the latter also sets other extensions' registered tags (F9).

### 15.15 Permission sets
- **60101 USE** adds `codeunit "obcfgav Address Source" = X` (B1), `codeunit "obcfgav Upgrade Tags" = X` (B1) and `codeunit "obcfgav Address Sync Subscr." = X` (B4).
- **60102 ADMIN:** no change.
- No `tabledata` changes, because there is no new table (F6).
- Upgrade codeunits get no entry.

### 15.16 Events
- **Published:** `OnAfterSaveSource` on 60144, `InternalEvent`. It is not an extension point; it exists only so B4 stays separate from B1 (Standards §10.2: not part of the public contract).
- **Subscribed, new:** 15.13 a–f and Upgrade Tag `OnGetPerCompanyUpgradeTags`.
- **Existing:** `Company-Initialize.OnCompanyInitialize`, unchanged.

### 15.17 Caller check (Part D-2, updated)
The guarded list adds 60113 `ValidateAddress` and `TryValidateAddress`. `CanModifySource` is not guarded (read-only).

### 15.18 Test app
**60124 Test Library, additions:**
- `CreateSource(SourceTableNo: Integer; Address; Address2; City; State; Zip): Guid`:
  - keys `GAVUT<n>` (Code[10] keys fit);
  - parents created first: Customer for Ship-to and Customer Bank Account; Vendor for Order, Remit and Vendor Bank; Employee for Alternative Address; Contact for Contact Alt. Address;
  - `Insert(true)` with the key set so no number series is used.
- `SaveCompanyInformation` / `RestoreCompanyInformation` and `SetCompanyAddress(AddressType; …)`.
- `SaveMarketingSetup` / `RestoreMarketingSetup` / `SetMarketingSetup(BusRelCodes; InheritAddress)`.
- `GetSourceValue`, `ValidateSourceField(SourceTableNo; SourceSystemId; AddressType; FieldIndex)` (via `FieldRef.Validate`), `AssertSourceAddress`, `AssertSourceValidated(SourceTableNo; SourceSystemId; AddressType; Expected)`.
- `LastLogEntryForSource(SourceTableNo; SourceSystemId; AddressType; var Log)`, `AssertLogSource` (table, type, system ID, description contains the key and **not** the record's Name, Customer No. blank unless table 18).
- `InitSetup` remembers the last log Entry No.
- `CleanUp` deletes:
  - log rows above the remembered Entry No.;
  - every `GAVUT*` record of the 15 tables, children first;
  - then restores Company Information and Marketing Setup.

**60129 "obcfgav Source Tests" (Subtype = Test):**
- `TestAccept<Source>` × 16 and `TestEditResets<Source>` × 16 (tests 25, 27);
- `TestCompanyBlocksIndependent` (28);
- Vendor tests (26, 29): `TestVendorConfirmed`, `TestVendorNotFoundClears`, `TestVendorIgnoreKeeps`, `TestVendorErrorKeeps`, `TestVendorNonUSRefused`, `TestVendorChangedDuringDialog` (generic message), `TestLocationTooLongBlocks`;
- `TestUnsupportedSourceRefused` (Item; 36);
- `TestContactPersonValidates`, `TestContactCompanyValidates` (31);
- `TestCustomerLogKeepsCustomerNo` and `TestLogDescriptionHasNoName` (37, 38).

**60130 "obcfgav Sync Tests" (B4):**
- `TestCustomerAcceptUpdatesContact`, `TestVendorAcceptUpdatesContact`, `TestBankAccAcceptUpdatesContact`;
- `TestContactEditClearsCustomerFlag` (32);
- `TestCustomerNotFoundClearsContact`;
- `TestCompanyAcceptFlagsPerson` (31);
- `TestContactAcceptFlagsEmployee`;
- `TestEmployeeAcceptUpdatesResource` (33);
- `TestCountryClearResetsFlag` (39, OQ-36).

The 61 existing tests are unchanged (35). They still assert on `Log."Customer No."`, which stays filled for customers.

### 15.19 Batch plan (one at a time; lint each, compile once at Step 07 unless OQ-41)
| Batch | Content | Objects / IDs | Behaviour change |
|---|---|---|---|
| B1 Engine | Address Source, Address Type, generic 60113/60118, buffer and log fields, log page, texts, upgrade (log), tags, install, USE grants | New 60143, 60144, 60145, 60146. Changed 60096, 60099, 60100, 60101, 60109, 60110, 60111, 60112, 60113, 60118 | None for Customer; only the 1.0.0.0 message texts are kept. Compiles alone (F12) |
| B2 Sales and purchasing | 6 sources | 60151–60154, 60157–60164 | New sources only |
| B3 Company/org and people | 9 sources + upgrade contact flag | 60167–60174, 60177–60186, 60147 (OQ-34) | New sources only |
| B4 Rest | Sync rules, Customer Country reset, test app | 60148, 60116 (edit), 60101 (line), test app 60124 (edit), 60129, 60130, `app.json` | OQ-35 / OQ-36 only |

### 15.20 Object Register delta
Add the rows in 15.3. Allocated range 60093–60192. Customer field 60093 is no longer "reserved": it is the shared Address Validated number (OQ-34). Events as in 15.16.

### 15.21 Not verified
1. That TransferFields copies table-extension fields with the same number (tests 32 and 34).
2. That xRec = Rec on code-driven modifies through RecordRef. A duplicate standard update would be harmless.
3. That `RecordRef.SetTable` followed by a typed `Modify(true)` raises no concurrency error.
4. That the 15.13 b loop ends in practice. Reasoned from the source; covered by test 32.
5. The US captions on the new cards (OQ-19).
6. That `Contact.WritePermission()` reflects the user's effective rights in a SaaS sandbox.

**Self-sufficiency:** every object, ID, file, field number, anchor, signature, label and batch is given above. The generator needs the OQ-34, OQ-35 and OQ-36 answers before Step 05, because they choose field numbers and include or exclude 60147, 60148 and the Country triggers.

---

# 5. Open questions for AJ Ansari
- **OQ-34 Field numbering.**
  - (a) 60093 on every source and 60094 for the company ship-to block — recommended; the flag travels with the address through standard Contact sync (F1).
  - (b) Unique numbers per table — the proposal; needs six more subscribers and still risks false Yes.
  - Either way, Customer, Vendor, Bank Account and Contact must share a number to avoid stale flags.
- **OQ-35 Flag follows standard address copies (batch 4, codeunit 60148).**
  - Yes — recommended.
  - No — keep as the known limitation of FR-12.5.
  - Note: Yes means a Confirmed or Not Found on a Customer also modifies its linked Contact. That changes Customer behaviour; it is skipped for users who may not modify contacts.
- **OQ-36 Reset Address Validated when a Country/Region change clears City/ZIP/State (F5), Customer included.**
  - Yes — recommended; fixes a latent 1.0.0.0 gap.
  - No.
- **OQ-37 Refuse validation when the record has Privacy Blocked = Yes** (Customer, Vendor, Contact, Employee, Resource)?
  - Yes for all, Customer included.
  - Yes for new sources only.
  - No (as today).
- **OQ-38 Sending people's home addresses** (Employee, Alternative Address, Resource, Contact persons) to Google under the one existing privacy notice: acceptable? Or a separate setup switch for the People group?
- **OQ-39 Customer No. on log entries for Ship-to Address and Customer Bank Account.**
  - Blank — recommended; the Customer Card log stays "this customer's own address".
  - The parent customer.
- **OQ-40 Company Information log action.**
  - One action for both blocks — recommended.
  - One per block.
- **OQ-41 After batch 1, a human-requested spot-check compile and a run of the 61 existing tests in a sandbox before batch 2,** to prove Customer is unchanged (Operating Rule 4 extra)?
- **OQ-42 Message wording.**
  - Customer texts kept verbatim, generic texts for other sources — recommended.
  - One neutral wording everywhere (changes the 1.0 Customer texts and the test expectations).
- **OQ-43 Validate Address on list pages** stays out of scope (G4)? Confirm.
- **OQ-44 Test app.**
  - Version 0.0.0.8 with dependency 1.1.0.0?
  - May the sync tests change Marketing Setup in the TEST company (saved and restored)?
- **OQ-45 Source Description** = table caption + key, never a name (keeps the "log stores no name" rule)? Confirm.
- **OQ-46 Enum "obcfgav Address Type" Extensible** (Step 03 rule, must be asked).
  - false — recommended; closed, code-driven.
  - true.
- Also needed for Step 03 / 05 (main role): Human Effort Estimate SC-1 addendum (reasoning role, not drafted here), AI Effort Estimate, ProjectParameters §1.2 range, `app.json` idRanges, Object Register (its status line still reads "0.0.0.7 … not yet installed").
