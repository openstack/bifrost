# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

import os.path
import shutil
import tempfile
from unittest import mock

from bifrost import cli
from bifrost.tests import base


FILE_NO_BRANCH = """
[gerrit]
host=review.opendev.org
port=29418
project=openstack/bifrost.git
"""


FILE_WITH_BRANCH = """
[gerrit]
host=review.opendev.org
port=29418
project=openstack/bifrost.git
defaultbranch=stable/banana
"""


class TestGetRelease(base.TestCase):
    def setUp(self):
        super().setUp()
        self.temp_dir = tempfile.mkdtemp()
        self.addCleanup(lambda: shutil.rmtree(self.temp_dir))

    def test_provided(self):
        self.assertEqual('stable/ussuri', cli.get_release('ussuri'))
        self.assertEqual('stable/ussuri', cli.get_release('stable/ussuri'))
        self.assertEqual('master', cli.get_release('master'))

    @mock.patch.object(cli, 'BASE', '/non/existing/dir')
    def test_no_file(self):
        self.assertIsNone(cli.get_release(None))

    def test_from_file_no_branch(self):
        with open(os.path.join(self.temp_dir, '.gitreview'), 'wt') as fp:
            fp.write(FILE_NO_BRANCH)
        with mock.patch.object(cli, 'BASE', self.temp_dir):
            self.assertIsNone(cli.get_release(None))

    def test_from_file_with_branch(self):
        with open(os.path.join(self.temp_dir, '.gitreview'), 'wt') as fp:
            fp.write(FILE_WITH_BRANCH)
        with mock.patch.object(cli, 'BASE', self.temp_dir):
            self.assertEqual('stable/banana', cli.get_release(None))
