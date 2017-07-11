Virtualenv Installation Support
===============================

Bifrost can be used with a Python virtual environment. At present,
this feature is experimental, so it's disabled by default. If you
would like to use a virtual environment, you'll need to modify the
install steps slightly. To set up the virtual environment and install
ansible into it, run ``env-setup.sh`` as follows::

  export VENV=/opt/stack/bifrost
  ./scripts/env-setup.sh

Then run the install playbook with the following arguments::

  ansible-playbook -vvvv -i inventory/target install.yaml

This will install ironic and its dependencies into the virtual environment.
