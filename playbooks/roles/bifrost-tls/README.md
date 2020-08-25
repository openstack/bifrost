bifrost-tls
===========

This role generates TLS certificates for Bifrost and copies the private key to
a predefined location.

Requirements
------------

This role requires:

- Ansible 2.9

Role Variables
--------------

generate_tls: Whether the generate new certificates or use existing ones.
              If the latter, this role only handles copying the private key,
              all files have to exist. Defaults to `false` to avoid overwriting
              operator's files.

network_interface: Network interface services are listening on.

tls_common_name: The common name of the certificate. Defaults to the host's
                 full domain name (FQDN).

tls_hosts: A list of valid IP addresses for the generated certificate. Defaults
           to `public_ip` (if set), `private_ip` (if set), `internal_ip` and
           127.0.0.1. The host `localhost` is always added.

tls_host_names: A list of valid host names for the generated certificate.
                Defaults to the host's FQDN + `localhost`.

tls_certificate_path: Path to the TLS certificate. Can be generated.

tls_private_key_path: Path to the private key. Can be generated.

tls_csr_path: Path to the signing request. Can be generated.

tls_force_regenerate: Boolean, whether to regenerate existing certificates.
                      Defaults to `false`.

dest_private_key_path: Destination to copy the private key to. Defaults to
                       undefined (not copying).

dest_private_key_owner: Owner of the destination private key. Defaults to root.

dest_private_key_group: Group of the destination private key. Defaults to root.

Dependencies
------------

None at this time.

Example Playbook
----------------

- hosts: localhost
  connection: local
  name: "Generate TLS parameters"
  become: yes
  gather_facts: yes
  roles:
    - role: bifrost-tls
      generate_tls: true
      tls_common_name: example.com

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
