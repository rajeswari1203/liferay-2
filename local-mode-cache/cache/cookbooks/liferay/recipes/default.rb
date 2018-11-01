tmp_path = Chef::Config[:file_cache_path]

package 'unzip' do
   package_name  'unzip'
end
bash "set the java home " do
  cwd "/opt/SP/weloadm/software"
  code <<-EOH
     wget --no-check-certificate -c --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/8u191-b12/2787e4a523244c269598db4e85c51e0c/jdk-8u191-linux-x64.tar.gz
     tar -zxvf jdk*
   EOH
   end
 ruby_block 'Set JAVA_HOME in /etc/environment' do
    block do
      file = Chef::Util::FileEdit.new('/root/.bash_profile')
      file.insert_line_if_no_match(/export JAVA_HOME=/, "export JAVA_HOME=#{node['java']['java_home']}")
      file.insert_line_if_no_match(/export JRE_HOME=/, "export JRE_HOME=#{node['java']['jre_home']}")
      file.insert_line_if_no_match(/export PATH=/, "export PATH=$PATH:$JAVA_HOME/bin/:$JRE_HOME/bin")
      file.write_file
    end
  end
bash "set the java home " do
  code <<-EOH
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

#remote_file "#{tmp_path}/liferay.zip" do
 # source node['liferay']['download_url']
  #mode '0777'
  #action :create
#end

##################unzip the software in liferay home directory ################


#omcat archive' do
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
    #cp  #{tmp_path}/liferay.zip  #{node['liferay']['install_location']}
    unzip  liferay.zip
  EOH
end
directory "/opt/SP/weloadm/software/liferay-ce-portal-7.0-ga3/deploy" do
 
end
ruby_block 'Set JAVA_HOME in catalina' do
    block do
      file = Chef::Util::FileEdit.new("#{node['tomcat']['path']}/bin/catalina.sh")
      file.insert_line_if_no_match(/export JAVA_HOME=/, "export JAVA_HOME=#{node['java']['java_home']}")
      file.insert_line_if_no_match(/export JRE_HOME=/, "export JRE_HOME=#{node['java']['jre_home']}")
      file.write_file
    end
  end
ruby_block 'Set JAVA_HOME in startup' do
    block do
      file = Chef::Util::FileEdit.new("#{node['tomcat']['path']}/bin/startup.sh")
      file.insert_line_if_no_match(/export JAVA_HOME=/, "export JAVA_HOME=#{node['java']['java_home']}")
      file.insert_line_if_no_match(/export JRE_HOME=/, "export JRE_HOME=#{node['java']['jre_home']}")
      file.write_file
    end
  end

#remote_file "#{tmp_path}/ehcache.tar.gz" do
 # source node['ehcache']['download_url']
  #mode '0777'
  #action :create
#end


bash "unzip_ehcache and configure it " do
 cwd node['liferay']['install_location']
  user 'weloadm'
  code <<-EOH
    tar -xvzf  ehcache-*
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

