include_attribute "conda"
include_attribute "kagent"
include_attribute "ndb"
include_attribute "kzookeeper"

default['hops']['versions']                    = "2.8.2.2,2.8.2.3,2.8.2.4,2.8.2.5,2.8.2.6,2.8.2.7,2.8.2.8,2.8.2.9,2.8.2.10,3.2.0.0,3.2.0.1,3.2.0.2,3.2.0.3,3.2.0.4"
default['hops']['version']                     = "3.2.0.5-SNAPSHOT"

default['hops']['hdfs']['user']                = node['install']['user'].empty? ? "hdfs" : node['install']['user']
default['hops']['hdfs']['user-home']           = "/home/#{node['hops']['hdfs']['user']}"
default['hops']['group']                       = node['install']['user'].empty? ? "hadoop" : node['install']['user']
default['hops']['secure_group']                = node['install']['user'].empty? ? "metaserver" : node['install']['user']
default['hops']['yarn']['user']                = node['install']['user'].empty? ? "yarn" : node['install']['user']
default['hops']['yarn']['user-home']           = "/home/#{node['hops']['yarn']['user']}"
default['hops']['yarnapp']['user']             = node['install']['user'].empty? ? "yarnapp" : node['install']['user']
default['hops']['yarnapp']['uid']              = 1235
default['hops']['rm']['user']                  = node['install']['user'].empty? ? "rmyarn" : node['install']['user']
default['hops']['rm']['user-home']             = "/home/#{node['hops']['rm']['user']}"
default['hops']['mr']['user']                  = node['install']['user'].empty? ? "mapred" : node['install']['user']
default['hops']['mr']['user-home']             = "/home/#{node['hops']['mr']['user']}"

default['hopsworks']['user']                   = node['install']['user'].empty? ? "glassfish" : node['install']['user']

default['hops']['jmx']['username']             = "monitorRole"
default['hops']['jmx']['password']             = "hadoop"

default['hops']['jmx']['adminUsername']        = "adminRole"
default['hops']['jmx']['adminPassword']        = "hadoopAdmin"

default['hops']['dir']                         = node['install']['dir'].empty? ? "/srv" : node['install']['dir']
default['hops']['base_dir']                    = node['hops']['dir'] + "/hadoop"
default['hops']['home']                        = node['hops']['dir'] + "/hadoop-" + node['hops']['version']

default['hops']['sbin_dir']                    = node['hops']['base_dir'] + "/sbin"
default['hops']['bin_dir']                     = node['hops']['base_dir'] + "/bin"
default['hops']['data_dir']                    = node['hops']['dir'] + "/hopsdata"
default['hops']['logs_dir']                    = node['hops']['base_dir'] + "/logs"
default['hops']['tmp_dir']                     = node['hops']['data_dir'] + "/tmp"
default['hops']['conf_dir_parent']             = node['hops']['base_dir'] + "/etc"
default['hops']['conf_dir']                    = node['hops']['conf_dir_parent'] + "/hadoop"
default['hops']['share_dir']                    = node['hops']['base_dir'] + "/share/hadoop"

default['hops']['enable_cloud_storage']        = "false"
default['hops']['cloud_provider']              = node["install"]["cloud"]
default['hops']['aws_s3_region']               = "eu-west-1"
default['hops']['aws_s3_bucket']               = "hopsfs.bucket"
default['hops']['cloud_bypass_disk_cache']         = "false"
default['hops']['cloud_max_upload_threads']        = "20"
default['hops']['cloud_store_small_files_in_db']   = "true"
default['hops']['disable_non_cloud_storage_policies']       = "false"
default['hops']['nn']['cloud_max_br_threads']               = "10"
default['hops']['nn']['root_dir_storage_policy']       = ""

default['hops']['dn']['data_dir']                       = "file://" + node['hops']['data_dir'] + "/hdfs/dn"
default['hops']['dn']['data_dir_permissions']           = '700'
default['hops']['nn']['name_dir']                       = "file://" + node['hops']['data_dir'] + "/hdfs/nn"

