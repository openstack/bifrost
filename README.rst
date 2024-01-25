Bifrost
-------

.. image:: https://governance.openstack.org/tc/badges/bifrost.svg
    :target: https://governance.openstack.org/tc/reference/tags/index.html
    :alt: Team and repository tags

Bifrost (pronounced bye-frost) is a set of Ansible playbooks that
automates the task of deploying a base image onto a set of known hardware using
ironic_. It provides modular utility for one-off operating system deployment
with as few operational requirements as reasonably possible.

The mission of bifrost is to provide an easy path to deploy ironic in
a stand-alone fashion, in order to help facilitate the deployment of
infrastructure, while also being a configurable project that can consume
other OpenStack components to allow users to easily customize the
environment to fit their needs, and drive forward the stand-alone
perspective.

Use cases include:

* Installation of ironic in standalone/noauth mode without other OpenStack
  components.
* Deployment of an operating system to a known pool of hardware as
  a batch operation.
* Testing and development of ironic in the standalone mode.

.. _ironic: https://docs.openstack.org/ironic/latest/

Useful Links
~~~~~~~~~~~~

Bifrost's documentation can be found at:
  https://docs.openstack.org/bifrost/latest

Release notes are at:
  https://docs.openstack.org/releasenotes/bifrost/

The project source code repository is located at:
  https://opendev.org/openstack/bifrost/

Bugs can be filed in launchpad:
  https://launchpad.net/bifrost
