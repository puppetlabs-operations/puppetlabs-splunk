# == Class splunk::params
#
# This class is meant to be called from splunk.
# It sets variables according to platform.
#
class splunk::params {
  case $::osfamily {
    'Debian': {
      $package_name = 'splunk'
      $service_name = 'splunk'
    }
    'RedHat', 'Amazon': {
      $package_name = 'splunk'
      $service_name = 'splunk'
    }
    default: {
      fail("${::operatingsystem} not supported")
    }
  }
}