default['hops']['yarn']['nodemanager_recovery_dir']          = node['hops']['data_dir'] + "/yarn-nm-recovery"

default['hops']['hdfs']['user_home']           = "/user"
default['hops']['hdfs']['apps_dir']            = "/apps"
default['hops']['hdfs']['blocksize']           = "134217728"
default['hops']['hdfs']['umask']               = "0007"



default['hops']['root_url']                    = node['download_url']
default['hops']['dist_url']                    = node['hops']['root_url'] + "/hops-" + node['hops']['version'] + ".tgz"

default['hops']['install_protobuf']            = "false"
default['hops']['protobuf_url']                = "https://protobuf.googlecode.com/files/protobuf-2.5.0.tar.gz"
default['hops']['hadoop_src_url']              = "https://archive.apache.org/dist/hadoop/core/hadoop-" + node['hops']['version'] + "/hadoop-" + node['hops']['version'] + "-src.tar.gz"
default['hops']['nn']['http_port']             = 50070
default['hops']['dn']['http_port']             = 50075
default['hops']['nn']['port']                  = 8020
default['hops']['dn']['port']                  = 50010
default['hops']['dn']['ipc_port']              = 50020

default['hops']['nn']['format_options']        = "-format -nonInteractive"

default['hops']['leader_check_interval_ms']    = 1000
default['hops']['missed_hb']                   = 1
default['hops']['num_replicas']                = 3
default['hops']['db']                          = "hops"
default['hops']['nn']['scripts']               = %w{ start-nn.sh stop-nn.sh restart-nn.sh }
default['hops']['dn']['scripts']               = %w{ start-dn.sh stop-dn.sh restart-dn.sh }
default['hops']['max_retries']                 = 0
default['hops']['retry_policy_spec']           = "1000,3"
default['hops']['retry_policy_enabled']         = "true"
default['hops']['reformat']                    = "false"
default['hops']['format']                      = "true"
default['hops']['io_buffer_sz']                = 131072
default['hops']['container_cleanup_delay_sec'] = 0

default['hops']['clusterj']['max_sessions']               = 1000 
default['hops']['clusterj']['session_max_reuse_count']    = 5000 
default['hops']['clusterj']['enable_dto_cache']           = "false" 
default['hops']['clusterj']['enable_session_cache']       = "false" 


default['hops']['nn']['replace-dn-on-failure']        = "true"
default['hops']['nn']['replace-dn-on-failure-policy'] = "NEVER" 

default['hops']['yarn']['scripts']             = %w{ start stop restart }
default['hops']['yarn']['ps_port']             = 20888

case node['platform_family']
when "debian"
default['hops']['yarn']['vpmem_ratio']         = "50.1"
default['hops']['yarn']['vmem_check']          = true
when "rhel"
default['hops']['yarn']['vpmem_ratio']         = "50.1"
default['hops']['yarn']['vmem_check']          = false
end
default['hops']['yarn']['pmem_check']          = "true"

default['hops']['yarn']['detect-hardware-capabilities'] = "true"
default['hops']['yarn']['logical-processors-as-cores']  = "true"
default['hops']['yarn']['pcores-vcores-multiplier']     = "0.9"
default['hops']['yarn']['system-reserved-memory-mb']    = "-1"

default['hops']['yarn']['vcores']              = 8
default['hops']['yarn']['min_vcores']          = 1
default['hops']['yarn']['max_vcores']          = 8
default['hops']['yarn']['log_aggregation']     = "true"
default['hops']['yarn']['nodemanager']['remote_app_log_dir'] = "#{node['hops']['hdfs']['user_home']}/#{node['hops']['yarn']['user']}/logs"
default['hops']['yarn']['log_retain_secs']     = 86400
default['hops']['yarn']['log_retain_check']    = 100
default['hops']['yarn']['log_roll_interval']    = 3600

default['hops']['yarn']['nodemanager_hb_ms']   = "1000"

default['hops']['yarn']['max_connect_wait']   = "900000"

default['hops']['am']['max_attempts']           = 2

default['hops']['yarn']['aux_services']        = "spark_shuffle,mapreduce_shuffle"

