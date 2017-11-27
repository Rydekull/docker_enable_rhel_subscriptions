# docker_enable_rhel_subscriptions

When you use Red Hat Enterprise Linux(RHEL) you need a subscription, this is regardless if its a physical machine, virtual machine or a container. Normally, when running a container on top of a physical RHEL machine the container will automatically obtain the same subscription as the host it is running on. 

If the host is running something other then RHEL, this usually means that you have to add a subscription for every container. Which in turn will consume way more then you need and become very inefficient since it'll require some processing time every time you add a subscription. 

To work around this issue, what this tool does is to:
 - Start up a container with RHEL
 - Subscribe the container using an activation key
 - The resulting subscription that was consumed will be added to the host system
 - Everytime a container starts afterward, adding the correct directories as a volume, it will automatically use the correct subscription

The usage of this tool is for a single host on which you can use one subscription to run multiple RHEL containers, just as it would've been done on a RHEL host.

## Requirements

A user needs the following before they can execute this role:

 - Linux Client with Docker and Ansible installed
 - Internet Connection
 - Red Hat Customer Portal account ( https://access.redhat.com )
 - The organization ID of your account ( Login to the portal and check your profile )
 - Create a new activation key inside the User Portal ( Subscriptions -> Activation Keys )
     or, look up the name of an already existing activation key inside the user portal

## Usage

### Configuration (optional)

You can make the script import the variables for organization id and activation key automatically by creates a file in vars/secrets.yml

```
user@host $ cat vars/secrets.yml 
---
redhat_organization_id: <insert-organization-id-here>
redhat_activationkey_name: <insert-activation-key-here>
user@host $
```

### Obtaining a subscription

```bash
user@host $ bash run-me.sh 
PLAY 1: IMPORTING ANY PRESET VARIABLES FROM SECRETS.YML, IF YOU HAVE THEM SET, JUST PRESS ENTER ON THE FOLLOWING PROMPTS
task 4: 127.0.0.1
Red Hat Organization Number: <INSERT ORGANIZATION ID HERE>
Red Hat Activation Key: <INSERT ACTIVATION KEY HERE>
PLAY 2: STARTING RHEL CONTAINER AND REQUESTING A NEW SUBSCRIPTION
task 2: 127.0.0.1
PLAY 3: FINISHED, SUBSCRIPTION DOWNLOADED. YOU MAY CONTINUE.
user@host $
```

### Consuming the subscription

#### Using a manually started container

```bash
user@host $ docker run -it --rm -v /etc/pki/consumer:/etc/pki/consumer:ro -v /etc/pki/entitlement:/etc/pki/entitlement:ro registry.access.redhat.com/rhel7:latest "yum install httpd -y"
``` 

#### Using Molecule

Inside molecule/defaults/mole
```
platforms:
  - name: instance
    image: registry.access.redhat.com/rhel7:latest
    volumes:
     - /etc/pki/consumer:/etc/pki/consumer:ro
     - /etc/pki/entitlement:/etc/pki/entitlement:ro
```

Fix the Dockerfile.j2 jinja2 template so that it doesn't try to install packages during the build-phase. It should look like this, you can delete the lines if you want too.

```bash
user@host $ cat molecule/default/Dockerfile.j2 
# Molecule managed

FROM {{ item.image }}

#RUN if [ $(command -v apt-get) ]; then apt-get update && apt-get upgrade -y && apt-get install -y python sudo bash ca-certificates && apt-get clean; \
#    elif [ $(command -v dnf) ]; then dnf makecache && dnf --assumeyes install python sudo python-devel python2-dnf bash && dnf clean all; \
#    elif [ $(command -v yum) ]; then yum makecache fast && yum update -y && yum install -y python sudo yum-plugin-ovl bash && sed -i 's/plugins=0/plugins=1/g' /etc/yum.conf && yum clean all; \
#    elif [ $(command -v zypper) ]; then zypper refresh && zypper update -y && zypper install -y python sudo bash python-xml && zypper clean -a; \
#    elif [ $(command -v apk) ]; then apk update && apk add --no-cache python sudo bash ca-certificates; fi
user@host $ 
```

Update molecule/default/prepare.yml with the following:

```
user@host $ cat molecule/default/prepare.yml 
---
- name: Prepare
  hosts: all
  gather_facts: False
  tasks:
  - name: install sudo
    raw: test -e /bin/sudo || (yum install sudo -y)
user@host $
```

Now you can execute your role with:

```
user@host $ molecule test
```

This will start a new container using the already existing subscriptions enabling you to do any yum-commands you wish.


#### Using integration tests for Promoteo-cfg Ansible roles

All you need should be built into docker_manage_hosts, so by referencing that in your requirements.yml, it should do everything you need.

```
$ cat requirements.yml 
---
user@host $
- name: docker_manage_hosts
  src: https://github.com/prometeo-cloud/docker_manage_hosts

- name: vagrant_manage_hosts
  src: https://github.com/prometeo-cloud/vagrant_manage_hosts
user@host $
```

Add your own role to the above, then execute it all with:

```
user@host $ ansible-galaxy install -r requirements.yml -p ./roles
user@host $ ansible-playbook -i inventory site.yml --extra-vars "host_type=docker"
```
