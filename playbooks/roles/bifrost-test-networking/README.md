# bifrost-test-networking

This role tests the ironic-networking service installation and basic functionality.

## Tests Performed

1. **Service Status Test**: Verifies that the ironic-networking service is active when enabled
2. **Configuration Files Test**: Checks that required configuration files exist
3. **JSON-RPC Endpoint Test**: Validates that the networking service JSON-RPC endpoint is accessible

## Requirements

This role should be run after the ironic-networking service has been installed and configured.

## Variables

The role uses the following variables from the main bifrost configuration:

- `enable_ironic_networking`: Boolean to enable/disable networking tests
- `internal_ip`: IP address for JSON-RPC endpoint testing
- `networking_json_rpc_port`: Port for JSON-RPC endpoint testing
- `networking_switch_config_file`: Path to switch configuration file

## Usage

The role is automatically included in the test-bifrost.yaml playbook when 
`enable_ironic_networking` is set to true.

Manual usage:
```yaml
- hosts: target
  roles:
    - role: bifrost-test-networking
      when: enable_ironic_networking | bool
```