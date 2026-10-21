# Security policy

## Scope

The install scripts in `harnesses/*/*/install.sh`, and the commands the READMEs tell you to run. The third-party CLIs, payload packs and vendor installers they download are out of scope — report those to their own maintainers.

## Reporting a vulnerability

Please report privately. Do not open a public issue.

1. Go to the repository's **Security** tab.
2. Choose **Report a vulnerability** (GitHub private vulnerability reporting / security advisory).
3. Describe the script, the problem, and how to reproduce it.

Expect a first reply within 7 days. Fixes ship as a new commit and a new release tag, with a CHANGELOG entry.

## Before you run anything

Every TL;DR here pipes a script into `bash`. Read the script first:

```bash
curl -fsSL <url> -o install.sh && less install.sh && bash install.sh
```

To get a fixed, reviewable copy, use a release tag instead of `master` in the URL (for example `v1.0.0`).
