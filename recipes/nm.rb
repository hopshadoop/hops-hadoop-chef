include_recipe "hops::default"
include_recipe "livy::install"

template_ssl_server()

deps = ""
if exists_local("hops", "rm")
  deps = "resourcemanager.service"
end

yarn_service="nm"
service_name="nodemanager"


directory node['hops']['yarn']['nodemanager_recovery_dir'] do
  owner node['hops']['nm']['user']
  group node['hops']['group']
  mode "0770"
  action :create
end

for script in node['hops']['yarn']['scripts']
  template "#{node['hops']['home']}/sbin/#{script}-#{yarn_service}.sh" do
    source "#{script}-#{yarn_service}.sh.erb"
    owner node['hops']['yarn']['user']
    group node['hops']['group']
    mode 0775
  end
end



if node['install']['cloud'].casecmp?("gcp") == 0
  
  gcp_url = node['hops']['gcp_url']
  gcp_jar = File.basename(gcp_url)
  
  remote_file "#{node['hops']['base_dir']}/share/hadoop/yarn/lib/#{gcp_jar}" do
    source gcp_url
    owner node['hops']['yarn']['user']
    group node['hops']['group']
    mode "0755"
  # TODO - checksum
    action :create_if_missing
  end
end

if node['install']['cloud'].casecmp?("azure") == 0
  
  adl_v1_url = node['hops']['adl_v1_url']
  adl_v1_jar = File.basename(adl_v1_url)
  
  remote_file "#{node['hops']['base_dir']}/share/hadoop/yarn/lib/#{adl_v1_jar}" do
    source adl_v1_url
    owner node['hops']['yarn']['user']
    group node['hops']['group']
    mode "0755"
  # TODO - checksum
    action :create_if_missing
  end
end



nvidia_url = node['nvidia']['download_url']
nvidia_jar = File.basename(nvidia_url)

remote_file "#{node['hops']['base_dir']}/share/hadoop/yarn/lib/#{nvidia_jar}" do
  source nvidia_url
  owner node['hops']['yarn']['user']
  group node['hops']['group']
  mode "0755"
  # TODO - checksum
  #  action :create_if_missing
  action :create
end

libhopsnvml = File.basename(node['hops']['libnvml_url'])
remote_file "#{node['hops']['base_dir']}/lib/native/#{libhopsnvml}" do
  source node['hops']['libnvml_url']
  owner node['hops']['yarn']['user']
  group node['hops']['group']
  mode "0755"
  # TODO - checksum
  action :create_if_missing
end

link "#{node['hops']['base_dir']}/lib/native/libhopsnvml.so" do
  owner node['hops']['yarn']['user']
  group node['hops']['group']
  to "#{node['hops']['base_dir']}/lib/native/#{libhopsnvml}"
end

amd_url = node['amd']['download_url']
amd_jar = File.basename(amd_url)

remote_file "#{node['hops']['base_dir']}/share/hadoop/yarn/lib/#{amd_jar}" do
  source amd_url
  owner node['hops']['yarn']['user']
  group node['hops']['group']
  mode "0755"
  # TODO - checksum
  #  action :create_if_missing
  action :create
end


libhopsrocm = File.basename(node['hops']['librocm_url'])
remote_file "#{node['hops']['base_dir']}/lib/native/#{libhopsrocm}" do
  source node['hops']['librocm_url']
  owner node['hops']['yarn']['user']
  group node['hops']['group']
  mode "0755"
  # TODO - checksum
  action :create_if_missing
end

link "#{node['hops']['base_dir']}/lib/native/libhopsrocm.so" do
  owner node['hops']['yarn']['user']
  group node['hops']['group']
  to "#{node['hops']['base_dir']}/lib/native/#{libhopsrocm}"
end

cookbook_file "#{node['hops']['conf_dir']}/nodemanager.yaml" do 
  source "metrics/nodemanager.yaml"
  owner node['hops']['yarn']['user']
  group node['hops']['group']
  mode 500
end

if node['hops']['systemd'] == "true"

  service service_name do
    provider Chef::Provider::Service::Systemd
    supports :restart => true, :stop => true, :start => true, :status => true
    action :nothing
  end

  case node['platform_family']
  when "rhel"
    systemd_script = "/usr/lib/systemd/system/#{service_name}.service"
  else
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
if node['services']['enabled'] == "true"
    notifies :enable, resources(:service => "#{service_name}")
end
    notifies :restart, resources(:service => service_name)
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
    mode 0774
    action :create
  end

  kagent_config "#{service_name}" do
    action :systemd_reload
    not_if "systemctl status nodemanager"
  end

else #sysv

  service service_name do
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
    notifies :restart, resources(:service => service_name)
  end

end

if node['kagent']['enabled'] == "true"
  kagent_config service_name do
    service "YARN"
    log_file "#{node['hops']['logs_dir']}/yarn-#{node['hops']['yarn']['user']}-#{service_name}-#{node['hostname']}.log"
  end
end


#
# If horovod is installed, mpi is enabled.
# Add the glassfish users' public key, so that it can start/stop horovod on host using mpi-run
#
if node.attribute?('tensorflow') == true
  if node['tensorflow'].attribute?('mpi') == true
    homedir = node['hops']['yarnapp']['user'].eql?("root") ? "/root" : "/home/#{node['hops']['yarnapp']['user']}"
    kagent_keys "#{homedir}" do
      cb_user "#{node['hops']['yarnapp']['user']}"
      cb_group "#{node['hops']['group']}"
      cb_name "hopsworks"
      cb_recipe "default"
      action :get_publickey
    end

  end
end