default['hops']['mr']['shuffle_class']         = "org.apache.hadoop.mapred.ShuffleHandler"

default['hops']['yarn']['app_classpath']       = "#{node['hops']['home']},
                                                  #{node['hops']['home']}/lib/*,
                                                  #{node['hops']['home']}/etc/hadoop/,
                                                  #{node['hops']['home']}/share/hadoop/common/*,
                                                  #{node['hops']['home']}/share/hadoop/common/lib/*,
                                                  #{node['hops']['home']}/share/hadoop/hdfs/*,
                                                  #{node['hops']['home']}/share/hadoop/hdfs/lib/*,
                                                  #{node['hops']['home']}/share/hadoop/yarn/*,
                                                  #{node['hops']['home']}/share/hadoop/yarn/lib/*,
                                                  #{node['hops']['home']}/share/hadoop/tools/lib/*,
                                                  #{node['hops']['home']}/share/hadoop/mapreduce/*,
                                                  #{node['hops']['home']}/share/hadoop/mapreduce/lib/*"
#                                                  #{node['hops']['home']}/share/hadoop/yarn/test/*,
#                                                  #{node['hops']['home']}/share/hadoop/mapreduce/test/*"


default['hops']['rm']['scheduler_class']       = "org.apache.hadoop.yarn.server.resourcemanager.scheduler.capacity.CapacityScheduler"

default['hops']['mr']['tmp_dir']               = "/mapreduce"
default['hops']['mr']['staging_dir']           = "#{default['hops']['mr']['tmp_dir']}/#{default['hops']['mr']['user']}/staging"

default['hops']['jhs']['root_dir']             = "/mr-history"
default['hops']['jhs']['inter_dir']            = "#{node['hops']['jhs']['root_dir']}/done_intermediate"
default['hops']['jhs']['done_dir']             = "#{node['hops']['jhs']['root_dir']}/done"

# YARN CONFIG VARIABLES
# http://hadoop.apache.org/docs/current/hadoop-yarn/hadoop-yarn-common/yarn-default.xml
# If you need mapreduce, mapreduce.shuffle should be included here.
# You can have a comma-separated list of services
# http://hadoop.apache.org/docs/r2.1.0-beta/hadoop-mapreduce-client/hadoop-mapreduce-client-core/PluggableShuffleAndPluggableSort.html

default['hops']['nn']['jmxport']               = "8077"
default['hops']['dn']['jmxport']               = "8078"
default['hops']['rm']['jmxport']               = "8082"
default['hops']['nm']['jmxport']               = "8083"

default['hops']['nn']['public_ips']            = ['10.0.2.15']
default['hops']['nn']['private_ips']           = ['10.0.2.15']
default['hops']['dn']['private_ips']           = ['10.0.2.15']
default['hops']['rm']['private_ips']           = ['10.0.2.15']
default['hops']['nm']['private_ips']           = ['10.0.2.15']

# comma-separated list of namenode addrs
default['hops']['nn']['addrs']                 = []

# build the native libraries. Is much slower, but removes warning when using services.
default['hops']['native_libraries']            = "false"

default['maven']['version']                    = "3.2.5"
default['maven']['checksum']                   = ""


default['hops']['yarn']['memory_mbs']          = 12000

default['hops']['yarn']['min_allocation_memory_mb']          = 128
default['hops']['yarn']['max_allocation_memory_mb'] = 64000

default['hops']['limits']['nofile']            = '32768'
default['hops']['limits']['nproc']             = '65536'
default['hops']['limits']['memory_limit']      = '100000'

default['hops']['logging_level']               = "INFO"
default['hops']['ha_enabled']                  = "false"

default['hops']['systemd']                     = "true"

default['hops']['log']['maxfilesize']          = "256MB"
default['hops']['log']['maxbackupindex']       = 10

# Retention period for Hadoop log copied over to HDFS
# Value suffix can be
# ms - milliseconds
# s - seconds
# m - minutes
# h - hours
# d - days
default['hops']['log']['remote_retention']     = "150d"


###################################################################
###################################################################
###################################################################
###################################################################

