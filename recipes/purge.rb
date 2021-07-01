daemons = %w{namenode datanode resourcemanager nodemanager historyserver proxyserver}
daemons.each { |d|
  bash 'uninstall_service_#{d}' do
    user "root"
    ignore_failure true
    code <<-EOF
 service #{d} stop
 systemctl stop #{d}
 pkillall -9 #{d}
 systemctl daemon-reload
 systemctl reset-failed
EOF
  end

  file "/etc/init.d/#{d}" do
    action :delete
    ignore_failure true
  end
  file "/usr/lib/systemd/systemd/#{d}.service" do
    action :delete
    ignore_failure true
  end
  file "/lib/systemd/systemd/#{d}.service" do
    action :delete
    ignore_failure true
  end
  file "/etc/systemd/system/#{d}.service" do
    action :delete
    ignore_failure true
  end
  directory "/etc/systemd/system/#{d}.service.d" do
    recursive true
    action :delete
    ignore_failure true
  end

}

directory "#{node['hops']['dir']}/hadoop-#{node['hops']['version']}" do
  recursive true
  action :delete
  ignore_failure true
end

link node['hops']['home'] do
  action :delete
  ignore_failure true
end

directory node['hops']['data_dir'] do
  recursive true
  action :delete
  ignore_failure true
end

directory Chef::Config.file_cache_path do
  recursive true
  action :delete
  ignore_failure true
end

package "Bouncy Castle Remove" do
  package_name 'bouncycastle'
  ignore_failure true
  action :purge
end


dist_url = node['hops']['dist_url']

base_package_filename = File.basename(dist_url)
cached_package_filename = "/tmp/#{base_package_filename}"

file cached_package_filename do
  action :delete
  ignore_failure true
end


link "#{node['hops']['dir']}/ndb-hops" do
  action :delete
  ignore_failure true
end

directory "#{node['hops']['dir']}/ndb-hops-#{node['hops']['version']}-#{node['ndb']['version']}" do
  recursive true
  action :delete
  ignore_failure true
end
