#!/usr/bin/env python

# Copyright (c) 2017 Mirantis Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Helper script to choose which ansible version to install for bifrost"""

from __future__ import print_function
import sys

import six

in_str = sys.argv[1]
HELP_MSG = ("Unsupported version or format %s - "
            "Supporting format [stable-]MAJ.MIN where MAJ.MIN is 1.9 or 2.x"
            % in_str)

if in_str.startswith('stable-'):
    in_version = in_str.split('stable-')[1]
else:
    if six.text_type(in_str[0]).isdecimal():
        print("ansible==%s" % in_str)
    else:
        print("ansible%s" % in_str)
    sys.exit(0)

if len(in_version) != 3 and in_version[1] != '.':
    print(HELP_MSG)
    sys.exit(1)
else:
    maj_version = in_version[0]
    try:
        min_version = int(in_version[2])
    except ValueError:
        print(HELP_MSG)
        sys.exit(1)

if maj_version == '1' and min_version == 9:
    upper_bound = '2.0'
elif maj_version == '2':
    upper_bound = '2.%i' % (min_version + 1)
else:
    print(HELP_MSG)
    sys.exit(1)

print("ansible<%s" % upper_bound)
