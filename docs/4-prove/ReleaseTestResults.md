# Release Test Results — Google Address Validator

> **Scope of this record.** Everything below is the release test of **1.0.0.0** (tested as 0.0.0.7, Customer only). **The 1.1 release test has not been run.** The 1.1 release candidate is `outputAppPackage/Google_Address_Validator_1.1.0.5.app` (previous build 1.1.0.4), to be tested with `docs/4-prove/HumanUnitTestScript.md` section 3a (TC-30 to TC-42) and the automated tests (test app 0.0.0.15, 131 tests, `docs/4-prove/AutomatedTestGuide.md`) on a sandbox. The package that passes is the one that ships, as it is: no rename, no new version number; a fix found in the test continues as 1.1.0.6, 1.1.0.7 and so on. This was decided by the main role under AJ Ansari's instruction to continue without questions, and AJ Ansari has not been asked. When the 1.1 round is run, record it in new sections of this file (review, results by case, upgrade from 1.0.0.0, release decision) and name the package that passed.

**Version tested:** 0.0.0.7 · **Package:** `outputAppPackage/Google_Address_Validator_0.0.0.7.app` · **Environment:** `sandbox` (type Sandbox) · **Script:** `docs/4-prove/HumanUnitTestScript.md` (29 cases, Step 11 Google build, 2026-10-17)

