# == Class splunk::service
#
# This class is meant to be called from splunk.
# It ensure the service is running.
#
class splunk::service {

  service { $::splunk::service_name:
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
  }
}
