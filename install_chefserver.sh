#!/bin/bash

# Create directories
mkdir ~/downloads
mkdir ~/drop

# Prepare the Chef repository, .chef directory and cookbooks directories
mkdir -p ~/chef-repo/.chef
mkdir -p ~/chef-repo/cookbooks

# Download Chef server and Chef development kit
wget -nv -P ~/downloads https://packages.chef.io/files/stable/chef-server/12.19.26/ubuntu/18.04/chef-server-core_12.19.26-1_amd64.deb
wget -nv -P ~/downloads https://packages.chef.io/files/stable/chefdk/3.7.23/ubuntu/18.04/chefdk_3.7.23-1_amd64.deb

# Install Chef server and Chef development kit
dpkg -i ~/downloads/chef-server-core_12.19.26-1_amd64.deb
dpkg -i ~/downloads/chefdk_3.7.23-1_amd64.deb

# Reconfigure Chef server
chef-server-ctl reconfigure >> ~/chef_server_reconfigure1.log

# Sleep for 5 minutes to let things quiet down
sleep 300s

# Everything from here on fails so need to log in and run from here on manually
chef-server-ctl cleanse
chef-server-ctl reconfigure

# Wait for the Chef server to come up after reconfiguring
until (curl -D - http://localhost:8000/_status) | grep "200 OK"; do echo "Sleep for 15 seconds until 200 OK appears when running curl http://localhost:8000/_status" ; sleep 15s; done
while (curl http://localhost:8000/_status) | grep "fail"; do echo "Sleep for 15 seconds while fail keeps appearing when running curl http://localhost:8000/_status" ; sleep 15s; done

# Create a Chef user
chef-server-ctl user-create gmortel Gerard Mortel gmortel@us.ibm.com 'abc123' --filename ~/chef-repo/.chef/gmortel.pem

# Create an Chef organization
chef-server-ctl org-create ibmodc 'IBM On Demand Consulting' --association_user gmortel --filename ~/chef-repo/.chef/ibmodc.pem

# Install the Chef management UI
chef-server-ctl install chef-manage

# Reconfigure the Chef server
chef-server-ctl reconfigure

# Reconfigure the Chef manager and automatically accept the license
chef-manage-ctl reconfigure --accept-license

# Copy the Chef user pem file to /etc/chef/ to use for bootstrapping
cp ~/chef-repo/.chef/gmortel.pem /etc/chef/

# Prepare the client.rb file to bootstrap server
cat << EOF >> /etc/chef/client.rb
chef_server_url        'https://chef2.odc.ibm.cloud.com/organizations/ibmodc'  
validation_key         '/etc/chef/gmortel.pem'
validation_client_name 'gmortel' 
ssl_verify_mode        :verify_none
EOF

# Bootstrap server
chef-client

# Prepare the config.rb to upload Chef recipes
cat << EOF >> ~/chef-repo/.chef/config.rb
current_dir = File.dirname(__FILE__)
log_level                :info
log_location             STDOUT
node_name                'gmortel'
client_key               "#{current_dir}/gmortel.pem"
validation_client_name   'ibmodc'
validation_key           "#{current_dir}/ibmodc.pem"
chef_server_url          'https://chef2.odc.ibm.cloud.com/organizations/ibmodc'
cache_type               'BasicFile'
cache_options( :path => "#{ENV['HOME']}/.chef/checksums" )
ssl_verify_mode          :verify_none
cookbook_path            ["#{current_dir}/../cookbooks"]
EOF

# Download Chef recipes
mkdir ~/git
cd ~/git
git clone https://github.com/gerardmortel/cookbook_ibm_workflow_multios.git
git clone https://github.com/IBM-CAMHub-Open/cookbook_ibm_cloud_utils_multios.git
git clone https://github.com/IBM-CAMHub-Open/cookbook_ibm_utils_linux.git

# Copy chef recipes to ~/chef-repo/cookbooks directory
cp -R ~/git/cookbook_ibm_workflow_multios/chef/cookbooks/workflow ~/chef-repo/cookbooks/
cp -R ~/git/cookbook_ibm_utils_linux/chef/cookbooks/linux ~/chef-repo/cookbooks/
cp -R ~/git/cookbook_ibm_cloud_utils_multios/chef/cookbooks/ibm_cloud_utils ~/chef-repo/cookbooks/

# Upload chef recipes
cd ~/chef-repo
knife cookbook upload --all
