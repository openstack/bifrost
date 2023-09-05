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

import argparse
import configparser
import ipaddress
import itertools
import json
import os
import subprocess
import sys


VENV = "/opt/stack/bifrost"
ANSIBLE = os.path.join(VENV, 'bin', 'ansible-playbook')
COMMON_ENV = {
    'VENV': VENV,
}
COMMON_PARAMS = [
    '-e', 'bifrost_venv_dir=%s' % VENV,
]
BASE = os.path.abspath(os.path.join(os.path.dirname(sys.argv[0]), '..'))
PLAYBOOKS = os.path.join(BASE, 'playbooks')
DEFAULT_BRANCH = 'master'


def get_env(extra=None):
    # NOTE(dtantsur): the order here matters!
    result = os.environ.copy()
    result.update(COMMON_ENV)
    if extra:
        result.update(extra)
    return result


def log(*message, only_if=True):
    if only_if:
        print(*message, file=sys.stderr)


def process_extra_vars(extra_vars):
    for item in extra_vars:

        # argparse removes quotes, just add quotes for these vars
        if 'extra_kernel_options=' in item:
            key, value = item.split('=', 1)
            item = key + '="' + value + '"'

        if item.startswith('@'):
            # Make sure relative paths still work
            item = '@' + os.path.abspath(item[1:])

        yield ('-e', item)


def ansible(playbook, inventory, verbose=False, env=None, extra_vars=None,
            params_output_file=None, **params):
    extra = COMMON_PARAMS[:]
    if params_output_file is None:
        extra.extend(itertools.chain.from_iterable(
            ('-e', '%s=%s' % pair) for pair in params.items()
            if pair[1] is not None))
    else:
        params_output_file = os.path.abspath(params_output_file)
        log('Writing environment file', params_output_file, only_if=verbose)
        with open(params_output_file, 'wt') as output:
            json.dump({k: v for k, v in params.items() if v is not None},
                      output)
        extra.extend(['-e', '@%s' % params_output_file])

    if extra_vars:
        extra.extend(itertools.chain.from_iterable(
            process_extra_vars(extra_vars)))
    if verbose:
        extra.append('-vvvv')
    args = [ANSIBLE, playbook, '-i', inventory] + extra
    log('Calling ansible with', args, 'and environment', env, only_if=verbose)
    subprocess.check_call(args, env=get_env(env), cwd=PLAYBOOKS)


def env_setup(args):
    log('Installing dependencies and preparing an environment in', VENV,
        only_if=args.debug)
    env = get_env({'BIFROST_TRACE': str(args.debug).lower(),
                   'BIFROST_HIDE_PROMPT': 'true'})
    subprocess.check_call(["bash", "scripts/env-setup.sh"], env=env, cwd=BASE)


def get_release(release):
    if release:
        if release != DEFAULT_BRANCH and not release.startswith('stable/'):
            release = 'stable/%s' % release
        return release
    else:
        try:
            gr = configparser.ConfigParser()
            gr.read(os.path.join(BASE, '.gitreview'))
            release = gr.get('gerrit', 'defaultbranch', fallback=None)
        except (FileNotFoundError, configparser.Error):
            log('Cannot read .gitreview, falling back to defaults')
            return None
        else:
            if release and release.startswith('bugfix/'):
                log('Bugfix branch', release, 'cannot be used as a release, '
                    'falling back to defaults')
                return None
            log('Using release', release, 'detected from the checkout')
            return release


def cmd_testenv(args):
    env_setup(args)
    log('Creating', args.count, 'test node(s) with', args.memory,
        'MiB RAM and', args.disk, 'GiB of disk')

    release = get_release(args.release)

    kwargs = {}
    if release:
        kwargs['git_branch'] = release
    if args.storage_pool_path:
        kwargs['test_vm_storage_pool_path'] = os.path.abspath(
            args.storage_pool_path)

    ansible('test-bifrost-create-vm.yaml',
            inventory='inventory/localhost',
            verbose=args.debug,
            test_vm_num_nodes=args.count,
            test_vm_memory_size=args.memory,
            test_vm_disk_gib=args.disk,
            test_vm_domain_type=args.domain_type,
            test_vm_node_driver=args.driver,
            default_boot_mode=args.boot_mode or 'uefi',
            baremetal_json_file=os.path.abspath(args.inventory),
            baremetal_nodes_json=os.path.abspath(args.output),
            extra_vars=args.extra_vars,
            **kwargs)
    log('Inventory generated in', args.output)


