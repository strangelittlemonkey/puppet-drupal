# Define: drupal::site
#
# Manage a Drupal site.
#
# === Parameters
#
# [*core_version*]
#   Set the version of the Drupal core to be installed.
#
# [*modules*]
#   Set modules to be installed along with the core (optional). See the README file for examples.
#
# [*themes*]
#   Set themes to be installed along with the core (optional). See the README file for examples.
#
# [*libraries*]
#   Set libraries to be installed (optional). See the README file for examples.
#
# [*makefile_content*]
#   Set content of the makefile to be used (optional). Other parameters used to generate a makefile (`core_version`,
#   `modules` and `themes`) are ignored when this one is used..
#
# [*document_root*]
#   Set the path to the document root. This will result in a symbolic link pointing to a directory containing all
#   modules and themes as configured.
#
# [*timeout*]
#   Set the timeout in seconds of the rebuild site command.
#
# === Authors
#
# Martin Meinhold <Martin.Meinhold@gmx.de>
#
# === Copyright
#
# Copyright 2014 Martin Meinhold, unless otherwise noted.
#
define drupal::site (
  $core_version     = undef,
  $modules          = {},
  $themes           = {},
  $libraries        = {},
  $makefile_content = undef,
  $document_root    = undef,
  $timeout          = undef,
) {

  require drupal

  $real_document_root = pick($document_root, "${drupal::www_dir}/${title}")
  validate_absolute_path($real_document_root)

  if empty($makefile_content) {
    $core_major_version = regsubst($core_version, '(\d+).(\d+)$', '\1', 'I')
    $real_makefile_content = template('drupal/drush.make.erb')
  }
  else {
    $real_makefile_content = $makefile_content
  }

  $makefile_md5 = md5($real_makefile_content)
  $config_file = "${drupal::config_dir}/${title}.make"
  $site_file = "${drupal::install_dir}/${title}-${makefile_md5}"
  $now = time()
  $temp_file = "/tmp/drush-${title}-${now}"


  file { $config_file:
    ensure  => file,
    content => $real_makefile_content,
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    notify  => Exec["rebuild-drupal-${title}"],
  }

  exec { "rebuild-drupal-${title}":
    command => "${drupal::drush_executable} make -v ${config_file} ${temp_file} >> ${drupal::log_dir}/${title}.log 2>&1 || rm -rf ${temp_file} && exit 99",
    creates => $site_file,
    timeout => $timeout,
    path    => $drupal::exec_paths,
    require => File[$drupal::drush_executable],
  }

  exec { "move-temporary-drupal-${title}":
    command => "mv ${temp_file} ${site_file}",
    creates => $site_file,
    path    => $drupal::exec_paths,
    require => Exec["rebuild-drupal-${title}"],
  }

  file { $real_document_root:
    ensure => link,
    target => $site_file,
  }
}
