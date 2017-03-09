#!/usr/bin/env python
#
# Copyright (c) 2017 Mirantis Inc
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

"""Helper script to cut down number of etries in JSON baremetal data file.

Splits the JSON file containing a top-level dict structure into two files,
where first has at most N entries, and the second has the rest of them.

Uses OrderedDict to preserve ordering of dict elements in input JSON file.
"""

from __future__ import print_function

import collections
import json
import os
import sys

HELP_MSG = """
Usage:
    python %s <N> <input> <first> <second>

where:
    N - max number of dict elements to be defined in the <first> JSON file
    input - path to input JSON file
    <first> - path to first output JSON file containig at most N entries
    <second> - path to the second output JSON file containig the rest
""" % sys.argv[0]


def fail(msg=None):
    if msg:
        print("Error: %s" % msg)
        print()
    print(HELP_MSG)
    sys.exit(1)


def parse_args(args):

    if len(args) != 4:
        fail("Wrong number of arguments")
    num, infile, out1, out2 = args

    try:
        num = int(num)
    except ValueError:
        fail("First argument is not integer")

    if not os.path.isfile(infile):
        fail("Input file %s does not exist or can not be accessed." % infile)
    return num, infile, out1, out2


def write_to_json(fname, data):
    with open(fname, 'w') as of:
        try:
            json.dump(data, of, indent=4)
        except Exception as ex:
            fail("Failed to save data to %s file - Error %s" % (fname, ex))


def split_json_dict(args):
    num, infile, out1, out2 = parse_args(args)
    data = {}
    with open(infile) as f:
        data = json.load(f, object_pairs_hook=collections.OrderedDict)
    if not data:
        fail("Baremetal data file %s is empty or non-valid JSON." % infile)

    first_data = collections.OrderedDict()
    second_data = collections.OrderedDict()
    for i, k in enumerate(data):
        if i < num:
            first_data[k] = data[k]
        else:
            second_data[k] = data[k]

    write_to_json(out1, first_data)
    write_to_json(out2, second_data)


if __name__ == '__main__':
    split_json_dict(sys.argv[1:])
    sys.exit(0)
