require 'spec_helper_acceptance'
shared_examples_for "default splunk settings" do
  describe user('splunkuser') do
      it { should exist }
  end

end

shared_examples_for "a running splunk service" do
  describe package('splunk') do
    it { is_expected.to be_installed }
  end

  describe service('splunk') do
    it { is_expected.to be_enabled }
    it { is_expected.to be_running }
  end

  # http port
  describe port(8000) do
    it { is_expected.to be_listening }
  end

  # management port
  describe port(8089) do
    it { is_expected.to be_listening }
  end

  # app server port
  describe port(8065) do
    it { is_expected.to be_listening }
  end

  # kvstore port
  describe port(8191) do
    it { is_expected.to be_listening }
  end
end

shared_examples_for "splunk self-tests" do
  describe command('/opt/splunk/bin/splunk status') do
    its(:exit_status) { should eq 0 }
    its(:stdout) { is_expected.to match /All preliminary checks passed./ }
    its(:stderr) { is_expected.to_not match /splunkd is not running./ }
    its(:stderr) { is_expected.to_not match /was not running./ }
  end
end

describe 'splunk class' do

  context 'default parameters' do
    # Using puppet_apply as a helper
    it 'should work idempotently with no errors' do
      pp = <<-EOS
      class { 'splunk': }

      # wait for splunk to finish starting before we run tests
      exec {'/opt/splunk/bin/splunk status':
        try_sleep => '.5', # sleep .5 seconds between tries until it passes
        tries     => 60,
        require   => Class['splunk'],
        # the unless is to avoid running this when the manifest is applied
        # a second time, which would fail the idempotency check.
        unless    => '/opt/splunk/bin/splunk status',
      }
      EOS

      # Run it twice and test for idempotency
      apply_manifest(pp, :catch_failures => true)
      apply_manifest(pp, :catch_changes  => true)
    end

    it_behaves_like "a running splunk service"
    it_behaves_like "splunk self-tests"

    # this basically just tests that splunk got installed at all
    # we need to add some more thoughtful tests here
    describe file('/opt/splunk/etc/instance.cfg') do
      its(:content) { should contain /guid/ }
    end
    # this basically just tests that splunk got installed at all
    # we need to add some more thoughtful tests here
    describe file('/opt/splunk/etc/splunk-launch.conf') do
      its(:content) { should contain /SPLUNK_SERVER_NAME=Splunkd/ }
    end
    # an init script should be created
    describe file('/etc/init.d/splunk') do
      its(:content) { should contain /splunk_start/ }
    end
  end

  context 'with config parameters set' do
    # Using puppet_apply as a helper
    it 'should work idempotently with no errors' do
      pp = <<-EOS
      class { '::splunk':
        package_name   => 'splunk',
        service_name   => 'splunk',
        manage_package => true,
        manage_repo    => true,
        version        => 'latest',
        settings       => {
          'log.syslog'                              => 'on',
          'erlang.schedulers.force_wakeup_interval' => '500',
          'erlang.schedulers.compaction_of_load'    => false,
          'buckets.default.last_write_wins'         => true,
        },
      }

      # wait for splunk to finish starting before we run tests
      exec {'/usr/sbin/splunk-admin test':
        try_sleep => '.5', # sleep .5 seconds between tries until it passes
        tries     => 60,
        require   => Class['splunk'],
        # the unless is to avoid running this when the manifest is applied
        # a second time, which would fail the idempotency check.
        unless    => '/usr/sbin/splunk-admin test',
      }
      EOS

      # Run it twice and test for idempotency
      apply_manifest(pp, :catch_failures => true)
      apply_manifest(pp, :catch_changes  => true)
    end

    it_behaves_like "a running splunk service"
    it_behaves_like "splunk self-tests"
    describe file('/etc/splunk/splunk.conf') do
      its(:content) { should match /log\.syslog = on/ } # custom setting
      its(:content) { should match /erlang\.schedulers\.force_wakeup_interval = 500/ } # custom setting
      its(:content) { should match /buckets.default.last_write_wins = true/ } # custom setting
      its(:content) { should match /log.crash.size = 10MB/ } # expected default setting
    end
  end
end
