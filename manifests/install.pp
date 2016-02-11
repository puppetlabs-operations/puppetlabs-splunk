# == Class splunk::install
#
# This class is called from splunk for install.
#
class splunk::install {

  package { $::splunk::package_name:
    ensure => present,
  }
}
