=======================================
Using Bifrost with your own DHCP server
=======================================

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
----------------------------------
In the examples below port 8080 is used. However, the port number may vary
depending on the environment configuration.

dnsmasq::

    dhcp-match=set:ipxe,175 # iPXE sends a 175 option.
    dhcp-boot=tag:!ipxe,/undionly.kpxe,<TFTP Server Hostname>,<TFTP Server IP Address>
    dhcp-boot=http://<Bifrost Host IP Address>:8080/boot.ipxe

Internet Systems Consortium DHCPd::

    if exists user-class and option user-class = "iPXE" {
          filename "http://<Bifrost Host IP Address>:8080/boot.ipxe";
    } else {
          filename "/undionly.kpxe";
          next-server <TFTP Server IP Address>;
    }


Architecture
------------

It should be emphasized that Ironic in standalone mode is intended to be used only
in a trusted environment.

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

===============================================================
Setting static DHCP assignments with the integrated DHCP server
===============================================================

You can set up a static DHCP reservation using the ``ipv4_address`` parameter
and setting the ``inventory_dhcp`` setting to a value of ``true``.  This will
result in the first MAC address defined in the list of hardware MAC addresses
to receive a static address assignment in dnsmasq.

======================================
Forcing DNS to resolve to ipv4_address
======================================

dnsmasq will resolve all entries to the IP assigned to each server in
the leases file. However, this IP will not always be the desired one, if you
are working with multiple networks.
To force DNS to always resolve to ``ipv4_address`` please set the
``inventory_dns`` setting to a value of ``true``. This will result in each
server to resolve to ``ipv4_address`` by explicitly using address capabilities
of dnsmasq.
