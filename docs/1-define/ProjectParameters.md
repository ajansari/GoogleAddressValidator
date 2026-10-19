# Project Parameters — Google Address Validator

> **Revised 2026-10-16 (remediation 07a, CR-1, AJ Ansari):** extension renamed, prefix `obcfusps` → `obcfgav`, namespace → `OnlyBCFans.GoogleAddress`, App Code `USPS` → `GAV`. Values below are the **new** ones; builds 0.0.0.1–0.0.0.4 used the USPS names. Sign-off of the CR-1 documents is recorded in the ChangeLog.

**Source of truth** for every name, ID, version, prefix, namespace and quoting decision in this project (runbook Step 01). Nothing in AL code hardcodes a value that belongs here.
**Gathered:** 2026-10-10 by AJ Ansari, through the options mechanism. **Status:** confirmed by AJ Ansari, 2026-10-10.

## 1.1 Extension identity
| Parameter | Value |
|---|---|
| Extension Name | Google Address Validator (was USPS Address Validator; renamed 2026-10-16, CR-1) |
| Publisher | OnlyBCFans (PRE-01) |
| Deployment Target | SaaS PTE |
| Use Namespace | Yes |
| Namespace | OnlyBCFans.GoogleAddress |
| Localization | US |
| Starting Version | 0.0.0.1 (new app) |
| App Icon | Yes — `src/logo/AppLogo.png`, 300 × 300, resized from `images/google-address-validation-icon-300.png` (was `images/usps-address-validation-icon-512.png`; new icon 2026-10-16) (PRE-01) |
| Approvers | One person (AJ Ansari, every role) |

Packages are written to `outputAppPackage/` in the project root, never overwritten; every build bumps the Revision segment; the release candidate `1.0.0.0` is asked for at Step 11.

## 1.2 Object ID allocation
| Block | From | To | Size |
|---|---|---|---|
| Main app (renumbered for 1.3.0.0, AJ Ansari 2026-10-19; per object type, Standards §5.0) | 92800 | 92829 | 30 IDs per type |
| Test app | 92830 | 92849 | 20 IDs per type |

Since 1.3.0.0 (AJ Ansari, 2026-10-19) the main app's `idRanges` is `[92800–92829]` and the test app's (own `app.json`, sibling folder `USPSAddressValidator.Tests`; app name Google Address Validator Tests) is `[92830–92849]`. Before 1.3.0.0 the apps used 60093–60192 (main 60093–60122 and 60134–60192, test 60123–60133); `docs/1-define/ObjectRegister.md` gives every object's old and new ID.

**Permission Sets required: Yes** — the extension owns tables (Standards §5.3); two or more IDs are reserved in the primary range for them (the TDD fixes the exact IDs).

## 1.3 Naming & API parameters
| Parameter | Value |
|---|---|
| AL Object Prefix | `obcfgav` (was `obcfusps`) |
| APIPublisher / APIGroup / APIVersion / entity patterns | N/A — the extension has no API pages |
| Permission Set App Code | `GAV` |
| Permission Set Names (derived) | `OBCFGAV GAV, USE` and `OBCFGAV GAV, ADMIN` (≤ 20 chars each; the spec's USE / ADMIN roles under Standards §5.4's naming; the default VIEW / EDIT pair is not used — confirmed by AJ in FRD OQ-11) |
| Other extensions using the prefix | None |

**Consequences recorded for the TDD:** the 8-character prefix leaves 22 characters of every 30-character AL identifier; the spec's long object names (e.g. "USPS Addr. Validation Setup") must be shortened and the abbreviations of Standards §4.2 applied. The App Code is limited to 5 characters (`13 − 8`).

## 1.4 Platform & runtime
| Parameter | Value |
|---|---|
| AL Runtime | 17.0 (Microsoft Learn: ships with Business Central 2026 release wave 1 = 28.0) |
| BC Application Minimum | 28.0.0.0 |
| Recommended BC Version | 28.5 |
| Symbol Source | BC 28.5.54151, W1, Microsoft public symbol feed (AL MCP Server global download; System 28.0.54688.0, System Application 28.5.54151.55108, Base Application 28.5.54151.55594, Application 28.5.54151.54178, Business Foundation 28.5.54151.54365 added at Step 07). Localization is US: the Customer address fields are global; any country-specific table or field is verified from a sandbox download before design uses it. |

## 1.5 Feature flags
`NoImplicitWith` — enabled and enforced. `TranslationFile` — enabled on every project (Standards §8.2); it only produces the regenerated `.g.xlf`.

