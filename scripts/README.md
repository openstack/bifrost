Scripts
=======

This directory contains several scripts used in the OpenStack CI
environment for CI testing of Bifrost, or CI testing that uses Bifrost
to test other projects.

The env-setup.sh script is often used to install initial dependencies.
These are generally not intended for use outside of the OpenStack CI
environment (or similar).

test-bifrost-build-image.sh, test-bifrost-venv.sh, and
test-bifrost-inventory-dhcp.sh are symlinks to test-bifrost.sh
intended to provide backwards compatibility now that all functionality
has been moved to test-bifrost.sh.
