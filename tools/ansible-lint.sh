#!/bin/bash

set -eu

DEST="$(dirname $0)/../.tox/linters/collections"
SOURCE="${ANSIBLE_COLLECTION_SOURCE_PATH:-../ansible-collections-openstack}"

if [ ! -d "$SOURCE" ]; then
    echo "Cannot find ansible-collections-openstack at $SOURCE"
    exit 1
fi

rm -f "$DEST" || true
mkdir -p "$DEST/ansible_collections/openstack"
rm -f "$DEST/ansible_collections/openstack/cloud"

ln -s "$(realpath $SOURCE)" "$DEST/ansible_collections/openstack/cloud"

export ANSIBLE_COLLECTIONS_PATHS="$(realpath $DEST)"
export ANSIBLE_LIBRARY="$(dirname $0)/../playbooks/library"

find playbooks -maxdepth 1 -type f -regex '.*.ya?ml' -print0 | \
    xargs -t -n1 -0 ansible-lint -vv --nocolor
find playbooks/roles -maxdepth 1 -mindepth 1 -type d -printf "%p/\n" | \
    xargs -t -n1 ansible-lint -vv --nocolor