## 1.6 Onboarding & discoverability
| Parameter | Answer | Specifics |
|---|---|---|
| Assisted Setup Wizard | **Yes** | Added to scope by AJ on 2026-10-10 (raw input: `requirements/scope-additions-2026-10-10-requirements.md`). Configures the **Google Maps API key only** (Isolated Storage, `SecretText`; the USPS Consumer Key/Secret and Environment of the earlier build no longer exist). Enabled (default No), US country code and timeout stay on the setup card. Not asked for: Test Connection step, enabling at the end. |
| Activity Cues | No | Nothing in the spec counts items needing attention. |
| Departments / My Business Central placement | No | Setup and log pages are reached through Tell Me by name; the action lives on the Customer Card and, since 1.1, on the 15 other master-data cards (FRD FR-10). |
| Business Central Copilot feature | No | Nothing in the spec uses AI. |

## 1.6a Scope additions decided at intake (AJ, 2026-10-10)
1. **Assisted Setup Wizard** for entering the Google Maps API key (above).
   *(1.1 note, SC-1: item 2 below applies to every address source in FRD FR-10, not only Customer; field number 92800 on each table, field 92801 for the Company Information ship-to block.)*
2. **Customer field "Address Validated"** — a Boolean added to the Customer table by a table extension and shown on the Customer Card in the FastTab where the address appears:
   - Default `false` for every new customer.
   - **Not editable by the user** (page field `Editable = false`); changed only by code.
   - Set `true` when the validation routine runs and the user **accepts** the suggested (Google) address.
   - Set `true` also when the check returns **Confirmed** (the suggested address equals the BC address). *(AJ chose this over strict "accept only".)*
   - **Run and ignored: the field stays as it was** (false if it was false).
   - Reset to `false` when a validated customer's address fields are edited afterwards. *(AJ chose this.)*
   - Exact field name, ID and the edit-detection trigger go in the FRD/TDD.

## 1.7 Model & effort assignment (from PRE-01)
| Role | Model | Harness identifier | Thinking effort | Materialized as |
|---|---|---|---|---|
| Main | Sonnet 5.5 | `claude-sonnet-5-5` (the session, set with `/model`) | Medium | this session (`/effort`) |
| Light | Haiku 5.5 | `haiku` | Medium | `.claude/agents/ocpf-light.md` |
| Reasoning | Opus 5.5 | `opus` | High | `.claude/agents/ocpf-reasoning.md` |
| Generator | Sonnet 5.5 (inherits Main) | `sonnet` | Medium | `.claude/agents/ocpf-generator.md` |
| Reviewer (pre-review, runbook 5.8.0.0) | Sonnet 5.5 (inherits Main) | `sonnet` | Medium | `.claude/agents/ocpf-reviewer.md` |

## 1.8 Framework file tracking
Framework files in `.gitignore`: **Yes**. Exception requested by AJ: `ocpfFramework/state/dashboard.html` stays tracked (see `docs/0-project/ProjectMemory.md`).

## 1.9 Languages & translation
| Parameter | Value |
|---|---|
| Working language | English |
| Countries | United States |
| Target languages | English (United States) — ENU → `en-US` — Microsoft built-in; required at first release: Yes (source language); reviewer: AJ Ansari; terminology source: Microsoft |
| Source language | `en-US` |
| Source wording | **US wording, no translation files** (en-US is the only target; not AppSource) |
| Document languages | English only; no translated documents |
| Customer-language documents | No (the extension produces none) |
| Translatable data | No (the log keeps provider text as returned) |
| Translation tooling | N/A (no translation files; decided at Step 05 if this changes) |

Because source wording is *US wording, no translation files*, no `TranslationGlossary.md` is created and the `Translations/` folder holds no target files; only Operating Rule 8 and Standards §1.7 apply. If a language is added later, this sheet and `app.json` are reopened.

## 1.10 Project setup (the agent's job)
`app.json` written complete (platform/application 28.0.0.0, runtime 17.0, features NoImplicitWith and TranslationFile, target Cloud, idRanges 60093–60142 at 1.0.0.0, 60093–60192 from 1.1.0.0, `[92800–92829]` since 1.3.0.0); local git repository initialized (no remote, no commits); `.gitignore` verified with `git check-ignore` from this sheet (id, name, publisher and logo kept from PRE-01); `src/` and `src/logo/AppLogo.png` exist; AL tools connected (AL MCP Server through the AL Language extension 18.1.2842859); symbols for BC 28.5 in `.alpackages/` (gitignored).
