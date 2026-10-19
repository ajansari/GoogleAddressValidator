# Scope additions — raw input

Provided by: AJ Ansari, in chat during Step 01 (Box 4, question 13 "Assisted Setup Wizard?"), 2026-10-10.
Captured verbatim and unedited below. Original spec: `USPS Address Validation for Business Central — PTE spec.md`.

---

Yes, we need an Assisted Setup Wizard for the user to populate their USPS API key/credentials. If this is not in the spec, we need to add it. We also need to add a custom boolean field to the customer table and added to customer card page called Address Validated that shows in the fasttab where the address appears. It shold be boolean, I'd like it to not be changeable by user; it should only be updatable by code when the address validation routine is run and accepted. If it is run but ignored, then that field remains false. false is the default value when a new customer record is created in BC.
