#!/usr/bin/env python

# (c) 2015, Hewlett-Packard Development Company, L.P.
#
# This module is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This software is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this software.  If not, see <http://www.gnu.org/licenses/>.

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
                    print("Failed to cherry pick %s on to %s branch %s"
                          % (ref, repo_name, branch))
                    sys.exit(1)
            else:
                print("Failed to download %s on to %s branch %s"
                      % (ref, repo_name, branch))
                sys.exit(1)

except Exception as e:
    print("Failed to process change: %s" % e)
