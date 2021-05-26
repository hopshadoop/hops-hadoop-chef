require 'etc'

include_recipe "hops::_config"
include_recipe "java"

if node['hops']['nn']['direct_memory_size'].to_i < node['hops']['nn']['heap_size'].to_i
  raise "Invalid Configuration. Set Java DirectByteBuffer memory as high as Java heap size otherwise, the NNs might experience severe GC pauses."
end

magic_shell_environment 'LD_LIBRARY_PATH' do
  value "#{node['hops']['base_dir']}/lib/native:$LD_LIBRARY_PATH"
end

# http://blog.cloudera.com/blog/2015/01/how-to-deploy-apache-hadoop-clusters-like-a-boss/
# Set Kernel parameters
sysctl_param 'vm.swappiness' do
  value node['hops']['kernel']['swappiness']
end

sysctl_param 'vm.overcommit_memory' do
  value node['hops']['kernel']['overcommit_memory']
  value
end

sysctl_param 'vm.overcommit_ratio' do
  value node['hops']['kernel']['overcommit_ratio']
end

sysctl_param 'net.core.somaxconn' do
  value node['hops']['kernel']['somaxconn']
end

group node["kagent"]["certs_group"] do
  action :manage
  append true
  excluded_members [node['hops']['hdfs']['user'], node['hops']['yarn']['user'], node['hops']['rm']['user'], node['hops']['mr']['user']]
  not_if { node['install']['external_users'].casecmp("true") == 0 }
  only_if { conda_helpers.is_upgrade }
end

#
# http://www.slideshare.net/vgogate/hadoop-configuration-performance-tuning
#
if node['platform_family'].eql?("redhat")
  bash "configure_os" do
     user "root"
     code <<-EOF
      echo "never" > /sys/kernel/mm/redhat_transparent_hugepages/defrag
     EOF
  end
end

# We need to change the group from the previous ID to the new one during an upgrade
bash 'chgrp' do
  user "root"
  code <<-EOH
    old_gid=`cat /etc/group | grep hadoop | awk '{split($0,a,":"); print a[3]}'`
    if [ "$old_gid" != "#{node['hops']['group_id']}" ];
    then
      find #{node['install']['dir']} -group $old_gid -exec chgrp #{node['hops']['group_id']} {} \\;
    fi
  EOH
  only_if { !node['install']['current_version'].eql?("") &&
    Gem::Version.new(node['install']['current_version']) <= Gem::Version.new('1.3.0')}
  not_if  { node['install']['external_users'].casecmp("true") == 0 }
end

# we need to fix the gid to match the one in the docker image
# here we re-create the group. users could have been added before this point
# so we need to make sure we add them back to the new group
current_hadoop_members = []
ruby_block 'find current hadoop group members' do
  block do
    current_hadoop_members = Etc.getgrnam(node['hops']['group']).mem
  end
  action :run
  only_if "getent group #{node['hops']['group']}"
end

group node['hops']['group'] do
  gid node['hops']['group_id']
  members lazy { current_hadoop_members }
  action :create
  not_if { node['install']['external_users'].casecmp("true") == 0 }
end

group node['hops']['secure_group'] do
  action :create
  not_if { node['install']['external_users'].casecmp("true") == 0 }
end

user node['hops']['hdfs']['user'] do
  home node['hops']['hdfs']['user-home']
  gid node['hops']['group']
  system true
  shell "/bin/bash"
  manage_home true
  action :create
  not_if "getent passwd #{node['hops']['hdfs']['user']}"
  not_if { node['install']['external_users'].casecmp("true") == 0 }
end

user node['hops']['yarn']['user'] do
  home node['hops']['yarn']['user-home']
  gid node['hops']['group']
  system true
  shell "/bin/bash"
  manage_home true
  action :create
  not_if "getent passwd #{node['hops']['yarn']['user']}"
  not_if { node['install']['external_users'].casecmp("true") == 0 }
end

