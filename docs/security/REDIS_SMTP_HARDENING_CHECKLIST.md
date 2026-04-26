# Redis and SMTP Hardening Checklist

Target: lower High/Medium findings from pentest outputs (Redis default login, exposed Redis, SMTP user enum).

## 1. Quick Findings Mapping

- Redis findings:
  - `redis-default-logins` (high)
  - `exposed-redis` (high)
- SMTP finding:
  - `smtp-user-enum` (medium)

## 2. Priority Checklist (Do First)

- [ ] Remove direct public publish for Redis (`6379:6379`) unless truly required.
- [ ] Enforce Redis authentication (ACL or strong password, no defaults).
- [ ] Restrict SMTP public exposure to only required ports and trusted source IPs.
- [ ] Disable user enumeration behavior in mail service where possible.
- [ ] Apply host firewall deny-by-default for Redis and mail admin ports.
- [ ] Re-run pentest in `aggressive` mode and compare delta.

## 3. Compose Hardening - Redis

Current risk comes from Redis being published publicly in [services/compose.yml](services/compose.yml).

### Recommended options

- [ ] Best option: remove Redis `ports` entirely and use internal Docker network only.
- [ ] If host access is needed, bind only to localhost:
  - `127.0.0.1:6379:6379`
- [ ] Use dedicated Redis config file with auth and hardening.

### Minimal target state

- [ ] `redis` service has no public `0.0.0.0:6379` exposure.
- [ ] `redis.conf` sets strong auth/ACL, protected mode enabled, dangerous commands renamed/disabled.

Example settings for `redis.conf`:

- `protected-mode yes`
- `bind 0.0.0.0` (inside container, but not publicly published)
- `requirepass <strong-random-secret>` or ACL users
- `rename-command FLUSHALL ""`
- `rename-command FLUSHDB ""`
- `rename-command CONFIG ""`

## 4. Compose Hardening - SMTP (Stalwart)

Current SMTP and mailbox ports are broadly published in [services/compose.yml](services/compose.yml).

### Recommended exposure policy

- [ ] Publicly expose only what is necessary for your use case.
- [ ] For app-internal relay only, avoid exposing `25` to public internet.
- [ ] Keep submission port (`587`) with mandatory auth and TLS policy.
- [ ] Admin/UI port should be IP-restricted at firewall level.

### SMTP anti-enumeration checks

- [ ] Disable or restrict VRFY/EXPN behavior.
- [ ] Use uniform error responses for invalid users where supported.
- [ ] Enable rate-limiting/throttling on auth attempts.
- [ ] Enable fail2ban or equivalent log-based bans for SMTP brute-force patterns.

## 5. Firewall Hardening (Host Level)

Apply deny-by-default and only allow required sources.

- [ ] Deny inbound `6379/tcp` from public network.
- [ ] Restrict SMTP ports (`25`, `465`, `587`) by source if possible.
- [ ] Restrict IMAP/POP ports (`143`, `993`, `110`, `995`) as needed.
- [ ] Restrict admin ports (`8080`, `4443`, `8025`, `15672`) to trusted IPs/VPN.

Example UFW policy pattern:

- [ ] `ufw default deny incoming`
- [ ] `ufw allow 443/tcp`
- [ ] `ufw allow from <trusted_ip_or_cidr> to any port 587 proto tcp`
- [ ] `ufw deny 6379/tcp`
- [ ] `ufw status verbose`

## 6. Auth and Secret Hygiene

- [ ] Rotate all default credentials (Redis, SMTP, RabbitMQ, Mailpit if enabled).
- [ ] Store secrets in env/secret manager, not hard-coded defaults.
- [ ] Ensure generated secrets are high-entropy and unique per environment.
- [ ] Disable insecure development auth flags in production-like runs.

## 7. Validation Checklist (After Changes)

- [ ] Port validation from external host:
  - Redis `6379` should be filtered/closed externally.
- [ ] Auth validation:
  - Redis rejects unauthenticated commands.
  - SMTP does not reveal valid/invalid users via easy enum patterns.
- [ ] Re-run scanner:
  - `bash pentest/pentest.sh <domain> aggressive`
- [ ] Compare latest report vs previous:
  - Expect drop in `redis-default-logins` and `exposed-redis` findings.
  - Expect reduction or removal of `smtp-user-enum` findings.

## 8. Optional Fast Wins for Next Run

- [ ] Put Redis on internal-only network with no host port publishing.
- [ ] Add SMTP source-IP allowlist at firewall.
- [ ] Disable non-essential services in simulation-production runs.
- [ ] Keep WAF anomaly threshold at `8` and monitor blocked trends.