# set the location of libndbclient.so. set-env.sh sets LD_LIBRARY_PATH to find this library.
default['ndb']['libndb']                    = "#{node['mysql']['version_dir']}/lib"
default['mysql']['port']                    = default['ndb']['mysql_port']

default['hops']['schema_dir']               = "#{node['hops']['root_url']}/hops-schemas"

default['hops']['ndb']['version']              = "21.04.0"

if node['hops']['ndb']['version'] != ""
  node.override['ndb']['version'] = node['hops']['ndb']['version']
end

default['dal']['download_url']              = "#{node['hops']['root_url']}/ndb-dal-#{node['hops']['version']}-#{node['ndb']['version']}.jar"

default['hops']['recipes']                  = %w{ nn dn rm nm jhs ps }

# limits.d settings
default['hops']['limits']['nofile']         = '32768'
default['hops']['limits']['nproc']          = '65536'

default['hops']['jhs']['https']['port']     = "19443"
default['hops']['rm']['https']['port'] 	    = "8090"
default['hops']['nm']['https']['port']      = "45443"

default['hops']['yarn']['resource_tracker'] = "false"
default['hops']['nn']['direct_memory_size'] = 1000
default['hops']['nn']['heap_size']          = 1000

default['hops']['nn']['private_ips']        = ['10.0.2.15']
default['hops']['dn']['private_ips']        = ['10.0.2.15']
default['hops']['rm']['private_ips']        = ['10.0.2.15']
default['hops']['nm']['private_ips']        = ['10.0.2.15']

default['hops']['erasure_coding']           = "false"

default['hops']['nn']['cache']                 = "true"
default['hops']['nn']['partition_key']         = "true"

default['vagrant']                       = "false"

default['hops']['reverse_dns_lookup_supported']    = "false"

default['hops']['use_systemd']              = "false"
default['hops']['nn']['format_options']        = "-formatAll"

default['hops']['trash']['interval']           = 360
default['hops']['trash']['checkpoint']['interval']= 60

default['hops']['yarn']['resourcemanager_ha_enabled']            = "false"
default['hops']['yarn']['resourcemanager_auto_failover_enabled'] = "false"
default['hops']['yarn']['nodemanager_recovery_enabled']      = "true"
default['hops']['yarn']['nodemanager_recovery_supervised']      = "true"
default['hops']['yarn']['resourcemanager_recovery_enabled']      = "true"
# NM heartbeats need to be at least twice as long as NDB transaction timeouts


default['hops']['yarn']['rm_heartbeat']                      = 1000
default['hops']['yarn']['quota']['enabled']                  = "true"
default['hops']['yarn']['quota']['price']['base_general']    = 1
default['hops']['yarn']['quota']['price']['base_gpu']        = 1
default['hops']['yarn']['quota']['min_runtime']              = 10000
default['hops']['yarn']['quota']['price']['mb_unit']         = 1024
default['hops']['yarn']['quota']['price']['gpu_unit']        = 1
default['hops']['yarn']['quota']['period']                   = 10000
default['hops']['yarn']['quota']['price']['variable']        = "true"
default['hops']['yarn']['quota']['price']['variable_interval'] = 10000
default['hops']['yarn']['quota']['price']['multiplicator_threshold_general'] = 0.2
default['hops']['yarn']['quota']['price']['multiplicator_threshold_gpu'] = 0.2
default['hops']['yarn']['quota']['price']['multiplicator_general'] = 1
default['hops']['yarn']['quota']['price']['multiplicator_gpu'] = 1
default['hops']['yarn']['quota']['poolsize']                 = 10
default['hops']['yarn']['nm_heapsize_mbs']                   = 1000
default['hops']['yarn']['rm_heapsize_mbs']                   = 1000

## SSL Config Attributes##

#hdfs-site.xml
default['hops']['dfs']['https']['enable']                    = "true"
default['hops']['dfs']['http']['policy']   		             = "HTTPS_ONLY"
default['hops']['dn']['https']['address'] 	            = "0.0.0.0:50475"
default['hops']['nn']['https']['port']                      = "50470"

