# Hosted AIOStreams with Cloudflare Tunnel

A reusable Docker Compose template for running a private AIOStreams instance and publishing it through Cloudflare Tunnel. No inbound router ports or public server IP are required.

This repository provides deployment code only. Every person who uses it creates and owns a separate deployment with their own:

- computer or server
- domain and DNS zone
- Cloudflare account, tunnel, and tunnel token
- AIOStreams encryption key and operator password
- AIOStreams configuration, database, and private manifest URL
- optional debrid, proxy, API, and upstream add-on credentials

It does not grant access to the maintainer's server, Cloudflare account, tunnel, domain, database, or media-service accounts.

## What it deploys

- The stable `ghcr.io/viren070/aiostreams:latest` image
- A local-only AIOStreams origin at `http://127.0.0.1:3000`
- An outbound-only `cloudflared` container in the same Compose network
- Persistent SQLite storage in the ignored `./data` directory
- Password protection for the configuration page and admin dashboard
- A bounded 1 MB JSON request limit for larger configuration templates
- A combined 15 GiB container memory ceiling: 14 GiB for AIOStreams and 1 GiB for `cloudflared`

The memory settings are ceilings, not reservations. Normal small deployments generally use much less. You may lower the limits in `compose.yaml` for a smaller host.

## Requirements and expected costs

