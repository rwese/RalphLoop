# Security Policy for RalphLoop

## 🔒 Commitment to Security

RalphLoop is committed to maintaining the highest standards of security. This document outlines our security practices and requirements.

## 🚨 Critical: Never Skip Pre-commit Hooks

**DO NOT use `git commit --no-verify` or `git commit -n`**

Pre-commit hooks are CRITICAL for security and MUST run on every commit. Skipping these hooks is a **security violation**.

### Why Hooks Cannot Be Skipped

1. **Secret Scanning**: Gitleaks in pre-commit catches exposed API keys, tokens, and secrets BEFORE they reach the CI pipeline
2. **CI Protection**: The GitHub Actions pipeline includes secret scanning that will REJECT commits with exposed secrets
3. **Security Breach Prevention**: Exposed secrets can lead to:
   - Unauthorized access to APIs and services
   - Compromised user accounts
   - Financial loss
   - Reputation damage

### Consequences of Skipping Hooks

- Commits with exposed secrets will be REJECTED by CI pipeline
- Repeated violations may result in access restrictions
- Exposed secrets MUST be rotated immediately (they are considered compromised)

## 🔑 Secret Management

### Allowed Secret Storage

Secrets may only be stored in:

- `.envrc` - with placeholder values like `YOUR_OPENCODE_API_KEY_HERE`
- Environment variables (recommended for local development)
- GitHub Secrets (for CI/CD)

### Forbidden Patterns

Never commit:

- JWT tokens
- API keys
- Database credentials
- SSH private keys
- OAuth tokens
- Any sensitive configuration

## 🛡️ Security Controls

### Pre-commit Hooks

RalphLoop uses [Lefthook](https://github.com/evilmartians/lefthook) for git hooks:

```bash
# Install lefthook
brew install lefthook

# Initialize hooks
lefthook install
```

Pre-commit hooks include:

- **Gitleaks**: Secret scanning (fails on exposed secrets)
- **Prettier**: Code formatting
- **MarkdownLint**: Documentation linting
- **ShellCheck**: Shell script analysis

### CI/CD Pipeline

The GitHub Actions pipeline enforces:

1. **Gitleaks scan**: Secrets detection
2. **Docker image build**: Only after secrets scan passes
3. **Image attestation**: Provenance verification

### Branch Protection

The `main` branch is protected:

- Require status checks to pass before merging
- Require secret scanning to pass
- Prevent force pushes

## 📋 Response to Security Incidents

### If You Expose a Secret

1. **Immediately rotate the secret** in the affected service
2. **Do NOT delete the commit** - this makes recovery harder
3. **Replace the secret with a placeholder** (like `YOUR_API_KEY_HERE`)
4. **Push the fix** - CI will allow the corrected commit
5. **Document the incident** for review

### Reporting Vulnerabilities

Report security vulnerabilities to: <security@ralphloop.example.com>

## 🔄 Security Best Practices

1. ✅ Always run `git commit` without `--no-verify`
2. ✅ Use environment variables for local secrets
3. ✅ Rotate exposed secrets immediately
4. ✅ Review code before committing
5. ✅ Report any security concerns

## 📞 Contact

For security questions: <security@ralphloop.example.com>

---

**Remember**: Security is everyone's responsibility. Never compromise security for convenience.
