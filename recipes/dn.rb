include_recipe "hops::default"

template_ssl_server()

for script in node['hops']['dn']['scripts']
  template "#{node['hops']['sbin_dir']}/#{script}" do
    source "#{script}.erb"
    owner node['hops']['hdfs']['user']
    group node['hops']['secure_group']
    mode 0750
  end
end 

#
# ZFS datadir may need to be createed/mounted by kagent
# Need to make sure it has correct owner/permissions
#

dd=node['hops']['dn']['data_dir']
dataDir=dd.gsub("file://","")
dirs = dataDir.split(",")

for d in dirs do
  directory d do
    owner node['hops']['hdfs']['user']
    group node['hops']['group']
    mode "0770"
    action :create
  end
end

cookbook_file "#{node['hops']['conf_dir']}/datanode.yaml" do 
  source "metrics/datanode.yaml"
  owner node['hops']['hdfs']['user']
  group node['hops']['group']
  mode 500
end

deps = ""
if service_discovery_enabled()
  deps += "consul.service "
end
if exists_local("hops", "nn") 
  deps += "namenode.service "
end  


# wait for kagent to start if the datadirs are encrypted with ZFS
# kagent will mount and unlock the datadir before the datanode starts
if node.attribute?("zfs") && node["zfs"].attribute?("pools")
  if node['zfs']['pools'].empty? == false
    deps = "kagent.service " + deps
  end
end


service_name="datanode"

if node['hops']['systemd'] == "true"

  case node['platform_family']
  when "rhel"
    systemd_script = "/usr/lib/systemd/system/#{service_name}.service" 
  else
    systemd_script = "/lib/systemd/system/#{service_name}.service"
  end

  service "#{service_name}" do
    provider Chef::Provider::Service::Systemd
    supports :restart => true, :stop => true, :start => true, :status => true
    action :nothing
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
if node['services']['enabled'] == "true"
    notifies :enable, "service[#{service_name}]"
end
    notifies :restart, "service[#{service_name}]"
  end

  directory "/etc/systemd/system/#{service_name}.service.d" do
    owner "root"
    group "root"
    mode "755"
    action :create
  end

  template "/etc/systemd/system/#{service_name}.service.d/limits.conf" do
    source "limits.conf.erb"
    owner "root"
    mode 0664
    action :create
    notifies :restart, "service[#{service_name}]"    
  end 

  kagent_config "#{service_name}" do
    action :systemd_reload
    not_if "systemctl status datanode"    
  end
  
  
else #sysv

  service "#{service_name}" do
    provider Chef::Provider::Service::Init::Debian
    supports :restart => true, :stop => true, :start => true, :status => true
    action :nothing
  end

  template "/etc/init.d/#{service_name}" do
    source "#{service_name}.erb"
    owner "root"
    group "root"
    mode 0755        
if node['services']['enabled'] == "true"
    notifies :enable, resources(:service => "#{service_name}")
end
    notifies :restart, resources(:service => "#{service_name}"), :immediately
  end

end

if node['kagent']['enabled'] == "true" 
  kagent_config service_name do
    service "HDFS"
    log_file "#{node['hops']['logs_dir']}/hadoop-#{node['hops']['hdfs']['user']}-#{service_name}-#{node['hostname']}.log"
    config_file "#{node['hops']['conf_dir']}/hdfs-site.xml"
  end
end

if service_discovery_enabled()
  # Register DataNode with Consul
  template "#{node['hops']['bin_dir']}/consul/dn-health.sh" do
    source "consul/dn-health.sh.erb"
    owner node['hops']['hdfs']['user']
    group node['hops']['group']
    mode 0750
  end

  consul_service "Registering DataNode with Consul" do
    service_definition "consul/dn-consul.hcl.erb"
    action :register
  end
end