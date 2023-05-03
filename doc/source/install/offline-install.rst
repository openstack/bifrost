Offline Installation
--------------------

The ansible scripts that compose Bifrost download and install
software via a number of means, which generally assumes connectivity
to the internet. However, it is possible to use Bifrost without external
connectivity.

If you want or need to install Bifrost without having a dependency on
a connection to the internet, there are a number of steps that you will
need to follow (many of which may have already been done in your
environment anyway).

Those steps can be broken down into two general categories; the first being
steps that need to be done in your inventory file, and the second being
steps that need to be done on your target host outside of Ansible.

Ansible Specific Steps
^^^^^^^^^^^^^^^^^^^^^^

The script ``scripts/env-setup.sh`` will do a ``git clone`` to create
``/opt/stack/ansible``, if it doesn't already exist.  You can use the
environment variables ``ANSIBLE_GIT_URL`` and ``ANSIBLE_GIT_BRANCH``
to override the source URL and the branch name to pull from.

Ansible uses Git submodules, which means if you are cloning from
anything other than the canonical location (GitHub), you'll need
to commit a patched ``.gitmodules`` to that repo so that submodules
are also cloned from an alternate location - otherwise, the submodules
will still try to clone from GitHub.

Bifrost Specific Steps
^^^^^^^^^^^^^^^^^^^^^^

As a general rule, any URL referenced by Bifrost scripts is configured in a
``playbook/roles/<role>/defaults/main.yml`` file, which means that all of
those can be redirected to point to a local copy by creating a file named
``playbooks/host_vars/<hostname>.yml`` and redirecting the appropriate
variables.

As an example, the yaml file's contents may look like something like
this.

.. code-block:: yaml

    ipa_kernel_upstream_url: file:///vagrant/ipa-centos9-master.kernel
    ipa_ramdisk_upstream_url: file:///vagrant/ipa-centos9-master.initramfs
    custom_deploy_image_upstream_url: file:///vagrant/cirros-0.5.3-x86_64-disk.img
    dib_git_url: file:///vagrant/git/diskimage-builder
    ironicclient_git_url: file:///vagrant/git/python-ironicclient
    ironic_git_url: file:///vagrant/git/ironic

If this list becomes out of date, it's simple enough to find the things that
need to be fixed by looking for any URLs in the
``playbook/roles/<role>/defaults/main.yml`` files, as noted above.

Currently you can grep the ``defaults/main.yml`` in Bifrost `repo
<https://opendev.org/openstack/bifrost/src/branch/master/playbooks/roles/bifrost-prep-for-install/defaults/main.yml>`_

For ``kolla-ansible`` you also need the ``sha256sum`` for the ``ipa`` images.

.. code-block:: console

   sha256sum /vagrant/ipa-centos8-master.kernel > /vagrant/ipa-centos8-master.kernel.sha256
   sha256sum /vagrant/ipa-centos8-master.initramfs > /vagrant/ipa-centos8-master.initramfs.sha256

External Steps
^^^^^^^^^^^^^^

Bifrost doesn't attempt to configure ``apt``, ``yum``, or ``pip``,
so if you are working in an offline mode, you'll need to make sure
those work independently.

``pip`` in particular will be sensitive; Bifrost tends to use the most recent
version of python modules, so you'll want to make sure your cache isn't stale.
