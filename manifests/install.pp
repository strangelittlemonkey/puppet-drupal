# == Class: drupal::install
#
# Install all requirements of the Drupal module.
#
# === Authors
#
# Martin Meinhold <Martin.Meinhold@gmx.de>
#
# === Copyright
#
# Copyright 2014 Martin Meinhold, unless otherwise noted.
#
class drupal::install inherits drupal {

  $composer_install_dir = dirname($drupal::composer_path)
  $drush_archive = "drush-${drupal::drush_version}"
  $drush_download_url = "https://github.com/drush-ops/drush/archive/${drupal::drush_version}.tar.gz"
  $drush_install_dir = "${drupal::install_dir}/${drush_archive}"

  file { $drupal::install_dir:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  }

  file { $drupal::config_dir:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  }

  file { $drupal::log_dir:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  }

  exec { 'install-composer':
    command => "curl -sS ${drupal::composer_installer_url} | php -d suhosin.executor.include.whitelist=phar -- --install-dir=${composer_install_dir} --filename=`basename ${drupal::composer_path}`",
    creates => $drupal::composer_path,
    path    => $drupal::exec_paths,
    require => [
      Package[$drupal::curl_package_name],
      Package[$drupal::php_cli_package_name],
    ],
  }

  archive { $drush_archive:
    ensure           => present,
    url              => $drush_download_url,
    digest_string    => $drupal::drush_archive_md5sum,
    target           => $drupal::install_dir,
    src_target       => $drupal::cache_dir,
    timeout          => 60,
    follow_redirects => true,
    require          => [
      File[$drupal::install_dir],
      File[$drupal::cache_dir]
    ],
  }

  exec { 'install-drush-dependencies':
    command     => "${drupal::composer_path} --working-dir=${drush_install_dir} install",
    creates     => "${drush_install_dir}/vendor",
    environment => "HOME=${::root_home}",
    require     => [
      Archive[$drush_archive],
      Exec['install-composer'],
    ],
  }

  file { $drupal::drush_path:
    ensure  => link,
    target  => "${drush_install_dir}/drush",
    require => Exec['install-drush-dependencies'],
  }
}
