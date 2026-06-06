# Security Policy

## Reporting A Vulnerability

Please do not report security vulnerabilities through public GitHub issues.

Use GitHub vulnerability reporting for this repository when it is available. If
that reporting channel is not enabled yet, open a minimal public issue that only
asks maintainers to enable a confidential reporting channel. Do not include
exploit details, secrets, logs, tokens, or personally identifying data in that
issue.

Include the following details only in the confidential report:

- a short description of the issue;
- affected files or features;
- reproduction steps if available;
- impact assessment if known;
- whether credentials, account data, purchase state, or local user data can be
  exposed or modified.

## Supported Versions

Until the first public release, only the default branch is considered supported
for security review.

After public releases begin, supported versions will be documented in this file.

## Config Safety

This is a public open-source repository. Do not commit production keys, local
config, signing material, provisioning profiles, generated local config, access
tokens, or service credentials.

Before opening a PR or preparing a public release, run:

```bash
scripts/check-public-release-readiness.sh
```

This checks public config hygiene, Markdown links, and the canonical asset gate.

## Public Data Safety

Do not include any of the following in public issues, pull requests, release
evidence, screenshots, or logs:

- Account AV user identifiers;
- purchase receipts or credit ledger details;
- access tokens, session values, provider request IDs, or signed upload URLs;
- private photos, clips, generated exports, or project metadata;
- demo account passwords;
- internal backend URLs or private provider configuration.

Security reports that require sensitive details must use a confidential
reporting channel.
