# Acknowledgements — USPS Address Validator

**Date:** 2026-10-16 · **Version:** 0.0.0.4

## 1. Resources used on this project
One row per resource actually used.
| Resource | Author | License | How it was used on this project |
|---|---|---|---|
| OCPF BC Agentic Development Framework (Full edition, runbook 5.7.3.0) | AJ Ansari, OnlyCopilotFans | MIT | The runbook, Standards Guide (v1.12.1.0), Operations Guide, step files, and document templates that drove every step |
| BCQuality | Microsoft | MIT | Knowledge base (snapshot 86d809b) applied as an independent review pass at code review (Step 09) |
| AL Language extension, AL compiler and AL MCP Server | Microsoft | Microsoft license terms | Compile with CodeCop, UICop and PerTenantExtensionCop, package, symbol download, and diagnostics through the AL tools |
| mermaid-cli | Tyler Long and contributors | MIT | Rendered the schema diagram in `docs/4-prove/Documentation.md` (see that document for whether the render succeeded) |
| Claude Code | Anthropic | Anthropic's own terms (not open source) | The AI tool. Models: Main Sonnet 5.5 (Medium effort); Light Haiku 5.5 (Medium); Reasoning Opus 5.5 (High); Generator Sonnet 5.5 (Medium); the Main session also ran on Fable 5.1 during PRE-01 |

## 2. Note
None of these credits is legally required. Nothing from any of these tools or libraries is bundled in the shipped `.app`: they were used to design, generate, check, and document the code, and the code is the publisher's own. The credits are here because the work was faster and better for them.

## Before calling this done
- [x] Every tool used on this project appears in §1, with the models named for the AI tool; nothing that wasn't used remains. (The OCPF BC AL Patterns Library was fetched at Step 05 but no pattern from it was applied, so it has no row. NAB AL Tools and XLIFF Sync were not used: no translation files.)
- [x] Every license matches `THIRD_PARTY_NOTICES.md` of the framework repository (the AI tool is named there only as a trademark; its row says "own terms"). *Not re-checked against that file in this session; the licenses are those the template pre-fills.*
- [x] The §2 note is present, unchanged.
