Repo for collaborating on a minimal ironic-based installer.

Deets on the etherpad for now:
    https://etherpad.openstack.org/p/OJYjW3fU9Q

Step 1:

    cd step1
    bash ./env-setup.sh
    source /opt/stack/ansible/hacking/env-setup
    ansible-playbook -vvvv -i localhost ./install.yaml