def cmd_install(args):
    release = get_release(args.release)

    kwargs = {}
    if release:
        kwargs.update({'git_branch': release,
                       'ipa_upstream_release': release.replace('/', '-')})
    if args.dhcp_pool:
        try:
            start, end = args.dhcp_pool.split('-')
            ipaddress.ip_address(start)
            ipaddress.ip_address(end)
        except ValueError as e:
            sys.exit("Malformed --dhcp-pool, expected two IP addresses. "
                     "Error: %s" % e)
        else:
            kwargs['dhcp_pool_start'] = start
            kwargs['dhcp_pool_end'] = end

    env_setup(args)
    ansible('install.yaml',
            inventory='inventory/target',
            verbose=args.debug,
            create_ipa_image=False,
            create_image_via_dib=False,
            install_dib=True,
            network_interface=args.network_interface,
            enable_keystone=args.enable_keystone,
            enable_tls=args.enable_tls,
            generate_tls=args.enable_tls,
            noauth_mode=False,
            enabled_hardware_types=args.hardware_types,
            cleaning_disk_erase=args.cleaning_disk_erase,
            testing=args.testenv,
            download_custom_deploy_image=args.testenv,
            use_tinyipa=args.testenv,
            developer_mode=args.develop,
            enable_prometheus_exporter=args.enable_prometheus_exporter,
            default_boot_mode=args.boot_mode or 'uefi',
            enable_dhcp=not args.disable_dhcp,
            extra_vars=args.extra_vars,
            params_output_file=args.output,
            **kwargs)
    log("Ironic is installed and running, try it yourself:\n",
        " $ source %s/bin/activate\n" % VENV,
        " $ export OS_CLOUD=bifrost\n",
        " $ baremetal driver list\n"
        "See documentation for next steps")


def ensure_inside_venv():
    try:
        import oslo_config  # noqa
    except ImportError:
        sys.exit("This command must be executed inside the Bifrost virtual "
                 "environment. Try:\n"
                 f" $ source {VENV}/bin/activate\n"
                 " $ export OS_CLOUD=bifrost")


def configure_inventory(args):
    ensure_inside_venv()
    inventory = os.path.join(PLAYBOOKS, 'inventory', 'bifrost_inventory.py')
    if not args.inventory:
        os.environ['BIFROST_INVENTORY_SOURCE'] = 'ironic'
    elif os.path.exists(args.inventory):
        nodes_inventory = os.path.abspath(args.inventory)
        os.environ['BIFROST_INVENTORY_SOURCE'] = nodes_inventory
    else:
        sys.exit('Inventory file %s cannot be found' % args.inventory)
    return inventory


def cmd_enroll(args):
    inventory = configure_inventory(args)
    ansible('enroll-dynamic.yaml',
            inventory=inventory,
            verbose=args.debug,
            inspect_nodes=args.inspect,
            extra_vars=args.extra_vars)


def cmd_deploy(args):
    inventory = configure_inventory(args)
    try:
        configdrive = json.loads(args.configdrive)
    except (ValueError, TypeError):
        configdrive = args.configdrive

    extra_vars = args.extra_vars or []
    if configdrive:
        # Need to preserve JSON
        extra_vars.append(json.dumps({'deploy_config_drive': configdrive}))

    if (args.image and not args.image.startswith('file://') and not
            args.image_checksum):
        raise TypeError('An --image-checksum is required with --image '
                        'when the image is not a local file')

    ansible('deploy-dynamic.yaml',
            inventory=inventory,
            verbose=args.debug,
            deploy_image_source=args.image,
            deploy_image_type=args.image_type,
            deploy_image_checksum=args.image_checksum,
            wait_for_node_deploy=args.wait,
            extra_vars=extra_vars)


