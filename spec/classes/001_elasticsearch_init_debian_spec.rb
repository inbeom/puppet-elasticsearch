require 'spec_helper'

describe 'elasticsearch', :type => 'class' do

  default_params = {
    :config  => { 'node.name' => 'foo' }
  }

  [ 'Debian', 'Ubuntu'].each do |distro|

    context "on #{distro} OS" do

      let :facts do {
        :operatingsystem => distro,
        :kernel => 'Linux',
        :osfamily => 'Debian',
        :lsbdistid => distro.downcase
      } end

      let (:params) {
        default_params
      }

      context 'main class tests' do

        it { should compile.with_all_deps }
        # init.pp
        it { should contain_anchor('elasticsearch::begin') }
        it { should contain_class('elasticsearch::params') }
        it { should contain_class('elasticsearch::package').that_requires('Anchor[elasticsearch::begin]') }
        it { should contain_class('elasticsearch::config').that_requires('Class[elasticsearch::package]') }

        # Base directories
        it { should contain_file('/etc/elasticsearch') }
        it { should contain_exec('mkdir_templates_elasticsearch').with(:command => 'mkdir -p /etc/elasticsearch/templates_import', :creates => '/etc/elasticsearch/templates_import') }
        it { should contain_file('/etc/elasticsearch/templates_import').with(:require => 'Exec[mkdir_templates_elasticsearch]') }
        it { should contain_file('/usr/share/elasticsearch/plugins') }
      end

      context 'package installation' do

        context 'via repository' do

          context 'with default settings' do

            it { should contain_package('elasticsearch').with(:ensure => 'present') }
            it { should_not contain_package('my-elasticsearch').with(:ensure => 'present') }

          end

          context 'with specified version' do

            let (:params) {
              default_params.merge({
                :version => '1.0'
              })
            }

            it { should contain_package('elasticsearch').with(:ensure => '1.0') }
          end

          context 'with specified package name' do

            let (:params) {
              default_params.merge({
                :package_name => 'my-elasticsearch'
              })
            }

            it { should contain_package('my-elasticsearch').with(:ensure => 'present') }
            it { should_not contain_package('elasticsearch').with(:ensure => 'present') }
          end

          context 'with auto upgrade enabled' do

            let (:params) {
              default_params.merge({
                :autoupgrade => true
              })
            }

            it { should contain_package('elasticsearch').with(:ensure => 'latest') }
          end

        end

        context 'when setting package version and package_url' do

          let (:params) {
            default_params.merge({
              :version     => '0.90.10',
              :package_url => 'puppet:///path/to/some/elasticsearch-0.90.10.deb'
            })
          }

          it { expect { should raise_error(Puppet::Error) } }

        end

        context 'via package_url setting' do

          context 'using puppet:/// schema' do

            let (:params) {
              default_params.merge({
                :package_url => 'puppet:///path/to/package.deb'
              })
            }

            it { should contain_file('/opt/elasticsearch/swdl/package.deb').with(:source => 'puppet:///path/to/package.deb', :backup => false) }
            it { should contain_package('elasticsearch').with(:ensure => 'present', :source => '/opt/elasticsearch/swdl/package.deb', :provider => 'dpkg') }
          end

          context 'using http:// schema' do

            let (:params) {
              default_params.merge({
                :package_url => 'http://www.domain.com/path/to/package.deb'
              })
            }

            it { should contain_exec('create_package_dir_elasticsearch').with(:command => 'mkdir -p /opt/elasticsearch/swdl') }
            it { should contain_file('/opt/elasticsearch/swdl').with(:purge => false, :force => false, :require => "Exec[create_package_dir_elasticsearch]") }
            it { should contain_exec('download_package_elasticsearch').with(:command => 'wget -O /opt/elasticsearch/swdl/package.deb http://www.domain.com/path/to/package.deb 2> /dev/null', :require => 'File[/opt/elasticsearch/swdl]') }
            it { should contain_package('elasticsearch').with(:ensure => 'present', :source => '/opt/elasticsearch/swdl/package.deb', :provider => 'dpkg') }
          end

          context 'using https:// schema' do

            let (:params) {
              default_params.merge({
                :package_url => 'https://www.domain.com/path/to/package.deb'
              })
            }

            it { should contain_exec('create_package_dir_elasticsearch').with(:command => 'mkdir -p /opt/elasticsearch/swdl') }
            it { should contain_file('/opt/elasticsearch/swdl').with(:purge => false, :force => false, :require => 'Exec[create_package_dir_elasticsearch]') }
            it { should contain_exec('download_package_elasticsearch').with(:command => 'wget -O /opt/elasticsearch/swdl/package.deb https://www.domain.com/path/to/package.deb 2> /dev/null', :require => 'File[/opt/elasticsearch/swdl]') }
            it { should contain_package('elasticsearch').with(:ensure => 'present', :source => '/opt/elasticsearch/swdl/package.deb', :provider => 'dpkg') }
          end

          context 'using ftp:// schema' do

            let (:params) {
              default_params.merge({
                :package_url => 'ftp://www.domain.com/path/to/package.deb'
              })
            }

            it { should contain_exec('create_package_dir_elasticsearch').with(:command => 'mkdir -p /opt/elasticsearch/swdl') }
            it { should contain_file('/opt/elasticsearch/swdl').with(:purge => false, :force => false, :require => 'Exec[create_package_dir_elasticsearch]') }
            it { should contain_exec('download_package_elasticsearch').with(:command => 'wget -O /opt/elasticsearch/swdl/package.deb ftp://www.domain.com/path/to/package.deb 2> /dev/null', :require => 'File[/opt/elasticsearch/swdl]') }
            it { should contain_package('elasticsearch').with(:ensure => 'present', :source => '/opt/elasticsearch/swdl/package.deb', :provider => 'dpkg') }
          end

          context 'using file:// schema' do

            let (:params) {
              default_params.merge({
                :package_url => 'file:/path/to/package.deb'
              })
            }

            it { should contain_exec('create_package_dir_elasticsearch').with(:command => 'mkdir -p /opt/elasticsearch/swdl') }
            it { should contain_file('/opt/elasticsearch/swdl').with(:purge => false, :force => false, :require => 'Exec[create_package_dir_elasticsearch]') }
            it { should contain_file('/opt/elasticsearch/swdl/package.deb').with(:source => '/path/to/package.deb', :backup => false) }
            it { should contain_package('elasticsearch').with(:ensure => 'present', :source => '/opt/elasticsearch/swdl/package.deb', :provider => 'dpkg') }
          end

        end

      end # package

      context 'when setting the module to absent' do

        let (:params) {
          default_params.merge({
            :ensure => 'absent'
          })
        }

        it { should contain_package('elasticsearch').with(:ensure => 'absent') }

      end

      context 'When managing the repository' do

        let (:params) {
          default_params.merge({
            :manage_repo => true,
            :repo_version => '1.0'
          })
        }

        it { should contain_class('elasticsearch::repo').that_requires('Anchor[elasticsearch::begin]') }
        it { should contain_class('apt') }
        it { should contain_apt__source('elasticsearch').with(:release => 'stable', :repos => 'main', :location => 'http://packages.elasticsearch.org/elasticsearch/1.0/debian') }

      end

    end

  end

end