user node['hops']['mr']['user'] do
  home node['hops']['mr']['user-home']
  gid node['hops']['group']
  system true
  shell "/bin/bash"
  manage_home true
  action :create
  not_if "getent passwd #{node['hops']['mr']['user']}"
  not_if { node['install']['external_users'].casecmp("true") == 0 }
end

# we need to fix the uid to match the one in the docker image
# during an upgrade the user id might not match what we expect.
# the :create will re-create the user with a different id
# yarnapp doesn't own anything on the fs (at least not in /srv/hops)
# so it's safe to remove and re-create the user
user node['hops']['yarnapp']['user'] do
  uid node['hops']['yarnapp']['uid']
  gid node['hops']['group']
  system true
  manage_home true
  shell "/bin/bash"
  action :create
  not_if { node['install']['external_users'].casecmp("true") == 0 }
end

user node['hops']['rm']['user'] do
  home node['hops']['rm']['user-home']
  gid node['hops']['secure_group']
  system true
  shell "/bin/bash"
  action :create
  manage_home true
  not_if "getent passwd #{node['hops']['rm']['user']}"
  not_if { node['install']['external_users'].casecmp("true") == 0 }
end

group "video" do
  action :modify
  members [node['hops']['yarnapp']['user']]
  append true
  not_if { node['install']['external_users'].casecmp("true") == 0 }
end

group node['hops']['secure_group'] do
  action :modify
  members [node['hops']['rm']['user'], node['hops']['mr']['user'], node['hops']['yarn']['user']]
  append true
  not_if { node['install']['external_users'].casecmp("true") == 0 }
end

group node['hops']['group'] do
  action :modify
  members [node['hops']['hdfs']['user'], node['hops']['yarn']['user'], node['hops']['mr']['user'], node['hops']['yarnapp']['user'], node['hops']['rm']['user']]
  append true
  not_if { node['install']['external_users'].casecmp("true") == 0 }
end

case node['platform_family']
when 'debian'
  package 'libsnappy1v5'
when 'rhel'
  package 'snappy'
  # bind-utils is needed to start the datanode, if HopsFS is installed without Hopsworks
  package 'bind-utils'
end

if node['hops']['native_libraries'].eql? "true"

  # build hadoop native libraries: http://www.drweiwang.com/build-hadoop-native-libraries/
  # g++ autoconf automake libtool zlib1g-dev pkg-config libssl-dev cmake

  include_recipe 'build-essential::default'
  include_recipe 'cmake::default'

    protobuf_url = node['hops']['protobuf_url']
    base_protobuf_filename = File.basename(protobuf_url)
    cached_protobuf_filename = "#{Chef::Config['file_cache_path']}/#{base_protobuf_filename}"

    remote_file cached_protobuf_filename do
      source protobuf_url
      owner node['hops']['hdfs']['user']
      group node['hops']['group']
      mode "0775"
      action :create_if_missing
    end

  protobuf_lib_prefix = "/usr"
  case node['platform_family']
  when "debian"
    package ['g++', 'autoconf', 'automake', 'libtool', 'zlib1g-dev', 'libssl-dev', 'pkg-config', 'maven']
  when "rhel"
    protobuf_lib_prefix = "/"

    # https://github.com/burtlo/ark
    ark "maven" do
      url "http://apache.mirrors.spacedump.net/maven/maven-3/#{node['maven']['version']}/binaries/apache-maven-#{node['maven']['version']}-bin.tar.gz"
      version "#{node['maven']['version']}"
      path "/usr/local/maven/"
      home_dir "/usr/local/maven"
 #     checksum  "#{node['maven']['checksum']}"
      append_env_path true
      owner "#{node['hops']['hdfs']['user']}"
    end

  end
   protobuf_name_no_extension = File.basename(base_protobuf_filename, ".tar.gz")
   protobuf_name = "#{protobuf_lib_prefix}/.#{protobuf_name_no_extension}_downloaded"
   bash 'extract-protobuf' do
      user "root"
      code <<-EOH
        set -e
        cd #{Chef::Config['file_cache_path']}
	tar -zxf #{cached_protobuf_filename}
        cd #{protobuf_name_no_extension}
        ./configure --prefix=#{protobuf_lib_prefix}
        make
        make check
        make install
        touch #{protobuf_name}
	EOH
     not_if { ::File.exist?("#{protobuf_name}") }
    end

