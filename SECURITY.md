# Security Policy — Green Algeria 🔐

## Supported Versions

| Version | Supported |
|---------|-----------|
| v3.6.x  | ✅ Active support |
| v3.5.x  | ⚠️ Critical fixes only |
| < v3.5  | ❌ No longer supported |

## Reporting a Vulnerability

If you discover a security vulnerability in this application, **do NOT open a public GitHub issue**.

### How to Report

Please report security issues directly to the developer:

- **GitHub**: [@sam22ir](https://github.com/sam22ir)
- **Email**: samirsaadi610@gmail.com

### What to Include

When reporting a vulnerability, please provide:
1. A description of the issue and its potential impact
2. Steps to reproduce the vulnerability
3. Any proof-of-concept code (if applicable)
4. Suggested remediation (optional)

### Response Time

- **Acknowledgement**: Within 48 hours
- **Initial assessment**: Within 7 days
- **Fix timeline**: Depends on severity (critical: 48h, high: 7 days, medium/low: next release)

## Security Architecture

This app enforces security at multiple levels:

- **Row Level Security (RLS)** enabled on ALL Supabase tables
- **Supabase service role key** is NEVER exposed in client code
- **Firebase keys** are stored in environment variables only
- **Privileged roles** (`developer`, `initiative_owner`) are assigned manually via Supabase Dashboard — never via the app
- **All sensitive keys** stored in `.env` file only (gitignored)

## Disclosure Policy

We follow responsible disclosure. Once a fix is released, we will publicly acknowledge the reporter (with permission) in the relevant release notes.