def parse_args():
    parser = argparse.ArgumentParser("Bifrost CLI")
    parser.add_argument('--debug', action='store_true',
                        help='output extensive logging')

    subparsers = parser.add_subparsers()

    testenv = subparsers.add_parser(
        'testenv', help='Prepare a virtual testing environment')
    testenv.set_defaults(func=cmd_testenv)
    testenv.add_argument('--release', default='master',
                         help='release branch to use (master, ussuri, etc), '
                              'must match the release of bifrost.')
    testenv.add_argument('--count', type=int, default=2,
                         help='number of nodes to create')
    testenv.add_argument('--memory', type=int, default=3072,
                         help='memory (in MiB) for test nodes')
    testenv.add_argument('--disk', type=int, default=10,
                         help='disk size (in GiB) for test nodes')
    testenv.add_argument('--domain-type', default='qemu',
                         help='domain type: qemu or kvm')
    testenv.add_argument('--storage-pool-path',
                         help='path to libvirt storage pool to setup')
    testenv.add_argument('--inventory', default='baremetal-inventory.json',
                         help='output file with the inventory for using '
                              'with dynamic playbooks')
    testenv.add_argument('--driver', default='ipmi',
                         choices=['ipmi', 'redfish'],
                         help='driver for testing nodes')
    boot_mode = testenv.add_mutually_exclusive_group()
    boot_mode.add_argument('--uefi', dest='boot_mode',
                           action='store_const', const='uefi',
                           help='boot testing VMs with UEFI by default')
    boot_mode.add_argument('--legacy-boot', dest='boot_mode',
                           action='store_const', const='bios',
                           help='boot testing VMs with legacy boot by default')
    testenv.add_argument('-e', '--extra-vars', action='append',
                         help='additional vars to pass to ansible')
    testenv.add_argument('-o', '--output', default='baremetal-nodes.json',
                         help='output file with the nodes information for '
                              'importing into ironic')

    install = subparsers.add_parser('install', help='Install ironic')
    install.set_defaults(func=cmd_install)
    install.add_argument('--testenv', action='store_true',
                         help='running in a virtual environment')
    install.add_argument('--develop', action='store_true',
                         help='install packages in development mode')
    install.add_argument('--dhcp-pool', metavar='START-END',
                         help='DHCP pool to use')
    install.add_argument('--release',
                         help='release branch to use (master, ussuri, etc), '
                              'the default value is determined from the '
                              '.gitreview file in the source tree')
    install.add_argument('--network-interface',
                         help='the network interface to use')
    install.add_argument('--enable-keystone', action='store_true',
                         help='enable keystone and use authentication')
    install.add_argument('--enable-tls', action='store_true',
                         help='enable self-signed TLS on API endpoints')
    install.add_argument('--hardware-types',
                         # only generic types are enabled in the simple CI
                         default='ipmi,redfish,manual-management',
                         help='a comma separated list of enabled bare metal '
                              'hardware types')
    install.add_argument('--cleaning-disk-erase',
                         action='store_true',
                         help='enable full disk cleaning between '
                              'deployments (can take a lot of time)')
    install.add_argument('--enable-prometheus-exporter', action='store_true',
                         help='Enable Ironic Prometheus Exporter')
    boot_mode = install.add_mutually_exclusive_group()
    boot_mode.add_argument('--uefi', dest='boot_mode',
                           action='store_const', const='uefi',
                           help='use UEFI boot by default')
    boot_mode.add_argument('--legacy-boot', dest='boot_mode',
                           action='store_const', const='bios',
                           help='use legacy boot (BIOS) by default')
    install.add_argument('--disable-dhcp', action='store_true',
                         help='Disable integrated dhcp server')
    install.add_argument('-e', '--extra-vars', action='append',
                         help='additional vars to pass to ansible')
    install.add_argument('-o', '--output',
                         default='baremetal-install-env.json',
                         help='output file with the ansible environment used '
                         'to install Bifrost (excluding -e arguments)')

    enroll = subparsers.add_parser(
        'enroll', help='Enroll bare metal nodes')
    enroll.set_defaults(func=cmd_enroll)
    enroll.add_argument('inventory', default='baremetal-inventory.json',
                        help='file with the inventory')
    enroll.add_argument('--inspect', action='store_true',
                        help='inspect nodes while enrolling')
    enroll.add_argument('-e', '--extra-vars', action='append',
                        help='additional vars to pass to ansible')

    deploy = subparsers.add_parser(
        'deploy', help='Deploy bare metal nodes')
    deploy.set_defaults(func=cmd_deploy)
    deploy.add_argument('inventory', nargs='?',
                        help='file with the inventory, skip to use Ironic')
    deploy.add_argument('--image', help='image URL to deploy')
    deploy.add_argument('--image-checksum',
                        help='checksum of the image to deploy')
    deploy.add_argument('--partition', action='store_const',
                        const='partition', dest='image_type',
                        help='the image is a partition image')
    deploy.add_argument('--configdrive', help='URL or JSON with a configdrive')
    deploy.add_argument('--wait', action='store_true',
                        help='wait for deployment to be finished')
    deploy.add_argument('-e', '--extra-vars', action='append',
                        help='additional vars to pass to ansible')

    args = parser.parse_args()
    if getattr(args, 'func', None) is None:
        parser.print_usage(file=sys.stderr)
        sys.exit("Bifrost CLI: error: a command is required")
    return args


def check_for_root():
    try:
        subprocess.check_call(
            '[ $(whoami) == root ] || sudo --non-interactive true',
            shell=True, stderr=subprocess.DEVNULL)
    except subprocess.CalledProcessError:
        COMMON_PARAMS.append('--ask-become-pass')


def main():
    args = parse_args()
    try:
        check_for_root()
        args.func(args)
    except Exception as exc:
        if args.debug:
            raise
        else:
            return str(exc)
    except KeyboardInterrupt:
        return 'Aborting by user request'
    return 0


if __name__ == '__main__':
    sys.exit(main())
