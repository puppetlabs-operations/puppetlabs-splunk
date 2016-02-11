# Class: splunk
# ===========================
#
# Full description of class splunk here.
#
# Parameters
# ----------
#
# * `sample parameter`
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
class splunk (
  $package_name = $::splunk::params::package_name,
  $service_name = $::splunk::params::service_name,
) inherits ::splunk::params {

  # validate parameters here

  class { '::splunk::install': } ->
  class { '::splunk::config': } ~>
  class { '::splunk::service': } ->
  Class['::splunk']
}
