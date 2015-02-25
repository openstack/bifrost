Repo for collaborating on a minimal ironic-based installer.

Deets on the etherpad for now:
    https://etherpad.openstack.org/p/OJYjW3fU9Q

Step 1:

1. cd step1
2. bash ./env-setup.sh
3. source /opt/stack/ansible/hacking/env-setup
4. ansible-playbook -vvvv -i loca1host ./install.yaml
