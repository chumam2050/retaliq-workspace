# Caddy WAF Setup - Quick Start Guide

## What Was Added

✅ **Custom Caddy build** with caddy-waf plugin (production-grade WAF)
✅ **Environment-based configuration** (development vs production)
✅ **Complete WAF rules** with OWASP protection
✅ **Management script** for easy WAF administration
✅ **Comprehensive documentation**

## Files Created/Modified

### New Files
- `Caddyfile.production` - Production config with WAF enabled
- `Caddyfile.development` - Development config with WAF + local certs
- `docker-entrypoint.sh` - Auto-selects Caddyfile based on env
- `waf/rules.json` - Custom WAF security rules
- `waf-manage.sh` - WAF management script
- `README.md` - Detailed documentation

### Modified Files
- `Dockerfile` - Now builds Caddy with caddy-waf + Cloudflare DNS
- `../compose.yml` - Updated to build custom image and mount configs

## How It Works

### Development Mode
```bash
RETALIQ_ENV=development  # in /services/.env
```
- Uses `Caddyfile.development`
- WAF is **ENABLED** with caddy-waf
- Local TLS certificates (*.retaliq.test)
- Security headers enabled
- Auto HTTPS OFF
- Perfect for local testing with full WAF protection

### Production Mode
```bash
RETALIQ_ENV=production  # in /services/.env
```
- Uses `Caddyfile.production`
- WAF is **ENABLED** with caddy-waf
- Automatic HTTPS with Let's Encrypt
- Security headers enabled
- Rate limiting active

## Quick Commands

```bash
# Check WAF status
./caddy/waf-manage.sh status

# Switch to production mode
./caddy/waf-manage.sh switch production

# Switch back to development
./caddy/waf-manage.sh switch development

# View WAF logs
./caddy/waf-manage.sh logs

# Show WAF statistics
./caddy/waf-manage.sh stats

# Test WAF protection
./caddy/waf-manage.sh test

# Reload configuration
./caddy/waf-manage.sh reload

# Add IP to whitelist
./caddy/waf-manage.sh whitelist 203.0.113.5

# Show all commands
./caddy/waf-manage.sh help
```

## WAF Protection (Production Only)

When enabled, the WAF protects against:

- ✅ SQL Injection (SQLi)
- ✅ Cross-Site Scripting (XSS)
- ✅ Remote Code Execution (RCE)
- ✅ Local File Inclusion (LFI)
- ✅ Path Traversal
- ✅ Security Scanner Detection
- ✅ Shellshock Attacks
- ✅ XXE (XML External Entity)
- ✅ SSRF (Server-Side Request Forgery)
- ✅ Malicious File Uploads
- ✅ Rate Limiting (Login: 10/min, API: 300/min)

## Deployment Steps

### Currently Building
The custom Caddy image with WAF is building now. To deploy:

1. **Wait for build to complete**:
   ```bash
   docker compose ps caddy  # Check if build finished
   ```

2. **Start Caddy** (development mode with WAF):
   ```bash
   docker compose up -d caddy
   ```

3. **Verify** it's working:
   ```bash
   ./caddy/waf-manage.sh status
   ```

4. **Test WAF protection** (works in both development and production):
   ```bash
   # Test WAF
   ./caddy/waf-manage.sh test
   ```

5. **When ready for production**, update `.env`:
   ```bash
   # Edit /services/.env
   RETALIQ_ENV=production
   
   # Restart Caddy
   docker compose restart caddy
   ```

## Configuration Files

### Caddyfile.development
- caddy-waf enabled
- Local TLS (self-signed certs)
- Suitable for *.test domains
- Auto HTTPS disabled
- Full security testing locally

### Caddyfile.production
- caddy-waf enabled
- Let's Encrypt automatic certificates
- Strong security headers
- Rate limiting per-endpoint
- Production TLS (TLS 1.2+)

### waf/rules.json
- JSON rules format
- Custom attack detection rules
- Rate limiting rules
- IP whitelist/blacklist (commented out)
- App-specific exclusions

## Security Headers (Production)

Automatically applied:
- `Strict-Transport-Security` - Force HTTPS
- `X-Content-Type-Options` - No MIME sniffing
- `X-Frame-Options` - Clickjacking protection
- `X-XSS-Protection` - XSS filter
- `Referrer-Policy` - Referrer control
- `Permissions-Policy` - Browser features
- `Content-Security-Policy` - XSS protection

