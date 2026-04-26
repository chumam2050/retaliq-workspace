# PHP Production Security Hardening

This document outlines the security hardening measures implemented for the production PHP/Laravel environment.

## PHP Configuration Hardening (php.ini)

### Disabled Dangerous Functions
The following potentially dangerous PHP functions are disabled:
- `exec`, `passthru`, `shell_exec`, `system` - Command execution
- `proc_open`, `popen` - Process control
- `curl_exec`, `curl_multi_exec` - External requests (if not needed)
- `parse_ini_file` - Configuration file parsing
- `show_source`, `phpinfo` - Information disclosure

**Note**: If your application requires any of these functions (e.g., for Laravel queue workers or specific features), remove them from the `disable_functions` list.

### File Access Restrictions
- `open_basedir = /var/www/html:/tmp` - Restricts PHP file operations to the application directory and temp folder
- Prevents path traversal attacks outside the application

### Session Security
- `session.cookie_httponly = On` - Prevents JavaScript access to session cookies
- `session.cookie_secure = On` - Only transmit cookies over HTTPS
- `session.cookie_samesite = Strict` - Prevents CSRF attacks
- `session.use_strict_mode = On` - Rejects uninitialized session IDs
- `session.sid_length = 48` - Increased session ID length
- `session.use_only_cookies = On` - Session ID only in cookies
- `session.use_trans_sid = Off` - No session ID in URLs

### File Upload Security
- `upload_tmp_dir = /tmp` - Dedicated temporary directory
- `max_file_uploads = 20` - Limits number of simultaneous uploads
- Combined with `upload_max_filesize = 20M` and `post_max_size = 20M`

### Additional Hardening
- `expose_php = Off` - Hides PHP version
- `allow_url_include = Off` - Prevents remote file inclusion
- `enable_dl = Off` - Disables dynamic loading of PHP extensions
- `html_errors = Off` - Prevents HTML in error messages
- `zend.assertions = -1` - Disables assertions in production

## OPcache Security (opcache.ini)

### Permission Validation
- `opcache.validate_permission = 1` - Validates file permissions
- `opcache.validate_root = 1` - Validates file ownership
- `opcache.file_cache_fallback = 0` - Prevents caching files with issues

### Performance Optimizations
- `opcache.validate_timestamps = 0` - No timestamp checking (requires restart for code changes)
- `opcache.max_accelerated_files = 20000` - Supports large applications
- `opcache.jit = tracing` - JIT compilation for PHP 8+

## Nginx Security Hardening

### Security Headers
- `X-Frame-Options: SAMEORIGIN` - Prevents clickjacking
- `X-Content-Type-Options: nosniff` - Prevents MIME sniffing
- `X-XSS-Protection: 1; mode=block` - Enables XSS filtering
- `Referrer-Policy: strict-origin-when-cross-origin` - Controls referrer information
- `Permissions-Policy` - Restricts browser features (geolocation, camera, microphone)
- `Strict-Transport-Security` - Forces HTTPS (31536000 seconds = 1 year)

### Rate Limiting
Three rate limiting zones are configured:
1. **General zone**: 10 requests/second, burst 20
   - Applied to all routes
2. **API zone**: 30 requests/second, burst 50
   - Applied to `/api/*` routes
3. **Connection limit**: 10 concurrent connections per IP (general), 20 for API

Rate limit exceeded responses return HTTP 429 (Too Many Requests).

### PHP Execution Protection
- `try_files $uri =404` - Prevents PHP execution of non-existent files
- Only files that exist can be executed, preventing attacks

### Directory and File Access Restrictions
Protected paths (return 404):
- `/storage/*` - Uploaded files and logs
- `/bootstrap/*` - Bootstrap cache
- `/config/*`, `/database/*`, `/routes/*` - Application structure
- `/vendor/*` - Composer dependencies
- `.env*` files - Environment configuration
- `composer.json`, `composer.lock` - Dependency definitions
- `.git*` - Version control
- `artisan` - Laravel CLI tool

### FastCGI Security
- `fastcgi_param PHP_VALUE "open_basedir=/var/www/html:/tmp"` - Reinforces PHP open_basedir
- `fastcgi_intercept_errors on` - Better error handling
- `fastcgi_hide_header X-Powered-By` - Hides PHP version

