# Installing Google Address Validator in a Business Central sandbox

**The agent does not upload packages — you do.** It builds the package; a person installs it. (A developer can explicitly ask the agent to publish a build as a DEV extension to a sandbox; that is never offered, and testers and administrators still install this way.)
This document is that person's procedure, from the file on disk to a working extension in a sandbox.
It takes about five minutes the first time and two minutes after that.

## 1. This build

| | |
|---|---|
| Package to install | `outputAppPackage/Google_Address_Validator_1.3.0.3.app` — 1.3.0.1 to 1.3.0.3 add, to the 1.3.0.0 renumbering, a country step in the Assisted Setup wizard (the Default Country/Region Code is no longer preset to US), a kept API key on a repeat run, and the brief, description and website URL in `app.json`; otherwise the same functionality as 1.2.0.4 (which passed the manual release test on 2026-10-19), with every object and field renumbered per object type into 92800–92829 and the online help link in `app.json` |
| Version | `1.3.0.3` (previous builds `1.3.0.2`, `1.3.0.1` and `1.3.0.0`; the last version installed and tested: `1.2.0.4`, manual release test passed 2026-10-19, in a sandbox) |
| Schema Sync Mode to choose | **Force Sync, or uninstall the old version with its data first.** Every table ID and every field ID on the 16 standard tables changed (the Setup, Validation Log, Address Buffer and Supported Country tables and the Address Validated / Ship-to Validated fields), so Business Central treats the old ones as removed and the new ones as new. **Add** refuses the upload as destructive. A forced sync drops the old tables and fields **and their data**: the Validation Log, the Address Validated flags, the Setup values and the Supported Countries rows. The API key is kept (isolated storage), and permission set assignments are kept (matched by name). Test it in a sandbox first. Production has never had the extension, so a first production install is a plain install and needs neither. |
| Object ID range | The extension uses **92800–92829** (every object ID is allocated per object type from 1.3.0.0). Before uploading, open **Extension Management** and check that no other installed per-tenant extension uses an ID in **92800–92829**, and that no other extension has added a field **92800** to any of the 15 standard tables the app extends (Ship-to Address, Customer Bank Account, Vendor, Order Address, Remit Address, Vendor Bank Account, Company Information, Location, Responsibility Center, Bank Account, Employee, Alternative Address, Contact, Contact Alt. Address, Resource) or **92801** to Company Information. If one does, stop and tell the agent |
| Sandbox environment | `sandbox` (type **Sandbox** — never a production environment) |
| Depends on | nothing beyond the Base Application. Optional test app: `Google_Address_Validator_Tests_0.0.0.24.app` (previous 0.0.0.23; sibling folder `USPSAddressValidator.Tests/outputAppPackage/`), built against main **1.3.0.0**, to run the 155 automated tests in a TEST company (`docs/4-prove/AutomatedTestGuide.md`). |
| Run order for the automated tests | (1) Install the main app 1.3.0.0 as above. (2) Install the Microsoft Test Runner app and the test app 0.0.0.24 (`docs/4-prove/AutomatedTestGuide.md` §3 and §4). (3) Open a company whose name contains **TEST**, and write down the values in the guide's §2 first. (4) Run the tests one row at a time, in the order of that guide's §6: rows 1 to 61 (the 1.0.0.0 tests; they must still pass, with row 16 now using Russia and the new message texts), then rows 62 to 115 (`codeunit 92836 Source Tests`), then rows 116 to 134 (`codeunit 92837 Sync Tests`), then rows 135 to 155 (`codeunit 92838 Country Tests`). Do the manual cases of `docs/4-prove/HumanUnitTestScript.md` sections 3a and 3b separately, in a company with real-looking test records, not in the TEST company the automated tests clean up |

The agent rewrites this table after every build. Everything below it does not change, except §9 below, which is specific to versions 1.1 and 1.2.

## 2. Before you start