default['hops']['dfs']['inodeid']['batchsize']              = "10000"
default['hops']['dfs']['blockid']['batchsize']              = "10000"

default['hops']['dfs']['processReport']['batchsize']                   = "10"
default['hops']['dfs']['misreplicated']['batchsize']                   = "500"
default['hops']['dfs']['misreplicated']['noofbatches']                 = "20"
default['hops']['dfs']['replication']['max_streams']                   = "50"
default['hops']['dfs']['replication']['max_streams_hard_limit']        = "100"
default['hops']['dfs']['replication']['work_multiplier_per_iteration']  = "2"

default['hops']['dfs']['balance']['max_concurrent_moves']              = "50"

#default no retries for move operation is 10. 
default['hops']['dfs']['mover']['retry_max_attempts']                  = "20"

default['hops']['dfs']['excluded_hosts']                               = ""

default['hops']['fs-security-actions']['actor_class']                  = "io.hops.common.security.DevHopsworksFsSecurityActions"
default['hops']['fs-security-actions']['x509']['get-path']             = "/hopsworks-api/api/admin/credentials/x509"

#yarn-site.xml
default['hops']['yarn']['container_executor']                = "org.apache.hadoop.yarn.server.nodemanager.LinuxContainerExecutor"

# Use Cgroup isolation
default['hops']['yarn']['cgroups']                        = "true"
default['hops']['yarn']['cgroups_deletion_timeout']       = "5000"
default['hops']['yarn']['cgroups_max_cpu_usage']          = "90"
default['hops']['yarn']['cgroups_strict_resource_usage']  = "false"

#ssl-server.xml
default['hops']['ssl']['server']['keystore']['password']   		= node['hopsworks']['master']['password']
default['hops']['ssl']['server']['keystore']['keypassword']   		= node['hopsworks']['master']['password']

## Keystore and truststore locations are substitued in recipes/default.rb
## They should be removed from here. They are not used anywhere
default['hops']['ssl']['server']['keystore']['location'] 		= "#{node['kagent']['keystore_dir']}/node_server_keystore.jks"
default['hops']['ssl']['server']['truststore']['location']   		= "#{node['kagent']['keystore_dir']}/node_server_truststore.jks"
##

default['hops']['ssl']['server']['truststore']['password']     	 	= node['hopsworks']['master']['password']

#ssl-client.xml

default['hops']['ssl']['client']['truststore']['password']		= node['hopsworks']['master']['password']
default['hops']['ssl']['client']['truststore']['location']		= "#{node['kagent']['keystore_dir']}/node_client_truststore.jks"

# Number of reader threads of the IPC/RPC server
# Default is 1, when TLS is enabled it is advisable to increase it
default['hops']['server']['threadpool'] = 3

# RPC TLS
default['hops']['tls']['enabled'] = "false"

# Do not verify the hostname
default['hops']['hadoop']['ssl']['hostname']['verifier']                = "ALLOW_ALL"
# Socket factory for the client
default['hops']['hadoop']['rpc']['socket']['factory']                   = "org.apache.hadoop.net.HopsSSLSocketFactory"
default['hops']['hadoop']['ssl']['enabled']['protocols']                = "TLSv1.2,TLSv1.1"
default['hops']['rmappsecurity']['actor_class']                         = "org.apache.hadoop.yarn.server.resourcemanager.security.DevHopsworksRMAppSecurityActions"

default['hops']['rmappsecurity']['x509']['expiration_safety_period']    = "2d"
default['hops']['rmappsecurity']['x509']['revocation_monitor_interval'] = "12h"
default['hops']['rmappsecurity']['x509']['sign-path']                   = "/hopsworks-ca/v2/certificate/app"
default['hops']['rmappsecurity']['x509']['revoke-path']                 = "/hopsworks-ca/v2/certificate/app"
default['hops']['rmappsecurity']['x509']['key-size']                    = "2048"

