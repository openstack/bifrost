# Copyright (c) 2015 Hewlett-Packard Development Company, L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import contextlib
import tempfile

from bifrost import inventory


@contextlib.contextmanager
def temporary_file(file_data):
    """
    A context manager for a temporary file.

    Args:
        file_data: (str): write your description
    """
    file = None
    file = tempfile.NamedTemporaryFile(mode='w')
    file.write(file_data)
    file.flush()

    try:
        yield file.name
    finally:
        if file is not None:
            file.close()


def bifrost_data_conversion(data):
    """
    Convert inventory data to inventory.

    Args:
        data: (array): write your description
    """
    (groups, hostvars) = inventory._prepare_inventory()
    with temporary_file(data) as file:
        (groups, hostvars) = inventory._process_baremetal_data(
            file,
            groups,
            hostvars)
    return (groups, hostvars)
