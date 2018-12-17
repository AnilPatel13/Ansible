# Ansible Playbook

Ansible is simply reliable and secure configuration management & automation tool. It is similar to puppet chef and salt, it can configure the server in a very efficient way.

This playbook will install.

  - jdk-8u101-linux-x64
  - hadoop-2.7.2
  - elasticsearch-6.1.1
  - hbase-1.2.6
  - spark-2.2.1
  - zookeeper-3.4.8
  - snappy-1.1.7
  - kafka-1.0
  - kubernethes
  - cassendra
  - kubernethes
  - snappy

# prerequisite.
  - OS should be centos-7
  - Python-2.7.2 should be installed on all server(machines).
  - All the machines should be passwordless ssh enabled.

    ```sh
    # steps to generate ssh keys.
    $ ssh-keygen -t rsa -b 2048
    # you need to just hit enter keys untill keys are generated.
    # for more details type
    $ man ssh-keygen
    # keys will be genrated at ~/.ssh directory
    ```

  - You need to put your public and private keys in ansible/roles/common/templates/ssh-keys.
  - Ansible should be installed in ansible node management(ansible node management is the machine from where you want to install the cluster).
  - You have to create a folder with name files inside ansible/roles/common/
  - You need to download java 1.8 Linux tar and place in ansible/roles/common/file.
  - You need to edit the configuration according to you in ansible/group_vars files.

# Ansible Configurations
- inventory file:- where you have to mention all your machine IP
  example:- consider that I have 3 machines and how to make the entry in inventory.

 machine  | IP-address 
 -------- |--------------
 machine1 | 192.168.1.x 
 machine2 | 192.168.1.y 
 machine3 | 192.168.1.z 

you need to configure your inventory file in such a way that whatever installation you want common for all machine put in a common array. The common array will install java on all machine, disable firewall and also update the system etc. You can find a common file at ansible/roles/common. If you insert any IP from above machine into the master array then it becomes your master machine and it is recommended to have only one IP on the master machine. There is no restriction on slave array you can put as many machine IP address you want for slave machine.

[common]
------------|
192.168.1.x
192.168.1.y
192.168.1.z

[master]
------------|
192.168.1.x
 
[slaves]
------------|
192.168.1.y 
192.168.1.z 


### Installation Steps
Installation of Ansible.
```sh
$ sudo yum -y update
$ sudo yum install ansible -y
# Check the version of Ansible that is installed:
$ ansible --version
```
Once the ansible is installed on your ansible mgmt node you need to clone or download this repository and run the below command in your ansible folder from ansible mgmt node.

```sh
$ ansible-playbook -i inventory -s install.yml
```
once the installation is completed you can login into that machine and verify it.
```sh
# default username is zerocrack & password is also zerocrack
$ su - zerocrack
```
For further reference please refer [https://medium.com/formcept/configuration-management-and-continuous-deployment-cd0892dce998](https://medium.com/formcept/configuration-management-and-continuous-deployment-cd0892dce998)

