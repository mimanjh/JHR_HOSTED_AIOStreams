# Security Policy

## Supported version

Security fixes apply to the latest commit on the default branch.

## Reporting a vulnerability

Use GitHub's private vulnerability-reporting feature for this repository. Do
not open a public issue containing credentials, private manifest URLs, logs with
private paths, exploit details, or personal deployment information.

Include:

- the affected file and version or commit
- a minimal reproduction with all secrets removed
- the security impact
- a suggested mitigation, if known

## If a secret is exposed

Assume an exposed secret is compromised even if it is deleted later because it
may remain in Git history, caches, logs, forks, and clones.

- Cloudflare tunnel token: rotate the token in Cloudflare and replace the local
  ignored token file.
- AIOStreams operator password: replace `AIOSTREAMS_AUTH` in `.env` and recreate
  the container.
- Private manifest URL: create a replacement AIOStreams configuration and
  reinstall the new manifest.
- `SECRET_KEY`: changing it makes existing encrypted configurations unreadable.
  Preserve the original key for recovery, then migrate deliberately to a clean
  deployment if compromise is suspected.
- Third-party API or debrid credential: revoke and rotate it with the provider.

Never post the original secret while reporting the incident.
