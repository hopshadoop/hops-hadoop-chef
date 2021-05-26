# Install and start Docker
Chef::Recipe.send(:include, Hops::Helpers)

case node['platform_family']
when 'rhel'

  # During upgrades, there might be a previous version of docker (not -ce) which will conflict with 
  # The docker-ce package we will install below. 
  package ['docker', 'docker-common'] do
    action :remove
    only_if "yum list installed docker.x86_64"
  end

  package ['lvm2','device-mapper','device-mapper-persistent-data','device-mapper-event','device-mapper-libs','device-mapper-event-libs']

  packages = ["container-selinux-#{node['hops']['selinux_version']['centos']}.el7.noarch.rpm", "containerd.io-#{node['hops']['containerd_version']['centos']}.el7.x86_64.rpm","docker-ce-#{node['hops']['docker_version']['centos']}.el7.x86_64.rpm","docker-ce-cli-#{node['hops']['docker_version']['centos']}.el7.x86_64.rpm"]

  packages.each do |pkg|
    remote_file "#{Chef::Config['file_cache_path']}/#{pkg}" do
      source "#{node['hops']['docker']['pkg']['download_url']['centos']}/#{pkg}"
      owner 'root'
      group 'root'
      mode '0755'
      action :create
    end
  end
  
  bash "install_pkgs" do
    user 'root'
    group 'root'
    cwd Chef::Config['file_cache_path']
    code <<-EOH
        yum install -y #{packages.join(" ")}
    EOH
    not_if "yum list installed docker-ce-#{node['hops']['docker_version']['centos']}.el7.x86_64"
  end

when 'debian'
  package 'containerd' do
    version node['hops']['containerd_version']['ubuntu']
  end

  package 'docker.io' do
    version node['hops']['docker_version']['ubuntu']
  end
end

if node['hops']['gpu'].eql?("false")
  if node.attribute?("cuda") && node['cuda'].attribute?("accept_nvidia_download_terms") && node['cuda']['accept_nvidia_download_terms'].eql?("true")
    node.override['hops']['gpu'] = "true"
  end
end

#delete the config file to not interfere with the package installation
#we recreate it after anyway.
file '/etc/docker/daemon.json' do
  action :delete
  only_if { File.exist? '/etc/docker/daemon.json' }
end

if node['hops']['gpu'].eql?("true")
  package_type = node['platform_family'].eql?("debian") ? "_amd64.deb" : ".x86_64.rpm"
  case node['platform_family']
  when 'rhel'
    nvidia_docker_packages = ["libnvidia-container1-1.0.7-1#{package_type}", "libnvidia-container-tools-1.0.7-1#{package_type}", "nvidia-container-toolkit-1.0.5-2#{package_type}", "nvidia-container-runtime-3.1.4-1#{package_type}", "nvidia-docker2-2.2.2-1.noarch.rpm"]
  when 'debian'
    nvidia_docker_packages = ["libnvidia-container1_1.0.7-1#{package_type}", "libnvidia-container-tools_1.0.7-1#{package_type}", "nvidia-container-toolkit_1.0.5-1#{package_type}", "nvidia-container-runtime_3.1.4-1#{package_type}", "nvidia-docker2_2.2.2-1_all.deb"]
  end
  nvidia_docker_packages.each do |pkg|
    remote_file "#{Chef::Config['file_cache_path']}/#{pkg}" do
      source "#{node['hops']['nvidia_pkgs']['download_url']}/#{pkg}"
      owner 'root'
      group 'root'
      mode '0755'
      action :create
    end
  end

  # Install packages & Platform specific configuration
  case node['platform_family']
  when 'rhel'

    bash "install_pkgs" do
      user 'root'
      group 'root'
      cwd Chef::Config['file_cache_path']
      code <<-EOH
        yum install -y #{nvidia_docker_packages.join(" ")}
        EOH
      not_if "yum list installed libnvidia-container1"
    end

  when 'debian'
    
    bash "install_pkgs" do
      user 'root'
      group 'root'
      cwd Chef::Config['file_cache_path']
      code <<-EOH
        apt install -y ./#{nvidia_docker_packages.join(" ./")}
        EOH
    end
  end
  
end

if !node['hops']['docker_dir'].eql?("/var/lib/docker")
  directory node['hops']['data_volume']['docker'] do
    owner 'root'
    group 'root'
    mode '0711'
    recursive true
    action :create
  end

  systemd_unit "docker.service" do
    action :stop
    only_if { conda_helpers.is_upgrade }
    only_if { File.directory?(node['hops']['docker_dir'])}
    not_if { File.symlink?(node['hops']['docker_dir'])}
    notifies :run, 'bash[move-docker-images]', :immediately
  end

  bash 'move-docker-images' do
    user 'root'
    code <<-EOH
      set -e
      mv -f #{node['hops']['docker_dir']}/* #{node['hops']['data_volume']['docker']}
      rm -rf #{node['hops']['docker_dir']}
    EOH
    action :nothing
    notifies :start, 'systemd_unit[docker.service]', :immediately
  end

  systemd_unit "docker.service" do
    action :nothing
  end

  link node['hops']['docker_dir'] do
    owner 'root'
    group 'root'
    mode '0711'
    to node['hops']['data_volume']['docker']
  end
end

# Configure Docker

directory '/etc/docker/' do
  owner 'root'
  group 'root'
  recursive true
end

insecure_registries = node['hops']['docker']['insecure_registries'].split(",")
if service_discovery_enabled()
  registry_host = consul_helper.get_service_fqdn("registry")
  insecure_registries << "#{registry_host}:#{node['hops']['docker']['registry']['port']}"
end

# Special case where its a localhost installation for Ubuntu
# If we don't override Docker's DNS servers, in AWS we can't
# resolve our own hostname
override_dns = node['install']['localhost'].casecmp?("true") && node['platform_family'].eql?("debian")
dns_servers = ["127.0.0.53"]

template '/etc/docker/daemon.json' do
  source 'daemon.json.erb'
  owner 'root'
  mode '0755'
  action :create
  variables({
              :insecure_registries => insecure_registries,
              :override_dns => override_dns,
              :dns_servers => dns_servers
            })
end

service_name='docker'
# Start the docker deamon
service service_name do
  action [:enable, :restart]
end

kagent_config service_name do
  action :systemd_reload
end
