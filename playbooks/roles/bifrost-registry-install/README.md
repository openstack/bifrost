# bifrost-registry-install

This role installs and configures a Docker registry using podman as a container
runtime. The registry is designed to integrate with Bifrost's existing
infrastructure, reusing authentication and TLS certificates from Ironic.

## Features

- Installs and configures a Docker registry using the official Docker registry container
- Runs as a systemd service using podman
- Reuses htpasswd authentication from Ironic
- Optionally uses TLS certificates from Ironic for secure connections
- Exposes the registry on the same internal IP as Ironic

## Variables

### Basic Configuration

- `registry_image`: Container image to use (default: "quay.io/opendevmirror/registry:2,
                    which is a mirror of "quay.io/library/registry:2")
- `registry_port`: Port to expose the registry on (default: 5500)

### Network Configuration

- `network_interface`: Network interface for bifrost (default: "virbr0")
- `ans_network_interface`: Ansible-compatible network interface name (calculated)
- `internal_interface`: Internal network interface details (calculated)
- `internal_ip`: IP address on the internal interface (calculated)

### Security and Authentication

- `noauth_mode`: Disable authentication (default: false, i.e. authentication enabled)
- `registry_enable_tls`: Enable TLS using Ironic's certificates (default: `enable_tls`)

### Storage and Logging

- `registry_data_dir`: Directory for registry data (default: "/var/lib/registry")
- `registry_config_dir`: Directory for registry configuration (default: "/etc/registry")
- `registry_log_dir`: Directory for registry logs (default: "/var/log/registry")
- `registry_storage_delete_enabled`: Allow image deletion (default: true)

### Installation Control

Following the same pattern as bifrost-ironic-install:

- `skip_package_install`: Skip installing dependencies (default: false)
- `skip_bootstrap`: Skip configuration and setup (default: false)
- `skip_start`: Skip starting the registry service (default: false)
- `skip_validation`: Skip validating the deployment (default: `skip_start`)

## Usage

Include this role in your playbook:

```yaml
- hosts: localhost
  roles:
    - bifrost-registry-install
```

## Registry Access

Once installed, the registry will be available at:

- HTTP: `http://{{ internal_ip }}:5500` (if TLS is disabled)
- HTTPS: `https://{{ internal_ip }}:5500` (if TLS is enabled)

Authentication uses the same credentials as configured for Ironic.