**How this record was made.** AJ Ansari reported the round in aggregate on 2026-10-17 ("Users tested, and are happy", `docs/0-project/TestingFeedback.md` TF-01) and, asked explicitly, confirmed that no findings were raised and every case passed. The per-case rows below carry that aggregate result; no per-case evidence (the script's "Actual" and "Pass/Fail" columns, the values the script asks testers to write down) was handed to the agent. If any case was skipped or marked Blocked in the testers' copy, correct the row here before the production deploy.

## 1. Review
| Reviewer (Dev Manager) | Date | Overall result | Notes |
|---|---|---|---|
| AJ Ansari | 2026-10-17 | Approved | Reviewed `docs/4-prove/PostDevTDD.md`, `docs/2-design/FRD.md` 2.0 (as-built baseline) and the Step 11 documents (Documentation, UserGuide, HumanUnitTestScript, Deployment, Acknowledgements, AutomatedTestScripts, AutomatedTestGuide). No findings. One PROVE review, covering Steps 10 and 11, as the step file prescribes. |

## 2. Results by test case
All cases: language en-US, tester AJ Ansari and the users, date 2026-10-17, result Pass, no ChangeLog issue.

| TC | Title | Language | Tester | Date | Result | ChangeLog issue (if failed) |
|---|---|---|---|---|---|---|
| TC-01 | Privacy notice — agree | en-US | AJ Ansari / users | 2026-10-17 | Pass | — |
| TC-02 | Assisted Setup wizard | en-US | AJ Ansari / users | 2026-10-17 | Pass | — |
| TC-03 | Setup card and Test Connection | en-US | AJ Ansari / users | 2026-10-17 | Pass | — |
| TC-04 | Suggestion accepted (bold changed values, attribution) | en-US | AJ Ansari / users | 2026-10-17 | Pass | — |
| TC-05 | Confirmed | en-US | AJ Ansari / users | 2026-10-17 | Pass | — |
| TC-06 | Suggestion ignored, then Esc | en-US | AJ Ansari / users | 2026-10-17 | Pass | — |
| TC-07 | Not Found | en-US | AJ Ansari / users | 2026-10-17 | Pass | — |
| TC-08 | Missing suite warning (optional) | en-US | AJ Ansari / users | 2026-10-17 | Pass | — |
| TC-09 | Address Validated indicator | en-US | AJ Ansari / users | 2026-10-17 | Pass | — |
| TC-10 | Log page | en-US | AJ Ansari / users | 2026-10-17 | Pass | — |
| TC-11 | Unsaved edit is the one sent | en-US | AJ Ansari / users | 2026-10-17 | Pass | — |
| TC-12 | Contact sync after Accept | en-US | AJ Ansari / users | 2026-10-17 | Pass | — |
| TC-13 | Time zones | en-US | AJ Ansari / users | 2026-10-17 | Pass | — |
| TC-14 | Rename of a customer keeps its log rows | en-US | AJ Ansari / users | 2026-10-17 | Pass | — |
| TC-15 | Platform checks only a sandbox can answer | en-US | AJ Ansari / users | 2026-10-17 | Pass | — |
| TC-16 | Standards §11.3 client checks | en-US | AJ Ansari / users | 2026-10-17 | Pass | — |
| TC-17 | No API key | en-US | AJ Ansari / users | 2026-10-17 | Pass | — |
| TC-18 | Incomplete address | en-US | AJ Ansari / users | 2026-10-17 | Pass | — |
| TC-19 | Bad state code | en-US | AJ Ansari / users | 2026-10-17 | Pass | — |
| TC-20 | Non-US customer | en-US | AJ Ansari / users | 2026-10-17 | Pass | — |
| TC-21 | Disabled setup | en-US | AJ Ansari / users | 2026-10-17 | Pass | — |
| TC-22 | Wrong API key | en-US | AJ Ansari / users | 2026-10-17 | Pass | — |
| TC-23 | User without permission to modify customers | en-US | AJ Ansari / users | 2026-10-17 | Pass | — |
| TC-24 | Address changed while the dialog is open | en-US | AJ Ansari / users | 2026-10-17 | Pass | — |
| TC-25 | Privacy notice refused | en-US | AJ Ansari / users | 2026-10-17 | Pass | — |
| TC-26 | Google value too long | en-US | AJ Ansari / users | 2026-10-17 | Pass | — |
| TC-27 | "Allow HttpClient Requests" switched off | en-US | AJ Ansari / users | 2026-10-17 | Pass | — |
| TC-28 | Google API disabled, and billing disabled | en-US | AJ Ansari / users | 2026-10-17 | Pass | — |
| TC-29 | Request limit and timeout | en-US | AJ Ansari / users | 2026-10-17 | Pass | — |

**Permission sets.** Verified as part of the same pass (TC-23 and the setup cases): `OBCFGAV GAV, USE` runs checks and reads the log; `OBCFGAV GAV, ADMIN` adds setup and log management; Customer and Contact modify come from the standard sets (Documentation §5).

**Automated tests.** The 61 tests in the test app (`docs/4-prove/AutomatedTestGuide.md`) were not separately reported for this round. AJ Ansari's aggregate answer covered the human script; whether the test app was installed and run in the sandbox is not recorded here. Roadmap R-09-1 and R-11-1 stay open on that point unless AJ confirms.

## 3. Upgrade path
*N/A — this is the extension's first release (Standards §9.6).* No version of Google Address Validator (or its USPS predecessor) was ever installed in any production environment; the sandbox received 0.0.0.7 as a fresh install. There is no upgrade codeunit (Documentation §7). The 1.0.0.0 package below installs over 0.0.0.7 in the sandbox as an ordinary newer build (Schema Sync Mode Add, no schema change).

## 4. Language passes and translation state scan
*N/A — Parameter §1.9: US wording, English (United States) only, no translation files.* The functional pass above is the language pass.

## 5. Feedback received
| Feedback entry | Triage (implement / roadmap / reject) | ChangeLog / Roadmap ref |
|---|---|---|
| `docs/0-project/TestingFeedback.md` TF-01 (2026-10-17, no findings) | Nothing to triage | ChangeLog 12-1 (release candidate built) |

## 6. Release decision
| Decision | By | Date | Package that ships |
|---|---|---|---|
| Round on 0.0.0.7 passed clean; build the release candidate 1.0.0.0 (Major bump, same code as 0.0.0.7, Rule 6a) | AJ Ansari | 2026-10-17 | `outputAppPackage/Google_Address_Validator_1.0.0.0.app` |
| 1.0.0.0 installed in `sandbox` over 0.0.0.7 and smoke-tested, passed; **this is the package that ships, as it is**. Production deploy is AJ Ansari's, through the Admin Center (`docs/4-prove/Deployment.md` §3). Project closed. | AJ Ansari | 2026-10-17 | `outputAppPackage/Google_Address_Validator_1.0.0.0.app` |

## Before calling this done
- [x] Every TC has a result; every failure has an issue. (All Pass per AJ Ansari's aggregate report; no per-case evidence held.)
- [x] The package that passed is named exactly and is the one Step 12 releases: `Google_Address_Validator_1.0.0.0.app`, smoke-tested in the sandbox by AJ Ansari, 2026-10-17.
- [x] The upgrade path passed, or the document states this is the first release.
- [x] Every language required at first release shows all units approved, with the reviewer named. (N/A, single language, no translation files.)

## 7. Release round for 1.1.0.0 – 1.2.0.4 (SC-1, SC-2, SC-4, SC-5; 2026-10-19)
| Item | Result |
|---|---|
| Manual tests (`HumanUnitTestScript.md` TC-01..TC-56, incl. master-data tables, Google names and Record No., 40 countries, country fill-in, blank-country handling) | **All passed** per AJ Ansari's report of 2026-10-19: "All manual tests succeed in flying colors". No per-case evidence held. |
| Package that passed | `outputAppPackage/Google_Address_Validator_1.2.0.4.app` (test app 0.0.0.23 is not shipped). AJ's report did not name the version; 1.2.0.4 is the latest build and the one under test. Confirm if different. |
| Automated tests (155 procedures, `AutomatedTestGuide.md`) | **Not run.** AJ Ansari chose to skip them. The AL MCP could not sign in (`al_auth_login` fails with a null reference: ASP.NET data-protection key `a44b976c-…` missing from the key ring), `al_run_tests` was denied by the permission classifier, and pocSandbox has no company with TEST in its name. Roadmap R-09-1 and R-11-1 stay open. |
| Upgrade path | 1.0.0.0 was never installed in production, so this is still the first production release (Standards §9.6). Sandbox upgrade 1.0.0.0 → 1.2.0.x passed as part of the manual round. Unconfirmed upgrade decisions (SC-4/SC-5a) are carried in `docs/0-project/ChangeLog.md`. |
| Languages | N/A: English (United States) only, no translation files. |
| Release decision | AJ Ansari, 2026-10-19: proceed to close. Production deploy is AJ's, through the Admin Center (`Deployment.md` §3). Schema: additive only versus 1.0.0.0 (new tables/fields, no removal) → Schema Sync Mode Add. |

**Addendum, 2026-10-19.** Build `Google_Address_Validator_1.2.0.5.app` has the code of 1.2.0.4 and adds only the `help` URL in `app.json` (online help, `help/index.html`); it compiled with 0 errors and 0 warnings under the PTE analyzers. Because the tested file was 1.2.0.4, the file that ships is 1.2.0.5 only if AJ Ansari accepts it as the same release (recorded in ChangeLog 12-4); otherwise 1.2.0.4 ships as tested and `help` is left blank.

## 8. Release candidate 1.3.0.0 (2026-10-19)
AJ Ansari chose to ship **1.3.0.0** (object and field IDs renumbered per object type into 92800–92829; help link in `app.json`; behaviour as 1.2.0.4). It compiled with 0 errors and 0 warnings. The manual release test of §7 was run on 1.2.0.4, not on 1.3.0.0. **Open:** install 1.3.0.0 in the sandbox (Force Sync over any earlier version, or uninstall with data deletion; `docs/4-prove/SandboxInstall.md` §1) and repeat the manual cases before production. The package that passes ships as it is. Supersedes the addendum to §7.
