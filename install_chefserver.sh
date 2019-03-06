#!/bin/bash

mkdir ~/downloads
mkdir ~/drop
wget -nv -P ~/downloads https://packages.chef.io/files/stable/chef-server/12.19.26/ubuntu/18.04/chef-server-core_12.19.26-1_amd64.deb
wget -nv -P ~/downloads https://packages.chef.io/files/stable/chefdk/3.7.23/ubuntu/18.04/chefdk_3.7.23-1_amd64.deb
dpkg -i ~/downloads/chef-server-core_12.19.26-1_amd64.deb
dpkg -i ~/downloads/chefdk_3.7.23-1_amd64.deb
#chef-server-ctl reconfigure >> ~/chef_server_reconfigure1.log
#chef-server-ctl cleanse >> ~/chef_cleanse.log
chef-server-ctl reconfigure >> ~/chef_server_reconfigure2.log

until (curl -D - http://localhost:8000/_status) | grep "200 OK"; do sleep 15s; done
while (curl http://localhost:8000/_status) | grep "fail"; do sleep 15s; done

chef-server-ctl user-create gmortel Gerard Mortel gmortel@us.ibm.com 'abc123' --filename ~/drop/gmortel.pem
chef-server-ctl org-create ibmodc 'IBM On Demand Consulting' --association_user gmortel --filename ~/drop/ibmodc.pem
chef-server-ctl install chef-manage
chef-server-ctl reconfigure
chef-manage-ctl reconfigure
