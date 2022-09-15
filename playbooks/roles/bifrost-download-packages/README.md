bifrost-download-packages
=========================

This role downloads RPM or DEB packages in extracts them on the target system.

Role Variables
--------------

`download_packages`: A list (not a string!) of packages to download.

`download_dest`: Destination directory (must exist). Each package is downloaded
                 into a subdirectory with the same name.

Dependencies
------------

None at this time.

Example Playbook
----------------

```
- hosts: localhost
  connection: local
  become: yes
  gather_facts: yes
  roles:
    - role: bifrost-download-packages
      download_packages:
        - python3
      download_dest: /tmp
```

License
-------

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

Author Information
------------------

Ironic Developers
