# Class: composer
#
# Installs Composer
class composer (
    $install_location = '/usr/bin',
    $filename         = 'composer'
) {
  $composer_location = $install_location
  $composer_filename = $filename

  exec { "composer-${install_location}":
    command => "curl -sS https://getcomposer.org/installer | php -- --install-dir=/tmp && mv /tmp/composer.phar ${install_location}/${filename}",
    path    => ['/usr/bin' , '/bin'],
  }
}
