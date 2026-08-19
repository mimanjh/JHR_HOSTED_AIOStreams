# Contributing

Contributions that improve deployment safety, documentation, compatibility, or
cross-platform behavior are welcome.

## Before opening a pull request

1. Do not add `.env`, `data/`, databases, backups, real domains, tunnel tokens,
   private manifest URLs, API keys, account identifiers, or generated logs.
2. Use placeholders such as `aio.example.com` and `replace_with_...`.
3. Run `scripts/check-repository-safety.ps1`.
4. Run `docker compose config --quiet` with disposable local configuration.
5. Build and start the Compose project when Docker is available.
6. Explain user impact, security implications, and validation in the pull
   request.

Do not weaken `.gitignore`, `.dockerignore`, or the fail-closed compatibility
patch without explaining and validating the resulting security boundary.
