#!/usr/bin/env python
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

# Note(TheJulia): This script is no longer required by bifrost, however
# it may prove useful to those performing complex feature development
# within bifrost where they do not want to wait to rely upon CI jobs.
# DEPRICATED: Remove after Mitaka cycle

import re
import subprocess
import sys

if len(sys.argv) is 1:
    print("ERROR: This script requires arguments!\n"
          "%s repository_path review_url repository_name "
          "zuul_changes" % sys.argv[0])
    sys.exit(1)

repo_path = sys.argv[1]
review_url = sys.argv[2]
repo_name = sys.argv[3]
change_list = str(sys.argv[4]).split('^')
applicable_changes = [x for x in change_list if repo_name in x]

try:
    for change in applicable_changes:
        (project, branch, ref) = change.split(':')
        if re.search(repo_name, project):
            if not re.search(branch, subprocess.check_output(
                             ['git', '-C', repo_path, 'status', '-s', '-b'])):
                command = ['git', '-C', repo_path, 'checkout', branch]
                subprocess.call(command, stdout=True)

            command = ['git', '-C', repo_path, 'fetch',
                       review_url + "/" + repo_name, ref]
            if subprocess.call(command, stdout=True) is 0:
                if subprocess.call(
                        ['git', '-C', repo_path, 'cherry-pick',
                         '-n', 'FETCH_HEAD'], stdout=True) is 0:
                    print("Applied %s" % ref)
                else:
                    print("Failed to cherry pick %s onto %s branch %s"
                          % (ref, repo_name, branch))
                    sys.exit(1)
            else:
                print("Failed to download %s on to %s branch %s"
                      % (ref, repo_name, branch))
                sys.exit(1)

except Exception as e:
    print("Failed to process change: %s" % e)
