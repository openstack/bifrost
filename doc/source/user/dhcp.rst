Configuring the integrated DHCP server
======================================

Setting static DHCP assignments with the integrated DHCP server
---------------------------------------------------------------

You can set up a static DHCP reservation using the ``ipv4_address`` parameter
and setting the ``inventory_dhcp`` setting to a value of ``true``.  This will
result in the first MAC address defined in the list of hardware MAC addresses
to receive a static address assignment in dnsmasq.

Forcing DNS to resolve to ipv4_address
--------------------------------------

dnsmasq will resolve all entries to the IP assigned to each server in
the leases file. However, this IP will not always be the desired one, if you
are working with multiple networks.
To force DNS to always resolve to ``ipv4_address`` please set the
``inventory_dns`` setting to a value of ``true``. This will result in each
server to resolve to ``ipv4_address`` by explicitly using address capabilities
of dnsmasq.

Extending dnsmasq configuration
-------------------------------

Bifrost manages the dnsmasq configuration file in ``/etc/dnsmasq.conf``. It is
not recommended to make manual modifications to this file after it has been
written.  dnsmasq supports the use of additional configuration files in
``/etc/dnsmasq.d``, allowing extension of the dnsmasq configuration provided by
bifrost.  It is possible to use this mechanism provide additional DHCP options
to systems managed by ironic, or even to create a DHCP boot environment for
systems not managed by ironic. For example, create a file
``/etc/dnsmasq.d/example.conf`` with the following contents::

    dhcp-match=set:<tag>,<match criteria>
    dhcp-boot=tag:<tag>,<boot options>

The tag, match criteria and boot options should be modified for your
environment.  Here we use dnsmasq tags to match against hosts that we want to
manage.  dnsmasq will use the last matching tagged ``dhcp-boot`` option for a
host or an untagged default ``dhcp-boot`` option if there were no matches.
These options will be inserted at the ``conf-dir=/etc/dnsmasq.d`` line of the
dnsmasq configuration file.  Once configured, send the ``HUP`` signal to
dnsmasq, which will cause it to reread its configuration::

    killall -HUP dnsmasq

Using Bifrost with your own DHCP server
---------------------------------------

The possibility exists that a user may already have a Dynamic Host
Configuration Protocol (DHCP) server on their network.

Currently Ironic, when configured with Bifrost in standalone mode, does not
utilize a DHCP provider. This would require a manual configuration of the
DHCP server to deploy an image. Bifrost utilizes dnsmasq for this
functionality; however, any DHCP server can be utilized. This is largely
intended to function in the context of a single flat network although
conceivably the nodes can be segregated.

What is required:

- DHCP server on the network segment
- Appropriate permissions to change DHCP settings
- Network access to the API and conductor. Keep in mind the iPXE image does
  not support ICMP redirects.

Example DHCP server configurations
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

In the examples below port 8080 is used. However, the port number may vary
depending on the environment configuration.

dnsmasq::

    dhcp-match=set:ipxe,175 # iPXE sends a 175 option.
    dhcp-boot=tag:ipxe,http://<Bifrost Host IP Address>:8080/boot.ipxe
    dhcp-boot=/undionly.kpxe,<TFTP Server Hostname>,<TFTP Server IP Address>

Internet Systems Consortium DHCPd::

    if exists user-class and option user-class = "iPXE" {
          filename "http://<Bifrost Host IP Address>:8080/boot.ipxe";
    } else {
          filename "/undionly.kpxe";
          next-server <TFTP Server IP Address>;
    }


Architecture
~~~~~~~~~~~~

It should be emphasized that Ironic in standalone mode is intended to be used
only in a trusted environment.

::

                   +-------------+
                   | DHCP Server |
                   +-------------+
                          |
          +--------Trusted-Network----------+
                 |                    |
          +-------------+       +-----------+
          |Ironic Server|       |   Server  |
          +-------------+       +-----------+
