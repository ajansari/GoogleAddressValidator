# Deployment — USPS Address Validator

**Version:** 0.0.0.4 · **Package:** `outputAppPackage/USPS_Address_Validator_0.0.0.4.app` · **Date:** 2026-10-16
**Rule:** the agent never publishes to production, and never publishes anywhere unprompted. The production deploy is the human's, from this document, after the Step 12 release test passes — the same procedure rehearsed in every sandbox install from `docs/4-prove/SandboxInstall.md`.

> **Status you should know before reading on:** no package of this extension has yet been installed or tested in any Business Central tenant (Step 07 and Step 09 closed under waivers 07-WAIVER and 09-WAIVER, AJ Ansari, 2026-10-16). The live USPS service has not been called either, because USPS onboarding is blocked. The package named here is the current development build; the package that passes Step 12 is the one that ships, and this document is updated to name it. A provider change (Change Request CR-1) is under discussion but not decided; if it is approved, this document changes.

## 1. What ships
| Item | Value |
|---|---|
| Package (exact file, the one that passed Step 12) | Not yet determined. Current build: `outputAppPackage/USPS_Address_Validator_0.0.0.4.app`. Update this row with the Step 12 package (a `1.0.0.x` build if a release candidate is built). |
| Extension | USPS Address Validator, publisher OnlyBCFans, app id `2d1d2fd8-0208-4096-a868-8489784df05a` |
| Requirements | Business Central **SaaS, version 28.0 or later** (built and symbol-checked against 28.5); per-tenant extension (PTE), not AppSource; single language, English (United States) |
| Dependencies | None beyond the Base Application. The separate test app (`USPS_Address_Validator_Tests_<version>.app`) is for sandboxes only and is **never** installed in production. |
| Outside access | **"Allow HttpClient Requests" must be on for this extension** in every environment that uses it (section 2). The extension calls `https://apis.usps.com` (Production) and `https://apis-tem.usps.com` (Test). |
| Schema Sync Mode | **Add** against a new install or against 0.0.0.1–0.0.0.3. No schema change in 0.0.0.4 against 0.0.0.2 (`docs/4-prove/SandboxInstall.md` §1). The agent restates this in the "Package built:" block for the exact package, judged against the last version installed in production. |
| Target environments | sandbox (type Sandbox, TEST company) → production. Environment names are the administrator's to fill in at go-live: sandbox ______ → production ______ |

## 2. Before deploying
- [ ] Release test passed (`docs/4-prove/ReleaseTestResults.md`). **Not yet run** — nothing has been installed in a tenant.
- [ ] Every required translation `signed-off` or `final`. N/A: single language, en-US, no translation files.
- [ ] Version bump approved and recorded (release candidate question at the end of Step 11).
- [ ] Backup / restore point per the customer's policy.
- [ ] **Open question OQ-20 — "Allow HttpClient Requests" is still unchecked.** Microsoft says outbound calls are blocked unless allowed per extension; the production default is not stated. Before the first production install, in a sandbox and then in production: **Extension Management** → select **USPS Address Validator** → **Configure** → switch **Allow HttpClient Requests** on. If it is off, checks fail with "USPS is not responding. Try again later." (a platform error may be raised instead; this too is unverified, gap G5).
- [ ] **Production quota check (OQ-9).** Read the real hourly address quota in the USPS developer portal and compare it with the expected checks per hour across all users. The figure of about 60 per hour is a third-party number; USPS does not publish it. If more than about 40 checks per hour are expected, request a quota increase **before** go-live. All users share the one set of credentials.
- [ ] **USPS access.** The credentials (Consumer Key and Consumer Secret) come from the customer's own USPS developer account. USPS now asks for a license or paid usage and onboarding may be blocked; do not schedule a go-live until credentials exist and the Test (TEM) checks (FRD acceptance tests 1–3) have passed. The USPS terms (OQ-1 resolved: the company ships or mails to these customers through USPS; OQ-18, the "operational test" clause, is still to be put to USPS).
- [ ] **Privacy notice link (OQ-23).** The extension creates a Business Central privacy notice "USPS Address Validation" (id `OBCFUSPS-ADDRESS`) that points at `https://about.usps.com/who/legal/privacy-policy/`. That link was written from memory and is **unconfirmed**. Confirm it opens the right USPS page, and have whoever owns data protection review the notice, before the first production install. If the link is wrong, a new build is needed.