end

# For LinuxContainerExecutor the the whole hadoop subtree should be own by root and not group writable.
# If another cookbook has created the directory before, it will be updaste to have the correct ownership/permissions
directory node['hops']['dir'] do
  owner "root"
  group node['hops']['group']
  mode "0755"
  action :create
end

directory node['data']['dir'] do
  owner 'root'
  group 'root'
  mode '0775'
  action :create
  not_if { ::File.directory?(node['data']['dir']) }
end

directory node['hops']['data_volume']['data_dir'] do
  owner node['hops']['hdfs']['user']
  group node['hops']['group']
  mode "0770"
  recursive true
  action :create
end

bash 'Move Hops hopsdata to data volume' do
  user 'root'
  code <<-EOH
    set -e
    mv -f #{node['hops']['data_dir']}/* #{node['hops']['data_volume']['data_dir']}
    rm -rf #{node['hops']['data_dir']}
  EOH
  only_if { conda_helpers.is_upgrade }
  only_if { File.directory?(node['hops']['data_dir'])}
  not_if { File.symlink?(node['hops']['data_dir'])}
end

link node['hops']['data_dir'] do
  owner node['hops']['hdfs']['user']
  group node['hops']['group']
  mode "0770"
  to node['hops']['data_volume']['data_dir']
end

if node['hops']['docker']['enabled'].eql?("true")
  include_recipe "hops::docker"
end

dd=node['hops']['data_dir']
dataDir=dd.gsub("file://","")

directory dataDir do
  owner node['hops']['hdfs']['user']
  group node['hops']['group']
  mode "0770"
  recursive true
  action :create
end

