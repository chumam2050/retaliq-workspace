# Caddy WAF Configuration

This directory contains Caddy reverse proxy configuration with Web Application Firewall (WAF) support.

## Overview

The setup uses custom-built Caddy with:
- **Cloudflare DNS plugin** - For DNS-01 ACME challenges
- **caddy-waf** - Web Application Firewall middleware for Caddy ([caddy-waf](https://github.com/fabriziosalmi/caddy-waf))
    - JSON-based rules configuration
  - OWASP Core Rule Set support
  - Written in Go for high performance
  - Production-ready and actively maintained

## Environment-Based Configuration

The configuration automatically switches between development and production mode based on the `RETALIQ_ENV` environment variable in `/services/.env`:

### Development Mode (default)
**Set:** `RETALIQ_ENV=development`

- Uses `Caddyfile.development`
- Local TLS with self-signed certificates
- Auto HTTPS disabled
- WAF enabled (same as production)
- Security headers enabled
- Perfect for testing WAF and security features locally
- Suitable for local development with `.test` domains

### Production Mode
**Set:** `RETALIQ_ENV=production`

- Uses `Caddyfile.production`
- Automatic HTTPS with Let's Encrypt
- WAF enabled and configured
- Enhanced security headers
- Rate limiting enabled
- Production-grade TLS configuration

## Files Structure

```
caddy/
├── Dockerfile                    # Custom Caddy build with plugins
├── docker-entrypoint.sh         # Entrypoint that selects Caddyfile
├── Caddyfile.development        # Development configuration (WAF + local certs)
├── Caddyfile.production         # Production configuration (WAF + Let's Encrypt)
├── waf/
│   ├── rules.json               # WAF rules (JSON)
│   ├── ip_blacklist.txt         # IP blacklist entries
│   └── dns_blacklist.txt        # DNS blacklist entries
├── certs/                       # Local development certificates
├── data/                        # Caddy data (certificates, etc.)
├── config/                      # Caddy auto-saved config
└── README.md                    # This file
```

## WAF Configuration

### Protection Features (Production Only)

The WAF provides protection against:

1. **SQL Injection (SQLi)** - Detects and blocks SQL injection attempts
2. **Cross-Site Scripting (XSS)** - Blocks XSS attack patterns
3. **Remote Code Execution (RCE)** - Prevents code execution attempts
4. **Local File Inclusion (LFI)** - Blocks path traversal attacks
5. **Security Scanners** - Detects and blocks common security tools
6. **Protocol Attacks** - HTTP protocol violation detection
7. **Session Fixation** - Session security enforcement

### WAF Settings (Caddyfile.production)

```caddyfile
(waf) {
    waf {
        directives {
            SecRuleEngine On
            SecRequestBodyAccess On
            
            # anomaly threshold (1-4, higher = stricter)
            SecAction \
                "id:900000,\
                phase:1,\
                nolog,\
                pass,\
                setvar:tx.anomaly_threshold=2"
            
            # Custom rules
            Include /etc/caddy/waf/rules.json
        }
        
        # Exclude paths
        exclude /health
        exclude /metrics
    }
}
```

### Custom Rules

Custom security rules are defined in `waf/rules.json` using JSON rules format:

- **Attack Pattern Detection** - Custom regex patterns for specific threats
- **Application Whitelists** - Exceptions for legitimate application behavior (e.g., Laravel CSRF tokens)
- **Rate Limiting Rules** - Endpoint-specific rate limits (login: 10/min, API: 300/min)  
- **IP Blacklist/Whitelist** - IP-based access control (commented by default)
- **Monitoring Rules** - Log-only rules for suspicious activity

### Rule Syntax

caddy-waf uses JSON rules format:

```conf
SecRule REQUEST_URI "@rx (pattern)" \
    "id:1001,\
    phase:1,\
    deny,\
    status:403,\
    log,\
    msg:'Description'"
```

### anomaly thresholds

Choose based on your security requirements:

- **Level 1**: Basic protection, minimal false positives
- **Level 2**: Moderate protection (recommended for production)
- **Level 3**: Strong protection, may require tuning
- **Level 4**: Maximum protection, expect false positives

### WAF Modes

- **block** - Block malicious requests (recommended for production)
- **log** - Log malicious requests but allow them (testing)
- **monitor** - Monitor only, minimal logging (debugging)

## Usage

### Building and Starting

```bash
# Navigate to services directory
cd /home/dev/retaliq/services

# Build Caddy with plugins
docker compose build caddy

# Start services (development)
docker compose up -d caddy

# Start services (production)
# First, set RETALIQ_ENV=production in .env
docker compose up -d caddy
```

### Viewing Logs

```bash
# Caddy general logs
docker compose logs -f caddy

# WAF logs (production only)
docker exec caddy tail -f /var/log/caddy/waf.log

# Access logs
docker exec caddy tail -f /var/log/caddy/access.log
```

### Testing WAF

Test WAF blocking in production mode:

```bash
# SQL injection attempt (should be blocked)
curl "https://your-domain.com/?id=1' OR '1'='1"

# XSS attempt (should be blocked)
curl "https://your-domain.com/?search=<script>alert('xss')</script>"

# Path traversal (should be blocked)
curl "https://your-domain.com/../../etc/passwd"

# Normal request (should work)
curl "https://your-domain.com/"
```

Expected responses:
- Blocked: HTTP 403 Forbidden
- Allowed: HTTP 200 OK

### Switching Environments

1. Edit `/services/.env`:
   ```env
   RETALIQ_ENV=production  # or development
   ```

2. Restart Caddy:
   ```bash
   docker compose restart caddy
   ```

3. Verify the mode in logs:
   ```bash
   docker compose logs caddy | grep "Starting Caddy"
   ```

Or use the management script:
```bash
./caddy/waf-manage.sh switch production
./caddy/waf-manage.sh switch development
```

## Security Headers (Production)

Automatically applied in production mode:

- `Strict-Transport-Security` - Force HTTPS
- `X-Content-Type-Options` - Prevent MIME sniffing
- `X-Frame-Options` - Clickjacking protection
- `X-XSS-Protection` - XSS filter
- `Referrer-Policy` - Control referrer information
- `Permissions-Policy` - Restrict browser features
- `Content-Security-Policy` - CSP for XSS protection

## Rate Limiting

### Global Rate Limits (Production)

- **General Routes**: 100 requests/minute per IP (burst: 20)
- **Login Endpoints**: 10 attempts/minute per IP
- **API Routes**: 300 requests/minute per IP

### Customizing Rate Limits

Edit `waf/rules.json` and adjust the rules:

```conf
# Example: Rate limit for login
SecRule REQUEST_URI "@rx (/login|/api/auth)" \
    "id:3001,phase:1,pass,setvar:ip.login_attempts=+1,expirevar:ip.login_attempts=60"

SecRule IP:LOGIN_ATTEMPTS "@gt 10" \
    "id:3002,phase:1,deny,status:429,msg:'Too many login attempts'"
```

## Whitelisting IPs

To whitelist specific IPs in production, edit `waf/rules.json`:

```conf
# Whitelist office IP
SecRule REMOTE_ADDR "@ipMatch 203.0.113.0/24" \
    "id:5001,phase:1,pass,ctl:ruleEngine=Off,msg:'Whitelisted IP'"
```

## Excluding Paths from WAF

To exclude specific paths from WAF protection, add to the `(waf)` snippet in `Caddyfile.production`:

```caddyfile
(waf) {
    waf {
        enabled true
        mode block
        
        # Exclude paths
        exclude /health
        exclude /metrics
        exclude /webhooks/github  # Example: webhook endpoint
    }
}
```

## Troubleshooting

### False Positives

If legitimate requests are blocked:

1. **Check WAF logs:**
   ```bash
   docker exec caddy tail -f /var/log/caddy/waf.log
   ```

2. **Identify the rule ID** causing the block

3. **Options:**
    - Add exception in `rules.json`
   - Lower anomaly threshold
   - Exclude specific path from WAF
   - Temporarily use `mode log` to test

### WAF Not Working

Verify WAF is enabled:

```bash
# Check environment
docker exec caddy env | grep RETALIQ_ENV

# Should show "production" for WAF to be active

# Validate Caddyfile
docker exec caddy caddy validate --config /etc/caddy/Caddyfile
```

### Performance Impact

If experiencing performance issues:

1. Adjust anomaly threshold to 1
2. Disable unused rule sets
3. Increase rate limits
4. Use `mode log` to reduce processing

## Maintenance

### Updating WAF Rules

1. Edit `waf/rules.json`
2. Restart Caddy:
   ```bash
   docker compose restart caddy
   ```

### Monitoring Security Events

Regularly review WAF logs:

```bash
# Count blocked requests today
docker exec caddy grep "$(date +%Y-%m-%d)" /var/log/caddy/waf.log | wc -l

# Top blocked IPs
docker exec caddy grep "deny" /var/log/caddy/waf.log | \
    awk '{print $1}' | sort | uniq -c | sort -rn | head -10

# Most triggered rules
docker exec caddy grep "id:" /var/log/caddy/waf.log | \
    grep -o "id:[0-9]*" | sort | uniq -c | sort -rn | head -10
```

### Updating Caddy Plugins

Rebuild the image when plugins are updated:

```bash
docker compose build --no-cache caddy
docker compose up -d caddy
```

## Production Checklist

Before deploying to production:

- [ ] Set `RETALIQ_ENV=production` in `.env`
- [ ] Configure `SSL_EMAIL_RENEWAL` for Let's Encrypt
- [ ] Review and customize WAF rules in `rules.json`
- [ ] Set appropriate anomaly threshold (start with 2)
- [ ] Test WAF with legitimate traffic
- [ ] Configure IP whitelists if needed
- [ ] Set up log monitoring/alerting
- [ ] Test all application endpoints
- [ ] Verify rate limits are appropriate
- [ ] Configure backup and restore for certificates

## References

- [Caddy Documentation](https://caddyserver.com/docs/)
- [caddy-waf](https://github.com/fabriziosalmi/caddy-waf)
- [caddy-waf repository](https://github.com/fabriziosalmi/caddy-waf)
- [caddy-waf Rules Format](https://github.com/fabriziosalmi/caddy-waf/blob/main/docs/rules.md)
- [OWASP Core Rule Set](https://coreruleset.org/)
- [OWASP WAF Best Practices](https://owasp.org/www-community/Web_Application_Firewall)

## Support

For issues or questions:

1. Check Caddy logs: `docker compose logs caddy`
2. Verify configuration: `docker exec caddy caddy validate --config /etc/caddy/Caddyfile`
3. Review WAF logs: `docker exec caddy tail -f /var/log/caddy/waf.log`
4. Test in development mode first
5. Consult [Caddy Community Forums](https://caddy.community/)
