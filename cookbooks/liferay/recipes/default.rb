tmp_path = Chef::Config[:file_cache_path]

package 'Install OpenJDK' do
    package_name 'java-1.8.0-openjdk'
end

package 'unzip' do
   package_name  'unzip'
end

bash "set the java home " do
  code <<-EOH
    echo "export JRE_HOME=$(readlink -f /usr/bin/java | sed "s:/bin/java::")" >> $HOME/.bash_profile
    echo "export JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:/jre/bin/java::")" >> $HOME/.bash_profile
    source $HOME/.bash_profile
  EOH
end
###########Creating the functional user #######################################
user 'weloadm' do
  comment 'A functional user'
  home '/home/weloadm'
  shell '/bin/bash'
  password 'redhat'
end


###########Create the liferay home directory ###################################
directory node['liferay']['install_location'] do
  owner 'weloadm'
  group 'weloadm'
  recursive true
  mode '0755'
end

remote_file "#{tmp_path}/liferay.zip" do
  source node['liferay']['download_url']
  mode '0777'
  action :create
end

##################unzip the software in liferay home directory ################


#bash 'Extract Liferay and tomcat archive' do
#  cwd node['liferay']['install_location']
#  user 'weloadm'
#  code <<-EOH
#    unzip  #{tmp_path}/liferay.zip -d #{node['liferay']['install_location']}
#  EOH
#end

bash 'Extract Liferay and tomcat archive' do
  cwd node['liferay']['install_location']
  user 'weloadm'
  code <<-EOH
    cp  #{tmp_path}/liferay.zip  #{node['liferay']['install_location']}
    unzip -f  #{node['liferay']['install_location']}/liferay.zip
  EOH
end

#bash "unzip_and_start the service" do
#  code <<-EOH
#    unzip "/tmp/liferay.zip" -d #{node['liferay']['dir']}
#    mv "/var/liferay-ce-portal-7.0-ga3" "/var/liferay/"
#    mkdir -p /var/liferay/liferay-ce-portal-7.0-ga3/deploy/
#    EOH
#end

bash "set the java home in catalina.sh and startup.sh" do
 code <<-EOH
    echo "JRE_HOME=$(readlink -f /usr/bin/java | sed "s:/bin/java::")" >> #{node['tomcat']['path']}/bin/catalina.sh
    echo "JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:/jre/bin/java::")" >> #{node['tomcat']['path']}/bin/catalina.sh
    echo "JRE_HOME=$(readlink -f /usr/bin/java | sed "s:/bin/java::")" >> #{node['tomcat']['path']}/bin/startup.sh
    echo "JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:/jre/bin/java::")" >> #{node['tomcat']['path']}/bin/startup.sh	
  EOH
end

remote_file "#{tmp_path}/ehcache.tar.gz" do
  source node['ehcache']['download_url']
  mode '0777'
  action :create
end


bash "unzip_ehcache and configure it " do
  user 'weloadm'
  code <<-EOH
    tar -xvzf "#{tmp_path}/ehcache.tar.gz" -C #{node['liferay']['install_location']}
    cp #{node['ehcache']['path']}/lib/*.jar   #{node['tomcat']['path']}/lib/
    printf '\n\nCLASSPATH="#{node['ehcache']['path']}/lib/slf4j-jdk14-1.7.25.jar:#{node['ehcache']['path']}/lib/slf4j-api-1.7.25.jar:#{node['ehcache']['path']}/lib/ehcache-2.10.5.jar"' >> #{node['tomcat']['path']}/bin/setenv.sh
    EOH
end
template "#{node['ehcache']['path']}/ehcache.xml" do
  source 'ehcache.erb'
end

template '/etc/systemd/system/liferay.service' do
  source 'liferay.erb'
end

directory "#{node['liferay']['path']}/deploy" do
  owner 'weloadm'
  group 'weloadm'
  mode '0755'
end
cookbook_file "#{node['liferay']['path']}/deploy/licence.xml" do
  source 'licence.xml'
  action :create
end

service 'liferay' do
  action [:enable, :start]
end

