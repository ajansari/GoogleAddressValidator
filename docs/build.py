#!/usr/bin/env python3
"""Builds docs/index.html from the three Markdown documents in docs/4-prove/.
Needs Node (npx fetches marked 12.0.2). Run from the repository root: python3 docs/build.py"""
import re, subprocess, html, pathlib, json

root = pathlib.Path(__file__).resolve().parents[1]
app = json.loads((root / "app.json").read_text())
SRC = {
    "user-guide": ("User Guide", "docs/4-prove/UserGuide.md"),
    "documentation": ("Documentation", "docs/4-prove/Documentation.md"),
    "faq": ("FAQ", "docs/4-prove/FAQ.md"),
    "google-setup": ("Google Setup", "docs/4-prove/GoogleSetupGuide.md"),
}

def md(text):
    return subprocess.run(["npx", "--yes", "marked@12.0.2", "--gfm"], input=text, capture_output=True, text=True, check=True).stdout


SUBS = [
    (r"This guide is separate from `docs/4-prove/Deployment.md` \(the install procedure\) and `docs/4-prove/SandboxInstall.md` \(uploading the package\)\.", "This guide covers only the Google side; installing the package is covered in the deployment guide in the repository."),
    (r"That is a design assumption: it has not been confirmed against Google's billing report \(open item, TDD §14\.y\)\.", "Check Google's billing report after your first test to confirm."),
    (r"\n\d+\. The cap is a go-live task recorded as FRD open question OQ-25\.", ""),
    (r" \(see `docs/4-prove/SandboxInstall.md`\)", ""),
    (r"Whether it is on by default in your environment is open question OQ-20\.", "Its default can differ between environments, so check it."),
    (r", and follow `docs/4-prove/HumanUnitTestScript.md`", ""),
    (r" This rule was confirmed by AJ Ansari on 2026-10-18; it has not been tested in a tenant\.", ""),
    (r"^> \*\*Note:\*\* nothing of this has been run.*$", "> **Note:** Google's answers differ by country (for example whether the state comes back as a code or a name, and what Brazil, Mexico, India and Japan return). Try a few real addresses in each country you rely on before you depend on it."),
    (r" Administrators can find installation, Google Cloud and permission details in `docs/4-prove/Deployment.md`\.", " Administrators can find installation, Google Cloud and permission details in the Google Setup section and the deployment guide in the repository."),
    (r"^Source of the list: `docs/1-define/ObjectRegister.md`, \"SC-1 additions\"\. ", ""),
    (r" Read from the code; not installed or run\. Rules: FRD FR-19; as-built detail: `docs/4-prove/PostDevTDD.md` Part G\.", ""),
    (r"The field numbers are those in `docs/2-design/TDD.md` §15\.22 \(checked against the Base Application 28\.5 symbols on 2026-10-17\); the code", "The field numbers were checked against the Base Application 28.5 symbols; the code"),
    (r" \(decision OQ-39\)", ""),
    (r" \(`docs/4-prove/AutomatedTestGuide.md` §2\)", ""),
    (r"^- \*\*Platform behaviour unverified\*\*.*$", "- **Platform behaviour.** The production default of \"Allow HttpClient Requests\" can differ between environments; check it before first use."),
    (r" \(GA-\d+(, GA-\d+)?\)", ""),
    (r" \(CR-[0-9.]+-\d+\)", ""),
]

def clean(text, key):
    if key == "user-guide":                                                # its FAQ section is the FAQ tab
        text = re.sub(r"^## \d+\. Frequently asked questions.*?(?=^## )", "", text, flags=re.M | re.S)
    text = re.sub(r"\A# .*\n", "", text)                                   # own title is in the page header
    text = re.sub(r"\A(\s*\*\*(Version|Written for):\*\*.*\n)+", "", text)  # build/author meta lines
    text = re.sub(r"^> \*\*Where this build stands:\*\*.*\n", "", text, flags=re.M)
    text = re.sub(r"^## (Before calling this done|Not verified).*\Z", "", text, flags=re.M | re.S)
    text = re.sub(r"^Redrawn for version 1\.1\.0\.8.*\n", "", text, flags=re.M)
    parts = re.split(r"(`[^`\n]*`)", text)   # placeholders such as <table caption> must not become HTML tags
    text = "".join(x if x.startswith("`") else re.sub(r"<(?!https?://)([^<>\n]{1,30})>", r"&lt;\1&gt;", x) for x in parts)
    for pat, rep in SUBS:
        text = re.sub(pat, rep, text, flags=re.M)
    return text.strip() + "\n"

sections = {}
for key, (title, path) in SRC.items():
    body = md(clean((root / path).read_text(), key)).replace('../screenshots/', 'screenshots/')
    body = re.sub(r'<pre><code class="language-mermaid">(.*?)</code></pre>',
                  lambda m: '<pre class="mermaid">' + m.group(1) + "</pre>", body, flags=re.S)
    if key == "faq":                                                       # collapsible questions
        body = re.sub(r'<h3[^>]*>(.*?)</h3>\s*(.*?)(?=<h3|<h2|\Z)',
                      lambda m: f'<details class="faq"><summary>{m.group(1)}</summary>{m.group(2)}</details>', body, flags=re.S)
    body = re.sub(r"<table>", '<div class="table-wrap"><table>', body).replace("</table>", "</table></div>")
    body = re.sub(r'<h([23]) id="([^"]+)">', lambda m: f'<h{m.group(1)} id="{key}-{m.group(2)}">', body)
    sections[key] = body

tabs = "".join(f'<button class="tab" role="tab" data-tab="{k}" aria-selected="false">{html.escape(t)}</button>' for k, (t, _) in SRC.items())
panels = "".join(f'<section class="panel" id="panel-{k}" role="tabpanel" hidden><h1>{html.escape(t)}</h1>{sections[k]}</section>' for k, (t, _) in SRC.items())

page = (pathlib.Path(__file__).parent / "template.html").read_text()
appfile = f'{app["name"].replace(" ", "_")}_{app["version"]}.app'
download = f"https://github.com/ajansari/GoogleAddressValidator/raw/main/outputAppPackage/{appfile}"
page = (page.replace("{{DOWNLOAD_URL}}", download).replace("{{VERSION}}", app["version"]).replace("{{TABS}}", tabs).replace("{{PANELS}}", panels))
(pathlib.Path(__file__).parent / "index.html").write_text(page)
print("wrote docs/index.html", len(page), "bytes")
