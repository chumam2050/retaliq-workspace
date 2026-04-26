<?php
  $config['db_dsnw'] = 'pgsql://app_user:password@postgres:5432/roundcubemail';
  $config['db_dsnr'] = '';
  $config['imap_host'] = 'ssl://stalwart:993';
  $config['smtp_host'] = 'ssl://stalwart:465';
  $config['username_domain'] = 'retaliq.test';
  $config['temp_dir'] = '/tmp/roundcube-temp';
  $config['skin'] = 'elastic';
  $config['request_path'] = '/';
  $config['plugins'] = array_filter(array_unique(array_merge($config['plugins'], ['archive', 'zipdownload'])));
  
include('/var/roundcube/config/custom.php');