## Entrypoint Security (entrypoint.sh)

### File Permissions
- Storage directories: 775 (read/write/execute for owner and group)
- `.env` file: 640 (read/write for owner, read for group)
- Application directories (app, config, database, routes): 750 (execute restricted)

### User Security
- All application processes run as `www-data` user (non-root)
- Supervisor runs as root but spawns child processes as `www-data`

## Best Practices

### 1. HTTPS Configuration
The security headers include HSTS, but ensure you're running behind a reverse proxy (like Caddy) that:
- Terminates SSL/TLS
- Redirects HTTP to HTTPS
- Uses valid SSL certificates

### 2. Environment Variables
Keep sensitive data in `.env` file:
- Database credentials
- API keys
- Encryption keys
- Never commit `.env` to version control

### 3. Regular Updates
- Update PHP and Alpine packages regularly
- Monitor security advisories
- Rebuild images when security patches are released

### 4. Disable Development Features
Ensure in production `.env`:
```env
APP_DEBUG=false
APP_ENV=production
```

### 5. Laravel Specific
- Run `php artisan config:cache` to cache configuration
- Run `php artisan route:cache` to cache routes
- Run `php artisan view:cache` to cache views
- These are already in the entrypoint.sh

### 6. Monitoring
- Review `/var/log/php_errors.log` regularly
- Monitor Nginx access and error logs
- Set up log aggregation (ELK, Loki, etc.)

### 7. Database Security
- Use parameterized queries (Laravel Eloquent does this)
- Limit database user permissions
- Use separate database users for different environments

### 8. Additional Considerations
- Implement CSRF protection (Laravel provides this)
- Validate and sanitize all input
- Use Laravel's built-in authentication
- Enable SQL injection protection via PDO prepared statements

## Testing the Hardening

### 1. Check disabled functions:
```bash
docker exec <container> php -r "echo ini_get('disable_functions');"
```

### 2. Test rate limiting:
```bash
# Should get 429 after exceeding limits
for i in {1..100}; do curl http://your-domain/; done
```

### 3. Test directory protection:
```bash
# Should return 404
curl http://your-domain/composer.json
curl http://your-domain/storage/logs/laravel.log
curl http://your-domain/.env
```

### 4. Check security headers:
```bash
curl -I http://your-domain/
```

### 5. Verify OPcache:
```bash
docker exec <container> php -r "print_r(opcache_get_status());"
```

## Deployment Checklist

- [ ] Review disabled functions and ensure your app doesn't require them
- [ ] Update `APP_ENV=production` and `APP_DEBUG=false` in `.env`
- [ ] Configure SSL/TLS on reverse proxy
- [ ] Set strong `APP_KEY` in `.env`
- [ ] Review rate limiting thresholds for your traffic
- [ ] Set up log monitoring and alerting
- [ ] Configure database with least-privilege user
- [ ] Test all security headers are present
- [ ] Verify file permissions after deployment
- [ ] Test that sensitive files return 404
- [ ] Document any custom security configurations

## Maintenance

### Code Updates
Since `opcache.validate_timestamps = 0`, you must restart PHP-FPM after code changes:
```bash
docker compose restart app
```

### Cache Clearing
If you need to clear caches:
```bash
docker exec <container> php artisan cache:clear
docker exec <container> php artisan config:clear
docker exec <container> php artisan route:clear
docker exec <container> php artisan view:clear
```

### Security Audit
Run regular security audits:
```bash
# Check for vulnerable dependencies
docker exec <container> composer audit
```

## Troubleshooting

### Application errors after hardening
1. Check disabled functions - your app might need one
2. Review open_basedir restrictions
3. Check file permissions
4. Review rate limiting logs

### Performance issues
1. Increase OPcache memory if needed
2. Adjust rate limiting thresholds
3. Monitor PHP-FPM pool settings
4. Check FastCGI buffer sizes

## References
- [OWASP PHP Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/PHP_Configuration_Cheat_Sheet.html)
- [Laravel Security Best Practices](https://laravel.com/docs/security)
- [Nginx Security Headers](https://securityheaders.com/)