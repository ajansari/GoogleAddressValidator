# Scope additions — raw input (master data beyond Customer)

Provided by: AJ Ansari, in chat, 2026-10-17. Captured verbatim; summary and decisions below the line.

---

> Time to extend the app. What are all the places where BC has addresses? Customer - we covered. Vendor? Location? Ship-To (customer) and whatever the equivalent is for vendor. Employee? Company Info? Where else? Give me a list of all standard places in BC where we have addresses.

> i only care about master data. Check symbols and give me a proper list.

> For each of these: Sales and customer side, Purchasing and vendor side, company and org, and people - we should add Address validation capability and a field that shows if address has been validated. I don't want it on any transactions, documents, etc. - so no sales transactions, no job, no work center, etc. Tell me, how will you do it

> go

---

## Decisions (AJ Ansari, 2026-10-17, options box)

- Union (5209): **out of scope**.
- Object ID range: **extend by 50** after the current block (60143–60192).
- Version: **minor bump to 1.1.0.0** (builds continue 1.1.0.1, 1.1.0.2 …).
- Batch mode: **one at a time** (batch 1, the engine rewire, must land first and leave Customer behavior unchanged).

## In scope (Base Application 28.5 symbols, checked 2026-10-17)

| ID | Table | Group |
|---|---|---|
| 18 | Customer (done) | Sales and customer |
| 222 | Ship-to Address | Sales and customer |
| 287 | Customer Bank Account | Sales and customer |
| 23 | Vendor | Purchasing and vendor |
| 224 | Order Address | Purchasing and vendor |
| 2224 | Remit Address | Purchasing and vendor |
| 288 | Vendor Bank Account | Purchasing and vendor |
| 79 | Company Information (two blocks: company, Ship-to) | Company and org |
| 14 | Location | Company and org |
| 5714 | Responsibility Center | Company and org |
| 270 | Bank Account | Company and org |
| 5200 | Employee | People |
| 5201 | Alternative Address | People |
| 5050 | Contact | People |
| 5051 | Contact Alt. Address | People |
| 156 | Resource | People |

## Out of scope

Every transaction and document table (sales, purchase, transfer, service, reminder, finance charge, archive and posted versions), Job, Job Task, Service Item, Work Center, Machine Center, Union, templates, Standard Address.

## Required per in-scope table

Address validation capability (a Validate Address action) and a non-editable **Address Validated** boolean on the page, set only by code when validation is run and accepted or confirmed, cleared when the address is edited; same behavior as Customer.