if "#{node['hops']['dn']['data_dir']}".include? ","
  dirs = node['hops']['dn']['data_dir'].split(",")
  for d in dirs do
    dir = d.gsub(/\[.*\]/, "") #remove [HOT], [CLOUD] storage type tags
    dir = dir.gsub("file://","")
    bash 'chown_datadirs_if_exist' do
      user "root"
      code <<-EOH
        set -e
        # -e tests for dir, file, symbolic link. It should be a dir.
        if [ ! -e #{dir} ] ; then
           mkdir -p #{dir}
           chown #{node['hops']['hdfs']['user']}:#{node['hops']['group']} #{dir}
        fi
        # chown -R #{node['hops']['hdfs']['user']}:#{node['hops']['group']} #{dir}
      EOH
    end
   end
else
  ad=node['hops']['dn']['data_dir']
  ddir = ad.gsub(/\[.*\]/, "") #remove [HOT], [CLOUD] storage type tags
  ddir = ddir.gsub("file://","")
  directory ddir do
    owner node['hops']['hdfs']['user']
    group node['hops']['group']
    mode "0770"
    recursive true
    action :create
  end
end

ann=node['hops']['nn']['name_dir']
nndir=ann.gsub("file://","")
directory nndir do
  owner node['hops']['hdfs']['user']
  group node['hops']['group']
  mode "0770"
  recursive true
  action :create
end

dist_url = node['hops']['dist_url']
Chef::Log.info "Attempting to download hadoop binaries from #{dist_url}"

base_package_filename = File.basename(dist_url)
cached_package_filename = "#{Chef::Config['file_cache_path']}/#{base_package_filename}"

remote_file cached_package_filename do
  source dist_url
  retries 2
  owner node['hops']['hdfs']['user']
  group node['hops']['group']
  headers get_ee_basic_auth_header()
  sensitive true
  mode "0755"
  ignore_failure true
  # TODO - checksum
  action :create_if_missing
end

hin = "#{node['hops']['home']}/.#{base_package_filename}_installed"
base_name = File.basename(base_package_filename, ".tgz")
# Extract and install hadoop
bash 'extract-hadoop' do
  user "root"
  code <<-EOH
        set -e
	      tar -zxf #{cached_package_filename} -C #{node['hops']['dir']}
        # remove the config files that we would otherwise overwrite
        rm -rf #{node['hops']['home']}/etc/*

        rm -f #{node['hops']['base_dir']}
        ln -s #{node['hops']['home']} #{node['hops']['base_dir']}

        # chown -L : traverse symbolic links
        chown -RL #{node['hops']['hdfs']['user']}:#{node['hops']['group']} #{node['hops']['base_dir']}
        chmod 755 #{node['hops']['home']}

        # Write flag
        touch #{hin}
	EOH
  not_if { ::File.exist?("#{hin}") }
end

bash 'chown-sbin' do
  user 'root'
  group 'root'
  code <<-EOH
    chown -R #{node['hops']['hdfs']['user']}:#{node['hops']['secure_group']} #{node['hops']['sbin_dir']}
    chmod -R 550 #{node['hops']['sbin_dir']}
  EOH
end

directory node['hops']['data_volume']['logs_dir'] do
  owner node['hops']['hdfs']['user']
  group node['hops']['group']
  mode '0770'
  action :create
end

bash 'Move Hops logs to data volume' do
  user 'root'
  code <<-EOH
    set -e
    mv -f #{node['hops']['logs_dir']}/* #{node['hops']['data_volume']['logs_dir']}
    rm -rf #{node['hops']['logs_dir']}
  EOH
  only_if { conda_helpers.is_upgrade }
  only_if { File.directory?(node['hops']['logs_dir'])}
  not_if { File.symlink?(node['hops']['logs_dir'])}
end

link node['hops']['logs_dir'] do
  owner node['hops']['hdfs']['user']
  group node['hops']['group']
  mode '0770'
  to node['hops']['data_volume']['logs_dir']
end

# Touch file with correct ownership and permission
file "#{node['hops']['logs_dir']}/hadoop.log" do
  owner node['hops']['hdfs']['user']
  group node['hops']['group']
  mode "0770"
  action :create_if_missing
end

directory node['hops']['tmp_dir'] do
  owner node['hops']['hdfs']['user']
  group node['hops']['group']
  mode "1770"
  action :create
end

directory "#{node['hops']['bin_dir']}/consul" do
  owner node['hops']['hdfs']['user']
  group node['hops']['group']
  mode "0750"
  action :create
end

# For the LinuxContainerExecutor to work the path the following dirs need to be root:hadoop and not group writable
lce_dirs = [node['hops']['home'], node['hops']['conf_dir_parent'], node['hops']['conf_dir']]
for dir in lce_dirs do
  directory dir do
    owner "root"
    group node['hops']['group']
    mode "0755"
  end
end

ruby_block 'Check for native binaries' do
  block do
    if !File.exist? "#{node['hops']['bin_dir']}/container-executor"
      raise "File #{node['hops']['bin_dir']}/container-executor does not exist! Does Hops distribution contain native binaries?"
    end
  end
end

# For the LinuxContainerExecutor to work the container-executor bin needs to be owned by root:hadoop and have permission ---sr-s--- (6150)
file "#{node['hops']['bin_dir']}/container-executor" do
  owner "root"
  group node['hops']['group']
  mode "6150"
end

# Download JMX prometheus exporter
jmx_prometheus_filename = File.basename(node['hops']['jmx']['prometheus_exporter']['url'])
remote_file "#{node['hops']['share_dir']}/common/lib/#{jmx_prometheus_filename}" do
  source node['hops']['jmx']['prometheus_exporter']['url']
  owner node['hops']['hdfs']['user']
  group node['hops']['group']
  mode '0755'
  action :create
end


if node['hops']['native_libraries'] == "true"

  hadoop_src_url = node['hops']['hadoop_src_url']
  base_hadoop_src_filename = File.basename(hadoop_src_url)
  cached_hadoop_src_filename = "#{Chef::Config['file_cache_path']}/#{base_hadoop_src_filename}"

  remote_file cached_hadoop_src_filename do
    source hadoop_src_url
    owner node['hops']['hdfs']['user']
    group node['hops']['group']
    mode "0755"
    action :create_if_missing
  end

  hadoop_src_name = File.basename(base_hadoop_src_filename, ".tar.gz")
  natives="#{node['hops']['dir']}/.downloaded_#{hadoop_src_name}"

  bash 'build-hadoop-from-src-with-native-libraries' do
    user node['hops']['hdfs']['user']
    code <<-EOH
        set -e
        cd #{Chef::Config['file_cache_path']}
	      tar -xf #{cached_hadoop_src_filename}
        cd #{hadoop_src_name}
        mvn package -Pdist,native -DskipTests -Dtar
        cp -r hadoop-dist/target/hadoop-#{node['hops']['version']}/lib/native/* #{node['hops']['home']}/lib/native/
        chown -R #{node['hops']['hdfs']['user']} #{node['hops']['home']}/lib/native/
        touch #{natives}
	EOH
    not_if { ::File.exist?("#{natives}") }
  end
end

magic_shell_environment 'PATH' do
  value "$PATH:#{node['hops']['base_dir']}/bin"
end

magic_shell_environment 'JAVA_HOME' do
  value "#{node['java']['java_home']}"
end

magic_shell_environment 'HADOOP_HOME' do
  value node['hops']['base_dir']
end

magic_shell_environment 'HADOOP_CONF_DIR' do
  value "#{node['hops']['base_dir']}/etc/hadoop"
end

magic_shell_environment 'HADOOP_PID_DIR' do
  value "#{node['hops']['base_dir']}/logs"
end

magic_shell_environment 'HADOOP_PID_DIR' do
  value "#{node['hops']['base_dir']}/logs"
end


rm_private_ip = private_recipe_ip("hops","rm")

begin
  jhs_private_ip = private_recipe_ip("hops","jhs")
rescue
  jhs_private_ip = ""
  Chef::Log.warn "could not find the joh history server IP - maybe it is not installed."
end

# This is here because Pydoop consults mapred-site.xml
# Pydoop is a dependancy of hdfscontents which is installed
# in hopsworks-chef::default
template "#{node['hops']['conf_dir']}/mapred-site.xml" do
  source "mapred-site.xml.erb"
  owner node['hops']['mr']['user']
  group node['hops']['group']
  mode "754"
  variables({
      :rm_private_ip => rm_private_ip,
      :jhs_private_ip => jhs_private_ip
  })
  action :create
end

# This is here for client machines. These are machines that run Hopsworks or
# other services, but they don't run Hadoop services.
# These services read the ssl-server.xml for configuring TLS.
# We template it here, so that it can be used with single node vms, where when
# Hopsworks starts, it needs to read the ssl-server.xml
# During a fresh installation, certificates won't be available at this stage, however,
# the configuration will be still correct. Clients will fail until the certificates are
# actually generated. This is fine.
# At this stage we don't add the JWT token (False parameter) as Hopsworks is not running yet
# The RM recipe will re-template this file and, at that stage, with the Hopsworks server running,
# the JWT will be added.
Chef::Recipe.send(:include, Hops::Helpers)
template_ssl_server(false)

cookbook_file "#{node['hops']['bin_dir']}/hadoop_logs_mgm.py" do
  source "hadoop_logs_mgm.py"
  owner node['hops']['hdfs']['user']
  group node['hops']['group']
  mode "0740"
  action :create
end

template "#{node['hops']['conf_dir']}/hadoop_logs_mgm.ini" do
  source "hadoop_logs_mgm.ini.erb"
  owner node['hops']['hdfs']['user']
  group node['hops']['group']
  mode "0740"
  action :create
end

cookbook_file "#{node['hops']['sbin_dir']}/renew_service_jwt.py" do
  source "renew_service_jwt.py"
  owner node['hops']['hdfs']['user']
  group node['hops']['secure_group']
  mode "0700"
  action :create
end

template "#{node['hops']['sbin_dir']}/conda_renew_service_jwt.sh" do
  source "conda_renew_service_jwt.sh.erb"
  owner node['hops']['hdfs']['user']
  group node['hops']['secure_group']
  mode "0700"
  action :create
end