## 3. Deploy — per-tenant (Admin Center → Manage Apps → Install Extension, or Extension Management → Upload Extension)
The upload mechanics are identical to the sandbox procedure. Follow `docs/4-prove/SandboxInstall.md`: **§2** (before you start), **§3** (Route A, the Admin Center, which Microsoft recommends) or **§4** (Route B, Extension Management, deprecated), staying on one route per environment. Only these items differ for production:

1. Name the **production** environment instead of the sandbox in SandboxInstall §3 step 2 (or sign in to production for §4). Upload the exact package from section 1, the one that passed Step 12 — no rename, copy, rebuild or version change.
2. **Deployment schedule:** a first install can be immediately or at the next update window. Choose per the customer's change policy; production rollouts usually use the update window.
3. **Sync Mode:** the value stated in the "Package built:" block for this package (Add unless that block says otherwise). Never choose Force without reading the data-loss warning in that block.
4. Do the post-install work in section 4. The agent does not do the upload, and does not offer to.

## 3a. Deploy — AppSource
N/A — Deployment Target is SaaS PTE, not AppSource.

## 4. After deploying
- [ ] **Permission sets assigned** on the **Users** page, under **User Permission Sets**:

  | Permission set | Caption | Give to | What it allows |
  |---|---|---|---|
  | `OBCFUSPS USPS, USE` | USPS Address Validator - Use | Customer service and sales administration staff who validate addresses | Run **Validate Address (USPS)**, see the comparison window, read the setup (not the secrets), insert into and read the **USPS Validation Log**. To accept a suggestion the user **also** needs permission to modify customers, from another permission set. |
  | `OBCFUSPS USPS, ADMIN` | USPS Address Validator - Admin | The administrator who sets up USPS | Everything in USE (it includes USE), plus the setup page and wizard, change the setup and the credentials, and **delete** log entries. |

  No permission set was renamed in this release, so no user needs reassigning.
- [ ] **Setup completed:** search **Assisted Setup** → **Set up USPS address validation**, enter the Consumer Key and Consumer Secret and **Finish**; then open **USPS Address Validation Setup**, choose the **Environment** (starts as Test (TEM); the Test environment still uses the real production credentials), switch **Enabled** on, and choose **Test Connection**. Agreeing to the privacy notice is required for Test Connection and for the first address check; an administrator's agreement applies to all users. Setup is per company, so repeat it in every company that will use USPS.
- [ ] **Smoke test** (from `docs/4-prove/HumanUnitTestScript.md`): (1) **Test Connection** reports *The connection to USPS works. A token was received.* (2) On a test customer with a known US address, **Validate Address (USPS)** shows the **USPS Address Suggestion** window or the *address is confirmed* message and sets **Address Validated** correctly. (3) The **USPS Validation Log** shows exactly one entry for that check with the correct Environment.
- [ ] **Retention policy enabled (section 4a).**
- [ ] Quota (OQ-9) and "Allow HttpClient Requests" (OQ-20) confirmed as in section 2.
- [ ] Incident reporting checklist (section 4b) filed with the customer's security process.

### 4a. Retention of the validation log
- The extension registers the **USPS Validation Log** with Business Central's Retention Policy at install, with a custom **2-year** retention period (`OBCFUSPS-2Y`), applying to all records, measured on **Checked At**.
- The policy is **created disabled**. Nothing is deleted until an administrator enables it: search **Retention Policies**, open the policy for table **USPS Validation Log**, review the period (it can be changed there), and switch **Enabled** on. This is a deliberate decision (OQ-8): the log is an audit trail.
- The retention job runs from the **Job Queue** as a user. That user needs **direct delete permission on the log** (included in `OBCFUSPS USPS, ADMIN`) and Microsoft's retention policy permissions for the job. If the job's user lacks them, old entries are not deleted and the job fails. Confirm after enabling that the job queue entry exists, runs, and reaches status Ready (TDD F23).
- Deleting a customer does not delete its log entries; only the retention policy does.