default['hops']['rmappsecurity']['jwt']['enabled']                      = "true"
default['hops']['rmappsecurity']['jwt']['validity']                     = "30m"
default['hops']['rmappsecurity']['jwt']['expiration-leeway']            = "5m"
# Comma separated list of JWT audience
default['hops']['rmappsecurity']['jwt']['audience']                     = "job"
default['hops']['rmappsecurity']['jwt']['generate-path']                = "/hopsworks-api/api/jwt"
default['hops']['rmappsecurity']['jwt']['invalidate-path']              = "/hopsworks-api/api/jwt/key"
default['hops']['rmappsecurity']['jwt']['renew-path']                   = "/hopsworks-api/api/jwt"

# Set to 'true' if you want production TLS certificates.
default['hops']['tls']['prod']                                          = "false"

# CRL validation when RPC TLS is enabled - by default enabled it if TLS is enabled.
default['hops']['tls']['crl_enabled']                                   = "#{node['hops']['tls']['enabled']}"
default['hops']['tls']['crl_fetcher_class']                             = "org.apache.hadoop.security.ssl.DevRemoteCRLFetcher"
default['hops']['tls']['crl_fetch_path']                                = "/hopsworks-ca/v2/certificate/crl/intermediate"
default['hops']['tls']['crl_output_file']                               = "#{node['hops']['tmp_dir']}/hops_crl.pem"
default['hops']['tls']['crl_fetcher_interval']                          = "5m"

# Service JWT properties
default['hops']['jwt-manager']['master-token-validity']                 = "7d"
default['hops']['jwt-manager']['renew-path']                            = "/hopsworks-api/api/jwt/service"
default['hops']['jwt-manager']['invalidate-path']                       = "/hopsworks-api/api/jwt/service"

# DataNode Data Transfer Protocol encryption
default['hops']['encrypt_data_transfer']['enabled']                     = "false"
default['hops']['encrypt_data_transfer']['algorithm']                   = "3des"

#capacity scheduler queue configuration
default['hops']['capacity']['max_app']                                  = 10000
default['hops']['capacity']['max_am_percent']                           = 0.3
default['hops']['capacity']['resource_calculator_class']                = "org.apache.hadoop.yarn.util.resource.DominantResourceCalculator"
default['hops']['capacity']['root_queues']                              = "default"
default['hops']['capacity']['default_capacity']                         = 100
default['hops']['capacity']['user_limit_factor']                        = 1
default['hops']['capacity']['default_max_capacity']                     = 100
default['hops']['capacity']['default_state']                            = "RUNNING"
default['hops']['capacity']['default_acl_submit_applications']          = "*"
default['hops']['capacity']['default_acl_administer_queue']             = "*"
default['hops']['capacity']['queue_mapping']                            = ""
default['hops']['capacity']['queue_mapping_override']['enable']         = "false"

#
# Flyway - Database upgrades
#
default['hops']['flyway']['version']                                    = "6.5.1"
default['hops']['flyway_url']                                           = node['hops']['root_url'] + "/flyway-commandline-#{node['hops']['flyway']['version']}-linux-x64.tar.gz"

default['hops']['yarnapp']['home_dir']                 = "/home"

#Store Small files in NDB
default['hops']['small_files']['store_in_db']                                       = "true"
default['hops']['small_files']['max_size']                                          = 65536
default['hops']['small_files']['on_disk']['max_size']['small']                      = 2000
default['hops']['small_files']['on_disk']['max_size']['medium']                     = 4000
default['hops']['small_files']['on_disk']['max_size']['large']                      = 65536
default['hops']['small_files']['in_memory']['max_size']                             = 1024

default['hopsmonitor']['default']['private_ips']                                    = ['10.0.2.15']
default['hopsworks']['default']['private_ips']                                      = ['10.0.2.15']

# Kernel tuning
default['hops']['kernel']['somaxconn']                  = 4096
default['hops']['kernel']['swappiness']                 = 1
default['hops']['kernel']['overcommit_memory']          = 1
default['hops']['kernel']['overcommit_ratio']           = 100

#LocationDomainId
default['hops']['nn']['private_ips_domainIds']        = {}
default['hops']['dn']['private_ips_domainIds']        = {}
default['hops']['topology']                           = "false"