## Testing WAF

After switching to production:

```bash
# Normal request (should work)
curl https://your-domain.com/

# SQL injection (should be blocked - 403)
curl "https://your-domain.com/?id=1' OR '1'='1"

# XSS (should be blocked - 403)
curl "https://your-domain.com/?search=<script>alert('xss')</script>"

# Path traversal (should be blocked - 403)
curl "https://your-domain.com/../../etc/passwd"

# Check WAF logs
./caddy/waf-manage.sh logs
```

## Customization

### Adjust anomaly threshold
Edit `Caddyfile.production`, change anomaly_threshold (1-4):
```caddyfile
SecAction \
    "id:900000,\
    phase:1,\
    nolog,\
    pass,\
    setvar:tx.anomaly_threshold=2"  # Change this
```

Level 1 = Basic protection  
Level 2 = Moderate (recommended)  
Level 3 = Strong (may need tuning)  
Level 4 = Maximum (expect false positives)

### Add IP Whitelist
Edit `waf/rules.json`, uncomment and modify:
```conf
SecRule REMOTE_ADDR "@ipMatch 203.0.113.0/24" \
    "id:5002,\
    phase:1,\
    pass,\
    nolog,\
    ctl:ruleEngine=Off"
```

Or use the management script:
```bash
./caddy/waf-manage.sh whitelist 203.0.113.5
docker compose restart caddy
```

### Exclude Path from WAF
Edit `Caddyfile.production`, add to `(waf)` snippet:
```caddyfile
(waf) {
    waf {
        # ... existing config ...
        exclude /webhooks/stripe
        exclude /api/public/status
    }
}
```

## Monitoring

### View Logs
```bash
# Caddy general logs
docker compose logs -f caddy

# WAF-specific (production)
docker exec caddy tail -f /var/log/caddy/waf.log

# Caddy access logs
docker exec caddy tail -f /var/log/caddy/access.log
```

### Statistics
```bash
# Full stats
./caddy/waf-manage.sh stats

# Quick count of blocks today
docker exec caddy grep "$(date +%Y-%m-%d)" /var/log/caddy/waf.log | grep -c "deny"
```

## Troubleshooting

### Build Failed
```bash
# Check build logs
docker compose build caddy 2>&1 | tee build.log

# Try with cache
docker compose build caddy
```

### Legitimate Requests Blocked
1. Check WAF logs for the rule ID
2. Either:
   - Lower anomaly threshold
   - Exclude the specific path
   - Add exception in rules.json
   - Whitelist the IP

### WAF Not Working
```bash
# Verify you're in production mode
grep RETALIQ_ENV /services/.env

# Check Caddyfile
docker exec caddy cat /etc/caddy/Caddyfile | head -20

# Validate config
docker exec caddy caddy validate --config /etc/caddy/Caddyfile
```

## Support & Documentation

- Full docs: `caddy/README.md`
- caddy-waf: https://github.com/fabriziosalmi/caddy-waf
- Caddy docs: https://caddyserver.com/docs/
- OWASP CRS: https://coreruleset.org/

## What is caddy-waf?

caddy-waf is an open-source WAF middleware for Caddy that:
- ✅ Uses JSON rules format and supports OWASP-inspired protections
- ✅ Written in Go (fast, efficient)
- ✅ Native Caddy integration
- ✅ Actively maintained
- ✅ Production-ready
- ✅ Used by major companies

## Next Steps

1. Wait for Docker build to complete
2. Test in development mode first
3. Review and customize WAF rules for your app
4. Test all endpoints work correctly
5. Switch to production when ready
6. Monitor WAF logs regularly
7. Tune rules based on false positives

## Production Checklist

Before going live:

- [ ] Build completed successfully
- [ ] Tested in development mode
- [ ] Reviewed custom WAF rules
- [ ] Set `SSL_EMAIL_RENEWAL` in `.env`
- [ ] Set `RETALIQ_ENV=production`
- [ ] Tested all application endpoints
- [ ] Verified rate limits are appropriate
- [ ] Set up log monitoring
- [ ] Configured IP whitelists (if needed)
- [ ] Tested WAF blocking works
- [ ] Documented any custom rules
- [ ] Backup plan if issues occur