### 4b. USPS incident-reporting checklist (72 hours)
USPS requires that **security incidents involving USPS data or credentials be reported to USPS within 72 hours** (FRD section 7). Keep this checklist with the customer's incident response plan:
- [ ] Name the person who owns the USPS developer account and the person who reports to USPS, with their contact details, before go-live.
- [ ] Treat as an incident: suspected exposure of the Consumer Key or Consumer Secret, a user who left with access to the credentials, unauthorized access to the **USPS Validation Log** (it holds customer addresses and user ids), or a tenant compromise affecting this extension.
- [ ] Record the time the incident was **discovered**; the 72 hours run from then.
- [ ] Contain it: revoke or rotate the credentials in the USPS developer portal; set **Enabled** off on the setup page; enter the new credentials there; remove the `OBCFUSPS USPS, ADMIN` permission set from anyone who no longer needs it.
- [ ] Report to USPS within 72 hours through the contact named in the USPS developer terms (confirm the contact beforehand).
- [ ] Record what was affected, the report reference and the follow-up in the customer's incident log.

## 5. Rollback
- **Updating to a fixed build** is the normal remedy: install the next higher version on top (SandboxInstall §6). A version, once installed, cannot be uploaded again.
- **Uninstall:** Admin Center → **Manage Apps** → the extension → **Uninstall** (or Extension Management → **Uninstall**). Details in `docs/4-prove/SandboxInstall.md` §7.
  - By default uninstalling **keeps the extension's data** — the setup record, the **USPS Validation Log**, and the **Address Validated** value on customers — so a later reinstall finds it again.
  - With **Delete Extension Data** switched on, the extension's tables and the Address Validated field are removed. This cannot be undone. Export or keep what you need from the log first.
  - Customers' addresses are never changed by uninstalling. The stored USPS credentials are held in isolated storage by the extension; whether they remain after uninstall has not been verified. If the extension will not come back, rotate the credentials in the USPS developer portal.
  - The privacy notice, the retention policy entry, and the Assisted Setup entry are Business Central records; check Retention Policies, Privacy Notices and Assisted Setup after uninstalling and remove what remains if unwanted.
- **Who decides:** the administrator who owns the production environment, together with the business owner of the extension (AJ Ansari for this project).

## 6. Upgrade notes
- **No upgrade codeunit exists** and none is needed so far: no earlier version has held data that must change shape (TDD §8, PostDevTDD). The only new field on an existing table is **Address Validated** on Customer; every existing customer starts at **No**.
- **Upgrading from 0.0.0.1–0.0.0.3** to 0.0.0.4 is an in-place update (higher version, Add). The **privacy notice** is created lazily: install code does not run on an upgrade, so the extension creates the notice "USPS Address Validation" the first time a user validates an address or chooses **Test Connection**. An upgraded environment therefore needs no extra step; the first user to validate sees the prompt (an administrator's Agree applies to all users). The retention policy and the Assisted Setup entry, which are registered at install, exist only if the environment was installed (not merely upgraded) on a build that included them; if **Retention Policies** or **Assisted Setup** lacks them after an upgrade, report this — an upgrade routine will be added in the next version.
- **Install behaviour** (per company, safe to repeat): registers the retention policy (disabled), the Assisted Setup entry (marked completed when credentials already exist) and the privacy notice; also runs when a new company is created.
- **Resource exposure (CR9-21).** `app.json` allows debugging, downloading source, and including source in the symbol file. This is acceptable for a per-tenant extension: every secret (Consumer Key, Consumer Secret, access token) is held as a secret value, marked `[NonDebuggable]`, and never written to the log, a message or telemetry. It does mean another developer with the right tenant access can read this extension's source. The test-app identity used by the extension's caller check is also visible this way; it only matters in sandboxes.
- **Permission sets.** No permission set was renamed in this release. `OBCFUSPS USPS, USE` and `OBCFUSPS USPS, ADMIN` keep their ids and names.
- **Known limitations carried into this release** (from `docs/4-prove/GapAnalysis.md`; none changes how an administrator deploys): a USPS answer with an empty address field is not rejected (G3); some of the extension's internal codeunits are callable by other extensions in the same tenant (G2, G4); these are scheduled with the provider decision. Customers' Tax Area Code is not re-evaluated after an accepted address. Contact address sync, the US captions of State and ZIP Code on a US tenant, and the "Allow HttpClient Requests" default are platform checks still to be made in a sandbox (G17, OQ-19, OQ-20).

## Before calling this done
- [ ] The package named in §1 is the one that passed Step 12. **Not yet — the row in §1 names the current build; update it after Step 12.**
- [x] Every step is runnable by an administrator who is not a developer (upload mechanics in `docs/4-prove/SandboxInstall.md`).
