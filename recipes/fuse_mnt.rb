include_recipe "hops::default"

# Intall the needed packages
case node['platform_family']
when 'debian'
  package 'fuse'
  package 'libfuse-dev'
when 'rhel'
  package 'fuse'
  package 'fuse-libs'
end

# Allow non root users to mount file systems 
bash "fuseconfig" do
  user "root" 
  code <<-EOH
    echo "user_allow_other" >>  /etc/fuse.conf
  EOH
  not_if "grep '^user_allow_other' /etc/fuse.conf"
end

directory node['hops']['fuse']['staging_folder'] do
  action :create
  owner node['hops']['hdfs']['user']
  group node['hops']['group']
  mode "0750"
  recursive true
end

directory node['hops']['fuse']['mount_point'] do
  action :create
  owner node['hops']['hdfs']['user']
  group node['hops']['group']
  mode "0700"
  recursive true
end

# download fuse mount bin
fuse_mount_bin_url = node['hops']['fuse']['dist_url']
bin_name = File.basename(fuse_mount_bin_url)
fuse_mount_bin = "#{node['hops']['sbin_dir']}/#{bin_name}"

file fuse_mount_bin do
  action :delete
  only_if { File.exist? "#{fuse_mount_bin}" }
end

remote_file fuse_mount_bin do
  source fuse_mount_bin_url
  owner node['hops']['hdfs']['user']
  group node['hops']['group']
  mode '0755'
  action :create
end

# FS URI
my_ip = my_private_ip()
if node['install']['localhost'].casecmp?("true")
  nn_address = "localhost"
else 
  if node['hops']['nn']['private_ips'].include?(my_ip)
    # If I'm a NameNode set it to my fqdn or IP
    if service_discovery_enabled()
      nn_address = node['fqdn']
    else
      nn_address = my_ip
    end
  else
    # Otherwise use Service Discovery FQDN
    nn_address = rpc_namenode_fqdn
  end
end

# creating script to mount FS
file "#{node['hops']['sbin_dir']}/mount-fs.sh" do
  action :delete
  only_if { File.exist? "#{node['hops']['sbin_dir']}/mount-fs.sh" }
end

file "#{node['hops']['sbin_dir']}/unmount-fs.sh" do
  action :delete
  only_if { File.exist? "#{node['hops']['sbin_dir']}/unmount-fs.sh" }
end

template "#{node['hops']['sbin_dir']}/mount-fs.sh" do
  source "mount-fs.sh.erb"
  owner node['hops']['hdfs']['user']
  group node['hops']['hdfs']['group']
  mode "750"
  variables({
    :nn_address => nn_address,
    :fuse_mount_bin => fuse_mount_bin
  })
  action :create
end

template "#{node['hops']['sbin_dir']}/unmount-fs.sh" do
  source "unmount-fs.sh.erb"
  owner node['hops']['hdfs']['user']
  group node['hops']['hdfs']['group']
  mode "750"
  variables({
    :nn_address => nn_address,
    :fuse_mount_bin => fuse_mount_bin
  })
  action :create
end

# create service for it
service_name="hopsfsmount"
deps = ""
if service_discovery_enabled()
  deps += "consul.service "
end
if exists_local("hops", "nn") 
  deps += "namenode.service "
end  

service service_name do
  provider Chef::Provider::Service::Systemd
  supports :restart => true, :stop => true, :start => true, :status => true
  action :nothing
end

case node['platform_family']
when "rhel"
  systemd_script = "/usr/lib/systemd/system/#{service_name}.service"
when "debian"
  systemd_script = "/lib/systemd/system/#{service_name}.service"
end

file systemd_script do
  action :delete
  ignore_failure true
end

template systemd_script do
  source "#{service_name}.service.erb"
  owner "root"
  group "root"
  mode 0664
  variables({
            :deps => deps
            })
  action :create
  if node['services']['enabled'] == "true"
    notifies :enable, "service[#{service_name}]"
  end
end

kagent_config "#{service_name}" do
  action :systemd_reload
end

if node['kagent']['enabled'] == "true"
  kagent_config service_name do
    service "HDFS"
    log_file "#{node['hops']['logs_dir']}/fuse-mount.log"
  end
end