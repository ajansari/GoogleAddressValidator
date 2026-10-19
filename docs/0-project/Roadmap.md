# Roadmap

| ID | Item | Source | Status |
|---|---|---|---|
| R-08-1 | `Access = Internal` on codeunit 60118 Validation Writer | GapAnalysis G2 | Scheduled with CR-1 batch R4 |
| R-08-2 | Reject USPS/provider address with blank street, city, state or ZIP (+ test) | GapAnalysis G3 | Scheduled with CR-1 R2 |
| R-08-3 | `Access = Internal` on API client (and Address Service under CR-1) | GapAnalysis G4 | Scheduled with CR-1 |
| R-08-4 | Sandbox: HttpClient-blocked path (Allow HttpClient Requests off, no network) | GapAnalysis G5 | Closed 2026-10-17 — release round on 0.0.0.7 passed with no findings (ReleaseTestResults) |
| R-08-5 | Sandbox round: 24 automated tests, manual tests 11–14, 19, 21; Contact sync, US captions, HttpClient default | GapAnalysis G15, G17 | Closed 2026-10-17 — release round on 0.0.0.7 passed with no findings (ReleaseTestResults) |
| R-08-6 | Live provider contract checks | GapAnalysis G16 | Closed 2026-10-17 — release round on 0.0.0.7 passed with no findings (ReleaseTestResults) |
| R-09-1 | Install main 0.0.0.4 (+ tests 0.0.0.3) in a sandbox; run AL Test Tool; verify privacy notice on fresh and upgraded install, Contact sync, rename propagation, caller check | CodeReview 09-1, 09-2, 09-WAIVER | Closed 2026-10-17 — release round on 0.0.0.7 passed with no findings (ReleaseTestResults); automated-test run not separately confirmed (R-09-1, R-11-1) |
| R-09-2 | Confirm USPS privacy-policy link in the notice; decide telemetry (CR9-23) and Standards §1.1 wording (CR9-12); flag patterns P1–P5 | CodeReview | Closed 2026-10-17 — release round on 0.0.0.7 passed with no findings (ReleaseTestResults) |
| R-11-1 | Check AL Test Tool page id (test app launch.json 130401 vs guide 130451); verify BC menu paths and page wording in a tenant; FRD FR-4 button names (OK/Cancel); fill Documentation commit SHA after committing; stray `OnlyBCFans_USPS Address Validator Tests_0.0.0.1.app` in the test app root | Step 11 writers | Closed 2026-10-17 — release round on 0.0.0.7 passed with no findings (ReleaseTestResults); automated-test run not separately confirmed (R-09-1, R-11-1) |
| R-12-1 | Google live spike (TDD §14.y), real key and real addresses; confirm Google privacy link and the platform's "Microsoft services" consent text; Google Cloud project/billing/API enablement/key restriction/daily cap/budget alert for Deployment.md | Gap Analysis GA-12, GA-24 | Closed 2026-10-17 — release round on 0.0.0.7 passed with no findings (ReleaseTestResults) |
| R-12-2 | FRD open questions renumbering (OQ-31 privacy link, OQ-32 telemetry; OQ-30 resolved), TDD 2.4 caller-check sentence, 2.17 caption sentence; consolidate FRD 2.0 / TDD / PostDevTDD for Google (Step 10) | Gap Analysis GA-19, GA-20 | Step 10 |
| R-08-7 | `AssertLogSource` should assert the key appears in "Source Description" (test 25) | GapAnalysis GA-1.1-02 b | Scheduled |
| R-08-8 | Generic `TestCountryResets<Tag>` for the 15 new Country/Region triggers (test 39) | GapAnalysis GA-1.1-14 | Scheduled |
| R-12-3 | First install of 1.1.0.3 + test app 0.0.0.12; run 127 automated tests and TC-30..TC-38; confirm D3 | GapAnalysis GA-1.1-07, GA-1.1-13 | Step 12 |