| Item | Required | Expected cost | Notes |
| --- | --- | --- | --- |
| Computer or server | Yes | Existing computer: no new hosting bill. VPS: provider-dependent monthly charge. | The host, Docker, AIOStreams, and `cloudflared` must remain running whenever clients need the add-on. Electricity and Internet usage still apply. |
| Domain name | Yes | Existing domain: usually no added cost for a subdomain. New domain: annual registration and renewal cost varies by registrar and top-level domain. | The domain can be purchased from any registrar, but its DNS zone must be active in the user's Cloudflare account. |
| Cloudflare account and Tunnel | Yes | Cloudflare Tunnel is available on Cloudflare plans, including the free plan. Paid plans are optional. | No public IP or inbound router port is required. |
| Docker runtime | Yes | Docker Engine is open source. Docker Desktop is free for personal use, education, non-commercial open source, and qualifying small businesses. Other commercial or government use may require a paid Docker subscription. | Review the current [Docker Desktop license terms](https://docs.docker.com/subscription/desktop-license/). |
| AIOStreams | Yes | Free and open source under GPL-3.0. | This project builds from the official upstream container image. |
| Third-party services | Optional | Provider-dependent. | Debrid, proxy, VPN, indexer, and API services may charge separately and have their own terms. |

Cloudflare Tunnel is documented as available on all Cloudflare plans. See the [Cloudflare Tunnel overview](https://developers.cloudflare.com/tunnel/) and [Cloudflare plan information](https://www.cloudflare.com/plans/zero-trust-services/).

## Security and account-isolation model

Each clone is independent. Local credentials never belong in Git:

- `.env` contains the deployment's encryption key and operator login.
- `secrets/cloudflare-tunnel-token.txt` contains the user's tunnel token.
- `data/` contains the SQLite database, encrypted AIOStreams configurations, templates, and cache.
- `secrets/aiostreams-manifest-url.txt` may contain a private manifest URL for local reference.

All four locations are ignored by Git. `.dockerignore` also uses an allowlist so they cannot enter the derived image build context.

A Cloudflare tunnel token is equivalent to permission to run that tunnel. Never paste it into an issue, commit, screenshot, support request, or full `docker run` command stored in this repository. See [Cloudflare's tunnel-token guidance](https://developers.cloudflare.com/tunnel/advanced/tunnel-tokens/).

Use only content, add-ons, APIs, and services that you are legally authorized to access, and comply with their terms.

## Installation

### 1. Create your copy

Select **Use this template** on GitHub, or clone the repository:

```powershell
git clone https://github.com/mimanjh/JHR_HOSTED_AIOStreams.git
Set-Location JHR_HOSTED_AIOStreams
```

A repository created from the template is independent and does not automatically receive future template updates.

### 2. Prepare a domain in Cloudflare

You need a domain whose DNS zone is active in your Cloudflare account.

- If you already own a domain, you can normally use a subdomain such as `aio.example.com` without buying another domain.
- If you do not own a domain, purchase one from a registrar and pay its registration and renewal fees.
- Add the domain to Cloudflare and follow Cloudflare's instructions to change the registrar's authoritative nameservers.
- Wait until Cloudflare reports the zone as active before troubleshooting the tunnel hostname.

Choose the final hostname before creating AIOStreams configurations. Changing `BASE_URL` later requires recreating and reinstalling generated add-ons.

### 3. Generate local configuration

Run the bootstrap script with your final HTTPS hostname:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\bootstrap.ps1 -BaseUrl https://aio.example.com
```

With PowerShell 7, you can instead run:

```powershell
pwsh ./scripts/bootstrap.ps1 -BaseUrl https://aio.example.com
```

The script:

- refuses to overwrite an existing `.env`
- generates a unique 64-character `SECRET_KEY`
- generates a strong random operator password
- creates the ignored tunnel-token file from its template
- never prints generated credentials to the terminal

Open `.env` locally to retrieve or change the generated operator password. Do not commit that file. Do not change `SECRET_KEY` after saving configurations because existing encrypted configurations would become unreadable.

If you prefer manual setup, copy `.env.example` to `.env`, replace every placeholder, and copy `secrets/cloudflare-tunnel-token.txt.example` to `secrets/cloudflare-tunnel-token.txt`.

### 4. Create your Cloudflare Tunnel

In the Cloudflare dashboard:

1. Go to **Networking > Tunnels**.
2. Select **Create Tunnel** and give it a unique name.
3. Choose the Docker setup instructions.
4. Copy the generated install command into a temporary text editor.
5. Copy only the long `eyJ...` tunnel-token value into `secrets/cloudflare-tunnel-token.txt` as one line.
6. Delete the temporary copy of the install command.

Then add a published application route:

| Setting | Value |
| --- | --- |
| Subdomain | Your chosen subdomain, such as `aio` |
| Domain | Your own domain |
| Path | Leave empty |
| Service type | `HTTP` |
| Service URL | `aiostreams:3000` |

Inside the Compose network, `aiostreams` is the service hostname. Do not use `localhost:3000` for the tunnel route because `localhost` inside the `cloudflared` container refers to that container itself.

Cloudflare's official prerequisites and tunnel workflow are documented in [Set up Cloudflare Tunnel](https://developers.cloudflare.com/tunnel/setup/).

### 5. Build and start

Open Docker Desktop and wait until its engine is ready, then run:

```powershell
docker compose config --quiet
docker compose build --pull
docker compose up -d
docker compose ps
```

The first start may take several minutes while AIOStreams initializes and downloads metadata. Wait for the `aiostreams` service to become healthy.

### 6. Configure your instance

Open your own URL:

```text
https://aio.example.com/stremio/configure
```

Sign in with `AIOSTREAMS_AUTH` from your ignored `.env`, then add your own optional service accounts, add-ons, APIs, filters, and formatters in the AIOStreams interface. Those runtime settings are stored in your local database, not in this repository.

Create the AIOStreams configuration, keep its generated manifest URL private, and install it in your supported client.

## Common commands

```powershell
# Show status
docker compose ps

# Show current resource usage
docker stats --no-stream

# Follow AIOStreams logs
docker compose logs -f aiostreams

# Follow Cloudflare Tunnel logs
docker compose logs -f cloudflared

# Restart both services
docker compose restart

# Stop without deleting local data
docker compose down

# Pull current base images, rebuild the compatibility patch, and recreate
docker compose build --pull
docker compose up -d
```

Avoid posting complete logs publicly without reviewing them for private URLs, identifiers, and credentials.

## Backups and recovery

Back up `.env` and `data/` together. Keep the backup private. The database cannot decrypt saved configurations without the matching `SECRET_KEY` from `.env`.

For a consistent SQLite backup, stop the services first:

```powershell
docker compose down
Copy-Item .env C:\path\to\private-backup\.env
Copy-Item data C:\path\to\private-backup\data -Recurse
Copy-Item secrets\cloudflare-tunnel-token.txt C:\path\to\private-backup\cloudflare-tunnel-token.txt
docker compose up -d
```

Store the backup in an encrypted location. Do not upload it to a public repository.

## Compatibility patch

The derived Docker image changes only AIOStreams' Express JSON request limit from the upstream default of 100 KB to a bounded 1 MB. This allows larger configuration templates that would otherwise fail with HTTP 413.

The patch requires exactly one known parser statement in the upstream image. If a future upstream release changes or removes that statement, the build stops instead of silently patching the wrong code. Review `docker/patch-request-limit.cjs` when that happens and remove the patch if upstream no longer needs it.

## Troubleshooting

### The add-on installs but no streams appear

- Confirm the public hostname resolves with `nslookup aio.example.com`.
- Confirm `docker compose ps` reports AIOStreams as healthy.
- Inspect the redacted AIOStreams and tunnel logs.
- Newly changed nameservers or DNS records may need time to propagate through resolver caches.

### Cloudflare reports the tunnel as healthy but the hostname fails

- Confirm the published route uses service type `HTTP` and service URL `aiostreams:3000`.
- Confirm `BASE_URL` exactly matches the public `https://` hostname.
- Confirm the token file contains only the tunnel token, not the entire Docker command.

### Docker build fails while applying the request-limit patch

The upstream image probably changed. Do not weaken the patch's exact-match safeguard. Compare the new upstream server code, update or remove the compatibility patch deliberately, and rebuild.

## Repository safety checks

Before committing changes, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\check-repository-safety.ps1
docker compose config --quiet
git status --short --untracked-files=all
```

Only templates, documentation, scripts, and deployment code should be tracked. Never use `docker compose config` without `--quiet` in public logs because the rendered output expands values from `.env`.

## Upstream project and independence

This is an independent deployment template. It is not affiliated with or endorsed by AIOStreams, Viren070, Cloudflare, Docker, Stremio, Nuvio, or any optional service provider.

- [AIOStreams source](https://github.com/Viren070/AIOStreams)
- [AIOStreams documentation](https://docs.aiostreams.viren070.me/)
- [AIOStreams environment variables](https://docs.aiostreams.viren070.me/configuration/environment-variables/)

## License

This repository is licensed under the GNU General Public License v3.0. See `LICENSE` and `NOTICE`.
