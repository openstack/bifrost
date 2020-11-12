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


def ansible(playbook, inventory, verbose=False, env=None, extra_vars=None,
            **params):
    extra = COMMON_PARAMS[:]
    extra.extend(itertools.chain.from_iterable(
        ('-e', '%s=%s' % pair) for pair in params.items()
        if pair[1] is not None))
    if extra_vars:
        extra.extend(itertools.chain.from_iterable(
            ('-e', item) for item in extra_vars))
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
            default_boot_mode='uefi' if args.uefi else 'bios',
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
            create_ipa_image='false',
            create_image_via_dib='false',
            install_dib='true',
            network_interface=args.network_interface,
            enable_keystone=args.enable_keystone,
            enable_tls=args.enable_tls,
            generate_tls=args.enable_tls,
            noauth_mode='false',
            enabled_hardware_types=args.hardware_types,
            cleaning_disk_erase=args.cleaning_disk_erase,
            testing=args.testenv,
            use_cirros=args.testenv,
            use_tinyipa=args.testenv,
            developer_mode=args.develop,
            enable_prometheus_exporter=args.enable_prometheus_exporter,
            default_boot_mode='uefi' if args.uefi else 'bios',
            extra_vars=args.extra_vars,
            **kwargs)
    log("Ironic is installed and running, try it yourself:\n",
        " $ source %s/bin/activate\n" % VENV,
        " $ export OS_CLOUD=bifrost\n",
        " $ baremetal driver list\n"
        "See documentation for next steps")


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
    testenv.add_argument('--uefi', action='store_true',
                         help='boot testing VMs with UEFI by default')
    testenv.add_argument('-e', '--extra-vars', action='append',
                         help='additional vars to pass to ansible')
    testenv.add_argument('-o', '--output', default='baremetal-nodes.json',
                         help='output file with the nodes information for '
                              'importing into ironic')

    install = subparsers.add_parser('install', help='Install ironic')
    install.set_defaults(func=cmd_install)
    install.add_argument('--testenv', action='store_true',
                         help='running in a virtual environment')
    install.add_argument('--develop', action='store_true', default=False,
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
                         action='store_true', default=False,
                         help='enable full disk cleaning between '
                              'deployments (can take a lot of time)')
    install.add_argument('--enable-prometheus-exporter', action='store_true',
                         default=False,
                         help='Enable Ironic Prometheus Exporter')
    install.add_argument('--uefi', action='store_true',
                         help='use UEFI by default')
    install.add_argument('-e', '--extra-vars', action='append',
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
            sys.exit(str(exc))
    except KeyboardInterrupt:
        sys.exit('Aborting by user request')


if __name__ == '__main__':
    sys.exit(main())