# Monitoring
default['hops']['jmx']['prometheus_exporter']['version']  = "0.12.0"
default['hops']['jmx']['prometheus_exporter']['url']      = "#{node['download_url']}/prometheus/jmx_prometheus_javaagent-#{node['hops']['jmx']['prometheus_exporter']['version']}.jar"

default['hops']['nn']['metrics_port']                     = "19850"
default['hops']['dn']['metrics_port']                     = "19851"
default['hops']['nm']['metrics_port']                     = "19852"
default['hops']['rm']['metrics_port']                     = "19853"

default['hops']['nn']['enable_retrycache']            = "true"

default['hops']['hdfs']['quota_enabled']              = "true"
default['hops']['nn']['handler_count']                = 120
default['hops']['nn']['subtree-executor-limit']       = 40
default['hops']['nn']['tx_retry_count']               = 5

default['hops']['gcp_url']                            = node['hops']['root_url'] + "/gcs-connector-hadoop2-latest.jar"


default['hops']['s3a']['sse_algorithm']        = ""
default['hops']['s3a']['sse_key']              = ""

default['hops']['adl_v1_version']                     = "2.3.8"
default['hops']['adl_v1_url']                         = node['hops']['root_url'] + "/azure-data-lake-store-sdk-" + node['hops']['adl_v1_version'] + ".jar"

#GPU
default['hops']['gpu']                                = "false"

#DOCKER
default['hops']['docker']['enabled']                  = "true"
default['hops']['docker_version']['ubuntu']           = "19.03.6-0ubuntu1~18.04.*"
default['hops']['docker_version']['centos']           = "19.03.8-3"
default['hops']['selinux_version']['centos']          = "2.119.1-1.c57a6f9"
default['hops']['containerd_version']['ubuntu']       = "1.2.6-0ubuntu1~18.04*"
default['hops']['containerd_version']['centos']       = "1.2.13-3.1"
default['hops']['docker_img_version']                 = node['install']['version']
default['hops']['docker_dir']                         = node['install']['dir'].empty? ? "/var/lib/docker" : "#{node['install']['dir']}/docker"
default['hops']['docker']['insecure_registries']      = ""
default['hops']['docker']['trusted_registries']       = ""
default['hops']['docker']['mounts']                   = "#{node['hops']['conf_dir']},#{node['hops']['dir']}/spark,#{node['hops']['dir']}/flink,#{node['hops']['dir']}/apache-livy"
default['hops']['docker']['base']['image']['name']           = "base"
default['hops']['docker']['base']['image']['python']['name']  = "python37"
default['hops']['docker']['base']['image']['python']['version'] = "3.7"
default['hops']['docker']['base']['download_url']     = "#{node['download_url']}/kube/docker-images/#{node['hops']['docker_img_version']}/base.tar"
default['hops']['cgroup-driver']                      = "cgroupfs"
default['hops']['docker']['registry']['port']         = 4443
default['hops']['docker']['registry']['download_url'] = "#{node['download_url']}/kube/docker-images/registry_image.tar"
default['hops']['docker']['pkg']['download_url']['centos'] ="#{node['download_url']}/docker/#{node['hops']['docker_version']['centos']}/rhel"
default['hops']['nvidia_pkgs']['download_url']        ="#{node['download_url']}/kube/nvidia"

#XAttrs
default['hops']['xattrs']['enabled']                  = "true"
default['hops']['xattrs']['max-xattrs-per-inode']     = 32
default['hops']['xattrs']['max-xattr-size']           = 1039755

#ACL
default['hops']['acl']['enabled']                     = "true"

#Cache tour files locally for cloud setup
default["hops"]["cloud_tours_cache"]['base_dir']   = "#{node['hops']['hdfs']['user-home']}/tours_cache"
default["hops"]["cloud_tours_cache"]['info_csv']   = "tours_info.csv"

default['hops']['yarn']['is-elastic']              = "false"

# Audit logs
default['hops']['nn']['audit_log']                 = "false"
default['hops']['rm']['audit_log']                 = "false"
