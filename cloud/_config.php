<?php
$CONFIG = array (
  'htaccess.RewriteBase' => '${HERMES_CLOUD_BASEPATH}',
  'overwrite.cli.url' => 'https://${HERMES_HOSTNAME}${HERMES_CLOUD_BASEPATH}',
  'overwritehost' => '${HERMES_HOSTNAME}',
  'overwriteprotocol' => 'https',
  'overwritewebroot' => '${HERMES_CLOUD_BASEPATH}',
  'memcache.local' => '\OC\Memcache\APCu',
  'memcache.distributed' => '\OC\Memcache\Redis',
  'memcache.locking' => '\OC\Memcache\Redis',
  'redis' => [
     'host' => '${HERMES_CLOUD_DB_REDIS}',
     'port' => 6379,
  ],
  'trusted_proxies' =>
  array (
    0 => '${HERMES_INGRESS_SUBNET}',
  ),
  'apps_paths' =>
  array (
    0 =>
    array (
      'path' => '/var/www/html/apps',
      'url' => '/apps',
      'writable' => false,
    ),
    1 =>
    array (
      'path' => '/var/www/html/custom_apps',
      'url' => '/custom_apps',
      'writable' => true,
    ),
  ),
);
