<?php
// Allow self-signed certificates for SMTP
$config['smtp_conn_options'] = [
    'ssl' => [
        'verify_peer' => false,
        'verify_peer_name' => false,
        'allow_self_signed' => true,
    ],
];
// Allow self-signed certificates for IMAP
$config['imap_conn_options'] = [
    'ssl' => [
        'verify_peer' => false,
        'verify_peer_name' => false,
        'allow_self_signed' => true,
    ],
];
$config["smtp_debug"] = false;
$config["imap_debug"] = false;
$config['session_domain'] = getenv('ROUNDCUBE_SESSION_DOMAIN') ?? 'webmail.retaliq.cloud';
$config['session_same_site'] = getenv('ROUNDCUBE_SESSION_SAME_SITE') ?? 'Lax';
$config['username_domain'] = getenv('ROUNDCUBE_USERNAME_DOMAIN') ?? 'retaliq.cloud';
$config['mail_domain'] = getenv('ROUNDCUBE_USERNAME_DOMAIN') ?? 'retaliq.cloud';
$config['use_https'] = true;
$config['force_https'] = true;
