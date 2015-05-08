require 'spec_helper'

describe 'puppet::agent', :type => :class do
  context 'on Debian operatingsystems' do
    let(:facts) do
      {
        :osfamily        => 'Debian',
        :operatingsystem => 'Debian',
        :kernel          => 'Linux'
      }
    end

    describe 'when installed as' do
      context 'a service' do
        let(:params) do
          {
            :puppet_server          => 'test.exaple.com',
            :puppet_agent_service   => 'puppet',
            :puppet_agent_package   => 'puppet',
            :version                => '/etc/puppet/manifests/site.pp',
            :puppet_run_style       => 'service',
            :splay                  => 'true',
            :environment            => 'production',
            :puppet_run_interval    => 30,
            :puppet_server_port     => 8140,
          }
        end
        it {
          should contain_file('/etc/default/puppet').with(
            :mode     => '0644',
            :owner    => 'root',
            :group    => 'root',
            :content  => /START=yes/,
            :require  => "Package[#{params[:puppet_agent_package]}]"
          )
          should contain_service(params[:puppet_agent_service]).with(
            :ensure  => 'running',
            :enable  => true,
            :require => "Package[#{params[:puppet_agent_package]}]"
          )
        }
      end
      context 'using cron' do
        let(:params) do
          {
            :puppet_server          => 'test.exaple.com',
            :puppet_agent_service   => 'puppet',
            :puppet_agent_package   => 'puppet',
            :version                => '/etc/puppet/manifests/site.pp',
            :puppet_run_style       => 'cron',
            :splay                  => 'true',
            :environment            => 'production',
            :puppet_server_port     => 8140,
            :cron_hour              => 5,
            :cron_minute            => '*/30',
          }
        end
        it{
          should contain_file('/etc/default/puppet').with(
            :mode     => '0644',
            :owner    => 'root',
            :group    => 'root',
            :content  => /START=no/,
            :require  => "Package[#{params[:puppet_agent_package]}]"
          )
          should contain_service(params[:puppet_agent_service]).with(
            :ensure  => 'stopped',
            :enable  => false,
            :require => "Package[#{params[:puppet_agent_package]}]"
          )
          should contain_cron('puppet-client').with(
            :command  => '/usr/bin/puppet agent --no-daemonize --onetime --logdest syslog > /dev/null 2>&1',
            :user     => 'root',
            :hour     => '5',
            :minute   => '*/30'
          )
        }
      end
    end

    describe 'on Debian with splay and splaylimit' do
      context 'with splaylimit but no splay set' do
        let(:params) do
          {
            :puppet_server          => 'test.exaple.com',
            :puppet_agent_service   => 'puppet',
            :puppet_agent_package   => 'puppet',
            :version                => '/etc/puppet/manifests/site.pp',
            :puppet_run_style       => 'cron',
            :splay                  => false,
            :splaylimit             => '300s',
            :environment            => 'production',
            :puppet_run_interval    => 30,
            :puppet_server_port     => 8140,
            :use_srv_records        => true,
          }
        end

        it {
          should compile.and_raise_error(/puppet has attribute splaylimit set but has splay unset/)
        }
      end
      context 'on Debian with splaylimit and splay set' do
        let(:params) do
          {
            :puppet_server          => 'test.exaple.com',
            :puppet_agent_service   => 'puppet',
            :puppet_agent_package   => 'puppet',
            :version                => '/etc/puppet/manifests/site.pp',
            :puppet_run_style       => 'cron',
            :splay                  => 'true',
            :splaylimit             => '300s',
            :environment            => 'production',
            :puppet_run_interval    => 30,
            :puppet_server_port     => 8140,
            :srv_domain             => 'example.com',
          }
        end

        it{
          should contain_ini_setting('puppetagentsplay').with(
            :ensure  => 'present',
            :section => 'agent',
            :setting => 'splay',
            :path    => '/etc/puppet/puppet.conf',
            :value   => 'true'
          )
          should contain_ini_setting('puppetagentsplaylimit').with(
            :ensure  => 'present',
            :section => 'agent',
            :setting => 'splaylimit',
            :path    => '/etc/puppet/puppet.conf',
            :value   => '300s'
          )
        }
      end
    end

    describe 'srv records on Debian' do
      context 'fail on Debian with use_srv_records but no srv_domain set' do
        let(:params) do
          {
            :puppet_server          => 'test.exaple.com',
            :puppet_agent_service   => 'puppet',
            :puppet_agent_package   => 'puppet',
            :version                => '/etc/puppet/manifests/site.pp',
            :puppet_run_style       => 'cron',
            :splay                  => 'true',
            :environment            => 'production',
            :puppet_run_interval    => 30,
            :puppet_server_port     => 8140,
            :use_srv_records        => true,
          }
        end

        it {
          should compile.and_raise_error(/puppet has attribute use_srv_records set but has srv_domain unset/)
        }
      end

      context 'on Debian with use_srv_records false' do
        let(:params) do
          {
            :puppet_server          => 'test.exaple.com',
            :puppet_agent_service   => 'puppet',
            :puppet_agent_package   => 'puppet',
            :version                => '/etc/puppet/manifests/site.pp',
            :puppet_run_style       => 'cron',
            :splay                  => 'true',
            :environment            => 'production',
            :puppet_run_interval    => 30,
            :puppet_server_port     => 8140,
            :use_srv_records        => false,
          }
        end

        it{
          should contain_ini_setting('puppetagentsrv_domain').with(
            :ensure  => 'absent',
            :section => 'agent',
            :setting => 'srv_domain',
            :path    => '/etc/puppet/puppet.conf'
          )
        }
      end

      context 'on Debian with use_srv_records and srv_domain set' do
        let(:params) do
          {
            :puppet_server          => 'test.exaple.com',
            :puppet_agent_service   => 'puppet',
            :puppet_agent_package   => 'puppet',
            :version                => '/etc/puppet/manifests/site.pp',
            :puppet_run_style       => 'cron',
            :splay                  => 'true',
            :environment            => 'production',
            :puppet_run_interval    => 30,
            :puppet_server_port     => 8140,
            :use_srv_records        => true,
            :srv_domain             => 'example.com',
          }
        end

        it{
          should contain_ini_setting('puppetagentuse_srv_records').with(
            :ensure  => 'present',
            :section => 'agent',
            :setting => 'use_srv_records',
            :path    => '/etc/puppet/puppet.conf',
            :value   => 'true'
          )
          should contain_ini_setting('puppetagentsrv_domain').with(
            :ensure  => 'present',
            :section => 'agent',
            :setting => 'srv_domain',
            :path    => '/etc/puppet/puppet.conf',
            :value   => params[:srv_domain]
          )
        }
      end
    end
  end
  context 'on RedHat operatingsystems' do
    let(:facts) do
      {
        :osfamily        => 'RedHat',
        :operatingsystem => 'RedHat',
        :kernel          => 'Linux'
      }
    end
    describe 'when installed' do
      context 'as a service' do
        let(:params) do
          {
            :puppet_server          => 'test.exaple.com',
            :puppet_agent_service   => 'puppet',
            :puppet_agent_package   => 'puppet',
            :version                => '/etc/puppet/manifests/site.pp',
            :puppet_run_style       => 'service',
            :splay                  => 'true',
            :environment            => 'production',
            :puppet_run_interval    => 30,
            :puppet_server_port     => 8140,
          }
        end
        it {
          should contain_file('/etc/sysconfig/puppet').with(
            :mode     => '0644',
            :owner    => 'root',
            :group    => 'root',
            :content  => /PUPPET_SERVER=#{params[:puppet_server]}/,
            :require  => "Package[#{params[:puppet_agent_package]}]"
          )
          should contain_service(params[:puppet_agent_service]).with(
            :ensure  => 'running',
            :enable  => true,
            :require => "Package[#{params[:puppet_agent_package]}]"
          )
        }
      end

      context 'using cron' do
        let(:params) do
          {
            :puppet_server          => 'test.exaple.com',
            :puppet_agent_service   => 'puppet',
            :puppet_agent_package   => 'puppet',
            :version                => '/etc/puppet/manifests/site.pp',
            :puppet_run_style       => 'cron',
            :splay                  => 'true',
            :environment            => 'production',
            :puppet_run_interval    => 30,
            :puppet_server_port     => 8140,
          }
        end
        it{
          should contain_file('/etc/sysconfig/puppet').with(
            :mode     => '0644',
            :owner    => 'root',
            :group    => 'root',
            :content  => /PUPPET_SERVER=#{params[:puppet_server]}/,
            :require  => "Package[#{params[:puppet_agent_package]}]"
          )
          should contain_service(params[:puppet_agent_service]).with(
            :ensure  => 'stopped',
            :enable  => false,
            :require => "Package[#{params[:puppet_agent_package]}]"
          )
          should contain_cron('puppet-client').with(
            :command  => '/usr/bin/puppet agent --no-daemonize --onetime --logdest syslog > /dev/null 2>&1',
            :user  => 'root',
            :hour => '*'
          )
        }
      end
    end

    describe 'srv records on RedHat' do
      context 'with use_srv_records but no srv_domain set' do
        let(:params) do
          {
            :puppet_server          => 'test.exaple.com',
            :puppet_agent_service   => 'puppet',
            :puppet_agent_package   => 'puppet',
            :version                => '/etc/puppet/manifests/site.pp',
            :puppet_run_style       => 'cron',
            :splay                  => 'true',
            :environment            => 'production',
            :puppet_run_interval    => 30,
            :puppet_server_port     => 8140,
            :use_srv_records        => true,
          }
        end

        it {
          should compile.and_raise_error(/puppet has attribute use_srv_records set but has srv_domain unset/)
        }
      end

      context 'with use_srv_records false' do
        let(:params) do
          {
            :puppet_server          => 'test.exaple.com',
            :puppet_agent_service   => 'puppet',
            :puppet_agent_package   => 'puppet',
            :version                => '/etc/puppet/manifests/site.pp',
            :puppet_run_style       => 'cron',
            :splay                  => 'true',
            :environment            => 'production',
            :puppet_run_interval    => 30,
            :puppet_server_port     => 8140,
            :use_srv_records        => false,
          }
        end

        it{
          should contain_ini_setting('puppetagentsrv_domain').with(
            :ensure  => 'absent',
            :section => 'agent',
            :setting => 'srv_domain',
            :path    => '/etc/puppet/puppet.conf'
          )
        }
      end

      context 'with use_srv_records and srv_domain set' do
        let(:params) do
          {
            :puppet_server          => 'test.exaple.com',
            :puppet_agent_service   => 'puppet',
            :puppet_agent_package   => 'puppet',
            :version                => '/etc/puppet/manifests/site.pp',
            :puppet_run_style       => 'cron',
            :splay                  => 'true',
            :environment            => 'production',
            :puppet_run_interval    => 30,
            :puppet_server_port     => 8140,
            :use_srv_records        => true,
            :srv_domain             => 'example.com',
          }
        end

        it{
          should contain_ini_setting('puppetagentuse_srv_records').with(
            :ensure  => 'present',
            :section => 'agent',
            :setting => 'use_srv_records',
            :path    => '/etc/puppet/puppet.conf',
            :value   => 'true'
          )
          should contain_ini_setting('puppetagentsrv_domain').with(
            :ensure  => 'present',
            :section => 'agent',
            :setting => 'srv_domain',
            :path    => '/etc/puppet/puppet.conf',
            :value   => params[:srv_domain]
          )
        }
      end
    end
  end

  describe 'Ordering' do
    let(:facts) do
      {
        :osfamily        => 'RedHat',
        :operatingsystem => 'RedHat',
        :kernel          => 'Linux'
      }
    end
    context 'with ordering set' do
      let(:params) do
        {
          :puppet_server          => 'test.exaple.com',
          :puppet_agent_service   => 'puppet',
          :puppet_agent_package   => 'puppet',
          :version                => '/etc/puppet/manifests/site.pp',
          :puppet_run_style       => 'cron',
          :splay                  => 'true',
          :environment            => 'production',
          :ordering               => 'manifest',
          :puppet_run_interval    => 30,
          :puppet_server_port     => 8140,
          :use_srv_records        => false,
        }
      end

      it{
        should contain_ini_setting('puppetagentordering').with(
          :ensure  => 'present',
          :section => 'agent',
          :setting => 'ordering',
          :value   => 'manifest',
          :path    => '/etc/puppet/puppet.conf'
        )
      }
    end

    context 'with ordering not set' do
      let(:params) do
        {
          :puppet_server          => 'test.exaple.com',
          :puppet_agent_service   => 'puppet',
          :puppet_agent_package   => 'puppet',
          :version                => '/etc/puppet/manifests/site.pp',
          :puppet_run_style       => 'cron',
          :splay                  => 'true',
          :environment            => 'production',
          :puppet_run_interval    => 30,
          :puppet_server_port     => 8140,
          :use_srv_records        => false,
        }
      end

      it{
        should contain_ini_setting('puppetagentordering').with(
          :ensure  => 'absent',
          :section => 'agent',
          :setting => 'ordering',
          :path    => '/etc/puppet/puppet.conf'
        )
      }
    end
  end
  describe 'Trusted fact' do
    let(:facts) do
      {
        :osfamily        => 'RedHat',
        :operatingsystem => 'RedHat',
        :kernel          => 'Linux'
      }
    end
    context 'with trusted set' do
      let(:params) do
        {
          :puppet_server          => 'test.exaple.com',
          :puppet_agent_service   => 'puppet',
          :puppet_agent_package   => 'puppet',
          :version                => '/etc/puppet/manifests/site.pp',
          :puppet_run_style       => 'cron',
          :splay                  => 'true',
          :environment            => 'production',
          :trusted_node_data      => 'true',
          :puppet_run_interval    => 30,
          :puppet_server_port     => 8140,
          :use_srv_records        => false,
        }
      end

      it{
        should contain_ini_setting('puppetagenttrusted_node_data').with(
          :ensure  => 'present',
          :section => 'agent',
          :setting => 'trusted_node_data',
          :value   => 'true',
          :path    => '/etc/puppet/puppet.conf'
        )
      }
    end

    context 'with trusted not set' do
      let(:params) do
        {
          :puppet_server          => 'test.exaple.com',
          :puppet_agent_service   => 'puppet',
          :puppet_agent_package   => 'puppet',
          :version                => '/etc/puppet/manifests/site.pp',
          :puppet_run_style       => 'cron',
          :splay                  => 'true',
          :environment            => 'production',
          :puppet_run_interval    => 30,
          :puppet_server_port     => 8140,
          :use_srv_records        => false,
        }
      end

      it{
        should contain_ini_setting('puppetagenttrusted_node_data').with(
          :ensure  => 'absent',
          :section => 'agent',
          :setting => 'trusted_node_data',
          :path    => '/etc/puppet/puppet.conf'
        )
      }
    end
  end
  describe 'Trusted fact' do
    let(:facts) do
      {
        :osfamily        => 'RedHat',
        :operatingsystem => 'RedHat',
        :kernel          => 'Linux'
      }
    end
    context 'with templatedir set' do
      let(:params) do
        {
          :puppet_server          => 'test.exaple.com',
          :puppet_agent_service   => 'puppet',
          :puppet_agent_package   => 'puppet',
          :version                => '/etc/puppet/manifests/site.pp',
          :puppet_run_style       => 'cron',
          :splay                  => 'true',
          :environment            => 'production',
          :puppet_run_interval    => 30,
          :puppet_server_port     => 8140,
          :use_srv_records        => false,
          :templatedir            => '$confdir/templates'
        }
      end

      it{
        should contain_ini_setting('puppetagenttemplatedir').with(
          :ensure  => 'present',
          :section => 'main',
          :setting => 'templatedir',
          :value   => '$confdir/templates',
          :path    => '/etc/puppet/puppet.conf'
        )
      }
    end

    context 'with templatedir not set' do
      let(:params) do
        {
          :puppet_server          => 'test.exaple.com',
          :puppet_agent_service   => 'puppet',
          :puppet_agent_package   => 'puppet',
          :version                => '/etc/puppet/manifests/site.pp',
          :puppet_run_style       => 'cron',
          :splay                  => 'true',
          :environment            => 'production',
          :puppet_run_interval    => 30,
          :puppet_server_port     => 8140,
          :use_srv_records        => false
        }
      end

      it{
        should contain_ini_setting('puppetagenttemplatedir').with(
          :ensure  => 'absent',
          :section => 'main',
          :setting => 'templatedir',
          :path    => '/etc/puppet/puppet.conf'
        )
      }
    end
  end
  describe 'configtimeout' do
    let(:facts) do
      {
        :osfamily        => 'RedHat',
        :operatingsystem => 'RedHat',
        :kernel          => 'Linux'
      }
    end
    context 'with configtimeout set' do
      let(:params) do
        {
          :configtimeout        => '3m',
        }
      end

      it{
        should contain_ini_setting('puppetagentconfigtimeout').with(
          :ensure  => 'present',
          :section => 'agent',
          :setting => 'configtimeout',
          :value   => '3m',
          :path    => '/etc/puppet/puppet.conf'
        )
      }
    end

    context 'with configtimeout not set' do
      let(:params) do
        {
        }
      end

      it{
        should contain_ini_setting('puppetagentconfigtimeout').with(
          :ensure  => 'present',
          :section => 'agent',
          :setting => 'configtimeout',
          :value   => '2m',
          :path    => '/etc/puppet/puppet.conf'
        )
      }
    end
  end
  describe 'puppetagentstringifyfacts' do
    let(:facts) do
      {
        :osfamily        => 'RedHat',
        :operatingsystem => 'RedHat',
        :kernel          => 'Linux'
      }
    end
    context 'with stringify_facts set' do
      let(:params) do
        {
          :stringify_facts        => true,
        }
      end

      it{
        should contain_ini_setting('puppetagentstringifyfacts').with(
          :ensure  => 'present',
          :section => 'agent',
          :setting => 'stringify_facts',
          :value   => 'true',
          :path    => '/etc/puppet/puppet.conf'
        )
      }
    end
  end
end
