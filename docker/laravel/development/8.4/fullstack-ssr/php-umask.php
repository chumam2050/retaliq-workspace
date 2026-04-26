<?php

// Only applies to CLI (php artisan, etc).
// PHP-FPM (fpm-fcgi) is intentionally excluded — its umask is controlled by the pool config.
if (PHP_SAPI === 'cli') {
    umask(0002);
}
