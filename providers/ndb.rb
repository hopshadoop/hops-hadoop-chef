action :install_hops do

  new_resource.updated_by_last_action(false)

  ndb_waiter "wait_mysql_started" do
    action :wait_until_cluster_ready
  end

  ndb_mysql_basic "mysqld_start_hop_install" do
    wait_time 10
    action :wait_until_started
  end

  bash "mysql-install-hops" do
    user "root"
    code <<-EOF
    set -e
    #{node['ndb']['scripts_dir']}/mysql-client.sh -e \"CREATE DATABASE IF NOT EXISTS #{node['hops']['db']} CHARACTER SET latin1\"
    EOF
  end
  flyway_basedir="#{node['hops']['dir']}/ndb-hops"

  template "#{flyway_basedir}/flyway.sql" do
    source "flyway.sql.erb"
    owner node['hops']['hdfs']['user']
    mode 0750
    action :create
  end


  flyway_dir="#{node['hops']['dir']}/ndb-hops/flyway"

  bash "flyway_baseline" do
    user "root"
    code <<-EOF
    set -e
    cd #{flyway_dir}
    #{flyway_dir}/flyway baseline
  EOF
    not_if "#{node['ndb']['scripts_dir']}/mysql-client.sh #{node['hops']['db']} -e 'show tables' | grep flyway_schema_history"
  end

  bash "flyway_migrate" do
    user "root"
    timeout 36000
    code <<-EOF
    set -e
    cd #{flyway_dir}
    #{flyway_dir}/flyway migrate
  EOF
  end
  
end


action :install_ndb_hops do

  Chef::Log.info "Installing hops sql on the mysql server"

  common="share/hadoop/common/lib"
  base_filename = "#{new_resource.base_filename}"

  link "#{node['hops']['home']}/#{common}/ndb-dal.jar" do
    action :delete
    only_if "test -L #{node['hops']['home']}/#{common}/ndb-dal.jar"
  end
  link "#{node['hops']['home']}/#{common}/ndb-dal.jar" do
    owner node['hops']['hdfs']['user']
    group node['hops']['group']
    to "#{node['hops']['dir']}/ndb-hops/#{base_filename}"
  end

  link "#{node['hops']['home']}/lib/native/libndbclient.so" do
    action :delete
    only_if "test -L #{node['hops']['home']}/lib/native/libndbclient.so"
  end
  link "#{node['hops']['home']}/lib/native/libndbclient.so" do
    owner "root"
    group "root"
    to "#{node['mysql']['dir']}/mysql/lib/libndbclient.so"
  end

end

action :format_nn do

  formatMarker="#{node['hops']['tmp_dir']}/.nn_formatted"
  if "#{node['hops']['reformat']}" === "true"
    ::File.delete(formatMarker)
  end
  
  bash 'format-nn' do
    user node['hops']['hdfs']['user']
    group node['hops']['secure_group']
    retries 1
    retry_delay 30
    code <<-EOH
      set -e
      sleep 10 # 10 seconds
      #{node['hops']['base_dir']}/sbin/format-nn.sh
      touch #{formatMarker}
 	  EOH
    not_if {::File.exist?(formatMarker)}
  end
end