- **A sandbox, not production.** Development builds go to a sandbox only. If you are not sure which
  environment is which, open the Business Central Admin Center
  (<https://businesscentral.dynamics.com/admin>): the **Environments** list shows each one's **Type**.
- **Permission to install.** You need one of:
  - access to the **Admin Center** as an internal, delegated, or application administrator (route A), or
  - in the environment itself, membership of the **D365 Extension MGT** user group, or the
    **EXTEND. MGT. - ADMIN** permission set (route B).
  If you have neither, ask your Business Central administrator to grant one before continuing.
- **The file.** Copy the package named in §1 somewhere you can browse to from the machine you will use.
  Business Central refuses a version it has already seen: every package the agent builds has its own
  version number, so always take the exact file §1 names, never an older one.
- **Pick one route and stay with it.** Microsoft's note: an installation scheduled from the Admin Center
  does not show on the environment's Extension Management page until it completes, and the other way
  round. Use the same route for this environment every time.

## 3. Route A — Business Central Admin Center (recommended by Microsoft)

Microsoft's current guidance is to upload per-tenant extensions through the Admin Center. The in-product
upload on the Extension Management page (route B) still works but is deprecated and is removed in
2027 release wave 1.

1. Open <https://businesscentral.dynamics.com/admin> and sign in with your work account.
2. In the left pane choose **Environments**, then select the sandbox named in §1.
3. On the environment's page choose the **Manage Apps** icon.
4. In the app-type dropdown choose **Per-tenant Extension**.
5. Choose **Install Extension**.
6. **Browse** to the `.app` file from §1 and select it. Business Central works out by itself whether this
   is a new extension or an update to one already installed; you do not have to say.
7. **Deployment schedule:** choose **Install immediately**. (The other choices — the next update window,
   the next minor or major update — are for production rollouts, and a brand-new extension can only be
   installed immediately or at the next update window.)
8. **Sync Mode:** choose what §1 says — **Add** or **Force**. Add is the safe default and is refused if the
   build changed the database schema in a breaking way; Force overwrites the schema and can delete data,
   which is why §1 says in advance which one this build needs.
9. Read and accept the terms, then confirm.
10. Business Central validates the file and schedules the install. Watch progress on the Admin Center's
    **Operations** page (left pane). The row for this install shows its status; a failed one shows the
    reason when you open it.
11. When the operation shows as completed, go back to **Manage Apps** and confirm the extension is listed
    at the version from §1.

To see or cancel a scheduled installation, open the extension's **App Details** page from Manage Apps.

## 4. Route B — Extension Management page inside Business Central (deprecated, still available)

1. Open the sandbox in your browser and sign in.
2. Choose the **Search for Page or Report** icon (the magnifying glass, top right), type
   **Extension Management**, and open the page.
3. Choose **Manage**, then **Upload Extension**. The **Upload and Deploy Extension** page opens.
4. Choose the browse button next to the file field and select the `.app` from §1.
5. **Deploy to:** leave **Current version** selected. (Next minor / next major are for an extension built
   specifically for a future Business Central release.)
6. **Language:** leave the default unless your administrator says otherwise.
7. **Schema Sync Mode:** choose what §1 says — **Add** or **Force**. If you choose Force, Business Central
   asks you to confirm that you understand data can be lost.
8. Turn on the **Accept** switch to accept the disclaimer.
9. Choose **Deploy**. The upload runs in the background and the page closes.
10. Back on Extension Management, choose **Manage**, then **Deployment Status**. Select the row for this
    upload and choose **Refresh** in its actions until the status is **Completed** (or **Failed** — then
    open the row's details for the reason, and see §8).
11. On Extension Management choose **Refresh** (or reopen the page) and confirm the extension is listed as
    **Installed** at the version from §1.

## 5. After it is installed

1. **Assign the permission sets.** Open **Users**, select each tester, and under **User Permission Sets**
   add `OBCFGAV GAV, USE` (validate addresses) or `OBCFGAV GAV, ADMIN` (also setup, credentials and the log). Without one of
   these a user sees nothing of the extension.
2. **Sign out and back in**, or press **Ctrl+F5** in the browser, so the client picks up the new objects.
3. **Confirm it is there:** search for **Google** (or **Google Address Validation Setup**) and open it.
   The first time anyone validates an address or chooses Test Connection, Business Central shows a privacy notice for sending addresses to Google (an administrator's Agree applies to everyone). The setup card shows the Provider (Google Maps, read-only), Enabled, the API key, Default Country/Region Code and Timeout (Seconds), and a **Supported Countries** action.
4. **Run any setup the extension needs:** the setup wizard (assisted setup) or the Google Address Validation Setup card — enter the Google Maps API key there; the extension is Enabled only after that..
5. **Tell the agent** the version you installed and the environment name. It records "last installed
   version" and judges the next build's Schema Sync Mode against it.

## 6. Installing a newer build (updating)

Repeat §3 or §4 with the new file. Business Central recognises the same extension at a higher version
and upgrades it in place; your data stays. Three things to know:

- The new version must be **higher** than the installed one. The agent increments the version on every
  build, so this is only a problem if you pick an old file by mistake.
- A build the agent marked **Force** in §1 stays Force until it has actually been installed, even if later
  builds only add things.
- If the environment ever refuses with *"An extension with same App ID and version has already been
  uploaded. Resolve and deploy again."*, the file was uploaded before (possibly a failed attempt). Ask the
  agent for a new build; it will carry the next version number.

## 7. Removing it

- **Route A:** Admin Center → **Manage Apps** → the extension's row → **Uninstall** (or **Uninstall** on its
  App Details page).
- **Route B:** Extension Management → select the extension → **Uninstall**.

Uninstalling keeps the extension's data by default, so you can install it again later. To delete the data
as well, turn on **Delete Extension Data** before confirming — that cannot be undone, and it also deletes
the data of every extension that depends on this one. If other extensions depend on this one, Business
Central lists them and uninstalls them with it.

## 8. When something goes wrong

| What you see | What it means | What to do |
|---|---|---|
| The install fails and the details mention a schema change, a field that cannot be removed, or data that would be lost | The build needs **Force** and you chose **Add** | Check §1. If it says Force, repeat with Force. If it says Add, tell the agent — its schema line was wrong. |
| *"An extension with same App ID and version has already been uploaded"* | This exact version was uploaded before | Ask the agent for a new build (next version). Never rename or re-save the file. |
| A dependency is missing or at the wrong version | Something in §1's *Depends on* row is not installed | Install that extension first, at the named version, then retry. |
| The extension installs but you cannot see any of its pages | No permission set assigned, or the client has not refreshed | §5 steps 1 and 2. |
| *"The view is filtered, and the entry is outside the filter"*, or a number-series field with no dropdown | A defect to report, not a setting to change | Report it to the agent exactly as shown; the framework treats both as bugs (Standards §11). |
| The upload is accepted but Deployment Status / Operations never completes | It can take a few minutes; the status is not live | Choose **Refresh** on the status row. After fifteen minutes, open the row's details and report the text to the agent. |

Anything else: copy the full message, note which route and which step you were on, and give both to the
agent. It will diagnose; it will not retry the upload for you.

## 9. Upgrading from 1.0.0.0 to 1.1.x and 1.2.x (versions 1.1 and 1.2 only)

1. **Before.** In the sandbox, write down for each company: the number of entries in **Google Address Validation Log**, and which customers have **Address Validated = Yes**. Check the ID range as §1 says.
2. **Install** the package named in §1 by §3 or §4 (**Add**). It is an in-place update: do not uninstall 1.0.0.0 first, because uninstalling can lose data.
3. **After.** Open **Google Address Validation Log**: the old entries are all there and each shows **Source Table** Customer. Customers keep their **Address Validated** values. Details and the full pass are in `docs/4-prove/HumanUnitTestScript.md` TC-36.
4. **Permission sets.** `OBCFGAV GAV, USE` was extended (new internal codeunits) and, from 1.1.0.4, its access to the log changed from direct read to **indirect** read: users no longer open the log table directly, and the **Google Address Validation Log** page shows each user only the entries of the kinds of record the user may read. `OBCFGAV GAV, ADMIN` keeps direct read and delete. Nobody needs reassigning. Users need their normal permissions on each new card's table (`docs/4-prove/Deployment.md` §4).
5. **Then the tests.** Install the test app 0.0.0.23 and run the automated tests as §1's last row says, in a company named with TEST. They overwrite the address validation setup and the stored key of that company and delete records whose keys start with `GAVUT`; they also create Business Relation codes `GAVUTC`, `GAVUTV`, `GAVUTB` and `GAVUTE`, insert the countries US and CA when they are missing (and, for the 1.2 tests, DE, SG, BR and two codes of their own), switch every country that is off back on at clean-up on the Supported Countries page, and change then restore Marketing Setup, Company Information and the General Ledger Setup field **Req.Country/Reg. Code in Addr.** The restore values are held in memory only: **a crashed run can leave those three altered in the TEST company**, and `docs/4-prove/AutomatedTestGuide.md` §2 says how to check and put them back by hand.
6. **Countries (new in 1.2; privacy).** Open **Google Address Validation Supported Countries** (Tell Me). The 40 countries are all **Enabled** after the install or upgrade, which means addresses outside the United States, including employee and contact addresses, can be sent to Google when a user validates. **Turn off the countries you do not want** before testers start. The price is one price for every country (5,000 free requests a month in total, then about $17 per 1,000; a billing account on India pricing gets 35,000 free). Google's real answers outside the US have not been seen: do a live probe per country you will use, with real addresses only, Brazil, Mexico, India and Japan especially (India and Japan are preview). The manual cases are `docs/4-prove/HumanUnitTestScript.md` section 3b, TC-45 to TC-52.
7. **Permissions to check afterwards.** Open **Google Address Validation Log** as a user with only `OBCFGAV GAV, USE` and no Employee read permission: no Employee, Alternative Address or Resource rows may appear (`docs/4-prove/HumanUnitTestScript.md` TC-39). Nothing of this has been run.

## Sources (Microsoft Learn, read October 15, 2026)

- *Install and uninstall apps* — <https://learn.microsoft.com/en-us/dynamics365/business-central/ui-extensions-install-uninstall>
- *Deploying a tenant customization* — <https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-deploy-tenant-customization>
- *Managing apps* (Admin Center) — <https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/administration/tenant-admin-center-manage-apps>
